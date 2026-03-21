; C64 Intro v0.1 (64tass)
; Build: make
; Load/run: SYS 2064

; --- Impostazioni di compilazione ---
CORRECT_LOGO_PRIORITY = 0 ; 1 = Corregge la priorità (logo monocolore), 0 = Look originale (priorità errata)

* = $0801

; BASIC loader: 10 SYS 2064
.word $080b       ; pointer to next BASIC line
.word 10          ; line number
.byte $9e         ; token for SYS
.text "2064"      ; SYS 2064
.byte 0
.word 0           ; end of BASIC program

* = $0810

    jmp start

USE_CHARSET = 1
LOGO_CHARSET_ADDR = $2800
LOGO_SCREEN_ADDR  = $0400

setup_logo:
    ; 1. Imposta i colori di sfondo (dallo screenshot)
    lda #0
    sta $d020
    sta $d021
    lda #15
    sta $d022
    lda #11
    sta $d023

    ; 2. Copia la mappa dello schermo
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

    ; 3. Pulizia parte bassa (HE GREET) con spazi
    lda #$20
    ldx #0
clean_lower_loop:
    sta LOGO_SCREEN_ADDR + 500,x
    sta LOGO_SCREEN_ADDR + 750,x
    inx
    cpx #250
    bne clean_lower_loop

    ; 4. Riempi Color RAM (Marrone $09)
    ldx #0
    lda #$09
fill_color_loop:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx
    bne fill_color_loop

    rts

start:
    jsr $e544      ; clear screen
    jsr init_colors
    jsr init_vic_bank
    .if USE_CHARSET
    jsr init_charset
    .endif
    ; Ordine importante:
    jsr init_screen
    jsr setup_logo     ; Disegna il logo SOPRA lo schermo pulito
    jsr init_scroller
    jsr init_irq
    jsr init_sprites
    jsr init_music

main_loop:
    ; Wait for V-blank (line 255) to avoid visual artifacts when moving screen memory
    lda #255
wait_vblank:
    cmp $d012
    bne wait_vblank

    jsr tick_scroller

wait_line_exit:
    ; Wait for raster to leave line 255 to ensure only 1 update per frame
    lda $d012
    cmp #255
    beq wait_line_exit
    jsr handle_runtime_keys
    jmp main_loop

; ------------------------------------------------------------
; Raster bars (IRQ-driven)
; ------------------------------------------------------------

; IRQ at Line 0: Prepare Top Screen & Music
irq_top:
    lda $d019
    sta $d019      ; ack raster IRQ

    ; --- ZONA LOGO (Top Screen) ---
    ; Charset Logo ($2800 -> $1A) + Multicolor ($18)
    lda #$1a
    sta $d018
.if CORRECT_LOGO_PRIORITY
    lda #$08       ; Multicolor OFF (priorità corretta), 40 Cols
.else
    lda #$18       ; Multicolor ON (look originale), 40 Cols
.endif
    sta $d016

    jsr music_tick ; Constant 50Hz music update
    jsr update_sprites
    
    ; Setup for Raster Bars
    lda #0
    sta bar_index

    ; Setup next IRQ for Split (enable scrolling before text)
    lda #146       ; Line 146 (Subito dopo il logo, prima dello scroller a 147)
    sta $d012
    lda #<irq_split
    sta $0314
    lda #>irq_split
    sta $0315
    jmp $ea81

irq_split:
    lda $d019
    sta $d019      ; ack raster IRQ

    ; --- ZONA SCROLLER/INTRO (Middle Screen) ---
    ; Charset Testo ($2000 -> $14)
    lda #$14
    sta $d018

    ; Enable Scroll for the middle section
    lda scroll_x
    and #7
    ora #$08
    sta $d016      ; Multicolor OFF (bit 4=0), Scroll attivo

    ; Continue to bars logic
    jmp next_bar_irq

irq_bars:
    lda $d019
    sta $d019

    ldx bar_index
    lda bar_colors,x
    sta $d021      ; background color

    inx
    cpx #BAR_COUNT
    bne store_bar
    ldx #0

store_bar:
    stx bar_index
    ; update bar position once per frame (when index wraps)
    cpx #0
    bne next_bar_irq

    jsr update_bar_phase

    ; Loop back to Top IRQ (Line 0)
    lda #0
    sta $d012
    lda #<irq_top
    sta $0314
    lda #>irq_top
    sta $0315
    jmp $ea81

next_bar_irq:
    ldx bar_index
    lda bar_lines,x
    clc
    adc bar_phase
    sta $d012
    
    lda #<irq_bars
    sta $0314
    lda #>irq_bars
    sta $0315

