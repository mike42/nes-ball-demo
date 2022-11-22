; demo.s - bouncing ball demo for the NES.
;
; iNES header
;

.segment "HEADER"

INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 1 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID
.byte $02 ; 16k PRG chunk count
.byte $01 ; 8k CHR chunk count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

;
; CHR ROM
;

.segment "TILES"
.incbin "build/background.chr"
.incbin "build/sprite.chr"

;
; vectors placed at top 6 bytes of memory area
;

.segment "VECTORS"
.word nmi
.word reset
.word irq

.include "src/oam.s"

;
; reset routine
;
.segment "CODE"
reset:
	sei       ; mask interrupts
	lda #0
	sta $2000 ; disable NMI
	sta $2001 ; disable rendering
;
;	sta $4015 ; disable APU sound
;	sta $4010 ; disable DMC IRQ
;	lda #$40
;	sta $4017 ; disable APU IRQ
	cld       ; disable decimal mode
	ldx #$FF
	txs       ; initialize stack
	; wait for first vblank
	bit $2002
	:
		bit $2002
		bpl :-
	; clear all RAM to 0
	lda #0
	ldx #0
	:
		sta $0000, X
		sta $0100, X
		sta $0200, X
		sta $0300, X
		sta $0400, X
		sta $0500, X
		sta $0600, X
		sta $0700, X
		inx
		bne :-
	; place all sprites offscreen at Y=255
	lda #255
	ldx #0
	:
		sta oam_1, X
		inx
		inx
		inx
		inx
		bne :-
	; wait for second vblank
	:
		bit $2002
		bpl :-
	; NES is initialized, ready to begin!
	; enable the NMI for graphical updates, and jump to our main program
	lda #%10001000
	sta $2000
	jmp main

; Based on https://wiki.nesdev.org/w/index.php/APU_basics
apu_init:         ; Init $4000-4013
        ldy #$13
@loop:  lda @apu_startup_values, Y
        sta $4000, Y
        dey
        bpl @loop
        ; We have to skip over $4014 (OAMDMA)
        lda #$0f
        sta $4015
        lda #$40
        sta $4017
        rts
@apu_startup_values:
        .byte $30,$08,$00,$00
        .byte $30,$08,$00,$00
        .byte $80,$00,$00,$00
        .byte $30,$00,$00,$00
        .byte $00,$00,$00,$00

;
; nmi routine
;

.segment "ZEROPAGE"
nmi_lock:       .res 1 ; prevents NMI re-entry
nmi_count:      .res 1 ; is incremented every NMI
nmi_ready:      .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI
nmt_update_len: .res 1 ; number of bytes in nmt_update buffer
scroll_x:       .res 1 ; x scroll position
scroll_y:       .res 1 ; y scroll position
scroll_nmt:     .res 1 ; nametable select (0-3 = $2000,$2400,$2800,$2C00)
temp:           .res 1 ; temporary variable
ball_x: .res 1
ball_y: .res 1
y_frame: .res 1       ; frame for Y-position
anim_frame: .res 1    ; ball animation frame
ball_dir: .res 1
mute_count: .res 1

.segment "BSS"
nmt_update: .res 256 ; nametable update entry buffer for PPU update
palette:    .res 32  ; palette buffer for PPU update

.segment "CODE"
nmi:
	; save registers
	pha
	txa
	pha
	tya
	pha
	; prevent NMI re-entry
	lda nmi_lock
	beq :+
		jmp @nmi_end
	:
	lda #1
	sta nmi_lock
	; increment frame counter
	inc nmi_count
	;
	lda nmi_ready
	bne :+ ; nmi_ready == 0 not ready to update PPU
		jmp @ppu_update_end
	:
	cmp #2 ; nmi_ready == 2 turns rendering off
	bne :+
		lda #%00000000
		sta $2001
		ldx #0
		stx nmi_ready
		jmp @ppu_update_end
	:
	; sprite OAM DMA
	ldx #0
	stx $2003
	lda active_oam
	sta $4014
	; palettes
	lda #%10001000
	sta $2000 ; set horizontal nametable increment
	lda $2002
	lda #$3F
	sta PPUADDR
	stx PPUADDR ; set PPU address to $3F00
	ldx #0
	:
		lda palette, X
		sta PPUDATA
		inx
		cpx #32
		bcc :-
	; nametable update
	ldx #0
	cpx nmt_update_len
	bcs @scroll
	@nmt_update_loop:
		lda nmt_update, X
		sta PPUADDR
		inx
		lda nmt_update, X
		sta PPUADDR
		inx
		lda nmt_update, X
		sta PPUDATA
		inx
		cpx nmt_update_len
		bcc @nmt_update_loop
	lda #0
	sta nmt_update_len
