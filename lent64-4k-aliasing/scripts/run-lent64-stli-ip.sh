#!/bin/bash
# Where do the duo threads' store-to-load conflicts occur? Sample
# ls_bad_status2.stli_other (and cycles) by symbol/instruction, old vs new,
# one direct process each for the focused cell. Also IBS op samples with
# data addresses for precise attribution. Diagnostic only.
set -u
r=/root/results/avx512-registers/lent64-stli-ip
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
b=/root/BLAKE3-stream-wake-guarded/target/check
for spec in old:0 new:4; do
    side=${spec%%:*}; i=${spec#*:}; exe=$b/$side/bench-hashes-$i; out="$r/$side"; mkdir -p "$out"
    args=(--threads 48 --contenders blake3-servil-st,blake3-servil-mt --points 'lent 64 B' --for-regression-check --rounds 48)
    ( cd "$out" && perf record -q -e ls_bad_status2.stli_other/period=1009/u -e cpu/cycles,period=100003/u -o "$out/stli.data" -- "$exe" "${args[@]}" ) > "$out/stli-run.out" 2> "$out/stli-run.err"
    perf report --stdio -i "$out/stli.data" --comm duo-copy-0,duo-copy-1 --sort sym --no-children -n > "$out/stli-by-sym.txt" 2> "$out/stli-by-sym.err"
    ( cd "$out" && perf record -q -e ibs_op//u -c 20003 -d -o "$out/ibs.data" -- "$exe" "${args[@]}" ) > "$out/ibs-run.out" 2> "$out/ibs-run.err"
    perf script -i "$out/ibs.data" -F comm,ip,sym,addr --comms duo-copy-0,duo-copy-1 > "$out/ibs.txt" 2> "$out/ibs.err"
    echo "$side done" >> "$r/status.log"
done
printf 'done\n' > "$r/complete"
