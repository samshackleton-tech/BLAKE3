#!/bin/bash
# Diagnostic: is cache-line placement the key? glibc with allocations of 64
# bytes or more aligned to 64 (feature diag-align64), servil b94e2fa (no fix).
# If #65's windows and the solo heap-layout states vanish, a line-crossing
# buffer is a precondition. Map + address probe. Waits for the speed job.
set -u
. /root/.cargo/env
r=/root/results/smalloc/align64
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
while pgrep -f '^bash /root/run-smalloc-speed.sh' > /dev/null; do sleep 20; done
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
d=/root/bench-align64
rm -rf "$d"; cp -a /root/bench-hashes-after "$d"; rm -rf "$d/target"
tar xzf /root/smalloc-src.tgz -C "$d"
( cd "$d" && cargo build -q --release --features diag-align64 ) > "$r/build.log" 2>&1 || exit 3
exe=$d/target/release/bench-hashes
cp "$exe" "$r/align64-base"
sym=$(nm "$exe" | python3 -c 'import sys; m=[l.split()[2] for l in sys.stdin if l.split()[-1].endswith("13blake3_servil11hash_serial")]; assert len(m)==1, m; print(m[0])')
out="$r/addr"; mkdir -p "$out"
printf '#!/bin/sh\ncd %s\nexec setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root %s --contenders blake3-servil-st --points "lent 64 B,lent 256 B" --for-regression-check --rounds 24 > %s/run.out 2> %s/run.err\n' "$out" "$exe" "$out" "$out" > "$out/run.sh"
bpftrace -q -e "uprobe:$exe:$sym /pid == tid/ { @[reg(\"dx\"), reg(\"si\") & 4095] = count(); }" -c "/bin/sh $out/run.sh" > "$out/probe.txt" 2> "$out/probe.err"
status 'address probe done'
python3 /root/offset_check.py --exe "$r/align64-base" --repeat 3 --map "$r/map-align64-base.tsv" --keep "$r/runs" > "$r/map.out" 2> "$r/map.err"
status "map exit=$?"
printf 'done\n' > "$r/complete"
