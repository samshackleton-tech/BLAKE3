#!/bin/bash
r=/root/results/many-bistable/oddeven2; rm -rf $r; mkdir -p $r
exe=/root/results/many-bistable/duo-order/bench-asis
for c in 0 1 2 3; do
  o=$r/cpu$c; mkdir -p $o
  ( cd $o && taskset -c $c setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root $exe --contenders blake3-servil-st,sha256,blake3-official --points '64,256,lent 64 B,64 KiB' --for-regression-check --rounds 24 > run.out 2> run.err )
done
