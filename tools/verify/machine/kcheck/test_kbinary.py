#!/usr/bin/env python3
"""Tests of the reading of a file whose addresses are settled (kdecode.py's Settled; klink.py; check_binary.py).

    python3 test_kbinary.py

The object klink.py makes is checked, and the same bytes as a loader would map them from a shared object
(made here: a program header put on the object, as a linker would lay it out). Then changes, each of which
must stop the reading or be refused: what a loader would not map as read, a part with leave to write, a file
that asks for its code to be changed, a name given to two places, a call sent elsewhere, an aligned read from
where nothing says it is aligned."""
import os, shutil, struct, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, HERE)
import check_binary, kcheck, kdecode, klink
from test_kcheck import assemble

QUICK = ["blake3_servil_compress_in_place_sse41", "blake3_servil_compress_in_place_avx512", "b3l_node_out", "blake3_servil_avx512_p16"]
LOAD, DYNAMIC = 1, 2


def shared(blob, flags=5, at=0x1040, off=0x40, longer=0, more=()):
    """The object as a shared object: its .text loaded at `at` from `off`, with `flags` (4 read, 2 write, 1 run)."""
    b = bytearray(blob)
    e = kdecode.Elf(blob)
    text, symtab = e.sections[e.index[".text"]], e.sections[e.index[".symtab"]]
    for i in range(symtab["size"] // 24):
        name, info, other, shndx, value, size = struct.unpack_from("<IBBHQQ", b, symtab["off"] + 24 * i)
        if shndx == e.index[".text"]: struct.pack_into("<Q", b, symtab["off"] + 24 * i + 8, value + at)
    headers = [(LOAD, flags, off, at, text["size"], text["size"] + longer)] + list(more)
    phoff = len(b)
    for typ, fl, o, v, filesz, memsz in headers: b += struct.pack("<IIQQQQQQ", typ, fl, o, v, v, filesz, memsz, 4096)
    struct.pack_into("<H", b, 16, 3); struct.pack_into("<Q", b, 32, phoff); struct.pack_into("<HH", b, 54, 56, len(headers))
    return bytes(b)


def verdict(file, symbol):
    try: check_binary.check(file, symbol); return "accepted"
    except kdecode.Stop as e: return f"stopped: {e}"
    except kcheck.Fail as e: return f"refused: {e}"


class Binary(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp(prefix="kbinary-")
        for obj, src in (("lib32.o", "c/blake3_avx512_32.S"), ("avx512.o", "c/blake3_avx512_x86-64_unix.S"), ("sse41.o", "c/blake3_sse41_x86-64_unix.S")):
            assemble(os.path.join(ROOT, src), os.path.join(cls.dir, obj))
        for name in klink.HASH: assemble(os.path.join(HERE, "glue", name + ".S"), os.path.join(cls.dir, name + ".o"))
        image, where, sizes, align = klink.link(cls.dir)
        cls.where, cls.blob = where, klink.elf(image, where, sizes, align)
        e = kdecode.Elf(cls.blob)
        cls.text = e.sections[e.index[".text"]]["off"]

    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.dir)

    def test_the_object_and_the_shared_object_are_read_alike(self):
        e = kdecode.Elf(self.blob)
        self.assertTrue(kdecode.settled(e))
        self.assertFalse(any(s["type"] in (4, 9) for s in e.sections), "klink's object has no relocations")
        so = shared(self.blob)
        for symbol in QUICK:
            self.assertEqual(verdict(self.blob, symbol), "accepted", symbol)
            self.assertEqual(verdict(so, symbol), "accepted", symbol)
            self.assertEqual([i for _, _, i in kdecode.read(self.blob, symbol, 0, 0)[0]], [i for _, _, i in kdecode.read(so, symbol, 0, 0)[0]], symbol)

    def test_the_file_shipped(self):
        with open(os.path.join(HERE, "b3hashr.o"), "rb") as f: shipped = f.read()
        e = kdecode.Elf(shipped)
        self.assertTrue(kdecode.settled(e))
        self.assertEqual(sorted(kdecode.Settled(e).at), sorted(self.where))
        for symbol in QUICK: self.assertEqual(verdict(shipped, symbol), "accepted", symbol)

    def test_the_proof_carried_in_the_file(self):
        import hashlib
        with open(os.path.join(HERE, "b3hashr.o"), "rb") as f: shipped = f.read()
        with open(os.path.join(HERE, "blake3.spec"), "rb") as f: spec = f.read()
        e = kdecode.Elf(shipped)
        proof = check_binary.carried(e.bytes_of(".ode.proof"))
        self.assertEqual(proof["spec"], hashlib.sha256(spec).hexdigest(), "the file shipped was made with the specification here")
        self.assertEqual(proof["at"], kdecode.Settled(e).at)
        self.assertEqual(proof["code"][:2], (len(e.bytes_of(".text")), hashlib.sha256(e.bytes_of(".text")).hexdigest()))
        self.assertEqual(sorted(proof["files"]), ["proofs/inner.spec", "proofs/k32.json", "proofs/p16.json", "proofs/p32.json", "specification"])
        self.assertEqual(proof["files"]["specification"], spec, "the specification the file carries is the one here")
        try:
            # the proof is not trusted: one of its contracts changed, and the function it is of is refused
            self.assertTrue(check_binary.take(proof, os.path.join(HERE, "blake3.spec")))
            self.assertEqual(verdict(shipped, "b3l_chunk_node"), "accepted")
            inner = proof["files"]["proofs/inner.spec"]
            self.assertEqual(inner.count(b"requires len <= 1024\n"), 1)
            changed = dict(proof, files=dict(proof["files"], **{"proofs/inner.spec": inner.replace(b"requires len <= 1024\n", b"requires len <= 1025\n")}))
            check_binary.take(changed, os.path.join(HERE, "blake3.spec"))
            self.assertTrue(verdict(shipped, "b3l_chunk_node").startswith("refused"))
            # and a reader with another specification is told so
            other = os.path.join(self.dir, "other.spec")
            with open(other, "wb") as f: f.write(spec + b"\n// a reader's note\n")
            self.assertFalse(check_binary.take(proof, other))
        finally:
            import kspec, kone, kloop, kfn, ode
            kspec.SPEC = ode.load(); kone.CONTRACTS = kone.contracts(); kloop.KERNELS = kloop.kernels(); kfn.CONTRACTS.clear(); check_binary.PLACES.clear()

    def test_a_proof_cannot_put_another_contract_in_the_place_of_the_readers(self):
        """The proof carries the contracts of the functions inside, which are read after the reader's
        specification. A proof whose part gives the public function a second, weaker contract (or a
        definition a second meaning) is refused: until November 15 the second took the first one's place."""
        import re, subprocess, tempfile
        with open(os.path.join(HERE, "b3hashr.o"), "rb") as f: c = kdecode.Elf(f.read()).bytes_of(".ode.proof")
        m = re.search(rb"file proofs/inner.spec (\d+)\n", c)
        n = int(m.group(1))
        weaker = b"\ncontract b3l_hashr(out: 32 bytes, input: len bytes, len: number, key: 32 bytes, flags: byte, plat: any) {\n    requires apart(out, input, key)\n    writes out\n    stack 18688 + 384 * bits(len / 1024)\n    needs sse41\n    needs avx512 if plat == 5\n}\n"
        for extra in (weaker, b"\nconst ROOT = 0\n", b"\ndef round(v, m) { v }\n", b"\ndef bits(n) { 1000000 }\n", b"\ndef len(x) { 0 }\n", b"\nlayout key 8 { a: number at 0 }\n", b"\nconst input = 1\n"):
            with tempfile.TemporaryDirectory() as d:
                path = os.path.join(d, "p")
                with open(path, "wb") as f: f.write(c[:m.start()] + b"file proofs/inner.spec %d\n" % (n + len(extra)) + c[m.end():m.end() + n] + extra + c[m.end() + n:])
                for spec in (["--spec", os.path.join(HERE, "blake3.spec")], []):
                    r = subprocess.run([sys.executable, os.path.join(HERE, "check_binary.py"), os.path.join(HERE, "b3hashr.o"), "--proof", path] + spec, capture_output=True, text=True)
                    self.assertNotEqual(r.returncode, 0, r.stdout)
                    self.assertRegex(r.stdout + r.stderr, "the proof's part declares|is the language's own|defined twice")
                    self.assertNotIn("meets its public contract", r.stdout)

    def test_what_a_loader_would_not_map_so_is_not_read(self):
        size = kdecode.Elf(self.blob).sections[1]["size"]
        for what, so in (("leave to write", shared(self.blob, flags=7)),
                         ("no leave to run", shared(self.blob, flags=4)),
                         ("not where its page is", shared(self.blob, at=0x1048)),
                         ("longer in memory than in the file", shared(self.blob, longer=8)),
                         ("two parts on one page", shared(self.blob, more=[(LOAD, 6, 0x40, 0x1040 + size, 8, 8)])),
                         ("read-only parts apart", shared(self.blob, more=[(LOAD, 4, 0x40, 0x1040 + 0x10000, 8, 8)]))):
            for symbol in QUICK: self.assertTrue(verdict(so, symbol).startswith("stopped"), f"{what}: {symbol}: {verdict(so, symbol)}")

    def test_a_file_that_asks_for_its_code_to_be_changed_is_not_read(self):
        for tags in ([(22, 0), (0, 0)], [(30, 4), (0, 0)], [(5, 0), (30, 12), (0, 0)]):
            dyn = b"".join(struct.pack("<QQ", t, v) for t, v in tags)
            so = shared(self.blob + dyn, more=[(DYNAMIC, 6, len(self.blob), 0x200000, len(dyn), len(dyn))])
            self.assertTrue(verdict(so, QUICK[0]).startswith("stopped: the file asks"), verdict(so, QUICK[0]))
        dyn = b"".join(struct.pack("<QQ", t, v) for t, v in [(5, 0), (30, 8), (0, 0), (22, 0)])       # no such tag before the end
        so = shared(self.blob + dyn, more=[(DYNAMIC, 6, len(self.blob), 0x200000, len(dyn), len(dyn))])
        self.assertEqual(verdict(so, QUICK[0]), "accepted")

    def test_a_name_given_to_two_places_is_no_name(self):
        a, b = b"blake3_servil_avx512_p32\0", b"blake3_servil_avx512_k32\0"
        self.assertEqual(self.blob.count(a), 1)
        twice = self.blob.replace(a, b)
        self.assertEqual(verdict(self.blob, "b3l_part32"), "accepted")
        self.assertTrue(verdict(twice, "blake3_servil_avx512_k32").startswith("stopped: no blake3_servil_avx512_k32"), verdict(twice, "blake3_servil_avx512_k32"))
        self.assertTrue(verdict(twice, "b3l_part32").startswith("stopped: a call to what is no function's start"), verdict(twice, "b3l_part32"))

    def test_a_call_sent_elsewhere_is_refused(self):
        calls = [(k, f) for k, f in __import__("klink_flip").fields(self.blob, "b3l_node_out") if k == "a call"]
        self.assertEqual(len(calls), 2)
        wide, narrow = "blake3_servil_compress_in_place_avx512", "blake3_servil_compress_in_place_sse41"
        seen = set()
        for _, field in calls:
            end = field + 4
            old, = struct.unpack_from("<i", self.blob, self.text + field)
            was = next(name for name, at in self.where.items() if at - end == old)
            seen.add(was)
            for name, at in self.where.items():
                if name == was: continue
                b = bytearray(self.blob); struct.pack_into("<i", b, self.text + field, at - end)
                # one change is no fault: where the contract allows AVX-512 the SSE4.1 kernel may be called as well
                self.assertEqual(verdict(bytes(b), "b3l_node_out") == "accepted", (was, name) == (wide, narrow), f"the call of {was} sent to {name}")
        self.assertEqual(seen, {wide, narrow})
        for _, field in calls:
            b = bytearray(self.blob); struct.pack_into("<i", b, self.text + field, struct.unpack_from("<i", b, self.text + field)[0] + 4)
            self.assertTrue(verdict(bytes(b), "b3l_node_out").startswith("stopped: a call to what is no function's start"))

    def test_an_aligned_read_must_be_shown_aligned(self):
        # MOVAPS from the read-only data: the object's section must be on a 16-byte boundary, and the bytes in it
        e = kdecode.Elf(self.blob)
        shoff, = struct.unpack_from("<Q", self.blob, 40)
        b = bytearray(self.blob); struct.pack_into("<Q", b, shoff + 64 * e.index[".text"] + 48, 8)
        self.assertTrue(verdict(bytes(b), "blake3_servil_compress_in_place_sse41").startswith("stopped: sixteen bytes read as aligned"))
        # the same of an assembler's object: its .rodata on an 8-byte boundary; an operand four bytes further
        with open(os.path.join(self.dir, "sse41.o"), "rb") as f: obj = f.read()
        e = kdecode.Elf(obj)
        shoff, = struct.unpack_from("<Q", obj, 40)
        b = bytearray(obj); struct.pack_into("<Q", b, shoff + 64 * e.index[".rodata"] + 48, 8)
        with self.assertRaisesRegex(kdecode.Stop, "sixteen bytes read as aligned"): kdecode.read(bytes(b), "blake3_servil_compress_in_place_sse41", 0, 0)
        rela = next(s for s in e.sections if s["type"] == 4 and s["info"] == e.index[".text"])
        start = kdecode.address(obj, "blake3_servil_compress_in_place_sse41")
        changed = 0
        for i in range(rela["size"] // 24):
            off, info, addend = struct.unpack_from("<QQq", obj, rela["off"] + 24 * i)
            if start <= off < start + 0x200 and e.sections[e.symbols[info >> 32]["shndx"]]["name"] == ".rodata" and not changed:
                b = bytearray(obj); struct.pack_into("<q", b, rela["off"] + 24 * i + 16, addend + 4); changed = 1
                with self.assertRaisesRegex(kdecode.Stop, "sixteen bytes read as aligned"): kdecode.read(bytes(b), "blake3_servil_compress_in_place_sse41", 0, 0)
        self.assertEqual(changed, 1)

    def test_an_operand_must_lie_in_what_is_loaded(self):
        fields = [f for k, f in __import__("klink_flip").fields(self.blob, "blake3_servil_avx512_p16") if k == "an operand"]
        size = kdecode.Elf(self.blob).sections[1]["size"]
        for field in fields[:2]:
            for target in (size - 32, size, size + 4096, -64):
                b = bytearray(self.blob); struct.pack_into("<i", b, self.text + field, target - (field + 4))
                v = verdict(bytes(b), "blake3_servil_avx512_p16")
                self.assertFalse(v == "accepted", f"{field:#x} -> {target:#x}")


if __name__ == "__main__":
    unittest.main()
