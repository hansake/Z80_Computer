z80test.bin : z80test.z80 z80hightest.bin
	z80asm --list=z80test.lst --output=z80test.bin z80test.z80

z80hightest.bin : z80hightest.z80
	date +'    db ", Built %F %R"' > built.z80
	z80asm --list=z80hightest.lst --output=z80hightest.bin z80hightest.z80

