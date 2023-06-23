.data

.extern number_tokens
.extern identifier_tokens

number_count:       .int 0
identifier_count:   .int 0

.section .text

// in:  %rdi: identifier buffer // 4 bytes in total
// out: %rax: identifier descriptor
.global insert_identifier
insert_identifier:
    lea identifier_tokens, %rax
    mov identifier_count, %rsi

    mov (%rdi), %r10
    mov 1(%rdi), %r11
    mov 2(%rdi), %r12
    mov 3(%rdi), %r13

    mov %r10, (%rax)
    mov %r11, 1(%rax)
    mov %r12, 2(%rax)
    mov %r13, 3(%rax)

    mov %rsi, %rax # return
    inc %rsi
    mov %rsi, identifier_count
    ret

// in:  %rdi: identifier descriptor
// out: %rax: char * to buffer
.global retrieve_identifier
retrieve_identifier:
    lea identifier_tokens(%rip), %rax
    mov identifier_tokens(%rax, %rdi, 4), %rax
    ret


// in:  %rdi: number
// out: %rax: number descriptor
.global insert_number
insert_number:
    lea number_tokens, %rax
    mov number_count, %rsi
    mov %rdi, (%rax, %rsi, 4)
    mov %rsi, %rax
    inc %rsi
    mov %rsi, number_count
    ret

// in:  %rdi: number descriptor
// out: %rax: the number associated with the descriptor
.global retrieve_number
retrieve_number:
    lea number_tokens, %rax
    mov (%rax, %rdi, 4), %rax
    ret

// in: %rdi: String 1
// in: %rsi: String 2
// out: %rax: 1 = true, 0 = false
.global cmp_string
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



// in: %rdi: Buffer to fill
// in: %al: Byte to fill with
// in: %rcx: count
.global fill_buffer
fill_buffer:
    movb %al, (%rdi)
    inc %rdi
    dec %rcx
    cmpq $0, %rcx
    jne fill_buffer
    ret

// in %rdi: target buffer
// in: %rsi: source buffer '\0' terminated
.global copy_string
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
.global read_char
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
