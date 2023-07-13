.section .data

current_indent: .int 0
.section .text

.type astprint, @function
.global astprint
astprint:
        push %rbp
        movq %rsp, %rbp

        call astprint_statement

        leave
        ret

astprint_statement:
        push %rbp
        movq %rsp, %rbp

        cmp $29, %rdi
        je astprint_assignment
        cmp $28, %rdi
        je astprint_statement_list
        cmp $30, %rdi
        je astprint_function
        cmp $31, %rdi
        je astprint_if
        cmp $32, %rdi
        je astprint_while
        cmp $39, %rdi
        je astprint_print
        leave
        ret

    astprint_assignment:
        push $696969 # expression descriptor
        push $696969 # expression id
        push $696969 # identifier descriptor
        push $696969 # identifier id
        movq %rsi, %rdi
        call retrieve_assignment
        
        call emit_assignment

        call increase_indent
        
        call emit_newline
        call indent

        call emit_lhs
        call emit_id
        movq (%rsp), %rdi
        call emit_number
        
        call emit_newline
        call indent

        call emit_lhs
        call emit_desc

        pop %rdi
        pop %rsi
        call astprint_expr

        call emit_newline
        call indent

        call emit_rhs
        call emit_id
        pop %rdi
        pop %rsi
        push %rdi
        push %rsi
        call emit_number

        call emit_newline
        call indent

        call emit_rhs
        call emit_desc
        
        pop %rdi
        pop %rsi
        push %rdi
        push %rsi
        call emit_number
        call emit_arrow
        pop %rdi
        pop %rsi

        call astprint_expr
        
        call decrease_indent

        call emit_newline

        leave
        ret
    astprint_statement_list:
        movq %rsi, %rdi
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_statement_list
        // call indent
        # LHS
        pop %rdi
        pop %rsi
        call astprint_statement
        call indent
        
        pop %rdi
        pop %rsi
        call astprint_statement
        leave
        ret
    astprint_function:
        movq %rsi, %rdi
        call set_current_function
        push $696969
        push $696969
        push $696969
        push $696969
        push $696969
        call retrieve_function
        call emit_function
        pop %rdi # Identifier
        call emit_identifier
        call emit_colon
        call emit_newline
        call increase_indent        
        # Make place for local vars on the stack 
        pop %rsi # body id
        pop %rdx # body descriptor
        pop %rax # var count
        pop %r8  # symbol_table offset

        movq %rsi, %rdi
        movq %rdx, %rsi
        call astprint_statement
        call decrease_indent
        leave
        ret
    astprint_if:
        movq %rsi, %rdi
        push $696969 # body descriptor
        push $696969 # body id
        push $696969 # guard expr
        push $696969 # guard id
        call retrieve_if
        
        call indent
        call emit_if_
        call emit_newline
        astprint_if_header_done:
            call increase_indent
            call indent
            call emit_guard
            call emit_id
            movq (%rsp), %rdi
            call emit_number
            
            call emit_newline
            call indent
            call emit_guard
            call emit_desc
            movq (%rsp), %rsi
            movq 8(%rsp), %rdi
            call emit_number
            call emit_arrow

            pop %rdi
            pop %rsi
            call astprint_expr

            call emit_newline
            call indent
            call emit_body_
            call emit_id
            movq (%rsp), %rdi
            call emit_number
            
            call emit_newline
            call indent
            
            call emit_body_
            call emit_desc
            movq (%rsp), %rsi
            movq 8(%rsp), %rdi
            call emit_number
            call emit_arrow
            pop %rdi
            pop %rsi
            call astprint_statement
            call decrease_indent
            leave
            ret
    astprint_while:
        movq %rsi, %rdi
        push $696969 # body descriptor
        push $696969 # body id
        push $696969 # guard expr
        push $696969 # guard id
        call retrieve_while
        
        call indent
        call emit_while_
        call emit_newline
        jmp astprint_if_header_done    
    astprint_print:
        movq %rsi, %rdi
        push $696969
        push $696969
        call retrieve_print
        
        call emit_print_
        call emit_newline
        call increase_indent
        call indent
        call emit_body_
        call emit_id
        
        movq (%rsp), %rdi        
        call emit_number
        
        call emit_newline
        call indent
        call emit_body_
        call emit_desc

        movq 8(%rsp), %rdi        
        call emit_number
        call emit_arrow

        pop %rdi # Expr id
        pop %rsi # expr descriptor
        call astprint_expr
        call emit_newline
        call decrease_indent
        leave
        ret



