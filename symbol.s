.global symbol_buffer
        symbol_buffer:          .space 256
.global symbol_offset
        symbol_offset:          .int 0

.section .text

.type collect, @function
.global collect
collect:
    push %rbp
    mov %rsp, %rbp

    leave
    ret
