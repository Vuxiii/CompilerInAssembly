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

_current_token_id_:             .int 0
_peek_token_id_:                .int 0
_token_data_:                   .int 0
_peek_data_:                    .int 0



.global function_buffer
        function_buffer:        .space 256
.global statement_list_buffer
        statement_list_buffer:  .space 256
.global assignment_buffer
        assignment_buffer:      .space 256
.global binary_op_buffer
        binary_op_buffer:       .space 256
binary_op_offset:               .int 0
assignment_offset:              .int 0
statement_list_offset:          .int 0
.global function_offset
        function_offset:        .int 0


.section .text

// out rax: token_id
// out rbx: descriptor
.type parse, @function
.global parse
parse:
        push %rbp
        mov %rsp, %rbp 
        call next_token # Move the first token into peek
        // We start by parsing a expression
        callq parse_statement

        leave
        ret

// out rax: token_id
// out rbx: descriptor
.type parse_statement, @function
parse_statement:
        push %rbp
        mov %rsp, %rbp

        call peek_token_id
        
        # Check if we have an identifier
        # statement ::= 'identifier' '=' expression
        cmp $24, %rax
        je maybe_assignment
        cmp $1, %rax
        je function_statement


        jmp node_is_not_statement

    function_statement:

        # eat the def
        call next_token
        # Do we have an identifier?
        call peek_token_id
        cmp $24, %rax
        jne node_is_not_statement # Parse error!

        # We have an identifier
        # Check for '(' ')'
        # Currently no args

        call next_token
        # Store the identifier descriptor
        call current_token_data
        push %rax # Store identifier

        call peek_token_id
        cmp $5, %rax # '('
        jne node_is_not_statement # Parse error!
        call next_token
        
        call peek_token_id
        cmp $6, %rax # ')'
        jne node_is_not_statement # Parse error!
        call next_token
        
        call peek_token_id
        cmp $7, %rax # '{'
        jne node_is_not_statement # Parse Error! Expected token: '{'
        call next_token 

        # Try to parse the statement
        call parse_statement
        cmp $0, %rax
        je node_is_not_statement # Parse Error. No Statement present
        
        push %rax # Store
        push %rbx # Store

        # Check '}'
        call peek_token_id
        cmp $8, %rax
        jne node_is_not_statement # Parse error! Expected token: '}'

        # Remove the '}'
        call next_token

        # We have a good function. Construct it and return

        pop %rdx # body descriptor
        pop %rsi # body id
        pop %rdi # identifier descriptor
        call construct_function_node
        push $30
        push %rax

        jmp check_statement_list

    maybe_assignment:
        // Check the assignment '='
        call next_token
        # current_token_id: identifier
        call peek_token_id
        cmp $4, %rax # Is it '='?
        jne node_is_not_statement # Handle other possibilities like function calls here

        # current_token_id: identifier
        # peek_token_id:    '='
        call current_token_data
        push %rax
        call next_token
        # Parse the right hand side of the assignment
        call parse_expression
        // rax: token_id of output from parse_expression
        // rbx: its token_descriptor
        push %rax
        push %rbx

        # We now have the following:
        # │ expr_descriptor│
        # │    expr_id     │ 
        # │   identifier   │
        # │      ...       │
        # └────────────────┘
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_assignment_node
        push $29  # Store the assignment id
        push %rax # Store the assignment descriptor
    
    check_statement_list:
        call parse_statement
        # Check if it was successfull
        cmp $0, %rax
        je single_statement

        push %rax
        push %rbx

        # We now have the following:
        # │token_descriptor│
        # │    token_id    │ statement ??
        # │token_descriptor│
        # │    token_id    │ statement ??
        # │      ...       │
        # └────────────────┘

        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_statement_list
        movq %rax, %rbx
        movq $28, %rax
        leave
        ret

    single_statement:
        # Store results
        pop %rbx # Descriptor
        pop %rax # Token ID
        leave
        ret

    statement_is_not_assignment_restore_last_token:
        pop %rbx
        pop %rax
        leave
        ret
    node_is_not_statement:
        movq $0, %rax # None
        leave
        ret

