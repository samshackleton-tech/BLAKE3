#!/bin/bash
# Why is the chunk-root fix's 64 B uniformly slower with its buffer 16 or 48
# bytes into a line (1.30/1.38 ns/B against 0.94 at 32)? Counters per
# placement, base and fix, solo lent 64 B on CPU 3 (pinned, one process),
# then where the misaligned loads and stli conflicts are (perf record, by
# symbol and address). Diagnostic, not a speed verdict.
set -u
r=/root/results/smalloc/line-offset-mechanism
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
ev=cycles,instructions,ls_misal_loads.ma64,ls_misal_loads.ma4k,ls_stlf,ls_bad_status2.stli_other,ls_dispatch.ld_dispatch,ls_dispatch.store_dispatch
for side in base fix; do
  for off in 16 32 48; do
    if [ "$side" = base ]; then exe=/root/results/smalloc/line-offset/line$off-base; else exe=/root/results/smalloc/line-offset-fix/line$off-fix; fi
    out="$r/$side-$off"; mkdir -p "$out"; cd "$out"
    taskset -c 3 perf stat -x, -o "$out/stat.csv" -e "$ev" -- "$exe" --contenders blake3-servil-st --points 'lent 64 B' --for-regression-check --rounds 24 > "$out/run.out" 2> "$out/run.err"
    taskset -c 3 perf record -q -e ls_misal_loads.ma64/period=1009/u -e ls_bad_status2.stli_other/period=1009/u -o "$out/perf.data" -- "$exe" --contenders blake3-servil-st --points 'lent 64 B' --for-regression-check --rounds 24 > /dev/null 2>&1
    perf report --stdio -i "$out/perf.data" --no-children -n --sort sym,srcline --percent-limit 2 > "$out/report.txt" 2> /dev/null
    perf annotate --stdio -i "$out/perf.data" -s blake3_sse41_chunk_root > "$out/annotate-fix.txt" 2> /dev/null
  done
done
printf 'done\n' > "$r/complete"
