#!/usr/bin/env python3
"""kbyte: a function over bytes and numbers, shown to meet its contract from the binary's bytes.

    python3 kbyte.py SPEC SYMBOL OBJECT [PROOF]

SPEC holds the specification and the contract of SYMBOL (CONTRACT.md says what a contract means); OBJECT
the function's bytes; PROOF, for a function with a loop whose count the paths do not fix, its places.

What is shown, for everything the contract's `requires` lines allow, along every path of the machine code:

  - every read is of a byte of something an argument addresses, within its length, or of the function's
    own stack; every write is of a byte of something an `ensures` or a `writes` names, within its length, or
    of the stack, within the contract's `stack`;
  - at the return: the result is the specification's value (`returns`); the registers a callee keeps, the
    stack pointer and the return address are as they were;
  - which instructions run and which addresses are touched do not depend on the bytes in memory, except the
    bytes of what a `trace depends on` line names;
  - at a place of the proof: what the place says. A PLACE is one instruction a loop comes back to, and what
    is true there whenever the code comes to it:

        place +0x1f {
            name i = r14                 the number in r14 is called i (`stack[8]`: the eight bytes 8 above the stack pointer)
            fact i <= len                what is known of the names
            r12 = s1(input)[i]           what a register holds, in the specification's terms
            any stack[16]                something the loop changes, of which nothing is said
            decreases len - i            numbers never below zero that are less at the next place the code comes
        }                                to: the first, or the first no greater and the second less, and so on

    The checker runs the code from the entry to the place, and from the place (the names any numbers the
    facts allow, the registers as said, the registers a callee keeps and the stack as they were if they
    were the same on every path, everything else unknown) to the place again or to the return. Every arrival must show what the place says. So each loop is run once, for every count.

A byte read is a number from 0 to 255 that the checker gives a name (`input[i]`); the specification read on
the same path gives the same name to the same byte. Numbers are compared by adding linear facts up
(klin.py): no solver. A sequence of the specification at a place the path does not fix is a number with a
name; at the place after one that is known it is the sequence's own equation of it.

The machine's instructions are kfn.py's reading of them (this file is a second kind of memory under the same
machine: bytes with a length, in place of BLAKE3's words). Calls are not followed yet.

WHAT IS NOT CHECKED HERE: this checker (Python, unverified)."""
import itertools, os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode, kfn, kspec, ode
from kcheck import Fail
from klin import Lin, Facts, sym
from kloop import value, lin
from kspec import plain, halved
from ode import Err

BASE, DATA, G64, KEPT, ARGS, WORD64 = kfn.BASE, kfn.DATA, kfn.G64, kfn.KEPT, kfn.ARGS, kfn.WORD64
STEPS = 2000000
HELD = tuple(KEPT) + ("rsp",)        # at a place, what these hold is kept if it was the same on every path; the others are unknown unless the place says
FRESH = itertools.count()


class View:
    """n bytes of the memory an argument addresses, from the offset `off`."""
    def __init__(self, region, off, n): self.region, self.off, self.n = region, Lin.of(off), Lin.of(n)


class Contract:
    def __init__(self, spec, symbol):
        c = spec.contracts.get(symbol)
        if c is None: raise Fail(f"{symbol}: no contract")
        self.name, self.text, self.spec = symbol, c, spec
        if len(c["args"]) > len(ARGS): raise Fail(f"{symbol}: more arguments than the registers that carry them")
        self.args = [(reg, kind, name) for reg, (name, kind) in zip(ARGS, c["args"])]
        self.kind = {name: kind for _, kind, name in self.args}
        for _, kind, name in self.args:
            n = kfn.bytes_kind(kind)
            if kind != "number" and n is None: raise Fail(f"{symbol}: {name} is of a kind this checker does not know: {kind}")
            if isinstance(n, str) and self.kind.get(n) != "number": raise Fail(f"{symbol}: {name} is {kind}, and {n} is not a number among the arguments")
        addresses = [name for _, kind, name in self.args if kind != "number"]
        if len(addresses) > 1 and sorted(c["apart"] or []) != sorted(addresses):
            raise Fail(f"{symbol}: the contract does not say `requires apart({', '.join(addresses)})`: the things at the addresses it is given are taken to be apart")
        if c["leaves"]: raise Fail(f"{symbol}: `ensures` of what is in memory: not this checker's yet (it knows `writes` and `returns`)")
        if c["calls"] or c["needs"] or c["given"] or c["decreases"] is not None: raise Fail(f"{symbol}: a clause this checker does not know")
        if not isinstance(c["stack"], int): raise Fail(f"{symbol}: the stack it may use is not a plain number")
        self.stack, self.writes, self.trace = c["stack"], set(c["spoils"]), set(c["trace"])
        for name in self.writes | self.trace:
            if self.kind.get(name) in (None, "number"): raise Fail(f"{symbol}: {name} is not something at an address among its arguments")


