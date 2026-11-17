#!/bin/sh
# Every single-bit audit of kcheck/, with this machine's processor as the judge, on this tree as it is.
#
#     sh audit.sh [JOBS [hash|programs]]   (needs AVX-512 F and VL, python3, cc, clang, zlib's header;
#                                           `hash`: only hash.ode's functions and the binary; `programs`: only programs/)
#
# For each function: every bit of its code is flipped in turn; a change the decoder knows and a proof is found
# for (or, for a kernel, that the verifier accepts) is linked with BLAKE3 written out in C and run on the
# processor on inputs the contract allows. The outputs go to audit/*.txt; the last lines here are one a
# function. Exit 1 if any accepted change is told from BLAKE3 by the processor, or any change has no verdict.
# Run it after any change of kdecode.py, kfn.py, kbyte.py, kspec.py, kterms.py, kcheck.py, kglue.py,
# ode.py, klin.py, blake3.spec, proofs/inner.spec or a program's specification or proof: an unverified
# verifier is worth what its audits are worth.
# (The functions of hash.ode are judged by the whole hash: each accepted change of one of them is linked with
# the others and the kernels, and `hashr` is run against BLAKE3 on some 2,400 lengths and 200 more.)
set -u
here=$(cd "$(dirname "$0")" && pwd); cd "$here"
root=$(cd ../../../.. && pwd)
jobs=${1:-$(nproc)}
only=${2:-all}
grep -q avx512vl /proc/cpuinfo || { echo "this machine has no AVX-512 VL: the processor cannot judge"; exit 2; }
work=$(mktemp -d); mkdir -p "$work/glue" "$work/hash" audit
clang -c -o "$work/out16.o" "$root/c/blake3_output16.S" || exit 2
for f in push merge add; do clang -c -o "$work/glue/$f.o" "glue/$f.S" || exit 2; done
for f in pad chunk_node node_out wide32 wide128 take part32 subtree hashr; do clang -c -o "$work/hash/$f.o" "glue/$f.S" || exit 2; done
# the five kernels: made from their Ode sources (kernels.py), as the file shipped has them since November 17, 2026
python3 kernels.py "$work/hash" > /dev/null || exit 2
cp "$work/hash/one.o" "$work/glue/avx512.o" && cp "$work/hash/one_sse41.o" "$work/glue/sse41.o" || exit 2
bad=0
run() {     # OUTPUT COMMAND...
    out=$1; shift
    "$@" > "audit/$out" 2>&1 || { bad=1; echo "FAILED: $out"; }
}
if [ "$only" = all ]; then
for k in p16 k32 p32; do
    obj="$work/hash/k32.o"; [ $k = p16 ] && obj="$work/hash/p16.o"
    # every number of blocks, as kfn.py verifies the kernel, with kwide.py's prover as the adversary
    run "kflip-general-$k.txt" python3 kflip.py $k "$obj" --jobs "$jobs" --native 1000 --refused-sample 400 --detail --general
    # (kcheck.py's machine, a fixed number of blocks: what no verification of a shipped file loads any more)
    run "kflip-$k.txt" python3 kflip.py $k "$obj" --jobs "$jobs" --native 1000 --refused-sample 400 --detail
