#!/bin/bash
# Direct: caller-only (2cf9a56, working tree) judged against wide-everywhere (a49ff2c), 12 pairs.
set -u
out=/root/results/wide-20261025/caller-vs-everywhere; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
exec 9>/root/bench-native-afk.lock; flock -w 600 9 || exit 75
cd /root/BLAKE3-wide-caller/bench-hashes
E=$(git -C .. rev-parse HEAD^)
echo "new $(git -C .. rev-parse HEAD) against $E $(date -u)"
cargo run --release -- check --against $E --cells all --pairs 12 --keep $out/samples > $out/check.out 2> $out/check.err
echo "exit $?"
./target/release/bench-hashes compare $out/samples/run-*-old.tsv -- $out/samples/run-*-new.tsv > $out/compare.out 2>&1
date -u
