#!/usr/bin/env python3
"""lemma_audit: an audit of the verifier's part for lemmas (kbyte.py's prove_lemmas), by changed lemmas.

    python3 lemma_audit.py [lz4 utf8 varint common frame blake3 ...] [--cases N] [--seed S] [--list]
    python3 lemma_audit.py ... --control N      the audit's own control: a verifier made wrong must be found out

A lemma is a step of a proof: the verifier shows it before it uses it. If it showed one that is not so, a
function could be "shown" by something false. The flips of the code's bits (audit.sh) do not ask that; this
does. For each lemma file it makes every changed copy of these kinds:

    a number in a clause one more or one less          a comparison made each other comparison
    + made - and - made +                              a `requires` left out
    one name of what the lemma is given made another, or 0, or 1
    the lemma made to require the impossible (shown then, of nothing: it must not be what "its definitions
    come to an end" is said by; kends.py)
    the kind the lemma says the definition's value is of (a list, a number, a record) made another

and asks the verifier of each (the other lemmas of the file as they are). And the other way about: the
lemmas as they are, of each changed copy of the specification's definitions they speak of (a number one more
or less, a comparison made another, + and - exchanged). A changed lemma that is REFUSED
needs no more. One that is SHOWN is put to the specification worked out on numbers (ode.Numbers: no symbols,
no facts, no verifier): the definitions are run on inputs made here, every use of a definition with a lemma
is noted with what it was given and what it gave, and of each use

    where `requires` holds of what it was given, `ensures` must hold of what it gave;
    where the lemma names a number that `decreases`, and the use is inside another of its ring: there
    `requires` must hold too, the number of the outer use must not be below zero, and the inner must be less.

A sequence's lemma is judged of places worked out straight (place k of the sequence of things of its kinds).

A SHOWN lemma that fails one of these on some input is a hole in the verifier ("shown, of something false"),
and the input is printed. One that passes them all is counted "shown, and so on N uses": not proved so (the
inputs are finitely many), but not found false.

What this is not: a proof that the verifier's part for lemmas is right. It is the same kind of evidence as
the flips: every acceptance among many near misses, judged by something that is not the verifier."""
import os, random, re, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kcheck, kends, klin, ode

PROGRAMS = {  # name: (specification, lemmas)
    "lz4": ("programs/lz4/lz4.spec", "programs/lz4/lz4.lemmas"), "frame": ("programs/frame/frame.spec", "programs/frame/frame.lemmas"),
    "utf8": ("programs/utf8/utf8.spec", "programs/utf8/utf8.lemmas"), "varint": ("programs/varint/varint.spec", "programs/varint/varint.lemmas"),
    "common": ("programs/common/common.spec", "programs/common/common.lemmas"), "blake3": ("blake3.spec", "proofs/blake3.lemmas"),
}
COMPARISONS = [">=", "<=", "==", "!=", ">", "<"]
# On numbers a definition may use itself as many times as its input is long (here: no shortcut for a definition
# whose value is its own on something else, so that each use is seen). The language's limit of 400 is for
# definitions inside definitions; the inputs made here are 300 bytes at most, and 3,000 uses deep is "goes on".
# (Only while numbers are worked out: the verifier is asked with the language's limit as it is.)
DEEP_ON_NUMBERS, LONGEST = 3000, 300


def read(path):
    with open(os.path.join(HERE, path)) as f: return f.read()


# ---- the changed copies
def lemma_spans(text):
    """(name, start, end, the names of what it is given) of each lemma of the text."""
    out = []
    for m in re.finditer(r"(?m)^lemma (\w+)\(([^)]*)\)", text):
        end = text.index("}", m.end()) + 1
        out.append((m.group(1), m.start(), end, [p.split(":")[0].strip() for p in m.group(2).split(",") if p.strip()]))
    return out


