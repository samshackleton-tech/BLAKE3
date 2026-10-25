#!/bin/bash
# Bounded EPYC regression screen for #152; existing bench-hashes owns timing/statistics.
set -euo pipefail
. /root/.cargo/env
r=/root/results/investigate-152-20261025
mkdir -p "$r/bin"
exec > "$r/runner.log" 2>&1
trap 'echo "benchmark exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
b=/root/bench-hashes-round-152
export CARGO_TARGET_DIR=/root/target-round-152
cd "$b"
[ "$(git rev-parse HEAD)" = d6ce88f6537a7fbd11ab9533853818b4adaf4824 ]
# Confirm source tests before measuring. Distinct target dirs keep independent builds separate.
(cd /root/BLAKE3-152-parent; CARGO_TARGET_DIR=/root/target-round-152-parent-tests cargo nextest run --release > "$r/parent-tests.log" 2>&1) & p1=$!
(cd /root/BLAKE3-152; CARGO_TARGET_DIR=/root/target-round-152-tests cargo nextest run --release > "$r/candidate-tests.log" 2>&1) & p2=$!
result=0
for pid in "$p1" "$p2"; do wait "$pid" || result=1; done
[ "$result" = 0 ] || exit "$result"
for group in parent control candidate; do
    wt=/root/BLAKE3-152-parent
    [ "$group" = candidate ] && wt=/root/BLAKE3-152
    cd "$wt/bench-hashes"
    patch='patch."https://github.com/johnservil/BLAKE3".blake3-servil.path=".."'
    cargo --config "$patch" build -q --release > "$r/build-$group.log" 2>&1
    cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/$group-initial"
    nm "$CARGO_TARGET_DIR/release/bench-hashes" | python3 -c 'import sys; print("\n".join(sorted({f[2] for l in sys.stdin if len(f:=l.split())==3 and f[1] in "tT"})))' > "$r/symbols-$group.txt"
    for i in 0 1 2 3; do
        python3 - "$r/symbols-$group.txt" "$r/$group-$i.order" "$group-$i" <<'PY'
import pathlib,random,sys
s=pathlib.Path(sys.argv[1]).read_text().splitlines()
random.Random('152-epyc-'+sys.argv[3]).shuffle(s)
pathlib.Path(sys.argv[2]).write_text('\n'.join(s)+'\n')
PY
        cargo --config "$patch" rustc -q --release --bin bench-hashes -- -Clink-arg=-fuse-ld=lld -Clink-arg=-B/root/results/afk-20261024-runtime-control/lld "-Clink-arg=-Wl,--symbol-ordering-file=$r/$group-$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
        cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/$group-$i"
    done
    echo "$group built $(date -Is)" >> "$r/status.log"
done
python3 - "$r" <<'PY'
from pathlib import Path
import sys
r=Path(sys.argv[1])
for group,commit in [('parent','61b469ce'),('candidate','3d67a0d'),('control','61b469ce')]: 
    p=r/f'smoke-{group}'
    p.mkdir(exist_ok=True)
    import subprocess
    subprocess.run([str(r/'bin'/f'{group}-initial'),'--contenders','blake3-servil-st','--points','64 B','--rounds','1'],cwd=p,stdout=(p/'run.out').open('w'),stderr=(p/'run.err').open('w'),check=True)
    sample=next(p.rglob('bench-hashes.samples.tsv'))
    headers=''.join(x for x in sample.open() if x.startswith('#'))
    assert commit in headers and 'dirty' not in headers,headers
    (r/f'{group}-provenance.txt').write_text(headers)
PY
# Binary audit: old shared name versus private name in the actual candidate.
python3 - "$r/bin/candidate-initial" "$r/bin/parent-initial" "$r" <<'PY'
import subprocess,sys,pathlib
out=pathlib.Path(sys.argv[3])
for name,path in [('candidate',sys.argv[1]),('parent',sys.argv[2])]:
    text=subprocess.check_output(['nm','-n',path],text=True)
    (out/f'{name}-nm.txt').write_text(text)
    symbols={x.split()[2]:x[0] for x in text.splitlines() if len(x.split())==3 and x.split()[1]=='T'}
    assert 'blake3_hash_many_avx512' in symbols
    if name=='candidate':
        assert 'blake3_servil_hash_many_avx512' in symbols
        assert symbols['blake3_hash_many_avx512']!=symbols['blake3_servil_hash_many_avx512']
    else:
        assert 'blake3_servil_hash_many_avx512' not in symbols
PY
sha256sum "$r"/bin/* > "$r/binaries.sha256"
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 "$r"/bin/* > "$r/binaries.blake3"
cd "$r"
points='64 B,256 B,1 KiB,1536 B,4 KiB,8 KiB,512 KiB,1 MiB,idle 64 B,idle 256 B,idle 1 KiB,idle 1536 B,idle 4 KiB,16,48,1024,idle 16,idle 48,idle 1024,lent batch 16,lent batch 1024,continuous batch 16,continuous batch 1024,lent 64 B,lent 256 B,lent 1 KiB,lent 4 KiB,continuous 64 B,continuous 256 B,continuous 1 KiB'
mkdir -p aa comparison
set +e
"$r/bin/parent-0" regress --contenders blake3-servil-st,blake3-servil-mt --points "$points" --pairs 4 --keep "$r/aa/samples" "$r"/bin/parent-{0..3} -- "$r"/bin/control-{0..3} > aa/regress.out 2> aa/regress.err
aa=$?
set -e
echo "A/A exit=$aa $(date -Is)" >> status.log
[ "$aa" -le 2 ]
"$r/bin/parent-0" compare "$r"/aa/samples/run-*-old.tsv -- "$r"/aa/samples/run-*-new.tsv > aa/compare.out 2> aa/compare.err
[ "$aa" = 0 ] || { echo 'BLOCKED by A/A' >> status.log; exit 0; }
set +e
"$r/bin/parent-0" regress --contenders blake3-servil-st,blake3-servil-mt --points "$points" --pairs 8 --keep "$r/comparison/samples" "$r"/bin/parent-{0..3} -- "$r"/bin/candidate-{0..3} > comparison/regress.out 2> comparison/regress.err
code=$?
set -e
echo "comparison exit=$code $(date -Is)" >> status.log
[ "$code" -le 2 ]
"$r/bin/parent-0" compare "$r"/comparison/samples/run-*-old.tsv -- "$r"/comparison/samples/run-*-new.tsv > comparison/compare.out 2> comparison/compare.err
echo "benchmark complete $(date -Is)" >> status.log
