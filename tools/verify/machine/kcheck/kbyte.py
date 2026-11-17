#!/usr/bin/env python3
"""kbyte: a function over bytes and numbers, shown to meet its contract from the binary's bytes.

    python3 kbyte.py SPEC SYMBOL OBJECT [PROOF]

SPEC holds the specification and the contract of SYMBOL (LANGUAGE.md, part 2, says what a contract means); OBJECT
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

    The verifier runs the code from the entry to the place, and from the place (the names any numbers the
    facts allow, the registers as said, the registers a callee keeps and the stack as they were if they
    were the same on every path, everything else unknown) to the place again or to the return. Every arrival must show what the place says. So each loop is run once, for every count.

A byte read is a number from 0 to 255 that the verifier gives a name (`input[i]`); the specification read on
the same path gives the same name to the same byte. Numbers are compared by adding linear facts up
(klin.py): no solver. A sequence of the specification at a place the path does not fix is a number with a
name; at the place after one that is known it is the sequence's own equation of it.

The machine's instructions are kfn.py's reading of them (this file is a second kind of memory under the same
machine: bytes with a length, in place of BLAKE3's words).

A call of another function is by that function's contract (`Machine.call`): what it requires is shown at the
call; what it ensures is so after it; nothing else of it is used, and it is checked apart. The specification
given must hold the callee's contract. `check` returns the names called: whoever runs it sees that each is
checked too, and that no function is called by what it calls.

WHAT IS NOT CHECKED HERE: this verifier (Python, unverified)."""
import itertools, os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kdecode, kfn, kspec, kterms, ode
from kterms import Fail
from klin import Lin, Facts, sym, value, lin
from kspec import plain, halved
from ode import Err

BASE, DATA, G64, KEPT, ARGS, WORD64 = kfn.BASE, kfn.DATA, kfn.G64, kfn.KEPT, kfn.ARGS, kfn.WORD64
STEPS = 2000000
PATH = 1000             # instructions on one path from the entry or a place to the next place or the return (the longest here: 286)
HELD = tuple(KEPT) + ("rsp",)        # at a place, what these hold is kept if it was the same on every path; the others are unknown unless the place says
FRESH = itertools.count()
DEBUG = bool(os.environ.get("KBYTE_DEBUG"))


class View:
    """n bytes of the memory an argument addresses, from the offset `off`."""
    def __init__(self, region, off, n): self.region, self.off, self.n = region, Lin.of(off), Lin.of(n)


class Rope:
    """Bytes in order, in parts: ("view", region, off, n): n bytes of memory given to read; ("list", name, n): n
    bytes with a name; ("one", x): one byte, the number x."""
    def __init__(self, parts=()): self.parts = tuple(parts)
    def __repr__(self): return "rope(" + " ++ ".join(f"{p[1]}[{p[2]!r} +{p[3]!r}]" if p[0] == "view" else f"{p[1]}" if p[0] == "list" else f"[{p[1]!r}]" for p in self.parts) + ")"


class Opaque:
    """A definition applied to things, where the path does not let it be worked out: named by what it is of."""
    def __init__(self, name, args): self.name, self.args = name, tuple(args)
    def __repr__(self): return f"{self.name}({', '.join(map(repr, self.args))})"


class Any:
    """A thing of which nothing is known and nothing is asked: what a lemma is given or says of kind `any`, and
    what words make in an opening (this verifier's programs are of bytes and numbers: a word is only passed on)."""
    def __init__(self, title): self.title = title
    def __repr__(self): return f"any {self.title}"


class Failure:
    """A definition that fails, as a value (so that it can be what something is known to be)."""
    def __init__(self, reason): self.reason = reason


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
            if kind != "number" and n is None: raise Fail(f"{symbol}: {name} is of a kind this verifier does not know: {kind}")
            if isinstance(n, str) and self.kind.get(n) != "number": raise Fail(f"{symbol}: {name} is {kind}, and {n} is not a number among the arguments")
        if c["calls"] or c["needs"] or c["given"] or c["decreases"] is not None: raise Fail(f"{symbol}: a clause this verifier does not know")
        if not isinstance(c["stack"], int): raise Fail(f"{symbol}: the stack it may use is not a plain number")
        # `returns r`, r a name the specification does not have: the number returned is called r, and `ensures` lines speak of it
        r = c["returns"]
        self.result = r[1] if r is not None and r[0] == "name" and r[1] not in self.kind and r[1] not in spec.consts else None
        for leaf in c["leaves"]:
            if leaf["index"] is not None: raise Fail(f"{symbol}: `ensures X[i] = ... for i`: not this verifier's")
            if leaf["name"] != self.result and self.kind.get(leaf["name"]) in (None, "number"): raise Fail(f"{symbol}: it ensures something of {leaf['name']}, which is not at an address among its arguments nor the result")
        self.writes = set(c["spoils"]) | {leaf["name"] for leaf in c["leaves"] if leaf["name"] != self.result}
        self.held = set(self.writes)                           # what the verifier keeps the bytes of: all it may write
        self.stack, self.trace, self.conditions = c["stack"], set(c["trace"]), c["conditions"]
        # What is written is taken to overlap nothing else given: the contract must ask it of the caller.
        # (Things that are only read may overlap: their bytes are then any bytes, alike or not.)
        addresses = [name for _, kind, name in self.args if kind != "number"]
        if self.writes and len(addresses) > 1 and sorted(c["no_overlap"] or []) != sorted(addresses):
            raise Fail(f"{symbol}: the contract does not say `requires no_overlap({', '.join(addresses)})`: what it writes is taken to overlap none of the other things it is given")
        for name in self.writes | self.trace:
            if self.kind.get(name) in (None, "number"): raise Fail(f"{symbol}: {name} is not something at an address among its arguments")


class Undecided(Err):
    """Two numbers the path does not say how to compare: x is zero or not (`zero`), x is at least 0 or not (`ge`)."""
    def __init__(self, text, kind, x): super().__init__(text); self.kind, self.x = kind, x


