.section .data
.global symbol_buffer
        symbol_buffer:          .space 256
.global struct_symbol_buffer
        struct_symbol_buffer:          .space 256
.global symbol_offset
        symbol_offset:          .int 0

.extern function_offset
.extern function_buffer


_current_symbol_count_:         .int 0
_current_function:              .int 0

.section .text

.type collect, @function
.global collect
collect:
        push %rbp
        mov %rsp, %rbp
        lea symbol_buffer(%rip), %rax

        # We want to iterate over each funciton. This can be done by iterating over the function_buffer.
        xor %rcx, %rcx
        mov function_offset(%rip), %ecx # Total amount of functions
        cmp $0, %ecx
        je emit_missing_main_function
        xor %rbx, %rbx
    loop_begin:
        dec %rcx
        push %rcx
        push %rbx
        mov %ebx, (_current_function)(%rip)
        mov %ebx, %edi
        callq set_symbol_table
        callq reset_symbol_count
        pop %rbx
        movq %rbx, %rdi
        push %rbx
        callq visit_function

        movl (_current_function)(%rip), %edi
        callq set_symbol_count

    testlabel:
        pop %rbx
        pop %rcx
        inc %rbx
        test %rcx, %rcx
        jnz loop_begin

        # Now we should have the offsets on the stack for each variable. Let us test it

        leave
        ret

// in rdi: function descriptor
.type visit_function, @function
visit_function:
        push %rbp
        mov %rsp, %rbp
        push %rdi # Might need to store it.

        push $696969
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_function

        addq $8, %rsp # Remove Function identifier
        pop %rdi # body id
        pop %rsi # body descriptor
        call symbol_check_statement_kind        

        # Done checking this functions statements.
        leave
        ret

// in rdi: token id
// in rsi: token descriptor
.type symbol_check_statement_kind, @function
symbol_check_statement_kind:
        push %rbp
        movq %rsp, %rbp
        
        cmp $28, %rdi # statement_list
        je symbol_check_call_statement_list
        cmp $29, %rdi
        je symbol_check_call_assignment
        cmp $31, %rdi
        je symbol_check_call_if
        cmp $32, %rdi
        je symbol_check_call_while
        cmp $33, %rdi
        je symbol_check_call_struct_decl
        cmp $38, %rdi
        je symbol_check_call_struct_instance
        cmp $40, %rdi
        je symbol_check_call_array_assignment

        # Found nothing. Return...
        jmp symbol_check_statement_kind_end
    symbol_check_call_statement_list:
        call symbol_statement_list
        jmp symbol_check_statement_kind_end
    symbol_check_call_assignment:
        call symbol_assignment
        jmp symbol_check_statement_kind_end
    symbol_check_call_if:
        call symbol_if
        jmp symbol_check_statement_kind_end
    symbol_check_call_while:
        call symbol_while
        jmp symbol_check_statement_kind_end
    symbol_check_call_struct_decl:
        call symbol_struct_decl
        jmp symbol_check_statement_kind_end
    symbol_check_call_struct_instance:
        call symbol_struct_instance
        jmp symbol_check_statement_kind_end
    symbol_check_call_array_assignment:
        call symbol_array_assignment
        jmp symbol_check_statement_kind_end
    symbol_check_statement_kind_end:
        leave
        ret

.type symbol_array_assignment, @function
symbol_array_assignment:
        push %rbp
        movq %rsp, %rbp

        # We want to ensure that we offset enough on the stack.
        
        movq %rsi, %rdi
        push $696969 # stride
        push $696969 # count
        push $696969 # identifier descriptor
        push $696969 # identifier id
        call retrieve_array_assignment
        # Check if it is an identifier or a struct
        
        pop %rdi # id type
        cmp $38, %rdi
        je symbol_array_assignment_struct
        pop %rdi # descriptor
        call set_offset_on_stack
        call decrease_symbol_count

        pop %rdi # Count
        call retrieve_number
        movq %rax, %rdi
        call increase_symbol_count_by
        leave
        ret
    symbol_array_assignment_struct:
        pop %rdi # descriptor
        push $696969 # variable name descriptor
        push $696969 # struct descriptor
        call retrieve_struct_instance
        movq 8(%rsp), %rdi # Variable name descriptor
        call set_offset_on_stack
        call decrease_symbol_count

        pop %rdi # struct descriptor.
        addq $8, %rsp
        push $696969 # field descriptor
        push $696969 # count
        push $696969 # name
        call retrieve_struct_decl
        addq $8, %rsp
        pop %rdx # Count
    breakhere1:
        addq $8, %rsp
        movq (%rsp), %rax # stride
        imulq %rdx        # Count
        
        movq %rax, %rdi
        call increase_symbol_count_by

        leave
        ret

