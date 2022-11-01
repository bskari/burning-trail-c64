# Burning Trail

An Oregon Trail spoof for the Commodore 64.

## Compiling

Use CharPad Pro to convert graphics/sprites.spd to graphics/Sprites.raw.

I use the Kickass 6502 compiler. Download the jar and put it somewhere. Edit
the Makefile and set "kickassJar" appropriately. Run `make`.

## Running

I use Vice for emulation. Run `x64 main.org`. Alternatively, run `make run`.
You can also run `make debug`.
