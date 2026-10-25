#!/bin/bash
set -euo pipefail
. /root/.cargo/env
r=/root/results/github-round-20261025-1458
exec > "$r/pr166-runner.log" 2>&1
trap 'echo "PR166 tests exit=$? $(date -Is)" >> "$r/status.log"' EXIT
cd /root/BLAKE3-round-pr166
[ "$(git rev-parse HEAD)" = f4f530eb304285ba261f9b94bfb09d2dbb524892 ]
(CARGO_TARGET_DIR=/root/target-round-pr166 cargo nextest run --release > "$r/default.log" 2>&1) & default=$!
(CARGO_TARGET_DIR=/root/target-round-pr166-pure cargo nextest run --release --features pure > "$r/pure.log" 2>&1) & pure=$!
(CARGO_TARGET_DIR=/root/target-round-pr166-nostd cargo nextest run --release --no-default-features > "$r/no-std.log" 2>&1) & nostd=$!
(CARGO_TARGET_DIR=/root/target-round-pr166-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/capi.log" 2>&1) & capi=$!
(CARGO_TARGET_DIR=/root/target-round-pr166-doc cargo test --doc > "$r/doc.log" 2>&1) & doc=$!
(python3 -m unittest discover -s tools/verify -p 'test_*.py' > "$r/verify-helpers.log" 2>&1) & helpers=$!
result=0
for pid in "$default" "$pure" "$nostd" "$capi" "$doc" "$helpers"; do wait "$pid" || result=1; done
[ "$result" = 0 ]
# The symbol-prefix checks are in this tree's suite; record actual names too.
python3 - "$r" <<'PY'
from pathlib import Path
import re,sys
r=Path(sys.argv[1]); names=[]
for p in Path('/root/BLAKE3-round-pr166/c').iterdir():
 if p.suffix not in ['.S','.asm']:continue
 for line in p.read_text().splitlines():
  words=line.split()
  if len(words)>=2 and words[0] in ['.globl','.global','PUBLIC','public']:
   names.append(words[1])
assert names and all(n.lstrip('_').startswith('blake3_servil_') for n in names)
(r/'symbol-count.txt').write_text(f'{len(names)} exported names, all prefixed\n')
PY
sha256sum /root/BLAKE3-round-pr166/c/blake3_avx512_x86-64_unix.S > "$r/avx512-source.sha256"
echo "PR166 native/proof-helper tests complete $(date -Is)" >> "$r/status.log"
