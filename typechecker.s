
.section .text
.global setup_types
.type setup_types, @function
setup_types:
        enter $16, $0
        # Iterate over each type

        movq $0, -8(%rbp)
        lea type_buffer(%rip), %rax
        movq %rax, -16(%rbp)
    setup_types_next_type:
        movq -16(%rbp), %rax
        
        movl 12(%rax), %ebx # type.
        cmp $0, %rbx
        je setup_types_continue

        movl 16(%rax), %edi
        push $696969 # field descriptor *
        push $696969 # field count
        push $696969 # struct name descriptor
        call retrieve_struct_decl
        addq $8, %rsp

        pop %r8  # Count
        pop %rdi # field descriptor *
        

        enter $24, $0
        movq %r8,   -8(%rbp) # Count
        movq %rdi, -16(%rbp) # field descriptor *
        movq $0,   -24(%rbp) # total size
        
        # Iterate over each field, and accumulate the total size
        check_next_field:
            decq -8(%rbp)

            movq -16(%rbp), %rax
            addq $8, -16(%rbp)
            movq  -8(%rbp), %rcx
            movl (%rax, %rcx, 4), %edi
            push $606060 # type descriptor
            push $696969 # name descriptor
            call retrieve_declaration
            
            addq $8, %rsp
            pop %rdi
            call retrieve_identifier
            movq %rax, %rdi
            call find_type_by_charptr
            movq %rax, %rdi
            push $696969 # type descriptor
            push $696969 # type id
            push $696969 # size int
            push $696969 # char *name
            call retrieve_type
            cmpq $0, 8(%rsp)
            je size_is_known

            movq 8(%rsp), %rbx # The size
            addq %rbx, -24(%rbp) # add size for THIS field.
        size_is_known:
            cmpq  $0, -8(%rbp)
            jg check_next_field
        movq -24(%rbp), %rbx
        leave
    asdfasdfasdf:
    movq -16(%rbp), %rax # the current type
    movl %ebx, 8(%rax) # Set the size of the type.

    setup_types_continue:
        addq $20, -16(%rbp) # Progress to next type.
        incq -8(%rbp)
        movq -8(%rbp), %rcx
        cmp (type_offset)(%rip), %rcx
        jg setup_types_next_type
        leave
        ret

// rdi: type name descriptor
.global lookup_type_size
.type lookup_type_size, @function
lookup_type_size:
        enter $0, $0
        call retrieve_identifier
        movq %rax, %rdi
        call find_type_by_charptr
        movq %rax, %rdi
        push $696969 # type_descriptor
        push $696969 # type id
        push $696969 # size int
        push $696969 # Char *name
        call retrieve_type

        movq 8(%rsp), %rax
        leave
        ret
