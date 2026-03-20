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

## Ripping del Logo (ICS Intro)
Il logo è stato recuperato dall'intro originale "ICS Import" (`ics-15.prg`) utilizzando il Monitor di VICE:
1. **Analisi**: Caricato il PRG originale e attivato il monitor. Identificato il charset grafico custom residente a `$2800` e la mappa dello schermo associata.
2. **Dump**: Salvataggio delle aree di memoria su file binari (`logo_charset.bin` e `logo_screen.bin`) direttamente dall'emulatore.
3. **Pulizia**: Nel codice assembly (`setup_logo`), viene caricata la mappa originale ma vengono sovrascritte con spazi le righe di testo inferiori (es. "PRESENT", "CRACKED BY") per isolare il logo pulito.
4. **Colori**: I colori originali (Multicolor 1 & 2) sono stati analizzati e replicati manualmente nel codice impostando i registri `$D022` e `$D023`.
