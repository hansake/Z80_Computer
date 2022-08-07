; z80upload.s
;
; Uploader for my DIY Z80 computer. This program
; can upload files to memory using Xmodem,
; execute the uploaded program and reboot.
;
; You are free to use, modify, and redistribute
; this source code. The software is provided "as is",
; without warranty of any kind.
; Hastily Cobbled Together 2021 and 2022
; by Hans-Ake Lund.
; Modified to be assembled with Whitesmiths/COSMIC x80
;
; The upload program is copied from EPROM or RAM
; by the calling program into high RAM memory
; at UPLADR address where it is executed

.include "z80comp.inc"

; Define address where upload is running (should really be given in the Makefile)
.define UPLADR = 0b000h

; Character definitions, mainly for Xmodem protocol
;
.define EOS		= 00h	; End Of String
.define CR		= 0dh	; Carriage Return (ENTER)
.define LF		= 0ah	; Line Feed
.define SPACE		= 20h	; Space
.define TAB		= 09h	; Tabulator
.define SOH		= 01h	; Xmodem start of header
.define EOT		= 04h	; Xmodem end of transfer
.define ACK		= 06h	; Xmodem ACK
.define NAK		= 15h	; Xmodem NAK
.define CTRLC		= 03h	; Control-C

; Serial channel timeout loop counter
.define GETCTM	= 9000		; loop counter for ~1 sec timeout

; Pointer to address where the file will be uploaded
.define UPLPTR      = 0fef0h
; Pointer to address where to start executing
.define EXEPTR      = 0fef2h

; The program starts here when invoked
;	org UPLADR
monitor:
	jp startupl

; Reload from EPROM
epromreload:
	ld a, 00000011b		; sw reset CTC2 to stop NMIs
	out (CTC_CH2), a
	out (MEMEPROM), a	; select EPROM in lower 32KB address range
	jp 0000h		; and jump to start of EPROM

startupl:
	; initialize stack pointer below code
	ld sp, UPLADR
	; the hardware is supposed to be initialized by the
	; program that is uploading this code
	out (LEDOFF),a	; Green LED off

	; upload and go
	di
	call upload
	jp execute

; Upload file to RAM
upload:
	ld hl, upload_msg
	call print_string
	out (MEMLORAM),a	; select RAM in lower 32KB address range

; Xmodem recieve file and put in memory
; protocol description
;   http://pauillac.inria.fr/~doligez/zmodem/ymodem.txt
; (much of the code is proudly stolen from PCGET.ASM)
xupload:

	; gobble up garbage characters from the line
xpurge:
	ld b, 1
	call getct
	jr c, xrecieve
	cp CTRLC		;Ctrl-C was recieved
	jp z, xabort
	jr xpurge		;loop until sender done

	; Recieve file and put in memory
xrecieve:
	ld hl, (UPLPTR)		;where to start putting memory in RAM
	ld (memptr), hl

	ld a, 0			;initialize last sector number
	ld (xlsectno), a

	ld a, NAK		;send NAK
	call putc

	; Recieve header
xgethdr:
	ld b, 3			;3 seconds timeout
	call getct
	jr nc, xgethchr		;no timeout, identify character in header

	; Header error or timeout
	; purge input characters and send NAK
xhdrerr:
	ld b, 1
	call getct
	jr nc, xhdrerr		;loop until sender done
	ld a, NAK
	call putc
	jr xgethdr		;try to get header again

	; Which type of header? SOH, EOT or Ctrl-C to abort
xgethchr:
	cp SOH
	jr z, xgotsoh
	cp CTRLC
	jp z, xabort
	cp EOT
	jp z, xgoteot
	jr xhdrerr

	; Got SOH header
xgotsoh:

	ld b, 1
	call getct
	jr c, xhdrerr
	ld d, a			;sector number
	ld b, 1
	call getct
	jr c, xhdrerr
	cpl			;complement of block number
	cp d
	jr z, xgetsec		;good sector header, get sector
	jr xhdrerr

	; Get sector and put in temporary buffer
xgetsec:
	ld a, d
	ld (xcsectno), a	;current sector
	ld c, 0			;init checksum
	ld hl, xsectbuf		;temporary buffer for uploaded data
	ld d, 128		;sector length
xgetschar:
	ld b, 1
	call getct
	jr c, xhdrerr
	ld (hl), a		;store byte in memory
	add c			;calculate checksum
	ld c, a
	inc hl
	dec d
	jr nz, xgetschar

	; Verify the checksum
	ld d, c			;verify checksum
	ld b, 1
	call getct
	jr c, xhdrerr
	cp d
	jr nz, xhdrerr

	; Check that this sector number is last sector + 1
	ld a, (xcsectno)
	ld b, a
	ld a, (xlsectno)
	inc a
	cp b
	jr z, xwrtsec		;expected sector number ok

	; sender missed last ACK
	jr xsndack

	; got new sector, write it to memory
