//! FFI bridge to the Lean-4-verified single-threaded BLAKE3 machine code
//! produced by Ode (`samshackleton-tech/ode`):
//! - x86-64: `blake3_servil_ode_hashr` (14/14 functions, 3,761 instructions,
//!   AVX-512 32-way when `plat == 5`, SSE4.1 otherwise).
//! - AArch64: `blake3_servil_ode_hashr_arm64` (6/6 functions, 368 instructions,
//!   NEON + scalar).

use crate::{CVWords, Hash, OUT_LEN, platform::Platform};

#[cfg(target_arch = "x86_64")]
unsafe extern "C" {
    fn blake3_servil_ode_hashr(
        out: *mut u8,
        input: *const u8,
        len: usize,
        key: *const u32,
        flags: u8,
        plat: u64,
    );
}

#[cfg(target_arch = "aarch64")]
unsafe extern "C" {
    fn blake3_servil_ode_hashr_arm64(
        out: *mut u8,
        input: *const u8,
        len: usize,
        key: *const u32,
        flags: u8,
    );
}

static EMPTY_INPUT: [u8; 1] = [0];

/// Hash `input` in one call using the Lean-4-verified Ode machine code for the
/// current target architecture.
#[inline]
pub(crate) fn hash(input: &[u8], key: &CVWords, flags: u8, platform: Platform) -> Hash {
    let mut out = [0u8; OUT_LEN];
    let in_ptr = if input.is_empty() { EMPTY_INPUT.as_ptr() } else { input.as_ptr() };

    #[cfg(target_arch = "x86_64")]
    {
        #[cfg(blake3_avx512_ffi)]
        let plat: u64 = if matches!(platform, Platform::AVX512) { 5 } else { 3 };
        #[cfg(not(blake3_avx512_ffi))]
        let plat: u64 = {
            let _ = platform;
            3
        };
        // Sound: `out` is a fresh stack 32-byte array disjoint from `input` and
        // `key`; `input` is valid for `input.len()` bytes; `key` is a 32-byte
        // `[u32; 8]`; `plat == 5` only when AVX-512 has been detected.
        unsafe {
            blake3_servil_ode_hashr(out.as_mut_ptr(), in_ptr, input.len(), key.as_ptr(), flags, plat);
        }
    }

    #[cfg(target_arch = "aarch64")]
    {
        let _ = platform;
        // Sound: `out` is a fresh stack 32-byte array disjoint from `input` and
        // `key`; `input` is valid for `input.len()` bytes; `key` is a 32-byte
        // `[u32; 8]`.
        unsafe {
            blake3_servil_ode_hashr_arm64(out.as_mut_ptr(), in_ptr, input.len(), key.as_ptr(), flags);
        }
    }

    Hash(out)
}

#[cfg(all(test, feature = "std"))]
mod test {
    use crate::{Mode, convenience};

    #[test]
    fn ode_verified_matches_official_blake3_all_modes_and_boundaries() {
        crate::initialize();
        let max_len = 1024 * 1024 + 7;
        let mut buf = vec![0u8; max_len + 13];
        for (i, b) in buf.iter_mut().enumerate() {
            *b = (i % 251) as u8;
        }
        let key = [0x42u8; 32];
        let ctx = "ode-verified BLAKE3 integration test 2026-11-24";
        let lens = [
            0, 1, 2, 3, 63, 64, 65, 127, 128, 1023, 1024, 1025, 2047, 2048, 2049,
            3072, 4096, 8192, 16384, 16385, 32767, 32768, 32769, 65535, 65536, 65537,
            131071, 131072, 131073, 262144, 1048576, max_len,
        ];
        for &len in &lens {
            // Unaligned offset (+3) to exercise arbitrary alignment
            let slice = &buf[3..3 + len];
            let got_plain = convenience::hash(slice);
            let want_plain = blake3::hash(slice);
            assert_eq!(got_plain.as_bytes(), want_plain.as_bytes(), "plain len={len}");

            let got_keyed = convenience::hash_with(Mode::Keyed(&key), slice);
            let want_keyed = blake3::keyed_hash(&key, slice);
            assert_eq!(got_keyed.as_bytes(), want_keyed.as_bytes(), "keyed len={len}");

            let got_dk = convenience::hash_with(Mode::DeriveKey(ctx), slice);
            let want_dk = blake3::derive_key(ctx, slice);
            assert_eq!(got_dk.as_bytes(), &want_dk, "derive_key len={len}");
        }
    }
}
