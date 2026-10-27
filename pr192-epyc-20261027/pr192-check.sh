#!/bin/bash
# #192 (Devon, forked child panics; a pool change) on the EPYC 9255:
# new 2eaad1c against its parent fb2cbda (#190's head), check's own selection
# (the cells that load the pool), --pairs 8, as Devon ran it on the i7.
# Bench: #87 (devonjonte candidate/devon-bench-018-fixes 7f275a1), the 0.18 bench.
set -u
export HOME=/root
out=/root/results/pr192-check
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
. /root/.cargo/env
# check finds llvm-profdata on PATH first; Ubuntu's (LLVM 21) can't read Rust
# 1.99's profiles (LLVM 23), so the toolchain's own llvm-tools come first.
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
R=/root/BLAKE3-round-pr164; D=/root/BLAKE3-fork-panic
git -C $R fetch -q https://github.com/devonjonte/BLAKE3 candidate/devon-fork-panic || exit 10
[ -d $D ] || git -C $R worktree add -q --detach $D 2eaad1c || exit 11
git -C $D checkout -q --detach 2eaad1c || exit 11
[ "$(git -C $D rev-parse HEAD | cut -c1-7)" = 2eaad1c ] || exit 12
[ "$(git -C $D rev-parse HEAD~1 | cut -c1-7)" = fb2cbda ] || exit 12
B=$D/bench-hashes
[ -d $B ] || git clone -q https://github.com/devonjonte/bench-hashes $B || exit 13
git -C $B fetch -q https://github.com/devonjonte/bench-hashes candidate/devon-bench-018-fixes || exit 13
git -C $B checkout -q --detach 7f275a1 || exit 14
cd $B
cargo build --release -q || exit 15
{
  date -u; uptime; nproc
  echo "library: $(git -C .. rev-parse HEAD)"; git -C .. status --short
  echo "bench:   $(git rev-parse HEAD)"; git status --short
} > "$out/provenance.txt" 2>&1
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || { echo "bench lock busy"; exit 75; }
sleep 30; date -u
cargo run --release -q -- check --against fb2cbda --pairs 8 \
  --keep "$out/samples" > "$out/check.out" 2> "$out/check.err"
status=$?
echo "check exit $status"
date -u; uptime
git checkout -q -- index.html 2>/dev/null
exit $status
