#!/usr/bin/env python3
"""check_all: what a reader would run. Every function shown so far, from its bytes, against blake3.spec.

    python3 check_all.py [FOLDER]

FOLDER holds the objects (lib32.o, out16.o, avx512.o, sse41.o, and one for each of glue/*.S). Without it they
are assembled here from the library's sources (c/*.S) and the Ode functions' assembly (glue/*.S), with clang
where there is one. Each function's bytes are read by kdecode.py and checked against the specification (blake3.spec)
by the checker for its kind, with its proof from proofs/ where it has a loop. Nothing here is a proof
assistant; the programs are what is trusted (README.md)."""
import json, os, shutil, sys, tempfile, time
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, HERE)
import kcheck, kdecode, kfn, kglue, kloop, kone, kspec
from test_kcheck import assemble

BASE, DATA = 0x10000, 0x50000000


def proof(name):
    path = os.path.join(HERE, "proofs", name + ".json")
    with open(path) as f: return json.load(f), os.path.getsize(path)


def kernel_any_count(folder, name):
    rows, data, entry = kloop.load(os.path.join(folder, "lib32.o"), name)
    p, size = proof(name)
    kloop.check(rows, data, name, p, entry)
    return kloop.KERNELS[name]["symbol"], len(rows), size, "every number of blocks, every flag byte"


def kernel_fixed(folder, name, obj):
    k = kcheck.KERNELS[name]
    rows, data = kdecode.read(os.path.join(folder, obj), k["start"], BASE, DATA)
    kspec.fits(os.path.join(folder, obj), k["start"], k["symbol"])
    kcheck.check(rows, DATA, data, name, BASE + kdecode.address(os.path.join(folder, obj), k["symbol"]) - kdecode.address(os.path.join(folder, obj), k["start"]))
    return k["symbol"], len(rows), 0, "every " + k["given"]


def one_block(folder, name):
    rows = kone.load(os.path.join(folder, name + ".o"), name)
    kone.check(rows, name)
    return kone.CONTRACTS[name]["symbol"], len(rows), 0, "every chaining value, block and counter"


def stack_function(folder, name):
    rows = kglue.load(os.path.join(folder, name + ".o"), name)
    p, size = proof(name)
    kglue.check(rows, name, p)
    return "b3l_" + name, len(rows), size if p["places"] else 0, "every stack and argument its contract allows"


def hash_function(folder, name):
    rows = kfn.load(os.path.join(folder, name + ".o"), name)
    kfn.check(rows, name)
    return "b3l_" + name, len(rows), 0, "everything its contract allows" + (": every length of message" if name in ("subtree", "hashr") else "")


CHECKS = [("the wide kernels", [lambda f: kernel_any_count(f, "k32"), lambda f: kernel_any_count(f, "p32"), lambda f: kernel_any_count(f, "p16"),
                                lambda f: kernel_fixed(f, "o16", "out16.o")]),
          ("the one-block kernels", [lambda f: one_block(f, "avx512"), lambda f: one_block(f, "sse41")]),
          ("the hash of a message, written to be proved (hash.ode; calls the kernels above)",
           [lambda f: hash_function(f, "pad"), lambda f: hash_function(f, "chunk_node"), lambda f: hash_function(f, "node_out"), lambda f: hash_function(f, "wide32"), lambda f: hash_function(f, "take"), lambda f: hash_function(f, "part32"), lambda f: hash_function(f, "subtree"),
            lambda f: hash_function(f, "hashr")]),
          ("a stack of subtrees, against an algorithm that is not the specification (an earlier trial; calls the one-block kernels)",
           [lambda f: stack_function(f, "push"), lambda f: stack_function(f, "merge"), lambda f: stack_function(f, "add")])]


def main():
    folder, made = (sys.argv[1], None) if len(sys.argv) > 1 else (tempfile.mkdtemp(prefix="check-all-"), True)
    if made:
        for obj, src in (("lib32.o", "c/blake3_avx512_32.S"), ("out16.o", "c/blake3_output16.S"), ("avx512.o", "c/blake3_avx512_x86-64_unix.S"), ("sse41.o", "c/blake3_sse41_x86-64_unix.S")):
            assemble(os.path.join(ROOT, src), os.path.join(folder, obj))
        for name in ("push", "merge", "add", "pad", "chunk_node", "node_out", "wide32", "take", "part32", "subtree", "hashr"): assemble(os.path.join(HERE, "glue", name + ".S"), os.path.join(folder, name + ".o"))
    bodies, count, failed, t_all = {}, 0, 0, time.time()
    try:
        for title, checks in CHECKS:
            print(title)
            for check in checks:
                t0 = time.time()
                try:
                    symbol, n, size, what = check(folder)
                    print(f"  {symbol:<42} {n:>4} instructions  proof {size:>5} bytes  {1000 * (time.time() - t0):7.1f} ms  meets the specification for {what}")
                    bodies[kloop.KERNELS[symbol[-3:]]["start"] if symbol[-3:] in ("k32", "p32") else symbol] = n; count += 1       # K32 and P32: two entries of one body
                except kcheck.Fail as e:
                    failed += 1; print(f"  NOT shown: {e}")
    finally:
        if made: shutil.rmtree(folder)
    print(f"{count} functions, {sum(bodies.values())} instructions (K32 and P32 are two entries of one body), against blake3.spec, in {time.time() - t_all:.2f} s"
          + (f"; {failed} NOT shown" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
