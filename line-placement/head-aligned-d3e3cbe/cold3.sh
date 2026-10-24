r=/root/results/cold-aligned-pinned; rm -rf $r; mkdir -p $r
for n in 1 2 3; do for spec in base:/root/results/smalloc/align64/align64-base v3:/root/results/chunk-root/v3-aligned/v3-align64 v3c:/root/results/chunk-root/v3c-aligned/v3-align64; do
  name=${spec%%:*}; e=${spec#*:}; o=$r/$name-$n; mkdir -p $o
  ( cd $o && taskset -c 2 $e --contenders blake3-servil-st,blake3-official,sha256 --points '64 B,1 KiB' --for-regression-check --rounds 48 > run.out 2> run.err )
done; done
python3 /root/cold2.py $r
