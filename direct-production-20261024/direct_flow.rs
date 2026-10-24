//! Experimental direct production/use model; never the published benchmark.
//!
//! A producer computes words directly in the final aligned input storage.
//! A consumer reads all 32 digest bytes there and folds them into one scalar
//! checksum. Neither end copies a message/digest from/to another buffer.
//! Timings still include production, hashing and consumption, through the
//! normal bench-hashes timing, load, samples and comparison machinery.
//!
//! Selected cells: ST LentMessages = synchronous hash_with; ST LentBatches
//! = synchronous hash_many; MT ContinuousMessages/ContinuousBatches = one
//! sustained Stream per sample, producer writing directly into its ring.
//! Input allocations/output tables persist across samples. Stream setup,
//! draining and free-slot bookkeeping remain part of the streaming cost.
use super::*;
use blake3_servil::{Hash, Mode};

struct Space {
    input: Vec<u8>,
    at: usize,
    output: Vec<Hash>,
}

impl Space {
    fn new(bytes: usize, messages: usize) -> Self {
        let input = written(bytes + BATCH_SPARE, 1u8);
        let at = input.as_ptr().align_offset(64);
        assert!(at <= BATCH_SPARE);
        Self {
            input,
            at,
            output: vec![Hash::from([0; 32]); messages],
        }
    }
}

thread_local! {
    static SPACES: std::cell::RefCell<crate::Map<(usize, usize), Space>> =
        std::cell::RefCell::new(crate::Map::default());
}

/// Each word is computed from this message's sequence and word position,
/// then stored at its final address. No source message exists to memcpy.
/// All experiment inputs are whole 64-byte blocks, including ring pieces.
#[inline]
fn produce(at: usize, room: &mut [u8], sequence: u64) {
    assert_eq!(at % 8, 0);
    assert_eq!(room.len() % 8, 0);
    assert_eq!(room.as_ptr() as usize % 64, 0);
    for (i, word) in room.chunks_exact_mut(8).enumerate() {
        let value = sequence
            .wrapping_add((at / 8 + i) as u64)
            .wrapping_mul(0x9e3779b97f4a7c15);
        // Sound: word holds exactly 8 writable bytes. These are generated
        // values stored in place, not loads from an earlier message buffer.
        unsafe {
            word.as_mut_ptr()
                .cast::<u64>()
                .write_unaligned(value.to_le())
        };
    }
    black_box(room);
}

/// Use every digest word in place. A scalar accumulator is the consumer's
/// result; there is no separate digest array or 32-byte return value here.
#[inline]
fn use_in_place(place: &Hash, checksum: &mut u64) {
    let bytes = black_box(place.as_bytes());
    for word in bytes.chunks_exact(8) {
        // Sound: exactly 8 readable bytes; the digest need not be u64-aligned.
        let value = u64::from_le(unsafe { word.as_ptr().cast::<u64>().read_unaligned() });
        *checksum = checksum.wrapping_add(value);
    }
}

fn synchronous(len: usize, messages: usize, batch: bool, iterations: usize) {
    assert!(len > 0 && len % 64 == 0);
    SPACES.with_borrow_mut(|spaces| {
        let bytes = len * messages;
        let space = spaces
            .entry((len, messages))
            .or_insert_with(|| Space::new(bytes, messages));
        let input = &mut space.input[space.at..space.at + bytes];
        let mut checksum = 0;
        for sequence in 0..iterations {
            // The single-message case needs its result before producing
            // the next value: this is a latency chain, not independent
            // hashes that an out-of-order CPU could overlap.
            let seed = if batch {
                sequence as u64
            } else {
                checksum ^ sequence as u64
            };
            produce(0, input, black_box(seed));
            if batch {
                // Sound: Hash is repr(transparent) over [u8; 32]; this is
                // the same heap allocation, viewed in hash_many's type.
                let output = unsafe {
                    core::slice::from_raw_parts_mut(
                        space.output.as_mut_ptr().cast::<[u8; 32]>(),
                        messages,
                    )
                };
                blake3_servil::hash_many(black_box(input), len, output);
            } else {
                blake3_servil::hash_with(Mode::Hash, black_box(input), &mut space.output[0]);
            }
            for place in &space.output {
                use_in_place(place, &mut checksum);
            }
        }
        black_box(checksum);
    });
}

