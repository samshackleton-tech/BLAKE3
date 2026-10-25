#!/bin/bash
set -euo pipefail
. /root/.cargo/env
ulimit -c 0
r=/root/results/github-round-capi-list
exec > "$r/runner.log" 2>&1
trap 'echo "C list tests exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-capi-contract-list
[ "$(git rev-parse HEAD)" = 17263a9ad05840bef17c69e8953b65e135e0e384 ]
(CARGO_TARGET_DIR=/root/target-round-capi-list cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/native.log" 2>&1) & native=$!
(CARGO_TARGET_DIR=/root/target-round-capi-list-lib cargo nextest run --release > "$r/library.log" 2>&1) & library=$!
(RUSTUP_TOOLCHAIN=nightly-2026-10-24 CARGO_TARGET_DIR=/root/target-round-capi-list-miri python3 tools/test_capi_guards.py > "$r/miri.log" 2>&1) & miri=$!
result=0
for pid in "$native" "$library" "$miri"; do wait "$pid" || result=1; done
[ "$result" = 0 ]
echo "shared C contract list checks complete $(date -Is)" >> "$r/status.log"
