#!/usr/bin/env python3
"""Duo-copy threads' IPC and store-to-load conflicts per 1k instructions,
from perf report --sort comm --show-total-period (sampled counts)."""
import collections, glob, re, sys

for d in sorted(glob.glob(sys.argv[1] + '/*-*')):
    tot = collections.defaultdict(int)
    event = None
    for line in open(d + '/by-thread.txt'):
        m = re.match(r"# Samples: .* of event '(.+)'$", line.strip())
        if m:
            event = m.group(1)
            continue
        p = line.split()
        if event and len(p) >= 4 and p[0].endswith('%') and p[3].startswith('duo-copy'):
            tot[event] += int(p[2])
    get = lambda key: sum(v for e, v in tot.items() if key in e)
    c, i, s = get('cycles'), get('instructions'), get('stli')
    print(f"{d.rsplit('/', 1)[1]:12} duo threads: IPC {i / c if c else 0:.2f}, store-to-load conflicts per 1k instructions {1000 * s / i if i else 0:.2f}")
