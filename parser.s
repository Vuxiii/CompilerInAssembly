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


.global declaration_buffer
        declaration_buffer:       .space 1024
.global declaration_assign_buffer
        declaration_assign_buffer:.space 1024
.global loop_buffer
        loop_buffer:             .space 1024
.global return_buffer
        return_buffer:           .space 1024
.global type_buffer
        type_buffer:             .space 1024
.global function_call_buffer
        function_call_buffer:    .space 1024
.global arg_buffer
        arg_buffer:              .space 1024
.global arg_list_buffer
        arg_list_buffer:         .space 1024
.global deref_buffer
        deref_buffer:            .space 1024
.global addressof_buffer
        addressof_buffer:        .space 1024
.global array_assignment_buffer
        array_assignment_buffer: .space 1024
.global array_access_buffer
        array_access_buffer:     .space 1024
.global print_statement_buffer
        print_statement_buffer:  .space 1024
.global struct_instance_buffer
        struct_instance_buffer: .space 1024
.global struct_type_buffer
        struct_type_buffer:     .space 1024
.global struct_buffer 
        struct_buffer:          .space 1024
.global field_access_buffer
        field_access_buffer:    .space 1024
.global function_buffer
        function_buffer:        .space 1024
.global if_buffer
        if_buffer:              .space 1024
.global while_buffer
        while_buffer:           .space 1024
.global statement_list_buffer
        statement_list_buffer:  .space 1024
.global assignment_buffer
        assignment_buffer:      .space 1024
.global binary_op_buffer
        binary_op_buffer:       .space 1024

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
addressof_offset:               .int 0
deref_offset:                   .int 0
function_call_offset:           .int 0
arg_offset:                     .int 0
arg_list_offset:                .int 1 # For functions with no args
loop_offset:                    .int 0
return_offset:                  .int 0
type_offset:                    .int 0
declaration_assign_offset:      .int 0
declaration_offset:             .int 0

.global declaration_offset
.global struct_offset
.global type_offset
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
        je some_statement
        cmp $45, %rax # '*' deref
        je deref_assignment_
        cmp $1, %rax
        je function_declaration_
        cmp $2, %rax
        je if_statement_
        cmp $12, %rax
        je while_statement_
        cmp $21, %rax
        je struct_statement_
        cmp $11, %rax
        je print_statement_
        cmp $49, %rax
        je loop_statement_
        cmp $50, %rax
        je return_statement_
        cmp $57, %rax
        je declaration_statement_
    node_is_not_statement:
        movq $0, %rax # None
        leave
        ret
    single_statement:
        # Store results
        pop %rbx # Descriptor
        pop %rax # Token ID
        leave
        ret
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
    declaration_statement_:
        call declaration_statement
        push %rax
        push %rbx
        jmp check_statement_list

    return_statement_:
        call return_statement
        push %rax
        push %rbx
        jmp check_statement_list
        
    loop_statement_:
        call loop_statement
        push %rax
        push %rbx
        jmp check_statement_list
        
    print_statement_:
        call print_statement
        push %rax
        push %rbx
        jmp check_statement_list
        
    struct_statement_:
        call struct_statement
        push %rax
        push %rbx
        jmp check_statement_list

    while_statement_:
        call while_statement
        push %rax
        push %rbx
        jmp check_statement_list

    if_statement_:
        call if_statement
        push %rax
        push %rbx
        jmp check_statement_list

    function_declaration_:
        call function_declaration
        push %rax
        push %rbx
        jmp check_statement_list

    deref_assignment_:
        call next_token
        call next_token
        movq $1, %rdi
        call assignment
        push %rax
        push %rbx
        jmp check_statement_list

    some_statement:
        # Determine if it is a functioncall
        # Or an assignment
        call next_token
        # current_token_id: identifier
        call peek_token_id
        cmp $5, %rax # We are dealing with a function call
        je function_call_
        jmp assignment_
    
    function_call_:
        call function_call
        push %rax # id
        push %rbx # descriptor
        jmp check_statement_list


    assignment_:

        movq $0, %rdi
        call assignment
        push %rax # id
        push %rbx # descriptor
        jmp check_statement_list


