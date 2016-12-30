.equ I8042_DATA, 0x60
.equ I8042_STATUS, 0x64
.equ I8042_COMMAND, 0x64

.macro i8042_init
    /* initialize the keyboard controller */
    movb    $0xad, %al          # disable first ps/2 port
    outb    %al, $I8042_COMMAND
    movb    $0xa7, %al          # disable second ps/2 port
    outb    %al, $I8042_COMMAND

    inb     $I8042_DATA, %al     # flush output buffer
    movb    $0x20, %al         # read configuration byte
    outb    %al, $I8042_COMMAND
    inb     $I8042_DATA, %al
    orb     $(4 + 2), %al  # enable first clock and after-post flag 
    xchg    %ah, %al
    movb    $0x60, %al
    outb    %al, $I8042_COMMAND
    xchg    %ah, %al
    outb    %al, $I8042_DATA

    movb    $0xae, %al         # enable first ps/2 port
    outb    %al, $I8042_COMMAND

wait_input_clear:
    inb     $I8042_STATUS, %al
    test    $2, %al
    jnz     wait_input_clear
    mov     $0xff, %al         # reset device
    outb    %al, $I8042_DATA
#    inb     $I8042_DATA          # should be 0xaa
#    inb     $I8042_DATA          # should be 0xfa

.endm
