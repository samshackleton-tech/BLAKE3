#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-capi-contract-final-20261025
exec > "$r/runner.log" 2>&1
trap 'echo "final C checks exit=$? $(date -Is)" >> "$r/status.log"' EXIT
(cd /root/BLAKE3-capi-contracts; CARGO_TARGET_DIR=/root/target-release-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/native.log" 2>&1) & native=$!
(cd /root/BLAKE3-capi-contracts; MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance' CARGO_TARGET_DIR=/root/target-capi-final-miri cargo +nightly-2026-10-24 miri nextest run --manifest-path capi/Cargo.toml --config-file .config/nextest.toml --profile miri miri_callback_context > "$r/miri.log" 2>&1) & fixed=$!
(cd /root/BLAKE3-capi-context-control; MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance' CARGO_TARGET_DIR=/root/target-capi-control-miri cargo +nightly-2026-10-24 miri nextest run --manifest-path capi/Cargo.toml --config-file .config/nextest.toml --profile miri miri_callback_context > "$r/control.log" 2>&1) & control=$!
set +e
wait "$native"; a=$?
wait "$fixed"; b=$?
wait "$control"; c=$?
set -e
printf 'native=%s fixed Miri=%s integer-control Miri=%s\n' "$a" "$b" "$c" >> "$r/status.log"
[ "$a" = 0 ] && [ "$b" = 0 ] && [ "$c" = 100 ]
grep -qi 'integer-to-pointer' "$r/control.log"
git -C /root/BLAKE3-capi-contracts rev-parse HEAD > "$r/review-commit.txt"
git -C /root/BLAKE3-capi-context-control rev-parse HEAD > "$r/control-commit.txt"
echo "final C contract/provenance checks complete $(date -Is)" >> "$r/status.log"
