#!/bin/bash
# A third stage on cells a check left unresolved: regress over the check's own
# builds (each side's random layouts, the i-th old against the i-th new),
# PAIRS pairs, the given contenders and points, judging the given cells.
# Usage: third-stage.sh CHECKOUT OUT CONTENDERS POINTS JUDGE [PAIRS]
#   CHECKOUT: the fork checkout whose target/check holds the builds
#   JUDGE: cells, ';'-separated, as regress --judge takes them
set -u
export HOME=/root
D=$1; out=$2; CONT=$3; POINTS=$4; JUDGE=$5; PAIRS=${6:-24}
mkdir -p $out; exec > $out/runner.log 2>&1
C=$D/target/check
list() { python3 -c '
import os,re,sys
d=sys.argv[1]
ks=sorted(int(n[len("bench-hashes-"):]) for n in os.listdir(d) if re.fullmatch(r"bench-hashes-\d+",n))
print(" ".join(os.path.join(d,"bench-hashes-%d" % k) for k in ks))' $1; }
old=($(list $C/old)); new=($(list $C/new))
echo "builds: ${#old[@]} old, ${#new[@]} new"
[ ${#old[@]} -gt 0 ] && [ ${#old[@]} = ${#new[@]} ] || exit 9
for i in $(seq 1 60); do l=$(cut -d" " -f1 /proc/loadavg); python3 -c "import sys; sys.exit(0 if float('$l') < 1.5 else 1)" && break; sleep 30; done
exec 9>/root/bench-native-afk.lock; flock -w 3600 9 || exit 75
date -u; uptime
cd $D/bench-hashes
./target/release/bench-hashes regress --contenders "$CONT" --points "$POINTS" --judge "$JUDGE" --pairs $PAIRS \
  --keep $out/samples "${old[@]}" -- "${new[@]}" > $out/regress.out 2> $out/regress.err
echo "regress exit $?"; date -u; uptime
git checkout -q -- index.html 2>/dev/null
