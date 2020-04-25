// vim: syntax=asm
#importonce

// I can never remember these
.macro blt(label) {
    bcc label
}
.macro bge(label) {
    bcs label
}
.macro bez(label) {
    beq label
}
.macro bnz(label) {
    bne label
}

// *********************
// C64/VIC/SID constants
// *********************

.const X_RESOLUTION = 320
.const Y_RESOLUTION = 200
.const X_CHARS = 40
.const Y_CHARS = 25

.const RUN_STOP_RESTORE_KEYS = $0328  // 808

.const DEFAULT_SCREEN_MEMORY = $0400  // 1024

.namespace RamRomLayout {
.label ADDRESS = $1
.label ENABLE_BASIC_MASK = %00000001
.label ENABLE_KERNAL_MASK = %00000010
.label ENABLE_CHAR_DISABLE_IO_MASK = %00000100
// The other bits are datasette stuff
.label DEFAULT = %00110111
.label DISABLE_ROMS = %00110000
}

.const CHARACTER_ROM = $D000  // 53248
.const SPRITE_TABLE_OFFSET = 1016
.const SPRITE_XY = $D000  // 53248
.function spriteX(spriteNumber) {
    .if (spriteNumber < 8) {
        .return spriteNumber * 2 + SPRITE_XY
    }
    .assert "Bad sprite number", 0, 1
}
.function spriteY(spriteNumber) {
    .if (spriteNumber < 8) {
        .return spriteNumber * 2 + SPRITE_XY + 1
    }
    .assert "Bad sprite number", 0, 1
}
.const SPRITE_X_EXTENDED = $D010  // 53264
// Screen control register
// bits 0-2: vertical raster scroll
// bit 3: screen height, 0 = 24 rows, 1 = 25 rows
// bit 4: screen enabled, 0 = off, 1 = on
// bit 5: background mode, 0 = text mode, 1 = bitmap mode
// bit 6: extended background mode, 1 = on
// bit 7: current raster line, bit #8. Use with $D012
.const SCREEN_CONTROL_1 = $D011  // 53265
.const RASTER_LINE = $D012  // 53266
.const SPRITE_ENABLE = $D015  // 53269
// Screen control bits
// 0-2: horizontal raster scroll
// 3: screen width: 0 = 38 columns, 1 = 40 columns
// 4: 1 = multicolor mode on
.const SCREEN_CONTROL_2 = $D016  // 53270
.const SPRITE_DOUBLE_HEIGHT = $D017  // 53271
// Memory control bits
// When in text screen mode, bits 1-3 * 2048 = start address of character set,
// bits 4-7 * 1024 = start address of screen character RAM
// When in bitmap mode, bit 3 indicates if bitmap begins at $0 or $2000, and
// bits 4-7  * 1-24 = start address of color information
.const MEMORY_SETUP = $D018  // 53272
.const SPRITE_PRIORITY = $D01B  // 53275
.const SPRITE_MULTICOLOR = $D01C  // 53276
.const SPRITE_DOUBLE_WIDTH = $D01D  // 53277
.const SPRITE_SPRITE_COLLISION = $D01E  // 53278
.const SPRITE_BACKGROUND_COLLISION = $D01F  // 53279
.const BORDER_COLOR = $D020  // 53280
.const BACKGROUND_COLOR = $D021  // 53281 normal mode
.const BACKGROUND_EXTRA_COLOR_1 = $D022  // 53282 multicolor and extended modes
.const BACKGROUND_EXTRA_COLOR_2 = $D023  // 53283 multicolor and extended modes
.const BACKGROUND_EXTRA_COLOR_3 = $D024  // 53284 extended color mode
.const SPRITE_EXTRA_COLOR_1 = $D025  // 53285 multicolor mode
.const SPRITE_EXTRA_COLOR_2 = $D026  // 53286 multicolor mode
.const SPRITE_0_COLOR = $D027  // 53287
.function spriteColor(spriteNumber) {
    .if (spriteNumber < 8) {
        .return SPRITE_0_COLOR + spriteNumber
    }
    .assert "Bad sprite number", 0, 1
}
.const CHAR_0_COLOR = $D800  // 55296
.function charColor(charNumber) {
    .if (charNumber < X_CHARS * Y_CHARS) {
        .return CHAR_0_COLOR + charNumber
    }
    .assert "Bad char number", 0, 1
}
// Keyboard matrix columns and joystick #2
// Bits are cleared (set to 0!) when joystick pressed
// 0 = up, 1 = down, 2 = left, 3 = right, 4 = fire
.const JOYSTICK_2 = $DC00  // 56320
// Keyboard matrix rows and joystick #1
.const JOYSTICK_1 = $DC01  // 56321
// Port A, serial bus access bits
// 0-1: VIC bank.
//    0 = Bank #3 $C000-$FFFF, 1 = Bank #2 $8000-$BFFF
//    2 = Bank #1 $4000-$7FFF, 3 = Bank #0 $0000-$3FFF
// 2: RS232 TXD line output bit
// 3: Serial bus ATN OUT, 0 = HIGH, 1 = LOW
// 4: Serial bus CLOCK OUT, 0 = HIGH, 1 = LOW
// 5: Serial bus DATA OUT, 0 = HIGH, 1 = LOW
// 6: Serial bus CLOCK IN, 0 = LOW, 1 = HIGH
// 7: Serial bus DATA IN, 0 = LOW, 1 = HIGH
.const VIC_BANK_SETUP = $DD00  // 56576
.const PORT_A = $DD00  // 56576


// **********************************
// Memory variable location constants
// **********************************
.const SCREEN_CHAR = $CC00  // 52224
.const ZEROPAGE_POINTER_1 = $17
.const ZEROPAGE_POINTER_2 = $19
.const PARAM_1 = $03
.const PARAM_2 = $04
.const PARAM_3 = $05
.const PARAM_4 = $06
.const NUMBER_OF_SPRITES = 11  // This is number of sprites defined in Sprite Pad
.const SPRITE_PLAYER = 64
.const SPRITE_POINTER_BASE = SCREEN_CHAR + SPRITE_TABLE_OFFSET
