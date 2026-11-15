"""klin: whole numbers that depend on counts (c + c1*x1 + c2*x2 ...), and what is known of them.

Used by the checkers (kloop.py, kglue.py, kfn.py) and by the specification read on symbols (kspec.py). No
solver in the usual sense: a fact is a number known not to be below zero. A fact that is known both ways is
an equality, and is used by putting one of its symbols in terms of the others. A question (is this number not
below zero?) is answered by adding known facts up: first one or two of them, then, if that does not do, by
eliminating the symbols one after another from the facts and the question's denial (Fourier and Motzkin's
way, in whole numbers: a fact's constant is rounded down when its coefficients have a common divisor). An
answer of "no" means "not shown".

`below`: a number x known to be below 2^k, where k too depends on counts (a loop that halves x as it climbs
k levels). From x >= 1 it gives k >= 1, and from x >= 2, k >= 2."""
import math


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
    def __rsub__(self, o): return Lin.of(o) - self
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


def sym(name): return Lin([(name, 1)])


class Facts:
    """Numbers known to be >= 0, numbers known not to be 0, symbols known in terms of others. Whole numbers."""
    def __init__(self): self.ge, self.ne, self.eq, self.below, self.bad, self.memo, self.asked = [], [], {}, [], False, {}, 0
    def clone(self):
        f = Facts(); f.ge, f.ne, f.eq, f.below, f.bad, f.memo, f.asked = list(self.ge), list(self.ne), dict(self.eq), list(self.below), self.bad, dict(self.memo), self.asked
        return f
    @staticmethod
    def norm(f):
        g = 0
        for _, a in f.c: g = math.gcd(g, abs(a))
        return f if g <= 1 else Lin(((s, a // g) for s, a in f.c), f.k // g)        # whole numbers: the constant rounds down

    def subst(self, x):
        """x with every symbol that is known in terms of others replaced."""
        x = Lin.of(x)
        if x.c: self.asked += 1                 # something was asked of the facts (kspec.py: what is worked out without asking does not depend on the path)
        if not self.eq: return x
        while True:
            hit = next((s for s, _ in x.c if s in self.eq), None)
            if hit is None: return x
            x = x.at(hit, self.eq[hit])

    # -- questions
    def ge0(self, goal):
        """Is goal >= 0 shown by the facts?"""
        goal = self.subst(goal)
        if not goal.c: return goal.k >= 0
        if self.bad: return True                                    # facts that cannot all hold show anything: such a path is no path
        goal = self.norm(goal)
        if goal in self.memo: return self.memo[goal]
        answer = self.quick(goal) or self.eliminate(self.ge + self.from_below() + [self.norm(-goal - 1)])
        self.memo[goal] = answer
        return answer

    def quick(self, goal):
        for f in self.ge:
            if f.c == goal.c and goal.k >= f.k: return True
        return False

    def from_below(self):
        """What the `below` facts give: x < 2^k and x >= 2^j show k >= j + 1."""
        if "from below" in self.memo: return self.memo["from below"]
        out = []
        for x, k in self.below:
            x, k = self.subst(x), self.subst(k)
            for j in (1, 0):
                need = self.norm(x - (1 << j))
                if (not need.c and need.k >= 0) or (need.c and (self.quick(need) or self.eliminate(self.ge + [self.norm(-need - 1)]))):
                    out.append(self.norm(k - (j + 1))); break
        self.memo["from below"] = [f for f in out if f.c]
        return self.memo["from below"]

    @staticmethod
    def eliminate(system, limit=600):
        """Can the numbers in `system` not all be >= 0? Symbols are eliminated one after another; a constant
        below zero left over says so."""
        rows = set()
        for f in system:
            if not f.c:
                if f.k < 0: return True
            else: rows.add(f)
        while rows:
            count = {}
            for f in rows:
                for s, a in f.c:
                    p = count.setdefault(s, [0, 0]); p[0 if a > 0 else 1] += 1
            s = min(count, key=lambda s: count[s][0] * count[s][1])
            pos = [f for f in rows if dict(f.c).get(s, 0) > 0]
            neg = [f for f in rows if dict(f.c).get(s, 0) < 0]
            rows = {f for f in rows if s not in dict(f.c)}
            if len(rows) + len(pos) * len(neg) > limit: return False
            for p in pos:
                a = dict(p.c)[s]
                for n in neg:
                    b = -dict(n.c)[s]
                    g = math.gcd(a, b)
                    r = Facts.norm(p.scale(b // g) + n.scale(a // g))
                    if not r.c:
                        if r.k < 0: return True
                    else: rows.add(r)
        return False

    def consistent(self):
        """False: the facts cannot all hold (a path that assumes them is taken by no run)."""
        if self.bad: return False
        if "consistent" not in self.memo: self.memo["consistent"] = not self.eliminate(self.ge + self.from_below())
        return self.memo["consistent"]

    def zero(self, x):
        """True: x is 0. False: it is not. None: the facts do not say."""
        x = self.subst(x)
        if not x.c: return x.k == 0
        if any(x == y or x == -y for y in (self.subst(y) for y in self.ne)): return False
        if self.ge0(x - 1) or self.ge0(-x - 1): return False
        if self.ge0(x) and self.ge0(-x): return True
        return None

    def number(self, x):
        """x as a plain number, if the facts fix it; else None."""
        x = self.subst(x)
        return x.k if not x.c else None

    # -- new facts
    def add(self, f):
        self.asked += 1
        f = self.norm(self.subst(f))
        if not f.c:
            if f.k < 0: self.bad = True
            return
        if f in self.ge: return
        self.memo = {}
        if self.quick(self.norm(-f)) or self.eliminate(self.ge + [self.norm(f - 1)]):          # -f >= 0 is known too: f is 0
            self.equal(f); return
        self.ge.append(f)
        for g in list(self.ge):                                                                # does it make an older fact an equality?
            if g is not f and g in self.ge and g.c == (-f).c and self.eliminate(self.ge + [self.norm(g - 1)]): self.equal(g)

    def equal(self, f):
        """f is 0: one of its symbols (one that f holds once) is put in terms of the others, everywhere."""
        s = next((s for s, a in f.c if abs(a) == 1), None)
        if s is None:
            for g in (f, self.norm(-f)):
                if g not in self.ge: self.ge.append(g)
            return
        a = dict(f.c)[s]
        self.eq = {t: v.at(s, (f - sym(s).scale(a)).scale(-a)) for t, v in self.eq.items()}
        self.eq[s] = (f - sym(s).scale(a)).scale(-a)
        old, self.ge, self.memo = self.ge, [], {}
        for g in old: self.add(g)

    def assume_zero(self, x):
        x = self.norm(self.subst(x))
        if not x.c:
            if x.k != 0: self.bad = True
            return
        self.memo = {}
        self.equal(x)
        if any(not y.c and y.k == 0 for y in (self.subst(y) for y in self.ne)): self.bad = True

    def assume_nonzero(self, x):
        x = self.subst(x)
        if not x.c:
            if x.k == 0: self.bad = True
            return
        if self.ge0(x): self.add(x - 1)
        elif self.ge0(-x): self.add(-x - 1)
        else: self.ne.append(x)

    def assume_below(self, x, k):
        """x < 2^k."""
        self.memo = {}; self.below.append((Lin.of(x), Lin.of(k)))

    def shows_below(self, x, k, halves=None):
        """Is x < 2^k shown? By a known such fact, by one for the number x is half of (`halves`: x's symbol ->
        the number it is half of), or by x <= 2^k - 1 where k is a plain number."""
        raw, x, k = Lin.of(x), self.subst(x), self.subst(k)
        if not x.c and x.k >= 0 and self.ge0(k - x.k.bit_length()): return True               # a plain number: below 2^(its length in bits)
        if not k.c and 0 <= k.k < 200 and self.ge0((1 << k.k) - 1 - x): return True
        half_of = halves.get(raw.c[0][0]) if halves is not None and len(raw.c) == 1 and raw.k == 0 and raw.c[0][1] == 1 else None
        for y, j in self.below:
            y, j = self.subst(y), self.subst(j)
            if x == y and self.ge0(k - j): return True
            # x is y >> 1 and y < 2^j: x < 2^(j-1)
            if half_of is not None and self.subst(half_of) == y and self.ge0(k - (j - 1)): return True
        return False
