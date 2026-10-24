#!/bin/bash
# (1) Mechanism: duo-copy threads' store-to-load conflicts (ls_bad_status2.
# stli_other) and IPC, base b94e2fa vs the chunk-root fix, at the base's worst
# thread-stack offsets (shared lent 64 B: +3648; shared owned 64 B: +1344) and
# a neutral one (+0), setarch -R, one direct process each.
# (2) Negative control: plant one push/pop pair in a scratch copy of the
# kernel source; test_chunk_root_kernel_touches_no_stack must fail; restore.
set -u
. /root/.cargo/env
r=/root/results/chunk-root/mechanism
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if kill -0 2373207 2>/dev/null; then tail --pid=2373207 -f /dev/null; fi
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
for side in base fix; do
    exe=$(cat /root/results/chunk-root/maps/$side-exe.txt)
    for off in 0 3648 1344; do
        out="$r/$side-$off"; mkdir -p "$out"
        ( cd "$out" && setarch x86_64 -R env -i PATH=/usr/bin:/bin HOME=/root GLIBC_TUNABLES=glibc.rtld.optional_static_tls=$((512 + off)) \
            perf record -q -e ls_bad_status2.stli_other/period=1009/u -e cpu/cycles,period=100003/u -e cpu/instructions,period=100003/u -o perf.data -- \
            "$exe" --contenders blake3-servil-st --points 'lent 64 B,continuous 64 B' --for-regression-check --rounds 48 ) > "$out/run.out" 2> "$out/run.err"
        perf report --stdio -i "$out/perf.data" --sort comm --show-total-period -n > "$out/by-thread.txt" 2> "$out/by-thread.err"
        perf report --stdio -i "$out/perf.data" --comms duo-copy-0,duo-copy-1 --no-children -n --sort symoff > "$out/sites.txt" 2>> "$out/by-thread.err"
        status "$side offset +$off done"
    done
done
w=/root/BLAKE3-chunk-root
cp "$w/c/blake3_chunk_root_x86-64_unix.S" "$r/kernel.S.orig"
python3 - "$w/c/blake3_chunk_root_x86-64_unix.S" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text()
old='        ret\n'
assert s.count(old)==2
s=s.replace(old,'        push rbx\n        pop rbx\n        ret\n',1)
p.write_text(s)
PY
( cd "$w" && cargo nextest run --release --lib -E 'test(test_chunk_root_kernel_touches_no_stack)' ) > "$r/negative.log" 2>&1
neg=$?
cp "$r/kernel.S.orig" "$w/c/blake3_chunk_root_x86-64_unix.S"
( cd "$w" && cargo nextest run --release --lib -E 'test(chunk_root)' ) > "$r/restored.log" 2>&1
status "negative control exit=$neg (expect 100); restored tests exit=$?"
git -C "$w" diff --stat HEAD -- c/ > "$r/restored.diff"
printf 'done\n' > "$r/complete"
