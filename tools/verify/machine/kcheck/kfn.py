#!/usr/bin/env python3
"""kfn: a function of compiled code against its contract. Records and arrays in memory, bytes of a message of
any length, calls by contract (a call of itself by its own).

    python3 kfn.py NAME OBJECT            the checker

The third trial of the way of kloop.py and kglue.py (November 15, 2026): BLAKE3's hash of a message as the Ode
compiler and the assembler leave it (hash.ode, x86-64): `pad`, `chunk_node`, `node_out`, `subtree`, `hashr`.

WHAT IS CLAIMED OF A FUNCTION is its `contract` (blake3.spec for the function a user calls; proofs/inner.spec
for the functions inside): what each argument is (a number, a flags byte, or the address of a chaining value,
of some bytes, or of a record whose `layout` is given), what the caller must show (`asks`), what the memory
named holds afterwards (`leaves`, in the specification's definitions), what is returned, how much stack it
may use, which function it calls only on a condition. Everything it does not name is as it was.

THE CHECKER runs the code on symbols from its entry, forward along every path, to the return:
  - a branch on something the path does not fix splits the path, and each side takes the fact with it; a
    path whose facts cannot all hold is dropped;
  - a loop is run: every loop of this code turns a number of times its path fixes (a chunk's 16 blocks, a
    block's 64 bytes, the 54 doublings of a count of chunks). A loop that turns more than 100 times on a path
    is refused;
  - at a call: the callee's contract. What it asks is shown from the caller's facts; what it leaves replaces
    what was there; the registers a call may change are forgotten. A function that calls itself is taken by
    its own contract (so what is shown is what holds if it returns; the stack it may use bounds how deep);
  - at the return: each thing the contract says is left is the specification's value of it, evaluated on the
    same path (where the specification asks how two numbers compare, the path must have asked too); the
    result, the registers a callee keeps, the stack pointer, and the stack used.
There is no proof text: the binary, the specification and the contracts are all the checker is given.

No solver: terms are compared by identity, numbers by adding linear facts up (klin.py). What the
specification's definitions give that cannot be worked out on a path (the tree over bytes whose count the
path does not fix) is named by what it is of, and two names are one thing when they are the same (kspec.py).
What a callee leaves is so named, not opened.

(An earlier state of this file also took a loop whose count is not fixed, by a PLACE: a machine of the
specification, and what the registers and the memory hold for any state of it. It checked the code's
earlier form so, a stack of levels with a loop over them. The hash was then written as the specification's
own recursion, no loop needed a place, and that part was taken out.)

WHAT IS NOT CHECKED HERE: this checker (Python, unverified: its audits are its worth)."""
import copy, itertools, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode, kspec, ode, kone
from kcheck import Fail, num, signed
from klin import Lin, Facts, sym
from kloop import value, lin
from kspec import Arr, ByteT, Slice, Named, plain, byte_or, byte_term, term_byte, halved
from ode import Word, Err

BASE, DATA = 0x10000, 0x50000000
G64 = kcheck.G64
KEPT = kcheck.SAVED                 # the registers a callee keeps
ARGS = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
WORD64 = (1 << 64) - 1
STEPS = 400000                      # instructions run before a check gives up
TURNS = 100                         # times a path may jump back to one instruction before it is given up
MISSING = object()
FRESH = itertools.count()           # for the names of things of which nothing is known


# ---------------------------------------------------------------------------------------------------------
# Kinds: how a value lies in memory.
def bytes_kind(kind):
    """`64 bytes`, `len bytes`: the count (a number, or the name of an argument); None for other kinds."""
    p = kind.split()
    return (int(p[0]) if p[0].isdigit() else p[0]) if len(p) == 2 and p[1] == "bytes" else None


def lanes_kind(kind, what):
    """`32 inputs`, `16 cvs`: the count; None for other kinds."""
    p = kind.split()
    return int(p[0]) if len(p) == 2 and p[1] == what and p[0].isdigit() else None


class Given:
    """Chaining values at an address, of which a contract says what each IS: `asks NAME[i] == E for i in a..b`."""
    def __init__(self, clause, env): self.clause, self.env = clause, env
    def get(self, m, i):
        """The i-th, in the specification's terms, on the path of the machine m (which shows i within a..b)."""
        A, i = m.A(), Lin.of(i)
        a, b = (Lin.of(kspec.SPEC.eval(A, e, self.env)) for e in self.clause["each"])
        if not m.facts.ge0(i - a) or not m.facts.ge0(b - 1 - i): raise Err(f"value {i} of those at {self.clause['name']}: not shown to be one the contract speaks of")
        A.fold = True                                       # what a definition with a kind gives is named here, not worked out
        return kspec.SPEC.eval(A, self.clause["expr"], dict(self.env, **{self.clause["index"]: plain(i)}))


class Lanes:
    """What a wide kernel leaves, a chaining value a lane: each is worked out when something reads it."""
    def __init__(self, n, each): self.n, self.each, self.memo = n, each, {}
    def __len__(self): return self.n
    def __getitem__(self, i):
        if not isinstance(i, int) or not 0 <= i < self.n: raise Err(f"lane {i} of {self.n}")
        if i not in self.memo: self.memo[i] = self.each(i)
        return self.memo[i]


def packed_kind(kind):
    """`bytes a b c d`: the names of a word's four low bytes; None for other kinds."""
    p = kind.split()
    return p[1:] if len(p) == 5 and p[0] == "bytes" else None


def size_of(kind):
    if kind == "cv": return 32
    if lanes_kind(kind, "cvs") is not None: return 32 * lanes_kind(kind, "cvs")
    if kind == "block": return 64
    if kind in ("number", "byte"): return 8
    n = bytes_kind(kind)
    if isinstance(n, int): return n
    if kind in kspec.SPEC.layouts: return kspec.SPEC.layouts[kind]["size"]
    raise Fail(f"a kind whose size is not a plain number: {kind}")


class Lazy(dict):
    """A record in memory that no call has left whole: each field is read when it is asked for."""
    def __init__(self, fields, read):
        super().__init__(); self.fields, self.read = list(fields), read
    def __contains__(self, k): return k in self.fields
    def __getitem__(self, k):
        if not dict.__contains__(self, k):
            if k not in self.fields: raise KeyError(k)
            dict.__setitem__(self, k, self.read(k))
        return dict.__getitem__(self, k)
    def all(self):
        for k in self.fields: self[k]
    def keys(self): self.all(); return dict.keys(self)
    def items(self): self.all(); return dict.items(self)
    def __iter__(self): self.all(); return dict.__iter__(self)
    def __len__(self): return len(self.fields)


