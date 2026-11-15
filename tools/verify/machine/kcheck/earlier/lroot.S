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
