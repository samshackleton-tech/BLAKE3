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
.global ode_unframe
.global _ode_unframe
.p2align 4
ode_unframe:
_ode_unframe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 24
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, 18446744073709551615
    mov r14, rax
    mov rax, 0
    mov r15, rax
    mov rax, 0
    mov qword ptr [rsp + 0], rax
    mov rax, 0
    mov qword ptr [rsp + 8], rax
    mov rax, 0
    mov qword ptr [rsp + 16], rax
    mov rax, r13
    mov rcx, 4
    cmp rax, rcx
    jae .Lode_unframe_0
    jmp .Lode_unframe_1
.Lode_unframe_0:
    mov rax, r13
    sub rax, 4
    mov r15, rax
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r15
    call CALL(ode_lz4_decode)
    mov qword ptr [rsp + 0], rax
    mov rax, qword ptr [rsp + 0]
    mov rcx, 18446744073709551615
    cmp rax, rcx
    je .Lode_unframe_2
    mov rdi, rbx
    mov rsi, qword ptr [rsp + 0]
    call CALL(ode_adler32_blocks4)
    mov qword ptr [rsp + 8], rax
    mov rax, r12
    add rax, r15
    movzx eax, byte ptr [rax]
    shl rax, 24
    mov rcx, r12
    add rcx, r15
    add rcx, 1
    movzx ecx, byte ptr [rcx]
    shl rcx, 16
    add rax, rcx
    mov rcx, r12
    add rcx, r15
    add rcx, 2
    movzx ecx, byte ptr [rcx]
    shl rcx, 8
    add rax, rcx
    mov rcx, r12
    add rcx, r15
    add rcx, 3
    movzx ecx, byte ptr [rcx]
    add rax, rcx
    mov qword ptr [rsp + 16], rax
    mov rax, qword ptr [rsp + 8]
    mov rcx, qword ptr [rsp + 16]
    cmp rax, rcx
    jne .Lode_unframe_4
    mov rax, qword ptr [rsp + 0]
    mov r14, rax
.Lode_unframe_4:
.Lode_unframe_2:
.Lode_unframe_1:
    mov rax, r14
    add rsp, 24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