# ---------------------------------------------------------------------------------------------------------
# The specification read on a path: numbers that depend on counts, bytes with names, sequences.
class Algebra:
    def __init__(self, m): self.m, self.facts, self.T = m, m.facts, m.T
    def word(self, n): raise Err("a word: this verifier's programs are of bytes and numbers")
    counter = add = xor = or_ = rotr = words = word
    def num(self, x):
        if isinstance(x, bool) or not isinstance(x, (int, Lin)): raise Err("a number expected")        # a thing with a name only is none
        return x
    def plus(self, x, y): return plain(Lin.of(self.num(x)) + Lin.of(self.num(y)))
    def compare(self, op, a, b):
        numbers = lambda x: isinstance(x, (int, Lin)) and not isinstance(x, bool)
        if not (numbers(a) and numbers(b)):
            # two things that are not numbers: the same if they are shown to be; never shown to differ
            if op == "==" and self.same(a, b): return True
            raise Err("the specification asks whether two things are the same, and the code's path does not show it")
        d = self.facts.subst(Lin.of(a) - Lin.of(b))
        if not d.c: return {"==": d.k == 0, "!=": d.k != 0, "<": d.k < 0, "<=": d.k <= 0, ">": d.k > 0, ">=": d.k >= 0}[op]
        if op in ("==", "!="):
            z = self.facts.zero(d)
            if z is None: raise Undecided(f"the specification asks whether {Lin.of(a)} is {Lin.of(b)}, and the code's path does not say", "zero", d)
            return z == (op == "==")
        if op in (">=", "<"): yes = True if self.facts.ge0(d) else False if self.facts.ge0(-d - 1) else None
        else: d = d - 1; yes = True if self.facts.ge0(d) else False if self.facts.ge0(-d - 1) else None
        if yes is None: raise Undecided(f"the specification asks how {Lin.of(a)} and {Lin.of(b)} compare, and the code's path does not say", "ge", d)
        return yes if op in (">=", ">") else not yes
    def minus(self, x, y):
        d = Lin.of(self.num(x)) - Lin.of(self.num(y))
        if not self.facts.ge0(d): raise Err(f"the specification takes {Lin.of(y)} from {Lin.of(x)}, and the code's path does not show the result is not below zero")
        return plain(d)
    def mul(self, x, y):
        x, y = plain(self.num(x)), plain(self.num(y))
        if isinstance(x, int): return plain(Lin.of(y).scale(x))
        if isinstance(y, int): return plain(x.scale(y))
        raise Err("a product of two numbers that both depend on counts")
    def quotient(self, x, d):
        """(x / d, x % d) for a plain d: by the path's facts; for a power of two, a number with a name."""
        d, x = ode.Spec.number(d), Lin.of(self.num(x))
        if d < 1: raise Err("a division by nothing")
        if not x.c: return x.k // d, x.k % d
        for q in range(4):                                  # the path says which multiple of d it is at or above
            if self.facts.ge0(x - q * d) and self.facts.ge0(q * d + d - 1 - x): return q, plain(x - q * d)
        q = self.m.halve(x, d)
        return plain(Lin.of(q)), plain(x - Lin.of(q).scale(d))
    def div(self, x, d): return self.quotient(x, d)[0]
    def mod(self, x, d): return self.quotient(x, d)[1]
    def plain(self, x):
        n = self.facts.number(Lin.of(x)) if isinstance(x, (int, Lin)) and not isinstance(x, bool) else None
        if n is None: raise Err(f"a plain number expected, not {x!r}")
        return n
    def length(self, x):
        if isinstance(x, Rope): return plain(sum((Lin.of(1) if q[0] == "one" else q[-1] for q in self.rope(x.parts).parts), Lin.of(0)))
        if isinstance(x, View): return plain(x.n)
        if not isinstance(x, list): raise Err("the length of something that is not a list")
        return len(x)
    def index(self, x, i):
        if isinstance(x, Rope):
            i, c = Lin.of(self.num(i)), Lin.of(0)
            for q in self.rope(x.parts).parts:
                n = Lin.of(1) if q[0] == "one" else q[-1]
                if self.facts.ge0(i - c) and self.facts.ge0(c + n - 1 - i):
                    if q[0] == "one": return plain(q[1])
                    if q[0] == "view": return plain(self.m.byte(q[1], q[2] + i - c))
                    return plain(self.m.item(q[1], i - c))
                if not self.facts.ge0(i - c - n): raise Err(f"place {i} of a list in parts: the path does not say which part it is in")
                c = c + n
            raise Err(f"place {i} of a list: not shown to be one of its places")
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
        if isinstance(x, Rope):
            # the parts from a to b: whole parts, and of bytes of memory any run
            a, b, c, out = Lin.of(self.num(a)), Lin.of(self.num(b)), Lin.of(0), []
            F = self.facts
            for q in self.rope(x.parts).parts:
                n = Lin.of(1) if q[0] == "one" else Lin.of(q[-1])
                if F.ge0(a - c - n) or F.ge0(c - b): c = c + n; continue                    # before a, or from b on
                if F.ge0(c - a) and F.ge0(b - c - n): out.append(q); c = c + n; continue     # within
                if q[0] != "view": raise Err("part of a list in parts: it does not begin and end where parts do")
                s = a - c if F.ge0(a - c) else Lin.of(0) if F.ge0(c - a) else None
                t = b - c if F.ge0(c + n - b) else n if F.ge0(b - c - n) else None
                if s is None or t is None: raise Err("part of a list in parts: the path does not say where it begins or ends")
                out.append(("view", q[1], plain(Lin.of(q[2]) + s), plain(t - s))); c = c + n
            if not F.ge0(c - b): raise Err("part of a list in parts: not shown to be within it")
            return self.rope(out)
        return ode.part(x, a if isinstance(a, int) else self.plain(a), b if isinstance(b, int) else self.plain(b))
    def concat(self, x, y):
        if isinstance(x, list) and isinstance(y, list) and all(isinstance(v, int) for v in x + y): return x + y
        return self.rope(self.parts(x) + self.parts(y))
    def parts(self, x):
        if isinstance(x, Rope): return list(x.parts)
        if isinstance(x, View): return [("view", x.region, x.off, x.n)]
        if isinstance(x, list): return [("one", Lin.of(self.num(v))) for v in x]
        raise Err("a list expected")
    def rope(self, parts):
        """Parts as a rope: none of no bytes; bytes of memory that follow one another as one part."""
        out, parts = [], list(parts)
        while parts:
            q = parts.pop(0)
            if q[0] == "list" and q[1] in self.m.lists:        # a list with a name, known to be something: that
                parts = self.parts(self.m.lists[q[1]]) + parts; continue
            n = Lin.of(1) if q[0] == "one" else q[-1]
            if self.facts.zero(n) is True: continue
            if out and out[-1][0] == "view":
                _, r, off, k = out[-1]
                if q[0] == "view" and q[1] == r and self.facts.zero(off + k - q[2]) is True: out[-1] = ("view", r, off, plain(Lin.of(k) + q[3])); continue
                if q[0] == "one" and self.facts.zero(Lin.of(q[1]) - sym(self.m.byte_name(r, Lin.of(off) + k))) is True and self.m.byte_name(r, Lin.of(off) + k) in self.m.bytes:
                    out[-1] = ("view", r, off, plain(Lin.of(k) + 1)); continue
            out.append(q)
        return Rope(out)
    def known(self, x, depth=0):
        """What a named thing is known to be on this path (itself, if nothing)."""
        if isinstance(x, Opaque) and depth < 20:
            for k, v in self.m.learned + self.m.equal:
                if self.alike(x, k): return self.known(v, depth + 1)
        return x
    def alike(self, a, b):
        """Two named things are one thing: the same definition of the same things."""
        return a.name == b.name and len(a.args) == len(b.args) and all(self.same(x, y) for x, y in zip(a.args, b.args))
    def same(self, a, b):
        """Are two values shown to be one? (Numbers by the facts; lists part by part; named things by their names.)"""
        a, b = self.known(a), self.known(b)
        numbers = lambda x: isinstance(x, (int, Lin)) and not isinstance(x, bool)
        if numbers(a) and numbers(b): return self.facts.zero(Lin.of(a) - Lin.of(b)) is True
        if isinstance(a, Opaque) or isinstance(b, Opaque): return isinstance(a, Opaque) and isinstance(b, Opaque) and self.alike(a, b)
        if isinstance(a, Failure) or isinstance(b, Failure): return isinstance(a, Failure) and isinstance(b, Failure) and a.reason == b.reason
        if isinstance(a, dict) or isinstance(b, dict): return isinstance(a, dict) and isinstance(b, dict) and sorted(a) == sorted(b) and all(self.same(a[k], b[k]) for k in a)
        if isinstance(a, (Rope, View, list)) and isinstance(b, (Rope, View, list)):
            try: x, y = self.rope(self.parts(a)).parts, self.rope(self.parts(b)).parts
            except Err: return False
            if len(x) != len(y): return False
            for q, w in zip(x, y):
                if q[0] != w[0]: return False
                if q[0] == "one":
                    if self.facts.zero(Lin.of(q[1]) - Lin.of(w[1])) is not True: return False
                elif q[1] != w[1] or any(self.facts.zero(Lin.of(u) - Lin.of(v)) is not True for u, v in zip(q[2:], w[2:])): return False
            return True
        return a is b or (type(a) == type(b) and a == b)
    def kept(self, name, args, body):
        """A definition applied: what it is known to be; else worked out; else, where the path does not let it
        be worked out, named by what it is of."""
        me = Opaque(name, args)
        v = self.known(me)
        if v is not me:
            if isinstance(v, Failure): raise ode.Fails(v.reason)
            return v
        try: return body()
        except Err as err:
            if DEBUG: print(f"      {name}: named, not worked out: {err}")
            return me
    def defined(self, v):
        v = self.known(v)
        if not isinstance(v, Opaque) or any(self.alike(v, k) for k in self.m.fine): return
        raise Undecided("the specification asks whether something has a value, and the code's path does not say", "defined", v)
    def element(self, spec, seq, i):
        v = self.element_of(spec, seq, i)
        if seq.id is not None and seq.id[0] in spec.lemmas:
            # the sequence has a lemma (shown before anything else: prove_lemmas): where it applies, it holds of this place
            l = spec.lemmas[seq.id[0]]
            env = applies(spec, self, l, seq.id[1])
            if env is not None and self.facts.ge0(Lin.of(self.num(i))):
                env[l["index"]] = i; env["result"] = v
                try:
                    for e in l["ensures"]:
                        for f in order(spec, self, e, env): self.facts.add(f)
                except Err: pass
        return v

    def element_of(self, spec, seq, i):
        """A sequence's value at place i. At a place the path fixes: worked out. At a place one after a place
        whose value is known: the sequence's equation of it. Else: a number, or a list, with a name."""
        if seq.id is None: return seq.at(spec, self, self.plain(i))
        i = self.facts.subst(Lin.of(self.num(i)))
        name, args = seq.id
        table = next((tb for nm, others, tb in self.m.seqs if nm == name and len(others) == len(args) and all(self.same(x, y) for x, y in zip(args, others))), None)
        if table is None:
            table = []; self.m.seqs.append((name, list(args), table))
        def title_of(v):
            """The name of a value that is a name only (a number or a list made here for a place not known)."""
            if isinstance(v, Lin) and len(v.c) == 1 and v.k == 0 and v.c[0][1] == 1 and v.c[0][0] in self.m.elements: return v.c[0][0]
            if isinstance(v, Rope) and len(v.parts) == 1 and v.parts[0][0] == "list" and v.parts[0][1] in self.m.elements and v.parts[0][1] not in self.m.lists: return v.parts[0][1]
            return None
        for j, v in table:
            if self.facts.zero(i - j) is True:
                # a name only, and the path now knows the place before it: it is the sequence's equation of that
                before = next((k for k, _ in table if self.facts.zero(i - k - 1) is True), None)
                if title_of(v) is None or before is None: return v
                inner = dict(seq.env); inner[seq.var] = plain(before)
                u = spec.eval(self, seq.next, inner)
                if isinstance(v, Lin):
                    d = v - Lin.of(self.num(u)); self.facts.add(d); self.facts.add(-d)
                else:
                    d = Lin.of(v.parts[0][2]) - Lin.of(self.length(u)); self.facts.add(d); self.facts.add(-d)
                    self.m.lists[title_of(v)] = u
                return u
        n = self.facts.number(i)
        if n is None and not any(self.facts.zero(i - j - 1) is True for j, _ in table):
            # a few places after a place that is known: the places between, one after another, each by the
            # sequence's own equation
            for j, _ in list(table):
                d = self.facts.number(i - j)
                if d is not None and 2 <= d <= 16:
                    for m in range(1, d): self.element(spec, seq, plain(Lin.of(j) + m))
                    break
        if n is not None and n > 4096 and not any(self.facts.zero(i - j - 1) is True for j, _ in table):
            raise Err(f"place {n} of a sequence, with no place near it known: more places than this verifier works out one by one")
        below = Lin.of(n - 1) if n is not None and n > 0 else next((j for j, _ in table if self.facts.zero(i - j - 1) is True), None)
        if n == 0: v = spec.eval(self, seq.first, seq.env)
        elif below is not None:
            if n is not None: self.element(spec, seq, below)
            inner = dict(seq.env); inner[seq.var] = plain(below)
            v = spec.eval(self, seq.next, inner)
        else:
            if not self.facts.ge0(i): raise Err(f"place {i} of a sequence: not shown to be a place of it")
            title = f"{name}.{next(FRESH)}[{i!r}]"
            if isinstance(spec.eval(self, seq.first, seq.env), (Rope, View, list)):
                # a sequence of lists: a list with a name, of a length with a name
                self.facts.add(sym("#" + title)); self.m.elements.add(title)
                v = Rope([("list", title, sym("#" + title))])
            else:
                v = sym(title); self.facts.add(v); self.m.elements.add(title)
                first, nxt = seq.first, seq.next
                if nxt[0] == "bin" and nxt[1] == "%" and nxt[3][0] == "num" and first[0] == "num" and first[1] < nxt[3][1]:
                    self.facts.add(nxt[3][1] - 1 - v)                    # every value of it is one of the remainders
                if any(isinstance(a, View) and a.region not in self.m.contract.trace for a in args): self.m.secret.add(title)
        table.append((i, v))
        return v


