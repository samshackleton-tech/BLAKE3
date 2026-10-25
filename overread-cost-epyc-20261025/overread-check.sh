#!/bin/bash
# #168: AVX-512 cost of the over-read fix, Devon's exact command.
# new = bfbda19 (fixed, #164 names), old = a137c68 (measurement-only unfixed).
set -u
out=/root/results/overread-check-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
. /root/.cargo/env
# The server has no git identity; check's worktree commits need one.
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
cd /root/BLAKE3-round-pr164/bench-hashes
{
  date -u; uptime; nproc
  echo "library: $(git -C .. rev-parse HEAD)"; git -C .. status --short
  echo "bench:   $(git rev-parse HEAD)"; git status --short; git diff
} > "$out/provenance.txt" 2>&1
exec 9>/root/bench-native-afk.lock
flock -n 9 || { echo "bench lock busy"; exit 75; }
date -u
# --keep retains every pair's samples (check deletes them otherwise).
cargo run --release -- check --against a137c68 --cells all --pairs 12 \
  --keep "$out/samples" > "$out/check.out" 2> "$out/check.err"
status=$?
echo "check exit $status"
date -u; uptime
exit $status
