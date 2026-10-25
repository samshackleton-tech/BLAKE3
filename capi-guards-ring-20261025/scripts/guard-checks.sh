#!/bin/bash
set -euo pipefail
. /root/.cargo/env
ulimit -c 0
r=/root/results/release-capi-guards-20261025
exec > "$r/runner.log" 2>&1
trap 'echo "guard checks exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-capi-contracts
git rev-parse HEAD > "$r/source-commit.txt"
(CARGO_TARGET_DIR=/root/target-release-capi cargo nextest run --release --manifest-path capi/Cargo.toml -E 'not test(bad_calls_stop_at_the_guard)' > "$r/native-valid.log" 2>&1) & native=$!
(MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance' CARGO_TARGET_DIR=/root/target-capi-guards-miri cargo +nightly-2026-10-24 miri nextest run --manifest-path capi/Cargo.toml --config-file .config/nextest.toml --profile miri miri_ > "$r/miri-valid.log" 2>&1) & miri=$!
result=0
for pid in "$native" "$miri"; do wait "$pid" || result=1; done
[ "$result" = 0 ]
python3 "$r/run-guard-miri.py" > "$r/guard-miri-runner.log" 2>&1
# Only after the interpreted bad calls reached their guards, test native aborts.
CARGO_TARGET_DIR=/root/target-release-capi cargo nextest run --release --manifest-path capi/Cargo.toml --success-output immediate > "$r/native-all.log" 2>&1
echo "guard and positive-control checks complete $(date -Is)" >> "$r/status.log"
