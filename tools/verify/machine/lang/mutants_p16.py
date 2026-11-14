#!/usr/bin/env python3
"""Mutation audit of Proof_p16: control must be ACCEPTED; code and statement mutants must be REJECTED.

usage: python3 mutants_p16.py [JOBS]  (run from tools/verify/machine/lang after Proof_p16 builds)"""
import os, shutil, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
JOBS = int(sys.argv[1]) if len(sys.argv) > 1 else 4
LIMIT = 900

CODE_MUTANTS = [
    ("round1 rotation 16 -> 17", ".zprord 13 13 16", ".zprord 13 13 17", "P16Round"),
    ("round XOR source register 0 -> 1", ".zpxord 13 13 0", ".zpxord 13 13 1", "P16Round"),
    ("input transpose shuffle 136 -> 221", ".zshufi32x4 30 31 18 136", ".zshufi32x4 30 31 18 221", "Proof_p16"),
    ("output store offset 0x1C0 -> 0x180", ".zstore false .r15 0x1C0 4", ".zstore false .r15 0x180 4", "Proof_p16"),
    ("flag unpack shift 8 -> 24", ".shr32 .r10 8", ".shr32 .r10 24", "Proof_p16"),
    ("block len shift 24 -> 16", ".shr32 .rsi 24", ".shr32 .rsi 16", "Proof_p16"),
    ("epilogue pop r15 -> pop r14", ".pop .r15", ".pop .r14", "Proof_p16"),
]

SPEC_MUTANTS = [
    ("contract allows flags < 512", "flags < 256#64", "flags < 512#64"),
    ("contract checks blocks = 2", "blocks = 1#64", "blocks = 2#64"),
    ("contract drops 1 <= n", "1#64 ≤ n ∧ n ≤ 16#64", "n ≤ 16#64"),
    ("contract claims stack := 256 (too small for 368)", "stack := 4096#64", "stack := 256#64"),
]


def base_lean_path():
    return subprocess.check_output(["lake", "env", "printenv", "LEAN_PATH"], cwd=HERE, text=True).strip()


def verdict(r):
    """True: Lean accepted it. False: Lean refused it, with an error it printed. None: NO VERDICT (the time
    limit, or a run that ended otherwise than with Lean's word): never counted as rejected."""
    text = r.stdout + r.stderr
    if r.returncode == 0: return "sorryAx" not in text
    if r.returncode == 124: return None
    return False if "error" in text else None


def run_fast(kind, name, fname, old, new, lean_path):
    """Fast check for control and Spec_p16 mutants using prebuilt .olean dependencies."""
    d = tempfile.mkdtemp(prefix="mut-p16-fast-")
    t0 = time.time()
    try:
        env = dict(os.environ, LEAN_PATH=f"{d}:{lean_path}")
        if kind == "spec":
            p_spec = os.path.join(d, "Spec_p16.lean")
            txt = open(os.path.join(HERE, fname)).read()
            assert old in txt, f"{old!r} not in {fname}"
            with open(p_spec, "w") as f:
                f.write(txt.replace(old, new))
            r1 = subprocess.run(
                ["timeout", str(LIMIT), "lean", p_spec, "-o", os.path.join(d, "Spec_p16.olean")],
                cwd=HERE, env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL,
            )
            if r1.returncode != 0:
                return (kind, name, verdict(r1), time.time() - t0, (r1.stdout + r1.stderr)[-300:])
        p_proof = os.path.join(d, "Proof_p16.lean")
        shutil.copy2(os.path.join(HERE, "Proof_p16.lean"), p_proof)
        if kind == "control":
            with open(p_proof, "a") as f:
                f.write("\n-- audit control\n")
        r2 = subprocess.run(
            ["timeout", str(LIMIT), "lean", p_proof],
            cwd=HERE, env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL,
        )
        return (kind, name, verdict(r2), time.time() - t0, (r2.stdout + r2.stderr)[-300:])
    finally:
        shutil.rmtree(d, ignore_errors=True)


def make_lake_copy(dest):
    def ig(_, names):
        return set(shutil.ignore_patterns("mut-*", "par-*", "*.o", "*.log", "ir")(_, names))
    w = os.path.join(dest, "w")
    shutil.copytree(HERE, w, symlinks=True, ignore=ig)
    for dep in ("one", "spec", "levels", "alg", "experiments"):
        src = os.path.join(os.path.dirname(HERE), dep)
        if os.path.exists(src):
            os.symlink(src, os.path.join(dest, dep))
    return w


def run_code(name, old, new, target):
    parent = os.path.dirname(HERE)
    d = tempfile.mkdtemp(prefix="mut-p16-", dir=parent)
    t0 = time.time()
    try:
        w = make_lake_copy(d)
        p = os.path.join(w, "Code_p16.lean")
        txt = open(p).read()
        assert old in txt, f"{old!r} not in Code_p16.lean"
        with open(p, "w") as f:
            f.write(txt.replace(old, new))
        r = subprocess.run(
            ["timeout", str(LIMIT), "lake", "build", target],
            cwd=w, capture_output=True, text=True, stdin=subprocess.DEVNULL,
        )
        return ("code", name, verdict(r), time.time() - t0, (r.stdout + r.stderr)[-300:])
    finally:
        shutil.rmtree(d, ignore_errors=True)


def main():
    lp = base_lean_path()
    kind, name, ok, dt, tail = run_fast("control", "unchanged copy", None, None, None, lp)
    print(f"{kind:<8} {name:<48} {'ACCEPTED' if ok else 'REJECTED' if ok is False else 'NO VERDICT'} ({dt:.1f}s)", flush=True)
    if not ok:
        print("CONTROL FAILED:\n" + tail)
        return 1

    res = []
    with ThreadPoolExecutor(max_workers=JOBS) as ex:
        futs = [ex.submit(run_fast, "spec", n, "Spec_p16.lean", o, nw, lp) for n, o, nw in SPEC_MUTANTS]
        if "--spec-only" not in sys.argv:
            futs += [ex.submit(run_code, n, o, nw, tgt) for n, o, nw, tgt in CODE_MUTANTS]
        for fut in futs:
            res.append(fut.result())

    bad = undecided = 0
    for kind, name, ok, dt, tail in res:
        status = "SURVIVED (BAD)" if ok else "NO VERDICT (the time limit, or no word from Lean)" if ok is None else "rejected"
        bad += ok is True
        undecided += ok is None
        print(f"{kind:<8} {name:<48} {status} ({dt:.1f}s)", flush=True)
    print(f"p16 audit: {len(res) - bad - undecided} of {len(res)} mutants rejected, {undecided} with NO VERDICT; control accepted")
    return 0 if bad == 0 and undecided == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
