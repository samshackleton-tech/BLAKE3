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
