#!/bin/bash
# #119, Devon's FANOUT design on the EPYC (47 workers), after wakes8-epyc.
#   A: exp/devon-fanout 485d7ab (FANOUT 8)  against  candidate/devon-release-0.8 ee4c0d7 (wakes-8)
#   B: 485d7ab with FANOUT = 64 (every wake direct; a local, measurement-only
#      commit changing only the constant)  against  485d7ab (FANOUT 8)
# bench d21cdf36 nested in each (the release integration's API on both sides).
set -u
FAN=485d7ab538
REL=ee4c0d7c27c4bfd5aa65973468c977dc08c848bb
BENCH=d21cdf36dfc02716e173be4e5b4590c04361084a
R=/root/BLAKE3-round-pr164
A=/root/BLAKE3-fanout8
B=/root/BLAKE3-fanout64
out=/root/results/fanout-epyc-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }

exec 9>/root/bench-native-afk.lock
flock -w 7200 9 || { echo "bench lock busy for two hours"; exit 75; }

step setup
git -C $R fetch -q https://github.com/devonjonte/BLAKE3 exp/devon-fanout || exit 10
FANFULL=$(git -C $R rev-parse "$FAN^{commit}") || exit 11
[ "$(git -C $R rev-parse "$FANFULL^")" = "$REL" ] || { echo "485d7ab is not on ee4c0d7"; exit 12; }
for d in $A $B; do
  if [ ! -d "$d" ]; then
    git -C $R worktree add --detach "$d" "$FANFULL" || exit 13
    git clone -q /root/BLAKE3-release-08/bench-hashes "$d/bench-hashes" || exit 14
    git -C "$d/bench-hashes" checkout -q --detach "$BENCH" || exit 15
  fi
done
# B: the constant alone, committed so the measured tree is a commit.
if grep -q 'pub(crate) const FANOUT: usize = 8;' $B/src/park.rs; then
  replace $B/src/park.rs 'pub(crate) const FANOUT: usize = 8;' 'pub(crate) const FANOUT: usize = 64;' || exit 16
  git -C $B commit -q -am 'Measurement only: FANOUT = 64, every wake direct on 48 threads (#119)' || exit 17
fi
grep -n 'pub(crate) const FANOUT' $A/src/park.rs $B/src/park.rs
B64=$(git -C $B rev-parse HEAD)
[ "$(git -C $B diff --stat "$FANFULL" HEAD -- . | tail -1 | tr -d ' ')" = "1filechanged,1insertion(+),1deletion(-)" ] || { git -C $B diff "$FANFULL" HEAD; exit 18; }
{
  date -u; uptime; lscpu | grep 'Model name'
  echo "A new: $FANFULL (FANOUT 8)  old: $REL (wakes-8)"
  echo "B new: $B64 (FANOUT 64, measurement only)  old: $FANFULL"
  git -C $B diff "$FANFULL" HEAD
  for d in $A $B; do echo "$d bench $(git -C $d/bench-hashes rev-parse HEAD)"; git -C $d status --short; git -C $d/bench-hashes status --short; done
  rustc -V
} > "$out/provenance.txt" 2>&1

step suites at 485d7ab
cd $A
T=/root/target-fanout
suites=0
(CARGO_TARGET_DIR=$T-default cargo nextest run --release > "$out/test-default.log" 2>&1) & p1=$!
(CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > "$out/test-no_std.log" 2>&1) & p2=$!
(CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > "$out/test-pure.log" 2>&1) & p3=$!
(CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$out/test-capi.log" 2>&1) & p4=$!
for p in $p1 $p2 $p3 $p4; do wait $p || suites=1; done
RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > "$out/test-shuttle.log" 2>&1 || suites=1
grep -qE "test result: ok\. [1-9]" "$out/test-shuttle.log" || suites=1
grep -hE 'Summary|test result:' "$out"/test-*.log > "$out/test-summary.txt"
echo "suites status $suites"
if [ "$suites" != 0 ]; then echo "suites failed: no timing run"; exit 20; fi
sleep 60

step A: FANOUT 8 against wakes-8
cd $A/bench-hashes
cargo run --release -- check --against "$REL" --cells all --pairs 12 --keep "$out/A-samples" \
  > "$out/A-check.out" 2> "$out/A-check.err"
echo "A check exit $?"; uptime

step B: FANOUT 64 against FANOUT 8
cd $B/bench-hashes
cargo run --release -- check --against "$FANFULL" --cells all --pairs 12 --keep "$out/B-samples" \
  > "$out/B-check.out" 2> "$out/B-check.err"
status=$?
echo "B check exit $status"; date -u; uptime
exit $status
