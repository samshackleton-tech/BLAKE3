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
.global b3l_ladd
.global _b3l_ladd
.p2align 4
b3l_ladd:
_b3l_ladd:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov r12, rdi
    mov r13, rsi
    mov qword ptr [rsp + 0], rdx
    mov r14, rcx
    mov qword ptr [rsp + 8], r8
    mov rax, qword ptr [rsp + 0]
    or rax, 4
    mov qword ptr [rsp + 16], rax
    mov rax, r12
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 24], rax
    mov rax, qword ptr [rsp + 24]
    mov rcx, qword ptr [rsp + 24]
    sub rcx, 1
    shr rcx, 63
    or rax, rcx
    mov rbx, rax
    mov rax, r12
    add rax, 64
    mov rbp, rax
.Lb3l_ladd_0:
    mov rax, rbx
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_ladd_1
    mov rax, rbx
    shr rax, 1
    mov rbx, rax
    mov rax, rbp
    add rax, 64
    mov rcx, rbx
    add rcx, 1
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    mov r15, rax
    mov rax, r13
    mov rcx, r15
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r14
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_ladd_2
    mov rdi, r15
    mov rsi, rbp
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 16]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_ladd_3
.Lb3l_ladd_2:
    mov rdi, r15
    mov rsi, rbp
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 16]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_ladd_3:
    mov rax, rbp
    add rax, 64
    mov rbp, rax
    jmp .Lb3l_ladd_0
.Lb3l_ladd_1:
    mov rax, qword ptr [rsp + 8]
    mov rcx, r12
    add rcx, 64
    mov rdx, qword ptr [rsp + 24]
    and rdx, 1
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 24]
    add rax, 1
    mov rcx, r12
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 24]
    add rax, 1
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_lroot
.global _b3l_lroot
.p2align 4
b3l_lroot:
_b3l_lroot:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 136
    mov qword ptr [rsp + 96], rdi
    mov r13, rsi
    mov r14, rdx
    mov qword ptr [rsp + 104], rcx
    mov r15, r8
    mov qword ptr [rsp + 112], r9
    mov rax, qword ptr [rsp + 104]
    or rax, 4
    mov qword ptr [rsp + 120], rax
    mov rax, r13
    mov rax, qword ptr [rax]
    sub rax, 1
    mov rbx, rax
    mov rax, r13
    add rax, 64
    mov rbp, rax
    mov rax, rbp
    mov rcx, rbx
    and rcx, 1
    shl rcx, 5
    add rax, rcx
    lea rcx, [rsp + 64]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lb3l_lroot_0:
    mov rax, 0
    mov rcx, rbx
    cmp rax, rcx
    jae .Lb3l_lroot_1
    mov rax, rbx
    and rax, 1
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_lroot_2
    mov rax, qword ptr [rsp + 120]
    mov r12, rax
    mov rax, rbx
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_lroot_4
    mov rax, qword ptr [rsp + 120]
    or rax, qword ptr [rsp + 112]
    mov r12, rax
.Lb3l_lroot_4:
    mov rax, rbp
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rax, [rsp + 64]
    lea rcx, [rsp + 0]
    add rcx, 32
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r14
    lea rcx, [rsp + 64]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_lroot_6
    lea rdi, [rsp + 64]
    lea rsi, [rsp + 0]
    mov rdx, 64
    mov rcx, 0
    mov r8, r12
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_lroot_7
.Lb3l_lroot_6:
    lea rdi, [rsp + 64]
    lea rsi, [rsp + 0]
    mov rdx, 64
    mov rcx, 0
    mov r8, r12
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_lroot_7:
.Lb3l_lroot_2:
    mov rax, rbx
    shr rax, 1
    mov rbx, rax
    mov rax, rbp
    add rax, 64
    mov rbp, rax
    jmp .Lb3l_lroot_0
.Lb3l_lroot_1:
    lea rax, [rsp + 64]
    mov rcx, qword ptr [rsp + 96]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    add rsp, 136
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_pad
.global _b3l_pad
.p2align 4
b3l_pad:
_b3l_pad:
    push rbx
    push rbp
    push r12
    push r13
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov rax, 64
    mov r13, rax
