#!/usr/bin/env python3
"""check_programs: every program of this folder, from its bytes, against its specification and public contract.

    python3 programs/check_programs.py [FOLDER]

FOLDER holds the objects (adler32.o, lz4_decode.o, ...). Without it they are assembled here from the assembly
the Ode compiler printed (programs/NAME/*.S), with clang where there is one. Each function's bytes are read
by kdecode.py and checked by kbyte.py against the contract in programs/NAME/NAME.spec, with its proof
(programs/NAME/FUNCTION.proof: the places of its loops; none where the checker runs the loop itself)."""
import os, shutil, sys, tempfile, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import kbyte, kcheck, kdecode, ode
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
                tally = kbyte.check(rows, ode.Spec(spec_text), "ode_" + function, proof)
                total += len(rows)
                print(f"  ode_{function:<12} {len(rows):>4} instructions  proof {lines(proof):>3} lines, {proof.count('place +')} places  {1000 * (time.time() - t0):7.1f} ms  meets its contract: {what}")
            except (kcheck.Fail, kdecode.Stop, ode.Err) as e:
                failed += 1; print(f"  ode_{function}: NOT shown: {e}")
    finally:
        if made: shutil.rmtree(folder)
    print(f"{len(PROGRAMS)} functions, {total} instructions, each against its own specification, in {time.time() - t_all:.2f} s" + (f"; {failed} NOT shown" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
