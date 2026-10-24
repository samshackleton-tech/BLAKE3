#!/bin/bash
# Same kept-output benchmark and aligned lent contract; rolled integer
# kernel vs the SIMD layouts already measured. Four fresh rolled layouts,
# eight pairs. Time-bound externally to under eight minutes.
set -euo pipefail
. /root/.cargo/env
r=/root/results/gpr-chunk-root/rolled-kept-output
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-gpr-with-out-rolled
[ ! -e "$wt" ]
git -C /root/BLAKE3 fetch -q /root/gpr-out-rolled.bundle experiment/sam-gpr-with-out-rolled
git -C /root/BLAKE3 worktree add -q --detach "$wt" FETCH_HEAD
[ "$(git -C "$wt" rev-parse HEAD)" = e1c66a147725b390127f9a80cc2edde98ea8935c ]
cd "$wt"
python3 tools/gen_x86_gpr_rolled.py | cmp - c/blake3_gpr_chunk_root_x86-64_unix.S
BLAKE3_DIAGNOSTIC_GPR=1 cargo nextest run --release --lib --tests --no-fail-fast > "$r/library-tests.log" 2>&1
grep Summary "$r/library-tests.log" >> "$r/status.log"
git clone -q -b experiment/sam-gpr-contract-screen /root/bench-contract-fixed.bundle "$wt/bench-hashes"
git -C "$wt/bench-hashes" remote set-url origin https://github.com/samshackleton-tech/bench-hashes
cd "$wt/bench-hashes"
export CARGO_TARGET_DIR=/root/BLAKE3-gpr-with-out/bench-contract-18de07c-backup/target
patch="patch.\"https://github.com/johnservil/BLAKE3\".blake3-servil.path=\"$wt\""
cargo --config "$patch" update -q -p blake3-servil
export BLAKE3_DIAGNOSTIC_GPR=1
cargo nextest run --config "$patch" --release > "$r/bench-tests.log" 2>&1
grep Summary "$r/bench-tests.log" >> "$r/status.log"
base=/root/results/gpr-chunk-root/kept-output
mkdir -p "$r/bin"
for i in 0 1 2 3; do
    cargo --config "$patch" rustc -q --release --bin bench-hashes -- -Clink-arg=-fuse-ld=lld "-Clink-arg=-B$base/lld" "-Clink-arg=-Wl,--symbol-ordering-file=$base/gpr-$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
    cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/rolled-$i"
done
unset BLAKE3_DIAGNOSTIC_GPR
cd "$r"
set +e
taskset -c 2 "$base/bin/simd-0" regress --contenders blake3-servil-st --points 'lent 64 B,lent 256 B,lent 1 KiB,lent 4 KiB' --pairs 8 --keep "$r/samples" "$base"/bin/simd-{0..3} -- "$r"/bin/rolled-{0..3} > "$r/regress.out" 2> "$r/regress.err"
code=$?
set -e
echo "regress exit=$code (focused screen, 4 layouts/side)" >> "$r/status.log"
[ "$code" -le 2 ]
"$base/bin/simd-0" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
sha256sum bin/* > binaries.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 bin/* > binaries.blake3
echo "complete $(date -Is)" >> "$r/status.log"
