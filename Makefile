main: main.o lexer.o config.o utils.o parser.o symbol.o typechecker.o emitter.o astprint.o errors.o
	ld -g -o main main.o lexer.o parser.o symbol.o typechecker.o emitter.o config.o utils.o errors.o astprint.o

main.o: main.s
	as -ggdb main.s -o main.o

config.o: config.s
	as -ggdb config.s -o config.o

lexer.o: lexer.s
	as -ggdb lexer.s -o lexer.o

parser.o: parser.s
	as -ggdb parser.s -o parser.o

symbol.o: symbol.s
	as -ggdb symbol.s -o symbol.o

emitter.o: emitter.s
	as -ggdb emitter.s -o emitter.o

typechecker.o: typechecker.s
	as -ggdb typechecker.s -o typechecker.o

astprint.o: astprint.s
	as -ggdb astprint.s -o astprint.o

utils.o: utils.s
	as -ggdb utils.s -o utils.o

errors.o: errors.s
	as -ggdb errors.s -o errors.o

phony: clean run crun

clean:
	rm *.o main code.s code tests/out/*.actual 2> /dev/null


run:	
	make -s && echo "\nDone Compiling the code!\nRunning the code:\n" && ./main

crun:
	make -s clean && echo "====COMPILE====" && make -s run