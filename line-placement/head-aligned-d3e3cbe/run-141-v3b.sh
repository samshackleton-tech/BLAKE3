#!/bin/bash
# #141 v3 4d2d4e4 (plain kernel, cold partial path, tree out of line) with
# the caller's buffers 64-byte aligned (bench main 4b65e6e's diag-align64):
# tests, a map, and the PR's offset_check at that build. Short (< 10 min).
set -u
. /root/.cargo/env
r=/root/results/chunk-root/v3c-aligned
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root-v3
rm -rf "$wt"; git -C /root/BLAKE3 worktree prune
git -C /root/BLAKE3 fetch -q -f /root/v3b.bundle +candidate/sam-x86-chunk-root-v3:candidate/sam-x86-chunk-root-v3 || exit 3
git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-x86-chunk-root-v3 || exit 3
[ "$(git -C "$wt" rev-parse HEAD)" = 1504f2ef92f49c197477c5a2afb9aabac439fd80 ] || exit 3
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
for side in v3b:/root/results/chunk-root/v3b-aligned/v3-align64 v3c:$r/v3-align64; do
    name=${side%%:*}; e=${side#*:}
    python3 - "$e" <<'PY' > "$r/realign-$name.txt"
import re, subprocess, sys
exe = sys.argv[1]
syms = subprocess.run(['nm', '-C', '-S', exe], capture_output=True, text=True).stdout.splitlines()
want = [l.split(' ', 3) for l in syms if re.search(r' blake3_servil::(hash|hash_serial|hash_serial_on|hash_serial_from)$', l)]
if not want:
    print('no such symbols')
for addr, size, kind, name in want:
    start, stop = int(addr, 16), int(addr, 16) + int(size, 16)
    out = subprocess.run(['objdump', '-d', '--no-show-raw-insn', f'--start-address={start}', f'--stop-address={stop}', exe], capture_output=True, text=True).stdout
    lines = [l for l in out.splitlines() if re.match(r'\s+[0-9a-f]+:', l)]
    realign = [l.strip() for l in lines if re.search(r'and\s+\$0xffffffffffffffc0,%rsp', l)]
    pushes = sum(1 for l in lines if re.search(r'\spush\s', l))
    print(f'{name}: {len(lines)} instructions, pushes {pushes}, realignments {len(realign)}')
PY
done
cat "$r"/realign-*.txt >> "$r/status.log"
python3 /root/offset_check.py --exe "$r/v3-align64" --repeat 3 --map "$r/map-v3-align64.tsv" --keep "$r/map-runs" > "$r/map.out" 2> "$r/map.err"
status "map exit=$?"
printf 'done\n' > "$r/complete"
