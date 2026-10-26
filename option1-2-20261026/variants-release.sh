#!/bin/bash
# Option 1 (#125), on one machine: 1a = candidate/sam-wide-off, 1b =
# candidate/sam-wide-off-nobudget (1a + the tree budget off).
#   1. suites at 1a and 1b (skipped with SKIP_TESTS=1, where already run)
#   2. 1b against 1a (the budget's effect without the wide kernel)
#   3. 1a, then 1b, against 07540667 (the release check)
#   4. the CLI: old / 1a / 1b, default threads and one thread, 16 rounds, 4 layouts
# Usage: variants-release.sh REPO OUT
set -u
export HOME=/root
R=$1; out=$2; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
OLD=0754066791424e571b7bfcb4f8ec85ee814b2706; BENCH=d21cdf36dfc02716e173be4e5b4590c04361084a
git -C $R fetch -q https://github.com/samshackleton-tech/BLAKE3 candidate/sam-wide-off:refs/heads/candidate/sam-wide-off candidate/sam-wide-off-nobudget:refs/heads/candidate/sam-wide-off-nobudget || exit 10
A=$(git -C $R rev-parse candidate/sam-wide-off); B=$(git -C $R rev-parse candidate/sam-wide-off-nobudget)
[ "${A:0:7}" = 9927504 ] && [ "${B:0:7}" = 60f3a00 ] || { echo "unexpected heads $A $B"; exit 12; }
git -C $R cat-file -e $OLD || exit 12
for x in a:$A b:$B; do n=${x%%:*}; c=${x#*:}; d=/root/BLAKE3-1$n
  [ -d $d ] || git -C $R worktree add -q --detach $d $c || exit 11
  [ -d $d/bench-hashes ] || git clone -q https://github.com/devonjonte/bench-hashes $d/bench-hashes || exit 13
  git -C $d/bench-hashes fetch -q https://github.com/devonjonte/bench-hashes $BENCH 2>/dev/null; git -C $d/bench-hashes checkout -q --detach $BENCH || exit 13
done
{ date -u; uptime; lscpu | grep -E 'Model name|^CPU\(s\)|Socket|NUMA node\(s\)'; echo "1a $A"; echo "1b $B"; echo "old $OLD"; echo "bench $BENCH"; rustc -V; } > $out/provenance.txt 2>&1
if [ "${SKIP_TESTS:-0}" != 1 ]; then
  for n in a b; do
    step suites 1$n; d=/root/BLAKE3-1$n; T=/root/target-1$n; o=$out/suites-1$n; mkdir -p $o; st=0; cd $d
    (CARGO_TARGET_DIR=$T cargo nextest run --release > $o/default.log 2>&1) & p1=$!
    (CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $o/pure.log 2>&1) & p2=$!
    (CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $o/capi.log 2>&1) & p3=$!
    for p in $p1 $p2 $p3; do wait $p || st=1; done
    RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > $o/shuttle.log 2>&1 || st=1
    python3 tools/verify/cross_check_x86.py > $o/cross-check.log 2>&1 || st=1
    grep -hE 'Summary|test result:|all agree' $o/*.log > $o/summary.txt
    echo "1$n suites status $st"; [ $st = 0 ] || exit 20
  done
  sleep 60
fi
step 1b against 1a
cd /root/BLAKE3-1b/bench-hashes
cargo run --release -- check --against $A --cells all --pairs 12 --keep $out/ba-samples > $out/ba.out 2> $out/ba.err
echo "ba exit $?"
./target/release/bench-hashes compare $out/ba-samples/run-*-old.tsv -- $out/ba-samples/run-*-new.tsv > $out/ba-compare.out 2>&1
for n in a b; do
  step 1$n against 07540667
  cd /root/BLAKE3-1$n/bench-hashes
  cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/rel1$n-samples > $out/rel1$n.out 2> $out/rel1$n.err
  echo "rel1$n exit $?"
  ./target/release/bench-hashes compare $out/rel1$n-samples/run-*-old.tsv -- $out/rel1$n-samples/run-*-new.tsv > $out/rel1$n-compare.out 2>&1
done
step CLI builds
cd /root/BLAKE3-1a/bench-hashes; CLI=/root/cli-variants
LAYOUTS=4 python3 tools/b3sum-contenders.py $R $CLI $OLD $A $B > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; tail $out/cli-build.log; exit 30; }
sleep 20
for mode in mt st; do
  args=(); f=""; [ $mode = st ] && f=" --num-threads 1"
  for c in $OLD:old $A:1a $B:1b; do h=${c%%:*}; n=${c#*:}; for i in 0 1 2 3; do args+=("$n=$CLI/b3sum-${h:0:7}-L$i$f"); done; done
  for r in 1 2; do
    step CLI $mode run $r
    cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli-$mode-r$r.out 2> $out/cli-$mode-r$r.err
    echo "cli $mode r$r exit $?"
    git checkout -q -- benchmark-results 2>/dev/null; git clean -q -fd benchmark-results
  done
done
step done; date -u; uptime
