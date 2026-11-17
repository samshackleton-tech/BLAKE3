#!/usr/bin/env python3
"""kglue_flip: every single-bit change of push, merge or add, given to the decoder, the prover and the verifier,
and the processor's word on each change a proof is found for.

    python3 kglue_flip.py push|merge|add|avx512|sse41 FOLDER [--jobs N] [--native CASES]

(avx512, sse41: the one-block kernels, verified by kfn.py since November 17, 2026 and run by kone_native.c.)

FOLDER holds push.o, merge.o, add.o (lang/NAME.S assembled) and the one-block kernels' objects (*.o beside
them: they are linked in, not changed). As kflip.py: each bit of the function's code is flipped in turn;
"stopped" (the decoder does not know the bytes), "refused" (no proof is found), "ACCEPTED" (a proof is found
and the verifier takes it). With --native every accepted object is linked with kglue_native.c and run on CASES
random stacks and arguments the contract allows: an accepted change the processor tells from the merge
machine is an error of the decoder or the verifier, and the exit status is 1."""
import multiprocessing, os, signal, subprocess, sys, tempfile, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode, kfn, kglue, kspec

ONE = {"avx512": "blake3_servil_compress_in_place_avx512", "sse41": "blake3_servil_compress_in_place_sse41"}


def symbol(name): return ONE.get(name, "b3l_" + name)

LIMIT = 30


class TimeUp(Exception):
    pass


def time_up(*_): raise TimeUp()


def verdict(obj, name):
    try:
        rows, _ = kdecode.read(obj, symbol(name), kglue.BASE, kglue.DATA)
    except kdecode.Stop as e: return "stopped", str(e)
    except (IndexError, ValueError, KeyError, StopIteration) as e: return "stopped", f"the decoder ran off the bytes ({type(e).__name__})"
    try:
        kspec.fits(obj, symbol(name))
        if name in ONE: kfn.check(rows, None, symbol=symbol(name))          # (since November 17, 2026: by the verifier of functions)
        else: kglue.find(rows, name)
    except kcheck.Fail as e: return "refused", str(e)
    except (KeyError, IndexError, ValueError, TypeError, AssertionError, RecursionError) as e: return "refused", f"the verifier cannot run it ({type(e).__name__}: {e})"
    return "ACCEPTED", ""


