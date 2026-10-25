#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-review-integration-20261025
exec > "$r/builds-docs-runner.log" 2>&1
trap 'echo "builds/docs exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-release-review-integration
[ "$(git rev-parse HEAD)" = 96f017bc190e867c22d176a330da644bdf32ce3f ]
export CARGO_TARGET_DIR=/root/target-review-check-builds
sh tools/check-builds.sh > "$r/check-builds.log" 2>&1
CARGO_TARGET_DIR=/root/target-review-docs cargo test --doc > "$r/doc-tests.log" 2>&1
RUSTDOCFLAGS='-D warnings' CARGO_TARGET_DIR=/root/target-review-docs cargo doc --no-deps -p blake3-servil > "$r/rustdoc.log" 2>&1
echo "review integration build and documentation checks complete $(date -Is)" >> "$r/status.log"
