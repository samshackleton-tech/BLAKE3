#!/bin/bash
# stream ring at a 64-byte boundary (candidate/sam-stream-ring-align64
# 9d827eb on servil f6bd06d): the new test, the release suite, and a
# negative control (the same test against the unaligned ring must fail).
set -u
. /root/.cargo/env
r=/root/results/ring-align
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-ring
rm -rf "$wt"; git -C /root/BLAKE3 worktree prune
git -C /root/BLAKE3 fetch -q -f /root/ring.bundle +candidate/sam-stream-ring-align64:candidate/sam-stream-ring-align64 || exit 3
git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-stream-ring-align64 || exit 3
[ "$(git -C "$wt" rev-parse HEAD)" = 9d827eb4b9b22be5e5704ecf63286426329578ba ] || exit 3
cd "$wt"
( timeout 600 cargo nextest run --release --lib -E 'test(test_stream_rooms_are_64_byte_aligned)' ) > "$r/new-test.log" 2>&1; status "new test exit=$?"
( timeout 900 cargo nextest run --release --lib --tests --no-fail-fast ) > "$r/release.log" 2>&1; status "release exit=$?"
grep -hE "Summary" "$r/new-test.log" "$r/release.log" >> "$r/status.log"
# Negative control: the ring as before (no skip).
python3 - src/stream.rs <<'PY' || exit 3
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
a = "    unsafe { raw.add(skip) }\n"
assert s.count(a) == 1
p.write_text(s.replace(a, "    let _ = skip;\n    raw\n"))
PY
( timeout 600 cargo nextest run --release --lib -E 'test(test_stream_rooms_are_64_byte_aligned)' ) > "$r/control.log" 2>&1; status "control exit=$? (must fail)"
grep -m1 -E "misalignment" "$r/control.log" | cut -c1-200 >> "$r/status.log"
git checkout -q -- src/stream.rs
printf 'done\n' > "$r/complete"
