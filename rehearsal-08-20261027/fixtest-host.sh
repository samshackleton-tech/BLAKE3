#!/bin/bash
# John's release check with bench 72b90f9 (#87 + names + the sizes fix), at #195's head 4fa4d555.
export HOME=/root; . /root/.cargo/env; systemctl is-active -q tuned && exit 9
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
R=/root/BLAKE3-rel-4fa4d555; B=$R/bench-hashes; o=/root/results/rehearsal-4fa4d55/release-fixed; mkdir -p $o
git -C $B fetch -q https://github.com/samshackleton-tech/bench-hashes measure/bench87-names || exit 13
git -C $B checkout -q --detach 72b90f9b5a2d6d45a449b11da80eff66993e35fe || exit 14
cd $B; cargo build --release -q || exit 15
{ date -u; echo "library $(git -C $R rev-parse HEAD)"; echo "bench $(git rev-parse HEAD)"; git status --short; } > $o/provenance.txt
exec 9>/root/bench-native-afk.lock; flock -w 3600 9 || exit 75
sleep 30
cargo run --release -q -- check --against bfbda1920283335ff3802723db11c209159f47fc --old-bench 5be5f23699ee7146ada56a08777173a4ee1c7bde --cells all --keep $o/samples > $o/release.out 2> $o/release.err
echo "release exit $?" > $o/status.txt
git checkout -q -- index.html 2>/dev/null
