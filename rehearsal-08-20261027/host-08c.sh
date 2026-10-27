#!/bin/bash
# 0.8 on one machine, the release measurements at NEW with bench BENCH:
#  1. the suites at NEW (release-tests.sh), unless SKIP_TESTS=1
#  2. the release check, John's command (#125): check --against
#     candidate/base-0.8 (bfbda192) --old-bench 5be5f236 --cells all, with the
#     bench nested in the release checkout (check builds the enclosing fork)
#  3. a full run (--all) of the release commit: Cargo.toml's servil pin
#     patched to the enclosing checkout (Cargo.toml, CONTRIBUTING.md)
#  4. EPYC only (B3SUM=1): the b3sum run over the files, the fork's b3sum at
#     the release commit beside official's (tools/b3sum-contenders.py)
# Usage: host-08c.sh REPO OUT NEW BENCH   (REPO: a clone of johnservil/BLAKE3)
set -u
export HOME=/root
R0=$1; out=$2; NEW=$3; BENCH=$4; mkdir -p $out
exec > $out/bench-runner.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
# check's coverage needs the toolchain's llvm-tools before any older system LLVM
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
step() { echo "== $* $(date -u +%T)"; }
OLD=bfbda1920283335ff3802723db11c209159f47fc
OLDBENCH=5be5f23699ee7146ada56a08777173a4ee1c7bde
git -C $R0 fetch -q https://github.com/johnservil/BLAKE3 candidate/release-0.8 candidate/base-0.8 || exit 10
# NEWREPO/NEWREF: where NEW comes from (default John's release branch)
[ -n "${NEWREPO:-}" ] && { git -C $R0 fetch -q $NEWREPO $NEWREF || exit 10; }
git -C $R0 cat-file -e $NEW || git -C $R0 fetch -q https://github.com/johnservil/BLAKE3 $NEW || exit 10
R=/root/BLAKE3-rel-${NEW:0:8}
[ -d $R ] || git -C $R0 worktree add -q --detach $R $NEW || exit 10
[ "$(git -C $R rev-parse HEAD)" = "$(git -C $R0 rev-parse $NEW)" ] || { echo "checkout is not $NEW"; exit 10; }
git -C $R cat-file -e $OLD || exit 10
if [ "${SKIP_TESTS:-0}" != 1 ]; then
  step suites
  bash /root/release-tests.sh $R $out/tests; echo "suites exit $?"
fi
B=$R/bench-hashes
[ -d $B ] || git clone -q https://github.com/johnservil/bench-hashes $B || exit 21
git -C $B fetch -q https://github.com/johnservil/bench-hashes 2>/dev/null
# BENCHREPO/BENCHREF: where BENCH comes from, when not John's or Devon's
[ -n "${BENCHREPO:-}" ] && git -C $B fetch -q $BENCHREPO $BENCHREF
git -C $B cat-file -e $BENCH 2>/dev/null || git -C $B fetch -q https://github.com/johnservil/bench-hashes $BENCH 2>/dev/null || git -C $B fetch -q https://github.com/devonjonte/bench-hashes $BENCH || exit 21
git -C $B cat-file -e $OLDBENCH 2>/dev/null || git -C $B fetch -q https://github.com/johnservil/bench-hashes candidate/bench-blocks-old-side 2>/dev/null; git -C $B cat-file -e $OLDBENCH 2>/dev/null || git -C $B fetch -q https://github.com/devonjonte/bench-hashes $OLDBENCH 2>/dev/null || git -C $B fetch -q https://github.com/johnservil/bench-hashes $OLDBENCH || exit 21
git -C $B checkout -q --detach $BENCH || exit 22
[ "$(git -C $B rev-parse HEAD)" = "$(git -C $B rev-parse $BENCH)" ] || exit 22
cd $B
URL=$(python3 -c '
import re
s=open("Cargo.toml").read().split("[dependencies.blake3-servil]")[1]
print(re.search(r"git\s*=\s*\"([^\"]+)\"", s).group(1))')
PATCH="patch.\"$URL\".blake3-servil.path=\"..\""
echo "servil git $URL"
cargo build --release -q || exit 23
cargo build --release -q --config "$PATCH" --target-dir target-release-commit || exit 23
{ date -u; uptime; echo "library $(git -C $R rev-parse HEAD)"; git -C $R status --short; echo "bench $(git rev-parse HEAD)"; git status --short
  echo "old $OLD old-bench $OLDBENCH"; echo "full run: --config $PATCH"; rustc -V; } > $out/bench-provenance.txt
sleep 60

step release check
cargo run --release -q -- check --against $OLD --old-bench $OLDBENCH --cells all --keep $out/release-samples > $out/release.out 2> $out/release.err
echo "release exit $?"
git checkout -q -- index.html 2>/dev/null
sleep 30

step full run
cargo run --release -q --config "$PATCH" --target-dir target-release-commit -- --all > $out/full.out 2> $out/full.err
echo "full exit $?"
git status --porcelain --untracked-files=all > $out/full-status.txt
mkdir -p $out/full-results
cut -c4- $out/full-status.txt | while read -r f; do [ -f "$f" ] && cp --parents -a "$f" $out/full-results/; done
git checkout -q -- . 2>/dev/null; git clean -q -fd benchmark-results 2>/dev/null

if [ "${B3SUM:-0}" = 1 ]; then
  step b3sum builds
  python3 tools/b3sum-contenders.py $R /root/b3c > $out/b3sum-contenders.txt 2> $out/b3sum-build.log || { echo "b3sum build failed"; exit 30; }
  sleep 30
  step b3sum run
  tr '\n' '\0' < $out/b3sum-contenders.txt | xargs -0 cargo run --release -q -- b3sum --files /root/b3sum-files > $out/b3sum.out 2> $out/b3sum.err
  echo "b3sum exit $?"
  git status --porcelain --untracked-files=all > $out/b3sum-status.txt
  mkdir -p $out/b3sum-results
  cut -c4- $out/b3sum-status.txt | while read -r f; do [ -f "$f" ] && cp --parents -a "$f" $out/b3sum-results/; done
  git checkout -q -- . 2>/dev/null; git clean -q -fd benchmark-results 2>/dev/null
fi
step done; uptime
