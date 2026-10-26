# The wide AVX-512 kernel on Zen 4 and Intel Ice Lake (#125)

Bare-metal Cherry Servers machines, hourly, set up by `newhost-setup.sh` like the EPYC 9255 (Rust 1.99.1, nextest 0.9.149, cargo-mutants 27.1.0, z3 4.13.3, performance governor); `newhost-release.sh` as run.

- `zen4/`: AMD EPYC 9124 (16 cores, 32 threads), Chicago.
- `icelake/`: 2× Intel Xeon Gold 6330 (56 cores, 112 threads, 2 NUMA nodes), Chicago.

On each: every suite at 8c34ead4 and `cross_check_x86.py` (332 forms, all agree); then `bench-hashes check --cells all --pairs 12` of 8c34ead4 against ffd1a8e (the same with the wide dispatch off: `wide*`). On Zen 4, also the release check against 07540667 (`release*`), and the CLI (`cli-*-r*.out`: old 07540667, nowide ffd1a8e, new 8c34ead4, 4 layouts each, 16 rounds; judged against old). The CLI result directories are not copied: the job's copy step took another machine's committed file, so the reports are the `.out` logs. Dual manifests cover this directory except themselves.
