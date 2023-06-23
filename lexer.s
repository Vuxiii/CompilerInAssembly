.data

.extern eop        # -1
.extern none       # 0
.extern def        # 1
.extern if         # 2
.extern equals     # 3
.extern assignment # 4
.extern lparen     # 5
.extern rparen     # 6
.extern vara       # 7
.extern print      # 8

.section .text
.global get_token
get_token:
    # rdi -> Current offst into the input stream                        | Start
    movq $0, %rcx   # What is out current offset for finding the space  | End = Start + rcx
token_remove_white_space:
    movb (%rdi, %rcx), %al
    cmp $32, %al
    jne token_loop
    inc %rdi
    jmp token_remove_white_space
token_loop:
    // Read until we find a space '32'
    movb (%rdi, %rcx), %al
    cmp $32, %al
    // We found space
    je identify_token
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
    movq $vara, %rsi
    callq cmp_string
    cmp $1, %ax
    je return_vara_token

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
return_vara_token:
    movq $7, %rax
    ret
return_print_token:
    movq $8, %rax
    ret
return_eop_token:
    movq $-1, %rax
    ret

// in: %rdi: String 1
// in: %rsi: String 2
// out: %rax: 1 = true, 0 = false
cmp_string:
    movb (%rdi), %al
    movb (%rsi), %bl
    xor %al, %bl
    // Check if they are equal.
    cmp $0, %bl 
    jne cmp_string_false

    // Check if we have reached '\0'
    cmp $0, %al 
    je cmp_string_true

    inc %rdi
    inc %rsi
    // Go to next byte
    jmp cmp_string 

cmp_string_false:
    movq $0, %rax
    ret
cmp_string_true:
    movq $1, %rax
    ret
