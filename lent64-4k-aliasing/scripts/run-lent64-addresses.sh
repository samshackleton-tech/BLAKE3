#!/bin/bash
# Record hash_serial_from's argument registers per thread during the focused
# shared LentMessages 64 B cell, old vs guarded build (one layout each).
# Diagnostic: uprobes perturb timing; only addresses/alignments are evidence.
set -u
r=/root/results/avx512-registers/lent64-addresses
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
b=/root/BLAKE3-stream-wake-guarded/target/check
sym=_RNvCs4zqYRKFMwRg_13blake3_servil16hash_serial_from
for spec in old:0 new:4; do
    side=${spec%%:*}; i=${spec#*:}; exe=$b/$side/bench-hashes-$i
    sym=$(nm "$exe" | python3 -c 'import sys; m=[l.split()[2] for l in sys.stdin if l.split()[-1].endswith("13blake3_servil16hash_serial_from")]; assert len(m)==1, m; print(m[0])')
    echo "$side symbol=$sym" >> "$r/status.log"
    out="$r/$side"; mkdir -p "$out"
    # Direct run of the same point the regression check visits (one process).
    printf '#!/bin/sh\ncd %s\nexec %s --threads 48 --contenders blake3-servil-st,blake3-servil-mt --points "lent 64 B" --for-regression-check --rounds 24\n' "$out" "$exe" > "$out/run.sh"
    chmod +x "$out/run.sh"
    bpftrace -q -e "uprobe:$exe:$sym { @[comm, reg(\"si\") & 4095, reg(\"dx\"), reg(\"di\") & 4095, reg(\"cx\") & 4095] = count(); }" \
        -c "/bin/sh $out/run.sh" \
        > "$out/probe.txt" 2> "$out/probe.err"
    echo "$side exit=$?" >> "$r/status.log"
done
printf 'done\n' > "$r/complete"
