"""klin: whole numbers that depend on counts (c + c1*x1 + c2*x2 ...), and what is known of them.

Used by the checkers (kloop.py, kglue.py) and by the specification read on symbols (kspec.py). No solver:
a fact is a number known not to be below zero, and a question is answered by adding one or two facts up."""
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


