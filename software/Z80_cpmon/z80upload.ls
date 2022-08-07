   1                    	; z80upload.s
   2                    	;
   3                    	; Uploader for my DIY Z80 computer. This program
   4                    	; can upload files to memory using Xmodem,
   5                    	; execute the uploaded program and reboot.
   6                    	;
   7                    	; You are free to use, modify, and redistribute
   8                    	; this source code. The software is provided "as is",
   9                    	; without warranty of any kind.
  10                    	; Hastily Cobbled Together 2021 and 2022
  11                    	; by Hans-Ake Lund.
  12                    	; Modified to be assembled with Whitesmiths/COSMIC x80
  13                    	;
  14                    	; The upload program is copied from EPROM or RAM
  15                    	; by the calling program into high RAM memory
  16                    	; at UPLADR address where it is executed
  17                    	
  29                    	.include "z80comp.inc"
  19                    	
  20                    	; Define address where upload is running (should really be given in the Makefile)
  21                    	.define UPLADR = 0b000h
  22                    	
  23                    	; Character definitions, mainly for Xmodem protocol
  24                    	;
  25                    	.define EOS		= 00h	; End Of String
  26                    	.define CR		= 0dh	; Carriage Return (ENTER)
  27                    	.define LF		= 0ah	; Line Feed
  28                    	.define SPACE		= 20h	; Space
  29                    	.define TAB		= 09h	; Tabulator
  30                    	.define SOH		= 01h	; Xmodem start of header
  31                    	.define EOT		= 04h	; Xmodem end of transfer
  32                    	.define ACK		= 06h	; Xmodem ACK
  33                    	.define NAK		= 15h	; Xmodem NAK
  34                    	.define CTRLC		= 03h	; Control-C
  35                    	
  36                    	; Serial channel timeout loop counter
  37                    	.define GETCTM	= 9000		; loop counter for ~1 sec timeout
  38                    	
  39                    	; Pointer to address where the file will be uploaded
  40                    	.define UPLPTR      = 0fef0h
  41                    	; Pointer to address where to start executing
  42                    	.define EXEPTR      = 0fef2h
  43                    	
  44                    	; The program starts here when invoked
  45                    	;	org UPLADR
  46                    	monitor:
  47    0000  C30C00    		jp startupl
  48                    	
  49                    	; Reload from EPROM
  50                    	epromreload:
  51    0003  3E03      		ld a, 00000011b		; sw reset CTC2 to stop NMIs
  52    0005  D30E      		out (CTC_CH2), a
  53    0007  D300      		out (MEMEPROM), a	; select EPROM in lower 32KB address range
  54    0009  C30000    		jp 0000h		; and jump to start of EPROM
  55                    	
  56                    	startupl:
  57                    		; initialize stack pointer below code
  58    000C  3100B0    		ld sp, UPLADR
  59                    		; the hardware is supposed to be initialized by the
  60                    		; program that is uploading this code
  61    000F  D314      		out (LEDOFF),a	; Green LED off
  62                    	
  63                    		; upload and go
  64    0011  F3        		di
  65    0012  CD1800    		call upload
  66    0015  C31F01    		jp execute
  67                    	
  68                    	; Upload file to RAM
  69                    	upload:
  70    0018  21E400    		ld hl, upload_msg
  71    001B  CD9B01    		call print_string
  72    001E  D304      		out (MEMLORAM),a	; select RAM in lower 32KB address range
  73                    	
  74                    	; Xmodem recieve file and put in memory
  75                    	; protocol description
  76                    	;   http://pauillac.inria.fr/~doligez/zmodem/ymodem.txt
  77                    	; (much of the code is proudly stolen from PCGET.ASM)
  78                    	xupload:
  79                    	
  80                    		; gobble up garbage characters from the line
  81                    	xpurge:
  82    0020  0601      		ld b, 1
  83    0022  CD6B01    		call getct
  84    0025  3807      		jr c, xrecieve
  85    0027  FE03      		cp CTRLC		;Ctrl-C was recieved
  86    0029  CADB00    		jp z, xabort
  87    002C  18F2      		jr xpurge		;loop until sender done
  88                    	
  89                    		; Recieve file and put in memory
  90                    	xrecieve:
  91    002E  2AF0FE    		ld hl, (UPLPTR)		;where to start putting memory in RAM
  92    0031  22AB01    		ld (memptr), hl
  93                    	
  94    0034  3E00      		ld a, 0			;initialize last sector number
  95    0036  32AE01    		ld (xlsectno), a
  96                    	
  97    0039  3E15      		ld a, NAK		;send NAK
  98    003B  CD5901    		call putc
  99                    	
 100                    		; Recieve header
 101                    	xgethdr:
 102    003E  0603      		ld b, 3			;3 seconds timeout
 103    0040  CD6B01    		call getct
 104    0043  300E      		jr nc, xgethchr		;no timeout, identify character in header
 105                    	
 106                    		; Header error or timeout
 107                    		; purge input characters and send NAK
 108                    	xhdrerr:
 109    0045  0601      		ld b, 1
 110    0047  CD6B01    		call getct
 111    004A  30F9      		jr nc, xhdrerr		;loop until sender done
 112    004C  3E15      		ld a, NAK
 113    004E  CD5901    		call putc
 114    0051  18EB      		jr xgethdr		;try to get header again
 115                    	
 116                    		; Which type of header? SOH, EOT or Ctrl-C to abort
 117                    	xgethchr:
 118    0053  FE01      		cp SOH
 119    0055  280C      		jr z, xgotsoh
 120    0057  FE03      		cp CTRLC
 121    0059  CADB00    		jp z, xabort
 122    005C  FE04      		cp EOT
 123    005E  CAC700    		jp z, xgoteot
 124    0061  18E2      		jr xhdrerr
 125                    	
 126                    		; Got SOH header
 127                    	xgotsoh:
 128                    	
 129    0063  0601      		ld b, 1
 130    0065  CD6B01    		call getct
 131    0068  38DB      		jr c, xhdrerr
 132    006A  57        		ld d, a			;sector number
 133    006B  0601      		ld b, 1
 134    006D  CD6B01    		call getct
 135    0070  38D3      		jr c, xhdrerr
 136    0072  2F        		cpl			;complement of block number
 137    0073  BA        		cp d
 138    0074  2802      		jr z, xgetsec		;good sector header, get sector
 139    0076  18CD      		jr xhdrerr
 140                    	
 141                    		; Get sector and put in temporary buffer
 142                    	xgetsec:
 143    0078  7A        		ld a, d
 144    0079  32AD01    		ld (xcsectno), a	;current sector
 145    007C  0E00      		ld c, 0			;init checksum
 146    007E  21AF01    		ld hl, xsectbuf		;temporary buffer for uploaded data
 147    0081  1680      		ld d, 128		;sector length
 148                    	xgetschar:
 149    0083  0601      		ld b, 1
 150    0085  CD6B01    		call getct
 151    0088  38BB      		jr c, xhdrerr
 152    008A  77        		ld (hl), a		;store byte in memory
 153    008B  81        		add c			;calculate checksum
 154    008C  4F        		ld c, a
 155    008D  23        		inc hl
 156    008E  15        		dec d
 157    008F  20F2      		jr nz, xgetschar
 158                    	
 159                    		; Verify the checksum
 160    0091  51        		ld d, c			;verify checksum
 161    0092  0601      		ld b, 1
 162    0094  CD6B01    		call getct
 163    0097  38AC      		jr c, xhdrerr
 164    0099  BA        		cp d
 165    009A  20A9      		jr nz, xhdrerr
 166                    	
 167                    		; Check that this sector number is last sector + 1
 168    009C  3AAD01    		ld a, (xcsectno)
 169    009F  47        		ld b, a
 170    00A0  3AAE01    		ld a, (xlsectno)
 171    00A3  3C        		inc a
 172    00A4  B8        		cp b
 173    00A5  2802      		jr z, xwrtsec		;expected sector number ok
 174                    	
 175                    		; sender missed last ACK
 176    00A7  1816      		jr xsndack
 177                    	
 178                    		; got new sector, write it to memory
 179                    	xwrtsec:
 180                    	
 181    00A9  3AAD01    		ld a, (xcsectno)	;update sector number
 182    00AC  32AE01    		ld (xlsectno), a
 183    00AF  ED5BAB01  		ld de, (memptr)		;where to put the uploaded data
 184    00B3  21AF01    		ld hl, xsectbuf		;from the recieve buffer
 185    00B6  018000    		ld bc, 128
 186                    	xcpymem:
 187    00B9  EDB0      		ldir
 188    00BB  ED53AB01  		ld (memptr), de		;update the destination in memory
 189                    	xsndack:
 190    00BF  3E06      		ld a, ACK		;send ACK
 191    00C1  CD5901    		call putc
 192    00C4  C33E00    		jp xgethdr		;get next sector
 193                    	
 194                    		; Got EOT, upload finished
 195                    	xgoteot:
 196                    	
 197    00C7  3E06      		ld a, ACK
 198    00C9  CD5901    		call putc
 199                    	
 200                    		;write message that upload was ok
 201    00CC  213075    		ld hl, 30000     ;but wait a while first
 202                    	xokwait:
 203    00CF  2B        	    dec hl
 204    00D0  7C        		ld a, h
 205    00D1  B5        	    or l
 206    00D2  20FB      	    jr nz, xokwait 
 207    00D4  21F400    		ld hl, upcpl_msg
 208    00D7  CD9B01    		call print_string
 209                    	
 210    00DA  C9        		ret
 211                    	
 212                    	xabort:
 213    00DB  210801    		ld hl, uperr_msg	;write message that upload was interrupted
 214    00DE  CD9B01    		call print_string
 215    00E1  C30300    		jp epromreload
 216                    	
 217                    	upload_msg:
 218    00E4  75706C6F  		.text "uploading file ", 0
              6164696E
              67206669
              6C652000
 219                    	
 220                    	upcpl_msg:
 221    00F4  2D207570  		.text "- upload complete\r\n", 0
              6C6F6164
              20636F6D
              706C6574
              650D0A00
 222                    	
 223                    	uperr_msg:
 224    0108  0D0A7570  		.text "\r\nupload interrupted\r\n", 0
              6C6F6164
              20696E74
              65727275
              70746564
              0D0A00
 225                    	
 226                    	
 227                    	; Execute code in RAM
 228                    	execute:
 229    011F  D304      		out (MEMLORAM),a	; select RAM in lower 32KB address range
 230    0121  212B01    		ld hl, execute_msg
 231    0124  CD9B01    		call print_string
 232    0127  2AF2FE    		ld hl, (EXEPTR)
 233    012A  E9        		jp (hl)
 234                    	
 235                    	execute_msg:
 236    012B  65786563  		.text "executing code in RAM\r\n", 0
              7574696E
              6720636F
              64652069
              6E205241
              4D0D0A00
 237                    	
 238                    	; tx_ready: waits for transmitt buffer to become empty
 239                    	; affects: none
 240                    	sio_tx_ready:
 241    0143  F5        		push af
 242    0144  C5        		push bc
 243                    	sio_tx_ready_loop:
 244    0145  DB0A      		in a, (SIO_A_CTRL)	; read RR0
 245    0147  CB57      		bit 2, a		; check if bit 2 is set
 246    0149  28FA      		jr z, sio_tx_ready_loop	; if no - check again
 247    014B  C1        		pop bc
 248    014C  F1        		pop af
 249    014D  C9        		ret
 250                    	
 251                    	; rx_ready: waits for a character to become available
 252                    	; affects: none
 253                    	sio_rx_ready:
 254    014E  F5        		push af
 255    014F  C5        		push bc
 256                    	sio_rx_ready_loop:
 257    0150  DB0A      		in a, (SIO_A_CTRL)	; read RR0
 258    0152  CB47      		bit 0, a		; check if bit 0 is set
 259    0154  28FA      		jr z, sio_rx_ready_loop	; if no - rx buffer has no data => check again
 260    0156  C1        		pop bc
 261    0157  F1        		pop af
 262    0158  C9        		ret
 263                    	
 264                    	; sends byte in reg A
 265                    	; affects: none
 266                    	putc:
 267    0159  C5        		push bc
 268    015A  F5        		push af
 269    015B  CD4301    		call sio_tx_ready
 270    015E  F1        		pop af
 271    015F  D308      		out (SIO_A_DATA), a	; write character
 272    0161  C1        		pop bc
 273    0162  C9        		ret
 274                    	
 275                    	; getc: waits for a byte to be available and reads it
 276                    	; returns: A - read byte
 277                    	getc:
 278    0163  C5        		push bc
 279    0164  CD4E01    		call sio_rx_ready	; wait until there is a character
 280    0167  DB08      		in a, (SIO_A_DATA)	; read character
 281    0169  C1        		pop bc
 282    016A  C9        		ret
 283                    	
 284                    	; getct: waits for a byte to be available with timeout and reads it
 285                    	; reg B - timeout in seconds
 286                    	; returns:
 287                    	;   Carry = 1: timeout, Carry = 0: no timeout
 288                    	;   reg A - read byte
 289                    	getct:
 290    016B  C5        		push bc
 291    016C  D5        		push de
 292    016D  112823    		ld de, GETCTM
 293                    	getcloop:
 294    0170  DB0A      		in a, (SIO_A_CTRL)	; read RR0
 295    0172  CB47      		bit 0, a		; check if bit 0 is set
 296    0174  2009      		jr nz, getchrin		; character available
 297    0176  1B        		dec de
 298    0177  7A        		ld a, d
 299    0178  B3        		or e
 300    0179  20F5      		jr nz, getcloop		; inner loop
 301    017B  10F3      		djnz getcloop		; outer loop, number of seconds
 302    017D  1807      		jr getcnochr		; timeout
 303                    	getchrin:
 304    017F  DB08      		in a, (SIO_A_DATA)	; read character
 305    0181  D1        		pop de
 306    0182  C1        		pop bc
 307    0183  37        		scf
 308    0184  3F        		ccf			; Carry = 0, no timeout
 309    0185  C9        		ret
 310                    	getcnochr:
 311    0186  3E00      		ld a, 0
 312    0188  D1        		pop de
 313    0189  C1        		pop bc
 314    018A  37        		scf			; Carry = 1, timeout
 315    018B  C9        		ret
 316                    	
 317                    	; getkey: gets a byte if available and reads it
 318                    	; returns: A - read byte or 0 if no byte available
 319                    	getkey:
 320    018C  C5        		push bc
 321    018D  DB0A      		in a, (SIO_A_CTRL)	; read RR0
 322    018F  CB47      		bit 0, a		; check if bit 0 is set
 323    0191  2804      		jr z, no_key		; if no - rx buffer has no data => return 0
 324    0193  DB08      		in a, (SIO_A_DATA)	; read character
 325    0195  C1        		pop bc
 326    0196  C9        		ret
 327                    	no_key:
 328    0197  3E00      		ld a, 0
 329    0199  C1        		pop bc
 330    019A  C9        		ret
 331                    	
 332                    	; print_string: prints a string which starts at adress HL
 333                    	; and is terminated by EOS-character
 334                    	; affects: none
 335                    	print_string:
 336    019B  F5        		push af
 337    019C  E5        		push hl
 338                    	print_string_1:
 339    019D  7E        		ld a,(hl)		; load next character
 340    019E  FE00      		cp 0			; is it en End Of String - character?
 341    01A0  2806      		jr z, print_string_2	; yes - return
 342    01A2  CD5901    		call putc		; no - print character
 343    01A5  23        		inc hl			; HL++
 344    01A6  18F5      		jr print_string_1	; do it again
 345                    	print_string_2:
 346    01A8  E1        		pop hl
 347    01A9  F1        		pop af
 348    01AA  C9        		ret
 349                    	
 350                    	; Variables
 351                    	memptr:		;pointer to the memory address where to put data
 352    01AB  0000      		.word 0
 353                    	xcsectno:	;current recieved sector number
 354    01AD  00        		.byte 0
 355                    	xlsectno:	;last recieved sector number
 356    01AE  00        		.byte 0
 357                    	xsectbuf:	;temporary recieve sector buffer
 358    022C  00000000  		.byte 0, [128]
 359                    	
 360                    	; End of monitor code
 361                    	monend:
 362                    	
 363                    	.end
 364                    	