# ---------------------------------------------------------------------------------------------------------
# The specification read on a path: numbers that depend on counts, bytes with names, sequences.
class Algebra:
    def __init__(self, m): self.m, self.facts, self.T = m, m.facts, m.T
    def word(self, n): raise Err("a word: this checker's programs are of bytes and numbers")
    counter = add = xor = or_ = rotr = words = word
    def compare(self, op, a, b):
        if isinstance(a, bool) or isinstance(b, bool) or not isinstance(a, (int, Lin)) or not isinstance(b, (int, Lin)): raise Err("a comparison of things that are not numbers")
        d = self.facts.subst(Lin.of(a) - Lin.of(b))
        if not d.c: return {"==": d.k == 0, "!=": d.k != 0, "<": d.k < 0, "<=": d.k <= 0, ">": d.k > 0, ">=": d.k >= 0}[op]
        if op in ("==", "!="):
            z = self.facts.zero(d)
            if z is None: raise Err(f"the specification asks whether {Lin.of(a)} is {Lin.of(b)}, and the code's path does not say")
            return z == (op == "==")
        if op in (">=", "<"): yes = True if self.facts.ge0(d) else False if self.facts.ge0(-d - 1) else None
        else: yes = True if self.facts.ge0(d - 1) else False if self.facts.ge0(-d) else None
        if yes is None: raise Err(f"the specification asks how {Lin.of(a)} and {Lin.of(b)} compare, and the code's path does not say")
        return yes if op in (">=", ">") else not yes
    def minus(self, x, y):
        d = Lin.of(x) - Lin.of(y)
        if not self.facts.ge0(d): raise Err(f"the specification takes {Lin.of(y)} from {Lin.of(x)}, and the code's path does not show the result is not below zero")
        return plain(d)
    def mul(self, x, y):
        x, y = plain(x), plain(y)
        if isinstance(x, int): return plain(Lin.of(y).scale(x))
        if isinstance(y, int): return plain(x.scale(y))
        raise Err("a product of two numbers that both depend on counts")
    def quotient(self, x, d):
        """(x / d, x % d) for a plain d: by the path's facts; for a power of two, a number with a name."""
        d, x = ode.Spec.number(d), Lin.of(x)
        if d < 1: raise Err("a division by nothing")
        if not x.c: return x.k // d, x.k % d
        for q in range(4):                                  # the path says which multiple of d it is at or above
            if self.facts.ge0(x - q * d) and self.facts.ge0(q * d + d - 1 - x): return q, plain(x - q * d)
        if d & (d - 1) == 0:
            q = halved(self.facts, x, d)
            return plain(Lin.of(q)), plain(x - Lin.of(q).scale(d))
        raise Err(f"{x} divided by {d}: the code's path does not say how many times")
    def div(self, x, d): return self.quotient(x, d)[0]
    def mod(self, x, d): return self.quotient(x, d)[1]
    def plain(self, x):
        n = self.facts.number(Lin.of(x)) if isinstance(x, (int, Lin)) and not isinstance(x, bool) else None
        if n is None: raise Err(f"a plain number expected, not {x!r}")
        return n
    def length(self, x): return plain(x.n) if isinstance(x, View) else len(x)
    def index(self, x, i):
        if isinstance(x, View):
            i = Lin.of(i)
            if not self.facts.ge0(i) or not self.facts.ge0(x.n - 1 - i): raise Err(f"byte {i} of {x.n} bytes: not shown to be one of them")
            return plain(self.m.byte(x.region, x.off + i))
        return ode.at(x, i if isinstance(i, int) else self.plain(i))
    def slice(self, x, a, b):
        if isinstance(x, View):
            a, b = Lin.of(a), Lin.of(b)
            if not self.facts.ge0(a) or not self.facts.ge0(b - a) or not self.facts.ge0(x.n - b): raise Err(f"bytes {a} to {b} of {x.n}: not shown to be within them")
            return View(x.region, x.off + a, b - a)
        return ode.part(x, a if isinstance(a, int) else self.plain(a), b if isinstance(b, int) else self.plain(b))
    def concat(self, x, y):
        if not isinstance(x, list) or not isinstance(y, list): raise Err("++ of things that are not plain lists")
        return x + y
    def key(self, a):
        if isinstance(a, View): return ("view", a.region, repr(self.facts.subst(a.off)), repr(self.facts.subst(a.n)))
        if isinstance(a, list): return tuple(self.key(x) for x in a)
        if isinstance(a, (int, Lin)) and not isinstance(a, bool): return repr(self.facts.subst(Lin.of(a)))
        raise Err("a sequence of something this checker gives no name to")
    def element(self, spec, seq, i):
        """A sequence's value at place i. At a place the path fixes: worked out. At a place one after a place
        whose value is known: the sequence's equation of it. Else: a number with a name."""
        if seq.id is None: return seq.at(spec, self, self.plain(i))
        i = self.facts.subst(Lin.of(i))
        name, args = seq.id
        key = (name, tuple(self.key(a) for a in args))
        table = self.m.seqs.setdefault(key, [])
        for j, v in table:
            if self.facts.zero(i - j) is True: return v
        n = self.facts.number(i)
        below = Lin.of(n - 1) if n is not None and n > 0 else next((j for j, _ in table if self.facts.zero(i - j - 1) is True), None)
        if n == 0: v = spec.eval(self, seq.first, seq.env)
        elif below is not None:
            if n is not None: self.element(spec, seq, below)
            inner = dict(seq.env); inner[seq.var] = plain(below)
            v = spec.eval(self, seq.next, inner)
        else:
            if not self.facts.ge0(i): raise Err(f"place {i} of a sequence: not shown to be a place of it")
            title = f"{name}{key[1]}[{i!r}]"
            v = sym(title); self.facts.add(v)
            first, nxt = seq.first, seq.next
            if nxt[0] == "bin" and nxt[1] == "%" and nxt[3][0] == "num" and first[0] == "num" and first[1] < nxt[3][1]:
                self.facts.add(nxt[3][1] - 1 - v)                    # every value of it is one of the remainders
            if any(isinstance(a, View) and a.region not in self.m.contract.trace for a in args): self.m.secret.add(title)
        table.append((i, v))
        return v


