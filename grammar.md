# Parsing for Assembly language

## Grammar Definition

```ebnf
top_level  : statement_list

statement_list : statement
               | statement statement_list

func_def   : 'def' '(' param_list ')' statement

param_list : 'identifier'
           | 'identifier' ',' param_list

var_decl   : 'let' 'identifier' '=' expression
var_assign : 'identifier' '=' expression

statement  : var_decl
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
           | 'identifier'

binary_op  : '+'
           | '-'
           | '*'
           | '/'
           | '<'
           | '>'
           | '||'
           | '&&'
           | '=='

arg_list   : expression
           | expression ',' arg_list
```

## Symbol Collection & Stack Offsets

In order to determine where each variable should should be placed on the stack, I need to make a method that traverses the AST and looks for all the functions. This way, I can count how many variables are needed for each function.

1. Traverse the AST to count the number of functions.
2. Each function is identified by the arrival time.
3. Traverse AST again: For each function, index into a buffer and count how many variables are needed.
4. Make a lookup table for each function. Given a variable/identifier, it should return the stack position for that function.

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

// This is unnecessary
expression:      descriptor
    type: 27
    node->type:  token_id
    node:        descriptor

statement_list:  descriptor
    type: 28
    left->type:  token_id
    left:        descriptor
    right->type: token_id
    right:       descriptor

assignment:      descriptor
    type: 29
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

function_list_buffer: size = 20
    [(identifier, body_id, body_descriptor, var_count, symbol_table),...]

statement_list_buffer: size = 16
    [(lhs_id, lhs_descriptor, rhs_id, rhs_descriptor),...]

binary_op_buffer: size = 20
    [(lhs_id, lhs_descriptor, operator_id, rhs_id, rhs_descriptor),...]

assignment_buffer: size = 12
    [(identifier_id, expr_id, expr_descriptor),...]
