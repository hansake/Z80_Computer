   1                    	;
   2                    	;   Hacked together by Hans-Ake Lund 2021 and 2022
   3                    	;   to work with Z80 Computer and a NMI based
   4                    	;   SPI interface using bit-banging on a PIO port
   5                    	;
  29                    	.include "z80computer.inc"
   7                    	
   8                    		.external c.rets
   9                    		.external c.savs
  10                    	
  11                    		.public spinmi
  12                    		.public _spiinit
  13                    		.public _spiselect
  14                    		.public _spideselect
  15                    		.public _spiio
  16                    	
  17                    		.public	_out
  18                    		.public	_in
  19                    		.public _reload
  20                    	
  21                    	;-------------------------------------------------------
  22                    	;	NMI with a jump from address 0x0066
  23                    	;
  24                    	; The NMI routine handles SPI byte input and output
  25                    	; The alternate registers are set-up by C functions
  26                    	; to send and receive one byte of data
  27                    	; reg B: clock pulse counter for sending/receving a byte
  28                    	; reg C: temporary save data to output
  29                    	; reg D: byte to transmit
  30                    	; reg E: received byte
  31                    	; Bit 6 in PIO port B set to 1 indicates that the NMI routine executes
  32                    	;       used for test/measurement
  33                    	; Bit 7 in PIO port B set to 1 indicates that byte transfer
  34                    	;       is ongoing and that the C functions
  35                    	;       can not read or write the alternate registers
  36                    	spinmi:
  37    0000  08        		ex af,af
  38    0001  D9        		exx
  39    0002  DB11      		in a, (PIO_B_DATA)	;read input and current outputs
  40                    	
  41                    		; test/measurement signal
  42    0004  F640      		or 40h			;set bit 6 to signal start of NMI
  43    0006  D311      		out (PIO_B_DATA), a
  44                    	
  45                    		; SCK toggles for each NMI
  46                    		; output SCK signal on PIO B bit 2
  47    0008  E6FB      		and 0fbh		;reset SCK (bit 2)
  48    000A  CB40      		bit 0,b			;reg B bit 0 controls SCK
  49    000C  200E      		jr nz, spiscklow		;SCK is set to 0
  50    000E  F604      		or 004h			;SCK set to 1
  51                    		; test MISO input signal from PIO B on SCK transition to 1
  52    0010  37        		scf
  53    0011  3F        		ccf			;reset carry flag
  54    0012  CB13      		rl e			;shift reg E left, carry shifted into bit 0
  55    0014  CB47      		bit 0, a		;test MISO input (bit 0)
  56    0016  2802      		jr z, spimisolow	;input was 0
  57    0018  CBC3      		set 0, e		;input was 1
  58                    	spimisolow:
  59    001A  1808      		jr spisckhi
  60                    	spiscklow:
  61                    		; set MOSI output signal to PIO B on SCK transition to 0
  62    001C  E6FD      		and 0fdh		;reset MOSI (bit)
  63    001E  CB12      		rl d			;shift byte to send left into carry
  64    0020  3002      		jr nc, spimosilow	;MOSI is set to 0
  65    0022  F602      		or 002h			;MOSI set to 1
  66                    	spimosilow:
  67                    	
  68                    	spisckhi:
  69                    		; all NMIs handled for this byte?
  70    0024  100A      		djnz spiend		;not yet
  71                    		; now all bits af the byte are sent
  72                    		; reset and stop CTC2 so that no NMIs are generated
  73    0026  4F        		ld c, a
  74    0027  3E03      		ld a, 00000011b		;bit 1: sw reset, bit 0: this is a ctrl cmd
  75    0029  D30E      		out (CTC_CH2), a
  76    002B  79        		ld a, c
  77    002C  F602      		or 002h			;MOSI set to 1
  78    002E  E67F      		and 07fh		;reset bit 7 to signal end of byte
  79                    	spiend:
  80                    	
  81                    		; test/measurement signal
  82    0030  E6BF      		and 0bfh		;reset bit 6 to signal end of NMI
  83                    	
  84    0032  D311      		out (PIO_B_DATA), a
  85                    	
  86    0034  D9        		exx
  87    0035  08        		ex af,af
  88    0036  ED45      		retn
  89                    	;-------------------------------------------------------
  90                    	; SPI C functions to control alternate registers,
  91                    	; PIO B and CTC 2 for byte transfer by the NMI routine
  92                    	
  93                    	; void spiinit(), called once for initialization
  94                    	_spiinit:
  95                    		; reset CTC2 so that no NMIs are generated
  96    0038  3E03      		ld a, 00000011b		; bit 1: sw reset, bit 0: this is a ctrl cmd
  97    003A  D30E      		out (CTC_CH2), a
  98                    	
  99                    		; Set up PIO B, SPI interface
 100    003C  3ECF      		ld a, 11001111b		; mode 3
 101    003E  D313      		out (PIO_B_CTRL), a
 102    0040  3E01      		ld a, 00000001b		; i/o mask
 103                    		;bit 0: MISO - input     3                   3
 104                    		;bit 1: MOSI - output    4                   5
 105                    		;bit 2: SCK  - output    5                   7
 106                    		;bit 3: /CS0 - output    6                   9
 107                    		;bit 4: /CS1 - output  extra device select  11
 108                    		;bit 5: /CS2 - output  extra device select  10
 109                    		;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
 110                    		;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
 111                    		;                                                with an 8 bit transmit or receive transfer
 112    0042  D313      		out (PIO_B_CTRL), a
 113    0044  3E07      		ld a, 00000111b		; int disable
 114    0046  D313      		out (PIO_B_CTRL), a
 115                    		; bit 1: MOSI - output	;high
 116                    		; bit 2: SCK  - output	;low
 117                    		; bit 3: /CS0 - output	;high = not selected
 118                    		; bit 4: /CS1 - output	;high = not selected
 119                    		; bit 5: /CS2 - output	;high = not selected
 120                    		; bit 6: TP1  - output  ;low
 121                    		; bit 7: TRA  - output  ;low
 122    0048  3E3A      		ld a, 00111010b		;initialize output bits
 123    004A  D311      		out (PIO_B_DATA), a
 124                    		; initialize alternate registers to 0
 125    004C  D9        		exx
 126    004D  010000    		ld bc, 0
 127    0050  110000    		ld de, 0
 128    0053  D9        		exx
 129    0054  C9        		ret
 130                    	
 131                    	;void spiselect()
 132                    	_spiselect:
 133    0055  DB11      		in a, (PIO_B_DATA)
 134    0057  E6F7      		and 0f7h		;set /CS (bit 3) low i.e. active
 135    0059  D311      		out (PIO_B_DATA), a	;indicate that i/o is ongoing
 136    005B  C9        		ret
 137                    	
 138                    	;void spideselect()
 139                    	_spideselect:
 140    005C  DB11      		in a, (PIO_B_DATA)
 141    005E  F608      		or 008h			;set /CS (bit 3) hign i.e. not active
 142    0060  D311      		out (PIO_B_DATA), a	;indicate that i/o is ongoing
 143    0062  C9        		ret
 144                    	
 145                    	;unsigned int spiio(unsigned int), send/receive a byte
 146                    	_spiio:
 147    0063  CD0000    		call	c.savs
 148                    	spiiowt1:
 149    0066  DB11      		in a, (PIO_B_DATA)	;wait until SPI i/o not ongoing
 150    0068  CB7F      		bit 7, a
 151    006A  20FA      		jr nz, spiiowt1
 152    006C  CBFF      		set 7, a
 153    006E  D311      		out (PIO_B_DATA), a	;indicate that i/o is ongoing
 154                    		; set up alternate registers for NMI handling
 155    0070  D9        		exx
 156    0071  DD5604    		ld d, (ix+4)		;byte to transmit
 157    0074  1E00      		ld e, 0			;where the received byte ends up
 158    0076  0611      		ld b, 17		;NMI counter, 2 * 8 pulses
 159                    					;+ 1 NMI before & the byte
 160    0078  D9        		exx
 161                    		; start CTC2 counter to generate NMIs
 162    0079  3E47      		ld a, 047h		;counter, with time const
 163    007B  D30E      		out (CTC_CH2), a
 164    007D  3E64      		ld a, 100		;counter divider
 165                    					;NMI frequency = 20 kHz
 166                    					;SCK frequency = 10 kHz
 167    007F  D30E      		out (CTC_CH2), a
 168                    	spiiowt2:
 169    0081  DB11      		in a, (PIO_B_DATA)	;wait until SPI byte i/o is ready
 170    0083  CB7F      		bit 7, a
 171    0085  20FA      		jr nz, spiiowt2
 172                    		;get recieved byte
 173    0087  D9        		exx
 174    0088  7B        		ld a, e			;the recieved byte is in reg E
 175    0089  D9        		exx
 176    008A  4F        		ld c, a
 177    008B  0600      		ld b, 0
 178    008D  C30000    		jp c.rets
 179                    	
 180                    	; I/O C functions for the Z80 Computer
 181                    	;
 182                    	_in:
 183    0090  CD0000    		call	c.savs
 184    0093  DD4E04    		ld	c,(ix+4)
 185    0096  DD4605    		ld	b,(ix+5)
 186    0099  ED78      		in	a,(c)
 187    009B  4F        		ld	c,a
 188    009C  0600      		ld	b,0
 189    009E  C30000    		jp	c.rets
 190                    	_out:
 191    00A1  CD0000    		call	c.savs
 192    00A4  DD4E04    		ld	c,(ix+4)
 193    00A7  DD4605    		ld	b,(ix+5)
 194    00AA  DD7E06    		ld	a,(ix+6)
 195    00AD  ED79      		out	(c),a
 196    00AF  C30000    		jp	c.rets
 197                    	
 198                    	_reload:
 199    00B2  C303F0    		jp 0F003H       ;fixed address in the monitor
 200                    	
 201                    	; hack to define routines that are used by olib but really belongs in a CP/M library
 202                    	
 203                    		.public	__svc
 204                    		.public	__setint
 205                    		.public __ltor
 206                    	
 207                    	__svc:
 208                    	__setint:
 209                    	__ltor:
 210                    	hackloop:
 211    00B5  C3B500    	    jp hackloop
 212                    	
 213                    	
 214                    		.end
 215                    	