# ---------------------------------------------------------------------------------------------------------
# The machine: kfn.py's, with memory that is bytes.
class Machine(kfn.Machine):
    def __init__(self, T, rows, c):
        self.T, self.rows, self.contract = T, {a: (n, kcheck.parse(i)) for a, n, i in rows}, c
        self.g = {r: ("q", r + " at entry") for r in G64}
        self.g["rsp"] = ("a", "frame", 0)
        self.x, self.flags, self.facts, self.conds, self.memo = {}, None, Facts(), {}, {}
        self.mem = {"frame": {0: (8, "q", ("q", "return address"))}}
        self.readonly, self.given, self.len = set(), {}, {}
        self.low, self.pc, self.steps, self.back, self.since = 0, None, 0, {}, 0
        self.secret, self.bytes, self.seqs = set(), set(), {}
        for reg, kind, name in c.args:
            if kind == "number":
                x = sym(name); self.facts.add(x); self.facts.add(WORD64 - x)
                self.g[reg], self.given[name] = ("l", x), x
        for reg, kind, name in c.args:
            if kind == "number": continue
            n = kfn.bytes_kind(kind)
            size = self.given[n] if isinstance(n, str) else n
            self.g[reg], self.len[name], self.given[name] = ("a", name, 0), Lin.of(size), View(name, 0, size)
            if name not in c.writes: self.readonly.add(name)
        A = Algebra(self)
        try:
            for e in c.text["asks"]:
                for f in order(c.spec, A, e, self.given): self.facts.add(f)
        except Err as e: raise Fail(f"{c.name}: what it requires cannot be read: {e}")

    def clone(self):
        c = super().clone()
        c.secret, c.bytes, c.seqs = set(self.secret), set(self.bytes), {k: list(v) for k, v in self.seqs.items()}
        return c

    # -- bytes
    def byte(self, region, off):
        """The byte at region + off as a number with a name: the same name for the same place."""
        name = f"{region}[{self.facts.subst(Lin.of(off))!r}]"
        if name not in self.bytes:
            self.bytes.add(name); self.facts.add(sym(name)); self.facts.add(255 - sym(name))
            if region not in self.contract.trace: self.secret.add(name)
        return sym(name)

    def tainted(self, x):
        """Does this number depend on bytes the contract does not let the trace depend on?"""
        return any(s in self.secret or (s.startswith("(") and any(n in s for n in self.secret)) for s, _ in Lin.of(x).c)

    def inside(self, region, off, what):
        n = self.len[region]
        if not self.facts.ge0(off) or not self.facts.ge0(n - 1 - off): raise Fail(f"a {what} at {region} + {off}: not shown to be within its {n} bytes")
        if self.tainted(off): raise Fail(f"a {what} at {region} + {off}: where it is depends on bytes the contract does not let the trace depend on")

    def load(self, region, off, size):
        if region == "frame": return super().load(region, off, size)
        if region not in self.len: raise Fail(f"an address in {region}: no such memory")
        if size != 1: raise Fail(f"a read of {size} bytes of {region}: this checker follows one byte at a time")
        off = Lin.of(off); self.inside(region, off, "read")
        if region in self.readonly: return ("l", self.byte(region, off))
        name = f"{region}?{next(FRESH)}"                    # of what the function has written nothing is kept
        self.facts.add(sym(name)); self.facts.add(255 - sym(name))
        if region not in self.contract.trace: self.secret.add(name)
        return ("l", sym(name))

    def store(self, region, off, size, new):
        if region == "frame": return super().store(region, off, size, new)
        if region not in self.len: raise Fail(f"an address in {region}: no such memory")
        if region in self.readonly: raise Fail(f"a write to {region}, which the contract gives to read")
        if size != 1: raise Fail(f"a write of {size} bytes of {region}: this checker follows one byte at a time")
        self.inside(region, Lin.of(off), "write")

    # -- instructions: a mask that is the low bits; a branch that may depend only on what the contract lets it
    def arith(self, op, x, y):
        if op == "and" and x[0] == "l" and y[0] == "n" and y[1] > 0 and (y[1] + 1) & y[1] == 0 and y[1] < 1 << 32:
            try: return value(x[1] - Lin.of(halved(self.facts, x[1], y[1] + 1)).scale(y[1] + 1))
            except Err as e: raise Fail(str(e))
        return super().arith(op, x, y)

    def branch(self, op):
        if self.flags is not None and self.flags[0] == "numbers" and self.tainted(self.flags[1]):
            raise Fail("a branch that depends on bytes in memory: the contract does not say the trace may depend on them")
        return super().branch(op)

    def call(self, name): raise Fail(f"a call of {name}: this checker does not follow calls yet")


