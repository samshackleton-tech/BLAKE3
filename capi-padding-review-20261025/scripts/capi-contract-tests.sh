#!/bin/bash
# Native installed-consumer tests and strict-provenance interpretation, no timing.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-capi-contracts-20261025
exec > "$r/runner.log" 2>&1
trap 'echo "C contract tests exit=$? $(date -Is)" >> "$r/status.log"' EXIT
(cd /root/BLAKE3-capi-contracts; CARGO_TARGET_DIR=/root/target-release-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/native.log" 2>&1) & native=$!
MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-strict-provenance' python3 "$r/run-capi-miri-v2.py" /root/BLAKE3-capi-contracts "$r" > "$r/miri-runner.log" 2>&1 & checked=$!
result=0
for pid in "$native" "$checked"; do wait "$pid" || result=1; done
[ "$result" = 0 ]
python3 - "$r" <<'PY'
import json,pathlib,sys
r=pathlib.Path(sys.argv[1]);data=json.loads((r/'outcomes.json').read_text());assert len(data['cases'])==11
invalid={'batch-overlap-control','stream-reentry-control','uninitialized-read-control'}
for case in data['cases']:
 if case['case'] in invalid: assert case['exit']==1 and case['miri_undefined_behavior_diagnostic'],case
 else: assert case['exit']==0 and case['completed_case'],case
PY
# The old callback converts ctx through an integer. This control is an
# unsupported strict-provenance operation, not a claim of Rust UB by itself.
set +e
MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-strict-provenance' CARGO_TARGET_DIR=/root/target-capi-strict-old cargo +nightly-2026-10-24 miri run --manifest-path /root/results/release-capi-miri-v2-current/fixture/Cargo.toml -- stream-context-control > "$r/old-context-strict.log" 2>&1
old=$?
set -e
echo "old strict-provenance context control=$old" >> "$r/status.log"
[ "$old" = 1 ]
grep -qi 'integer-to-pointer' "$r/old-context-strict.log"
echo "native consumers and strict-provenance controls complete $(date -Is)" >> "$r/status.log"
