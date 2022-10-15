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
    // I'm not going to use custom tiles, so I shouldn't need that
    //:copy_character_rom()

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

    // TODO: Add this back in
    //:fade()

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

.macro fade() {
    .const fadeCounter = $25
    lda #50
    sta fadeCounter  // Which line we've faded out

repeat:
    jsr wait_frame

    lda #BLACK
    sta BORDER_COLOR
    sta BACKGROUND_COLOR

    // Move the fade down
    inc fadeCounter
    lda fadeCounter
    cmp #128
    beq done

    // Wait until we hit that line
!:
    cmp RASTER_LINE
    bne !-

    lda #LIGHT_BLUE
    sta BORDER_COLOR
    lda #BLUE
    sta BACKGROUND_COLOR

    // Wait until we hit the other side
    lda #254
    // I don't think sec is necessary because it won't be noticeable anyway
    sbc fadeCounter
!:
    cmp RASTER_LINE
    bne !-

    lda #BLACK
    sta BORDER_COLOR
    sta BACKGROUND_COLOR

    jmp repeat
done:
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

.macro copy_character_rom() {
    lda #%110011  // Enable character ROM for CPU
    sta $01
    lda #$D0
    sta $FC
    ldy #00
    sty $FB

    // Copy 2 KiB
    ldx #8
loop:
    lda ($FB), y
    sta ($FB), y
    iny
    bne loop
    inc $FC
    dex
    bne loop
    lda #%110111  // Switch in I/O mapped registers again
    sta $01
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
#import "size_up_state.asm"

*=SPRITE_DATA "sprite data"
my_assert(mod(SPRITE_DATA, 64) == 0, "Bad SPRITE_DATA boundary")
.import binary "graphics/Sprites.raw"
