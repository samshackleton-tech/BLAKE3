# Const-function header controls, native EPYC

Reviewed source: `d14548a44b7c1da7e6c985be9c445dda186dc553`, PR139. Its selector and test-control files are byte-identical at Devon's later `8bd5af644e6b50e1999127d3a2742adb77a8e3e2` tip. `reach-reviewed.py` is the unchanged selector; `source-restoration.diff` is empty. Native runs finished2026-10-24 00:25 UTC, serialized on the EPYC9255.

The ordinary const-function fix is independently confirmed. Two equivalent Rust declarations still narrow unsafely:

```rust
const extern "C" fn base() -> u16 {
    3
}
```

```rust
const
fn base() -> u16 {
    3
}
```

As in the earlier fixture, `const B: u16 = base()` feeds a full-width test, while a runtime `base() as u8` feeds another test. Changing only the return literal3 to259 leaves the low byte unchanged. The full-width test must fail.

| Declaration | Selected check | Full suite |
|---|---|---|
| `const fn` | selects both; exit100, intended assertion | exit100, intended assertion |
| `const extern "C" fn` | selects only low byte; exit0, writes green map | exit100:259 instead of3 |
| split-line `const` / `fn` | selects only low byte; exit0, writes green map | exit100:259 instead of3 |

These are actual Rust/LLVM-coverage/nextest runs, not just parser-unit fixtures. `selected.log` and `full.log` show the test names and assertions. No timeout is counted as detection. Nine existing selector controls also pass.

The parser blanks string literals before its const-function regex looks for a quoted ABI string; it also detects qualifiers on one line only. These counterexamples establish two holes, not completeness of a proposed parser repair. Unknown syntax should select conservatively.

## Reproduce

Requires the existing `replace` exact-count utility, cargo-nextest, LLVM coverage tools and the selector's normal dependencies. On a coordinated native host:

```sh
python3 reproduce-reach-const-forms.py reach-reviewed.py /absolute/new-report/plain plain
python3 reproduce-reach-const-forms.py reach-reviewed.py /absolute/new-report/extern-c extern-c
python3 reproduce-reach-const-forms.py reach-reviewed.py /absolute/new-report/split split
```

The fixture tracks Cargo.lock before making the baseline map. Empty serde/zeroize features match the updated selector's suite options; no fixture code is conditional on them. The first launch omitted those feature declarations and failed before coverage. Its Cargo diagnostic is retained in `initial-suite-failure.log`; it is not a false-green observation. The corrected run's map, dry-run, selected/full logs, diff, outcome, manifest, lockfile and mutated source are included per form.
