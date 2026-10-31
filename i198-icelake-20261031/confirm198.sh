#!/bin/bash
# 24 pairs, A/B and A/A, on a verified run's check builds (one socket): the cells slower in both Ice Lake checks.
set -u
RUN=$1; D=$RUN/src; C=$D/target/check; out=$RUN-confirm; mkdir -p $out; exec > $out/runner.log 2>&1
list() { python3 -c '
import os,re,sys
d=sys.argv[1]
ks=sorted(int(n[len("bench-hashes-"):]) for n in os.listdir(d) if re.fullmatch(r"bench-hashes-\d+",n))
print(" ".join(os.path.join(d,"bench-hashes-%d" % k) for k in ks))' $1; }
old=($(list $C/old)); new=($(list $C/new)); h=$((${#old[@]}/2)); N0=$(cat /sys/devices/system/node/node0/cpulist)
J="blake3-servil-mt|shared|LentMessages|64 MiB;blake3-servil-mt|solo|LentMessages|64 MiB;blake3-servil-mt|solo|OneMessage|2 MiB;blake3-servil-st|shared|ContinuousBatches|65536;blake3-servil-mt|solo|ManyMessages|16384"
X=$D/bench-hashes/target/release/bench-hashes
exec 9>/root/bench-native-afk.lock; flock -w 3600 9 || exit 75
cd $D/bench-hashes
for cpus in all "$N0"; do tag=$([ "$cpus" = all ] && echo all || echo node0); pre=(); [ "$cpus" != all ] && pre=(taskset -c "$cpus")
 "${pre[@]}" $X regress --contenders blake3-servil-mt,blake3-servil-st --points "lent 64 MiB,2 MiB,continuous batch 65536,16384" --judge "$J" --pairs 24 --keep $out/$tag-ab "${old[@]}" -- "${new[@]}" > $out/$tag-ab.out 2>&1; echo "$tag ab exit $?"
 "${pre[@]}" $X regress --contenders blake3-servil-mt,blake3-servil-st --points "lent 64 MiB,2 MiB,continuous batch 65536,16384" --judge "$J" --pairs 24 --keep $out/$tag-aa "${old[@]:0:$h}" -- "${old[@]:$h:$h}" > $out/$tag-aa.out 2>&1; echo "$tag aa exit $?"
done
git checkout -q -- index.html 2>/dev/null; date -u
