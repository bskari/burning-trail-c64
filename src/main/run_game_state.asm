#importonce

.namespace RunGameState {

// **** Subroutines ****
initialize: {
    .var intro = "this is the run state"

    jsr clear_screen
    :draw_string(1, 6, intro, _intro)
    rts

    _intro: .text intro
}


tick: {
    jsr ripple_colors
    lda #0
    rts
}


}  // End namespace
