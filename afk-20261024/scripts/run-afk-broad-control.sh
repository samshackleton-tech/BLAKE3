#!/bin/bash
# First-stage standard-budget check: four fresh processes/layouts per side,
# the full ST/MT cell family, identical plant-capable code, activation 0/1.
# Reuses already-built independent layouts. Diagnose the result; do not
# pretend that passing a narrow 12-cell control establishes this larger one.
set -euo pipefail
r=/root/results/afk-20261024-broad-control
mkdir -p "$r/wrappers" "$r/run"
exec > "$r/runner.log" 2>&1
trap 'echo "exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
base=/root/results/afk-20261024-runtime-control
for side in old new; do
    if [ "$side" = old ]; then group=control-a; active=0; else group=control-b; active=1; fi
    for i in 0 1 2 3; do
        printf '#!/bin/sh\nexec env DIAG_DIRECT_PLANT_ACTIVE=%s %s --threads 4 "$@"\n' "$active" "$base/bin/$group/bench-$i" > "$r/wrappers/$side-$i"
        chmod +x "$r/wrappers/$side-$i"
    done
done
cd "$r/run"
echo "begin $(date -Is)" >> "$r/status.log"
set +e
env DIAG_DIRECT_PLANT_ACTIVE=0 taskset -c 0,2,4,6 "$base/bin/control-a/bench-0" regress --contenders blake3-servil-st,blake3-servil-mt --pairs 4 --keep "$r/samples" "$r"/wrappers/old-{0..3} -- "$r"/wrappers/new-{0..3} > "$r/regress.out" 2> "$r/regress.err"
code=$?
set -e
echo "regress exit=$code $(date -Is)" >> "$r/status.log"
[ "$code" -le 2 ]
env DIAG_DIRECT_PLANT_ACTIVE=0 "$base/bin/control-a/bench-0" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
echo complete >> "$r/status.log"
