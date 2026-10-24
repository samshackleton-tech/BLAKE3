# AFK progress — October 24, 21:35 UTC

User authorized long jobs, briefly checked in, then explicitly resumed them.
Native EPYC work remains serialized by /root/bench-native-afk.lock.

## Controls and corrections (all attempts retained)

1. /root/results/afk-20261024-direct-flow:
   - Ordinary SIMD A/A: 16 layouts per side, 16 pairs, serial/batch and stream
     families, no slower cells.
   - Invalid positive control: driver called build_group('plant') without
     plant=True. Samples had no plant marker, so this tested nothing.
   - Three repeated core-axis runs completed, each detecting the six known
     sensitive cells. These runs are independent of the failed control setup.
2. /root/results/afk-20261024-direct-flow-repair:
   - Feature enabled and runtime header checked. Target solo64 detected +16.4%,
     but two unintended batch16 cells also slower (~6%). Compiling the plant
     changed shared helper code/setup; this was not an isolated one-cell plant.
   - Dependent performance comparisons correctly blocked.
3. /root/results/afk-20261024-runtime-control (bench 84248f3):
   - Plant-capable code on BOTH sides, runtime activation 0/1 (equal length).
   - A/A inactive: no slower cells in either family.
   - Positive control: ONLY intended solo64 cell slower, +16.2%, 16/16 pairs.
   - Runtime headers verify old inactive / new active.
   - Ordinary implementation comparisons omit the plant feature entirely.

## Confirmed results (16 layouts per side, 16 pairs)

Library 0627c0c: Devon output API + unrolled GPR opt-in + aligned Stream ring.
Bench 84248f3 direct-flow model (final aligned input, in-place heap output use).
Same original source pins as focused experiments; no production dispatch change.

Generated-word producer:
- GPR dependent singles 64B -22.8%, 256B -22.2%, 1KiB -23.2%, all16 faster.
- Batch16/64/256 level.
- Stream all level, but positive means remain: solo64 +6.9%, solo1KiB +14.5%,
  shared64 +5.6%, shared1KiB +5.0%. No stream win/equivalence claim.
Direct byte fill:
- GPR dependent singles -20.8%, -23.4%, -23.9%; all16 faster.
- Batches level; streams mixed/level (shared1KiB +5.6%).
Independent-word producer (bench e24c2df), /root/results/afk-20261024-dependency-final:
- GPR singles -23.3%, -23.5%, -23.2%, all16 faster; batches level.
- Removing cross-message dependency did NOT explain the 64B sign flip.
- Producer/consumer differences versus memcpy-in still need isolation.

## Assembly follow-ups

/root/results/afk-20261024-output-stores-final (ff46a606): complete.
Two 16-byte output stores instead of eight 4-byte stores: words producer small
positive means (-1.0%, -1.7%, -0.1%), all level. ABI 199680 comparisons and
108/108 library, 49/49 benchmark tests pass. Fill result available, not yet read.
Adds SSE4.1 and instructions for modest benefit; no adoption rationale yet.

/root/results/afk-20261024-resident-d (6cad867): RUNNING.
Keeps two D-row words resident across rounds, reorders independent Gs; halves
GP/XMM transfers from16 to8 per round, same SSE2 contract, 2996 bytes vs3232.
Native ABI, library and bench tests passed before timing. Builds words then fill,
16 layouts each, compares with old GPR. Both controls already passed.

/root/results/afk-20261024-cross-x86 (7092ac5): queued after resident.
GPR opt-in on BOTH SSE4.1/AVX2 and AVX-512 routes (so the i7 can actually test it),
records actual GPR entry in test trace. Tests only; default builds unchanged.
Old experimental trace recorded AVX512 even when it called GPR; perf profiles,
not that trace, were used for attribution. No speed results for cross-x86 glue yet.

/root/results/afk-20261024-simd-cleanup (2c48fa4): queued last, ~5 min.
Diagnostic: vzeroupper at SIMD chunk-root return, checking whether vector-state
cleanup before the in-place consumer accounts for the SIMD fixed cost. One
word-producer comparison, 16 layouts; no change to existing experiment binaries.

Original queue scripts kept on server; v2 helper adds first-layout header
verification. Current PIDs (as scheduled): resident 2761211, cross-x86 2763031,
SIMD cleanup 2777337. Check actual processes before new native work.
