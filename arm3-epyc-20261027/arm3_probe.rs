// Measurement probe (not committed): CALLS warm calls of hash_many over
// COUNT messages of LEN bytes (whole blocks: hash_four_at_a_time's path on x86-64).
use blake3_servil::performance::{self, Block};
fn main() {
    let a: Vec<usize> = std::env::args().skip(1).map(|s| s.parse().unwrap()).collect();
    let (count, len, calls) = (a[0], a[1], a[2]);
    blake3_servil::initialize();
    let input = vec![Block([7u8; 64]); count * len / 64];
    let mut out = vec![[0u8; 32]; count];
    for _ in 0..calls {
        performance::hash_many(blake3_servil::Mode::Plain, std::hint::black_box(&input), len, &mut out);
        std::hint::black_box(&mut out);
    }
}
