#!/usr/bin/env python3
"""Per allocator and ASLR setting: how many distinct main-thread input
offsets (mod 4096) and stack offsets across the 16 processes, by length."""
import collections, glob, os, re, sys

root = sys.argv[1]
groups = collections.defaultdict(lambda: collections.defaultdict(list))
for d in glob.glob(root + '/addr-*'):
    if not os.path.isdir(d):
        continue
    _, exe, aslr, n = os.path.basename(d).rsplit('-', 3)[0].split('-', 1)[0], *os.path.basename(d)[5:].rsplit('-', 2)
    hits = [tuple(map(int, h)) for h in re.findall(r'@\[(\d+), (\d+), (\d+)\]: (\d+)', open(d + '/probe.txt').read())]
    for ln in (64, 256):
        c = collections.Counter({(si, di): k for l, si, di, k in hits if l == ln})
        if c:
            groups[(exe, aslr)][ln].append(c.most_common(1)[0][0])
for (exe, aslr), by_len in sorted(groups.items()):
    for ln, pairs in sorted(by_len.items()):
        ins = collections.Counter(p[0] for p in pairs)
        sts = collections.Counter(p[1] for p in pairs)
        print(f'{exe:13} ASLR {aslr:3} {ln:3} B: {len(pairs)} processes; input offsets {len(ins)} distinct {dict(ins.most_common(4))}; stack offsets {len(sts)} distinct')
