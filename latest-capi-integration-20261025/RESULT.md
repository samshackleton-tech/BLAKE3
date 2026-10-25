# Latest GitHub updates and integrated release review — October 25, 2026

## New upstream work reviewed

John main is `7213223d9449040e8701c48ef3b777e89539d4a4` (announcement docs).
PR157 advanced to `e3013b149bf86900259f96d70e54bbdab420dca7`, adding
stream-padding zeroing, guard-page tests, docs and API work. PR158 remains
its padding fix. New issues #160 (Win32) and #162 (Fil-C) explicitly stay
outside 0.8 unless Zooko changes scope; no expansion was undertaken.
#163 was filed for the announcement/CHANGELOG claim that every assembly
kernel is proved, which conflicts with the quality manual's “proved in
part” wording and its separate Rust-intrinsics/test scope. This is a
release-documentation consistency finding, not a claim that any proof is
invalid.

## C guards on the newest API

The older two-kinds integration was rebased onto `e3013b1`. Its C tests
initially exposed three integration details, all retained as failures:
the new guard-page callback needed `Some(callback)`, stream rounded-size
validation had to precede overlap checking, and Miri returns status1 for
some aborting extern C calls rather than nextest's100. The test driver now
accepts either status only alongside the exact guard diagnostic and no
Miri UB diagnostic.

Latest C review head before the final integration additions:
`07c245e712297d6eb6c39ebddffc3d20470eabc1`.
- **8/8 native C API tests**, including guard pages.
- **19 interpreted C guard cases**, including alignment and rounded-range
  overflow, all reach intended diagnostics without Miri UB.
- Full strict-provenance C vector run **2/2 pass**, including the large
  case at1160.117s. Its exact C API source is unchanged in the integrated
  review below.
- The main C guard driver was also updated to accept the interpreter's
  abort status, with its 16 cases passing.

## Combined local release-review integration

`integration/sam-release-candidate-review`, exact head
`96f017bc190e867c22d176a330da644bdf32ce3f`, contains:
- PR157/e3013b1 two-kinds API and padding fix;
- simple C guards and pointer-provenance test;
- Batch block-count overflow fix;
- native x86 symbol isolation;
- no SIMD/GPR/full-group performance experiment or new dispatch policy.

Native EPYC results:

| Check | Result |
|---|---|
| Default library tests | **108/108 pass** |
| Pure library tests | **106/106 pass** |
| C API tests | **8/8 pass** |
| `tools/check-builds.sh` | **PASS** |
| Doc tests | **9/9 pass** |
| Rustdoc `-D warnings` | **PASS** |

The C API source is byte-identical between `07c245e` and this integrated
head; only the Batch constructor, native FFI/build files and their tests
changed outside `capi/`. The full Miri vector result from `07c245e` can
therefore be mapped explicitly to this integration's C API once complete,
without pretending that the whole integration was interpreted.

No final RC has been selected or approved. These are review/integration
checks, not a release-check PASS. Actual Windows/macOS runs, proof/mutation
campaigns, C ABI output-initialization and stream-room contract decisions,
and release acceptance remain open.

Evidence directories: `final-native/` (latest C and full vectors),
`final-integration-native/` (combined native/build/doc suites), and
`failures-*` for the earlier integration/test-harness failures. Scripts and
bundles are retained locally and on the EPYC. No public tag or crate upload
occurred. All native/interpreter work is complete as of06:07:18UTC.
