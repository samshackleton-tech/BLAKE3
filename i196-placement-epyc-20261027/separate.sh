#!/bin/bash
# BLAKE3 #196 step 5: CPU count or L3 spread? Four placements, 3 processes each,
# interleaved: A one L3 domain (12 CPUs), B two domains (6+6 CPUs), D two whole
# domains (24), C all four (48). The pool's thread count sampled in each process.
set -eu
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O"
(cd "$R/b018" && cargo build --release 2> "$O/build.log" && \
 CARGO_TARGET_DIR="$R/t" ./target/release/bench-hashes build-against ../src 2>> "$O/build.log" | tail -1 > "$O/exe.txt")
X=$(cat "$O/exe.txt"); [ -x "$X" ]
P="continuous 256 B,continuous 16 KiB,continuous 1 MiB,continuous batch 1024,1 MiB,8 MiB,128 MiB,16384,lent 1 MiB"
declare -A CPUS=([A]="0-5,24-29" [B]="0-2,24-26,6-8,30-32" [D]="0-11,24-35" [C]="0-47")
for i in 1 2 3; do for p in A B D C; do
  d="$O/runs/$p-$i"; mkdir -p "$d"; cd "$d"
  taskset -c "${CPUS[$p]}" "$X" --contenders blake3-servil-mt --points "$P" --rounds 24 > out.txt 2> err.txt &
  pid=$!; m=0; while kill -0 $pid 2>/dev/null; do n=$(ls /proc/$pid/task 2>/dev/null | wc -l); [ "$n" -gt "$m" ] && m=$n; sleep 0.5; done
  wait $pid; echo "$m" > threads.txt
  cp benchmark-results/*/bench-hashes.result.txt result.txt
done; done
cp "$O/runs/A-1/result.txt" "$O/result-A.txt"
