#import "constants.asm"

.encoding "screencode_mixed"

// This creates a basic start
*=$0801
    // SYS 2064
.byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00

main: {
    sei

    :initialize_screen()
    :initialize_sprites()

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

    // Set VIC bank to 0
    lda #%00000011
    sta VIC_BANK_SETUP

    // Before disabling KERNAL ROM, we need to set the IRQ handler. The default
    // handler is in KERNAL ROM, so if we just disable it, it will crash.
    lda #<dummy_irq_handler
    sta $FFFE
    lda #>dummy_irq_handler
    sta $FFFF
    lda #(RamRomLayout.DEFAULT & ~RamRomLayout.ENABLE_KERNAL_MASK)
    sta RamRomLayout.ADDRESS

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
    ldx #DARK_GRAY
    stx BORDER_COLOR
    stx BACKGROUND_COLOR

    jsr clear_screen
}

.macro initialize_sprites() {
    // Disable sprites
    ldx #0
    stx SPRITE_ENABLE

    // Use multicolor sprites
    ldx #%11111111
    stx SPRITE_MULTICOLOR

    // Set some default colors
    lda #BLACK
    sta BACKGROUND_COLOR
    lda #LIGHT_GRAY
    sta SPRITE_EXTRA_COLOR_1
    lda #WHITE
    sta SPRITE_EXTRA_COLOR_2
    lda #GREEN
    sta SPRITE_0_COLOR + 0
    sta SPRITE_0_COLOR + 1
    lda #YELLOW
    sta SPRITE_0_COLOR + 2
    sta SPRITE_0_COLOR + 3
    lda #BLUE
    sta SPRITE_0_COLOR + 4
    sta SPRITE_0_COLOR + 5
}

dummy_irq_handler: {
    pha
    txa
    pha
    tya
    pha

    // Acknowledge the interrupt
    inc $D019

    pla
    tay
    pla
    tax
    pla

    rti
}

#import "functions.asm"
#import "game_state.asm"
#import "main_menu_state.asm"
#import "run_game_state.asm"

*=SPRITE_DATA
my_assert(mod(SPRITE_DATA, 64) == 0, "Bad SPRITE_DATA boundary")
.import binary "graphics/Sprites.raw"
