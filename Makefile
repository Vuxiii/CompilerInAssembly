main: main.o lexer.o config.o utils.o parser.o symbol.o typechecker.o emitter.o astprint.o errors.o
	ld -g -o main main.o lexer.o parser.o symbol.o typechecker.o emitter.o config.o utils.o errors.o astprint.o

main.o: main.s
	as -g main.s -o main.o

config.o: config.s
	as -g config.s -o config.o

lexer.o: lexer.s
	as -g lexer.s -o lexer.o

parser.o: parser.s
	as -g parser.s -o parser.o

symbol.o: symbol.s
	as -g symbol.s -o symbol.o

emitter.o: emitter.s
	as -g emitter.s -o emitter.o

typechecker.o: typechecker.s
	as -g typechecker.s -o typechecker.o

astprint.o: astprint.s
	as -g astprint.s -o astprint.o

utils.o: utils.s
	as -g utils.s -o utils.o

errors.o: errors.s
	as -g errors.s -o errors.o

phony: clean run test

clean:
	find . -name '*.o' -delete
	find . -name 'main' -delete
	find . -name 'code.s' -delete
	find . -name 'code' -delete
	find . -name '*.actual' -delete


run:
	./run.sh

test:
	./utest.sh