// out rax: token id
// out rbx: token descriptor
.type declaration_statement, @function
declaration_statement:
        enter $24, $0
        #  -8(%rbp)  -> variable name descriptor
        # -16(%rbp)  -> variable name type
        # -24(%rbp)  -> type identifier descriptor
        # -32(%rbp)  -> value descriptor
        # -40(%rbp)  -> value type
        call next_token
        # Current: 'let'

        call peek_token_id
        cmp $24, %rax
        jne error_parse_expected_identifier

        call next_token
        # Current: 'identifier'
        call current_token_data
        movq %rax, -8(%rbp) # The name for the variable
        
        call peek_token_id
        cmp $58, %rax #  ':'    colon
        je declaration_statement_determine_type
        cmp $59, %rax #  ':='   coloneq
        je declaration_statement_typeinfer_assign
        cmp $60, %rax # '::'    doublecolon
        je declaration_statement_new_type
        cmp $37, %rax #  '.'    dot
        jne emit_parse_error_unexpected_token
        movq $36, -16(%rbp) # type is field_access
    declaration_statement_field_start:
        call next_token
        # Current: '.' dot
        call peek_token_id
        cmp $24, %rax
        jne emit_parse_error_expected_identifier
        call next_token
        # Current: 'identifier'
        call current_token_data
        movq %rax, %rsi
        movq -8(%rbp), %rdi
        call construct_field_access_node
        movq %rax, -8(%rbp)
        //TODO! Add recursive call here for nested field_access.
    declaration_statement_determine_type:
        call peek_token_id
        cmp $58, %rax
        jne emit_parse_error_expected_colon

        call next_token
        # Current: ':'
        call peek_token_id
        cmp $24, %rax
        jne emit_parse_error_expected_identifier

        call next_token
        # Current: 'identifier'
        call current_token_data
        movq %rax, -24(%rbp)

        call peek_token_id
        cmp $4, %rax
        jne declaration_statement_construct_declaration
    declaration_statement_assign:
        call next_token
        # Current: '='
        call parse_expression
        movq %rax, -40(%rbp)
        movq %rbx, -32(%rbp)
    declaration_statement_construct_declaration_with_assign:
        movq  -8(%rbp), %rdi
        movq -24(%rbp), %rsi
        movq -40(%rbp), %rdx
        movq -32(%rbp), %rcx
        call construct_declaration_assign
        movq %rax, %rbx
        movq $62, %rax
        leave
        ret
    declaration_statement_construct_declaration:
        movq  -8(%rbp), %rdi
        movq -24(%rbp), %rsi
        call construct_declaration
        movq %rax, %rbx
        movq $63, %rax
        leave
        ret
    declaration_statement_typeinfer_assign:
        jmp emit_not_implemented
        leave
        ret
    declaration_statement_new_type:
        call next_token
        # Current: '::' doublecolon
        call peek_token_id
        cmp $24, %rax
        je declaration_statement_type_alias
        cmp $21, %rax #'struct'
        jne emit_parse_error_unexpected_token

        call next_token
        # Current: 'struct'
        call peek_token_id
        cmp $7, %rax # '{'
        jne error_parse_missing_lcurly

        
        xor %r8, %r8
        declaration_statement_new_type_parse_fields:
        call next_token
        # Current: '{' or | ','
        call parse_struct_field
        push %rbx
        inc %r8
        call peek_token_id
        cmp $35, %rax # ','
        je declaration_statement_new_type_parse_fields
        # We are done
        call peek_token_id
        cmp $8, %rax # '}'
        jne emit_parse_error_missing_rcurly
        call next_token

        # The stack is full of struct_fields descriptors
        # Construct the struct
        movq %r8, %rdx
        movq -8(%rbp), %rdi
        lea (%rsp), %rsi
        dec %r8
        shl $3, %r8
        addq %r8, %rsi
        call construct_struct_decl_node
        push %rax
        push $33

        
        movq -8(%rbp), %rdi
        call retrieve_identifier
        movq %rax, %rdi
        xor %rsi, %rsi          # typechecker.s will determine the size
        movq (%rsp), %rdx
        movq 8(%rsp), %rcx
        call construct_type
        pop %rax
        pop %rbx
        leave
        ret
    declaration_statement_type_alias:
        jmp emit_not_implemented
        leave
        ret

.type parse_struct_field, @function
parse_struct_field:
        enter $16, $0
        //  -8(%rbp)  -> name descriptor
        // -16(%rbp)  -> type descriptor
        call peek_token_id
        cmp $24, %rax
        jne emit_parse_error_expected_identifier
        call next_token
        call current_token_data
        movq %rax, -8(%rbp)

        call peek_token_id
        cmp $58, %rax
        jne error_expected_colon

        call next_token
        # Current: ':'
        
        call peek_token_id
        cmp $24, %rax
        jne emit_parse_error_expected_identifier

        call next_token
        call current_token_data
        movq %rax, -16(%rbp)

        movq -8(%rbp), %rdi
        movq -16(%rbp), %rsi
        call construct_declaration
        movq %rax, %rbx
        movq $63, %rax
        leave
        ret

// out rax: token id
// out rbx: token descriptor
.type return_statement, @function
return_statement:
        enter $0, $0
        call next_token
        call parse_expression
        movq %rax, %rdi
        movq %rbx, %rsi
        call construct_return
        movq %rax, %rbx
        movq $51, %rax
        leave
        ret

// out rax: token id
// out rbx: token descriptor
.type loop_statement, @function
loop_statement:
        enter $0, $0
        call next_token
        # Current: 'loop'
        call parse_expression
        push %rax
        push %rbx

        call peek_token_id
        cmp $7, %rax
        jne emit_parse_error_missing_lcurly

        call next_token
        # Current: '{'

        call parse_statement
        push %rax
        push %rbx

        call peek_token_id
        cmp $8, %rax
        jne emit_parse_error_missing_rcurly

        call next_token
        # Current: '}'

        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_loop
        movq %rax, %rbx
        movq $49, %rax
        leave
        ret

// out rax: token id
// out rbx: token descriptor
.type function_call, @function
function_call:
        push %rbp
        movq %rsp, %rbp
        # Save the name
        call current_token_data
        push %rax
        push $0 # Assume no arg list as default
        call next_token
        # Current: '('
        call current_token_id
        cmp $5, %rax
        jne emit_parse_error_missing_lparen
        
        
        
        xor %r15, %r15 # Counter of how many arguments
        xor %r14, %r14 # Counter of how many arguments
        
        call peek_token_id
        cmp $6, %rax
        je funciton_call_skip_args
        jmp collect_arg_loop
    collect_arg_loop_consume_comma:
        call next_token
        # Current: ','
    collect_arg_loop:
        call parse_expression
        movq %rax, %rdi
        movq %rbx, %rsi
        call construct_arg
        push %rax
        inc %r15
        addq $8, %r14
        call peek_token_id
        cmp $35, %rax
        je collect_arg_loop_consume_comma

        # Construct the arg list
        leaq (%rsp), %rsi
        addq %r14, %rsi
        subq $8, %rsi
        movq %r15, %rdi
        call construct_arg_list
        addq %r14, %rsp
        movq %rax, (%rsp) # Override the arglist descriptor
    funciton_call_skip_args:
        
        call peek_token_id
        cmp $6, %rax
        jne emit_parse_error_missing_rparen
        
        call next_token
        # Current: ')'
        pop %rsi
        pop %rdi
        call construct_function_call
        movq %rax, %rbx
        movq $46, %rax
        leave
        ret

