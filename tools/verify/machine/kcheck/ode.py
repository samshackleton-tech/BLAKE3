#!/usr/bin/env python3
"""ode: the reader of the specification's language, on numbers and on symbols.

    python3 ode.py blake3.spec --vectors ../../../../test_vectors/test_vectors.json [--up-to BYTES]

The language is described at the top of blake3.spec. This file is its reader: a parser (to a tree), and one
evaluator of the tree over an "algebra" of words: Numbers (words are 32-bit numbers) or Symbols (words are
the verifiers' terms; a comparison of numbers that depend on a count is decided from the path's facts, or the
evaluation stops). The same text is thus what gives BLAKE3's test vectors and what code is compared with.

    const NAME = EXPR
    def NAME(args) { let X = E ... VALUE }        a definition: equations and a value
    sequence NAME(args) { h[0] = A   h[b + 1] = F(h[b])   for b in 0..n }
    layout NAME BYTES { FIELD: KIND at OFFSET [below N], FIELD[COUNT]: KIND at OFFSET, ... }
    kind NAME: KIND                               what sort of thing a definition gives
    contract NAME(ARG: KIND, ...) { requires E | requires X[i] == E for i in A..B | ensures NAME = E | writes NAME
                                    | returns E | stack E | needs F [if E] | decreases E | calls F if E }
    machine NAME(args) on STATE, ... [= INIT, ...] { while COND | for I in A..B   turn { STATE = E ... } }
                                                  (an algorithm, not a specification: proofs/inner.spec has one)

A sequence or machine called as a function runs to its end; with more than one state its result is a record
of them. The verifiers ask it for one `turn` and whether it `goes` on. On symbols a definition with a kind
that cannot be evaluated (the tree over bytes whose count the path does not fix) gives a value of that
kind named by what it was given; a machine that cannot be run likewise."""
import json, os, re, sys, time

M32 = 0xFFFFFFFF
DEEP = 400                      # definitions inside definitions: more is a definition of itself that does not end
sys.setrecursionlimit(max(sys.getrecursionlimit(), 30000))


class Err(Exception):
    pass


# ---------------------------------------------------------------------------------------------------------
# Text to tree.
TOKEN = re.compile(r"\s*(?:(//[^\n]*)|(0x[0-9A-Fa-f]+|\d+)|([A-Za-z_][A-Za-z_0-9]*)|(>>>|\+\+|\.\.|==|!=|<=|>=|&&|\|\||[-+*/%^|&<>=!(){}\[\],:.]))")
KEYWORDS = {"const", "def", "sequence", "the", "machine", "contract", "layout", "kind", "on", "while", "for", "in", "turn", "if", "then", "else", "let", "fails", "lemma"}
LEVELS = [["||"], ["&&"], ["==", "!=", "<", "<=", ">", ">="], ["++"], ["|"], ["^"], ["&"], ["+", "-"], ["*", "/", "%"], [">>>"]]


def lex(text):
    out, at = [], 0
    while at < len(text):
        m = TOKEN.match(text, at)
        if not m:
            if text[at:].strip() == "": break
            raise Err(f"line {text.count(chr(10), 0, at) + 1}: not a word of the language: {text[at:at + 20]!r}")
        at = m.end()
        if m.group(1): continue
        line = text.count("\n", 0, m.start(m.lastindex)) + 1
        if m.group(2): out.append(("num", int(m.group(2), 0), line))
        elif m.group(3): out.append(("key" if m.group(3) in KEYWORDS else "name", m.group(3), line))
        else: out.append(("sym", m.group(4), line))
    out.append(("end", None, 0))
    return out


# The names the language itself gives a meaning (LANGUAGE.md): no specification defines one of them.
OWN = {"word", "counter", "words", "nothing", "bits", "lo", "hi", "len", "ones", "pow", "word_bytes", "bytes_of", "failed", "reason"}


def with_proof(text, inner):
    """The reader's specification with a proof's part read after it (the contracts of the functions inside, and
    the layouts and algorithms those contracts speak of). The proof's part is not the reader's, so it must not
    be able to change what the reader's text means: no name it declares may be written anywhere in the reader's
    text. (Then no name the reader reads has its meaning from the proof; a name his text uses and does not
    define stays undefined. A name declared twice, or one of the language's own, is refused by the parser.
    `kind NAME: ...` lines are let through: they say how a definition of the reader's is to be followed on
    symbols, not what it is. So are `lemma NAME(...)` declarations: a lemma is about a definition of the
    reader's and gives it no meaning; a verifier shows each lemma before it uses it.)"""
    mine = {value for kind, value, _ in lex(text) if kind == "name"}
    p = Parser(inner); p.file()
    for what, name in sorted(p.declared):
        if what not in ("kind", "lemma") and name in mine: raise Err(f"the proof's part declares {name}, a name the reader's specification uses: it is refused")
    return Spec(text + "\n" + inner)


