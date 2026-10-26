#!/bin/bash
# The wide-kernel comparison on the EPYC 9255 (#125), after the suites.
#   old: a9e70b8 = John's candidate/release-0.8 (0754066) + FANOUT 8 (Devon's 485d7ab)
#   new: experiment/sam-wide-on-0.8 = old + the 32-input AVX-512 chunk kernel,
#        its 16-input parent kernel and tree budget (a5e1e18, symbols renamed)
#   bench: d21cdf36 nested in the new side (the 0.8 API on both sides)
# Every timing and statistic is the existing bench-hashes check/regress/
# compare/b3sum; SMT and energy reuse today's perf-based scripts.
set -u
NEWDIR=/root/BLAKE3-wide-new
OLD=$(git -C $NEWDIR rev-parse HEAD^)
NEW=$(git -C $NEWDIR rev-parse HEAD)
BENCH=d21cdf36dfc02716e173be4e5b4590c04361084a
out=/root/results/wide-20261025
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 7200 9 || { echo "lock busy"; exit 75; }
grep -q 'suites status 0' $out/suites/runner.log || { echo "suites did not pass: no timing"; exit 20; }

step setup
[ -d $NEWDIR/bench-hashes ] || git clone -q /root/BLAKE3-release-08/bench-hashes $NEWDIR/bench-hashes || exit 10
git -C $NEWDIR/bench-hashes checkout -q --detach $BENCH || exit 11
{
  date -u; uptime; lscpu | grep 'Model name'; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
  echo "old $OLD"; git -C $NEWDIR log -1 --format='  %s' $OLD
  echo "new $NEW"; git -C $NEWDIR log -1 --format='  %s' $NEW
  git -C $NEWDIR status --short
  echo "bench $(git -C $NEWDIR/bench-hashes rev-parse HEAD)"; git -C $NEWDIR/bench-hashes status --short
  git -C $NEWDIR diff --stat $OLD $NEW
  rustc -V; cargo -V; cc --version | head -1
} > $out/provenance.txt 2>&1
sleep 30

cd $NEWDIR/bench-hashes
step same-code control
cargo run --release -- check --against HEAD --cells all --keep $out/aa-samples > $out/aa.out 2> $out/aa.err
echo "aa exit $?"
for run in 1 2; do
  step library comparison run $run
  cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/lib$run-samples > $out/lib$run.out 2> $out/lib$run.err
  echo "lib$run exit $?"
  ./target/release/bench-hashes compare $out/lib$run-samples/run-*-old.tsv -- $out/lib$run-samples/run-*-new.tsv > $out/lib$run-compare.out 2>&1
  [ -d $out/lib$run-samples/second ] && ./target/release/bench-hashes compare $out/lib$run-samples/second/run-*-old.tsv -- $out/lib$run-samples/second/run-*-new.tsv > $out/lib$run-compare-second.out 2>&1
  mkdir -p $out/lib$run-builds; ls -l $NEWDIR/target/check/old/bench-hashes-* $NEWDIR/target/check/new/bench-hashes-* > $out/lib$run-builds/list.txt 2>&1
done
uptime

step CLI builds
CLI=/root/results/wide-cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py /root/BLAKE3-round-pr164 $CLI $OLD $NEW > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; tail -20 $out/cli-build.log; }
ls -l $CLI > $out/cli-bin.txt
sha256sum $CLI/* > $out/cli-bin.sha256 2>/dev/null
o=${OLD:0:7}; n=${NEW:0:7}
args=(official=$CLI/b3sum-official-1.8.2)
for i in 0 1 2 3; do
  args+=("old=$CLI/b3sum-$o-L$i" "new=$CLI/b3sum-$n-L$i")
done
step CLI multithreaded
cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli-mt.out 2> $out/cli-mt.err
echo "cli-mt exit $?"; mkdir -p $out/cli-mt-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/cli-mt-results/; git status --short benchmark-results > $out/cli-mt-bench-dirty.txt; git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
args=(official-1t="$CLI/b3sum-official-1.8.2 --num-threads 1")
for i in 0 1 2 3; do
  args+=("old-1t=$CLI/b3sum-$o-L$i --num-threads 1" "new-1t=$CLI/b3sum-$n-L$i --num-threads 1")
done
step CLI one thread
cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli-st.out 2> $out/cli-st.err
echo "cli-st exit $?"; mkdir -p $out/cli-st-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/cli-st-results/; git status --short benchmark-results > $out/cli-st-bench-dirty.txt; git checkout -q -- benchmark-results; git clean -q -fd benchmark-results

step done; date -u; uptime
