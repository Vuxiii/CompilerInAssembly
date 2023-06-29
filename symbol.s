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

        # We want to iterate over each  funciton. This can be done by iterating over the function_buffer.
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
        movq $0, %r15 # Keep track if we have set our subtract_offset.
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

        cmp $28, %rdi # statement_list
        je statement_list
        cmp $29, %rdi
        je do_assignment
        leave # If we reach here, something bad happend....
        ret

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
        subq $8, %rsp

        cmp $0, %r15 # If 0 it's the first symbol in this function
        jne offset_is_set
        inc %r15 # It is now set

        # Set offset
        # descriptor
        push %rdi
        call set_offset
        jmp new_symbol # We know this is a new symbol
    offset_is_set:
        push %rdi
        # Check if we already have this symbol
        call is_symbol_registered
        cmp $0, %rax
        je new_symbol
        leave
        ret

    new_symbol:
        call increase_symbol_count
        # Give the symbol an offset
        pop %rdi
        call set_offset_on_stack

        leave
        ret

// in rdi: The descriptor for the identifier
.type set_offset_on_stack, @function
set_offset_on_stack:
        push %rbp
        mov %rsp, %rbp

        push %rdi
        xor %rax, %rax
        call get_offset
        movq %rax, %rcx
        push %rcx
        call get_symbol_table
        pop %rcx
        pop %rdi
        push %rax
        subq %rcx, %rdi
        # Multiply this number by sizeof(int) = 4
        movq $4, %rdx
        movq %rdi, %rax
        imulq %rdx
        movq %rax, %rdi

        pop %rax
        addq %rdi, %rax


        # Update the offset into the symbol table.
        push %rdi
        addl $8, %edi
        movl %edi, (symbol_offset)(%rip)
        pop %rdi
        push %rax   
        call get_symbol_count
        movq %rax, %rdi
        pop %rax
        
        movl %edi, (%rax)

        leave
        ret

// in rdi: the descriptor of the identifier
.global get_offset_on_stack
.type get_offset_on_stack, @function
get_offset_on_stack:
        push %rbp
        mov %rsp, %rbp
        push %rdi
        xor %rax, %rax
        call get_offset
        movq %rax, %rcx
        push %rcx
        call get_symbol_table
        pop %rcx
        pop %rdi

        push %rax
        subq %rcx, %rdi
        # Multiply this number by sizeof(int) = 4
        movq $4, %rdx
        movq %rdi, %rax
        imulq %rdx
        movq %rax, %rdi

        pop %rax

        addq %rdi, %rax
        
        movl (%rax), %eax
        cltq # Sign extend. (remove the top 32 bits rax)
        leave
        ret

// in rdi: the descriptor of the identifier
// Im kinda assumning that it fills with zeros......
.type is_symbol_registered, @function
is_symbol_registered:
        push %rbp
        mov %rsp, %rbp
        call get_offset_on_stack
        cmp $0, %rax
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
        addq $4, %rax
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

// in rdi: function descriptor
.global set_current_function
.type set_current_function, @function
set_current_function:
        push %rbp
        mov %rsp, %rbp

        mov %rdi, (_current_function)(%rip)

        leave
        ret


// in edi: The offset to subtract on each lookup
// This method also updates the symbol table pointer for the function
.type set_offset, @function
set_offset:
        push %rbp
        mov %rsp, %rbp
        call get_symbol_table
        movl %edi, -4(%rax)
        leave
        ret

// out rax: The offset to subtract on each lookup
.type get_offset, @function
get_offset:
        push %rbp
        mov %rsp, %rbp
        call get_symbol_table
        movl -4(%rax), %eax
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