class Parser:
    def __init__(self, text): self.t, self.i = lex(text), 0
    def peek(self, value=None, kind=None):
        k, v, _ = self.t[self.i]
        return (value is None or (v == value and k in ("sym", "key"))) and (kind is None or k == kind)
    def take(self, value=None, kind=None):
        k, v, line = self.t[self.i]
        if not self.peek(value, kind): raise Err(f"line {line}: {value or kind} expected, not {v!r}")
        self.i += 1
        return v
    def maybe(self, value):
        if self.peek(value): self.i += 1; return True
        return False

    def file(self):
        consts, fns, machines, self.contracts, self.layouts, self.kinds, self.seqs = {}, {}, {}, {}, {}, {}, {}
        self.lemmas = {}
        said = self.declared = set()
        def once(what, name):
            if what == "value" and name in OWN: raise Err(f"line {self.t[self.i - 1][2]}: {name} is the language's own: a specification does not define it")
            # A name is given its meaning once. (A second `def` or `contract` of a name would take the first
            # one's place without a word: and a text may be two texts put end to end, one of them not the reader's.)
            if (what, name) in said: raise Err(f"line {self.t[self.i - 1][2]}: {name} is defined twice")
            said.add((what, name))
            return name
        while not self.peek(kind="end"):
            if self.maybe("const"):
                name = once("value", self.take(kind="name")); self.take("="); consts[name] = self.expr()
            elif self.maybe("def"):
                # a definition: equations (`let`) and a value; nothing is assigned twice, nothing loops
                name = once("value", self.take(kind="name")); params = self.params()
                if self.maybe(":"): self.kinds[once("kind", name)] = self.kind()
                fns[name] = (params, self.definition())
            elif self.maybe("sequence"):
                # NAME(args) { h[0] = FIRST   h[b + 1] = NEXT   for b in 0..n }: a sequence by its first value and
                # each next one from the one before; NAME(args) is its last, h[n]
                name = once("value", self.take(kind="name")); params = self.params(); self.take("{")
                h = self.take(kind="name"); self.take("["); zero = self.take(kind="num"); self.take("]"); self.take("=")
                if zero != 0: raise Err(f"sequence {name}: its first equation is of {h}[0]")
                first = self.expr()
                if self.take(kind="name") != h: raise Err(f"sequence {name}: its second equation is of {h}[b + 1]")
                self.take("["); b = self.take(kind="name"); self.take("+")
                if self.take(kind="num") != 1: raise Err(f"sequence {name}: its second equation is of {h}[{b} + 1]")
                self.take("]"); self.take("="); nxt = self.expr()
                if self.maybe("}"):
                    # with no `for`: the whole sequence; NAME(args)[k] is its value at place k
                    self.seqs[name] = (params, h, b, first, nxt); continue
                self.take("for")
                if self.take(kind="name") != b: raise Err(f"sequence {name}: `for {b} in 0..n` expected")
                self.take("in"); a = self.expr(); self.take(".."); n = self.expr(); self.take("}")
                if a != ("num", 0): raise Err(f"sequence {name}: it begins at 0")
                machines[name] = dict(params=params, states=[h], state=h, init=first, inits=[first], loop=("for", b, a, n),
                                      turn=[("set", h, self.before(nxt, h, b, name))])
            elif self.maybe("layout"):
                name = once("layout", self.take(kind="name")); self.layouts[name] = self.layout()
            elif self.maybe("kind"):
                name = once("kind", self.take(kind="name")); self.take(":"); self.kinds[name] = self.kind()
            elif self.maybe("machine"):
                name = once("value", self.take(kind="name")); params = self.params(); self.take("on"); state = [self.take(kind="name")]
                while self.maybe(","): state.append(self.take(kind="name"))
                init = None
                if self.maybe("="):
                    init = [self.expr()]
                    while self.maybe(","): init.append(self.expr())
                    if len(init) != len(state): raise Err(f"machine {name}: {len(state)} states and {len(init)} first values")
                self.take("{")
                if self.maybe("while"): loop = ("while", self.expr())
                else:
                    self.take("for"); var = self.take(kind="name"); self.take("in"); a = self.expr(); self.take(".."); loop = ("for", var, a, self.expr())
                self.take("turn"); turn = self.turn(); self.take("}")
                machines[name] = dict(params=params, states=state, state=state[0] if len(state) == 1 else None,
                                      init=init[0] if init is not None and len(state) == 1 else None, inits=init, loop=loop, turn=turn)
            elif self.maybe("contract"):
                name = once("contract", self.take(kind="name")); self.contracts[name] = self.contract()
            elif self.maybe("lemma"):
                # lemma NAME(param: bytes | list | number, ...) [ "[" k "]" ] : list | number | record(field, ...) { requires E | ensures E | decreases E }
                # A contract of a definition (or of a sequence's place k): where what it is given meets `requires`
                # and the definition has a value, `ensures` holds of that value, written `result`. A step of a
                # proof: a verifier shows it before it uses it (kbyte.py), so it changes no meaning.
                # `decreases E`: a number that is not below zero where the definition uses itself (or another that
                # uses it back), and less at each such use: so the definition comes to an end, with a value or failing.
                name = once("lemma", self.take(kind="name")); self.take("("); params = []
                while not self.maybe(")"):
                    p = self.take(kind="name"); self.take(":"); params.append((p, self.take(kind="name"))); self.maybe(",")
                index = None
                if self.maybe("["): index = self.take(kind="name"); self.take("]")
                self.take(":"); kind, fields = self.take(kind="name"), []
                if kind == "record":
                    self.take("(")
                    while not self.maybe(")"): fields.append(self.take(kind="name")); self.maybe(",")
                if kind not in ("list", "number", "record") or any(k not in ("bytes", "list", "number") for _, k in params): raise Err(f"line {self.t[self.i - 1][2]}: a lemma's kinds are bytes, list, number, record(...)")
                self.take("{"); requires, ensures, decreases = [], [], None
                while not self.maybe("}"):
                    clause = self.take(kind="name")
                    if clause == "requires": requires.append(self.expr())
                    elif clause == "ensures": ensures.append(self.expr())
                    elif clause == "decreases" and decreases is None and index is None: decreases = self.expr()
                    else: raise Err(f"line {self.t[self.i - 1][2]}: a lemma says `requires`, `ensures` and, once and of a definition, `decreases`")
                self.lemmas[name] = dict(params=params, index=index, kind=kind, fields=fields, requires=requires, ensures=ensures, decreases=decreases)
            else: raise Err(f"line {self.t[self.i][2]}: const, def, sequence, contract, layout, kind or machine expected")
        return consts, fns, machines

    def before(self, e, h, b, name):
        """The equation's right side with `h[b]`, the value before, as the one name `h`; `h` any other way is refused."""
        if e == ("index", ("name", h), ("name", b)): return ("name", h)
        if e == ("name", h): raise Err(f"sequence {name}: {h} is used other than as {h}[{b}]")
        if isinstance(e, tuple): return tuple(self.before(x, h, b, name) for x in e)
        if isinstance(e, list): return [self.before(x, h, b, name) for x in e]
        return e

    def definition(self):
        """{ let NAME = E | let NAME[0] = E | let NAME[i + 1] = E | fails REASON if C ... VALUE }"""
        self.take("{"); out = []
        while self.peek("let") or self.peek("fails"):
            if self.maybe("fails"):
                reason = self.expr(); self.take("if"); out.append(("fails", reason, self.expr())); continue
            self.take("let")
            name = self.take(kind="name")
            if self.maybe("["):
                if self.peek(kind="num"):
                    if self.take(kind="num") != 0: raise Err(f"line {self.t[self.i][2]}: a sequence's first equation is of {name}[0]")
                    self.take("]"); self.take("="); out.append(("first", name, self.expr()))
                else:
                    i = self.take(kind="name"); self.take("+")
                    if self.take(kind="num") != 1: raise Err(f"line {self.t[self.i][2]}: a sequence's equation is of {name}[{i} + 1]")
                    self.take("]"); self.take("="); out.append(("next", name, i, self.expr()))
            else:
                self.take("="); out.append(("set", name, self.expr()))
        out.append(("expr", self.expr()))
        if any(s[0] == "set" and sum(1 for r in out if r[0] == "set" and r[1] == s[1]) > 1 for s in out): raise Err("a definition gives a name twice")
        self.take("}")
        return out

    def kind(self):
        kind = []
        while self.peek(kind="name") or self.peek(kind="num"): kind.append(str(self.take()))
        if not kind: raise Err(f"line {self.t[self.i][2]}: a kind expected")
        return " ".join(kind)

    def layout(self):
        """BYTES { FIELD: KIND at OFFSET [below N], FIELD[COUNT]: KIND at OFFSET, ... }: where a record's parts lie."""
        size = self.take(kind="num"); self.take("{"); fields = {}
        while not self.maybe("}"):
            name, count = self.take(kind="name"), None
            if self.maybe("["):
                count = self.take(kind="num"); self.take("]")
            self.take(":"); kind = []
            while not (self.t[self.i][0] == "name" and self.t[self.i][1] == "at"): kind.append(str(self.take()))
            self.take(); at = self.take(kind="num"); below = None
            if self.t[self.i][0] == "name" and self.t[self.i][1] == "below":
                self.take(); below = self.take(kind="num")
            fields[name] = dict(kind=" ".join(kind), at=at, count=count, below=below); self.maybe(",")
        return dict(size=size, fields=fields)

    def contract(self):
        """(arg: kind, ...) { asks E | leaves NAME = E | writes NAME | returns E | stack N | calls F if E }"""
        self.take("("); args = []
        while not self.maybe(")"):
            arg = self.take(kind="name"); self.take(":"); args.append((arg, self.kind())); self.maybe(",")
        c = dict(args=args, asks=[], given=[], leaves=[], spoils=[], returns=None, stack=None, calls=[], needs=[], decreases=None, apart=None, trace=[], conditions=[])
        self.take("{")
        def once(what, key):
            # said twice, the second would silently be the one meant
            if c[key] is not None: raise Err(f"line {self.t[self.i - 1][2]}: a contract says `{what}` once")
        while not self.maybe("}"):
            clause = self.take(kind="name")
            if clause == "requires" and self.t[self.i][:2] == ("name", "apart") and self.t[self.i + 1][1] == "(":
                # requires apart(a, b, ...): the things at those addresses do not overlap one another
                once("requires apart(...)", "apart")
                self.take(); self.take("("); c["apart"] = []
                while not self.maybe(")"): c["apart"].append(self.take(kind="name")); self.maybe(",")
            elif clause == "requires":
                e = self.expr()
                if self.maybe("for"):
                    # asks NAME[i] == E for i in A..B: what each of some values at an address is
                    if not (e[0] == "bin" and e[1] == "==" and e[2][0] == "index" and e[2][1][0] == "name" and e[2][2][0] == "name"): raise Err("`requires NAME[i] == E for i in A..B` expected")
                    if self.take(kind="name") != e[2][2][1]: raise Err(f"`for {e[2][2][1]}` expected")
                    self.take("in"); a = self.expr(); self.take("..")
                    c["given"].append(dict(name=e[2][1][1], index=e[2][2][1], expr=e[3], each=(a, self.expr())))
                else: c["asks"].append(e)
            elif clause == "ensures":
                # ensures NAME = E; ensures NAME[I] = E for I in A..B (each place of what NAME addresses);
                # ensures NAME[A .. B] = E (those bytes of it). Any of them `if C`: only where C holds.
                # Or: ensures CONDITION (something that is true or false of the result and of what is in memory).
                save = self.i
                name, index, each, part = self.take(kind="name") if self.peek(kind="name") else None, None, None, None
                if name is not None and self.maybe("["):
                    if self.peek(kind="name") and self.t[self.i + 1][1] == "]": index = self.take(kind="name")
                    else: a = self.expr(); self.take(".."); part = (a, self.expr())
                    self.take("]")
                if name is None or not self.peek("="):
                    self.i = save
                    cond = self.expr()
                    c["conditions"].append((cond, self.expr() if self.maybe("if") else None)); continue
                self.take("="); e = self.expr()
                if index is not None:
                    self.take("for")
                    if self.take(kind="name") != index: raise Err(f"line {self.t[self.i - 1][2]}: `for {index}` expected")
                    self.take("in"); a = self.expr(); self.take(".."); each = (a, self.expr())
                cond = self.expr() if self.maybe("if") else None
                c["leaves"].append(dict(name=name, index=index, expr=e, each=each, part=part, cond=cond))
            elif clause == "returns": once("returns", "returns"); c["returns"] = self.expr()
            elif clause == "writes": c["spoils"].append(self.take(kind="name"))         # written, and nothing said of what
            elif clause == "trace":
                # trace depends on NAME, ...: which instructions run and which addresses are touched may depend on those bytes
                if self.take(kind="name") != "depends": raise Err("`trace depends on NAME, ...` expected")
                self.take("on"); c["trace"].append(self.take(kind="name"))
                while self.maybe(","): c["trace"].append(self.take(kind="name"))
            elif clause == "stack":
                once("stack", "stack"); e = self.expr()
                c["stack"] = e[1] if e[0] == "num" else ("grows", e)
            elif clause == "calls":
                name = self.take(kind="name"); self.take("if"); c["calls"].append((name, self.expr(1)))
            elif clause == "decreases": once("decreases", "decreases"); c["decreases"] = self.expr()            # a number that is less at every call of itself
            elif clause == "needs":
                # needs FEATURE [if E]: it runs instructions of that kind (only where E holds)
                name = self.take(kind="name"); c["needs"].append((name, self.expr(1) if self.maybe("if") else None))
            else: raise Err(f"line {self.t[self.i - 1][2]}: requires, ensures, writes, returns, stack, trace, calls, needs or decreases expected, not {clause!r}")
        if c["stack"] is None or not (c["leaves"] or c["spoils"] or c["conditions"] or c["returns"] is not None): raise Err("a contract says its stack, and what it ensures, writes or returns")
        return c

    def params(self):
        self.take("("); out = []
        while not self.maybe(")"):
            out.append(self.take(kind="name")); self.maybe(",")
        return out

    def turn(self):
        """A machine's turn: { NAME = E ... }: its states given anew."""
        self.take("{"); out = []
        while not self.maybe("}"):
            name = self.take(kind="name"); self.take("="); out.append(("set", name, self.expr()))
        return out

    def expr(self, level=0):
        if level == 0 and self.maybe("if"):
            c = self.expr(); self.take("then"); a = self.expr(); self.take("else"); return ("ifx", c, a, self.expr())
        if level == len(LEVELS): return self.unary()
        left = self.expr(level + 1)
        while self.t[self.i][0] == "sym" and self.t[self.i][1] in LEVELS[level]:
            op = self.take(); left = ("bin", op, left, self.expr(level + 1))
        return left

    def unary(self):
        if self.maybe("!"): return ("not", self.unary())
        e = self.primary()
        while True:
            # an index is on the line of what it indexes: a `[` on a new line begins the next statement
            if self.peek("[") and self.t[self.i][2] == self.t[self.i - 1][2] and self.maybe("["):
                a = self.expr()
                if self.maybe(".."): e = ("slice", e, a, self.expr())
                else: e = ("index", e, a)
                self.take("]")
            elif self.maybe("."): e = ("field", e, self.take(kind="name"))
            elif self.t[self.i][:2] == ("name", "with") and self.t[self.i + 1][:2] == ("sym", "["):
                # xs with [i: a, j: b]: the list xs with those places replaced
                self.take(); self.take("["); places = []
                while not self.maybe("]"):
                    i = self.expr(1); self.take(":"); places.append((i, self.expr())); self.maybe(",")
                e = ("with", e, places)
            else: return e

    def primary(self):
        k, v, line = self.t[self.i]
        if k == "num": self.i += 1; return ("num", v)
        if self.maybe("("):
            e = self.expr(); self.take(")"); return e
        if self.maybe("["):
            if self.maybe("]"): return ("list", [])
            first = self.expr()
            if self.maybe("for"):
                var = self.take(kind="name"); self.take("in"); a = self.expr(); self.take(".."); b = self.expr(); self.take("]")
                return ("each", first, var, a, b)
            items = [first]
            while self.maybe(","): items.append(self.expr())
            self.take("]"); return ("list", items)
        if self.peek("if"): return self.expr()
        if self.maybe("the"):
            # the least number n in A..B with COND | the greatest power of two k with COND (and the other two)
            which = self.take(kind="name")
            if which not in ("least", "greatest"): raise Err(f"line {line}: `the least` or `the greatest` expected")
            if self.take(kind="name") == "number":
                var = self.take(kind="name"); self.take("in"); a = self.expr(1); self.take(".."); among = ("range", a, self.expr(1))
            else:
                for word in ("of", "two"):
                    if self.take(kind="name") != word: raise Err(f"line {line}: `number NAME in A..B` or `power of two NAME` expected")
                var, among = self.take(kind="name"), ("powers",)
            if self.take(kind="name") != "with": raise Err(f"line {line}: `with` expected")
            return ("the", which, var, among, self.expr())
        if self.maybe("{"):
            fields = []
            while not self.maybe("}"):
                name = self.take(kind="name"); self.take(":"); fields.append((name, self.expr())); self.maybe(",")
            return ("record", fields)
        name = self.take(kind="name")
        if self.maybe("("):
            args = []
            while not self.maybe(")"):
                args.append(self.expr()); self.maybe(",")
            return ("call", name, args)
        return ("name", name)


