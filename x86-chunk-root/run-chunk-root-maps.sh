#!/bin/bash
# Before/after offset maps: John's servil b94e2fa against the chunk-root fix
# (cba5f24, same base), each built with `bench-hashes build-against` at the
# same bench commit (#67: a run's heap laid out alike every run), so solo
# cells repeat too. setarch -R inside the tool.
set -u
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile GIT_CONFIG_VALUE_0=/root/bench-excludes
r=/root/results/chunk-root/maps
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
bench=aedc061ac0c0ef07eddf0d7d455cc9ce87b4d8c0   # main + deterministic heap (#67)
git -C /root/bench-hashes-v7 fetch -q https://github.com/samshackleton-tech/bench-hashes.git "$bench"
base=/root/BLAKE3-base-b94e2fa
[ -d "$base" ] || git -C /root/BLAKE3 worktree add -q --detach "$base" b94e2fac72b8be346e8c012c6a749caa134e2480
fix=/root/BLAKE3-chunk-root
git -C "$fix" add -A -- . ':!bench-hashes' && git -C "$fix" -c core.hooksPath=/dev/null commit -q -m 'chunk root (local copy of cba5f24)' || true
git -C "$fix" rev-parse HEAD HEAD^{tree} > "$r/fix-commit.txt"
for side in base fix; do
    wt=$base; [ "$side" = fix ] && wt=$fix
    [ -d "$wt/bench-hashes" ] || git clone -q /root/bench-hashes-v7 "$wt/bench-hashes"
    git -C "$wt/bench-hashes" checkout -q "$bench"
    exe=$(cd "$wt/bench-hashes" && cargo run -q --release -- build-against .. 2> "$r/$side-build.err")
    printf '%s\n' "$exe" > "$r/$side-exe.txt"; status "$side built: $exe"
    test -x "$exe" || exit 3
    python3 /root/offset_check.py --exe "$exe" --repeat 3 --map "$r/$side.tsv" --keep "$r/$side-runs" > "$r/$side-map.out" 2> "$r/$side-map.err"
    status "$side map exit=$?"
done
status complete
printf 'done\n' > "$r/complete"
