ASM=intro.asm
# Cambia solo questo percorso per usare un'altra musica SID.
SID=Sometimes.sid
# Per SID non presenti in tools/sid_lengths.json, indica qui la durata in secondi.
SID_DURATION_SECONDS=
# Il PRG mantiene il nome del SID scelto, dentro la directory build/.
SID_NAME=$(notdir $(basename $(SID)))
PRG=build/$(SID_NAME).prg
SID_PREPARE=tools/prepare_sid.py
SID_LENGTHS=tools/sid_lengths.json
SID_CONFIG=build/sid_config.asm
SID_DATA=build/sid_data.bin
SID_VICE_ARGS=build/sid_vice_args
SID_STAMP=build/.sid-prepared

all: $(PRG)


.PHONY: FORCE
FORCE:

# FORCE also makes `make run SID=...` reliable when switching tunes without
# cleaning first.  The helper preserves generated-file timestamps if unchanged.
$(SID_STAMP): FORCE $(SID) $(SID_PREPARE) $(SID_LENGTHS) Makefile | build
	python3 $(SID_PREPARE) "$(SID)" $(SID_CONFIG) $(SID_DATA) $(SID_VICE_ARGS) "$(SID_DURATION_SECONDS)"
	@touch $(SID_STAMP)

$(SID_CONFIG) $(SID_DATA) $(SID_VICE_ARGS): $(SID_STAMP)

$(PRG): $(ASM) $(SID_CONFIG) $(SID_DATA)
	@mkdir -p build
	64tass -a -B -o $(PRG) $(ASM)

run: $(PRG)
	# Keep VICE's multi-SID channels in stereo; do not downmix them to mono.
	x64 -soundoutput 2 $$(cat $(SID_VICE_ARGS)) $(PRG)

.PHONY: diagnose-sprites diagnose-bars diagnose-scroller diagnose-sprites-above-bars diagnose-sprite-dma-guard
diagnose-sprites: $(SID_CONFIG) $(SID_DATA)
	64tass -a -B -D DIAGNOSTIC_MODE=1 -o build/$(SID_NAME)-no-sprites.prg $(ASM)

diagnose-bars: $(SID_CONFIG) $(SID_DATA)
	64tass -a -B -D DIAGNOSTIC_MODE=2 -o build/$(SID_NAME)-static-bars.prg $(ASM)

diagnose-scroller: $(SID_CONFIG) $(SID_DATA)
	64tass -a -B -D DIAGNOSTIC_MODE=3 -o build/$(SID_NAME)-no-scroller.prg $(ASM)

diagnose-sprites-above-bars: $(SID_CONFIG) $(SID_DATA)
	64tass -a -B -D DIAGNOSTIC_MODE=4 -o build/$(SID_NAME)-sprites-above-bars.prg $(ASM)

diagnose-sprite-dma-guard: $(SID_CONFIG) $(SID_DATA)
	64tass -a -B -D DIAGNOSTIC_MODE=5 -o build/$(SID_NAME)-sprite-dma-guard.prg $(ASM)

build:
	@mkdir -p build

clean:
	rm -f build/*.prg $(SID_CONFIG) $(SID_DATA) $(SID_VICE_ARGS) $(SID_STAMP)
