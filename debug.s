dprint:
    movw    $0xe9, %dx
loop:
    lodsb
    outb    %al, (%dx)
    test    %al, %al
    jnz     loop
    ret
dprint_int:
    pusha 
    mov     $4, %cx
    mov     $0xe9, %dx
dprint_int_loop:
    rol     $4, %ax
    push    %ax
    and     $0xf, %al
    add     $'0', %al
    cmp     $'9', %al
    jbe     dprint_number
    add     $('A' - '9' - 1), %al            
dprint_number:
    out     %al, (%dx)
    pop     %ax
    loop    dprint_int_loop
    mov     $' ',%al
    out     %al, (%dx)
    popa
    ret