class Env(dict):
    """A callee's arguments in the specification's terms: what lies at an address is read when it is asked for."""
    def __init__(self, values, later):
        super().__init__(values); self.later = later
    def __contains__(self, k): return dict.__contains__(self, k) or k in self.later
    def __getitem__(self, k):
        if not dict.__contains__(self, k): dict.__setitem__(self, k, self.later[k]())
        return dict.__getitem__(self, k)


class Contract:
    """A function's contract, as blake3.spec states it. The arguments are in the calling convention's order."""
    def __init__(self, symbol):
        c = kspec.SPEC.contracts.get(symbol)
        if c is None: raise Fail(f"{symbol}: no contract")
        self.name, self.text, self.stack = symbol, c, c["stack"]
        if len(c["args"]) > len(ARGS): raise Fail(f"{symbol}: more arguments than the registers that carry them")
        self.args = [(reg, kind, name) for reg, (name, kind) in zip(ARGS, c["args"])]
        self.kind = {name: kind for _, kind, name in self.args}
        for _, kind, name in self.args:
            if (kind not in ("number", "byte", "any", "cv", "cvs", "block", "counter", "low byte", "word", "low word") and kind not in kspec.SPEC.layouts and bytes_kind(kind) is None
                    and lanes_kind(kind, "inputs") is None and lanes_kind(kind, "cvs") is None and packed_kind(kind) is None): raise Fail(f"{symbol}: {name} is of a kind this checker does not know: {kind}")
            n = bytes_kind(kind)
            if isinstance(n, str) and self.kind.get(n) != "number": raise Fail(f"{symbol}: {name} is {kind}, and {n} is not a number among the arguments")
            if lanes_kind(kind, "inputs") is not None and self.kind.get("n") != "number": raise Fail(f"{symbol}: {name} is {kind}, and no number n says how many blocks each input has")
        for leaf in c["leaves"]:
            if leaf["index"] is not None and (lanes_kind(self.kind.get(leaf["name"], ""), "cvs") is None or leaf["each"] != (("num", 0), ("num", lanes_kind(self.kind[leaf["name"]], "cvs")))):
                raise Fail(f"{symbol}: it leaves each of some values that are not all the chaining values at an address")
        self.writes = {leaf["name"] for leaf in c["leaves"]} | set(c["spoils"])
        # `asks NAME[i] == E for i in a..b`: what each of the chaining values at an address is
        self.given = {g["name"]: g for g in c["given"]}
        if any(self.kind.get(name) != "cvs" for name in self.given) or any(kind == "cvs" and name not in self.given for _, kind, name in self.args) or self.writes & set(self.given):
            raise Fail(f"{symbol}: `cvs` is the kind of chaining values the contract says each one of (`asks NAME[i] == E for i in a..b`), given to read")
        # `needs F`: it runs instructions of the kind F; `needs F if NAME == NUMBER`: only where that holds
        self.needs = {}
        for feature, cond in c["needs"]:
            if cond is not None and not (cond[0] == "bin" and cond[1] == "==" and cond[2][0] == "name" and cond[3][0] == "num"): raise Fail(f"{symbol}: a condition on what it needs that is not NAME == NUMBER")
            self.needs[feature] = None if cond is None else (cond[2][1], cond[3][1])
        if any(self.kind.get(name) in (None, "number", "byte", "any") for name in self.writes): raise Fail(f"{symbol}: it leaves something that is not at an address among its arguments")
        self.calls = {}
        for callee, cond in c["calls"]:
            if not (cond[0] == "bin" and cond[1] == "==" and cond[2][0] == "name" and cond[3][0] == "num"): raise Fail(f"{symbol}: a condition on a call that is not NAME == NUMBER")
            self.calls[callee] = (cond[2][1], cond[3][1])


def stack_of(c, A, env, bound):
    """The stack a contract gives: a plain number, or one that grows with the length in bits of a number of the
    function's. `bound`: where the path does not fix that length, the least it can be (for the function's own
    use, which must be within it) or the most (for a caller, which must leave room for it)."""
    if isinstance(c.stack, int): return c.stack
    A.bound = bound
    try: return A.plain(kspec.SPEC.eval(A, c.stack[1], env))
    except Err as e: raise Fail(f"{c.name}: the stack it may use cannot be read here: {e}")
    finally: A.bound = None


CONTRACTS = {}
def contract(symbol):
    if symbol not in CONTRACTS: CONTRACTS[symbol] = Contract(symbol)
    return CONTRACTS[symbol]


# The one-block kernels, by their contracts: checked against the kernels' bytes by kone.py, and read from there.
def kernels(): return {c["symbol"]: c for c in kone.CONTRACTS.values()}


# ---------------------------------------------------------------------------------------------------------
# The machine: general registers, XMM registers as four 32-bit terms, memory in named regions of typed things.
#
# A general register holds: ("n", number); ("l", a number that depends on counts: whole, within 64 bits);
# ("a", region, offset): an address; ("p", eight bytes, each a number or a number or-ed with named flag bytes);
# ("z", a byte): a byte of memory, zero-extended; ("q", name): 64 bits of which nothing is known.
class Fork(Exception):
    def __init__(self, kind, x): self.kind, self.x = kind, x


