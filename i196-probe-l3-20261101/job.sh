#!/bin/bash
# BLAKE3 #196: John's probe/l3-domain (dad78920) on the EPYC 9255: full --all runs under
# BLAKE3_PROBE_DOMAIN=none / workers / both, three cycles, the order rotating; then compare.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"; cd "$R"
. /root/.cargo/env
P=dad78920d8aed7b2d464c61d529542fa52f1e843
{ grep -m1 'model name' /proc/cpuinfo; nproc; sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; git -C fork log -1 --format=%H; git -C bench log -1 --format=%H; } > "$O/machine.txt"
cd bench; cargo build --release > "$O/bench-build.log" 2>&1 || exit 2
EXE=$(./target/release/bench-hashes build-against ../fork 2> "$O/build-against.err" | tail -1); [ -x "$EXE" ] || exit 3
for c in 1 2 3; do
  case $c in 1) order="none workers both";; 2) order="workers both none";; 3) order="both none workers";; esac
  for m in $order; do
    d="$O/run-$c-$m"; mkdir -p "$d"
    (cd "$d" && BLAKE3_PROBE_DOMAIN=$m /usr/bin/time -p "$EXE" --all --expect-servil $P > report.txt 2> err.txt; echo "$c $m exit $?" >> "$O/status.txt")
    grep -m1 "probe/l3-domain:" "$d/err.txt" > "$d/probe.txt" || echo "no probe line (mode $m)" > "$d/probe.txt"
    cp "$d"/benchmark-results/*/bench-hashes.samples.tsv "$d"/benchmark-results/*/bench-hashes.result.txt "$d/"; rm -rf "$d/benchmark-results"
  done
done
s() { ls "$O"/run-[123]-$1/bench-hashes.samples.tsv; }
X=./target/release/bench-hashes
$X compare $(s none) -- $(s workers) > "$O/compare-none-workers.txt" 2>&1
$X compare $(s none) -- $(s both) > "$O/compare-none-both.txt" 2>&1
$X compare $(s workers) -- $(s both) > "$O/compare-workers-both.txt" 2>&1
grep -h "probe/l3-domain\|no probe" "$O"/run-*/probe.txt | sort | uniq -c > "$O/probe-lines.txt"
grep -h "load during the run" "$O"/run-*/bench-hashes.result.txt > "$O/load.txt"
