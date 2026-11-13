// Printed from Lean (Lang.lean). Not written or edited by hand.
#if defined(__ELF__) && defined(__linux__)
.section .note.GNU-stack,"",%progbits
#endif
#ifdef __APPLE__
#define CALL(f) _##f
#else
#define CALL(f) f@PLT
#endif
.intel_syntax noprefix
.text
.global t_hash2
.global _t_hash2
.p2align 4
t_hash2:
_t_hash2:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov rax, rsp
    sub rsp, 5216
    and rsp, -64
    mov qword ptr [rsp + 5208], rax
    mov qword ptr [rsp + 5056], rdi
    mov qword ptr [rsp + 5064], rsi
    mov qword ptr [rsp + 5072], rdx
    mov r15, rcx
    mov qword ptr [rsp + 5080], r8
    mov qword ptr [rsp + 5088], r9
    mov rax, qword ptr [rsp + 5064]
    mov rbx, rax
    mov rax, qword ptr [rsp + 5072]
    mov rbp, rax
    mov rax, 0
    mov r12, rax
    mov rax, qword ptr [rsp + 5080]
    or rax, 4
    mov qword ptr [rsp + 5096], rax
    mov rax, 0
    mov r13, rax
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov qword ptr [rsp + 5104], rax
    mov rax, 0
    mov qword ptr [rsp + 5112], rax
    mov rax, 0
    mov qword ptr [rsp + 5120], rax
    mov rax, 0
    mov qword ptr [rsp + 5128], rax
    mov rax, 0
    mov qword ptr [rsp + 5136], rax
    mov rax, 0
    mov qword ptr [rsp + 5144], rax
    mov rax, 0
    mov qword ptr [rsp + 5152], rax
    mov rax, 0
    mov qword ptr [rsp + 5160], rax
    mov rax, 0
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
.Lt_hash2_0:
    mov rax, 1024
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hash2_1
    mov rax, rbp
    shr rax, 10
    mov r14, rax
    mov rax, 16
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hash2_2
    mov rax, 16
    mov r14, rax
.Lt_hash2_2:
    mov rax, 0
    mov r13, rax
.Lt_hash2_4:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hash2_5
    mov rax, rbx
    mov rcx, r13
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hash2_4
.Lt_hash2_5:
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hash2_6
    mov rax, qword ptr [rsp + 5080]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_avx512)
    jmp .Lt_hash2_7
.Lt_hash2_6:
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 4
    cmp rax, rcx
    jne .Lt_hash2_8
    mov rax, qword ptr [rsp + 5080]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_avx2)
    jmp .Lt_hash2_9
.Lt_hash2_8:
    mov rax, qword ptr [rsp + 5080]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_sse41)
.Lt_hash2_9:
.Lt_hash2_7:
    mov rax, rbx
    mov rcx, r14
    shl rcx, 10
    add rax, rcx
    mov rbx, rax
    mov rax, rbp
    mov rcx, r14
    shl rcx, 10
    sub rax, rcx
    mov rbp, rax
    mov rax, 0
    mov r13, rax
.Lt_hash2_10:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hash2_11
    lea rax, [rsp + 3584]
    mov rcx, r13
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5104], rax
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5120], rax
    mov rax, qword ptr [rsp + 5120]
    mov rcx, qword ptr [rsp + 5120]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov qword ptr [rsp + 5128], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5144], rax
.Lt_hash2_12:
    mov rax, qword ptr [rsp + 5128]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hash2_13
    mov rax, qword ptr [rsp + 5128]
    shr rax, 1
    mov qword ptr [rsp + 5128], rax
    mov rax, qword ptr [rsp + 5144]
    add rax, 64
    mov rcx, qword ptr [rsp + 5128]
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5152], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 5152]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hash2_14
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hash2_15
.Lt_hash2_14:
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hash2_15:
    mov rax, qword ptr [rsp + 5144]
    add rax, 64
    mov qword ptr [rsp + 5144], rax
    jmp .Lt_hash2_12
.Lt_hash2_13:
    mov rax, qword ptr [rsp + 5104]
    lea rcx, [rsp + 64]
    add rcx, 64
    mov rdx, qword ptr [rsp + 5120]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5120]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hash2_10
.Lt_hash2_11:
    mov rax, r12
    add rax, r14
    mov r12, rax
    jmp .Lt_hash2_0
.Lt_hash2_1:
    mov rax, 0
    mov qword ptr [rsp + 5168], rax
    mov rax, r12
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hash2_16
    mov rax, 1
    mov qword ptr [rsp + 5168], rax
.Lt_hash2_16:
    mov rax, qword ptr [rsp + 5168]
    mov qword ptr [rsp + 5176], rax
    mov rax, rbp
    mov rcx, 0
    cmp rax, rcx
    je .Lt_hash2_18
    mov rax, 1
    mov qword ptr [rsp + 5176], rax
