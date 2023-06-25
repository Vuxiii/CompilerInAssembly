# Parsing for Assembly language

## Grammar Definition

```ebnf
top_level  : statement_list

func_def   : 'def' '(' param_list ')' statement

param_list : 'identifier'
           | 'identifier' ',' param_list

var_decl   : 'let' 'identifier' '=' expression

statement  : var_decl ';'
           | 'identifier' '=' expression ';'
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

statement_list : statement
               | statement ';' statement_list
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

expression:      descriptor
    type: 27
    node->type:  token_id
    node:        descriptor