def order(spec, A, e, env):
    """A comparison of two numbers as numbers known not to be below zero."""
    if e[0] != "bin" or e[1] not in (">=", "<=", ">", "<", "=="): raise Err("something that is not an order of two numbers")
    x, y = Lin.of(spec.eval(A, e[2], env)), Lin.of(spec.eval(A, e[3], env))
    return {">=": [x - y], "<=": [y - x], ">": [x - y - 1], "<": [y - x - 1], "==": [x - y, y - x]}[e[1]]


# ---------------------------------------------------------------------------------------------------------
# Places.
class Place:
    def __init__(self, at): self.at, self.names, self.facts, self.says, self.any, self.decreases = at, [], [], {}, set(), []


def expression(text):
    p = ode.Parser(text); e = p.expr()
    if p.t[p.i][0] != "end": raise Fail(f"the proof: {text!r} is not one expression")
    return e


def location(text):
    """A register, or `stack[N]`: the eight bytes N above the stack pointer as it is at the place."""
    text = text.strip()
    if text in G64 and text != "rsp": return ("reg", text)
    m = re.fullmatch(r"stack\[(\d+)\]", text)
    if m and int(m.group(1)) % 8 == 0: return ("stack", int(m.group(1)))
    raise Fail(f"the proof: {text!r} is not a register or stack[N]")


