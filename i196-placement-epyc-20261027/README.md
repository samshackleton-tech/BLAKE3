# BLAKE3 #196 on the EPYC 9255: the two-speed stream is where the pool's threads land

Every run here went through pinned-run (pinned-run.py, as run): inputs fetched by full hash
(fork 934dee89, bench 67bae864 / 3f9edd13), fresh checkouts, outputs verified to name
blake3-servil 0.8.0+f7ce4e4e (local checkout ..) at 934dee89; each run's manifest.json, STATUS, logs.
The EPYC 9255 has four L3 domains of 6 cores (12 logical CPUs): 0-5,24-29 / 6-11,30-35 / ...

- runs/i196-reproduce-*: mt ContinuousMessages 256 B alone, 10 processes per bench: both benches two-speed.
- runs/i196-placement-*: 8 processes each under taskset: one L3 domain / two domains (same CPU count) / all.
- runs/i196-scope-*, i196-pool-*: the stream, batch, one-shot, lent and after-a-pause cells, one domain vs all.
- runs/i196-separate-*: four placements (1 domain 12 CPUs, 2 domains 12, 2 domains 24, all 48), the pool's
  thread count sampled per process (14 / 14 / 26 / 50).
placement_table.py prints the medians; the FAILED-* run is a bad --points label (kept, as pinned-run keeps it).
