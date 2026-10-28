#!/bin/bash
# BLAKE3 #205: when does nonzero padding change a digest? At 83d59db, every
# padding byte of every message set to 0xA5, every digest compared with the
# clean input's, one-thread and multithreaded, over counts and lengths.
set -u
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O" "$R/src/examples"
cat > "$R/src/examples/pad_hazard.rs" <<'PROBE_EOF'
use blake3_servil::performance::{self, Block};
use blake3_servil::Mode;
fn run(count: usize, len: usize, dirty: bool, mt: bool) -> Vec<[u8; 32]> {
    let slot = len.div_ceil(64).max(1) * 64;
    let mut input = vec![Block([0u8; 64]); count * slot / 64];
    for m in 0..count {
        for i in 0..slot {
            let (b, o) = ((m * slot + i) / 64, (m * slot + i) % 64);
            input[b].0[o] = if i < len { (m * 31 + i * 7 + 1) as u8 } else if dirty { 0xA5 } else { 0 };
        }
    }
    let mut out = vec![[0u8; 32]; count];
    if mt { performance::hash_many_multithreaded(Mode::Plain, &input, len, &mut out) } else { performance::hash_many(Mode::Plain, &input, len, &mut out) }
    out
}
fn main() {
    blake3_servil::initialize();
    blake3_servil::initialize_multithreaded(None);
    for mt in [false, true] {
        for count in [1, 2, 3, 4, 7, 8, 15, 16, 17, 31, 32, 33, 64, 100, 1024, 16384] {
            let mut line = format!("{} count {count:5}:", if mt { "mt" } else { "st" });
            for len in [1, 33, 63, 65, 100, 127, 200, 513, 1000, 1023, 1025, 2000, 4000] {
                let (c, d) = (run(count, len, false, mt), run(count, len, true, mt));
                // the clean digests against official BLAKE3 too
                let ok = (0..count).all(|m| { let slot = len.div_ceil(64).max(1) * 64; let msg: Vec<u8> = (0..len).map(|i| (m * 31 + i * 7 + 1) as u8).collect(); let _ = slot; c[m] == *blake3::hash(&msg).as_bytes() });
                let wrong = (0..count).filter(|&m| c[m] != d[m]).count();
                line += &format!(" {len}:{}{}", wrong, if ok { "" } else { "!" });
            }
            println!("{line}");
        }
    }
}
PROBE_EOF
cd "$R/src"
grep -q '^blake3 = ' Cargo.toml || python3 - <<'PY'
from pathlib import Path
p=Path('Cargo.toml'); s=p.read_text()
assert '[dev-dependencies]' in s
s=s.replace('[dev-dependencies]\n','[dev-dependencies]\nblake3 = "=1.8.7"\n',1); p.write_text(s)
PY
grep -n '^blake3 = ' Cargo.toml > "$O/devdep.txt"
cargo build --release --example pad_hazard > "$O/build.log" 2>&1 || exit 5
./target/release/examples/pad_hazard > "$O/hazard.txt" 2> "$O/hazard.err" || exit 6
git log -1 --format='%H' > "$O/commit.txt"; grep -m1 '^version' Cargo.toml >> "$O/commit.txt"
