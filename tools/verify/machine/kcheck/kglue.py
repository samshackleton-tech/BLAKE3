#!/usr/bin/env python3
"""kglue: code that is not a kernel. A loop over a data structure in memory, and calls, by proofs found and checked.

    python3 kglue.py merge|push|add OBJECT --find PROOF.json     the prover: finds a proof, writes it (not trusted)
    python3 kglue.py merge|push|add OBJECT --proof PROOF.json    the checker

A second trial of the way of kloop.py (November 15, 2026), on the hasher's stack of chaining values: the
functions `push`, `merge` and `add` of lang/hasher.ode, as the Ode compiler and the assembler leave them
(x86-64). `merge` loops over a stack in memory whose count is a symbol, and calls a one-block kernel; `add`
calls `push` and `merge`. Lean checks the same three in about 100 seconds from proofs with lemmas by hand
(lang/Proof_merge.lean, Lemmas_merge.lean, StackLemmas.lean).

WHAT IS CLAIMED OF A FUNCTION is its contract (CONTRACTS, below): what each argument is, what the caller must
show, what the function leaves, how much stack it may use.
  merge(st, key, flags, plat, target)   the stack at `st` becomes what THE MERGE MACHINE makes of it, and the
                                        result is its count; the AVX-512 kernel is called only where plat is 5
  THE MERGE MACHINE                     while the stack holds more than `target` values, its top two become
                                        their parent: `machine merge` and `fn parent` of blake3.ode
  push(st, cv)                          the value at `cv` is put on the stack at `st`
  add(st, key, flags, plat, cv, target) push, then merge

A PROOF names the places of the code's loops, and for each what the registers and the frame hold there, for
ANY stack `now` of any count m the stack's memory may hold: kept, or a number c + cm*m. A function with no
loop has the empty proof.

THE CHECKER runs the code from its entry and from each place, forward along every path, on symbols:
  - to a place: the registers are what the proof says for the stack now in memory; and if the path began at a
    place, the stack in memory is one turn of the machine from the stack it began with, and the machine does
    turn there (it holds more than `target`);
  - to the return: the stack in memory and the result are what the contract says (for a loop: the machine
    has stopped), the registers a callee keeps and the stack pointer are back, the stack used is within bound;
  - at a call: the callee's contract. What it asks is shown from the caller's facts; what it leaves replaces
    what was there; the registers a call may change are forgotten.
No solver. A stack is a named unknown stack with some places replaced, and two are compared place by place;
whether two places are one, or a place is below the count, is decided by adding linear facts up.

The one-block kernels `merge` calls are checked against the same specification by kone.py, and what they ask
of their caller is read from there. WHAT IS NOT CHECKED HERE: that the merge machine is BLAKE3's tree
(alg/Stack.lean proves that of the same machine: `merge_lazy`)."""
import copy, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode, kspec, ode
from kcheck import Fail, num, signed
from klin import Lin, Facts
from kloop import value, lin
from kspec import Stack, plain, byte, byte_or, byte_term

BASE, DATA = 0x10000, 0x50000000
CAPACITY = 55                       # values a stack's memory holds (1792 bytes: the count's 32, and 55 of 32)
AVX512 = 5                          # the platform word that says the machine has AVX-512 (hasher.ode)
G64 = kcheck.G64
KEPT = kcheck.SAVED                 # the registers a callee keeps
ARGS = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]


def sym(name): return Lin([(name, 1)])


# ---------------------------------------------------------------------------------------------------------
# The specification: the merge machine, and what each function is claimed to do.
def merge_given(T, facts, key, flags, target, stack):
    """What blake3.ode's merge machine is given: the key, the flags byte, the target, and its state, the stack."""
    return kspec.Symbols(T, facts), dict(key=kspec.words(key), flags=ode.Word(byte_term(T, flags)), target=plain(target), s=stack)


