PRG=build/intro.prg
ASM=intro.asm
# Cambia solo questo percorso per usare un'altra musica SID.
SID=Sometimes.sid
SID_PREPARE=tools/prepare_sid.py
SID_CONFIG=build/sid_config.asm
SID_DATA=build/sid_data.bin
SID_VICE_ARGS=build/sid_vice_args
SID_STAMP=build/.sid-prepared

all: $(PRG)


.PHONY: FORCE
FORCE:

# FORCE also makes `make run SID=...` reliable when switching tunes without
# cleaning first.  The helper preserves generated-file timestamps if unchanged.
$(SID_STAMP): FORCE $(SID) $(SID_PREPARE) Makefile | build
	python3 $(SID_PREPARE) "$(SID)" $(SID_CONFIG) $(SID_DATA) $(SID_VICE_ARGS)
	@touch $(SID_STAMP)

$(SID_CONFIG) $(SID_DATA) $(SID_VICE_ARGS): $(SID_STAMP)

$(PRG): $(ASM) $(SID_CONFIG) $(SID_DATA)
	@mkdir -p build
	64tass -a -B -o $(PRG) $(ASM)

run: $(PRG)
	# Keep VICE's multi-SID channels in stereo; do not downmix them to mono.
	x64 -soundoutput 2 $$(cat $(SID_VICE_ARGS)) $(PRG)

build:
	@mkdir -p build

clean:
	rm -f $(PRG) $(SID_CONFIG) $(SID_DATA) $(SID_VICE_ARGS) $(SID_STAMP)
