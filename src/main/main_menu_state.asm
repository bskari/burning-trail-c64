#importonce
#import "macros.asm"
.namespace MainMenuState {
// **** Constants ****
.const STATE_YOU_MAY = 1
.const STATE_TRAVEL = 2
.const STATE_LEARN_ABOUT_GATE_1 = 3
.const STATE_LEARN_ABOUT_GATE_2 = 4
.const STATE_LEARN_ABOUT_BURNING_MAN = 5

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
    .word _tick_space_key_return
    .word _tick_space_key_return
    .word _tick_space_key_return
    .word _tick_space_key_return

// **** Variables ****
_state: .byte STATE_YOU_MAY


// **** Subroutines ****

initialize: {
    lda #STATE_YOU_MAY
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
    sta KEYBOARD_1
    lda KEYBOARD_2
    and #%0000_0001
    bne !not_pressed+
    lda #STATE_TRAVEL
    rts

!not_pressed:
    // Check for 2 key, row = 7, column = 3
    lda #%0111_1111
    sta KEYBOARD_1
    lda KEYBOARD_2
    and #%0000_1000
    bne !not_pressed+
    lda #STATE_LEARN_ABOUT_GATE_1
    rts

!not_pressed:
    // Check for 3 key, row = 1, column = 0
    // We could put this test right after the check for 1 key, beacuse it
    // already has column 0 selected, but eeehhhh this is clearer
    lda #%1111_1101
    sta KEYBOARD_1
    lda KEYBOARD_2
    and #%0000_0001
    bne !not_pressed+
    lda #STATE_LEARN_ABOUT_BURNING_MAN
    rts

!not_pressed:
    lda #0
    rts
}


_tick_space_key_return: {
    // When space key is pressed, go back to the first state
    // Check for space key, row = 7, column = 4
    lda #%0111_1111
    sta KEYBOARD_1
    lda KEYBOARD_2
    and #%0001_0000
    bne !not_pressed+
    lda #STATE_YOU_MAY
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
    .var greeting = "you may:"
    .var line_1 = "1. enter the gate"
    .var line_2 = "2. learn about the gate"
    .var line_3 = "3. learn about burning man"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
    :draw_string(7, 10, line_1, _line_1)
    :draw_string(7, 11, line_2, _line_2)
    :draw_string(7, 12, line_3, _line_3)
     rts

_greeting:
    .text greeting
_line_1:
    .text line_1
_line_2:
    .text line_2
_line_3:
    .text line_3
}


_initialize_travel: {
    .var greeting = "okay wow let's travel the trail"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
     rts

_greeting:
    .text greeting
}


_initialize_learn_about_gate_1: {
    .var greeting = "learning about gate"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
     rts

_greeting:
    .text greeting
}


_initialize_learn_about_gate_2: {
    .var greeting = "learning about gate part 2"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
     rts

_greeting:
    .text greeting
}


_initialize_learn_about_burning_man: {
    .var greeting = "learning about burning man"

    jsr clear_screen
    :draw_string(5, 8, greeting, _greeting)
     rts

_greeting:
    .text greeting
}

.var space_to_continue = "press space to continue"
_space_to_continue:
.text space_to_continue

}  // End namespace
