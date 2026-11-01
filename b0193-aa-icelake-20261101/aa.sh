#!/bin/bash
# bench-hashes 0.19.3 (a48ee6c7): the A/A check, the fork at 0.8 against itself, every cell.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"; cd "$R"
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
E=b5b988d8982bea9490c38c79ec4b8c5c2428270c
{ grep -m1 'model name' /proc/cpuinfo; nproc; sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; git -C bench log -1 --format='%H %s' | cut -c1-100; git -C fork log -1 --format=%H; } > "$O/machine.txt"
cd bench; cargo build --release > "$O/bench-build.log" 2>&1 || exit 2
s=$(date +%s)
./target/release/bench-hashes check --fork ../fork --against $E --cells all > "$O/aa.out" 2> "$O/aa.err"; echo "aa exit $? $(( $(date +%s) - s )) s" >> "$O/status.txt"
grep -E " again: |busy" "$O/aa.err" > "$O/busy-lines.txt"
git checkout -q -- index.html 2>/dev/null
