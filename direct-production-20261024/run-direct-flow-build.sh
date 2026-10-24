#!/bin/bash
# Build/test only, externally bounded <8 minutes. No global allocator change.
# Library adds identical aligned Stream ring to both SIMD/GPR builds.
set -euo pipefail
. /root/.cargo/env
r=/root/results/gpr-chunk-root/direct-flow
mkdir -p "$r"
exec > "$r/build-runner.log" 2>&1
trap 'echo "build exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-direct-flow-gpr
[ ! -e "$wt" ]
git -C /root/BLAKE3 fetch -q /root/library-direct-flow.bundle experiment/sam-direct-flow-gpr
git -C /root/BLAKE3 worktree add -q --detach "$wt" FETCH_HEAD
[ "$(git -C "$wt" rev-parse HEAD)" = 0627c0c38309a9e68ecf51ca1764978a67c6cb3d ]
cd "$wt"
BLAKE3_DIAGNOSTIC_GPR=1 cargo nextest run --release --lib --tests --no-fail-fast > "$r/library-tests.log" 2>&1
grep Summary "$r/library-tests.log" >> "$r/status.log"
git clone -q -b experiment/sam-direct-flow /root/bench-direct-flow.bundle "$wt/bench-hashes"
cd "$wt/bench-hashes"
git remote set-url origin https://github.com/samshackleton-tech/bench-hashes
[ "$(git rev-parse HEAD)" = d87f18ad70b55f5d53fe553bb4ff93a2139d642d ]
export CARGO_TARGET_DIR=/root/BLAKE3-gpr-with-out/bench-contract-18de07c-backup/target
patch="patch.\"https://github.com/johnservil/BLAKE3\".blake3-servil.path=\"$wt\""
cargo --config "$patch" update -q -p blake3-servil
cargo nextest run --config "$patch" --release --features diag-direct-flow > "$r/bench-tests-simd.log" 2>&1
grep Summary "$r/bench-tests-simd.log" >> "$r/status.log"
BLAKE3_DIAGNOSTIC_GPR=1 cargo nextest run --config "$patch" --release --features diag-direct-flow > "$r/bench-tests-gpr.log" 2>&1
grep Summary "$r/bench-tests-gpr.log" >> "$r/status.log"
cargo --config "$patch" build -q --release --features diag-direct-flow > "$r/build-simd.log" 2>&1
cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/simd-original-layout"
nm "$r/simd-original-layout" | python3 -c 'import sys; print("\n".join(sorted({f[2] for f in (l.split() for l in sys.stdin) if len(f)==3 and f[1] in "tT"})))' > "$r/symbols.txt"
mkdir -p "$r/bin" "$r/lld"
lld=$(find /usr/bin -maxdepth 1 -name 'ld.lld-*' | sort -V | tail -1)
[ -n "$lld" ]; ln -s "$lld" "$r/lld/ld.lld"
for side in simd gpr; do
    if [ "$side" = gpr ]; then export BLAKE3_DIAGNOSTIC_GPR=1; else unset BLAKE3_DIAGNOSTIC_GPR; fi
    for i in 0 1 2 3; do
        python3 - "$r/symbols.txt" "$r/$side-$i.order" "$side-$i" <<'PY'
import pathlib, random, sys
s=pathlib.Path(sys.argv[1]).read_text().splitlines()
random.Random(sys.argv[3]).shuffle(s)
pathlib.Path(sys.argv[2]).write_text('\n'.join(s)+'\n')
PY
        cargo --config "$patch" rustc -q --release --features diag-direct-flow --bin bench-hashes -- -Clink-arg=-fuse-ld=lld "-Clink-arg=-B$r/lld" "-Clink-arg=-Wl,--symbol-ordering-file=$r/$side-$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
        cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/$side-$i"
    done
    echo "$side relinked $(date -Is)" >> "$r/status.log"
done
unset BLAKE3_DIAGNOSTIC_GPR
cd "$r"
sha256sum bin/* > binaries.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 bin/* > binaries.blake3
echo "build complete $(date -Is)" >> "$r/status.log"
