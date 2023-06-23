.data

.extern eop        # -1
.extern none       # 0
.extern def        # 1
.extern if         # 2
.extern equals     # 3
.extern assignment # 4
.extern lparen     # 5
.extern rparen     # 6
.extern lcurly     # 7
.extern rcurly     # 8
.extern lbracket   # 9
.extern rbracket   # 10
.extern print      # 11
.extern number     # 12
.extern identifier # 13



.section .text
.global _start
_start:
    movq $in, %rdi
    push %rdi
_llopers:
    pop %rdi

    callq get_token
    inc %rdi
    push %rdi

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
    cmp $-1, %rax 
    je print_eop
    
    
    movq $1, %rax
    movq $1, %rdi
    leaq none, %rsi
    movq $5, %rdx
    syscall
    jmp end_start
print_def:
    movq $1, %rax
    movq $1, %rdi
    leaq def, %rsi
    movq $4, %rdx
    syscall
    jmp _llopers
print_if:
    movq $1, %rax
    movq $1, %rdi
    leaq if, %rsi
    movq $3, %rdx
    syscall
    jmp _llopers
print_equals:
    movq $1, %rax
    movq $1, %rdi
    leaq equals, %rsi
    movq $3, %rdx
    syscall
    jmp _llopers
print_assignment:
    movq $1, %rax
    movq $1, %rdi
    leaq assignment, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_lparen:
    movq $1, %rax
    movq $1, %rdi
    leaq lparen, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_rparen:
    movq $1, %rax
    movq $1, %rdi
    leaq rparen, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_lcurly:
    movq $1, %rax
    movq $1, %rdi
    leaq lcurly, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_rcurly:
    movq $1, %rax
    movq $1, %rdi
    leaq rcurly, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_lbracket:
    movq $1, %rax
    movq $1, %rdi
    leaq lbracket, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_rbracket:
    movq $1, %rax
    movq $1, %rdi
    leaq rbracket, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_print:
    movq $1, %rax
    movq $1, %rdi
    leaq print, %rsi
    movq $6, %rdx
    syscall
    jmp _llopers
print_eop:
    movq $1, %rax
    movq $1, %rdi
    leaq eop, %rsi
    movq $4, %rdx
    syscall
    jmp end_start
    // callq main_loop

    // movq $def, %rdi
    // callq cmp_string

//     cmp $0, %ax
//     je print_false
//     movq $1, %rax
//     movq $1, %rdi
//     leaq true, %rsi
//     movq $5, %rdx
//     syscall
//     jmp end_start

// print_false:
//     movq $1, %rax
//     movq $1, %rdi
//     leaq false, %rsi
//     movq $6, %rdx
//     syscall

end_start:
    movq $60, %rax
    movq $0, %rdi
    syscall

// in  %rdi: The buffer to find the next token
// out %rax: The id of the token. See header
// out %rdi: The buffer at the current location

