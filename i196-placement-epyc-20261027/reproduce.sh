#!/bin/bash
# BLAKE3 #196 step 1: mt ContinuousMessages 256 B under bench 0.18 (67bae864)
# and bench 3f9edd13, both built against the fork at 934dee89; 10 fresh
# processes each, alternating, each measuring that one cell (24 rounds) under
# perf stat (user cycles and instructions), its report kept.
set -eu
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O"
for b in b018 b3f9; do
  (cd "$R/$b" && cargo build --release 2> "$O/$b-build.log" && \
   CARGO_TARGET_DIR="$R/t-$b" ./target/release/bench-hashes build-against ../src 2>> "$O/$b-build.log" | tail -1 > "$O/$b-exe.txt")
  [ -x "$(cat "$O/$b-exe.txt")" ]
done
for i in $(seq 1 10); do
  for b in b018 b3f9; do
    d="$O/runs/$b-$i"; mkdir -p "$d"; cd "$d"
    perf stat -x, -e cycles:u,instructions:u -o perf.csv -- "$(cat "$O/$b-exe.txt")" \
      --contenders blake3-servil-mt --points "continuous 256 B" --rounds 24 > out.txt 2> err.txt
    cp benchmark-results/*/bench-hashes.result.txt result.txt
  done
done
for b in b018 b3f9; do cp "$O/runs/$b-1/result.txt" "$O/$b-result.txt"; done
