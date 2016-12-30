all: bitdec.bin
ASFLAGS=-L
vga_palette.s: palette.py
	python palette.py > vga_palette.s

note_data.s: notes.py compress.py
	python notes.py

forth.o: forth.s

forth.bin: forth.o
	ld -Map=forth.map -o forth.bin -T 1kb.lds forth.o

packed_forth.s: forth.py forth.o forth.bin test.forth
	python forth.py

packed_forth.o: bitdec.s packed_forth.s
	as -o packed_forth.o --defsym FORTH=1 bitdec.s

packed_forth.bin: packed_forth.o
	ld -Map=packed_forth.map -o packed_forth.bin -T 1kb.lds packed_forth.o

font3x5.s: font3x5.py
	python font3x5.py

1kb.o: 1kb.s vga.s vga_registers.s vgafont16.s pic.s i8042.s vga_palette.s opl.s notes.s tracker.s notes.s note_data.s font.s font3x5.s

1kb.bin: 1kb.o 1kb.lds
	ld -Map=1kb.map -o 1kb.bin -T 1kb.lds 1kb.o

packed_data.s: 1kb.bin compress.py
	ENTRY=$$(objdump -t 1kb.o | egrep ' entry$$'|awk '{print $$1}') ; \
		python compress.py 1kb.bin packed_data.s $$ENTRY

bitdec.o: bitdec.s packed_data.s

bitdec.bin: bitdec.o packed_data.s
	ld -Map=bitdec.map -o bitdec.bin -T 1kb.lds bitdec.o

register_init.o: register_init.s

register_init: register_init.o
	ld -o register_init -T 1kb.lds register_init.o

size: 1kb.bin
	@SIZE=$$(egrep ^.text 1kb.map | awk '{print $$3}'); SIZE=$$(printf "%d" $$SIZE) ; if [ $$SIZE -gt 1024 ] ; then printf "%d bytes left to remove\n" $$(($$SIZE - 1024)) ; else printf "%d bytes left to add\n" $$((1024 - $$SIZE)) ; fi

run-qemu: bitdec.bin
	qemu-system-x86_64 -bios bitdec.bin -soundhw adlib -debugcon stdio

run-bochs: bitdec.bin
	bochs 'port_e9_hack: enabled=1' 'romimage: file=./bitdec.bin' 

clean:
	rm -f 1kb.bin *.o