// in  rdi: bool wrap identifier in deref
// out rax: token id
// out rbx: token descriptor
.type assignment, @function
assignment:
        push %rbp
        movq %rsp, %rbp
        subq $8, %rsp
        movq %rdi, -8(%rbp)

        call peek_token_id
        cmp $37, %rax # dot '.'
        je assignment_field_acces
        cmp $9, %rax # Is it '['
        je assignment_array_identifier

        # Check for function call
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
        
        # Check if we need to wrap lhs in deref
        movq -8(%rbp), %rax
        cmp $0, %rax
        je assignment_skip_wrap_in_deref
        movq 16(%rsp), %rsi
        movq 24(%rsp), %rdi
        call construct_deref
        movq %rax, 16(%rsp)
        movq $44,  24(%rsp)
    assignment_skip_wrap_in_deref:
        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_assignment_node
        movq %rax, %rbx # Store the assignment descriptor
        movq $29, %rax  # Store the assignment id
        leave
        ret
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
        # Current: 'identifier'
        // TODO! Check peek for '[' or '='

        call peek_token_id
        cmp $4, %rax
        je assignment_parse_rhs
        
        cmp $9, %rax
        jne emit_parse_error_missing_lbracket

        call next_token
        # Current: '['

        call parse_expression
        push %rax
        push %rbx
        call next_token
        # Current: ']'

        call current_token_id
        cmp $10, %rax
        jne emit_parse_error_missing_rbracket
        
        jmp emit_not_implemented

        jmp assignment_parse_rhs
    assignment_array_identifier:
        # Store identifier
        call current_token_id
        push %rax
        call current_token_data
        push %rax
        call next_token

        call current_token_id
        cmp $9, %rax
        jne emit_parse_error_missing_lbracket

        # current: '['
        # TODO! Add error handling here.
        # For now, just assume it is a number
        call parse_expression
        push %rax
        push %rbx

        call next_token
        # current: ']'

        call current_token_id
        cmp $10, %rax
        jne emit_parse_error_missing_rbracket

        # At this point, it be
        # * An array initialization 
        # * An array access. 
        # * A field array access 

        call peek_token_id
        cmp $4, %rax
        je assignment_array_identifier_access
        cmp $37, %rax # dot '.'
        je assignment_array_field_access
    assignment_array:
        movq   (%rsp), %rdx # count
        movq 16(%rsp), %rsi # Token descriptor
        movq 24(%rsp), %rdi # Token id
        movq $8, %rcx       # Stride, ints are 8 bytes
        call construct_array_assignment
        movq %rax, %rbx
        movq $40, %rax

        # Check if '*' was present. If it was there was an error
        movq -8(%rbp), %rcx
        cmp $1, %rcx
        je emit_parse_error_unexpected_deref
        leave
        ret
    assignment_array_identifier_access:
        pop %rcx # index descriptor
        pop %rdx # index type
        pop %rsi # identifier descriptor
        pop %rdi # identifier id
        call construct_array_access
        push $41
        push %rax
        jmp assignment_parse_rhs
    assignment_array_field_access:
        # At this point we need to identify the fields that are accessed. We can then construct a field access and replace it with the identifier descriptor and id.
        call next_token
        # Current: '.'
        # peek: 'identifier'
        
        call peek_token_id
        cmp $24, %rax
        jne emit_parse_error_expected_identifier

        call peek_token_data # The field
        movq 16(%rsp), %rdi
        movq %rax, %rsi
        call construct_field_access_node
        movq %rax, %rsi
        movq $36, %rdi
        pop %rcx
        pop %rdx
        addq $16, %rsp
        call construct_array_access
        push $41
        push %rax
        call next_token
        jmp assignment_parse_rhs

// out rax: token id
// out rbx: token descriptor
.type deref_assignment, @function
deref_assignment:
        push %rbp
        movq %rsp, %rbp

        call next_token
        # Current: '*'
        
        # Assume for now that we only accept identifiers
        call next_token
        # Current: 'identifier'
        call current_token_id
        movq %rax, %rdi
        call current_token_data
        movq %rax, %rsi

        call construct_deref
        push $44
        push %rax
        
        call next_token
        # Current: '='        

        call parse_expression
        push %rax
        push %rbx

        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_assignment_node
        movq %rax, %rbx # Store the assignment descriptor
        movq $29, %rax  # Store the assignment id

        leave
        ret