# ---------------------------------------------------------------------------------------------------------
# Values: a number is an int (or, on symbols, a number that depends on counts); a list is a Python list.
class Word:
    __slots__ = ("v",)
    def __init__(self, v): self.v = v
    def __eq__(self, o): return isinstance(o, Word) and self.v == o.v
    def __hash__(self): return hash(("word", self.v))
    def __repr__(self): return f"word({self.v})"


class Counter:
    """64 bits: its low and high words."""
    __slots__ = ("lo", "hi")
    def __init__(self, lo, hi): self.lo, self.hi = lo, hi


class Numbers:
    """Words are 32-bit numbers."""
    def word(self, n): return Word(n & M32)
    def add(self, a, b): return Word((a.v + b.v) & M32)
    def xor(self, a, b): return Word(a.v ^ b.v)
    def or_(self, a, b): return Word(a.v | b.v)
    def rotr(self, a, n): return Word(((a.v >> n) | (a.v << (32 - n))) & M32)
    def counter(self, n): return Counter(Word(n & M32), Word((n >> 32) & M32))
    def counter_add(self, t, n):
        v = (t.lo.v | t.hi.v << 32) + n
        return Counter(Word(v & M32), Word((v >> 32) & M32))
    def compare(self, op, a, b): return {"==": a == b, "!=": a != b, "<": a < b, "<=": a <= b, ">": a > b, ">=": a >= b}[op]
    def minus(self, x, y):
        if x < y: raise Err(f"{x} - {y}: a number below zero")
        return x - y
    def length(self, x): return len(x)
    def index(self, x, i): return at(x, i)
    def slice(self, x, a, b): return part(x, a, b)
    def concat(self, x, y): return x + y
    def put(self, xs, i, v):
        if not isinstance(xs, list) or not isinstance(i, int) or not 0 <= i < len(xs): raise Err(f"place {i} of a list of {len(xs) if isinstance(xs, list) else '?'}")
        xs = list(xs); xs[i] = v
        return xs
    def words(self, bs):
        if len(bs) % 4 or any(not isinstance(b, int) or not 0 <= b < 256 for b in bs): raise Err("words of something that is not bytes, four to a word")
        return [Word(bs[i] | bs[i + 1] << 8 | bs[i + 2] << 16 | bs[i + 3] << 24) for i in range(0, len(bs), 4)]
    def bytes_of(self, ws):
        if any(not isinstance(w, Word) for w in ws): raise Err("bytes of something that is not words")
        return [(w.v >> (8 * i)) & 0xFF for w in ws for i in range(4)]
    def nothing(self, n): return [None] * n
    def bits(self, x): return Spec.number(x).bit_length()
    def div(self, x, y): return Spec.number(x) // Spec.number(y)
    def mod(self, x, y): return Spec.number(x) % Spec.number(y)
    def mul(self, x, y): return Spec.number(x) * Spec.number(y)
    def plain(self, x): return Spec.number(x)


