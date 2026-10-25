
/home/samshackleton/blake3-reports/review/github-round-20261024-2254/native/private-symbols-bench:     file format elf64-x86-64


Disassembly of section .text:

00000000002bae00 <_blake3_servil_hash_many_avx512>:
  2bae00:	endbr64
  2bae04:	push   r15
  2bae06:	push   r14
  2bae08:	push   r13
  2bae0a:	push   r12
  2bae0c:	push   rbx
  2bae0d:	push   rbp
  2bae0e:	mov    rbp,rsp
  2bae11:	sub    rsp,0x90
  2bae18:	and    rsp,0xffffffffffffffc0
  2bae1c:	neg    r9
  2bae1f:	kmovw  k1,r9d
  2bae24:	vmovd  xmm0,r8d
  2bae29:	vpbroadcastd ymm0,xmm0
  2bae2e:	shr    r8,0x20
  2bae32:	vmovd  xmm1,r8d
  2bae37:	vpbroadcastd ymm1,xmm1
  2bae3c:	vmovdqa ymm4,ymm1
  2bae40:	vmovdqa ymm5,ymm1
  2bae44:	vpaddd ymm2,ymm0,YMMWORD PTR [rip+0xffffffffffd828f4]        # 3d740 <ADD0>
  2bae4c:	vpaddd ymm3,ymm0,YMMWORD PTR [rip+0xffffffffffd8290c]        # 3d760 <ADD0+0x20>
  2bae54:	vpcmpltud k2,ymm2,ymm0
  2bae5b:	vpcmpltud k3,ymm3,ymm0
  2bae62:	vpaddd ymm4{k2},ymm4,DWORD BCST [rip+0xffffffffffd82914]        # 3d780 <ADD1>
  2bae6c:	vpaddd ymm5{k3},ymm5,DWORD BCST [rip+0xffffffffffd8290a]        # 3d780 <ADD1>
  2bae76:	knotw  k2,k1
  2bae7a:	vmovdqa32 ymm2{k2},ymm0
  2bae80:	vmovdqa32 ymm3{k2},ymm0
  2bae86:	vmovdqa32 ymm4{k2},ymm1
  2bae8c:	vmovdqa32 ymm5{k2},ymm1
  2bae92:	vmovdqa YMMWORD PTR [rsp],ymm2
  2bae97:	vmovdqa YMMWORD PTR [rsp+0x20],ymm3
  2bae9d:	vmovdqa YMMWORD PTR [rsp+0x40],ymm4
  2baea3:	vmovdqa YMMWORD PTR [rsp+0x60],ymm5
  2baea9:	shl    rdx,0x6
  2baead:	mov    QWORD PTR [rsp+0x80],rdx
  2baeb5:	cmp    rsi,0x10
  2baeb9:	jb     2bc840 <_blake3_servil_hash_many_avx512+0x1a40>
  2baebf:	vpbroadcastd zmm0,DWORD PTR [rcx]
  2baec5:	vpbroadcastd zmm1,DWORD PTR [rcx+0x4]
  2baecc:	vpbroadcastd zmm2,DWORD PTR [rcx+0x8]
  2baed3:	vpbroadcastd zmm3,DWORD PTR [rcx+0xc]
  2baeda:	vpbroadcastd zmm4,DWORD PTR [rcx+0x10]
  2baee1:	vpbroadcastd zmm5,DWORD PTR [rcx+0x14]
  2baee8:	vpbroadcastd zmm6,DWORD PTR [rcx+0x18]
  2baeef:	vpbroadcastd zmm7,DWORD PTR [rcx+0x1c]
  2baef6:	movzx  eax,BYTE PTR [rbp+0x38]
  2baefa:	movzx  ebx,BYTE PTR [rbp+0x40]
  2baefe:	or     eax,ebx
  2baf00:	xor    edx,edx
  2baf02:	nop    DWORD PTR [rax+rax*1+0x0]
  2baf0a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2baf15:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2baf20:	movzx  ebx,BYTE PTR [rbp+0x48]
  2baf24:	or     ebx,eax
  2baf26:	add    rdx,0x40
  2baf2a:	cmp    rdx,QWORD PTR [rsp+0x80]
  2baf32:	cmove  eax,ebx
  2baf35:	mov    DWORD PTR [rsp+0x88],eax
  2baf3c:	mov    r8,QWORD PTR [rdi]
  2baf3f:	mov    r9,QWORD PTR [rdi+0x8]
  2baf43:	mov    r10,QWORD PTR [rdi+0x10]
  2baf47:	mov    r11,QWORD PTR [rdi+0x18]
  2baf4b:	mov    r12,QWORD PTR [rdi+0x40]
  2baf4f:	mov    r13,QWORD PTR [rdi+0x48]
  2baf53:	mov    r14,QWORD PTR [rdi+0x50]
  2baf57:	mov    r15,QWORD PTR [rdi+0x58]
  2baf5b:	vmovdqu32 ymm16,YMMWORD PTR [rdx+r8*1-0x40]
  2baf63:	vinserti64x4 zmm16,zmm16,YMMWORD PTR [rdx+r12*1-0x40],0x1
  2baf6c:	vmovdqu32 ymm17,YMMWORD PTR [rdx+r9*1-0x40]
  2baf74:	vinserti64x4 zmm17,zmm17,YMMWORD PTR [rdx+r13*1-0x40],0x1
  2baf7d:	vpunpcklqdq zmm8,zmm16,zmm17
  2baf83:	vpunpckhqdq zmm9,zmm16,zmm17
  2baf89:	vmovdqu32 ymm18,YMMWORD PTR [rdx+r10*1-0x40]
  2baf91:	vinserti64x4 zmm18,zmm18,YMMWORD PTR [rdx+r14*1-0x40],0x1
  2baf9a:	vmovdqu32 ymm19,YMMWORD PTR [rdx+r11*1-0x40]
  2bafa2:	vinserti64x4 zmm19,zmm19,YMMWORD PTR [rdx+r15*1-0x40],0x1
  2bafab:	vpunpcklqdq zmm10,zmm18,zmm19
  2bafb1:	vpunpckhqdq zmm11,zmm18,zmm19
  2bafb7:	mov    r8,QWORD PTR [rdi+0x20]
  2bafbb:	mov    r9,QWORD PTR [rdi+0x28]
  2bafbf:	mov    r10,QWORD PTR [rdi+0x30]
  2bafc3:	mov    r11,QWORD PTR [rdi+0x38]
  2bafc7:	mov    r12,QWORD PTR [rdi+0x60]
  2bafcb:	mov    r13,QWORD PTR [rdi+0x68]
  2bafcf:	mov    r14,QWORD PTR [rdi+0x70]
  2bafd3:	mov    r15,QWORD PTR [rdi+0x78]
  2bafd7:	vmovdqu32 ymm16,YMMWORD PTR [rdx+r8*1-0x40]
  2bafdf:	vinserti64x4 zmm16,zmm16,YMMWORD PTR [rdx+r12*1-0x40],0x1
  2bafe8:	vmovdqu32 ymm17,YMMWORD PTR [rdx+r9*1-0x40]
  2baff0:	vinserti64x4 zmm17,zmm17,YMMWORD PTR [rdx+r13*1-0x40],0x1
  2baff9:	vpunpcklqdq zmm12,zmm16,zmm17
  2bafff:	vpunpckhqdq zmm13,zmm16,zmm17
  2bb005:	vmovdqu32 ymm18,YMMWORD PTR [rdx+r10*1-0x40]
  2bb00d:	vinserti64x4 zmm18,zmm18,YMMWORD PTR [rdx+r14*1-0x40],0x1
  2bb016:	vmovdqu32 ymm19,YMMWORD PTR [rdx+r11*1-0x40]
  2bb01e:	vinserti64x4 zmm19,zmm19,YMMWORD PTR [rdx+r15*1-0x40],0x1
  2bb027:	vpunpcklqdq zmm14,zmm18,zmm19
  2bb02d:	vpunpckhqdq zmm15,zmm18,zmm19
  2bb033:	vmovdqa32 zmm27,ZMMWORD PTR [rip+0xffffffffffd82683]        # 3d6c0 <INDEX0>
  2bb03d:	vmovdqa32 zmm31,ZMMWORD PTR [rip+0xffffffffffd826b9]        # 3d700 <INDEX1>
  2bb047:	vshufps zmm16,zmm8,zmm10,0x88
  2bb04e:	vshufps zmm17,zmm12,zmm14,0x88
  2bb055:	vmovdqa32 zmm20,zmm16
  2bb05b:	vpermt2d zmm16,zmm27,zmm17
  2bb061:	vpermt2d zmm20,zmm31,zmm17
  2bb067:	vshufps zmm17,zmm8,zmm10,0xdd
  2bb06e:	vshufps zmm30,zmm12,zmm14,0xdd
  2bb075:	vmovdqa32 zmm21,zmm17
  2bb07b:	vpermt2d zmm17,zmm27,zmm30
  2bb081:	vpermt2d zmm21,zmm31,zmm30
  2bb087:	vshufps zmm18,zmm9,zmm11,0x88
  2bb08e:	vshufps zmm8,zmm13,zmm15,0x88
  2bb095:	vmovdqa32 zmm22,zmm18
  2bb09b:	vpermt2d zmm18,zmm27,zmm8
  2bb0a1:	vpermt2d zmm22,zmm31,zmm8
  2bb0a7:	vshufps zmm19,zmm9,zmm11,0xdd
  2bb0ae:	vshufps zmm8,zmm13,zmm15,0xdd
  2bb0b5:	vmovdqa32 zmm23,zmm19
  2bb0bb:	vpermt2d zmm19,zmm27,zmm8
  2bb0c1:	vpermt2d zmm23,zmm31,zmm8
  2bb0c7:	mov    r8,QWORD PTR [rdi]
  2bb0ca:	mov    r9,QWORD PTR [rdi+0x8]
  2bb0ce:	mov    r10,QWORD PTR [rdi+0x10]
  2bb0d2:	mov    r11,QWORD PTR [rdi+0x18]
  2bb0d6:	mov    r12,QWORD PTR [rdi+0x40]
  2bb0da:	mov    r13,QWORD PTR [rdi+0x48]
  2bb0de:	mov    r14,QWORD PTR [rdi+0x50]
  2bb0e2:	mov    r15,QWORD PTR [rdi+0x58]
  2bb0e6:	vmovdqu32 ymm24,YMMWORD PTR [r8+rdx*1-0x20]
  2bb0ee:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r12+rdx*1-0x20],0x1
  2bb0f7:	vmovdqu32 ymm25,YMMWORD PTR [r9+rdx*1-0x20]
  2bb0ff:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r13+rdx*1-0x20],0x1
  2bb108:	vpunpcklqdq zmm8,zmm24,zmm25
  2bb10e:	vpunpckhqdq zmm9,zmm24,zmm25
  2bb114:	vmovdqu32 ymm24,YMMWORD PTR [r10+rdx*1-0x20]
  2bb11c:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r14+rdx*1-0x20],0x1
  2bb125:	vmovdqu32 ymm25,YMMWORD PTR [r11+rdx*1-0x20]
  2bb12d:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r15+rdx*1-0x20],0x1
  2bb136:	vpunpcklqdq zmm10,zmm24,zmm25
  2bb13c:	vpunpckhqdq zmm11,zmm24,zmm25
  2bb142:	prefetcht0 BYTE PTR [r8+rdx*1+0x80]
  2bb14b:	prefetcht0 BYTE PTR [r12+rdx*1+0x80]
  2bb154:	prefetcht0 BYTE PTR [r9+rdx*1+0x80]
  2bb15d:	prefetcht0 BYTE PTR [r13+rdx*1+0x80]
  2bb166:	prefetcht0 BYTE PTR [r10+rdx*1+0x80]
  2bb16f:	prefetcht0 BYTE PTR [r14+rdx*1+0x80]
  2bb178:	prefetcht0 BYTE PTR [r11+rdx*1+0x80]
  2bb181:	prefetcht0 BYTE PTR [r15+rdx*1+0x80]
  2bb18a:	mov    r8,QWORD PTR [rdi+0x20]
  2bb18e:	mov    r9,QWORD PTR [rdi+0x28]
  2bb192:	mov    r10,QWORD PTR [rdi+0x30]
  2bb196:	mov    r11,QWORD PTR [rdi+0x38]
  2bb19a:	mov    r12,QWORD PTR [rdi+0x60]
  2bb19e:	mov    r13,QWORD PTR [rdi+0x68]
  2bb1a2:	mov    r14,QWORD PTR [rdi+0x70]
  2bb1a6:	mov    r15,QWORD PTR [rdi+0x78]
  2bb1aa:	vmovdqu32 ymm24,YMMWORD PTR [r8+rdx*1-0x20]
  2bb1b2:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r12+rdx*1-0x20],0x1
  2bb1bb:	vmovdqu32 ymm25,YMMWORD PTR [r9+rdx*1-0x20]
  2bb1c3:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r13+rdx*1-0x20],0x1
  2bb1cc:	vpunpcklqdq zmm12,zmm24,zmm25
  2bb1d2:	vpunpckhqdq zmm13,zmm24,zmm25
  2bb1d8:	vmovdqu32 ymm24,YMMWORD PTR [r10+rdx*1-0x20]
  2bb1e0:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r14+rdx*1-0x20],0x1
  2bb1e9:	vmovdqu32 ymm25,YMMWORD PTR [r11+rdx*1-0x20]
  2bb1f1:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r15+rdx*1-0x20],0x1
  2bb1fa:	vpunpcklqdq zmm14,zmm24,zmm25
  2bb200:	vpunpckhqdq zmm15,zmm24,zmm25
  2bb206:	prefetcht0 BYTE PTR [r8+rdx*1+0x80]
  2bb20f:	prefetcht0 BYTE PTR [r12+rdx*1+0x80]
  2bb218:	prefetcht0 BYTE PTR [r9+rdx*1+0x80]
  2bb221:	prefetcht0 BYTE PTR [r13+rdx*1+0x80]
  2bb22a:	prefetcht0 BYTE PTR [r10+rdx*1+0x80]
  2bb233:	prefetcht0 BYTE PTR [r14+rdx*1+0x80]
  2bb23c:	prefetcht0 BYTE PTR [r11+rdx*1+0x80]
  2bb245:	prefetcht0 BYTE PTR [r15+rdx*1+0x80]
  2bb24e:	vshufps zmm24,zmm8,zmm10,0x88
  2bb255:	vshufps zmm30,zmm12,zmm14,0x88
  2bb25c:	vmovdqa32 zmm28,zmm24
  2bb262:	vpermt2d zmm24,zmm27,zmm30
  2bb268:	vpermt2d zmm28,zmm31,zmm30
  2bb26e:	vshufps zmm25,zmm8,zmm10,0xdd
  2bb275:	vshufps zmm30,zmm12,zmm14,0xdd
  2bb27c:	vmovdqa32 zmm29,zmm25
  2bb282:	vpermt2d zmm25,zmm27,zmm30
  2bb288:	vpermt2d zmm29,zmm31,zmm30
  2bb28e:	vshufps zmm26,zmm9,zmm11,0x88
  2bb295:	vshufps zmm8,zmm13,zmm15,0x88
  2bb29c:	vmovdqa32 zmm30,zmm26
  2bb2a2:	vpermt2d zmm26,zmm27,zmm8
  2bb2a8:	vpermt2d zmm30,zmm31,zmm8
  2bb2ae:	vshufps zmm8,zmm9,zmm11,0xdd
  2bb2b5:	vshufps zmm10,zmm13,zmm15,0xdd
  2bb2bc:	vpermi2d zmm27,zmm8,zmm10
  2bb2c2:	vpermi2d zmm31,zmm8,zmm10
  2bb2c8:	vpbroadcastd zmm8,DWORD PTR [rip+0xffffffffffd824ee]        # 3d7c0 <BLAKE3_IV>
  2bb2d2:	vpbroadcastd zmm9,DWORD PTR [rip+0xffffffffffd824e8]        # 3d7c4 <BLAKE3_IV_1>
  2bb2dc:	vpbroadcastd zmm10,DWORD PTR [rip+0xffffffffffd824e2]        # 3d7c8 <BLAKE3_IV_2>
  2bb2e6:	vpbroadcastd zmm11,DWORD PTR [rip+0xffffffffffd824dc]        # 3d7cc <BLAKE3_IV_3>
  2bb2f0:	vmovdqa32 zmm12,ZMMWORD PTR [rsp]
  2bb2f7:	vmovdqa32 zmm13,ZMMWORD PTR [rsp+0x40]
  2bb2ff:	vpbroadcastd zmm14,DWORD PTR [rip+0xffffffffffd8247f]        # 3d788 <BLAKE3_BLOCK_LEN>
  2bb309:	vpbroadcastd zmm15,DWORD PTR [rsp+0x88]
  2bb311:	vpaddd zmm0,zmm0,zmm16
  2bb317:	vpaddd zmm1,zmm1,zmm18
  2bb31d:	vpaddd zmm2,zmm2,zmm20
  2bb323:	vpaddd zmm3,zmm3,zmm22
  2bb329:	vpaddd zmm0,zmm0,zmm4
  2bb32f:	vpaddd zmm1,zmm1,zmm5
  2bb335:	vpaddd zmm2,zmm2,zmm6
  2bb33b:	vpaddd zmm3,zmm3,zmm7
  2bb341:	vpxord zmm12,zmm12,zmm0
  2bb347:	vpxord zmm13,zmm13,zmm1
  2bb34d:	vpxord zmm14,zmm14,zmm2
  2bb353:	vpxord zmm15,zmm15,zmm3
  2bb359:	vprord zmm12,zmm12,0x10
  2bb360:	vprord zmm13,zmm13,0x10
  2bb367:	vprord zmm14,zmm14,0x10
  2bb36e:	vprord zmm15,zmm15,0x10
  2bb375:	vpaddd zmm8,zmm8,zmm12
  2bb37b:	vpaddd zmm9,zmm9,zmm13
  2bb381:	vpaddd zmm10,zmm10,zmm14
  2bb387:	vpaddd zmm11,zmm11,zmm15
  2bb38d:	vpxord zmm4,zmm4,zmm8
  2bb393:	vpxord zmm5,zmm5,zmm9
  2bb399:	vpxord zmm6,zmm6,zmm10
  2bb39f:	vpxord zmm7,zmm7,zmm11
  2bb3a5:	vprord zmm4,zmm4,0xc
  2bb3ac:	vprord zmm5,zmm5,0xc
  2bb3b3:	vprord zmm6,zmm6,0xc
  2bb3ba:	vprord zmm7,zmm7,0xc
  2bb3c1:	vpaddd zmm0,zmm0,zmm17
  2bb3c7:	vpaddd zmm1,zmm1,zmm19
  2bb3cd:	vpaddd zmm2,zmm2,zmm21
  2bb3d3:	vpaddd zmm3,zmm3,zmm23
  2bb3d9:	vpaddd zmm0,zmm0,zmm4
  2bb3df:	vpaddd zmm1,zmm1,zmm5
  2bb3e5:	vpaddd zmm2,zmm2,zmm6
  2bb3eb:	vpaddd zmm3,zmm3,zmm7
  2bb3f1:	vpxord zmm12,zmm12,zmm0
  2bb3f7:	vpxord zmm13,zmm13,zmm1
  2bb3fd:	vpxord zmm14,zmm14,zmm2
  2bb403:	vpxord zmm15,zmm15,zmm3
  2bb409:	vprord zmm12,zmm12,0x8
  2bb410:	vprord zmm13,zmm13,0x8
  2bb417:	vprord zmm14,zmm14,0x8
  2bb41e:	vprord zmm15,zmm15,0x8
  2bb425:	vpaddd zmm8,zmm8,zmm12
  2bb42b:	vpaddd zmm9,zmm9,zmm13
  2bb431:	vpaddd zmm10,zmm10,zmm14
  2bb437:	vpaddd zmm11,zmm11,zmm15
  2bb43d:	vpxord zmm4,zmm4,zmm8
  2bb443:	vpxord zmm5,zmm5,zmm9
  2bb449:	vpxord zmm6,zmm6,zmm10
  2bb44f:	vpxord zmm7,zmm7,zmm11
  2bb455:	vprord zmm4,zmm4,0x7
  2bb45c:	vprord zmm5,zmm5,0x7
  2bb463:	vprord zmm6,zmm6,0x7
  2bb46a:	vprord zmm7,zmm7,0x7
  2bb471:	vpaddd zmm0,zmm0,zmm24
  2bb477:	vpaddd zmm1,zmm1,zmm26
  2bb47d:	vpaddd zmm2,zmm2,zmm28
  2bb483:	vpaddd zmm3,zmm3,zmm30
  2bb489:	vpaddd zmm0,zmm0,zmm5
  2bb48f:	vpaddd zmm1,zmm1,zmm6
  2bb495:	vpaddd zmm2,zmm2,zmm7
  2bb49b:	vpaddd zmm3,zmm3,zmm4
  2bb4a1:	vpxord zmm15,zmm15,zmm0
  2bb4a7:	vpxord zmm12,zmm12,zmm1
  2bb4ad:	vpxord zmm13,zmm13,zmm2
  2bb4b3:	vpxord zmm14,zmm14,zmm3
  2bb4b9:	vprord zmm15,zmm15,0x10
  2bb4c0:	vprord zmm12,zmm12,0x10
  2bb4c7:	vprord zmm13,zmm13,0x10
  2bb4ce:	vprord zmm14,zmm14,0x10
  2bb4d5:	vpaddd zmm10,zmm10,zmm15
  2bb4db:	vpaddd zmm11,zmm11,zmm12
  2bb4e1:	vpaddd zmm8,zmm8,zmm13
  2bb4e7:	vpaddd zmm9,zmm9,zmm14
  2bb4ed:	vpxord zmm5,zmm5,zmm10
  2bb4f3:	vpxord zmm6,zmm6,zmm11
  2bb4f9:	vpxord zmm7,zmm7,zmm8
  2bb4ff:	vpxord zmm4,zmm4,zmm9
  2bb505:	vprord zmm5,zmm5,0xc
  2bb50c:	vprord zmm6,zmm6,0xc
  2bb513:	vprord zmm7,zmm7,0xc
  2bb51a:	vprord zmm4,zmm4,0xc
  2bb521:	vpaddd zmm0,zmm0,zmm25
  2bb527:	vpaddd zmm1,zmm1,zmm27
  2bb52d:	vpaddd zmm2,zmm2,zmm29
  2bb533:	vpaddd zmm3,zmm3,zmm31
  2bb539:	vpaddd zmm0,zmm0,zmm5
  2bb53f:	vpaddd zmm1,zmm1,zmm6
  2bb545:	vpaddd zmm2,zmm2,zmm7
  2bb54b:	vpaddd zmm3,zmm3,zmm4
  2bb551:	vpxord zmm15,zmm15,zmm0
  2bb557:	vpxord zmm12,zmm12,zmm1
  2bb55d:	vpxord zmm13,zmm13,zmm2
  2bb563:	vpxord zmm14,zmm14,zmm3
  2bb569:	vprord zmm15,zmm15,0x8
  2bb570:	vprord zmm12,zmm12,0x8
  2bb577:	vprord zmm13,zmm13,0x8
  2bb57e:	vprord zmm14,zmm14,0x8
  2bb585:	vpaddd zmm10,zmm10,zmm15
  2bb58b:	vpaddd zmm11,zmm11,zmm12
  2bb591:	vpaddd zmm8,zmm8,zmm13
  2bb597:	vpaddd zmm9,zmm9,zmm14
  2bb59d:	vpxord zmm5,zmm5,zmm10
  2bb5a3:	vpxord zmm6,zmm6,zmm11
  2bb5a9:	vpxord zmm7,zmm7,zmm8
  2bb5af:	vpxord zmm4,zmm4,zmm9
  2bb5b5:	vprord zmm5,zmm5,0x7
  2bb5bc:	vprord zmm6,zmm6,0x7
  2bb5c3:	vprord zmm7,zmm7,0x7
  2bb5ca:	vprord zmm4,zmm4,0x7
  2bb5d1:	vpaddd zmm0,zmm0,zmm18
  2bb5d7:	vpaddd zmm1,zmm1,zmm19
  2bb5dd:	vpaddd zmm2,zmm2,zmm23
  2bb5e3:	vpaddd zmm3,zmm3,zmm20
  2bb5e9:	vpaddd zmm0,zmm0,zmm4
  2bb5ef:	vpaddd zmm1,zmm1,zmm5
  2bb5f5:	vpaddd zmm2,zmm2,zmm6
  2bb5fb:	vpaddd zmm3,zmm3,zmm7
  2bb601:	vpxord zmm12,zmm12,zmm0
  2bb607:	vpxord zmm13,zmm13,zmm1
  2bb60d:	vpxord zmm14,zmm14,zmm2
  2bb613:	vpxord zmm15,zmm15,zmm3
  2bb619:	vprord zmm12,zmm12,0x10
  2bb620:	vprord zmm13,zmm13,0x10
  2bb627:	vprord zmm14,zmm14,0x10
  2bb62e:	vprord zmm15,zmm15,0x10
  2bb635:	vpaddd zmm8,zmm8,zmm12
  2bb63b:	vpaddd zmm9,zmm9,zmm13
  2bb641:	vpaddd zmm10,zmm10,zmm14
  2bb647:	vpaddd zmm11,zmm11,zmm15
  2bb64d:	vpxord zmm4,zmm4,zmm8
  2bb653:	vpxord zmm5,zmm5,zmm9
  2bb659:	vpxord zmm6,zmm6,zmm10
  2bb65f:	vpxord zmm7,zmm7,zmm11
  2bb665:	vprord zmm4,zmm4,0xc
  2bb66c:	vprord zmm5,zmm5,0xc
  2bb673:	vprord zmm6,zmm6,0xc
  2bb67a:	vprord zmm7,zmm7,0xc
  2bb681:	vpaddd zmm0,zmm0,zmm22
  2bb687:	vpaddd zmm1,zmm1,zmm26
  2bb68d:	vpaddd zmm2,zmm2,zmm16
  2bb693:	vpaddd zmm3,zmm3,zmm29
  2bb699:	vpaddd zmm0,zmm0,zmm4
  2bb69f:	vpaddd zmm1,zmm1,zmm5
  2bb6a5:	vpaddd zmm2,zmm2,zmm6
  2bb6ab:	vpaddd zmm3,zmm3,zmm7
  2bb6b1:	vpxord zmm12,zmm12,zmm0
  2bb6b7:	vpxord zmm13,zmm13,zmm1
  2bb6bd:	vpxord zmm14,zmm14,zmm2
  2bb6c3:	vpxord zmm15,zmm15,zmm3
  2bb6c9:	vprord zmm12,zmm12,0x8
  2bb6d0:	vprord zmm13,zmm13,0x8
  2bb6d7:	vprord zmm14,zmm14,0x8
  2bb6de:	vprord zmm15,zmm15,0x8
  2bb6e5:	vpaddd zmm8,zmm8,zmm12
  2bb6eb:	vpaddd zmm9,zmm9,zmm13
  2bb6f1:	vpaddd zmm10,zmm10,zmm14
  2bb6f7:	vpaddd zmm11,zmm11,zmm15
  2bb6fd:	vpxord zmm4,zmm4,zmm8
  2bb703:	vpxord zmm5,zmm5,zmm9
  2bb709:	vpxord zmm6,zmm6,zmm10
  2bb70f:	vpxord zmm7,zmm7,zmm11
  2bb715:	vprord zmm4,zmm4,0x7
  2bb71c:	vprord zmm5,zmm5,0x7
  2bb723:	vprord zmm6,zmm6,0x7
  2bb72a:	vprord zmm7,zmm7,0x7
  2bb731:	vpaddd zmm0,zmm0,zmm17
  2bb737:	vpaddd zmm1,zmm1,zmm28
  2bb73d:	vpaddd zmm2,zmm2,zmm25
  2bb743:	vpaddd zmm3,zmm3,zmm31
  2bb749:	vpaddd zmm0,zmm0,zmm5
  2bb74f:	vpaddd zmm1,zmm1,zmm6
  2bb755:	vpaddd zmm2,zmm2,zmm7
  2bb75b:	vpaddd zmm3,zmm3,zmm4
  2bb761:	vpxord zmm15,zmm15,zmm0
  2bb767:	vpxord zmm12,zmm12,zmm1
  2bb76d:	vpxord zmm13,zmm13,zmm2
  2bb773:	vpxord zmm14,zmm14,zmm3
  2bb779:	vprord zmm15,zmm15,0x10
  2bb780:	vprord zmm12,zmm12,0x10
  2bb787:	vprord zmm13,zmm13,0x10
  2bb78e:	vprord zmm14,zmm14,0x10
  2bb795:	vpaddd zmm10,zmm10,zmm15
  2bb79b:	vpaddd zmm11,zmm11,zmm12
  2bb7a1:	vpaddd zmm8,zmm8,zmm13
  2bb7a7:	vpaddd zmm9,zmm9,zmm14
  2bb7ad:	vpxord zmm5,zmm5,zmm10
  2bb7b3:	vpxord zmm6,zmm6,zmm11
  2bb7b9:	vpxord zmm7,zmm7,zmm8
  2bb7bf:	vpxord zmm4,zmm4,zmm9
  2bb7c5:	vprord zmm5,zmm5,0xc
  2bb7cc:	vprord zmm6,zmm6,0xc
  2bb7d3:	vprord zmm7,zmm7,0xc
  2bb7da:	vprord zmm4,zmm4,0xc
  2bb7e1:	vpaddd zmm0,zmm0,zmm27
  2bb7e7:	vpaddd zmm1,zmm1,zmm21
  2bb7ed:	vpaddd zmm2,zmm2,zmm30
  2bb7f3:	vpaddd zmm3,zmm3,zmm24
  2bb7f9:	vpaddd zmm0,zmm0,zmm5
  2bb7ff:	vpaddd zmm1,zmm1,zmm6
  2bb805:	vpaddd zmm2,zmm2,zmm7
  2bb80b:	vpaddd zmm3,zmm3,zmm4
  2bb811:	vpxord zmm15,zmm15,zmm0
  2bb817:	vpxord zmm12,zmm12,zmm1
  2bb81d:	vpxord zmm13,zmm13,zmm2
  2bb823:	vpxord zmm14,zmm14,zmm3
  2bb829:	vprord zmm15,zmm15,0x8
  2bb830:	vprord zmm12,zmm12,0x8
  2bb837:	vprord zmm13,zmm13,0x8
  2bb83e:	vprord zmm14,zmm14,0x8
  2bb845:	vpaddd zmm10,zmm10,zmm15
  2bb84b:	vpaddd zmm11,zmm11,zmm12
  2bb851:	vpaddd zmm8,zmm8,zmm13
  2bb857:	vpaddd zmm9,zmm9,zmm14
  2bb85d:	vpxord zmm5,zmm5,zmm10
  2bb863:	vpxord zmm6,zmm6,zmm11
  2bb869:	vpxord zmm7,zmm7,zmm8
  2bb86f:	vpxord zmm4,zmm4,zmm9
  2bb875:	vprord zmm5,zmm5,0x7
  2bb87c:	vprord zmm6,zmm6,0x7
  2bb883:	vprord zmm7,zmm7,0x7
  2bb88a:	vprord zmm4,zmm4,0x7
  2bb891:	vpaddd zmm0,zmm0,zmm19
  2bb897:	vpaddd zmm1,zmm1,zmm26
  2bb89d:	vpaddd zmm2,zmm2,zmm29
  2bb8a3:	vpaddd zmm3,zmm3,zmm23
  2bb8a9:	vpaddd zmm0,zmm0,zmm4
  2bb8af:	vpaddd zmm1,zmm1,zmm5
  2bb8b5:	vpaddd zmm2,zmm2,zmm6
  2bb8bb:	vpaddd zmm3,zmm3,zmm7
  2bb8c1:	vpxord zmm12,zmm12,zmm0
  2bb8c7:	vpxord zmm13,zmm13,zmm1
  2bb8cd:	vpxord zmm14,zmm14,zmm2
  2bb8d3:	vpxord zmm15,zmm15,zmm3
  2bb8d9:	vprord zmm12,zmm12,0x10
  2bb8e0:	vprord zmm13,zmm13,0x10
  2bb8e7:	vprord zmm14,zmm14,0x10
  2bb8ee:	vprord zmm15,zmm15,0x10
  2bb8f5:	vpaddd zmm8,zmm8,zmm12
  2bb8fb:	vpaddd zmm9,zmm9,zmm13
  2bb901:	vpaddd zmm10,zmm10,zmm14
  2bb907:	vpaddd zmm11,zmm11,zmm15
  2bb90d:	vpxord zmm4,zmm4,zmm8
  2bb913:	vpxord zmm5,zmm5,zmm9
  2bb919:	vpxord zmm6,zmm6,zmm10
  2bb91f:	vpxord zmm7,zmm7,zmm11
  2bb925:	vprord zmm4,zmm4,0xc
  2bb92c:	vprord zmm5,zmm5,0xc
  2bb933:	vprord zmm6,zmm6,0xc
  2bb93a:	vprord zmm7,zmm7,0xc
  2bb941:	vpaddd zmm0,zmm0,zmm20
  2bb947:	vpaddd zmm1,zmm1,zmm28
  2bb94d:	vpaddd zmm2,zmm2,zmm18
  2bb953:	vpaddd zmm3,zmm3,zmm30
  2bb959:	vpaddd zmm0,zmm0,zmm4
  2bb95f:	vpaddd zmm1,zmm1,zmm5
  2bb965:	vpaddd zmm2,zmm2,zmm6
  2bb96b:	vpaddd zmm3,zmm3,zmm7
  2bb971:	vpxord zmm12,zmm12,zmm0
  2bb977:	vpxord zmm13,zmm13,zmm1
  2bb97d:	vpxord zmm14,zmm14,zmm2
  2bb983:	vpxord zmm15,zmm15,zmm3
  2bb989:	vprord zmm12,zmm12,0x8
  2bb990:	vprord zmm13,zmm13,0x8
  2bb997:	vprord zmm14,zmm14,0x8
  2bb99e:	vprord zmm15,zmm15,0x8
  2bb9a5:	vpaddd zmm8,zmm8,zmm12
  2bb9ab:	vpaddd zmm9,zmm9,zmm13
  2bb9b1:	vpaddd zmm10,zmm10,zmm14
  2bb9b7:	vpaddd zmm11,zmm11,zmm15
  2bb9bd:	vpxord zmm4,zmm4,zmm8
  2bb9c3:	vpxord zmm5,zmm5,zmm9
  2bb9c9:	vpxord zmm6,zmm6,zmm10
  2bb9cf:	vpxord zmm7,zmm7,zmm11
  2bb9d5:	vprord zmm4,zmm4,0x7
  2bb9dc:	vprord zmm5,zmm5,0x7
  2bb9e3:	vprord zmm6,zmm6,0x7
  2bb9ea:	vprord zmm7,zmm7,0x7
  2bb9f1:	vpaddd zmm0,zmm0,zmm22
  2bb9f7:	vpaddd zmm1,zmm1,zmm25
  2bb9fd:	vpaddd zmm2,zmm2,zmm27
  2bba03:	vpaddd zmm3,zmm3,zmm24
  2bba09:	vpaddd zmm0,zmm0,zmm5
  2bba0f:	vpaddd zmm1,zmm1,zmm6
  2bba15:	vpaddd zmm2,zmm2,zmm7
  2bba1b:	vpaddd zmm3,zmm3,zmm4
  2bba21:	vpxord zmm15,zmm15,zmm0
  2bba27:	vpxord zmm12,zmm12,zmm1
  2bba2d:	vpxord zmm13,zmm13,zmm2
  2bba33:	vpxord zmm14,zmm14,zmm3
  2bba39:	vprord zmm15,zmm15,0x10
  2bba40:	vprord zmm12,zmm12,0x10
  2bba47:	vprord zmm13,zmm13,0x10
  2bba4e:	vprord zmm14,zmm14,0x10
  2bba55:	vpaddd zmm10,zmm10,zmm15
  2bba5b:	vpaddd zmm11,zmm11,zmm12
  2bba61:	vpaddd zmm8,zmm8,zmm13
  2bba67:	vpaddd zmm9,zmm9,zmm14
  2bba6d:	vpxord zmm5,zmm5,zmm10
  2bba73:	vpxord zmm6,zmm6,zmm11
  2bba79:	vpxord zmm7,zmm7,zmm8
  2bba7f:	vpxord zmm4,zmm4,zmm9
  2bba85:	vprord zmm5,zmm5,0xc
  2bba8c:	vprord zmm6,zmm6,0xc
  2bba93:	vprord zmm7,zmm7,0xc
  2bba9a:	vprord zmm4,zmm4,0xc
  2bbaa1:	vpaddd zmm0,zmm0,zmm21
  2bbaa7:	vpaddd zmm1,zmm1,zmm16
  2bbaad:	vpaddd zmm2,zmm2,zmm31
  2bbab3:	vpaddd zmm3,zmm3,zmm17
  2bbab9:	vpaddd zmm0,zmm0,zmm5
  2bbabf:	vpaddd zmm1,zmm1,zmm6
  2bbac5:	vpaddd zmm2,zmm2,zmm7
  2bbacb:	vpaddd zmm3,zmm3,zmm4
  2bbad1:	vpxord zmm15,zmm15,zmm0
  2bbad7:	vpxord zmm12,zmm12,zmm1
  2bbadd:	vpxord zmm13,zmm13,zmm2
  2bbae3:	vpxord zmm14,zmm14,zmm3
  2bbae9:	vprord zmm15,zmm15,0x8
  2bbaf0:	vprord zmm12,zmm12,0x8
  2bbaf7:	vprord zmm13,zmm13,0x8
  2bbafe:	vprord zmm14,zmm14,0x8
  2bbb05:	vpaddd zmm10,zmm10,zmm15
  2bbb0b:	vpaddd zmm11,zmm11,zmm12
  2bbb11:	vpaddd zmm8,zmm8,zmm13
  2bbb17:	vpaddd zmm9,zmm9,zmm14
  2bbb1d:	vpxord zmm5,zmm5,zmm10
  2bbb23:	vpxord zmm6,zmm6,zmm11
  2bbb29:	vpxord zmm7,zmm7,zmm8
  2bbb2f:	vpxord zmm4,zmm4,zmm9
  2bbb35:	vprord zmm5,zmm5,0x7
  2bbb3c:	vprord zmm6,zmm6,0x7
  2bbb43:	vprord zmm7,zmm7,0x7
  2bbb4a:	vprord zmm4,zmm4,0x7
  2bbb51:	vpaddd zmm0,zmm0,zmm26
  2bbb57:	vpaddd zmm1,zmm1,zmm28
  2bbb5d:	vpaddd zmm2,zmm2,zmm30
  2bbb63:	vpaddd zmm3,zmm3,zmm29
  2bbb69:	vpaddd zmm0,zmm0,zmm4
  2bbb6f:	vpaddd zmm1,zmm1,zmm5
  2bbb75:	vpaddd zmm2,zmm2,zmm6
  2bbb7b:	vpaddd zmm3,zmm3,zmm7
  2bbb81:	vpxord zmm12,zmm12,zmm0
  2bbb87:	vpxord zmm13,zmm13,zmm1
  2bbb8d:	vpxord zmm14,zmm14,zmm2
  2bbb93:	vpxord zmm15,zmm15,zmm3
  2bbb99:	vprord zmm12,zmm12,0x10
  2bbba0:	vprord zmm13,zmm13,0x10
  2bbba7:	vprord zmm14,zmm14,0x10
  2bbbae:	vprord zmm15,zmm15,0x10
  2bbbb5:	vpaddd zmm8,zmm8,zmm12
  2bbbbb:	vpaddd zmm9,zmm9,zmm13
  2bbbc1:	vpaddd zmm10,zmm10,zmm14
  2bbbc7:	vpaddd zmm11,zmm11,zmm15
  2bbbcd:	vpxord zmm4,zmm4,zmm8
  2bbbd3:	vpxord zmm5,zmm5,zmm9
  2bbbd9:	vpxord zmm6,zmm6,zmm10
  2bbbdf:	vpxord zmm7,zmm7,zmm11
  2bbbe5:	vprord zmm4,zmm4,0xc
  2bbbec:	vprord zmm5,zmm5,0xc
  2bbbf3:	vprord zmm6,zmm6,0xc
  2bbbfa:	vprord zmm7,zmm7,0xc
  2bbc01:	vpaddd zmm0,zmm0,zmm23
  2bbc07:	vpaddd zmm1,zmm1,zmm25
  2bbc0d:	vpaddd zmm2,zmm2,zmm19
  2bbc13:	vpaddd zmm3,zmm3,zmm31
  2bbc19:	vpaddd zmm0,zmm0,zmm4
  2bbc1f:	vpaddd zmm1,zmm1,zmm5
  2bbc25:	vpaddd zmm2,zmm2,zmm6
  2bbc2b:	vpaddd zmm3,zmm3,zmm7
  2bbc31:	vpxord zmm12,zmm12,zmm0
  2bbc37:	vpxord zmm13,zmm13,zmm1
  2bbc3d:	vpxord zmm14,zmm14,zmm2
  2bbc43:	vpxord zmm15,zmm15,zmm3
  2bbc49:	vprord zmm12,zmm12,0x8
  2bbc50:	vprord zmm13,zmm13,0x8
  2bbc57:	vprord zmm14,zmm14,0x8
  2bbc5e:	vprord zmm15,zmm15,0x8
  2bbc65:	vpaddd zmm8,zmm8,zmm12
  2bbc6b:	vpaddd zmm9,zmm9,zmm13
  2bbc71:	vpaddd zmm10,zmm10,zmm14
  2bbc77:	vpaddd zmm11,zmm11,zmm15
  2bbc7d:	vpxord zmm4,zmm4,zmm8
  2bbc83:	vpxord zmm5,zmm5,zmm9
  2bbc89:	vpxord zmm6,zmm6,zmm10
  2bbc8f:	vpxord zmm7,zmm7,zmm11
  2bbc95:	vprord zmm4,zmm4,0x7
  2bbc9c:	vprord zmm5,zmm5,0x7
  2bbca3:	vprord zmm6,zmm6,0x7
  2bbcaa:	vprord zmm7,zmm7,0x7
  2bbcb1:	vpaddd zmm0,zmm0,zmm20
  2bbcb7:	vpaddd zmm1,zmm1,zmm27
  2bbcbd:	vpaddd zmm2,zmm2,zmm21
  2bbcc3:	vpaddd zmm3,zmm3,zmm17
  2bbcc9:	vpaddd zmm0,zmm0,zmm5
  2bbccf:	vpaddd zmm1,zmm1,zmm6
  2bbcd5:	vpaddd zmm2,zmm2,zmm7
  2bbcdb:	vpaddd zmm3,zmm3,zmm4
  2bbce1:	vpxord zmm15,zmm15,zmm0
  2bbce7:	vpxord zmm12,zmm12,zmm1
  2bbced:	vpxord zmm13,zmm13,zmm2
  2bbcf3:	vpxord zmm14,zmm14,zmm3
  2bbcf9:	vprord zmm15,zmm15,0x10
  2bbd00:	vprord zmm12,zmm12,0x10
  2bbd07:	vprord zmm13,zmm13,0x10
  2bbd0e:	vprord zmm14,zmm14,0x10
  2bbd15:	vpaddd zmm10,zmm10,zmm15
  2bbd1b:	vpaddd zmm11,zmm11,zmm12
  2bbd21:	vpaddd zmm8,zmm8,zmm13
  2bbd27:	vpaddd zmm9,zmm9,zmm14
  2bbd2d:	vpxord zmm5,zmm5,zmm10
  2bbd33:	vpxord zmm6,zmm6,zmm11
  2bbd39:	vpxord zmm7,zmm7,zmm8
  2bbd3f:	vpxord zmm4,zmm4,zmm9
  2bbd45:	vprord zmm5,zmm5,0xc
  2bbd4c:	vprord zmm6,zmm6,0xc
  2bbd53:	vprord zmm7,zmm7,0xc
  2bbd5a:	vprord zmm4,zmm4,0xc
  2bbd61:	vpaddd zmm0,zmm0,zmm16
  2bbd67:	vpaddd zmm1,zmm1,zmm18
  2bbd6d:	vpaddd zmm2,zmm2,zmm24
  2bbd73:	vpaddd zmm3,zmm3,zmm22
  2bbd79:	vpaddd zmm0,zmm0,zmm5
  2bbd7f:	vpaddd zmm1,zmm1,zmm6
  2bbd85:	vpaddd zmm2,zmm2,zmm7
  2bbd8b:	vpaddd zmm3,zmm3,zmm4
  2bbd91:	vpxord zmm15,zmm15,zmm0
  2bbd97:	vpxord zmm12,zmm12,zmm1
  2bbd9d:	vpxord zmm13,zmm13,zmm2
  2bbda3:	vpxord zmm14,zmm14,zmm3
  2bbda9:	vprord zmm15,zmm15,0x8
  2bbdb0:	vprord zmm12,zmm12,0x8
  2bbdb7:	vprord zmm13,zmm13,0x8
  2bbdbe:	vprord zmm14,zmm14,0x8
  2bbdc5:	vpaddd zmm10,zmm10,zmm15
  2bbdcb:	vpaddd zmm11,zmm11,zmm12
  2bbdd1:	vpaddd zmm8,zmm8,zmm13
  2bbdd7:	vpaddd zmm9,zmm9,zmm14
  2bbddd:	vpxord zmm5,zmm5,zmm10
  2bbde3:	vpxord zmm6,zmm6,zmm11
  2bbde9:	vpxord zmm7,zmm7,zmm8
  2bbdef:	vpxord zmm4,zmm4,zmm9
  2bbdf5:	vprord zmm5,zmm5,0x7
  2bbdfc:	vprord zmm6,zmm6,0x7
  2bbe03:	vprord zmm7,zmm7,0x7
  2bbe0a:	vprord zmm4,zmm4,0x7
  2bbe11:	vpaddd zmm0,zmm0,zmm28
  2bbe17:	vpaddd zmm1,zmm1,zmm25
  2bbe1d:	vpaddd zmm2,zmm2,zmm31
  2bbe23:	vpaddd zmm3,zmm3,zmm30
  2bbe29:	vpaddd zmm0,zmm0,zmm4
  2bbe2f:	vpaddd zmm1,zmm1,zmm5
  2bbe35:	vpaddd zmm2,zmm2,zmm6
  2bbe3b:	vpaddd zmm3,zmm3,zmm7
  2bbe41:	vpxord zmm12,zmm12,zmm0
  2bbe47:	vpxord zmm13,zmm13,zmm1
  2bbe4d:	vpxord zmm14,zmm14,zmm2
  2bbe53:	vpxord zmm15,zmm15,zmm3
  2bbe59:	vprord zmm12,zmm12,0x10
  2bbe60:	vprord zmm13,zmm13,0x10
  2bbe67:	vprord zmm14,zmm14,0x10
  2bbe6e:	vprord zmm15,zmm15,0x10
  2bbe75:	vpaddd zmm8,zmm8,zmm12
  2bbe7b:	vpaddd zmm9,zmm9,zmm13
  2bbe81:	vpaddd zmm10,zmm10,zmm14
  2bbe87:	vpaddd zmm11,zmm11,zmm15
  2bbe8d:	vpxord zmm4,zmm4,zmm8
  2bbe93:	vpxord zmm5,zmm5,zmm9
  2bbe99:	vpxord zmm6,zmm6,zmm10
  2bbe9f:	vpxord zmm7,zmm7,zmm11
  2bbea5:	vprord zmm4,zmm4,0xc
  2bbeac:	vprord zmm5,zmm5,0xc
  2bbeb3:	vprord zmm6,zmm6,0xc
  2bbeba:	vprord zmm7,zmm7,0xc
  2bbec1:	vpaddd zmm0,zmm0,zmm29
  2bbec7:	vpaddd zmm1,zmm1,zmm27
  2bbecd:	vpaddd zmm2,zmm2,zmm26
  2bbed3:	vpaddd zmm3,zmm3,zmm24
  2bbed9:	vpaddd zmm0,zmm0,zmm4
  2bbedf:	vpaddd zmm1,zmm1,zmm5
  2bbee5:	vpaddd zmm2,zmm2,zmm6
  2bbeeb:	vpaddd zmm3,zmm3,zmm7
  2bbef1:	vpxord zmm12,zmm12,zmm0
  2bbef7:	vpxord zmm13,zmm13,zmm1
  2bbefd:	vpxord zmm14,zmm14,zmm2
  2bbf03:	vpxord zmm15,zmm15,zmm3
  2bbf09:	vprord zmm12,zmm12,0x8
  2bbf10:	vprord zmm13,zmm13,0x8
  2bbf17:	vprord zmm14,zmm14,0x8
  2bbf1e:	vprord zmm15,zmm15,0x8
  2bbf25:	vpaddd zmm8,zmm8,zmm12
  2bbf2b:	vpaddd zmm9,zmm9,zmm13
  2bbf31:	vpaddd zmm10,zmm10,zmm14
  2bbf37:	vpaddd zmm11,zmm11,zmm15
  2bbf3d:	vpxord zmm4,zmm4,zmm8
  2bbf43:	vpxord zmm5,zmm5,zmm9
  2bbf49:	vpxord zmm6,zmm6,zmm10
  2bbf4f:	vpxord zmm7,zmm7,zmm11
  2bbf55:	vprord zmm4,zmm4,0x7
  2bbf5c:	vprord zmm5,zmm5,0x7
  2bbf63:	vprord zmm6,zmm6,0x7
  2bbf6a:	vprord zmm7,zmm7,0x7
  2bbf71:	vpaddd zmm0,zmm0,zmm23
  2bbf77:	vpaddd zmm1,zmm1,zmm21
  2bbf7d:	vpaddd zmm2,zmm2,zmm16
  2bbf83:	vpaddd zmm3,zmm3,zmm22
  2bbf89:	vpaddd zmm0,zmm0,zmm5
  2bbf8f:	vpaddd zmm1,zmm1,zmm6
  2bbf95:	vpaddd zmm2,zmm2,zmm7
  2bbf9b:	vpaddd zmm3,zmm3,zmm4
  2bbfa1:	vpxord zmm15,zmm15,zmm0
  2bbfa7:	vpxord zmm12,zmm12,zmm1
  2bbfad:	vpxord zmm13,zmm13,zmm2
  2bbfb3:	vpxord zmm14,zmm14,zmm3
  2bbfb9:	vprord zmm15,zmm15,0x10
  2bbfc0:	vprord zmm12,zmm12,0x10
  2bbfc7:	vprord zmm13,zmm13,0x10
  2bbfce:	vprord zmm14,zmm14,0x10
  2bbfd5:	vpaddd zmm10,zmm10,zmm15
  2bbfdb:	vpaddd zmm11,zmm11,zmm12
  2bbfe1:	vpaddd zmm8,zmm8,zmm13
  2bbfe7:	vpaddd zmm9,zmm9,zmm14
  2bbfed:	vpxord zmm5,zmm5,zmm10
  2bbff3:	vpxord zmm6,zmm6,zmm11
  2bbff9:	vpxord zmm7,zmm7,zmm8
  2bbfff:	vpxord zmm4,zmm4,zmm9
  2bc005:	vprord zmm5,zmm5,0xc
  2bc00c:	vprord zmm6,zmm6,0xc
  2bc013:	vprord zmm7,zmm7,0xc
  2bc01a:	vprord zmm4,zmm4,0xc
  2bc021:	vpaddd zmm0,zmm0,zmm18
  2bc027:	vpaddd zmm1,zmm1,zmm19
  2bc02d:	vpaddd zmm2,zmm2,zmm17
  2bc033:	vpaddd zmm3,zmm3,zmm20
  2bc039:	vpaddd zmm0,zmm0,zmm5
  2bc03f:	vpaddd zmm1,zmm1,zmm6
  2bc045:	vpaddd zmm2,zmm2,zmm7
  2bc04b:	vpaddd zmm3,zmm3,zmm4
  2bc051:	vpxord zmm15,zmm15,zmm0
  2bc057:	vpxord zmm12,zmm12,zmm1
  2bc05d:	vpxord zmm13,zmm13,zmm2
  2bc063:	vpxord zmm14,zmm14,zmm3
  2bc069:	vprord zmm15,zmm15,0x8
  2bc070:	vprord zmm12,zmm12,0x8
  2bc077:	vprord zmm13,zmm13,0x8
  2bc07e:	vprord zmm14,zmm14,0x8
  2bc085:	vpaddd zmm10,zmm10,zmm15
  2bc08b:	vpaddd zmm11,zmm11,zmm12
  2bc091:	vpaddd zmm8,zmm8,zmm13
  2bc097:	vpaddd zmm9,zmm9,zmm14
  2bc09d:	vpxord zmm5,zmm5,zmm10
  2bc0a3:	vpxord zmm6,zmm6,zmm11
  2bc0a9:	vpxord zmm7,zmm7,zmm8
  2bc0af:	vpxord zmm4,zmm4,zmm9
  2bc0b5:	vprord zmm5,zmm5,0x7
  2bc0bc:	vprord zmm6,zmm6,0x7
  2bc0c3:	vprord zmm7,zmm7,0x7
  2bc0ca:	vprord zmm4,zmm4,0x7
  2bc0d1:	vpaddd zmm0,zmm0,zmm25
  2bc0d7:	vpaddd zmm1,zmm1,zmm27
  2bc0dd:	vpaddd zmm2,zmm2,zmm24
  2bc0e3:	vpaddd zmm3,zmm3,zmm31
  2bc0e9:	vpaddd zmm0,zmm0,zmm4
  2bc0ef:	vpaddd zmm1,zmm1,zmm5
  2bc0f5:	vpaddd zmm2,zmm2,zmm6
  2bc0fb:	vpaddd zmm3,zmm3,zmm7
  2bc101:	vpxord zmm12,zmm12,zmm0
  2bc107:	vpxord zmm13,zmm13,zmm1
  2bc10d:	vpxord zmm14,zmm14,zmm2
  2bc113:	vpxord zmm15,zmm15,zmm3
  2bc119:	vprord zmm12,zmm12,0x10
  2bc120:	vprord zmm13,zmm13,0x10
  2bc127:	vprord zmm14,zmm14,0x10
  2bc12e:	vprord zmm15,zmm15,0x10
  2bc135:	vpaddd zmm8,zmm8,zmm12
  2bc13b:	vpaddd zmm9,zmm9,zmm13
  2bc141:	vpaddd zmm10,zmm10,zmm14
  2bc147:	vpaddd zmm11,zmm11,zmm15
  2bc14d:	vpxord zmm4,zmm4,zmm8
  2bc153:	vpxord zmm5,zmm5,zmm9
  2bc159:	vpxord zmm6,zmm6,zmm10
  2bc15f:	vpxord zmm7,zmm7,zmm11
  2bc165:	vprord zmm4,zmm4,0xc
  2bc16c:	vprord zmm5,zmm5,0xc
  2bc173:	vprord zmm6,zmm6,0xc
  2bc17a:	vprord zmm7,zmm7,0xc
  2bc181:	vpaddd zmm0,zmm0,zmm30
  2bc187:	vpaddd zmm1,zmm1,zmm21
  2bc18d:	vpaddd zmm2,zmm2,zmm28
  2bc193:	vpaddd zmm3,zmm3,zmm17
  2bc199:	vpaddd zmm0,zmm0,zmm4
  2bc19f:	vpaddd zmm1,zmm1,zmm5
  2bc1a5:	vpaddd zmm2,zmm2,zmm6
  2bc1ab:	vpaddd zmm3,zmm3,zmm7
  2bc1b1:	vpxord zmm12,zmm12,zmm0
  2bc1b7:	vpxord zmm13,zmm13,zmm1
  2bc1bd:	vpxord zmm14,zmm14,zmm2
  2bc1c3:	vpxord zmm15,zmm15,zmm3
  2bc1c9:	vprord zmm12,zmm12,0x8
  2bc1d0:	vprord zmm13,zmm13,0x8
  2bc1d7:	vprord zmm14,zmm14,0x8
  2bc1de:	vprord zmm15,zmm15,0x8
  2bc1e5:	vpaddd zmm8,zmm8,zmm12
  2bc1eb:	vpaddd zmm9,zmm9,zmm13
  2bc1f1:	vpaddd zmm10,zmm10,zmm14
  2bc1f7:	vpaddd zmm11,zmm11,zmm15
  2bc1fd:	vpxord zmm4,zmm4,zmm8
  2bc203:	vpxord zmm5,zmm5,zmm9
  2bc209:	vpxord zmm6,zmm6,zmm10
  2bc20f:	vpxord zmm7,zmm7,zmm11
  2bc215:	vprord zmm4,zmm4,0x7
  2bc21c:	vprord zmm5,zmm5,0x7
  2bc223:	vprord zmm6,zmm6,0x7
  2bc22a:	vprord zmm7,zmm7,0x7
  2bc231:	vpaddd zmm0,zmm0,zmm29
  2bc237:	vpaddd zmm1,zmm1,zmm16
  2bc23d:	vpaddd zmm2,zmm2,zmm18
  2bc243:	vpaddd zmm3,zmm3,zmm20
  2bc249:	vpaddd zmm0,zmm0,zmm5
  2bc24f:	vpaddd zmm1,zmm1,zmm6
  2bc255:	vpaddd zmm2,zmm2,zmm7
  2bc25b:	vpaddd zmm3,zmm3,zmm4
  2bc261:	vpxord zmm15,zmm15,zmm0
  2bc267:	vpxord zmm12,zmm12,zmm1
  2bc26d:	vpxord zmm13,zmm13,zmm2
  2bc273:	vpxord zmm14,zmm14,zmm3
  2bc279:	vprord zmm15,zmm15,0x10
  2bc280:	vprord zmm12,zmm12,0x10
  2bc287:	vprord zmm13,zmm13,0x10
  2bc28e:	vprord zmm14,zmm14,0x10
  2bc295:	vpaddd zmm10,zmm10,zmm15
  2bc29b:	vpaddd zmm11,zmm11,zmm12
  2bc2a1:	vpaddd zmm8,zmm8,zmm13
  2bc2a7:	vpaddd zmm9,zmm9,zmm14
  2bc2ad:	vpxord zmm5,zmm5,zmm10
  2bc2b3:	vpxord zmm6,zmm6,zmm11
  2bc2b9:	vpxord zmm7,zmm7,zmm8
  2bc2bf:	vpxord zmm4,zmm4,zmm9
  2bc2c5:	vprord zmm5,zmm5,0xc
  2bc2cc:	vprord zmm6,zmm6,0xc
  2bc2d3:	vprord zmm7,zmm7,0xc
  2bc2da:	vprord zmm4,zmm4,0xc
  2bc2e1:	vpaddd zmm0,zmm0,zmm19
  2bc2e7:	vpaddd zmm1,zmm1,zmm26
  2bc2ed:	vpaddd zmm2,zmm2,zmm22
  2bc2f3:	vpaddd zmm3,zmm3,zmm23
  2bc2f9:	vpaddd zmm0,zmm0,zmm5
  2bc2ff:	vpaddd zmm1,zmm1,zmm6
  2bc305:	vpaddd zmm2,zmm2,zmm7
  2bc30b:	vpaddd zmm3,zmm3,zmm4
  2bc311:	vpxord zmm15,zmm15,zmm0
  2bc317:	vpxord zmm12,zmm12,zmm1
  2bc31d:	vpxord zmm13,zmm13,zmm2
  2bc323:	vpxord zmm14,zmm14,zmm3
  2bc329:	vprord zmm15,zmm15,0x8
  2bc330:	vprord zmm12,zmm12,0x8
  2bc337:	vprord zmm13,zmm13,0x8
  2bc33e:	vprord zmm14,zmm14,0x8
  2bc345:	vpaddd zmm10,zmm10,zmm15
  2bc34b:	vpaddd zmm11,zmm11,zmm12
  2bc351:	vpaddd zmm8,zmm8,zmm13
  2bc357:	vpaddd zmm9,zmm9,zmm14
  2bc35d:	vpxord zmm5,zmm5,zmm10
  2bc363:	vpxord zmm6,zmm6,zmm11
  2bc369:	vpxord zmm7,zmm7,zmm8
  2bc36f:	vpxord zmm4,zmm4,zmm9
  2bc375:	vprord zmm5,zmm5,0x7
  2bc37c:	vprord zmm6,zmm6,0x7
  2bc383:	vprord zmm7,zmm7,0x7
  2bc38a:	vprord zmm4,zmm4,0x7
  2bc391:	vpaddd zmm0,zmm0,zmm27
  2bc397:	vpaddd zmm1,zmm1,zmm21
  2bc39d:	vpaddd zmm2,zmm2,zmm17
  2bc3a3:	vpaddd zmm3,zmm3,zmm24
  2bc3a9:	vpaddd zmm0,zmm0,zmm4
  2bc3af:	vpaddd zmm1,zmm1,zmm5
  2bc3b5:	vpaddd zmm2,zmm2,zmm6
  2bc3bb:	vpaddd zmm3,zmm3,zmm7
  2bc3c1:	vpxord zmm12,zmm12,zmm0
  2bc3c7:	vpxord zmm13,zmm13,zmm1
  2bc3cd:	vpxord zmm14,zmm14,zmm2
  2bc3d3:	vpxord zmm15,zmm15,zmm3
  2bc3d9:	vprord zmm12,zmm12,0x10
  2bc3e0:	vprord zmm13,zmm13,0x10
  2bc3e7:	vprord zmm14,zmm14,0x10
  2bc3ee:	vprord zmm15,zmm15,0x10
  2bc3f5:	vpaddd zmm8,zmm8,zmm12
  2bc3fb:	vpaddd zmm9,zmm9,zmm13
  2bc401:	vpaddd zmm10,zmm10,zmm14
  2bc407:	vpaddd zmm11,zmm11,zmm15
  2bc40d:	vpxord zmm4,zmm4,zmm8
  2bc413:	vpxord zmm5,zmm5,zmm9
  2bc419:	vpxord zmm6,zmm6,zmm10
  2bc41f:	vpxord zmm7,zmm7,zmm11
  2bc425:	vprord zmm4,zmm4,0xc
  2bc42c:	vprord zmm5,zmm5,0xc
  2bc433:	vprord zmm6,zmm6,0xc
  2bc43a:	vprord zmm7,zmm7,0xc
  2bc441:	vpaddd zmm0,zmm0,zmm31
  2bc447:	vpaddd zmm1,zmm1,zmm16
  2bc44d:	vpaddd zmm2,zmm2,zmm25
  2bc453:	vpaddd zmm3,zmm3,zmm22
  2bc459:	vpaddd zmm0,zmm0,zmm4
  2bc45f:	vpaddd zmm1,zmm1,zmm5
  2bc465:	vpaddd zmm2,zmm2,zmm6
  2bc46b:	vpaddd zmm3,zmm3,zmm7
  2bc471:	vpxord zmm12,zmm12,zmm0
  2bc477:	vpxord zmm13,zmm13,zmm1
  2bc47d:	vpxord zmm14,zmm14,zmm2
  2bc483:	vpxord zmm15,zmm15,zmm3
  2bc489:	vprord zmm12,zmm12,0x8
  2bc490:	vprord zmm13,zmm13,0x8
  2bc497:	vprord zmm14,zmm14,0x8
  2bc49e:	vprord zmm15,zmm15,0x8
  2bc4a5:	vpaddd zmm8,zmm8,zmm12
  2bc4ab:	vpaddd zmm9,zmm9,zmm13
  2bc4b1:	vpaddd zmm10,zmm10,zmm14
  2bc4b7:	vpaddd zmm11,zmm11,zmm15
  2bc4bd:	vpxord zmm4,zmm4,zmm8
  2bc4c3:	vpxord zmm5,zmm5,zmm9
  2bc4c9:	vpxord zmm6,zmm6,zmm10
  2bc4cf:	vpxord zmm7,zmm7,zmm11
  2bc4d5:	vprord zmm4,zmm4,0x7
  2bc4dc:	vprord zmm5,zmm5,0x7
  2bc4e3:	vprord zmm6,zmm6,0x7
  2bc4ea:	vprord zmm7,zmm7,0x7
  2bc4f1:	vpaddd zmm0,zmm0,zmm30
  2bc4f7:	vpaddd zmm1,zmm1,zmm18
  2bc4fd:	vpaddd zmm2,zmm2,zmm19
  2bc503:	vpaddd zmm3,zmm3,zmm23
  2bc509:	vpaddd zmm0,zmm0,zmm5
  2bc50f:	vpaddd zmm1,zmm1,zmm6
  2bc515:	vpaddd zmm2,zmm2,zmm7
  2bc51b:	vpaddd zmm3,zmm3,zmm4
  2bc521:	vpxord zmm15,zmm15,zmm0
  2bc527:	vpxord zmm12,zmm12,zmm1
  2bc52d:	vpxord zmm13,zmm13,zmm2
  2bc533:	vpxord zmm14,zmm14,zmm3
  2bc539:	vprord zmm15,zmm15,0x10
  2bc540:	vprord zmm12,zmm12,0x10
  2bc547:	vprord zmm13,zmm13,0x10
  2bc54e:	vprord zmm14,zmm14,0x10
  2bc555:	vpaddd zmm10,zmm10,zmm15
  2bc55b:	vpaddd zmm11,zmm11,zmm12
  2bc561:	vpaddd zmm8,zmm8,zmm13
  2bc567:	vpaddd zmm9,zmm9,zmm14
  2bc56d:	vpxord zmm5,zmm5,zmm10
  2bc573:	vpxord zmm6,zmm6,zmm11
  2bc579:	vpxord zmm7,zmm7,zmm8
  2bc57f:	vpxord zmm4,zmm4,zmm9
  2bc585:	vprord zmm5,zmm5,0xc
  2bc58c:	vprord zmm6,zmm6,0xc
  2bc593:	vprord zmm7,zmm7,0xc
  2bc59a:	vprord zmm4,zmm4,0xc
  2bc5a1:	vpaddd zmm0,zmm0,zmm26
  2bc5a7:	vpaddd zmm1,zmm1,zmm28
  2bc5ad:	vpaddd zmm2,zmm2,zmm20
  2bc5b3:	vpaddd zmm3,zmm3,zmm29
  2bc5b9:	vpaddd zmm0,zmm0,zmm5
  2bc5bf:	vpaddd zmm1,zmm1,zmm6
  2bc5c5:	vpaddd zmm2,zmm2,zmm7
  2bc5cb:	vpaddd zmm3,zmm3,zmm4
  2bc5d1:	vpxord zmm15,zmm15,zmm0
  2bc5d7:	vpxord zmm12,zmm12,zmm1
  2bc5dd:	vpxord zmm13,zmm13,zmm2
  2bc5e3:	vpxord zmm14,zmm14,zmm3
  2bc5e9:	vprord zmm15,zmm15,0x8
  2bc5f0:	vprord zmm12,zmm12,0x8
  2bc5f7:	vprord zmm13,zmm13,0x8
  2bc5fe:	vprord zmm14,zmm14,0x8
  2bc605:	vpaddd zmm10,zmm10,zmm15
  2bc60b:	vpaddd zmm11,zmm11,zmm12
  2bc611:	vpaddd zmm8,zmm8,zmm13
  2bc617:	vpaddd zmm9,zmm9,zmm14
  2bc61d:	vpxord zmm5,zmm5,zmm10
  2bc623:	vpxord zmm6,zmm6,zmm11
  2bc629:	vpxord zmm7,zmm7,zmm8
  2bc62f:	vpxord zmm4,zmm4,zmm9
  2bc635:	vprord zmm5,zmm5,0x7
  2bc63c:	vprord zmm6,zmm6,0x7
  2bc643:	vprord zmm7,zmm7,0x7
  2bc64a:	vprord zmm4,zmm4,0x7
  2bc651:	vpxord zmm0,zmm0,zmm8
  2bc657:	vpxord zmm1,zmm1,zmm9
  2bc65d:	vpxord zmm2,zmm2,zmm10
  2bc663:	vpxord zmm3,zmm3,zmm11
  2bc669:	vpxord zmm4,zmm4,zmm12
  2bc66f:	vpxord zmm5,zmm5,zmm13
  2bc675:	vpxord zmm6,zmm6,zmm14
  2bc67b:	vpxord zmm7,zmm7,zmm15
  2bc681:	movzx  eax,BYTE PTR [rbp+0x38]
  2bc685:	jne    2baf20 <_blake3_servil_hash_many_avx512+0x120>
  2bc68b:	mov    rbx,QWORD PTR [rbp+0x50]
  2bc68f:	vpunpckldq zmm16,zmm0,zmm1
  2bc695:	vpunpckhdq zmm17,zmm0,zmm1
  2bc69b:	vpunpckldq zmm18,zmm2,zmm3
  2bc6a1:	vpunpckhdq zmm19,zmm2,zmm3
  2bc6a7:	vpunpckldq zmm20,zmm4,zmm5
  2bc6ad:	vpunpckhdq zmm21,zmm4,zmm5
  2bc6b3:	vpunpckldq zmm22,zmm6,zmm7
  2bc6b9:	vpunpckhdq zmm23,zmm6,zmm7
  2bc6bf:	vpunpcklqdq zmm0,zmm16,zmm18
  2bc6c5:	vpunpckhqdq zmm1,zmm16,zmm18
  2bc6cb:	vpunpcklqdq zmm2,zmm17,zmm19
  2bc6d1:	vpunpckhqdq zmm3,zmm17,zmm19
  2bc6d7:	vpunpcklqdq zmm4,zmm20,zmm22
  2bc6dd:	vpunpckhqdq zmm5,zmm20,zmm22
  2bc6e3:	vpunpcklqdq zmm6,zmm21,zmm23
  2bc6e9:	vpunpckhqdq zmm7,zmm21,zmm23
  2bc6ef:	vshufi32x4 zmm16,zmm0,zmm4,0x88
  2bc6f6:	vshufi32x4 zmm17,zmm1,zmm5,0x88
  2bc6fd:	vshufi32x4 zmm18,zmm2,zmm6,0x88
  2bc704:	vshufi32x4 zmm19,zmm3,zmm7,0x88
  2bc70b:	vshufi32x4 zmm20,zmm0,zmm4,0xdd
  2bc712:	vshufi32x4 zmm21,zmm1,zmm5,0xdd
  2bc719:	vshufi32x4 zmm22,zmm2,zmm6,0xdd
  2bc720:	vshufi32x4 zmm23,zmm3,zmm7,0xdd
  2bc727:	vshufi32x4 zmm0,zmm16,zmm17,0x88
  2bc72e:	vshufi32x4 zmm1,zmm18,zmm19,0x88
  2bc735:	vshufi32x4 zmm2,zmm20,zmm21,0x88
  2bc73c:	vshufi32x4 zmm3,zmm22,zmm23,0x88
  2bc743:	vshufi32x4 zmm4,zmm16,zmm17,0xdd
  2bc74a:	vshufi32x4 zmm5,zmm18,zmm19,0xdd
  2bc751:	vshufi32x4 zmm6,zmm20,zmm21,0xdd
  2bc758:	vshufi32x4 zmm7,zmm22,zmm23,0xdd
  2bc75f:	vmovdqu32 ZMMWORD PTR [rbx],zmm0
  2bc765:	vmovdqu32 ZMMWORD PTR [rbx+0x40],zmm1
  2bc76c:	vmovdqu32 ZMMWORD PTR [rbx+0x80],zmm2
  2bc773:	vmovdqu32 ZMMWORD PTR [rbx+0xc0],zmm3
  2bc77a:	vmovdqu32 ZMMWORD PTR [rbx+0x100],zmm4
  2bc781:	vmovdqu32 ZMMWORD PTR [rbx+0x140],zmm5
  2bc788:	vmovdqu32 ZMMWORD PTR [rbx+0x180],zmm6
  2bc78f:	vmovdqu32 ZMMWORD PTR [rbx+0x1c0],zmm7
  2bc796:	vmovdqa32 zmm0,ZMMWORD PTR [rsp]
  2bc79d:	vmovdqa32 zmm1,ZMMWORD PTR [rsp+0x40]
  2bc7a5:	vmovdqa32 zmm2,zmm0
  2bc7ab:	vpaddd zmm2{k1},zmm0,DWORD BCST [rip+0xffffffffffd80fcf]        # 3d784 <ADD16>
  2bc7b5:	vpcmpltud k2,zmm2,zmm0
  2bc7bc:	vpaddd zmm1{k2},zmm1,DWORD BCST [rip+0xffffffffffd80fba]        # 3d780 <ADD1>
  2bc7c6:	vmovdqa32 ZMMWORD PTR [rsp],zmm2
  2bc7cd:	vmovdqa32 ZMMWORD PTR [rsp+0x40],zmm1
  2bc7d5:	add    rdi,0x80
  2bc7dc:	add    rbx,0x200
  2bc7e3:	mov    QWORD PTR [rbp+0x50],rbx
  2bc7e7:	sub    rsi,0x10
  2bc7eb:	cmp    rsi,0x10
  2bc7ef:	jae    2baebf <_blake3_servil_hash_many_avx512+0xbf>
  2bc7f5:	test   rsi,rsi
  2bc7f8:	jne    2bc840 <_blake3_servil_hash_many_avx512+0x1a40>
  2bc7fa:	vzeroupper
  2bc7fd:	mov    rsp,rbp
  2bc800:	pop    rbp
  2bc801:	pop    rbx
  2bc802:	pop    r12
  2bc804:	pop    r13
  2bc806:	pop    r14
  2bc808:	pop    r15
  2bc80a:	ret
  2bc80b:	nop    WORD PTR [rax+rax*1+0x0]
  2bc814:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2bc81f:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2bc82a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2bc835:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2bc840:	test   esi,0x8
  2bc846:	je     2bdddd <_blake3_servil_hash_many_avx512+0x2fdd>
  2bc84c:	vpbroadcastd ymm0,DWORD PTR [rcx]
  2bc851:	vpbroadcastd ymm1,DWORD PTR [rcx+0x4]
  2bc857:	vpbroadcastd ymm2,DWORD PTR [rcx+0x8]
  2bc85d:	vpbroadcastd ymm3,DWORD PTR [rcx+0xc]
  2bc863:	vpbroadcastd ymm4,DWORD PTR [rcx+0x10]
  2bc869:	vpbroadcastd ymm5,DWORD PTR [rcx+0x14]
  2bc86f:	vpbroadcastd ymm6,DWORD PTR [rcx+0x18]
  2bc875:	vpbroadcastd ymm7,DWORD PTR [rcx+0x1c]
  2bc87b:	mov    r8,QWORD PTR [rdi]
  2bc87e:	mov    r9,QWORD PTR [rdi+0x8]
  2bc882:	mov    r10,QWORD PTR [rdi+0x10]
  2bc886:	mov    r11,QWORD PTR [rdi+0x18]
  2bc88a:	mov    r12,QWORD PTR [rdi+0x20]
  2bc88e:	mov    r13,QWORD PTR [rdi+0x28]
  2bc892:	mov    r14,QWORD PTR [rdi+0x30]
  2bc896:	mov    r15,QWORD PTR [rdi+0x38]
  2bc89a:	movzx  eax,BYTE PTR [rbp+0x38]
  2bc89e:	movzx  ebx,BYTE PTR [rbp+0x40]
  2bc8a2:	or     eax,ebx
  2bc8a4:	xor    edx,edx
  2bc8a6:	movzx  ebx,BYTE PTR [rbp+0x48]
  2bc8aa:	or     ebx,eax
  2bc8ac:	add    rdx,0x40
  2bc8b0:	cmp    rdx,QWORD PTR [rsp+0x80]
  2bc8b8:	cmove  eax,ebx
  2bc8bb:	mov    DWORD PTR [rsp+0x88],eax
  2bc8c2:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2bc8c9:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x40],0x1
  2bc8d1:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x40]
  2bc8d8:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x40],0x1
  2bc8e0:	vunpcklpd ymm12,ymm8,ymm9
  2bc8e5:	vunpckhpd ymm13,ymm8,ymm9
  2bc8ea:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x40]
  2bc8f1:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x40],0x1
  2bc8f9:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x40]
  2bc900:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x40],0x1
  2bc908:	vunpcklpd ymm14,ymm10,ymm11
  2bc90d:	vunpckhpd ymm15,ymm10,ymm11
  2bc912:	vshufps ymm16,ymm12,ymm14,0x88
  2bc919:	vshufps ymm17,ymm12,ymm14,0xdd
  2bc920:	vshufps ymm18,ymm13,ymm15,0x88
  2bc927:	vshufps ymm19,ymm13,ymm15,0xdd
  2bc92e:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x30]
  2bc935:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x30],0x1
  2bc93d:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x30]
  2bc944:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x30],0x1
  2bc94c:	vunpcklpd ymm12,ymm8,ymm9
  2bc951:	vunpckhpd ymm13,ymm8,ymm9
  2bc956:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x30]
  2bc95d:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x30],0x1
  2bc965:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x30]
  2bc96c:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x30],0x1
  2bc974:	vunpcklpd ymm14,ymm10,ymm11
  2bc979:	vunpckhpd ymm15,ymm10,ymm11
  2bc97e:	vshufps ymm20,ymm12,ymm14,0x88
  2bc985:	vshufps ymm21,ymm12,ymm14,0xdd
  2bc98c:	vshufps ymm22,ymm13,ymm15,0x88
  2bc993:	vshufps ymm23,ymm13,ymm15,0xdd
  2bc99a:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2bc9a1:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x20],0x1
  2bc9a9:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x20]
  2bc9b0:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x20],0x1
  2bc9b8:	vunpcklpd ymm12,ymm8,ymm9
  2bc9bd:	vunpckhpd ymm13,ymm8,ymm9
  2bc9c2:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x20]
  2bc9c9:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x20],0x1
  2bc9d1:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x20]
  2bc9d8:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x20],0x1
  2bc9e0:	vunpcklpd ymm14,ymm10,ymm11
  2bc9e5:	vunpckhpd ymm15,ymm10,ymm11
  2bc9ea:	vshufps ymm24,ymm12,ymm14,0x88
  2bc9f1:	vshufps ymm25,ymm12,ymm14,0xdd
  2bc9f8:	vshufps ymm26,ymm13,ymm15,0x88
  2bc9ff:	vshufps ymm27,ymm13,ymm15,0xdd
  2bca06:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x10]
  2bca0d:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x10],0x1
  2bca15:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x10]
  2bca1c:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x10],0x1
  2bca24:	vunpcklpd ymm12,ymm8,ymm9
  2bca29:	vunpckhpd ymm13,ymm8,ymm9
  2bca2e:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x10]
  2bca35:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x10],0x1
  2bca3d:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x10]
  2bca44:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x10],0x1
  2bca4c:	vunpcklpd ymm14,ymm10,ymm11
  2bca51:	vunpckhpd ymm15,ymm10,ymm11
  2bca56:	vshufps ymm28,ymm12,ymm14,0x88
  2bca5d:	vshufps ymm29,ymm12,ymm14,0xdd
  2bca64:	vshufps ymm30,ymm13,ymm15,0x88
  2bca6b:	vshufps ymm31,ymm13,ymm15,0xdd
  2bca72:	vpbroadcastd ymm8,DWORD PTR [rip+0xffffffffffd80d45]        # 3d7c0 <BLAKE3_IV>
  2bca7b:	vpbroadcastd ymm9,DWORD PTR [rip+0xffffffffffd80d40]        # 3d7c4 <BLAKE3_IV_1>
  2bca84:	vpbroadcastd ymm10,DWORD PTR [rip+0xffffffffffd80d3b]        # 3d7c8 <BLAKE3_IV_2>
  2bca8d:	vpbroadcastd ymm11,DWORD PTR [rip+0xffffffffffd80d36]        # 3d7cc <BLAKE3_IV_3>
  2bca96:	vmovdqa ymm12,YMMWORD PTR [rsp]
  2bca9b:	vmovdqa ymm13,YMMWORD PTR [rsp+0x40]
  2bcaa1:	vpbroadcastd ymm14,DWORD PTR [rip+0xffffffffffd80cde]        # 3d788 <BLAKE3_BLOCK_LEN>
  2bcaaa:	vpbroadcastd ymm15,DWORD PTR [rsp+0x88]
  2bcab4:	vpaddd ymm0,ymm0,ymm16
  2bcaba:	vpaddd ymm1,ymm1,ymm18
  2bcac0:	vpaddd ymm2,ymm2,ymm20
  2bcac6:	vpaddd ymm3,ymm3,ymm22
  2bcacc:	vpaddd ymm0,ymm0,ymm4
  2bcad0:	vpaddd ymm1,ymm1,ymm5
  2bcad4:	vpaddd ymm2,ymm2,ymm6
  2bcad8:	vpaddd ymm3,ymm3,ymm7
  2bcadc:	vpxord ymm12,ymm12,ymm0
  2bcae2:	vpxord ymm13,ymm13,ymm1
  2bcae8:	vpxord ymm14,ymm14,ymm2
  2bcaee:	vpxord ymm15,ymm15,ymm3
  2bcaf4:	vprord ymm12,ymm12,0x10
  2bcafb:	vprord ymm13,ymm13,0x10
  2bcb02:	vprord ymm14,ymm14,0x10
  2bcb09:	vprord ymm15,ymm15,0x10
  2bcb10:	vpaddd ymm8,ymm8,ymm12
  2bcb15:	vpaddd ymm9,ymm9,ymm13
  2bcb1a:	vpaddd ymm10,ymm10,ymm14
  2bcb1f:	vpaddd ymm11,ymm11,ymm15
  2bcb24:	vpxord ymm4,ymm4,ymm8
  2bcb2a:	vpxord ymm5,ymm5,ymm9
  2bcb30:	vpxord ymm6,ymm6,ymm10
  2bcb36:	vpxord ymm7,ymm7,ymm11
  2bcb3c:	vprord ymm4,ymm4,0xc
  2bcb43:	vprord ymm5,ymm5,0xc
  2bcb4a:	vprord ymm6,ymm6,0xc
  2bcb51:	vprord ymm7,ymm7,0xc
  2bcb58:	vpaddd ymm0,ymm0,ymm17
  2bcb5e:	vpaddd ymm1,ymm1,ymm19
  2bcb64:	vpaddd ymm2,ymm2,ymm21
  2bcb6a:	vpaddd ymm3,ymm3,ymm23
  2bcb70:	vpaddd ymm0,ymm0,ymm4
  2bcb74:	vpaddd ymm1,ymm1,ymm5
  2bcb78:	vpaddd ymm2,ymm2,ymm6
  2bcb7c:	vpaddd ymm3,ymm3,ymm7
  2bcb80:	vpxord ymm12,ymm12,ymm0
  2bcb86:	vpxord ymm13,ymm13,ymm1
  2bcb8c:	vpxord ymm14,ymm14,ymm2
  2bcb92:	vpxord ymm15,ymm15,ymm3
  2bcb98:	vprord ymm12,ymm12,0x8
  2bcb9f:	vprord ymm13,ymm13,0x8
  2bcba6:	vprord ymm14,ymm14,0x8
  2bcbad:	vprord ymm15,ymm15,0x8
  2bcbb4:	vpaddd ymm8,ymm8,ymm12
  2bcbb9:	vpaddd ymm9,ymm9,ymm13
  2bcbbe:	vpaddd ymm10,ymm10,ymm14
  2bcbc3:	vpaddd ymm11,ymm11,ymm15
  2bcbc8:	vpxord ymm4,ymm4,ymm8
  2bcbce:	vpxord ymm5,ymm5,ymm9
  2bcbd4:	vpxord ymm6,ymm6,ymm10
  2bcbda:	vpxord ymm7,ymm7,ymm11
  2bcbe0:	vprord ymm4,ymm4,0x7
  2bcbe7:	vprord ymm5,ymm5,0x7
  2bcbee:	vprord ymm6,ymm6,0x7
  2bcbf5:	vprord ymm7,ymm7,0x7
  2bcbfc:	vpaddd ymm0,ymm0,ymm24
  2bcc02:	vpaddd ymm1,ymm1,ymm26
  2bcc08:	vpaddd ymm2,ymm2,ymm28
  2bcc0e:	vpaddd ymm3,ymm3,ymm30
  2bcc14:	vpaddd ymm0,ymm0,ymm5
  2bcc18:	vpaddd ymm1,ymm1,ymm6
  2bcc1c:	vpaddd ymm2,ymm2,ymm7
  2bcc20:	vpaddd ymm3,ymm3,ymm4
  2bcc24:	vpxord ymm15,ymm15,ymm0
  2bcc2a:	vpxord ymm12,ymm12,ymm1
  2bcc30:	vpxord ymm13,ymm13,ymm2
  2bcc36:	vpxord ymm14,ymm14,ymm3
  2bcc3c:	vprord ymm15,ymm15,0x10
  2bcc43:	vprord ymm12,ymm12,0x10
  2bcc4a:	vprord ymm13,ymm13,0x10
  2bcc51:	vprord ymm14,ymm14,0x10
  2bcc58:	vpaddd ymm10,ymm10,ymm15
  2bcc5d:	vpaddd ymm11,ymm11,ymm12
  2bcc62:	vpaddd ymm8,ymm8,ymm13
  2bcc67:	vpaddd ymm9,ymm9,ymm14
  2bcc6c:	vpxord ymm5,ymm5,ymm10
  2bcc72:	vpxord ymm6,ymm6,ymm11
  2bcc78:	vpxord ymm7,ymm7,ymm8
  2bcc7e:	vpxord ymm4,ymm4,ymm9
  2bcc84:	vprord ymm5,ymm5,0xc
  2bcc8b:	vprord ymm6,ymm6,0xc
  2bcc92:	vprord ymm7,ymm7,0xc
  2bcc99:	vprord ymm4,ymm4,0xc
  2bcca0:	vpaddd ymm0,ymm0,ymm25
  2bcca6:	vpaddd ymm1,ymm1,ymm27
  2bccac:	vpaddd ymm2,ymm2,ymm29
  2bccb2:	vpaddd ymm3,ymm3,ymm31
  2bccb8:	vpaddd ymm0,ymm0,ymm5
  2bccbc:	vpaddd ymm1,ymm1,ymm6
  2bccc0:	vpaddd ymm2,ymm2,ymm7
  2bccc4:	vpaddd ymm3,ymm3,ymm4
  2bccc8:	vpxord ymm15,ymm15,ymm0
  2bccce:	vpxord ymm12,ymm12,ymm1
  2bccd4:	vpxord ymm13,ymm13,ymm2
  2bccda:	vpxord ymm14,ymm14,ymm3
  2bcce0:	vprord ymm15,ymm15,0x8
  2bcce7:	vprord ymm12,ymm12,0x8
  2bccee:	vprord ymm13,ymm13,0x8
  2bccf5:	vprord ymm14,ymm14,0x8
  2bccfc:	vpaddd ymm10,ymm10,ymm15
  2bcd01:	vpaddd ymm11,ymm11,ymm12
  2bcd06:	vpaddd ymm8,ymm8,ymm13
  2bcd0b:	vpaddd ymm9,ymm9,ymm14
  2bcd10:	vpxord ymm5,ymm5,ymm10
  2bcd16:	vpxord ymm6,ymm6,ymm11
  2bcd1c:	vpxord ymm7,ymm7,ymm8
  2bcd22:	vpxord ymm4,ymm4,ymm9
  2bcd28:	vprord ymm5,ymm5,0x7
  2bcd2f:	vprord ymm6,ymm6,0x7
  2bcd36:	vprord ymm7,ymm7,0x7
  2bcd3d:	vprord ymm4,ymm4,0x7
  2bcd44:	vpaddd ymm0,ymm0,ymm18
  2bcd4a:	vpaddd ymm1,ymm1,ymm19
  2bcd50:	vpaddd ymm2,ymm2,ymm23
  2bcd56:	vpaddd ymm3,ymm3,ymm20
  2bcd5c:	vpaddd ymm0,ymm0,ymm4
  2bcd60:	vpaddd ymm1,ymm1,ymm5
  2bcd64:	vpaddd ymm2,ymm2,ymm6
  2bcd68:	vpaddd ymm3,ymm3,ymm7
  2bcd6c:	vpxord ymm12,ymm12,ymm0
  2bcd72:	vpxord ymm13,ymm13,ymm1
  2bcd78:	vpxord ymm14,ymm14,ymm2
  2bcd7e:	vpxord ymm15,ymm15,ymm3
  2bcd84:	vprord ymm12,ymm12,0x10
  2bcd8b:	vprord ymm13,ymm13,0x10
  2bcd92:	vprord ymm14,ymm14,0x10
  2bcd99:	vprord ymm15,ymm15,0x10
  2bcda0:	vpaddd ymm8,ymm8,ymm12
  2bcda5:	vpaddd ymm9,ymm9,ymm13
  2bcdaa:	vpaddd ymm10,ymm10,ymm14
  2bcdaf:	vpaddd ymm11,ymm11,ymm15
  2bcdb4:	vpxord ymm4,ymm4,ymm8
  2bcdba:	vpxord ymm5,ymm5,ymm9
  2bcdc0:	vpxord ymm6,ymm6,ymm10
  2bcdc6:	vpxord ymm7,ymm7,ymm11
  2bcdcc:	vprord ymm4,ymm4,0xc
  2bcdd3:	vprord ymm5,ymm5,0xc
  2bcdda:	vprord ymm6,ymm6,0xc
  2bcde1:	vprord ymm7,ymm7,0xc
  2bcde8:	vpaddd ymm0,ymm0,ymm22
  2bcdee:	vpaddd ymm1,ymm1,ymm26
  2bcdf4:	vpaddd ymm2,ymm2,ymm16
  2bcdfa:	vpaddd ymm3,ymm3,ymm29
  2bce00:	vpaddd ymm0,ymm0,ymm4
  2bce04:	vpaddd ymm1,ymm1,ymm5
  2bce08:	vpaddd ymm2,ymm2,ymm6
  2bce0c:	vpaddd ymm3,ymm3,ymm7
  2bce10:	vpxord ymm12,ymm12,ymm0
  2bce16:	vpxord ymm13,ymm13,ymm1
  2bce1c:	vpxord ymm14,ymm14,ymm2
  2bce22:	vpxord ymm15,ymm15,ymm3
  2bce28:	vprord ymm12,ymm12,0x8
  2bce2f:	vprord ymm13,ymm13,0x8
  2bce36:	vprord ymm14,ymm14,0x8
  2bce3d:	vprord ymm15,ymm15,0x8
  2bce44:	vpaddd ymm8,ymm8,ymm12
  2bce49:	vpaddd ymm9,ymm9,ymm13
  2bce4e:	vpaddd ymm10,ymm10,ymm14
  2bce53:	vpaddd ymm11,ymm11,ymm15
  2bce58:	vpxord ymm4,ymm4,ymm8
  2bce5e:	vpxord ymm5,ymm5,ymm9
  2bce64:	vpxord ymm6,ymm6,ymm10
  2bce6a:	vpxord ymm7,ymm7,ymm11
  2bce70:	vprord ymm4,ymm4,0x7
  2bce77:	vprord ymm5,ymm5,0x7
  2bce7e:	vprord ymm6,ymm6,0x7
  2bce85:	vprord ymm7,ymm7,0x7
  2bce8c:	vpaddd ymm0,ymm0,ymm17
  2bce92:	vpaddd ymm1,ymm1,ymm28
  2bce98:	vpaddd ymm2,ymm2,ymm25
  2bce9e:	vpaddd ymm3,ymm3,ymm31
  2bcea4:	vpaddd ymm0,ymm0,ymm5
  2bcea8:	vpaddd ymm1,ymm1,ymm6
  2bceac:	vpaddd ymm2,ymm2,ymm7
  2bceb0:	vpaddd ymm3,ymm3,ymm4
  2bceb4:	vpxord ymm15,ymm15,ymm0
  2bceba:	vpxord ymm12,ymm12,ymm1
  2bcec0:	vpxord ymm13,ymm13,ymm2
  2bcec6:	vpxord ymm14,ymm14,ymm3
  2bcecc:	vprord ymm15,ymm15,0x10
  2bced3:	vprord ymm12,ymm12,0x10
  2bceda:	vprord ymm13,ymm13,0x10
  2bcee1:	vprord ymm14,ymm14,0x10
  2bcee8:	vpaddd ymm10,ymm10,ymm15
  2bceed:	vpaddd ymm11,ymm11,ymm12
  2bcef2:	vpaddd ymm8,ymm8,ymm13
  2bcef7:	vpaddd ymm9,ymm9,ymm14
  2bcefc:	vpxord ymm5,ymm5,ymm10
  2bcf02:	vpxord ymm6,ymm6,ymm11
  2bcf08:	vpxord ymm7,ymm7,ymm8
  2bcf0e:	vpxord ymm4,ymm4,ymm9
  2bcf14:	vprord ymm5,ymm5,0xc
  2bcf1b:	vprord ymm6,ymm6,0xc
  2bcf22:	vprord ymm7,ymm7,0xc
  2bcf29:	vprord ymm4,ymm4,0xc
  2bcf30:	vpaddd ymm0,ymm0,ymm27
  2bcf36:	vpaddd ymm1,ymm1,ymm21
  2bcf3c:	vpaddd ymm2,ymm2,ymm30
  2bcf42:	vpaddd ymm3,ymm3,ymm24
  2bcf48:	vpaddd ymm0,ymm0,ymm5
  2bcf4c:	vpaddd ymm1,ymm1,ymm6
  2bcf50:	vpaddd ymm2,ymm2,ymm7
  2bcf54:	vpaddd ymm3,ymm3,ymm4
  2bcf58:	vpxord ymm15,ymm15,ymm0
  2bcf5e:	vpxord ymm12,ymm12,ymm1
  2bcf64:	vpxord ymm13,ymm13,ymm2
  2bcf6a:	vpxord ymm14,ymm14,ymm3
  2bcf70:	vprord ymm15,ymm15,0x8
  2bcf77:	vprord ymm12,ymm12,0x8
  2bcf7e:	vprord ymm13,ymm13,0x8
  2bcf85:	vprord ymm14,ymm14,0x8
  2bcf8c:	vpaddd ymm10,ymm10,ymm15
  2bcf91:	vpaddd ymm11,ymm11,ymm12
  2bcf96:	vpaddd ymm8,ymm8,ymm13
  2bcf9b:	vpaddd ymm9,ymm9,ymm14
  2bcfa0:	vpxord ymm5,ymm5,ymm10
  2bcfa6:	vpxord ymm6,ymm6,ymm11
  2bcfac:	vpxord ymm7,ymm7,ymm8
  2bcfb2:	vpxord ymm4,ymm4,ymm9
  2bcfb8:	vprord ymm5,ymm5,0x7
  2bcfbf:	vprord ymm6,ymm6,0x7
  2bcfc6:	vprord ymm7,ymm7,0x7
  2bcfcd:	vprord ymm4,ymm4,0x7
  2bcfd4:	vpaddd ymm0,ymm0,ymm19
  2bcfda:	vpaddd ymm1,ymm1,ymm26
  2bcfe0:	vpaddd ymm2,ymm2,ymm29
  2bcfe6:	vpaddd ymm3,ymm3,ymm23
  2bcfec:	vpaddd ymm0,ymm0,ymm4
  2bcff0:	vpaddd ymm1,ymm1,ymm5
  2bcff4:	vpaddd ymm2,ymm2,ymm6
  2bcff8:	vpaddd ymm3,ymm3,ymm7
  2bcffc:	vpxord ymm12,ymm12,ymm0
  2bd002:	vpxord ymm13,ymm13,ymm1
  2bd008:	vpxord ymm14,ymm14,ymm2
  2bd00e:	vpxord ymm15,ymm15,ymm3
  2bd014:	vprord ymm12,ymm12,0x10
  2bd01b:	vprord ymm13,ymm13,0x10
  2bd022:	vprord ymm14,ymm14,0x10
  2bd029:	vprord ymm15,ymm15,0x10
  2bd030:	vpaddd ymm8,ymm8,ymm12
  2bd035:	vpaddd ymm9,ymm9,ymm13
  2bd03a:	vpaddd ymm10,ymm10,ymm14
  2bd03f:	vpaddd ymm11,ymm11,ymm15
  2bd044:	vpxord ymm4,ymm4,ymm8
  2bd04a:	vpxord ymm5,ymm5,ymm9
  2bd050:	vpxord ymm6,ymm6,ymm10
  2bd056:	vpxord ymm7,ymm7,ymm11
  2bd05c:	vprord ymm4,ymm4,0xc
  2bd063:	vprord ymm5,ymm5,0xc
  2bd06a:	vprord ymm6,ymm6,0xc
  2bd071:	vprord ymm7,ymm7,0xc
  2bd078:	vpaddd ymm0,ymm0,ymm20
  2bd07e:	vpaddd ymm1,ymm1,ymm28
  2bd084:	vpaddd ymm2,ymm2,ymm18
  2bd08a:	vpaddd ymm3,ymm3,ymm30
  2bd090:	vpaddd ymm0,ymm0,ymm4
  2bd094:	vpaddd ymm1,ymm1,ymm5
  2bd098:	vpaddd ymm2,ymm2,ymm6
  2bd09c:	vpaddd ymm3,ymm3,ymm7
  2bd0a0:	vpxord ymm12,ymm12,ymm0
  2bd0a6:	vpxord ymm13,ymm13,ymm1
  2bd0ac:	vpxord ymm14,ymm14,ymm2
  2bd0b2:	vpxord ymm15,ymm15,ymm3
  2bd0b8:	vprord ymm12,ymm12,0x8
  2bd0bf:	vprord ymm13,ymm13,0x8
  2bd0c6:	vprord ymm14,ymm14,0x8
  2bd0cd:	vprord ymm15,ymm15,0x8
  2bd0d4:	vpaddd ymm8,ymm8,ymm12
  2bd0d9:	vpaddd ymm9,ymm9,ymm13
  2bd0de:	vpaddd ymm10,ymm10,ymm14
  2bd0e3:	vpaddd ymm11,ymm11,ymm15
  2bd0e8:	vpxord ymm4,ymm4,ymm8
  2bd0ee:	vpxord ymm5,ymm5,ymm9
  2bd0f4:	vpxord ymm6,ymm6,ymm10
  2bd0fa:	vpxord ymm7,ymm7,ymm11
  2bd100:	vprord ymm4,ymm4,0x7
  2bd107:	vprord ymm5,ymm5,0x7
  2bd10e:	vprord ymm6,ymm6,0x7
  2bd115:	vprord ymm7,ymm7,0x7
  2bd11c:	vpaddd ymm0,ymm0,ymm22
  2bd122:	vpaddd ymm1,ymm1,ymm25
  2bd128:	vpaddd ymm2,ymm2,ymm27
  2bd12e:	vpaddd ymm3,ymm3,ymm24
  2bd134:	vpaddd ymm0,ymm0,ymm5
  2bd138:	vpaddd ymm1,ymm1,ymm6
  2bd13c:	vpaddd ymm2,ymm2,ymm7
  2bd140:	vpaddd ymm3,ymm3,ymm4
  2bd144:	vpxord ymm15,ymm15,ymm0
  2bd14a:	vpxord ymm12,ymm12,ymm1
  2bd150:	vpxord ymm13,ymm13,ymm2
  2bd156:	vpxord ymm14,ymm14,ymm3
  2bd15c:	vprord ymm15,ymm15,0x10
  2bd163:	vprord ymm12,ymm12,0x10
  2bd16a:	vprord ymm13,ymm13,0x10
  2bd171:	vprord ymm14,ymm14,0x10
  2bd178:	vpaddd ymm10,ymm10,ymm15
  2bd17d:	vpaddd ymm11,ymm11,ymm12
  2bd182:	vpaddd ymm8,ymm8,ymm13
  2bd187:	vpaddd ymm9,ymm9,ymm14
  2bd18c:	vpxord ymm5,ymm5,ymm10
  2bd192:	vpxord ymm6,ymm6,ymm11
  2bd198:	vpxord ymm7,ymm7,ymm8
  2bd19e:	vpxord ymm4,ymm4,ymm9
  2bd1a4:	vprord ymm5,ymm5,0xc
  2bd1ab:	vprord ymm6,ymm6,0xc
  2bd1b2:	vprord ymm7,ymm7,0xc
  2bd1b9:	vprord ymm4,ymm4,0xc
  2bd1c0:	vpaddd ymm0,ymm0,ymm21
  2bd1c6:	vpaddd ymm1,ymm1,ymm16
  2bd1cc:	vpaddd ymm2,ymm2,ymm31
  2bd1d2:	vpaddd ymm3,ymm3,ymm17
  2bd1d8:	vpaddd ymm0,ymm0,ymm5
  2bd1dc:	vpaddd ymm1,ymm1,ymm6
  2bd1e0:	vpaddd ymm2,ymm2,ymm7
  2bd1e4:	vpaddd ymm3,ymm3,ymm4
  2bd1e8:	vpxord ymm15,ymm15,ymm0
  2bd1ee:	vpxord ymm12,ymm12,ymm1
  2bd1f4:	vpxord ymm13,ymm13,ymm2
  2bd1fa:	vpxord ymm14,ymm14,ymm3
  2bd200:	vprord ymm15,ymm15,0x8
  2bd207:	vprord ymm12,ymm12,0x8
  2bd20e:	vprord ymm13,ymm13,0x8
  2bd215:	vprord ymm14,ymm14,0x8
  2bd21c:	vpaddd ymm10,ymm10,ymm15
  2bd221:	vpaddd ymm11,ymm11,ymm12
  2bd226:	vpaddd ymm8,ymm8,ymm13
  2bd22b:	vpaddd ymm9,ymm9,ymm14
  2bd230:	vpxord ymm5,ymm5,ymm10
  2bd236:	vpxord ymm6,ymm6,ymm11
  2bd23c:	vpxord ymm7,ymm7,ymm8
  2bd242:	vpxord ymm4,ymm4,ymm9
  2bd248:	vprord ymm5,ymm5,0x7
  2bd24f:	vprord ymm6,ymm6,0x7
  2bd256:	vprord ymm7,ymm7,0x7
  2bd25d:	vprord ymm4,ymm4,0x7
  2bd264:	vpaddd ymm0,ymm0,ymm26
  2bd26a:	vpaddd ymm1,ymm1,ymm28
  2bd270:	vpaddd ymm2,ymm2,ymm30
  2bd276:	vpaddd ymm3,ymm3,ymm29
  2bd27c:	vpaddd ymm0,ymm0,ymm4
  2bd280:	vpaddd ymm1,ymm1,ymm5
  2bd284:	vpaddd ymm2,ymm2,ymm6
  2bd288:	vpaddd ymm3,ymm3,ymm7
  2bd28c:	vpxord ymm12,ymm12,ymm0
  2bd292:	vpxord ymm13,ymm13,ymm1
  2bd298:	vpxord ymm14,ymm14,ymm2
  2bd29e:	vpxord ymm15,ymm15,ymm3
  2bd2a4:	vprord ymm12,ymm12,0x10
  2bd2ab:	vprord ymm13,ymm13,0x10
  2bd2b2:	vprord ymm14,ymm14,0x10
  2bd2b9:	vprord ymm15,ymm15,0x10
  2bd2c0:	vpaddd ymm8,ymm8,ymm12
  2bd2c5:	vpaddd ymm9,ymm9,ymm13
  2bd2ca:	vpaddd ymm10,ymm10,ymm14
  2bd2cf:	vpaddd ymm11,ymm11,ymm15
  2bd2d4:	vpxord ymm4,ymm4,ymm8
  2bd2da:	vpxord ymm5,ymm5,ymm9
  2bd2e0:	vpxord ymm6,ymm6,ymm10
  2bd2e6:	vpxord ymm7,ymm7,ymm11
  2bd2ec:	vprord ymm4,ymm4,0xc
  2bd2f3:	vprord ymm5,ymm5,0xc
  2bd2fa:	vprord ymm6,ymm6,0xc
  2bd301:	vprord ymm7,ymm7,0xc
  2bd308:	vpaddd ymm0,ymm0,ymm23
  2bd30e:	vpaddd ymm1,ymm1,ymm25
  2bd314:	vpaddd ymm2,ymm2,ymm19
  2bd31a:	vpaddd ymm3,ymm3,ymm31
  2bd320:	vpaddd ymm0,ymm0,ymm4
  2bd324:	vpaddd ymm1,ymm1,ymm5
  2bd328:	vpaddd ymm2,ymm2,ymm6
  2bd32c:	vpaddd ymm3,ymm3,ymm7
  2bd330:	vpxord ymm12,ymm12,ymm0
  2bd336:	vpxord ymm13,ymm13,ymm1
  2bd33c:	vpxord ymm14,ymm14,ymm2
  2bd342:	vpxord ymm15,ymm15,ymm3
  2bd348:	vprord ymm12,ymm12,0x8
  2bd34f:	vprord ymm13,ymm13,0x8
  2bd356:	vprord ymm14,ymm14,0x8
  2bd35d:	vprord ymm15,ymm15,0x8
  2bd364:	vpaddd ymm8,ymm8,ymm12
  2bd369:	vpaddd ymm9,ymm9,ymm13
  2bd36e:	vpaddd ymm10,ymm10,ymm14
  2bd373:	vpaddd ymm11,ymm11,ymm15
  2bd378:	vpxord ymm4,ymm4,ymm8
  2bd37e:	vpxord ymm5,ymm5,ymm9
  2bd384:	vpxord ymm6,ymm6,ymm10
  2bd38a:	vpxord ymm7,ymm7,ymm11
  2bd390:	vprord ymm4,ymm4,0x7
  2bd397:	vprord ymm5,ymm5,0x7
  2bd39e:	vprord ymm6,ymm6,0x7
  2bd3a5:	vprord ymm7,ymm7,0x7
  2bd3ac:	vpaddd ymm0,ymm0,ymm20
  2bd3b2:	vpaddd ymm1,ymm1,ymm27
  2bd3b8:	vpaddd ymm2,ymm2,ymm21
  2bd3be:	vpaddd ymm3,ymm3,ymm17
  2bd3c4:	vpaddd ymm0,ymm0,ymm5
  2bd3c8:	vpaddd ymm1,ymm1,ymm6
  2bd3cc:	vpaddd ymm2,ymm2,ymm7
  2bd3d0:	vpaddd ymm3,ymm3,ymm4
  2bd3d4:	vpxord ymm15,ymm15,ymm0
  2bd3da:	vpxord ymm12,ymm12,ymm1
  2bd3e0:	vpxord ymm13,ymm13,ymm2
  2bd3e6:	vpxord ymm14,ymm14,ymm3
  2bd3ec:	vprord ymm15,ymm15,0x10
  2bd3f3:	vprord ymm12,ymm12,0x10
  2bd3fa:	vprord ymm13,ymm13,0x10
  2bd401:	vprord ymm14,ymm14,0x10
  2bd408:	vpaddd ymm10,ymm10,ymm15
  2bd40d:	vpaddd ymm11,ymm11,ymm12
  2bd412:	vpaddd ymm8,ymm8,ymm13
  2bd417:	vpaddd ymm9,ymm9,ymm14
  2bd41c:	vpxord ymm5,ymm5,ymm10
  2bd422:	vpxord ymm6,ymm6,ymm11
  2bd428:	vpxord ymm7,ymm7,ymm8
  2bd42e:	vpxord ymm4,ymm4,ymm9
  2bd434:	vprord ymm5,ymm5,0xc
  2bd43b:	vprord ymm6,ymm6,0xc
  2bd442:	vprord ymm7,ymm7,0xc
  2bd449:	vprord ymm4,ymm4,0xc
  2bd450:	vpaddd ymm0,ymm0,ymm16
  2bd456:	vpaddd ymm1,ymm1,ymm18
  2bd45c:	vpaddd ymm2,ymm2,ymm24
  2bd462:	vpaddd ymm3,ymm3,ymm22
  2bd468:	vpaddd ymm0,ymm0,ymm5
  2bd46c:	vpaddd ymm1,ymm1,ymm6
  2bd470:	vpaddd ymm2,ymm2,ymm7
  2bd474:	vpaddd ymm3,ymm3,ymm4
  2bd478:	vpxord ymm15,ymm15,ymm0
  2bd47e:	vpxord ymm12,ymm12,ymm1
  2bd484:	vpxord ymm13,ymm13,ymm2
  2bd48a:	vpxord ymm14,ymm14,ymm3
  2bd490:	vprord ymm15,ymm15,0x8
  2bd497:	vprord ymm12,ymm12,0x8
  2bd49e:	vprord ymm13,ymm13,0x8
  2bd4a5:	vprord ymm14,ymm14,0x8
  2bd4ac:	vpaddd ymm10,ymm10,ymm15
  2bd4b1:	vpaddd ymm11,ymm11,ymm12
  2bd4b6:	vpaddd ymm8,ymm8,ymm13
  2bd4bb:	vpaddd ymm9,ymm9,ymm14
  2bd4c0:	vpxord ymm5,ymm5,ymm10
  2bd4c6:	vpxord ymm6,ymm6,ymm11
  2bd4cc:	vpxord ymm7,ymm7,ymm8
  2bd4d2:	vpxord ymm4,ymm4,ymm9
  2bd4d8:	vprord ymm5,ymm5,0x7
  2bd4df:	vprord ymm6,ymm6,0x7
  2bd4e6:	vprord ymm7,ymm7,0x7
  2bd4ed:	vprord ymm4,ymm4,0x7
  2bd4f4:	vpaddd ymm0,ymm0,ymm28
  2bd4fa:	vpaddd ymm1,ymm1,ymm25
  2bd500:	vpaddd ymm2,ymm2,ymm31
  2bd506:	vpaddd ymm3,ymm3,ymm30
  2bd50c:	vpaddd ymm0,ymm0,ymm4
  2bd510:	vpaddd ymm1,ymm1,ymm5
  2bd514:	vpaddd ymm2,ymm2,ymm6
  2bd518:	vpaddd ymm3,ymm3,ymm7
  2bd51c:	vpxord ymm12,ymm12,ymm0
  2bd522:	vpxord ymm13,ymm13,ymm1
  2bd528:	vpxord ymm14,ymm14,ymm2
  2bd52e:	vpxord ymm15,ymm15,ymm3
  2bd534:	vprord ymm12,ymm12,0x10
  2bd53b:	vprord ymm13,ymm13,0x10
  2bd542:	vprord ymm14,ymm14,0x10
  2bd549:	vprord ymm15,ymm15,0x10
  2bd550:	vpaddd ymm8,ymm8,ymm12
  2bd555:	vpaddd ymm9,ymm9,ymm13
  2bd55a:	vpaddd ymm10,ymm10,ymm14
  2bd55f:	vpaddd ymm11,ymm11,ymm15
  2bd564:	vpxord ymm4,ymm4,ymm8
  2bd56a:	vpxord ymm5,ymm5,ymm9
  2bd570:	vpxord ymm6,ymm6,ymm10
  2bd576:	vpxord ymm7,ymm7,ymm11
  2bd57c:	vprord ymm4,ymm4,0xc
  2bd583:	vprord ymm5,ymm5,0xc
  2bd58a:	vprord ymm6,ymm6,0xc
  2bd591:	vprord ymm7,ymm7,0xc
  2bd598:	vpaddd ymm0,ymm0,ymm29
  2bd59e:	vpaddd ymm1,ymm1,ymm27
  2bd5a4:	vpaddd ymm2,ymm2,ymm26
  2bd5aa:	vpaddd ymm3,ymm3,ymm24
  2bd5b0:	vpaddd ymm0,ymm0,ymm4
  2bd5b4:	vpaddd ymm1,ymm1,ymm5
  2bd5b8:	vpaddd ymm2,ymm2,ymm6
  2bd5bc:	vpaddd ymm3,ymm3,ymm7
  2bd5c0:	vpxord ymm12,ymm12,ymm0
  2bd5c6:	vpxord ymm13,ymm13,ymm1
  2bd5cc:	vpxord ymm14,ymm14,ymm2
  2bd5d2:	vpxord ymm15,ymm15,ymm3
  2bd5d8:	vprord ymm12,ymm12,0x8
  2bd5df:	vprord ymm13,ymm13,0x8
  2bd5e6:	vprord ymm14,ymm14,0x8
  2bd5ed:	vprord ymm15,ymm15,0x8
  2bd5f4:	vpaddd ymm8,ymm8,ymm12
  2bd5f9:	vpaddd ymm9,ymm9,ymm13
  2bd5fe:	vpaddd ymm10,ymm10,ymm14
  2bd603:	vpaddd ymm11,ymm11,ymm15
  2bd608:	vpxord ymm4,ymm4,ymm8
  2bd60e:	vpxord ymm5,ymm5,ymm9
  2bd614:	vpxord ymm6,ymm6,ymm10
  2bd61a:	vpxord ymm7,ymm7,ymm11
  2bd620:	vprord ymm4,ymm4,0x7
  2bd627:	vprord ymm5,ymm5,0x7
  2bd62e:	vprord ymm6,ymm6,0x7
  2bd635:	vprord ymm7,ymm7,0x7
  2bd63c:	vpaddd ymm0,ymm0,ymm23
  2bd642:	vpaddd ymm1,ymm1,ymm21
  2bd648:	vpaddd ymm2,ymm2,ymm16
  2bd64e:	vpaddd ymm3,ymm3,ymm22
  2bd654:	vpaddd ymm0,ymm0,ymm5
  2bd658:	vpaddd ymm1,ymm1,ymm6
  2bd65c:	vpaddd ymm2,ymm2,ymm7
  2bd660:	vpaddd ymm3,ymm3,ymm4
  2bd664:	vpxord ymm15,ymm15,ymm0
  2bd66a:	vpxord ymm12,ymm12,ymm1
  2bd670:	vpxord ymm13,ymm13,ymm2
  2bd676:	vpxord ymm14,ymm14,ymm3
  2bd67c:	vprord ymm15,ymm15,0x10
  2bd683:	vprord ymm12,ymm12,0x10
  2bd68a:	vprord ymm13,ymm13,0x10
  2bd691:	vprord ymm14,ymm14,0x10
  2bd698:	vpaddd ymm10,ymm10,ymm15
  2bd69d:	vpaddd ymm11,ymm11,ymm12
  2bd6a2:	vpaddd ymm8,ymm8,ymm13
  2bd6a7:	vpaddd ymm9,ymm9,ymm14
  2bd6ac:	vpxord ymm5,ymm5,ymm10
  2bd6b2:	vpxord ymm6,ymm6,ymm11
  2bd6b8:	vpxord ymm7,ymm7,ymm8
  2bd6be:	vpxord ymm4,ymm4,ymm9
  2bd6c4:	vprord ymm5,ymm5,0xc
  2bd6cb:	vprord ymm6,ymm6,0xc
  2bd6d2:	vprord ymm7,ymm7,0xc
  2bd6d9:	vprord ymm4,ymm4,0xc
  2bd6e0:	vpaddd ymm0,ymm0,ymm18
  2bd6e6:	vpaddd ymm1,ymm1,ymm19
  2bd6ec:	vpaddd ymm2,ymm2,ymm17
  2bd6f2:	vpaddd ymm3,ymm3,ymm20
  2bd6f8:	vpaddd ymm0,ymm0,ymm5
  2bd6fc:	vpaddd ymm1,ymm1,ymm6
  2bd700:	vpaddd ymm2,ymm2,ymm7
  2bd704:	vpaddd ymm3,ymm3,ymm4
  2bd708:	vpxord ymm15,ymm15,ymm0
  2bd70e:	vpxord ymm12,ymm12,ymm1
  2bd714:	vpxord ymm13,ymm13,ymm2
  2bd71a:	vpxord ymm14,ymm14,ymm3
  2bd720:	vprord ymm15,ymm15,0x8
  2bd727:	vprord ymm12,ymm12,0x8
  2bd72e:	vprord ymm13,ymm13,0x8
  2bd735:	vprord ymm14,ymm14,0x8
  2bd73c:	vpaddd ymm10,ymm10,ymm15
  2bd741:	vpaddd ymm11,ymm11,ymm12
  2bd746:	vpaddd ymm8,ymm8,ymm13
  2bd74b:	vpaddd ymm9,ymm9,ymm14
  2bd750:	vpxord ymm5,ymm5,ymm10
  2bd756:	vpxord ymm6,ymm6,ymm11
  2bd75c:	vpxord ymm7,ymm7,ymm8
  2bd762:	vpxord ymm4,ymm4,ymm9
  2bd768:	vprord ymm5,ymm5,0x7
  2bd76f:	vprord ymm6,ymm6,0x7
  2bd776:	vprord ymm7,ymm7,0x7
  2bd77d:	vprord ymm4,ymm4,0x7
  2bd784:	vpaddd ymm0,ymm0,ymm25
  2bd78a:	vpaddd ymm1,ymm1,ymm27
  2bd790:	vpaddd ymm2,ymm2,ymm24
  2bd796:	vpaddd ymm3,ymm3,ymm31
  2bd79c:	vpaddd ymm0,ymm0,ymm4
  2bd7a0:	vpaddd ymm1,ymm1,ymm5
  2bd7a4:	vpaddd ymm2,ymm2,ymm6
  2bd7a8:	vpaddd ymm3,ymm3,ymm7
  2bd7ac:	vpxord ymm12,ymm12,ymm0
  2bd7b2:	vpxord ymm13,ymm13,ymm1
  2bd7b8:	vpxord ymm14,ymm14,ymm2
  2bd7be:	vpxord ymm15,ymm15,ymm3
  2bd7c4:	vprord ymm12,ymm12,0x10
  2bd7cb:	vprord ymm13,ymm13,0x10
  2bd7d2:	vprord ymm14,ymm14,0x10
  2bd7d9:	vprord ymm15,ymm15,0x10
  2bd7e0:	vpaddd ymm8,ymm8,ymm12
  2bd7e5:	vpaddd ymm9,ymm9,ymm13
  2bd7ea:	vpaddd ymm10,ymm10,ymm14
  2bd7ef:	vpaddd ymm11,ymm11,ymm15
  2bd7f4:	vpxord ymm4,ymm4,ymm8
  2bd7fa:	vpxord ymm5,ymm5,ymm9
  2bd800:	vpxord ymm6,ymm6,ymm10
  2bd806:	vpxord ymm7,ymm7,ymm11
  2bd80c:	vprord ymm4,ymm4,0xc
  2bd813:	vprord ymm5,ymm5,0xc
  2bd81a:	vprord ymm6,ymm6,0xc
  2bd821:	vprord ymm7,ymm7,0xc
  2bd828:	vpaddd ymm0,ymm0,ymm30
  2bd82e:	vpaddd ymm1,ymm1,ymm21
  2bd834:	vpaddd ymm2,ymm2,ymm28
  2bd83a:	vpaddd ymm3,ymm3,ymm17
  2bd840:	vpaddd ymm0,ymm0,ymm4
  2bd844:	vpaddd ymm1,ymm1,ymm5
  2bd848:	vpaddd ymm2,ymm2,ymm6
  2bd84c:	vpaddd ymm3,ymm3,ymm7
  2bd850:	vpxord ymm12,ymm12,ymm0
  2bd856:	vpxord ymm13,ymm13,ymm1
  2bd85c:	vpxord ymm14,ymm14,ymm2
  2bd862:	vpxord ymm15,ymm15,ymm3
  2bd868:	vprord ymm12,ymm12,0x8
  2bd86f:	vprord ymm13,ymm13,0x8
  2bd876:	vprord ymm14,ymm14,0x8
  2bd87d:	vprord ymm15,ymm15,0x8
  2bd884:	vpaddd ymm8,ymm8,ymm12
  2bd889:	vpaddd ymm9,ymm9,ymm13
  2bd88e:	vpaddd ymm10,ymm10,ymm14
  2bd893:	vpaddd ymm11,ymm11,ymm15
  2bd898:	vpxord ymm4,ymm4,ymm8
  2bd89e:	vpxord ymm5,ymm5,ymm9
  2bd8a4:	vpxord ymm6,ymm6,ymm10
  2bd8aa:	vpxord ymm7,ymm7,ymm11
  2bd8b0:	vprord ymm4,ymm4,0x7
  2bd8b7:	vprord ymm5,ymm5,0x7
  2bd8be:	vprord ymm6,ymm6,0x7
  2bd8c5:	vprord ymm7,ymm7,0x7
  2bd8cc:	vpaddd ymm0,ymm0,ymm29
  2bd8d2:	vpaddd ymm1,ymm1,ymm16
  2bd8d8:	vpaddd ymm2,ymm2,ymm18
  2bd8de:	vpaddd ymm3,ymm3,ymm20
  2bd8e4:	vpaddd ymm0,ymm0,ymm5
  2bd8e8:	vpaddd ymm1,ymm1,ymm6
  2bd8ec:	vpaddd ymm2,ymm2,ymm7
  2bd8f0:	vpaddd ymm3,ymm3,ymm4
  2bd8f4:	vpxord ymm15,ymm15,ymm0
  2bd8fa:	vpxord ymm12,ymm12,ymm1
  2bd900:	vpxord ymm13,ymm13,ymm2
  2bd906:	vpxord ymm14,ymm14,ymm3
  2bd90c:	vprord ymm15,ymm15,0x10
  2bd913:	vprord ymm12,ymm12,0x10
  2bd91a:	vprord ymm13,ymm13,0x10
  2bd921:	vprord ymm14,ymm14,0x10
  2bd928:	vpaddd ymm10,ymm10,ymm15
  2bd92d:	vpaddd ymm11,ymm11,ymm12
  2bd932:	vpaddd ymm8,ymm8,ymm13
  2bd937:	vpaddd ymm9,ymm9,ymm14
  2bd93c:	vpxord ymm5,ymm5,ymm10
  2bd942:	vpxord ymm6,ymm6,ymm11
  2bd948:	vpxord ymm7,ymm7,ymm8
  2bd94e:	vpxord ymm4,ymm4,ymm9
  2bd954:	vprord ymm5,ymm5,0xc
  2bd95b:	vprord ymm6,ymm6,0xc
  2bd962:	vprord ymm7,ymm7,0xc
  2bd969:	vprord ymm4,ymm4,0xc
  2bd970:	vpaddd ymm0,ymm0,ymm19
  2bd976:	vpaddd ymm1,ymm1,ymm26
  2bd97c:	vpaddd ymm2,ymm2,ymm22
  2bd982:	vpaddd ymm3,ymm3,ymm23
  2bd988:	vpaddd ymm0,ymm0,ymm5
  2bd98c:	vpaddd ymm1,ymm1,ymm6
  2bd990:	vpaddd ymm2,ymm2,ymm7
  2bd994:	vpaddd ymm3,ymm3,ymm4
  2bd998:	vpxord ymm15,ymm15,ymm0
  2bd99e:	vpxord ymm12,ymm12,ymm1
  2bd9a4:	vpxord ymm13,ymm13,ymm2
  2bd9aa:	vpxord ymm14,ymm14,ymm3
  2bd9b0:	vprord ymm15,ymm15,0x8
  2bd9b7:	vprord ymm12,ymm12,0x8
  2bd9be:	vprord ymm13,ymm13,0x8
  2bd9c5:	vprord ymm14,ymm14,0x8
  2bd9cc:	vpaddd ymm10,ymm10,ymm15
  2bd9d1:	vpaddd ymm11,ymm11,ymm12
  2bd9d6:	vpaddd ymm8,ymm8,ymm13
  2bd9db:	vpaddd ymm9,ymm9,ymm14
  2bd9e0:	vpxord ymm5,ymm5,ymm10
  2bd9e6:	vpxord ymm6,ymm6,ymm11
  2bd9ec:	vpxord ymm7,ymm7,ymm8
  2bd9f2:	vpxord ymm4,ymm4,ymm9
  2bd9f8:	vprord ymm5,ymm5,0x7
  2bd9ff:	vprord ymm6,ymm6,0x7
  2bda06:	vprord ymm7,ymm7,0x7
  2bda0d:	vprord ymm4,ymm4,0x7
  2bda14:	vpaddd ymm0,ymm0,ymm27
  2bda1a:	vpaddd ymm1,ymm1,ymm21
  2bda20:	vpaddd ymm2,ymm2,ymm17
  2bda26:	vpaddd ymm3,ymm3,ymm24
  2bda2c:	vpaddd ymm0,ymm0,ymm4
  2bda30:	vpaddd ymm1,ymm1,ymm5
  2bda34:	vpaddd ymm2,ymm2,ymm6
  2bda38:	vpaddd ymm3,ymm3,ymm7
  2bda3c:	vpxord ymm12,ymm12,ymm0
  2bda42:	vpxord ymm13,ymm13,ymm1
  2bda48:	vpxord ymm14,ymm14,ymm2
  2bda4e:	vpxord ymm15,ymm15,ymm3
  2bda54:	vprord ymm12,ymm12,0x10
  2bda5b:	vprord ymm13,ymm13,0x10
  2bda62:	vprord ymm14,ymm14,0x10
  2bda69:	vprord ymm15,ymm15,0x10
  2bda70:	vpaddd ymm8,ymm8,ymm12
  2bda75:	vpaddd ymm9,ymm9,ymm13
  2bda7a:	vpaddd ymm10,ymm10,ymm14
  2bda7f:	vpaddd ymm11,ymm11,ymm15
  2bda84:	vpxord ymm4,ymm4,ymm8
  2bda8a:	vpxord ymm5,ymm5,ymm9
  2bda90:	vpxord ymm6,ymm6,ymm10
  2bda96:	vpxord ymm7,ymm7,ymm11
  2bda9c:	vprord ymm4,ymm4,0xc
  2bdaa3:	vprord ymm5,ymm5,0xc
  2bdaaa:	vprord ymm6,ymm6,0xc
  2bdab1:	vprord ymm7,ymm7,0xc
  2bdab8:	vpaddd ymm0,ymm0,ymm31
  2bdabe:	vpaddd ymm1,ymm1,ymm16
  2bdac4:	vpaddd ymm2,ymm2,ymm25
  2bdaca:	vpaddd ymm3,ymm3,ymm22
  2bdad0:	vpaddd ymm0,ymm0,ymm4
  2bdad4:	vpaddd ymm1,ymm1,ymm5
  2bdad8:	vpaddd ymm2,ymm2,ymm6
  2bdadc:	vpaddd ymm3,ymm3,ymm7
  2bdae0:	vpxord ymm12,ymm12,ymm0
  2bdae6:	vpxord ymm13,ymm13,ymm1
  2bdaec:	vpxord ymm14,ymm14,ymm2
  2bdaf2:	vpxord ymm15,ymm15,ymm3
  2bdaf8:	vprord ymm12,ymm12,0x8
  2bdaff:	vprord ymm13,ymm13,0x8
  2bdb06:	vprord ymm14,ymm14,0x8
  2bdb0d:	vprord ymm15,ymm15,0x8
  2bdb14:	vpaddd ymm8,ymm8,ymm12
  2bdb19:	vpaddd ymm9,ymm9,ymm13
  2bdb1e:	vpaddd ymm10,ymm10,ymm14
  2bdb23:	vpaddd ymm11,ymm11,ymm15
  2bdb28:	vpxord ymm4,ymm4,ymm8
  2bdb2e:	vpxord ymm5,ymm5,ymm9
  2bdb34:	vpxord ymm6,ymm6,ymm10
  2bdb3a:	vpxord ymm7,ymm7,ymm11
  2bdb40:	vprord ymm4,ymm4,0x7
  2bdb47:	vprord ymm5,ymm5,0x7
  2bdb4e:	vprord ymm6,ymm6,0x7
  2bdb55:	vprord ymm7,ymm7,0x7
  2bdb5c:	vpaddd ymm0,ymm0,ymm30
  2bdb62:	vpaddd ymm1,ymm1,ymm18
  2bdb68:	vpaddd ymm2,ymm2,ymm19
  2bdb6e:	vpaddd ymm3,ymm3,ymm23
  2bdb74:	vpaddd ymm0,ymm0,ymm5
  2bdb78:	vpaddd ymm1,ymm1,ymm6
  2bdb7c:	vpaddd ymm2,ymm2,ymm7
  2bdb80:	vpaddd ymm3,ymm3,ymm4
  2bdb84:	vpxord ymm15,ymm15,ymm0
  2bdb8a:	vpxord ymm12,ymm12,ymm1
  2bdb90:	vpxord ymm13,ymm13,ymm2
  2bdb96:	vpxord ymm14,ymm14,ymm3
  2bdb9c:	vprord ymm15,ymm15,0x10
  2bdba3:	vprord ymm12,ymm12,0x10
  2bdbaa:	vprord ymm13,ymm13,0x10
  2bdbb1:	vprord ymm14,ymm14,0x10
  2bdbb8:	vpaddd ymm10,ymm10,ymm15
  2bdbbd:	vpaddd ymm11,ymm11,ymm12
  2bdbc2:	vpaddd ymm8,ymm8,ymm13
  2bdbc7:	vpaddd ymm9,ymm9,ymm14
  2bdbcc:	vpxord ymm5,ymm5,ymm10
  2bdbd2:	vpxord ymm6,ymm6,ymm11
  2bdbd8:	vpxord ymm7,ymm7,ymm8
  2bdbde:	vpxord ymm4,ymm4,ymm9
  2bdbe4:	vprord ymm5,ymm5,0xc
  2bdbeb:	vprord ymm6,ymm6,0xc
  2bdbf2:	vprord ymm7,ymm7,0xc
  2bdbf9:	vprord ymm4,ymm4,0xc
  2bdc00:	vpaddd ymm0,ymm0,ymm26
  2bdc06:	vpaddd ymm1,ymm1,ymm28
  2bdc0c:	vpaddd ymm2,ymm2,ymm20
  2bdc12:	vpaddd ymm3,ymm3,ymm29
  2bdc18:	vpaddd ymm0,ymm0,ymm5
  2bdc1c:	vpaddd ymm1,ymm1,ymm6
  2bdc20:	vpaddd ymm2,ymm2,ymm7
  2bdc24:	vpaddd ymm3,ymm3,ymm4
  2bdc28:	vpxord ymm15,ymm15,ymm0
  2bdc2e:	vpxord ymm12,ymm12,ymm1
  2bdc34:	vpxord ymm13,ymm13,ymm2
  2bdc3a:	vpxord ymm14,ymm14,ymm3
  2bdc40:	vprord ymm15,ymm15,0x8
  2bdc47:	vprord ymm12,ymm12,0x8
  2bdc4e:	vprord ymm13,ymm13,0x8
  2bdc55:	vprord ymm14,ymm14,0x8
  2bdc5c:	vpaddd ymm10,ymm10,ymm15
  2bdc61:	vpaddd ymm11,ymm11,ymm12
  2bdc66:	vpaddd ymm8,ymm8,ymm13
  2bdc6b:	vpaddd ymm9,ymm9,ymm14
  2bdc70:	vpxord ymm5,ymm5,ymm10
  2bdc76:	vpxord ymm6,ymm6,ymm11
  2bdc7c:	vpxord ymm7,ymm7,ymm8
  2bdc82:	vpxord ymm4,ymm4,ymm9
  2bdc88:	vprord ymm5,ymm5,0x7
  2bdc8f:	vprord ymm6,ymm6,0x7
  2bdc96:	vprord ymm7,ymm7,0x7
  2bdc9d:	vprord ymm4,ymm4,0x7
  2bdca4:	vpxor  ymm0,ymm0,ymm8
  2bdca9:	vpxor  ymm1,ymm1,ymm9
  2bdcae:	vpxor  ymm2,ymm2,ymm10
  2bdcb3:	vpxor  ymm3,ymm3,ymm11
  2bdcb8:	vpxor  ymm4,ymm4,ymm12
  2bdcbd:	vpxor  ymm5,ymm5,ymm13
  2bdcc2:	vpxor  ymm6,ymm6,ymm14
  2bdcc7:	vpxor  ymm7,ymm7,ymm15
  2bdccc:	movzx  eax,BYTE PTR [rbp+0x38]
  2bdcd0:	jne    2bc8a6 <_blake3_servil_hash_many_avx512+0x1aa6>
  2bdcd6:	mov    rbx,QWORD PTR [rbp+0x50]
  2bdcda:	vunpcklps ymm8,ymm0,ymm1
  2bdcde:	vunpcklps ymm9,ymm2,ymm3
  2bdce2:	vunpckhps ymm10,ymm0,ymm1
  2bdce6:	vunpcklps ymm11,ymm4,ymm5
  2bdcea:	vunpcklps ymm0,ymm6,ymm7
  2bdcee:	vshufps ymm12,ymm8,ymm9,0x4e
  2bdcf4:	vblendps ymm1,ymm8,ymm12,0xcc
  2bdcfa:	vshufps ymm8,ymm11,ymm0,0x4e
  2bdcff:	vunpckhps ymm13,ymm2,ymm3
  2bdd03:	vblendps ymm2,ymm11,ymm8,0xcc
  2bdd09:	vblendps ymm3,ymm12,ymm9,0xcc
  2bdd0f:	vperm2f128 ymm12,ymm1,ymm2,0x20
  2bdd15:	vmovups YMMWORD PTR [rbx],ymm12
  2bdd19:	vunpckhps ymm14,ymm4,ymm5
  2bdd1d:	vblendps ymm4,ymm8,ymm0,0xcc
  2bdd23:	vunpckhps ymm15,ymm6,ymm7
  2bdd27:	vperm2f128 ymm7,ymm3,ymm4,0x20
  2bdd2d:	vmovups YMMWORD PTR [rbx+0x20],ymm7
  2bdd32:	vshufps ymm5,ymm10,ymm13,0x4e
  2bdd38:	vblendps ymm6,ymm5,ymm13,0xcc
  2bdd3e:	vshufps ymm13,ymm14,ymm15,0x4e
  2bdd44:	vblendps ymm10,ymm10,ymm5,0xcc
  2bdd4a:	vblendps ymm14,ymm14,ymm13,0xcc
  2bdd50:	vperm2f128 ymm8,ymm10,ymm14,0x20
  2bdd56:	vmovups YMMWORD PTR [rbx+0x40],ymm8
  2bdd5b:	vblendps ymm15,ymm13,ymm15,0xcc
  2bdd61:	vperm2f128 ymm13,ymm6,ymm15,0x20
  2bdd67:	vmovups YMMWORD PTR [rbx+0x60],ymm13
  2bdd6c:	vperm2f128 ymm9,ymm1,ymm2,0x31
  2bdd72:	vperm2f128 ymm11,ymm3,ymm4,0x31
  2bdd78:	vmovups YMMWORD PTR [rbx+0x80],ymm9
  2bdd80:	vperm2f128 ymm14,ymm10,ymm14,0x31
  2bdd86:	vperm2f128 ymm15,ymm6,ymm15,0x31
  2bdd8c:	vmovups YMMWORD PTR [rbx+0xa0],ymm11
  2bdd94:	vmovups YMMWORD PTR [rbx+0xc0],ymm14
  2bdd9c:	vmovups YMMWORD PTR [rbx+0xe0],ymm15
  2bdda4:	vmovdqa ymm0,YMMWORD PTR [rsp]
  2bdda9:	vmovdqa ymm2,YMMWORD PTR [rsp+0x40]
  2bddaf:	vmovdqa32 ymm0{k1},YMMWORD PTR [rsp+0x20]
  2bddb7:	vmovdqa32 ymm2{k1},YMMWORD PTR [rsp+0x60]
  2bddbf:	vmovdqa YMMWORD PTR [rsp],ymm0
  2bddc4:	vmovdqa YMMWORD PTR [rsp+0x40],ymm2
  2bddca:	add    rbx,0x100
  2bddd1:	mov    QWORD PTR [rbp+0x50],rbx
  2bddd5:	add    rdi,0x40
  2bddd9:	sub    rsi,0x8
  2bdddd:	mov    rbx,QWORD PTR [rbp+0x50]
  2bdde1:	mov    r15,QWORD PTR [rsp+0x80]
  2bdde9:	movzx  r13,BYTE PTR [rbp+0x38]
  2bddee:	movzx  r12,BYTE PTR [rbp+0x48]
  2bddf3:	test   esi,0x4
  2bddf9:	je     2be13b <_blake3_servil_hash_many_avx512+0x333b>
  2bddff:	vbroadcasti32x4 zmm0,XMMWORD PTR [rcx]
  2bde05:	vbroadcasti32x4 zmm1,XMMWORD PTR [rcx+0x10]
  2bde0c:	vmovdqa xmm12,XMMWORD PTR [rsp]
  2bde11:	vmovdqa xmm13,XMMWORD PTR [rsp+0x40]
  2bde17:	vpunpckldq xmm14,xmm12,xmm13
  2bde1c:	vpunpckhdq xmm15,xmm12,xmm13
  2bde21:	vpermq ymm14,ymm14,0xdc
  2bde27:	vpermq ymm15,ymm15,0xdc
  2bde2d:	vpbroadcastd zmm12,DWORD PTR [rip+0xffffffffffd7f951]        # 3d788 <BLAKE3_BLOCK_LEN>
  2bde37:	vinserti64x4 zmm13,zmm14,ymm15,0x1
  2bde3e:	mov    eax,0x4444
  2bde43:	kmovw  k2,eax
  2bde47:	vpblendmd zmm13{k2},zmm13,zmm12
  2bde4d:	vbroadcasti32x4 zmm15,XMMWORD PTR [rip+0xffffffffffd7f969]        # 3d7c0 <BLAKE3_IV>
  2bde57:	mov    r8,QWORD PTR [rdi]
  2bde5a:	mov    r9,QWORD PTR [rdi+0x8]
  2bde5e:	mov    r10,QWORD PTR [rdi+0x10]
  2bde62:	mov    r11,QWORD PTR [rdi+0x18]
  2bde66:	mov    eax,0xaaaa
  2bde6b:	kmovw  k3,eax
  2bde6f:	mov    eax,0x8888
  2bde74:	kmovw  k4,eax
  2bde78:	movzx  eax,BYTE PTR [rbp+0x40]
  2bde7c:	or     eax,r13d
  2bde7f:	xor    edx,edx
  2bde81:	nop    WORD PTR [rax+rax*1+0x0]
  2bde8a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2bde95:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2bdea0:	mov    r14d,eax
  2bdea3:	or     eax,r12d
  2bdea6:	add    rdx,0x40
  2bdeaa:	cmp    rdx,r15
  2bdead:	cmovne eax,r14d
  2bdeb1:	mov    DWORD PTR [rsp+0x88],eax
  2bdeb8:	vmovdqa32 zmm2,zmm15
  2bdebe:	vpbroadcastd zmm8,DWORD PTR [rsp+0x88]
  2bdec6:	vpblendmd zmm3{k4},zmm13,zmm8
  2bdecc:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2bded3:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r9+rdx*1-0x40],0x1
  2bdedc:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r10+rdx*1-0x40],0x2
  2bdee5:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r11+rdx*1-0x40],0x3
  2bdeee:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x30]
  2bdef5:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r9+rdx*1-0x30],0x1
  2bdefe:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r10+rdx*1-0x30],0x2
  2bdf07:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r11+rdx*1-0x30],0x3
  2bdf10:	vshufps zmm4,zmm8,zmm9,0x88
  2bdf17:	vshufps zmm5,zmm8,zmm9,0xdd
  2bdf1e:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2bdf25:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r9+rdx*1-0x20],0x1
  2bdf2e:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r10+rdx*1-0x20],0x2
  2bdf37:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r11+rdx*1-0x20],0x3
  2bdf40:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x10]
  2bdf47:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r9+rdx*1-0x10],0x1
  2bdf50:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r10+rdx*1-0x10],0x2
  2bdf59:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r11+rdx*1-0x10],0x3
  2bdf62:	vshufps zmm6,zmm8,zmm9,0x88
  2bdf69:	vshufps zmm7,zmm8,zmm9,0xdd
  2bdf70:	vpshufd zmm6,zmm6,0x93
  2bdf77:	vpshufd zmm7,zmm7,0x93
  2bdf7e:	mov    al,0x7
  2bdf80:	vpaddd zmm0,zmm0,zmm4
  2bdf86:	vpaddd zmm0,zmm0,zmm1
  2bdf8c:	vpxord zmm3,zmm3,zmm0
  2bdf92:	vprord zmm3,zmm3,0x10
  2bdf99:	vpaddd zmm2,zmm2,zmm3
  2bdf9f:	vpxord zmm1,zmm1,zmm2
  2bdfa5:	vprord zmm1,zmm1,0xc
  2bdfac:	vpaddd zmm0,zmm0,zmm5
  2bdfb2:	vpaddd zmm0,zmm0,zmm1
  2bdfb8:	vpxord zmm3,zmm3,zmm0
  2bdfbe:	vprord zmm3,zmm3,0x8
  2bdfc5:	vpaddd zmm2,zmm2,zmm3
  2bdfcb:	vpxord zmm1,zmm1,zmm2
  2bdfd1:	vprord zmm1,zmm1,0x7
  2bdfd8:	vpshufd zmm0,zmm0,0x93
  2bdfdf:	vpshufd zmm3,zmm3,0x4e
  2bdfe6:	vpshufd zmm2,zmm2,0x39
  2bdfed:	vpaddd zmm0,zmm0,zmm6
  2bdff3:	vpaddd zmm0,zmm0,zmm1
  2bdff9:	vpxord zmm3,zmm3,zmm0
  2bdfff:	vprord zmm3,zmm3,0x10
  2be006:	vpaddd zmm2,zmm2,zmm3
  2be00c:	vpxord zmm1,zmm1,zmm2
  2be012:	vprord zmm1,zmm1,0xc
  2be019:	vpaddd zmm0,zmm0,zmm7
  2be01f:	vpaddd zmm0,zmm0,zmm1
  2be025:	vpxord zmm3,zmm3,zmm0
  2be02b:	vprord zmm3,zmm3,0x8
  2be032:	vpaddd zmm2,zmm2,zmm3
  2be038:	vpxord zmm1,zmm1,zmm2
  2be03e:	vprord zmm1,zmm1,0x7
  2be045:	vpshufd zmm0,zmm0,0x39
  2be04c:	vpshufd zmm3,zmm3,0x4e
  2be053:	vpshufd zmm2,zmm2,0x93
  2be05a:	dec    al
  2be05c:	je     2be0b7 <_blake3_servil_hash_many_avx512+0x32b7>
  2be05e:	vshufps zmm8,zmm4,zmm5,0xd6
  2be065:	vpshufd zmm9,zmm4,0xf
  2be06c:	vpshufd zmm4,zmm8,0x39
  2be073:	vshufps zmm8,zmm6,zmm7,0xfa
  2be07a:	vpblendmd zmm9{k3},zmm9,zmm8
  2be080:	vpunpcklqdq zmm8,zmm7,zmm5
  2be086:	vpblendmd zmm8{k4},zmm8,zmm6
  2be08c:	vpshufd zmm8,zmm8,0x78
  2be093:	vpunpckhdq zmm5,zmm5,zmm7
  2be099:	vpunpckldq zmm6,zmm6,zmm5
  2be09f:	vpshufd zmm7,zmm6,0x1e
  2be0a6:	vmovdqa32 zmm5,zmm9
  2be0ac:	vmovdqa32 zmm6,zmm8
  2be0b2:	jmp    2bdf80 <_blake3_servil_hash_many_avx512+0x3180>
  2be0b7:	vpxord zmm0,zmm0,zmm2
  2be0bd:	vpxord zmm1,zmm1,zmm3
  2be0c3:	mov    eax,r13d
  2be0c6:	cmp    rdx,r15
  2be0c9:	jne    2bdea0 <_blake3_servil_hash_many_avx512+0x30a0>
  2be0cf:	vmovdqu XMMWORD PTR [rbx],xmm0
  2be0d3:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2be0d8:	vextracti128 XMMWORD PTR [rbx+0x20],ymm0,0x1
  2be0df:	vextracti128 XMMWORD PTR [rbx+0x30],ymm1,0x1
  2be0e6:	vextracti32x4 XMMWORD PTR [rbx+0x40],zmm0,0x2
  2be0ee:	vextracti32x4 XMMWORD PTR [rbx+0x50],zmm1,0x2
  2be0f6:	vextracti32x4 XMMWORD PTR [rbx+0x60],zmm0,0x3
  2be0fe:	vextracti32x4 XMMWORD PTR [rbx+0x70],zmm1,0x3
  2be106:	vmovdqa xmm0,XMMWORD PTR [rsp]
  2be10b:	vmovdqa xmm2,XMMWORD PTR [rsp+0x40]
  2be111:	vmovdqa32 xmm0{k1},XMMWORD PTR [rsp+0x10]
  2be119:	vmovdqa32 xmm2{k1},XMMWORD PTR [rsp+0x50]
  2be121:	vmovdqa XMMWORD PTR [rsp],xmm0
  2be126:	vmovdqa XMMWORD PTR [rsp+0x40],xmm2
  2be12c:	add    rbx,0x80
  2be133:	add    rdi,0x20
  2be137:	sub    rsi,0x4
  2be13b:	test   esi,0x2
  2be141:	je     2be393 <_blake3_servil_hash_many_avx512+0x3593>
  2be147:	vbroadcasti128 ymm0,XMMWORD PTR [rcx]
  2be14c:	vbroadcasti128 ymm1,XMMWORD PTR [rcx+0x10]
  2be152:	vmovd  xmm13,DWORD PTR [rsp]
  2be157:	vpinsrd xmm13,xmm13,DWORD PTR [rsp+0x40],0x1
  2be15f:	vpinsrd xmm13,xmm13,DWORD PTR [rip+0xffffffffffd7f61f],0x2        # 3d788 <BLAKE3_BLOCK_LEN>
  2be169:	vmovd  xmm14,DWORD PTR [rsp+0x4]
  2be16f:	vpinsrd xmm14,xmm14,DWORD PTR [rsp+0x44],0x1
  2be177:	vpinsrd xmm14,xmm14,DWORD PTR [rip+0xffffffffffd7f607],0x2        # 3d788 <BLAKE3_BLOCK_LEN>
  2be181:	vinserti128 ymm13,ymm13,xmm14,0x1
  2be187:	mov    r8,QWORD PTR [rdi]
  2be18a:	mov    r9,QWORD PTR [rdi+0x8]
  2be18e:	movzx  eax,BYTE PTR [rbp+0x40]
  2be192:	or     eax,r13d
  2be195:	xor    edx,edx
  2be197:	nop    WORD PTR [rax+rax*1+0x0]
  2be1a0:	mov    r14d,eax
  2be1a3:	or     eax,r12d
  2be1a6:	add    rdx,0x40
  2be1aa:	cmp    rdx,r15
  2be1ad:	cmovne eax,r14d
  2be1b1:	mov    DWORD PTR [rsp+0x88],eax
  2be1b8:	vbroadcasti128 ymm2,XMMWORD PTR [rip+0xffffffffffd7f5ff]        # 3d7c0 <BLAKE3_IV>
  2be1c1:	vpbroadcastd ymm8,DWORD PTR [rsp+0x88]
  2be1cb:	vpblendd ymm3,ymm13,ymm8,0x88
  2be1d1:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2be1d8:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r9+rdx*1-0x40],0x1
  2be1e0:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x30]
  2be1e7:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r9+rdx*1-0x30],0x1
  2be1ef:	vshufps ymm4,ymm8,ymm9,0x88
  2be1f5:	vshufps ymm5,ymm8,ymm9,0xdd
  2be1fb:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2be202:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r9+rdx*1-0x20],0x1
  2be20a:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x10]
  2be211:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r9+rdx*1-0x10],0x1
  2be219:	vshufps ymm6,ymm8,ymm9,0x88
  2be21f:	vshufps ymm7,ymm8,ymm9,0xdd
  2be225:	vpshufd ymm6,ymm6,0x93
  2be22a:	vpshufd ymm7,ymm7,0x93
  2be22f:	mov    al,0x7
  2be231:	vpaddd ymm0,ymm0,ymm4
  2be235:	vpaddd ymm0,ymm0,ymm1
  2be239:	vpxord ymm3,ymm3,ymm0
  2be23f:	vprord ymm3,ymm3,0x10
  2be246:	vpaddd ymm2,ymm2,ymm3
  2be24a:	vpxord ymm1,ymm1,ymm2
  2be250:	vprord ymm1,ymm1,0xc
  2be257:	vpaddd ymm0,ymm0,ymm5
  2be25b:	vpaddd ymm0,ymm0,ymm1
  2be25f:	vpxord ymm3,ymm3,ymm0
  2be265:	vprord ymm3,ymm3,0x8
  2be26c:	vpaddd ymm2,ymm2,ymm3
  2be270:	vpxord ymm1,ymm1,ymm2
  2be276:	vprord ymm1,ymm1,0x7
  2be27d:	vpshufd ymm0,ymm0,0x93
  2be282:	vpshufd ymm3,ymm3,0x4e
  2be287:	vpshufd ymm2,ymm2,0x39
  2be28c:	vpaddd ymm0,ymm0,ymm6
  2be290:	vpaddd ymm0,ymm0,ymm1
  2be294:	vpxord ymm3,ymm3,ymm0
  2be29a:	vprord ymm3,ymm3,0x10
  2be2a1:	vpaddd ymm2,ymm2,ymm3
  2be2a5:	vpxord ymm1,ymm1,ymm2
  2be2ab:	vprord ymm1,ymm1,0xc
  2be2b2:	vpaddd ymm0,ymm0,ymm7
  2be2b6:	vpaddd ymm0,ymm0,ymm1
  2be2ba:	vpxord ymm3,ymm3,ymm0
  2be2c0:	vprord ymm3,ymm3,0x8
  2be2c7:	vpaddd ymm2,ymm2,ymm3
  2be2cb:	vpxord ymm1,ymm1,ymm2
  2be2d1:	vprord ymm1,ymm1,0x7
  2be2d8:	vpshufd ymm0,ymm0,0x39
  2be2dd:	vpshufd ymm3,ymm3,0x4e
  2be2e2:	vpshufd ymm2,ymm2,0x93
  2be2e7:	dec    al
  2be2e9:	je     2be330 <_blake3_servil_hash_many_avx512+0x3530>
  2be2eb:	vshufps ymm8,ymm4,ymm5,0xd6
  2be2f0:	vpshufd ymm9,ymm4,0xf
  2be2f5:	vpshufd ymm4,ymm8,0x39
  2be2fb:	vshufps ymm8,ymm6,ymm7,0xfa
  2be300:	vpblendd ymm9,ymm9,ymm8,0xaa
  2be306:	vpunpcklqdq ymm8,ymm7,ymm5
  2be30a:	vpblendd ymm8,ymm8,ymm6,0x88
  2be310:	vpshufd ymm8,ymm8,0x78
  2be316:	vpunpckhdq ymm5,ymm5,ymm7
  2be31a:	vpunpckldq ymm6,ymm6,ymm5
  2be31e:	vpshufd ymm7,ymm6,0x1e
  2be323:	vmovdqa ymm5,ymm9
  2be327:	vmovdqa ymm6,ymm8
  2be32b:	jmp    2be231 <_blake3_servil_hash_many_avx512+0x3431>
  2be330:	vpxor  ymm0,ymm0,ymm2
  2be334:	vpxor  ymm1,ymm1,ymm3
  2be338:	mov    eax,r13d
  2be33b:	cmp    rdx,r15
  2be33e:	jne    2be1a0 <_blake3_servil_hash_many_avx512+0x33a0>
  2be344:	vmovdqu XMMWORD PTR [rbx],xmm0
  2be348:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2be34d:	vextracti128 XMMWORD PTR [rbx+0x20],ymm0,0x1
  2be354:	vextracti128 XMMWORD PTR [rbx+0x30],ymm1,0x1
  2be35b:	vmovdqa xmm0,XMMWORD PTR [rsp]
  2be360:	vmovdqa xmm2,XMMWORD PTR [rsp+0x40]
  2be366:	vmovdqu32 xmm0{k1},XMMWORD PTR [rsp+0x8]
  2be371:	vmovdqu32 xmm2{k1},XMMWORD PTR [rsp+0x48]
  2be37c:	vmovdqa XMMWORD PTR [rsp],xmm0
  2be381:	vmovdqa XMMWORD PTR [rsp+0x40],xmm2
  2be387:	add    rbx,0x40
  2be38b:	add    rdi,0x10
  2be38f:	sub    rsi,0x2
  2be393:	test   esi,0x1
  2be399:	je     2bc7fa <_blake3_servil_hash_many_avx512+0x19fa>
  2be39f:	vmovdqu xmm0,XMMWORD PTR [rcx]
  2be3a3:	vmovdqu xmm1,XMMWORD PTR [rcx+0x10]
  2be3a8:	vmovd  xmm14,DWORD PTR [rsp]
  2be3ad:	vpinsrd xmm14,xmm14,DWORD PTR [rsp+0x40],0x1
  2be3b5:	vpinsrd xmm14,xmm14,DWORD PTR [rip+0xffffffffffd7f3c9],0x2        # 3d788 <BLAKE3_BLOCK_LEN>
  2be3bf:	vmovdqa xmm15,XMMWORD PTR [rip+0xffffffffffd7f3f9]        # 3d7c0 <BLAKE3_IV>
  2be3c7:	mov    r8,QWORD PTR [rdi]
  2be3ca:	movzx  eax,BYTE PTR [rbp+0x40]
  2be3ce:	or     eax,r13d
  2be3d1:	xor    edx,edx
  2be3d3:	xchg   ax,ax
  2be3d5:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2be3e0:	mov    r14d,eax
  2be3e3:	or     eax,r12d
  2be3e6:	add    rdx,0x40
  2be3ea:	cmp    rdx,r15
  2be3ed:	cmovne eax,r14d
  2be3f1:	vpinsrd xmm3,xmm14,eax,0x3
  2be3f7:	vmovdqa xmm2,xmm15
  2be3fb:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2be402:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x30]
  2be409:	vshufps xmm4,xmm8,xmm9,0x88
  2be40f:	vshufps xmm5,xmm8,xmm9,0xdd
  2be415:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2be41c:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x10]
  2be423:	vshufps xmm6,xmm8,xmm9,0x88
  2be429:	vshufps xmm7,xmm8,xmm9,0xdd
  2be42f:	vpshufd xmm6,xmm6,0x93
  2be434:	vpshufd xmm7,xmm7,0x93
  2be439:	mov    al,0x7
  2be43b:	vpaddd xmm0,xmm0,xmm4
  2be43f:	vpaddd xmm0,xmm0,xmm1
  2be443:	vpxord xmm3,xmm3,xmm0
  2be449:	vprord xmm3,xmm3,0x10
  2be450:	vpaddd xmm2,xmm2,xmm3
  2be454:	vpxord xmm1,xmm1,xmm2
  2be45a:	vprord xmm1,xmm1,0xc
  2be461:	vpaddd xmm0,xmm0,xmm5
  2be465:	vpaddd xmm0,xmm0,xmm1
  2be469:	vpxord xmm3,xmm3,xmm0
  2be46f:	vprord xmm3,xmm3,0x8
  2be476:	vpaddd xmm2,xmm2,xmm3
  2be47a:	vpxord xmm1,xmm1,xmm2
  2be480:	vprord xmm1,xmm1,0x7
  2be487:	vpshufd xmm0,xmm0,0x93
  2be48c:	vpshufd xmm3,xmm3,0x4e
  2be491:	vpshufd xmm2,xmm2,0x39
  2be496:	vpaddd xmm0,xmm0,xmm6
  2be49a:	vpaddd xmm0,xmm0,xmm1
  2be49e:	vpxord xmm3,xmm3,xmm0
  2be4a4:	vprord xmm3,xmm3,0x10
  2be4ab:	vpaddd xmm2,xmm2,xmm3
  2be4af:	vpxord xmm1,xmm1,xmm2
  2be4b5:	vprord xmm1,xmm1,0xc
  2be4bc:	vpaddd xmm0,xmm0,xmm7
  2be4c0:	vpaddd xmm0,xmm0,xmm1
  2be4c4:	vpxord xmm3,xmm3,xmm0
  2be4ca:	vprord xmm3,xmm3,0x8
  2be4d1:	vpaddd xmm2,xmm2,xmm3
  2be4d5:	vpxord xmm1,xmm1,xmm2
  2be4db:	vprord xmm1,xmm1,0x7
  2be4e2:	vpshufd xmm0,xmm0,0x39
  2be4e7:	vpshufd xmm3,xmm3,0x4e
  2be4ec:	vpshufd xmm2,xmm2,0x93
  2be4f1:	dec    al
  2be4f3:	je     2be53a <_blake3_servil_hash_many_avx512+0x373a>
  2be4f5:	vshufps xmm8,xmm4,xmm5,0xd6
  2be4fa:	vpshufd xmm9,xmm4,0xf
  2be4ff:	vpshufd xmm4,xmm8,0x39
  2be505:	vshufps xmm8,xmm6,xmm7,0xfa
  2be50a:	vpblendd xmm9,xmm9,xmm8,0xaa
  2be510:	vpunpcklqdq xmm8,xmm7,xmm5
  2be514:	vpblendd xmm8,xmm8,xmm6,0x88
  2be51a:	vpshufd xmm8,xmm8,0x78
  2be520:	vpunpckhdq xmm5,xmm5,xmm7
  2be524:	vpunpckldq xmm6,xmm6,xmm5
  2be528:	vpshufd xmm7,xmm6,0x1e
  2be52d:	vmovdqa xmm5,xmm9
  2be531:	vmovdqa xmm6,xmm8
  2be535:	jmp    2be43b <_blake3_servil_hash_many_avx512+0x363b>
  2be53a:	vpxor  xmm0,xmm0,xmm2
  2be53e:	vpxor  xmm1,xmm1,xmm3
  2be542:	mov    eax,r13d
  2be545:	cmp    rdx,r15
  2be548:	jne    2be3e0 <_blake3_servil_hash_many_avx512+0x35e0>
  2be54e:	vmovdqu XMMWORD PTR [rbx],xmm0
  2be552:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2be557:	jmp    2bc7fa <_blake3_servil_hash_many_avx512+0x19fa>
  2be55c:	nop    DWORD PTR [rax]
  2be55f:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2be56a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2be575:	data16 cs nop WORD PTR [rax+rax*1+0x0]