.type parse_expression, @function
// out rax: token_id
// out rbx: descriptor
parse_expression:
        push %rbp
        mov %rsp, %rbp

        # Check if we are dealing with a number

        # We can have:
        # [1]: parse_sum
        # [2]: parse_func_call
        call parse_sum
        leave
        ret

    .type parse_sum, @function
    parse_sum:
            # We can have:
            # [1]: parse_mult + parse_expression
            # [2]: parse_mult - parse_expression
            # [3]: parse_mult
            push %rbp
            mov %rsp, %rbp
            # Parse the mult
            call parse_mult
            push %rax
            push %rbx
        check_sum:
            # Check for operator
            call peek_token_id
            cmp $13, %rax
            je parse_sum_return_plus
            cmp $14, %rax
            je parse_sum_return_minus
        
        # Case [3]
            pop %rbx
            pop %rax
            leave
            ret
        parse_sum_return_plus:
        # Case [1]
            call next_token
            call parse_mult
            # LHS
            pop %r8
            pop %rcx
            # operator
            movq $13, %rdx
            movq %rax, %rdi
            movq %rbx, %rsi
            call construct_binary_op_node
            push $26
            push %rax
            jmp check_sum
        parse_sum_return_minus:
        # Case [2]
            call next_token
            call parse_mult
            # LHS
            pop %r8
            pop %rcx
            # operator
            movq $14, %rdx
            movq %rax, %rdi
            movq %rbx, %rsi
            call construct_binary_op_node
            push $26
            push %rax
            jmp check_sum
        
    .type parse_mult, @function
    parse_mult:

            # We can have:
            # [1]: parse_token * parse_mult
            # [2]: parse_token / parse_mult
            # [3]: parse_token
            push %rbp
            mov %rsp, %rbp
            # Parse the token
            call parse_token
            push %rax
            push %rbx
        check_mult:    
            # Check for operator
            call peek_token_id
            cmp $15, %rax
            je parse_mult_return_times
            cmp $16, %rax
            je parse_mult_return_div

        # Case [3]
            pop %rbx
            pop %rax
            leave
            ret
        parse_mult_return_times:
        # Case [1]
            call next_token
            call parse_token
            # LHS
            pop %r8
            pop %rcx
            # operator
            movq $15, %rdx
            movq %rax, %rdi
            movq %rbx, %rsi
            call construct_binary_op_node
            push $26
            push %rax
            jmp check_mult
        parse_mult_return_div:
        # Case [2]
            call next_token
            call parse_token
            # LHS
            pop %r8
            pop %rcx
            # operator
            movq $16, %rdx
            movq %rax, %rdi
            movq %rbx, %rsi
            call construct_binary_op_node
            push $26
            push %rax
            jmp check_mult

    .type parse_token, @function
    parse_token:
            # We can have:
            # [1]: '(' expr ')'
            # [2]: 'number'
            # [2]: 'identifier'
            push %rbp
            mov %rsp, %rbp
            call peek_token_id
            cmp $25, %rax
            je parse_token_return_number
            cmp $24, %rax
            je parse_token_return_identifier
        # Case [1]
            # Consume the '('
            call next_token
            call parse_expression
            push %rax
            push %rbx
            # Consume the ')'
            call next_token
            pop %rbx
            pop %rax
            leave
            ret
        parse_token_return_number:
        # Case [2]
            call next_token
            call current_token_data
            movq %rax, %rbx
            call current_token_id
            leave
            ret
        parse_token_return_identifier:
        # Case [3]
            call next_token
            call current_token_data
            movq %rax, %rbx
            call current_token_id
            leave
            ret

// in rdi: lhs id
// in rsi: lhs descriptor
// in rdx: rhs id
// in rcx: rhs descriptor
// out:    assignment descriptor
.type construct_statement_list, @function
construct_statement_list:
        push %rbp
        mov %rsp, %rbp
        
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov statement_list_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # mulq uses rdx...
        movq $16, %rdx # Size of assignment (16 bytes)
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea statement_list_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)

        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (statement_list_offset)(%rip)

        leave
        ret

// in rdi: identifier_descriptor
// in rsi: expr_id
// in rdx: expr_descriptor
// out:    assignment descriptor
.type construct_assignment_node, @function
construct_assignment_node:
        push %rbp
        mov %rsp, %rbp
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov assignment_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # mulq uses rdx...
        movq $12, %rdx # Size of assignment (12 bytes)
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea assignment_buffer(%rip), %rax
        mov %edi, (%rax, %rbx)
        mov %esi, 4(%rax, %rbx)
        mov %edx, 8(%rax, %rbx)

        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (assignment_offset)(%rip)

        leave
        ret

// in rdi: rhs token_id
// in rsi: rhs token_descriptor
// in rdx: operator_id
// in rcx: lhs token_id
// in r8:  lhs token_descriptor
// out:    binary op descriptor
.type construct_binary_op_node, @function
construct_binary_op_node:
        push %rbp
        mov %rsp, %rbp 
        xor %rbx, %rbx
        xor %rax, %rax
        mov binary_op_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        # Ensure that we are offset by the correct size of each struct -> ebx * sizeof(binaryop) -> ebx * 20 bytes
        push %rdx # mulq uses rdx...
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
    // p (int[5])*0x202fee
        lea binary_op_buffer(%rip), %rax
        
        mov %ecx, (%rax, %rbx)
        mov %r8,  4(%rax, %rbx)
        mov %edx, 8(%rax, %rbx)
        mov %edi, 12(%rax, %rbx)
        mov %esi, 16(%rax, %rbx)
        
        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (binary_op_offset)(%rip)

        leave
        ret