.Lb3l_pad_0:
    mov rax, 0
    mov rcx, r13
    cmp rax, rcx
    jae .Lb3l_pad_1
    mov rax, r13
    sub rax, 1
    mov r13, rax
    mov rax, r13
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_pad_2
    mov rax, rbp
    add rax, r13
    movzx eax, byte ptr [rax]
    mov rcx, rbx
    add rcx, r13
    mov byte ptr [rcx], al
    jmp .Lb3l_pad_3
.Lb3l_pad_2:
    mov rax, 0
    mov rcx, rbx
    add rcx, r13
    mov byte ptr [rcx], al
.Lb3l_pad_3:
    jmp .Lb3l_pad_0
.Lb3l_pad_1:
    add rsp, 8
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_chunk_node
.global _b3l_chunk_node
.p2align 4
b3l_chunk_node:
_b3l_chunk_node:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov r13, rdi
    mov qword ptr [rsp + 0], rsi
    mov qword ptr [rsp + 8], rdx
    mov r14, rcx
    mov qword ptr [rsp + 16], r8
    mov r15, r9
    mov rax, 1
    mov r12, rax
    mov rax, qword ptr [rsp + 0]
    mov rbx, rax
    mov rax, qword ptr [rsp + 8]
    mov rbp, rax
.Lb3l_chunk_node_0:
    mov rax, 64
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_chunk_node_1
    mov rax, qword ptr [rsp + 16]
    or rax, r12
    mov qword ptr [rsp + 24], rax
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_chunk_node_2
    mov rdi, r13
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r14
    mov r8, qword ptr [rsp + 24]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_chunk_node_3
.Lb3l_chunk_node_2:
    mov rdi, r13
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r14
    mov r8, qword ptr [rsp + 24]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_chunk_node_3:
    mov rax, 0
    mov r12, rax
    mov rax, rbx
    add rax, 64
    mov rbx, rax
    mov rax, rbp
    sub rax, 64
    mov rbp, rax
    jmp .Lb3l_chunk_node_0
.Lb3l_chunk_node_1:
    mov rax, r13
    add rax, 32
    mov qword ptr [rsp + 32], rax
    mov rdi, qword ptr [rsp + 32]
    mov rsi, rbx
    mov rdx, rbp
    call CALL(b3l_pad)
    mov rax, r14
    mov rcx, r13
    add rcx, 96
    mov qword ptr [rcx], rax
    mov rax, rbp
    mov rcx, r13
    add rcx, 104
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 16]
    or rax, r12
    or rax, 2
    mov rcx, r13
    add rcx, 112
    mov qword ptr [rcx], rax
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_node_out
.global _b3l_node_out
.p2align 4
b3l_node_out:
_b3l_node_out:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 24
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, rbp
    add rax, 32
    mov r14, rax
    mov rax, rbp
    add rax, 104
    mov rax, qword ptr [rax]
    mov r15, rax
    mov rax, rbp
    add rax, 96
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 0], rax
    mov rax, rbp
    add rax, 112
    mov rax, qword ptr [rax]
    or rax, r12
    mov qword ptr [rsp + 8], rax
    mov rax, rbp
    mov rcx, rbx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r13
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_node_out_0
    mov rdi, rbx
    mov rsi, r14
    mov rdx, r15
    mov rcx, qword ptr [rsp + 0]
    mov r8, qword ptr [rsp + 8]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_node_out_1
.Lb3l_node_out_0:
    mov rdi, rbx
    mov rsi, r14
    mov rdx, r15
    mov rcx, qword ptr [rsp + 0]
    mov r8, qword ptr [rsp + 8]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_node_out_1:
    add rsp, 24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_hashl
.global _b3l_hashl
.p2align 4
b3l_hashl:
_b3l_hashl:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 3704
    mov qword ptr [rsp + 3680], rdi
    mov qword ptr [rsp + 3688], rsi
    mov qword ptr [rsp + 3696], rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, 0
    lea rcx, [rsp + 0]
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 3688]
    mov rbx, rax
    mov rax, qword ptr [rsp + 3696]
    mov rbp, rax
    mov rax, 0
    mov r12, rax
