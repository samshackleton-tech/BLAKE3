#!/usr/bin/env python3
"""Tabulate smt-warm3.sh: ns/B per cell and PipelineL1 slots, by kernel and placement."""
import re, statistics as st, sys
from collections import defaultdict
from pathlib import Path

root = Path(sys.argv[1])
ns = defaultdict(list); td = defaultdict(lambda: defaultdict(list))
for d in sorted(root.glob('*-r*')):
    k, cfg, rep = d.name.split('-')
    for f in d.glob('benchmark-results/*/bench-hashes.samples.tsv'):
        for l in f.read_text().splitlines():
            if l.startswith('#') or l.startswith('contender'): continue
            p = l.split('\t')
            vals = [int(a) / int(b) for a, b in (x.split('/') for x in p[5].split(','))]
            ns[(k, cfg, p[3])].append(st.median(vals))
    t = (d / 'perf.txt').read_text()
    for m in re.finditer(r'#\s+([\d.]+) %(?:slots|ops)\s+(\w+)', t):
        td[(k, cfg)][m.group(2)].append(float(m.group(1)))
print('ns per byte, warm, one thread on CPU 0 (median of 5 processes; min-max)')
print('%-10s %-9s %24s %24s' % ('kernel', 'placement', '64 KiB', '1 MiB'))
for k in ('old', 'new'):
    for cfg in ('solo', 'separate', 'siblings'):
        row = '%-10s %-9s' % (k, cfg)
        for pt in ('64 KiB', '1 MiB'):
            v = ns[(k, cfg, pt)]
            row += '   %.4f (%.4f-%.4f)' % (st.median(v), min(v), max(v))
        print(row)
    for pt in ('64 KiB', '1 MiB'):
        s = st.median(ns[(k, 'solo', pt)]); sb = st.median(ns[(k, 'siblings', pt)])
        print('   %s %s: sibling busy costs x%.2f per thread; one core with two threads gives x%.2f of one' % (k, pt, sb / s, 2 * s / sb))
print()
print('PipelineL1, % of dispatch slots, median of 5 (whole bench process)')
cols = ['retiring', 'smt_contention', 'backend_bound', 'frontend_bound', 'bad_speculation']
print('%-10s %-9s' % ('kernel', 'placement') + ''.join('%16s' % c for c in cols))
for k in ('old', 'new'):
    for cfg in ('solo', 'separate', 'siblings'):
        print('%-10s %-9s' % (k, cfg) + ''.join('%16.1f' % st.median(td[(k, cfg)][c]) if td[(k, cfg)][c] else '%16s' % '-' for c in cols))
