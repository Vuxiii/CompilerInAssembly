# This file contains global settings for the compiler.
# In here we define the different tokens.
.data

.global number_tokens
        number_tokens:     .space 256 # These number tokens can be indexed into. Each number spans 4 bytes (32 bit)

.global identifier_tokens
        identifier_tokens: .space 256 # These identifier tokens can be index into. Each identifier is terminated with a '\0' null char

.global buffer_address
        buffer_address:    .quad 0 # Current offset into the buffer. Should be set at startup.

.global input_buffer
        input_buffer: .space 30
.global in
        // in:         .asciz "William EOP"
        in:         .asciz "a = 4 + 6 EOP"
        // in:         .asciz "= def == ( ) if { } [] print while +- /    * < > && let || willi EOP"
        // in:         .asciz "def if = == ( ) { } [] print while +- /    * < > && let || 12 ass EOP"

.global newline
        newline:    .asciz "\n"
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
        token_number:     .asciz ""      # 25

.global number_0
        number_0:   .asciz "0" # value: 48

.global number_9
        number_9:   .asciz "9" # value: 57
