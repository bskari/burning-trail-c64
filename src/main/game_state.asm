#importonce
#import "main_menu_state.asm"

.namespace GameState {

// **** Variables ****
player_type: .byte Player_Billionaire
_state: .byte GameState_MainMenu
// Hours since day before gate opening at midnight
time_hours: .byte 0
time_minutes: .byte 0

// **** Subroutines ****

// Initializes a new state, including loading new graphics, etc.
_initialize_state: {
    lda _state
    jsr jump_engine
    .word MainMenuState.initialize
    .word RunGameState.initialize
    .word SizeUpState.initialize
}


// Runs a frame of the current state. Initializes a state if necessary.
tick: {
    jsr _call_tick_subroutine

    // If carry is set, then A is the next requested state
    bcc no_state_change
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
    jsr jump_engine
    .word MainMenuState.tick
    .word RunGameState.tick
    .word SizeUpState.tick
}

}
