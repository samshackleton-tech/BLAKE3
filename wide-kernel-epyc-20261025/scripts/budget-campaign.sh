#!/bin/bash
# The tree-thread budget's trade-offs (#125), EPYC 9255. Measurement only.
#   A: wide everywhere WITH the budget (a49ff2c) judged against WITHOUT it (433502a)
#   B: the pool cells it acts on, 32 pairs (regress on A's relinked builds)
#   C: the budget on the OLD kernel (45d6ea5) against old (a9e70b8)
#   D: CLI, wide everywhere with against without (b3sum workload, mt)
#   E: energy at medium sizes, with against without
set -u
out=/root/results/wide-20261025/budget
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
W=/root/BLAKE3-wide-new; KONLY=$(git -C /root/BLAKE3-wide-konly rev-parse HEAD)
OLD=$(git -C $W rev-parse HEAD^); B=/root/BLAKE3-budget-old
{ date -u; echo "with $(git -C $W rev-parse HEAD)"; echo "without $KONLY"; echo "old $OLD"; echo "old+budget $(git -C $B rev-parse HEAD)"; git -C $W diff --stat $KONLY HEAD; git -C $B diff --stat $OLD HEAD; } > $out/provenance.txt 2>&1

step tests on old+budget
cd $B && CARGO_TARGET_DIR=/root/target-budget-old cargo nextest run --release > $out/test-old-budget.log 2>&1 || { echo "tests failed"; exit 20; }
grep Summary $out/test-old-budget.log
[ -d $B/bench-hashes ] || git clone -q $W/bench-hashes $B/bench-hashes
git -C $B/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
sleep 30

step A: with budget against without, wide everywhere
cd $W/bench-hashes
cargo run --release -- check --against $KONLY --cells all --pairs 12 --keep $out/A-samples > $out/A.out 2> $out/A.err
echo "A exit $?"
./target/release/bench-hashes compare $out/A-samples/run-*-old.tsv -- $out/A-samples/run-*-new.tsv > $out/A-compare.out 2>&1

step B: pool cells, 32 pairs
POINTS="512 KiB,1 MiB,2 MiB,3 MiB,4 MiB,8 MiB,32 MiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,idle 3 MiB,idle 4 MiB,idle 8 MiB,lent 1 MiB,lent 4 MiB,merkle 4096,merkle 16384"
mapfile -t olds < <(ls $W/target/check/old/bench-hashes-* | sort -V | tail -16)
mapfile -t news < <(ls $W/target/check/new/bench-hashes-* | sort -V | tail -16)
./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs 32 --keep $out/B-samples "${olds[@]}" "${olds[@]}" -- "${news[@]}" "${news[@]}" > $out/B.out 2> $out/B.err
echo "B exit $?"

step C: the budget on the old kernel
cd $B/bench-hashes
cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/C-samples > $out/C.out 2> $out/C.err
echo "C exit $?"
./target/release/bench-hashes compare $out/C-samples/run-*-old.tsv -- $out/C-samples/run-*-new.tsv > $out/C-compare.out 2>&1

step D: CLI with against without
cd $W/bench-hashes
CLI=/root/results/wide-cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py /root/BLAKE3-round-pr164 $CLI $KONLY $(git -C $W rev-parse HEAD) > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; exit 30; }
k=${KONLY:0:7}; n=$(git -C $W rev-parse --short=7 HEAD)
sleep 20
for r in 1 2; do
  args=(); for i in 0 1 2 3; do args+=("without=$CLI/b3sum-$k-L$i"); done; for i in 0 1 2 3; do args+=("with=$CLI/b3sum-$n-L$i"); done
  cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/D-r$r.out 2> $out/D-r$r.err
  echo "D r$r exit $?"
  mkdir -p $out/D-r$r-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/D-r$r-results/
  git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
done

step E: energy at medium sizes
E=$out/energy; mkdir -p $E
for s in 1 2 4 8; do head -c $((s<<20)) /dev/urandom > /dev/shm/budget-$s; done
perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/idle.txt sleep 2
for rep in 1 2 3 4 5; do
  for side in without:$CLI/b3sum-$k-L0 with:$CLI/b3sum-$n-L0; do
    nm=${side%%:*}; BIN=${side#*:}
    for s in 1 2 4 8; do
      perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$nm-$s-r$rep.txt bash -c "for i in \$(seq 200); do $BIN /dev/shm/budget-$s > /dev/null; done"
    done
  done
done
rm -f /dev/shm/budget-*
step done; date -u
