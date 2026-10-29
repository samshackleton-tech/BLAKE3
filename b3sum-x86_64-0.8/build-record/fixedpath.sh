#!/bin/bash
# Same test, each checkout moved in turn to one fixed path and built there by
# tools/b3sum-release.sh itself (unmodified), clean target each time.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
T='v0.8.0+b3c5efc7c975d903762dea809066f7c0a0603861'; N="b3sum-$T-x86_64-unknown-linux-gnu"; F=/root/b3sum-release-build
for d in src src2; do
  rm -rf $F; mv "$R/$d" $F; cd $F
  git fetch -q https://github.com/johnservil/BLAKE3 "refs/tags/$T:refs/tags/$T" || exit 3
  sh tools/b3sum-release.sh > "$O/$d-release.log" 2>&1 || exit 4
  cp dist/$N "$O/$d-$N"; cd /; mv $F "$R/$d"
done
cd "$O"; cmp src-$N src2-$N && echo "reproduces at one fixed path" > result.txt || echo "still differs" > result.txt
sha256sum src-$N src2-$N >> result.txt
