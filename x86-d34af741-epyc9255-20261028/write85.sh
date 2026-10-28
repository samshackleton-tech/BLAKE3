#!/bin/bash
# BLAKE3 #125: the x86 list at 85868fc9 on the EPYC 9255 (AVX-512 side): check.py, then --write and its diff.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
git -C "$R/src" log -1 --format=%H > "$O/commit.txt"
cd "$R/src"
python3 tools/mutants/check.py > "$O/mutants-check.log" 2>&1; echo "mutants exit $?" >> "$O/status.txt"
python3 tools/mutants/check.py --write > "$O/mutants-write.log" 2>&1; echo "mutants --write exit $?" >> "$O/status.txt"
git diff -- tools/mutants > "$O/mutants-write.diff"
cp tools/mutants/known-x86_64.txt tools/mutants/timeouts-x86_64.txt "$O/"
