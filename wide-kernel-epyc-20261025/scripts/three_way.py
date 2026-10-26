#!/usr/bin/env python3
"""Per-cell: E = wide kernel everywhere (a49ff2c), C = calling threads only
(2cf9a56), each against old (a9e70b8), geometric means over two check runs
each; and C/E. Grouped by contender, scenario and use case."""
import math, re, statistics as st, sys
from collections import defaultdict
L = re.compile(r'blake3-servil-(st|mt)\|(\w+)\|(\w+)\|(.+?): ([\d.]+) -> ([\d.]+) ns/unit\s+x([\d.]+) (\w+), (\d+) of')
def load(f):
    return {(m[1], m[2], m[3], m[4]): (float(m[7]), m[8]) for m in map(L.match, open(f)) if m}
def gm(xs): return math.exp(sum(map(math.log, xs)) / len(xs))
E1, E2 = load('data/lib1-compare.out'), load('data/lib2-compare.out')
C1, C2 = load('data/caller/lib1-compare.out'), load('data/caller/lib2-compare.out')
AA = load('data/aa-compare.out')
keys = sorted(set(E1) & set(E2) & set(C1) & set(C2))
cells = {}
for k in keys:
    cells[k] = dict(E=gm([E1[k][0], E2[k][0]]), C=gm([C1[k][0], C2[k][0]]), aa=AA.get(k, (float('nan'),))[0],
                    Ev=[E1[k][1], E2[k][1]], Cv=[C1[k][1], C2[k][1]])
    cells[k]['CE'] = cells[k]['C'] / cells[k]['E']
import json; json.dump({'|'.join(k): v for k, v in cells.items()}, open('data/three-way.json', 'w'), indent=0)
g = defaultdict(list)
for k, v in cells.items(): g[(k[0], k[1], k[2])].append((k[3], v))
print('%-3s %-6s %-20s %3s | %-26s | %-26s | %-15s' % ('', '', 'use case', 'n', 'everywhere/old med (min-max)', 'caller-only/old med (min-max)', 'caller/everywhere'))
for key in sorted(g):
    vs = [v for _, v in g[key]]
    f = lambda a: '%.3f (%.3f-%.3f)' % (st.median(x[a] for x in vs), min(x[a] for x in vs), max(x[a] for x in vs))
    print('%-3s %-6s %-20s %3d | %-26s | %-26s | %s' % (key[0], key[1], key[2], len(vs), f('E'), f('C'), f('CE')))
print()
diff = sorted(cells.items(), key=lambda kv: kv[1]['CE'])
print('caller-only most faster than everywhere:')
for k, v in diff[:12]: print('   %-45s E x%.3f  C x%.3f  C/E x%.3f' % ('|'.join(k), v['E'], v['C'], v['CE']))
print('caller-only most slower than everywhere:')
for k, v in diff[-16:]: print('   %-45s E x%.3f  C x%.3f  C/E x%.3f  E:%s C:%s' % ('|'.join(k), v['E'], v['C'], v['CE'], '/'.join(v['Ev']), '/'.join(v['Cv'])))
