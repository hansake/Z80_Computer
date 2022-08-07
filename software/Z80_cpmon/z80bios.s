; z80bios.s
;
; BIOS for my DIY Z80 computer.
; Large parts of the code is copied from:
; https://github.com/mastmees/z-one/blob/master/software/bios.asm
; and also from: http://cpuville.com/Code/z80_cbios_asm.txt
;
; The code from z-one contains this license:
;
;  The MIT License (MIT)
;
;  Copyright (c) 2018 Madis Kaal <mast@nomad.ee>
;
;  Permission is hereby granted, free of charge, to any person obtaining a copy
;  of this software and associated documentation files (the "Software"), to deal
;  in the Software without restriction, including without limitation the rights
;  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;  copies of the Software, and to permit persons to whom the Software is
;  furnished to do so, subject to the following conditions:
;
;  The above copyright notice and this permission notice shall be included in all
;  copies or substantial portions of the Software.
;
;  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;  SOFTWARE.
;
; Modified for Whitesmiths/COSMIC x80 assembler and tools for Z80.
;
; Disks are implemented with a SD card through a SPI interface.
;
; You are free to use, modify, and redistribute
; this source code implementing the modifications.
; No warranties of any kind are given.
;
; The adoptions were Hastily Cobbled Together 2022 by Hans-Ake Lund
;
.include "z80comp.inc"
.include "cpm.inc"

; The subroutines provided by this BIOS code:
.public CBOOT, WBOOT, CONST, CONIN, CONOUT, LIST, PUNCH, READER
.public HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, LISTST, SECTRN

;To interface with the read/write routines
.public _spt    ;word
.public _diskno, _track, _sector, _dmaad

; SD card read and write routines
.external _rdsdsec
.external _wrsdsec
; initialize minimal debug output
.external mprobini

; The BIOS also needs to know the BDOS entry point
.external FBASE

.define dskblks =   243             ;disk size in logical blocks

.define nsects = (bios - ccp)/128   ;warm start sector count
;
;	jump vectors for individual subroutines
;
CBOOT:	jp	_boot	;cold start
WBOOT:	jp	_wboot	;warm start
CONST:	jp	_const	;console status
CONIN:	jp	_conin	;console character in
CONOUT:	jp	_conout	;console character out
LIST:	jp	_list	;list character out
PUNCH:	jp	_punch	;punch character out
READER:	jp	_reader	;reader character out
HOME:	jp	_home	;move head to home position
SELDSK:	jp	_seldsk	;select disk
SETTRK:	jp	_settrk	;set track number
SETSEC:	jp	_setsec	;set sector number
SETDMA:	jp	_setdma	;set dma address
READ:	jp	_read	;read disk
WRITE:	jp	_write	;write disk
LISTST:	jp	_listst	;return list status
SECTRN: jp	_sectran ;sector translate
;
;   fixed data tables for 4 drives
;
dpbase:
;
;	fixed data tables for four standard
;	IBM-compatible 8" SD disks (disktool-type: ibm-3740)
;
;	disk parameter header for disk 00
    .word trans     ;translation table
    .word 0000h,0000h,0000h ;CP/M workspace
    .word dirbf     ;address of 128 byte sector buffer (shared)
    .word dpblk     ;DPB address
    .word chk00     ;directory checksums
    .word all00     ;disk allocation vector
;	disk parameter header for disk 01
    .word trans     ;translation table
    .word 0000h,0000h,0000h ;CP/M workspace
    .word dirbf     ;address of 128 byte sector buffer (shared)
    .word dpblk     ;DPB address
    .word chk01     ;directory checksums
    .word all01     ;disk allocation vector
;   disk parameter header for disk 02
    .word trans     ;translation table
    .word 0000h,0000h,0000h ;CP/M workspace
    .word dirbf     ;address of 128 byte sector buffer (shared)
    .word dpblk     ;DPB address
    .word chk02     ;directory checksums
    .word all02     ;disk allocation vector