def read_proof(text, c):
    """The places of a proof: {address: Place}."""
    places, p = {}, None
    for raw in text.split("\n"):
        line = raw.split("//")[0].strip()
        if not line: continue
        m = re.fullmatch(r"place \+(0x[0-9a-fA-F]+) \{", line)
        if m: p = Place(BASE + int(m.group(1), 16)); places[p.at] = p; continue
        if p is None: raise Fail(f"the proof: {line!r} outside a place")
        if line == "}": p = None; continue
        m = re.fullmatch(r"name (\w+) = ([\w\[\]]+)(?: - (\w+))?", line)
        if m:
            if m.group(3) is not None and c.kind.get(m.group(3)) in (None, "number"): raise Fail(f"the proof: {line!r}")
            p.names.append((m.group(1), location(m.group(2)), m.group(3))); continue
        if line.startswith("fact "): p.facts.append(expression(line[5:])); continue
        if line.startswith("any "): p.any |= {location(r) for r in line[4:].split(",")}; continue
        if line.startswith("decreases "):
            depth, part, parts = 0, "", []
            for ch in line[10:]:                        # E1, E2, ...: by the first, then the second, ...
                depth += ch in "([" ; depth -= ch in ")]"
                if ch == "," and depth == 0: parts.append(part); part = ""
                else: part += ch
            p.decreases = [expression(x) for x in parts + [part]]; continue
        m = re.fullmatch(r"([\w\[\]]+) = (.+)", line)
        if not m: raise Fail(f"the proof: {line!r}")
        e, region = expression(m.group(2)), None
        if e[0] == "name" and c.kind.get(e[1]) not in (None, "number"): region, e = e[1], ("num", 0)
        elif e[0] == "bin" and e[1] == "+" and e[2][0] == "name" and c.kind.get(e[2][1]) not in (None, "number"): region, e = e[2][1], e[3]
        p.says[location(m.group(1))] = (region, e)
    return places


def get(e, loc):
    if loc[0] == "reg": return e.g[loc[1]]
    cell = e.mem["frame"].get(e.g["rsp"][2] + loc[1])
    if cell is None or cell[1] != "q": raise Fail(f"stack[{loc[1]}]: nothing the code wrote as eight bytes is there")
    return cell[2]


def put(m, loc, v):
    if loc[0] == "reg": m.g[loc[1]] = v
    else: m.mem["frame"][m.g["rsp"][2] + loc[1]] = (8, "q", v)


def show(loc): return loc[1] if loc[0] == "reg" else f"stack[{loc[1]}]"


def stable(m, v):
    """Is this the same on every path: a plain number, something as it was at entry, or made of the arguments?"""
    own = {s for x in m.given.values() if isinstance(x, Lin) for s, _ in x.c}
    made = lambda x: all(s in own for s, _ in Lin.of(x).c)
    if v[0] == "n": return True
    if v[0] == "q": return v[1].endswith(" at entry") or v[1] == "return address"
    if v[0] == "l": return made(v[1])
    if v[0] == "a": return made(v[2])
    return False


def same(F, v, w):
    if lin(v) is not None and lin(w) is not None: return F.zero(lin(v) - lin(w)) is True
    if v[0] == "a" and w[0] == "a": return v[1] == w[1] and F.zero(Lin.of(v[2]) - Lin.of(w[2])) is True
    return v == w


def bind(e, p):
    """The names of a place, as e holds them."""
    env = dict(e.given)
    for name, loc, region in p.names:
        v = get(e, loc)
        if region is None:
            if lin(v) is None: raise Fail(f"{show(loc)} holds {v}: not a number to call {name}")
            env[name] = plain(lin(v))
        else:
            if v[0] != "a" or v[1] != region: raise Fail(f"{show(loc)} holds {v}: not an address in {region}")
            env[name] = plain(Lin.of(v[2]))
        if e.tainted(env[name]): raise Fail(f"{name} depends on bytes the contract does not let the trace depend on")
    return env


def holds(e, p, env, spec, where):
    """What the place says is so in e."""
    A = Algebra(e)
    try:
        for f in p.facts:
            if spec.eval(A, f, env) is not True: raise Fail(f"{where}: a fact of the place at +{p.at - BASE:#x} does not hold")
        for loc, (region, x) in p.says.items():
            want, v = Lin.of(spec.eval(A, x, env)), get(e, loc)
            if region is None:
                if lin(v) is None or e.facts.zero(lin(v) - want) is not True: raise Fail(f"{where}: {show(loc)} holds {v}, the place says {want}")
            elif v[0] != "a" or v[1] != region or e.facts.zero(Lin.of(v[2]) - want) is not True: raise Fail(f"{where}: {show(loc)} holds {v}, the place says {region} + {want}")
    except Err as err: raise Fail(f"{where}: what the place at +{p.at - BASE:#x} says cannot be read on this path: {err}")


