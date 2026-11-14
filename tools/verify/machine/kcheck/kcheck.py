#!/usr/bin/env python3
"""kcheck: a trial of a checker made for one job (BLAKE3 #361, November 14, 2026).

Question: can a small program made for exactly this, and nothing else, show that a wide kernel's machine
code computes BLAKE3 for every input, in seconds and with no proof written by hand?

What it does, for `blake3_servil_avx512_k32` as the lifter read it from the object (the same rows Lean's
proofs are about):
  1. runs every instruction on symbolic values: a general register is a number, an address in a named
     region, or the packed flags by bytes; a ZMM register is sixteen 32-bit terms, one a lane; memory is
     named regions (the frame, the saved registers, the inputs' address table, the 32 inputs, the key,
     the object's read-only data, the output);
  2. builds, with the same term constructors, what the specification says each lane's chaining value is
     (sixteen blocks of BLAKE3's compression, written here from the paper's definition);
  3. compares the 256 words the code stored with the 256 the specification names. Terms are interned and
     sums and xors are kept flat and sorted, so "equal" is "the same node": no solver.
Beside the result it checks: no read outside what the contract gives, no write outside the frame, the saved
registers and the output; aligned stores on aligned addresses; the stack used within the contract's bound;
the registers a callee keeps are restored; every branch decided by numbers (no input decides one), every
address a region and a number (so the trace of addresses and branches is the same for every input).

Not a proof assistant, and nothing here is checked by one: this program is what would have to be trusted
(or itself proved, or made to emit a certificate). One arithmetic fact is taken as the specification's own
form: a lane's counter words, low + index and high + carry, which Lean proves equal to the 64-bit counter
plus the index (K32Lemmas.lean: counter_lo, counter_hi).

usage: kcheck.py k32|p32|p16 --object OBJECT [--anchor test_vectors.json] [--mutants]   (the library's object, read by kdecode.py)
       kcheck.py k32|p32|p16 ROWS DATA [--anchor test_vectors.json] [--mutants]      (ROWS, DATA: lift_one.py's OUT.rows and OUT.data)
"""
import re, sys, time

MASK32 = 0xFFFFFFFF
IV = [0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A]
PERM = [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8]
CHUNK_START, CHUNK_END = 1, 2


class Fail(Exception):
    pass


WIDEST = 64        # terms in one flat sum or xor. A state word gathers 8 a round: 57 after BLAKE3's 7 rounds


class Terms:
    """32-bit terms, interned: equal terms are one number."""
    def __init__(self):
        self.ids, self.nodes, self.widest = {}, [], 0

    def mk(self, *key):
        i = self.ids.get(key)
        if i is None:
            i = len(self.nodes); self.ids[key] = i; self.nodes.append(key)
        return i

    def const(self, n): return self.mk("c", n & MASK32)
    def var(self, *name): return self.mk("v", *name)

    def _flat(self, op, xs):
        out, c = [], 0
        for x in xs:
            k = self.nodes[x]
            if k[0] == op: out.extend(k[1:])
            elif k[0] == "c": c = (c + k[1]) & MASK32 if op == "add" else c ^ k[1]
            else: out.append(x)
        # a constant inside a flat node was folded when that node was made: fold again across nodes
        consts = [x for x in out if self.nodes[x][0] == "c"]
        for x in consts:
            c = (c + self.nodes[x][1]) & MASK32 if op == "add" else c ^ self.nodes[x][1]
        out = sorted(x for x in out if self.nodes[x][0] != "c")
        if c: out.append(self.const(c))
        # A changed kernel can double a sum on every turn of a loop (x + x, then that plus itself): stop it
        # here, where it costs nothing, not after the memory is gone.
        if len(out) > WIDEST: raise Fail(f"a sum or xor of {len(out)} terms: BLAKE3's widest has 57")
        self.widest = max(self.widest, len(out))
        if not out: return self.const(0)
        return out[0] if len(out) == 1 else self.mk(op, *out)

    def add(self, *xs): return self._flat("add", xs)
    def xor(self, *xs): return self._flat("xor", xs)

    def ror(self, x, n):
        k = self.nodes[x]
        if k[0] == "c": return self.const((k[1] >> n) | (k[1] << (32 - n)))
        return self.mk("ror", x, n)

    def ult(self, a, b): return self.mk("ult", a, b)
    def ite(self, c, a, b): return a if a == b else self.mk("ite", c, a, b)


