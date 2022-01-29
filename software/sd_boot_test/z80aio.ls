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
  31                    		.public _jumpto
  32                    		.public _reload
  33                    	
  34                    	;-------------------------------------------------------
  35                    	;	NMI with a jump from address 0x0066
  36                    	;       if NMI driven SPI interface is configured
  37                    	;
  38                    	; The NMI routine handles SPI byte input and output
  39                    	; The alternate registers are set-up by C functions
  40                    	; to send and receive one byte of data
  41                    	; reg B: clock pulse counter for sending/receving a byte
  42                    	; reg C: temporary save data to output
  43                    	; reg D: byte to transmit
  44                    	; reg E: received byte
  45                    	; Bit 6 in PIO port B set to 1 indicates that the NMI routine executes
  46                    	;       used for test/measurement
  47                    	; Bit 7 in PIO port B set to 1 indicates that byte transfer
  48                    	;       is ongoing and that the C functions
  49                    	;       can not read or write the alternate registers
  50                    	spinmi:
  51                    	
  52                    	.if NMISPI = 0
  53                    		;if not NMI driven, return directly
  54    0000  ED45      		retn
  55                    	.endif
  56                    	spipolled:
  57    0002  08        		ex af,af
  58    0003  D9        		exx
  59    0004  DB11      		in a, (PIO_B_DATA)	;read input and current outputs
  60                    	
  61                    		; test/measurement signal
  62    0006  F640      		or 40h			;set bit 6 to signal start of NMI
  63    0008  D311      		out (PIO_B_DATA), a
  64                    	
  65                    		; SCK toggles for each NMI
  66                    		; output SCK signal on PIO B bit 2
  67    000A  E6FB      		and 0fbh		;reset SCK (bit 2)
  68    000C  CB40      		bit 0,b			;reg B bit 0 controls SCK
  69    000E  200E      		jr nz, spiscklow		;SCK is set to 0
  70    0010  F604      		or 004h			;SCK set to 1
  71                    		; test MISO input signal from PIO B on SCK transition to 1
  72    0012  37        		scf
  73    0013  3F        		ccf			;reset carry flag
  74    0014  CB13      		rl e			;shift reg E left, carry shifted into bit 0
  75    0016  CB47      		bit 0, a		;test MISO input (bit 0)
  76    0018  2802      		jr z, spimisolow	;input was 0
  77    001A  CBC3      		set 0, e		;input was 1
  78                    	spimisolow:
  79    001C  1808      		jr spisckhi
  80                    	spiscklow:
  81                    		; set MOSI output signal to PIO B on SCK transition to 0
  82    001E  E6FD      		and 0fdh		;reset MOSI (bit)
  83    0020  CB12      		rl d			;shift byte to send left into carry
  84    0022  3002      		jr nc, spimosilow	;MOSI is set to 0
  85    0024  F602      		or 002h			;MOSI set to 1
  86                    	spimosilow:
  87                    	
  88                    	spisckhi:
  89                    		; all NMIs handled for this byte?
  90    0026  100A      		djnz spiend		;not yet
  91                    		; now all bits af the byte are sent
  92                    		; reset and stop CTC2 so that no NMIs are generated
  93    0028  4F        		ld c, a
  94    0029  3E03      		ld a, 00000011b		;bit 1: sw reset, bit 0: this is a ctrl cmd
  95    002B  D30E      		out (CTC_CH2), a
  96    002D  79        		ld a, c
  97    002E  F602      		or 002h			;MOSI set to 1
  98    0030  E67F      		and 07fh		;reset bit 7 to signal end of byte
  99                    	spiend:
 100                    	
 101                    		; test/measurement signal
 102    0032  E6BF      		and 0bfh		;reset bit 6 to signal end of NMI
 103                    	
 104    0034  D311      		out (PIO_B_DATA), a
 105                    	
 106    0036  D9        		exx
 107    0037  08        		ex af,af
 108                    	.if NMISPI
 111    0038  C9        		ret
 112                    	.endif
 113                    	
 114                    	;-------------------------------------------------------
 115                    	; SPI C functions to control alternate registers,
 116                    	; PIO B and CTC 2 for byte transfer by the NMI routine
 117                    	
 118                    	; void spiinit(), called once for initialization
 119                    	_spiinit:
 120                    		; reset CTC2 so that no NMIs are generated
 121    0039  3E03      		ld a, 00000011b		; bit 1: sw reset, bit 0: this is a ctrl cmd
 122    003B  D30E      		out (CTC_CH2), a
 123                    	
 124                    		; Set up PIO B, SPI interface
 125    003D  3ECF      		ld a, 11001111b		; mode 3
 126    003F  D313      		out (PIO_B_CTRL), a
 127    0041  3E01      		ld a, 00000001b		; i/o mask
 128                    		;bit 0: MISO - input     3                   3
 129                    		;bit 1: MOSI - output    4                   5
 130                    		;bit 2: SCK  - output    5                   7
 131                    		;bit 3: /CS0 - output    6                   9
 132                    		;bit 4: /CS1 - output  extra device select  11
 133                    		;bit 5: /CS2 - output  extra device select  10
 134                    		;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
 135                    		;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
 136                    		;                                                with an 8 bit transmit or receive transfer
 137    0043  D313      		out (PIO_B_CTRL), a
 138    0045  3E07      		ld a, 00000111b		; int disable
 139    0047  D313      		out (PIO_B_CTRL), a
 140                    		; bit 1: MOSI - output	;high
 141                    		; bit 2: SCK  - output	;low
 142                    		; bit 3: /CS0 - output	;high = not selected
 143                    		; bit 4: /CS1 - output	;high = not selected
 144                    		; bit 5: /CS2 - output	;high = not selected
 145                    		; bit 6: TP1  - output  ;low
 146                    		; bit 7: TRA  - output  ;low
 147    0049  3E3A      		ld a, 00111010b		;initialize output bits
 148    004B  D311      		out (PIO_B_DATA), a
 149                    		; initialize alternate registers to 0
 150    004D  D9        		exx
 151    004E  010000    		ld bc, 0
 152    0051  110000    		ld de, 0
 153    0054  D9        		exx
 154    0055  C9        		ret
 155                    	
 156                    	;void spiselect()
 157                    	_spiselect:
 158    0056  DB11      		in a, (PIO_B_DATA)
 159    0058  E6F7      		and 0f7h		;set /CS (bit 3) low i.e. active
 160    005A  D311      		out (PIO_B_DATA), a
 161    005C  C9        		ret
 162                    	
 163                    	;void spideselect()
 164                    	_spideselect:
 165    005D  DB11      		in a, (PIO_B_DATA)
 166    005F  F608      		or 008h			;set /CS (bit 3) hign i.e. not active
 167    0061  D311      		out (PIO_B_DATA), a
 168    0063  C9        		ret
 169                    	
 170                    	;unsigned int spiio(unsigned int), send/receive a byte
 171                    	_spiio:
 172    0064  CD0000    		call	c.savs
 173                    	spiiowt1:
 174    0067  DB11      		in a, (PIO_B_DATA)	;wait until SPI i/o not ongoing
 175    0069  CB7F      		bit 7, a
 176                    	.if SPINMI
 179    006B  2805      		jr z, spiidle ;this will probably never happen
 180    006D  CD0200    		call spipolled
 181    0070  18F5      		jr spiiowt1
 182                    	spiidle:
 183                    	.endif
 184    0072  CBFF      		set 7, a
 185    0074  D311      		out (PIO_B_DATA), a	;indicate that i/o is ongoing
 186                    		; set up alternate registers for NMI handling
 187    0076  D9        		exx
 188    0077  DD5604    		ld d, (ix+4)		;byte to transmit
 189    007A  1E00      		ld e, 0			;where the received byte ends up
 190    007C  0611      		ld b, 17		;NMI counter, 2 * 8 pulses
 191                    					;+ 1 NMI before & the byte
 192    007E  D9        		exx
 193                    	.if SPINMI
 202                    	spiiowt2:
 203    007F  DB11      		in a, (PIO_B_DATA)	;wait until SPI byte i/o is ready
 204    0081  CB7F      		bit 7, a
 205                    	.if SPINMI
 208    0083  2805      		jr z, spiready
 209    0085  CD0200    		call spipolled
 210    0088  18F5      		jr spiiowt2
 211                    	spiready:
 212                    	.endif
 213                    		;get recieved byte
 214    008A  D9        		exx
 215    008B  7B        		ld a, e			;the recieved byte is in reg E
 216    008C  D9        		exx
 217    008D  4F        		ld c, a
 218    008E  0600      		ld b, 0
 219    0090  C30000    		jp c.rets
 220                    	
 221                    	
 222                    	; I/O C functions for the Z80 Computer
 223                    	;
 224                    	.if FASTIO
 225                    	
 226                    	_in:
 227    0093  4D        		ld	c, l	;i/o port
 228    0094  0600      		ld	b, 0
 229    0096  ED78      		in	a, (c)
 230    0098  4F        		ld	c, a	;byte that was input
 231    0099  0600      		ld	b, 0
 232    009B  C9        		ret
 233                    	
 234                    	_out:
 235    009C  4D        		ld	c, l    ;i/o port
 236    009D  0600      		ld	b, 0
 237    009F  210200    		ld	hl, 2
 238    00A2  39        		add	hl, sp
 239    00A3  7E        		ld	a, (hl)	;byte to output
 240    00A4  ED79      		out	(c), a
 241    00A6  C9        		ret
 242                    	
 243                    	.else
 262                    	
 263                    	_jumpto:
 264    00A7  E9        		jp (hl)		;jump to address
 265                    	
 266                    	_reload:
 267    00A8  C303F0    		jp 0F003H       ;fixed address in the monitor
 268                    	
 269                    		.end
 270                    	
