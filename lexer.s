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

.section .text
.global get_token
get_token:
    # rdi -> Current offst into the input stream                        | Start
    movq $0, %rcx   # What is out current offset for finding the space  | End = Start + rcx
    xor %rax, %rax # Clear out the rax register
token_remove_white_space:
    movb (%rdi, %rcx), %al
    cmp $32, %al
    jne token_loop
    inc %rdi
    jmp token_remove_white_space
token_loop:
    // Read until we find a space '32'
    movb (%rdi, %rcx), %al

    // Check for special one char token
    // lparen
    cmp (lparen), %al
    je return_lparen_token
    // rparen
    cmp (rparen), %al
    je return_rparen_token
    // lcurly
    cmp (lcurly), %al
    je return_lcurly_token
    // rcurly
    cmp (rcurly), %al
    je return_rcurly_token
    // lbracket
    cmp (lbracket), %al
    je return_lbracket_token
    // rbracket
    cmp (rbracket), %al
    je return_rbracket_token

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
    push %rdi
    movq %rbx, %rdi
    callq insert_number
    pop %rdi

    // rax contains the descriptor for the number.
    inc %rcx
    jmp token_loop
not_a_number:


    inc %rcx
    jmp token_loop
identify_token:
// rdi is the start of the buffer
// rcx is the length of the word to identify
// Replace the rdi+rcx char with a '\0'
    movb $0, (%rdi, %rcx)
// Check one by one for the correct token

    movq %rdi, %rdx
    movq $def, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_def_token
    
    movq %rdx, %rdi
    movq $if, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_if_token

    movq %rdx, %rdi
    movq $equals, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_equals_token

    movq %rdx, %rdi
    movq $assignment, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_assignment_token

    movq %rdx, %rdi
    movq $lparen, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_lparen_token

    movq %rdx, %rdi
    movq $rparen, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_rparen_token

    movq %rdx, %rdi
    movq $print, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_print_token

    movq %rdx, %rdi
    movq $eop, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_eop_token

    movq $0, %rax
    ret

return_def_token:
    movq $1, %rax
    ret
return_if_token:
    movq $2, %rax
    ret
return_equals_token:
    movq $3, %rax
    ret
return_assignment_token:
    movq $4, %rax
    ret
return_lparen_token:
    movq $5, %rax
    ret
return_rparen_token:
    movq $6, %rax
    ret
return_lcurly_token:
    movq $7, %rax
    ret
return_rcurly_token:
    movq $8, %rax
    ret
return_lbracket_token:
    movq $9, %rax
    ret
return_rbracket_token:
    movq $10, %rax
    ret
return_print_token:
    movq $11, %rax
    ret
return_eop_token:
    movq $-1, %rax
    ret
