#!/bin/bash
# John's test for bench-hashes #69: create the duo copy threads before the
# main thread writes its input (own), versus as now. Same source otherwise
# (bench main f4f347c + #70's diag-align64), solo ManyMessages 64, 10
# processes each under taskset -c 0,1 (same CCD) and unpinned, ASLR off.
set -u
. /root/.cargo/env
r=/root/results/many-bistable/duo-order
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
for side in asis duofirst; do
    d=/root/bench-duo-$side
    rm -rf "$d"; git clone -q -b candidate/sam-diag-placement /root/bench-placement.bundle "$d" || exit 3
    if [ "$side" = duofirst ]; then
        python3 - "$d/src/main.rs" <<'PY' || exit 3
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
a = "    let own = make_input_seeded(largest(&|_| true), 0);\n"
b = "    let mut progress = Progress::new(roster);\n    let duo = Duo::new();\n"
assert s.count(a) == 1 and s.count(b) == 1
s = s.replace(b, "    let mut progress = Progress::new(roster);\n")
s = s.replace(a, "    let duo = Duo::new();\n" + a)
p.write_text(s)
PY
    fi
    git -C "$d" diff > "$r/$side.diff"
    ( cd "$d" && cargo build -q --release --features diag-align64 ) > "$r/build-$side.log" 2>&1 || exit 3
    cp "$d/target/release/bench-hashes" "$r/bench-$side"
done
status built
for n in $(seq 1 10); do
    for side in asis duofirst; do
        for pin in pair free; do
            o="$r/$side-$pin-$n"; mkdir -p "$o"
            if [ "$pin" = pair ]; then pre=(taskset -c 0,1); else pre=(); fi
            ( cd "$o" && "${pre[@]}" setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root "$r/bench-$side" --contenders blake3-servil-st --points '64' --for-regression-check --rounds 24 > run.out 2> run.err )
        done
    done
done
python3 - "$r" <<'PY' > "$r/summary.txt"
import glob, sys
r = sys.argv[1]
def mean(path):
    for l in open(path):
        f = l.rstrip('\n').split('\t')
        if len(f) > 5 and f[2] == 'ManyMessages' and f[3] == '64' and f[1] == 'solo':
            v = [a.split('/') for a in f[5].split(',')]
            return sum(int(n) for n, u in v) / sum(int(u) for n, u in v)
for side in ('asis', 'duofirst'):
    for pin in ('pair', 'free'):
        vals = []
        for n in range(1, 11):
            s = glob.glob(f'{r}/{side}-{pin}-{n}/benchmark-results/*/bench-hashes.samples.tsv')
            vals.append(mean(s[0]) if s else float('nan'))
        slow = sum(v >= 33 for v in vals)
        print(f'{side:9} {pin:5} slow {slow}/10:', ' '.join(f'{v:5.1f}' for v in vals))
PY
printf 'done\n' > "$r/complete"
