#!/bin/bash
# Attribution only: perf samples identify the kernel paths. These profiled
# runs are NOT used for performance verdicts (the separate paired run is).
set -euo pipefail
r=/root/results/gpr-chunk-root/direct-flow/profiles
mkdir -p "$r"
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
exe=/root/results/gpr-chunk-root/direct-flow/bin/gpr-0
for name in latency batch stream stream-batch; do
    case "$name" in
        latency) contender=blake3-servil-st; point='lent 1 KiB'; cpus=2;;
        batch) contender=blake3-servil-st; point='lent batch 64'; cpus=2;;
        stream) contender=blake3-servil-mt; point='continuous 64 B'; cpus=0,2,4,6;;
        stream-batch) contender=blake3-servil-mt; point='continuous batch 64'; cpus=0,2,4,6;;
    esac
    o="$r/$name"; mkdir -p "$o"
    (cd "$o" && taskset -c "$cpus" perf record -q -e cpu/cycles,period=10007/u -o "$o/perf.data" -- "$exe" --threads 4 --contenders "$contender" --points "$point" --for-regression-check --rounds 96 > run.out 2> run.err)
    perf report --stdio -i "$o/perf.data" --no-children -n --sort sym --percent-limit 0.5 > "$o/report.txt" 2> "$o/report.err"
done
