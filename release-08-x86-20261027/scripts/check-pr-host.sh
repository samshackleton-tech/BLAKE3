#!/bin/bash
# A PR's speed check on this machine: NEW (fetched from REPO BRANCH) against
# OLD, all cells, with the bench at BENCH (default 9eb9f14: #87 + John's
# candidate/names, merged for measurement) nested in NEW's checkout.
# Waits for any running c195 unit first (one timing job at a time).
# Usage: check-pr-host.sh REPO BRANCH NEW OLD OUT [BENCHREPO BENCHREF BENCH]
set -u
export HOME=/root
REPO=$1; BRANCH=$2; NEW=$3; OLD=$4; o=$5
BREPO=${6:-https://github.com/samshackleton-tech/bench-hashes}; BREF=${7:-measure/bench87-names}; BENCH=${8:-9eb9f14c3e364332043a15e9c741e3287a346e96}
mkdir -p $o; exec > $o/runner.log 2>&1
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
while systemctl is-active -q c195 2>/dev/null; do sleep 30; done
R=/root/BLAKE3; [ -d $R ] || R=/root/BLAKE3-round-pr164
D=/root/BLAKE3-check-${NEW:0:7}
git -C $R fetch -q $REPO $BRANCH || exit 10
[ -d $D ] || git -C $R worktree add -q --detach $D $NEW || exit 11
[ "$(git -C $D rev-parse HEAD)" = "$(git -C $R rev-parse $NEW)" ] || exit 12
git -C $D cat-file -e $OLD || exit 12
B=$D/bench-hashes
[ -d $B ] || git clone -q $BREPO $B || exit 13
git -C $B fetch -q $BREPO $BREF || exit 13
git -C $B checkout -q --detach $BENCH || exit 14
cd $B; cargo build --release -q || exit 15
{ date -u; uptime; grep -m1 'model name' /proc/cpuinfo; nproc; echo "library $(git -C $D rev-parse HEAD)"; git -C $D status --short
  echo "old $OLD"; echo "bench $(git rev-parse HEAD)"; git status --short; } > $o/provenance.txt
exec 9>/root/bench-native-afk.lock; flock -w 7200 9 || exit 75
sleep 60
cargo run --release -q -- check --against $OLD --cells all --keep $o/samples > $o/check.out 2> $o/check.err
echo "check exit $?"; date -u; uptime
git checkout -q -- index.html 2>/dev/null
