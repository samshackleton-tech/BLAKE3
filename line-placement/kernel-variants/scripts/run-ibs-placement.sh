#!/bin/bash
# IBS ops (system-wide, 1 in ~20k cycles) while one pinned bench process
# hashes solo lent 64 B: the chunk-root fix with buffers 16 and 32 bytes into
# a line, and the base at 16. Decoded with perf report -D, joined to symbols.
set -u
r=/root/results/smalloc/ibs-placement
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
for spec in fix16:/root/results/smalloc/line-offset-fix/line16-fix fix32:/root/results/smalloc/line-offset-fix/line32-fix base16:/root/results/smalloc/line-offset/line16-base; do
    name=${spec%%:*}; exe=${spec#*:}; out="$r/$name"; mkdir -p "$out"; cd "$out"
    cp "$exe" "$out/ibsrun"
    perf record -q -a -e ibs_op// -c 2003 --raw-samples -o "$out/ibs.data" -- taskset -c 3 "$out/ibsrun" --contenders blake3-servil-st --points 'lent 64 B' --for-regression-check --rounds 192 > "$out/run.out" 2> "$out/run.err"
    perf report -D -i "$out/ibs.data" > "$out/dump.txt" 2> /dev/null
    perf script -i "$out/ibs.data" --ns -F comm,tid,time,ip,sym,symoff > "$out/script.txt" 2> /dev/null
    python3 /root/ibs-join.py "$out/dump.txt" "$out/script.txt" ibsrun > "$out/all.txt"
    python3 /root/ibs-join.py "$out/dump.txt" "$out/script.txt" ibsrun chunk_root compress hash_serial hash_in_memory memcpy > "$out/hot.txt"
    python3 /root/ibs-join.py "$out/dump.txt" "$out/script.txt" ibsrun --mem > "$out/mem.txt"
    rm -f "$out/dump.txt"
done
printf 'done\n' > "$r/complete"
