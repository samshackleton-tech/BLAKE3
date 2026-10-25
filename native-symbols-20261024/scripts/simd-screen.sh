#!/bin/bash
# Bounded current-instrument screen of draft #141, not a release gate.
set -euo pipefail
. /root/.cargo/env
r=/root/results/latest-20261024/simd-screen
mkdir -p "$r/bin"
exec > "$r/runner.log" 2>&1
trap 'echo "screen exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
export BENCH_CLOCKS_CHECKOUT=/root/BLAKE3-load-other/clocks
clock='patch."https://github.com/devonjonte/BLAKE3".clocks.path="/root/BLAKE3-load-other/clocks"'
# Tests may run concurrently; no benchmark runs beside them.
(cd /root/BLAKE3-api-current; CARGO_TARGET_DIR=/root/target-latest-20261024 cargo nextest run --release > "$r/base-tests.log" 2>&1) & p1=$!
(cd /root/BLAKE3-api-simd-root; CARGO_TARGET_DIR=/root/target-latest-candidate cargo nextest run --release > "$r/candidate-tests.log" 2>&1) & p2=$!
result=0
for pid in "$p1" "$p2"; do wait "$pid" || result=1; done
[ "$result" = 0 ] || exit "$result"
cp /root/results/latest-20261024/bin/L0 "$r/bin/a-0"
cp /root/results/latest-20261024/bin/L1 "$r/bin/a-1"
cp /root/results/latest-20261024/bin/L2 "$r/bin/a-2"
for group in a b candidate; do
    wt=/root/BLAKE3-api-current
    [ "$group" != candidate ] || wt=/root/BLAKE3-api-simd-root
    export CARGO_TARGET_DIR=/root/target-latest-20261024
    patch="patch.\"https://github.com/devonjonte/BLAKE3\".blake3-servil.path=\"$wt\""
    cd "$wt/bench-hashes"
    if [ "$group" = candidate ]; then
        cargo nextest run --config "$patch" --config "$clock" --release > "$r/candidate-bench-tests.log" 2>&1
        cargo --config "$patch" --config "$clock" build -q --release > "$r/candidate-build.log" 2>&1
        nm "$CARGO_TARGET_DIR/release/bench-hashes" | python3 -c 'import sys; print("\n".join(sorted({f[2] for l in sys.stdin if len(f:=l.split())==3 and f[1] in "tT"})))' > "$r/candidate-symbols.txt"
    fi
    symbols=/root/results/latest-20261024/symbols.txt
    [ "$group" != candidate ] || symbols="$r/candidate-symbols.txt"
    for i in 0 1 2 3; do
        if [ "$group" = a ] && [ "$i" != 3 ]; then continue; fi
        python3 - "$symbols" "$r/$group-$i.order" "$group-$i" <<'PY'
import pathlib,random,sys
names=pathlib.Path(sys.argv[1]).read_text().splitlines()
random.Random('latest-simd-screen-'+sys.argv[3]).shuffle(names)
pathlib.Path(sys.argv[2]).write_text('\n'.join(names)+'\n')
PY
        cargo --config "$patch" --config "$clock" rustc -q --release --bin bench-hashes -- -Clink-arg=-fuse-ld=lld -Clink-arg=-B/root/results/afk-20261024-runtime-control/lld "-Clink-arg=-Wl,--symbol-ordering-file=$r/$group-$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
        cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/$group-$i"
    done
    echo "$group built $(date -Is)" >> "$r/status.log"
done
cd "$r"
# Gates on source headers precede speed measurements.
for group in a candidate; do
    mkdir -p "$r/smoke-$group"
    cd "$r/smoke-$group"
    "$r/bin/$group-0" --contenders blake3-servil-st --points '64 B' --rounds 1 > run.out 2> run.err
done
python3 - "$r" <<'PY'
import pathlib,sys
r=pathlib.Path(sys.argv[1])
for group,commit in [('a','f31ad2fdc668'),('candidate','d3a21a40')]:
 p=next((r/f'smoke-{group}').rglob('bench-hashes.samples.tsv'))
 headers=[]
 for line in p.open():
  if not line.startswith('#'): break
  headers.append(line)
 s=''.join(headers)
 assert commit in s and '0d38c5f' in s and 'd6671f57483b' in s and 'dirty' not in s, s
PY
cd "$r"
points='64 B,256 B,1 KiB,1536 B,4 KiB,512 KiB,1 MiB,idle 64 B,idle 256 B,idle 1 KiB,idle 512 KiB,lent 64 B,lent 256 B,lent 1 KiB,lent 4 KiB,continuous 64 B,continuous 256 B,continuous 1 KiB,continuous batch 16'
mkdir -p aa comparison
set +e
"$r/bin/a-0" regress --contenders blake3-servil-st,blake3-servil-mt --points "$points" --pairs 4 --keep "$r/aa/samples" "$r"/bin/a-{0..3} -- "$r"/bin/b-{0..3} > aa/regress.out 2> aa/regress.err
aa=$?
set -e
echo "A/A exit=$aa $(date -Is)" >> status.log
[ "$aa" -le 2 ]
"$r/bin/a-0" compare "$r"/aa/samples/run-*-old.tsv -- "$r"/aa/samples/run-*-new.tsv > aa/compare.out 2> aa/compare.err
[ "$aa" = 0 ] || { echo 'BLOCKED by A/A' >> status.log; exit 0; }
set +e
"$r/bin/a-0" regress --contenders blake3-servil-st,blake3-servil-mt --points "$points" --pairs 8 --keep "$r/comparison/samples" "$r"/bin/a-{0..3} -- "$r"/bin/candidate-{0..3} > comparison/regress.out 2> comparison/regress.err
code=$?
set -e
echo "comparison exit=$code $(date -Is)" >> status.log
[ "$code" -le 2 ]
"$r/bin/a-0" compare "$r"/comparison/samples/run-*-old.tsv -- "$r"/comparison/samples/run-*-new.tsv > comparison/compare.out 2> comparison/compare.err
sha256sum bin/* > binaries.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 bin/* > binaries.blake3
echo "screen complete $(date -Is)" >> status.log
