#!/usr/bin/env python3
"""kflip: every single-bit change of a kernel's code, given to the decoder and the checker.

    python3 kflip.py k32|p32|p16 OBJECT [--jobs N] [--every K] [--native CASES] [--refused-sample N] [--detail]

An audit of kdecode.py and kcheck.py together. Each bit of the kernel's code in the object is flipped in turn
(--every K: each K-th bit), and the changed object is read and checked as the true one is. Three outcomes:

  stopped   the decoder does not know the bytes (it knows only the forms the kernels use)
  refused   the checker ran the changed code and it does not meet the contract
  ACCEPTED  the changed code is shown to meet the contract
  NO VERDICT  not decided within the time limit: counted apart, never as refused

An accepted change must be one that changes nothing the contract speaks of. Who says so, apart from the
checker under audit? The processor: with `--native CASES` (on an x86-64 machine with AVX-512) every accepted
object is linked with kflip_native.c and run on CASES random inputs the contract allows, against BLAKE3
written out in C: the chaining values, the bytes beside the output, the inputs, the key, the kept registers,
the stack pointer. An accepted change the processor tells from BLAKE3 is an error of the decoder or the
checker: exit status 1. (The other way round is no error: the checker may refuse what happens to work.)

The accepted changes are sorted by where they are:

  padding    inside a no-op an assembler pads with
  prefetch   an operand of PREFETCHT0, which changes no register or memory
  linker     a field the linker fills (a relocation's four bytes: the object's own bytes there are not used)
  contract   anything else: code that does more than the contract asks of it (the kernels take 1 to 16
             blocks and any start and end flags; the contracts fix them), so a change there is not seen

The first lines are controls: the unchanged object is accepted and runs as BLAKE3; asked for a block more
than its inputs hold it faults (the pages around each input); a refused change of a rotation does not run as
BLAKE3."""
import faulthandler, multiprocessing, os, signal, subprocess, sys, tempfile, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode

BASE, DATA = 0x10000, 0x50000000


def verdict(obj, name):
    try:
        rows, data = kdecode.read(obj, kcheck.KERNELS[name]["start"], BASE, DATA)
        entry = BASE + kdecode.address(obj, "blake3_servil_avx512_" + name) - kdecode.address(obj, kcheck.KERNELS[name]["start"])
    except kdecode.Stop as e: return "stopped", str(e)
    except (IndexError, ValueError, KeyError, StopIteration) as e: return "stopped", f"the decoder ran off the bytes ({type(e).__name__})"
    try:
        kcheck.check(rows, DATA, data, name, entry)
    except kcheck.Fail as e: return "refused", str(e)
    except (KeyError, IndexError, ValueError, TypeError, AssertionError, RecursionError) as e: return "refused", f"the checker cannot run it ({type(e).__name__}: {e})"
    return "ACCEPTED", ""


class TimeUp(Exception):
    pass


def time_up(*_): raise TimeUp()


LIMIT = 30          # seconds for one changed object; the true kernels take under one


