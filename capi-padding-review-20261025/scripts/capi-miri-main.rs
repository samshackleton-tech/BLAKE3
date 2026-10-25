use b3::{hash, Hasher};
use std::ffi::c_void;
use std::mem::MaybeUninit;

#[repr(align(64))]
struct Input([u8; 128]);

unsafe extern "C" fn done(_: *mut c_void, _: *mut capi::Digest, count: usize) {
    assert_eq!(count, 1);
}

struct Context {
    stream: *mut capi::B3Stream,
    entered: bool,
}

unsafe extern "C" fn context_done(ctx: *mut c_void, _: *mut capi::Digest, count: usize) {
    assert_eq!(count, 1);
    let ctx = ctx.cast::<Context>();
    assert!(!unsafe { (*ctx).stream }.is_null());
    unsafe { (*ctx).entered = true };
}

unsafe extern "C" fn reenter(ctx: *mut c_void, _: *mut capi::Digest, _: usize) {
    let ctx = ctx.cast::<Context>();
    if !unsafe { (*ctx).entered } {
        unsafe { (*ctx).entered = true };
        // Deliberately invalid control: the outer C entry still borrows this stream.
        unsafe { capi::b3_stream_collect((*ctx).stream) };
    }
}

fn main() {
    let case = std::env::args().nth(1).expect("case");
    if case == "uninitialized-read-control" {
        let storage = MaybeUninit::<u8>::uninit();
        let byte = unsafe { storage.assume_init() };
        println!("{byte}");
        return;
    }
    let mode = capi::b3_plain();
    let mut input = Input([42; 128]);
    match case.as_str() {
        "batch-initialized" | "batch-uninitialized" => {
            let mut output = MaybeUninit::<[capi::Digest; 2]>::uninit();
            if case == "batch-initialized" {
                output.write([capi::Digest { bytes: [0; 32] }; 2]);
            }
            unsafe { capi::b3_hash_many(&mode, input.0.as_ptr().cast(), 64, 2, output.as_mut_ptr().cast()) };
            let output = unsafe { output.assume_init() };
            assert_eq!(output[0].bytes, hash(&input.0[..64]).as_bytes()[..]);
            assert_eq!(output[1].bytes, hash(&input.0[64..]).as_bytes()[..]);
        }
        "batch-overlap-control" => {
            let pointer = input.0.as_mut_ptr();
            // Deliberately overlapping initialized regions; interpret only under Miri.
            unsafe { capi::b3_hash_many(&mode, pointer.cast(), 64, 2, pointer.cast()) };
        }
        "xof-initialized" | "xof-uninitialized" => {
            let mut hasher = MaybeUninit::<capi::B3Hasher>::uninit();
            let mut output = MaybeUninit::<[u8; 33]>::uninit();
            if case == "xof-initialized" {
                output.write([0; 33]);
            }
            unsafe {
                capi::b3_hasher_init(hasher.as_mut_ptr(), &mode);
                capi::b3_hasher_update(hasher.as_mut_ptr(), input.0.as_ptr().cast(), 64);
                capi::b3_hasher_output(hasher.as_ptr(), 0, output.as_mut_ptr().cast(), 33);
            }
            let output = unsafe { output.assume_init() };
            let mut expected = [0; 33];
            Hasher::new().update(&input.0[..64]).finalize_xof().fill(&mut expected);
            assert_eq!(output, expected);
        }
        "stream-tail-uninitialized" => {
            #[repr(align(64))]
            struct Tail(MaybeUninit<[u8; 64]>);
            let mut storage = Tail(MaybeUninit::uninit());
            let pointer = storage.0.as_mut_ptr().cast::<u8>();
            unsafe { pointer.write(42) };
            let mut output = capi::Digest { bytes: [0; 32] };
            let stream = unsafe { capi::b3_stream_begin(&mode, done, std::ptr::null_mut()) };
            unsafe {
                capi::b3_stream_submit(stream, pointer.cast(), 1, &mut output);
                capi::b3_stream_finish(stream);
            }
            assert_eq!(output.bytes, hash(&[42]).as_bytes()[..]);
        }
        "stream-initialized" | "stream-uninitialized" | "stream-context-control" | "stream-reentry-control" => {
            let mut output = MaybeUninit::<capi::Digest>::uninit();
            if case != "stream-uninitialized" {
                output.write(capi::Digest { bytes: [0; 32] });
            }
            let context = Box::into_raw(Box::new(Context { stream: std::ptr::null_mut(), entered: false }));
            let stream = match case.as_str() {
                "stream-reentry-control" => unsafe { capi::b3_stream_begin(&mode, reenter, context.cast()) },
                "stream-context-control" => unsafe { capi::b3_stream_begin(&mode, context_done, context.cast()) },
                _ => unsafe { capi::b3_stream_begin(&mode, done, std::ptr::null_mut()) },
            };
            // Keep using the raw pointer whose provenance was passed to C.
            // A direct write through the original Rust owner would invalidate it.
            unsafe { (*context).stream = stream };
            unsafe {
                capi::b3_stream_submit(stream, input.0.as_ptr().cast(), 64, output.as_mut_ptr());
                capi::b3_stream_finish(stream);
            }
            assert_eq!(unsafe { output.assume_init() }.bytes, hash(&input.0[..64]).as_bytes()[..]);
            if case == "stream-context-control" {
                assert!(unsafe { (*context).entered });
            }
            drop(unsafe { Box::from_raw(context) });
        }
        _ => panic!("unknown case"),
    }
    println!("case completed: {case}");
}
