#!/bin/bash
# The general tree-thread budget (#125): below 2 MiB one 128 KiB piece a
# participant, on every target but Miri. After variants-campaign.sh.
#   G  = experiment/sam-budget-general (195cba0): candidate/release-0.8 + FANOUT 8 + budget
#   WG = experiment/sam-wide-budget-general (8dfa687): the wide kernel + the same budget
# Tests both; then G against a9e70b8 (the EPYC row of the cross-machine runs):
# check, pool cells 32 pairs, emulated machines, CLI, energy.
set -u
out=/root/results/wide-20261025/general
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
sleep 300
exec 9>/root/bench-native-afk.lock
flock -w 21600 9 || exit 75
grep -q '== done' /root/results/wide-20261025/variants/campaign.log || { echo "variants campaign did not finish"; exit 21; }
R=/root/BLAKE3-round-pr164
step setup
git -C $R fetch -q https://github.com/samshackleton-tech/BLAKE3 experiment/sam-budget-general:refs/heads/experiment/sam-budget-general experiment/sam-wide-budget-general:refs/heads/experiment/sam-wide-budget-general || exit 10
for v in budget-general wide-budget-general; do
  [ -d /root/BLAKE3-$v ] || git -C $R worktree add -q --detach /root/BLAKE3-$v experiment/sam-$v || exit 11
done
G=/root/BLAKE3-budget-general; WG=/root/BLAKE3-wide-budget-general
OLD=$(git -C /root/BLAKE3-wide-new rev-parse HEAD^)
[ "$(git -C $G rev-parse HEAD^^)" = "$OLD" ] || { echo "G is not two commits on a9e70b8"; exit 12; }
{ date -u; echo "G $(git -C $G rev-parse HEAD)"; echo "WG $(git -C $WG rev-parse HEAD)"; echo "old $OLD"; git -C $G diff $OLD HEAD -- src/lanes.rs; } > $out/provenance.txt 2>&1

step tests
st=0
for v in budget-general wide-budget-general; do
  d=/root/BLAKE3-$v; T=/root/target-$v; o=$out/tests-$v; mkdir -p $o; cd $d
  (CARGO_TARGET_DIR=$T cargo nextest run --release > $o/default.log 2>&1) & p1=$!
  (CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $o/pure.log 2>&1) & p2=$!
  (CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > $o/no_std.log 2>&1) & p3=$!
  (CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $o/capi.log 2>&1) & p4=$!
  (CARGO_TARGET_DIR=$T-doc cargo test --doc > $o/doc.log 2>&1) & p5=$!
  for p in $p1 $p2 $p3 $p4 $p5; do wait $p || st=1; done
  CARGO_TARGET_DIR=$T-miri timeout 1800 cargo +nightly-2026-10-24 miri test --lib tree_thread_budget > $o/miri-budget.log 2>&1 || st=1
  grep -hE 'Summary|test result:' $o/*.log > $o/summary.txt
done
echo "tests status $st"; [ $st = 0 ] || exit 20

[ -d $G/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $G/bench-hashes
git -C $G/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
sleep 30
cd $G/bench-hashes
step G check against old
cargo run --release -- check --against $OLD --cells all --pairs 12 --keep $out/check-samples > $out/check.out 2> $out/check.err
echo "check exit $?"
./target/release/bench-hashes compare $out/check-samples/run-*-old.tsv -- $out/check-samples/run-*-new.tsv > $out/check-compare.out 2>&1
POINTS="512 KiB,1 MiB,2 MiB,3 MiB,4 MiB,8 MiB,32 MiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,idle 3 MiB,idle 4 MiB,idle 8 MiB,lent 1 MiB,lent 4 MiB,merkle 4096,merkle 16384"
mapfile -t olds < <(ls $G/target/check/old/bench-hashes-* | sort -V | tail -16)
mapfile -t news < <(ls $G/target/check/new/bench-hashes-* | sort -V | tail -16)
step pool cells 32 pairs
./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs 32 --keep $out/pool-samples "${olds[@]}" "${olds[@]}" -- "${news[@]}" "${news[@]}" > $out/pool.out 2> $out/pool.err
echo "pool exit $?"
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
done
step CLI
CLI=/root/results/wide-cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py $R $CLI $OLD $(git -C $G rev-parse HEAD) > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; exit 30; }
o=${OLD:0:7}; n=$(git -C $G rev-parse --short=7 HEAD)
sleep 10
for r in 1 2; do
  args=(); for i in 0 1 2 3; do args+=("old=$CLI/b3sum-$o-L$i"); done; for i in 0 1 2 3; do args+=("budget=$CLI/b3sum-$n-L$i"); done
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
  for side in without:$CLI/b3sum-$o-L0 with:$CLI/b3sum-$n-L0; do
    nm=${side%%:*}; BIN=${side#*:}
    for s in 1 2 4 8; do
      perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$nm-$s-r$rep.txt bash -c "for i in \$(seq 200); do $BIN /dev/shm/budget-$s > /dev/null; done"
    done
  done
done
rm -f /dev/shm/budget-*
step done; date -u
