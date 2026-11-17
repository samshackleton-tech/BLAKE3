#!/usr/bin/env python3
"""kpack: a program of this folder as one file to ship: its functions' bytes, their names, and the proof in a
section that is not loaded. Trusted for nothing: check_file.py reads what it wrote.

    python3 programs/kpack.py PROGRAM FOLDER OUT.o [OUT.proof]

FOLDER holds the assembler's objects (FUNCTION.o for each function of PROGRAM: lz4 has lz4_decode, lz4_store
and lz4_pack). Each function's bytes are taken from its first to its `ret`, laid on a 16-byte boundary, and
given its name. The proof carried is the folder's FUNCTION.proof files, where each function is, and the
BLAKE3 hash of the specification the maker had (programs/PROGRAM/PROGRAM.spec). These functions call nothing and
read no constants, so there is nothing a linker would have had to write."""
import hashlib, os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import kdecode, klink
from check_programs import PROGRAMS, COMPOSED


def pack(program, folder):
    image, where, sizes, files = bytearray(), {}, {}, []
    made = next((c for c in COMPOSED if c[0] == program), None)
    # a program made of others: its function, then each function it calls (from that one's own folder)
    members = [(program, f) for p, f, _ in PROGRAMS if p == program] if made is None else [(program, made[1])] + sorted(made[3].values())
    fields = []
    for home, function in members:
        path, symbol = os.path.join(folder, function + ".o"), "ode_" + function
        e = kdecode.Elf(path)
        start = kdecode.address(path, symbol)
        rows, _ = kdecode.read(path, symbol, 0, 0)
        size = rows[-1][1]
        text = e.index[".text"]
        at = klink.up(len(image), 16)
        for s in e.sections:
            if s["type"] != 4 or s["info"] != text: continue
            for i in range(s["size"] // 24):
                # a call of another function of the file: the one thing here a linker would have had to write
                off, info, addend = struct.unpack_from("<QQq", e.b, s["off"] + 24 * i)
                sym, kind = e.symbols[info >> 32], info & 0xFFFFFFFF
                if kind not in (2, 4) or sym["shndx"] != 0 or not start <= off < start + size: raise SystemExit(f"kpack: {function}.o leaves something for a linker to fill in that is no call")
                fields.append((at + off - start, sym["name"], addend))
        image += b"\xCC" * (at - len(image)) + e.bytes_of(".text")[start:start + size]
        where[symbol], sizes[symbol] = at, size
        with open(os.path.join(HERE, home, function + ".proof"), "rb") as f: files.append((function + ".proof", f.read()))
    for field, name, addend in fields:
        if name not in where: raise SystemExit(f"kpack: a call of {name}, which is not among the functions")
        struct.pack_into("<i", image, field, where[name] + addend - field)
    if made is not None:
        with open(os.path.join(HERE, program, made[1] + ".inner"), "rb") as f: files.append((made[1] + ".inner", f.read()))
    if os.path.exists(os.path.join(HERE, program, program + ".lemmas")):
        with open(os.path.join(HERE, program, program + ".lemmas"), "rb") as f: files.append((program + ".lemmas", f.read()))
    if not where: raise SystemExit(f"kpack: no program {program}")
    image += bytes(klink.up(len(image), 16) - len(image))
    with open(os.path.join(HERE, program, program + ".spec"), "rb") as f: spec = f.read()
    import kshow
    carried = b"ode proof 2\n" + f"specification blake3 {kshow.b3(spec)}\n".encode()
    carried += f"code {len(image)} blake3 {kshow.b3(bytes(image))} begins {bytes(image[:32]).hex()}\n".encode()
    for name, at in sorted(where.items(), key=lambda x: x[1]): carried += f"at {at} {name}\n".encode()
    carried += f"file specification {len(spec)}\n".encode() + spec          # the specification itself, for a reader who has the file alone
    for name, text in files: carried += f"file {name} {len(text)}\n".encode() + text
    # The prover's part: each function verified with the search, from the bytes just laid out, and the proofs
    # of the arithmetic it needed kept for the file to carry: check_file.py then searches for nothing.
    import tempfile
    import kbyte, kprove, ode, varith
    inner = b"\n".join(text for name, text in files if name.endswith((".inner", ".lemmas"))).decode()
    whole = ode.with_proof(spec.decode(), inner) if inner else ode.Spec(spec.decode())
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "packed.o")
        with open(path, "wb") as f: f.write(klink.elf(bytes(image), where, sizes, 16, carried))
        for symbol in sorted(where, key=where.get):
            rows = kbyte.load(path, symbol)
            places = dict(files).get(symbol[len("ode_"):] + ".proof", b"").decode()
            table = kprove.prove(lambda: kbyte.check(rows, whole, symbol, places))
            if table:
                blob = varith.pack(table)
                carried += f"file {symbol[len('ode_'):]}.arith.z {len(blob)}\n".encode() + blob
    return klink.elf(bytes(image), where, sizes, 16, carried), carried, where, len(image)


def main():
    if os.environ.get("PYTHONHASHSEED") != "0":
        # the prover's search goes through sets, whose order Python changes from run to run: fixed, so that the
        # same objects make the same file (the proofs it finds are then the same ones)
        os.execve(sys.executable, [sys.executable] + sys.argv, dict(os.environ, PYTHONHASHSEED="0"))
    program, folder, out = sys.argv[1:4]
    blob, carried, where, size = pack(program, folder)
    with open(out, "wb") as f: f.write(blob)
    if len(sys.argv) > 4:
        with open(sys.argv[4], "wb") as f: f.write(carried)
    print(f"{os.path.basename(out)}: {len(where)} function(s), {size} bytes of code, {len(blob)} bytes in all; no relocations; the proof ({len(carried)} bytes) in a section that is not loaded")
    return 0


if __name__ == "__main__":
    sys.exit(main())
