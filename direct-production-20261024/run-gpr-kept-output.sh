#!/bin/bash
# Focused heap-output performance API screen. Bounded externally to <8 min.
# Same input/output contract on both sides: aligned lent input, one kept
# heap Hash per thread; convenience OneMessage is not measured here.
set -euo pipefail
. /root/.cargo/env
r=/root/results/gpr-chunk-root/kept-output
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-gpr-with-out
b="$wt/bench-hashes"
[ "$(git -C "$wt" rev-parse HEAD)" = e49e06f389ff79f36f4f1dd8ee1f91f35bd4ed7d ]
[ "$(git -C "$b" rev-parse HEAD)" = 18de07c2d52904ca250cec7501ba4f2e97d9f1c8 ]
mv "$b" "$wt/bench-contract-18de07c-backup"
git clone -q -b experiment/sam-gpr-contract-screen /root/bench-contract-fixed.bundle "$b"
git -C "$b" remote set-url origin https://github.com/samshackleton-tech/bench-hashes
[ "$(git -C "$b" rev-parse HEAD)" = 2b0ab2874dda0234f63bec7df1bb34de6b952951 ]
cd "$b"
# Reuse dependency artifacts, not executable names, from the integration build.
export CARGO_TARGET_DIR="$wt/bench-contract-18de07c-backup/target"
patch="patch.\"https://github.com/johnservil/BLAKE3\".blake3-servil.path=\"$wt\""
cargo --config "$patch" update -q -p blake3-servil
cargo nextest run --config "$patch" --release > "$r/bench-tests.log" 2>&1
grep Summary "$r/bench-tests.log" >> "$r/status.log"
BLAKE3_DIAGNOSTIC_GPR=1 cargo nextest run --config "$patch" --release > "$r/bench-gpr-tests.log" 2>&1
grep Summary "$r/bench-gpr-tests.log" >> "$r/status.log"
cargo --config "$patch" build -q --release > "$r/build.log" 2>&1
cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/simd-default-layout"
nm "$r/simd-default-layout" | python3 -c 'import sys; print("\n".join(sorted({f[2] for f in (l.split() for l in sys.stdin) if len(f)==3 and f[1] in "tT"})))' > "$r/symbols.txt"
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
        cargo --config "$patch" rustc -q --release --bin bench-hashes -- -Clink-arg=-fuse-ld=lld "-Clink-arg=-B$r/lld" "-Clink-arg=-Wl,--symbol-ordering-file=$r/$side-$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
        cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/$side-$i"
    done
    echo "$side relinked $(date -Is)" >> "$r/status.log"
done
unset BLAKE3_DIAGNOSTIC_GPR
cd "$r"
set +e
taskset -c 2 "$r/bin/simd-0" regress --contenders blake3-servil-st --points 'lent 64 B,lent 256 B,lent 1 KiB,lent 4 KiB' --pairs 8 --keep "$r/samples" "$r"/bin/simd-{0..3} -- "$r"/bin/gpr-{0..3} > "$r/regress.out" 2> "$r/regress.err"
code=$?
set -e
echo "regress exit=$code (focused screen, 4 layouts/side)" >> "$r/status.log"
[ "$code" -le 2 ]
"$r/bin/simd-0" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
sha256sum bin/* > "$r/binaries.sha256"
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 bin/* > "$r/binaries.blake3"
echo "complete $(date -Is)" >> "$r/status.log"
