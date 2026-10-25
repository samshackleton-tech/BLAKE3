#!/bin/bash
# EPYC release run for 0.8 (#125, #119), after #168's run has finished.
#   candidate: devonjonte/BLAKE3 candidate/devon-release-0.8 ee4c0d7 (incl. DIRECT_WAKES = 8)
#   baseline:  candidate/devon-kernel-names-john bfbda19 (servil + #164: both sides run servil's kernels)
#   bench:     new side d21cdf36 (devonjonte, the two-kinds API, as Devon's i7 run),
#              old side --old-bench 5be5f236 (inputs in blocks, the old API).
# Order: suites first (no timing running), then the same-code control
# (check --against HEAD --cells all, once), then the release check.
set -u
NEW=ee4c0d7c27
OLD=bfbda1920283335ff3802723db11c209159f47fc
BENCH=d21cdf36dfc02716e173be4e5b4590c04361084a
OLD_BENCH=5be5f23699ee7146ada56a08777173a4ee1c7bde
LIB=/root/BLAKE3-release-08
out=/root/results/release-08-epyc-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }

exec 9>/root/bench-native-afk.lock
flock -n 9 || { echo "bench lock busy"; exit 75; }

step setup
if [ ! -d "$LIB" ]; then
  git -C /root/BLAKE3-round-pr164 fetch -q https://github.com/devonjonte/BLAKE3 candidate/devon-release-0.8 || exit 10
  git -C /root/BLAKE3-round-pr164 worktree add --detach "$LIB" "$NEW" || exit 11
  git clone -q /root/BLAKE3-round-pr164/bench-hashes "$LIB/bench-hashes" || exit 12
  git -C "$LIB/bench-hashes" fetch -q https://github.com/devonjonte/bench-hashes "$BENCH" || exit 13
  git -C "$LIB/bench-hashes" checkout -q --detach "$BENCH" || exit 13
fi
[ "$(git -C "$LIB" rev-parse HEAD)" = "$(git -C "$LIB" rev-parse "$NEW^{commit}")" ] || exit 14
[ "$(git -C "$LIB/bench-hashes" rev-parse HEAD)" = "$BENCH" ] || exit 15
git -C "$LIB" cat-file -e "$OLD^{commit}" || exit 16
git -C "$LIB/bench-hashes" cat-file -e "$OLD_BENCH^{commit}" || exit 17
{
  date -u; uptime; nproc; lscpu | grep -E 'Model name|Flags' | cut -c1-200
  echo "candidate: $(git -C "$LIB" rev-parse HEAD)"; git -C "$LIB" log -1 --format=%s
  git -C "$LIB" status --short
  echo "baseline:  $OLD"
  echo "bench:     $(git -C "$LIB/bench-hashes" rev-parse HEAD)"; git -C "$LIB/bench-hashes" status --short
  grep -n 'DIRECT_WAKES' "$LIB"/src/*.rs | head
  rustc -Vv; cargo -V
} > "$out/provenance.txt" 2>&1

step suites
cd "$LIB"
suites=0
T=/root/target-release-08
(CARGO_TARGET_DIR=$T-default cargo nextest run --release > "$out/test-default.log" 2>&1) & p1=$!
(CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > "$out/test-pure.log" 2>&1) & p2=$!
(CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > "$out/test-no_std.log" 2>&1) & p3=$!
(CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$out/test-capi.log" 2>&1) & p4=$!
(CARGO_TARGET_DIR=$T-doc cargo test --doc > "$out/test-doc.log" 2>&1) & p5=$!
for p in $p1 $p2 $p3 $p4 $p5; do wait $p || suites=1; done
CARGO_TARGET_DIR=$T-builds bash tools/check-builds.sh > "$out/check-builds.log" 2>&1 || suites=1
grep -hE 'Summary|test result:' "$out"/test-*.log > "$out/test-summary.txt"
echo "suites status $suites"
if [ "$suites" != 0 ]; then echo "suites failed: no timing run"; exit 20; fi

sleep 60  # let the machine settle after the builds
cd "$LIB/bench-hashes"
step same-code control
cargo run --release -- check --against HEAD --cells all --keep "$out/aa-samples" \
  > "$out/aa-check.out" 2> "$out/aa-check.err"
echo "aa check exit $?"; uptime

step release check
cargo run --release -- check --against "$OLD" --old-bench "$OLD_BENCH" --cells all --pairs 12 \
  --keep "$out/release-samples" > "$out/release-check.out" 2> "$out/release-check.err"
status=$?
echo "release check exit $status"; date -u; uptime
exit $status
