#!/bin/bash
# After campaign.sh: (1) the kernel-only ablation (wide kernel without its
# tree-thread budget) against the old side; (2) warm SMT behaviour of the
# old and new builds; (3) energy per GiB of the old and new b3sum.
# Measurement only; existing tools and today's perf-based methods.
set -u
out=/root/results/wide-20261025
exec > $out/followup.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
sleep 120   # let campaign.sh take the lock first
exec 9>/root/bench-native-afk.lock
flock -w 14400 9 || { echo "lock busy"; exit 75; }
grep -q '== done' $out/campaign.log || { echo "campaign did not finish"; exit 21; }

K=/root/BLAKE3-wide-konly
OLD=$(git -C /root/BLAKE3-wide-new rev-parse HEAD^)
step konly tests
cd $K && CARGO_TARGET_DIR=/root/target-wide-konly cargo nextest run --release > $out/konly-tests.log 2>&1 || { echo "konly tests failed"; exit 22; }
grep Summary $out/konly-tests.log
[ -d $K/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $K/bench-hashes
git -C $K/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
sleep 30
step konly check
cd $K/bench-hashes
cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/konly-samples > $out/konly.out 2> $out/konly.err
echo "konly exit $?"
./target/release/bench-hashes compare $out/konly-samples/run-*-old.tsv -- $out/konly-samples/run-*-new.tsv > $out/konly-compare.out 2>&1

step SMT warm
W=$out/smt-warm; mkdir -p $W
OLDB=$(ls /root/BLAKE3-wide-new/target/check/old/bench-hashes-* | sort -V | head -1)
NEWB=$(ls /root/BLAKE3-wide-new/target/check/new/bench-hashes-* | sort -V | head -1)
CLI=/root/results/wide-cli-bin
OLDC=$CLI/b3sum-${OLD:0:7}-L0
NEWC=$CLI/b3sum-$(git -C /root/BLAKE3-wide-new rev-parse --short=7 HEAD)-L0
for b in $OLDB $NEWB $OLDC $NEWC; do echo "$b $(sha256sum $b | cut -c1-16)"; done > $W/binaries.txt
F=/dev/shm/wide-16m; head -c $((16<<20)) /dev/urandom > $F
loader() { taskset -c $1 bash -c "while :; do $2 --num-threads 1 $F > /dev/null; done" & LOADER=$!; }
run() { local d=$W/$1; mkdir -p $d; cd $d; taskset -c 0 perf stat -M PipelineL1 -o $d/perf.txt $2 --contenders blake3-servil-st --points "64 KiB,1 MiB" --rounds 96 > $d/stdout.txt 2> $d/stderr.txt; }
for rep in 1 2 3 4 5; do
  for k in old:$OLDB:$OLDC new:$NEWB:$NEWC; do
    IFS=: read n b l <<< "$k"
    run $n-solo-r$rep $b
    loader 24 $l; sleep 0.3; run $n-siblings-r$rep $b; kill $LOADER; wait $LOADER 2>/dev/null
    loader 1 $l; sleep 0.3; run $n-separate-r$rep $b; kill $LOADER; wait $LOADER 2>/dev/null
  done
done
rm -f $F

step energy
E=$out/energy; mkdir -p $E
export F=/dev/shm/wide-energy-1g; head -c $((1<<30)) /dev/urandom > $F
perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/idle.txt sleep 2
sleep 5
work() { for c in "$@"; do taskset -c $c $B --num-threads 1 $F > /dev/null & done; wait; }
export -f work
for rep in 1 2 3 4 5; do
  for k in old:$OLDC new:$NEWC; do
    n=${k%%:*}; export B=${k#*:}
    perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$n-p1-r$rep.txt bash -c 'work 0'
    perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$n-p24-r$rep.txt bash -c "work $(seq -s' ' 0 23)"
    perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$n-p48-r$rep.txt bash -c "work $(seq -s' ' 0 47)"
    # multithreaded b3sum, one process, every thread: the library's pool
    perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$n-mt-r$rep.txt bash -c "for i in 1 2 3 4 5 6 7 8; do $B $F > /dev/null; done"
    sleep 2
  done
done
grep -h 'seconds time elapsed' $E/*-p*-r*.txt | sort -n | head -2
rm -f $F
step done; date -u
