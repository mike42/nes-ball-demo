;
; Macros and routines for handling object attribute memory (OAM)
;

; Store A register to 8 OAM locations (row of sprite Y locations)
.macro oam_row oam_base, sprite_base, offset
  sta oam_base+((0+sprite_base)*4)+offset
  sta oam_base+((1+sprite_base)*4)+offset
	sta oam_base+((2+sprite_base)*4)+offset
  sta oam_base+((3+sprite_base)*4)+offset
  sta oam_base+((4+sprite_base)*4)+offset
  sta oam_base+((5+sprite_base)*4)+offset
  sta oam_base+((6+sprite_base)*4)+offset
  sta oam_base+((7+sprite_base)*4)+offset
.endmacro

; Store A register to 8 OAM locations and increment each time (row of tiles)
.macro oam_row_inc oam_base, sprite_base, offset
  clc
  sta oam_base+((0+sprite_base)*4)+offset
  adc #1
  sta oam_base+((1+sprite_base)*4)+offset
  adc #1
	sta oam_base+((2+sprite_base)*4)+offset
  adc #1
  sta oam_base+((3+sprite_base)*4)+offset
  adc #1
  sta oam_base+((4+sprite_base)*4)+offset
  adc #1
  sta oam_base+((5+sprite_base)*4)+offset
  adc #1
  sta oam_base+((6+sprite_base)*4)+offset
  adc #1
  sta oam_base+((7+sprite_base)*4)+offset
.endmacro

; Store A register to 8 OAM locations (column of sprites)
.macro oam_col oam_base, sprite_base, offset
  sta oam_base+((0+sprite_base)*4)+offset
  sta oam_base+((8+sprite_base)*4)+offset
	sta oam_base+((16+sprite_base)*4)+offset
  sta oam_base+((24+sprite_base)*4)+offset
  sta oam_base+((32+sprite_base)*4)+offset
  sta oam_base+((40+sprite_base)*4)+offset
  sta oam_base+((48+sprite_base)*4)+offset
  sta oam_base+((56+sprite_base)*4)+offset
.endmacro

.segment "OAM"
oam_1: .res 256        ; OAM for even frames
oam_2: .res 256        ; OAM for odd frames

.segment "ZEROPAGE"
active_oam: .res 1
frame: .res 1

.segment "CODE"
sprite_y_oam_1:         ; Set Y position of 64 sprites in OAM 1
  clc
  lda ball_y            ; Row 0
  oam_row oam_1, 0, 0
  adc #8                ; Row 1
  oam_row oam_1, 8, 0
  adc #8                ; Row 2
  oam_row oam_1, 16, 0
  adc #8                ; Row 3
  oam_row oam_1, 24, 0
  adc #8                ; Row 4
  oam_row oam_1, 32, 0
  adc #8                ; Row 5
  oam_row oam_1, 40, 0
  adc #8                ; Row 6
  oam_row oam_1, 48, 0
  adc #8                ; Row 7
  oam_row oam_1, 56, 0
  rts

sprite_y_oam_2:         ; Set Y position of 64 sprites in OAM 2
  clc
  lda ball_y            ; Row 0
  oam_row oam_2, 0, 0
  adc #8                ; Row 1
  oam_row oam_2, 8, 0
  adc #8                ; Row 2
  oam_row oam_2, 16, 0
  adc #8                ; Row 3
  oam_row oam_2, 24, 0
  adc #8                ; Row 4
  oam_row oam_2, 32, 0
  adc #8                ; Row 5
  oam_row oam_2, 40, 0
  adc #8                ; Row 6
  oam_row oam_2, 48, 0
  adc #8                ; Row 7
  oam_row oam_2, 56, 0
  rts

sprite_tile_oam_1:      ; Set tile of 64 sprites in OAM 1
  lda #0                ; Row 0
  oam_row_inc oam_1, 0, 1
  lda #16               ; Row 1
  oam_row_inc oam_1, 8, 1
  lda #32               ; Row 2
  oam_row_inc oam_1, 16, 1
  lda #48               ; Row 3
  oam_row_inc oam_1, 24, 1
  lda #64               ; Row 4
  oam_row_inc oam_1, 32, 1
  lda #80               ; Row 5
  oam_row_inc oam_1, 40, 1
  lda #96               ; Row 6
  oam_row_inc oam_1, 48, 1
  lda #112              ; Row 7
  oam_row_inc oam_1, 56, 1
  rts

