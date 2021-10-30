z80mon.bin : z80mon.z80
	date +'    db ", Built %F %R"' > mbuilt.z80
	./z80asm --list=z80mon.lst --output=z80mon.bin z80mon.z80
	cp z80mon.bin ~/Z80_computer