def changed(text):
    """[(what was done, the changed text)]: each differs from `text` in one place of one lemma's clauses."""
    out = []
    for name, a, z, params in lemma_spans(text):
        body_at = text.index("{", a)
        # the kind the lemma says the value is of, made another
        head = re.match(r"lemma \w+\([^)]*\)(\[\w+\])?: (list|number|any|record\([^)]*\))", text[a:body_at])
        if head:
            was = head.group(2)
            for other in ("list", "number", "record(value)"):
                if other.split("(")[0] != was.split("(")[0] and was != "any":
                    out.append((f"{name}: said to be a {other} (it is a {was})", text[:a + head.start(2)] + other + text[a + head.end(2):]))
                    # and with nothing ensured of it (what is ensured would be refused for speaking of the wrong kind of thing)
                    bare = re.sub(r"(?m)^[ \t]*ensures\b.*\n", "", text[body_at:z])
                    if bare != text[body_at:z]: out.append((f"{name}: said to be a {other} (it is a {was}), and nothing ensured of it", text[:a + head.start(2)] + other + text[a + head.end(2):body_at] + bare + text[z:]))
        # a lemma made to require the impossible: it is then shown (of nothing), and must count for nothing
        kinds = dict(re.findall(r"(\w+): (\w+)", text[a:body_at]))
        for p in params:
            never = f"{p} + 1 <= {p}" if kinds.get(p) == "number" else f"len({p}) + 1 <= len({p})" if kinds.get(p) in ("bytes", "list") else None
            if never: out.append((f"{name}: made to require the impossible (`requires {never}`)", text[:body_at + 1] + f"\n    requires {never}" + text[body_at + 1:]))
        for line in re.finditer(r"(?m)^[ \t]*(requires|ensures|decreases)\b(.*)$|\{[ \t]*((?:requires|ensures|decreases)\b[^}\n]*)\}", text[body_at:z]):
            la, lz = body_at + line.start(), body_at + line.end()
            clause = text[la:lz]
            where = f"{name}: `{clause.strip().strip('{}').strip()}`"
            if clause.lstrip().startswith("requires") and "\n" not in clause and not clause.lstrip().startswith("{"):
                out.append((f"{where}: left out", text[:la] + text[lz:].lstrip("\n") if text[la - 1] == "\n" else text[:la] + text[lz:]))
            for m in re.finditer(r"(?<![\w.])\d+(?![\w.])", clause):
                for d in (1, -1):
                    if int(m.group()) + d >= 0: out.append((f"{where}: {m.group()} made {int(m.group()) + d}", text[:la + m.start()] + str(int(m.group()) + d) + text[la + m.end():]))
            for m in re.finditer(r">=|<=|==|!=|>|<", clause):
                for op in COMPARISONS:
                    if op != m.group(): out.append((f"{where}: {m.group()} made {op}", text[:la + m.start()] + op + text[la + m.end():]))
            for m in re.finditer(r"(?<= )[+-](?= )", clause):
                op = "-" if m.group() == "+" else "+"
                out.append((f"{where}: {m.group()} made {op}", text[:la + m.start()] + op + text[la + m.end():]))
            for m in re.finditer(r"(?<![\w.])[A-Za-z_]\w*(?![\w(])", clause):
                if m.group() in params:
                    for other in [p for p in params if p != m.group()] + ["0", "1"]:
                        out.append((f"{where}: {m.group()} made {other}", text[:la + m.start()] + other + text[la + m.end():]))
    return out


def changed_spec(text, only):
    """[(what was done, the changed specification)]: one number, comparison or sign changed in the definitions
    `only` (those with lemmas, and those they use): the lemmas, as they are, may then be false of them."""
    out = []
    end = text.index("// ====") if "// ====" in text else len(text)
    for m in re.finditer(r"(?m)^(def|sequence) (\w+)\(", text[:end]):
        if m.group(2) not in only: continue
        # the definition's text: to its closing brace at the start of a line, or the end of its line
        z = text.index("\n", m.start())
        if text[m.start():z].count("{") > text[m.start():z].count("}"): z = text.index("\n}", m.start()) + 2
        body_at = text.index("{", m.start())
        chunk = text[body_at:z]
        code = re.sub(r"//[^\n]*", lambda c: " " * len(c.group()), chunk)                   # (comments are not changed)
        def put(a, b, new, what):
            line = text.count("\n", 0, body_at + a) + 1
            out.append((f"the specification's {m.group(2)}, line {line}: {what}", text[:body_at + a] + new + text[body_at + b:]))
        for n in re.finditer(r"(?<![\w.])\d+(?![\w.])", code):
            for d in (1, -1):
                if int(n.group()) + d >= 0: put(n.start(), n.end(), str(int(n.group()) + d), f"{n.group()} made {int(n.group()) + d}")
        for n in re.finditer(r">=|<=|==|!=|(?<![.])>(?!>)|<", code):
            for op in COMPARISONS:
                if op != n.group(): put(n.start(), n.end(), op, f"{n.group()} made {op}")
        for n in re.finditer(r"(?<= )[+-](?= )", code):
            put(n.start(), n.end(), "-" if n.group() == "+" else "+", f"{n.group()} made {'-' if n.group() == '+' else '+'}")
    return out


