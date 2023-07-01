.section .data
.global symbol_buffer
        symbol_buffer:          .space 256
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
        xor %rbx, %rbx
    loop_begin:
        dec %rcx
        push %rcx
        push %rbx
        mov %ebx, (_current_function)(%rip)
        mov %ebx, %edi
        call set_symbol_table
        call reset_symbol_count
        pop %rbx
        movq %rbx, %rdi
        push %rbx
        call visit_function

        movl (_current_function)(%rip), %edi
        call set_symbol_count


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

        pop %rdi # Function identifier
        pop %rdi # body id
        pop %rsi # body descriptor
    check_for_statement_id:
        cmp $28, %rdi # statement_list
        je statement_list
        cmp $29, %rdi
        je do_assignment
        cmp $31, %rdi
        je symbol_if
        leave # If we reach here, something bad happend....
        ret

    symbol_if:
        push $696969
        push $696969
        push $696969
        push $696969
        movq %rsi, %rdi
        call retrieve_if
        addq $16, %rsp # remove the guard
        pop %rdi
        pop %rsi
        jmp check_for_statement_id
    do_assignment:
        call assignment
        leave
        ret
        

    statement_list:
        # Check left side. Then jump back up
        push $696969
        push $696969
        push $696969
        push $696969
        movq %rsi, %rdi
        call retrieve_statement_list
        pop %rdi # LHS id
        pop %rsi # LHS descriptor
        cmp $29, %rdi # Assignment
        jne check_right_side

        # It is an assignment
        call assignment

    check_right_side:
        pop %rdi # RHS id
        pop %rsi # RHS descriptor
        cmp $28, %rdi # Statement_list
        je statement_list
        cmp $29, %rdi # assignment
        je do_assignment

        # We have reached the end of this function's body
        leave
        ret

.type assignment, @function
assignment:
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
        call retrieve_assignment
        pop %rdi # identifier
        call set_offset_on_stack
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
        cmp $0, (%rax)
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
.global get_offset_on_stack
.type get_offset_on_stack, @function
get_offset_on_stack:
        push %rbp
        mov %rsp, %rbp
        
        call locate_symbol
        movl 8(%rax), %eax
        cltq # Sign extend. (remove the top 32 bits rax)
        leave
        ret

// in rdi: the descriptor of the identifier
// Im kinda assumning that it fills with zeros......
.type is_symbol_registered, @function
is_symbol_registered:
        push %rbp
        mov %rsp, %rbp
        call locate_symbol
        cmp $0, (%rax)
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
        mov %rsp, %rbp
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