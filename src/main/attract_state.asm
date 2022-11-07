#importonce

.namespace AttractState {
// **** Constants ****
.const intro = "bs presents..."
.const title = "burning man: gate road"
.const middle_offset = X_CHARS * (Y_CHARS / 2) - intro.size()
.const offset = X_CHARS * (Y_CHARS - 2)
.const state = $20
.const timer = $21
.const color_index = $22
.const reveal_sprite_x = $23

// **** Subroutines ****

initialize: {
    jsr clear_screen
    lda #0
    sta state
    sta color_index
    lda #30
    sta reveal_sprite_x

    lda #BLACK
    sta sprite_color(0)
    lda #(SPRITE_DATA / 64 + 9)  // Fade sprite
    sta SPRITE_POINTER_BASE
    lda #140
    sta sprite_y(0)
    lda SPRITE_ENABLE
    ora #%0000_0001
    sta SPRITE_ENABLE

    ldx #intro.size() - 1
repeat:
    lda _intro, x
    sta DEFAULT_SCREEN_MEMORY + middle_offset + intro.size() / 2, x
    // Keep the colors black for now
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
    cmp #1
    beq tick_fade_presents
    jmp tick_presents
scroll:
    jmp scroll
}

tick_presents: {
    lda reveal_sprite_x
    cmp #250
    bne continue
    inc state
continue:
    clc
    adc #2
    sta reveal_sprite_x
    sta sprite_x(0)

    // Reveal any letters
    lsr
    lsr
    lsr
    sec
    sbc #14
    tax
    lda #WHITE
    sta CHAR_0_COLOR + middle_offset + intro.size() / 2, x

    clc
    rts

reveal_letter:
    lda reveal_sprite_x
    cmp #240
    beq next_state

    clc
    rts

next_state:
    lda #0
    sta SPRITE_ENABLE

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
}

tick_fade_presents: {
                    }

tick_scroll: {
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

}  // End namespace