def said(e, p):
    """The registers and the stack's offsets (from the entry stack pointer) the place speaks of."""
    locs = p.any | set(p.says) | {loc for _, loc, _ in p.names}
    return {loc[1] for loc in locs if loc[0] == "reg"}, {e.g["rsp"][2] + loc[1] for loc in locs if loc[0] == "stack"}


def kept(e, first, p, where):
    """What the place does not speak of, and was the same on every path when the place was first come to, is so still."""
    regs, cells = said(first, p)
    for r in HELD:
        if r not in regs and stable(first, first.g[r]) and not same(e.facts, e.g[r], first.g[r]): raise Fail(f"{where}: at +{p.at - BASE:#x} {r} holds {e.g[r]}, and held {first.g[r]} when the place was first come to")
    for off, cell in first.mem["frame"].items():
        if off not in cells and stable(first, cell[2]) and e.mem["frame"].get(off) != cell:
            raise Fail(f"{where}: at +{p.at - BASE:#x} stack[{off - first.g['rsp'][2]}] is not as it was when the place was first come to (it held {cell[2]})")


def start(entry, first, p, spec):
    """The machine at a place, for any numbers its names may be: (machine, the names)."""
    m = first.clone()
    m.facts, m.secret, m.bytes, m.seqs = entry.facts.clone(), set(entry.secret), set(entry.bytes), {}
    m.x, m.flags, m.conds, m.back, m.pc, m.since = {}, None, {}, {}, p.at, m.steps
    if not stable(first, first.g["rsp"]): raise Fail("at a place the stack pointer is not the same on every path")
    for r in G64:
        if r not in HELD or not stable(first, first.g[r]): m.g[r] = ("q", f"{r}?{next(FRESH)}")
    for off, (size, kind, v) in list(m.mem["frame"].items()):
        if kind != "q": del m.mem["frame"][off]
        elif not stable(first, v): m.mem["frame"][off] = (size, "q", ("q", f"stack?{next(FRESH)}"))
    env = dict(m.given)
    for name, loc, region in p.names:
        s = sym(f"{name}@{p.at - BASE:#x}"); m.facts.add(s); m.facts.add(WORD64 - s)
        env[name] = s
        put(m, loc, ("l", s) if region is None else ("a", region, s))
    A = Algebra(m)
    try:
        for f in p.facts:
            for x in order(spec, A, f, env): m.facts.add(x)
        for loc, (region, x) in p.says.items():
            v = spec.eval(A, x, env)
            put(m, loc, value(Lin.of(v)) if region is None else ("a", region, plain(Lin.of(v))))
        for x in p.decreases:
            if not m.facts.ge0(Lin.of(spec.eval(A, x, env))): raise Fail(f"a number the place at +{p.at - BASE:#x} says decreases is not shown to stay at or above zero")
    except Err as err: raise Fail(f"what the place at +{p.at - BASE:#x} says cannot be read: {err}")
    for loc in p.any: put(m, loc, ("q", f"{show(loc)}?{next(FRESH)}"))
    if not m.facts.consistent(): raise Fail(f"the facts of the place at +{p.at - BASE:#x} cannot all hold")
    return m, env


def less(e, spec, before, env0, after, env, where):
    """From one place to the next the numbers that decrease are less: the first of them, or the first the same
    (or less) and the second less, and so on. So no path goes from place to place for ever."""
    A = Algebra(e)
    if not before or not after: raise Fail(f"{where}: the code goes from a place to a place, and one of them names no number that decreases")
    try:
        for x, y in zip(before, after):
            x, y = Lin.of(spec.eval(A, x, env0)), Lin.of(spec.eval(A, y, env))
            if e.facts.ge0(x - 1 - y): return
            if not e.facts.ge0(x - y): break
    except Err as err: raise Fail(f"{where}: the numbers that decrease cannot be read: {err}")
    raise Fail(f"{where}: the numbers that decrease are not shown to be less at the place the code comes to")


