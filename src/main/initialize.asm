#importonce

// Initialization macros
// I don't think you can put macros in a namespace, so we need to do C-style
// namespacing

.macro initialize_sprites() {
    // Initialize sprite registers
    // No visible sprites
    lda #0
    sta SPRITE_ENABLE

    // Turn on multicolor sprites
    lda #%11111111
    sta SPRITE_MULTICOLOR
}

.macro initialize_set_charset() {
    // Set charset
    // Character RAM VIC bank address offset = %0011 * 1024 = 3072 = 0xC00
    // Character set RAM VIC bank address offset = %110 * 2048 = 12288 = 0x3000
    lda #%0011_1100
    sta GRAPHICS_SETUP

    // Set VIC bank to $C000-$FFFF
    lda VIC_BANK_SETUP
    and #%11111100
    sta VIC_BANK_SETUP
}

.macro initialize_disable_run_stop_keys() {
    // Disable run/stop and restore keys
    lda #%11111100
    sta RUN_STOP_RESTORE_KEYS
}

.macro initialize_screen() {
.const SCREEN_CONTROL_1_CONFIG = (
    %0
    | %00000111  // Vertical raster scroll, lower 3 bits
    | %00000000  // 24 rows (25 rows off)
    | %00010000  // Screen on
)
    lda #SCREEN_CONTROL_1_CONFIG
    sta SCREEN_CONTROL_1
.const SCREEN_CONTROL_2_CONFIG = (
    %0
    | %00000000  // Horizontal raster scroll, lower 3 bits
    | %00001000  // 40 columns
    | %00010000  // Multicolor mode
)
    lda #SCREEN_CONTROL_2_CONFIG
    sta SCREEN_CONTROL_2
}

.macro initialize_turn_off_roms() {
    :initialize_disable_roms()
    :initialize_enable_roms()
}

.macro initialize_disable_roms() {
    // Block interrupts while we turn off ROMs so that we don't jump to
    // uninitialized RAM and crash
    sei

    // Save old configuration
    lda RamRomLayout.ADDRESS
    pha

    // Turn off all ROM banks so that we only have RAM
    lda #RamRomLayout.DISABLE_ROMS
    sta RamRomLayout.ADDRESS
}


.macro initialize_enable_roms() {
    // Restore the ROM
    pla
    sta RamRomLayout.ADDRESS

    // Reenable interrupts
    cli
}
