#!/bin/bash
# clocks: other programs counted from their own CPU time (candidate/
# sam-load-other-programs 6ed0856 on servil 0909641; clocks/ identical to
# the bench's pin 7f9f1f7 otherwise). Tests, reading cost, then the released
# bench (ae63011) with only clocks patched to this, rerunning the same
# b3sum run: do the 16 busy windows go away?
set -u
. /root/.cargo/env
r=/root/results/load-fix-v2
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-load-other
rm -rf "$wt"; git -C /root/BLAKE3 worktree prune
git -C /root/BLAKE3 fetch -q -f /root/load.bundle +candidate/sam-load-other-programs:candidate/sam-load-other-programs || exit 3
git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-load-other-programs || exit 3
[ "$(git -C "$wt" rev-parse HEAD)" = a240274ded39ce20a17bd6b06da40272184dd6d4 ] || exit 3
git -C "$wt" diff --quiet 7f9f1f7f79f4b239bf9b3089afdde83d2333febb HEAD~1 -- clocks/ || exit 3
run() { name=$1; shift; ( cd "$wt/clocks" && timeout 900 "$@" ) > "$r/$name.log" 2>&1; code=$?; echo "$code" > "$r/$name-exit"; status "$name exit=$code"; }
run clocks-tests cargo nextest run --release --no-fail-fast
run clocks-own-children cargo test --release --lib -- --ignored --nocapture own_children
run clocks-reading-cost cargo test --release --lib -- --ignored --nocapture reading_cost
b=/root/bench-load-fix
rm -rf "$b"; git clone -q /root/bench-hashes-v7 "$b" || exit 3
git -C "$b" checkout -q --detach ae6301136e1827cff86bf823f024870775b224d5 || exit 3
patch="patch.\"https://github.com/devonjonte/BLAKE3\".clocks.path=\"$wt/clocks\""
( cd "$b" && cargo --config "$patch" update -q -p clocks && cargo --config "$patch" build -q --release ) > "$r/bench-build.log" 2>&1 || exit 3
git -C "$b" diff --stat > "$r/bench-lock-diff.txt"
o="$r/b3sum"; mkdir -p "$o"
mapfile -t contenders < /root/results/released-cli-v7/contenders.txt
( cd /root/results/released-cli-v7/bin && sha256sum * ) | cmp - /root/results/released-cli-v7/bin.sha256 || exit 3
status 'b3sum rerun with the patched clocks begins'
( cd "$o" && "$b/target/release/bench-hashes" b3sum --files /root/results/b3sum-files-v7 "${contenders[@]}" ) > "$o/run.out" 2> "$o/run.err"
status "b3sum exit=$?"
grep -E '^load:' "$o"/benchmark-results/*/b3sum.result.txt >> "$r/status.log"
printf 'done\n' > "$r/complete"