# ---------------------------------------------------------------------------------------------------------
# The machine: kfn.py's, with memory that is bytes.
class Machine(kfn.Machine):
    BOUNDARY = False                    # a program of bytes has no frame on a 64-byte boundary (kfn.py)

    def __init__(self, T, rows, c):
        self.T, self.rows, self.contract = T, {a: (n, kterms.parse(i)) for a, n, i in rows}, c
        self.g = {r: ("q", r + " at entry") for r in G64}
        self.g["rsp"] = ("a", "frame", 0)
        self.x, self.flags, self.facts, self.conds, self.memo = {}, None, Facts(), {}, {}
        self.facts.thorough = True
        self.mem = {"frame": {0: (8, "q", ("q", "return address"))}}
        self.readonly, self.given, self.len = set(), {}, {}
        self.low, self.pc, self.steps, self.back, self.since = 0, None, 0, {}, 0
        self.secret, self.bytes, self.seqs = set(), set(), []
        self.held = {name: Rope() for name in c.held}        # the bytes written at the start of what the contract ensures something of
        self.equal = []                                      # at a path's end: named things and what they are known to be
        self.named = {}                                      # the names given to bytes: {region or list: [(where, name)]}
        self.halves = []                                     # the names given to quotients: [(of what, by what, the name)]
        self.elements, self.lists = set(), {}                # the names given to lists of sequences; what such a list is known to be
        self.fine, self.calling = [], False                  # named things known to have a value (a callee's contract said so); within a call
        self.learned = []                                    # named things and what a callee's contract has made them known to be
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
        c.secret, c.bytes, c.seqs = set(self.secret), set(self.bytes), [(n, a, list(tb)) for n, a, tb in self.seqs]
        c.elements, c.lists, c.fine, c.learned = set(self.elements), dict(self.lists), list(self.fine), list(self.learned)
        c.held, c.equal, c.named, c.halves = dict(self.held), list(self.equal), {k: list(v) for k, v in self.named.items()}, list(self.halves)
        return c

    # -- bytes
    def place_name(self, of, off):
        """The name of place `off` of something (a region, a list): the name it was first given, whatever has
        been learned since of the numbers that say where it is; None if it has none yet."""
        off = Lin.of(off)
        for other, name in self.named.get(of, ()):
            if self.facts.zero(off - other) is True: return name
        return None

    def byte_name(self, region, off):
        return self.place_name(region, off) or f"{region}[{self.facts.subst(Lin.of(off))!r}]"

    def number_at(self, of, off, secret):
        name = self.place_name(of, off)
        if name is None:
            name = f"{of}[{self.facts.subst(Lin.of(off))!r}]"
            self.named.setdefault(of, []).append((Lin.of(off), name))
        if name not in self.bytes:
            self.bytes.add(name); self.facts.add(sym(name)); self.facts.add(255 - sym(name))
            if secret: self.secret.add(name)
        return sym(name)

    def item(self, name, i):
        """Place i of a list with a name, as a number with a name."""
        return self.number_at(name, i, True)

    def byte(self, region, off):
        """The byte at region + off as a number with a name: the same name for the same place."""
        return self.number_at(region, off, region not in self.contract.trace)

    def halve(self, x, d):
        """x / d for d a power of two, as a number with a name: the name the same number was first given."""
        x = Lin.of(x)
        for other, d2, q in self.halves:
            if d2 == d and self.facts.zero(x - other) is True: return q
        if d & (d - 1) == 0: q = halved(self.facts, x, d)
        else:
            if not self.facts.ge0(x): raise Err(f"{x} is divided, and is not shown to be a number not below zero")
            q = sym(f"({x!r})/{d}")
            self.facts.add(q); self.facts.add(x - q.scale(d)); self.facts.add(q.scale(d) + d - 1 - x)
        self.halves.append((x, d, q))
        return q

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
        if size != 1: raise Fail(f"a read of {size} bytes of {region}: this verifier follows one byte at a time")
        off = Lin.of(off); self.inside(region, off, "read")
        if region in self.readonly: return ("l", self.byte(region, off))
        rope = self.held.get(region)
        if rope is not None:
            A = Algebra(self)
            if self.facts.ge0(Lin.of(A.length(rope)) - 1 - off):
                try: return value(Lin.of(A.index(rope, off)))
                except Err as e: raise Fail(f"a read at {region} + {off}: {e}")
        name = f"{region}?{next(FRESH)}"                    # of what else the function has written nothing is kept
        self.facts.add(sym(name)); self.facts.add(255 - sym(name))
        if region not in self.contract.trace: self.secret.add(name)
        return ("l", sym(name))

    def store(self, region, off, size, new):
        if region == "frame": return super().store(region, off, size, new)
        if region not in self.len: raise Fail(f"an address in {region}: no such memory")
        if region in self.readonly: raise Fail(f"a write to {region}, which the contract gives to read")
        if size != 1: raise Fail(f"a write of {size} bytes of {region}: this verifier follows one byte at a time")
        off = Lin.of(off); self.inside(region, off, "write")
        rope = self.held.get(region)
        if rope is not None:
            # the bytes kept are those from the start: a write at their end is one more; elsewhere, nothing is kept any more
            A = Algebra(self)
            v = lin(new)
            if self.facts.zero(Lin.of(A.length(rope)) - off) is True and v is not None and self.facts.ge0(v) and self.facts.ge0(255 - v):
                self.held[region] = A.rope(list(rope.parts) + [("one", Lin.of(v))])
            else: self.held[region] = None

    # -- instructions: a mask that is the low bits; a branch that may depend only on what the contract lets it
    def arith(self, op, x, y):
        try:
            if op == "and" and x[0] == "l" and y[0] == "n" and y[1] > 0 and (y[1] + 1) & y[1] == 0 and y[1] < 1 << 32:
                return value(x[1] - Lin.of(self.halve(x[1], y[1] + 1)).scale(y[1] + 1))
            if op == "shr" and x[0] == "l" and 0 < y[1] < 64 and not self.facts.ge0((1 << y[1]) - 1 - x[1]):
                return value(self.halve(x[1], 1 << y[1]))
            if op == "or" and lin(x) is not None and lin(y) is not None:
                # two numbers with no bit in common: their `or` is their sum. One is a multiple of 2^k (every part
                # of it is), the other is shown to be below 2^k.
                for a, b in ((lin(x), lin(y)), (lin(y), lin(x))):
                    k = min([(c & -c).bit_length() - 1 for _, c in a.c] + ([(a.k & -a.k).bit_length() - 1] if a.k else []), default=0)
                    if k > 0 and self.facts.ge0(b) and self.facts.ge0((1 << k) - 1 - b): return value(a + b)
        except Err as e: raise Fail(str(e))
        return super().arith(op, x, y)

    def branch(self, op):
        if self.flags is not None and self.flags[0] == "numbers" and self.tainted(self.flags[1]):
            raise Fail("a branch that depends on bytes in memory: the contract does not say the trace may depend on them")
        return super().branch(op)

    # -- a call of another function: by its contract, and by nothing else of it
    def call(self, name):
        """What the callee's contract requires is shown here; what it ensures is taken as so after it. Nothing
        else is known of the callee (it is checked apart, against the same contract). A question its contract
        asks that this path does not answer (has the specification's value failed? how do two numbers compare?)
        is taken both ways, each as a path of its own."""
        sp = self.g["rsp"][2]
        self.calling = True
        try: used = self.call_contract(name, callee(self.contract.spec, name))
        except Undecided as u: raise kfn.Fork(u.kind, u.x)
        except ode.Fails as e: raise Fail(f"a call of {name}: its contract speaks of something the specification gives no value (it fails with {e.reason})")
        except Err as e: raise Fail(f"a call of {name}: {e}")
        finally: self.calling = False
        # as kfn.py: the facts a callee's contract adds cannot make the path's facts hold falsely together
        # (a path so made would be dropped as no path, and what the code did after the call never checked)
        if not self.facts.consistent():
            raise Fail(f"a call of {name}: what it ensures, with what it is given here, cannot all hold: its contract says nothing of this path")
        CALLED.add(name)
        self.low = min(self.low, sp - used)
        self.left()                                         # (kfn.py: each register a callee may change holds an unknown of its own)

    def public(self, v, what):
        """A list given to a callee holds nothing the trace may not depend on."""
        for q in Algebra(self).parts(v):
            if q[0] == "one" and self.tainted(q[1]): raise Fail(f"{what}: a byte of it depends on bytes the contract does not let the trace depend on")
            if q[0] == "view" and q[1] not in self.readonly: raise Fail(f"{what}: bytes of {q[1]} of which nothing is kept")

    def entitled(self, A, v, title, a_list):
        """A value of the specification that this path cannot work out, as a list or a number with a name: the
        same name wherever the same definition of the same things is asked for again."""
        v = A.known(v)
        if not isinstance(v, Opaque): return v
        if a_list:
            n = sym("#" + title); self.facts.add(n)
            w = Rope([("list", title, n)])
        else:
            w = sym(title); self.facts.add(w)
        self.learned.append((v, w))
        return w

    def call_contract(self, name, c):
        mine, spec, F, A = self.contract, self.contract.spec, self.facts, Algebra(self)
        if name == mine.name: raise Fail("the function calls itself: not this verifier's")
        for _, kind, arg in mine.args:
            if kind != "number" and arg not in mine.writes and arg not in mine.trace:
                raise Fail(f"this function is given {arg} to read and its contract does not let the trace depend on it: what a callee does with such bytes is not followed")
        env, spans = {}, {}
        for reg, kind, arg in c.args:
            if kind != "number": continue
            x = lin(self.g[reg])
            if x is None: raise Fail(f"{arg} is given {self.g[reg]}: not a number")
            if not self.facts.ge0(x): raise Fail(f"{arg} is given {x}: not shown to be a number not below zero")
            if self.tainted(x): raise Fail(f"{arg} is given a number that depends on bytes the contract does not let the trace depend on")
            env[arg] = plain(x)
        for reg, kind, arg in c.args:
            if kind == "number": continue
            a, n = self.g[reg], kfn.bytes_kind(kind)
            if a[0] != "a" or a[1] not in self.len: raise Fail(f"{arg} is given {a}: not an address in something this function was given")
            region, off, count = a[1], Lin.of(a[2]), Lin.of(env[n] if isinstance(n, str) else n)
            if not F.ge0(off) or not F.ge0(self.len[region] - off - count): raise Fail(f"{arg}: {count} bytes at {region} + {off} are not shown to be within its {self.len[region]} bytes")
            if self.tainted(off): raise Fail(f"{arg}: where it is depends on bytes the contract does not let the trace depend on")
            spans[arg] = (region, off, count)
            if arg in c.writes:
                if region in self.readonly: raise Fail(f"{arg} is written by {name}, and {region} is given to this function to read")
            elif region in self.readonly: env[arg] = View(region, off, count)
            else:
                rope = self.held.get(region)
                if rope is None or not F.ge0(Lin.of(A.length(rope)) - off - count): raise Fail(f"{arg}: the {count} bytes at {region} + {off} are not all bytes this function is known to have written")
                env[arg] = A.slice(rope, off, plain(off + count))
                self.public(env[arg], arg)
        # what the callee requires
        given_apart, ap = set(mine.text["no_overlap"] or ()), c.text["no_overlap"] or []
        for k, x in enumerate(ap):
            for y in ap[k + 1:]:
                (r1, o1, n1), (r2, o2, n2) = spans[x], spans[y]
                if r1 == r2:
                    if not F.ge0(o2 - o1 - n1) and not F.ge0(o1 - o2 - n2): raise Fail(f"{x} and {y} are not shown to have no byte in common")
                elif r1 not in given_apart or r2 not in given_apart: raise Fail(f"{x} and {y}: this function's own contract does not require that {r1} and {r2} do not overlap")
        for e in c.text["asks"]:
            for f in order(spec, A, e, env):
                if not F.ge0(f): raise Fail(f"what {name} requires is not shown here ({f} >= 0)")
        # what it ensures
        tag = f"{name} #{self.steps}"
        after, result, new = dict(env), None, {}
        decided = lambda guard: guard is None or spec.eval(A, guard, after) is True
        if c.result is not None:
            result = sym(f"the result of {tag}"); after[c.result] = plain(result)
        for leaf in c.text["leaves"]:
            if leaf["name"] == c.result or not decided(leaf["cond"]): continue
            arg, (a, b) = leaf["name"], leaf["part"] or (("num", 0), ("num", None))
            v = self.entitled(A, spec.eval(A, leaf["expr"], after), f"{arg} of {tag}", True)
            if not isinstance(v, (Rope, View, list)): raise Fail(f"what {name} ensures of {arg} is not a list of bytes")
            if spec.eval(A, a, after) != 0: raise Fail(f"`ensures {arg}[a .. b]` with a that is not 0: not this verifier's")
            n = spans[arg][2] if b == ("num", None) else numb(spec.eval(A, b, after))
            if F.zero(Lin.of(A.length(v)) - n) is not True: raise Fail(f"what {name} ensures of {arg}: {n} bytes are said to be a list not shown to be of that length")
            F.add(spans[arg][2] - n)                                # they are within what it was given: its own check showed each write to be
            new[arg] = after[arg] = v
        if c.result is None and c.text["returns"] is not None:
            result = numb(self.entitled(A, spec.eval(A, c.text["returns"], after), f"the result of {tag}", False))
        for leaf in c.text["leaves"]:
            if leaf["name"] == c.result and decided(leaf["cond"]):
                d = result - numb(self.entitled(A, spec.eval(A, leaf["expr"], after), f"the result of {tag}, said", False))
                F.add(d); F.add(-d)
        for cond, guard in c.conditions:
            if not decided(guard): continue
            try: facts = order(spec, A, cond, after)
            except Undecided: raise
            except (Err, ode.Fails): continue                       # not an order of two numbers this path can read: nothing is learned of it
            for f in facts: F.add(f)
        # now what the call has changed (nothing above has changed the registers or the bytes held)
        for arg in c.writes:
            region, off, count = spans[arg]
            old = self.held.get(region)
            if F.zero(off) is True: before = Rope()
            elif old is not None and F.ge0(Lin.of(A.length(old)) - off): before = A.slice(old, 0, plain(off))
            else: before = None
            self.held[region] = None if before is None else before if arg not in new else A.rope(A.parts(before) + A.parts(new[arg]))
        if result is not None:
            F.add(result); F.add(WORD64 - result)
            self.g["rax"] = value(result)
        else: self.g["rax"] = ("q", "left by a call")
        return 8 + c.stack


