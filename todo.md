# TODOS

## Backlog

1. Parser
    a. Function Calls
        i. Call functions with no arguments
        ii. Call functions with arguments
    b. String literals
    c. String printing
    d. Ensure that all the binary operators are implemented
2. Lexer
    a. Add support for string literals Lexer
    b. Reading from std in
    c. Handle newline characters

## Nice to have

Keyword to specify where the 'thing' is being allocated.
Like: on_heap to indicate that it should be placed on the heap
And: on_stack for stack allocation.

`a = on_heap 4`
`b = on_stack 5`

Give the language access to the compiler.
This enables the user to modify how the language works.
Also enables selfhosting the compiler in the language while still
using the prebuilt assembly functions.
