#!/bin/bash
# 0.8 on a bare-metal box (BLAKE3 #125, John's plan of October 27):
#  1. the suites at 2907ea5d (release-tests.sh)
#  2. wait for /root/bench-commit.txt (bench-hashes 0.18's merged commit)
#  3. the release check, John's command: check --against candidate/base-0.8
#     (bfbda192) --old-bench 5be5f236 --cells all, bench nested in the checkout
#  4. a full bench-hashes 0.18 run (--all), for the benchmark pages
# Timing steps run alone, after their builds. Results in /root/results/r08.
set -u
export HOME=/root
out=/root/results/r08; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
step() { echo "== $* $(date -u +%T)"; }
R=/root/BLAKE3; NEW=2907ea5dda304ba36a3308df90aa033701fd3dfc; OLD=bfbda1920283335ff3802723db11c209159f47fc
OLDBENCH=5be5f23699ee7146ada56a08777173a4ee1c7bde
[ "$(git -C $R rev-parse HEAD)" = $NEW ] || { echo "checkout is not $NEW"; exit 10; }
git -C $R cat-file -e $OLD || exit 10
{ date -u; lscpu; cat /root/setup-versions.txt; uptime; } > $out/machine.txt 2>&1

step suites
bash /root/release-tests.sh $R $out/tests; echo "suites exit $?"

step waiting for the bench commit
for i in $(seq 1 1440); do [ -s /root/bench-commit.txt ] && break; sleep 30; done
BENCH=$(head -1 /root/bench-commit.txt | tr -d ' \n'); [ -n "$BENCH" ] || { echo "no bench commit"; exit 20; }
B=$R/bench-hashes
git -C $B fetch -q https://github.com/johnservil/bench-hashes || true
git -C $B fetch -q https://github.com/johnservil/bench-hashes $BENCH 2>/dev/null || git -C $B fetch -q https://github.com/devonjonte/bench-hashes $BENCH || exit 21
git -C $B cat-file -e $OLDBENCH 2>/dev/null || git -C $B fetch -q https://github.com/devonjonte/bench-hashes $OLDBENCH || git -C $B fetch -q https://github.com/johnservil/bench-hashes $OLDBENCH || exit 21
git -C $B checkout -q --detach $BENCH || exit 22
cd $B; cargo build --release -q || exit 23
{ echo "library $(git -C $R rev-parse HEAD)"; git -C $R status --short; echo "bench $(git rev-parse HEAD)"; git status --short; echo "old $OLD old-bench $OLDBENCH"; } > $out/provenance.txt
sleep 60

step release check
cargo run --release -q -- check --against $OLD --old-bench $OLDBENCH --cells all --keep $out/release-samples > $out/release.out 2> $out/release.err
echo "release exit $?"
git checkout -q -- index.html 2>/dev/null
sleep 30

step full run
cargo run --release -q -- --all > $out/full.out 2> $out/full.err
echo "full exit $?"
git status --porcelain --untracked-files=all > $out/full-status.txt
mkdir -p $out/full-results
cut -c4- $out/full-status.txt | while read -r f; do [ -f "$f" ] && cp --parents -a "$f" $out/full-results/; done
step done; uptime
