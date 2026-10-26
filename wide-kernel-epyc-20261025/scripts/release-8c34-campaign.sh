#!/bin/bash
# The EPYC's release check at candidate/release-0.8 8c34ead4 against 07540667,
# the Mac's comparison (job 1682), with bench d21cdf36: suites first, then
# check --cells all --pairs 12, then the CLI (b3sum, 16 rounds, 4 layouts each).
set -u
out=/root/results/release-8c34ead4
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
R=/root/BLAKE3-round-pr164; D=/root/BLAKE3-rc-8c34
step setup
git -C $R fetch -q https://github.com/johnservil/BLAKE3 candidate/release-0.8 || exit 10
NEW=$(git -C $R rev-parse 8c34ead4^{commit}) || exit 10
OLD=$(git -C $R rev-parse 07540667^{commit}) || exit 10
[ -d $D ] || git -C $R worktree add -q --detach $D $NEW || exit 11
{ date -u; echo "new $NEW"; git -C $D log -1 --format=%s; echo "old $OLD"; git -C $R log -1 --format=%s $OLD; git -C $D status --short; git -C $R diff --stat $OLD $NEW | tail -1; rustc -V; } > $out/provenance.txt 2>&1
step suites
cd $D; T=/root/target-rc-8c34; st=0; o=$out/suites; mkdir -p $o
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
python3 tools/verify/cross_check_x86.py > $o/cross-check-x86.log 2>&1 || st=1
grep -hE 'Summary|test result:|all agree' $o/*.log > $o/summary.txt
echo "suites status $st"; [ $st = 0 ] || exit 20
[ -d $D/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $D/bench-hashes
git -C $D/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
sleep 60
cd $D/bench-hashes
step release check
cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/samples > $out/check.out 2> $out/check.err
echo "check exit $?"
./target/release/bench-hashes compare $out/samples/run-*-old.tsv -- $out/samples/run-*-new.tsv > $out/compare.out 2>&1
[ -d $out/samples/second ] && ./target/release/bench-hashes compare $out/samples/second/run-*-old.tsv -- $out/samples/second/run-*-new.tsv > $out/compare-second.out 2>&1
step CLI
CLI=/root/results/wide-cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py $R $CLI $OLD $NEW > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; exit 30; }
o=${OLD:0:7}; n=${NEW:0:7}
sleep 10
for mode in mt st; do
  args=()
  for i in 0 1 2 3; do if [ $mode = mt ]; then args+=("old=$CLI/b3sum-$o-L$i"); else args+=("old-1t=$CLI/b3sum-$o-L$i --num-threads 1"); fi; done
  for i in 0 1 2 3; do if [ $mode = mt ]; then args+=("new=$CLI/b3sum-$n-L$i"); else args+=("new-1t=$CLI/b3sum-$n-L$i --num-threads 1"); fi; done
  cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli-$mode.out 2> $out/cli-$mode.err
  echo "cli-$mode exit $?"
  mkdir -p $out/cli-$mode-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/cli-$mode-results/
  git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
done
step done; date -u
