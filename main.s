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
.global _start
_start:
    movq $in, %rdi
    push %rdi
_llopers:
    pop %rdi

    callq get_token
    // addq $1, %rcx
    // addq %rcx, %rdi
    inc %rdi
    push %rdi

    cmp $1, %rax
    je print_def
    cmp $2, %rax
    je print_if 
    cmp $3, %rax
    je print_equals 
    cmp $4, %rax 
    je print_assignment
    cmp $5, %rax 
    je print_lparen
    cmp $6, %rax 
    je print_rparen
    cmp $7, %rax 
    je print_vara
    cmp $8, %rax 
    je print_print
    cmp $-1, %rax 
    je print_eop
    
    
    movq $1, %rax
    movq $1, %rdi
    leaq none, %rsi
    movq $5, %rdx
    syscall
    jmp end_start
print_def:
    movq $1, %rax
    movq $1, %rdi
    leaq def, %rsi
    movq $4, %rdx
    syscall
    jmp _llopers
print_if:
    movq $1, %rax
    movq $1, %rdi
    leaq if, %rsi
    movq $3, %rdx
    syscall
    jmp _llopers
print_equals:
    movq $1, %rax
    movq $1, %rdi
    leaq equals, %rsi
    movq $3, %rdx
    syscall
    jmp _llopers
print_assignment:
    movq $1, %rax
    movq $1, %rdi
    leaq assignment, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_lparen:
    movq $1, %rax
    movq $1, %rdi
    leaq lparen, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_rparen:
    movq $1, %rax
    movq $1, %rdi
    leaq rparen, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_vara:
    movq $1, %rax
    movq $1, %rdi
    leaq vara, %rsi
    movq $2, %rdx
    syscall
    jmp _llopers
print_print:
    movq $1, %rax
    movq $1, %rdi
    leaq print, %rsi
    movq $6, %rdx
    syscall
    jmp _llopers
print_eop:
    movq $1, %rax
    movq $1, %rdi
    leaq eop, %rsi
    movq $4, %rdx
    syscall
    jmp end_start
    // callq main_loop

    // movq $def, %rdi
    // callq cmp_string

//     cmp $0, %ax
//     je print_false
//     movq $1, %rax
//     movq $1, %rdi
//     leaq true, %rsi
//     movq $5, %rdx
//     syscall
//     jmp end_start

// print_false:
//     movq $1, %rax
//     movq $1, %rdi
//     leaq false, %rsi
//     movq $6, %rdx
//     syscall

end_start:
    movq $60, %rax
    movq $0, %rdi
    syscall

// in  %rdi: The buffer to find the next token
// out %rax: The id of the token. See header
// out %rdi: The buffer at the current location


// in: %rdi: Buffer to fill
// in: %al: Byte to fill with
// in: %rcx: count
fill_buffer:
    movb %al, (%rdi)
    inc %rdi
    dec %rcx
    cmpq $0, %rcx
    jne fill_buffer
    ret

// in %rdi: target buffer
// in: %rsi: source buffer '\0' terminated
copy_string:
    movb (%rsi), %al         # Move a byte from source to %al
    movb %al, (%rdi)         # Move the byte from %al to destination
    inc %rsi                 # Increment the source address
    inc %rdi                 # Increment the destination address
    cmpb $0, %al             # Compare the moved byte with 0 (end of string)
    jne copy_string           # Jump to movsb_loop if the byte is not zero
    ret

# IN: %rcx: offset into buffer.
# IN: %rdx: Bytes to read
read_char:
    movq $0, %rax
    movq $0, %rdi
    leaq input_buffer, %rsi
    addq %rcx, %rsi
    syscall
    ret


main_loop:
    movq $0, %r8

read_loop:
// Read from std in
   
    movq %r8, %rcx
    movq $10, %rdx
    callq read_char
    addq %rax, %r8
    // Check if we are done reading from std in
    cmpq $0, %rax 
    je loop_read

    // Check if we have reached the capacity of our buffer
    // If so, flush
    cmpq $20, %r8
    jge flush_buffer

    // Repeat reading
    jmp read_loop

flush_buffer:
    movq $1, %rax
    movq $1, %rdi
    leaq input_buffer, %rsi
    movq %r8, %rdx
    movq $0, %r8
    syscall
    jmp read_loop

loop_read:
    movq $1, %rax
    movq $1, %rdi
    leaq input_buffer, %rsi
    movq %r8, %rdx
    syscall
    ret
