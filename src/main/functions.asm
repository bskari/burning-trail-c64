// Generic functions, e.g. for copying memory

// Moves memory down from a higher address to a lower address. The direction
// (down) only matters if the memory ranges overlap.
// ZEROPAGE_POINTER_1 = src
// ZEROPAGE_POINTER_2 = dest
// PARAM_1 + PARAM_2 = number of bytes to move
/*
move_memory: {
    ldy #0
    ldx PARAM_1
    beq move_2
move_1:
    // TODO: Use self-modifying code to replace these indirect addressing
    // instructions with indexed instructions
    lda (ZEROPAGE_POINTER_1), y
    sta (ZEROPAGE_POINTER_2), y
    iny
    bne move_1
    inc ZEROPAGE_POINTER_1 + 1
    inc ZEROPAGE_POINTER_2 + 1
    dex
    bne move_1
move_2:
    ldx PARAM_2
    beq done

    // Move the remaining bytes
move_3:
    lda (ZEROPAGE_POINTER_1), y
    sta (ZEROPAGE_POINTER_2), y
    iny
    dex
    bne move_3

done:
    rts
}
*/

wait_frame: {
    lda RASTER_LINE
    cmp #248
    beq wait_frame

    // Wait for the raster line to reach line 248
    // (should be the start of the line this way)
wait_step_2:
    lda RASTER_LINE
    cmp #248
    bne wait_step_2
    rts
}


clear_screen: {
    lda #' '
    ldx #251
clear:
    dex
    sta DEFAULT_SCREEN_MEMORY, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    sta DEFAULT_SCREEN_MEMORY + 500, x
    sta DEFAULT_SCREEN_MEMORY + 750, x
    bne clear
    rts
}


// Reads a single key from the keyboard. Handles debouncing, so it immediately
// returns the keyboard state when pressed, but subsequent checks won't until
// it's released and pressed again. Put the bitfield for KEYBOARD_1 in PARAM_1
// and bitfiled for KEYBOARD_2 in PARAM_2. Returns $FF if no keys were pressed,
// otherwise returns the bitfield.
read_keyboard_press: {
    // Basic flow here is:
    // if previously pressed:
    //   if no keys are currently pressed:
    //     set previous to false
    //   return not pressed ($ff)
    // else:
    //   if the key is pressed:
    //     set previous to true
    //     return the key
    //   else:
    //     return not pressed ($ff)

    // if previously pressed:
    lda previous
    beq not_previously_pressed

        .break
        // See if any key is pressed
        lda #%0000_0000
        sta KEYBOARD_1
        lda KEYBOARD_2
        // Normally you would bitwise-and the value with some
        // bitmask, but because we're checking for any key, our
        // bitmask would be all 1s

        // if no key is pressed (0 means pressed):
        cmp #$ff
        bne pressed

            // set previous to false
            ldx #0
            stx previous

        pressed:
        // return not pressed
        lda #$ff
        rts

    // else:
    not_previously_pressed:
        // See if the key is pressed
        lda PARAM_1
        sta KEYBOARD_1
        lda KEYBOARD_2
        and PARAM_2

        // if the key is pressed (0 means pressed):
        bne not_pressed

            // set previous to true
            ldx #1
            stx previous
            // return the key, which is already stored in A
            // But do tax so that we set the zero flag
            tax
            rts

        // else:
        not_pressed:
            // return not pressed
            lda #$ff
            rts

previous: .byte 0
}
