#!/bin/bash
# Which zeroed allocations do the MT cells that slow down under smalloc make,
# and how big? uprobe counts (diagnostic; perturbs timing) on the glibc-side
# and smalloc-side benches (layout 0), plus perf cycles share by symbol.
set -u
r=/root/results/smalloc/zeroed
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
bin=/root/results/smalloc/speed/bin
for side in glibc smalloc; do
    exe=$bin/$side-0; out="$r/$side"; mkdir -p "$out"
    z=$(nm "$exe" | python3 -c 'import sys; m=[l.split()[2] for l in sys.stdin if l.split()[-1:]==["__rustc::__rust_alloc_zeroed"] or l.split()[-1].endswith("___rust_alloc_zeroed")]; print(m[0] if m else "")')
    [ -n "$z" ] || z=$(nm "$exe" | grep -E 'rust_alloc_zeroed$' | head -1 | awk '{print $3}')
    echo "$z" > "$out/symbol.txt"
    for point in 'continuous 4 MiB' 'outboard 1 MiB' 'lent 1 MiB'; do
        tag=$(echo "$point" | tr ' ' '-')
        printf '#!/bin/sh\ncd %s\nexec %s --contenders blake3-servil-mt --points "%s" --for-regression-check --rounds 24 > %s/%s.out 2>&1\n' "$out" "$exe" "$point" "$out" "$tag" > "$out/$tag.sh"
        bpftrace -q -e "uprobe:$exe:$z { @zeroed_bytes = hist(arg0); @calls = count(); }" -c "/bin/sh $out/$tag.sh" > "$out/$tag-zeroed.txt" 2>&1
    done
    ( cd "$out" && perf record -q -e cpu/cycles,period=100003/u -o "$out/perf.data" -- "$exe" --contenders blake3-servil-mt --points 'continuous 4 MiB,outboard 1 MiB,lent 1 MiB' --for-regression-check --rounds 24 ) > /dev/null 2>&1
    perf report --stdio -i "$out/perf.data" --no-children --sort sym --percent-limit 0.5 > "$out/cycles.txt" 2> /dev/null
    rm -f "$out/perf.data"
done
printf 'done\n' > "$r/complete"
