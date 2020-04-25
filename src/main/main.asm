#import "constants.asm"

// This creates a basic start
*=$0801
    // SYS 2064
.byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00

main: {
    sei

    jsr init_screen
    jsr init_text

    // Turn off CIA timer interrupts
    ldy #%01111111
    sty $dc0d
    sty $dd0d
    // Cancel CIA-IRQs in flight
    lda $dc0d
    lda $dd0d

    // Set interrupt request mask to raster beam
    lda #1
    sta $d01a

    // $d012 is the current raster line, and bit #7 of d011 is the 9th bit of
    // that value. We need to make sure it's 0 for our intro.
    lda $d011
    and #%01111111
    sta $d011

    // Point IRQ vector to our custom routine
    lda #<irq
    sta $314
    lda #>irq
    sta $315

    // Trigger interrupt at scanline 0
    lda #0
    sta $d012

    cli

loop:
    jmp loop
}


irq: {
    // Acknowledge IRQ by clearing register for next interrupt
    dec $d019

    jsr color_wash

    // Return to kernel interrupt routine
    jmp $ea81
}


init_screen: {
    ldx #BLACK
    stx $d020 // Border color
    stx $d021  // Background color

    lda #' '
    ldx #251
clear:
    dex
    sta $0400, x
    sta $0400 + 250, x
    sta $0500 + 250, x
    sta $0600 + 250, x
    bne clear

    rts
}


.encoding "screencode_mixed"


init_text: {
    .var line_1 = "actraiser in 2013 presents..."
    .var line_2 = "example effect for dustlayer tutorials"

    // Copy lines to screen RAM

    ldx #line_1.size() - 1
!loop_text:
    lda _line_1, x
    sta $0595, x
    dex
    bpl !loop_text-

    ldx #line_2.size() - 1
!loop_text:
    lda _line_2, x
    sta $05e0, x
    dex
    bpl !loop_text-

    rts

_line_1:
    .text line_1
_line_2:
    .text line_2
}


color_wash: {
    // We only run this every few frames
    dec count
    beq !zero+
    rts
!zero:
    ldx #2
    stx count

.const ARRAY_SIZE = 5 * 8

    // Do the first line
    ldy index
    ldx #ARRAY_SIZE - 1
!repeat:
    lda color_array, y
    sta $d995, x

    iny
    cpy #ARRAY_SIZE
    bcc !less_than+
    ldy #0
!less_than:

    dex
    bpl !repeat-

    // Do the second line, reversed
    ldy index
    ldx #ARRAY_SIZE - 1
!repeat:
    lda color_array, y
    sta $d9e0, x

    dey
    bpl !greater_than_zero+
    ldy #ARRAY_SIZE - 1

!greater_than_zero:
    dex
    bpl !repeat-

    // Now increment start index
    ldy index
    iny
    cpy #ARRAY_SIZE
    bcc !less_than+
    ldy #0
!less_than:
    sty index

    rts

index:
    .byte 0
count:
    .byte 1
color_array:
    .byte $09,$09,$02,$02,$08 
    .byte $08,$0a,$0a,$0f,$0f 
    .byte $07,$07,$01,$01,$01 
    .byte $01,$01,$01,$01,$01 
    .byte $01,$01,$01,$01,$01 
    .byte $01,$01,$01,$07,$07 
    .byte $0f,$0f,$0a,$0a,$08 
    .byte $08,$02,$02,$09,$09 
}
