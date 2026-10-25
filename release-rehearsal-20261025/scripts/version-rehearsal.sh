#!/bin/bash
# Rehearsal ONLY: private clone, disabled push URL, no production refs changed.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-version-rehearsal-20261025
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "version rehearsal exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
source=/root/BLAKE3-private-symbols-review
[ "$(git -C "$source" rev-parse HEAD)" = 3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4 ]
git -C "$source" show-ref --tags > "$r/production-tags-before.txt"
[ ! -e "$r/checkout" ]
git clone -q --shared --no-checkout "$source" "$r/checkout"
cd "$r/checkout"
git checkout -q --detach 3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4
[ "$(git rev-parse --path-format=absolute --git-common-dir)" = "$r/checkout/.git" ]
git remote set-url origin https://example.invalid/release-rehearsal.git
git remote set-url --push origin disabled://release-rehearsal
git config user.name 'Sam Shackleton'
git config user.email 'samshackleton-tech@users.noreply.github.com'
git config core.hooksPath /dev/null
python3 tools/gen-ver.py 0.8.0 > "$r/gen-ver.log" 2>&1
python3 "$r/verify-version.py" "$r" > "$r/verify-version.log" 2>&1
git -C "$source" show-ref --tags > "$r/production-tags-after.txt"
cmp "$r/production-tags-before.txt" "$r/production-tags-after.txt"
git status --porcelain > "$r/status-after.txt"
[ ! -s "$r/status-after.txt" ]
git show --format=fuller --stat HEAD > "$r/version-commit.txt"
git diff HEAD^ HEAD > "$r/version.diff"
echo "private-clone version rehearsal complete; production tags unchanged $(date -Is)" >> "$r/status.log"
