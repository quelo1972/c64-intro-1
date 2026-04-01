# Changelog

## [v1.2.0] - 2026-04-01
### Funzionalità
- **Sprite Animati (3 Frame)**: Implementata animazione pulsante con tre stadi (Piccolo, Medio, Grande) e sequenza "ping-pong".
- **Effetto Onda (Wave)**: Introdotto offset nell'animazione degli sprite della scia per un movimento coordinato ma sfalsato.
- **Priorità Sprite (Z-Depth)**: Stabilizzata la logica di passaggio automatico davanti/dietro al logo e allo scroller durante i rimbalzi.

## [v1.1.0] - 2026-03-28
### Funzionalità
- **Rilocazione Memoria**: Spostate le variabili degli sprite a `$3300` per evitare collisioni con la musica a `$1000`.
- **Fix Palette**: Ripristinata la sequenza corretta (Bianco, V.Chiaro, Giallo, Rosa, Arancio, Rosso, Marrone, Nero).

### Refactor & UX
- **HUD Debug 2.0**: Ristrutturato il footer su due righe: riga 23 (parametri) e riga 24 (URL GitHub 40 char).
- **Allineamento Scroller**: Spostato lo scroller alla riga 17 (`$06A8`) per il centraggio verticale.
- **Uniformità Estetica**: Tutte le modalità di movimento (`r=0,1,2`) ora condividono la stessa tabella sinusoidale (`medium`) per un'ampiezza costante di 32 pixel.
- **Motore Frazionario**: Implementato accumulatore a 16-bit per la fase delle barre. Questo permette alla modalità `r=0` di muoversi a 0.5 pixel/frame (1 step ogni 2 frame).

### Ottimizzazioni Tecniche
- **Sincronizzazione Audio**: Spostate le variabili in Zero Page dall'area `$FB-$FE` all'area `$70-$73` (safe zone).
- **Simmetria Oscillazione Barre**: Ricalcolate le tabelle sinusoidali per garantire un'oscillazione perfettamente simmetrica e fluida.
- **Timing IRQ**: Anticipato lo split dell'HUD alla riga raster 233 per prevenire glitch grafici causati dal DMA degli sprite che "rubano" cicli alla CPU.
- **Doppio Rimbalzo Barre Raster**: Eliminato l'effetto di "doppio rimbalzo" e asimmetria nell'oscillazione delle barre raster.

## [v1.0.4] - 2026-03-22
### Migliorie
- **Scroller `S` rifinito**: rimosso il profilo `subtle` perché troppo vicino a `fixed`; nuovo ciclo runtime `fixed -> balanced -> extreme -> pulse_max`.
- **Nuova modalità `pulse_max`**: aggiunta LUT dedicata (`scroll_speed_table_pulse_max`) con pulsazione più evidente e aggressiva.
- **HUD debug più chiaro**: etichette aggiornate da `pset`/`smode` a `debug (r)mode` e `(s)mode`.
- **Preset barre default**: `R` ora parte da modalità `0` (`soft`), in linea con `S` che parte da `0`.
- **Hint nello scroller**: aggiunto all'inizio del testo il messaggio `premi (d) per attivare/disattivare il debug mode.`

### Correzioni
- **Allineamento HUD**: aggiornati offset di scrittura dei valori numerici dopo il cambio etichette, evitando mismatch visuale.

### Documentazione
- **README aggiornato**: allineati controlli runtime (`R`/`S`/`D`), ordine modalità `S`, nuova `pulse_max` e naming HUD `(r)mode`/`(s)mode`.
- **README default preset**: corretto esempio `BAR_MOTION_PRESET_DEFAULT = 0`.

## [v1.0.3] - 2026-03-22
### Migliorie
- **Preset runtime raster bars**: cambio preset durante l'esecuzione via tastiera (`R`) senza usare `SPACE`.
- **Input più sicuro per intro attachate**: evitato conflitto con `SPACE`, spesso usato per avvio programma.
- **Scroller runtime mode**: aggiunto cambio modalità velocità con tasto `S` (`fixed`, `subtle`, `balanced`, `extreme`).
- **Scroller accel/decel dolce**: introdotto motore frazionario con LUT di velocità per variazione fluida della cadenza.
- **Preset scroller multipli**: aggiunti tre profili pulsanti con intensità crescente.
- **Debug runtime HUD (`D`)**: reintrodotto toggle debug con tasto `D`/`d` e overlay in basso con stato `pset` (preset barre) e `smode` (modalità scroller).
- **HUD stabile e leggibile**: aggiunto split raster dedicato a fine frame per disattivare il fine-scroll solo nella zona HUD, mantenendo testo fermo e charset corretto.

