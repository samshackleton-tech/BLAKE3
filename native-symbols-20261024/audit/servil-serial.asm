
/home/samshackleton/blake3-reports/review/github-round-20261024-2254/native/baseline-L0:     file format elf64-x86-64


Disassembly of section .text:

00000000000b97f0 <blake3_servil::hash_serial>:
   b97f0:	push   %rbp
   b97f1:	mov    %rsp,%rbp
   b97f4:	push   %r15
   b97f6:	push   %r14
   b97f8:	push   %r13
   b97fa:	push   %r12
   b97fc:	push   %rbx
   b97fd:	and    $0xffffffffffffffc0,%rsp
   b9801:	sub    $0x240,%rsp
   b9808:	movzbl 0x20c273(%rip),%ebx        # 2c5a82 <blake3_servil::platform::DETECTED>
   b980f:	test   %bl,%bl
   b9811:	je     b9be9 <blake3_servil::hash_serial+0x3f9>
   b9817:	mov    %r8d,%r12d
   b981a:	mov    %rcx,%r14
   b981d:	mov    %rdx,%r13
   b9820:	mov    %rsi,%r15
   b9823:	movzbl %bl,%ecx
   b9826:	mov    %r14,0xf0(%rsp)
   b982e:	mov    %r12b,0xf8(%rsp)
   b9836:	mov    %bl,0xf9(%rsp)
   b983d:	cmp    $0x401,%rdx
   b9844:	mov    %rdi,0x38(%rsp)
   b9849:	jae    b990d <blake3_servil::hash_serial+0x11d>
   b984f:	xorps  %xmm0,%xmm0
   b9852:	movaps %xmm0,0x70(%rsp)
   b9857:	movaps %xmm0,0x60(%rsp)
   b985c:	movaps %xmm0,0x50(%rsp)
   b9861:	movaps %xmm0,0x40(%rsp)
   b9866:	lea    0x80(%rsp),%rsi
   b986e:	movups (%r14),%xmm0
   b9872:	movups 0x10(%r14),%xmm1
   b9877:	movaps %xmm0,0x80(%rsp)
   b987f:	movaps %xmm1,0x90(%rsp)
   b9887:	movq   $0x0,0xa0(%rsp)
   b9893:	movw   $0x0,0xa8(%rsp)
   b989d:	mov    %r12b,0xaa(%rsp)
   b98a5:	mov    %bl,0xab(%rsp)
   b98ac:	cmp    $0x41,%r13
   b98b0:	jb     b9a12 <blake3_servil::hash_serial+0x222>
   b98b6:	lea    -0x1(%r13),%rbx
   b98ba:	mov    %rbx,%r14
   b98bd:	shr    $0x6,%r14
   b98c1:	movzbl %r12b,%eax
   b98c5:	mov    %ecx,%edi
   b98c7:	mov    %rsi,%r12
   b98ca:	mov    %r15,%rdx
   b98cd:	mov    %r13,%rcx
   b98d0:	mov    %r14,%r8
   b98d3:	xor    %r9d,%r9d
   b98d6:	push   $0x1
   b98d8:	push   %rax
   b98d9:	call   115fe0 <<blake3_servil::platform::Platform>::compress_blocks>
   b98de:	add    $0x10,%rsp
   b98e2:	add    %r14b,0xa9(%rsp)
   b98ea:	and    $0xffffffffffffffc0,%rbx
   b98ee:	mov    %r13,%rax
   b98f1:	sub    %rbx,%rax
   b98f4:	jb     b9bff <blake3_servil::hash_serial+0x40f>
   b98fa:	add    %rbx,%r15
   b98fd:	movzbl 0xa8(%rsp),%edi
   b9905:	mov    %rax,%r13
   b9908:	jmp    b9a17 <blake3_servil::hash_serial+0x227>
   b990d:	lea    0x1c0(%rsp),%rdi
   b9915:	lea    0xf0(%rsp),%rsi
   b991d:	mov    %r15,%rdx
   b9920:	mov    %rcx,%r15
   b9923:	mov    %r13,%rcx
   b9926:	xor    %r8d,%r8d
   b9929:	xor    %r9d,%r9d
   b992c:	call   10eca0 <blake3_servil::tree::root_children::<blake3_servil::tree::PlatformKernels>>
   b9931:	movups 0x1c0(%rsp),%xmm0
   b9939:	movups 0x1d0(%rsp),%xmm1
   b9941:	movups 0x1e0(%rsp),%xmm2
   b9949:	movups 0x1f0(%rsp),%xmm3
   b9951:	movaps %xmm1,0x110(%rsp)
   b9959:	movaps %xmm0,0x100(%rsp)
   b9961:	movaps %xmm2,0x120(%rsp)
   b9969:	movaps %xmm3,0x130(%rsp)
   b9971:	mov    %r12d,%eax
   b9974:	or     $0x4,%al
   b9976:	movaps %xmm3,0x70(%rsp)
   b997b:	movaps %xmm2,0x60(%rsp)
   b9980:	movaps %xmm1,0x50(%rsp)
   b9985:	movaps %xmm0,0x40(%rsp)
   b998a:	movups (%r14),%xmm0
   b998e:	movaps %xmm0,0x80(%rsp)
   b9996:	movups 0x10(%r14),%xmm0
   b999b:	movaps %xmm0,0x90(%rsp)
   b99a3:	movb   $0x40,0xa0(%rsp)
   b99ab:	movq   $0x0,0xa8(%rsp)
   b99b7:	mov    %al,0xb0(%rsp)
   b99be:	mov    %bl,0xb1(%rsp)
   b99c5:	movups (%r14),%xmm0
   b99c9:	movups 0x10(%r14),%xmm1
   b99ce:	movaps %xmm1,0x110(%rsp)
   b99d6:	movaps %xmm0,0x100(%rsp)
   b99de:	or     $0xc,%r12b
   b99e2:	lea    -0x3(%r15),%eax
   b99e6:	cmp    $0x2,%eax
   b99e9:	jae    b9b30 <blake3_servil::hash_serial+0x340>
   b99ef:	movzbl %r12b,%r8d
   b99f3:	lea    0x100(%rsp),%rdi
   b99fb:	lea    0x40(%rsp),%rsi
   b9a00:	mov    $0x40,%edx
   b9a05:	xor    %ecx,%ecx
   b9a07:	call   *0x209f7b(%rip)        # 2c3988 <_DYNAMIC+0x300>
   b9a0d:	jmp    b9b84 <blake3_servil::hash_serial+0x394>
   b9a12:	mov    %rsi,%r12
   b9a15:	xor    %edi,%edi
   b9a17:	mov    $0x40,%ebx
   b9a1c:	sub    %rdi,%rbx
   b9a1f:	cmp    %r13,%rbx
   b9a22:	cmovae %r13,%rbx
   b9a26:	lea    (%rbx,%rdi,1),%rsi
   b9a2a:	cmp    $0x41,%rsi
   b9a2e:	jae    b9bee <blake3_servil::hash_serial+0x3fe>
   b9a34:	add    %rsp,%rdi
   b9a37:	add    $0x40,%rdi
   b9a3b:	mov    %r15,%rsi
   b9a3e:	mov    %rbx,%rdx
   b9a41:	call   *0x209e51(%rip)        # 2c3898 <memcpy@GLIBC_2.14>
   b9a47:	add    0xa8(%rsp),%bl
   b9a4e:	mov    %bl,0xa8(%rsp)
   b9a55:	movaps 0x40(%rsp),%xmm0
   b9a5a:	movaps 0x50(%rsp),%xmm1
   b9a5f:	movaps 0x60(%rsp),%xmm2
   b9a64:	movaps 0x70(%rsp),%xmm3
   b9a69:	movaps %xmm0,0x100(%rsp)
   b9a71:	movaps %xmm1,0x110(%rsp)
   b9a79:	movaps %xmm2,0x120(%rsp)
   b9a81:	movaps %xmm3,0x130(%rsp)
   b9a89:	movaps (%r12),%xmm0
   b9a8e:	movaps 0x10(%r12),%xmm1
   b9a94:	movaps %xmm1,0x1d0(%rsp)
   b9a9c:	movaps %xmm0,0x1c0(%rsp)
   b9aa4:	mov    0xa0(%rsp),%rdx
   b9aac:	cmpb   $0x0,0xa9(%rsp)
   b9ab4:	sete   %al
   b9ab7:	or     0xaa(%rsp),%al
   b9abe:	mov    %eax,%esi
   b9ac0:	or     $0x2,%sil
   b9ac4:	movzbl 0xab(%rsp),%ecx
   b9acc:	movaps (%r12),%xmm0
   b9ad1:	movaps 0x10(%r12),%xmm1
   b9ad7:	movaps %xmm1,0x150(%rsp)
   b9adf:	movaps %xmm0,0x140(%rsp)
   b9ae7:	mov    %bl,0x160(%rsp)
   b9aee:	mov    %rdx,0x168(%rsp)
   b9af6:	mov    %sil,0x170(%rsp)
   b9afe:	mov    %cl,0x171(%rsp)
   b9b05:	or     $0xa,%al
   b9b07:	lea    -0x3(%rcx),%edx
   b9b0a:	cmp    $0x2,%edx
   b9b0d:	jae    b9b57 <blake3_servil::hash_serial+0x367>
   b9b0f:	movzbl %bl,%edx
   b9b12:	movzbl %al,%r8d
   b9b16:	lea    0x1c0(%rsp),%rdi
   b9b1e:	lea    0x100(%rsp),%rsi
   b9b26:	xor    %ecx,%ecx
   b9b28:	call   *0x209e5a(%rip)        # 2c3988 <_DYNAMIC+0x300>
   b9b2e:	jmp    b9b9e <blake3_servil::hash_serial+0x3ae>
   b9b30:	mov    %r15,%rcx
   b9b33:	movzbl %r12b,%r8d
   b9b37:	lea    0x100(%rsp),%rdi
   b9b3f:	lea    0x40(%rsp),%rsi
   b9b44:	mov    $0x40,%edx
   b9b49:	cmp    $0x1,%ecx
   b9b4c:	jne    b9b7c <blake3_servil::hash_serial+0x38c>
   b9b4e:	xor    %ecx,%ecx
   b9b50:	call   10fe30 <blake3_servil::portable::compress_in_place>
   b9b55:	jmp    b9b84 <blake3_servil::hash_serial+0x394>
   b9b57:	movzbl %bl,%edx
   b9b5a:	movzbl %al,%r8d
   b9b5e:	lea    0x1c0(%rsp),%rdi
   b9b66:	lea    0x100(%rsp),%rsi
   b9b6e:	cmp    $0x1,%ecx
   b9b71:	jne    b9b96 <blake3_servil::hash_serial+0x3a6>
   b9b73:	xor    %ecx,%ecx
   b9b75:	call   10fe30 <blake3_servil::portable::compress_in_place>
   b9b7a:	jmp    b9b9e <blake3_servil::hash_serial+0x3ae>
   b9b7c:	xor    %ecx,%ecx
   b9b7e:	call   *0x209e0c(%rip)        # 2c3990 <_DYNAMIC+0x308>
   b9b84:	movaps 0x100(%rsp),%xmm0
   b9b8c:	movaps 0x110(%rsp),%xmm1
   b9b94:	jmp    b9bae <blake3_servil::hash_serial+0x3be>
   b9b96:	xor    %ecx,%ecx
   b9b98:	call   *0x209df2(%rip)        # 2c3990 <_DYNAMIC+0x308>
   b9b9e:	movaps 0x1c0(%rsp),%xmm0
   b9ba6:	movaps 0x1d0(%rsp),%xmm1
   b9bae:	movaps %xmm1,0x1b0(%rsp)
   b9bb6:	movaps %xmm0,0x1a0(%rsp)
   b9bbe:	mov    0x38(%rsp),%rax
   b9bc3:	movaps 0x1a0(%rsp),%xmm0
   b9bcb:	movaps 0x1b0(%rsp),%xmm1
   b9bd3:	movups %xmm1,0x10(%rax)
   b9bd7:	movups %xmm0,(%rax)
   b9bda:	lea    -0x28(%rbp),%rsp
   b9bde:	pop    %rbx
   b9bdf:	pop    %r12
   b9be1:	pop    %r13
   b9be3:	pop    %r14
   b9be5:	pop    %r15
   b9be7:	pop    %rbp
   b9be8:	ret
   b9be9:	call   116c50 <blake3_servil::platform::not_initialized>
   b9bee:	lea    0x204183(%rip),%rcx        # 2bdd78 <__frame_dummy_init_array_entry+0x6e20>
   b9bf5:	mov    $0x40,%edx
   b9bfa:	call   238a00 <core::slice::index::slice_index_fail>
   b9bff:	lea    0x20415a(%rip),%rcx        # 2bdd60 <__frame_dummy_init_array_entry+0x6e08>
   b9c06:	mov    %rbx,%rdi
   b9c09:	mov    %r13,%rsi
   b9c0c:	mov    %r13,%rdx
   b9c0f:	call   238a00 <core::slice::index::slice_index_fail>
