# http://www.shipbrook.net/jeff/sb.html
# http://www.shikadi.net/moddingwiki/OPL_chip

.equ OPL_ADDRESS, 0x388
.equ OPL_STATUS, 0x388
.equ OPL_DATA, 0x389

opl_write_register: # %al = register %ah = value
.ifgt OPL_DO_DELAY
    push    %cx
.endif
    movw    $OPL_ADDRESS, %dx
    out     %al, %dx
.ifgt OPL_DO_DELAY
    movw    $6, %cx
opl_write_delay:
    inb (%dx)
    loop    opl_write_delay
.endif
    inc     %dx
    mov     %ah, %al
    out     %al, %dx
.ifgt OPL_DO_DELAY
    pop     %cx
.endif
    ret

.macro opl_init
    movw    $0xf5, %cx
    subb    %ah, %ah
opl_init_loop:
    mov     %cl, %al
    call    opl_write_register
    loop    opl_init_loop
.endm

.section .rodata
#simple_tone: .byte 0x10, 0xf0, 0x77
#.text
#.macro opl_simple_tone_configure
#    mov     $0120, %ax
#    mov     $3, %cx
#opl_simple_tone_configure_loop:
#    call    opl_write_register
#    add     $20, %al
#    xchg    %ah, %al
#    lodsb
#    xchg    %ah, %al
#    loop    opl_simple_tone_configure_loop
opl_simple_tone: .word 0x0120, 0x1040, 0xf060, 0x7780, 0x0123, 0x0043, 0xf063, 0x7783
.text
.macro opl_simple_tone_configure
    mov     $0x12, %cx                  # set all operators
    #sub     %cx, %cx
opl_simple_tone_configure_loop:
    movw    $opl_simple_tone, %si
    movw    $8, %bx
opl_simple_tone_configure_set_loop:
    lodsw
    add     %cl, %al
    call    opl_write_register
    dec     %bx
    jnz     opl_simple_tone_configure_set_loop
    cmp     $8, %cx
    jnz     opl_simple_tone_no_skip               # 2-operator channels 0-2(+3) and 8-0x12(+3)
    cmp     $0xa, %cx
    jnz     opl_simple_tone_no_skip
    sub     $6, %cx
opl_simple_tone_no_skip:
    dec     %cx
    jns     opl_simple_tone_configure_loop
#    loop    opl_simple_tone_configure_loop
.endm

opl_key_on: # %al = channel, %bx = note    
    add     %bx, %bx
    #add     $notes, %bx
    movw    notes(%bx), %bx
    push    %ax
    add     $0xa0, %al
    movb    %bl, %ah
    #movb    $0x98, %ah
    call    opl_write_register
    pop     %ax
    mov     %bh, %ah
    #movb    $0x31, %ah
    jmp     opl_key_set

opl_key_off: # %al = channel
    sub     %ah, %ah

opl_key_set:    
    add     $0xb0, %al
    jmp     opl_write_register
