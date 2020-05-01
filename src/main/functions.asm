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

clear_screen: {
    lda #' '
    ldx #251
clear:
    dex
    sta DEFAULT_SCREEN_MEMORY, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    bne clear
    rts
}
