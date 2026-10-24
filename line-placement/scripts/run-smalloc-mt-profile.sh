#!/bin/bash
# Why is servil mt slower under smalloc (continuous 4 MiB +39%, outboard 1 MiB
# +23%, lent 1 MiB +22%)? Same relinked layout index on each side; whole-
# process counters, then cycles and store-to-load conflicts by symbol. Also the
# addresses of the buffers involved (main thread's hash_multithreaded input).
set -u
r=/root/results/smalloc/mt-profile
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
bin=/root/results/smalloc/speed/bin
for side in glibc smalloc; do
    exe=$bin/$side-0; out="$r/$side"; mkdir -p "$out"
    args=(--contenders blake3-servil-mt --points 'continuous 4 MiB,outboard 1 MiB,lent 1 MiB' --for-regression-check --rounds 24)
    ( cd "$out" && perf stat -o "$out/stat.txt" -e task-clock,cycles,instructions,page-faults,dTLB-load-misses,ls_bad_status2.stli_other,cache-misses,context-switches -- "$exe" "${args[@]}" ) > "$out/stat-run.out" 2> "$out/stat-run.err"
    ( cd "$out" && perf record -q -g -e cpu/cycles,period=200003/u -e ls_bad_status2.stli_other/period=2003/u -o "$out/perf.data" -- "$exe" "${args[@]}" ) > "$out/rec-run.out" 2> "$out/rec-run.err"
    perf report --stdio -i "$out/perf.data" --no-children -n --sort sym --percent-limit 1 -g none > "$out/report.txt" 2> "$out/report.err"
    grep -B1 -A8 -E 'Messages one after another, buffers owned|outboards|buffers lent' "$out"/benchmark-results/*/bench-hashes.result.txt > "$out/cells.txt" 2>/dev/null
done
printf 'done\n' > "$r/complete"
