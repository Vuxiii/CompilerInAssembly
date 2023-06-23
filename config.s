# This file contains global settings for the compiler.
# In here we define the different tokens.
.data
.global input_buffer
        input_buffer: .space 30
.global in
        in:         .asciz "def a ( a )            if ( a == a ) print ( a ) EOP print asd asd asd"

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
.global vara
        vara:       .asciz "a"     # 7
.global print
        print:      .asciz "print" # 8
