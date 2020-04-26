.macro draw_string(x_pos, y_pos, string_var, string_address) {
    ldx #string_var.size() - 1
!loop_text:
    lda string_address, x
    sta DEFAULT_SCREEN_MEMORY + (40 * y_pos) + x_pos, x
    dex
    bpl !loop_text-
}
