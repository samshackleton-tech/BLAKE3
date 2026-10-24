#!/usr/bin/env python3
"""Run one bench process (argv after --) and poll its threads' CPUs every
2 ms from /proc; print per thread name the CPUs seen (counts), then the
process's solo ManyMessages|64 mean. Diagnostic only."""
import collections, glob, os, subprocess, sys, time
cmd = sys.argv[sys.argv.index('--') + 1:]
out_dir = sys.argv[1]
os.makedirs(out_dir, exist_ok=True)
p = subprocess.Popen(cmd, cwd=out_dir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
seen = collections.defaultdict(collections.Counter)
while p.poll() is None:
    for t in glob.glob(f'/proc/{p.pid}/task/*'):
        try:
            name = open(t + '/comm').read().strip()
            stat = open(t + '/stat').read()
            fields = stat[stat.rindex(')') + 2:].split()
            state, cpu = fields[0], int(fields[36])
            if state == 'R':
                seen[name][cpu] += 1
        except OSError:
            pass
    time.sleep(0.002)
def mean(path):
    for l in open(path):
        f = l.rstrip('\n').split('\t')
        if len(f) > 5 and f[2] == 'ManyMessages' and f[3] == '64' and f[1] == 'solo':
            v = [a.split('/') for a in f[5].split(',')]
            return sum(int(n) for n, u in v) / sum(int(u) for n, u in v)
s = glob.glob(out_dir + '/benchmark-results/*/bench-hashes.samples.tsv')
m = mean(s[0]) if s else float('nan')
print(f'many64={m:5.1f}', '; '.join(f'{n}: ' + ','.join(f'{c}x{k}' for c, k in cnt.most_common(4)) for n, cnt in sorted(seen.items())))