// out rax: token id
// out rbx: token descriptor
.type function_declaration, @function
function_declaration:
        push %rbp
        movq %rsp, %rbp

                # eat the def
        call next_token
        # Do we have an identifier?
        call peek_token_id
        cmp $24, %rax
        jne emit_parse_error_missing_function_name

        # We have an identifier
        # Check for '(' ')'
        # Currently no args

        call next_token
        # Store the identifier descriptor
        call current_token_data
        push %rax # Store identifier
        push $0   # Zero arguments as default
        call peek_token_id
        cmp $5, %rax # '('
        jne emit_parse_error_missing_lparen
        call next_token

        xor %r15, %r15 # Counter of how many arguments
        xor %r14, %r14 # Counter of how many arguments

        call peek_token_id
        cmp $6, %rax
        je function_skip_args
        jmp collect_param_loop
    collect_param_loop_consume_comma:
        call next_token
        # Current: ','
    collect_param_loop:
        call next_token
        # Current: token descriptor
        call current_token_id
        movq %rax, %rdi
        cmp $24, %rdi
        jne emit_parse_error_unexpected_identifier
        call current_token_data
        movq %rax, %rsi
        call construct_arg
        push %rax
        inc %r15
        addq $8, %r14
        call peek_token_id
        cmp $35, %rax
        je collect_param_loop_consume_comma

        # Construct the arg list
        leaq (%rsp), %rsi
        addq %r14, %rsi
        subq $8, %rsi
        movq %r15, %rdi
        call construct_arg_list
        addq %r14, %rsp # Remvoe the args from the stack

        movq %rax, (%rsp) # Override the arglist descriptor

    function_skip_args:
        call peek_token_id
        cmp $6, %rax # ')'
        jne emit_parse_error_missing_rparen
        call next_token
        # Current: ')'

        # Push void as default return type
        call get_void_type
        push %rax

        call peek_token_id
        cmp $7, %rax
        je skip_return_type

        call next_token
        # Current: '->'

        call peek_token_id
        cmp $24, %rax
        jne emit_not_implemented
        call current_token_data
        movq %rax, %rdi
        call retrieve_identifier
        movq %rax, %rdi
        call find_type_by_charptr
        movq %rax, (%rsp)        # Replace the type
        
        call next_token
        # Current: 'type'
    skip_return_type:

        call peek_token_id
        cmp $7, %rax # '{'
        jne emit_parse_error_missing_lcurly
        call next_token 

        # Try to parse the statement
        call parse_statement
        cmp $0, %rax
        je emit_parse_error_missing_statement
        
        push %rax # Store
        push %rbx # Store

        # Check '}'
        call peek_token_id
        cmp $8, %rax
        jne emit_parse_error_missing_rcurly

        # Remove the '}'
        call next_token

        # We have a good function. Construct it and return

        pop %rdx # body descriptor
        pop %rsi # body id
        pop %r8  # Return type
        pop %rcx # arglist descriptor
        pop %rdi # identifier descriptor
        call construct_function_node
        movq %rax, %rbx
        movq $30, %rax

        leave
        ret

// out rax: token id
// out rbx: token descriptor
.type if_statement, @function
if_statement:
        push %rbp
        movq %rsp, %rbp
        
        # eat the if
        call next_token

        # parse the expression
        call parse_expression
        push %rax # id
        push %rbx # descriptor

        # eat the '{'
        call next_token

        call current_token_id
        cmp $7, %rax
        jne emit_parse_error_missing_lcurly

        call parse_statement
        push %rax # id
        push %rbx # descriptor

        # eat the '}'
        call next_token

        call current_token_id
        cmp $8, %rax
        jne emit_parse_error_missing_rcurly

        # Construct the if statement
        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_if_node
        movq %rax, %rbx
        movq $31, %rax
        leave
        ret

// out rax: token id
// out rbx: token descriptor
.type while_statement, @function
while_statement:
        push %rbp
        movq %rsp, %rbp

        call next_token
        # Current: "While"
       
        # parse the expression
        call parse_expression
        push %rax # id
        push %rbx # descriptor
        
        # eat the '{'
        call next_token

        call current_token_id
        cmp $7, %rax
        jne emit_parse_error_missing_lcurly

        call parse_statement
        push %rax # id
        push %rbx # descriptor

        # eat the '}'
        call next_token

        call current_token_id
        cmp $8, %rax
        jne emit_parse_error_missing_rcurly

        # Construct the while statement
        pop %rcx
        pop %rdx
        pop %rsi
        pop %rdi
        call construct_while_node
        movq %rax, %rbx
        movq $32, %rax
        leave
        ret

// out rax: token id
// out rbx: token descriptor
.type struct_statement, @function
struct_statement:
        push %rbp
        movq %rsp, %rbp
        # We need to determine if this is a struct declaration or an assignment
        # We do this by checking for the number og identifiers token
        # [1]: A single identifier -> declaration
        # [2]: Two identifiers -> instance

        # eat the struct
        call next_token
        # eat the first identifier
        call next_token
        
        call current_token_id
        cmp $24, %rax
        jne emit_parse_error_expected_identifier

        # Is the next token an '{' or an 'identifier'
        call peek_token_id
        cmp $24, %rax
        je struct_instance
    struct_declaration:
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

        call current_token_id
        cmp $8, %rax
        jne emit_parse_error_missing_rcurly

        # We have length in r8
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
        
        pop %rbx
        pop %rax
        leave
        ret    
    struct_instance:
        # This is an struct instance

        call current_token_data
        movq %rax, %rdi # struct name
        # Find the descriptor
        call find_struct_type_by_name
        push %rax
        movq %rax, %rdi

        call peek_token_data
        movq %rax, %rsi # variable name
        call construct_struct_instance
        push $38
        push %rax

        call next_token # Eat the variable name
        
        # Check if it is an array
        call peek_token_id
        cmp $9, %rax
        je struct_instance_array

        pop %rbx
        pop %rax
        leave
        ret
    struct_instance_array:
        call next_token
        # Current: '['

        call current_token_id
        cmp $9, %rax
        jne emit_parse_error_missing_lbracket


        call parse_expression
        push %rbx # The number of elements. MUST be number

        call next_token
        # Current: ']'

        call current_token_id
        cmp $10, %rax
        jne emit_parse_error_missing_rbracket

        # We need to find he stride and the count
        movq 24(%rsp), %rdi
        push $696969
        push $696969 # count
        push $696969
        call retrieve_struct_decl
        addq $8, %rsp
        pop %rax
        addq $8, %rsp
        movq $8, %rdx
        imulq %rdx
        
        pop %rdi        # Count descriptor
        push %rax
        call retrieve_number
        movq %rax, %rdx # Count
        pop %rcx        # stride
        pop %rsi        # descriptor
        pop %rdi        # type
        call construct_array_assignment
        movq %rax, %rbx
        movq $40, %rax
        leave
        ret

