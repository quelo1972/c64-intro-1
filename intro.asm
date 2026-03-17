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
    jsr init_sprites
    jsr init_music

main_loop:
    ; Wait for V-blank (line 255) to avoid visual artifacts when moving screen memory
    lda #255
wait_vblank:
    cmp $d012
    bne wait_vblank

    lda hard_scroll_flag
    beq main_loop
    jsr do_hard_scroll
    jmp main_loop

; ------------------------------------------------------------
; Raster bars (IRQ-driven)
; ------------------------------------------------------------

; IRQ at Line 0: Prepare Top Screen & Music
irq_top:
    lda $d019
    sta $d019      ; ack raster IRQ

    lda #$c8       ; 40 cols, normal scroll (bits 0-2=0, bit 3=1) -> actually scroll=0 is shifted. 
                   ; Let's use $C8 = 11001000. Bit 3=1 (40col). Scroll=0.
                   ; Standard C64 text is scroll 7 ($CF). Let's use $C8 to match original look or $CF?
                   ; Original code had $08 (0000 1000). 40cols, scroll 0.
                   ; To keep top stable, we enforce $C8 (Screen on, 40 cols).
    sta $d016

    jsr music_tick ; Constant 50Hz music update
    jsr update_sprites
    
    ; Setup for Raster Bars
    lda #0
    sta bar_index
    ; Fall through to bar logic setup...
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

    ; Bars done, setup Scroller IRQ
    ; Trigger slightly before the text line ($F2) to avoid jitter caused by sprite DMA
    lda #$f0
    sta $d012
    lda #<irq_scroller
    sta $0314
    lda #>irq_scroller
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

irq_scroller:
    lda $d019
    sta $d019

    jsr scroller_update ; Logic for hardware + hard scroll

    ; Back to Top
    lda #0
    sta $d012
    lda #<irq_top
    sta $0314
    lda #>irq_top
    sta $0315
    jmp $ea81

BAR_COUNT = 11

bar_lines:
    .byte 50,55,60,65,70,75,80,85,90,95,100

bar_colors:
    .byte 0,2,8,10,7,1,7,10,8,2,0

; ------------------------------------------------------------
; Scroller (line 24, 40 columns)
; ------------------------------------------------------------

SCROLL_LINE = $07c0  ; $0400 + (24*40)
ZP_SCROLL = $60

init_scroller:
    lda #0
    sta hard_scroll_flag

    lda #<msg_scroll
    sta ZP_SCROLL
    lda #>msg_scroll
    sta ZP_SCROLL+1
    lda #7
    sta scroll_x
    jsr clear_scroll_line
    rts

scroller_update:
    ; Hardware Scroll Logic
    ; Set 38 Columns (Bit 3=0) to hide side artifacts
    ; Set Scroll bits (0-2) from scroll_x
    lda scroll_x
    and #7
    ora #$c0       ; Keep Multicolor/Screen bits if needed, but important is Bit 3=0 (38 cols)
                   ; $C0 = 1100 0000. 38 cols.
    sta $d016

    dec scroll_x
    bpl scroller_exit ; if >= 0, we are just shifting pixels

    ; Hard Scroll (Shift Memory) needed now
    lda #7
    sta scroll_x

    ; Set a flag to tell the main loop to perform the hard scroll.
    ; This keeps the IRQ routine short and consistent in timing.
    lda #1
    sta hard_scroll_flag

scroller_exit:
    rts

do_hard_scroll:
    ; This is called from the main loop, not the IRQ.
    ; It's safe for it to take longer.
    lda #0
    sta hard_scroll_flag

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
    sta bar_phase
    lda #1
    sta bar_dir
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

hard_scroll_flag:
    .byte 0

bar_index:
    .byte 0

bar_phase:
    .byte 0
bar_dir:
    .byte 1

msg_scroll:
    .enc "screen"      ; Mappa automaticamente ASCII -> Screen Codes (es. 'A' -> $01)
    .text "   *** hello c64 world! ***   "
    .text "ora il testo si legge perfettamente.   "
    .text "modifica questo messaggio come preferisci!   "
    .byte 0
    .enc "petscii"     ; Ripristina la codifica standard per il resto

label_text:
    .enc "screen"
    .text "c64 intro - irg/scroller/charset  glyph: "
    .byte 1
    .byte 0
    .enc "petscii"

; ------------------------------------------------------------
; Raster movement (bounce)
; ------------------------------------------------------------

BAR_MIN = 0
BAR_MAX = 40

update_bar_phase:
    lda bar_phase
    clc
    adc bar_dir
    sta bar_phase
    cmp #BAR_MAX
    bne check_min
    lda #$ff       ; -1
    sta bar_dir
    rts
check_min:
    cmp #BAR_MIN
    bne done_phase
    lda #1
    sta bar_dir
done_phase:
    rts

; ------------------------------------------------------------
; Sprites Logic
; ------------------------------------------------------------

SPRITE_DATA = $3000
SPRITE_PTR  = $07f8  ; Screen $0400 + $3f8 offset for Sprite 0

TRAIL_DELAY = 4       ; Delay in frames between trail segments. Aumentalo per più spazio.
TRAIL_BUFFER_SIZE = 32  ; Power of 2, deve essere >= 8 * TRAIL_DELAY
TRAIL_BUFFER_MASK = TRAIL_BUFFER_SIZE - 1

history_idx_zp = $fb  ; ZP temp variable for history index
msb_collect_zp = $fd  ; ZP temp for collecting MSB bits

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

    ; Fill history buffers with start position to avoid artifacts
    ldx #TRAIL_BUFFER_SIZE - 1
fill_hist_loop:
    sta trail_history_x,x
    sta trail_history_y,x
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

    ; --- Part 4: Increment history pointer for next frame ---
    inc trail_history_ptr
    lda trail_history_ptr
    and #TRAIL_BUFFER_MASK
    sta trail_history_ptr
    rts

spr_x:  .byte 100
spr_x_hi: .byte 0
spr_y:  .byte 100
spr_dx: .byte 1
spr_dy: .byte 1

trail_history_ptr: .byte 0
trail_history_x:   .fill TRAIL_BUFFER_SIZE
trail_history_x_msb: .fill TRAIL_BUFFER_SIZE
trail_history_y:   .fill TRAIL_BUFFER_SIZE

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
; Sprite Data (Located at $3000, safe in Bank 0)
; ------------------------------------------------------------
* = SPRITE_DATA
    ; Simple Ball Shape (24x21 pixels, single color)
    ; 3 bytes per row
    .byte 0,60,0, 0,126,0, 0,255,0, 1,255,128, 3,255,192, 3,255,192
    .byte 7,255,224, 7,255,224, 7,255,224, 7,255,224, 7,255,224, 3,255,192
    .byte 3,255,192, 1,255,128, 0,255,0, 0,126,0, 0,60,0, 0,0,0
    .byte 0,0,0, 0,0,0, 0,0,0  ; Padding to 63/64 bytes
