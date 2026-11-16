#!/usr/bin/env python3
"""kbyte_flip: every single-bit change of a function's code, checked by kbyte.py; each change it accepts is
run on this machine's processor.

    python3 kbyte_flip.py SPEC SYMBOL OBJECT PROOF [--jobs N] [--native HARNESS.c ARGS...]

The processor is the judge of the verifier's yes: the harness (programs/NAME/native.c) is linked with the
changed object and run; exit 0 means the changed function did, on its cases, what the contract says. A
change the verifier accepts and the processor tells from that is the verifier's fault. Exit 1 if there is one,
or a change without a verdict."""
import multiprocessing, os, signal, subprocess, sys, tempfile, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kbyte, kcheck, kdecode, ode

LIMIT = int(os.environ.get("LIMIT", "300"))


class TimeUp(Exception):
    pass


def time_up(*_): raise TimeUp()


def verdict(obj, spec_text, symbol, proof):
    try: rows = kbyte.load(obj, symbol)
    except kdecode.Stop as e: return "stopped", str(e)
    except kcheck.Fail as e: return "refused", str(e)
    except (IndexError, ValueError, KeyError, StopIteration) as e: return "stopped", f"the decoder ran off the bytes ({type(e).__name__})"
    try: kbyte.check(rows, ode.Spec(spec_text), symbol, proof)
    except (kcheck.Fail, ode.Err) as e: return "refused", str(e)
    except (KeyError, IndexError, ValueError, TypeError, AssertionError, RecursionError, AttributeError) as e: return "refused", f"the verifier cannot run it ({type(e).__name__}: {e})"
    return "ACCEPTED", ""


def one(job):
    obj, spec_text, symbol, proof, bit = job
    b = bytearray(obj); b[bit // 8] ^= 1 << (bit % 8)
    signal.signal(signal.SIGALRM, time_up); signal.alarm(LIMIT)
    try: return bit, verdict(bytes(b), spec_text, symbol, proof)
    except TimeUp: return bit, ("NO VERDICT", f"not decided in {LIMIT} s")
    finally: signal.alarm(0)


def native(job):
    obj, bit, work, args = job
    b = bytearray(obj)
    if bit is not None: b[bit // 8] ^= 1 << (bit % 8)
    o, exe = f"{work}/m{bit}.o", f"{work}/m{bit}"
    with open(o, "wb") as f: f.write(b)
    try:
        r = subprocess.run([os.environ.get("CC", "cc"), "-o", exe, f"{work}/h.o", o] + os.environ.get("LIBS", "").split(), capture_output=True, text=True)
        if r.returncode: return bit, "not linked: " + r.stderr.strip().splitlines()[-1][:120]
        try: r = subprocess.run([exe] + args, capture_output=True, text=True, timeout=120)
        except subprocess.TimeoutExpired: return bit, "CRASHES: still running after 120 s"
        if r.returncode == 0: return bit, "same"
        if r.returncode == 1: return bit, "DIFFERS: " + r.stdout.strip()[:120]
        return bit, f"CRASHES: status {r.returncode}"
    finally:
        for path in (o, exe):
            if os.path.exists(path): os.unlink(path)


def main():
    spec_path, symbol, obj_path, proof_path = sys.argv[1:5]
    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else os.cpu_count()
    with open(spec_path) as f: spec_text = f.read()
    with open(proof_path) as f: proof = f.read()
    with open(obj_path, "rb") as f: obj = f.read()
    v = verdict(obj, spec_text, symbol, proof)
    print(f"control: the unchanged object is {v[0]} {v[1]}")
    if v[0] != "ACCEPTED": return 1
    e = kdecode.Elf(obj)
    sec, start = e.sections[e.index[".text"]], kdecode.address(obj, symbol)
    rows = kbyte.load(obj, symbol)
    size = rows[-1][1] - kbyte.BASE
    first = (sec["off"] + start) * 8
    t0 = time.time()
    with multiprocessing.Pool(jobs) as pool:
        results = pool.map(one, [(obj, spec_text, symbol, proof, b) for b in range(first, first + size * 8)], chunksize=8)
    count = {"stopped": 0, "refused": 0, "ACCEPTED": 0, "NO VERDICT": 0}
    for _, (v, _) in results: count[v] += 1
    print(f"{symbol}: {len(results)} single-bit changes of {size} bytes of code ({time.time() - t0:.0f} s): {count['stopped']} stopped by the decoder, "
          f"{count['refused']} refused, {count['ACCEPTED']} accepted, {count['NO VERDICT']} with NO VERDICT (the time limit)")
    accepted, wrong = [bit for bit, (v, _) in results if v == "ACCEPTED"], []
    if "--detail" in sys.argv:
        for bit in accepted:
            at = bit // 8 - sec["off"] - start
            row = next(r for r in rows if r[0] - kbyte.BASE <= at < r[1] - kbyte.BASE)
            b = bytearray(obj); b[bit // 8] ^= 1 << (bit % 8)
            new = next((x[2] for x in kbyte.load(bytes(b), symbol) if x[0] == row[0]), "?")
            print(f"  accepted: +0x{row[0] - kbyte.BASE:X} byte {at - (row[0] - kbyte.BASE)} bit {bit % 8}: {row[2]}  ->  {new}")
    if "--native" in sys.argv:
        k = sys.argv.index("--native")
        harness, args = sys.argv[k + 1], [a for a in sys.argv[k + 2:] if not a.startswith("--")]
        work = tempfile.mkdtemp(prefix="kbyte-flip-")
        subprocess.run([os.environ.get("CC", "cc"), "-O1", "-c", "-o", f"{work}/h.o", harness], check=True)
        print(f"control: the unchanged object on this processor ({' '.join(args)}): {native((obj, None, work, args))[1]}")
        with multiprocessing.Pool(jobs) as pool:
            ran = pool.map(native, [(obj, b, work, args) for b in accepted], chunksize=1)
        tally = {}
        for bit, r in ran:
            tally[r.split(":")[0]] = tally.get(r.split(":")[0], 0) + 1
            if r != "same": wrong.append((bit, r))
        print(f"the {len(accepted)} accepted changes on this processor: " + ", ".join(f"{v} {k}" for k, v in sorted(tally.items())))
        for bit, r in wrong[:40]: print(f"  ACCEPTED, AND THE PROCESSOR SAYS {r}: bit {bit - first}")
        sample = [bit for bit, (v, _) in results if v != "ACCEPTED"][::max(1, (len(results) - len(accepted)) // 300)][:300]
        with multiprocessing.Pool(jobs) as pool:
            ran = pool.map(native, [(obj, b, work, args) for b in sample], chunksize=1)
        tally = {}
        for bit, r in ran: tally[r.split(":")[0]] = tally.get(r.split(":")[0], 0) + 1
        print(f"for scale, {len(sample)} of the changes stopped or refused, on this processor: " + ", ".join(f"{v} {k}" for k, v in sorted(tally.items())))
    return 1 if wrong or count["NO VERDICT"] else 0


if __name__ == "__main__":
    sys.exit(main())
