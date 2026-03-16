; C64 Intro Starter (64tass)
; Build: make
; Load/run: SYS 2064

* = $0801

; BASIC loader: 10 SYS 2064
.word $080b       ; pointer to next BASIC line
.word 10          ; line number
.byte $9e         ; token for SYS
.text "2064"      ; SYS 2064
.byte 0
.word 0           ; end of BASIC program

* = $0810

USE_CHARSET = 1

start:
    jsr $e544      ; clear screen
    jsr init_colors
    jsr init_vic_bank
    .if USE_CHARSET
    jsr init_charset
    .endif
    jsr init_screen
    jsr init_scroller
    jsr init_irq
    jsr init_music

main_loop:
    jsr wait_frame
    jsr music_tick
    jsr scroller_tick
    jmp main_loop

; simple busy-wait delay
; tune the constants to change speed

delay:
    ldy #0
outer:
    ldx #0
inner:
    dex
    bne inner
    iny
    bne outer
    rts

; ------------------------------------------------------------
; Raster bars (IRQ-driven)
; ------------------------------------------------------------

irq_handler:
    lda $d019
    sta $d019      ; ack raster IRQ

    ldx bar_index
    lda bar_colors,x
    sta $d021      ; background color

    inx
    cpx #BAR_COUNT
    bne store_bar
    ldx #0

store_bar:
    stx bar_index

    ; set next raster line
    lda bar_lines,x
    sta $d012

irq_done:
    jmp $ea81      ; exit via KERNAL IRQ tail (restores regs, RTI)

BAR_COUNT = 8

bar_lines:
    .byte 50,60,70,80,90,100,110,120

bar_colors:
    .byte 6,14,3,1,3,14,6,0

; ------------------------------------------------------------
; Scroller (line 24, 40 columns)
; ------------------------------------------------------------

SCROLL_LINE = $07c0  ; $0400 + (24*40)
ZP_SCROLL = $60

init_scroller:
    lda #<msg_scroll
    sta ZP_SCROLL
    lda #>msg_scroll
    sta ZP_SCROLL+1
    lda #4
    sta scroll_delay
    jsr clear_scroll_line
    rts

scroller_tick:
    lda scroll_delay
    beq do_scroll
    dec scroll_delay
    rts

do_scroll:
    lda #4
    sta scroll_delay

    ; shift 39 chars left
    ldx #0
shift_loop:
    lda SCROLL_LINE+1,x
    sta SCROLL_LINE,x
    inx
    cpx #39
    bne shift_loop

    ; add next char at rightmost
    ldy #0
    lda (ZP_SCROLL),y
    bne write_char
    lda #<msg_scroll
    sta ZP_SCROLL
    lda #>msg_scroll
    sta ZP_SCROLL+1
    lda (ZP_SCROLL),y

write_char:
    sta SCROLL_LINE+39
    inc ZP_SCROLL
    bne done_scroll
    inc ZP_SCROLL+1
done_scroll:
    rts

clear_scroll_line:
    ldx #0
    lda #$20        ; space
clear_chars:
    sta SCROLL_LINE,x
    inx
    cpx #40
    bne clear_chars

    ldx #0
    lda #1          ; white
clear_colors:
    sta $dbc0,x     ; color RAM line 24
    inx
    cpx #40
    bne clear_colors
    rts

; ------------------------------------------------------------
; Screen init: fill color RAM and write a top line label
; ------------------------------------------------------------

init_screen:
    ldx #0
    lda #$20
fill_screen:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $06e8,x
    inx
    bne fill_screen

    ldx #0
    lda #1
fill_color:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx
    bne fill_color

    ldx #0
label_loop:
    lda label_text,x
    beq label_done
    sta $0400,x
    inx
    bne label_loop
label_done:
    rts

; ------------------------------------------------------------
; Charset: copy ROM to $2000 and tweak a glyph
; ------------------------------------------------------------

