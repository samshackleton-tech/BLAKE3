// The fast hash of levels.ode (hashf: proved, given its two kernels' contracts) with the library's own kernels
// linked, beside the library's hash: do they agree, and what does a call take? Single runs: inventory.
use std::time::Instant;

extern "C" {
    fn b3l_hashf(out: u64, input: u64, len: u64, key: u64, flags: u64, plat: u64) -> u64;
    fn b3l_hashl(out: u64, input: u64, len: u64, key: u64, flags: u64, plat: u64) -> u64;
}
type HashFn = unsafe extern "C" fn(u64, u64, u64, u64, u64, u64) -> u64;

fn rng(state: &mut u64) -> u64 {
    *state ^= *state << 13;
    *state ^= *state >> 7;
    *state ^= *state << 17;
    *state
}

fn agree(name: &str, hash: HashFn, plat: u64, big: bool) -> u64 {
    let mut s = 0xD1B54A32D192ED03u64;
    let data: Vec<u8> = (0..(5 << 20) + 77).map(|_| rng(&mut s) as u8).collect();
    let mut lens: Vec<usize> = (0..=2100).step_by(7).collect();
    for k in 2..70 {
        for d in [-65i64, -1, 0, 1, 64] {
            lens.push((k * 1024 + d) as usize);
        }
    }
    if big {
        for k in 1..40 {
            for d in [-1025i64, -1024, -1, 0, 1, 1023, 1024, 1025] {
                lens.push((k * 32768 + d) as usize);
            }
        }
        lens.extend([1 << 20, (1 << 20) + 1, (5 << 20) + 77, 5 << 20]);
    }
    let mut cases = 0;
    for (m, flags) in [0u8, 16, 64].into_iter().enumerate() {
        let key: [u32; 8] = if m == 0 { *blake3_servil_core::IV } else { core::array::from_fn(|_| rng(&mut s) as u32) };
        for &len in &lens {
            let want = blake3_servil_core::hash_serial(&data[..len], &key, flags);
            let mut out = [0u8; 32];
            unsafe { hash(out.as_mut_ptr() as u64, data.as_ptr() as u64, len as u64, key.as_ptr() as u64, flags as u64, plat) };
            assert_eq!(&out, want.as_bytes(), "{name}: the hash of {len} bytes, flags {flags}");
            cases += 1;
        }
    }
    cases
}

fn least(tries: usize, reps: u64, mut f: impl FnMut()) -> f64 {
    let mut best = f64::MAX;
    for _ in 0..tries {
        let t = Instant::now();
        for _ in 0..reps {
            f();
        }
        best = best.min(t.elapsed().as_nanos() as f64 / reps as f64);
    }
    best
}

fn main() {
    blake3_servil_core::initialize();
    let plat: u64 = if std::is_x86_feature_detected!("avx512f") && std::is_x86_feature_detected!("avx512vl") { 5 }
        else if std::is_x86_feature_detected!("avx2") { 4 } else { 3 };
    println!("platform {plat}");
    println!("hashf agrees with the crate's hash_serial on {} inputs", agree("hashf", b3l_hashf as HashFn, plat, true));
    println!("hashl agrees with the crate's hash_serial on {} inputs", agree("hashl", b3l_hashl as HashFn, plat, false));
    let mut s = 99u64;
    let data: Vec<u8> = (0..16 << 20).map(|_| rng(&mut s) as u8).collect();
    let key = *blake3_servil_core::IV;
    for len in [1024usize, 16384, 65536, 1 << 20, 16 << 20] {
        let reps = (100_000_000 / (len as u64 + 200)).max(3);
        let crate_ns = least(9, reps, || {
            std::hint::black_box(blake3_servil_core::convenience::hash(std::hint::black_box(&data[..len])));
        });
        let mut out = [0u8; 32];
        let mut ns = vec![];
        for h in [b3l_hashf as HashFn, b3l_hashl as HashFn] {
            let reps = if len > 65536 && h as usize == b3l_hashl as usize { 2 } else { reps };
            ns.push(least(if len > 65536 { 3 } else { 9 }, reps, || {
                unsafe { h(out.as_mut_ptr() as u64, std::hint::black_box(data.as_ptr()) as u64, len as u64, key.as_ptr() as u64, 0, plat) };
                std::hint::black_box(&out);
            }));
        }
        let gbs = |ns: f64| len as f64 / ns;
        println!("{len} bytes, GB/s: the crate's hash {:.2}; hashf {:.2} ({:+.1}% of the crate's); hashl {:.2}",
                 gbs(crate_ns), gbs(ns[0]), 100.0 * (crate_ns / ns[0] - 1.0), gbs(ns[1]));
    }
}
