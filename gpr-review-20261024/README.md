# GPR kernel review submission — October 24

Review head **87d837a6461189348d2f2ab74bd5588a4b24a09e** on Sam's BLAKE3 fork,
`candidate/sam-gpr-chunk-root-review`.

This is the resident-D kernel measured at 6cad867, plus the Intel-testable
opt-in/tracing glue from 8e6f0a1. The review cleanup consolidates the generator
into one file, `tools/gen_x86_gpr_chunk_root.py`; generated assembly was checked
identical to 8e6f0a1 except its first provenance comment. Default builds keep
SIMD. GPR requires the build-time BLAKE3_DIAGNOSTIC_GPR variable to be present.

Native EPYC tests at the exact review head: default108/108, GPR109/109. Earlier
199680 ABI/output/canary checks for the same assembly are in ../afk-20261024/.
No formal proof or Intel performance claim. New routing glue has no separate
speed claim; performance below was measured at 6cad867.

Dependencies: #141 d3e3cbe, Devon's output-parameter API f503409 and the aligned
Stream ring from #144. The isolated kernel experiment is seen by comparing
f503409..review-head (that range includes the ring-alignment dependency).
No new public function or production CPU-selection policy is proposed.

## Full performance balance sheet: cost change against SIMD, EPYC

| caller/condition | 64 B | 256 B | 1 KiB |
|---|---|---|---|
| warm direct production, final heap output consumed in place | -36–38% | -36–37% | -36–37% |
| same caller after other work | +49.7% slower | +1.6%, level | -24.1% faster |
| same caller after idling | -52.9% faster | -43.2% faster | -39.4% faster |
| convenience hash after other work | +77.8% slower | +27.6% slower | -8.9% faster |

Warm and convenience figures: 16 layouts/side, 16 pairs, in ../afk-20261024/.
Cold direct caller: 4 layouts/side, 8 pairs, preliminary screen here. All
labelled wins/losses in that screen have 8/8 consistent pairs. 256B after work
is unresolved, not equivalent. A/A4 has no slower labels, with +1–4% cold means
retained. Larger-layout cold validation remains pending.

The cold caller keeps the warm model's producer and consumer. It uses clocks'
existing idle or other-code+128MiB gaps. Its producer/hash/consumer run together
in the first timed closure of measure_after_gaps_prepared; the second closure
is empty and its measurements discarded. No clock/counter reads intervene
between production and hashing; no manual timing loop or subtraction.
Allocation is outside the measured interval; the same input/output addresses
persist. The samples and reports label the experimental override of ST
OneMessage and IdleOneMessage. Standard defaults are untouched.

Cold bench source **b7ebfa280f22f23ea182b3ba9eecbb4481a8e9d5**, Sam branch
`experiment/sam-direct-cold`, feature `diag-direct-cold`. Native tests: 50/50
on SIMD and GPR, including addresses, byte generation, upstream digest
agreement and one warm-up plus two measured calls; fill sensitivity test passes.

Batches predominantly use unchanged wide kernels and remain level. Earlier
stream comparisons are mixed/level with positive means retained; the latest
resident-D improvement has no dedicated stream comparison. Performance-oriented
API does not mean warm caller. These results block an unconditional replacement
of either hash() or hash_with().

Hardware counters are retained. The map's short-cell cycles/time ratios are
not CPU-frequency proofs: linux_counts counts user cycles while its running
time includes kernel time (documented in clocks). No wall times were rescaled.
The instruction-footprint explanation for after-work64 is a hypothesis.
