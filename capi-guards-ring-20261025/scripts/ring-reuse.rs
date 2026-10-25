//! Functional data-isolation probe using only safe public Rust calls.
use b3::{Hash, Mode, hash_with, stream};

fn first_caller() {
    let private_material = [0xA5; 64];
    let mode = Mode::DeriveKey("release test: ring reuse, dummy key material");
    let mut digest = Hash::from_bytes([0; 32]);
    stream(mode, |_| {}, |s| {
        s.submit_with(64, |at, room| room.copy_from_slice(&private_material[at..][..room.len()]), &mut digest);
        s.finish();
    });
    assert_eq!(digest, hash_with(mode, &private_material));
}

fn next_caller() -> [u8; 64] {
    let mut observed = [0u8; 64];
    let mut digest = Hash::from_bytes([0; 32]);
    stream(Mode::Hash, |_| {}, |s| {
        s.submit_with(64, |_, room| {
            observed.copy_from_slice(room);
            // This caller still overwrites every byte, as the fill contract asks.
            room.fill(0x3C);
        }, &mut digest);
        s.finish();
    });
    assert_eq!(digest, hash_with(Mode::Hash, &[0x3C; 64]));
    observed
}

fn main() {
    b3::initialize_multithreaded(std::num::NonZeroUsize::new(1));
    // Fresh allocation is the control; the first probe also fills its own bytes.
    assert_eq!(next_caller(), [0; 64]);
    first_caller();
    let observed = next_caller();
    assert_eq!(observed, [0xA5; 64], "does the next caller receive the prior caller's input?");
    println!("sequential safe callers: all 64 bytes of prior dummy key material observed before the next fill");
}
