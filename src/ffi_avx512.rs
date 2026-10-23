use crate::{BLOCK_LEN, CVWords, IncrementCounter, OUT_LEN};

// Unsafe because this may only be called on platforms supporting AVX-512.
pub unsafe fn compress_in_place(cv: &mut CVWords, block: &[u8; BLOCK_LEN], block_len: u8, counter: u64, flags: u8) {
    unsafe { ffi::blake3_compress_in_place_avx512(cv.as_mut_ptr(), block.as_ptr(), block_len, counter, flags) }
}

// Unsafe because this may only be called on platforms supporting AVX-512.
pub unsafe fn compress_xof(cv: &CVWords, block: &[u8; BLOCK_LEN], block_len: u8, counter: u64, flags: u8) -> [u8; 64] {
    unsafe {
        let mut out = [0u8; 64];
        ffi::blake3_compress_xof_avx512(cv.as_ptr(), block.as_ptr(), block_len, counter, flags, out.as_mut_ptr());
        out
    }
}

// Unsafe because this may only be called on platforms supporting AVX-512.
pub unsafe fn hash_many<const N: usize>(
    inputs: &[&[u8; N]],
    key: &CVWords,
    counter: u64,
    increment_counter: IncrementCounter,
    flags: u8,
    flags_start: u8,
    flags_end: u8,
    out: &mut [u8],
) {
    unsafe {
        // The Rust hash_many implementations do bounds checking on the `out`
        // array, but the C implementations don't. Even though this is an unsafe
        // function, assert the bounds here.
        assert!(out.len() >= inputs.len() * OUT_LEN);
        #[cfg(target_os = "linux")]
        let (inputs, counter, out) = {
            let done = if N == crate::CHUNK_LEN {
                // Bounded iterators own progress, rather than a mutable
                // arithmetic cursor. Every call gets exactly one output group.
                for (group, (batch, outputs)) in inputs.chunks_exact(32).zip(out.chunks_exact_mut(32 * OUT_LEN)).enumerate() {
                    let first = group * 32;
                    crate::avx512_32::hash32(
                        batch,
                        key,
                        counter.wrapping_add(if increment_counter.yes() { first as u64 } else { 0 }),
                        increment_counter,
                        flags,
                        flags_start,
                        flags_end,
                        outputs,
                    );
                }
                let done = inputs.len() / 32 * 32;
                // The old assembly's zero-input path still initializes counters
                // and visits its smaller-width entry points. Do not enter it
                // when the new kernel has already consumed the entire slice.
                if done == inputs.len() {
                    return;
                }
                done
            } else if N == BLOCK_LEN && !increment_counter.yes() && flags & crate::PARENT != 0 {
                // Experiment only on parent nodes, not batches of short roots.
                for (batch, outputs) in inputs.chunks_exact(16).zip(out.chunks_exact_mut(16 * OUT_LEN)) {
                    crate::avx512_32::hash16(batch, key, counter, flags, flags_start, flags_end, outputs);
                }
                let done = inputs.len() / 16 * 16;
                if done == inputs.len() {
                    return;
                }
                done
            } else {
                0
            };
            (&inputs[done..], counter.wrapping_add(if increment_counter.yes() { done as u64 } else { 0 }), &mut out[done * OUT_LEN..])
        };
        crate::ran_kernel(ffi::blake3_hash_many_avx512 as *const ());
        ffi::blake3_hash_many_avx512(
            inputs.as_ptr() as *const *const u8,
            inputs.len(),
            N / BLOCK_LEN,
            key.as_ptr(),
            counter,
            increment_counter.yes(),
            flags,
            flags_start,
            flags_end,
            out.as_mut_ptr(),
        )
    }
}

/// Existing register-message kernel for pooled group chunks.
/// Caller detected AVX-512 F+VL. No new assembly or counter convention.
#[cfg(target_os = "linux")]
pub(crate) unsafe fn hash_chunks_legacy(inputs: &[&[u8; crate::CHUNK_LEN]], key: &CVWords, counter: u64, flags: u8, out: &mut [u8]) {
    assert!(out.len() / OUT_LEN >= inputs.len(), "output buffer too short");
    crate::ran_kernel(ffi::blake3_hash_many_avx512 as *const ());
    unsafe {
        ffi::blake3_hash_many_avx512(
            inputs.as_ptr().cast(),
            inputs.len(),
            crate::CHUNK_LEN / BLOCK_LEN,
            key.as_ptr(),
            counter,
            true,
            flags,
            crate::CHUNK_START,
            crate::CHUNK_END,
            out.as_mut_ptr(),
        )
    };
}

