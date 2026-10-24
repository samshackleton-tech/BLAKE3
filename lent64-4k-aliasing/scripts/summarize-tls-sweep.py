#!/usr/bin/env python3
"""Tabulate the TLS-surplus sweep: duo threads' stack/input offsets (from
bpftrace) beside the bench's own printed 64 B cell means (diagnostic runs,
not verdicts)."""
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])
for side in ['old', 'new']:
    print(f'== {side} build')
    print(f"  {'surplus':>8} {'ret-slot%4096':>14} {'input%4096':>10} {'(input-ret)%4096':>17} {'solo st/mt':>12} {'SHARED st/mt':>14}")
    for d in sorted((root / side).glob('tls-*'), key=lambda p: int(p.name[4:])):
        keys = sorted(set(re.findall(r'@\[duo-copy-\d, (\d+), (\d+)\]', (d / 'probe.txt').read_text())))
        res = list(d.glob('benchmark-results/*/bench-hashes.result.txt'))
        vals = re.findall(r'64 B\s+([\d.]+)\s+([\d.]+)', res[0].read_text()) if res else []
        solo = '/'.join(vals[0]) if vals else '?'
        shared = '/'.join(vals[1]) if len(vals) > 1 else '?'
        ret = ','.join(a for a, _ in keys)
        inp = ','.join(b for _, b in keys)
        diff = ','.join(str((int(b) - int(a)) % 4096) for a, b in keys)
        print(f'  {d.name[4:]:>8} {ret:>14} {inp:>10} {diff:>17} {solo:>12} {shared:>14}')