def reached(spec):
    """The definitions with lemmas, and those they use (through any number of others)."""
    seen, todo = set(), [n for n in spec.lemmas]
    while todo:
        n = todo.pop()
        if n in seen or (n not in spec.fns and n not in spec.seqs): continue
        seen.add(n); todo += list(kbyte.uses(spec, n))
    return seen


# ---- the specification on numbers, every use of a definition with a lemma noted
class Noting(ode.Numbers):
    """ode.Numbers, with `kept`: so that a definition's use of itself is a use like any other (no shortcut for a
    definition whose value is its own on something else), and each use is noted."""
    def __init__(self, spec):
        self.spec, self.uses, self.stack, self.count = spec, [], [], 0
    def kept(self, name, args, body):
        if name not in self.spec.lemmas or self.spec.lemmas[name]["index"] is not None: return body()
        use = dict(name=name, args=list(args), outer=self.stack[-1] if self.stack else None, value=None, has=False)
        self.uses.append(use); self.stack.append(use)
        try:
            use["value"] = body(); use["has"] = True
            return use["value"]
        finally: self.stack.pop()


def truth(spec, N, expr, env):
    """An expression of a lemma on numbers: True, False, or None where it has no value there."""
    try: return spec.eval(ode.Numbers(), expr, dict(env))
    except (ode.Fails, ode.Err, ZeroDivisionError, IndexError, TypeError, KeyError, AttributeError, RecursionError): return None


def kinds_fit(l, args):
    for (p, kind), a in zip(l["params"], args):
        if kind in ("bytes", "list") and not (isinstance(a, list) and all(isinstance(b, int) and not isinstance(b, bool) and 0 <= b < 256 for b in a)): return False
        if kind == "number" and not (isinstance(a, int) and not isinstance(a, bool) and a >= 0): return False
    return True


def judge(spec, uses):
    """None, or (what is false, the use) for the first use that shows a lemma of `spec` false."""
    ring = {}
    checked = 0
    for u in uses:
        l = spec.lemmas[u["name"]]
        if not kinds_fit(l, u["args"]): continue
        env = dict(zip((p for p, _ in l["params"]), u["args"]))
        req = [truth(spec, None, e, env) for e in l["requires"]]
        holds = all(r is True for r in req)
        if holds and u["has"]:
            v = u["value"]
            if l["kind"] != "any":
                checked += 1
                is_number = isinstance(v, int) and not isinstance(v, bool)
                if not {"number": is_number, "list": isinstance(v, list), "record": isinstance(v, dict) and sorted(v) == sorted(l["fields"])}[l["kind"]]:
                    return f"the lemma says the value is a {l['kind']}, and the definition gave {type(v).__name__}", u, checked
            env2 = dict(env); env2["result"] = u["value"]
            for k, e in enumerate(l["ensures"]):
                checked += 1
                if truth(spec, None, e, env2) is not True: return f"ensures (its clause {k + 1}) does not hold of what the definition gave", u, checked
        o = u["outer"]
        if o is not None and l is not None:
            lo = spec.lemmas[o["name"]]
            if lo["decreases"] is None: continue
            if o["name"] not in ring: ring[o["name"]] = kbyte.ring(spec, o["name"])
            if u["name"] not in ring[o["name"]] or not kinds_fit(lo, o["args"]): continue
            envo = dict(zip((p for p, _ in lo["params"]), o["args"]))
            if not all(truth(spec, None, e, envo) is True for e in lo["requires"]): continue          # the outer use is not one the lemma speaks of
            checked += 1
            if not holds: return f"inside a use of {o['name']} that the lemma speaks of, a use of {u['name']} that does not meet its `requires`", u, checked
            if l["decreases"] is None: return f"{u['name']} is used back and names no number", u, checked
            mo, mi = truth(spec, None, lo["decreases"], envo) if not _below(spec, lo, envo) else -1, truth(spec, None, l["decreases"], env) if not _below(spec, l, env) else -1
            if mo is None or mi is None or isinstance(mo, bool) or isinstance(mi, bool) or mo < 0 or not mi < mo:
                return f"the number that decreases is {mo} at the outer use (of {o['name']}) and {mi} at the inner (of {u['name']})", u, checked
    return None, None, checked


