"""Arbitrary-CV root-block entries sharing the existing stack-free round body.

(cv32, block64, length0..64, byte flags): standard compression at counter0,
ROOT added, output32. The first ABI pointer is unused and has zero readable
bytes. CV/block are read-only; ABI/stack/trace/output bounds are checked.
"""
import os
import pathlib
import subprocess
import sys
import tempfile
sys.path.insert(0,os.path.dirname(__file__))
from z3 import BitVec,BitVecVal,ULE,ZeroExt
from aarch64 import Ptr,Region,Unproved
from prove_hybrid import byte_symbols,same
from prove_x86 import Setup,d_row_facts
import lean_spec as spec
import x86
import workers
ROOT=pathlib.Path(__file__).resolve().parents[2]


def prove(source,isa):
    with tempfile.TemporaryDirectory()as directory:
        d=pathlib.Path(directory);(d/'kernel.S').write_text(source)
        subprocess.run([x86.tool('clang'),'-c','--target=x86_64-linux-gnu',str(d/'kernel.S'),'-o',str(d/'kernel.o')],check=True)
        so=x86.link(str(d/'kernel.o'))
        cv=byte_symbols('cv',32);block=byte_symbols('block',64)
        length=BitVec('length',8);flags=BitVec('flags',8)
        regions={'unused':Region('unused',0,False,None),'cv':Region('cv',32,False,lambda o:cv[o]),'block':Region('block',64,False,lambda o:block[o]),'out':Region('out',32,True,None)}
        packed=ZeroExt(56,flags)|(ZeroExt(56,length)<<8)
        # Disassemble from the old entry so the shared compression body before
        # the new entry is in the code map; execution starts at the new entry.
        setup=Setup(so,f'blake3_servil_{isa}_chunk_root',regions,[Ptr('unused',0),Ptr('cv',0),Ptr('block',0),packed,Ptr('out',0)])
        setup.entry=x86.symbols(so)[f'blake3_servil_{isa}_root_block']
        setup.m.assumptions += [ULE(length,64)]
        d_row_facts(setup.m,BitVecVal(0,64),1,[ZeroExt(24,length),ZeroExt(24,flags|8)])
        m=setup.run();out=m.regions['out']
        if set(out.bytes)!=set(range(32)):raise Unproved('output not exactly written')
        expected=spec.compress(spec.words(cv),spec.words(block),BitVecVal(0,64),ZeroExt(24,length),ZeroExt(24,flags|8))
        got=spec.words([out.bytes[i]for i in range(32)])
        for w in range(8):
            if not same(got[w],expected[w]):raise Unproved(f'{isa} word{w} differs from root compression')
        return m.steps


def one(case):
    isa,fault=case;source=(ROOT/'c/blake3_chunk_root_x86-64_unix.S').read_text()
    if fault is None:return f'{isa} root block: proved {prove(source,isa)} steps'
    start=source.index(f'\nblake3_servil_{isa}_root_block:\n')
    stop=source.find('\n.p2align 6',start+1)
    if stop<0:stop=len(source)
    stub=source[start:stop]
    if fault=='missing ROOT':old='        or eax, 8';new='        or eax, 0'
    elif fault=='forced CHUNK_END':old='        or eax, 8';new='        or eax, 10'
    elif fault=='wrong length':old='        shr r10, 8';new='        shr r10, 9'
    else:
        mnemonic='vmovups'if isa=='avx512'else'movups'
        old=f'        {mnemonic} xmm0, xmmword ptr [rsi]';new=f'        {mnemonic} xmm0, xmmword ptr [rsi+0x10]'
    assert stub.count(old)==1,(isa,fault)
    changed=source[:start]+stub.replace(old,new)+source[stop:]
    try:prove(changed,isa)
    except Unproved as error:return f'{isa} {fault}: rejected: {error}'
    raise AssertionError(f'{isa} {fault} escaped')


if __name__=='__main__':
    cases=[(isa,None)for isa in ['sse41','avx512']]+[(isa,f)for isa in ['sse41','avx512']for f in ['missing ROOT','forced CHUNK_END','wrong length','wrong CV']]
    for result in workers.each(one,cases,3):print(result,flush=True)
    print('root-block proofs and eight controls passed',flush=True)
