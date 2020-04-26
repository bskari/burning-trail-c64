#importonce
#import "macros.asm"
.namespace MainMenuState {
// **** Constants ****
.const STATE_YOU_MAY = 0
.const STATE_TRAVEL = 1
.const STATE_LEARN_ABOUT_GATE_1 = 2
.const STATE_LEARN_ABOUT_GATE_2 = 3

_initialize_subroutine_table:
    .word _initialize_you_may
    //.word _initialize_travel
    //.word _initialize_learn_about_gate_1
    //.word _initialize_learn_about_gate_2

_tick_subroutine_table:
    .word _tick_you_may
    //.word _tick_travel
    //.word _tick_learn_about_gate_1
    //.word _tick_learn_about_gate_2

// **** Variables ****
_state: .byte STATE_YOU_MAY
_need_to_change_state: .byte 1


// **** Subroutines ****

initialize: {
    // TODO: Load graphics, etc.
    rts
}


tick: {
    lda _need_to_change_state
    beq continue
    jsr _call_initialize_subroutine
    lda #0
    sta _need_to_change_state

continue:
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
    // TODO: Check keyboard input
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

}  // End namespace
