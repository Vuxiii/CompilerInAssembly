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

.extern buffer_address

current_token_id:       .int 0
token_data:             .int 0


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
parse_expression:
    push %rbp
    mov %rsp, %rbp

    callq get_token

    // expression ::= 'number'
    // Check if rax is 25 (number)
    cmp $25, %eax
    jne expression_binaryop_expression
    // it is a number
    // Fetch the number
    mov token_data(%rip), %eax
    

expression_binaryop_expression:
    // expression ::= expression binary_op expression
    callq parse_expression
    // We have the node in rax
    callq get_token



    callq parse_expression
    leave
    ret

// .type parse_binary_op, @function
// parse_binary_op:
//     push %rbp
//     mov %rsp, %rbp 

//     callq get_token
//     mov %rax, current_token_id(%rip)

//     leave
//     ret