def one(job):
    name, obj, bit = job
    b = bytearray(obj); b[bit // 8] ^= 1 << (bit % 8)
    signal.signal(signal.SIGALRM, time_up); signal.alarm(LIMIT)
    try:
        return bit, verdict(bytes(b), name)
    except TimeUp:
        return bit, ("NO VERDICT", f"not decided in {LIMIT} s")
    finally:
        signal.alarm(0)


def native(job):
    name, obj, bit, folder, work, cases = job
    b = bytearray(obj)
    if bit is not None: b[bit // 8] ^= 1 << (bit % 8)
    o, exe = f"{work}/m{bit}.o", f"{work}/m{bit}"
    with open(o, "wb") as f: f.write(b)
    others = [f"{folder}/{f}" for f in sorted(os.listdir(folder)) if f.endswith(".o") and f != name + ".o"]
    try:
        r = subprocess.run([os.environ.get("CC", "cc"), "-o", exe, f"{work}/h.o", f"{work}/t.o", o] + others, capture_output=True, text=True)
        if r.returncode: return bit, "not linked: " + r.stderr.strip().splitlines()[-1][:120]
        try:
            r = subprocess.run([exe, name, str(cases)], capture_output=True, text=True, timeout=60)
        except subprocess.TimeoutExpired: return bit, "CRASHES: still running after 60 s"
        if r.returncode == 0: return bit, "same"
        if r.returncode == 1: return bit, "DIFFERS: " + r.stdout.strip()[:120]
        return bit, f"CRASHES: status {r.returncode}"
    finally:
        for path in (o, exe):
            if os.path.exists(path): os.unlink(path)


def main():
    name, folder = sys.argv[1], sys.argv[2]
    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else os.cpu_count()
    with open(f"{folder}/{name}.o", "rb") as f: obj = f.read()
    v = verdict(obj, name)
    print(f"control: the unchanged object is {v[0]} {v[1]}")
    if v[0] != "ACCEPTED": return 1
    e = kdecode.Elf(obj)
    sec = e.sections[e.index[".text"]]
    start = kdecode.address(obj, symbol(name))
    rows, _ = kdecode.read(obj, symbol(name), kglue.BASE, kglue.DATA)
    size = rows[-1][1] - kglue.BASE
    first = (sec["off"] + start) * 8
    t0 = time.time()
    with multiprocessing.Pool(jobs) as pool:
        results = pool.map(one, [(name, obj, b) for b in range(first, first + size * 8)], chunksize=8)
    count = {"stopped": 0, "refused": 0, "ACCEPTED": 0, "NO VERDICT": 0}
    for _, (v, _) in results: count[v] += 1
    print(f"{name}: {len(results)} single-bit changes of {size} bytes of code ({time.time() - t0:.0f} s): {count['stopped']} stopped by the decoder, "
          f"{count['refused']} refused (no proof), {count['ACCEPTED']} accepted, {count['NO VERDICT']} with NO VERDICT (the time limit)")
    wrong = []
    accepted = [bit for bit, (v, _) in results if v == "ACCEPTED"]
    for bit in accepted:
        at = bit // 8 - sec["off"] - start
        row = next(r for r in rows if r[0] - kglue.BASE <= at < r[1] - kglue.BASE)
        b = bytearray(obj); b[bit // 8] ^= 1 << (bit % 8)
        rows2, _ = kdecode.read(bytes(b), symbol(name), kglue.BASE, kglue.DATA)
        new = next((x[2] for x in rows2 if x[0] == row[0]), "?")
        print(f"  accepted: +0x{row[0] - kglue.BASE:X} byte {at - (row[0] - kglue.BASE)} bit {bit % 8}: {row[2]}  ->  {new}")
    if "--native" in sys.argv:
        cases = int(sys.argv[sys.argv.index("--native") + 1])
        here = os.path.dirname(os.path.abspath(__file__))
        work = tempfile.mkdtemp(prefix="kglue-flip-")
        cc = os.environ.get("CC", "cc")
        subprocess.run([cc, "-O1", "-c", "-o", f"{work}/h.o", f"{here}/{'kone' if name in ONE else 'kglue'}_native.c"], check=True)
        subprocess.run([cc, "-c", "-o", f"{work}/t.o", f"{here}/kflip_thunk.S"], check=True)
        print(f"control: the unchanged object on this processor, {cases} cases: {native((name, obj, None, folder, work, cases))[1]}")
        refused = next((bit for bit, (v, why) in results if v == "refused" and ("not one turn" in why or "not what the contract says" in why or "not the specification's" in why)), None)
        print(f"control: a change no proof was found for, on this processor: {native((name, obj, refused, folder, work, cases))[1] if refused is not None else 'NONE FOUND'}")
        with multiprocessing.Pool(jobs) as pool:
            ran = pool.map(native, [(name, obj, b, folder, work, cases) for b in accepted], chunksize=1)
        tally = {}
        for bit, r in ran:
            tally[r.split(":")[0]] = tally.get(r.split(":")[0], 0) + 1
            if r != "same": wrong.append((bit, r))
        print(f"the {len(accepted)} accepted changes on this processor, {cases} cases each: " + ", ".join(f"{v} {k}" for k, v in sorted(tally.items())))
        for bit, r in wrong[:40]: print(f"  ACCEPTED, AND THE PROCESSOR SAYS {r}: bit {bit - first}")
        sample = [bit for bit, (v, _) in results if v != "ACCEPTED"][::max(1, (len(results) - len(accepted)) // 300)][:300]
        with multiprocessing.Pool(jobs) as pool:
            ran = pool.map(native, [(name, obj, b, folder, work, min(cases, 300)) for b in sample], chunksize=1)
        tally = {}
        for bit, r in ran: tally[r.split(":")[0]] = tally.get(r.split(":")[0], 0) + 1
        print(f"for scale, {len(sample)} of the changes stopped or refused, on this processor: " + ", ".join(f"{v} {k}" for k, v in sorted(tally.items())))
    return 1 if wrong or count["NO VERDICT"] else 0


if __name__ == "__main__":
    sys.exit(main())
