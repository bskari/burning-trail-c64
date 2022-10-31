#importonce

.namespace AttractState {
// **** Constants ****
.const intro = "bs presents..."
.const title = "burning man: gate road"
.var colors_list = List().add(BLACK, GREY, WHITE, GREY, BLACK)
.const middle_offset = X_CHARS * (Y_CHARS / 2) - intro.size()
.const offset = X_CHARS * (Y_CHARS - 2)
.const state = $20
.const timer = $21
.const color_index = $22

// **** Subroutines ****

initialize: {
    jsr clear_screen
    lda #0
    sta state
    sta color_index
    lda #50
    sta timer

    //// TODO Remove this testing code
    //lda #1
    //sta timer
    //lda #colors_list.size() - 1
    //sta color_index

    ldx #intro.size() - 1
repeat:
    lda _intro, x
    sta DEFAULT_SCREEN_MEMORY + middle_offset + intro.size() / 2, x
    lda #BLACK
    sta CHAR_0_COLOR + middle_offset + intro.size() / 2, x
    dex
    bpl repeat

    // TODO: load the sprite graphics for the man?
    rts
}

tick: {
    lda state
    bne scroll
    dec timer
    bmi continue
    rts
continue:
    // Reset timer
    lda #50
    sta timer
    // Next color
    inc color_index
    ldx color_index
    cpx #colors_list.size()
    bcs next_state
    lda _colors, x
    ldx #intro.size() - 1
!repeat:
    sta CHAR_0_COLOR + middle_offset + intro.size() / 2, x
    dex
    bpl !repeat-
    clc
    rts

next_state:
    inc state
    jsr clear_screen
    lda #WHITE
    jsr set_screen_color
    ldx #title.size() - 1
!repeat:
    lda _title, x
    sta DEFAULT_SCREEN_MEMORY + offset, x
    dex
    bpl !repeat-
    clc
    rts

scroll:
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

    jsr wait_frame

    // Check for spacebar
    lda #%0111_1111
    sta PARAM_1
    lda #%0001_0000
    sta PARAM_2
    jsr read_keyboard_press

    bcc nothing_pressed
    lda #GameState_MainMenu
    sec
    rts

nothing_pressed:
    // This clc is unnecessary since we only jump here from bcc, but for
    // defensive programming, keep it in
    clc
    rts
}

_intro: .text intro
_title: .text title
_colors:
.for (var i = 0; i < colors_list.size(); i++) {
    .byte colors_list.get(i)
}

}  // End namespace
