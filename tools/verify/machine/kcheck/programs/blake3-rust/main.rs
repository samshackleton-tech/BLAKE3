// A Rust program that hashes with the function in b3hashr.o: the object is given to the linker as it is
// (no assembler, no C compiler), and check_binary.py then checks the executable.
//
//   rustc -O -C link-arg=../../b3hashr.o main.rs -o b3hashr-demo
//   ./b3hashr-demo                 the official vector of 102,400 bytes, and the hash of nothing
//   ./b3hashr-demo FILE            the BLAKE3 hash of a file
//   python3 ../../check_binary.py b3hashr-demo
use std::io::Read;

extern "C" {
    // The public contract is in blake3.spec: out and key are 32 bytes each, input is len bytes, and the three
    // do not overlap; flags below 256; plat is 5 only where the processor has AVX-512 F and VL.
    fn b3l_hashr(out: *mut u8, input: *const u8, len: u64, key: *const u8, flags: u64, plat: u64);
}

const IV: [u32; 8] = [0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19];

fn blake3(input: &[u8]) -> [u8; 32] {
    let mut key = [0u8; 32];
    for (i, w) in IV.iter().enumerate() { key[4 * i..4 * i + 4].copy_from_slice(&w.to_le_bytes()); }
    let plat = if std::is_x86_feature_detected!("avx512f") && std::is_x86_feature_detected!("avx512vl") { 5 } else { 0 };
    assert!(std::is_x86_feature_detected!("sse4.1"), "the function needs SSE4.1");
    let mut out = [0u8; 32];
    // SAFETY: the contract's `requires`: out, input and key are three separate things of the lengths given.
    unsafe { b3l_hashr(out.as_mut_ptr(), input.as_ptr(), input.len() as u64, key.as_ptr(), 0, plat) };
    out
}

fn hex(bytes: &[u8]) -> String { bytes.iter().map(|b| format!("{b:02x}")).collect() }

fn main() {
    match std::env::args().nth(1) {
        Some(path) => {
            let mut data = Vec::new();
            std::fs::File::open(&path).expect("no such file").read_to_end(&mut data).expect("cannot read it");
            println!("{}  {}", hex(&blake3(&data)), path);
        }
        None => {
            let input: Vec<u8> = (0..102400usize).map(|i| (i % 251) as u8).collect();
            let got = hex(&blake3(&input));
            assert_eq!(got, "bc3e3d41a1146b069abffad3c0d44860cf664390afce4d9661f7902e7943e085", "the official vector of 102,400 bytes");
            assert_eq!(hex(&blake3(b"")), "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262", "the hash of nothing");
            println!("the official vectors of 0 and of 102,400 bytes: as published");
        }
    }
}
