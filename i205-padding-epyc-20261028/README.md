# BLAKE3 #205 on the EPYC 9255 (AVX-512, wide kernels on), at 0.8's version commit 83d59db

Both runs through pinned-run (inputs by hash, outputs' identities verified; manifest, logs per run).
- `runs/i205-hazard-x86-*`: hazard.sh. Every padding byte of every message 0xA5, every digest compared
  with the clean input's, st and mt, counts 1-16384, lengths 1-4000; clean digests also against official
  BLAKE3 1.8.7. Result: no digest changes; every clean digest equals official's.
- `runs/i205-padcheck-*` (FAILED only on my own expectation that base changes a digest; it does not on x86):
  the padding check in every build, base / checked (the debug_assert promoted to assert) / checked-or (an
  OR-fold, no early exit): out/speed.txt, user cycles per warm call pinned to CPU 2, 5 rounds rotating builds;
  out/correctness.txt: both checked builds stop on nonzero padding. (Its mt part failed: the probe lacked
  initialize_multithreaded.)
