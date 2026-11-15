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
.global b3l_part32
.global _b3l_part32
.p2align 4
b3l_part32:
_b3l_part32:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 1304
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov rax, r13
    add rax, 32
    mov rax, qword ptr [rax]
    mov r15, rax
    mov rax, r15
    or rax, 1073873152
    mov qword ptr [rsp + 1280], rax
    mov rax, r12
    shr rax, 10
    mov qword ptr [rsp + 1288], rax
    mov rax, 0
    mov qword ptr [rsp + 1296], rax
    mov rax, 0
    mov qword ptr [rsp + 1296], rax
.Lb3l_part32_0:
    mov rax, qword ptr [rsp + 1296]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_part32_1
    mov rax, qword ptr [rsp + 1296]
    mov rcx, qword ptr [rsp + 1288]
    cmp rax, rcx
    jae .Lb3l_part32_2
    mov rax, rbp
    mov rcx, qword ptr [rsp + 1296]
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 1296]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_part32_3
.Lb3l_part32_2:
    mov rax, rbp
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 1296]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_part32_3:
    mov rax, qword ptr [rsp + 1296]
    add rax, 1
    mov qword ptr [rsp + 1296], rax
    jmp .Lb3l_part32_0
.Lb3l_part32_1:
    lea rdi, [rsp + 0]
    mov rsi, 16
    mov rdx, r13
    mov rcx, r14
    mov r8, qword ptr [rsp + 1280]
    lea r9, [rsp + 256]
    call CALL(blake3_servil_avx512_k32)
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    lea r9, [rsp + 256]
    call CALL(b3l_take)
    add rsp, 1304
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
