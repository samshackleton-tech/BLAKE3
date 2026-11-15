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
.global b3l_chunk_node
.global _b3l_chunk_node
.p2align 4
b3l_chunk_node:
_b3l_chunk_node:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov r13, rdi
    mov qword ptr [rsp + 0], rsi
    mov qword ptr [rsp + 8], rdx
    mov r14, rcx
    mov qword ptr [rsp + 16], r8
    mov r15, r9
    mov rax, 1
    mov r12, rax
    mov rax, qword ptr [rsp + 0]
    mov rbx, rax
    mov rax, qword ptr [rsp + 8]
    mov rbp, rax
.Lb3l_chunk_node_0:
    mov rax, 64
    mov rcx, rbp
    cmp rax, rcx
    jae .Lb3l_chunk_node_1
    mov rax, qword ptr [rsp + 16]
    or rax, r12
    mov qword ptr [rsp + 24], rax
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_chunk_node_2
    mov rdi, r13
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r14
    mov r8, qword ptr [rsp + 24]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_chunk_node_3
.Lb3l_chunk_node_2:
    mov rdi, r13
    mov rsi, rbx
    mov rdx, 64
    mov rcx, r14
    mov r8, qword ptr [rsp + 24]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_chunk_node_3:
    mov rax, 0
    mov r12, rax
    mov rax, rbx
    add rax, 64
    mov rbx, rax
    mov rax, rbp
    sub rax, 64
    mov rbp, rax
    jmp .Lb3l_chunk_node_0
.Lb3l_chunk_node_1:
    mov rax, r13
    add rax, 32
    mov qword ptr [rsp + 32], rax
    mov rdi, qword ptr [rsp + 32]
    mov rsi, rbx
    mov rdx, rbp
    call CALL(b3l_pad)
    mov rax, r14
    mov rcx, r13
    add rcx, 96
    mov qword ptr [rcx], rax
    mov rax, rbp
    mov rcx, r13
    add rcx, 104
    mov qword ptr [rcx], rax
    mov rax, qword ptr [rsp + 16]
    or rax, r12
    or rax, 2
    mov rcx, r13
    add rcx, 112
    mov qword ptr [rcx], rax
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
