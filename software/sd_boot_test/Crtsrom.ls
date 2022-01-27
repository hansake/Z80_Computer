   1                    	;
   2                    	;	SAMPLE STARTUP CODE FOR FREESTANDING SYSTEM
   3                    	;	Copyright (c) 1989 by COSMIC (France)
   4                    	;
   5                    	;   Hacked by Hans-Ake Lund 2022 to work with
   6                    	;   Z80 Computer by jumping to a NMI based SPI
   7                    	;   interface using bit-banging on a PIO port
   8                    	;
   9                    		.external spinmi
  10                    		.external _hwinit
  11                    		.external _main
  12                    		.external __memory
  13                    		.external __toram
  14                    		.public	_exit
  15                    		.public	__text
  16                    		.public	__data
  17                    		.public	__bss
  18                    	;
  19                    	;	PROGRAM STARTS HERE SINCE THIS FILE IS LINKED FIRST
  20                    	;
  21                    	;	First we must zero bss if needed
  22                    	;
  23                    		.psect	_text
  24                    	__text:
  25    0000  210000    		ld	hl, __memory	; __memory is the end of the bss
  26                    					; it is defined by the link line
  27    0003  110100    		ld	de, __bss	; __bss is the start of the bss (see below)
  28    0006  97        		sub	a
  29    0007  ED52      		sbc	hl, de		; compute size of bss
  30    0009  2809      		jr	z, bssok	; if zero do nothing
  31    000B  EB        		ex	de, hl
  32                    	loop:
  33    000C  3600      		ld	(hl), 0		; zero	bss
  34    000E  23        		inc	hl
  35    000F  1B        		dec	de
  36    0010  7B        		ld	a, e
  37    0011  B2        		or	d
  38    0012  20F8      		jr	nz, loop	; any more left ???
  39                    	bssok:
  40                    	;
  41                    	;	Then set up stack
  42                    	;
  43                    	;	The code below sets up an 8K byte stack
  44                    	;	
  45                    	;	after the bss. This code can be modified
  46                    	;
  47                    	;	to set up stack in any other convenient way
  48                    	;
  49    0014  010000    		ld	bc, __memory	; get end of bss 
  50    0017  DD210020  		ld	ix, 8192	; ix = 8K
  51    001B  DD09      		add	ix, bc		; ix = end of mem + 8k
  52    001D  DDF9      		ld	sp, ix		; init sp
  53                    	;
  54                    	;
  55                    	;	Perform ROM to RAM copy
  56                    	;   the -dprom option is specified on the compiler command line
  57                    	;
  58    001F  CD0000    		call	__toram
  59                    	;
  60                    	;       Initialize hardware
  61                    	;
  62    0022  CD0000    	        call    _hwinit
  63                    	;
  64                    	;
  65                    	;	Then call main
  66                    	;
  67    0025  CD0000    		call	_main
  68                    	_exit:				; exit code
  69    0028  18FE      		jr	_exit		; for now loop
  70                    	;
  71                    	;
  72                    	;-------------------------------------------------------
  73                    	;	NMI goes here, but first pad to address 0x0066
  74                    	nmipad:
  75    002A  00000000  		.byte	0 (066h - (nmipad - __text))
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
  76    0066  C30000    	    jp spinmi
  77                    	;
  78                    	;
  79                    	;
  80                    		.psect	_data
  81                    	__data:
  82    0000  00        		.byte	0	; NULL cannot be a valid pointer
  83                    	;
  84                    	;
  85                    	;
  86                    		.psect	_bss
  87                    	__bss:			; define start of bss
  88                    		.end
