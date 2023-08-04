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


        # My print implementation
        # Expects value to print in rdi
        call emit_asm_prologue
        call emit_print
        call emit_colon
        call emit_function_prologue
        call emit_print_body
        call emit_function_epilogue
        
        call emit_newline
        
        call emit_entry_point
        call emit_function_prologue
        call emit_call
        call emit_main
        call emit_asm_epilogue
        
        

        pop %rsi
        pop %rdi
        call visit_statement



        leave
        ret

// in rdi: Token id
// in rsi: Token descriptor
.type visit_statement, @function
visit_statement:
        push %rbp
        mov %rsp, %rbp

        cmp $28, %rdi
        je visit_statement_list
        cmp $29, %rdi
        je visit_assignment
        cmp $30, %rdi
        je visit_function
        cmp $31, %rdi
        je visit_if
        cmp $32, %rdi
        je visit_while
        cmp $39, %rdi
        je visit_print
        cmp $46, %rdi
        je visit_function_call
        cmp $49, %rdi
        je visit_loop
        cmp $62, %rdi
        je visit_declaration_assign
        cmp $63, %rdi
        je visit_declaration
        leave
        ret
    visit_declaration:
        # Do nothing
        leave
        ret
    visit_declaration_assign:
        movq %rsi, %rdi
        push $696969 # Value descriptor
        push $696969 # Value type
        push $696969 # Name descriptor
        push $696969 # name id
        call retrieve_declaration_assign
        movq (%rsp), %rax
        movq %rax, 8(%rsp)
        movq $24, (%rsp)
        jmp visit_assignment_stack_init_done
        leave
        ret
    visit_loop:
        movq %rsi, %rdi
        push %rdi
        push $696969 # body descriptor
        push $696969 # Body type
        push $696969 # Count descriptor 
        push $696969 # Count type
        call retrieve_loop
        pop %rdi
        pop %rsi
        call visit_expression

        call emit_pop
        call emit_rcx
        call emit_newline
        call emit_loop
        movq 16(%rsp), %rdi
        call emit_number
        call emit_colon
        call emit_push
        call emit_rcx
        pop %rdi
        pop %rsi
        call visit_statement

        call emit_pop
        call emit_rcx
        call emit_test
        call emit_rcx
        call emit_comma
        call emit_rcx

        call emit_loopnz
        call emit_loop
        pop %rdi
        call emit_number
        call emit_newline_tab
        leave
        ret
    visit_function_call:
        movq %rsi, %rdi
        push $696969 # arglist descriptor
        push $696969 # identifier descriptor
        call retrieve_function_call

        movq 8(%rsp), %rdi
        cmp $0, %rdi
        je function_skip_args

        push $696969 # Arg descriptor *
        push $696969 # Count
        call retrieve_arg_list
        pop %rcx # Count
        pop %rsi # Descriptor *
        
        push %rbp
        movq %rsp, %rbp
        subq $16, %rsp
        movq %rcx,  -8(%rbp) # Count
        movq %rsi, -16(%rbp) # Descriptor *
    function_visit_arg_begin:
        
        
        movq -16(%rbp), %rsi    # Load arg_list *
        movl (%rsi), %edi       # Arg descriptor
        addq $4, %rsi           # Go to next arg
        movq %rsi, -16(%rbp)    # Save arg_list *
        
        push $696969 # token descriptor
        push $696969 # token id
        call retrieve_arg
        
        pop %rdi
        pop %rsi
        call visit_expression

        movq -8(%rbp), %rcx # Count
        dec %rcx
        movq %rcx,  -8(%rbp) # Count
        cmp $0, %rcx
        jne function_visit_arg_begin
        
        leave

    function_skip_args:
        # Check for the return type
        pop %rdi
        call retrieve_identifier
        movq %rax, %rdi
        call find_function_by_charptr
        movq %rax, %rdi
        push $696969 # return type descriptor
        push $696969 # arg list
        push $696969 # symbol table
        push $696969 # var vound
        push $696969 # body descriptor
        push $696969 # body id
        push $696969 # identifier
        call retrieve_function
        pop %rsi # Identifier
        addq $40, %rsp
        pop %rdi # return type descriptor
        push %rsi # identifier
        push $696969 # type descriptor
        push $696969 # type id
        push $696969 # size int
        push $696969 # char *name
        call retrieve_type
        addq $8, %rsp
        
        call emit_sub
        call emit_dollar
        pop %rdi
        addq $16, %rsp
        call emit_number
        call emit_comma
        call emit_rsp

        call emit_call

        pop %rdi
        call emit_identifier
        call emit_newline

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
        call emit_newline
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

        call emit_newline
        call emit_comment_enter_guard

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

        call emit_newline
        call emit_comment_leaving_guard
        call emit_newline
        call emit_comment_enter_body

        pop %rdi
        pop %rsi
        call visit_statement
        
        call emit_comment_leaving_body

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

        call emit_newline
        call emit_comment_enter_guard
        
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


        call emit_newline
        call emit_comment_leaving_guard
        call emit_newline
        call emit_comment_enter_body

        pop %rdi
        pop %rsi
        call visit_statement
        
        call emit_comment_leaving_body

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
        push $696969 # return type descriptor
        push $696969 # Arg list descriptor
        push $696969 # Symbol Table Descriptor
        push $696969 # Variable Count
        push $696969 # Body Descriptor
        push $696969 # Body id
        push $696969 # Identifier
        call retrieve_function

        call emit_newline

        pop %rdi # Identifier
        call emit_identifier
        call emit_colon
        call emit_function_prologue
        
        # Make place for local vars on the stack 
        call emit_sub
        call emit_dollar

        movq 16(%rsp), %rdi # var size
        call emit_number
        call emit_comma
        call emit_rsp
        
        
        pop %rdi
        pop %rsi
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
        enter $40, $0
        #  -8(%rbp) -> base offset on the stack
        # -16(%rbp) -> expression descriptor
        # -24(%rbp) -> expression id
        # -32(%rbp) -> identifier descriptor
        # -40(%rbp) -> identifier id
        movq $0,  -8(%rbp)
        movq $0, -16(%rbp)
        movq $0, -24(%rbp)
        movq $0, -32(%rbp)
        movq $0, -40(%rbp)
        movq %rsi, %rdi
        call retrieve_assignment
    visit_assignment_stack_init_done:

        movq -40(%rbp), %rsi
        movq -32(%rbp), %rdi
        cmp $41, %rsi # array access
        je visit_assignment_array_access

        call get_offset_on_stack
        movq %rax, -8(%rbp)

        # Eval the right side
        movq -24(%rbp), %rdi
        movq -16(%rbp), %rsi
        call visit_expression

        # At this point we need to determine what we are dealing with
        # It could either be a primitive
        # Or it could be a struct

        movq -40(%rbp), %rdi
        cmp $36, %rdi # Array Access
        je assignment_primitive

        movq -32(%rbp), %rdi
        call find_type_by_name
        movq %rax, %rdi
        push $696969 # type descriptor
        push $696969 # type id
        push $696969 # size int
        push $696969 # char *name
        call retrieve_type

        cmpq $0, 16(%rsp)
        je assignment_primitive
    assignment_struct:
        # At this point we are dealing wit ha struct
        movq 24(%rsp), %rdi
        push $696969 # field descriptor *
        push $696969 # field count
        push $696969 # struct name descriptor
        call retrieve_struct_decl
        movq (%rsp), %rdi
        movq %rdi, -32(%rbp)
        movq 16(%rsp), %rdi # field descriptor *
        movq  8(%rsp), %rsi # Count

            enter $16, $1
            #  -8(%rbp) -> count
            # -16(%rbp) -> current field descriptor *
            movq %rsi,  -8(%rbp)
            movq %rdi, -16(%rbp)
        assignment_struct_pop_into_field:
            movq -16(%rbp), %rdi
            movl (%rdi), %edi
            decq -8(%rbp)       # Decrease the counter
            addq $4, -16(%rbp)  # Progress to the next descriptor
            push $696969        # type descriptor
            push $696969        # name descriptor
            call retrieve_declaration

            call emit_pop
            call emit_rax
            call emit_mov
            call emit_rax
            call emit_comma
            call emit_minus
            
            pop %rsi
            addq $8, %rsp
            movq (%rbp),    %rdi
            movq -32(%rdi), %rdi
            call get_relative_offset_for_field
            
            # Load the base offset
            movq (%rbp), %rdi
            movq -8(%rdi), %rdi
            addq %rax, %rdi
            call emit_number

            call emit_lparen
            call emit_rbp
            call emit_rparen
            
            cmpq $0, -8(%rbp) 
            jg assignment_struct_pop_into_field
            leave
        leave
        leave
        ret

    assignment_primitive:
        # Here we can decide on the correct move isntruction,
        # depending on the size of the target

        # However, for now we just ignore it.
        //TODO! Futureproof with correct move instructions.
        call emit_pop
        call emit_rax



        movq -40(%rbp), %rsi
        # Check if we have a deref
        cmp $44, %rsi
        je visit_assignment_deref

        call emit_mov
        call emit_rax
        call emit_comma

        

        pop %rsi
        pop %rdi
        call emit_var

        call emit_newline

        leave
        leave
        ret

    visit_assignment_deref:
        call emit_mov
        pop %rsi
        pop %rdi
        push $696969
        push $696969
        call retrieve_deref
        pop %rsi
        pop %rdi
        call emit_var
        call emit_comma
        call emit_rbx
        call emit_mov
        call emit_rax
        call emit_comma
        call emit_lparen
        call emit_rbx
        call emit_rparen
        call emit_newline
        leave
        ret

    visit_assignment_array_access:
    # Unwrap the expression for the index
        movq 8(%rsp), %rdi
        push $696969 # index descriptor
        push $696969 # index id
        push $696969 # identifier descriptor
        push $696969 # identifier id
        call retrieve_array_access

        movq  (%rsp), %rsi
        movq 8(%rsp), %rdi
        call get_offset_on_stack
        movq $8, %rdx
        imulq %rdx
        # base offset
        push %rax

        movq 16(%rsp), %rdi
        movq 8(%rsp), %rsi
        call find_array_assignment_by_identifier
        movq %rax, %rdi
        push $69 # type
        push $69 # count int
        push $69 # identifier descriptor
        push $69 # identifier id
        call retrieve_array_assignment
        addq $24, %rsp
        
        # Eval index
        movq 32(%rsp), %rdi
        movq 40(%rsp), %rsi
        pop %rax # type
        pop %rbx # offset
        addq $32, %rsp # Remove the array access stuff
        push %rbx # offset
        push %rax # type
        call visit_expression
        
        call emit_pop
        call emit_rax
        call emit_mov
        call emit_dollar
        pop %rdi # type
        call emit_number
        call emit_comma
        call emit_rdx
        call emit_mul
        call emit_rdx
        call emit_push
        call emit_rax

        call emit_newline

        # We now have the dest on the stack.

        # Evaluate the rhs
        movq 24(%rsp), %rdi
        movq 32(%rsp), %rsi
        call visit_expression

        # We have the result on the stack
        # Destination is just below
        # -baseoffset(%rbp, %rcx)
        
    # Result
        call emit_pop
        call emit_rax
    # Relative offset
        call emit_pop
        call emit_rcx
        call emit_neg
        call emit_rcx
        call emit_mov
        call emit_rax
        call emit_comma
        call emit_minus
        pop %rdi # Base Offset
        call emit_number
        call emit_lparen
        call emit_rbp
        call emit_comma
        call emit_rcx
        call emit_rparen

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
        je field
        cmp $41, %rdi # array access
        je array_access
        cmp $43, %rdi # addressof
        je addressof
        cmp $44, %rdi # eref
        je deref
        cmp $19, %rdi # true
        je true
        cmp $20, %rdi # false
        je false
        # It was neither a binary op nor a number
        leave 
        ret
    true:
        call emit_push
        call emit_dollar
        movq $1, %rdi
        call emit_number
        call emit_newline_tab
        leave
        ret
    false:
        call emit_push
        call emit_dollar
        movq $0, %rdi
        call emit_number
        call emit_newline_tab
        leave
        ret
    deref:
        movq %rsi, %rdi
        push $696969 # expr descriptor
        push $696969 # expr id
        call retrieve_deref

        pop %rdi
        pop %rsi
        call visit_expression
        call emit_pop
        call emit_rax
        call emit_push
        call emit_lparen
        call emit_rax
        call emit_rparen
        leave
        ret
    addressof:
        movq %rsi, %rdi
        push $696969 # expr descriptor
        push $696969 # expr id
        call retrieve_addressof

        movq (%rsp), %rdi
        cmp $24, %rdi # Must be an lvalue
        je addressof_identifier
        cmp $41, %rdi
        je addressof_array_access
        cmp $36, %rdi
        je addressof_field_access
        jmp emit_unexpected_expr_expected_lvalue
        addressof_identifier:
            call emit_lea

            pop %rsi
            pop %rdi
            call emit_var
            call emit_comma
            call emit_rax
            call emit_push
            call emit_rax

            leave
            ret
        addressof_field_access:
            jmp emit_not_implemented
            leave
            ret
        addressof_array_access:
            # We need to evaluate the index.
            # For now, just evaluate it at runtime
            # Check for compiletime evaluation later

            # New idea for loading array accesses
            # Compute the address of the array_index
            
            # lea base_address, rax
            # add offset, rax

            movq 8(%rsp), %rdi
            # rdi is array access
            push $696969 # index descriptor
            push $696969 # index id
            push $696969 # identifier descriptor
            push $696969 # identifier id
            call retrieve_array_access

            # Find the base address of identifier
            movq  (%rsp), %rsi
            movq 8(%rsp), %rdi
            call get_offset_on_stack
            movq $8, %rdx
            imulq %rdx
            push %rax

            call emit_lea
            call emit_minus
            pop %rdi
            call emit_number
            call emit_lparen
            call emit_rbp
            call emit_rparen
            call emit_comma
            call emit_rax

            call emit_push
            call emit_rax
            # Base address is on top of the stack

            # Eval the index

            movq 16(%rsp), %rdi
            movq 24(%rsp), %rsi
            call visit_expression

            # index is on top of the stack
            # multiply it by the stride
            movq  (%rsp), %rdi
            movq 8(%rsp), %rsi
            call retrieve_stride_from_identifier

            push %rax # Stride in bytes

            call emit_pop
            call emit_rax
            call emit_mov
            call emit_dollar
            pop %rdi
            call emit_number
            call emit_comma 
            call emit_rdx
            call emit_mul
            call emit_rdx
            call emit_push
            call emit_rax

            # Relative offset on top of stack
            # Load the base offset
            call emit_pop
            call emit_rbx # Relative offset
            call emit_pop
            call emit_rax # Base offset

            call emit_add
            call emit_rbx
            call emit_comma
            call emit_rax
            
            call emit_push
            call emit_rax # Store the address

            leave
            ret
    array_access:
        push %rsi
        
        call emit_newline_tab

        pop %rdi
        call emit_load_array_access

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
        callq emit_rax
        callq emit_pop
        callq emit_rbx
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
        cmp $22, %rdx
        je insert_and
        cmp $23, %rdx
        je insert_or
        leave
        ret

    identifier:
        # We want to check the identifier's type.
        # If it is of type struct, we need to load each field
        # The primitive types are just a subset of the above,
        # Where the struct only contains a single field.
        enter $24, $0
        #  -8(%rbp) -> identifier descriptor
        # -16(%rbp) -> identifier id
        # -24(%rbp) -> base offset on the stack
        movq %rdi, -16(%rbp)
        movq %rsi,  -8(%rbp)
        
        movq -16(%rbp), %rsi
        movq  -8(%rbp), %rdi
        call get_offset_on_stack
        movq %rax, -24(%rbp)

        movq -8(%rbp), %rdi
        call find_type_by_name
        movq %rax, %rdi
        push $696969 # type descriptor
        push $696969 # type id
        push $696969 # size int
        push $696969 # char *name
        call retrieve_type
        
        cmpq $0, 16(%rsp)
        je identifier_primitive
    identifier_struct:
        # We now want to push each field on the stack
        # One by one.
        # Let us push it in reverse order.
        # That way the assign to can do it in the 'normal' direction
        movq 24(%rsp), %rdi
        push $696969 # field descriptor *
        push $696969 # field count
        push $696969 # struct name descriptor
        call retrieve_struct_decl
        movq (%rsp), %rdi
        movq %rdi, -8(%rbp)
        movq 16(%rsp), %rdi # field descriptor *
        movq  8(%rsp), %rsi # Count


            enter $16, $1
            #  -8(%rbp) -> count
            # -16(%rbp) -> current field descriptor *
            movq %rsi,  -8(%rbp)
            decq %rsi

            # Reverse order
            shl $2, %rsi
            addq %rsi, %rdi

            movq %rdi, -16(%rbp)
        identifier_struct_push_field:
            movq -16(%rbp), %rdi
            movl (%rdi), %edi
            decq -8(%rbp)       # Decrease the counter
            subq $4, -16(%rbp)  # Progress to the next descriptor
            push $696969        # type descriptor
            push $696969        # name descriptor
            call retrieve_declaration

            //TODO! Futureproof with correct move instruction.

            call emit_mov
            call emit_minus

            pop %rsi
            addq $8, %rsp
            movq (%rbp), %rdi
            movq -8(%rdi), %rdi
            call get_relative_offset_for_field
            
            # Load the base offset
            movq (%rbp), %rdi
            movq -24(%rdi), %rdi
            addq %rax, %rdi
            call emit_number
            
            call emit_lparen
            call emit_rbp
            call emit_rparen
            call emit_comma
            call emit_rax
            call emit_push
            call emit_rax


            cmpq $0, -8(%rbp) 
            jg identifier_struct_push_field
            leave

        call emit_newline
        
        leave
        leave
        ret
    identifier_primitive:
        # Here we can decide on the correct move isntruction,
        # depending on the size of the target

        # However, for now we just ignore it.
        //TODO! Futureproof with correct move instructions.
        addq $32, %rsp
        call emit_mov
        
        pop %rdi
        pop %rsi
        call emit_var

        call emit_comma
        call emit_rax
        call emit_push
        call emit_rax
        leave
        leave
        ret

    field:
        push %rdi
        push %rsi
        call emit_mov
        
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
        
        call emit_cmp
        call emit_rax
        call emit_comma
        call emit_rbx
        
        call emit_sete
        call emit_rax8
        call emit_push
        call emit_rax

        leave 
        ret
    insert_noteq:
        call emit_cmp
        call emit_rax
        call emit_comma
        call emit_rbx
        
        call emit_setne
        call emit_rax8
        call emit_push
        call emit_rax
        leave 
        ret
    insert_less:
        call emit_cmp
        call emit_rax
        call emit_comma
        call emit_rbx
        
        call emit_setl
        call emit_rax8
        call emit_push
        call emit_rax
        leave 
        ret
    insert_greater:
        call emit_cmp
        call emit_rax
        call emit_comma
        call emit_rbx
        
        call emit_setg
        call emit_rax8
        call emit_push
        call emit_rax
        leave
        ret
    insert_and:
        call emit_and
        call emit_rax
        call emit_comma
        call emit_rbx
        
        call emit_push
        call emit_rbx

        leave
        ret
    insert_or:
        call emit_or
        call emit_rax
        call emit_comma
        call emit_rbx
        
        call emit_push
        call emit_rbx
        
        leave
        ret

