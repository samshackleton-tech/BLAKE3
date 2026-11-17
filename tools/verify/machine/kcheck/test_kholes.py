#!/usr/bin/env python3
"""Four holes found November 17, 2026 by reading kfn.py and the kernels' verifiers (to merge them, and then
again with the question the first two had taught); each was "shown, of something false". The copies that
were shown then are refused now; these are the copies.

1. The stack pointer (kfn.py's machine, which is kbyte.py's too). `mov rsp, rdi`, `lea rsp, [rdi]` and
   `pop rsp` put an argument's address in the stack pointer, and the machine then took a push to go to the
   function's own frame. A copy of the shipped ode_common with four instructions added wrote eight bytes
   below `a` on a processor and was shown to meet its public contract.
2. The address of the file's data (kdecode.py; kcheck.py, kloop.py). The decoder wrote `lea reg, [rip + data]`
   as a move of the number RODATA + where, the same row as a true `mov reg, NUMBER`, and the kernels'
   verifiers took any such number within the data for its address. A copy of b3hashr.o with seven bytes
   changed in the 32-lane kernel (`mov rdi, 0x50004500` for `lea rdi, [rip + the schedule]`) was shown to
   meet the public contract; on a processor it stopped on a fault, and with a page mapped at that address it
   returned a digest that is not BLAKE3's.
3. The stack below the stack pointer (kfn.py's machine). What the machine remembered of it outlived a call,
   which writes there (the return address, the callee's frame). A copy of the shipped ode_unframe that pushes
   r15 and pops it before a call, then moves the stack pointer down and pops r15 again, was shown to meet its
   public contract; on a processor r15 then holds the return address, and the function reads its input far
   outside it.
4. What a call leaves in the registers (kfn.py's machine). Every register a callee may change was the one
   unknown "left by a call"; two of them compared with a number were taken to answer alike, so a path on
   which they differ was never run. A copy of ode_unframe that writes a byte below `out` where rcx is zero
   and rdx is not (after a call, whose callee is free in what it leaves there) was shown to meet its public
   contract.
And one of that day's own changes, caught the same way before it was shipped: counting down (`dec`) and
`test` were taken to set the flags as a compare does; a jump on the order after them is refused now.
And two things the decoder read that a processor refuses as illegal instructions (class Decoder): of a milder
kind, since a function with them stops on a fault and computes nothing wrong; but it was shown to return."""
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

    def test_counting_down_says_only_whether_the_number_is_zero(self):
        at = "  dec al\n  jz @done\n"
        self.assertEqual(self.source.count(at), 2)             # (the source has two kernels: the first is the one tried here)
        with self.assertRaises(kcheck.Fail) as refused: self.kernel(self.source.replace(at, "  dec al\n  jb @done\n  jz @done\n", 1))
        self.assertIn("say only whether a number is zero", str(refused.exception))

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


class Calls(unittest.TestCase):
    """ode_unframe (programs/frame: it calls two functions by their contracts) with instructions added around a call."""
    @classmethod
    def setUpClass(cls):
        cls.work = tempfile.mkdtemp()
        read = lambda *p: open(os.path.join(HERE, "programs", *p)).read()
        cls.spec = ode.with_proof(read("frame", "frame.spec"), read("frame", "unframe.inner") + check_programs.lemmas("frame"))
        cls.source, cls.proof = read("frame", "unframe.S"), read("frame", "unframe.proof")

    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.work)

    def unframe(self, text):
        with open(os.path.join(self.work, "u.S"), "w") as f: f.write(text)
        assemble(os.path.join(self.work, "u.S"), os.path.join(self.work, "u.o"))
        kbyte.check(kbyte.load(os.path.join(self.work, "u.o"), "ode_unframe"), self.spec, "ode_unframe", self.proof)

    def changed(self, old, new):
        self.assertEqual(self.source.count(old), 1, old)
        return self.source.replace(old, new)

    def test_as_shipped(self): self.unframe(self.source)

    def test_nothing_is_remembered_of_the_stack_below_the_stack_pointer(self):
        call = "    mov rcx, r15\n    call CALL(ode_lz4_decode)\n"
        with self.assertRaises(kcheck.Fail) as refused:
            self.unframe(self.changed(call, "    mov rcx, r15\n    push r15\n    pop r11\n    call CALL(ode_lz4_decode)\n    sub rsp, 8\n    pop r15\n"))
        self.assertIn("nothing was written there", str(refused.exception))

    def test_what_a_call_leaves_in_two_registers_is_two_unknowns(self):
        after = "    call CALL(ode_lz4_decode)\n    mov qword ptr [rsp + 0], rax\n"
        evil = "    mov byte ptr [rbx - 1], 65\n.Lskip:\n    mov qword ptr [rsp + 0], rax\n"         # a byte written below `out`
        for asked in ("    cmp rcx, 0\n    jne .Lskip\n    cmp rdx, 0\n    je .Lskip\n",            # where rcx is zero and rdx is not
                      "    cmp rcx, 0\n    jne .Lskip\n"):                                         # (where rcx is zero: this one was always refused)
            with self.assertRaises(kcheck.Fail) as refused: self.unframe(self.changed(after, "    call CALL(ode_lz4_decode)\n" + asked + evil))
            self.assertIn("a write at out + -1", str(refused.exception))


