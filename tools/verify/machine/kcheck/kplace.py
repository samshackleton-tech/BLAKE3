#!/usr/bin/env python3
"""kplace: a prover that guesses the place of a loop: what a function's registers hold, in the specification's
terms, each time the code comes round. Trusted for nothing: what it prints is a proof like one written by hand,
and the verifier (kbyte.py) shows the function by it or does not.

    python3 kplace.py SPEC SYMBOL OBJECT [LEMMAS]        prints the proof it found (a `.proof` file's text)
    python3 kplace.py --again                           the functions of programs/ with one loop: is a
                                                        proof found for each from nothing?

For a function with one loop. What it tries:

    where        the instruction a jump goes back to; or the first of the loop's body (after its test)
    the things   the registers and the places of the stack the loop writes. Of each, what it is when the code
                 first comes there (asked of the verifier: is it 0? is it 1?), and then one of:
                 the count `i` of bytes taken (0 at first; `i <= N` for a number N the function is given;
                 `decreases N - i`); another count not above it; the same plain number every time; place i
                 of one of the specification's sequences of the bytes; nothing said (`any`)
    one fact     the definition the contract speaks of, or one it uses, of the bytes and the counts, is the
                 whole (`points(input, i, count) == utf8(input)`): what is left to do is what was to do

and asks the verifier of each proof made of these, the plainest first."""
import itertools, os, re, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kcheck, kdecode, kguess, ode

KEPT = ["rbx", "rbp", "r12", "r13", "r14", "r15"]


def verdict(rows, spec, symbol, proof):
    try: kbyte.check(rows, spec, symbol, proof); return None
    except (kcheck.Fail, kdecode.Stop, ode.Err) as err: return str(err)
    except RecursionError: return "too deep"


def loops(rows):
    """[(the address a jump goes back to, the address it is jumped from)] of the function's loops."""
    out = []
    for a, z, i in rows:
        m = re.match(r"\.j\w+ 0x([0-9A-Fa-f]+)", i)
        if m and int(m.group(1), 16) <= a: out.append((int(m.group(1), 16), a))
    return out


def written(rows, lo, hi):
    """The registers the callee keeps and the places of the stack that the instructions from lo to hi write."""
    regs, slots = [], []
    for a, z, i in rows:
        if not lo <= a <= hi: continue
        m = re.match(r"\.\w+(?: \d+)? \(\.reg \.(\w+)\)", i) or re.match(r"\.movzx\d+ \.(\w+) ", i) or re.match(r"\.pop \.(\w+)", i)
        if m and m.group(1) in KEPT and m.group(1) not in regs and not i.startswith((".cmp", ".test", ".push")): regs.append(m.group(1))
        m = re.match(r"\.mov(?: \d+)? \(\.mem \.rsp (0x[0-9A-Fa-f]+|\d+)\)", i)
        if m:
            off = int(m.group(1), 0)
            if f"stack[{off}]" not in slots: slots.append(f"stack[{off}]")
    return regs + slots


def place_text(at, base, lines): return f"place +{at - base:#x} {{\n" + "".join(f"    {l}\n" for l in lines) + "}\n"


def first_values(rows, spec, symbol, at, base, things):
    """{thing: 0 | 1 | "number" | None}: what each is when the code first comes to `at`, asked of the verifier
    (a proof that says `x == c` of one thing and nothing of the others: is it refused at the entry?)."""
    out = {}
    for t in things:
        others = [o for o in things if o != t]
        out[t] = None
        for c in (0, 1):
            v = verdict(rows, spec, symbol, place_text(at, base, [f"name x = {t}", f"fact x == {c}"] + ([f"any {', '.join(others)}"] if others else [])))
            if v is None or "not a number to call" in v: 
                if v is None: out[t] = c
                break
            if "from the entry" not in v: out[t] = c; break
        else:
            v = verdict(rows, spec, symbol, place_text(at, base, [f"name x = {t}"] + ([f"any {', '.join(others)}"] if others else [])))
            if v is not None and "not a number to call" not in v: out[t] = "number"
    return out


