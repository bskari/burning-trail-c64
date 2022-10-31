# The main sources and test sources should be separate, but I've been fighting
# with Make trying to make them separate and it's not working. It looks like
# it's trying to run the source files as commands. Whatever. Compiling is very
# fast though, so just put them all together.
sources = \
  src/main/*.asm \
  graphics/Sprites.raw \
  ;

.PHONY: all
all: main.prg #src/test/test.prg

main.prg: $(sources)
	java -jar $$HOME/Documents/kick-ass/KickAss.jar src/main/main.asm
	mv src/main/main.prg main.prg
	mv src/main/main.sym main.sym
	ls -l main.prg

run: main.prg
	x64 main.prg

test.prg: $(sources)
	java -jar $$HOME/Documents/kick-ass/KickAss.jar src/test/test.asm
	mv src/test/test.prg test.prg
	mv src/test/test.sym test.sym

test: test.prg

runtest: test.prg
	x64 test.prg

main.vs: $(sources)
	java -jar $$HOME/Documents/kick-ass/KickAss.jar -vicesymbols src/main/main.asm
	mv src/main/main.vs main.vs

debug: main.prg main.vs

rundebug: main.prg main.vs
	echo 'll "main.vs"' > debug-commands.txt
	x64 -moncommands debug-commands.txt main.prg

test.vs:
	java -jar $$HOME/Documents/kick-ass/KickAss.jar -vicesymbols test.asm
	mv src/test/test.vs test.vs

runtestdebug: test.prg test.vs
	echo 'll "test.vs"' > debug-commands.txt
	x64 -moncommands debug-commands.txt test.prg

.PHONY: clean
clean:
	find . -name '*.sym' -delete
	find . -name '*.prg' -delete
	rm -f main.vs test.vs
