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
RODATA, as the lifter places it; `lea reg, [rip + data]` is that data's address."""
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
        shoff, = struct.unpack_from("<Q", b, 40); shentsize, shnum, shstrndx = struct.unpack_from("<HHH", b, 58)
        self.sections = []
        for i in range(shnum):
            name, typ, flags, addr, off, size, link, info, align, entsize = struct.unpack_from("<IIQQQQIIQQ", b, shoff + i * shentsize)
            self.sections.append(dict(name=name, type=typ, off=off, size=size, link=link, info=info))
        names = self.sections[shstrndx]
        cstr = lambda sec, at: b[sec["off"] + at:b.index(b"\0", sec["off"] + at)].decode()
        for s in self.sections: s["name"] = cstr(names, s["name"])
        symtab = next(s for s in self.sections if s["type"] == 2)
        strtab = self.sections[symtab["link"]]
        self.symbols = []
        for i in range(symtab["size"] // 24):
            name, info, other, shndx, value, size = struct.unpack_from("<IBBHQQ", b, symtab["off"] + 24 * i)
            self.symbols.append(dict(name=cstr(strtab, name), type=info & 15, shndx=shndx, value=value))
        self.index = {s["name"]: i for i, s in enumerate(self.sections)}

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


def decode(code, at, relocs, rodata, rodata_at, base, start):
    """One instruction at `at`: (its length, its text in the lifter's form)."""
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

    def data_at(field, end):
        if field not in relocs: raise Stop("a RIP-relative operand with no relocation")
        sec, off = relocs[field]
        if sec != ".rodata": raise Stop(f"an operand in {sec}")
        return off + (end - field)

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
        if mm != 1 or pp == 3: raise Stop("a VEX instruction this does not know")
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
        if relocs.get(field, ("", ""))[0] != "call": raise Stop("a call with no function named")
        return p - at, f".call {relocs[field][1]}"
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
        if mem[0] == "rip": return p - at, f".mov 64 {r64(reg)} (.imm {bv(rodata_at + data_at(mem[1], p))})"
        b, index, disp = mem
        if index: raise Stop("an indexed lea")
        return p - at, f".lea .{G[reg]} .{b} {bv(disp)}"
    raise Stop(f"an instruction this does not know: {code[at:at + 6].hex()}")


def address(obj, symbol):
    e = Elf(obj)
    sym = next((s for s in e.symbols if s["name"] == symbol and e.sections[s["shndx"]]["name"] == ".text"), None)
    if sym is None: raise Stop(f"no {symbol} in the object's .text")
    return sym["value"]


def read(obj, symbol, base, rodata_at):
    e = Elf(obj)
    text, rodata, relocs = e.bytes_of(".text"), e.bytes_of(".rodata"), e.relocations(".text")
    sym = next((s for s in e.symbols if s["name"] == symbol and e.sections[s["shndx"]]["name"] == ".text"), None)
    if sym is None: raise Stop(f"no {symbol} in the object's .text")
    start = at = sym["value"]
    rows = []
    while True:
        n, ins = decode(text, at, relocs, rodata, rodata_at, base, start)
        rows.append((base + at - start, base + at - start + n, ins))
        at += n
        if ins == ".ret": break
        if at >= len(text): raise Stop("the code runs off the section")
    return rows, rodata


def features(obj, symbol):
    """What kinds of instruction the function at `symbol` holds, by how each is encoded: "avx512" (an EVEX
    prefix), "avx" (a VEX prefix), "sse41" (the 0F 38 and 0F 3A maps of the older encoding: SSSE3 and
    SSE4.1). The rest are the instructions every x86-64 processor has."""
    e = Elf(obj)
    text = e.bytes_of(".text")
    start = next(s["value"] for s in e.symbols if s["name"] == symbol and e.sections[s["shndx"]]["name"] == ".text")
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
        ours = [(f"{x:X}", f"{y:X}", i) for x, y, i in rows]
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
