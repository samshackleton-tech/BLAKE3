# C ABI interpretation and portable padding tests — October 25, 2026

Release correctness/review work only. No performance experiments, public
release tags or crate uploads. The final RC remains unselected.

## Source snapshot

John main:c75daebf383820e73bbe366d9e770d6168b236e6.
API PR157:87ab0a283058f4508a41c9476585f69653a2a6cd.
Padding PR158:5f979fb2a049149759fcb43836becf820dc50707.
PR157's block.rs is unchanged from80f845c; the separately supplied Batch
size-overflow fix remains for review. PR156/157/158 are new review inputs,
not an automatically merged RC.

## C ABI under Miri

Installed pinned nightly-2026-10-24 plus Miri/rust-src on EPYC. Version:
rustc1.101.0-nightly / Miri0.1.0, commit48f4b05538b8eca412137042d9647a61e692c6b3.
Stable/default toolchain stayed unchanged. These are Rust callers of the
Rust-defined C ABI functions, interpreted with portable hashing; they do
not execute C compiler output or assembly and do not prove all schedules.

With `-Zmiri-num-cpus=1`, the corrected v2 harness gives the same results
on current main and the two-kinds API:

- Eight cases complete: initialized/uninitialized outputs for batch, XOF
  and stream; a one-byte streamed input with uninitialized ignored tail;
  and a valid non-null callback context without re-entry.
- Overlapping batch input/output is rejected by Stacked Borrows at the
  C wrapper's borrow construction.
- Re-entry into the same stream during its callback is rejected at
  `stream_mut`: it would invalidate a strongly protected mutable borrow.
- An explicit uninitialized-byte read is rejected, checking that the
  initialization diagnostic is live.

**Initialization remains a contract question.** These write-only paths
completed under Miri; no initialization failure was reproduced. That is
not a proof of every case, or a resolution of the documented initialized-
value precondition of `from_raw_parts_mut`. No blanket zeroing or ABI
redesign was added on that basis.

**Invalid first fixture retained:** v1's re-entry case failed in its own
context handling before it attempted re-entry. A later direct Rust-owner
write invalidated the pointer already exposed to C. V2 keeps the context
in a Box and accesses it through its original raw pointer, and adds the
passing non-reentrant context control. Only v2 supports the re-entry finding.

The default model is experimental Stacked Borrows. The existing context
pointer/integer conversion also warns that exposed provenance can hide
bugs. Diagnostics and that warning are retained; controls were never run
as native undefined-behavior programs.

## C boundary proposal

Branch candidate/sam-capi-memory-contracts, review head
2eaa2307cb9197438acd022bbfd96834656b4bf7 (on c75daeb).

- State disjoint writable ranges, exclusive handle access, callback
  non-re-entry/normal return and place-reuse rules, over-aligned heap storage,
  and the limits of diagnostics for raw-memory misuse.
- Replace the unqualified fork-recovery and “never slower” promises with
  explicit conservative support boundaries. This needs owner review; no
  native fork failure is claimed to have been reproduced.
- Keep ctx as a pointer, removing an unnecessary integer round trip. This
  enables strict-provenance checking; the old cast's rejection in strict
  mode is not itself a claim of Rust UB under exposed-provenance semantics.
- Preserve a valid callback-context test in native tests and CI's Miri job.
  No public declarations, kernel, scheduler or per-call output-zeroing change.
  Output initialization remains a separate #155 item.

Checks: the intermediate production-code head8faf342 passes all11
interpreter cases with `-Zmiri-strict-provenance` (eight expected completions,
three intentional diagnostics). Exact final head2eaa230 passes5/5 native
C API tests, including installed C11/C++11 static/shared consumers, and
its permanent strict-provenance Miri test. Controlb7f4bee85f12cbaa193585d8dd8a860a4fac80b6
restores the integer conversion; that permanent test fails with the
expected unsupported integer-to-pointer diagnostic (nextest exit100).

## PR158 test blind spot, and a portable control

John's unchanged PR158 passes107 native tests on EPYC. But the planted
controlc53fabd (restoring the old runtime padding behavior) also passes
its digest-only test. The x86 partial-message paths in many.rs truncate
to the message bytes before hashing, so stale padding does not change
these digests. This does not refute the Arm bug; it limits this test's
ability to guard the wrapper contract on x86.

Test-only improvement:c49d3353773d95fa3ab9e186eb74e8ffaaaa5091,
review/sam-stream-padding-contract. It inspects the ring through its owner's
original pointer after finish while the stream still owns the room:
message bytes are unchanged and padding is zero. It adds64B as a no-padding
control and retains digest comparisons. No production code changes.

- 107/107 native and106/106 pure tests pass.
- The changed test passes under Miri (one CPU, pure, intentional process-
  lifetime pool leaks ignored as in the project's Miri profile).
- Controlf7c7d78993d886ea037c13bded071b102fbdd998 removes the zeroing;
  the improved release-mode test fails at “0-byte message retained padding”.
- The first surviving control and blocked initial review script are kept.

This is correctness/test review, not performance acceptance. PR158 still
needs the already-noted mains-powered Mac confirmation before release.
All source pins, scripts, failures and model flags are retained.
Native/interpreter jobs finished03:53:33UTC; server idle.
