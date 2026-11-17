#!/usr/bin/env python3
"""The stack pointer stays in the function's own frame (kfn.py's machine, which is kbyte.py's too).

Found November 17, 2026: `mov rsp, rdi`, `lea rsp, [rdi]` and `pop rsp` put an argument's address in the stack
pointer, and the machine then took a push to go to the function's own frame. A copy of the shipped ode_common
with four instructions added wrote eight bytes below `a` on a processor and was shown to meet its public
contract. Each such copy is refused now; these are the copies."""
import os, shutil, subprocess, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, "programs")); sys.path.insert(0, os.path.join(HERE, "..", "lang"))
import check_programs, kbyte, kcheck, kdecode, kfn, kspec, ode, odec
from test_kcheck import assemble

KERNEL = "blake3_servil_compress_in_place_avx512"
FIRST = "  vmovdqu xmm0, xmmword ptr [rdi]\n"            # the kernel's first instruction (wide/one.ode)
WAYS = [("an argument's address moved into it, a push, and back", "  mov rax, rsp\n  mov rsp, rdi\n  push rbx\n  mov rsp, rax\n", "leaves the function's own frame"),
        ("the same by lea", "  mov rax, rsp\n  lea rsp, [rdi+0]\n  push rbx\n  mov rsp, rax\n", "leaves the function's own frame"),
        ("the same by a pop", "  mov rax, rsp\n  push rdi\n  pop rsp\n  push rbx\n  mov rsp, rax\n", "a pop into the stack pointer"),
        ("a push of it", "  push rsp\n  pop rax\n", "a push of the stack pointer"),
        ("above where it was at entry", "  add rsp, 8\n  sub rsp, 8\n", "leaves the function's own frame"),
        ("moved 8192 bytes down by lea, a write there, and back", "  lea rsp, [rsp-0x2000]\n  mov qword ptr [rsp], rbx\n  lea rsp, [rsp+0x2000]\n", "8192 bytes of stack used")]


class Stack(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.work = tempfile.mkdtemp()
        with open(os.path.join(HERE, "blake3.spec")) as f: spec = f.read()
        with open(os.path.join(HERE, "proofs", "inner.spec")) as f: inner = f.read()
        head = "ensures h = compress(h, m, t, length, flags)\n    stack 0\n    needs avx512"
        assert inner.count(head) == 1
        # the kernel's contract with room on the stack: a maker's to write (an inner contract)
        cls.spec = ode.with_proof(spec, inner.replace(head, head.replace("stack 0", "stack 4096")))
        with open(os.path.join(HERE, "..", "wide", "one.ode")) as f: cls.source = f.read()
        assert cls.source.count(FIRST) == 1

    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.work)

    def kernel(self, source):
        p = os.path.join(self.work, "k.ode")
        with open(p, "w") as f: f.write(source)
        with open(os.path.join(self.work, "k.S"), "w") as f: f.write(odec.kernel_x86(p, "compress1", prefix="x_").replace("x_compress1", KERNEL))
        assemble(os.path.join(self.work, "k.S"), os.path.join(self.work, "k.o"))
        kspec.SPEC = self.spec; kfn.CONTRACTS.clear()
        kfn.check(kfn.load(os.path.join(self.work, "k.o"), None, KERNEL), None, symbol=KERNEL)

    def test_the_kernel_as_it_is_meets_the_contract_with_room_on_the_stack(self):
        self.kernel(self.source)

    def test_no_way_out_of_the_frame(self):
        for what, added, why in WAYS:
            with self.subTest(what):
                with self.assertRaises(kcheck.Fail) as refused: self.kernel(self.source.replace(FIRST, added + FIRST))
                self.assertIn(why, str(refused.exception))

    def common(self, text, place):
        read = lambda *p: open(os.path.join(HERE, "programs", *p)).read()
        with open(os.path.join(self.work, "c.S"), "w") as f: f.write(text)
        assemble(os.path.join(self.work, "c.S"), os.path.join(self.work, "c.o"))
        spec = ode.with_proof(read("common", "common.spec"), check_programs.lemmas("common"))
        kbyte.check(kbyte.load(os.path.join(self.work, "c.o"), "ode_common"), spec, "ode_common", read("common", "common.proof").replace("place +0x34", "place " + place))

    def test_a_program_of_bytes_that_writes_below_its_argument(self):
        with open(os.path.join(HERE, "programs", "common", "common.S")) as f: text = f.read()
        at = "_ode_common:\n    push rbx\n"
        self.assertEqual(text.count(at), 1)
        self.common(text, "+0x34")                                          # as shipped
        with self.assertRaises(kcheck.Fail) as refused:
            self.common(text.replace(at, "_ode_common:\n    mov rax, rsp\n    mov rsp, rdi\n    push rbx\n    mov rsp, rax\n    push rbx\n"), "+0x3e")
        self.assertIn("leaves the function's own frame", str(refused.exception))


if __name__ == "__main__":
    unittest.main()
