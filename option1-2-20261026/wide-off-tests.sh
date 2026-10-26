#!/bin/bash
# Tests of option 1a (candidate/sam-wide-off) and 1b (candidate/sam-wide-off-nobudget)
# on the EPYC 9255 (AVX-512: the WIDE-gated paths live). Suites, Shuttle,
# check-builds, rustfmt as CI runs it, the cross-check, the budget under Miri.
set -u
export HOME=/root
out=/root/results/wide-off-tests; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
R=/root/BLAKE3-round-pr164
for b in sam-wide-off sam-wide-off-nobudget; do git -C $R fetch -q /root/$b.bundle candidate/$b:refs/heads/candidate/$b || exit 10; done
exec 9>/root/bench-native-afk.lock; flock -w 3600 9 || exit 75
all=0
for b in sam-wide-off sam-wide-off-nobudget; do
  D=/root/BLAKE3-$b; [ -d $D ] || git -C $R worktree add -q --detach $D candidate/$b || exit 11
  o=$out/$b; mkdir -p $o; cd $D; T=/root/target-$b; st=0
  git log -2 --oneline > $o/commit.txt
  (CARGO_TARGET_DIR=$T cargo nextest run --release > $o/default.log 2>&1) & p1=$!
  (CARGO_TARGET_DIR=$T-debug cargo nextest run > $o/debug.log 2>&1) & p2=$!
  (CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $o/pure.log 2>&1) & p3=$!
  (CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > $o/no_std.log 2>&1) & p4=$!
  (CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $o/capi.log 2>&1) & p5=$!
  (CARGO_TARGET_DIR=$T-doc cargo test --doc > $o/doc.log 2>&1) & p6=$!
  (CARGO_TARGET_DIR=$T-b3sum cargo nextest run --release --manifest-path b3sum/Cargo.toml > $o/b3sum.log 2>&1) & p7=$!
  for p in $p1 $p2 $p3 $p4 $p5 $p6 $p7; do wait $p || st=1; done
  RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > $o/shuttle.log 2>&1 || st=1
  CARGO_TARGET_DIR=$T-builds bash tools/check-builds.sh > $o/check-builds.log 2>&1 || st=1
  (for d in $(git ls-files '*Cargo.toml' | xargs -n1 dirname); do (cd "$d" && cargo fmt --all -- --check) || exit 1; done) > $o/rustfmt.log 2>&1 || st=1
  python3 tools/verify/cross_check_x86.py > $o/cross-check.log 2>&1 || st=1
  CARGO_TARGET_DIR=$T-miri timeout 2400 cargo +nightly-2026-10-24 miri test --lib tree_thread_budget > $o/miri.log 2>&1 || st=1
  grep -hE 'Summary|test result:|all agree|every build passes' $o/*.log > $o/summary.txt
  echo "$b status $st"; [ $st = 0 ] || all=1
done
echo "all status $all"
