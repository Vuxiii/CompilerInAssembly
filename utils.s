.section .data

.extern identifier_tokens

identifier_count:   .int 0

.section .text

// in:  %rdi: identifier buffer
// in:  %rdx: count (NO \0 CHAR! Will be inserted by this call)
// out: %rax: identifier descriptor
.global insert_identifier
.type insert_identifier, @function
insert_identifier:
    lea identifier_tokens(%rip), %rax
    xor %rbx, %rbx
    mov identifier_count(%rip), %ebx
    addq %rbx, %rax # Correct offset into token buffer
    xorq %rdx, %rdx  # Clear inter reg for chars.
    xorq %rcx, %rcx  # Clear counter 

insert_chars:
    # Read the char one by one.
    movb (%rdi, %rcx, 1), %dl # Read source char
    movb %dl, (%rax, %rcx, 1) # Move stored char into target buffer
    inc %rcx # Next char
    cmp %rsi, %rcx
    jne insert_chars
    # Insert '\0'
    movb $0, (%rax, %rcx, 1)
    inc %rcx # We have added an extra char

    mov %rbx, %rax  # return
    addq %rcx, %rbx # Increase the offset into the buffer and store it.
    mov %ebx, (identifier_count)(%rip)
    ret

// in:  %rdi: identifier descriptor
// out: %rax: char * to buffer
.global retrieve_identifier
.type retrieve_identifier, @function
retrieve_identifier:
    lea identifier_tokens(%rip), %rax
    addq %rdi, %rax
    ret

// in: %rdi: String 1
// in: %rsi: String 2
// out: %rax: 1 = true, 0 = false
// NOTE: This function assumes that rsi contains a '\0' to terminate the string 2. 
// The only way to return true, is if rdi and rsi match until the \0 char is met in rsi.
.global cmp_string
.type cmp_string, @function
cmp_string:
    xor %rax, %rax
    xor %rbx, %rbx
cmp_string_:
    movb (%rdi), %al
    movb (%rsi), %bl
    xor %bl, %al

    // Check if they are equal.
    cmp $0, %al 
    jne cmp_string_false
    
    // Check if we have reached '\0'
    cmp $0, %bl
    je cmp_string_true
    inc %rdi
    inc %rsi
    jmp cmp_string_
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
.type fill_buffer, @function
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
.type copy_string, @function
copy_string:
    movb (%rsi), %al         # Move a byte from source to %al
    movb %al, (%rdi)         # Move the byte from %al to destination
    inc %rsi                 # Increment the source address
    inc %rdi                 # Increment the destination address
    cmpb $0, %al             # Compare the moved byte with 0 (end of string)
    jne copy_string           # Jump to movsb_loop if the byte is not zero
    ret

// in  rdi: buffer
// out rax: len in bytes
.global count_string_len
.type count_string_len, @function
count_string_len:
        push %rbp
        movq %rsp, %rbp
        xor %rax, %rax
    count_len:
        inc %rax
        movb (%rdi), %bl
        inc %rdi
        test %bl, %bl
        jnz count_len
        leave
        ret


# IN: %rcx: offset into buffer.
# IN: %rdx: Bytes to read
.global read_char
.type read_char, @function
read_char:
    movq $0, %rax
    movq $0, %rdi
    leaq input_buffer, %rsi
    addq %rcx, %rsi
    syscall
    ret

// in  rdi: char *character
// out: Conditional flag. je if equal jne if not equal
.global is_char
.type is_char, @function
is_char:
        movb (%rdi), %bl
        andb $223, %bl # 223 -> 1101 1111
        # Trick to remove the 6th bit
        # We now only have to compare twice
        # In the range [65; 90]
        cmpb $65, %bl
        setge %al
        cmpb $90, %bl
        setle %bl
        cmpb %bl, %al
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

.global emit_storage_error_unknown_id___
.type emit_storage_error_unknown_id___, @function
emit_storage_error_unknown_id___:
        // push %rbp
        // mov %rsp, %rbp 
        push %rdi

        call emit_newline
        call emit_newline

        movq $error_storage_error, %rdi
        call count_string_len

        movq %rax, %rdx
        movq $1, %rdi
        movq $error_storage_error, %rsi
        movq $1, %rax
        syscall

        
        
        movq (%rsp), %rdi
        call count_string_len
        movq %rax, %rdx
        pop %rsi

        movq $1, %rdi
        movq $1, %rax
        syscall
        call emit_newline
        call emit_newline

        movq $60, %rax
        movq $-1, %rdi
        syscall
