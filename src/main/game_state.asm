#importonce
#import "main_menu_state.asm"

.namespace GameState {

// **** Constants ****
.var initializeSubroutineTable = List().add(
    MainMenuState.initialize,
    RunGameState.initialize
).lock()
_temp_initialize_subroutine_table:
.for (var i = 0; i < initializeSubroutineTable.size(); i++) {
    // Use address - 1 for the rts trick
    .word initializeSubroutineTable.get(i) - 1
}
// The first entry is excluded to save space, since states start at 1
.const _initialize_subroutine_table = _temp_initialize_subroutine_table - 2

.var tickSubroutineTable = List().add(
    MainMenuState.tick,
    RunGameState.tick
).lock()
_temp_tick_subroutine_table:
.for (var i = 0; i < tickSubroutineTable.size(); i++) {
    // Use address - 1 for the rts trick
    .word tickSubroutineTable.get(i) - 1
}
// The first entry is excluded to save space, since states start at 1
.const _tick_subroutine_table = _temp_tick_subroutine_table - 2

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
    asl
    tax
    lda _initialize_subroutine_table + 1, x
    pha
    lda _initialize_subroutine_table, x
    pha
    rts
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
    lda _tick_subroutine_table + 1, x
    pha
    lda _tick_subroutine_table, x
    pha
    rts
}

}
