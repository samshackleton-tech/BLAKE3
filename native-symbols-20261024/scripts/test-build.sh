#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/latest-20261024
mkdir -p "$r"
exec > "$r/test-build.log" 2>&1
trap 'echo "test-build exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
wt=/root/BLAKE3-api-current
b=$wt/bench-hashes
export CARGO_TARGET_DIR=/root/target-latest-20261024
export BENCH_CLOCKS_CHECKOUT=/root/BLAKE3-load-other/clocks
patch='patch."https://github.com/devonjonte/BLAKE3".blake3-servil.path="/root/BLAKE3-api-current"'
clock='patch."https://github.com/devonjonte/BLAKE3".clocks.path="/root/BLAKE3-load-other/clocks"'
(cd "$wt"; cargo nextest run --release --lib > "$r/library-tests.log" 2>&1) & lib=$!
(cd /root/BLAKE3-load-other/clocks; CARGO_TARGET_DIR=/root/target-latest-clocks cargo nextest run --release > "$r/clocks-tests.log" 2>&1) & clk=$!
(cd "$b"; cargo nextest run --config "$patch" --config "$clock" --release > "$r/bench-tests.log" 2>&1) & bench=$!
result=0
for pid in "$lib" "$clk" "$bench"; do wait "$pid" || result=1; done
[ "$result" = 0 ] || exit "$result"
cd "$b"
cargo --config "$patch" --config "$clock" build --release > "$r/build.log" 2>&1
cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bench-hashes"
"$r/bench-hashes" --help > "$r/help.txt"
git -C "$wt" rev-parse HEAD > "$r/library-commit.txt"
git -C "$b" rev-parse HEAD > "$r/benchmark-commit.txt"
git -C /root/BLAKE3-load-other rev-parse HEAD > "$r/clocks-commit.txt"
sha256sum "$r/bench-hashes" > "$r/binary.sha256"
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 "$r/bench-hashes" > "$r/binary.blake3"
echo "tests and build complete $(date -Is)" >> "$r/status.log"
