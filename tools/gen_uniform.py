#!/usr/bin/env python3
"""Equal-ending first chunks: keep eight/sixteen CV chains in registers.

(params, out), Linux SysV. Uniform<W>, repr(C,align64): FIRST/REST/LAST are
W readable block pointers each (8W bytes), then8 word-major CV vectors,
LENS and FLAGS word vectors, then BLOCKS:u32. W8 offsets0/64/128/192/448/480/512,
size576; W16 offsets0/128/256/384/896/960/1024,size1088.
BLOCKS is1..16. At one block only LAST is read; otherwise FIRST64, REST
64*(BLOCKS-2), and LAST64. Final lengths0..64; flags per lane. Counter0.
CHUNK_START is ORed into the first block, CHUNK_END|ROOT into the last.
All read-only inputs are consumed before W canonical32-byte output stores.
"""
import ast
import pathlib
import gen_x86 as shared

wide_source=pathlib.Path(__file__).with_name('gen_avx512_32.py').read_text()
module=ast.parse(wide_source)
functions={'emit','transpose','output_group','g'}
constants={'IV','PERM','COLS','DIAGS','WORD'}
nodes=[n for n in module.body if isinstance(n,ast.FunctionDef)and n.name in functions or isinstance(n,ast.Assign)and any(isinstance(t,ast.Name)and t.id in constants for t in n.targets)]
assert len(nodes)==len(functions)+len(constants)
ns={};exec(compile(ast.Module(body=nodes,type_ignores=[]),'shared_avx512', 'exec'),ns)


class Uniform8(shared.Kernel):
    def pm(self,name,extra=0):
        if name in ('IV','ROT16','ROT8'):
            return self.mem('rip',f'.Luni8_{name.lower()} + {extra}')
        return super().pm(name,extra)


def header(name):
    print(f'.text\n.p2align 6\n.global {name}\n.hidden {name}\n.type {name}, @function\n{name}:\n    endbr64')


def emit8():
    name='blake3_servil_uniform8';header(name)
    k=Uniform8('avx2');k.off.update(KEY=192,LENS=448,FLAGS=480)
    e=k.e;r=k.r
    for reg in ['rbp','rbx','r12','r13','r14','r15']:e(f'push {reg}')
    e('mov rbp, rsp');e(f'sub rsp, {k.frame+64}');e('and rsp, -64')
    for w in range(8):k.load(r(w),k.pm('KEY',32*w))
    e('mov ecx, dword ptr [rdi+512]');e('shl rcx, 6');e('xor ebx, ebx')
    k.lines.append('.Luni8_block:')
    e('lea rax, [rbx+64]');e('cmp rax, rcx');e('je .Luni8_last')
    e('test rbx, rbx');e('jnz .Luni8_rest')
    e('mov rax, rdi');e('xor edx, edx');e('jmp .Luni8_load')
    k.lines.append('.Luni8_rest:');e('lea rax, [rdi+64]');e('lea rdx, [rbx-64]');e('jmp .Luni8_load')
    k.lines.append('.Luni8_last:');e('lea rax, [rdi+128]');e('xor edx, edx')
    k.lines.append('.Luni8_load:')
    for i in range(8):e(f'mov r{8+i}, qword ptr [rax+{8*i}]')
    k.transpose()
    k.load(r(8),k.pm('IV'));k.store_aligned(k.mem('rsp',k.spill),r(8))
    for i in range(1,4):k.load(r(8+i),k.pm('IV',32*i))
    e('vpxor ymm12, ymm12, ymm12');e('vpxor ymm13, ymm13, ymm13')
    e('vpbroadcastd ymm14, dword ptr [rip+.Luni64]');k.load(r(15),k.pm('FLAGS'))
    e('test rbx, rbx');e('jnz .Luni8_not_start');e('vpor ymm15, ymm15, ymmword ptr [rip+.Luni_start]')
    k.lines.append('.Luni8_not_start:');e('lea rax, [rbx+64]');e('cmp rax, rcx');e('jne .Luni8_rounds')
    k.load(r(14),k.pm('LENS'));e('vpor ymm15, ymm15, ymmword ptr [rip+.Luni_end]')
    k.lines.append('.Luni8_rounds:')
    for schedule in shared.schedule():
        for quads,base in [(shared.COLS,0),(shared.DIAGS,8)]:
            k.half(quads,[schedule[base+2*i]for i in range(4)],16,12)
            k.half(quads,[schedule[base+2*i+1]for i in range(4)],8,7)
    k.xor(r(0),r(0),k.mem('rsp',k.spill))
    for i in range(1,8):k.xor(r(i),r(i),r(i+8))
    e('add rbx, 64');e('cmp rbx, rcx');e('jb .Luni8_block')
    k.output8('rsi');e('vzeroupper');e('mov rsp, rbp')
    for reg in ['r15','r14','r13','r12','rbx','rbp']:e(f'pop {reg}')
    e('ret');print('\n'.join(k.lines));print(f'.size {name}, .-{name}')


