#!/bin/bash
# #195 (356e4ea) against 2907ea5d on this machine, all cells (Devon's i7 check,
# on another design). Bench: #87 (7f275a1) + John's candidate/names (3f9edd1),
# merged for measurement (samshackleton-tech/bench-hashes measure/bench87-names
# 9eb9f14): 7f275a1 alone predates 0.8's names and builds against neither side.
set -u
export HOME=/root
o=/root/results/pr195-check; mkdir -p $o
exec > $o/runner.log 2>&1
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
D=/root/BLAKE3-195; B=$D/bench-hashes
[ "$(git -C $D rev-parse --short=7 HEAD)" = 356e4ea ] || exit 10
git -C $D cat-file -e 2907ea5dda304ba36a3308df90aa033701fd3dfc || exit 10
[ -d $B ] || git clone -q https://github.com/devonjonte/bench-hashes $B || exit 11
git -C $B fetch -q https://github.com/samshackleton-tech/bench-hashes measure/bench87-names || exit 11
git -C $B checkout -q --detach 9eb9f14c3e364332043a15e9c741e3287a346e96 || exit 12
cd $B; cargo build --release -q || exit 13
{ date -u; uptime; grep -m1 'model name' /proc/cpuinfo; nproc; echo "library $(git -C $D rev-parse HEAD)"; git -C $D status --short; echo "bench $(git rev-parse HEAD)"; git status --short; } > $o/provenance.txt
sleep 60
cargo run --release -q -- check --against 2907ea5dda304ba36a3308df90aa033701fd3dfc --cells all --keep $o/samples > $o/check.out 2> $o/check.err
echo "check exit $?"; date -u; uptime
git checkout -q -- index.html 2>/dev/null