.Lt_hash2_18:
    mov rax, qword ptr [rsp + 5176]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hash2_20
    mov rax, r15
    lea rcx, [rsp + 4928]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, 1
    mov qword ptr [rsp + 5184], rax
.Lt_hash2_22:
    mov rax, 64
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hash2_23
    mov rax, qword ptr [rsp + 5080]
    or rax, qword ptr [rsp + 5184]
    mov qword ptr [rsp + 5112], rax
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hash2_24
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hash2_25
.Lt_hash2_24:
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hash2_25:
    mov rax, 0
    mov qword ptr [rsp + 5184], rax
    mov rax, rbx
    add rax, 64
    mov rbx, rax
    mov rax, rbp
    sub rax, 64
    mov rbp, rax
    jmp .Lt_hash2_22
.Lt_hash2_23:
    mov rax, rbx
    mov qword ptr [rsp + 5192], rax
    mov rax, rbp
    mov rcx, 64
    cmp rax, rcx
    je .Lt_hash2_26
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 0
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 8
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 16
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 24
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 32
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 40
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 48
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 56
    mov qword ptr [rcx], rax
    mov rax, 0
    mov qword ptr [rsp + 5200], rax
.Lt_hash2_28:
    mov rax, qword ptr [rsp + 5200]
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hash2_29
    mov rax, rbx
    add rax, qword ptr [rsp + 5200]
    movzx eax, byte ptr [rax]
    lea rcx, [rsp + 4864]
    add rcx, qword ptr [rsp + 5200]
    mov byte ptr [rcx], al
    mov rax, qword ptr [rsp + 5200]
    add rax, 1
    mov qword ptr [rsp + 5200], rax
    jmp .Lt_hash2_28
.Lt_hash2_29:
    lea rax, [rsp + 4864]
    mov qword ptr [rsp + 5192], rax
.Lt_hash2_26:
    mov rax, qword ptr [rsp + 5080]
    or rax, qword ptr [rsp + 5184]
    or rax, 2
    mov qword ptr [rsp + 5112], rax
    mov rax, qword ptr [rsp + 5168]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hash2_30
    mov rax, qword ptr [rsp + 5112]
    or rax, 8
    mov qword ptr [rsp + 5112], rax
.Lt_hash2_30:
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hash2_32
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5192]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hash2_33
.Lt_hash2_32:
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5192]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hash2_33:
.Lt_hash2_20:
    mov rax, qword ptr [rsp + 5168]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hash2_34
    lea rax, [rsp + 4928]
    mov rcx, qword ptr [rsp + 5056]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    jmp .Lt_hash2_35
.Lt_hash2_34:
    mov rax, qword ptr [rsp + 5176]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hash2_36
    lea rax, [rsp + 4928]
    mov qword ptr [rsp + 5104], rax
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5120], rax
    mov rax, qword ptr [rsp + 5120]
    mov rcx, qword ptr [rsp + 5120]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov qword ptr [rsp + 5128], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5144], rax
.Lt_hash2_38:
    mov rax, qword ptr [rsp + 5128]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hash2_39
    mov rax, qword ptr [rsp + 5128]
    shr rax, 1
    mov qword ptr [rsp + 5128], rax
    mov rax, qword ptr [rsp + 5144]
    add rax, 64
    mov rcx, qword ptr [rsp + 5128]
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5152], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 5152]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hash2_40
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hash2_41
.Lt_hash2_40:
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hash2_41:
    mov rax, qword ptr [rsp + 5144]
    add rax, 64
    mov qword ptr [rsp + 5144], rax
    jmp .Lt_hash2_38
.Lt_hash2_39:
    mov rax, qword ptr [rsp + 5104]
    lea rcx, [rsp + 64]
    add rcx, 64
    mov rdx, qword ptr [rsp + 5120]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5120]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
.Lt_hash2_36:
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5120], rax
    mov rax, qword ptr [rsp + 5120]
    sub rax, 1
    mov qword ptr [rsp + 5136], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5160], rax
    mov rax, qword ptr [rsp + 5160]
    mov rcx, qword ptr [rsp + 5136]
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lt_hash2_42:
    mov rax, 0
    mov rcx, qword ptr [rsp + 5136]
    cmp rax, rcx
    jae .Lt_hash2_43
    mov rax, qword ptr [rsp + 5136]
    and rax, 1
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hash2_44
    mov rax, qword ptr [rsp + 5096]
    mov qword ptr [rsp + 5112], rax
    mov rax, qword ptr [rsp + 5136]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hash2_46
    mov rax, qword ptr [rsp + 5096]
    or rax, 8
    mov qword ptr [rsp + 5112], rax
