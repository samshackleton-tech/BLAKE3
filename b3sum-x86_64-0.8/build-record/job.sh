#!/bin/bash
# 0.8's Linux x86-64 b3sum release binary (BLAKE3 #125): tools/b3sum-release.sh in a
# clean checkout of the tag, twice (two checkouts), to see if the build reproduces.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
T='v0.8.0+b3c5efc7c975d903762dea809066f7c0a0603861'
for d in src src2; do
  cd "$R/$d"
  git fetch -q https://github.com/johnservil/BLAKE3 "refs/tags/$T:refs/tags/$T" || exit 3
  [ "$(git rev-parse "$T^{commit}")" = "$(git rev-parse HEAD)" ] || { echo "tag is not HEAD in $d"; exit 4; }
  git status --porcelain --untracked-files=no > "$O/$d-status.txt"
  sh tools/b3sum-release.sh > "$O/$d-release.log" 2>&1; echo "$d release exit $?" >> "$O/status.txt"
  git describe --tags --exact-match > "$O/$d-describe.txt"
done
cd "$R"
N="b3sum-$T-x86_64-unknown-linux-gnu"
for d in src src2; do (cd $d/dist && sha256sum "$N" && cat "$N.b3") > "$O/$d-digests.txt"; done
cmp src/dist/$N src2/dist/$N && echo "reproduces: identical bytes in two checkouts" >> "$O/status.txt" || echo "does not reproduce across checkouts" >> "$O/status.txt"
mkdir -p "$O/dist"; cp src/dist/$N src/dist/$N.sha256 src/dist/$N.b3 "$O/dist/"
file "$O/dist/$N" > "$O/file.txt"; (ldd "$O/dist/$N" 2>&1 || true) > "$O/ldd.txt"
"$O/dist/$N" --version > "$O/version.txt" 2>&1
printf '' | "$O/dist/$N" --no-names > "$O/empty.txt"
(cd "$O/dist" && sha256sum -c "$N.sha256" && "./$N" --check "$N.b3") > "$O/selfcheck.txt" 2>&1
rustc -V > "$O/rustc.txt"; grep -m1 PRETTY_NAME /etc/os-release >> "$O/rustc.txt"
