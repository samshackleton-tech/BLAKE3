"""kspec: the specification (blake3.spec) read on symbols, for the verifiers.

ode.py evaluates the specification's text over an algebra of words. Numbers (ode.Numbers) gives the test
vectors. Symbols, here, gives the verifiers their terms: a word is a term of the verifier's table (kcheck.Terms);
a number may depend on counts (klin.Lin), and a comparison of such numbers is decided from the path's facts or
the evaluation stops. There is no other specification: every verifier takes what it compares code with from
the one text.

Values that are not plain lists:
  Stack    a stack of chaining values of unknown count (kglue.py)
  Blocks   a lane's input of unknown length; Inputs: a kernel's table of them (kloop.py)
  Arr      an array of chaining values: a named unknown array (or one nothing was written to) with some
           places replaced; a place may be a number that depends on counts
  Slice    some bytes of a named region of memory (a message): from an offset, a length
  Named    bytes that are the result of something that could not be evaluated: named by what made them
  a record is a dict.

A machine that cannot be run on symbols (its condition depends on a count the path does not fix) gives a
result of the shape of its first state, named by the machine and all it was given. A `fn` with a kind
(`fn f(..): node`) that cannot be evaluated gives a value of that kind, named likewise. Two such results are
one thing exactly when the names are: both are functions of what they were given. (If a machine does not
stop, its result is a name for nothing, and a contract that speaks of it claims nothing for that input.)"""
import ode
from ode import Word, Counter, Err
from klin import Lin, Facts, sym

SPEC = ode.load()
HALVES = {}                 # the symbol of x / 2 -> x (for facts of the kind "x is below 2^k")
FUEL = 2000000              # applications of the specification's functions followed before a result is named instead


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


class Count(Counter):
    """A counter that is a number (a chunk's number): its two words, and the number."""
    __slots__ = ("n",)
    def __init__(self, lo, hi, n):
        super().__init__(lo, hi); self.n = n


class Blocks:
    """A lane's input: its blocks by number, sixteen words each."""
    def __init__(self, lane): self.lane = lane


class Inputs:
    """The inputs a kernel is given the addresses of: each a lane's blocks."""
    def __init__(self, lanes): self.lanes = lanes


class Arr:
    """An array of chaining values. `base`: the name of an unknown array, or None (nothing was written: a
    place not replaced has no value). `over`: the places replaced."""
    def __init__(self, base, size, over=None): self.base, self.size, self.over = base, size, dict(over or {})
    def where(self, facts, i):
        i = Lin.of(i)
        if not facts.ge0(i) or not facts.ge0(self.size - 1 - i): raise Err(f"place {i} of an array of {self.size}: not shown to be within it")
        return i
    def get(self, T, facts, i):
        i = self.where(facts, i)
        for j, words in self.over.items():
            z = facts.zero(i - j)
            if z is None: raise Err(f"places {i} and {j} of an array: the facts do not say whether they are one")
            if z: return words
        if self.base is None: raise Err(f"place {i} of an array: nothing was put there")
        return tuple(T.var("value", self.base, plain(i), w) for w in range(8))
    def put(self, T, facts, i, words):
        i, over = self.where(facts, i), {}
        for j, old in self.over.items():
            z = facts.zero(i - j)
            if z is None: raise Err(f"places {i} and {j} of an array: the facts do not say whether they are one")
            if not z: over[j] = old
        over[i] = tuple(words)
        return Arr(self.base, self.size, over)
    def key(self): return ("arr", self.base, self.size, tuple(sorted((repr(i), w) for i, w in self.over.items())))
    def same(self, T, facts, other):
        """The same value at every place either has replaced (and the same array beneath)."""
        if self.base != other.base or self.size != other.size: return False
        for i in set(self.over) | set(other.over):
            mine, theirs = self.has(T, facts, i), other.has(T, facts, i)
            if mine != theirs: return False
        return True
    def has(self, T, facts, i):
        try: return self.get(T, facts, i)
        except Err:
            if self.base is None: return None
            raise


