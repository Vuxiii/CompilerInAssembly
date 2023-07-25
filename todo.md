# TODOS

## Backlog

1. Parser
    a. Function Calls
        1. Differentiate between arguments and local variables.
    b. String literals
    c. String printing
    d. Ensure that all the binary operators are implemented
    e. Read from std in
2. Lexer
    a. Add support for string literals Lexer
    b. Reading from std in
3. Allocate memory
    a. For bigger allocations use mmap
    b. For smaller allocations < 4096 use brk
4. String printing
    Lexer . '"'
    Parser . Extend the existing print
    Collect . Collect the string
    Emit . Paste string in target asm
5. Unit tests
    a. Variables
    b. Structs
    c. Array
    d. Functions
    e. If statement
    f. While statement
    g. Multiple Boolean Conditions
    h. Parse Errors
6. Conditional set
    Replace the current guard scheme with the instruction set(b|l|ne|e)
7. New Instructions
    * LOOPcc label
        This instruction jump to the given label if the condition is met. RCX == 0
        It decrements rcx by 1 for each loop iteration.
    * enter imm, imm
        This instruction is the reverse of leave. It sets up a stack frame
        The first operand is the amount of bytes for the frame IE variables
        The second is the nesting level. Upto 31

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
