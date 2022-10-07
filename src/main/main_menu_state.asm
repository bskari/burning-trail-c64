#importonce
#import "lookup_tables.asm"
#import "macros.asm"
#import "game_state.asm"

.namespace MainMenuState {
// **** Constants ****
.enum {
    State_YouMay = 0,
    State_Travel = 1,
    State_LearnAboutBurningMan = 2,
    State_LearnAboutGate = 3,
    State_Shop = 4,
    State_SelectDepartureTime = 5,
    State_ExitMenu = 255
}

.var space_to_continue = "press space to continue"
_space_to_continue: .text space_to_continue

.var you_may = "you may:"
_you_may: .text you_may

.var question = "what is your choice?"
_question: .text question

// **** Variables ****
// TODO: For testing, you can set this to State_SelectDepartureTime, but
// normally this should be State_YouMay
_state: .byte State_YouMay
_space_key_return_state: .byte 0


// **** Subroutines ****

initialize: {
    jmp _call_initialize_subroutine
}

tick: {
    jsr wait_frame
    jsr _call_tick_subroutine
    // If carry is set, then A is the next requested state
    bcc no_state_change
    cmp #State_ExitMenu
    bne still_main_menu
    // Transition to state RunGame
    lda #GameState_RunGame
    sec
    rts

still_main_menu:
    sta _state
    jsr _call_initialize_subroutine

no_state_change:
    clc
    rts
}

_call_tick_subroutine: {
    lda _state
    jsr jump_engine
    .word _tick_you_may
    .word _tick_travel
    .word _tick_space_key_return  // Learn about Burning Man
    .word _tick_space_key_return  // Learn about gate
    .word _tick_space_key_return  // Shop
    .word _tick_select_departure_time
}

_tick_you_may: {
.var state_list = List().add(State_Travel, State_LearnAboutBurningMan, State_LearnAboutGate)

    ldy #0
check_next:
    iny
    cpy #state_list.size() + 1
    beq nothing_pressed
    lda LookupTables.number_key_to_row_bitmask, y
    sta PARAM_1
    lda LookupTables.number_key_to_column_bitmask, y
    sta PARAM_2
    jsr read_keyboard_press
    bne check_next

    // Something was pressed!
    lda _states, y
    sec
    rts

nothing_pressed:
    clc

// This lookup table should never use index 0, so put the first byte as an
// opcode for rts. Aw yeah, saved a byte!
_states:
    rts

.for (var i = 0; i < state_list.size(); i++) {
    .byte state_list.get(i)
}
}

_tick_travel: {
.var playerList = List().add(Player_Billionaire, Player_SparklePony, Player_VeteranBurner, Player_Virgin)

    ldy #0
check_next:
    iny
    cpy #playerList.size() + 1
    beq nothing_pressed
    lda LookupTables.number_key_to_row_bitmask, y
    sta PARAM_1
    lda LookupTables.number_key_to_column_bitmask, y
    sta PARAM_2
    jsr read_keyboard_press
    bne check_next

    // Something was pressed!
    lda _player_types, y
    sta GameState.player_type
    lda #State_Shop
    sec
    rts

nothing_pressed:
    clc

// This lookup table should never use index 0, so put the first byte as an
// opcode for rts. Aw yeah, saved a byte!
_player_types:
    rts

.for (var i = 0; i < playerList.size(); i++) {
    .byte playerList.get(i)
}
}

_tick_select_departure_time: {
.var departure_hour_list = List().add(18, 21, 24, 33, 45)
    ldy #0
check_next:
    iny
    cpy #departure_hour_list.size() + 1
    beq nothing_pressed
    lda LookupTables.number_key_to_row_bitmask, y
    sta PARAM_1
    lda LookupTables.number_key_to_column_bitmask, y
    sta PARAM_2
    jsr read_keyboard_press
    bne check_next

    // Something was pressed!
    lda _departure_hours, y
    sta GameState.time_hours
    lda #State_ExitMenu
    sec
    rts

nothing_pressed:
    clc

// This lookup table should never use index 0, so put the first byte as an
// opcode for rts. Aw yeah, saved a byte!
_departure_hours:
    rts

.for (var i = 0; i < departure_hour_list.size(); i++) {
    .byte departure_hour_list.get(i)
}
}

_tick_space_key_return: {
    // When space key is pressed, go back to the first state
    // Check for space key, row = 7, column = 4
    lda #%0111_1111
    sta PARAM_1
    lda #%0001_0000
    sta PARAM_2
    jsr read_keyboard_press
    bne !not_pressed+
    lda _space_key_return_state
    sec
    rts

!not_pressed:
    clc
    rts
}

_call_initialize_subroutine: {
    lda _state
    jsr jump_engine
    .word _initialize_you_may
    .word _initialize_travel
    .word _initialize_learn_about_burning_man
    .word _initialize_learn_about_gate
    .word _initialize_shop
    .word _initialize_select_departure_time
}

_initialize_you_may: {
    .var line_1 = "1. travel to the burn"
    .var line_2 = "2. learn about burning man"
    .var line_3 = "3. learn about the gate"

    jsr clear_screen
    :draw_string(5, 10, you_may, _you_may)
    :draw_string(7, 12, line_1, _line_1)
    :draw_string(7, 13, line_2, _line_2)
    :draw_string(7, 14, line_3, _line_3)
    rts

    _line_1: .text line_1
    _line_2: .text line_2
    _line_3: .text line_3
}

_initialize_travel: {
    .var intro_1 = "many kinds of people make the"
    .var intro_2 = "journey to burning man."
    .var option_1 = "1. be a billionaire techbro"
    .var option_2 = "2. be a sparkle pony"
    .var option_3 = "3. be a veteran burner"
    .var option_4 = "4. be a bright-eyed bushy-tailed virgin"

    jsr clear_screen
    :draw_string(1, 6, intro_1, _intro_1)
    :draw_string(1, 7, intro_2, _intro_2)
    :draw_string(1, 9, you_may, _you_may)
    :draw_string(1, 11, option_1, _option_1)
    :draw_string(1, 12, option_2, _option_2)
    :draw_string(1, 13, option_3, _option_3)
    :draw_string(1, 14, option_4, _option_4)
    :draw_string(1, 17, question, _question)
    rts

    _intro_1: .text intro_1
    _intro_2: .text intro_2
    _option_1: .text option_1
    _option_2: .text option_2
    _option_3: .text option_3
    _option_4: .text option_4
}

_initialize_learn_about_gate: {
    lda #State_YouMay
    sta _space_key_return_state

    .var line_1 = "like the cities of old, black"
    .var line_2 = "rock city is secured by a"
    .var line_3 = "perimeter fence, and"
    .var line_4 = "participants enter through a"
    .var line_5 = "gate. you must have a ticket to"
    .var line_6 = "enter black rock city. the gate"
    .var line_7 = "opens in early august for"
    .var line_8 = "pre-event traffic (only people"
    .var line_9 = "with early entry passes are"
    .var line_10 = "allowed in prior to the first"
    .var line_11 = "day of the event), then opens"
    .var line_12 = "for all participants at 12:01"
    .var line_13 = "am on the sunday prior to the"
    .var line_14 = "man burn, and is open 24 hours"
    .var line_15 = "a day throughout the event."

    jsr clear_screen
    :draw_centered_string(4, line_1, _line_1)
    :draw_centered_string(5, line_2, _line_2)
    :draw_centered_string(6, line_3, _line_3)
    :draw_centered_string(7, line_4, _line_4)
    :draw_centered_string(8, line_5, _line_5)
    :draw_centered_string(9, line_6, _line_6)
    :draw_centered_string(10, line_7, _line_7)
    :draw_centered_string(11, line_8, _line_8)
    :draw_centered_string(12, line_9, _line_9)
    :draw_centered_string(13, line_10, _line_10)
    :draw_centered_string(14, line_11, _line_11)
    :draw_centered_string(15, line_12, _line_12)
    :draw_centered_string(16, line_13, _line_13)
    :draw_centered_string(17, line_14, _line_14)
    :draw_centered_string(18, line_15, _line_15)

    :draw_centered_string(22, space_to_continue, _space_to_continue)
    rts

    _line_1: .text line_1
    _line_2: .text line_2
    _line_3: .text line_3
    _line_4: .text line_4
    _line_5: .text line_5
    _line_6: .text line_6
    _line_7: .text line_7
    _line_8: .text line_8
    _line_9: .text line_9
    _line_10: .text line_10
    _line_11: .text line_11
    _line_12: .text line_12
    _line_13: .text line_13
    _line_14: .text line_14
    _line_15: .text line_15
}

_initialize_shop: {
    lda #State_SelectDepartureTime
    sta _space_key_return_state

    .var line_1 = "before you head out, you'll need"
    .var line_2 = "to get some supplies. you'll need"
    .var line_3 = "food, plenty of water, and shelter."

    .var billionaire_1 = "don't worry though, your camp"
    .var billionaire_2 = "provides all that. let's go!"

    .var sparkle_pony_1 = "one of the principles of burning"
    .var sparkle_pony_2 = "is gifting. you've got 2"
    .var sparkle_pony_3 = "suitcases of costumes, your new"
    .var sparkle_pony_4 = "friends can provide the rest!"

    .var veteran_1 = "you've been doing this for years,"
    .var veteran_2 = "just need to get food, load and go!"

    jsr clear_screen
    :draw_centered_string(4, line_1, _line_1)
    :draw_centered_string(5, line_2, _line_2)
    :draw_centered_string(6, line_3, _line_3)

    // :draw_centered_string doesn't clopper Y, so use it
    ldy GameState.player_type

    cpy #Player_Billionaire
    bne !next+
    :draw_centered_string(10, billionaire_1, _billionaire_1)
    :draw_centered_string(11, billionaire_2, _billionaire_2)
    jmp end

!next:
    cpy #Player_SparklePony
    bne !next+
    :draw_centered_string(10, sparkle_pony_1, _sparkle_pony_1)
    :draw_centered_string(11, sparkle_pony_2, _sparkle_pony_2)
    :draw_centered_string(12, sparkle_pony_3, _sparkle_pony_3)
    :draw_centered_string(13, sparkle_pony_4, _sparkle_pony_4)
    jmp end

!next:
    cpy #Player_VeteranBurner
    bne !next+
    :draw_centered_string(10, veteran_1, _veteran_1)
    :draw_centered_string(11, veteran_2, _veteran_2)
    jmp end

!next:
end:
    :draw_centered_string(22, space_to_continue, _space_to_continue)
    rts

    _line_1: .text line_1
    _line_2: .text line_2
    _line_3: .text line_3
    _billionaire_1: .text billionaire_1
    _billionaire_2: .text billionaire_2
    _sparkle_pony_1: .text sparkle_pony_1
    _sparkle_pony_2: .text sparkle_pony_2
    _sparkle_pony_3: .text sparkle_pony_3
    _sparkle_pony_4: .text sparkle_pony_4
    _veteran_1: .text veteran_1
    _veteran_2: .text veteran_2
}

_initialize_learn_about_burning_man: {
    lda #State_YouMay
    sta _space_key_return_state

    .var line_1 = "burning man is an annual"
    .var line_2 = "experiment in temporary"
    .var line_3 = "community dedicated to radical"
    .var line_4 = "self-expression and radical"
    .var line_5 = "self-reliance."
    .var line_6 = "first held 34 years ago in 1986"
    .var line_7 = "on baker beach in san francisco"
    .var line_8 = "as a small function organized"
    .var line_9 = "by larry harvey and jerry james"
    .var line_10 = @"who built the first \"man\", it"
    .var line_11 = "has since been held annually,"
    .var line_12 = "spanning the nine days leading"
    .var line_13 = "up to and including labor day."

    jsr clear_screen
    :draw_centered_string(4, line_1, _line_1)
    :draw_centered_string(5, line_2, _line_2)
    :draw_centered_string(6, line_3, _line_3)
    :draw_centered_string(7, line_4, _line_4)
    :draw_centered_string(8, line_5, _line_5)
    :draw_centered_string(9, line_6, _line_6)
    :draw_centered_string(10, line_7, _line_7)
    :draw_centered_string(11, line_8, _line_8)
    :draw_centered_string(12, line_9, _line_9)
    :draw_centered_string(13, line_10, _line_10)
    :draw_centered_string(14, line_11, _line_11)
    :draw_centered_string(15, line_12, _line_12)
    :draw_centered_string(16, line_13, _line_13)
    :draw_centered_string(18, space_to_continue, _space_to_continue)
    rts

    _line_1: .text line_1
    _line_2: .text line_2
    _line_3: .text line_3
    _line_4: .text line_4
    _line_5: .text line_5
    _line_6: .text line_6
    _line_7: .text line_7
    _line_8: .text line_8
    _line_9: .text line_9
    _line_10: .text line_10
    _line_11: .text line_11
    _line_12: .text line_12
    _line_13: .text line_13
}

_initialize_select_departure_time: {
    .var description_1 = "from reno, it's 29 miles east to"
    .var description_2 = "wadsworth, then 78 miles north to"
    .var description_3 = "gerlach, then 8 miles north to"
    .var description_4 = "gate. the gate opens at midnight,"
    .var description_5 = "sunday, so don't show up early!"
    .var option_1 = "1. leave at 18:00 sat"
    .var option_2 = "2. leave at 21:00 sat"
    .var option_3 = "3. leave at 00:00 sun"
    .var option_4 = "4. leave at 09:00 sun"
    .var option_5 = "5. leave at 21:00 sun"

    jsr clear_screen

    :draw_centered_string(6, description_1, _description_1)
    :draw_centered_string(7, description_2, _description_2)
    :draw_centered_string(8, description_3, _description_3)
    :draw_centered_string(9, description_4, _description_4)
    :draw_centered_string(10, description_5, _description_5)

    :draw_string(1, 12, option_1, _option_1)
    :draw_string(1, 13, option_2, _option_2)
    :draw_string(1, 14, option_3, _option_3)
    :draw_string(1, 15, option_4, _option_4)
    :draw_string(1, 16, option_5, _option_5)

    :draw_string(1, 18, question, _question)

    rts

    _description_1: .text description_1
    _description_2: .text description_2
    _description_3: .text description_3
    _description_4: .text description_4
    _description_5: .text description_5
    _option_1: .text option_1
    _option_2: .text option_2
    _option_3: .text option_3
    _option_4: .text option_4
    _option_5: .text option_5
}

}  // End namespace
