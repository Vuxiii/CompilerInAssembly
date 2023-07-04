# Parsing for Assembly language

## Grammar Definition

```ebnf
top_level  : statement_list

statement_list : statement
               | statement statement_list

func_def   : 'def' '(' param_list ')' statement

param_list : 'identifier'
           | 'identifier' ',' param_list

arg_list   : expression
           | expression ',' arg_list

struct_decl : 'struct' 'identifier' '{' param_list '}'

struct_assign : 'struct' 'identifier' 'identifier' '=' '{' arg_list '}'
var_assign    : 'identifier' '=' expression

array_assign  : 'struct' 'identifier' 'identifier' '=' '[' 'number' ']'
              | 'identifier' '=' '[' 'number' ']'

statement  : struct_assign
           | var_assign
           | func_def
           | '{' statement_list '}'
           | 'while' '(' expression ')' statement
           | 'if' '(' expression ')' statement

expression : 'identifier' '(' ')'
           | 'identifier' '(' arg_list ')'
           | expression binary_op expression
           | '(' expression ')'
           | 'number'
           | 'identifier' '.' 'identifier'
           | 'identifier'

field      : 'identifier'
           | 'identifier' '.' field

binary_op  : '+'
           | '-'
           | '*'
           | '/'
           | '<'
           | '>'
           | '||'
           | '&&'
           | '=='
           | '!='
```

## Symbol Collection & Stack Offsets

In order to determine where each variable should should be placed on the stack, I need to make a method that traverses the AST and looks for all the functions. This way, I can count how many variables are needed for each function.

1. Traverse the AST to count the number of functions.
2. Each function is identified by the arrival time.
3. Traverse AST again: For each function, index into a buffer and count how many variables are needed.
4. Make a lookup table for each function. Given a variable/identifier, it should return the stack position for that function.

The symbol table could just be a copy of the lexed-tokens followed by the index. This gives `O(n)` runtime to find the offset, where `n` is the sum of the length of all identifiers. Might be okay for few identifiers. Remember, identifiers are local to each function. However, the table will explode in size.

Better idéa, Just have a pointer followed by an integer representing the offset..... Much better lmao. -.- Sometimes I really need to use ma brain.

symbol_buffer:
    [(char *, uint),...]

## Data structures

(struct name):   (type)

number:          descriptor

identifier:      descriptor

binaryop:        descriptor
    type: 26
    operator:    token_id
    left->type:  token_id
    left:        descriptor
    right->type: token_id
    right:       descriptor

statement_list:  descriptor
    type: 28
    left->type:  token_id
    left:        descriptor
    right->type: token_id
    right:       descriptor

assignment:      descriptor
    type: 29
    ident->type: token_id
    identifier:  descriptor
    expr->type:  token_id
    expr:        descriptor

function:        descriptor
    type: 30
    identifier:  descriptor
    body->type:  token_id
    body:        descriptor
    var_count:   int
    symbol_table:descriptor

if_statement:    descriptor
    type: 31
    guard->type: token_id
    guard:       descriptor
    body->type:  token_id
    body:        descriptor

while_statement: descriptor
    type: 32
    guard->type: token_id
    guard:       descriptor
    body->type:  token_id
    body:        descriptor

struct_decl: size = 8 + 4 * count
    type: 33
    name:        descriptor
    count:       int
    fields:      descriptor[]

array_expr: size = 4
    type: 34
    count:       descriptor

field_access: size = 8
    type: 36
    struct name: descriptor
    field:       descriptor

struct_type_list_buffer: size = 8
    [(name_descriptor, struct_descriptor),...]

field_acces_list_buffer: size = 8
    [(structname_Descriptor, field_descriptor),...]

struct_list_buffer: size = 8 + 4 * count
    [(name_descriptor, count_int, field_descriptor[] ),...]

while_list_buffer: size = 16
    [(guard_id, guard_descriptor, body_id, body_descriptor),...]

if_list_buffer: size = 16
    [(guard_id, guard_descriptor, body_id, body_descriptor),...]

function_list_buffer: size = 20
    [(identifier, body_id, body_descriptor, var_count, symbol_table),...]

statement_list_buffer: size = 16
    [(lhs_id, lhs_descriptor, rhs_id, rhs_descriptor),...]

binary_op_buffer: size = 20
    [(lhs_id, lhs_descriptor, operator_id, rhs_id, rhs_descriptor),...]

assignment_buffer: size = 16
    [(ident_id, identifier_descriptor, expr_id, expr_descriptor),...]
