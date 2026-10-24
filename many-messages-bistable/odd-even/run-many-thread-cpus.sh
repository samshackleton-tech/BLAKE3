#!/bin/bash
# bench-hashes #69: where each thread runs, per process, against the state.
# Solo ManyMessages 64 on the as-is diag-align64 build (bench main f4f347c +
# #70), 12 processes under taskset -c 0,1 and 12 unpinned, ASLR off; a 2 ms
# /proc poller records running threads' CPUs. Diagnostic only.
set -u
r=/root/results/many-bistable/thread-cpus
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
exe=/root/results/many-bistable/duo-order/bench-asis
for pin in pair free; do
    for n in $(seq 1 12); do
        if [ "$pin" = pair ]; then pre=(taskset -c 0,1); else pre=(); fi
        printf '%s-%s ' "$pin" "$n" >> "$r/summary.txt"
        python3 /root/thread-cpus.py "$r/$pin-$n" -- "${pre[@]}" setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root "$exe" --contenders blake3-servil-st --points 64 --for-regression-check --rounds 24 >> "$r/summary.txt" 2>> "$r/errors.txt"
    done
done
printf 'done\n' > "$r/complete"