def guess(rows, spec, symbol, say=lambda s: None, limit=1500):
    """(the proof's text or None, tries). The verifier's refusals lead: a refusal that names a thing of which
    the proof says nothing ("a compare of r12 and n") is taken to mean that thing needs saying something of."""
    c = spec.contracts[symbol]
    base = rows[0][0]
    if verdict(rows, spec, symbol, "") is None: return "", 1
    ls = loops(rows)
    if len({t for t, _ in ls}) != 1: say(f"  {len({t for t, _ in ls})} loops: this guesser takes a function with one"); return None, 1
    head, back = min(t for t, _ in ls), max(s for _, s in ls)
    spots = [head]
    for a, z, i in rows:                                         # the first of the body: after the first jump out of the loop
        m = re.match(r"\.j\w+ 0x([0-9A-Fa-f]+)", i)
        if a >= head and m and int(m.group(1), 16) > back:
            spots.insert(0, z); break
    things = written(rows, head, back)
    numbers = [name for name, kind in c["args"] if kind == "number"]
    bytes_args = [name for name, kind in c["args"] if kind != "number"]
    tops = []
    def see(x):
        if isinstance(x, tuple) and len(x) == 3 and x[0] == "call" and x[1] in spec.fns and x not in tops: tops.append(x)
    kguess.walk([c["returns"]] + [l for l in c["leaves"]] + list(c["conditions"]), see)
    seqs = [n for n, (params, h, var, first, nxt) in spec.seqs.items() if len(params) == 1]
    tries = [0]

    def text_of(at, roles, fact):
        """roles: {thing: ("index", N) | ("count",) | ("const", c) | ("seq", S)}; the others: any."""
        index = next((t for t, r in roles.items() if r[0] == "index"), None)
        names, k, n = {}, 0, 0
        for t, r in roles.items():
            if r[0] == "index": names[t] = "i"
            elif r[0] == "count": names[t] = f"count{n if n else ''}"; n += 1
            elif r[0] == "const": names[t] = f"k{k}"; k += 1
        lines = [f"name {v} = {t}" for t, v in names.items()]
        lines += [f"fact {names[t]} == {r[1]}" for t, r in roles.items() if r[0] == "const"]
        if index: lines.append(f"fact i <= {roles[index][1]}")
        if index: lines += [f"fact {names[t]} <= i" for t, r in roles.items() if r[0] == "count"]
        if index: lines += [f"{t} = {r[1]}({bytes_args[0]})[i]" for t, r in roles.items() if r[0] == "seq" and bytes_args]
        if fact: lines.append(fact)
        anys = [t for t in things if t not in roles]
        if anys: lines.append(f"any {', '.join(anys)}")
        if index: lines.append(f"decreases {roles[index][1]} - i")
        return place_text(at, base, lines), names

    def facts_for(names):
        out = []
        counts = [v for v in names.values() if v.startswith("count")]
        for top in tops:
            for d in [top[1]] + sorted(kguess.uses_closure(spec, top[1])):
                if d not in spec.fns or not kbyte.ring(spec, d): continue
                ring = sorted(kbyte.ring(spec, d))
                kinds = kguess.list_params(spec, ring, kguess.ring_kinds(spec, ring))[d]
                options = [bytes_args if kinds[p] in ("bytes", "list") else ["i"] + counts for p in spec.fns[d][0]]
                for args in itertools.product(*options):
                    if "i" in args: out.append(f"fact {d}({', '.join(args)}) == {ode_text(top)}")
        return out

    seen = {}
    def solve(at, first, roles, free, depth=0):
        """free: how many things may still be given something to say with no refusal pointing at them."""
        if tries[0] > limit or depth > len(things): return None
        key = (at, tuple(sorted(roles.items())))
        if key not in seen:
            text, names = text_of(at, roles, None)
            tries[0] += 1
            v = verdict(rows, spec, symbol, text)
            if v is None: return text
            if any(r[0] == "index" for r in roles.values()):
                for fact in facts_for(names):
                    tries[0] += 1
                    t2, _ = text_of(at, roles, fact)
                    if verdict(rows, spec, symbol, t2) is None: return t2
            seen[key] = v
        v = seen[key]
        # which thing does the refusal speak of?
        m = re.search(r"\('q', '(\w+)\?\d+'\)", v)
        lead = True
        if m and m.group(1) in things and m.group(1) not in roles: wanted = [m.group(1)]
        elif m and m.group(1) == "stack": wanted = [t for t in things if t.startswith("stack") and t not in roles]
        else: wanted, lead = [t for t in things if t not in roles], False     # no lead: each in turn, if any is allowed
        if not lead and free == 0: return None
        bound = re.search(r"and \('l', 1\*(\w+)\)", v)
        counted = v.startswith("add of")                                       # a thing one is added to: a count before a plain number
        for t in wanted:
            options = []
            has_index = any(r[0] == "index" for r in roles.values())
            if first[t] == 0 and not has_index:
                options += [("index", n) for n in ([bound.group(1)] if bound and bound.group(1) in numbers else []) + [n for n in numbers if not (bound and bound.group(1) == n)]]
            if first[t] == 0 and has_index and counted: options.append(("count",))
            if first[t] in (0, 1): options.append(("const", first[t]))
            if first[t] == 0 and has_index and not counted: options.append(("count",))
            if first[t] in (0, 1) and has_index: options += [("seq", s) for s in seqs if not any(r == ("seq", s) for r in roles.values())]
            for r in options:
                got = solve(at, first, dict(roles, **{t: r}), free if lead else free - 1, depth + 1)
                if got: return got
        return None

    firsts = {}
    for free in (0, 1, 2):                                       # the plainest first: only what the refusals point at; then one thing more; then two
        for at in spots:
            if at not in firsts:
                firsts[at] = first_values(rows, spec, symbol, at, base, things)
                tries[0] += 3 * len(things)
                say(f"  at +{at - base:#x}: " + ", ".join(f"{t} is {'not a number' if v is None else v} at first" for t, v in firsts[at].items()))
            got = solve(at, firsts[at], {}, free)
            if got: return got, tries[0]
    return None, tries[0]


