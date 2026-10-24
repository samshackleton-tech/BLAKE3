#!/bin/bash
# offset_check.py as it would land with #141 (candidate/sam-x86-chunk-root-tool
# 75c1ec2: Devon's 6a9816d + our 64 B hash() immune, upstream blake3's the
# control): #141 build x3 and picking build x2 (expect exit 0), base x2
# (expect exit 1: our cells sensitive), align64 base x1 (expect exit 3).
set -u
r=/root/results/tool-in-141
rm -rf "$r"; mkdir -p "$r"
trap 'printf "%s\n" "$?" > "$r/runner-exit-code"' EXIT
status() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$r/status.log"; }
if ps -eo comm= | grep -Eq '^(cargo|rustc|bench-hashes.*|cargo-nextest|perf|bpftrace)$'; then exit 3; fi
wt=/root/BLAKE3-chunk-root-tool
rm -rf "$wt"; git -C /root/BLAKE3 worktree prune
git -C /root/BLAKE3 fetch -q -f /root/tool.bundle +candidate/sam-x86-chunk-root-tool:candidate/sam-x86-chunk-root-tool || exit 3
git -C /root/BLAKE3 worktree add -q "$wt" candidate/sam-x86-chunk-root-tool || exit 3
[ "$(git -C "$wt" rev-parse HEAD)" = ad29ede16d07f437202d9bd6b1bb56c1f53448b1 ] || exit 3
for spec in fix:/root/results/chunk-root/devon-check-fix/fix-clean:3 pick:/root/results/chunk-root/pick/plain-pick:2 base:/root/results/smalloc/layout/glibc-base:2 align64:/root/results/smalloc/align64/align64-base:1; do
    IFS=: read -r name exe count <<< "$spec"
    for n in $(seq 1 "$count"); do
        ( cd "$wt" && timeout 1200 python3 tools/offset_check.py --exe "$exe" --keep "$r/$name-$n" ) > "$r/$name-$n.out" 2> "$r/$name-$n.err"
        status "$name run $n: exit=$?"
    done
done
printf 'done\n' > "$r/complete"
