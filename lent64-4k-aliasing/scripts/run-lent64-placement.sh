#!/bin/bash
# Hypothesis: shared LentMessages 64 B slows when the scheduler places the
# two duo-copy threads on SMT siblings of one core. (1) trace where they run;
# (2) force placement. Existing check-built executables, one layout per pair;
# --threads 48 explicit everywhere so pool size never follows affinity.
set -u
r=/root/results/avx512-registers/lent64-placement
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
status 'wait for lent64 repro'
if kill -0 1537949 2>/dev/null; then tail --pid=1537949 -f /dev/null; fi
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf)$'; then exit 3; fi
control=/root/bench-hashes-v7/target/release/bench-hashes
[ "$(git -C /root/bench-hashes-v7 rev-parse HEAD)" = ae6301136e1827cff86bf823f024870775b224d5 ] || exit 3
cat /sys/devices/system/cpu/cpu0/topology/thread_siblings_list /sys/devices/system/cpu/cpu1/topology/thread_siblings_list > "$r/siblings-check.txt"
b=/root/BLAKE3-stream-wake-guarded/target/check
point='lent 64 B'
wrappers() {  # name prefix: emits old then -- then new wrapper paths
    d=$1; prefix=$2; mkdir -p "$d/bin"
    list=()
    for spec in old:0 old:1 old:2 old:3 -- new:4 new:5 new:6 new:7; do
        if [ "$spec" = -- ]; then list+=(--); continue; fi
        side=${spec%%:*}; i=${spec#*:}
        w="$d/bin/$side-$i"
        printf '#!/bin/sh\nexec %s %s/%s/bench-hashes-%s --threads 48 "$@"\n' "$prefix" "$b" "$side" "$i" > "$w"
        chmod +x "$w"; list+=("$w")
    done
}
regress() {
    d=$1; shift
    "$control" regress --contenders blake3-servil-st,blake3-servil-mt --points "$point" --pairs 4 --keep "$d/samples" "$@" > "$d/check.out" 2> "$d/check.err"
    code=$?; printf '%s\n' "$code" > "$d/exit-code"
    "$control" compare "$d"/samples/run-*-old.tsv -- "$d"/samples/run-*-new.tsv > "$d/compare.out" 2> "$d/compare.err"
    return 0
}
# (1) Placement trace: per process, sched_switch with CPU; timings diagnostic.
d="$r/trace"; mkdir -p "$d/data"
wrappers "$d" "perf record -q -e task-clock -F 4000 -o $d/data/\$\$.data --"
# The prefix must expand $$ per process: rewrite wrappers accordingly.
for w in "$d"/bin/*; do
    python3 - "$w" "$d/data" "$(basename "$w")" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text()
s=s.replace(f'-o {sys.argv[2]}/$$.data', f'-o {sys.argv[2]}/{sys.argv[3]}-$$.data')
p.write_text(s)
PY
done
status 'trace run begins (task-clock samples at4kHz: thread, CPU, time)'
regress "$d" "${list[@]}"
status "trace run exit=$(cat "$d/exit-code")"
for f in "$d"/data/*.data; do
    perf script -F comm,tid,cpu,time -i "$f" > "${f%.data}.txt" 2> "${f%.data}.err"
done
# (2) Forced placement: same executables and layouts, three affinities.
for spec in separate-cores:0,1 siblings:0,24 one-per-core:0-23; do
    name=${spec%%:*}; cpus=${spec#*:}
    d="$r/$name"; mkdir -p "$d"
    wrappers "$d" "taskset -c $cpus"
    status "$name ($cpus) begins"
    regress "$d" "${list[@]}"
    status "$name exit=$(cat "$d/exit-code")"
done
# Same-build placement effect: parent unpinned-like (all CPUs) vs siblings.
d="$r/parent-all-vs-siblings"; mkdir -p "$d/bin"; list=()
for i in 0 1 2 3; do w="$d/bin/all-$i"; printf '#!/bin/sh\nexec taskset -c 0-47 %s/old/bench-hashes-%s --threads 48 "$@"\n' "$b" "$i" > "$w"; chmod +x "$w"; list+=("$w"); done
list+=(--)
for i in 2 3 0 1; do w="$d/bin/sib-$i"; printf '#!/bin/sh\nexec taskset -c 0,24 %s/old/bench-hashes-%s --threads 48 "$@"\n' "$b" "$i" > "$w"; chmod +x "$w"; list+=("$w"); done
status 'parent all-CPUs vs forced siblings'
regress "$d" "${list[@]}"
status "parent placement exit=$(cat "$d/exit-code")"
status 'complete'
printf 'done\n' > "$r/complete"
