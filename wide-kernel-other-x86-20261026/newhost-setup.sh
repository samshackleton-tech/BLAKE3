#!/bin/bash
# Set up a fresh Cherry Servers box (Ubuntu 26.04) like the EPYC 9255:
# the same packages, Rust 1.99.1, nextest 0.9.149, cargo-mutants 27.1.0,
# cargo-c 0.10.26; the candidate and bench checkouts. Idempotent.
set -eu
export HOME=/root
exec > /root/setup.log 2>&1
export DEBIAN_FRONTEND=noninteractive
echo "start $(date -u)"
apt-get update -q
apt-get install -y -q build-essential git curl libssl-dev python3 python3-z3 clang lld llvm pkg-config \
  linux-tools-common "linux-tools-$(uname -r)" util-linux numactl
if [ ! -x /root/.cargo/bin/rustup ]; then
  curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.99.1 --profile minimal
fi
. /root/.cargo/env
rustup default 1.99.1
cargo install --locked cargo-nextest --version 0.9.149
cargo install --locked cargo-mutants --version 27.1.0
cargo install --locked cargo-c --version 0.10.26
git config --global user.name 'Sam Shackleton'
git config --global user.email 'samshackleton-tech@users.noreply.github.com'
R=/root/BLAKE3
[ -d $R ] || git clone -q https://github.com/johnservil/BLAKE3 $R
git -C $R fetch -q https://github.com/johnservil/BLAKE3 candidate/release-0.8 servil
git -C $R checkout -q --detach 8c34ead4cf275289e4f405b409feca327c5c7828
git -C $R cat-file -e 0754066791424e571b7bfcb4f8ec85ee814b2706
[ -d $R/bench-hashes ] || git clone -q https://github.com/devonjonte/bench-hashes $R/bench-hashes
git -C $R/bench-hashes fetch -q https://github.com/devonjonte/bench-hashes d21cdf36dfc02716e173be4e5b4590c04361084a || true
git -C $R/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
# no frequency scaling games: performance governor where the driver allows
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > $g 2>/dev/null || true; done
{ rustc -V; cargo nextest --version | head -1; cargo mutants --version; cargo cinstall --version | head -1
  python3 -c 'import z3;print("z3",z3.get_version_string())'; ld.lld --version | head -1; perf --version
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; lscpu | grep -E 'Model name|^CPU\(s\)|Socket|NUMA node\(s\)'
  git -C $R log -1 --oneline; git -C $R/bench-hashes log -1 --oneline; } > /root/setup-versions.txt 2>&1
echo "done $(date -u)"
