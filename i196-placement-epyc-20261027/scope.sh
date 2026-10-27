#!/bin/bash
# BLAKE3 #196 step 3: the stream, lent and batch cells under one L3 domain
# (A, 12 CPUs) and all 48 CPUs (C); 3 processes each, interleaved; mt only.
set -eu
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O"
(cd "$R/b018" && cargo build --release 2> "$O/build.log" && \
 CARGO_TARGET_DIR="$R/t" ./target/release/bench-hashes build-against ../src 2>> "$O/build.log" | tail -1 > "$O/exe.txt")
X=$(cat "$O/exe.txt"); [ -x "$X" ]
P="continuous 64 B,continuous 128 B,continuous 256 B,continuous 512 B,continuous 1 KiB,continuous 4 KiB,continuous 16 KiB,continuous 64 KiB,continuous 1 MiB"
P="$P,continuous batch 16,continuous batch 256,continuous batch 1024,continuous batch 16384"
declare -A CPUS=([A]="0-5,24-29" [C]="0-47")
for i in 1 2 3; do for p in A C; do
  d="$O/runs/$p-$i"; mkdir -p "$d"; cd "$d"
  taskset -c "${CPUS[$p]}" "$X" --contenders blake3-servil-mt --points "$P" --rounds 24 > out.txt 2> err.txt
  cp benchmark-results/*/bench-hashes.result.txt result.txt
done; done
cp "$O/runs/A-1/result.txt" "$O/result-A.txt"
