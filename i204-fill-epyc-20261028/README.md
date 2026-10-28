# BLAKE3 #204 on the EPYC 9255: Devon's fill-like-read prototype

Library devonjonte exp/devon-fill-like-read c09e2100, bench devonjonte exp/devon-bench-fill-count 946555d2 nested; orchestrating binary bench 0.18.1 (2c9633ae). Suites (nextest release, no_std), then `check --against 83d59db --old-bench 2c9633ae --cells all`. pinned-run; the FAILED run built the new bench alone, which needs the new library (kept).
