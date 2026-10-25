#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/full-group-pool-20261024
exec > "$r/tests-runner.log" 2>&1
trap 'echo "tests exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
(cd /root/BLAKE3-full-group-pool; CARGO_TARGET_DIR=/root/target-private-symbols cargo nextest run --release > "$r/default.log" 2>&1) & fixed=$!
(cd /root/BLAKE3-full-group-control; CARGO_TARGET_DIR=/root/target-symbol-control cargo nextest run --release test_tree_group_piece_counts > "$r/control.log" 2>&1) & mutant=$!
set +e
wait "$fixed"; good=$?
wait "$mutant"; bad=$?
set -e
echo "default=$good negative=$bad" >> "$r/status.log"
[ "$good" = 0 ] && [ "$bad" = 100 ]
grep -q 'test_tree_group_piece_counts' "$r/control.log"
cd /root/BLAKE3-full-group-pool
CARGO_TARGET_DIR=/root/target-private-symbols cargo nextest run --release --success-output immediate test_tree_group_piece_counts > "$r/piece-shapes.log" 2>&1
(CARGO_TARGET_DIR=/root/target-symbol-pure cargo nextest run --release --features pure --lib > "$r/pure.log" 2>&1) & pure=$!
export BENCH_CLOCKS_CHECKOUT=/root/BLAKE3-load-other/clocks
export CARGO_TARGET_DIR=/root/target-latest-20261024
patch='patch."https://github.com/devonjonte/BLAKE3".blake3-servil.path="/root/BLAKE3-full-group-pool"'
clock='patch."https://github.com/devonjonte/BLAKE3".clocks.path="/root/BLAKE3-load-other/clocks"'
cd bench-hashes
cargo nextest run --config "$patch" --config "$clock" --release > "$r/bench-tests.log" 2>&1
wait "$pure"
cargo --config "$patch" --config "$clock" build -q --release > "$r/build.log" 2>&1
cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bench-hashes"
nm "$r/bench-hashes" > "$r/nm.txt"
python3 - "$r/nm.txt" <<'PY'
import pathlib,sys
rows=[s.split() for s in pathlib.Path(sys.argv[1]).read_text().splitlines()]
names={r[2]:r[0] for r in rows if len(r)==3 and r[1]=='T'}
for suffix in ['hash_many_sse41','hash_many_avx2','hash_many_avx512']:
 assert names['blake3_'+suffix]!=names['blake3_servil_'+suffix]
PY
echo "tests and build complete $(date -Is)" >> "$r/status.log"
