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
  29                    	.include "z80computer.inc"
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
  31                    		.public _reload
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
 114                    	; SPI C functions to control alternate registers,
 115                    	; PIO B and CTC 2 for byte transfer by the NMI routine
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
 155                    	;void spiselect()
 156                    	_spiselect:
 157    0056  DB11      		in a, (PIO_B_DATA)
 158    0058  E6F7      		and 0f7h		;set /CS (bit 3) low i.e. active
 159    005A  D311      		out (PIO_B_DATA), a
 160    005C  C9        		ret
 161                    	
 162                    	;void spideselect()
 163                    	_spideselect:
 164    005D  DB11      		in a, (PIO_B_DATA)
 165    005F  F608      		or 008h			;set /CS (bit 3) hign i.e. not active
 166    0061  D311      		out (PIO_B_DATA), a
 167    0063  C9        		ret
 168                    	
 169                    	;unsigned int spiio(unsigned int), send/receive a byte
 170                    	_spiio:
 171    0064  CD0000    		call	c.savs
 172                    	spiiowt1:
 173    0067  DB11      		in a, (PIO_B_DATA)	;wait until SPI i/o not ongoing
 174    0069  CB7F      		bit 7, a
 175                    	.if SPINMI
 178    006B  2805      		jr z, spiidle ;this will probably never happen
 179    006D  CD0200    		call spipolled
 180    0070  18F5      		jr spiiowt1
 181                    	spiidle:
 182                    	.endif
 183    0072  CBFF      		set 7, a
 184    0074  D311      		out (PIO_B_DATA), a	;indicate that i/o is ongoing
 185                    		; set up alternate registers for NMI handling
 186    0076  D9        		exx
 187    0077  DD5604    		ld d, (ix+4)		;byte to transmit
 188    007A  1E00      		ld e, 0			;where the received byte ends up
 189    007C  0611      		ld b, 17		;NMI counter, 2 * 8 pulses
 190                    					;+ 1 NMI before & the byte
 191    007E  D9        		exx
 192                    	.if SPINMI
 201                    	spiiowt2:
 202    007F  DB11      		in a, (PIO_B_DATA)	;wait until SPI byte i/o is ready
 203    0081  CB7F      		bit 7, a
 204                    	.if SPINMI
 207    0083  2805      		jr z, spiready
 208    0085  CD0200    		call spipolled
 209    0088  18F5      		jr spiiowt2
 210                    	spiready:
 211                    	.endif
 212                    		;get recieved byte
 213    008A  D9        		exx
 214    008B  7B        		ld a, e			;the recieved byte is in reg E
 215    008C  D9        		exx
 216    008D  4F        		ld c, a
 217    008E  0600      		ld b, 0
 218    0090  C30000    		jp c.rets
 219                    	
 220                    	
 221                    	; I/O C functions for the Z80 Computer
 222                    	;
 223                    	.if FASTIO
 224                    	
 225                    	_in:
 226    0093  4D        		ld	c, l	;i/o port
 227    0094  0600      		ld	b, 0
 228    0096  ED78      		in	a, (c)
 229    0098  4F        		ld	c, a	;byte that was input
 230    0099  0600      		ld	b, 0
 231    009B  C9        		ret
 232                    	
 233                    	_out:
 234    009C  4D        		ld	c, l    ;i/o port
 235    009D  0600      		ld	b, 0
 236    009F  210200    		ld	hl, 2
 237    00A2  39        		add	hl, sp
 238    00A3  7E        		ld	a, (hl)	;byte to output
 239    00A4  ED79      		out	(c), a
 240    00A6  C9        		ret
 241                    	
 242                    	.else
 261                    	
 262                    	_reload:
 263    00A7  C303F0    		jp 0F003H       ;fixed address in the monitor
 264                    	
 265                    		.end
 266                    	
