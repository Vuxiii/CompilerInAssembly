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


.global array_assignment_buffer
        array_assignment_buffer: .space 256
.global array_access_buffer
        array_access_buffer: .space 256
.global print_statement_buffer
        print_statement_buffer: .space 256
.global struct_instance_buffer
        struct_instance_buffer: .space 256
.global struct_type_buffer
        struct_type_buffer:     .space 256
.global struct_buffer 
        struct_buffer:          .space 256
.global field_access_buffer
        field_access_buffer:    .space 256
.global function_buffer
        function_buffer:        .space 256
.global if_buffer
        if_buffer:              .space 256
.global while_buffer
        while_buffer:           .space 256
.global statement_list_buffer
        statement_list_buffer:  .space 256
.global assignment_buffer
        assignment_buffer:      .space 256
.global binary_op_buffer
        binary_op_buffer:       .space 256
field_access_offset:            .int 0
binary_op_offset:               .int 0
assignment_offset:              .int 0
statement_list_offset:          .int 0
if_offset:                      .int 0
while_offset:                   .int 0
struct_offset:                  .int 0
struct_type_offset:             .int 0
struct_instance_offset:         .int 0
print_statement_offset:         .int 0
array_access_offset:            .int 0
array_assignment_offset:        .int 0
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
        cmp $2, %rax
        je if_statement
        cmp $12, %rax
        je while_statement
        cmp $21, %rax
        je struct_statement
        cmp $11, %rax
        je print_statement

        jmp node_is_not_statement


    print_statement:
        # Move the 'print' token to current
        call next_token
        call peek_token_id
        cmp $5, %rax 
        jne node_is_not_statement # Error in parsing '(' not found

        # Move the '(' token to current
        call next_token
        call parse_expression
        push %rax # Store expression ID
        push %rbx # Store expression descriptor

        call peek_token_id
        cmp $6, %rax
        jne node_is_not_statement # Error in parsing ')' not found
        # Move the ')' token to current
        call next_token

        # Construct the print statement

        pop %rsi
        pop %rdi
        call construct_print_node
        push $39
        push %rax
        jmp check_statement_list
    struct_statement:
            # We need to determine if this is a struct declaration or an assignment
            # We do this by checking for the number og identifiers token
            # [1]: A single identifier -> assign
            # [2]: Two identifiers -> decl

            # eat the struct
            call next_token
            # eat the first identifier
            call next_token
            
            # Is the next token an '{' or an 'identifier'
            call peek_token_id
            cmp $24, %rax
            je struct_instance
            
            # This is a struct declaration
            # Store the identifier for the struct definition
            call current_token_data
            movq %rax, %r10


            # Parse the identifiers seperated by ','
            # Count the number of identifiers
            xor %r8, %r8
        struct_field_count:
            inc %r8
            # We have: current -> Identifier
            #          peek    -> ',' or '}'

            # eat the seperator: '{' ',' '}'
            call next_token
            call peek_token_id # Just to check....
            call peek_token_data
            push %rax # Store the field descriptor

            call next_token

            call peek_token_id
            cmp $35, %rax
            je struct_field_count 

            # eat the '}'
            call next_token

            # We have length in rcx
            # We have each field identifier on the stack
            # We can load the address of the stack, and pass it to the constructor method
            mov %r10, %rdi
            leaq (%rsp), %rsi
            mov %r8, %rdx
            call construct_struct_decl_node
            push $33
            push %rax
            movq %rax, %rsi
            movq %r10, %rdi
            call construct_struct_type
            
            jmp check_statement_list
        
        struct_instance:

            # This is an struct instance

            call current_token_data
            movq %rax, %rdi # struct name
            # Find the descriptor
            call find_struct_type_by_name
            movq %rax, %rdi

            call peek_token_data
            movq %rax, %rsi # variable name
            call construct_struct_instance
            push $38
            push %rax
            call next_token # Eat the variable name
            jmp check_statement_list

    while_statement:
        # eat the while
        call next_token
        # eat the '('
        call next_token

        # parse the expression
        call parse_expression
        push %rax # id
        push %rbx # descriptor
        # eat the ')'
        call next_token
        # eat the '{'
        call next_token

        call parse_statement
        push %rax # id
        push %rbx # descriptor

        # eat the '}'
        call next_token

        # Construct the while statement
        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_while_node
        push $32
        push %rax
        
        jmp check_statement_list

    if_statement:
        # eat the if
        call next_token
        # eat the '('
        call next_token

        # parse the expression
        call parse_expression
        push %rax # id
        push %rbx # descriptor
        # eat the ')'
        call next_token
        # eat the '{'
        call next_token

        call parse_statement
        push %rax # id
        push %rbx # descriptor

        # eat the '}'
        call next_token

        # Construct the if statement
        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_if_node
        push $31
        push %rax

        jmp check_statement_list

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
        cmp $37, %rax # dot '.'
        je assignment_field_acces
        cmp $9, %rax # Is it '['
        je assignment_array_identifier

        # We now assume '='

        # current_token_id: identifier
        # peek_token_id:    '='
        call current_token_id
        push %rax
        call current_token_data
        push %rax
    assignment_parse_rhs:
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
        pop %rcx
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
    assignment_array_identifier:
        # Store identifier
        call current_token_id
        push %rax
        call current_token_data
        push %rax
        call next_token
        # current: '['
        # TODO! Add error handling here.
        # For now, just assume it is a number
        call parse_expression
        push %rbx

        call next_token
        # current: ']'

        # At this point, it can either be an array initialization or an array access. We check this by peeking for '='

        call peek_token_id
        cmp $4, %rax
        je assignment_array_identifier_access

        pop %rdx # count
        pop %rsi # descriptor
        pop %rdi # Token id
        movq $8, %rcx # For now, ints are 8 bytes
        call construct_array_assignment
        push $40
        push %rax
        jmp check_statement_list
    assignment_array_identifier_access:
        
        pop %rcx # index descriptor
        pop %rdx # index type
        pop %rsi # identifier descriptor
        pop %rdi # identifier id
        call construct_array_access
        push $41
        push %rax
        jmp assignment_parse_rhs
    assignment_field_acces:
        call current_token_data
        push %rax # Store the variable descriptor
        # Peek has '.'
        call next_token

        call peek_token_data
        push %rax # Store the field descriptor

        pop %rsi
        pop %rdi
        call construct_field_access_node
        push $36
        push %rax
        call next_token
        jmp assignment_parse_rhs
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
        push %rax
        push %rbx
        # Check for '==', '<', '>'
        call peek_token_id
        cmp $3, %rax
        je parse_create_binop # equals
        cmp $17, %rax
        je parse_create_binop # less
        cmp $18, %rax
        je parse_create_binop # greater
        cmp $27, %rax
        je parse_create_binop # noteq
        pop %rbx
        pop %rax
        leave
        ret
    parse_create_binop:
        push %rax
        call next_token
        call parse_sum
        movq %rax, %rdi
        movq %rbx, %rsi
        pop %rdx
        pop %r8
        pop %rcx
        call construct_binary_op_node
        movq %rax, %rbx
        movq $26, %rax
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
    # [3]: 'identifier'
    # [4]: 'identifier' '[' expr ']'
    # [5]: 'identifier' '.' 'identifier'
    # [6]: 'identifier' '.' 'identifier' '[' expr ']'
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
            
            call peek_token_id
            cmp $37, %rax # dot '.'
            je parse_token_return_field_access
            cmp $9, %rax # bracket '['
            je parse_token_return_identifier_array_access

            call current_token_data
            movq %rax, %rbx
            call current_token_id
            leave
            ret
        parse_token_return_identifier_array_access:
        # Case [4]
            call current_token_data
            push %rax
            call current_token_id
            push %rax

            call next_token
            # current: '['

            call parse_expression
            push %rax
            push %rbx

            call next_token
            # current: ']'
            pop %rcx
            pop %rdx
            pop %rdi
            pop %rsi
            call construct_array_access
            movq %rax, %rbx
            movq $41, %rax
            leave
            ret
        parse_token_return_field_access:
        # Case [5]
            call current_token_data
            push %rax
            call next_token # eat '.'
            call next_token # eat 'identifier' - field
            call current_token_data
            movq %rax, %rsi
            pop %rdi
            call construct_field_access_node
            movq %rax, %rbx
            movq $36, %rax
            leave
            ret


