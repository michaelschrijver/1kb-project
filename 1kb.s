/*
 *      http://www.shikadi.net/moddingwiki/OPL_chip
 *      http://neptune.billgatliff.com/debugger.html
 */
    .code16

.include "i8042.s"
.include "kbd_scancode2.s"

.equ DEBUG, 0
.equ OPL_DO_DELAY, 0
.equ DEMO_SONG, 0

.equ TRACKER_TICKS, 255

.equ interrupt_table, 0x0

.bss
last_count: .word 0 
tracker_ticks: .byte 0
.text

.ifgt DEBUG
.include "debug.s"
.endif

.include "notes.s"

.include "font.s"
.include "vga_registers.s"
.include "vga.s"

.include "opl.s"

.include "tracker.s"

keyboard_interrupt_return:
    andw    $(TRACKER_ROWS - 1), (current_row)
    andw    $(TRACKER_TRACKS -1), (current_track)
    popa
    ret

keyboard_wait:
    mov     $16, %cx
keyboard_wait_loop:
    inb     $I8042_STATUS
    test    $1, %al
    jnz     keyboard_wait_over
    loop    keyboard_wait_loop
keyboard_wait_over:
    ret

keyboard_interrupt:
    pusha

    push    $keyboard_interrupt_return
    call    keyboard_wait
    test    $1, %al
    jnz     keyboard_read
    ret
keyboard_read:
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
    cmp     $SCANCODE_S, %al
    jz      s
    cmp     $SCANCODE_ENTER, %al
    jz      enter
    cmp     $SCANCODE_BRACKET_OPEN, %al
    jz      bracket_open
    cmp     $SCANCODE_BRACKET_CLOSE, %al
    jz      bracket_close
    cmp     $SCANCODE_SPACEBAR, %al
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
    call    keyboard_wait
    inb     $I8042_DATA
.ifgt DEBUG
    mov     $1, %ah
    call    dprint_int
.endif
    inc     %si
    inc     %si                     # %si = current_row
    cmp     $SCANCODE_CURSOR_UP, %al
    jz      cursor_up
    cmp     $SCANCODE_CURSOR_DOWN, %al
    jz      cursor_down
    inc     %si
    inc     %si                     # %si = current_track
    cmp     $SCANCODE_CURSOR_RIGHT, %al
    jz      cursor_right
    cmp     $SCANCODE_CURSOR_LEFT, %al
    jz      cursor_left
    cmp     $SCANCODE_DELETE, %al
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
tracker_set_note:
    movw    (current_row), %bx
    incw    (current_row)
    shl     $3, %bx
    movw    (current_track), %si
    movb    %al, track(%bx,%si)
tracker_interrupt_next_channel_ret:
    ret

extended_scancode2:
    call    keyboard_wait
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

    opl_init
    opl_simple_tone_configure

    mov     $((2 << 1) | (3 << 4)), %al
    out     %al, $0x43
    mov     $0x0, %al
    out     %al, $0x40
    out     %al, $0x40                      # set pit channel 0 to mode 3 reload value 0x0

    i8042_init
    push    %cs
    pop     %es
    tracker_init                        # tracker expect %al=0xff from i8042_init
    notes_init
    vga_init                            # vga expect %cx=0

    movb    $TRACKER_TICKS, (tracker_ticks)
    movw    $VGASEG_TEXT, %ax
    movw    %ax, %es
infinity:
    movb    $0, %al
    outb    %al, $0x43
    inb     $0x40, %al
    xchg    %al, %ah
    inb     $0x40, %al

.ifgt DEBUG
    call    dprint_int
.endif

    mov     (last_count), %dx
    mov     %ax, (last_count)
    cmp     %dx, %ax
    jb      read_keyboard
    decb    (tracker_ticks)
    jnz     read_keyboard
    movb    $TRACKER_TICKS, (tracker_ticks)
    call    tracker_interrupt

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
read_keyboard:
    call    keyboard_interrupt
    jmp     infinity
