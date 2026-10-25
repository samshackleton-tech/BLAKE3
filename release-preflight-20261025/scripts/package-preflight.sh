#!/bin/bash
# Short release preflight, not a benchmark and not a publish operation.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-preflight-20261025
mkdir -p "$r"
exec > "$r/runner.log" 2>&1
trap 'echo "preflight exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
wt=/root/BLAKE3-private-symbols-review
[ "$(git -C "$wt" rev-parse HEAD)" = 3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4 ]
git -C "$wt" status --porcelain > "$r/source-status-before.txt"
[ ! -s "$r/source-status-before.txt" ]
rustc -Vv > "$r/toolchain.txt"
cargo cinstall --version >> "$r/toolchain.txt"
cc --version >> "$r/toolchain.txt"
# Independent test suites run concurrently, in distinct build directories.
(cd "$wt"; CARGO_TARGET_DIR=/root/target-release-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/capi.log" 2>&1) & capi=$!
(cd "$wt"; CARGO_TARGET_DIR=/root/target-release-cli cargo nextest run --release --locked --manifest-path b3sum/Cargo.toml > "$r/cli.log" 2>&1) & cli=$!
(cd "$wt"; CARGO_TARGET_DIR=/root/target-release-package cargo package --locked --no-verify > "$r/package.log" 2>&1) & pkg=$!
result=0
for pid in "$capi" "$cli" "$pkg"; do wait "$pid" || result=1; done
[ "$result" = 0 ] || exit "$result"
cp "$wt/capi/Cargo.lock" "$r/capi-Cargo.lock"
cp "$wt/b3sum/Cargo.lock" "$r/cli-Cargo.lock"
cp /root/target-release-package/package/*.crate "$r/"
python3 - "$r" <<'PY'
import json,pathlib,tarfile,sys
r=pathlib.Path(sys.argv[1])
archive,=r.glob('*.crate')
with tarfile.open(archive) as f:
 f.extractall(r/'unpacked',filter='data')
package,=(r/'unpacked').iterdir()
vcs=json.loads((package/'.cargo_vcs_info.json').read_text())
assert vcs['git']['sha1']=='3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4' and not vcs['git'].get('dirty',False),vcs
for name in ['build.rs','c/blake3_avx512_x86-64_unix.S','tools/require_nextest.rs']:
 assert (package/name).is_file(),name
project=r/'consumer'
(project/'src').mkdir(parents=True,exist_ok=True)
(project/'src/main.rs').write_bytes((r/'consumer.rs').read_bytes())
(project/'Cargo.toml').write_text('[package]\nname="packaged-consumer"\nversion="0.0.0"\nedition="2024"\n[dependencies]\nb3={package="blake3-servil",path='+json.dumps(str(package))+'}\nofficial={package="blake3",version="=1.8.7",default-features=false,features=["std"]}\n[features]\npure=["b3/pure"]\n')
print('consumer uses only the extracted package:',package)
PY
cd "$r/consumer"
export CARGO_TARGET_DIR=/root/target-release-consumer
cargo run --release > "$r/consumer-default.log" 2>&1
cp "$CARGO_TARGET_DIR/release/packaged-consumer" "$r/consumer-default"
nm "$r/consumer-default" > "$r/consumer-nm.txt"
python3 - "$r/consumer-nm.txt" <<'PY'
import pathlib,sys
rows=[s.split() for s in pathlib.Path(sys.argv[1]).read_text().splitlines()]
names={r[2]:r[0] for r in rows if len(r)==3 and r[1]=='T'}
a='blake3_hash_many_avx512';b='blake3_servil_hash_many_avx512'
assert a in names and b in names and names[a]!=names[b],(names.get(a),names.get(b))
print('packaged consumer binds distinct native entries:',names[a],names[b])
PY
cargo run --release --locked --features pure > "$r/consumer-pure.log" 2>&1
cargo run --release --locked --features b3/serde,b3/zeroize > "$r/consumer-features.log" 2>&1
cp Cargo.lock "$r/consumer-Cargo.lock"
git -C "$wt" status --porcelain > "$r/source-status-after.txt"
[ ! -s "$r/source-status-after.txt" ]
cd "$r"
sha256sum *.crate consumer-default > artifacts.sha256
/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0 *.crate consumer-default > artifacts.blake3
echo "package, CLI, installed C/C++ and extracted Rust consumer checks complete $(date -Is)" >> status.log