@scroll:
	lda scroll_nmt
	and #%00000011 ; keep only lowest 2 bits to prevent error
	ora #%10001000
	sta $2000
	lda scroll_x
	sta $2005
	lda scroll_y
	sta $2005
	; enable rendering
	lda #%00011110
	sta $2001
	; flag PPU update complete
	ldx #0
	stx nmi_ready
@ppu_update_end:
	; if this engine had music/sound, this would be a good place to play it
	; unlock re-entry flag
	lda #0
	sta nmi_lock
@nmi_end:
	; restore registers and return
	pla
	tay
	pla
	tax
	pla
	rti

;
; irq
;

.segment "CODE"
irq:
	rti

; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
ppu_update:
	lda #1
	sta nmi_ready
	:
		lda nmi_ready
		bne :-
	rts

.segment "RODATA"
start_palette: ; background last, foreground second
.byte $0F,$04,$26,$10 ; bg0 purple/grey
.byte $0F,$09,$19,$29 ; bg1 not used
.byte $0F,$01,$11,$21 ; bg2 not used
.byte $0F,$00,$10,$30 ; bg3 not used
.byte $0F,$20,$28,$16 ; sp0 updated dynamically
.byte $0F,$14,$24,$34 ; sp1 not used
.byte $0F,$1B,$2B,$3B ; sp2 not used
.byte $0F,$12,$22,$32 ; sp3 not used


.segment "CODE"
main:
	; setup
	ldx #0
	:
		lda start_palette, X
		sta palette, X
		inx
		cpx #32
		bcc :-
	jsr setup_background
	; center the ball
	lda #150
	sta ball_x
	lda #80
	sta ball_y
  lda #0
  sta anim_frame
  sta ball_dir
  sta mute_count
  jsr setup_oam
	jsr update_ball
	jsr ppu_update
  jsr apu_init
	; main loop
@draw:
	; draw everything and finish the frame
	jsr ball_physics
	jsr update_ball
	jsr ppu_update
	; keep doing this forever!
	jmp @draw

PPUADDR = $2006
PPUDATA = $2007

setup_background:
	; clear first nametable
	lda $2002 ; reset latch
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	; empty nametable
	lda #$34
	ldy #30 ; 30 rows
	:
		ldx #32 ; 32 columns
		:
			sta PPUDATA
			dex
			bne :-
		dey
		bne :--
	; set all attributes to 0
	lda #0
	ldx #64 ; 64 bytes
	:
		sta PPUDATA
		dex
		bne :-

	; second nametable empty (not used)
	lda #$24
	sta PPUADDR
	lda #$00
	sta PPUADDR
	; empty nametable
	lda #0
	ldy #30 ; 30 rows
	:
		ldx #32 ; 32 columns
		:
			sta PPUDATA
			dex
			bne :-
		dey
		bne :--

  ; draw a grid to first nametable
	lda $2002 ; reset latch
	lda #$20
	sta PPUADDR
	lda #$60
  sta PPUADDR
	ldy #11
@grid_row:                ; each grid row is 2 roes of tiles
  lda #$34
  sta PPUDATA
  sta PPUDATA
	ldx #14
	:
    lda #$30
    sta PPUDATA
    lda #$31
    sta PPUDATA
  dex
  bne :-
  lda #$32
  sta PPUDATA
  lda #$34
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
	ldx #14
	:
    lda #$32
    sta PPUDATA
    lda #$34
    sta PPUDATA
  dex
  bne :-
  lda #$32
  sta PPUDATA
  lda #$34
  sta PPUDATA
  dey
  bne @grid_row
  ; Paste in some defined lines for the end of the screen
  ldx #16
  lda #$40
  clc
  :
    sta PPUDATA
    adc #1
  dex
  bne :-
  ldx #16
  lda #$60
  clc
  :
    sta PPUDATA
    adc #1
  dex
  bne :-
  ldx #16
  lda #$50
  clc
  :
    sta PPUDATA
    adc #1
  dex
  bne :-
  ldx #16
  lda #$70
  clc
  :
    sta PPUDATA
    adc #1
  dex
  bne :-

  ldx #32
  :
    lda #$33
    sta PPUDATA
  dex
  bne :-
	rts

