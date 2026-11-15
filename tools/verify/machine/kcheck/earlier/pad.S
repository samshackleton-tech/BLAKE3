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
.global b3l_pad
.global _b3l_pad
.p2align 4
b3l_pad:
_b3l_pad:
    push rbx
    push rbp
    push r12
    push r13
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov rax, 64
    mov r13, rax
.Lb3l_pad_0:
    mov rax, 0
    mov rcx, r13
    cmp rax, rcx
    jae .Lb3l_pad_1
    mov rax, r13
    sub rax, 1
    mov r13, rax
    mov rax, r13
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_pad_2
    mov rax, rbp
    add rax, r13
    movzx eax, byte ptr [rax]
    mov rcx, rbx
    add rcx, r13
    mov byte ptr [rcx], al
    jmp .Lb3l_pad_3
.Lb3l_pad_2:
    mov rax, 0
    mov rcx, rbx
    add rcx, r13
    mov byte ptr [rcx], al
.Lb3l_pad_3:
    jmp .Lb3l_pad_0
.Lb3l_pad_1:
    add rsp, 8
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
