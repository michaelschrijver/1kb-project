.equ TRACKER_NO_ENTRY, 0xff
.equ TRACKER_KEY_OFF, 0xfe
.equ TRACKER_ROWS, 512
.equ TRACKER_TRACKS, 8

.equ TRACKER_RENDER_ROWS, 64

# -- C#5 -- note
# --------- no entry
# -- *** -- key off

.macro render_line # %es:%di points at current line, points to next row after
                   # %ds:%si at current track row, points to next row after
    subw    %cx, %cx
next_track:
    push    %dx
    cmp     %cx, (current_track)
    jnz     emit_note 
    movb    %dh, %dl
emit_note:
    movb    %dl, %ah
    mov     $FONT_SPACE, %al
    stosw
    stosw
    stosw
    lodsb   (%si), %al 
    cmp     $TRACKER_NO_ENTRY, %al
    jz      no_entry
    cmp     $TRACKER_KEY_OFF, %al
    jz      key_off
    sub     %ah, %ah
    call    write_note_name
    jmp     threespace
no_entry:
    mov     $FONT_DASH, %al
    jmp     threestosw 
key_off:
    movb    $FONT_STAR, %al
threestosw:
    stosw
    stosw
    stosw
threespace:
    mov     $FONT_SPACE, %al
    stosw
    stosw
    stosw
    stosw
    pop     %dx
    inc     %cx
    cmp     $TRACKER_TRACKS, %cl
    jnz     next_track
.endm

.macro tracker_init # requires %es = 0
.ifgt DEMO_SONG
    movw    $demo_song, %si
    movw    $track, %di
    movw    $0, %cx
tracker_init_loop:
    lodsb
    mov     %al, %cl
    lodsb
    rep     stosb
    cmp     $demo_song_end, %si
    jnz     tracker_init_loop
    mov     $track_end, %cx
    sub     %di, %cx
    mov     $TRACKER_NO_ENTRY, %al
    rep     stosb
.else
    #movb    $TRACKER_NO_ENTRY, %al         # left like this by i8042_init
    movb    %al, %ah
    movw    $(TRACKER_ROWS * TRACKER_TRACKS / 2), %cx
    movw    $track, %di
    rep     stosw
.endif
.endm

tracker_interrupt:
    pusha
    cmp     $0, tracker_playing
    jz      tracker_interrupt_ret 
    movw    $current_row, %si
    movw    (%si), %ax
    incw    (%si)
    andw    $(TRACKER_ROWS - 1), (%si)
    shl     $3, %ax
    addw    $track, %ax
    movw    %ax, %si
    mov     $0, %cx
tracker_interrupt_loop:
    push    $tracker_interrupt_next_channel
    lodsb   (%si), %al
    cmp     $TRACKER_KEY_OFF, %al
    jz      tracker_interrupt_key_off
    cmp     $TRACKER_NO_ENTRY, %al
    jz      tracker_interrupt_next_channel_ret
    mov     %al, %bl
    sub     %bh, %bh
    mov     %cl, %al
    jmp     opl_key_on
tracker_interrupt_next_channel:
    inc     %cx
    cmp     $8, %cx
    jnz     tracker_interrupt_loop
tracker_interrupt_ret:
    popa
    ret

tracker_interrupt_key_off:
    movb    %cl, %al
    jmp     opl_key_off

.ifgt DEMO_SONG
.section .rodata
demo_song: .byte 1, 0, 8, TRACKER_NO_ENTRY
demo_song_end:
.endif

.section .bss
track:
    .fill TRACKER_ROWS, TRACKER_TRACKS
track_end:

current_note: .word 0           # order important!
current_row: .word 0
current_track: .word 0
tracker_playing: .word 0

.text
