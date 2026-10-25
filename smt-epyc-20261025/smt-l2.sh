#!/bin/bash
set -u
out=/root/results/smt-warm-l2-20261025; mkdir -p $out
exec 9>/root/bench-native-afk.lock; flock -w 600 9 || exit 75
CANDB=$(ls /root/BLAKE3-release-08/target/check/new/bench-hashes-* | sort -V | head -1)
WIDEB=$(ls /root/BLAKE3-v7-preview/target/check/new/bench-hashes-* | sort -V | head -1)
for rep in 1 2 3; do for k in candidate:$CANDB wide:$WIDEB; do n=${k%%:*}; b=${k#*:}
  d=$out/$n-solo-r$rep; mkdir -p $d; cd $d
  taskset -c 0 perf stat -M PipelineL2 -o $d/perf.txt $b --contenders blake3-servil-st --points "64 KiB,1 MiB" --rounds 96 > /dev/null 2>&1
done; done; echo done
