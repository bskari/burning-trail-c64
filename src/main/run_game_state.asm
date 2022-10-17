#importonce

.namespace RunGameState {

// **** Constants ****
.const _colon_column = 19
.const _press_return_row = 18
.const _time_row = _press_return_row + 1

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

    // We use these to decide when to start showing the next landmark
_landmark_sprite_offset:
    .byte 0
_landmark_sprite_offset_start:
    .byte 

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
_timer: .byte 0  // Animation timer
_player_mood: .byte PlayerMood_Excited
_miles_travelled: .byte 0
_next_landmark: .byte NextLandmark_Wadsworth
_waiting_for_input: .byte 0
_size_up_the_situation: .byte 0

// **** Subroutines ****
initialize: {
    jsr clear_screen
    jsr _draw_information_background
    jsr _draw_highway

    // Set up raster interrupt, top half white, bottom black
    sei
    // Enable raster interrupt signals from VIC
    lda #%0000_0001
    sta INTERRUPT_CONTROL_3   // $D01A
    lda #<irq_handler
    sta $FFFE
    lda #>irq_handler
    sta $FFFF
    // We don't need to set the raster line, just use whatever it's currently
    // set to - we'll reset it in top_irq_handler anyway
    cli

    // Set the bottom half of text to be black
    lda #BLACK
    ldx #250
!repeat:
    dex
    // These 2 stas will overlap some, but that's fine
    sta CHAR_0_COLOR + 1000 - 10 * 40, x
    sta CHAR_0_COLOR + 750, x
    bne !repeat-

    // Set the "press enter" text part of the screen to be white
    lda #WHITE
    ldx #40
!repeat:
    dex
    sta CHAR_0_COLOR + 40 * _press_return_row, x
    bne !repeat-


    // **** Set up the sprites ****

    lda SPRITE_ENABLE
    ora #%00000011
    sta SPRITE_ENABLE

    // Road sign
    lda #80
    sta sprite_y(2)

    // Load the car sprite offset into A
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

    jsr _update_next_landmark_sprite

    jsr _draw_information

done:
    rts
}


tick: {
    // Check for return, to size up the situation
    lda #%1111_1110
    sta PARAM_1
    lda #%0000_0010
    sta PARAM_2
    jsr read_keyboard_press
    // If no keys were pressed, the carry flag will be clear
    bcc !continue+
    lda #1
    sta _size_up_the_situation
    inc BORDER_COLOR

!continue:
    jsr _animate

    // We only want to size up the situation after the animation
    // has stopped. The first 60 frames are animated.
    lda _timer
    cmp #65
    bcc return

    lda _size_up_the_situation
    beq return
    lda #GameState_SizeUp
    sec // Carry indicates a state change to whatever's in A
    rts

return:
    clc
    rts
}

_animate: {
    lda _waiting_for_input
    beq !continue+
    // Check for space
    lda #%0111_1111
    sta PARAM_1
    lda #%0001_0000
    sta PARAM_2
    jsr read_keyboard_press
    // If no keys were pressed, the carry flag will be clear
    bcc clear_screen_and_redraw
    rts
clear_screen_and_redraw:
    jsr clear_screen
    jsr _draw_information_background
    jsr _draw_highway
    jsr _draw_information

    // Disable the landmark
    lda SPRITE_ENABLE
    and #%1111_1011
    sta SPRITE_ENABLE

    lda #0
    sta _waiting_for_input
!continue:

    // We draw a 2-second cycle: 1 second of animation, 1 second off
    ldy _timer
    cpy #60
    bcc animate
    bne skip_update

    // We only need to update the information periodically, like how the Oregon
    // Trail game did
    jsr _update_state
    // If we reached a landmark, tell them the next landmark
    bcc no_landmark_reached
    jsr _draw_information
    jsr _popup_next_landmark
    lda #1
    sta _waiting_for_input
    rts

no_landmark_reached:
    jsr _draw_information
    ldy _timer
skip_update:

    // Pause for 1 second
    cpy #120
    bcc done
    ldy #0
    sty _timer
    jmp done

    // Animate the car up and down, and any upcoming signs
animate:

.const car_y_base = 90
    tya  // Load timer into A
    and #%00001000
    lsr
    clc
    adc #car_y_base
    sta sprite_y(0)
    sta sprite_y(1)

    jsr _update_next_landmark_sprite

done:
    inc _timer
    rts
}

// Sets the data needed for the next landmark sprite, including X and Y
// offsets, enabling or disabling the landmark if it's offscreen, and setting
// the sprite pointer. This does more work than necessary when animating per
// frame, but I'm not time constrained, so who cares.
_update_next_landmark_sprite: {
    // We only update the distance after each animation (~2 seconds), but the
    // sign should be moving faster. So only start drawing the sign when we're
    // close.
    lda _miles_travelled
    sta $10  // Arbitrarily chosen
    ldx _next_landmark
    lda _landmark_distance, x
    sec
    sbc $10

    // Don't start drawing the sign unless we're within 20 miles
    cmp #50
    bcc continue

disable:
    lda #50
    sta _landmark_sprite_offset
    lda #%1111_1011
    and SPRITE_ENABLE
    sta SPRITE_ENABLE
    rts

continue:
    // Set the sprite
    lda #7 + (SPRITE_DATA / 64)
    sta SPRITE_POINTER_BASE + 2
    lda #GREEN
    sta sprite_color(2)

    lda _landmark_sprite_offset
    sta sprite_x(2)
    lda SPRITE_ENABLE
    ora #%00000100
    sta SPRITE_ENABLE

    // Just move it part time
    lda #0000_0001
    bit _timer
    beq return

    inc _landmark_sprite_offset

return:
    rts
}

.var time = "time:"
_draw_information_background: {
.var press_return = "press return to size up the situation"
    :draw_string(1, _press_return_row, press_return, _press_return)

    // Information should be on the lower half of the screen
    lda #>screen_memory(_colon_column - 5, _time_row)
    sta ZEROPAGE_POINTER_1 + 1
    lda #<screen_memory(_colon_column - 5, _time_row)
    sta ZEROPAGE_POINTER_1

    jmp draw_information_background
_press_return: .text press_return
}


// Draws the information backgrund starting at the position
// stored in ZEROPAGE_POINTER_1
draw_information_background: {
.var weather = "weather:"
.var mood = "mood:"
.var next_landmark = "next landmark:"
.var miles_travelled = "miles travelled:"

    :draw_string_zeropage_pointer_1(time, _time)

    ldx #40 + time.size() - weather.size()
    stx PARAM_1
    jsr _add_param_1_to_zeropage_pointer
    :draw_string_zeropage_pointer_1(weather, _weather)

    ldx #40 + weather.size() - mood.size()
    stx PARAM_1
    jsr _add_param_1_to_zeropage_pointer
    :draw_string_zeropage_pointer_1(mood, _mood)

    ldx #40 + mood.size() - next_landmark.size()
    stx PARAM_1
    jsr _add_param_1_to_zeropage_pointer
    :draw_string_zeropage_pointer_1(next_landmark, _next_landmark)

    ldx #40 + next_landmark.size() - miles_travelled.size()
    stx PARAM_1
    jsr _add_param_1_to_zeropage_pointer
    :draw_string_zeropage_pointer_1(miles_travelled, _miles_travelled)

    rts

_time: .text time
_weather: .text weather
_mood: .text mood
_next_landmark: .text next_landmark
_miles_travelled: .text miles_travelled
}


_draw_information: {
    lda #>screen_memory(_colon_column + 1, _time_row)
    sta ZEROPAGE_POINTER_1 + 1
    lda #<screen_memory(_colon_column + 1, _time_row)
    sta ZEROPAGE_POINTER_1

    // Fall through to draw_information
    // jmp draw_information
}


// Draws the information starting at the position stored in
// ZEROPAGE_POINTER_1
draw_information: {
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
    :draw_string_zeropage_pointer_1(monday, _monday)
    lda GameState.time_hours
    // Carry should be set
    sbc #48
    jmp !done+
before_monday:
    cmp #24
    bcc before_sunday
    :draw_string_zeropage_pointer_1(sunday, _sunday)
    lda GameState.time_hours
    // Carry should be set
    sbc #24
    jmp !done+
before_sunday:
    :draw_string_zeropage_pointer_1(saturday, _saturday)
    lda GameState.time_hours
!done:

    // a should now have hours % 24
    cmp #20
    bcc !under_20+
    ldx #'2'
    // Carry should be set
    sbc #20
    jmp !done+
!under_20:
    cmp #10
    bcc !under_10+
    // Carry should be set
    sbc #10
    ldx #'1'
    jmp !done+
!under_10:
    ldx #'0'
!done:

    ldy #saturday.size() + 1
    pha
    txa
    sta (ZEROPAGE_POINTER_1), y
    pla

    // a should now have hours % 10
    clc
    adc #'0'
    iny
    sta (ZEROPAGE_POINTER_1), y

    // Now let's do minutes
    // TODO: This colon should probably be drawn with the background
    lda #':'
    iny
    sta (ZEROPAGE_POINTER_1), y

    lda GameState.time_minutes
    ldx #0
!over_10:
    cmp #10
    bcc !under_10+
    // We know carry is set now, otherwise we would have branched
    sbc #10
    inx
    jmp !over_10-
!under_10:
    pha
    txa
    // Carry should be clear
    adc #'0'
    iny
    sta (ZEROPAGE_POINTER_1), y
    pla

    // a should now have minutes % 10
    clc
    adc #'0'
    iny
    sta (ZEROPAGE_POINTER_1), y

    // ***** Show the weather *****
    lda ZEROPAGE_POINTER_1
    // Carry should be clear
    adc #40
    sta ZEROPAGE_POINTER_1
    bcc !no_carry+
    inc ZEROPAGE_POINTER_1 + 1
!no_carry:
    :draw_string_zeropage_pointer_1(clear, _clear)

    // ***** Show the mood *****
    lda ZEROPAGE_POINTER_1
    clc
    adc #40
    sta ZEROPAGE_POINTER_1
    bcc !no_carry+
    inc ZEROPAGE_POINTER_1 + 1
!no_carry:

    lda _player_mood
    cmp PlayerMood_Crusty
    bne !next+
    :draw_string_zeropage_pointer_1(crusty, _crusty)
    jmp done
!next:
    cmp PlayerMood_Excited
    bne !next+
    :draw_string_zeropage_pointer_1(excited, _excited)
    jmp done
!next:
    cmp PlayerMood_Tired
    bne !next+
    :draw_string_zeropage_pointer_1(tired, _tired)
    jmp done
!next:
    :draw_string_zeropage_pointer_1(exhausted, _exhausted)
done:

    // ***** Show the next landmark *****
    lda ZEROPAGE_POINTER_1
    clc
    adc #40
    sta ZEROPAGE_POINTER_1
    bcc !no_carry+
    inc ZEROPAGE_POINTER_1 + 1
!no_carry:

    // Miles to next landmark is always under 100
    ldx _next_landmark
    lda _landmark_distance, x
    sec
    sbc _miles_travelled
    ldx #0
!over_10:
    cmp #10
    bcc !under_10+
    // Carry should be set
    sbc #10
    inx
    jmp !over_10-
!under_10:
    pha
    txa
    // Carry should be clear
    adc #'0'
    ldy #0
    sta (ZEROPAGE_POINTER_1), y
    pla

    // a should now have miles % 10
    // Carry should be clear
    adc #'0'
    iny
    sta (ZEROPAGE_POINTER_1), y

    // TODO: This should probably be drawn with the background
    lda ZEROPAGE_POINTER_1
    clc
    adc #3
    sta ZEROPAGE_POINTER_1
    bcc !no_carry+
    inc ZEROPAGE_POINTER_1 + 1
!no_carry:
    :draw_string_zeropage_pointer_1(miles, _miles)

    // ***** Show the miles travelled *****
    lda ZEROPAGE_POINTER_1
    clc
    adc #40 - 3
    sta ZEROPAGE_POINTER_1
    bcc !no_carry+
    inc ZEROPAGE_POINTER_1 + 1
!no_carry:

    lda _miles_travelled
    // The max here is 115 miles
    cmp #100
    bcc !under_100+
    // Carry should be set
    sbc #100
    ldx #'1'
    jmp !next+
!under_100:
    ldx #'0'
!next:
    pha
    txa
    ldy #0
    sta (ZEROPAGE_POINTER_1), y
    pla

    ldx #0
!over_10:
    cmp #10
    bcc !under_10+
    // Carry should be set
    sbc #10
    inx
    jmp !over_10-
!under_10:
    pha
    txa
    // Carry should be clear
    adc #'0'
    ldy #1
    sta (ZEROPAGE_POINTER_1), y
    pla

    // a should now have miles % 10
    // Carry should be clear
    adc #'0'
    ldy #2
    sta (ZEROPAGE_POINTER_1), y

    // TODO: This should probably be drawn with the background
    // This should probably be drawn with the background
    lda ZEROPAGE_POINTER_1
    clc
    adc #4
    sta ZEROPAGE_POINTER_1
    bcc !no_carry+
    inc ZEROPAGE_POINTER_1 + 1
!no_carry:
    :draw_string_zeropage_pointer_1(miles, _miles)

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


_add_param_1_to_zeropage_pointer: {
    lda ZEROPAGE_POINTER_1
    clc
    adc PARAM_1
    sta ZEROPAGE_POINTER_1
    bcc !no_carry+
    inc ZEROPAGE_POINTER_1 + 1
!no_carry:
    rts
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
.const border_row = 11
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


_draw_highway: {
.const row = 2
.const offset = 40 * row + 25
    ldx #-40
    lda #$43  // Dash
!repeat:
    // Draw two lines at a time, then two blanks
    sta DEFAULT_SCREEN_MEMORY + offset, x
    inx
    sta DEFAULT_SCREEN_MEMORY + offset, x
    inx
    inx
    inx
    bmi !repeat-

    ldx #-40
    lda #YELLOW
!repeat:
    // Draw two lines at a time, then two blanks
    sta CHAR_0_COLOR + offset, x
    inx
    sta CHAR_0_COLOR + offset, x
    inx
    inx
    inx
    bmi !repeat-

    rts
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


// Updates the game state. Sets carry if a landmark was reached.
_update_state: {
.const minutes_increment = 5
    // Update the time
    lda GameState.time_minutes
    clc
    adc #minutes_increment
    cmp #60
    bcc !continue+
    inc GameState.time_hours
:my_assert(mod(60, minutes_increment) == 0, "bad minutes increment")
    lda #0
!continue:
    sta GameState.time_minutes

    // Update the distance travelled
    // Our speed depends on where we are: highway? gate?
    lda _next_landmark
    cmp #NextLandmark_Gate
    bcs not_highway
    // Speed limit is 65 MPH, so just round down and call it 60 MPH
    lda _miles_travelled
    // Carry is already clear
    adc #minutes_increment
    jmp check_next_landmark
not_highway:
    // TODO: Other slower speeds
    inc _miles_travelled
    lda _miles_travelled

check_next_landmark:
    // Are we at the next landmark? a has _miles_travelled
    sta PARAM_1  // Temp
    ldx _next_landmark
    lda _landmark_distance, x
    cmp PARAM_1
    bcs not_reached_landmark
    // If we are, just set the miles traveled to it
    sta _miles_travelled
    inc _next_landmark
    sec
    rts
not_reached_landmark:
    lda PARAM_1
    sta _miles_travelled
    clc
!continue:

    rts
}


// Draws a popup with information about distance to the next landmark
_popup_next_landmark: {
.var press_space = "press space bar to continue"
    :draw_centered_string(24, press_space, _press_space)
    lda _next_landmark
    :my_assert(NextLandmark_Wadsworth == 0, "unexpected enum value")
    bne !next+
    // We need to jump to a location instead of just calling the macro because
    // bne has a limit to how far it can jump, and the macro makes it too long
    jmp _draw_popup_1
!next:
    cmp #NextLandmark_Gerlach
    bne !next+
    jmp _draw_popup_2
!next:
    cmp #NextLandmark_Gate
    bne !next+
    jmp _draw_popup_3
!next:
.var message_4_1 = "home stretch! just 5 more" 
.var message_4_2 = "miles to go via gate road"
    :_call_draw_information_popup(message_4_1, _message_4_1, message_4_2, _message_4_2)
    rts

.var message_1_1 = "from reno it is 29 miles east"
.var message_1_2 = "to wadsworth via i-80"
.var message_2_1 = "from wadsworth it is 78 miles"
.var message_2_2 = "north to gerlach via nv-447"
.var message_3_1 = "from gerlach it is 8"
.var message_3_2 = "miles to gate road"

_draw_popup_1:
    :_call_draw_information_popup(message_1_1, _message_1_1, message_1_2, _message_1_2)
    rts
_draw_popup_2:
    :_call_draw_information_popup(message_2_1, _message_2_1, message_2_2, _message_2_2)
    rts
_draw_popup_3:
    :_call_draw_information_popup(message_3_1, _message_3_1, message_3_2, _message_3_2)
    rts

_message_1_1: .text message_1_1
_message_1_2: .text message_1_2
_message_2_1: .text message_2_1
_message_2_2: .text message_2_2
_message_3_1: .text message_3_1
_message_3_2: .text message_3_2
_message_4_1: .text message_4_1
_message_4_2: .text message_4_2
_press_space: .text press_space
}


// Split the screen into different background color horizontal strips
irq_handler: {
.var _colors = List().add(BLACK, GRAY, BLACK, BLACK, WHITE)
.var _lines = List().add(105, 129, 192, 201, 0)

    pha
    txa
    pha

    // By the time we set the BACKGROUND_COLOR below, we've already rendered
    // part of the screen, which makes the color tear, and because of bad
    // lines, it also wiggles. So burn some time until the render beam is in
    // the border.
    ldx #20
burn_time:
    dex
    bne burn_time

    ldx index
    lda colors, x
    sta BACKGROUND_COLOR

    lda lines, x
    sta RASTER_LINE_INTERRUPT

    dec index
    bpl continue
    lda #_colors.size() - 1
    sta index
continue:

    // Acknowledge the interrupt
    inc $D019
    pla
    tax
    pla
    rti

index: .byte _colors.size() - 1
// We store the list of colors in reverse order, so we can dec and use bpl
// instead of having an additional cmp
colors:
.for (var i = _colors.size() - 1; i >= 0; i--) {
    .byte _colors.get(i)
}
lines:
.for (var i = _lines.size() - 1; i >= 0; i--) {
    .byte _lines.get(i)
}
}


}  // End namespace
