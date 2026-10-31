#!/bin/bash
# BLAKE3 #198/#199: is the slowdown a commit's or the pool's placement?
#  1. the release check, 0.8's tag against candidate/base-0.8 (bench 0.18.3 nested), every cell;
#  2. the issue's cell (CELL, its contender and point) on that check's own builds, 24 pairs:
#     default placement, one L3 domain (CPU 0's), and one NUMA node (node 0) where there are
#     several; each beside an A/A control (old builds against old).
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
{ git -C "$R/src" log -1 --format=%H; git -C "$R/src/bench-hashes" log -1 --format=%H; grep -m1 'model name' /proc/cpuinfo; nproc; sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; } > "$O/provenance.txt"
cd "$R/src"; git fetch -q https://github.com/johnservil/BLAKE3 candidate/base-0.8 || exit 2
cd "$R/src/bench-hashes"; git fetch -q https://github.com/johnservil/bench-hashes candidate/bench-blocks-old-side || exit 2
cargo build --release > "$O/bench-build.log" 2>&1 || exit 3
sleep 30
cargo run --release -- check --against bfbda1920283335ff3802723db11c209159f47fc --old-bench 5be5f23699ee7146ada56a08777173a4ee1c7bde --cells all --keep "$O/check-samples" > "$O/check.out" 2> "$O/check.err"
echo "check exit $?" >> "$O/status.txt"
git checkout -q -- index.html 2>/dev/null
C=$R/src/target/check
list() { python3 -c '
import os,re,sys
d=sys.argv[1]
ks=sorted(int(n[len("bench-hashes-"):]) for n in os.listdir(d) if re.fullmatch(r"bench-hashes-\d+",n))
print(" ".join(os.path.join(d,"bench-hashes-%d" % k) for k in ks))' $1; }
old=($(list $C/old)); new=($(list $C/new)); h=$((${#old[@]}/2))
L3=$(cat /sys/devices/system/cpu/cpu0/cache/index3/shared_cpu_list)
NODES=$(ls -d /sys/devices/system/node/node[0-9]* | wc -l); N0=$(cat /sys/devices/system/node/node0/cpulist)
echo "L3 of CPU 0: $L3; nodes $NODES, node 0: $N0" > "$O/topology.txt"
X=./target/release/bench-hashes
place() { name=$1; cpus=$2; for k in ab aa; do
  if [ $k = ab ]; then a=("${old[@]}"); b=("${new[@]}"); else a=("${old[@]:0:$h}"); b=("${old[@]:$h:$h}"); fi
  if [ "$cpus" = all ]; then pre=(); else pre=(taskset -c "$cpus"); fi
  "${pre[@]}" $X regress --contenders "$CONTENDER" --points "$POINT" --judge "$CELL" --pairs 24 --keep "$O/$name-$k" "${a[@]}" -- "${b[@]}" > "$O/$name-$k.out" 2> "$O/$name-$k.err"
  echo "$name $k exit $?" >> "$O/status.txt"
done; }
place default all
place l3 "$L3"
[ "$NODES" -gt 1 ] && place node0 "$N0"
git checkout -q -- index.html 2>/dev/null
echo done >> "$O/status.txt"