// in rdi: name descriptor
// in rsi: struct descriptor
.type construct_struct_type, @function
construct_struct_type:
        push %rbp
        movq %rsp, %rbp

        mov struct_type_offset(%rip), %eax
        push %rax
        
        movq $8, %rdx # Size of struct_type (8 bytes)
        mulq %rdx
        mov %rax, %rbx

        lea struct_type_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax
        inc %eax
        # Store next available descriptor 
        mov %eax, (struct_type_offset)(%rip)
        
        leave
        ret


// in rdi: lhs id
// in rsi: lhs descriptor
// in rdx: rhs id
// in rcx: rhs descriptor
// out:    token descriptor
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
        movq $16, %rdx # Size of statementlist (16 bytes)
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


// in rdi: identifier type
// in rsi: identifier descriptor
// in rdx: count
// in rcx: stride
// out:    token descriptor
.type construct_array_assignment, @function
construct_array_assignment:
        push %rbp
        mov %rsp, %rbp
        
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov array_assignment_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # mulq uses rdx...
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea array_assignment_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)

        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (array_assignment_offset)(%rip)

        leave
        ret

// in rdi: identifier type
// in rsi: identifier descriptor
// in rdx: index type
// in rcx: index descriptor
// out:    token descriptor
.type construct_array_access, @function
construct_array_access:
        push %rbp
        mov %rsp, %rbp 
        xor %rbx, %rbx
        xor %rax, %rax
        mov array_access_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # mulq uses rdx...
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx

        lea array_access_buffer(%rip), %rax
        
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)
        
        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (array_access_offset)(%rip)

        leave
        ret

