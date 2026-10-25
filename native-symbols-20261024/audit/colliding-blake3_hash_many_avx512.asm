
/home/samshackleton/blake3-reports/review/github-round-20261024-2254/native/baseline-L0:     file format elf64-x86-64


Disassembly of section .text:

00000000002aeb80 <_blake3_hash_many_avx512>:
  2aeb80:	endbr64
  2aeb84:	push   r15
  2aeb86:	push   r14
  2aeb88:	push   r13
  2aeb8a:	push   r12
  2aeb8c:	push   rbx
  2aeb8d:	push   rbp
  2aeb8e:	mov    rbp,rsp
  2aeb91:	sub    rsp,0x90
  2aeb98:	and    rsp,0xffffffffffffffc0
  2aeb9c:	neg    r9
  2aeb9f:	kmovw  k1,r9d
  2aeba4:	vmovd  xmm0,r8d
  2aeba9:	vpbroadcastd ymm0,xmm0
  2aebae:	shr    r8,0x20
  2aebb2:	vmovd  xmm1,r8d
  2aebb7:	vpbroadcastd ymm1,xmm1
  2aebbc:	vmovdqa ymm4,ymm1
  2aebc0:	vmovdqa ymm5,ymm1
  2aebc4:	vpaddd ymm2,ymm0,YMMWORD PTR [rip+0xffffffffffd8e774]        # 3d340 <ADD0>
  2aebcc:	vpaddd ymm3,ymm0,YMMWORD PTR [rip+0xffffffffffd8e78c]        # 3d360 <ADD0+0x20>
  2aebd4:	vpcmpltud k2,ymm2,ymm0
  2aebdb:	vpcmpltud k3,ymm3,ymm0
  2aebe2:	vpaddd ymm4{k2},ymm4,DWORD BCST [rip+0xffffffffffd8e794]        # 3d380 <ADD1>
  2aebec:	vpaddd ymm5{k3},ymm5,DWORD BCST [rip+0xffffffffffd8e78a]        # 3d380 <ADD1>
  2aebf6:	knotw  k2,k1
  2aebfa:	vmovdqa32 ymm2{k2},ymm0
  2aec00:	vmovdqa32 ymm3{k2},ymm0
  2aec06:	vmovdqa32 ymm4{k2},ymm1
  2aec0c:	vmovdqa32 ymm5{k2},ymm1
  2aec12:	vmovdqa YMMWORD PTR [rsp],ymm2
  2aec17:	vmovdqa YMMWORD PTR [rsp+0x20],ymm3
  2aec1d:	vmovdqa YMMWORD PTR [rsp+0x40],ymm4
  2aec23:	vmovdqa YMMWORD PTR [rsp+0x60],ymm5
  2aec29:	shl    rdx,0x6
  2aec2d:	mov    QWORD PTR [rsp+0x80],rdx
  2aec35:	cmp    rsi,0x10
  2aec39:	jb     2b05c0 <_blake3_hash_many_avx512+0x1a40>
  2aec3f:	vpbroadcastd zmm0,DWORD PTR [rcx]
  2aec45:	vpbroadcastd zmm1,DWORD PTR [rcx+0x4]
  2aec4c:	vpbroadcastd zmm2,DWORD PTR [rcx+0x8]
  2aec53:	vpbroadcastd zmm3,DWORD PTR [rcx+0xc]
  2aec5a:	vpbroadcastd zmm4,DWORD PTR [rcx+0x10]
  2aec61:	vpbroadcastd zmm5,DWORD PTR [rcx+0x14]
  2aec68:	vpbroadcastd zmm6,DWORD PTR [rcx+0x18]
  2aec6f:	vpbroadcastd zmm7,DWORD PTR [rcx+0x1c]
  2aec76:	movzx  eax,BYTE PTR [rbp+0x38]
  2aec7a:	movzx  ebx,BYTE PTR [rbp+0x40]
  2aec7e:	or     eax,ebx
  2aec80:	xor    edx,edx
  2aec82:	nop    DWORD PTR [rax+rax*1+0x0]
  2aec8a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2aec95:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2aeca0:	movzx  ebx,BYTE PTR [rbp+0x48]
  2aeca4:	or     ebx,eax
  2aeca6:	add    rdx,0x40
  2aecaa:	cmp    rdx,QWORD PTR [rsp+0x80]
  2aecb2:	cmove  eax,ebx
  2aecb5:	mov    DWORD PTR [rsp+0x88],eax
  2aecbc:	mov    r8,QWORD PTR [rdi]
  2aecbf:	mov    r9,QWORD PTR [rdi+0x8]
  2aecc3:	mov    r10,QWORD PTR [rdi+0x10]
  2aecc7:	mov    r11,QWORD PTR [rdi+0x18]
  2aeccb:	mov    r12,QWORD PTR [rdi+0x40]
  2aeccf:	mov    r13,QWORD PTR [rdi+0x48]
  2aecd3:	mov    r14,QWORD PTR [rdi+0x50]
  2aecd7:	mov    r15,QWORD PTR [rdi+0x58]
  2aecdb:	vmovdqu32 ymm16,YMMWORD PTR [rdx+r8*1-0x40]
  2aece3:	vinserti64x4 zmm16,zmm16,YMMWORD PTR [rdx+r12*1-0x40],0x1
  2aecec:	vmovdqu32 ymm17,YMMWORD PTR [rdx+r9*1-0x40]
  2aecf4:	vinserti64x4 zmm17,zmm17,YMMWORD PTR [rdx+r13*1-0x40],0x1
  2aecfd:	vpunpcklqdq zmm8,zmm16,zmm17
  2aed03:	vpunpckhqdq zmm9,zmm16,zmm17
  2aed09:	vmovdqu32 ymm18,YMMWORD PTR [rdx+r10*1-0x40]
  2aed11:	vinserti64x4 zmm18,zmm18,YMMWORD PTR [rdx+r14*1-0x40],0x1
  2aed1a:	vmovdqu32 ymm19,YMMWORD PTR [rdx+r11*1-0x40]
  2aed22:	vinserti64x4 zmm19,zmm19,YMMWORD PTR [rdx+r15*1-0x40],0x1
  2aed2b:	vpunpcklqdq zmm10,zmm18,zmm19
  2aed31:	vpunpckhqdq zmm11,zmm18,zmm19
  2aed37:	mov    r8,QWORD PTR [rdi+0x20]
  2aed3b:	mov    r9,QWORD PTR [rdi+0x28]
  2aed3f:	mov    r10,QWORD PTR [rdi+0x30]
  2aed43:	mov    r11,QWORD PTR [rdi+0x38]
  2aed47:	mov    r12,QWORD PTR [rdi+0x60]
  2aed4b:	mov    r13,QWORD PTR [rdi+0x68]
  2aed4f:	mov    r14,QWORD PTR [rdi+0x70]
  2aed53:	mov    r15,QWORD PTR [rdi+0x78]
  2aed57:	vmovdqu32 ymm16,YMMWORD PTR [rdx+r8*1-0x40]
  2aed5f:	vinserti64x4 zmm16,zmm16,YMMWORD PTR [rdx+r12*1-0x40],0x1
  2aed68:	vmovdqu32 ymm17,YMMWORD PTR [rdx+r9*1-0x40]
  2aed70:	vinserti64x4 zmm17,zmm17,YMMWORD PTR [rdx+r13*1-0x40],0x1
  2aed79:	vpunpcklqdq zmm12,zmm16,zmm17
  2aed7f:	vpunpckhqdq zmm13,zmm16,zmm17
  2aed85:	vmovdqu32 ymm18,YMMWORD PTR [rdx+r10*1-0x40]
  2aed8d:	vinserti64x4 zmm18,zmm18,YMMWORD PTR [rdx+r14*1-0x40],0x1
  2aed96:	vmovdqu32 ymm19,YMMWORD PTR [rdx+r11*1-0x40]
  2aed9e:	vinserti64x4 zmm19,zmm19,YMMWORD PTR [rdx+r15*1-0x40],0x1
  2aeda7:	vpunpcklqdq zmm14,zmm18,zmm19
  2aedad:	vpunpckhqdq zmm15,zmm18,zmm19
  2aedb3:	vmovdqa32 zmm27,ZMMWORD PTR [rip+0xffffffffffd8e503]        # 3d2c0 <INDEX0>
  2aedbd:	vmovdqa32 zmm31,ZMMWORD PTR [rip+0xffffffffffd8e539]        # 3d300 <INDEX1>
  2aedc7:	vshufps zmm16,zmm8,zmm10,0x88
  2aedce:	vshufps zmm17,zmm12,zmm14,0x88
  2aedd5:	vmovdqa32 zmm20,zmm16
  2aeddb:	vpermt2d zmm16,zmm27,zmm17
  2aede1:	vpermt2d zmm20,zmm31,zmm17
  2aede7:	vshufps zmm17,zmm8,zmm10,0xdd
  2aedee:	vshufps zmm30,zmm12,zmm14,0xdd
  2aedf5:	vmovdqa32 zmm21,zmm17
  2aedfb:	vpermt2d zmm17,zmm27,zmm30
  2aee01:	vpermt2d zmm21,zmm31,zmm30
  2aee07:	vshufps zmm18,zmm9,zmm11,0x88
  2aee0e:	vshufps zmm8,zmm13,zmm15,0x88
  2aee15:	vmovdqa32 zmm22,zmm18
  2aee1b:	vpermt2d zmm18,zmm27,zmm8
  2aee21:	vpermt2d zmm22,zmm31,zmm8
  2aee27:	vshufps zmm19,zmm9,zmm11,0xdd
  2aee2e:	vshufps zmm8,zmm13,zmm15,0xdd
  2aee35:	vmovdqa32 zmm23,zmm19
  2aee3b:	vpermt2d zmm19,zmm27,zmm8
  2aee41:	vpermt2d zmm23,zmm31,zmm8
  2aee47:	mov    r8,QWORD PTR [rdi]
  2aee4a:	mov    r9,QWORD PTR [rdi+0x8]
  2aee4e:	mov    r10,QWORD PTR [rdi+0x10]
  2aee52:	mov    r11,QWORD PTR [rdi+0x18]
  2aee56:	mov    r12,QWORD PTR [rdi+0x40]
  2aee5a:	mov    r13,QWORD PTR [rdi+0x48]
  2aee5e:	mov    r14,QWORD PTR [rdi+0x50]
  2aee62:	mov    r15,QWORD PTR [rdi+0x58]
  2aee66:	vmovdqu32 ymm24,YMMWORD PTR [r8+rdx*1-0x20]
  2aee6e:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r12+rdx*1-0x20],0x1
  2aee77:	vmovdqu32 ymm25,YMMWORD PTR [r9+rdx*1-0x20]
  2aee7f:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r13+rdx*1-0x20],0x1
  2aee88:	vpunpcklqdq zmm8,zmm24,zmm25
  2aee8e:	vpunpckhqdq zmm9,zmm24,zmm25
  2aee94:	vmovdqu32 ymm24,YMMWORD PTR [r10+rdx*1-0x20]
  2aee9c:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r14+rdx*1-0x20],0x1
  2aeea5:	vmovdqu32 ymm25,YMMWORD PTR [r11+rdx*1-0x20]
  2aeead:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r15+rdx*1-0x20],0x1
  2aeeb6:	vpunpcklqdq zmm10,zmm24,zmm25
  2aeebc:	vpunpckhqdq zmm11,zmm24,zmm25
  2aeec2:	prefetcht0 BYTE PTR [r8+rdx*1+0x80]
  2aeecb:	prefetcht0 BYTE PTR [r12+rdx*1+0x80]
  2aeed4:	prefetcht0 BYTE PTR [r9+rdx*1+0x80]
  2aeedd:	prefetcht0 BYTE PTR [r13+rdx*1+0x80]
  2aeee6:	prefetcht0 BYTE PTR [r10+rdx*1+0x80]
  2aeeef:	prefetcht0 BYTE PTR [r14+rdx*1+0x80]
  2aeef8:	prefetcht0 BYTE PTR [r11+rdx*1+0x80]
  2aef01:	prefetcht0 BYTE PTR [r15+rdx*1+0x80]
  2aef0a:	mov    r8,QWORD PTR [rdi+0x20]
  2aef0e:	mov    r9,QWORD PTR [rdi+0x28]
  2aef12:	mov    r10,QWORD PTR [rdi+0x30]
  2aef16:	mov    r11,QWORD PTR [rdi+0x38]
  2aef1a:	mov    r12,QWORD PTR [rdi+0x60]
  2aef1e:	mov    r13,QWORD PTR [rdi+0x68]
  2aef22:	mov    r14,QWORD PTR [rdi+0x70]
  2aef26:	mov    r15,QWORD PTR [rdi+0x78]
  2aef2a:	vmovdqu32 ymm24,YMMWORD PTR [r8+rdx*1-0x20]
  2aef32:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r12+rdx*1-0x20],0x1
  2aef3b:	vmovdqu32 ymm25,YMMWORD PTR [r9+rdx*1-0x20]
  2aef43:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r13+rdx*1-0x20],0x1
  2aef4c:	vpunpcklqdq zmm12,zmm24,zmm25
  2aef52:	vpunpckhqdq zmm13,zmm24,zmm25
  2aef58:	vmovdqu32 ymm24,YMMWORD PTR [r10+rdx*1-0x20]
  2aef60:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r14+rdx*1-0x20],0x1
  2aef69:	vmovdqu32 ymm25,YMMWORD PTR [r11+rdx*1-0x20]
  2aef71:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r15+rdx*1-0x20],0x1
  2aef7a:	vpunpcklqdq zmm14,zmm24,zmm25
  2aef80:	vpunpckhqdq zmm15,zmm24,zmm25
  2aef86:	prefetcht0 BYTE PTR [r8+rdx*1+0x80]
  2aef8f:	prefetcht0 BYTE PTR [r12+rdx*1+0x80]
  2aef98:	prefetcht0 BYTE PTR [r9+rdx*1+0x80]
  2aefa1:	prefetcht0 BYTE PTR [r13+rdx*1+0x80]
  2aefaa:	prefetcht0 BYTE PTR [r10+rdx*1+0x80]
  2aefb3:	prefetcht0 BYTE PTR [r14+rdx*1+0x80]
  2aefbc:	prefetcht0 BYTE PTR [r11+rdx*1+0x80]
  2aefc5:	prefetcht0 BYTE PTR [r15+rdx*1+0x80]
  2aefce:	vshufps zmm24,zmm8,zmm10,0x88
  2aefd5:	vshufps zmm30,zmm12,zmm14,0x88
  2aefdc:	vmovdqa32 zmm28,zmm24
  2aefe2:	vpermt2d zmm24,zmm27,zmm30
  2aefe8:	vpermt2d zmm28,zmm31,zmm30
  2aefee:	vshufps zmm25,zmm8,zmm10,0xdd
  2aeff5:	vshufps zmm30,zmm12,zmm14,0xdd
  2aeffc:	vmovdqa32 zmm29,zmm25
  2af002:	vpermt2d zmm25,zmm27,zmm30
  2af008:	vpermt2d zmm29,zmm31,zmm30
  2af00e:	vshufps zmm26,zmm9,zmm11,0x88
  2af015:	vshufps zmm8,zmm13,zmm15,0x88
  2af01c:	vmovdqa32 zmm30,zmm26
  2af022:	vpermt2d zmm26,zmm27,zmm8
  2af028:	vpermt2d zmm30,zmm31,zmm8
  2af02e:	vshufps zmm8,zmm9,zmm11,0xdd
  2af035:	vshufps zmm10,zmm13,zmm15,0xdd
  2af03c:	vpermi2d zmm27,zmm8,zmm10
  2af042:	vpermi2d zmm31,zmm8,zmm10
  2af048:	vpbroadcastd zmm8,DWORD PTR [rip+0xffffffffffd8e36e]        # 3d3c0 <BLAKE3_IV>
  2af052:	vpbroadcastd zmm9,DWORD PTR [rip+0xffffffffffd8e368]        # 3d3c4 <BLAKE3_IV_1>
  2af05c:	vpbroadcastd zmm10,DWORD PTR [rip+0xffffffffffd8e362]        # 3d3c8 <BLAKE3_IV_2>
  2af066:	vpbroadcastd zmm11,DWORD PTR [rip+0xffffffffffd8e35c]        # 3d3cc <BLAKE3_IV_3>
  2af070:	vmovdqa32 zmm12,ZMMWORD PTR [rsp]
  2af077:	vmovdqa32 zmm13,ZMMWORD PTR [rsp+0x40]
  2af07f:	vpbroadcastd zmm14,DWORD PTR [rip+0xffffffffffd8e2ff]        # 3d388 <BLAKE3_BLOCK_LEN>
  2af089:	vpbroadcastd zmm15,DWORD PTR [rsp+0x88]
  2af091:	vpaddd zmm0,zmm0,zmm16
  2af097:	vpaddd zmm1,zmm1,zmm18
  2af09d:	vpaddd zmm2,zmm2,zmm20
  2af0a3:	vpaddd zmm3,zmm3,zmm22
  2af0a9:	vpaddd zmm0,zmm0,zmm4
  2af0af:	vpaddd zmm1,zmm1,zmm5
  2af0b5:	vpaddd zmm2,zmm2,zmm6
  2af0bb:	vpaddd zmm3,zmm3,zmm7
  2af0c1:	vpxord zmm12,zmm12,zmm0
  2af0c7:	vpxord zmm13,zmm13,zmm1
  2af0cd:	vpxord zmm14,zmm14,zmm2
  2af0d3:	vpxord zmm15,zmm15,zmm3
  2af0d9:	vprord zmm12,zmm12,0x10
  2af0e0:	vprord zmm13,zmm13,0x10
  2af0e7:	vprord zmm14,zmm14,0x10
  2af0ee:	vprord zmm15,zmm15,0x10
  2af0f5:	vpaddd zmm8,zmm8,zmm12
  2af0fb:	vpaddd zmm9,zmm9,zmm13
  2af101:	vpaddd zmm10,zmm10,zmm14
  2af107:	vpaddd zmm11,zmm11,zmm15
  2af10d:	vpxord zmm4,zmm4,zmm8
  2af113:	vpxord zmm5,zmm5,zmm9
  2af119:	vpxord zmm6,zmm6,zmm10
  2af11f:	vpxord zmm7,zmm7,zmm11
  2af125:	vprord zmm4,zmm4,0xc
  2af12c:	vprord zmm5,zmm5,0xc
  2af133:	vprord zmm6,zmm6,0xc
  2af13a:	vprord zmm7,zmm7,0xc
  2af141:	vpaddd zmm0,zmm0,zmm17
  2af147:	vpaddd zmm1,zmm1,zmm19
  2af14d:	vpaddd zmm2,zmm2,zmm21
  2af153:	vpaddd zmm3,zmm3,zmm23
  2af159:	vpaddd zmm0,zmm0,zmm4
  2af15f:	vpaddd zmm1,zmm1,zmm5
  2af165:	vpaddd zmm2,zmm2,zmm6
  2af16b:	vpaddd zmm3,zmm3,zmm7
  2af171:	vpxord zmm12,zmm12,zmm0
  2af177:	vpxord zmm13,zmm13,zmm1
  2af17d:	vpxord zmm14,zmm14,zmm2
  2af183:	vpxord zmm15,zmm15,zmm3
  2af189:	vprord zmm12,zmm12,0x8
  2af190:	vprord zmm13,zmm13,0x8
  2af197:	vprord zmm14,zmm14,0x8
  2af19e:	vprord zmm15,zmm15,0x8
  2af1a5:	vpaddd zmm8,zmm8,zmm12
  2af1ab:	vpaddd zmm9,zmm9,zmm13
  2af1b1:	vpaddd zmm10,zmm10,zmm14
  2af1b7:	vpaddd zmm11,zmm11,zmm15
  2af1bd:	vpxord zmm4,zmm4,zmm8
  2af1c3:	vpxord zmm5,zmm5,zmm9
  2af1c9:	vpxord zmm6,zmm6,zmm10
  2af1cf:	vpxord zmm7,zmm7,zmm11
  2af1d5:	vprord zmm4,zmm4,0x7
  2af1dc:	vprord zmm5,zmm5,0x7
  2af1e3:	vprord zmm6,zmm6,0x7
  2af1ea:	vprord zmm7,zmm7,0x7
  2af1f1:	vpaddd zmm0,zmm0,zmm24
  2af1f7:	vpaddd zmm1,zmm1,zmm26
  2af1fd:	vpaddd zmm2,zmm2,zmm28
  2af203:	vpaddd zmm3,zmm3,zmm30
  2af209:	vpaddd zmm0,zmm0,zmm5
  2af20f:	vpaddd zmm1,zmm1,zmm6
  2af215:	vpaddd zmm2,zmm2,zmm7
  2af21b:	vpaddd zmm3,zmm3,zmm4
  2af221:	vpxord zmm15,zmm15,zmm0
  2af227:	vpxord zmm12,zmm12,zmm1
  2af22d:	vpxord zmm13,zmm13,zmm2
  2af233:	vpxord zmm14,zmm14,zmm3
  2af239:	vprord zmm15,zmm15,0x10
  2af240:	vprord zmm12,zmm12,0x10
  2af247:	vprord zmm13,zmm13,0x10
  2af24e:	vprord zmm14,zmm14,0x10
  2af255:	vpaddd zmm10,zmm10,zmm15
  2af25b:	vpaddd zmm11,zmm11,zmm12
  2af261:	vpaddd zmm8,zmm8,zmm13
  2af267:	vpaddd zmm9,zmm9,zmm14
  2af26d:	vpxord zmm5,zmm5,zmm10
  2af273:	vpxord zmm6,zmm6,zmm11
  2af279:	vpxord zmm7,zmm7,zmm8
  2af27f:	vpxord zmm4,zmm4,zmm9
  2af285:	vprord zmm5,zmm5,0xc
  2af28c:	vprord zmm6,zmm6,0xc
  2af293:	vprord zmm7,zmm7,0xc
  2af29a:	vprord zmm4,zmm4,0xc
  2af2a1:	vpaddd zmm0,zmm0,zmm25
  2af2a7:	vpaddd zmm1,zmm1,zmm27
  2af2ad:	vpaddd zmm2,zmm2,zmm29
  2af2b3:	vpaddd zmm3,zmm3,zmm31
  2af2b9:	vpaddd zmm0,zmm0,zmm5
  2af2bf:	vpaddd zmm1,zmm1,zmm6
  2af2c5:	vpaddd zmm2,zmm2,zmm7
  2af2cb:	vpaddd zmm3,zmm3,zmm4
  2af2d1:	vpxord zmm15,zmm15,zmm0
  2af2d7:	vpxord zmm12,zmm12,zmm1
  2af2dd:	vpxord zmm13,zmm13,zmm2
  2af2e3:	vpxord zmm14,zmm14,zmm3
  2af2e9:	vprord zmm15,zmm15,0x8
  2af2f0:	vprord zmm12,zmm12,0x8
  2af2f7:	vprord zmm13,zmm13,0x8
  2af2fe:	vprord zmm14,zmm14,0x8
  2af305:	vpaddd zmm10,zmm10,zmm15
  2af30b:	vpaddd zmm11,zmm11,zmm12
  2af311:	vpaddd zmm8,zmm8,zmm13
  2af317:	vpaddd zmm9,zmm9,zmm14
  2af31d:	vpxord zmm5,zmm5,zmm10
  2af323:	vpxord zmm6,zmm6,zmm11
  2af329:	vpxord zmm7,zmm7,zmm8
  2af32f:	vpxord zmm4,zmm4,zmm9
  2af335:	vprord zmm5,zmm5,0x7
  2af33c:	vprord zmm6,zmm6,0x7
  2af343:	vprord zmm7,zmm7,0x7
  2af34a:	vprord zmm4,zmm4,0x7
  2af351:	vpaddd zmm0,zmm0,zmm18
  2af357:	vpaddd zmm1,zmm1,zmm19
  2af35d:	vpaddd zmm2,zmm2,zmm23
  2af363:	vpaddd zmm3,zmm3,zmm20
  2af369:	vpaddd zmm0,zmm0,zmm4
  2af36f:	vpaddd zmm1,zmm1,zmm5
  2af375:	vpaddd zmm2,zmm2,zmm6
  2af37b:	vpaddd zmm3,zmm3,zmm7
  2af381:	vpxord zmm12,zmm12,zmm0
  2af387:	vpxord zmm13,zmm13,zmm1
  2af38d:	vpxord zmm14,zmm14,zmm2
  2af393:	vpxord zmm15,zmm15,zmm3
  2af399:	vprord zmm12,zmm12,0x10
  2af3a0:	vprord zmm13,zmm13,0x10
  2af3a7:	vprord zmm14,zmm14,0x10
  2af3ae:	vprord zmm15,zmm15,0x10
  2af3b5:	vpaddd zmm8,zmm8,zmm12
  2af3bb:	vpaddd zmm9,zmm9,zmm13
  2af3c1:	vpaddd zmm10,zmm10,zmm14
  2af3c7:	vpaddd zmm11,zmm11,zmm15
  2af3cd:	vpxord zmm4,zmm4,zmm8
  2af3d3:	vpxord zmm5,zmm5,zmm9
  2af3d9:	vpxord zmm6,zmm6,zmm10
  2af3df:	vpxord zmm7,zmm7,zmm11
  2af3e5:	vprord zmm4,zmm4,0xc
  2af3ec:	vprord zmm5,zmm5,0xc
  2af3f3:	vprord zmm6,zmm6,0xc
  2af3fa:	vprord zmm7,zmm7,0xc
  2af401:	vpaddd zmm0,zmm0,zmm22
  2af407:	vpaddd zmm1,zmm1,zmm26
  2af40d:	vpaddd zmm2,zmm2,zmm16
  2af413:	vpaddd zmm3,zmm3,zmm29
  2af419:	vpaddd zmm0,zmm0,zmm4
  2af41f:	vpaddd zmm1,zmm1,zmm5
  2af425:	vpaddd zmm2,zmm2,zmm6
  2af42b:	vpaddd zmm3,zmm3,zmm7
  2af431:	vpxord zmm12,zmm12,zmm0
  2af437:	vpxord zmm13,zmm13,zmm1
  2af43d:	vpxord zmm14,zmm14,zmm2
  2af443:	vpxord zmm15,zmm15,zmm3
  2af449:	vprord zmm12,zmm12,0x8
  2af450:	vprord zmm13,zmm13,0x8
  2af457:	vprord zmm14,zmm14,0x8
  2af45e:	vprord zmm15,zmm15,0x8
  2af465:	vpaddd zmm8,zmm8,zmm12
  2af46b:	vpaddd zmm9,zmm9,zmm13
  2af471:	vpaddd zmm10,zmm10,zmm14
  2af477:	vpaddd zmm11,zmm11,zmm15
  2af47d:	vpxord zmm4,zmm4,zmm8
  2af483:	vpxord zmm5,zmm5,zmm9
  2af489:	vpxord zmm6,zmm6,zmm10
  2af48f:	vpxord zmm7,zmm7,zmm11
  2af495:	vprord zmm4,zmm4,0x7
  2af49c:	vprord zmm5,zmm5,0x7
  2af4a3:	vprord zmm6,zmm6,0x7
  2af4aa:	vprord zmm7,zmm7,0x7
  2af4b1:	vpaddd zmm0,zmm0,zmm17
  2af4b7:	vpaddd zmm1,zmm1,zmm28
  2af4bd:	vpaddd zmm2,zmm2,zmm25
  2af4c3:	vpaddd zmm3,zmm3,zmm31
  2af4c9:	vpaddd zmm0,zmm0,zmm5
  2af4cf:	vpaddd zmm1,zmm1,zmm6
  2af4d5:	vpaddd zmm2,zmm2,zmm7
  2af4db:	vpaddd zmm3,zmm3,zmm4
  2af4e1:	vpxord zmm15,zmm15,zmm0
  2af4e7:	vpxord zmm12,zmm12,zmm1
  2af4ed:	vpxord zmm13,zmm13,zmm2
  2af4f3:	vpxord zmm14,zmm14,zmm3
  2af4f9:	vprord zmm15,zmm15,0x10
  2af500:	vprord zmm12,zmm12,0x10
  2af507:	vprord zmm13,zmm13,0x10
  2af50e:	vprord zmm14,zmm14,0x10
  2af515:	vpaddd zmm10,zmm10,zmm15
  2af51b:	vpaddd zmm11,zmm11,zmm12
  2af521:	vpaddd zmm8,zmm8,zmm13
  2af527:	vpaddd zmm9,zmm9,zmm14
  2af52d:	vpxord zmm5,zmm5,zmm10
  2af533:	vpxord zmm6,zmm6,zmm11
  2af539:	vpxord zmm7,zmm7,zmm8
  2af53f:	vpxord zmm4,zmm4,zmm9
  2af545:	vprord zmm5,zmm5,0xc
  2af54c:	vprord zmm6,zmm6,0xc
  2af553:	vprord zmm7,zmm7,0xc
  2af55a:	vprord zmm4,zmm4,0xc
  2af561:	vpaddd zmm0,zmm0,zmm27
  2af567:	vpaddd zmm1,zmm1,zmm21
  2af56d:	vpaddd zmm2,zmm2,zmm30
  2af573:	vpaddd zmm3,zmm3,zmm24
  2af579:	vpaddd zmm0,zmm0,zmm5
  2af57f:	vpaddd zmm1,zmm1,zmm6
  2af585:	vpaddd zmm2,zmm2,zmm7
  2af58b:	vpaddd zmm3,zmm3,zmm4
  2af591:	vpxord zmm15,zmm15,zmm0
  2af597:	vpxord zmm12,zmm12,zmm1
  2af59d:	vpxord zmm13,zmm13,zmm2
  2af5a3:	vpxord zmm14,zmm14,zmm3
  2af5a9:	vprord zmm15,zmm15,0x8
  2af5b0:	vprord zmm12,zmm12,0x8
  2af5b7:	vprord zmm13,zmm13,0x8
  2af5be:	vprord zmm14,zmm14,0x8
  2af5c5:	vpaddd zmm10,zmm10,zmm15
  2af5cb:	vpaddd zmm11,zmm11,zmm12
  2af5d1:	vpaddd zmm8,zmm8,zmm13
  2af5d7:	vpaddd zmm9,zmm9,zmm14
  2af5dd:	vpxord zmm5,zmm5,zmm10
  2af5e3:	vpxord zmm6,zmm6,zmm11
  2af5e9:	vpxord zmm7,zmm7,zmm8
  2af5ef:	vpxord zmm4,zmm4,zmm9
  2af5f5:	vprord zmm5,zmm5,0x7
  2af5fc:	vprord zmm6,zmm6,0x7
  2af603:	vprord zmm7,zmm7,0x7
  2af60a:	vprord zmm4,zmm4,0x7
  2af611:	vpaddd zmm0,zmm0,zmm19
  2af617:	vpaddd zmm1,zmm1,zmm26
  2af61d:	vpaddd zmm2,zmm2,zmm29
  2af623:	vpaddd zmm3,zmm3,zmm23
  2af629:	vpaddd zmm0,zmm0,zmm4
  2af62f:	vpaddd zmm1,zmm1,zmm5
  2af635:	vpaddd zmm2,zmm2,zmm6
  2af63b:	vpaddd zmm3,zmm3,zmm7
  2af641:	vpxord zmm12,zmm12,zmm0
  2af647:	vpxord zmm13,zmm13,zmm1
  2af64d:	vpxord zmm14,zmm14,zmm2
  2af653:	vpxord zmm15,zmm15,zmm3
  2af659:	vprord zmm12,zmm12,0x10
  2af660:	vprord zmm13,zmm13,0x10
  2af667:	vprord zmm14,zmm14,0x10
  2af66e:	vprord zmm15,zmm15,0x10
  2af675:	vpaddd zmm8,zmm8,zmm12
  2af67b:	vpaddd zmm9,zmm9,zmm13
  2af681:	vpaddd zmm10,zmm10,zmm14
  2af687:	vpaddd zmm11,zmm11,zmm15
  2af68d:	vpxord zmm4,zmm4,zmm8
  2af693:	vpxord zmm5,zmm5,zmm9
  2af699:	vpxord zmm6,zmm6,zmm10
  2af69f:	vpxord zmm7,zmm7,zmm11
  2af6a5:	vprord zmm4,zmm4,0xc
  2af6ac:	vprord zmm5,zmm5,0xc
  2af6b3:	vprord zmm6,zmm6,0xc
  2af6ba:	vprord zmm7,zmm7,0xc
  2af6c1:	vpaddd zmm0,zmm0,zmm20
  2af6c7:	vpaddd zmm1,zmm1,zmm28
  2af6cd:	vpaddd zmm2,zmm2,zmm18
  2af6d3:	vpaddd zmm3,zmm3,zmm30
  2af6d9:	vpaddd zmm0,zmm0,zmm4
  2af6df:	vpaddd zmm1,zmm1,zmm5
  2af6e5:	vpaddd zmm2,zmm2,zmm6
  2af6eb:	vpaddd zmm3,zmm3,zmm7
  2af6f1:	vpxord zmm12,zmm12,zmm0
  2af6f7:	vpxord zmm13,zmm13,zmm1
  2af6fd:	vpxord zmm14,zmm14,zmm2
  2af703:	vpxord zmm15,zmm15,zmm3
  2af709:	vprord zmm12,zmm12,0x8
  2af710:	vprord zmm13,zmm13,0x8
  2af717:	vprord zmm14,zmm14,0x8
  2af71e:	vprord zmm15,zmm15,0x8
  2af725:	vpaddd zmm8,zmm8,zmm12
  2af72b:	vpaddd zmm9,zmm9,zmm13
  2af731:	vpaddd zmm10,zmm10,zmm14
  2af737:	vpaddd zmm11,zmm11,zmm15
  2af73d:	vpxord zmm4,zmm4,zmm8
  2af743:	vpxord zmm5,zmm5,zmm9
  2af749:	vpxord zmm6,zmm6,zmm10
  2af74f:	vpxord zmm7,zmm7,zmm11
  2af755:	vprord zmm4,zmm4,0x7
  2af75c:	vprord zmm5,zmm5,0x7
  2af763:	vprord zmm6,zmm6,0x7
  2af76a:	vprord zmm7,zmm7,0x7
  2af771:	vpaddd zmm0,zmm0,zmm22
  2af777:	vpaddd zmm1,zmm1,zmm25
  2af77d:	vpaddd zmm2,zmm2,zmm27
  2af783:	vpaddd zmm3,zmm3,zmm24
  2af789:	vpaddd zmm0,zmm0,zmm5
  2af78f:	vpaddd zmm1,zmm1,zmm6
  2af795:	vpaddd zmm2,zmm2,zmm7
  2af79b:	vpaddd zmm3,zmm3,zmm4
  2af7a1:	vpxord zmm15,zmm15,zmm0
  2af7a7:	vpxord zmm12,zmm12,zmm1
  2af7ad:	vpxord zmm13,zmm13,zmm2
  2af7b3:	vpxord zmm14,zmm14,zmm3
  2af7b9:	vprord zmm15,zmm15,0x10
  2af7c0:	vprord zmm12,zmm12,0x10
  2af7c7:	vprord zmm13,zmm13,0x10
  2af7ce:	vprord zmm14,zmm14,0x10
  2af7d5:	vpaddd zmm10,zmm10,zmm15
  2af7db:	vpaddd zmm11,zmm11,zmm12
  2af7e1:	vpaddd zmm8,zmm8,zmm13
  2af7e7:	vpaddd zmm9,zmm9,zmm14
  2af7ed:	vpxord zmm5,zmm5,zmm10
  2af7f3:	vpxord zmm6,zmm6,zmm11
  2af7f9:	vpxord zmm7,zmm7,zmm8
  2af7ff:	vpxord zmm4,zmm4,zmm9
  2af805:	vprord zmm5,zmm5,0xc
  2af80c:	vprord zmm6,zmm6,0xc
  2af813:	vprord zmm7,zmm7,0xc
  2af81a:	vprord zmm4,zmm4,0xc
  2af821:	vpaddd zmm0,zmm0,zmm21
  2af827:	vpaddd zmm1,zmm1,zmm16
  2af82d:	vpaddd zmm2,zmm2,zmm31
  2af833:	vpaddd zmm3,zmm3,zmm17
  2af839:	vpaddd zmm0,zmm0,zmm5
  2af83f:	vpaddd zmm1,zmm1,zmm6
  2af845:	vpaddd zmm2,zmm2,zmm7
  2af84b:	vpaddd zmm3,zmm3,zmm4
  2af851:	vpxord zmm15,zmm15,zmm0
  2af857:	vpxord zmm12,zmm12,zmm1
  2af85d:	vpxord zmm13,zmm13,zmm2
  2af863:	vpxord zmm14,zmm14,zmm3
  2af869:	vprord zmm15,zmm15,0x8
  2af870:	vprord zmm12,zmm12,0x8
  2af877:	vprord zmm13,zmm13,0x8
  2af87e:	vprord zmm14,zmm14,0x8
  2af885:	vpaddd zmm10,zmm10,zmm15
  2af88b:	vpaddd zmm11,zmm11,zmm12
  2af891:	vpaddd zmm8,zmm8,zmm13
  2af897:	vpaddd zmm9,zmm9,zmm14
  2af89d:	vpxord zmm5,zmm5,zmm10
  2af8a3:	vpxord zmm6,zmm6,zmm11
  2af8a9:	vpxord zmm7,zmm7,zmm8
  2af8af:	vpxord zmm4,zmm4,zmm9
  2af8b5:	vprord zmm5,zmm5,0x7
  2af8bc:	vprord zmm6,zmm6,0x7
  2af8c3:	vprord zmm7,zmm7,0x7
  2af8ca:	vprord zmm4,zmm4,0x7
  2af8d1:	vpaddd zmm0,zmm0,zmm26
  2af8d7:	vpaddd zmm1,zmm1,zmm28
  2af8dd:	vpaddd zmm2,zmm2,zmm30
  2af8e3:	vpaddd zmm3,zmm3,zmm29
  2af8e9:	vpaddd zmm0,zmm0,zmm4
  2af8ef:	vpaddd zmm1,zmm1,zmm5
  2af8f5:	vpaddd zmm2,zmm2,zmm6
  2af8fb:	vpaddd zmm3,zmm3,zmm7
  2af901:	vpxord zmm12,zmm12,zmm0
  2af907:	vpxord zmm13,zmm13,zmm1
  2af90d:	vpxord zmm14,zmm14,zmm2
  2af913:	vpxord zmm15,zmm15,zmm3
  2af919:	vprord zmm12,zmm12,0x10
  2af920:	vprord zmm13,zmm13,0x10
  2af927:	vprord zmm14,zmm14,0x10
  2af92e:	vprord zmm15,zmm15,0x10
  2af935:	vpaddd zmm8,zmm8,zmm12
  2af93b:	vpaddd zmm9,zmm9,zmm13
  2af941:	vpaddd zmm10,zmm10,zmm14
  2af947:	vpaddd zmm11,zmm11,zmm15
  2af94d:	vpxord zmm4,zmm4,zmm8
  2af953:	vpxord zmm5,zmm5,zmm9
  2af959:	vpxord zmm6,zmm6,zmm10
  2af95f:	vpxord zmm7,zmm7,zmm11
  2af965:	vprord zmm4,zmm4,0xc
  2af96c:	vprord zmm5,zmm5,0xc
  2af973:	vprord zmm6,zmm6,0xc
  2af97a:	vprord zmm7,zmm7,0xc
  2af981:	vpaddd zmm0,zmm0,zmm23
  2af987:	vpaddd zmm1,zmm1,zmm25
  2af98d:	vpaddd zmm2,zmm2,zmm19
  2af993:	vpaddd zmm3,zmm3,zmm31
  2af999:	vpaddd zmm0,zmm0,zmm4
  2af99f:	vpaddd zmm1,zmm1,zmm5
  2af9a5:	vpaddd zmm2,zmm2,zmm6
  2af9ab:	vpaddd zmm3,zmm3,zmm7
  2af9b1:	vpxord zmm12,zmm12,zmm0
  2af9b7:	vpxord zmm13,zmm13,zmm1
  2af9bd:	vpxord zmm14,zmm14,zmm2
  2af9c3:	vpxord zmm15,zmm15,zmm3
  2af9c9:	vprord zmm12,zmm12,0x8
  2af9d0:	vprord zmm13,zmm13,0x8
  2af9d7:	vprord zmm14,zmm14,0x8
  2af9de:	vprord zmm15,zmm15,0x8
  2af9e5:	vpaddd zmm8,zmm8,zmm12
  2af9eb:	vpaddd zmm9,zmm9,zmm13
  2af9f1:	vpaddd zmm10,zmm10,zmm14
  2af9f7:	vpaddd zmm11,zmm11,zmm15
  2af9fd:	vpxord zmm4,zmm4,zmm8
  2afa03:	vpxord zmm5,zmm5,zmm9
  2afa09:	vpxord zmm6,zmm6,zmm10
  2afa0f:	vpxord zmm7,zmm7,zmm11
  2afa15:	vprord zmm4,zmm4,0x7
  2afa1c:	vprord zmm5,zmm5,0x7
  2afa23:	vprord zmm6,zmm6,0x7
  2afa2a:	vprord zmm7,zmm7,0x7
  2afa31:	vpaddd zmm0,zmm0,zmm20
  2afa37:	vpaddd zmm1,zmm1,zmm27
  2afa3d:	vpaddd zmm2,zmm2,zmm21
  2afa43:	vpaddd zmm3,zmm3,zmm17
  2afa49:	vpaddd zmm0,zmm0,zmm5
  2afa4f:	vpaddd zmm1,zmm1,zmm6
  2afa55:	vpaddd zmm2,zmm2,zmm7
  2afa5b:	vpaddd zmm3,zmm3,zmm4
  2afa61:	vpxord zmm15,zmm15,zmm0
  2afa67:	vpxord zmm12,zmm12,zmm1
  2afa6d:	vpxord zmm13,zmm13,zmm2
  2afa73:	vpxord zmm14,zmm14,zmm3
  2afa79:	vprord zmm15,zmm15,0x10
  2afa80:	vprord zmm12,zmm12,0x10
  2afa87:	vprord zmm13,zmm13,0x10
  2afa8e:	vprord zmm14,zmm14,0x10
  2afa95:	vpaddd zmm10,zmm10,zmm15
  2afa9b:	vpaddd zmm11,zmm11,zmm12
  2afaa1:	vpaddd zmm8,zmm8,zmm13
  2afaa7:	vpaddd zmm9,zmm9,zmm14
  2afaad:	vpxord zmm5,zmm5,zmm10
  2afab3:	vpxord zmm6,zmm6,zmm11
  2afab9:	vpxord zmm7,zmm7,zmm8
  2afabf:	vpxord zmm4,zmm4,zmm9
  2afac5:	vprord zmm5,zmm5,0xc
  2afacc:	vprord zmm6,zmm6,0xc
  2afad3:	vprord zmm7,zmm7,0xc
  2afada:	vprord zmm4,zmm4,0xc
  2afae1:	vpaddd zmm0,zmm0,zmm16
  2afae7:	vpaddd zmm1,zmm1,zmm18
  2afaed:	vpaddd zmm2,zmm2,zmm24
  2afaf3:	vpaddd zmm3,zmm3,zmm22
  2afaf9:	vpaddd zmm0,zmm0,zmm5
  2afaff:	vpaddd zmm1,zmm1,zmm6
  2afb05:	vpaddd zmm2,zmm2,zmm7
  2afb0b:	vpaddd zmm3,zmm3,zmm4
  2afb11:	vpxord zmm15,zmm15,zmm0
  2afb17:	vpxord zmm12,zmm12,zmm1
  2afb1d:	vpxord zmm13,zmm13,zmm2
  2afb23:	vpxord zmm14,zmm14,zmm3
  2afb29:	vprord zmm15,zmm15,0x8
  2afb30:	vprord zmm12,zmm12,0x8
  2afb37:	vprord zmm13,zmm13,0x8
  2afb3e:	vprord zmm14,zmm14,0x8
  2afb45:	vpaddd zmm10,zmm10,zmm15
  2afb4b:	vpaddd zmm11,zmm11,zmm12
  2afb51:	vpaddd zmm8,zmm8,zmm13
  2afb57:	vpaddd zmm9,zmm9,zmm14
  2afb5d:	vpxord zmm5,zmm5,zmm10
  2afb63:	vpxord zmm6,zmm6,zmm11
  2afb69:	vpxord zmm7,zmm7,zmm8
  2afb6f:	vpxord zmm4,zmm4,zmm9
  2afb75:	vprord zmm5,zmm5,0x7
  2afb7c:	vprord zmm6,zmm6,0x7
  2afb83:	vprord zmm7,zmm7,0x7
  2afb8a:	vprord zmm4,zmm4,0x7
  2afb91:	vpaddd zmm0,zmm0,zmm28
  2afb97:	vpaddd zmm1,zmm1,zmm25
  2afb9d:	vpaddd zmm2,zmm2,zmm31
  2afba3:	vpaddd zmm3,zmm3,zmm30
  2afba9:	vpaddd zmm0,zmm0,zmm4
  2afbaf:	vpaddd zmm1,zmm1,zmm5
  2afbb5:	vpaddd zmm2,zmm2,zmm6
  2afbbb:	vpaddd zmm3,zmm3,zmm7
  2afbc1:	vpxord zmm12,zmm12,zmm0
  2afbc7:	vpxord zmm13,zmm13,zmm1
  2afbcd:	vpxord zmm14,zmm14,zmm2
  2afbd3:	vpxord zmm15,zmm15,zmm3
  2afbd9:	vprord zmm12,zmm12,0x10
  2afbe0:	vprord zmm13,zmm13,0x10
  2afbe7:	vprord zmm14,zmm14,0x10
  2afbee:	vprord zmm15,zmm15,0x10
  2afbf5:	vpaddd zmm8,zmm8,zmm12
  2afbfb:	vpaddd zmm9,zmm9,zmm13
  2afc01:	vpaddd zmm10,zmm10,zmm14
  2afc07:	vpaddd zmm11,zmm11,zmm15
  2afc0d:	vpxord zmm4,zmm4,zmm8
  2afc13:	vpxord zmm5,zmm5,zmm9
  2afc19:	vpxord zmm6,zmm6,zmm10
  2afc1f:	vpxord zmm7,zmm7,zmm11
  2afc25:	vprord zmm4,zmm4,0xc
  2afc2c:	vprord zmm5,zmm5,0xc
  2afc33:	vprord zmm6,zmm6,0xc
  2afc3a:	vprord zmm7,zmm7,0xc
  2afc41:	vpaddd zmm0,zmm0,zmm29
  2afc47:	vpaddd zmm1,zmm1,zmm27
  2afc4d:	vpaddd zmm2,zmm2,zmm26
  2afc53:	vpaddd zmm3,zmm3,zmm24
  2afc59:	vpaddd zmm0,zmm0,zmm4
  2afc5f:	vpaddd zmm1,zmm1,zmm5
  2afc65:	vpaddd zmm2,zmm2,zmm6
  2afc6b:	vpaddd zmm3,zmm3,zmm7
  2afc71:	vpxord zmm12,zmm12,zmm0
  2afc77:	vpxord zmm13,zmm13,zmm1
  2afc7d:	vpxord zmm14,zmm14,zmm2
  2afc83:	vpxord zmm15,zmm15,zmm3
  2afc89:	vprord zmm12,zmm12,0x8
  2afc90:	vprord zmm13,zmm13,0x8
  2afc97:	vprord zmm14,zmm14,0x8
  2afc9e:	vprord zmm15,zmm15,0x8
  2afca5:	vpaddd zmm8,zmm8,zmm12
  2afcab:	vpaddd zmm9,zmm9,zmm13
  2afcb1:	vpaddd zmm10,zmm10,zmm14
  2afcb7:	vpaddd zmm11,zmm11,zmm15
  2afcbd:	vpxord zmm4,zmm4,zmm8
  2afcc3:	vpxord zmm5,zmm5,zmm9
  2afcc9:	vpxord zmm6,zmm6,zmm10
  2afccf:	vpxord zmm7,zmm7,zmm11
  2afcd5:	vprord zmm4,zmm4,0x7
  2afcdc:	vprord zmm5,zmm5,0x7
  2afce3:	vprord zmm6,zmm6,0x7
  2afcea:	vprord zmm7,zmm7,0x7
  2afcf1:	vpaddd zmm0,zmm0,zmm23
  2afcf7:	vpaddd zmm1,zmm1,zmm21
  2afcfd:	vpaddd zmm2,zmm2,zmm16
  2afd03:	vpaddd zmm3,zmm3,zmm22
  2afd09:	vpaddd zmm0,zmm0,zmm5
  2afd0f:	vpaddd zmm1,zmm1,zmm6
  2afd15:	vpaddd zmm2,zmm2,zmm7
  2afd1b:	vpaddd zmm3,zmm3,zmm4
  2afd21:	vpxord zmm15,zmm15,zmm0
  2afd27:	vpxord zmm12,zmm12,zmm1
  2afd2d:	vpxord zmm13,zmm13,zmm2
  2afd33:	vpxord zmm14,zmm14,zmm3
  2afd39:	vprord zmm15,zmm15,0x10
  2afd40:	vprord zmm12,zmm12,0x10
  2afd47:	vprord zmm13,zmm13,0x10
  2afd4e:	vprord zmm14,zmm14,0x10
  2afd55:	vpaddd zmm10,zmm10,zmm15
  2afd5b:	vpaddd zmm11,zmm11,zmm12
  2afd61:	vpaddd zmm8,zmm8,zmm13
  2afd67:	vpaddd zmm9,zmm9,zmm14
  2afd6d:	vpxord zmm5,zmm5,zmm10
  2afd73:	vpxord zmm6,zmm6,zmm11
  2afd79:	vpxord zmm7,zmm7,zmm8
  2afd7f:	vpxord zmm4,zmm4,zmm9
  2afd85:	vprord zmm5,zmm5,0xc
  2afd8c:	vprord zmm6,zmm6,0xc
  2afd93:	vprord zmm7,zmm7,0xc
  2afd9a:	vprord zmm4,zmm4,0xc
  2afda1:	vpaddd zmm0,zmm0,zmm18
  2afda7:	vpaddd zmm1,zmm1,zmm19
  2afdad:	vpaddd zmm2,zmm2,zmm17
  2afdb3:	vpaddd zmm3,zmm3,zmm20
  2afdb9:	vpaddd zmm0,zmm0,zmm5
  2afdbf:	vpaddd zmm1,zmm1,zmm6
  2afdc5:	vpaddd zmm2,zmm2,zmm7
  2afdcb:	vpaddd zmm3,zmm3,zmm4
  2afdd1:	vpxord zmm15,zmm15,zmm0
  2afdd7:	vpxord zmm12,zmm12,zmm1
  2afddd:	vpxord zmm13,zmm13,zmm2
  2afde3:	vpxord zmm14,zmm14,zmm3
  2afde9:	vprord zmm15,zmm15,0x8
  2afdf0:	vprord zmm12,zmm12,0x8
  2afdf7:	vprord zmm13,zmm13,0x8
  2afdfe:	vprord zmm14,zmm14,0x8
  2afe05:	vpaddd zmm10,zmm10,zmm15
  2afe0b:	vpaddd zmm11,zmm11,zmm12
  2afe11:	vpaddd zmm8,zmm8,zmm13
  2afe17:	vpaddd zmm9,zmm9,zmm14
  2afe1d:	vpxord zmm5,zmm5,zmm10
  2afe23:	vpxord zmm6,zmm6,zmm11
  2afe29:	vpxord zmm7,zmm7,zmm8
  2afe2f:	vpxord zmm4,zmm4,zmm9
  2afe35:	vprord zmm5,zmm5,0x7
  2afe3c:	vprord zmm6,zmm6,0x7
  2afe43:	vprord zmm7,zmm7,0x7
  2afe4a:	vprord zmm4,zmm4,0x7
  2afe51:	vpaddd zmm0,zmm0,zmm25
  2afe57:	vpaddd zmm1,zmm1,zmm27
  2afe5d:	vpaddd zmm2,zmm2,zmm24
  2afe63:	vpaddd zmm3,zmm3,zmm31
  2afe69:	vpaddd zmm0,zmm0,zmm4
  2afe6f:	vpaddd zmm1,zmm1,zmm5
  2afe75:	vpaddd zmm2,zmm2,zmm6
  2afe7b:	vpaddd zmm3,zmm3,zmm7
  2afe81:	vpxord zmm12,zmm12,zmm0
  2afe87:	vpxord zmm13,zmm13,zmm1
  2afe8d:	vpxord zmm14,zmm14,zmm2
  2afe93:	vpxord zmm15,zmm15,zmm3
  2afe99:	vprord zmm12,zmm12,0x10
  2afea0:	vprord zmm13,zmm13,0x10
  2afea7:	vprord zmm14,zmm14,0x10
  2afeae:	vprord zmm15,zmm15,0x10
  2afeb5:	vpaddd zmm8,zmm8,zmm12
  2afebb:	vpaddd zmm9,zmm9,zmm13
  2afec1:	vpaddd zmm10,zmm10,zmm14
  2afec7:	vpaddd zmm11,zmm11,zmm15
  2afecd:	vpxord zmm4,zmm4,zmm8
  2afed3:	vpxord zmm5,zmm5,zmm9
  2afed9:	vpxord zmm6,zmm6,zmm10
  2afedf:	vpxord zmm7,zmm7,zmm11
  2afee5:	vprord zmm4,zmm4,0xc
  2afeec:	vprord zmm5,zmm5,0xc
  2afef3:	vprord zmm6,zmm6,0xc
  2afefa:	vprord zmm7,zmm7,0xc
  2aff01:	vpaddd zmm0,zmm0,zmm30
  2aff07:	vpaddd zmm1,zmm1,zmm21
  2aff0d:	vpaddd zmm2,zmm2,zmm28
  2aff13:	vpaddd zmm3,zmm3,zmm17
  2aff19:	vpaddd zmm0,zmm0,zmm4
  2aff1f:	vpaddd zmm1,zmm1,zmm5
  2aff25:	vpaddd zmm2,zmm2,zmm6
  2aff2b:	vpaddd zmm3,zmm3,zmm7
  2aff31:	vpxord zmm12,zmm12,zmm0
  2aff37:	vpxord zmm13,zmm13,zmm1
  2aff3d:	vpxord zmm14,zmm14,zmm2
  2aff43:	vpxord zmm15,zmm15,zmm3
  2aff49:	vprord zmm12,zmm12,0x8
  2aff50:	vprord zmm13,zmm13,0x8
  2aff57:	vprord zmm14,zmm14,0x8
  2aff5e:	vprord zmm15,zmm15,0x8
  2aff65:	vpaddd zmm8,zmm8,zmm12
  2aff6b:	vpaddd zmm9,zmm9,zmm13
  2aff71:	vpaddd zmm10,zmm10,zmm14
  2aff77:	vpaddd zmm11,zmm11,zmm15
  2aff7d:	vpxord zmm4,zmm4,zmm8
  2aff83:	vpxord zmm5,zmm5,zmm9
  2aff89:	vpxord zmm6,zmm6,zmm10
  2aff8f:	vpxord zmm7,zmm7,zmm11
  2aff95:	vprord zmm4,zmm4,0x7
  2aff9c:	vprord zmm5,zmm5,0x7
  2affa3:	vprord zmm6,zmm6,0x7
  2affaa:	vprord zmm7,zmm7,0x7
  2affb1:	vpaddd zmm0,zmm0,zmm29
  2affb7:	vpaddd zmm1,zmm1,zmm16
  2affbd:	vpaddd zmm2,zmm2,zmm18
  2affc3:	vpaddd zmm3,zmm3,zmm20
  2affc9:	vpaddd zmm0,zmm0,zmm5
  2affcf:	vpaddd zmm1,zmm1,zmm6
  2affd5:	vpaddd zmm2,zmm2,zmm7
  2affdb:	vpaddd zmm3,zmm3,zmm4
  2affe1:	vpxord zmm15,zmm15,zmm0
  2affe7:	vpxord zmm12,zmm12,zmm1
  2affed:	vpxord zmm13,zmm13,zmm2
  2afff3:	vpxord zmm14,zmm14,zmm3
  2afff9:	vprord zmm15,zmm15,0x10
  2b0000:	vprord zmm12,zmm12,0x10
  2b0007:	vprord zmm13,zmm13,0x10
  2b000e:	vprord zmm14,zmm14,0x10
  2b0015:	vpaddd zmm10,zmm10,zmm15
  2b001b:	vpaddd zmm11,zmm11,zmm12
  2b0021:	vpaddd zmm8,zmm8,zmm13
  2b0027:	vpaddd zmm9,zmm9,zmm14
  2b002d:	vpxord zmm5,zmm5,zmm10
  2b0033:	vpxord zmm6,zmm6,zmm11
  2b0039:	vpxord zmm7,zmm7,zmm8
  2b003f:	vpxord zmm4,zmm4,zmm9
  2b0045:	vprord zmm5,zmm5,0xc
  2b004c:	vprord zmm6,zmm6,0xc
  2b0053:	vprord zmm7,zmm7,0xc
  2b005a:	vprord zmm4,zmm4,0xc
  2b0061:	vpaddd zmm0,zmm0,zmm19
  2b0067:	vpaddd zmm1,zmm1,zmm26
  2b006d:	vpaddd zmm2,zmm2,zmm22
  2b0073:	vpaddd zmm3,zmm3,zmm23
  2b0079:	vpaddd zmm0,zmm0,zmm5
  2b007f:	vpaddd zmm1,zmm1,zmm6
  2b0085:	vpaddd zmm2,zmm2,zmm7
  2b008b:	vpaddd zmm3,zmm3,zmm4
  2b0091:	vpxord zmm15,zmm15,zmm0
  2b0097:	vpxord zmm12,zmm12,zmm1
  2b009d:	vpxord zmm13,zmm13,zmm2
  2b00a3:	vpxord zmm14,zmm14,zmm3
  2b00a9:	vprord zmm15,zmm15,0x8
  2b00b0:	vprord zmm12,zmm12,0x8
  2b00b7:	vprord zmm13,zmm13,0x8
  2b00be:	vprord zmm14,zmm14,0x8
  2b00c5:	vpaddd zmm10,zmm10,zmm15
  2b00cb:	vpaddd zmm11,zmm11,zmm12
  2b00d1:	vpaddd zmm8,zmm8,zmm13
  2b00d7:	vpaddd zmm9,zmm9,zmm14
  2b00dd:	vpxord zmm5,zmm5,zmm10
  2b00e3:	vpxord zmm6,zmm6,zmm11
  2b00e9:	vpxord zmm7,zmm7,zmm8
  2b00ef:	vpxord zmm4,zmm4,zmm9
  2b00f5:	vprord zmm5,zmm5,0x7
  2b00fc:	vprord zmm6,zmm6,0x7
  2b0103:	vprord zmm7,zmm7,0x7
  2b010a:	vprord zmm4,zmm4,0x7
  2b0111:	vpaddd zmm0,zmm0,zmm27
  2b0117:	vpaddd zmm1,zmm1,zmm21
  2b011d:	vpaddd zmm2,zmm2,zmm17
  2b0123:	vpaddd zmm3,zmm3,zmm24
  2b0129:	vpaddd zmm0,zmm0,zmm4
  2b012f:	vpaddd zmm1,zmm1,zmm5
  2b0135:	vpaddd zmm2,zmm2,zmm6
  2b013b:	vpaddd zmm3,zmm3,zmm7
  2b0141:	vpxord zmm12,zmm12,zmm0
  2b0147:	vpxord zmm13,zmm13,zmm1
  2b014d:	vpxord zmm14,zmm14,zmm2
  2b0153:	vpxord zmm15,zmm15,zmm3
  2b0159:	vprord zmm12,zmm12,0x10
  2b0160:	vprord zmm13,zmm13,0x10
  2b0167:	vprord zmm14,zmm14,0x10
  2b016e:	vprord zmm15,zmm15,0x10
  2b0175:	vpaddd zmm8,zmm8,zmm12
  2b017b:	vpaddd zmm9,zmm9,zmm13
  2b0181:	vpaddd zmm10,zmm10,zmm14
  2b0187:	vpaddd zmm11,zmm11,zmm15
  2b018d:	vpxord zmm4,zmm4,zmm8
  2b0193:	vpxord zmm5,zmm5,zmm9
  2b0199:	vpxord zmm6,zmm6,zmm10
  2b019f:	vpxord zmm7,zmm7,zmm11
  2b01a5:	vprord zmm4,zmm4,0xc
  2b01ac:	vprord zmm5,zmm5,0xc
  2b01b3:	vprord zmm6,zmm6,0xc
  2b01ba:	vprord zmm7,zmm7,0xc
  2b01c1:	vpaddd zmm0,zmm0,zmm31
  2b01c7:	vpaddd zmm1,zmm1,zmm16
  2b01cd:	vpaddd zmm2,zmm2,zmm25
  2b01d3:	vpaddd zmm3,zmm3,zmm22
  2b01d9:	vpaddd zmm0,zmm0,zmm4
  2b01df:	vpaddd zmm1,zmm1,zmm5
  2b01e5:	vpaddd zmm2,zmm2,zmm6
  2b01eb:	vpaddd zmm3,zmm3,zmm7
  2b01f1:	vpxord zmm12,zmm12,zmm0
  2b01f7:	vpxord zmm13,zmm13,zmm1
  2b01fd:	vpxord zmm14,zmm14,zmm2
  2b0203:	vpxord zmm15,zmm15,zmm3
  2b0209:	vprord zmm12,zmm12,0x8
  2b0210:	vprord zmm13,zmm13,0x8
  2b0217:	vprord zmm14,zmm14,0x8
  2b021e:	vprord zmm15,zmm15,0x8
  2b0225:	vpaddd zmm8,zmm8,zmm12
  2b022b:	vpaddd zmm9,zmm9,zmm13
  2b0231:	vpaddd zmm10,zmm10,zmm14
  2b0237:	vpaddd zmm11,zmm11,zmm15
  2b023d:	vpxord zmm4,zmm4,zmm8
  2b0243:	vpxord zmm5,zmm5,zmm9
  2b0249:	vpxord zmm6,zmm6,zmm10
  2b024f:	vpxord zmm7,zmm7,zmm11
  2b0255:	vprord zmm4,zmm4,0x7
  2b025c:	vprord zmm5,zmm5,0x7
  2b0263:	vprord zmm6,zmm6,0x7
  2b026a:	vprord zmm7,zmm7,0x7
  2b0271:	vpaddd zmm0,zmm0,zmm30
  2b0277:	vpaddd zmm1,zmm1,zmm18
  2b027d:	vpaddd zmm2,zmm2,zmm19
  2b0283:	vpaddd zmm3,zmm3,zmm23
  2b0289:	vpaddd zmm0,zmm0,zmm5
  2b028f:	vpaddd zmm1,zmm1,zmm6
  2b0295:	vpaddd zmm2,zmm2,zmm7
  2b029b:	vpaddd zmm3,zmm3,zmm4
  2b02a1:	vpxord zmm15,zmm15,zmm0
  2b02a7:	vpxord zmm12,zmm12,zmm1
  2b02ad:	vpxord zmm13,zmm13,zmm2
  2b02b3:	vpxord zmm14,zmm14,zmm3
  2b02b9:	vprord zmm15,zmm15,0x10
  2b02c0:	vprord zmm12,zmm12,0x10
  2b02c7:	vprord zmm13,zmm13,0x10
  2b02ce:	vprord zmm14,zmm14,0x10
  2b02d5:	vpaddd zmm10,zmm10,zmm15
  2b02db:	vpaddd zmm11,zmm11,zmm12
  2b02e1:	vpaddd zmm8,zmm8,zmm13
  2b02e7:	vpaddd zmm9,zmm9,zmm14
  2b02ed:	vpxord zmm5,zmm5,zmm10
  2b02f3:	vpxord zmm6,zmm6,zmm11
  2b02f9:	vpxord zmm7,zmm7,zmm8
  2b02ff:	vpxord zmm4,zmm4,zmm9
  2b0305:	vprord zmm5,zmm5,0xc
  2b030c:	vprord zmm6,zmm6,0xc
  2b0313:	vprord zmm7,zmm7,0xc
  2b031a:	vprord zmm4,zmm4,0xc
  2b0321:	vpaddd zmm0,zmm0,zmm26
  2b0327:	vpaddd zmm1,zmm1,zmm28
  2b032d:	vpaddd zmm2,zmm2,zmm20
  2b0333:	vpaddd zmm3,zmm3,zmm29
  2b0339:	vpaddd zmm0,zmm0,zmm5
  2b033f:	vpaddd zmm1,zmm1,zmm6
  2b0345:	vpaddd zmm2,zmm2,zmm7
  2b034b:	vpaddd zmm3,zmm3,zmm4
  2b0351:	vpxord zmm15,zmm15,zmm0
  2b0357:	vpxord zmm12,zmm12,zmm1
  2b035d:	vpxord zmm13,zmm13,zmm2
  2b0363:	vpxord zmm14,zmm14,zmm3
  2b0369:	vprord zmm15,zmm15,0x8
  2b0370:	vprord zmm12,zmm12,0x8
  2b0377:	vprord zmm13,zmm13,0x8
  2b037e:	vprord zmm14,zmm14,0x8
  2b0385:	vpaddd zmm10,zmm10,zmm15
  2b038b:	vpaddd zmm11,zmm11,zmm12
  2b0391:	vpaddd zmm8,zmm8,zmm13
  2b0397:	vpaddd zmm9,zmm9,zmm14
  2b039d:	vpxord zmm5,zmm5,zmm10
  2b03a3:	vpxord zmm6,zmm6,zmm11
  2b03a9:	vpxord zmm7,zmm7,zmm8
  2b03af:	vpxord zmm4,zmm4,zmm9
  2b03b5:	vprord zmm5,zmm5,0x7
  2b03bc:	vprord zmm6,zmm6,0x7
  2b03c3:	vprord zmm7,zmm7,0x7
  2b03ca:	vprord zmm4,zmm4,0x7
  2b03d1:	vpxord zmm0,zmm0,zmm8
  2b03d7:	vpxord zmm1,zmm1,zmm9
  2b03dd:	vpxord zmm2,zmm2,zmm10
  2b03e3:	vpxord zmm3,zmm3,zmm11
  2b03e9:	vpxord zmm4,zmm4,zmm12
  2b03ef:	vpxord zmm5,zmm5,zmm13
  2b03f5:	vpxord zmm6,zmm6,zmm14
  2b03fb:	vpxord zmm7,zmm7,zmm15
  2b0401:	movzx  eax,BYTE PTR [rbp+0x38]
  2b0405:	jne    2aeca0 <_blake3_hash_many_avx512+0x120>
  2b040b:	mov    rbx,QWORD PTR [rbp+0x50]
  2b040f:	vpunpckldq zmm16,zmm0,zmm1
  2b0415:	vpunpckhdq zmm17,zmm0,zmm1
  2b041b:	vpunpckldq zmm18,zmm2,zmm3
  2b0421:	vpunpckhdq zmm19,zmm2,zmm3
  2b0427:	vpunpckldq zmm20,zmm4,zmm5
  2b042d:	vpunpckhdq zmm21,zmm4,zmm5
  2b0433:	vpunpckldq zmm22,zmm6,zmm7
  2b0439:	vpunpckhdq zmm23,zmm6,zmm7
  2b043f:	vpunpcklqdq zmm0,zmm16,zmm18
  2b0445:	vpunpckhqdq zmm1,zmm16,zmm18
  2b044b:	vpunpcklqdq zmm2,zmm17,zmm19
  2b0451:	vpunpckhqdq zmm3,zmm17,zmm19
  2b0457:	vpunpcklqdq zmm4,zmm20,zmm22
  2b045d:	vpunpckhqdq zmm5,zmm20,zmm22
  2b0463:	vpunpcklqdq zmm6,zmm21,zmm23
  2b0469:	vpunpckhqdq zmm7,zmm21,zmm23
  2b046f:	vshufi32x4 zmm16,zmm0,zmm4,0x88
  2b0476:	vshufi32x4 zmm17,zmm1,zmm5,0x88
  2b047d:	vshufi32x4 zmm18,zmm2,zmm6,0x88
  2b0484:	vshufi32x4 zmm19,zmm3,zmm7,0x88
  2b048b:	vshufi32x4 zmm20,zmm0,zmm4,0xdd
  2b0492:	vshufi32x4 zmm21,zmm1,zmm5,0xdd
  2b0499:	vshufi32x4 zmm22,zmm2,zmm6,0xdd
  2b04a0:	vshufi32x4 zmm23,zmm3,zmm7,0xdd
  2b04a7:	vshufi32x4 zmm0,zmm16,zmm17,0x88
  2b04ae:	vshufi32x4 zmm1,zmm18,zmm19,0x88
  2b04b5:	vshufi32x4 zmm2,zmm20,zmm21,0x88
  2b04bc:	vshufi32x4 zmm3,zmm22,zmm23,0x88
  2b04c3:	vshufi32x4 zmm4,zmm16,zmm17,0xdd
  2b04ca:	vshufi32x4 zmm5,zmm18,zmm19,0xdd
  2b04d1:	vshufi32x4 zmm6,zmm20,zmm21,0xdd
  2b04d8:	vshufi32x4 zmm7,zmm22,zmm23,0xdd
  2b04df:	vmovdqu32 ZMMWORD PTR [rbx],zmm0
  2b04e5:	vmovdqu32 ZMMWORD PTR [rbx+0x40],zmm1
  2b04ec:	vmovdqu32 ZMMWORD PTR [rbx+0x80],zmm2
  2b04f3:	vmovdqu32 ZMMWORD PTR [rbx+0xc0],zmm3
  2b04fa:	vmovdqu32 ZMMWORD PTR [rbx+0x100],zmm4
  2b0501:	vmovdqu32 ZMMWORD PTR [rbx+0x140],zmm5
  2b0508:	vmovdqu32 ZMMWORD PTR [rbx+0x180],zmm6
  2b050f:	vmovdqu32 ZMMWORD PTR [rbx+0x1c0],zmm7
  2b0516:	vmovdqa32 zmm0,ZMMWORD PTR [rsp]
  2b051d:	vmovdqa32 zmm1,ZMMWORD PTR [rsp+0x40]
  2b0525:	vmovdqa32 zmm2,zmm0
  2b052b:	vpaddd zmm2{k1},zmm0,DWORD BCST [rip+0xffffffffffd8ce4f]        # 3d384 <ADD16>
  2b0535:	vpcmpltud k2,zmm2,zmm0
  2b053c:	vpaddd zmm1{k2},zmm1,DWORD BCST [rip+0xffffffffffd8ce3a]        # 3d380 <ADD1>
  2b0546:	vmovdqa32 ZMMWORD PTR [rsp],zmm2
  2b054d:	vmovdqa32 ZMMWORD PTR [rsp+0x40],zmm1
  2b0555:	add    rdi,0x80
  2b055c:	add    rbx,0x200
  2b0563:	mov    QWORD PTR [rbp+0x50],rbx
  2b0567:	sub    rsi,0x10
  2b056b:	cmp    rsi,0x10
  2b056f:	jae    2aec3f <_blake3_hash_many_avx512+0xbf>
  2b0575:	test   rsi,rsi
  2b0578:	jne    2b05c0 <_blake3_hash_many_avx512+0x1a40>
  2b057a:	vzeroupper
  2b057d:	mov    rsp,rbp
  2b0580:	pop    rbp
  2b0581:	pop    rbx
  2b0582:	pop    r12
  2b0584:	pop    r13
  2b0586:	pop    r14
  2b0588:	pop    r15
  2b058a:	ret
  2b058b:	nop    WORD PTR [rax+rax*1+0x0]
  2b0594:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b059f:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b05aa:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b05b5:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b05c0:	test   esi,0x8
  2b05c6:	je     2b1b5d <_blake3_hash_many_avx512+0x2fdd>
  2b05cc:	vpbroadcastd ymm0,DWORD PTR [rcx]
  2b05d1:	vpbroadcastd ymm1,DWORD PTR [rcx+0x4]
  2b05d7:	vpbroadcastd ymm2,DWORD PTR [rcx+0x8]
  2b05dd:	vpbroadcastd ymm3,DWORD PTR [rcx+0xc]
  2b05e3:	vpbroadcastd ymm4,DWORD PTR [rcx+0x10]
  2b05e9:	vpbroadcastd ymm5,DWORD PTR [rcx+0x14]
  2b05ef:	vpbroadcastd ymm6,DWORD PTR [rcx+0x18]
  2b05f5:	vpbroadcastd ymm7,DWORD PTR [rcx+0x1c]
  2b05fb:	mov    r8,QWORD PTR [rdi]
  2b05fe:	mov    r9,QWORD PTR [rdi+0x8]
  2b0602:	mov    r10,QWORD PTR [rdi+0x10]
  2b0606:	mov    r11,QWORD PTR [rdi+0x18]
  2b060a:	mov    r12,QWORD PTR [rdi+0x20]
  2b060e:	mov    r13,QWORD PTR [rdi+0x28]
  2b0612:	mov    r14,QWORD PTR [rdi+0x30]
  2b0616:	mov    r15,QWORD PTR [rdi+0x38]
  2b061a:	movzx  eax,BYTE PTR [rbp+0x38]
  2b061e:	movzx  ebx,BYTE PTR [rbp+0x40]
  2b0622:	or     eax,ebx
  2b0624:	xor    edx,edx
  2b0626:	movzx  ebx,BYTE PTR [rbp+0x48]
  2b062a:	or     ebx,eax
  2b062c:	add    rdx,0x40
  2b0630:	cmp    rdx,QWORD PTR [rsp+0x80]
  2b0638:	cmove  eax,ebx
  2b063b:	mov    DWORD PTR [rsp+0x88],eax
  2b0642:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2b0649:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x40],0x1
  2b0651:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x40]
  2b0658:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x40],0x1
  2b0660:	vunpcklpd ymm12,ymm8,ymm9
  2b0665:	vunpckhpd ymm13,ymm8,ymm9
  2b066a:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x40]
  2b0671:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x40],0x1
  2b0679:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x40]
  2b0680:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x40],0x1
  2b0688:	vunpcklpd ymm14,ymm10,ymm11
  2b068d:	vunpckhpd ymm15,ymm10,ymm11
  2b0692:	vshufps ymm16,ymm12,ymm14,0x88
  2b0699:	vshufps ymm17,ymm12,ymm14,0xdd
  2b06a0:	vshufps ymm18,ymm13,ymm15,0x88
  2b06a7:	vshufps ymm19,ymm13,ymm15,0xdd
  2b06ae:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x30]
  2b06b5:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x30],0x1
  2b06bd:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x30]
  2b06c4:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x30],0x1
  2b06cc:	vunpcklpd ymm12,ymm8,ymm9
  2b06d1:	vunpckhpd ymm13,ymm8,ymm9
  2b06d6:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x30]
  2b06dd:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x30],0x1
  2b06e5:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x30]
  2b06ec:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x30],0x1
  2b06f4:	vunpcklpd ymm14,ymm10,ymm11
  2b06f9:	vunpckhpd ymm15,ymm10,ymm11
  2b06fe:	vshufps ymm20,ymm12,ymm14,0x88
  2b0705:	vshufps ymm21,ymm12,ymm14,0xdd
  2b070c:	vshufps ymm22,ymm13,ymm15,0x88
  2b0713:	vshufps ymm23,ymm13,ymm15,0xdd
  2b071a:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2b0721:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x20],0x1
  2b0729:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x20]
  2b0730:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x20],0x1
  2b0738:	vunpcklpd ymm12,ymm8,ymm9
  2b073d:	vunpckhpd ymm13,ymm8,ymm9
  2b0742:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x20]
  2b0749:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x20],0x1
  2b0751:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x20]
  2b0758:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x20],0x1
  2b0760:	vunpcklpd ymm14,ymm10,ymm11
  2b0765:	vunpckhpd ymm15,ymm10,ymm11
  2b076a:	vshufps ymm24,ymm12,ymm14,0x88
  2b0771:	vshufps ymm25,ymm12,ymm14,0xdd
  2b0778:	vshufps ymm26,ymm13,ymm15,0x88
  2b077f:	vshufps ymm27,ymm13,ymm15,0xdd
  2b0786:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x10]
  2b078d:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x10],0x1
  2b0795:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x10]
  2b079c:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x10],0x1
  2b07a4:	vunpcklpd ymm12,ymm8,ymm9
  2b07a9:	vunpckhpd ymm13,ymm8,ymm9
  2b07ae:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x10]
  2b07b5:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x10],0x1
  2b07bd:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x10]
  2b07c4:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x10],0x1
  2b07cc:	vunpcklpd ymm14,ymm10,ymm11
  2b07d1:	vunpckhpd ymm15,ymm10,ymm11
  2b07d6:	vshufps ymm28,ymm12,ymm14,0x88
  2b07dd:	vshufps ymm29,ymm12,ymm14,0xdd
  2b07e4:	vshufps ymm30,ymm13,ymm15,0x88
  2b07eb:	vshufps ymm31,ymm13,ymm15,0xdd
  2b07f2:	vpbroadcastd ymm8,DWORD PTR [rip+0xffffffffffd8cbc5]        # 3d3c0 <BLAKE3_IV>
  2b07fb:	vpbroadcastd ymm9,DWORD PTR [rip+0xffffffffffd8cbc0]        # 3d3c4 <BLAKE3_IV_1>
  2b0804:	vpbroadcastd ymm10,DWORD PTR [rip+0xffffffffffd8cbbb]        # 3d3c8 <BLAKE3_IV_2>
  2b080d:	vpbroadcastd ymm11,DWORD PTR [rip+0xffffffffffd8cbb6]        # 3d3cc <BLAKE3_IV_3>
  2b0816:	vmovdqa ymm12,YMMWORD PTR [rsp]
  2b081b:	vmovdqa ymm13,YMMWORD PTR [rsp+0x40]
  2b0821:	vpbroadcastd ymm14,DWORD PTR [rip+0xffffffffffd8cb5e]        # 3d388 <BLAKE3_BLOCK_LEN>
  2b082a:	vpbroadcastd ymm15,DWORD PTR [rsp+0x88]
  2b0834:	vpaddd ymm0,ymm0,ymm16
  2b083a:	vpaddd ymm1,ymm1,ymm18
  2b0840:	vpaddd ymm2,ymm2,ymm20
  2b0846:	vpaddd ymm3,ymm3,ymm22
  2b084c:	vpaddd ymm0,ymm0,ymm4
  2b0850:	vpaddd ymm1,ymm1,ymm5
  2b0854:	vpaddd ymm2,ymm2,ymm6
  2b0858:	vpaddd ymm3,ymm3,ymm7
  2b085c:	vpxord ymm12,ymm12,ymm0
  2b0862:	vpxord ymm13,ymm13,ymm1
  2b0868:	vpxord ymm14,ymm14,ymm2
  2b086e:	vpxord ymm15,ymm15,ymm3
  2b0874:	vprord ymm12,ymm12,0x10
  2b087b:	vprord ymm13,ymm13,0x10
  2b0882:	vprord ymm14,ymm14,0x10
  2b0889:	vprord ymm15,ymm15,0x10
  2b0890:	vpaddd ymm8,ymm8,ymm12
  2b0895:	vpaddd ymm9,ymm9,ymm13
  2b089a:	vpaddd ymm10,ymm10,ymm14
  2b089f:	vpaddd ymm11,ymm11,ymm15
  2b08a4:	vpxord ymm4,ymm4,ymm8
  2b08aa:	vpxord ymm5,ymm5,ymm9
  2b08b0:	vpxord ymm6,ymm6,ymm10
  2b08b6:	vpxord ymm7,ymm7,ymm11
  2b08bc:	vprord ymm4,ymm4,0xc
  2b08c3:	vprord ymm5,ymm5,0xc
  2b08ca:	vprord ymm6,ymm6,0xc
  2b08d1:	vprord ymm7,ymm7,0xc
  2b08d8:	vpaddd ymm0,ymm0,ymm17
  2b08de:	vpaddd ymm1,ymm1,ymm19
  2b08e4:	vpaddd ymm2,ymm2,ymm21
  2b08ea:	vpaddd ymm3,ymm3,ymm23
  2b08f0:	vpaddd ymm0,ymm0,ymm4
  2b08f4:	vpaddd ymm1,ymm1,ymm5
  2b08f8:	vpaddd ymm2,ymm2,ymm6
  2b08fc:	vpaddd ymm3,ymm3,ymm7
  2b0900:	vpxord ymm12,ymm12,ymm0
  2b0906:	vpxord ymm13,ymm13,ymm1
  2b090c:	vpxord ymm14,ymm14,ymm2
  2b0912:	vpxord ymm15,ymm15,ymm3
  2b0918:	vprord ymm12,ymm12,0x8
  2b091f:	vprord ymm13,ymm13,0x8
  2b0926:	vprord ymm14,ymm14,0x8
  2b092d:	vprord ymm15,ymm15,0x8
  2b0934:	vpaddd ymm8,ymm8,ymm12
  2b0939:	vpaddd ymm9,ymm9,ymm13
  2b093e:	vpaddd ymm10,ymm10,ymm14
  2b0943:	vpaddd ymm11,ymm11,ymm15
  2b0948:	vpxord ymm4,ymm4,ymm8
  2b094e:	vpxord ymm5,ymm5,ymm9
  2b0954:	vpxord ymm6,ymm6,ymm10
  2b095a:	vpxord ymm7,ymm7,ymm11
  2b0960:	vprord ymm4,ymm4,0x7
  2b0967:	vprord ymm5,ymm5,0x7
  2b096e:	vprord ymm6,ymm6,0x7
  2b0975:	vprord ymm7,ymm7,0x7
  2b097c:	vpaddd ymm0,ymm0,ymm24
  2b0982:	vpaddd ymm1,ymm1,ymm26
  2b0988:	vpaddd ymm2,ymm2,ymm28
  2b098e:	vpaddd ymm3,ymm3,ymm30
  2b0994:	vpaddd ymm0,ymm0,ymm5
  2b0998:	vpaddd ymm1,ymm1,ymm6
  2b099c:	vpaddd ymm2,ymm2,ymm7
  2b09a0:	vpaddd ymm3,ymm3,ymm4
  2b09a4:	vpxord ymm15,ymm15,ymm0
  2b09aa:	vpxord ymm12,ymm12,ymm1
  2b09b0:	vpxord ymm13,ymm13,ymm2
  2b09b6:	vpxord ymm14,ymm14,ymm3
  2b09bc:	vprord ymm15,ymm15,0x10
  2b09c3:	vprord ymm12,ymm12,0x10
  2b09ca:	vprord ymm13,ymm13,0x10
  2b09d1:	vprord ymm14,ymm14,0x10
  2b09d8:	vpaddd ymm10,ymm10,ymm15
  2b09dd:	vpaddd ymm11,ymm11,ymm12
  2b09e2:	vpaddd ymm8,ymm8,ymm13
  2b09e7:	vpaddd ymm9,ymm9,ymm14
  2b09ec:	vpxord ymm5,ymm5,ymm10
  2b09f2:	vpxord ymm6,ymm6,ymm11
  2b09f8:	vpxord ymm7,ymm7,ymm8
  2b09fe:	vpxord ymm4,ymm4,ymm9
  2b0a04:	vprord ymm5,ymm5,0xc
  2b0a0b:	vprord ymm6,ymm6,0xc
  2b0a12:	vprord ymm7,ymm7,0xc
  2b0a19:	vprord ymm4,ymm4,0xc
  2b0a20:	vpaddd ymm0,ymm0,ymm25
  2b0a26:	vpaddd ymm1,ymm1,ymm27
  2b0a2c:	vpaddd ymm2,ymm2,ymm29
  2b0a32:	vpaddd ymm3,ymm3,ymm31
  2b0a38:	vpaddd ymm0,ymm0,ymm5
  2b0a3c:	vpaddd ymm1,ymm1,ymm6
  2b0a40:	vpaddd ymm2,ymm2,ymm7
  2b0a44:	vpaddd ymm3,ymm3,ymm4
  2b0a48:	vpxord ymm15,ymm15,ymm0
  2b0a4e:	vpxord ymm12,ymm12,ymm1
  2b0a54:	vpxord ymm13,ymm13,ymm2
  2b0a5a:	vpxord ymm14,ymm14,ymm3
  2b0a60:	vprord ymm15,ymm15,0x8
  2b0a67:	vprord ymm12,ymm12,0x8
  2b0a6e:	vprord ymm13,ymm13,0x8
  2b0a75:	vprord ymm14,ymm14,0x8
  2b0a7c:	vpaddd ymm10,ymm10,ymm15
  2b0a81:	vpaddd ymm11,ymm11,ymm12
  2b0a86:	vpaddd ymm8,ymm8,ymm13
  2b0a8b:	vpaddd ymm9,ymm9,ymm14
  2b0a90:	vpxord ymm5,ymm5,ymm10
  2b0a96:	vpxord ymm6,ymm6,ymm11
  2b0a9c:	vpxord ymm7,ymm7,ymm8
  2b0aa2:	vpxord ymm4,ymm4,ymm9
  2b0aa8:	vprord ymm5,ymm5,0x7
  2b0aaf:	vprord ymm6,ymm6,0x7
  2b0ab6:	vprord ymm7,ymm7,0x7
  2b0abd:	vprord ymm4,ymm4,0x7
  2b0ac4:	vpaddd ymm0,ymm0,ymm18
  2b0aca:	vpaddd ymm1,ymm1,ymm19
  2b0ad0:	vpaddd ymm2,ymm2,ymm23
  2b0ad6:	vpaddd ymm3,ymm3,ymm20
  2b0adc:	vpaddd ymm0,ymm0,ymm4
  2b0ae0:	vpaddd ymm1,ymm1,ymm5
  2b0ae4:	vpaddd ymm2,ymm2,ymm6
  2b0ae8:	vpaddd ymm3,ymm3,ymm7
  2b0aec:	vpxord ymm12,ymm12,ymm0
  2b0af2:	vpxord ymm13,ymm13,ymm1
  2b0af8:	vpxord ymm14,ymm14,ymm2
  2b0afe:	vpxord ymm15,ymm15,ymm3
  2b0b04:	vprord ymm12,ymm12,0x10
  2b0b0b:	vprord ymm13,ymm13,0x10
  2b0b12:	vprord ymm14,ymm14,0x10
  2b0b19:	vprord ymm15,ymm15,0x10
  2b0b20:	vpaddd ymm8,ymm8,ymm12
  2b0b25:	vpaddd ymm9,ymm9,ymm13
  2b0b2a:	vpaddd ymm10,ymm10,ymm14
  2b0b2f:	vpaddd ymm11,ymm11,ymm15
  2b0b34:	vpxord ymm4,ymm4,ymm8
  2b0b3a:	vpxord ymm5,ymm5,ymm9
  2b0b40:	vpxord ymm6,ymm6,ymm10
  2b0b46:	vpxord ymm7,ymm7,ymm11
  2b0b4c:	vprord ymm4,ymm4,0xc
  2b0b53:	vprord ymm5,ymm5,0xc
  2b0b5a:	vprord ymm6,ymm6,0xc
  2b0b61:	vprord ymm7,ymm7,0xc
  2b0b68:	vpaddd ymm0,ymm0,ymm22
  2b0b6e:	vpaddd ymm1,ymm1,ymm26
  2b0b74:	vpaddd ymm2,ymm2,ymm16
  2b0b7a:	vpaddd ymm3,ymm3,ymm29
  2b0b80:	vpaddd ymm0,ymm0,ymm4
  2b0b84:	vpaddd ymm1,ymm1,ymm5
  2b0b88:	vpaddd ymm2,ymm2,ymm6
  2b0b8c:	vpaddd ymm3,ymm3,ymm7
  2b0b90:	vpxord ymm12,ymm12,ymm0
  2b0b96:	vpxord ymm13,ymm13,ymm1
  2b0b9c:	vpxord ymm14,ymm14,ymm2
  2b0ba2:	vpxord ymm15,ymm15,ymm3
  2b0ba8:	vprord ymm12,ymm12,0x8
  2b0baf:	vprord ymm13,ymm13,0x8
  2b0bb6:	vprord ymm14,ymm14,0x8
  2b0bbd:	vprord ymm15,ymm15,0x8
  2b0bc4:	vpaddd ymm8,ymm8,ymm12
  2b0bc9:	vpaddd ymm9,ymm9,ymm13
  2b0bce:	vpaddd ymm10,ymm10,ymm14
  2b0bd3:	vpaddd ymm11,ymm11,ymm15
  2b0bd8:	vpxord ymm4,ymm4,ymm8
  2b0bde:	vpxord ymm5,ymm5,ymm9
  2b0be4:	vpxord ymm6,ymm6,ymm10
  2b0bea:	vpxord ymm7,ymm7,ymm11
  2b0bf0:	vprord ymm4,ymm4,0x7
  2b0bf7:	vprord ymm5,ymm5,0x7
  2b0bfe:	vprord ymm6,ymm6,0x7
  2b0c05:	vprord ymm7,ymm7,0x7
  2b0c0c:	vpaddd ymm0,ymm0,ymm17
  2b0c12:	vpaddd ymm1,ymm1,ymm28
  2b0c18:	vpaddd ymm2,ymm2,ymm25
  2b0c1e:	vpaddd ymm3,ymm3,ymm31
  2b0c24:	vpaddd ymm0,ymm0,ymm5
  2b0c28:	vpaddd ymm1,ymm1,ymm6
  2b0c2c:	vpaddd ymm2,ymm2,ymm7
  2b0c30:	vpaddd ymm3,ymm3,ymm4
  2b0c34:	vpxord ymm15,ymm15,ymm0
  2b0c3a:	vpxord ymm12,ymm12,ymm1
  2b0c40:	vpxord ymm13,ymm13,ymm2
  2b0c46:	vpxord ymm14,ymm14,ymm3
  2b0c4c:	vprord ymm15,ymm15,0x10
  2b0c53:	vprord ymm12,ymm12,0x10
  2b0c5a:	vprord ymm13,ymm13,0x10
  2b0c61:	vprord ymm14,ymm14,0x10
  2b0c68:	vpaddd ymm10,ymm10,ymm15
  2b0c6d:	vpaddd ymm11,ymm11,ymm12
  2b0c72:	vpaddd ymm8,ymm8,ymm13
  2b0c77:	vpaddd ymm9,ymm9,ymm14
  2b0c7c:	vpxord ymm5,ymm5,ymm10
  2b0c82:	vpxord ymm6,ymm6,ymm11
  2b0c88:	vpxord ymm7,ymm7,ymm8
  2b0c8e:	vpxord ymm4,ymm4,ymm9
  2b0c94:	vprord ymm5,ymm5,0xc
  2b0c9b:	vprord ymm6,ymm6,0xc
  2b0ca2:	vprord ymm7,ymm7,0xc
  2b0ca9:	vprord ymm4,ymm4,0xc
  2b0cb0:	vpaddd ymm0,ymm0,ymm27
  2b0cb6:	vpaddd ymm1,ymm1,ymm21
  2b0cbc:	vpaddd ymm2,ymm2,ymm30
  2b0cc2:	vpaddd ymm3,ymm3,ymm24
  2b0cc8:	vpaddd ymm0,ymm0,ymm5
  2b0ccc:	vpaddd ymm1,ymm1,ymm6
  2b0cd0:	vpaddd ymm2,ymm2,ymm7
  2b0cd4:	vpaddd ymm3,ymm3,ymm4
  2b0cd8:	vpxord ymm15,ymm15,ymm0
  2b0cde:	vpxord ymm12,ymm12,ymm1
  2b0ce4:	vpxord ymm13,ymm13,ymm2
  2b0cea:	vpxord ymm14,ymm14,ymm3
  2b0cf0:	vprord ymm15,ymm15,0x8
  2b0cf7:	vprord ymm12,ymm12,0x8
  2b0cfe:	vprord ymm13,ymm13,0x8
  2b0d05:	vprord ymm14,ymm14,0x8
  2b0d0c:	vpaddd ymm10,ymm10,ymm15
  2b0d11:	vpaddd ymm11,ymm11,ymm12
  2b0d16:	vpaddd ymm8,ymm8,ymm13
  2b0d1b:	vpaddd ymm9,ymm9,ymm14
  2b0d20:	vpxord ymm5,ymm5,ymm10
  2b0d26:	vpxord ymm6,ymm6,ymm11
  2b0d2c:	vpxord ymm7,ymm7,ymm8
  2b0d32:	vpxord ymm4,ymm4,ymm9
  2b0d38:	vprord ymm5,ymm5,0x7
  2b0d3f:	vprord ymm6,ymm6,0x7
  2b0d46:	vprord ymm7,ymm7,0x7
  2b0d4d:	vprord ymm4,ymm4,0x7
  2b0d54:	vpaddd ymm0,ymm0,ymm19
  2b0d5a:	vpaddd ymm1,ymm1,ymm26
  2b0d60:	vpaddd ymm2,ymm2,ymm29
  2b0d66:	vpaddd ymm3,ymm3,ymm23
  2b0d6c:	vpaddd ymm0,ymm0,ymm4
  2b0d70:	vpaddd ymm1,ymm1,ymm5
  2b0d74:	vpaddd ymm2,ymm2,ymm6
  2b0d78:	vpaddd ymm3,ymm3,ymm7
  2b0d7c:	vpxord ymm12,ymm12,ymm0
  2b0d82:	vpxord ymm13,ymm13,ymm1
  2b0d88:	vpxord ymm14,ymm14,ymm2
  2b0d8e:	vpxord ymm15,ymm15,ymm3
  2b0d94:	vprord ymm12,ymm12,0x10
  2b0d9b:	vprord ymm13,ymm13,0x10
  2b0da2:	vprord ymm14,ymm14,0x10
  2b0da9:	vprord ymm15,ymm15,0x10
  2b0db0:	vpaddd ymm8,ymm8,ymm12
  2b0db5:	vpaddd ymm9,ymm9,ymm13
  2b0dba:	vpaddd ymm10,ymm10,ymm14
  2b0dbf:	vpaddd ymm11,ymm11,ymm15
  2b0dc4:	vpxord ymm4,ymm4,ymm8
  2b0dca:	vpxord ymm5,ymm5,ymm9
  2b0dd0:	vpxord ymm6,ymm6,ymm10
  2b0dd6:	vpxord ymm7,ymm7,ymm11
  2b0ddc:	vprord ymm4,ymm4,0xc
  2b0de3:	vprord ymm5,ymm5,0xc
  2b0dea:	vprord ymm6,ymm6,0xc
  2b0df1:	vprord ymm7,ymm7,0xc
  2b0df8:	vpaddd ymm0,ymm0,ymm20
  2b0dfe:	vpaddd ymm1,ymm1,ymm28
  2b0e04:	vpaddd ymm2,ymm2,ymm18
  2b0e0a:	vpaddd ymm3,ymm3,ymm30
  2b0e10:	vpaddd ymm0,ymm0,ymm4
  2b0e14:	vpaddd ymm1,ymm1,ymm5
  2b0e18:	vpaddd ymm2,ymm2,ymm6
  2b0e1c:	vpaddd ymm3,ymm3,ymm7
  2b0e20:	vpxord ymm12,ymm12,ymm0
  2b0e26:	vpxord ymm13,ymm13,ymm1
  2b0e2c:	vpxord ymm14,ymm14,ymm2
  2b0e32:	vpxord ymm15,ymm15,ymm3
  2b0e38:	vprord ymm12,ymm12,0x8
  2b0e3f:	vprord ymm13,ymm13,0x8
  2b0e46:	vprord ymm14,ymm14,0x8
  2b0e4d:	vprord ymm15,ymm15,0x8
  2b0e54:	vpaddd ymm8,ymm8,ymm12
  2b0e59:	vpaddd ymm9,ymm9,ymm13
  2b0e5e:	vpaddd ymm10,ymm10,ymm14
  2b0e63:	vpaddd ymm11,ymm11,ymm15
  2b0e68:	vpxord ymm4,ymm4,ymm8
  2b0e6e:	vpxord ymm5,ymm5,ymm9
  2b0e74:	vpxord ymm6,ymm6,ymm10
  2b0e7a:	vpxord ymm7,ymm7,ymm11
  2b0e80:	vprord ymm4,ymm4,0x7
  2b0e87:	vprord ymm5,ymm5,0x7
  2b0e8e:	vprord ymm6,ymm6,0x7
  2b0e95:	vprord ymm7,ymm7,0x7
  2b0e9c:	vpaddd ymm0,ymm0,ymm22
  2b0ea2:	vpaddd ymm1,ymm1,ymm25
  2b0ea8:	vpaddd ymm2,ymm2,ymm27
  2b0eae:	vpaddd ymm3,ymm3,ymm24
  2b0eb4:	vpaddd ymm0,ymm0,ymm5
  2b0eb8:	vpaddd ymm1,ymm1,ymm6
  2b0ebc:	vpaddd ymm2,ymm2,ymm7
  2b0ec0:	vpaddd ymm3,ymm3,ymm4
  2b0ec4:	vpxord ymm15,ymm15,ymm0
  2b0eca:	vpxord ymm12,ymm12,ymm1
  2b0ed0:	vpxord ymm13,ymm13,ymm2
  2b0ed6:	vpxord ymm14,ymm14,ymm3
  2b0edc:	vprord ymm15,ymm15,0x10
  2b0ee3:	vprord ymm12,ymm12,0x10
  2b0eea:	vprord ymm13,ymm13,0x10
  2b0ef1:	vprord ymm14,ymm14,0x10
  2b0ef8:	vpaddd ymm10,ymm10,ymm15
  2b0efd:	vpaddd ymm11,ymm11,ymm12
  2b0f02:	vpaddd ymm8,ymm8,ymm13
  2b0f07:	vpaddd ymm9,ymm9,ymm14
  2b0f0c:	vpxord ymm5,ymm5,ymm10
  2b0f12:	vpxord ymm6,ymm6,ymm11
  2b0f18:	vpxord ymm7,ymm7,ymm8
  2b0f1e:	vpxord ymm4,ymm4,ymm9
  2b0f24:	vprord ymm5,ymm5,0xc
  2b0f2b:	vprord ymm6,ymm6,0xc
  2b0f32:	vprord ymm7,ymm7,0xc
  2b0f39:	vprord ymm4,ymm4,0xc
  2b0f40:	vpaddd ymm0,ymm0,ymm21
  2b0f46:	vpaddd ymm1,ymm1,ymm16
  2b0f4c:	vpaddd ymm2,ymm2,ymm31
  2b0f52:	vpaddd ymm3,ymm3,ymm17
  2b0f58:	vpaddd ymm0,ymm0,ymm5
  2b0f5c:	vpaddd ymm1,ymm1,ymm6
  2b0f60:	vpaddd ymm2,ymm2,ymm7
  2b0f64:	vpaddd ymm3,ymm3,ymm4
  2b0f68:	vpxord ymm15,ymm15,ymm0
  2b0f6e:	vpxord ymm12,ymm12,ymm1
  2b0f74:	vpxord ymm13,ymm13,ymm2
  2b0f7a:	vpxord ymm14,ymm14,ymm3
  2b0f80:	vprord ymm15,ymm15,0x8
  2b0f87:	vprord ymm12,ymm12,0x8
  2b0f8e:	vprord ymm13,ymm13,0x8
  2b0f95:	vprord ymm14,ymm14,0x8
  2b0f9c:	vpaddd ymm10,ymm10,ymm15
  2b0fa1:	vpaddd ymm11,ymm11,ymm12
  2b0fa6:	vpaddd ymm8,ymm8,ymm13
  2b0fab:	vpaddd ymm9,ymm9,ymm14
  2b0fb0:	vpxord ymm5,ymm5,ymm10
  2b0fb6:	vpxord ymm6,ymm6,ymm11
  2b0fbc:	vpxord ymm7,ymm7,ymm8
  2b0fc2:	vpxord ymm4,ymm4,ymm9
  2b0fc8:	vprord ymm5,ymm5,0x7
  2b0fcf:	vprord ymm6,ymm6,0x7
  2b0fd6:	vprord ymm7,ymm7,0x7
  2b0fdd:	vprord ymm4,ymm4,0x7
  2b0fe4:	vpaddd ymm0,ymm0,ymm26
  2b0fea:	vpaddd ymm1,ymm1,ymm28
  2b0ff0:	vpaddd ymm2,ymm2,ymm30
  2b0ff6:	vpaddd ymm3,ymm3,ymm29
  2b0ffc:	vpaddd ymm0,ymm0,ymm4
  2b1000:	vpaddd ymm1,ymm1,ymm5
  2b1004:	vpaddd ymm2,ymm2,ymm6
  2b1008:	vpaddd ymm3,ymm3,ymm7
  2b100c:	vpxord ymm12,ymm12,ymm0
  2b1012:	vpxord ymm13,ymm13,ymm1
  2b1018:	vpxord ymm14,ymm14,ymm2
  2b101e:	vpxord ymm15,ymm15,ymm3
  2b1024:	vprord ymm12,ymm12,0x10
  2b102b:	vprord ymm13,ymm13,0x10
  2b1032:	vprord ymm14,ymm14,0x10
  2b1039:	vprord ymm15,ymm15,0x10
  2b1040:	vpaddd ymm8,ymm8,ymm12
  2b1045:	vpaddd ymm9,ymm9,ymm13
  2b104a:	vpaddd ymm10,ymm10,ymm14
  2b104f:	vpaddd ymm11,ymm11,ymm15
  2b1054:	vpxord ymm4,ymm4,ymm8
  2b105a:	vpxord ymm5,ymm5,ymm9
  2b1060:	vpxord ymm6,ymm6,ymm10
  2b1066:	vpxord ymm7,ymm7,ymm11
  2b106c:	vprord ymm4,ymm4,0xc
  2b1073:	vprord ymm5,ymm5,0xc
  2b107a:	vprord ymm6,ymm6,0xc
  2b1081:	vprord ymm7,ymm7,0xc
  2b1088:	vpaddd ymm0,ymm0,ymm23
  2b108e:	vpaddd ymm1,ymm1,ymm25
  2b1094:	vpaddd ymm2,ymm2,ymm19
  2b109a:	vpaddd ymm3,ymm3,ymm31
  2b10a0:	vpaddd ymm0,ymm0,ymm4
  2b10a4:	vpaddd ymm1,ymm1,ymm5
  2b10a8:	vpaddd ymm2,ymm2,ymm6
  2b10ac:	vpaddd ymm3,ymm3,ymm7
  2b10b0:	vpxord ymm12,ymm12,ymm0
  2b10b6:	vpxord ymm13,ymm13,ymm1
  2b10bc:	vpxord ymm14,ymm14,ymm2
  2b10c2:	vpxord ymm15,ymm15,ymm3
  2b10c8:	vprord ymm12,ymm12,0x8
  2b10cf:	vprord ymm13,ymm13,0x8
  2b10d6:	vprord ymm14,ymm14,0x8
  2b10dd:	vprord ymm15,ymm15,0x8
  2b10e4:	vpaddd ymm8,ymm8,ymm12
  2b10e9:	vpaddd ymm9,ymm9,ymm13
  2b10ee:	vpaddd ymm10,ymm10,ymm14
  2b10f3:	vpaddd ymm11,ymm11,ymm15
  2b10f8:	vpxord ymm4,ymm4,ymm8
  2b10fe:	vpxord ymm5,ymm5,ymm9
  2b1104:	vpxord ymm6,ymm6,ymm10
  2b110a:	vpxord ymm7,ymm7,ymm11
  2b1110:	vprord ymm4,ymm4,0x7
  2b1117:	vprord ymm5,ymm5,0x7
  2b111e:	vprord ymm6,ymm6,0x7
  2b1125:	vprord ymm7,ymm7,0x7
  2b112c:	vpaddd ymm0,ymm0,ymm20
  2b1132:	vpaddd ymm1,ymm1,ymm27
  2b1138:	vpaddd ymm2,ymm2,ymm21
  2b113e:	vpaddd ymm3,ymm3,ymm17
  2b1144:	vpaddd ymm0,ymm0,ymm5
  2b1148:	vpaddd ymm1,ymm1,ymm6
  2b114c:	vpaddd ymm2,ymm2,ymm7
  2b1150:	vpaddd ymm3,ymm3,ymm4
  2b1154:	vpxord ymm15,ymm15,ymm0
  2b115a:	vpxord ymm12,ymm12,ymm1
  2b1160:	vpxord ymm13,ymm13,ymm2
  2b1166:	vpxord ymm14,ymm14,ymm3
  2b116c:	vprord ymm15,ymm15,0x10
  2b1173:	vprord ymm12,ymm12,0x10
  2b117a:	vprord ymm13,ymm13,0x10
  2b1181:	vprord ymm14,ymm14,0x10
  2b1188:	vpaddd ymm10,ymm10,ymm15
  2b118d:	vpaddd ymm11,ymm11,ymm12
  2b1192:	vpaddd ymm8,ymm8,ymm13
  2b1197:	vpaddd ymm9,ymm9,ymm14
  2b119c:	vpxord ymm5,ymm5,ymm10
  2b11a2:	vpxord ymm6,ymm6,ymm11
  2b11a8:	vpxord ymm7,ymm7,ymm8
  2b11ae:	vpxord ymm4,ymm4,ymm9
  2b11b4:	vprord ymm5,ymm5,0xc
  2b11bb:	vprord ymm6,ymm6,0xc
  2b11c2:	vprord ymm7,ymm7,0xc
  2b11c9:	vprord ymm4,ymm4,0xc
  2b11d0:	vpaddd ymm0,ymm0,ymm16
  2b11d6:	vpaddd ymm1,ymm1,ymm18
  2b11dc:	vpaddd ymm2,ymm2,ymm24
  2b11e2:	vpaddd ymm3,ymm3,ymm22
  2b11e8:	vpaddd ymm0,ymm0,ymm5
  2b11ec:	vpaddd ymm1,ymm1,ymm6
  2b11f0:	vpaddd ymm2,ymm2,ymm7
  2b11f4:	vpaddd ymm3,ymm3,ymm4
  2b11f8:	vpxord ymm15,ymm15,ymm0
  2b11fe:	vpxord ymm12,ymm12,ymm1
  2b1204:	vpxord ymm13,ymm13,ymm2
  2b120a:	vpxord ymm14,ymm14,ymm3
  2b1210:	vprord ymm15,ymm15,0x8
  2b1217:	vprord ymm12,ymm12,0x8
  2b121e:	vprord ymm13,ymm13,0x8
  2b1225:	vprord ymm14,ymm14,0x8
  2b122c:	vpaddd ymm10,ymm10,ymm15
  2b1231:	vpaddd ymm11,ymm11,ymm12
  2b1236:	vpaddd ymm8,ymm8,ymm13
  2b123b:	vpaddd ymm9,ymm9,ymm14
  2b1240:	vpxord ymm5,ymm5,ymm10
  2b1246:	vpxord ymm6,ymm6,ymm11
  2b124c:	vpxord ymm7,ymm7,ymm8
  2b1252:	vpxord ymm4,ymm4,ymm9
  2b1258:	vprord ymm5,ymm5,0x7
  2b125f:	vprord ymm6,ymm6,0x7
  2b1266:	vprord ymm7,ymm7,0x7
  2b126d:	vprord ymm4,ymm4,0x7
  2b1274:	vpaddd ymm0,ymm0,ymm28
  2b127a:	vpaddd ymm1,ymm1,ymm25
  2b1280:	vpaddd ymm2,ymm2,ymm31
  2b1286:	vpaddd ymm3,ymm3,ymm30
  2b128c:	vpaddd ymm0,ymm0,ymm4
  2b1290:	vpaddd ymm1,ymm1,ymm5
  2b1294:	vpaddd ymm2,ymm2,ymm6
  2b1298:	vpaddd ymm3,ymm3,ymm7
  2b129c:	vpxord ymm12,ymm12,ymm0
  2b12a2:	vpxord ymm13,ymm13,ymm1
  2b12a8:	vpxord ymm14,ymm14,ymm2
  2b12ae:	vpxord ymm15,ymm15,ymm3
  2b12b4:	vprord ymm12,ymm12,0x10
  2b12bb:	vprord ymm13,ymm13,0x10
  2b12c2:	vprord ymm14,ymm14,0x10
  2b12c9:	vprord ymm15,ymm15,0x10
  2b12d0:	vpaddd ymm8,ymm8,ymm12
  2b12d5:	vpaddd ymm9,ymm9,ymm13
  2b12da:	vpaddd ymm10,ymm10,ymm14
  2b12df:	vpaddd ymm11,ymm11,ymm15
  2b12e4:	vpxord ymm4,ymm4,ymm8
  2b12ea:	vpxord ymm5,ymm5,ymm9
  2b12f0:	vpxord ymm6,ymm6,ymm10
  2b12f6:	vpxord ymm7,ymm7,ymm11
  2b12fc:	vprord ymm4,ymm4,0xc
  2b1303:	vprord ymm5,ymm5,0xc
  2b130a:	vprord ymm6,ymm6,0xc
  2b1311:	vprord ymm7,ymm7,0xc
  2b1318:	vpaddd ymm0,ymm0,ymm29
  2b131e:	vpaddd ymm1,ymm1,ymm27
  2b1324:	vpaddd ymm2,ymm2,ymm26
  2b132a:	vpaddd ymm3,ymm3,ymm24
  2b1330:	vpaddd ymm0,ymm0,ymm4
  2b1334:	vpaddd ymm1,ymm1,ymm5
  2b1338:	vpaddd ymm2,ymm2,ymm6
  2b133c:	vpaddd ymm3,ymm3,ymm7
  2b1340:	vpxord ymm12,ymm12,ymm0
  2b1346:	vpxord ymm13,ymm13,ymm1
  2b134c:	vpxord ymm14,ymm14,ymm2
  2b1352:	vpxord ymm15,ymm15,ymm3
  2b1358:	vprord ymm12,ymm12,0x8
  2b135f:	vprord ymm13,ymm13,0x8
  2b1366:	vprord ymm14,ymm14,0x8
  2b136d:	vprord ymm15,ymm15,0x8
  2b1374:	vpaddd ymm8,ymm8,ymm12
  2b1379:	vpaddd ymm9,ymm9,ymm13
  2b137e:	vpaddd ymm10,ymm10,ymm14
  2b1383:	vpaddd ymm11,ymm11,ymm15
  2b1388:	vpxord ymm4,ymm4,ymm8
  2b138e:	vpxord ymm5,ymm5,ymm9
  2b1394:	vpxord ymm6,ymm6,ymm10
  2b139a:	vpxord ymm7,ymm7,ymm11
  2b13a0:	vprord ymm4,ymm4,0x7
  2b13a7:	vprord ymm5,ymm5,0x7
  2b13ae:	vprord ymm6,ymm6,0x7
  2b13b5:	vprord ymm7,ymm7,0x7
  2b13bc:	vpaddd ymm0,ymm0,ymm23
  2b13c2:	vpaddd ymm1,ymm1,ymm21
  2b13c8:	vpaddd ymm2,ymm2,ymm16
  2b13ce:	vpaddd ymm3,ymm3,ymm22
  2b13d4:	vpaddd ymm0,ymm0,ymm5
  2b13d8:	vpaddd ymm1,ymm1,ymm6
  2b13dc:	vpaddd ymm2,ymm2,ymm7
  2b13e0:	vpaddd ymm3,ymm3,ymm4
  2b13e4:	vpxord ymm15,ymm15,ymm0
  2b13ea:	vpxord ymm12,ymm12,ymm1
  2b13f0:	vpxord ymm13,ymm13,ymm2
  2b13f6:	vpxord ymm14,ymm14,ymm3
  2b13fc:	vprord ymm15,ymm15,0x10
  2b1403:	vprord ymm12,ymm12,0x10
  2b140a:	vprord ymm13,ymm13,0x10
  2b1411:	vprord ymm14,ymm14,0x10
  2b1418:	vpaddd ymm10,ymm10,ymm15
  2b141d:	vpaddd ymm11,ymm11,ymm12
  2b1422:	vpaddd ymm8,ymm8,ymm13
  2b1427:	vpaddd ymm9,ymm9,ymm14
  2b142c:	vpxord ymm5,ymm5,ymm10
  2b1432:	vpxord ymm6,ymm6,ymm11
  2b1438:	vpxord ymm7,ymm7,ymm8
  2b143e:	vpxord ymm4,ymm4,ymm9
  2b1444:	vprord ymm5,ymm5,0xc
  2b144b:	vprord ymm6,ymm6,0xc
  2b1452:	vprord ymm7,ymm7,0xc
  2b1459:	vprord ymm4,ymm4,0xc
  2b1460:	vpaddd ymm0,ymm0,ymm18
  2b1466:	vpaddd ymm1,ymm1,ymm19
  2b146c:	vpaddd ymm2,ymm2,ymm17
  2b1472:	vpaddd ymm3,ymm3,ymm20
  2b1478:	vpaddd ymm0,ymm0,ymm5
  2b147c:	vpaddd ymm1,ymm1,ymm6
  2b1480:	vpaddd ymm2,ymm2,ymm7
  2b1484:	vpaddd ymm3,ymm3,ymm4
  2b1488:	vpxord ymm15,ymm15,ymm0
  2b148e:	vpxord ymm12,ymm12,ymm1
  2b1494:	vpxord ymm13,ymm13,ymm2
  2b149a:	vpxord ymm14,ymm14,ymm3
  2b14a0:	vprord ymm15,ymm15,0x8
  2b14a7:	vprord ymm12,ymm12,0x8
  2b14ae:	vprord ymm13,ymm13,0x8
  2b14b5:	vprord ymm14,ymm14,0x8
  2b14bc:	vpaddd ymm10,ymm10,ymm15
  2b14c1:	vpaddd ymm11,ymm11,ymm12
  2b14c6:	vpaddd ymm8,ymm8,ymm13
  2b14cb:	vpaddd ymm9,ymm9,ymm14
  2b14d0:	vpxord ymm5,ymm5,ymm10
  2b14d6:	vpxord ymm6,ymm6,ymm11
  2b14dc:	vpxord ymm7,ymm7,ymm8
  2b14e2:	vpxord ymm4,ymm4,ymm9
  2b14e8:	vprord ymm5,ymm5,0x7
  2b14ef:	vprord ymm6,ymm6,0x7
  2b14f6:	vprord ymm7,ymm7,0x7
  2b14fd:	vprord ymm4,ymm4,0x7
  2b1504:	vpaddd ymm0,ymm0,ymm25
  2b150a:	vpaddd ymm1,ymm1,ymm27
  2b1510:	vpaddd ymm2,ymm2,ymm24
  2b1516:	vpaddd ymm3,ymm3,ymm31
  2b151c:	vpaddd ymm0,ymm0,ymm4
  2b1520:	vpaddd ymm1,ymm1,ymm5
  2b1524:	vpaddd ymm2,ymm2,ymm6
  2b1528:	vpaddd ymm3,ymm3,ymm7
  2b152c:	vpxord ymm12,ymm12,ymm0
  2b1532:	vpxord ymm13,ymm13,ymm1
  2b1538:	vpxord ymm14,ymm14,ymm2
  2b153e:	vpxord ymm15,ymm15,ymm3
  2b1544:	vprord ymm12,ymm12,0x10
  2b154b:	vprord ymm13,ymm13,0x10
  2b1552:	vprord ymm14,ymm14,0x10
  2b1559:	vprord ymm15,ymm15,0x10
  2b1560:	vpaddd ymm8,ymm8,ymm12
  2b1565:	vpaddd ymm9,ymm9,ymm13
  2b156a:	vpaddd ymm10,ymm10,ymm14
  2b156f:	vpaddd ymm11,ymm11,ymm15
  2b1574:	vpxord ymm4,ymm4,ymm8
  2b157a:	vpxord ymm5,ymm5,ymm9
  2b1580:	vpxord ymm6,ymm6,ymm10
  2b1586:	vpxord ymm7,ymm7,ymm11
  2b158c:	vprord ymm4,ymm4,0xc
  2b1593:	vprord ymm5,ymm5,0xc
  2b159a:	vprord ymm6,ymm6,0xc
  2b15a1:	vprord ymm7,ymm7,0xc
  2b15a8:	vpaddd ymm0,ymm0,ymm30
  2b15ae:	vpaddd ymm1,ymm1,ymm21
  2b15b4:	vpaddd ymm2,ymm2,ymm28
  2b15ba:	vpaddd ymm3,ymm3,ymm17
  2b15c0:	vpaddd ymm0,ymm0,ymm4
  2b15c4:	vpaddd ymm1,ymm1,ymm5
  2b15c8:	vpaddd ymm2,ymm2,ymm6
  2b15cc:	vpaddd ymm3,ymm3,ymm7
  2b15d0:	vpxord ymm12,ymm12,ymm0
  2b15d6:	vpxord ymm13,ymm13,ymm1
  2b15dc:	vpxord ymm14,ymm14,ymm2
  2b15e2:	vpxord ymm15,ymm15,ymm3
  2b15e8:	vprord ymm12,ymm12,0x8
  2b15ef:	vprord ymm13,ymm13,0x8
  2b15f6:	vprord ymm14,ymm14,0x8
  2b15fd:	vprord ymm15,ymm15,0x8
  2b1604:	vpaddd ymm8,ymm8,ymm12
  2b1609:	vpaddd ymm9,ymm9,ymm13
  2b160e:	vpaddd ymm10,ymm10,ymm14
  2b1613:	vpaddd ymm11,ymm11,ymm15
  2b1618:	vpxord ymm4,ymm4,ymm8
  2b161e:	vpxord ymm5,ymm5,ymm9
  2b1624:	vpxord ymm6,ymm6,ymm10
  2b162a:	vpxord ymm7,ymm7,ymm11
  2b1630:	vprord ymm4,ymm4,0x7
  2b1637:	vprord ymm5,ymm5,0x7
  2b163e:	vprord ymm6,ymm6,0x7
  2b1645:	vprord ymm7,ymm7,0x7
  2b164c:	vpaddd ymm0,ymm0,ymm29
  2b1652:	vpaddd ymm1,ymm1,ymm16
  2b1658:	vpaddd ymm2,ymm2,ymm18
  2b165e:	vpaddd ymm3,ymm3,ymm20
  2b1664:	vpaddd ymm0,ymm0,ymm5
  2b1668:	vpaddd ymm1,ymm1,ymm6
  2b166c:	vpaddd ymm2,ymm2,ymm7
  2b1670:	vpaddd ymm3,ymm3,ymm4
  2b1674:	vpxord ymm15,ymm15,ymm0
  2b167a:	vpxord ymm12,ymm12,ymm1
  2b1680:	vpxord ymm13,ymm13,ymm2
  2b1686:	vpxord ymm14,ymm14,ymm3
  2b168c:	vprord ymm15,ymm15,0x10
  2b1693:	vprord ymm12,ymm12,0x10
  2b169a:	vprord ymm13,ymm13,0x10
  2b16a1:	vprord ymm14,ymm14,0x10
  2b16a8:	vpaddd ymm10,ymm10,ymm15
  2b16ad:	vpaddd ymm11,ymm11,ymm12
  2b16b2:	vpaddd ymm8,ymm8,ymm13
  2b16b7:	vpaddd ymm9,ymm9,ymm14
  2b16bc:	vpxord ymm5,ymm5,ymm10
  2b16c2:	vpxord ymm6,ymm6,ymm11
  2b16c8:	vpxord ymm7,ymm7,ymm8
  2b16ce:	vpxord ymm4,ymm4,ymm9
  2b16d4:	vprord ymm5,ymm5,0xc
  2b16db:	vprord ymm6,ymm6,0xc
  2b16e2:	vprord ymm7,ymm7,0xc
  2b16e9:	vprord ymm4,ymm4,0xc
  2b16f0:	vpaddd ymm0,ymm0,ymm19
  2b16f6:	vpaddd ymm1,ymm1,ymm26
  2b16fc:	vpaddd ymm2,ymm2,ymm22
  2b1702:	vpaddd ymm3,ymm3,ymm23
  2b1708:	vpaddd ymm0,ymm0,ymm5
  2b170c:	vpaddd ymm1,ymm1,ymm6
  2b1710:	vpaddd ymm2,ymm2,ymm7
  2b1714:	vpaddd ymm3,ymm3,ymm4
  2b1718:	vpxord ymm15,ymm15,ymm0
  2b171e:	vpxord ymm12,ymm12,ymm1
  2b1724:	vpxord ymm13,ymm13,ymm2
  2b172a:	vpxord ymm14,ymm14,ymm3
  2b1730:	vprord ymm15,ymm15,0x8
  2b1737:	vprord ymm12,ymm12,0x8
  2b173e:	vprord ymm13,ymm13,0x8
  2b1745:	vprord ymm14,ymm14,0x8
  2b174c:	vpaddd ymm10,ymm10,ymm15
  2b1751:	vpaddd ymm11,ymm11,ymm12
  2b1756:	vpaddd ymm8,ymm8,ymm13
  2b175b:	vpaddd ymm9,ymm9,ymm14
  2b1760:	vpxord ymm5,ymm5,ymm10
  2b1766:	vpxord ymm6,ymm6,ymm11
  2b176c:	vpxord ymm7,ymm7,ymm8
  2b1772:	vpxord ymm4,ymm4,ymm9
  2b1778:	vprord ymm5,ymm5,0x7
  2b177f:	vprord ymm6,ymm6,0x7
  2b1786:	vprord ymm7,ymm7,0x7
  2b178d:	vprord ymm4,ymm4,0x7
  2b1794:	vpaddd ymm0,ymm0,ymm27
  2b179a:	vpaddd ymm1,ymm1,ymm21
  2b17a0:	vpaddd ymm2,ymm2,ymm17
  2b17a6:	vpaddd ymm3,ymm3,ymm24
  2b17ac:	vpaddd ymm0,ymm0,ymm4
  2b17b0:	vpaddd ymm1,ymm1,ymm5
  2b17b4:	vpaddd ymm2,ymm2,ymm6
  2b17b8:	vpaddd ymm3,ymm3,ymm7
  2b17bc:	vpxord ymm12,ymm12,ymm0
  2b17c2:	vpxord ymm13,ymm13,ymm1
  2b17c8:	vpxord ymm14,ymm14,ymm2
  2b17ce:	vpxord ymm15,ymm15,ymm3
  2b17d4:	vprord ymm12,ymm12,0x10
  2b17db:	vprord ymm13,ymm13,0x10
  2b17e2:	vprord ymm14,ymm14,0x10
  2b17e9:	vprord ymm15,ymm15,0x10
  2b17f0:	vpaddd ymm8,ymm8,ymm12
  2b17f5:	vpaddd ymm9,ymm9,ymm13
  2b17fa:	vpaddd ymm10,ymm10,ymm14
  2b17ff:	vpaddd ymm11,ymm11,ymm15
  2b1804:	vpxord ymm4,ymm4,ymm8
  2b180a:	vpxord ymm5,ymm5,ymm9
  2b1810:	vpxord ymm6,ymm6,ymm10
  2b1816:	vpxord ymm7,ymm7,ymm11
  2b181c:	vprord ymm4,ymm4,0xc
  2b1823:	vprord ymm5,ymm5,0xc
  2b182a:	vprord ymm6,ymm6,0xc
  2b1831:	vprord ymm7,ymm7,0xc
  2b1838:	vpaddd ymm0,ymm0,ymm31
  2b183e:	vpaddd ymm1,ymm1,ymm16
  2b1844:	vpaddd ymm2,ymm2,ymm25
  2b184a:	vpaddd ymm3,ymm3,ymm22
  2b1850:	vpaddd ymm0,ymm0,ymm4
  2b1854:	vpaddd ymm1,ymm1,ymm5
  2b1858:	vpaddd ymm2,ymm2,ymm6
  2b185c:	vpaddd ymm3,ymm3,ymm7
  2b1860:	vpxord ymm12,ymm12,ymm0
  2b1866:	vpxord ymm13,ymm13,ymm1
  2b186c:	vpxord ymm14,ymm14,ymm2
  2b1872:	vpxord ymm15,ymm15,ymm3
  2b1878:	vprord ymm12,ymm12,0x8
  2b187f:	vprord ymm13,ymm13,0x8
  2b1886:	vprord ymm14,ymm14,0x8
  2b188d:	vprord ymm15,ymm15,0x8
  2b1894:	vpaddd ymm8,ymm8,ymm12
  2b1899:	vpaddd ymm9,ymm9,ymm13
  2b189e:	vpaddd ymm10,ymm10,ymm14
  2b18a3:	vpaddd ymm11,ymm11,ymm15
  2b18a8:	vpxord ymm4,ymm4,ymm8
  2b18ae:	vpxord ymm5,ymm5,ymm9
  2b18b4:	vpxord ymm6,ymm6,ymm10
  2b18ba:	vpxord ymm7,ymm7,ymm11
  2b18c0:	vprord ymm4,ymm4,0x7
  2b18c7:	vprord ymm5,ymm5,0x7
  2b18ce:	vprord ymm6,ymm6,0x7
  2b18d5:	vprord ymm7,ymm7,0x7
  2b18dc:	vpaddd ymm0,ymm0,ymm30
  2b18e2:	vpaddd ymm1,ymm1,ymm18
  2b18e8:	vpaddd ymm2,ymm2,ymm19
  2b18ee:	vpaddd ymm3,ymm3,ymm23
  2b18f4:	vpaddd ymm0,ymm0,ymm5
  2b18f8:	vpaddd ymm1,ymm1,ymm6
  2b18fc:	vpaddd ymm2,ymm2,ymm7
  2b1900:	vpaddd ymm3,ymm3,ymm4
  2b1904:	vpxord ymm15,ymm15,ymm0
  2b190a:	vpxord ymm12,ymm12,ymm1
  2b1910:	vpxord ymm13,ymm13,ymm2
  2b1916:	vpxord ymm14,ymm14,ymm3
  2b191c:	vprord ymm15,ymm15,0x10
  2b1923:	vprord ymm12,ymm12,0x10
  2b192a:	vprord ymm13,ymm13,0x10
  2b1931:	vprord ymm14,ymm14,0x10
  2b1938:	vpaddd ymm10,ymm10,ymm15
  2b193d:	vpaddd ymm11,ymm11,ymm12
  2b1942:	vpaddd ymm8,ymm8,ymm13
  2b1947:	vpaddd ymm9,ymm9,ymm14
  2b194c:	vpxord ymm5,ymm5,ymm10
  2b1952:	vpxord ymm6,ymm6,ymm11
  2b1958:	vpxord ymm7,ymm7,ymm8
  2b195e:	vpxord ymm4,ymm4,ymm9
  2b1964:	vprord ymm5,ymm5,0xc
  2b196b:	vprord ymm6,ymm6,0xc
  2b1972:	vprord ymm7,ymm7,0xc
  2b1979:	vprord ymm4,ymm4,0xc
  2b1980:	vpaddd ymm0,ymm0,ymm26
  2b1986:	vpaddd ymm1,ymm1,ymm28
  2b198c:	vpaddd ymm2,ymm2,ymm20
  2b1992:	vpaddd ymm3,ymm3,ymm29
  2b1998:	vpaddd ymm0,ymm0,ymm5
  2b199c:	vpaddd ymm1,ymm1,ymm6
  2b19a0:	vpaddd ymm2,ymm2,ymm7
  2b19a4:	vpaddd ymm3,ymm3,ymm4
  2b19a8:	vpxord ymm15,ymm15,ymm0
  2b19ae:	vpxord ymm12,ymm12,ymm1
  2b19b4:	vpxord ymm13,ymm13,ymm2
  2b19ba:	vpxord ymm14,ymm14,ymm3
  2b19c0:	vprord ymm15,ymm15,0x8
  2b19c7:	vprord ymm12,ymm12,0x8
  2b19ce:	vprord ymm13,ymm13,0x8
  2b19d5:	vprord ymm14,ymm14,0x8
  2b19dc:	vpaddd ymm10,ymm10,ymm15
  2b19e1:	vpaddd ymm11,ymm11,ymm12
  2b19e6:	vpaddd ymm8,ymm8,ymm13
  2b19eb:	vpaddd ymm9,ymm9,ymm14
  2b19f0:	vpxord ymm5,ymm5,ymm10
  2b19f6:	vpxord ymm6,ymm6,ymm11
  2b19fc:	vpxord ymm7,ymm7,ymm8
  2b1a02:	vpxord ymm4,ymm4,ymm9
  2b1a08:	vprord ymm5,ymm5,0x7
  2b1a0f:	vprord ymm6,ymm6,0x7
  2b1a16:	vprord ymm7,ymm7,0x7
  2b1a1d:	vprord ymm4,ymm4,0x7
  2b1a24:	vpxor  ymm0,ymm0,ymm8
  2b1a29:	vpxor  ymm1,ymm1,ymm9
  2b1a2e:	vpxor  ymm2,ymm2,ymm10
  2b1a33:	vpxor  ymm3,ymm3,ymm11
  2b1a38:	vpxor  ymm4,ymm4,ymm12
  2b1a3d:	vpxor  ymm5,ymm5,ymm13
  2b1a42:	vpxor  ymm6,ymm6,ymm14
  2b1a47:	vpxor  ymm7,ymm7,ymm15
  2b1a4c:	movzx  eax,BYTE PTR [rbp+0x38]
  2b1a50:	jne    2b0626 <_blake3_hash_many_avx512+0x1aa6>
  2b1a56:	mov    rbx,QWORD PTR [rbp+0x50]
  2b1a5a:	vunpcklps ymm8,ymm0,ymm1
  2b1a5e:	vunpcklps ymm9,ymm2,ymm3
  2b1a62:	vunpckhps ymm10,ymm0,ymm1
  2b1a66:	vunpcklps ymm11,ymm4,ymm5
  2b1a6a:	vunpcklps ymm0,ymm6,ymm7
  2b1a6e:	vshufps ymm12,ymm8,ymm9,0x4e
  2b1a74:	vblendps ymm1,ymm8,ymm12,0xcc
  2b1a7a:	vshufps ymm8,ymm11,ymm0,0x4e
  2b1a7f:	vunpckhps ymm13,ymm2,ymm3
  2b1a83:	vblendps ymm2,ymm11,ymm8,0xcc
  2b1a89:	vblendps ymm3,ymm12,ymm9,0xcc
  2b1a8f:	vperm2f128 ymm12,ymm1,ymm2,0x20
  2b1a95:	vmovups YMMWORD PTR [rbx],ymm12
  2b1a99:	vunpckhps ymm14,ymm4,ymm5
  2b1a9d:	vblendps ymm4,ymm8,ymm0,0xcc
  2b1aa3:	vunpckhps ymm15,ymm6,ymm7
  2b1aa7:	vperm2f128 ymm7,ymm3,ymm4,0x20
  2b1aad:	vmovups YMMWORD PTR [rbx+0x20],ymm7
  2b1ab2:	vshufps ymm5,ymm10,ymm13,0x4e
  2b1ab8:	vblendps ymm6,ymm5,ymm13,0xcc
  2b1abe:	vshufps ymm13,ymm14,ymm15,0x4e
  2b1ac4:	vblendps ymm10,ymm10,ymm5,0xcc
  2b1aca:	vblendps ymm14,ymm14,ymm13,0xcc
  2b1ad0:	vperm2f128 ymm8,ymm10,ymm14,0x20
  2b1ad6:	vmovups YMMWORD PTR [rbx+0x40],ymm8
  2b1adb:	vblendps ymm15,ymm13,ymm15,0xcc
  2b1ae1:	vperm2f128 ymm13,ymm6,ymm15,0x20
  2b1ae7:	vmovups YMMWORD PTR [rbx+0x60],ymm13
  2b1aec:	vperm2f128 ymm9,ymm1,ymm2,0x31
  2b1af2:	vperm2f128 ymm11,ymm3,ymm4,0x31
  2b1af8:	vmovups YMMWORD PTR [rbx+0x80],ymm9
  2b1b00:	vperm2f128 ymm14,ymm10,ymm14,0x31
  2b1b06:	vperm2f128 ymm15,ymm6,ymm15,0x31
  2b1b0c:	vmovups YMMWORD PTR [rbx+0xa0],ymm11
  2b1b14:	vmovups YMMWORD PTR [rbx+0xc0],ymm14
  2b1b1c:	vmovups YMMWORD PTR [rbx+0xe0],ymm15
  2b1b24:	vmovdqa ymm0,YMMWORD PTR [rsp]
  2b1b29:	vmovdqa ymm2,YMMWORD PTR [rsp+0x40]
  2b1b2f:	vmovdqa32 ymm0{k1},YMMWORD PTR [rsp+0x20]
  2b1b37:	vmovdqa32 ymm2{k1},YMMWORD PTR [rsp+0x60]
  2b1b3f:	vmovdqa YMMWORD PTR [rsp],ymm0
  2b1b44:	vmovdqa YMMWORD PTR [rsp+0x40],ymm2
  2b1b4a:	add    rbx,0x100
  2b1b51:	mov    QWORD PTR [rbp+0x50],rbx
  2b1b55:	add    rdi,0x40
  2b1b59:	sub    rsi,0x8
  2b1b5d:	mov    rbx,QWORD PTR [rbp+0x50]
  2b1b61:	mov    r15,QWORD PTR [rsp+0x80]
  2b1b69:	movzx  r13,BYTE PTR [rbp+0x38]
  2b1b6e:	movzx  r12,BYTE PTR [rbp+0x48]
  2b1b73:	test   esi,0x4
  2b1b79:	je     2b1ec8 <_blake3_hash_many_avx512+0x3348>
  2b1b7f:	vbroadcasti32x4 zmm0,XMMWORD PTR [rcx]
  2b1b85:	vbroadcasti32x4 zmm1,XMMWORD PTR [rcx+0x10]
  2b1b8c:	vmovdqa xmm12,XMMWORD PTR [rsp]
  2b1b91:	vmovdqa xmm13,XMMWORD PTR [rsp+0x40]
  2b1b97:	vpunpckldq xmm14,xmm12,xmm13
  2b1b9c:	vpunpckhdq xmm15,xmm12,xmm13
  2b1ba1:	vpermq ymm14,ymm14,0xdc
  2b1ba7:	vpermq ymm15,ymm15,0xdc
  2b1bad:	vpbroadcastd zmm12,DWORD PTR [rip+0xffffffffffd8b7d1]        # 3d388 <BLAKE3_BLOCK_LEN>
  2b1bb7:	vinserti64x4 zmm13,zmm14,ymm15,0x1
  2b1bbe:	mov    eax,0x4444
  2b1bc3:	kmovw  k2,eax
  2b1bc7:	vpblendmd zmm13{k2},zmm13,zmm12
  2b1bcd:	vbroadcasti32x4 zmm15,XMMWORD PTR [rip+0xffffffffffd8b7e9]        # 3d3c0 <BLAKE3_IV>
  2b1bd7:	mov    r8,QWORD PTR [rdi]
  2b1bda:	mov    r9,QWORD PTR [rdi+0x8]
  2b1bde:	mov    r10,QWORD PTR [rdi+0x10]
  2b1be2:	mov    r11,QWORD PTR [rdi+0x18]
  2b1be6:	mov    eax,0xaaaa
  2b1beb:	kmovw  k3,eax
  2b1bef:	mov    eax,0x8888
  2b1bf4:	kmovw  k4,eax
  2b1bf8:	movzx  eax,BYTE PTR [rbp+0x40]
  2b1bfc:	or     eax,r13d
  2b1bff:	xor    edx,edx
  2b1c01:	nop    WORD PTR [rax+rax*1+0x0]
  2b1c0a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b1c15:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b1c20:	mov    r14d,eax
  2b1c23:	or     eax,r12d
  2b1c26:	add    rdx,0x40
  2b1c2a:	cmp    rdx,r15
  2b1c2d:	cmovne eax,r14d
  2b1c31:	mov    DWORD PTR [rsp+0x88],eax
  2b1c38:	vmovdqa32 zmm2,zmm15
  2b1c3e:	vpbroadcastd zmm8,DWORD PTR [rsp+0x88]
  2b1c46:	vpblendmd zmm3{k4},zmm13,zmm8
  2b1c4c:	vmovups zmm8,ZMMWORD PTR [r8+rdx*1-0x40]
  2b1c54:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r9+rdx*1-0x40],0x1
  2b1c5d:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r10+rdx*1-0x40],0x2
  2b1c66:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r11+rdx*1-0x40],0x3
  2b1c6f:	vmovups zmm9,ZMMWORD PTR [r8+rdx*1-0x30]
  2b1c7a:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r9+rdx*1-0x30],0x1
  2b1c83:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r10+rdx*1-0x30],0x2
  2b1c8c:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r11+rdx*1-0x30],0x3
  2b1c95:	vshufps zmm4,zmm8,zmm9,0x88
  2b1c9c:	vshufps zmm5,zmm8,zmm9,0xdd
  2b1ca3:	vmovups zmm8,ZMMWORD PTR [r8+rdx*1-0x20]
  2b1cae:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r9+rdx*1-0x20],0x1
  2b1cb7:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r10+rdx*1-0x20],0x2
  2b1cc0:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r11+rdx*1-0x20],0x3
  2b1cc9:	vmovups zmm9,ZMMWORD PTR [r8+rdx*1-0x10]
  2b1cd4:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r9+rdx*1-0x10],0x1
  2b1cdd:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r10+rdx*1-0x10],0x2
  2b1ce6:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r11+rdx*1-0x10],0x3
  2b1cef:	vshufps zmm6,zmm8,zmm9,0x88
  2b1cf6:	vshufps zmm7,zmm8,zmm9,0xdd
  2b1cfd:	vpshufd zmm6,zmm6,0x93
  2b1d04:	vpshufd zmm7,zmm7,0x93
  2b1d0b:	mov    al,0x7
  2b1d0d:	vpaddd zmm0,zmm0,zmm4
  2b1d13:	vpaddd zmm0,zmm0,zmm1
  2b1d19:	vpxord zmm3,zmm3,zmm0
  2b1d1f:	vprord zmm3,zmm3,0x10
  2b1d26:	vpaddd zmm2,zmm2,zmm3
  2b1d2c:	vpxord zmm1,zmm1,zmm2
  2b1d32:	vprord zmm1,zmm1,0xc
  2b1d39:	vpaddd zmm0,zmm0,zmm5
  2b1d3f:	vpaddd zmm0,zmm0,zmm1
  2b1d45:	vpxord zmm3,zmm3,zmm0
  2b1d4b:	vprord zmm3,zmm3,0x8
  2b1d52:	vpaddd zmm2,zmm2,zmm3
  2b1d58:	vpxord zmm1,zmm1,zmm2
  2b1d5e:	vprord zmm1,zmm1,0x7
  2b1d65:	vpshufd zmm0,zmm0,0x93
  2b1d6c:	vpshufd zmm3,zmm3,0x4e
  2b1d73:	vpshufd zmm2,zmm2,0x39
  2b1d7a:	vpaddd zmm0,zmm0,zmm6
  2b1d80:	vpaddd zmm0,zmm0,zmm1
  2b1d86:	vpxord zmm3,zmm3,zmm0
  2b1d8c:	vprord zmm3,zmm3,0x10
  2b1d93:	vpaddd zmm2,zmm2,zmm3
  2b1d99:	vpxord zmm1,zmm1,zmm2
  2b1d9f:	vprord zmm1,zmm1,0xc
  2b1da6:	vpaddd zmm0,zmm0,zmm7
  2b1dac:	vpaddd zmm0,zmm0,zmm1
  2b1db2:	vpxord zmm3,zmm3,zmm0
  2b1db8:	vprord zmm3,zmm3,0x8
  2b1dbf:	vpaddd zmm2,zmm2,zmm3
  2b1dc5:	vpxord zmm1,zmm1,zmm2
  2b1dcb:	vprord zmm1,zmm1,0x7
  2b1dd2:	vpshufd zmm0,zmm0,0x39
  2b1dd9:	vpshufd zmm3,zmm3,0x4e
  2b1de0:	vpshufd zmm2,zmm2,0x93
  2b1de7:	dec    al
  2b1de9:	je     2b1e44 <_blake3_hash_many_avx512+0x32c4>
  2b1deb:	vshufps zmm8,zmm4,zmm5,0xd6
  2b1df2:	vpshufd zmm9,zmm4,0xf
  2b1df9:	vpshufd zmm4,zmm8,0x39
  2b1e00:	vshufps zmm8,zmm6,zmm7,0xfa
  2b1e07:	vpblendmd zmm9{k3},zmm9,zmm8
  2b1e0d:	vpunpcklqdq zmm8,zmm7,zmm5
  2b1e13:	vpblendmd zmm8{k4},zmm8,zmm6
  2b1e19:	vpshufd zmm8,zmm8,0x78
  2b1e20:	vpunpckhdq zmm5,zmm5,zmm7
  2b1e26:	vpunpckldq zmm6,zmm6,zmm5
  2b1e2c:	vpshufd zmm7,zmm6,0x1e
  2b1e33:	vmovdqa32 zmm5,zmm9
  2b1e39:	vmovdqa32 zmm6,zmm8
  2b1e3f:	jmp    2b1d0d <_blake3_hash_many_avx512+0x318d>
  2b1e44:	vpxord zmm0,zmm0,zmm2
  2b1e4a:	vpxord zmm1,zmm1,zmm3
  2b1e50:	mov    eax,r13d
  2b1e53:	cmp    rdx,r15
  2b1e56:	jne    2b1c20 <_blake3_hash_many_avx512+0x30a0>
  2b1e5c:	vmovdqu XMMWORD PTR [rbx],xmm0
  2b1e60:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2b1e65:	vextracti128 XMMWORD PTR [rbx+0x20],ymm0,0x1
  2b1e6c:	vextracti128 XMMWORD PTR [rbx+0x30],ymm1,0x1
  2b1e73:	vextracti32x4 XMMWORD PTR [rbx+0x40],zmm0,0x2
  2b1e7b:	vextracti32x4 XMMWORD PTR [rbx+0x50],zmm1,0x2
  2b1e83:	vextracti32x4 XMMWORD PTR [rbx+0x60],zmm0,0x3
  2b1e8b:	vextracti32x4 XMMWORD PTR [rbx+0x70],zmm1,0x3
  2b1e93:	vmovdqa xmm0,XMMWORD PTR [rsp]
  2b1e98:	vmovdqa xmm2,XMMWORD PTR [rsp+0x40]
  2b1e9e:	vmovdqa32 xmm0{k1},XMMWORD PTR [rsp+0x10]
  2b1ea6:	vmovdqa32 xmm2{k1},XMMWORD PTR [rsp+0x50]
  2b1eae:	vmovdqa XMMWORD PTR [rsp],xmm0
  2b1eb3:	vmovdqa XMMWORD PTR [rsp+0x40],xmm2
  2b1eb9:	add    rbx,0x80
  2b1ec0:	add    rdi,0x20
  2b1ec4:	sub    rsi,0x4
  2b1ec8:	test   esi,0x2
  2b1ece:	je     2b2133 <_blake3_hash_many_avx512+0x35b3>
  2b1ed4:	vbroadcasti128 ymm0,XMMWORD PTR [rcx]
  2b1ed9:	vbroadcasti128 ymm1,XMMWORD PTR [rcx+0x10]
  2b1edf:	vmovd  xmm13,DWORD PTR [rsp]
  2b1ee4:	vpinsrd xmm13,xmm13,DWORD PTR [rsp+0x40],0x1
  2b1eec:	vpinsrd xmm13,xmm13,DWORD PTR [rip+0xffffffffffd8b492],0x2        # 3d388 <BLAKE3_BLOCK_LEN>
  2b1ef6:	vmovd  xmm14,DWORD PTR [rsp+0x4]
  2b1efc:	vpinsrd xmm14,xmm14,DWORD PTR [rsp+0x44],0x1
  2b1f04:	vpinsrd xmm14,xmm14,DWORD PTR [rip+0xffffffffffd8b47a],0x2        # 3d388 <BLAKE3_BLOCK_LEN>
  2b1f0e:	vinserti128 ymm13,ymm13,xmm14,0x1
  2b1f14:	mov    r8,QWORD PTR [rdi]
  2b1f17:	mov    r9,QWORD PTR [rdi+0x8]
  2b1f1b:	movzx  eax,BYTE PTR [rbp+0x40]
  2b1f1f:	or     eax,r13d
  2b1f22:	xor    edx,edx
  2b1f24:	nop    WORD PTR [rax+rax*1+0x0]
  2b1f2a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b1f35:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b1f40:	mov    r14d,eax
  2b1f43:	or     eax,r12d
  2b1f46:	add    rdx,0x40
  2b1f4a:	cmp    rdx,r15
  2b1f4d:	cmovne eax,r14d
  2b1f51:	mov    DWORD PTR [rsp+0x88],eax
  2b1f58:	vbroadcasti128 ymm2,XMMWORD PTR [rip+0xffffffffffd8b45f]        # 3d3c0 <BLAKE3_IV>
  2b1f61:	vpbroadcastd ymm8,DWORD PTR [rsp+0x88]
  2b1f6b:	vpblendd ymm3,ymm13,ymm8,0x88
  2b1f71:	vmovups ymm8,YMMWORD PTR [r8+rdx*1-0x40]
  2b1f78:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r9+rdx*1-0x40],0x1
  2b1f80:	vmovups ymm9,YMMWORD PTR [r8+rdx*1-0x30]
  2b1f87:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r9+rdx*1-0x30],0x1
  2b1f8f:	vshufps ymm4,ymm8,ymm9,0x88
  2b1f95:	vshufps ymm5,ymm8,ymm9,0xdd
  2b1f9b:	vmovups ymm8,YMMWORD PTR [r8+rdx*1-0x20]
  2b1fa2:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r9+rdx*1-0x20],0x1
  2b1faa:	vmovups ymm9,YMMWORD PTR [r8+rdx*1-0x10]
  2b1fb1:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r9+rdx*1-0x10],0x1
  2b1fb9:	vshufps ymm6,ymm8,ymm9,0x88
  2b1fbf:	vshufps ymm7,ymm8,ymm9,0xdd
  2b1fc5:	vpshufd ymm6,ymm6,0x93
  2b1fca:	vpshufd ymm7,ymm7,0x93
  2b1fcf:	mov    al,0x7
  2b1fd1:	vpaddd ymm0,ymm0,ymm4
  2b1fd5:	vpaddd ymm0,ymm0,ymm1
  2b1fd9:	vpxord ymm3,ymm3,ymm0
  2b1fdf:	vprord ymm3,ymm3,0x10
  2b1fe6:	vpaddd ymm2,ymm2,ymm3
  2b1fea:	vpxord ymm1,ymm1,ymm2
  2b1ff0:	vprord ymm1,ymm1,0xc
  2b1ff7:	vpaddd ymm0,ymm0,ymm5
  2b1ffb:	vpaddd ymm0,ymm0,ymm1
  2b1fff:	vpxord ymm3,ymm3,ymm0
  2b2005:	vprord ymm3,ymm3,0x8
  2b200c:	vpaddd ymm2,ymm2,ymm3
  2b2010:	vpxord ymm1,ymm1,ymm2
  2b2016:	vprord ymm1,ymm1,0x7
  2b201d:	vpshufd ymm0,ymm0,0x93
  2b2022:	vpshufd ymm3,ymm3,0x4e
  2b2027:	vpshufd ymm2,ymm2,0x39
  2b202c:	vpaddd ymm0,ymm0,ymm6
  2b2030:	vpaddd ymm0,ymm0,ymm1
  2b2034:	vpxord ymm3,ymm3,ymm0
  2b203a:	vprord ymm3,ymm3,0x10
  2b2041:	vpaddd ymm2,ymm2,ymm3
  2b2045:	vpxord ymm1,ymm1,ymm2
  2b204b:	vprord ymm1,ymm1,0xc
  2b2052:	vpaddd ymm0,ymm0,ymm7
  2b2056:	vpaddd ymm0,ymm0,ymm1
  2b205a:	vpxord ymm3,ymm3,ymm0
  2b2060:	vprord ymm3,ymm3,0x8
  2b2067:	vpaddd ymm2,ymm2,ymm3
  2b206b:	vpxord ymm1,ymm1,ymm2
  2b2071:	vprord ymm1,ymm1,0x7
  2b2078:	vpshufd ymm0,ymm0,0x39
  2b207d:	vpshufd ymm3,ymm3,0x4e
  2b2082:	vpshufd ymm2,ymm2,0x93
  2b2087:	dec    al
  2b2089:	je     2b20d0 <_blake3_hash_many_avx512+0x3550>
  2b208b:	vshufps ymm8,ymm4,ymm5,0xd6
  2b2090:	vpshufd ymm9,ymm4,0xf
  2b2095:	vpshufd ymm4,ymm8,0x39
  2b209b:	vshufps ymm8,ymm6,ymm7,0xfa
  2b20a0:	vpblendd ymm9,ymm9,ymm8,0xaa
  2b20a6:	vpunpcklqdq ymm8,ymm7,ymm5
  2b20aa:	vpblendd ymm8,ymm8,ymm6,0x88
  2b20b0:	vpshufd ymm8,ymm8,0x78
  2b20b6:	vpunpckhdq ymm5,ymm5,ymm7
  2b20ba:	vpunpckldq ymm6,ymm6,ymm5
  2b20be:	vpshufd ymm7,ymm6,0x1e
  2b20c3:	vmovdqa ymm5,ymm9
  2b20c7:	vmovdqa ymm6,ymm8
  2b20cb:	jmp    2b1fd1 <_blake3_hash_many_avx512+0x3451>
  2b20d0:	vpxor  ymm0,ymm0,ymm2
  2b20d4:	vpxor  ymm1,ymm1,ymm3
  2b20d8:	mov    eax,r13d
  2b20db:	cmp    rdx,r15
  2b20de:	jne    2b1f40 <_blake3_hash_many_avx512+0x33c0>
  2b20e4:	vmovdqu XMMWORD PTR [rbx],xmm0
  2b20e8:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2b20ed:	vextracti128 XMMWORD PTR [rbx+0x20],ymm0,0x1
  2b20f4:	vextracti128 XMMWORD PTR [rbx+0x30],ymm1,0x1
  2b20fb:	vmovdqa xmm0,XMMWORD PTR [rsp]
  2b2100:	vmovdqa xmm2,XMMWORD PTR [rsp+0x40]
  2b2106:	vmovdqu32 xmm0{k1},XMMWORD PTR [rsp+0x8]
  2b2111:	vmovdqu32 xmm2{k1},XMMWORD PTR [rsp+0x48]
  2b211c:	vmovdqa XMMWORD PTR [rsp],xmm0
  2b2121:	vmovdqa XMMWORD PTR [rsp+0x40],xmm2
  2b2127:	add    rbx,0x40
  2b212b:	add    rdi,0x10
  2b212f:	sub    rsi,0x2
  2b2133:	test   esi,0x1
  2b2139:	je     2b057a <_blake3_hash_many_avx512+0x19fa>
  2b213f:	vmovdqu xmm0,XMMWORD PTR [rcx]
  2b2143:	vmovdqu xmm1,XMMWORD PTR [rcx+0x10]
  2b2148:	vmovd  xmm14,DWORD PTR [rsp]
  2b214d:	vpinsrd xmm14,xmm14,DWORD PTR [rsp+0x40],0x1
  2b2155:	vpinsrd xmm14,xmm14,DWORD PTR [rip+0xffffffffffd8b229],0x2        # 3d388 <BLAKE3_BLOCK_LEN>
  2b215f:	vmovdqa xmm15,XMMWORD PTR [rip+0xffffffffffd8b259]        # 3d3c0 <BLAKE3_IV>
  2b2167:	mov    r8,QWORD PTR [rdi]
  2b216a:	movzx  eax,BYTE PTR [rbp+0x40]
  2b216e:	or     eax,r13d
  2b2171:	xor    edx,edx
  2b2173:	xchg   ax,ax
  2b2175:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b2180:	mov    r14d,eax
  2b2183:	or     eax,r12d
  2b2186:	add    rdx,0x40
  2b218a:	cmp    rdx,r15
  2b218d:	cmovne eax,r14d
  2b2191:	vpinsrd xmm3,xmm14,eax,0x3
  2b2197:	vmovdqa xmm2,xmm15
  2b219b:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2b21a2:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x30]
  2b21a9:	vshufps xmm4,xmm8,xmm9,0x88
  2b21af:	vshufps xmm5,xmm8,xmm9,0xdd
  2b21b5:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2b21bc:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x10]
  2b21c3:	vshufps xmm6,xmm8,xmm9,0x88
  2b21c9:	vshufps xmm7,xmm8,xmm9,0xdd
  2b21cf:	vpshufd xmm6,xmm6,0x93
  2b21d4:	vpshufd xmm7,xmm7,0x93
  2b21d9:	mov    al,0x7
  2b21db:	vpaddd xmm0,xmm0,xmm4
  2b21df:	vpaddd xmm0,xmm0,xmm1
  2b21e3:	vpxord xmm3,xmm3,xmm0
  2b21e9:	vprord xmm3,xmm3,0x10
  2b21f0:	vpaddd xmm2,xmm2,xmm3
  2b21f4:	vpxord xmm1,xmm1,xmm2
  2b21fa:	vprord xmm1,xmm1,0xc
  2b2201:	vpaddd xmm0,xmm0,xmm5
  2b2205:	vpaddd xmm0,xmm0,xmm1
  2b2209:	vpxord xmm3,xmm3,xmm0
  2b220f:	vprord xmm3,xmm3,0x8
  2b2216:	vpaddd xmm2,xmm2,xmm3
  2b221a:	vpxord xmm1,xmm1,xmm2
  2b2220:	vprord xmm1,xmm1,0x7
  2b2227:	vpshufd xmm0,xmm0,0x93
  2b222c:	vpshufd xmm3,xmm3,0x4e
  2b2231:	vpshufd xmm2,xmm2,0x39
  2b2236:	vpaddd xmm0,xmm0,xmm6
  2b223a:	vpaddd xmm0,xmm0,xmm1
  2b223e:	vpxord xmm3,xmm3,xmm0
  2b2244:	vprord xmm3,xmm3,0x10
  2b224b:	vpaddd xmm2,xmm2,xmm3
  2b224f:	vpxord xmm1,xmm1,xmm2
  2b2255:	vprord xmm1,xmm1,0xc
  2b225c:	vpaddd xmm0,xmm0,xmm7
  2b2260:	vpaddd xmm0,xmm0,xmm1
  2b2264:	vpxord xmm3,xmm3,xmm0
  2b226a:	vprord xmm3,xmm3,0x8
  2b2271:	vpaddd xmm2,xmm2,xmm3
  2b2275:	vpxord xmm1,xmm1,xmm2
  2b227b:	vprord xmm1,xmm1,0x7
  2b2282:	vpshufd xmm0,xmm0,0x39
  2b2287:	vpshufd xmm3,xmm3,0x4e
  2b228c:	vpshufd xmm2,xmm2,0x93
  2b2291:	dec    al
  2b2293:	je     2b22da <_blake3_hash_many_avx512+0x375a>
  2b2295:	vshufps xmm8,xmm4,xmm5,0xd6
  2b229a:	vpshufd xmm9,xmm4,0xf
  2b229f:	vpshufd xmm4,xmm8,0x39
  2b22a5:	vshufps xmm8,xmm6,xmm7,0xfa
  2b22aa:	vpblendd xmm9,xmm9,xmm8,0xaa
  2b22b0:	vpunpcklqdq xmm8,xmm7,xmm5
  2b22b4:	vpblendd xmm8,xmm8,xmm6,0x88
  2b22ba:	vpshufd xmm8,xmm8,0x78
  2b22c0:	vpunpckhdq xmm5,xmm5,xmm7
  2b22c4:	vpunpckldq xmm6,xmm6,xmm5
  2b22c8:	vpshufd xmm7,xmm6,0x1e
  2b22cd:	vmovdqa xmm5,xmm9
  2b22d1:	vmovdqa xmm6,xmm8
  2b22d5:	jmp    2b21db <_blake3_hash_many_avx512+0x365b>
  2b22da:	vpxor  xmm0,xmm0,xmm2
  2b22de:	vpxor  xmm1,xmm1,xmm3
  2b22e2:	mov    eax,r13d
  2b22e5:	cmp    rdx,r15
  2b22e8:	jne    2b2180 <_blake3_hash_many_avx512+0x3600>
  2b22ee:	vmovdqu XMMWORD PTR [rbx],xmm0
  2b22f2:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2b22f7:	jmp    2b057a <_blake3_hash_many_avx512+0x19fa>
  2b22fc:	nop    DWORD PTR [rax+0x0]