.Lt_hash2_46:
    mov rax, qword ptr [rsp + 5160]
    lea rcx, [rsp + 4960]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rax, [rsp + 5024]
    lea rcx, [rsp + 4960]
    add rcx, 32
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r15
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hash2_48
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hash2_49
.Lt_hash2_48:
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hash2_49:
.Lt_hash2_44:
    mov rax, qword ptr [rsp + 5136]
    shr rax, 1
    mov qword ptr [rsp + 5136], rax
    mov rax, qword ptr [rsp + 5160]
    add rax, 64
    mov qword ptr [rsp + 5160], rax
    jmp .Lt_hash2_42
.Lt_hash2_43:
    lea rax, [rsp + 5024]
    mov rcx, qword ptr [rsp + 5056]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lt_hash2_35:
    mov rsp, qword ptr [rsp + 5208]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global t_hashwa
.global _t_hashwa
.p2align 4
t_hashwa:
_t_hashwa:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov rax, rsp
    sub rsp, 5744
    and rsp, -64
    mov qword ptr [rsp + 5736], rax
    mov qword ptr [rsp + 5568], rdi
    mov qword ptr [rsp + 5576], rsi
    mov qword ptr [rsp + 5584], rdx
    mov r15, rcx
    mov qword ptr [rsp + 5592], r8
    mov qword ptr [rsp + 5600], r9
    mov rax, 0
    mov qword ptr [rsp + 5608], rax
    mov rax, qword ptr [rsp + 5576]
    mov rbx, rax
    mov rax, qword ptr [rsp + 5584]
    mov rbp, rax
    mov rax, 0
    mov r12, rax
    mov rax, qword ptr [rsp + 5592]
    or rax, 4
    mov qword ptr [rsp + 5616], rax
    mov rax, 0
    mov r13, rax
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov qword ptr [rsp + 5624], rax
    mov rax, 0
    mov qword ptr [rsp + 5632], rax
    mov rax, 0
    mov qword ptr [rsp + 5640], rax
    mov rax, 0
    mov qword ptr [rsp + 5648], rax
    mov rax, 0
    mov qword ptr [rsp + 5656], rax
    mov rax, 0
    mov qword ptr [rsp + 5664], rax
    mov rax, 0
    mov qword ptr [rsp + 5672], rax
    mov rax, 0
    mov qword ptr [rsp + 5680], rax
    mov rax, 0
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_0
    mov rax, qword ptr [rsp + 5592]
    or rax, 256
    or rax, 131072
    or rax, 1073741824
    mov qword ptr [rsp + 5688], rax
.Lt_hashwa_2:
    mov rax, 32768
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwa_3
    mov rax, 0
    mov r13, rax
.Lt_hashwa_4:
    mov rax, r13
    mov rcx, 32
    cmp rax, rcx
    jae .Lt_hashwa_5
    mov rax, rbx
    mov rcx, r13
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwa_4
.Lt_hashwa_5:
    lea rdi, [rsp + 4608]
    mov rsi, 16
    mov rdx, r15
    mov rcx, r12
    mov r8, qword ptr [rsp + 5688]
    lea r9, [rsp + 3584]
    call CALL(blake3_servil_avx512_k32)
    mov rax, 0
    mov r13, rax
.Lt_hashwa_6:
    mov rax, r13
    mov rcx, 32
    cmp rax, rcx
    jae .Lt_hashwa_7
    lea rax, [rsp + 3584]
    mov rcx, r13
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5624], rax
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5640]
    mov rcx, qword ptr [rsp + 5640]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov qword ptr [rsp + 5648], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
.Lt_hashwa_8:
    mov rax, qword ptr [rsp + 5648]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hashwa_9
    mov rax, qword ptr [rsp + 5648]
    shr rax, 1
    mov qword ptr [rsp + 5648], rax
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov rcx, qword ptr [rsp + 5648]
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5672], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 5672]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_10
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwa_11
.Lt_hashwa_10:
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwa_11:
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
    jmp .Lt_hashwa_8
.Lt_hashwa_9:
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 64]
    add rcx, 64
    mov rdx, qword ptr [rsp + 5640]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5640]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwa_6
.Lt_hashwa_7:
    mov rax, rbx
    add rax, 32768
    mov rbx, rax
    mov rax, rbp
    sub rax, 32768
    mov rbp, rax
    mov rax, r12
    add rax, 32
    mov r12, rax
    jmp .Lt_hashwa_2
.Lt_hashwa_3:
.Lt_hashwa_0:
.Lt_hashwa_12:
    mov rax, 1024
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwa_13
    mov rax, rbp
    shr rax, 10
    mov r14, rax
    mov rax, 16
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hashwa_14
    mov rax, 16
    mov r14, rax
.Lt_hashwa_14:
    mov rax, 0
    mov r13, rax
