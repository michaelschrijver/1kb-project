.equ PIC1, 0x20
.equ PIC2, 0xa0
.equ PIC1_COMMAND, PIC1 
.equ PIC1_DATA, (PIC1 + 1)
.equ PIC2_COMMAND, PIC2
.equ PIC2_DATA, (PIC2 + 1)

.equ PIC_EOI, 0x20

.equ ICW1_ICW4,   0x01        /* ICW4 (not) needed */
.equ ICW1_SINGLE, 0x02        /* Single (cascade) mode */
.equ ICW1_INTERVAL4,  0x04        /* Call address interval 4 (8) */
.equ ICW1_LEVEL,  0x08        /* Level triggered (edge) mode */
.equ ICW1_INIT,   0x10        /* Initialization - required! */
 
.equ ICW4_8086,   0x01        /* 8086/88 (MCS-80/85) mode */
.equ ICW4_AUTO,   0x02        /* Auto (normal) EOI */
.equ ICW4_BUF_SLAVE,  0x08        /* Buffered mode/slave */
.equ ICW4_BUF_MASTER, 0x0C        /* Buffered mode/master */
.equ ICW4_SFNM,   0x10        /* Special fully nested (not) */

.macro io_wait
#    outb    %al, $0x80
.endm

.macro pic_init    
    movb    $(ICW1_INIT + ICW1_ICW4), %al
    outb    %al, $PIC1_COMMAND
    io_wait
    outb    %al, $PIC2_COMMAND
    io_wait
    mov     $0, %al
    outb    %al, $PIC1_DATA
    io_wait
    movb    $7, %al
    outb    %al, $PIC2_DATA
    io_wait
    movb    $4, %al
    outb    %al, $PIC1_DATA
    io_wait
    movb    $2, %al
    outb    %al, $PIC2_DATA
    io_wait
    movb    $ICW4_8086, %al
    outb    %al, $PIC1_DATA
    io_wait
    outb    %al, $PIC2_DATA

    movb    $0xff, %al
    outb    %al, $PIC2_DATA
    movb    $~(2|1), %al
    outb    %al, $PIC1_DATA    # enable keyboard interrupt and pit channel 0 interrupt
.endm
