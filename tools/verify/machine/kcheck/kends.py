#!/usr/bin/env python3
"""kends: do the definitions a contract speaks through come to an end, on everything the contract allows?

A definition that uses itself could go on for ever on some input; a contract written with it would then say
nothing of that input, and reading the contract would not show it. A lemma may name a number that
`decreases` (kbyte.py's prove_lemmas shows it). That alone is not enough to say "it comes to an end", for a
lemma speaks only where its `requires` holds, and a lemma comes with the proof, which is not trusted: one
that requires the impossible (`requires at < at`) is shown, of nothing. Until November 16, 2026 the line a
verification printed counted such a lemma. So, for a contract:

  1. every definition that uses itself, among those the contract's text reaches, has a lemma that names a
     number that decreases, and the lemmas are shown (prove_lemmas);
  2. each use of a definition by the contract's own text meets what the lemmas require: the definition is
     gone through once from what the contract gives it (an argument of the contract as it is, with its
     length and what the contract `requires`; anything else the contract writes there, a part of what the
     function wrote for one, as any bytes or any thing at all), every use inside of a definition with a
     lemma taken by that lemma, whose `requires` must be shown there.

  3. nothing that is taken without being gone through has, among what it reaches, a definition that uses
     itself: a sequence (taken a place at a time), and a definition whose lemma says nothing of it
     (`lemma NAME(...): any { }`, which prove_lemmas does not go through either). Until November 16, 2026
     such a lemma, or a sequence, between the contract and a definition that uses itself hid that
     definition's uses from this question.

Inside a ring the same is asked where its lemmas are shown (a use of one of the ring must meet its lemma's
`requires` and be less). So from the contract inward every use is one a lemma speaks of.

    python3 kends.py SPEC [LEMMAS]     a line for each contract of the specification"""
import itertools, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kfn, kterms, ode


def calls_of(spec, c):
    """Every use of one of the specification's definitions in the contract's text: [(name, [argument])]."""
    out = []
    def walk(x):
        if isinstance(x, tuple) and len(x) == 3 and x[0] == "call" and isinstance(x[1], str) and (x[1] in spec.fns or x[1] in spec.seqs or x[1] in spec.machines) and (x[1], x[2]) not in out: out.append((x[1], x[2]))
        if isinstance(x, dict):
            for y in x.values(): walk(y)
        elif isinstance(x, (tuple, list)):
            for y in x: walk(y)
    for part in ("returns", "leaves", "conditions", "asks", "given", "stack"): walk(c.get(part))
    return out


def uses_all(spec, name):
    """The definitions and sequences (those written with `for` or `while` too) that the text of `name` applies."""
    out = set()
    def walk(x):
        if isinstance(x, tuple) and len(x) == 3 and x[0] == "call" and isinstance(x[1], str) and (x[1] in spec.fns or x[1] in spec.seqs or x[1] in spec.machines): out.add(x[1])
        if isinstance(x, dict):
            for y in x.values(): walk(y)
        elif isinstance(x, (tuple, list)):
            for y in x: walk(y)
    if name in spec.fns: walk(spec.fns[name][1])
    elif name in spec.seqs: walk([spec.seqs[name][3], spec.seqs[name][4]])      # a sequence: its first value and the next from one
    else: walk(spec.machines[name])
    return out


def reached(spec, names):
    """`names` and everything their texts apply, through any number of others."""
    seen, todo = set(), list(names)
    while todo:
        n = todo.pop()
        if n in seen or not (n in spec.fns or n in spec.seqs or n in spec.machines): continue
        seen.add(n); todo += list(uses_all(spec, n))
    return seen


def skipped(spec, name):
    """Why `name` is taken here without its text being gone through with what it is given, or None. A sequence
    is taken a place at a time. A definition whose lemma says nothing (`lemma NAME(...): any { }`) is taken by
    that lemma, and prove_lemmas does not go through it either."""
    if name in spec.seqs or name in spec.machines: return "a sequence, which is not gone through"
    l = spec.lemmas.get(name)
    if l is not None and l["index"] is None and l["kind"] == "any" and not l["ensures"] and l["decreases"] is None:
        return "its lemma says nothing of it, so it is not gone through"
    return None


