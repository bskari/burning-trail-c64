#importonce

.namespace AttractState {
// **** Constants ****
.const message = "burning man: gate road"
.const offset = X_CHARS * (Y_CHARS - 2)
.const ripple = 0
// Some of these colors look bad for some reason? Maybe my graphics mode is
// wrong. Orange, brown a little, most of the light colors.
// From DustLayer demo
//.var color_list = List().add(
//    ORANGE, LIGHT_RED, LIGHT_RED, LIGHT_GREY, LIGHT_GREY 
//    YELLOW, YELLOW, WHITE, WHITE, WHITE 
//    WHITE, WHITE, WHITE, WHITE, WHITE 
//    WHITE, WHITE, WHITE, WHITE, WHITE 
//    WHITE, WHITE, WHITE, YELLOW, YELLOW 
//    LIGHT_GREY, LIGHT_GREY, LIGHT_RED, LIGHT_RED, ORANGE 
//    ORANGE, RED, RED, BROWN, BROWN 
//)
.const color_list = List().add(
    RED, RED, /*ORANGE, ORANGE,*/ YELLOW, YELLOW,
    GREEN, GREEN, BLUE, BLUE, PURPLE, PURPLE
)

// **** Subroutines ****

initialize: {
    .break
    lda #ORANGE

    // TODO: load the sprite graphics for the man?
    ldx #message.size() - 1
repeat:
    lda _message, x
    sta DEFAULT_SCREEN_MEMORY + offset, x
    dex
    bpl repeat
    inc BORDER_COLOR
    .break
    rts
}

tick: {
    // Horizontal scroll
    lda SCREEN_CONTROL_2
    and #%0000_0111
    tax
    sec
    sbc #2
    ora #1111_1000
    sta SCREEN_CONTROL_2

    cpx #0
    bne no_adjust
    // The scroll register is full, we need to move the characters over
    ldx #0
    ldy DEFAULT_SCREEN_MEMORY + offset
!repeat:
    lda DEFAULT_SCREEN_MEMORY + offset + 1, x
    sta DEFAULT_SCREEN_MEMORY + offset, x
    inx
    cpx #40
    bcc !repeat-
    sty DEFAULT_SCREEN_MEMORY + offset + 39
no_adjust:

/*
    // Colors
    ldx #color_list.size()
    ldy #40
!repeat:
    lda colors, x
    sta CHAR_0_COLOR + offset, y
    dex
    bpl continue
    ldx #color_list.size()
continue:
    dey
    bpl !repeat-
*/

    jsr wait_frame
    clc
    rts
}

_message: .text message
/*
colors:
.for (var i = 0; i < color_list.size(); i++) {
    .byte color_list.get(i)
}
*/

}  // End namespace
