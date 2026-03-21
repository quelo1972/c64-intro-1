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
  | Indirizzo | Descrizione | Note |
  |-----------|-------------|------|
  | `$0801`   | BASIC Header | `SYS 2064` |
  | `$0810`   | Main Code | Logica, IRQ |
  | `$1000`   | SID Music | Player e Dati |
  | `$2000`   | Main Charset | Modificato da ROM (Glyph 'A') |
  | `$2800`   | Logo Charset | Grafica custom (Ripped) |
  | `$3000`   | Sprites | Dati sprite hardware |
  | `$3C00`   | Logo Map | Mappa schermo logo |
  | `$4000`   | Scroller Text | Buffer testo |

## Struttura dei File
- `intro.asm`: Il cuore del progetto (Sorgente Assembly).
- `sid_data.bin`: Dati grezzi del modulo musicale (senza header PSID, caricati a `$1000`).
- `logo_charset.bin` / `logo_screen.bin`: Asset grafici estratti (rippati) dall'intro originale.
- `Makefile`: Script per compilazione e avvio rapido.

## Personalizzazione
Vuoi modificare l'intro? Ecco i punti chiave in `intro.asm`:
- **Testo Scroller**: Cerca l'etichetta `msg_scroll`. Il testo usa la codifica `.enc "screen"`, quindi scrivi in **minuscolo** per visualizzare lettere corrette (es. "ciao" -> "CIAO").
- **Colori**:
  - `bar_colors`: Modifica la sequenza di colori delle barre raster.
  - `spr_colors`: Cambia la palette della scia degli sprite.
- **Velocità Scroller**: In `main_loop`, la variabile `scroll_x` controlla lo spostamento pixel per pixel.

### Regolare il movimento delle Raster Bars sinusoidali
Il movimento verticale delle barre ora usa una **LUT** (Look-Up Table) per simulare una sinusoide: più lento ai bordi, più veloce verso il centro.

Parametri principali in `intro.asm`:
- `BAR_MOTION_PRESET`
  - `0` = `soft` (ampiezza ridotta, movimento più dolce)
  - `1` = `medium` (preset standard)
  - `2` = `wild` (stessa ampiezza del medium, ma più veloce)
- `BAR_PHASE_STEP`
  - Definisce di quanti step avanza la fase a ogni frame.
  - `1` = velocità normale, `2` = circa doppia velocità.
  - È impostato automaticamente dal preset, ma puoi personalizzarlo.
- `bar_phase_table`
  - Tabella dei valori verticali precomputati (64 step).
  - Modificando i valori cambi il "feeling" dell'oscillazione (ampiezza e risposta vicino ai bordi).

Esempio pratico:
1. Imposta `BAR_MOTION_PRESET = 0` per un movimento più elegante e ampio controllo visivo.
2. Ricompila con `make`.
3. Avvia con `make run` e osserva il ritmo.

Nota: il centro medio dell'oscillazione resta allineato al layout attuale, quindi lo scroller centrale mantiene la leggibilità prevista.

## Storia del Progetto
Il logo "SID" visualizzato in questa intro ha una storia speciale: è stato disegnato circa 40 anni fa dall'autore (SID) per il gruppo **ICS (Italian Cracking Service)**. Ritrovato recentemente all'interno della release "ICS Import" di *Ikari Warrior II* su CSDB, è stato estratto e utilizzato come cuore di questa intro per celebrare i vecchi tempi e la passione per il Commodore 64.

## Ripping del Logo (ICS Intro)
Il logo è stato recuperato dall'intro originale "ICS Import" (`ics-15.prg`) utilizzando il Monitor di VICE:
1. **Analisi**: Caricato il PRG originale e attivato il monitor. Identificato il charset grafico custom residente a `$2800` e la mappa dello schermo associata.
2. **Dump**: Salvataggio delle aree di memoria su file binari (`logo_charset.bin` e `logo_screen.bin`) direttamente dall'emulatore.
3. **Pulizia**: Nel codice assembly (`setup_logo`), viene caricata la mappa originale ma vengono sovrascritte con spazi le righe di testo inferiori (es. "PRESENT", "CRACKED BY") per isolare il logo pulito.
4. **Colori**: I colori originali (Multicolor 1 & 2) sono stati analizzati e replicati manualmente nel codice impostando i registri `$D022` e `$D023`.

## Crediti
- **Codice & Assembly**: SID (quelo1972)
- **Grafica Logo**: SID (1989)
- **Tools**: 64tass, VICE, VSCode, Gemini AI

## Dettagli Tecnici
- **Sprite Trail**: L'effetto scia non calcola 8 posizioni diverse ogni frame. Utilizza un **buffer circolare** (`trail_history`) che registra la posizione dello sprite "testa". Gli altri 7 sprite leggono lo stesso storico ma con un indice ritardato nel tempo, creando un movimento fluido a "serpente".
- **Raster Split**: L'interrupt divide lo schermo in tre zone logiche (Top, Middle, Bars) per permettere di avere il logo statico in alto e lo scroller in basso, gestendo indipendentemente modalità video e scroll hardware.
