## Synopsis

This is an OPL-2 tracker implemented as a PC BIOS. It should run on 386+, but runs in real-mode to keep the code size down.
I've only tested it in emulators (qemu mostly, bochs a few times), once my flash chip programmer arrives I'll have a go at running it on hardware.

Currently it's a bit oversized, but think there's a few more bytes to squeeze and otherwise features to remove.
It produces horrible sounds, which is also something to look into.

# Compiling it

You need GNU assembler, GNU linker, python2+ and make installed.
Just run make to compile.

# Running it

The included makefile contains targets to run the tracker in either qemu or bochs.

 make run-qemu

or 

 make run-bochs

# Using it

Key(s)        | Function
==============+===============
Arrow keys    | Navigate track
Enter         | Start playback
Delete        | Remove note under cursor
S             | Set note under cursor to key off
[ ]           | Adjust current note
Space         | Place current note under cursor

# How does it work

The final binary consists of a very simple unpacker (bitdec.s) which unpacks the final payload
into lower memory (0x40:0). This unpacker also installs a bit reading function into interrupt 3.
Calling interrupt 3 is a single byte instruction, making it a cheap function to call.
This is used not only in the unpacker itself but also in the final payload.

The final payload is packed by compress.py. It makes a histogram of the payload and uses that
to find the most frequent bytes. These most frequent bytes are replaced by shorter bit sequences starting with a 1-bit, the others get a 0-bit prefix. Net result is a shorter payload, though the loss don't completely offset the size of the unpacker. Reuse in the payload does make up for that.

The final payload is assembled from 1kb.s. In the file various macros are combined together
to form the program. Various source files provides parts:
vga.s - VGA initialization, sets a text mode, palette and loads a partial font
vga_registers.s - VGA initialization data
opl.s - OPL-2 code
pic.s - PIC initialization code, configure interrupts
i8042.s - 8042 initialization, only used for PS/2 keyboard
notes.s - Initializes a table with notes in OPL-2 form, 
            contains code to output a note name to screen
tracker.s - Tracker playback code and line rendering code

1kb.s itself contains the keyboard interrupt handler and the main loop.

Some of the data is generated using python scripts:
compress.py - Compressing payload for bitdec.s
notes.py - Generates the note table
font3x5.py - Generates the font data 

# Optimizations

## VGA palette registers

The vga_actl registers, amongst other things, controls the mapping of text attributes
to palette indices. Since I don't use that many colors the unused mappings have been zeroed out for better compression.

## VGA font

VGA font loading uses a 3x5 font packed into a single bitstring. Unpacking is done using
the interrupt 3 handler from the unpacker. Only the characters used in the tracker are
packed in (0-9 # - *  ).

## VGA register loading

All the VGA initialization data is layed out in memory in a sequential fashion.
Because of this layout only a single offset loading instruction is needed. 
The setting code consistly mostly of mov $REGISTER,%dx / mov $count, %cx / rep outsb like sequences.
My attempts to pack this down into some VM-like structure unfortunately didn't pan out.

The initialization data and sequence itself was borrowed from the SeaBIOS project.

## PIC & I8042

Mostly straight-forward port setting code. Because the ports used can be used as immediates
to the out instructions loading register setting data from memory doesn't help out here.
Information about the settings I found mostly on the osdev website.

# Keyboard interrupt handler

Because of the many branches it's beneficial to push a return offset onto the stack and use
the single byte ret instruction to terminate branches. This replaces a two byte relative jump.

A pointer to the state variables is maintained in %si. It's loaded with an offset only once and increased using the inc instruction if it has skipped all branches affecting that certain value.
