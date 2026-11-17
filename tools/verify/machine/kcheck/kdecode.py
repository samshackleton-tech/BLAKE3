#!/usr/bin/env python3
"""kdecode: the wide kernels' instructions read from an object's bytes, with no disassembler.

    python3 kdecode.py OBJECT SYMBOL BASE RODATA OUT        writes OUT.rows and OUT.data, as one/lift_one.py does
    python3 kdecode.py --compare OBJECT SYMBOL BASE RODATA LIFTED.rows LIFTED.data

kcheck.py runs rows of instructions. Until now they came from `llvm-objdump`'s text through one/lift_one.py:
a disassembler and a parser of its output stood between the object and the check. This reads the ELF object
itself: the section headers, the symbol, the relocations, the bytes; and decodes the instruction forms the
wide kernels use, and no others: a byte it does not know stops it. `--compare` says whether its rows are the
lifter's, instruction for instruction: two readings of the same bytes, made apart.

Decoding starts at SYMBOL and goes on, instruction after instruction, to the first `ret` (so a second entry
that falls into the same body, as P32 into K32, is read with it). The object's read-only data is placed at
RODATA, as the lifter places it. `lea reg, [rip + data]` is the row `.lea_data reg WHERE` (the lifter writes
it as a move of the number RODATA + WHERE: `--compare` reads the one as the other; the verifiers must not,
for a true move of that number is no address).

Two kinds of file. An object whose code has relocations (an assembler's output): an operand's or a call's
target is what its relocation names. A file whose addresses are settled (`settled` below: an object with no
relocation left for its code, a shared object, an executable): the target is where the instruction's own
bytes say; the bytes read are those a loader maps without leave to write, whole pages of the file, and they
are the read-only data too."""
import struct, sys

G = "rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15".split()


class Stop(Exception):
    pass


def bv(n): return f"0x{n & ((1 << 64) - 1):X}"
def sx(n, bits): return n - (1 << bits) if n >> (bits - 1) else n