.Lb3l_hashl_0:
    mov rax, 1024
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_hashl_1
    mov rax, r13
    lea rcx, [rsp + 3520]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 3520]
    mov rsi, rbx
    mov rdx, 1024
    mov rcx, r12
    mov r8, r14
    mov r9, r15
    call CALL(b3l_chunk_node)
    lea rdi, [rsp + 3648]
    lea rsi, [rsp + 3520]
    mov rdx, 0
    mov rcx, r15
    call CALL(b3l_node_out)
    lea rdi, [rsp + 0]
    mov rsi, r13
    mov rdx, r14
    mov rcx, r15
    lea r8, [rsp + 3648]
    call CALL(b3l_ladd)
    mov rax, rbx
    add rax, 1024
    mov rbx, rax
    mov rax, rbp
    sub rax, 1024
    mov rbp, rax
    mov rax, r12
    add rax, 1
    mov r12, rax
    jmp .Lb3l_hashl_0
.Lb3l_hashl_1:
    mov rax, r13
    lea rcx, [rsp + 3520]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 3520]
    mov rsi, rbx
    mov rdx, rbp
    mov rcx, r12
    mov r8, r14
    mov r9, r15
    call CALL(b3l_chunk_node)
    mov rax, r12
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_hashl_2
    mov rdi, qword ptr [rsp + 3680]
    lea rsi, [rsp + 3520]
    mov rdx, 8
    mov rcx, r15
    call CALL(b3l_node_out)
    jmp .Lb3l_hashl_3
.Lb3l_hashl_2:
    lea rdi, [rsp + 3648]
    lea rsi, [rsp + 3520]
    mov rdx, 0
    mov rcx, r15
    call CALL(b3l_node_out)
    lea rdi, [rsp + 0]
    mov rsi, r13
    mov rdx, r14
    mov rcx, r15
    lea r8, [rsp + 3648]
    call CALL(b3l_ladd)
    mov rdi, qword ptr [rsp + 3680]
    lea rsi, [rsp + 0]
    mov rdx, r13
    mov rcx, r14
    mov r8, r15
    mov r9, 8
    call CALL(b3l_lroot)
.Lb3l_hashl_3:
    add rsp, 3704
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_fillp
.global _b3l_fillp
.p2align 4
b3l_fillp:
_b3l_fillp:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, 0
    mov r14, rax
    mov rax, rbp
    mov r15, rax
.Lb3l_fillp_0:
    mov rax, r14
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_fillp_1
    mov rax, r14
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_fillp_2
    mov rax, r15
    mov rcx, rbx
    mov rdx, r14
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_fillp_3
.Lb3l_fillp_2:
    mov rax, rbp
    mov rcx, rbx
    mov rdx, r14
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_fillp_3:
    mov rax, r15
    add rax, r13
    mov r15, rax
    mov rax, r14
    add rax, 1
    mov r14, rax
    jmp .Lb3l_fillp_0
.Lb3l_fillp_1:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_p16s
.global _b3l_p16s
.p2align 4
b3l_p16s:
_b3l_p16s:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, r14
    and rax, 255
    mov qword ptr [rsp + 0], rax
    mov rax, 0
    mov qword ptr [rsp + 8], rax
    mov rax, 0
    mov qword ptr [rsp + 16], rax
    mov rax, 0
    mov qword ptr [rsp + 24], rax
.Lb3l_p16s_0:
    mov rax, qword ptr [rsp + 8]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_p16s_1
    mov rax, rbx
    mov rcx, qword ptr [rsp + 8]
    shl rcx, 3
    add rax, rcx
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 16], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 8]
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 24], rax
    mov rax, r12
    mov rcx, qword ptr [rsp + 24]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rdi, qword ptr [rsp + 24]
    mov rsi, qword ptr [rsp + 16]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 0]
    call CALL(blake3_servil_compress_in_place_avx512)
    mov rax, qword ptr [rsp + 8]
    add rax, 1
    mov qword ptr [rsp + 8], rax
    jmp .Lb3l_p16s_0
.Lb3l_p16s_1:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_k32s
.global _b3l_k32s
.p2align 4
b3l_k32s:
_b3l_k32s:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 168
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, r14
    and rax, 255
    mov qword ptr [rsp + 120], rax
    mov rax, 0
    mov qword ptr [rsp + 128], rax
    mov rax, 0
    mov qword ptr [rsp + 136], rax
    mov rax, 0
    mov qword ptr [rsp + 144], rax
    mov rax, 0
    mov qword ptr [rsp + 152], rax
