#!/usr/bin/env python3
"""Median per cell, by placement, from bench-hashes reports of one contender:
runs/<P>-<i>/result.txt, solo section, every table. Usage: placement_table.py OUT_DIR"""
import collections, glob, re, statistics as st, sys

vals = collections.defaultdict(lambda: collections.defaultdict(list))
for d in sorted(glob.glob(f"{sys.argv[1]}/runs/*")):
    p = d.rsplit("/", 1)[1].split("-")[0]
    text = open(f"{d}/result.txt").read()
    solo = text.split("\nSOLO:", 1)[1].split("\nSHARED:", 1)[0]
    for block in re.split(r"\n\s*\n", solo):
        lines = [l for l in block.splitlines() if l.strip()]
        if len(lines) < 3 or not re.search(r"\((ns/[A-Za-z]+)\)\s*$", lines[0]):
            continue
        title = lines[0].strip()
        for row in lines[2:]:
            f = row.split()
            try:
                v = float(f[-1])
            except ValueError:
                continue
            vals[(title, " ".join(f[:-1]))][p].append(v)
places = sorted({p for v in vals.values() for p in v})
print(f"{'cell':70} " + " ".join(f"{p:>8}" for p in places) + "   last/first")
for (title, point), v in vals.items():
    meds = [st.median(v[p]) if v[p] else float("nan") for p in places]
    print(f"{(title[:52] + ' | ' + point):70} " + " ".join(f"{m:8.3f}" for m in meds) + f"   x{meds[-1] / meds[0]:.2f}")