class Elf:
    def __init__(self, path):
        if isinstance(path, (bytes, bytearray)): self.b = bytes(path)
        else:
            with open(path, "rb") as f: self.b = f.read()
        b = self.b
        if b[:4] != b"\x7fELF" or b[4] != 2 or b[5] != 1 or struct.unpack_from("<H", b, 18)[0] != 62: raise Stop("not a little-endian x86-64 ELF object")
        self.type, = struct.unpack_from("<H", b, 16)            # 1: an object to be linked; 2: an executable; 3: a shared object
        shoff, = struct.unpack_from("<Q", b, 40); shentsize, shnum, shstrndx = struct.unpack_from("<HHH", b, 58)
        self.sections = []
        for i in range(shnum):
            name, typ, flags, addr, off, size, link, info, align, entsize = struct.unpack_from("<IIQQQQIIQQ", b, shoff + i * shentsize)
            self.sections.append(dict(name=name, type=typ, off=off, size=size, link=link, info=info, align=align, flags=flags))
        names = self.sections[shstrndx]
        cstr = lambda sec, at: b[sec["off"] + at:b.index(b"\0", sec["off"] + at)].decode()
        for s in self.sections: s["name"] = cstr(names, s["name"])
        self.symbols = []
        for symtab in [s for s in self.sections if s["type"] in ((2,) if self.type == 1 else (2, 11))]:    # .symtab; in a linked file .dynsym too
            strtab = self.sections[symtab["link"]]
            for i in range(symtab["size"] // 24):
                name, info, other, shndx, value, size = struct.unpack_from("<IBBHQQ", b, symtab["off"] + 24 * i)
                self.symbols.append(dict(name=cstr(strtab, name), type=info & 15, bind=info >> 4, shndx=shndx, value=value, other=other & 3))
        self.index = {s["name"]: i for i, s in enumerate(self.sections)}
        phoff, = struct.unpack_from("<Q", b, 32); phentsize, phnum = struct.unpack_from("<HH", b, 54)
        self.segments = []
        for i in range(phnum if self.type != 1 else 0):
            typ, flags, off, vaddr, paddr, filesz, memsz, align = struct.unpack_from("<IIQQQQQQ", b, phoff + i * phentsize)
            self.segments.append(dict(type=typ, flags=flags, off=off, vaddr=vaddr, filesz=filesz, memsz=memsz))

    def bytes_of(self, name):
        if name not in self.index: return b""                 # an object with no read-only data
        s = self.sections[self.index[name]]
        return self.b[s["off"]:s["off"] + s["size"]]

    def relocations(self, name):
        """offset in the section -> (section the target is in, offset there before the instruction's own length is counted)"""
        out = {}
        for s in self.sections:
            if s["type"] == 4 and s["info"] == self.index[name]:
                for i in range(s["size"] // 24):
                    off, info, addend = struct.unpack_from("<QQq", self.b, s["off"] + 24 * i)
                    sym = self.symbols[info >> 32]
                    kind = info & 0xFFFFFFFF
                    if kind == 4 or kind == 2 and sym["shndx"] == 0:        # R_X86_64_PLT32, or PC32 to a name from elsewhere: a call
                        out[off] = ("call", sym["name"])
                    elif kind == 2: out[off] = (self.sections[sym["shndx"]]["name"], sym["value"] + addend)      # R_X86_64_PC32
                    else: raise Stop(f"a relocation of type {kind}")
        return out


PAGE = 4096
GIVEN = {}          # names a proof gives to addresses of a file whose own names are gone (check_binary.py): {name: address}


class Named:
    """An object whose code has relocations: an operand's or a call's target is what its relocation names.
    `align`: the boundary the read-only data starts on, wherever a linker puts it."""
    def __init__(self, e):
        self.table = e.relocations(".text")
        self.align = e.sections[e.index[".rodata"]]["align"] if ".rodata" in e.index else 1

    def data(self, code, field, end):
        if field not in self.table: raise Stop("a RIP-relative operand with no relocation")
        sec, off = self.table[field]
        if sec != ".rodata": raise Stop(f"an operand in {sec}")
        return off + (end - field)

    def callee(self, code, field, end):
        if self.table.get(field, ("", ""))[0] != "call": raise Stop("a call with no function named")
        return self.table[field][1]


class Settled:
    """A file whose addresses are settled. `image`: the bytes a loader maps without leave to write, from the
    lowest such address `lo` (for an object: its .text); `parts`: (from, to, executable) within the image;
    `names`: the functions' names by where they start; `align`: the boundary the image starts on."""
    def __init__(self, e):
        if e.type == 1:
            if ".text" not in e.index: raise Stop("an object with no .text")
            text = e.bytes_of(".text")
            self.image, self.lo, self.parts, self.align = text, 0, [(0, len(text), True)], e.sections[e.index[".text"]]["align"]
            inside = lambda s: s["shndx"] == e.index[".text"]
        else:
            spans = []
            for s in e.segments:
                if s["type"] == 2:                               # PT_DYNAMIC: does the file ask the loader to change its code?
                    for i in range(s["filesz"] // 16):
                        tag, val = struct.unpack_from("<QQ", e.b, s["off"] + 16 * i)
                        if tag == 0: break
                        if tag == 22 or tag == 30 and val & 4: raise Stop("the file asks the loader to write into its code (TEXTREL)")
                if s["type"] != 1: continue                      # PT_LOAD: what is mapped, in whole pages
                if (s["vaddr"] - s["off"]) % PAGE: raise Stop("a part of the file is not where its page in memory is")
                spans.append((s["vaddr"] // PAGE * PAGE, -(-(s["vaddr"] + s["memsz"]) // PAGE) * PAGE, s))
            for i, (a, z, s) in enumerate(spans):
                if any(a < z2 and a2 < z for a2, z2, _ in spans[i + 1:]): raise Stop("two parts of the file are loaded on one page")
            keep = sorted(((a, z, s) for a, z, s in spans if not s["flags"] & 2), key=lambda x: x[0])      # without leave to write
            if not keep: raise Stop("nothing in the file is loaded read-only")
            if any(z != a2 for (_, z, _), (a2, _, _) in zip(keep, keep[1:])): raise Stop("the parts loaded read-only do not lie side by side")
            self.lo, image, self.parts, self.align = keep[0][0], bytearray(), [], PAGE
            for a, z, s in keep:
                if s["memsz"] != s["filesz"]: raise Stop("a read-only part that is longer in memory than in the file")
                first = s["off"] - (s["vaddr"] - a)
                piece = e.b[first:first + z - a]                 # whole pages of the file, as a loader maps them; past the file's end, zeros
                image += piece + bytes(z - a - len(piece))
                self.parts.append((a - self.lo, z - self.lo, bool(s["flags"] & 1)))
            self.image = bytes(image)
            inside = lambda s: 0 < s["shndx"] < 0xFF00 and self.lo <= s["value"] < self.lo + len(self.image)      # in a section: a loader moves it with the file
        # Names: of functions, and of labels an assembler gave no type. A name the file gives to two places
        # (as an object's own names may be, once several objects are linked) is no name here.
        places = {}
        for s in e.symbols:
            if s["name"] and s["type"] in (0, 2) and inside(s): places.setdefault(s["name"], set()).add(s["value"] - self.lo)
        for name, value in GIVEN.items(): places.setdefault(name, set()).add(value - self.lo)        # names a proof gives: as the file's own
        self.at = {name: min(where) for name, where in places.items() if len(where) == 1}
        self.names = {}
        for name, v in self.at.items(): self.names.setdefault(v, []).append(name)

    def runs(self, a, z):
        return any(x and lo <= a and z <= hi for lo, hi, x in self.parts)

    def target(self, code, field, end):
        return end + sx(int.from_bytes(code[field:field + 4], "little"), 32)

    def data(self, code, field, end):
        t = self.target(code, field, end)
        if not any(lo <= t and t + 64 <= hi for lo, hi, _ in self.parts): raise Stop("an operand that is not in what is loaded read-only")
        return t

    def callee(self, code, field, end):
        t = self.target(code, field, end)
        if t not in self.names: raise Stop("a call to what is no function's start")
        return sorted(self.names[t], key=lambda n: (n.startswith("_"), n))[0]


def settled(e):
    """The file's addresses are settled: no relocation is left for its code."""
    return e.type != 1 or not any(s["type"] in (4, 9) and s["info"] == e.index.get(".text") for s in e.sections)


KNOWN = {".text": (1, 0x6), ".note.GNU-stack": (1, 0), ".symtab": (2, 0), ".strtab": (3, 0), ".shstrtab": (3, 0), ".ode.proof": (1, 0)}      # a section's name: (its type, its leave)


def linkable(e):
    """For an object that is to be linked (a file of type 1): (why it is not read, {}), or (None, {name: its
    place in .text}) with every name the file gives a linker.

    A linker takes more from an object than the bytes of `.text` read here: other sections it loads to be
    run, whatever they are called; names it resolves by rules of its own (a LOCAL name goes to no caller, a
    WEAK one may give way to another file's, an IFUNC is resolved when the program starts); a stack it is
    asked to make executable. Until November 16, 2026 a copy of the shipped odeframe.o whose `ode_unframe` was
    made LOCAL, with another function under the GLOBAL name in a second executable section, was verified as
    the shipped file is, and a program linked with it ran the other function. So an object is read only in
    the one shape the makers here write (klink.py, programs/kpack.py), with its names or stripped of them:
    the sections of KNOWN and no others, each once, of that type and with that leave (and the one that says the stack is not to be run, there); and no name but GLOBAL
    names of functions in `.text`, each once. A driver then asks that each such name be verified."""
    seen = set()
    for i, s in enumerate(e.sections):
        if i == 0 and s["type"] == 0 and s["size"] == 0: continue
        name = s["name"]
        if name not in KNOWN or name in seen:
            return f"it has a section this reader does not read ({name!r}{', a second time' if name in seen else ''}), and a linker would take that too", {}
        seen.add(name)
        if (s["type"], s["flags"]) != KNOWN[name]:
            return f"its section {name} is not of the kind, or has not the leave, this reader takes it to have (type {s['type']}, flags {s['flags']:#x})", {}
    if ".note.GNU-stack" not in seen: return "it has no section .note.GNU-stack, and a linker takes that as asking for a stack that can be run", {}
    names, text = {}, e.index.get(".text")
    for k, sym in enumerate(e.symbols):
        if k == 0 and not sym["name"] and sym["shndx"] == 0: continue
        if not (sym["type"] in (0, 2) and sym["bind"] == 1 and sym["other"] == 0 and sym["shndx"] == text and sym["name"]) or sym["name"] in names:
            return (f"it has a name of a kind this reader does not read ({sym['name']!r}: type {sym['type']}, binding {sym['bind']}, visibility {sym['other']}, "
                    f"section {sym['shndx']}{', given twice' if sym['name'] in names else ''}), and a linker reads names by rules of its own"), {}
        names[sym["name"]] = sym["value"]
    return None, names


def decode(code, at, relocs, rodata, rodata_at, base, start):
    """One instruction at `at`: (its length, its text in the lifter's form)."""
    n, text = decode1(code, at, relocs, rodata, rodata_at, base, start)
    if n > 15: raise Stop("an instruction of more than fifteen bytes: a processor refuses it")
    return n, text


def decode1(code, at, relocs, rodata, rodata_at, base, start):
    p = at
    def u8():
        nonlocal p
        p += 1; return code[p - 1]
    def imm(n):
        nonlocal p
        p += n; return int.from_bytes(code[p - n:p], "little")
    here = lambda v: f"0x{base + v - start:X}"

    def modrm(rex_r, rex_x, rex_b, scale8=1, evex=False):
        """(mod, reg, rm register or None, memory operand or None). Memory: (base, index or None, disp) or ("rip", field offset).
        A bit the encoding does not use (X with no index, a scale with no index, X and B of a RIP-relative
        operand) must be clear, as an assembler leaves it: what a processor does with it set is not our question."""
        m = u8(); mod, reg, rm = m >> 6, (m >> 3) & 7, m & 7
        reg |= rex_r << 3
        if mod == 3:
            if rex_x and not evex: raise Stop("X set with no index")       # EVEX: X is a vector register's fifth bit (the caller's)
            return mod, reg, rm | (rex_b << 3), None
        index = None
        if rm == 4:
            s = u8(); scale, idx, bs = s >> 6, (s >> 3) & 7, s & 7
            idx |= rex_x << 3
            if scale: raise Stop("a scale")
            if idx != 4: index = G[idx]
            if bs == 5 and mod == 0: raise Stop("an address with no base")
            b = G[bs | (rex_b << 3)]
        elif rm == 5 and mod == 0:
            if rex_x or rex_b: raise Stop("X or B set on a RIP-relative operand")
            field = p; imm(4)
            return mod, reg, None, ("rip", field)
        else:
            if rex_x: raise Stop("X set with no index")
            b = G[rm | (rex_b << 3)]
        disp = 0 if mod == 0 else (sx(imm(1), 8) * scale8 if mod == 1 else sx(imm(4), 32))
        return mod, reg, None, (b, index, disp)

    def data_at(field, end): return relocs.data(code, field, end)

    op = u8()
    # no-ops: ENDBR64, the multi-byte NOPs an assembler pads with, PREFETCHT0
    if code[at:at + 4] == b"\xf3\x0f\x1e\xfa": return 4, ".nop"
    q = at
    while code[q] in (0x66, 0x2E): q += 1
    if code[q] == 0x90 and q > at or code[at] == 0x90: return q - at + 1, ".nop"
    if code[q:q + 2] == b"\x0f\x1f":
        p = q + 2; mod, reg, r, mem = modrm(0, 0, 0)
        if reg != 0: raise Stop("0F 1F with another digit")
        return p - at, ".nop"
    if op == 0xC5 and code[at + 1:at + 3] == b"\xf8\x77": return 3, ".vzeroupper"

    def words128(field, end):
        off = data_at(field, end)
        # MOVAPS faults where the sixteen bytes do not start on a 16-byte boundary
        if off % 16 or relocs.align % 16: raise Stop("sixteen bytes read as aligned from where they need not be on a 16-byte boundary")
        return " ".join(f"0x{int.from_bytes(rodata[off + 4 * i:off + 4 * i + 4], 'little'):X}" for i in range(4))

    def xmm_form(sse66, opc, W, R, X, B, v):
        """An instruction of 128-bit registers, as legacy SSE writes it (v None: the destination is the first
        source) or as VEX does (v: the first source). Rows name the destination and both sources."""
        nonlocal p
        if opc == 0x38:
            if u8() != 0x00 or not sse66: raise Stop("0F 38 other than PSHUFB")
            mod, reg, rm, mem = modrm(R, X, B, evex=True)
            if rm is None: raise Stop("a shuffle by a mask in memory")
            return f".xpshufb {reg} {reg if v is None else v} {rm}"
        if opc == 0x3A:
            if u8() != 0x0E or not sse66: raise Stop("0F 3A other than PBLENDW")
            mod, reg, rm, mem = modrm(R, X, B, evex=True)
            if rm is None: raise Stop("a blend from memory")
            return f".xpblendw {reg} {reg if v is None else v} {rm} {imm(1)}"
        mod, reg, rm, mem = modrm(R, X, B, evex=True)       # X: of an index only (a register operand has no fifth bit here)
        if rm is not None and X: raise Stop("X set with no index")
        a = reg if v is None else v
        if W != (1 if (sse66, opc) == (True, 0x6E) else 0): raise Stop("W set where it has no meaning, or clear on a 64-bit move")
        if not sse66 and opc in (0x10, 0x11) or sse66 == "f3" and opc in (0x6F, 0x7F):
            # sixteen bytes between a register and memory, any alignment (MOVUPS, VMOVUPS, VMOVDQU)
            if rm is not None or mem[0] == "rip" or mem[1]: raise Stop("an unaligned 128-bit move other than with [base + displacement]")
            if v not in (None, 0): raise Stop("a second source where there is none")
            return f".xloadu {reg} .{mem[0]} {bv(mem[2])}" if opc in (0x10, 0x6F) else f".xstoreu .{mem[0]} {bv(mem[2])} {reg}"
        if not sse66 and opc == 0x28 or sse66 is True and opc in (0x6F, 0x7F):
            # MOVAPS, MOVDQA: a register to a register, or (0x28) sixteen bytes of the object's read-only data
            if v not in (None, 0): raise Stop("a second source where there is none")
            if rm is not None: return f".xmov {rm} {reg}" if opc == 0x7F else f".xmov {reg} {rm}"
            if opc != 0x28 or mem[0] != "rip": raise Stop("an aligned 128-bit move with memory that is not read-only data")
            return f".xconst {reg} {words128(mem[1], p)}"
        if not sse66 and opc == 0xC6:
            if rm is None: raise Stop("a shuffle from memory")
            return f".xshufps {reg} {a} {rm} {imm(1)}"
        if sse66 is not True: raise Stop("a 128-bit instruction this does not know")
        if opc == 0x6E:
            if rm is None or v not in (None, 0): raise Stop("a 64-bit move into a vector register from memory")
            return f".xmovq {reg} .{G[rm]}"
        if rm is None: raise Stop("a 128-bit operation from memory")
        three = {0x6C: "xpunpcklqdq", 0x62: "xpunpckldq", 0x6A: "xpunpckhdq", 0xFE: "xpaddd", 0xEF: "xpxor", 0xEB: "xpor"}
        if opc in three: return f".{three[opc]} {reg} {a} {rm}"
        if opc == 0x70:
            if v not in (None, 0): raise Stop("a second source where there is none")
            return f".xpshufd {reg} {rm} {imm(1)}"
        if opc == 0x72:
            if reg not in (2, 6) or v is not None: raise Stop("0F 72 with another digit")
            return f".{'xpsrld' if reg == 2 else 'xpslld'} {rm} {rm} {imm(1)}"
        raise Stop(f"a 128-bit instruction this does not know: 0F {opc:02X}")

    if op in (0xC4, 0xC5):      # VEX: 128 bits only
        b1 = u8()
        if op == 0xC5: R, X, B, mm, W, b2 = (~b1 >> 7) & 1, 0, 0, 1, 0, b1
        else:
            R, X, B, mm = (~b1 >> 7) & 1, (~b1 >> 6) & 1, (~b1 >> 5) & 1, b1 & 31
            b2 = u8(); W = b2 >> 7
        v, L, pp = (~b2 >> 3) & 15, (b2 >> 2) & 1, b2 & 3
        if L: raise Stop("a VEX form of 256 bits")
        opc = u8()
        if mm == 3 and pp == 1 and opc == 0x02:
            if W: raise Stop("VPBLENDD with W set")
            mod, reg, rm, mem = modrm(R, X, B, evex=True)
            if rm is None or X: raise Stop("a blend from memory")
            return p - at + 1, f".xpblendd {reg} {v} {rm} {imm(1)}"
        # (38 and 3A are the older encoding's ways into its other maps; VEX names the map itself, and has no instruction there)
        if mm != 1 or pp == 3 or opc in (0x38, 0x3A): raise Stop("a VEX instruction this does not know")
        text = xmm_form({0: False, 1: True, 2: "f3"}[pp], opc, W, R, X, B, v)
        return p - at, text
    q = at
    sse66 = code[q] == 0x66
    if sse66: q += 1
    rexq = code[q] if 0x40 <= code[q] <= 0x4F else 0
    if rexq: q += 1
    if code[q] == 0x0F and (sse66 and code[q + 1] in (0x6E, 0x6C, 0x62, 0x6A, 0xFE, 0xEF, 0xEB, 0x70, 0x72, 0x6F, 0x38, 0x3A) or not sse66 and code[q + 1] in (0x10, 0x11, 0x28, 0xC6)):
        if rexq and not rexq & 0x0F: raise Stop("an empty REX prefix")
        p = q + 1
        text = xmm_form(sse66, u8(), (rexq >> 3) & 1, (rexq >> 2) & 1, (rexq >> 1) & 1, rexq & 1, None)
        return p - at, text
    if op == 0x62:      # EVEX
        p0, p1, p2 = u8(), u8(), u8()
        if p0 & 0x08 or not p1 & 0x04: raise Stop("not an EVEX prefix")
        R, X, B, R2 = (~p0 >> 7) & 1, (~p0 >> 6) & 1, (~p0 >> 5) & 1, (~p0 >> 4) & 1
        mm, W, vvvv, pp = p0 & 7, p1 >> 7, (~p1 >> 3) & 15, p1 & 3
        z, LL, bcast, V2, aaa = p2 >> 7, (p2 >> 5) & 3, (p2 >> 4) & 1, (~p2 >> 3) & 1, p2 & 7
        if z or bcast: raise Stop("an EVEX form with zeroing or a broadcast operand")
        v = vvvv | (V2 << 4)
        opc = u8()
        scalar = (mm, opc) == (2, 0x58)
        # 512 bits everywhere, but for one form: the unaligned load of 256 bits (eight words) into a register's low half
        half = LL == 1 and (mm, pp, W, opc) == (1, 2, 0, 0x6F)
        narrow = LL == 0 and (mm, pp, W, opc) in ((1, 1, 0, 0xEF), (1, 1, 0, 0x72))       # VPXORD, VPRORD of XMM registers
        if LL != 2 and not half and not narrow: raise Stop("an EVEX form other than 512 bits")
        mod, reg, rm, mem = modrm(R, X, B, 4 if scalar else 32 if half else 16 if narrow else 64, evex=True)
        reg |= R2 << 4
        if rm is not None: rm |= X << 4          # a register operand: X is its fifth bit
        if narrow:
            if aaa or rm is None: raise Stop("a masked or memory form of a 128-bit instruction")
            if opc == 0xEF: return p - at, f".xpxor {reg} {v} {rm}"
            if reg != 0: raise Stop("0F 72 with another digit, or R set beside a digit")
            return p - at + 1, f".xprord {v} {rm} {imm(1)}"
        key = (mm, pp, W, opc)
        tail = lambda: imm(1)
        def no_mask():
            if aaa: raise Stop("a mask on an instruction read without one")
        def no_v():
            if v: raise Stop("a second source where there is none")
        if half:
            no_mask(); no_v()
            if rm is not None or mem[0] == "rip" or mem[1]: raise Stop("a 256-bit move other than a load from [base + displacement]")
            return p - at, f".yloadu {reg} .{mem[0]} {bv(mem[2])}"
        if key in ((1, 1, 0, 0x6F), (1, 2, 0, 0x6F), (1, 1, 0, 0x7F), (1, 2, 0, 0x7F)):
            no_mask(); no_v(); al = "true" if pp == 1 else "false"
            if rm is not None:
                if opc != 0x6F: raise Stop("a register store")
                return p - at, f".zmov {reg} {rm}"
            if mem[0] == "rip": raise Stop("a wide move of read-only data")
            b, index, disp = mem
            if opc == 0x7F:
                if index: raise Stop("an indexed store")
                return p - at, f".zstore {al} .{b} {bv(disp)} {reg}"
            if index:
                if pp != 2: raise Stop("an aligned indexed load")
                return p - at, f".zloadi {reg} .{b} .{index} {bv(disp)}"
            return p - at, f".zload {al} {reg} .{b} {bv(disp)}"
        if key == (1, 1, 0, 0xFE):
            if rm is not None:
                return p - at, (f".zpaddd_k {reg} {aaa} {v} {rm}" if aaa else f".zpaddd {reg} {v} {rm}")
            no_mask()
            if mem[0] == "rip":
                off = data_at(mem[1], p)
                return p - at, f".zpadddc {reg} {v} 0x" + "".join(f"{x:02X}" for x in reversed(rodata[off:off + 64])) + "#512"
            b, index, disp = mem
            if not index: raise Stop("an add from memory with no index")
            return p - at, f".zpadddm {reg} {v} .{b} .{index} {bv(disp)}"
        three = {(1, 1, 0, 0xEF): "zpxord", (1, 1, 0, 0x62): "zunpckldq", (1, 1, 0, 0x6A): "zunpckhdq", (1, 1, 1, 0x6C): "zunpcklqdq", (1, 1, 1, 0x6D): "zunpckhqdq"}
        if key in three:
            no_mask()
            if rm is None: raise Stop("a memory operand")
            return p - at, f".{three[key]} {reg} {v} {rm}"
        if key == (1, 1, 0, 0x72):
            no_mask()
            if reg != 0 or rm is None: raise Stop("0F 72 with another digit, or R set beside a digit")
            return p - at + 1, f".zprord {v} {rm} {tail()}"
        if key == (3, 1, 0, 0x43):
            no_mask()
            if rm is None: raise Stop("a memory operand")
            return p - at + 1, f".zshufi32x4 {reg} {v} {rm} {tail()}"
        if key == (3, 1, 0, 0x1E):
            no_mask()
            if rm is None or reg > 7: raise Stop("a compare this does not know")
            return p - at + 1, f".zpcmpud {reg} {v} {rm} {tail()}"
        if key == (2, 1, 0, 0x7C):
            no_mask(); no_v()
            if rm is None: raise Stop("a memory operand")
            if rm > 15: raise Stop("X set on a general register")
            return p - at, f".zbroadcast {reg} (.reg .{G[rm]})"
        if key == (2, 1, 0, 0x58):
            no_mask(); no_v()
            if rm is not None: raise Stop("a broadcast from a vector register")
            if mem[0] == "rip":
                off = data_at(mem[1], p)
                return p - at, f".zbroadcast {reg} (.imm 0x" + "".join(f"{x:02X}" for x in reversed(rodata[off:off + 4])) + ")"
            b, index, disp = mem
            if index: raise Stop("an indexed broadcast")
            return p - at, f".zbroadcast {reg} (.mem .{b} {bv(disp)})"
        raise Stop(f"an EVEX instruction this does not know: map {mm}, prefix {pp}, W {W}, opcode {opc:02X}")
    # general instructions, with an optional REX prefix
    W = R = X = B = 0
    rex = 0x40 <= op <= 0x4F
    if rex:
        W, R, X, B = (op >> 3) & 1, (op >> 2) & 1, (op >> 1) & 1, op & 1; op = u8()
        if not (W or R or X or B): raise Stop("an empty REX prefix")
    def only_b():
        if W or R or X: raise Stop("a REX bit this instruction does not use")
    def no_rex():
        if rex: raise Stop("a REX prefix this instruction does not use")
    w = 64 if W else 32
    r64 = lambda n: f"(.reg .{G[n]})"
    def memop(mem):
        b, index, disp = mem
        if index: raise Stop("an indexed operand of a general instruction")
        return f"(.mem .{b} {bv(disp)})"
    if 0x50 <= op <= 0x57: only_b(); return p - at, f".push .{G[(op - 0x50) | (B << 3)]}"
    if 0x58 <= op <= 0x5F: only_b(); return p - at, f".pop .{G[(op - 0x58) | (B << 3)]}"
    if op == 0xC3: no_rex(); return p - at, ".ret"
    if op == 0xB0: no_rex(); return p - at + 1, f".mov 8 (.reg .rax) (.imm {bv(imm(1))})"         # MOV AL, a byte
    if op == 0xFE:
        mod, reg, rm, mem = modrm(R, X, B)
        if rex or rm != 0 or reg != 1: raise Stop("FE other than DEC AL")
        return p - at, ".decb .rax"
    if 0xB8 <= op <= 0xBF:
        only_b()
        return p - at + 4, f".mov 32 {r64((op - 0xB8) | (B << 3))} (.imm {bv(imm(4))})"
    if op == 0xE8:
        no_rex(); field = p; imm(4)
        return p - at, f".call {relocs.callee(code, field, p)}"
    if op in (0x72, 0x73): no_rex(); d = sx(imm(1), 8); return p - at, f".{'jb' if op == 0x72 else 'jae'} {here(p + d)}"
    if op == 0xEB: no_rex(); d = sx(imm(1), 8); return p - at, f".jmp {here(p + d)}"
    if op == 0xE9: no_rex(); d = sx(imm(4), 32); return p - at, f".jmp {here(p + d)}"
    if op in (0x74, 0x75): no_rex(); d = sx(imm(1), 8); return p - at, f".{'je' if op == 0x74 else 'jne'} {here(p + d)}"
    if op == 0x0F:
        op2 = u8()
        if op2 in (0x84, 0x85): no_rex(); d = sx(imm(4), 32); return p - at, f".{'je' if op2 == 0x84 else 'jne'} {here(p + d)}"
        if op2 in (0x82, 0x83): no_rex(); d = sx(imm(4), 32); return p - at, f".{'jb' if op2 == 0x82 else 'jae'} {here(p + d)}"
        if op2 == 0xB6:
            mod, reg, rm, mem = modrm(R, X, B)
            if W: raise Stop("a movzx this does not know")
            if rm is None:
                if mem[0] == "rip": raise Stop("a movzx of read-only data")
                return p - at, f".movzx8 .{G[reg]} {memop(mem)}"
            if 4 <= rm <= 7: raise Stop("a movzx of AH, CH, DH, BH or their REX namesakes: not known here")
            return p - at, f".movzx8 .{G[reg]} {r64(rm)}"
        if op2 == 0x18:
            mod, reg, rm, mem = modrm(R, X, B)
            if rm is not None or reg != 1: raise Stop("0F 18 other than PREFETCHT0 of memory")
            return p - at, ".nop"
        raise Stop(f"0F {op2:02X}")
    if op in (0x05, 0x0D, 0x25, 0x2D, 0x3D):
        # the short forms with RAX and a 32-bit number (sign-extended to 64 bits)
        if R or X or B: raise Stop("a REX bit this instruction does not use")
        name = {0x05: "add", 0x0D: "or", 0x25: "and", 0x2D: "sub", 0x3D: "cmp"}[op]
        return p - at + 4, f".{name} {w} (.reg .rax) (.imm {bv(sx(imm(4), 32) if W else imm(4))})"
    if op in (0x03, 0x0B, 0x23, 0x2B, 0x3B):
        mod, reg, rm, mem = modrm(R, X, B)
        name = {0x03: "add", 0x0B: "or", 0x23: "and", 0x2B: "sub", 0x3B: "cmp"}[op]
        if rm is not None or mem[0] == "rip": raise Stop(f"{name} from a register in the form assemblers do not write, or from read-only data")
        return p - at, f".{name} {w} {r64(reg)} {memop(mem)}"
    if op == 0x88:
        mod, reg, rm, mem = modrm(R, X, B)
        if rex or rm is not None or reg != 0 or mem[0] == "rip": raise Stop("88 other than AL to memory")
        return p - at, f".mov 8 {memop(mem)} (.reg .rax)"
    if op == 0xD1:
        mod, reg, rm, mem = modrm(R, X, B)
        if rm is None or reg not in (4, 5): raise Stop("a shift this does not know")
        return p - at, f".{'shl' if reg == 4 else 'shr'}{w} .{G[rm]} 1"
    if op in (0x89, 0x31, 0x09, 0x85, 0x01, 0x29, 0x39, 0x21):
        mod, reg, rm, mem = modrm(R, X, B)
        name = {0x89: "mov", 0x31: "xor", 0x09: "or", 0x85: "test", 0x01: "add", 0x29: "sub", 0x39: "cmp", 0x21: "and"}[op]
        if rm is None:
            if name != "mov" or mem[0] == "rip": raise Stop(f"{name} to memory")
            return p - at, f".mov {w} {memop(mem)} {r64(reg)}"
        return p - at, f".{name} {w} {r64(rm)} {r64(reg)}"
    if op == 0x8B:
        mod, reg, rm, mem = modrm(R, X, B)
        if rm is not None or mem[0] == "rip": raise Stop("a mov this does not know")
        return p - at, f".mov {w} {r64(reg)} {memop(mem)}"
    if op == 0xC7:
        mod, reg, rm, mem = modrm(R, X, B)
        if rm is None or reg != 0 or not W: raise Stop("C7 other than a 32-bit number, sign-extended, to a 64-bit register")
        return p - at + 4, f".mov 64 {r64(rm)} (.imm {bv(sx(imm(4), 32))})"
    if op == 0xC6:
        mod, reg, rm, mem = modrm(R, X, B)
        if rm is not None or reg != 0 or mem[0] == "rip": raise Stop("C6 other than a byte to memory")
        return p - at + 1, f".mov 8 {memop(mem)} (.imm {bv(imm(1))})"
    if op in (0x81, 0x83):
        mod, reg, rm, mem = modrm(R, X, B)
        name = {0: "add", 1: "or", 4: "and", 5: "sub", 7: "cmp"}.get(reg)       # R set beside a digit: not known
        if rm is None or name is None: raise Stop("an arithmetic instruction this does not know")
        v = sx(imm(1), 8) if op == 0x83 else (sx(imm(4), 32) if W else imm(4))
        return p - at, f".{name} {w} {r64(rm)} (.imm {bv(v)})"
    if op == 0xC1:
        mod, reg, rm, mem = modrm(R, X, B)
        if rm is None or reg not in (4, 5): raise Stop("a shift this does not know")
        n = imm(1)
        if n >= w: raise Stop("a shift by the register's width or more")
        return p - at, f".{'shl' if reg == 4 else 'shr'}{w} .{G[rm]} {n}"
    if op == 0xFF:
        mod, reg, rm, mem = modrm(R, X, B)
        if rm is None or reg != 1: raise Stop("FF other than DEC of a register")
        return p - at, f".dec{w} .{G[rm]}"
    if op == 0x8D:
        mod, reg, rm, mem = modrm(R, X, B)
        if rm is not None or not W: raise Stop("a lea this does not know")
        # the address of the file's read-only data, so many bytes in: a row of its own, which no move of a number is
        if mem[0] == "rip": return p - at, f".lea_data .{G[reg]} {bv(data_at(mem[1], p))}"
        b, index, disp = mem
        if index: raise Stop("an indexed lea")
        return p - at, f".lea .{G[reg]} .{b} {bv(disp)}"
    raise Stop(f"an instruction this does not know: {code[at:at + 6].hex()}")


def place(e, symbol):
    """(the bytes the code is in, where `symbol` starts in them, the relocations or the settled file, the read-only data)"""
    if settled(e):
        s = Settled(e)
        if symbol not in s.at or not s.runs(s.at[symbol], s.at[symbol] + 1): raise Stop(f"no {symbol} in the file's code")
        return s.image, s.at[symbol], s, s.image
    sym = next((s for s in e.symbols if s["name"] == symbol and e.sections[s["shndx"]]["name"] == ".text"), None)
    if sym is None: raise Stop(f"no {symbol} in the object's .text")
    return e.bytes_of(".text"), sym["value"], Named(e), e.bytes_of(".rodata")


def address(obj, symbol):
    return place(Elf(obj), symbol)[1]


def read(obj, symbol, base, rodata_at):
    text, start, relocs, rodata = place(Elf(obj), symbol)
    at = start
    rows = []
    while True:
        n, ins = decode(text, at, relocs, rodata, rodata_at, base, start)
        if isinstance(relocs, Settled) and not relocs.runs(at, at + n): raise Stop("the code runs out of what is loaded to be run")
        rows.append((base + at - start, base + at - start + n, ins))
        at += n
        if ins == ".ret": break
        if at >= len(text): raise Stop("the code runs off the section")
    return rows, rodata


def features(obj, symbol):
    """What kinds of instruction the function at `symbol` holds, by how each is encoded: "avx512" (an EVEX
    prefix), "avx" (a VEX prefix), "sse41" (the 0F 38 and 0F 3A maps of the older encoding: SSSE3 and
    SSE4.1). The rest are the instructions every x86-64 processor has."""
    text, start, _, _ = place(Elf(obj), symbol)
    rows, _ = read(obj, symbol, 0, 0)
    out = set()
    for at, _, _ in rows:
        p = start + at
        while text[p] in (0x66, 0xF2, 0xF3): p += 1
        if text[p] == 0x62: out.add("avx512")
        elif text[p] in (0xC4, 0xC5): out.add("avx")
        else:
            if 0x40 <= text[p] <= 0x4F: p += 1
            if text[p] == 0x0F and text[p + 1] in (0x38, 0x3A): out.add("sse41")
    return out


def main():
    a = sys.argv[1:]
    compare = a and a[0] == "--compare"
    if compare: a = a[1:]
    obj, symbol, base, rodata_at = a[0], a[1], int(a[2], 16), int(a[3], 16)
    rows, rodata = read(obj, symbol, base, rodata_at)
    if compare:
        with open(a[4]) as f: theirs = [tuple(l.rstrip("\n").split("\t")) for l in f]
        lifters = lambda i: f".mov 64 (.reg {i.split()[1]}) (.imm {bv(rodata_at + int(i.split()[2], 16))})" if i.startswith(".lea_data ") else i
        ours = [(f"{x:X}", f"{y:X}", lifters(i)) for x, y, i in rows]
        with open(a[5]) as f: data = f.read().split()
        same_data = data == [f"{rodata_at:X}", rodata.hex().upper()]
        diff = [(o, t) for o, t in zip(ours, theirs) if o != t]
        print(f"{symbol}: {len(ours)} instructions decoded from the bytes, the lifter read {len(theirs)}: " + ("the same, every one" if not diff and len(ours) == len(theirs) else f"{len(diff)} DIFFER")
              + "; the read-only data " + ("the same" if same_data else "DIFFERS"))
        for o, t in diff[:8]: print("  ours  ", o, "\n  theirs", t)
        return 0 if not diff and len(ours) == len(theirs) and same_data else 1
    with open(a[4] + ".rows", "w") as f: f.write("".join(f"{x:X}\t{y:X}\t{i}\n" for x, y, i in rows))
    with open(a[4] + ".data", "w") as f: f.write(f"{rodata_at:X}\t{rodata.hex().upper()}\n")
    print(len(rows), "instructions")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Stop as e:
        print(f"kdecode: stopped: {e}"); sys.exit(1)