.type symbol_struct_instance, @function
symbol_struct_instance:
        push %rbp
        movq %rsp, %rbp
        
        push $696969 # identifier descriptor
        push $696969 # struct descriptor
        movq %rsi, %rdi
        call retrieve_struct_instance
        
        pop %rsi # Struct descriptor
        pop %rdi # var descriptor
        push %rsi
        call set_offset_on_stack
        
        pop %rdi # Struct descriptor
        
        push $696969 # field descriptor *
        push $696969 # field count
        push $696969 # struct name identifier

        call retrieve_struct_decl

        pop %rdi # struct var descriptor
        pop %rdx # field count
        # Increase the offset by rdx - 1 to compensate for the fields in the struct.
    correct_stack_offset_loop:
        cmp $1, %rdx
        je correct_stack_offset_done
        call increase_symbol_count
        dec %rdx
        jmp correct_stack_offset_loop
    correct_stack_offset_done:
        leave
        ret

.type symbol_struct_decl, @function
symbol_struct_decl:
        push %rbp
        movq %rsp, %rbp

       
        leave
        ret

.type symbol_if, @function
symbol_if:
        push %rbp
        movq %rsp, %rbp
        push $696969
        push $696969
        push $696969
        push $696969
        movq %rsi, %rdi
        call retrieve_if
        addq $16, %rsp # remove the guard
        
        pop %rdi
        pop %rsi
        # Check for which statement the body is.
        call symbol_check_statement_kind
        leave
        ret
     
.type symbol_while, @function
symbol_while:
        push %rbp
        movq %rsp, %rbp
        push $696969
        push $696969
        push $696969
        push $696969
        movq %rsi, %rdi
        call retrieve_while
        addq $16, %rsp # remove the guard
        
        pop %rdi
        pop %rsi
        # Check for which statement the body is.
        call symbol_check_statement_kind
        leave
        ret
           

.type symbol_statement_list, @function
symbol_statement_list:
        push %rbp
        movq %rsp, %rbp
        # Check left side. Then jump back up
        push $696969
        push $696969
        push $696969
        push $696969
        movq %rsi, %rdi
        call retrieve_statement_list
        
        pop %rdi # LHS id
        pop %rsi # LHS descriptor
        call symbol_check_statement_kind
        
        pop %rdi # RHS id
        pop %rsi # RHS descriptor
        call symbol_check_statement_kind

        # We have reached the end of this function's body
        leave
        ret

.type symbol_assignment, @function
symbol_assignment:
        push %rbp
        mov %rsp, %rbp
        # Check if we already have seen this assignment
        # If yes: return
        # If no: increase var count. Find place on stack for var
        movq %rsi, %rdi
        # Extract the identifier from the assignment
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_assignment
        pop %rsi # id
        cmp $41, %rsi
        je symbol_assignment_array_access
        cmp $24, %rsi
        jne symbol_assignment_skip_field_access
        pop %rdi # descriptor
        call set_offset_on_stack
        leave
        ret
    symbol_assignment_array_access:
        pop %rdi
        push $696969 # index descriptor
        push $696969 # index id
        push $696969 # descriptor
        push $696969 # id
        call retrieve_array_access
        pop %rsi
        cmp $24, %rsi
        je symbol_assignment_array_access_identifier
        
        # It is a field access.

        leave
        ret
    symbol_assignment_array_access_identifier:
        pop %rdi # identifier
        call set_offset_on_stack
        leave
        ret
    symbol_assignment_skip_field_access:
        leave
        ret

// in rdi:  identifier descriptor
// out rax: pointer to struct { char *, int offset}
// This method returns either the position in the symbol_buffer or an empty spot if the identifier hasn't been inserted yet.
.type locate_symbol, @function
locate_symbol:
        push %rbp
        mov %rsp, %rbp
        call retrieve_identifier
        push %rax
        call get_symbol_table
        xor %rcx, %rcx # Is the index into rax
        xor %rdx, %rdx # Is the index into rdi
        pop %rdi
        
        # rdi stores the variable
        # rax is the symbol_buffer
        # rsi stores the stored char * in the buffer
        # first 8 bytes is the pointer
        # next 4 bytes is the offset
    locate_symbol_loop_begin:
        movq (%rax), %rsi
        # if rsi is 0, then it was not found
        cmp $0, %rsi
        je return_empty_spot
        push %rdi
        push %rax
        call cmp_string
        cmp $1, %rax
        je symbol_located
        pop %rax
        pop %rdi
        addq $12, %rax
        jmp locate_symbol_loop_begin
    return_empty_spot:
        leave
        ret
    symbol_located:
        pop %rax
        leave
        ret

// in rdi: The descriptor for the identifier
.type set_offset_on_stack, @function
set_offset_on_stack:
        push %rbp
        mov %rsp, %rbp
        # We can use the fact that locate_symbol returns an empty spot if it doesn't exist in the table
        push %rdi
        call locate_symbol
        pop %rdi
        # Check if it already is in there.
        cmpl $0, (%rax)
        jne already_inserted

        call increase_symbol_count
        push %rax
        call retrieve_identifier
        movq %rax, %rdi
        pop %rax
        movq %rdi, (%rax)
        movq %rax, %rbx
        call get_symbol_count
        movl %eax, 8(%rbx)
    already_inserted:
        leave
        ret

