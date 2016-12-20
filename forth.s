.code16

.text

.macro NEXT
    jmp     forth_interpreter_next
.endm

.equ DEBUG, 0

.equ CELLS, 2                   # number of bytes in a forth word

.ifgt DEBUG
.include "debug.s"
.endif

# %bp = instruction bit pointer
# %si = base of bytecode
# %bx = return pointer
# %sp = stack pointer

# Virtual machine

forth_interpreter_start:
#    mov     $forth_bytecode, %si   # inherited from loader
#    mov     $0, %bp
    mov     %sp, %bx
    sub     $0x400, %bx
forth_interpreter_next:
    mov     $5, %cx
    int     $3              # load 5-bit opcode
    cmp     $0x1f, %ax
    jnz     forth_interpreter_dispatch
                            # extended opcode
    mov     $8, %cl
    int     $3
    add     $0x1f, %ax
forth_interpreter_dispatch:
    cmp     $0, %cs:(forth_compilation_mode)
    jnz     forth_interpreter_compilation
.ifgt DEBUG
    push    %ax
    mov     $0, %ax
    call    dprint_int
    pop     %ax
    call    dprint_int
.endif
    push    %bx
    mov     %ax, %bx
    add     %bx, %bx
    mov     %cs:forth_dictionary(%bx), %ax
    pop     %bx
    movw    %sp, %di        # often needed
    test    $32768, %ax
    jnz     forth_interpreter_pcode
    jmp     *%ax
forth_interpreter_pcode:
    dec     %bx
    dec     %bx
    mov     %bp, %ss:(%bx)
    and     $32767, %ax
    mov     %ax, %bp
    NEXT
forth_interpreter_compilation:
.ifgt DEBUG
    push    %ax
    mov     $1, %ax
    call    dprint_int
    pop     %ax
    call    dprint_int
.endif
    cmp     $3, %ax                # 3 = exit
    jb      forth_interpreter_skip_immediate
    jnz     forth_interpreter_next
    decw    %cs:(forth_compilation_mode)
    NEXT
forth_interpreter_skip_immediate:
    push    $forth_interpreter_next
forth_load_immediate:
    mov     $16, %cx
    int     $3
    ret

forth_branch: # FORTH: branch
    call    forth_load_immediate
    add     %ax, %bp
    NEXT

forth_branch0: # FORTH: branch0
    call    forth_load_immediate
    pop     %dx
    test    %dx, %dx
    jnz     forth_nobranch0
    add     %dx, %si
forth_nobranch0:
    NEXT

forth_immediate: # FORTH: immediate
    mov     $16, %cx
    int     $3
    push    %ax
    NEXT

forth_exit: # FORTH: exit
    movw    %ss:(%bx), %bp
    inc     %bx
    inc     %bx
    NEXT

forth_colon: # FORTH: :
    # store %bp | 32768 into next dictionary entry
    mov     %bp, %ax
    or      $32768, %ax
    mov     %cs:(forth_dictionary_index), %di
    add     %di, %di
    add     $forth_dictionary, %di
    stosw
    incw    %cs:(forth_dictionary_index)
    incw    %cs:(forth_compilation_mode)
    NEXT

# Primitives from punyforth

forth_dup: # FORTH: dup
    movw    (%di), %ax
    push    %ax
    NEXT

forth_drop: # FORTH: drop
    inc     %sp
    inc     %sp
    NEXT

forth_swap: # FORTH: swap
    pop     %ax
    pop     %dx
    push    %ax
    push    %dx
    NEXT

forth_rot: # FORTH: rot
    pop     %cx
    pop     %dx
    pop     %ax
    push    %dx
    push    %cx
    push    %ax
    NEXT

#forth_2swap: # FORTH: 2swap
#    pop     %dx
#    pop     %cx
#    pop     %di
#    pop     %ax
#    push    %cx
#    push    %dx
#    push    %ax
#    push    %di
#    NEXT
#
#forth_2over: # FORTH: 2over
#    pop     %dx
#    pop     %cx
#    pop     %di
#    pop     %ax
#    push    %ax
#    push    %di
#    push    %cx
#    push    %dx
#    push    %ax
#    push    %di
#    NEXT

