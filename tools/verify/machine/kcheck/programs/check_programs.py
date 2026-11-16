#!/usr/bin/env python3
"""check_programs: every program of this folder, from its bytes, against its specification and public contract.

    python3 programs/check_programs.py [FOLDER]

FOLDER holds the objects (adler32.o, lz4_decode.o, ...). Without it they are assembled here from the assembly
the Ode compiler printed (programs/NAME/*.S), with clang where there is one. Each function's bytes are read
by kdecode.py and checked by kbyte.py against the contract in programs/NAME/NAME.spec, with its proof
(programs/NAME/FUNCTION.proof: the places of its loops; none where the verifier runs the loop itself)."""
import os, shutil, sys, tempfile, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import kbyte, kcheck, kdecode, kends, ode
from test_kcheck import assemble

PROGRAMS = [("adler32", "adler32", "Adler-32 of any bytes"),
            ("adler32", "adler32_blocks", "the same, the sums brought below 65521 once in 5552 bytes"),
            ("adler32", "adler32_blocks4", "the same, four bytes a turn"),
            ("lz4", "lz4_decode", "an LZ4 block decoded: the count and the bytes, or NO where decoding fails; safe on any input"),
            ("lz4", "lz4_store", "an LZ4 block written that decodes to the input (all literals)"),
            ("lz4", "lz4_pack", "an LZ4 block written that decodes to the input (with matches)"),
            ("varint", "varint", "a number's varint"),
            ("common", "common", "how many bytes two runs have alike at their start"),
            ("utf8", "utf8", "the count of code points of well-formed UTF-8, or NO"),
            ("base64", "base64", "bytes written in base 64, the room the caller's to give"),
            ("inet", "inet", "the Internet checksum; its trace does not depend on the bytes")]

# A program made of others: (its folder, its function, what it is, {a function it calls: (that one's folder, its name)}).
# One specification for all of it: the folder's NAME.spec (the definitions and the public contract) and
# FUNCTION.inner (the contracts of the functions called: steps of the proof). The function is checked with its
# calls taken by those contracts, and each function it calls is checked against the same text, from its own bytes.
COMPOSED = [("frame", "unframe", "a frame opened: an LZ4 block decoded and its Adler-32 compared, by two functions used through their contracts",
             {"ode_lz4_decode": ("lz4", "lz4_decode"), "ode_adler32_blocks4": ("adler32", "adler32_blocks4")})]


def lemmas(program):
    """The program's lemmas about its specification's definitions (programs/NAME/NAME.lemmas): steps of its proofs."""
    path = os.path.join(HERE, program, program + ".lemmas")
    if not os.path.exists(path): return ""
    with open(path) as f: return "\n" + f.read()


def composed(folder, program, function, parts, made=True):
    """[(symbol, instructions, seconds, what it calls)] of the function and of all it calls; raises where one is not shown."""
    read = lambda *p: open(os.path.join(HERE, *p)).read()
    spec = ode.with_proof(read(program, program + ".spec"), read(program, function + ".inner") + lemmas(program))
    out, todo, seen = [], [("ode_" + function, program, function)], set()
    while todo:
        symbol, where, name = todo.pop(0)
        if symbol in seen: continue
        seen.add(symbol)
        if made: assemble(os.path.join(HERE, where, name + ".S"), os.path.join(folder, name + ".o"))
        t0 = time.time()
        rows = kbyte.load(os.path.join(folder, name + ".o"), symbol)
        tally = kbyte.check(rows, spec, symbol, read(where, name + ".proof"))
        out.append((symbol, len(rows), time.time() - t0, tally["calls"]))
        for called in tally["calls"]:
            if symbol != "ode_" + function: raise kcheck.Fail(f"{symbol} calls {called}: a function that is called and calls another is not this driver's yet")
            if called not in parts: raise kcheck.Fail(f"{symbol} calls {called}, which is no part of this program")
            todo.append((called,) + parts[called])
    return out


def main():
    folder, made = (sys.argv[1], None) if len(sys.argv) > 1 else (tempfile.mkdtemp(prefix="check-programs-"), True)
    failed, total, t_all = 0, 0, time.time()
    try:
        for program, function, what in PROGRAMS:
            if made: assemble(os.path.join(HERE, program, function + ".S"), os.path.join(folder, function + ".o"))
            with open(os.path.join(HERE, program, program + ".spec")) as f: spec_text = f.read()
            with open(os.path.join(HERE, program, function + ".proof")) as f: proof = f.read()
            lines = lambda s: sum(1 for l in s.split("\n") if l.strip() and not l.strip().startswith("//"))
            t0 = time.time()
            try:
                rows = kbyte.load(os.path.join(folder, function + ".o"), "ode_" + function)
                tally = kbyte.check(rows, ode.with_proof(spec_text, lemmas(program)) if lemmas(program) else ode.Spec(spec_text), "ode_" + function, proof)
                total += len(rows)
                again, why = kends.ends_for(ode.with_proof(spec_text, lemmas(program)) if lemmas(program) else ode.Spec(spec_text), "ode_" + function)
                if why: raise kcheck.Fail(f"the definitions its contract speaks through are not shown to come to an end: {why}")
                print(f"  ode_{function:<12} {len(rows):>4} instructions  proof {lines(proof):>3} lines, {proof.count('place +')} places  {1000 * (time.time() - t0):7.1f} ms  meets its contract: {what}")
            except (kcheck.Fail, kdecode.Stop, ode.Err) as e:
                failed += 1; print(f"  ode_{function}: NOT shown: {e}")
        for program, function, what, parts in COMPOSED:
            try:
                done = composed(folder, program, function, parts, made)
                total += done[0][1]
                print(f"  ode_{function:<12} {done[0][1]:>4} instructions  {len(done[0][3])} functions called by their contracts  {1000 * done[0][2]:7.1f} ms  meets its contract: {what}")
                for symbol, n, secs, _ in done[1:]: print(f"      {symbol}: its {n} instructions meet the contract the caller used ({1000 * secs:.0f} ms)")
            except (kcheck.Fail, kdecode.Stop, ode.Err) as e:
                failed += 1; print(f"  ode_{function}: NOT shown: {e}")
    finally:
        if made: shutil.rmtree(folder)
    print(f"{len(PROGRAMS) + len(COMPOSED)} functions, {total} instructions, each against its own specification, in {time.time() - t_all:.2f} s" + (f"; {failed} NOT shown" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
