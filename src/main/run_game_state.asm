#importonce

.namespace RunGameState {

// **** Subroutines ****
initialize: {
    jsr clear_screen

    // Let's just display the sprites for testing

.const spriteCount = 6

    // Set sprite pointers
.for (var i = 0; i < spriteCount; i++) {
    lda #(SPRITE_DATA / 64) + i
    sta SPRITE_POINTER_BASE + i
}

    // Set sprite positions
.for (var i = 0; i < spriteCount / 2; i++) {
    // Set the 2 halves' x positions
    lda #20 * i + 60
    sta spriteX(i * 2)
    lda #20 * i + 60 + 24
    sta spriteX(i * 2 + 1)
    // Set the 2 halves' y positions
    lda #60 + 21 * i
    sta spriteY(i * 2)
    sta spriteY(i * 2 + 1)
}

    // Enable the sprites
.var enables = 0
.for (var i = 0; i < spriteCount; i++) {
    .eval enables = (enables << 1) | 1;
}
    lda #enables
    sta SPRITE_ENABLE

    rts
}

tick: {
    lda #0
    rts
}

}  // End namespace