forth_plus: # FORTH: +
    pop     %ax
    add     %ax, %ss:(%di)
    NEXT

forth_minus: # FORTH: -
    pop     %ax
    sub     %ax, %ss:(%di)
    NEXT

forth_mul: # FORTH: mul
    pop     %dx
    pop     %ax
    imul    %dx
    push    %ax
    NEXT 

forth_divmod: # FORTH: /mod
    pop     %di
    pop     %ax
    mov     $0, %dx
    cdq
    idiv    %di
    push    %dx
    push    %ax
    NEXT

forth_or: # FORTH: or
    pop     %ax
    or      %ax, %ss:(%di)
    NEXT

forth_and: # FORTH: and
    pop     %ax
    and     %ax, %ss:(%di)
    NEXT

forth_xor: # FORTH: xor
    pop     %ax
    xor     %ax, %ss:(%di)
    NEXT

forth_lshift: # FORTH: lshift
    pop     %cx
    pop     %ax
    shl     %cl, %ax
    push    %ax
    NEXT

forth_rshift: # FORTH: rshift
    pop     %cx
    pop     %ax
    shr     %cl, %ax
    push    %ax
    NEXT

# skipped _emit
# skipped abort

forth_at: # FORTH: @
    pop     %di
    mov     %ss:(%di), %ax
    push    %ax
    NEXT

forth_store: # FORTH: !
    pop     %di
    pop     %ax
    stosw
    NEXT

forth_store_byte: # FORTH: c!
    pop     %di
    pop     %ax
    stosb
    NEXT


# skipped [']


forth_lt: # FORTH: <
    pop     %ax
    pop     %dx
    cmp     %ax, %dx
    setl    %al
    cbw
    neg     %ax
    push    %ax
    NEXT

forth_invert: # FORTH: invert
    notw    %ss:(%di)
    NEXT


#forth_push_return: # FORTH: >r
#    pop     %ax
#    dec     %bx
#    dec     %bx
#    movw    %ax, (%bx)
#    NEXT

#forth_pop_return: # FORTH: r>
#    movw    %ss:(%bx), %ax
#    inc     %bx
#    inc     %bx
#    push    %ax
#    NEXT

forth_i: # FORTH: i
    movw    %ss:(%bx), %ax
    push    %ax
    NEXT

forth_j: # FORTH: j
    movw    %ss:(2 * CELLS)(%bx), %ax
    push    %ax
    NEXT

#forth_execute: # FORTH: execute
#    pop     %ax
#    jmp     *%ax
   

forth_sp_at: # FORTH: sp@
    push    %sp
    NEXT

forth_sp_store: # FORTH: sp!
    pop     %sp
    NEXT

#forth_rp_at: # FORTH: rp@
#    push    %bx
#    NEXT

#forth_rp_store: # FORTH: rp!
#    pop     %bx
#    NEXT

# primitives not from punyforth

forth_outb: # FORTH: outb
    pop     %ax
    pop     %dx
    outb    %al, (%dx)
    NEXT

forth_outw: # FORTH: outw
    pop     %ax
    pop     %dx
    outw    %ax, (%dx)
    NEXT

forth_inb: # FORTH: inb
    pop     %dx
    inb     (%dx), %al
    mov     $0, %ah
    push    %ax
    NEXT

forth_inw: # FORTH: inw
    pop     %dx
    inw     (%dx), %ax
    push    %ax
    NEXT

forth_hlt: # FORTH: halt
.ifgt DEBUG
    mov     $0xdead, %ax
    call    dprint_int
.endif
forth_hlt_loop:
    hlt
    jmp     forth_hlt_loop

forth_dictionary_index: .word 34 # needs to match number of primitives
forth_compilation_mode: .word 0
forth_dictionary: #.fill 256+31,2
.section .bss
