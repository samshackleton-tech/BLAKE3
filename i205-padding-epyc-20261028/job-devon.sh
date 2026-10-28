#!/bin/bash
# BLAKE3 #205 option 2: the padding check in every build, measured on the EPYC 9255.
set -u
. /root/.cargo/env
R="$1"; O="$R/out"; mkdir -p "$O"
cat > "$R/pad_probe.rs" <<'PROBE_EOF'
// Measurement probe for BLAKE3 #205 (not committed): CALLS warm calls of
// performance::hash_many (MT=1: hash_many_multithreaded) over COUNT messages
// of LEN bytes in their padded slots. DIRTY=1 sets one padding byte nonzero
// and prints the first digest (or the build panics, as a checked one must).
use blake3_servil::performance::{self, Block};
use blake3_servil::Mode;
fn main() {
    let a: Vec<usize> = std::env::args().skip(1).map(|s| s.parse().unwrap()).collect();
    let (count, len, calls, mt, dirty) = (a[0], a[1], a[2], a[3], a[4]);
    blake3_servil::initialize();
    blake3_servil::initialize_multithreaded(None);
    let slot = len.div_ceil(64).max(1) * 64;
    let mut input = vec![Block([0u8; 64]); count * slot / 64];
    for m in 0..count {
        for i in 0..len {
            let (b, o) = ((m * slot + i) / 64, (m * slot + i) % 64);
            input[b].0[o] = (m * 31 + i * 7 + 1) as u8;
        }
    }
    if dirty == 1 {
        let (b, o) = ((slot - 1) / 64, (slot - 1) % 64);
        input[b].0[o] = 0xA5;
    }
    let mut out = vec![[0u8; 32]; count];
    let t = std::time::Instant::now();
    for _ in 0..calls {
        if mt == 1 {
            performance::hash_many_multithreaded(Mode::Plain, std::hint::black_box(&input), len, &mut out);
        } else {
            performance::hash_many(Mode::Plain, std::hint::black_box(&input), len, &mut out);
        }
        std::hint::black_box(&mut out);
    }
    let ns = t.elapsed().as_nanos() as f64 / calls as f64;
    println!("ns_per_call {ns:.1} digest0 {}", out[0].iter().map(|b| format!("{b:02x}")).collect::<String>());
}
PROBE_EOF
OLD='    debug_assert!(len % BLOCK_LEN == 0 || input.chunks_exact(slot).all(|s| s[len..].iter().all(|&b| b == 0)), "every slot'"'"'s bytes past its message are zero");'
NEW_ALL='    assert!(len % BLOCK_LEN == 0 || input.chunks_exact(slot).all(|s| s[len..].iter().all(|&b| b == 0)), "every slot'"'"'s bytes past its message are zero");'
NEW_OR='    assert!(len % BLOCK_LEN == 0 || input.chunks_exact(slot).all(|s| s[len..].iter().fold(0u8, |a, &b| a | b) == 0), "every slot'"'"'s bytes past its message are zero");'
for b in base devon; do
  case $b in base) d="$R/src";; devon) d="$R/devon";; esac
  mkdir -p "$d/examples"; cp "$R/pad_probe.rs" "$d/examples/pad_probe.rs"
  (cd "$d" && CARGO_TARGET_DIR="$R/t-$b" cargo build --release --example pad_probe) > "$O/$b-build.log" 2>&1 || exit 5
done
(cd "$R/devon" && . /root/.cargo/env && CARGO_TARGET_DIR="$R/t-devon-tests" cargo nextest run --release > "$O/devon-tests.log" 2>&1; echo "devon tests exit $?" >> "$O/devon-tests.log")
E() { echo "$R/t-$1/release/examples/pad_probe"; }
# Correctness: nonzero padding. base gives a digest (wrong), checked builds stop.
for b in base devon; do $(E $b) 3 100 1 0 1 > "$O/dirty-$b.txt" 2>&1; echo "exit $?" >> "$O/dirty-$b.txt"; done
$(E base) 3 100 1 0 0 > "$O/clean-base.txt" 2>&1
python3 - "$O" <<'PY' > "$O/correctness.txt"
import sys,re
O=sys.argv[1]; r=lambda f: open(f"{O}/{f}").read()
d=lambda t: re.search(r"digest0 ([0-9a-f]+)",t).group(1) if "digest0" in t else None
print("base, clean padding:", d(r("clean-base.txt")))
print("base, dirty padding:", d(r("dirty-base.txt")), "| differs from clean:", d(r("dirty-base.txt"))!=d(r("clean-base.txt")))
for b in ("devon",):
    t=r(f"dirty-{b}.txt"); print(f"{b}, dirty padding: panicked:", "every slot's bytes past its message are zero" in t and "exit 0" not in t)
PY
# Speed: st cycles pinned to CPU 2; 5 rounds rotating the builds.
python3 - "$R" "$O" <<'PY' > "$O/speed.txt"
import subprocess,statistics as st,sys
R,O=sys.argv[1:3]; B=["base","devon"]
exe=lambda b: f"{R}/t-{b}/release/examples/pad_probe"
rows={}
for count in (1,4,16,64,1024):
    for ln in (1,33,63,64,65,100,200,513,1000,1025,2000):
        slot=-(-ln//64)*64
        calls=max(1, 100_000_000//(count*slot))
        for rnd in range(5):
            for b in B[rnd%2:]+B[:rnd%2]:
                e=subprocess.run(["taskset","-c","2","perf","stat","-x,","-e","instructions:u,cycles:u","--",exe(b),str(count),str(ln),str(calls),"0","0"],capture_output=True,text=True).stderr
                v=[int(l.split(",")[0]) for l in e.splitlines() if l and l.split(",")[0].isdigit()]
                rows.setdefault((count,ln,b),[]).append((v[0]/calls,v[1]/calls))
print("count  len   base cyc/call   devon x   (instr/call base, devon)")
for count in (1,4,16,64,1024):
    for ln in (1,33,63,64,65,100,200,513,1000,1025,2000):
        m={b: st.median(c for _,c in rows[(count,ln,b)]) for b in B}
        i={b: st.median(x for x,_ in rows[(count,ln,b)]) for b in B}
        print(f"{count:5} {ln:5} {m['base']:12.0f}   x{m['devon']/m['base']:.3f}   ({i['base']:.0f}, {i['devon']:.0f})")
PY
git -C "$R/src" log -1 --format='%H %s' > "$O/commit.txt"
