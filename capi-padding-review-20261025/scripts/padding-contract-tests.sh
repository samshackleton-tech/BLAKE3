#!/bin/bash
# PR158 plus the portable owner-contract assertion. No performance measurement.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-padding-contract-20261025
exec > "$r/runner.log" 2>&1
trap 'echo "padding contract review exit=$? $(date -Is)" >> "$r/status.log"' EXIT
(cd /root/BLAKE3-stream-padding-contract; CARGO_TARGET_DIR=/root/target-release-padding cargo nextest run --release > "$r/default.log" 2>&1) & good=$!
(cd /root/BLAKE3-padding-contract-control; CARGO_TARGET_DIR=/root/target-release-padding-control cargo nextest run --release test_batch_with_zeroes_past_each_message > "$r/control.log" 2>&1) & bad=$!
set +e
wait "$good"; a=$?
wait "$bad"; b=$?
set -e
printf 'fixed=%s negative=%s\n' "$a" "$b" >> "$r/status.log"
[ "$a" = 0 ] && [ "$b" = 100 ]
grep -q '0-byte message retained padding' "$r/control.log"
cd /root/BLAKE3-stream-padding-contract
CARGO_TARGET_DIR=/root/target-release-padding-pure cargo nextest run --release --features pure > "$r/pure.log" 2>&1
MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks' CARGO_TARGET_DIR=/root/target-padding-contract-miri cargo +nightly-2026-10-24 miri nextest run --profile miri --features pure -E 'test(test_batch_with_zeroes_past_each_message)' > "$r/miri.log" 2>&1
git rev-parse HEAD > "$r/review-commit.txt"
git -C /root/BLAKE3-padding-contract-control rev-parse HEAD > "$r/control-commit.txt"
echo "padding contract review complete $(date -Is)" >> "$r/status.log"
