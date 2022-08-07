; z80aio.s
;
; Assembler SPI routines for the Z80 computer.
;
; Hacked together by Hans-Ake Lund 2021 and 2022
; to work with Z80 Computer and a NMI based
; SPI interface using bit-banging on a PIO port
;
; The SPI interface has the option of not using NMI,
; the reason for this is that the NMI routine address (66h)
; is in the middle of the default FCB area for CP/M.
; NMI driven SPI interface is more suitable for a multi tasking
; operating system.
;
.include "z80comp.inc"

.define NMISPI = 0 ;set to 1 for NMI driven SPI interface

	.external c.savs
	.external c.rets

	.public spinmi
	.public _spiinit
	.public _spiselect
	.public _spideselect
	.public _spiio

	.public _blk2byte
	.public _jumpto
	.public _reload
	.public _addblk

;-------------------------------------------------------
;	NMI with a jump from address 0x0066
;       if NMI driven SPI interface is configured
;
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

.if NMISPI = 0
	;if not NMI driven, return directly
	retn
.endif
spipolled:
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
.if NMISPI
	retn
.else
	ret
.endif

;-------------------------------------------------------
; SPI C functions to set alternate registers for SPI i/o,
; PIO B and CTC 2 are used for byte transfer by the NMI routine.

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

;/* Select the SPI SD card
; */
;void spiselect()
_spiselect:
	in a, (PIO_B_DATA)
	and 0f7h		;set /CS (bit 3) low i.e. active
	out (PIO_B_DATA), a
	ret

;/* Deselect the SPI SD card
; */
;void spideselect()
_spideselect:
	in a, (PIO_B_DATA)
	or 008h			;set /CS (bit 3) hign i.e. not active
	out (PIO_B_DATA), a
	ret

;/* send/receive a byte over SPI interface
; */
;unsigned int spiio(unsigned int)
_spiio:
	call	c.savs
spiiowt1:
	in a, (PIO_B_DATA)	;wait until SPI i/o not ongoing
	bit 7, a
.if SPINMI
	jr nz, spiiowt1
.else
	jr z, spiidle ;this will probably never happen
	call spipolled
	jr spiiowt1
spiidle:
.endif
	set 7, a
	out (PIO_B_DATA), a	;indicate that i/o is ongoing
	; set up alternate registers for NMI handling
	exx
	ld d, (ix+4)		;byte to transmit
	ld e, 0			;where the received byte ends up
	ld b, 17		;NMI counter, 2 * 8 pulses
				;+ 1 NMI before & the byte
	exx
.if SPINMI
	; start CTC2 counter to generate NMIs
	ld a, 047h		;counter, with time const
	out (CTC_CH2), a
	ld a, 100		;counter divider
				;NMI frequency = 20 kHz
				;SCK frequency = 10 kHz
	out (CTC_CH2), a
.endif
spiiowt2:
	in a, (PIO_B_DATA)	;wait until SPI byte i/o is ready
	bit 7, a
.if SPINMI
	jr nz, spiiowt2
.else
	jr z, spiready
	call spipolled
	jr spiiowt2
spiready:
.endif
	;get recieved byte
	exx
	ld a, e			;the recieved byte is in reg E
	exx
	ld c, a
	ld b, 0
	jp c.rets

;/* Make block address to byte address
; * by multiplying with 512 (blocksize)
; */
;int blk2byte(unsigned char *)
_blk2byte:
	;dsk parameter in HL
	; shift left 8 bits
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	ld	(hl), 0
	; then shift left 1 bit
	dec	hl
	sla	(hl)
	dec	hl
	rl	(hl)
	dec	hl
	rl	(hl)
	ret

; Jump to address
_jumpto:
	jp (hl)		;jump to address

; Reload from EPROM
_reload:
        out (MEMEPROM),a ; select EPROM in lower 32KB address range
        jp 0000h         ;jump to start of EPROM

;/* Add block addresses
; */
;void addblk(unsigned char *, unsigned char *);
_addblk:
	;first dsk parameter in HL
	ld	de, 3	;put pointer to LSB in DE
	add	hl, de
	ld	e, l
	ld	d, h
	;second dsk parameter on stack
	ld	hl, 2
	add	hl, sp
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	hl, 3	;put pointer to LSB in HL
	add	hl, bc

	ld	b, 4
	scf
	ccf
addit:
	ld	a, (de)
	adc	a, (hl)
	ld	(de),  a
	dec	de
	dec	hl
	djnz	addit
	ret

;------------------------------------
; A minimal debug probe with printout
; of a character
;------------------------------------
; Minimal print probe,
; insert in the code
;    rst 38h
;    .byte 'x' ;character to print
;
; implemented as the macro PRTPROB
;
;    .macro PRTPROB
;    rst 7 ;rst 38h in Zilog manual
;    .byte ?1
;    .endm

    .public mprobini

; Initialize probe
mprobini:
    ld  a, 0c3h    ;c3 is a jmp instruction
    ld (038h), a   ;for jmp to mprobe for rst 7
    ld hl, mprobe
    ld (039h), hl
    ret

; The routine to print the character
mprobe:
    ex (sp), hl
    push af
txwait:
    in  a, (SIO_A_CTRL)
    and 004h        ;check TxRDY bit
    jp  z, txwait   ;loop until port ready
    ld a, (hl)
    out (SIO_A_DATA), a ;out to port
    pop  af
    inc hl
    ex (sp), hl
    ret

;------------------------------------
	.end

