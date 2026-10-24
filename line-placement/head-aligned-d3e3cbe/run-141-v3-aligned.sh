#!/bin/bash
# #141 v3 76a0781 (plain kernel, cold partial path, no picking branch) with
# the caller's buffers 64-byte aligned (bench main 4b65e6e's diag-align64):
# tests, a map, and the PR's offset_check at that build. Short (< 10 min).
set -u
. /root/.cargo/env
r=/root/results/chunk-root/v3-aligned
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root-v3
rm -rf "$wt"; git -C /root/BLAKE3 worktree prune
git -C /root/BLAKE3 fetch -q -f /root/v3.bundle +candidate/sam-x86-chunk-root-v3:candidate/sam-x86-chunk-root-v3 || exit 3
git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-x86-chunk-root-v3 || exit 3
[ "$(git -C "$wt" rev-parse HEAD)" = 76a07812c9ea331d95c3f04b1b949ddc979d4065 ] || exit 3
cd "$wt"
python3 tools/gen_x86_chunk_root.py | cmp - c/blake3_chunk_root_x86-64_unix.S; status "generated matches: $?"
( timeout 600 cargo nextest run --release --lib -E 'test(chunk_root)' ) > "$r/focused.log" 2>&1; status "focused exit=$?"
( timeout 600 cargo nextest run --release --lib --tests --no-fail-fast ) > "$r/release.log" 2>&1; status "release exit=$?"
grep -hE "Summary" "$r/focused.log" "$r/release.log" >> "$r/status.log"
b="$wt/bench-hashes"; rm -rf "$b"
git clone -q -b candidate/sam-diag-placement /root/bench-placement.bundle "$b" || exit 3
python3 - "$b/Cargo.toml" <<'PY' || exit 3
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text(); a = 'diag-align64 = []'
assert s.count(a) == 1
p.write_text(s.replace(a, a + '\ndefault = ["diag-align64"]'))
PY
exe=$(cd "$b" && cargo run -q --release -- build-against .. 2> "$r/build.err") || exit 3
cp "$exe" "$r/v3-align64"
python3 /root/offset_check.py --exe "$r/v3-align64" --repeat 3 --map "$r/map-v3-align64.tsv" --keep "$r/map-runs" > "$r/map.out" 2> "$r/map.err"
status "map exit=$?"
( timeout 600 python3 tools/offset_check.py --exe "$r/v3-align64" --keep "$r/offset" ) > "$r/offset.out" 2> "$r/offset.err"
status "offset_check exit=$?"
grep -E "^offset-sensitive|^FAIL|^ok" "$r/offset.out" >> "$r/status.log"
printf 'done\n' > "$r/complete"
