#!/bin/bash
# Option 2 (candidate/sam-wide-zen5) on a machine where the wide kernels are
# off (AVX-512, not Zen 5): suites, Shuttle, check-builds, the cross-check.
set -u
export HOME=/root
out=/root/results/zen5-tests; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
R=/root/BLAKE3; D=/root/BLAKE3-zen5
git -C $R fetch -q https://github.com/samshackleton-tech/BLAKE3 candidate/sam-wide-zen5 || exit 10
[ -d $D ] || git -C $R worktree add -q --detach $D FETCH_HEAD || exit 11
cd $D; git log -2 --oneline > $out/commit.txt; T=/root/target-zen5; st=0
grep -m1 -E 'vendor_id|cpu family' /proc/cpuinfo > $out/cpu.txt; grep -m1 'cpu family' /proc/cpuinfo >> $out/cpu.txt
(CARGO_TARGET_DIR=$T cargo nextest run --release > $out/default.log 2>&1) & p1=$!
(CARGO_TARGET_DIR=$T-debug cargo nextest run > $out/debug.log 2>&1) & p2=$!
(CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $out/pure.log 2>&1) & p3=$!
(CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > $out/no_std.log 2>&1) & p4=$!
(CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $out/capi.log 2>&1) & p5=$!
(CARGO_TARGET_DIR=$T-doc cargo test --doc > $out/doc.log 2>&1) & p6=$!
for p in $p1 $p2 $p3 $p4 $p5 $p6; do wait $p || st=1; done
RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > $out/shuttle.log 2>&1 || st=1
CARGO_TARGET_DIR=$T-builds bash tools/check-builds.sh > $out/check-builds.log 2>&1 || st=1
python3 tools/verify/cross_check_x86.py > $out/cross-check.log 2>&1 || st=1
CARGO_TARGET_DIR=$T cargo nextest run --release --no-capture wide 2> $out/wide-tests.log >&2 || st=1
grep -hE 'Summary|test result:|all agree|every build passes' $out/*.log > $out/summary.txt
echo "status $st"
