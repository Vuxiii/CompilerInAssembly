.global symbol_buffer
        symbol_buffer:          .space 256
.global symbol_offset
        symbol_offset:          .int 0

.extern function_offset
.extern function_buffer


_current_symbol_count_:         .int 0
current_function:               .int 0
.section .text

.type collect, @function
.global collect
collect:
        push %rbp
        mov %rsp, %rbp
        # We want to iterate over each  funciton. This can be done by iterating over the function_buffer.
        xor %rcx, %rcx
        mov function_offset(%rip), %ecx # Total amount of functions

        xor %rbx, %rbx
    loop_begin:
        dec %rcx
        push %rcx
        push %rbx
        movl %ebx, current_function(%rip)
        call reset_symbol_count
        movq %rbx, %rdi
        call visit_function
        
        pop %rbx
        pop %rcx
        inc %rbx
        jnz loop_begin

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
        # Check if we already have seen this assignment
        # If yes: return
        # If no: increase var count. Find place on stack for var

        cmp $0, %r15 # If 0 it's the first symbol in this function
        jne offset_is_set
        inc %r15 # It is now set

        # Set offset
        # descriptor - 4 (4 to ensure the offset is not overwritten)
        push %rdi
        subq $4, %rsi
        movq %rsi, %rdi
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
        call get_symbol_table
        pop %rdi

        subq %rcx, %rdi
        addq %rdi, %rax
        push %rax
        call get_symbol_count
        movq %rax, %rdi
        pop %rax
        
        movl %edi, (%rax)

        leave
        ret

// in rdi: the descriptor of the identifier
.type get_offset_on_stack, @function
get_offset_on_stack:
        push %rbp
        mov %rsp, %rbp
        push %rdi
        xor %rax, %rax
        call get_offset
        movq %rax, %rcx
        call get_symbol_table
        pop %rdi

        subq %rcx, %rdi
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
        movl current_function(%rip), %eax
        movq $20, %rdx
        mov %rax, %rbx # Offset
        lea function_buffer(%rip), %rax
        xor %rcx, %rcx
        movl 16(%rax, %rbx), %ecx # Get the symbol_table descriptor

        lea symbol_buffer(%rip), %rax
        addq %rcx, %rax
        addq $4, %rax
        leave
        ret

// in edi: The offset to subtract on each lookup
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


.type increate_symbol_count, @function
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

