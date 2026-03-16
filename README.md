# C64 Intro Starter

Starter minimo per una intro Commodore 64 con raster bars, scroller e una semplice musica SID.

## Requisiti
- `64tass` (cross-assembler)
- `VICE` (`x64`) per eseguire il PRG

Su Debian/Ubuntu di solito:
- `sudo apt install 64tass vice`

## Build
```sh
make
```

## Run
```sh
make run
```

Se carichi il PRG manualmente in VICE:
- `LOAD"INTRO.PRG",8,1`
- `RUN`

## Note
- Il loader BASIC esegue `SYS 2064`.
- Inclusi: raster bars via IRQ, scroller su riga 24, charset custom a $2000 e player SID (PSID) con dati integrati.
- Possiamo evolvere verso sprites, charset più ricco e player musicale più avanzato.
