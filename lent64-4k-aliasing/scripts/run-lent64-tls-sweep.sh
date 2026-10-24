#!/bin/bash
# Causal test of the 4 KiB-aliasing hypothesis with NO code change: shift the
# duo-copy threads' stacks in 16-byte steps via glibc's static-TLS surplus
# tunable, in the SAME binaries. For each step: (a) bpftrace records the
# duo threads' hash_serial_from return-slot (stack) and input (heap) offsets
# mod 4096; (b) a separate untraced process measures the cell (the bench's own
# printed report). Then one paired regress confirms the predicted toggle.
set -u
r=/root/results/avx512-registers/lent64-tls-sweep
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
b=/root/BLAKE3-stream-wake-guarded/target/check
ldd --version | head -1 > "$r/glibc.txt"
for spec in old:0 new:4; do
    side=${spec%%:*}; i=${spec#*:}; exe=$b/$side/bench-hashes-$i
    sym=$(nm "$exe" | python3 -c 'import sys; m=[l.split()[2] for l in sys.stdin if l.split()[-1].endswith("13blake3_servil16hash_serial_from")]; assert len(m)==1, m; print(m[0])')
    for surplus in 448 464 480 496 512 528 544 560 576; do
        out="$r/$side/tls-$surplus"; mkdir -p "$out"
        printf '#!/bin/sh\ncd %s\nexport GLIBC_TUNABLES=glibc.rtld.optional_static_tls=%s\nexec %s --threads 48 --contenders blake3-servil-st,blake3-servil-mt --points "lent 64 B" --for-regression-check --rounds 24\n' "$out" "$surplus" "$exe" > "$out/run.sh"
        bpftrace -q -e "uprobe:$exe:$sym /comm == \"duo-copy-0\" || comm == \"duo-copy-1\"/ { @[comm, reg(\"di\") & 4095, reg(\"dx\") & 4095] = count(); }" -c "/bin/sh $out/run.sh" > "$out/probe.txt" 2> "$out/probe.err"
        rm -rf "$out/benchmark-results"
        /bin/sh "$out/run.sh" > "$out/time.out" 2> "$out/time.err"
        status "$side surplus=$surplus done"
    done
done
printf 'done\n' > "$r/complete"
