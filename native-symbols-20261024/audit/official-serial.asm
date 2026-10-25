
/home/samshackleton/blake3-reports/review/github-round-20261024-2254/native/baseline-L0:     file format elf64-x86-64


Disassembly of section .text:

000000000010a2a0 <blake3::hash_all_at_once::<blake3::join::SerialJoin>>:
  10a2a0:	push   %rbp
  10a2a1:	push   %r15
  10a2a3:	push   %r14
  10a2a5:	push   %r13
  10a2a7:	push   %r12
  10a2a9:	push   %rbx
  10a2aa:	sub    $0x88,%rsp
  10a2b1:	mov    %rdi,%rbx
  10a2b4:	movzbl 0x1bab97(%rip),%eax        # 2c4e52 <blake3::platform::avx512_detected::has_avx512::STORAGE>
  10a2bb:	mov    $0x4,%bpl
  10a2be:	cmp    $0x1,%al
  10a2c0:	je     10a304 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x64>
  10a2c2:	movzbl %al,%eax
  10a2c5:	cmp    $0xff,%eax
  10a2ca:	je     10a40c <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x16c>
  10a2d0:	movzbl 0x1bab79(%rip),%eax        # 2c4e50 <blake3::platform::avx2_detected::has_avx2::STORAGE>
  10a2d7:	mov    $0x3,%bpl
  10a2da:	cmp    $0x1,%al
  10a2dc:	je     10a304 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x64>
  10a2de:	movzbl %al,%eax
  10a2e1:	cmp    $0xff,%eax
  10a2e6:	je     10a436 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x196>
  10a2ec:	movzbl 0x1bab5e(%rip),%eax        # 2c4e51 <blake3::platform::sse41_detected::has_sse41::STORAGE>
  10a2f3:	cmp    $0xff,%al
  10a2f5:	je     10a460 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x1c0>
  10a2fb:	cmp    $0x1,%al
  10a2fd:	sete   %bpl
  10a301:	inc    %bpl
  10a304:	cmp    $0x401,%rdx
  10a30b:	jae    10a3b5 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x115>
  10a311:	xorps  %xmm0,%xmm0
  10a314:	movaps %xmm0,0x40(%rsp)
  10a319:	movaps %xmm0,0x30(%rsp)
  10a31e:	movaps %xmm0,0x20(%rsp)
  10a323:	movaps %xmm0,0x10(%rsp)
  10a328:	movups (%rcx),%xmm0
  10a32b:	movups 0x10(%rcx),%xmm1
  10a32f:	movaps %xmm0,0x50(%rsp)
  10a334:	movaps %xmm1,0x60(%rsp)
  10a339:	movq   $0x0,0x70(%rsp)
  10a342:	movw   $0x0,0x78(%rsp)
  10a349:	mov    %r8b,0x7a(%rsp)
  10a34e:	mov    %bpl,0x7b(%rsp)
  10a353:	lea    0x10(%rsp),%rdi
  10a358:	call   10a830 <<blake3::ChunkState>::update>
  10a35d:	cmpb   $0x0,0x79(%rsp)
  10a362:	sete   %r14b
  10a366:	or     0x7a(%rsp),%r14b
  10a36b:	or     $0x2,%r14b
  10a36f:	movaps 0x50(%rsp),%xmm0
  10a374:	movaps 0x60(%rsp),%xmm1
  10a379:	movups %xmm1,0x50(%rbx)
  10a37d:	movups %xmm0,0x40(%rbx)
  10a381:	movaps 0x10(%rsp),%xmm0
  10a386:	movaps 0x20(%rsp),%xmm1
  10a38b:	movaps 0x30(%rsp),%xmm2
  10a390:	movaps 0x40(%rsp),%xmm3
  10a395:	movups %xmm3,0x30(%rbx)
  10a399:	movups %xmm2,0x20(%rbx)
  10a39d:	movups %xmm1,0x10(%rbx)
  10a3a1:	movups %xmm0,(%rbx)
  10a3a4:	movzbl 0x78(%rsp),%eax
  10a3a9:	mov    0x70(%rsp),%r12
  10a3ae:	movzbl 0x7b(%rsp),%ebp
  10a3b3:	jmp    10a3eb <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x14b>
  10a3b5:	movzbl %bpl,%eax
  10a3b9:	mov    %eax,(%rsp)
  10a3bc:	movzbl %r8b,%r14d
  10a3c0:	xor    %r12d,%r12d
  10a3c3:	mov    %rbx,%rdi
  10a3c6:	mov    %rcx,%r15
  10a3c9:	xor    %r8d,%r8d
  10a3cc:	mov    %r14d,%r9d
  10a3cf:	call   10a640 <blake3::compress_subtree_to_parent_node::<blake3::join::SerialJoin>>
  10a3d4:	or     $0x4,%r14b
  10a3d8:	movups (%r15),%xmm0
  10a3dc:	movups 0x10(%r15),%xmm1
  10a3e1:	movups %xmm1,0x50(%rbx)
  10a3e5:	movups %xmm0,0x40(%rbx)
  10a3e9:	mov    $0x40,%al
  10a3eb:	mov    %al,0x68(%rbx)
  10a3ee:	mov    %r12,0x60(%rbx)
  10a3f2:	mov    %r14b,0x69(%rbx)
  10a3f6:	mov    %bpl,0x6a(%rbx)
  10a3fa:	add    $0x88,%rsp
  10a401:	pop    %rbx
  10a402:	pop    %r12
  10a404:	pop    %r13
  10a406:	pop    %r14
  10a408:	pop    %r15
  10a40a:	pop    %rbp
  10a40b:	ret
  10a40c:	mov    %rdx,%r14
  10a40f:	mov    %rcx,%r12
  10a412:	mov    %rsi,%r15
  10a415:	mov    %r8d,%r13d
  10a418:	call   10a550 <blake3::platform::avx512_detected::has_avx512::init_get::init_inner>
  10a41d:	mov    %r13d,%r8d
  10a420:	mov    %r15,%rsi
  10a423:	mov    %r12,%rcx
  10a426:	mov    %r14,%rdx
  10a429:	test   %al,%al
  10a42b:	je     10a2d0 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x30>
  10a431:	jmp    10a304 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x64>
  10a436:	mov    %rdx,%r14
  10a439:	mov    %rcx,%r12
  10a43c:	mov    %rsi,%r15
  10a43f:	mov    %r8d,%r13d
  10a442:	call   10a5d0 <blake3::platform::avx2_detected::has_avx2::init_get::init_inner>
  10a447:	mov    %r13d,%r8d
  10a44a:	mov    %r15,%rsi
  10a44d:	mov    %r12,%rcx
  10a450:	mov    %r14,%rdx
  10a453:	test   %al,%al
  10a455:	je     10a2ec <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x4c>
  10a45b:	jmp    10a304 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x64>
  10a460:	mov    $0x1,%eax
  10a465:	mov    %rcx,%rdi
  10a468:	xor    %ecx,%ecx
  10a46a:	mov    %rdx,%r9
  10a46d:	mov    %rbx,%r10
  10a470:	cpuid
  10a472:	xchg   %r10,%rbx
  10a475:	mov    %ecx,%ebp
  10a477:	mov    $0x7,%eax
  10a47c:	xor    %ecx,%ecx
  10a47e:	mov    %rbx,%r10
  10a481:	cpuid
  10a483:	xchg   %r10,%rbx
  10a486:	mov    $0x7,%eax
  10a48b:	mov    $0x1,%ecx
  10a490:	mov    %rbx,%r10
  10a493:	cpuid
  10a495:	xchg   %r10,%rbx
  10a498:	mov    %rdi,%rcx
  10a49b:	mov    %r9,%rdx
  10a49e:	shr    $0x13,%ebp
  10a4a1:	and    $0x1,%ebp
  10a4a4:	mov    %bpl,0x1ba9a6(%rip)        # 2c4e51 <blake3::platform::sse41_detected::has_sse41::STORAGE>
  10a4ab:	jmp    10a301 <blake3::hash_all_at_once::<blake3::join::SerialJoin>+0x61>
