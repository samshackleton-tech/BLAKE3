#!/usr/bin/env python3
"""ode: a specification that runs, read on numbers and on symbols.

    python3 ode.py blake3.ode --vectors ../../../../test_vectors/test_vectors.json [--up-to BYTES]

The language is described at the top of blake3.ode. This file is its reader: a parser (to a tree), and one
evaluator of the tree over an "algebra" of words: Numbers (words are 32-bit numbers) or Symbols (words are
the checkers' terms; a comparison of numbers that depend on a count is decided from the path's facts, or the
evaluation stops). The same text is thus the thing that gives BLAKE3's test vectors and the thing code is
compared with.

    fn NAME(args) { statements }           the value of the last expression, or of `return`
    machine NAME(args) on STATE [= INIT] { while COND | for I in A..B   turn { statements } }
    const NAME = EXPR

A machine called as a function runs to its end (its state the last argument, if it has no INIT). The
checkers ask it for one `turn` and whether it `goes` on."""
import json, os, re, sys, time

M32 = 0xFFFFFFFF


class Err(Exception):
    pass


# ---------------------------------------------------------------------------------------------------------
# Text to tree.
TOKEN = re.compile(r"\s*(?:(//[^\n]*)|(0x[0-9A-Fa-f]+|\d+)|([A-Za-z_][A-Za-z_0-9]*)|(>>>|\+\+|\.\.|==|!=|<=|>=|&&|\|\||[-+*/%^|&<>=!(){}\[\],:.]))")
KEYWORDS = {"const", "fn", "machine", "contract", "on", "while", "for", "in", "turn", "if", "then", "else", "let", "var", "return"}
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
        consts, fns, machines, self.contracts = {}, {}, {}, {}
        while not self.peek(kind="end"):
            if self.maybe("const"):
                name = self.take(kind="name"); self.take("="); consts[name] = self.expr()
            elif self.maybe("fn"):
                name = self.take(kind="name"); fns[name] = (self.params(), self.block())
            elif self.maybe("machine"):
                name = self.take(kind="name"); params = self.params(); self.take("on"); state = self.take(kind="name")
                init = self.expr() if self.maybe("=") else None
                self.take("{")
                if self.maybe("while"): loop = ("while", self.expr())
                else:
                    self.take("for"); var = self.take(kind="name"); self.take("in"); a = self.expr(); self.take(".."); loop = ("for", var, a, self.expr())
                self.take("turn"); turn = self.block(); self.take("}")
                machines[name] = dict(params=params, state=state, init=init, loop=loop, turn=turn)
            elif self.maybe("contract"):
                name = self.take(kind="name"); self.contracts[name] = self.contract()
            else: raise Err(f"line {self.t[self.i][2]}: const, fn, machine or contract expected")
        return consts, fns, machines

    def contract(self):
        """(arg: kind, ...) { asks E | leaves NAME = E | returns E | stack N | calls F if E }"""
        self.take("("); args = []
        while not self.maybe(")"):
            arg = self.take(kind="name"); self.take(":"); kind = []
            while self.peek(kind="name") or self.peek(kind="num"): kind.append(str(self.take()))
            if not kind: raise Err(f"line {self.t[self.i][2]}: the kind of {arg} expected")
            args.append((arg, " ".join(kind))); self.maybe(",")
        c = dict(args=args, asks=[], leaves=[], returns=None, stack=None, calls=[])
        self.take("{")
        while not self.maybe("}"):
            clause = self.take(kind="name")
            if clause == "asks": c["asks"].append(self.expr())
            elif clause == "leaves":
                # leaves NAME = E, or leaves NAME[I] = E for I in A..B (each place of what NAME addresses)
                name, index, each = self.take(kind="name"), None, None
                if self.maybe("["):
                    index = self.take(kind="name"); self.take("]")
                self.take("="); e = self.expr()
                if index is not None:
                    self.take("for")
                    if self.take(kind="name") != index: raise Err(f"line {self.t[self.i - 1][2]}: `for {index}` expected")
                    self.take("in"); a = self.expr(); self.take(".."); each = (a, self.expr())
                c["leaves"].append(dict(name=name, index=index, expr=e, each=each))
            elif clause == "returns": c["returns"] = self.expr()
            elif clause == "stack": c["stack"] = self.take(kind="num")
            elif clause == "calls":
                name = self.take(kind="name"); self.take("if"); c["calls"].append((name, self.expr(1)))
            else: raise Err(f"line {self.t[self.i - 1][2]}: asks, leaves, returns, stack or calls expected, not {clause!r}")
        if c["stack"] is None or len(c["leaves"]) != 1: raise Err("a contract says its stack, and what one thing it leaves")
        return c

    def params(self):
        self.take("("); out = []
        while not self.maybe(")"):
            out.append(self.take(kind="name")); self.maybe(",")
        return out

    def block(self):
        self.take("{"); out = []
        while not self.maybe("}"): out.append(self.stmt())
        return out

    def stmt(self):
        if self.maybe("let") or self.maybe("var"):
            name = self.take(kind="name"); self.take("="); return ("set", name, self.expr())
        if self.maybe("for"):
            var = self.take(kind="name"); self.take("in"); a = self.expr(); self.take(".."); b = self.expr(); return ("for", var, a, b, self.block())
        if self.maybe("while"):
            c = self.expr(); return ("while", c, self.block())
        if self.maybe("return"): return ("return", self.expr())
        if self.peek("if"):
            # a statement `if c { }` or an expression `if c then a else b`: the brace or `then` says which
            save = self.i; self.take("if"); c = self.expr()
            if self.peek("{"):
                then = self.block(); other = self.block() if self.maybe("else") else []
                return ("if", c, then, other)
            self.i = save
        if self.peek(kind="name") and self.t[self.i + 1][1] == "=" and self.t[self.i + 1][0] == "sym":
            name = self.take(kind="name"); self.take("="); return ("set", name, self.expr())
        if self.peek(kind="name") and self.t[self.i + 1][1] == "[":
            # NAME[i] = e, or an expression that starts so
            save = self.i; name = self.take(kind="name"); self.take("["); i = self.expr()
            if self.maybe("]") and self.maybe("="): return ("setidx", name, i, self.expr())
            self.i = save
        return ("expr", self.expr())

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


