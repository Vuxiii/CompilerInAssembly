#!/bin/bash
file_actual="$1.actual"
file_expected="$1.expected"


diff_output=$(diff -u "$file_actual" "$file_expected")

if ! [ -z "$diff_output" ]; then
    echo -e "\033[1;31m\t[Failed]\033[0m"
    echo ""
    echo "Differences:"
    echo "$diff_output"
    echo ""
else
    echo -e "\033[1;32m\t[OK]\033[0m"
fi