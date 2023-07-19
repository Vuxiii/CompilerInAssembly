
.section .text
.type emit_missing_main_function, @function
.global emit_missing_main_function
emit_missing_main_function:
        
    movq $error_missing_main_function, %rdi
    call count_string_len
    movq %rax, %rdx
    movq $error_missing_main_function, %rsi
    movq $1, %rax
    movq $1, %rdi
    syscall

    movq $60, %rax
    movq $1, %rdi
    syscall

.type emit_parse_error_missing_rbracket, @function
.global emit_parse_error_missing_rbracket
emit_parse_error_missing_rbracket:
        
    movq $error_parse_missing_rbracket, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_missing_lbracket, @function
.global emit_parse_error_missing_lbracket
emit_parse_error_missing_lbracket:
        
    movq $error_parse_missing_lbracket, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_missing_rparen, @function
.global emit_parse_error_missing_rparen
emit_parse_error_missing_rparen:
        
    movq $error_parse_missing_rparen, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_missing_lparen, @function
.global emit_parse_error_missing_lparen
emit_parse_error_missing_lparen:
        
    movq $error_parse_missing_lparen, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_missing_lcurly, @function
.global emit_parse_error_missing_lcurly
emit_parse_error_missing_lcurly:
        
    movq $error_parse_missing_lcurly, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_missing_rcurly, @function
.global emit_parse_error_missing_rcurly
emit_parse_error_missing_rcurly:
        
    movq $error_parse_missing_rcurly, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_missing_statement, @function
.global emit_parse_error_missing_statement
emit_parse_error_missing_statement:
        
    movq $error_parse_missing_statement, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_expected_identifier, @function
.global emit_parse_error_expected_identifier
emit_parse_error_expected_identifier:
        
    movq $error_parse_expected_identifier, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_expected_number, @function
.global emit_parse_error_expected_number
emit_parse_error_expected_number:
        
    movq $error_parse_expected_number, %rdi
    jmp emit_parse_error_exit

.type emit_unexpected_expr_expected_lvalue, @function
.global emit_unexpected_expr_expected_lvalue
emit_unexpected_expr_expected_lvalue:
        
    movq $error_unexpected_expr_expected_lvalue, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_unexpected_deref, @function
.global emit_parse_error_unexpected_deref
emit_parse_error_unexpected_deref:
        
    movq $error_unexpected_deref, %rdi
    jmp emit_parse_error_exit

.type emit_parse_error_missing_function_name, @function
.global emit_parse_error_missing_function_name
emit_parse_error_missing_function_name:
        
    movq $error_missing_function_name, %rdi
    jmp emit_parse_error_exit

.type emit_not_implemented, @function
.global emit_not_implemented
emit_not_implemented:
        
    movq $error_not_implemented, %rdi
    jmp emit_parse_error_exit