CALLED, CALLEES = set(), {}
def callee(spec, name):
    key = (id(spec), name)
    if key not in CALLEES: CALLEES[key] = (spec, Contract(spec, name))       # (the specification is kept, so that its id is its own)
    return CALLEES[key][1]


def numb(x):
    """A value of the specification that must be a number (a thing with a name only is none)."""
    if isinstance(x, bool) or not isinstance(x, (int, Lin)): raise Err("a number expected")
    return Lin.of(x)


def order(spec, A, e, env):
    """A comparison of two numbers as numbers known not to be below zero."""
    if e[0] != "bin" or e[1] not in (">=", "<=", ">", "<", "=="): raise Err("something that is not an order of two numbers")
    x, y = numb(spec.eval(A, e[2], env)), numb(spec.eval(A, e[3], env))
    return {">=": [x - y], "<=": [y - x], ">": [x - y - 1], "<": [y - x - 1], "==": [x - y, y - x]}[e[1]]


# ---------------------------------------------------------------------------------------------------------
# Places.
class Place:
    def __init__(self, at):
        self.at, self.names, self.facts, self.says, self.any, self.decreases = at, [], [], {}, set(), []
        self.ghosts, self.lists, self.memory = [], [], {}       # (name, witness or None, is it a list); (name, region, length); region: (length, what it holds)
        self.futures = []                                       # (name, region): whatever will be written at region after what is written now


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
        m = re.fullmatch(r"future (\w+) = (\w+)", line)
        if m:
            if m.group(2) not in c.held: raise Fail(f"the proof: {line!r}: the function does not write {m.group(2)}")
            p.futures.append((m.group(1), m.group(2))); continue
        m = re.fullmatch(r"ghost list (\w+)(?: = (.+))?", line)
        if m: p.ghosts.append((m.group(1), expression(m.group(2)) if m.group(2) else None, True)); continue
        m = re.fullmatch(r"ghost (\w+)(?: = (.+))?", line)
        if m: p.ghosts.append((m.group(1), expression(m.group(2)) if m.group(2) else None, False)); continue
        m = re.fullmatch(r"list (\w+) = (\w+)\[0 \.\. (.+)\]", line)
        if m:
            if m.group(2) not in c.held: raise Fail(f"the proof: {line!r}: the contract ensures nothing of {m.group(2)}")
            p.lists.append((m.group(1), m.group(2), expression(m.group(3)))); continue
        m = re.fullmatch(r"(\w+)\[0 \.\. (.+?)\] = (.+)", line)
        if m and m.group(1) in c.held: p.memory[m.group(1)] = (expression(m.group(2)), expression(m.group(3))); continue
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


