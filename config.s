# This file contains global settings for the compiler.
# In here we define the different tokens.
.data

.global number_tokens
        number_tokens:     .space 256 # These number tokens can be indexed into. Each number spans 4 bytes (32 bit)

.global identifier_tokens
        identifier_tokens: .space 256 # These identifier tokens can be index into. Each identifier spans 4 chars (32 bit)

.global input_buffer
        input_buffer: .space 30
.global in
        in:         .asciz "152 EOP print asd asd asd"

.global true
        true:       .asciz "True\n"
.global false
        false:      .asciz "False\n"
.global eop
        eop:        .asciz "EOP"   # -1
.global none
        none:       .asciz "None"  # 0
.global def
        def:        .asciz "def"   # 1
.global if
        if:         .asciz "if"    # 2
.global equals
        equals:     .asciz "=="    # 3
.global assignment
        assignment: .asciz "="     # 4
.global lparen
        lparen:     .asciz "("     # 5
.global rparen
        rparen:     .asciz ")"     # 6
.global lcurly
        lcurly:     .asciz "{"     # 7
.global rcurly
        rcurly:     .asciz "}"     # 8
.global lbracket
        lbracket:   .asciz "["     # 9
.global rbracket
        rbracket:   .asciz "]"     # 10
.global print
        print:      .asciz "print" # 11

.global number_0
        number_0:   .asciz "0"

.global number_9
        number_9:   .asciz "9"
