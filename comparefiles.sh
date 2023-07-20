#!/bin/bash
file_actual="$1.actual"
file_expected="$1.expected"
file_name=$(basename "$1")

diff_output=$(colordiff -u "$file_actual" "$file_expected")
if ! [ -z "$diff_output" ]; then
    printf " - %-30s \033[1;31m[Failed]\033[0m\n" "$file_name"
    echo ""
    echo "Differences:"
    echo "$diff_output"
    echo ""
else
    printf " - %-30s \033[1;32m[Passed]\033[0m\n" "$file_name"
fi