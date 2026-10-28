#!/bin/bash
# BLAKE3 #207's x86 list (877f5146) on the EPYC 9255: the full mutation check, its exit status the verdict.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
git -C "$R/src" log -1 --format=%H > "$O/commit.txt"
cd "$R/src"; python3 tools/mutants/check.py > "$O/mutants-check.log" 2>&1; echo "mutants exit $?" > "$O/status.txt"
