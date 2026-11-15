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
