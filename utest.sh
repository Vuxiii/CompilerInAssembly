#!/bin/bash

make clean 2> /dev/null > /dev/null
make 2> /dev/null > /dev/null
echo "Running tests"
find tests/in -type f -exec sh -c 'echo -n " - {}" && ./testfile.sh {}' \;