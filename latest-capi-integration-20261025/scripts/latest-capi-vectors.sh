#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-latest-capi-guards-20261025
exec > "$r/vectors-runner.log" 2>&1
trap 'echo "latest C vectors exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-latest-capi-guards
[ "$(git rev-parse HEAD)" = 07c245e712297d6eb6c39ebddffc3d20470eabc1 ]
MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance' CARGO_TARGET_DIR=/root/target-latest-capi-vectors cargo +nightly-2026-10-24 miri nextest run --manifest-path capi/Cargo.toml --config-file .config/nextest.toml --profile miri -E 'binary(vectors)' > "$r/vectors.log" 2>&1
echo "latest two-kinds full C vectors complete $(date -Is)" >> "$r/status.log"
