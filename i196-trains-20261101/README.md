# BLAKE3 #196: 2 s trains of servil mt streams on the EPYC 9255, by placement

bench 0.19 candidate (99eefde3) against the fork at 0.8 (b5b988d8), --train 0,2000 --nonstop-visits 1, 3 processes each. runs/i196-train-by-placement-*: confined to one L3 domain (taskset 0-5,24-29) and on all 48 CPUs (job2.sh). runs/FAILED-i196-placement-over-time-*: thread CPU snapshots every 20 ms beside the trains (job.sh; marked FAILED only for my tag names; its alignment of placement to samples is unreliable, see #196).
