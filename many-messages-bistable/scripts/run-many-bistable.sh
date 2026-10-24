#!/bin/bash
# Solo ManyMessages is bistable per process (~24 vs ~40 ns/msg at 64
# messages), A/A included, buffers aligned. Does the state follow the main
# thread's stack position? Base b94e2fa, diag-align64 build. 32 processes with
# ASLR off and the environment moving the main stack by k*128 bytes, then 16
# with ASLR on. Diagnostic only.
set -u
r=/root/results/many-bistable
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
exe=/root/results/smalloc/align64/align64-base
one() {
    out=$1; shift
    mkdir -p "$out"
    ( cd "$out" && "$@" "$exe" --contenders blake3-servil-st --points '64,256' --for-regression-check --rounds 24 > run.out 2> run.err )
}
for k in $(seq 0 31); do
    pad=$(python3 -c "print('x' * ($k * 128))")
    one "$r/pad-$k" setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root OFFSET_CHECK_PAD="$pad"
done
for n in $(seq 1 16); do
    one "$r/aslr-$n" env -i PATH=/usr/bin:/bin HOME=/root
done
python3 - "$r" <<'PY' > "$r/summary.txt"
import glob, os, re, sys
sys.path.insert(0, '/root')
import offset_check as o
root = sys.argv[1]
for d in sorted(glob.glob(root + '/*-*'), key=lambda p: (p.split('/')[-1].split('-')[0], int(p.split('-')[-1]))):
    rep = glob.glob(d + '/benchmark-results/*/bench-hashes.result.txt')
    if not rep:
        print(os.path.basename(d), 'no report'); continue
    cells = o.parse_report(open(rep[0]).read())
    vals = {k: v for k, v in cells.items() if 'many' in ' '.join(map(str, k)).lower() or 'Many' in ' '.join(map(str, k))}
    print(os.path.basename(d), ' '.join(f'{"|".join(map(str, k))}={v:.2f}' for k, v in sorted(vals.items())))
PY
printf 'done\n' > "$r/complete"
