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
  14                    		.public	_binsize
  15                    		.public	_binstart
  16                    		.public	_exit
  17                    		.public	__text
  18                    		.public	__data
  19                    		.public	__bss
  20                    	;
  21                    	;	PROGRAM STARTS HERE SINCE THIS FILE IS LINKED FIRST
  22                    	;
  23                    	;	First we must zero bss if needed
  24                    	;
  25                    		.psect	_text
  26                    	__text:
  27    0000  C30700    		jp	aftersize	;jump over the size,
  28                    					;also a kind of file signature
  29                    	_binsize:
  30    0003  0000      		.word   0		;the size of the binary file to be patched here
  31                    	_binstart:
  32    0005  0000      		.word	__text		;the start address of this program
  33                    	
  34                    	aftersize:
  35    0007  210000    		ld	hl, __memory	; __memory is the end of the bss
  36                    					; it is defined by the link line
  37    000A  110100    		ld	de, __bss	; __bss is the start of the bss (see below)
  38    000D  97        		sub	a
  39    000E  ED52      		sbc	hl, de		; compute size of bss
  40    0010  2809      		jr	z, bssok	; if zero do nothing
  41    0012  EB        		ex	de, hl
  42                    	loop:
  43    0013  3600      		ld	(hl), 0		; zero	bss
  44    0015  23        		inc	hl
  45    0016  1B        		dec	de
  46    0017  7B        		ld	a, e
  47    0018  B2        		or	d
  48    0019  20F8      		jr	nz, loop	; any more left ???
  49                    	bssok:
  50                    	;
  51                    	;	Then set up stack
  52                    	;
  53                    	;	The code below sets up an 8K byte stack
  54                    	;	
  55                    	;	after the bss. This code can be modified
  56                    	;
  57                    	;	to set up stack in any other convenient way
  58                    	;
  59    001B  010000    		ld	bc, __memory	; get end of bss 
  60    001E  DD210020  		ld	ix, 8192	; ix = 8K
  61    0022  DD09      		add	ix, bc		; ix = end of mem + 8k
  62    0024  DDF9      		ld	sp, ix		; init sp
  63                    	;
  64                    	;
  65                    	;	Perform ROM to RAM copy
  66                    	;   the -dprom option is specified on the compiler command line
  67                    	;
  68    0026  CD0000    		call	__toram
  69                    	;
  70                    	;       Initialize hardware
  71                    	;
  72    0029  CD0000    	        call    _hwinit
  73                    	;
  74                    	;
  75                    	;	Then call main
  76                    	;
  77    002C  CD0000    		call	_main
  78                    	_exit:				; exit code
  79    002F  18FE      		jr	_exit		; for now loop
  80                    	;
  81                    	;
  82                    	;-------------------------------------------------------
  83                    	;	NMI goes here, but first pad to address 0x0066
  84                    	nmipad:
  85    0031  00000000  		.byte	0 (066h - (nmipad - __text))
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
              00
  86    0066  C30000    	    jp spinmi
  87                    	;
  88                    	;
  89                    	;
  90                    		.psect	_data
  91                    	__data:
  92    0000  00        		.byte	0	; NULL cannot be a valid pointer
  93                    	;
  94                    	;
  95                    	;
  96                    		.psect	_bss
  97                    	__bss:			; define start of bss
  98                    		.end
