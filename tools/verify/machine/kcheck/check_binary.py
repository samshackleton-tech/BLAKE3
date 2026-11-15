#!/usr/bin/env python3
"""check_binary: one file as it is shipped: a shared object, an executable, or an object with nothing left
for a linker to fill in.

    python3 check_binary.py FILE [FUNCTION]          (FUNCTION: b3l_hashr)

The claim (the last lines of blake3.spec) is about FUNCTION. Its bytes are read from the file as a loader
maps it (kdecode.py: whole pages, the parts without leave to write), and so are the bytes of every function
it calls, and of those they call: each found by where the `call` goes, and checked against the specification by
the checker for its kind, as check_all.py does for the objects an assembler makes. No assembler and no
linker is relied on: what they made is what is read.

Then what else the file holds: how many of the bytes it loads to be run are of the functions checked. (The
claim does not need the rest to be nothing: FUNCTION never leaves the functions checked. A reader may want
to know.)"""
import json, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kcheck, kdecode, kfn, kloop, kone, kspec

WIDE = {kloop.KERNELS[n]["symbol"]: n for n in ("k32", "p32", "p16")}
ONE = {c["symbol"]: n for n, c in kone.CONTRACTS.items()}


def check(path, symbol):
    """(instructions, calls, what kind, where its bytes are in the file's image). Raises kcheck.Fail."""
    if symbol in WIDE:
        name = WIDE[symbol]
        rows, data, entry = kloop.load(path, name)
        with open(os.path.join(HERE, "proofs", name + ".json")) as f: kloop.check(rows, data, name, json.load(f), entry)
        start = kloop.KERNELS[name]["start"]
        return rows, "a wide kernel: every number of blocks", start
    if symbol in ONE:
        rows = kone.load(path, ONE[symbol]); kone.check(rows, ONE[symbol])
        return rows, "a one-block kernel", symbol
    if symbol.startswith("b3l_") and symbol in kspec.SPEC.contracts:
        rows = kfn.load(path, symbol[4:]); kfn.check(rows, symbol[4:])
        return rows, "everything its contract allows", symbol
    raise kcheck.Fail(f"{symbol}: no contract for it")


def main():
    path, top = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "b3l_hashr"
    e = kdecode.Elf(path)
    if not kdecode.settled(e):
        print(f"{os.path.basename(path)}: its code has relocations for a linker to fill in: check_all.py reads such objects"); return 2
    s = kdecode.Settled(e)
    kind = {1: "an object with nothing left for a linker to fill in", 2: "an executable", 3: "a shared object, or an executable that may be loaded anywhere"}[e.type]
    print(f"{os.path.basename(path)}: {kind}, {len(e.b)} bytes; {sum(z - a for a, z, x in s.parts if x)} of them loaded to be run")
    done, todo, covered, failed, count, t_all = {}, [top], [], 0, 0, time.time()
    while todo:
        symbol = todo.pop(0)
        if symbol in done: continue
        t0 = time.time()
        try:
            rows, what, start = check(path, symbol)
        except (kcheck.Fail, kdecode.Stop) as err:
            done[symbol] = None; failed += 1; print(f"  {symbol}: NOT shown: {err}"); continue
        done[symbol] = len(rows)
        at = s.at[start]
        if (at, at + rows[-1][1] - rows[0][0]) not in covered: covered.append((at, at + rows[-1][1] - rows[0][0])); count += len(rows)      # two ways into one body: once
        calls = sorted({i.split()[1] for _, _, i in rows if i.split()[0] == ".call"})
        print(f"  {symbol:<42} at {s.lo + s.at[symbol]:#8x}  {len(rows):>4} instructions  {1000 * (time.time() - t0):7.1f} ms  {what}")
        todo += [c for c in calls if c not in done]
    inside = bytearray(len(s.image))
    for a, z in covered: inside[a:z] = b"\1" * (z - a)
    rest = [i for a, z, x in s.parts if x for i in range(a, z) if not inside[i]]
    zeros = sum(1 for i in rest if s.image[i] == 0)
    run = sum(z - a for a, z, x in s.parts if x)
    print(f"of the {run} bytes loaded to be run: {sum(inside)} are the {len(covered)} bodies checked ({count} instructions), {zeros} are zero, {len(rest) - zeros} are others"
          + (" (constants the functions read; what lies between functions; whatever else the file holds)" if len(rest) - zeros else ""))
    if failed: print(f"{top}: NOT shown ({failed} failed)"); return 1
    print(f"{top} in this file meets the claim in blake3.spec, with all it calls: {len(done)} functions, from the file's bytes, in {time.time() - t_all:.2f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
