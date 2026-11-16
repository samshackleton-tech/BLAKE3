#!/usr/bin/env python3
"""kguess: a prover that guesses. For a specification's definitions that use themselves it looks for the number
that decreases, by trying the few such numbers there are and asking the verifier of each.

    python3 kguess.py SPEC [LEMMAS]          prints the `decreases` lemmas it found (LEMMAS: lemmas to keep)
    python3 kguess.py --again                the six lemma files of this folder with every `decreases` taken
                                             out: are they found again?

Trusted for nothing: what it prints is a lemma like one written by hand, and the verifier shows it or not
(kbyte.py's prove_lemmas). It is here to show where guessing belongs, and how little of it this takes.

What it tries, for a definition `f(p1, p2, ...)` in a ring of definitions that use each other:

    the kinds     a thing whose length is asked or that is indexed: bytes; one that is counted with: number;
                  what is only passed on: any. (A lemma that is there already keeps its kinds and its clauses.)
    the number    n;  len(b) - n;  len(b);  and for a ring of two, 2 * len(b) and 2 * len(b) - 1
    `requires`    none; n <= len(b); len(a) <= len(b); len(b) > C for a number C the definitions name
                  (one or two of them)

and for the definitions the ring uses that work on words, a lemma of kind `any` that says nothing."""
import itertools, os, re, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kcheck, ode


def walk(x, f):
    f(x)
    if isinstance(x, (tuple, list)):
        for y in x: walk(y, f)


def kinds_of(spec, name):
    """{param: bytes | number | any} from how the definition's own text uses each."""
    params, body = spec.fns[name]
    kind = {p: "any" for p in params}
    def see(x):
        if not isinstance(x, tuple) or not x: return
        if x[0] == "call" and x[1] == "len" and x[2] and x[2][0] == ("name", x[2][0][1]) and x[2][0][1] in kind: kind[x[2][0][1]] = "bytes"
        if x[0] in ("index", "slice") and isinstance(x[1], tuple) and x[1][0] == "name" and x[1][1] in kind: kind[x[1][1]] = "bytes"
        if x[0] == "bin" and x[1] in ("+", "-", "*", "/", "%", "<", "<=", ">", ">=", "==", "!="):
            for y in x[2:4]:
                if isinstance(y, tuple) and y[0] == "name" and y[1] in kind and kind[y[1]] == "any": kind[y[1]] = "number"
        if x[0] in ("index", "slice"):
            for y in x[2:]:
                if isinstance(y, tuple) and y[0] == "name" and y[1] in kind and kind[y[1]] == "any": kind[y[1]] = "number"
    walk(body, see)
    return kind


def has_words(spec, name, seen=None):
    """Does the definition, or one it uses, work on words (which this verifier's part for lemmas only passes on)?"""
    seen = seen if seen is not None else set()
    if name in seen or name not in spec.fns: return False
    seen.add(name)
    found = [False]
    def see(x):
        if isinstance(x, tuple) and x:
            if x[0] == "bin" and x[1] in ("^", ">>>", "|", "&"): found[0] = True
            if x[0] == "call" and x[1] in ("counter", "word", "words", "bytes_of", "lo", "hi"): found[0] = True
    walk(spec.fns[name][1], see)
    return found[0] or any(has_words(spec, n, seen) for n in kbyte.uses(spec, name))


def numbers_in(spec, names):
    out = set()
    def see(x):
        if isinstance(x, tuple) and len(x) == 2 and x[0] == "num" and 1 < x[1] < 1 << 20: out.add(x[1])
    for n in names: walk(spec.fns[n][1], see)
    return sorted(out)


def ring_kinds(spec, ring):
    """kinds_of for each of the ring, and then: a thing one of them only passes on to another, where that one
    counts with it or asks its length, is of that kind in both."""
    kinds = {n: kinds_of(spec, n) for n in ring}
    for _ in range(len(ring) + 1):
        for n in ring:
            def see(x, n=n):
                if isinstance(x, tuple) and len(x) == 3 and x[0] == "call" and x[1] in kinds:
                    for q, a in zip(spec.fns[x[1]][0], x[2]):
                        if isinstance(a, tuple) and a[0] == "name" and a[1] in kinds[n] and kinds[n][a[1]] == "any": kinds[n][a[1]] = kinds[x[1]][q]
            walk(spec.fns[n][1], see)
    return kinds


def candidates(spec, name, ring, kept):
    """Lemma texts for `name`, the likeliest first. `kept`: the lemma it has already (its head and clauses stay)."""
    if name in kept:
        head, clauses = kept[name]
        kind = dict(re.findall(r"(\w+): (\w+)", head[head.index("("):head.index(")") + 1]))
    else:
        kind = ring_kinds(spec, ring)[name]
        head, clauses = f"lemma {name}({', '.join(f'{p}: {kind[p]}' for p in spec.fns[name][0])}): any", []
    nums = [p for p, k in kind.items() if k == "number"]
    lists = [p for p, k in kind.items() if k in ("bytes", "list")]
    measures = [f"len({b}) - {n}" for b in lists for n in nums] + nums + [f"len({b})" for b in lists]
    if len(ring) > 1: measures = [m for b in lists for m in (f"2 * len({b})", f"2 * len({b}) - 1")] + measures
    req = [f"{n} <= len({b})" for b in lists for n in nums] + [f"len({a}) <= len({b})" for a in lists for b in lists if a != b]
    req += [f"len({b}) > {c}" for b in lists for c in numbers_in(spec, ring)]
    sets = [()] + [(r,) for r in req] + list(itertools.combinations(req, 2))
    for rs in sets:
        for m in measures:
            lines = clauses + [f"requires {r}" for r in rs if f"requires {r}" not in clauses] + [f"decreases {m}"]
            yield head + " {\n" + "".join(f"    {l}\n" for l in lines) + "}\n"


