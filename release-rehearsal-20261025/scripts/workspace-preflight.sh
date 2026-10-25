#!/bin/bash
# Both unpublished packages, via Cargo's own temporary-registry support.
# The workspace is OUTSIDE the private rehearsal checkout. No source edit/upload.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-version-rehearsal-20261025
exec > "$r/workspace-runner.log" 2>&1
trap 'echo "workspace preflight exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
[ ! -e "$r/Cargo.toml" ]
cp "$r/workspace.toml" "$r/Cargo.toml"
cd "$r"
CARGO_TARGET_DIR=/root/target-versioned-workspace cargo publish --dry-run --manifest-path "$r/Cargo.toml" -p blake3-servil -p b3sums > "$r/workspace-dry-run.log" 2>&1
mkdir -p "$r/paired-artifacts"
cp /root/target-versioned-workspace/package/tmp-crate/*.crate "$r/paired-artifacts/"
python3 "$r/verify-pair.py" "$r" > "$r/verify-pair.log" 2>&1
git -C "$r/checkout" status --porcelain > "$r/status-after-workspace.txt"
[ ! -s "$r/status-after-workspace.txt" ]
git -C /root/BLAKE3-private-symbols-review show-ref --tags > "$r/production-tags-after-workspace.txt"
cmp "$r/production-tags-before.txt" "$r/production-tags-after-workspace.txt"
cd "$r/paired-artifacts"
sha256sum *.crate > artifacts.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 *.crate > artifacts.blake3
echo "paired package dry-run complete; source clean; production tags unchanged; no upload $(date -Is)" >> "$r/status.log"
