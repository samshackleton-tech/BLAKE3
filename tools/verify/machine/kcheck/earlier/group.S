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
