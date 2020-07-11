#import "constants.asm"

.encoding "screencode_mixed"

// This creates a basic start
*=$0801 "program"
    // SYS 2064
.byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00

main: {
    sei

    :initialize_screen()
    :initialize_sprites()

    // Turn off CIA timer interrupts
    lda #%0111_1111
    sta INTERRUPT_CONTROL_1  // $DC0D
    sta INTERRUPT_CONTROL_2  // $DD0D

    // $d012 is the current raster line, and bit #7 of d011 is the 9th bit of
    // that value. We need to make sure it's 0 for our intro.
    and SCREEN_CONTROL_1  // $D011
    sta SCREEN_CONTROL_1  // $D011

    // Cancel CIA-IRQs in flight
    lda INTERRUPT_CONTROL_1  // $DC0D
    lda INTERRUPT_CONTROL_2  // $DD0D

    // Enable raster interrupt signals from VIC
    lda #%0000_0001
    sta INTERRUPT_CONTROL_3   // $D01A

    // Just set any raster line as the interrupt. We're doing two interrupts in
    // irq_handler, and changing the line each tie, so any number will work.
    lda #0
    sta RASTER_LINE_INTERRUPT  // $D012

    // Set VIC bank to 0
    lda #%000_00011
    sta VIC_BANK_SETUP  // $DD00

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

    lda #WHITE
    ldx #250
repeat:
    dex
    sta CHAR_0_COLOR, x
    sta CHAR_0_COLOR + 250, x
    sta CHAR_0_COLOR + 500, x
    sta CHAR_0_COLOR + 750, x
    bne repeat

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
    // Acknowledge the interrupt
    inc $D019
    rti
}


#import "functions.asm"
#import "game_state.asm"
#import "main_menu_state.asm"
#import "run_game_state.asm"

*=SPRITE_DATA "sprite data"
my_assert(mod(SPRITE_DATA, 64) == 0, "Bad SPRITE_DATA boundary")
.import binary "graphics/Sprites.raw"