def run(m, places, budget):
    """Every path of m to its end: a place (after at least one instruction) or the return."""
    ends, work = [], [m]
    while work:
        m = work.pop()
        while True:
            if m.pc is None or (m.pc in places and m.steps > m.since): ends.append(m); break
            if budget[0] <= 0: raise Fail(f"still running after {STEPS} instructions: a loop that needs a place")
            try:
                m.one(); budget[0] -= 1
            except kfn.Fork as f:
                yes, no = m.clone(), m.clone()
                if f.kind == "zero": yes.facts.assume_zero(f.x); no.facts.assume_nonzero(f.x)
                elif f.kind == "ge": yes.facts.add(f.x); no.facts.add(-f.x - 1)
                else: yes.conds[f.x] = True; no.conds[f.x] = False
                work += [side for side in (yes, no) if side.facts.consistent()]; break
    return ends


def returned(e, c, where):
    A = Algebra(e)
    if c.text["returns"] is not None:
        try: want = Lin.of(c.spec.eval(A, c.text["returns"], dict(e.given)))
        except (Err, ode.Fails) as err: raise Fail(f"{where}: the specification cannot be followed on this path: {err}")
        if lin(e.g["rax"]) is None or e.facts.zero(lin(e.g["rax"]) - want) is not True: raise Fail(f"{where}: the result is {e.g['rax']}, the contract says {want}")
    for r in KEPT:
        if e.g[r] != ("q", r + " at entry"): raise Fail(f"{where}: {r} is not restored")
    within(e, c, where)


def within(e, c, where):
    if -e.low > c.stack: raise Fail(f"{where}: {-e.low} bytes of stack used, the contract gives {c.stack}")


def check(rows, spec, symbol, proof=""):
    """The function's instructions meet its contract. Raises Fail; returns a tally."""
    c, T = Contract(spec, symbol), kcheck.Terms()
    places = read_proof(proof, c)
    for at in places:
        if at not in {a for a, _, _ in rows}: raise Fail(f"the proof: no instruction at +{at - BASE:#x}")
    entry = Machine(T, rows, c); entry.pc = rows[0][0]
    base = entry.clone()
    first, work, budget, tally = {}, [(None, None, entry)], [STEPS], {"return": 0, "place": 0}
    while work:
        origin, env0, m0 = work.pop()
        where = "from the entry" if origin is None else f"from the place at +{origin - BASE:#x}"
        for e in run(m0, places, budget):
            if e.pc is None:
                tally["return"] += 1; returned(e, c, where); continue
            tally["place"] += 1
            p = places[e.pc]
            env = bind(e, p)
            if e.pc not in first:
                first[e.pc] = e
                m, names = start(base, e, p, spec)
                work.append((e.pc, names, m))
            kept(e, first[e.pc], p, where)
            holds(e, p, env, spec, where)
            within(e, c, where)
            if origin is not None: less(e, spec, places[origin].decreases, env0, p.decreases, env, f"{where} to +{e.pc - BASE:#x}")
    if set(places) - set(first): raise Fail("the proof has a place the code does not come to")
    if not tally["return"]: raise Fail("no path returns")
    tally["instructions"] = STEPS - budget[0]
    return tally


def load(obj, symbol):
    rows, _ = kdecode.read(obj, symbol, BASE, DATA)
    more = kdecode.features(obj, symbol)
    if more: raise Fail(f"{symbol} holds instructions not every x86-64 processor has: {', '.join(sorted(more))}")
    return rows


def main():
    with open(sys.argv[1]) as f: spec = ode.Spec(f.read())
    symbol, obj = sys.argv[2], sys.argv[3]
    proof = ""
    if len(sys.argv) > 4:
        with open(sys.argv[4]) as f: proof = f.read()
    rows = load(obj, symbol)
    t0 = time.time()
    tally = check(rows, spec, symbol, proof)
    print(f"{symbol}: the {len(rows)} instructions meet the contract, for everything it allows")
    print(f"     checked in {time.time() - t0:.3f} s: {tally['return']} path(s) to the return, {tally['place']} to a place, {tally['instructions']} instructions run")
    return 0


if __name__ == "__main__":
    try: sys.exit(main())
    except (Fail, kdecode.Stop) as e:
        print(f"kbyte: NOT shown: {e}"); sys.exit(1)
