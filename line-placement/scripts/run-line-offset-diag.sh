#!/bin/bash
# Converse of the align64 diagnostic: glibc with every >=64-byte allocation
# placed 16, 32 or 48 bytes into a cache line (feature diag-line-offset), base
# servil b94e2fa (no fix). If the windows come back at 16/32/48 and were absent
# at 0 (align64), a line-crossing buffer is the precondition. Address probe +
# offset map per placement.
set -u
. /root/.cargo/env
r=/root/results/smalloc/line-offset
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
d=/root/bench-line-offset
rm -rf "$d"; cp -a /root/bench-hashes-after "$d"; rm -rf "$d/target"
tar xzf /root/smalloc-src-diag2.tgz -C "$d"
for off in 16 32 48; do
    ( cd "$d" && BENCH_DIAG_LINE_OFFSET=$off cargo build -q --release --features diag-line-offset ) > "$r/build-$off.log" 2>&1 || exit 3
    cp "$d/target/release/bench-hashes" "$r/line$off-base"
done
status 'built'
for off in 16 32 48; do
    exe=$r/line$off-base
    sym=$(nm "$exe" | python3 -c 'import sys; m=[l.split()[2] for l in sys.stdin if l.split()[-1].endswith("13blake3_servil11hash_serial")]; assert len(m)==1, m; print(m[0])')
    out="$r/addr-$off"; mkdir -p "$out"
    printf '#!/bin/sh\ncd %s\nexec setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root %s --contenders blake3-servil-st --points "lent 64 B,lent 256 B" --for-regression-check --rounds 24 > %s/run.out 2> %s/run.err\n' "$out" "$exe" "$out" "$out" > "$out/run.sh"
    bpftrace -q -e "uprobe:$exe:$sym /pid == tid/ { @[reg(\"dx\"), reg(\"si\") & 4095] = count(); }" -c "/bin/sh $out/run.sh" > "$out/probe.txt" 2> "$out/probe.err"
    python3 /root/offset_check.py --exe "$exe" --repeat 3 --map "$r/map-line$off-base.tsv" --keep "$r/runs-$off" > "$r/map-$off.out" 2> "$r/map-$off.err"
    status "line offset $off: map exit=$?"
done
printf 'done\n' > "$r/complete"
