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


.section .text
.global get_token
get_token:
    movq buffer_address(%rip), %rdi # Load the correct palce in the buffer
    # rdi -> Current offst into the input stream                        | Start
    xor %rcx, %rcx  # What is out current offset for finding the space  | End = Start + rcx
    xor %rax, %rax  # Clear out the rax register
token_remove_white_space:
    movb (%rdi, %rcx), %al
    cmp $32, %al
    jne token_loop
    inc %rdi
    jmp token_remove_white_space
token_loop:
    // Check for keyword tokens
    push %rdi
    callq identify_token
    pop %rdi
    cmp $-1, %rax # We are done EOP
    je get_token_return_eop
    cmp $0, %rax
    jne get_token_return_keyword

    // It was not a keyword or a special symbol.
    // Thus it is a number or an identifier.

    movb (%rdi, %rcx), %al

    // Check for number
    cmp (number_0), %al
    jl not_a_number
    cmp (number_9), %al
    jg not_a_number
    // It is a number.
    mov %rcx, %r9 # Store the start number in the buffer
    xor %rbx, %rbx # zero the result dst
    mov $10, %r11
    number_loop_begin:
        inc %rcx
        movb (%rdi, %rcx), %al
        cmp (number_0), %al
        jl submit_number
        cmp (number_9), %al
        jg submit_number
        jmp number_loop_begin

        submit_number: # Store the number in %ebx
            // We have the range from [(%rdi, %rdx), (%rdi, &rcx)[ that defines our number
            // We haven't reached the bottom of the stack. Therefore -> Continue to compute the number
            
            # Fetch the stored char
            movb (%rdi, %r9), %al 

            # sub '0' = 48 to it
            subb $48, %al
            
            # Multiply it by 10^(rcx - r9)
            mov %rcx, %r8
            sub %r9, %r8 # r8 = r8 - r9
            submit_number_mul10_loop:
                cmp $1, %r8
                je submit_number_mul10_loop_end
                
                imul %r11 # rdx:rax = rax * r11 (10)
                dec %r8
                jmp submit_number_mul10_loop
            submit_number_mul10_loop_end:
            add %eax, %ebx
            inc %r9
            cmp %r9, %rcx
            jne submit_number
    # Register the computed number and store the descriptor somewhere
    inc %rcx
    addq %rcx, %rdi
    movq %rdi, (buffer_address)(%rip)
    movq %rbx, %rdi
    callq insert_number
    jmp get_token_return_number

not_a_number:

    // Then it must be an identifier.
    // We already know the first char is an alphanumerical value.
    mov %rcx, %r9 # Store the start number in the buffer
    identifier_loop_begin:
        inc %rcx
        movb (%rdi, %rcx), %al
        cmp (number_0), %al
        jl submit_identifier # We are done reading the identifier. Nothing below 48
        cmp $122, %al
        jg submit_identifier # We are dont reading the identifier. Nothing above 122
        # Check for chars in range from 58 - 64 -> Special symbols
        cmp $64, %al
        jg identifier_char_above_64
        cmp $58, %al
        jl identifier_char_is_number

        # If we reach this point. We have read a special symbol. Thus submit.
        jmp submit_identifier

        identifier_char_is_number:
            # At this point, don't do anything. We want to accept identifiers that contain numbers :)
            jmp identifier_loop_begin

        identifier_char_above_64:
            # We know the range is below 122
            # Range from [65, 90] -> BIG LETTER
            # Range from [97, 122] -> small letter
            # Value: 95 -> under_score '_'
            cmp $95, %al
            je identifier_loop_begin  # Accept
            cmp $90, %al
            jle identifier_loop_begin # Accept
            cmp $97, %al
            jge identifier_loop_begin # Accept
            
            # At this point we saw a special symbol. Submit identifier
            jmp submit_identifier

    submit_identifier:
        movq %rcx, %rsi # Count
        subq %r9, %rsi
        pushq %rcx
        callq insert_identifier
        popq %rcx
        # Now RAX contains the descriptor for the identifier.

        inc %rcx
        addq %rcx, %rdi
        movq %rdi, (buffer_address)(%rip)
        jmp get_token_return_identifier

identify_token:
    // Check one by one for the correct token

        movq %rdi, %rdx
        movq $token_def, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_def_token
        
        movq %rdx, %rdi
        movq $token_if, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_if_token

        movq %rdx, %rdi
        movq $token_equals, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_equals_token

        movq %rdx, %rdi
        movq $token_assignment, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_assignment_token

        movq %rdx, %rdi
        movq $token_lparen, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_lparen_token

        movq %rdx, %rdi
        movq $token_rparen, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_rparen_token

        movq %rdx, %rdi
        movq $token_print, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_print_token

        movq %rdx, %rdi
        movq $token_eop, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_eop_token

        movq %rdx, %rdi
        movq $token_while, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_while_token

        movq %rdx, %rdi
        movq $token_plus, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_plus_token

        movq %rdx, %rdi
        movq $token_minus, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_minus_token

        movq %rdx, %rdi
        movq $token_times, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_times_token

        movq %rdx, %rdi
        movq $token_div, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_div_token

        movq %rdx, %rdi
        movq $token_less, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_less_token

        movq %rdx, %rdi
        movq $token_greater, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_greater_token

        movq %rdx, %rdi
        movq $token_true, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_true_token

        movq %rdx, %rdi
        movq $token_false, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_false_token

        movq %rdx, %rdi
        movq $token_let, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_let_token

        movq %rdx, %rdi
        movq $token_and, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_and_token

        movq %rdx, %rdi
        movq $token_or, %rsi
        callq cmp_string
        cmp $1, %ax
        je return_or_token

        movq $0, %rax
        ret

        return_def_token:
            addq $4, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $1, %rax
            ret
        return_if_token:
            addq $3, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $2, %rax
            ret
        return_equals_token:
            addq $3, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $3, %rax
            ret
        return_assignment_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $4, %rax
            ret
        return_lparen_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $5, %rax
            ret
        return_rparen_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $6, %rax
            ret
        return_lcurly_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $7, %rax
            ret
        return_rcurly_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $8, %rax
            ret
        return_lbracket_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $9, %rax
            ret
        return_rbracket_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $10, %rax
            ret
        return_print_token:
            addq $6, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $11, %rax
            ret
        return_while_token:
            addq $6, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $12, %rax
            ret
        return_plus_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $13, %rax
            ret
        return_minus_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $14, %rax
            ret
        return_times_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $15, %rax
            ret
        return_div_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $16, %rax
            ret
        return_less_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $17, %rax
            ret
        return_greater_token:
            addq $2, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $18, %rax
            ret
        return_true_token:
            addq $5, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $19, %rax
            ret
        return_false_token:
            addq $6, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $20, %rax
            ret
        return_let_token:
            addq $4, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $21, %rax
            ret
        return_and_token:
            addq $3, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $22, %rax
            ret
        return_or_token:
            addq $4, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $23, %rax
            ret
        return_eop_token:
            addq $4, %rdx
            movq %rdx, (buffer_address)(%rip)

            movq $-1, %rax
            ret


get_token_return_eop:
    // rax: eop token id
    ret
get_token_return_keyword:
    // rax: keyword token id
    ret
get_token_return_number:
    // rax: number token id
    // rbx: number descriptor
    movq %rax, %rbx
    movq $25, %rax
    ret
get_token_return_identifier:
    // rax: identifier token id
    // rbx: identifier descriptor
    movq %rax, %rbx
    movq $24, %rax
    ret
