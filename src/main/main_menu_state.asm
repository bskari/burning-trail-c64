#importonce
#import "macros.asm"
.namespace MainMenuState {
// **** Constants ****
.enum {
    State_YouMay = 1,
    State_Travel = 2,
    State_LearnAboutBurningMan1 = 3,
    State_LearnAboutBurningMan2 = 4,
    State_LearnAboutBurningMan3 = 5,
    State_LearnAboutBurningMan4 = 6,
    State_LearnAboutGate = 7
}

_initialize_subroutine_table:
    .word 0  // This space intentionally left blank
    .word _initialize_you_may
    .word _initialize_travel
    .word _initialize_learn_about_burning_man_1
    .word _initialize_learn_about_burning_man_2
    .word _initialize_learn_about_burning_man_3
    .word _initialize_learn_about_burning_man_4
    .word _initialize_learn_about_gate

_tick_subroutine_table:
    .word 0  // This space intentionally left blank
    .word _tick_you_may
    .word _tick_space_key_return
    .word _tick_space_learn_about_burning_man_1
    .word _tick_space_learn_about_burning_man_2
    .word _tick_space_learn_about_burning_man_3
    .word _tick_space_key_return
    .word _tick_space_key_return

.var space_to_continue = "press space to continue"
_space_to_continue:
.text space_to_continue

.var you_may = "you may:"
_you_may:
.text you_may


// **** Variables ****
_state: .byte State_YouMay


// **** Subroutines ****

initialize: {
    lda #State_YouMay
    sta _state
    jsr _initialize_you_may
    rts
}


tick: {
    jsr _call_tick_subroutine
    // If a != 0, then that is the next requested state
    beq no_state_change
    sta _state
    jsr _call_initialize_subroutine

no_state_change:
    rts
}


_call_tick_subroutine: {
    lda _state
    asl
    tax
    lda _tick_subroutine_table, x
    sta ZEROPAGE_POINTER_1
    lda _tick_subroutine_table + 1, x
    sta ZEROPAGE_POINTER_1 + 1
    jmp (ZEROPAGE_POINTER_1)

    // No rts here because the subroutine will do it
}


_tick_you_may: {
    // Check for 1 key, row = 7, column = 0
    lda #%0111_1111
    ldx #%0000_0001
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_Travel
    rts

!not_pressed:
    // Check for 2 key, row = 7, column = 3
    lda #%0111_1111
    ldx #%0000_1000
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutBurningMan1
    rts

!not_pressed:
    // Check for 3 key, row = 1, column = 0
    lda #%1111_1101
    ldx #%0000_0001
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutGate
    rts

!not_pressed:
    lda #0
    rts
}


_tick_travel: {
    // This function is just a placeholder for now
    // Check for 1 key, row = 7, column = 0
    lda #%0111_1111
    ldx #%0000_0001
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_Travel
    rts

!not_pressed:
    // Check for 2 key, row = 7, column = 3
    lda #%0111_1111
    ldx #%0000_1000
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutGate
    rts

!not_pressed:
    // Check for 3 key, row = 1, column = 0
    lda #%1111_1101
    ldx #%0000_0001
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutBurningMan1
    rts

!not_pressed:
    lda #0
    rts
}


_tick_space_learn_about_burning_man_1: {
    // When space key is pressed, go to learning part 2
    // Check for space key, row = 7, column = 4
    lda #%0111_1111
    ldx #%0001_0000
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutBurningMan2
    rts

!not_pressed:
    lda #0
    rts
}


_tick_space_learn_about_burning_man_2: {
    // When space key is pressed, go to learning part 3
    // Check for space key, row = 7, column = 4
    lda #%0111_1111
    ldx #%0001_0000
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutBurningMan3
    rts

!not_pressed:
    lda #0
    rts
}


_tick_space_learn_about_burning_man_3: {
    // When space key is pressed, go to learning part 4
    // Check for space key, row = 7, column = 4
    lda #%0111_1111
    ldx #%0001_0000
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutBurningMan4
    rts

!not_pressed:
    lda #0
    rts
}


_tick_space_key_return: {
    // When space key is pressed, go back to the first state
    // Check for space key, row = 7, column = 4
    lda #%0111_1111
    ldx #%0001_0000
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_YouMay
    rts

!not_pressed:
    lda #0
    rts
}


_call_initialize_subroutine: {
    lda _state
    asl
    tax
    lda _initialize_subroutine_table, x
    sta ZEROPAGE_POINTER_1
    lda _initialize_subroutine_table + 1, x
    sta ZEROPAGE_POINTER_1 + 1
    jmp (ZEROPAGE_POINTER_1)
    // No rts here because the subroutine will do it
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
    .var option_5 = "5. found out the differences"
    .var option_5_2 = "between the choices"
    .var question = "what is your choice?"

    .break
    jsr clear_screen
    :draw_string(1, 6, intro_1, _intro_1)
    :draw_string(1, 7, intro_2, _intro_2)
    :draw_string(1, 9, you_may, _you_may)
    :draw_string(1, 11, option_1, _option_1)
    :draw_string(1, 12, option_2, _option_2)
    :draw_string(1, 13, option_3, _option_3)
    :draw_string(1, 14, option_4, _option_4)
    :draw_string(1, 15, option_5, _option_5)
    :draw_string(4, 16, option_5_2, _option_5_2)
    :draw_string(1, 18, question, _question)
    rts

_intro_1:
    .text intro_1
_intro_2:
    .text intro_2
_option_1:
    .text option_1
_option_2:
    .text option_2
_option_3:
    .text option_3
_option_4:
    .text option_4
_option_5:
    .text option_5
_option_5_2:
    .text option_5_2
_question:
    .text question
}


_initialize_learn_about_gate: {
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
    :draw_string(4, 4, line_1, _line_1)
    :draw_string(4, 5, line_2, _line_2)
    :draw_string(4, 6, line_3, _line_3)
    :draw_string(4, 7, line_4, _line_4)
    :draw_string(4, 8, line_5, _line_5)
    :draw_string(4, 9, line_6, _line_6)
    :draw_string(4, 10, line_7, _line_7)
    :draw_string(4, 11, line_8, _line_8)
    :draw_string(4, 12, line_9, _line_9)
    :draw_string(4, 13, line_10, _line_10)
    :draw_string(4, 14, line_11, _line_11)
    :draw_string(4, 15, line_12, _line_12)
    :draw_string(4, 16, line_13, _line_13)
    :draw_string(4, 17, line_14, _line_14)
    :draw_string(4, 18, line_15, _line_15)

    :draw_string(8, 20, space_to_continue, _space_to_continue)
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


_initialize_learn_about_burning_man_1: {
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
    :draw_string(4, 3, line_1, _line_1)
    :draw_string(4, 4, line_2, _line_2)
    :draw_string(4, 5, line_3, _line_3)
    :draw_string(4, 6, line_4, _line_4)
    :draw_string(4, 7, line_5, _line_5)
    :draw_string(4, 8, line_6, _line_6)
    :draw_string(4, 9, line_7, _line_7)
    :draw_string(4, 10, line_8, _line_8)
    :draw_string(4, 11, line_9, _line_9)
    :draw_string(4, 12, line_10, _line_10)
    :draw_string(4, 13, line_11, _line_11)
    :draw_string(4, 14, line_12, _line_12)
    :draw_string(4, 15, line_13, _line_13)
    :draw_string(8, 17, space_to_continue, _space_to_continue)
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


_initialize_learn_about_burning_man_2: {
    .var line_1 = "burning man's ethos are"
    .var line_2 = "exemplified by ten principles."
    .var line_3 = "they were crafted not as a"
    .var line_4 = "dictate of how people should be"
    .var line_5 = "and act, but as a reflection of"
    .var line_6 = "the community’s ethos and"
    .var line_7 = "culture as it had organically"
    .var line_8 = "developed since the event’s"
    .var line_9 = "inception."
    .var line_10 = "1. radical inclusion"
    .var line_11 = "anyone may be a part of burning"
    .var line_12 = "man. we welcome and respect the"
    .var line_13 = "stranger. no prerequisites."
    .var line_14 = "2. gifting"
    .var line_15 = "burning man is devoted to acts of"
    .var line_16 = "gift giving. gift are unconditional"
    .var line_17 = "and do not contemplate exchange."

    jsr clear_screen
    :draw_string(4, 2, line_1, _line_1)
    :draw_string(4, 3, line_2, _line_2)
    :draw_string(4, 4, line_3, _line_3)
    :draw_string(4, 5, line_4, _line_4)
    :draw_string(4, 6, line_5, _line_5)
    :draw_string(4, 7, line_6, _line_6)
    :draw_string(4, 8, line_7, _line_7)
    :draw_string(4, 9, line_8, _line_8)
    :draw_string(4, 10, line_9, _line_9)

    :draw_string(6, 12, line_10, _line_10)
    :draw_string(4, 13, line_11, _line_11)
    :draw_string(4, 14, line_12, _line_12)
    :draw_string(4, 15, line_13, _line_13)

    :draw_string(6, 17, line_14, _line_14)
    :draw_string(4, 18, line_15, _line_15)
    :draw_string(4, 19, line_16, _line_16)
    :draw_string(4, 20, line_17, _line_17)

    :draw_string(8, 22, space_to_continue, _space_to_continue)
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
    _line_16: .text line_16
    _line_17: .text line_17
}


_initialize_learn_about_burning_man_3: {
    .var line_1 = "3. decommodification"
    .var line_2 = "we resist the substitution of"
    .var line_3 = "consumption for experiences."
    .var line_4 = "4. radical self-reliance"
    .var line_5 = "burning man encourages the"
    .var line_6 = "individual to discover, exercise"
    .var line_7 = "and rely on their inner resources."
    .var line_8 = "5. radical self-expression"
    .var line_9 = "arises from the unique gifts of"
    .var line_10 = "the individual, offered to all."
    .var line_11 = "6. communal effort"
    .var line_12 = "our community values creative"
    .var line_13 = "cooperation and collaboration."

    jsr clear_screen
    :draw_string(6, 3, line_1, _line_1)
    :draw_string(4, 4, line_2, _line_2)
    :draw_string(4, 5, line_3, _line_3)

    :draw_string(6, 7, line_4, _line_4)
    :draw_string(4, 8, line_5, _line_5)
    :draw_string(4, 9, line_6, _line_6)
    :draw_string(4, 10, line_7, _line_7)

    :draw_string(6, 12, line_8, _line_8)
    :draw_string(4, 13, line_9, _line_9)
    :draw_string(4, 14, line_10, _line_10)

    :draw_string(6, 16, line_11, _line_11)
    :draw_string(4, 17, line_12, _line_12)
    :draw_string(4, 18, line_13, _line_13)

    :draw_string(8, 20, space_to_continue, _space_to_continue)
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


_initialize_learn_about_burning_man_4: {
    .var line_1 = "7. civic responsibility"
    .var line_2 = "we value civil society."
    .var line_3 = "8. leaving no trace"
    .var line_4 = "we are committed to leaving no"
    .var line_5 = "physical trace of our activities."
    .var line_6 = "9. participation"
    .var line_7 = "we achieve being through doing."
    .var line_8 = "all are invited to work and play."
    .var line_9 = "10. immediacy"
    .var line_10 = "we seek to overcome barriers that"
    .var line_11 = "stand between us and a"
    .var line_12 = "recognition of our inner selves."

    jsr clear_screen
    :draw_string(6, 4, line_1, _line_1)
    :draw_string(4, 5, line_2, _line_2)

    :draw_string(6, 7, line_3, _line_3)
    :draw_string(4, 8, line_4, _line_4)
    :draw_string(4, 9, line_5, _line_5)

    :draw_string(6, 11, line_6, _line_6)
    :draw_string(4, 12, line_7, _line_7)
    :draw_string(4, 13, line_8, _line_8)

    :draw_string(6, 14, line_9, _line_9)
    :draw_string(6, 15, line_10, _line_10)
    :draw_string(4, 16, line_11, _line_11)
    :draw_string(4, 17, line_12, _line_12)

    :draw_string(8, 19, space_to_continue, _space_to_continue)
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
}

}  // End namespace