def outcome(spec, A, x, env):
    """An expression's value, or the failure it is."""
    try: return A.known(spec.eval(A, x, env))
    except ode.Fails as f: return Failure(f.reason)


def carry(e, spec, origin, env0, env=None):
    """At a path's end: the facts of the place it began at that say two things are the same, worked out again
    in that place's names with what the path has since learned. Each gives a named thing something it is.
    A `future` of that place (whatever was to be written after what was written then) is, now, what has been
    written since and then the future of the place the path has come to (nothing, at the return)."""
    e.equal = []
    if origin is None: return
    A = Algebra(e)
    if origin.futures:
        env0 = dict(env0)
        for name, region in origin.futures:
            was, now = env0["\0" + region], e.held.get(region)
            try:
                if now is None: raise Err("nothing is kept of it")
                k, n = A.length(was), A.length(now)
                if not A.same(A.slice(now, 0, k), was): raise Err("it does not begin with what was written then")
                since = A.slice(now, k, n)
            except Err as err: raise Fail(f"what is written at {region}, at the end of a path from the place at +{origin.at - BASE:#x}: {err}")
            after = next((env[n] for n, r in (places_future(env) if env else ()) if r == region), Rope())
            env0[name] = A.rope(list(since.parts) + list(after.parts))
    for f in origin.facts:
        if f[0] != "bin" or f[1] != "==": continue
        try: x, y = outcome(spec, A, f[2], env0), outcome(spec, A, f[3], env0)
        except Err as err:
            if DEBUG: print("   carry: cannot read", err)
            continue
        if DEBUG: print(f"   carry from +{origin.at - BASE:#x} to {'the return' if e.pc is None else f'+{e.pc - BASE:#x}'}: {x!r}  ==  {y!r}")
        if isinstance(x, Opaque) and not A.same(x, y): e.equal.append((x, y))
        elif isinstance(y, Opaque) and not A.same(x, y): e.equal.append((y, x))
        else:
            for u, v in ((x, y), (y, x)):
                # a list of a sequence, with a name only, said to be some list: it is that, and as long
                if isinstance(u, Rope) and len(u.parts) == 1 and u.parts[0][0] == "list" and u.parts[0][1] in e.elements and isinstance(v, (Rope, View, list)) and not A.same(u, v):
                    try: d = Lin.of(u.parts[0][2]) - Lin.of(A.length(v))
                    except Err: break
                    e.lists[u.parts[0][1]] = v; e.facts.add(d); e.facts.add(-d); break


def places_future(env): return env.get("\0futures", ())


def bind(e, p, spec, env0=None):
    """The names of a place, as e holds them; its ghosts, as the place the path began at had them or as the
    place says they are found."""
    env, A = dict(e.given), Algebra(e)
    for name, loc, region in p.names:
        v = get(e, loc)
        if region is None:
            if lin(v) is None: raise Fail(f"{show(loc)} holds {v}: not a number to call {name}")
            env[name] = plain(lin(v))
        else:
            if v[0] != "a" or v[1] != region: raise Fail(f"{show(loc)} holds {v}: not an address in {region}")
            env[name] = plain(Lin.of(v[2]))
        if e.tainted(env[name]): raise Fail(f"{name} depends on bytes the contract does not let the trace depend on")
    for region, rope in e.held.items():
        if rope is not None: env[region] = rope                # what is written there, as a list
        else: env.pop(region, None)
    try:
        for name, region, n in p.lists:
            rope = e.held.get(region)
            if rope is None or e.facts.zero(Lin.of(A.length(rope)) - numb(spec.eval(A, n, env))) is not True: raise Fail(f"at +{p.at - BASE:#x}: the bytes written at {region} are not known to be {name}'s count")
            env[name] = rope
        for name, region in p.futures:                          # any bytes: a list with a name of its own, of any length
            k = next(FRESH); s = sym(f"#{name}!{k}"); e.facts.add(s)
            env[name] = Rope([("list", f"{name}!{k}", s)])
        env["\0futures"] = [(name, region) for name, region in p.futures]
        for name, witness, is_list in p.ghosts:
            if env0 is not None and name in env0: env[name] = env0[name]
            elif witness is not None: env[name] = spec.eval(A, witness, env)
            else: raise Fail(f"at +{p.at - BASE:#x}: nothing says what {name} is here")
    except Err as err: raise Fail(f"at +{p.at - BASE:#x}: what the place says cannot be read: {err}")
    return env


