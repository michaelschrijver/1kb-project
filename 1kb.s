/*
 *      http://www.shikadi.net/moddingwiki/OPL_chip
 *      http://neptune.billgatliff.com/debugger.html
 */
    .code16

.include "pic.s"
.include "i8042.s"

.equ DEBUG, 0
.equ OPL_DO_DELAY, 0

.equ interrupt_table, 0x0

.section .bss
skip_next_scancode: .byte 0

.text

.ifgt DEBUG
.include "debug.s"
.endif

.include "notes.s"

#.include "vgafont16.s"
.include "font.s"
.include "vga_registers.s"
.include "vga.s"

.include "opl.s"

.include "tracker.s"

keyboard_interrupt_return:
    andw    $(TRACKER_ROWS - 1), (current_row)
    andw    $(TRACKER_TRACKS -1), (current_track)
eoi:
    movb    $PIC_EOI, %al
    outb    %al, $PIC1_COMMAND
    popa
    iret

keyboard_interrupt:
    pusha

.ifgt DEBUG
    mov     skip_next_scancode, %ax
    call    dprint_int
.endif
    push    $keyboard_interrupt_return
    cmp     $0, skip_next_scancode
    jz      keyboard_dispatch
    decw    skip_next_scancode
    inb     $I8042_DATA
.ifgt DEBUG
    mov     $0xff, %ah
    call    dprint_int
.endif
    ret
keyboard_dispatch:
    movw    $current_note, %si
    inb     $I8042_DATA
.ifgt DEBUG
    mov     $0x00, %ah
    call    dprint_int
.endif
    cmp     $0xe0, %al
    jz      extended_scancode
    cmp     $0xf0, %al
    jz      extended_scancode2
    cmp     $0x1b, %al
    jz      s
    cmp     $0x5a, %al
    jz      enter
    cmp     $0x54, %al
    jz      bracket_open
    cmp     $0x5b, %al
    jz      bracket_close
    cmp     $0x29, %al
    jz      spacebar
    ret
bracket_open:
    cmp     $0, (%si)
    jz      lowest_note
    decw    (%si)
lowest_note:
    ret
bracket_close:
    incw    (%si)
    ret
spacebar:
    movb    (current_note), %al
    jmp     tracker_set_note
enter:
    #mov     $1, %al
    #mov     %al, tracker_playing
    xor     $1, tracker_playing
    ret
s:
    # insert stop note at current position
    mov     $TRACKER_KEY_OFF, %al
    jmp     tracker_set_note

extended_scancode:
    incw    skip_next_scancode
    inb     $I8042_DATA
.ifgt DEBUG
    mov     $1, %ah
    call    dprint_int
.endif
    inc     %si
    inc     %si                     # %si = current_row
    cmp     $0x75, %al
    jz      cursor_up
    cmp     $0x72, %al
    jz      cursor_down
    inc     %si
    inc     %si                     # %si = current_track
    cmp     $0x74, %al
    jz      cursor_right
    cmp     $0x6b, %al
    jz      cursor_left
    cmp     $0x71, %al
    jz      delete
    cmp     $0xf0, %al
    jz      extended_scancode2
    ret

cursor_up:
    # move cursor up
    decw    (%si)
    ret
cursor_down:
    # move cursor down
    incw    (%si)
    ret

cursor_left:
    # move to left next channel
    decw    (%si)
    ret
cursor_right:
    # move to right next channel
    incw    (%si)
    ret

delete:
    mov     $TRACKER_NO_ENTRY, %al
    jmp     tracker_set_note
extended_scancode2:
    movb    $1, skip_next_scancode
    inb     $I8042_DATA
.ifgt DEBUG
    mov     $2, %ah
    call    dprint_int
.endif
    ret

entry:
.ifgt DEBUG
    mov     $0x1337, %ax
    call    dprint_int
.endif
    push    %cs
    pop     %ds

    /* install interrupt handlers */
    #sub     %ax, %ax
    mov     $0, %ax
    movw    %ax, %es
    mov     %ax, %di
    
    movw    $tracker_interrupt, %ax
    stosw
    mov     %cs, %ax
    stosw
    movw    $keyboard_interrupt, %ax
    stosw
    movw    %cs, %ax
    stosw

    opl_init
    opl_simple_tone_configure

    mov     $((2 << 1) | (3 << 4)), %al
    out     %al, $0x43
    mov     $0xff, %al
    out     %al, $0x40
    out     %al, $0x40                      # set pit channel 0 to mode 3 reload value 0xffff

    pic_init
    i8042_init
    push    %cs
    pop     %es
    tracker_init                        # tracker expect %al=0xff from i8042_init
    notes_init
    vga_init                            # vga expect %cx=0

    movw    $0, skip_next_scancode

    sti

    movw    $VGASEG_TEXT, %ax
    movw    %ax, %es
infinity:
    movw    $0, %di
    mov     (current_row), %si
    mov     %si, %bp
    and     $(TRACKER_RENDER_ROWS-1), %bp
    and     $~(TRACKER_RENDER_ROWS-1), %si
    shl     $3, %si
    add     $track, %si
    movw    $0, %cx
render_loop:
    mov     $0x0101, %dx                # %dh = highligh attrib %dl = regular attrib
    cmp     %cx, %bp 
    jnz     no_highlight
    mov     $0x21, %dh
no_highlight:
    push    %cx
    render_line
    pop     %cx
    inc     %cx
    cmp     $TRACKER_RENDER_ROWS, %cl
    jnz     render_loop

    movb    $0x31, %dl
    movw    (current_note), %ax
    call    write_note_name

    hlt
    jmp     infinity
