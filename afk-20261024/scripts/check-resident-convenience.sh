#!/bin/bash
# Short boundary check using already-built 16-layout sets. These are the
# UNCHANGED convenience OneMessage cells, not direct-flow replacements.
# Record their costs too; do not infer them from performance-API wins.
set -euo pipefail
r=/root/results/afk-20261024-resident-convenience
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
old=/root/results/afk-20261024-runtime-control/bin/simd-words
new=/root/results/afk-20261024-resident-d/bin/resident-words
cd "$r"
set +e
taskset -c 0,2 "$old/bench-0" regress --contenders blake3-servil-st --points '64 B,256 B,1 KiB' --pairs 16 --keep "$r/samples" "$old"/bench-{0..15} -- "$new"/bench-{0..15} > regress.out 2> regress.err
code=$?
set -e
echo "regress exit=$code $(date -Is)" >> status.log
[ "$code" -le 2 ]
"$old/bench-0" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > compare.out 2> compare.err
