"""varith: the verifier's arithmetic. A proof that some whole numbers cannot all be >= 0, verified by adding up.

A row is a sum of whole multiples of names plus a whole number, said to be >= 0:  ({name: multiple}, number).
A proof is the rows it starts from, then steps. Each row it starts from must be one of the rows given. A step
(i, a, j, b), a and b whole numbers above zero, makes the row

    a * row[i] + b * row[j],  divided by the greatest number that divides all its multiples,
                              its plain number rounded down       (the names stand for whole numbers)

The last row must have no name left and a number below zero: the rows given cannot all hold.

Nothing here searches. Which rows, which steps: a prover found them (kprove.py), and is trusted for nothing:
a proof that does not add up shows nothing. A table of proofs is what a binary carries for a function
(`FUNCTION.arith.z` in its proof section): {the last row given: the proofs for questions that end in it}.
klin.py asks it in place of its own elimination when `klin.Facts.PROOFS` is set."""
import json, zlib
from math import gcd


def combine(p, a, q, b):
    c = {}
    for row, m in ((p, a), (q, b)):
        for name, mult in row[0].items(): c[name] = c.get(name, 0) + m * mult
    c = {n: v for n, v in c.items() if v}
    k = a * p[1] + b * q[1]
    g = 0
    for v in c.values(): g = gcd(g, abs(v))
    if g > 1: c, k = {n: v // g for n, v in c.items()}, k // g
    return c, k


def key(row): return (tuple(sorted(row[0].items())), row[1])


def refutes(given, proof):
    """given: the keys of the rows that are known. True only if the proof shows they cannot all hold."""
    starts, steps = proof
    rows = []
    for r in starts:
        if key(r) not in given: return False
        rows.append(r)
    for i, a, j, b in steps:
        if not (isinstance(a, int) and isinstance(b, int) and a > 0 and b > 0 and 0 <= i < len(rows) and 0 <= j < len(rows)): return False
        rows.append(combine(rows[i], a, rows[j], b))
    return bool(rows) and not rows[-1][0] and rows[-1][1] < 0


def shown(table, rows):
    """Can `rows` (each ({name: multiple}, number), known to be >= 0) not all hold, by a proof of the table?"""
    for c, k in rows:
        if not c and k < 0: return True
    if not rows: return False
    proofs = table.get(key(rows[-1]))
    if not proofs: return False
    given = {key(r) for r in rows}
    return any(refutes(given, p) for p in proofs)


# -- a table as bytes: names once, rows as numbers
def pack(table):
    names, index, out = [], {}, []
    def row(r):
        flat = []
        for n, m in sorted(r[0].items()):
            if n not in index: index[n] = len(names); names.append(n)
            flat += [index[n], m]
        return [flat, r[1]]
    for proofs in table.values():
        for starts, steps in proofs: out.append([[row(r) for r in starts], [list(s) for s in steps]])
    return zlib.compress(json.dumps({"names": names, "proofs": out}, separators=(",", ":")).encode(), 9)


def unpack(blob):
    """The table a binary carries. The last row a proof starts from is the one its questions end in. (Whatever
    the bytes are, a table read from them can only answer by `refutes`.)"""
    whole = lambda v: isinstance(v, int) and not isinstance(v, bool)
    try:
        d = json.loads(zlib.decompress(blob))
        names, table = d["names"], {}
        if not all(isinstance(n, str) for n in names): raise ValueError
        def row(r):
            flat, k = r
            if not whole(k) or len(flat) % 2 or not all(whole(v) for v in flat) or any(not 0 <= flat[i] < len(names) for i in range(0, len(flat), 2)): raise ValueError
            return {names[flat[i]]: flat[i + 1] for i in range(0, len(flat), 2)}, k
        for starts, steps in d["proofs"]:
            starts = [row(r) for r in starts]
            if any(len(s) != 4 or not all(whole(v) for v in s) for s in steps): raise ValueError
            if starts: table.setdefault(key(starts[-1]), []).append((starts, [tuple(s) for s in steps]))
    except Exception: raise ValueError("not a table of proofs of arithmetic")       # (zlib's and JSON's own errors among them)
    return table