fn streaming(len: usize, messages: usize, batch: bool, iterations: usize) {
    assert!(len > 0 && len % 64 == 0);
    let in_flight = if batch {
        ((8 << 20) / (len * messages)).clamp(2, 1024)
    } else {
        STREAM_PLACES_PER_MESSAGE
    };
    let mut places = take_places(in_flight * messages);
    let free = std::cell::RefCell::new(places.chunks_mut(messages).collect::<Vec<_>>());
    let mut checksum = 0;
    blake3_servil::stream(
        Mode::Hash,
        |place: &mut [Hash]| {
            for digest in &*place {
                use_in_place(digest, &mut checksum);
            }
            free.borrow_mut().push(place);
        },
        |s| {
            for sequence in 0..iterations {
                let place = free_place(&free, s);
                let seed = black_box(sequence as u64);
                if batch {
                    s.submit_batch_with(len, |at, room| produce(at, room, seed), place);
                } else {
                    s.submit_with(len, |at, room| produce(at, room, seed), &mut place[0]);
                }
            }
            s.finish();
        },
    );
    black_box(checksum);
    drop(free);
    keep_places(places);
}

/// Return false for cells this experiment does not change. Standard
/// correctness tests of hash_batch and other cells keep their semantics.
pub(super) fn run(algorithm: Algorithm, point: Point, iterations: usize) -> bool {
    match (algorithm, point.use_case) {
        (Algorithm::Blake3ServilSt, UseCase::LentMessages) => {
            synchronous(point.bytes, 1, false, iterations)
        }
        (Algorithm::Blake3ServilSt, UseCase::LentBatches) => {
            synchronous(MESSAGE_LEN, point.messages, true, iterations)
        }
        (Algorithm::Blake3ServilMt, UseCase::ContinuousMessages) => {
            streaming(point.bytes, 1, false, iterations)
        }
        (Algorithm::Blake3ServilMt, UseCase::ContinuousBatches) => {
            streaming(MESSAGE_LEN, point.messages, true, iterations)
        }
        _ => return false,
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn direct_input_and_output_have_the_expected_bytes_and_stable_places() {
        blake3_servil::initialize();
        for len in [64, 256, 1024] {
            let mut space = Space::new(len * 16, 16);
            let input = &mut space.input[space.at..space.at + len * 16];
            let input_address = input.as_ptr();
            let output_address = space.output.as_ptr();
            for sequence in 0..3 {
                produce(0, input, sequence);
                for (i, word) in input.chunks_exact(8).enumerate() {
                    let expected = sequence
                        .wrapping_add(i as u64)
                        .wrapping_mul(0x9e3779b97f4a7c15);
                    assert_eq!(word, expected.to_le_bytes());
                }
                let out = unsafe {
                    core::slice::from_raw_parts_mut(
                        space.output.as_mut_ptr().cast::<[u8; 32]>(),
                        16,
                    )
                };
                blake3_servil::hash_many(input, len, out);
                let mut checksum = 0;
                for (message, digest) in input.chunks_exact(len).zip(&space.output) {
                    assert_eq!(*digest, blake3_servil::hash(message));
                    use_in_place(digest, &mut checksum);
                }
                assert_eq!(input.as_ptr(), input_address);
                assert_eq!(space.output.as_ptr(), output_address);
            }
        }
    }

    #[test]
    fn direct_stream_rooms_and_destinations_match_the_serial_reference() {
        blake3_servil::initialize_multithreaded(None);
        // Generate directly into real ring rooms; use callbacks to verify
        // digests without a separate production-side message copy.
        for len in [64, 256, 1024] {
            let mut places = vec![Hash::from([0; 32]); 64];
            let mut delivered = 0;
            blake3_servil::stream(
                Mode::Hash,
                |out: &mut [Hash]| {
                    assert_eq!(out.len(), 1);
                    let mut reference = Space::new(len, 1);
                    let input = &mut reference.input[reference.at..reference.at + len];
                    produce(0, input, delivered as u64);
                    assert_eq!(out[0], blake3_servil::hash(input));
                    delivered += 1;
                },
                |s| {
                    for (i, out) in places.iter_mut().enumerate() {
                        s.submit_with(len, |at, room| produce(at, room, i as u64), out);
                    }
                    s.finish();
                },
            );
            assert_eq!(delivered, 64);
        }
    }
}
