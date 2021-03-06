
palette_data = [
        0x00, 0x00, 0x00,  # 00
        0x2a,0x2a,0x3f,    # 01
        0x00, 0x2a, 0x2a,  # 02
        0x2a, 0x00, 0x00,  # 03
]

#        0x2a, 0x00, 0x00,  # 04
#        0x2a, 0x00, 0x2a,  # 05
#        0x2a, 0x2a, 0x00,  # 06
#        0x2a, 0x2a, 0x2a,  # 07
#        0x00,0x00,0x15,    # 08
#        0x00,0x00,0x3f,    # 09
#        0x00,0x2a,0x15,    # 0A
#        0x00,0x2a,0x3f,    # 0B
#        0x2a,0x00,0x15,    # 0C
#        0x2a,0x00,0x3f,    # 0D
#        0x2a,0x2a,0x15,    # 0E
#        0x2a,0x2a,0x3f,    # 0F
#        0x00,0x15,0x00,    # 10
#        0x00,0x15,0x2a,    # 11
#        0x00,0x3f,0x00,    # 12
#        0x00,0x3f,0x2a,    # 13
#        0x2a,0x15,0x00,    # 14
#        0x2a,0x15,0x2a,    # 15
#        0x2a,0x3f,0x00,    # 16
#        0x2a,0x3f,0x2a,    # 17
#        0x00,0x15,0x15,    # 18
#        0x00,0x15,0x3f,    # 19
#        0x00,0x3f,0x15,    # 1A
#        0x00,0x3f,0x3f,    # 1B
#        0x2a,0x15,0x15,    # 1C
#        0x2a,0x15,0x3f,    # 1D
#        0x2a,0x3f,0x15,    # 1E
#        0x2a,0x3f,0x3f,    # 1F
#        0x15,0x00,0x00,    # 20
#        0x15,0x00,0x2a,    # 21
#        0x15,0x2a,0x00,    # 22
#        0x15,0x2a,0x2a,    # 23
#        0x3f,0x00,0x00,    # 24
#        0x3f,0x00,0x2a,    # 25
#        0x3f,0x2a,0x00,    # 26
#        0x3f,0x2a,0x2a,    # 27
#        0x15,0x00,0x15,    # 28
#        0x15,0x00,0x3f,    # 29
#        0x15,0x2a,0x15,    # 2A
#        0x15,0x2a,0x3f,    # 2B
#        0x3f,0x00,0x15,    # 2C
#        0x3f,0x00,0x3f,    # 2D
#        0x3f,0x2a,0x15,    # 2E
#        0x3f,0x2a,0x3f,    # 2F
#        0x15,0x15,0x00,    # 30
#        0x15,0x15,0x2a,    # 31
#        0x15,0x3f,0x00,    # 32
#        0x15,0x3f,0x2a,    # 33
#        0x3f,0x15,0x00,    # 34
#        0x3f,0x15,0x2a,    # 35
#        0x3f,0x3f,0x00,    # 36
#        0x3f,0x3f,0x2a,    # 37
#        0x15,0x15,0x15,    # 38
#        0x15,0x15,0x3f,    # 39
#        0x15,0x3f,0x15,    # 3A
#        0x15,0x3f,0x3f,    # 3B
#        0x3f,0x15,0x15,    # 3C
#        0x3f,0x15,0x3f,    # 3D
#        0x3f,0x3f,0x15,    # 3E
#        0x3f,0x3f,0x3f]    # 3F
#
values = [0, 0x15, 0x2a, 0x3f]
xlat = {values[0]: 0,values[1]: 1, values[2]: 2, values[3]: 3}

def bit_writer(g):
    g = iter(g)
    while True:
        try:
            val = next(g)
        except StopIteration:
            break
        try:
            val |= next(g) << 2
            val |= next(g) << 4
            val |= next(g) << 6
        except StopIteration:
            yield val
            break
        else:
            yield val

e = [xlat[v] for v in palette_data]
print("palette_xlat: .byte %s" % ", ".join([hex(v) for v in values]))
print("palette: .byte %s\npalette_end:" % ", ".join([hex(v) for v in bit_writer(e)]))
