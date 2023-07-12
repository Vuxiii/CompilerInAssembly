make clean > /dev/null
make > /dev/null
./main > code.s
as code.s -o code.o
ld code.o -o code
./code
