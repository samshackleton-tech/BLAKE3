# #192 on the EPYC 9255, and #189/#193 mutation runs (October 27)

- `pr192-check/`: `check --against fb2cbda --pairs 8` at 2eaad1c (#192), check's own selection (160 cells), bench #87 7f275a1. Both stages: no cell slower.
- `pr192-check-failed-profdata/`: the first attempt; check's coverage step took Ubuntu's llvm-profdata (LLVM 21) from PATH, which can't read Rust 1.99's profiles. Rerun with the toolchain's llvm-tools first on PATH.
- `pr192-third/`: `regress` over check's own 24+24 builds, mt, ManyMessages 2-48, 24 pairs. No cell slower; the cells are bistable (pair ratios ~0.7-1.2).
- `sam-wide-zen5-120e9fa-tests/`: #189 rebased on bc66561, suites (all status 0). `sam-wide-zen5-120e9fa-exit2/`: its mutation run, exit 2 on the stale Hasher time-out row (#193). `sam-wide-zen5-deb02ad/`: #189 on #193, exit 0.