irq_done:
    jmp $ea81      ; exit via KERNAL IRQ tail (restores regs, RTI)

BAR_COUNT = 11

bar_lines:
    .byte 150,155,160,165,170,175,180,185,190,195,200

bar_colors:
    .byte 0,2,8,10,7,1,7,10,8,2,0

; ------------------------------------------------------------
; Scroller (line 24, 40 columns)
; ------------------------------------------------------------

SCROLL_LINE = $06d0  ; $0400 + (18*40) -> Riga 18 (Centrata nelle barre)
ZP_SCROLL = $60
ZP_SCROLL_SPEED_TABLE = $68
SCROLL_SPEED_TABLE_MASK = $3f
SCROLL_SPEED_MODE_DEFAULT = 0
SCROLL_SPEED_MODE_COUNT = 2

init_scroller:
    lda #<msg_scroll
    sta ZP_SCROLL
    lda #>msg_scroll
    sta ZP_SCROLL+1
    lda #7
    sta scroll_x
    lda #SCROLL_SPEED_MODE_DEFAULT
    sta scroll_speed_mode
    lda #0
    sta scroll_speed_idx
    sta scroll_accum
    jsr load_scroll_speed_mode
    jsr clear_scroll_line
    rts

tick_scroller:
    jsr update_scroll_speed

    ; Fractional speed accumulator:
    ; carry means "advance 1 pixel this frame"
    lda scroll_accum
    clc
    adc scroll_speed_cur
    sta scroll_accum
    bcc done_tick

    dec scroll_x
    bpl done_tick

    lda #7
    sta scroll_x
    jsr do_hard_scroll  ; Shift memory during V-Blank
done_tick:
    rts

update_scroll_speed:
    lda scroll_speed_idx
    clc
    adc #1
    and #SCROLL_SPEED_TABLE_MASK
    sta scroll_speed_idx
    tay
    lda (ZP_SCROLL_SPEED_TABLE),y
    sta scroll_speed_cur
    rts

load_scroll_speed_mode:
    ldx scroll_speed_mode
    lda scroll_table_ptr_lo,x
    sta ZP_SCROLL_SPEED_TABLE
    lda scroll_table_ptr_hi,x
    sta ZP_SCROLL_SPEED_TABLE+1

    ldy scroll_speed_idx
    lda (ZP_SCROLL_SPEED_TABLE),y
    sta scroll_speed_cur
    lda #0
    sta scroll_accum
    rts

do_hard_scroll:
    ; This is called from the main loop, not the IRQ.
    ; It's safe for it to take longer.
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
    sta $dad0,x     ; color RAM line 18 ($d800 + 18*40)
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

    ldx #$08      ; 8 pages * 256 = 2048 bytes (STOP PRIMA DI $2800 per salvare il logo!)
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
    jsr SID_PLAY
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

    lda #<irq_top
    sta $0314
    lda #>irq_top
    sta $0315

    lda #0
    sta bar_index
    sta bar_phase_idx
    lda #BAR_MOTION_PRESET_DEFAULT
    sta bar_motion_preset
    jsr load_bar_motion_preset
    lda #0         ; Start at line 0
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

scroll_x:
    .byte 7
scroll_speed_cur:
    .byte 224
scroll_accum:
    .byte 0
scroll_speed_idx:
    .byte 0
scroll_speed_mode:
    .byte 0

bar_index:
    .byte 0

bar_phase:
    .byte 0
bar_phase_idx:
    .byte 0
bar_phase_step_cur:
    .byte 1
bar_motion_preset:
    .byte 0

; ------------------------------------------------------------
; Raster movement (sinusoidal via lookup table)
; ------------------------------------------------------------

