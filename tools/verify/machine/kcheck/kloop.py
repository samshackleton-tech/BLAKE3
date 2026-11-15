#!/usr/bin/env python3
"""kloop: the wide kernels for EVERY number of blocks, by a proof that is found and then checked.

    python3 kloop.py k32|p32|p16 OBJECT --find PROOF.json [--smallest]     the prover: finds a proof and writes it (no trust in it)
    python3 kloop.py k32|p32|p16 OBJECT --proof PROOF.json     the checker: reads the proof and says yes or no

A trial of a way to make proofs (November 15, 2026). kcheck.py shows a kernel for one fixed number of blocks,
by running it to its end. Here the number of blocks `n` is a symbol, and so are the flags' four bytes: the
kernel's whole interface. The loop over blocks is not run n times; it is checked once, by induction.

THE SPECIFICATION is a small machine, one lane at a time:

    state 0            = the key's eight words
    state b+1          = compress(state b, block b of the lane's input, counter (+ lane where the kernel counts),
                                  length = 64, or the byte `len` for the last block,
                                  flags | `start` for block 0 | `end` for the last block)
    what is stored     = state n

THE PROOF is a short text (JSON): one place in the code (the head of the loop over blocks), and for that place
what each register and each cell of the frame holds when the code is there with b blocks done:
    "keep"          what it held when the code came there after the first block
    "lin"           a number that moves with b: c + cn*n + cb*b
    "cv"            word w of the specification's state for sixteen lanes
    (unnamed)       anything: the code must not read it before writing it

THE CHECKER does no searching:
  base   it runs the code from its entry through the first block (which may differ from the others: the start
         flag) and sees that the place then holds what the proof says for b = 1 and the specification's state
         1, or, where the path returns, that n was 1 and state 1 is stored;
  step   it starts at the place with what the proof says for an unknown b >= 1 and an unknown state, runs the
         code forward along every path (a path forks where the code asks "is this the last block?"), and at
         each path's end sees either the place again holding what the proof says for b+1 and the
         specification's next state, or the return with the specification's next state stored, and that path
         is one where b was the last.
So for every n: after n turns what is stored is state n. (Floyd's method of 1967; nothing new in the logic.)
Equality is identity of terms, as in kcheck.py; "is b zero?" is decided from a few linear facts (b >= 0,
b <= n-1) by adding them up, never by a solver.

THE PROVER guesses the proof: it runs the code from the entry to the place and twice around the loop, and
compares the second and third visits. What is the same is "keep"; a number that moved is "lin"; a register that holds the
specification's next state is "cv"; the rest is unnamed. A guess the checker refuses at one register is
weakened there (that register becomes unnamed) and tried again. Nothing the prover does is trusted."""
import copy, json, math, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode
from kcheck import Fail, num

BASE, DATA = 0x10000, 0x50000000


