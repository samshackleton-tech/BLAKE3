#!/bin/bash
set -euo pipefail
. /root/.cargo/env
ulimit -c 0
r=/root/results/release-review-integration-20261025
exec > "$r/runner.log" 2>&1
trap 'echo "review integration exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-release-review-integration
[ "$(git rev-parse HEAD)" = 96f017bc190e867c22d176a330da644bdf32ce3f ]
(CARGO_TARGET_DIR=/root/target-review-integration cargo nextest run --release > "$r/library.log" 2>&1) & library=$!
(CARGO_TARGET_DIR=/root/target-review-integration-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/capi.log" 2>&1) & capi=$!
result=0
for pid in "$library" "$capi"; do wait "$pid" || result=1; done
[ "$result" = 0 ]
echo "review integration native suites complete $(date -Is)" >> "$r/status.log"