// in rdi: identifier_id
// in rsi: identifier_descriptor
// in rdx: expr_id
// in rcx: expr_descriptor
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
        movq $16, %rdx # Size of assignment (16 bytes)
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea assignment_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)

        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (assignment_offset)(%rip)

        leave
        ret

// in rdi: variable descriptor
// in rsi: field descriptor
// out:    field_access descriptor
.type construct_field_access_node, @function
construct_field_access_node:
        push %rbp
        mov %rsp, %rbp
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov field_access_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # mulq uses rdx...
        movq $8, %rdx # Size of field_access (8 bytes)
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea field_access_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (field_access_offset)(%rip)

        leave
        ret


// in rdi: struct descriptor
// in rsi: identifier descriptor
// out:    struct instance descriptor
.type construct_struct_instance, @function
construct_struct_instance:
        push %rbp
        mov %rsp, %rbp
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov struct_instance_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # mulq uses rdx...
        movq $8, %rdx # Size of struct_instance (8 bytes)
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea struct_instance_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (struct_instance_offset)(%rip)

        leave
        ret


// in rdi: expr id
// in rsi: expr descriptor
// out:    print descriptor
.type construct_print_node, @function
construct_print_node:
        push %rbp
        mov %rsp, %rbp
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov print_statement_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        movq $8, %rdx # Size of print node (8 bytes)
        mulq %rdx
        mov %rax, %rbx
        # We now have the correct offset into the buffer
        # Load buffer
        lea print_statement_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (print_statement_offset)(%rip)

        leave
        ret


// in rdi: struct name identifier
// in rsi: int * to the field-descriptors
// in rdx: field count
// out:    declaration descriptor
.type construct_struct_decl_node, @function
construct_struct_decl_node:
        push %rbp
        mov %rsp, %rbp
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov struct_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # Store the length.

        # We multiply by 4 because we are using ints.

        push %rdx # mulq uses rdx...
        movq $4, %rdx
        mulq %rdx
        mov %rax, %rbx
        
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea struct_buffer(%rip), %rax
        mov %edi, (%rax, %rbx) # name
        mov %edx, 4(%rax, %rbx) # count
        
        # We need to go through the pointer rdx times. Offset between each is 8 bytes, because we are using the stack.
        addq %rbx, %rax
        addq $8, %rax

    struct_insert_loop_begin:
        mov (%rsi), %edi
        mov %edi, (%rax)
        addq $8, %rsi # 64 bit (stack)
        addq $4, %rax # 32 bit (array)
        dec %rdx
        test %rdx, %rdx
        jnz struct_insert_loop_begin

        

        pop %rbx # Restore the #fields
        pop %rax # Restore descriptor
        addq $2, %rbx # Add 4*2 bytes for the two ints
        addq %rax, %rbx # Add the length
        # Store next available descriptor 
        mov %ebx, (struct_offset)(%rip)

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

