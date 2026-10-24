#!/bin/bash
# Solo ManyMessages 64 bistability: SMT siblings? The process (main + duo
# copy threads) confined to (a) one logical CPU of every physical core
# (0-23), (b) a whole physical core's two siblings (0,24) plus core 1 (1,25),
# (c) unconfined. 10 processes each, ASLR off, base b94e2fa diag-align64.
set -u
r=/root/results/many-bistable/smt
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
exe=/root/results/smalloc/align64/align64-base
lscpu -e=CPU,CORE > "$r/topology.txt"
for spec in physical:0-23 siblings:0,24,1,25 free:; do
    name=${spec%%:*}; cpus=${spec#*:}
    for n in $(seq 1 10); do
        o="$r/$name-$n"; mkdir -p "$o"
        if [ -n "$cpus" ]; then pre=(taskset -c "$cpus"); else pre=(); fi
        ( cd "$o" && "${pre[@]}" setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root "$exe" --contenders blake3-servil-st --points '64' --for-regression-check --rounds 24 > run.out 2> run.err )
    done
done
python3 - "$r" <<'PY' > "$r/summary.txt"
import glob, sys
r = sys.argv[1]
def mean(path):
    for l in open(path):
        f = l.rstrip('\n').split('\t')
        if len(f) > 5 and f[2] == 'ManyMessages' and f[3] == '64' and f[1] == 'solo':
            v = [a.split('/') for a in f[5].split(',')]
            return sum(int(n) for n, u in v) / sum(int(u) for n, u in v)
for name in ('physical', 'siblings', 'free'):
    vals = []
    for n in range(1, 11):
        s = glob.glob(f'{r}/{name}-{n}/benchmark-results/*/bench-hashes.samples.tsv')
        vals.append(mean(s[0]) if s else float('nan'))
    print(f'{name:9}', ' '.join(f'{v:5.1f}' for v in vals))
PY
printf 'done\n' > "$r/complete"