xwrtsec:

	ld a, (xcsectno)	;update sector number
	ld (xlsectno), a
	ld de, (memptr)		;where to put the uploaded data
	ld hl, xsectbuf		;from the recieve buffer
	ld bc, 128
xcpymem:
	ldir
	ld (memptr), de		;update the destination in memory
xsndack:
	ld a, ACK		;send ACK
	call putc
	jp xgethdr		;get next sector

	; Got EOT, upload finished
xgoteot:

	ld a, ACK
	call putc

	;write message that upload was ok
	ld hl, 30000     ;but wait a while first
xokwait:
    dec hl
	ld a, h
    or l
    jr nz, xokwait 
	ld hl, upcpl_msg
	call print_string

	ret

xabort:
	ld hl, uperr_msg	;write message that upload was interrupted
	call print_string
	jp epromreload

upload_msg:
	.text "uploading file ", 0

upcpl_msg:
	.text "- upload complete\r\n", 0

uperr_msg:
	.text "\r\nupload interrupted\r\n", 0


; Execute code in RAM
execute:
	out (MEMLORAM),a	; select RAM in lower 32KB address range
	ld hl, execute_msg
	call print_string
	ld hl, (EXEPTR)
	jp (hl)

execute_msg:
	.text "executing code in RAM\r\n", 0

; tx_ready: waits for transmitt buffer to become empty
; affects: none
sio_tx_ready:
	push af
	push bc
sio_tx_ready_loop:
	in a, (SIO_A_CTRL)	; read RR0
	bit 2, a		; check if bit 2 is set
	jr z, sio_tx_ready_loop	; if no - check again
	pop bc
	pop af
	ret

; rx_ready: waits for a character to become available
; affects: none
sio_rx_ready:
	push af
	push bc
sio_rx_ready_loop:
	in a, (SIO_A_CTRL)	; read RR0
	bit 0, a		; check if bit 0 is set
	jr z, sio_rx_ready_loop	; if no - rx buffer has no data => check again
	pop bc
	pop af
	ret

; sends byte in reg A
; affects: none
putc:
	push bc
	push af
	call sio_tx_ready
	pop af
	out (SIO_A_DATA), a	; write character
	pop bc
	ret

; getc: waits for a byte to be available and reads it
; returns: A - read byte
getc:
	push bc
	call sio_rx_ready	; wait until there is a character
	in a, (SIO_A_DATA)	; read character
	pop bc
	ret

; getct: waits for a byte to be available with timeout and reads it
; reg B - timeout in seconds
; returns:
;   Carry = 1: timeout, Carry = 0: no timeout
;   reg A - read byte
getct:
	push bc
	push de
	ld de, GETCTM
getcloop:
	in a, (SIO_A_CTRL)	; read RR0
	bit 0, a		; check if bit 0 is set
	jr nz, getchrin		; character available
	dec de
	ld a, d
	or e
	jr nz, getcloop		; inner loop
	djnz getcloop		; outer loop, number of seconds
	jr getcnochr		; timeout
getchrin:
	in a, (SIO_A_DATA)	; read character
	pop de
	pop bc
	scf
	ccf			; Carry = 0, no timeout
	ret
getcnochr:
	ld a, 0
	pop de
	pop bc
	scf			; Carry = 1, timeout
	ret

; getkey: gets a byte if available and reads it
; returns: A - read byte or 0 if no byte available
getkey:
	push bc
	in a, (SIO_A_CTRL)	; read RR0
	bit 0, a		; check if bit 0 is set
	jr z, no_key		; if no - rx buffer has no data => return 0
	in a, (SIO_A_DATA)	; read character
	pop bc
	ret
no_key:
	ld a, 0
	pop bc
	ret

; print_string: prints a string which starts at adress HL
; and is terminated by EOS-character
; affects: none
print_string:
	push af
	push hl
print_string_1:
	ld a,(hl)		; load next character
	cp 0			; is it en End Of String - character?
	jr z, print_string_2	; yes - return
	call putc		; no - print character
	inc hl			; HL++
	jr print_string_1	; do it again
print_string_2:
	pop hl
	pop af
	ret

; Variables
memptr:		;pointer to the memory address where to put data
	.word 0
xcsectno:	;current recieved sector number
	.byte 0
xlsectno:	;last recieved sector number
	.byte 0
xsectbuf:	;temporary recieve sector buffer
	.byte 0, [128]

; End of monitor code
monend:

.end

