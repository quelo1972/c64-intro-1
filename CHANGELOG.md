# Changelog

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
