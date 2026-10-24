#!/bin/bash
# Combine Devon's batch alignment 665438c and heap-output bench 2b7c9ea
# (cherry-picked as 18de07c), against f503409 + Sam's optional GPR kernel.
# Validate integration only; no speed verdict until the per-message heap
# allocation identified in the output experiment is resolved.
set -euo pipefail
. /root/.cargo/env
r=/root/results/gpr-chunk-root/contract-integration
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-gpr-with-out
b="$wt/bench-hashes"
[ "$(git -C "$wt" rev-parse HEAD)" = e49e06f389ff79f36f4f1dd8ee1f91f35bd4ed7d ]
[ "$(git -C "$b" rev-parse HEAD)" = 2b7c9ea4f621df7c19855994258cb826c3aea81e ]
mv "$b" "$wt/bench-output-only-2b7c9ea"
git clone -q -b experiment/sam-contract-integration /root/bench-contract.bundle "$b"
git -C "$b" remote set-url origin https://github.com/samshackleton-tech/bench-hashes
cd "$b"
patch='patch."https://github.com/johnservil/BLAKE3".blake3-servil.path=".."'
cargo --config "$patch" update -q -p blake3-servil
cargo nextest run --config "$patch" --release > "$r/bench-tests.log" 2>&1
grep Summary "$r/bench-tests.log" >> "$r/status.log"
BLAKE3_DIAGNOSTIC_GPR=1 cargo nextest run --config "$patch" --release > "$r/bench-gpr-tests.log" 2>&1
grep Summary "$r/bench-gpr-tests.log" >> "$r/status.log"
cargo --config "$patch" build -q --release > "$r/build-simd.log" 2>&1
cp target/release/bench-hashes "$r/simd"
BLAKE3_DIAGNOSTIC_GPR=1 cargo --config "$patch" build -q --release > "$r/build-gpr.log" 2>&1
cp target/release/bench-hashes "$r/gpr"
git rev-parse HEAD > "$r/bench-head.txt"
git -C "$wt" rev-parse HEAD > "$r/library-head.txt"
echo "complete $(date -Is); defaults unchanged; tests only, no speed verdict" >> "$r/status.log"
