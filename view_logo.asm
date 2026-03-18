; C64 Logo Viewer
; VERSIONE STABILE (Checkpoint)
; Build: 64tass -a view_logo.asm -o view_logo.prg
; Run: SYS 2064
;
; CONTROLLI:
; SPACE = Cambia indirizzo Charset (cicla $D018)
; M     = Toggle Multicolor Mode
; P     = Cambia colore caratteri (Color RAM)
; C     = Cambia colore sfondo/bordo
; I     = INFO SCREEN (Mostra valori attuali)

* = $0801
.word $080b, 10
.byte $9e
.text "2064"
.byte 0, 0, 0

* = $0810

start:
    sei

    ; 1. Inizializza Colori
    lda #0
    sta $d020
    sta $d021
    lda #15        ; Light Grey ($0F) - Colore sfondo extra 1
    sta $d022
    lda #11        ; Dark Grey ($0B)  - Colore sfondo extra 2
    sta $d023

    ; 2. VIC Bank 1 ($4000-$7FFF)
    lda $dd00
    and #%11111100
    ora #%00000010 
    sta $dd00

    ; 3. Default Pointers
    ; Screen $0400 (relative), Charset $2000 (relative) -> $18
    lda #$18
    sta current_d018
    sta $d018

    ; 4. Default Mode (Hires, 40 cols)
    lda #$08
    sta current_d016
    sta $d016

    ; 5. Default Color RAM: 1 (Bianco - semplice per iniziare)
    lda #1
    sta current_color
    jsr fill_color_ram

    ; --- FIX: Cancellazione forzata metà inferiore schermo (HE GREET) ---
    ; Scriviamo spazi ($20) a partire da metà schermo ($4400 + 500)
    lda #$20
    ldx #0
clean_loop:
    sta $4400+500,x
    sta $4400+750,x
    inx
    cpx #250
    bne clean_loop

    cli
mainloop:
    jsr check_keys
    jsr wait_vblank
    jmp mainloop

wait_vblank:
    lda $d012
    cmp #250
    bne wait_vblank
    rts

fill_color_ram:
    ldx #0
    lda current_color
c_loop:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx
    bne c_loop
    rts

check_keys:
    ; --- Check 'I' (Info Toggle) ---
    lda #$EF       ; Row 4
    sta $dc00
    lda $dc01
    and #$02       ; Col 1 (I)
    bne i_up
    
    lda key_lock_i
    beq do_i
    jmp check_space ; Skip se tasto già premuto
do_i:
    inc key_lock_i
    jsr toggle_info
    jmp key_done    ; Salta gli altri tasti
i_up:
    lda #0
    sta key_lock_i

check_space:
    lda info_mode
    beq do_check_space
    jmp key_done   ; Se siamo in Info Mode, ignora gli altri tasti
do_check_space:
    ; --- Check SPACE (Charset Cycle) ---
    lda #$7f       ; Row 7
    sta $dc00
    lda $dc01
    and #$10       ; Col 4 (Space)
    bne space_up
    
    lda key_lock_space
    beq do_space   ; Se premuto e non lockato, esegui
    jmp key_done
do_space:
    inc key_lock_space
    
    ; Cicla Charset (Bits 1-3 di D018)
    ; Mantiene Screen (Bits 4-7) fisso a quello che è impostato ($1x)
    lda current_d018
    clc
    adc #$02
    and #$0E        ; Tieni solo bits 1-3 (0000xxx0)
    ora #$10        ; Rimetti Screen a $0400 relative ($1xxx)
    sta current_d018
    sta $d018
    jmp key_done
space_up:
    lda #0
    sta key_lock_space

    ; --- Check 'M' (Multicolor Toggle) ---
    lda #$EF       ; Row 4
    sta $dc00
    lda $dc01
    and #$10       ; Col 4 (M)
    bne m_up
    
    lda key_lock_m
    beq do_m       ; Logica di salto sicura
    jmp key_done