def holds(e, p, env, spec, where):
    """What the place says is so in e."""
    A = Algebra(e)
    try:
        for f in p.facts:
            try: ok = spec.eval(A, f, env) is True
            except ode.Fails: ok = f[0] == "bin" and f[1] == "==" and A.same(outcome(spec, A, f[2], env), outcome(spec, A, f[3], env))
            if not ok: raise Fail(f"{where}: a fact of the place at +{p.at - BASE:#x} does not hold")
        for loc, (region, x) in p.says.items():
            want, v = numb(spec.eval(A, x, env)), get(e, loc)
            if region is None:
                if lin(v) is None or e.facts.zero(lin(v) - want) is not True: raise Fail(f"{where}: {show(loc)} holds {v}, the place says {want}")
            elif v[0] != "a" or v[1] != region or e.facts.zero(Lin.of(v[2]) - want) is not True: raise Fail(f"{where}: {show(loc)} holds {v}, the place says {region} + {want}")
        for region, (n, x) in p.memory.items():
            rope = e.held.get(region)
            if rope is None or e.facts.zero(Lin.of(A.length(rope)) - numb(spec.eval(A, n, env))) is not True or not A.same(rope, spec.eval(A, x, env)):
                raise Fail(f"{where}: the bytes written at {region} are not what the place at +{p.at - BASE:#x} says ({rope})")
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
    m.facts, m.secret, m.bytes, m.seqs, m.named, m.halves = entry.facts.clone(), set(entry.secret), set(entry.bytes), [], {}, []
    m.elements, m.lists = set(), {}
    m.x, m.flags, m.conds, m.back, m.pc, m.since = {}, None, {}, {}, p.at, m.steps
    if not stable(first, first.g["rsp"]): raise Fail("at a place the stack pointer is not the same on every path")
    for r in G64:
        if r not in HELD or not stable(first, first.g[r]): m.g[r] = ("q", f"{r}?{next(FRESH)}")
    for off, (size, kind, v) in list(m.mem["frame"].items()):
        if kind != "q": del m.mem["frame"][off]
        elif not stable(first, v): m.mem["frame"][off] = (size, "q", ("q", f"stack?{next(FRESH)}"))
    env, tag = dict(m.given), f"@{p.at - BASE:#x}"
    m.equal, m.held = [], {region: None for region in m.held}
    for name, loc, region in p.names:
        s = sym(name + tag); m.facts.add(s); m.facts.add(WORD64 - s)
        env[name] = s
        put(m, loc, ("l", s) if region is None else ("a", region, s))
    A = Algebra(m)
    try:
        for name, region, n in p.lists:                     # the bytes written so far: a list with a name, of the count said
            env[name] = m.held[region] = Rope([("list", name + tag, numb(spec.eval(A, n, env)))])
        for name, witness, is_list in p.ghosts:
            s = sym(("#" if is_list else "") + name + tag); m.facts.add(s)
            env[name] = Rope([("list", name + tag, s)]) if is_list else s
        for name, region in p.futures:
            s = sym("#" + name + tag); m.facts.add(s)
            env[name] = Rope([("list", name + tag, s)])
        def take(f):
            if f[0] == "bin" and f[1] == "==":
                # two things said to be the same: if they are numbers here, a fact; else it waits for the path's end (carry)
                try: x, y = outcome(spec, A, f[2], env), outcome(spec, A, f[3], env)
                except Err: return
                if not all(isinstance(v, (int, Lin)) and not isinstance(v, bool) for v in (x, y)): return
            for x in order(spec, A, f, env): m.facts.add(x)
        later = []
        for f in p.facts:                                   # the facts in order; one that speaks of what is in memory waits for it
            try: take(f)
            except Err: later.append(f)
        for region, (n, x) in p.memory.items():
            rope = A.rope(A.parts(spec.eval(A, x, env)))
            d = Lin.of(A.length(rope)) - numb(spec.eval(A, n, env))
            m.facts.add(d); m.facts.add(-d); m.held[region] = rope
        for region, rope in m.held.items():
            if rope is not None: env[region] = env["\0" + region] = rope
            else: env.pop(region, None)
        for f in later: take(f)
        for name, region in p.futures:
            if m.held.get(region) is None: raise Fail(f"the place at +{p.at - BASE:#x} speaks of what will be written at {region}, and does not say what is written there")
        for loc, (region, x) in p.says.items():
            v = spec.eval(A, x, env)
            put(m, loc, value(Lin.of(v)) if region is None else ("a", region, plain(Lin.of(v))))
        for x in p.decreases:
            if not m.facts.ge0(numb(spec.eval(A, x, env))): raise Fail(f"a number the place at +{p.at - BASE:#x} says decreases is not shown to stay at or above zero")
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
            x, y = numb(spec.eval(A, x, env0)), numb(spec.eval(A, y, env))
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
            if m.steps - m.since > PATH: raise Fail(f"a path of more than {PATH} instructions that comes to no place and does not return: a loop that needs a place")
            try:
                m.one(); budget[0] -= 1
            except kfn.Fork as f:
                if f.kind in ("zero", "ge", "defined"): work += split(m, f); break
                yes, no = m.clone(), m.clone()
                yes.conds[f.x] = True; no.conds[f.x] = False
                work += [side for side in (yes, no) if side.facts.consistent()]; break
    return ends


def where_holds(e, spec, guard, env):
    """`ensures ... if GUARD`: the cases of this path's end in which the guard holds. Where the path does not say how
    two numbers of the guard compare, it is taken both ways: so what is ensured is shown wherever the guard holds,
    and nothing is asked where it does not. (A guard that cannot be read at all is an Err, as before.)"""
    if guard is None: return [e]
    holds, work = [], [e]
    while work:
        m = work.pop()
        try:
            if spec.eval(Algebra(m), guard, env) is True: holds.append(m)
        except Undecided as u:
            work += split(m, u)
            if len(work) + len(holds) > 64: raise Fail("a guard of the contract with more cases than this verifier takes")
    return holds


def returned(e, c, where):
    """What the contract says of the return, on this path. Where the contract asks what the path does not answer
    (has `lz4(input)` a value?), each way it can be is a case of its own, and the contract is shown in each."""
    work, cases = [e], 0
    while work:
        m = work.pop()
        cases += 1
        if cases > 200: raise Fail(f"{where}: the contract asks more questions the path does not answer than this verifier takes")
        try: returned_case(m, c, where)
        except Undecided as u: work += split(m, u)


