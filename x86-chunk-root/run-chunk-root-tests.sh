#!/bin/bash
# Native tests of the x86 one-chunk root kernel (candidate/sam-x86-chunk-root
# on John's servil b94e2fa). Serialized on the EPYC; timeouts are unresolved.
set -u
. /root/.cargo/env
r=/root/results/chunk-root/tests
mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root
if [ ! -d "$wt" ]; then
    git -C /root/BLAKE3 fetch -q https://github.com/johnservil/BLAKE3.git b94e2fac72b8be346e8c012c6a749caa134e2480
    git -C /root/BLAKE3 worktree add -q --detach "$wt" b94e2fac72b8be346e8c012c6a749caa134e2480
fi
tar xzf /root/chunk-root-src.tgz -C "$wt"
cd "$wt"
git status --short > "$r/source-status.txt"; git diff > "$r/source.diff"
run() { name=$1; shift; status "$name"; timeout --signal=TERM --kill-after=10 900 "$@" > "$r/$name.log" 2>&1; code=$?; printf '%s\n' "$code" > "$r/$name-exit"; status "$name exit=$code"; }
run focused cargo nextest run --release --lib -E 'test(chunk_root)' --success-output immediate --no-fail-fast
run release cargo nextest run --release --lib --tests --no-fail-fast
run debug cargo nextest run --lib --tests --no-fail-fast
run no-default cargo nextest run --release --no-default-features --lib --tests --no-fail-fast
run pure cargo nextest run --release --features pure --lib --tests --no-fail-fast
run vectors cargo nextest run --release --manifest-path test_vectors/Cargo.toml
run capi cargo nextest run --release --manifest-path capi/Cargo.toml
run docs cargo test --doc --release
run clippy cargo clippy --release --all-targets -- -D warnings
status complete
printf 'done\n' > "$r/complete"
