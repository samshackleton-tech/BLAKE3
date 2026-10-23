# Finish visibility and selector followup at 8023f70

Reviewed source: `8023f707ced1fa3b91399ef7388f086fa1b7d526` (BLAKE3 #139). Native EPYC work ran serially after the optimization measurements. The tracked review checkout stayed unchanged; `logs/source-restoration.diff` is empty.

## Finish polling fast path misses an acquire

`Finish::wait` can return from its first loop after `finished_count()` observes the completed count. That method uses a Relaxed load. This return bypasses the Acquire/AcqRel operations on the sleeping path.

The fixture includes an exact copy of the reviewed `src/finish.rs`. Its paired copy changes just the load in `finished_count()` from Relaxed to Acquire. Both use Loom 0.7.2's primitives through the same `finish_sync` interface as the public tests. The manifest and lockfile are included.

Each worker writes its own atomic payload with Relaxed ordering, then calls `finished(1)`. The caller calls `wait`, then checks those payloads **before joining the workers**. A join before the assertion would independently acquire the output writes and hide the missing acquire in `wait`.

| Control | Result |
|---|---|
| Unchanged public wake/count models | 3 passed, exit 0 |
| Added one-worker output model, original finish source | assertion failure: output 0, expected 1 |
| Added two-worker output model, original finish source | assertion failure: output 0, expected 1 |
| Same output models with only the count load changed to Acquire | 2 passed, exit 0 |

The original output-model command exits 101 with two assertion failures. No timeout was counted as detection. Logs are in `logs/visibility-{original,acquire}.log`; the one-line change is in `logs/acquire-control.diff`.

Reproduce from `fixture/`:

```sh
RUSTFLAGS='--cfg loom' cargo test --release --test visibility original_ -- --test-threads=1 --nocapture
# Expected: two assertion failures, exit 101.
RUSTFLAGS='--cfg loom' cargo test --release --test visibility acquire_ -- --test-threads=1 --nocapture
# Expected: two passes, exit 0.
```

These models cover output visibility with one or two completing workers. They do not establish the whole pool's lifetime, ownership, overflow, or scheduling contracts. No native wrong hash was observed: the unchanged native release suite with serde/zeroize passes 104 tests. That pass coexists with the memory-model counterexample.

## Selector fixes and remaining const-function case

The updated helper suites pass: ten mutation-helper controls and eight selector controls.

Replaying the two original native Rust/LLVM-coverage fixtures against this source now selects the failing consumer: each selected check and full suite exits 100 with the intended assertion. The constant-only and transitive-constant fixes are independently confirmed (`reach-fixed/`).

The const-function fixture still gives a false green on this updated source (`reach-const-fn/`): only the truncating runtime consumer is selected and passes, exit 0; the full suite catches the compile-time consumer, exit 100. Its fixture and reproduction command are in the main README's const-function section. The updated selector is available at the reviewed Git commit above.
