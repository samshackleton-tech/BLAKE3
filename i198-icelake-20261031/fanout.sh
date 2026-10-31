#!/bin/bash
# BLAKE3 #198: the 0.8 tag with park.rs's FANOUT at other values, each against the tag itself
# (check --cells all: a changed const is inlined, so coverage selects no cell), then mt ManyMessages 16384
# at 32 pairs on that check's builds. Same bench (0.18.3) both sides.
set -u
R="$1"; O="$R/out"; mkdir -p "$O"
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
T=b5b988d8982bea9490c38c79ec4b8c5c2428270c
{ grep -m1 'model name' /proc/cpuinfo; nproc; sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; } > "$O/machine.txt"
for V in $FANOUTS; do
  d="$R/w-$V"; o="$O/fanout-$V"; mkdir -p "$o"
  git -C "$R/src" worktree add -q --detach "$d" $T || exit 2
  python3 - "$d/src/park.rs" "$V" <<'PY' || exit 3
import sys
p,v=sys.argv[1:3]; s=open(p).read(); a="pub(crate) const FANOUT: usize = 8;"
assert s.count(a)==1; open(p,"w").write(s.replace(a,f"pub(crate) const FANOUT: usize = {v};"))
PY
  git -C "$d" diff > "$o/patch.diff"
  git clone -q "$R/bench" "$d/bench-hashes" && git -C "$d/bench-hashes" checkout -q --detach f17a161b6c19a2a639da0e19f82d44975a841bef
  cd "$d/bench-hashes"; cargo build --release > "$o/bench-build.log" 2>&1 || exit 4
  cargo run --release -- check --against $T --cells all > "$o/check.out" 2> "$o/check.err"; echo "fanout $V check exit $?" >> "$O/status.txt"
  C=$d/target/check
  mapfile -t old < <(ls $C/old | grep -E '^bench-hashes-[0-9]+$' | sort -t- -k3 -n | sed "s|^|$C/old/|")
  mapfile -t new < <(ls $C/new | grep -E '^bench-hashes-[0-9]+$' | sort -t- -k3 -n | sed "s|^|$C/new/|")
  ./target/release/bench-hashes regress --contenders blake3-servil-mt --points 16384 --judge "blake3-servil-mt|solo|ManyMessages|16384" --pairs 32 --keep "$o/mm16384" "${old[@]}" -- "${new[@]}" > "$o/mm16384.out" 2>&1
  echo "fanout $V mm16384 exit $?" >> "$O/status.txt"
  git checkout -q -- index.html 2>/dev/null; rm -rf "$d/target"; cd "$R"
done
echo done >> "$O/status.txt"
