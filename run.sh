#!/bin/bash
make > /dev/null 2> /dev/null
./main in.a > code.s
as code.s -o code.o
ld code.o -o code
./code
rm code 2> /dev/null
rm code.o 2> /dev/null
rm code.s 2> /dev/null
make clean > /dev/null 2> /dev/null
