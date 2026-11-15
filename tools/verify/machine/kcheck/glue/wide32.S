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
.global b3l_wide32
.global _b3l_wide32
.p2align 4
b3l_wide32:
_b3l_wide32:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 2328
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, r12
    add rax, 32
    mov rax, qword ptr [rax]
    mov r14, rax
    mov rax, r14
    or rax, 1073873152
    mov r15, rax
    mov rax, r14
    or rax, 1073741828
    mov qword ptr [rsp + 2304], rax
    mov rax, 0
    mov qword ptr [rsp + 2312], rax
    mov rax, 0
    mov qword ptr [rsp + 2312], rax
.Lb3l_wide32_0:
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide32_1
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide32_2
    mov rax, rbp
    mov rcx, qword ptr [rsp + 2312]
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide32_3
.Lb3l_wide32_2:
    mov rax, rbp
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide32_3:
    mov rax, qword ptr [rsp + 2312]
    add rax, 1
    mov qword ptr [rsp + 2312], rax
    jmp .Lb3l_wide32_0
.Lb3l_wide32_1:
    lea rdi, [rsp + 0]
    mov rsi, 16
    mov rdx, r12
    mov rcx, r13
    mov r8, r15
    lea r9, [rsp + 256]
    call CALL(blake3_servil_avx512_k32)
    mov rax, 0
    mov qword ptr [rsp + 2312], rax
.Lb3l_wide32_4:
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide32_5
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide32_6
    lea rax, [rsp + 256]
    mov rcx, qword ptr [rsp + 2312]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide32_7
.Lb3l_wide32_6:
    lea rax, [rsp + 256]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide32_7:
    mov rax, qword ptr [rsp + 2312]
    add rax, 1
    mov qword ptr [rsp + 2312], rax
    jmp .Lb3l_wide32_4
.Lb3l_wide32_5:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 2304]
    lea r9, [rsp + 1280]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 2312], rax
.Lb3l_wide32_8:
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide32_9
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 8
    cmp rax, rcx
    jae .Lb3l_wide32_10
    lea rax, [rsp + 1280]
    mov rcx, qword ptr [rsp + 2312]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide32_11
.Lb3l_wide32_10:
    lea rax, [rsp + 1280]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide32_11:
    mov rax, qword ptr [rsp + 2312]
    add rax, 1
    mov qword ptr [rsp + 2312], rax
    jmp .Lb3l_wide32_8
.Lb3l_wide32_9:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 2304]
    lea r9, [rsp + 1792]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 2312], rax
.Lb3l_wide32_12:
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide32_13
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 4
    cmp rax, rcx
    jae .Lb3l_wide32_14
    lea rax, [rsp + 1792]
    mov rcx, qword ptr [rsp + 2312]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide32_15
.Lb3l_wide32_14:
    lea rax, [rsp + 1792]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide32_15:
    mov rax, qword ptr [rsp + 2312]
    add rax, 1
    mov qword ptr [rsp + 2312], rax
    jmp .Lb3l_wide32_12
.Lb3l_wide32_13:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 2304]
    lea r9, [rsp + 1280]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 2312], rax
.Lb3l_wide32_16:
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide32_17
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 2
    cmp rax, rcx
    jae .Lb3l_wide32_18
    lea rax, [rsp + 1280]
    mov rcx, qword ptr [rsp + 2312]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide32_19
.Lb3l_wide32_18:
    lea rax, [rsp + 1280]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide32_19:
    mov rax, qword ptr [rsp + 2312]
    add rax, 1
    mov qword ptr [rsp + 2312], rax
    jmp .Lb3l_wide32_16
.Lb3l_wide32_17:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 2304]
    lea r9, [rsp + 1792]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 2312], rax
.Lb3l_wide32_20:
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide32_21
    mov rax, qword ptr [rsp + 2312]
    mov rcx, 1
    cmp rax, rcx
    jae .Lb3l_wide32_22
    lea rax, [rsp + 1792]
    mov rcx, qword ptr [rsp + 2312]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide32_23
.Lb3l_wide32_22:
    lea rax, [rsp + 1792]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 2312]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide32_23:
    mov rax, qword ptr [rsp + 2312]
    add rax, 1
    mov qword ptr [rsp + 2312], rax
    jmp .Lb3l_wide32_20
.Lb3l_wide32_21:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 2304]
    lea r9, [rsp + 1280]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 1280]
    mov rcx, rbx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    add rsp, 2328
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
