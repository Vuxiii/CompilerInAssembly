# This file contains global settings for the compiler.
# In here we define the different tokens.
.data

.global filename
        filename: .quad 0
.global filesize
        filesize: .int 4096

.global identifier_tokens
        identifier_tokens: .space 256 # These identifier tokens can be indexed into. Each identifier is terminated with a '\0' null char

.global buffer_address
        buffer_address:    .quad 0 # Current offset into the buffer. Should be set at startup.

.global input_buffer
        input_buffer: .space 30

.global newline
        newline:          .asciz "\n"
.global token_eop
        token_eop:        .asciz "EOP"   # -1
.global token_none
        token_none:       .asciz "None"  # 0
.global token_def
        token_def:        .asciz "def"   # 1
.global token_if
        token_if:         .asciz "if"    # 2
.global token_equals
        token_equals:     .asciz "=="    # 3
.global token_assignment
        token_assignment: .asciz "="     # 4
.global token_lparen
        token_lparen:     .asciz "("     # 5
.global token_rparen
        token_rparen:     .asciz ")"     # 6
.global token_lcurly
        token_lcurly:     .asciz "{"     # 7
.global token_rcurly
        token_rcurly:     .asciz "}"     # 8
.global token_lbracket
        token_lbracket:   .asciz "["     # 9
.global token_rbracket
        token_rbracket:   .asciz "]"     # 10
.global token_print
        token_print:      .asciz "print" # 11 NOT USED
.global token_while
        token_while:      .asciz "while" # 12
.global token_plus
        token_plus:       .asciz "+"     # 13
.global token_minus
        token_minus:      .asciz "-"     # 14
.global token_times
        token_times:      .asciz "*"     # 15
.global token_div
        token_div:        .asciz "/"     # 16
.global token_less
        token_less:       .asciz "<"     # 17
.global token_greater
        token_greater:    .asciz ">"     # 18
.global token_true
        token_true:       .asciz "true"  # 19
.global token_false
        token_false:      .asciz "false" # 20
.global token_struct
        token_struct:     .asciz "struct"# 21
.global token_and
        token_and:        .asciz "&&"    # 22
.global token_or
        token_or:         .asciz "||"    # 23
.global token_identifier
        token_identifier: .asciz ""      # 24
.global token_number
        token_number:     .asciz ""      # 25
.global token_noteq
        token_noteq:      .asciz "!="    # 27
.global token_comma
        token_comma:      .asciz ","     # 35
.global token_dot
        token_dot:        .asciz "."     # 37
.global token_ampersand
        token_ampersand:  .asciz "&"     # 42
.global token_deref
        token_deref:      .asciz "~"     # 45
.global token_loopii
        token_loopii:     .asciz "loop"  # 49
.global token_return
        token_return:     .asciz "return"# 50
.global token_arrow
        token_arrow:      .asciz "->"    # 52
.global token_int
        token_int:        .asciz "int"   # 54 NOT USED
.global token_double
        token_double:     .asciz "double"# 55 NOT USED
.global token_void
        token_void:       .asciz "void "  # 56
.global token_let
        token_let:        .asciz "let"   # 57
.global token_colon
        token_colon:      .asciz ":"     # 58
.global token_coloneq
        token_coloneq:    .asciz ":="    # 59
.global token_doublecolon
        token_doublecolon:.asciz "::"    # 60

.global number_0
        number_0:   .asciz "0" # value: 48

.global number_9
        number_9:   .asciz "9" # value: 57

.global _emit_asm_prologue
        _emit_asm_prologue:       .asciz ".section .text\n"

.global _emit_entry_point
        _emit_entry_point:        .asciz ".global _start\n_start:\n"

.global _emit_function_prologue
        _emit_function_prologue:  .asciz "\n\tpush %rbp\n\tmov %rsp, %rbp\n"

.global _emit_function_epilogue
        _emit_function_epilogue:  .asciz "\n\tleave\n\tret\n"

.global _emit_asm_epilogue
        _emit_asm_epilogue:       .asciz "\n\tleave\n\tmovq $60, %rax\n\tmovq $0, %rdi\n\tsyscall\n"
