#!/bin/bash
# The kernels' SMT behaviour on cache-resident input: the bench's own
# single-thread one-shot cells (64 KiB, 1 MiB, warm), one process alone on
# core 0, beside an identical process on its SMT sibling (CPU 24), or on
# another core (CPU 1). Each process under perf stat -M PipelineL1.
# Measurement only, existing builds. The bench's load line will read the
# deliberate second process as "busy"; that is the point of the test.
set -u
out=/root/results/smt-warm-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
CANDB=$(ls /root/BLAKE3-release-08/target/check/new/bench-hashes-* | sort -V | head -1)
WIDEB=$(ls /root/BLAKE3-v7-preview/target/check/new/bench-hashes-* | sort -V | head -1)
for b in $CANDB $WIDEB; do [ -x $b ] || exit 10; echo "$b $(sha256sum $b | cut -c1-16)"; done > $out/binaries.txt
git -C /root/BLAKE3-release-08 rev-parse HEAD >> $out/binaries.txt
git -C /root/BLAKE3-v7-preview/target/check/new/src rev-parse HEAD >> $out/binaries.txt
run() { # name cpu exe contender
  local d=$out/$1-c$2; mkdir -p $d; cd $d
  taskset -c $2 perf stat -M PipelineL1 -o $d/perf.txt $3 --contenders $4 --points "64 KiB,1 MiB" --rounds 12 > $d/stdout.txt 2> $d/stderr.txt
}
for rep in 1 2; do
  for k in candidate:$CANDB:blake3-servil-st official:$CANDB:blake3-official wide:$WIDEB:blake3-servil-st; do
    IFS=: read n b c <<< "$k"
    run $n-solo-r$rep 0 $b $c
    run $n-siblings-r$rep 0 $b $c & run $n-siblings-r$rep 24 $b $c & wait
    run $n-separate-r$rep 0 $b $c & run $n-separate-r$rep 1 $b $c & wait
  done
done
echo done; date -u