// in rdi: the descriptor of the identifier
// in rsi: token field/identifier
.global get_offset_on_stack
.type get_offset_on_stack, @function
get_offset_on_stack:
        push %rbp
        mov %rsp, %rbp
        cmp $36, %rsi
        je get_field_offset

        call locate_symbol
        movl 8(%rax), %eax
        cltq # Sign extend. (remove the top 32 bits rax)
        leave
        ret
    get_field_offset:
        # Step [1]: Locate the symbol
        # Step [2]: Locate the field offset
        push $696969
        push $696969
        call retrieve_field_access
        pop %rsi # field descriptor
        pop %rdi # variable descriptor
        push %rsi
        call retrieve_identifier
        movq %rax, %r11
        
        pop %rdi
        push %rdi
        call locate_symbol
        movl 8(%rax), %r13d # The base offset
        pop %rdi
        
        # Find the correct struct type by name
        call find_struct_type_by_name
        movq %rax, %rdi
        push $696969
        push $696969
        push $696969
        call retrieve_struct_decl
        pop %rdi # name descriptor
        pop %rdi # field count
        pop %rdi # field descriptor *
        # Count the offset for the field in the struct decl.
    add_offset_loop:
        push %rdi
        movl (%rdi), %edi
        call retrieve_identifier
        movq %rax, %rsi
        movq %r11, %rdi
        call cmp_string
        cmp $1, %rax
        je found_correct_offset
        pop %rdi
        addq $4, %rdi
        add $1, %r13d
        jne add_offset_loop
    found_correct_offset:
        mov %r13d, %eax
        cltq
        leave
        ret


// in rdi: the descriptor of the identifier
// Im kinda assumning that it fills with zeros......
.type is_symbol_registered, @function
is_symbol_registered:
        push %rbp
        mov %rsp, %rbp
        call locate_symbol
        cmpl $0, (%rax)
        jg true
        movq $0, %rax
        leave
        ret
    true:
        movq $1, %rax
        leave
        ret

// out rax: The pointer to the symbol table
.type get_symbol_table, @function
get_symbol_table:
        push %rbp
        mov %rsp, %rbp

        xor %rax, %rax
        movl _current_function(%rip), %eax
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx # Offset
        lea function_buffer(%rip), %rax
        xor %rcx, %rcx
        movl 16(%rax, %rbx), %ecx # Get the symbol_table descriptor

        lea symbol_buffer(%rip), %rax
        addq %rcx, %rax
        # addq $4, %rax
        leave
        ret

// in rdi: Function descriptor
.type set_symbol_table, @function
set_symbol_table:
        push %rbp
        mov %rsp, %rbp
        xor %rax, %rax
        movl %edi, %eax
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx # Offset
        lea function_buffer(%rip), %rax
        movl symbol_offset(%rip), %ecx
        movl %ecx, 16(%rax, %rbx) # Set the symbol table descriptor

        leave
        ret

// in rdi: Function descriptor
.type set_symbol_count, @function
set_symbol_count:
        push %rbp
        movq %rsp, %rbp
        xor %rax, %rax
        movl %edi, %eax
        movq $20, %rdx
        mulq %rdx
        mov %rax, %rbx # Offset
        call get_symbol_count
        mov %eax, %ecx
        lea function_buffer(%rip), %rax
        movl %ecx, 12(%rax, %rbx)

        leave
        ret

// in rdi: function descriptor
.global set_current_function
.type set_current_function, @function
set_current_function:
        push %rbp
        mov %rsp, %rbp

        mov %edi, (_current_function)(%rip)

        leave
        ret


// out eax: The current symbol count
.type get_symbol_count, @function
get_symbol_count:
        push %rbp
        mov %rsp, %rbp
        movl _current_symbol_count_(%rip), %eax
        cltq
        leave
        ret


.type reset_symbol_count, @function
reset_symbol_count:
        push %rbp
        mov %rsp, %rbp
        movl $0, _current_symbol_count_(%rip)
        leave
        ret


.type increase_symbol_count, @function
increase_symbol_count:
        push %rbp
        mov %rsp, %rbp
        push %rax
        movl _current_symbol_count_(%rip), %eax
        inc %eax
        movl %eax, _current_symbol_count_(%rip)
        pop %rax
        leave
        ret

.type decrease_symbol_count, @function
decrease_symbol_count:
        push %rbp
        mov %rsp, %rbp
        push %rax
        movl _current_symbol_count_(%rip), %eax
        dec %eax
        movl %eax, _current_symbol_count_(%rip)
        pop %rax
        leave
        ret

// in rdi: amount to increase by
.type increase_symbol_count_by, @function
increase_symbol_count_by:
        push %rbp
        mov %rsp, %rbp
        push %rax
        movl _current_symbol_count_(%rip), %eax
        addl %edi, %eax
        movl %eax, _current_symbol_count_(%rip)
        pop %rax
        leave
        ret
