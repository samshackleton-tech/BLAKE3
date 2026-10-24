#!/bin/bash
# Experiment candidate/sam-x86-chunk-root-ymm 5c8fdb5 (on #141 cba5f24): the
# AVX-512 chunk-root entry loads each block in two 32-byte loads. Focused and
# release tests, then offset maps with the caller's buffer 0 (align64), 16,
# 32 and 48 bytes into a line, beside the earlier cba5f24 maps.
set -u
. /root/.cargo/env
r=/root/results/chunk-root/ymm
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root-ymm
if [ ! -d "$wt" ]; then
    git -C /root/BLAKE3 fetch -q /root/ymm.bundle candidate/sam-x86-chunk-root-ymm:candidate/sam-x86-chunk-root-ymm || exit 3
    git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-x86-chunk-root-ymm || exit 3
fi
cd "$wt" || exit 3
[ "$(git rev-parse HEAD)" = 5c8fdb5057f9aa99cf32091124b7567e8be7d2af ] || exit 3
git rev-parse HEAD > "$r/head.txt"; git status --short > "$r/source-status.txt"
python3 tools/gen_x86_chunk_root.py | cmp - c/blake3_chunk_root_x86-64_unix.S > "$r/generated-cmp.txt" 2>&1; status "generated matches: $?"
run() { name=$1; shift; status "$name"; timeout --signal=TERM --kill-after=10 900 "$@" > "$r/$name.log" 2>&1; code=$?; printf '%s\n' "$code" > "$r/$name-exit"; status "$name exit=$code"; }
run focused cargo nextest run --release --lib -E 'test(chunk_root)' --success-output immediate --no-fail-fast
run release cargo nextest run --release --lib --tests --no-fail-fast
fixb=$wt/bench-hashes
for off in 0 16 32 48; do
    rm -rf "$fixb"; cp -a /root/bench-hashes-after "$fixb"; rm -rf "$fixb/target"
    tar xzf /root/smalloc-src-diag2.tgz -C "$fixb"
    feat=diag-line-offset; [ "$off" = 0 ] && feat=diag-align64
    python3 - "$fixb/Cargo.toml" "$feat" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text(); a=f'{sys.argv[2]} = []'
assert s.count(a)==1
p.write_text(s.replace(a,a+f'\ndefault = ["{sys.argv[2]}"]'))
PY
    exe=$(cd "$fixb" && BENCH_DIAG_LINE_OFFSET=$off cargo run -q --release -- build-against .. 2> "$r/build-$off.err") || exit 3
    cp "$exe" "$r/line$off-ymm"
done
[ "$(sha256sum "$r"/line*-ymm | cut -d" " -f1 | sort -u | wc -l)" = 4 ] || exit 4
status built
for off in 0 16 32 48; do
    python3 /root/offset_check.py --exe "$r/line$off-ymm" --repeat 3 --map "$r/map-line$off-ymm.tsv" --keep "$r/runs-$off" > "$r/map-$off.out" 2> "$r/map-$off.err"
    status "ymm line offset $off: map exit=$?"
done
status complete
printf 'done\n' > "$r/complete"
