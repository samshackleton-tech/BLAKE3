# call_kernel(f, args, after): call f(args[0..5]) with known values in the registers a callee keeps;
# after[0..5] = rbx, rbp, r12, r13, r14, r15 as f left them; after[6] = 1 if the stack pointer came back moved.
    .intel_syntax noprefix
    .text
    .globl call_kernel
    .type call_kernel, @function
call_kernel:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov [rsp], rdx
    mov r10, rdi
    mov r11, rsi
    mov rbx, [rip + call_kernel_values]
    mov rbp, [rip + call_kernel_values + 8]
    mov r12, [rip + call_kernel_values + 16]
    mov r13, [rip + call_kernel_values + 24]
    mov r14, [rip + call_kernel_values + 32]
    mov r15, [rip + call_kernel_values + 40]
    mov rdi, [r11]
    mov rsi, [r11 + 8]
    mov rdx, [r11 + 16]
    mov rcx, [r11 + 24]
    mov r8, [r11 + 32]
    mov r9, [r11 + 40]
    mov [rip + saved_rsp], rsp
    cld
    call r10
    xor eax, eax
    cmp rsp, [rip + saved_rsp]
    je 1f
    mov rsp, [rip + saved_rsp]
    mov eax, 1
1:  mov r11, [rsp]
    mov [r11], rbx
    mov [r11 + 8], rbp
    mov [r11 + 16], r12
    mov [r11 + 24], r13
    mov [r11 + 32], r14
    mov [r11 + 40], r15
    mov [r11 + 48], rax
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
    .size call_kernel, .-call_kernel

    .data
    .balign 8
    .globl call_kernel_values
call_kernel_values:
    .quad 0x1111111111111111, 0x2222222222222222, 0x3333333333333333, 0x4444444444444444, 0x5555555555555555, 0x6666666666666666
saved_rsp:
    .quad 0
    .section .note.GNU-stack, "", @progbits