def ends_for(spec, symbol):
    """(the definitions that use themselves among those the contract reaches, None or why it is not shown that
    they come to an end on everything the contract allows). The lemmas are taken as shown (prove_lemmas)."""
    c = spec.contracts[symbol]
    calls = calls_of(spec, c)
    defs = reached(spec, [f for f, _ in calls])
    again = sorted(n for n in defs if n in reached(spec, uses_all(spec, n)))      # used by what it uses, or by itself
    round_ = sorted(m for m in defs if m in spec.machines and spec.machines[m]["loop"][0] == "while")
    if round_: return sorted(set(again) | set(round_)), f"{', '.join(round_)} goes round while something holds, and that it stops is not shown"
    if not again: return again, None
    bare = [n for n in again if n not in spec.lemmas or spec.lemmas[n]["decreases"] is None]
    if bare: return again, f"no number that decreases is named for {', '.join(bare)}"
    for u in sorted(defs):                                       # what is not gone through must have nothing under it that uses itself
        why = skipped(spec, u)
        inner = sorted(x for x in reached(spec, uses_all(spec, u)) if x in again) if why else []
        if inner: return again, f"{u} is {why}, and it reaches {', '.join(inner)}, which use{'s itself' if len(inner) == 1 else ' themselves'}: that the uses there come to an end is not shown"
    kinds = dict(c["args"])
    size = {name: kfn.bytes_kind(kind) for name, kind in c["args"]}
    for f, args in calls:
        if f in spec.seqs or f in spec.machines: continue                              # a sequence comes to its place k in k steps; what it uses is reached through `reached`
        params, requires, given = [], [], []
        def number(n):
            if (n, "number") not in params: params.append((n, "number"))
        for k, a in enumerate(args):
            if a[0] == "name" and size.get(a[1]) is not None:    # bytes the function is given, as they are
                if (a[1], "bytes") not in params: params.append((a[1], "bytes"))
                n = size[a[1]]
                if isinstance(n, str): number(n)
                requires.append(("bin", "==", ("call", "len", [a]), ("num", n) if isinstance(n, int) else ("name", n)))
                given.append(a[1])
            elif a[0] == "name" and kinds.get(a[1]) in ("number", "byte"):
                number(a[1])
                if kinds[a[1]] == "byte": requires.append(("bin", "<=", a, ("num", 255)))
                given.append(a[1])
            elif a[0] == "slice" and a[1][0] == "name" and size.get(a[1][1]) is not None:
                params.append((f"part{k}", "bytes")); given.append(f"part{k}")            # a part of some bytes: any bytes
            elif a[0] == "num":
                params.append((f"number{k}", "number")); requires.append(("bin", "==", ("name", f"number{k}"), a)); given.append(f"number{k}")
            else:
                params.append((f"thing{k}", "any")); given.append(f"thing{k}")            # anything else: a thing of which nothing is known
        named = {p for p, _ in params}
        def only(e):
            ok = [True]
            def walk(x):
                if isinstance(x, tuple) and len(x) == 2 and x[0] == "name" and x[1] not in named and x[1] not in spec.consts: ok[0] = False
                if isinstance(x, (tuple, list)):
                    for y in x: walk(y)
            walk(e)
            return ok[0]
        requires += [e for e in c["asks"] if only(e)]            # what the contract requires of these
        what = f"{symbol}'s {f}({', '.join(given)})"
        l = dict(params=params, index=None, kind="any", fields=[], requires=requires, ensures=[], decreases=None)
        try:
            m0, values, env0 = kbyte.lemma_machine(spec, what, l)
            tag = next(kbyte.FRESH)
            def one(m):
                A = kbyte.Opening(m, spec, None, tag)
                spec.apply(A, f, [env0[g] for g in given])
            kbyte.lemma_cases(m0, one, what)
        except (kterms.Fail, ode.Err) as err: return again, f"{what}: {err}"
    return again, None


def line(spec, symbols):
    """The line a verification prints, for the public contracts of a file."""
    again, why = set(), []
    for s in symbols:
        a, w = ends_for(spec, s)
        again |= set(a)
        if w: why.append(w)
    if not again: return "no definition its contracts speak through uses itself: each comes to an end"
    names = ", ".join(sorted(again))
    if not why: return f"the definitions its contracts speak through that use themselves ({names}): each is shown to come to an end on everything the contracts allow (a number that decreases, in a lemma)"
    return f"the definitions its contracts speak through that use themselves ({names}): NOT shown to come to an end on everything the contracts allow: {'; '.join(why)[:300]} (a contract says nothing of an input on which one does not)"


def main():
    with open(sys.argv[1]) as f: text = f.read()
    lemmas = ""
    if len(sys.argv) > 2:
        with open(sys.argv[2]) as f: lemmas = f.read()
    spec = ode.with_proof(text, lemmas) if lemmas else ode.Spec(text)
    try: kbyte.prove_lemmas(spec)
    except (kterms.Fail, ode.Err) as err: print(f"the lemmas are not shown: {err}"); return 1
    bad = 0
    for symbol in ode.Spec(text).contracts:
        again, why = ends_for(spec, symbol)
        print(f"{symbol}: " + ("uses no definition that uses itself" if not again else f"{', '.join(again)}: " + ("each comes to an end on everything the contract allows" if why is None else f"NOT shown: {why}")))
        bad += why is not None
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