def emit16():
    name='blake3_servil_uniform16';header(name)
    e=ns['emit'];transpose=ns['transpose'];g=ns['g']
    e('push rbp');e('mov rbp, rsp');e('push rbx');e('push r15')
    e('and rsp, -64');e('sub rsp, 256');e('mov r15, rsi')
    for w in range(8):e(f'vmovdqu32 zmm{w}, ZMMWORD PTR [rdi + {384+64*w}]')
    e('mov ecx, DWORD PTR [rdi + 1024]');e('shl rcx, 6');e('xor ebx, ebx')
    print('.Luni16_block:')
    e('lea rax, [rbx + 64]');e('cmp rax, rcx');e('je .Luni16_last')
    e('test rbx, rbx');e('jnz .Luni16_rest')
    e('mov r9, rdi');e('xor edx, edx');e('jmp .Luni16_load')
    print('.Luni16_rest:');e('lea r9, [rdi + 128]');e('lea rdx, [rbx - 64]');e('jmp .Luni16_load')
    print('.Luni16_last:');e('lea r9, [rdi + 256]');e('xor edx, edx')
    print('.Luni16_load:')
    for i in range(16):
        e(f'mov rax, QWORD PTR [r9 + {8*i}]');e(f'vmovdqu32 zmm{16+i}, ZMMWORD PTR [rax + rdx]')
    rows=transpose(list(range(16,32)),8)
    messages=[rows[ns['WORD'][w]]for w in range(16)]
    upper=[r for r in range(8,32)if r not in messages];registers=list(range(8))+upper
    assert len(upper)==8 and len(set(registers+messages))==32
    for w in range(4):e(f'vpbroadcastd zmm{registers[8+w]}, DWORD PTR [rip + .Luni16_iv + {4*w}]')
    for w in [12,13]:e(f'vpxord zmm{registers[w]}, zmm{registers[w]}, zmm{registers[w]}')
    e(f'vpbroadcastd zmm{registers[14]}, DWORD PTR [rip + .Luni64]')
    e(f'vmovdqu32 zmm{registers[15]}, ZMMWORD PTR [rdi + 960]')
    e('test rbx, rbx');e('jnz .Luni16_not_start');e(f'vpord zmm{registers[15]}, zmm{registers[15]}, ZMMWORD PTR [rip + .Luni_start]')
    print('.Luni16_not_start:');e('lea rax, [rbx + 64]');e('cmp rax, rcx');e('jne .Luni16_rounds')
    e(f'vmovdqu32 zmm{registers[14]}, ZMMWORD PTR [rdi + 896]')
    e(f'vpord zmm{registers[15]}, zmm{registers[15]}, ZMMWORD PTR [rip + .Luni_end]')
    print('.Luni16_rounds:');e('mov r11d, 7')
    perm=ns['PERM'];p2=[perm[perm[i]]for i in range(16)];cycles=[];seen=set()
    for start in range(16):
        if start in seen:continue
        cycle=[];word=start
        while word not in seen:seen.add(word);cycle.append(word);word=p2[word]
        assert word==start;cycles.append(cycle)
    assert len(cycles)==4 and all(len(c)==4 for c in cycles)
    print('.p2align 5\n.Luni16_round:')
    for schedule in [list(range(16)),perm]:
        for half,positions in enumerate([ns['COLS'],ns['DIAGS']]):
            chains=[g(*[f'zmm{registers[w]}'for w in pos],f'zmm{messages[schedule[8*half+2*i]]}',f'zmm{messages[schedule[8*half+2*i+1]]}')for i,pos in enumerate(positions)]
            for instructions in zip(*chains):
                for instruction in instructions:e(instruction)
        e('dec r11d')
        if schedule==list(range(16)):e('jz .Luni16_done')
    for i,cycle in enumerate(cycles):
        e(f'vmovdqa32 ZMMWORD PTR [rsp + {64*i}], zmm{messages[cycle[0]]}')
        for a,b in zip(cycle,cycle[1:]):e(f'vmovdqa32 zmm{messages[a]}, zmm{messages[b]}')
        e(f'vmovdqa32 zmm{messages[cycle[-1]]}, ZMMWORD PTR [rsp + {64*i}]')
    e('jmp .Luni16_round');print('.Luni16_done:')
    for w in range(8):e(f'vpxord zmm{w}, zmm{w}, zmm{registers[8+w]}')
    e('add rbx, 64');e('cmp rbx, rcx');e('jb .Luni16_block')
    ns['output_group'](0,0)
    e('vzeroupper');e('lea rsp, [rbp - 16]');e('pop r15');e('pop rbx');e('pop rbp');e('ret')
    print(f'.size {name}, .-{name}')


if __name__=='__main__':
    print('// Generated by tools/gen_uniform.py; equal-ending counter-zero chains.\n.intel_syntax noprefix')
    emit8();emit16()
    print('.section .rodata\n.p2align 6\n.Luni8_iv:')
    for word in ns['IV']:print('.long '+', '.join([hex(word)]*8))
    for name,shift in [('rot16',2),('rot8',1)]:
        print(f'.Luni8_{name}:');print('.byte '+', '.join(map(str,[4*(j//4)+(j+shift)%4 for j in range(16)]*2)))
    print('.Luni16_iv:\n.long '+', '.join(hex(word)for word in ns['IV']))
    print('.Luni64:\n.long 64\n.p2align 6\n.Luni_start:\n.long '+', '.join(['1']*16))
    print('.Luni_end:\n.long '+', '.join(['10']*16))
    print('.section .note.GNU-stack,"",@progbits')
