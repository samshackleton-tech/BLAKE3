#!/bin/bash
# bench-hashes #73 rebased onto main: its tests and the provenance cases A-E.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
B="$R/bench"; F="$R/fork-clocks"; N="$R/fork/bench-hashes"
line() { grep -h -E "^# (git clean status|clocks source|source blake3-servil-st):" "$1"/benchmark-results/*/bench-hashes.samples.tsv; }
run() { d="$O/$1"; mkdir -p "$d"; (cd "$d" && "$2" --contenders sha256,blake3-servil-st --points "64 B" --rounds 1 > run.out 2> run.err); line "$d" > "$O/$1.txt"; }
cd "$B"
cargo build --release > "$O/build-A.log" 2>&1 || exit 2
cargo nextest run --release > "$O/tests.log" 2>&1; echo "tests exit $?" >> "$O/status.txt"
run A "$B/target/release/bench-hashes"
git status --porcelain > "$O/A-tree.txt"
# B: clocks patched, no BENCH_CLOCKS_CHECKOUT: the build must stop.
P="patch.\"https://github.com/johnservil/BLAKE3\".clocks.path=\"$F/clocks\""
cargo build --release --config "$P" --target-dir "$R/t-B" > "$O/build-B.log" 2>&1; echo "B build exit $?" >> "$O/status.txt"
git checkout -q -- Cargo.lock
# C: patched and named.
BENCH_CLOCKS_CHECKOUT="$F/clocks" cargo build --release --config "$P" --target-dir "$R/t-C" > "$O/build-C.log" 2>&1; echo "C build exit $?" >> "$O/status.txt"
run C "$R/t-C/release/bench-hashes"
git checkout -q -- Cargo.lock
# D: build-against in the fork layout (the bench nested in the fork).
(cd "$N" && cargo build --release > "$O/build-D0.log" 2>&1 && ./target/release/bench-hashes build-against .. 2> "$O/build-D.log" | tail -1 > "$O/D-exe.txt")
run D "$(cat "$O/D-exe.txt")"
git -C "$N" status --porcelain > "$O/D-tree.txt"
# E: an edited source file reads dirty.
echo "// edit" >> src/chart.rs
cargo build --release --target-dir "$R/t-E" > "$O/build-E.log" 2>&1
run E "$R/t-E/release/bench-hashes"
git checkout -q -- src/chart.rs
grep -n "BENCH_CLOCKS_CHECKOUT" "$O/build-B.log" | head -2 > "$O/B-message.txt"
