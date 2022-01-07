   1                    	;
   2                    	;	SAMPLE STARTUP CODE FOR FREESTANDING SYSTEM
   3                    	;	Copyright (c) 1989 by COSMIC (France)
   4                    	;
   5                    	;   Hacked by Hans-Ake Lund 2022 to work with
   6                    	;   Z80 Computer by jumping to a NMI based SPI
   7                    	;   interface using bit-banging on a PIO port
   8                    	;
   9                    		.external spinmi
  10                    		.external _main
  11                    		.external __memory
  12                    		.public	_exit
  13                    		.public	__text
  14                    		.public	__data
  15                    		.public	__bss
  16                    	;
  17                    	;	PROGRAM STARTS HERE SINCE THIS FILE IS LINKED FIRST
  18                    	;
  19                    	;	First we must zero bss if needed
  20                    	;
  21                    		.psect	_text
  22                    	__text:
  23    0000  210000    		ld	hl, __memory	; __memory is the end of the bss
  24                    					; it is defined by the link line
  25    0003  110100    		ld	de, __bss	; __bss is the start of the bss (see below)
  26    0006  97        		sub	a
  27    0007  ED52      		sbc	hl, de		; compute size of bss
  28    0009  2809      		jr	z, bssok	; if zero do nothing
  29    000B  EB        		ex	de, hl
  30                    	loop:
  31    000C  3600      		ld	(hl), 0		; zero	bss
  32    000E  23        		inc	hl
  33    000F  1B        		dec	de
  34    0010  7B        		ld	a, e
  35    0011  B2        		or	d
  36    0012  20F8      		jr	nz, loop	; any more left ???
  37                    	bssok:
  38                    	;
  39                    	;	Then set up stack
  40                    	;
  41                    	;	The code below sets up an 8K byte stack
  42                    	;	
  43                    	;	after the bss. This code can be modified
  44                    	;
  45                    	;	to set up stack in any other convenient way
  46                    	;
  47    0014  010000    		ld	bc, __memory	; get end of bss 
  48    0017  DD210020  		ld	ix, 8192	; ix = 8K
  49    001B  DD09      		add	ix, bc		; ix = end of mem + 8k
  50    001D  DDF9      		ld	sp, ix		; init sp
  51                    	;
  52                    	;
  53                    	;
  54                    	;	Then call main
  55                    	;
  56    001F  CD0000    		call	_main
  57                    	_exit:				; exit code
  58    0022  18FE      		jr	_exit		; for now loop
  59                    	;
  60                    	;-------------------------------------------------------
  61                    	;	NMI goes here, but first pad to address 0x0066
  62                    	nmipad:
  63    0024  00000000  		.byte	0 (066h - (nmipad - __text))
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
              00000000
              0000
  64    0066  C30000    	    jp spinmi
  65                    	;
  66                    	;
  67                    		.psect	_data
  68                    	__data:
  69    0000  00        		.byte	0	; NULL cannot be a valid pointer
  70                    	;
  71                    	;
  72                    	;
  73                    		.psect	_bss
  74                    	__bss:			; define start of bss
  75                    		.end
