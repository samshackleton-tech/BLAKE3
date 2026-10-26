#!/bin/bash
# Suites for both sides of the wide-kernel comparison, on the EPYC (AVX-512).
#   old: /root/BLAKE3-wide-old (a9e70b8: candidate/release-0.8 0754066 + FANOUT 8)
#   new: /root/BLAKE3-wide-new (the same + the 32-input AVX-512 kernel)
set -u
out=/root/results/wide-20261025/suites
mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
status=0
for side in old new; do
  d=/root/BLAKE3-wide-$side; T=/root/target-wide-$side; o=$out/$side; mkdir -p $o
  git -C $d log -1 --format='%H %s' > $o/commit.txt; git -C $d status --short >> $o/commit.txt
  cd $d
  (CARGO_TARGET_DIR=$T cargo nextest run --release > $o/default.log 2>&1) & p1=$!
  (CARGO_TARGET_DIR=$T-debug cargo nextest run > $o/debug.log 2>&1) & p2=$!
  (CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $o/pure.log 2>&1) & p3=$!
  (CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > $o/no_std.log 2>&1) & p4=$!
  (CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $o/capi.log 2>&1) & p5=$!
  (CARGO_TARGET_DIR=$T-doc cargo test --doc > $o/doc.log 2>&1) & p6=$!
  (python3 -m unittest discover -s tools/verify -p 'test_*.py' > $o/verify-helpers.log 2>&1) & p7=$!
  for p in $p1 $p2 $p3 $p4 $p5 $p6 $p7; do wait $p || status=1; done
  RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > $o/shuttle.log 2>&1 || status=1
  CARGO_TARGET_DIR=$T-builds bash tools/check-builds.sh > $o/check-builds.log 2>&1 || status=1
  (CARGO_TARGET_DIR=$T-b3sum cargo nextest run --release --manifest-path b3sum/Cargo.toml > $o/b3sum.log 2>&1) || status=1
  grep -hE 'Summary|test result:|^Ran |^OK|FAILED' $o/*.log > $o/summary.txt
  echo "$side done status so far $status"
done
echo "suites status $status"
