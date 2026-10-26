#!/bin/bash
# Candidate budget (351c679) vs none (9b82d0d), the cells near 1 MiB, more
# doubled-up machine shapes (threads:cpus). Existing relinked builds.
set -u
out=/root/results/wide-20261025/cand-vs-none/shapes; mkdir -p $out
exec > $out/runner.log 2>&1
exec 9>/root/bench-native-afk.lock; flock -w 600 9 || exit 75
C=/root/BLAKE3-cand-351; cd $C/bench-hashes
mapfile -t olds < <(ls $C/target/check/old/bench-hashes-* | sort -V)
mapfile -t news < <(ls $C/target/check/new/bench-hashes-* | sort -V)
N=$(( ${#olds[@]} < ${#news[@]} ? ${#olds[@]} : ${#news[@]} )); echo "N=$N"
POINTS="512 KiB,1 MiB,2 MiB,idle 512 KiB,idle 1 MiB,idle 2 MiB,lent 1 MiB"
for cfg in t16on8:16:0-7,24-31 t32on16:32:0-15,24-39 t48:48: t24on12b:24:0-11,24-35 t24on24:24:0-23 t12on12:12:0-11; do
  IFS=: read name n cpus <<< "$cfg"
  wd=$out/$name/bin; mkdir -p $wd; eo=(); en=()
  for i in $(seq 0 $((N-1))); do
    for side in old new; do
      if [ $side = old ]; then exe=${olds[$i]}; else exe=${news[$i]}; fi
      if [ -n "$cpus" ]; then printf '#!/bin/sh\nexec taskset -c %s %s --threads %s "$@"\n' "$cpus" "$exe" "$n" > $wd/$side-$i
      else printf '#!/bin/sh\nexec %s --threads %s "$@"\n' "$exe" "$n" > $wd/$side-$i; fi
      chmod +x $wd/$side-$i
    done
    eo+=($wd/old-$i); en+=($wd/new-$i)
  done
  ./target/release/bench-hashes regress --contenders blake3-servil-mt --points "$POINTS" --pairs $N --keep $out/$name/samples "${eo[@]}" -- "${en[@]}" > $out/$name/regress.out 2> $out/$name/regress.err
  echo "$name exit $?"
  ./target/release/bench-hashes compare $out/$name/samples/run-*-old.tsv -- $out/$name/samples/run-*-new.tsv > $out/$name/compare.out 2>&1
done
date -u
