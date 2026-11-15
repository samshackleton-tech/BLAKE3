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
.global ode_lz4_store
.global _ode_lz4_store
.p2align 4
ode_lz4_store:
_ode_lz4_store:
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
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov r15, rax
    mov rax, 0
    mov qword ptr [rsp + 0], rax
    mov rax, 0
    mov qword ptr [rsp + 8], rax
    mov rax, 0
    mov qword ptr [rsp + 16], rax
    mov rax, rbp
    mov rcx, 1
    cmp rax, rcx
    jae .Lode_lz4_store_0
    mov rax, 2
    mov qword ptr [rsp + 8], rax
    jmp .Lode_lz4_store_1
.Lode_lz4_store_0:
    mov rax, r13
    mov rcx, 15
    cmp rax, rcx
    jae .Lode_lz4_store_2
    mov rax, r13
    shl rax, 4
    mov rcx, rbx
    mov byte ptr [rcx], al
    mov rax, 1
    mov r14, rax
    jmp .Lode_lz4_store_3
.Lode_lz4_store_2:
    mov rax, 240
    mov rcx, rbx
    mov byte ptr [rcx], al
    mov rax, 1
    mov r14, rax
    mov rax, r13
    sub rax, 15
    mov r15, rax
    mov rax, 1
    mov qword ptr [rsp + 16], rax
.Lode_lz4_store_4:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_store_5
    mov rax, r14
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_lz4_store_6
    mov rax, r15
    mov rcx, 255
    cmp rax, rcx
    jae .Lode_lz4_store_8
    mov rax, r15
    mov rcx, rbx
    add rcx, r14
    mov byte ptr [rcx], al
    mov rax, r14
    add rax, 1
    mov r14, rax
    mov rax, 0
    mov qword ptr [rsp + 16], rax
    jmp .Lode_lz4_store_9
.Lode_lz4_store_8:
    mov rax, 255
    mov rcx, rbx
    add rcx, r14
    mov byte ptr [rcx], al
    mov rax, r14
    add rax, 1
    mov r14, rax
    mov rax, r15
    sub rax, 255
    mov r15, rax
.Lode_lz4_store_9:
    jmp .Lode_lz4_store_7
.Lode_lz4_store_6:
    mov rax, 2
    mov qword ptr [rsp + 8], rax
    mov rax, 0
    mov qword ptr [rsp + 16], rax
.Lode_lz4_store_7:
    jmp .Lode_lz4_store_4
.Lode_lz4_store_5:
.Lode_lz4_store_3:
.Lode_lz4_store_1:
    mov rax, qword ptr [rsp + 8]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_store_10
    mov rax, rbp
    sub rax, r14
    mov rcx, r13
    cmp rax, rcx
    jae .Lode_lz4_store_12
    mov rax, 2
    mov qword ptr [rsp + 8], rax
    jmp .Lode_lz4_store_13
.Lode_lz4_store_12:
.Lode_lz4_store_14:
    mov rax, qword ptr [rsp + 0]
    mov rcx, r13
    cmp rax, rcx
    jae .Lode_lz4_store_15
    mov rax, r12
    add rax, qword ptr [rsp + 0]
    movzx eax, byte ptr [rax]
    mov rcx, rbx
    add rcx, r14
    add rcx, qword ptr [rsp + 0]
    mov byte ptr [rcx], al
    mov rax, qword ptr [rsp + 0]
    add rax, 1
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_store_14
.Lode_lz4_store_15:
.Lode_lz4_store_13:
.Lode_lz4_store_10:
    mov rax, 18446744073709551615
    mov qword ptr [rsp + 24], rax
    mov rax, qword ptr [rsp + 8]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_store_16
    mov rax, r14
    add rax, r13
    mov qword ptr [rsp + 24], rax
.Lode_lz4_store_16:
    mov rax, qword ptr [rsp + 24]
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
