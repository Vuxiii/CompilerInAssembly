
main: main.o lexer.o config.o
	ld main.o lexer.o config.o -o main

main.o: main.s
	as -gstabs main.s -o main.o

config.o: config.s
	as -gstabs config.s -o config.o

lexer.o: lexer.s
	as -gstabs lexer.s -o lexer.o

phony: clean run crun

clean:
	rm *.o main

run:	
	make -s && echo "\nDone Compiling the code!\nRunning the code:\n" && ./main

crun:
	make -s clean && echo "====COMPILE====" && make -s run