"""kspec: the specification (blake3.ode) read on symbols, for the checkers.

ode.py evaluates the specification's text over an algebra of words. Numbers (ode.Numbers) gives the test
vectors. Symbols, here, gives the checkers their terms: a word is a term of the checker's table (kcheck.Terms);
a number may depend on counts (klin.Lin), and a comparison of such numbers is decided from the path's facts or
the evaluation stops; a list may be a stack of chaining values of unknown count (Stack) or a lane's input of
unknown length (Blocks). There is no other specification: kcheck.py, kloop.py and kglue.py take compress, the
chunk machine, parent and the merge machine from the one text."""
import ode
from ode import Word, Counter, Err
from klin import Lin, Facts

SPEC = ode.load()


def plain(x):
    x = Lin.of(x)
    return x if x.c else x.k


# ---------------------------------------------------------------------------------------------------------
# A byte that is a number, or a number or-ed with named unknown bytes: the flags, and what is or-ed into them.
def byte(x): return (x, ()) if isinstance(x, int) else x
def unbyte(c, names): return c if not names else (c, tuple(sorted(set(names))))
def byte_or(x, y):
    (c, p), (d, q) = byte(x), byte(y)
    return unbyte(c | d, p + q)
def byte_term(T, x):
    """A byte, zero-extended to a word, as a term."""
    c, names = byte(x)
    return T.const(c) if not names else T.mk("orb", c, names)
def term_byte(T, t):
    """A term that is such a byte, as the byte; None if it is not one."""
    k = T.nodes[t]
    if k[0] == "c" and k[1] < 256: return k[1]
    if k[0] == "orb": return (k[1], k[2])
    return None


# ---------------------------------------------------------------------------------------------------------
# Lists whose length is not a plain number.
class Stack:
    """A stack of chaining values: a named unknown stack with some places replaced, and its count. Place 0
    is the oldest value."""
    def __init__(self, base, count, over=None):
        self.base, self.count, self.over = base, Lin.of(count), dict(over or {})
    def get(self, T, facts, i):
        i = Lin.of(i)
        for j, words in self.over.items():
            z = facts.zero(i - j)
            if z is None: raise Err(f"places {i} and {j} of a stack: the facts do not say whether they are one")
            if z: return words
        return tuple(T.var("value", self.base, plain(i), w) for w in range(8))
    def put(self, T, facts, i, words, count=None):
        i, over = Lin.of(i), {}
        for j, old in self.over.items():
            z = facts.zero(i - j)
            if z is None: raise Err(f"places {i} and {j} of a stack: the facts do not say whether they are one")
            if not z: over[j] = old
        over[i] = tuple(words)
        return Stack(self.base, self.count if count is None else count, over)
    def counted(self, count): return Stack(self.base, count, self.over)
    def same(self, T, facts, other):
        """The same count, and the same value at every place below it."""
        if self.base != other.base or self.count != other.count: return False
        for i in set(self.over) | set(other.over):
            if facts.ge0(i - self.count): continue                         # at or above the count: no part of the stack
            if not facts.ge0(self.count - i - 1): raise Err(f"place {i} of a stack: the facts do not say whether it is below the count {self.count}")
            if self.get(T, facts, i) != other.get(T, facts, i): return False
        return True
    def key(self, T, facts):
        """What names this stack's value: for a machine's result, which is a function of it."""
        below = []
        for i, words in self.over.items():
            if facts.ge0(i - self.count): continue
            if not facts.ge0(self.count - i - 1): raise Err(f"place {i} of a stack: the facts do not say whether it is below the count {self.count}")
            below.append((repr(i), words))
        return (self.base, self.count, tuple(sorted(below)))


class Blocks:
    """A lane's input: its blocks by number, sixteen words each."""
    def __init__(self, lane): self.lane = lane


class Inputs:
    """The inputs a kernel is given the addresses of: each a lane's blocks."""
    def __init__(self, lanes): self.lanes = lanes


