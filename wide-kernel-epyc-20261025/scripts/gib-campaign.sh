#!/bin/bash
# Warm/cold 1 GiB-scale cells, every thread: old (07540667), new (8c34ead4),
# and new with --num-threads 24 (no SMT doubling, unpinned). 3 runs.
set -u
out=/root/results/gib-8c34; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
exec 9>/root/bench-native-afk.lock; flock -w 600 9 || exit 75
cd /root/BLAKE3-rc-8c34/bench-hashes
CLI=/root/results/wide-cli-bin
for r in 1 2 3; do
  args=(); for i in 0 1 2 3; do args+=("old=$CLI/b3sum-0754066-L$i"); done
  for i in 0 1 2 3; do args+=("new=$CLI/b3sum-8c34ead-L$i"); done
  for i in 0 1 2 3; do args+=("new-24t=$CLI/b3sum-8c34ead-L$i --num-threads 24"); done
  cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/r$r.out 2> $out/r$r.err
  echo "r$r exit $?"
  mkdir -p $out/r$r; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/r$r/
  git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
done
date -u
