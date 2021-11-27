#importonce

.namespace SizeUpState {

// **** Constants ****

.enum {
    SizeUp_Menu = 1,
    SizeUp_Continue = 2,
    SizeUp_Map = 3,
    SizeUp_ChangePace = 4,
    SizeUp_Rest = 5,
    SizeUp_Talk = 6
}
.const _period_column = 10
.const _time_row = 5
.const _you_may_row = _time_row + 9

.const _colon_column = 19

// **** Variables ****
_state: .byte SizeUp_Menu

// **** Subroutines ****

initialize: {
    lda #SizeUp_Menu
    sta _state

    // Disable raster interrupt signals from VIC
    sei
    lda #%0000_0000
    sta INTERRUPT_CONTROL_3   // $D01A
    cli

    // Disable all the sprites
    ldx #0
    stx SPRITE_ENABLE

    // Reset the colors
    lda #BLACK
    sta BACKGROUND_COLOR
    // Set all the text to be white
    lda #WHITE
    ldx #250
!repeat:
    dex
    sta CHAR_0_COLOR + 250, x
    sta CHAR_0_COLOR + 500, x
    sta CHAR_0_COLOR + 750, x
    sta CHAR_0_COLOR + 1000, x
    bne !repeat-

    jsr clear_screen
    jsr _draw_information
    jsr _draw_size_up_background
    rts
}


_draw_information: {
    lda #>screen_memory(_colon_column + 1, _time_row)
    sta ZEROPAGE_POINTER_1 + 1
    lda #<screen_memory(_colon_column + 1, _time_row)
    sta ZEROPAGE_POINTER_1

    jmp RunGameState.draw_information
}


_draw_size_up_background: {
.var you_may = "you may:"
.var continue = "1. continue on trail"
.var look_at_map = "2. look at map"
.var change_pace = "3. change pace"
.var stop_to_rest = "4. stop to rest"
.var talk_to_people = "5. talk to people"

    // Information should be on the top half of the screen
    lda #>screen_memory(_colon_column - 5, _time_row)
    sta ZEROPAGE_POINTER_1 + 1
    lda #<screen_memory(_colon_column - 5, _time_row)
    sta ZEROPAGE_POINTER_1

    jsr RunGameState.draw_information_background

    :draw_string(4, _you_may_row, you_may, _you_may)
    :draw_string(_period_column, _you_may_row + 1, continue, _continue)
    :draw_string(_period_column, _you_may_row + 2, look_at_map, _look_at_map)
    :draw_string(_period_column, _you_may_row + 3, change_pace, _change_pace)
    :draw_string(_period_column, _you_may_row + 4, stop_to_rest, _stop_to_rest)
    :draw_string(_period_column, _you_may_row + 5, talk_to_people, _talk_to_people)

    rts

_you_may: .text you_may
_continue: .text continue
_look_at_map: .text look_at_map
_change_pace: .text change_pace
_stop_to_rest: .text stop_to_rest
_talk_to_people: .text talk_to_people
}

tick: {
    // TODO
    clc
    rts
}

}
