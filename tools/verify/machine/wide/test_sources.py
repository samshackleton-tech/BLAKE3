#!/usr/bin/env python3
"""The five kernels' Ode sources (one.ode, k32.ode, p16.ode) against BLAKE3-Servil's own assembly files:

    python3 test_sources.py

- each kernel made from its source (kcheck/kernels.py: odec.py, then an assembler) is, byte for byte, the
  kernel the library's assembly file gives, and reads the same constants; the 32-lane kernel's second way in
  is at the same place;
- each is verified from that object by kcheck/kfn.py, the verifier of functions;
- the proof of a wide kernel's loop written from the source (`place b { ... }`) is the one a prover finds by
  running the kernel (kcheck/kwide.py), name for name;
- a source changed (a rotation; what the place says) gives other bytes or another proof, and is refused."""
import json, os, shutil, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "kcheck")); sys.path.insert(0, os.path.join(HERE, "..", "lang"))
import kdecode, kernels, kfn, kspec, kterms, kwide, ode, odec

CRATE = {"blake3_servil_compress_in_place_avx512": "blake3_avx512_x86-64_unix.S", "blake3_servil_compress_in_place_sse41": "blake3_sse41_x86-64_unix.S",
         "blake3_servil_avx512_k32": "blake3_avx512_32.S", "blake3_servil_avx512_p16": "blake3_avx512_32.S"}
START = {"blake3_servil_avx512_p32": "blake3_servil_avx512_k32"}


def body(obj, symbol):
    """(the function's bytes as they lie in the object, its instructions with the constants they read)"""
    start, rows = kdecode.address(obj, symbol), kdecode.read(obj, symbol, 0, 0)[0]
    return kdecode.Elf(obj).bytes_of(".text")[start:start + rows[-1][1]], [i for _, _, i in rows]


class Sources(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp(prefix="sources-")
        cls.made = {obj: (kernel, proof) for obj, kernel, proof in kernels.make(cls.dir)}
        for source in set(CRATE.values()): kernels.assemble(os.path.join(ROOT, "c", source), os.path.join(cls.dir, "crate-" + source[:-2] + ".o"))
        with open(os.path.join(HERE, "..", "kcheck", "blake3.spec")) as f: spec = f.read()
        with open(os.path.join(HERE, "..", "kcheck", "proofs", "inner.spec")) as f: inner = f.read()
        kspec.SPEC = ode.with_proof(spec, inner)

    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.dir)

    def verify(self, obj, symbol, proof):
        kfn.CONTRACTS.clear()
        rows, data, entry = kfn.load_from(obj, symbol, START.get(symbol, symbol))
        return kfn.check(rows, None, proof=proof, symbol=symbol, entry=entry, data=data)

    def test_each_kernel_is_the_librarys_byte_for_byte(self):
        for _, _, obj, entries in kernels.KERNELS:
            symbol = next(iter(entries))
            mine, theirs = body(os.path.join(self.dir, obj), symbol), body(os.path.join(self.dir, "crate-" + CRATE[symbol][:-2] + ".o"), symbol)
            self.assertEqual(mine[0], theirs[0], f"{symbol}: its bytes")
            self.assertEqual(mine[1], theirs[1], f"{symbol}: its instructions and the constants they read")
        k32, crate = os.path.join(self.dir, "k32.o"), os.path.join(self.dir, "crate-blake3_avx512_32.o")
        self.assertEqual(kdecode.address(k32, "blake3_servil_avx512_p32") - kdecode.address(k32, "blake3_servil_avx512_k32"),
                         kdecode.address(crate, "blake3_servil_avx512_p32") - kdecode.address(crate, "blake3_servil_avx512_k32"))

    def test_each_is_verified_and_the_loops_proofs_are_what_a_prover_finds(self):
        for _, _, obj, entries in kernels.KERNELS:
            path, proof = os.path.join(self.dir, obj), self.made[obj][1]
            for symbol, name in entries.items():
                self.verify(path, symbol, proof)
                if name is None: self.assertIsNone(proof); continue
                with open(os.path.join(HERE, "..", "kcheck", "proofs", name + ".json")) as f: self.assertEqual(json.load(f), proof, f"proofs/{name}.json is what the source says")
                rows, data, entry = kfn.load_from(path, symbol, START.get(symbol, symbol))
                kfn.CONTRACTS.clear()
                self.assertEqual(kwide.smallest(rows, data, symbol, entry, kwide.find(rows, data, symbol, entry)), proof, f"{symbol}: the prover's proof")

    def changed(self, source, kernel, old, new):
        """The kernel of a source with `old` (which is there once) changed to `new`: (the object, the proof of its loop)."""
        with open(os.path.join(HERE, source)) as f: text = f.read()
        self.assertEqual(text.count(old), 1, old)
        src = os.path.join(self.dir, "changed.ode")
        with open(src, "w") as f: f.write(text.replace(old, new))
        with open(os.path.join(self.dir, "changed.S"), "w") as f: f.write(odec.kernel_x86(src, kernel, shipped=True))
        kernels.assemble(os.path.join(self.dir, "changed.S"), os.path.join(self.dir, "changed.o"))
        held = odec.place_of(src, kernel)
        return os.path.join(self.dir, "changed.o"), held and dict(held, place=self.made["p16.o"][1]["place"])

    def test_a_changed_source_is_refused(self):
        p16 = "blake3_servil_avx512_p16"
        true = body(os.path.join(self.dir, "p16.o"), p16)[0]
        for what, old, new in (("the place says the offset moves 32 a block", "    r14 = 64 * b\n", "    r14 = 32 * b\n"),
                               ("the place does not say the table's register is kept", "keep rsp, rbp, rsi, rdi, r8, r9, r10, r12, r15", "keep rsp, rbp, rsi, rdi, r8, r9, r10, r15"),
                               ("the place says the value is in other registers", "    zmm0 .. zmm7 = h[b]\n", "    zmm1 .. zmm8 = h[b]\n"),
                               ("the offset moves 128 a block", "  add r14, 64\n", "  add r14, 128\n")):
            with self.subTest(what):
                obj, proof = self.changed("p16.ode", "p16", old, new)
                self.assertEqual(body(obj, p16)[0] == true, old.startswith(("    ", "keep")), what)       # a change of the place's lines changes no byte of the kernel
                with self.assertRaises(kterms.Fail): self.verify(obj, p16, proof)
        one = "blake3_servil_compress_in_place_sse41"
        with open(os.path.join(HERE, "one.ode")) as f: text = f.read()
        src = os.path.join(self.dir, "one-changed.ode")
        at = text.index("kernel compress1_sse41")
        self.assertEqual(text.count("    pslld xmm1, 20\n", at), 1)
        with open(src, "w") as f: f.write(text[:at] + text[at:].replace("    pslld xmm1, 20\n", "    pslld xmm1, 21\n"))
        with open(os.path.join(self.dir, "one-changed.S"), "w") as f: f.write(odec.kernel_x86(src, "compress1_sse41", shipped=True))
        kernels.assemble(os.path.join(self.dir, "one-changed.S"), os.path.join(self.dir, "one-changed.o"))
        self.assertNotEqual(body(os.path.join(self.dir, "one-changed.o"), one)[0], body(os.path.join(self.dir, "one_sse41.o"), one)[0])
        with self.assertRaises(kterms.Fail): self.verify(os.path.join(self.dir, "one-changed.o"), one, None)


if __name__ == "__main__":
    unittest.main()
