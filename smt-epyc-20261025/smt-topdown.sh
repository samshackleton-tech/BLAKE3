#!/bin/bash
# Where the dispatch slots go (Zen 5 PipelineL1/L2), one b3sum thread
# hashing 1 GiB, alone on core 0 or beside its SMT sibling (CPU 24) doing
# the same. Measurement only, existing binaries.
set -u
out=/root/results/smt-topdown-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
CAND=/root/target-smt-b3sum/release/b3sum
WIDE=/root/results/avx512-registers/cli-layouts16/cli-bin/b3sum-215441f-L0
OFF=/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0
F=/dev/shm/smt-td-1g
head -c $((1<<30)) /dev/urandom > $F; sleep 20
for rep in 1 2 3; do
  for k in candidate:$CAND wide:$WIDE official:$OFF; do
    n=${k%%:*}; b=${k#*:}
    for m in PipelineL1 PipelineL2; do
      taskset -c 0 perf stat -M $m -o $out/$n-solo-$m-r$rep.txt $b --num-threads 1 $F > /dev/null
      taskset -c 0 perf stat -M $m -o $out/$n-siblings-$m-r$rep.txt $b --num-threads 1 $F > /dev/null &
      taskset -c 24 $b --num-threads 1 $F > /dev/null &
      wait
    done
  done
done
rm -f $F
echo done; date -u
