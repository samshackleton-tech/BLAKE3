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
.global ode_adler32_blocks4
.global _ode_adler32_blocks4
.p2align 4
ode_adler32_blocks4:
_ode_adler32_blocks4:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov rax, 0
    mov r12, rax
    mov rax, 1
    mov r13, rax
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov r15, rax
.Lode_adler32_blocks4_0:
    mov rax, r12
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_adler32_blocks4_1
    mov rax, rbp
    mov r15, rax
    mov rax, 5552
    mov rcx, rbp
    sub rcx, r12
    cmp rax, rcx
    jae .Lode_adler32_blocks4_2
    mov rax, r12
    add rax, 5552
    mov r15, rax
.Lode_adler32_blocks4_2:
.Lode_adler32_blocks4_4:
    mov rax, 3
    mov rcx, r15
    sub rcx, r12
    cmp rax, rcx
    jae .Lode_adler32_blocks4_5
    mov rax, r13
    mov rcx, rbx
    add rcx, r12
    movzx ecx, byte ptr [rcx]
    add rax, rcx
    mov r13, rax
    mov rax, r14
    add rax, r13
    mov r14, rax
    mov rax, r13
    mov rcx, rbx
    add rcx, r12
    add rcx, 1
    movzx ecx, byte ptr [rcx]
    add rax, rcx
    mov r13, rax
    mov rax, r14
    add rax, r13
    mov r14, rax
    mov rax, r13
    mov rcx, rbx
    add rcx, r12
    add rcx, 2
    movzx ecx, byte ptr [rcx]
    add rax, rcx
    mov r13, rax
    mov rax, r14
    add rax, r13
    mov r14, rax
    mov rax, r13
    mov rcx, rbx
    add rcx, r12
    add rcx, 3
    movzx ecx, byte ptr [rcx]
    add rax, rcx
    mov r13, rax
    mov rax, r14
    add rax, r13
    mov r14, rax
    mov rax, r12
    add rax, 4
    mov r12, rax
    jmp .Lode_adler32_blocks4_4
.Lode_adler32_blocks4_5:
.Lode_adler32_blocks4_6:
    mov rax, r12
    mov rcx, r15
    cmp rax, rcx
    jae .Lode_adler32_blocks4_7
    mov rax, r13
    mov rcx, rbx
    add rcx, r12
    movzx ecx, byte ptr [rcx]
    add rax, rcx
    mov r13, rax
    mov rax, r14
    add rax, r13
    mov r14, rax
    mov rax, r12
    add rax, 1
    mov r12, rax
    jmp .Lode_adler32_blocks4_6
.Lode_adler32_blocks4_7:
    mov rax, r13
    and rax, 65535
    mov rcx, r13
    shr rcx, 16
    shl rcx, 4
    add rax, rcx
    mov rcx, r13
    shr rcx, 16
    sub rax, rcx
    mov r13, rax
    mov rax, r13
    and rax, 65535
    mov rcx, r13
    shr rcx, 16
    shl rcx, 4
    add rax, rcx
    mov rcx, r13
    shr rcx, 16
    sub rax, rcx
    mov r13, rax
    mov rax, r13
    mov rcx, 65521
    cmp rax, rcx
    jae .Lode_adler32_blocks4_8
    jmp .Lode_adler32_blocks4_9
.Lode_adler32_blocks4_8:
    mov rax, r13
    sub rax, 65521
    mov r13, rax
.Lode_adler32_blocks4_9:
    mov rax, r14
    and rax, 65535
    mov rcx, r14
    shr rcx, 16
    shl rcx, 4
    add rax, rcx
    mov rcx, r14
    shr rcx, 16
    sub rax, rcx
    mov r14, rax
    mov rax, r14
    and rax, 65535
    mov rcx, r14
    shr rcx, 16
    shl rcx, 4
    add rax, rcx
    mov rcx, r14
    shr rcx, 16
    sub rax, rcx
    mov r14, rax
    mov rax, r14
    mov rcx, 65521
    cmp rax, rcx
    jae .Lode_adler32_blocks4_10
    jmp .Lode_adler32_blocks4_11
.Lode_adler32_blocks4_10:
    mov rax, r14
    sub rax, 65521
    mov r14, rax
.Lode_adler32_blocks4_11:
    jmp .Lode_adler32_blocks4_0
.Lode_adler32_blocks4_1:
    mov rax, r14
    shl rax, 16
    add rax, r13
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
