#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-batch-overflow-20261025
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "overflow tests exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
(cd /root/BLAKE3-batch-overflow; CARGO_TARGET_DIR=/root/target-release-batch cargo nextest run --release > "$r/fixed.log" 2>&1) & fixed=$!
(cd /root/BLAKE3-batch-overflow-control; CARGO_TARGET_DIR=/root/target-release-batch-control cargo nextest run --release test_batch_rejects_block_count_overflow > "$r/control.log" 2>&1) & control=$!
set +e
wait "$fixed"; a=$?
wait "$control"; b=$?
set -e
printf 'fixed=%s negative=%s\n' "$a" "$b" >> "$r/status.log"
[ "$a" = 0 ] && [ "$b" = 100 ]
grep -q 'did not panic as expected' "$r/control.log"
git -C /root/BLAKE3-batch-overflow rev-parse HEAD > "$r/fixed-commit.txt"
git -C /root/BLAKE3-batch-overflow-control rev-parse HEAD > "$r/control-commit.txt"
echo "overflow controls complete $(date -Is)" >> "$r/status.log"
