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
    