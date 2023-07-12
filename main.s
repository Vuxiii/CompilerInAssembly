.data

.extern token_eop        # -1
.extern token_none       # 0
.extern token_def        # 1
.extern token_if         # 2
.extern token_equals     # 3
.extern token_assignment # 4
.extern token_lparen     # 5
.extern token_rparen     # 6
.extern token_lcurly     # 7
.extern token_rcurly     # 8
.extern token_lbracket   # 9
.extern token_rbracket   # 10
.extern token_print      # 11
.extern token_while      # 12
.extern token_plus       # 13
.extern token_minus      # 14
.extern token_times      # 15
.extern token_div        # 16
.extern token_less       # 17
.extern token_greater    # 18
.extern token_true       # 19
.extern token_false      # 20
.extern token_let        # 21
.extern token_and        # 22
.extern token_or         # 23
.extern token_identifier # 24
.extern token_number     # 25

.extern buffer_address

.extern newline

.section .text
.global _start
_start:
    push %rbp
    mov %rsp, %rbp 
    movq $in, %rdi
    movq %rdi, (buffer_address)(%rip)

    callq parse
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
    callq emit
    jmp end_start
// ignore below for now.
_llopers:

    callq get_token

    cmp $1, %rax
    je print_def
    cmp $2, %rax
    je print_if 
    cmp $3, %rax
    je print_equals 
    cmp $4, %rax 
    je print_assignment
    cmp $5, %rax 
    je print_lparen
    cmp $6, %rax 
    je print_rparen
    cmp $7, %rax 
    je print_lcurly
    cmp $8, %rax 
    je print_rcurly
    cmp $9, %rax 
    je print_lbracket
    cmp $10, %rax 
    je print_rbracket
    cmp $11, %rax 
    je print_print
    cmp $12, %rax 
    je print_while
    cmp $13, %rax 
    je print_plus
    cmp $14, %rax 
    je print_minus
    cmp $15, %rax 
    je print_times
    cmp $16, %rax 
    je print_div
    cmp $17, %rax 
    je print_less
    cmp $18, %rax 
    je print_greater
    cmp $19, %rax 
    je print_true
    cmp $20, %rax 
    je print_false
    cmp $21, %rax 
    je print_let
    cmp $22, %rax 
    je print_and
    cmp $23, %rax 
    je print_or
    cmp $24, %rax 
    je print_identifier
    cmp $25, %rax 
    je print_number
    cmp $-1, %rax 
    je print_eop
    
    
    movq $1, %rax
    movq $1, %rdi
    leaq token_none, %rsi
    movq $5, %rdx
    syscall
    callq println
    jmp end_start
print_def:
    movq $1, %rax
    movq $1, %rdi
    leaq token_def, %rsi
    movq $3, %rdx
    syscall
    callq println
    jmp _llopers
print_if:
    movq $1, %rax
    movq $1, %rdi
    leaq token_if, %rsi
    movq $2, %rdx
    syscall
    callq println
    jmp _llopers
print_equals:
    movq $1, %rax
    movq $1, %rdi
    leaq token_equals, %rsi
    movq $2, %rdx
    syscall
    callq println
    jmp _llopers
print_assignment:
    movq $1, %rax
    movq $1, %rdi
    leaq token_assignment, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_lparen:
    movq $1, %rax
    movq $1, %rdi
    leaq token_lparen, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_rparen:
    movq $1, %rax
    movq $1, %rdi
    leaq token_rparen, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_lcurly:
    movq $1, %rax
    movq $1, %rdi
    leaq token_lcurly, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_rcurly:
    movq $1, %rax
    movq $1, %rdi
    leaq token_rcurly, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_lbracket:
    movq $1, %rax
    movq $1, %rdi
    leaq token_lbracket, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_rbracket:
    movq $1, %rax
    movq $1, %rdi
    leaq token_rbracket, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_print:
    movq $1, %rax
    movq $1, %rdi
    leaq token_print, %rsi
    movq $5, %rdx
    syscall
    callq println
    jmp _llopers
