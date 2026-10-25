"""Inspect symbols and AVX-512 remainder loads in the actual benchmark executables."""
import pathlib,subprocess
root=pathlib.Path(__file__).resolve().parent
for label,exe in [('colliding',root/'native/baseline-L0'),('isolated',root/'native/private-symbols-bench')]:
    nm=subprocess.check_output(['nm','-n',str(exe)],text=True)
    (root/'native'/f'{label}-nm.txt').write_text(nm)
    rows=[line.split() for line in nm.splitlines()]
    symbols={r[2]:int(r[0],16) for r in rows if len(r)==3 and r[1]=='T'}
    for name in ['blake3_hash_many_avx512','blake3_servil_hash_many_avx512']:
        if name not in symbols:
            print(label,name,'ABSENT');continue
        start=symbols[name]
        end=min(v for v in symbols.values() if v>start)
        asm=subprocess.check_output(['objdump','-d','-Mintel','--no-show-raw-insn',f'--start-address={start}',f'--stop-address={end}',str(exe)],text=True)
        (root/'native'/f'{label}-{name}.asm').write_text(asm)
        lines=[line for line in asm.splitlines() if 'vmovups' in line and 'r8+rdx' in line]
        print(label,name,hex(start))
        print('\n'.join(lines[-12:]))
