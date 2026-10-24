#!/bin/bash
# Allocation attribution only: uprobes perturb timing, so none of these
# runs is speed evidence. Count 32-byte calloc calls in the benchmark PID,
# beside chunk-root entries; compare Devon's original per-invocation Box
# with the persistent per-thread Box. Same single lent64 test selection.
set -euo pipefail
r=/root/results/gpr-chunk-root/kept-output/allocation-probe
mkdir -p "$r"
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
libc=/usr/lib/x86_64-linux-gnu/libc.so.6
[ -e "$libc" ]
for name in original fixed; do
    if [ "$name" = original ]; then
        exe=/root/results/gpr-chunk-root/devon-output-integration/simd
    else
        exe=/root/results/gpr-chunk-root/kept-output/bin/simd-0
    fi
    # Rust's typed symbol is visible to bpftrace; the aliased assembly
    # entry is not consistently resolved by its symbol reader.
    sym=$(nm "$exe" | python3 -c 'import sys; s=[l.split()[-1] for l in sys.stdin if l.split()[-1].endswith("13blake3_servil11hash_serial")]; assert len(s)==1,s; print(s[0])')
    o="$r/$name"; mkdir -p "$o"
    printf '#!/bin/sh\ncd %s\nexec %s --contenders blake3-servil-st --points "lent 64 B" --for-regression-check --rounds 2 >run.out 2>run.err\n' "$o" "$exe" > "$o/run.sh"
    timeout 90 bpftrace -q -e "uprobe:$libc:calloc /pid == cpid && arg0 * arg1 == 32/ { @calloc32 = count(); @allocation_stacks[ustack(5)] = count(); } uprobe:$exe:$sym /pid == cpid/ { @hash_calls = count(); }" -c "/bin/sh $o/run.sh" > "$o/counts.txt" 2> "$o/probe.err"
done
