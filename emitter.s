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
        call emit_asm_prologue
        call emit_function_prologue
        call emit_call
        call emit_main
        call emit_asm_epilogue
        
        

        pop %rsi
        pop %rdi
        call visit_statement


        # My print implementation
        # Expects value to print in rdi
        call emit_newline
        call emit_print
        call emit_colon
        call emit_function_prologue
        call emit_print_body
        call emit_function_epilogue

        leave
        ret

// in rdi: Token id
// in rsi: Token descriptor
.type visit_statement, @function
visit_statement:
        push %rbp
        mov %rsp, %rbp

        cmp $29, %rdi
        je visit_assignment
        cmp $28, %rdi
        je visit_statement_list
        cmp $30, %rdi
        je visit_function
        cmp $31, %rdi
        je visit_if
        cmp $32, %rdi
        je visit_while
        cmp $39, %rdi
        je visit_print
        leave
        ret

    visit_print:
        movq %rsi, %rdi
        push $696969
        push $696969
        call retrieve_print
        pop %rdi # Expr id
        pop %rsi # expr descriptor

        call visit_expression

        call emit_pop
        call emit_rdi

        call emit_call

        call emit_print

        leave
        ret
    visit_if:
        mov %rsi, %rdi
        push %rdi # Store the id of the if statement for use in the label
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_if
        pop %rdi
        pop %rsi
        call visit_expression


        call emit_pop
        call emit_rax
        call emit_cmp
        call emit_dollar
        movq $1, %rdi
        call emit_number
        call emit_comma
        call emit_rax
        call emit_jne
        
        # Construct the end of body label
        call emit_if
        pop %rax 
        pop %rbx
        pop %rdi # The descriptor of this if statement
        push %rdi
        push %rbx
        push %rax 
        call emit_number

        pop %rdi
        pop %rsi
        call visit_statement
        
        # Insert the end of body label
        call emit_newline
        call emit_if
        pop %rdi
        call emit_number
        call emit_colon
        leave 
        ret

    visit_while:
        mov %rsi, %rdi
        push %rdi # Store the id of the while statement for use in the label
        
        # Construct the enter-guard label
        
        call emit_newline
        call emit_guard
        pop %rdi
        push %rdi
        call emit_number
        call emit_colon
        
        pop %rdi
        push %rdi
        
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_while
        pop %rdi
        pop %rsi
        call visit_expression


        call emit_pop
        call emit_rax
        call emit_cmp
        call emit_dollar
        movq $1, %rdi
        call emit_number
        call emit_comma
        call emit_rax
        call emit_jne
        
        # Construct the end of body label
        call emit_while
        pop %rax 
        pop %rbx
        pop %rdi # The descriptor of this if statement
        push %rdi
        push %rbx
        push %rax 
        call emit_number

        pop %rdi
        pop %rsi
        call visit_statement
        
        # Insert jump to enter-guard label
        call emit_jmp
        call emit_guard
        pop %rdi
        push %rdi
        call emit_number

        # Insert the end of body label
        call emit_newline
        call emit_while
        pop %rdi
        call emit_number
        call emit_colon
        leave 
        ret

    visit_function:
        movq %rsi, %rdi
        call set_current_function
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
        
        # Make place for local vars on the stack 
        call emit_sub
        call emit_dollar

        pop %rsi # body id
        pop %rdx # body descriptor
        pop %rax # var count
        push %rdx
        push %rsi

        movq $8, %rdx
        imulq %rdx
        movq %rax, %rdi
        call emit_number
        call emit_comma
        call emit_rsp
        
        
        pop %rsi
        pop %rdx
        pop %r8  # symbol_table offset
        

        movq %rsi, %rdi
        movq %rdx, %rsi
        call visit_statement
        
        call emit_function_epilogue

        leave
        ret
    visit_statement_list:

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

    visit_assignment:
        // subq $24, %rsp
        push $696969 # expression descriptor
        push $696969 # expression id
        push $696969 # identifier descriptor
        push $696969 # identifier id
        movq %rsi, %rdi
        call retrieve_assignment
        movq 16(%rsp), %rdi # expr id
        movq 24(%rsp), %rsi # expr descriptor
        
        call visit_expression

        call emit_newline_tab

        call emit_pop
        call emit_rax

        call emit_mov
        call emit_rax
        call emit_comma
        call emit_minus

        movq  (%rsp), %rsi # id
        movq 8(%rsp), %rdi # descriptor
        call emit_var

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
        cmp $24, %rdi # identifier
        je identifier
        cmp $36, %rdi # field
        je identifier
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
        cmp $15, %rdx
        je insert_mul
        cmp $3, %rdx
        je insert_equals
        cmp $17, %rdx
        je insert_less
        cmp $18, %rdx
        je insert_greater
        cmp $27, %rdx
        je insert_noteq
        leave
        ret

    identifier:
        push %rdi
        push %rsi
        call emit_mov
        call emit_minus
        
        pop %rdi
        pop %rsi
        call emit_var

        call emit_comma
        call emit_rax
        call emit_push
        call emit_rax
        leave
        ret

    field:
        push %rdi
        push %rsi
        call emit_mov
        call emit_minus
        
        pop %rdi
        pop %rsi
        call emit_var

        call emit_comma
        call emit_rax
        call emit_push
        call emit_rax
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
    insert_mul:
        callq emit_mul
        callq emit_rax
        callq emit_comma
        callq emit_rbx
        callq emit_push
        callq emit_rbx
        callq emit_newline_tab
        leave 
        ret
    insert_equals:
        call insert_comparison_prologue
        call emit_cmove
        call insert_comparison_epilogue
        leave 
        ret
    insert_noteq:
        call insert_comparison_prologue
        call emit_cmovz
        call insert_comparison_epilogue
        leave 
        ret
    insert_less:
        call insert_comparison_prologue
        call emit_cmovl
        call insert_comparison_epilogue
        leave 
        ret
    insert_greater:
        call insert_comparison_prologue
        call emit_cmovg
        call insert_comparison_epilogue
        ret
    insert_comparison_prologue:
        push %rbp
        mov %rsp, %rbp

        # Set up for true
        call emit_mov
        call emit_dollar
        movq $1, %rdi
        call emit_number
        call emit_comma
        call emit_rdx

        # Default to false
        call emit_mov
        call emit_dollar
        movq $0, %rdi
        call emit_number
        call emit_comma
        call emit_rcx

        call emit_cmp
        call emit_rax
        call emit_comma
        call emit_rbx

        leave
        ret
    insert_comparison_epilogue:
        push %rbp
        mov %rsp, %rbp

        call emit_rdx
        call emit_comma
        call emit_rcx
        call emit_push
        call emit_rcx
        call emit_newline_tab

        leave
        ret
    

