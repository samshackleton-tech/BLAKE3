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