.Lb3l_k32s_0:
    mov rax, qword ptr [rsp + 128]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_k32s_1
    mov rax, rbx
    mov rcx, qword ptr [rsp + 128]
    shl rcx, 3
    add rax, rcx
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 136], rax
    mov rax, r15
    mov rcx, qword ptr [rsp + 128]
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 144], rax
    mov rax, r13
    add rax, qword ptr [rsp + 128]
    mov qword ptr [rsp + 152], rax
    mov rax, r12
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 0]
    mov rsi, qword ptr [rsp + 136]
    mov rdx, 1024
    mov rcx, qword ptr [rsp + 152]
    mov r8, qword ptr [rsp + 120]
    mov r9, 5
    call CALL(b3l_chunk_node)
    mov rdi, qword ptr [rsp + 144]
    lea rsi, [rsp + 0]
    mov rdx, 0
    mov rcx, 5
    call CALL(b3l_node_out)
    mov rax, qword ptr [rsp + 128]
    add rax, 1
    mov qword ptr [rsp + 128], rax
    jmp .Lb3l_k32s_0
.Lb3l_k32s_1:
    add rsp, 168
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_tree32
.global _b3l_tree32
.p2align 4
b3l_tree32:
_b3l_tree32:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    sub rsp, 1280
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, r13
    or rax, 1073741828
    mov r14, rax
    lea rdi, [rsp + 0]
    mov rsi, rbp
    mov rdx, 16
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 256]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 256]
    mov rdx, 8
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 768]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 768]
    mov rdx, 4
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 256]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 256]
    mov rdx, 2
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 768]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 768]
    mov rdx, 1
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    mov r9, rbx
    call CALL(blake3_servil_avx512_p16)
    add rsp, 1280
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_wide
.global _b3l_wide
.p2align 4
b3l_wide:
_b3l_wide:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 1816
    mov r13, rdi
    mov qword ptr [rsp + 1792], rsi
    mov qword ptr [rsp + 1800], rdx
    mov r14, rcx
    mov r15, r8
    mov rax, r15
    or rax, 1073873152
    mov qword ptr [rsp + 1808], rax
    mov rax, 0
    mov rcx, r13
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 1792]
    mov rbx, rax
    mov rax, qword ptr [rsp + 1800]
    mov rbp, rax
    mov rax, 0
    mov r12, rax
.Lb3l_wide_0:
    mov rax, 32768
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_wide_1
    lea rdi, [rsp + 0]
    mov rsi, rbx
    mov rdx, 32
    mov rcx, 1024
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 16
    mov rdx, r14
    mov rcx, r12
    mov r8, qword ptr [rsp + 1808]
    lea r9, [rsp + 256]
    call CALL(blake3_servil_avx512_k32)
    lea rdi, [rsp + 1280]
    lea rsi, [rsp + 256]
    mov rdx, r14
    mov rcx, r15
    call CALL(b3l_tree32)
    mov rdi, r13
    mov rsi, r14
    mov rdx, r15
    mov rcx, 5
    lea r8, [rsp + 1280]
    call CALL(b3l_ladd)
    mov rax, rbx
    add rax, 32768
    mov rbx, rax
    mov rax, rbp
    sub rax, 32768
    mov rbp, rax
    mov rax, r12
    add rax, 32
    mov r12, rax
    jmp .Lb3l_wide_0
.Lb3l_wide_1:
    mov rax, r12
    add rsp, 1816
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_addn
.global _b3l_addn
.p2align 4
b3l_addn:
_b3l_addn:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov qword ptr [rsp + 0], rcx
    mov r15, r8
    mov rax, 0
    mov rbx, rax
    mov rax, qword ptr [rsp + 0]
    mov rbp, rax
.Lb3l_addn_0:
    mov rax, rbx
    mov rcx, r15
    cmp rax, rcx
    jae .Lb3l_addn_1
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    mov rcx, 5
    mov r8, rbp
    call CALL(b3l_ladd)
    mov rax, rbp
    add rax, 32
    mov rbp, rax
    mov rax, rbx
    add rax, 1
    mov rbx, rax
    jmp .Lb3l_addn_0
.Lb3l_addn_1:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_finish
.global _b3l_finish
.p2align 4
b3l_finish:
_b3l_finish:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, r12
    add rax, 64
    mov qword ptr [rsp + 32], rax
    mov rax, r15
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_finish_0
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov rcx, r14
    mov r8, 5
    mov r9, 8
    call CALL(b3l_lroot)
    jmp .Lb3l_finish_1