// in rdi: array access descriptor
.type emit_load_array_access, @function
emit_load_array_access:
        push %rbp
        movq %rsp, %rbp

        push $696969 # index descriptor
        push $696969 # index id
        push $696969 # identifier token
        push $696969 # identifier id
        call retrieve_array_access

        # Case [1]: Hardcoded @Compile -> a[1]
        # Case [2]: Variable  @Runtime -> a[expr]
        
        # Condition [1]: 
        #   * index id == 'number' 25
        # Condition [2]:
        #   * index id != 'number' 25
        movq 16(%rsp), %rdi
        cmp $25, %rdi
        je emit_load_array_access_compiletime
    emit_load_array_access_runtime:
    # Case [2]
        # 1. Load the base address
        # 2. evaluate the expr
        # 3. load the expr into rcx
        # 4. Emit the relative offset
        #     -baseoffset(%rbp, %rcx, 8)
        # 5. Push to stack
    # 1
        movq  (%rsp), %rsi # Token id
        movq 8(%rsp), %rdi # Token descriptor
        call find_array_assignment_by_identifier
        movq %rax, %rdi
        push $696969 # type
        push $696969 # count
        push $696969 # Identifier desc
        push $696969 # Identifier id
        call retrieve_array_assignment
        addq $24, %rsp
        pop %rax
        pop %rsi # identifier id
        pop %rdi # identifier token
        push %rax # type
        call get_offset_on_stack
        cltq
        movq $8, %rdx
        imulq %rdx
        push %rax # Base offset
    # 2
        movq 24(%rsp), %rsi
        movq 16(%rsp), %rdi
        call visit_expression
    # 3
        call emit_pop
        call emit_rax
        call emit_mov
        call emit_dollar
        movq 8(%rsp), %rdi # type //TODO! Fix me
        call emit_number
        call emit_comma
        call emit_rdx
        call emit_mul
        call emit_rdx
        call emit_mov
        call emit_rax
        call emit_comma
        call emit_rcx
        call emit_neg
        call emit_rcx
    # 4
        call emit_mov
        call emit_minus
        pop %rdi # Base offset
        call emit_number
        call emit_lparen
        call emit_rbp
        call emit_comma
        call emit_rcx
        call emit_rparen
    # 5
        call emit_comma
        call emit_rax
        call emit_push
        call emit_rax
        leave
        ret
    emit_load_array_access_compiletime:
    # Case [1]
        # 1. load the base address
        # 2. add the offset for the index
        # 3. profit
        # 4. Push to stack

    # 1
        pop %rsi
        pop %rdi
        call get_offset_on_stack
        cltq
        movq $8, %rdx
        imulq %rdx
        push %rax # Base offset

    # 2

        movq 16(%rsp), %rax
        movq $8, %rdx
        imulq %rdx
        pop %rbx
        addq %rax, %rbx
        push %rbx # Final offset
    # 3
        call emit_mov
        call emit_minus
        pop %rdi
        call emit_number
        call emit_lparen
        call emit_rbp
        call emit_rparen
    # 4
        call emit_comma
        call emit_rax
        call emit_push
        call emit_rax

        leave
        ret