print_eop:
    movq $1, %rax
    movq $1, %rdi
    leaq token_eop, %rsi
    movq $3, %rdx
    syscall
    callq println
    jmp end_start

print_while:
    movq $1, %rax
    movq $1, %rdi
    leaq token_while, %rsi
    movq $5, %rdx
    syscall
    callq println
    jmp _llopers
print_plus:
    movq $1, %rax
    movq $1, %rdi
    leaq token_plus, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_minus:
    movq $1, %rax
    movq $1, %rdi
    leaq token_minus, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_times:
    movq $1, %rax
    movq $1, %rdi
    leaq token_times, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_div:
    movq $1, %rax
    movq $1, %rdi
    leaq token_div, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_less:
    movq $1, %rax
    movq $1, %rdi
    leaq token_less, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_greater:
    movq $1, %rax
    movq $1, %rdi
    leaq token_greater, %rsi
    movq $1, %rdx
    syscall
    callq println
    jmp _llopers
print_true:
    movq $1, %rax
    movq $1, %rdi
    leaq token_true, %rsi
    movq $4, %rdx
    syscall
    callq println
    jmp _llopers
print_false:
    movq $1, %rax
    movq $1, %rdi
    leaq token_false, %rsi
    movq $5, %rdx
    syscall
    callq println
    jmp _llopers
print_let:
    movq $1, %rax
    movq $1, %rdi
    leaq token_struct, %rsi
    movq $6, %rdx
    syscall
    callq println
    jmp _llopers
print_and:
    movq $1, %rax
    movq $1, %rdi
    leaq token_and, %rsi
    movq $2, %rdx
    syscall
    callq println
    jmp _llopers
print_or:
    movq $1, %rax
    movq $1, %rdi
    leaq token_or, %rsi
    movq $2, %rdx
    syscall
    callq println
    jmp _llopers
print_identifier:

    movq %rbx, %rdi
    callq retrieve_identifier

    movq %rax, %rsi
    movq $1, %rax
    movq $1, %rdi
    movq $100, %rdx # dumb number.
    syscall
    callq println
    jmp _llopers
print_number:

    movq %rbx, %rdi
    callq retrieve_number
    movq %rax, %rdi
    
    push %rbp
        mov %rsp, %rbp
        # Because syscalls are slow, we will opt to first count the length of the number. And then print it. This means we will iterate over it twice

        movq %rdi, %rax
        xor %rcx, %rcx # Counter
        movq $10, %rbx
    begin_count:
        cqto
        idivq %rbx
        inc %rcx
        test %rax, %rax
        jnz begin_count

        # We will now pack the numbers in a char * We must remember that the stack grows negative. For that reason we will need to push it in reverse order on the stack in order for the write syscall to not print in reverse.

        # Make room on the stack for char *
        subq %rcx, %rsp
        # Ensure correct alignment
        // 4 - (rcx % 4) = correction
        movq %rcx, %rax
        cqto
        movq $4, %rbx
        idivq %rbx 
        # We now have the remainder in %rdx
        subq %rdx, %rbx # This is the correction amount
        subq %rbx, %rsp
        # We now have correct alignment
        movq $10, %rbx
        movq %rcx, %r8 # Store the count
        movq %rdi, %rax
        # Push the char * to stack
    begin_push:
        cqto
        idivq %rbx
        addb $48, %dl
        dec %r8
        movb %dl, (%rsp, %r8, 1)
        test %r8, %r8
        jnz begin_push

        movq $1, %rax
        movq $1, %rdi
        leaq (%rsp), %rsi
        movq %rcx, %rdx
        syscall
        leave
    callq println
    jmp _llopers


end_start:
    leave
    movq $60, %rax
    movq $0, %rdi
    syscall


println:
    movq $1, %rax
    movq $1, %rdi
    leaq newline, %rsi
    movq $1, %rdx
    syscall
    ret
    