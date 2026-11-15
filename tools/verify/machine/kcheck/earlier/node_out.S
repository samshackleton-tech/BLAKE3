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
.global b3l_node_out
.global _b3l_node_out
.p2align 4
b3l_node_out:
_b3l_node_out:
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
    mov rax, rbp
    add rax, 32
    mov r14, rax
    mov rax, rbp
    add rax, 104
    mov rax, qword ptr [rax]
    mov r15, rax
    mov rax, rbp
    add rax, 96
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 0], rax
    mov rax, rbp
    add rax, 112
    mov rax, qword ptr [rax]
    or rax, r12
    mov qword ptr [rsp + 8], rax
    mov rax, rbp
    mov rcx, rbx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r13
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_node_out_0
    mov rdi, rbx
    mov rsi, r14
    mov rdx, r15
    mov rcx, qword ptr [rsp + 0]
    mov r8, qword ptr [rsp + 8]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_node_out_1
.Lb3l_node_out_0:
    mov rdi, rbx
    mov rsi, r14
    mov rdx, r15
    mov rcx, qword ptr [rsp + 0]
    mov r8, qword ptr [rsp + 8]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_node_out_1:
    add rsp, 24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