def at(xs, i):
    """A list's value at a place: the place must be there (no counting from the end, as Python would)."""
    if not isinstance(xs, list) or not isinstance(i, int) or not 0 <= i < len(xs): raise Err(f"place {i} of a list of {len(xs) if isinstance(xs, list) else '?'}")
    if xs[i] is None: raise Err(f"place {i} of a list: nothing was put there")
    return xs[i]


def part(xs, a, b):
    if not isinstance(xs, list) or not isinstance(a, int) or not isinstance(b, int) or not 0 <= a <= b <= len(xs): raise Err(f"places {a} to {b} of a list of {len(xs) if isinstance(xs, list) else '?'}")
    return xs[a:b]


class Tail:
    def __init__(self, name, args): self.name, self.args = name, args


class Fails(Exception):
    """A definition that has no value for what it was given, and says why (`fails REASON if C`)."""
    def __init__(self, reason): self.reason = reason


class Seq:
    """A sequence: its first value, and each next from the one before. `id`: for one that has a name of its own,
    the name and what it was given."""
    def __init__(self): self.first, self.var, self.next, self.env, self.memo, self.id = None, None, None, None, {}, None
    def at(self, spec, A, i):
        if i not in self.memo:
            if self.first is None or self.next is None or i < 0: raise Err("a sequence without its two equations, or a place before its first")
            k = i
            while k > 0 and k - 1 not in self.memo: k -= 1                # from the last one known, upward
            if k == 0 and 0 not in self.memo: self.memo[0] = spec.eval(A, self.first, self.env)
            for j in range(max(k, 1), i + 1):
                inner = dict(self.env); inner[self.var] = j - 1
                self.memo[j] = spec.eval(A, self.next, inner)
        return self.memo[i]


