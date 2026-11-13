"""Identity checks for the P16 transcription, not a functional proof.

The production kernel is an external baseline. Macro expansion must preserve
its instruction schedule, internal alignment, unwind directives and constants.
"""
from pathlib import Path
import hashlib
import re
import sys
import unittest

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE.parent / 'lang'))
import odec

SOURCE = HERE / 'p16.ode'
BASELINE_SHA256 = '1ef109be28848a619d0b36911b62c332e4caaefa1f6c0e085431e585aba7cc1a'


def canonical(source):
    _, data, kernels = odec.kernels(odec.contracts_of(source)[2])
    name, _, lines = next(k for k in kernels if k[0] == 'p16')
    expanded = odec.expand(name, lines, {}, {})
    assert expanded[0] == '.p2align 6'
    return [s.replace('.Lode_data_p16_iv', '.Liv32').replace('.Lode_p16_', '.L')
            for s in expanded[1:]], dict(data)


class P16Source(unittest.TestCase):
    def test_production_identity(self):
        asm = (ROOT / 'c/blake3_avx512_32.S').read_text()
        body = asm.split('blake3_servil_avx512_p16:\n', 1)[1].split('.size blake3_servil_avx512_p16', 1)[0]
        expected = [re.sub(r'\s+', ' ', s.strip()) for s in body.splitlines() if s.strip()]
        self.assertEqual(hashlib.sha256(('\n'.join(expected)+'\n').encode()).hexdigest(), BASELINE_SHA256)
        actual, data = canonical(SOURCE.read_text())
        self.assertEqual(actual, expected)
        self.assertEqual(data['p16_iv'], [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a])

    def test_wrong_rotation_changes_identity(self):
        source = SOURCE.read_text()
        old = 'vprord $d0, $d0, 16'
        self.assertEqual(source.count(old), 1)
        baseline, _ = canonical(source)
        changed, _ = canonical(source.replace(old, 'vprord $d0, $d0, 17'))
        self.assertNotEqual(changed, baseline)

    def test_entry_alignment_precedes_symbols(self):
        asm = odec.kernel_x86(str(SOURCE), 'p16')
        self.assertIn('.p2align 6\nb3l_p16:\n_b3l_p16:\n', asm)
        self.assertIn('.p2align 5\n.Lode_p16_round16:', asm)
        self.assertIn('.Lode_data_p16_iv:', asm)
        self.assertEqual(asm.count('.p2align 5'), 1)


if __name__ == '__main__':
    unittest.main()