class Data(unittest.TestCase):
    def test_a_number_moved_is_not_the_address_of_the_data(self):
        obj = os.path.join(HERE, "b3hashr.o")
        e = kdecode.Elf(obj); s = kdecode.Settled(e)
        start = s.at["blake3_servil_avx512_k32"]
        rows, data = kdecode.read(obj, "blake3_servil_avx512_k32", 0, 0)
        at, row = next((a, i) for a, _, i in rows if i.startswith(".lea_data "))
        self.assertTrue(row.startswith(".lea_data .rdi "))
        where = e.sections[e.index[".text"]]["off"] + (start - s.lo) + at
        b = bytearray(e.b)
        self.assertEqual(bytes(b[where:where + 3]), bytes.fromhex("488d3d"))                    # lea rdi, [rip + ...]
        b[where:where + 7] = bytes.fromhex("48c7c7") + (0x50000000 + int(row.split()[2], 16)).to_bytes(4, "little")    # mov rdi, that number
        work = tempfile.mkdtemp()
        try:
            changed = os.path.join(work, "changed.o")
            with open(changed, "wb") as f: f.write(bytes(b))
            self.assertIn(".mov 64 (.reg .rdi) (.imm 0x5000", "\n".join(i for _, _, i in kdecode.read(changed, "blake3_servil_avx512_k32", 0, 0)[0]))
            r = subprocess.run([sys.executable, os.path.join(HERE, "check_binary.py"), changed, "--maintain"], capture_output=True, text=True)
            self.assertEqual(r.returncode, 1, r.stdout[-400:])
            self.assertIn("blake3_servil_avx512_k32: NOT shown", r.stdout)
            self.assertIn("b3l_hashr: NOT shown", r.stdout)
        finally: shutil.rmtree(work)


class Decoder(unittest.TestCase):
    """Bytes the decoder read as instructions and a processor stops on (a fault for the one that is too long, an
    illegal instruction for the others: seen on one, November 17): a function with them was shown to return."""
    def decode(self, code): return kdecode.decode(bytes.fromhex(code), 0, None, b"", 0, 0, 0)

    def test_an_instruction_is_at_most_fifteen_bytes(self):
        self.assertEqual(self.decode("66" * 14 + "90"), (15, ".nop"))
        with self.assertRaisesRegex(kdecode.Stop, "more than fifteen bytes"): self.decode("66" * 20 + "90")
        with self.assertRaisesRegex(kdecode.Stop, "more than fifteen bytes"): self.decode("66" * 12 + "0f1f840000000000")

    def test_vex_has_no_instruction_at_the_older_encodings_escapes(self):
        self.assertEqual(self.decode("660f3800c1"), (5, ".xpshufb 0 0 1"))             # PSHUFB as SSSE3 writes it
        for code in ("c5f93800c1", "c5f93a0ec105", "c4e1793800c1"):
            with self.assertRaisesRegex(kdecode.Stop, "a VEX instruction this does not know"): self.decode(code)


if __name__ == "__main__":
    unittest.main()