.Lt_hashwa_16:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hashwa_17
    mov rax, rbx
    mov rcx, r13
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwa_16
.Lt_hashwa_17:
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_18
    mov rax, qword ptr [rsp + 5592]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_avx512)
    jmp .Lt_hashwa_19
.Lt_hashwa_18:
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 4
    cmp rax, rcx
    jne .Lt_hashwa_20
    mov rax, qword ptr [rsp + 5592]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_avx2)
    jmp .Lt_hashwa_21
.Lt_hashwa_20:
    mov rax, qword ptr [rsp + 5592]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_sse41)
.Lt_hashwa_21:
.Lt_hashwa_19:
    mov rax, rbx
    mov rcx, r14
    shl rcx, 10
    add rax, rcx
    mov rbx, rax
    mov rax, rbp
    mov rcx, r14
    shl rcx, 10
    sub rax, rcx
    mov rbp, rax
    mov rax, 0
    mov r13, rax
.Lt_hashwa_22:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hashwa_23
    lea rax, [rsp + 3584]
    mov rcx, r13
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5624], rax
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5640]
    mov rcx, qword ptr [rsp + 5640]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov qword ptr [rsp + 5648], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
.Lt_hashwa_24:
    mov rax, qword ptr [rsp + 5648]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hashwa_25
    mov rax, qword ptr [rsp + 5648]
    shr rax, 1
    mov qword ptr [rsp + 5648], rax
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov rcx, qword ptr [rsp + 5648]
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5672], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 5672]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_26
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwa_27
.Lt_hashwa_26:
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwa_27:
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
    jmp .Lt_hashwa_24
.Lt_hashwa_25:
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 64]
    add rcx, 64
    mov rdx, qword ptr [rsp + 5640]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5640]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwa_22
.Lt_hashwa_23:
    mov rax, r12
    add rax, r14
    mov r12, rax
    jmp .Lt_hashwa_12
.Lt_hashwa_13:
    mov rax, 0
    mov qword ptr [rsp + 5696], rax
    mov rax, r12
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hashwa_28
    mov rax, 1
    mov qword ptr [rsp + 5696], rax
.Lt_hashwa_28:
    mov rax, qword ptr [rsp + 5696]
    mov qword ptr [rsp + 5704], rax
    mov rax, rbp
    mov rcx, 0
    cmp rax, rcx
    je .Lt_hashwa_30
    mov rax, 1
    mov qword ptr [rsp + 5704], rax
.Lt_hashwa_30:
    mov rax, qword ptr [rsp + 5704]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwa_32
    mov rax, r15
    lea rcx, [rsp + 4928]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, 1
    mov qword ptr [rsp + 5712], rax
.Lt_hashwa_34:
    mov rax, 64
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwa_35
    mov rax, qword ptr [rsp + 5592]
    or rax, qword ptr [rsp + 5712]
    mov qword ptr [rsp + 5632], rax
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_36
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwa_37
.Lt_hashwa_36:
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwa_37:
    mov rax, 0
    mov qword ptr [rsp + 5712], rax
    mov rax, rbx
    add rax, 64
    mov rbx, rax
    mov rax, rbp
    sub rax, 64
    mov rbp, rax
    jmp .Lt_hashwa_34
.Lt_hashwa_35:
    mov rax, rbx
    mov qword ptr [rsp + 5720], rax
    mov rax, rbp
    mov rcx, 64
    cmp rax, rcx
    je .Lt_hashwa_38
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 0
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 8
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 16
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 24
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 32
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 40
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 48
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 56
    mov qword ptr [rcx], rax
    mov rax, 0
    mov qword ptr [rsp + 5728], rax
.Lt_hashwa_40:
    mov rax, qword ptr [rsp + 5728]
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwa_41
    mov rax, rbx
    add rax, qword ptr [rsp + 5728]
    movzx eax, byte ptr [rax]
    lea rcx, [rsp + 4864]
    add rcx, qword ptr [rsp + 5728]
    mov byte ptr [rcx], al
    mov rax, qword ptr [rsp + 5728]
    add rax, 1
    mov qword ptr [rsp + 5728], rax
    jmp .Lt_hashwa_40
.Lt_hashwa_41:
    lea rax, [rsp + 4864]
    mov qword ptr [rsp + 5720], rax
.Lt_hashwa_38:
    mov rax, qword ptr [rsp + 5592]
    or rax, qword ptr [rsp + 5712]
    or rax, 2
    mov qword ptr [rsp + 5632], rax
    mov rax, qword ptr [rsp + 5696]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwa_42
    mov rax, qword ptr [rsp + 5632]
    or rax, 8
    mov qword ptr [rsp + 5632], rax
