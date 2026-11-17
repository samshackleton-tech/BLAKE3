#!/usr/bin/env python3
"""klink: the functions the hash is made of, and nothing else, as one object with nothing left to fill in.

    python3 klink.py FOLDER OUT.o [OUT.proof]

FOLDER holds the objects an assembler made (as check_all.py's: lib32.o, avx512.o, sse41.o, and one for each
function of hash.ode). This takes from each the bytes of the functions the hash calls, from the function's
first byte to its `ret`, and the read-only data of the objects that have any; lays them out in one section
(code, then data); and writes into each instruction the distance to what it names, which a linker would have
written. OUT.o is an ELF object with one section of code and constants, the functions' names, and no
relocations: a linker has only to place it, on a 64-byte boundary.

Nothing here is trusted. check_binary.py reads OUT.o, or whatever a linker makes of it, from its bytes."""
import hashlib, os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kdecode

HASH = ["pad", "chunk_node", "node_out", "wide32", "wide128", "take", "part32", "subtree", "hashr"]
# The kernels: from their Ode sources (kernels.py makes these objects; until November 17, 2026 they were taken from
# the objects of BLAKE3-Servil's own assembly files, avx512.o, sse41.o and lib32.o: the same bytes, function for function).
BODIES = [(name + ".o", "b3l_" + name) for name in HASH] + [("one.o", "blake3_servil_compress_in_place_avx512"), ("one_sse41.o", "blake3_servil_compress_in_place_sse41"),
                                                              ("k32.o", "blake3_servil_avx512_k32"), ("p16.o", "blake3_servil_avx512_p16")]
ENTRIES = [("k32.o", "blake3_servil_avx512_p32", "blake3_servil_avx512_k32")]         # a second way into a body


def up(n, to, rest=0):
    """The least number not below n that leaves `rest` when divided by `to`."""
    return n + (rest - n) % to


