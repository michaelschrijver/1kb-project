import midi
import midi.events
import sys
import itertools

TRACKER_NO_ENTRY = 0xfe
TRACKER_KEY_OFF = 0xff

def absolute_ticks(track):
    tick = 0
    for ev in track:
        tick += ev.tick
        ev.tick = tick
        yield ev

def sequence(pattern):
    current_tick = 0
    current_row = None
    for ev in sorted(filter(lambda e: issubclass(type(e), midi.events.NoteEvent), itertools.chain(*[absolute_ticks(track) for track in pattern])), key = lambda e: (e.tick, e.channel)):
        print ev
        if ev.tick != current_tick:
            if current_row is not None:
                yield tuple(current_row)
            current_row = None
            for tick in xrange(current_tick + 1, ev.tick):
                yield (TRACKER_NO_ENTRY,) * 8
            current_tick = ev.tick
        else:
            if current_row is None:
                current_row = [TRACKER_NO_ENTRY] * 8

            if ev.channel < 9:
                current_row[ev.channel - 1] = ev.pitch
for filename in sys.argv[1:]:
    pattern = midi.read_midifile(filename)
    #print pattern[1]
    print len(sequence(pattern))
    #for event in sequence(pattern):
    #    print event
