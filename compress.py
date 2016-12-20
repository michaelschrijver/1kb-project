import collections
import sys

class BitWriter(object):
    def __init__(self):
        self.current_byte = 0
        self.index = 0
        self.bits = 0
        self.values = []
    def flush(self):
        self.values.append(self.current_byte)
        self.current_byte = 0
        self.index = 0
    def write(self, b):
        self.current_byte |= b << self.index
        self.index += 1
        self.bits += 1
        if self.index == 8:
            self.values.append(self.current_byte)
            self.current_byte = 0
            self.index = 0
    def write_bits(self, v, bits): # MSB first
        for bit in range(bits-1, -1, -1):
            self.write(1 if (v & (1 << bit)) != 0 else 0)

    def write_var_bits(self, v, bits):
        highest_set = bits - 1
        for highest_set in range(bits - 1, -1, -1):
            if (v & (2 ** highest_set)) != 0:
                break
        for i in range(highest_set):
            self.write(1)
        self.write(1 if ((highest_set + 1) == bits) else 0)
        self.write_bits(v, highest_set + 1)

class Reader(object):
    def __init__(self, values):
        self.values = values
        self.pointer = 0
    def eof(self):
        return self.pointer >= len(self.values)
    def read(self):
        if self.pointer >= len(self.values):
            raise ValueError
        value = self.values[self.pointer]
        self.pointer += 1
        return value
    def peek_word(self):
        if self.pointer + 1 < len(self.values):
            return self.values[self.pointer] + self.values[self.pointer + 1] * 256
        else:
            raise ValueError
    def peek_signed_word(self):
        v = self.peek_word()
        if v & 32768 != 0:
            v = v - 65536 
        return v

def generate_file(out_file, prefix, writer, properties):
    for k, v in properties:
        out_file.write(".equ %s_%s, %s\n" % (prefix.upper(), k, v))
    out_file.write("%s: .byte %s\n" % (prefix, ", ".join("0x%02X" % v for v in writer.values)))
    out_file.write("%s_end:\n" % prefix)

def histogram(data):
    histogram = collections.defaultdict(lambda :0)
    for value in data:
        histogram[value] = histogram[value] + 1
    return histogram

def repeated_bytes(histogram):
    return list(sorted([(v, k) for k,v in histogram.items() if v > 1], reverse = True))

def compress(filename, out_file, entry_point,
        offset_bits, word_bits, codepoint_bits):
    data = list([ord(c) for c in open(filename).read()])
    h = histogram(data)
    candidates = repeated_bytes(h) 
    print candidates

    #offset_bits = 5
    #word_bits = 5
    #codepoint_bits = 4

    values = list([v for _, v in candidates[:2**codepoint_bits]])
    dictionary = {}
    dictionary_index = 0

    properties =[
            ('BITS', codepoint_bits),
            ('ENTRY_POINT', entry_point),
            ('WORD_BITS', word_bits),
            ('OFFSET_BITS', offset_bits),
            ('UNCOMPRESSED_SIZE', len(data))]

    writer = BitWriter()
    reader = Reader(data)
    while not reader.eof():
        if 0:
            try:
                word = reader.peek_word()
            except ValueError:
                pass
            else:
                if word >= 0 and word < 2**word_bits:
                    writer.write(1)
                    writer.write(1)
                    writer.write(0)
                    writer.write_bits(word, word_bits)
                    reader.pointer += 2
                    #print('word', word)
                    continue
            try:
                word = reader.peek_signed_word()
            except ValueError:
                pass
            else:
                offset = reader.pointer + 2 + word # calculate absolute offset
                if offset >= 0 and offset < 2**offset_bits:
                    writer.write(1)
                    writer.write(1)
                    writer.write(1)
                    writer.write_bits(offset, offset_bits)
                    #print('offset', offset, 'pointer', reader.pointer, 'word was', word)
                    reader.pointer += 2
                    continue

        v = reader.read()

        try:
            codepoint = values.index(v)
        except ValueError:
            #print('literal', hex(v))
            writer.write(0)
            writer.write_bits(v, 8)
            #print 'literal', v
        else:
            #print('codepoint', hex(codepoint), 'value', hex(v))
            writer.write(1)
            #writer.write(0)
            writer.write_bits(codepoint, codepoint_bits)
            #print 'codepoint', codepoint, '->', v
    #print 'bits', writer.bits
    writer.flush()
    generate_file(out_file, 'packed_data', writer, properties)
    out_file.write("table: .byte %s\n" % ", ".join(['0x%02X' % v for v in values]))
    print('Encoded into %d bytes with a %d bytes table.' % (len(writer.values), len(values)))
    return len(writer.values)

if len(sys.argv) == 4:
    smallest = 65536
    params = None
    ob = 0
    wb = 0
    for cb in range(7):
        size = compress(sys.argv[1], open(sys.argv[2], 'w'), int(sys.argv[3], 16),
                ob, wb, cb)
        if size < smallest: 
            smallest = size
            params = (ob, wb, cb)

    if params:
        print smallest, params
        compress(sys.argv[1], open(sys.argv[2], 'w'), int(sys.argv[3], 16),
                        *params)
