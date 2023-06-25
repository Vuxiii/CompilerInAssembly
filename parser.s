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

current_token_id:       .int 0
token_data:             .int 0

expressions_buffer:     .space 256
binary_op_buffer:       .space 256
binary_op_offset:       .int 0

.section .text
.global parse
.type parse, @function
parse:
        push %rbp
        mov %rsp, %rbp 
        
        // We start by parsing a expression
        callq parse_expression

        leave
        ret


.type parse_expression, @function
// out rax: token_id
// out rbx: descriptor
parse_expression:
        push %rbp
        mov %rsp, %rbp
        callq next_token
    
        // At this stage we have parsed the first expression

        call current_token
        push %rax # Store the token_id
        call current_token_data
        push %rax # Store the descriptor

        # We now have the following:
        # │token_descriptor│
        # │    token_id    │
        # │      ...       │
        # └────────────────┘
        // Check the operator

        call next_token
        call current_token
        cmp $13, %eax # +
        je setup_plus_operator
        cmp $14, %eax # -
        je setup_minus_operator
        cmp $15, %eax # *
        je setup_times_operator
        cmp $16, %eax # /
        je setup_div_operator
        cmp $17, %eax # <
        cmp $18, %eax # >
        cmp $22, %eax # &&
        cmp $23, %eax # ||

        # It was not an operator.
        # Return the expression
        pop %rbx
        pop %rax
        leave
        ret

    done_with_operator:
        # We now have the following:
        # │  operator_id   │
        # │token_descriptor│ LHS
        # │    token_id    │ LHS
        # │      ...       │
        # └────────────────┘

        # Need some logic for handling precedence

        callq parse_expression
        # rax should contain the token_id
        # rbx should contain the descriptor
        // call current_token
        push %rax # Store the token_id
        // call current_token_data
        push %rbx # Store the descriptor
        # We now have all we need.
        # │token_descriptor│ RHS
        # │    token_id    │ RHS
        # │  operator_id   │
        # │token_descriptor│ LHS
        # │    token_id    │ LHS
        # │      ...       │
        # └────────────────┘

        pop %rsi
        pop %rdi
        pop %rdx
        pop %r8
        pop %rcx
        call construct_binary_op_node
        movq %rax, %rdi 
        call push_token_descriptor
        movq $26, %rdi
        call push_token_id
        mov %eax, %edi
        leave
        ret

        

        setup_plus_operator:
            push $13
            jmp done_with_operator
        setup_minus_operator:
            push $14
            jmp done_with_operator
        setup_times_operator:
            push $15
            jmp done_with_operator
        setup_div_operator:
            push $16
            jmp done_with_operator

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
// p (int[5])*0x202f33
        lea binary_op_buffer(%rip), %rax
        
        mov %ecx, (%rax, %rbx)
        mov %r8,  4(%rax, %rbx)
        mov %edx, 8(%rax, %rbx)
        mov %edi, 12(%rax, %rbx)
        mov %esi, 16(%rax, %rbx)
        
        inc %ebx
        mov %ebx, (binary_op_offset)(%rip)

        pop %rax # Restore descriptor
        leave
        ret


.type push_token_id, @function
push_token_id:
        push %rbp
        mov %rsp, %rbp
        mov %edi, current_token_id(%rip)
        leave
        ret

.type push_token_descriptor, @function
push_token_descriptor:
        push %rbp
        mov %rsp, %rbp
        mov %edi, token_data(%rip)
        leave
        ret

.type current_token, @function
current_token:
        push %rbp
        mov %rsp, %rbp
        mov current_token_id(%rip), %eax
        leave
        ret

.type current_token_data, @function
current_token_data:
        push %rbp
        mov %rsp, %rbp
        mov token_data(%rip), %eax
        leave
        ret

.type next_token, @function
next_token:
        push %rbp
        mov %rsp, %rbp
        callq get_token
        mov %eax, current_token_id(%rip)
        cmp $25, %rax
        je set_descriptor
        cmp $24, %rax
        je set_descriptor
        leave
        ret
    set_descriptor:
        mov %ebx, token_data(%rip)
        leave
        ret
