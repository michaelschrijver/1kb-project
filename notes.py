import math


#(290, 0, 290, 0)
#(307, 0, 17, 0)
#(325, 0, 18, 0)
#(344, 0, 19, 0)
#(364, 0, 20, 0)
#(386, 0, 22, 0)
#(409, 0, 23, 0)
#(433, 0, 24, 0)
#(458, 0, 25, 0)
#(485, 0, 27, 0)
#
#(514, 0, 29, 0)
#(544, 0, 30, 0)
#(580, 0, 36, 0)
#(614, 0, 34, 0)
#(650, 0, 36, 0)
#(688, 0, 38, 0)
#(729, 0, 41, 0)
#(772, 0, 43, 0)
#(818, 0, 46, 0)
#(866, 0, 48, 0)
#(917, 0, 51, 0)
#(971, 0, 54, 0)
#
#(514, 1, -457, 1)
#(544, 1, 30, 0)
#(580, 1, 36, 0)
#(614, 1, 34, 0)
#(650, 1, 36, 0)
#(688, 1, 38, 0)
#(729, 1, 41, 0)
#(772, 1, 43, 0)
#(818, 1, 46, 0)
#(866, 1, 48, 0)
#(917, 1, 51, 0)
#(971, 1, 54, 0)
#(514, 2, -457, 1)

def generate_notes():
    opl_blocks = [48.503, 97.006, 194.013, 388.026, 776.053, 1552.107, 3104.125, 6208.431]
    octaves = [13.75, 27.5, 55, 110, 220, 440, 880, 1760] #, 3520, 7040, 14080]
    ratio = 1.059463

    last_f_num = 0 
    last_block = 0
    for base_freq in octaves:
        for note in range(12):
            freq = base_freq * ratio**(note + 3) # start a C0
            for block, max_freq in enumerate(opl_blocks):
                if freq < max_freq:
                    break
            f_num = int(freq * 2 ** (20 - block) / 49716)

            delta = ((block - last_block) << 7) | (f_num - last_f_num)
            #print base_freq, freq, note
            print(note, freq, hex(f_num), block, f_num - last_f_num, block - last_block)
            yield block, f_num
            last_f_num = f_num
            last_block = block
       
def generate_note_data(writer):
    notes = list(generate_notes())
    for block, f_num in notes[24:36]:
        writer.write_bits(f_num, 10)

import compress
writer = compress.BitWriter()
generate_note_data(writer)
compress.generate_file(open('note_data.s', 'w'), 'note_data', writer, [])