class Machine:
    def __init__(self, T, rows, c):
        self.T, self.rows, self.contract = T, {a: (n, kcheck.parse(i)) for a, n, i in rows}, c
        self.g = {r: ("q", r + " at entry") for r in G64}
        self.g["rsp"] = ("a", "frame", 0)
        self.x, self.flags, self.facts, self.conds, self.memo = {}, None, Facts(), {}, {}
        # region -> {offset: (bytes, kind, value)}. The frame's offsets are from the entry stack pointer. Kind
        # "q": eight bytes as a register holds them; "x": sixteen as four terms; else a kind of the contracts.
        self.mem = {"frame": {0: (8, "q", ("q", "return address"))}}
        self.readonly, self.given = set(), {}
        self.low, self.pc, self.steps, self.back = 0, None, 0, {}
        A = self.A()
        for reg, kind, name in c.args:               # numbers first: a count of bytes may be named before it is given
            if kind == "number":
                x = sym(name); self.facts.add(x); self.facts.add(WORD64 - x)
                self.g[reg], self.given[name] = ("l", x), x
            elif kind == "byte":
                self.g[reg] = ("p", ((0, (name,)),) + (0,) * 7); self.given[name] = Word(byte_term(T, (0, (name,))))
            elif kind == "any": self.g[reg] = ("q", name)
        for reg, kind, name in c.args:
            if kind in ("number", "byte", "any"): continue
            if kind in ("counter", "low byte", "word", "low word") or packed_kind(kind) is not None or lanes_kind(kind, "inputs") is not None or lanes_kind(kind, "cvs") is not None:
                raise Fail(f"{c.name}: {name} is {kind}: a kernel's argument, and kernels are checked by kloop.py")
            self.g[reg] = ("a", name, 0)
            n = bytes_kind(kind)
            if kind == "cvs": v = None                                      # made below, when everything else it speaks of is
            elif kind == "block": v = [Word(T.mk("part", name, w)) for w in range(16)]
            elif n is None: v = A.of_kind(kspec.SPEC, kind, name)
            elif name in c.writes:
                if not isinstance(n, int): raise Fail(f"{c.name}: {name} is written, and its length is not a plain number")
                v = [A.index(Named(name, n), i) for i in range(n)]
            else: v = Slice(name, 0, self.given[n] if isinstance(n, str) else n)
            self.mem[name] = {0: (None, kind, v)}
            if name not in c.writes: self.readonly.add(name)
            self.given[name] = v
        try:
            for f in kspec.asked(c.text, A, self.given): self.facts.add(f)
        except Err as e: raise Fail(f"{c.name}: what it asks cannot be read: {e}")
        for name, clause in c.given.items():
            self.mem[name] = {0: (None, "cvs", Given(clause, self.given))}

    def A(self): return kspec.Symbols(self.T, self.facts, self.memo)

    def clone(self):
        c = copy.copy(self)
        c.g, c.x, c.conds, c.facts, c.memo, c.back = dict(self.g), dict(self.x), dict(self.conds), self.facts.clone(), dict(self.memo), dict(self.back)
        c.mem = {r: dict(cells) for r, cells in self.mem.items()}
        return c

    # -- memory
    def within(self, region, off, size):
        """The thing that holds `size` bytes at region + off: (its offset, (bytes, kind, value)); None where
        nothing was written."""
        if region != "frame":
            if region not in self.mem: raise Fail(f"an address in {region}: no such memory")
            return 0, self.mem[region][0]
        if isinstance(off, Lin): raise Fail(f"an address in the frame that depends on a count: {off}")
        for o, c in self.mem["frame"].items():
            if o <= off and off + size <= o + c[0]: return o, c
        return None

    def field_at(self, kind, off, size):
        """The field of a record that holds `size` bytes at `off`: (name, field, offset within it)."""
        for name, f in kspec.SPEC.layouts[kind]["fields"].items():
            whole = size_of(f["kind"]) * (f["count"] or 1)
            lo, hi = Lin.of(off) - f["at"], Lin.of(f["at"] + whole - size) - off
            if (not lo.c and not hi.c and lo.k >= 0 and hi.k >= 0) or ((lo.c or hi.c) and self.facts.ge0(lo) and self.facts.ge0(hi)): return name, f, plain(lo)
        raise Fail(f"{size} bytes at {off} of a {kind}: not shown to lie within one of its fields")

    def read_in(self, kind, v, off, size, where):
        A, T = self.A(), self.T
        try:
            if kind in ("q", "x"):
                if off == 0 and size == (8 if kind == "q" else 16): return v
            elif kind in ("cv", "block"):
                if size == 16 and isinstance(off, int) and off % 16 == 0 and 0 <= off < 4 * len(v): return tuple(w.v for w in v[off // 4:off // 4 + 4])
            elif lanes_kind(kind, "cvs") is not None:
                if size == 16 and isinstance(off, int) and off % 16 == 0 and 0 <= off < 32 * len(v): return tuple(w.v for w in v[off // 32][off % 32 // 4:off % 32 // 4 + 4])
            elif kind == "cvs":
                for half in (0, 16):
                    i = (Lin.of(off) - half).over(32)
                    if i is not None and size == 16: return tuple(w.v for w in v.get(self, i))[half // 4:half // 4 + 4]
            elif kind == "number":
                if off == 0 and size == 8: return value(v)
            elif kind == "byte":
                if off == 0 and size == 8: return ("p", (term_byte(T, v.v),) + (0,) * 7)
            elif bytes_kind(kind) is not None:
                if size == 1: return ("z", A.index(v, off))
                if size == 16:
                    if isinstance(v, Named):
                        if isinstance(off, int) and off % 4 == 0 and 0 <= off <= v.n - 16: return tuple(w.v for w in A.words(v)[off // 4:off // 4 + 4])
                    else: return tuple(w.v for w in A.words(A.slice(v, off, Lin.of(off) + 16)))
            elif kind in kspec.SPEC.layouts:
                name, f, sub = self.field_at(kind, off, size)
                if f["count"] is None: return self.read_in(f["kind"], v[name], sub, size, where)
                for half in (0, 16):
                    i = (Lin.of(sub) - half).over(32)
                    if i is not None and size == 16: return tuple(w.v for w in A.index(v[name], plain(i)))[half // 4:half // 4 + 4]
        except Err as e: raise Fail(f"a read at {where}: {e}")
        raise Fail(f"a read of {size} bytes at {where}: not as a {kind} lies")

    def write_in(self, kind, v, off, size, new, where):
        """The value of a thing of `kind` with `size` bytes at `off` replaced by what a register holds."""
        A, T = self.A(), self.T
        try:
            if kind in ("cv", "block"):
                if size == 16 and isinstance(off, int) and off % 16 == 0 and 0 <= off < 4 * len(v) and isinstance(new, tuple) and len(new) == 4:
                    out = list(v); out[off // 4:off // 4 + 4] = [Word(t) for t in new]
                    return out
            elif kind == "number":
                if off == 0 and size == 8 and lin(new) is not None: return plain(lin(new))
            elif kind == "byte":
                if off == 0 and size == 8: return Word(byte_term(T, one_byte(new)))
            elif bytes_kind(kind) is not None:
                if size == 1 and isinstance(off, int):
                    out = list(v) if isinstance(v, list) else [A.index(v, i) for i in range(A.plain(A.length(v)))]
                    if not 0 <= off < len(out): raise Fail(f"a write at {where}: outside the bytes")
                    out[off] = low_byte(new)
                    return out
            elif kind in kspec.SPEC.layouts:
                name, f, sub = self.field_at(kind, off, size)
                out = dict(v)
                if f["count"] is None:
                    out[name] = self.write_in(f["kind"], v[name], sub, size, new, where)
                    if f["below"] is not None and not self.facts.ge0(f["below"] - 1 - Lin.of(out[name])): raise Fail(f"a write at {where}: {out[name]} is not shown to be below {f['below']}, as a {kind}'s {name} is")
                    return out
                for half in (0, 16):
                    i = (Lin.of(sub) - half).over(32)
                    if i is not None and size == 16 and isinstance(new, tuple) and len(new) == 4:
                        try: words = A.index(v[name], plain(i))
                        except Err:
                            if v[name].base is not None: raise
                            words = [None] * 8                              # nothing was there: the other half is still nothing
                        words = list(words); words[half // 4:half // 4 + 4] = [Word(t) for t in new]
                        if any(w is None for w in words): raise Fail(f"a write at {where}: half of a value where nothing was")
                        out[name] = A.put(v[name], plain(i), words)
                        return out
        except Err as e: raise Fail(f"a write at {where}: {e}")
        raise Fail(f"a write of {size} bytes at {where}: not as a {kind} lies")

    def load(self, region, off, size):
        if region == "frame" and (isinstance(off, Lin) or off < self.g["rsp"][2]): raise Fail(f"a read below the stack pointer or at an unknown place of the frame, at {off}")
        hit = self.within(region, off, size)
        if hit is None: raise Fail(f"a read of {size} bytes at {region} + {off}: nothing was written there")
        o, (_, kind, v) = hit
        return self.read_in(kind, v, plain(Lin.of(off) - o), size, f"{region} + {off}")

    def store(self, region, off, size, new):
        where = f"{region} + {off}"
        if region in self.readonly: raise Fail(f"a write to {region}, which the contract gives to read")
        if region != "frame":
            if region not in self.mem: raise Fail(f"an address in {region}: no such memory")
            n, kind, v = self.mem[region][0]
            self.mem[region][0] = (n, kind, self.write_in(kind, v, off, size, new, where)); return
        if isinstance(off, Lin): raise Fail(f"a write at {where}")
        if off < self.g["rsp"][2] or off + size > 0: raise Fail(f"a write at {off} from the entry stack pointer: outside the function's own frame")
        hit = self.within(region, off, size)
        if hit is not None and hit[1][1] not in ("q", "x"):
            o, (n, kind, v) = hit
            self.mem["frame"][o] = (n, kind, self.write_in(kind, v, off - o, size, new, where)); return
        if size not in (8, 16): raise Fail(f"a write of {size} bytes at {where}: not into something of bytes")
        self.clear(off, size)
        self.mem["frame"][off] = (size, "q" if size == 8 else "x", new)

    def clear(self, off, size):
        """What lies within these bytes of the frame is gone; what lies across their edge may not be written through."""
        frame = self.mem["frame"]
        for o, c in list(frame.items()):
            if o < off + size and off < o + c[0]:
                if c[1] not in ("q", "x") and not (off <= o and o + c[0] <= off + size): raise Fail(f"a write at frame + {off} across the edge of a {c[1]}")
                del frame[o]

    # -- what lies at an address, as a value of the specification
    def descend(self, okind, v, sub, kind, count):
        A = self.A()
        if bytes_kind(kind) is not None:
            # some bytes: of a message, those from here; of bytes that were left whole, all of them
            if bytes_kind(okind) is not None:
                if isinstance(v, Slice): return A.slice(v, sub, Lin.of(sub) + count)
                if isinstance(sub, int) and sub == 0 and A.facts.zero(Lin.of(A.length(v)) - count) is True: return v
                return MISSING
        elif lanes_kind(okind, "cvs") is not None:
            if kind == okind and isinstance(sub, int) and sub == 0: return v
            if kind == "cv" and isinstance(sub, int) and sub % 32 == 0 and 0 <= sub < 32 * len(v): return v[sub // 32]
            return MISSING
        elif isinstance(sub, int) and sub == 0:
            if okind == kind: return v
            if kind == "block" and bytes_kind(okind) == 64: return A.words(v)
        if okind in kspec.SPEC.layouts:
            try: name, f, s2 = self.field_at(okind, sub, 1)
            except Fail: return MISSING
            if f["count"] is None: return self.descend(f["kind"], v[name], s2, kind, count)
            i = Lin.of(s2).over(32)
            if i is not None and kind == "cv": return A.index(v[name], plain(i))
        return MISSING

    def view(self, region, off, kind, count=None):
        """What a callee given the address region + off is given, as a value of `kind` (`count`: the bytes of a
        kind of bytes)."""
        try:
            hit = self.within(region, off, 1)
            if hit is not None and hit[1][1] not in ("q", "x"):
                o, (_, okind, v) = hit
                found = self.descend(okind, v, plain(Lin.of(off) - o), kind, count)
                if found is not MISSING: return found
            if kind == "cv": return [Word(t) for i in range(2) for t in self.load(region, plain(Lin.of(off) + 16 * i), 16)]
            if kind == "block": return [Word(t) for i in range(4) for t in self.load(region, plain(Lin.of(off) + 16 * i), 16)]
            if kind in kspec.SPEC.layouts and region == "frame":
                fields = kspec.SPEC.layouts[kind]["fields"]
                return Lazy(fields, lambda name: self.view_field(off, fields[name]))
        except Err as e: raise Fail(f"what lies at {region} + {off} as a {kind}: {e}")
        raise Fail(f"what lies at {region} + {off} is not a {kind}")

    def view_field(self, off, f):
        """A field of a record in the frame that no call has left whole."""
        at = off + f["at"]
        if f["count"] is not None: return Arr(None, f["count"])                    # nothing was put there (what the code wrote there by hand is not seen)
        if f["kind"] == "number":
            x = lin(self.load("frame", at, 8))
            if x is None or (f["below"] is not None and not self.facts.ge0(f["below"] - 1 - x)): raise Fail(f"frame + {at}: not a number as its kind says")
            return plain(x)
        if f["kind"] == "byte": return Word(byte_term(self.T, one_byte(self.load("frame", at, 8))))
        return self.view("frame", at, f["kind"], bytes_kind(f["kind"]))

    def put(self, region, off, kind, v):
        """A value of `kind` is left at region + off (by a callee)."""
        A = self.A()
        if region in self.readonly: raise Fail(f"a callee writes to {region}, which the contract gives to read")
        try:
            hit = self.within(region, off, 1)
            if hit is not None and hit[1][1] not in ("q", "x"):
                o, (n, okind, old) = hit
                self.mem[region][o] = (n, okind, self.replace(okind, old, plain(Lin.of(off) - o), kind, v)); return
        except Err as e: raise Fail(f"a callee leaves a {kind} at {region} + {off}: {e}")
        if region != "frame" or isinstance(off, Lin): raise Fail(f"a callee leaves a {kind} at {region} + {off}: not where one lies")
        if kind == "cv":
            self.store(region, off, 16, tuple(w.v for w in v[:4])); self.store(region, off + 16, 16, tuple(w.v for w in v[4:])); return
        size = size_of(kind)
        if off < self.g["rsp"][2] or off + size > 0: raise Fail(f"a callee leaves a {kind} at {off} from the entry stack pointer: outside the function's own frame")
        self.clear(off, size)
        self.mem["frame"][off] = (size, kind, v)

    def replace(self, okind, old, sub, kind, v):
        if isinstance(sub, int) and sub == 0 and okind == kind: return v
        if okind in kspec.SPEC.layouts:
            name, f, s2 = self.field_at(okind, sub, 1)
            out = dict(old)
            if f["count"] is None: out[name] = self.replace(f["kind"], old[name], s2, kind, v)
            else:
                i = Lin.of(s2).over(32)
                if i is None or kind != "cv": raise Fail(f"a {kind} left where a value of an array does not begin")
                out[name] = self.A().put(old[name], plain(i), v)
            return out
        raise Fail(f"a {kind} left inside a {okind}, not where one lies")

    # -- registers
    def address(self, base, disp):
        b = self.g[base.lstrip(".")]
        if b[0] != "a": raise Fail(f"an address from {base} = {b}")
        return b[1], plain(Lin.of(b[2]) + signed(num(disp)))

    def operand(self, o):
        if o[0] == ".reg": return self.g[o[1].lstrip(".")]
        if o[0] == ".imm": return ("n", num(o[1]))
        return self.load(*self.address(o[1], o[2]), 8)

    def number(self, d):
        """A number the code has computed, within 64 bits. A subtraction that may go below zero splits the
        path; below zero it wraps, and must then be a plain number."""
        F = self.facts
        if not d.c: return ("n", d.k & WORD64)
        if F.ge0(d):
            if not F.ge0(WORD64 - d): raise Fail(f"{d} is not shown to stay within 64 bits")
            return ("l", d)
        if F.ge0(-d - 1):
            k = F.number(d)
            if k is None: raise Fail(f"{d} is below zero, and not a plain number")
            return ("n", k & WORD64)
        raise Fork("ge", d)

    def arith(self, op, x, y):
        F = self.facts
        if op in ("add", "sub"):
            if x[0] == "a" and lin(y) is not None: return ("a", x[1], plain(Lin.of(x[2]) + (lin(y) if op == "add" else -lin(y))))
            if op == "add" and y[0] == "a" and lin(x) is not None: return ("a", y[1], plain(Lin.of(y[2]) + lin(x)))
            if lin(x) is not None and lin(y) is not None: return self.number(lin(x) + lin(y) if op == "add" else lin(x) - lin(y))
        elif op == "shl":
            if lin(x) is not None and 0 <= y[1] < 32: return self.number(lin(x).scale(1 << y[1]))
        elif op == "shr":
            if x[0] == "n": return ("n", x[1] >> y[1])
            if x[0] == "l":
                if F.ge0((1 << y[1]) - 1 - x[1]): return ("n", 0)
                if y[1] <= 16:
                    try: return value(halved(F, x[1], 1 << y[1]))
                    except Err as e: raise Fail(str(e))
        elif op == "and":
            if x[0] == "n" and y[0] == "n": return ("n", x[1] & y[1])
            if x[0] == "l" and y == ("n", 1):
                try: return value(x[1] - Lin.of(halved(F, x[1], 2)).scale(2))
                except Err as e: raise Fail(str(e))
        elif op == "or":
            if x[0] == "n" and y[0] == "n": return ("n", x[1] | y[1])
            if x[0] == "p" and y[0] == "n": return ("p", tuple(byte_or(b, (y[1] >> 8 * i) & 0xFF) for i, b in enumerate(x[1])))
            if x[0] == "n" and y[0] == "p": return self.arith(op, y, x)
            if x[0] == "p" and y[0] == "p": return ("p", tuple(byte_or(b, c) for b, c in zip(x[1], y[1])))
            for a, b in ((x, y), (y, x)):
                if a[0] == "l" and b[0] == "n":
                    if b[1] == 0: return a
                    k = F.number(a[1])
                    if k is not None: return ("n", k | b[1])
        raise Fail(f"{op} of {x} and {y}")

    def branch(self, op):
        if self.flags is None: raise Fail("a branch on flags no compare set")
        kind, x = self.flags
        if kind == "numbers":
            if op in (".je", ".jne"):
                z = self.facts.zero(x)
                if z is None: raise Fork("zero", x)
                return z == (op == ".je")
            ge = True if self.facts.ge0(x) else False if self.facts.ge0(-x - 1) else None      # unsigned: both sides are whole numbers not below zero
            if ge is None: raise Fork("ge", x)
            return ge == (op == ".jae")
        if op not in (".je", ".jne"): raise Fail("an order asked of something that is not a number")
        if x not in self.conds: raise Fork("cond", x)
        return self.conds[x] == (op == ".je")

    # -- calls
    def call(self, name):
        T, sp = self.T, self.g["rsp"][2]
        only = self.contract.calls.get(name)
        if only is not None and self.conds.get(only) is not True: raise Fail(f"{name} is called on a path that does not say {only[0]} is {only[1]}")
        A = self.A()
        try:
            c = contract(name)
            self.needed(name, c)
            if name in kernels(): used = self.call_kernel(A, name, kernels()[name])
            else: used = self.call_contract(A, name, c)
        except Err as e: raise Fail(f"a call of {name}: {e}")
        self.low = min(self.low, sp - used)
        for r in G64:
            if r not in KEPT and r not in ("rsp", "rax"): self.g[r] = ("q", "left by a call")
        self.x, self.flags = {}, None

    def needed(self, name, c):
        """What the callee needs of the processor, this function's contract says it needs too: always, or on a
        condition that holds on this path. Where the callee's need is itself on a condition (of an argument),
        what it is given for that argument is this function's own (with the same number), or a plain number
        that is not the callee's, or anything on a path where this function's own condition holds."""
        for feature, cond in c.needs.items():
            if feature not in self.contract.needs: raise Fail(f"{name} needs {feature}, and this function's contract does not say that it does")
            mine = self.contract.needs[feature]
            if mine is None or self.conds.get(mine) is True: continue
            if cond is None: raise Fail(f"{name} needs {feature}, and is called on a path that does not say {mine[0]} is {mine[1]}")
            passed = self.g[next(reg for reg, _, a in c.args if a == cond[0])]
            if not ((passed == ("q", mine[0]) and cond[1] == mine[1]) or (passed[0] == "n" and passed[1] != cond[1])):
                raise Fail(f"{name} needs {feature} if its {cond[0]} is {cond[1]}: what it is given for {cond[0]} is not shown to be so only where {mine[0]} is {mine[1]}")

    def apart(self, name, written, others):
        """What a callee writes is apart from everything else it is given the address of: its own check took
        them to be. (region, offset, bytes); things of different regions are apart."""
        for region, off, size in written:
            for r, o, n in others:
                if r != region: continue
                if isinstance(off, Lin) or isinstance(o, Lin) or isinstance(size, Lin) or isinstance(n, Lin) or size is None or n is None:
                    raise Fail(f"{name}: what it writes and something else it is given are both in {region}, and are not shown to be apart")
                if off < o + n and o < off + size: raise Fail(f"{name}: what it writes at {region} + {off} lies across something else it is given, at {region} + {o}")

    def told(self, A, name, c, clause, at, env):
        """`asks NAME[i] == E for i in a..b` of a callee: each of those values in this function's memory is E.
        Where a and b are plain numbers, each i in turn; else for a number i of which nothing is known but
        that it is within a..b."""
        region, off, _ = at
        a, b = (kspec.SPEC.eval(A, e, env) for e in clause["each"])
        for k in env.later:
            if k not in c.writes and k not in c.given: env[k]               # what the callee is given to read, read now
        def one(i):
            got = self.view(region, plain(Lin.of(off) + Lin.of(i).scale(32)), "cv")       # first: what the memory holds names what it can
            want = kspec.SPEC.eval(self.A(), clause["expr"], dict(env, **{clause["index"]: plain(i)}))
            if not kspec.same(self.A(), got, want): raise Fail(f"{name}: the value {i} at {clause['name']} is not shown to be what it asks")
        if region != "frame" and self.mem[region][0][1] == "cvs":
            # this function's memory there is itself such values (of which its own contract says what each is):
            # shown for a number i of which nothing is known but that it is within a..b
            mine, i = self.facts, sym(f"any {clause['index']} #{next(FRESH)}")
            self.facts = mine.clone()
            try:
                self.facts.add(i - a); self.facts.add(Lin.of(b) - 1 - i)
                if self.facts.consistent(): one(i)                              # (no such i: nothing is asked)
            finally: self.facts = mine
            return
        a, b = A.plain(a), A.plain(b)
        if b - a > 64: raise Fail(f"{name}: {b - a} values asked of, one by one: more than this checker takes")
        for i in range(a, b): one(i)

    def call_kernel(self, A, name, k):
        """(cv, block, length, counter, flags): the 32 bytes at cv become compress(cv, the 64 bytes at block,
        counter, length, flags). Where the kernel reads the length and the flags from is its contract's."""
        cv, block, length, counter, flags = (self.g[r] for r in ARGS[:5])
        if cv[0] != "a" or block[0] != "a": raise Fail(f"{name} called with something that is not an address")
        self.apart(name, [(cv[1], cv[2], 32)], [(block[1], block[2], 64)])
        h, m = self.view(cv[1], cv[2], "cv"), self.view(block[1], block[2], "block")
        if lin(length) is None or lin(counter) is None: raise Fail(f"{name} called with a length or a counter that is not a number: {length}, {counter}")
        top = 255 if k["length"] == "low byte" else (1 << 32) - 1
        if not self.facts.ge0(top - lin(length)): raise Fail(f"{name} reads the length's {k['length']}: the caller does not show it is at most {top}")
        if flags[0] == "n" and flags[1] < 256: flags = ("p", (flags[1],) + (0,) * 7)
        if flags[0] != "p" or (k["flags"] == "low word" and any(b != 0 for b in flags[1][1:4])): raise Fail(f"{name} reads the flags' {k['flags']}: the caller does not show them to be a byte")
        env = dict(zip(k["names"], (h, m, plain(lin(length)), A.counter(lin(counter)), Word(byte_term(self.T, flags[1][0])))))
        self.put(cv[1], cv[2], "cv", kspec.SPEC.eval(A, k["leaves"], env))
        self.g["rax"] = ("q", "left by a call")
        return 8

    def call_contract(self, A, name, c):
        v, later, where = {}, {}, {}
        # what the callee calls only on a condition, this function calls only on its own: the callee's
        # condition is on an argument, which must be this function's own (with the same number), or a plain
        # number that is not the callee's, or anything on a path where this function's condition holds
        for f, (arg, number) in c.calls.items():
            only = self.contract.calls.get(f)
            if only is None: raise Fail(f"{name} may call {f}, and this function's contract does not say when it does")
            passed = self.g[next(reg for reg, _, a in c.args if a == arg)]
            if not (self.conds.get(only) is True or (passed == ("q", only[0]) and number == only[1]) or (passed[0] == "n" and passed[1] != number)):
                raise Fail(f"{name} calls {f} if its {arg} is {number}: what it is given for {arg} is not shown to be so only where {only[0]} is {only[1]}")
        number = lambda b: b if isinstance(b, int) else Word(byte_term(self.T, b))      # a byte that is a plain number is that number, as the specification writes it
        for reg, kind, arg in c.args:
            a = self.g[reg]
            if kind == "number":
                if lin(a) is None: raise Fail(f"{name}: {arg} is not a number")
                v[arg] = plain(lin(a))
            elif kind == "counter":
                if lin(a) is None: raise Fail(f"{name}: {arg} is not a number")
                v[arg] = A.counter(lin(a))
            elif kind == "byte": v[arg] = number(one_byte(a))
            elif packed_kind(kind) is not None:
                # a word whose four low bytes are named; what is above them the callee does not read
                if a[0] == "n": a = ("p", tuple((a[1] >> 8 * i) & 0xFF for i in range(8)))
                if a[0] != "p": raise Fail(f"{name}: {arg} is not a word of flag bytes")
                for nm, b in zip(packed_kind(kind), a[1]): v[nm] = number(b)
        spans = {}
        for reg, kind, arg in c.args:
            if kind in ("number", "byte", "any", "counter") or packed_kind(kind) is not None: continue
            a = self.g[reg]
            if a[0] != "a": raise Fail(f"{name}: {arg} is not an address")
            n = bytes_kind(kind)
            count = v[n] if isinstance(n, str) else n
            where[arg] = (a[1], a[2], kind)
            lanes = lanes_kind(kind, "inputs")
            if lanes is not None:
                # a table of addresses, each of an input of n blocks of 64 bytes
                blocks = A.plain(v["n"])
                table = [self.load(a[1], plain(Lin.of(a[2]) + 8 * i), 8) for i in range(lanes)]
                if any(e[0] != "a" for e in table): raise Fail(f"{name}: {arg} is not a table of addresses")
                v[arg] = [[self.view(e[1], plain(Lin.of(e[2]) + 64 * b), "block") for b in range(blocks)] for e in table]
                spans[arg] = [(a[1], a[2], 8 * lanes)] + [(e[1], e[2], 64 * blocks) for e in table]
                continue
            if kind == "cvs":
                # as many values as the contract speaks of, where that is a plain number here
                try: extent = 32 * A.plain(kspec.SPEC.eval(A, c.given[arg]["each"][1], v))
                except Err: extent = None
                spans[arg] = [(a[1], a[2], extent)]
            else: spans[arg] = [(a[1], a[2], count if n is not None else size_of(kind))]
            later[arg] = (lambda a=a, kind=kind, count=count: self.view(a[1], a[2], kind, count))
            if arg not in c.writes and n is not None: later[arg]()             # bytes given to read are there to be read
        for arg in c.writes: self.apart(name, spans[arg], [s for other, ss in spans.items() if other != arg for s in ss])
        env = Env(v, later)
        for arg, clause in c.given.items(): self.told(A, name, c, clause, where[arg], env)
        for f in kspec.asked(c.text, A, env):
            if not self.facts.ge0(f): raise Fail(f"{name}: the caller does not show what it asks ({f} >= 0)")
        left = {}
        A.fold = True
        try:
            for leaf in c.text["leaves"]:
                if leaf["index"] is None: left[leaf["name"]] = kspec.SPEC.eval(A, leaf["expr"], env)
                else:
                    # each of the chaining values at the address: `out[i] = E for i in 0..N`
                    for k in later:
                        if k not in c.writes: env[k]                    # what is read at an address: read now, for each lane
                    frozen, facts, memo = dict(env), self.facts, self.memo
                    def lane(i, leaf=leaf, frozen=frozen):
                        # a lane's value, when something reads it: from what the kernel was given at the call
                        # (no fact is needed for it but that the counter stays within 64 bits, shown here)
                        return kspec.SPEC.eval(kspec.Symbols(self.T, facts, memo), leaf["expr"], dict(frozen, **{leaf["index"]: i}))
                    for name, v in frozen.items():
                        if isinstance(v, kspec.Count) and not self.facts.ge0(WORD64 - Lin.of(v.n) - lanes_kind(c.kind[leaf["name"]], "cvs")): raise Fail(f"{name}: the counter is not shown to stay within 64 bits over the lanes")
                    left[leaf["name"]] = Lanes(lanes_kind(c.kind[leaf["name"]], "cvs"), lane)
        finally: A.fold = False
        for arg, new in left.items(): self.put(*where[arg], new)
        for arg in c.text["spoils"]: self.put(*where[arg], A.of_kind(kspec.SPEC, c.kind[arg], f"{arg} as {name} leaves it, #{next(FRESH)}"))
        if c.text["returns"] is not None:
            result = Lin.of(kspec.SPEC.eval(A, c.text["returns"], Env(dict(v, **left), {k: f for k, f in later.items() if k not in left})))
            self.facts.add(result); self.facts.add(WORD64 - result)
            self.g["rax"] = value(result)
        else: self.g["rax"] = ("q", "left by a call")
        return 8 + stack_of(c, A, env, "most")

    # -- one instruction
    def one(self):
        if self.pc not in self.rows: raise Fail(f"no instruction at 0x{self.pc:X}")
        nxt, i = self.rows[self.pc]
        op, a = i[0], i[1:]
        if op in (".je", ".jne", ".jae", ".jb"):
            if self.branch(op): nxt = num(a[0])                       # may fork: nothing is changed before it does
        elif op == ".jmp": nxt = num(a[0])
        elif op == ".nop": pass
        elif op == ".mov":
            if a[0] == "8":
                if a[1][0] != ".mem" or a[2][0] != ".reg": raise Fail("a move of a byte that is not from a register to memory")
                self.store(*self.address(a[1][1], a[1][2]), 1, self.g[a[2][1].lstrip(".")])
            elif a[0] == "64":
                v = self.operand(a[2])
                if a[1][0] == ".reg": self.g[a[1][1].lstrip(".")] = v
                else: self.store(*self.address(a[1][1], a[1][2]), 8, v)
            else: raise Fail("a move that is not of 64 bits or of a byte")
        elif op == ".movzx8":
            if a[1][0] != ".mem": raise Fail("a byte that is not from memory")
            self.g[a[0].lstrip(".")] = self.load(*self.address(a[1][1], a[1][2]), 1)
        elif op in (".add", ".sub", ".or", ".and"):
            if a[0] != "64" or a[1][0] != ".reg": raise Fail(f"{op} that is not of 64 bits into a register")
            r = a[1][1].lstrip(".")
            v = self.arith(op[1:], self.g[r], self.operand(a[2]))
            if r == "rsp":
                if v[0] != "a" or v[1] != "frame" or isinstance(v[2], Lin): raise Fail("the stack pointer leaves the frame")
                self.low = min(self.low, v[2])
            self.g[r] = v; self.flags = None
        elif op in (".shl64", ".shr64"):
            r = a[0].lstrip("."); self.g[r] = self.arith(op[1:4], self.g[r], ("n", num(a[1]))); self.flags = None
        elif op == ".cmp":
            if a[0] != "64": raise Fail("a compare that is not of 64 bits")
            x, y = self.operand(a[1]), self.operand(a[2])
            if lin(x) is not None and lin(y) is not None: self.flags = ("numbers", lin(x) - lin(y))
            elif x[0] == "q" and y[0] == "n": self.flags = ("unknown", (x[1], y[1]))        # is an unknown word this number? either way
            else: raise Fail(f"a compare of {x} and {y}")
        elif op == ".lea":
            b = self.g[a[1].lstrip(".")]
            if b[0] != "a": raise Fail("lea from a non-address")
            self.g[a[0].lstrip(".")] = ("a", b[1], plain(Lin.of(b[2]) + signed(num(a[2]))))
        elif op == ".xloadu": self.x[int(a[0])] = self.load(*self.address(a[1], a[2]), 16)
        elif op == ".xstoreu":
            if int(a[2]) not in self.x: raise Fail(f"xmm{a[2]} stored before it is written")
            self.store(*self.address(a[0], a[1]), 16, self.x[int(a[2])])
        elif op == ".push":
            sp = self.g["rsp"]
            self.g["rsp"] = ("a", "frame", sp[2] - 8); self.low = min(self.low, sp[2] - 8)
            self.store("frame", sp[2] - 8, 8, self.g[a[0].lstrip(".")])
        elif op == ".pop":
            sp = self.g["rsp"]
            self.g[a[0].lstrip(".")] = self.load("frame", sp[2], 8); self.g["rsp"] = ("a", "frame", sp[2] + 8)
        elif op == ".call": self.call(a[0])
        elif op == ".ret":
            if self.g["rsp"] != ("a", "frame", 0) or self.mem["frame"].get(0) != (8, "q", ("q", "return address")): raise Fail("a return to somewhere else")
            nxt = None
        else: raise Fail(f"an instruction this checker does not know: {' '.join(map(str, i))}")
        if nxt is not None and nxt <= self.pc:
            self.back[nxt] = self.back.get(nxt, 0) + 1
            if self.back[nxt] > TURNS: raise Fail(f"a loop has turned {TURNS} times on one path: not a loop this checker runs")
        self.steps += 1; self.pc = nxt


def one_byte(v):
    """A register that holds a byte and nothing above it, as the byte."""
    if v[0] == "n" and v[1] < 256: return v[1]
    if v[0] == "p" and all(b == 0 for b in v[1][1:]): return v[1][0]
    raise Fail(f"{v} is not shown to be a byte")


def low_byte(v):
    """The low byte of a register, as a byte of memory."""
    if v[0] == "n": return v[1] & 0xFF
    if v[0] == "z": return v[1]
    raise Fail(f"the low byte of {v}: not a byte this checker follows")


def paths(m, budget):
    """Every path of m to the return. `budget`: a list of one number, the instructions that may still be run."""
    ends, work = [], [m]
    while work:
        m = work.pop()
        while True:
            if m.pc is None: ends.append(m); break
            if budget[0] <= 0: raise Fail(f"still running after {STEPS} instructions")
            try:
                m.one(); budget[0] -= 1
            except Fork as f:
                yes, no = m.clone(), m.clone()
                if f.kind == "zero": yes.facts.assume_zero(f.x); no.facts.assume_nonzero(f.x)
                elif f.kind == "ge": yes.facts.add(f.x); no.facts.add(-f.x - 1)
                else: yes.conds[f.x] = True; no.conds[f.x] = False
                work += [side for side in (yes, no) if side.facts.consistent()]; break
    return ends


# ---------------------------------------------------------------------------------------------------------
# The checker.
def returned(e, c, where):
    """At a return: what the contract says is left and returned, the registers a callee keeps, the stack."""
    A = e.A()
    left = {}
    for leaf in c.text["leaves"]:
        name = leaf["name"]
        try:
            want = kspec.SPEC.eval(A, leaf["expr"], dict(e.given))
            n = bytes_kind(c.kind[name])
            got = e.view(name, 0, c.kind[name], e.given.get(n) if isinstance(n, str) else n)
            if not kspec.same(A, got, want): raise Fail(f"{where}: {name} at the return is not what the contract says")
        except Err as err: raise Fail(f"{where}: the specification cannot be followed on this path: {err}")
        left[name] = want
    if c.text["returns"] is not None:
        env = dict(e.given); env.update(left)
        try: want = Lin.of(kspec.SPEC.eval(A, c.text["returns"], env))
        except Err as err: raise Fail(f"{where}: the specification cannot be followed on this path: {err}")
        if lin(e.g["rax"]) is None or e.facts.zero(lin(e.g["rax"]) - want) is not True: raise Fail(f"{where}: the result is {e.g['rax']}, the contract says {want}")
    for r in KEPT:
        if e.g[r] != ("q", r + " at entry"): raise Fail(f"{where}: {r} is not restored")
    within(e, c, where)


def within(e, c, where):
    """The stack used on the path of e is within what the contract gives."""
    given = stack_of(c, e.A(), dict(e.given), "least")
    if -e.low > given: raise Fail(f"{where}: {-e.low} bytes of stack used, the contract gives {given}")


def check(rows, name, proof=None):
    """The function's instructions meet its contract. (`proof`: for this checker, nothing: a proof with a place
    is refused.)"""
    if proof is not None and proof.get("places"): raise Fail("a proof with a place: this checker runs every loop")
    c, T = contract("b3l_" + name), kcheck.Terms()
    m = Machine(T, rows, c); m.pc = rows[0][0]
    budget = [STEPS]
    ends = paths(m, budget)
    for e in ends: returned(e, c, "at a return")
    if not ends: raise Fail("no path returns")
    return {"return": len(ends), "place": 0, "widest": STEPS - budget[0]}


def find(rows, name):
    """What a prover would do here: there is nothing to find."""
    check(rows, name)
    return dict(function=name, places=[])


def load(obj, name):
    rows, _ = kdecode.read(obj, "b3l_" + name, BASE, DATA)
    return rows


def main():
    name, obj = sys.argv[1], sys.argv[2]
    rows = load(obj, name)
    if "--find" in sys.argv:
        with open(sys.argv[sys.argv.index("--find") + 1], "w") as f: json.dump(find(rows, name), f, indent=1)
    t0 = time.time()
    done = check(rows, name)
    print(f"{name}: the {len(rows)} instructions meet the contract, for everything the contract allows")
    print(f"     checked in {time.time() - t0:.3f} s: {done['return']} path(s) to the return, {done['widest']} instructions run")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Fail as e:
        print(f"{sys.argv[1]}: NOT shown: {e}"); sys.exit(1)
