#!/bin/bash
# st ManyMessages 2/4/6/12 and IdleManyMessages 2/3 solo: A/B (old vs new builds of the
# b52735e9 check, 24 pairs) and A/A (old builds against old builds).
set -u
RUN=$1; D=$RUN/src; C=$D/target/check; out=$RUN-mm-confirm; mkdir -p $out; exec > $out/runner.log 2>&1
list() { python3 -c '
import os,re,sys
d=sys.argv[1]
ks=sorted(int(n[len("bench-hashes-"):]) for n in os.listdir(d) if re.fullmatch(r"bench-hashes-\d+",n))
print(" ".join(os.path.join(d,"bench-hashes-%d" % k) for k in ks))' $1; }
old=($(list $C/old)); new=($(list $C/new)); echo "builds ${#old[@]} old ${#new[@]} new"
h=$((${#old[@]}/2))
J="blake3-servil-st|solo|ManyMessages|2;blake3-servil-st|solo|ManyMessages|4;blake3-servil-st|solo|ManyMessages|6;blake3-servil-st|solo|ManyMessages|12;blake3-servil-st|solo|IdleManyMessages|2;blake3-servil-st|solo|IdleManyMessages|3"
X=$D/bench-hashes/target/release/bench-hashes
exec 9>/root/bench-native-afk.lock; flock -w 3600 9 || exit 75
cd $D/bench-hashes
$X regress --contenders blake3-servil-st --points 2,4,6,12,"idle 2","idle 3" --judge "$J" --pairs 24 --keep $out/ab "${old[@]}" -- "${new[@]}" > $out/ab.out 2> $out/ab.err; echo "ab exit $?"
$X regress --contenders blake3-servil-st --points 2,4,6,12,"idle 2","idle 3" --judge "$J" --pairs 24 --keep $out/aa "${old[@]:0:$h}" -- "${old[@]:$h:$h}" > $out/aa.out 2> $out/aa.err; echo "aa exit $?"
git checkout -q -- index.html 2>/dev/null; date -u
