#!/bin/bash
# Bounded tooling setup; the stable/default toolchain is unchanged.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-capi-miri-20261025
mkdir -p "$r"
exec > "$r/setup.log" 2>&1
trap 'echo "miri setup exit=$? $(date -Is)" >> "$r/status.log"' EXIT
rustup show active-toolchain > "$r/default-before.txt"
rustup toolchain install nightly-2026-10-24 --profile minimal --component miri --component rust-src
rustc +nightly-2026-10-24 -Vv > "$r/toolchain.txt"
cargo +nightly-2026-10-24 miri --version >> "$r/toolchain.txt"
cargo +nightly-2026-10-24 miri setup
rustup show active-toolchain > "$r/default-after.txt"
cmp "$r/default-before.txt" "$r/default-after.txt"
echo "miri setup complete; stable default unchanged $(date -Is)" >> "$r/status.log"
