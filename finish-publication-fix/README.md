# Finish output publication: focused fix and controls

`fix.patch` applies to PR139 head `d14548a44b7c1da7e6c985be9c445dda186dc553`. Its two source files are unchanged at Devon's later `8bd5af644e6b50e1999127d3a2742adb77a8e3e2`; `git apply --check` also succeeds there.

The production change is one load ordering: `finished_count()` uses Acquire, so `wait()`'s polling return acquires worker output writes. The accompanying Loom models write one payload per worker, then check every payload immediately after `wait`, before any join or separate completion-count read. Those later operations could otherwise mask a missing acquire in `wait`.

The existing three wake/count scenarios gain payload assertions. A fourth scenario continues polling. All use the library's actual `src/finish.rs` through the existing path inclusion; the test command now uses nextest.

## Native EPYC controls

Completed 2026-10-24 00:46:56 UTC, serialized, Loom 0.7.2:

| Source under the same four enhanced models | Result |
|---|---|
| Original Relaxed count load | 0 passed, 4 assertion failures, exit 100 |
| Acquire count load | 4 passed, exit 0 |
| Fixed source, native serde/zeroize release suite | 104 passed |
| Fixed source, native serde/zeroize debug suite | 105 passed |

The negative control fails with `wait returned without publishing worker output 0`, observing 0 instead of 1. No timeout is counted as detection. Full logs, exact patch, exits and paired SHA-256/BLAKE3 log manifests are included.

These are correctness controls for the finish component, not a whole-pool proof or a performance promotion. Cross-platform and performance integration checks remain the maintainer's gate. No native wrong hash is claimed from the original source.

## Apply and run

```sh
git apply /path/to/fix.patch
RUSTFLAGS='--cfg loom' cargo nextest run --release --test loom_finish --test-threads 1 --no-fail-fast
cargo nextest run --release --lib --tests --features serde,zeroize
cargo nextest run --lib --tests --features serde,zeroize
```

For the negative control, keep the new tests and restore only the completion-count load to Relaxed. Run serially on a coordinated native host. `run-finish-publication-fix.sh` records the exact original/fixed order used here; its server paths are setup details rather than a portable installer.