class ByteT:
    """A byte that is a term (a byte of a message)."""
    __slots__ = ("v",)
    def __init__(self, v): self.v = v
    def __eq__(self, o): return isinstance(o, ByteT) and self.v == o.v
    def __hash__(self): return hash(("byte", self.v))
    def __repr__(self): return f"byte({self.v})"


class Slice:
    """n bytes of the memory named `base`, from the offset `off`."""
    def __init__(self, base, off, n): self.base, self.off, self.n = base, Lin.of(off), Lin.of(n)
    def key(self): return ("slice", self.base, self.off, self.n)


class Named:
    """n bytes named by what made them."""
    def __init__(self, name, n): self.name, self.n = name, n
    def key(self): return ("named", self.name, self.n)


# ---------------------------------------------------------------------------------------------------------
# The algebra.
class Symbols:
    def __init__(self, T, facts=None, memo=None, ghost=None):
        self.T, self.facts = T, facts if facts is not None else Facts()
        self.memo = memo if memo is not None else {}        # what was named or evaluated on this path, by what it was given
        self.ghost = ghost or {}                            # a machine the verifier is at a place of: its state there
        self.unrun = []                                     # the machines that could not be run: (instance, first state)
        self.bound = None                                   # "least" or "most": how `bits` of a number the path does not fix is read
        self.fold = False                                   # at a call: a function with a kind is not opened, only named
        self.depth = 0                                      # how many functions with a kind are being followed
    def word(self, n):
        n = plain(n)
        return Word(self.T.const(n)) if isinstance(n, int) else Word(self.T.mk("numw", n))
    def add(self, a, b): return Word(self.T.add(a.v, b.v))
    def xor(self, a, b): return Word(self.T.xor(a.v, b.v))
    def rotr(self, a, n): return Word(self.T.ror(a.v, n))
    def or_(self, a, b):
        # BLAKE3 ors nothing but flag bytes
        x, y = term_byte(self.T, a.v), term_byte(self.T, b.v)
        if x is None or y is None: raise Err("an or of words that are not flag bytes")
        return Word(byte_term(self.T, byte_or(x, y)))
    def counter(self, n):
        n = plain(n)
        if isinstance(n, int): return Count(Word(self.T.const(n & 0xFFFFFFFF)), Word(self.T.const(n >> 32)), n)
        return Count(Word(self.T.mk("lo", n)), Word(self.T.mk("hi", n)), n)
    def counter_add(self, t, n):
        if isinstance(t, Count):
            # a counter that is a number, plus a number: the sum's counter, where the sum is shown to stay within 64 bits
            total = Lin.of(t.n) + n
            if not self.facts.ge0((1 << 64) - 1 - total): raise Err(f"the counter {total} is not shown to stay within 64 bits")
            return self.counter(total)
        # 64 bits in two words: the low word plus n, and a carry into the high word when the sum is below the low word
        T = self.T
        low = T.add(t.lo.v, T.const(n))
        return Counter(Word(low), Word(T.ite(T.ult(low, t.lo.v), T.add(t.hi.v, T.const(1)), t.hi.v)))
    def compare(self, op, a, b):
        if not isinstance(a, (int, Lin)) or not isinstance(b, (int, Lin)): raise Err("a comparison of things that are not numbers")
        d = self.facts.subst(Lin.of(a) - Lin.of(b))
        if not d.c: return {"==": d.k == 0, "!=": d.k != 0, "<": d.k < 0, "<=": d.k <= 0, ">": d.k > 0, ">=": d.k >= 0}[op]
        if op in ("==", "!="):
            z = self.facts.zero(d)
            if z is None: raise Err(f"the specification asks whether {Lin.of(a)} is {Lin.of(b)}, and the code's path does not say")
            return z == (op == "==")
        if op in (">=", "<"): yes = True if self.facts.ge0(d) else False if self.facts.ge0(-d - 1) else None       # is a >= b?
        else: yes = True if self.facts.ge0(d - 1) else False if self.facts.ge0(-d) else None                       # is a > b?
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
    def div(self, x, d): return plain(halved(self.facts, x, d))
    def mod(self, x, d): return plain(Lin.of(x) - Lin.of(halved(self.facts, x, d)).scale(ode.Spec.number(d)))
    def bits(self, x):
        """The length in bits of a number. Where the path does not fix it: the least it can be, or the most
        (the verifier says which it needs: the stack a function may use, or the stack a callee may use)."""
        x = self.facts.subst(Lin.of(x))
        if not x.c: return x.k.bit_length()
        if self.bound == "most":
            # the least j for which x <= 2^j - 1 is shown (if it is shown for j it is for every greater one)
            lo, hi = 0, 65
            while lo < hi:
                mid = (lo + hi) // 2
                if self.facts.ge0((1 << mid) - 1 - x): hi = mid
                else: lo = mid + 1
            return lo
        if self.bound == "least":
            # the greatest j for which x >= 2^(j-1) is shown
            lo, hi = 0, 64
            while lo < hi:
                mid = (lo + hi + 1) // 2
                if self.facts.ge0(x - (1 << (mid - 1))): lo = mid
                else: hi = mid - 1
            return lo
        raise Err(f"the length in bits of {x}, which the path does not fix")
    def plain(self, x):
        """A number the path fixes, as a plain number."""
        n = self.facts.number(Lin.of(x)) if isinstance(x, (int, Lin)) else None
        if n is None and isinstance(x, Lin):
            # fixed by the facts together, not by one of them: a small number is looked for
            n = next((c for c in range(65) if self.facts.zero(x - c) is True), None)
        if n is None: raise Err(f"a plain number expected, not {x!r}")
        return n

    # -- lists, arrays, bytes
    def length(self, x):
        if isinstance(x, Stack): return plain(x.count)
        if isinstance(x, Slice): return plain(x.n)
        if isinstance(x, Named): return x.n
        if isinstance(x, Arr): return x.size
        return len(x)
    def index(self, x, i):
        if isinstance(x, Stack): return [Word(t) for t in x.get(self.T, self.facts, i)]
        if isinstance(x, Arr): return [Word(t) for t in x.get(self.T, self.facts, i)]
        if isinstance(x, Blocks): return [Word(self.T.var("input", x.lane, plain(i), w)) for w in range(16)]
        if isinstance(x, Inputs):
            if not isinstance(i, int) or not 0 <= i < x.lanes: raise Err(f"input {i} of {x.lanes}")
            return Blocks(i)
        if isinstance(x, Slice):
            i = Lin.of(i)
            if not self.facts.ge0(i) or not self.facts.ge0(x.n - 1 - i): raise Err(f"byte {i} of {x.n} bytes: not shown to be one of them")
            return ByteT(self.T.var("byte", x.base, plain(x.off + i)))
        if isinstance(x, Named): return ByteT(self.T.mk("byte of", x.key(), self.plain(i)))
        return ode.at(x, i if isinstance(i, int) else self.plain(i))
    def slice(self, x, a, b):
        if isinstance(x, Stack):
            if plain(a) != 0: raise Err("a part of a stack that does not begin at its oldest value")
            return x.counted(b)
        if isinstance(x, Slice):
            a, b = Lin.of(a), Lin.of(b)
            if not self.facts.ge0(a) or not self.facts.ge0(b - a) or not self.facts.ge0(x.n - b): raise Err(f"bytes {a} to {b} of {x.n}: not shown to be within them")
            return Slice(x.base, x.off + a, b - a)
        return ode.part(x, a if isinstance(a, int) else self.plain(a), b if isinstance(b, int) else self.plain(b))
    def concat(self, x, y):
        if isinstance(x, Stack):
            if not isinstance(y, list) or len(y) != 1: raise Err("a stack takes one value at a time")
            return x.put(self.T, self.facts, x.count, [w.v for w in y[0]], x.count + 1)
        if not isinstance(x, list) or not isinstance(y, list): raise Err("++ of things that are not plain lists")
        return x + y
    def put(self, xs, i, v):
        if isinstance(xs, Arr):
            if not isinstance(v, list) or len(v) != 8 or not all(isinstance(w, Word) for w in v): raise Err("an array of chaining values takes a chaining value")
            return xs.put(self.T, self.facts, i, [w.v for w in v])
        if not isinstance(xs, list): raise Err("a place of something that is not a list")
        i = i if isinstance(i, int) else self.plain(i)
        if not 0 <= i < len(xs): raise Err(f"place {i} of a list of {len(xs)}")
        xs = list(xs); xs[i] = v
        return xs
    def words(self, bs):
        """Every four bytes a word, the lowest byte first."""
        T = self.T
        if isinstance(bs, Slice):
            n = self.plain(bs.n)
            if n % 4: raise Err("words of bytes that are not four to a word")
            return [Word(T.var("mw", bs.base, plain(bs.off + 4 * j))) for j in range(n // 4)]
        if isinstance(bs, Named):
            if bs.n % 4: raise Err("words of bytes that are not four to a word")
            return [Word(T.mk("word of", bs.key(), j)) for j in range(bs.n // 4)]
        if not isinstance(bs, list) or len(bs) % 4: raise Err("words of something that is not bytes, four to a word")
        return [Word(word_of_bytes(T, bs[i:i + 4])) for i in range(0, len(bs), 4)]
    def nothing(self, n): return Arr(None, n)

    # -- what could not be evaluated
    def key(self, v):
        if isinstance(v, Word): return ("word", v.v)
        if isinstance(v, ByteT): return ("byte", v.v)
        if isinstance(v, Counter): return ("counter", v.lo.v, v.hi.v)
        if isinstance(v, list): return tuple(self.key(x) for x in v)
        if isinstance(v, dict): return ("record",) + tuple((name, self.key(x)) for name, x in sorted(v.items()))
        if isinstance(v, Stack): return v.key(self.T, self.facts)
        if isinstance(v, (Arr, Slice, Named)): return v.key()
        if isinstance(v, Blocks): return ("blocks", v.lane)
        if v is None: return None
        if isinstance(v, bool): raise Err("a truth where a value is expected")
        return Lin.of(v)

    def machine_result(self, spec, name, m, env):
        """A machine called. If the verifier is at a place of this very machine, its state there. If it can be
        run, it is. Else its result is named by the machine and everything it was given, in the shape of its
        first state. (In the machine's own function the code is checked against it turn by turn.)"""
        state = env[m["states"][0]]
        if m["state"] is not None and isinstance(state, Stack):
            if not state.count.c: return spec.run_machine(self, m, env)
            named = self.T.mk("machine", name, *(self.key(env[p]) for p in m["params"]), state.key(self.T, self.facts))
            count = sym(f"count of {name} {named}")
            self.facts.add(count)
            return Stack((name, named), count)
        first = spec.state_of(m, env)
        instance = (name, tuple(self.key(env[p]) for p in m["params"]), self.key(first))
        if instance in self.ghost: return self.ghost[instance]
        if instance in self.memo: return self.memo[instance]
        try:
            result = spec.run_machine(self, m, dict(env))
        except Err:
            self.unrun.append((instance, first, {p: env[p] for p in m["params"]}))
            named = self.like(first, f"{name}#{self.T.mk('machine', *instance)}")
            if m["loop"][0] == "for":
                # the state's shape must be shown to stay over a turn: the name says the result is of the shape
                # of the first state, and a sequence whose value grows each turn would be named too small
                # (November 17, 2026: `h[0] = [0]  h[b + 1] = h[b] ++ [0]` was taken for a list of one)
                try:
                    env2 = dict(env)
                    env2[m["states"][0]] = named
                    env2[m["loop"][1]] = plain(sym(f"{name} turn"))
                    after = spec.turn(self, name, env2)
                    if self.shape(after) != self.shape(first):
                        raise Err(f"the state of {name} is not shown to stay of one shape over a turn: its value cannot be named here")
                except Err as e:
                    raise Err(f"{name} cannot be run here, and its turn cannot be followed on names: {e}")
            result = named
        self.memo[instance] = result
        return result

    def shape(self, v):
        """The shape of a value, leaves aside: what two values of the same shape are."""
        if isinstance(v, Word): return "w"
        if isinstance(v, bool): return "b"
        if isinstance(v, (int, Lin)): return "n"
        if isinstance(v, list): return tuple(self.shape(x) for x in v)
        if isinstance(v, dict): return tuple((k, self.shape(x)) for k, x in sorted(v.items()))
        if isinstance(v, Counter): return ("counter", self.shape(v.lo), self.shape(v.hi))
        return ("?", type(v).__name__)

    def kept(self, name, args, body):
        """A definition applied to plain words (and plain numbers) only: what it gives does not depend on
        the path, and is kept with the terms."""
        if not all(plain_words(a) for a in args): return body()
        if not hasattr(self.T, "kept"): self.T.kept = {}
        k = (name, tuple(self.key(a) for a in args))
        if k not in self.T.kept: self.T.kept[k] = body()
        return self.T.kept[k]

    def known(self, instance):
        """What was named or evaluated on this path for this application: by what it was given, as the path's
        facts now have the numbers in it (a length the path has since fixed is that number)."""
        if instance in self.memo: return self.memo[instance]
        want = self.settled(instance)
        for k, v in self.memo.items():
            if isinstance(k, tuple) and k and k[0] == instance[0] and self.settled(k) == want: return v
        return None

    def settled(self, k):
        if isinstance(k, Lin): return self.facts.subst(k)
        if isinstance(k, tuple): return tuple(self.settled(x) for x in k)
        return k

    def like(self, v, name):
        """A value of the shape of v, of which only its name is known."""
        if isinstance(v, (int, Lin)) and not isinstance(v, bool):
            x = sym(name); self.facts.add(x)
            return x
        if isinstance(v, Word): return Word(self.T.mk("part", name))
        if isinstance(v, list): return [self.like(x, f"{name}.{i}") for i, x in enumerate(v)]
        if isinstance(v, dict): return {k: self.like(x, f"{name}.{k}") for k, x in v.items()}
        if isinstance(v, Arr): return Arr(name, v.size)
        raise Err("a machine's state of a shape that cannot be named")

    def named(self, spec, name, kind, args, body):
        """A function with a kind: evaluated if it can be, else a value of the kind named by what it was given."""
        instance = (name, tuple(self.key(a) for a in args))
        known = self.known(instance)
        if known is not None: return known
        if instance in getattr(self.T, "kept", ()):
            result = self.memo[instance] = self.T.kept[instance]
            return result
        if self.fold and self.depth == 0:
            # a call is taken by the callee's contract as it is written: what it leaves is not opened here.
            # (The caller's own specification, opened later on the same path, finds this name for the same
            # application.)
            result = self.memo[instance] = self.of_kind(spec, kind, f"{name}#{self.T.mk('named', *instance)}")
            return result
        outer, asked = spec.fuel, self.facts.asked
        if outer is None: spec.fuel = FUEL
        self.depth += 1
        try:
            result = body()
            if self.facts.asked == asked:
                # worked out without asking anything of the path's facts: the same on every path
                if not hasattr(self.T, "kept"): self.T.kept = {}
                self.T.kept[instance] = result
        except Err:
            result = self.of_kind(spec, kind, f"{name}#{self.T.mk('named', *instance)}")
        finally:
            self.depth -= 1
            if outer is None: spec.fuel = None
        self.memo[instance] = result
        return result

    def of_kind(self, spec, kind, name):
        """A value of a kind (a layout's record, a chaining value, bytes, a number, a flags byte), of which only
        its name is known; a number or a byte is within what its kind says."""
        parts = kind.split()
        if kind == "cv": return [Word(self.T.mk("part", name, w)) for w in range(8)]
        if len(parts) == 2 and parts[1] == "bytes" and parts[0].isdigit(): return Named(name, int(parts[0]))
        if kind == "number":
            x = sym(name); self.facts.add(x)
            return x
        if kind == "byte": return Word(byte_term(self.T, (0, (name,))))
        if kind in spec.layouts:
            out = {}
            for field, f in spec.layouts[kind]["fields"].items():
                if f["count"] is not None:
                    if f["kind"] != "cv": raise Err("an array that is not of chaining values")
                    out[field] = Arr(f"{name}.{field}", f["count"])
                else:
                    out[field] = self.of_kind(spec, f["kind"], f"{name}.{field}")
                    if f["below"] is not None: self.facts.add(f["below"] - 1 - out[field])
            return out
        raise Err(f"no kind {kind}")


def plain_words(v):
    """Words, a counter of words, plain numbers, or lists of them: nothing a path's facts could bear on."""
    if isinstance(v, bool): return False
    if isinstance(v, (Word, int)): return True
    if isinstance(v, Counter): return not isinstance(getattr(v, "n", 0), Lin)
    if isinstance(v, list): return all(plain_words(x) for x in v)
    return False


def fits(obj, start, symbol=None):
    """The instructions of the function at `start` are of kinds its contract says it needs (`needs F`, with
    no condition): a function that does not say it needs AVX-512 holds no instruction of that kind. (A machine
    with AVX-512 has AVX and SSE4.1; one with AVX has SSE4.1.) `symbol`: the contract's, where the function is
    entered at another symbol than where its code begins."""
    import kdecode
    c = SPEC.contracts.get(symbol or start)
    have = {f for f, cond in (c["needs"] if c else []) if cond is None}
    if "avx512" in have: have |= {"avx", "sse41"}
    if "avx" in have: have.add("sse41")
    extra = kdecode.features(obj, start) - have
    if extra: raise Err(f"{symbol or start} holds instructions of a kind its contract does not say it needs: {', '.join(sorted(extra))}")


def halved(facts, x, d):
    """x / d for d a power of two (rounded down): exact where x's parts all divide, else a symbol q with
    d*q <= x <= d*q + d - 1. The code's shifts and the specification's divisions make the same symbol."""
    d = ode.Spec.number(d)
    if d < 2 or d & (d - 1): raise Err(f"a division by {d}: not a power of two")
    x = Lin.of(x)
    if not x.c: return x.k // d
    exact = x.over(d)
    if exact is not None: return exact
    if not facts.ge0(x): raise Err(f"{x} is divided, and is not shown to be a number not below zero")
    name = f"({x!r})/{d}"
    q = sym(name)
    if d == 2: HALVES[name] = x
    facts.add(q); facts.add(x - q.scale(d)); facts.add(q.scale(d) + d - 1 - x)
    return q


def word_of_bytes(T, four):
    """Four bytes (numbers, or bytes of a message) as a word, the lowest first."""
    if all(isinstance(b, int) and not isinstance(b, bool) and 0 <= b < 256 for b in four): return T.const(four[0] | four[1] << 8 | four[2] << 16 | four[3] << 24)
    if not all(isinstance(b, ByteT) or (isinstance(b, int) and not isinstance(b, bool) and 0 <= b < 256) for b in four): raise Err("a word of things that are not bytes")
    nodes = [T.nodes[b.v] if isinstance(b, ByteT) else None for b in four]
    if all(n is not None and n[0] == "v" and n[1] == "byte" for n in nodes):
        base, first = nodes[0][2], Lin.of(nodes[0][3])
        if all(n[2] == base and Lin.of(n[3]) == first + i for i, n in enumerate(nodes)): return T.var("mw", base, plain(first))         # four bytes of a message as they lie: its word there
    return T.mk("word of bytes", *(b.v if isinstance(b, ByteT) else ("c", b) for b in four))


def same(A, v, w):
    """Are two values of the specification one? (Numbers by the path's facts; arrays place by place.)"""
    if isinstance(v, (int, Lin)) and isinstance(w, (int, Lin)) and not isinstance(v, bool) and not isinstance(w, bool): return A.facts.zero(Lin.of(v) - Lin.of(w)) is True
    if isinstance(v, Word) and isinstance(w, Word): return v.v == w.v
    if isinstance(v, ByteT) and isinstance(w, ByteT): return v.v == w.v
    if isinstance(v, list) and isinstance(w, list): return len(v) == len(w) and all(same(A, x, y) for x, y in zip(v, w))
    if isinstance(v, dict) and isinstance(w, dict): return v.keys() == w.keys() and all(same(A, v[k], w[k]) for k in v)
    if isinstance(v, Arr) and isinstance(w, Arr): return v.same(A.T, A.facts, w)
    if isinstance(v, Stack) and isinstance(w, Stack): return v.same(A.T, A.facts, w)
    if isinstance(v, (Slice, Named)) and type(v) is type(w): return v.key() == w.key()
    return False


def asked(contract, A, env):
    """What a contract asks, as numbers the caller must show are not below zero."""
    out = []
    for e in contract["asks"]:
        if e[0] != "bin" or e[1] not in (">=", "<=", ">", "<"): raise Err("a contract asks something that is not an order of two numbers")
        x, y = Lin.of(SPEC.eval(A, e[2], env)), Lin.of(SPEC.eval(A, e[3], env))
        out.append({">=": x - y, "<=": y - x, ">": x - y - 1, "<": y - x - 1}[e[1]])
    return out


def as_words(c, spec):
    """A contract that speaks of the 32 bytes at an address as words, read as one of eight words there.

    `words(X)` is every four bytes a word, the lowest byte first; `ensures X = bytes_of(E)` says the bytes at X are
    those of the words E, each word's lowest byte first. That is how this machine reads and writes a word in
    memory, and it is all the kind `cv` is: eight words at an address. So where X is `32 bytes` and the contract
    uses it in those two ways only, X is taken as a `cv`, `words(X)` as its words, and what it ensures as the
    words E. Used any other way (a byte of it, its length), it stays bytes, and a contract that mixes the two is
    refused. `words` and `bytes_of` must be the language's own: a specification that defines either is refused."""
    if c is None: return c
    wide = [name for name, kind in c["args"] if kind == "32 bytes"]
    if not wide: return c
    as_word = lambda e, x: isinstance(e, tuple) and e == ("call", "words", [("name", x)])
    def count(e, x):
        """(times x is used as words(x), times it is used otherwise)"""
        if as_word(e, x): return 1, 0
        if e == ("name", x): return 0, 1
        w = b = 0
        for part in (e.values() if isinstance(e, dict) else e if isinstance(e, (tuple, list)) else ()):
            dw, db = count(part, x); w, b = w + dw, b + db
        return w, b
    def rewrite(e, x):
        if as_word(e, x): return ("name", x)
        if isinstance(e, tuple): return tuple(rewrite(p, x) for p in e)
        if isinstance(e, list): return [rewrite(p, x) for p in e]
        if isinstance(e, dict): return {k: rewrite(v, x) for k, v in e.items()}
        return e
    for x in wide:
        rest = {k: v for k, v in c.items() if k not in ("args", "leaves")}
        ensured = [leaf for leaf in c["leaves"] if leaf["name"] == x]
        others = [leaf for leaf in c["leaves"] if leaf["name"] != x]
        of_words = [leaf for leaf in ensured if leaf["expr"][0] == "call" and leaf["expr"][1] == "bytes_of" and len(leaf["expr"][2]) == 1
                    and leaf.get("part") is None and leaf.get("index") is None]
        w, b = count([rest, others, [leaf["expr"] for leaf in ensured]], x)
        if not w and not of_words: continue                                       # bytes, as written
        if b or len(of_words) != len(ensured): raise Err(f"the contract speaks of {x} both as bytes and as words: not this verifier's")
        if "words" in spec.fns or "bytes_of" in spec.fns: raise Err("the specification defines `words` or `bytes_of`: they are the language's own, and a contract's bytes are read by them")
        c = rewrite(c, x)
        c["args"] = [(name, "cv" if name == x else kind) for name, kind in c["args"]]
        c["leaves"] = [dict(leaf, expr=leaf["expr"][2][0]) if leaf["name"] == x else leaf for leaf in c["leaves"]]
    return c


def words(terms): return [Word(t) for t in terms]
def terms(ws): return tuple(w.v for w in ws)
