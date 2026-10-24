#!/bin/bash
# (C, rerun) glibc (old) against smalloc (new): the default contenders named
# (servil st/mt, sha256, ring), every cell they run, 8 pairs, the 8 relinked
# layouts per side already built. Waits for the align64 diagnostic.
set -u
r=/root/results/smalloc/speed
while pgrep -f '^bash /root/run-align64-diag.sh' > /dev/null; do sleep 20; done
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
rm -rf "$r/samples"
echo "$(date -Is) regress begins" >> "$r/status.log"
"$r/bin/glibc-0" regress --contenders blake3-servil-st,blake3-servil-mt,sha256,sha256-ring --pairs 8 --keep "$r/samples" "$r"/bin/glibc-{0..7} -- "$r"/bin/smalloc-{0..7} > "$r/regress.out" 2> "$r/regress.err"
echo "$(date -Is) regress exit=$?" >> "$r/status.log"
"$r/bin/glibc-0" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
echo "$(date -Is) complete" >> "$r/status.log"
printf 'done\n' > "$r/complete-regress"
