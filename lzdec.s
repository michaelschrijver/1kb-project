.code16

.text
get_bit:
    push    %bp
    push    %cx
    shr     $3, %bp
    mov     %bp, %cx
    and     $7, %cl
    mov     $1, %ah
    shl     %cl, %ah
    mov     (%si, %bp), %al
    pop     %cx
    pop     %bp
    inc     %bp
    test    %ah, %al
    setnz   %bl
    ret

read_var_bits:
    mov     $0, %cl
next_var_prefix:
    inc     %cl
    cmp     %bh, %cl
    jz      max_var_bits
    call    get_bit
    jnz     next_var_prefix
max_var_bits
    sub     %bh, %bh
    sub     %ch, %ch
next_var_data:
    call    get_bit
    shl     %cl, %bl
    or      %bl, %bh
    inc     %cl
    cmp     %ch, %cl
    jb      next_var_data
    ret

entry:
    mov     $0, %bp
next:
    call    get_bit
    jz      literal
    // read var bits distance
    mov     $4, %ch
    call    read_var_bits
    // read var bits length
    mov     %bh, %al
    cbw    
    mov     $3, %ch
    call    read_var_bits
    mov     %bh, %cl
    sub     %ch, %ch
    // copy length bits from distance
    push    %si
    mov     %di, %si
    sub     distance, %si
    rep     movsb
    pop     %si
    jmp     next
literal:
    mov     $0, %cl
    mov     %cl, %bh
next_literal_bit: 
    call    get_bit
    shl     %cl, %bl
    or      %bl, %bh
    inc     %cx
    and     $7, %cx
    jnz     next_literal_bit
    push    %ax
    mov     %bh, %al
    stosb
    pop     %ax
    jmp     next
