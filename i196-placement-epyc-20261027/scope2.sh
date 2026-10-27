#!/bin/bash
# BLAKE3 #196 step 4: the pool's other mt cells (one-shot, batches, lent, after a pause) under one L3 domain
# (A, 12 CPUs) and all 48 CPUs (C); 3 processes each, interleaved; mt only.
set -eu
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O"
(cd "$R/b018" && cargo build --release 2> "$O/build.log" && \
 CARGO_TARGET_DIR="$R/t" ./target/release/bench-hashes build-against ../src 2>> "$O/build.log" | tail -1 > "$O/exe.txt")
X=$(cat "$O/exe.txt"); [ -x "$X" ]
P="1 MiB,8 MiB,32 MiB,128 MiB,1024,16384,262144,lent 64 KiB,lent 1 MiB,lent 16 MiB,idle 1 MiB,idle 16384,lent batch 1024,lent batch 65536"
declare -A CPUS=([A]="0-5,24-29" [C]="0-47")
for i in 1 2 3; do for p in A C; do
  d="$O/runs/$p-$i"; mkdir -p "$d"; cd "$d"
  taskset -c "${CPUS[$p]}" "$X" --contenders blake3-servil-mt --points "$P" --rounds 24 > out.txt 2> err.txt
  cp benchmark-results/*/bench-hashes.result.txt result.txt
done; done
cp "$O/runs/A-1/result.txt" "$O/result-A.txt"
