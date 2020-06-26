#importonce

.namespace RunGameState {

// **** Constants ****
.const _colon_column = 19
.const _press_return_row = 15
.const _time_row = 16
.const _weather_row = 17
.const _mood_row = 18
.const _next_landmark_row = 19
.const _miles_travelled_row = 20

.enum {
    PlayerMood_Crusty = 1,
    PlayerMood_Excited = 2,
    PlayerMood_Tired = 3,
    PlayerMood_Exhausted = 4
}

.enum {
    NextLandmark_Wadsworth = 0,
    NextLandmark_Gerlach = 1,
    NextLandmark_Gate = 2,
    NextLandmark_Brc = 3,
    NextLandmark_Initial = 255
}
_landmark_distance:
    .byte 29
    .byte 29 + 78
    .byte 29 + 78 + 8
    .byte 29 + 78 + 8 + 5

// We store gate wait times in 2 hour chunks
_wait_time_hours_by_2_hour_intervals:
    .byte 2  // -24
    .byte 2  // -22
    .byte 2  // -20
    .byte 1  // -18
    .byte 1  // -16
    .byte 1  // -14
    .byte 2  // -12
    .byte 2  // -10
    .byte 2  // -8
    .byte 3  // -6
    .byte 3  // -4
    .byte 2  // -2
    .byte 2  // 0
    .byte 2  // 2
    .byte 3  // 4
    .byte 3  // 6
    .byte 4  // 8
    .byte 4  // 10
    .byte 4  // 12
    .byte 3  // 14
    .byte 5  // 16
    .byte 3  // 18
    .byte 3  // 20
    .byte 2  // 22
    .byte 3  // 24
    // Pretty much everything after this is 2, except for a dip at 38

// **** Variables ****
_player_mood: .byte PlayerMood_Excited
_miles_travelled: .byte 0
_miles_to_next_landmark: .byte 29
_next_landmark: .byte NextLandmark_Wadsworth

// **** Subroutines ****
initialize: {
    jsr clear_screen
    jsr _draw_information_background

    // **** Set up the sprites ****

    lda SPRITE_ENABLE
    ora #%00000011
    sta SPRITE_ENABLE

    // Load the car sprite offset into a
    ldy GameState.player_type
    cpy Player_Billionaire
    bne !next+
    lda #4
    jmp set_sprite_pointers
!next:
    cpy Player_VeteranBurner
    bne !next+
    lda #2
    jmp set_sprite_pointers
!next:
    lda #0
set_sprite_pointers:

    // Once we have the offset, set the pointer
    clc
    adc #(SPRITE_DATA / 64)
    sta SPRITE_POINTER_BASE + 0
    adc #1
    sta SPRITE_POINTER_BASE + 1

.const sprite_x_base = 280
    lda #sprite_x_base
    sta sprite_x(0)
    lda #sprite_x_base + 24
    sta sprite_x(1)

.var x_extended = 0
.if (sprite_x_base > 255) {
    .eval x_extended = 1
}
.if (sprite_x_base + 24 > 255) {
    .eval x_extended = x_extended | %10
}
.if (x_extended != 0) {
    lda #x_extended
    sta SPRITE_X_EXTENDED
}

done:
    rts
}


tick: {
    jsr _animate
    lda #0
    rts
}


_animate: {
    jsr ripple_colors

    // We draw a 2-second cycle: 1 second of animation, 1 second off
    ldy timer
    cpy #60
    bcc animate

    // Pause for 1 second
    cpy #120
    bcc done
    ldy #0
    sty timer

    jmp done

    // Animate the car up and down
animate:

.const sprite_y_base = 120
    tya  // Load timer into a
    and #%00001000
    lsr
    clc
    adc #sprite_y_base
    sta sprite_y(0)
    sta sprite_y(1)

done:
    inc timer
    rts

timer: .byte 0
}


_draw_information_background: {
.var press_return = "press return to size up the situation"
.var time = "time:"
.var weather = "weather:"
.var mood = "mood:"
.var bladder = "bladder:"
.var next_landmark = "next landmark:"
.var miles_travelled = "miles travelled:"
    // Information should be on the lower half of the screen

    :draw_string(_colon_column - miles_travelled.size(), _miles_travelled_row, miles_travelled, _miles_travelled)
    :draw_string(_colon_column - time.size(), _time_row, time, _time)
    :draw_string(_colon_column - weather.size(), _weather_row, weather, _weather)
    :draw_string(_colon_column - mood.size(), _mood_row, mood, _mood)
    :draw_string(_colon_column - next_landmark.size(), _next_landmark_row, next_landmark, _next_landmark)
    :draw_string(_colon_column - miles_travelled.size(), _miles_travelled_row, miles_travelled, _miles_travelled)

    rts

_time: .text time
_weather: .text weather
_mood: .text mood
_next_landmark: .text next_landmark
_miles_travelled: .text miles_travelled
}


_draw_information: {
.var saturday = "sat"
.var sunday = "sun"
.var monday = "mon"

.var clear = "clear"

.var crusty = "crusty"
.var excited = "excited"
.var tired = "tired"
.var exhausted = "exhausted"

.var miles = "miles"

    // ***** Show the time *****
    lda GameState.time_hours
    // We store hours as total hours since since day before gate open, Saturday 12:01 AM
    cmp #48
    bcc before_monday
    :draw_string(_colon_column + 1, _time_row, monday, _monday)
    lda GameState.time_hours
    sec
    sbc #48
    jmp !done+
before_monday:
    cmp #24
    bcc before_sunday
    :draw_string(_colon_column + 1, _time_row, sunday, _sunday)
    lda GameState.time_hours
    sec
    sbc #24
    jmp !done+
before_sunday:
    :draw_string(_colon_column + 1, _time_row, saturday, _saturday)
    lda GameState.time_hours
!done:

    // a should now have hours % 24
    cmp #20
    bcc !under_20+
    ldx #'2'
    sec
    sbc #20
    jmp !done+
!under_20:
    cmp #10
    bcc !under_10+
    sec
    sbc #10
    ldx #'1'
    jmp !done+
!under_10:
    ldx #'0'
!done:
    .const after_day_x_position = _colon_column + saturday.size() + 2
    stx screen_memory(after_day_x_position, _time_row)

    // a should now have hours % 10
    clc
    adc #'0'
    sta screen_memory(after_day_x_position + 1, _time_row)

    // Now let's do minutes
    // This colon should probably be drawn with the background
    lda #':'
    sta screen_memory(after_day_x_position + 2, _time_row)

    lda GameState.time_minutes
    ldx #0
!over_10:
    cmp #10
    bcc !under_10+
    sec
    sbc #10
    inx
    jmp !over_10-
!under_10:
    tay
    txa
    clc
    adc #'0'
    sta screen_memory(after_day_x_position + 3, _time_row)

    tya
    // a should now have minutes % 10
    clc
    adc #'0'
    sta screen_memory(after_day_x_position + 4, _time_row)

    // ***** Show the weather *****
    :draw_string(_colon_column + 1, _weather_row, clear, _clear)

    // ***** Show the mood *****
    lda _player_mood
    cmp PlayerMood_Crusty
    bne !next+
    :draw_string(_colon_column + 1, _mood_row, crusty, _crusty)
    jmp done
!next:
    cmp PlayerMood_Excited
    bne !next+
    :draw_string(_colon_column + 1, _mood_row, excited, _excited)
    jmp done
!next:
    cmp PlayerMood_Tired
    bne !next+
    :draw_string(_colon_column + 1, _mood_row, tired, _tired)
    jmp done
!next:
    :draw_string(_colon_column + 1, _mood_row, exhausted, _exhausted)
done:

    // ***** Show the next landmark *****
    // This is always under 100
    lda _miles_to_next_landmark
    ldx #0
!over_10:
    cmp #10
    bcc !under_10+
    sec
    sbc #10
    inx
    jmp !over_10-
!under_10:
    tay
    txa
    clc
    adc #'0'
    sta screen_memory(_colon_column + 1, _next_landmark_row)

    tya
    // a should now have miles % 10
    clc
    adc #'0'
    sta screen_memory(_colon_column + 2, _next_landmark_row)

    // This should probably be drawn with the background
    :draw_string(_colon_column + 4, _next_landmark_row, miles, _miles)

    // ***** Show the miles travelled *****
    lda _miles_travelled
    // The max here is 115 miles
    cmp #100
    bcc !under_100+
    sec
    sbc #100
    ldx #'1'
    jmp !next+
!under_100:
    ldx #'0'
!next:
    stx screen_memory(_colon_column + 1, _miles_travelled_row)

    ldx #0
!over_10:
    cmp #10
    bcc !under_10+
    sec
    sbc #10
    inx
    jmp !over_10-
!under_10:
    tay
    txa
    clc
    adc #'0'
    sta screen_memory(_colon_column + 2, _miles_travelled_row)

    tya
    // a should now have miles % 10
    clc
    adc #'0'
    sta screen_memory(_colon_column + 3, _miles_travelled_row)

    // This should probably be drawn with the background
    :draw_string(_colon_column + 5, _miles_travelled_row, miles, _miles)

    rts

_saturday: .text saturday
_sunday: .text sunday
_monday: .text monday

_clear: .text clear

_excited: .text excited
_tired: .text tired
_exhausted: .text exhausted
_crusty: .text crusty

_miles: .text miles
}


_draw_information_popup: {
    // ZEROPAGE_POINTER_1 is text part 1.
    // PARAM_1 is x length of text part 1.
    // ZEROPAGE_POINTER_2 is text part 2.
    // PARAM_2 is x length of text part 2.
    // We always put the first string as the longer one.

    // Find the x starting point, which is midpoint - half of length
    lda #40
    sec
    sbc PARAM_1
    lsr
    sta PARAM_3  // PARAM_3 = halfway - (x / 2) = (whole - x) / 2

    // Draw the top and bottom borders
.const border_row = 10
.const upper_border_row_memory = screen_memory(0, border_row)
.const lower_border_row_memory = screen_memory(0, border_row + 3)
    tax
    dex
    lda #$55  // Upper left rounded corner
    sta upper_border_row_memory, x
    lda #$4A  // Lower left rounded corner
    sta lower_border_row_memory, x
    lda #$43  // Horizontal bar
    inx
    ldy #0
!repeat:
    sta upper_border_row_memory, x
    sta lower_border_row_memory, x
    inx
    iny
    cpy PARAM_1
    bcc !repeat-
    lda #$49  // Upper right rounded corner
    sta upper_border_row_memory, x
    lda #$4B  // Lower right rounded corner
    sta lower_border_row_memory, x

    // Draw the first line of text
.const text_row_memory_1 = screen_memory(0, border_row + 1)
    .break
    ldx PARAM_3
    dex
    lda #$5D  // Vertical bar
    sta text_row_memory_1, x
    inx
    ldy #0
!repeat:
    lda (ZEROPAGE_POINTER_1), y
    sta text_row_memory_1, x
    inx
    iny
    cpy PARAM_1
    bcc !repeat-
    lda #$5D  // Vertical bar
    sta text_row_memory_1, x

    // Draw the second line of text
.const text_row_memory_2 = screen_memory(0, border_row + 2)
    // Draw the second vertical bar first. We know that line 1 is longer than
    // line 2, and x is currently pointing at the correct offset, so just write
    // it now.
    lda #$5D  // Vertical bar
    sta text_row_memory_2, x
    ldx PARAM_3
    dex
    sta text_row_memory_2, x
    inx
    ldy #0
!repeat:
    lda (ZEROPAGE_POINTER_2), y
    sta text_row_memory_2, x
    inx
    iny
    cpy PARAM_2
    bcc !repeat-
    // The second vertical bar was already drawn above

    rts
}
.macro _call_draw_information_popup(string_1, string_1_address, string_2, string_2_address) {
    :my_assert(string_1.size() <= 38, "string_1 is too long")
    :my_assert(string_2.size() <= 38, "string_2 is too long")
    :my_assert(string_1.size() >= string_2.size(), "string_1 should be longer than string_2")
    lda #string_1.size()
    sta PARAM_1
    lda #string_2.size()
    sta PARAM_2
    lda #<string_1_address
    sta ZEROPAGE_POINTER_1
    lda #>string_1_address
    sta ZEROPAGE_POINTER_1 + 1
    lda #<string_2_address
    sta ZEROPAGE_POINTER_2
    lda #>string_2_address
    sta ZEROPAGE_POINTER_2 + 1
    jsr _draw_information_popup
}


_get_wait_time: {
    lda GameState.time_hours
    cmp #50
    bcs over_50
    lsr
    tax
    lda _wait_time_hours_by_2_hour_intervals
    rts
over_50:
    // There's a small dip at 38
    cmp #24 + 38
    beq equal_24_38
    lda #2
    rts
equal_24_38:
    lda #1
    rts
}

}  // End namespace
