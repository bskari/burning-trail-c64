.macro draw_string(x_pos, y_pos, string_var, string_address) {
    ldx #string_var.size() - 1
!loop_text:
    lda string_address, x
    sta DEFAULT_SCREEN_MEMORY + (40 * y_pos) + x_pos, x
    dex
    bpl !loop_text-
}

.macro draw_centered_string(y_pos, string_var, string_address) {
    .var x_pos = (40 - string_var.size() - 1) / 2
    :draw_string(x_pos, y_pos, string_var, string_address)
}

// I dislike how the built-in assertions always show in the output, so only run
// them if they fail. I also dislike the order of the arguments, so make them
// Python-like.
.macro my_assert(expression, message) {
    .if (!(expression)) {
        .assert message, 1, 0
    }
}

// I guess KickAss doesn't support modulo?
.function mod(a, b) {
    .var dividend = 0
    .while (a - dividend * b >= b) {
        .eval dividend = dividend + 1
    }
    .return a - dividend * b
}
