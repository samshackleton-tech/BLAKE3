#!/bin/bash
# The general tree-thread budget on the current candidate (#125):
#   C0 = john candidate/release-0.8 351c679 (the wide kernel, FANOUT 8, the
#        x86-Linux-AVX-512 budget: one 128 KiB piece a thread, any length)
#   C1 = efa4e28 (experiment/sam-budget-general-rc): C0 with the budget on every
#        target, below 2 MiB one 64 KiB share a thread, every thread from 2 MiB
# Tests, the AVX-512 cross-check of the model, then C1 against C0 on the EPYC:
# check, pool cells, emulated machines, CLI, energy. Measurement only.
set -u
out=/root/results/wide-20261025/rc-general
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
R=/root/BLAKE3-round-pr164
step setup
git -C $R fetch -q https://github.com/samshackleton-tech/BLAKE3 experiment/sam-budget-general-rc:refs/heads/experiment/sam-budget-general-rc || exit 10
git -C $R fetch -q https://github.com/johnservil/BLAKE3 candidate/release-0.8 || exit 10
C1D=/root/BLAKE3-budget-general-rc
[ -d $C1D ] || git -C $R worktree add -q --detach $C1D experiment/sam-budget-general-rc || exit 11
C1=$(git -C $C1D rev-parse HEAD); C0=$(git -C $C1D rev-parse HEAD^)
[ "${C0:0:7}" = 351c679 ] || { echo "C1's parent is $C0, not 351c679"; exit 12; }
{ date -u; echo "C0 $C0"; echo "C1 $C1"; git -C $C1D diff $C0 $C1 -- src/lanes.rs; git -C $C1D status --short; } > $out/provenance.txt 2>&1

step tests
cd $C1D; T=/root/target-rc-general; st=0; o=$out/tests; mkdir -p $o
(CARGO_TARGET_DIR=$T cargo nextest run --release > $o/default.log 2>&1) & p1=$!
(CARGO_TARGET_DIR=$T-debug cargo nextest run > $o/debug.log 2>&1) & p2=$!
(CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $o/pure.log 2>&1) & p3=$!
(CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > $o/no_std.log 2>&1) & p4=$!
(CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $o/capi.log 2>&1) & p5=$!
(CARGO_TARGET_DIR=$T-doc cargo test --doc > $o/doc.log 2>&1) & p6=$!
(python3 -m unittest discover -s tools/verify -p 'test_*.py' > $o/verify-helpers.log 2>&1) & p7=$!
for p in $p1 $p2 $p3 $p4 $p5 $p6 $p7; do wait $p || st=1; done
RUSTFLAGS="--cfg shuttle" CARGO_TARGET_DIR=$T-shuttle cargo test --release --test shuttle_park > $o/shuttle.log 2>&1 || st=1
CARGO_TARGET_DIR=$T-builds bash tools/check-builds.sh > $o/check-builds.log 2>&1 || st=1
CARGO_TARGET_DIR=$T-miri timeout 2400 cargo +nightly-2026-10-24 miri test --lib tree_thread_budget > $o/miri-budget.log 2>&1 || st=1
grep -hE 'Summary|test result:|^Ran |^OK|FAILED' $o/*.log > $o/summary.txt
echo "tests status $st"
step cross-check the x86 model on this AVX-512 CPU
(python3 tools/verify/cross_check_x86.py > $out/cross-check-x86.log 2>&1); echo "cross-check exit $?"
tail -5 $out/cross-check-x86.log
[ $st = 0 ] || { echo "tests failed: no timing"; exit 20; }

[ -d $C1D/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $C1D/bench-hashes
git -C $C1D/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
sleep 30
cd $C1D/bench-hashes
step check C1 against C0
cargo run --release -- check --against $C0 --cells all --pairs 12 --keep $out/check-samples > $out/check.out 2> $out/check.err
echo "check exit $?"
./target/release/bench-hashes compare $out/check-samples/run-*-old.tsv -- $out/check-samples/run-*-new.tsv > $out/check-compare.out 2>&1
POINTS="512 KiB,1 MiB,2 MiB,3 MiB,4 MiB,8 MiB,32 MiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,idle 3 MiB,idle 4 MiB,idle 8 MiB,lent 1 MiB,lent 4 MiB,merkle 4096,merkle 16384"
mapfile -t olds < <(ls $C1D/target/check/old/bench-hashes-* | sort -V | tail -16)
mapfile -t news < <(ls $C1D/target/check/new/bench-hashes-* | sort -V | tail -16)
step pool cells 32 pairs
./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs 32 --keep $out/pool-samples "${olds[@]}" "${olds[@]}" -- "${news[@]}" "${news[@]}" > $out/pool.out 2> $out/pool.err
echo "pool exit $?"
./target/release/bench-hashes compare $out/pool-samples/run-*-old.tsv -- $out/pool-samples/run-*-new.tsv > $out/pool-compare.out 2>&1
for cfg in t8:8: t16:16: t24on12:24:0-11,24-35; do
  IFS=: read name n cpus <<< "$cfg"
  wd=$out/emu-$name/bin; mkdir -p $wd; eo=(); en=()
  for i in $(seq 0 15); do
    for side in old new; do
      if [ $side = old ]; then exe=${olds[$i]}; else exe=${news[$i]}; fi
      if [ -n "$cpus" ]; then printf '#!/bin/sh\nexec taskset -c %s %s --threads %s "$@"\n' "$cpus" "$exe" "$n" > $wd/$side-$i
      else printf '#!/bin/sh\nexec %s --threads %s "$@"\n' "$exe" "$n" > $wd/$side-$i; fi
      chmod +x $wd/$side-$i
    done
    eo+=($wd/old-$i); en+=($wd/new-$i)
  done
  step emulated $name
  ./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs 16 --keep $out/emu-$name/samples "${eo[@]}" -- "${en[@]}" > $out/emu-$name/regress.out 2> $out/emu-$name/regress.err
  echo "emu $name exit $?"
  ./target/release/bench-hashes compare $out/emu-$name/samples/run-*-old.tsv -- $out/emu-$name/samples/run-*-new.tsv > $out/emu-$name/compare.out 2>&1
done
step CLI
CLI=/root/results/wide-cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py $R $CLI $C0 $C1 > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; exit 30; }
o=${C0:0:7}; n=${C1:0:7}
sleep 10
for r in 1 2; do
  args=(); for i in 0 1 2 3; do args+=("candidate=$CLI/b3sum-$o-L$i"); done; for i in 0 1 2 3; do args+=("general=$CLI/b3sum-$n-L$i"); done
  cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/cli-r$r.out 2> $out/cli-r$r.err
  echo "cli r$r exit $?"
  mkdir -p $out/cli-r$r-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/cli-r$r-results/
  git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
done
step energy
E=$out/energy; mkdir -p $E
for s in 1 2 4 8; do head -c $((s<<20)) /dev/urandom > /dev/shm/budget-$s; done
perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/idle.txt sleep 2
for rep in 1 2 3 4 5; do
  for side in candidate:$CLI/b3sum-$o-L0 general:$CLI/b3sum-$n-L0; do
    nm=${side%%:*}; BIN=${side#*:}
    for s in 1 2 4 8; do
      perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$nm-$s-r$rep.txt bash -c "for i in \$(seq 200); do $BIN /dev/shm/budget-$s > /dev/null; done"
    done
  done
done
rm -f /dev/shm/budget-*
step done; date -u
