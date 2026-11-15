#!/usr/bin/env python3
"""kone: the one-block kernels, whose contract the callers of kglue.py take.

    python3 kone.py avx512|sse41 OBJECT

`blake3_servil_compress_in_place_avx512` and `_sse41` (c/blake3_avx512_x86-64_unix.S, c/blake3_sse41_x86-64_unix.S):
(cv, block, block_len, counter, flags): the 32 bytes at cv become the first eight words of BLAKE3's compression
of them with the 64 bytes at block. kglue.py first took their contract as I wrote it by hand, and it was wrong
for the SSE4.1 kernel (which reads all of EDX for the length, not its low byte). Here the contract is CHECKED
against the kernel's bytes, in kcheck.py's way: the instructions are run on symbols (an XMM register is four
32-bit terms), the specification's `compress` (blake3.spec) is built on the same symbols, and the eight words
stored are compared by identity.

What each kernel is claimed to do is its `contract` in blake3.spec, and shown for every cv, block and counter:
  avx512   cv <- compress(cv, block, counter, the low byte of RDX, the low byte of R8), whatever else RDX and R8 hold
  sse41    cv <- compress(cv, block, counter, EDX, the low word of R8), IF RDX is below 2^32 (its upper half would
           be added into the flags' word: the contract's `word`); whatever the upper half of R8 holds
Both: nothing is read but the 32 bytes at cv, the 64 at block and the object's constants; nothing is written
but the 32 bytes at cv; no stack is used and no register a callee keeps is written; the seven rounds' branch is
decided by a number. kglue.py's table of what a caller must show (COMPRESS) is read from CONTRACTS here."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode, kspec, ode
from kcheck import Fail, num, signed

BASE, DATA = 0x10000, 0x50000000
KEPT = kcheck.SAVED

def contract_of(symbol):
    """A one-block kernel's contract, as blake3.spec states it: (cv, block, length, counter, flags) in the calling
    convention's order, the length a `low byte` or a `word`, the flags a `low byte` or a `low word`, and what the
    chaining value is left as."""
    c = kspec.SPEC.contracts[symbol]
    kinds = [kind for _, kind in c["args"]]
    if len(kinds) != 5 or kinds[0] != "cv" or kinds[1] != "block" or kinds[2] not in ("low byte", "word") or kinds[3] != "counter" or kinds[4] not in ("low byte", "low word"):
        raise Fail(f"{symbol}: not a one-block kernel's contract: {kinds}")
    if c["stack"] != 0 or c["leaves"][0]["name"] != c["args"][0][0] or c["leaves"][0]["index"] is not None or c["asks"] or c["returns"] is not None: raise Fail(f"{symbol}: a one-block kernel leaves its chaining value, uses no stack, asks and returns nothing")
    return dict(symbol=symbol, length=kinds[2], flags=kinds[4], names=[arg for arg, _ in c["args"]], leaves=c["leaves"][0]["expr"])


def contracts(): return {name: contract_of("blake3_servil_compress_in_place_" + name) for name in ("avx512", "sse41")}


CONTRACTS = contracts()


class Machine:
    """General registers hold: ("q", name) an unknown 64 bits; ("w", term) a 32-bit term, zero above; ("pair",
    low, high) two 32-bit terms; ("a", region, offset); ("al", n) a number in AL, the rest unknown."""
    def __init__(self, T, rows, contract):
        self.T, self.rows = T, {a: (n, kcheck.parse(i)) for a, n, i in rows}
        self.g = {r: ("q", r) for r in kcheck.G64}
        self.g.update(rdi=("a", "cv", 0), rsi=("a", "block", 0), rsp=("a", "stack", 0),
                      rcx=("pair", T.var("counter low"), T.var("counter high")))
        if contract["length"] == "word": self.g["rdx"] = ("w", T.var("edx"))       # the contract's `word`: RDX below 2^32
        self.x, self.zf, self.out, self.steps, self.pc = {}, None, {}, 0, None
        self.cv = [T.var("cv", w) for w in range(8)]
        self.block = [T.var("input", w) for w in range(16)]

    def lanes(self, r):
        if r not in self.x: raise Fail(f"xmm{r} read before it is written")
        return self.x[r]

    def plain(self, r):
        v = self.lanes(r)
        if any(isinstance(t, tuple) for t in v): raise Fail(f"xmm{r} holds half of a rotation")
        return v

    def address(self, base, disp):
        b = self.g[base.lstrip(".")]
        if b[0] != "a": raise Fail(f"an address from {base} = {b}")
        return b[1], b[2] + signed(num(disp))

    def one(self):
        T = self.T
        if self.pc not in self.rows: raise Fail(f"no instruction at 0x{self.pc:X}")
        if self.steps >= 5000: raise Fail("still running")
        nxt, i = self.rows[self.pc]
        op, a = i[0], i[1:]
        reg = lambda name: name.lstrip(".")
        if op == ".nop": pass
        elif op == ".xloadu":
            region, off = self.address(a[1], a[2])
            if region == "cv" and off in (0, 16): self.x[int(a[0])] = tuple(self.cv[off // 4:off // 4 + 4])
            elif region == "block" and off in (0, 16, 32, 48): self.x[int(a[0])] = tuple(self.block[off // 4:off // 4 + 4])
            else: raise Fail(f"a read of 16 bytes at {region} + {off}")
        elif op == ".xstoreu":
            region, off = self.address(a[0], a[1])
            if region != "cv" or off not in (0, 16): raise Fail(f"a write of 16 bytes at {region} + {off}")
            self.out[off] = self.plain(int(a[2]))
        elif op == ".xconst": self.x[int(a[0])] = tuple(T.const(num(w)) for w in a[1:5])
        elif op == ".xmov": self.x[int(a[0])] = self.lanes(int(a[1]))
        elif op == ".xmovq":
            v = self.g[reg(a[1])]
            if v[0] == "pair": self.x[int(a[0])] = (v[1], v[2], T.const(0), T.const(0))
            elif v[0] == "w": self.x[int(a[0])] = (v[1], T.const(0), T.const(0), T.const(0))
            else: raise Fail(f"a general register moved to a vector register: {v}")
        elif op in (".xpaddd", ".xpxor"):
            x, y = self.plain(int(a[1])), self.plain(int(a[2]))
            self.x[int(a[0])] = tuple((T.add if op == ".xpaddd" else T.xor)(p, q) for p, q in zip(x, y))
        elif op in (".xpslld", ".xpsrld"):
            n = int(a[2])
            if not 0 < n < 32: raise Fail("a shift by nothing, or by the word's width")
            self.x[int(a[0])] = tuple(("shl" if op == ".xpslld" else "shr", t, n) for t in self.plain(int(a[1])))
        elif op == ".xpor":
            # the two halves of a rotation: (x << (32 - n)) | (x >> n)
            out = []
            for p, q in zip(self.lanes(int(a[1])), self.lanes(int(a[2]))):
                if not (isinstance(p, tuple) and isinstance(q, tuple)): raise Fail("an or that is not of a rotation's halves")
                if p[0] == "shr": p, q = q, p
                if not (p[0] == "shl" and q[0] == "shr" and p[1] == q[1] and p[2] + q[2] == 32): raise Fail("an or that is not of a rotation's halves")
                out.append(T.ror(q[1], q[2]))
            self.x[int(a[0])] = tuple(out)
        elif op == ".xprord": self.x[int(a[0])] = tuple(T.ror(t, int(a[2])) for t in self.plain(int(a[1])))
        elif op == ".xpshufb":
            # a shuffle of bytes by a constant that rotates each word's bytes: a rotation of each word by whole bytes
            src, mask, out = self.plain(int(a[1])), self.lanes(int(a[2])), []
            for lane, m in enumerate(mask):
                k = T.nodes[m] if not isinstance(m, tuple) else None
                if k is None or k[0] != "c": raise Fail("a shuffle of bytes by something that is not a constant")
                idx = [(k[1] >> (8 * j)) & 0xFF for j in range(4)]
                r = idx[0] - 4 * lane
                if not 0 <= r < 4 or any(idx[j] != 4 * lane + (r + j) % 4 for j in range(4)): raise Fail("a shuffle of bytes that is not a rotation of each word")
                out.append(T.ror(src[lane], 8 * r) if r else src[lane])
            self.x[int(a[0])] = tuple(out)
        elif op == ".xpshufd":
            s, n = self.plain(int(a[1])), int(a[2]); self.x[int(a[0])] = tuple(s[(n >> (2 * j)) & 3] for j in range(4))
        elif op == ".xshufps":
            x, y, n = self.plain(int(a[1])), self.plain(int(a[2])), int(a[3])
            self.x[int(a[0])] = (x[n & 3], x[(n >> 2) & 3], y[(n >> 4) & 3], y[(n >> 6) & 3])
        elif op == ".xpunpcklqdq": x, y = self.plain(int(a[1])), self.plain(int(a[2])); self.x[int(a[0])] = (x[0], x[1], y[0], y[1])
        elif op == ".xpunpckldq": x, y = self.plain(int(a[1])), self.plain(int(a[2])); self.x[int(a[0])] = (x[0], y[0], x[1], y[1])
        elif op == ".xpunpckhdq": x, y = self.plain(int(a[1])), self.plain(int(a[2])); self.x[int(a[0])] = (x[2], y[2], x[3], y[3])
        elif op in (".xpblendw", ".xpblendd"):
            x, y, n = self.plain(int(a[1])), self.plain(int(a[2])), int(a[3])
            if op == ".xpblendw":
                # by 16-bit halves: both halves of a word from one source, or this is no blend of words
                if any(((n >> (2 * j)) & 3) not in (0, 3) for j in range(4)): raise Fail("a blend that splits a word")
                n = sum(((n >> (2 * j)) & 1) << j for j in range(4))
            else: n &= 15                   # of 128 bits the processor reads the mask's low four bits (the kernel writes 0xAA, 0x88)
            self.x[int(a[0])] = tuple(y[j] if (n >> j) & 1 else x[j] for j in range(4))
        elif op == ".movzx8":
            # the low byte of a register, zero above: a byte the caller chose
            src = self.g[reg(a[1][1])]
            if a[1][0] != ".reg" or src[0] != "q": raise Fail(f"the low byte of {src}")
            self.g[reg(a[0])] = ("w", kspec.byte_term(T, (0, ("low byte of " + src[1],))))
        elif op == ".shl64":
            v, n = self.g[reg(a[0])], num(a[1])
            if n != 32: raise Fail("a shift this does not take")
            if v[0] == "w": self.g[reg(a[0])] = ("pair", T.const(0), v[1])
            elif v[0] == "q": self.g[reg(a[0])] = ("pair", T.const(0), T.var("low word of " + v[1]))      # its upper half is shifted out
            else: raise Fail(f"a shift of {v}")
            self.zf = None
        elif op == ".add":
            if a[0] != "64" or a[1][0] != ".reg" or a[2][0] != ".reg": raise Fail("an add this does not take")
            x, y = self.g[reg(a[1][1])], self.g[reg(a[2][1])]
            # a word below 2^32 plus a word shifted up 32: the two side by side, no carry between them
            if not (x[0] == "w" and y[0] == "pair" and T.nodes[y[1]] == ("c", 0)): raise Fail(f"an add of {x} and {y}")
            self.g[reg(a[1][1])] = ("pair", x[1], y[2]); self.zf = None
        elif op == ".mov":
            if a[0] != "8" or a[1] != [".reg", ".rax"] or a[2][0] != ".imm": raise Fail("a move this does not take")
            self.g["rax"] = ("al", num(a[2][1]) & 0xFF)
        elif op == ".decb":
            v = self.g[reg(a[0])]
            if v[0] != "al": raise Fail("a byte counted down that no number was put in")
            n = (v[1] - 1) & 0xFF; self.g[reg(a[0])] = ("al", n); self.zf = n == 0
        elif op in (".je", ".jne"):
            if self.zf is None: raise Fail("a branch on a flag no number decided")
            if self.zf == (op == ".je"): nxt = num(a[0])
        elif op == ".jmp": nxt = num(a[0])
        elif op == ".ret": nxt = None
        else: raise Fail(f"an instruction this checker does not know: {' '.join(map(str, i))}")
        self.steps += 1; self.pc = nxt


def check(rows, name):
    """Does the kernel meet CONTRACTS[name]? Returns the number of instructions run; raises Fail if not."""
    c, T = CONTRACTS[name], kcheck.Terms()
    m = Machine(T, rows, c)
    m.pc = rows[0][0]
    while m.pc is not None: m.one()
    for r in KEPT + ["rsp"]:
        if m.g[r] != (("q", r) if r != "rsp" else ("a", "stack", 0)): raise Fail(f"{r} is written")
    A = kspec.Symbols(T)
    length = ode.Word(T.var("edx")) if c["length"] == "word" else ode.Word(kspec.byte_term(T, (0, ("low byte of rdx",))))
    flags = ode.Word(T.var("low word of r8")) if c["flags"] == "low word" else ode.Word(kspec.byte_term(T, (0, ("low byte of r8",))))
    counter = ode.Counter(ode.Word(T.var("counter low")), ode.Word(T.var("counter high")))
    # what the contract says the chaining value is left as, in its own names for the five arguments
    want = kspec.terms(kspec.SPEC.eval(A, c["leaves"], dict(zip(c["names"], [kspec.words(m.cv), kspec.words(m.block), length, counter, flags]))))
    for half in (0, 16):
        if half not in m.out: raise Fail(f"the chaining value's bytes from {half} are not written")
        if tuple(m.out[half]) != want[half // 4:half // 4 + 4]: raise Fail(f"the words stored at {half} are not the specification's")
    return m.steps


def load(obj, name):
    rows, _ = kdecode.read(obj, CONTRACTS[name]["symbol"], BASE, DATA)
    kspec.fits(obj, CONTRACTS[name]["symbol"])
    return rows


def main():
    name, obj = sys.argv[1], sys.argv[2]
    rows = load(obj, name)
    t0 = time.time()
    steps = check(rows, name)
    c = CONTRACTS[name]
    print(f"{c['symbol']}: for every chaining value, block and counter the eight words stored are the specification's compress,")
    print(f"     with the length from {'the low byte of RDX' if c['length'] == 'low byte' else 'EDX (RDX below 2^32)'} and the flags from {'the low byte of R8' if c['flags'] == 'low byte' else 'the low word of R8'}; "
          f"{len(rows)} instructions, {steps} run, {time.time() - t0:.3f} s")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Fail as e:
        print(f"{sys.argv[1]}: NOT shown: {e}"); sys.exit(1)