done
run "kflip-o16.txt" python3 kflip.py o16 "$work/out16.o" --jobs "$jobs" --native 2000 --refused-sample 400 --detail
for f in push merge add; do run "kglue-flip-$f.txt" python3 kglue_flip.py $f "$work/glue" --jobs "$jobs" --native 3000; done
for f in avx512 sse41; do run "kone-flip-$f.txt" python3 kglue_flip.py $f "$work/glue" --jobs "$jobs" --native 20000; done
fi
if [ "$only" != programs ]; then
for f in pad chunk_node node_out wide32 wide128 take part32 subtree hashr; do run "kfn-flip-$f.txt" env LIMIT="${LIMIT:-900}" python3 kfn_flip.py $f "$work/hash" --jobs "$jobs" --native 200; done
fi
if [ "$only" != hash ]; then
# the programs of programs/ (kbyte.py): every single-bit change, the processor's word on each one accepted
mkdir -p "$work/p"
for f in adler32/adler32 adler32/adler32_blocks adler32/adler32_blocks4 lz4/lz4_decode lz4/lz4_store lz4/lz4_pack varint/varint common/common utf8/utf8 base64/base64 inet/inet frame/unframe; do cc -c -o "$work/p/$(basename $f).o" "programs/$f.S" || exit 2; done
export LIMIT="${LIMIT:-900}"
export JOBS="$jobs"
flip() {    # PROGRAM FUNCTION HARNESS ARGS...
    prog=$1; fn=$2; harness=$3; shift 3
    spec="programs/$prog/$prog.spec"
    # a program with lemmas about its specification's definitions: they are read after it (steps of the proof)
    if [ -f "programs/$prog/$prog.lemmas" ]; then cat "$spec" "programs/$prog/$prog.lemmas" > "$work/$prog.spec"; spec="$work/$prog.spec"; fi
    run "kbyte-flip-$fn.txt" python3 kbyte_flip.py "$spec" "ode_$fn" "$work/p/$fn.o" "programs/$prog/$fn.proof" --jobs "$jobs" --detail --native "programs/$prog/$harness" "$@"
}
LIBS=-lz flip adler32 adler32 native.c 200
LIBS=-lz flip adler32 adler32_blocks native_blocks.c 300
LIBS=-lz flip adler32 adler32_blocks4 native_blocks4.c 300
flip lz4 lz4_decode native.c 3000 full
flip lz4 lz4_store native_store.c 3000 room
flip lz4 lz4_pack native_pack.c 2000 full
flip varint varint native.c 3000
flip common common native.c 3000
flip utf8 utf8 native.c 3000
flip inet inet native.c 3000
flip base64 base64 native.c 2000
# a function made of two others, each used by its contract: its own code changed (the two it calls are linked in as they are)
cat programs/frame/frame.spec programs/frame/unframe.inner programs/frame/frame.lemmas > "$work/frame.spec"
run "kbyte-flip-unframe.txt" env LIBS="-lz $work/p/lz4_decode.o $work/p/adler32_blocks4.o" python3 kbyte_flip.py "$work/frame.spec" ode_unframe "$work/p/unframe.o" programs/frame/unframe.proof --jobs "$jobs" --detail --native programs/frame/native.c 3000
# and every instruction left out in turn
run "kbyte-nop-unframe.txt" env LIBS="-lz $work/p/lz4_decode.o $work/p/adler32_blocks4.o" python3 kbyte_nop.py "$work/frame.spec" ode_unframe "$work/p/unframe.o" programs/frame/unframe.proof programs/frame/native.c 6000
run "kbyte-nop-lz4_pack.txt" python3 kbyte_nop.py "$work/lz4.spec" ode_lz4_pack "$work/p/lz4_pack.o" programs/lz4/lz4_pack.proof programs/lz4/native_pack.c 6000 full
run "kbyte-nop-utf8.txt" python3 kbyte_nop.py "$work/utf8.spec" ode_utf8 "$work/p/utf8.o" programs/utf8/utf8.proof programs/utf8/native.c 20000        # (with its lemma, as the file shipped has it)
run "kbyte-nop-inet.txt" python3 kbyte_nop.py programs/inet/inet.spec ode_inet "$work/p/inet.o" programs/inet/inet.proof programs/inet/native.c 5000
run "kbyte-nop-adler32_blocks.txt" env LIBS=-lz python3 kbyte_nop.py programs/adler32/adler32.spec ode_adler32_blocks "$work/p/adler32_blocks.o" programs/adler32/adler32_blocks.proof programs/adler32/native_blocks.c 600
run "kbyte-nop-adler32_blocks4.txt" env LIBS=-lz python3 kbyte_nop.py programs/adler32/adler32.spec ode_adler32_blocks4 "$work/p/adler32_blocks4.o" programs/adler32/adler32_blocks4.proof programs/adler32/native_blocks4.c 600
# the decoder with every instruction left out in turn: its proof now rests on lemmas (the unbent LZ4)
run "kbyte-nop-lz4_decode.txt" python3 kbyte_nop.py "$work/lz4.spec" ode_lz4_decode "$work/p/lz4_decode.o" programs/lz4/lz4_decode.proof programs/lz4/native.c 6000 full
# the arithmetic's proofs (varith.py) and the refuter (refute.py: the contracts worked out on numbers beside the code run here)
run "varith.txt" python3 test_varith.py
run "refute.txt" python3 test_refute.py
# the programs' files as shipped (programs/NAME/odeNAME.o): each verified as a file (by the arithmetic's proofs it
# carries, nothing searched for; then again with the search), then run on this processor
run "programs-shipped.txt" sh -c "for p in adler32 lz4 varint common utf8 base64 inet frame; do python3 programs/check_file.py programs/\$p/ode\$p.o programs/\$p/\$p.spec || exit 1; python3 programs/check_file.py programs/\$p/ode\$p.o --search | tail -n 2 || exit 1; done
  cc -O1 -o '$work/s10' programs/frame/native.c programs/frame/odeframe.o -lz && '$work/s10' 30000 &&
  cc -O1 -o '$work/s1' programs/adler32/native.c programs/adler32/odeadler32.o -lz && '$work/s1' 200 &&
  cc -O1 -o '$work/s1b' programs/adler32/native_blocks.c programs/adler32/odeadler32.o -lz && '$work/s1b' 3000 &&
  cc -O1 -o '$work/s1c' programs/adler32/native_blocks4.c programs/adler32/odeadler32.o -lz && '$work/s1c' 3000 &&
  cc -O1 -o '$work/s7' programs/utf8/native.c programs/utf8/odeutf8.o && '$work/s7' 20000 &&
  cc -O1 -o '$work/s8' programs/base64/native.c programs/base64/odebase64.o && '$work/s8' 20000 &&
  cc -O1 -o '$work/s9' programs/inet/native.c programs/inet/odeinet.o && '$work/s9' 20000 &&
  cc -O1 -o '$work/s2' programs/lz4/native.c programs/lz4/odelz4.o && '$work/s2' 20000 full &&
  cc -O1 -DBOTH -o '$work/s3' programs/lz4/native_store.c programs/lz4/odelz4.o && '$work/s3' 20000 room &&
  cc -O1 -DBOTH -o '$work/s4' programs/lz4/native_pack.c programs/lz4/odelz4.o && '$work/s4' 20000 full &&
  cc -O1 -o '$work/s5' programs/varint/native.c programs/varint/odevarint.o && '$work/s5' 100000 &&
  cc -O1 -o '$work/s6' programs/common/native.c programs/common/odecommon.o && '$work/s6' 20000"