def one(job):
    name, obj, bit = job
    b = bytearray(obj); b[bit // 8] ^= 1 << (bit % 8)
    signal.signal(signal.SIGALRM, time_up); signal.alarm(LIMIT)
    faulthandler.dump_traceback_later(LIMIT + 10)       # a change that the alarm cannot stop: say where it is
    try:
        return bit, verdict(bytes(b), name)
    except TimeUp:
        return bit, ("NO VERDICT", f"not decided in {LIMIT} s")       # neither refused nor accepted
    finally:
        signal.alarm(0); faulthandler.cancel_dump_traceback_later()


def explain(off, bit, raw, ins, relocs, text_off):
    """Where a flipped bit of the instruction `raw` (at byte `off` within it) is."""
    if any(r <= off + text_off < r + 4 for r in relocs): return "linker"
    if ins == ".nop" and raw[:4] != b"\xf3\x0f\x1e\xfa":
        q = 0
        while raw[q] in (0x66, 0x2E): q += 1
        if raw[q:q + 2] == b"\x0f\x18" or (raw[q] & 0xF0) == 0x40 and raw[q + 1:q + 3] == b"\x0f\x18": return "prefetch"
        return "padding"
    return "contract"


def native(job):
    """The changed object on this processor: "same", "DIFFERS: ...", "CRASHES: ..." or "not linked"."""
    name, obj, bit, folder, cases = job
    b = bytearray(obj)
    extra = ["over"] if bit == "over" else []
    if bit not in (None, "over"): b[bit // 8] ^= 1 << (bit % 8)
    o, exe = f"{folder}/m{bit}.o", f"{folder}/m{bit}"
    with open(o, "wb") as f: f.write(b)
    try:
        r = subprocess.run([os.environ.get("CC", "cc"), "-o", exe, f"{folder}/h.o", f"{folder}/t.o", o], capture_output=True, text=True)
        if r.returncode: return bit, "not linked: " + r.stderr.strip().splitlines()[-1][:120]
        try:
            r = subprocess.run([exe, name, str(cases)] + extra, capture_output=True, text=True, timeout=60)
        except subprocess.TimeoutExpired: return bit, "CRASHES: still running after 60 s"
        if r.returncode == 0: return bit, "same"
        if r.returncode == 1: return bit, "DIFFERS: " + r.stdout.strip()[:120]
        return bit, f"CRASHES: status {r.returncode}"
    finally:
        for path in (o, exe):
            if os.path.exists(path): os.unlink(path)


def main():
    name, path = sys.argv[1], sys.argv[2]
    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else os.cpu_count()
    every = int(sys.argv[sys.argv.index("--every") + 1]) if "--every" in sys.argv else 1
    with open(path, "rb") as f: obj = f.read()
    v = verdict(obj, name)
    print(f"control: the unchanged object is {v[0]} {v[1]}")
    if v[0] != "ACCEPTED": return 1
    e = kdecode.Elf(obj)
    sec = e.sections[e.index[".text"]]
    start = kdecode.address(obj, kcheck.KERNELS[name]["start"])
    rows, _ = kdecode.read(obj, kcheck.KERNELS[name]["start"], BASE, DATA)
    size = rows[-1][1] - BASE
    relocs = e.relocations(".text")
    first = (sec["off"] + start) * 8
    bits = range(first, first + size * 8, every)
    t0 = time.time()
    with multiprocessing.Pool(jobs) as pool:
        results = pool.map(one, [(name, obj, b) for b in bits], chunksize=16)
    count = {"stopped": 0, "refused": 0, "ACCEPTED": 0, "NO VERDICT": 0}
    kinds, unexplained, undecided, detail = {}, {}, [], []
    for bit, (v, why) in results:
        count[v] += 1
        if v in ("stopped", "refused"): continue
        at = bit // 8 - sec["off"] - start                       # the byte's place in the kernel
        row = next(r for r in rows if r[0] - BASE <= at < r[1] - BASE)
        raw = obj[sec["off"] + start + row[0] - BASE:sec["off"] + start + row[1] - BASE]
        if v == "NO VERDICT": undecided.append((at, bit % 8, raw.hex(), row[2])); continue
        kind = explain(at - (row[0] - BASE), bit % 8, raw, row[2], relocs, start + row[0] - BASE)
        kinds[kind] = kinds.get(kind, 0) + 1
        if kind == "contract":
            unexplained[row[2]] = unexplained.get(row[2], 0) + 1
            if "--detail" in sys.argv:
                b = bytearray(obj); b[bit // 8] ^= 1 << (bit % 8)
                rows2, _ = kdecode.read(bytes(b), kcheck.KERNELS[name]["start"], BASE, DATA)
                new = next((x[2] for x in rows2 if x[0] == row[0]), "?")
                detail.append(f"  0x{row[0]:X} `{raw.hex()}` byte {at - (row[0] - BASE)} bit {bit % 8}: {row[2]}  ->  {new}" + ("" if len(rows2) == len(rows) else f"  ({len(rows2)} instructions, were {len(rows)})"))
    n = len(results)
    here = os.path.dirname(os.path.abspath(__file__))
    wrong = []
    if "--native" in sys.argv:
        cases = int(sys.argv[sys.argv.index("--native") + 1])
        folder = tempfile.mkdtemp(prefix="kflip-")
        cc = os.environ.get("CC", "cc")
        subprocess.run([cc, "-O1", "-c", "-o", f"{folder}/h.o", f"{here}/kflip_native.c"], check=True)
        subprocess.run([cc, "-c", "-o", f"{folder}/t.o", f"{here}/kflip_thunk.S"], check=True)
        print(f"control: the unchanged object on this processor, {cases} cases: {native((name, obj, None, folder, cases))[1]}")
        rot = next((bit for bit, (v, why) in results if v == "refused" and "chaining value is not the specification's" in why), None)
        print(f"control: the unchanged object asked for a block more than its inputs hold, on this processor: {native((name, obj, 'over', folder, 20))[1]}")
        print(f"control: a change the checker refused ({dict(results)[rot][1]}), on this processor: {native((name, obj, rot, folder, 20))[1] if rot is not None else 'NONE FOUND'}")
        accepted = [bit for bit, (v, why) in results if v == "ACCEPTED"]
        t1 = time.time()
        with multiprocessing.Pool(jobs) as pool:
            ran = pool.map(native, [(name, obj, b, folder, cases) for b in accepted], chunksize=1)
        tally = {}
        for bit, r in ran:
            k = r.split(":")[0]; tally[k] = tally.get(k, 0) + 1
            if r != "same": wrong.append((bit, r))
        print(f"the {len(accepted)} accepted changes on this processor, {cases} cases each ({time.time() - t1:.0f} s): "
              + ", ".join(f"{v} {k}" for k, v in sorted(tally.items())))
        for bit, r in wrong[:40]:
            at = bit // 8 - sec["off"] - start
            row = next(x for x in rows if x[0] - BASE <= at < x[1] - BASE)
            print(f"  ACCEPTED BY THE CHECKER, AND THE PROCESSOR SAYS {r}: byte 0x{at:X} bit {bit % 8} of {row[2]}")
        if "--refused-sample" in sys.argv:
            k = int(sys.argv[sys.argv.index("--refused-sample") + 1])
            refused = [bit for bit, (v, why) in results if v != "ACCEPTED"]
            sample = refused[::max(1, len(refused) // k)][:k]
            with multiprocessing.Pool(jobs) as pool:
                ran = pool.map(native, [(name, obj, b, folder, min(cases, 200)) for b in sample], chunksize=1)
            tally = {}
            for bit, r in ran: tally[r.split(":")[0]] = tally.get(r.split(":")[0], 0) + 1
            print(f"for scale, {len(sample)} of the changes stopped or refused, on this processor ({min(cases, 200)} cases each): "
                  + ", ".join(f"{v} {k}" for k, v in sorted(tally.items())) + " (\"same\": refused or not decoded, yet it works on these inputs)")
    print(f"{name}: {n} single-bit changes of {size} bytes of code ({time.time() - t0:.0f} s, {jobs} at a time): "
          f"{count['stopped']} stopped by the decoder, {count['refused']} refused by the checker, {count['ACCEPTED']} accepted, {count['NO VERDICT']} with NO VERDICT (the time limit)")
    print("accepted, by where the change is: " + (", ".join(f"{k} {v}" for k, v in sorted(kinds.items())) or "none"))
    if unexplained:
        print(f"contract: the {len(unexplained)} instructions with a change the contract does not see (changes accepted in each):")
        print("  " + "; ".join(f"{k} x{v}" for k, v in sorted(unexplained.items(), key=lambda kv: -kv[1])))
    for line in detail: print(line)
    for at, b, raw, ins in undecided[:400]: print(f"  NO VERDICT: byte 0x{at:X} bit {b} of `{raw}`  {ins}")
    return 1 if wrong or undecided else 0


if __name__ == "__main__":
    sys.exit(main())