.Lb3l_finish_0:
    mov rax, r15
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_finish_2
    mov rdi, rbp
    mov rsi, r13
    mov rdx, r14
    mov rcx, 5
    mov r8, qword ptr [rsp + 32]
    call CALL(b3l_ladd)
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r13
    mov rcx, r14
    mov r8, 5
    mov r9, 8
    call CALL(b3l_lroot)
    jmp .Lb3l_finish_3
.Lb3l_finish_2:
    lea rdi, [rsp + 0]
    mov rsi, r12
    mov rdx, r13
    mov rcx, r14
    mov r8, 5
    mov r9, 0
    call CALL(b3l_lroot)
    mov rdi, rbp
    mov rsi, r13
    mov rdx, r14
    mov rcx, 5
    lea r8, [rsp + 0]
    call CALL(b3l_ladd)
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r13
    mov rcx, r14
    mov r8, 5
    mov r9, 8
    call CALL(b3l_lroot)
.Lb3l_finish_3:
.Lb3l_finish_1:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_group
.global _b3l_group
.p2align 4
b3l_group:
_b3l_group:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 200
    mov r15, rdi
    mov qword ptr [rsp + 160], rsi
    mov qword ptr [rsp + 168], rdx
    mov r13, rcx
    mov r14, r8
    mov qword ptr [rsp + 176], r9
    mov rax, 0
    mov rcx, r15
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 160]
    mov rbx, rax
    mov rax, qword ptr [rsp + 168]
    mov rbp, rax
    mov rax, 0
    mov r12, rax
.Lb3l_group_0:
    mov rax, 1024
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_group_1
    mov rax, qword ptr [rsp + 176]
    add rax, r12
    mov qword ptr [rsp + 184], rax
    mov rax, r13
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 0]
    mov rsi, rbx
    mov rdx, 1024
    mov rcx, qword ptr [rsp + 184]
    mov r8, r14
    mov r9, 5
    call CALL(b3l_chunk_node)
    lea rdi, [rsp + 128]
    lea rsi, [rsp + 0]
    mov rdx, 0
    mov rcx, 5
    call CALL(b3l_node_out)
    mov rdi, r15
    mov rsi, r13
    mov rdx, r14
    mov rcx, 5
    lea r8, [rsp + 128]
    call CALL(b3l_ladd)
    mov rax, rbx
    add rax, 1024
    mov rbx, rax
    mov rax, rbp
    sub rax, 1024
    mov rbp, rax
    mov rax, r12
    add rax, 1
    mov r12, rax
    jmp .Lb3l_group_0
.Lb3l_group_1:
    mov rax, qword ptr [rsp + 176]
    add rax, r12
    mov qword ptr [rsp + 192], rax
    mov rax, r13
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 0]
    mov rsi, rbx
    mov rdx, rbp
    mov rcx, qword ptr [rsp + 192]
    mov r8, r14
    mov r9, 5
    call CALL(b3l_chunk_node)
    lea rdi, [rsp + 128]
    lea rsi, [rsp + 0]
    mov rdx, 0
    mov rcx, 5
    call CALL(b3l_node_out)
    mov rdi, r15
    mov rsi, r13
    mov rdx, r14
    mov rcx, 5
    lea r8, [rsp + 128]
    call CALL(b3l_ladd)
    add rsp, 200
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_hashw
.global _b3l_hashw
.p2align 4
b3l_hashw:
_b3l_hashw:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 7064
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov rax, 1024
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_hashw_0
    lea rdi, [rsp + 0]
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    call CALL(b3l_wide)
    mov r15, rax
    mov rax, rbp
    mov rcx, r15
    shl rcx, 10
    add rax, rcx
    mov qword ptr [rsp + 7040], rax
    mov rax, r12
    mov rcx, r15
    shl rcx, 10
    sub rax, rcx
    mov qword ptr [rsp + 7048], rax
    lea rdi, [rsp + 3520]
    mov rsi, qword ptr [rsp + 7040]
    mov rdx, qword ptr [rsp + 7048]
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call CALL(b3l_group)
    mov rax, r15
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_hashw_2
    mov rdi, rbx
    lea rsi, [rsp + 0]
    lea rdx, [rsp + 3520]
    mov rcx, r13
    mov r8, r14
    mov r9, 0
    call CALL(b3l_finish)
    jmp .Lb3l_hashw_3
