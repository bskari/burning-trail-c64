#importonce

.namespace AttractState {
// **** Constants ****
.const intro = "bs presents..."
.const title = "burning man: gate road"
.const colors = List().add(GRAY, DARK_GRAY, BLACK)
.const middle_offset = X_CHARS * (Y_CHARS / 2) - intro.size()
.const offset = X_CHARS * (Y_CHARS - 2)
.const state = $20
.const timer = $21
.const color_index = $22
.const reveal_sprite_x = $23
.const man_sprite_y = $23

// **** Subroutines ****

initialize: {
    jsr clear_screen
    lda #0
    sta state
    sta color_index
    lda #50
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

    // Keep everything black for now
    lda #BLACK
    jsr set_screen_color

    ldx #intro.size() - 1
repeat:
    lda _intro, x
    sta DEFAULT_SCREEN_MEMORY + middle_offset + intro.size() / 2, x
    dex
    bpl repeat

    rts
}

tick: {
    // switch (state) {
    //  case 0: tick_reveal_presents(); break;
    //  case 1: tick_fade_presents(); break;
    //  case 2: tick_reveal_presents(); break;
    lda state
    beq tick_reveal_presents
    cmp #1
    beq call_fade_presents
    jmp tick_scroll
call_fade_presents:
    jmp tick_fade_presents
}

tick_reveal_presents: {
    lda reveal_sprite_x
    cmp #250
    bcs next_state
continue:
    :assert_cc()
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

next_state:
    inc state

    lda #0
    sta SPRITE_ENABLE

    lda #30
    sta timer

    :assert_cs()
    clc
    rts
}


tick_fade_presents: {
    dec timer
    bne return

    lda #30
    sta timer

    ldx color_index
    cpx #colors.size()
    beq next_state
    inc color_index
    lda _colors, x
    jsr set_screen_color
    jmp return

next_state:
    inc state

    // Colors for the man
    lda #LIGHT_RED
    sta SPRITE_EXTRA_COLOR_1
    lda #BROWN
    sta SPRITE_EXTRA_COLOR_2
    lda #YELLOW
    sta SPRITE_0_COLOR + 0
    sta SPRITE_0_COLOR + 1
    sta SPRITE_0_COLOR + 2

    // Sprite setup for the man
    lda #(SPRITE_DATA / 64 + 10)  // Head
    sta SPRITE_POINTER_BASE
    lda #(SPRITE_DATA / 64 + 11)  // Body
    sta SPRITE_POINTER_BASE + 1
    lda #(SPRITE_DATA / 64 + 12)  // Legs
    sta SPRITE_POINTER_BASE + 2

    lda #%0000_0111
    sta SPRITE_DOUBLE_WIDTH
    sta SPRITE_DOUBLE_HEIGHT

    lda #%0000_0111
    sta SPRITE_ENABLE
    sta SPRITE_PRIORITY

    lda #160
    sta sprite_x(0)
    sta sprite_x(1)
    sta sprite_x(2)
    lda #255
    sta man_sprite_y
    sta sprite_y(0)
    sta sprite_y(1)
    sta sprite_y(2)

    jsr clear_screen
    ldx #title.size() - 1
!repeat:
    lda _title, x
    sta DEFAULT_SCREEN_MEMORY + offset, x
    dex
    bpl !repeat-

    lda #WHITE
    jsr set_screen_color

return:
    clc
    rts
}

tick_scroll: {
.const sprite_height = 21
    // Move the man up until... TODO
    lda man_sprite_y
    cmp #70
    bcc done_moving_man
    dec man_sprite_y
    // Head
    sta sprite_y(0)
    clc
    adc #sprite_height * 2
    cmp man_sprite_y
    bcc done_moving_man
    sta sprite_y(1)
    clc
    adc #sprite_height * 2
    cmp man_sprite_y
    bcc done_moving_man
    sta sprite_y(2)
done_moving_man:

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
    :assert_cc()
    rts
}

_intro: .text intro
_title: .text title
_colors:
.for (var i = 0; i < colors.size(); i++) {
    .byte colors.get(i)
}

}  // End namespace