def ode_text(e):
    """An expression of the specification as text (the few forms a contract's `returns` names a definition with)."""
    if e[0] == "call": return f"{e[1]}({', '.join(ode_text(a) for a in e[2])})"
    if e[0] == "name": return e[1]
    if e[0] == "num": return str(e[1])
    raise ValueError(e[0])


def again():
    import test_kbyte as T
    sys.path.insert(0, os.path.join(HERE, "programs"))
    import check_programs as P
    found = total = 0
    for program, function, what in P.PROGRAMS:
        p = T.Program(program, function, "ode_" + function)
        spec = ode.Spec(p.spec)
        n = len({t for t, _ in loops(p.rows)})
        if n != 1:
            print(f"ode_{function}: {n} loops" + (": no proof is needed" if n == 0 and verdict(p.rows, spec, p.symbol, "") is None else ": not tried")); continue
        total += 1
        t0 = time.time()
        text, tries = guess(p.rows, spec, p.symbol, say=print)
        if text is None: print(f"ode_{function}: no proof found; {tries} tries, {time.time() - t0:.1f} s"); continue
        found += 1
        print(f"ode_{function}: shown by this, found in {tries} tries, {time.time() - t0:.1f} s (the one written by hand: {sum(1 for l in p.proof.split(chr(10)) if l.strip() and not l.strip().startswith('//'))} lines):")
        print("    " + text.replace("\n", "\n    ").rstrip())
    print(f"kplace: a proof found for {found} of the {total} functions with one loop")
    return 0


def main():
    if "--again" in sys.argv: return again()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    with open(args[0]) as f: text = f.read()
    lemmas = ""
    if len(args) > 3:
        with open(args[3]) as f: lemmas = f.read()
    spec = ode.with_proof(text, lemmas) if lemmas else ode.Spec(text)
    rows = kbyte.load(args[2], args[1])
    proof, tries = guess(rows, spec, args[1], say=lambda s: print("//" + s))
    if proof is None: print(f"// no proof found ({tries} tries)"); return 1
    sys.stdout.write(proof)
    return 0


if __name__ == "__main__":
    sys.exit(main())