def returned_case(e, c, where):
    A, env, spec = Algebra(e), dict(e.given), c.spec
    for region, rope in e.held.items():
        if rope is not None: env[region] = rope                # what is written there, as a list
        else: env.pop(region, None)
    try:
        if c.result is not None:
            if lin(e.g["rax"]) is None: raise Fail(f"{where}: the result is {e.g['rax']}: not a number")
            env[c.result] = plain(lin(e.g["rax"]))
        elif c.text["returns"] is not None:
            want = numb(spec.eval(A, c.text["returns"], env))
            if lin(e.g["rax"]) is None or e.facts.zero(lin(e.g["rax"]) - want) is not True: raise Fail(f"{where}: the result is {e.g['rax']}, the contract says {want}")
        for leaf in c.text["leaves"]:
            for m in where_holds(e, spec, leaf["cond"], env):
                A = Algebra(m)
                want = spec.eval(A, leaf["expr"], env)
                if leaf["name"] == c.result:
                    if not A.same(env[c.result], want): raise Fail(f"{where}: the result is {env[c.result]}, the contract says {want}")
                    continue
                rope, (a, b) = e.held.get(leaf["name"]), leaf["part"] or (("num", 0), ("num", None))
                n = e.len[leaf["name"]] if b == ("num", None) else numb(spec.eval(A, b, env))
                if spec.eval(A, a, env) != 0: raise Fail(f"{where}: `ensures {leaf['name']}[a .. b]` with a that is not 0: not this verifier's")
                if rope is None or m.facts.zero(Lin.of(A.length(rope)) - n) is not True or not A.same(rope, want):
                    raise Fail(f"{where}: the bytes at {leaf['name']} are not what the contract says: they are {rope}, it says {want}")
        for cond, guard in c.conditions:
            for m in where_holds(e, spec, guard, env):
                if spec.eval(Algebra(m), cond, env) is not True: raise Fail(f"{where}: something the contract ensures is not so")
    except Undecided: raise
    except ode.Fails as err: raise Fail(f"{where}: the contract speaks of something the specification gives no value (it fails with {err.reason})")
    except Err as err: raise Fail(f"{where}: the specification cannot be followed on this path: {err}")
    for r in KEPT:
        if e.g[r] != ("q", r + " at entry"): raise Fail(f"{where}: {r} is not restored")
    within(e, c, where)


# ---------------------------------------------------------------------------------------------------------
# Lemmas: contracts of the specification's own definitions (ode.py: `lemma`). Steps of a proof.
#
# A lemma says: where what the definition is given meets `requires`, and the definition has a value, `ensures`
# holds of that value. It is shown by opening the definition once on names, every use of a definition that
# has a lemma inside taken by that lemma: as a function that calls itself is taken by its own contract. (If the
# definition has a value, it was reached by finitely many openings; so what holds after one opening, given that
# it holds of the openings inside, holds.) A sequence's lemma is of its place k: shown of its first value, and
# of the value after one of which it holds.
#
# Used: (1) wherever a place of a sequence with a lemma is asked for; (2) where the contract asks whether
# something has a value and the path does not say: in the case that it has, the definition it is known to be is
# opened once, the uses inside by their lemmas, and each way that opening can go is a case of its own.

def fresh_value(m, kind, fields, title):
    """A value of which nothing is known but its kind: a list, a number, a record of numbers, with a name."""
    if kind == "any": return Any(title)
    if kind == "list":
        n = sym("#" + title); m.facts.add(n)
        return Rope([("list", title, n)])
    if kind == "number":
        v = sym(title); m.facts.add(v)
        return plain(v)
    out = {}
    for f in fields:
        v = sym(f"{title}.{f}"); m.facts.add(v); out[f] = plain(v)
    return out


def applies(spec, A, l, args):
    """The lemma's names for what it is given, if these are of its kinds and meet its `requires` here; else None."""
    if len(args) != len(l["params"]): return None
    env = {}
    try:
        for (p, kind), a in zip(l["params"], args):
            if kind == "bytes" and not isinstance(a, View): return None
            if kind == "list":
                # a list of bytes (a lemma is shown of such): bytes of memory, lists with a name, and numbers shown to be bytes
                if not isinstance(a, (Rope, View, list)): return None
                for q in A.parts(a):
                    if q[0] == "one" and not (A.facts.ge0(Lin.of(q[1])) and A.facts.ge0(255 - Lin.of(q[1]))): return None
            if kind == "number" and not A.facts.ge0(numb(a)): return None
            env[p] = a                                                   # (kind `any`: whatever it is)
        for e in l["requires"]:
            for f in order(spec, A, e, env):
                if not A.facts.ge0(f): return None
    except Err: return None
    return env


class Opening(Algebra):
    """The algebra while one definition (`top`) is opened once: a definition with a lemma that is used inside is
    not opened: its value is a name of which the lemma's `ensures` holds."""
    def __init__(self, m, spec, top, tag):
        # `tag`: this opening's own; the names it gives are numbered from 0 each time it is gone through, so that
        # going through it again, after a question was taken both ways, speaks of the same things
        super().__init__(m); self.spec, self.top, self.opened, self.tag, self.count = spec, top, False, tag, itertools.count()
        self.only = None        # while a sequence's lemma is shown: the one place of which it may be taken (the place before)
        self.measure = None     # while a lemma with `decreases` is shown: (the definitions that use it back, its number as given)
    # words, in an opening: things passed on, of which nothing is known (so nothing can be shown of them)
    def word(self, *args): return Any("a word")
    counter = add = xor = or_ = rotr = words = word
    def bits_of(self, op, x, y): return Any("bits of two things")
    def concat(self, x, y):
        if isinstance(x, Any) or isinstance(y, Any): return Any("two things, one after the other")
        return super().concat(x, y)
    def hypothesis(self, name, args, index=None):
        l = self.spec.lemmas[name]
        env = applies(self.spec, self, l, args)
        if env is None or (index is not None and not self.facts.ge0(Lin.of(self.num(index)))): raise Err(f"the lemma of {name} does not apply here")
        if self.measure is not None and name in self.measure[0]:
            # a use of the definition by itself (or of one that uses it back): the number that decreases is not
            # below zero here, and is less for what is used
            if l["decreases"] is None: raise Err(f"{name} uses {self.top} back, and its lemma names no number that decreases")
            mine, its = self.measure[1], numb(self.spec.eval(Whole(self.m), l["decreases"], env))
            if not self.facts.ge0(mine) or not self.facts.ge0(mine - 1 - its): raise Err(f"at its use of {name} the number that decreases ({its}, from {mine}) is not shown to be less, or the one before not to be below zero")
        v = fresh_value(self.m, l["kind"], l["fields"], f"{name}!{self.tag}.{next(self.count)}")
        env["result"] = v
        if index is not None: env[l["index"]] = index
        for e in l["ensures"]:
            for f in order(self.spec, self, e, env): self.facts.add(f)
        return v
    def kept(self, name, args, body):
        if name == self.top and not self.opened: self.opened = True; return body()
        v = self.known(Opaque(name, args))
        if isinstance(v, Failure): raise ode.Fails(v.reason)
        if not isinstance(v, Opaque): return v
        if name in self.spec.lemmas: return self.hypothesis(name, args)
        return body()                                            # a definition without a lemma: opened where it stands
    def defined(self, v):
        v = self.known(v)
        if isinstance(v, Opaque) and not any(self.alike(v, k) for k in self.m.fine): raise Err("a definition that asks whether something has a value: not followed in an opening")
    def element(self, spec, seq, i):
        if seq.id is not None and seq.id[0] in spec.lemmas:
            if self.only is not None and self.facts.zero(Lin.of(self.num(i)) - self.only) is not True: raise Err(f"a sequence's lemma is shown from the place before, and place {i} is asked for")
            return self.hypothesis(seq.id[0], seq.id[1], i)
        return super().element(spec, seq, i)


class Whole(Algebra):
    """For the number a lemma says decreases: it is worked out as a whole number that may be below zero (where it
    must not be is asked at each use, not here)."""
    def minus(self, x, y): return plain(Lin.of(self.num(x)) - Lin.of(self.num(y)))


def lemma_machine(spec, name, l):
    """A machine with no code, for the facts and the names: and what the lemma is given, of which nothing is known
    but its kinds and its `requires`."""
    c = Contract.__new__(Contract)
    c.name, c.spec, c.args, c.kind, c.result = "lemma " + name, spec, [], {}, None
    c.writes, c.held, c.trace, c.stack, c.conditions = set(), set(), {p for p, k in l["params"] if k == "bytes"}, 0, []
    c.text = dict(asks=[], no_overlap=None, leaves=[], returns=None, spoils=[])
    m = Machine(kterms.Terms(), [], c)
    args = []
    for p, kind in l["params"]:
        if kind == "bytes":
            n = sym("#" + p); m.facts.add(n); m.facts.add(WORD64 - n)          # bytes in memory: fewer than 2^64 of them
            m.len[p], m.given[p] = Lin.of(n), View(p, 0, plain(n)); m.readonly.add(p)
            args.append(m.given[p])
        else: args.append(fresh_value(m, kind, (), p))
    env = dict(zip((p for p, _ in l["params"]), args))
    A = Algebra(m)
    for e in l["requires"]:
        for f in order(spec, A, e, env): m.facts.add(f)
    return m, args, env


