#importonce
#import "main_menu_state.asm"

.const GAME_STATE_MAIN_MENU = 0

.namespace GameState {

// **** Constants ****
_initialize_subroutine_table:
    .word MainMenuState.initialize
_tick_subroutine_table:
    .word MainMenuState.tick

// **** Variables ****
_state: .byte GAME_STATE_MAIN_MENU
_need_to_initialize_new_state: .byte 1

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


// Runs a frame of the current state. Loads a state if necessary.
tick: {
    lda _need_to_initialize_new_state
    beq continue
    jsr _initialize_state
    lda #0
    sta _need_to_initialize_new_state

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

}
