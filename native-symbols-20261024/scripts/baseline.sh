#!/bin/bash
# Three full-size maps: reconnaissance, not a paired regression verdict.
set -euo pipefail
. /root/.cargo/env
r=/root/results/latest-20261024
exec > "$r/baseline-runner.log" 2>&1
trap 'echo "baseline exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
wt=/root/BLAKE3-api-current
b=$wt/bench-hashes
export CARGO_TARGET_DIR=/root/target-latest-20261024
export BENCH_CLOCKS_CHECKOUT=/root/BLAKE3-load-other/clocks
patch='patch."https://github.com/devonjonte/BLAKE3".blake3-servil.path="/root/BLAKE3-api-current"'
clock='patch."https://github.com/devonjonte/BLAKE3".clocks.path="/root/BLAKE3-load-other/clocks"'
contenders=blake3-official,blake3-servil-st,blake3-official-mt,blake3-servil-mt
mkdir -p "$r/smoke" "$r/bin"
cd "$r/smoke"
"$r/bench-hashes" --contenders "$contenders" --points '64 B,4' --rounds 1 > run.out 2> run.err
python3 - "$r/smoke" <<'PY'
import pathlib,sys
p=next(pathlib.Path(sys.argv[1]).rglob('bench-hashes.samples.tsv'))
headers=[]
for line in p.open():
    if line.startswith('#'): headers.append(line)
    else: break
s=''.join(headers)
assert 'f31ad2fd' in s, s
assert 'd6671f57483b' in s, s
assert '0d38c5f' in s, s
assert 'dirty' not in s, s
print(s)
PY
nm "$r/bench-hashes" | python3 -c 'import sys; print("\n".join(sorted({f[2] for l in sys.stdin if len(f:=l.split())==3 and f[1] in "tT"})))' > "$r/symbols.txt"
cp "$r/bench-hashes" "$r/bin/L0"
for i in 0 1 2; do
    if [ "$i" != 0 ]; then
        python3 - "$r/symbols.txt" "$r/L$i.order" "$i" <<'PY'
import pathlib,random,sys
names=pathlib.Path(sys.argv[1]).read_text().splitlines()
random.Random('latest-20261024-'+sys.argv[3]).shuffle(names)
pathlib.Path(sys.argv[2]).write_text('\n'.join(names)+'\n')
PY
        cd "$b"
        cargo --config "$patch" --config "$clock" rustc -q --release --bin bench-hashes -- -Clink-arg=-fuse-ld=lld -Clink-arg=-B/root/results/afk-20261024-runtime-control/lld "-Clink-arg=-Wl,--symbol-ordering-file=$r/L$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
        cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/L$i"
    fi
    mkdir -p "$r/map-$i"
    cd "$r/map-$i"
    echo "map $i starting $(date -Is)" >> "$r/status.log"
    "$r/bin/L$i" --contenders "$contenders" > run.out 2> run.err
    echo "map $i complete $(date -Is)" >> "$r/status.log"
done
cd "$r"
sha256sum bin/* > binaries.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 bin/* > binaries.blake3
echo "baseline maps complete $(date -Is)" >> status.log
