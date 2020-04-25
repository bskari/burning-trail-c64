.const GAME_STATE_MAIN_MENU = 1

namespace GameState {

_load_state_routines:
    .word $0  // Value deliberately left empty
    .word _load_main_menu

_tick_state_routines:
    .word $0  // Value deliberately left empty
    .word _tick_main_menu

// Prepares to load a new state, including loading new graphics, etc. State
// passed in in A.
_load_state:
    asl
    tax
    lda _load_state_routines, x
    sta _address
    lda _states + 1, x
    sta _address + 1
    .byte $20  // JSR
_address:
    .word $0
    rts
}


// Runs a frame of the current state. State passed in in A. Returns non-zero in
// A if the state should be changed.
tick_state: {
    asl
    tax
    lda _states, x
    sta _address
    lda _states + 1, x
    sta _address + 1
    .byte $20  // JSR
_address:
    .word $0  // placeholder
    rts
}

_load_main_menu: {
    // Wipe the screen
    lda #0
    ldx #251
repeat:
    dex
    sta SCREEN_CHAR, x
    sta SCREEN_CHAR + 250, x
    sta SCREEN_CHAR + 500, x
    sta SCREEN_CHAR + 750, x
    bne repeat

    // Load some text

main_text_1:
    .text "You may:"
main_text_2:
    .text "1. Enter the gate"
main_text_3
    .text "2. Learn about the gate"
main_text_
}

_tick_main_menu: {
}

}