.global _emit_print_body
        _emit_print_body:         .asciz "\t\tmovq %rdi, %rax\n\t\txor %rcx, %rcx\n\t\tmovq $10, %rbx\n\tbegin_count:\n\t\tcqto\n\t\tidivq %rbx\n\t\tinc %rcx\n\t\ttest %rax, %rax\n\t\tjnz begin_count\n\t\tsubq %rcx, %rsp\n\t\tmovq %rcx, %rax\n\t\tcqto\n\t\tmovq $4, %rbx\n\t\tidivq %rbx \n\t\tsubq %rdx, %rbx\n\t\tsubq %rbx, %rsp\n\t\tmovq $10, %rbx\n\t\tmovq %rcx, %r8\n\t\tmovq %rdi, %rax\n\tbegin_push:\n\t\tcqto\n\t\tidivq %rbx\n\t\taddb $48, %dl\n\t\tdec %r8\n\t\tmovb %dl, (%rsp, %r8, 1)\n\t\ttest %r8, %r8\n\t\tjnz begin_push\n\n\t\tmovq $1, %rax\n\t\tmovq $1, %rdi\n\t\tleaq (%rsp), %rsi\n\t\tmovq %rcx, %rdx\n\t\tsyscall\n\t\tpush $10\n\t\tmovq $1, %rax\n\t\tmovq $1, %rdi\n\t\tleaq (%rsp), %rsi\n\t\tmovq $1, %rdx\n\t\tsyscall"

# --[ Opcodes ]--
.global _emit_push
        _emit_push: .asciz "\n\tpush "
.global _emit_pop
        _emit_pop: .asciz "\n\tpop "
.global _emit_mov
        _emit_mov: .asciz "\n\tmovq "
.global _emit_cmove
        _emit_cmove: .asciz "\n\tcmoveq "
.global _emit_cmovne
        _emit_cmovne: .asciz "\n\tcmovneq "
.global _emit_cmovg
        _emit_cmovg: .asciz "\n\tcmovgq "
.global _emit_cmovl
        _emit_cmovl: .asciz "\n\tcmovlq "
.global _emit_add
        _emit_add: .asciz "\n\taddq "
.global _emit_sub
        _emit_sub: .asciz "\n\tsubq "
.global _emit_mul
        _emit_mul: .asciz "\n\timulq "
.global _emit_lea
        _emit_lea: .asciz "\n\tleaq "
.global _emit_call
        _emit_call: .asciz "\n\tcallq "
.global _emit_ret
        _emit_ret: .asciz "\n\tretq"
.global _emit_jmp
        _emit_jmp: .asciz "\n\tjmp "
.global _emit_jne
        _emit_jne: .asciz "\n\tjne "
.global _emit_je
        _emit_je: .asciz "\n\tje "
.global _emit_jle
        _emit_jle: .asciz "\n\tjle "
.global _emit_jge
        _emit_jge: .asciz "\n\tjge "
.global _emit_cmp
        _emit_cmp: .asciz "\n\tcmp "
.global _emit_test
        _emit_test: .asciz "\n\ttest "
.global _emit_neg
        _emit_neg: .asciz "\n\tneg "
.global _emit_and
        _emit_and: .asciz "\n\tandq "
.global _emit_or
        _emit_or: .asciz "\n\torq "
.global _emit_xor
        _emit_xor: .asciz "\n\txorq "
.global _emit_sete
        _emit_sete: .asciz "\n\tsete "
.global _emit_setne
        _emit_setne: .asciz "\n\tsetne "
.global _emit_setg
        _emit_setg: .asciz "\n\tsetg "
.global _emit_setl
        _emit_setl: .asciz "\n\tsetl "
.global _emit_loopnz
        _emit_loopnz: .asciz "\n\tloopnz "

# --[ Operands ]--
.global _emit_rax
        _emit_rax: .asciz "%rax"
.global _emit_rax8
        _emit_rax8: .asciz "%al"
.global _emit_rbx
        _emit_rbx: .asciz "%rbx"
.global _emit_rcx
        _emit_rcx: .asciz "%rcx"
.global _emit_rdx
        _emit_rdx: .asciz "%rdx"
.global _emit_rdi
        _emit_rdi: .asciz "%rdi"
.global _emit_rsi
        _emit_rsi: .asciz "%rsi"
.global _emit_rbp
        _emit_rbp: .asciz "%rbp"
.global _emit_rsp
        _emit_rsp: .asciz "%rsp"

# --[ Misc ]--
.global _emit_comma
        _emit_comma: .asciz ", "
.global _emit_colon
        _emit_colon: .asciz ":"
.global _emit_dollar
        _emit_dollar: .asciz "$"
.global _emit_minus
        _emit_minus: .asciz "-"
.global _emit_lparen
        _emit_lparen: .asciz "("
.global _emit_rparen
        _emit_rparen: .asciz ")"
.global _emit_newline
        _emit_newline: .asciz "\n"
.global _emit_newline_tab
        _emit_newline_tab: .asciz "\n\t"
.global _emit_main
        _emit_main: .asciz "main"

.global _emit_guard
        _emit_guard: .asciz "guard"

# -- [[ astprint Stuff ]] --

.global _astprint_tab
        _astprint_tab: .asciz "\t"

.global _astprint_lhs
        _astprint_lhs: .asciz "lhs "

