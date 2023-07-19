.section .text
.global _start
_start:
    push %rbp
    mov %rsp, %rbp

    call read_file_contents

    call parse
    movq %rax, %rdi
    movq %rbx, %rsi
    push %rdi
    push %rsi
    // call astprint
    pop %rsi
    pop %rdi
    push %rdi
    push %rsi
    call collect
    pop %rsi
    pop %rdi
    call emit
    jmp end_start
end_start:
    leave
    movq $60, %rax
    movq $0, %rdi
    syscall
    