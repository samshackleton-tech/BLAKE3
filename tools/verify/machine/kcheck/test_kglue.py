#!/usr/bin/env python3
"""kglue on push, merge and add: a proof is found and checked for each; changed code and wrong proofs are refused.

    python3 test_kglue.py

glue/push.S, merge.S and add.S are lang/NAME.S as the Ode compiler prints them from lang/hasher.ode (copies:
the compiler needs Lean); they are assembled here (clang where there is one, else cc)."""
import copy, os, shutil, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kcheck, kglue
from test_kcheck import assemble

# (function, what, the instruction, which occurrence, what it becomes)
MUTANTS = [
    ("merge", "the pair below the top is merged", ".sub 64 (.reg .rcx) (.imm 0x2)", 0, ".sub 64 (.reg .rcx) (.imm 0x3)"),
    ("merge", "a value taken for 16 bytes", ".shl64 .rcx 5", 0, ".shl64 .rcx 4"),
    ("merge", "the ROOT flag in place of PARENT", ".or 64 (.reg .rax) (.imm 0x4)", 0, ".or 64 (.reg .rax) (.imm 0x8)"),
    ("merge", "no PARENT flag", ".or 64 (.reg .rax) (.imm 0x4)", 0, ".nop"),
    ("merge", "the left value twice", ".add 64 (.reg .rax) (.imm 0x20)", 1, ".add 64 (.reg .rax) (.imm 0x0)"),
    ("merge", "the right value first", ".add 64 (.reg .rcx) (.imm 0x20)", 0, ".add 64 (.reg .rcx) (.imm 0x0)"),
    ("merge", "the count falls by two", ".sub 64 (.reg .rax) (.imm 0x1)", 0, ".sub 64 (.reg .rax) (.imm 0x2)"),
    ("merge", "the loop's condition turned round", ".jae 0x1012A", 0, ".jb 0x1012A"),
    ("merge", "the count not written back", ".mov 64 (.mem .rcx 0x0) (.reg .rax)", 0, ".nop"),
    ("merge", "half of the parent not written back", ".xstoreu .rcx 0x10 0", 3, ".nop"),
    ("merge", "the stack's memory read as the key", ".mov 64 (.reg .rax) (.reg .rbp)", 0, ".mov 64 (.reg .rax) (.reg .rbx)"),
    ("merge", "a block length of 63", ".mov 64 (.reg .rdx) (.imm 0x40)", 0, ".mov 64 (.reg .rdx) (.imm 0x3F)"),
    ("merge", "a counter of 1", ".mov 64 (.reg .rcx) (.imm 0x0)", 0, ".mov 64 (.reg .rcx) (.imm 0x1)"),
    ("merge", "the target returned", ".mov 64 (.reg .rax) (.reg .r15)", 2, ".mov 64 (.reg .rax) (.reg .r14)"),
    ("merge", "a kept register not restored", ".pop .r13", 0, ".pop .r12"),
    ("merge", "the frame freed short", ".add 64 (.reg .rsp) (.imm 0x78)", 0, ".add 64 (.reg .rsp) (.imm 0x70)"),
    ("merge", "the kernel's result left in the frame", ".xstoreu .rcx 0x0 0", 3, ".nop"),
    ("push", "a value taken for 16 bytes", ".shl64 .rdx 5", 0, ".shl64 .rdx 4"),
    ("push", "the value put a place low", ".add 64 (.reg .rcx) (.imm 0x20)", 0, ".add 64 (.reg .rcx) (.imm 0x0)"),
    ("push", "the count rises by two", ".add 64 (.reg .rax) (.imm 0x1)", 0, ".add 64 (.reg .rax) (.imm 0x2)"),
    ("push", "half of the value not copied", ".xstoreu .rcx 0x10 0", 0, ".nop"),
    ("add", "merge given the new value for the key", ".mov 64 (.reg .rsi) (.reg .rbp)", 0, ".mov 64 (.reg .rsi) (.reg .r14)"),
    ("add", "no push", ".call b3l_push", 0, ".nop"),
    ("add", "the platform given for the target", ".mov 64 (.reg .r8) (.reg .r15)", 0, ".mov 64 (.reg .r8) (.reg .r13)"),
    ("add", "push twice", ".call b3l_merge", 0, ".call b3l_push"),
]


