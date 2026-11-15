#!/usr/bin/env python3
"""kpack: a program of this folder as one file to ship: its functions' bytes, their names, and the proof in a
section that is not loaded. Trusted for nothing: check_file.py reads what it wrote.

    python3 programs/kpack.py PROGRAM FOLDER OUT.o [OUT.proof]

FOLDER holds the assembler's objects (FUNCTION.o for each function of PROGRAM: lz4 has lz4_decode, lz4_store
and lz4_pack). Each function's bytes are taken from its first to its `ret`, laid on a 16-byte boundary, and
given its name. The proof carried is the folder's FUNCTION.proof files, where each function is, and the
SHA-256 of the specification the maker had (programs/PROGRAM/PROGRAM.spec). These functions call nothing and
read no constants, so there is nothing a linker would have had to write."""
import hashlib, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import kdecode, klink
from check_programs import PROGRAMS


def pack(program, folder):
    image, where, sizes, files = bytearray(), {}, {}, []
    for function in [f for p, f, _ in PROGRAMS if p == program]:
        path, symbol = os.path.join(folder, function + ".o"), "ode_" + function
        e = kdecode.Elf(path)
        start = kdecode.address(path, symbol)
        rows, _ = kdecode.read(path, symbol, 0, 0)
        size = rows[-1][1]
        text = e.index[".text"]
        for s in e.sections:
            if s["type"] == 4 and s["info"] == text and s["size"]: raise SystemExit(f"kpack: {function}.o leaves something for a linker to fill in")
        at = klink.up(len(image), 16)
        image += b"\xCC" * (at - len(image)) + e.bytes_of(".text")[start:start + size]
        where[symbol], sizes[symbol] = at, size
        with open(os.path.join(HERE, program, function + ".proof"), "rb") as f: files.append((function + ".proof", f.read()))
    if not where: raise SystemExit(f"kpack: no program {program}")
    image += bytes(klink.up(len(image), 16) - len(image))
    with open(os.path.join(HERE, program, program + ".spec"), "rb") as f: spec = f.read()
    carried = b"ode proof 1\n" + f"specification sha256 {hashlib.sha256(spec).hexdigest()}\n".encode()
    carried += f"code {len(image)} sha256 {hashlib.sha256(image).hexdigest()} begins {bytes(image[:32]).hex()}\n".encode()
    for name, at in sorted(where.items(), key=lambda x: x[1]): carried += f"at {at} {name}\n".encode()
    carried += f"file specification {len(spec)}\n".encode() + spec          # the specification itself, for a reader who has the file alone
    for name, text in files: carried += f"file {name} {len(text)}\n".encode() + text
    return klink.elf(bytes(image), where, sizes, 16, carried), carried, where, len(image)


def main():
    program, folder, out = sys.argv[1:4]
    blob, carried, where, size = pack(program, folder)
    with open(out, "wb") as f: f.write(blob)
    if len(sys.argv) > 4:
        with open(sys.argv[4], "wb") as f: f.write(carried)
    print(f"{os.path.basename(out)}: {len(where)} function(s), {size} bytes of code, {len(blob)} bytes in all; no relocations; the proof ({len(carried)} bytes) in a section that is not loaded")
    return 0


if __name__ == "__main__":
    sys.exit(main())
