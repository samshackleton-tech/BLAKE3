# Independent public-source review — EPYC 9255, 2026-10-23

Two small reviews, run serially on a native AMD EPYC 9255 (Linux x86-64, AVX-512). No optimization candidate or private performance results are included. Tool versions are in `tool-versions.txt`.

## Test selection: two false-green controls

Reviewed `tools/tests/reach.py` unchanged at Devon's `1232ed8c7d1bc160d61a6feb2c1031776a3871d8`. It is identical to the file in BLAKE3 PR #139 at `188ca5f52b55b4baa34b04e2515fd4f7bbc6f6e8`.

These are actual Rust builds and LLVM coverage maps, not invented coverage dictionaries. In each fixture the baseline passes and is mapped; one constant changes; the selected check succeeds; the full suite fails.

| Fixture | Selected check | Full suite |
|---|---|---|
| Constant-only module | `not compiled here: src/constants.rs`, 0 of 1 tests, exit 0 | `answer_is_seven` fails, exit 100 |
| Transitive constant | selects only `direct_low_byte`, which passes, exit 0 | `indirect_full_width` fails, exit 100 |

### Constant-only module

`src/constants.rs` contains `pub const ANSWER: u32 = 7;`. The library returns `constants::ANSWER`; its test expects 7. Change the constant to 9.

No instrumented line in this file does **not** establish that it is uncompiled. It is compiled constant data used by the test. The early `not compiled here` decision skips the affected test.

### Transitive constant

```rust
const A: u16 = 3;
const B: u16 = A;
pub fn direct() -> u8 {
    A as u8
}
pub fn indirect() -> u16 {
    B
}
#[test]
fn direct_low_byte() {
    assert_eq!(direct(), 3);
}
#[test]
fn indirect_full_width() {
    assert_eq!(indirect(), 3);
}
```

Change A from 3 to 259. The selector finds the executed line naming A and runs only the direct test, which still passes after truncation. The test using B is affected transitively, but is not selected and fails in the full suite. The selected check also writes a new successful map.

Conservative interim behavior: do not equate missing coverage with uncompiled source; do not narrow changes to constants/types/imports solely by direct textual uses. Run all tests where dependencies or compilation status are not established. This does not require replacing the useful line-selection path inside known functions.

### Reproduce

Prerequisites: Python 3, Rust, cargo-nextest, matching LLVM coverage tools (`rustup component add llvm-tools`), Git, and a C toolchain. The included exact-count `replace` utility is used only to edit the fixtures. From this directory:

```sh
export PATH="$PWD/reach:$PATH"
python3 reach/reproduce-reach.py "$PWD/reach/reach-reviewed.py" /absolute/path/to/new-results
```

The result directory must be fresh. The script generates and tracks Cargo.lock before mapping; otherwise an untracked lock forces all tests and masks the behavior. An initial local trial had that confound and was discarded as evidence for these cases. The recorded logs here are from the corrected run. Neither fixture changes the reviewed selector.

## PR #137: independent native instruction/memory model check

Source: `68faedf7c923a56863ce8ee55b34f2d0f922ac5e`, unchanged. From that checkout:

```sh
python3 tools/verify/cross_check_x86.py
```

Result, exit 0:

```
312 vector instruction forms (81 memory forms), 200 random states each, 24 alignment fault controls: all agree
```

No AVX-512 skips. `model/model.log` is the full output, and the empty tracked-source diff is retained. The expected alignment child faults are controls, not timeouts or failed proof jobs. This is randomized hardware/model evidence on another native machine; **not** a full-kernel or symbolic proof, nor validation of general-register instructions, branches, or prefetch effects. Those remain outside this cross-check's stated scope.