.Lt_hashwa_42:
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_44
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5720]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwa_45
.Lt_hashwa_44:
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5720]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwa_45:
.Lt_hashwa_32:
    mov rax, qword ptr [rsp + 5696]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwa_46
    lea rax, [rsp + 4928]
    mov rcx, qword ptr [rsp + 5568]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    jmp .Lt_hashwa_47
.Lt_hashwa_46:
    mov rax, qword ptr [rsp + 5704]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwa_48
    lea rax, [rsp + 4928]
    mov qword ptr [rsp + 5624], rax
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5640]
    mov rcx, qword ptr [rsp + 5640]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov qword ptr [rsp + 5648], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
.Lt_hashwa_50:
    mov rax, qword ptr [rsp + 5648]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hashwa_51
    mov rax, qword ptr [rsp + 5648]
    shr rax, 1
    mov qword ptr [rsp + 5648], rax
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov rcx, qword ptr [rsp + 5648]
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5672], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 5672]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_52
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwa_53
.Lt_hashwa_52:
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwa_53:
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
    jmp .Lt_hashwa_50
.Lt_hashwa_51:
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 64]
    add rcx, 64
    mov rdx, qword ptr [rsp + 5640]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5640]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
.Lt_hashwa_48:
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5640]
    sub rax, 1
    mov qword ptr [rsp + 5656], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5680], rax
    mov rax, qword ptr [rsp + 5680]
    mov rcx, qword ptr [rsp + 5656]
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lt_hashwa_54:
    mov rax, 0
    mov rcx, qword ptr [rsp + 5656]
    cmp rax, rcx
    jae .Lt_hashwa_55
    mov rax, qword ptr [rsp + 5656]
    and rax, 1
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwa_56
    mov rax, qword ptr [rsp + 5616]
    mov qword ptr [rsp + 5632], rax
    mov rax, qword ptr [rsp + 5656]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwa_58
    mov rax, qword ptr [rsp + 5616]
    or rax, 8
    mov qword ptr [rsp + 5632], rax
.Lt_hashwa_58:
    mov rax, qword ptr [rsp + 5680]
    lea rcx, [rsp + 4960]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rax, [rsp + 5024]
    lea rcx, [rsp + 4960]
    add rcx, 32
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r15
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwa_60
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwa_61
.Lt_hashwa_60:
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwa_61:
.Lt_hashwa_56:
    mov rax, qword ptr [rsp + 5656]
    shr rax, 1
    mov qword ptr [rsp + 5656], rax
    mov rax, qword ptr [rsp + 5680]
    add rax, 64
    mov qword ptr [rsp + 5680], rax
    jmp .Lt_hashwa_54
.Lt_hashwa_55:
    lea rax, [rsp + 5024]
    mov rcx, qword ptr [rsp + 5568]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lt_hashwa_47:
    mov rsp, qword ptr [rsp + 5736]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global t_hashwb
.global _t_hashwb
.p2align 4
t_hashwb:
_t_hashwb:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov rax, rsp
    sub rsp, 5760
    and rsp, -64
    mov qword ptr [rsp + 5744], rax
    mov qword ptr [rsp + 5568], rdi
    mov qword ptr [rsp + 5576], rsi
    mov qword ptr [rsp + 5584], rdx
    mov r15, rcx
    mov qword ptr [rsp + 5592], r8
    mov qword ptr [rsp + 5600], r9
    mov rax, 0
    mov qword ptr [rsp + 5608], rax
    mov rax, qword ptr [rsp + 5576]
    mov rbx, rax
    mov rax, qword ptr [rsp + 5584]
    mov rbp, rax
    mov rax, 0
    mov r12, rax
    mov rax, qword ptr [rsp + 5592]
    or rax, 4
    mov qword ptr [rsp + 5616], rax
    mov rax, 0
    mov r13, rax
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov qword ptr [rsp + 5624], rax
    mov rax, 0
    mov qword ptr [rsp + 5632], rax
    mov rax, 0
    mov qword ptr [rsp + 5640], rax
    mov rax, 0
    mov qword ptr [rsp + 5648], rax
    mov rax, 0
    mov qword ptr [rsp + 5656], rax
    mov rax, 0
    mov qword ptr [rsp + 5664], rax
    mov rax, 0
    mov qword ptr [rsp + 5672], rax
    mov rax, 0
    mov qword ptr [rsp + 5680], rax
    mov rax, 0
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_0
    mov rax, qword ptr [rsp + 5592]
    or rax, 256
    or rax, 131072
    or rax, 1073741824
    mov qword ptr [rsp + 5688], rax
    mov rax, qword ptr [rsp + 5616]
    or rax, 1073741824
    mov qword ptr [rsp + 5696], rax
.Lt_hashwb_2:
    mov rax, 32768
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwb_3
    mov rax, 0
    mov r13, rax
