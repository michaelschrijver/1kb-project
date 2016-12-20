# ecx            0x0      0
#edx            0x663    1635
#ebx            0x0      0
#esp            0x0      0x0
#ebp            0x0      0x0
#esi            0x0      0
#edi            0x0      0
#eip            0xfff0   0xfff0
#eflags         0x2      [ ]
#cs             0xf000   61440
#ss             0x0      0
#ds             0x0      0
#es             0x0      0
#fs             0x0      0
#gs             0x0      0
#   0xffff0:     jmp    0xf0135

import re
import collections

reg_re = re.compile('(eax|ebx|ecx|edx|ebp|esp|esi|edi|eip|eflags|cs|ss|ds|es|fs|gs)\s+0x([0-9a-f]+)')
ins_re = re.compile('\s*0x([0-9a-f]+):\s+(.*)')
out_re = re.compile('out\s+%(\S+),\(%(\S+)\)')

registers = collections.defaultdict(lambda :None)
changes = []
with open('trace.log') as f:
    for line in f:
        m = reg_re.match(line)
        if m:
            register = m.group(1)
            value = int(m.group(2), 16)
            if registers[register] != value:
                changes.append((register, value))
        else:
            m = ins_re.match(line)
            if m:
                offset = int(m.group(1), 16)
                instruction = m.group(2)
                if changes:
                    #print '\t\t\t\t\t',
                    for register, value in changes:
                        registers[register] = value
                        #if register != 'eip':
                        #    print '%s = 0x%x' % (register, value),
                    #print
                if instruction.startswith('out '):
                    out_m = out_re.match(instruction)
                    if not out_m:
                        print repr(instruction)
                    if out_m.group(1) == 'al':
                        value = registers['eax'] & 0xff
                        size = 'b'
                    else:
                        value = registers['eax']
                        size = 'w'
                    print('%s: %s %x -> %x' % (m.group(1), size, value, registers['edx']))
                elif instruction.startswith('in '):
                    print('%s: <- %x' % (m.group(1), registers['edx']))

                changes = []
