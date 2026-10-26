#!/bin/bash
set -u
out=/root/results/nst-8c34; mkdir -p $out
exec > $out/runner.log 2>&1
. /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
exec 9>/root/bench-native-afk.lock; flock -w 600 9 || exit 75
R=/root/BLAKE3-round-pr164
git -C $R fetch -q /root/nst.bundle HEAD:refs/heads/experiment/sam-no-wide-selftest || exit 10
A=$(git -C $R rev-parse experiment/sam-no-wide-selftest); echo "ablation $A"
cd /root/BLAKE3-rc-8c34/bench-hashes
CLI=/root/results/wide-cli-bin
LAYOUTS=4 python3 tools/b3sum-contenders.py $R $CLI $A 8c34ead4cf275289e4f405b409feca327c5c7828 > $out/contenders.txt 2> $out/build.log || { echo build failed; tail $out/build.log; exit 30; }
a=${A:0:7}
head -c $((1<<30)) /dev/urandom > /dev/shm/nst-1g
for b in $CLI/b3sum-0754066-L0 $CLI/b3sum-8c34ead-L0 $CLI/b3sum-$a-L0; do echo "$($b /dev/shm/nst-1g | cut -c1-64) $b"; done > $out/digests.txt
rm -f /dev/shm/nst-1g
[ $(cut -d' ' -f1 $out/digests.txt | sort -u | wc -l) = 1 ] || { echo "digests differ"; exit 31; }
sleep 10
for r in 1 2 3; do
  args=(); for i in 0 1 2 3; do args+=("old=$CLI/b3sum-0754066-L$i"); done
  for i in 0 1 2 3; do args+=("new=$CLI/b3sum-8c34ead-L$i"); done
  for i in 0 1 2 3; do args+=("noselftest=$CLI/b3sum-$a-L$i"); done
  cargo run --release -- b3sum --rounds 16 "${args[@]}" > $out/r$r.out 2> $out/r$r.err
  echo "r$r exit $?"
  mkdir -p $out/r$r; cp -a benchmark-results/AMDEPYC*/b3sum.* $out/r$r/
  git checkout -q -- benchmark-results; git clean -q -fd benchmark-results
done
date -u
