#!/bin/bash
set -u
. /root/.cargo/env
r=/root/results/peer-finish-publication-fix
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if kill -0 2898809 2>/dev/null; then tail --pid=2898809 -f /dev/null; fi
test -f /root/results/peer-promoted-model-2e892e1/complete || exit 3
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf)$'; then exit 3; fi
base=d14548a44b7c1da7e6c985be9c445dda186dc553
wt=/root/BLAKE3-finish-publication
git -C /root/BLAKE3 worktree add --detach "$wt" "$base" > "$r/setup.log" 2>&1 || exit 3
cp /root/finish-publication-loom.rs "$wt/tests/loom_finish.rs" || exit 3
cd "$wt"
printf '%s\n' "$base" > "$r/base.txt"
status 'enhanced payload-before-join models against ORIGINAL Relaxed source: negative control'
timeout --signal=TERM --kill-after=10 300 env RUSTFLAGS='--cfg loom' cargo nextest run --release --test loom_finish --test-threads 1 --no-fail-fast > "$r/loom-relaxed.log" 2>&1
code=$?; printf '%s\n' "$code" > "$r/loom-relaxed-exit"; status "Relaxed control exit=$code"
[ "$code" = 100 ] || exit 3
grep -Fq 'wait returned without publishing worker output' "$r/loom-relaxed.log" || exit 3
cp /root/finish-publication-acquire.rs src/finish.rs || exit 3
git diff --check || exit 3
git diff > "$r/fix.patch"
status 'same models with Acquire completion-count load'
timeout --signal=TERM --kill-after=10 300 env RUSTFLAGS='--cfg loom' cargo nextest run --release --test loom_finish --test-threads 1 --no-fail-fast > "$r/loom-acquire.log" 2>&1
code=$?; printf '%s\n' "$code" > "$r/loom-acquire-exit"; status "Acquire models exit=$code"
[ "$code" = 0 ] || exit "$code"
status 'native library serde/zeroize release and debug suites on fix'
cargo nextest run --release --lib --tests --features serde,zeroize > "$r/native-release.log" 2>&1
code=$?; status "release exit=$code"; [ "$code" = 0 ] || exit "$code"
cargo nextest run --lib --tests --features serde,zeroize > "$r/native-debug.log" 2>&1
code=$?; status "debug exit=$code"; [ "$code" = 0 ] || exit "$code"
cargo tree -p loom --depth 0 > "$r/loom-version.txt"
git diff --check || exit 3
status 'patch controls complete; no performance promotion or whole-pool proof claimed'
printf 'done\n' > "$r/complete"
