# Direct performance caller after work/idling — October 24, 22:34 UTC

Short screen while user present; no >=10-minute job. Library resident-D 6cad867;
benchmark b7ebfa280f22f23ea182b3ba9eecbb4481a8e9d5, feature diag-direct-cold.
Same library source with BLAKE3_DIAGNOSTIC_GPR unset (SIMD) or1 (GPR).

Same dependent producer/hash/consumer as warm direct model: aligned final input,
kept final heap output, read every output word in place, checksum feeds next
input. Allocate/select before gaps. Existing clocks::measure_after_gaps_prepared
runs ENTIRE producer/hash/consumer in its first timed closure, second closure
empty, second timing discarded. This keeps stores adjacent to hashing (no
counter reads between them). Gap, clocks/counter overhead outside interval.
Use existing 1 ms idle or other-code+128MiB Busy gap. One untimed call precedes
measured ones. Tests check addresses, generated final bytes and final digest
against upstream BLAKE3, plus warm-up/call count. 50/50 native bench tests on
each backend; fill version's targeted cold test passes.

Four fresh link layouts per side; A/A four pairs then comparison eight pairs;
CPUs0,2. A/A no slower label, but cold means +1–4% remain (not equivalence).
All numbers below are cost ratios, from existing regress/compare.

| state | size | SIMD ns/B | GPR ns/B | result |
|---|---|---:|---:|---|
| after work | 64 B |3.306|4.950|+49.7% slower, 0/8 faster|
| after work |256 B|1.736|1.763|+1.6% level, 4/8 faster|
| after work |1 KiB|1.360|1.033|-24.1% faster, 8/8|
| after idle |64 B|2.724|1.283|-52.9% faster, 8/8|
| after idle |256 B|1.616|0.918|-43.2% faster, 8/8|
| after idle |1 KiB|1.352|0.820|-39.4% faster, 8/8|
| warm |64 B|1.382|0.895|-35.3% faster, 8/8|
| warm |256 B|1.263|0.825|-34.7% faster, 8/8|
| warm |1 KiB|1.246|0.798|-35.9% faster, 8/8|

64B after-work total: ~212 ->317 ns/message. After-idle ~174 ->82 ns.
This shows performance-oriented API != warm caller, and idle != cache/code
displacement by other work. Do not globally route _with to GPR merely by API.
Instruction footprint is a plausible contributor to the after-work64 cost,
not proved as the cause by this screen.

Core counters retained in samples. Existing map rendered for the first old/new
pair. Its cycles/time ratios read low for short cells: clocks/linux_counts.rs
explicitly counts user cycles but running time includes kernel time, so these
ratios across counter-read syscalls are not direct frequency measurements.
No wall times scaled by cycles; no frequency explanation claimed.

Server /root/results/gpr-chunk-root/direct-cold (tests, build, AA, comparison,
raw samples, binary manifests, layout orders, representative maps).
Longer-layout validation and producer sensitivity deferred until user AFK.
Next candidate worth exploring: compact rolled rounds with improved D-row
residency, to test footprint vs execution cost without CPU-specific dispatch.