// out rax: token id
// out rbx: token descriptor
.type print_statement, @function
print_statement:
        push %rbp
        movq %rsp, %rbp
        # Move the 'print' token to current
        call next_token
        
        # Move the '(' token to current
        call next_token
        call current_token_id
        cmp $5, %rax
        jne emit_parse_error_missing_lparen

        call parse_expression
        push %rax # Store expression ID
        push %rbx # Store expression descriptor

        # Move the ')' token to current
        call next_token
        call current_token_id
        cmp $6, %rax
        jne emit_parse_error_missing_rparen

        # Construct the print statement

        pop %rsi
        pop %rdi
        call construct_print_node
        movq %rax, %rbx
        movq $39, %rax
        leave
        ret

// out rax: token_id
// out rbx: descriptor
.type parse_expression, @function
parse_expression:
        push %rbp
        mov %rsp, %rbp

        # We can have:
        # [1]: expr
        # [2]: expr && expr
        # [3]: expr || expr

        call parse_sub_expression
        push %rax
        push %rbx
    check_and_or:
        call peek_token_id
        cmp $22, %rax
        je parse_create_and # Case [3]
        cmp $23, %rax
        je parse_create_or # Case [2]
    # Case [1]
        pop %rbx
        pop %rax
        leave
        ret
    
    parse_create_and:
    parse_create_or:
        push %rax
        call next_token
        call parse_sub_expression
        movq %rax, %rdi
        movq %rbx, %rsi
        pop %rdx
        pop %r8
        pop %rcx
        call construct_binary_op_node
        push $26
        push %rax
        jmp check_and_or
    .type parse_sub_expression, @function
    parse_sub_expression:
            push %rbp
            mov %rsp, %rbp

            # We can have:
            # [1]: expr
            # [2]: expr == expr
            # [3]: expr != expr
            # [4]: expr <  expr
            # [5]: expr >  expr
            call parse_sum
            push %rax
            push %rbx
            # Check for '==', '<', '>'
            call peek_token_id
            cmp $3, %rax
            je parse_create_binop # Case [2]
            cmp $27, %rax
            je parse_create_binop # Case [3]
            cmp $17, %rax
            je parse_create_binop # Case [4]
            cmp $18, %rax
            je parse_create_binop # Case [5]
        # Case [1]
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
    # [7]: '&' expr
    # [8]: '~' expr
    # [9]: 'true'
    # [a]: 'false'
            push %rbp
            mov %rsp, %rbp
            call peek_token_id
            cmp $25, %rax
            je parse_token_return_number
            cmp $19, %rax
            je parse_token_return_true_false
            cmp $20, %rax
            je parse_token_return_true_false
            cmp $24, %rax
            je parse_token_return_identifier
            cmp $42, %rax
            je parse_token_return_addressof
            cmp $45, %rax
            je parse_token_return_deref
        # Case [1]
            # Consume the '('
            call next_token
            call parse_expression
            push %rax
            push %rbx
            # Consume the ')'
            call next_token

            call current_token_id
            cmp $6, %rax
            jne emit_parse_error_missing_rparen
            

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

            call current_token_id
            cmp $9, %rax
            jne emit_parse_error_missing_lbracket

            call parse_expression
            push %rax
            push %rbx

            call next_token
            # current: ']'

            call current_token_id
            cmp $10, %rax
            jne emit_parse_error_missing_rbracket


            call peek_token_id
            cmp $37, %rax # dot '.'
            je parse_token_return_field_access_array_access
            
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
        parse_token_return_field_access_array_access:
        # Case [6]
            call next_token 
            # current: '.'

            call next_token 
            # current 'identifier' - field
            call current_token_data
            movq %rax, %rsi
            movq 24(%rsp), %rdi
            call construct_field_access_node
            movq %rax, %rsi
            movq $36, %rdi
            
            pop %rcx
            pop %rdx
            call construct_array_access
            movq %rax, %rbx
            movq $41, %rax
            leave
            ret
        parse_token_return_addressof:
        # Case [7]
            call next_token
            # current: '&'

            call parse_expression
            movq %rax, %rdi
            movq %rbx, %rsi

            call construct_addressof
            movq %rax, %rbx
            movq $43, %rax
            leave
            ret
        parse_token_return_deref:
        # Case [8]
            call next_token
            # current: '~'

            call parse_expression
            movq %rax, %rdi
            movq %rbx, %rsi

            call construct_deref
            movq %rax, %rbx
            movq $44, %rax
            leave
            ret
        parse_token_return_true_false:
        # Case [9]
            call next_token
            # Current: 'true|false'
            call current_token_data
            movq %rax, %rbx
            call current_token_id
            leave
            ret


// in rdi: error buffer
.global emit_parse_error_exit
.type emit_parse_error_exit, @function
emit_parse_error_exit:
        push %rdi
        call count_string_len
        pop %rsi
        movq %rax, %rdx

        movq $1, %rax
        movq $1, %rdi
        syscall

        movq $1, %rax
        movq $1, %rdi
        movq $error_parse_current_id, %rsi
        movq $13, %rdx
        syscall

        call current_token_id
        movq %rax, %rdi
        call emit_number
        call emit_newline
        movq $1, %rax
        movq $1, %rdi
        movq $error_parse_current_data, %rsi
        movq $13, %rdx
        syscall

        call current_token_data
        movq %rax, %rdi
        call emit_number
        call emit_newline

        movq $1, %rax
        movq $1, %rdi
        movq $error_parse_peek_id, %rsi
        movq $13, %rdx
        syscall

        call peek_token_id
        movq %rax, %rdi
        call emit_number
        call emit_newline
        movq $1, %rax
        movq $1, %rdi
        movq $error_parse_peek_data, %rsi
        movq $13, %rdx
        syscall

        call peek_token_data
        movq %rax, %rdi
        call emit_number
        call emit_newline

        movq $60, %rax
        movq (%rax), %rax
        movq $1, %rdi
        syscall


