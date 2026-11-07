"""Prove equal-ending 8/16-lane CV chains, full-round standard compressions.

Each lane has independent arbitrary initial CV, first/prefix/final block bytes,
final length0..64 and byte flags. Blocks1..16 is common; counter0, CHUNK_START
on the first and CHUNK_END|ROOT on the last. Params and all input regions are
read-only, including exact zero-size unused first/rest regions. Output is exact.
"""
import argparse
import os
import pathlib
import subprocess
import sys
import tempfile
sys.path.insert(0,os.path.dirname(__file__))
from z3 import BitVec, BitVecVal, ULE, ZeroExt
from aarch64 import Ptr, Region, Unproved
from prove_hybrid import byte_symbols,same
from prove_x86 import Setup,d_row_facts
import lean_spec as spec
import workers
import x86
ROOT=pathlib.Path(__file__).resolve().parents[2]


def prove(source,width,blocks):
    with tempfile.TemporaryDirectory()as directory:
        d=pathlib.Path(directory);(d/'kernel.S').write_text(source)
        subprocess.run([x86.tool('clang'),'-c','--target=x86_64-linux-gnu',str(d/'kernel.S'),'-o',str(d/'kernel.o')],check=True)
        so=x86.link(str(d/'kernel.o'))
        cvs=[byte_symbols(f'cv{i}_',32)for i in range(width)]
        lens=[BitVec(f'length_{i}',8)for i in range(width)]
        flags=[BitVec(f'flags_{i}',8)for i in range(width)]
        data={}
        size=((64*width+4+63)//64)*64
        p=Region('params',size,False,None,alignment=64)
        regions={'params':p,'out':Region('out',32*width,True,None)}
        for i in range(width):
            for name,offset,length in [('first',0,64 if blocks>1 else 0),('rest',8*width,64*max(0,blocks-2)),('last',16*width,64)]:
                key=f'{name}{i}';values=byte_symbols(key+'_',length);data[key]=values
                regions[key]=Region(key,length,False,lambda at,values=values:values[at])
                for j in range(8):p.bytes[offset+8*i+j]=(Ptr(key,0),j)
            for w in range(8):
                for j in range(4):p.bytes[24*width+4*(width*w+i)+j]=cvs[i][4*w+j]
            for base,value in [(56*width,lens[i]),(60*width,flags[i])]:
                p.bytes[base+4*i]=value
                for j in range(1,4):p.bytes[base+4*i+j]=BitVecVal(0,8)
        for j in range(4):p.bytes[64*width+j]=BitVecVal((blocks>>(8*j))&255,8)
        setup=Setup(so,f'blake3_servil_uniform{width}',regions,[Ptr('params',0),Ptr('out',0)])
        setup.m.assumptions += [ULE(length,64)for length in lens]
        facts=[BitVecVal(64,32)]
        for i in range(width):facts += [ZeroExt(24,lens[i])]+[ZeroExt(24,flags[i]|bits)for bits in [0,1,10,11]]
        d_row_facts(setup.m,BitVecVal(0,64),1,facts)
        m=setup.run();out=m.regions['out']
        if set(out.bytes)!=set(range(32*width)):raise Unproved('outputs not written exactly')
        for i in range(width):
            cv=spec.words(cvs[i])
            for b in range(blocks):
                last=b+1==blocks
                chunk=data[f'last{i}']if last else data[f'first{i}']if b==0 else data[f'rest{i}'][(b-1)*64:b*64]
                cv=spec.compress(cv,spec.words(chunk),BitVecVal(0,64),ZeroExt(24,lens[i])if last else BitVecVal(64,32),ZeroExt(24,flags[i]|(1 if b==0 else 0)|(10 if last else 0)))[:8]
            got=spec.words([out.bytes[32*i+j]for j in range(32)])
            for w in range(8):
                if not same(got[w],cv[w]):raise Unproved(f'width{width} blocks{blocks} lane{i} word{w} differs')
        return m.steps


def one(case):
    width,blocks,fault=case;source=(ROOT/'c/blake3_uniform.S').read_text()
    if fault is None:return f'uniform{width}/{blocks}: proved {prove(source,width,blocks)} steps'
    if fault=='missing ROOT':
        lines=[l for l in source.splitlines()if '.Luni_end'in l and ('vpor ymm'in l if width==8 else 'vpord zmm'in l)]
        assert len(lines)==1;old=lines[0];new=old.replace('.Luni_end','.Luni_start')
    elif fault=='wrong REST offset':
        old='        lea rdx, [rbx-64]'if width==8 else'    lea rdx, [rbx - 64]';new='    mov rdx, rbx'
    elif fault=='lost CV chain':
        old=f'.Luni{width}_block:';new=old+('\n    vpxor ymm0, ymm0, ymm0'if width==8 else'\n    vpxord zmm0, zmm0, zmm0')
    else:
        lines=[l for l in source.splitlines()if ('vmovdqu ymmword ptr [rsi+224]'in l if width==8 else'vmovdqu32 ZMMWORD PTR [r15 + 448]'in l)]
        assert len(lines)==1;old=lines[0];new='    nop'
    assert source.count(old)==1,(width,fault,old)
    try:prove(source.replace(old,new),width,blocks)
    except Unproved as error:return f'uniform{width}/{blocks} {fault}: rejected: {error}'
    raise AssertionError(fault+' escaped')


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--width',type=int,choices=[8,16]);parser.add_argument('--blocks',type=int,nargs='+',default=[1,2,16]);parser.add_argument('--controls',action='store_true');parser.add_argument('--workers',type=int,default=2)
    args=parser.parse_args();assert all(1<=b<=16 for b in args.blocks)
    widths=[args.width]if args.width else[8,16]
    cases=[(w,b,None)for w in widths for b in args.blocks]
    if args.controls:cases += [(w,3,f)for w in widths for f in ['missing ROOT','wrong REST offset','lost CV chain','missing final output']]
    for result in workers.each(one,cases,args.workers):print(result,flush=True)
    print('uniform proof cases passed',flush=True)
