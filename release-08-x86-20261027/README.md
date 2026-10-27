# 0.8's x86 scope on six machines (October 27, BLAKE3 #125, #194, #195)

Machines (bare metal; the five beside electric-rhino rented hourly from Cherry Servers, deleted after):
electric-rhino = EPYC 9255 (Zen 5, AVX-512, wide on); zen5-9700x = Ryzen 7 9700X (Zen 5 desktop, family 0x1A, wide on);
zen4-9254p = EPYC 9254 (Zen 4, AVX-512, wide off); icelake-6330-c = 2x Xeon Gold 6330 (Ice Lake, AVX-512, wide off);
zen3-7443p = EPYC 7443P (Zen 3, AVX2); broadwell-1650v4 = Xeon E5-1650 v4 (Broadwell, AVX2).

Per machine:
- `r08/tests/` (`rel-2907ea5/tests/` on the EPYC): the suites at candidate/release-0.8 2907ea5d (scripts/release-tests.sh). All pass.
- `pr195-tests/` (`pr195/tests/` on the EPYC): the suites at #195 356e4ea. All pass. EPYC: `pr195/golden.log`, BLAKE3_GOLDEN=1 (127/127; 22 constants identical to those committed).
- `pr195a-check/`: #195 at a31dbf73 against 2907ea5d, `check --cells all`, governor performance. No cell slower, both stages.
- `pr195-check*/`: #195 at 356e4ea (the inlined form), the same check; diagnostic.
- Suffixes: `-oldbench` = bench 7f275a1, which predates 0.8's names and failed to build; `-schedutil`/`-powersave` = runs before I found tuned resetting the governor (the verdicts stand as paired checks; the repeated runs under performance are the ones reported).
- Bench for the checks: 9eb9f14 (samshackleton-tech/bench-hashes measure/bench87-names: #87 7f275a1 + John's candidate/names 3f9edd1, merged for measurement).
- EPYC mutation runs: `mutants-rel-2907ea5` (exit 1: two xof_many counts, #194), `mutants-rel-ca601b1` (#194, exit 0), `mutants-195-356e4ea` (#195, exit 0).
Samples are in `*.tar.xz`. Dual manifests cover this directory except themselves.
