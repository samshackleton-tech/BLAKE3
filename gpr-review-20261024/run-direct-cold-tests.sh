#!/bin/bash
# Short setup/test job. No performance conclusions. The cold model uses
# existing clocks gaps and one contiguous producer/hash/consumer interval.
set -euo pipefail
. /root/.cargo/env
r=/root/results/gpr-chunk-root/direct-cold
mkdir -p "$r"
exec > "$r/test-runner.log" 2>&1
trap 'echo "tests exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-gpr-resident-d
[ "$(git -C "$wt" rev-parse HEAD)" = 6cad867a5cafe5b6d75f360be86b884dc026c5fb ]
b="$wt/bench-hashes"
[ "$(git -C "$b" rev-parse HEAD)" = 84248f33eb0a8d196e8e17a68acc711f4a5c641f ]
mv "$b" "$r/previous-benchmark-checkout"
git clone -q -b experiment/sam-direct-cold /root/bench-direct-cold.bundle "$b"
git -C "$b" remote set-url origin https://github.com/samshackleton-tech/bench-hashes
[ "$(git -C "$b" rev-parse HEAD)" = b7ebfa280f22f23ea182b3ba9eecbb4481a8e9d5 ]
export CARGO_TARGET_DIR=/root/BLAKE3-gpr-with-out/bench-contract-18de07c-backup/target
patch="patch.\"https://github.com/johnservil/BLAKE3\".blake3-servil.path=\"$wt\""
cd "$b"
cargo --config "$patch" update -q -p blake3-servil
for side in simd gpr; do
    if [ "$side" = gpr ]; then export BLAKE3_DIAGNOSTIC_GPR=1; else unset BLAKE3_DIAGNOSTIC_GPR; fi
    cargo nextest run --config "$patch" --release --features diag-direct-cold > "$r/tests-$side.log" 2>&1
    grep Summary "$r/tests-$side.log" >> "$r/status.log"
done
unset BLAKE3_DIAGNOSTIC_GPR
cargo nextest run --config "$patch" --release --features diag-direct-cold,diag-direct-fill -E 'test(after_gap_uses_the_same_producer_and_final_places)' > "$r/tests-fill.log" 2>&1
grep Summary "$r/tests-fill.log" >> "$r/status.log"
echo "tests complete $(date -Is)" >> "$r/status.log"