# ---------------------------------------------------------------------------------------------------------
# Numbers that depend on n and b: c + cn*n + cb*b. And what is known of them.
class Lin:
    __slots__ = ("c", "k")
    def __init__(self, c=(), k=0):
        self.c, self.k = tuple(sorted((s, a) for s, a in c if a)), k
    @staticmethod
    def of(x): return x if isinstance(x, Lin) else Lin((), x)
    def __add__(self, o):
        o = Lin.of(o); d = dict(self.c)
        for s, a in o.c: d[s] = d.get(s, 0) + a
        return Lin(d.items(), self.k + o.k)
    __radd__ = __add__
    def scale(self, m): return Lin(((s, a * m) for s, a in self.c), self.k * m)
    def __neg__(self): return self.scale(-1)
    def __sub__(self, o): return self + (-Lin.of(o))
    def __eq__(self, o): return isinstance(o, Lin) and (self.c, self.k) == (o.c, o.k)
    def __hash__(self): return hash((self.c, self.k))
    def at(self, sym, value):
        """This number with `sym` replaced by a number or another such number."""
        rest = Lin(((s, a) for s, a in self.c if s != sym), self.k)
        return rest + Lin.of(value).scale(dict(self.c).get(sym, 0))
    def over(self, d):
        """Divided by d, if that is exact."""
        if self.k % d or any(a % d for _, a in self.c): return None
        return Lin(((s, a // d) for s, a in self.c), self.k // d)
    def __repr__(self): return " + ".join([f"{a}*{s}" for s, a in self.c] + ([str(self.k)] if self.k or not self.c else []))


N, B = Lin([("n", 1)]), Lin([("b", 1)])


def value(x):
    """A general register's value for a number that may depend on n and b."""
    x = Lin.of(x)
    return ("l", x) if x.c else ("n", x.k)


def lin(v):
    """A register's value as such a number, or None."""
    return Lin.of(v[1]) if v[0] in ("n", "l") else None


class Facts:
    """Numbers known to be >= 0, and numbers known not to be 0. Whole numbers."""
    def __init__(self): self.ge, self.ne = [], []
    def clone(self):
        f = Facts(); f.ge, f.ne = list(self.ge), list(self.ne); return f
    @staticmethod
    def norm(f):
        g = 0
        for _, a in f.c: g = math.gcd(g, abs(a))
        return f if g <= 1 else Lin(((s, a // g) for s, a in f.c), f.k // g)        # whole numbers: the constant rounds down
    def ge0(self, goal):
        """Is goal >= 0 a sum of known facts (each taken a few times) and a number >= 0?"""
        goal = Lin.of(goal)
        if not goal.c: return goal.k >= 0
        goal = self.norm(goal)
        for f in self.ge:
            if f.c == goal.c and goal.k >= f.k: return True
        for i, f in enumerate(self.ge):
            for g in self.ge[i + 1:]:
                for a in (1, 2):
                    for b in (1, 2):
                        s = f.scale(a) + g.scale(b)
                        if s.c == goal.c and goal.k >= s.k: return True
        return False
    def zero(self, x):
        """True: x is 0. False: it is not. None: the facts do not say."""
        x = Lin.of(x)
        if not x.c: return x.k == 0
        if any(x == y or x == -y for y in self.ne): return False
        if self.ge0(x - 1) or self.ge0(-x - 1): return False
        if self.ge0(x) and self.ge0(-x): return True
        return None
    def add(self, f):
        f = self.norm(Lin.of(f))
        if f.c and f not in self.ge: self.ge.append(f)
    def assume_zero(self, x): self.add(x); self.add(-Lin.of(x))
    def assume_nonzero(self, x):
        x = Lin.of(x)
        if self.ge0(x): self.add(x - 1)
        elif self.ge0(-x): self.add(-x - 1)
        else: self.ne.append(x)


class Fork(Exception):
    def __init__(self, x): self.x = x


# ---------------------------------------------------------------------------------------------------------
# The flags' bytes: a byte is a number, or a number or-ed with named unknown bytes.
def byte(x): return (x, ()) if isinstance(x, int) else x
def unbyte(c, names): return c if not names else (c, tuple(sorted(set(names))))
def byte_or(x, y):
    (c, p), (d, q) = byte(x), byte(y)
    return unbyte(c | d, p + q)
def byte_term(T, x):
    """A byte, zero-extended to a lane's 32 bits, as a term."""
    c, names = byte(x)
    return T.const(c) if not names else T.mk("orb", c, names)


# ---------------------------------------------------------------------------------------------------------
# The specification's step.
KERNELS = {
    "k32": dict(start="blake3_servil_avx512_k32", symbol="blake3_servil_avx512_k32", lanes=32, increment=True),
    "p32": dict(start="blake3_servil_avx512_k32", symbol="blake3_servil_avx512_p32", lanes=32, increment=False),
    "p16": dict(start="blake3_servil_avx512_p16", symbol="blake3_servil_avx512_p16", lanes=16, increment=False),
}


def spec_start(T): return [T.var("key", w) for w in range(8)]


def spec_step(T, facts, kernel, state, lane, b):
    """The lane's state after block b, from its state before it. Whether b is the first block and whether it is
    the last are asked of the path's facts: the code must have asked too."""
    first, last = facts.zero(b), facts.zero(N - b - 1)
    if first is None or last is None: raise Fail("the specification asks whether this block is the first, or the last, and the code's path does not say")
    flags = byte_term(T, unbyte(0, ("flags",) + (("start",) if first else ()) + (("end",) if last else ())))
    length = byte_term(T, (0, ("len",))) if last else T.const(64)
    t_lo, t_hi = kcheck.spec_counter(T, lane) if kernel["increment"] else (T.var("counter low"), T.var("counter high"))
    block = b.k if isinstance(b, Lin) and not b.c else b
    return kcheck.spec_compress(T, state, [T.var("input", lane, block, w) for w in range(16)], t_lo, t_hi, length, flags)


# ---------------------------------------------------------------------------------------------------------
# The machine of kcheck.py, with a number of blocks that is a symbol, the flags' bytes unknown, and paths.
class Machine(kcheck.Machine):
    def __init__(self, T, rows, data_at, data, kernel):
        super().__init__(T, rows, data_at, data, dict(lanes=kernel["lanes"], blocks=0, counter=("q", "counter"), packed=(0, 0, 0, 0)))
        self.kernel, self.facts, self.moved = kernel, Facts(), False
        self.facts.add(N - 1)                               # the contract: at least one block
        self.g["rsi"] = ("l", N)
        # the packed flags: four unknown bytes, and four above them the code must not need
        self.g["r8"] = ("p", ((0, ("flags",)), (0, ("start",)), (0, ("end",)), (0, ("len",)), (0, ("byte 4",)), (0, ("byte 5",)), (0, ("byte 6",)), (0, ("byte 7",))))

    def clone(self):
        c = copy.copy(self)
        c.g, c.z, c.k, c.frame, c.saved, c.out, c.trace, c.facts = dict(self.g), list(self.z), dict(self.k), dict(self.frame), dict(self.saved), dict(self.out), [], self.facts.clone()
        return c

    def trunc(self, v, w):
        if v[0] == "l" and w != 64: raise Fail(f"{w} bits of a number that depends on the block count")
        return super().trunc(v, w)

    def lane(self, v):
        if v[0] == "p":
            if any(x != 0 for x in v[1][1:4]): raise Fail(f"a word of packed bytes {v[1]}")
            return byte_term(self.T, v[1][0])
        return super().lane(v)

    def addr(self, base, disp, index=None):
        if index is not None and self.reg(index)[0] == "l":
            b = self.reg(base)
            if b[0] != "a": raise Fail(f"an address from {base} = {b}")
            return (b[1], self.reg(index)[1] + (b[2] + kcheck.signed(disp)))
        return super().addr(base, disp, index)

    def load512(self, at, aligned):
        region, off = at
        if isinstance(region, tuple) and region[0] == "input":
            # block off/64 of a lane's input: within the n blocks the contract gives
            self.trace.append(("read", region, off, 512))
            if aligned: raise Fail(f"an aligned wide read at {region} + {off}")
            block = Lin.of(off).over(64)
            if block is None or not self.facts.ge0(block) or not self.facts.ge0(N - block - 1): raise Fail(f"a wide read at {region} + {off}: not a block of the input")
            return tuple(self.T.var("input", region[1], block.k if not block.c else block, w) for w in range(16))
        return super().load512(at, aligned)

    def step(self):
        nxt, i = self.rows[self.pc]
        op, a = i[0], i[1:]
        if op in (".je", ".jne") and isinstance(self.zf, tuple):
            # a branch on a number that depends on n and b: the facts decide it, or the path forks
            is_zero = self.facts.zero(self.zf[1])
            if is_zero is None: raise Fork(self.zf[1])
            self.steps += 1
            if is_zero == (op == ".je"): nxt = num(a[0])
            self.trace.append(("branch", nxt)); self.pc = nxt; return
        if op in (".test", ".cmp") and a[0] == "64" and a[1][0] == ".reg" and a[2][0] in (".reg", ".imm"):
            x, y = self.val(a[1], 64), self.val(a[2], 64)
            if "l" in (x[0], y[0]) and lin(x) is not None and lin(y) is not None:
                if op == ".test" and a[1] != a[2]: raise Fail("a test of two different numbers")
                d = lin(x) if op == ".test" else lin(x) - lin(y)        # the zero flag: both are below 2^64, so equal as whole numbers
                self.steps += 1; self.zf = ("zero?", d) if d.c else (d.k == 0); self.pc = nxt; return
        r = a[0] if op == ".dec64" else a[1][1] if op in (".add", ".sub") and a[1][0] == ".reg" else None
        if r is not None and self.reg(r)[0] == "l":
            # a number that depends on n and b, one more or fewer: it must stay a number that is not below zero
            if op != ".dec64" and (a[0] != "64" or a[2][0] != ".imm"): raise Fail(f"{op} on a number that depends on the block count")
            d = self.reg(r)[1] + (-1 if op == ".dec64" else num(a[2][1]) if op == ".add" else -num(a[2][1]))
            if not self.facts.ge0(d): raise Fail(f"{op}: the result {d} may be below zero")
            self.steps += 1; self.setreg(r, value(d)); self.pc = nxt
            self.zf = (("zero?", d) if d.c else d.k == 0) if op == ".dec64" else None
            return
        if op == ".or" and a[0] == "32" and a[1][0] == ".reg":
            x, y = self.val(a[1], 32), self.val(a[2], 32)
            if x[0] == "p" and y[0] == "p":
                self.steps += 1; self.setreg(a[1][1], ("p", tuple(byte_or(p, q) for p, q in zip(x[1], y[1])))); self.zf = None; self.pc = nxt; return
        self.moved = True
        return super().step()

    def one(self):
        """One instruction (kcheck's run, a step at a time)."""
        if self.pc not in self.rows: raise Fail(f"no instruction at 0x{self.pc:X}")
        if self.steps >= 200000: raise Fail("still running")
        nxt, i = self.rows[self.pc]
        self.moved = True
        if i[0] == ".mov" and i[1] == "64" and i[3][0] == ".imm" and self.data_at <= num(i[3][1]) < self.data_at + len(self.data):
            self.setreg(i[2][1], ("a", "rodata", num(i[3][1]) - self.data_at)); self.steps += 1; self.pc = nxt
        else: self.step()

    def returned(self):
        """What kcheck asks at the return."""
        for r in kcheck.SAVED:
            if self.g[r] != ("q", r + " at entry"): raise Fail(f"{r} is not restored")
        if self.g["rsp"] != ("a", "stack", 8): raise Fail(f"the stack pointer at the return: {self.g['rsp']}")
        if -self.low > self.budget: raise Fail(f"{-self.low} bytes of stack used, the contract gives {self.budget}")


def paths(m, head):
    """Every path of m to its end: the place `head` (after at least one instruction) or the return."""
    ends, work = [], [m]
    while work:
        m = work.pop()
        while True:
            if m.pc is None: ends.append(("return", m)); break
            if m.pc == head and m.moved: ends.append(("head", m)); break
            try:
                m.one()
            except Fork as f:
                yes, no = m.clone(), m.clone()
                yes.facts.assume_zero(f.x); no.facts.assume_nonzero(f.x)
                work += [yes, no]; break
    return ends


# ---------------------------------------------------------------------------------------------------------
# The checker.
def same(v, w):
    """Two register values, the same number or the same thing."""
    if lin(v) is not None and lin(w) is not None: return lin(v) == lin(w)
    return v == w


def at_place(seen, proof, T, kernel, b, state):
    """The machine at the place with b blocks done and the specification's state `state` (a function of the
    lane), as the proof says. `seen` is the machine at its second visit of the place (one block done): what
    the proof calls "keep" is what it held then."""
    m = seen.clone()
    m.moved, m.zf, m.steps = False, None, 0
    m.g = {r: ("q", "anything") for r in kcheck.G64}
    for r, what in proof["registers"].items():
        m.g[r] = seen.g[r] if what == "keep" else value(Lin([(s, a) for s, a in what["lin"].items() if s != "1"], what["lin"].get("1", 0)).at("b", b))
    m.z = [None] * 32
    for r, what in proof["vectors"].items():
        m.z[int(r)] = seen.z[int(r)] if what == "keep" else tuple(state(what["cv"][0] + lane)[what["cv"][1]] for lane in range(16))
    m.k = {}
    m.frame = {int(off): seen.frame[int(off)] for off, what in proof["frame"].items()}
    return m


def stored(e, lanes, want, where):
    """At a return: the registers a callee keeps, the stack, and the specification's state stored."""
    e.returned()
    for lane in range(lanes):
        for w in range(8):
            word = 8 * lane + w
            cell = e.out.get(64 * (word // 16))
            if cell is None: raise Fail(f"{where}: the output at {64 * (word // 16)} is not written")
            if cell[word % 16] != want[lane][w]: raise Fail(f"{where}: word {w} of lane {lane}'s chaining value is not the specification's")


def agrees(e, want, seen, where):
    """A machine come to the place holds what the proof says (`want`, made by at_place)."""
    for r in kcheck.G64:
        if want.g[r] != ("q", "anything") and not same(want.g[r], e.g[r]): raise Fail(f"{where}: {r} is {e.g[r]} at the place, the proof says {want.g[r]}")
    for r in range(32):
        if want.z[r] is not None and want.z[r] != e.z[r]: raise Fail(f"{where}: zmm{r} at the place is not what the proof says")
    for off, cell in want.frame.items():
        if e.frame.get(off) != cell: raise Fail(f"{where}: the frame's cell at {off} is not kept")
    if e.out: raise Fail(f"{where}: output is written before the last block")
    if (e.saved, e.frame_size, e.frame_at) != (seen.saved, seen.frame_size, seen.frame_at): raise Fail(f"{where}: the saved registers or the frame are not as they were")
    if -e.low > e.budget: raise Fail(f"{-e.low} bytes of stack used, the contract gives {e.budget}")


def visits(rows, data, kernel, T, head, entry):
    """The code run from its entry to the place, and from there once around: the first visit, the second,
    and the paths that return on the way (they must be the one-block case)."""
    m = Machine(T, rows, DATA, data, kernel)
    m.pc = entry
    ends = paths(m, head)
    if len(ends) != 1 or ends[0][0] != "head": raise Fail("from the entry the code does not come to the place by one path")
    first = ends[0][1]
    if first.out: raise Fail("output is written before the place")
    around = paths(first.clone_at_rest(), head)
    second = [e for kind, e in around if kind == "head"]
    if len(second) != 1: raise Fail("the first block does not lead back to the place by one path")
    return first, second[0], [e for kind, e in around if kind == "return"]


def check(rows, data, name, proof, entry):
    """Does the proof show the kernel? Returns a few numbers of what was done; raises Fail if not."""
    kernel, T = KERNELS[name], kcheck.Terms()
    head = BASE + proof["place"]
    lanes = kernel["lanes"]
    # base: from the entry through the first block. The first block is run as it is (it may differ from the
    # others: the start flag); what the proof says must hold from the second visit of the place on.
    first, second, one_block = visits(rows, data, kernel, T, head, entry)
    start = spec_start(T)
    for e in one_block:
        if e.facts.zero(N - 1) is not True: raise Fail("base: the code returns after its first block when there are more")
        stored(e, lanes, {lane: spec_step(T, e.facts, kernel, start, lane, 0) for lane in range(lanes)}, "one block")
    if not one_block: raise Fail("base: no path for one block")
    after1 = {lane: spec_step(T, second.facts, kernel, start, lane, 0) for lane in range(lanes)}
    agrees(second, at_place(second, proof, T, kernel, 1, lambda lane: after1[lane]), second, "base")
    # step: from the place with b blocks done, 1 <= b <= n-1, and any state
    unknown = lambda lane: [T.var("state", lane, w) for w in range(8)]
    m = at_place(second, proof, T, kernel, B, unknown)
    m.facts.add(B - 1); m.facts.add(N - B - 1)
    m.pc = head
    steps = first.steps + second.steps + sum(e.steps for e in one_block)
    tally = {"head": 0, "return": 0}
    for kind, e in paths(m, head):
        tally[kind] += 1; steps += e.steps
        nxt = {lane: spec_step(T, e.facts, kernel, unknown(lane), lane, B) for lane in range(lanes)}
        if kind == "head":
            # the place again: what the proof says for b+1 and the specification's next state
            if not e.facts.ge0(N - B - 2): raise Fail("step: the code comes back to the place after the last block")
            agrees(e, at_place(second, proof, T, kernel, B + 1, lambda lane: nxt[lane]), second, "step")
        else:
            # the return: only after the last block, with the specification's next state stored
            if e.facts.zero(N - B - 1) is not True: raise Fail("step: the code returns before the last block")
            stored(e, lanes, nxt, "step")
    if not tally["head"] or not tally["return"]: raise Fail("the step has no path back to the place, or none to the return")
    return dict(paths=tally, steps=steps, terms=len(T.nodes))


# ---------------------------------------------------------------------------------------------------------
# The prover (nothing here is trusted).
def find(rows, data, name, entry):
    kernel, T = KERNELS[name], kcheck.Terms()
    # the place: the target of a backward branch that the code passes once a block (two blocks: twice)
    m = Machine(T, rows, DATA, data, kernel); m.pc = entry
    m.facts.assume_zero(N - 2)
    count, back, index = {}, set(), {r[0]: r for r in rows}
    while m.pc is not None:
        pc = m.pc; count[pc] = count.get(pc, 0) + 1
        m.one()
        if m.pc is not None and m.pc <= pc and index[pc][2].split()[0] in (".je", ".jne", ".jmp"): back.add(m.pc)
    places = sorted(p for p in back if count[p] == 2)
    if not places: raise Fail("no place the code passes once a block")
    head = places[0]
    # the second and third visits of the place: what is the same, what moved, what holds the specification's state
    first, second, _ = visits(rows, data, kernel, T, head, entry)
    third = [e for kind, e in paths(second.clone_at_rest(), head) if kind == "head"]
    if len(third) != 1: raise Fail("the second block does not lead back to the place by one path")
    third = third[0]
    start = spec_start(T)
    words = {}
    for lane0 in range(0, kernel["lanes"], 16):
        after2 = [spec_step(T, third.facts, kernel, spec_step(T, third.facts, kernel, start, lane0 + lane, 0), lane0 + lane, 1) for lane in range(16)]
        for w in range(8): words[tuple(after2[lane][w] for lane in range(16))] = (lane0, w)
    proof = dict(kernel=name, place=head - BASE, registers={}, vectors={}, frame={})
    for r in kcheck.G64:
        v1, v2 = second.g[r], third.g[r]
        if v1 == v2: proof["registers"][r] = "keep"
        elif lin(v1) is not None and lin(v2) is not None and not (lin(v2) - lin(v1)).c:
            g = lin(v1) + (B - 1).scale((lin(v2) - lin(v1)).k)             # as it was at b = 1, and its move a block
            proof["registers"][r] = {"lin": {**{s: a for s, a in g.c}, "1": g.k}}
    for r in range(32):
        if third.z[r] in words: proof["vectors"][str(r)] = {"cv": list(words[third.z[r]])}
        elif second.z[r] is not None and second.z[r] == third.z[r]: proof["vectors"][str(r)] = "keep"
    for off, cell in second.frame.items():
        if third.frame.get(off) == cell: proof["frame"][str(off)] = "keep"
    # weaken where the checker refuses, one name at a time
    for _ in range(96):
        try:
            check(rows, data, name, proof, entry); return proof
        except Fail as e:
            msg = str(e)
            weak = next((r for r in list(proof["registers"]) if f": {r} is" in msg), None)
            if weak is not None: del proof["registers"][weak]; continue
            weak = next((r for r in list(proof["vectors"]) if f"zmm{r} " in msg and proof["vectors"][r] == "keep"), None)
            if weak is not None: del proof["vectors"][weak]; continue
            weak = next((off for off in list(proof["frame"]) if f"cell at {off} " in msg), None)
            if weak is not None: del proof["frame"][weak]; continue
            raise
    raise Fail("no proof found")


def smallest(rows, data, name, proof, entry):
    """The proof with every name taken out that the checker does not need: what is left is what the loop rests on."""
    proof = copy.deepcopy(proof)
    for part in ("registers", "vectors", "frame"):
        for key in list(proof[part]):
            kept = proof[part].pop(key)
            try: check(rows, data, name, proof, entry)
            except Fail: proof[part][key] = kept
    return proof


def _clone_at_rest(self):
    c = self.clone(); c.moved = False; return c
Machine.clone_at_rest = _clone_at_rest


def load(obj, name):
    kernel = KERNELS[name]
    rows, data = kdecode.read(obj, kernel["start"], BASE, DATA)
    entry = BASE + kdecode.address(obj, kernel["symbol"]) - kdecode.address(obj, kernel["start"])
    return rows, data, entry


def main():
    name, obj, mode, path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    rows, data, entry = load(obj, name)
    if mode == "--find":
        t0 = time.time()
        proof = find(rows, data, name, entry)
        if "--smallest" in sys.argv: proof = smallest(rows, data, name, proof, entry)
        with open(path, "w") as f: json.dump(proof, f, indent=1)
        print(f"{name}: a proof found in {time.time() - t0:.2f} s and written to {path} ({os.path.getsize(path)} bytes): the place +0x{proof['place']:X}, "
              f"{len(proof['registers'])} registers, {len(proof['vectors'])} vector registers, {len(proof['frame'])} frame cells named")
        return 0
    with open(path) as f: proof = json.load(f)
    t0 = time.time()
    done = check(rows, data, name, proof, entry)
    k = KERNELS[name]
    print(f"{name}: for every number of blocks n >= 1, every key, counter, input, and every flags, start, end and length byte, the {k['lanes']} chaining values stored are the specification's")
    print(f"     checked by induction over the blocks in {time.time() - t0:.2f} s: the base, and a step of {done['paths']['head']} paths back to the place and {done['paths']['return']} to the return; "
          f"{done['steps']} instructions run, {done['terms']} terms")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Fail as e:
        print(f"{sys.argv[1]}: NOT shown: {e}"); sys.exit(1)
