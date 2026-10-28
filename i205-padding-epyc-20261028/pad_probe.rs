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
