# The main sources and test sources should be separate, but I've been fighting
# with Make trying to make them separate and it's not working. It looks like
# it's trying to run the source files as commands. Whatever. Compiling is very
# fast though, so just put them all together.
sources = \
  src/main/constants.asm \
  src/main/functions.asm \
  src/main/main.asm \
  ;

.PHONY: all
all: src/main/main.prg src/test/test.prg

src/main/main.prg: $(sources)
	java -jar assembler/KickAss.jar src/main/main.asm

run: src/main/main.prg
	x64 src/main/main.prg

src/test/test.prg: $(sources)
	java -jar assembler/KickAss.jar src/test/test.asm

test: src/test/test.prg

runtest: src/test/test.prg
	x64 src/test/test.prg

src/main/main.vs:
	java -jar assembler/KickAss.jar -vicesymbols src/main/main.asm

debug: src/main/main.vs

rundebug: src/main/main.prg src/main/main.vs
	echo 'll "src/main/main.vs"' > debug-commands.txt
	x64 -moncommands debug-commands.txt src/main/main.prg

src/test/test.vs:
	java -jar assembler/KickAss.jar -vicesymbols src/test/test.asm

runtestdebug: src/test/test.prg src/test/test.vs
	echo 'll "src/test/test.vs"' > debug-commands.txt
	x64 -moncommands debug-commands.txt src/test/test.prg

.PHONY: clean
clean:
	find src -name '*.sym' -delete
	find src -name '*.prg' -delete
	rm -f src/main/main.vs src/test/test.vs
