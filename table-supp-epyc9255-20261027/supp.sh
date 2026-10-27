#!/bin/bash
# The CHANGELOG table's rows with official's multithreaded contender (BLAKE3 #125):
# bench 0.18 (67bae864) built with build-against against 934dee89, 96 rounds.
set -eu
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O"
(cd "$R/b018" && cargo build --release 2> "$O/build.log" && \
 CARGO_TARGET_DIR="$R/t" ./target/release/bench-hashes build-against ../src 2>> "$O/build.log" | tail -1 > "$O/exe.txt")
X=$(cat "$O/exe.txt"); [ -x "$X" ]
cd "$O"
"$X" --contenders blake3-official,blake3-official-mt,blake3-servil-st,blake3-servil-mt \
  --points "64 B,1 KiB,1 MiB,128 MiB,1024,continuous 64 KiB" --rounds 96 > run.out 2> run.err
d=$(ls -d benchmark-results/*); cp $d/bench-hashes.result.txt $d/bench-hashes.samples.tsv .