CHARSET_ADDR = $2000
ZP_SRC = $62
ZP_DST = $64

init_charset:
    sei
    lda #<$d000
    sta ZP_SRC
    lda #>$d000
    sta ZP_SRC+1
    lda #<CHARSET_ADDR
    sta ZP_DST
    lda #>CHARSET_ADDR
    sta ZP_DST+1

    lda $01
    sta old_mem
    lda #$35
    sta $01       ; map CHARGEN at $D000, I/O off

    ldx #$10      ; 16 pages * 256 = 4096 bytes
copy_page:
    ldy #0
copy_loop:
    lda (ZP_SRC),y
    sta (ZP_DST),y
    iny
    bne copy_loop
    inc ZP_SRC+1
    inc ZP_DST+1
    dex
    bne copy_page

    lda old_mem
    sta $01       ; restore memory config

    ; tweak glyph for screen code 1 ('A')
    ldy #7
glyph_copy:
    lda glyph_A,y
    sta CHARSET_ADDR+8,y
    dey
    bpl glyph_copy

    lda #$14
    sta $d018     ; screen $0400, charset $2000
    cli
    rts

glyph_A:
    .byte %00011000
    .byte %00100100
    .byte %01000010
    .byte %01111110
    .byte %01000010
    .byte %01000010
    .byte %01000010
    .byte %00000000

old_mem:
    .byte 0

; ------------------------------------------------------------
; SID music (PSID player)
; ------------------------------------------------------------

SID_LOAD = $1000
SID_INIT = $1000
SID_PLAY = $1003
SID_SONG = 0

init_music:
    lda #15
    sta $d418      ; volume max
    lda #SID_SONG
    ldx #0
    ldy #0
    jsr SID_INIT
    rts

music_tick:
    lda music_div_ctr
    cmp #3
    bcc do_play
    jmp skip_play
do_play:
    jsr SID_PLAY
skip_play:
    inc music_div_ctr
    lda music_div_ctr
    cmp #5
    bne done_music
    lda #0
    sta music_div_ctr
done_music:
    rts

; ------------------------------------------------------------
; Init helpers and data
; ------------------------------------------------------------

init_colors:
    lda #6
    sta $d020      ; border color
    lda #0
    sta $d021      ; background color
    rts

init_vic_bank:
    lda $dd00
    and #%11111100
    ora #%00000011  ; bank 0 ($0000-$3fff)
    sta $dd00
    rts

init_irq:
    sei
    lda #$1b
    sta $d011      ; screen on, 25 rows, raster hi = 0
    lda #$08
    sta $d016      ; 40 columns, no scroll
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d

    lda #<irq_handler
    sta $0314
    lda #>irq_handler
    sta $0315

    lda #0
    sta bar_index
    lda bar_lines
    sta $d012
    lda $d011
    and #%01111111
    sta $d011

    lda #%00000001
    sta $d01a      ; enable raster IRQ
    lda #%00000001
    sta $d019      ; ack any pending
    cli
    rts

scroll_delay:
    .byte 4

bar_index:
    .byte 0

msg_scroll:
    .text "  --- C64 INTRO: RASTER + SCROLLER + SID ---   "
    .text "CUSTOM GLYPH: "
    .byte 1
    .text "   "
    .text "CODED WITH 64TASS   "
    .text "PRESS RUN/STOP TO QUIT   "
    .byte 0

label_text:
    .text "C64 INTRO - IRQ/SCROLLER/CHARSET  GLYPH: "
    .byte 1
    .byte 0


; ------------------------------------------------------------
; SID data (loaded at $1000)
; ------------------------------------------------------------

* = SID_LOAD
sid_data:
    .binary "sid_data.bin"
sid_data_end:
wait_frame:
    lda #0
wait_line0:
    cmp $d012
    bne wait_line0
wait_line0b:
    cmp $d012
    beq wait_line0b
    rts
music_div_ctr:
    .byte 0
