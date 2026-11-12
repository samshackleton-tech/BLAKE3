// Ways for Hash::to_hex to make its string from the kernel, timed (inventory; single runs).
use std::hint::black_box;
use std::time::Instant;
use arrayvec::ArrayString;

extern "C" {
    #[cfg_attr(target_arch = "aarch64", link_name = "b3l_hex_neon")]
    #[cfg_attr(target_arch = "x86_64", link_name = "b3l_hex")]
    fn hex_kernel(out: *mut u8, hash: *const u8);
}

#[inline(never)]
fn v_a(h: &[u8; 32]) -> u64 { let mut out = [0u8; 64]; unsafe { hex_kernel(out.as_mut_ptr(), h.as_ptr()) }; black_box(&out)[7] as u64 }

#[inline(never)]
fn v_b(h: &[u8; 32]) -> u64 { let copy = *black_box(h); let mut out = [0u8; 64]; unsafe { hex_kernel(out.as_mut_ptr(), copy.as_ptr()) }; black_box(&out)[7] as u64 }

// as drafted: the string is built in a local and returned
#[inline(never)]
fn to_hex_drafted(h: &[u8; 32]) -> ArrayString<64> {
    let mut s = ArrayString::new();
    unsafe { hex_kernel(s.as_mut_ptr(), h.as_ptr()); s.set_len(64); }
    s
}

// through a buffer of its own: the copy out of it loads what the kernel stored, sixteen bytes at a time
#[inline(never)]
fn to_hex_buffer(h: &[u8; 32]) -> ArrayString<64> {
    let mut out = [0u8; 64];
    unsafe { hex_kernel(out.as_mut_ptr(), h.as_ptr()); }
    let mut s = ArrayString::new();
    unsafe { core::ptr::copy_nonoverlapping(out.as_ptr(), s.as_mut_ptr(), 64); s.set_len(64); }
    s
}

// through a buffer, the string made from it without a check of its characters
#[inline(never)]
fn to_hex_unchecked(h: &[u8; 32]) -> ArrayString<64> {
    let mut out = [0u8; 64];
    unsafe { hex_kernel(out.as_mut_ptr(), h.as_ptr()); }
    ArrayString::from(unsafe { core::str::from_utf8_unchecked(&out) }).unwrap()
}

// through a buffer, the string made from it by safe code (its characters checked)
#[inline(never)]
fn to_hex_checked(h: &[u8; 32]) -> ArrayString<64> {
    let mut out = [0u8; 64];
    unsafe { hex_kernel(out.as_mut_ptr(), h.as_ptr()); }
    ArrayString::from_byte_string(&out).unwrap()
}

// the arithmetic of 0.9
#[inline(never)]
fn to_hex_arith(h: &[u8; 32]) -> ArrayString<64> {
    let character = |n: u8| (b'0' + n + ((n + 6) >> 4) * 39) as char;
    let mut s = ArrayString::new();
    for &b in h.iter() { s.push(character(b >> 4)); s.push(character(b & 0xf)); }
    s
}

fn time(name: &str, hashes: &[[u8; 32]], f: &dyn Fn(&[u8; 32]) -> u64) {
    let rounds = 20_000usize;
    let mut best = f64::MAX; let mut acc = 0u64;
    for _ in 0..3 {
        let t = Instant::now();
        for _ in 0..rounds { for h in hashes { acc = acc.wrapping_add(f(black_box(h))); } }
        best = best.min(t.elapsed().as_nanos() as f64 / (rounds * hashes.len()) as f64);
    }
    println!("{name}: {best:.2} ns ({acc})");
}

fn main() {
    let mut s: u64 = 88172645463325252;
    let mut hashes = Vec::new();
    for _ in 0..4096 { let mut h = [0u8; 32]; for b in h.iter_mut() { s ^= s << 13; s ^= s >> 7; s ^= s << 17; *b = (s >> 24) as u8; } hashes.push(h); }
    for h in &hashes { assert_eq!(to_hex_drafted(h), to_hex_arith(h)); assert_eq!(to_hex_buffer(h), to_hex_arith(h)); assert_eq!(to_hex_unchecked(h), to_hex_arith(h)); assert_eq!(to_hex_checked(h), to_hex_arith(h)); }
    time("kernel, its output read in place", &hashes, &|h| v_a(h));
    time("kernel, the hash copied first", &hashes, &|h| v_b(h));
    time("string as drafted (built in a local, returned)", &hashes, &|h| { let x = to_hex_drafted(h); black_box(&x).as_bytes()[7] as u64 });
    time("string through a buffer of the kernel's own", &hashes, &|h| { let x = to_hex_buffer(h); black_box(&x).as_bytes()[7] as u64 });
    time("string through a buffer, unchecked", &hashes, &|h| { let x = to_hex_unchecked(h); black_box(&x).as_bytes()[7] as u64 });
    time("string through a buffer, checked (safe)", &hashes, &|h| { let x = to_hex_checked(h); black_box(&x).as_bytes()[7] as u64 });
    time("string by 0.9's arithmetic", &hashes, &|h| { let x = to_hex_arith(h); black_box(&x).as_bytes()[7] as u64 });
}
