
main: main.o lexer.o config.o utils.o parser.o symbol.o emitter.o
	ld -o main main.o lexer.o parser.o symbol.o emitter.o config.o utils.o

main.o: main.s
	as -gstabs main.s -o main.o

config.o: config.s
	as -gstabs config.s -o config.o

lexer.o: lexer.s
	as -gstabs lexer.s -o lexer.o

parser.o: parser.s
	as -gstabs parser.s -o parser.o

symbol.o: symbol.s
	as -gstabs symbol.s -o symbol.o

emitter.o: emitter.s
	as -gstabs emitter.s -o emitter.o

utils.o: utils.s
	as -gstabs utils.s -o utils.o

phony: clean run crun

clean:
	rm *.o main

run:	
	make -s && echo "\nDone Compiling the code!\nRunning the code:\n" && ./main

crun:
	make -s clean && echo "====COMPILE====" && make -s run