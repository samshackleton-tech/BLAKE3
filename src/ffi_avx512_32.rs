//! FFI for the 32-input AVX-512 kernels. Arithmetic, transposition,
//! counter setup and output stores are all in generated assembly.
//! The ABI matches the AArch64 kernel family; see the generator's contract.
use crate::{BLOCK_LEN, CVWords, IncrementCounter, OUT_LEN};

unsafe extern "C" {
    fn blake3_avx512_k32(inputs: *const *const u8, blocks: u64, key: *const u32,
        counter: u64, packed_flags: u64, out: *mut u8);
    fn blake3_avx512_p32(inputs: *const *const u8, blocks: u64, key: *const u32,
        counter: u64, packed_flags: u64, out: *mut u8);
}

/// Exactly 32 inputs, each 1..=16 whole blocks, and space for their CVs.
/// Caller has detected AVX-512F. Initial counter increments wrap as u64.
pub(crate) unsafe fn hash32<const N: usize>(inputs: &[&[u8; N]], key: &CVWords,
    counter: u64, increment: IncrementCounter, flags: u8, start: u8, end: u8, out: &mut [u8]) {
    const { assert!(N > 0 && N <= 1024 && N % BLOCK_LEN == 0); }
    assert_eq!(inputs.len(), 32);
    assert!(out.len() >= 32 * OUT_LEN);
    type Kernel = unsafe extern "C" fn(*const *const u8, u64, *const u32, u64, u64, *mut u8);
    let kernel: Kernel = if increment.yes() { blake3_avx512_k32 } else { blake3_avx512_p32 };
    let packed = flags as u64 | (start as u64) << 8 | (end as u64) << 16 | (BLOCK_LEN as u64) << 24;
    crate::ran_kernel(kernel as *const ());
    // Sound: every input points at N readable bytes, the key has 8 words,
    // and the bounds above provide 32 outputs. The caller detected AVX-512.
    unsafe { kernel(inputs.as_ptr().cast(), (N/BLOCK_LEN) as u64, key.as_ptr(), counter, packed, out.as_mut_ptr()) };
}

#[cfg(test)]
mod tests {
    use super::*;

    fn check<const N: usize>() {
        let mut data = vec![[0u8;N]; 32];
        let mut seed = 0xfedcba9876543210u64;
        for row in &mut data { for b in row {
            seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; *b = seed as u8;
        } }
        let refs: Vec<_> = data.iter().collect();
        for counter in [0, u32::MAX as u64 - 15, 1u64 << 32, u64::MAX - 15] {
            for inc in [IncrementCounter::No, IncrementCounter::Yes] {
                for (flags,start,end) in [(0,1,2), (16,1,10), (4,0,8), (32,1,2), (64,1,10)] {
                    let key = [0x12345678,0x87654321,2,3,4,5,6,0xfedcba98];
                    let mut got = [0xa5u8;32*OUT_LEN+1];
                    unsafe { hash32(&refs, &key, counter, inc, flags, start, end, &mut got); }
                    for (i,input) in refs.iter().enumerate() {
                        let mut cv = key;
                        let c = counter.wrapping_add(if inc.yes() { i as u64 } else { 0 });
                        for (b,block) in input.chunks_exact(BLOCK_LEN).enumerate() {
                            crate::portable::compress_in_place(&mut cv, block.try_into().unwrap(), BLOCK_LEN as u8, c,
                                flags | if b == 0 { start } else { 0 } | if b+1 == N/BLOCK_LEN { end } else { 0 });
                        }
                        for w in 0..8 { assert_eq!(&got[i*OUT_LEN+4*w..][..4], &cv[w].to_le_bytes(), "N={N} counter={c} flags={flags}"); }
                    }
                    assert_eq!(got[32*OUT_LEN], 0xa5, "output canary");
                }
            }
        }
    }

    #[test]
    fn randomized_counters_flags_and_block_counts() {
        if !crate::platform::avx512_detected() { return; }
        check::<64>(); check::<128>(); check::<192>(); check::<256>();
        check::<320>(); check::<384>(); check::<448>(); check::<512>();
        check::<576>(); check::<640>(); check::<704>(); check::<768>();
        check::<832>(); check::<896>(); check::<960>(); check::<1024>();
    }

    #[test]
    fn short_last_blocks_unaligned_and_overlapping_output() {
        if !crate::platform::avx512_detected() { return; }
        for blocks in [1, 2, 16] {
            let n = blocks * BLOCK_LEN;
            for last_len in [0, 1, 31, 63, 64] {
                // Every input starts one byte past alignment. Compute the
                // reference first, then overwrite the input with the digests.
                let mut data = vec![0u8; 1 + 32*n];
                for (i,b) in data[1..].iter_mut().enumerate() { *b = ((i*13+i/251)%251) as u8; }
                for i in 0..32 { data[1+i*n+(blocks-1)*BLOCK_LEN+last_len..1+(i+1)*n].fill(0); }
                for inc in [false, true] {
                    let mut input = data.clone();
                    let key = [11,22,33,44,55,66,77,88];
                    let counter = u32::MAX as u64 - 15;
                    let mut want = [0u8;32*OUT_LEN];
                    for i in 0..32 {
                        let mut cv = key;
                        for b in 0..blocks {
                            let at = 1+i*n+b*BLOCK_LEN;
                            crate::portable::compress_in_place(&mut cv, input[at..at+BLOCK_LEN].try_into().unwrap(),
                                if b+1 == blocks { last_len as u8 } else { BLOCK_LEN as u8 },
                                counter+if inc { i as u64 } else { 0 },
                                16 | if b == 0 { 1 } else { 0 } | if b+1 == blocks { 10 } else { 0 });
                        }
                        for w in 0..8 { want[i*OUT_LEN+4*w..][..4].copy_from_slice(&cv[w].to_le_bytes()); }
                    }
                    let pointers: [*const u8;32] = core::array::from_fn(|i| input[1+i*n..].as_ptr());
                    let packed = 16 | (1<<8) | (10<<16) | ((last_len as u64)<<24);
                    unsafe {
                        let kernel = if inc { blake3_avx512_k32 } else { blake3_avx512_p32 };
                        kernel(pointers.as_ptr(), blocks as u64, key.as_ptr(), counter, packed, input.as_mut_ptr().add(1));
                    }
                    assert_eq!(&input[1..1+32*OUT_LEN], &want, "blocks={blocks} last_len={last_len} increment={inc}");
                    assert_eq!(input[0], data[0], "leading canary");
                    assert_eq!(&input[1+32*OUT_LEN..], &data[1+32*OUT_LEN..], "trailing input untouched");
                }
            }
        }
    }

    #[test]
    fn generated_assembly_matches() {
        let output = std::process::Command::new("python3")
            .arg(concat!(env!("CARGO_MANIFEST_DIR"), "/tools/gen_avx512_32.py"))
            .output().expect("Python runs the assembly generator");
        assert!(output.status.success());
        assert_eq!(output.stdout, include_bytes!("../c/blake3_avx512_32.S"));
    }
}
