;
;	SAMPLE STARTUP CODE FOR FREESTANDING SYSTEM
;	Copyright (c) 1989 by COSMIC (France)
;
;   Hacked by Hans-Ake Lund 2022 to work with
;   Z80 Computer by jumping to a NMI based SPI
;   interface using bit-banging on a PIO port
;
	.external spinmi
	.external _main
	.external __memory
	.public	_exit
	.public	__text
	.public	__data
	.public	__bss
;
;	PROGRAM STARTS HERE SINCE THIS FILE IS LINKED FIRST
;
;	First we must zero bss if needed
;
	.psect	_text
__text:
	ld	hl, __memory	; __memory is the end of the bss
				; it is defined by the link line
	ld	de, __bss	; __bss is the start of the bss (see below)
	sub	a
	sbc	hl, de		; compute size of bss
	jr	z, bssok	; if zero do nothing
	ex	de, hl
loop:
	ld	(hl), 0		; zero	bss
	inc	hl
	dec	de
	ld	a, e
	or	d
	jr	nz, loop	; any more left ???
bssok:
;
;	Then set up stack
;
;	The code below sets up an 8K byte stack
;	
;	after the bss. This code can be modified
;
;	to set up stack in any other convenient way
;
	ld	bc, __memory	; get end of bss 
	ld	ix, 8192	; ix = 8K
	add	ix, bc		; ix = end of mem + 8k
	ld	sp, ix		; init sp
;
;
;
;	Then call main
;
	call	_main
_exit:				; exit code
	jr	_exit		; for now loop
;
;-------------------------------------------------------
;	NMI goes here, but first pad to address 0x0066
nmipad:
	.byte	0 (066h - (nmipad - __text))
    jp spinmi
;
;
	.psect	_data
__data:
	.byte	0	; NULL cannot be a valid pointer
;
;
;
	.psect	_bss
__bss:			; define start of bss
	.end
