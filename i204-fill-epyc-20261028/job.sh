#!/bin/bash
# BLAKE3 #204: Devon's fill-like-read prototype on the EPYC 9255: its suites,
# then his check, against 83d59db with the 0.18.1 bench on the old side.
set -u
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
R="$1"; O="$R/out"; mkdir -p "$O"
cd "$R/src"; git cat-file -e 83d59db22f6d606d96a5e38223d411123e8cbd18 || git fetch -q https://github.com/johnservil/BLAKE3 candidate/release-0.8
(CARGO_TARGET_DIR="$R/t" cargo nextest run --release > "$O/tests.log" 2>&1; echo "tests exit $?" >> "$O/tests.log")
(CARGO_TARGET_DIR="$R/t-nostd" cargo nextest run --release --no-default-features > "$O/tests-nostd.log" 2>&1; echo "tests exit $?" >> "$O/tests-nostd.log")
cd "$R/src/bench-hashes"; git cat-file -e 2c9633ae69712b2e40363584387ba5665261997b || git fetch -q https://github.com/johnservil/bench-hashes candidate/bench-0.18
# The orchestrating binary: bench 0.18.1 (the new bench builds only against the new
# library, which check does itself, from this directory, for the new side).
(cd "$R/b0181" && cargo build --release > "$O/bench-build.log" 2>&1) || exit 5
sleep 30
"$R/b0181/target/release/bench-hashes" check --against 83d59db22f6d606d96a5e38223d411123e8cbd18 --old-bench 2c9633ae69712b2e40363584387ba5665261997b --cells all --keep "$O/samples" > "$O/check.out" 2> "$O/check.err"
echo "check exit $?" >> "$O/check.out"
git -C "$R/src" log -1 --format=%H > "$O/commit.txt"; git log -1 --format=%H >> "$O/commit.txt"
