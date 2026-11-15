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
    mov rax, r15
    mov rcx, 0
    cmp rax, rcx
    jne .Lb3l_hashw_2
    lea rdi, [rsp + 3520]
    mov rsi, qword ptr [rsp + 7040]
    mov rdx, qword ptr [rsp + 7048]
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call CALL(b3l_groupf)
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
    lea rdi, [rsp + 3520]
    mov rsi, qword ptr [rsp + 7040]
    mov rdx, qword ptr [rsp + 7048]
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call CALL(b3l_groupf)
    mov rdi, rbx
    lea rsi, [rsp + 0]
    lea rdx, [rsp + 3520]
    mov rcx, r13
    mov r8, r14
    mov r9, 2
    call CALL(b3l_finish)
    jmp .Lb3l_hashw_5
.Lb3l_hashw_4:
    lea rdi, [rsp + 3520]
    mov rsi, qword ptr [rsp + 7040]
    mov rdx, qword ptr [rsp + 7048]
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call CALL(b3l_group)
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