# ---------------------------------------------------------------------------------------------------------
# The specification: BLAKE3's compression (section 2.2 of the paper), a chunk's chaining value (2.4, 2.5).
def spec_round(T, s, m):
    def g(a, b, c, d, x, y):
        s[a] = T.add(s[a], s[b], x); s[d] = T.ror(T.xor(s[d], s[a]), 16)
        s[c] = T.add(s[c], s[d]); s[b] = T.ror(T.xor(s[b], s[c]), 12)
        s[a] = T.add(s[a], s[b], y); s[d] = T.ror(T.xor(s[d], s[a]), 8)
        s[c] = T.add(s[c], s[d]); s[b] = T.ror(T.xor(s[b], s[c]), 7)
    g(0, 4, 8, 12, m[0], m[1]); g(1, 5, 9, 13, m[2], m[3]); g(2, 6, 10, 14, m[4], m[5]); g(3, 7, 11, 15, m[6], m[7])
    g(0, 5, 10, 15, m[8], m[9]); g(1, 6, 11, 12, m[10], m[11]); g(2, 7, 8, 13, m[12], m[13]); g(3, 4, 9, 14, m[14], m[15])


def spec_compress(T, cv, m, t_lo, t_hi, length, flags):
    s = list(cv) + [T.const(x) for x in IV] + [t_lo, t_hi, length, flags]
    m = list(m)
    for r in range(7):
        spec_round(T, s, m)
        m = [m[PERM[k]] for k in range(16)]
    return [T.xor(s[i], s[i + 8]) for i in range(8)]


def spec_counter(T, lane):
    """A lane's counter words: the 64-bit counter plus the lane's index, low word and high word."""
    lo, hi = T.var("counter low"), T.var("counter high")
    low = T.add(lo, T.const(lane))
    return low, T.ite(T.ult(low, lo), T.add(hi, T.const(1)), hi)


def spec_flags(T, extra): return T.var("flags") if extra == 0 else T.mk("or", T.var("flags"), extra)


def spec_chunk_cv(T, lane, blocks=16, increment=True):
    """Lane `lane`'s chunk: `blocks` blocks from the key, numbered counter + lane (or counter, for the entry that
    does not increment)."""
    cv = [T.var("key", w) for w in range(8)]
    t_lo, t_hi = spec_counter(T, lane) if increment else (T.var("counter low"), T.var("counter high"))
    for j in range(blocks):
        flags = spec_flags(T, (CHUNK_START if j == 0 else 0) | (CHUNK_END if j + 1 == blocks else 0))
        cv = spec_compress(T, cv, [T.var("input", lane, j, w) for w in range(16)], t_lo, t_hi, T.const(64), flags)
    return cv


# ---------------------------------------------------------------------------------------------------------
# The machine: the instructions of one/Machine.lean that the kernel uses, on symbolic values.
G64 = "rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15".split()
SAVED = ["rbx", "rbp", "r12", "r13", "r14", "r15"]


def parse(ins):
    toks = re.findall(r"\(|\)|[^\s()]+", ins)
    def read(i):
        if toks[i] == "(":
            out, i = [], i + 1
            while toks[i] != ")":
                x, i = read(i); out.append(x)
            return out, i + 1
        return toks[i], i + 1
    out, i = [], 0
    while i < len(toks):
        x, i = read(i); out.append(x)
    return out


def num(t): return int(t.split("#")[0], 16) if t.startswith("0x") else int(t.split("#")[0])
def signed(n): return n - (1 << 64) if n >> 63 else n