def machine_turns(T, facts, key, flags, target, stack):
    """Does the merge machine turn on this stack? True, False, or None: the facts do not say."""
    A, env = merge_given(T, facts, key, flags, target, stack)
    try:
        return kspec.SPEC.goes(A, "merge", env)
    except ode.Err:
        return None


def machine_turn(T, facts, key, flags, target, stack):
    """One turn of the merge machine: the top two values become their parent."""
    A, env = merge_given(T, facts, key, flags, target, stack)
    return kspec.SPEC.turn(A, "merge", env)


def machine_result(T, facts, key, flags, target, stack):
    """What the machine makes of a stack, as a caller knows it: a stack named by what went in. Its count is a
    number of its own: at least 1 if the stack held a value, at most the stack's count."""
    name = T.mk("merged", tuple(key), byte(flags), Lin.of(target), stack.key(T, facts))
    count = sym(f"count of merged {name}")
    return Stack(("merged", name), count), count


class Contract:
    """name(args...): `args` are (register, kind, name): kind "stack" (the address of a stack, which the function
    may change), "cv" (the address of 32 bytes it may read), "byte" (a number below 256), "number" (a number,
    with what is asked of it), "any". `asks(v)`: the numbers the caller must show are not below zero.
    `leaves(T, facts, v)`: the stack afterwards and the result (None: nothing is said of rax). `machine`: for a
    function that is a loop of the merge machine, proved by its turns. `stack`: the bytes of stack it may use."""
    def __init__(self, name, args, asks, leaves, stack, machine=False):
        self.name, self.args, self.asks, self.leaves, self.stack, self.machine = name, args, asks, leaves, stack, machine


CONTRACTS = {
    "push": Contract("push", [("rdi", "stack", "st"), ("rsi", "cv", "new")],
                     asks=lambda v: [CAPACITY - 1 - v["st"].count],
                     leaves=lambda T, facts, v: (v["st"].put(T, facts, v["st"].count, v["new"], v["st"].count + 1), None), stack=64),
    "merge": Contract("merge", [("rdi", "stack", "st"), ("rsi", "cv", "key"), ("rdx", "byte", "flags"), ("rcx", "any", "plat"), ("r8", "number", "target")],
                      asks=lambda v: [v["target"] - 1],
                      leaves=lambda T, facts, v: machine_result(T, facts, v["key"], v["flags"], v["target"], v["st"]), stack=256, machine=True),
    "add": Contract("add", [("rdi", "stack", "st"), ("rsi", "cv", "key"), ("rdx", "byte", "flags"), ("rcx", "any", "plat"), ("r8", "cv", "new"), ("r9", "number", "target")],
                    asks=lambda v: [CAPACITY - 1 - v["st"].count, v["target"] - 1],
                    leaves=lambda T, facts, v: machine_result(T, facts, v["key"], v["flags"], v["target"],
                                                              v["st"].put(T, facts, v["st"].count, v["new"], v["st"].count + 1)), stack=512),
}
SYMBOLS = {"b3l_push": "push", "b3l_merge": "merge", "b3l_add": "add"}
# The one-block kernels, by their contract: (cv, block, block_len, counter, flags): the 32 bytes at cv become
# the first eight words of compress(cv, the 64 bytes at block, counter, block_len, flags); no stack but the
# return address. Where each reads the length and the flags from is CHECKED against the kernels' bytes by
# kone.py, and read from there: the AVX-512 kernel takes the low byte of each; the SSE4.1 kernel takes all of
# EDX (and RDX must be below 2^32) and the low word of R8. (This file first said "the low byte" of both, by
# hand: kglue_flip.py found 24 changes of merge's `mov rdx, 64` accepted that the processor told from the
# machine. A contract taken on trust is a hole until it is checked.)
import kone
COMPRESS = {c["symbol"]: c for c in kone.CONTRACTS.values()}


