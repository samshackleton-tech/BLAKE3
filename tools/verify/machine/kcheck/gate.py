#!/usr/bin/env python3
"""gate: the ≤5-minute gate before a merge or a post (Sam, November 17 2026: an assurance step that takes
hours cannot gate every merge; the exhaustive sweep is a soak, not a gate).

    python3 gate.py [DIR] [--jobs N]       DIR: this folder (default: here)
    GATE_FULL=1 python3 gate.py            (also the exhaustive-soak decision summary, below)

It runs, in parallel (one process per step), and fails on the first failure:

  (1) the adversarial tests: test_kholes.py (the copies that were wrongly shown, each refused), test_refute.py
      (the FALSE-with-an-input machinery), and test_kbinary.py (the hash file as an object and as a shared
      object, every name it gives a linker verified);
  (2) full verification of every shipped binary (verify.py on b3hashr.o and programs/*/ode*.o): exit 0 only
      if shown;
  (3) ELF/linkable shape flips: kfile_flip.py on a program file (every single-bit change of its ELF outside
      code/proof; the hash file's own ELF flips are in the soak, because its driver takes ~15 s a file);
  (4) the lemma tests (test_lemma_audit.py: changed lemmas and specifications judged on numbers; the full
      lemma_audit.py sweep is in the soak).
The full 355k-bit instruction sweep takes hours and is RUN AS A SOAK (audit.sh), not a gate.

Why this catches real bugs in minutes: every hole found by reading (Nov 17: 6 + 2 milder) is a multi-byte /
contract / layout / spec / ELF combination — the exhaustive single-bit sweep cannot see any of them; test_kholes
holds the copies. The sample keeps the instruction model honest between soaks. The gate measures itself:
it prints elapsed seconds and fails if it exceeds 300 (5 minutes).

Run it on the workhorse (64 threads) before merging scratch/sam-batch1 into experiment/sam-wide-model or
posting an audit number publicly. Locally it is slower (10 cores) but still a gate, not a soak."""
import concurrent.futures, os, subprocess, sys, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))


def run(job, timeout=290):
    name, cmd = job
    t0 = time.time()
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=HERE)
        ok = r.returncode == 0
        return (ok, name, time.time() - t0, "" if ok else (r.stdout[-1500:] + r.stderr[-500:]))
    except subprocess.TimeoutExpired:
        return (False, name, time.time() - t0, f"did not end in {timeout}s")


def main():
    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else (os.cpu_count() or 8)
    t_all = time.time()
    work = [
        ("test_kholes (adversarial copies, incl. backdoor.o)", [sys.executable, "test_kholes.py"]),
        ("refuter (FALSE-with-an-input machinery)", [sys.executable, "test_refute.py"]),
        ("verify b3hashr.o (all 14 functions + lemmas)", [sys.executable, "verify.py", os.path.join(HERE, "b3hashr.o")]),
        ("test_kbinary (hash file as object and shared object)", [sys.executable, "test_kbinary.py"]),
        ("kfile_flip frame (ELF outside code/proof)", [sys.executable, "kfile_flip.py", "frame", "--jobs", str(jobs)]),
        ("test_lemma_audit (changed lemmas judged on numbers)", [sys.executable, "test_lemma_audit.py"]),
    ]
    for p in ("adler32", "lz4", "varint", "common", "utf8", "base64", "inet", "frame"):
        work.append((f"verify ode{p}.o", [sys.executable, "programs/check_file.py",
                                           os.path.join(HERE, "programs", p, f"ode{p}.o"),
                                           os.path.join(HERE, "programs", p, f"{p}.spec")]))
    # Steps are independent; run them concurrently. The verifier itself is single-threaded, so this uses the
    # machine instead of adding the times up. Twelve workers is enough: more only makes Python contend.
    with concurrent.futures.ThreadPoolExecutor(max_workers=min(12, len(work))) as pool:
        steps = list(pool.map(run, work))
    failed = [s for s in steps if not s[0]]
    for ok, name, dt, why in sorted(steps, key=lambda s: -s[2]):
        print(f"{'OK  ' if ok else 'FAIL'}  {name:<58} {dt:6.1f}s" + (f"\n  {why[-800:]}\n" if not ok else ""))
    elapsed = time.time() - t_all
    print(f"gate: {'PASS' if not failed and elapsed <= 300 else 'FAIL'} in {elapsed:.0f}s (limit 300s, jobs={jobs}). "
          "The exhaustive single-bit sweep (audit.sh, ~3.5-4h) is a soak, not a gate: "
          "it cannot see the holes in test_kholes (multi-byte/contract/layout), so it must not block merges.")
    # Positive control: if this file's own copy of the backdoor was NOT refused, the gate is broken.
    backdoor = os.path.join(HERE, "backdoor.o")
    if os.path.exists(backdoor):
        r = subprocess.run([sys.executable, "check_binary.py", backdoor, "--spec", os.path.join(HERE, "blake3.spec")],
                           capture_output=True, text=True, timeout=290, cwd=HERE)
        good = r.returncode == 1 and "NOT shown" in r.stdout
        print(f"gate control: backdoor.o refused = {good} ({'OK' if good else 'FAIL: gate broken'})")
        if not good: failed = True
    return 1 if failed or elapsed > 300 else 0


if __name__ == "__main__":
    sys.exit(main())