.Lb3l_hashw_2:
    mov rax, 1024
    mov rcx, qword ptr [rsp + 7048]
    cmp rax, rcx
    jae .Lb3l_hashw_4
    mov rdi, rbx
    lea rsi, [rsp + 0]
    lea rdx, [rsp + 3520]
    mov rcx, r13
    mov r8, r14
    mov r9, 2
    call CALL(b3l_finish)
    jmp .Lb3l_hashw_5
.Lb3l_hashw_4:
    mov rdi, rbx
    lea rsi, [rsp + 0]
    lea rdx, [rsp + 3520]
    mov rcx, r13
    mov r8, r14
    mov r9, 1
    call CALL(b3l_finish)
.Lb3l_hashw_5:
.Lb3l_hashw_3:
    jmp .Lb3l_hashw_1
.Lb3l_hashw_0:
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    mov r9, 5
    call CALL(b3l_hashl)
.Lb3l_hashw_1:
    add rsp, 7064
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_hashf
.global _b3l_hashf
.p2align 4
b3l_hashf:
_b3l_hashf:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_hashf_0
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    call CALL(b3l_hashw)
    jmp .Lb3l_hashf_1
.Lb3l_hashf_0:
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call CALL(b3l_hashl)
.Lb3l_hashf_1:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_hash2
.global _b3l_hash2
.p2align 4
b3l_hash2:
_b3l_hash2:
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
.Lb3l_hash2_0:
    mov rax, 1024
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_hash2_1
    mov rax, rbp
    shr rax, 10
    mov r14, rax
    mov rax, 16
    mov rcx, r14
    cmp rax, rcx
    jae .Lb3l_hash2_2
    mov rax, 16
    mov r14, rax
.Lb3l_hash2_2:
    mov rax, 0
    mov r13, rax
.Lb3l_hash2_4:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lb3l_hash2_5
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
    jmp .Lb3l_hash2_4
.Lb3l_hash2_5:
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_hash2_6
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
    jmp .Lb3l_hash2_7
.Lb3l_hash2_6:
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 4
    cmp rax, rcx
    jne .Lb3l_hash2_8
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
    jmp .Lb3l_hash2_9
.Lb3l_hash2_8:
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
.Lb3l_hash2_9:
.Lb3l_hash2_7:
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
.Lb3l_hash2_10:
    mov rax, r13
    mov rcx, r14
    cmp rax, rcx
    jae .Lb3l_hash2_11
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
.Lb3l_hash2_12:
    mov rax, qword ptr [rsp + 5128]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_hash2_13
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
    jne .Lb3l_hash2_14
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hash2_15
.Lb3l_hash2_14:
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_hash2_15:
    mov rax, qword ptr [rsp + 5144]
    add rax, 64
    mov qword ptr [rsp + 5144], rax
    jmp .Lb3l_hash2_12
.Lb3l_hash2_13:
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
    jmp .Lb3l_hash2_10
.Lb3l_hash2_11:
    mov rax, r12
    add rax, r14
    mov r12, rax
    jmp .Lb3l_hash2_0
.Lb3l_hash2_1:
    mov rax, 0
    mov qword ptr [rsp + 5168], rax
    mov rax, r12
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_hash2_16
    mov rax, 1
    mov qword ptr [rsp + 5168], rax
.Lb3l_hash2_16:
    mov rax, qword ptr [rsp + 5168]
    mov qword ptr [rsp + 5176], rax
    mov rax, rbp
    mov rcx, 0
    cmp rax, rcx
    je .Lb3l_hash2_18
    mov rax, 1
    mov qword ptr [rsp + 5176], rax
.Lb3l_hash2_18:
    mov rax, qword ptr [rsp + 5176]
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_hash2_20
    mov rax, r15
    lea rcx, [rsp + 4928]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, 1
    mov qword ptr [rsp + 5184], rax