// in rdi: the descriptor of the identifier
// in rsi: the type of the field/identifier
.type emit_var, @function
emit_var:
        push %rbp
        mov %rsp, %rbp
        # We need to check if this is array access.
        cmp $41, %rsi
        je emit_var_array_access

        call get_offset_on_stack
        movq $8, %rdx
        imulq %rdx
        
        movq %rax, %rdi
        call emit_number

        call emit_lparen
        call emit_rbp
        call emit_rparen
        leave
        ret
    emit_var_array_access:
        # arr = [0, 1, 2, 3]
        #    8--^ 16^24^32^
        # base offset + stride * index 
        push $69 # index
        push $69 # identifier descriptor
        push $69 # identifier id
        call retrieve_array_access
        movq  (%rsp), %rsi
        movq 8(%rsp), %rdi
        call get_offset_on_stack
        movq $8, %rdx
        imulq %rdx
        push %rax # Base offset
        
        movq 24(%rsp), %rdi
        call retrieve_number
        push %rax # index

        movq 8(%rsp), %rdi
        call find_array_assignment_by_identifier
        movq %rax, %rdi
        push $69 # stride
        push $69 # count
        push $69 # identifier descriptor
        push $69 # identifier id
        call retrieve_array_assignment

        movq 24(%rsp), %rbx # stride
        movq 32(%rsp), %rax # index
        imulq %rbx
        movq 40(%rsp), %rdi # base offset
        addq %rax, %rdi
        call emit_number

        call emit_lparen
        call emit_rbp
        call emit_rparen
        leave
        ret

// in rdi: The number to be displayed
.type emit_number, @function
.global emit_number
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

.type emit_print_body, @function
emit_print_body:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_print_body, %rsi
        movq $582, %rdx
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
        movq $38, %rdx
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
.type emit_main, @function
emit_main:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_main, %rsi
        movq $4, %rdx
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
.type emit_mov, @function
emit_mov:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_mov, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_cmove, @function
emit_cmove:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_cmove, %rsi
        movq $9, %rdx
        syscall
        leave
        ret
.type emit_cmovz, @function
emit_cmovz:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_cmovz, %rsi
        movq $9, %rdx
        syscall
        leave
        ret
.type emit_cmovg, @function
emit_cmovg:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_cmovg, %rsi
        movq $9, %rdx
        syscall
        leave
        ret
.type emit_cmovl, @function
emit_cmovl:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_cmovl, %rsi
        movq $9, %rdx
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
.type emit_mul, @function
emit_mul:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_mul, %rsi
        movq $8, %rdx
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
.type emit_cmp, @function
emit_cmp:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_cmp, %rsi
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
.type emit_rbp, @function
emit_rbp:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rbp, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rsp, @function
emit_rsp:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rsp, %rsi
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
.global emit_colon
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
.type emit_minus, @function
emit_minus:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_minus, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_lparen, @function
emit_lparen:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_lparen, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_rparen, @function
emit_rparen:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rparen, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_newline, @function
.global emit_newline
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
.global emit_identifier
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
        
        dec %rcx # Remove '\0'

        movq %rax, %rsi
        movq $1, %rax
        movq $1, %rdi
        movq %rcx, %rdx
        syscall
        leave
        ret

.type emit_print, @function
emit_print:
        push %rbp
        movq %rsp, %rbp
        movq $1, %rax
        movq $1, %rdi
        leaq token_print, %rsi
        movq $5, %rdx
        syscall
        leave
        ret

.type emit_if, @function
emit_if:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq token_if, %rsi
        movq $2, %rdx
        syscall
        leave
        ret
.type emit_while, @function
emit_while:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq token_while, %rsi
        movq $5, %rdx
        syscall
        leave
        ret
.type emit_guard, @function
emit_guard:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_guard, %rsi
        movq $5, %rdx
        syscall
        leave
        ret