.Lt_hashwb_4:
    mov rax, r13
    mov rcx, 32
    cmp rax, rcx
    jae .Lt_hashwb_5
    mov rax, rbx
    mov rcx, r13
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_4
.Lt_hashwb_5:
    lea rdi, [rsp + 4608]
    mov rsi, 16
    mov rdx, r15
    mov rcx, r12
    mov r8, qword ptr [rsp + 5688]
    lea r9, [rsp + 3584]
    call CALL(blake3_servil_avx512_k32)
    mov rax, 0
    mov r13, rax
.Lt_hashwb_6:
    mov rax, r13
    mov rcx, 16
    cmp rax, rcx
    jae .Lt_hashwb_7
    lea rax, [rsp + 3584]
    mov rcx, r13
    and rcx, 15
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_6
.Lt_hashwb_7:
    lea rdi, [rsp + 4608]
    mov rsi, 1
    mov rdx, r15
    mov rcx, 0
    mov r8, qword ptr [rsp + 5696]
    lea r9, [rsp + 5056]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov r13, rax
.Lt_hashwb_8:
    mov rax, r13
    mov rcx, 16
    cmp rax, rcx
    jae .Lt_hashwb_9
    lea rax, [rsp + 5056]
    mov rcx, r13
    and rcx, 7
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_8
.Lt_hashwb_9:
    lea rdi, [rsp + 4608]
    mov rsi, 1
    mov rdx, r15
    mov rcx, 0
    mov r8, qword ptr [rsp + 5696]
    lea r9, [rsp + 3584]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov r13, rax
.Lt_hashwb_10:
    mov rax, r13
    mov rcx, 16
    cmp rax, rcx
    jae .Lt_hashwb_11
    lea rax, [rsp + 3584]
    mov rcx, r13
    and rcx, 3
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_10
.Lt_hashwb_11:
    lea rdi, [rsp + 4608]
    mov rsi, 1
    mov rdx, r15
    mov rcx, 0
    mov r8, qword ptr [rsp + 5696]
    lea r9, [rsp + 5056]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov r13, rax
.Lt_hashwb_12:
    mov rax, r13
    mov rcx, 16
    cmp rax, rcx
    jae .Lt_hashwb_13
    lea rax, [rsp + 5056]
    mov rcx, r13
    and rcx, 1
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_12
.Lt_hashwb_13:
    lea rdi, [rsp + 4608]
    mov rsi, 1
    mov rdx, r15
    mov rcx, 0
    mov r8, qword ptr [rsp + 5696]
    lea r9, [rsp + 3584]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov r13, rax
.Lt_hashwb_14:
    mov rax, r13
    mov rcx, 16
    cmp rax, rcx
    jae .Lt_hashwb_15
    lea rax, [rsp + 3584]
    mov rcx, r13
    and rcx, 0
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_14
.Lt_hashwb_15:
    lea rdi, [rsp + 4608]
    mov rsi, 1
    mov rdx, r15
    mov rcx, 0
    mov r8, qword ptr [rsp + 5696]
    lea r9, [rsp + 5056]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 5056]
    mov qword ptr [rsp + 5624], rax
    mov rax, r12
    shr rax, 5
    mov qword ptr [rsp + 5648], rax
    lea rax, [rsp + 64]
    add rax, 64
    add rax, 320
    mov qword ptr [rsp + 5664], rax
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lt_hashwb_16:
    mov rax, qword ptr [rsp + 5648]
    and rax, 1
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_17
    mov rax, qword ptr [rsp + 5664]
    lea rcx, [rsp + 4960]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rax, [rsp + 5024]
    lea rcx, [rsp + 4960]
    add rcx, 32
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r15
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_18
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwb_19
.Lt_hashwb_18:
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwb_19:
    mov rax, qword ptr [rsp + 5648]
    shr rax, 1
    mov qword ptr [rsp + 5648], rax
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
    jmp .Lt_hashwb_16
.Lt_hashwb_17:
    lea rax, [rsp + 5024]
    mov rcx, qword ptr [rsp + 5664]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, rbx
    add rax, 32768
    mov rbx, rax
    mov rax, rbp
    sub rax, 32768
    mov rbp, rax
    mov rax, r12
    add rax, 32
    mov r12, rax
    jmp .Lt_hashwb_2
.Lt_hashwb_3:
    mov rax, r12
    mov rcx, 0
    cmp rax, rcx
    je .Lt_hashwb_20
    mov rax, r12
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, 1
    mov qword ptr [rsp + 5608], rax
.Lt_hashwb_20:
.Lt_hashwb_0:
.Lt_hashwb_22:
    mov rax, 1024
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwb_23
    mov rax, rbp
    shr rax, 10
    mov r14, rax
    mov rax, 16
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hashwb_24
    mov rax, 16
    mov r14, rax
.Lt_hashwb_24:
    mov rax, 0
    mov r13, rax
