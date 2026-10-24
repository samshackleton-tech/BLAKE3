#!/bin/bash
# Retrospective: decisions possibly made under bench-hashes #65's artifact,
# re-run with no buffer crossing a cache line: bench v7 ae63011 plus the
# DIAGNOSTIC-ONLY default allocator aligning >=64-byte allocations to 64
# (51ce58f). Both sides of each check build that same bench.
#  0. A/A: a5e1e18 against itself, full4 (instrument control).
#  A. guarded publication wake (a5e1e18 + /root/stream-wake-guarded-lanes.rs)
#     against a5e1e18, full4 (originally exit1: only MT shared lent 64 B
#     +43.8%); if clean, full8 against 8e968d5 as the original pipeline.
#  B. parent-routing ablation 9e5f484 against a5e1e18, full16 (originally
#     v6 full16 failed only MT solo IdleManyMessages|1 +3.1%).
set -u
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile GIT_CONFIG_VALUE_0=/root/bench-excludes
r=/root/results/retro-align64
mkdir -p "$r"   # kept: the A/A step of the first launch (exit 0) stays
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
while pgrep -f "^bash /root/run-line-offset-drain.sh" > /dev/null; do sleep 30; done
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
parent=a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00
bench=/root/bench-v7-align64
rm -rf "$bench"
git clone -q /root/bench-hashes-v7 "$bench" || exit 3
git -C "$bench" fetch -q /root/v7-align64.bundle HEAD || exit 3
git -C "$bench" checkout -q --detach FETCH_HEAD || exit 3
[ "$(git -C "$bench" rev-parse HEAD)" = 51ce58f59bcd2ed7f89a914645f2b3ff915928b5 ] || exit 3
( cd "$bench" && cargo build -q --release ) > "$r/control-build.log" 2>&1 || exit 3
control=$bench/target/release/bench-hashes
git -C /root/BLAKE3 fetch -q /root/routing.bundle retro/parent-routing-ablation 2>> "$r/setup.log" || git -C /root/BLAKE3 cat-file -e 9e5f4841a212f724b279459fb10f7760baec216a || exit 3
printf 'bench=51ce58f59bcd2ed7f89a914645f2b3ff915928b5 (ae63011 + diag-align64 default)\nparent=%s\n' "$parent" > "$r/pins.txt"
# check(name, worktree, against, pairs): run from a bench clone inside the worktree
check() {
    name=$1; wt=$2; against=$3; pairs=$4
    rm -rf "$wt/bench-hashes"
    git clone -q "$bench" "$wt/bench-hashes" || exit 3
    git -C "$wt/bench-hashes" checkout -q --detach 51ce58f59bcd2ed7f89a914645f2b3ff915928b5 || exit 3
    status "$name: check --against $against --pairs $pairs begins"
    ( cd "$wt/bench-hashes" && "$control" check --against "$against" --cells all --pairs "$pairs" --keep "$r/samples-$name" ) > "$r/check-$name.out" 2> "$r/check-$name.err"
    code=$?; printf '%s\n' "$code" > "$r/exit-$name"; status "$name exit=$code"
    grep -l 'global allocator: diagnostic' "$r"/samples-"$name"/run-*-old.tsv "$r"/samples-"$name"/run-*-new.tsv 2>/dev/null | wc -l > "$r/diag-header-count-$name"
    status "$name: samples files carrying the diagnostic allocator header: $(cat "$r/diag-header-count-$name") of $(ls "$r"/samples-"$name"/run-*.tsv 2>/dev/null | wc -l)"
    "$control" compare "$r"/samples-"$name"/run-*-old.tsv -- "$r"/samples-"$name"/run-*-new.tsv > "$r/compare-$name.out" 2> "$r/compare-$name.err"
    return $code
}
mk() { wt=$1; rev=$2; rm -rf "$wt"; git -C /root/BLAKE3 worktree prune; git -C /root/BLAKE3 worktree add -q --detach "$wt" "$rev" || exit 3; }
if [ "$(cat "$r/exit-aa" 2>/dev/null)" != 0 ]; then
    mk /root/retro-aa "$parent"
    check aa /root/retro-aa "$parent" 4; aa=$?
    [ "$aa" -le 2 ] || exit "$aa"
fi
status "relaunched after the source guard compared diff headers; A/A kept"
mk /root/retro-guarded "$parent"
cp /root/stream-wake-guarded-lanes.rs /root/retro-guarded/src/lanes.rs || exit 3
git -C /root/retro-guarded diff --stat > "$r/guarded-source-stat.txt"; cmp /root/retro-guarded/src/lanes.rs /root/results/avx512-registers/stream-wake-guarded/lanes.rs || exit 3
git -C /root/retro-guarded diff > "$r/guarded-source.diff"
check guarded-parent /root/retro-guarded "$parent" 4; g=$?
[ "$g" -le 2 ] || exit "$g"
if [ "$g" = 0 ]; then
    check guarded-baseline /root/retro-guarded 8e968d5599b3ae577f5234f1e8e5e10cfb72b9e4 8
fi
mk /root/retro-routing 9e5f4841a212f724b279459fb10f7760baec216a
check routing /root/retro-routing "$parent" 16
status complete
printf 'done\n' > "$r/complete"
