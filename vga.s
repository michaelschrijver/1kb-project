.equ VGAREG_ACTL_ADDRESS, 0x3c0
.equ VGAREG_ACTL_WRITE_DATA, 0x3c0
.equ VGAREG_ACTL_READ_DATA, 0x3c1

.equ VGAREG_INPUT_STATUS, 0x3c2
.equ VGAREG_WRITE_MISC_OUTPUT, 0x3c2
.equ VGAREG_VIDEO_ENABLE, 0x3c3
.equ VGAREG_SEQU_ADDRESS, 0x3c4
.equ VGAREG_SEQU_DATA, 0x3c5

.equ VGAREG_PEL_MASK, 0x3c6
.equ VGAREG_DAC_STATE, 0x3c7
.equ VGAREG_DAC_READ_ADDRESS, 0x3c7
.equ VGAREG_DAC_WRITE_ADDRESS, 0x3c8
.equ VGAREG_DAC_DATA, 0x3c9

.equ VGAREG_READ_FEATURE_CTL, 0x3ca
.equ VGAREG_READ_MISC_OUTPUT, 0x3cc

.equ VGAREG_GRDC_ADDRESS, 0x3ce
.equ VGAREG_GRDC_DATA, 0x3cf

.equ VGAREG_MDA_CRTC_ADDRESS, 0x3b4
.equ VGAREG_MDA_CRTC_DATA, 0x3b5
.equ VGAREG_VGA_CRTC_ADDRESS, 0x3d4
.equ VGAREG_VGA_CRTC_DATA, 0x3d5

.equ VGAREG_MDA_WRITE_FEATURE_CTL, 0x3ba
.equ VGAREG_VGA_WRITE_FEATURE_CTL, 0x3da
.equ VGAREG_ACTL_RESET, 0x3da

.equ VGAREG_MDA_MODECTL, 0x3b8
.equ VGAREG_CGA_MODECTL, 0x3d8
.equ VGAREG_CGA_PALETTE, 0x3d9

.equ VGASEG_GRAPH, 0xa000
.equ VGASEG_TEXT, 0xb800

indexed_register_loop: /* %bl = max_index, %si = data, %dx = register */
    sub     %al,%al
again:
    out     %al, (%dx)
    inc     %dx
    outsb
    dec     %dx
    inc     %al
    cmp     %al, %bl        /* while %bl > %al */
    jae     again 
    ret

font_registers:
    movw    $VGAREG_SEQU_ADDRESS, %dx
    #movw    $vga_font_disable, %si
    movb    $4, %cl             # %ch once again zero
    rep     outsw
    movw    $VGAREG_GRDC_ADDRESS, %dx
    movb    $3, %cl             # and again
    rep     outsw
    ret

.macro vga_init  # assume %cx = 0
    movw    $vga_init, %si
    /* color mode and enable CPU access */
    movw    $VGAREG_WRITE_MISC_OUTPUT, %dx
    outsb
    /* more than 64k */
    movw    $VGAREG_SEQU_ADDRESS, %dx
    outsw

#    /* memory setup */ 
#    stdvga_sequ_read 0xf
#    movb    $0xf, %al
#    outb    %al, (%dx)
#    inc     %dx
#    inb     (%dx), %al
#    dec     %dx

 #   and     $0x18, %al
 #   movb    %al, %ah
 #   movb    $0xa, %al
 #   #movw    $VGAREG_SEQU_ADDRESS, %dx
 #   outw    %ax, %dx 
    /* set vga mode */
    outsw
    /* reset bitblt */
    movw    $VGAREG_GRDC_ADDRESS, %dx
    outsw
    outsw

    /* configure palette */
    movw    $VGAREG_PEL_MASK, %dx
    outsb
    inc     %dx
    inc     %dx                                 /* %dx = VGAREG_DAC_WRITE_ADDRESS */
    outsb
    inc     %dx                                 /* %dx = VGAREG_DAC_DATA */

    sub     %bp, %bp
palette_loop:
    mov     $2, %cl
    int     $3
    shl     $5, %ax
    outb    %al, %dx
    cmp     $((palette_end - palette) * 8), %bp
    jne     palette_loop
 
    /* set attribute registers */
    mov     $0, %cx
    movw    $vga_actl, %si
actl_loop:
    movw    $VGAREG_ACTL_ADDRESS, %dx
    movb    %cl, %al
    outb    %al, %dx
    outsb
    inc     %cl
    cmp     $(vga_actl_end - vga_actl), %cl
    jne     actl_loop

    /* disable CRTC write protection */
    outsw

    /* set sequence registers */
    movw    $VGAREG_SEQU_ADDRESS, %dx
    #movw    $vga_sequ, %si
    movb    $4, %bl
    call    indexed_register_loop

    /* set grafix registers */
    movw    $VGAREG_GRDC_ADDRESS, %dx
    #movw    $vga_grdc, %si
    movb    $8, %bl
    call    indexed_register_loop

    /* set CRTC registers */
    movw    $VGAREG_VGA_CRTC_ADDRESS, %dx
    movb    $0x18, %bl
    #movw    $vga_crtc, %si
    call    indexed_register_loop

    /* set the misc register */
    movw    $VGAREG_WRITE_MISC_OUTPUT, %dx
    outsb

    /* enable video */
    movw    $VGAREG_ACTL_RESET, %dx
    inb     %dx, %al
    movw    $VGAREG_ACTL_ADDRESS, %dx
    outsb

    /* load font */
    call    font_registers
    push    %si
 
    movw    $VGASEG_GRAPH, %ax
    movw    %ax, %es
    mov     $0, %di
    movw    $font, %si
    sub     %bp, %bp
    movw    $(FONT_SPACE + 1), %dx
vga_font_next_character:
    movb    $5, %bl
vga_font_next_row:
    movb    $3, %cl
    int     $3
    stosb
    dec     %bl
    jnz     vga_font_next_row
    add     $27, %di
    dec     %dx
    jnz     vga_font_next_character

    pop     %si
    call    font_registers
.endm
