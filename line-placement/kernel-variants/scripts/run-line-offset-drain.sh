#!/bin/bash
# Is #141's 64 B placement cost the bench's just-made write? An mfence after
# each prepared write (feature diag-drain, inside the timed preparation,
# equal at every placement), base and fix, buffers 16 and 32 bytes into a
# line. If the fix's 16-vs-32 gap closes with the fence, the stores in flight
# are the cause. Solo + shared lent 64 B via offset maps (default offset
# each, --map). Waits for the retrospective.
set -u
. /root/.cargo/env
r=/root/results/smalloc/line-offset-drain
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
while pgrep -f '^bash /root/run-retro-align64.sh' > /dev/null; do sleep 30; done
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
for side in base fix; do
    if [ "$side" = base ]; then d=/root/bench-drain-base; else d=/root/BLAKE3-chunk-root/bench-hashes; fi
    for off in 16 32; do
        rm -rf "$d"; cp -a /root/bench-hashes-after "$d" || exit 3; rm -rf "$d/target"
        tar xzf /root/smalloc-src-diag3.tgz -C "$d" || exit 3
        python3 - "$d/Cargo.toml" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text(); a='diag-drain = []'
assert s.count(a)==1
p.write_text(s.replace(a,a+'\ndefault = ["diag-line-offset", "diag-drain"]'))
PY
        if [ "$side" = base ]; then
            ( cd "$d" && BENCH_DIAG_LINE_OFFSET=$off cargo build -q --release ) > "$r/build-$side-$off.log" 2>&1 || exit 3
            cp "$d/target/release/bench-hashes" "$r/line$off-$side-drain"
        else
            exe=$(cd "$d" && BENCH_DIAG_LINE_OFFSET=$off cargo run -q --release -- build-against .. 2> "$r/build-$side-$off.log") || exit 3
            cp "$exe" "$r/line$off-$side-drain"
        fi
    done
done
[ "$(sha256sum "$r"/line*-drain | cut -d" " -f1 | sort -u | wc -l)" = 4 ] || exit 4
sha256sum "$r"/line*-drain > "$r/bins.sha256"
status built
for b in line16-base line32-base line16-fix line32-fix; do
    python3 /root/offset_check.py --exe "$r/$b-drain" --repeat 3 --map "$r/map-$b-drain.tsv" --keep "$r/runs-$b" > "$r/map-$b.out" 2> "$r/map-$b.err"
    status "$b drain: map exit=$?"
done
status complete
printf 'done\n' > "$r/complete"
