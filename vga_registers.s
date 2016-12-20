.section .rodata
# these all must be in this order
#.include "vga_palette.s"

vga_init: .byte 0xc3 # color mode and enable CPU access
          .word 0x204 # more than 64k
          .word 0x7 # set vga mode
          .word 0x431, 0x31 # reset bitblt
          .byte 0xff # pel mask
          .byte 0x00 # palette start
palette: .byte 0x80, 0x8e, 0xa
palette_end:
vga_actl: .byte 0x00, 0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00, 0x0
          .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x00
          .byte 0x0f, 0x08, 0x00
vga_actl_end:
          .word 0x11 # disable CRTC write protection
vga_sequ: .byte 0x03, 0x00, 0x03, 0x00, 0x02
vga_grdc: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x0e, 0x0f, 0xff
vga_crtc: .byte 0x5f, 0x4f, 0x50, 0x82, 0x55, 0x81, 0xbf, 0x1f, 0x00
          .byte 0x45, 0x0d, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x9c, 0x8e
          .byte 0x8f, 0x28, 0x1f, 0x96, 0xb9, 0xa3, 0xff
misc:     .byte 0x67
enable_video: .byte 0x20
vga_font_enable: .word 0x0100, 0x0402, 0x0704, 0x0300 # sequencer registers
                 .word 0x0204, 0x0005, 0x0406 # grdc registers
vga_font_disable: .word 0x0100, 0x0302, 0x0304, 0x0300 # sequencer registers
                  .word 0x0e06, 0x0004, 0x1005 # grdc registers

# until here
.text
.macro stdvga_indexed_write register, index, value
    movw    $((\value << 8) | \index), %ax
    movw    $\register, %dx
    outw    %ax, %dx
.endm

.macro stdvga_sequ_write index, value
    stdvga_indexed_write VGAREG_SEQU_ADDRESS, \index, \value
.endm

.macro stdvga_grdc_write index, value
    stdvga_indexed_write VGAREG_GRDC_ADDRESS, \index, \value 
.endm


.macro stdvga_sequ_read index
    movw    $VGAREG_SEQU_ADDRESS, %dx
    movb    $\index, %al
    outb    %al, %dx
    inc     %dx
    inb     %dx, %al
.endm

.macro stdvga_attrindex_write value
    movw    $VGAREG_ACTL_RESET, %dx
    inb     %dx, %al
    movb    $\value, %al
    movw    $VGAREG_ACTL_ADDRESS, %dx
    outb    %al, %dx
.endm

