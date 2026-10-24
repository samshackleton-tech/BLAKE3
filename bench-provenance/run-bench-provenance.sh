#!/bin/bash
# bench-hashes candidate/sam-clocks-provenance 36c592e (on main f4f347c):
# A default build: clocks line pinned, clean. B clocks patched without
# BENCH_CLOCKS_CHECKOUT: build stops. C patched with it: line names the
# checkout, clean. D servil patched (the fork's layout, bench inside it):
# clean, servil line local. E an edited source file: dirty. F the tests.
set -u
. /root/.cargo/env
r=/root/results/bench-provenance
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
b=/root/bench-prov
rm -rf "$b"; git clone -q -b candidate/sam-clocks-provenance /root/bench-prov.bundle "$b" || exit 3
[ "$(git -C "$b" rev-parse HEAD)" = 36c592eb8574e81c503fa176be63c42f03b00cdf ] || exit 3
git -C "$b" remote set-url origin https://github.com/samshackleton-tech/bench-hashes
export CARGO_TARGET_DIR=/root/bench-prov-target
clocks=/root/BLAKE3-load-other/clocks
patch="patch.\"https://github.com/johnservil/BLAKE3\".clocks.path=\"$clocks\""
hdr() { # name: run the built bench briefly, keep its samples header lines of interest
    o="$r/$1"; mkdir -p "$o"
    ( cd "$o" && "$CARGO_TARGET_DIR/release/bench-hashes" --contenders blake3-official --points '64 B' --rounds 2 > run.out 2>&1 )
    grep -hE '^# (git clean status|clocks source|dependency lock|source blake3-servil-st)' "$o"/benchmark-results/*/bench-hashes.samples.tsv > "$o/header.txt"
    status "$1: $(tr '\n' '|' < "$o/header.txt")"
}
# A
( cd "$b" && cargo build -q --release ) > "$r/A-build.log" 2>&1; status "A build exit=$?"; hdr A
# B
( cd "$b" && cargo --config "$patch" update -q -p clocks && cargo --config "$patch" build -q --release ) > "$r/B-build.log" 2>&1; status "B build exit=$? (must fail)"
grep -m1 -E "BENCH_CLOCKS_CHECKOUT" "$r/B-build.log" >> "$r/status.log"
# C
( cd "$b" && BENCH_CLOCKS_CHECKOUT="$clocks" cargo --config "$patch" build -q --release ) > "$r/C-build.log" 2>&1; status "C build exit=$?"
( cd "$r" && BENCH_CLOCKS_CHECKOUT="$clocks" hdr C )
git -C "$b" checkout -q -- Cargo.lock
# D: the fork's layout, bench inside a servil checkout, servil patched to ..
fork=/root/BLAKE3-base-b94e2fa
[ -e "$fork/bench-hashes.saved-prov" ] && exit 3
[ -d "$fork/bench-hashes" ] && mv "$fork/bench-hashes" "$fork/bench-hashes.saved-prov"
git clone -q -b candidate/sam-clocks-provenance /root/bench-prov.bundle "$fork/bench-hashes" || exit 3
git -C "$fork/bench-hashes" remote set-url origin https://github.com/samshackleton-tech/bench-hashes
sp='patch."https://github.com/johnservil/BLAKE3".blake3-servil.path=".."'
( cd "$fork/bench-hashes" && cargo --config "$sp" update -q -p blake3-servil && cargo --config "$sp" build -q --release ) > "$r/D-build.log" 2>&1; status "D build exit=$?"
hdr D
rm -rf "$fork/bench-hashes"
[ -d "$fork/bench-hashes.saved-prov" ] && mv "$fork/bench-hashes.saved-prov" "$fork/bench-hashes"
# E: an edit
echo '// edit' >> "$b/src/overview.rs"
( cd "$b" && cargo build -q --release ) > "$r/E-build.log" 2>&1; status "E build exit=$?"; hdr E
git -C "$b" checkout -q -- src/overview.rs
# F
( cd "$b" && cargo nextest run --release ) > "$r/F-tests.log" 2>&1; status "F tests exit=$?"
grep -E "Summary" "$r/F-tests.log" >> "$r/status.log"
printf 'done\n' > "$r/complete"