def _below(spec, l, env):
    """Is the number the lemma names below zero here? (On numbers a subtraction below zero is an error of the
    specification's language; the verifier works the number out as a whole number, and so must this.)"""
    try: spec.eval(ode.Numbers(), l["decreases"], dict(env)); return False
    except ode.Err as err: return "below zero" in str(err)
    except Exception: return False


# ---- inputs: what the definitions are run on
def lz4_block(rng, data):
    """An LZ4 block of `data`: literals and matches as a simple encoder finds them (and some it need not)."""
    out, i, lit = [], 0, []
    def emit(lit, mlen, off):
        token_l, token_m = min(len(lit), 15), min(mlen - 4, 15) if mlen else 0
        out.append(token_l * 16 + token_m)
        if len(lit) >= 15:
            n = len(lit) - 15
            while n >= 255: out.append(255); n -= 255
            out.append(n)
        out.extend(lit)
        if mlen:
            out.extend([off % 256, off // 256])
            if mlen - 4 >= 15:
                n = mlen - 4 - 15
                while n >= 255: out.append(255); n -= 255
                out.append(n)
    while i < len(data):
        best = None
        if i >= 1 and len(data) - i >= 4 and rng.random() < 0.8:
            for off in sorted({1, 2, 3, 4, rng.randrange(1, i + 1), rng.randrange(1, i + 1)}):
                if off > i: continue
                n = 0
                while i + n < len(data) and data[i + n - off] == data[i + n]: n += 1
                if n >= 4 and (best is None or n > best[0]): best = (n, off)
        if best and len(data) - (i + best[0]) >= 0 and i + best[0] < len(data):
            emit(lit, best[0], best[1]); lit = []; i += best[0]
        else: lit.append(data[i]); i += 1
    emit(lit, 0, 0)
    return out


def some_bytes(rng, n, kind):
    if kind == 0: return [rng.randrange(256) for _ in range(n)]
    if kind == 1: return [rng.choice([0, 1, 65, 255]) for _ in range(n)]
    if kind == 2: return ([rng.randrange(256) for _ in range(rng.randrange(1, 6))] * (n + 1))[:n]
    text = "".join(chr(rng.choice([65, 0x7F, 0x80, 0x7FF, 0x800, 0xFFFF, 0x10000, 0x10FFFF, 0xE9, 0x20AC, 0x1F600, rng.randrange(0x20, 0xD000)])) for _ in range(n))
    return list(text.encode("utf-8", "replace"))[:n] if rng.random() < 0.3 else list(text.encode("utf-8", "replace"))[:LONGEST]


def runs(program, spec, rng, cases):
    """[(definition, what it is given)]: what to work out on numbers, to see uses of the definitions with lemmas."""
    out = []
    names = [n for n, l in spec.lemmas.items() if l["index"] is None]
    for _ in range(cases):
        n = rng.choice([0, 1, 2, 3, 5, 8, 13, 21, 40, 70, rng.randrange(0, 300)])
        data = some_bytes(rng, n, rng.randrange(4))
        if program in ("lz4", "frame"):
            block = lz4_block(rng, data) if rng.random() < 0.75 else some_bytes(rng, n, rng.randrange(3))
            if rng.random() < 0.15 and block: block[rng.randrange(len(block))] = rng.randrange(256)            # a block gone wrong in one byte
            out.append(("lz4", [block]))
            if program == "frame":
                frame = [rng.randrange(256) for _ in range(4)] + block
                out.append(("unframe", [frame]))
        elif program == "utf8": out.append(("utf8", [data]))
        elif program == "varint": out.append(("varint", [rng.choice([0, 1, 127, 128, 129, 16383, 16384, 2 ** 32, 2 ** 63, 2 ** 64 - 1, rng.randrange(2 ** 64), rng.randrange(70000)])]))
        elif program == "common":
            other = list(data)
            if other and rng.random() < 0.7: other[rng.randrange(len(other))] ^= 1 + rng.randrange(255)
            out.append(("common", [data, other + some_bytes(rng, rng.randrange(0, 4), 0)]))
        elif program == "blake3":
            m = rng.choice([0, 1, 63, 64, 65, 1023, 1024, 1025, 2047, 2048, 2049, 3072, 3073, 4096, 4097, 5000, 7169, 8193, rng.randrange(0, 9000)])
            key = [ode.Word(rng.randrange(2 ** 32)) for _ in range(8)]
            out.append(("subtree", [key, rng.choice([0, 16, 32, 64]), rng.randrange(0, 5), some_bytes(rng, m, rng.randrange(3))]))
        # and each definition with a lemma, straight, on things of its lemma's kinds (most have no value there: those say nothing)
        for name in names:
            l = spec.lemmas[name]
            if any(kind == "any" for _, kind in l["params"]): continue
            args = []
            for p, kind in l["params"]:
                if kind in ("bytes", "list"): args.append(list(out[-1][1][0]) if out and isinstance(out[-1][1][0], list) and rng.random() < 0.7 else some_bytes(rng, rng.randrange(0, 30), rng.randrange(3)))
                else: args.append(rng.choice([0, 1, 2, 3, 4, 5, len(args[0]) if args and isinstance(args[0], list) else 7, max(0, (len(args[0]) if args and isinstance(args[0], list) else 7) - 1), rng.randrange(0, 80), rng.randrange(0, 70000)]))
            out.append((name, args))
    return out


def noted(spec, todo, count=False):
    """Every use of a definition with a lemma, over all of `todo`. With `count`: and how many runs did not come
    to an end within the language's limits (a definition of itself that goes on)."""
    uses, no_end, deep = [], 0, ode.DEEP
    ode.DEEP = DEEP_ON_NUMBERS
    try:
        for name, args in todo:
            if name not in spec.fns: continue
            N = Noting(spec)
            try: spec.apply(N, name, list(args))
            except ode.Fails: pass
            except RecursionError: no_end += 1
            except ode.Err as err:
                if "does not come to an end" in str(err) or "too many steps" in str(err): no_end += 1
            except (ZeroDivisionError, IndexError, TypeError, KeyError, AttributeError): pass
            uses += N.uses
    finally: ode.DEEP = deep
    return (uses, no_end) if count else uses


def places(spec, rng, cases):
    """Uses of the sequences with lemmas, worked out on numbers: place k of the sequence of some things, for
    things of the lemma's kinds (the lemma of a sequence speaks of every place)."""
    uses, deep = [], ode.DEEP
    ode.DEEP = DEEP_ON_NUMBERS
    try:
        for name, l in spec.lemmas.items():
            if l["index"] is None or name not in spec.seqs or any(kind == "any" for _, kind in l["params"]): continue
            for _ in range(cases):
                args = []
                for p, kind in l["params"]:
                    if kind in ("bytes", "list"): args.append(some_bytes(rng, rng.choice([0, 1, 2, 3, 5, 8, 20, rng.randrange(0, 60)]), rng.randrange(3)))
                    else: args.append(rng.choice([0, 1, 2, 3, 4, len(args[0]) if args and isinstance(args[0], list) else 5, (len(args[0]) if args and isinstance(args[0], list) else 5) + 1, rng.randrange(0, 70)]))
                k = rng.choice([0, 1, 2, 3, 7, rng.randrange(0, 40)])
                use = dict(name=name, args=args, index=k, value=None, has=False, outer=None)
                try:
                    N = ode.Numbers()
                    use["value"] = spec.apply(N, name, list(args)).at(spec, N, k); use["has"] = True
                except (ode.Fails, ode.Err, ZeroDivisionError, IndexError, TypeError, KeyError, AttributeError, RecursionError): pass
                uses.append(use)
    finally: ode.DEEP = deep
    return uses


def judge_places(spec, uses):
    """None, or (what is false, the use): a sequence's lemma that does not hold of a place worked out."""
    checked = 0
    for u in uses:
        l = spec.lemmas.get(u["name"])
        if l is None or l["index"] is None or not u["has"] or not kinds_fit(l, u["args"]): continue
        env = dict(zip((p for p, _ in l["params"]), u["args"])); env[l["index"]] = u["index"]
        if not all(truth(spec, None, e, env) is True for e in l["requires"]): continue
        env["result"] = u["value"]
        for k, e in enumerate(l["ensures"]):
            checked += 1
            if truth(spec, None, e, env) is not True: return f"ensures (its clause {k + 1}) does not hold of place {u['index']}", u, checked
    return None, None, checked


def said_to_end(spec, text):
    """Does a verification say, of this specification with these lemmas, that the definitions its contracts
    speak through come to an end? (kends.py, with no search, as a shipped file is asked.)"""
    try:
        klin.Facts.PROOFS = {}
        return all(kends.ends_for(spec, s)[1] is None for s in ode.Spec(text).contracts)
    except (kcheck.Fail, ode.Err, KeyError, IndexError, TypeError, AttributeError, RecursionError): return False
    finally: klin.Facts.PROOFS = None


def show(u):
    def short(v):
        if isinstance(v, list): return f"{len(v)} things " + (bytes(v[:24]).hex() if all(isinstance(b, int) and 0 <= b < 256 for b in v[:24]) else "...") + ("..." if len(v) > 24 else "")
        return repr(v)[:80]
    return f"{u['name']}({', '.join(short(a) for a in u['args'])})" + (f"[{u['index']}]" if "index" in u else "") + (f" = {short(u['value'])}" if u["has"] else " (no value)")


def verdict(spec_text, lemma_text, limit=120):
    """("shown", the specification with the lemmas) or ("refused", why)."""
    try:
        spec = ode.with_proof(spec_text, lemma_text)
        kbyte.prove_lemmas(spec)
        return "shown", spec
    except (kcheck.Fail, ode.Err) as err: return "refused", str(err)
    except RecursionError: return "refused", "too deep"


def audit(program, cases, seed, out=print, control=False):
    spec_text, lemma_text = read(PROGRAMS[program][0]), read(PROGRAMS[program][1])
    t0 = time.time()
    v, spec = verdict(spec_text, lemma_text)
    if v != "shown":
        if control: out(f"{program}: the verifier made wrong refuses the lemmas as they are: nothing to find here"); return 0
        out(f"{program}: CONTROL FAILED: the lemmas as they are are refused: {spec}"); return 1
    rng = random.Random(seed)
    todo = runs(program, spec, rng, cases)
    uses = noted(spec, todo)
    bad, _, n = judge(spec, uses)
    seq_uses = places(spec, rng, cases)
    bad2, _, n2 = judge_places(spec, seq_uses)
    bad, n = bad or bad2, n + n2
    by = {}
    for u in seq_uses:
        if u["has"]: by[u["name"] + "[k]"] = by.get(u["name"] + "[k]", 0) + 1
    for u in uses: by[u["name"]] = by.get(u["name"], 0) + 1
    if bad: out(f"{program}: CONTROL FAILED: the lemmas as they are, shown, are FALSE on numbers: {bad}"); return 1
    if not n: out(f"{program}: CONTROL FAILED: no use of a definition with a lemma was judged"); return 1
    out(f"{program}: the lemmas as they are: shown, and so on {n} judgements of {len(uses)} uses ({', '.join(f'{k} {v}' for k, v in sorted(by.items()))})")
    copies = changed(lemma_text)
    refused, so, holes, vacuous = 0, 0, [], 0
    for what, text in copies:
        v, s = verdict(spec_text, text)
        if v == "refused": refused += 1; continue
        # the uses were noted with the lemmas as they are: the definitions are the same, so the uses are the same;
        # the changed lemmas are what is judged of them
        bad, u, n = judge(s, uses)
        if not bad:
            bad, u, n2 = judge_places(s, seq_uses); n += n2
        if bad: holes.append((what, bad, u)); out(f"  HOLE: {what}: SHOWN, and FALSE: {bad}: {show(u)}" + (f" inside {show(u['outer'])}" if u["outer"] else ""))
        elif not n:
            # a lemma that speaks of no use tried here (one that requires what never is, for one): harmless as a lemma,
            # and it must not be what "comes to an end" is said by
            still = said_to_end(s, spec_text) and any(l["decreases"] is not None for l in s.lemmas.values())
            if still and "the impossible" in what:
                holes.append((what, "said to end", None)); out(f"  HOLE: {what}: SHOWN (of nothing), and \"comes to an end\" is STILL SAID by it")
            else: vacuous += 1; out(f"  shown, and judged on no use (nothing here says whether it is so; \"comes to an end\" is {'still said' if still else 'not said'} with it): {what}")
        else: so += 1; out(f"  shown, and so on {n} judgements: {what}")
    out(f"{program}: {len(copies)} changed lemmas: {refused} refused, {so} shown and so on every use tried, {vacuous} shown and not judged, {len(holes)} SHOWN AND FALSE; {time.time() - t0:.1f} s")
    # the other way about: the lemmas as they are, of changed definitions
    t0 = time.time()
    copies = changed_spec(spec_text, reached(spec))
    refused, so, vacuous, unread, n_holes = 0, 0, 0, 0, len(holes)
    for what, text in copies:
        try: ode.Spec(text)
        except (ode.Err, RecursionError): unread += 1; continue                # not a specification at all
        v, s = verdict(text, lemma_text)
        if v == "refused": refused += 1; continue
        rng = random.Random(seed)
        uses, no_end = noted(s, runs(program, s, rng, max(20, cases // 3)), count=True)
        bad, u, n = judge(s, uses)
        if not bad:
            bad, u, n2 = judge_places(s, places(s, rng, max(20, cases // 3))); n += n2
        if bad: holes.append((what, bad, u)); out(f"  HOLE: {what}: the lemmas are SHOWN of it, and FALSE: {bad}: {show(u)}" + (f" inside {show(u['outer'])}" if u["outer"] else ""))
        elif no_end and said_to_end(s, text):
            holes.append((what, "no end", None)); out(f"  HOLE?: {what}: its definitions are SHOWN to come to an end, and {no_end} run(s) on numbers did not within the limit: look")
        elif not n: vacuous += 1; out(f"  the lemmas shown of it, and judged on no use: {what}")
        else: so += 1; out(f"  the lemmas shown of it, and so on {n} judgements: {what}")
    out(f"{program}: {len(copies)} changed specifications ({unread} of them no specification): the lemmas {refused} times refused, {so} shown and so on every use tried, {vacuous} shown and not judged, {len(holes) - n_holes} SHOWN AND FALSE; {time.time() - t0:.1f} s")
    return len(holes)


def main():
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] not in ("--cases", "--seed", "--control")]
    option = lambda name, default: int(sys.argv[sys.argv.index(name) + 1]) if name in sys.argv else default
    programs = args or list(PROGRAMS)
    if "--list" in sys.argv:
        for p in programs:
            for what, _ in changed(read(PROGRAMS[p][1])): print(p, what)
        return 0
    if "--control" in sys.argv:
        # the audit's own control: a verifier made wrong on purpose (in this process only: each question about the
        # numbers answered "shown" one time in `--control N`, by its count) must be found out
        import klin
        every, honest, asked = option("--control", 7), klin.Facts.ge0, [0]
        def ge0(self, f):
            asked[0] += 1
            return True if asked[0] % every == 0 else honest(self, f)
        klin.Facts.ge0 = ge0
        quiet = lambda line: print(line) if not line.startswith("  shown") and not line.startswith("  the lemmas shown") else None
        holes = 0
        for p in programs:
            asked[0] = 0
            try: holes += audit(p, option("--cases", 150), option("--seed", 1), out=quiet, control=True)
            except Exception as err: print(f"{p}: the wrong verifier fell over ({type(err).__name__}): no finding from it")
        print(f"lemma_audit --control: the verifier made wrong showed {holes} false lemma(s), and each was found out" if holes else "lemma_audit --control: NOTHING FOUND: this audit would not see such a verifier")
        return 0 if holes else 1
    holes = sum(audit(p, option("--cases", 150), option("--seed", 1)) for p in programs)
    print(f"lemma_audit: {holes} changed lemma(s) shown and false" if holes else "lemma_audit: no changed lemma is shown and false")
    return 1 if holes else 0


if __name__ == "__main__":
    sys.exit(main())
