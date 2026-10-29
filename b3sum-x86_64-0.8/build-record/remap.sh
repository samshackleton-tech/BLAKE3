#!/bin/bash
# Does --remap-path-prefix make tools/b3sum-release.sh's build reproduce across checkouts?
# The script's own build line, with the checkout and CARGO_HOME remapped.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
T='v0.8.0+b3c5efc7c975d903762dea809066f7c0a0603861'; tgt=x86_64-unknown-linux-gnu
for d in src src2; do
  cd "$R/$d"
  RUSTFLAGS="-C target-feature=+crt-static --remap-path-prefix=$R/$d=/build --remap-path-prefix=${CARGO_HOME:-$HOME/.cargo}=/cargo" \
    cargo build --release --locked --manifest-path b3sum/Cargo.toml --target $tgt --target-dir target/b3sum-release > "$O/$d-build.log" 2>&1 || exit 3
  cp target/b3sum-release/$tgt/release/b3sum "$O/b3sum-$d"
  strings -n 8 "$O/b3sum-$d" | grep -c "$R" > "$O/$d-paths.txt" || true
done
cmp "$O/b3sum-src" "$O/b3sum-src2" && echo "reproduces with remap" > "$O/result.txt" || echo "still differs" > "$O/result.txt"
printf '' | "$O/b3sum-src" --no-names >> "$O/result.txt"; sha256sum "$O"/b3sum-src* >> "$O/result.txt"
