
/home/samshackleton/blake3-reports/review/github-round-20261024-2254/native/private-symbols-bench:     file format elf64-x86-64


Disassembly of section .text:

00000000002aef80 <_blake3_hash_many_avx512>:
  2aef80:	endbr64
  2aef84:	push   r15
  2aef86:	push   r14
  2aef88:	push   r13
  2aef8a:	push   r12
  2aef8c:	push   rbx
  2aef8d:	push   rbp
  2aef8e:	mov    rbp,rsp
  2aef91:	sub    rsp,0x90
  2aef98:	and    rsp,0xffffffffffffffc0
  2aef9c:	neg    r9
  2aef9f:	kmovw  k1,r9d
  2aefa4:	vmovd  xmm0,r8d
  2aefa9:	vpbroadcastd ymm0,xmm0
  2aefae:	shr    r8,0x20
  2aefb2:	vmovd  xmm1,r8d
  2aefb7:	vpbroadcastd ymm1,xmm1
  2aefbc:	vmovdqa ymm4,ymm1
  2aefc0:	vmovdqa ymm5,ymm1
  2aefc4:	vpaddd ymm2,ymm0,YMMWORD PTR [rip+0xffffffffffd8e434]        # 3d400 <ADD0>
  2aefcc:	vpaddd ymm3,ymm0,YMMWORD PTR [rip+0xffffffffffd8e44c]        # 3d420 <ADD0+0x20>
  2aefd4:	vpcmpltud k2,ymm2,ymm0
  2aefdb:	vpcmpltud k3,ymm3,ymm0
  2aefe2:	vpaddd ymm4{k2},ymm4,DWORD BCST [rip+0xffffffffffd8e454]        # 3d440 <ADD1>
  2aefec:	vpaddd ymm5{k3},ymm5,DWORD BCST [rip+0xffffffffffd8e44a]        # 3d440 <ADD1>
  2aeff6:	knotw  k2,k1
  2aeffa:	vmovdqa32 ymm2{k2},ymm0
  2af000:	vmovdqa32 ymm3{k2},ymm0
  2af006:	vmovdqa32 ymm4{k2},ymm1
  2af00c:	vmovdqa32 ymm5{k2},ymm1
  2af012:	vmovdqa YMMWORD PTR [rsp],ymm2
  2af017:	vmovdqa YMMWORD PTR [rsp+0x20],ymm3
  2af01d:	vmovdqa YMMWORD PTR [rsp+0x40],ymm4
  2af023:	vmovdqa YMMWORD PTR [rsp+0x60],ymm5
  2af029:	shl    rdx,0x6
  2af02d:	mov    QWORD PTR [rsp+0x80],rdx
  2af035:	cmp    rsi,0x10
  2af039:	jb     2b09c0 <_blake3_hash_many_avx512+0x1a40>
  2af03f:	vpbroadcastd zmm0,DWORD PTR [rcx]
  2af045:	vpbroadcastd zmm1,DWORD PTR [rcx+0x4]
  2af04c:	vpbroadcastd zmm2,DWORD PTR [rcx+0x8]
  2af053:	vpbroadcastd zmm3,DWORD PTR [rcx+0xc]
  2af05a:	vpbroadcastd zmm4,DWORD PTR [rcx+0x10]
  2af061:	vpbroadcastd zmm5,DWORD PTR [rcx+0x14]
  2af068:	vpbroadcastd zmm6,DWORD PTR [rcx+0x18]
  2af06f:	vpbroadcastd zmm7,DWORD PTR [rcx+0x1c]
  2af076:	movzx  eax,BYTE PTR [rbp+0x38]
  2af07a:	movzx  ebx,BYTE PTR [rbp+0x40]
  2af07e:	or     eax,ebx
  2af080:	xor    edx,edx
  2af082:	nop    DWORD PTR [rax+rax*1+0x0]
  2af08a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2af095:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2af0a0:	movzx  ebx,BYTE PTR [rbp+0x48]
  2af0a4:	or     ebx,eax
  2af0a6:	add    rdx,0x40
  2af0aa:	cmp    rdx,QWORD PTR [rsp+0x80]
  2af0b2:	cmove  eax,ebx
  2af0b5:	mov    DWORD PTR [rsp+0x88],eax
  2af0bc:	mov    r8,QWORD PTR [rdi]
  2af0bf:	mov    r9,QWORD PTR [rdi+0x8]
  2af0c3:	mov    r10,QWORD PTR [rdi+0x10]
  2af0c7:	mov    r11,QWORD PTR [rdi+0x18]
  2af0cb:	mov    r12,QWORD PTR [rdi+0x40]
  2af0cf:	mov    r13,QWORD PTR [rdi+0x48]
  2af0d3:	mov    r14,QWORD PTR [rdi+0x50]
  2af0d7:	mov    r15,QWORD PTR [rdi+0x58]
  2af0db:	vmovdqu32 ymm16,YMMWORD PTR [rdx+r8*1-0x40]
  2af0e3:	vinserti64x4 zmm16,zmm16,YMMWORD PTR [rdx+r12*1-0x40],0x1
  2af0ec:	vmovdqu32 ymm17,YMMWORD PTR [rdx+r9*1-0x40]
  2af0f4:	vinserti64x4 zmm17,zmm17,YMMWORD PTR [rdx+r13*1-0x40],0x1
  2af0fd:	vpunpcklqdq zmm8,zmm16,zmm17
  2af103:	vpunpckhqdq zmm9,zmm16,zmm17
  2af109:	vmovdqu32 ymm18,YMMWORD PTR [rdx+r10*1-0x40]
  2af111:	vinserti64x4 zmm18,zmm18,YMMWORD PTR [rdx+r14*1-0x40],0x1
  2af11a:	vmovdqu32 ymm19,YMMWORD PTR [rdx+r11*1-0x40]
  2af122:	vinserti64x4 zmm19,zmm19,YMMWORD PTR [rdx+r15*1-0x40],0x1
  2af12b:	vpunpcklqdq zmm10,zmm18,zmm19
  2af131:	vpunpckhqdq zmm11,zmm18,zmm19
  2af137:	mov    r8,QWORD PTR [rdi+0x20]
  2af13b:	mov    r9,QWORD PTR [rdi+0x28]
  2af13f:	mov    r10,QWORD PTR [rdi+0x30]
  2af143:	mov    r11,QWORD PTR [rdi+0x38]
  2af147:	mov    r12,QWORD PTR [rdi+0x60]
  2af14b:	mov    r13,QWORD PTR [rdi+0x68]
  2af14f:	mov    r14,QWORD PTR [rdi+0x70]
  2af153:	mov    r15,QWORD PTR [rdi+0x78]
  2af157:	vmovdqu32 ymm16,YMMWORD PTR [rdx+r8*1-0x40]
  2af15f:	vinserti64x4 zmm16,zmm16,YMMWORD PTR [rdx+r12*1-0x40],0x1
  2af168:	vmovdqu32 ymm17,YMMWORD PTR [rdx+r9*1-0x40]
  2af170:	vinserti64x4 zmm17,zmm17,YMMWORD PTR [rdx+r13*1-0x40],0x1
  2af179:	vpunpcklqdq zmm12,zmm16,zmm17
  2af17f:	vpunpckhqdq zmm13,zmm16,zmm17
  2af185:	vmovdqu32 ymm18,YMMWORD PTR [rdx+r10*1-0x40]
  2af18d:	vinserti64x4 zmm18,zmm18,YMMWORD PTR [rdx+r14*1-0x40],0x1
  2af196:	vmovdqu32 ymm19,YMMWORD PTR [rdx+r11*1-0x40]
  2af19e:	vinserti64x4 zmm19,zmm19,YMMWORD PTR [rdx+r15*1-0x40],0x1
  2af1a7:	vpunpcklqdq zmm14,zmm18,zmm19
  2af1ad:	vpunpckhqdq zmm15,zmm18,zmm19
  2af1b3:	vmovdqa32 zmm27,ZMMWORD PTR [rip+0xffffffffffd8e1c3]        # 3d380 <INDEX0>
  2af1bd:	vmovdqa32 zmm31,ZMMWORD PTR [rip+0xffffffffffd8e1f9]        # 3d3c0 <INDEX1>
  2af1c7:	vshufps zmm16,zmm8,zmm10,0x88
  2af1ce:	vshufps zmm17,zmm12,zmm14,0x88
  2af1d5:	vmovdqa32 zmm20,zmm16
  2af1db:	vpermt2d zmm16,zmm27,zmm17
  2af1e1:	vpermt2d zmm20,zmm31,zmm17
  2af1e7:	vshufps zmm17,zmm8,zmm10,0xdd
  2af1ee:	vshufps zmm30,zmm12,zmm14,0xdd
  2af1f5:	vmovdqa32 zmm21,zmm17
  2af1fb:	vpermt2d zmm17,zmm27,zmm30
  2af201:	vpermt2d zmm21,zmm31,zmm30
  2af207:	vshufps zmm18,zmm9,zmm11,0x88
  2af20e:	vshufps zmm8,zmm13,zmm15,0x88
  2af215:	vmovdqa32 zmm22,zmm18
  2af21b:	vpermt2d zmm18,zmm27,zmm8
  2af221:	vpermt2d zmm22,zmm31,zmm8
  2af227:	vshufps zmm19,zmm9,zmm11,0xdd
  2af22e:	vshufps zmm8,zmm13,zmm15,0xdd
  2af235:	vmovdqa32 zmm23,zmm19
  2af23b:	vpermt2d zmm19,zmm27,zmm8
  2af241:	vpermt2d zmm23,zmm31,zmm8
  2af247:	mov    r8,QWORD PTR [rdi]
  2af24a:	mov    r9,QWORD PTR [rdi+0x8]
  2af24e:	mov    r10,QWORD PTR [rdi+0x10]
  2af252:	mov    r11,QWORD PTR [rdi+0x18]
  2af256:	mov    r12,QWORD PTR [rdi+0x40]
  2af25a:	mov    r13,QWORD PTR [rdi+0x48]
  2af25e:	mov    r14,QWORD PTR [rdi+0x50]
  2af262:	mov    r15,QWORD PTR [rdi+0x58]
  2af266:	vmovdqu32 ymm24,YMMWORD PTR [r8+rdx*1-0x20]
  2af26e:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r12+rdx*1-0x20],0x1
  2af277:	vmovdqu32 ymm25,YMMWORD PTR [r9+rdx*1-0x20]
  2af27f:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r13+rdx*1-0x20],0x1
  2af288:	vpunpcklqdq zmm8,zmm24,zmm25
  2af28e:	vpunpckhqdq zmm9,zmm24,zmm25
  2af294:	vmovdqu32 ymm24,YMMWORD PTR [r10+rdx*1-0x20]
  2af29c:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r14+rdx*1-0x20],0x1
  2af2a5:	vmovdqu32 ymm25,YMMWORD PTR [r11+rdx*1-0x20]
  2af2ad:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r15+rdx*1-0x20],0x1
  2af2b6:	vpunpcklqdq zmm10,zmm24,zmm25
  2af2bc:	vpunpckhqdq zmm11,zmm24,zmm25
  2af2c2:	prefetcht0 BYTE PTR [r8+rdx*1+0x80]
  2af2cb:	prefetcht0 BYTE PTR [r12+rdx*1+0x80]
  2af2d4:	prefetcht0 BYTE PTR [r9+rdx*1+0x80]
  2af2dd:	prefetcht0 BYTE PTR [r13+rdx*1+0x80]
  2af2e6:	prefetcht0 BYTE PTR [r10+rdx*1+0x80]
  2af2ef:	prefetcht0 BYTE PTR [r14+rdx*1+0x80]
  2af2f8:	prefetcht0 BYTE PTR [r11+rdx*1+0x80]
  2af301:	prefetcht0 BYTE PTR [r15+rdx*1+0x80]
  2af30a:	mov    r8,QWORD PTR [rdi+0x20]
  2af30e:	mov    r9,QWORD PTR [rdi+0x28]
  2af312:	mov    r10,QWORD PTR [rdi+0x30]
  2af316:	mov    r11,QWORD PTR [rdi+0x38]
  2af31a:	mov    r12,QWORD PTR [rdi+0x60]
  2af31e:	mov    r13,QWORD PTR [rdi+0x68]
  2af322:	mov    r14,QWORD PTR [rdi+0x70]
  2af326:	mov    r15,QWORD PTR [rdi+0x78]
  2af32a:	vmovdqu32 ymm24,YMMWORD PTR [r8+rdx*1-0x20]
  2af332:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r12+rdx*1-0x20],0x1
  2af33b:	vmovdqu32 ymm25,YMMWORD PTR [r9+rdx*1-0x20]
  2af343:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r13+rdx*1-0x20],0x1
  2af34c:	vpunpcklqdq zmm12,zmm24,zmm25
  2af352:	vpunpckhqdq zmm13,zmm24,zmm25
  2af358:	vmovdqu32 ymm24,YMMWORD PTR [r10+rdx*1-0x20]
  2af360:	vinserti64x4 zmm24,zmm24,YMMWORD PTR [r14+rdx*1-0x20],0x1
  2af369:	vmovdqu32 ymm25,YMMWORD PTR [r11+rdx*1-0x20]
  2af371:	vinserti64x4 zmm25,zmm25,YMMWORD PTR [r15+rdx*1-0x20],0x1
  2af37a:	vpunpcklqdq zmm14,zmm24,zmm25
  2af380:	vpunpckhqdq zmm15,zmm24,zmm25
  2af386:	prefetcht0 BYTE PTR [r8+rdx*1+0x80]
  2af38f:	prefetcht0 BYTE PTR [r12+rdx*1+0x80]
  2af398:	prefetcht0 BYTE PTR [r9+rdx*1+0x80]
  2af3a1:	prefetcht0 BYTE PTR [r13+rdx*1+0x80]
  2af3aa:	prefetcht0 BYTE PTR [r10+rdx*1+0x80]
  2af3b3:	prefetcht0 BYTE PTR [r14+rdx*1+0x80]
  2af3bc:	prefetcht0 BYTE PTR [r11+rdx*1+0x80]
  2af3c5:	prefetcht0 BYTE PTR [r15+rdx*1+0x80]
  2af3ce:	vshufps zmm24,zmm8,zmm10,0x88
  2af3d5:	vshufps zmm30,zmm12,zmm14,0x88
  2af3dc:	vmovdqa32 zmm28,zmm24
  2af3e2:	vpermt2d zmm24,zmm27,zmm30
  2af3e8:	vpermt2d zmm28,zmm31,zmm30
  2af3ee:	vshufps zmm25,zmm8,zmm10,0xdd
  2af3f5:	vshufps zmm30,zmm12,zmm14,0xdd
  2af3fc:	vmovdqa32 zmm29,zmm25
  2af402:	vpermt2d zmm25,zmm27,zmm30
  2af408:	vpermt2d zmm29,zmm31,zmm30
  2af40e:	vshufps zmm26,zmm9,zmm11,0x88
  2af415:	vshufps zmm8,zmm13,zmm15,0x88
  2af41c:	vmovdqa32 zmm30,zmm26
  2af422:	vpermt2d zmm26,zmm27,zmm8
  2af428:	vpermt2d zmm30,zmm31,zmm8
  2af42e:	vshufps zmm8,zmm9,zmm11,0xdd
  2af435:	vshufps zmm10,zmm13,zmm15,0xdd
  2af43c:	vpermi2d zmm27,zmm8,zmm10
  2af442:	vpermi2d zmm31,zmm8,zmm10
  2af448:	vpbroadcastd zmm8,DWORD PTR [rip+0xffffffffffd8e02e]        # 3d480 <BLAKE3_IV>
  2af452:	vpbroadcastd zmm9,DWORD PTR [rip+0xffffffffffd8e028]        # 3d484 <BLAKE3_IV_1>
  2af45c:	vpbroadcastd zmm10,DWORD PTR [rip+0xffffffffffd8e022]        # 3d488 <BLAKE3_IV_2>
  2af466:	vpbroadcastd zmm11,DWORD PTR [rip+0xffffffffffd8e01c]        # 3d48c <BLAKE3_IV_3>
  2af470:	vmovdqa32 zmm12,ZMMWORD PTR [rsp]
  2af477:	vmovdqa32 zmm13,ZMMWORD PTR [rsp+0x40]
  2af47f:	vpbroadcastd zmm14,DWORD PTR [rip+0xffffffffffd8dfbf]        # 3d448 <BLAKE3_BLOCK_LEN>
  2af489:	vpbroadcastd zmm15,DWORD PTR [rsp+0x88]
  2af491:	vpaddd zmm0,zmm0,zmm16
  2af497:	vpaddd zmm1,zmm1,zmm18
  2af49d:	vpaddd zmm2,zmm2,zmm20
  2af4a3:	vpaddd zmm3,zmm3,zmm22
  2af4a9:	vpaddd zmm0,zmm0,zmm4
  2af4af:	vpaddd zmm1,zmm1,zmm5
  2af4b5:	vpaddd zmm2,zmm2,zmm6
  2af4bb:	vpaddd zmm3,zmm3,zmm7
  2af4c1:	vpxord zmm12,zmm12,zmm0
  2af4c7:	vpxord zmm13,zmm13,zmm1
  2af4cd:	vpxord zmm14,zmm14,zmm2
  2af4d3:	vpxord zmm15,zmm15,zmm3
  2af4d9:	vprord zmm12,zmm12,0x10
  2af4e0:	vprord zmm13,zmm13,0x10
  2af4e7:	vprord zmm14,zmm14,0x10
  2af4ee:	vprord zmm15,zmm15,0x10
  2af4f5:	vpaddd zmm8,zmm8,zmm12
  2af4fb:	vpaddd zmm9,zmm9,zmm13
  2af501:	vpaddd zmm10,zmm10,zmm14
  2af507:	vpaddd zmm11,zmm11,zmm15
  2af50d:	vpxord zmm4,zmm4,zmm8
  2af513:	vpxord zmm5,zmm5,zmm9
  2af519:	vpxord zmm6,zmm6,zmm10
  2af51f:	vpxord zmm7,zmm7,zmm11
  2af525:	vprord zmm4,zmm4,0xc
  2af52c:	vprord zmm5,zmm5,0xc
  2af533:	vprord zmm6,zmm6,0xc
  2af53a:	vprord zmm7,zmm7,0xc
  2af541:	vpaddd zmm0,zmm0,zmm17
  2af547:	vpaddd zmm1,zmm1,zmm19
  2af54d:	vpaddd zmm2,zmm2,zmm21
  2af553:	vpaddd zmm3,zmm3,zmm23
  2af559:	vpaddd zmm0,zmm0,zmm4
  2af55f:	vpaddd zmm1,zmm1,zmm5
  2af565:	vpaddd zmm2,zmm2,zmm6
  2af56b:	vpaddd zmm3,zmm3,zmm7
  2af571:	vpxord zmm12,zmm12,zmm0
  2af577:	vpxord zmm13,zmm13,zmm1
  2af57d:	vpxord zmm14,zmm14,zmm2
  2af583:	vpxord zmm15,zmm15,zmm3
  2af589:	vprord zmm12,zmm12,0x8
  2af590:	vprord zmm13,zmm13,0x8
  2af597:	vprord zmm14,zmm14,0x8
  2af59e:	vprord zmm15,zmm15,0x8
  2af5a5:	vpaddd zmm8,zmm8,zmm12
  2af5ab:	vpaddd zmm9,zmm9,zmm13
  2af5b1:	vpaddd zmm10,zmm10,zmm14
  2af5b7:	vpaddd zmm11,zmm11,zmm15
  2af5bd:	vpxord zmm4,zmm4,zmm8
  2af5c3:	vpxord zmm5,zmm5,zmm9
  2af5c9:	vpxord zmm6,zmm6,zmm10
  2af5cf:	vpxord zmm7,zmm7,zmm11
  2af5d5:	vprord zmm4,zmm4,0x7
  2af5dc:	vprord zmm5,zmm5,0x7
  2af5e3:	vprord zmm6,zmm6,0x7
  2af5ea:	vprord zmm7,zmm7,0x7
  2af5f1:	vpaddd zmm0,zmm0,zmm24
  2af5f7:	vpaddd zmm1,zmm1,zmm26
  2af5fd:	vpaddd zmm2,zmm2,zmm28
  2af603:	vpaddd zmm3,zmm3,zmm30
  2af609:	vpaddd zmm0,zmm0,zmm5
  2af60f:	vpaddd zmm1,zmm1,zmm6
  2af615:	vpaddd zmm2,zmm2,zmm7
  2af61b:	vpaddd zmm3,zmm3,zmm4
  2af621:	vpxord zmm15,zmm15,zmm0
  2af627:	vpxord zmm12,zmm12,zmm1
  2af62d:	vpxord zmm13,zmm13,zmm2
  2af633:	vpxord zmm14,zmm14,zmm3
  2af639:	vprord zmm15,zmm15,0x10
  2af640:	vprord zmm12,zmm12,0x10
  2af647:	vprord zmm13,zmm13,0x10
  2af64e:	vprord zmm14,zmm14,0x10
  2af655:	vpaddd zmm10,zmm10,zmm15
  2af65b:	vpaddd zmm11,zmm11,zmm12
  2af661:	vpaddd zmm8,zmm8,zmm13
  2af667:	vpaddd zmm9,zmm9,zmm14
  2af66d:	vpxord zmm5,zmm5,zmm10
  2af673:	vpxord zmm6,zmm6,zmm11
  2af679:	vpxord zmm7,zmm7,zmm8
  2af67f:	vpxord zmm4,zmm4,zmm9
  2af685:	vprord zmm5,zmm5,0xc
  2af68c:	vprord zmm6,zmm6,0xc
  2af693:	vprord zmm7,zmm7,0xc
  2af69a:	vprord zmm4,zmm4,0xc
  2af6a1:	vpaddd zmm0,zmm0,zmm25
  2af6a7:	vpaddd zmm1,zmm1,zmm27
  2af6ad:	vpaddd zmm2,zmm2,zmm29
  2af6b3:	vpaddd zmm3,zmm3,zmm31
  2af6b9:	vpaddd zmm0,zmm0,zmm5
  2af6bf:	vpaddd zmm1,zmm1,zmm6
  2af6c5:	vpaddd zmm2,zmm2,zmm7
  2af6cb:	vpaddd zmm3,zmm3,zmm4
  2af6d1:	vpxord zmm15,zmm15,zmm0
  2af6d7:	vpxord zmm12,zmm12,zmm1
  2af6dd:	vpxord zmm13,zmm13,zmm2
  2af6e3:	vpxord zmm14,zmm14,zmm3
  2af6e9:	vprord zmm15,zmm15,0x8
  2af6f0:	vprord zmm12,zmm12,0x8
  2af6f7:	vprord zmm13,zmm13,0x8
  2af6fe:	vprord zmm14,zmm14,0x8
  2af705:	vpaddd zmm10,zmm10,zmm15
  2af70b:	vpaddd zmm11,zmm11,zmm12
  2af711:	vpaddd zmm8,zmm8,zmm13
  2af717:	vpaddd zmm9,zmm9,zmm14
  2af71d:	vpxord zmm5,zmm5,zmm10
  2af723:	vpxord zmm6,zmm6,zmm11
  2af729:	vpxord zmm7,zmm7,zmm8
  2af72f:	vpxord zmm4,zmm4,zmm9
  2af735:	vprord zmm5,zmm5,0x7
  2af73c:	vprord zmm6,zmm6,0x7
  2af743:	vprord zmm7,zmm7,0x7
  2af74a:	vprord zmm4,zmm4,0x7
  2af751:	vpaddd zmm0,zmm0,zmm18
  2af757:	vpaddd zmm1,zmm1,zmm19
  2af75d:	vpaddd zmm2,zmm2,zmm23
  2af763:	vpaddd zmm3,zmm3,zmm20
  2af769:	vpaddd zmm0,zmm0,zmm4
  2af76f:	vpaddd zmm1,zmm1,zmm5
  2af775:	vpaddd zmm2,zmm2,zmm6
  2af77b:	vpaddd zmm3,zmm3,zmm7
  2af781:	vpxord zmm12,zmm12,zmm0
  2af787:	vpxord zmm13,zmm13,zmm1
  2af78d:	vpxord zmm14,zmm14,zmm2
  2af793:	vpxord zmm15,zmm15,zmm3
  2af799:	vprord zmm12,zmm12,0x10
  2af7a0:	vprord zmm13,zmm13,0x10
  2af7a7:	vprord zmm14,zmm14,0x10
  2af7ae:	vprord zmm15,zmm15,0x10
  2af7b5:	vpaddd zmm8,zmm8,zmm12
  2af7bb:	vpaddd zmm9,zmm9,zmm13
  2af7c1:	vpaddd zmm10,zmm10,zmm14
  2af7c7:	vpaddd zmm11,zmm11,zmm15
  2af7cd:	vpxord zmm4,zmm4,zmm8
  2af7d3:	vpxord zmm5,zmm5,zmm9
  2af7d9:	vpxord zmm6,zmm6,zmm10
  2af7df:	vpxord zmm7,zmm7,zmm11
  2af7e5:	vprord zmm4,zmm4,0xc
  2af7ec:	vprord zmm5,zmm5,0xc
  2af7f3:	vprord zmm6,zmm6,0xc
  2af7fa:	vprord zmm7,zmm7,0xc
  2af801:	vpaddd zmm0,zmm0,zmm22
  2af807:	vpaddd zmm1,zmm1,zmm26
  2af80d:	vpaddd zmm2,zmm2,zmm16
  2af813:	vpaddd zmm3,zmm3,zmm29
  2af819:	vpaddd zmm0,zmm0,zmm4
  2af81f:	vpaddd zmm1,zmm1,zmm5
  2af825:	vpaddd zmm2,zmm2,zmm6
  2af82b:	vpaddd zmm3,zmm3,zmm7
  2af831:	vpxord zmm12,zmm12,zmm0
  2af837:	vpxord zmm13,zmm13,zmm1
  2af83d:	vpxord zmm14,zmm14,zmm2
  2af843:	vpxord zmm15,zmm15,zmm3
  2af849:	vprord zmm12,zmm12,0x8
  2af850:	vprord zmm13,zmm13,0x8
  2af857:	vprord zmm14,zmm14,0x8
  2af85e:	vprord zmm15,zmm15,0x8
  2af865:	vpaddd zmm8,zmm8,zmm12
  2af86b:	vpaddd zmm9,zmm9,zmm13
  2af871:	vpaddd zmm10,zmm10,zmm14
  2af877:	vpaddd zmm11,zmm11,zmm15
  2af87d:	vpxord zmm4,zmm4,zmm8
  2af883:	vpxord zmm5,zmm5,zmm9
  2af889:	vpxord zmm6,zmm6,zmm10
  2af88f:	vpxord zmm7,zmm7,zmm11
  2af895:	vprord zmm4,zmm4,0x7
  2af89c:	vprord zmm5,zmm5,0x7
  2af8a3:	vprord zmm6,zmm6,0x7
  2af8aa:	vprord zmm7,zmm7,0x7
  2af8b1:	vpaddd zmm0,zmm0,zmm17
  2af8b7:	vpaddd zmm1,zmm1,zmm28
  2af8bd:	vpaddd zmm2,zmm2,zmm25
  2af8c3:	vpaddd zmm3,zmm3,zmm31
  2af8c9:	vpaddd zmm0,zmm0,zmm5
  2af8cf:	vpaddd zmm1,zmm1,zmm6
  2af8d5:	vpaddd zmm2,zmm2,zmm7
  2af8db:	vpaddd zmm3,zmm3,zmm4
  2af8e1:	vpxord zmm15,zmm15,zmm0
  2af8e7:	vpxord zmm12,zmm12,zmm1
  2af8ed:	vpxord zmm13,zmm13,zmm2
  2af8f3:	vpxord zmm14,zmm14,zmm3
  2af8f9:	vprord zmm15,zmm15,0x10
  2af900:	vprord zmm12,zmm12,0x10
  2af907:	vprord zmm13,zmm13,0x10
  2af90e:	vprord zmm14,zmm14,0x10
  2af915:	vpaddd zmm10,zmm10,zmm15
  2af91b:	vpaddd zmm11,zmm11,zmm12
  2af921:	vpaddd zmm8,zmm8,zmm13
  2af927:	vpaddd zmm9,zmm9,zmm14
  2af92d:	vpxord zmm5,zmm5,zmm10
  2af933:	vpxord zmm6,zmm6,zmm11
  2af939:	vpxord zmm7,zmm7,zmm8
  2af93f:	vpxord zmm4,zmm4,zmm9
  2af945:	vprord zmm5,zmm5,0xc
  2af94c:	vprord zmm6,zmm6,0xc
  2af953:	vprord zmm7,zmm7,0xc
  2af95a:	vprord zmm4,zmm4,0xc
  2af961:	vpaddd zmm0,zmm0,zmm27
  2af967:	vpaddd zmm1,zmm1,zmm21
  2af96d:	vpaddd zmm2,zmm2,zmm30
  2af973:	vpaddd zmm3,zmm3,zmm24
  2af979:	vpaddd zmm0,zmm0,zmm5
  2af97f:	vpaddd zmm1,zmm1,zmm6
  2af985:	vpaddd zmm2,zmm2,zmm7
  2af98b:	vpaddd zmm3,zmm3,zmm4
  2af991:	vpxord zmm15,zmm15,zmm0
  2af997:	vpxord zmm12,zmm12,zmm1
  2af99d:	vpxord zmm13,zmm13,zmm2
  2af9a3:	vpxord zmm14,zmm14,zmm3
  2af9a9:	vprord zmm15,zmm15,0x8
  2af9b0:	vprord zmm12,zmm12,0x8
  2af9b7:	vprord zmm13,zmm13,0x8
  2af9be:	vprord zmm14,zmm14,0x8
  2af9c5:	vpaddd zmm10,zmm10,zmm15
  2af9cb:	vpaddd zmm11,zmm11,zmm12
  2af9d1:	vpaddd zmm8,zmm8,zmm13
  2af9d7:	vpaddd zmm9,zmm9,zmm14
  2af9dd:	vpxord zmm5,zmm5,zmm10
  2af9e3:	vpxord zmm6,zmm6,zmm11
  2af9e9:	vpxord zmm7,zmm7,zmm8
  2af9ef:	vpxord zmm4,zmm4,zmm9
  2af9f5:	vprord zmm5,zmm5,0x7
  2af9fc:	vprord zmm6,zmm6,0x7
  2afa03:	vprord zmm7,zmm7,0x7
  2afa0a:	vprord zmm4,zmm4,0x7
  2afa11:	vpaddd zmm0,zmm0,zmm19
  2afa17:	vpaddd zmm1,zmm1,zmm26
  2afa1d:	vpaddd zmm2,zmm2,zmm29
  2afa23:	vpaddd zmm3,zmm3,zmm23
  2afa29:	vpaddd zmm0,zmm0,zmm4
  2afa2f:	vpaddd zmm1,zmm1,zmm5
  2afa35:	vpaddd zmm2,zmm2,zmm6
  2afa3b:	vpaddd zmm3,zmm3,zmm7
  2afa41:	vpxord zmm12,zmm12,zmm0
  2afa47:	vpxord zmm13,zmm13,zmm1
  2afa4d:	vpxord zmm14,zmm14,zmm2
  2afa53:	vpxord zmm15,zmm15,zmm3
  2afa59:	vprord zmm12,zmm12,0x10
  2afa60:	vprord zmm13,zmm13,0x10
  2afa67:	vprord zmm14,zmm14,0x10
  2afa6e:	vprord zmm15,zmm15,0x10
  2afa75:	vpaddd zmm8,zmm8,zmm12
  2afa7b:	vpaddd zmm9,zmm9,zmm13
  2afa81:	vpaddd zmm10,zmm10,zmm14
  2afa87:	vpaddd zmm11,zmm11,zmm15
  2afa8d:	vpxord zmm4,zmm4,zmm8
  2afa93:	vpxord zmm5,zmm5,zmm9
  2afa99:	vpxord zmm6,zmm6,zmm10
  2afa9f:	vpxord zmm7,zmm7,zmm11
  2afaa5:	vprord zmm4,zmm4,0xc
  2afaac:	vprord zmm5,zmm5,0xc
  2afab3:	vprord zmm6,zmm6,0xc
  2afaba:	vprord zmm7,zmm7,0xc
  2afac1:	vpaddd zmm0,zmm0,zmm20
  2afac7:	vpaddd zmm1,zmm1,zmm28
  2afacd:	vpaddd zmm2,zmm2,zmm18
  2afad3:	vpaddd zmm3,zmm3,zmm30
  2afad9:	vpaddd zmm0,zmm0,zmm4
  2afadf:	vpaddd zmm1,zmm1,zmm5
  2afae5:	vpaddd zmm2,zmm2,zmm6
  2afaeb:	vpaddd zmm3,zmm3,zmm7
  2afaf1:	vpxord zmm12,zmm12,zmm0
  2afaf7:	vpxord zmm13,zmm13,zmm1
  2afafd:	vpxord zmm14,zmm14,zmm2
  2afb03:	vpxord zmm15,zmm15,zmm3
  2afb09:	vprord zmm12,zmm12,0x8
  2afb10:	vprord zmm13,zmm13,0x8
  2afb17:	vprord zmm14,zmm14,0x8
  2afb1e:	vprord zmm15,zmm15,0x8
  2afb25:	vpaddd zmm8,zmm8,zmm12
  2afb2b:	vpaddd zmm9,zmm9,zmm13
  2afb31:	vpaddd zmm10,zmm10,zmm14
  2afb37:	vpaddd zmm11,zmm11,zmm15
  2afb3d:	vpxord zmm4,zmm4,zmm8
  2afb43:	vpxord zmm5,zmm5,zmm9
  2afb49:	vpxord zmm6,zmm6,zmm10
  2afb4f:	vpxord zmm7,zmm7,zmm11
  2afb55:	vprord zmm4,zmm4,0x7
  2afb5c:	vprord zmm5,zmm5,0x7
  2afb63:	vprord zmm6,zmm6,0x7
  2afb6a:	vprord zmm7,zmm7,0x7
  2afb71:	vpaddd zmm0,zmm0,zmm22
  2afb77:	vpaddd zmm1,zmm1,zmm25
  2afb7d:	vpaddd zmm2,zmm2,zmm27
  2afb83:	vpaddd zmm3,zmm3,zmm24
  2afb89:	vpaddd zmm0,zmm0,zmm5
  2afb8f:	vpaddd zmm1,zmm1,zmm6
  2afb95:	vpaddd zmm2,zmm2,zmm7
  2afb9b:	vpaddd zmm3,zmm3,zmm4
  2afba1:	vpxord zmm15,zmm15,zmm0
  2afba7:	vpxord zmm12,zmm12,zmm1
  2afbad:	vpxord zmm13,zmm13,zmm2
  2afbb3:	vpxord zmm14,zmm14,zmm3
  2afbb9:	vprord zmm15,zmm15,0x10
  2afbc0:	vprord zmm12,zmm12,0x10
  2afbc7:	vprord zmm13,zmm13,0x10
  2afbce:	vprord zmm14,zmm14,0x10
  2afbd5:	vpaddd zmm10,zmm10,zmm15
  2afbdb:	vpaddd zmm11,zmm11,zmm12
  2afbe1:	vpaddd zmm8,zmm8,zmm13
  2afbe7:	vpaddd zmm9,zmm9,zmm14
  2afbed:	vpxord zmm5,zmm5,zmm10
  2afbf3:	vpxord zmm6,zmm6,zmm11
  2afbf9:	vpxord zmm7,zmm7,zmm8
  2afbff:	vpxord zmm4,zmm4,zmm9
  2afc05:	vprord zmm5,zmm5,0xc
  2afc0c:	vprord zmm6,zmm6,0xc
  2afc13:	vprord zmm7,zmm7,0xc
  2afc1a:	vprord zmm4,zmm4,0xc
  2afc21:	vpaddd zmm0,zmm0,zmm21
  2afc27:	vpaddd zmm1,zmm1,zmm16
  2afc2d:	vpaddd zmm2,zmm2,zmm31
  2afc33:	vpaddd zmm3,zmm3,zmm17
  2afc39:	vpaddd zmm0,zmm0,zmm5
  2afc3f:	vpaddd zmm1,zmm1,zmm6
  2afc45:	vpaddd zmm2,zmm2,zmm7
  2afc4b:	vpaddd zmm3,zmm3,zmm4
  2afc51:	vpxord zmm15,zmm15,zmm0
  2afc57:	vpxord zmm12,zmm12,zmm1
  2afc5d:	vpxord zmm13,zmm13,zmm2
  2afc63:	vpxord zmm14,zmm14,zmm3
  2afc69:	vprord zmm15,zmm15,0x8
  2afc70:	vprord zmm12,zmm12,0x8
  2afc77:	vprord zmm13,zmm13,0x8
  2afc7e:	vprord zmm14,zmm14,0x8
  2afc85:	vpaddd zmm10,zmm10,zmm15
  2afc8b:	vpaddd zmm11,zmm11,zmm12
  2afc91:	vpaddd zmm8,zmm8,zmm13
  2afc97:	vpaddd zmm9,zmm9,zmm14
  2afc9d:	vpxord zmm5,zmm5,zmm10
  2afca3:	vpxord zmm6,zmm6,zmm11
  2afca9:	vpxord zmm7,zmm7,zmm8
  2afcaf:	vpxord zmm4,zmm4,zmm9
  2afcb5:	vprord zmm5,zmm5,0x7
  2afcbc:	vprord zmm6,zmm6,0x7
  2afcc3:	vprord zmm7,zmm7,0x7
  2afcca:	vprord zmm4,zmm4,0x7
  2afcd1:	vpaddd zmm0,zmm0,zmm26
  2afcd7:	vpaddd zmm1,zmm1,zmm28
  2afcdd:	vpaddd zmm2,zmm2,zmm30
  2afce3:	vpaddd zmm3,zmm3,zmm29
  2afce9:	vpaddd zmm0,zmm0,zmm4
  2afcef:	vpaddd zmm1,zmm1,zmm5
  2afcf5:	vpaddd zmm2,zmm2,zmm6
  2afcfb:	vpaddd zmm3,zmm3,zmm7
  2afd01:	vpxord zmm12,zmm12,zmm0
  2afd07:	vpxord zmm13,zmm13,zmm1
  2afd0d:	vpxord zmm14,zmm14,zmm2
  2afd13:	vpxord zmm15,zmm15,zmm3
  2afd19:	vprord zmm12,zmm12,0x10
  2afd20:	vprord zmm13,zmm13,0x10
  2afd27:	vprord zmm14,zmm14,0x10
  2afd2e:	vprord zmm15,zmm15,0x10
  2afd35:	vpaddd zmm8,zmm8,zmm12
  2afd3b:	vpaddd zmm9,zmm9,zmm13
  2afd41:	vpaddd zmm10,zmm10,zmm14
  2afd47:	vpaddd zmm11,zmm11,zmm15
  2afd4d:	vpxord zmm4,zmm4,zmm8
  2afd53:	vpxord zmm5,zmm5,zmm9
  2afd59:	vpxord zmm6,zmm6,zmm10
  2afd5f:	vpxord zmm7,zmm7,zmm11
  2afd65:	vprord zmm4,zmm4,0xc
  2afd6c:	vprord zmm5,zmm5,0xc
  2afd73:	vprord zmm6,zmm6,0xc
  2afd7a:	vprord zmm7,zmm7,0xc
  2afd81:	vpaddd zmm0,zmm0,zmm23
  2afd87:	vpaddd zmm1,zmm1,zmm25
  2afd8d:	vpaddd zmm2,zmm2,zmm19
  2afd93:	vpaddd zmm3,zmm3,zmm31
  2afd99:	vpaddd zmm0,zmm0,zmm4
  2afd9f:	vpaddd zmm1,zmm1,zmm5
  2afda5:	vpaddd zmm2,zmm2,zmm6
  2afdab:	vpaddd zmm3,zmm3,zmm7
  2afdb1:	vpxord zmm12,zmm12,zmm0
  2afdb7:	vpxord zmm13,zmm13,zmm1
  2afdbd:	vpxord zmm14,zmm14,zmm2
  2afdc3:	vpxord zmm15,zmm15,zmm3
  2afdc9:	vprord zmm12,zmm12,0x8
  2afdd0:	vprord zmm13,zmm13,0x8
  2afdd7:	vprord zmm14,zmm14,0x8
  2afdde:	vprord zmm15,zmm15,0x8
  2afde5:	vpaddd zmm8,zmm8,zmm12
  2afdeb:	vpaddd zmm9,zmm9,zmm13
  2afdf1:	vpaddd zmm10,zmm10,zmm14
  2afdf7:	vpaddd zmm11,zmm11,zmm15
  2afdfd:	vpxord zmm4,zmm4,zmm8
  2afe03:	vpxord zmm5,zmm5,zmm9
  2afe09:	vpxord zmm6,zmm6,zmm10
  2afe0f:	vpxord zmm7,zmm7,zmm11
  2afe15:	vprord zmm4,zmm4,0x7
  2afe1c:	vprord zmm5,zmm5,0x7
  2afe23:	vprord zmm6,zmm6,0x7
  2afe2a:	vprord zmm7,zmm7,0x7
  2afe31:	vpaddd zmm0,zmm0,zmm20
  2afe37:	vpaddd zmm1,zmm1,zmm27
  2afe3d:	vpaddd zmm2,zmm2,zmm21
  2afe43:	vpaddd zmm3,zmm3,zmm17
  2afe49:	vpaddd zmm0,zmm0,zmm5
  2afe4f:	vpaddd zmm1,zmm1,zmm6
  2afe55:	vpaddd zmm2,zmm2,zmm7
  2afe5b:	vpaddd zmm3,zmm3,zmm4
  2afe61:	vpxord zmm15,zmm15,zmm0
  2afe67:	vpxord zmm12,zmm12,zmm1
  2afe6d:	vpxord zmm13,zmm13,zmm2
  2afe73:	vpxord zmm14,zmm14,zmm3
  2afe79:	vprord zmm15,zmm15,0x10
  2afe80:	vprord zmm12,zmm12,0x10
  2afe87:	vprord zmm13,zmm13,0x10
  2afe8e:	vprord zmm14,zmm14,0x10
  2afe95:	vpaddd zmm10,zmm10,zmm15
  2afe9b:	vpaddd zmm11,zmm11,zmm12
  2afea1:	vpaddd zmm8,zmm8,zmm13
  2afea7:	vpaddd zmm9,zmm9,zmm14
  2afead:	vpxord zmm5,zmm5,zmm10
  2afeb3:	vpxord zmm6,zmm6,zmm11
  2afeb9:	vpxord zmm7,zmm7,zmm8
  2afebf:	vpxord zmm4,zmm4,zmm9
  2afec5:	vprord zmm5,zmm5,0xc
  2afecc:	vprord zmm6,zmm6,0xc
  2afed3:	vprord zmm7,zmm7,0xc
  2afeda:	vprord zmm4,zmm4,0xc
  2afee1:	vpaddd zmm0,zmm0,zmm16
  2afee7:	vpaddd zmm1,zmm1,zmm18
  2afeed:	vpaddd zmm2,zmm2,zmm24
  2afef3:	vpaddd zmm3,zmm3,zmm22
  2afef9:	vpaddd zmm0,zmm0,zmm5
  2afeff:	vpaddd zmm1,zmm1,zmm6
  2aff05:	vpaddd zmm2,zmm2,zmm7
  2aff0b:	vpaddd zmm3,zmm3,zmm4
  2aff11:	vpxord zmm15,zmm15,zmm0
  2aff17:	vpxord zmm12,zmm12,zmm1
  2aff1d:	vpxord zmm13,zmm13,zmm2
  2aff23:	vpxord zmm14,zmm14,zmm3
  2aff29:	vprord zmm15,zmm15,0x8
  2aff30:	vprord zmm12,zmm12,0x8
  2aff37:	vprord zmm13,zmm13,0x8
  2aff3e:	vprord zmm14,zmm14,0x8
  2aff45:	vpaddd zmm10,zmm10,zmm15
  2aff4b:	vpaddd zmm11,zmm11,zmm12
  2aff51:	vpaddd zmm8,zmm8,zmm13
  2aff57:	vpaddd zmm9,zmm9,zmm14
  2aff5d:	vpxord zmm5,zmm5,zmm10
  2aff63:	vpxord zmm6,zmm6,zmm11
  2aff69:	vpxord zmm7,zmm7,zmm8
  2aff6f:	vpxord zmm4,zmm4,zmm9
  2aff75:	vprord zmm5,zmm5,0x7
  2aff7c:	vprord zmm6,zmm6,0x7
  2aff83:	vprord zmm7,zmm7,0x7
  2aff8a:	vprord zmm4,zmm4,0x7
  2aff91:	vpaddd zmm0,zmm0,zmm28
  2aff97:	vpaddd zmm1,zmm1,zmm25
  2aff9d:	vpaddd zmm2,zmm2,zmm31
  2affa3:	vpaddd zmm3,zmm3,zmm30
  2affa9:	vpaddd zmm0,zmm0,zmm4
  2affaf:	vpaddd zmm1,zmm1,zmm5
  2affb5:	vpaddd zmm2,zmm2,zmm6
  2affbb:	vpaddd zmm3,zmm3,zmm7
  2affc1:	vpxord zmm12,zmm12,zmm0
  2affc7:	vpxord zmm13,zmm13,zmm1
  2affcd:	vpxord zmm14,zmm14,zmm2
  2affd3:	vpxord zmm15,zmm15,zmm3
  2affd9:	vprord zmm12,zmm12,0x10
  2affe0:	vprord zmm13,zmm13,0x10
  2affe7:	vprord zmm14,zmm14,0x10
  2affee:	vprord zmm15,zmm15,0x10
  2afff5:	vpaddd zmm8,zmm8,zmm12
  2afffb:	vpaddd zmm9,zmm9,zmm13
  2b0001:	vpaddd zmm10,zmm10,zmm14
  2b0007:	vpaddd zmm11,zmm11,zmm15
  2b000d:	vpxord zmm4,zmm4,zmm8
  2b0013:	vpxord zmm5,zmm5,zmm9
  2b0019:	vpxord zmm6,zmm6,zmm10
  2b001f:	vpxord zmm7,zmm7,zmm11
  2b0025:	vprord zmm4,zmm4,0xc
  2b002c:	vprord zmm5,zmm5,0xc
  2b0033:	vprord zmm6,zmm6,0xc
  2b003a:	vprord zmm7,zmm7,0xc
  2b0041:	vpaddd zmm0,zmm0,zmm29
  2b0047:	vpaddd zmm1,zmm1,zmm27
  2b004d:	vpaddd zmm2,zmm2,zmm26
  2b0053:	vpaddd zmm3,zmm3,zmm24
  2b0059:	vpaddd zmm0,zmm0,zmm4
  2b005f:	vpaddd zmm1,zmm1,zmm5
  2b0065:	vpaddd zmm2,zmm2,zmm6
  2b006b:	vpaddd zmm3,zmm3,zmm7
  2b0071:	vpxord zmm12,zmm12,zmm0
  2b0077:	vpxord zmm13,zmm13,zmm1
  2b007d:	vpxord zmm14,zmm14,zmm2
  2b0083:	vpxord zmm15,zmm15,zmm3
  2b0089:	vprord zmm12,zmm12,0x8
  2b0090:	vprord zmm13,zmm13,0x8
  2b0097:	vprord zmm14,zmm14,0x8
  2b009e:	vprord zmm15,zmm15,0x8
  2b00a5:	vpaddd zmm8,zmm8,zmm12
  2b00ab:	vpaddd zmm9,zmm9,zmm13
  2b00b1:	vpaddd zmm10,zmm10,zmm14
  2b00b7:	vpaddd zmm11,zmm11,zmm15
  2b00bd:	vpxord zmm4,zmm4,zmm8
  2b00c3:	vpxord zmm5,zmm5,zmm9
  2b00c9:	vpxord zmm6,zmm6,zmm10
  2b00cf:	vpxord zmm7,zmm7,zmm11
  2b00d5:	vprord zmm4,zmm4,0x7
  2b00dc:	vprord zmm5,zmm5,0x7
  2b00e3:	vprord zmm6,zmm6,0x7
  2b00ea:	vprord zmm7,zmm7,0x7
  2b00f1:	vpaddd zmm0,zmm0,zmm23
  2b00f7:	vpaddd zmm1,zmm1,zmm21
  2b00fd:	vpaddd zmm2,zmm2,zmm16
  2b0103:	vpaddd zmm3,zmm3,zmm22
  2b0109:	vpaddd zmm0,zmm0,zmm5
  2b010f:	vpaddd zmm1,zmm1,zmm6
  2b0115:	vpaddd zmm2,zmm2,zmm7
  2b011b:	vpaddd zmm3,zmm3,zmm4
  2b0121:	vpxord zmm15,zmm15,zmm0
  2b0127:	vpxord zmm12,zmm12,zmm1
  2b012d:	vpxord zmm13,zmm13,zmm2
  2b0133:	vpxord zmm14,zmm14,zmm3
  2b0139:	vprord zmm15,zmm15,0x10
  2b0140:	vprord zmm12,zmm12,0x10
  2b0147:	vprord zmm13,zmm13,0x10
  2b014e:	vprord zmm14,zmm14,0x10
  2b0155:	vpaddd zmm10,zmm10,zmm15
  2b015b:	vpaddd zmm11,zmm11,zmm12
  2b0161:	vpaddd zmm8,zmm8,zmm13
  2b0167:	vpaddd zmm9,zmm9,zmm14
  2b016d:	vpxord zmm5,zmm5,zmm10
  2b0173:	vpxord zmm6,zmm6,zmm11
  2b0179:	vpxord zmm7,zmm7,zmm8
  2b017f:	vpxord zmm4,zmm4,zmm9
  2b0185:	vprord zmm5,zmm5,0xc
  2b018c:	vprord zmm6,zmm6,0xc
  2b0193:	vprord zmm7,zmm7,0xc
  2b019a:	vprord zmm4,zmm4,0xc
  2b01a1:	vpaddd zmm0,zmm0,zmm18
  2b01a7:	vpaddd zmm1,zmm1,zmm19
  2b01ad:	vpaddd zmm2,zmm2,zmm17
  2b01b3:	vpaddd zmm3,zmm3,zmm20
  2b01b9:	vpaddd zmm0,zmm0,zmm5
  2b01bf:	vpaddd zmm1,zmm1,zmm6
  2b01c5:	vpaddd zmm2,zmm2,zmm7
  2b01cb:	vpaddd zmm3,zmm3,zmm4
  2b01d1:	vpxord zmm15,zmm15,zmm0
  2b01d7:	vpxord zmm12,zmm12,zmm1
  2b01dd:	vpxord zmm13,zmm13,zmm2
  2b01e3:	vpxord zmm14,zmm14,zmm3
  2b01e9:	vprord zmm15,zmm15,0x8
  2b01f0:	vprord zmm12,zmm12,0x8
  2b01f7:	vprord zmm13,zmm13,0x8
  2b01fe:	vprord zmm14,zmm14,0x8
  2b0205:	vpaddd zmm10,zmm10,zmm15
  2b020b:	vpaddd zmm11,zmm11,zmm12
  2b0211:	vpaddd zmm8,zmm8,zmm13
  2b0217:	vpaddd zmm9,zmm9,zmm14
  2b021d:	vpxord zmm5,zmm5,zmm10
  2b0223:	vpxord zmm6,zmm6,zmm11
  2b0229:	vpxord zmm7,zmm7,zmm8
  2b022f:	vpxord zmm4,zmm4,zmm9
  2b0235:	vprord zmm5,zmm5,0x7
  2b023c:	vprord zmm6,zmm6,0x7
  2b0243:	vprord zmm7,zmm7,0x7
  2b024a:	vprord zmm4,zmm4,0x7
  2b0251:	vpaddd zmm0,zmm0,zmm25
  2b0257:	vpaddd zmm1,zmm1,zmm27
  2b025d:	vpaddd zmm2,zmm2,zmm24
  2b0263:	vpaddd zmm3,zmm3,zmm31
  2b0269:	vpaddd zmm0,zmm0,zmm4
  2b026f:	vpaddd zmm1,zmm1,zmm5
  2b0275:	vpaddd zmm2,zmm2,zmm6
  2b027b:	vpaddd zmm3,zmm3,zmm7
  2b0281:	vpxord zmm12,zmm12,zmm0
  2b0287:	vpxord zmm13,zmm13,zmm1
  2b028d:	vpxord zmm14,zmm14,zmm2
  2b0293:	vpxord zmm15,zmm15,zmm3
  2b0299:	vprord zmm12,zmm12,0x10
  2b02a0:	vprord zmm13,zmm13,0x10
  2b02a7:	vprord zmm14,zmm14,0x10
  2b02ae:	vprord zmm15,zmm15,0x10
  2b02b5:	vpaddd zmm8,zmm8,zmm12
  2b02bb:	vpaddd zmm9,zmm9,zmm13
  2b02c1:	vpaddd zmm10,zmm10,zmm14
  2b02c7:	vpaddd zmm11,zmm11,zmm15
  2b02cd:	vpxord zmm4,zmm4,zmm8
  2b02d3:	vpxord zmm5,zmm5,zmm9
  2b02d9:	vpxord zmm6,zmm6,zmm10
  2b02df:	vpxord zmm7,zmm7,zmm11
  2b02e5:	vprord zmm4,zmm4,0xc
  2b02ec:	vprord zmm5,zmm5,0xc
  2b02f3:	vprord zmm6,zmm6,0xc
  2b02fa:	vprord zmm7,zmm7,0xc
  2b0301:	vpaddd zmm0,zmm0,zmm30
  2b0307:	vpaddd zmm1,zmm1,zmm21
  2b030d:	vpaddd zmm2,zmm2,zmm28
  2b0313:	vpaddd zmm3,zmm3,zmm17
  2b0319:	vpaddd zmm0,zmm0,zmm4
  2b031f:	vpaddd zmm1,zmm1,zmm5
  2b0325:	vpaddd zmm2,zmm2,zmm6
  2b032b:	vpaddd zmm3,zmm3,zmm7
  2b0331:	vpxord zmm12,zmm12,zmm0
  2b0337:	vpxord zmm13,zmm13,zmm1
  2b033d:	vpxord zmm14,zmm14,zmm2
  2b0343:	vpxord zmm15,zmm15,zmm3
  2b0349:	vprord zmm12,zmm12,0x8
  2b0350:	vprord zmm13,zmm13,0x8
  2b0357:	vprord zmm14,zmm14,0x8
  2b035e:	vprord zmm15,zmm15,0x8
  2b0365:	vpaddd zmm8,zmm8,zmm12
  2b036b:	vpaddd zmm9,zmm9,zmm13
  2b0371:	vpaddd zmm10,zmm10,zmm14
  2b0377:	vpaddd zmm11,zmm11,zmm15
  2b037d:	vpxord zmm4,zmm4,zmm8
  2b0383:	vpxord zmm5,zmm5,zmm9
  2b0389:	vpxord zmm6,zmm6,zmm10
  2b038f:	vpxord zmm7,zmm7,zmm11
  2b0395:	vprord zmm4,zmm4,0x7
  2b039c:	vprord zmm5,zmm5,0x7
  2b03a3:	vprord zmm6,zmm6,0x7
  2b03aa:	vprord zmm7,zmm7,0x7
  2b03b1:	vpaddd zmm0,zmm0,zmm29
  2b03b7:	vpaddd zmm1,zmm1,zmm16
  2b03bd:	vpaddd zmm2,zmm2,zmm18
  2b03c3:	vpaddd zmm3,zmm3,zmm20
  2b03c9:	vpaddd zmm0,zmm0,zmm5
  2b03cf:	vpaddd zmm1,zmm1,zmm6
  2b03d5:	vpaddd zmm2,zmm2,zmm7
  2b03db:	vpaddd zmm3,zmm3,zmm4
  2b03e1:	vpxord zmm15,zmm15,zmm0
  2b03e7:	vpxord zmm12,zmm12,zmm1
  2b03ed:	vpxord zmm13,zmm13,zmm2
  2b03f3:	vpxord zmm14,zmm14,zmm3
  2b03f9:	vprord zmm15,zmm15,0x10
  2b0400:	vprord zmm12,zmm12,0x10
  2b0407:	vprord zmm13,zmm13,0x10
  2b040e:	vprord zmm14,zmm14,0x10
  2b0415:	vpaddd zmm10,zmm10,zmm15
  2b041b:	vpaddd zmm11,zmm11,zmm12
  2b0421:	vpaddd zmm8,zmm8,zmm13
  2b0427:	vpaddd zmm9,zmm9,zmm14
  2b042d:	vpxord zmm5,zmm5,zmm10
  2b0433:	vpxord zmm6,zmm6,zmm11
  2b0439:	vpxord zmm7,zmm7,zmm8
  2b043f:	vpxord zmm4,zmm4,zmm9
  2b0445:	vprord zmm5,zmm5,0xc
  2b044c:	vprord zmm6,zmm6,0xc
  2b0453:	vprord zmm7,zmm7,0xc
  2b045a:	vprord zmm4,zmm4,0xc
  2b0461:	vpaddd zmm0,zmm0,zmm19
  2b0467:	vpaddd zmm1,zmm1,zmm26
  2b046d:	vpaddd zmm2,zmm2,zmm22
  2b0473:	vpaddd zmm3,zmm3,zmm23
  2b0479:	vpaddd zmm0,zmm0,zmm5
  2b047f:	vpaddd zmm1,zmm1,zmm6
  2b0485:	vpaddd zmm2,zmm2,zmm7
  2b048b:	vpaddd zmm3,zmm3,zmm4
  2b0491:	vpxord zmm15,zmm15,zmm0
  2b0497:	vpxord zmm12,zmm12,zmm1
  2b049d:	vpxord zmm13,zmm13,zmm2
  2b04a3:	vpxord zmm14,zmm14,zmm3
  2b04a9:	vprord zmm15,zmm15,0x8
  2b04b0:	vprord zmm12,zmm12,0x8
  2b04b7:	vprord zmm13,zmm13,0x8
  2b04be:	vprord zmm14,zmm14,0x8
  2b04c5:	vpaddd zmm10,zmm10,zmm15
  2b04cb:	vpaddd zmm11,zmm11,zmm12
  2b04d1:	vpaddd zmm8,zmm8,zmm13
  2b04d7:	vpaddd zmm9,zmm9,zmm14
  2b04dd:	vpxord zmm5,zmm5,zmm10
  2b04e3:	vpxord zmm6,zmm6,zmm11
  2b04e9:	vpxord zmm7,zmm7,zmm8
  2b04ef:	vpxord zmm4,zmm4,zmm9
  2b04f5:	vprord zmm5,zmm5,0x7
  2b04fc:	vprord zmm6,zmm6,0x7
  2b0503:	vprord zmm7,zmm7,0x7
  2b050a:	vprord zmm4,zmm4,0x7
  2b0511:	vpaddd zmm0,zmm0,zmm27
  2b0517:	vpaddd zmm1,zmm1,zmm21
  2b051d:	vpaddd zmm2,zmm2,zmm17
  2b0523:	vpaddd zmm3,zmm3,zmm24
  2b0529:	vpaddd zmm0,zmm0,zmm4
  2b052f:	vpaddd zmm1,zmm1,zmm5
  2b0535:	vpaddd zmm2,zmm2,zmm6
  2b053b:	vpaddd zmm3,zmm3,zmm7
  2b0541:	vpxord zmm12,zmm12,zmm0
  2b0547:	vpxord zmm13,zmm13,zmm1
  2b054d:	vpxord zmm14,zmm14,zmm2
  2b0553:	vpxord zmm15,zmm15,zmm3
  2b0559:	vprord zmm12,zmm12,0x10
  2b0560:	vprord zmm13,zmm13,0x10
  2b0567:	vprord zmm14,zmm14,0x10
  2b056e:	vprord zmm15,zmm15,0x10
  2b0575:	vpaddd zmm8,zmm8,zmm12
  2b057b:	vpaddd zmm9,zmm9,zmm13
  2b0581:	vpaddd zmm10,zmm10,zmm14
  2b0587:	vpaddd zmm11,zmm11,zmm15
  2b058d:	vpxord zmm4,zmm4,zmm8
  2b0593:	vpxord zmm5,zmm5,zmm9
  2b0599:	vpxord zmm6,zmm6,zmm10
  2b059f:	vpxord zmm7,zmm7,zmm11
  2b05a5:	vprord zmm4,zmm4,0xc
  2b05ac:	vprord zmm5,zmm5,0xc
  2b05b3:	vprord zmm6,zmm6,0xc
  2b05ba:	vprord zmm7,zmm7,0xc
  2b05c1:	vpaddd zmm0,zmm0,zmm31
  2b05c7:	vpaddd zmm1,zmm1,zmm16
  2b05cd:	vpaddd zmm2,zmm2,zmm25
  2b05d3:	vpaddd zmm3,zmm3,zmm22
  2b05d9:	vpaddd zmm0,zmm0,zmm4
  2b05df:	vpaddd zmm1,zmm1,zmm5
  2b05e5:	vpaddd zmm2,zmm2,zmm6
  2b05eb:	vpaddd zmm3,zmm3,zmm7
  2b05f1:	vpxord zmm12,zmm12,zmm0
  2b05f7:	vpxord zmm13,zmm13,zmm1
  2b05fd:	vpxord zmm14,zmm14,zmm2
  2b0603:	vpxord zmm15,zmm15,zmm3
  2b0609:	vprord zmm12,zmm12,0x8
  2b0610:	vprord zmm13,zmm13,0x8
  2b0617:	vprord zmm14,zmm14,0x8
  2b061e:	vprord zmm15,zmm15,0x8
  2b0625:	vpaddd zmm8,zmm8,zmm12
  2b062b:	vpaddd zmm9,zmm9,zmm13
  2b0631:	vpaddd zmm10,zmm10,zmm14
  2b0637:	vpaddd zmm11,zmm11,zmm15
  2b063d:	vpxord zmm4,zmm4,zmm8
  2b0643:	vpxord zmm5,zmm5,zmm9
  2b0649:	vpxord zmm6,zmm6,zmm10
  2b064f:	vpxord zmm7,zmm7,zmm11
  2b0655:	vprord zmm4,zmm4,0x7
  2b065c:	vprord zmm5,zmm5,0x7
  2b0663:	vprord zmm6,zmm6,0x7
  2b066a:	vprord zmm7,zmm7,0x7
  2b0671:	vpaddd zmm0,zmm0,zmm30
  2b0677:	vpaddd zmm1,zmm1,zmm18
  2b067d:	vpaddd zmm2,zmm2,zmm19
  2b0683:	vpaddd zmm3,zmm3,zmm23
  2b0689:	vpaddd zmm0,zmm0,zmm5
  2b068f:	vpaddd zmm1,zmm1,zmm6
  2b0695:	vpaddd zmm2,zmm2,zmm7
  2b069b:	vpaddd zmm3,zmm3,zmm4
  2b06a1:	vpxord zmm15,zmm15,zmm0
  2b06a7:	vpxord zmm12,zmm12,zmm1
  2b06ad:	vpxord zmm13,zmm13,zmm2
  2b06b3:	vpxord zmm14,zmm14,zmm3
  2b06b9:	vprord zmm15,zmm15,0x10
  2b06c0:	vprord zmm12,zmm12,0x10
  2b06c7:	vprord zmm13,zmm13,0x10
  2b06ce:	vprord zmm14,zmm14,0x10
  2b06d5:	vpaddd zmm10,zmm10,zmm15
  2b06db:	vpaddd zmm11,zmm11,zmm12
  2b06e1:	vpaddd zmm8,zmm8,zmm13
  2b06e7:	vpaddd zmm9,zmm9,zmm14
  2b06ed:	vpxord zmm5,zmm5,zmm10
  2b06f3:	vpxord zmm6,zmm6,zmm11
  2b06f9:	vpxord zmm7,zmm7,zmm8
  2b06ff:	vpxord zmm4,zmm4,zmm9
  2b0705:	vprord zmm5,zmm5,0xc
  2b070c:	vprord zmm6,zmm6,0xc
  2b0713:	vprord zmm7,zmm7,0xc
  2b071a:	vprord zmm4,zmm4,0xc
  2b0721:	vpaddd zmm0,zmm0,zmm26
  2b0727:	vpaddd zmm1,zmm1,zmm28
  2b072d:	vpaddd zmm2,zmm2,zmm20
  2b0733:	vpaddd zmm3,zmm3,zmm29
  2b0739:	vpaddd zmm0,zmm0,zmm5
  2b073f:	vpaddd zmm1,zmm1,zmm6
  2b0745:	vpaddd zmm2,zmm2,zmm7
  2b074b:	vpaddd zmm3,zmm3,zmm4
  2b0751:	vpxord zmm15,zmm15,zmm0
  2b0757:	vpxord zmm12,zmm12,zmm1
  2b075d:	vpxord zmm13,zmm13,zmm2
  2b0763:	vpxord zmm14,zmm14,zmm3
  2b0769:	vprord zmm15,zmm15,0x8
  2b0770:	vprord zmm12,zmm12,0x8
  2b0777:	vprord zmm13,zmm13,0x8
  2b077e:	vprord zmm14,zmm14,0x8
  2b0785:	vpaddd zmm10,zmm10,zmm15
  2b078b:	vpaddd zmm11,zmm11,zmm12
  2b0791:	vpaddd zmm8,zmm8,zmm13
  2b0797:	vpaddd zmm9,zmm9,zmm14
  2b079d:	vpxord zmm5,zmm5,zmm10
  2b07a3:	vpxord zmm6,zmm6,zmm11
  2b07a9:	vpxord zmm7,zmm7,zmm8
  2b07af:	vpxord zmm4,zmm4,zmm9
  2b07b5:	vprord zmm5,zmm5,0x7
  2b07bc:	vprord zmm6,zmm6,0x7
  2b07c3:	vprord zmm7,zmm7,0x7
  2b07ca:	vprord zmm4,zmm4,0x7
  2b07d1:	vpxord zmm0,zmm0,zmm8
  2b07d7:	vpxord zmm1,zmm1,zmm9
  2b07dd:	vpxord zmm2,zmm2,zmm10
  2b07e3:	vpxord zmm3,zmm3,zmm11
  2b07e9:	vpxord zmm4,zmm4,zmm12
  2b07ef:	vpxord zmm5,zmm5,zmm13
  2b07f5:	vpxord zmm6,zmm6,zmm14
  2b07fb:	vpxord zmm7,zmm7,zmm15
  2b0801:	movzx  eax,BYTE PTR [rbp+0x38]
  2b0805:	jne    2af0a0 <_blake3_hash_many_avx512+0x120>
  2b080b:	mov    rbx,QWORD PTR [rbp+0x50]
  2b080f:	vpunpckldq zmm16,zmm0,zmm1
  2b0815:	vpunpckhdq zmm17,zmm0,zmm1
  2b081b:	vpunpckldq zmm18,zmm2,zmm3
  2b0821:	vpunpckhdq zmm19,zmm2,zmm3
  2b0827:	vpunpckldq zmm20,zmm4,zmm5
  2b082d:	vpunpckhdq zmm21,zmm4,zmm5
  2b0833:	vpunpckldq zmm22,zmm6,zmm7
  2b0839:	vpunpckhdq zmm23,zmm6,zmm7
  2b083f:	vpunpcklqdq zmm0,zmm16,zmm18
  2b0845:	vpunpckhqdq zmm1,zmm16,zmm18
  2b084b:	vpunpcklqdq zmm2,zmm17,zmm19
  2b0851:	vpunpckhqdq zmm3,zmm17,zmm19
  2b0857:	vpunpcklqdq zmm4,zmm20,zmm22
  2b085d:	vpunpckhqdq zmm5,zmm20,zmm22
  2b0863:	vpunpcklqdq zmm6,zmm21,zmm23
  2b0869:	vpunpckhqdq zmm7,zmm21,zmm23
  2b086f:	vshufi32x4 zmm16,zmm0,zmm4,0x88
  2b0876:	vshufi32x4 zmm17,zmm1,zmm5,0x88
  2b087d:	vshufi32x4 zmm18,zmm2,zmm6,0x88
  2b0884:	vshufi32x4 zmm19,zmm3,zmm7,0x88
  2b088b:	vshufi32x4 zmm20,zmm0,zmm4,0xdd
  2b0892:	vshufi32x4 zmm21,zmm1,zmm5,0xdd
  2b0899:	vshufi32x4 zmm22,zmm2,zmm6,0xdd
  2b08a0:	vshufi32x4 zmm23,zmm3,zmm7,0xdd
  2b08a7:	vshufi32x4 zmm0,zmm16,zmm17,0x88
  2b08ae:	vshufi32x4 zmm1,zmm18,zmm19,0x88
  2b08b5:	vshufi32x4 zmm2,zmm20,zmm21,0x88
  2b08bc:	vshufi32x4 zmm3,zmm22,zmm23,0x88
  2b08c3:	vshufi32x4 zmm4,zmm16,zmm17,0xdd
  2b08ca:	vshufi32x4 zmm5,zmm18,zmm19,0xdd
  2b08d1:	vshufi32x4 zmm6,zmm20,zmm21,0xdd
  2b08d8:	vshufi32x4 zmm7,zmm22,zmm23,0xdd
  2b08df:	vmovdqu32 ZMMWORD PTR [rbx],zmm0
  2b08e5:	vmovdqu32 ZMMWORD PTR [rbx+0x40],zmm1
  2b08ec:	vmovdqu32 ZMMWORD PTR [rbx+0x80],zmm2
  2b08f3:	vmovdqu32 ZMMWORD PTR [rbx+0xc0],zmm3
  2b08fa:	vmovdqu32 ZMMWORD PTR [rbx+0x100],zmm4
  2b0901:	vmovdqu32 ZMMWORD PTR [rbx+0x140],zmm5
  2b0908:	vmovdqu32 ZMMWORD PTR [rbx+0x180],zmm6
  2b090f:	vmovdqu32 ZMMWORD PTR [rbx+0x1c0],zmm7
  2b0916:	vmovdqa32 zmm0,ZMMWORD PTR [rsp]
  2b091d:	vmovdqa32 zmm1,ZMMWORD PTR [rsp+0x40]
  2b0925:	vmovdqa32 zmm2,zmm0
  2b092b:	vpaddd zmm2{k1},zmm0,DWORD BCST [rip+0xffffffffffd8cb0f]        # 3d444 <ADD16>
  2b0935:	vpcmpltud k2,zmm2,zmm0
  2b093c:	vpaddd zmm1{k2},zmm1,DWORD BCST [rip+0xffffffffffd8cafa]        # 3d440 <ADD1>
  2b0946:	vmovdqa32 ZMMWORD PTR [rsp],zmm2
  2b094d:	vmovdqa32 ZMMWORD PTR [rsp+0x40],zmm1
  2b0955:	add    rdi,0x80
  2b095c:	add    rbx,0x200
  2b0963:	mov    QWORD PTR [rbp+0x50],rbx
  2b0967:	sub    rsi,0x10
  2b096b:	cmp    rsi,0x10
  2b096f:	jae    2af03f <_blake3_hash_many_avx512+0xbf>
  2b0975:	test   rsi,rsi
  2b0978:	jne    2b09c0 <_blake3_hash_many_avx512+0x1a40>
  2b097a:	vzeroupper
  2b097d:	mov    rsp,rbp
  2b0980:	pop    rbp
  2b0981:	pop    rbx
  2b0982:	pop    r12
  2b0984:	pop    r13
  2b0986:	pop    r14
  2b0988:	pop    r15
  2b098a:	ret
  2b098b:	nop    WORD PTR [rax+rax*1+0x0]
  2b0994:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b099f:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b09aa:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b09b5:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b09c0:	test   esi,0x8
  2b09c6:	je     2b1f5d <_blake3_hash_many_avx512+0x2fdd>
  2b09cc:	vpbroadcastd ymm0,DWORD PTR [rcx]
  2b09d1:	vpbroadcastd ymm1,DWORD PTR [rcx+0x4]
  2b09d7:	vpbroadcastd ymm2,DWORD PTR [rcx+0x8]
  2b09dd:	vpbroadcastd ymm3,DWORD PTR [rcx+0xc]
  2b09e3:	vpbroadcastd ymm4,DWORD PTR [rcx+0x10]
  2b09e9:	vpbroadcastd ymm5,DWORD PTR [rcx+0x14]
  2b09ef:	vpbroadcastd ymm6,DWORD PTR [rcx+0x18]
  2b09f5:	vpbroadcastd ymm7,DWORD PTR [rcx+0x1c]
  2b09fb:	mov    r8,QWORD PTR [rdi]
  2b09fe:	mov    r9,QWORD PTR [rdi+0x8]
  2b0a02:	mov    r10,QWORD PTR [rdi+0x10]
  2b0a06:	mov    r11,QWORD PTR [rdi+0x18]
  2b0a0a:	mov    r12,QWORD PTR [rdi+0x20]
  2b0a0e:	mov    r13,QWORD PTR [rdi+0x28]
  2b0a12:	mov    r14,QWORD PTR [rdi+0x30]
  2b0a16:	mov    r15,QWORD PTR [rdi+0x38]
  2b0a1a:	movzx  eax,BYTE PTR [rbp+0x38]
  2b0a1e:	movzx  ebx,BYTE PTR [rbp+0x40]
  2b0a22:	or     eax,ebx
  2b0a24:	xor    edx,edx
  2b0a26:	movzx  ebx,BYTE PTR [rbp+0x48]
  2b0a2a:	or     ebx,eax
  2b0a2c:	add    rdx,0x40
  2b0a30:	cmp    rdx,QWORD PTR [rsp+0x80]
  2b0a38:	cmove  eax,ebx
  2b0a3b:	mov    DWORD PTR [rsp+0x88],eax
  2b0a42:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2b0a49:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x40],0x1
  2b0a51:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x40]
  2b0a58:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x40],0x1
  2b0a60:	vunpcklpd ymm12,ymm8,ymm9
  2b0a65:	vunpckhpd ymm13,ymm8,ymm9
  2b0a6a:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x40]
  2b0a71:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x40],0x1
  2b0a79:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x40]
  2b0a80:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x40],0x1
  2b0a88:	vunpcklpd ymm14,ymm10,ymm11
  2b0a8d:	vunpckhpd ymm15,ymm10,ymm11
  2b0a92:	vshufps ymm16,ymm12,ymm14,0x88
  2b0a99:	vshufps ymm17,ymm12,ymm14,0xdd
  2b0aa0:	vshufps ymm18,ymm13,ymm15,0x88
  2b0aa7:	vshufps ymm19,ymm13,ymm15,0xdd
  2b0aae:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x30]
  2b0ab5:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x30],0x1
  2b0abd:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x30]
  2b0ac4:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x30],0x1
  2b0acc:	vunpcklpd ymm12,ymm8,ymm9
  2b0ad1:	vunpckhpd ymm13,ymm8,ymm9
  2b0ad6:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x30]
  2b0add:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x30],0x1
  2b0ae5:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x30]
  2b0aec:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x30],0x1
  2b0af4:	vunpcklpd ymm14,ymm10,ymm11
  2b0af9:	vunpckhpd ymm15,ymm10,ymm11
  2b0afe:	vshufps ymm20,ymm12,ymm14,0x88
  2b0b05:	vshufps ymm21,ymm12,ymm14,0xdd
  2b0b0c:	vshufps ymm22,ymm13,ymm15,0x88
  2b0b13:	vshufps ymm23,ymm13,ymm15,0xdd
  2b0b1a:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2b0b21:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x20],0x1
  2b0b29:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x20]
  2b0b30:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x20],0x1
  2b0b38:	vunpcklpd ymm12,ymm8,ymm9
  2b0b3d:	vunpckhpd ymm13,ymm8,ymm9
  2b0b42:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x20]
  2b0b49:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x20],0x1
  2b0b51:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x20]
  2b0b58:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x20],0x1
  2b0b60:	vunpcklpd ymm14,ymm10,ymm11
  2b0b65:	vunpckhpd ymm15,ymm10,ymm11
  2b0b6a:	vshufps ymm24,ymm12,ymm14,0x88
  2b0b71:	vshufps ymm25,ymm12,ymm14,0xdd
  2b0b78:	vshufps ymm26,ymm13,ymm15,0x88
  2b0b7f:	vshufps ymm27,ymm13,ymm15,0xdd
  2b0b86:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x10]
  2b0b8d:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r12+rdx*1-0x10],0x1
  2b0b95:	vmovups xmm9,XMMWORD PTR [r9+rdx*1-0x10]
  2b0b9c:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r13+rdx*1-0x10],0x1
  2b0ba4:	vunpcklpd ymm12,ymm8,ymm9
  2b0ba9:	vunpckhpd ymm13,ymm8,ymm9
  2b0bae:	vmovups xmm10,XMMWORD PTR [r10+rdx*1-0x10]
  2b0bb5:	vinsertf128 ymm10,ymm10,XMMWORD PTR [r14+rdx*1-0x10],0x1
  2b0bbd:	vmovups xmm11,XMMWORD PTR [r11+rdx*1-0x10]
  2b0bc4:	vinsertf128 ymm11,ymm11,XMMWORD PTR [r15+rdx*1-0x10],0x1
  2b0bcc:	vunpcklpd ymm14,ymm10,ymm11
  2b0bd1:	vunpckhpd ymm15,ymm10,ymm11
  2b0bd6:	vshufps ymm28,ymm12,ymm14,0x88
  2b0bdd:	vshufps ymm29,ymm12,ymm14,0xdd
  2b0be4:	vshufps ymm30,ymm13,ymm15,0x88
  2b0beb:	vshufps ymm31,ymm13,ymm15,0xdd
  2b0bf2:	vpbroadcastd ymm8,DWORD PTR [rip+0xffffffffffd8c885]        # 3d480 <BLAKE3_IV>
  2b0bfb:	vpbroadcastd ymm9,DWORD PTR [rip+0xffffffffffd8c880]        # 3d484 <BLAKE3_IV_1>
  2b0c04:	vpbroadcastd ymm10,DWORD PTR [rip+0xffffffffffd8c87b]        # 3d488 <BLAKE3_IV_2>
  2b0c0d:	vpbroadcastd ymm11,DWORD PTR [rip+0xffffffffffd8c876]        # 3d48c <BLAKE3_IV_3>
  2b0c16:	vmovdqa ymm12,YMMWORD PTR [rsp]
  2b0c1b:	vmovdqa ymm13,YMMWORD PTR [rsp+0x40]
  2b0c21:	vpbroadcastd ymm14,DWORD PTR [rip+0xffffffffffd8c81e]        # 3d448 <BLAKE3_BLOCK_LEN>
  2b0c2a:	vpbroadcastd ymm15,DWORD PTR [rsp+0x88]
  2b0c34:	vpaddd ymm0,ymm0,ymm16
  2b0c3a:	vpaddd ymm1,ymm1,ymm18
  2b0c40:	vpaddd ymm2,ymm2,ymm20
  2b0c46:	vpaddd ymm3,ymm3,ymm22
  2b0c4c:	vpaddd ymm0,ymm0,ymm4
  2b0c50:	vpaddd ymm1,ymm1,ymm5
  2b0c54:	vpaddd ymm2,ymm2,ymm6
  2b0c58:	vpaddd ymm3,ymm3,ymm7
  2b0c5c:	vpxord ymm12,ymm12,ymm0
  2b0c62:	vpxord ymm13,ymm13,ymm1
  2b0c68:	vpxord ymm14,ymm14,ymm2
  2b0c6e:	vpxord ymm15,ymm15,ymm3
  2b0c74:	vprord ymm12,ymm12,0x10
  2b0c7b:	vprord ymm13,ymm13,0x10
  2b0c82:	vprord ymm14,ymm14,0x10
  2b0c89:	vprord ymm15,ymm15,0x10
  2b0c90:	vpaddd ymm8,ymm8,ymm12
  2b0c95:	vpaddd ymm9,ymm9,ymm13
  2b0c9a:	vpaddd ymm10,ymm10,ymm14
  2b0c9f:	vpaddd ymm11,ymm11,ymm15
  2b0ca4:	vpxord ymm4,ymm4,ymm8
  2b0caa:	vpxord ymm5,ymm5,ymm9
  2b0cb0:	vpxord ymm6,ymm6,ymm10
  2b0cb6:	vpxord ymm7,ymm7,ymm11
  2b0cbc:	vprord ymm4,ymm4,0xc
  2b0cc3:	vprord ymm5,ymm5,0xc
  2b0cca:	vprord ymm6,ymm6,0xc
  2b0cd1:	vprord ymm7,ymm7,0xc
  2b0cd8:	vpaddd ymm0,ymm0,ymm17
  2b0cde:	vpaddd ymm1,ymm1,ymm19
  2b0ce4:	vpaddd ymm2,ymm2,ymm21
  2b0cea:	vpaddd ymm3,ymm3,ymm23
  2b0cf0:	vpaddd ymm0,ymm0,ymm4
  2b0cf4:	vpaddd ymm1,ymm1,ymm5
  2b0cf8:	vpaddd ymm2,ymm2,ymm6
  2b0cfc:	vpaddd ymm3,ymm3,ymm7
  2b0d00:	vpxord ymm12,ymm12,ymm0
  2b0d06:	vpxord ymm13,ymm13,ymm1
  2b0d0c:	vpxord ymm14,ymm14,ymm2
  2b0d12:	vpxord ymm15,ymm15,ymm3
  2b0d18:	vprord ymm12,ymm12,0x8
  2b0d1f:	vprord ymm13,ymm13,0x8
  2b0d26:	vprord ymm14,ymm14,0x8
  2b0d2d:	vprord ymm15,ymm15,0x8
  2b0d34:	vpaddd ymm8,ymm8,ymm12
  2b0d39:	vpaddd ymm9,ymm9,ymm13
  2b0d3e:	vpaddd ymm10,ymm10,ymm14
  2b0d43:	vpaddd ymm11,ymm11,ymm15
  2b0d48:	vpxord ymm4,ymm4,ymm8
  2b0d4e:	vpxord ymm5,ymm5,ymm9
  2b0d54:	vpxord ymm6,ymm6,ymm10
  2b0d5a:	vpxord ymm7,ymm7,ymm11
  2b0d60:	vprord ymm4,ymm4,0x7
  2b0d67:	vprord ymm5,ymm5,0x7
  2b0d6e:	vprord ymm6,ymm6,0x7
  2b0d75:	vprord ymm7,ymm7,0x7
  2b0d7c:	vpaddd ymm0,ymm0,ymm24
  2b0d82:	vpaddd ymm1,ymm1,ymm26
  2b0d88:	vpaddd ymm2,ymm2,ymm28
  2b0d8e:	vpaddd ymm3,ymm3,ymm30
  2b0d94:	vpaddd ymm0,ymm0,ymm5
  2b0d98:	vpaddd ymm1,ymm1,ymm6
  2b0d9c:	vpaddd ymm2,ymm2,ymm7
  2b0da0:	vpaddd ymm3,ymm3,ymm4
  2b0da4:	vpxord ymm15,ymm15,ymm0
  2b0daa:	vpxord ymm12,ymm12,ymm1
  2b0db0:	vpxord ymm13,ymm13,ymm2
  2b0db6:	vpxord ymm14,ymm14,ymm3
  2b0dbc:	vprord ymm15,ymm15,0x10
  2b0dc3:	vprord ymm12,ymm12,0x10
  2b0dca:	vprord ymm13,ymm13,0x10
  2b0dd1:	vprord ymm14,ymm14,0x10
  2b0dd8:	vpaddd ymm10,ymm10,ymm15
  2b0ddd:	vpaddd ymm11,ymm11,ymm12
  2b0de2:	vpaddd ymm8,ymm8,ymm13
  2b0de7:	vpaddd ymm9,ymm9,ymm14
  2b0dec:	vpxord ymm5,ymm5,ymm10
  2b0df2:	vpxord ymm6,ymm6,ymm11
  2b0df8:	vpxord ymm7,ymm7,ymm8
  2b0dfe:	vpxord ymm4,ymm4,ymm9
  2b0e04:	vprord ymm5,ymm5,0xc
  2b0e0b:	vprord ymm6,ymm6,0xc
  2b0e12:	vprord ymm7,ymm7,0xc
  2b0e19:	vprord ymm4,ymm4,0xc
  2b0e20:	vpaddd ymm0,ymm0,ymm25
  2b0e26:	vpaddd ymm1,ymm1,ymm27
  2b0e2c:	vpaddd ymm2,ymm2,ymm29
  2b0e32:	vpaddd ymm3,ymm3,ymm31
  2b0e38:	vpaddd ymm0,ymm0,ymm5
  2b0e3c:	vpaddd ymm1,ymm1,ymm6
  2b0e40:	vpaddd ymm2,ymm2,ymm7
  2b0e44:	vpaddd ymm3,ymm3,ymm4
  2b0e48:	vpxord ymm15,ymm15,ymm0
  2b0e4e:	vpxord ymm12,ymm12,ymm1
  2b0e54:	vpxord ymm13,ymm13,ymm2
  2b0e5a:	vpxord ymm14,ymm14,ymm3
  2b0e60:	vprord ymm15,ymm15,0x8
  2b0e67:	vprord ymm12,ymm12,0x8
  2b0e6e:	vprord ymm13,ymm13,0x8
  2b0e75:	vprord ymm14,ymm14,0x8
  2b0e7c:	vpaddd ymm10,ymm10,ymm15
  2b0e81:	vpaddd ymm11,ymm11,ymm12
  2b0e86:	vpaddd ymm8,ymm8,ymm13
  2b0e8b:	vpaddd ymm9,ymm9,ymm14
  2b0e90:	vpxord ymm5,ymm5,ymm10
  2b0e96:	vpxord ymm6,ymm6,ymm11
  2b0e9c:	vpxord ymm7,ymm7,ymm8
  2b0ea2:	vpxord ymm4,ymm4,ymm9
  2b0ea8:	vprord ymm5,ymm5,0x7
  2b0eaf:	vprord ymm6,ymm6,0x7
  2b0eb6:	vprord ymm7,ymm7,0x7
  2b0ebd:	vprord ymm4,ymm4,0x7
  2b0ec4:	vpaddd ymm0,ymm0,ymm18
  2b0eca:	vpaddd ymm1,ymm1,ymm19
  2b0ed0:	vpaddd ymm2,ymm2,ymm23
  2b0ed6:	vpaddd ymm3,ymm3,ymm20
  2b0edc:	vpaddd ymm0,ymm0,ymm4
  2b0ee0:	vpaddd ymm1,ymm1,ymm5
  2b0ee4:	vpaddd ymm2,ymm2,ymm6
  2b0ee8:	vpaddd ymm3,ymm3,ymm7
  2b0eec:	vpxord ymm12,ymm12,ymm0
  2b0ef2:	vpxord ymm13,ymm13,ymm1
  2b0ef8:	vpxord ymm14,ymm14,ymm2
  2b0efe:	vpxord ymm15,ymm15,ymm3
  2b0f04:	vprord ymm12,ymm12,0x10
  2b0f0b:	vprord ymm13,ymm13,0x10
  2b0f12:	vprord ymm14,ymm14,0x10
  2b0f19:	vprord ymm15,ymm15,0x10
  2b0f20:	vpaddd ymm8,ymm8,ymm12
  2b0f25:	vpaddd ymm9,ymm9,ymm13
  2b0f2a:	vpaddd ymm10,ymm10,ymm14
  2b0f2f:	vpaddd ymm11,ymm11,ymm15
  2b0f34:	vpxord ymm4,ymm4,ymm8
  2b0f3a:	vpxord ymm5,ymm5,ymm9
  2b0f40:	vpxord ymm6,ymm6,ymm10
  2b0f46:	vpxord ymm7,ymm7,ymm11
  2b0f4c:	vprord ymm4,ymm4,0xc
  2b0f53:	vprord ymm5,ymm5,0xc
  2b0f5a:	vprord ymm6,ymm6,0xc
  2b0f61:	vprord ymm7,ymm7,0xc
  2b0f68:	vpaddd ymm0,ymm0,ymm22
  2b0f6e:	vpaddd ymm1,ymm1,ymm26
  2b0f74:	vpaddd ymm2,ymm2,ymm16
  2b0f7a:	vpaddd ymm3,ymm3,ymm29
  2b0f80:	vpaddd ymm0,ymm0,ymm4
  2b0f84:	vpaddd ymm1,ymm1,ymm5
  2b0f88:	vpaddd ymm2,ymm2,ymm6
  2b0f8c:	vpaddd ymm3,ymm3,ymm7
  2b0f90:	vpxord ymm12,ymm12,ymm0
  2b0f96:	vpxord ymm13,ymm13,ymm1
  2b0f9c:	vpxord ymm14,ymm14,ymm2
  2b0fa2:	vpxord ymm15,ymm15,ymm3
  2b0fa8:	vprord ymm12,ymm12,0x8
  2b0faf:	vprord ymm13,ymm13,0x8
  2b0fb6:	vprord ymm14,ymm14,0x8
  2b0fbd:	vprord ymm15,ymm15,0x8
  2b0fc4:	vpaddd ymm8,ymm8,ymm12
  2b0fc9:	vpaddd ymm9,ymm9,ymm13
  2b0fce:	vpaddd ymm10,ymm10,ymm14
  2b0fd3:	vpaddd ymm11,ymm11,ymm15
  2b0fd8:	vpxord ymm4,ymm4,ymm8
  2b0fde:	vpxord ymm5,ymm5,ymm9
  2b0fe4:	vpxord ymm6,ymm6,ymm10
  2b0fea:	vpxord ymm7,ymm7,ymm11
  2b0ff0:	vprord ymm4,ymm4,0x7
  2b0ff7:	vprord ymm5,ymm5,0x7
  2b0ffe:	vprord ymm6,ymm6,0x7
  2b1005:	vprord ymm7,ymm7,0x7
  2b100c:	vpaddd ymm0,ymm0,ymm17
  2b1012:	vpaddd ymm1,ymm1,ymm28
  2b1018:	vpaddd ymm2,ymm2,ymm25
  2b101e:	vpaddd ymm3,ymm3,ymm31
  2b1024:	vpaddd ymm0,ymm0,ymm5
  2b1028:	vpaddd ymm1,ymm1,ymm6
  2b102c:	vpaddd ymm2,ymm2,ymm7
  2b1030:	vpaddd ymm3,ymm3,ymm4
  2b1034:	vpxord ymm15,ymm15,ymm0
  2b103a:	vpxord ymm12,ymm12,ymm1
  2b1040:	vpxord ymm13,ymm13,ymm2
  2b1046:	vpxord ymm14,ymm14,ymm3
  2b104c:	vprord ymm15,ymm15,0x10
  2b1053:	vprord ymm12,ymm12,0x10
  2b105a:	vprord ymm13,ymm13,0x10
  2b1061:	vprord ymm14,ymm14,0x10
  2b1068:	vpaddd ymm10,ymm10,ymm15
  2b106d:	vpaddd ymm11,ymm11,ymm12
  2b1072:	vpaddd ymm8,ymm8,ymm13
  2b1077:	vpaddd ymm9,ymm9,ymm14
  2b107c:	vpxord ymm5,ymm5,ymm10
  2b1082:	vpxord ymm6,ymm6,ymm11
  2b1088:	vpxord ymm7,ymm7,ymm8
  2b108e:	vpxord ymm4,ymm4,ymm9
  2b1094:	vprord ymm5,ymm5,0xc
  2b109b:	vprord ymm6,ymm6,0xc
  2b10a2:	vprord ymm7,ymm7,0xc
  2b10a9:	vprord ymm4,ymm4,0xc
  2b10b0:	vpaddd ymm0,ymm0,ymm27
  2b10b6:	vpaddd ymm1,ymm1,ymm21
  2b10bc:	vpaddd ymm2,ymm2,ymm30
  2b10c2:	vpaddd ymm3,ymm3,ymm24
  2b10c8:	vpaddd ymm0,ymm0,ymm5
  2b10cc:	vpaddd ymm1,ymm1,ymm6
  2b10d0:	vpaddd ymm2,ymm2,ymm7
  2b10d4:	vpaddd ymm3,ymm3,ymm4
  2b10d8:	vpxord ymm15,ymm15,ymm0
  2b10de:	vpxord ymm12,ymm12,ymm1
  2b10e4:	vpxord ymm13,ymm13,ymm2
  2b10ea:	vpxord ymm14,ymm14,ymm3
  2b10f0:	vprord ymm15,ymm15,0x8
  2b10f7:	vprord ymm12,ymm12,0x8
  2b10fe:	vprord ymm13,ymm13,0x8
  2b1105:	vprord ymm14,ymm14,0x8
  2b110c:	vpaddd ymm10,ymm10,ymm15
  2b1111:	vpaddd ymm11,ymm11,ymm12
  2b1116:	vpaddd ymm8,ymm8,ymm13
  2b111b:	vpaddd ymm9,ymm9,ymm14
  2b1120:	vpxord ymm5,ymm5,ymm10
  2b1126:	vpxord ymm6,ymm6,ymm11
  2b112c:	vpxord ymm7,ymm7,ymm8
  2b1132:	vpxord ymm4,ymm4,ymm9
  2b1138:	vprord ymm5,ymm5,0x7
  2b113f:	vprord ymm6,ymm6,0x7
  2b1146:	vprord ymm7,ymm7,0x7
  2b114d:	vprord ymm4,ymm4,0x7
  2b1154:	vpaddd ymm0,ymm0,ymm19
  2b115a:	vpaddd ymm1,ymm1,ymm26
  2b1160:	vpaddd ymm2,ymm2,ymm29
  2b1166:	vpaddd ymm3,ymm3,ymm23
  2b116c:	vpaddd ymm0,ymm0,ymm4
  2b1170:	vpaddd ymm1,ymm1,ymm5
  2b1174:	vpaddd ymm2,ymm2,ymm6
  2b1178:	vpaddd ymm3,ymm3,ymm7
  2b117c:	vpxord ymm12,ymm12,ymm0
  2b1182:	vpxord ymm13,ymm13,ymm1
  2b1188:	vpxord ymm14,ymm14,ymm2
  2b118e:	vpxord ymm15,ymm15,ymm3
  2b1194:	vprord ymm12,ymm12,0x10
  2b119b:	vprord ymm13,ymm13,0x10
  2b11a2:	vprord ymm14,ymm14,0x10
  2b11a9:	vprord ymm15,ymm15,0x10
  2b11b0:	vpaddd ymm8,ymm8,ymm12
  2b11b5:	vpaddd ymm9,ymm9,ymm13
  2b11ba:	vpaddd ymm10,ymm10,ymm14
  2b11bf:	vpaddd ymm11,ymm11,ymm15
  2b11c4:	vpxord ymm4,ymm4,ymm8
  2b11ca:	vpxord ymm5,ymm5,ymm9
  2b11d0:	vpxord ymm6,ymm6,ymm10
  2b11d6:	vpxord ymm7,ymm7,ymm11
  2b11dc:	vprord ymm4,ymm4,0xc
  2b11e3:	vprord ymm5,ymm5,0xc
  2b11ea:	vprord ymm6,ymm6,0xc
  2b11f1:	vprord ymm7,ymm7,0xc
  2b11f8:	vpaddd ymm0,ymm0,ymm20
  2b11fe:	vpaddd ymm1,ymm1,ymm28
  2b1204:	vpaddd ymm2,ymm2,ymm18
  2b120a:	vpaddd ymm3,ymm3,ymm30
  2b1210:	vpaddd ymm0,ymm0,ymm4
  2b1214:	vpaddd ymm1,ymm1,ymm5
  2b1218:	vpaddd ymm2,ymm2,ymm6
  2b121c:	vpaddd ymm3,ymm3,ymm7
  2b1220:	vpxord ymm12,ymm12,ymm0
  2b1226:	vpxord ymm13,ymm13,ymm1
  2b122c:	vpxord ymm14,ymm14,ymm2
  2b1232:	vpxord ymm15,ymm15,ymm3
  2b1238:	vprord ymm12,ymm12,0x8
  2b123f:	vprord ymm13,ymm13,0x8
  2b1246:	vprord ymm14,ymm14,0x8
  2b124d:	vprord ymm15,ymm15,0x8
  2b1254:	vpaddd ymm8,ymm8,ymm12
  2b1259:	vpaddd ymm9,ymm9,ymm13
  2b125e:	vpaddd ymm10,ymm10,ymm14
  2b1263:	vpaddd ymm11,ymm11,ymm15
  2b1268:	vpxord ymm4,ymm4,ymm8
  2b126e:	vpxord ymm5,ymm5,ymm9
  2b1274:	vpxord ymm6,ymm6,ymm10
  2b127a:	vpxord ymm7,ymm7,ymm11
  2b1280:	vprord ymm4,ymm4,0x7
  2b1287:	vprord ymm5,ymm5,0x7
  2b128e:	vprord ymm6,ymm6,0x7
  2b1295:	vprord ymm7,ymm7,0x7
  2b129c:	vpaddd ymm0,ymm0,ymm22
  2b12a2:	vpaddd ymm1,ymm1,ymm25
  2b12a8:	vpaddd ymm2,ymm2,ymm27
  2b12ae:	vpaddd ymm3,ymm3,ymm24
  2b12b4:	vpaddd ymm0,ymm0,ymm5
  2b12b8:	vpaddd ymm1,ymm1,ymm6
  2b12bc:	vpaddd ymm2,ymm2,ymm7
  2b12c0:	vpaddd ymm3,ymm3,ymm4
  2b12c4:	vpxord ymm15,ymm15,ymm0
  2b12ca:	vpxord ymm12,ymm12,ymm1
  2b12d0:	vpxord ymm13,ymm13,ymm2
  2b12d6:	vpxord ymm14,ymm14,ymm3
  2b12dc:	vprord ymm15,ymm15,0x10
  2b12e3:	vprord ymm12,ymm12,0x10
  2b12ea:	vprord ymm13,ymm13,0x10
  2b12f1:	vprord ymm14,ymm14,0x10
  2b12f8:	vpaddd ymm10,ymm10,ymm15
  2b12fd:	vpaddd ymm11,ymm11,ymm12
  2b1302:	vpaddd ymm8,ymm8,ymm13
  2b1307:	vpaddd ymm9,ymm9,ymm14
  2b130c:	vpxord ymm5,ymm5,ymm10
  2b1312:	vpxord ymm6,ymm6,ymm11
  2b1318:	vpxord ymm7,ymm7,ymm8
  2b131e:	vpxord ymm4,ymm4,ymm9
  2b1324:	vprord ymm5,ymm5,0xc
  2b132b:	vprord ymm6,ymm6,0xc
  2b1332:	vprord ymm7,ymm7,0xc
  2b1339:	vprord ymm4,ymm4,0xc
  2b1340:	vpaddd ymm0,ymm0,ymm21
  2b1346:	vpaddd ymm1,ymm1,ymm16
  2b134c:	vpaddd ymm2,ymm2,ymm31
  2b1352:	vpaddd ymm3,ymm3,ymm17
  2b1358:	vpaddd ymm0,ymm0,ymm5
  2b135c:	vpaddd ymm1,ymm1,ymm6
  2b1360:	vpaddd ymm2,ymm2,ymm7
  2b1364:	vpaddd ymm3,ymm3,ymm4
  2b1368:	vpxord ymm15,ymm15,ymm0
  2b136e:	vpxord ymm12,ymm12,ymm1
  2b1374:	vpxord ymm13,ymm13,ymm2
  2b137a:	vpxord ymm14,ymm14,ymm3
  2b1380:	vprord ymm15,ymm15,0x8
  2b1387:	vprord ymm12,ymm12,0x8
  2b138e:	vprord ymm13,ymm13,0x8
  2b1395:	vprord ymm14,ymm14,0x8
  2b139c:	vpaddd ymm10,ymm10,ymm15
  2b13a1:	vpaddd ymm11,ymm11,ymm12
  2b13a6:	vpaddd ymm8,ymm8,ymm13
  2b13ab:	vpaddd ymm9,ymm9,ymm14
  2b13b0:	vpxord ymm5,ymm5,ymm10
  2b13b6:	vpxord ymm6,ymm6,ymm11
  2b13bc:	vpxord ymm7,ymm7,ymm8
  2b13c2:	vpxord ymm4,ymm4,ymm9
  2b13c8:	vprord ymm5,ymm5,0x7
  2b13cf:	vprord ymm6,ymm6,0x7
  2b13d6:	vprord ymm7,ymm7,0x7
  2b13dd:	vprord ymm4,ymm4,0x7
  2b13e4:	vpaddd ymm0,ymm0,ymm26
  2b13ea:	vpaddd ymm1,ymm1,ymm28
  2b13f0:	vpaddd ymm2,ymm2,ymm30
  2b13f6:	vpaddd ymm3,ymm3,ymm29
  2b13fc:	vpaddd ymm0,ymm0,ymm4
  2b1400:	vpaddd ymm1,ymm1,ymm5
  2b1404:	vpaddd ymm2,ymm2,ymm6
  2b1408:	vpaddd ymm3,ymm3,ymm7
  2b140c:	vpxord ymm12,ymm12,ymm0
  2b1412:	vpxord ymm13,ymm13,ymm1
  2b1418:	vpxord ymm14,ymm14,ymm2
  2b141e:	vpxord ymm15,ymm15,ymm3
  2b1424:	vprord ymm12,ymm12,0x10
  2b142b:	vprord ymm13,ymm13,0x10
  2b1432:	vprord ymm14,ymm14,0x10
  2b1439:	vprord ymm15,ymm15,0x10
  2b1440:	vpaddd ymm8,ymm8,ymm12
  2b1445:	vpaddd ymm9,ymm9,ymm13
  2b144a:	vpaddd ymm10,ymm10,ymm14
  2b144f:	vpaddd ymm11,ymm11,ymm15
  2b1454:	vpxord ymm4,ymm4,ymm8
  2b145a:	vpxord ymm5,ymm5,ymm9
  2b1460:	vpxord ymm6,ymm6,ymm10
  2b1466:	vpxord ymm7,ymm7,ymm11
  2b146c:	vprord ymm4,ymm4,0xc
  2b1473:	vprord ymm5,ymm5,0xc
  2b147a:	vprord ymm6,ymm6,0xc
  2b1481:	vprord ymm7,ymm7,0xc
  2b1488:	vpaddd ymm0,ymm0,ymm23
  2b148e:	vpaddd ymm1,ymm1,ymm25
  2b1494:	vpaddd ymm2,ymm2,ymm19
  2b149a:	vpaddd ymm3,ymm3,ymm31
  2b14a0:	vpaddd ymm0,ymm0,ymm4
  2b14a4:	vpaddd ymm1,ymm1,ymm5
  2b14a8:	vpaddd ymm2,ymm2,ymm6
  2b14ac:	vpaddd ymm3,ymm3,ymm7
  2b14b0:	vpxord ymm12,ymm12,ymm0
  2b14b6:	vpxord ymm13,ymm13,ymm1
  2b14bc:	vpxord ymm14,ymm14,ymm2
  2b14c2:	vpxord ymm15,ymm15,ymm3
  2b14c8:	vprord ymm12,ymm12,0x8
  2b14cf:	vprord ymm13,ymm13,0x8
  2b14d6:	vprord ymm14,ymm14,0x8
  2b14dd:	vprord ymm15,ymm15,0x8
  2b14e4:	vpaddd ymm8,ymm8,ymm12
  2b14e9:	vpaddd ymm9,ymm9,ymm13
  2b14ee:	vpaddd ymm10,ymm10,ymm14
  2b14f3:	vpaddd ymm11,ymm11,ymm15
  2b14f8:	vpxord ymm4,ymm4,ymm8
  2b14fe:	vpxord ymm5,ymm5,ymm9
  2b1504:	vpxord ymm6,ymm6,ymm10
  2b150a:	vpxord ymm7,ymm7,ymm11
  2b1510:	vprord ymm4,ymm4,0x7
  2b1517:	vprord ymm5,ymm5,0x7
  2b151e:	vprord ymm6,ymm6,0x7
  2b1525:	vprord ymm7,ymm7,0x7
  2b152c:	vpaddd ymm0,ymm0,ymm20
  2b1532:	vpaddd ymm1,ymm1,ymm27
  2b1538:	vpaddd ymm2,ymm2,ymm21
  2b153e:	vpaddd ymm3,ymm3,ymm17
  2b1544:	vpaddd ymm0,ymm0,ymm5
  2b1548:	vpaddd ymm1,ymm1,ymm6
  2b154c:	vpaddd ymm2,ymm2,ymm7
  2b1550:	vpaddd ymm3,ymm3,ymm4
  2b1554:	vpxord ymm15,ymm15,ymm0
  2b155a:	vpxord ymm12,ymm12,ymm1
  2b1560:	vpxord ymm13,ymm13,ymm2
  2b1566:	vpxord ymm14,ymm14,ymm3
  2b156c:	vprord ymm15,ymm15,0x10
  2b1573:	vprord ymm12,ymm12,0x10
  2b157a:	vprord ymm13,ymm13,0x10
  2b1581:	vprord ymm14,ymm14,0x10
  2b1588:	vpaddd ymm10,ymm10,ymm15
  2b158d:	vpaddd ymm11,ymm11,ymm12
  2b1592:	vpaddd ymm8,ymm8,ymm13
  2b1597:	vpaddd ymm9,ymm9,ymm14
  2b159c:	vpxord ymm5,ymm5,ymm10
  2b15a2:	vpxord ymm6,ymm6,ymm11
  2b15a8:	vpxord ymm7,ymm7,ymm8
  2b15ae:	vpxord ymm4,ymm4,ymm9
  2b15b4:	vprord ymm5,ymm5,0xc
  2b15bb:	vprord ymm6,ymm6,0xc
  2b15c2:	vprord ymm7,ymm7,0xc
  2b15c9:	vprord ymm4,ymm4,0xc
  2b15d0:	vpaddd ymm0,ymm0,ymm16
  2b15d6:	vpaddd ymm1,ymm1,ymm18
  2b15dc:	vpaddd ymm2,ymm2,ymm24
  2b15e2:	vpaddd ymm3,ymm3,ymm22
  2b15e8:	vpaddd ymm0,ymm0,ymm5
  2b15ec:	vpaddd ymm1,ymm1,ymm6
  2b15f0:	vpaddd ymm2,ymm2,ymm7
  2b15f4:	vpaddd ymm3,ymm3,ymm4
  2b15f8:	vpxord ymm15,ymm15,ymm0
  2b15fe:	vpxord ymm12,ymm12,ymm1
  2b1604:	vpxord ymm13,ymm13,ymm2
  2b160a:	vpxord ymm14,ymm14,ymm3
  2b1610:	vprord ymm15,ymm15,0x8
  2b1617:	vprord ymm12,ymm12,0x8
  2b161e:	vprord ymm13,ymm13,0x8
  2b1625:	vprord ymm14,ymm14,0x8
  2b162c:	vpaddd ymm10,ymm10,ymm15
  2b1631:	vpaddd ymm11,ymm11,ymm12
  2b1636:	vpaddd ymm8,ymm8,ymm13
  2b163b:	vpaddd ymm9,ymm9,ymm14
  2b1640:	vpxord ymm5,ymm5,ymm10
  2b1646:	vpxord ymm6,ymm6,ymm11
  2b164c:	vpxord ymm7,ymm7,ymm8
  2b1652:	vpxord ymm4,ymm4,ymm9
  2b1658:	vprord ymm5,ymm5,0x7
  2b165f:	vprord ymm6,ymm6,0x7
  2b1666:	vprord ymm7,ymm7,0x7
  2b166d:	vprord ymm4,ymm4,0x7
  2b1674:	vpaddd ymm0,ymm0,ymm28
  2b167a:	vpaddd ymm1,ymm1,ymm25
  2b1680:	vpaddd ymm2,ymm2,ymm31
  2b1686:	vpaddd ymm3,ymm3,ymm30
  2b168c:	vpaddd ymm0,ymm0,ymm4
  2b1690:	vpaddd ymm1,ymm1,ymm5
  2b1694:	vpaddd ymm2,ymm2,ymm6
  2b1698:	vpaddd ymm3,ymm3,ymm7
  2b169c:	vpxord ymm12,ymm12,ymm0
  2b16a2:	vpxord ymm13,ymm13,ymm1
  2b16a8:	vpxord ymm14,ymm14,ymm2
  2b16ae:	vpxord ymm15,ymm15,ymm3
  2b16b4:	vprord ymm12,ymm12,0x10
  2b16bb:	vprord ymm13,ymm13,0x10
  2b16c2:	vprord ymm14,ymm14,0x10
  2b16c9:	vprord ymm15,ymm15,0x10
  2b16d0:	vpaddd ymm8,ymm8,ymm12
  2b16d5:	vpaddd ymm9,ymm9,ymm13
  2b16da:	vpaddd ymm10,ymm10,ymm14
  2b16df:	vpaddd ymm11,ymm11,ymm15
  2b16e4:	vpxord ymm4,ymm4,ymm8
  2b16ea:	vpxord ymm5,ymm5,ymm9
  2b16f0:	vpxord ymm6,ymm6,ymm10
  2b16f6:	vpxord ymm7,ymm7,ymm11
  2b16fc:	vprord ymm4,ymm4,0xc
  2b1703:	vprord ymm5,ymm5,0xc
  2b170a:	vprord ymm6,ymm6,0xc
  2b1711:	vprord ymm7,ymm7,0xc
  2b1718:	vpaddd ymm0,ymm0,ymm29
  2b171e:	vpaddd ymm1,ymm1,ymm27
  2b1724:	vpaddd ymm2,ymm2,ymm26
  2b172a:	vpaddd ymm3,ymm3,ymm24
  2b1730:	vpaddd ymm0,ymm0,ymm4
  2b1734:	vpaddd ymm1,ymm1,ymm5
  2b1738:	vpaddd ymm2,ymm2,ymm6
  2b173c:	vpaddd ymm3,ymm3,ymm7
  2b1740:	vpxord ymm12,ymm12,ymm0
  2b1746:	vpxord ymm13,ymm13,ymm1
  2b174c:	vpxord ymm14,ymm14,ymm2
  2b1752:	vpxord ymm15,ymm15,ymm3
  2b1758:	vprord ymm12,ymm12,0x8
  2b175f:	vprord ymm13,ymm13,0x8
  2b1766:	vprord ymm14,ymm14,0x8
  2b176d:	vprord ymm15,ymm15,0x8
  2b1774:	vpaddd ymm8,ymm8,ymm12
  2b1779:	vpaddd ymm9,ymm9,ymm13
  2b177e:	vpaddd ymm10,ymm10,ymm14
  2b1783:	vpaddd ymm11,ymm11,ymm15
  2b1788:	vpxord ymm4,ymm4,ymm8
  2b178e:	vpxord ymm5,ymm5,ymm9
  2b1794:	vpxord ymm6,ymm6,ymm10
  2b179a:	vpxord ymm7,ymm7,ymm11
  2b17a0:	vprord ymm4,ymm4,0x7
  2b17a7:	vprord ymm5,ymm5,0x7
  2b17ae:	vprord ymm6,ymm6,0x7
  2b17b5:	vprord ymm7,ymm7,0x7
  2b17bc:	vpaddd ymm0,ymm0,ymm23
  2b17c2:	vpaddd ymm1,ymm1,ymm21
  2b17c8:	vpaddd ymm2,ymm2,ymm16
  2b17ce:	vpaddd ymm3,ymm3,ymm22
  2b17d4:	vpaddd ymm0,ymm0,ymm5
  2b17d8:	vpaddd ymm1,ymm1,ymm6
  2b17dc:	vpaddd ymm2,ymm2,ymm7
  2b17e0:	vpaddd ymm3,ymm3,ymm4
  2b17e4:	vpxord ymm15,ymm15,ymm0
  2b17ea:	vpxord ymm12,ymm12,ymm1
  2b17f0:	vpxord ymm13,ymm13,ymm2
  2b17f6:	vpxord ymm14,ymm14,ymm3
  2b17fc:	vprord ymm15,ymm15,0x10
  2b1803:	vprord ymm12,ymm12,0x10
  2b180a:	vprord ymm13,ymm13,0x10
  2b1811:	vprord ymm14,ymm14,0x10
  2b1818:	vpaddd ymm10,ymm10,ymm15
  2b181d:	vpaddd ymm11,ymm11,ymm12
  2b1822:	vpaddd ymm8,ymm8,ymm13
  2b1827:	vpaddd ymm9,ymm9,ymm14
  2b182c:	vpxord ymm5,ymm5,ymm10
  2b1832:	vpxord ymm6,ymm6,ymm11
  2b1838:	vpxord ymm7,ymm7,ymm8
  2b183e:	vpxord ymm4,ymm4,ymm9
  2b1844:	vprord ymm5,ymm5,0xc
  2b184b:	vprord ymm6,ymm6,0xc
  2b1852:	vprord ymm7,ymm7,0xc
  2b1859:	vprord ymm4,ymm4,0xc
  2b1860:	vpaddd ymm0,ymm0,ymm18
  2b1866:	vpaddd ymm1,ymm1,ymm19
  2b186c:	vpaddd ymm2,ymm2,ymm17
  2b1872:	vpaddd ymm3,ymm3,ymm20
  2b1878:	vpaddd ymm0,ymm0,ymm5
  2b187c:	vpaddd ymm1,ymm1,ymm6
  2b1880:	vpaddd ymm2,ymm2,ymm7
  2b1884:	vpaddd ymm3,ymm3,ymm4
  2b1888:	vpxord ymm15,ymm15,ymm0
  2b188e:	vpxord ymm12,ymm12,ymm1
  2b1894:	vpxord ymm13,ymm13,ymm2
  2b189a:	vpxord ymm14,ymm14,ymm3
  2b18a0:	vprord ymm15,ymm15,0x8
  2b18a7:	vprord ymm12,ymm12,0x8
  2b18ae:	vprord ymm13,ymm13,0x8
  2b18b5:	vprord ymm14,ymm14,0x8
  2b18bc:	vpaddd ymm10,ymm10,ymm15
  2b18c1:	vpaddd ymm11,ymm11,ymm12
  2b18c6:	vpaddd ymm8,ymm8,ymm13
  2b18cb:	vpaddd ymm9,ymm9,ymm14
  2b18d0:	vpxord ymm5,ymm5,ymm10
  2b18d6:	vpxord ymm6,ymm6,ymm11
  2b18dc:	vpxord ymm7,ymm7,ymm8
  2b18e2:	vpxord ymm4,ymm4,ymm9
  2b18e8:	vprord ymm5,ymm5,0x7
  2b18ef:	vprord ymm6,ymm6,0x7
  2b18f6:	vprord ymm7,ymm7,0x7
  2b18fd:	vprord ymm4,ymm4,0x7
  2b1904:	vpaddd ymm0,ymm0,ymm25
  2b190a:	vpaddd ymm1,ymm1,ymm27
  2b1910:	vpaddd ymm2,ymm2,ymm24
  2b1916:	vpaddd ymm3,ymm3,ymm31
  2b191c:	vpaddd ymm0,ymm0,ymm4
  2b1920:	vpaddd ymm1,ymm1,ymm5
  2b1924:	vpaddd ymm2,ymm2,ymm6
  2b1928:	vpaddd ymm3,ymm3,ymm7
  2b192c:	vpxord ymm12,ymm12,ymm0
  2b1932:	vpxord ymm13,ymm13,ymm1
  2b1938:	vpxord ymm14,ymm14,ymm2
  2b193e:	vpxord ymm15,ymm15,ymm3
  2b1944:	vprord ymm12,ymm12,0x10
  2b194b:	vprord ymm13,ymm13,0x10
  2b1952:	vprord ymm14,ymm14,0x10
  2b1959:	vprord ymm15,ymm15,0x10
  2b1960:	vpaddd ymm8,ymm8,ymm12
  2b1965:	vpaddd ymm9,ymm9,ymm13
  2b196a:	vpaddd ymm10,ymm10,ymm14
  2b196f:	vpaddd ymm11,ymm11,ymm15
  2b1974:	vpxord ymm4,ymm4,ymm8
  2b197a:	vpxord ymm5,ymm5,ymm9
  2b1980:	vpxord ymm6,ymm6,ymm10
  2b1986:	vpxord ymm7,ymm7,ymm11
  2b198c:	vprord ymm4,ymm4,0xc
  2b1993:	vprord ymm5,ymm5,0xc
  2b199a:	vprord ymm6,ymm6,0xc
  2b19a1:	vprord ymm7,ymm7,0xc
  2b19a8:	vpaddd ymm0,ymm0,ymm30
  2b19ae:	vpaddd ymm1,ymm1,ymm21
  2b19b4:	vpaddd ymm2,ymm2,ymm28
  2b19ba:	vpaddd ymm3,ymm3,ymm17
  2b19c0:	vpaddd ymm0,ymm0,ymm4
  2b19c4:	vpaddd ymm1,ymm1,ymm5
  2b19c8:	vpaddd ymm2,ymm2,ymm6
  2b19cc:	vpaddd ymm3,ymm3,ymm7
  2b19d0:	vpxord ymm12,ymm12,ymm0
  2b19d6:	vpxord ymm13,ymm13,ymm1
  2b19dc:	vpxord ymm14,ymm14,ymm2
  2b19e2:	vpxord ymm15,ymm15,ymm3
  2b19e8:	vprord ymm12,ymm12,0x8
  2b19ef:	vprord ymm13,ymm13,0x8
  2b19f6:	vprord ymm14,ymm14,0x8
  2b19fd:	vprord ymm15,ymm15,0x8
  2b1a04:	vpaddd ymm8,ymm8,ymm12
  2b1a09:	vpaddd ymm9,ymm9,ymm13
  2b1a0e:	vpaddd ymm10,ymm10,ymm14
  2b1a13:	vpaddd ymm11,ymm11,ymm15
  2b1a18:	vpxord ymm4,ymm4,ymm8
  2b1a1e:	vpxord ymm5,ymm5,ymm9
  2b1a24:	vpxord ymm6,ymm6,ymm10
  2b1a2a:	vpxord ymm7,ymm7,ymm11
  2b1a30:	vprord ymm4,ymm4,0x7
  2b1a37:	vprord ymm5,ymm5,0x7
  2b1a3e:	vprord ymm6,ymm6,0x7
  2b1a45:	vprord ymm7,ymm7,0x7
  2b1a4c:	vpaddd ymm0,ymm0,ymm29
  2b1a52:	vpaddd ymm1,ymm1,ymm16
  2b1a58:	vpaddd ymm2,ymm2,ymm18
  2b1a5e:	vpaddd ymm3,ymm3,ymm20
  2b1a64:	vpaddd ymm0,ymm0,ymm5
  2b1a68:	vpaddd ymm1,ymm1,ymm6
  2b1a6c:	vpaddd ymm2,ymm2,ymm7
  2b1a70:	vpaddd ymm3,ymm3,ymm4
  2b1a74:	vpxord ymm15,ymm15,ymm0
  2b1a7a:	vpxord ymm12,ymm12,ymm1
  2b1a80:	vpxord ymm13,ymm13,ymm2
  2b1a86:	vpxord ymm14,ymm14,ymm3
  2b1a8c:	vprord ymm15,ymm15,0x10
  2b1a93:	vprord ymm12,ymm12,0x10
  2b1a9a:	vprord ymm13,ymm13,0x10
  2b1aa1:	vprord ymm14,ymm14,0x10
  2b1aa8:	vpaddd ymm10,ymm10,ymm15
  2b1aad:	vpaddd ymm11,ymm11,ymm12
  2b1ab2:	vpaddd ymm8,ymm8,ymm13
  2b1ab7:	vpaddd ymm9,ymm9,ymm14
  2b1abc:	vpxord ymm5,ymm5,ymm10
  2b1ac2:	vpxord ymm6,ymm6,ymm11
  2b1ac8:	vpxord ymm7,ymm7,ymm8
  2b1ace:	vpxord ymm4,ymm4,ymm9
  2b1ad4:	vprord ymm5,ymm5,0xc
  2b1adb:	vprord ymm6,ymm6,0xc
  2b1ae2:	vprord ymm7,ymm7,0xc
  2b1ae9:	vprord ymm4,ymm4,0xc
  2b1af0:	vpaddd ymm0,ymm0,ymm19
  2b1af6:	vpaddd ymm1,ymm1,ymm26
  2b1afc:	vpaddd ymm2,ymm2,ymm22
  2b1b02:	vpaddd ymm3,ymm3,ymm23
  2b1b08:	vpaddd ymm0,ymm0,ymm5
  2b1b0c:	vpaddd ymm1,ymm1,ymm6
  2b1b10:	vpaddd ymm2,ymm2,ymm7
  2b1b14:	vpaddd ymm3,ymm3,ymm4
  2b1b18:	vpxord ymm15,ymm15,ymm0
  2b1b1e:	vpxord ymm12,ymm12,ymm1
  2b1b24:	vpxord ymm13,ymm13,ymm2
  2b1b2a:	vpxord ymm14,ymm14,ymm3
  2b1b30:	vprord ymm15,ymm15,0x8
  2b1b37:	vprord ymm12,ymm12,0x8
  2b1b3e:	vprord ymm13,ymm13,0x8
  2b1b45:	vprord ymm14,ymm14,0x8
  2b1b4c:	vpaddd ymm10,ymm10,ymm15
  2b1b51:	vpaddd ymm11,ymm11,ymm12
  2b1b56:	vpaddd ymm8,ymm8,ymm13
  2b1b5b:	vpaddd ymm9,ymm9,ymm14
  2b1b60:	vpxord ymm5,ymm5,ymm10
  2b1b66:	vpxord ymm6,ymm6,ymm11
  2b1b6c:	vpxord ymm7,ymm7,ymm8
  2b1b72:	vpxord ymm4,ymm4,ymm9
  2b1b78:	vprord ymm5,ymm5,0x7
  2b1b7f:	vprord ymm6,ymm6,0x7
  2b1b86:	vprord ymm7,ymm7,0x7
  2b1b8d:	vprord ymm4,ymm4,0x7
  2b1b94:	vpaddd ymm0,ymm0,ymm27
  2b1b9a:	vpaddd ymm1,ymm1,ymm21
  2b1ba0:	vpaddd ymm2,ymm2,ymm17
  2b1ba6:	vpaddd ymm3,ymm3,ymm24
  2b1bac:	vpaddd ymm0,ymm0,ymm4
  2b1bb0:	vpaddd ymm1,ymm1,ymm5
  2b1bb4:	vpaddd ymm2,ymm2,ymm6
  2b1bb8:	vpaddd ymm3,ymm3,ymm7
  2b1bbc:	vpxord ymm12,ymm12,ymm0
  2b1bc2:	vpxord ymm13,ymm13,ymm1
  2b1bc8:	vpxord ymm14,ymm14,ymm2
  2b1bce:	vpxord ymm15,ymm15,ymm3
  2b1bd4:	vprord ymm12,ymm12,0x10
  2b1bdb:	vprord ymm13,ymm13,0x10
  2b1be2:	vprord ymm14,ymm14,0x10
  2b1be9:	vprord ymm15,ymm15,0x10
  2b1bf0:	vpaddd ymm8,ymm8,ymm12
  2b1bf5:	vpaddd ymm9,ymm9,ymm13
  2b1bfa:	vpaddd ymm10,ymm10,ymm14
  2b1bff:	vpaddd ymm11,ymm11,ymm15
  2b1c04:	vpxord ymm4,ymm4,ymm8
  2b1c0a:	vpxord ymm5,ymm5,ymm9
  2b1c10:	vpxord ymm6,ymm6,ymm10
  2b1c16:	vpxord ymm7,ymm7,ymm11
  2b1c1c:	vprord ymm4,ymm4,0xc
  2b1c23:	vprord ymm5,ymm5,0xc
  2b1c2a:	vprord ymm6,ymm6,0xc
  2b1c31:	vprord ymm7,ymm7,0xc
  2b1c38:	vpaddd ymm0,ymm0,ymm31
  2b1c3e:	vpaddd ymm1,ymm1,ymm16
  2b1c44:	vpaddd ymm2,ymm2,ymm25
  2b1c4a:	vpaddd ymm3,ymm3,ymm22
  2b1c50:	vpaddd ymm0,ymm0,ymm4
  2b1c54:	vpaddd ymm1,ymm1,ymm5
  2b1c58:	vpaddd ymm2,ymm2,ymm6
  2b1c5c:	vpaddd ymm3,ymm3,ymm7
  2b1c60:	vpxord ymm12,ymm12,ymm0
  2b1c66:	vpxord ymm13,ymm13,ymm1
  2b1c6c:	vpxord ymm14,ymm14,ymm2
  2b1c72:	vpxord ymm15,ymm15,ymm3
  2b1c78:	vprord ymm12,ymm12,0x8
  2b1c7f:	vprord ymm13,ymm13,0x8
  2b1c86:	vprord ymm14,ymm14,0x8
  2b1c8d:	vprord ymm15,ymm15,0x8
  2b1c94:	vpaddd ymm8,ymm8,ymm12
  2b1c99:	vpaddd ymm9,ymm9,ymm13
  2b1c9e:	vpaddd ymm10,ymm10,ymm14
  2b1ca3:	vpaddd ymm11,ymm11,ymm15
  2b1ca8:	vpxord ymm4,ymm4,ymm8
  2b1cae:	vpxord ymm5,ymm5,ymm9
  2b1cb4:	vpxord ymm6,ymm6,ymm10
  2b1cba:	vpxord ymm7,ymm7,ymm11
  2b1cc0:	vprord ymm4,ymm4,0x7
  2b1cc7:	vprord ymm5,ymm5,0x7
  2b1cce:	vprord ymm6,ymm6,0x7
  2b1cd5:	vprord ymm7,ymm7,0x7
  2b1cdc:	vpaddd ymm0,ymm0,ymm30
  2b1ce2:	vpaddd ymm1,ymm1,ymm18
  2b1ce8:	vpaddd ymm2,ymm2,ymm19
  2b1cee:	vpaddd ymm3,ymm3,ymm23
  2b1cf4:	vpaddd ymm0,ymm0,ymm5
  2b1cf8:	vpaddd ymm1,ymm1,ymm6
  2b1cfc:	vpaddd ymm2,ymm2,ymm7
  2b1d00:	vpaddd ymm3,ymm3,ymm4
  2b1d04:	vpxord ymm15,ymm15,ymm0
  2b1d0a:	vpxord ymm12,ymm12,ymm1
  2b1d10:	vpxord ymm13,ymm13,ymm2
  2b1d16:	vpxord ymm14,ymm14,ymm3
  2b1d1c:	vprord ymm15,ymm15,0x10
  2b1d23:	vprord ymm12,ymm12,0x10
  2b1d2a:	vprord ymm13,ymm13,0x10
  2b1d31:	vprord ymm14,ymm14,0x10
  2b1d38:	vpaddd ymm10,ymm10,ymm15
  2b1d3d:	vpaddd ymm11,ymm11,ymm12
  2b1d42:	vpaddd ymm8,ymm8,ymm13
  2b1d47:	vpaddd ymm9,ymm9,ymm14
  2b1d4c:	vpxord ymm5,ymm5,ymm10
  2b1d52:	vpxord ymm6,ymm6,ymm11
  2b1d58:	vpxord ymm7,ymm7,ymm8
  2b1d5e:	vpxord ymm4,ymm4,ymm9
  2b1d64:	vprord ymm5,ymm5,0xc
  2b1d6b:	vprord ymm6,ymm6,0xc
  2b1d72:	vprord ymm7,ymm7,0xc
  2b1d79:	vprord ymm4,ymm4,0xc
  2b1d80:	vpaddd ymm0,ymm0,ymm26
  2b1d86:	vpaddd ymm1,ymm1,ymm28
  2b1d8c:	vpaddd ymm2,ymm2,ymm20
  2b1d92:	vpaddd ymm3,ymm3,ymm29
  2b1d98:	vpaddd ymm0,ymm0,ymm5
  2b1d9c:	vpaddd ymm1,ymm1,ymm6
  2b1da0:	vpaddd ymm2,ymm2,ymm7
  2b1da4:	vpaddd ymm3,ymm3,ymm4
  2b1da8:	vpxord ymm15,ymm15,ymm0
  2b1dae:	vpxord ymm12,ymm12,ymm1
  2b1db4:	vpxord ymm13,ymm13,ymm2
  2b1dba:	vpxord ymm14,ymm14,ymm3
  2b1dc0:	vprord ymm15,ymm15,0x8
  2b1dc7:	vprord ymm12,ymm12,0x8
  2b1dce:	vprord ymm13,ymm13,0x8
  2b1dd5:	vprord ymm14,ymm14,0x8
  2b1ddc:	vpaddd ymm10,ymm10,ymm15
  2b1de1:	vpaddd ymm11,ymm11,ymm12
  2b1de6:	vpaddd ymm8,ymm8,ymm13
  2b1deb:	vpaddd ymm9,ymm9,ymm14
  2b1df0:	vpxord ymm5,ymm5,ymm10
  2b1df6:	vpxord ymm6,ymm6,ymm11
  2b1dfc:	vpxord ymm7,ymm7,ymm8
  2b1e02:	vpxord ymm4,ymm4,ymm9
  2b1e08:	vprord ymm5,ymm5,0x7
  2b1e0f:	vprord ymm6,ymm6,0x7
  2b1e16:	vprord ymm7,ymm7,0x7
  2b1e1d:	vprord ymm4,ymm4,0x7
  2b1e24:	vpxor  ymm0,ymm0,ymm8
  2b1e29:	vpxor  ymm1,ymm1,ymm9
  2b1e2e:	vpxor  ymm2,ymm2,ymm10
  2b1e33:	vpxor  ymm3,ymm3,ymm11
  2b1e38:	vpxor  ymm4,ymm4,ymm12
  2b1e3d:	vpxor  ymm5,ymm5,ymm13
  2b1e42:	vpxor  ymm6,ymm6,ymm14
  2b1e47:	vpxor  ymm7,ymm7,ymm15
  2b1e4c:	movzx  eax,BYTE PTR [rbp+0x38]
  2b1e50:	jne    2b0a26 <_blake3_hash_many_avx512+0x1aa6>
  2b1e56:	mov    rbx,QWORD PTR [rbp+0x50]
  2b1e5a:	vunpcklps ymm8,ymm0,ymm1
  2b1e5e:	vunpcklps ymm9,ymm2,ymm3
  2b1e62:	vunpckhps ymm10,ymm0,ymm1
  2b1e66:	vunpcklps ymm11,ymm4,ymm5
  2b1e6a:	vunpcklps ymm0,ymm6,ymm7
  2b1e6e:	vshufps ymm12,ymm8,ymm9,0x4e
  2b1e74:	vblendps ymm1,ymm8,ymm12,0xcc
  2b1e7a:	vshufps ymm8,ymm11,ymm0,0x4e
  2b1e7f:	vunpckhps ymm13,ymm2,ymm3
  2b1e83:	vblendps ymm2,ymm11,ymm8,0xcc
  2b1e89:	vblendps ymm3,ymm12,ymm9,0xcc
  2b1e8f:	vperm2f128 ymm12,ymm1,ymm2,0x20
  2b1e95:	vmovups YMMWORD PTR [rbx],ymm12
  2b1e99:	vunpckhps ymm14,ymm4,ymm5
  2b1e9d:	vblendps ymm4,ymm8,ymm0,0xcc
  2b1ea3:	vunpckhps ymm15,ymm6,ymm7
  2b1ea7:	vperm2f128 ymm7,ymm3,ymm4,0x20
  2b1ead:	vmovups YMMWORD PTR [rbx+0x20],ymm7
  2b1eb2:	vshufps ymm5,ymm10,ymm13,0x4e
  2b1eb8:	vblendps ymm6,ymm5,ymm13,0xcc
  2b1ebe:	vshufps ymm13,ymm14,ymm15,0x4e
  2b1ec4:	vblendps ymm10,ymm10,ymm5,0xcc
  2b1eca:	vblendps ymm14,ymm14,ymm13,0xcc
  2b1ed0:	vperm2f128 ymm8,ymm10,ymm14,0x20
  2b1ed6:	vmovups YMMWORD PTR [rbx+0x40],ymm8
  2b1edb:	vblendps ymm15,ymm13,ymm15,0xcc
  2b1ee1:	vperm2f128 ymm13,ymm6,ymm15,0x20
  2b1ee7:	vmovups YMMWORD PTR [rbx+0x60],ymm13
  2b1eec:	vperm2f128 ymm9,ymm1,ymm2,0x31
  2b1ef2:	vperm2f128 ymm11,ymm3,ymm4,0x31
  2b1ef8:	vmovups YMMWORD PTR [rbx+0x80],ymm9
  2b1f00:	vperm2f128 ymm14,ymm10,ymm14,0x31
  2b1f06:	vperm2f128 ymm15,ymm6,ymm15,0x31
  2b1f0c:	vmovups YMMWORD PTR [rbx+0xa0],ymm11
  2b1f14:	vmovups YMMWORD PTR [rbx+0xc0],ymm14
  2b1f1c:	vmovups YMMWORD PTR [rbx+0xe0],ymm15
  2b1f24:	vmovdqa ymm0,YMMWORD PTR [rsp]
  2b1f29:	vmovdqa ymm2,YMMWORD PTR [rsp+0x40]
  2b1f2f:	vmovdqa32 ymm0{k1},YMMWORD PTR [rsp+0x20]
  2b1f37:	vmovdqa32 ymm2{k1},YMMWORD PTR [rsp+0x60]
  2b1f3f:	vmovdqa YMMWORD PTR [rsp],ymm0
  2b1f44:	vmovdqa YMMWORD PTR [rsp+0x40],ymm2
  2b1f4a:	add    rbx,0x100
  2b1f51:	mov    QWORD PTR [rbp+0x50],rbx
  2b1f55:	add    rdi,0x40
  2b1f59:	sub    rsi,0x8
  2b1f5d:	mov    rbx,QWORD PTR [rbp+0x50]
  2b1f61:	mov    r15,QWORD PTR [rsp+0x80]
  2b1f69:	movzx  r13,BYTE PTR [rbp+0x38]
  2b1f6e:	movzx  r12,BYTE PTR [rbp+0x48]
  2b1f73:	test   esi,0x4
  2b1f79:	je     2b22c8 <_blake3_hash_many_avx512+0x3348>
  2b1f7f:	vbroadcasti32x4 zmm0,XMMWORD PTR [rcx]
  2b1f85:	vbroadcasti32x4 zmm1,XMMWORD PTR [rcx+0x10]
  2b1f8c:	vmovdqa xmm12,XMMWORD PTR [rsp]
  2b1f91:	vmovdqa xmm13,XMMWORD PTR [rsp+0x40]
  2b1f97:	vpunpckldq xmm14,xmm12,xmm13
  2b1f9c:	vpunpckhdq xmm15,xmm12,xmm13
  2b1fa1:	vpermq ymm14,ymm14,0xdc
  2b1fa7:	vpermq ymm15,ymm15,0xdc
  2b1fad:	vpbroadcastd zmm12,DWORD PTR [rip+0xffffffffffd8b491]        # 3d448 <BLAKE3_BLOCK_LEN>
  2b1fb7:	vinserti64x4 zmm13,zmm14,ymm15,0x1
  2b1fbe:	mov    eax,0x4444
  2b1fc3:	kmovw  k2,eax
  2b1fc7:	vpblendmd zmm13{k2},zmm13,zmm12
  2b1fcd:	vbroadcasti32x4 zmm15,XMMWORD PTR [rip+0xffffffffffd8b4a9]        # 3d480 <BLAKE3_IV>
  2b1fd7:	mov    r8,QWORD PTR [rdi]
  2b1fda:	mov    r9,QWORD PTR [rdi+0x8]
  2b1fde:	mov    r10,QWORD PTR [rdi+0x10]
  2b1fe2:	mov    r11,QWORD PTR [rdi+0x18]
  2b1fe6:	mov    eax,0xaaaa
  2b1feb:	kmovw  k3,eax
  2b1fef:	mov    eax,0x8888
  2b1ff4:	kmovw  k4,eax
  2b1ff8:	movzx  eax,BYTE PTR [rbp+0x40]
  2b1ffc:	or     eax,r13d
  2b1fff:	xor    edx,edx
  2b2001:	nop    WORD PTR [rax+rax*1+0x0]
  2b200a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b2015:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b2020:	mov    r14d,eax
  2b2023:	or     eax,r12d
  2b2026:	add    rdx,0x40
  2b202a:	cmp    rdx,r15
  2b202d:	cmovne eax,r14d
  2b2031:	mov    DWORD PTR [rsp+0x88],eax
  2b2038:	vmovdqa32 zmm2,zmm15
  2b203e:	vpbroadcastd zmm8,DWORD PTR [rsp+0x88]
  2b2046:	vpblendmd zmm3{k4},zmm13,zmm8
  2b204c:	vmovups zmm8,ZMMWORD PTR [r8+rdx*1-0x40]
  2b2054:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r9+rdx*1-0x40],0x1
  2b205d:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r10+rdx*1-0x40],0x2
  2b2066:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r11+rdx*1-0x40],0x3
  2b206f:	vmovups zmm9,ZMMWORD PTR [r8+rdx*1-0x30]
  2b207a:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r9+rdx*1-0x30],0x1
  2b2083:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r10+rdx*1-0x30],0x2
  2b208c:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r11+rdx*1-0x30],0x3
  2b2095:	vshufps zmm4,zmm8,zmm9,0x88
  2b209c:	vshufps zmm5,zmm8,zmm9,0xdd
  2b20a3:	vmovups zmm8,ZMMWORD PTR [r8+rdx*1-0x20]
  2b20ae:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r9+rdx*1-0x20],0x1
  2b20b7:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r10+rdx*1-0x20],0x2
  2b20c0:	vinserti32x4 zmm8,zmm8,XMMWORD PTR [r11+rdx*1-0x20],0x3
  2b20c9:	vmovups zmm9,ZMMWORD PTR [r8+rdx*1-0x10]
  2b20d4:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r9+rdx*1-0x10],0x1
  2b20dd:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r10+rdx*1-0x10],0x2
  2b20e6:	vinserti32x4 zmm9,zmm9,XMMWORD PTR [r11+rdx*1-0x10],0x3
  2b20ef:	vshufps zmm6,zmm8,zmm9,0x88
  2b20f6:	vshufps zmm7,zmm8,zmm9,0xdd
  2b20fd:	vpshufd zmm6,zmm6,0x93
  2b2104:	vpshufd zmm7,zmm7,0x93
  2b210b:	mov    al,0x7
  2b210d:	vpaddd zmm0,zmm0,zmm4
  2b2113:	vpaddd zmm0,zmm0,zmm1
  2b2119:	vpxord zmm3,zmm3,zmm0
  2b211f:	vprord zmm3,zmm3,0x10
  2b2126:	vpaddd zmm2,zmm2,zmm3
  2b212c:	vpxord zmm1,zmm1,zmm2
  2b2132:	vprord zmm1,zmm1,0xc
  2b2139:	vpaddd zmm0,zmm0,zmm5
  2b213f:	vpaddd zmm0,zmm0,zmm1
  2b2145:	vpxord zmm3,zmm3,zmm0
  2b214b:	vprord zmm3,zmm3,0x8
  2b2152:	vpaddd zmm2,zmm2,zmm3
  2b2158:	vpxord zmm1,zmm1,zmm2
  2b215e:	vprord zmm1,zmm1,0x7
  2b2165:	vpshufd zmm0,zmm0,0x93
  2b216c:	vpshufd zmm3,zmm3,0x4e
  2b2173:	vpshufd zmm2,zmm2,0x39
  2b217a:	vpaddd zmm0,zmm0,zmm6
  2b2180:	vpaddd zmm0,zmm0,zmm1
  2b2186:	vpxord zmm3,zmm3,zmm0
  2b218c:	vprord zmm3,zmm3,0x10
  2b2193:	vpaddd zmm2,zmm2,zmm3
  2b2199:	vpxord zmm1,zmm1,zmm2
  2b219f:	vprord zmm1,zmm1,0xc
  2b21a6:	vpaddd zmm0,zmm0,zmm7
  2b21ac:	vpaddd zmm0,zmm0,zmm1
  2b21b2:	vpxord zmm3,zmm3,zmm0
  2b21b8:	vprord zmm3,zmm3,0x8
  2b21bf:	vpaddd zmm2,zmm2,zmm3
  2b21c5:	vpxord zmm1,zmm1,zmm2
  2b21cb:	vprord zmm1,zmm1,0x7
  2b21d2:	vpshufd zmm0,zmm0,0x39
  2b21d9:	vpshufd zmm3,zmm3,0x4e
  2b21e0:	vpshufd zmm2,zmm2,0x93
  2b21e7:	dec    al
  2b21e9:	je     2b2244 <_blake3_hash_many_avx512+0x32c4>
  2b21eb:	vshufps zmm8,zmm4,zmm5,0xd6
  2b21f2:	vpshufd zmm9,zmm4,0xf
  2b21f9:	vpshufd zmm4,zmm8,0x39
  2b2200:	vshufps zmm8,zmm6,zmm7,0xfa
  2b2207:	vpblendmd zmm9{k3},zmm9,zmm8
  2b220d:	vpunpcklqdq zmm8,zmm7,zmm5
  2b2213:	vpblendmd zmm8{k4},zmm8,zmm6
  2b2219:	vpshufd zmm8,zmm8,0x78
  2b2220:	vpunpckhdq zmm5,zmm5,zmm7
  2b2226:	vpunpckldq zmm6,zmm6,zmm5
  2b222c:	vpshufd zmm7,zmm6,0x1e
  2b2233:	vmovdqa32 zmm5,zmm9
  2b2239:	vmovdqa32 zmm6,zmm8
  2b223f:	jmp    2b210d <_blake3_hash_many_avx512+0x318d>
  2b2244:	vpxord zmm0,zmm0,zmm2
  2b224a:	vpxord zmm1,zmm1,zmm3
  2b2250:	mov    eax,r13d
  2b2253:	cmp    rdx,r15
  2b2256:	jne    2b2020 <_blake3_hash_many_avx512+0x30a0>
  2b225c:	vmovdqu XMMWORD PTR [rbx],xmm0
  2b2260:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2b2265:	vextracti128 XMMWORD PTR [rbx+0x20],ymm0,0x1
  2b226c:	vextracti128 XMMWORD PTR [rbx+0x30],ymm1,0x1
  2b2273:	vextracti32x4 XMMWORD PTR [rbx+0x40],zmm0,0x2
  2b227b:	vextracti32x4 XMMWORD PTR [rbx+0x50],zmm1,0x2
  2b2283:	vextracti32x4 XMMWORD PTR [rbx+0x60],zmm0,0x3
  2b228b:	vextracti32x4 XMMWORD PTR [rbx+0x70],zmm1,0x3
  2b2293:	vmovdqa xmm0,XMMWORD PTR [rsp]
  2b2298:	vmovdqa xmm2,XMMWORD PTR [rsp+0x40]
  2b229e:	vmovdqa32 xmm0{k1},XMMWORD PTR [rsp+0x10]
  2b22a6:	vmovdqa32 xmm2{k1},XMMWORD PTR [rsp+0x50]
  2b22ae:	vmovdqa XMMWORD PTR [rsp],xmm0
  2b22b3:	vmovdqa XMMWORD PTR [rsp+0x40],xmm2
  2b22b9:	add    rbx,0x80
  2b22c0:	add    rdi,0x20
  2b22c4:	sub    rsi,0x4
  2b22c8:	test   esi,0x2
  2b22ce:	je     2b2533 <_blake3_hash_many_avx512+0x35b3>
  2b22d4:	vbroadcasti128 ymm0,XMMWORD PTR [rcx]
  2b22d9:	vbroadcasti128 ymm1,XMMWORD PTR [rcx+0x10]
  2b22df:	vmovd  xmm13,DWORD PTR [rsp]
  2b22e4:	vpinsrd xmm13,xmm13,DWORD PTR [rsp+0x40],0x1
  2b22ec:	vpinsrd xmm13,xmm13,DWORD PTR [rip+0xffffffffffd8b152],0x2        # 3d448 <BLAKE3_BLOCK_LEN>
  2b22f6:	vmovd  xmm14,DWORD PTR [rsp+0x4]
  2b22fc:	vpinsrd xmm14,xmm14,DWORD PTR [rsp+0x44],0x1
  2b2304:	vpinsrd xmm14,xmm14,DWORD PTR [rip+0xffffffffffd8b13a],0x2        # 3d448 <BLAKE3_BLOCK_LEN>
  2b230e:	vinserti128 ymm13,ymm13,xmm14,0x1
  2b2314:	mov    r8,QWORD PTR [rdi]
  2b2317:	mov    r9,QWORD PTR [rdi+0x8]
  2b231b:	movzx  eax,BYTE PTR [rbp+0x40]
  2b231f:	or     eax,r13d
  2b2322:	xor    edx,edx
  2b2324:	nop    WORD PTR [rax+rax*1+0x0]
  2b232a:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b2335:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b2340:	mov    r14d,eax
  2b2343:	or     eax,r12d
  2b2346:	add    rdx,0x40
  2b234a:	cmp    rdx,r15
  2b234d:	cmovne eax,r14d
  2b2351:	mov    DWORD PTR [rsp+0x88],eax
  2b2358:	vbroadcasti128 ymm2,XMMWORD PTR [rip+0xffffffffffd8b11f]        # 3d480 <BLAKE3_IV>
  2b2361:	vpbroadcastd ymm8,DWORD PTR [rsp+0x88]
  2b236b:	vpblendd ymm3,ymm13,ymm8,0x88
  2b2371:	vmovups ymm8,YMMWORD PTR [r8+rdx*1-0x40]
  2b2378:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r9+rdx*1-0x40],0x1
  2b2380:	vmovups ymm9,YMMWORD PTR [r8+rdx*1-0x30]
  2b2387:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r9+rdx*1-0x30],0x1
  2b238f:	vshufps ymm4,ymm8,ymm9,0x88
  2b2395:	vshufps ymm5,ymm8,ymm9,0xdd
  2b239b:	vmovups ymm8,YMMWORD PTR [r8+rdx*1-0x20]
  2b23a2:	vinsertf128 ymm8,ymm8,XMMWORD PTR [r9+rdx*1-0x20],0x1
  2b23aa:	vmovups ymm9,YMMWORD PTR [r8+rdx*1-0x10]
  2b23b1:	vinsertf128 ymm9,ymm9,XMMWORD PTR [r9+rdx*1-0x10],0x1
  2b23b9:	vshufps ymm6,ymm8,ymm9,0x88
  2b23bf:	vshufps ymm7,ymm8,ymm9,0xdd
  2b23c5:	vpshufd ymm6,ymm6,0x93
  2b23ca:	vpshufd ymm7,ymm7,0x93
  2b23cf:	mov    al,0x7
  2b23d1:	vpaddd ymm0,ymm0,ymm4
  2b23d5:	vpaddd ymm0,ymm0,ymm1
  2b23d9:	vpxord ymm3,ymm3,ymm0
  2b23df:	vprord ymm3,ymm3,0x10
  2b23e6:	vpaddd ymm2,ymm2,ymm3
  2b23ea:	vpxord ymm1,ymm1,ymm2
  2b23f0:	vprord ymm1,ymm1,0xc
  2b23f7:	vpaddd ymm0,ymm0,ymm5
  2b23fb:	vpaddd ymm0,ymm0,ymm1
  2b23ff:	vpxord ymm3,ymm3,ymm0
  2b2405:	vprord ymm3,ymm3,0x8
  2b240c:	vpaddd ymm2,ymm2,ymm3
  2b2410:	vpxord ymm1,ymm1,ymm2
  2b2416:	vprord ymm1,ymm1,0x7
  2b241d:	vpshufd ymm0,ymm0,0x93
  2b2422:	vpshufd ymm3,ymm3,0x4e
  2b2427:	vpshufd ymm2,ymm2,0x39
  2b242c:	vpaddd ymm0,ymm0,ymm6
  2b2430:	vpaddd ymm0,ymm0,ymm1
  2b2434:	vpxord ymm3,ymm3,ymm0
  2b243a:	vprord ymm3,ymm3,0x10
  2b2441:	vpaddd ymm2,ymm2,ymm3
  2b2445:	vpxord ymm1,ymm1,ymm2
  2b244b:	vprord ymm1,ymm1,0xc
  2b2452:	vpaddd ymm0,ymm0,ymm7
  2b2456:	vpaddd ymm0,ymm0,ymm1
  2b245a:	vpxord ymm3,ymm3,ymm0
  2b2460:	vprord ymm3,ymm3,0x8
  2b2467:	vpaddd ymm2,ymm2,ymm3
  2b246b:	vpxord ymm1,ymm1,ymm2
  2b2471:	vprord ymm1,ymm1,0x7
  2b2478:	vpshufd ymm0,ymm0,0x39
  2b247d:	vpshufd ymm3,ymm3,0x4e
  2b2482:	vpshufd ymm2,ymm2,0x93
  2b2487:	dec    al
  2b2489:	je     2b24d0 <_blake3_hash_many_avx512+0x3550>
  2b248b:	vshufps ymm8,ymm4,ymm5,0xd6
  2b2490:	vpshufd ymm9,ymm4,0xf
  2b2495:	vpshufd ymm4,ymm8,0x39
  2b249b:	vshufps ymm8,ymm6,ymm7,0xfa
  2b24a0:	vpblendd ymm9,ymm9,ymm8,0xaa
  2b24a6:	vpunpcklqdq ymm8,ymm7,ymm5
  2b24aa:	vpblendd ymm8,ymm8,ymm6,0x88
  2b24b0:	vpshufd ymm8,ymm8,0x78
  2b24b6:	vpunpckhdq ymm5,ymm5,ymm7
  2b24ba:	vpunpckldq ymm6,ymm6,ymm5
  2b24be:	vpshufd ymm7,ymm6,0x1e
  2b24c3:	vmovdqa ymm5,ymm9
  2b24c7:	vmovdqa ymm6,ymm8
  2b24cb:	jmp    2b23d1 <_blake3_hash_many_avx512+0x3451>
  2b24d0:	vpxor  ymm0,ymm0,ymm2
  2b24d4:	vpxor  ymm1,ymm1,ymm3
  2b24d8:	mov    eax,r13d
  2b24db:	cmp    rdx,r15
  2b24de:	jne    2b2340 <_blake3_hash_many_avx512+0x33c0>
  2b24e4:	vmovdqu XMMWORD PTR [rbx],xmm0
  2b24e8:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2b24ed:	vextracti128 XMMWORD PTR [rbx+0x20],ymm0,0x1
  2b24f4:	vextracti128 XMMWORD PTR [rbx+0x30],ymm1,0x1
  2b24fb:	vmovdqa xmm0,XMMWORD PTR [rsp]
  2b2500:	vmovdqa xmm2,XMMWORD PTR [rsp+0x40]
  2b2506:	vmovdqu32 xmm0{k1},XMMWORD PTR [rsp+0x8]
  2b2511:	vmovdqu32 xmm2{k1},XMMWORD PTR [rsp+0x48]
  2b251c:	vmovdqa XMMWORD PTR [rsp],xmm0
  2b2521:	vmovdqa XMMWORD PTR [rsp+0x40],xmm2
  2b2527:	add    rbx,0x40
  2b252b:	add    rdi,0x10
  2b252f:	sub    rsi,0x2
  2b2533:	test   esi,0x1
  2b2539:	je     2b097a <_blake3_hash_many_avx512+0x19fa>
  2b253f:	vmovdqu xmm0,XMMWORD PTR [rcx]
  2b2543:	vmovdqu xmm1,XMMWORD PTR [rcx+0x10]
  2b2548:	vmovd  xmm14,DWORD PTR [rsp]
  2b254d:	vpinsrd xmm14,xmm14,DWORD PTR [rsp+0x40],0x1
  2b2555:	vpinsrd xmm14,xmm14,DWORD PTR [rip+0xffffffffffd8aee9],0x2        # 3d448 <BLAKE3_BLOCK_LEN>
  2b255f:	vmovdqa xmm15,XMMWORD PTR [rip+0xffffffffffd8af19]        # 3d480 <BLAKE3_IV>
  2b2567:	mov    r8,QWORD PTR [rdi]
  2b256a:	movzx  eax,BYTE PTR [rbp+0x40]
  2b256e:	or     eax,r13d
  2b2571:	xor    edx,edx
  2b2573:	xchg   ax,ax
  2b2575:	data16 cs nop WORD PTR [rax+rax*1+0x0]
  2b2580:	mov    r14d,eax
  2b2583:	or     eax,r12d
  2b2586:	add    rdx,0x40
  2b258a:	cmp    rdx,r15
  2b258d:	cmovne eax,r14d
  2b2591:	vpinsrd xmm3,xmm14,eax,0x3
  2b2597:	vmovdqa xmm2,xmm15
  2b259b:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x40]
  2b25a2:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x30]
  2b25a9:	vshufps xmm4,xmm8,xmm9,0x88
  2b25af:	vshufps xmm5,xmm8,xmm9,0xdd
  2b25b5:	vmovups xmm8,XMMWORD PTR [r8+rdx*1-0x20]
  2b25bc:	vmovups xmm9,XMMWORD PTR [r8+rdx*1-0x10]
  2b25c3:	vshufps xmm6,xmm8,xmm9,0x88
  2b25c9:	vshufps xmm7,xmm8,xmm9,0xdd
  2b25cf:	vpshufd xmm6,xmm6,0x93
  2b25d4:	vpshufd xmm7,xmm7,0x93
  2b25d9:	mov    al,0x7
  2b25db:	vpaddd xmm0,xmm0,xmm4
  2b25df:	vpaddd xmm0,xmm0,xmm1
  2b25e3:	vpxord xmm3,xmm3,xmm0
  2b25e9:	vprord xmm3,xmm3,0x10
  2b25f0:	vpaddd xmm2,xmm2,xmm3
  2b25f4:	vpxord xmm1,xmm1,xmm2
  2b25fa:	vprord xmm1,xmm1,0xc
  2b2601:	vpaddd xmm0,xmm0,xmm5
  2b2605:	vpaddd xmm0,xmm0,xmm1
  2b2609:	vpxord xmm3,xmm3,xmm0
  2b260f:	vprord xmm3,xmm3,0x8
  2b2616:	vpaddd xmm2,xmm2,xmm3
  2b261a:	vpxord xmm1,xmm1,xmm2
  2b2620:	vprord xmm1,xmm1,0x7
  2b2627:	vpshufd xmm0,xmm0,0x93
  2b262c:	vpshufd xmm3,xmm3,0x4e
  2b2631:	vpshufd xmm2,xmm2,0x39
  2b2636:	vpaddd xmm0,xmm0,xmm6
  2b263a:	vpaddd xmm0,xmm0,xmm1
  2b263e:	vpxord xmm3,xmm3,xmm0
  2b2644:	vprord xmm3,xmm3,0x10
  2b264b:	vpaddd xmm2,xmm2,xmm3
  2b264f:	vpxord xmm1,xmm1,xmm2
  2b2655:	vprord xmm1,xmm1,0xc
  2b265c:	vpaddd xmm0,xmm0,xmm7
  2b2660:	vpaddd xmm0,xmm0,xmm1
  2b2664:	vpxord xmm3,xmm3,xmm0
  2b266a:	vprord xmm3,xmm3,0x8
  2b2671:	vpaddd xmm2,xmm2,xmm3
  2b2675:	vpxord xmm1,xmm1,xmm2
  2b267b:	vprord xmm1,xmm1,0x7
  2b2682:	vpshufd xmm0,xmm0,0x39
  2b2687:	vpshufd xmm3,xmm3,0x4e
  2b268c:	vpshufd xmm2,xmm2,0x93
  2b2691:	dec    al
  2b2693:	je     2b26da <_blake3_hash_many_avx512+0x375a>
  2b2695:	vshufps xmm8,xmm4,xmm5,0xd6
  2b269a:	vpshufd xmm9,xmm4,0xf
  2b269f:	vpshufd xmm4,xmm8,0x39
  2b26a5:	vshufps xmm8,xmm6,xmm7,0xfa
  2b26aa:	vpblendd xmm9,xmm9,xmm8,0xaa
  2b26b0:	vpunpcklqdq xmm8,xmm7,xmm5
  2b26b4:	vpblendd xmm8,xmm8,xmm6,0x88
  2b26ba:	vpshufd xmm8,xmm8,0x78
  2b26c0:	vpunpckhdq xmm5,xmm5,xmm7
  2b26c4:	vpunpckldq xmm6,xmm6,xmm5
  2b26c8:	vpshufd xmm7,xmm6,0x1e
  2b26cd:	vmovdqa xmm5,xmm9
  2b26d1:	vmovdqa xmm6,xmm8
  2b26d5:	jmp    2b25db <_blake3_hash_many_avx512+0x365b>
  2b26da:	vpxor  xmm0,xmm0,xmm2
  2b26de:	vpxor  xmm1,xmm1,xmm3
  2b26e2:	mov    eax,r13d
  2b26e5:	cmp    rdx,r15
  2b26e8:	jne    2b2580 <_blake3_hash_many_avx512+0x3600>
  2b26ee:	vmovdqu XMMWORD PTR [rbx],xmm0
  2b26f2:	vmovdqu XMMWORD PTR [rbx+0x10],xmm1
  2b26f7:	jmp    2b097a <_blake3_hash_many_avx512+0x19fa>
  2b26fc:	nop    DWORD PTR [rax+0x0]