// in rdi: guard id
// in rsi: guard descriptor
// in rdx: body id
// in rcx: body descriptor
// out:    if descriptor
.type construct_if_node, @function
construct_if_node:
        push %rbp
        mov %rsp, %rbp 
        xor %rbx, %rbx
        xor %rax, %rax
        mov if_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        # Ensure that we are offset by the correct size of each struct -> ebx * sizeof(binaryop) -> ebx * 20 bytes
        push %rdx # mulq uses rdx...
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        lea if_buffer(%rip), %rax
        
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)
        
        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (if_offset)(%rip)

        leave
        ret
// in rdi: guard id
// in rsi: guard descriptor
// in rdx: body id
// in rcx: body descriptor
// out:    while descriptor
.type construct_while_node, @function
construct_while_node:
        push %rbp
        mov %rsp, %rbp 
        xor %rbx, %rbx
        xor %rax, %rax
        mov while_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        # Ensure that we are offset by the correct size of each struct -> ebx * sizeof(binaryop) -> ebx * 20 bytes
        push %rdx # mulq uses rdx...
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        lea while_buffer(%rip), %rax
        
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)
        
        pop %rax # Restore descriptor
        movq %rax, %rbx
        inc %ebx
        # Store next available descriptor 
        mov %ebx, (while_offset)(%rip)

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
// out 16(%rbp): identifier id
// out 24(%rbp): identifier descriptor
// out 32(%rbp): count
// out 40(%rbp): stride
.type retrieve_array_assignment, @function
.global retrieve_array_assignment
retrieve_array_assignment:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea array_assignment_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi # identifier id
        mov  4(%rax, %rbx), %esi # identifier desc
        mov  8(%rax, %rbx), %edx # count
        mov 12(%rax, %rbx), %ecx # stride
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

        leave
        ret

// in rdi: token descriptor
// out 16(%rbp): identifier id
// out 24(%rbp): identifier descriptor
// out 32(%rbp): index id
// out 40(%rbp): index descriptor
.type retrieve_array_access, @function
.global retrieve_array_access
retrieve_array_access:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea array_access_buffer(%rip), %rax
        mov   (%rax, %rbx), %edi # identifier id
        mov  4(%rax, %rbx), %esi # identifier desc
        mov  8(%rax, %rbx), %edx # index id
        mov 12(%rax, %rbx), %ecx # index descriptor

        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

        leave
        ret

// in rdi: Token descriptor
// out 16(%rbp): expr id
// out 24(%rbp): expr descriptor
.type retrieve_print, @function
.global retrieve_print
retrieve_print:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea print_statement_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi # expr id
        mov  4(%rax, %rbx), %esi # expr desc
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

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

// in rdi: Token descriptor
// out 16(%rbp): name descriptor
// out 24(%rbp): struct descriptor
.type retrieve_struct_type, @function
.global retrieve_struct_type
retrieve_struct_type:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea struct_type_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi # name descriptor
        mov  4(%rax, %rbx), %esi # struct descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

        leave
        ret

// in rdi:  identifier descriptor
// out rax: assignment descriptor
.type find_array_assignment_by_identifier, @function
.global find_array_assignment_by_identifier
find_array_assignment_by_identifier:
        push %rbp
        movq %rsp, %rbp
        call retrieve_identifier
        movq %rax, %rdi

        mov assignment_offset(%rip), %r8d
        # Total num to check
        lea assignment_buffer(%rip), %rsi
        addq $8, %rsi # Place offset ontop of identifier descriptor

        xor %rcx, %rcx
    check_next_array:
        push %rcx
        push %rsi
        push %rdi
        mov (%rsi), %edi
        call retrieve_identifier
        movq %rax, %rsi
        pop %rdi # Restore
        
        call cmp_string
        pop %rsi
        cmp $1, %rax
        je found_array

        addq $16, %rsi
        pop %rcx
        inc %rcx
        cmp %r8d, %ecx
        jne check_next_array
        # We didn't find it....
        leave
        ret
    found_array:
        movq %rcx, %rax
        leave
        ret