// Unsafe because this may only be called on platforms supporting AVX-512.
#[cfg(unix)]
pub unsafe fn xof_many(cv: &CVWords, block: &[u8; BLOCK_LEN], block_len: u8, counter: u64, flags: u8, out: &mut [u8]) {
    unsafe {
        debug_assert_eq!(0, out.len() % BLOCK_LEN, "whole blocks only");
        ffi::blake3_xof_many_avx512(cv.as_ptr(), block.as_ptr(), block_len, counter, flags, out.as_mut_ptr(), out.len() / BLOCK_LEN);
    }
}

pub mod ffi {
    unsafe extern "C" {
        pub fn blake3_compress_in_place_avx512(cv: *mut u32, block: *const u8, block_len: u8, counter: u64, flags: u8);
        pub fn blake3_compress_xof_avx512(cv: *const u32, block: *const u8, block_len: u8, counter: u64, flags: u8, out: *mut u8);
        pub fn blake3_hash_many_avx512(
            inputs: *const *const u8,
            num_inputs: usize,
            blocks: usize,
            key: *const u32,
            counter: u64,
            increment_counter: bool,
            flags: u8,
            flags_start: u8,
            flags_end: u8,
            out: *mut u8,
        );
        #[cfg(unix)]
        pub fn blake3_xof_many_avx512(cv: *const u32, block: *const u8, block_len: u8, counter: u64, flags: u8, out: *mut u8, outblocks: usize);
    }
}

#[cfg(all(test, unix))]
mod test {
    use super::*;

