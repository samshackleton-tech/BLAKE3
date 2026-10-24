#!/bin/bash
# Same direct producer/consumer on both sides. ST: CPUs 0,2 (physical,
# even cores), stream: CPUs 0,2,4,6, four participants. Eight pairs and
# four link layouts per side. Focused experiment, not a release gate.
set -euo pipefail
r=/root/results/gpr-chunk-root/direct-flow
exec > "$r/screen-runner.log" 2>&1
trap 'echo "screen exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
cd "$r"
[ -f "$r/bin/gpr-3" ]
run_screen() {
    name=$1; cpus=$2; contenders=$3; points=$4; shift 4
    set +e
    taskset -c "$cpus" "$r/bin/simd-0" regress --contenders "$contenders" --points "$points" --pairs 8 --keep "$r/$name/samples" "$@" > "$r/$name/regress.out" 2> "$r/$name/regress.err"
    code=$?
    set -e
    echo "$name exit=$code $(date -Is)" >> "$r/status.log"
    [ "$code" -le 2 ]
    "$r/bin/simd-0" compare "$r/$name"/samples/run-*-old.tsv -- "$r/$name"/samples/run-*-new.tsv > "$r/$name/compare.out" 2> "$r/$name/compare.err"
}
mkdir -p "$r/serial-batch" "$r/stream" "$r/wrappers"
run_screen serial-batch 0,2 blake3-servil-st 'lent 64 B,lent 256 B,lent 1 KiB,lent batch 16,lent batch 64,lent batch 256' "$r"/bin/simd-{0..3} -- "$r"/bin/gpr-{0..3}
for side in simd gpr; do
    for i in 0 1 2 3; do
        printf '#!/bin/sh\nexec %s --threads 4 "$@"\n' "$r/bin/$side-$i" > "$r/wrappers/$side-$i"
        chmod +x "$r/wrappers/$side-$i"
    done
done
run_screen stream 0,2,4,6 blake3-servil-mt 'continuous 64 B,continuous 256 B,continuous 1 KiB,continuous batch 64' "$r"/wrappers/simd-{0..3} -- "$r"/wrappers/gpr-{0..3}
echo "screens complete $(date -Is)" >> "$r/status.log"