.Lt_hashwb_26:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hashwb_27
    mov rax, rbx
    mov rcx, r13
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 4608]
    mov rdx, r13
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_26
.Lt_hashwb_27:
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_28
    mov rax, qword ptr [rsp + 5592]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_avx512)
    jmp .Lt_hashwb_29
.Lt_hashwb_28:
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 4
    cmp rax, rcx
    jne .Lt_hashwb_30
    mov rax, qword ptr [rsp + 5592]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_avx2)
    jmp .Lt_hashwb_31
.Lt_hashwb_30:
    mov rax, qword ptr [rsp + 5592]
    mov qword ptr [rsp + 0], rax
    mov rax, 1
    mov qword ptr [rsp + 8], rax
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    lea rax, [rsp + 3584]
    mov qword ptr [rsp + 24], rax
    lea rdi, [rsp + 4608]
    mov rsi, r14
    mov rdx, 16
    mov rcx, r15
    mov r8, r12
    mov r9, 1
    call CALL(blake3_servil_hash_many_sse41)
.Lt_hashwb_31:
.Lt_hashwb_29:
    mov rax, rbx
    mov rcx, r14
    shl rcx, 10
    add rax, rcx
    mov rbx, rax
    mov rax, rbp
    mov rcx, r14
    shl rcx, 10
    sub rax, rcx
    mov rbp, rax
    mov rax, 0
    mov r13, rax
.Lt_hashwb_32:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lt_hashwb_33
    lea rax, [rsp + 3584]
    mov rcx, r13
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5624], rax
    mov rax, qword ptr [rsp + 5608]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_34
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 64]
    add rcx, 64
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5640]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, 0
    mov qword ptr [rsp + 5608], rax
    jmp .Lt_hashwb_35
.Lt_hashwb_34:
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5640]
    mov rcx, qword ptr [rsp + 5640]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov qword ptr [rsp + 5648], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
.Lt_hashwb_36:
    mov rax, qword ptr [rsp + 5648]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hashwb_37
    mov rax, qword ptr [rsp + 5648]
    shr rax, 1
    mov qword ptr [rsp + 5648], rax
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov rcx, qword ptr [rsp + 5648]
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5672], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 5672]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_38
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwb_39
.Lt_hashwb_38:
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwb_39:
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
    jmp .Lt_hashwb_36
.Lt_hashwb_37:
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 64]
    add rcx, 64
    mov rdx, qword ptr [rsp + 5640]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5640]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
.Lt_hashwb_35:
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lt_hashwb_32
.Lt_hashwb_33:
    mov rax, r12
    add rax, r14
    mov r12, rax
    jmp .Lt_hashwb_22
.Lt_hashwb_23:
    mov rax, 0
    mov qword ptr [rsp + 5704], rax
    mov rax, r12
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hashwb_40
    mov rax, 1
    mov qword ptr [rsp + 5704], rax
.Lt_hashwb_40:
    mov rax, qword ptr [rsp + 5704]
    mov qword ptr [rsp + 5712], rax
    mov rax, rbp
    mov rcx, 0
    cmp rax, rcx
    je .Lt_hashwb_42
    mov rax, 1
    mov qword ptr [rsp + 5712], rax
.Lt_hashwb_42:
    mov rax, qword ptr [rsp + 5712]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_44
    mov rax, r15
    lea rcx, [rsp + 4928]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, 1
    mov qword ptr [rsp + 5720], rax
.Lt_hashwb_46:
    mov rax, 64
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwb_47
    mov rax, qword ptr [rsp + 5592]
    or rax, qword ptr [rsp + 5720]
    mov qword ptr [rsp + 5632], rax
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_48
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwb_49
.Lt_hashwb_48:
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwb_49:
    mov rax, 0
    mov qword ptr [rsp + 5720], rax
    mov rax, rbx
    add rax, 64
    mov rbx, rax
    mov rax, rbp
    sub rax, 64
    mov rbp, rax
    jmp .Lt_hashwb_46
.Lt_hashwb_47:
    mov rax, rbx
    mov qword ptr [rsp + 5728], rax
    mov rax, rbp
    mov rcx, 64
    cmp rax, rcx
    je .Lt_hashwb_50
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 0
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 8
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 16
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 24
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 32
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 40
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 48
    mov qword ptr [rcx], rax
    mov rax, 0
    lea rcx, [rsp + 4864]
    add rcx, 56
    mov qword ptr [rcx], rax
    mov rax, 0
    mov qword ptr [rsp + 5736], rax
.Lt_hashwb_52:
    mov rax, qword ptr [rsp + 5736]
    mov rcx, rbp
    cmp rax, rcx
    jae .Lt_hashwb_53
    mov rax, rbx
    add rax, qword ptr [rsp + 5736]
    movzx eax, byte ptr [rax]
    lea rcx, [rsp + 4864]
    add rcx, qword ptr [rsp + 5736]
    mov byte ptr [rcx], al
    mov rax, qword ptr [rsp + 5736]
    add rax, 1
    mov qword ptr [rsp + 5736], rax
    jmp .Lt_hashwb_52
