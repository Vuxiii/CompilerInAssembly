# TODOS

## Backlog

1. Parser
    a. Function Calls
        i.  Arglist
        ii. Call functions with arguments
    b. String literals
    c. String printing
    d. Ensure that all the binary operators are implemented
    e. Read from std in
2. Lexer
    a. Add support for string literals Lexer
    b. Reading from std in
3. Allocate memory
4. String printing
    Lexer . '"'
    Parser . Extend the existing print
    Collect . Collect the string
    Emit . Paste string in target asm
5. Test facility
    a. Test Script
6. Unit tests
    a. Variables
    b. Structs
    c. Array
    d. Functions
    e. If statement
    f. While statement
    g. Multiple Boolean Conditions
    h. Parse Errors

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

## Since last time

* Reading from file
    mmap
* structs
    Declarations
    Initialization
* Arrays
    ints
    structs
* Pointer
    Address of
    Deref
* Function call
    With ZERO arguments
