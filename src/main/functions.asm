#importonce
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

// Generates a pseudo random number
_random_seed: .byte 0
_frame_counter: .byte 0
random: {
    lda _random_seed
    adc RASTER_LINE
    adc _frame_counter
    sta _random_seed
    rts
}

// Wiats for the frame to finish drawing
wait_frame: {
    lda _random_seed
repeat:
    adc _frame_counter
    ldx RASTER_LINE
    cpx #248
    beq repeat

    // Wait for the raster line to reach line 248
    // (should be the start of the line this way)
wait_step_2:
    adc _frame_counter
    ldx RASTER_LINE
    cpx #248
    bne wait_step_2

    sta _random_seed
    inc _frame_counter
    rts
}

clear_screen: {
    lda #' '
set_screen_to_a:
    ldx #251
!_more_clear_screen:
    dex
    sta DEFAULT_SCREEN_MEMORY, x
    sta DEFAULT_SCREEN_MEMORY + 250, x
    sta DEFAULT_SCREEN_MEMORY + 500, x
    sta DEFAULT_SCREEN_MEMORY + 750, x
    bne !_more_clear_screen-
    rts
}

set_screen_color: {
    ldx #251
!_more_clear_screen:
    dex
    sta CHAR_0_COLOR, x
    sta CHAR_0_COLOR + 250, x
    sta CHAR_0_COLOR + 500, x
    sta CHAR_0_COLOR + 750, x
    bne !_more_clear_screen-
    rts
}

// Reads a single key from the keyboard. Handles debouncing, so it immediately
// returns the keyboard state when pressed, but subsequent checks won't until
// it's released and pressed again. Put the bitfield for KEYBOARD_1 in PARAM_1
// and bitfiled for KEYBOARD_2 in PARAM_2. Sets carry if something was pressed
// and returns the bitfield in A.
read_keyboard_press: {
    // Basic flow here is:
    // if previously pressed:
    //   if no keys are currently pressed:
    //     set previous to false
    //   return not pressed (clear carry)
    // else:
    //   if the key is pressed:
    //     set previous to true
    //     return the key (set carry)
    //   else:
    //     return not pressed (clear carry)

    // if previously pressed:
    lda previous
    beq not_previously_pressed

        // See if any key is pressed
        lda #%0000_0000
        sta KEYBOARD_1
        lda KEYBOARD_2
        // Normally you would bitwise-and the value with some
        // bitmask, but because we're checking for any key, our
        // bitmask would be all 1s

        // if no keys are pressed
        cmp #$ff
        bne pressed

            // set previous to false
            ldx #0
            stx previous

        pressed:
        // return not pressed
        clc
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
            sec
            rts

        // else:
        not_pressed:
            // return not pressed
            clc
            rts

previous: .byte 0
}
.function keyboard_row(character) {
    .var table = Hashtable()
    .eval table.put('0', %1110_1111)  // 0 key, row 4
    .eval table.put('1', %0111_1111)  // 1 key, row 7
    .eval table.put('2', %0111_1111)  // 2 key, row 7
    .eval table.put('3', %1111_1101)  // 3 key, row 1
    .eval table.put('4', %1111_1101)  // 4 key, row 1
    .eval table.put('5', %1111_1011)  // 5 key, row 2
    .return table.get(character)
}
.function keyboard_column(character) {
    .var table = Hashtable()
    .eval table.put('0', %0000_1000)  // 0 key, column 3
    .eval table.put('1', %0000_0001)  // 1 key, column 0
    .eval table.put('2', %0000_1000)  // 2 key, column 3
    .eval table.put('3', %0000_0001)  // 3 key, column 0
    .eval table.put('4', %0000_1000)  // 4 key, column 3
    .eval table.put('5', %0000_0001)  // 5 key, column 0
    .return table.get(character)
}

jump_engine: {
    // Taken from Super Mario Bros. To use, lda an index, then jsr to this,
    // and after that jsr use .word to list labels to jump to
    asl          // shift bit from contents of A
    tay
    pla          // pull saved return address from stack
    sta $F4      // save to indirect
    pla
    sta $F5
    iny
    lda ($F4),y  // load pointer from indirect
    sta $F6      // note that if an RTS is performed in next routine
    iny          // it will return to the execution before the sub
    lda ($F4),y  // that called this routine
    sta $F7
    jmp ($F6)    // jump to the address we loaded
}

/*
ripple_colors: {
    .var rippleColorsList = List().add(
        BROWN, RED, ORANGE, LIGHT_RED, LIGHT_GRAY, YELLOW, WHITE, WHITE,
        WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, YELLOW, LIGHT_GRAY,
        LIGHT_RED, ORANGE, RED, BROWN
    )

    inc offset
    lda offset
    lsr  // Slow the ripple effect down a little
    lsr
    cmp #rippleColorsList.size()
    bcc !continue+
    lda #0
    sta offset
!continue:
    tay

    ldx #200
repeat:
    iny
    cpy #rippleColorsList.size()
    bcc !continue+
    ldy #0
!continue:
    lda color, y
    dex
    sta CHAR_0_COLOR, x
    sta CHAR_0_COLOR + 200, x
    sta CHAR_0_COLOR + 400, x
    sta CHAR_0_COLOR + 600, x
    sta CHAR_0_COLOR + 800, x
    bne repeat

    rts

offset: .byte 0
color:
    .for (var i = 0; i < rippleColorsList.size(); i++) {
        .byte rippleColorsList.get(i)
    }
}
*/
