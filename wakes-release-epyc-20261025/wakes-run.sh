#!/bin/bash
# #119 on the EPYC: the newer wake design alone, as Devon's i7 run (wakes8-i7).
#   new: devonjonte/BLAKE3 candidate/devon-wakes-8 d795fd0 (cascade + at most 8 direct wakes)
#   old: 338e249, the line's servil: the publisher makes every wake itself
#   bench: f4a8f4eb nested in the new side (as on the i7)
# Then a 16-pair regress over the pool cells: #80's one-shots, Sam's 14 cells
# from October 24, and the i7 cascade's batches, on the check's own
# relinked builds.
set -u
NEW=d795fd088d
OLD=338e249
BENCH=f4a8f4ebc7546ba802b439de01c7c8775f2283f7
LIB=/root/BLAKE3-wakes8
out=/root/results/wakes8-epyc-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }

exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || { echo "bench lock busy for an hour"; exit 75; }

step setup
R=/root/BLAKE3-round-pr164
git -C $R fetch -q https://github.com/devonjonte/BLAKE3 candidate/devon-wakes-8 || exit 10
if [ ! -d "$LIB" ]; then
  git -C $R worktree add --detach "$LIB" "$NEW" || exit 11
  git clone -q $R/bench-hashes "$LIB/bench-hashes" || exit 12
  git -C "$LIB/bench-hashes" checkout -q --detach "$BENCH" || exit 13
fi
NEWFULL=$(git -C "$LIB" rev-parse "$NEW^{commit}"); OLDFULL=$(git -C "$LIB" rev-parse "$OLD^{commit}") || exit 14
[ "$(git -C "$LIB" rev-parse HEAD)" = "$NEWFULL" ] || exit 15
[ "$(git -C "$LIB/bench-hashes" rev-parse HEAD)" = "$BENCH" ] || exit 16
[ "$(git -C "$LIB" rev-parse "$NEWFULL^^")" = "$OLDFULL" ] || exit 17
{
  date -u; uptime; nproc; lscpu | grep 'Model name'
  echo "new:   $NEWFULL"; git -C "$LIB" log -2 --format='  %h %s'
  echo "old:   $OLDFULL"; git -C "$LIB" status --short
  echo "bench: $(git -C "$LIB/bench-hashes" rev-parse HEAD)"; git -C "$LIB/bench-hashes" status --short
  rustc -V; cargo -V
} > "$out/provenance.txt" 2>&1
# Is the release integration's wake code this design? (ee4c0d7 names the 8 DIRECT_WAKES.)
git -C $R diff "$NEWFULL" ee4c0d7c27c4bfd5aa65973468c977dc08c848bb -- src/park.rs > "$out/park-vs-release.diff" 2>&1

step suites
cd "$LIB"
T=/root/target-wakes8
suites=0
(CARGO_TARGET_DIR=$T-default cargo nextest run --release > "$out/test-default.log" 2>&1) & p1=$!
(CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > "$out/test-no_std.log" 2>&1) & p2=$!
(CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > "$out/test-pure.log" 2>&1) & p3=$!
for p in $p1 $p2 $p3; do wait $p || suites=1; done
RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > "$out/test-shuttle.log" 2>&1 || suites=1
# the cfg must have compiled the tests, not nothing
grep -qE "test result: ok\. [1-9]" "$out/test-shuttle.log" || suites=1
grep -hE 'Summary|test result:' "$out"/test-*.log > "$out/test-summary.txt"
echo "suites status $suites"
if [ "$suites" != 0 ]; then echo "suites failed: no timing run"; exit 20; fi

sleep 60
cd "$LIB/bench-hashes"
step check
cargo run --release -- check --against "$OLDFULL" --cells all --pairs 12 --keep "$out/check-samples" \
  > "$out/check.out" 2> "$out/check.err"
echo "check exit $?"; uptime

step pool cells
POINTS="512 KiB,1 MiB,2 MiB,3 MiB,4 MiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,idle 3 MiB,idle 4 MiB,idle 8192,idle 16384,idle 32768,16384,32768,lent batch 16384,lent 1 MiB,lent 4 MiB,outboard 1 MiB,merkle 4096"
mapfile -t olds < <(ls "$LIB"/target/check/old/bench-hashes-* | sort -V | tail -16)
mapfile -t news < <(ls "$LIB"/target/check/new/bench-hashes-* | sort -V | tail -16)
n=$(( ${#olds[@]} < ${#news[@]} ? ${#olds[@]} : ${#news[@]} ))
printf '%s\n' "${olds[@]: -$n}" > "$out/pool-old-builds.txt"; printf '%s\n' "${news[@]: -$n}" > "$out/pool-new-builds.txt"
echo "pool cells: $n relinked builds a side"
./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs "$n" \
  --keep "$out/pool-samples" "${olds[@]: -$n}" -- "${news[@]: -$n}" > "$out/pool.out" 2> "$out/pool.err"
status=$?
echo "pool regress exit $status"; date -u; uptime
exit $status