def at(xs, i):
    """A list's value at a place: the place must be there (no counting from the end, as Python would)."""
    if not isinstance(xs, list) or not isinstance(i, int) or not 0 <= i < len(xs): raise Err(f"place {i} of a list of {len(xs) if isinstance(xs, list) else '?'}")
    return xs[i]


def part(xs, a, b):
    if not isinstance(xs, list) or not isinstance(a, int) or not isinstance(b, int) or not 0 <= a <= b <= len(xs): raise Err(f"places {a} to {b} of a list of {len(xs) if isinstance(xs, list) else '?'}")
    return xs[a:b]


class Return(Exception):
    def __init__(self, value): self.value = value


class Spec:
    def __init__(self, text):
        parser = Parser(text)
        self.consts, self.fns, self.machines = parser.file()
        self.contracts, self.turns = parser.contracts, 0
        numbers = Numbers()
        self.consts = {k: self.eval(numbers, e, {}) for k, e in self.consts.items()}

    def tick(self):
        """A `while` loop that does not end is an error of the text, not a wait."""
        self.turns += 1
        if self.turns > 10_000_000: raise Err("a loop has turned ten million times")

    # -- what the checkers ask
    def call(self, A, name, *args): return self.apply(A, name, list(args))
    def turn(self, A, name, env):
        """One turn of a machine: env names its arguments, its state, and for a `for` machine its counter."""
        m, env = self.machines[name], dict(env)
        self.run(A, m["turn"], env)
        return env[m["state"]]
    def goes(self, A, name, env):
        """Does the machine turn again from this state? (On symbols it may raise: the facts do not say.)"""
        m = self.machines[name]
        if m["loop"][0] == "while": return self.eval(A, m["loop"][1], env)
        return A.compare("<", env[m["loop"][1]], self.eval(A, m["loop"][3], env))

    # -- the evaluator
    def apply(self, A, name, args):
        if name in self.fns:
            params, body = self.fns[name]
            if len(params) != len(args): raise Err(f"{name}: {len(params)} arguments expected")
            env = dict(zip(params, args))
            try:
                last = self.run(A, body, env)
            except Return as r: return r.value
            return last
        if name in self.machines:
            m = self.machines[name]
            names = m["params"] + ([] if m["init"] is not None else [m["state"]])
            if len(names) != len(args): raise Err(f"{name}: {len(names)} arguments expected")
            env = dict(zip(names, args))
            if m["init"] is not None: env[m["state"]] = self.eval(A, m["init"], env)
            named = A.machine_result(name, m, env) if hasattr(A, "machine_result") else None
            if named is not None: return named          # on symbols: what the machine makes of a state it cannot be run on
            if m["loop"][0] == "while":
                while self.eval(A, m["loop"][1], env) is True: self.tick(); self.run(A, m["turn"], env)
            else:
                _, var, a, b = m["loop"]
                for i in self.span(A, a, b, env):
                    env[var] = i; self.run(A, m["turn"], env)
            return env[m["state"]]
        return self.builtin(A, name, args)

    def span(self, A, a, b, env):
        a, b = self.eval(A, a, env), self.eval(A, b, env)
        if not isinstance(a, int) or not isinstance(b, int): raise Err("a loop whose bounds are not plain numbers (a machine's loop is turned by the checker)")
        return range(a, b)

    def builtin(self, A, name, args):
        if name == "word": return args[0] if isinstance(args[0], Word) else A.word(self.number(args[0]))
        if name == "counter": return A.counter(self.number(args[0]))
        if name == "lo": return args[0].lo
        if name == "hi": return args[0].hi
        if name == "len": return A.length(args[0])
        if name == "ones": return bin(self.number(args[0])).count("1")
        if name == "word_bytes": return [(args[0].v >> (8 * i)) & 0xFF for i in range(4)]
        raise Err(f"no function {name}")

    @staticmethod
    def number(x):
        if not isinstance(x, int) or isinstance(x, bool): raise Err(f"a plain number expected, not {x!r}")
        return x

    def run(self, A, body, env):
        last = None
        for s in body:
            kind = s[0]
            if kind == "set": env[s[1]] = self.eval(A, s[2], env); last = None
            elif kind == "setidx":
                xs, i = list(env[s[1]]), self.number(self.eval(A, s[2], env))
                if not 0 <= i < len(xs): raise Err(f"place {i} of a list of {len(xs)}")
                xs[i] = self.eval(A, s[3], env); env[s[1]] = xs; last = None
            elif kind == "for":
                for i in self.span(A, s[2], s[3], env):
                    env[s[1]] = i; self.run(A, s[4], env)
                last = None
            elif kind == "while":
                while self.eval(A, s[1], env) is True: self.tick(); self.run(A, s[2], env)
                last = None
            elif kind == "if":
                self.run(A, s[2] if self.eval(A, s[1], env) is True else s[3], env); last = None
            elif kind == "return": raise Return(self.eval(A, s[1], env))
            else: last = self.eval(A, s[1], env)
        return last

    def eval(self, A, e, env):
        kind = e[0]
        if kind == "num": return e[1]
        if kind == "name":
            if e[1] in env: return env[e[1]]
            if e[1] in self.consts: return self.consts[e[1]]
            raise Err(f"no name {e[1]}")
        if kind == "call": return self.apply(A, e[1], [self.eval(A, a, env) for a in e[2]])
        if kind == "index": return A.index(self.eval(A, e[1], env), self.eval(A, e[2], env))
        if kind == "slice": return A.slice(self.eval(A, e[1], env), self.eval(A, e[2], env), self.eval(A, e[3], env))
        if kind == "list": return [self.eval(A, x, env) for x in e[1]]
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
        if kind == "not": return not self.eval(A, e[1], env)
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
        if op == "+": return x + y
        if op == "-": return A.minus(x, y)
        if op == "*": return x * y
        if op == "/": return self.number(x) // self.number(y)
        if op == "%": return self.number(x) % self.number(y)
        if op == "|": return self.number(x) | self.number(y)
        if op == "&": return self.number(x) & self.number(y)
        raise Err(f"no operator {op}")

    @staticmethod
    def as_word(A, x): return x if isinstance(x, Word) else A.word(Spec.number(x))


def load(path=None):
    with open(path or os.path.join(os.path.dirname(os.path.abspath(__file__)), "blake3.ode")) as f: return Spec(f.read())


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
