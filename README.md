# C64 Intro Starter

Intro per Commodore 64 con raster bars, scroller fluido, logo, sprite e musica SID.

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
- **Effetti Visivi**:
  - **Raster Bars**: Gradiente a 11 colori gestito via IRQ (Line 150+).
  - **Scroller**: Scorrimento fluido (hard+soft scroll) su riga 18 ($06D0).
  - **Logo**: Charset personalizzato ($2800) e mappa schermo ($3C00).
  - **Sprites**: 8 sprite con effetto scia (trail) che rimbalzano ($3000).
- **Mappa Memoria**:
  - `$1000`: Player SID e musica.
  - `$2000`: Charset principale (modificato da ROM).
  - `$4000`: Testo dello scroller (spostato per evitare sovrapposizioni).
