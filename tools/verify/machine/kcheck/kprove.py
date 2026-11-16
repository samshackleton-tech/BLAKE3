"""kprove: the prover's side of the arithmetic. Trusted for nothing: varith.py verifies what it writes.

`search` and `bounds` answer "can these whole numbers not all be >= 0?" by elimination and by the bounds of
the names: the search itself. klin.py calls them only where it is given no table of proofs.

klin.py's elimination, remembering how each row was made, so that when it comes to a contradiction the few
rows and steps that led there can be written out (`derive`). `Recorder` sits in klin.Facts.RECORD while a
function is verified the old way (with the search), and keeps a proof of every answer "shown"; `prove` runs a
verification so, then again with no search and only the proofs, until the second way asks nothing the table
cannot answer."""
import math, random
import klin, varith
from klin import Facts


# -- the search (it was klin.py's until November 16, 2026: a verifier that is given proofs does not load this file)
def search(system, limit=600, last=frozenset()):
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
        s = min(count, key=lambda s: (s in last, count[s][0] * count[s][1]))
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


def bounds(system, rounds=12):
    """Can the numbers in `system` not all be >= 0, by the bounds of their symbols alone?"""
    lo, hi = {}, {}
    for _ in range(rounds):
        changed = False
        for f in system:
            for s, a in f.c:
                # a * s >= -(the rest), and the rest is at most `most`
                most = f.k
                for t, b in f.c:
                    if t == s: continue
                    bound = hi.get(t) if b > 0 else lo.get(t)
                    if bound is None: most = None; break
                    most += b * bound
                if most is None: continue
                if a > 0:
                    least = -(most // a)                        # s >= -most / a, rounded up
                    if s not in lo or least > lo[s]: lo[s] = least; changed = True
                else:
                    greatest = most // -a                       # s <= most / -a, rounded down
                    if s not in hi or greatest < hi[s]: hi[s] = greatest; changed = True
                if s in lo and s in hi and lo[s] > hi[s]: return True
        if not changed: return False
    return False


def row(f): return (dict(f.c), f.k)


def derive(system, limit=30000, last=frozenset(), order=None):
    """A proof (rows to start from, steps) that `system` cannot hold, the goal's row last among the starts; or None."""
    how, rows = {}, set()                     # row -> None (given) or (p, a, n, b)
    def done(final):
        index = {}
        def visit(f):
            if f in index: return
            h = how[f]
            if h is not None: visit(h[0]); visit(h[2])
            index[f] = None
        visit(final)
        used = list(index)
        starts = [f for f in used if how[f] is None]
        if system and system[-1] in starts: starts.remove(system[-1])
        if system: starts.append(system[-1])                      # the table's key: the last row given, used or not
        for k, f in enumerate(starts): index[f] = k
        steps = []
        for f in used:
            if how[f] is not None:
                p, a, q, b = how[f]; index[f] = len(starts) + len(steps); steps.append((index[p], a, index[q], b))
        if how[final] is None and (final.c or final.k >= 0): return None
        if how[final] is None:                                    # a row given that is itself a number below zero
            k = starts.index(final); steps.append((k, 1, k, 1))
        return [row(f) for f in starts], steps
    for f in system:
        how.setdefault(f, None)
        if not f.c:
            if f.k < 0: return done(f)
        else: rows.add(f)
    while rows:
        count = {}
        for f in rows:
            for s, a in f.c:
                p = count.setdefault(s, [0, 0]); p[0 if a > 0 else 1] += 1
        s = min(count, key=(lambda s: (s in last, count[s][0] * count[s][1], s)) if order is None else order)
        pos = [f for f in rows if dict(f.c).get(s, 0) > 0]
        neg = [f for f in rows if dict(f.c).get(s, 0) < 0]
        rows = {f for f in rows if s not in dict(f.c)}
        if len(rows) + len(pos) * len(neg) > limit: return None
        for p in pos:
            a = dict(p.c)[s]
            for n in neg:
                b = -dict(n.c)[s]
                g = math.gcd(a, b)
                r = Facts.norm(p.scale(b // g) + n.scale(a // g))
                if r not in how: how[r] = (p, b // g, n, a // g)
                if not r.c:
                    if r.k < 0: return done(r)
                else: rows.add(r)
    return None


def find(system, oracle, last=frozenset()):
    """A proof for a system the oracle (the search that said "shown") said cannot hold; None if none is found."""
    p = derive(system, 600, last) or derive(system, 30000, last)
    if p is not None: return p
    keep, k = list(system[:-1]), 0                                # fewer rows, by the oracle: then other orders
    while k < len(keep):
        trial = keep[:k] + keep[k + 1:]
        if oracle(trial + system[-1:]): keep = trial
        else: k += 1
    small, rnd = keep + list(system[-1:]), random.Random(1)
    for _ in range(40):
        w = {}
        p = derive(small, 200000, order=lambda s: w.setdefault(s, rnd.random()))
        if p is not None: return p
    return None


class Recorder:
    def __init__(self, table=None): self.table, self.shown, self.unproved = table if table is not None else {}, 0, 0
    def __call__(self, system, oracle, last=frozenset()):
        self.shown += 1
        if not system: return
        rows = [row(f) for f in system]
        if varith.shown(self.table, rows): return                 # a proof kept already answers it
        p = find(system, oracle, last)
        if p is None: self.unproved += 1; return
        assert varith.refutes({varith.key(r) for r in rows}, p), "a proof the prover wrote does not add up"
        self.table.setdefault(varith.key(rows[-1]), []).append(p)


def prove(run, rounds=4):
    """run(): verifies something (raises if it is not shown). Returns the table of arithmetic proofs with which
    it is shown with no search at all. (The second way may ask what the first did not: an answer a proof gives
    where the search gave up changes what is asked next. So it is run with the search behind it, until it
    asks nothing new.)"""
    rec = Recorder()
    before = (Facts.PROOFS, Facts.RECORD, Facts.MISS)
    try:
        Facts.PROOFS, Facts.RECORD, Facts.MISS = None, rec, None
        run()
        for _ in range(rounds):
            missed = [0]
            def miss(system, limit, last):
                r = Facts.search(system, limit, last) if limit is not None else Facts.bounds(system) or Facts.search(system, klin.AGAIN)
                if r:
                    n = sum(len(v) for v in rec.table.values())
                    rec(system, (lambda s: Facts.search(s, limit, last)) if limit is not None else (lambda s: Facts.bounds(s) or Facts.search(s, klin.AGAIN)), last)
                    if sum(len(v) for v in rec.table.values()) > n: missed[0] += 1
                    return varith.shown(rec.table, [row(f) for f in system])
                return False
            Facts.PROOFS, Facts.RECORD, Facts.MISS = rec.table, None, miss
            run()
            if not missed[0]: break
        Facts.PROOFS, Facts.RECORD, Facts.MISS = rec.table, None, None
        run()                                                     # with the proofs alone
    finally:
        Facts.PROOFS, Facts.RECORD, Facts.MISS = before
    return rec.table