### Correzioni
- **Glitch al margine basso raster bars**: corretta la catena IRQ in prossimità del picco inferiore, eliminando lampeggi/corruzioni video quando l'oscillazione raggiunge il massimo.
- **Drop audio ai picchi**: risolto jitter di timing che poteva far perdere colpi al `music_tick` durante i frame critici.
- **HUD `smode`**: corretto offset di scrittura del valore runtime (digit update coerente con il tasto `S`).
- **Ultima riga scroller**: ridotto il picco della LUT `bar_phase_table_medium` (`40 -> 39`) per evitare deformazioni della scanline inferiore dei caratteri al massimo dell'oscillazione.

### Documentazione
- **README aggiornato**: aggiunte istruzioni per ciclo `S` a 4 modalità e parametri LUT scroller.
- **README controlli runtime**: documentati i tasti `R`/`S`/`D` e il raster split a 4 zone (Top, Middle, Bars, HUD).

## [v1.0.2] - 2026-03-21
### Documentazione
- **README migliorato**: spiegazione più precisa di cosa modificare in `intro.asm` per regolare la velocità della raster bar.
- **Palette colori documentate**: aggiunte istruzioni pratiche su `bar_colors`, `spr_colors` e registri VIC `$d022/$d023`.
- **Guida operativa velocità**: chiarito il ruolo di `BAR_MOTION_PRESET` e `BAR_PHASE_STEP` con esempio diretto.

## [v1.0.1] - 2026-03-21
### Documentazione
- **README aggiornato**: aggiunta guida pratica al tuning delle raster bars sinusoidali.
- **Parametri spiegati**: documentati `BAR_MOTION_PRESET`, `BAR_PHASE_STEP` e uso della `bar_phase_table`.
- **Workflow rapido**: aggiunti passaggi operativi per provare preset e velocità con `make`/`make run`.

## [v1.0] - 2026-03-21
### Funzionalità
- **Raster Bars Sinusoidali**: Sostituito il movimento lineare con una LUT (Look-Up Table) per ottenere rallentamento ai bordi e accelerazione verso il centro.
- **Preset Movimento Barre**: Aggiunti preset compile-time (`soft`, `medium`, `wild`) per regolare ampiezza e velocità dell'oscillazione.
- **Oscillazione Centrata**: Mantenuto il centro dell'oscillazione coerente con il layout esistente, preservando la leggibilità dello scroller.

### Migliorie
- **Stabilità Timing IRQ**: Aggiornamento fase barre lightweight tramite indice tabellare, senza calcolo trigonometrico runtime.
- **Correzione Testo Scroller**: Fix typo nel messaggio (`c6tass` -> `c64tass`).

### Tecnico
- Refactor della logica `update_bar_phase` con indice circolare mascherato (`$3f`) su tabella da 64 step.
- Inizializzazione fase in `init_irq` allineata ai valori LUT.

## [v0.1] - 2026-03-18
### Funzionalità
- **Intro Engine**: Struttura base con loop principale e gestione IRQ stabile.
- **Raster Split**: Gestione interrupt per dividere lo schermo in due zone grafiche (Multicolor in alto, Standard in basso).
- **Logo Ripped**: Integrazione del logo "SID" estratto, pulito (rimozione scritte originali) e visualizzato con charset dedicato a `$2800`.
- **Scroller**: Scorrimento testo fluido 1x1 su riga singola (centrato nelle barre) con font custom a `$2000`.
- **Raster Bars**: Effetto barre colorate "bouncing" sincronizzate con il raster (flicker-free).
- **Sprite Trail**: 8 sprite hardware con effetto "scia" (snake) e logica di rimbalzo sui bordi.
- **Musica**: Integrazione player SID (PSID) inizializzato all'avvio.

### Tecnico
- Makefile per build automatica con 64tass e run in VICE.
- Tool `view_logo.asm` incluso per analisi memoria e visualizzazione asset grafici.
- Organizzazione memoria ottimizzata per coesistenza di 2 charset e codice.
