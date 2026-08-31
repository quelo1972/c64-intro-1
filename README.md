# C64 Intro Starter

Intro per Commodore 64 con raster bars, scroller fluido, logo, sprite e musica SID.

La release corrente mantiene la scia di otto sprite all'interno dell'area del
logo, così non si sovrappone alla rasterbar. La barra usa un gradiente freddo
simmetrico (grigio scuro, blu, azzurro, ciano, bianco e ritorno).

## Requisiti
- `64tass` (cross-assembler)
- `VICE` (`x64`) per eseguire il PRG

Su Debian/Ubuntu di solito:
- `sudo apt install 64tass vice`

## Build
```sh
make
```

Il comando genera `build/Sometimes.prg`, cioè un PRG con il nome del SID
selezionato.

## Run
```sh
make run
```

## Sostituire la musica SID

Nel `Makefile` modifica soltanto il valore di `SID` con il percorso del nuovo
file `.sid`, quindi esegui `make run`:

```make
SID=Sometimes.sid
```

In alternativa puoi scegliere il file senza modificare il Makefile. Il PRG
generato usa automaticamente lo stesso nome del SID:

```sh
make run SID=Warriors.sid
# genera ed esegue build/Warriors.prg
```

Per compilare senza avviare VICE:

```sh
make SID=Human_Race.sid
# genera build/Human_Race.prg
```

### SID inclusi nel progetto

| File SID | PRG generato | Durata / riavvio |
|----------|--------------|------------------|
| `Sometimes.sid` | `build/Sometimes.prg` | 3:55 / 4:00 |
| `Warriors.sid` | `build/Warriors.prg` | loop interno (nessun riavvio esterno) |
| `Human_Race.sid` | `build/Human_Race.prg` | 2:44.554 / 2:49.554 |
| `Human_Raced.sid` | `build/Human_Raced.prg` | 2:52.323 / 2:57.323 |
| `Human_Race_Tango.sid` | `build/Human_Race_Tango.prg` | 2:26 / 2:31 |
| `Human_Race_Is_Dying_Out.sid` | `build/Human_Race_Is_Dying_Out.prg` | 2:08.281 / 2:13.281 |
| `Human_Race_Subtune_4_Cover.sid` | `build/Human_Race_Subtune_4_Cover.prg` | 2:34 / 2:39 |

Puoi usare allo stesso modo qualunque altro file `.sid`, anche indicando un
percorso esterno al repository: `make run SID=percorso/brano.sid`.

Durante la build il progetto legge l'header PSID, estrae automaticamente il
payload e usa gli indirizzi `load`, `init`, `play` e la song di default del
brano. `make run` controlla anche gli eventuali SID aggiuntivi dichiarati dal
file: abilita in VICE solo quelli il cui indirizzo è effettivamente referenziato
dal payload. Un file che dichiara SID extra ma usa solo `$D400` viene quindi
avviato come mono e riprodotto su entrambe le cuffie; un vero StereoSID/3SID
mantiene invece i canali sinistro e destro separati.

Sono supportati file PSID/RSID con routine di play richiamabile a 50 Hz; i
brani che richiedono un CIA timer vengono rifiutati con un messaggio chiaro. Su
C64 reale, un brano multi-SID richiede naturalmente l'hardware SID aggiuntivo
corrispondente.

Sono supportati payload SID caricati nelle aree `$1000-$27FF` e
`$A000-$B1FF`. Per i secondi il progetto mappa automaticamente la RAM sotto la
BASIC ROM mentre il player è in esecuzione.

I brani vengono reinizializzati cinque secondi dopo la loro durata misurata. Il
formato SID non contiene questa informazione: le durate dei SID inclusi sono
registrate in `tools/sid_lengths.json` (database HVSC, quando disponibile).
Per `Sometimes.sid` è stata impostata la durata verificata di 3:55.
Per un nuovo SID non presente nella tabella, specifica la durata in secondi:

```sh
make run SID=percorso/brano.sid SID_DURATION_SECONDS=172.3
```

Il valore viene convertito automaticamente in frame PAL e include i cinque
secondi di attesa prima del riavvio.

Se carichi il PRG manualmente in VICE:
- `LOAD"INTRO.PRG",8,1`
- `RUN`

## Note
- Il loader BASIC esegue `SYS 9984`, un bootstrap che avvia in modo pulito il
  codice principale a `$0810`.
- **Effetti Visivi**:
  - **Raster Bars**: Gradiente freddo a 11 cambi colore gestito via IRQ (linea 150+).
  - **Scroller**: Scorrimento fluido (hard+soft scroll) su riga 17 ($06A8).
  - **Logo**: Charset personalizzato ($5000) e mappa schermo ($7C00).
  - **Sprites**: 8 sprite con effetto scia (trail) che rimbalzano entro il logo ($7000).
