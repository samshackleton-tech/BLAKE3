#!/bin/bash
# Is the candidate's tree-thread budget (351c679: one 128 KiB piece a thread)
# safe on machine shapes we don't have? 351c679 against the same with no
# budget (9b82d0d), on the EPYC and on emulated machines. Plus the tests of
# 7958582 (the same rule on every target), including pure (degree 1, now
# budgeted) and Miri. Measurement only; existing tools.
set -u
out=/root/results/wide-20261025/cand-vs-none
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
for b in nobudget ungated; do git -C $R fetch -q /root/b-$b.bundle HEAD:refs/heads/experiment/sam-budget-$b || exit 10; done
C=/root/BLAKE3-cand-351; U=/root/BLAKE3-budget-ungated
[ -d $C ] || git -C $R worktree add -q --detach $C 351c6799c5d88c060814eedf37017ada0dacf71a || exit 11
[ -d $U ] || git -C $R worktree add -q --detach $U experiment/sam-budget-ungated || exit 11
NONE=$(git -C $R rev-parse experiment/sam-budget-nobudget)
[ "$(git -C $R rev-parse $NONE^)" = "$(git -C $C rev-parse HEAD)" ] || exit 12
[ "$(git -C $U rev-parse HEAD^)" = "$(git -C $C rev-parse HEAD)" ] || exit 12
{ date -u; echo "candidate $(git -C $C rev-parse HEAD)"; echo "none $NONE"; echo "ungated $(git -C $U rev-parse HEAD)"; git -C $R diff $NONE^ $NONE; git -C $R diff $NONE^ experiment/sam-budget-ungated; } > $out/provenance.txt 2>&1

step tests of the ungated rule
cd $U; T=/root/target-ungated; st=0; o=$out/tests-ungated; mkdir -p $o
(CARGO_TARGET_DIR=$T cargo nextest run --release > $o/default.log 2>&1) & p1=$!
(CARGO_TARGET_DIR=$T-pure cargo nextest run --release --features pure > $o/pure.log 2>&1) & p2=$!
(CARGO_TARGET_DIR=$T-pure-debug cargo nextest run --features pure > $o/pure-debug.log 2>&1) & p3=$!
(CARGO_TARGET_DIR=$T-nostd cargo nextest run --release --no-default-features > $o/no_std.log 2>&1) & p4=$!
(CARGO_TARGET_DIR=$T-capi cargo nextest run --release --manifest-path capi/Cargo.toml > $o/capi.log 2>&1) & p5=$!
for p in $p1 $p2 $p3 $p4 $p5; do wait $p || st=1; done
CARGO_TARGET_DIR=$T-miri timeout 2400 cargo +nightly-2026-10-24 miri test --lib tree_thread_budget > $o/miri-budget.log 2>&1 || st=1
grep -hE 'Summary|test result:' $o/*.log > $o/summary.txt
echo "tests status $st"

[ -d $C/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $C/bench-hashes
git -C $C/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
sleep 30
cd $C/bench-hashes
step check candidate against none
cargo run --release -- check --against $NONE --cells all --pairs 12 --keep $out/check-samples > $out/check.out 2> $out/check.err
echo "check exit $?"
./target/release/bench-hashes compare $out/check-samples/run-*-old.tsv -- $out/check-samples/run-*-new.tsv > $out/check-compare.out 2>&1
POINTS="512 KiB,1 MiB,2 MiB,3 MiB,4 MiB,8 MiB,32 MiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,idle 3 MiB,idle 4 MiB,idle 8 MiB,lent 1 MiB,lent 4 MiB,merkle 4096,merkle 16384"
mapfile -t olds < <(ls $C/target/check/old/bench-hashes-* | sort -V)
mapfile -t news < <(ls $C/target/check/new/bench-hashes-* | sort -V)
N=$(( ${#olds[@]} < ${#news[@]} ? ${#olds[@]} : ${#news[@]} ))
echo "$N relinked builds a side"
step pool cells
./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs $((2*N)) --keep $out/pool-samples "${olds[@]:0:N}" "${olds[@]:0:N}" -- "${news[@]:0:N}" "${news[@]:0:N}" > $out/pool.out 2> $out/pool.err
echo "pool exit $?"
./target/release/bench-hashes compare $out/pool-samples/run-*-old.tsv -- $out/pool-samples/run-*-new.tsv > $out/pool-compare.out 2>&1
for cfg in t4:4: t8:8: t16:16: t24on12:24:0-11,24-35 t12on6:12:0-5,24-29; do
  IFS=: read name n cpus <<< "$cfg"
  wd=$out/emu-$name/bin; mkdir -p $wd; eo=(); en=()
  for i in $(seq 0 $((N-1))); do
    for side in old new; do
      if [ $side = old ]; then exe=${olds[$i]}; else exe=${news[$i]}; fi
      if [ -n "$cpus" ]; then printf '#!/bin/sh\nexec taskset -c %s %s --threads %s "$@"\n' "$cpus" "$exe" "$n" > $wd/$side-$i
      else printf '#!/bin/sh\nexec %s --threads %s "$@"\n' "$exe" "$n" > $wd/$side-$i; fi
      chmod +x $wd/$side-$i
    done
    eo+=($wd/old-$i); en+=($wd/new-$i)
  done
  step emulated $name
  ./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs $N --keep $out/emu-$name/samples "${eo[@]}" -- "${en[@]}" > $out/emu-$name/regress.out 2> $out/emu-$name/regress.err
  echo "emu $name exit $?"
  ./target/release/bench-hashes compare $out/emu-$name/samples/run-*-old.tsv -- $out/emu-$name/samples/run-*-new.tsv > $out/emu-$name/compare.out 2>&1
done
step CLI
CLI=/root/results/wide-cli-bin
CAND=$(git -C $C rev-parse HEAD)
LAYOUTS=4 python3 tools/b3sum-contenders.py $R $CLI $NONE $CAND > $out/cli-contenders.txt 2> $out/cli-build.log || { echo "cli build failed"; exit 30; }
o=${NONE:0:7}; n=${CAND:0:7}
sleep 10
for r in 1 2; do
  args=(); for i in 0 1 2 3; do args+=("none=$CLI/b3sum-$o-L$i"); done; for i in 0 1 2 3; do args+=("candidate=$CLI/b3sum-$n-L$i"); done
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
  for side in none:$CLI/b3sum-$o-L0 candidate:$CLI/b3sum-$n-L0; do
    nm=${side%%:*}; BIN=${side#*:}
    for s in 1 2 4 8; do
      perf stat -a -e power/energy-pkg/,power_core/energy-core/ -o $E/$nm-$s-r$rep.txt bash -c "for i in \$(seq 200); do $BIN /dev/shm/budget-$s > /dev/null; done"
    done
  done
done
rm -f /dev/shm/budget-*
step done; date -u
