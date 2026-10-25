# Current-source EPYC result — October 24, 2026

## Main finding: native linkage needed repair

The first mixed benchmark linked both crates to official's inherited x86
assembly symbols. Disassembly showed official's wide AVX-512 remainder
loads in servil's path, instead of its narrowed loads. Source provenance
and a passing A/A did not detect this. Those first maps and the interrupted
comparison are retained as provisional.

- Issue: https://github.com/johnservil/BLAKE3/issues/151
- Fix: https://github.com/johnservil/BLAKE3/pull/152
- Review head3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4, on John's main:
  107/107 native tests. The no-isolation control fails the actual binding
  assertion. On the new API stack, ce93dbf passes106default,85pure,
  33no-std and48benchmark tests.
- Both native symbol sets are present in the corrected executable. Its
  original function has upstream's ZMM/YMM loads; its private servil
  function has servil's XMM loads. Assembly-only `.text` is byte-identical
  under renaming for all three inherited x86 backends. Proof sources are
  unchanged. Windows/macOS validation remains pending.

## Updated baseline

Three corrected 96-round full-size maps, independent link layouts,
finished quietly. Sources and the initial provenance-smoke failure are
in INTEGRATION.md. This is an unreleased integration, not released0.17
or an overview update. Official is1.8.7; performance inputs are aligned;
clocks d6671f5 and the mean/pair/statistical rules remain explicitly pinned.

Official's repeatable advantages in these maps are small idle calls,
roughly2% on warm1KiB, and tiny streamed batches compared with its
synchronous batch call. Servil's own synchronous batch is much closer.
The512KiB threading cutoff also costs more than serial after idle in these
runs. Larger batches, collections and streams show substantial servil
advantages;16 messages of4KiB cost servil st0.660–0.679µs/message versus
official1.629–1.638µs. See OPPORTUNITIES.md for exact scope and cautions.

## SIMD draft on the corrected sources

Baseline ce93dbf versus candidate0584cbe29f9992c1ebea443be35bfa4efed2417b
(#141's SIMD chunk-root/frame separation plus symbol isolation), benchmark
0d38c5f, clocks d6671f5. Candidate110/110 native tests and48/48bench tests.
Four layouts per side, eight comparison pairs, following a four-pair A/A.
54 cells judged together by existing regress/compare. No GPR selector.

Selected single-threaded results (ns/B):

| Cell | Baseline | Candidate | Existing compare verdict |
|---|---:|---:|---|
|64B after idle|3.499|3.025|−13.6%, faster,8/8|
|256B after idle|1.850|1.709|−7.6%, faster,8/8|
|1KiB after idle|1.411|1.351|−4.2%, faster,8/8|
|1KiB after other work|1.753|1.676|−4.4%, faster,7/8|
|warm lent64B|1.088|1.014|−6.8%, faster,8/8|
|warm lent1KiB|1.265|1.213|−4.2%, faster,8/8|

**Hold:** shared MT16-message continuous batches9.515→11.016ns/message,
**+15.8%, slower**,7/8 pairs slower. MT continuous1KiB has positive means
+15.4% solo and+20.2% shared, labelled level. Keep them visible.

**Control limitation:** A/A had no slower labels, but its MT continuous
1KiB solo mean was+31.2% (all4pairs slower), and its solo stream-batch
mean+18.4%. Thus “A/A passed” is only the tool's exit0, not evidence of
stable streams. The candidate's stream loss needs wider independent-layout
confirmation and diagnosis; it blocks adoption in the meantime. Four
layouts reused across eight pairs is a bounded screen, not sixteen
independent layouts or a broad release gate.

No runtime policy or kernel was promoted. Corrected regress returned1;
the orchestration completed normally. All logs, samples, layout orders,
positive means and the earlier interrupted attempt remain available.

## Next

1. John/Devon review symbol-isolation PR152; check native Windows/macOS.
2. Audit historical mixed-crate binaries before changing claims about them.
   Uniquely named kernels and standalone CLI binaries need separate checks.
3. During AFK, confirm the SIMD stream finding with a larger independent
   layout bank and isolate code-layout versus scheduling effects.
4. Investigate official's full-SIMD-group subtree leaves versus servil's
   8KiB minimum pool pieces near the split boundary. This is a motivated
   hypothesis, not a measured fix; preserve AVX2/NEON and large-core controls.

EPYC native work ended23:31:10UTC; no benchmark or build left running.
