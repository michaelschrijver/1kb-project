OUTPUT_FORMAT("binary")
SECTIONS {
    /*
    .padding    (0xc0000): { FILL(0x0); BYTE(0); }
    .text       (0xff000): { *(.text) }
    .init       (0xffff0): { *(.init) }
    */
    .text       (0x0): { *(.text) *(.rodata) }
    .init       (0xfff0): { *(.init) }
    .bss        (0x4000): { *(.bss) }
}
