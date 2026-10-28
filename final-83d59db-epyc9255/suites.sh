#!/bin/bash
# The suites at the final version commit on the EPYC 9255 (AVX-512, wide kernels on): release-tests.sh as a pinned-run job.
set -u
R="$1"; grep -m1 "^version" "$R/src/Cargo.toml" > "$R/version.txt"; mkdir -p "$R/out"
bash -s "$R/src" "$R/out/tests" <<'TESTS'
#!/bin/bash
# 0.8's suites on one x86-64 Linux machine, as CI runs them (no `pure`
# since #190): nextest in each feature set, the C API, b3sum, doc examples,
# Shuttle, check-builds, rustfmt, the tools' own tests, the x86 cross-check,
# and the wide-dispatch tests with their output (which path this CPU takes).
# Miri's smoke test where a Miri nightly is installed (MIRI_TOOLCHAIN).
# Usage: release-tests.sh REPO OUT   (REPO checked out at the commit to test)
set -u
export HOME=/root
D=$1; out=$2; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
cd $D || exit 10
T=/root/target-release-tests; st=0
{ date -u; git log -1 --format='%H %s'; git status --short; rustc -V; cargo nextest --version | head -1
  grep -m1 'model name' /proc/cpuinfo; grep -m1 vendor_id /proc/cpuinfo; grep -m1 'cpu family' /proc/cpuinfo
  grep -m1 -o -w -E 'avx512f|avx512vl' /proc/cpuinfo | sort -u | tr '\n' ' '; echo; grep -m1 -o -w avx2 /proc/cpuinfo; nproc; } > $out/provenance.txt 2>&1
run() { name=$1; shift; ( "$@" ) > $out/$name.log 2>&1; s=$?; echo "$name exit $s"; [ $s = 0 ] || st=1; }
(CARGO_TARGET_DIR=$T-a cargo nextest run --features=serde,zeroize > $out/debug-features.log 2>&1; echo $? > $out/debug-features.st) &
(CARGO_TARGET_DIR=$T-b cargo nextest run --release > $out/release.log 2>&1; echo $? > $out/release.st) &
(CARGO_TARGET_DIR=$T-c cargo nextest run --no-default-features > $out/no_std.log 2>&1; echo $? > $out/no_std.st) &
(CARGO_TARGET_DIR=$T-d cargo nextest run --features= --release > $out/no-features.log 2>&1; echo $? > $out/no-features.st) &
(CARGO_TARGET_DIR=$T-e cargo nextest run --release --manifest-path capi/Cargo.toml > $out/capi.log 2>&1; echo $? > $out/capi.st) &
(CARGO_TARGET_DIR=$T-f cargo nextest run --release --manifest-path b3sum/Cargo.toml > $out/b3sum.log 2>&1; echo $? > $out/b3sum.st) &
(CARGO_TARGET_DIR=$T-g cargo test --doc --features=serde,zeroize > $out/doc.log 2>&1; echo $? > $out/doc.st) &
wait
for n in debug-features release no_std no-features capi b3sum doc; do s=$(cat $out/$n.st); echo "$n exit $s"; [ "$s" = 0 ] || st=1; done
run shuttle-park env RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-s cargo test --release --test shuttle_park
run shuttle-finish env RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-s cargo test --release --test shuttle_finish
run check-builds env CARGO_TARGET_DIR=$T-builds bash tools/check-builds.sh
run rustfmt bash -c 'for d in $(git ls-files "*Cargo.toml" | xargs -n1 dirname); do (cd "$d" && cargo fmt --all -- --check) || exit 1; done'
run release-check-tests python3 tools/test_release_check.py
run cross-check python3 tools/verify/cross_check_x86.py
run wide-tests env CARGO_TARGET_DIR=$T-b cargo nextest run --release --no-capture wide
if [ -n "${MIRI_TOOLCHAIN:-}" ]; then
  run miri env MIRIFLAGS="-Zmiri-num-cpus=4 -Zmiri-ignore-leaks" CARGO_TARGET_DIR=$T-miri cargo +$MIRI_TOOLCHAIN miri nextest run --profile miri miri
  # CI's Miri job runs the C API's guard tests under Miri too.
  run capi-guards env RUSTUP_TOOLCHAIN=$MIRI_TOOLCHAIN CARGO_TARGET_DIR=$T-miri python3 tools/test_capi_guards.py
fi
grep -hE 'Summary|test result:|all agree|every build passes' $out/*.log > $out/summary.txt
echo "all status $st"; date -u
exit $st
TESTS
cp "$R/version.txt" "$R/out/version.txt"