.Lt_hashwb_53:
    lea rax, [rsp + 4864]
    mov qword ptr [rsp + 5728], rax
.Lt_hashwb_50:
    mov rax, qword ptr [rsp + 5592]
    or rax, qword ptr [rsp + 5720]
    or rax, 2
    mov qword ptr [rsp + 5632], rax
    mov rax, qword ptr [rsp + 5704]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_54
    mov rax, qword ptr [rsp + 5632]
    or rax, 8
    mov qword ptr [rsp + 5632], rax
.Lt_hashwb_54:
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_56
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5728]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwb_57
.Lt_hashwb_56:
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5728]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwb_57:
.Lt_hashwb_44:
    mov rax, qword ptr [rsp + 5704]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_58
    lea rax, [rsp + 4928]
    mov rcx, qword ptr [rsp + 5568]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    jmp .Lt_hashwb_59
.Lt_hashwb_58:
    mov rax, qword ptr [rsp + 5712]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_60
    lea rax, [rsp + 4928]
    mov qword ptr [rsp + 5624], rax
    mov rax, qword ptr [rsp + 5608]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_62
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 64]
    add rcx, 64
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5640]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
    mov rax, 0
    mov qword ptr [rsp + 5608], rax
    jmp .Lt_hashwb_63
.Lt_hashwb_62:
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5640]
    mov rcx, qword ptr [rsp + 5640]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov qword ptr [rsp + 5648], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
.Lt_hashwb_64:
    mov rax, qword ptr [rsp + 5648]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lt_hashwb_65
    mov rax, qword ptr [rsp + 5648]
    shr rax, 1
    mov qword ptr [rsp + 5648], rax
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov rcx, qword ptr [rsp + 5648]
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 5672], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 5672]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_66
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwb_67
.Lt_hashwb_66:
    mov rdi, qword ptr [rsp + 5672]
    mov rsi, qword ptr [rsp + 5664]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5616]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwb_67:
    mov rax, qword ptr [rsp + 5664]
    add rax, 64
    mov qword ptr [rsp + 5664], rax
    jmp .Lt_hashwb_64
.Lt_hashwb_65:
    mov rax, qword ptr [rsp + 5624]
    lea rcx, [rsp + 64]
    add rcx, 64
    mov rdx, qword ptr [rsp + 5640]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5640]
    add rax, 1
    lea rcx, [rsp + 64]
    mov qword ptr [rcx], rax
.Lt_hashwb_63:
.Lt_hashwb_60:
    lea rax, [rsp + 64]
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 5640], rax
    mov rax, qword ptr [rsp + 5640]
    sub rax, 1
    mov qword ptr [rsp + 5656], rax
    lea rax, [rsp + 64]
    add rax, 64
    mov qword ptr [rsp + 5680], rax
    mov rax, qword ptr [rsp + 5680]
    mov rcx, qword ptr [rsp + 5656]
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lt_hashwb_68:
    mov rax, 0
    mov rcx, qword ptr [rsp + 5656]
    cmp rax, rcx
    jae .Lt_hashwb_69
    mov rax, qword ptr [rsp + 5656]
    and rax, 1
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_70
    mov rax, qword ptr [rsp + 5616]
    mov qword ptr [rsp + 5632], rax
    mov rax, qword ptr [rsp + 5656]
    mov rcx, 1
    cmp rax, rcx
    jne .Lt_hashwb_72
    mov rax, qword ptr [rsp + 5616]
    or rax, 8
    mov qword ptr [rsp + 5632], rax
.Lt_hashwb_72:
    mov rax, qword ptr [rsp + 5680]
    lea rcx, [rsp + 4960]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rax, [rsp + 5024]
    lea rcx, [rsp + 4960]
    add rcx, 32
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r15
    lea rcx, [rsp + 5024]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 5600]
    mov rcx, 5
    cmp rax, rcx
    jne .Lt_hashwb_74
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lt_hashwb_75
.Lt_hashwb_74:
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5632]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lt_hashwb_75:
.Lt_hashwb_70:
    mov rax, qword ptr [rsp + 5656]
    shr rax, 1
    mov qword ptr [rsp + 5656], rax
    mov rax, qword ptr [rsp + 5680]
    add rax, 64
    mov qword ptr [rsp + 5680], rax
    jmp .Lt_hashwb_68
.Lt_hashwb_69:
    lea rax, [rsp + 5024]
    mov rcx, qword ptr [rsp + 5568]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lt_hashwb_59:
    mov rsp, qword ptr [rsp + 5744]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