// in rdi: the descriptor of the identifier
// in rsi: the type of the field/identifier
.type emit_var, @function
emit_var:
        push %rbp
        mov %rsp, %rbp

        call get_offset_on_stack
        movq %rax, %rdi
        push %rdi
        call emit_minus
        pop %rdi
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

.type emit_entry_point, @function
emit_entry_point:
        enter $0, $0
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_entry_point, %rsi
        movq $23, %rdx
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
        movq $15, %rdx
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
.type emit_sete, @function
emit_sete:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_sete, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_setne, @function
emit_setne:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_setne, %rsi
        movq $8, %rdx
        syscall
        leave
        ret
.type emit_setg, @function
emit_setg:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_setg, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_setl, @function
emit_setl:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_setl, %rsi
        movq $7, %rdx
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
.type emit_cmovne, @function
emit_cmovne:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_cmovne, %rsi
        movq $10, %rdx
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
.type emit_test, @function
emit_test:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_test, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_neg, @function
emit_neg:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_neg, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_and, @function
emit_and:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_and, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_or, @function
emit_or:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_or, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_xor, @function
emit_xor:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_xor, %rsi
        movq $7, %rdx
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
.type emit_rax8, @function
emit_rax8:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rax8, %rsi
        movq $3, %rdx
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
.type emit_loop, @function
emit_loop:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq token_loopii, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_loopnz, @function
emit_loopnz:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_loopnz, %rsi
        movq $9, %rdx
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
.type emit_comment_enter_body, @function
emit_comment_enter_body:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_comment_enter_body, %rsi
        movq $18, %rdx
        syscall
        leave
        ret
.type emit_comment_leaving_body, @function
emit_comment_leaving_body:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_comment_leaving_body, %rsi
        movq $17, %rdx
        syscall
        leave
        ret

.type emit_comment_enter_guard, @function
emit_comment_enter_guard:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_comment_enter_guard, %rsi
        movq $19, %rdx
        syscall
        leave
        ret
.type emit_comment_leaving_guard, @function
emit_comment_leaving_guard:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_comment_leaving_guard, %rsi
        movq $18, %rdx
        syscall
        leave
        ret


