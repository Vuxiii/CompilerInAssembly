.section .text
.global _start
_start:
        push %rbp
        mov %rsp, %rbp
        # Argc is in 8(%rbp)
        # If argc == 1
        #   * Read from std in
        # If argc == 2
        #   * read from filename 24(%rbp)
        #   * Check if it exists

        movq 8(%rbp), %rax
        cmp $1, %rax # Read from std in
        je read_from_stdin
        cmp $2, %rax # Read from given file
        je read_from_file
        jmp emit_not_implemented # Not supported yet
    read_from_file:
        movq 24(%rbp), %rdi
        call set_filename
        call read_file_contents
        jmp end_read_setup
    read_from_stdin:
        jmp emit_no_inputfile # Not supported yet
    end_read_setup:
        call parse
        movq %rax, %rdi
        movq %rbx, %rsi
        push %rdi
        push %rsi
        // call astprint
        pop %rsi
        pop %rdi
        push %rdi
        push %rsi
        call collect
        pop %rsi
        pop %rdi
        call emit
        jmp end_start
    end_start:
        leave
        movq $60, %rax
        movq $0, %rdi
        syscall
        