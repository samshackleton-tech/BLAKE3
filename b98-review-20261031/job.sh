#!/bin/bash
# bench-hashes #98 review runs on this machine: bench 0.19 candidate (99eefde3), the fork at 0.8.
#  1. A/A: check --fork fork --against b5b988d8 --cells all (timed)
#  2. plant/spin0 and plant/hash6, default cell choice, against b5b988d8
#  3. the calibration cache: two --quick runs; the second's sizes from the cache
#  4. load: the b3sum run, its load line
set -u
R="$1"; O="$R/out"; mkdir -p "$O"; cd "$R"
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
E=b5b988d8982bea9490c38c79ec4b8c5c2428270c
for f in fork fork-spin0 fork-hash6; do git -C $f cat-file -e $E || git -C $f fetch -q https://github.com/johnservil/BLAKE3 servil; done
{ grep -m1 'model name' /proc/cpuinfo; nproc; sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; rustc -V; for f in bench fork fork-spin0 fork-hash6; do echo "$f $(git -C $f log -1 --format='%H %s' | cut -c1-120)"; done; } > "$O/provenance.txt"
cd bench; cargo build --release > "$O/bench-build.log" 2>&1 || exit 2
X=./target/release/bench-hashes
rm -rf "$HOME/.cache/bench-hashes"
step() { n=$1; shift; s=$(date +%s); "$@" > "$O/$n.out" 2> "$O/$n.err"; echo "$n exit $? $(( $(date +%s) - s )) s" >> "$O/status.txt"; git checkout -q -- index.html 2>/dev/null; }
step aa $X check --fork ../fork --against $E --cells all --keep "$O/aa-samples"
step spin0 $X check --fork ../fork-spin0 --against $E --keep "$O/spin0-samples"
step hash6 $X check --fork ../fork-hash6 --against $E --keep "$O/hash6-samples"
EXE=$($X build-against ../fork 2> "$O/build-against.err" | tail -1); echo "exe $EXE" >> "$O/status.txt"
rm -rf "$HOME/.cache/bench-hashes"
for i in 1 2; do mkdir -p "$O/quick-$i"; (cd "$O/quick-$i" && "$EXE" --quick --expect-servil $E > report.txt 2> err.txt; echo "quick $i exit $?" >> "$O/status.txt"); done
ls -la "$HOME/.cache/bench-hashes" > "$O/cache-listing.txt" 2>&1
python3 tools/b3sum-contenders.py ../fork /root/b3c > "$O/b3sum-contenders.txt" 2> "$O/b3sum-build.log" || echo "b3sum build failed" >> "$O/status.txt"
mkdir -p "$O/b3sum"; (cd "$O/b3sum" && tr '\n' '\0' < "$O/b3sum-contenders.txt" | xargs -0 "$R/bench/$X" b3sum --files /root/b3sum-files > report.txt 2> err.txt; echo "b3sum exit $?" >> "$O/status.txt")
git checkout -q -- index.html 2>/dev/null
echo done >> "$O/status.txt"
