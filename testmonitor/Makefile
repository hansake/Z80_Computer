z80tmon.bin : z80tmon.z80 z80hitmon.bin
	./z80asm --list=z80tmon.lst --output=z80tmon.bin z80tmon.z80

z80hitmon.bin : z80hitmon.z80
	date +'    db ", Built %F %R"' > built.z80
	z80asm --list=z80hitmon.lst --output=z80hitmon.bin z80hitmon.z80

z80ultst.bin : z80ultst.z80
	date +'    db ", Built %F %R"' > tbuilt.z80
	z80asm --list=z80ultst.lst --output=z80ultst.bin z80ultst.z80
	cp z80ultst.bin ~/Z80_computer