// in rdi:  identifier descriptor
// out rax: struct_type descriptor
.type find_struct_type_by_name, @function
.global find_struct_type_by_name
find_struct_type_by_name:
        push %rbp
        mov %rsp, %rbp 

        call retrieve_identifier
        movq %rax, %rdi

        mov struct_offset(%rip), %r8d
        # Total num to check
        lea struct_type_buffer(%rip), %rsi
        
        xor %rcx, %rcx
    check_next_type:
        push %rcx
        push %rsi
        push %rdi
        mov (%rsi), %edi
        call retrieve_identifier
        movq %rax, %rsi
        pop %rdi # Restore
        
        call cmp_string
        pop %rsi # Restore struct_type_buffer
        cmp $1, %rax
        je found_type

        addq $8, %rsi
        pop %rcx
        inc %rcx
        cmp %r8d, %ecx
        jne check_next_type
        # We didn't find it....
        leave
        ret
    found_type:
        movl 4(%rsi), %eax
        cltq
        leave
        ret


// in rdi: token descriptor
// out 16(%rbp): struct name descriptor
// out 24(%rbp): field count
// out 32(%rbp): field descriptor *
.type retrieve_struct_decl, @function
.global retrieve_struct_decl
retrieve_struct_decl:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $4, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea struct_buffer(%rip), %rax
        xor %rdi, %rdi
        xor %rsi, %rsi
        xor %rdx, %rdx
        mov   (%rax, %rbx), %edi # struct name descriptor
        mov  4(%rax, %rbx), %esi # field count
        # field descriptor *
        addq $8, %rax
        addq %rbx, %rax
        mov %edi,  16(%rbp)
        mov %esi,  24(%rbp)
        movq %rax, 32(%rbp)

        leave
        ret

// in rdi: token descriptor
// out 16(%rbp): var descriptor
// out 24(%rbp): field descriptor
.type retrieve_field_access, @function
.global retrieve_field_access
retrieve_field_access:
        push %rbp
        mov %rsp, %rbp
        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea field_access_buffer(%rip), %rax
        xor %rdi, %rdi
        xor %rsi, %rsi
        mov   (%rax, %rbx), %edi # identifier descriptor
        mov  4(%rax, %rbx), %esi # field descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

        leave
        ret


// in rdi: token descriptor
// out 16(%rbp): struct descriptor
// out 24(%rbp): identifier descriptor
.type retrieve_struct_instance, @function
.global retrieve_struct_instance
retrieve_struct_instance:
        push %rbp
        mov %rsp, %rbp
        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea struct_instance_buffer(%rip), %rax
        xor %rdi, %rdi
        xor %rsi, %rsi
        mov   (%rax, %rbx), %edi # struct descriptor
        mov  4(%rax, %rbx), %esi # identifier descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

        leave
        ret

// in rdi: token descriptor
// out 16(%rbp): identifier id
// out 24(%rbp): identifier descriptor
// out 32(%rbp): expr id
// out 40(%rbp): expr descriptor
.type retrieve_assignment, @function
.global retrieve_assignment
retrieve_assignment:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea assignment_buffer(%rip), %rax
        xor %rdi, %rdi
        xor %rsi, %rsi
        xor %rdx, %rdx
        xor %rcx, %rcx
        mov   (%rax, %rbx), %edi # identifier id
        mov  4(%rax, %rbx), %esi # identifier descriptor
        mov  8(%rax, %rbx), %edx # expr id
        mov 12(%rax, %rbx), %ecx # expr descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

        leave
        ret

// in rdi: token descriptor
// out 16(%rbp): guard id
// out 24(%rbp): guard descriptor
// out 32(%rbp): body id
// out 40(%rbp): body descriptor
.type retrieve_if, @function
.global retrieve_if
retrieve_if:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea if_buffer(%rip), %rax
        xor %rdi, %rdi
        xor %rsi, %rsi
        xor %rdx, %rdx
        xor %rcx, %rcx
        mov   (%rax, %rbx), %edi # guard id
        mov  4(%rax, %rbx), %esi # guard descriptor
        mov  8(%rax, %rbx), %edx # body id
        mov 12(%rax, %rbx), %ecx # body descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

        leave
        ret

// in rdi: token descriptor
// out 16(%rbp): guard id
// out 24(%rbp): guard descriptor
// out 32(%rbp): body id
// out 40(%rbp): body descriptor
.type retrieve_while, @function
.global retrieve_while
retrieve_while:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea while_buffer(%rip), %rax
        xor %rdi, %rdi
        xor %rsi, %rsi
        xor %rdx, %rdx
        xor %rcx, %rcx
        mov   (%rax, %rbx), %edi # guard id
        mov  4(%rax, %rbx), %esi # guard descriptor
        mov  8(%rax, %rbx), %edx # body id
        mov 12(%rax, %rbx), %ecx # body descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

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
