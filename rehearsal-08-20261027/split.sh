#!/bin/bash
# Separating bench from library in the release check's 15 slower cells (EPYC 9255).
#  A (bench only): library 4fa4d555 both sides; old bench 3f9edd1 (John's candidate/names,
#    before #87), new bench 72b90f9 (#87 + names + sizes fix).
#  B (library only): new 4fa4d555 with bench 3f9edd1, old bfbda192 with old bench 5be5f236.
export HOME=/root; . /root/.cargo/env
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton'
export GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
R=/root/BLAKE3-rel-4fa4d555; B=$R/bench-hashes; o=/root/results/split-15; mkdir -p $o
git -C $B fetch -q https://github.com/johnservil/bench-hashes candidate/names || exit 13
git -C $B cat-file -e 3f9edd139b || exit 13
exec 9>/root/bench-native-afk.lock; flock -w 3600 9 || exit 75
git -C $B checkout -q --detach 72b90f9b5a2d6d45a449b11da80eff66993e35fe && cd $B && cargo build --release -q || exit 15
sleep 30
cargo run --release -q -- check --against 4fa4d555054f35b8a43e06da8d145c669625c0ea --old-bench 3f9edd139b --cells all --keep $o/A-samples > $o/A.out 2> $o/A.err
echo "A (bench only) exit $?" >> $o/status.txt
git checkout -q -- index.html 2>/dev/null
git -C $B checkout -q --detach 3f9edd139b && cargo build --release -q || exit 16
sleep 30
cargo run --release -q -- check --against bfbda1920283335ff3802723db11c209159f47fc --old-bench 5be5f23699ee7146ada56a08777173a4ee1c7bde --cells all --keep $o/B-samples > $o/B.out 2> $o/B.err
echo "B (library only) exit $?" >> $o/status.txt
git checkout -q -- index.html 2>/dev/null
