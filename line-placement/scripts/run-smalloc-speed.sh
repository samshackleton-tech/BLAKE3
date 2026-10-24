#!/bin/bash
# (C) Speed: the same bench and servil (b94e2fa) under glibc's allocator
# against smalloc, every cell, 8 pairs, each pair a fresh link layout on each
# side (lld --symbol-ordering-file, seeded per side and layout, as
# tools/b3sum-contenders.py relinks). Waits for the layout experiment.
set -u
. /root/.cargo/env
r=/root/results/smalloc/speed
rm -rf "$r"; mkdir -p "$r/bin"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if kill -0 2382942 2>/dev/null; then tail --pid=2382942 -f /dev/null; fi
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
b=/root/bench-smalloc
lld=$(ls /usr/bin/ld.lld-* | sort -V | tail -1); mkdir -p "$r/lld"; ln -sf "$lld" "$r/lld/ld.lld"
nm "$b/target/release/bench-hashes" | python3 -c 'import sys; print("\n".join(sorted({f[2] for f in (l.split() for l in sys.stdin) if len(f)==3 and f[1] in "tT"})))' > "$r/symbols.txt"
for side in glibc smalloc; do
    feat=""; [ "$side" = smalloc ] && feat="--features smalloc"
    for i in 0 1 2 3 4 5 6 7; do
        python3 - "$r/symbols.txt" "$r/order-$side-$i" "$side-$i" <<'PY'
import random,sys,zlib
s=open(sys.argv[1]).read().split()
random.Random(zlib.crc32(sys.argv[3].encode())).shuffle(s)
open(sys.argv[2],'w').write('\n'.join(s)+'\n')
PY
        ( cd "$b" && CARGO_TARGET_DIR="$r/target-$side" cargo rustc -q --release $feat --bin bench-hashes -- \
            -Clink-arg=-fuse-ld=lld "-Clink-arg=-B$r/lld" "-Clink-arg=-Wl,--symbol-ordering-file=$r/order-$side-$i" -Clink-arg=-Wl,--no-warn-symbol-ordering ) >> "$r/build.log" 2>&1 || exit 3
        cp "$r/target-$side/release/bench-hashes" "$r/bin/$side-$i"
    done
    status "$side: 8 layouts built"
done
sha256sum "$r"/bin/* > "$r/bin.sha256"
status 'regress all cells, 8 pairs: glibc (old) against smalloc (new)'
"$r/bin/glibc-0" regress --full --pairs 8 --keep "$r/samples" "$r"/bin/glibc-{0..7} -- "$r"/bin/smalloc-{0..7} > "$r/regress.out" 2> "$r/regress.err"
status "regress exit=$?"
"$r/bin/glibc-0" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
status complete
printf 'done\n' > "$r/complete"
