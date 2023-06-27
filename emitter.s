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


.extern number_0
.extern number_9

.extern assignment_buffer:      .space 256
.extern binary_op_buffer:       .space 256

.extern _emit_asm_prologue
.extern _emit_function_prologue
.extern _emit_function_epilogue
.extern _emit_asm_epilogue
.extern _emit_push
.extern _emit_pop
.extern _emit_add
.extern _emit_sub
.extern _emit_lea
.extern _emit_call
.extern _emit_ret
.extern _emit_jmp
.extern _emit_jne
.extern _emit_je
.extern _emit_jle
.extern _emit_jge
.extern _emit_rax
.extern _emit_rbx
.extern _emit_rcx
.extern _emit_rdx
.extern _emit_rdi
.extern _emit_rsi
.extern _emit_comma
.extern _emit_colon
.extern _emit_dollar
.extern _emit_newline_tab

.section .text
.global emit
// in rdi: Token id
// in rsi: Token descriptor
.type emit, @function
emit:
        push %rbp
        mov %rsp, %rbp 
        push %rdi
        push %rsi
        // callq emit_asm_prologue
        // callq emit_function_prologue

        pop %rsi
        pop %rdi
        callq visit_statement

        // callq emit_asm_epilogue

        leave
        ret

// in rdi: Token id
// in rsi: Token descriptor
.type visit_statement, @function
visit_statement:
        push %rbp
        mov %rsp, %rbp

        cmp $29, %rdi
        je assignment
        cmp $28, %rdi
        je statement_list
        cmp $30, %rdi
        je function
        leave
        ret

    function:
        movq %rsi, %rdi
        push $696969
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_function
        
        call emit_newline

        pop %rdi # Identifier
        call emit_identifier
        call emit_colon
        call emit_function_prologue        
        pop %rsi # body id
        pop %rdx # body descriptor
        pop %rcx # var count
        pop %r8  # symbol_table offset



        movq %rsi, %rdi
        movq %rdx, %rdi
        call visit_statement
        
        call emit_function_epilogue

        leave
        ret
    statement_list:

        movq %rsi, %rdi
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_statement_list
        # LHS
        pop %rdi
        pop %rsi
        call visit_statement
        pop %rdi
        pop %rsi
        call visit_statement
        leave
        ret

    assignment:
        // subq $24, %rsp
        push $696969
        push $696969
        push $696969
        movq %rsi, %rdi
        callq retrieve_assignment
        pop %rax
        pop %rdi # expr id
        pop %rsi # expr descriptor
        push %rax # Store the descripor for the identifier

        callq visit_expression

        leave
        ret

// in rdi: Token id
// in rsi: Token descriptor
.type visit_expression, @function
visit_expression:
        push %rbp
        mov %rsp, %rbp

        cmp $26, %rdi # Binary op
        je binary
        cmp $25, %rdi # Number
        je number

        # It was neither a binary op nor a number
        leave 
        ret
    binary:
        
        # Just eval the expression
        # subq $20, %rsp  # Make space for return values
        push $696969
        push $696969
        push $696969
        push $696969
        push $696969
        movq %rsi, %rdi # Move descriptor
        callq retrieve_binary_op 

        # Evaluate the LHS

        pop %rdi # lhs id
        pop %rsi # lhs descriptor

        callq visit_expression

        # Evaluate the RHS

        pop %rdx  # operator id
        pop %rdi  # rhs id
        pop %rsi  # rhs descriptor 
        push %rdx # Store operator
        callq visit_expression

        # Both children have now been evaluated
        callq emit_pop
        callq emit_rbx
        callq emit_pop
        callq emit_rax
        pop %rdx # Restore operator
        cmp $13, %rdx
        je insert_add
        cmp $14, %rdx
        je insert_sub
        leave
        ret

    number:
        # We have found a 'number'
        push %rsi
        callq emit_push
        callq emit_dollar
        # Retrieve the number
        pop %rdi
        callq retrieve_number
        movq %rax, %rdi
        callq emit_number
        callq emit_newline_tab
        leave
        ret

    insert_add:
        callq emit_add
        callq emit_rax
        callq emit_comma
        callq emit_rbx
        callq emit_push
        callq emit_rbx
        callq emit_newline_tab
        leave 
        ret
    insert_sub:
        callq emit_sub
        callq emit_rax
        callq emit_comma
        callq emit_rbx
        callq emit_push
        callq emit_rbx
        callq emit_newline_tab
        leave 
        ret

// in rdi: The number to be displayed
.type emit_number, @function
emit_number:
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
        ret

.type emit_asm_prologue, @function
emit_asm_prologue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_asm_prologue, %rsi
        movq $31, %rdx
        syscall
        leave
        ret
.type emit_function_prologue, @function
emit_function_prologue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_function_prologue, %rsi
        movq $28, %rdx
        syscall
        leave
        ret
.type emit_function_epilogue, @function
emit_function_epilogue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_function_epilogue, %rsi
        movq $13, %rdx
        syscall
        leave
        ret
.type emit_asm_epilogue, @function
emit_asm_epilogue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_asm_epilogue, %rsi
        movq $48, %rdx
        syscall
        leave
        ret
.type emit_push, @function
emit_push:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_push, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_pop, @function
emit_pop:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_pop, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_add, @function
emit_add:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_add, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_sub, @function
emit_sub:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_sub, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_lea, @function
emit_lea:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_lea, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_call, @function
emit_call:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_call, %rsi
        movq $8, %rdx
        syscall
        leave
        ret
.type emit_ret, @function
emit_ret:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_ret, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_jmp, @function
emit_jmp:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jmp, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_jne, @function
emit_jne:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jne, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_je, @function
emit_je:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_je, %rsi
        movq $5, %rdx
        syscall
        leave
        ret
.type emit_jle, @function
emit_jle:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jle, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_jge, @function
emit_jge:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jge, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_rax, @function
emit_rax:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rax, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rbx, @function
emit_rbx:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rbx, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rcx, @function
emit_rcx:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rcx, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rdx, @function
emit_rdx:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rdx, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rdi, @function
emit_rdi:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rdi, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rsi, @function
emit_rsi:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rsi, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_comma, @function
emit_comma:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_comma, %rsi
        movq $2, %rdx
        syscall
        leave
        ret
.type emit_colon, @function
emit_colon:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_colon, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_dollar, @function
emit_dollar:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_dollar, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_newline, @function
emit_newline:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_newline, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_newline_tab, @function
emit_newline_tab:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_newline_tab, %rsi
        movq $2, %rdx
        syscall
        leave
        ret
// in rdi: string descriptor
.type emit_identifier, @function
emit_identifier:
        push %rbp
        mov %rsp, %rbp
        call retrieve_identifier
        xor %rcx, %rcx

    count_len:
        movb (%rax, %rcx, 1), %bl
        inc %rcx
        test %bl, %bl
        jnz count_len

        movq %rax, %rsi
        movq $1, %rax
        movq $1, %rdi
        movq %rcx, %rdx
        syscall
        leave
        ret
