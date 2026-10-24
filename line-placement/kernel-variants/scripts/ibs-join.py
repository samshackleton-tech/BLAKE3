#!/usr/bin/env python3
"""Join `perf report -D` IBS op decodes with `perf script` symbols by
(tid, timestamp); per (symbol+offset): samples, load/store, mean and max
tag-to-retire cycles, data addresses mod 4096. Diagnostic only.

usage: ibs-join.py DUMP SCRIPT COMM [SYMBOL_SUBSTRING...]"""
import collections, re, sys

dump, script, comm = sys.argv[1:4]
want = [w for w in sys.argv[4:] if w != '--mem']
mem_only = '--mem' in sys.argv[4:]
sym = {}
for line in open(script, errors='replace'):
    m = re.match(r'\s*(\S+)\s+(\d+)\s+(\d+\.\d+):\s+([0-9a-f]+)\s+(.+?)\s*$', line)
    if m and m.group(1).startswith(comm[:15]):
        t = int(m.group(3).replace('.', ''))
        sym[(int(m.group(2)), t)] = m.group(5)
ops = []
cur = {}
for line in open(dump, errors='replace'):
    m = re.match(r'\d+ (\d+) 0x[0-9a-f]+ \[0x[0-9a-f]+\]: PERF_RECORD_SAMPLE\(IP, 0x[0-9a-f]+\): (\d+)/(\d+):', line)
    if m:
        cur['t'] = int(m.group(1)); cur['tid'] = int(m.group(3))
        ops.append(cur); cur = {}
        continue
    if line.startswith('ibs_op_data:'):
        cur['ttr'] = int(re.search(r'TagToRetCtr\s+(\d+)', line).group(1))
    elif line.startswith('ibs_op_data3:'):
        cur['ld'] = ' LdOp 1' in line; cur['st'] = ' StOp 1' in line
        cur['lin'] = 'DcLinAddrValid 1' in line
        w = re.search(r'OpMemWidth\s+(\d+)', line); cur['w'] = int(w.group(1)) if w else 0
    elif line.startswith('IbsDCLinAd:'):
        cur['addr'] = int(line.split()[1], 16)
# The decode lines precede their PERF_RECORD_SAMPLE line in -D output.
by = collections.defaultdict(list)
for o in ops:
    s = sym.get((o.get('tid'), o.get('t')))
    if s is None or (want and not any(x in s for x in want)):
        continue
    if mem_only and not (o.get('ld') or o.get('st')):
        continue
    by[s].append(o)
print(f'{len(ops)} ops decoded, {sum(len(v) for v in by.values())} matched')
rows = sorted(by.items(), key=lambda kv: -sum(o.get('ttr', 0) for o in kv[1]))
for s, v in rows[:40]:
    ttr = [o.get('ttr', 0) for o in v]
    kind = 'LD' if any(o.get('ld') for o in v) else ('ST' if any(o.get('st') for o in v) else '  ')
    addrs = collections.Counter(o['addr'] % 4096 for o in v if o.get('lin') and 'addr' in o)
    print(f'{s[-48:]:48} {kind} n={len(v):5} mean_ttr={sum(ttr)/len(ttr):6.1f} max={max(ttr):5} sum={sum(ttr):7} addr%4096={dict(addrs.most_common(3))}')
