#!/bin/bash
# Release work on a new bare-metal box (#125), in order, results in /root/results/release:
#  1. suites at 8c34ead4 (+ Shuttle, check-builds, the AVX-512 cross-check of the proof model)
#  2. the wide kernel on this CPU: 8c34ead4 against ffd1a8e (the same, wide dispatch off),
#     check --cells all --pairs 12, then the CLI both ways
#  3. the release check, 8c34ead4 against 07540667, --cells all --pairs 12, plus the CLI
# Timing runs alone: the builds of each step finish before its timing starts.
set -u
export HOME=/root
out=/root/results/release; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
step() { echo "== $* $(date -u +%T)"; }
R=/root/BLAKE3; NEW=8c34ead4cf275289e4f405b409feca327c5c7828; OLD=0754066791424e571b7bfcb4f8ec85ee814b2706
NOWIDE=ffd1a8ef76dbcb4f07c9273ecc157f76005cd927
git -C $R fetch -q https://github.com/samshackleton-tech/BLAKE3 experiment/sam-degree32-no-wide || exit 10
git -C $R cat-file -e $NOWIDE || exit 10
{ date -u; lscpu; cat /root/setup-versions.txt; uptime; } > $out/machine.txt 2>&1

step suites
cd $R; T=/root/target; st=0; o=$out/suites; mkdir -p $o
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
grep -hE 'Summary|test result:|all agree|SKIP|skipped' $o/*.log > $o/summary.txt
echo "suites status $st"; [ $st = 0 ] || exit 20
sleep 60

cd $R/bench-hashes
step wide kernel: 8c34ead4 against the same without the wide dispatch
cargo run --release -- check --against $NOWIDE --cells all --pairs 12 --keep $out/wide-samples > $out/wide.out 2> $out/wide.err
echo "wide exit $?"
./target/release/bench-hashes compare $out/wide-samples/run-*-old.tsv -- $out/wide-samples/run-*-new.tsv > $out/wide-compare.out 2>&1
step release check: 8c34ead4 against 07540667
cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/release-samples > $out/release.out 2> $out/release.err
echo "release exit $?"
./target/release/bench-hashes compare $out/release-samples/run-*-old.tsv -- $out/release-samples/run-*-new.tsv > $out/release-compare.out 2>&1
step CLI builds
CLI=/root/cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py $R $CLI $OLD $NOWIDE $NEW > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; tail $out/cli-build.log; exit 30; }
sleep 20
for mode in mt st; do
  args=(); f=""; [ $mode = st ] && f=" --num-threads 1"
  for i in 0 1 2 3; do args+=("old=$CLI/b3sum-${OLD:0:7}-L$i$f"); done
  for i in 0 1 2 3; do args+=("nowide=$CLI/b3sum-${NOWIDE:0:7}-L$i$f"); done
  for i in 0 1 2 3; do args+=("new=$CLI/b3sum-${NEW:0:7}-L$i$f"); done
  for r in 1 2; do
    step CLI $mode run $r
    cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli-$mode-r$r.out 2> $out/cli-$mode-r$r.err
    echo "cli $mode r$r exit $?"
    mkdir -p $out/cli-$mode-r$r; cp -a benchmark-results/*/b3sum.* $out/cli-$mode-r$r/
    git checkout -q -- benchmark-results 2>/dev/null; git clean -q -fd benchmark-results
  done
done
step done; date -u; uptime
