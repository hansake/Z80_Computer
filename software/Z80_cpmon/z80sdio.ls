   1                    	; z80aio.s
   2                    	;
   3                    	; Assembler SPI routines for the Z80 computer.
   4                    	;
   5                    	; Hacked together by Hans-Ake Lund 2021 and 2022
   6                    	; to work with Z80 Computer and a NMI based
   7                    	; SPI interface using bit-banging on a PIO port
   8                    	;
   9                    	; The SPI interface has the option of not using NMI,
  10                    	; the reason for this is that the NMI routine address (66h)
  11                    	; is in the middle of the default FCB area for CP/M.
  12                    	; NMI driven SPI interface is more suitable for a multi tasking
  13                    	; operating system.
  14                    	;
  29                    	.include "z80comp.inc"
  16                    	
  17                    	.define NMISPI = 0 ;set to 1 for NMI driven SPI interface
  18                    	
  19                    		.external c.savs
  20                    		.external c.rets
  21                    	
  22                    		.public spinmi
  23                    		.public _spiinit
  24                    		.public _spiselect
  25                    		.public _spideselect
  26                    		.public _spiio
  27                    	
  28                    		.public _blk2byte
  29                    		.public _jumpto
  30                    		.public _reload
  31                    		.public _addblk
  32                    	
  33                    	;-------------------------------------------------------
  34                    	;	NMI with a jump from address 0x0066
  35                    	;       if NMI driven SPI interface is configured
  36                    	;
  37                    	; The NMI routine handles SPI byte input and output
  38                    	; The alternate registers are set-up by C functions
  39                    	; to send and receive one byte of data
  40                    	; reg B: clock pulse counter for sending/receving a byte
  41                    	; reg C: temporary save data to output
  42                    	; reg D: byte to transmit
  43                    	; reg E: received byte
  44                    	; Bit 6 in PIO port B set to 1 indicates that the NMI routine executes
  45                    	;       used for test/measurement
  46                    	; Bit 7 in PIO port B set to 1 indicates that byte transfer
  47                    	;       is ongoing and that the C functions
  48                    	;       can not read or write the alternate registers
  49                    	spinmi:
  50                    	
  51                    	.if NMISPI = 0
  52                    		;if not NMI driven, return directly
  53    0000  ED45      		retn
  54                    	.endif
  55                    	spipolled:
  56    0002  08        		ex af,af
  57    0003  D9        		exx
  58    0004  DB11      		in a, (PIO_B_DATA)	;read input and current outputs
  59                    	
  60                    		; test/measurement signal
  61    0006  F640      		or 40h			;set bit 6 to signal start of NMI
  62    0008  D311      		out (PIO_B_DATA), a
  63                    	
  64                    		; SCK toggles for each NMI
  65                    		; output SCK signal on PIO B bit 2
  66    000A  E6FB      		and 0fbh		;reset SCK (bit 2)
  67    000C  CB40      		bit 0,b			;reg B bit 0 controls SCK
  68    000E  200E      		jr nz, spiscklow		;SCK is set to 0
  69    0010  F604      		or 004h			;SCK set to 1
  70                    		; test MISO input signal from PIO B on SCK transition to 1
  71    0012  37        		scf
  72    0013  3F        		ccf			;reset carry flag
  73    0014  CB13      		rl e			;shift reg E left, carry shifted into bit 0
  74    0016  CB47      		bit 0, a		;test MISO input (bit 0)
  75    0018  2802      		jr z, spimisolow	;input was 0
  76    001A  CBC3      		set 0, e		;input was 1
  77                    	spimisolow:
  78    001C  1808      		jr spisckhi
  79                    	spiscklow:
  80                    		; set MOSI output signal to PIO B on SCK transition to 0
  81    001E  E6FD      		and 0fdh		;reset MOSI (bit)
  82    0020  CB12      		rl d			;shift byte to send left into carry
  83    0022  3002      		jr nc, spimosilow	;MOSI is set to 0
  84    0024  F602      		or 002h			;MOSI set to 1
  85                    	spimosilow:
  86                    	
  87                    	spisckhi:
  88                    		; all NMIs handled for this byte?
  89    0026  100A      		djnz spiend		;not yet
  90                    		; now all bits af the byte are sent
  91                    		; reset and stop CTC2 so that no NMIs are generated
  92    0028  4F        		ld c, a
  93    0029  3E03      		ld a, 00000011b		;bit 1: sw reset, bit 0: this is a ctrl cmd
  94    002B  D30E      		out (CTC_CH2), a
  95    002D  79        		ld a, c
  96    002E  F602      		or 002h			;MOSI set to 1
  97    0030  E67F      		and 07fh		;reset bit 7 to signal end of byte
  98                    	spiend:
  99                    	
 100                    		; test/measurement signal
 101    0032  E6BF      		and 0bfh		;reset bit 6 to signal end of NMI
 102                    	
 103    0034  D311      		out (PIO_B_DATA), a
 104                    	
 105    0036  D9        		exx
 106    0037  08        		ex af,af
 107                    	.if NMISPI
 110    0038  C9        		ret
 111                    	.endif
 112                    	
 113                    	;-------------------------------------------------------
 114                    	; SPI C functions to set alternate registers for SPI i/o,
 115                    	; PIO B and CTC 2 are used for byte transfer by the NMI routine.
 116                    	
 117                    	; void spiinit(), called once for initialization
 118                    	_spiinit:
 119                    		; reset CTC2 so that no NMIs are generated
 120    0039  3E03      		ld a, 00000011b		; bit 1: sw reset, bit 0: this is a ctrl cmd
 121    003B  D30E      		out (CTC_CH2), a
 122                    	
 123                    		; Set up PIO B, SPI interface
 124    003D  3ECF      		ld a, 11001111b		; mode 3
 125    003F  D313      		out (PIO_B_CTRL), a
 126    0041  3E01      		ld a, 00000001b		; i/o mask
 127                    		;bit 0: MISO - input     3                   3
 128                    		;bit 1: MOSI - output    4                   5
 129                    		;bit 2: SCK  - output    5                   7
 130                    		;bit 3: /CS0 - output    6                   9
 131                    		;bit 4: /CS1 - output  extra device select  11
 132                    		;bit 5: /CS2 - output  extra device select  10
 133                    		;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
 134                    		;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
 135                    		;                                                with an 8 bit transmit or receive transfer
 136    0043  D313      		out (PIO_B_CTRL), a
 137    0045  3E07      		ld a, 00000111b		; int disable
 138    0047  D313      		out (PIO_B_CTRL), a
 139                    		; bit 1: MOSI - output	;high
 140                    		; bit 2: SCK  - output	;low
 141                    		; bit 3: /CS0 - output	;high = not selected
 142                    		; bit 4: /CS1 - output	;high = not selected
 143                    		; bit 5: /CS2 - output	;high = not selected
 144                    		; bit 6: TP1  - output  ;low
 145                    		; bit 7: TRA  - output  ;low
 146    0049  3E3A      		ld a, 00111010b		;initialize output bits
 147    004B  D311      		out (PIO_B_DATA), a
 148                    		; initialize alternate registers to 0
 149    004D  D9        		exx
 150    004E  010000    		ld bc, 0
 151    0051  110000    		ld de, 0
 152    0054  D9        		exx
 153    0055  C9        		ret
 154                    	
 155                    	;/* Select the SPI SD card
 156                    	; */
 157                    	;void spiselect()
 158                    	_spiselect:
 159    0056  DB11      		in a, (PIO_B_DATA)
 160    0058  E6F7      		and 0f7h		;set /CS (bit 3) low i.e. active
 161    005A  D311      		out (PIO_B_DATA), a
 162    005C  C9        		ret
 163                    	
 164                    	;/* Deselect the SPI SD card
 165                    	; */
 166                    	;void spideselect()
 167                    	_spideselect:
 168    005D  DB11      		in a, (PIO_B_DATA)
 169    005F  F608      		or 008h			;set /CS (bit 3) hign i.e. not active
 170    0061  D311      		out (PIO_B_DATA), a
 171    0063  C9        		ret
 172                    	
 173                    	;/* send/receive a byte over SPI interface
 174                    	; */
 175                    	;unsigned int spiio(unsigned int)
 176                    	_spiio:
 177    0064  CD0000    		call	c.savs
 178                    	spiiowt1:
 179    0067  DB11      		in a, (PIO_B_DATA)	;wait until SPI i/o not ongoing
 180    0069  CB7F      		bit 7, a
 181                    	.if SPINMI
 184    006B  2805      		jr z, spiidle ;this will probably never happen
 185    006D  CD0200    		call spipolled
 186    0070  18F5      		jr spiiowt1
 187                    	spiidle:
 188                    	.endif
 189    0072  CBFF      		set 7, a
 190    0074  D311      		out (PIO_B_DATA), a	;indicate that i/o is ongoing
 191                    		; set up alternate registers for NMI handling
 192    0076  D9        		exx
 193    0077  DD5604    		ld d, (ix+4)		;byte to transmit
 194    007A  1E00      		ld e, 0			;where the received byte ends up
 195    007C  0611      		ld b, 17		;NMI counter, 2 * 8 pulses
 196                    					;+ 1 NMI before & the byte
 197    007E  D9        		exx
 198                    	.if SPINMI
 207                    	spiiowt2:
 208    007F  DB11      		in a, (PIO_B_DATA)	;wait until SPI byte i/o is ready
 209    0081  CB7F      		bit 7, a
 210                    	.if SPINMI
 213    0083  2805      		jr z, spiready
 214    0085  CD0200    		call spipolled
 215    0088  18F5      		jr spiiowt2
 216                    	spiready:
 217                    	.endif
 218                    		;get recieved byte
 219    008A  D9        		exx
 220    008B  7B        		ld a, e			;the recieved byte is in reg E
 221    008C  D9        		exx
 222    008D  4F        		ld c, a
 223    008E  0600      		ld b, 0
 224    0090  C30000    		jp c.rets
 225                    	
 226                    	;/* Make block address to byte address
 227                    	; * by multiplying with 512 (blocksize)
 228                    	; */
 229                    	;int blk2byte(unsigned char *)
 230                    	_blk2byte:
 231                    		;dsk parameter in HL
 232                    		; shift left 8 bits
 233    0093  23        		inc	hl
 234    0094  7E        		ld	a, (hl)
 235    0095  2B        		dec	hl
 236    0096  77        		ld	(hl), a
 237    0097  23        		inc	hl
 238    0098  23        		inc	hl
 239    0099  7E        		ld	a, (hl)
 240    009A  2B        		dec	hl
 241    009B  77        		ld	(hl), a
 242    009C  23        		inc	hl
 243    009D  23        		inc	hl
 244    009E  7E        		ld	a, (hl)
 245    009F  2B        		dec	hl
 246    00A0  77        		ld	(hl), a
 247    00A1  23        		inc	hl
 248    00A2  3600      		ld	(hl), 0
 249                    		; then shift left 1 bit
 250    00A4  2B        		dec	hl
 251    00A5  CB26      		sla	(hl)
 252    00A7  2B        		dec	hl
 253    00A8  CB16      		rl	(hl)
 254    00AA  2B        		dec	hl
 255    00AB  CB16      		rl	(hl)
 256    00AD  C9        		ret
 257                    	
 258                    	; Jump to address
 259                    	_jumpto:
 260    00AE  E9        		jp (hl)		;jump to address
 261                    	
 262                    	; Reload from EPROM
 263                    	_reload:
 264    00AF  D300      	        out (MEMEPROM),a ; select EPROM in lower 32KB address range
 265    00B1  C30000    	        jp 0000h         ;jump to start of EPROM
 266                    	
 267                    	;/* Add block addresses
 268                    	; */
 269                    	;void addblk(unsigned char *, unsigned char *);
 270                    	_addblk:
 271                    		;first dsk parameter in HL
 272    00B4  110300    		ld	de, 3	;put pointer to LSB in DE
 273    00B7  19        		add	hl, de
 274    00B8  5D        		ld	e, l
 275    00B9  54        		ld	d, h
 276                    		;second dsk parameter on stack
 277    00BA  210200    		ld	hl, 2
 278    00BD  39        		add	hl, sp
 279    00BE  4E        		ld	c, (hl)
 280    00BF  23        		inc	hl
 281    00C0  46        		ld	b, (hl)
 282    00C1  210300    		ld	hl, 3	;put pointer to LSB in HL
 283    00C4  09        		add	hl, bc
 284                    	
 285    00C5  0604      		ld	b, 4
 286    00C7  37        		scf
 287    00C8  3F        		ccf
 288                    	addit:
 289    00C9  1A        		ld	a, (de)
 290    00CA  8E        		adc	a, (hl)
 291    00CB  12        		ld	(de),  a
 292    00CC  1B        		dec	de
 293    00CD  2B        		dec	hl
 294    00CE  10F9      		djnz	addit
 295    00D0  C9        		ret
 296                    	
 297                    	;------------------------------------
 298                    	; A minimal debug probe with printout
 299                    	; of a character
 300                    	;------------------------------------
 301                    	; Minimal print probe,
 302                    	; insert in the code
 303                    	;    rst 38h
 304                    	;    .byte 'x' ;character to print
 305                    	;
 306                    	; implemented as the macro PRTPROB
 307                    	;
 308                    	;    .macro PRTPROB
 309                    	;    rst 7 ;rst 38h in Zilog manual
 310                    	;    .byte ?1
 311                    	;    .endm
 312                    	
 313                    	    .public mprobini
 314                    	
 315                    	; Initialize probe
 316                    	mprobini:
 317    00D1  3EC3      	    ld  a, 0c3h    ;c3 is a jmp instruction
 318    00D3  323800    	    ld (038h), a   ;for jmp to mprobe for rst 7
 319    00D6  21DD00    	    ld hl, mprobe
 320    00D9  223900    	    ld (039h), hl
 321    00DC  C9        	    ret
 322                    	
 323                    	; The routine to print the character
 324                    	mprobe:
 325    00DD  E3        	    ex (sp), hl
 326    00DE  F5        	    push af
 327                    	txwait:
 328    00DF  DB0A      	    in  a, (SIO_A_CTRL)
 329    00E1  E604      	    and 004h        ;check TxRDY bit
 330    00E3  CADF00    	    jp  z, txwait   ;loop until port ready
 331    00E6  7E        	    ld a, (hl)
 332    00E7  D308      	    out (SIO_A_DATA), a ;out to port
 333    00E9  F1        	    pop  af
 334    00EA  23        	    inc hl
 335    00EB  E3        	    ex (sp), hl
 336    00EC  C9        	    ret
 337                    	
 338                    	;------------------------------------
 339                    		.end
 340                    	
