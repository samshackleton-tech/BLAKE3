//! Simple C guards diagnose bad arguments before borrowing their storage.
use b3_servil::*;
use core::ffi::{c_char, c_void};
use core::mem::{MaybeUninit, size_of};

const CHILD: &str = "B3_CAPI_GUARD_CASE";
const CASES: &[(&str, &str)] = &[
    ("callback-null", "the done callback is NULL"),
    ("hasher-init-alignment", "the hasher is not 64-byte aligned"),
    ("hasher-read-alignment", "the hasher is not 64-byte aligned"),
    ("hasher-mode-overlap", "input and output ranges overlap"),
    ("input-null", "the input is NULL"),
    ("input-length", "the input length exceeds isize::MAX"),
    ("input-wrap", "the input address range overflows"),
    ("batch-stride", "batch stride overflows size_t"),
    ("batch-count", "the batch's length fits a size_t"),
    ("batch-overlap", "input and output ranges overlap"),
    ("batch-overlap-reverse", "input and output ranges overlap"),
    ("hasher-update-overlap", "input and output ranges overlap"),
    ("hasher-output-overlap", "input and output ranges overlap"),
    ("output-length", "the output length exceeds isize::MAX"),
    ("stream-overlap", "input and output ranges overlap"),
    ("stream-alignment", "the stream handle is misaligned"),
    // The native contract cases from the older contracts.rs, using the
    // current guards' actual diagnostics. This is the one shared inventory
    // consumed by both the native child runner and the Miri driver.
    ("input NULL", "the input is NULL with a length of 5"),
    ("mode NULL", "the mode is NULL"),
    ("mode unmade", "a b3_mode made by b3_plain, b3_keyed, or b3_derive_key (kind 9)"),
    ("key NULL", "the key is NULL"),
    ("context NULL", "the context is NULL"),
    ("context not UTF-8", "the context is UTF-8"),
    ("batch misplaced", "a batch starts at a 64-byte boundary"),
    ("batch NULL", "the batch is NULL with a length of 128"),
    ("batch too long", "the batch length exceeds isize::MAX"),
    ("digests NULL", "the digests' storage is NULL"),
    ("hasher NULL", "the hasher is NULL"),
    ("output NULL", "the output is NULL with a length of 5"),
    ("stream NULL", "the stream is NULL"),
    ("place NULL", "the digest's place is NULL"),
    ("stream input NULL", "the input is NULL with a length of 3"),
    ("message misplaced", "a submitted message starts at a 64-byte boundary"),
    ("stream-rounded-length", "the submitted block range exceeds isize::MAX"),
];

#[repr(align(64))]
struct Arena([u8; size_of::<B3Hasher>() + 64]);

unsafe extern "C" fn done(_: *mut c_void, _: *mut Digest, _: usize) {}

unsafe fn bad_call(case: &str) {
    let mode = b3_plain();
    let mut arena = Arena([42; size_of::<B3Hasher>() + 64]);
    let pointer = arena.0.as_mut_ptr();
    let mut output = [Digest { bytes: [0; 32] }; 2];
    let mut hasher = MaybeUninit::<B3Hasher>::uninit();
    unsafe {
        match case {
            "callback-null" => {
                b3_stream_begin(&mode, None, core::ptr::null_mut());
            }
            "hasher-init-alignment" => b3_hasher_init(pointer.add(1).cast(), &mode),
            "hasher-read-alignment" => {
                b3_hasher_init(pointer.cast(), &mode);
                b3_hasher_finalize(pointer.add(1).cast());
            }
            "hasher-mode-overlap" => {
                pointer.cast::<B3Mode>().write(mode);
                b3_hasher_init(pointer.cast(), pointer.cast());
            }
            "input-null" => {
                b3_hash(&mode, core::ptr::null(), 1);
            }
            "input-length" => {
                b3_hash(&mode, pointer.cast(), isize::MAX as usize + 1);
            }
            "input-wrap" => {
                b3_hash(&mode, core::ptr::without_provenance(usize::MAX - 7), 16);
            }
            "batch-stride" => b3_hash_many(&mode, pointer.cast(), usize::MAX, 1, output.as_mut_ptr()),
            "batch-count" => b3_hash_many(&mode, pointer.cast(), 64, usize::MAX, output.as_mut_ptr()),
            "batch-overlap" => b3_hash_many(&mode, pointer.cast(), 64, 2, pointer.add(32).cast()),
            "batch-overlap-reverse" => b3_hash_many(&mode, pointer.add(64).cast(), 64, 2, pointer.add(32).cast()),
            "hasher-update-overlap" => {
                b3_hasher_init(hasher.as_mut_ptr(), &mode);
                b3_hasher_update(hasher.as_mut_ptr(), hasher.as_ptr().cast(), 1);
            }
            "hasher-output-overlap" => {
                b3_hasher_init(hasher.as_mut_ptr(), &mode);
                b3_hasher_output(hasher.as_ptr(), 0, hasher.as_mut_ptr().cast(), 32);
            }
            "output-length" => {
                b3_hasher_init(hasher.as_mut_ptr(), &mode);
                b3_hasher_output(hasher.as_ptr(), 0, output.as_mut_ptr().cast(), isize::MAX as usize + 1);
            }
            "stream-overlap" => {
                let stream = b3_stream_begin(&mode, Some(done), core::ptr::null_mut());
                b3_stream_submit(stream, pointer.cast(), 64, pointer.cast());
            }
            "stream-alignment" => {
                let stream = b3_stream_begin(&mode, Some(done), core::ptr::null_mut());
                b3_stream_collect(stream.cast::<u8>().add(1).cast());
            }
            "input NULL" => {
                b3_hash(&mode, core::ptr::null(), 5);
            }
            "mode NULL" => {
                b3_hash(core::ptr::null(), pointer.cast(), 5);
            }
            "mode unmade" => {
                let mut unmade = mode;
                *(&mut unmade as *mut B3Mode as *mut u8) = 9;
                b3_hash(&unmade, pointer.cast(), 5);
            }
            "key NULL" => {
                b3_keyed(core::ptr::null());
            }
            "context NULL" => {
                b3_derive_key(core::ptr::null());
            }
            "context not UTF-8" => {
                b3_derive_key(b"\xff\0".as_ptr().cast::<c_char>());
            }
            "batch misplaced" => b3_hash_many(&mode, pointer.add(1).cast(), 64, 1, output.as_mut_ptr()),
            "batch NULL" => b3_hash_many(&mode, core::ptr::null(), 64, 2, output.as_mut_ptr()),
            "batch too long" => b3_hash_many(&mode, pointer.cast(), 64, usize::MAX / 32, output.as_mut_ptr()),
            "digests NULL" => b3_hash_many(&mode, pointer.cast(), 1, 2, core::ptr::null_mut()),
            "hasher NULL" => b3_hasher_update(core::ptr::null_mut(), pointer.cast(), 5),
            "output NULL" => {
                b3_hasher_init(hasher.as_mut_ptr(), &mode);
                b3_hasher_output(hasher.as_ptr(), 0, core::ptr::null_mut(), 5);
            }
            "stream NULL" => b3_stream_submit(core::ptr::null_mut(), pointer.cast(), 5, output.as_mut_ptr()),
            "place NULL" => {
                let stream = b3_stream_begin(&mode, Some(done), core::ptr::null_mut());
                b3_stream_submit(stream, pointer.cast(), 5, core::ptr::null_mut());
            }
            "stream input NULL" => {
                let stream = b3_stream_begin(&mode, Some(done), core::ptr::null_mut());
                b3_stream_submit(stream, core::ptr::null(), 3, output.as_mut_ptr());
            }
            "message misplaced" => {
                let stream = b3_stream_begin(&mode, Some(done), core::ptr::null_mut());
                b3_stream_submit(stream, pointer.add(1).cast(), 5, output.as_mut_ptr());
            }
            "stream-rounded-length" => {
                let stream = b3_stream_begin(&mode, Some(done), core::ptr::null_mut());
                b3_stream_submit(stream, pointer.cast(), isize::MAX as usize, output.as_mut_ptr());
            }
            _ => panic!("unknown guard case"),
        }
    }
    panic!("guard did not stop {case}");
}

