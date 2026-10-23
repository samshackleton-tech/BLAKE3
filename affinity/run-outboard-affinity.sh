#!/bin/bash
# Fixed host topology; existing benchmarks/layouts only. No new timing loop.
set -u
. /root/.cargo/env
r=/root/results/avx512-registers/outboard-affinity
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
status 'waiting for parent-routing full comparisons'
if kill -0 2969647 2>/dev/null; then tail --pid=2969647 -f /dev/null; fi
test -f /root/results/avx512-registers/parent-legacy/complete || exit 3
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf)$'; then exit 3; fi
lscpu -p=CPU,CORE,SOCKET,NODE > "$r/topology.csv"
for ((cpu=0;cpu<24;cpu++)); do
    read -r siblings < "/sys/devices/system/cpu/cpu$cpu/topology/thread_siblings_list"
    [ "$siblings" = "$cpu,$((cpu+24))" ] || exit 3
    read -r llc < "/sys/devices/system/cpu/cpu$cpu/cache/index3/shared_cpu_list"
    printf '%s %s %s\n' "$cpu" "$siblings" "$llc" >> "$r/cache-and-siblings.txt"
done
control=/root/BLAKE3-avx32/bench-hashes/target/release/bench-hashes
wide=/root/BLAKE3-avx512-parent16-startup/target/check
narrow=/root/BLAKE3-pooled-groups-narrow/target/check
[ "$(git -C "$wide/new/src" rev-parse HEAD^{tree})" = db1cf79a8a9d4f771c7a963bbf35cef33cf4cd2a ] || exit 3
[ "$(git -C "$narrow/new/src" rev-parse HEAD)" = 215441f3f1c327e00869538eeced3ad90ec46dea ] || exit 3
for dir in "$wide" "$narrow"; do
    [ "$(git -C "$dir/old/src" rev-parse HEAD)" = 8e968d5599b3ae577f5234f1e8e5e10cfb72b9e4 ] || exit 3
    printf '%s %s\n' "$dir" "$(git -C "$dir/new/src" rev-parse HEAD)" >> "$r/sources.txt"
done
# Half-core selection is interleaved over primary CPU IDs, rather than
# taking only the first CCDs. Cache topology is retained for interpretation.
for config in half-one half-two full-one full-two; do
    case "$config" in
        half-one) cpus=$(seq -s, 0 2 22); threads=12;;
        half-two) cpus=$(seq -s, 0 2 46); threads=24;;
        full-one) cpus=0-23; threads=24;;
        full-two) cpus=0-47; threads=48;;
    esac
    for variant in wide narrow; do
        builds=$wide; [ "$variant" != narrow ] || builds=$narrow
        d="$r/$config-$variant"
        mkdir -p "$d/bin"
        printf 'cpus=%s\nthreads=%s\n' "$cpus" "$threads" > "$d/config.txt"
        old=(); new=()
        for side in old new; do
            for ((i=0;i<16;i++)); do
                layout=$i; [ "$side" != new ] || layout=$((i+16))
                exe="$builds/$side/bench-hashes-$layout"
                test -x "$exe" || exit 3
                wrapper="$d/bin/$side-$i"
                printf '#!/bin/bash\nexec taskset -c "%s" "%s" --threads %s "$@"\n' "$cpus" "$exe" "$threads" > "$wrapper"
                chmod +x "$wrapper"
                if [ "$side" = old ]; then old+=("$wrapper"); else new+=("$wrapper"); fi
            done
        done
        status "$config $variant: CPUs=$cpus, threads=$threads, sixteen pairs, both outboard sizes"
        "$control" regress --contenders blake3-servil-mt --points 'outboard 1 MiB,outboard 64 MiB' --pairs 16 --keep "$d/samples" "${old[@]}" -- "${new[@]}" > "$d/check.out" 2> "$d/check.err"
        code=$?; printf '%s\n' "$code" > "$d/exit-code"; status "$config/$variant exit=$code"
        [ "$code" -le 2 ] || exit "$code"
        "$control" compare "$d"/samples/run-*-old.tsv -- "$d"/samples/run-*-new.tsv > "$d/compare.out" 2> "$d/compare.err"
    done
done
status 'affinity diagnostic complete; this neither replaces full-cell checks nor another CPU'
printf 'done\n' > "$r/complete"
