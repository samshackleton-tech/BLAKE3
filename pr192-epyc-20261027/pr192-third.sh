#!/bin/bash
# #192: a third stage on check's ManyMessages suspects (second stage: 3 +8.7%,
# 4 +7.9% median, judged not slower). Same builds check made (matching layout
# seeds, old i against new i), 24 pairs, mt only, the ManyMessages points.
set -u
export HOME=/root
J=/root/results/latest-20261024/job-tool/tools/jobs.py
while python3 $J status night3 | grep -q running; do sleep 30; done
out=/root/results/pr192-third; mkdir -p $out
exec > $out/runner.log 2>&1
C=/root/BLAKE3-fork-panic/target/check
# check numbers its builds across both sides (each a random layout); regress
# pairs the i-th old with the i-th new, so list each side in numeric order.
list() { python3 -c '
import os,re,sys
d=sys.argv[1]
ks=sorted(int(n[len("bench-hashes-"):]) for n in os.listdir(d) if re.fullmatch(r"bench-hashes-\d+",n))
print(" ".join(os.path.join(d,"bench-hashes-%d" % k) for k in ks))' $1; }
old=($(list $C/old)); new=($(list $C/new))
echo "builds: ${#old[@]} old, ${#new[@]} new"
[ ${#old[@]} -gt 0 ] && [ ${#old[@]} = ${#new[@]} ] || exit 9
# Wait for the machine to settle (a mutation run's tail can outlast its job).
for i in $(seq 1 60); do l=$(cut -d" " -f1 /proc/loadavg); python3 -c "import sys; sys.exit(0 if float('$l') < 1.5 else 1)" && break; sleep 30; done
judge=""; for p in 2 3 4 6 8 12 16 24 48; do judge="$judge;blake3-servil-mt|solo|ManyMessages|$p"; done; judge=${judge#;}
exec 9>/root/bench-native-afk.lock; flock -w 3600 9 || exit 75
date -u; uptime
cd /root/BLAKE3-fork-panic/bench-hashes
./target/release/bench-hashes regress --contenders blake3-servil-mt --points 2,3,4,6,8,12,16,24,48 \
  --judge "$judge" --pairs 24 --keep $out/samples "${old[@]}" -- "${new[@]}" > $out/regress.out 2> $out/regress.err
echo "regress exit $?"; date -u; uptime
git checkout -q -- index.html 2>/dev/null