// in rdi: count type
// in rsi: count descriptor
// in rdx: body type
// in rcx: body descriptor
// out rax: token descriptor
.global construct_loop
.type construct_loop, @function
construct_loop:
        push %rbp
        movq %rsp, %rbp

        mov loop_offset(%rip), %eax
        push %rax
        push %rdx
        
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx

        lea loop_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)

        pop %rax
        incl (loop_offset)(%rip)
        
        leave
        ret

// in rdi: name descriptor
// in rsi: type descriptor
// out rax: token descriptor
.global construct_declaration
.type construct_declaration, @function
construct_declaration:
        push %rbp
        movq %rsp, %rbp

        mov declaration_offset(%rip), %eax
        push %rax
        push %rdx
        
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx

        lea declaration_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax
        incl (declaration_offset)(%rip)
        
        leave
        ret
// in rdi: name descriptor
// in rsi: type descriptor
// in rdx: expression type
// in rcx: expression descriptor
// out rax: token descriptor
.global construct_declaration_assign
.type construct_declaration_assign, @function
construct_declaration_assign:
        push %rbp
        movq %rsp, %rbp

        mov declaration_assign_offset(%rip), %eax
        push %rax
        push %rdx
        
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx

        lea declaration_assign_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        mov %ecx, 12(%rax, %rbx)

        pop %rax
        incl (declaration_assign_offset)(%rip)
        
        leave
        ret
// in rdi: count
// in rsi: arg descriptor[]
// out rax: token descriptor
.global construct_arg_list
.type construct_arg_list, @function
construct_arg_list:
        push %rbp
        movq %rsp, %rbp

        mov arg_list_offset(%rip), %eax
        push %rax
        
        movq $4, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea arg_list_buffer(%rip), %rax
        mov %edi, (%rax, %rbx)
        xor %rdx, %rdx
    arg_list_insert_begin:
        movq (%rsi), %rcx
        movl %ecx, 4(%rax, %rbx)
        subq $8, %rsi # We are going backwards to achieve correct ordering later.
        addq $4, %rax
        inc %rdx
        cmp %rdx, %rdi
        jne arg_list_insert_begin

        pop %rax
        movq %rax, %rbx
        add %edi, %ebx
        # Store next available descriptor 
        mov %ebx, (arg_list_offset)(%rip)
        

        leave
        ret
    
// in rdi: identifier id
// in rsi: identifier descriptor
// out rax: token descriptor
.global construct_arg
.type construct_arg, @function
construct_arg:
        push %rbp
        movq %rsp, %rbp

        mov arg_offset(%rip), %eax
        push %rax
        
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea arg_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax
        incl (arg_offset)(%rip)
        leave
        ret

// in rdi: expression id
// in rsi: expression descriptor
// out rax: token descriptor
.global construct_return
.type construct_return, @function
construct_return:
        push %rbp
        movq %rsp, %rbp

        mov return_offset(%rip), %eax
        push %rax
        
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea return_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax
        incl (return_offset)(%rip)
        leave
        ret


// in rdi: identifier descriptor
// in rsi: arglist descriptor
// out rax: token descriptor
.global construct_function_call
.type construct_function_call, @function
construct_function_call:
        push %rbp
        movq %rsp, %rbp

        mov function_call_offset(%rip), %eax
        push %rax
        
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea function_call_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax
        incl (function_call_offset)(%rip)
        leave
        ret
        
// in rdi: expr tokenid
// in rsi: expr descriptor
// out rax: token descriptor
.global construct_deref
.type construct_deref, @function
construct_deref:
        push %rbp
        movq %rsp, %rbp

        mov deref_offset(%rip), %eax
        push %rax
        
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea deref_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax
        incl (deref_offset)(%rip)
        leave
        ret

// in rdi: expr tokenid
// in rsi: expr descriptor
// out rax: token descriptor
.global construct_addressof
.type construct_addressof, @function
construct_addressof:
        push %rbp
        movq %rsp, %rbp

        mov addressof_offset(%rip), %eax
        push %rax
        
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea addressof_buffer(%rip), %rax
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)

        pop %rax
        incl (addressof_offset)(%rip)
        leave
        ret

// in rdi: name descriptor
// in rsi: struct descriptor
// out rax: token descriptor
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
        incl (struct_type_offset)(%rip)
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
        incl (statement_list_offset)(%rip)
        leave
        ret

// in rdi: char *name
// in rsi: size int
// in rdx: type id (primitive_id|struct_id)
// in rcx: type descriptor
// out:    token descriptor
.global construct_type
.type construct_type, @function
construct_type:
        push %rbp
        mov %rsp, %rbp
        
        xor %rbx, %rbx
        xor %rax, %rax
        # Compute correct offst into buffer
        mov type_offset(%rip), %eax
        push %rax # Store so we can return the descriptor
        push %rdx # mulq uses rdx...
        movq $20, %rdx # Size of statementlist (16 bytes)
        mulq %rdx
        mov %rax, %rbx
        pop %rdx
        # We now have the correct offset into the buffer
        # Load buffer
        lea type_buffer(%rip), %rax
        movq %rdi,  (%rax, %rbx)
        mov %esi,  8(%rax, %rbx)
        mov %edx, 12(%rax, %rbx)
        mov %ecx, 16(%rax, %rbx)

        pop %rax # Restore descriptor
        incl (type_offset)(%rip)
        leave
        ret


