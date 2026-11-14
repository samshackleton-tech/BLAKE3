"""Identity checks for the K32 transcription, not a functional proof.

The production kernel is an external baseline. Macro expansion must preserve its
instruction schedule, internal alignment, unwind directives and constants: every
line of `blake3_servil_avx512_k32` of c/blake3_avx512_32.S, to its `.size`, is a
line of the source. One line differs in form only: the library's second entry,
the symbol `blake3_servil_avx512_p32`, is a label of this kernel (`@p32`).
"""
from pathlib import Path
import re
import sys
import unittest

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE.parent / 'lang'))
import odec

SOURCE = HERE / 'k32.ode'
NAMES = {'.Lode_data_k32_iv': '.Liv32', '.Lode_data_k32_indices': '.Lindices32',
         '.Lode_data_k32_schedule': '.Lschedule32', '.Lode_k32_': '.L'}


def canonical(source):
    _, data, kernels = odec.kernels(odec.contracts_of(source)[2])
    name, _, lines = next(k for k in kernels if k[0] == 'k32')
    expanded = odec.expand(name, lines, {}, {})
    assert expanded[0] == '.p2align 6'
    out = []
    for s in expanded[1:]:
        for ours, theirs in NAMES.items():
            s = s.replace(ours, theirs)
        out.append(s)
    return out, dict(data)


def production():
    asm = (ROOT / 'c/blake3_avx512_32.S').read_text()
    body = asm.split('blake3_servil_avx512_k32:\n', 1)[1].split('.size blake3_servil_avx512_k32', 1)[0]
    lines = [re.sub(r'\s+', ' ', s.strip()) for s in body.splitlines() if s.strip()]
    assert lines.count('blake3_servil_avx512_p32:') == 1
    return ['.Lp32:' if s == 'blake3_servil_avx512_p32:' else s for s in lines], asm


def longs(asm, label, end):
    text = asm.split(label + ':\n', 1)[1].split(end, 1)[0]
    return [int(x, 0) for line in text.splitlines() if line.strip().startswith('.long ') for x in line.strip()[6:].split(',')]


class K32Source(unittest.TestCase):
    def test_production_identity(self):
        expected, asm = production()
        actual, data = canonical(SOURCE.read_text())
        self.assertEqual(actual, expected)
        self.assertEqual(data['k32_iv'], longs(asm, '.Liv32', '.p2align'))
        self.assertEqual(data['k32_indices'], longs(asm, '.Lindices32', '.p2align'))
        self.assertEqual(data['k32_schedule'], longs(asm, '.Lschedule32', '.section'))
        self.assertEqual(len(data['k32_schedule']), 7 * 16)

    def test_wrong_mask_changes_identity(self):
        source = SOURCE.read_text()
        old = 'vpaddd zmm5 {k1}, zmm1, zmm4'
        self.assertEqual(source.count(old), 1)
        baseline, _ = canonical(source)
        changed, _ = canonical(source.replace(old, 'vpaddd zmm5 {k2}, zmm1, zmm4'))
        self.assertNotEqual(changed, baseline)

    def test_entry_alignment_precedes_symbols(self):
        asm = odec.kernel_x86(str(SOURCE), 'k32')
        self.assertIn('.p2align 6\nb3l_k32:\n_b3l_k32:\n', asm)
        self.assertIn('.p2align 5\n.Lode_k32_round32:', asm)
        for name in ('iv', 'indices', 'schedule'):
            self.assertIn(f'.Lode_data_k32_{name}:', asm)
        self.assertEqual(asm.count('.p2align 5'), 1)


if __name__ == '__main__':
    unittest.main()