.Lb3l_hash2_22:
    mov rax, 64
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_hash2_23
    mov rax, qword ptr [rsp + 5080]
    or rax, qword ptr [rsp + 5184]
    mov qword ptr [rsp + 5112], rax
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_hash2_24
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hash2_25
.Lb3l_hash2_24:
    lea rdi, [rsp + 4928]
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_hash2_25:
    mov rax, 0
    mov qword ptr [rsp + 5184], rax
    mov rax, rbx
    add rax, 64
    mov rbx, rax
    mov rax, rbp
    sub rax, 64
    mov rbp, rax
    jmp .Lb3l_hash2_22
.Lb3l_hash2_23:
    mov rax, rbx
    mov qword ptr [rsp + 5192], rax
    mov rax, rbp
    mov rcx, 64
    cmp rax, rcx
    je .Lb3l_hash2_26
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
.Lb3l_hash2_28:
    mov rax, qword ptr [rsp + 5200]
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_hash2_29
    mov rax, rbx
    add rax, qword ptr [rsp + 5200]
    movzx eax, byte ptr [rax]
    lea rcx, [rsp + 4864]
    add rcx, qword ptr [rsp + 5200]
    mov byte ptr [rcx], al
    mov rax, qword ptr [rsp + 5200]
    add rax, 1
    mov qword ptr [rsp + 5200], rax
    jmp .Lb3l_hash2_28
.Lb3l_hash2_29:
    lea rax, [rsp + 4864]
    mov qword ptr [rsp + 5192], rax
.Lb3l_hash2_26:
    mov rax, qword ptr [rsp + 5080]
    or rax, qword ptr [rsp + 5184]
    or rax, 2
    mov qword ptr [rsp + 5112], rax
    mov rax, qword ptr [rsp + 5168]
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_hash2_30
    mov rax, qword ptr [rsp + 5112]
    or rax, 8
    mov qword ptr [rsp + 5112], rax
.Lb3l_hash2_30:
    mov rax, qword ptr [rsp + 5088]
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_hash2_32
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5192]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hash2_33
.Lb3l_hash2_32:
    lea rdi, [rsp + 4928]
    mov rsi, qword ptr [rsp + 5192]
    mov rdx, rbp
    mov rcx, r12
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_hash2_33:
.Lb3l_hash2_20:
    mov rax, qword ptr [rsp + 5168]
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_hash2_34
    lea rax, [rsp + 4928]
    mov rcx, qword ptr [rsp + 5056]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    jmp .Lb3l_hash2_35
.Lb3l_hash2_34:
    mov rax, qword ptr [rsp + 5176]
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_hash2_36
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
.Lb3l_hash2_38:
    mov rax, qword ptr [rsp + 5128]
    and rax, 1
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_hash2_39
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
    jne .Lb3l_hash2_40
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hash2_41
.Lb3l_hash2_40:
    mov rdi, qword ptr [rsp + 5152]
    mov rsi, qword ptr [rsp + 5144]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5096]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_hash2_41:
    mov rax, qword ptr [rsp + 5144]
    add rax, 64
    mov qword ptr [rsp + 5144], rax
    jmp .Lb3l_hash2_38
.Lb3l_hash2_39:
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
.Lb3l_hash2_36:
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
.Lb3l_hash2_42:
    mov rax, 0
    mov rcx, qword ptr [rsp + 5136]
    cmp rax, rcx
    jae .Lb3l_hash2_43
    mov rax, qword ptr [rsp + 5136]
    and rax, 1
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_hash2_44
    mov rax, qword ptr [rsp + 5096]
    mov qword ptr [rsp + 5112], rax
    mov rax, qword ptr [rsp + 5136]
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_hash2_46
    mov rax, qword ptr [rsp + 5096]
    or rax, 8
    mov qword ptr [rsp + 5112], rax
.Lb3l_hash2_46:
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
    jne .Lb3l_hash2_48
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hash2_49
.Lb3l_hash2_48:
    lea rdi, [rsp + 5024]
    lea rsi, [rsp + 4960]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 5112]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_hash2_49:
.Lb3l_hash2_44:
    mov rax, qword ptr [rsp + 5136]
    shr rax, 1
    mov qword ptr [rsp + 5136], rax
    mov rax, qword ptr [rsp + 5160]
    add rax, 64
    mov qword ptr [rsp + 5160], rax
    jmp .Lb3l_hash2_42
.Lb3l_hash2_43:
    lea rax, [rsp + 5024]
    mov rcx, qword ptr [rsp + 5056]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
.Lb3l_hash2_35:
    mov rsp, qword ptr [rsp + 5208]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
