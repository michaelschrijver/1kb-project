.code16

.text

packed_data: .byte 1, 2, 3
packed_data_end:

table_twos: .byte 1, 1, 2, 2, 3, 3
table_threes: .byte 4, 4, 4, 5, 5, 5

    movw    $0, %si
    movw    $0x400, %di
    movw    $(packed_data_end - packed_data), %bp
loop:
    lodsb
    test    $0x80, %al
    jz      copy_me_i_want_to_travel
    cbw

    push    %si
    mov     $2, %cx
    movw    %ax, %si
    add     %si, %si
    add     $table_twos, %si

    cmp     $84, %al    
    jbe      twos
    add     %ax, %si
    add     $(table_threes - table_twos), %si
    inc     %cx
twos:
    rep     movsb
    pop     %si
    jmp     next 
copy_me_i_want_to_travel:
    and     $0x7f, %ax
    xchg    %ax, %cx
    rep     movsb
next:
    dec     %bp
    jnz     loop
/*
0000000F  BE0000            mov si,0x0
00000012  BF0004            mov di,0x400
00000015  BD0300            mov bp,0x3
00000018  AC                lodsb
00000019  A880              test al,0x80
0000001B  741C              jz 0x39
0000001D  98                cbw
0000001E  56                push si
0000001F  B90200            mov cx,0x2
00000022  89C6              mov si,ax
00000024  01F6              add si,si
00000026  81C60300          add si,0x3
0000002A  3C54              cmp al,0x54
0000002C  7606              jna 0x34
0000002E  01C6              add si,ax
00000030  83C606            add si,byte +0x6
00000033  41                inc cx
00000034  F3A4              rep movsb
00000036  5E                pop si
00000037  EB06              jmp short 0x3f
00000039  83E07F            and ax,byte +0x7f
0000003C  91                xchg ax,cx
0000003D  F3A4              rep movsb
0000003F  4D                dec bp
00000040  75D6              jnz 0x18
*/
