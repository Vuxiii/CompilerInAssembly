#!/bin/bash
input_file="$1"
output_file="tests/out/$(basename "$input_file").actual"
./main $input_file > code.s
as code.s -o code.o > "$output_file" 2>> "$output_file"
ld code.o -o code >> "$output_file" 2>> "$output_file"
./code >> "$output_file" 2> /dev/null
rm code.s 2> /dev/null
rm code.o 2> /dev/null
rm code 2> /dev/null

./comparefiles.sh "tests/out/$(basename "$input_file")"