// in rdi: Token id
// in rsi: Token descriptor
astprint_expr:
        push %rbp
        movq %rsp, %rbp


        cmp $26, %rdi # Binary op
        je binary
        cmp $25, %rdi # Number
        je number
        cmp $24, %rdi # identifier
        je identifier
        cmp $36, %rdi # field
        je identifier
        cmp $41, %rdi # array_access
        je array_access
        leave 
        ret
    array_access:
        push %rsi
        call emit_array_access_
        pop %rdi
        push $696969 # index descriptor
        push $696969 # index id
        push $696969 # identifier id
        push $696969 # identifier descriptor
        call retrieve_array_access
        
        call emit_arrow
        call emit_identifier_

        # Check for field or identifier here. (%rsp)

        // movq 8(%rsp), %rdi
        // call emit_identifier

        // call emit_arrow

        // movq 16(%rsp), %rdi
        // call retrieve_number
        // movq %rax, %rdi
        // call emit_number


        leave
        ret
    binary:
        push %rsi
        call emit_binaryop
        call emit_newline
        call increase_indent

        pop %rdi
        push $696969
        push $696969
        push $696969
        push $696969
        push $696969
        callq retrieve_binary_op 

        call indent
        call emit_operator
        movq 16(%rsp), %rdi
        cmp $3,  %rdi # ==
        je binary_operator_eq
        cmp $27,  %rdi # !=
        je binary_operator_neq
        cmp $22, %rdi # &&
        je binary_operator_and
        cmp $23, %rdi # ||
        je binary_operator_or
        cmp $13, %rdi # +
        je binary_operator_plus
        cmp $14, %rdi # -
        je binary_operator_minus
        cmp $15, %rdi # *
        je binary_operator_times
        cmp $16, %rdi # /
        je binary_operator_div
        cmp $17, %rdi # <
        je binary_operator_le
        cmp $18, %rdi # >
        je binary_operator_ge
        binary_operator_eq:
            call emit_equals
            jmp binary_operator_done
        binary_operator_neq:
            call emit_notequals
            jmp binary_operator_done
        binary_operator_and:
            call emit_and
            jmp binary_operator_done
        binary_operator_or:
            call emit_or
            jmp binary_operator_done
        binary_operator_plus:
            call emit_plus
            jmp binary_operator_done
        binary_operator_minus:
            call emit_minus
            jmp binary_operator_done
        binary_operator_times:
            call emit_times
            jmp binary_operator_done
        binary_operator_div:
            call emit_div
            jmp binary_operator_done
        binary_operator_le:
            call emit_le
            jmp binary_operator_done
        binary_operator_ge:
            call emit_ge
            jmp binary_operator_done
        binary_operator_done:
        call emit_newline
        call indent
        call emit_lhs
        call emit_id

        pop %rdi # lhs id
        push %rdi
        call emit_number
        call emit_newline
        call indent
        call emit_lhs
        call emit_desc
        pop %rsi
        pop %rdi # lhs descriptor
        push %rsi
        push %rdi
        call emit_number
        call emit_arrow
        pop %rsi
        pop %rdi
        callq astprint_expr

        call emit_newline
        call indent
        call emit_rhs
        call emit_id

        pop %rdx  # operator id ignore


        pop %rdi # lhs id
        push %rdi
        call emit_number
        call emit_newline
        call indent
        call emit_rhs
        call emit_desc
        pop %rsi
        pop %rdi # rhs descriptor
        push %rsi
        push %rdi
        call emit_number
        call emit_arrow
        pop %rsi
        pop %rdi
        callq astprint_expr
        
        call decrease_indent
        leave
        ret

    identifier:
        push %rsi
        call emit_identifier_
        pop %rdi
        call emit_identifier
        leave
        ret

    field:
        leave
        ret

    number:
        # Retrieve the number
        push %rsi
        call emit_number_
        pop %rdi
        callq retrieve_number
        movq %rax, %rdi
        callq emit_number
        leave
        ret


        leave
        ret


.type increase_indent, @function
increase_indent:
        push %rbp
        movq %rsp, %rbp
        mov current_indent(%rip), %eax
        inc %eax
        mov %eax, (current_indent)(%rip)
        leave
        ret

