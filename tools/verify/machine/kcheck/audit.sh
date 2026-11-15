#!/bin/sh
# Every single-bit audit of kcheck/, with this machine's processor as the judge, on this tree as it is.
#
#     sh audit.sh [JOBS [hash]]   (needs AVX-512 F and VL, python3, cc, clang; `hash`: only hash.ode's functions)
#
# For each function: every bit of its code is flipped in turn; a change the decoder knows and a proof is found
# for (or, for a kernel, that the checker accepts) is linked with BLAKE3 written out in C and run on the
# processor on inputs the contract allows. The outputs go to audit/*.txt; the last lines here are one a
# function. Exit 1 if any accepted change is told from BLAKE3 by the processor, or any change has no verdict.
# Run it after any change of kdecode.py, kcheck.py, kloop.py, kglue.py, kone.py, kfn.py, kspec.py, ode.py,
# klin.py, blake3.spec or proofs/inner.spec: an unverified checker is worth what its audits are worth.
# (The functions of hash.ode are judged by the whole hash: each accepted change of one of them is linked with
# the others and the kernels, and `hashr` is run against BLAKE3 on some 2,400 lengths and 200 more.)
set -u
here=$(cd "$(dirname "$0")" && pwd); cd "$here"
root=$(cd ../../../.. && pwd)
jobs=${1:-$(nproc)}
only=${2:-all}
grep -q avx512vl /proc/cpuinfo || { echo "this machine has no AVX-512 VL: the processor cannot judge"; exit 2; }
work=$(mktemp -d); mkdir -p "$work/glue" "$work/hash" audit
clang -c -o "$work/lib32.o" "$root/c/blake3_avx512_32.S" && clang -c -o "$work/out16.o" "$root/c/blake3_output16.S" || exit 2
for f in push merge add; do clang -c -o "$work/glue/$f.o" "glue/$f.S" || exit 2; done
cc -c -o "$work/glue/avx512.o" "$root/c/blake3_avx512_x86-64_unix.S" && cc -c -o "$work/glue/sse41.o" "$root/c/blake3_sse41_x86-64_unix.S" || exit 2
for f in pad chunk_node node_out wide32 wide128 take part32 subtree hashr; do clang -c -o "$work/hash/$f.o" "glue/$f.S" || exit 2; done
cp "$work/glue/avx512.o" "$work/glue/sse41.o" "$work/lib32.o" "$work/hash/"
bad=0
run() {     # OUTPUT COMMAND...
    out=$1; shift
    "$@" > "audit/$out" 2>&1 || { bad=1; echo "FAILED: $out"; }
}
if [ "$only" = all ]; then
for k in p16 k32 p32; do
    run "kflip-$k.txt" python3 kflip.py $k "$work/lib32.o" --jobs "$jobs" --native 1000 --refused-sample 400 --detail
    run "kflip-general-$k.txt" python3 kflip.py $k "$work/lib32.o" --jobs "$jobs" --native 1000 --refused-sample 400 --detail --general
done
run "kflip-o16.txt" python3 kflip.py o16 "$work/out16.o" --jobs "$jobs" --native 2000 --refused-sample 400 --detail
for f in push merge add; do run "kglue-flip-$f.txt" python3 kglue_flip.py $f "$work/glue" --jobs "$jobs" --native 3000; done
for f in avx512 sse41; do run "kone-flip-$f.txt" python3 kglue_flip.py $f "$work/glue" --jobs "$jobs" --native 20000; done
fi
for f in pad chunk_node node_out wide32 wide128 take part32 subtree hashr; do run "kfn-flip-$f.txt" env LIMIT="${LIMIT:-900}" python3 kfn_flip.py $f "$work/hash" --jobs "$jobs" --native 200; done
# the binary as one file: what a linker would have written, bit by bit; then the file shipped, on this processor
python3 klink.py "$work/hash" "$work/blob.o" > /dev/null && run "klink-flip.txt" python3 klink_flip.py "$work/blob.o" --native 2000
run "binary.txt" sh -c "python3 check_binary.py b3hashr.o && cc -O1 -o '$work/shipped' khash_native.c kflip_thunk.S b3hashr.o && '$work/shipped' 2000 say"
rm -rf "$work"
grep -H "single-bit changes" audit/kflip-*.txt audit/kglue-flip-*.txt audit/kone-flip-*.txt audit/kfn-flip-*.txt | sed "s|^audit/||" | cut -c1-250
grep -h "accepted changes on this processor" audit/*.txt | sort | uniq -c | cut -c1-160
tail -n 1 audit/binary.txt | sed "s|^|b3hashr.o on this processor: |"
echo "audit: $([ $bad = 0 ] && echo 'every accepted change runs as the specification on this processor' || echo 'FAILED')"
exit $bad
