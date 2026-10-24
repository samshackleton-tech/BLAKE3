#!/usr/bin/env python3
"""Aggregate perf-report per-thread event totals (sampled counters, not
timings): main thread (solo samples) vs duo-copy-0/1 (shared samples)."""
import collections, pathlib, re, sys

root = pathlib.Path(sys.argv[1])
tot = collections.defaultdict(lambda: collections.defaultdict(int))
for f in root.glob('*.report'):
    side = f.name.split('-')[0]
    event = None
    for line in f.read_text().splitlines():
        m = re.match(r"# Samples: .* of event '(.+)'$", line)
        if m:
            event = m.group(1)
            continue
        if line.startswith('#') or not line.strip() or event is None:
            continue
        p = line.split()
        if len(p) >= 4 and p[0].endswith('%'):
            comm = ' '.join(p[3:])
            if comm.startswith('bench-hashes'):
                comm = 'main'
            if comm.startswith('duo-copy') or comm == 'main':
                tot[(side, comm)][event] += int(p[2])


def short(event):
    return re.sub(r'^cpu/|/u$', '', event).split(',')[0].split('/')[0]


def get(d, key):
    return sum(v for e, v in d.items() if key in e)


events = sorted({e for d in tot.values() for e in d})
print(f"{'side/thread':20}" + ''.join(f'{short(e)[:26]:>28}' for e in events))
for k in sorted(tot):
    print(f'{k[0] + "/" + k[1]:20}' + ''.join(f'{tot[k][e]:>28,}' for e in events))
print()
for k in sorted(tot):
    d = tot[k]
    c, i = get(d, 'cycles'), get(d, 'instructions')
    print(f'{k[0] + "/" + k[1]:20} IPC={i / c:.3f}  per 1k instructions: '
          f'store-load conflicts={1000 * get(d, "stli") / i:.3f}  '
          f'load-not-complete cycles={1000 * get(d, "load_not_complete") / i:.1f}  '
          f'smt-contention slots={1000 * get(d, "smt_contention") / i:.1f}  '
          f'dTLB misses={1000 * get(d, "tlb_miss") / i:.3f}')