do_m:
    inc key_lock_m
    
    lda current_d016
    eor #$10       ; Toggle bit 4
    sta current_d016
    sta $d016
    jmp key_done
m_up:
    lda #0
    sta key_lock_m

    ; --- Check 'P' (Paint Color) ---
    lda #$DF       ; Row 5
    sta $dc00
    lda $dc01
    and #$02       ; Col 1 (P)
    bne p_up
    
    lda key_lock_p
    beq do_p
    jmp key_done
do_p:
    inc key_lock_p

    inc current_color
    lda current_color
    and #$0F       ; Wrap 0-15
    sta current_color
    jsr fill_color_ram
    jmp key_done
p_up:
    lda #0
    sta key_lock_p

    ; --- Check 'C' (Color Bg) ---
    lda #$FB       ; Row 2
    sta $dc00
    lda $dc01
    and #$02       ; Col 1 (C)
    bne c_up
    
    lda key_lock_c
    beq do_c
    jmp key_done
do_c:
    inc key_lock_c
    inc $d021
    inc $d020
    jmp key_done
c_up:
    lda #0
    sta key_lock_c

key_done:
    rts

; --- Routine Info Screen ---
toggle_info:
    lda info_mode
    eor #1
    sta info_mode
    beq restore_view

    ; ATTIVA INFO VIEW
    ; 1. Seleziona Bank 0 ($0000-$3FFF) per vedere il charset ROM e Screen RAM standard
    lda $dd00
    ora #%00000011
    sta $dd00
    
    ; 2. Imposta modalità testo standard
    lda #$14       ; Screen $0400, Charset $1000 (ROM Lowercase)
    sta $d018
    lda #$08       ; 40 Colonne, Multicolor OFF
    sta $d016
    
    jsr clear_screen
    jsr print_status
    rts

restore_view:
    ; RIPRISTINA LOGO VIEW
    ; 1. Seleziona Bank 1 ($4000-$7FFF) dove c'è il dump
    lda $dd00
    and #%11111100
    ora #%00000010 
    sta $dd00
    
    ; 2. Ripristina registri salvati
    lda current_d018
    sta $d018
    lda current_d016
    sta $d016
    
    ; 3. Ripristina colori (necessario perché clear_screen li ha cancellati)
    jsr fill_color_ram
    rts

print_status:
    ldx #0
pr_loop:
    lda txt_info,x
    beq pr_vals
    sta $0400,x    ; Scrive in Screen RAM
    lda #1         ; Colore Bianco
    sta $d800,x
    inx
    bne pr_loop
pr_vals:
    ; Stampa D018
    lda current_d018
    ldx #5
    jsr print_hex
    ; Stampa D016
    lda current_d016
    ldx #13
    jsr print_hex
    ; Stampa COL
    lda current_color
    ldx #22
    jsr print_hex
    rts

print_hex:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr hex_digit
    sta $0400,x
    inx
    pla
    and #$0F
    jsr hex_digit
    sta $0400,x
    rts

hex_digit:
    cmp #10
    bcc is_num
    sbc #9         ; 10->1 (A), 15->6 (F). Carry è 1 dal cmp
    rts
is_num:
    adc #$30       ; 0-9. Carry è 0 dal bcc
    rts

clear_screen:
    ldx #0
    lda #$20       ; Spazio
cl_loop:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $06e8,x
    inx
    bne cl_loop
    rts

; --- Variabili ---
txt_info:       .enc "screen"
                .text "d018:   d016:    col:   "
                .byte 0
current_d018:   .byte $18
current_d016:   .byte $08
current_color:  .byte $01
info_mode:      .byte 0
key_lock_space: .byte 0
key_lock_m:     .byte 0
key_lock_p:     .byte 0
key_lock_c:     .byte 0
key_lock_i:     .byte 0

* = $4000
    .binary "bank0.bin"