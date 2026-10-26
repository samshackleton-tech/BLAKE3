#!/bin/bash
set -u
export HOME=/root
out=/root/results/mutants-9e77e03; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
R=/root/BLAKE3; D=/root/BLAKE3-mut
git -C $R fetch -q https://github.com/samshackleton-tech/BLAKE3 candidate/sam-avx512-mutation-rows || exit 10
[ -d $D ] || git -C $R worktree add -q --detach $D 9e77e03 || exit 11
cd $D; { date -u; git rev-parse HEAD; git status --short; lscpu | grep 'Model name'; } > $out/provenance.txt
echo "start $(date -u)"
python3 tools/mutants/check.py > $out/check.log 2>&1
echo "check exit $? $(date -u)"
