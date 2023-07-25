.section .text
.global _start
_start:
        enter $8, $0
        movq $10, %rcx
        xor %rax, %rax
    begin:
        inc %rax
        loopnz  begin

    b:
        leave

        movq $60, %rax
        movq $1, %rdi
        syscall
