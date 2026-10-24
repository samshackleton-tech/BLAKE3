#!/usr/bin/env python3
"""Per-axis summary of offset_check --map tables: shared cells against the
thread-stack axis, solo cells against the main-stack axis (each cell feels
only its own thread's stack); the default offset belongs to both. Also the
slow fraction by main-stack offset modulo 32/64, to tell page aliasing
(narrow windows) from alignment (residue classes). Diagnostic only."""
import collections, csv, statistics, sys

for f in sys.argv[1:]:
    rows = list(csv.reader(open(f), delimiter='\t'))
    head, data = rows[0][1:], {r[0]: list(map(float, r[1:])) for r in rows[1:]}
    print(f'===== {f}')
    for j, cell in enumerate(head):
        axis = 'thread-stack' if cell.startswith('shared') else 'main-stack'
        vals = {k: v[j] for k, v in data.items() if k == 'default' or k.startswith(axis)}
        lo, med, hi = min(vals.values()), statistics.median(vals.values()), max(vals.values())
        slow = sorted((k for k, v in vals.items() if v >= lo * 1.05), key=lambda k: int(k.split('+')[1]) if '+' in k else 0)
        line = (f'{cell[:66]:66} best {lo:.3f} median {med:.3f} worst {hi:.3f} ({hi / lo:.2f}x); '
                f'slow {len(slow)}/{len(vals)}; default {vals["default"] / lo:.2f}x')
        if 0 < len(slow) <= 8:
            line += ': ' + ', '.join(s.replace(axis, '') for s in slow)
        print(line)
        if axis == 'main-stack' and len(slow) > 8:
            for mod in (32, 64):
                c = collections.defaultdict(lambda: [0, 0])
                for k, v in vals.items():
                    pad = int(k.split('+')[1]) if '+' in k else 0
                    c[pad % mod][0] += v >= lo * 1.05
                    c[pad % mod][1] += 1
                print(f'    slow by pad mod {mod}: ' + ' '.join(f'{k}:{a}/{b}' for k, (a, b) in sorted(c.items())))
