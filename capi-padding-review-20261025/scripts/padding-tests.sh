#!/bin/bash
# Correctness review of PR158, no timing comparison.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-padding-review-20261025
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "padding review exit=$? $(date -Is)" >> "$r/status.log"' EXIT
(cd /root/BLAKE3-stream-padding-review; CARGO_TARGET_DIR=/root/target-release-padding cargo nextest run --release > "$r/default.log" 2>&1) & good=$!
(cd /root/BLAKE3-stream-padding-control; CARGO_TARGET_DIR=/root/target-release-padding-control cargo nextest run --release test_batch_with_zeroes_past_each_message > "$r/control.log" 2>&1) & bad=$!
set +e
wait "$good"; a=$?
wait "$bad"; b=$?
set -e
printf 'fixed=%s negative=%s\n' "$a" "$b" >> "$r/status.log"
[ "$a" = 0 ] && [ "$b" = 100 ]
grep -q '1-byte messages' "$r/control.log"
cd /root/BLAKE3-stream-padding-review
CARGO_TARGET_DIR=/root/target-release-padding-pure cargo nextest run --release --features pure > "$r/pure.log" 2>&1
git rev-parse HEAD > "$r/review-commit.txt"
git -C /root/BLAKE3-stream-padding-control rev-parse HEAD > "$r/control-commit.txt"
echo "padding review tests complete $(date -Is)" >> "$r/status.log"
