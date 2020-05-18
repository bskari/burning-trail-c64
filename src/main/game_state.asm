#importonce
#import "main_menu_state.asm"

.namespace GameState {

// **** Constants ****
_initialize_subroutine_table:
    .word 0  // This space intentionally left blank
    .word MainMenuState.initialize
    .word RunGameState.initialize
_tick_subroutine_table:
    .word 0  // This space intentionally left blank
    .word MainMenuState.tick
    .word RunGameState.tick

// **** Variables ****
player_type: .byte Player_Billionaire
_state: .byte GameState_MainMenu

// **** Subroutines ****

// Initializes a new state, including loading new graphics, etc.
_initialize_state: {
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


// Runs a frame of the current state. Initializes a state if necessary.
tick: {

    jsr _call_tick_subroutine

    // A return value of 0 indicates that no state change is necessary
    beq no_state_change
    sta _state
    // We could set a flag so that we only do this at the beginning of a tick
    // and prevent screen tearing, but it's only going to be there for one
    // frame, who cares
    jsr _initialize_state

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

}