ball_physics:
  jsr ball_physics_x
  jsr ball_physics_y
  jsr ball_physics_spin
  jsr ball_bounce_mute
  rts

ball_bounce_mute:         ; mute sound eventually
  dec mute_count
  bne @end
  jsr apu_init
@end:
  rts

; lookup table for y-coordinates over two bounces
ball_loc_y: .byte $96, $93, $90, $8d, $8a, $87, $84, $81, $7e, $7b, $78, $75, $72, $6f, $6c, $69, $66, $63, $60, $5e, $5b, $58, $55, $53, $50, $4e, $4b, $49, $46, $44, $42, $3f, $3d, $3b, $39, $37, $35, $33, $31, $2f, $2d, $2c, $2a, $29, $27, $26, $24, $23, $22, $21, $20, $1f, $1e, $1d, $1c, $1b, $1b, $1a, $1a, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $1a, $1a, $1b, $1b, $1c, $1c, $1d, $1e, $1f, $20, $21, $22, $24, $25, $26, $28, $29, $2b, $2d, $2e, $30, $32, $34, $36, $38, $3a, $3c, $3e, $40, $43, $45, $48, $4a, $4c, $4f, $52, $54, $57, $5a, $5c, $5f, $62, $65, $68, $6a, $6d, $70, $73, $76, $79, $7c, $7f, $82, $85, $89, $8c, $8f, $92, $95, $95, $92, $8f, $8c, $89, $85, $82, $7f, $7c, $79, $76, $73, $70, $6d, $6a, $68, $65, $62, $5f, $5c, $5a, $57, $54, $52, $4f, $4c, $4a, $48, $45, $43, $40, $3e, $3c, $3a, $38, $36, $34, $32, $30, $2e, $2d, $2b, $29, $28, $26, $25, $24, $22, $21, $20, $1f, $1e, $1d, $1c, $1c, $1b, $1b, $1a, $1a, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $1a, $1a, $1b, $1b, $1c, $1d, $1e, $1f, $20, $21, $22, $23, $24, $26, $27, $29, $2a, $2c, $2d, $2f, $31, $33, $35, $37, $39, $3b, $3d, $3f, $42, $44, $46, $49, $4b, $4e, $50, $53, $55, $58, $5b, $5e, $60, $63, $66, $69, $6c, $6f, $72, $75, $78, $7b, $7e, $81, $84, $87, $8a, $8d, $90, $93, $96

X_MIN = 8
X_MAX = 184
BALL_RIGHT = 0
BALL_LEFT = 1

ball_physics_x:
  lda ball_dir
  cmp #BALL_RIGHT         ; branch on ball direction
  bne @ball_move_left
  inc ball_x              ; move right
  lda ball_x
  cmp #X_MAX              ; check against right wall
  bne @ball_move_end
  lda #BALL_LEFT          ; change direction
  sta ball_dir
  jsr bounce_noise
  jmp @ball_move_end
  @ball_move_left:
  dec ball_x              ; move left
  lda ball_x
  cmp #X_MIN              ; check against left wall
  bne @ball_move_end
  lda #BALL_RIGHT         ; change direction
  sta ball_dir
  jsr bounce_noise
  @ball_move_end:
  rts

ball_physics_y:           ; set Y from lookup table
  inc y_frame
  ldy y_frame
  lda ball_loc_y, Y
  sta ball_y
  cmp #$95
  bcc @end
  jsr bounce_noise
@end:
  rts

ball_physics_spin:       ; set animation frame
  lda ball_x
  ; slow mode
  ror
  and #%01111111
  sta anim_frame
  rts

bounce_noise:
  jsr apu_init
  lda #%00000101        ; some raw noise
  sta $400E
  lda #%00110001
  sta $400C
  lda #5
  sta mute_count
  rts
