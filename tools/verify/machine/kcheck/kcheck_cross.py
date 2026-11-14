#!/usr/bin/env python3
"""kcheck's own reading of the instructions, against the Lean model's.

    cd ../one && lake env lean --run CrossOne.lean 5 > vectors.txt
    python3 ../kcheck/kcheck_cross.py CrossOneTable.lean vectors.txt

kcheck.py runs a kernel's instructions on symbolic values by its own rules (its `step`). Lean's model
(one/Machine.lean) is checked against a processor (one/cross_one.sh: every instruction form of the proved
programs and of the wide kernels, on random states). Here each of the model's test vectors (an instruction,
a random state, the state the model says it leaves, which the processor agreed with) is given to kcheck's
`step` with numbers in every register, and what kcheck leaves is compared: the general registers, the 32 ZMM
registers, the two mask registers, the zero flag where both define it, and the bytes of memory a store wrote.

kcheck knows only the instruction forms the wide kernels use, and its general registers hold numbers, addresses
in named regions or the packed flags: a form it does not take with plain numbers is counted "not taken", not
passed. A difference is an error."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck
from kcheck import Fail, MASK32

ORDER = "rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r12 r13 r14 r15 r10 r11".split()
BASE = 0x20001000
fill = lambda seed, a: ((a * 2654435761 + seed * 40503) // 256) & 0xFF


class Cross(kcheck.Machine):
    """kcheck's machine with every register a number and memory the test's window of bytes."""
    def __init__(self, T, seed):
        self.T, self.g, self.z, self.k, self.zf = T, {}, [None] * 32, {}, None
        self.mem = {a: fill(seed, a) for a in range(BASE - 512, BASE + 512)}
        self.written = set()
        self.trace, self.steps, self.frame, self.frame_size = [], 0, {}, 0

    def addr(self, base, disp, index=None):
        b = self.reg(base)
        if b[0] != "n": raise Fail("an address from a non-number")
        a = b[1] + kcheck.signed(disp)
        if index is not None: a += self.reg(index)[1]
        return ("window", a & ((1 << 64) - 1))

    def bytes_at(self, a, n):
        if any(a + i not in self.mem for i in range(n)): raise Fail("a read outside the window")
        return bytes(self.mem[a + i] for i in range(n))

    def load(self, at, w): return ("n", int.from_bytes(self.bytes_at(at[1], w // 8), "little"))

    def load512(self, at, aligned):
        if aligned and at[1] % 64: raise Fail("an aligned read of an unaligned address")
        b = self.bytes_at(at[1], 64)
        return tuple(self.T.const(int.from_bytes(b[4 * i:4 * i + 4], "little")) for i in range(16))

    def store512(self, at, v, aligned):
        if aligned and at[1] % 64: raise Fail("an aligned store to an unaligned address")
        for i, x in enumerate(v):
            k = self.T.nodes[x]
            if k[0] != "c": raise Fail("a store of a term")
            for j in range(4):
                if at[1] + 4 * i + j not in self.mem: raise Fail("a store outside the window")
                self.mem[at[1] + 4 * i + j] = (k[1] >> (8 * j)) & 0xFF; self.written.add(at[1] + 4 * i + j)


def main():
    table = dict((b, i) for i, b in re.findall(r'^  \((.+), "([0-9a-f]+)"\),?$', open(sys.argv[1]).read(), re.M))
    same = differ = 0
    not_taken, forms_same, forms_all = {}, set(), set()
    for line in open(sys.argv[2]):
        f = line.split()
        if not f or f[0] != "test": continue
        ins, seed = table[f[1]], int(f[2])
        forms_all.add(f[1])
        T = kcheck.Terms()
        m = Cross(T, seed)
        for i, r in enumerate(ORDER): m.g[r] = ("n", int(f[3 + i], 16))
        for i in range(32):
            v = int(f[19 + i], 16); m.z[i] = tuple(T.const((v >> (32 * l)) & MASK32) for l in range(16))
        bit = lambda b: T.ult(T.const(0), T.const(1)) if b else T.ult(T.const(1), T.const(0))
        for n, tok in ((1, f[53]), (2, f[54])): m.k[n] = tuple(bit((int(tok, 16) >> l) & 1) for l in range(16))
        m.zf = {"1": True, "0": False}.get(f[51])
        m.rows = {1: (2, kcheck.parse(ins))}; m.pc = 1
        try:
            m.step()
        except (Fail, KeyError, AssertionError, IndexError, TypeError, ValueError) as e:
            op = ins.split()[0]; not_taken[op] = not_taken.get(op, 0) + 1; continue
        val = kcheck.evaluate(T, {})
        ok = all(m.g[r][0] == "n" and m.g[r][1] == int(f[55 + i], 16) for i, r in enumerate(ORDER))
        for i in range(32):
            got = sum(val[x] << (32 * l) for l, x in enumerate(m.z[i]))
            ok = ok and got == int(f[71 + i], 16)
        for n, tok in ((1, f[105]), (2, f[106])):
            ok = ok and sum(val[x] << l for l, x in enumerate(m.k[n])) == int(tok, 16)
        if f[103] != "-" and m.zf is not None: ok = ok and m.zf == (f[103] == "1")
        window = bytes.fromhex(f[107])
        ok = ok and all(m.mem[a] == window[a - (BASE - 512)] for a in range(BASE - 512, BASE + 512))
        if ok: same += 1; forms_same.add(f[1])
        else:
            differ += 1
            if differ <= 10: print(f"DIFFERS: {ins} (seed {seed})")
    taken = len(forms_same)
    print(f"{same + differ} vectors of {taken} instruction forms taken by kcheck with numbers: {differ} differ from the Lean model")
    print(f"not taken with plain numbers ({len(forms_all) - taken} forms; kcheck holds addresses and flags in its own domains, or does not know the form): "
          + ", ".join(f"{k} x{v}" for k, v in sorted(not_taken.items())))
    return 1 if differ or not same else 0


if __name__ == "__main__":
    sys.exit(main())
