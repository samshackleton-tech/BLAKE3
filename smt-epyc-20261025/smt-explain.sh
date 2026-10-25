#!/bin/bash
# SMT diagnostic on the EPYC 9255 (24 cores, siblings n and n+24), at the 0.8
# candidate. Measurement only: existing binaries, perf's counters, and the
# bench's own regress/compare. No code under test changes.
#   Part 1: one thread's kernel speed under SMT (b3sum --num-threads 1)
#   Part 2: the candidate's pool, by thread count and placement (b3sum)
#   Part 3: the library's mt cells, 48 against 24 threads one per core (regress)
set -u
out=/root/results/smt-20261025
mkdir -p "$out"
exec > "$out/runner.log" 2>&1
. /root/.cargo/env
step() { echo "== $* $(date -u +%T)"; }
exec 9>/root/bench-native-afk.lock
flock -w 3600 9 || { echo "bench lock busy"; exit 75; }

step setup
LIB=/root/BLAKE3-release-08            # ee4c0d7, the measured release candidate
[ "$(git -C $LIB rev-parse HEAD)" = ee4c0d7c27c4bfd5aa65973468c977dc08c848bb ] || exit 10
CARGO_TARGET_DIR=/root/target-smt-b3sum cargo build -q --release --manifest-path $LIB/b3sum/Cargo.toml > "$out/build.log" 2>&1 || exit 11
CAND=/root/target-smt-b3sum/release/b3sum
OFF=/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0
BASE=/root/results/avx512-registers/cli-layouts16/cli-bin/b3sum-8e968d5-L0
WIDE=/root/results/avx512-registers/cli-layouts16/cli-bin/b3sum-215441f-L0
for b in $CAND $OFF $BASE $WIDE; do [ -x $b ] || exit 12; echo "$b $(sha256sum $b | cut -c1-16) $($b --version)"; done > "$out/binaries.txt"
for c in $(seq 0 47); do echo "$c $(cat /sys/devices/system/cpu/cpu$c/topology/thread_siblings_list) $(cat /sys/devices/system/cpu/cpu$c/cache/index3/shared_cpu_list)"; done > "$out/topology.txt"
{ date -u; uptime; lscpu; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor; rustc -V; perf --version; } > "$out/machine.txt" 2>&1
F1=/dev/shm/smt-1g; F=/dev/shm/smt
head -c $((1<<30)) /dev/urandom > $F1
for s in 4 16 256 1024; do head -c $((s<<20)) $F1 > $F-$s; done
sync; sleep 30

# perf stat for one process, pinned: user cycles/instructions (the hashing,
# without the kernel's page faults), task-clock, faults.
EV=task-clock,cycles:u,instructions:u,cycles,page-faults
runp() { # $1 out file, $2 cpu list, rest: command
  local o=$1 cpus=$2; shift 2
  taskset -c "$cpus" perf stat -x, -e $EV -o "$o" "$@" > /dev/null
}

step part1 kernels
P1=$out/part1; mkdir -p $P1
declare -A KER=([candidate]=$CAND [official]=$OFF [baseline]=$BASE [wide]=$WIDE)
for rep in 1 2 3 4 5; do
  for k in candidate official baseline wide; do
    b=${KER[$k]}
    # solo
    runp $P1/$k-solo-r$rep-c0.csv 0 $b --num-threads 1 $F1
    # SMT siblings
    runp $P1/$k-siblings-r$rep-c0.csv 0 $b --num-threads 1 $F1 & runp $P1/$k-siblings-r$rep-c24.csv 24 $b --num-threads 1 $F1 & wait
    # separate cores
    runp $P1/$k-separate-r$rep-c0.csv 0 $b --num-threads 1 $F1 & runp $P1/$k-separate-r$rep-c1.csv 1 $b --num-threads 1 $F1 & wait
    # every core once
    for c in $(seq 0 23); do runp $P1/$k-cores24-r$rep-c$c.csv $c $b --num-threads 1 $F1 & done; wait
    # every logical CPU
    for c in $(seq 0 47); do runp $P1/$k-cpus48-r$rep-c$c.csv $c $b --num-threads 1 $F1 & done; wait
  done
done

step part2 pool
P2=$out/part2; mkdir -p $P2
# name : thread count : cpu list
CONFIGS="t48-all:48:0-47 t24-unpinned:24:0-47 t24-cores:24:0-23 t36-mixed:36:0-35 t24-siblings12:24:0-11,24-35"
for rep in $(seq 1 9); do
  for s in 4 16 256 1024; do
    for cfg in $CONFIGS; do
      IFS=: read name n cpus <<< "$cfg"
      taskset -c $cpus perf stat -o $P2/$name-$s-r$rep.txt $CAND --num-threads $n $F-$s > /dev/null
    done
  done
done

step part3 library cells
P3=$out/part3; mkdir -p $P3/bin
builds=$LIB/target/check/new
cores=$(seq -s, 0 23)
old=(); new=()
for i in $(seq 0 7); do
  b=$(ls $builds/bench-hashes-* | sort -V | sed -n "$((i+1))p")
  printf '#!/bin/sh\nexec %s --threads 48 "$@"\n' "$b" > $P3/bin/t48-$i
  printf '#!/bin/sh\nexec taskset -c %s %s --threads 24 "$@"\n' "$cores" "$b" > $P3/bin/t24cores-$i
  chmod +x $P3/bin/t48-$i $P3/bin/t24cores-$i
  old+=($P3/bin/t48-$i); new+=($P3/bin/t24cores-$i)
done
ls -l $builds/bench-hashes-* | head -8 > $P3/builds.txt
cd $LIB/bench-hashes
./target/release/bench-hashes regress --contenders blake3-servil-mt --pairs 8 --keep $P3/samples "${old[@]}" -- "${new[@]}" > $P3/regress.out 2> $P3/regress.err
echo "part3 regress exit $?"
./target/release/bench-hashes compare $P3/samples/run-*-old.tsv -- $P3/samples/run-*-new.tsv > $P3/compare.out 2> $P3/compare.err
echo "part3 compare exit $?"
rm -f $F1 $F-4 $F-16 $F-256 $F-1024
step done; uptime
