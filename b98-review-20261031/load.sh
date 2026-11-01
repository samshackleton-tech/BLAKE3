#!/bin/bash
# bench-hashes #98, item 4: does 0.19's load (other programs' user time) see other programs'
# system time? A short run of bench 0.19 (99eefde3, built against the fork at 0.8) under:
# quiet; 4 user spinners; 4 readers of /dev/urandom (system time); 4 page-fault loops (system time).
# Each background process's own CPU time (/proc/PID/stat utime, stime) is recorded beside the run's load line.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"; cd "$R"
. /root/.cargo/env
cd bench; cargo build --release > "$O/bench-build.log" 2>&1 || exit 2
EXE=$(./target/release/bench-hashes build-against ../fork 2> "$O/build-against.err" | tail -1)
spin() { python3 -c 'while True: pass'; }
urandom() { exec dd if=/dev/urandom of=/dev/null bs=1M status=none; }
faults() { python3 -c '
import mmap
while True:
    m = mmap.mmap(-1, 256 << 20)
    for i in range(0, 256 << 20, 4096): m[i] = 1
    m.close()'; }
for cond in quiet spin urandom faults; do
  pids=()
  if [ $cond != quiet ]; then for i in 1 2 3 4; do ( $cond ) & pids+=($!); done; sleep 3; fi
  ticks() { for p in "${pids[@]}"; do for c in $(pgrep -P $p) $p; do awk '{print $14, $15}' /proc/$c/stat 2>/dev/null; done; done | awk '{u+=$1; s+=$2} END {print u+0, s+0}'; }
  t0=$(date +%s.%N); b=$(ticks)
  d="$O/$cond"; mkdir -p "$d"; (cd "$d" && "$EXE" --contenders sha256,blake3-servil-st --points "64 KiB,1 MiB,continuous 64 KiB" --rounds 24 --expect-servil b5b988d8982bea9490c38c79ec4b8c5c2428270c > report.txt 2> err.txt)
  t1=$(date +%s.%N); a=$(ticks)
  python3 - "$b" "$a" "$t0" "$t1" "$(getconf CLK_TCK)" > "$d/background.txt" <<'PY'
import sys
(ub,sb),(ua,sa)=[map(int,x.split()) for x in sys.argv[1:3]]; t=float(sys.argv[4])-float(sys.argv[3]); hz=int(sys.argv[5])
print(f"background CPUs over the run: user {(ua-ub)/hz/t:.2f}, system {(sa-sb)/hz/t:.2f}")
PY
  for p in "${pids[@]}"; do pkill -P $p 2>/dev/null; kill $p 2>/dev/null; done; wait 2>/dev/null; sleep 2
  grep -h "load during the run" "$d"/benchmark-results/*/bench-hashes.result.txt > "$d/load.txt"
  echo "$cond: $(cat $d/background.txt) | $(cut -c1-140 $d/load.txt)" >> "$O/summary.txt"
done
