   1                    	; z80bios.s
   2                    	;
   3                    	; BIOS for my DIY Z80 computer.
   4                    	; Large parts of the code is copied from:
   5                    	; https://github.com/mastmees/z-one/blob/master/software/bios.asm
   6                    	; and also from: http://cpuville.com/Code/z80_cbios_asm.txt
   7                    	;
   8                    	; The code from z-one contains this license:
   9                    	;
  10                    	;  The MIT License (MIT)
  11                    	;
  12                    	;  Copyright (c) 2018 Madis Kaal <mast@nomad.ee>
  13                    	;
  14                    	;  Permission is hereby granted, free of charge, to any person obtaining a copy
  15                    	;  of this software and associated documentation files (the "Software"), to deal
  16                    	;  in the Software without restriction, including without limitation the rights
  17                    	;  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  18                    	;  copies of the Software, and to permit persons to whom the Software is
  19                    	;  furnished to do so, subject to the following conditions:
  20                    	;
  21                    	;  The above copyright notice and this permission notice shall be included in all
  22                    	;  copies or substantial portions of the Software.
  23                    	;
  24                    	;  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  25                    	;  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  26                    	;  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  27                    	;  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  28                    	;  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  29                    	;  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  30                    	;  SOFTWARE.
  31                    	;
  32                    	; Modified for Whitesmiths/COSMIC x80 assembler and tools for Z80.
  33                    	;
  34                    	; Disks are implemented with a SD card through a SPI interface.
  35                    	;
  36                    	; You are free to use, modify, and redistribute
  37                    	; this source code implementing the modifications.
  38                    	; No warranties of any kind are given.
  39                    	;
  40                    	; The adoptions were Hastily Cobbled Together 2022 by Hans-Ake Lund
  41                    	;
  29                    	.include "z80comp.inc"
  65                    	.include "cpm.inc"
  44                    	
  45                    	; The subroutines provided by this BIOS code:
  46                    	.public CBOOT, WBOOT, CONST, CONIN, CONOUT, LIST, PUNCH, READER
  47                    	.public HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, LISTST, SECTRN
  48                    	
  49                    	;To interface with the read/write routines
  50                    	.public _spt    ;word
  51                    	.public _diskno, _track, _sector, _dmaad
  52                    	
  53                    	; SD card read and write routines
  54                    	.external _rdsdsec
  55                    	.external _wrsdsec
  56                    	; initialize minimal debug output
  57                    	.external mprobini
  58                    	
  59                    	; The BIOS also needs to know the BDOS entry point
  60                    	.external FBASE
  61                    	
  62                    	.define dskblks =   243             ;disk size in logical blocks
  63                    	
  64                    	.define nsects = (bios - ccp)/128   ;warm start sector count
  65                    	;
  66                    	;	jump vectors for individual subroutines
  67                    	;
  68    0000  C39C00    	CBOOT:	jp	_boot	;cold start
  69    0003  C3AF00    	WBOOT:	jp	_wboot	;warm start
  70    0006  C32401    	CONST:	jp	_const	;console status
  71    0009  C33101    	CONIN:	jp	_conin	;console character in
  72    000C  C34201    	CONOUT:	jp	_conout	;console character out
  73    000F  C34D01    	LIST:	jp	_list	;list character out
  74    0012  C35101    	PUNCH:	jp	_punch	;punch character out
  75    0015  C35301    	READER:	jp	_reader	;reader character out
  76    0018  C35801    	HOME:	jp	_home	;move head to home position
  77    001B  C35E01    	SELDSK:	jp	_seldsk	;select disk
  78    001E  C37701    	SETTRK:	jp	_settrk	;set track number
  79    0021  C37C01    	SETSEC:	jp	_setsec	;set sector number
  80    0024  C38101    	SETDMA:	jp	_setdma	;set dma address
  81    0027  C39801    	READ:	jp	_read	;read disk
  82    002A  C3A501    	WRITE:	jp	_write	;write disk
  83    002D  C34F01    	LISTST:	jp	_listst	;return list status
  84    0030  C38701    	SECTRN: jp	_sectran ;sector translate
  85                    	;
  86                    	;   fixed data tables for 4 drives
  87                    	;
  88                    	dpbase:
  89                    	;
  90                    	;	fixed data tables for four standard
  91                    	;	IBM-compatible 8" SD disks (disktool-type: ibm-3740)
  92                    	;
  93                    	;	disk parameter header for disk 00
  94    0033  7300      	    .word trans     ;translation table
  95    0035  00000000  	    .word 0000h,0000h,0000h ;CP/M workspace
              0000
  96    003B  B801      	    .word dirbf     ;address of 128 byte sector buffer (shared)
  97    003D  8D00      	    .word dpblk     ;DPB address
  98    003F  B002      	    .word chk00     ;directory checksums
  99    0041  3802      	    .word all00     ;disk allocation vector
 100                    	;	disk parameter header for disk 01
 101    0043  7300      	    .word trans     ;translation table
 102    0045  00000000  	    .word 0000h,0000h,0000h ;CP/M workspace
              0000
 103    004B  B801      	    .word dirbf     ;address of 128 byte sector buffer (shared)
 104    004D  8D00      	    .word dpblk     ;DPB address
 105    004F  C002      	    .word chk01     ;directory checksums
 106    0051  5602      	    .word all01     ;disk allocation vector
 107                    	;   disk parameter header for disk 02
 108    0053  7300      	    .word trans     ;translation table
 109    0055  00000000  	    .word 0000h,0000h,0000h ;CP/M workspace
              0000
 110    005B  B801      	    .word dirbf     ;address of 128 byte sector buffer (shared)
 111    005D  8D00      	    .word dpblk     ;DPB address
 112    005F  D002      	    .word chk02     ;directory checksums
 113    0061  7402      	    .word all02     ;disk allocation vector
 114                    	;   disk parameter header for disk 03
 115    0063  7300      	    .word trans     ;translation table
 116    0065  00000000  	    .word 0000h,0000h,0000h ;CP/M workspace
              0000
 117    006B  B801      	    .word dirbf     ;address of 128 byte sector buffer (shared)
 118    006D  8D00      	    .word dpblk     ;DPB address
 119    006F  E002      	    .word chk03     ;directory checksums
 120    0071  9202      	    .word all03     ;disk allocation vector
 121                    	dpend:
 122                    	; Number of disks in the system, every parameter block is 16 bytes
 123                    	.define ndisks= (dpend-dpbase)/16
 124                    	
 125                    	;
 126                    	;	sector translate vector for the IBM 8" SD disks
 127                    	;
 128    0073  01070D13  	trans:	.byte	1,7,13,19	;sectors 1,2,3,4
 129    0077  19050B11  		.byte	25,5,11,17	;sectors 5,6,7,8
 130    007B  1703090F  		.byte	23,3,9,15	;sectors 9,10,11,12
 131    007F  1502080E  		.byte	21,2,8,14	;sectors 13,14,15,16
 132    0083  141A060C  		.byte	20,26,6,12	;sectors 17,18,19,20
 133    0087  1218040A  		.byte	18,24,4,10	;sectors 21,22,23,24
 134    008B  1016      		.byte	16,22		;sectors 25,26
 135                    	
 136                    	;disk parameter block, for floppy disks
 137                    	
 138                    	dpblk:
 139                    	_spt:
 140    008D  1A00      	    .word 26        ;SPT number of 128 byte sectors per track
 141    008F  03        	    .byte 3         ;BSH block shift factor (128<<bsf=block size)
 142    0090  07        	    .byte 7         ;BLM block mask (blm+1)*128=block size
 143    0091  00        	    .byte 0         ;EXM extent mask EXM+1 physical extents per
 144                    	                    ;dir entry
 145    0092  F200      	    .word dskblks-1 ;disk size-1, in blocks
 146    0094  3F00      	    .word 63        ;directory max, 1 block for directory=512
 147                    	                    ;directory entries
 148    0096  C0        	    .byte 192       ;alloc 0
 149    0097  00        	    .byte 0         ;alloc 1
 150    0098  1000      	    .word 16        ;check size, 0 for fixed disks
 151    009A  0200      	    .word 2         ;track offset for boot tracks
 152                    	;
 153                    	;   end of fixed tables
 154                    	;
 155                    	;   individual subroutines to perform each function
 156                    	;
 157                    	; cold boot loader, this is only invoked once, 
 158                    	; when the CP/M is initially loaded
 159                    	_boot:
 160                    	    ;simplest case is to just perform parameter initialization
 161    009C  318000    	    ld sp, 80h      ;use space below buffer for stack
 162    009F  CDF902    	    call verprt     ;print BIOS version
 163    00A2  CD0000    	    call mprobini   ;initialize debug print probe
 164    00A5  AF        	    xor a           ;zero in the accum
 165    00A6  320300    	    ld (iobyte), a  ;clear the iobyte
 166    00A9  320400    	    ld (cdisk), a   ;select disk zero
 167    00AC  C3FB00    	    jp gocpm        ;initialize and go to cp/m
 168                    	
 169                    	; warm boot loader, this is called to
 170                    	; reload ccp & bdos in case it was overwritten by application
 171                    	; simplest case is to read the disk until all sectors loaded
 172                    	_wboot:
 173    00AF  318000    	    ld sp, 80h      ;use space below buffer for stack
 174    00B2  0E00      	    ld c, 0         ;select disk 0
 175    00B4  CD5E01    	    call _seldsk
 176    00B7  CD5801    	    call _home      ;go to track 00
 177                    	
 178    00BA  C3FB00    	    jp epromload    ;for now CP/M is loaded from EPROM
 179                    	
 180    00BD  0600      	    ld b, nsects    ;B counts * of sectors to load
 181    00BF  0E00      	    ld c, 0         ;C has the current track number
 182    00C1  1602      	    ld d, 2         ;D has the next sector to read
 183                    	;   note that we begin by reading track 0, sector 2 since sector 1
 184                    	;   contains the cold start loader, which is skipped in a warm start
 185    00C3  210000    	    ld  hl, ccp     ;base of cp/m (initial load point)
 186                    	load1:
 187                    	;   load   one more sector
 188    00C6  C5        	    push bc         ;save sector count, current track
 189    00C7  D5        	    push de         ;save next sector to read
 190    00C8  E5        	    push hl         ;save dma address
 191    00C9  4A        	    ld c, d         ;get sector address to register C
 192    00CA  CD7C01    	    call _setsec    ;set sector address from register C
 193    00CD  C1        	    pop bc          ;recall dma address to BC
 194    00CE  C5        	    push bc         ;replace on stack for later recall
 195    00CF  CD8101    	    call _setdma    ;set dma address from BC
 196                    	;   drive set to 0, track set, sector set, dma address set
 197    00D2  CD9801    	    call _read
 198    00D5  FE00      	    cp 00h          ;any errors?
 199    00D7  C2AF00    	    jp nz, _wboot   ;retry the entire boot if an error occurs
 200                    	;   no error, move to next sector
 201    00DA  E1        	    pop hl          ;recall dma address
 202    00DB  118000    	    ld de, 128      ;dma = dma + 128
 203    00DE  19        	    add hl, de      ;new dma address is in HL
 204    00DF  D1        	    pop de          ;recall sector address
 205    00E0  C1        	    pop bc          ;recall number of sectors remaining, and current trk
 206    00E1  05        	    dec b           ;sectors = sectors - 1
 207    00E2  CAFB00    	    jp z, gocpm     ;transfer to cp/m if all have been loaded
 208                    	;   more    sectors remain to load, check for track change
 209    00E5  14        	    inc d
 210    00E6  7A        	    ld a, d         ;sector == 129?, if so, change tracks
 211    00E7  FE81      	    cp 129
 212    00E9  DAC600    	    jp c, load1    ;carry generated if sector < 129
 213                    	;
 214                    	;   end of  current track,  go to next track
 215    00EC  1601      	    ld  d, 1        ;begin with first sector of next track
 216    00EE  0C        	    inc c       ;track=track+1
 217                    	;
 218                    	;   save    register state, and change tracks
 219    00EF  C5        	    push    bc
 220    00F0  D5        	    push    de
 221    00F1  E5        	    push    hl
 222    00F2  CD7701    	    call _settrk      ;track address set from register c
 223    00F5  E1        	    pop hl
 224    00F6  D1        	    pop de
 225    00F7  C1        	    pop bc
 226    00F8  C3C600    	    jp  load1       ;for another sector
 227                    	
 228                    	epromload:
 229                    	    ;re-load from EPROM shall be inserted here
 230                    	;
 231                    	;   end of  load operation, set parameters and go to cp/m
 232                    	gocpm:
 233    00FB  3EC3      	    ld  a, 0c3h     ;c3 is a jmp instruction
 234    00FD  320000    	    ld  (0), a      ;for jmp to wboot
 235    0100  210300    	    ld  hl, WBOOT   ;wboot entry point
 236    0103  220100    	    ld  (1), hl     ;set address field for jmp at 0
 237                    	;
 238    0106  320500    	    ld  (5), a      ;for jmp to bdos
 239    0109  210000    	    ld  hl, FBASE   ;bdos entry point (just after serial number)
 240    010C  220600    	    ld  (6), hl     ;address field of Jump at 5 to bdos
 241                    	;
 242    010F  018000    	    ld  bc, 80h     ;default dma address is 80h
 243    0112  CD8101    	    call _setdma
 244                    	;
 245    0115  FB        	    ei          ;enable the interrupt system
 246    0116  3A0400    	    ld  a, (cdisk)  ;get current disk number
 247    0119  FE04      	    cp  ndisks       ;see if valid disk number
 248    011B  DA2001    	    jp  c, diskok   ;disk valid, go to ccp
 249    011E  3E00      	    ld  a, 0        ;invalid disk, change to disk 0
 250    0120  4F        	diskok: ld  c, a        ;send to the ccp
 251    0121  C30000    	    jp  ccp     ;go to cp/m for further processing
 252                    	;
 253                    	;
 254                    	;   simple i/o handlers (must be filled in by user)
 255                    	;   in each case, the entry point is provided, with space reserved
 256                    	;   to insert your own code
 257                    	;
 258                    	_const:  ;console status, return 0ffh if character ready, 00h if not
 259    0124  DB0A      	    in  a, (SIO_A_CTRL) ;get status
 260    0126  E601      	    and     001h        ;check RxRDY bit
 261    0128  CA2E01    	    jp  z, no_char
 262    012B  3EFF      	    ld  a, 0ffh     ;char ready
 263    012D  C9        	    ret
 264    012E  3E00      	no_char:ld  a, 00h      ;no char
 265    0130  C9        	    ret
 266                    	;
 267                    	_conin:  ;console character into register a
 268    0131  DB0A      	    in  a, (SIO_A_CTRL) ;get status
 269    0133  E601      	    and     001h        ;check RxRDY bit
 270    0135  CA3101    	    jp  z, _conin       ;loop until char ready
 271    0138  DB08      	    in  a, (SIO_A_DATA) ;get char
 272    013A  E67F      	    and 7fh             ;strip parity bit
 273    013C  FE1A      	    cp 1ah              ;Ctrl-Z EPRPM reboot (my addition)
 274    013E  CAF002    	    jp z, epromrld      ;reload from EPROM
 275    0141  C9        	    ret
 276                    	;
 277                    	_conout: ;console character output from register c
 278    0142  DB0A      	    in  a, (SIO_A_CTRL)
 279    0144  E604      	    and 004h        ;check TxRDY bit
 280    0146  CA4201    	    jp  z, _conout   ;loop until port ready
 281    0149  79        	    ld  a, c        ;get the char
 282    014A  D308      	    out (SIO_A_DATA), a ;out to port
 283    014C  C9        	    ret
 284                    	;
 285                    	_list:   ;list character from register c
 286    014D  79        	    ld  a, c        ;character to register a
 287    014E  C9        	    ret         ;null subroutine
 288                    	;
 289                    	_listst: ;return list status (0 if not ready, 1 if ready)
 290    014F  AF        	    xor a       ;0 is always ok to return
 291    0150  C9        	    ret
 292                    	;
 293                    	_punch:  ;punch  character from  register C
 294    0151  79        	    ld  a, c        ;character to register a
 295    0152  C9        	    ret         ;null subroutine
 296                    	;
 297                    	;
 298                    	_reader: ;reader character into register a from reader device
 299    0153  3E1A      	    ld     a, 1ah       ;enter end of file for now (replace later)
 300    0155  E67F      	    and    7fh      ;remember to strip parity bit
 301    0157  C9        	    ret
 302                    	;
 303                    	;
 304                    	;   i/o drivers for the disk follow
 305                    	;   for now, we will simply store the parameters away for use
 306                    	;   in the read and write subroutines
 307                    	;
 308                    	_home:   ;move to the track 00   position of current drive
 309                    	;   translate this call into a settrk call with Parameter 00
 310    0158  0E00      	    ld     c, 0     ;select track 0
 311    015A  CD7701    	    call _settrk
 312    015D  C9        	    ret         ;we will move to 00 on first read/write
 313                    	;
 314                    	_seldsk: ;select disk given by register c
 315    015E  210000    	    ld  hl, 0000h   ;error return code
 316    0161  79        	    ld  a, c
 317    0162  32B701    	    ld  (diskno), a
 318    0165  FE04      	    cp  ndisks       ;must be between 0 and number of disks value
 319    0167  D0        	    ret nc      ;no carry if > disks value
 320                    	;   disk number is in the proper range
 321                    	;   compute proper disk Parameter header address
 322    0168  3AB701    	    ld  a, (diskno)
 323    016B  6F        	    ld  l, a        ;l=disk number 0, 1, 2, 3
 324    016C  2600      	    ld  h, 0        ;high order zero
 325    016E  29        	    add hl, hl      ;*2
 326    016F  29        	    add hl, hl      ;*4
 327    0170  29        	    add hl, hl      ;*8
 328    0171  29        	    add hl, hl      ;*16 (size of each header)
 329    0172  113300    	    ld  de, dpbase
 330    0175  19        	    add hl, de      ;hl=,dpbase (diskno*16) Note typo here in original source.
 331    0176  C9        	    ret
 332                    	;
 333                    	_settrk: ;set track given by register c
 334    0177  79        	    ld  a, c
 335    0178  32B101    	    ld  (track), a
 336    017B  C9        	    ret
 337                    	
 338                    	; set sector given by register BC
 339                    	; as we have only 128 sectors per track, B can be ignored
 340                    	_setsec:
 341    017C  79        	    ld  a, c
 342    017D  32B301    	    ld  (sector), a
 343    0180  C9        	    ret
 344                    	
 345                    	;set DMA address given by register BC
 346                    	_setdma:
 347    0181  69        	    ld  l, c        ;low order address
 348    0182  60        	    ld  h, b        ;high order address
 349    0183  22B501    	    ld  (dmaad), hl ;save the address
 350    0186  C9        	    ret
 351                    	
 352                    	;
 353                    	;	translate the sector given by BC using the
 354                    	;	translate table given by DE
 355                    	;
 356                    	_sectran:
 357    0187  7A        		LD	A,D		;do we have a translation table?
 358    0188  B3        		OR	E
 359    0189  C29201    		JP	NZ,SECT1	;yes, translate
 360    018C  69        		LD	L,C		;no, return untranslated
 361    018D  60        		LD	H,B		;in HL
 362    018E  2C        		INC	L		;sector no. start with 1
 363    018F  C0        		RET	NZ
 364    0190  24        		INC	H
 365    0191  C9        		RET
 366    0192  EB        	SECT1:	EX	DE,HL		;HL=.trans
 367    0193  09        		ADD	HL,BC		;HL=.trans(sector)
 368    0194  6E        		LD	L,(HL)		;L = trans(sector)
 369    0195  2600      		LD	H,0		;HL= trans(sector)
 370    0197  C9        		RET			;with value in HL
 371                    	
 372                    	_read:
 373                    	;Read one CP/M sector from disk.
 374                    	;try 2 times
 375                    	;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read.
 376                    	;Disk number in 'diskno'
 377                    	;Track number in 'track'
 378                    	;Sector number in 'sector'
 379                    	;Dma address in 'dmaad' (0-65535)
 380                    	;
 381    0198  CD0000    	    call _rdsdsec
 382    019B  79        	    ld a, c             ;set return value
 383    019C  FE00      	    cp a, 0
 384    019E  C8        	    ret z
 385    019F  CD0000    	    call _rdsdsec
 386    01A2  79        	    ld a, c             ;set return value
 387    01A3  C9        	    ret
 388    01A4  C9        	    ret
 389                    	
 390                    	_write:
 391                    	;Write one CP/M sector to disk.
 392                    	;try 2 times
 393                    	;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read or write
 394                    	;Disk number in 'diskno'
 395                    	;Track number in 'track'
 396                    	;Sector number in 'sector'
 397                    	;Dma address in 'dmaad' (0-65535)
 398    01A5  CD0000    	    call _wrsdsec
 399    01A8  79        	    ld a, c             ;set return value
 400    01A9  FE00      	    cp a, 0
 401    01AB  C8        	    ret z
 402    01AC  CD0000    	    call _wrsdsec
 403    01AF  79        	    ld a, c             ;set return value
 404    01B0  C9        	    ret
 405                    	
 406                    	;*****************************************************
 407                    	;*                                                   *
 408                    	;*  Unitialized RAM data areas                       *
 409                    	;*                                                   *
 410                    	;*****************************************************
 411                    	;   The remainder of the cbios is reserved uninitialized
 412                    	;   data area, and does not need to be a Part of the
 413                    	;   system memory image (the space must be available,
 414                    	;   however, between "begdat" and "enddat").
 415                    	;
 416                    	begdat:                 ;beginning of data area
 417                    	_track:
 418                    	track:  .byte   [2]     ;track number, two bytes for expansion
 419                    	_sector:
 420                    	sector: .byte   [2]     ;sector number,two bytes for expansion
 421                    	_dmaad:
 422                    	dmaad:  .byte   [2]     ;direct memory address
 423                    	_diskno:
 424                    	diskno: .byte   [1]     ;disk number 0-15
 425                    	
 426                    	.public dirbf
 427                    	dirbf:  .byte      [128]    ;scratch directory area
 428                    	; disk allocation vectors, 1 bit per block. we have
 429                    	; 128 logical sectors per block, so total 512 blocks
 430                    	; on drive, alv needs 64 bytes per drive, one for each drive
 431                    	all00:  .byte      [dskblks/8]  ;A
 432                    	all01:  .byte      [dskblks/8]  ;B
 433                    	all02:  .byte      [dskblks/8]  ;C
 434                    	all03:  .byte      [dskblks/8]  ;D
 435                    	
 436                    	chk00:	.byte	   [16] 		;check vector 0
 437                    	chk01:	.byte	   [16] 		;check vector 1
 438                    	chk02:	.byte	   [16] 		;check vector 2
 439                    	chk03:	.byte	   [16] 		;check vector 3
 440                    	
 441                    	;
 442                    	enddat:             ;end of data area
 443                    	.define datsiz  = enddat-begdat ;size of data area
 444                    	
 445                    	; Reload from EPROM
 446                    	epromrld:
 447    02F0  3E03      	        ld a, 00000011b         ; sw reset CTC2 to stop NMIs
 448    02F2  D30E      	        out (CTC_CH2), a
 449    02F4  D300      	        out (MEMEPROM), a       ; select EPROM in lower 32KB address range
 450    02F6  C30000    	        jp 0000h                ; and jump to start of EPROM
 451                    	
 452                    	; Print version information when booting
 453                    	verprt:
 454    02F9  211103    	    ld hl, ver_msg
 455    02FC  CD0003    	    call print_string
 456    02FF  C9        	    ret
 457                    	
 458                    	; print_string: prints a string which starts at adress HL
 459                    	; and is terminated by EOS-character
 460                    	; affects: none
 461                    	print_string:
 462    0300  F5        		push af
 463    0301  E5        		push hl
 464                    	print_string_1:
 465    0302  7E        		ld a,(hl)		; load next character
 466    0303  FE00      		cp 0			; is it en End Of String - character?
 467    0305  2807      		jr z, print_string_2	; yes - return
 468    0307  4F        		ld c, a
 469    0308  CD4201    		call _conout		; else - print character
 470    030B  23        		inc hl			; HL++
 471    030C  18F4      		jr print_string_1	; do it again
 472                    	print_string_2:
 473    030E  E1        		pop hl
 474    030F  F1        		pop af
 475    0310  C9        		ret
 476                    	
 477                    	ver_msg:
 478    0311  43502F4D  		.text "CP/M 2.2 & Z80 BIOS v1.0 with unbelievably slow SPI/SD card interface\r\n"
              20322E32
              2026205A
              38302042
              494F5320
              76312E30
              20776974
              6820756E
              62656C69
              65766162
              6C792073
              6C6F7720
              5350492F
              53442063
              61726420
              696E7465
              72666163
              650D0A
 479    0358  28437472  		.text "(Ctrl-Z to reboot from EPROM)\r\n", 0
              6C2D5A20
              746F2072
              65626F6F
              74206672
              6F6D2045
              50524F4D
              290D0A00
 480                    	
 481                    	    .end
