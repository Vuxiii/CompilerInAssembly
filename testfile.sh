#!/bin/bash
input_file="$1"
output_file="tests/out/$(basename "$input_file").actual"

./main $input_file > code.s
as code.s -o code.o
ld code.o -o code
./code > "$output_file"
rm code.s
rm code.o
rm code

./comparefiles.sh "tests/out/$(basename "$input_file")"