# EPYC 9255: the newer wake design (#119), and the 0.8 release run (#125)

All runs: AMD EPYC 9255 (24 cores, 48 threads, 47 pool workers), Linux
7.0.0-38, rustc 1.99.1, governor `performance`. The bench lock was held,
and nothing else ran. All 88 kept runs read `quiet` (at most 0.04 other
CPUs on average, 0.33 in the busiest window). Every timing and statistic
comes from the existing `bench-hashes check`/`regress`.

## 1. The wake design alone: no cell slower; the pool cells faster

`wakes8-epyc/`. New: devonjonte/BLAKE3 `candidate/devon-wakes-8`
`d795fd088d` (the cascade, plus at most 8 direct wakes). Old: `338e249`, the
line's `servil` (the publisher makes every wake itself). The bench is
`f4a8f4eb`, nested, the same as Devon's i7 run.

- Suites at d795fd0, on the EPYC: default 110/110, `no_std` 35/35, pure
  108/108, and Shuttle (`--cfg shuttle`) 5/5.
- `check --against 338e249 --cells all --pairs 12 --keep`: **no cell slower**
  in the first stage (412 cells; 12 judged faster). The second stage (8
  suspects, 16 fresh pairs): **no cell slower**.
- Pool cells, `regress --contenders blake3-servil-mt --pairs 16` on the
  check's last 16 relinked builds a side. The points are #80's one-shots
  (512 KiB to 4 MiB, nonstop and after a pause), the 14 cells from my
  October 24 run, and the i7 cascade's batches of 16384 and 32768:
  25 cells measured: **no cell slower; 18 faster, 7 level**. The October 24 cells:

| cell (mt) | 16 pairs |
|---|---|
| solo OneMessage 2 MiB / 3 MiB | -5.0% / -4.2% |
| solo IdleOneMessage 512 KiB / 1 / 2 / 3 MiB | -3.3% / -4.5% / -6.9% / -6.3% |
| solo IdleManyMessages 8192 / 16384 / 32768 | -4.2% / -6.3% / -12.1% |
| solo ManyMessages 16384 / 32768 | -4.8% / -5.7% |
| solo LentBatches 16384; shared | -8.0%; -5.4% |
| solo Outboard 1 MiB; shared | -7.6%; -5.5% |
| solo MerkleTree 4096; shared | -4.4%; -4.4% |
| solo LentMessages 4 MiB | -3.4% |

Of the 14 cells where every-wake-direct was 4-12% slower on October 24,
13 now read 3-12% faster; LentMessages 1 MiB reads level. Capping the publisher's direct wakes at 8 helps the
47-worker machine, as on the i7 (level) and John's VM (17-45% faster).
ee4c0d7's `park.rs` is d795fd0's, with the constant named `DIRECT_WAKES`
(`wakes8-epyc/park-vs-release.diff`).

## 2. The release run: 4 cells slower, none of them the waker's

`release-08-epyc/`. New: `candidate/devon-release-0.8` `ee4c0d7` with
bench `d21cdf36`. Old: `candidate/devon-kernel-names-john` `bfbda19` with
`--old-bench 5be5f236`.

- Suites at ee4c0d7, on the EPYC: default 112, pure 104, `no_std` 29,
  capi 8, doc 19, and check-builds: all pass.
- **Same-code control** (`check --against HEAD --cells all`, 4 pairs):
  first stage, no cell slower. **Its second stage judged one cell faster,
  between identical code**: mt solo OneMessage 64 B **-18.2%**, with 16
  pairs ranging from -39% to +37%. That is a false decision on this machine
  (bench-hashes #81).
- **Release check, `--cells all --pairs 12`: "REGRESSION: 4 cells slower"**
  in the first stage, so `check` ran no second stage (exit 1):

| cell | 12 pairs |
|---|---|
| st solo LentBatches 256 | +4.0% (all 12 positive) |
| st shared LentBatches 256 | +4.6% (all 12 positive) |
| mt solo LentBatches 256 | +3.3% (all 12 positive) |
| mt solo Collection Nix files | +3.0% (all 12 positive) |

  It also judged 40 cells faster, among them all the pool cells above.
- **Not the waker:** the st contender never uses the pool. Each side ran
  its own bench (d21cdf36 against 5be5f236, which `--old-bench` requires
  for the API change). So these four may be the integration's lent-batch
  path, or the benches' workloads. **Not yet resolved.** The next step is to
  re-judge these four cells on fresh pairs (the second stage that `check`
  skipped).

## Code review notes (no blocker)

- `pay_owed` (d795fd0/ee4c0d7): the first woken worker could pay
  nearly all the owed wakes. Devon found this by counting, and fixes it
  with FANOUT (485d7ab).
- In both versions, when `wake_one` finds nobody parked, `pay_owed` does
  `owed.store(0)`. That can erase wakes another publisher owed at the
  same moment. This costs speed only (the pool's other wake paths and the
  next publish still run the work), not liveness. Undoing just the
  failed decrement (`fetch_add(1)` back, or a CAS to the value observed)
  would keep the debt.

## Queued

`fanout-epyc` (`fanout-run.sh`): suites and Shuttle at 485d7ab, then (A)
FANOUT 8 against ee4c0d7 (wakes-8), then (B) FANOUT 64 (every wake
direct; a measurement-only commit that changes only the constant)
against FANOUT 8. Both `--cells all --pairs 12 --keep`, bench d21cdf36.
