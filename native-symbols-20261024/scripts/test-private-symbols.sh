#!/bin/bash
set -euo pipefail
. /root/.cargo/env
ulimit -c 0
r=/root/results/latest-20261024/private-symbols
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "private-symbols exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
# The identical new assertion must fail without the fix.
(cd /root/BLAKE3-symbol-control; CARGO_TARGET_DIR=/root/target-symbol-control cargo nextest run --release test_native_kernels_are_private_when_official_is_linked > "$r/control.log" 2>&1) & p1=$!
(cd /root/BLAKE3-private-symbols; CARGO_TARGET_DIR=/root/target-private-symbols cargo nextest run --release > "$r/default.log" 2>&1) & p2=$!
set +e
wait "$p1"; control=$?
wait "$p2"; fixed=$?
set -e
printf 'control=%s fixed=%s\n' "$control" "$fixed" >> "$r/status.log"
[ "$control" = 100 ] && [ "$fixed" = 0 ]
grep -q "servil's FFI bound upstream's native kernel" "$r/control.log"
cd /root/BLAKE3-private-symbols
(CARGO_TARGET_DIR=/root/target-symbol-pure cargo nextest run --release --features pure --lib > "$r/pure.log" 2>&1) & p1=$!
(CARGO_TARGET_DIR=/root/target-symbol-nostd cargo nextest run --release --no-default-features --lib > "$r/no-std.log" 2>&1) & p2=$!
result=0
for pid in "$p1" "$p2"; do wait "$pid" || result=1; done
[ "$result" = 0 ]
export CARGO_TARGET_DIR=/root/target-latest-20261024
export BENCH_CLOCKS_CHECKOUT=/root/BLAKE3-load-other/clocks
patch='patch."https://github.com/devonjonte/BLAKE3".blake3-servil.path="/root/BLAKE3-private-symbols"'
clock='patch."https://github.com/devonjonte/BLAKE3".clocks.path="/root/BLAKE3-load-other/clocks"'
cd /root/BLAKE3-private-symbols/bench-hashes
cargo nextest run --config "$patch" --config "$clock" --release > "$r/bench-tests.log" 2>&1
cargo --config "$patch" --config "$clock" build --release > "$r/build.log" 2>&1
cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bench-hashes"
nm "$r/bench-hashes" > "$r/nm.txt"
python3 - "$r/nm.txt" <<'PY'
import pathlib,sys
rows=[line.split() for line in pathlib.Path(sys.argv[1]).read_text().splitlines()]
symbols={row[2]:row[0] for row in rows if len(row)==3 and row[1]=='T'}
for suffix in ['hash_many_sse41','compress_in_place_sse41','compress_xof_sse41','hash_many_avx2','hash_many_avx512','compress_in_place_avx512','compress_xof_avx512','xof_many_avx512']:
 old='blake3_'+suffix; new='blake3_servil_'+suffix
 assert old in symbols and new in symbols,(old,new)
 assert symbols[old]!=symbols[new],(old,new,symbols[old])
 print(old,symbols[old],new,symbols[new])
PY
sha256sum "$r/bench-hashes" > "$r/binary.sha256"
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 "$r/bench-hashes" > "$r/binary.blake3"
echo "private-symbol tests and separate-entry check complete $(date -Is)" >> "$r/status.log"
