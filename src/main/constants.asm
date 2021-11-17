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

.const INTERRUPT_SUBROUTINE_ADDRESS = $0314

.const CHARACTER_ROM = $D000  // 53248
.const SPRITE_TABLE_OFFSET = 1016
.const SPRITE_XY = $D000  // 53248
.function sprite_x(sprite_number) {
    .if (sprite_number < 8) {
        .return sprite_number * 2 + SPRITE_XY
    }
    .assert "Bad sprite number", 0, 1
}
.function sprite_y(sprite_number) {
    .if (sprite_number < 8) {
        .return sprite_number * 2 + SPRITE_XY + 1
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
// Set this to generate an interrupt on a specific raster line
.const RASTER_LINE_INTERRUPT = $D012  // 53266
// Or read it to find the current raster line
.const RASTER_LINE = $D012  // 53266
.const SPRITE_ENABLE = $D015  // 53269
// Screen control bits
// 0-2: horizontal raster scroll
// 3: screen width: 0 = 38 columns, 1 = 40 columns
// 4: 1 = multicolor mode on
.const SCREEN_CONTROL_2 = $D016  // 53270
.const SPRITE_DOUBLE_HEIGHT = $D017  // 53271
// Interrupt status register
// Read bit #0: 1 = Current raster line == RASTER_LINE_INTERRUPT
// Read bit #1: 1 = Sprite-background collision occurred
// Read bit #2: 1 = Sprite-sprite collision occurred
// Read bit #3: 1 = Light pen signal arrived
// Read bit #7: 1 = Some other event generated an interrupt
// Write bit #0: 1 = Acknowledge raster interrupt
// Write bit #1: 1 = Acknowledge sprite-background collision interrupt
// Write bit #2: 1 = Acknowledge sprite-sprite collision interrupt
// Write bit #3: 1 = Acknowledge light pen interrupt
.const INTERRUPT_STATUS_REGISTER = $D019
// Interrupt control register
// Bit #0: 1 = raster interrupt enabled
// Bit #1: 1 = sprite background collision interrupt enabled
// Bit #2: 1 = sprite-sprite collision interrupt enabled
// Bit #3: 1 = Light pen interrupt enabled
.const INTERRUPT_CONTROL_3 = $D01A
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
.function sprite_color(sprite_number) {
    .if (sprite_number < 8) {
        .return SPRITE_0_COLOR + sprite_number
    }
    .assert "Bad sprite number", 0, 1
}
.const CHAR_0_COLOR = $D800  // 55296
.function char_color(char_number) {
    .if (char_number < X_CHARS * Y_CHARS) {
        .return CHAR_0_COLOR + char_number
    }
    .assert "Bad char number", 0, 1
}
// Keyboard matrix columns and joystick #2
// Bits are cleared (set to 0!) when joystick pressed
// Read 0 = up, 1 = down, 2 = left, 3 = right, 4 = fire
.const JOYSTICK_2 = $DC00  // 56320
// Keyboard matrix rows and joystick #1
.const JOYSTICK_1 = $DC01  // 56321
// Write bit #0-5 = select keyboard matrix column #x
// Write bit #6-7 = paddle selection, %01 = paddle #1, %10 = paddle #2
.const KEYBOARD_1 = $DC00
// Bit #x: 0 = A key is currently being pressed in keyboard matrix row #x, in
// the column selected at memory address $DC00
.const KEYBOARD_2 = $DC01
// Direction registers, bit #x: 0 = bit #x in port is read-only, 1 = read/write
.const PORT_A_DIRECTION = $DC02
.const PORT_B_DIRECTION = $DC03

// Interrupt control and status registers
// Read bit #0: 1 = Timer A underflow occurred
// Read bit #1: 1 = Timer B underflow occurred
// Read bit #2: 1 = TOD == alarm time
// Read bit #3: 1 = Complete byte received or sent from serial shift register
// Read bit #4: 1 = Signal level on FLAG pin, datasette input
// Read bit #7: 1 = Interrupt has been generated
// Write bit #0: 1 = Enable interrupts generated by timer A underflow
// Write bit #1: 1 = Enable interrupts generated by timer B underflow
// Write bit #2: 1 = Enable TOD alarm interrupt
// Write bit #3: 1 = Enable interrupts generated by serial shift register
// Write bit #4: 1 = Enable interrupts generated by postitive edge FLAG pin
// Write bit #7: Fill bit
.const INTERRUPT_CONTROL_1 = $DC0D
// Same as above, but with the above changes
// Read bit #4: 1 = Signal level of FLAG pin
// Read bit #7: 1 = A non-maskable interrupt has been generated
// Write bits #0-#4: Same as above, but generate non-maskable interrupts
.const INTERRUPT_CONTROL_2 = $DD0D

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
.const SCREEN_CHAR = $0400
.const ZEROPAGE_POINTER_1 = $17
.const ZEROPAGE_POINTER_2 = $19
.const PARAM_1 = $03
.const PARAM_2 = $04
.const PARAM_3 = $05
.const PARAM_4 = $06
.const NUMBER_OF_SPRITES = 11  // This is number of sprites defined in Sprite Pad
.const SPRITE_PLAYER = 64
.const SPRITE_POINTER_BASE = SCREEN_CHAR + SPRITE_TABLE_OFFSET

// I don't know why but setting this to $1800 or other things garbles the
// sprite, so leave it at $2000 for now
.const SPRITE_DATA = $2000


// ****************
// Game state enums
// ****************
.enum {
    Player_Billionaire = 1,
    Player_SparklePony = 2,
    Player_VeteranBurner = 3,
    Player_Virgin = 4
}

.enum {
    GameState_MainMenu = 0,
    GameState_RunGame = 1,
    GameState_SizeUp = 2
}
