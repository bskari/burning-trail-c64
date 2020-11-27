#importonce

.namespace SizeUpState {
.const _period_column = 10
.const _continue_row = 10
.const _look_at_map_row = _continue_row + 1
.const _change_pace_row = _look_at_map_row + 1
.const _stop_to_rest_row = _change_pace_row + 1
.const _talk_to_people_row = _stop_to_rest_row + 1


initialize: {
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
    jsr _draw_size_up_background
do_nothing:
    rts
}

_draw_size_up_background: {
.var you_may = "you may:"
.var continue = "1. continue on trail"
.var look_at_map = "2. look at map"
.var change_pace = "3. change pace"
.var stop_to_rest = "4. stop to rest"
.var talk_to_people = "5. talk to people"

    :draw_string(4, 8, you_may, _you_may)
    :draw_string(_period_column, _continue_row, continue, _continue)
    :draw_string(_period_column, _look_at_map_row, look_at_map, _look_at_map)
    :draw_string(_period_column, _change_pace_row, change_pace, _change_pace)
    :draw_string(_period_column, _stop_to_rest_row, stop_to_rest, _stop_to_rest)
    :draw_string(_period_column, _talk_to_people_row, talk_to_people, _talk_to_people)

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
    lda #0
    rts
}

}