- **Mappa Memoria**:
  | Indirizzo | Descrizione | Note |
  |-----------|-------------|------|
  | `$0801`   | BASIC Header | `SYS 9984` (bootstrap) |
  | `$2700`   | Bootstrap | Disattiva video, sprite e SID durante l'avvio |
  | `$0810`   | Main Code | Logica, IRQ |
  | `$1000-$27FF` | SID Music | Payload SID selezionato |
  | `$2800-$3FFF` | SID workspace | Area lasciata libera per i player SID |
  | `$4400`   | Logo screen | Schermo del logo (banca VIC 1) |
  | `$5000`   | Logo Charset | Grafica custom (Ripped) |
  | `$7000`   | Sprites | Dati sprite hardware |
  | `$7300`   | Sprite state | Variabili e storico della scia |
  | `$7C00`   | Logo Map | Mappa schermo logo |
  | `$8000`   | Scroller Text | Buffer testo |
  | `$8800`   | Text screen | Scroller e HUD (banca VIC 2) |
  | `$9000`   | Main Charset | Character ROM C64 standard |
  | `$A000-$B1FF` | SID Music | Area SID alternativa sotto BASIC ROM |
  | `$B200`   | Text-bank sprites | Copia sprite per la banca VIC 2 |

## Struttura dei File
- `intro.asm`: Il cuore del progetto (Sorgente Assembly).
- `tools/prepare_sid.py`: Estrae dati e indirizzi dal file SID scelto nel `Makefile`.
- `tools/sid_lengths.json`: Durate misurate dei SID inclusi, indicizzate per MD5.
- `build/sid_data.bin`: Payload musicale generato durante la build (senza header PSID).
- `build/<nome-sid>.prg`: PRG finale, nominato in base al SID selezionato.
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
  - Tasto `T`: alterna la visualizzazione tra il link GitHub e i dati di setup (`(r)mode`, `(s)mode` e `l(e)vel`). I tasti `R`, `S` ed `E` restano attivi in entrambe le visualizzazioni.

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

### Regolare la velocità degli Sprite (tasto E)
Il movimento degli sprite è controllato da un sistema di delay e da un "extra tick" per garantire fluidità anche a velocità elevate.

Parametri in `intro.asm`:
- `SPRITE_SPEED_MODE_DEFAULT`: Imposta il livello iniziale (`0`=Bassa, `1`=Media, `2`=Alta).
- `sprite_move_delay_lut`: Controlla quanti frame attendere prima di aggiornare la posizione:
  - `.byte 2` (Livello 1): Movimento ogni 3 update.
  - `.byte 1` (Livello 2): Movimento ogni 2 update.
  - `.byte 0` (Livello 3): Movimento a ogni update (Massima reattività).

Il tasto `E` cicla tra questi tre livelli, anche quando il Setup HUD è nascosto. L'indicatore `l(e)vel` mostra il valore corrente (1-3) quando il pannello è visibile.

#### Ottimizzazione del movimento
Per superare il limite di 1 pixel/frame senza scatti, la routine `maybe_extra_sprite_tick` esegue un aggiornamento supplementare della posizione ogni due frame, aumentando la velocità complessiva del 50% su tutti i livelli.

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

Il testo completo visualizzato dallo scroller (`msg_scroll` in `intro.asm`) è:

> premi (t) per attivare/disattivare il setup mode. *** hello c64 world! *** intro realizzata a marzo 2026 sono sid e circa 40 anni fa feci questo logo per il gruppo ics (italian cracking service) non so se abbiano mai saputo chi l'avesse disegnato. i miei amici rasterburner e the rock me lo commissionarono. da grande appassionato del nostro amato biscottone presi questo compito con grande abnegazione, avevo 17 anni nel 1989!!! fu il fantastico commodore 64 che mi introdusse all'informatica, la mia grande passione, che divenne poi lavoro. per anni mi dimenticai, per vari motivi, dell'amico c64, segregandolo in una cantina chiuso nella sua custodia originale. nel 2023 volli recuperarlo, e scoprii un mondo nascosto che lo manteneva in vita, una grande comunita' di appassionati, retro-maniaci nerd, come lo ero io... e lo sono ancora. ritrovai per caso il logo frugando su csdb.de, vidi che c'era la versione ics import del gioco ikari warrior ii, con mia grande sorpresa vidi il logo, e mi emozionai tantissimo, era proprio quello che avevo disegnato 37 anni fa!!! per rendere onore al momento entusiasmante, ho estratto il logo e ci ho costruito sopra questa intro senza pretese. spero vi piaccia, a me ha fatto tornare alla mente tanti ricordi bellissimi legati al mio amato c64, e alla mia passione per l'informatica. il progetto e' alla pagina https://github.com/quelo1972/c64-intro-1, se volete dare un'occhiata al codice sorgente, o contribuire con miglioramenti, siete i benvenuti! ho usato il c64tass cross-assembler per compilarlo, vscode (windows) e vscodium (linux) per editarlo... e qualche aiutino da codex e gemini!!!

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
