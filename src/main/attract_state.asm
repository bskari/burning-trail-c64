#importonce

.namespace AttractState {
// **** Constants ****
.const message = "burning man gate road"
.const offset = 600
.const ripple = 20

// **** Subroutines ****

initialize: {
    // Offset for color ripple
    lda #0
    sta ripple

    //// Set screen width to 38 columns
    //lda SCREEN_CONTROL_2 
    //and #%1111_0111
    //sta SCREEN_CONTROL_2

    // TODO: load the sprite graphics for the man?
    ldx #message.size() - 1
repeat:
    lda _message, x
    sta DEFAULT_SCREEN_MEMORY + offset, x
    dex
    bpl repeat
    inc BORDER_COLOR
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
repeat:
    lda DEFAULT_SCREEN_MEMORY + offset + 1, x
    sta DEFAULT_SCREEN_MEMORY + offset, x
    inx
    cpx #40
    bcc repeat
    sty DEFAULT_SCREEN_MEMORY + offset + 39

no_adjust:
    jsr wait_frame
    clc
    rts
}

_message: .text message
colors: .byte LIGHT_RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, PURPLE, WHITE

}  // End namespace
