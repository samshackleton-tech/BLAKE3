#!/bin/bash
# Eight distinct layouts per side; existing bench-hashes owns all timing/statistics.
set -euo pipefail
. /root/.cargo/env
r=/root/results/full-group-pool-20261024
exec > "$r/screen-runner.log" 2>&1
trap 'echo "screen exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
export CARGO_TARGET_DIR=/root/target-latest-20261024
export BENCH_CLOCKS_CHECKOUT=/root/BLAKE3-load-other/clocks
patch='patch."https://github.com/devonjonte/BLAKE3".blake3-servil.path="/root/BLAKE3-full-group-pool"'
clock='patch."https://github.com/devonjonte/BLAKE3".clocks.path="/root/BLAKE3-load-other/clocks"'
mkdir -p "$r/bin" "$r/smoke"
cd "$r/smoke"
"$r/bench-hashes" --contenders blake3-servil-mt --points '512 KiB' --rounds 1 > run.out 2> run.err
python3 - "$r/smoke" <<'PY'
import pathlib,sys
p=next(pathlib.Path(sys.argv[1]).rglob('bench-hashes.samples.tsv'))
s=''.join(line for line in p.open() if line.startswith('#'))
assert '3d2c625' in s and '0d38c5f' in s and 'd6671f5' in s and 'dirty' not in s,s
PY
nm "$r/bench-hashes" | python3 -c 'import sys; print("\n".join(sorted({f[2] for l in sys.stdin if len(f:=l.split())==3 and f[1] in "tT"})))' > "$r/symbols.txt"
# Reuse every baseline layout in the pre-existing bank, not a selected subset.
for i in 0 1 2 3; do
    cp /root/results/latest-20261024/private-symbols/simd-screen/bin/a-$i "$r/bin/base-$i"
    cp /root/results/latest-20261024/private-symbols/simd-screen/bin/b-$i "$r/bin/base-$((i+4))"
done
cd /root/BLAKE3-full-group-pool/bench-hashes
for i in 0 1 2 3 4 5 6 7; do
    python3 - "$r/symbols.txt" "$r/candidate-$i.order" "$i" <<'PY'
import pathlib,random,sys
s=pathlib.Path(sys.argv[1]).read_text().splitlines()
random.Random('full-group-pool-'+sys.argv[3]).shuffle(s)
pathlib.Path(sys.argv[2]).write_text('\n'.join(s)+'\n')
PY
    cargo --config "$patch" --config "$clock" rustc -q --release --bin bench-hashes -- -Clink-arg=-fuse-ld=lld -Clink-arg=-B/root/results/afk-20261024-runtime-control/lld "-Clink-arg=-Wl,--symbol-ordering-file=$r/candidate-$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
    cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/candidate-$i"
    echo "layout $i built $(date -Is)" >> "$r/status.log"
done
cd "$r"
sha256sum bin/* > binaries.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 bin/* > binaries.blake3
points='256 KiB,512 KiB,1 MiB,2 MiB,8 MiB,64 MiB,idle 256 KiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,idle 8 MiB,idle 64 MiB,lent 256 KiB,lent 1 MiB,lent 4 MiB,lent 16 MiB,lent 64 MiB'
mkdir -p aa comparison
set +e
"$r/bin/base-0" regress --contenders blake3-servil-st,blake3-servil-mt --points "$points" --pairs 4 --keep "$r/aa/samples" "$r"/bin/base-{0..3} -- "$r"/bin/base-{4..7} > aa/regress.out 2> aa/regress.err
aa=$?
set -e
echo "A/A exit=$aa $(date -Is)" >> status.log
[ "$aa" -le 2 ]
"$r/bin/base-0" compare "$r"/aa/samples/run-*-old.tsv -- "$r"/aa/samples/run-*-new.tsv > aa/compare.out 2> aa/compare.err
[ "$aa" = 0 ] || { echo 'BLOCKED by A/A' >> status.log; exit 0; }
set +e
"$r/bin/base-0" regress --contenders blake3-servil-st,blake3-servil-mt --points "$points" --pairs 8 --keep "$r/comparison/samples" "$r"/bin/base-{0..7} -- "$r"/bin/candidate-{0..7} > comparison/regress.out 2> comparison/regress.err
code=$?
set -e
echo "comparison exit=$code $(date -Is)" >> status.log
[ "$code" -le 2 ]
"$r/bin/base-0" compare "$r"/comparison/samples/run-*-old.tsv -- "$r"/comparison/samples/run-*-new.tsv > comparison/compare.out 2> comparison/compare.err
echo "screen complete $(date -Is)" >> status.log
