#!/usr/bin/env python3
"""Summarize smt-explain.sh's perf output (parts 1 and 2)."""
import re, statistics as st, sys
from collections import defaultdict
from pathlib import Path

root = Path(sys.argv[1])
GIB = 1 << 30

def csv(path):
    v = {}
    for line in path.read_text().splitlines():
        f = line.split(',')
        if len(f) > 3 and f[0] and f[0][0].isdigit():
            v[f[2]] = float(f[0])
    return v

# Part 1: per process: user cycles per byte, GHz, IPC
p1 = defaultdict(list)
for f in sorted((root / 'part1').glob('*.csv')):
    k, cfg, rep, cpu = f.stem.split('-')
    v = csv(f)
    cyc_u = v.get('cycles:u'); ins_u = v.get('instructions:u'); tc = v.get('task-clock')
    cyc = v.get('cycles')
    if not (cyc_u and ins_u and tc and cyc):
        print('incomplete', f, v); continue
    p1[(k, cfg)].append(dict(cpb=cyc_u / GIB, ipc=ins_u / cyc_u, ghz=cyc / (tc * 1e6), ms=tc,
                             ipb=ins_u / GIB))
print('Part 1: one thread hashing 1 GiB (b3sum --num-threads 1), per process, medians')
print('%-10s %-9s %4s %8s %7s %6s %6s %9s' % ('kernel', 'placement', 'n', 'cyc/B', 'ins/B', 'IPC', 'GHz', 'task ms'))
for k in ('candidate', 'official', 'baseline', 'wide'):
    solo = None
    for cfg in ('solo', 'separate', 'siblings', 'cores24', 'cpus48'):
        r = p1.get((k, cfg))
        if not r: continue
        m = {x: st.median(d[x] for d in r) for x in r[0]}
        if cfg == 'solo': solo = m
        print('%-10s %-9s %4d %8.3f %7.3f %6.2f %6.2f %9.1f' % (k, cfg, len(r), m['cpb'], m['ipb'], m['ipc'], m['ghz'], m['ms']))
    # SMT yield: two siblings' combined throughput over one thread alone on a
    # core, both in cycles (frequency aside): 2 * solo cyc/B / siblings cyc/B.
    sib = p1.get((k, 'siblings')); c48 = p1.get((k, 'cpus48')); c24 = p1.get((k, 'cores24'))
    if solo and sib:
        y = 2 * solo['cpb'] / st.median(d['cpb'] for d in sib)
        print('  %s: SMT yield, siblings vs alone (cycles): x%.2f' % (k, y))
    if c24 and c48:
        # whole machine: 48 threads' throughput over 24's, by task time (frequency in)
        t24 = st.median(d['ms'] for d in c24); t48 = st.median(d['ms'] for d in c48)
        print('  %s: whole machine, 48 threads over 24 (bytes per second): x%.2f' % (k, 2 * t24 / t48))

# Part 2: wall and CPU time of the candidate's pool
print()
print('Part 2: the candidate b3sum, medians of 9 (wall ms, CPU ms = user+sys)')
p2 = defaultdict(list)
for f in sorted((root / 'part2').glob('*.txt')):
    name, size, rep = f.stem.rsplit('-', 2)
    t = f.read_text()
    wall = float(re.search(r'([\d.]+) seconds time elapsed', t).group(1)) * 1e3
    user = float(re.search(r'([\d.]+) seconds user', t).group(1)) * 1e3
    sys_ = float(re.search(r'([\d.]+) seconds sys', t).group(1)) * 1e3
    p2[(name, int(size))].append((wall, user + sys_))
names = ['t48-all', 't24-unpinned', 't24-cores', 't36-mixed', 't24-siblings12']
print('%-8s' % 'MiB' + ''.join('%22s' % n for n in names))
for s in (4, 16, 256, 1024):
    row = '%-8d' % s
    base = st.median(w for w, _ in p2[('t48-all', s)])
    for n in names:
        r = p2.get((n, s))
        if not r: row += '%22s' % '-'; continue
        w = st.median(x for x, _ in r); c = st.median(y for _, y in r)
        row += '%9.2f x%.3f %6.0fc' % (w, w / base, c)
    print(row)
print('(each cell: wall ms, wall against t48-all, CPU ms)')
