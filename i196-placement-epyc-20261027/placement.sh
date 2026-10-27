#!/bin/bash
# BLAKE3 #196 step 2: is the two-speed cell where the pool's threads land?
# Bench 0.18 built against 934dee89; mt ContinuousMessages 256 B, 24 rounds,
# 8 fresh processes per placement, interleaved: A one L3 domain (12 CPUs),
# B two L3 domains (6 + 6 CPUs), C all 48 CPUs. perf stat beside each.
set -eu
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O"
(cd "$R/b018" && cargo build --release 2> "$O/build.log" && \
 CARGO_TARGET_DIR="$R/t" ./target/release/bench-hashes build-against ../src 2>> "$O/build.log" | tail -1 > "$O/exe.txt")
X=$(cat "$O/exe.txt"); [ -x "$X" ]
declare -A CPUS=([A]="0-5,24-29" [B]="0-2,24-26,6-8,30-32" [C]="0-47")
for i in $(seq 1 8); do
  for p in A B C; do
    d="$O/runs/$p-$i"; mkdir -p "$d"; cd "$d"
    taskset -c "${CPUS[$p]}" perf stat -x, -e cycles:u,instructions:u -o perf.csv -- "$X" \
      --contenders blake3-servil-mt --points "continuous 256 B" --rounds 24 > out.txt 2> err.txt
    cp benchmark-results/*/bench-hashes.result.txt result.txt
  done
done
cp "$O/runs/A-1/result.txt" "$O/result-A.txt"