# ---------------------------------------------------------------------------------------------------------
# The machine: general registers, XMM registers as four 32-bit terms, memory in named regions.
class Fork(Exception):
    def __init__(self, kind, x): self.kind, self.x = kind, x


class Machine:
    def __init__(self, T, rows, contract):
        self.T, self.rows, self.contract = T, {a: (n, kcheck.parse(i)) for a, n, i in rows}, contract
        self.g = {r: ("q", r + " at entry") for r in G64}
        self.x, self.flags, self.facts, self.conds = {}, None, Facts(), {}
        self.cells = {("frame", 0): (8, ("q", "return address"))}      # (region, offset) -> (bytes, value); the frame's offsets are from the entry stack pointer
        self.stacks, self.readonly = {}, set()
        self.g["rsp"] = ("a", "frame", 0)
        self.low, self.pc, self.steps, self.moved = 0, None, 0, False
        self.given = {}                                                 # the contract's names: what the function was given
        for reg, kind, name in contract.args:
            if kind == "stack":
                self.g[reg] = ("a", name, 0)
                self.stacks[name] = Stack(name, sym("count"))
                self.facts.add(sym("count")); self.facts.add(CAPACITY - sym("count"))
                self.given[name] = self.stacks[name]
            elif kind == "cv":
                self.g[reg] = ("a", name, 0)
                words = tuple(T.var(name, w) for w in range(8))
                self.cells[(name, 0)], self.cells[(name, 16)] = (16, words[:4]), (16, words[4:])
                self.readonly.add(name); self.given[name] = words
            elif kind == "byte":
                self.g[reg] = ("p", ((0, (name,)),) + (0,) * 7); self.given[name] = (0, (name,))
            elif kind == "number":
                self.g[reg] = ("l", sym(name)); self.facts.add(sym(name)); self.given[name] = sym(name)
            else: self.g[reg] = ("q", name)
        for f in contract.asks(self.given): self.facts.add(f)

    def clone(self):
        c = copy.copy(self)
        c.g, c.x, c.cells, c.stacks, c.conds, c.facts = dict(self.g), dict(self.x), dict(self.cells), dict(self.stacks), dict(self.conds), self.facts.clone()
        return c

    # -- memory
    def address(self, base, disp):
        b = self.g[base.lstrip(".")]
        if b[0] != "a": raise Fail(f"an address from {base} = {b}")
        return b[1], b[2] + signed(num(disp))

    def place_of(self, region, off, size):
        """An address in a stack's memory: ("count",) or (place, word offset in the value)."""
        off = Lin.of(off)
        if not off.c and off.k == 0 and size == 8: return ("count",)
        for half in (0, 16):
            i = (off - 32 - half).over(32)
            if i is not None and size == 16:
                if not self.facts.ge0(i) or not self.facts.ge0(CAPACITY - 1 - i): raise Fail(f"place {i} of the stack at {region}: not shown to be within its {CAPACITY}")
                return (i, half // 4)
        raise Fail(f"{size} bytes at {region} + {off}: not the stack's count, and not half of a value")

    def load(self, region, off, size):
        if region in self.stacks:
            where = self.place_of(region, off, size)
            if where == ("count",): return value(self.stacks[region].count)
            return self.stacks[region].get(self.T, self.facts, where[0])[where[1]:where[1] + 4]
        if isinstance(off, Lin): raise Fail(f"a read at {region} + {off}")
        if region == "frame" and off < self.g["rsp"][2]: raise Fail(f"a read below the stack pointer, at {off}")
        cell = self.cells.get((region, off))
        if cell is None or cell[0] != size: raise Fail(f"a read of {size} bytes at {region} + {off}: not written so")
        return cell[1]

    def store(self, region, off, size, v):
        if region in self.readonly: raise Fail(f"a write to {region}, which the contract gives to read")
        if region in self.stacks:
            where, s = self.place_of(region, off, size), self.stacks[region]
            if where == ("count",):
                if lin(v) is None: raise Fail(f"a count that is not a number: {v}")
                self.stacks[region] = s.counted(lin(v))
            else:
                words = list(s.get(self.T, self.facts, where[0])); words[where[1]:where[1] + 4] = v
                self.stacks[region] = s.put(self.T, self.facts, where[0], words)
            return
        if region != "frame" or isinstance(off, Lin): raise Fail(f"a write at {region} + {off}")
        if off < self.g["rsp"][2] or off + size > 0: raise Fail(f"a write at {off} from the entry stack pointer: outside the function's own frame")
        for (r, o), (n, _) in list(self.cells.items()):
            if r == region and o < off + size and off < o + n and (o, n) != (off, size): del self.cells[(r, o)]         # what it overlaps is gone
        self.cells[(region, off)] = (size, v)

    # -- registers
    def operand(self, o):
        if o[0] == ".reg": return self.g[o[1].lstrip(".")]
        if o[0] == ".imm": return ("n", num(o[1]))
        return self.load(*self.address(o[1], o[2]), 8)

    def arith(self, op, x, y):
        """x + y, x - y, x << y, x | y of 64 bits, where this machine knows it."""
        if op in ("add", "sub") and x[0] == "a" and lin(y) is not None:
            return ("a", x[1], plain(Lin.of(x[2]) + (lin(y) if op == "add" else -lin(y))))
        if op == "add" and y[0] == "a" and lin(x) is not None: return ("a", y[1], plain(Lin.of(y[2]) + lin(x)))
        if op in ("add", "sub", "shl") and lin(x) is not None and lin(y) is not None:
            if op == "shl":
                if y[0] != "n" or not 0 <= y[1] < 16: raise Fail("a shift this does not take")
                d = lin(x).scale(1 << y[1])
            else: d = lin(x) + lin(y) if op == "add" else lin(x) - lin(y)
            # a number that depends on a count stays a whole number not below zero: no wrap at 64 bits
            if not self.facts.ge0(d): raise Fail(f"{op}: the result {d} may be below zero")
            return value(d)
        if op == "or" and x[0] == "p" and y[0] == "n" and y[1] < 256: return ("p", (byte_or(x[1][0], y[1]),) + x[1][1:])
        raise Fail(f"{op} of {x} and {y}")

    def decide(self):
        """The flags after a compare, for a branch: ("eq", bool) and ("ge", bool) as far as known."""
        if self.flags is None: raise Fail("a branch on flags no compare set")
        return self.flags

    def branch(self, op):
        kind, x = self.decide()
        if kind == "numbers":
            if op in (".je", ".jne"):
                z = self.facts.zero(x)
                if z is None: raise Fork("zero", x)
                return z == (op == ".je")
            ge = True if self.facts.ge0(x) else False if self.facts.ge0(-x - 1) else None      # unsigned: both sides are whole numbers not below zero
            if ge is None: raise Fork("ge", x)
            return ge == (op == ".jae")
        if op not in (".je", ".jne"): raise Fail("an order asked of something that is not a number")
        if x not in self.conds: raise Fork("cond", x)
        return self.conds[x] == (op == ".je")

    # -- calls
    def call(self, name):
        T, sp = self.T, self.g["rsp"][2]
        if name in COMPRESS:
            cv, block = self.g["rdi"], self.g["rsi"]
            if cv[0] != "a" or block[0] != "a": raise Fail("a kernel called with something that is not an address")
            state = self.load(cv[1], cv[2], 16) + self.load(cv[1], cv[2] + 16, 16)
            message = sum((self.load(block[1], block[2] + 16 * i, 16) for i in range(4)), ())
            length, counter, flags = self.g["rdx"], self.g["rcx"], self.g["r8"]
            if length[0] != "n" or counter[0] != "n" or flags[0] != "p": raise Fail(f"a kernel called with a length, counter or flags this does not take: {length}, {counter}, {flags}")
            if name.endswith("avx512") and self.conds.get(("plat", AVX512)) is not True:
                # found by reading kglue_flip.py's accepted changes: `mov rcx, 5` could become any number and
                # the AVX-512 kernel be called on a machine without it, with the contract none the wiser
                raise Fail("the AVX-512 kernel is called on a path that does not say the platform word is 5 (AVX-512)")
            wide = COMPRESS[name]["length"] == "whole word"
            if wide and (length[1] >= 1 << 32 or any(b != 0 for b in flags[1][1:4])):
                raise Fail(f"{name} reads all of EDX and of R8D: the caller does not show the length is below 2^32 and the flags below 256")
            A = kspec.Symbols(T, self.facts)
            out = kspec.terms(kspec.SPEC.call(A, "compress", kspec.words(state), kspec.words(message), A.counter(counter[1]), length[1] if wide else length[1] & 0xFF, ode.Word(byte_term(T, flags[1][0]))))
            self.store(cv[1], cv[2], 16, tuple(out[:4])); self.store(cv[1], cv[2] + 16, 16, tuple(out[4:]))
            used = 8
        else:
            c = CONTRACTS.get(SYMBOLS.get(name))
            if c is None: raise Fail(f"a call of {name}: no contract")
            v, region = {}, None
            for reg, kind, arg in c.args:
                a = self.g[reg]
                if kind == "stack":
                    if a[0] != "a" or a[2] != 0 or a[1] not in self.stacks: raise Fail(f"{name}: {arg} is not the address of a stack")
                    region, v[arg] = a[1], self.stacks[a[1]]
                elif kind == "cv":
                    if a[0] != "a" or a[1] in self.stacks: raise Fail(f"{name}: {arg} is not the address of a chaining value apart from the stack")
                    v[arg] = self.load(a[1], a[2], 16) + self.load(a[1], a[2] + 16, 16)
                elif kind == "byte":
                    if a[0] != "p" or any(b != 0 for b in a[1][1:]): raise Fail(f"{name}: {arg} is not shown to be below 256")
                    v[arg] = a[1][0]
                elif kind == "number":
                    if lin(a) is None: raise Fail(f"{name}: {arg} is not a number")
                    v[arg] = lin(a)
            for f in c.asks(v):
                if not self.facts.ge0(f): raise Fail(f"{name}: the caller does not show what it asks ({f} >= 0)")
            after, result = c.leaves(T, self.facts, v)
            self.stacks[region] = after
            if result is not None:
                self.facts.add(result)                                 # a count: not below zero, and within the stack's memory
                self.facts.add(CAPACITY - result)
            used = 8 + c.stack
            self.g["rax"] = value(result) if result is not None else ("q", "left by a call")
        self.low = min(self.low, sp - used)
        for r in G64:
            if r not in KEPT and r != "rsp" and not (r == "rax" and name not in COMPRESS): self.g[r] = ("q", "left by a call")
        self.x, self.flags = {}, None

    # -- one instruction
    def one(self):
        if self.pc not in self.rows: raise Fail(f"no instruction at 0x{self.pc:X}")
        if self.steps >= 100000: raise Fail("still running")
        nxt, i = self.rows[self.pc]
        op, a = i[0], i[1:]
        if op in (".je", ".jne", ".jae", ".jb"):
            if self.branch(op): nxt = num(a[0])                       # may fork: nothing is changed before it does
        elif op == ".jmp": nxt = num(a[0])
        elif op == ".nop": pass
        elif op == ".mov":
            if a[0] != "64": raise Fail("a move that is not of 64 bits")
            v = self.operand(a[2])
            if a[1][0] == ".reg": self.g[a[1][1].lstrip(".")] = v
            else: self.store(*self.address(a[1][1], a[1][2]), 8, v)
        elif op in (".add", ".sub", ".or"):
            if a[0] != "64" or a[1][0] != ".reg": raise Fail(f"{op} that is not of 64 bits into a register")
            r = a[1][1].lstrip(".")
            v = self.arith(op[1:], self.g[r], self.operand(a[2]))
            if r == "rsp":
                if v[0] != "a" or v[1] != "frame" or isinstance(v[2], Lin): raise Fail("the stack pointer leaves the frame")
                self.low = min(self.low, v[2])
            self.g[r] = v; self.flags = None
        elif op == ".shl64":
            r = a[0].lstrip("."); self.g[r] = self.arith("shl", self.g[r], ("n", num(a[1]))); self.flags = None
        elif op == ".cmp":
            if a[0] != "64": raise Fail("a compare that is not of 64 bits")
            x, y = self.operand(a[1]), self.operand(a[2])
            if lin(x) is not None and lin(y) is not None: self.flags = ("numbers", lin(x) - lin(y))
            elif x[0] == "q" and y[0] == "n": self.flags = ("unknown", (x[1], y[1]))        # is an unknown word this number? either way
            else: raise Fail(f"a compare of {x} and {y}")
        elif op == ".lea":
            b = self.g[a[1].lstrip(".")]
            if b[0] != "a": raise Fail("lea from a non-address")
            self.g[a[0].lstrip(".")] = ("a", b[1], b[2] + signed(num(a[2])))
        elif op == ".xloadu": self.x[int(a[0])] = self.load(*self.address(a[1], a[2]), 16)
        elif op == ".xstoreu":
            if int(a[2]) not in self.x: raise Fail(f"xmm{a[2]} stored before it is written")
            self.store(*self.address(a[0], a[1]), 16, self.x[int(a[2])])
        elif op == ".push":
            sp = self.g["rsp"]
            self.g["rsp"] = ("a", "frame", sp[2] - 8); self.low = min(self.low, sp[2] - 8)
            self.store("frame", sp[2] - 8, 8, self.g[a[0].lstrip(".")])
        elif op == ".pop":
            sp = self.g["rsp"]
            self.g[a[0].lstrip(".")] = self.load("frame", sp[2], 8); self.g["rsp"] = ("a", "frame", sp[2] + 8)
        elif op == ".call": self.call(a[0])
        elif op == ".ret":
            if self.g["rsp"] != ("a", "frame", 0) or self.cells.get(("frame", 0)) != (8, ("q", "return address")): raise Fail("a return to somewhere else")
            nxt = None
        else: raise Fail(f"an instruction this checker does not know: {' '.join(map(str, i))}")
        self.steps += 1; self.moved = True; self.pc = nxt


def paths(m, places):
    """Every path of m to its end: a place (after at least one instruction) or the return."""
    ends, work = [], [m]
    while work:
        m = work.pop()
        while True:
            if m.pc is None: ends.append(("return", m)); break
            if m.pc in places and m.moved: ends.append(("place", m)); break
            try:
                m.one()
            except Fork as f:
                yes, no = m.clone(), m.clone()
                if f.kind == "zero": yes.facts.assume_zero(f.x); no.facts.assume_nonzero(f.x)
                elif f.kind == "ge": yes.facts.add(f.x); no.facts.add(-f.x - 1)
                else: yes.conds[f.x] = True; no.conds[f.x] = False
                work += [yes, no]; break
    return ends


# ---------------------------------------------------------------------------------------------------------
# The checker.
def same(v, w):
    if lin(v) is not None and lin(w) is not None: return lin(v) == lin(w)
    return v == w


def at_place(seen, said, stack_region, stack):
    """The machine at a place holding the stack `stack`, as the proof says (`said`); `seen` is the machine at
    its first visit there, for what the proof calls kept."""
    m = seen.clone()
    m.moved, m.flags, m.steps, m.x = False, None, 0, {}
    m.g = {r: ("q", "anything") for r in G64}
    for r, what in said["registers"].items():
        m.g[r] = seen.g[r] if what == "keep" else value(Lin([("count", what["lin"].get("m", 0))], what["lin"].get("1", 0)).at("count", stack.count))
    m.cells = {k: v for k, v in seen.cells.items() if k[0] != "frame" or str(k[1]) in said["frame"]}       # what is given to read stays; of the frame, what is named
    m.stacks = dict(seen.stacks); m.stacks[stack_region] = stack
    return m


def agrees(e, want, where):
    for r in G64:
        if want.g[r] != ("q", "anything") and not same(want.g[r], e.g[r]): raise Fail(f"{where}: {r} is {e.g[r]} at the place, the proof says {want.g[r]}")
    for k, cell in want.cells.items():
        if e.cells.get(k) != cell: raise Fail(f"{where}: the frame's cell at {k[1]} is not kept")


def returned(e, c, T, where):
    """At a return: the registers a callee keeps, the stack pointer (the return checked it), the stack used."""
    for r in KEPT:
        if e.g[r] != ("q", r + " at entry"): raise Fail(f"{where}: {r} is not restored")
    if -e.low > c.stack: raise Fail(f"{where}: {-e.low} bytes of stack used, the contract gives {c.stack}")


def check(rows, name, proof):
    c, T = CONTRACTS[name], kcheck.Terms()
    entry = rows[0][0]
    places = {BASE + p["at"]: p for p in proof["places"]}
    region = next(arg for _, kind, arg in c.args if kind == "stack")
    m = Machine(T, rows, c); m.pc = entry
    given = m.given
    tally = {"place": 0, "return": 0, "steps": 0}
    seen = {}
    # from the entry
    for kind, e in paths(m, places):
        tally[kind] += 1; tally["steps"] += e.steps
        if kind == "return":
            if c.machine:
                # a loop of the machine that returns before its place: the machine must not turn at all
                if machine_turns(T, e.facts, given["key"], given["flags"], given["target"], given[region]) is not False: raise Fail("entry: the code returns where the machine turns")
                want, result = given[region], given[region].count
            else: want, result = c.leaves(T, e.facts, given)
            if not e.stacks[region].same(T, e.facts, want): raise Fail("entry: the stack at the return is not what the contract says")
            if result is not None and not same(e.g["rax"], value(result)): raise Fail(f"entry: the result is {e.g['rax']}, the contract says {value(result)}")
            returned(e, c, T, "entry")
        else:
            if not c.machine: raise Fail("a place in a function that is not a loop of the machine")
            if e.pc in seen: raise Fail("entry: two paths to one place")
            seen[e.pc] = e
            if not e.stacks[region].same(T, e.facts, given[region]): raise Fail("entry: the stack is changed before the place")
            agrees(e, at_place(e, places[e.pc], region, e.stacks[region]), "entry")
    # from each place, with any stack the memory may hold
    for at, first in seen.items():
        now = Stack("now", sym("m"))
        m = at_place(first, places[at], region, now)
        m.facts.add(sym("m")); m.facts.add(CAPACITY - sym("m"))
        m.pc = at
        for kind, e in paths(m, places):
            tally[kind] += 1; tally["steps"] += e.steps
            turns = machine_turns(T, e.facts, given["key"], given["flags"], given["target"], now)
            if kind == "place":
                if turns is not True: raise Fail("step: the code goes round where the machine has stopped (or the path does not say)")
                want = machine_turn(T, e.facts, given["key"], given["flags"], given["target"], now)
                if not e.stacks[region].same(T, e.facts, want): raise Fail("step: the stack at the place is not one turn of the machine")
                agrees(e, at_place(seen[e.pc], places[e.pc], region, e.stacks[region]), "step")
                if -e.low > c.stack: raise Fail(f"step: {-e.low} bytes of stack used, the contract gives {c.stack}")
            else:
                if turns is not False: raise Fail("step: the code returns where the machine turns (or the path does not say)")
                if not e.stacks[region].same(T, e.facts, now): raise Fail("step: the stack at the return is not the stack the machine stopped with")
                if not same(e.g["rax"], value(now.count)): raise Fail(f"step: the result is {e.g['rax']}, not the count")
                returned(e, c, T, "step")
    if c.machine and not seen: raise Fail("a loop of the machine with no place")
    if not tally["return"]: raise Fail("no path returns")
    return tally


# ---------------------------------------------------------------------------------------------------------
# The prover (nothing here is trusted).
def find(rows, name):
    c, T = CONTRACTS[name], kcheck.Terms()
    proof = dict(function=name, places=[])
    if not c.machine:
        check(rows, name, proof); return proof
    # the places: the targets of backward jumps
    heads = sorted({num(i.split()[1]) for a, n, i in rows if i.split()[0] in (".jmp", ".je", ".jne", ".jae", ".jb") and num(i.split()[1]) <= a})
    region = next(arg for _, kind, arg in c.args if kind == "stack")
    m = Machine(T, rows, c); m.pc = rows[0][0]
    for head in heads:
        first = [e for kind, e in paths(m.clone(), {head}) if kind == "place"]
        if len(first) != 1: raise Fail("the code does not come to its loop by one path")
        first = first[0]
        again = [e for kind, e in paths(restart(first), {head}) if kind == "place"]
        if not again: raise Fail("the loop does not come round")
        again = again[0]
        said = dict(at=head - BASE, registers={}, frame={})
        c0, c1 = first.stacks[region].count, again.stacks[region].count
        for r in G64:
            v0, v1 = first.g[r], again.g[r]
            if v0 == v1: said["registers"][r] = "keep"
            elif lin(v0) is not None and lin(v1) is not None and lin(v0) - c0 == lin(v1) - c1 and not (lin(v0) - c0).c:
                said["registers"][r] = {"lin": {"m": 1, "1": (lin(v0) - c0).k}}          # the count, and a number
        for (r, off), cell in first.cells.items():
            if r == "frame" and again.cells.get((r, off)) == cell: said["frame"][str(off)] = "keep"
        proof["places"].append(said)
    for _ in range(64):
        try:
            check(rows, name, proof); return proof
        except Fail as e:
            msg = str(e)
            for said in proof["places"]:
                weak = next((r for r in list(said["registers"]) if f": {r} is" in msg), None)
                if weak is not None: del said["registers"][weak]; break
                weak = next((off for off in list(said["frame"]) if f"cell at {off} " in msg), None)
                if weak is not None: del said["frame"][weak]; break
            else: raise
    raise Fail("no proof found")


def restart(m):
    c = m.clone(); c.moved = False; return c


def smallest(rows, name, proof):
    proof = copy.deepcopy(proof)
    for said in proof["places"]:
        for part in ("registers", "frame"):
            for key in list(said[part]):
                kept = said[part].pop(key)
                try: check(rows, name, proof)
                except Fail: said[part][key] = kept
    return proof


def load(obj, name):
    rows, _ = kdecode.read(obj, "b3l_" + name, BASE, DATA)
    return rows


def main():
    name, obj, mode, path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    rows = load(obj, name)
    if mode == "--find":
        t0 = time.time()
        proof = find(rows, name)
        if "--smallest" in sys.argv: proof = smallest(rows, name, proof)
        with open(path, "w") as f: json.dump(proof, f, indent=1)
        print(f"{name}: a proof found in {time.time() - t0:.3f} s and written to {path} ({os.path.getsize(path)} bytes): {len(proof['places'])} place(s)")
        return 0
    with open(path) as f: proof = json.load(f)
    t0 = time.time()
    done = check(rows, name, proof)
    print(f"{name}: the {len(rows)} instructions meet the contract, for every stack and every argument the contract allows")
    print(f"     checked in {time.time() - t0:.3f} s: {done['place']} path(s) to a place, {done['return']} to the return, {done['steps']} instructions run")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Fail as e:
        print(f"{sys.argv[1]}: NOT shown: {e}"); sys.exit(1)
