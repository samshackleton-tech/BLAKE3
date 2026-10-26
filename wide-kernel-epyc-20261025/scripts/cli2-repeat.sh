#!/bin/bash
# The CLI judged new against old directly (bench-hashes b3sum judges every
# contender against the first): old's 4 layouts first, then new's 4, default
# threads and --num-threads 1. Same binaries as campaign.sh. After followup.sh.
set -u
out=/root/results/wide-20261025
R=${1:?repeat number}
exec > $out/cli2-r$R.log 2>&1
. /root/.cargo/env
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 14400 9 || { echo "lock busy"; exit 75; }
cd /root/BLAKE3-wide-new/bench-hashes
CLI=/root/results/wide-cli-bin
o=a9e70b8; n=$(git -C /root/BLAKE3-wide-new rev-parse --short=7 HEAD)
sleep 20
for mode in mt st; do
  args=()
  for i in 0 1 2 3; do
    if [ $mode = mt ]; then args+=("old=$CLI/b3sum-$o-L$i"); else args+=("old-1t=$CLI/b3sum-$o-L$i --num-threads 1"); fi
  done
  for i in 0 1 2 3; do
    if [ $mode = mt ]; then args+=("new=$CLI/b3sum-$n-L$i"); else args+=("new-1t=$CLI/b3sum-$n-L$i --num-threads 1"); fi
  done
  step CLI $mode, new against old
  cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli2-r$R-$mode.out 2> $out/cli2-r$R-$mode.err
  echo "cli2-r$R-$mode exit $?"
  mkdir -p $out/cli2-r$R-$mode-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/cli2-r$R-$mode-results/
  git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
done
step done
