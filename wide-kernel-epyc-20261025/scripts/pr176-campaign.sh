#!/bin/bash
# PR #176 (Devon: the pool wakes through Park::wake_one alone), at 6af0e74,
# judged against its parent on the EPYC, as asked: check --pairs 8 (--cells
# all), plus the suites and Shuttle first. Measurement only.
set -u
out=/root/results/pr176-20261026
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
R=/root/BLAKE3-round-pr164; D=/root/BLAKE3-pr176
step setup
git -C $R fetch -q https://github.com/devonjonte/BLAKE3 candidate/devon-wake-one:refs/heads/review/pr176 || exit 10
[ -d $D ] || git -C $R worktree add -q --detach $D review/pr176 || exit 11
NEW=$(git -C $D rev-parse HEAD); PARENT=$(git -C $D rev-parse HEAD^)
{ date -u; echo "new $NEW"; git -C $D log -1 --format=%s; echo "parent $PARENT"; git -C $D log -1 --format=%s HEAD^; git -C $D diff --stat HEAD^ HEAD; } > $out/provenance.txt 2>&1
step tests
cd $D; T=/root/target-pr176; st=0
(CARGO_TARGET_DIR=$T cargo nextest run --release > $out/test-default.log 2>&1) || st=1
(CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $out/test-pure.log 2>&1) || st=1
RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > $out/test-shuttle.log 2>&1 || st=1
grep -hE 'Summary|test result:' $out/test-*.log
echo "tests status $st"; [ $st = 0 ] || exit 20
[ -d $D/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $D/bench-hashes
git -C $D/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
sleep 30
cd $D/bench-hashes
step check against parent
cargo run --release -- check --against $PARENT --cells all --pairs 8 --keep $out/samples > $out/check.out 2> $out/check.err
echo "check exit $?"
./target/release/bench-hashes compare $out/samples/run-*-old.tsv -- $out/samples/run-*-new.tsv > $out/compare.out 2>&1
step done; date -u
