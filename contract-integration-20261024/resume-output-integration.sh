#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/gpr-chunk-root/devon-output-integration
wt=/root/BLAKE3-gpr-with-out
exec >> "$r/runner.log" 2>&1
trap 'echo "resume exit=$? time=$(date -Is)" >> "$r/status.log"' EXIT
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|perf|bpftrace)$'; then exit 3; fi
cd "$wt/bench-hashes"
patch='patch."https://github.com/devonjonte/BLAKE3".blake3-servil.path=".."'
cargo --config "$patch" update -q -p blake3-servil
# nextest is an external Cargo subcommand: pass --config to nextest itself.
cargo nextest run --config "$patch" --release > "$r/bench-tests-fixed-invocation.log" 2>&1
grep Summary "$r/bench-tests-fixed-invocation.log" >> "$r/status.log"
cargo --config "$patch" build -q --release > "$r/build-simd.log" 2>&1
cp target/release/bench-hashes "$r/simd"
BLAKE3_DIAGNOSTIC_GPR=1 cargo --config "$patch" build -q --release > "$r/build-gpr.log" 2>&1
cp target/release/bench-hashes "$r/gpr"
python3 - "$r/simd" "$r/call-path.txt" <<'PY'
import pathlib, subprocess, sys
exe, dest = sys.argv[1:]
syms = subprocess.run(['nm','-C','-S','--defined-only',exe],check=True,capture_output=True,text=True).stdout
result=[]
for line in syms.splitlines():
    f=line.split(None,3)
    if len(f)!=4 or not any(k in f[3] for k in ('bench_hashes::hash_lent','bench_hashes::hash_in_memory','each_message_into_kept')): continue
    a,n=int(f[0],16),int(f[1],16)
    asm=subprocess.run(['objdump','-d','-C','--no-show-raw-insn',f'--start-address={a}',f'--stop-address={a+n}',exe],check=True,capture_output=True,text=True).stdout
    result.append(asm)
pathlib.Path(dest).write_text('\n'.join(result))
print('call-path disassembly blocks:',len(result))
PY
printf 'library=e49e06f389ff79f36f4f1dd8ee1f91f35bd4ed7d (f503409 + opt-in GPR)\nbench=2b7c9ea4f621df7c19855994258cb826c3aea81e\ninput allocator=default\n' > "$r/pins.txt"
echo "integration complete $(date -Is); no performance verdict" >> "$r/status.log"