def shown(spec_text, lemmas):
    try:
        spec = ode.with_proof(spec_text, lemmas); kbyte.prove_lemmas(spec)
        return spec
    except (kcheck.Fail, ode.Err, RecursionError): return None


def split_lemmas(text):
    """{name: (head, [clauses])} and the text of the lemmas of sequences (kept as they are)."""
    kept, rest = {}, ""
    for m in re.finditer(r"(?m)^lemma (\w+)\(([^)]*)\)(\[\w+\])?: ([^{]*)\{([^}]*)\}\n?", text):
        if m.group(3): rest += m.group(0) if m.group(0).endswith("\n") else m.group(0) + "\n"; continue
        head = m.group(0)[:m.group(0).index("{")].strip()
        kept[m.group(1)] = (head, [c.strip() for c in m.group(5).split("\n") if c.strip()])
    return kept, rest


def guess(spec_text, lemma_text="", limit=4000, say=lambda s: None):
    """(the lemma text with a `decreases` for every ring it could find one for, the rings left, tries)."""
    spec = ode.Spec(spec_text)
    kept, sequences = split_lemmas(lemma_text)
    rings, seen = [], set()
    for n in spec.fns:
        r = frozenset(kbyte.ring(spec, n))
        if r and r not in seen: seen.add(r); rings.append(sorted(r))
    # a ring that uses another comes after it
    def uses_all(names):
        out, todo = set(), list(names)
        while todo:
            for b in kbyte.uses(spec, todo.pop()):
                if b not in out: out.add(b); todo.append(b)
        return out
    rings.sort(key=lambda r: len([q for q in rings if set(q) & uses_all(r) and q != r]))
    def text_of(kept): return sequences + "".join(h + " {\n" + "".join(f"    {c}\n" for c in cs) + "}\n" for h, cs in kept.values())
    # the definitions a ring uses that cannot be opened here (words): a lemma that says nothing, where the plain try fails
    tries, left = 0, []
    for ring in rings:
        if all(n in kept and any(c.startswith("decreases") for c in kept[n][1]) for n in ring): continue
        found = None
        for quiet in (False, True):
            extra = ""
            if quiet:
                outside = sorted(n for n in kbyte.uses(spec, ring[0]).union(*[kbyte.uses(spec, r) for r in ring]) if n in spec.fns and n not in ring and n not in kept and has_words(spec, n))
                extra = "".join(f"lemma {n}({', '.join(p + ': any' for p in spec.fns[n][0])}): any {{ }}\n" for n in outside)
            base = {n: v for n, v in kept.items() if n not in ring}
            for combo in itertools.product(*[list(itertools.islice(candidates(spec, n, ring, kept), 60)) for n in ring]):
                tries += 1
                if tries > limit: break
                if shown(spec_text, text_of(base) + extra + "".join(combo)) is not None: found = (extra, combo); break
            if found or tries > limit: break
        if not found: left.append(ring); say(f"  {', '.join(ring)}: no number found"); continue
        extra, combo = found
        for n, lemma in zip(ring, combo): kept[n] = split_lemmas(lemma)[0][n]
        for n, v in split_lemmas(extra)[0].items(): kept[n] = v
        for n in ring: say(f"  {n}: {' ; '.join(c for c in kept[n][1] if c.startswith(('requires', 'decreases')))}")
    return text_of(kept), left, tries


def again():
    """Every `decreases` (and every lemma that says nothing else) taken out of the six lemma files: found again?"""
    import lemma_audit
    total, found = 0, 0
    for program, (spec_path, lemma_path) in lemma_audit.PROGRAMS.items():
        spec_text, lemmas = lemma_audit.read(spec_path), lemma_audit.read(lemma_path)
        kept, sequences = split_lemmas(lemmas)
        bare = {n: (h, [c for c in cs if not c.startswith("decreases")]) for n, (h, cs) in kept.items()}
        # a lemma left with nothing but `requires`, or nothing at all, is taken out whole: the guesser starts from the definition
        bare = {n: v for n, v in bare.items() if any(c.startswith("ensures") for c in v[1])}
        start = sequences + "".join(h + " {\n" + "".join(f"    {c}\n" for c in cs) + "}\n" for h, cs in bare.values())
        spec = ode.Spec(spec_text)
        rings = {frozenset(kbyte.ring(spec, n)) for n in spec.fns if kbyte.ring(spec, n)}
        t0 = time.time()
        print(f"{program}: {len(rings)} ring(s) of definitions that use themselves; the lemmas kept: {', '.join(sorted(bare)) or 'none'}")
        text, left, tries = guess(spec_text, start, say=print)
        ok = shown(spec_text, text)
        done = ok is not None and not kbyte.ends(ok)[1]
        total += len(rings); found += len(rings) - len(left)
        print(f"{program}: {'every definition shown to come to an end' if done else 'NOT all found'}; {tries} tries, {time.time() - t0:.1f} s")
    print(f"kguess: the number that decreases found for {found} of {total} rings")
    return 0 if found == total else 1


def main():
    if "--again" in sys.argv: return again()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    with open(args[0]) as f: spec_text = f.read()
    lemmas = ""
    if len(args) > 1:
        with open(args[1]) as f: lemmas = f.read()
    text, left, tries = guess(spec_text, lemmas, say=lambda s: print("//" + s))
    sys.stdout.write(text)
    return 1 if left else 0


if __name__ == "__main__":
    sys.exit(main())
