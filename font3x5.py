font = [0x76,  0xba,
0x59,  0x5c,
0xc5,  0x9e,
0xc5,  0x38,
0x92,  0xe6,
0xf3,  0x3a,
0x73,  0xba,
0xe5,  0x90,
0x77,  0xba,
0x77,  0x3a,

0x77,  0xb6,
0x77,  0xb8,
0x72,  0x8c,
0xd6,  0xba,
0x73,  0x9e,
0x73,  0x92,
0x72  ,  0xae,
0xbe,  0xf6,
0x03,  0x02,
0x15,  0xa0,
0x0, 0x0]

import itertools

def generate_font(w):
    i = iter(font)
    char = 0
    for b1, b2 in itertools.izip(i, i):
        #print 'char', char
        char += 1
        line0 = (((b1 >> 4) & 0xe) >> 1) & 7
        line1 = (((b1 >> 1) & 0xe) >> 1) & 7
        line2 = (((((b1 & 3) << 2) | (b2 & 2)) & 0xe) >> 1) & 7
        line3 = (((b2 >> 4) & 0xe) >> 1) & 7
        line4 = (((b2 >> 1) & 0xe) >> 1) & 7

        for line in [line0, line1, line2, line3, line4]:
            w.write_bits(line, 3)

if __name__ == '__main__':
    import compress
    writer = compress.BitWriter()
    font3x5.generate_font(writer)
    writer.flush()
    generate_file(open('font3x5.s', 'w'), 'font', writer, [])
