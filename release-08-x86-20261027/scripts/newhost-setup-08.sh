#!/bin/bash
# Set up a fresh Cherry Servers box (Ubuntu 26.04) like the EPYC 9255:
# the same packages, Rust 1.99.1, nextest 0.9.149, cargo-mutants 27.1.0,
# cargo-c 0.10.26; 0.8 at 2907ea5d and its base bfbda192. Idempotent.
# (No cargo-mutants: the full mutation run is the EPYC's.)
set -eu
export HOME=/root
exec > /root/setup.log 2>&1
export DEBIAN_FRONTEND=noninteractive
echo "start $(date -u)"
# A fresh box runs unattended-upgrades first; wait for its apt lock.
for i in $(seq 1 120); do pgrep -x 'apt|apt-get|dpkg|unattended-upgr' >/dev/null || break; sleep 10; done
apt-get -o DPkg::Lock::Timeout=600 update -q
apt-get -o DPkg::Lock::Timeout=600 install -y -q build-essential git curl libssl-dev python3 python3-z3 clang lld llvm pkg-config \
  linux-tools-common "linux-tools-$(uname -r)" util-linux numactl
if [ ! -x /root/.cargo/bin/rustup ]; then
  curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.99.1 --profile minimal
fi
. /root/.cargo/env
rustup default 1.99.1
rustup component add rustfmt
cargo install --locked cargo-nextest --version 0.9.149
cargo install --locked cargo-c --version 0.10.26
git config --global user.name 'Sam Shackleton'
git config --global user.email 'samshackleton-tech@users.noreply.github.com'
R=/root/BLAKE3
[ -d $R ] || git clone -q https://github.com/johnservil/BLAKE3 $R
git -C $R fetch -q https://github.com/johnservil/BLAKE3 candidate/release-0.8 candidate/base-0.8
git -C $R checkout -q --detach 2907ea5dda304ba36a3308df90aa033701fd3dfc
git -C $R cat-file -e bfbda1920283335ff3802723db11c209159f47fc
[ -d $R/bench-hashes ] || git clone -q https://github.com/johnservil/bench-hashes $R/bench-hashes
# no frequency scaling games: tuned (Cherry's images run it, balanced) and the
# apt timers off, which reset the governor; performance where the driver allows
systemctl disable --now tuned unattended-upgrades apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
for e in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do [ -e $e ] && echo performance > $e 2>/dev/null; done
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > $g 2>/dev/null || true; done
{ rustc -V; cargo nextest --version | head -1; cargo cinstall --version | head -1
  python3 -c 'import z3;print("z3",z3.get_version_string())'; ld.lld --version | head -1; perf --version
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; lscpu | grep -E 'Model name|^CPU\(s\)|Socket|NUMA node\(s\)'
  git -C $R log -1 --oneline; } > /root/setup-versions.txt 2>&1
echo "done $(date -u)"
