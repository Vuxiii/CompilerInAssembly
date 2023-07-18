make clean 2> /dev/null > /dev/null
make 2> /dev/null > /dev/null
./main > code.s
as code.s -o code.o
ld code.o -o code
./code
