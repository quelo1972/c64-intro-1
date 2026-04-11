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
  - **Scroller**: Scorrimento fluido (hard+soft scroll) su riga 17 ($06A8).
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
- **Velocità Scroller**:
  - Modalità runtime: tasto `S` durante l'intro (ciclo `fixed -> balanced -> extreme -> pulse_max`).
  - Default all'avvio: `SCROLL_SPEED_MODE_DEFAULT` nella sezione scroller di `intro.asm`.
- **Setup Runtime / Footer**:
  - Tasto `T`: alterna la visualizzazione tra il link GitHub e i dati di setup (`(r)mode`, `(s)mode` e `l(e)vel`).

### Modificare le palette colori
Per cambiare i colori in `intro.asm`, intervieni qui:

- **Palette Raster Bars**: etichetta `bar_colors`
  - Sequenza di 11 valori (0-15) usata dal gradiente delle barre.
- **Palette Sprite Trail**: etichetta `spr_colors`
  - Sequenza di 8 valori (0-15), un colore per ciascuno sprite della scia.
- **Palette Logo Multicolor (2 registri VIC)**: routine `setup_logo`
  - `$d022` = Multicolor 1
  - `$d023` = Multicolor 2

Mappa colori C64 (0-15):
- `0` nero, `1` bianco, `2` rosso, `3` ciano
- `4` viola, `5` verde, `6` blu, `7` giallo
- `8` arancio, `9` marrone, `10` rosa, `11` grigio scuro
- `12` grigio medio, `13` verde chiaro, `14` azzurro chiaro, `15` grigio chiaro

### Regolare il movimento delle Raster Bars sinusoidali
Il movimento verticale delle barre ora usa una **LUT** (Look-Up Table) per simulare una sinusoide: più lento ai bordi, più veloce verso il centro.

#### Modifica rapida (consigliata)
Apri `intro.asm`, sezione `Raster movement (sinusoidal via lookup table)`, e cambia il valore di `BAR_MOTION_PRESET_DEFAULT`:

```asm
BAR_MOTION_PRESET_DEFAULT = 0
```

Valori disponibili:
- `0` = `soft` -> movimento più dolce (ampiezza ridotta, velocità normale)
- `1` = `medium` -> movimento standard
- `2` = `wild` -> più veloce (fase a doppio passo)

Nel codice attuale il default è `0` (`soft`), quindi `R` parte dalla modalità base come `S`.

Durante l'esecuzione puoi cambiare preset al volo con il tasto `R` (ciclo `soft -> medium -> wild`).

Poi ricompila:

```sh
make
make run
```

#### Cosa controlla la velocità reale
La velocità verticale è determinata da `BAR_PHASE_STEP`:
- `BAR_PHASE_STEP = 1` -> velocità normale
- `BAR_PHASE_STEP = 2` -> circa 2x più veloce

Nel codice attuale `BAR_PHASE_STEP` viene scelto automaticamente in base al preset runtime tramite:

```asm
bar_phase_step_lut:
    .byte 1,1,2
```

Se vuoi una velocità personalizzata, modifica la LUT degli step (esempio: `.byte 1,2,2` per avere `medium` e `wild` più veloci).

Nota: l'ampiezza dell'oscillazione dipende dalla `bar_phase_table`; la velocità dipende da `BAR_PHASE_STEP`.

### Regolare la velocità dello Scroller (tasto S)
Lo scroller supporta quattro modalità runtime, selezionabili con `S`:
- `fixed`: velocità costante (comportamento classico)
- `balanced`: pulsazione intermedia
- `extreme`: pulsazione forte
- `pulse_max`: pulsazione molto marcata

Parametri principali in `intro.asm`:
- `SCROLL_SPEED_MODE_DEFAULT`
  - `0` = `fixed`
  - `1` = `balanced`
  - `2` = `extreme`
  - `3` = `pulse_max`
- `scroll_speed_table_fixed`
  - Tabella LUT con velocità fissa (`.fill 64,224`)
- `scroll_speed_table_balanced` / `scroll_speed_table_extreme` / `scroll_speed_table_pulse_max`
  - Tabelle LUT con intensità pulsante crescente

Come funziona:
- Lo scroller non avanza ogni frame in modo rigido.
- A ogni frame legge una velocità dalla LUT (`scroll_speed_cur`).
- La velocità alimenta un accumulatore frazionario (`scroll_accum`).
- Quando l'accumulatore produce carry, lo scroller avanza di 1 pixel.
- Risultato: in modalità pulsanti il testo accelera e rallenta in modo morbido.

### Controlli Runtime Rapidi
- `R`: cambia velocità movimento raster bars (`super-lenta -> lenta -> veloce`)
- `S`: cambia modalità velocità scroller (`fixed -> balanced -> extreme -> pulse_max`)
- `E`: cambia velocità movimento sprite (`bassa -> media -> alta`)
- `T`: toggle Footer/Setup (`URL GitHub` <-> `Setup Mode`)

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
- **Raster Split**: L'interrupt divide lo schermo in quattro zone logiche (Top, Middle, Bars, HUD). La zona HUD usa uno split raster dedicato a fine frame per disattivare il fine-scroll orizzontale e mantenere il testo di setup stabile e leggibile.
