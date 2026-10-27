#!/bin/bash
# The full x86 mutation run on the EPYC 9255 (AVX-512 F/VL: the wide kernel's
# Rust paths live), at candidate/release-0.8 2907ea5d (0.8's x86 scope), in a clean worktree.
# The project's own tool; its exit status and full output are the result.
set -u
out=/root/results/mutants-rel-2907ea5
mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
exec 9>/root/bench-native-afk.lock
flock -w 600 9 || { echo "lock busy"; exit 75; }
R=/root/BLAKE3-round-pr164; D=/root/BLAKE3-mut-2907ea5
git -C $R fetch -q https://github.com/johnservil/BLAKE3 candidate/release-0.8 || exit 10
[ -d $D ] || git -C $R worktree add -q --detach $D 2907ea5dda304ba36a3308df90aa033701fd3dfc || exit 11
cd $D
{ date -u; git rev-parse HEAD; git status --short; lscpu | grep -E 'Model name|Flags' | cut -c1-300; cargo mutants --version; cargo nextest --version; rustc -V; } > $out/provenance.txt 2>&1
echo "start $(date -u)"
python3 tools/mutants/check.py > $out/check.log 2>&1
status=$?
[ $status = 0 ] || python3 tools/mutants/check.py --write > $out/check-write.log 2>&1; git diff > $out/write.diff
echo "check exit $status $(date -u)"
cp -a tmp/mutants-last $out/mutants-last 2>/dev/null
exit $status