# ---------------------------------------------------------------------------------------------------------
# The algebra.
class Symbols:
    def __init__(self, T, facts=None): self.T, self.facts = T, facts if facts is not None else Facts()
    def word(self, n): return Word(self.T.const(n))
    def add(self, a, b): return Word(self.T.add(a.v, b.v))
    def xor(self, a, b): return Word(self.T.xor(a.v, b.v))
    def rotr(self, a, n): return Word(self.T.ror(a.v, n))
    def or_(self, a, b):
        # BLAKE3 ors nothing but flag bytes
        x, y = term_byte(self.T, a.v), term_byte(self.T, b.v)
        if x is None or y is None: raise Err("an or of words that are not flag bytes")
        return Word(byte_term(self.T, byte_or(x, y)))
    def counter(self, n): return Counter(Word(self.T.const(n & 0xFFFFFFFF)), Word(self.T.const(n >> 32)))
    def counter_add(self, t, n):
        # 64 bits in two words: the low word plus n, and a carry into the high word when the sum is below the low word
        T = self.T
        low = T.add(t.lo.v, T.const(n))
        return Counter(Word(low), Word(T.ite(T.ult(low, t.lo.v), T.add(t.hi.v, T.const(1)), t.hi.v)))
    def compare(self, op, a, b):
        d = Lin.of(a) - Lin.of(b)
        if not d.c: return {"==": d.k == 0, "!=": d.k != 0, "<": d.k < 0, "<=": d.k <= 0, ">": d.k > 0, ">=": d.k >= 0}[op]
        if op in ("==", "!="):
            z = self.facts.zero(d)
            if z is None: raise Err(f"the specification asks whether {Lin.of(a)} is {Lin.of(b)}, and the code's path does not say")
            return z == (op == "==")
        if op in (">=", "<"): yes = True if self.facts.ge0(d) else False if self.facts.ge0(-d - 1) else None       # is a >= b?
        else: yes = True if self.facts.ge0(d - 1) else False if self.facts.ge0(-d) else None                       # is a > b?
        if yes is None: raise Err(f"the specification asks how {Lin.of(a)} and {Lin.of(b)} compare, and the code's path does not say")
        return yes if op in (">=", ">") else not yes
    def machine_result(self, name, m, env):
        """A machine applied to a stack whose count is not a plain number cannot be run: its result is a stack
        named by the machine and everything it was given, with a count of its own. (In the machine's own
        function the code is checked against it turn by turn; here a caller only names what it gets.)"""
        state = env[m["state"]]
        if not isinstance(state, Stack) or not state.count.c: return None
        named = self.T.mk("machine", name, *(self.key(env[p]) for p in m["params"]), state.key(self.T, self.facts))
        count = Lin([(f"count of {name} {named}", 1)])
        self.facts.add(count)
        return Stack((name, named), count)
    def key(self, v):
        if isinstance(v, Word): return ("word", v.v)
        if isinstance(v, Counter): return ("counter", v.lo.v, v.hi.v)
        if isinstance(v, list): return tuple(self.key(x) for x in v)
        if isinstance(v, Stack): return v.key(self.T, self.facts)
        if isinstance(v, Blocks): return ("blocks", v.lane)
        return Lin.of(v)
    def minus(self, x, y):
        d = Lin.of(x) - Lin.of(y)
        if not self.facts.ge0(d): raise Err(f"the specification takes {Lin.of(y)} from {Lin.of(x)}, and the code's path does not show the result is not below zero")
        return plain(d)
    def length(self, x): return plain(x.count) if isinstance(x, Stack) else len(x)
    def index(self, x, i):
        if isinstance(x, Stack): return [Word(t) for t in x.get(self.T, self.facts, i)]
        if isinstance(x, Blocks): return [Word(self.T.var("input", x.lane, plain(i), w)) for w in range(16)]
        if isinstance(x, Inputs):
            if not isinstance(i, int) or not 0 <= i < x.lanes: raise Err(f"input {i} of {x.lanes}")
            return Blocks(i)
        return ode.at(x, i)
    def slice(self, x, a, b):
        if isinstance(x, Stack):
            if plain(a) != 0: raise Err("a part of a stack that does not begin at its oldest value")
            return x.counted(b)
        return ode.part(x, a, b)
    def concat(self, x, y):
        if isinstance(x, Stack):
            if not isinstance(y, list) or len(y) != 1: raise Err("a stack takes one value at a time")
            return x.put(self.T, self.facts, x.count, [w.v for w in y[0]], x.count + 1)
        return x + y


def asked(contract, A, env):
    """What a contract asks, as numbers the caller must show are not below zero."""
    out = []
    for e in contract["asks"]:
        if e[0] != "bin" or e[1] not in (">=", "<=", ">", "<"): raise Err("a contract asks something that is not an order of two numbers")
        x, y = Lin.of(SPEC.eval(A, e[2], env)), Lin.of(SPEC.eval(A, e[3], env))
        out.append({">=": x - y, "<=": y - x, ">": x - y - 1, "<": y - x - 1}[e[1]])
    return out


def words(terms): return [Word(t) for t in terms]
def terms(ws): return tuple(w.v for w in ws)