// in rdi: identifier type
// in rsi: identifier descriptor
// in rdx: count SHOULD THIS BE INT ONLY
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
        incl (array_assignment_offset)(%rip)
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
        incl (array_access_offset)(%rip)
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
        incl (assignment_offset)(%rip)
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
        incl (field_access_offset)(%rip)
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
        incl (struct_instance_offset)(%rip)
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
        incl (print_statement_offset)(%rip)

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
        subq $8, %rsi # 64 bit (stack)
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
        incl (binary_op_offset)(%rip)
        leave
        ret


// in rdi: identifier
// in rsi: body id
// in rdx: body descriptor
// in rcx: arg list
// in r8: return_type descriptor
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
        movq $32, %rdx
        mulq %rdx
        mov %rax, %rbx
        pop %rdx

        lea function_buffer(%rip), %rax
        
        mov %edi,   (%rax, %rbx)
        mov %esi,  4(%rax, %rbx)
        mov %edx,  8(%rax, %rbx)
        movl $0,  12(%rax, %rbx)
        movl $0,  16(%rax, %rbx)
        mov %ecx, 20(%rax, %rbx)
        mov %r8d, 24(%rax, %rbx)

        pop %rax # Restore descriptor
        incl (function_offset)(%rip)
        # Store next available descriptor 
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
        incl (if_offset)(%rip)

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
        incl (while_offset)(%rip)
        leave
        ret




// in rdi: Token descriptor
// out 16(%rbp): Count type
// out 24(%rbp): Count descriptor
// out 32(%rbp): body type
// out 40(%rbp): body descriptor
.global retrieve_loop
.type retrieve_loop, @function
retrieve_loop:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea loop_buffer(%rip), %rax
        addq %rbx, %rax
        mov   (%rax), %edi
        mov  4(%rax), %esi
        mov  8(%rax), %edx
        mov 12(%rax), %ecx
        
        mov %edi, 16(%rbp)
        mov %rsi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

        leave
        ret
// in rdi: Token descriptor
// out 16(%rbp): name descriptor
// out 24(%rbp): type descriptor
.global retrieve_declaration
.type retrieve_declaration, @function
retrieve_declaration:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea declaration_buffer(%rip), %rax
        addq %rbx, %rax
        mov   (%rax), %edi
        mov  4(%rax), %esi
        
        mov %edi, 16(%rbp)
        mov %rsi, 24(%rbp)

        leave
        ret
// in rdi: Token descriptor
// out 16(%rbp): name descriptor
// out 24(%rbp): type descriptor
// out 32(%rbp): value type
// out 40(%rbp): value descriptor
.global retrieve_declaration_assign
.type retrieve_declaration_assign, @function
retrieve_declaration_assign:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $16, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea declaration_assign_buffer(%rip), %rax
        addq %rbx, %rax
        mov   (%rax), %edi
        mov  4(%rax), %esi
        mov  8(%rax), %edx
        mov 12(%rax), %ecx
        
        mov %edi, 16(%rbp)
        mov %rsi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)

        leave
        ret
// in rdi: Token descriptor
// out 16(%rbp): Count
// out 24(%rbp): Arg Descriptor*
.global retrieve_arg_list
.type retrieve_arg_list, @function
retrieve_arg_list:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $4, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea arg_list_buffer(%rip), %rax
        addq %rbx, %rax
        mov   (%rax), %edi
        leaq 4(%rax), %rsi
        
        mov %edi, 16(%rbp)
        mov %rsi, 24(%rbp)

        leave
        ret

// in rdi: Token descriptor
// out 16(%rbp): identifier id
// out 24(%rbp): identifier descriptor
.global retrieve_arg
.type retrieve_arg, @function
retrieve_arg:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea arg_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi
        mov  4(%rax, %rbx), %esi
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

        leave
        ret

// in rdi: Token descriptor
// out 16(%rbp): expression id
// out 24(%rbp): expression descriptor
.global retrieve_return
.type retrieve_return, @function
retrieve_return:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea return_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi
        mov  4(%rax, %rbx), %esi
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

        leave
        ret


// in rdi: Token descriptor
// out 16(%rbp): identifier descriptor
// out 24(%rbp): arglist descriptor
.global retrieve_function_call
.type retrieve_function_call, @function
retrieve_function_call:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea function_call_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi
        mov  4(%rax, %rbx), %esi
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

        leave
        ret

// in rdi: Token descriptor
// out 16(%rbp): expr id
// out 24(%rbp): expr descriptor
.global retrieve_deref
.type retrieve_deref, @function
retrieve_deref:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea deref_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi
        mov  4(%rax, %rbx), %esi
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

        leave
        ret

// in rdi: Token descriptor
// out 16(%rbp): expr id
// out 24(%rbp): expr descriptor
.global retrieve_addressof
.type retrieve_addressof, @function
retrieve_addressof:
        push %rbp
        movq %rsp, %rbp

        mov %rdi, %rax
        movq $8, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea addressof_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi
        mov  4(%rax, %rbx), %esi
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)

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
// out 16(%rbp): char *name
// out 24(%rbp): size int
// out 32(%rbp): type id (primitive_id|struct_id)
// out 40(%rbp): type_descriptor
.type retrieve_type, @function
.global retrieve_type
retrieve_type:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea type_buffer(%rip), %rax
        
        movq  (%rax, %rbx), %rdi
        mov  8(%rax, %rbx), %esi
        mov 12(%rax, %rbx), %edx
        mov 16(%rax, %rbx), %ecx
        
        movq %rdi, 16(%rbp)
        mov  %esi, 24(%rbp)
        mov  %edx, 32(%rbp)
        mov  %ecx, 40(%rbp)

        leave
        ret


