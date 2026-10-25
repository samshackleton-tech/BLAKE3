#!/bin/bash
set -euo pipefail
. /root/.cargo/env
ulimit -c 0
r=/root/results/release-latest-capi-guards-20261025
exec > "$r/runner.log" 2>&1
trap 'echo "latest C integration exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-latest-capi-guards
[ "$(git rev-parse HEAD)" = 07c245e712297d6eb6c39ebddffc3d20470eabc1 ]
(CARGO_TARGET_DIR=/root/target-latest-capi-native cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/native.log" 2>&1) & native=$!
(RUSTUP_TOOLCHAIN=nightly-2026-10-24 CARGO_TARGET_DIR=/root/target-latest-capi-miri python3 tools/test_capi_guards.py > "$r/miri.log" 2>&1) & miri=$!
result=0
for pid in "$native" "$miri"; do wait "$pid" || result=1; done
[ "$result" = 0 ]
echo "latest two-kinds C checks complete $(date -Is)" >> "$r/status.log"
