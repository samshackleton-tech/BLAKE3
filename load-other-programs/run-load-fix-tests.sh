#!/bin/bash
# clocks tests at 157cf95fbb760e72c8c88cade75767f4bc0bbc6e, three times over, and the ignored own-children test
# three times, after the suite (its orphan test must leave nothing running).
set -u
. /root/.cargo/env
r=/root/results/load-fix-tests
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
wt=/root/BLAKE3-load-other
git -C "$wt" fetch -q -f /root/load.bundle +candidate/sam-load-other-programs:refs/remotes/b/load || exit 3
git -C "$wt" checkout -q --detach 157cf95fbb760e72c8c88cade75767f4bc0bbc6e || exit 3
for n in 1 2 3; do
    ( cd "$wt/clocks" && timeout 900 cargo nextest run --release --no-fail-fast ) > "$r/suite-$n.log" 2>&1; echo "suite $n exit=$?" >> "$r/status.log"
    ( cd "$wt/clocks" && timeout 300 cargo test --release --lib -- --ignored own_children ) > "$r/own-$n.log" 2>&1; echo "own_children $n exit=$?" >> "$r/status.log"
done
printf 'done\n' > "$r/complete"