fi
if [ "$only" != programs ]; then
# the binary as one file: what a linker would have written, bit by bit; then the file shipped, on this processor
python3 klink.py "$work/hash" "$work/blob.o" > /dev/null && run "klink-flip.txt" python3 klink_flip.py "$work/blob.o" --native 2000
run "binary.txt" sh -c "python3 check_binary.py b3hashr.o && cc -O1 -o '$work/shipped' khash_native.c kflip_thunk.S b3hashr.o && '$work/shipped' 2000 say"
fi
# the verifier's part for lemmas: every changed lemma it shows, and the lemmas as they are of every changed
# specification, judged by the specification worked out on numbers; and that this would find a verifier made wrong
run "lemma_audit.txt" python3 lemma_audit.py --cases 300 --seed 20261116
run "lemma_audit-control.txt" python3 lemma_audit.py lz4 common --control 7
# a prover that looks for another proof of changed code (functions with one loop): what it gets accepted is run on the processor
if [ "$only" != hash ]; then
(LIBS=-lz python3 kadversary.py adler32 adler32 "$work/p/adler32.o" programs/adler32/native.c 200 --jobs "$jobs" && python3 kadversary.py common common "$work/p/common.o" programs/common/native.c 3000 --jobs "$jobs" && python3 kadversary.py utf8 utf8 "$work/p/utf8.o" programs/utf8/native.c 3000 --jobs "$jobs" --limit 60) > audit/kadversary.txt 2>&1 || { bad=1; echo "FAILED: kadversary.txt"; }
fi
rm -rf "$work"
grep -H "single-bit changes" audit/kflip-*.txt audit/kglue-flip-*.txt audit/kone-flip-*.txt audit/kfn-flip-*.txt audit/kbyte-flip-*.txt | sed "s|^audit/||" | cut -c1-250
grep -h "accepted changes on this processor" audit/*.txt | sort | uniq -c | cut -c1-160
grep -h "with one left out" audit/kbyte-nop-*.txt | cut -c1-200
grep -h "^lemma_audit" audit/lemma_audit.txt audit/lemma_audit-control.txt | cut -c1-200
[ "$only" = programs ] || tail -n 1 audit/binary.txt | sed "s|^|b3hashr.o on this processor: |"
echo "audit: $([ $bad = 0 ] && echo 'every accepted change runs as the specification on this processor' || echo 'FAILED')"
exit $bad
