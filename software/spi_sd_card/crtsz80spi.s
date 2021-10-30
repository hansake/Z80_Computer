;
;   Based on:
;	SAMPLE STARTUP CODE FOR FREESTANDING SYSTEM
;	Copyright (c) 1989 by COSMIC (France)
;
;   Hacked by Hans-Ake Lund 2021 to work with
;   Z80 Computer and a NMI based SPI interface
;   using bit-banging on a PIO port
;
.include "z80computer.inc"

	.external _main
	.external __memory
	.external __toram
	.external c.rets
	.external c.savs

	.public	_exit
	.public	__text
	.public	__data
	.public	__bss

	.public _spiinit
	.public _spiselect
	.public _spideselect
	.public _spiio

	.public	_out
	.public	_in
	.public _reload

	.public __romdata	;seems to be needed although
				;no romdata copy is done

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
;	Perform ROM to RAM copy, but not needed in this program
;
;
;	call	__toram
;
;
;	Then call main
;
	call	_main
_exit:				; exit code
	jr	_exit		; for now loop

;-------------------------------------------------------
;	NMI goes here, but first pad to address 0x0066
nmipad:
	.byte	0 (066h - (nmipad - __text))

; The NMI routine handles SPI byte input and output
; The alternate registers are set-up by C functions
; to send and receive one byte of data
; reg B: clock pulse counter for sending/receving a byte
; reg C: temporary save data to output
; reg D: byte to transmit
; reg E: received byte
; Bit 6 in PIO port B set to 1 indicates that the NMI routine executes
;       used for test/measurement
; Bit 7 in PIO port B set to 1 indicates that byte transfer
;       is ongoing and that the C functions
;       can not read or write the alternate registers
spinmi:
	ex af,af
	exx
	in a, (PIO_B_DATA)	;read input and current outputs

	; test/measurement signal
	or 40h			;set bit 6 to signal start of NMI
	out (PIO_B_DATA), a

	; SCK toggles for each NMI
	; output SCK signal on PIO B bit 2
	and 0fbh		;reset SCK (bit 2)
	bit 0,b			;reg B bit 0 controls SCK
	jr nz, spiscklow		;SCK is set to 0
	or 004h			;SCK set to 1
	; test MISO input signal from PIO B on SCK transition to 1
	scf
	ccf			;reset carry flag
	rl e			;shift reg E left, carry shifted into bit 0
	bit 0, a		;test MISO input (bit 0)
	jr z, spimisolow	;input was 0
	set 0, e		;input was 1
spimisolow:
	jr spisckhi
spiscklow:
	; set MOSI output signal to PIO B on SCK transition to 0
	and 0fdh		;reset MOSI (bit)
	rl d			;shift byte to send left into carry
	jr nc, spimosilow	;MOSI is set to 0
	or 002h			;MOSI set to 1
spimosilow:

spisckhi:
	; all NMIs handled for this byte?
	djnz spiend		;not yet
	; now all bits af the byte are sent
	; reset and stop CTC2 so that no NMIs are generated
	ld c, a
	ld a, 00000011b		;bit 1: sw reset, bit 0: this is a ctrl cmd
	out (CTC_CH2), a
	ld a, c
	or 002h			;MOSI set to 1
	and 07fh		;reset bit 7 to signal end of byte
spiend:

	; test/measurement signal
	and 0bfh		;reset bit 6 to signal end of NMI

	out (PIO_B_DATA), a

	exx
	ex af,af
	retn
;-------------------------------------------------------

; SPI C functions to control alternate registers,
; PIO B and CTC 2 for byte transfer by the NMI routine

; void spiinit(), called once for initialization
_spiinit:
	; reset CTC2 so that no NMIs are generated
	ld a, 00000011b		; bit 1: sw reset, bit 0: this is a ctrl cmd
	out (CTC_CH2), a

	; Set up PIO B, SPI interface
	ld a, 11001111b		; mode 3
	out (PIO_B_CTRL), a
	ld a, 00000001b		; i/o mask
	;bit 0: MISO - input     3                   3
	;bit 1: MOSI - output    4                   5
	;bit 2: SCK  - output    5                   7
	;bit 3: /CS0 - output    6                   9
	;bit 4: /CS1 - output  extra device select  11
	;bit 5: /CS2 - output  extra device select  10
	;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
	;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
	;                                                with an 8 bit transmit or receive transfer
	out (PIO_B_CTRL), a
	ld a, 00000111b		; int disable
	out (PIO_B_CTRL), a
	; bit 1: MOSI - output	;high
	; bit 2: SCK  - output	;low
	; bit 3: /CS0 - output	;high = not selected
	; bit 4: /CS1 - output	;high = not selected
	; bit 5: /CS2 - output	;high = not selected
	; bit 6: TP1  - output  ;low
	; bit 7: TRA  - output  ;low
	ld a, 00111010b		;initialize output bits
	out (PIO_B_DATA), a
	; initialize alternate registers to 0
	exx
	ld bc, 0
	ld de, 0
	exx
	ret

;void spiselect()
_spiselect:
	in a, (PIO_B_DATA)
	and 0f7h		;set /CS (bit 3) low i.e. active
	out (PIO_B_DATA), a	;indicate that i/o is ongoing
	ret

;void spideselect()
_spideselect:
	in a, (PIO_B_DATA)
	or 008h			;set /CS (bit 3) hign i.e. not active
	out (PIO_B_DATA), a	;indicate that i/o is ongoing
	ret

;unsigned int spiio(unsigned int), send/receive a byte
_spiio:
	call	c.savs
spiiowt1:
	in a, (PIO_B_DATA)	;wait until SPI i/o not ongoing
	bit 7, a
	jr nz, spiiowt1
	set 7, a
	out (PIO_B_DATA), a	;indicate that i/o is ongoing
	; set up alternate registers for NMI handling
	exx
	ld d, (ix+4)		;byte to transmit
	ld e, 0			;where the received byte ends up
	ld b, 17		;NMI counter, 2 * 8 pulses
				;+ 1 NMI before & the byte
	exx
	; start CTC2 counter to generate NMIs
	ld a, 047h		;counter, with time const
	out (CTC_CH2), a
	ld a, 100		;counter divider
				;NMI frequency = 20 kHz
				;SCK frequency = 10 kHz
	out (CTC_CH2), a
spiiowt2:
	in a, (PIO_B_DATA)	;wait until SPI byte i/o is ready
	bit 7, a
	jr nz, spiiowt2
	;get recieved byte
	exx
	ld a, e			;the recieved byte is in reg E
	exx
	ld c, a
	ld b, 0
	jp c.rets


; I/O C functions for the Z80 Computer
;
_in:
	call	c.savs
	ld	c,(ix+4)
	ld	b,(ix+5)
	in	a,(c)
	ld	c,a
	ld	b,0
	jp	c.rets
_out:
	call	c.savs
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	a,(ix+6)
	out	(c),a
	jp	c.rets

_reload:
	jp 0F003H

	.psect	_data
__data:
	.byte	0	; NULL cannot be a valid pointer


__romdata:		;needed by libm.80, find out why
;
;
;
	.psect	_bss
__bss:			; define start of bss
	.end

