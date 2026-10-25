#!/bin/bash
# AFK authorization: full C ABI vector cases interpreted, not performance work.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-capi-guards-20261025
exec > "$r/afk-vectors-runner.log" 2>&1
trap 'echo "AFK C API vectors exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-capi-contracts
[ "$(git rev-parse HEAD)" = 50d28e289d035dbde089e5016b3ffef8c599f0a9 ]
# Same default Miri profile as CI, with one outer job limit rather than
# short native timeouts. Native and installed C tests already passed.
MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance' CARGO_TARGET_DIR=/root/target-capi-vectors-miri cargo +nightly-2026-10-24 miri nextest run --manifest-path capi/Cargo.toml --config-file .config/nextest.toml --profile miri -E 'binary(vectors)' > "$r/afk-vectors.log" 2>&1
echo "full C ABI vectors interpreted $(date -Is)" >> "$r/status.log"