sprite_tile_oam_2:      ; Set tile of 64 sprites in OAM 2
  lda #8                ; Row 0
  oam_row_inc oam_2, 0, 1
  lda #24               ; Row 1
  oam_row_inc oam_2, 8, 1
  lda #40               ; Row 2
  oam_row_inc oam_2, 16, 1
  lda #56               ; Row 3
  oam_row_inc oam_2, 24, 1
  lda #72               ; Row 4
  oam_row_inc oam_2, 32, 1
  lda #88               ; Row 5
  oam_row_inc oam_2, 40, 1
  lda #104               ; Row 6
  oam_row_inc oam_2, 48, 1
  lda #120              ; Row 7
  oam_row_inc oam_2, 56, 1
  rts

sprite_x_oam_1:
  clc
  lda ball_x            ; Row 0
  oam_col oam_1, 0, 3
  adc #8                ; Row 1
  oam_col oam_1, 1, 3
  adc #8                ; Row 2
  oam_col oam_1, 2, 3
  adc #8                ; Row 3
  oam_col oam_1, 3, 3
  adc #8                ; Row 4
  oam_col oam_1, 4, 3
  adc #8                ; Row 5
  oam_col oam_1, 5, 3
  adc #8                ; Row 6
  oam_col oam_1, 6, 3
  adc #8                ; Row 7
  oam_col oam_1, 7, 3
  rts

sprite_x_oam_2:
  clc
  lda ball_x            ; Row 0
  oam_col oam_2, 0, 3
  adc #8                ; Row 1
  oam_col oam_2, 1, 3
  adc #8                ; Row 2
  oam_col oam_2, 2, 3
  adc #8                ; Row 3
  oam_col oam_2, 3, 3
  adc #8                ; Row 4
  oam_col oam_2, 4, 3
  adc #8                ; Row 5
  oam_col oam_2, 5, 3
  adc #8                ; Row 6
  oam_col oam_2, 6, 3
  adc #8                ; Row 7
  oam_col oam_2, 7, 3
  rts

sprite_attr_oam_1:
	; attributes * 64
	lda #%00000000 ; no flip
	oam_row oam_1, 0, 2
  oam_row oam_1, 8, 2
  oam_row oam_1, 16, 2
  oam_row oam_1, 24, 2
  oam_row oam_1, 32, 2
  oam_row oam_1, 40, 2
  oam_row oam_1, 48, 2
  oam_row oam_1, 60, 2
  rts

sprite_attr_oam_2:
	; attributes * 64
	lda #%00000000 ; no flip
	oam_row oam_2, 0, 2
  oam_row oam_2, 8, 2
  oam_row oam_2, 16, 2
  oam_row oam_2, 24, 2
  oam_row oam_2, 32, 2
  oam_row oam_2, 40, 2
  oam_row oam_2, 48, 2
  oam_row oam_2, 60, 2
  rts

setup_oam:
  jsr sprite_tile_oam_1
  jsr sprite_attr_oam_1
  jsr sprite_tile_oam_2
  jsr sprite_attr_oam_2
  lda #0
  sta frame
  jsr setup_frame
  rts

setup_frame:
  lda frame
  and #%00000100
  cmp #%00000100
  beq @odd_frame
  lda #>oam_2
  sta active_oam
  jmp @end_frame_branch
@odd_frame:
  lda #>oam_1
  sta active_oam
@end_frame_branch:

; .byte $0F,$20,$28,$16 ; sp0 yellow
  lda frame
  and #%00001000
  cmp #%00001000
  beq @pal1_frame
  ; Second palette
  lda #$20
  ldy #17
  sta palette, Y
  lda #$16
  ldy #19
  sta palette, Y
  jmp @end_pal_branch
@pal1_frame:
  ; Second palette
  lda #$16
  ldy #17
  sta palette, Y
  lda #$20
  ldy #19
  sta palette, Y
@end_pal_branch:




  rts

update_ball:
  inc frame             ; Advance ball animation
  jsr setup_frame
  jsr sprite_x_oam_1    ; Set sprite locations
  jsr sprite_y_oam_1
  jsr sprite_x_oam_2    ; Set sprite locations
  jsr sprite_y_oam_2
	rts
