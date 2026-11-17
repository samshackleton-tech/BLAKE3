#!/usr/bin/env python3
"""kterms: what every verifier here shares. 32-bit terms, compared by identity; the rows a decoder writes,
read; the names of the general registers. (Until November 17, 2026 a part of kcheck.py.)"""
import collections, re
from ode import Err as Fail        # one failure: the verifier's and the specification reader's

MASK32 = 0xFFFFFFFF
G64 = "rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15".split()
SAVED = ["rbx", "rbp", "r12", "r13", "r14", "r15"]         # the registers a callee keeps


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
        if op == "xor":         # a term xored with itself is gone (in pairs)
            out = [x for x, n in sorted(collections.Counter(out).items()) if n % 2]
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