def lemma_cases(m0, one, what):
    work, n = [m0], 0
    while work:
        m = work.pop(); n += 1
        if n > 500: raise Fail(f"{what}: more cases than this verifier takes")
        try: one(m)
        except Undecided as u:
            if u.kind == "defined": raise Fail(f"{what}: its opening asks whether something has a value")
            work += split(m, u)
        except ode.Fails: pass                                   # no value in this case: the lemma says nothing of it
        except Err as err: raise Fail(str(err) if str(err).startswith(what) else f"{what}: its opening cannot be followed: {err}")
        except (AttributeError, TypeError, KeyError, IndexError) as err:
            # a thing of kind `any` where the specification's own functions want a word, a record, a list: not followed
            raise Fail(f"{what}: its opening cannot be followed: a thing of which nothing is known is used ({type(err).__name__})")


def prove_lemmas(spec):
    """Every lemma of the specification is shown, or Fail. (Each use of a lemma rests on this.)"""
    for name, l in spec.lemmas.items():
        what = f"the lemma of {name}"
        m0, args, env0 = lemma_machine(spec, name, l)
        def holds(m, A, v, index=None, of=""):
            # the kind the lemma says the value is of is something said too: a use is given a thing of that kind
            v = A.known(v)
            numbers = lambda x: isinstance(x, (int, Lin)) and not isinstance(x, bool)
            if not {"any": True, "number": numbers(v), "list": isinstance(v, (Rope, View, list)),
                    "record": isinstance(v, dict) and sorted(v) == sorted(l["fields"]) and all(numbers(x) for x in v.values())}[l["kind"]]:
                raise Fail(f"{what}: it says the definition's value is a {l['kind']}{of}, and what the definition gives here is not shown to be one")
            env = dict(env0); env["result"] = v
            if index is not None: env[l["index"]] = index
            for e in l["ensures"]:
                for f in order(spec, A, e, env):
                    if not m.facts.ge0(f): raise Fail(f"{what}: what it ensures is not shown{of} ({f} >= 0)")
        tag = next(FRESH)
        if l["index"] is None and l["kind"] == "any" and not l["ensures"] and l["decreases"] is None:
            continue                                 # it says nothing of the definition: there is nothing to show
        if l["index"] is None:
            measure = None
            if l["decreases"] is not None:
                measure = (ring(spec, name), numb(spec.eval(Whole(m0), l["decreases"], dict(env0))))
                if name not in measure[0]: raise Fail(f"{what}: it names a number that decreases, and the definition does not use itself")
            def one(m):
                A = Opening(m, spec, name, tag)
                A.measure = measure
                holds(m, A, spec.apply(A, name, list(args)))
            lemma_cases(m0, one, what)
        else:
            params, h, var, first, nxt = spec.seqs[name]
            k = sym(l["index"] + "?"); m0.facts.add(k)
            def one(m):
                A = Opening(m, spec, None, tag)
                A.only = k
                s = ode.Seq(); s.first, s.var, s.next, s.id = first, var, nxt, (name, list(args))
                s.env = dict(zip(params, args)); s.env[h] = s
                holds(m, A, spec.eval(A, first, dict(s.env)), 0, " of its first value")
                inner = dict(s.env); inner[var] = plain(k)
                holds(m, A, spec.eval(A, nxt, inner), plain(k + 1), " of the value after one of which it holds")
            lemma_cases(m0, one, what)


def uses(spec, name):
    """The definitions a definition's own text applies."""
    out = set()
    def walk(x):
        if isinstance(x, tuple) and len(x) == 3 and x[0] == "call" and (x[1] in spec.fns or x[1] in spec.seqs): out.add(x[1])
        if isinstance(x, (tuple, list)):
            for y in x: walk(y)
    if name in spec.fns: walk(spec.fns[name][1])
    else: walk(spec.seqs[name][3]); walk(spec.seqs[name][4])      # a sequence: its first value and the next from one
    return out


def ring(spec, name):
    """The definitions that `name` uses (through any number of others) and that use it back: itself among them
    if it uses itself."""
    def reach(a):
        seen, todo = set(), [a]
        while todo:
            for b in uses(spec, todo.pop()):
                if b not in seen: seen.add(b); todo.append(b)
        return seen
    return {b for b in reach(name) if name in reach(b)}


def ends(spec):
    """(the definitions that use themselves, straight or through others; those of them not shown to come to an end).
    Shown: by a lemma that names a number that decreases (prove_lemmas shows it): the definition then comes to an
    end, with a value or failing, wherever what it is given meets that lemma's `requires`."""
    again = sorted(name for name in list(spec.fns) + list(spec.seqs) if ring(spec, name))
    return again, [name for name in again if name not in spec.lemmas or spec.lemmas[name]["decreases"] is None]


def ends_line(spec):
    again, open_ = ends(spec)
    if not again: return "no definition of the specification uses itself: each comes to an end"
    if not open_: return f"the definitions that use themselves ({', '.join(again)}): each is shown to come to an end (a number that decreases, in a lemma)"
    return f"the definitions that use themselves ({', '.join(again)}): NOT shown to come to an end: {', '.join(open_)} (a contract says nothing of an input on which one does not)"


def split(m, u):
    """The ways a question the path does not answer can be, each a machine of its own (those that cannot be are left out)."""
    if u.kind == "defined": return split_defined(m, u.x)
    yes, no = m.clone(), m.clone()
    if u.kind == "zero": yes.facts.assume_zero(u.x); no.facts.assume_nonzero(u.x)
    else: yes.facts.add(u.x); no.facts.add(-u.x - 1)
    return [s for s in (yes, no) if s.facts.consistent()]


def split_defined(m, V):
    """V (a definition of some things, not worked out) has a value, or fails. Where it has one, the definition
    (or one it is known to be the same as: the rest of the specification from where the code is) is opened once,
    each definition with a lemma that is used inside taken by its lemma: each way the opening goes is a case, in
    which V is what the opening gives."""
    spec, A = m.contract.spec, Algebra(m)
    no = m.clone(); no.learned.append((V, Failure(Opaque("reason", (V,)))))
    opens = lambda x: isinstance(x, Opaque) and x.name in spec.fns
    target = next((k for k, v in m.learned + m.equal if opens(k) and isinstance(v, Opaque) and A.alike(v, V)), V if opens(V) else None)
    yes = []
    if target is None:
        y = m.clone(); y.fine.append(V); yes.append(y)
    else:
        work, tag = [m.clone()], next(FRESH)
        while work:
            sm = work.pop()
            if len(yes) + len(work) > 64:
                y = m.clone(); y.fine.append(V); yes = [y]; break       # too many ways: only that it has a value
            O = Opening(sm, spec, target.name, tag)
            try: val = spec.apply(O, target.name, list(target.args))
            except Undecided as u:
                work += [s for s in split(sm, u)] if u.kind != "defined" else []
                if u.kind == "defined": sm.fine.append(V); yes.append(sm)
                continue
            except ode.Fails: continue                               # it has a value: not this way
            except Err:
                sm.fine.append(V); yes.append(sm); continue          # the opening cannot be followed: only that it has a value
            sm.learned.append((V, val)); sm.fine.append(V); yes.append(sm)
    return [s for s in yes + [no] if s.facts.consistent()]


def within(e, c, where):
    if -e.low > c.stack: raise Fail(f"{where}: {-e.low} bytes of stack used, the contract gives {c.stack}")


def check(rows, spec, symbol, proof=""):
    """The function's instructions meet its contract. Raises Fail; returns a tally."""
    global FRESH
    FRESH = itertools.count()               # the names given on the way are the same every time: a proof of the arithmetic speaks of them
    c, T = Contract(spec, symbol), kterms.Terms()
    prove_lemmas(spec)                      # before any is used
    places = read_proof(proof, c)
    CALLED.clear()
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
                carry(e, spec, places.get(origin), env0)
                tally["return"] += 1; returned(e, c, where); continue
            tally["place"] += 1
            p = places[e.pc]
            env = bind(e, p, spec, env0)
            carry(e, spec, places.get(origin), env0, env)
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
    tally["instructions"], tally["calls"] = STEPS - budget[0], sorted(CALLED)
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
