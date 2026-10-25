# Simple C guards and recycled stream rooms — October 25, 2026

Release correctness work only. No performance experiments, public tags or
crate uploads. Final RC remains unselected.

## Simple C guards: implemented for review

PR159 proposed head: dc37f57ae09269979f55d432eb694eb1fe9f9d7f,
based on c75daebf383820e73bbe366d9e770d6168b236e6.

Following Zooko's direction, the C wrapper now performs straightforward
local checks before constructing Rust references or typed values:

- null `done` via a nullable Rust function-pointer representation;
- mode/key/stream/hasher range and stream/hasher alignment checks;
- lengths above `isize::MAX`, address-range wrap, batch stride and total
  overflow;
- immediate batch, hasher/mode/input/output overlap where both ranges are
  already available to the entry point.

It does not track outstanding stream ranges, validate arbitrary ownership
or lifetimes, add locks/registries, or zero output on each call. Empty
ranges and exactly adjacent ranges remain valid. Header text distinguishes
these guards from obligations the caller still owns.

Validation:

- All 16 malformed cases reach their intended diagnostic under pinned
  Miri nightly-2026-10-24, strict provenance, one CPU, with no Miri UB
  diagnostic. Each intentionally uses nextest exit100 for the caught panic.
- Removing overlap/alignment guards or making the null callback unchecked
  makes the corresponding Miri controls fail with UB and no guard message.
  These malformed controls ran only under Miri, never natively.
- Native exact-head C suite passes 7/7. Valid adjacent/empty cases pass
  natively and under Miri. The full official C vector binary also passes
  under strict-provenance Miri: 2/2, with the large case taking1165.9s.
  That validates those interpreted paths, not native assembly or all schedules.
- CI now runs the context/adjacency checks and invokes
  `tools/test_capi_guards.py`, which obtains cases from the compiled test
  inventory rather than duplicating or parsing a source list.

The first interpreted guard run did not forward the case selector into
Miri and therefore tested the harness guard instead of a C entry. Its logs
are retained as `guards-env-failure/`; no conclusion was drawn from it.
The first CI-record run also failed because test output prefixed the
inventory line. Emitting it on its own line fixed the record; that failure
is retained. Native production code was unchanged by that follow-up.

This remains a draft for contract/support review. Output initialization
under #155 is still not declared either reproduced or generally safe.

## Recycled stream rooms expose previous contents to the next fill

A separate safe-Rust probe used only dummy DeriveKey material. One caller
filled a 64-byte stream room, finished, and dropped its stream. A later,
sequential caller on the same thread inspected its room before overwriting
it, as the fill closure is able to do. It observed all 64 prior dummy bytes.

This reproduced on:

- main c75daeb, natively and under Miri;
- two-kinds API87ab0a2, natively and under Miri.

No Miri UB was reported. This is not memory corruption and not evidence
about concurrent access or other processes. It is a data-isolation/API
contract question: the ring storage is process-global and recycled, and
the current docs do not state that initial room contents are unspecified
or may contain earlier stream data.

Release decision needed before treating stream rooms as an isolation
boundary. Options have different costs: explicitly document unspecified
contents and require overwriting/zeroization by callers with secrecy needs;
clear used rooms at a defined lifecycle point; or another owner-approved
design. No fix is asserted here and no performance experiment was run.
Filed as BLAKE3 issue #161 for owner review.
