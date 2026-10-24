#!/usr/bin/env python3
"""What is the "other programs" load during the b3sum "1000 x 16 KiB, a
process each" cell? Run a contender once per file (as that cell does), and
every 100 ms read /proc/stat's fields, this process's own CPU (self +
reaped children, as clocks::load counts it) and the kernel threads' CPU
(children of kthreadd). Print per-field totals of the unattributed time.
Diagnostic only.  usage: load-attribution.py DIR CONTENDER [ARGS...]"""
import os, subprocess, sys, threading, time

files = sorted(os.path.join(sys.argv[1], f) for f in os.listdir(sys.argv[1]))
cmd = sys.argv[2:]
TICK = os.sysconf('SC_CLK_TCK')
FIELDS = ['user', 'nice', 'system', 'idle', 'iowait', 'irq', 'softirq', 'steal']

def stat():
    v = list(map(int, open('/proc/stat').readline().split()[1:9]))
    return dict(zip(FIELDS, v))

def own():
    t = os.times()
    return t.user + t.system + t.children_user + t.children_system

ME = os.getpid()

def kthreads():
    """(kernel threads' CPU, other programs' CPU): the second is every
    process neither ours (this one and its descendants) nor a kernel thread,
    with its reaped children's time (cutime + cstime)."""
    procs = {}
    for pid in os.listdir('/proc'):
        if not pid.isdigit():
            continue
        try:
            s = open(f'/proc/{pid}/stat').read()
        except OSError:
            continue
        f = s[s.rindex(')') + 2:].split()
        procs[int(pid)] = (int(f[1]), int(f[11]) + int(f[12]), int(f[13]) + int(f[14]))
    kern = other = 0
    for pid, (ppid, cpu, reaped) in procs.items():
        if pid == 2 or ppid == 2:
            kern += cpu
            continue
        p, ours = pid, False
        while p in procs and p > 1:
            if p == ME:
                ours = True
                break
            p = procs[p][0]
        if not ours:
            other += cpu + reaped
    return kern / TICK, other / TICK

samples = []
done = threading.Event()
def sampler():
    while not done.is_set():
        samples.append((time.monotonic(), stat(), own(), kthreads()))
        time.sleep(0.1)
th = threading.Thread(target=sampler); th.start()
time.sleep(0.5)
for f in files:
    subprocess.run(cmd + [f], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(0.5)
done.set(); th.join()
(t0, s0, o0, (k0, p0)), (t1, s1, o1, (k1, p1)) = samples[0], samples[-1]
wall = t1 - t0
d = {k: (s1[k] - s0[k]) / TICK for k in FIELDS}
busy = sum(d[k] for k in FIELDS if k not in ('idle', 'iowait'))
print(f'wall {wall:.2f} s; busy {busy:.2f} CPU-s: ' + ', '.join(f'{k} {d[k]:.2f}' for k in FIELDS if k not in ('idle', 'iowait')))
print(f'own (self + children) {o1 - o0:.2f} CPU-s; kernel threads {k1 - k0:.2f} CPU-s')
other = busy - (o1 - o0)
print(f'unattributed (busy - own) {other:.2f} CPU-s = {other / wall:.2f} CPUs; of it irq+softirq {d["irq"] + d["softirq"]:.2f}, kernel threads {k1 - k0:.2f}, rest {other - d["irq"] - d["softirq"] - (k1 - k0):.2f}')
print(f'other programs, counted directly: {p1 - p0:.2f} CPU-s = {(p1 - p0) / wall:.2f} CPUs')
