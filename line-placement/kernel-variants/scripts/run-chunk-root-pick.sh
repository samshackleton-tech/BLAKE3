#!/bin/bash
# Experiment candidate/sam-x86-chunk-root-pick 6f9d962 (on #141 cba5f24): at 16/48
# into a line one 64-byte load; else 4x16 B.
# release tests, then offset maps with the caller's buffer 0 (align64), 16,
# 32 and 48 bytes into a line, beside the earlier cba5f24 maps.
set -u
. /root/.cargo/env
r=/root/results/chunk-root/pick
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root-pick
if [ ! -d "$wt" ]; then
    git -C /root/BLAKE3 fetch -q /root/pick.bundle candidate/sam-x86-chunk-root-pick:candidate/sam-x86-chunk-root-pick || exit 3
    git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-x86-chunk-root-pick || exit 3
fi
cd "$wt" || exit 3
[ "$(git rev-parse HEAD)" = 6f9d9620d0886b1a99a031cb4031aa2f61cf6016 ] || exit 3
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
    cp "$exe" "$r/line$off-pick"
done
[ "$(sha256sum "$r"/line*-pick | cut -d" " -f1 | sort -u | wc -l)" = 4 ] || exit 4
status built
for off in 0 16 32 48; do
    python3 /root/offset_check.py --exe "$r/line$off-pick" --repeat 3 --map "$r/map-line$off-pick.tsv" --keep "$r/runs-$off" > "$r/map-$off.out" 2> "$r/map-$off.err"
    status "pick line offset $off: map exit=$?"
done
status 'pick maps complete'
# Devon's offset_check (devonjonte/BLAKE3 candidate/devon-offset-check 4f3e033) on the EPYC.
d=/root/BLAKE3-devon-offset-check
if [ ! -d "$d" ]; then
    git -C /root/BLAKE3 fetch -q https://github.com/devonjonte/BLAKE3.git candidate/devon-offset-check || exit 3
    git -C /root/BLAKE3 worktree add -q --detach "$d" FETCH_HEAD || exit 3
fi
git -C "$d" rev-parse HEAD > "$r/devon-head.txt"
case "$(cat "$r/devon-head.txt")" in 4f3e033*) ;; *) status "devon head is $(cat "$r/devon-head.txt"), not 4f3e033"; exit 3;; esac
rm -rf "$fixb"; cp -a /root/bench-hashes-after "$fixb" || exit 3; rm -rf "$fixb/target"
plain=$(cd "$fixb" && cargo run -q --release -- build-against .. 2> "$r/build-plain.err") || exit 3
cp "$plain" "$r/plain-pick"
for n in 1 2; do
    ( cd "$d" && timeout 900 python3 tools/offset_check.py --exe "$r/plain-pick" --keep "$r/devon-pick-$n" ) > "$r/devon-pick-$n.out" 2> "$r/devon-pick-$n.err"
    status "devon offset_check on the pick variant (default glibc), run $n: exit=$?"
done
status complete
printf 'done\n' > "$r/complete"
