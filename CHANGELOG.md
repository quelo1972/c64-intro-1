# Changelog

## [v1.3.5] - 2026-09-01
### Correzioni
- **Ciclo SID affidabile**: il contesto zero-page del player viene ripristinato
  prima di ogni reinizializzazione, consentendo a `Human_Raced.sid` e
  `Sometimes.sid` di ripartire correttamente con il ciclo gestito dall'intro.
- **Loop interni rispettati**: `Warriors.sid`, `Human_Race.sid`,
  `Human_Race_Tango.sid`, `Human_Race_Is_Dying_Out.sid` e
  `Human_Race_Subtune_4_Cover.sid` non vengono più reinizializzati
  artificialmente, perché dispongono già di un loop interno pulito.
- **Compatibilità payload SID estesi**: spostata la routine di copia del logo
  fuori dall'area `$1000-$27ff`, evitando sovrapposizioni con SID come
  `Human_Race_Is_Dying_Out.sid`.

## [v1.3.4] - 2026-08-31
### Correzioni
- **Scia sprite confinata al logo**: gli otto sprite rimbalzano entro l'area
  del logo e non attraversano più la rasterbar, preservando la stabilità
  dell'intro completa (logo, scroller e musica).
- **Avvio pulito**: aggiunto un bootstrap separato che disattiva video,
  sprite e audio prima dell'inizializzazione, evitando il lampo iniziale di
  caratteri non inizializzati.
- **Loop di Warriors.sid**: riconosciuto il loop interno del brano e rimosso
  il riavvio esterno che ne causava una doppia ripartenza.

### Controlli
- **R, S ed E sempre attivi**: i controlli di rasterbar, scroller e velocità
  sprite non dipendono più dalla visualizzazione del pannello Setup (`T`).

### Grafica
- **Gradiente rasterbar freddo**: aggiornata la palette con una sequenza
  simmetrica grigio scuro, blu, azzurro, ciano e bianco.

### Manutenzione
- **Progetto ripulito**: rimossi i laboratori e i PRG sperimentali; `make`
  genera nuovamente soltanto la release principale `build/Sometimes.prg`.

## [v1.3.3] - 2026-08-24
### Funzionalità
- **PRG nominato in base al SID**: `make SID=brano.sid` e
  `make run SID=brano.sid` generano ora `build/brano.prg`, consentendo di
  conservare build distinte per ciascuna chip tune.

### Documentazione
- **Catalogo SID disponibili**: il README elenca tutti i file `.sid` inclusi
  nel progetto, il rispettivo nome del PRG e gli esempi di compilazione e avvio.

### Correzioni
- **Rilevamento SID extra inattivi**: il preparatore non abilita più in VICE
  chip dichiarati nell'header ma non referenziati dal payload; i brani mono
  vengono quindi riprodotti correttamente su entrambe le cuffie.
- **Loop SID con durata misurata**: eliminato il rilevamento del silenzio, che
  poteva confondere pause musicali con la fine del brano. Il preparatore usa
  ora una durata per SID/subtune e programma il riavvio cinque secondi dopo la
  fine; per nuovi file è disponibile l'override `SID_DURATION_SECONDS`. Per
  `Sometimes.sid` il ciclo è impostato a 4:00 (3:55 di musica + 5 secondi).
- **Payload SID sotto BASIC ROM**: supportati i brani caricati a
  `$A000-$B1FF`, con mapping temporaneo della RAM e sprite della banca testo
  spostati a `$B200`.

## [v1.3.2] - 2026-08-21
### Correzioni
- **Loop SID configurabile**: i player che concludono il brano in dissolvenza
  vengono reinizializzati ogni 240 secondi, mantenendo la musica in esecuzione.

## [v1.3.1] - 2026-08-21

## [v1.3.0] - 2026-08-21
### Funzionalità
- **SID selezionabile da Makefile**: la variabile `SID` identifica il file da
  includere. È possibile usare anche `make run SID=percorso/brano.sid` senza
  modificare i sorgenti.
- **Preparazione PSID automatica**: `tools/prepare_sid.py` legge l'header,
  estrae il payload e configura automaticamente indirizzi `load`, `init`,
  `play` e brano di default.
- **Supporto StereoSID/3SID in VICE**: `make run` rileva gli SID aggiuntivi
  dichiarati nel file e avvia VICE con i rispettivi indirizzi, preservando
  l'uscita stereo.

### Correzioni
- **Isolamento memoria SID/video**: logo, sprite, scroller e HUD sono stati
  separati dalle aree usate dai player SID; lo stato zero-page condiviso viene
  salvato e ripristinato attorno alle chiamate al player.
- **Charset standard per testo e HUD**: rimosso il copia-in-RAM del charset
  ROM (che differiva solo per un glifo). Scroller e menu ora usano direttamente
  il charset ROM C64 nella banca VIC 2, evitando corruzioni causate dai player.
- **Doppia banca sprite**: i dati sprite vengono duplicati nella banca del
  testo per mantenerli corretti durante gli split raster tra logo e scroller.

### Documentazione
- **README aggiornato**: aggiunte istruzioni per la sostituzione della musica,
  requisiti multi-SID e nuova mappa memoria.

## [v1.2.2] - 2026-04-11
### Aggiunte
- **Velocità Sprite Runtime**: Implementato il cambio di velocità per il movimento degli sprite tramite il tasto `E`. Supporta 3 livelli di reattività (Bassa, Media, Alta).
- **Integrazione HUD**: Aggiunto l'indicatore `l(e)vel` nel pannello di Setup per monitorare e cambiare la velocità degli sprite in tempo reale.

## [v1.2.1] - 2026-04-03
### Refactor & UX
- **Setup Mode consolidato**: La vecchia terminologia "debug" e' stata rimossa dal codice e dall'HUD in favore di `Setup Mode`, piu' coerente con la funzione runtime reale.
- **Toggle `T`**: Il pannello Setup ora si attiva con il tasto `T`/`t` al posto di `D`/`d`.
- **Scroller e documentazione allineati**: aggiornati hint nel testo scorrevole, `README.md` e riferimenti operativi al nuovo naming.

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

## [v1.0.6] - 2026-03-24
### Funzionalità
- **Footer Informativo Condiviso**: L'ultima riga dello schermo ora mostra il link completo al repository GitHub (Giallo) quando il menu info è disattivato.
- **Modalità Setup**: Rinominata la vecchia "Debug Mode" in "Setup Mode" per riflettere le funzionalità interattive utente.
- **Toggle 'D'**: Il tasto `D` ora agisce come switch tra il Footer GitHub e i valori di Setup ((r)mode, (s)mode).
- **Layout**: Ottimizzata la centratura delle etichette e utilizzato l'intero width (40 colonne) per l'URL.

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
