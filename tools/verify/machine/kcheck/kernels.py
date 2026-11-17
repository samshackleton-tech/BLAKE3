#!/usr/bin/env python3
"""kernels: the hash's five kernels made from their Ode sources. A maker's step: trusted for nothing, loaded
by no verification.

    python3 kernels.py FOLDER [--proofs]

The sources are ../wide/one.ode (the two one-block kernels), ../wide/k32.ode (the 32-lane kernel, entered
two ways) and ../wide/p16.ode (the 16-lane one): Ode's instruction layer. The Ode compiler (../lang/odec.py)
prints each as assembly, adding and changing no instruction, and an assembler makes FOLDER/NAME.o of it,
which klink.py takes. (Each is, byte for byte, the kernel of BLAKE3-Servil's own assembly files:
../wide/test_sources.py.)

A wide kernel loops over the blocks of a chunk, any number of them, and its source says what holds at the
loop (`place b { ... }`). `--proofs` writes the proof of each such loop to proofs/NAME.json: what the source
says, and how many bytes into the kernel the place is, which the assembler knows (it is in the object, in a
section `.ode.place` that is not loaded). No search: until November 17, 2026 these proofs were found by a
prover that ran the kernel (now kwide.py, which the audits still use as an adversary)."""
import json, os, shutil, struct, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, "..", "lang"))
import kdecode, odec

# (the source, the kernel's name in it, the object, {a name it is entered by: the proof of its loop, if it has one})
KERNELS = [("one.ode", "compress1", "one.o", {"blake3_servil_compress_in_place_avx512": None}),
           ("one.ode", "compress1_sse41", "one_sse41.o", {"blake3_servil_compress_in_place_sse41": None}),
           ("k32.ode", "k32", "k32.o", {"blake3_servil_avx512_k32": "k32", "blake3_servil_avx512_p32": "p32"}),
           ("p16.ode", "p16", "p16.o", {"blake3_servil_avx512_p16": "p16"})]


def assemble(s_path, o_path):
    for cc in (["clang", "--target=x86_64-unknown-linux-gnu"], ["cc"]):
        if shutil.which(cc[0]) and subprocess.run(cc + ["-c", "-o", o_path, s_path], capture_output=True).returncode == 0: return
    raise SystemExit(f"kernels: no assembler here makes an x86-64 ELF object of {s_path}")


def make(folder, proofs=False):
    out = []
    for source, kernel, obj, entries in KERNELS:
        src = os.path.join(HERE, "..", "wide", source)
        with open(os.path.join(folder, obj[:-2] + ".S"), "w") as f: f.write(odec.kernel_x86(src, kernel, shipped=True))
        assemble(os.path.join(folder, obj[:-2] + ".S"), os.path.join(folder, obj))
        held = odec.place_of(src, kernel)
        if held is None: out.append((obj, kernel, None)); continue
        place, = struct.unpack("<I", kdecode.Elf(os.path.join(folder, obj)).bytes_of(".ode.place"))
        proof = dict(place=place, **held)
        out.append((obj, kernel, proof))
        if proofs:
            for name in entries.values():
                with open(os.path.join(HERE, "proofs", name + ".json"), "w") as f: json.dump(proof, f, indent=1); f.write("\n")
    return out


if __name__ == "__main__":
    for obj, kernel, proof in make(sys.argv[1], "--proofs" in sys.argv):
        print(f"{obj}: kernel {kernel}" + (f"; its loop's place +0x{proof['place']:X}, {len(proof['registers'])} registers, {len(proof['vectors'])} vector registers, {len(proof['frame'])} frame cells named, from the source" if proof else ""))
