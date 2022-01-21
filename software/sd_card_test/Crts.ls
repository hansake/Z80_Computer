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
  13                    		.public	_exit
  14                    		.public	__text
  15                    		.public	__data
  16                    		.public	__bss
  17                    	;
  18                    	;	PROGRAM STARTS HERE SINCE THIS FILE IS LINKED FIRST
  19                    	;
  20                    	;	First we must zero bss if needed
  21                    	;
  22                    		.psect	_text
  23                    	__text:
  24    0000  210000    		ld	hl, __memory	; __memory is the end of the bss
  25                    					; it is defined by the link line
  26    0003  110100    		ld	de, __bss	; __bss is the start of the bss (see below)
  27    0006  97        		sub	a
  28    0007  ED52      		sbc	hl, de		; compute size of bss
  29    0009  2809      		jr	z, bssok	; if zero do nothing
  30    000B  EB        		ex	de, hl
  31                    	loop:
  32    000C  3600      		ld	(hl), 0		; zero	bss
  33    000E  23        		inc	hl
  34    000F  1B        		dec	de
  35    0010  7B        		ld	a, e
  36    0011  B2        		or	d
  37    0012  20F8      		jr	nz, loop	; any more left ???
  38                    	bssok:
  39                    	;
  40                    	;	Then set up stack
  41                    	;
  42                    	;	The code below sets up an 8K byte stack
  43                    	;	
  44                    	;	after the bss. This code can be modified
  45                    	;
  46                    	;	to set up stack in any other convenient way
  47                    	;
  48    0014  010000    		ld	bc, __memory	; get end of bss 
  49    0017  DD210020  		ld	ix, 8192	; ix = 8K
  50    001B  DD09      		add	ix, bc		; ix = end of mem + 8k
  51    001D  DDF9      		ld	sp, ix		; init sp
  52                    	;
  53                    	;	Initialize hardware
  54                    	;
  55    001F  CD0000    		call	_hwinit
  56                    	;
  57                    	;	Then call main
  58                    	;
  59    0022  CD0000    		call	_main
  60                    	_exit:				; exit code
  61    0025  18FE      		jr	_exit		; for now loop
  62                    	;
  63                    	;-------------------------------------------------------
  64                    	;	NMI goes here, but first pad to address 0x0066
  65                    	nmipad:
  66    0027  00000000  		.byte	0 (066h - (nmipad - __text))
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
              000000
  67    0066  C30000    	    jp spinmi
  68                    	;
  69                    	;
  70                    		.psect	_data
  71                    	__data:
  72    0000  00        		.byte	0	; NULL cannot be a valid pointer
  73                    	;
  74                    	;
  75                    	;
  76                    		.psect	_bss
  77                    	__bss:			; define start of bss
  78                    		.end
