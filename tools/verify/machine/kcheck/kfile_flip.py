#!/usr/bin/env python3
"""kfile_flip: every single-bit change of a shipped object outside its code and its proof.

    python3 kfile_flip.py PROGRAM [--jobs N]        PROGRAM: hash, or a folder of programs/ (frame, lz4, ...)

The file's header, its sections' headers, its table of names and their strings are read by a linker by rules
of its own, and by this folder's reader of files (kdecode.Elf; kdecode.linkable answers for an object's shape).
The single-bit audits of the functions change the code, and the proof is trusted for nothing; this changes
each bit of the rest in turn and gives the changed file to the driver as a reader would (check_binary.py for
the hash, programs/check_file.py for the others).

A changed file the driver still verifies (exit 0) is linked with each of the program's harnesses (the
functions against another implementation of what their contracts say) and run on this machine's processor.
The linker may refuse it; if it links, it must run as the file shipped does. Exit 1 if one does not, or if a
change gets no verdict in time. (A changed file that verifies, links, and runs otherwise would be the
verifier saying "shown" of bytes a caller does not get: found by hand on November 16, 2026, before this.)"""
import concurrent.futures, os, struct, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kdecode

P = os.path.join(HERE, "programs")
# PROGRAM: (the file, the driver, [(the harness's sources, what else the compiler is given, what the harness is given)])
FILES = {
    "hash": ("b3hashr.o", "check_binary.py", [(["khash_native.c", "kflip_thunk.S"], [], ["500"])]),
    "frame": ("programs/frame/odeframe.o", "programs/check_file.py", [(["programs/frame/native.c"], ["-lz"], ["3000"])]),
    "adler32": ("programs/adler32/odeadler32.o", "programs/check_file.py", [(["programs/adler32/native.c"], ["-lz"], ["200"]), (["programs/adler32/native_blocks.c"], ["-lz"], ["600"]),
                                                                         (["programs/adler32/native_blocks4.c"], ["-lz"], ["600"])]),
    "lz4": ("programs/lz4/odelz4.o", "programs/check_file.py", [(["programs/lz4/native.c"], [], ["3000", "full"]), (["programs/lz4/native_store.c"], ["-DBOTH"], ["3000", "room"]),
                                                              (["programs/lz4/native_pack.c"], ["-DBOTH"], ["2000", "full"])]),
    "utf8": ("programs/utf8/odeutf8.o", "programs/check_file.py", [(["programs/utf8/native.c"], [], ["3000"])]),
    "base64": ("programs/base64/odebase64.o", "programs/check_file.py", [(["programs/base64/native.c"], [], ["2000"])]),
    "inet": ("programs/inet/odeinet.o", "programs/check_file.py", [(["programs/inet/native.c"], [], ["3000"])]),
    "varint": ("programs/varint/odevarint.o", "programs/check_file.py", [(["programs/varint/native.c"], [], ["3000"])]),
    "common": ("programs/common/odecommon.o", "programs/check_file.py", [(["programs/common/native.c"], [], ["3000"])]),
}
LIMIT = int(os.environ.get("LIMIT", "300"))        # seconds the driver may take with one changed file


def places(blob):
    """The bytes this changes: the file's header, the sections' headers, and what every section holds but the
    code's and the proof's. [(what, from, to)]"""
    e = kdecode.Elf(blob)
    shoff, = struct.unpack_from("<Q", blob, 40); shentsize, shnum = struct.unpack_from("<HH", blob, 58)
    out = [("the file's header", 0, 64), ("the sections' headers", shoff, shoff + shentsize * shnum)]
    for s in e.sections:
        if s["name"] not in ("", ".text", ".ode.proof") and s["size"]: out.append((f"what {s['name']} holds", s["off"], s["off"] + s["size"]))
    return out


def one(job):
    blob, driver, harnesses, what, at, bit = job
    b = bytearray(blob); b[at] ^= 1 << bit
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "x.o")
        with open(path, "wb") as f: f.write(b)
        try: r = subprocess.run([sys.executable, os.path.join(HERE, driver), path], capture_output=True, text=True, timeout=LIMIT)
        except subprocess.TimeoutExpired: return (what, at, bit, "NO VERDICT", f"the driver did not end in {LIMIT} s")
        if r.returncode != 0: return (what, at, bit, "refused", "")
        ran = []
        for k, (sources, more, given) in enumerate(harnesses):
            exe = os.path.join(d, f"h{k}")
            c = subprocess.run(["cc", "-O1"] + [a for a in more if not a.startswith("-l")] + ["-o", exe] + [os.path.join(HERE, s) for s in sources] + [path] + [a for a in more if a.startswith("-l")],
                               capture_output=True, text=True)
            if c.returncode != 0: ran.append("the linker refuses it"); continue
            try: x = subprocess.run([exe] + given, capture_output=True, text=True, timeout=600)
            except subprocess.TimeoutExpired: return (what, at, bit, "WRONG", f"verified, linked with {sources[0]}, and did not end")
            if x.returncode != 0: return (what, at, bit, "WRONG", f"verified, linked with {sources[0]}, and the processor tells it from the reference: {(x.stdout + x.stderr)[-200:]!r}")
            ran.append("runs as the file shipped does")
        return (what, at, bit, "verified", "; ".join(sorted(set(ran))))


def main():
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] != "--jobs"]
    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else os.cpu_count()
    name, driver, harnesses = FILES[args[0]]
    with open(os.path.join(HERE, name), "rb") as f: blob = f.read()
    r = subprocess.run([sys.executable, os.path.join(HERE, driver), os.path.join(HERE, name)], capture_output=True, text=True)
    if r.returncode != 0: print(f"{name}: the file as shipped is not verified: nothing to change"); return 1
    work = [(blob, driver, harnesses, what, at, bit) for what, a, z in places(blob) for at in range(a, z) for bit in range(8)]
    tally, wrong = {}, []
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        for what, at, bit, verdict, why in pool.map(one, work):
            key = (what, verdict if verdict != "verified" else f"verified: {why}")
            tally[key] = tally.get(key, 0) + 1
            if verdict in ("WRONG", "NO VERDICT"): wrong.append((what, at, bit, verdict, why))
            if verdict == "verified" and "--detail" in sys.argv: print(f"  byte {at:#x} bit {bit} ({what}): still verified; {why}")
    print(f"{name}: {len(work)} single-bit changes outside the code and the proof ({', '.join(f'{w}: {8 * (z - a)}' for w, a, z in places(blob))})")
    for (what, verdict), n in sorted(tally.items()): print(f"  {what:<32} {n:>6}  {verdict}")
    for what, at, bit, verdict, why in wrong: print(f"  {verdict}: byte {at:#x} bit {bit} ({what}): {why}")
    print(f"{name}: " + ("every changed file the driver verified either is refused by the linker or runs as the file shipped does" if not wrong else f"{len(wrong)} WRONG or with no verdict"))
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main())
