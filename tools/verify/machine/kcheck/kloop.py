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
import copy, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode, kspec, ode
from kcheck import Fail, num
from klin import Lin, Facts
from kspec import byte_or, byte_term

BASE, DATA = 0x10000, 0x50000000


# ---------------------------------------------------------------------------------------------------------
# Numbers that depend on n and b (klin.py), as register values.
N, B = Lin([("n", 1)]), Lin([("b", 1)])


def value(x):
    """A general register's value for a number that may depend on n and b."""
    x = Lin.of(x)
    return ("l", x) if x.c else ("n", x.k)


def lin(v):
    """A register's value as such a number, or None."""
    return Lin.of(v[1]) if v[0] in ("n", "l") else None


class Fork(Exception):
    def __init__(self, x): self.x = x


# ---------------------------------------------------------------------------------------------------------
# The specification: the chunk machine of blake3.spec, a turn at a time (kspec.py reads it on symbols).
def kernel_of(symbol, start):
    """A wide kernel's contract, as blake3.spec states it: (inputs, n, key, counter, packed bytes, out) in the
    calling convention's order; each of the out's chaining values is left as a machine's result on a lane's
    input. `start`: the symbol its code begins at (P32 enters K32's body)."""
    c = kspec.SPEC.contracts[symbol]
    kinds = [kind.split() for _, kind in c["args"]]
    lanes = int(kinds[0][0]) if kinds[0][0].isdigit() else 0
    if (len(kinds) != 6 or kinds[0][1:] != ["inputs"] or kinds[1] != ["number"] or kinds[2] != ["cv"] or kinds[3] != ["counter"]
            or kinds[4][0] != "bytes" or len(kinds[4]) != 5 or kinds[5] != [str(lanes), "cvs"] or lanes not in (16, 32)):
        raise Fail(f"{symbol}: not a wide kernel's contract: {kinds}")
    left = c["leaves"][0]
    e = left["expr"]
    if left["name"] != c["args"][5][0] or left["index"] is None or left["each"] != (("num", 0), ("num", lanes)): raise Fail(f"{symbol}: a wide kernel leaves each of its {lanes} chaining values")
    if e[0] != "call" or e[1] not in kspec.SPEC.machines or c["returns"] is not None: raise Fail(f"{symbol}: each chaining value is a machine's result, and nothing is returned")
    return dict(symbol=symbol, start=start, lanes=lanes, names=[arg for arg, _ in c["args"]], bytes=kinds[4][1:], index=left["index"], machine=e[1], args=e[2],
                stack=c["stack"], text=c)


def kernels():
    return {"k32": kernel_of("blake3_servil_avx512_k32", "blake3_servil_avx512_k32"), "p32": kernel_of("blake3_servil_avx512_p32", "blake3_servil_avx512_k32"),
            "p16": kernel_of("blake3_servil_avx512_p16", "blake3_servil_avx512_p16")}


KERNELS = kernels()


def given(T, facts, kernel, lane):
    """The contract's arguments in the specification's terms, and the lane's number under the contract's name
    for it: the inputs, the number of blocks n, the key, the counter, the four packed bytes."""
    A = kspec.Symbols(T, facts)
    inputs, n, key, t, _, _ = kernel["names"]
    env = {inputs: kspec.Inputs(kernel["lanes"]), n: N, key: kspec.words(T.var("key", w) for w in range(8)),
           t: ode.Counter(ode.Word(T.var("counter low")), ode.Word(T.var("counter high"))), kernel["index"]: lane}
    for name in kernel["bytes"]: env[name] = ode.Word(byte_term(T, (0, (name,))))
    return A, env


def machine_given(T, facts, kernel, lane):
    """What the contract's machine is given for a lane: its arguments, as the contract writes them."""
    A, env = given(T, facts, kernel, lane)
    m = kspec.SPEC.machines[kernel["machine"]]
    if len(m["params"]) != len(kernel["args"]) or m["loop"][0] != "for": raise Fail(f"{kernel['symbol']}: the machine is not given what it takes, or is not a counted loop")
    return A, m, {p: kspec.SPEC.eval(A, e, env) for p, e in zip(m["params"], kernel["args"])}


def spec_start(T, kernel):
    """The machine's first state."""
    A, m, env = machine_given(T, Facts(), kernel, 0)
    return list(kspec.terms(kspec.SPEC.eval(A, m["init"], env)))


def spec_step(T, facts, kernel, state, lane, b):
    """The lane's state after block b, from its state before it: one turn of the machine. Whether b is the
    first block and whether it is the last are asked of the path's facts: the code must have asked too."""
    A, m, env = machine_given(T, facts, kernel, lane)
    env[m["state"]], env[m["loop"][1]] = kspec.words(state), kspec.plain(b)
    return list(kspec.terms(kspec.SPEC.turn(A, kernel["machine"], env)))


# ---------------------------------------------------------------------------------------------------------
# The machine of kcheck.py, with a number of blocks that is a symbol, the flags' bytes unknown, and paths.
class Machine(kcheck.Machine):
    def __init__(self, T, rows, data_at, data, kernel):
        super().__init__(T, rows, data_at, data, dict(lanes=kernel["lanes"], blocks=0, counter=("q", "counter"), packed=(0, 0, 0, 0)), stack_budget=kernel["stack"])
        self.kernel, self.facts, self.moved = kernel, Facts(), False
        self.g["rsi"] = ("l", N)
        # the packed flags: four unknown bytes (the contract names them), and four above them the code must not need
        self.g["r8"] = ("p", tuple((0, (name,)) for name in kernel["bytes"]) + ((0, ("byte 4",)), (0, ("byte 5",)), (0, ("byte 6",)), (0, ("byte 7",))))
        A, env = given(T, self.facts, kernel, 0)
        for f in kspec.asked(kernel["text"], A, env): self.facts.add(f)             # what the contract asks: at least one block

    def clone(self):
        c = copy.copy(self)
        c.g, c.z, c.k, c.frame, c.saved, c.out, c.trace, c.facts = dict(self.g), list(self.z), dict(self.k), dict(self.frame), dict(self.saved), dict(self.out), [], self.facts.clone()
        return c

    def trunc(self, v, w):
        if v[0] == "l" and w != 64: raise Fail(f"{w} bits of a number that depends on the block count")
        return super().trunc(v, w)

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
    start = spec_start(T, kernel)
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
    start = spec_start(T, kernel)
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
