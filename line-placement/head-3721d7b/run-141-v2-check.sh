#!/bin/bash
# #141 v2 head candidate 3721d7b (ad29ede + picking kernel + cold partial
# path): tests, a build-against bench, stack realignment in the hash path
# against the old head's build, one offset_check run. Short (< 10 min).
set -u
. /root/.cargo/env
r=/root/results/chunk-root/v2-check
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root-v2
rm -rf "$wt"; git -C /root/BLAKE3 worktree prune
git -C /root/BLAKE3 fetch -q -f /root/v2.bundle +candidate/sam-x86-chunk-root-v2:candidate/sam-x86-chunk-root-v2 || exit 3
git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-x86-chunk-root-v2 || exit 3
[ "$(git -C "$wt" rev-parse HEAD)" = 3721d7b7ac80dc467c62bfeb90da03aec12214c2 ] || exit 3
cd "$wt"
python3 tools/gen_x86_chunk_root.py | cmp - c/blake3_chunk_root_x86-64_unix.S; status "generated matches: $?"
( timeout 600 cargo nextest run --release --lib -E 'test(chunk_root)' ) > "$r/focused.log" 2>&1; status "focused exit=$?"
( timeout 600 cargo nextest run --release --lib --tests --no-fail-fast ) > "$r/release.log" 2>&1; status "release exit=$?"
grep -hE "Summary" "$r/focused.log" "$r/release.log" >> "$r/status.log"
b="$wt/bench-hashes"; rm -rf "$b"; cp -a /root/bench-hashes-after "$b" || exit 3; rm -rf "$b/target"
exe=$(cd "$b" && cargo run -q --release -- build-against .. 2> "$r/build.err") || exit 3
cp "$exe" "$r/v2-exe"
for side in old:/root/results/chunk-root/devon-check-fix/fix-clean new:$r/v2-exe; do
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
cat "$r/realign-old.txt" "$r/realign-new.txt" >> "$r/status.log"
( timeout 600 python3 tools/offset_check.py --exe "$r/v2-exe" --keep "$r/offset" ) > "$r/offset.out" 2> "$r/offset.err"
status "offset_check exit=$?"
grep -E "^offset-sensitive|^FAIL|^ok" "$r/offset.out" >> "$r/status.log"
printf 'done\n' > "$r/complete"
