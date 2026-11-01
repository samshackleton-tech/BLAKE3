#!/bin/bash
# BLAKE3 #196: do servil mt's streams slow over seconds as the pool's threads spread across
# L3 domains? A 2 s train of mt ContinuousMessages 1 MiB (and batches of 4096), bench 0.19
# (99eefde3) against the fork at 0.8, while every thread's CPU is sampled every 20 ms.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"; cd "$R"
. /root/.cargo/env
cd bench; cargo build --release > "$O/bench-build.log" 2>&1 || exit 2
EXE=$(./target/release/bench-hashes build-against ../fork 2> "$O/build-against.err" | tail -1)
for f in /sys/devices/system/cpu/cpu[0-9]*; do echo "${f##*cpu} $(cat $f/cache/index3/id 2>/dev/null || cat $f/cache/index3/shared_cpu_list)"; done > "$O/l3-map.txt"
for i in 1 2 3; do for pt in "continuous 1 MiB" "continuous batch 4096"; do
  tag="$(echo $pt | tr -cd 'a-zA-Z0-9')-$i"; d="$O/l3-$tag"; mkdir -p "$d"; cd "$d"
  taskset -c 0-5,24-29 "$EXE" --contenders blake3-servil-mt --points "$pt" --rounds 1 --train 0,2000 --nonstop-visits 1 --expect-servil b5b988d8982bea9490c38c79ec4b8c5c2428270c > report.txt 2> err.txt &
  pid=$!; t0=$(date +%s%N)
  while kill -0 $pid 2>/dev/null; do
    now=$(( ($(date +%s%N) - t0) / 1000000 ))
    for t in /proc/$pid/task/*; do s=$(cat $t/stat 2>/dev/null) || continue; echo "$now ${t##*/} $(echo "$s" | awk '{print $3, $39}')"; done
    sleep 0.02
  done > placement.txt
  wait $pid; echo "l3-$tag exit $?" >> "$O/status.txt"; cd "$R/bench"
done; done
for i in 1 2 3; do for pt in "continuous 1 MiB" "continuous batch 4096"; do
  tag="$(echo $pt | tr -cd 'a-zA-Z0-9')-$i"; d="$O/all-$tag"; mkdir -p "$d"; cd "$d"
  "$EXE" --contenders blake3-servil-mt --points "$pt" --rounds 1 --train 0,2000 --nonstop-visits 1 --expect-servil b5b988d8982bea9490c38c79ec4b8c5c2428270c > report.txt 2> err.txt &
  pid=$!; t0=$(date +%s%N)
  while kill -0 $pid 2>/dev/null; do
    now=$(( ($(date +%s%N) - t0) / 1000000 ))
    for t in /proc/$pid/task/*; do s=$(cat $t/stat 2>/dev/null) || continue; echo "$now ${t##*/} $(echo "$s" | awk '{print $3, $39}')"; done
    sleep 0.02
  done > placement.txt
  wait $pid; echo "all-$tag exit $?" >> "$O/status.txt"; cd "$R/bench"
done; done