class Kglue(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp(prefix="kglue-")
        cls.rows = {}
        for name in ("push", "merge", "add"):
            assemble(os.path.join(HERE, "glue", name + ".S"), os.path.join(cls.dir, name + ".o"))
            cls.rows[name] = kglue.load(os.path.join(cls.dir, name + ".o"), name)
        cls.proofs = {name: kglue.find(rows, name) for name, rows in cls.rows.items()}

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.dir)

    def test_a_proof_is_found_and_checked_for_each(self):
        self.assertEqual([len(self.proofs[n]["places"]) for n in ("push", "merge", "add")], [0, 1, 0])
        for name, rows in self.rows.items():
            done = kglue.check(rows, name, self.proofs[name])
            self.assertGreaterEqual(done["return"], 1, name)

    def test_changed_code_gets_no_proof_and_the_true_proof_is_refused_on_it(self):
        for name, what, old, which, new in MUTANTS:
            rows = list(self.rows[name])
            hits = [k for k, r in enumerate(rows) if r[2] == old]
            self.assertGreater(len(hits), which, f"{name}: no instruction `{old}` number {which}")
            rows[hits[which]] = (rows[hits[which]][0], rows[hits[which]][1], new)
            with self.assertRaises(kcheck.Fail, msg=f"the prover on {name}: {what}"):
                kglue.find(rows, name)
            with self.assertRaises(kcheck.Fail, msg=f"the verifier with the true proof on {name}: {what}"):
                kglue.check(rows, name, self.proofs[name])

    def test_a_changed_contract_refuses_the_true_function(self):
        # the contracts are text in blake3.spec: one change of a contract, and the function that met it does not
        import kspec, ode
        true = kspec.SPEC
        text = ode.source()
        changes = [("push", "ensures st = st ++ [new]", "ensures st = st"),
                   ("push", "requires len(st) <= 54\n    ensures st = st ++ [new]", "requires len(st) <= 55\n    ensures st = st ++ [new]"),
                   ("push", "ensures st = st ++ [new]\n    stack 64\n", "ensures st = st ++ [new]\n    stack 16\n"),
                   ("merge", "requires target >= 1\n    ensures st = merge(key, flags, target, st)", "requires target >= 0\n    ensures st = merge(key, flags, target, st)"),
                   ("merge", "returns len(st)\n    stack 256", "returns len(st) + 1\n    stack 256"),
                   ("merge", "returns len(st)\n    stack 256", "returns len(st)\n    stack 100"),
                   ("merge", "returns len(st)\n    stack 256\n    calls blake3_servil_compress_in_place_avx512 if plat == 5", "returns len(st)\n    stack 256\n    calls blake3_servil_compress_in_place_avx512 if plat == 4"),
                   ("merge", "ensures st = merge(key, flags, target, st)", "ensures st = merge(key, flags, target + 1, st)"),
                   ("add", "ensures st = merge(key, flags, target, st ++ [new])", "ensures st = merge(key, flags, target, st)"),
                   ("add", "ensures st = merge(key, flags, target, st ++ [new])", "ensures st = merge(new, flags, target, st ++ [new])"),
                   ("add", "stack 512", "stack 300")]
        try:
            for name, old, new in changes:
                self.assertEqual(text.count(old), 1, old)
                kspec.SPEC = ode.Spec(text.replace(old, new))
                kglue.CONTRACTS, kglue.BY_SYMBOL = kglue.contracts()
                with self.assertRaises(kcheck.Fail, msg=f"{name}: {new}"):
                    kglue.find(self.rows[name], name)
        finally:
            kspec.SPEC = true
            kglue.CONTRACTS, kglue.BY_SYMBOL = kglue.contracts()

    def test_a_wrong_proof_of_merge_is_refused(self):
        def wrong(change):
            proof = copy.deepcopy(self.proofs["merge"]); change(proof["places"][0]); return proof
        for what, change in (("the place moved", lambda p: p.update(at=p["at"] + 3)),
                             ("the count's register said to hold one more", lambda p: p["registers"]["r15"]["lin"].update({"1": 1})),
                             ("the count's register not named", lambda p: p["registers"].pop("r15")),
                             ("the stack's address not named", lambda p: p["registers"].pop("rbx")),
                             ("a saved register's cell not named", lambda p: p["frame"].pop("-8")),
                             ("the flags' cell not named", lambda p: p["frame"].pop("-72"))):
            with self.assertRaises(kcheck.Fail, msg=what):
                kglue.check(self.rows["merge"], "merge", wrong(change))
        with self.assertRaises(kcheck.Fail):
            kglue.check(self.rows["merge"], "merge", dict(function="merge", places=[]))


if __name__ == "__main__":
    unittest.main()
