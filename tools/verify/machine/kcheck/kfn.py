#!/usr/bin/env python3
"""kfn: a function of compiled code against its contract. Records and arrays in memory, bytes of a message of
any length, calls by contract (a call of itself by its own).

    python3 kfn.py NAME OBJECT            the verifier

The third trial of the way of kloop.py and kglue.py (November 15, 2026): BLAKE3's hash of a message as the Ode
compiler and the assembler leave it (hash.ode, x86-64): `pad`, `chunk_node`, `node_out`, `subtree`, `hashr`.

WHAT IS CLAIMED OF A FUNCTION is its `contract` (blake3.spec for the function a user calls; proofs/inner.spec
for the functions inside): what each argument is (a number, a flags byte, or the address of a chaining value,
of some bytes, or of a record whose `layout` is given), what the caller must show (`asks`), what the memory
named holds afterwards (`leaves`, in the specification's definitions), what is returned, how much stack it
may use, which function it calls only on a condition. Everything it does not name is as it was.

THE VERIFIER runs the code on symbols from its entry, forward along every path, to the return:
  - a branch on something the path does not fix splits the path, and each side takes the fact with it; a
    path whose facts cannot all hold is dropped;
  - a loop is run: every loop of this code turns a number of times its path fixes (a chunk's 16 blocks, a
    block's 64 bytes, the 54 doublings of a count of chunks). A loop that turns more than 100 times on a path
    is refused;
  - at a call: the callee's contract. What it asks is shown from the caller's facts; what it leaves replaces
    what was there; the registers a call may change are forgotten. A function that calls itself is taken by
    its own contract, and its contract names a number that is shown less at each such call (`decreases`), so
    the calls of itself come to an end;
  - at the return: each thing the contract says is left is the specification's value of it, evaluated on the
    same path (where the specification asks how two numbers compare, the path must have asked too); the
    result, the registers a callee keeps, the stack pointer, and the stack used.
A loop whose count the path does not fix (a kernel's loop over the blocks of a chunk) is not run: the proof
names a PLACE in it and what holds there after any number of turns, and that is shown by induction (below:
"A loop whose count the path does not fix"). For every other function there is no proof text: the binary,
the specification and the contracts are all the verifier is given.

No solver: terms are compared by identity, numbers by adding linear facts up (klin.py). What the
specification's definitions give that cannot be worked out on a path (the tree over bytes whose count the
path does not fix) is named by what it is of, and two names are one thing when they are the same (kspec.py).
What a callee leaves is so named, not opened.

WHAT IS NOT CHECKED HERE: this verifier (Python, unverified: its audits are its worth)."""
import copy, itertools, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kdecode, kspec, kterms, ode
from kterms import Fail, num, signed
from klin import Lin, Facts, sym, value, lin
from kspec import Arr, ByteT, Slice, Named, plain, byte_or, byte_term, term_byte, halved
from ode import Word, Counter, Err

BASE, DATA = 0x10000, 0x50000000
G64 = kterms.G64
KEPT = kterms.SAVED                 # the registers a callee keeps
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
        try: c = kspec.as_words(kspec.SPEC.contracts.get(symbol), kspec.SPEC)
        except Err as e: raise Fail(f"{symbol}: {e}")
        if c is None: raise Fail(f"{symbol}: no contract")
        self.name, self.text, self.stack = symbol, c, c["stack"]
        if len(c["args"]) > len(ARGS): raise Fail(f"{symbol}: more arguments than the registers that carry them")
        self.args = [(reg, kind, name) for reg, (name, kind) in zip(ARGS, c["args"])]
        self.kind = {name: kind for _, kind, name in self.args}
        for _, kind, name in self.args:
            if (kind not in ("number", "byte", "any", "cv", "cvs", "block", "counter", "low byte", "word", "low word") and kind not in kspec.SPEC.layouts and bytes_kind(kind) is None
                    and lanes_kind(kind, "inputs") is None and lanes_kind(kind, "cvs") is None and packed_kind(kind) is None): raise Fail(f"{symbol}: {name} is of a kind this verifier does not know: {kind}")
            n = bytes_kind(kind)
            if isinstance(n, str) and self.kind.get(n) != "number": raise Fail(f"{symbol}: {name} is {kind}, and {n} is not a number among the arguments")
            if lanes_kind(kind, "inputs") is not None and self.kind.get("n") != "number": raise Fail(f"{symbol}: {name} is {kind}, and no number n says how many blocks each input has")
        if any(leaf.get("part") is not None or leaf.get("cond") is not None for leaf in c["leaves"]) or c.get("trace") or c.get("conditions"):
            raise Fail(f"{symbol}: a contract with `ensures X[a .. b]`, `ensures ... if C` or `trace depends on`: not this verifier's yet")
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


def one_block(symbol):
    """A one-block kernel's contract, for a call of it: (cv, block, length, counter, flags) in the calling
    convention's order, the length a `low byte` or a `word`, the flags a `low byte` or a `low word`; it leaves
    the chaining value, uses no stack, returns nothing. None for any other contract."""
    c = kspec.SPEC.contracts.get(symbol)
    kinds = [kind for _, kind in c["args"]] if c else []
    if len(kinds) != 5 or kinds[0] != "cv" or kinds[1] != "block" or kinds[2] not in ("low byte", "word") or kinds[3] != "counter" or kinds[4] not in ("low byte", "low word"): return None
    if c["stack"] != 0 or len(c["leaves"]) != 1 or c["leaves"][0]["name"] != c["args"][0][0] or c["leaves"][0]["index"] is not None or c["asks"] or c["returns"] is not None: return None
    return dict(symbol=symbol, length=kinds[2], flags=kinds[4], names=[arg for arg, _ in c["args"]], leaves=c["leaves"][0]["expr"])


# ---------------------------------------------------------------------------------------------------------
# The machine: general registers, XMM registers as four 32-bit terms, memory in named regions of typed things.
#
# A general register holds: ("n", number); ("l", a number that depends on counts: whole, within 64 bits);
# ("a", region, offset): an address; ("p", eight bytes, each a number or a number or-ed with named flag bytes);
# ("z", a byte): a byte of memory, zero-extended; ("q", name): 64 bits of which nothing is known;
# ("pair", low, high): two 32-bit terms (a counter); ("low", name): 64 bits of which only the low byte is
# spoken of, the byte `name`; ("al", n): the plain number n in AL, nothing known above it.
# ("t", term): a 32-bit term, zeros above it; ("lowt", term): 64 bits of which only the low 32 are spoken of.
# A vector register holds 32-bit terms (kterms.Terms), the lowest first: four where only its low 128 bits are
# known (XMM), sixteen where all 512 are (ZMM). A mask register ("k", number) holds sixteen truths, as terms.
# An XMM register may hold, for a moment, half of a rotation a word: ("shl" or "shr", term, by how much): the
# older instructions rotate by two shifts and an or. Nothing takes such a half but a move and that or.
class Fork(Exception):
    def __init__(self, kind, x): self.kind, self.x = kind, x


