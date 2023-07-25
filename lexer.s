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

.extern filename
.extern filesize
.extern buffer_address

.section .text


// in rdi: char *filename
.global set_filename
.type set_filename, @function
set_filename:
        push %rbp
        movq %rsp, %rbp

        movq %rdi, filename(%rip)

        leave
        ret

// in rdi: file name to read
// This function fills the buffer address
.global read_file_contents
.type read_file_contents, @function
read_file_contents:
        push %rbp
        movq %rsp, %rbp
        # Open the file
        movq $2, %rax
        movq filename, %rdi
        movq $0, %rsi
        xorq %rdx, %rdx
        syscall
        cmp $0, %rax
        jle emit_file_not_found
        movq %rax, %r8       # Move the fd
        
        movq $9, %rax        # mmap
        movq $0, %rdi        # addr   -> null kernel chooses
        movq $filesize, %rsi # len    -> length to map in bytes
        movq $1, %rdx        # prot
        movq $2, %r10        # flags
        xorq %r9, %r9        # offset -> 0
        syscall

        movq %rax, (buffer_address)(%rip)
        leave
        ret

// out rax: identifier token id
// out rbx: identifier descriptor
.global get_token
.type get_token, @function
get_token:
    push %rbp
    mov %rsp, %rbp 
    movq buffer_address(%rip), %rdi # Load the correct place in the buffer
    # rdi -> Current offst into the input stream                        | Start
    xor %rcx, %rcx  # What is out current offset for finding the space  | End = Start + rcx
    xor %rax, %rax  # Clear out the rax register
token_remove_white_space:
    movb (%rdi, %rcx), %al
    cmp $32, %al
    jg token_loop
    inc %rdi
    jmp token_remove_white_space
token_loop:
    // Check for keyword tokens
    push %rdi
    push %rcx
    callq identify_token
    pop %rcx
    pop %rdi
    cmp $-1, %rax # We are done EOP
    je get_token_return_eop
    cmp $0, %rax
    jne get_token_return_keyword

not_keyword:
    // It was not a keyword or a special symbol.
    // Thus it is a number or an identifier.

    movb (%rdi, %rcx), %al

    // Check for number
    cmp $48, %al # 0
    jl not_a_number
    cmp $57, %al # 9
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
            # Clear rax, Some numbers are big
            xor %rax, %rax
            
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

        addq %rcx, %rdi
        movq %rdi, (buffer_address)(%rip)
        jmp get_token_return_identifier

