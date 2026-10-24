#!/bin/bash
# Per-thread hardware counters for the focused shared LentMessages 64 B cell:
# duo-copy-0/1 run only shared samples; the main thread runs solo ones.
# Old a5e1e18 vs guarded build, existing check executables, --threads 48.
set -u
r=/root/results/avx512-registers/lent64-thread-counters
mkdir -p "$r/bin" "$r/stats"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf)$'; then exit 3; fi
control=/root/bench-hashes-v7/target/release/bench-hashes
b=/root/BLAKE3-stream-wake-guarded/target/check
events='-e cpu/cycles,period=200003/u -e cpu/instructions,period=200003/u -e ls_bad_status2.stli_other/period=2003/u -e ex_no_retire.load_not_complete/period=20003/u -e de_no_dispatch_per_slot.smt_contention/period=20003/u -e ls_l1_d_tlb_miss.all/period=2003/u'
list=()
for spec in old:0 old:1 old:2 old:3 -- new:4 new:5 new:6 new:7; do
    if [ "$spec" = -- ]; then list+=(--); continue; fi
    side=${spec%%:*}; i=${spec#*:}; w="$r/bin/$side-$i"
    printf '#!/bin/sh\nexec perf record -q %s -o %s/%s-%s-$$.data -- %s/%s/bench-hashes-%s --threads 48 "$@"\n' "$events" "$r/stats" "$side" "$i" "$b" "$side" "$i" > "$w"
    chmod +x "$w"; list+=("$w")
done
status 'per-thread counter run'
"$control" regress --contenders blake3-servil-st,blake3-servil-mt --points 'lent 64 B' --pairs 4 --keep "$r/samples" "${list[@]}" > "$r/check.out" 2> "$r/check.err"
status "regress exit=$?"
"$control" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
for f in "$r"/stats/*.data; do
    perf report --stdio -i "$f" --sort comm --show-total-period -n > "${f%.data}.report" 2> "${f%.data}.report.err"
done
status 'complete'
printf 'done\n' > "$r/complete"