class Machine:
    # `wide`: where the stack pointer was (from its entry value) when it was rounded down to a 64-byte boundary,
    # while it is in the part of the frame below that ("wide": sixty-four bytes a cell, as sixteen terms).
    # `ghost`: at a return, the sequences whose last values a place's induction has shown. `rest`: for a place.
    # BOUNDARY: this machine takes such a frame (kbyte.py's, which is this one with other memory, does not).
    # `data`: the file's read-only data ("rodata": numbers of 32 bits are read from it, nothing is written).
    # `calls`: how many calls the path has made: what a call leaves in a register is an unknown of its own,
    # named by the register and the call (two unknowns under one name would be taken to answer alike).
    wide, ghost, rest, BOUNDARY, data, calls = None, {}, 0, True, b"", 0

    def __init__(self, T, rows, c, data=b""):
        self.data = data
        self.T, self.rows, self.contract = T, {a: (n, kterms.parse(i)) for a, n, i in rows}, c
        self.g = {r: ("q", r + " at entry") for r in G64}
        self.g["rsp"] = ("a", "frame", 0)
        self.x, self.flags, self.facts, self.conds, self.memo = {}, None, Facts(), {}, {}
        # region -> {offset: (bytes, kind, value)}. The frame's offsets are from the entry stack pointer. Kind
        # "q": eight bytes as a register holds them; "x": sixteen as four terms; else a kind of the contracts.
        self.mem = {"frame": {0: (8, "q", ("q", "return address"))}}
        self.readonly, self.given = set(), {}
        self.low, self.pc, self.steps, self.back = 0, None, 0, {}
        # the things at the addresses given are taken not to overlap: the contract must ask it of the caller
        addresses = [name for _, kind, name in c.args if kind not in ("number", "byte", "any", "counter", "low byte", "word", "low word") and packed_kind(kind) is None]
        if len(addresses) > 1 and sorted(c.text["no_overlap"] or []) != sorted(addresses):
            raise Fail(f"{c.name}: the contract does not say `requires no_overlap({', '.join(addresses)})`: the things at the addresses it is given are taken not to overlap")
        A = self.A()
        for reg, kind, name in c.args:               # numbers first: a count of bytes may be named before it is given
            if kind == "number":
                x = sym(name); self.facts.add(x); self.facts.add(WORD64 - x)
                self.g[reg], self.given[name] = ("l", x), x
            elif kind == "byte":
                self.g[reg] = ("p", ((0, (name,)),) + (0,) * 7); self.given[name] = Word(byte_term(T, (0, (name,))))
            elif kind == "any": self.g[reg] = ("q", name)
            elif kind == "counter":                                         # 64 bits in the register: the counter's two words
                lo, hi = T.var(name, "low"), T.var(name, "high")
                self.g[reg], self.given[name] = ("pair", lo, hi), Counter(Word(lo), Word(hi))
            elif kind == "low byte":                                        # the register's low byte is the number; nothing is said of the rest
                self.g[reg], self.given[name] = ("low", name), Word(byte_term(T, (0, (name,))))
            elif kind in ("word", "low word"):                              # a number below 2^32: zeros above it in the register (`word`), or nothing said of what is above (`low word`)
                self.g[reg], self.given[name] = ("t" if kind == "word" else "lowt", T.var("word", name)), Word(T.var("word", name))
            elif packed_kind(kind) is not None:                             # a word whose four low bytes are named; of the four above them nothing is said
                self.g[reg] = ("p", tuple((0, (b,)) for b in packed_kind(kind)) + tuple((0, (f"{name} byte {k}",)) for k in range(4, 8)))
                for b in packed_kind(kind): self.given[b] = Word(byte_term(T, (0, (b,))))
        for reg, kind, name in c.args:
            if kind in ("number", "byte", "any", "counter", "low byte", "word", "low word") or packed_kind(kind) is not None: continue
            self.g[reg] = ("a", name, 0)
            if lanes_kind(kind, "inputs") is not None:
                # a table of addresses, each of an input of n blocks of 64 bytes, all given to read. The blocks
                # lie in memory one after another, so 64 * n is below 2^64.
                lanes = lanes_kind(kind, "inputs")
                if name in c.writes or any(lanes_kind(k, "inputs") is not None for _, k, other in c.args if other != name): raise Fail(f"{c.name}: {name} is {kind}: one table of inputs, given to read")
                self.mem[name] = {0: (None, kind, kspec.Inputs(lanes))}; self.given[name] = kspec.Inputs(lanes); self.readonly.add(name)
                for i in range(lanes): self.mem[(name, i)] = {0: (None, "blocks", kspec.Blocks(i))}; self.readonly.add((name, i))
                self.facts.add(WORD64 - self.given["n"].scale(64))
                continue
            n = bytes_kind(kind)
            if kind == "cvs": v = None                                      # made below, when everything else it speaks of is
            elif kind == "block": v = [Word(T.mk("part", name, w)) for w in range(16)]
            elif lanes_kind(kind, "cvs") is not None:                       # chaining values the function leaves: of what is there before nothing is said
                if name not in c.writes: raise Fail(f"{c.name}: {name} is {kind}, and the contract does not say what is left there")
                v = [[Word(T.mk("part", name, i, w)) for w in range(8)] for i in range(lanes_kind(kind, "cvs"))]
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

    def A(self): return kspec.Symbols(self.T, self.facts, self.memo, self.ghost)

    def rested(self):
        """A copy at rest where it is (at a place): a path from it ends when it comes there again."""
        c = self.clone(); c.rest = c.steps
        return c

    def floor(self):
        """The lowest place of the frame (from the entry stack pointer) that is the function's to read and write:
        the stack pointer, or where it was when it was rounded down to a 64-byte boundary."""
        return self.g["rsp"][2] if self.wide is None else self.wide

    def top(self):
        """The stack pointer for a push, a pop or a call: in the frame as it was at entry, not in the part on a 64-byte boundary."""
        if self.wide is not None: raise Fail("a push, a pop or a call with the stack pointer in the frame on a 64-byte boundary")
        return self.g["rsp"]

    def cell(self, off, size):
        """Bytes of the frame on a 64-byte boundary: within what the stack pointer has given."""
        if self.wide is None or not isinstance(off, int) or off < self.g["rsp"][2] or off + size > 0: raise Fail(f"{size} bytes at {off} of the frame on a 64-byte boundary: outside it")

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
                if size == 4 and isinstance(off, int) and off % 4 == 0 and 0 <= off < 4 * len(v): return ("t", v[off // 4].v)
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
            elif lanes_kind(kind, "cvs") is not None:
                # sixteen words: two chaining values, as they lie one after another
                if size == 64 and isinstance(v, list) and isinstance(off, int) and off % 64 == 0 and 0 <= off and off + 64 <= 32 * len(v) and isinstance(new, tuple) and len(new) == 16:
                    out = list(v); out[off // 32], out[off // 32 + 1] = [Word(t) for t in new[:8]], [Word(t) for t in new[8:]]
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
        if region == "rodata":
            if size != 4 or not isinstance(off, int) or off < 0 or off + 4 > len(self.data): raise Fail(f"a read of {size} bytes at {off} of the file's read-only data")
            return ("n", int.from_bytes(self.data[off:off + 4], "little"))
        if region == "wide":
            self.cell(off, size)
            if size != 64 or off % 64 or off not in self.mem["wide"]: raise Fail(f"a read of {size} bytes at {off} of the frame on a 64-byte boundary: no sixteen words were written there")
            return self.mem["wide"][off]
        if region == "frame" and (isinstance(off, Lin) or off < self.floor()): raise Fail(f"a read below the stack pointer or at an unknown place of the frame, at {off}")
        hit = self.within(region, off, size)
        if hit is None: raise Fail(f"a read of {size} bytes at {region} + {off}: nothing was written there")
        o, (_, kind, v) = hit
        if isinstance(v, kspec.Inputs):
            # the table of a kernel's inputs: one of its addresses
            if size == 8 and isinstance(off, int) and off % 8 == 0 and 0 <= off < 8 * v.lanes: return ("a", (region, off // 8), 0)
            raise Fail(f"a read of {size} bytes at {region} + {off}: not one of the table's addresses")
        if isinstance(v, kspec.Blocks):
            # a block of a lane's input, one of the n the contract gives: sixteen words
            block = Lin.of(off).over(64)
            if size != 64 or block is None or not self.facts.ge0(block) or not self.facts.ge0(self.given["n"] - block - 1): raise Fail(f"a read of {size} bytes at {region} + {off}: not a block of the input")
            return tuple(self.T.var("input", v.lane, plain(block), w) for w in range(16))
        return self.read_in(kind, v, plain(Lin.of(off) - o), size, f"{region} + {off}")

    def store(self, region, off, size, new):
        where = f"{region} + {off}"
        if region == "wide":
            self.cell(off, size)
            if size == 1 and new == ("n", 0) and off - off % 64 not in self.mem["wide"]: return        # a zero byte where nothing is yet: the stack is touched before it is used
            if size != 64 or off % 64 or not isinstance(new, tuple) or len(new) != 16: raise Fail(f"a write of {size} bytes at {off} of the frame on a 64-byte boundary: not sixteen words at a cell")
            self.mem["wide"][off] = new; return
        if region in self.readonly: raise Fail(f"a write to {region}, which the contract gives to read")
        if region != "frame":
            if region not in self.mem: raise Fail(f"an address in {region}: no such memory")
            n, kind, v = self.mem[region][0]
            self.mem[region][0] = (n, kind, self.write_in(kind, v, off, size, new, where)); return
        if isinstance(off, Lin): raise Fail(f"a write at {where}")
        if off < self.floor() or off + size > 0: raise Fail(f"a write at {off} from the entry stack pointer: outside the function's own frame")
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
        if off < self.floor() or off + size > 0: raise Fail(f"a callee leaves a {kind} at {off} from the entry stack pointer: outside the function's own frame")
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
    def address(self, base, disp, index=None):
        b = self.g[base.lstrip(".")]
        if b[0] != "a": raise Fail(f"an address from {base} = {b}")
        off = Lin.of(b[2]) + signed(num(disp))
        if index is not None:
            i = lin(self.g[index.lstrip(".")])
            if i is None: raise Fail(f"an index that is not a number: {index} = {self.g[index.lstrip('.')]}")
            off = off + i
        return b[1], plain(off)

    def halves(self, r):
        if r not in self.x: raise Fail(f"xmm{r} read before it is written")
        return self.x[r][:4]

    def lanes(self, r):
        v = self.halves(r)
        if any(isinstance(t, tuple) for t in v): raise Fail(f"xmm{r} holds half of a rotation")
        return v

    def vec(self, r):
        if len(self.x.get(r, ())) != 16: raise Fail(f"zmm{r} read before all of it is written")
        return self.x[r]

    def low32(self, v):
        """The low 32 bits of what a register holds, zeros above them."""
        if v[0] == "n": return ("n", v[1] & 0xFFFFFFFF)
        if v[0] == "p": return ("p", tuple(v[1][:4]) + (0,) * 4)
        if v[0] == "pair": return ("t", v[1])
        if v[0] in ("t", "z"): return v
        raise Fail(f"the low 32 bits of {v}")

    def word(self, o):
        """An operand as a 32-bit term: a word of memory, a number, the low 32 bits of a register."""
        v = self.load(*self.address(o[1], o[2]), 4) if o[0] == ".mem" else self.low32(self.operand(o))
        if v[0] == "t": return v[1]
        if v[0] == "n": return self.T.const(v[1])
        if v[0] == "p" and all(b == 0 for b in v[1][1:]): return byte_term(self.T, v[1][0])
        raise Fail(f"a word from {v}")

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
            # a word below 2^32 and a word moved up 32 bits: the two side by side, nothing carried
            if op == "add" and x[0] == "t" and y[0] == "pair" and self.T.nodes[y[1]] == ("c", 0): return ("pair", x[1], y[2])
            # bytes beside bytes: where one has a byte the other has zero, nothing is carried
            if op == "add" and x[0] == "p" and y[0] == "p" and all(p == 0 or q == 0 for p, q in zip(x[1], y[1])): return ("p", tuple(q if p == 0 else p for p, q in zip(x[1], y[1])))
            if x[0] == "a" and lin(y) is not None: return ("a", x[1], plain(Lin.of(x[2]) + (lin(y) if op == "add" else -lin(y))))
            if op == "add" and y[0] == "a" and lin(x) is not None: return ("a", y[1], plain(Lin.of(y[2]) + lin(x)))
            if lin(x) is not None and lin(y) is not None: return self.number(lin(x) + lin(y) if op == "add" else lin(x) - lin(y))
        elif op == "shl":
            if x[0] in ("t", "lowt") and y[1] == 32: return ("pair", self.T.const(0), x[1])              # a word moved up 32 bits: what was above it is gone
            if x[0] == "p" and y[1] % 8 == 0 and 0 <= y[1] < 64: return ("p", (0,) * (y[1] // 8) + tuple(x[1][:8 - y[1] // 8]))      # by whole bytes
            if lin(x) is not None and 0 <= y[1] < 32: return self.number(lin(x).scale(1 << y[1]))
        elif op == "shr":
            if x[0] == "n": return ("n", x[1] >> y[1])
            if x[0] == "pair" and y[1] == 32: return ("t", x[2])                # a counter's high word
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
        kind, x = self.flags[0], self.flags[1]
        if kind == "numbers":
            if op in (".je", ".jne"):
                z = self.facts.zero(x)
                if z is None: raise Fork("zero", x)
                return z == (op == ".je")
            # (counting down and `test` leave the carry flag as it was, or clear it: their flags say whether the number is zero, and no more)
            if len(self.flags) > 2: raise Fail("an order asked of flags that say only whether a number is zero")
            ge = True if self.facts.ge0(x) else False if self.facts.ge0(-x - 1) else None      # unsigned: both sides are whole numbers not below zero
            if ge is None: raise Fork("ge", x)
            return ge == (op == ".jae")
        if op not in (".je", ".jne"): raise Fail("an order asked of something that is not a number")
        if x not in self.conds: raise Fork("cond", x)
        return self.conds[x] == (op == ".je")

    # -- calls
    def call(self, name):
        T, sp = self.T, self.top()[2]
        only = self.contract.calls.get(name)
        if only is not None and self.conds.get(only) is not True: raise Fail(f"{name} is called on a path that does not say {only[0]} is {only[1]}")
        A = self.A()
        try:
            c = contract(name)
            self.needed(name, c)
            if one_block(name) is not None: used = self.call_kernel(A, name, one_block(name))
            else: used = self.call_contract(A, name, c)
        except Err as e: raise Fail(f"a call of {name}: {e}")
        # the facts a callee's contract adds cannot make the path's facts hold falsely together: such a path
        # would be dropped as no path, and what the code did after the call never checked (November 17, 2026:
        # it was, until a caller that had been shown the contract of a callee with contradictory `ensures`)
        if not self.facts.consistent():
            raise Fail(f"a call of {name}: what it ensures, with what it is given here, cannot all hold: its contract says nothing of this path")
        self.low = min(self.low, sp - used)
        self.left()

    def left(self):
        """After a call: each register a callee may change holds an unknown of its own (the result too, where the
        contract says nothing of it); the vector registers and the flags hold nothing."""
        self.calls += 1
        for r in G64:
            if (r not in KEPT and r not in ("rsp", "rax")) or (r == "rax" and self.g[r] == ("q", "left by a call")): self.g[r] = ("q", f"left in {r} by call {self.calls}")
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

    def no_overlap(self, name, written, others):
        """What a callee writes overlaps nothing else it is given the address of: its own check took
        it so. (region, offset, bytes); things of different regions do not overlap."""
        for region, off, size in written:
            for r, o, n in others:
                if r != region: continue
                if isinstance(off, Lin) or isinstance(o, Lin) or isinstance(size, Lin) or isinstance(n, Lin) or size is None or n is None:
                    raise Fail(f"{name}: what it writes and something else it is given are both in {region}, and are not shown to have no byte in common")
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
        if b - a > 64: raise Fail(f"{name}: {b - a} values asked of, one by one: more than this verifier takes")
        for i in range(a, b): one(i)

    def call_kernel(self, A, name, k):
        """(cv, block, length, counter, flags): the 32 bytes at cv become compress(cv, the 64 bytes at block,
        counter, length, flags). Where the kernel reads the length and the flags from is its contract's."""
        cv, block, length, counter, flags = (self.g[r] for r in ARGS[:5])
        if cv[0] != "a" or block[0] != "a": raise Fail(f"{name} called with something that is not an address")
        self.no_overlap(name, [(cv[1], cv[2], 32)], [(block[1], block[2], 64)])
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

    def lessens(self, A, name, c, env):
        """A call of the function by itself: the number its contract says decreases is less than it was. (So
        the calls of itself come to an end: with every loop bounded, the function returns if what else it calls
        does.)"""
        if c.text["decreases"] is None: raise Fail(f"{name} calls itself, and its contract names no number that decreases")
        try:
            mine, its = Lin.of(kspec.SPEC.eval(self.A(), c.text["decreases"], dict(self.given))), Lin.of(kspec.SPEC.eval(A, c.text["decreases"], env))
        except Err as e: raise Fail(f"{name}: the number that decreases cannot be read: {e}")
        if not self.facts.ge0(its) or not self.facts.ge0(mine - 1 - its): raise Fail(f"{name} calls itself with {its}, not shown to be less than {mine}")

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
        for arg in c.writes: self.no_overlap(name, spans[arg], [s for other, ss in spans.items() if other != arg for s in ss])
        env = Env(v, later)
        if name == self.contract.name: self.lessens(A, name, c, env)
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
                    frozen, facts, memo = dict(env), self.facts.clone(), dict(self.memo)
                    def lane(i, leaf=leaf, frozen=frozen, facts=facts, memo=memo):
                        # a lane's value, when something reads it: from what the kernel was given at the call,
                        # and by the facts as they were at the call (a later path's facts are not asked)
                        return kspec.SPEC.eval(kspec.Symbols(self.T, facts.clone(), dict(memo)), leaf["expr"], dict(frozen, **{leaf["index"]: i}))
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
            if a[0] == "8" and a[1] == [".reg", ".rax"] and a[2][0] == ".imm": self.g["rax"] = ("al", num(a[2][1]) & 0xFF)      # a count put in AL
            elif a[0] == "8":
                if a[1][0] != ".mem" or a[2][0] not in (".reg", ".imm"): raise Fail("a move of a byte that is not from a register or a number to memory")
                self.store(*self.address(a[1][1], a[1][2]), 1, self.g[a[2][1].lstrip(".")] if a[2][0] == ".reg" else ("n", num(a[2][1]) & 0xFF))
            elif a[0] == "32":
                if a[1][0] != ".reg": raise Fail("a move of 32 bits that is not into a register")
                self.g[a[1][1].lstrip(".")] = self.low32(self.load(*self.address(a[2][1], a[2][2]), 4) if a[2][0] == ".mem" else self.operand(a[2]))
            elif a[0] == "64":
                v = self.operand(a[2])
                if a[1][0] == ".reg": self.g[a[1][1].lstrip(".")] = v
                else: self.store(*self.address(a[1][1], a[1][2]), 8, v)
            else: raise Fail("a move that is not of 64 bits, of 32 or of a byte")
        elif op == ".movzx8":
            if a[1][0] == ".reg":                                           # a register's low byte, zeros above it
                src = self.g[a[1][1].lstrip(".")]
                if src[0] == "low": self.g[a[0].lstrip(".")] = ("p", ((0, (src[1],)),) + (0,) * 7)
                elif src[0] == "p": self.g[a[0].lstrip(".")] = ("p", (src[1][0],) + (0,) * 7)
                else: raise Fail(f"the low byte of {src}")
            elif a[1][0] != ".mem": raise Fail("a byte that is not from memory or a register")
            else: self.g[a[0].lstrip(".")] = self.load(*self.address(a[1][1], a[1][2]), 1)
        elif op == ".and" and self.BOUNDARY and a[0] == "64" and a[1] == [".reg", ".rsp"] and a[2][0] == ".imm" and num(a[2][1]) == WORD64 - 63:
            # the stack pointer rounded down to a 64-byte boundary: from here it is in a part of the frame of its
            # own ("wide"), whose top is 0 to 63 bytes below where the stack pointer was
            self.wide = self.top()[2]; self.g["rsp"] = ("a", "wide", 0); self.mem["wide"] = {}; self.flags = None
        elif op in (".or", ".and") and a[0] == "32":
            # of 32 bits, zeros above: bytes or-ed, or a register's low byte taken
            if a[1][0] != ".reg" or a[2][0] != (".reg" if op == ".or" else ".imm"): raise Fail(f"{op} of 32 bits that is not of two registers, or of a register and a number")
            r = a[1][1].lstrip("."); x = self.low32(self.g[r])
            if op == ".or": self.g[r] = self.arith("or", x, self.low32(self.operand(a[2])))
            elif num(a[2][1]) != 0xFF or x[0] not in ("n", "p"): raise Fail(f"an and of {x} that does not take its low byte")
            else: self.g[r] = ("n", x[1] & 0xFF) if x[0] == "n" else ("p", (x[1][0],) + (0,) * 7)
            self.flags = None
        elif op in (".add", ".sub", ".or", ".and"):
            if a[0] != "64" or a[1][0] != ".reg": raise Fail(f"{op} that is not of 64 bits into a register")
            r = a[1][1].lstrip(".")
            self.g[r] = self.arith(op[1:], self.g[r], self.operand(a[2])); self.flags = None
        elif op == ".xor":
            if a[1][0] != ".reg" or a[1] != a[2]: raise Fail("an xor that is not of a register with itself")
            self.g[a[1][1].lstrip(".")] = ("n", 0); self.flags = None
        elif op == ".test":
            # a register with itself: is the number it holds zero?
            if a[1][0] != ".reg" or a[1] != a[2]: raise Fail("a test that is not of a register with itself")
            v = self.g[a[1][1].lstrip(".")] if a[0] == "64" else self.low32(self.g[a[1][1].lstrip(".")])
            if lin(v) is None: raise Fail(f"a test of {v}")
            self.flags = ("numbers", lin(v), "zero")
        elif op == ".lea_data": self.g[a[0].lstrip(".")] = ("a", "rodata", num(a[1]))            # the address of the file's read-only data, so many bytes in
        elif op == ".shr32":
            r, n = a[0].lstrip("."), num(a[1]); v = self.low32(self.g[r])
            if v[0] == "n" and 0 <= n < 32: self.g[r] = ("n", v[1] >> n)
            elif v[0] == "p" and n in (8, 16, 24): self.g[r] = ("p", v[1][n // 8:4] + (0,) * (4 + n // 8))
            else: raise Fail(f"{v} shifted right by {n}")
            self.flags = None
        elif op in (".dec64", ".dec32"):
            # one less: a number that stays one (a count of turns), and the branch after it asks whether it is zero
            r = a[0].lstrip("."); v = self.g[r] if op == ".dec64" else self.low32(self.g[r])
            if lin(v) is None: raise Fail(f"one taken from {v}")
            self.g[r] = self.number(lin(v) - 1) if op == ".dec64" else ("n", (v[1] - 1) & 0xFFFFFFFF)
            self.flags = ("numbers", lin(self.g[r]), "zero")
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
        elif op == ".xstoreu": self.store(*self.address(a[0], a[1]), 16, self.lanes(int(a[2])))
        elif op == ".xconst": self.x[int(a[0])] = tuple(self.T.const(num(w)) for w in a[1:5])
        elif op == ".xmov": self.x[int(a[0])] = self.halves(int(a[1]))
        elif op in (".xpslld", ".xpsrld"):
            n = int(a[2])
            if not 0 < n < 32: raise Fail("a shift by nothing, or by the word's width")
            self.x[int(a[0])] = tuple(("shl" if op == ".xpslld" else "shr", t, n) for t in self.lanes(int(a[1])))
        elif op == ".xpor":
            # the two halves of a rotation: (x << (32 - n)) | (x >> n)
            out = []
            for p, q in zip(self.halves(int(a[1])), self.halves(int(a[2]))):
                if not (isinstance(p, tuple) and isinstance(q, tuple)): raise Fail("an or that is not of a rotation's halves")
                if p[0] == "shr": p, q = q, p
                if not (p[0] == "shl" and q[0] == "shr" and p[1] == q[1] and p[2] + q[2] == 32): raise Fail("an or that is not of a rotation's halves")
                out.append(self.T.ror(q[1], q[2]))
            self.x[int(a[0])] = tuple(out)
        elif op == ".xpshufb":
            # a shuffle of bytes by a constant that rotates each word's bytes: a rotation of each word by whole bytes
            src, mask, out = self.lanes(int(a[1])), self.lanes(int(a[2])), []
            for lane, m in enumerate(mask):
                k = self.T.nodes[m]
                if k[0] != "c": raise Fail("a shuffle of bytes by something that is not a constant")
                idx = [(k[1] >> (8 * j)) & 0xFF for j in range(4)]
                r = idx[0] - 4 * lane
                if not 0 <= r < 4 or any(idx[j] != 4 * lane + (r + j) % 4 for j in range(4)): raise Fail("a shuffle of bytes that is not a rotation of each word")
                out.append(self.T.ror(src[lane], 8 * r) if r else src[lane])
            self.x[int(a[0])] = tuple(out)
        elif op == ".xpblendw":
            # by 16-bit halves: both halves of a word from one source, or this is no blend of words
            x, y, n = self.lanes(int(a[1])), self.lanes(int(a[2])), int(a[3])
            if any(((n >> (2 * j)) & 3) not in (0, 3) for j in range(4)): raise Fail("a blend that splits a word")
            self.x[int(a[0])] = tuple(y[j] if (n >> (2 * j)) & 1 else x[j] for j in range(4))
        elif op == ".xmovq":
            # the low 64 bits from a general register, zero above: a counter's two words; or bytes, each word a byte with zeros above it
            v, T = self.g[a[1].lstrip(".")], self.T
            if v[0] == "pair": self.x[int(a[0])] = (v[1], v[2], T.const(0), T.const(0))
            elif v[0] == "p":
                if any(b != 0 for k, b in enumerate(v[1]) if k % 4): raise Fail(f"a register moved to a vector register whose words are not each a byte: {v}")
                self.x[int(a[0])] = tuple(T.const(b) if isinstance(b, int) else byte_term(T, b) for b in (v[1][0], v[1][4])) + (T.const(0), T.const(0))
            else: raise Fail(f"a general register moved to a vector register: {v}")
        elif op in (".xpaddd", ".xpxor"):
            x, y = self.lanes(int(a[1])), self.lanes(int(a[2]))
            self.x[int(a[0])] = tuple((self.T.add if op == ".xpaddd" else self.T.xor)(p, q) for p, q in zip(x, y))
        elif op == ".xprord":
            if not 0 < int(a[2]) < 32: raise Fail("a rotation by nothing, or by the word's width")
            self.x[int(a[0])] = tuple(self.T.ror(t, int(a[2])) for t in self.lanes(int(a[1])))
        elif op == ".xpshufd":
            s, n = self.lanes(int(a[1])), int(a[2]); self.x[int(a[0])] = tuple(s[(n >> (2 * j)) & 3] for j in range(4))
        elif op == ".xshufps":
            x, y, n = self.lanes(int(a[1])), self.lanes(int(a[2])), int(a[3])
            self.x[int(a[0])] = (x[n & 3], x[(n >> 2) & 3], y[(n >> 4) & 3], y[(n >> 6) & 3])
        elif op == ".xpunpcklqdq": x, y = self.lanes(int(a[1])), self.lanes(int(a[2])); self.x[int(a[0])] = (x[0], x[1], y[0], y[1])
        elif op == ".xpunpckldq": x, y = self.lanes(int(a[1])), self.lanes(int(a[2])); self.x[int(a[0])] = (x[0], y[0], x[1], y[1])
        elif op == ".xpunpckhdq": x, y = self.lanes(int(a[1])), self.lanes(int(a[2])); self.x[int(a[0])] = (x[2], y[2], x[3], y[3])
        elif op == ".xpblendd":
            # of 128 bits the processor reads the mask's low four bits
            x, y, n = self.lanes(int(a[1])), self.lanes(int(a[2])), int(a[3]) & 15
            self.x[int(a[0])] = tuple(y[j] if (n >> j) & 1 else x[j] for j in range(4))
        elif op == ".vzeroupper":                                           # ZMM0 to ZMM15 cleared above bit 127
            for r in range(16):
                if r in self.x: self.x[r] = self.x[r][:4]
        elif op == ".zbroadcast": self.x[int(a[0])] = (self.word(a[1]),) * 16
        elif op == ".zmov": self.x[int(a[0])] = self.vec(int(a[1]))
        elif op in (".zload", ".zloadi", ".zstore"):
            # sixty-four bytes as sixteen words. An aligned one faults off a 64-byte boundary: taken only in the frame on one.
            if op == ".zloadi": aligned, r, at = False, int(a[0]), self.address(a[1], a[3], a[2])
            elif op == ".zload": aligned, r, at = a[0] == "true", int(a[1]), self.address(a[2], a[3])
            else: aligned, r, at = a[0] == "true", int(a[3]), self.address(a[1], a[2])
            if aligned and at[0] != "wide": raise Fail(f"an aligned read or write of 64 bytes at {at[0]} + {at[1]}: not known to be on a 64-byte boundary")
            if op == ".zstore": self.store(*at, 64, self.vec(r))
            else: self.x[r] = self.load(*at, 64)
        elif op == ".zpadddm":                                              # a sum with sixteen words of memory
            x, y = self.vec(int(a[1])), self.load(*self.address(a[2], a[4], a[3]), 64)
            self.x[int(a[0])] = tuple(self.T.add(p, q) for p, q in zip(x, y))
        elif op == ".zpadddc":                                              # a sum with sixteen numbers
            self.x[int(a[0])] = tuple(self.T.add(p, self.T.const((num(a[2]) >> (32 * k)) & 0xFFFFFFFF)) for k, p in enumerate(self.vec(int(a[1]))))
        elif op == ".zpcmpud":                                              # a mask: where the first's word is below the second's
            if int(a[3]) != 1: raise Fail("a comparison other than less-than")
            self.x[("k", int(a[0]))] = tuple(self.T.ult(p, q) for p, q in zip(self.vec(int(a[1])), self.vec(int(a[2]))))
        elif op == ".zpaddd_k":                                             # a sum where the mask says so; the word that was there elsewhere
            if ("k", int(a[1])) not in self.x: raise Fail(f"k{a[1]} read before it is written")
            d, k, x, y = self.vec(int(a[0])), self.x[("k", int(a[1]))], self.vec(int(a[2])), self.vec(int(a[3]))
            self.x[int(a[0])] = tuple(self.T.ite(c, self.T.add(p, q), old) for c, p, q, old in zip(k, x, y, d))
        elif op in (".zpaddd", ".zpxord"):
            if op == ".zpxord" and a[1] == a[2]: self.x[int(a[0])] = (self.T.const(0),) * 16         # a register with itself: zero, whatever it held
            else:
                x, y = self.vec(int(a[1])), self.vec(int(a[2]))
                self.x[int(a[0])] = tuple((self.T.add if op == ".zpaddd" else self.T.xor)(p, q) for p, q in zip(x, y))
        elif op == ".zprord":
            if not 0 < int(a[2]) < 32: raise Fail("a rotation by nothing, or by the word's width")
            self.x[int(a[0])] = tuple(self.T.ror(t, int(a[2])) for t in self.vec(int(a[1])))
        elif op in (".zunpckldq", ".zunpckhdq", ".zunpcklqdq", ".zunpckhqdq"):
            # within each quarter of the register (four words)
            x, y = self.vec(int(a[1])), self.vec(int(a[2]))
            pick = {".zunpckldq": lambda q: (x[q], y[q], x[q + 1], y[q + 1]), ".zunpckhdq": lambda q: (x[q + 2], y[q + 2], x[q + 3], y[q + 3]),
                    ".zunpcklqdq": lambda q: (x[q], x[q + 1], y[q], y[q + 1]), ".zunpckhqdq": lambda q: (x[q + 2], x[q + 3], y[q + 2], y[q + 3])}[op]
            self.x[int(a[0])] = sum((pick(q) for q in (0, 4, 8, 12)), ())
        elif op == ".zshufi32x4":
            # quarters picked: two of the first register, then two of the second
            x, y, n = self.vec(int(a[1])), self.vec(int(a[2])), int(a[3])
            quarter = lambda v, q: v[4 * q:4 * q + 4]
            self.x[int(a[0])] = quarter(x, n % 4) + quarter(x, n // 4 % 4) + quarter(y, n // 16 % 4) + quarter(y, n // 64 % 4)
        elif op == ".decb":
            # a count kept in AL, counted down: a plain number, so the branch after it is decided
            r = a[0].lstrip("."); v = self.g[r]
            if v[0] != "al": raise Fail("a byte counted down that no number was put in")
            n = (v[1] - 1) & 0xFF; self.g[r] = ("al", n); self.flags = ("numbers", Lin.of(n), "zero")
        elif op == ".push":
            if a[0] == ".rsp": raise Fail("a push of the stack pointer")
            sp = self.top()
            self.g["rsp"] = ("a", "frame", sp[2] - 8); self.low = min(self.low, sp[2] - 8)
            self.store("frame", sp[2] - 8, 8, self.g[a[0].lstrip(".")])
        elif op == ".pop":
            if a[0] == ".rsp": raise Fail("a pop into the stack pointer")
            sp = self.top()
            self.g[a[0].lstrip(".")] = self.load("frame", sp[2], 8); self.g["rsp"] = ("a", "frame", sp[2] + 8)
        elif op == ".call": self.call(a[0])
        elif op == ".ret":
            if self.g["rsp"] != ("a", "frame", 0) or self.mem["frame"].get(0) != (8, "q", ("q", "return address")): raise Fail("a return to somewhere else")
            nxt = None
        else: raise Fail(f"an instruction this verifier does not know: {' '.join(map(str, i))}")
        if nxt is not None and nxt <= self.pc:
            self.back[nxt] = self.back.get(nxt, 0) + 1
            if self.back[nxt] > TURNS: raise Fail(f"a loop has turned {TURNS} times on one path: not a loop this verifier runs")
        # Whatever instruction it was: the stack pointer is in the function's own frame, a plain number of bytes
        # not above where it was at entry. (A push, a pop, a call and a write through it are then where this
        # machine takes them to be; the stack used is counted from wherever it is.)
        sp = self.g["rsp"]
        if self.wide is not None and sp[0] == "a" and sp[1] == "frame": self.wide = None; del self.mem["wide"]         # back in the frame as it was: the part on the boundary is given up
        if sp[0] != "a" or sp[1] != ("frame" if self.wide is None else "wide") or not isinstance(sp[2], int) or sp[2] > 0: raise Fail(f"the stack pointer leaves the function's own frame: {sp}")
        self.low = min(self.low, sp[2] if self.wide is None else self.wide - 63 + sp[2])
        # Nothing is remembered of the stack below the stack pointer: a call writes there (its return address, the
        # callee's own frame), and so may whatever interrupts the program.
        floor = self.floor()
        for o in [o for o in self.mem["frame"] if o < floor]: del self.mem["frame"][o]
        if self.wide is not None:
            for o in [o for o in self.mem["wide"] if o < sp[2]]: del self.mem["wide"][o]
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
    raise Fail(f"the low byte of {v}: not a byte this verifier follows")


def paths(m, budget, head=None):
    """Every path of m to the return, or to the instruction at `head` once it has run at least one instruction.
    `budget`: a list of one number, the instructions that may still be run."""
    ends, work = [], [m]
    while work:
        m = work.pop()
        while True:
            if m.pc is None or (m.pc == head and m.steps > m.rest): ends.append(m); break
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
# The verifier.
def returned(e, c, where):
    """At a return: what the contract says is left and returned, the registers a callee keeps, the stack."""
    A = e.A()
    left = {}
    for leaf in c.text["leaves"]:
        name = leaf["name"]
        wrong = None
        try:
            if leaf["index"] is not None:
                # each of the chaining values at the address
                for i in range(lanes_kind(c.kind[name], "cvs")):
                    want = kspec.SPEC.eval(A, leaf["expr"], dict(e.given, **{leaf["index"]: i}))
                    if not kspec.same(A, e.view(name, 32 * i, "cv"), want): wrong = f"{name}[{i}]"; break
            else:
                want = kspec.SPEC.eval(A, leaf["expr"], dict(e.given))
                n = bytes_kind(c.kind[name])
                if not kspec.same(A, e.view(name, 0, c.kind[name], e.given.get(n) if isinstance(n, str) else n), want): wrong = name
        except Err as err: raise Fail(f"{where}: the specification cannot be followed on this path: {err}")
        if wrong is not None: raise Fail(f"{where}: {wrong} at the return is not what the contract says")
        if leaf["index"] is None: left[name] = want
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


# ---------------------------------------------------------------------------------------------------------
# A loop whose count the path does not fix: a PLACE, and what holds there after any number of turns.
#
# The contract leaves, a lane, the last value of a sequence of the specification
# (`ensures out[i] = chunk(...) for i in 0..16`, where `sequence chunk(...) { h[0] = ...  h[b + 1] = ...  for b in 0..n }`).
# The proof names one instruction, the PLACE, which the code passes once a turn, and says what the registers
# hold there when b turns are done (1 <= b <= n - 1):
#     "keep"                what it held when the code first came back to the place (after the first turn)
#     {"lin": {...}}        a number that moves with b: c + cn*n + cb*b
#     {"cv": [lane, w]}     (a ZMM register) word w of the sequence's value h[b], for sixteen lanes from `lane`
#     (not named)           anything: the code must not read it before writing it
# The memory is as it was at that first coming back; of the frame on a 64-byte boundary only the cells the proof names.
#   base   the code is run from its entry to the place and once around (the first turn may differ from the
#          others). Where that returns, n is 1 and what is left is h[1]. Where it comes back, n is at least 2,
#          and the place holds what the proof says for b = 1 and h[1].
#   step   from the place as the proof says, for an unknown b with 1 <= b <= n - 1 and an unknown h[b], every
#          path is run to the place again or to the return. At the place again: b + 1 <= n - 1, and it holds
#          what the proof says for b + 1 and h[b + 1] (one turn of the sequence, as the specification writes
#          it, on that path's facts). At the return: b was n - 1, and what the contract says is left is there,
#          the sequence's last value being h[b + 1].
# So for every n the function leaves h[n]; and the place is passed at most n times, so the loop ends.
TURN = sym("turns done at the place")       # (no argument has this name)


class Turns:
    """The sequence whose last values a contract leaves, a lane each, on a machine's path."""
    def __init__(self, c):
        if len(c.text["leaves"]) != 1 or c.text["leaves"][0]["index"] is None or c.text["returns"] is not None: raise Fail(f"{c.name}: a place is of a function that leaves one thing: the last value of a sequence, a lane")
        self.leaf = c.text["leaves"][0]
        e = self.leaf["expr"]
        if e[0] != "call" or e[1] not in kspec.SPEC.machines: raise Fail(f"{c.name}: what it leaves a lane is not the last value of a sequence")
        self.name, self.m, self.args, self.lanes = e[1], kspec.SPEC.machines[e[1]], e[2], lanes_kind(c.kind[self.leaf["name"]], "cvs")
        m = self.m
        if m["state"] is None or m["init"] is None or m["loop"][0] != "for" or m["loop"][2] != ("num", 0) or len(m["params"]) != len(self.args): raise Fail(f"{c.name}: {e[1]} is not a sequence counted from 0")

    def env(self, e, lane):
        """What the sequence is given for a lane, as the contract writes it."""
        A = e.A()
        given = dict(e.given, **{self.leaf["index"]: lane})
        return A, {p: kspec.SPEC.eval(A, x, given) for p, x in zip(self.m["params"], self.args)}

    def count(self, e, lane):
        A, env = self.env(e, lane)
        return Lin.of(kspec.SPEC.eval(A, self.m["loop"][3], env))

    def first(self, e, lane):
        A, env = self.env(e, lane)
        return kspec.terms(kspec.SPEC.eval(A, self.m["init"], env))

    def turn(self, e, lane, state, b):
        """h[b + 1] from h[b] = `state`: one turn, as the specification writes it. What it asks of b and n the path's facts answer: the code must have asked too."""
        A, env = self.env(e, lane)
        env[self.m["state"]], env[self.m["loop"][1]] = kspec.words(state), plain(b)
        return kspec.terms(kspec.SPEC.turn(A, self.name, env))

    def instance(self, e, lane):
        """The lane's sequence, as kspec.py knows it where the specification speaks of its last value."""
        A, env = self.env(e, lane)
        env[self.m["state"]] = kspec.SPEC.eval(A, self.m["init"], env)
        return (self.name, tuple(A.key(env[p]) for p in self.m["params"]), A.key(kspec.SPEC.state_of(self.m, env)))


def held(seen, proof, c, b, state):
    """What the proof says the place holds with b turns done and the sequence's values `state` (eight words a
    lane): the registers it names, the ZMM registers, the cells of the frame on a 64-byte boundary (by their
    place from the stack pointer). `seen`: the machine at its first coming back to the place."""
    g, x, wide = {}, {}, {}
    whole = lambda k: type(k) is int                    # (a proof is text from outside: a number in it is a whole number, or it is refused)
    numbers = {name for _, kind, name in c.args if kind == "number"}
    if "b" in numbers: raise Fail(f"{c.name}: an argument is named b, the proof's name for the turns done")
    for r, what in proof["registers"].items():
        if r not in G64: raise Fail(f"the proof names a register that is none: {r}")
        if what == "keep": g[r] = seen.g[r]; continue
        if not isinstance(what, dict) or not isinstance(what.get("lin"), dict) or not all(whole(k) for k in what["lin"].values()): raise Fail(f"the proof's word for {r} is neither keep nor a number that moves with the turns")
        d = Lin.of(what["lin"].get("1", 0)) + Lin.of(b).scale(what["lin"].get("b", 0))
        for name, k in what["lin"].items():
            if name in ("1", "b"): continue
            if name not in numbers: raise Fail(f"the proof's number for {r} speaks of {name}, which is no number among the arguments")
            d = d + sym(name).scale(k)
        g[r] = value(d)
    for r, what in proof["vectors"].items():
        r = int(r)
        if not 0 <= r < 32: raise Fail(f"the proof names a register that is none: zmm{r}")
        if what == "keep":
            if len(seen.x.get(r, ())) != 16: raise Fail(f"the proof keeps zmm{r}, which held nothing whole")
            x[r] = seen.x[r]
        else:
            if not isinstance(what, dict) or not isinstance(what.get("cv"), list) or len(what["cv"]) != 2 or not all(whole(k) for k in what["cv"]): raise Fail(f"the proof's word for zmm{r} is neither keep nor a word of the sequence's value")
            lane, w = what["cv"]
            if not (0 <= lane and lane + 16 <= len(state) and 0 <= w < 8): raise Fail(f"the proof's word for zmm{r} is none of the sequence's")
            x[r] = tuple(state[lane + k][w] for k in range(16))
    for off in proof["frame"]:
        at = seen.g["rsp"][2] + int(off)
        if seen.wide is None or at not in seen.mem["wide"]: raise Fail(f"the proof keeps the frame's cell at {off}, which held nothing")
        wide[at] = seen.mem["wide"][at]
    return g, x, wide


def at_place(seen, proof, c, b, state):
    """The machine at the place, holding what the proof says and nothing more."""
    m = seen.rested()
    g, x, wide = held(seen, proof, c, b, state)
    m.g = {r: g.get(r, ("q", f"whatever {r} holds at the place")) for r in G64}
    m.x, m.flags, m.back = x, None, {}
    if m.wide is not None: m.mem["wide"] = wide
    return m


def agrees(e, seen, proof, c, b, state, where):
    """A machine come to the place holds what the proof says, and its memory is as it was at the first coming back."""
    g, x, wide = held(seen, proof, c, b, state)
    for r, v in g.items():
        if e.g[r] != v and not (lin(e.g[r]) is not None and lin(v) is not None and e.facts.zero(lin(e.g[r]) - lin(v)) is True): raise Fail(f"{where}: {r} is {e.g[r]} at the place, the proof says {v}")
    for r, v in x.items():
        if e.x.get(r) != v: raise Fail(f"{where}: zmm{r} at the place is not what the proof says")
    if e.wide != seen.wide: raise Fail(f"{where}: the frame on a 64-byte boundary is not as it was")
    for at, v in wide.items():
        if e.mem["wide"].get(at) != v: raise Fail(f"{where}: the frame's cell at {at} is not kept")
    for region in set(e.mem) | set(seen.mem):
        if region == "wide": continue
        was, now = seen.mem.get(region), e.mem.get(region)
        if was is None or now is None or was.keys() != now.keys() or any(not (was[o] is now[o] or was[o] == now[o]) for o in was): raise Fail(f"{where}: what is at {region} is not as it was when the code first came back to the place")
    within(e, c, where)


def left(e, c, turns, state, where):
    """At a return: what the contract says is left, the sequence's last value being `state`, a lane each."""
    e.ghost = {turns.instance(e, lane): kspec.words(state[lane]) for lane in range(turns.lanes)}
    returned(e, c, where)


def check_place(rows, c, T, proof, entry, data):
    if type(proof["place"]) is not int or not all(isinstance(proof.get(part), dict) for part in ("registers", "vectors", "frame")): raise Fail("the proof is not a place and what the registers, the vector registers and the frame hold there")
    turns, head, budget = Turns(c), BASE + proof["place"], [STEPS]
    if head not in {a for a, _, _ in rows}: raise Fail("the place is at no instruction")
    lanes = range(turns.lanes)
    # base: from the entry to the place, and once around
    m = Machine(T, rows, c, data); m.pc = entry
    count = turns.count(m, 0)
    if any(turns.count(m, lane) != count for lane in lanes): raise Fail("the lanes' sequences are not of one length")
    ends = paths(m, budget, head)
    if len(ends) != 1 or ends[0].pc != head: raise Fail("from the entry the code does not come to the place by one path")
    first = ends[0]
    start = [turns.first(first, lane) for lane in lanes]
    around = paths(first.rested(), budget, head)
    back = [e for e in around if e.pc == head]
    if len(back) != 1: raise Fail("the first turn does not lead back to the place by one path")
    seen = back[0]
    for e in around:
        if e.pc is not None: continue
        if e.facts.zero(count - 1) is not True: raise Fail("base: the code returns after its first turn when there are more")
        left(e, c, turns, [turns.turn(e, lane, start[lane], 0) for lane in lanes], "after one turn")
    if not seen.facts.ge0(count - 2): raise Fail("base: the code comes back to the place after the last turn")
    agrees(seen, seen, proof, c, 1, [turns.turn(seen, lane, start[lane], 0) for lane in lanes], "base")
    # step: from the place with b turns done, 1 <= b <= count - 1, and any values of the sequence
    unknown = [tuple(T.var("state", lane, w) for w in range(8)) for lane in lanes]
    m = at_place(seen, proof, c, TURN, unknown)
    m.facts.add(TURN - 1); m.facts.add(count - TURN - 1)
    tally = {"place": 0, "return": len(around) - 1}
    for e in paths(m, budget, head):
        nxt = [turns.turn(e, lane, unknown[lane], TURN) for lane in lanes]
        if e.pc == head:
            if not e.facts.ge0(count - TURN - 2): raise Fail("step: the code comes back to the place after the last turn")
            agrees(e, seen, proof, c, TURN + 1, nxt, "step")
            tally["place"] += 1
        else:
            if e.facts.zero(count - TURN - 1) is not True: raise Fail("step: the code returns before the last turn")
            left(e, c, turns, nxt, "step")
            tally["return"] += 1
    if not tally["place"] or not tally["return"]: raise Fail("the step has no path back to the place, or the function none to the return")
    return dict(tally, widest=STEPS - budget[0])


def check(rows, name, proof=None, symbol=None, entry=None, data=b""):
    """The function's instructions meet its contract. `proof`: for a loop whose count the path does not fix, its
    place and what holds there; nothing for any other function. `entry`: where the function is entered, if
    not at its first instruction. `data`: the file's read-only data, where the function reads it."""
    global FRESH
    FRESH = itertools.count()               # the names given on the way are the same every time: a proof of the arithmetic speaks of them
    c, T = contract(symbol or "b3l_" + name), kterms.Terms()        # (`symbol`: a function that is not one of hash.ode's: a kernel)
    if proof is not None and "place" in proof: return check_place(rows, c, T, proof, rows[0][0] if entry is None else entry, data)
    if proof is not None and proof.get("places"): raise Fail("a proof with several places: this verifier takes one")
    m = Machine(T, rows, c, data); m.pc = rows[0][0] if entry is None else entry
    budget = [STEPS]
    ends = paths(m, budget)
    for e in ends: returned(e, c, "at a return")
    if not ends: raise Fail("no path returns")
    return {"return": len(ends), "place": 0, "widest": STEPS - budget[0]}


def find(rows, name):
    """What a prover would do here: there is nothing to find."""
    check(rows, name)
    return dict(function=name, places=[])


def load(obj, name, symbol=None):
    rows, _ = kdecode.read(obj, symbol or "b3l_" + name, BASE, DATA)
    kspec.fits(obj, symbol or "b3l_" + name)
    return rows


def load_from(obj, symbol, start):
    """(rows, the file's read-only data, where it is entered): a function that is entered at `symbol` and whose
    code begins at `start` (the 32-lane kernel has two ways in)."""
    rows, data = kdecode.read(obj, start, BASE, DATA)
    kspec.fits(obj, start, symbol)
    return rows, data, BASE + kdecode.address(obj, symbol) - kdecode.address(obj, start)


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
