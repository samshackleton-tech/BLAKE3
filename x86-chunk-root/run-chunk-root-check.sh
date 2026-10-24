#!/bin/bash
# Speed check of the x86 chunk-root fix against John's servil b94e2fa: all
# cells, 8 pairs, bench main e3cfbd1 (official; heap layout still varies per
# process there, so solo cells average over layouts rather than sit in one).
set -u
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile GIT_CONFIG_VALUE_0=/root/bench-excludes
r=/root/results/chunk-root/check-main
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
w=/root/BLAKE3-chunk-root
git -C "$w/bench-hashes" fetch https://github.com/johnservil/bench-hashes.git e3cfbd1dd9b6 >> "$r/fetch.log" 2>&1 || git -C "$w/bench-hashes" fetch https://github.com/johnservil/bench-hashes.git main >> "$r/fetch.log" 2>&1 || exit 3
git -C "$w/bench-hashes" checkout -q FETCH_HEAD
case "$(git -C "$w/bench-hashes" rev-parse HEAD)" in e3cfbd1dd9b6*) ;; *) echo "bench is not main e3cfbd1" >&2; exit 3;; esac
git -C "$w/bench-hashes" rev-parse HEAD > "$r/bench.txt"
git -C "$w" rev-parse HEAD HEAD^{tree} > "$r/fix.txt"
cd "$w/bench-hashes"
status 'check --cells all --pairs 8 against b94e2fa'
cargo run -q --release -- check --against b94e2fac72b8be346e8c012c6a749caa134e2480 --cells all --pairs 8 --keep "$r/samples" > "$r/check.out" 2> "$r/check.err"
status "check exit=$?"
e=$(ls ../target/check/new/bench-hashes-* | head -1)
"$e" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
status complete
printf 'done\n' > "$r/complete"
