.section .data
s1: .asciz "equals"
s2: .asciz "equals "

.section .text
.global _start
_start:
        enter $8, $0
    
        movq $s1, %rsi
        movq $s2, %rdi
        cld
        movq $8, %rcx
        repe cmpsb 
        je crash

        leave
        movq $60, %rax
        movq $1, %rdi
        syscall
    crash:
        movq (%rax), %rax

loopii:
    enter $0, $0
    movq $10, %rcx
        xor %rax, %rax
    begin:
        inc %rax
        loopnz  begin
    leave
    ret