; Runtime preset (R to cycle):
; 0 = soft   (ampiezza ridotta, periodo normale)
; 1 = medium (ampiezza piena, periodo normale)
; 2 = wild   (ampiezza piena, periodo doppia velocita')
BAR_MOTION_PRESET_DEFAULT = 1
BAR_PRESET_COUNT = 3
BAR_PHASE_TABLE_MASK = $3f

ZP_BAR_TABLE = $66

update_bar_phase:
    lda bar_phase_idx
    clc
    adc bar_phase_step_cur
    sta bar_phase_idx
    lda bar_phase_idx
    and #BAR_PHASE_TABLE_MASK
    sta bar_phase_idx
    tay
    lda (ZP_BAR_TABLE),y
    sta bar_phase
    rts

load_bar_motion_preset:
    ldx bar_motion_preset
    lda bar_phase_step_lut,x
    sta bar_phase_step_cur
    lda bar_table_ptr_lo,x
    sta ZP_BAR_TABLE
    lda bar_table_ptr_hi,x
    sta ZP_BAR_TABLE+1

    ldy bar_phase_idx
    lda (ZP_BAR_TABLE),y
    sta bar_phase
    rts

handle_runtime_keys:
    jsr $ff9f      ; KERNAL SCNKEY: scan keyboard matrix now
    jsr $ffe4      ; KERNAL GETIN (0 if no key)
    beq key_done
    cmp #'R'
    beq cycle_preset
    cmp #'r'
    beq cycle_preset
    cmp #'S'
    beq cycle_scroll_mode
    cmp #'s'
    beq cycle_scroll_mode
    bne key_done

cycle_preset:
    inc bar_motion_preset
    lda bar_motion_preset
    cmp #BAR_PRESET_COUNT
    bcc apply_new_preset
    lda #0
    sta bar_motion_preset

apply_new_preset:
    jsr load_bar_motion_preset
    rts

cycle_scroll_mode:
    inc scroll_speed_mode
    lda scroll_speed_mode
    cmp #SCROLL_SPEED_MODE_COUNT
    bcc apply_new_scroll_mode
    lda #0
    sta scroll_speed_mode

apply_new_scroll_mode:
    jsr load_scroll_speed_mode
key_done:
    rts

bar_phase_step_lut:
    .byte 1,1,2

scroll_table_ptr_lo:
    .byte <scroll_speed_table_fixed, <scroll_speed_table_wave
scroll_table_ptr_hi:
    .byte >scroll_speed_table_fixed, >scroll_speed_table_wave

scroll_speed_table_fixed:
    .fill 64,224
scroll_speed_table_wave:
    .byte 152,163,174,185,195,205,214,223,231,239,245,251,252,252,252,252
    .byte 252,252,252,252,252,251,245,239,231,223,214,205,195,185,174,163
    .byte 152,141,130,119,109,99,90,81,73,65,59,53,49,45,42,41
    .byte 40,41,42,45,49,53,59,65,73,81,90,99,109,119,130,141

bar_table_ptr_lo:
    .byte <bar_phase_table_soft, <bar_phase_table_medium, <bar_phase_table_medium
bar_table_ptr_hi:
    .byte >bar_phase_table_soft, >bar_phase_table_medium, >bar_phase_table_medium

bar_phase_table_soft:
    .byte 20,22,23,25,26,28,29,30,31,32,33,34,35,35,36,36
    .byte 36,36,36,35,35,34,33,32,31,30,29,28,26,25,23,22
    .byte 20,18,17,15,14,12,11,10,9,8,7,6,5,5,4,4
    .byte 4,4,4,5,5,6,7,8,9,10,11,12,14,15,17,18

bar_phase_table_medium:
    .byte 20,22,24,26,28,29,31,33,34,35,37,38,38,39,40,40
    .byte 40,40,40,39,38,38,37,35,34,33,31,29,28,26,24,22
    .byte 20,18,16,14,12,11,9,7,6,5,3,2,2,1,0,0
    .byte 0,0,0,1,2,2,3,5,6,7,9,11,12,14,16,18

; ------------------------------------------------------------
; Sprites Logic
; ------------------------------------------------------------

SPRITE_DATA = $3000
SPRITE_PTR  = $07f8  ; Screen $0400 + $3f8 offset for Sprite 0

TRAIL_DELAY = 8       ; Delay in frames between trail segments. Aumentalo per più spazio.
TRAIL_BUFFER_SIZE = 64  ; Power of 2, deve essere >= 8 * TRAIL_DELAY
TRAIL_BUFFER_MASK = TRAIL_BUFFER_SIZE - 1

history_idx_zp = $fb  ; ZP temp variable for history index
msb_collect_zp = $fd  ; ZP temp for collecting MSB bits
prio_collect_zp = $fc ; ZP temp for collecting Priority bits

init_sprites:
    ; Enable all 8 Sprites
    lda #$ff
    sta $d015
    
    ; Set Sprite Priority to Background (Sprites go behind text pixels)
    sta $d01b

    ldx #7
init_spr_loop:
    ; Set Pointer to data block ($3000 / 64 = $C0)
    lda #$c0
    sta SPRITE_PTR,x
    ; Set Colors
    lda spr_colors,x
    sta $d027,x
    dex
    bpl init_spr_loop

    ; Init positions
    lda #100
    sta spr_x
    sta spr_y
    lda #0
    sta spr_z_depth

    ; Fill history buffers with start position to avoid artifacts
    ldx #TRAIL_BUFFER_SIZE - 1
fill_hist_loop:
    sta trail_history_x,x
    sta trail_history_y,x
    lda #0
    sta trail_history_x_msb,x  ; Fix missing MSB init
    sta trail_history_prio,x   ; Init priority to Front (0)
    dex
    bpl fill_hist_loop

    ; Initial sprite update to place them correctly, avoiding artifacts
    jsr update_sprites
    rts

update_sprites:
    ; --- Part 1: Update head sprite position (bouncing logic) ---
    ; Update X
    ; 16-bit signed addition: spr_x (16bit) = spr_x + spr_dx (8bit signed)
    lda spr_x
    clc
    adc spr_dx
    sta spr_x
    
    ; Handle Carry/Borrow for High Byte
    ldy spr_dx
    bpl dx_positive
    ; DX is negative
    bcs dx_done      ; If carry set, no borrow needed (e.g. 5 + (-1) = 4, C=1)
    dec spr_x_hi
    jmp dx_done
dx_positive:
    ; DX is positive
    bcc dx_done      ; If carry clear, no carry needed
    inc spr_x_hi
dx_done:

    ; Bounce X (Limits 24 - 320). Sprite width is 24px. Visible area ends at 343. 343-24=319.
    ; Right Limit Check (>= 320 = $0140)
    lda spr_x_hi
    cmp #1
    bcc check_left   ; If Hi < 1, not at right limit
    bne do_invert_x  ; If Hi > 1, definitely past right limit
    lda spr_x
    cmp #$40         ; Low byte check (320)
    bcs do_invert_x

check_left:
    ; Left Limit Check (< 24)
    lda spr_x_hi
    bne update_y     ; If Hi != 0, we are safe > 24
    lda spr_x
    cmp #24
    bcs update_y

do_invert_x:
    jmp invert_x

    ; (Jump target helper)
invert_x:
    ; Toggle Z-depth (priority) on wall bounce
    lda spr_z_depth
    eor #1
    sta spr_z_depth

    lda spr_dx
    eor #$ff     ; Negate direction
    clc
    adc #1
    sta spr_dx
    jmp update_y
update_y:
    ; Update Y
    lda spr_y
    clc
    adc spr_dy
    sta spr_y

    ; Bounce Y (Limits 50-229). Sprite height 21px. Visible area 50-249. 249-21=228.
    cmp #229
    bcs invert_y
    cmp #50
    bcc invert_y
    jmp store_head_pos
invert_y:
    lda spr_dy
    eor #$ff
    clc
    adc #1
    sta spr_dy

store_head_pos:
    ; --- Part 2: Store new head position in circular buffer ---
    ldy trail_history_ptr
    lda spr_x
    sta trail_history_x,y
    lda spr_x_hi
    sta trail_history_x_msb,y
    lda spr_z_depth
    sta trail_history_prio,y
    lda spr_y
    sta trail_history_y,y

    ; --- Part 3: Update all sprite VIC registers from history buffer ---
    ; Calculate history index for sprite 7: index = (ptr - 7*delay) & mask
    lda trail_history_ptr
    sec
    sbc #(7 * TRAIL_DELAY)
    and #TRAIL_BUFFER_MASK
    sta history_idx_zp

    lda #0
    sta msb_collect_zp
    sta prio_collect_zp

    ldx #14 ; VIC offset for sprite 7 (7*2)
update_vic_loop:
    ldy history_idx_zp
    lda trail_history_x,y
    sta $d000,x
    lda trail_history_y,y
    sta $d001,x

    ; Collect MSB (9th bit)
    lda trail_history_x_msb,y
    beq no_msb
    lda msb_table,x   ; Get bitmask for current sprite
    ora msb_collect_zp
    sta msb_collect_zp
no_msb:

    ; Collect Priority
    lda trail_history_prio,y
    beq no_prio
    lda msb_table,x   ; Get bitmask (reuse MSB table as it matches sprite bits)
    ora prio_collect_zp
    sta prio_collect_zp
no_prio:

    ; Update history index for next sprite in trail (N-1)
    lda history_idx_zp
    clc
    adc #TRAIL_DELAY
    and #TRAIL_BUFFER_MASK
    sta history_idx_zp

    dex
    dex
    bpl update_vic_loop

    lda msb_collect_zp
    sta $d010        ; Update MSB register
    lda prio_collect_zp
    sta $d01b        ; Update Priority register (0=Front, 1=Behind text)

    ; --- Part 4: Increment history pointer for next frame ---
    inc trail_history_ptr
    lda trail_history_ptr
    and #TRAIL_BUFFER_MASK
    sta trail_history_ptr
    rts

spr_x:  .byte 100
spr_x_hi: .byte 0
spr_z_depth: .byte 0
spr_y:  .byte 100
spr_dx: .byte 1
spr_dy: .byte 1

trail_history_ptr: .byte 0
trail_history_x:   .fill TRAIL_BUFFER_SIZE
trail_history_x_msb: .fill TRAIL_BUFFER_SIZE
trail_history_y:   .fill TRAIL_BUFFER_SIZE
trail_history_prio: .fill TRAIL_BUFFER_SIZE

msb_table:
    .byte 1,0, 2,0, 4,0, 8,0, 16,0, 32,0, 64,0, 128,0

spr_colors:
    .byte 1, 13, 7, 10, 8, 2, 9, 0 ; Palette: White -> Yellow/Red tones -> Dark

; ------------------------------------------------------------
; SID data (loaded at $1000)
; ------------------------------------------------------------

* = SID_LOAD
sid_data:
    .binary "sid_data.bin"
sid_data_end:

; ------------------------------------------------------------
; Sprite Data (Located at $3000)
; ------------------------------------------------------------
* = SPRITE_DATA
    ; Simple Ball Shape (24x21 pixels, single color)
    ; 3 bytes per row
    .byte 0,0,0, 0,60,0, 0,255,0, 1,255,128, 7,255,224, 15,255,240
    .byte 31,255,248, 31,255,248, 63,255,252, 63,255,252, 63,255,252, 31,255,248
    .byte 31,255,248, 15,255,240, 7,255,224, 1,255,128, 0,255,0, 0,60,0
    .byte 0,0,0, 0,0,0, 0,0,0  ; Padding

; ------------------------------------------------------------
; Logo Data (Appended at the end to avoid memory conflict)
; ------------------------------------------------------------
* = LOGO_CHARSET_ADDR
    .binary "logo_charset.bin"
* = $3c00
logo_screen_data:
    .binary "logo_screen.bin"

; ------------------------------------------------------------
; Scroll Text Data
; Spostato a $4000 per evitare sovrapposizioni con il codice/SID a $1000
; ------------------------------------------------------------
* = $4000
msg_scroll:
    .enc "screen"      ; Mappa automaticamente ASCII -> Screen Codes
    .text "   *** hello c64 world! ***   "
    .text "sono sid e circa 40 anni fa feci questo logo per il gruppo ics "
    .text "(italian cracking service) non so se abbiano mai saputo chi l'avesse "
    .text "disegnato. i miei amici rasterburner e the rock me lo commissionarono. "
    .text "da grande appassionato del nostro amato biscottone presi questo compito "
    .text "con grande abnegazione, avevo 17 anni nel 1989!!! fu il fantastico commodore 64 "
    .text "che mi introdusse all'informatica, la mia grande passione, che divenne poi "
    .text "lavoro. per anni mi dimenticai, per vari motivi, dell'amico c64, segregandolo "
    .text "in una cantina chiuso nella sua custodia originale. nel 2023 volli "
    .text "recuperarlo, e scoprii un mondo nascosto che lo manteneva in vita, una grande comunita' "
    .text "di appassionati, retro-maniaci nerd, come lo ero io... e lo sono ancora. "
    .text "ritrovai per caso il logo frugando su csdb.de, vidi che c'era la versione ics import "
    .text "del gioco ikari warrior ii, con mia grande sorpresa vidi il logo, e mi emozionai tantissimo, "
    .text "era proprio quello che avevo disegnato 35 anni fa!!! "
    .text "per rendere onore al momento entusiasmante, ho estratto il logo e ci ho costruito sopra questa intro senza pretese. "
    .text "spero vi piaccia, a me ha fatto tornare alla mente tanti ricordi bellissimi legati al mio amato c64, e alla mia passione per l'informatica. "
    .text "il progetto e' alla pagina https://github.com/quelo1972/c64-intro-1, se volete dare un'occhiata al codice sorgente, o contribuire con miglioramenti, siete i benvenuti! "
    .text "ho usato il c64tass cross-assembler per compilarlo, vscode (windows) e vscodium (linux) per editarlo...        "
    .text "e qualche aiutino da codex e gemini!!!"
    .byte 0
    .enc "petscii"

label_text:
    .enc "screen"
    .text "c64 intro - irg/scroller/charset  glyph: "
    .byte 0
    .enc "petscii"
