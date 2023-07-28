# CompilerInAssembly
This repository is my journey into developing a Compiler written in assembly and targeting assembly.
Currently the target code is Stack Based, however, the plan is to do a register allocation scheme once I have the basics up and running.

## Unittesting
The project contains a script `./utest.sh` that compiles the compiler and calls the tests located in the `test` folder.
Each testfile is run one by one and the output of each test is compared to a corresponding file located in the `test/out` folder named `<filename>.expected`.
If the `<filename>.actual` matches the `<filename>.expected` a `[PASSED]` string is outputted to `stdout`. If a test fails, a `colordiff` command is run on the files and displayed to the user.

## Tokens
The file `config.s` contains information about different tokens and their enum values. The file also contains strings used for outputting the target assembly code and error messages.

## Nodes
The file `grammar.md` contains information about the internal data structure of the nodes. It also contains a language spec, however it is a bit outdated. It was used in the beginning to give myself an idea of where the project was going.

## Tokenizing
The lexical step or the tokenization phase happens in the `lexer.s` file. It reads from an input buffer one character at a time and matches the sequence of characters to one of the tokens specified in the `config.s` file.
This file also exports some functions used by the parser. Primarily `next_token`, `current_token_id`, `current_token_data`, `peek_token_id` and `peek_token_data`.
The `.*_id` functions return the enum value in `rax`, while the `.*_data` functions return the data associated with the token (string descriptors)

## Parsing
The parser located in `parser.s` calls the tokenizer for token information on-demand. It compares sequences of token ids with the language syntax and constructs new nodes based on the input.
The `parser` is just like the `lexer`. It (the parser) compares `tokens` and assembles correct sequences into another `node` (token) just like the `lexer` compares sequences of `characters` and assembles them into `tokens`.
The output of the `parser` is the top-level node containing the entire AST of the program. `rax` contains the node id while `rbx` contains the descriptor for that node.

## Types
The file `typechecker.s` traverses through the `Types` data structure to find any "incomplete" types. These are types which physical sizes cannot be computed on construction. 
For example: 
```
let Line :: struct { p1: Point, p2: Point } 
let Point :: struct { x: int, y: int }
```
 here the parser will first construcct the `Line` struct, however all it sees for its types are two identifiers `Point`. For that reason the typechecker is run after the parsing phase is over. 

## Symbols
The job of the `symbol.s` file is to map each variable to a place on the stack. The first variable it enconters gets the first position on the stack `-8(%rbp)`. The next available spot on the stack is then computed by adding the size of the variable to the stack offset counter. 
### variables
If it is a 32 bit integer for example, the next available spot would be `-12(%rbp)`. 
### Structs
For structs the base offset for the identifier is computed and allocated. For each access to one of its fields a relative offset is computed at compiletime and added to the baseoffset.
The following example: 
```
let Point :: struct { x: int, y: int }
let p: Point
```
 would set the base offset for the variable `p` to `-8(%rbp)`. Field `x` would have relative offset `0` while `y` would have `8`. The final offset for the following symbol `p.y` is `base_offset('p') + relative_offset('y', Point)` = `-(8+8)` = `-16`.
### Arrays
For arrays we just follow the principles of the two above statements. However, this time we compute the stride of the type and multiply it with the length of the array.
For example: `let points: [10] Point`, creates 10 `Point`s on the stack. To do this efficiently we find the stride of a single `Point` which is computed in the `Types-phase`, in this example it is two integers so `16`. Because we are creating ten `Point`s we use a total of `160` bytes on the stack.

## Emitting
The output of the compiler comes the `emitter.s`. The emitters job is to traverse the AST to produce working assembly code. 
To do this the emitter is comprised of small functions that does one job. Such a job could be to push a number to the stack. Or load a variable from memory.
By doing this we can compose more advanced features by using the smaller building bloks.

## Data Structures
To make things simple in assembly-land, everything is just arrays of structs. ... tbc 
