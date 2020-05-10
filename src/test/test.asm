// Test runner

#import "../main/constants.asm"
#import "../main/initialize.asm"

.var tests = List().add(
)


// This creates a basic start
*=$0801
    // SYS 2064
.byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00

    cld

    :initialize_sprites()
    :initialize_disable_run_stop_keys()
    :initialize_screen()
    :initialize_turn_off_roms()

    lda #WHITE
    sta BACKGROUND_COLOR
    sta BORDER_COLOR

    lda #BLACK
    ldx #250
!repeat:
    dex
    sta CHAR_0_COLOR, x
    sta CHAR_0_COLOR + 250, x
    sta CHAR_0_COLOR + 500, x
    sta CHAR_0_COLOR + 750, x
    bne !repeat-

.const BLANK = $60
    lda #BLANK
    ldx #250
    clc
!repeat:
    dex
.const DEFAULT_SCREEN_CHAR = $0400
    sta DEFAULT_SCREEN_CHAR, x
    sta DEFAULT_SCREEN_CHAR + 250, x
    sta DEFAULT_SCREEN_CHAR + 500, x
    sta DEFAULT_SCREEN_CHAR + 750, x
    bne !repeat-

    // Run the tests
    lda #0
    sta test_number
.for (var i = 0; i < tests.size(); i++) {
    jsr tests.get(i)
    jsr show_test_results
    inc test_number
}

    // All done with tests, shut off border color
    lda #BLACK
    sta BORDER_COLOR
loop_forever:
    jmp loop_forever

test_number: .byte 0


show_test_results: {
    // Show a green heart for success; for failure, show the number
    // A holds test result, 0 == passed
    beq test_passed

    // For failure, let's show the number, or at least, 0-9
.const zero_offset = $30
    clc
    adc #zero_offset
    tay
    lda #RED
    jmp show_test_status

test_passed:
    lda #GREEN
.const HEART = $53
    ldy #HEART

show_test_status:
    ldx test_number
    sta CHAR_0_COLOR, x
    tya
    sta DEFAULT_SCREEN_CHAR, x

    rts
}


wait_frame: {
    lda RASTER_LINE
    cmp 248
    beq wait_frame

    // Wait for the raster line to reach line 248
    // (should be the start of the line this way)
wait_step_2:
    lda RASTER_LINE
    cmp 248
    bne wait_step_2
    rts
}
