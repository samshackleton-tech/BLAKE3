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
.global ode_varint
.global _ode_varint
.p2align 4
ode_varint:
_ode_varint:
    push rbx
    push rbp
    push r12
    mov rbx, rdi
    mov rbp, rsi
    mov rax, 0
    mov r12, rax
.Lode_varint_0:
    mov rax, 127
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_varint_1
    mov rax, 128
    mov rcx, rbp
    and rcx, 127
    add rax, rcx
    mov rcx, rbx
    add rcx, r12
    mov byte ptr [rcx], al
    mov rax, rbp
    shr rax, 7
    mov rbp, rax
    mov rax, r12
    add rax, 1
    mov r12, rax
    jmp .Lode_varint_0
.Lode_varint_1:
    mov rax, rbp
    mov rcx, rbx
    add rcx, r12
    mov byte ptr [rcx], al
    mov rax, r12
    add rax, 1
    pop r12
    pop rbp
    pop rbx
    ret