def link(folder):
    objects, bodies = {}, []
    for obj, symbol in BODIES:
        e = objects.setdefault(obj, kdecode.Elf(os.path.join(folder, obj)))
        start = kdecode.address(os.path.join(folder, obj), symbol)
        rows, _ = kdecode.read(os.path.join(folder, obj), symbol, 0, 0)
        bodies.append(dict(obj=obj, symbol=symbol, start=start, size=rows[-1][1]))
    image, where = bytearray(), {}
    for b in bodies:                                     # each body where it lay on its section's boundary
        e = objects[b["obj"]]
        align = e.sections[e.index[".text"]]["align"] or 1
        at = up(len(image), align, b["start"] % align)
        image += b"\xCC" * (at - len(image)) + e.bytes_of(".text")[b["start"]:b["start"] + b["size"]]
        b["at"] = where[b["symbol"]] = at
    for obj, symbol, body in ENTRIES:
        b = next(b for b in bodies if b["symbol"] == body)
        where[symbol] = b["at"] + kdecode.address(os.path.join(folder, obj), symbol) - b["start"]
    data, widest = {}, 64
    for obj, e in objects.items():                       # then the read-only data of each object that has any
        if ".rodata" not in e.index: continue
        align = e.sections[e.index[".rodata"]]["align"] or 1
        widest = max(widest, align)
        at = up(len(image), align)
        image += bytes(at - len(image)) + e.bytes_of(".rodata")
        data[obj] = at
    image += bytes(up(len(image), 64) - len(image)) + bytes(64)        # an operand of 64 bytes may be the last thing in it
    for b in bodies:                                     # what a linker would have written
        e = objects[b["obj"]]
        text = e.index[".text"]
        for s in e.sections:
            if s["type"] != 4 or s["info"] != text: continue
            for i in range(s["size"] // 24):
                off, info, addend = struct.unpack_from("<QQq", e.b, s["off"] + 24 * i)
                if not b["start"] <= off < b["start"] + b["size"]: continue
                sym, kind = e.symbols[info >> 32], info & 0xFFFFFFFF
                if kind not in (2, 4): raise SystemExit(f"klink: {b['symbol']}: a relocation of type {kind}")
                field = b["at"] + off - b["start"]
                if sym["shndx"] == 0:
                    if sym["name"] not in where: raise SystemExit(f"klink: {b['symbol']} names {sym['name']}, which is not among the functions")
                    target = where[sym["name"]]
                elif e.sections[sym["shndx"]]["name"] == ".rodata": target = data[b["obj"]] + sym["value"]
                elif sym["shndx"] == text and sym["name"] in where: target = where[sym["name"]]
                else: raise SystemExit(f"klink: {b['symbol']} names something in {e.sections[sym['shndx']]['name']}")
                struct.pack_into("<i", image, field, target + addend - field)
    return bytes(image), where, {b["symbol"]: b["size"] for b in bodies}, widest


PROOF = ["proofs/inner.spec", "proofs/blake3.lemmas", "proofs/k32.json", "proofs/p32.json", "proofs/p16.json"]


def proof(image, where, more=()):
    """What a verifier needs beside the code and the specification, to be carried in the file: the contracts of
    the functions inside and the kernels' places; where each function is in the code (for a file whose names
    have been stripped); and which specification the maker had (a reader compares it with his own)."""
    with open(os.path.join(HERE, "blake3.spec"), "rb") as f: spec = f.read()
    import kshow
    out = b"ode proof 2\n"
    out += f"specification blake3 {kshow.b3(spec)}\n".encode()
    out += f"code {len(image)} blake3 {kshow.b3(image)} begins {image[:32].hex()}\n".encode()
    for name, at in sorted(where.items(), key=lambda x: x[1]): out += f"at {at} {name}\n".encode()
    out += f"file specification {len(spec)}\n".encode() + spec          # the specification itself: a reader with the file alone can read what it is shown to meet
    for name in PROOF:
        with open(os.path.join(HERE, name), "rb") as f: text = f.read()
        out += f"file {name} {len(text)}\n".encode() + text
    for name, text in more: out += f"file {name} {len(text)}\n".encode() + text
    return out


def arithmetic(path, top="b3l_hashr"):
    """The prover's part of making the file: each function of `path` is verified with the search, and the proofs
    of the arithmetic it needed are kept (kprove.py), to be carried in the file: [(SYMBOL.arith.z, bytes)].
    With them check_binary.py searches for nothing. Trusted for nothing: a table that is wrong shows nothing."""
    import check_binary, kdecode, kprove, varith
    e = kdecode.Elf(path)
    check_binary.take(check_binary.carried(e.bytes_of(".ode.proof")), None)
    # (every name the file gives a linker is verified, called by `top` or not: its arithmetic's proofs too)
    out, todo, done = [], [top] + sorted(n for n in kdecode.linkable(e)[1] if n != top), set()
    while todo:
        symbol = todo.pop(0)
        if symbol in done: continue
        done.add(symbol)
        table = kprove.prove(lambda: check_binary.check(path, symbol))
        rows = check_binary.check(path, symbol)[0]
        if table: out.append((symbol + ".arith.z", varith.pack(table)))
        todo += sorted({i.split()[1] for _, _, i in rows if i.split()[0] == ".call"})
    # and the lemmas about the specification's definitions (that those which use themselves come to an end)
    if check_binary.LEMMAS:
        import kbyte, ode
        spec = ode.with_proof(check_binary.MINE, check_binary.LEMMAS)
        table = kprove.prove(lambda: kbyte.prove_lemmas(spec))
        if table: out.append(("lemmas.arith.z", varith.pack(table)))
    return out


def elf(image, where, sizes, align, carried=None):
    """An ELF object: .text (code and constants), the names, the proof (a section that is not loaded; the hash's,
    unless one is given), and the note that the stack is not to be run."""
    shstr = b"\0.text\0.note.GNU-stack\0.symtab\0.strtab\0.shstrtab\0.ode.proof\0"
    if carried is None: carried = proof(image, where)
    strtab, syms = bytearray(b"\0"), bytearray(24)
    for name, at in sorted(where.items(), key=lambda x: x[1]):
        syms += struct.pack("<IBBHQQ", len(strtab), (1 << 4) | 2, 0, 1, at, sizes.get(name, 0))       # global, a function, in section 1
        strtab += name.encode() + b"\0"
    out = bytearray(64)
    def put(blob, boundary):
        out.extend(bytes(up(len(out), boundary) - len(out)))
        at = len(out); out.extend(blob); return at
    text_at = put(image, align); syms_at = put(syms, 8); str_at = put(strtab, 1); shstr_at = put(shstr, 1); proof_at = put(carried, 1)
    shoff = up(len(out), 8); out.extend(bytes(shoff - len(out)))
    sec = lambda name, typ, flags, off, size, link, info, boundary, entsize: struct.pack("<IIQQQQIIQQ", shstr.index(name), typ, flags, 0, off, size, link, info, boundary, entsize)
    out += bytes(64)
    out += sec(b".text\0", 1, 6, text_at, len(image), 0, 0, align, 0)
    out += sec(b".note.GNU-stack\0", 1, 0, text_at + len(image), 0, 0, 0, 1, 0)
    out += sec(b".symtab\0", 2, 0, syms_at, len(syms), 4, 1, 8, 24)
    out += sec(b".strtab\0", 3, 0, str_at, len(strtab), 0, 0, 1, 0)
    out += sec(b".shstrtab\0", 3, 0, shstr_at, len(shstr), 0, 0, 1, 0)
    out += sec(b".ode.proof\0", 1, 0, proof_at, len(carried), 0, 0, 1, 0)
    out[:64] = b"\x7fELF\x02\x01\x01" + bytes(9) + struct.pack("<HHIQQQIHHHHHH", 1, 62, 1, 0, 0, shoff, 0, 64, 0, 0, 64, 7, 5)
    return bytes(out)


def main():
    if os.environ.get("PYTHONHASHSEED") != "0":
        # the prover's search goes through sets, whose order Python changes from run to run: fixed, so that the
        # same objects make the same file (the proofs it finds are then the same ones)
        os.execve(sys.executable, [sys.executable] + sys.argv, dict(os.environ, PYTHONHASHSEED="0"))
    folder, path = sys.argv[1], sys.argv[2]
    image, where, sizes, align = link(folder)
    with open(path, "wb") as f: f.write(elf(image, where, sizes, align))
    more = arithmetic(path)                                                    # (of the file just written: its bytes as a loader maps them)
    whole = proof(image, where, more)
    with open(path, "wb") as f: f.write(elf(image, where, sizes, align, whole))
    if len(sys.argv) > 3:
        with open(sys.argv[3], "wb") as f: f.write(whole)                      # the proof by itself, for a file that has lost its own
    print(f"{os.path.basename(path)}: {len(where)} names, {sum(sizes.values())} bytes of code in {len(sizes)} bodies, {len(image)} bytes in all, on a {align}-byte boundary; no relocations; "
          f"the proof ({len(whole)} bytes, {sum(len(b) for _, b in more)} of them the arithmetic's proofs for {len(more)} functions) in a section that is not loaded")
    return 0


if __name__ == "__main__":
    sys.exit(main())
