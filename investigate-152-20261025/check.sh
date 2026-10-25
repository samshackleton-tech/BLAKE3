#!/bin/bash
# Full existing check, including its second-stage fresh-layout suspects.
set -euo pipefail
. /root/.cargo/env
r=/root/results/investigate-152-20261025/check
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "full check exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
export GIT_AUTHOR_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
cd /root/BLAKE3-152/bench-hashes
[ "$(git rev-parse HEAD)" = d6ce88f6537a7fbd11ab9533853818b4adaf4824 ]
[ "$(git -C .. rev-parse HEAD)" = 3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4 ]
cargo run --release -- check --against 61b469ce88cec441859e7e6d698473acc9ddc929 --cells all --keep "$r/samples" > "$r/check.out" 2> "$r/check.err"
echo "full check complete $(date -Is)" >> "$r/status.log"
