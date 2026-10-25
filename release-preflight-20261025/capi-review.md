## Before the C ABI freezes: make its memory and callback contracts explicit

For release tracker #125. @johnservil @devonjonte

The Linux installed C11/C++11 static/shared tests pass on the #152 review
head. A separate source review found contract gaps that those passing
execution tests do not settle. These are review findings, not a reproduced
memory-corruption or exploit claim.

### 1. Output initialization versus Rust references

`capi/src/lib.rs` turns output storage into typed mutable references:

- `batch`: `slice::from_raw_parts_mut(out as *mut [u8; OUT_LEN], count)`;
- `b3_hasher_output`: `slice::from_raw_parts_mut(out as *mut u8, len)`;
- stream submission: `&mut *(out as *mut Hash)` and mutable Hash slices.

Their safety comments currently require “room” for the outputs. The
[documented from_raw_parts_mut contract](https://doc.rust-lang.org/std/slice/fn.from_raw_parts_mut.html#safety)
requires properly initialized values, as well as valid storage and
exclusivity. Meanwhile `capi/tests/check.c` passes local uninitialized
`b3_digest batch[4]` and `b3_digest bplaces[16]` as output buffers.

Before freezing this ABI, please decide and implement the output-storage
contract: support uninitialized C output storage without first constructing
references that require initialized values, or explicitly require initialized
output places and update every example/consumer accordingly. Kernel proofs
about writable output memory do not establish the Rust wrapper's reference
preconditions. No Miri result is claimed here.

### 2. Aliasing, access and callbacks

The header does not state the non-overlap/exclusive-access conditions
needed when the wrappers simultaneously create shared input and mutable
output references. It should define:

- non-overlapping writable regions, including outstanding stream places;
- input immutability and when output access/reuse becomes permitted;
- serialized calls on a stream handle (as already stated for a hasher);
- no re-entry into the same stream from its callback, while the outer Rust
  call still holds `&mut B3Stream`;
- callbacks return normally: no C++ exceptions or longjmp through Rust
  frames; the callback function must be non-null.

Please preserve the intended place-reuse behavior while stating precisely
when ownership/access returns; I am not proposing a new buffering API.

### 3. Heap alignment and fail-stop wording

`b3_hasher` needs 64-byte alignment. The header mentions allocated storage
but should explain the requirement for heap allocation too; ordinary
`malloc` is not a promise of that over-alignment.

The opening promise that *every* contract-breaking call stops with a
message is too broad for raw pointers, lifetimes and aliasing. Distinguish
checked scalar/alignment errors from the memory obligations that the C
caller must uphold. Invalid pointers cannot generally be validated by this
boundary code.

Inspected sources: John's61b469ce / #152's3d67a0d, and Devon's
`api/two-kinds`80f845c. The output-reference and missing-contract issues
are present across both API forms. No new performance experiments are
needed to make this safety/compatibility decision.

— Sam Shackleton
