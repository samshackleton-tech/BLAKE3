#!/bin/bash
# The middle way (#125): the wide AVX-512 kernel on calling threads only, the
# pool's workers keeping the 16-input kernel (2cf9a56 = a49ff2c + that rule),
# against the same old side (a9e70b8). Existing tools only; energy as before.
set -u
C=/root/BLAKE3-wide-caller
OLD=$(git -C /root/BLAKE3-wide-new rev-parse HEAD^)
NEW=$(git -C $C rev-parse HEAD)
out=/root/results/wide-20261025/caller
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
step setup
[ -d $C/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $C/bench-hashes
git -C $C/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
{ date -u; echo "old $OLD"; echo "new $NEW"; git -C $C log -1 --format=%s; git -C $C status --short; git -C $C/bench-hashes rev-parse HEAD; git -C $C diff --stat $OLD $NEW; } > $out/provenance.txt 2>&1
step suites
cd $C
(CARGO_TARGET_DIR=/root/target-wide-caller cargo nextest run --release > $out/test-default.log 2>&1) || { echo "tests failed"; exit 20; }
(CARGO_TARGET_DIR=/root/target-wide-caller-pure cargo nextest run --release --features pure > $out/test-pure.log 2>&1) || { echo "pure tests failed"; exit 20; }
(CARGO_TARGET_DIR=/root/target-wide-caller-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $out/test-capi.log 2>&1) || { echo "capi tests failed"; exit 20; }
grep -h Summary $out/test-*.log
sleep 30
cd $C/bench-hashes
for run in 1 2; do
  step library run $run
  cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/lib$run-samples > $out/lib$run.out 2> $out/lib$run.err
  echo "lib$run exit $?"
  ./target/release/bench-hashes compare $out/lib$run-samples/run-*-old.tsv -- $out/lib$run-samples/run-*-new.tsv > $out/lib$run-compare.out 2>&1
done
step CLI builds
CLI=/root/results/wide-cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py /root/BLAKE3-round-pr164 $CLI $OLD $NEW > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; tail $out/cli-build.log; exit 30; }
o=${OLD:0:7}; n=${NEW:0:7}
sleep 20
for r in 1 2; do
  for mode in mt st; do
    args=()
    for i in 0 1 2 3; do if [ $mode = mt ]; then args+=("old=$CLI/b3sum-$o-L$i"); else args+=("old-1t=$CLI/b3sum-$o-L$i --num-threads 1"); fi; done
    for i in 0 1 2 3; do if [ $mode = mt ]; then args+=("new=$CLI/b3sum-$n-L$i"); else args+=("new-1t=$CLI/b3sum-$n-L$i --num-threads 1"); fi; done
    step CLI r$r $mode
    cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli-r$r-$mode.out 2> $out/cli-r$r-$mode.err
    echo "cli-r$r-$mode exit $?"
    mkdir -p $out/cli-r$r-$mode-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/cli-r$r-$mode-results/
    git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
  done
done
step energy
E=$out/energy; mkdir -p $E
export F=/dev/shm/caller-energy-1g; head -c $((1<<30)) /dev/urandom > $F
perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/idle.txt sleep 2
sleep 5
OLDC=$CLI/b3sum-$o-L0; NEWC=$CLI/b3sum-$n-L0
for rep in 1 2 3 4 5; do
  for k in old:$OLDC new:$NEWC; do
    nm=${k%%:*}; B=${k#*:}
    perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$nm-p1-r$rep.txt taskset -c 0 $B --num-threads 1 $F > /dev/null
    perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$nm-mt-r$rep.txt bash -c "for i in 1 2 3 4 5 6 7 8; do $B $F > /dev/null; done"
    sleep 2
  done
done
rm -f $F
step done; date -u
