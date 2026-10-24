#!/bin/bash
# bench-hashes #69: solo ManyMessages 64 pinned to odd and even CPUs, 2 runs each.
r=/root/results/many-bistable/oddeven; rm -rf $r; mkdir -p $r
exe=/root/results/many-bistable/duo-order/bench-asis
for c in 0 1 2 3 12 13 20 21 24 25; do for n in 1 2; do
  o=$r/cpu$c-$n; mkdir -p $o
  ( cd $o && taskset -c $c setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root $exe --contenders blake3-servil-st --points 64 --for-regression-check --rounds 24 > run.out 2> run.err )
done; done
python3 /root/many-sum.py $r > $r/summary.txt
