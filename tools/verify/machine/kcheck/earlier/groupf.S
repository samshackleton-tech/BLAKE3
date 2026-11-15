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
.global b3l_groupf
.global _b3l_groupf
.p2align 4
b3l_groupf:
_b3l_groupf:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 1480
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, r14
    or rax, 1073873152
    mov qword ptr [rsp + 1440], rax
    mov rax, r12
    sub rax, 1
    shr rax, 10
    mov qword ptr [rsp + 1448], rax
    mov rax, rbp
    mov rcx, qword ptr [rsp + 1448]
    shl rcx, 10
    add rax, rcx
    mov qword ptr [rsp + 1456], rax
    mov rax, r12
    mov rcx, qword ptr [rsp + 1448]
    shl rcx, 10
    sub rax, rcx
    mov qword ptr [rsp + 1464], rax
    mov rax, r15
    add rax, qword ptr [rsp + 1448]
    mov qword ptr [rsp + 1472], rax
    lea rdi, [rsp + 160]
    mov rsi, rbp
    mov rdx, qword ptr [rsp + 1448]
    mov rcx, 1024
    call CALL(b3l_fillp)
    lea rdi, [rsp + 160]
    mov rsi, 16
    mov rdx, r13
    mov rcx, r15
    mov r8, qword ptr [rsp + 1440]
    lea r9, [rsp + 416]
    call CALL(blake3_servil_avx512_k32)
    mov rax, 0
    mov rcx, rbx
    mov qword ptr [rcx], rax
    mov rdi, rbx
    mov rsi, r13
    mov rdx, r14
    lea rcx, [rsp + 416]
    mov r8, qword ptr [rsp + 1448]
    call CALL(b3l_addn)
    mov rax, r13
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 0]
    mov rsi, qword ptr [rsp + 1456]
    mov rdx, qword ptr [rsp + 1464]
    mov rcx, qword ptr [rsp + 1472]
    mov r8, r14
    mov r9, 5
    call CALL(b3l_chunk_node)
    lea rdi, [rsp + 128]
    lea rsi, [rsp + 0]
    mov rdx, 0
    mov rcx, 5
    call CALL(b3l_node_out)
    mov rdi, rbx
    mov rsi, r13
    mov rdx, r14
    mov rcx, 5
    lea r8, [rsp + 128]
    call CALL(b3l_ladd)
    add rsp, 1480
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
