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

statement  : var_decl ';'
           | var_assign ';'
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

## Data structure

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

statement:       descriptor
    type: 28
    node->type:  token_id
    node:        descriptor

assignment:      descriptor
    type: 29
    identifier:  descriptor
    expr->type:  token_id
    expr:        descriptor

binary_op_buffer: size = 20
    [(lhs_id, lhs_descriptor, operator_id, rhs_id, rhs_descriptor),...]

assignment_buffer: size = 12
    [(identifier_id, expr_id, expr_descriptor),...]
