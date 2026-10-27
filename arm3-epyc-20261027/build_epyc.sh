#!/bin/bash
# The three builds of Devon's arm-3 probe at devonjonte candidate/devon-no-portable 8769d4b3.
set -eu
export HOME=/root; . /root/.cargo/env
R=/root/BLAKE3-round-pr164; A=/root/arm3; mkdir -p $A
git -C $R fetch -q https://github.com/devonjonte/BLAKE3 candidate/devon-no-portable
git -C $R cat-file -e 8769d4b3
for b in keep delete whole; do
  [ -d $A/$b ] || git -C $R worktree add -q --detach $A/$b 8769d4b3
  cd $A/$b; git checkout -q -- .; git clean -qfd
  [ $b = delete ] && git apply /root/arm3-src/delete.diff
  [ $b = whole ] && git apply /root/arm3-src/whole.diff
  mkdir -p examples; cp /root/arm3-src/arm3_probe.rs examples/arm3_probe.rs
  CARGO_TARGET_DIR=target-probe cargo build -q --release --example arm3_probe
  git diff --stat | tail -1 | sed "s/^/$b: /"
done