;   disk parameter header for disk 03
    .word trans     ;translation table
    .word 0000h,0000h,0000h ;CP/M workspace
    .word dirbf     ;address of 128 byte sector buffer (shared)
    .word dpblk     ;DPB address
    .word chk03     ;directory checksums
    .word all03     ;disk allocation vector
dpend:
; Number of disks in the system, every parameter block is 16 bytes
.define ndisks= (dpend-dpbase)/16

;
;	sector translate vector for the IBM 8" SD disks
;
trans:	.byte	1,7,13,19	;sectors 1,2,3,4
	.byte	25,5,11,17	;sectors 5,6,7,8
	.byte	23,3,9,15	;sectors 9,10,11,12
	.byte	21,2,8,14	;sectors 13,14,15,16
	.byte	20,26,6,12	;sectors 17,18,19,20
	.byte	18,24,4,10	;sectors 21,22,23,24
	.byte	16,22		;sectors 25,26

;disk parameter block, for floppy disks

dpblk:
_spt:
    .word 26        ;SPT number of 128 byte sectors per track
    .byte 3         ;BSH block shift factor (128<<bsf=block size)
    .byte 7         ;BLM block mask (blm+1)*128=block size
    .byte 0         ;EXM extent mask EXM+1 physical extents per
                    ;dir entry
    .word dskblks-1 ;disk size-1, in blocks
    .word 63        ;directory max, 1 block for directory=512
                    ;directory entries
    .byte 192       ;alloc 0
    .byte 0         ;alloc 1
    .word 16        ;check size, 0 for fixed disks
    .word 2         ;track offset for boot tracks
;
;   end of fixed tables
;
;   individual subroutines to perform each function
;
; cold boot loader, this is only invoked once, 
; when the CP/M is initially loaded
_boot:
    ;simplest case is to just perform parameter initialization
    ld sp, 80h      ;use space below buffer for stack
    call verprt     ;print BIOS version
    call mprobini   ;initialize debug print probe
    xor a           ;zero in the accum
    ld (iobyte), a  ;clear the iobyte
    ld (cdisk), a   ;select disk zero
    jp gocpm        ;initialize and go to cp/m

; warm boot loader, this is called to
; reload ccp & bdos in case it was overwritten by application
; simplest case is to read the disk until all sectors loaded
_wboot:
    ld sp, 80h      ;use space below buffer for stack
    ld c, 0         ;select disk 0
    call _seldsk
    call _home      ;go to track 00

    jp epromload    ;for now CP/M is loaded from EPROM

    ld b, nsects    ;B counts * of sectors to load
    ld c, 0         ;C has the current track number
    ld d, 2         ;D has the next sector to read
;   note that we begin by reading track 0, sector 2 since sector 1
;   contains the cold start loader, which is skipped in a warm start
    ld  hl, ccp     ;base of cp/m (initial load point)
load1:
;   load   one more sector
    push bc         ;save sector count, current track
    push de         ;save next sector to read
    push hl         ;save dma address
    ld c, d         ;get sector address to register C
    call _setsec    ;set sector address from register C
    pop bc          ;recall dma address to BC
    push bc         ;replace on stack for later recall
    call _setdma    ;set dma address from BC
;   drive set to 0, track set, sector set, dma address set
    call _read
    cp 00h          ;any errors?
    jp nz, _wboot   ;retry the entire boot if an error occurs
;   no error, move to next sector
    pop hl          ;recall dma address
    ld de, 128      ;dma = dma + 128
    add hl, de      ;new dma address is in HL
    pop de          ;recall sector address
    pop bc          ;recall number of sectors remaining, and current trk
    dec b           ;sectors = sectors - 1
    jp z, gocpm     ;transfer to cp/m if all have been loaded
;   more    sectors remain to load, check for track change
    inc d
    ld a, d         ;sector == 129?, if so, change tracks
    cp 129
    jp c, load1    ;carry generated if sector < 129
