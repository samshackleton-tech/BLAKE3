# Independent public-source review — EPYC 9255, October 23–24, 2026

Independent reviews, run serially on a native AMD EPYC 9255 (Linux x86-64, AVX-512). No optimization candidate or private performance results are included. Tool versions are in `tool-versions.txt`.

## Latest followups, October 24

- [Const-function header forms](const-forms-d14548a/): the ordinary `const fn` fix passes the native control. External-ABI and split-line forms still select only the passing runtime test; full suites catch the compile-time consumer. Exact PR head and logs included.
- [Finish publication fix](finish-publication-fix/): a small applicable patch with payload-before-join assertions. Four enhanced Loom models fail with the original Relaxed load and pass with Acquire; native release104/debug105 tests pass on the fix. Performance and cross-platform promotion remain open.
- [Promoted x86 model check](promoted-model-2e892e1/): the unchanged checker at John's promoted tip agrees on all312 forms,81 memory forms and24 alignment-fault controls, with no AVX-512 skips. This is native instruction-model evidence, separately scoped from his symbolic proofs.

Earlier findings and their source-pinned outcomes remain below.

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

Conservative interim behavior: do not equate missing coverage with uncompiled source; do not narrow changes to constants/types/imports solely by direct textual uses. Run all tests where dependencies or compilation status are not established. Runtime coverage can inform selection for ordinary function bodies; these controls do not establish the completeness of a selector. The additional control below identifies a compile-time exception.

### Reproduce

Prerequisites: Python 3, Rust, cargo-nextest, matching LLVM coverage tools (`rustup component add llvm-tools`), Git, and a C toolchain. The included exact-count `replace` utility is used only to edit the fixtures. From this directory:

```sh
export PATH="$PWD/reach:$PATH"
python3 reach/reproduce-reach.py "$PWD/reach/reach-reviewed.py" /absolute/path/to/new-results
```

The result directory must be fresh. The script generates and tracks Cargo.lock before mapping; otherwise an untracked lock forces all tests and masks the behavior. An initial local trial had that confound and was discarded as evidence for these cases. The recorded logs here are from the corrected run. Neither fixture changes the reviewed selector.

## Additional control: a const function's compile-time consumer

The unchanged published selector at `1232ed8c7d1bc160d61a6feb2c1031776a3871d8` also misses a compile-time consumer of a changed function body:

```rust
#[inline(never)]
const fn base() -> u16 {
    3
}
const B: u16 = base();
pub fn direct() -> u8 { base() as u8 }
pub fn indirect() -> u16 { B }
```

Two tests expect 3 from `direct()` and `indirect()`. Change only the body of `base()` from 3 to 259. Actual runtime coverage selects `direct_low_byte` for the changed body line. It passes after truncation, and the selector exits 0 and writes a new map. The full suite fails `indirect_full_width` (259 versus 3), exit 100. Logs are in `reach/const-fn/`.

This fixture uses an instrumented function body. Its compile-time consumer leaves no runtime call edge in that coverage. A conservative selector should run all tests for changes to const functions unless it accounts for compile-time dependencies. Moving outside-function changes to all-tests selection does not cover this case by itself.

The initial third-case run uses `1232ed8`. A [followup on the updated #139 source, 8023f70](finish-8023f70/), independently confirms both earlier fixes and reproduces this const-function false green. It also supplies a separate Loom counterexample for output visibility in the new finish handshake, paired with an Acquire-load control.

```sh
export PATH="$PWD/reach:$PATH"
python3 reach/reproduce-reach-const-fn.py "$PWD/reach/reach-reviewed.py" /absolute/path/to/fresh-const-fn-results
```

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
- [`overread-cost-epyc-20261025/`](overread-cost-epyc-20261025/): #168, the over-read fix's AVX-512 cost on EPYC 9255. `check --cells all --pairs 12` found no cell slower in two runs. Raw samples are kept, with the failed and incomplete attempts.
- [`wakes-release-epyc-20261025/`](wakes-release-epyc-20261025/): #119 wake design on EPYC (no cell slower, pool cells faster) and the 0.8 release run (4 cells slower, unresolved; same-code control false "faster").
- [`smt-epyc-20261025/`](smt-epyc-20261025/): SMT explained on EPYC 9255. The held wide kernel gets x0.96-1.11 from a core's second thread; 0.8's kernels get x1.44-1.73. Capping at physical cores is a trade-off; mixed-speed threads are handled.
- [`wide-kernel-epyc-20261025/`](wide-kernel-epyc-20261025/): the 32-input AVX-512 kernel ported onto candidate/release-0.8 + FANOUT 8; a full EPYC comparison with charts, CLI, SMT, energy, an ablation and a pros and cons table.
