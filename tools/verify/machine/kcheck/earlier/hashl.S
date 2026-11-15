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
