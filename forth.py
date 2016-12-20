import re
import compress
import subprocess

def load_symbols(filename):
    for m in re.finditer('([0-9a-f]+)\s+l\s+\S+\s+0+\s+(\S+)', subprocess.check_output(['objdump', '-t', filename])):
        yield (m.group(2), int(m.group(1), 16))

class ForthException(Exception): pass

class ForthCodeGenerator(object):
    def __init__(self, writer):
        self.w = writer

    @property
    def offset(self):
        return self.w.bits

    def emit_immediate(self, v):
        print 'immediate', v
        self.w.write_bits(v, 16)
    def emit_word(self, v):
        print 'word', v
        if v > 30:
            self.w.write_bits(31, 5)
            self.w.write_bits(v - 31, 8)
        else:
            self.w.write_bits(v, 5)

class ForthCompiler(object):
    def compile(self, s, cg):
        def emit_named(word):
            cg.emit_word(self.dictionary[word])
        def tokenize(s):
            for m in re.finditer('\s*(\S+)', s):
                yield m.group(1)
        g = tokenize(s)
        try:
            while True:
                v = next(g) 
                try:
                    immediate = int(v)
                except ValueError:
                    if v == ':':
                        name = next(g)
                        emit_named(':')
                        body = cg.offset # pointer to body in bitstream
                    elif v == ';':
                        emit_named('exit')
                        self.dictionary[name] = len(self.jump_table) | 32768
                        self.jump_table.append(body | 32768)
                        name = None
                        body = None
                    else:
                        try:
                            word = self.dictionary[v]
                        except KeyError:
                            raise ForthException('Unknown word %s.' % v)
                        else:
                            cg.emit_word(word)
                            #print 'word', word, '(', self.jump_table[word], ')'
                else:
                    emit_named('immediate')
                    cg.emit_immediate(immediate)
                    #print 'immediate', immediate
        except StopIteration:
            pass

    def load_primitives(self):
        primitive_re = re.compile('(\w+?):\s+#\s+FORTH: (\S+)')
        symbols = dict(load_symbols('forth.o'))
        self.jump_table = []
        self.dictionary = {}
        for line in open('forth.s'):
            m = primitive_re.match(line)
            if m:
                self.dictionary[m.group(2)] = len(self.jump_table)
                self.jump_table.append(symbols[m.group(1)])
        return symbols

def forth_compress(writer, payload):
    c = ForthCompiler()
    symbols = c.load_primitives()
    print len(c.dictionary), 'primitives loaded.'
    for p, i  in sorted(c.dictionary.iteritems(), key = lambda v:v[1]):
        print i, p
    binary = list([ord(ch) for ch in open('forth.bin').read()])
    repeated_bytes = compress.repeated_bytes(compress.histogram(binary))
    def size_projection(b):
        replaced_bytes = sum([f for f,v in repeated_bytes[:2**b]])
        new_size = replaced_bytes * (b + 2) + \
         (len(binary) - replaced_bytes) * 9 + \
         2**5 * 8 + \
         len(c.jump_table) * 2
        # bytes replaced by codepoints (two-bit prefix)
        # literal bytes (one-bit prefix)                        
        # translation table
        # primitive markers (two-bit prefix)           
        return new_size / 8

    new_size, b = sorted([(size_projection(b), b) for b in range(3, 7)])[0]
    codepoints = list([v for _, v in repeated_bytes[:2**b]])

    for i, v in enumerate(binary):
        if i in c.jump_table:
            #print 'marker'
            writer.write(1)
            writer.write(1)

        try:
            codepoint = codepoints.index(v)
        except ValueError:
            #print 'literal', hex(v)
            writer.write(0)
            writer.write_bits(v, 8)
        else:
            #print 'codepoint', codepoint
            writer.write(1)
            writer.write(0)
            writer.write_bits(codepoint, b)
    print 'Forth VM encoded into %d bytes.' % (writer.bits / 8)
    c.compile(payload, ForthCodeGenerator(writer))
    writer.flush()
    with open('packed_forth.s', 'w') as out_file:
        compress.generate_file(out_file, 'packed_data', writer, [
            ('BITS', b),
            ('ENTRY_POINT', symbols['forth_interpreter_start']),
            ('DICTIONARY', symbols['forth_dictionary']),
            ('UNCOMPRESSED_SIZE', len(binary)),
            ('FORTH', 1)
            ])
        out_file.write("table: .byte %s\n" % ", ".join(['0x%02X' % v for v in codepoints]))

if __name__ == '__main__':
    #c = ForthCompiler()
    #c.load_primitives()
    #s = open('test.forth', 'r').read()
    #c.compile(s)
    writer = compress.BitWriter()
    forth_compress(writer, open("test.forth").read())
    print writer.bits / 8
