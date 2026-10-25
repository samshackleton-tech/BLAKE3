#!/bin/bash
# Warm single-thread cells on CPU 0 (the bench's own one-shot cells, 64 KiB
# and 1 MiB) with: nothing else on the core (solo); its SMT sibling (CPU 24)
# kept busy for the whole run by the same kernel hashing a 16 MiB file in a
# loop (siblings); or another core (CPU 1) busy the same way (separate).
# Each measured process under perf stat -M PipelineL1. Measurement only.
set -u
out=/root/results/smt-warm3-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
CANDB=$(ls /root/BLAKE3-release-08/target/check/new/bench-hashes-* | sort -V | head -1)
WIDEB=$(ls /root/BLAKE3-v7-preview/target/check/new/bench-hashes-* | sort -V | head -1)
CAND=/root/target-smt-b3sum/release/b3sum
OFF=/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0
WIDE=/root/results/avx512-registers/cli-layouts16/cli-bin/b3sum-215441f-L0
F=/dev/shm/smt-16m; head -c $((16<<20)) /dev/urandom > $F
loader() { # cpu b3sum: hash $F forever on cpu
  taskset -c $1 bash -c "while :; do $2 --num-threads 1 $F > /dev/null; done" &
  LOADER=$!
}
run() { # dir exe contender
  local d=$out/$1; mkdir -p $d; cd $d
  taskset -c 0 perf stat -M PipelineL1 -o $d/perf.txt $2 --contenders $3 --points "64 KiB,1 MiB" --rounds 96 > $d/stdout.txt 2> $d/stderr.txt
}
for rep in 1 2 3 4 5; do
  for k in candidate:$CANDB:blake3-servil-st:$CAND official:$CANDB:blake3-official:$OFF wide:$WIDEB:blake3-servil-st:$WIDE; do
    IFS=: read n b c l <<< "$k"
    run $n-solo-r$rep $b $c
    loader 24 $l; sleep 0.3; run $n-siblings-r$rep $b $c; kill $LOADER; wait $LOADER 2>/dev/null
    loader 1 $l; sleep 0.3; run $n-separate-r$rep $b $c; kill $LOADER; wait $LOADER 2>/dev/null
  done
done
sleep 1; ps -eo pid,args | grep -c "[s]mt-16m"
rm -f $F
echo done; date -u
