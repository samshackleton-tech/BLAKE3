#!/bin/bash
# The chunk-root fix (#141 cba5f24) under diag-line-offset 16/32/48: is it
# immune at every buffer placement within a line, and does it also avoid the
# 256 B placement penalty seen at 16/48 on the base? Map per placement.
set -u
. /root/.cargo/env
r=/root/results/smalloc/line-offset-fix
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
git -C /root/BLAKE3-chunk-root rev-parse HEAD > "$r/fix-head.txt"
fixb=/root/BLAKE3-chunk-root/bench-hashes
rm -rf "$fixb"; cp -a /root/bench-hashes-after "$fixb"; rm -rf "$fixb/target"
tar xzf /root/smalloc-src-diag2.tgz -C "$fixb"
python3 - "$fixb/Cargo.toml" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text()
a='diag-line-offset = []'
assert s.count(a)==1
p.write_text(s.replace(a,a+'\ndefault = ["diag-line-offset"]'))
PY
for off in 16 32 48; do
    exe=$(cd "$fixb" && BENCH_DIAG_LINE_OFFSET=$off cargo run -q --release -- build-against .. 2> "$r/build-$off.err") || exit 3
    cp "$exe" "$r/line$off-fix"
done
[ "$(sha256sum "$r"/line*-fix | cut -d" " -f1 | sort -u | wc -l)" = 3 ] || exit 4
status built
for off in 16 32 48; do
    python3 /root/offset_check.py --exe "$r/line$off-fix" --repeat 3 --map "$r/map-line$off-fix.tsv" --keep "$r/runs-$off" > "$r/map-$off.out" 2> "$r/map-$off.err"
    status "fix line offset $off: map exit=$?"
done
sha256sum "$r"/line*-fix > "$r/bins.sha256"
printf 'done\n' > "$r/complete"
