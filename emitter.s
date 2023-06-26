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

.extern assignment_buffer:      .space 256
.extern binary_op_buffer:       .space 256

.extern _emit_asm_prologue
.extern _emit_function_prologue
.extern _emit_function_epilogue
.extern _emit_asm_epilogue
.extern _emit_push
.extern _emit_pop
.extern _emit_add
.extern _emit_sub
.extern _emit_lea
.extern _emit_call
.extern _emit_ret
.extern _emit_jmp
.extern _emit_jne
.extern _emit_je
.extern _emit_jle
.extern _emit_jge
.extern _emit_rax
.extern _emit_rbx
.extern _emit_rcx
.extern _emit_rdx
.extern _emit_rdi
.extern _emit_rsi
.extern _emit_comma
.extern _emit_colon
.extern _emit_dollar
.extern _emit_newline_tab

.section .text
.global emit
// in rdi: Token id
// in rsi: Token descriptor
.type emit, @function
emit:
        push %rbp
        mov %rsp, %rbp 
        callq emit_asm_prologue
        callq emit_function_prologue

        callq emit_add
        callq emit_rax
        callq emit_comma
        callq emit_rbx
        callq emit_newline_tab


        call emit_push
        call emit_rax
        call emit_newline_tab
        call emit_pop
        call emit_rdi
        call emit_newline_tab

        callq emit_asm_epilogue


        leave
        ret

.type emit_asm_prologue, @function
emit_asm_prologue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_asm_prologue, %rsi
        movq $31, %rdx
        syscall
        leave
        ret
.type emit_function_prologue, @function
emit_function_prologue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_function_prologue, %rsi
        movq $28, %rdx
        syscall
        leave
        ret
.type emit_function_epilogue, @function
emit_function_epilogue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_function_epilogue, %rsi
        movq $12, %rdx
        syscall
        leave
        ret
.type emit_asm_epilogue, @function
emit_asm_epilogue:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_asm_epilogue, %rsi
        movq $48, %rdx
        syscall
        leave
        ret
.type emit_push, @function
emit_push:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_push, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_pop, @function
emit_pop:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_pop, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_add, @function
emit_add:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_add, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_sub, @function
emit_sub:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_sub, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_lea, @function
emit_lea:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_lea, %rsi
        movq $7, %rdx
        syscall
        leave
        ret
.type emit_call, @function
emit_call:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_call, %rsi
        movq $8, %rdx
        syscall
        leave
        ret
.type emit_ret, @function
emit_ret:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_ret, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_jmp, @function
emit_jmp:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jmp, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_jne, @function
emit_jne:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jne, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_je, @function
emit_je:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_je, %rsi
        movq $5, %rdx
        syscall
        leave
        ret
.type emit_jle, @function
emit_jle:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jle, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_jge, @function
emit_jge:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_jge, %rsi
        movq $6, %rdx
        syscall
        leave
        ret
.type emit_rax, @function
emit_rax:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rax, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rbx, @function
emit_rbx:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rbx, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rcx, @function
emit_rcx:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rcx, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rdx, @function
emit_rdx:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rdx, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rdi, @function
emit_rdi:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rdi, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_rsi, @function
emit_rsi:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_rsi, %rsi
        movq $4, %rdx
        syscall
        leave
        ret
.type emit_comma, @function
emit_comma:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_comma, %rsi
        movq $2, %rdx
        syscall
        leave
        ret
.type emit_colon, @function
emit_colon:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_colon, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_dollar, @function
emit_dollar:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_dollar, %rsi
        movq $1, %rdx
        syscall
        leave
        ret
.type emit_newline_tab, @function
emit_newline_tab:
        push %rbp
        mov %rsp, %rbp 
        movq $1, %rax
        movq $1, %rdi
        leaq _emit_newline_tab, %rsi
        movq $2, %rdx
        syscall
        leave
        ret