    #[test]
    #[cfg(all(target_os = "linux", feature = "std"))]
    fn test_wide_dispatch_groups_tails_and_bounds() {
        if !crate::platform::avx512_detected() {
            return;
        }
        let mut data = std::vec![[0u8; crate::CHUNK_LEN]; 65];
        crate::test::paint_test_input(data.as_flattened_mut());
        let inputs: std::vec::Vec<_> = data.iter().collect();
        let counter = u64::MAX - 15;
        let key = crate::IV;
        let legacy = ffi::blake3_hash_many_avx512 as *const () as usize;
        for increment in [IncrementCounter::No, IncrementCounter::Yes] {
            for n in [0, 1, 16, 31, 32, 33, 64, 65] {
                let mut out = std::vec![0xa5u8; n * OUT_LEN + 1];
                crate::RAN_ENTRIES.with(|r| r.borrow_mut().clear());
                unsafe { hash_many(&inputs[..n], key, counter, increment, crate::KEYED_HASH, crate::CHUNK_START, crate::CHUNK_END, &mut out) };
                let mut expected_entries = std::collections::BTreeSet::new();
                if n >= 32 {
                    let entry = crate::avx512_32::entries()[if increment.yes() { 0 } else { 1 }].1;
                    expected_entries.insert(entry as usize);
                }
                if n % 32 != 0 {
                    expected_entries.insert(legacy);
                }
                assert_eq!(crate::RAN_ENTRIES.with(|r| r.borrow().clone()), expected_entries, "dispatch for {n} inputs");
                for (i, &input) in inputs[..n].iter().enumerate() {
                    let mut expected = [0u8; OUT_LEN];
                    crate::portable::hash1(
                        input,
                        key,
                        counter.wrapping_add(if increment.yes() { i as u64 } else { 0 }),
                        crate::KEYED_HASH,
                        crate::CHUNK_START,
                        crate::CHUNK_END,
                        &mut expected,
                    );
                    assert_eq!(&out[i * OUT_LEN..][..OUT_LEN], &expected);
                }
                assert_eq!(out[n * OUT_LEN], 0xa5, "output canary");
            }
        }
        // Zip must never silently truncate an undersized output. Reject it
        // before entering either assembly kernel or writing any output byte.
        let mut short = [0xa5u8; 32 * OUT_LEN - 1];
        crate::RAN_ENTRIES.with(|r| r.borrow_mut().clear());
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| unsafe {
            hash_many(&inputs[..32], key, 0, IncrementCounter::Yes, 0, 1, 2, &mut short);
        }));
        assert!(result.is_err());
        assert!(crate::RAN_ENTRIES.with(|r| r.borrow().is_empty()));
        assert!(short.iter().all(|&b| b == 0xa5));

        // A batch of one-block roots still takes the older kernel, not
        // the wide full-chunk path (whose all-length experiment regressed).
        let blocks = [[0x39u8; BLOCK_LEN]; 32];
        let refs: std::vec::Vec<_> = blocks.iter().collect();
        let mut out = [0u8; 32 * OUT_LEN];
        crate::RAN_ENTRIES.with(|r| r.borrow_mut().clear());
        unsafe { hash_many(&refs, key, 0, IncrementCounter::No, 0, crate::CHUNK_START, crate::CHUNK_END | crate::ROOT, &mut out) };
        assert_eq!(crate::RAN_ENTRIES.with(|r| r.borrow().clone()), [legacy].into_iter().collect());
        let mut expected = [0u8; OUT_LEN];
        crate::portable::hash1(&blocks[0], key, 0, 0, crate::CHUNK_START, crate::CHUNK_END | crate::ROOT, &mut expected);
        assert!(out.chunks_exact(OUT_LEN).all(|bytes| bytes == expected));
    }

    #[test]
    #[cfg(all(target_os = "linux", feature = "std"))]
    fn test_parent16_dispatch_and_legacy_incrementing_route() {
        if !crate::platform::avx512_detected() {
            return;
        }
        let mut data = std::vec![[0u8; BLOCK_LEN]; 33];
        crate::test::paint_test_input(data.as_flattened_mut());
        let inputs: std::vec::Vec<_> = data.iter().collect();
        let legacy = ffi::blake3_hash_many_avx512 as *const () as usize;
        let parent = crate::avx512_32::parent_entry() as usize;
        let counter = u64::MAX - 7;
        let flags = crate::PARENT | crate::KEYED_HASH;
        for increment in [IncrementCounter::No, IncrementCounter::Yes] {
            for n in [0, 1, 15, 16, 17, 32, 33] {
                let mut out = std::vec![0xa5u8; n * OUT_LEN + 1];
                crate::RAN_ENTRIES.with(|r| r.borrow_mut().clear());
                unsafe { hash_many(&inputs[..n], crate::IV, counter, increment, flags, 0, 0, &mut out) };
                let mut expected_entries = std::collections::BTreeSet::new();
                if increment.yes() {
                    expected_entries.insert(legacy);
                } else {
                    if n >= 16 {
                        expected_entries.insert(parent);
                    }
                    if n % 16 != 0 {
                        expected_entries.insert(legacy);
                    }
                }
                assert_eq!(crate::RAN_ENTRIES.with(|r| r.borrow().clone()), expected_entries);
                for (i, &input) in inputs[..n].iter().enumerate() {
                    let mut expected = [0u8; OUT_LEN];
                    crate::portable::hash1(input, crate::IV, counter.wrapping_add(if increment.yes() { i as u64 } else { 0 }), flags, 0, 0, &mut expected);
                    assert_eq!(&out[i * OUT_LEN..][..OUT_LEN], &expected);
                }
                assert_eq!(out[n * OUT_LEN], 0xa5);
            }
        }
    }

    #[test]
    #[cfg(all(target_os = "linux", feature = "std"))]
    fn test_legacy_group_output_bound_precedes_assembly() {
        if !crate::platform::avx512_detected() {
            return;
        }
        let input = [0u8; crate::CHUNK_LEN];
        let mut out = [0xa5u8; OUT_LEN - 1];
        crate::RAN_ENTRIES.with(|r| r.borrow_mut().clear());
        let rejected = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| unsafe {
            hash_chunks_legacy(&[&input], crate::IV, 0, 0, &mut out);
        }));
        assert!(rejected.is_err());
        assert_eq!(out, [0xa5; OUT_LEN - 1]);
        assert!(crate::RAN_ENTRIES.with(|r| r.borrow().is_empty()));
    }

    #[test]
    fn test_xof_many() {
        if !crate::platform::avx512_detected() {
            return;
        }
        crate::test::test_xof_many_fn(xof_many);
    }
}
