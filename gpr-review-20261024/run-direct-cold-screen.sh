#!/bin/bash
# Bounded short screen: three sets of four fresh layouts (SIMD A/A, then
# SIMD vs resident-D GPR), same direct caller warm/after work/after idle.
# Not a full validation gate. All timing uses bench-hashes.
set -euo pipefail
. /root/.cargo/env
r=/root/results/gpr-chunk-root/direct-cold
exec > "$r/screen-runner.log" 2>&1
trap 'echo "screen exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-gpr-resident-d
b="$wt/bench-hashes"
[ "$(git -C "$b" rev-parse HEAD)" = b7ebfa280f22f23ea182b3ba9eecbb4481a8e9d5 ]
[ "$(git -C "$wt" rev-parse HEAD)" = 6cad867a5cafe5b6d75f360be86b884dc026c5fb ]
export CARGO_TARGET_DIR=/root/BLAKE3-gpr-with-out/bench-contract-18de07c-backup/target
patch="patch.\"https://github.com/johnservil/BLAKE3\".blake3-servil.path=\"$wt\""
cd "$b"
cargo --config "$patch" build -q --release --features diag-direct-cold > "$r/build-initial.log" 2>&1
nm "$CARGO_TARGET_DIR/release/bench-hashes" | python3 -c 'import sys; print("\n".join(sorted({f[2] for l in sys.stdin if len(f:=l.split())==3 and f[1] in "tT"})))' > "$r/symbols.txt"
mkdir -p "$r/bin"
lld=/root/results/afk-20261024-runtime-control/lld
for group in simd-a simd-b gpr; do
    if [ "$group" = gpr ]; then export BLAKE3_DIAGNOSTIC_GPR=1; else unset BLAKE3_DIAGNOSTIC_GPR; fi
    for i in 0 1 2 3; do
        python3 - "$r/symbols.txt" "$r/$group-$i.order" "$group-$i" <<'PY'
import pathlib, random, sys
s=pathlib.Path(sys.argv[1]).read_text().splitlines()
random.Random('direct-cold-'+sys.argv[3]).shuffle(s)
pathlib.Path(sys.argv[2]).write_text('\n'.join(s)+'\n')
PY
        cargo --config "$patch" rustc -q --release --features diag-direct-cold --bin bench-hashes -- -Clink-arg=-fuse-ld=lld "-Clink-arg=-B$lld" "-Clink-arg=-Wl,--symbol-ordering-file=$r/$group-$i.order" -Clink-arg=-Wl,--no-warn-symbol-ordering >> "$r/relink.log" 2>&1
        cp "$CARGO_TARGET_DIR/release/bench-hashes" "$r/bin/$group-$i"
    done
    echo "$group built $(date -Is)" >> "$r/status.log"
done
unset BLAKE3_DIAGNOSTIC_GPR
cd "$r"
points='64 B,256 B,1 KiB,idle 64 B,idle 256 B,idle 1 KiB,lent 64 B,lent 256 B,lent 1 KiB'
mkdir -p aa comparison
set +e
taskset -c 0,2 "$r/bin/simd-a-0" regress --contenders blake3-servil-st --points "$points" --pairs 4 --keep "$r/aa/samples" "$r"/bin/simd-a-{0..3} -- "$r"/bin/simd-b-{0..3} > aa/regress.out 2> aa/regress.err
aa=$?
set -e
echo "A/A exit=$aa $(date -Is)" >> status.log
[ "$aa" -le 2 ]
"$r/bin/simd-a-0" compare "$r"/aa/samples/run-*-old.tsv -- "$r"/aa/samples/run-*-new.tsv > aa/compare.out 2> aa/compare.err
[ "$aa" = 0 ] || { echo 'BLOCKED by A/A' >> status.log; exit 0; }
set +e
taskset -c 0,2 "$r/bin/simd-a-0" regress --contenders blake3-servil-st --points "$points" --pairs 8 --keep "$r/comparison/samples" "$r"/bin/simd-a-{0..3} -- "$r"/bin/gpr-{0..3} > comparison/regress.out 2> comparison/regress.err
code=$?
set -e
echo "comparison exit=$code $(date -Is)" >> status.log
[ "$code" -le 2 ]
"$r/bin/simd-a-0" compare "$r"/comparison/samples/run-*-old.tsv -- "$r"/comparison/samples/run-*-new.tsv > comparison/compare.out 2> comparison/compare.err
sha256sum bin/* > binaries.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 bin/* > binaries.blake3
echo "screen complete $(date -Is)" >> status.log
