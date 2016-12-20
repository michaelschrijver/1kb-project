.code16

.section .rodata
.ifdef FORTH
.include "packed_forth.s"
.else
.include "packed_data.s"
.endif

.section .text

# %si = bitstream start %bp = bitpointer %cx = number of bits
# returns up to 16 bits in %ax
get_bits:
    push    %dx
    mov     $0, %ax
get_bits_loop:
    push    %bp
    push    %cx
    mov     %bp, %cx
    and     $7, %cx
    mov     $1, %ch
    shl     %cl, %ch
    shr     $3, %bp
    test    %ch, %ds:(%bp, %si)
    setnz   %dl
    pop     %cx
    pop     %bp
    inc     %bp
    shl     $1, %ax
    or      %dl, %al
    loop    get_bits_loop
    pop     %dx
    iret

entry:
    pop     %ds:(3*4)
    pop     %ds:(3*4+2)
    push    %cs
    pop     %ds
.ifdef PACKED_DATA_FORTH
    mov     $PACKED_DATA_DICTIONARY, %dx
.endif
next:
    cmp     $PACKED_DATA_UNCOMPRESSED_SIZE, %di
    jae     far_jmp
    inc     %cx                 # #cx was zero from either reset or last int $3 loop
    int     $3
    test    %al, %al
    jz      literal
.ifdef PACKED_DATA_FORTH
    inc     %cx
    int     $3
    test    %al, %al
    jnz     dictionary
.endif
    mov     $PACKED_DATA_BITS, %cl
    int     $3
    xlat
    jmp     stosb 
literal:
    mov     $8, %cl
    int     $3
stosb:
    stosb
    jmp     next
.ifdef PACKED_DATA_FORTH
dictionary:
    xchg    %dx, %di
    movw    %dx, %es:(%di)
    xchg    %dx, %di
    inc     %dx
    inc     %dx
    jmp     next
.endif
far_jmp:
    push    %es
    push    $PACKED_DATA_ENTRY_POINT
    retf

.section .init
    mov     $packed_data, %si       # 3
    mov     $table, %bx             # 3
    push    $0x40                   # 2
    pop     %es                     # 1
    push    %cs                     # 1
    push    $get_bits               # 3

    jmp     entry                   # 3

                                    # total 16