identify_token:
    // Check one by one for the correct token

        movq %rdi, %rdx

        cld
        movq $token_loopii, %rsi
        cmpsl
        je return_loop_token

        movq %rdx, %rdi
        movq $token_def, %rsi
        movq $3, %rcx
        repe cmpsb
        je return_def_token
        
        movq %rdx, %rdi
        movq $token_if, %rsi
        cmpsw
        je return_if_token

        movq %rdx, %rdi
        movq $token_equals, %rsi
        cmpsw
        je return_equals_token

        movq %rdx, %rdi
        movq $token_noteq, %rsi
        cmpsw
        je return_notequals_token

        movq %rdx, %rdi
        movq $token_assignment, %rsi
        cmpsb
        je return_assignment_token

        movq %rdx, %rdi
        movq $token_lparen, %rsi
        cmpsb
        je return_lparen_token

        movq %rdx, %rdi
        movq $token_rparen, %rsi
        cmpsb
        je return_rparen_token

        movq %rdx, %rdi
        movq $token_lbracket, %rsi
        cmpsb
        je return_lbracket_token

        movq %rdx, %rdi
        movq $token_rbracket, %rsi
        cmpsb
        je return_rbracket_token

        movq %rdx, %rdi
        movq $token_lcurly, %rsi
        cmpsb
        je return_lcurly_token

        movq %rdx, %rdi
        movq $token_rcurly, %rsi
        cmpsb
        je return_rcurly_token

        movq %rdx, %rdi
        movq $token_comma, %rsi
        cmpsb
        je return_comma_token

        movq %rdx, %rdi
        movq $token_print, %rsi
        movq $5, %rcx
        repe cmpsb
        je return_print_token

        movq %rdx, %rdi
        movq $token_eop, %rsi
        movq $3, %rcx
        repe cmpsb
        je return_eop_token

        movq %rdx, %rdi
        movq $token_while, %rsi
        movq $5, %rcx
        repe cmpsb
        je return_while_token

        movq %rdx, %rdi
        movq $token_plus, %rsi
        cmpsb
        je return_plus_token

        movq %rdx, %rdi
        movq $token_minus, %rsi
        cmpsb
        je return_minus_token

        movq %rdx, %rdi
        movq $token_times, %rsi
        cmpsb
        je return_times_token

        movq %rdx, %rdi
        movq $token_div, %rsi
        cmpsb
        je return_div_token

        movq %rdx, %rdi
        movq $token_less, %rsi
        cmpsb
        je return_less_token

        movq %rdx, %rdi
        movq $token_greater, %rsi
        cmpsb
        je return_greater_token

        movq %rdx, %rdi
        movq $token_true, %rsi
        cmpsl
        je return_true_token

        movq %rdx, %rdi
        movq $token_false, %rsi
        movq $5, %rcx
        repe cmpsb
        je return_false_token

        movq %rdx, %rdi
        movq $token_struct, %rsi
        movq $6, %rcx
        repe cmpsb
        je return_struct_token

        movq %rdx, %rdi
        movq $token_and, %rsi
        cmpsw
        je return_and_token

        movq %rdx, %rdi
        movq $token_or, %rsi
        cmpsw
        je return_or_token

        movq %rdx, %rdi
        movq $token_dot, %rsi
        cmpsb
        je return_dot_token

        movq %rdx, %rdi
        movq $token_ampersand, %rsi
        cmpsb
        je return_ampersand_token

        movq %rdx, %rdi
        movq $token_deref, %rsi
        cmpsb
        je return_deref_token

        

        movq $0, %rbx
        movq $0, %rax
        ret

        return_def_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $1, %rax
            ret
        return_if_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $2, %rax
            ret
        return_equals_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $3, %rax
            ret
        return_notequals_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $27, %rax
            ret
        return_assignment_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $4, %rax
            ret
        return_lparen_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $5, %rax
            ret
        return_rparen_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $6, %rax
            ret
        return_lcurly_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $7, %rax
            ret
        return_rcurly_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $8, %rax
            ret
        return_comma_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $35, %rax
            ret
        return_lbracket_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $9, %rax
            ret
        return_rbracket_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $10, %rax
            ret
        return_print_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $11, %rax
            ret
        return_while_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $12, %rax
            ret
        return_plus_token:
            movq %rdi, (buffer_address)(%rip)
            
            movq $5, %rbx
            movq $13, %rax
            ret
        return_minus_token:
            movq %rdi, (buffer_address)(%rip)
            
            movq $5, %rbx
            movq $14, %rax
            ret
        return_times_token:
            movq %rdi, (buffer_address)(%rip)

            movq $10, %rbx
            movq $15, %rax
            ret
        return_div_token:
            movq %rdi, (buffer_address)(%rip)

            movq $10, %rbx
            movq $16, %rax
            ret
        return_less_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $17, %rax
            ret
        return_greater_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $18, %rax
            ret
        return_true_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $19, %rax
            ret
        return_false_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $20, %rax
            ret
        return_struct_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $21, %rax
            ret
        return_and_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $22, %rax
            ret
        return_or_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $23, %rax
            ret
        return_dot_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $37, %rax
            ret
        return_ampersand_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $42, %rax
            ret
        return_deref_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $45, %rax
            ret
        return_loop_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movq $49, %rax
            ret
        return_eop_token:
            movq %rdi, (buffer_address)(%rip)

            movq $0, %rbx
            movl $-1, %eax
            ret


get_token_return_eop:
        // rax: eop token id
        movq $0, %rbx
        leave
        ret
get_token_return_keyword:
        // rax: keyword token id
        leave
        ret
get_token_return_number:
        // rax: number token id
        // rbx: number descriptor
        movq %rax, %rbx
        movq $25, %rax
        leave
        ret
get_token_return_identifier:
        // rax: identifier token id
        // rbx: identifier descriptor
        movq %rax, %rbx
        movq $24, %rax
        leave
        ret