;
;   end of  current track,  go to next track
    ld  d, 1        ;begin with first sector of next track
    inc c       ;track=track+1
;
;   save    register state, and change tracks
    push    bc
    push    de
    push    hl
    call _settrk      ;track address set from register c
    pop hl
    pop de
    pop bc
    jp  load1       ;for another sector

epromload:
    ;re-load from EPROM shall be inserted here
;
;   end of  load operation, set parameters and go to cp/m
gocpm:
    ld  a, 0c3h     ;c3 is a jmp instruction
    ld  (0), a      ;for jmp to wboot
    ld  hl, WBOOT   ;wboot entry point
    ld  (1), hl     ;set address field for jmp at 0
;
    ld  (5), a      ;for jmp to bdos
    ld  hl, FBASE   ;bdos entry point (just after serial number)
    ld  (6), hl     ;address field of Jump at 5 to bdos
;
    ld  bc, 80h     ;default dma address is 80h
    call _setdma
;
    ei          ;enable the interrupt system
    ld  a, (cdisk)  ;get current disk number
    cp  ndisks       ;see if valid disk number
    jp  c, diskok   ;disk valid, go to ccp
    ld  a, 0        ;invalid disk, change to disk 0
diskok: ld  c, a        ;send to the ccp
    jp  ccp     ;go to cp/m for further processing
;
;
;   simple i/o handlers (must be filled in by user)
;   in each case, the entry point is provided, with space reserved
;   to insert your own code
;
_const:  ;console status, return 0ffh if character ready, 00h if not
    in  a, (SIO_A_CTRL) ;get status
    and     001h        ;check RxRDY bit
    jp  z, no_char
    ld  a, 0ffh     ;char ready
    ret
no_char:ld  a, 00h      ;no char
    ret
;
_conin:  ;console character into register a
    in  a, (SIO_A_CTRL) ;get status
    and     001h        ;check RxRDY bit
    jp  z, _conin       ;loop until char ready
    in  a, (SIO_A_DATA) ;get char
    and 7fh             ;strip parity bit
    cp 1ah              ;Ctrl-Z EPRPM reboot (my addition)
    jp z, epromrld      ;reload from EPROM
    ret
;
_conout: ;console character output from register c
    in  a, (SIO_A_CTRL)
    and 004h        ;check TxRDY bit
    jp  z, _conout   ;loop until port ready
    ld  a, c        ;get the char
    out (SIO_A_DATA), a ;out to port
    ret
;
_list:   ;list character from register c
    ld  a, c        ;character to register a
    ret         ;null subroutine
;
_listst: ;return list status (0 if not ready, 1 if ready)
    xor a       ;0 is always ok to return
    ret
;
_punch:  ;punch  character from  register C
    ld  a, c        ;character to register a
    ret         ;null subroutine
;
;
_reader: ;reader character into register a from reader device
    ld     a, 1ah       ;enter end of file for now (replace later)
    and    7fh      ;remember to strip parity bit
    ret
;
;
;   i/o drivers for the disk follow
;   for now, we will simply store the parameters away for use
;   in the read and write subroutines
;
_home:   ;move to the track 00   position of current drive
;   translate this call into a settrk call with Parameter 00
    ld     c, 0     ;select track 0
    call _settrk
    ret         ;we will move to 00 on first read/write
;
_seldsk: ;select disk given by register c
    ld  hl, 0000h   ;error return code
    ld  a, c
    ld  (diskno), a
    cp  ndisks       ;must be between 0 and number of disks value
    ret nc      ;no carry if > disks value
;   disk number is in the proper range
;   compute proper disk Parameter header address
    ld  a, (diskno)
    ld  l, a        ;l=disk number 0, 1, 2, 3
    ld  h, 0        ;high order zero
    add hl, hl      ;*2
    add hl, hl      ;*4
    add hl, hl      ;*8
    add hl, hl      ;*16 (size of each header)
    ld  de, dpbase
    add hl, de      ;hl=,dpbase (diskno*16) Note typo here in original source.
    ret
