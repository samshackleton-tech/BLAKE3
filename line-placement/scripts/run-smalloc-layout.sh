#!/bin/bash
# smalloc as bench-hashes' global allocator (candidate/sam-smalloc-option, on
# #67 aedc061): (A) determinism of the main thread's kept-buffer address over
# 16 processes, glibc vs smalloc, ASLR on and off; (B) offset maps under
# smalloc for servil b94e2fa (base) and the chunk-root fix.
set -u
. /root/.cargo/env
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile GIT_CONFIG_VALUE_0=/root/bench-excludes
r=/root/results/smalloc/layout
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
# The bench with the smalloc option, normal build (servil b94e2fa from its lock).
b=/root/bench-smalloc
rm -rf "$b"; cp -a /root/bench-hashes-after "$b"; rm -rf "$b/target"
tar xzf /root/smalloc-src.tgz -C "$b"
( cd "$b" && cargo build -q --release && cp target/release/bench-hashes "$r/glibc-base" && \
  cargo build -q --release --features smalloc && cp target/release/bench-hashes "$r/smalloc-base" ) > "$r/build.log" 2>&1 || exit 3
( cd "$b" && cargo nextest run --release --features smalloc ) > "$r/tests-smalloc.log" 2>&1; status "smalloc bench tests exit=$?"
( cd "$b" && cp Cargo.lock "$r/Cargo.lock" )
# The fix under smalloc: build-against with the feature on by default in a copy.
fixb=/root/BLAKE3-chunk-root/bench-hashes
rm -rf "$fixb"; cp -a "$b" "$fixb"; rm -rf "$fixb/target"
python3 - "$fixb/Cargo.toml" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text()
assert s.count('smalloc = ["dep:smalloc"]')==1
p.write_text(s.replace('smalloc = ["dep:smalloc"]','smalloc = ["dep:smalloc"]\ndefault = ["smalloc"]'))
PY
fixexe=$(cd "$fixb" && cargo run -q --release -- build-against .. 2> "$r/fix-build.err") || exit 3
cp "$fixexe" "$r/smalloc-fix"
"$r/smalloc-fix" --contenders blake3-servil-st --points 'lent 64 B' --rounds 2 --for-regression-check > /dev/null 2>&1
status 'builds done'
# (A) addresses
for exe in glibc-base smalloc-base; do
    sym=$(nm "$r/$exe" | python3 -c 'import sys; m=[l.split()[2] for l in sys.stdin if l.split()[-1].endswith("13blake3_servil11hash_serial")]; assert len(m)==1, m; print(m[0])')
    for aslr in off on; do
        pre=""; [ "$aslr" = off ] && pre="setarch x86_64 -R"
        for n in $(seq 1 16); do
            out="$r/addr-$exe-$aslr-$n"; mkdir -p "$out"
            printf '#!/bin/sh\ncd %s\nexec %s env -i PATH=/usr/bin:/bin HOME=/root %s --contenders blake3-servil-st --points "lent 64 B,lent 256 B" --for-regression-check --rounds 24 > %s/run.out 2> %s/run.err\n' "$out" "$pre" "$r/$exe" "$out" "$out" > "$out/run.sh"
            bpftrace -q -e "uprobe:$r/$exe:$sym /pid == tid/ { @[reg(\"dx\"), reg(\"si\") & 4095, reg(\"di\") & 4095] = count(); }" -c "/bin/sh $out/run.sh" > "$out/probe.txt" 2> "$out/probe.err"
        done
        status "addresses $exe aslr=$aslr done"
    done
done
# (B) maps under smalloc
for side in base fix; do
    python3 /root/offset_check.py --exe "$r/smalloc-$side" --repeat 3 --map "$r/map-smalloc-$side.tsv" --keep "$r/map-smalloc-$side-runs" > "$r/map-smalloc-$side.out" 2> "$r/map-smalloc-$side.err"
    status "map smalloc-$side exit=$?"
done
status complete
printf 'done\n' > "$r/complete"