.global _astprint_rhs
        _astprint_rhs: .asciz "rhs "

.global _astprint_guard
        _astprint_guard: .asciz "guard "


.global _astprint_body
        _astprint_body: .asciz "body "

.global _astprint_id
        _astprint_id: .asciz "id: "

.global _astprint_desc
        _astprint_desc: .asciz "desc: "

.global _astprint_index
        _astprint_index: .asciz "index: "

.global _astprint_arrow
        _astprint_arrow: .asciz " -> "

.global _astprint_number
        _astprint_number: .asciz "Number: "
.global _astprint_identifier
        _astprint_identifier: .asciz "Identifier: "

.global _astprint_binaryop
        _astprint_binaryop: .asciz "BinaryOP:"

.global _astprint_operator
        _astprint_operator: .asciz "operator: "

.global _astprint_function
        _astprint_function: .asciz "function: "

.global _astprint_assignment
        _astprint_assignment: .asciz "Assignment:"

.global _astprint_array_access
        _astprint_array_access: .asciz "ArrayAccess:"


# -- [[ COMMENTS ]] --
.global _emit_comment_enter_body
        _emit_comment_enter_body:   .asciz "\t\t\t# Entering Body"

.global _emit_comment_leaving_body
        _emit_comment_leaving_body: .asciz "\t\t\t# Leaving Body"

.global _emit_comment_enter_guard
        _emit_comment_enter_guard:   .asciz "\t\t\t# Entering Guard"

.global _emit_comment_leaving_guard
        _emit_comment_leaving_guard: .asciz "\t\t\t# Leaving Guard"

# -- [[ ERROR MESSAGES ]] --

.global error_parse_current_id
        error_parse_current_id:   .asciz "Current ID   "
.global error_parse_current_data
        error_parse_current_data: .asciz "Current DATA "
.global error_parse_peek_id
        error_parse_peek_id:   .asciz "PEEK ID      "
.global error_parse_peek_data
        error_parse_peek_data: .asciz "PEEK DATA    "


.global error_parse_missing_lparen
        error_parse_missing_lparen: .asciz "Missing a '(' token.\n"
.global error_parse_missing_rparen
        error_parse_missing_rparen: .asciz "Missing a ')' token.\n"
.global error_parse_missing_lbracket
        error_parse_missing_lbracket: .asciz "Missing a '[' token.\n"
.global error_parse_missing_rbracket
        error_parse_missing_rbracket: .asciz "Missing a ']' token.\n"
.global error_parse_missing_lcurly
        error_parse_missing_lcurly: .asciz "Missing a '{' token.\n"
.global error_parse_missing_rcurly
        error_parse_missing_rcurly: .asciz "Missing a '}' token.\n"
.global error_parse_missing_statement
        error_parse_missing_statement: .asciz "No statement present.\n"
.global error_parse_expected_identifier
        error_parse_expected_identifier: .asciz "Expected an identifier.\n"
.global error_parse_unexpected_identifier
        error_parse_unexpected_identifier: .asciz "Unexpected identifier.\n"



.global error_parse_expected_number
        error_parse_expected_number: .asciz "Expected a number.\n"
.global error_missing_main_function
        error_missing_main_function: .asciz "Missing the main function 'main()'.\n"

.global error_unexpected_expr_expected_lvalue
        error_unexpected_expr_expected_lvalue: .asciz "Unexpected expression. Expected an lvalue.\n"

.global error_unexpected_token
        error_unexpected_token: .asciz "Unexpected Token.\n"

.global error_expected_colon
        error_expected_colon: .asciz "Expected a Colon ':'.\n"

.global error_unexpected_deref
    error_unexpected_deref: .asciz "Unexpected deref.\n"
.global error_missing_function_name
    error_missing_function_name: .asciz "Missing function name.\n"

.global error_not_implemented
    error_not_implemented: .asciz "This feature is not yet implemented.\n"

.global error_no_inputfile
    error_no_inputfile: .asciz "No input file given.\n"

.global error_file_not_found
    error_file_not_found: .asciz "The given file was not found.\n"

.global error_array_assignment_
    error_array_assignment_: .asciz "Array Assignment Buffer"

.global error_storage_error
error_storage_error: .asciz "Error in the datastructure for: "

.global error_struct_declaration_not_found
error_struct_declaration_not_found: .asciz "Struct declaration not found!\n"

.global error_declaration_not_found
error_declaration_not_found: .asciz "Declaration not found!\n"

.global error_struct_field_not_found
error_struct_field_not_found: .asciz "Struct field not found!\n"

.global error_expected_identifier
error_expected_identifier: .asciz "Expected an identifier!\n"

.global error_unknown_type
error_unknown_type: .asciz "Unknown type!\n"

