# bench-hashes #98 review runs: the EPYC 9255 and a 2x Xeon Gold 6330, bench 0.19 candidate 99eefde3, fork at 0.8 (b5b988d8)

runs/b98-review-*: job.sh (A/A check, plant/spin0, plant/hash6, the cache, b3sum load). runs/b98-load-*: load.sh (quiet; 4 user spinners; 4 /dev/urandom readers; 4 page-fault loops; each with the background processes' own CPU time).