class Spec:
    def __init__(self, text):
        parser = Parser(text)
        self.consts, self.fns, self.machines = parser.file()
        self.contracts, self.layouts, self.kinds, self.turns = parser.contracts, parser.layouts, parser.kinds, 0
        self.seqs, self.seq_cache = parser.seqs, {}
        self.lemmas = parser.lemmas
        for name, l in self.lemmas.items():
            if (name in self.seqs) != (l["index"] is not None) or (name not in self.seqs and name not in self.fns): raise Err(f"lemma {name}: of no definition, or a sequence's lemma without its place")
            if len(l["params"]) != len((self.seqs.get(name) or self.fns.get(name))[0]): raise Err(f"lemma {name}: not the definition's parameters")
        self.fuel = None        # on symbols: the applications that may still be followed before a result is given a name instead
        self.deep = 0
        numbers = Numbers()
        self.consts = {k: self.eval(numbers, e, {}) for k, e in self.consts.items()}

    def tick(self):
        """A `while` loop that does not end is an error of the text, not a wait."""
        self.turns += 1
        if self.turns > 10_000_000: raise Err("a loop has turned ten million times")

    def spend(self):
        if self.fuel is not None:
            self.fuel -= 1
            if self.fuel < 0: raise Err("too much to follow here")

    # -- what the verifiers ask
    def call(self, A, name, *args): return self.apply(A, name, list(args))
    def turn(self, A, name, env):
        """One turn of a machine: env names its arguments, its state, and for a `for` machine its counter."""
        m, env = self.machines[name], dict(env)
        self.run(A, m["turn"], env)
        return self.state_of(m, env)
    @staticmethod
    def state_of(m, env):
        """A machine's state: the one value, or with several states a record of them."""
        return env[m["state"]] if m["state"] is not None else {s: env[s] for s in m["states"]}
    def goes(self, A, name, env):
        """Does the machine turn again from this state? (On symbols it may raise: the facts do not say.)"""
        m = self.machines[name]
        if m["loop"][0] == "while": return self.eval(A, m["loop"][1], env)
        return A.compare("<", env[m["loop"][1]], self.eval(A, m["loop"][3], env))

    # -- the evaluator
    def apply(self, A, name, args):
        if name in self.fns:
            self.spend()
            params, body = self.fns[name]
            if len(params) != len(args): raise Err(f"{name}: {len(params)} arguments expected")
            env = dict(zip(params, args))
            self.deep += 1
            try:
                if self.deep > DEEP: raise Err(f"{name}: a definition of itself that does not come to an end")
                if name in self.kinds and hasattr(A, "named"):
                    # on symbols: a function with a kind that cannot be evaluated here is named by what it was given
                    return A.named(self, name, self.kinds[name], args, lambda: self.body(A, body, env))
                if hasattr(A, "kept"): return A.kept(name, args, lambda: self.body(A, body, env))
                # on numbers: a definition whose value is another definition's (or its own on something smaller)
                # is followed without going deeper
                while True:
                    r = self.run(A, body, env, tail=True)
                    if not isinstance(r, Tail): return r
                    self.spend()
                    params, body = self.fns[r.name]
                    if len(params) != len(r.args): raise Err(f"{r.name}: {len(params)} arguments expected")
                    env = dict(zip(params, r.args))
            finally: self.deep -= 1
        if name in self.seqs:
            params, h, var, first, nxt = self.seqs[name]
            if len(params) != len(args): raise Err(f"{name}: {len(params)} arguments expected")
            key = (name, tuple(id(a) if isinstance(a, list) else a if isinstance(a, int) else None for a in args))
            if None not in key[1] and key in self.seq_cache: return self.seq_cache[key][1]       # the same sequence of the same things
            s = Seq(); s.first, s.var, s.next, s.id = first, var, nxt, (name, list(args))
            s.env = dict(zip(params, args)); s.env[h] = s
            if None not in key[1]: self.seq_cache[key] = (args, s)
            return s
        if name in self.machines:
            m = self.machines[name]
            names = m["params"] + ([] if m["inits"] is not None else m["states"])
            if len(names) != len(args): raise Err(f"{name}: {len(names)} arguments expected")
            env = dict(zip(names, args))
            if m["inits"] is not None:
                first = [self.eval(A, e, env) for e in m["inits"]]
                env.update(zip(m["states"], first))
            if hasattr(A, "machine_result"): return A.machine_result(self, name, m, env)
            return self.run_machine(A, m, env)
        return self.builtin(A, name, args)

    def body(self, A, body, env): return self.run(A, body, env)

    def run_machine(self, A, m, env):
        if m["loop"][0] == "while":
            while self.eval(A, m["loop"][1], env) is True: self.tick(); self.spend(); self.run(A, m["turn"], env)
        else:
            _, var, a, b = m["loop"]
            for i in self.span(A, a, b, env):
                self.spend(); env[var] = i; self.run(A, m["turn"], env)
        return self.state_of(m, env)

    def span(self, A, a, b, env):
        a, b = A.plain(self.eval(A, a, env)), A.plain(self.eval(A, b, env))
        return range(a, b)

    def builtin(self, A, name, args):
        if name == "word": return args[0] if isinstance(args[0], Word) else A.word(args[0])
        if name == "counter": return args[0] if isinstance(args[0], Counter) else A.counter(args[0])
        if name == "words": return A.words(args[0])
        if name == "nothing": return A.nothing(self.number(args[0]))
        if name == "bits": return A.bits(args[0])
        if name == "lo": return args[0].lo
        if name == "hi": return args[0].hi
        if name == "len": return A.length(args[0])
        if name == "ones": return bin(self.number(args[0])).count("1")
        if name == "pow": return self.number(args[0]) ** self.number(args[1])
        if name == "word_bytes": return [(args[0].v >> (8 * i)) & 0xFF for i in range(4)]
        if name == "bytes_of": return A.bytes_of(args[0])
        raise Err(f"no function {name}")

    @staticmethod
    def number(x):
        if not isinstance(x, int) or isinstance(x, bool): raise Err(f"a plain number expected, not {x!r}")
        return x

    def run(self, A, body, env, tail=False):
        last = None
        for s in body:
            kind = s[0]
            if kind == "set": env[s[1]] = self.eval(A, s[2], env); last = None
            elif kind == "fails":
                c = self.eval(A, s[2], env)
                if c is not True and c is not False: raise Err("a condition that is not true or false")
                if c: raise Fails(self.eval(A, s[1], env))
                last = None
            elif kind in ("first", "next"):
                seq = env.get(s[1])
                if not isinstance(seq, Seq): seq = env[s[1]] = Seq()
                seq.env = env
                if kind == "first": seq.first = s[2]
                else: seq.var, seq.next = s[2], s[3]
                last = None
            else: last = self.last(A, s[1], env) if tail else self.eval(A, s[1], env)
        return last

    def last(self, A, e, env):
        """A definition's value: where it is another definition applied, that application is given back to be followed."""
        if e[0] == "ifx":
            c = self.eval(A, e[1], env)
            if c is not True and c is not False: raise Err("a condition that is not true or false")
            return self.last(A, e[2] if c else e[3], env)
        if e[0] == "call" and e[1] in self.fns: return Tail(e[1], [self.eval(A, a, env) for a in e[2]])
        return self.eval(A, e, env)

    def eval(self, A, e, env):
        kind = e[0]
        if kind == "num": return e[1]
        if kind == "name":
            if e[1] in env: return env[e[1]]
            if e[1] in self.consts: return self.consts[e[1]]
            raise Err(f"no name {e[1]}")
        if kind == "call" and e[1] in ("failed", "reason") and len(e[2]) == 1:
            # failed(E): E has no value; reason(E): why (a definition's `fails REASON if C`)
            try: v = self.eval(A, e[2][0], env)
            except Fails as f: return True if e[1] == "failed" else f.reason
            if hasattr(A, "defined"): A.defined(v)             # on symbols: a thing with a name only is not known to have a value
            if e[1] == "reason": raise Err("the reason of something that has a value")
            return False
        if kind == "call": return self.apply(A, e[1], [self.eval(A, a, env) for a in e[2]])
        if kind == "index":
            x = self.eval(A, e[1], env)
            if isinstance(x, Seq):
                i = self.eval(A, e[2], env)
                return A.element(self, x, i) if hasattr(A, "element") else x.at(self, A, A.plain(i))
            return A.index(x, self.eval(A, e[2], env))
        if kind == "the":
            # the least (or greatest) of some numbers for which a condition holds: each is asked in turn
            _, which, var, among, cond = e
            numbers = [1 << i for i in range(64)] if among[0] == "powers" else list(range(A.plain(self.eval(A, among[1], env)), A.plain(self.eval(A, among[2], env))))
            for v in (numbers if which == "least" else reversed(numbers)):
                inner = dict(env); inner[var] = v
                c = self.eval(A, cond, inner)
                if c is True: return v
                if c is not False: raise Err("a condition that is not true or false")
            raise Err(f"the {which} {var}: there is none")
        if kind == "slice": return A.slice(self.eval(A, e[1], env), self.eval(A, e[2], env), self.eval(A, e[3], env))
        if kind == "list": return [self.eval(A, x, env) for x in e[1]]
        if kind == "record": return {name: self.eval(A, x, env) for name, x in e[1]}
        if kind == "with":
            xs = self.eval(A, e[1], env)
            for i, x in e[2]: xs = A.put(xs, self.eval(A, i, env), self.eval(A, x, env))
            return xs
        if kind == "field":
            record = self.eval(A, e[1], env)
            if not isinstance(record, dict) or e[2] not in record: raise Err(f"no field {e[2]}")
            return record[e[2]]
        if kind == "each":
            out = []
            for i in self.span(A, e[3], e[4], env):
                inner = dict(env); inner[e[2]] = i; out.append(self.eval(A, e[1], inner))
            return out
        if kind == "ifx":
            c = self.eval(A, e[1], env)
            if c is not True and c is not False: raise Err("a condition that is not true or false")
            return self.eval(A, e[2] if c else e[3], env)
        if kind == "not":
            c = self.eval(A, e[1], env)
            if c is not True and c is not False: raise Err("a condition that is not true or false")
            return not c
        op, x = e[1], self.eval(A, e[2], env)
        if op == "&&": return x is True and self.eval(A, e[3], env) is True
        if op == "||": return x is True or self.eval(A, e[3], env) is True
        y = self.eval(A, e[3], env)
        if op in ("==", "!=", "<", "<=", ">", ">="): return A.compare(op, x, y)
        if op == "++": return A.concat(x, y)
        if op == ">>>": return A.rotr(self.as_word(A, x), self.number(y))
        words = isinstance(x, Word) or isinstance(y, Word)
        if op == "+" and isinstance(x, Counter): return A.counter_add(x, self.number(y))
        if op == "+" and words: return A.add(self.as_word(A, x), self.as_word(A, y))
        if op == "^": return A.xor(self.as_word(A, x), self.as_word(A, y))
        if op == "|" and words: return A.or_(self.as_word(A, x), self.as_word(A, y))
        if isinstance(x, Word) or isinstance(y, Word): raise Err(f"{op} of words")
        if op == "+": return A.plus(x, y) if hasattr(A, "plus") else x + y
        if op == "-": return A.minus(x, y)
        if op == "*": return A.mul(x, y)
        if op == "/": return A.div(x, y)
        if op == "%": return A.mod(x, y)
        if op == "|": return self.number(x) | self.number(y)
        if op == "&": return self.number(x) & self.number(y)
        raise Err(f"no operator {op}")

    @staticmethod
    def as_word(A, x): return x if isinstance(x, Word) else A.word(x)


HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = ["blake3.spec", os.path.join("proofs", "inner.spec")]      # the specification and the claim; what the functions inside are claimed to do


def source():
    """The specification's text, and after it the contracts of the functions inside."""
    out = []
    for name in SOURCES:
        with open(os.path.join(HERE, name)) as f: out.append(f.read())
    return "\n".join(out)


def load(path=None):
    if path is None: return Spec(source())
    with open(path) as f: return Spec(f.read())


def vectors(spec, path, up_to=None):
    """The specification on the official test vectors: hash, keyed hash and key derivation, at every length."""
    with open(path) as f: v = json.load(f)
    A, key, context = Numbers(), list(v["key"].encode()), list(v["context_string"].encode())
    done = 0
    for case in v["cases"]:
        n = case["input_len"]
        if up_to is not None and n > up_to: continue
        message = [i % 251 for i in range(n)]
        for mode, got in (("hash", spec.call(A, "blake3", message)), ("keyed_hash", spec.call(A, "blake3_keyed", key, message)),
                          ("derive_key", spec.call(A, "blake3_derive_key", context, message))):
            if bytes(got).hex() != case[mode][:64]: raise Err(f"{mode} of {n} bytes: {bytes(got).hex()}, the vector says {case[mode][:64]}")
            done += 1
    return done


def main():
    spec = load(sys.argv[1])
    if "--vectors" in sys.argv:
        up_to = int(sys.argv[sys.argv.index("--up-to") + 1]) if "--up-to" in sys.argv else None
        t0 = time.time()
        n = vectors(spec, sys.argv[sys.argv.index("--vectors") + 1], up_to)
        print(f"{os.path.basename(sys.argv[1])}: {n} official test vectors (hash, keyed hash, key derivation" + (f"; inputs up to {up_to} bytes" if up_to is not None else "") + f") as the vectors say, in {time.time() - t0:.1f} s")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Err as e:
        print(f"ode: {e}"); sys.exit(1)