#[test]
#[cfg_attr(miri, ignore = "select an individual B3_CAPI_GUARD_CASE with --run-ignored only")]
fn bad_calls_stop_at_the_guard() {
    if let Ok(case) = std::env::var(CHILD) {
        if case == "list" {
            println!("\nB3_CAPI_GUARD_CASES={}", serde_json::to_string(CASES).unwrap());
            return;
        }
        unsafe { bad_call(&case) };
    }
    assert!(!cfg!(miri), "select an individual guard case under Miri");
    for &(case, message) in CASES {
        let result = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "bad_calls_stop_at_the_guard", "--nocapture", "--test-threads", "1"])
            .env(CHILD, case)
            .env("RUST_BACKTRACE", "0")
            .output()
            .unwrap();
        let error = String::from_utf8_lossy(&result.stderr);
        assert!(!result.status.success(), "{case}: the child returned");
        #[cfg(unix)]
        {
            use std::os::unix::process::ExitStatusExt;
            assert_eq!(result.status.signal(), Some(6), "{case}: expected SIGABRT, got {:?}: {error}", result.status);
        }
        assert!(error.contains(message), "{case}: missing guard diagnostic {message}: {error}");
        eprintln!("{case}: guard diagnostic and abort verified");
    }
}

#[test]
fn miri_adjacent_ranges_and_empty_null_ranges_are_allowed() {
    let mode = b3_plain();
    unsafe {
        // Exactly adjacent in both address orders, with initialized storage.
        for (input_at, out_at) in [(0, 128), (64, 0)] {
            let mut arena = Arena([42; size_of::<B3Hasher>() + 64]);
            let pointer = arena.0.as_mut_ptr();
            let input = pointer.add(input_at);
            let out = pointer.add(out_at).cast::<Digest>();
            b3_hash_many(&mode, input.cast(), 64, 2, out);
            let expected = b3_hash(&mode, input.cast(), 64);
            assert_eq!(*out, expected);
            assert_eq!(*out.add(1), expected);
        }
        for len in [0, 64] {
            b3_hash_many(&mode, core::ptr::null(), len, 0, core::ptr::null_mut());
        }
        let mut hasher = MaybeUninit::<B3Hasher>::uninit();
        b3_hasher_init(hasher.as_mut_ptr(), &mode);
        b3_hasher_update(hasher.as_mut_ptr(), core::ptr::null(), 0);
        b3_hasher_output(hasher.as_ptr(), 0, core::ptr::null_mut(), 0);
        let mut out = Digest { bytes: [0; 32] };
        let stream = b3_stream_begin(&mode, Some(done), core::ptr::null_mut());
        b3_stream_submit(stream, core::ptr::null(), 0, &mut out);
        b3_stream_finish(stream);
        assert_eq!(out, b3_hash(&mode, core::ptr::null(), 0));
    }
}