// in rdi: Token descriptor
// out 16(%rbp): identifier id
// out 24(%rbp): identifier descriptor
// out 32(%rbp): count SHOULD THIS BE INT ONLY
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

// in  rdi: token descriptor
// in  rsi: token id
// out rax: stride in bytes
.type retrieve_stride_from_identifier, @function
.global retrieve_stride_from_identifier
retrieve_stride_from_identifier:
        push %rbp
        movq %rsp, %rbp

        lea array_assignment_buffer(%rip), %rax

        movl (%rax), %ebx
        cmp $38, %ebx # Structc instance
        je retrieve_stride_from_struct
        cmp $24, %ebx # variable
        je retrieve_stride_from_ident
        movq $error_array_assignment_, %rdi
        jmp emit_storage_error_unknown_id___
    retrieve_stride_from_struct:
        # get the cont
        movq %rsi, %rdi
        push $696969 # identifier descriptor
        push $696969 # struct descriptor
        call retrieve_struct_instance
        pop %rsi
        addq $8, %rsp
        push $696969 # field descriptors
        push $696969 # field count
        push $696969 # struct name
        call retrieve_struct_decl
        addq $8, %rsp
        pop %rax
        movq $8, %rdx
        imulq %rdx
        leave
        ret
    retrieve_stride_from_ident:
        movq $8, %rax
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
// out 54(%rbp): arg list descriptor
// out 64(%rbp): return_type descriptor
.type retrieve_function, @function
.global retrieve_function
retrieve_function:
        push %rbp
        mov %rsp, %rbp 
        mov %rdi, %rax
        movq $32, %rdx
        mulq %rdx
        mov %rax, %rbx

        lea function_buffer(%rip), %rax
        
        mov   (%rax, %rbx), %edi # identifier
        mov  4(%rax, %rbx), %esi # body id
        mov  8(%rax, %rbx), %edx # body descriptor
        mov 12(%rax, %rbx), %ecx # variable count int
        mov 16(%rax, %rbx), %r8d # symbol table descriptor
        mov 20(%rax, %rbx), %r9d # arg list descriptor
        mov 24(%rax, %rbx), %r10d # return_type descriptor
        
        mov %edi, 16(%rbp)
        mov %esi, 24(%rbp)
        mov %edx, 32(%rbp)
        mov %ecx, 40(%rbp)
        mov %r8d, 48(%rbp)
        mov %r9d, 54(%rbp)
        mov %r10d,64(%rbp)

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

// in  rdi: char *name
// out rax: Type descriptor
.type find_type_by_charptr, @function
.global find_type_by_charptr
.type get_void_type, @function
.global get_void_type
get_void_type:
        lea token_void(%rip), %rdi
find_type_by_charptr:
        enter $24, $0

        lea type_buffer(%rip), %rsi
        movq $0,    -8(%rbp) # Counter
        movq %rsi, -16(%rbp) # Haystack
        movq %rdi, -24(%rbp) # Needle

    find_type_by_charptr_loop:
        cmp $0, (%rsi)
        je find_type_by_charptr_type_not_found

        movq (%rsi), %rsi # Hay
        call cmp_string
        cmpb $1, %al
        je find_type_by_charptr_found_type

        incq -8(%rbp)
        addq $20, -16(%rbp)
        movq -16(%rbp), %rsi # Haystack
        movq -24(%rbp), %rdi # Needle
        jmp find_type_by_charptr_loop
    
    find_type_by_charptr_type_not_found:
        movq $-1, %rax
        leave
        ret
    find_type_by_charptr_found_type:
        movq -8(%rbp), %rax
        leave
        ret

// in  rdi: char *name
// out rax: function descriptor
.type find_function_by_charptr, @function
.global find_function_by_charptr
find_function_by_charptr:
        enter $24, $0

        lea function_buffer(%rip), %rsi
        movl function_offset(%rip), %r8d
        movq $0,    -8(%rbp) # Counter
        movq %rsi, -16(%rbp) # Haystack
        movq %rdi, -24(%rbp) # Needle

    find_function_by_charptr_loop:
        cmp %r8, -8(%rbp)
        je find_function_by_charptr_not_found

        
        movl (%rsi), %edi
        call retrieve_identifier
        movq %rax, %rsi # Hay
        movq -24(%rbp), %rdi # Needle
        call cmp_string
        cmpb $1, %al
        je find_function_by_charptr_found

        incq -8(%rbp)
        addq $32, -16(%rbp)
        movq -16(%rbp), %rsi # Haystack
        jmp find_function_by_charptr_loop
    
    find_function_by_charptr_not_found:
        movq $-1, %rax
        leave
        ret
    find_function_by_charptr_found:
        movq -8(%rbp), %rax
        leave
        ret

// in rdi:  token descriptor
// in rsi:  token id (24/36)
// out rax: assignment descriptor
.type find_array_assignment_by_identifier, @function
.global find_array_assignment_by_identifier
find_array_assignment_by_identifier:
        push %rbp
        movq %rsp, %rbp
        cmp $24, %rsi
        je array_assignment_token_is_identifier
        push $696969 # field
        push $696969 # var 
        call retrieve_field_access
        pop %rdi
        addq $8, %rsp
    array_assignment_token_is_identifier:
        call retrieve_identifier
        movq %rax, %rdi

        mov array_assignment_offset(%rip), %r8d
        # Total num to check
        lea array_assignment_buffer(%rip), %rsi
        addq $4, %rsi # Place offset ontop of identifier descriptor

        xor %rcx, %rcx
    check_next_array:
        push %rcx
        push %rsi
        push %rdi
        mov -4(%rsi), %edi
    brrrrr:
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
