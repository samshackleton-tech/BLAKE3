#!/bin/bash
# Refined tree-thread budgets (#125, option 3), each on the wide kernel,
# each judged against the wide kernel WITHOUT a budget (433502a):
#   below-2m (787aeb7): one 128 KiB piece a thread, only below 2 MiB
#   64k      (8d456bf): one 64 KiB unit a thread (twice the threads)
# Per variant: check --cells all --pairs 12; the pool cells on 32 pairs;
# the CLI once; energy at 1-8 MiB. Same tools and points as budget-campaign.sh.
set -u
out=/root/results/wide-20261025/variants
mkdir -p $out
exec > $out/campaign.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com'
export GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || exit 75
KONLY=$(git -C /root/BLAKE3-wide-konly rev-parse HEAD)
CLI=/root/results/wide-cli-bin
POINTS="512 KiB,1 MiB,2 MiB,3 MiB,4 MiB,8 MiB,32 MiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,idle 3 MiB,idle 4 MiB,idle 8 MiB,lent 1 MiB,lent 4 MiB,merkle 4096,merkle 16384"
for v in below-2m 64k; do
  D=/root/BLAKE3-budget-$v; o=$out/$v; mkdir -p $o
  [ -d $D/bench-hashes ] || git clone -q /root/BLAKE3-wide-new/bench-hashes $D/bench-hashes
  git -C $D/bench-hashes checkout -q --detach d21cdf36dfc02716e173be4e5b4590c04361084a
  { date -u; echo "variant $(git -C $D rev-parse HEAD)"; echo "against $KONLY"; git -C $D diff $KONLY HEAD -- src/lanes.rs | head -80; git -C $D status --short; } > $o/provenance.txt 2>&1
  sleep 20
  cd $D/bench-hashes
  step $v check
  cargo run --release -- check --against $KONLY --cells all --pairs 12 --keep $o/check-samples > $o/check.out 2> $o/check.err
  echo "$v check exit $?"
  ./target/release/bench-hashes compare $o/check-samples/run-*-old.tsv -- $o/check-samples/run-*-new.tsv > $o/check-compare.out 2>&1
  step $v pool cells 32 pairs
  mapfile -t olds < <(ls $D/target/check/old/bench-hashes-* | sort -V | tail -16)
  mapfile -t news < <(ls $D/target/check/new/bench-hashes-* | sort -V | tail -16)
  ./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs 32 --keep $o/pool-samples "${olds[@]}" "${olds[@]}" -- "${news[@]}" "${news[@]}" > $o/pool.out 2> $o/pool.err
  echo "$v pool exit $?"
  # Emulated machines (robustness, #125): a pool of 8 threads, of 16, and
  # 24 threads squeezed onto 12 cores (two a core: slower threads, SMT
  # contention). The same relinked builds, wrapped; 16 pairs, pool cells.
  for cfg in t8:8: t16:16: t24on12:24:0-11,24-35; do
    IFS=: read name n cpus <<< "$cfg"
    wd=$o/emu-$name/bin; mkdir -p $wd
    eo=(); en=()
    for i in $(seq 0 15); do
      for side in old new; do
        if [ $side = old ]; then exe=${olds[$i]}; else exe=${news[$i]}; fi
        if [ -n "$cpus" ]; then
          printf '#!/bin/sh\nexec taskset -c %s %s --threads %s "$@"\n' "$cpus" "$exe" "$n" > $wd/$side-$i
        else
          printf '#!/bin/sh\nexec %s --threads %s "$@"\n' "$exe" "$n" > $wd/$side-$i
        fi
        chmod +x $wd/$side-$i
      done
      eo+=($wd/old-$i); en+=($wd/new-$i)
    done
    step $v emulated $name
    ./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs 16 --keep $o/emu-$name/samples "${eo[@]}" -- "${en[@]}" > $o/emu-$name/regress.out 2> $o/emu-$name/regress.err
    echo "$v emu $name exit $?"
  done
  step $v CLI
  LAYOUTS=4 python3 tools/b3sum-contenders.py /root/BLAKE3-round-pr164 $CLI $KONLY $(git -C $D rev-parse HEAD) > $o/cli-contenders.txt 2> $o/cli-build.log || { echo "cli build failed"; continue; }
  k=${KONLY:0:7}; n=$(git -C $D rev-parse --short=7 HEAD)
  sleep 10
  args=(); for i in 0 1 2 3; do args+=("without=$CLI/b3sum-$k-L$i"); done; for i in 0 1 2 3; do args+=("$v=$CLI/b3sum-$n-L$i"); done
  cargo run --release -- b3sum --rounds 16 "${args[@]}" > $o/cli.out 2> $o/cli.err
  echo "$v cli exit $?"
  mkdir -p $o/cli-results; cp -a benchmark-results/AMDEPYC*/b3sum.* $o/cli-results/
  git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
  step $v energy
  E=$o/energy; mkdir -p $E
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
done
step done; date -u
