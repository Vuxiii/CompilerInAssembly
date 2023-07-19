
.section .text
.global _start
_start:
        push %rbp
        movq %rsp, %rbp
        subq $16, %rsp

        movq $69, -8(%rbp)
        leaq -8(%rbp), %rax
        movq %rax, -16(%rbp)
        push (%rax)

        leave
        movq $60, %rax
        movq $0, %rdi
        syscall
