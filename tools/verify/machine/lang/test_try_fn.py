"""Exercise example-runner verdicts without a Lean toolchain or expensive examples."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class Verdicts(unittest.TestCase):
    def run_case(self, output='', build_exit=0, run_exit=0):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / 'try_fn.py').write_text(Path(__file__).with_name('try_fn.py').read_text())
            (root / 'odec.py').write_text("own = {}\ndef contracts_of(_): return ({'pad': {'head': [('meets', 'Pad.contract')]}}, None, None)\ndef assumed_of(*_): return []\n")
            (root / 'source.ode').write_text('test source')
            (root / 'rows').write_text('1000\t1001\t.nop\n')
            (root / 'HasherOde.lean').write_text('import Lang\nnamespace Ode\ndef all := []\nend Ode\ndef main (args : List String) : IO Unit := pure ()\n')
            lake = root / 'lake'
            lake.write_text('#!' + sys.executable + '\nimport os,sys\nfrom pathlib import Path\nif sys.argv[1] == "env":\n print("param x : BitVec 64\\naccepts True\\nreturns result | True")\nelse:\n text=Path("TryMain.lean").read_text()\n assert "def main : IO Unit" in text and "#eval" not in text\n assert "def main (args" not in text\n sys.exit(int(os.environ["BUILD_EXIT"]))\n')
            lake.chmod(0o755)
            exe = root / '.lake/build/bin/tryExamples'
            exe.parent.mkdir(parents=True)
            exe.write_text('#!' + sys.executable + '\nimport os,sys\nfrom pathlib import Path\nPath("ran").touch()\nprint(os.environ["EXAMPLE_OUTPUT"])\nsys.exit(int(os.environ["RUN_EXIT"]))\n')
            exe.chmod(0o755)
            env = {**os.environ, 'PATH': str(root) + os.pathsep + os.environ['PATH'],
                   'BUILD_EXIT': str(build_exit), 'RUN_EXIT': str(run_exit),
                   'EXAMPLE_OUTPUT': output, 'TRY_SECONDS': '10'}
            env.pop('ODEMOD', None)
            result = subprocess.run([sys.executable, 'try_fn.py', 'source.ode', 'pad', 'rows'],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=15)
            return result.returncode, result.stdout + result.stderr, (root / 'ran').exists()

    def test_meets(self):
        code, out, ran = self.run_case('example 0: meets the contract (1 instructions)')
        self.assertEqual(code, 0, out)
        self.assertTrue(ran)

    def test_refuted_after_good_example(self):
        code, out, _ = self.run_case('example 0: meets the contract (1 instructions)\nexample 1: REFUTED: wrong output')
        self.assertNotEqual(code, 0, out)

    def test_no_verdict_after_good_example(self):
        code, out, _ = self.run_case('example 0: meets the contract (1 instructions)\nexample 1: NO VERDICT: out of fuel')
        self.assertNotEqual(code, 0, out)
        self.assertIn('1 NO VERDICT', out)

    def test_no_examples(self):
        code, out, _ = self.run_case()
        self.assertNotEqual(code, 0, out)
        self.assertIn('did not run', out)

    def test_only_invalid_example(self):
        code, out, _ = self.run_case('example 0: NOT AN EXAMPLE: bad precondition')
        self.assertNotEqual(code, 0, out)

    def test_build_failure_does_not_run_stale_executable(self):
        code, out, ran = self.run_case(build_exit=1)
        self.assertNotEqual(code, 0, out)
        self.assertFalse(ran)
        self.assertIn('NO VERDICT: failed while building', out)

    def test_executable_failure_is_not_success(self):
        code, out, _ = self.run_case('example 0: meets the contract (1 instructions)', run_exit=1)
        self.assertNotEqual(code, 0, out)
        self.assertIn('NO VERDICT: failed while running', out)


if __name__ == '__main__':
    unittest.main()
