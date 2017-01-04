note_store:             # store f-num %ax block %bx to %es:%di
                        # return f-num in %dx 
                        # clobbers %ax
    int     $3
    movw    %ax, %dx
    movw    %bx, %cx    
    shl     $10, %cx
    or      %cx, %ax
    or      $32, %ah    # toggle key-on bit    
    stosw
    ret

.macro notes_init
    movw    $note_data, %si
    movw    $notes, %di
    sub     %bp, %bp

    mov     $7, %cx
    mov     $1, %bx
notes_outer_loop:
    push    %cx
    mov     $12, %cx
notes_inner_loop:
    push    %cx
    mov     $10, %cx
    call    note_store
    pop     %cx
    loop    notes_inner_loop
    inc     %bx
    sub     $(12 * 10), %bp
    pop     %cx
    loop    notes_outer_loop
.endm

# A  A# B  C  C# D  D# E  F  F# G  G#
# 0  1  2  3  4  5  6  7  8  9  10 11
write_note_name: # write note %ax with attribute %dl to %es:%di
                       # clobbers %dh, %bx, %ax
    #add     $3, %ax
    aam     $12
    push    %ax
    movw    $note_names, %bx
    xlatb   (%bx) 
    movb    %al, %dh
    and     $31, %al
    movb    %dl, %ah
    stosw
    test    $32, %dh
    jz      no_pound
    mov     $FONT_POUND, %al
    jmp     store
no_pound:
    mov     $FONT_SPACE, %al
store:
    stosw
    pop     %ax
    mov     %ah, %al
    mov     %dl, %ah
    stosw
    ret

.section .rodata
note_names:
    .byte FONT_A, FONT_A | 32, FONT_B
    .byte FONT_C, FONT_C | 32, FONT_D
    .byte FONT_D | 32, FONT_E, FONT_F
    .byte FONT_F | 32, FONT_G, FONT_G | 32

.include "note_data.s"

.text

.section .bss
notes:
.fill 96,2

.text
