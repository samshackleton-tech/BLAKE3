# bench-hashes provenance: a clocks patch reads "clean" (October 24, 15:45 UTC)

build.rs (identical on v7 ae63011 and main f4f347c):
- `only_servil_patched` forgives any Cargo.lock line starting `source = "git+https://github.com/devonjonte/BLAKE3`, which is the servil repository's URL. clocks is pinned from the same repository, so a `--config` patch of clocks (the instrument) passes, and the run says "git clean status: clean".
- Nothing emits clocks provenance; only the lock fingerprint changes. b3sum samples files carry no source lines at all, though clocks times them.

Published runs audited (johnservil and devonjonte main):
- 08170e2 = ae63011's committed lock.
- 9dd5b3a = f4f347c/4b65e6e lock with servil's source dropped (build-against).
- 6648cbe = 6cefdd6 lock with servil's source dropped; its servil line says dirty-50249e3.
- 76467d9 = ae63011 with clocks' source dropped (my run, disclosed).
No published run carries an unrecorded clocks change.

Proposed fix (bench-hashes; Devon's code):
1. Compare locks package by package; only blake3-servil's source line may differ.
2. Emit a clocks provenance line (pinned commit, or a named local checkout with its git state via e.g. BENCH_CLOCKS_CHECKOUT); a patched clocks with no named checkout makes the run dirty.
3. Put the source lines (at least clocks) in b3sum samples headers too.
Optional: a header line that says when any provenance line is dirty (the M4 run's top-level "clean" sits beside a dirty servil).
