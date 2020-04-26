#import "constants.asm"

.encoding "screencode_mixed"

// This creates a basic start
*=$0801
    // SYS 2064
.byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00

main: {
    sei

    :init_screen()

    // Turn off CIA timer interrupts
    ldy #%01111111
    sty INTERRUPT_CONTROL_1
    sty INTERRUPT_CONTROL_2
    // Cancel CIA-IRQs in flight
    lda INTERRUPT_CONTROL_1
    lda INTERRUPT_CONTROL_2

    // Set interrupt request mask to raster beam
    lda #1
    sta INTERRUPT_CONTROL_3

    // $d012 is the current raster line, and bit #7 of d011 is the 9th bit of
    // that value. We need to make sure it's 0 for our intro.
    lda SCREEN_CONTROL_1
    and #%01111111
    sta SCREEN_CONTROL_1

    // Point IRQ vector to our custom routine
    lda #<irq
    sta INTERRUPT_SUBROUTINE_ADDRESS
    lda #>irq
    sta INTERRUPT_SUBROUTINE_ADDRESS + 1

    // Trigger interrupt at scanline 0
    lda #0
    sta RASTER_LINE_INTERRUPT

    cli

loop:
    jmp loop
}


irq: {
    // Acknowledge IRQ by clearing register for next interrupt
    dec INTERRUPT_STATUS_REGISTER

    jsr GameState.tick

    // Return to kernel interrupt routine
    jmp $ea81
}


.macro init_screen() {
    ldx #BLACK
    stx BORDER_COLOR
    stx BACKGROUND_COLOR

    lda #' '
    ldx #251
clear:
    dex
    sta DEFAULT_SCREEN_MEMORY, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    bne clear
}

#import "game_state.asm"
#import "main_menu_state.asm"
