// A Rust program that packs and unpacks with the three functions in ../lz4/odelz4.o: the object is given to
// the linker as it is (no assembler, no C compiler), and check_file.py then checks the executable.
//
//   rustc -O -C link-arg=../lz4/odelz4.o main.rs -o lz4-demo
//   ./lz4-demo                 packs some text and unpacks it; then a damaged block, which is refused
//   ./lz4-demo FILE            packs a file (at each distance 1 to 8, keeping the smallest) and unpacks it
//   python3 ../check_file.py lz4-demo ../lz4/lz4.spec
//
// The public contracts are in ../lz4/lz4.spec. What this program relies on is what they say and no more:
// a count the packer gives is of bytes that decode to the input; with n + n / 255 + 16 bytes of room it
// gives one; the decoder gives the count and the bytes of any block that is one and fits, and NO for
// anything else, whatever the bytes are, having written nothing outside the room it was given.
use std::io::Read;

const NO: u64 = u64::MAX;

extern "C" {
    fn ode_lz4_pack(out: *mut u8, cap: u64, input: *const u8, n: u64, d: u64) -> u64;
    fn ode_lz4_store(out: *mut u8, cap: u64, input: *const u8, n: u64) -> u64;
    fn ode_lz4_decode(out: *mut u8, cap: u64, input: *const u8, n: u64) -> u64;
}

fn pack(input: &[u8], d: u64) -> Vec<u8> {
    let mut out = vec![0u8; input.len() + input.len() / 255 + 16];
    // SAFETY: the contract's `requires`: out and input do not overlap, cap is below NO, d is 1 to 65535.
    let r = unsafe { ode_lz4_pack(out.as_mut_ptr(), out.len() as u64, input.as_ptr(), input.len() as u64, d) };
    assert!(r != NO, "the contract says it does not say NO with this much room");
    out.truncate(r as usize);
    out
}

fn store(input: &[u8]) -> Vec<u8> {
    let mut out = vec![0u8; input.len() + input.len() / 255 + 16];
    // SAFETY: out and input do not overlap, cap is below NO.
    let r = unsafe { ode_lz4_store(out.as_mut_ptr(), out.len() as u64, input.as_ptr(), input.len() as u64) };
    assert!(r != NO);
    out.truncate(r as usize);
    out
}

fn unpack(block: &[u8], cap: usize) -> Option<Vec<u8>> {
    let mut out = vec![0u8; cap];
    // SAFETY: out and block do not overlap; the block is shorter than 2^56 bytes. Nothing is asked of its bytes.
    let r = unsafe { ode_lz4_decode(out.as_mut_ptr(), cap as u64, block.as_ptr(), block.len() as u64) };
    if r == NO { return None; }
    out.truncate(r as usize);
    Some(out)
}

fn main() {
    let input = match std::env::args().nth(1) {
        Some(path) => { let mut v = Vec::new(); std::fs::File::open(&path).expect("open").read_to_end(&mut v).expect("read"); v }
        None => "It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, \
                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa abcdabcdabcdabcdabcdabcdabcdabcdabcdabcd".as_bytes().to_vec(),
    };
    let stored = store(&input);
    assert_eq!(unpack(&stored, input.len()).as_deref(), Some(&input[..]), "what the storing encoder wrote decodes to the input");
    let (d, best) = (1..=8u64).map(|d| (d, pack(&input, d))).min_by_key(|(_, b)| b.len()).unwrap();
    assert_eq!(unpack(&best, input.len()).as_deref(), Some(&input[..]), "what the packing encoder wrote decodes to the input");
    println!("{} bytes: stored in {}, packed in {} (matches at distance {}); both unpack to the input", input.len(), stored.len(), best.len(), d);
    // too little room, and a damaged block: NO, and nothing else happens
    if !input.is_empty() { assert_eq!(unpack(&best, input.len() - 1), None, "one byte too little room: NO"); }
    let mut refused = 0;
    for k in 0..best.len().min(2000) {
        let mut bad = best.clone();
        bad[k] ^= 0x55;
        match unpack(&bad, input.len()) { None => refused += 1, Some(v) => assert!(v.len() <= input.len()) }
    }
    println!("{} of {} blocks with one byte changed are refused; the others decode to something that fits", refused, best.len().min(2000));
}
