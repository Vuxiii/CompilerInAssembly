.section .text
.global _start
_start:
        push %rbp
        movq %rsp, %rbp

        movq $0, %rax
        movq $0, %rbx
        andq %rax, %rbx
        
        movq $0, %rax
        movq $1, %rbx
        andq %rax, %rbx
        
        movq $1, %rax
        movq $1, %rbx
        andq %rax, %rbx
        
        movq $1, %rax
        movq $0, %rbx
        andq %rax, %rbx

        movq $0, %rax
        movq $0, %rbx
        orq %rax, %rbx
        
        movq $0, %rax
        movq $1, %rbx
        orq %rax, %rbx
        
        movq $1, %rax
        movq $1, %rbx
        orq %rax, %rbx
        
        movq $1, %rax
        movq $0, %rbx
        orq %rax, %rbx
    b:        

        leave

        movq $60, %rax
        movq $1, %rdi
        syscall
