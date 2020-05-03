#importonce
#import "macros.asm"
.namespace MainMenuState {
// **** Constants ****
.enum {
    State_YouMay = 1,
    State_Travel = 2,
    State_LearnAboutGate1 = 3,
    State_LearnAboutGate2 = 4,
    State_LearnAboutBurningMan = 5
}

_initialize_subroutine_table:
    .word 0  // This space intentionally left blank
    .word _initialize_you_may
    .word _initialize_travel
    .word _initialize_learn_about_gate_1
    .word _initialize_learn_about_gate_2
    .word _initialize_learn_about_burning_man

_tick_subroutine_table:
    .word 0  // This space intentionally left blank
    .word _tick_you_may
    //.word _tick_travel
    .word _tick_space_key_return
    .word _tick_space_key_return
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
    lda #State_LearnAboutGate1
    rts

!not_pressed:
    // Check for 3 key, row = 1, column = 0
    lda #%1111_1101
    ldx #%0000_0001
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutBurningMan
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
    lda #State_LearnAboutGate1
    rts

!not_pressed:
    // Check for 3 key, row = 1, column = 0
    lda #%1111_1101
    ldx #%0000_0001
    jsr read_keyboard_press
    bne !not_pressed+
    lda #State_LearnAboutBurningMan
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
    .var line_1 = "1. enter the gate"
    .var line_2 = "2. learn about the gate"
    .var line_3 = "3. learn about burning man"

    jsr clear_screen
    :draw_string(5, 10, you_may, _you_may)
    :draw_string(7, 12, line_1, _line_1)
    :draw_string(7, 13, line_2, _line_2)
    :draw_string(7, 14, line_3, _line_3)
     rts

_line_1:
    .text line_1
_line_2:
    .text line_2
_line_3:
    .text line_3
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


_initialize_learn_about_gate_1: {
    .var greeting = "learning about gate"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
    :draw_string(8, 15, space_to_continue, _space_to_continue)
     rts

_greeting:
    .text greeting
}


_initialize_learn_about_gate_2: {
    .var greeting = "learning about gate part 2"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
    :draw_string(8, 15, space_to_continue, _space_to_continue)
     rts

_greeting:
    .text greeting
}


_initialize_learn_about_burning_man: {
    .var greeting = "learning about burning man"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
    :draw_string(8, 15, space_to_continue, _space_to_continue)
     rts

_greeting:
    .text greeting
}

}  // End namespace