class Machine:
    def __init__(self, T, rows, data_at, data, kernel, stack_budget=4096):
        self.T, self.rows, self.data_at, self.data = T, {a: (n, parse(i)) for a, n, i in rows}, data_at, data
        self.budget, self.lanes, self.blocks = stack_budget, kernel["lanes"], kernel["blocks"]
        blocks = self.blocks
        # general registers: ("n", int) | ("a", region, offset) | ("p", bytes) packed flags | ("q", name) a 64-bit unknown
        self.g = {r: ("q", r + " at entry") for r in G64}
        self.g.update(rdi=("a", "inputs", 0), rsi=("n", blocks), rdx=("a", "key", 0), rcx=kernel["counter"],
                      r8=("p", kernel["packed"] + (0, 0, 0, 0)), r9=("a", "out", 0), rsp=("a", "stack", 0))
        self.z = [None] * 32            # sixteen terms each, or None: not yet written (reading it is a fault)
        self.k = {}
        self.zf = None
        self.frame = {}                 # 64-byte cells of the aligned frame, by offset
        self.saved = {}                 # 8-byte cells below the entry stack pointer, by offset
        self.out = {}
        self.low = 0                    # lowest address used, from the entry stack pointer (the frame's base is up to 63 lower)
        self.frame_at = None            # the frame's base is the entry stack pointer plus this, rounded down to 64
        self.frame_size = 0
        self.trace, self.steps, self.pc = [], 0, None
        self.saved[0] = ("q", "return address")

    # -- values
    def reg(self, r): return self.g[r.lstrip(".")]
    def setreg(self, r, v): self.g[r.lstrip(".")] = v

    def val(self, o, w):
        """An operand's value, of width w."""
        if o[0] == ".reg": v = self.reg(o[1])
        elif o[0] == ".imm": v = ("n", num(o[1]))
        else: v = self.load(self.addr(o[1], num(o[2])), w)
        return self.trunc(v, w)

    def trunc(self, v, w):
        if w == 64: return v
        if v[0] == "n": return ("n", v[1] & ((1 << w) - 1))
        if v[0] == "p": return ("p", v[1][:w // 8] + (0,) * (8 - w // 8))
        if v[0] == "q" and v[1] == "counter" and w == 32: return ("lo",)
        if v[0] == "hi" and w == 32: return v
        raise Fail(f"{w} bits of {v}")

    def addr(self, base, disp, index=None):
        b = self.reg(base)
        if b[0] != "a": raise Fail(f"an address from {base} = {b}")
        off = b[2] + signed(disp)
        if index is not None:
            i = self.reg(index)
            if i[0] != "n": raise Fail(f"an index that is not a number: {index} = {i}")
            off += i[1]
        return (b[1], off)

    # -- memory
    def load(self, at, w):
        region, off = at
        self.trace.append(("read", region, off, w))
        if region == "inputs" and w == 64 and off % 8 == 0 and 0 <= off < 8 * self.lanes: return ("a", ("input", off // 8), 0)
        if region == "rodata" and w == 32 and 0 <= off and off + 4 <= len(self.data): return ("n", int.from_bytes(self.data[off:off + 4], "little"))
        if region == "stack" and w == 64 and off in self.saved: return self.saved[off]
        raise Fail(f"a read of {w} bits at {region} + {off}")

    def load512(self, at, aligned):
        region, off = at
        self.trace.append(("read", region, off, 512))
        if region == "frame":
            if off % 64 or off not in self.frame: raise Fail(f"a wide read of the frame at {off}, not written")
            return self.frame[off]
        if aligned: raise Fail(f"an aligned wide read at {region} + {off}")
        if isinstance(region, tuple) and region[0] == "input" and off % 64 == 0 and 0 <= off < 64 * self.blocks:
            return tuple(self.T.var("input", region[1], off // 64, w) for w in range(16))
        raise Fail(f"a wide read at {region} + {off}")

    def store512(self, at, v, aligned):
        region, off = at
        self.trace.append(("write", region, off, 512))
        if v is None: raise Fail("a store of a register never written")
        if region == "frame" and off % 64 == 0 and 0 <= off and off + 64 <= self.frame_size: self.frame[off] = v
        elif region == "out" and not aligned and off % 64 == 0 and 0 <= off < 32 * self.lanes: self.out[off] = v
        else: raise Fail(f"a wide store at {region} + {off}")

    def word(self, at):
        """A 32-bit word of memory as a term: a word of the key."""
        self.trace.append(("read", at[0], at[1], 32))
        if at[0] != "key" or at[1] % 4 or not 0 <= at[1] < 32: raise Fail(f"a word read at {at}")
        return self.T.var("key", at[1] // 4)

    def vec(self, r):
        if self.z[r] is None: raise Fail(f"zmm{r} read before it is written")
        return self.z[r]

    def lane(self, v):
        """A 32-bit general value as a term."""
        T = self.T
        if v[0] == "n": return T.const(v[1])
        if v[0] == "lo": return T.var("counter low")
        if v[0] == "hi": return T.var("counter high")
        if v[0] == "p":
            b = v[1]
            if any(b[1:4]): raise Fail(f"a word of packed bytes {b}")
            if isinstance(b[0], int): return T.const(b[0])
            return spec_flags(T, b[0][1]) if isinstance(b[0], tuple) else T.var("flags")
        raise Fail(f"a lane from {v}")

    def stack_pointer(self):
        """The stack pointer for a push, a pop or a return: among the saved registers, not in the frame."""
        sp = self.reg("rsp")
        if sp[0] != "a" or sp[1] != "stack": raise Fail(f"a push, pop or return with the stack pointer at {sp}")
        return sp

    # -- one instruction
    def step(self):
        T = self.T
        nxt, i = self.rows[self.pc]
        op, a = i[0], i[1:]
        self.steps += 1
        if op == ".nop": pass
        elif op == ".vzeroupper":       # ZMM0 to ZMM15 cleared above bit 127
            for r in range(16):
                if self.z[r] is not None: self.z[r] = self.z[r][:4] + (T.const(0),) * 12
        elif op == ".mov":
            w = int(a[0]); v = self.val(a[2], w)
            if a[1][0] == ".reg":
                if w == 8: raise Fail("a byte moved into a register (the other 56 bits stay: not modelled here)")
                self.setreg(a[1][1], v)
            else:
                at = self.addr(a[1][1], num(a[1][2]))
                if not (w == 8 and at[0] == "frame" and 0 <= at[1] < self.frame_size and v == ("n", 0)): raise Fail(f"a store of {w} bits at {at}")
                self.trace.append(("write", at[0], at[1], 8))       # the stack probe: one byte of the frame, before any wide store there
                if at[1] - at[1] % 64 in self.frame: raise Fail("a byte stored over a wide cell")
        elif op == ".movzx8": self.setreg(a[0], self.val(a[1], 8))
        elif op in (".jmp",): nxt = num(a[0]); self.trace.append(("jump", nxt))
        elif op in (".je", ".jne"):
            if self.zf is None: raise Fail("a branch on a flag no number decided")
            if self.zf == (op == ".je"): nxt = num(a[0])
            self.trace.append(("branch", nxt))
        elif op == ".push":
            sp = self.stack_pointer()
            self.saved[sp[2] - 8] = self.reg(a[0]); self.setreg("rsp", ("a", "stack", sp[2] - 8)); self.low = min(self.low, sp[2] - 8)
            self.trace.append(("write", "stack", sp[2] - 8, 64))
        elif op == ".pop":
            sp = self.stack_pointer(); self.setreg(a[0], self.load(("stack", sp[2]), 64)); self.setreg("rsp", ("a", "stack", sp[2] + 8))
        elif op == ".ret":
            sp = self.stack_pointer(); to = self.load(("stack", sp[2]), 64); self.setreg("rsp", ("a", "stack", sp[2] + 8))
            if to != ("q", "return address"): raise Fail("a return to somewhere else")
            self.pc = None; return
        elif op == ".lea":
            b = self.reg(a[1])
            if b[0] != "a": raise Fail("lea from a non-address")
            self.setreg(a[0], ("a", b[1], b[2] + signed(num(a[2]))))
        elif op == ".and":
            if a[1][0] != ".reg" or a[2][0] != ".imm": raise Fail("and of other than a register and a number")
            w = int(a[0]); d = self.reg(a[1][1]); m = num(a[2][1])
            if w == 64 and a[1][1] == ".rsp" and m == 0xFFFFFFFFFFFFFFC0 and d[0] == "a" and d[1] == "stack":
                self.frame_at = d[2]; self.setreg("rsp", ("a", "frame", 0)); self.frame_size = 0     # the frame's base: rounded down to 64 bytes
            elif w == 32 and m == 0xFF: self.setreg(a[1][1], self.trunc(self.val(a[1], 32), 8))
            else: raise Fail(f"and {a}")
            self.zf = None
        elif op in (".sub", ".add"):
            if a[1][0] != ".reg" or a[2][0] != ".imm": raise Fail(f"{op} of other than a register and a number")
            w = int(a[0]); d = self.reg(a[1][1]); n = num(a[2][1]) * (1 if op == ".add" else -1)
            if d[0] == "a" and w != 64: raise Fail(f"{op} of {w} bits on an address")
            if d[0] == "a" and d[1] == "frame" and op == ".sub" and d[2] == 0 and not self.frame and self.frame_size == 0:
                # the frame grows down from its aligned top: its base is the new stack pointer, and stays
                # on a 64-byte boundary only if the frame is whole cells (the aligned stores rest on that:
                # kflip.py found frames of 0x101 to 0x120 bytes accepted here, which fault on a processor)
                if n >= 0 or n % 64: raise Fail(f"a frame of {-n} bytes: not whole 64-byte cells")
                self.frame_size = -n; self.low = min(self.low, self.frame_at - 63 - self.frame_size)
            elif d[0] == "n": self.setreg(a[1][1], ("n", (d[1] + n) & ((1 << w) - 1)))
            elif d[0] == "a" and d[1] == "rodata": self.setreg(a[1][1], ("a", d[1], d[2] + n))
            else: raise Fail(f"{op} on {d}")
            self.zf = None
        elif op == ".xor":
            if a[1] != a[2]: raise Fail("xor of two registers")
            self.setreg(a[1][1], ("n", 0)); self.zf = True
        elif op == ".or":
            if a[0] != "32" or a[1][0] != ".reg": raise Fail("an or that is not of 32 bits into a register")
            x, y = self.val(a[1], 32), self.val(a[2], 32)
            if x[0] == "n" and y[0] == "n": self.setreg(a[1][1], ("n", x[1] | y[1]))
            elif x[0] == "p" and y[0] == "p":
                bx, by = x[1], y[1]
                if any(bx[1:]) or any(by[1:]): raise Fail(f"or of {x} and {y}")
                self.setreg(a[1][1], ("p", (or8(bx[0], by[0]),) + (0,) * 7))
            else: raise Fail(f"or of {x} and {y}")
            self.zf = None
        elif op in (".shr64", ".shr32"):
            v = self.reg(a[0]); n = num(a[1])
            if op == ".shr64" and v == ("q", "counter") and n == 32: self.setreg(a[0], ("hi",))
            elif op == ".shr64" and v[0] == "n": self.setreg(a[0], ("n", v[1] >> (n & 63)))
            elif op == ".shr32" and v[0] == "n": self.setreg(a[0], ("n", (v[1] & MASK32) >> (n & 31)))
            elif op == ".shr32" and v[0] == "p" and n % 8 == 0: self.setreg(a[0], ("p", v[1][n // 8:4] + (0,) * (4 + n // 8)))
            else: raise Fail(f"{op} {v} {n}")
            self.zf = None
        elif op in (".test", ".cmp"):
            x, y = self.val(a[1], int(a[0])), self.val(a[2], int(a[0]))
            if x[0] != "n" or y[0] != "n": raise Fail(f"{op} of values no number decides: {x}, {y}")
            self.zf = ((x[1] & y[1]) if op == ".test" else (x[1] - y[1])) == 0
        elif op in (".dec32", ".dec64"):
            v = self.reg(a[0])
            if v[0] != "n": raise Fail("dec of a non-number")
            n = (v[1] - 1) & (MASK32 if op == ".dec32" else (1 << 64) - 1); self.setreg(a[0], ("n", n)); self.zf = n == 0
        elif op == ".zbroadcast":
            t = self.word(self.addr(a[1][1], num(a[1][2]))) if a[1][0] == ".mem" else self.lane(self.val(a[1], 32))
            self.z[int(a[0])] = (t,) * 16
        elif op == ".zmov": self.z[int(a[0])] = self.vec(int(a[1]))
        elif op == ".zload": self.z[int(a[1])] = self.load512(self.addr(a[2], num(a[3])), a[0] == "true")
        elif op == ".zloadi": self.z[int(a[0])] = self.load512(self.addr(a[1], num(a[3]), a[2]), False)
        elif op == ".zstore": self.store512(self.addr(a[1], num(a[2])), self.vec(int(a[3])), a[0] == "true")
        elif op == ".zpaddd": x, y = self.vec(int(a[1])), self.vec(int(a[2])); self.z[int(a[0])] = tuple(T.add(p, q) for p, q in zip(x, y))
        elif op == ".zpxord": x, y = self.vec(int(a[1])), self.vec(int(a[2])); self.z[int(a[0])] = tuple(T.xor(p, q) for p, q in zip(x, y))
        elif op == ".zprord": x = self.vec(int(a[1])); n = int(a[2]); self.z[int(a[0])] = tuple(T.ror(p, n) for p in x)
        elif op == ".zpadddc":
            c = num(a[2]); x = self.vec(int(a[1]))
            self.z[int(a[0])] = tuple(T.add(p, T.const((c >> (32 * i)) & MASK32)) for i, p in enumerate(x))
        elif op == ".zpadddm":
            y = self.load512(self.addr(a[2], num(a[4]), a[3]), False); x = self.vec(int(a[1]))
            self.z[int(a[0])] = tuple(T.add(p, q) for p, q in zip(x, y))
        elif op == ".zpcmpud":
            if int(a[3]) != 1: raise Fail("a comparison other than less-than")
            x, y = self.vec(int(a[1])), self.vec(int(a[2])); self.k[int(a[0])] = tuple(T.ult(p, q) for p, q in zip(x, y))
        elif op == ".zpaddd_k":
            d, k, x, y = self.vec(int(a[0])), self.k[int(a[1])], self.vec(int(a[2])), self.vec(int(a[3]))
            self.z[int(a[0])] = tuple(T.ite(c, T.add(p, q), old) for c, p, q, old in zip(k, x, y, d))
        elif op in (".zunpckldq", ".zunpckhdq", ".zunpcklqdq", ".zunpckhqdq"):
            x, y = self.vec(int(a[1])), self.vec(int(a[2]))
            pick = {".zunpckldq": lambda q: (x[q], y[q], x[q + 1], y[q + 1]), ".zunpckhdq": lambda q: (x[q + 2], y[q + 2], x[q + 3], y[q + 3]),
                    ".zunpcklqdq": lambda q: (x[q], x[q + 1], y[q], y[q + 1]), ".zunpckhqdq": lambda q: (x[q + 2], x[q + 3], y[q + 2], y[q + 3])}[op]
            self.z[int(a[0])] = sum((pick(q) for q in (0, 4, 8, 12)), ())
        elif op == ".zshufi32x4":
            x, y, imm = self.vec(int(a[1])), self.vec(int(a[2])), int(a[3])
            quarter = lambda v, q: v[4 * q:4 * q + 4]
            self.z[int(a[0])] = quarter(x, imm % 4) + quarter(x, imm // 4 % 4) + quarter(y, imm // 16 % 4) + quarter(y, imm // 64 % 4)
        else: raise Fail(f"an instruction this checker does not know: {' '.join(map(str, i))}")
        self.pc = nxt

    def run(self, entry, limit=200000):
        self.pc = entry
        entry_regs = {r: self.g[r] for r in SAVED}
        while self.pc is not None:
            if self.pc not in self.rows: raise Fail(f"no instruction at 0x{self.pc:X}")
            if self.steps >= limit: raise Fail("still running")
            # the schedule's address is a number the lifter wrote: it names the object's read-only data
            nxt, i = self.rows[self.pc]
            if i[0] == ".mov" and i[1] == "64" and i[3][0] == ".imm" and num(i[3][1]) >= self.data_at and num(i[3][1]) < self.data_at + len(self.data):
                self.setreg(i[2][1], ("a", "rodata", num(i[3][1]) - self.data_at)); self.steps += 1; self.pc = nxt; continue
            self.step()
        for r in SAVED:
            if self.g[r] != entry_regs[r]: raise Fail(f"{r} is not restored")
        if self.g["rsp"] != ("a", "stack", 8): raise Fail(f"the stack pointer at the return: {self.g['rsp']}")
        if -self.low > self.budget: raise Fail(f"{-self.low} bytes of stack used, the contract gives {self.budget}")


def check(rows, data_at, data, name="k32", entry=None):
    kernel = KERNELS[name]
    T = Terms()
    m = Machine(T, rows, data_at, data, kernel)
    m.run(rows[kernel["entry"]][0] if entry is None else entry)
    want = [kernel["spec"](T, lane) for lane in range(kernel["lanes"])]
    for lane in range(kernel["lanes"]):
        for w in range(8):
            word = 8 * lane + w
            cell = m.out.get(64 * (word // 16))
            if cell is None: raise Fail(f"the output at {64 * (word // 16)} is not written")
            if cell[word % 16] != want[lane][w]: raise Fail(f"word {w} of lane {lane}'s chaining value is not the specification's")
    return m, T


def spec_parent_cv(T, lane):
    """Lane `lane`'s parent node (section 2.5): one block, the two children's chaining values, counter 0, PARENT."""
    return spec_compress(T, [T.var("key", w) for w in range(8)], [T.var("input", lane, 0, w) for w in range(16)],
                         T.const(0), T.const(0), T.const(64), spec_flags(T, 4))


# What each kernel is given (its contract's `accepts`), and what it must leave.
KERNELS = {
    "k32": dict(entry=0, start="blake3_servil_avx512_k32", lanes=32, blocks=16, counter=("q", "counter"), packed=("flags", CHUNK_START, CHUNK_END, 64), spec=lambda T, lane: spec_chunk_cv(T, lane)),
    "p32": dict(entry=3, start="blake3_servil_avx512_k32", lanes=32, blocks=16, counter=("q", "counter"), packed=("flags", CHUNK_START, CHUNK_END, 64), spec=lambda T, lane: spec_chunk_cv(T, lane, increment=False)),
    "p16": dict(entry=0, start="blake3_servil_avx512_p16", lanes=16, blocks=1, counter=("n", 0), packed=(("flags|", 4), 0, 0, 64), spec=spec_parent_cv),
}


def or8(x, y):
    """The or of two bytes, each a number, the mode flags, or the mode flags with bits set."""
    if isinstance(x, int) and isinstance(y, int): return x | y
    bits = lambda b: b if isinstance(b, int) else (b[1] if isinstance(b, tuple) else 0)
    c = bits(x) | bits(y)
    return ("flags|", c) if c else "flags"


def evaluate(T, env):
    """Every term's value under an assignment of the variables (a term's parts were made before it)."""
    val = [0] * len(T.nodes)
    rot = lambda x, n: ((x >> n) | (x << (32 - n))) & MASK32
    for i, k in enumerate(T.nodes):
        op = k[0]
        if op == "c": val[i] = k[1]
        elif op == "v": val[i] = env[k[1:]]
        elif op == "add": val[i] = sum(val[x] for x in k[1:]) & MASK32
        elif op == "xor":
            v = 0
            for x in k[1:]: v ^= val[x]
            val[i] = v
        elif op == "ror": val[i] = rot(val[k[1]], k[2])
        elif op == "ult": val[i] = int(val[k[1]] < val[k[2]])
        elif op == "ite": val[i] = val[k[2]] if val[k[1]] else val[k[3]]
        elif op == "or": val[i] = val[k[1]] | k[2]
        else: raise Fail(f"a term this evaluator does not know: {k}")
    return val


def anchor(vectors_path):
    """The specification written here against the official test vectors: the hash of the 2048-byte input is the
    root of two chunks, so lanes 0 and 1 of the symbolic specification (the same terms the code was compared
    with), given that input's two chunks, the IV as key, counter 0 and no mode flags, must give the two
    chaining values whose parent's root output is that hash. Lane 1's counter is 1: the lane index is in it."""
    import json
    with open(vectors_path) as f: cases = {c["input_len"]: c["hash"] for c in json.load(f)["cases"]}
    data = bytes(i % 251 for i in range(2048))
    T = Terms()
    cvs = [spec_chunk_cv(T, lane) for lane in (0, 1)]
    env = {("counter low",): 0, ("counter high",): 0, ("flags",): 0}
    env.update({("key", w): IV_FULL[w] for w in range(8)})
    for k in T.nodes:
        if k[0] == "v" and k[1] == "input":
            lane, blk, w = k[2:]
            env[k[1:]] = int.from_bytes(data[1024 * lane + 64 * blk + 4 * w:][:4], "little")
    val = evaluate(T, env)
    left, right = ([val[x] for x in cv] for cv in cvs)
    C = Terms(); c = C.const
    root = spec_compress(C, [c(x) for x in IV_FULL], [c(x) for x in left + right], c(0), c(0), c(64), c(4 | 8))    # PARENT | ROOT
    got = b"".join(C.nodes[x][1].to_bytes(4, "little") for x in root).hex()
    if got != cases[2048][:64]: raise Fail(f"the specification written here gives {got} for the 2048-byte test vector, the vector says {cases[2048][:64]}")
    return got


IV_FULL = IV + [0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19]


def read(rows_path, data_path):
    with open(rows_path) as f: rows = [(int(a, 16), int(n, 16), i) for a, n, i in (l.rstrip("\n").split("\t") for l in f)]
    with open(data_path) as f: at, hexs = f.read().split()
    return rows, int(at, 16), bytes.fromhex(hexs)


MUTANTS = [("a rotation 12 -> 13", ".zprord 4 4 12", ".zprord 4 4 13"), ("a rotation 7 -> 8, second half", ".zprord 12 12 7", ".zprord 12 12 8"),
           ("an xor's source", ".zpxord 20 20 0", ".zpxord 20 20 1"), ("the mask of the carry", ".zpaddd_k 5 1 1 4", ".zpaddd_k 5 2 1 4"),
           ("the comparison's operands", ".zpcmpud 1 2 0 1", ".zpcmpud 1 0 2 1"), ("a message word's offset", ".zpadddm 9 9 .rsi .rcx 0x400", ".zpadddm 9 9 .rsi .rcx 0x0"),
           ("an output store's offset", ".zstore false .r15 0x100 4", ".zstore false .r15 0x140 4"), ("a transpose's shuffle", ".zshufi32x4 30 31 18 136", ".zshufi32x4 30 31 18 221"),
           ("the end flag's shift", ".shr32 .rcx 16", ".shr32 .rcx 8"), ("the start flag left out", ".or 32 (.reg .rax) (.reg .rdx)", ".nop"),
           ("the feed-forward's register", ".zpxord 3 3 19", ".zpxord 3 3 18"), ("a callee-saved register not restored", ".pop .r13", ".pop .rax"),
           ("a store below the frame", ".zstore true .rsp 0x900 15", ".zstore true .rsp 0x940 15"), ("the block offset's step", ".add 64 (.reg .r14) (.imm 0x40)", ".add 64 (.reg .r14) (.imm 0x80)")]


def main():
    name = sys.argv[1]
    entry = None
    t0 = time.time()
    if sys.argv[2] == "--object":
        # the object's bytes themselves, decoded by kdecode.py: no disassembler. The code is read from the symbol
        # the kernel's body begins at (P32 enters K32's), and run from the kernel's own symbol.
        import kdecode
        try:
            rows, data = kdecode.read(sys.argv[3], KERNELS[name]["start"], 0x10000, 0x50000000)
            entry = 0x10000 + kdecode.address(sys.argv[3], "blake3_servil_avx512_" + name) - kdecode.address(sys.argv[3], KERNELS[name]["start"])
        except kdecode.Stop as e: raise Fail(f"the object is not read: {e}")
        data_at = 0x50000000
    else: rows, data_at, data = read(sys.argv[2], sys.argv[3])
    m, T = check(rows, data_at, data, name, entry)
    dt = time.time() - t0
    kinds = {}
    for e in m.trace: kinds[e[0]] = kinds.get(e[0], 0) + 1
    print(f"{name}: the {KERNELS[name]['lanes']} chaining values the code stores are the specification's, for every key, flags and input" + ("" if name == "p16" else " and every counter"))
    print(f"     {m.steps} instructions run, {len(T.nodes)} terms, {dt:.2f} s; stack used at most {-m.low} bytes of {m.budget}")
    print(f"     trace: {kinds.get('read', 0)} reads, {kinds.get('write', 0)} writes, {kinds.get('branch', 0)} branches, each a region and a number: the same for every input")
    if "--anchor" in sys.argv:
        t1 = time.time(); got = anchor(sys.argv[sys.argv.index("--anchor") + 1])
        print(f"     the specification's terms, evaluated on the official 2048-byte test vector (two chunks, counters 0 and 1): {got[:16]}... as the vector says ({time.time() - t1:.2f} s)")
    if "--mutants" in sys.argv:
        assert name == "k32", "the changed kernels are K32's"
        caught = 0
        for name, old, new in MUTANTS:
            hits = [k for k, r in enumerate(rows) if r[2] == old]
            if not hits: print(f"  mutant ({name}): NOT MADE, no instruction `{old}`"); continue
            changed = list(rows); a, n, _ = changed[hits[0]]; changed[hits[0]] = (a, n, new)
            t1 = time.time()
            try:
                check(changed, data_at, data, "k32", entry); print(f"  mutant ({name}): ACCEPTED (bad)")
            except Fail as e:
                caught += 1; print(f"  mutant ({name}): refused in {time.time() - t1:.2f} s: {e}")
        bad = bytearray(data); bad[0xC0 + 64 + 4] ^= 0x40
        try:
            check(rows, data_at, bytes(bad), "k32", entry); print("  mutant (one entry of the schedule table): ACCEPTED (bad)")
        except Fail as e:
            caught += 1; print(f"  mutant (one entry of the schedule table): refused: {e}")
        print(f"mutants: {caught} of {len(MUTANTS) + 1} refused")


if __name__ == "__main__":
    try:
        main()
    except Fail as e:
        print(f"{sys.argv[1]}: NOT shown: {e}"); sys.exit(1)