;
_settrk: ;set track given by register c
    ld  a, c
    ld  (track), a
    ret

; set sector given by register BC
; as we have only 128 sectors per track, B can be ignored
_setsec:
    ld  a, c
    ld  (sector), a
    ret

;set DMA address given by register BC
_setdma:
    ld  l, c        ;low order address
    ld  h, b        ;high order address
    ld  (dmaad), hl ;save the address
    ret

;
;	translate the sector given by BC using the
;	translate table given by DE
;
_sectran:
	LD	A,D		;do we have a translation table?
	OR	E
	JP	NZ,SECT1	;yes, translate
	LD	L,C		;no, return untranslated
	LD	H,B		;in HL
	INC	L		;sector no. start with 1
	RET	NZ
	INC	H
	RET
SECT1:	EX	DE,HL		;HL=.trans
	ADD	HL,BC		;HL=.trans(sector)
	LD	L,(HL)		;L = trans(sector)
	LD	H,0		;HL= trans(sector)
	RET			;with value in HL

_read:
;Read one CP/M sector from disk.
;try 2 times
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read.
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
;
    call _rdsdsec
    ld a, c             ;set return value
    cp a, 0
    ret z
    call _rdsdsec
    ld a, c             ;set return value
    ret
    ret

_write:
;Write one CP/M sector to disk.
;try 2 times
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read or write
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
    call _wrsdsec
    ld a, c             ;set return value
    cp a, 0
    ret z
    call _wrsdsec
    ld a, c             ;set return value
    ret

;*****************************************************
;*                                                   *
;*  Unitialized RAM data areas                       *
;*                                                   *
;*****************************************************
;   The remainder of the cbios is reserved uninitialized
;   data area, and does not need to be a Part of the
;   system memory image (the space must be available,
;   however, between "begdat" and "enddat").
;
begdat:                 ;beginning of data area
_track:
track:  .byte   [2]     ;track number, two bytes for expansion
_sector:
sector: .byte   [2]     ;sector number,two bytes for expansion
_dmaad:
dmaad:  .byte   [2]     ;direct memory address
_diskno:
diskno: .byte   [1]     ;disk number 0-15

.public dirbf
dirbf:  .byte      [128]    ;scratch directory area
; disk allocation vectors, 1 bit per block. we have
; 128 logical sectors per block, so total 512 blocks
; on drive, alv needs 64 bytes per drive, one for each drive
all00:  .byte      [dskblks/8]  ;A
all01:  .byte      [dskblks/8]  ;B
all02:  .byte      [dskblks/8]  ;C
all03:  .byte      [dskblks/8]  ;D

chk00:	.byte	   [16] 		;check vector 0
chk01:	.byte	   [16] 		;check vector 1
chk02:	.byte	   [16] 		;check vector 2
chk03:	.byte	   [16] 		;check vector 3

;
enddat:             ;end of data area
.define datsiz  = enddat-begdat ;size of data area

; Reload from EPROM
epromrld:
        ld a, 00000011b         ; sw reset CTC2 to stop NMIs
        out (CTC_CH2), a
        out (MEMEPROM), a       ; select EPROM in lower 32KB address range
        jp 0000h                ; and jump to start of EPROM

; Print version information when booting
verprt:
    ld hl, ver_msg
    call print_string
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
	ld c, a
	call _conout		; else - print character
	inc hl			; HL++
	jr print_string_1	; do it again
print_string_2:
	pop hl
	pop af
	ret

ver_msg:
	.text "CP/M 2.2 & Z80 BIOS v1.0 with unbelievably slow SPI/SD card interface\r\n"
	.text "(Ctrl-Z to reboot from EPROM)\r\n", 0

    .end
