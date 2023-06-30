# This file contains global settings for the compiler.
# In here we define the different tokens.
.data

.global number_tokens
        number_tokens:     .space 256 # These number tokens can be indexed into. Each number spans 4 bytes (32 bit)

.global identifier_tokens
        identifier_tokens: .space 256 # These identifier tokens can be indexed into. Each identifier is terminated with a '\0' null char

.global buffer_address
        buffer_address:    .quad 0 # Current offset into the buffer. Should be set at startup.

.global input_buffer
        input_buffer: .space 30
.global in
        // in:         .asciz "William EOP"
        in:         .asciz "def main() { var1 = 6 + 3 * 2 + 1 } EOP"
        // in:         .asciz "def main() { a = 4 + 6 } def another_function() { b = 1 + 9 e = 5 + 6 } EOP"
        // in:         .asciz "a = 4 + 6 b = 42 + 69 EOP"
        // in:         .asciz "= def == ( ) if { } [] print while +- /    * < > && let || willi EOP"
        // in:         .asciz "def if = == ( ) { } [] print while +- /    * < > && let || 12 ass EOP"

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
        token_print:      .asciz "print" # 11
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
.global token_let
        token_let:        .asciz "let"   # 21
.global token_and
        token_and:        .asciz "&&"    # 22
.global token_or
        token_or:         .asciz "||"    # 23
.global token_identifier
        token_identifier: .asciz ""      # 24
.global token_number
        token_number:     .asciz ""     # 25

.global number_0
        number_0:   .asciz "0" # value: 48

.global number_9
        number_9:   .asciz "9" # value: 57

.global _emit_asm_prologue
        _emit_asm_prologue:       .asciz ".section .text\n.global _start:\n"

.global _emit_function_prologue
        _emit_function_prologue:  .asciz "\n\tpush %rbp\n\tmov %rsp, %rbp\n"

.global _emit_function_epilogue
        _emit_function_epilogue:  .asciz "\n\tleave\n\tret\n"

.global _emit_asm_epilogue
        _emit_asm_epilogue:       .asciz "\n\tleave\n\tmovq $60, %rax\n\tmovq $0, %rdi\n\tsyscall\n"

# --[ Opcodes ]--
.global _emit_push
        _emit_push: .asciz "\n\tpush "
.global _emit_pop
        _emit_pop: .asciz "\n\tpop "
.global _emit_mov
        _emit_mov: .asciz "\n\tmovq "
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

# --[ Operands ]--
.global _emit_rax
        _emit_rax: .asciz "%rax"
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
