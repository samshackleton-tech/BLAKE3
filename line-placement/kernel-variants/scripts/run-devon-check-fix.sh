#!/bin/bash
# Devon's offset_check (4f3e033: thread stacks in 16-byte steps, rescans,
# eight-pair confirmations) on the EPYC against a clean #141 build (cba5f24
# tree bd9af8ec; bench as the base build's, no diagnostic features).
set -u
. /root/.cargo/env
r=/root/results/chunk-root/devon-check-fix
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root
[ "$(git -C "$wt" rev-parse HEAD^{tree})" = bd9af8ecf6cf927f47d639c3ad9e3b5449ae2e27 ] || exit 3
[ -z "$(git -C "$wt" status --short -- src c tools Cargo.toml build.rs)" ] || exit 3
fixb=$wt/bench-hashes
rm -rf "$fixb"; cp -a /root/bench-hashes-after "$fixb" || exit 3; rm -rf "$fixb/target"
exe=$(cd "$fixb" && cargo run -q --release -- build-against .. 2> "$r/build.err") || exit 3
cp "$exe" "$r/fix-clean"
strings "$r/fix-clean" | grep -c 'global allocator' > "$r/diag-strings.txt"
status "built; diagnostic strings: $(cat "$r/diag-strings.txt")"
d=/root/BLAKE3-devon-offset-check
for n in 1 2 3; do
    ( cd "$d" && timeout 900 python3 tools/offset_check.py --exe "$r/fix-clean" --keep "$r/devon-fix-$n" ) > "$r/devon-fix-$n.out" 2> "$r/devon-fix-$n.err"
    status "devon offset_check on #141 build, run $n: exit=$?"
done
printf 'done\n' > "$r/complete"
