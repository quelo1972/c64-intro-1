; logo.asm
; Contiene i dati e la routine per visualizzare il logo estratto.

LOGO_CHARSET_ADDR = $2800
LOGO_SCREEN_ADDR  = $0400

show_logo:
    sei

    ; 1. Imposta i colori di sfondo per il multicolor (dallo screenshot)
    lda #0          ; Sfondo Nero
    sta $d021
    lda #15         ; Grigio Chiaro
    sta $d022
    lda #11         ; Grigio Scuro
    sta $d023
    lda #0          ; Bordo Nero
    sta $d020

    ; 2. Copia la mappa dello schermo in posizione
    ldx #0
copy_screen_loop:
    lda logo_screen_data,x
    sta LOGO_SCREEN_ADDR,x
    lda logo_screen_data+250,x
    sta LOGO_SCREEN_ADDR+250,x
    lda logo_screen_data+500,x
    sta LOGO_SCREEN_ADDR+500,x
    lda logo_screen_data+750,x
    sta LOGO_SCREEN_ADDR+750,x
    inx
    cpx #250
    bne copy_screen_loop

    ; 2b. FIX: Pulisci la metà inferiore dello schermo per nascondere "HE GREET"
    ; Preleviamo il carattere alla posizione 0,0 (offset 0) e lo usiamo come sfondo
    lda LOGO_SCREEN_ADDR
    ldx #0
clean_lower_loop:
    sta LOGO_SCREEN_ADDR + 500,x ; Pulisce da metà schermo in giù
    sta LOGO_SCREEN_ADDR + 750,x
    inx
    cpx #250
    bne clean_lower_loop

    ; 3. Riempi la Color RAM con il colore $09 (Marrone)
    ldx #0
    lda #$09
fill_color_loop:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx
    bne fill_color_loop

    ; 4. Imposta i puntatori e la modalità VIC con i valori trovati
    lda #$1a        ; Screen @ $0400, Charset @ $2800
    sta $d018
    lda #$18        ; Multicolor ON, 40 colonne
    sta $d016

    ; 5. Attendi la pressione di un tasto per continuare
    cli
wait_key:
    lda $c5         ; KERNAL: numero di tasti nel buffer
    beq wait_key    ; Loop finché non c'è un tasto
    jsr $f157       ; KERNAL: svuota il buffer della tastiera

    rts

; --- Dati del Logo ---
* = LOGO_CHARSET_ADDR
    .binary "logo_charset.bin"

* = $3c00 ; Mettiamo la mappa dello schermo qui, fuori dalla vista del VIC
logo_screen_data:
    .binary "logo_screen.bin"