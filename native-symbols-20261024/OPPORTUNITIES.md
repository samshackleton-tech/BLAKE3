# What to investigate after native isolation

These observations use the corrected `ce93dbf` integration, bench `0d38c5f`,
clocks `d6671f5`: three independently linked 96-round maps. They locate
suspects; the maps do not supply paired cross-algorithm significance tests.
All three runs were quiet. Do not use the earlier colliding maps for claims.

## Official's remaining advantages

- **Idle 64 B:** official 3.382–3.394 ns/B, servil st 3.543–3.600:
  about 4–6% more time. Idle128 B also costs servil more in all three maps.
- **Warm 1 KiB:** official about1.24 ns/B, servil st about1.26–1.27:
  approximately2% more time, present with one or two callers.
- **16-message streaming batches, two callers:** official's synchronous
  batch about7.57–7.58 ns/message, servil's stream9.35–9.94; servil's
  synchronous batch is about7.60. The API/call-path distinction matters:
  these figures do not establish a slower compression kernel.
- **512 KiB after idle:** servil mt0.122–0.152 ns/B versus servil st
  0.110–0.112, roughly9–36% more time, although still much faster than
  official's Rayon call. The fixed512 KiB split cutoff is relevant. The
  public claim “never slower” is stronger than these measurements support.
- Official's solo lent64 B varies strongly across the maps (about1.03
  versus1.49–1.50 ns/B). Keep the known placement sensitivity in view.

## Existing SIMD draft, not a GPR default

The #141 stack-free SIMD chunk-root and frame separation are being tested
on the isolated sources. They directly target the small-call and1KiB
costs. GPR's after-other-work regressions remain a separate blocker.

## A concrete technique in official worth testing

Official's `compress_subtree_wide` stops at `simd_degree * CHUNK_LEN`;
on AVX-512 its whole groups are16 KiB. Servil's pool `next_piece_len`
can cut to8 KiB (the minimum chosen for the AArch64 hybrid kernels), so
near its split threshold it can issue half-width x86 work and more jobs.

This is a hypothesis and an experiment plan, not a demonstrated cause or
an adopted policy. First count the actual piece shapes, then compare
keeping full SIMD groups at the split boundary. Preserve the AVX2/NEON
behavior as controls; test idle, after-work and sustained loads and large
core counts. A minimum based on useful kernel work could be broadly
motivated; an EPYC model-specific threshold is not justified. Raising the
whole library's cutoff is particularly unsafe: the existing lanes.rs
comment records why512 KiB was chosen for the M4, despite a VM cost.

For tiny batches, investigate the stream's queue/handler work separately
from its kernels. The existing synchronous batch API already avoids much
of that cost. Do not add another scheduling mode without isolating which
work it would remove and testing larger streams for losses.

## Strong positive control in the new workload

For16 messages of4 KiB after other work, official costs1.629–1.638 µs per
message; servil st0.660–0.679 µs. Devon's new batch case exposes a real
path that the older instrument omitted. Preserve it in the next release;
do not replace released0.17 data with this different workload silently.
