#!/bin/bash
# Attribution for the guarded-wake baseline failures under aligned buffers
# (IdleManyMessages|1 ST/MT +3.4/+3.8%, Idle/OneMessage 2 MiB MT +4.5/+3.3%):
# the a5e1e18 candidate itself against 8e968d5, full8, same diagnostic bench
# (51ce58f). Waits for run-retro-align64.sh.
set -u
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile GIT_CONFIG_VALUE_0=/root/bench-excludes
r=/root/results/retro-align64
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
while pgrep -f '^bash /root/run-retro-align64.sh' > /dev/null; do sleep 30; done
trap 'printf "%s\n" "$?" > "$r/runner-exit-code-line"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
bench=/root/bench-v7-align64
[ "$(git -C "$bench" rev-parse HEAD)" = 51ce58f59bcd2ed7f89a914645f2b3ff915928b5 ] || exit 3
control=$bench/target/release/bench-hashes
wt=/root/retro-line
rm -rf "$wt"; git -C /root/BLAKE3 worktree prune
git -C /root/BLAKE3 worktree add -q --detach "$wt" a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00 || exit 3
git clone -q "$bench" "$wt/bench-hashes" || exit 3
git -C "$wt/bench-hashes" checkout -q --detach 51ce58f59bcd2ed7f89a914645f2b3ff915928b5 || exit 3
status 'line: a5e1e18 check --against 8e968d5 --pairs 8 begins'
( cd "$wt/bench-hashes" && "$control" check --against 8e968d5599b3ae577f5234f1e8e5e10cfb72b9e4 --cells all --pairs 8 --keep "$r/samples-line" ) > "$r/check-line.out" 2> "$r/check-line.err"
code=$?; printf '%s\n' "$code" > "$r/exit-line"; status "line exit=$code"
status "line: samples files carrying the diagnostic allocator header: $(grep -l 'global allocator: diagnostic' "$r"/samples-line/run-*.tsv | wc -l) of $(ls "$r"/samples-line/run-*.tsv | wc -l)"
"$control" compare "$r"/samples-line/run-*-old.tsv -- "$r"/samples-line/run-*-new.tsv > "$r/compare-line.out" 2> "$r/compare-line.err"
printf 'done\n' > "$r/complete-line"
