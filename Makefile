PRG=build/intro.prg
ASM=intro.asm

all: $(PRG)

$(PRG): $(ASM)
	@mkdir -p build
	64tass -a -B -o $(PRG) $(ASM)

run: $(PRG)
	x64 $(PRG)

clean:
	rm -f $(PRG)