.type decrease_indent, @function
decrease_indent:
        push %rbp
        movq %rsp, %rbp
        mov current_indent(%rip), %eax
        dec %eax
        mov %eax, (current_indent)(%rip)
        leave
        ret

.type indent, @function
indent:
        push %rbp
        movq %rsp, %rbp
        mov current_indent(%rip), %ecx
    indent_begin:
        cmp $0, %ecx
        je indent_end

        push %rcx
        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_tab, %rsi
        movq $1, %rdx
        syscall
        pop %rcx

        dec %ecx        
        jmp indent_begin
    indent_end:
        leave
        ret

.type emit_equals, @function
emit_equals:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_equals, %rsi
        movq $2, %rdx
        syscall

        leave
        ret
.type emit_notequals, @function
emit_notequals:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_noteq, %rsi
        movq $2, %rdx
        syscall

        leave
        ret
.type emit_and, @function
emit_and:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_and, %rsi
        movq $2, %rdx
        syscall

        leave
        ret
.type emit_or, @function
emit_or:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_or, %rsi
        movq $2, %rdx
        syscall

        leave
        ret
.type emit_plus, @function
emit_plus:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_plus, %rsi
        movq $1, %rdx
        syscall

        leave
        ret
.type emit_minus, @function
emit_minus:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_minus, %rsi
        movq $1, %rdx
        syscall

        leave
        ret
.type emit_times, @function
emit_times:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_times, %rsi
        movq $1, %rdx
        syscall

        leave
        ret
.type emit_div, @function
emit_div:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_div, %rsi
        movq $1, %rdx
        syscall

        leave
        ret
.type emit_le, @function
emit_le:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_less, %rsi
        movq $1, %rdx
        syscall

        leave
        ret
.type emit_ge, @function
emit_ge:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_greater, %rsi
        movq $1, %rdx
        syscall

        leave
        ret

.type emit_binaryop, @function
emit_binaryop:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_binaryop, %rsi
        movq $9, %rdx
        syscall

        leave
        ret

.type emit_number_, @function
emit_number_:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_number, %rsi
        movq $8, %rdx
        syscall

        leave
        ret

.type emit_identifier_, @function
emit_identifier_:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_identifier, %rsi
        movq $12, %rdx
        syscall

        leave
        ret

.type emit_operator, @function
emit_operator:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_operator, %rsi
        movq $10, %rdx
        syscall

        leave
        ret

.type emit_arrow, @function
emit_arrow:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_arrow, %rsi
        movq $4, %rdx
        syscall

        leave
        ret

.type emit_lhs, @function
emit_lhs:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_lhs, %rsi
        movq $4, %rdx
        syscall

        leave
        ret

.type emit_rhs, @function
emit_rhs:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_rhs, %rsi
        movq $4, %rdx
        syscall

        leave
        ret


.type emit_id, @function
emit_id:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_id, %rsi
        movq $4, %rdx
        syscall

        leave
        ret

.type emit_desc, @function
emit_desc:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_desc, %rsi
        movq $6, %rdx
        syscall

        leave
        ret


.type emit_assignment, @function
emit_assignment:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_assignment, %rsi
        movq $11, %rdx
        syscall

        leave
        ret



.type emit_function, @function
emit_function:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_function, %rsi
        movq $10, %rdx
        syscall

        leave
        ret

.type emit_print_, @function
emit_print_:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_print, %rsi
        movq $5, %rdx
        syscall

        leave
        ret
.type emit_if_, @function
emit_if_:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_if, %rsi
        movq $2, %rdx
        syscall

        leave
        ret
.type emit_while_, @function
emit_while_:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq token_while, %rsi
        movq $5, %rdx
        syscall

        leave
        ret
.type emit_array_access_, @function
emit_array_access_:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_array_access, %rsi
        movq $12, %rdx
        syscall

        leave
        ret
.type emit_guard, @function
emit_guard:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_guard, %rsi
        movq $6, %rdx
        syscall

        leave
        ret

.type emit_body_, @function
emit_body_:
        push %rbp
        movq %rsp, %rbp

        movq $1, %rax
        movq $1, %rdi
        leaq _astprint_body, %rsi
        movq $6, %rdx
        syscall

        leave
        ret


