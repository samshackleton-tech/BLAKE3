#!/bin/bash
# Bounded recheck of the full check's suspects; not a substitute for its 16 fresh-layout stage.
set -euo pipefail
. /root/.cargo/env
r=/root/results/investigate-152-20261025/suspects
mkdir -p "$r/samples"
exec > "$r/runner.log" 2>&1
trap 'echo "suspect recheck exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
b=/root/BLAKE3-152-parent/bench-hashes
cd /root/results/investigate-152-20261025
judge='blake3-servil-mt|solo|ContinuousMessages|64 B;blake3-servil-mt|solo|ManyMessages|3;blake3-servil-mt|solo|ManyMessages|32;blake3-servil-st|solo|ManyMessages|3;blake3-servil-st|solo|ManyMessages|24;blake3-servil-mt|solo|ContinuousMessages|1 KiB;blake3-servil-mt|solo|ManyMessages|64;blake3-servil-st|solo|ManyMessages|8'
set +e
"$PWD/bin/parent-0" regress --pairs 8 --contenders blake3-servil-st,blake3-servil-mt --points 'continuous 64 B,continuous 1 KiB,3,8,24,32,64' --judge "$judge" --keep "$r/samples" "$PWD"/bin/parent-{0..3} -- "$PWD"/bin/candidate-{0..3} > "$r/regress.out" 2> "$r/regress.err"
code=$?
set -e
echo "suspect regress exit=$code $(date -Is)" >> "$r/status.log"
[ "$code" -le 2 ]
"$PWD/bin/parent-0" compare "$r"/samples/run-*-old.tsv -- "$r"/samples/run-*-new.tsv > "$r/compare.out" 2> "$r/compare.err"
echo "suspect recheck complete $(date -Is)" >> "$r/status.log"