// in rdi: identifier
// in rsi: body id
// in rdx: body descriptor
// out:    function descriptor
.type construct_function_node, @function
construct_function_node:
        push %rbp
        mov %rsp, %rbp 
        xor %rbx, %rbx
        xor %rax, %rax
        mov function_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        # Ensure that we are offset by the correct size of each struct -> ebx * sizeof(binaryop) -> ebx * 20 bytes
        push %rdx # mulq uses rdx...
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
    // p (int[5])*0x202fee
        lea function_buffer(%rip), %rax
        
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        movl $0,  12(%rax, %rbx)
        movl $0,  16(%rax, %rbx)
        
        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (function_offset)(%rip)

        leave
        ret

// in rdi: Token descriptor
// out 16(%rbp): lhs id
// out 24(%rbp): lhs descriptor
// out 32(%rbp): rhs id
// out 40(%rbp): rhs descriptor
.type retrieve_statement_list, @function
.global retrieve_statement_list
retrieve_statement_list:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea statement_list_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi # lhs id
        mov  4(%rax, %rbx), %esi # lhs desc
        mov  8(%rax, %rbx), %edx # rhs id
        mov 12(%rax, %rbx), %ecx # rhs desc
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

        leave
        ret



// in rdi: Token descriptor
// out 16(%rbp): lhs id
// out 24(%rbp): lhs descriptor
// out 32(%rbp): operator id
// out 40(%rbp): rhs id
// out 48(%rbp): rhs descriptor
.type retrieve_binary_op, @function
.global retrieve_binary_op
retrieve_binary_op:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea binary_op_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi # lhs id
        mov  4(%rax, %rbx), %esi # lhs desc
        mov  8(%rax, %rbx), %edx # op id
        mov 12(%rax, %rbx), %ecx # rhs id
        mov 16(%rax, %rbx), %r8d # rhs desc
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)
        mov %r8d, 48(%rbp)

        leave
        ret

// in rdi: Token descriptor
// out 16(%rbp): identifier
// out 24(%rbp): body id
// out 32(%rbp): body descriptor
// out 40(%rbp): variable count int
// out 48(%rbp): symbol table descriptor
.type retrieve_function, @function
.global retrieve_function
retrieve_function:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea function_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi # identifier
        mov  4(%rax, %rbx), %esi # body id
        mov  8(%rax, %rbx), %edx # body descriptor
        mov 12(%rax, %rbx), %ecx # variable count int
        mov 16(%rax, %rbx), %r8d # symbol table descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)
        mov %r8d, 48(%rbp)

        leave
        ret

// in rdi: token descriptor
// out  4(%rbp): identifier descriptor
// out  8(%rbp): expr id
// out 12(%rbp): expr descriptor
.type retrieve_assignment, @function
.global retrieve_assignment
retrieve_assignment:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $12, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea assignment_buffer(%rip), %rax
        xor %rdi, %rdi
        xor %rsi, %rsi
        xor %rdx, %rdx
        mov   (%rax, %rbx), %edi # identifier descriptor
        mov  4(%rax, %rbx), %esi # expr id
        mov  8(%rax, %rbx), %edx # expr descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)

        leave
        ret


.type push_token_id, @function
push_token_id:
        push %rbp
        mov %rsp, %rbp
        mov %edi, _current_token_id_(%rip)
        leave
        ret

.type push_token_descriptor, @function
push_token_descriptor:
        push %rbp
        mov %rsp, %rbp
        mov %edi, _token_data_(%rip)
        leave
        ret



.type current_token_id, @function
current_token_id:
        push %rbp
        mov %rsp, %rbp
        mov _current_token_id_(%rip), %eax
        leave
        ret

.type current_token_data, @function
current_token_data:
        push %rbp
        mov %rsp, %rbp
        mov _token_data_(%rip), %eax
        leave
        ret

.type peek_token_id, @function
peek_token_id:
        push %rbp
        mov %rsp, %rbp
        mov _peek_token_id_(%rip), %eax
        leave
        ret

.type peek_token_data, @function
peek_token_data:
        push %rbp
        mov %rsp, %rbp
        mov _peek_data_(%rip), %eax
        leave
        ret

.type next_token, @function
next_token:
        push %rbp
        mov %rsp, %rbp
        # Move peek into current
        call peek_token_id
        mov %eax, %edi
        call push_token_id
        call peek_token_data
        mov %eax, %edi
        call push_token_descriptor

        callq get_token
        mov %eax, _peek_token_id_(%rip)
        mov %ebx, _peek_data_(%rip)
        leave
        ret
