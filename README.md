# C64 Intro - Release v0.1

Una intro "old-school" per Commodore 64 scritta in Assembly 6502.
Questa release combina diverse tecniche classiche della demoscene: raster bars, sprite multiplexing/trails, scroller orizzontale e split dello schermo per visualizzare modalità grafiche miste.

## Funzionalità Principali

*   **Raster Split (IRQ Split):**
    *   **Top Screen:** Modalità *Multicolor Text* per il logo.
    *   **Bottom Screen:** Modalità *Standard Text* (Hires) per lo scroller.
    *   Gestione precisa tramite interrupt raster per cambiare puntatori al Charset e registri VIC ($D016, $D018) a metà quadro.
*   **Logo Ripped & Restored:**
    *   Logo "SID" estratto dalla memoria e pulito (rimozione artefatti originali).
    *   Charset dedicato posizionato a `$2800`.
*   **Scroller Orizzontale:**
    *   Scroller 1x1 fluido a 50Hz.
    *   Posizionato strategicamente tra le raster bars.
    *   Utilizza un Charset custom copiato dalla ROM e modificato in RAM (`$2000`).
*   **Raster Bars:**
    *   Barre colorate animate che rimbalzano verticalmente.
    *   Sincronizzate via IRQ per stabilità perfetta (nessun flickering).
*   **Sprite Trail:**
    *   8 Sprite hardware utilizzati per creare un effetto "scia" (snake/trail).
    *   Movimento fluido con logica di rimbalzo (bouncing) sui bordi dello schermo.
    *   Palette colori "fuoco" (Bianco -> Giallo -> Rosso -> Scuro).
*   **Musica SID:**
    *   Player PSID integrato e inizializzato all'avvio.

## Mappa della Memoria

| Indirizzo | Contenuto | Descrizione |
|-----------|-----------|-------------|
| `$0801` | Basic Stub | `10 SYS 2064` per l'avvio automatico. |
| `$0810` | Codice | Logica principale, IRQ handlers, setup. |
| `$1000` | SID Player | Codice e dati della musica. |
| `$2000` | Charset (Text) | Copia della ROM Character set per lo scroller. |
| `$2800` | Charset (Logo) | Font Multicolor estratto per il logo in alto. |
| `$3000` | Sprite Data | Forme degli sprite. |
| `$3C00` | Logo Map | Dati grezzi della mappa schermo del logo (buffer). |
| `$0400` | Screen RAM | Memoria video attiva (condivisa tra Logo e Scroller). |

## Requisiti

- `64tass` (cross-assembler)
- `VICE` (`x64`) per eseguire il PRG
- `Make` (opzionale, per il build system)

Su Debian/Ubuntu:
```bash
sudo apt install 64tass vice
```

## Build
Per compilare il progetto e generare `intro.prg`:
```bash
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
