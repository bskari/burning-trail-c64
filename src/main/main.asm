#import "constants.asm"

.encoding "screencode_mixed"

// This creates a basic start
*=$0801
    // SYS 2064
.byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00

main: {
    sei

    :initialize_screen()

    // Turn off CIA timer interrupts
    ldy #%01111111
    sty INTERRUPT_CONTROL_1
    sty INTERRUPT_CONTROL_2
    // Cancel CIA-IRQs in flight
    lda INTERRUPT_CONTROL_1
    lda INTERRUPT_CONTROL_2

    // $d012 is the current raster line, and bit #7 of d011 is the 9th bit of
    // that value. We need to make sure it's 0 for our intro.
    lda SCREEN_CONTROL_1
    and #%01111111
    sta SCREEN_CONTROL_1

    cli

    // One time, we need to initialize the state
    jsr GameState._initialize_state

    // Set CIA port A to all outputs
    lda #$FF
    sta PORT_A_DIRECTION
    // Set CIA port B to all inputs
    lda #0
    sta PORT_B_DIRECTION

loop:
    jsr GameState.tick
    jsr wait_frame
    jmp loop
}


.macro initialize_screen() {
    ldx #BLACK
    stx BORDER_COLOR
    stx BACKGROUND_COLOR

    jsr clear_screen
}

#import "functions.asm"
#import "game_state.asm"
#import "main_menu_state.asm"
#import "run_game_state.asm"
