#!/usr/bin/env python3
"""Paired new/old medians from a check's --keep directory (run-NNN-{old,new}.tsv,
pairs in order). Prints the median of the cells' medians, the most-slower cells,
and the cells named with --cells (substring match on contender|scenario|use|point).
Usage: pair_medians.py DIR [--cells A,B,...] [--top N]"""
import collections, glob, os, statistics as st, sys

def runs(d):
    out = []
    for f in sorted(glob.glob(os.path.join(d, "run-*.tsv"))):
        side = "new" if f.endswith("-new.tsv") else "old"
        hdr, cells = None, {}
        for line in open(f):
            if line.startswith("#"):
                continue
            p = line.rstrip("\n").split("\t")
            if hdr is None:
                hdr = p
                continue
            r = dict(zip(hdr, p))
            ns = u = 0.0
            for x in r["ns/units"].split(","):
                a, b = x.split("/")
                ns += float(a); u += float(b)
            if u:
                cells["|".join((r["contender"], r["scenario"], r["use_case"], r["point"]))] = ns / u
        out.append((side, cells))
    return out

def medians(d):
    R = runs(d)
    rat = collections.defaultdict(list)
    for i in range(0, len(R) - 1, 2):
        a, b = R[i], R[i + 1]
        if {a[0], b[0]} != {"old", "new"}:
            raise SystemExit(f"{d}: runs {i+1},{i+2} are not an old/new pair")
        o, n = (a[1], b[1]) if a[0] == "old" else (b[1], a[1])
        for k in n:
            if k in o and o[k] > 0:
                rat[k].append(n[k] / o[k])
    return len(R) // 2, rat

def main():
    args = sys.argv[1:]
    d = args[0]
    want = []
    top = 6
    if "--cells" in args:
        want = args[args.index("--cells") + 1].split(",")
    if "--top" in args:
        top = int(args[args.index("--top") + 1])
    for sub in (d, os.path.join(d, "second")):
        if not glob.glob(os.path.join(sub, "run-*.tsv")):
            continue
        n, rat = medians(sub)
        med = {k: st.median(v) for k, v in rat.items()}
        print(f"{sub}: {n} pairs, {len(med)} cells, median of medians {st.median(med.values()):.3f}")
        for k, v in sorted(med.items(), key=lambda kv: -kv[1])[:top]:
            print(f"  slowest {v:.3f}  {k}")
        for w in want:
            for k in sorted(med):
                if w in k:
                    v = sorted(rat[k])
                    print(f"  cell {med[k]:.3f}  new slower {sum(x > 1 for x in v)}/{len(v)}  {k}")

main()
