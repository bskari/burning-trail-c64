#importonce

.namespace RunGameState {

// **** Constants ****
.const _colon_column = 19
.const _time_row = 15
.const _weather_row = 16
.const _mood_row = 17
.const _bladder_row = 18
.const _next_landmark_row = 19
.const _miles_travelled_row = 20

// **** Subroutines ****
initialize: {
    jsr clear_screen
    jsr _draw_information_background
    rts
}


tick: {
    jsr ripple_colors
    jsr _draw_information

    lda #0
    rts
}


_draw_information_background: {
.var time = "time:"
.var weather = "weather:"
.var mood = "mood:"
.var bladder = "bladder:"
.var next_landmark = "next landmark:"
.var miles_travelled = "miles travelled:"
.var press_space = "press space bar to continue"
    // Information should be on the lower half of the screen

    :draw_string(_colon_column - time.size(), _time_row, time, _time)
    :draw_string(_colon_column - weather.size(), _weather_row, weather, _weather)
    :draw_string(_colon_column - mood.size(), _mood_row, mood, _mood)
    :draw_string(_colon_column - bladder.size(), _bladder_row, bladder, _bladder)
    :draw_string(_colon_column - next_landmark.size(), _next_landmark_row, next_landmark, _next_landmark)
    :draw_string(_colon_column - miles_travelled.size(), _miles_travelled_row, miles_travelled, _miles_travelled)

    :draw_centered_string(24, press_space, _press_space)
    rts

_time: .text time
_weather: .text weather
_mood: .text mood
_bladder: .text bladder
_next_landmark: .text next_landmark
_miles_travelled: .text miles_travelled
_press_space: .text press_space
}


_draw_information: {
.var saturday = "sat"
.var sunday = "sun"
.var monday = "mon"

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

    rts

_saturday: .text saturday
_sunday: .text sunday
_monday: .text monday
}

}  // End namespace
