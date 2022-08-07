   1                    	; z80aio.s
   2                    	;
   3                    	; Assembler input/output routines for the Z80 computer.
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
  17                    	.define FASTIO = 1 ;set to 1 for faster serial i/o
  18                    	.define NMISPI = 0 ;set to 1 for NMI driven SPI interface
  19                    	
  20                    		.external c.rets
  21                    		.external c.savs
  22                    	
  23                    		.public spinmi
  24                    		.public _spiinit
  25                    		.public _spiselect
  26                    		.public _spideselect
  27                    		.public _spiio
  28                    	
  29                    		.public	_out
  30                    		.public	_in
  31                    		.public _jumpto
  32                    		.public _jumptoram
  33                    		.public _reload
  34                    	
  35                    	;-------------------------------------------------------
  36                    	;	NMI with a jump from address 0x0066
  37                    	;       if NMI driven SPI interface is configured
  38                    	;
  39                    	; The NMI routine handles SPI byte input and output
  40                    	; The alternate registers are set-up by C functions
  41                    	; to send and receive one byte of data
  42                    	; reg B: clock pulse counter for sending/receving a byte
  43                    	; reg C: temporary save data to output
  44                    	; reg D: byte to transmit
  45                    	; reg E: received byte
  46                    	; Bit 6 in PIO port B set to 1 indicates that the NMI routine executes
  47                    	;       used for test/measurement
  48                    	; Bit 7 in PIO port B set to 1 indicates that byte transfer
  49                    	;       is ongoing and that the C functions
  50                    	;       can not read or write the alternate registers
  51                    	spinmi:
  52                    	
  53                    	.if NMISPI = 0
  54                    		;if not NMI driven, return directly
  55    0000  ED45      		retn
  56                    	.endif
  57                    	spipolled:
  58    0002  08        		ex af,af
  59    0003  D9        		exx
  60    0004  DB11      		in a, (PIO_B_DATA)	;read input and current outputs
  61                    	
  62                    		; test/measurement signal
  63    0006  F640      		or 40h			;set bit 6 to signal start of NMI
  64    0008  D311      		out (PIO_B_DATA), a
  65                    	
  66                    		; SCK toggles for each NMI
  67                    		; output SCK signal on PIO B bit 2
  68    000A  E6FB      		and 0fbh		;reset SCK (bit 2)
  69    000C  CB40      		bit 0,b			;reg B bit 0 controls SCK
  70    000E  200E      		jr nz, spiscklow		;SCK is set to 0
  71    0010  F604      		or 004h			;SCK set to 1
  72                    		; test MISO input signal from PIO B on SCK transition to 1
  73    0012  37        		scf
  74    0013  3F        		ccf			;reset carry flag
  75    0014  CB13      		rl e			;shift reg E left, carry shifted into bit 0
  76    0016  CB47      		bit 0, a		;test MISO input (bit 0)
  77    0018  2802      		jr z, spimisolow	;input was 0
  78    001A  CBC3      		set 0, e		;input was 1
  79                    	spimisolow:
  80    001C  1808      		jr spisckhi
  81                    	spiscklow:
  82                    		; set MOSI output signal to PIO B on SCK transition to 0
  83    001E  E6FD      		and 0fdh		;reset MOSI (bit)
  84    0020  CB12      		rl d			;shift byte to send left into carry
  85    0022  3002      		jr nc, spimosilow	;MOSI is set to 0
  86    0024  F602      		or 002h			;MOSI set to 1
  87                    	spimosilow:
  88                    	
  89                    	spisckhi:
  90                    		; all NMIs handled for this byte?
  91    0026  100A      		djnz spiend		;not yet
  92                    		; now all bits af the byte are sent
  93                    		; reset and stop CTC2 so that no NMIs are generated
  94    0028  4F        		ld c, a
  95    0029  3E03      		ld a, 00000011b		;bit 1: sw reset, bit 0: this is a ctrl cmd
  96    002B  D30E      		out (CTC_CH2), a
  97    002D  79        		ld a, c
  98    002E  F602      		or 002h			;MOSI set to 1
  99    0030  E67F      		and 07fh		;reset bit 7 to signal end of byte
 100                    	spiend:
 101                    	
 102                    		; test/measurement signal
 103    0032  E6BF      		and 0bfh		;reset bit 6 to signal end of NMI
 104                    	
 105    0034  D311      		out (PIO_B_DATA), a
 106                    	
 107    0036  D9        		exx
 108    0037  08        		ex af,af
 109                    	.if NMISPI
 112    0038  C9        		ret
 113                    	.endif
 114                    	
 115                    	;-------------------------------------------------------
 116                    	; SPI C functions to control alternate registers,
 117                    	; PIO B and CTC 2 for byte transfer by the NMI routine
 118                    	
 119                    	; void spiinit(), called once for initialization
 120                    	_spiinit:
 121                    		; reset CTC2 so that no NMIs are generated
 122    0039  3E03      		ld a, 00000011b		; bit 1: sw reset, bit 0: this is a ctrl cmd
 123    003B  D30E      		out (CTC_CH2), a
 124                    	
 125                    		; Set up PIO B, SPI interface
 126    003D  3ECF      		ld a, 11001111b		; mode 3
 127    003F  D313      		out (PIO_B_CTRL), a
 128    0041  3E01      		ld a, 00000001b		; i/o mask
 129                    		;bit 0: MISO - input     3                   3
 130                    		;bit 1: MOSI - output    4                   5
 131                    		;bit 2: SCK  - output    5                   7
 132                    		;bit 3: /CS0 - output    6                   9
 133                    		;bit 4: /CS1 - output  extra device select  11
 134                    		;bit 5: /CS2 - output  extra device select  10
 135                    		;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
 136                    		;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
 137                    		;                                                with an 8 bit transmit or receive transfer
 138    0043  D313      		out (PIO_B_CTRL), a
 139    0045  3E07      		ld a, 00000111b		; int disable
 140    0047  D313      		out (PIO_B_CTRL), a
 141                    		; bit 1: MOSI - output	;high
 142                    		; bit 2: SCK  - output	;low
 143                    		; bit 3: /CS0 - output	;high = not selected
 144                    		; bit 4: /CS1 - output	;high = not selected
 145                    		; bit 5: /CS2 - output	;high = not selected
 146                    		; bit 6: TP1  - output  ;low
 147                    		; bit 7: TRA  - output  ;low
 148    0049  3E3A      		ld a, 00111010b		;initialize output bits
 149    004B  D311      		out (PIO_B_DATA), a
 150                    		; initialize alternate registers to 0
 151    004D  D9        		exx
 152    004E  010000    		ld bc, 0
 153    0051  110000    		ld de, 0
 154    0054  D9        		exx
 155    0055  C9        		ret
 156                    	
 157                    	;void spiselect()
 158                    	_spiselect:
 159    0056  DB11      		in a, (PIO_B_DATA)
 160    0058  E6F7      		and 0f7h		;set /CS (bit 3) low i.e. active
 161    005A  D311      		out (PIO_B_DATA), a
 162    005C  C9        		ret
 163                    	
 164                    	;void spideselect()
 165                    	_spideselect:
 166    005D  DB11      		in a, (PIO_B_DATA)
 167    005F  F608      		or 008h			;set /CS (bit 3) hign i.e. not active
 168    0061  D311      		out (PIO_B_DATA), a
 169    0063  C9        		ret
 170                    	
 171                    	;unsigned int spiio(unsigned int), send/receive a byte
 172                    	_spiio:
 173    0064  CD0000    		call	c.savs
 174                    	spiiowt1:
 175    0067  DB11      		in a, (PIO_B_DATA)	;wait until SPI i/o not ongoing
 176    0069  CB7F      		bit 7, a
 177                    	.if SPINMI
 180    006B  2805      		jr z, spiidle ;this will probably never happen
 181    006D  CD0200    		call spipolled
 182    0070  18F5      		jr spiiowt1
 183                    	spiidle:
 184                    	.endif
 185    0072  CBFF      		set 7, a
 186    0074  D311      		out (PIO_B_DATA), a	;indicate that i/o is ongoing
 187                    		; set up alternate registers for NMI handling
 188    0076  D9        		exx
 189    0077  DD5604    		ld d, (ix+4)		;byte to transmit
 190    007A  1E00      		ld e, 0			;where the received byte ends up
 191    007C  0611      		ld b, 17		;NMI counter, 2 * 8 pulses
 192                    					;+ 1 NMI before & the byte
 193    007E  D9        		exx
 194                    	.if SPINMI
 203                    	spiiowt2:
 204    007F  DB11      		in a, (PIO_B_DATA)	;wait until SPI byte i/o is ready
 205    0081  CB7F      		bit 7, a
 206                    	.if SPINMI
 209    0083  2805      		jr z, spiready
 210    0085  CD0200    		call spipolled
 211    0088  18F5      		jr spiiowt2
 212                    	spiready:
 213                    	.endif
 214                    		;get recieved byte
 215    008A  D9        		exx
 216    008B  7B        		ld a, e			;the recieved byte is in reg E
 217    008C  D9        		exx
 218    008D  4F        		ld c, a
 219    008E  0600      		ld b, 0
 220    0090  C30000    		jp c.rets
 221                    	
 222                    	
 223                    	; I/O C functions for the Z80 Computer
 224                    	;
 225                    	.if FASTIO
 226                    	
 227                    	_in:
 228    0093  4D        		ld	c, l	;i/o port
 229    0094  0600      		ld	b, 0
 230    0096  ED78      		in	a, (c)
 231    0098  4F        		ld	c, a	;byte that was input
 232    0099  0600      		ld	b, 0
 233    009B  C9        		ret
 234                    	
 235                    	_out:
 236    009C  4D        		ld	c, l    ;i/o port
 237    009D  0600      		ld	b, 0
 238    009F  210200    		ld	hl, 2
 239    00A2  39        		add	hl, sp
 240    00A3  7E        		ld	a, (hl)	;byte to output
 241    00A4  ED79      		out	(c), a
 242    00A6  C9        		ret
 243                    	
 244                    	.else
 263                    	
 264                    	_jumptoram: ; copy the jump code to upper RAM before switching
 265                    		    ; to lower RAM
 266    00A7  E5        		push hl
 267    00A8  110080    		ld de, 8000h
 268    00AB  21B700    		ld hl, jumpram
 269    00AE  010300    		ld bc, jumpramend - jumpram
 270    00B1  EDB0      		ldir
 271    00B3  E1        		pop hl
 272    00B4  C30080    		jp 8000h
 273                    	jumpram:
 274    00B7  D304      		out (MEMLORAM),a ; select RAM in lower 32KB address range
 275                    	_jumpto:
 276    00B9  E9        		jp (hl)		;jump to address
 277                    	jumpramend:
 278                    	
 279                    	_reload:    ; copy the jump code to upper RAM before switching
 280                    		    ; to lower RAM
 281    00BA  E5        		push hl
 282    00BB  110080    		ld de, 8000h
 283    00BE  21CA00    		ld hl, ereload
 284    00C1  010500    		ld bc, ereloadend - ereload
 285    00C4  EDB0      		ldir
 286    00C6  E1        		pop hl
 287    00C7  C30080    		jp 8000h
 288                    	ereload:
 289    00CA  D300      		out (MEMEPROM),a ; select EPROM in lower 32KB address range
 290    00CC  C30000    		jp 0000h	 ;jump to start of EPROM
 291                    	ereloadend:
 292                    	
 293                    		.end
 294                    	
