   1                    	;**************************************************************
   2                    	;*
   3                    	;*             C P / M   version   2 . 2
   4                    	;*
   5                    	;*   Reconstructed from memory image on February 27, 1981
   6                    	;*
   7                    	;*                by Clark A. Calkins
   8                    	;*
   9                    	;*   Modifications by Madis Kaal 2018 to produce identical
  10                    	;*   binary image to actual CPM.SYS for some Xerox machine
  11                    	;*   Also fixed some minor typos and converted to pyz80
  12                    	;*   assembler syntax
  13                    	;**************************************************************
  14                    	;
  15                    	; Modified for Whitesmiths/COSMIC x80 assembler and tools for Z80
  16                    	;
  17                    	; You are free to use, modify, and redistribute
  18                    	; the source code implementing the modifications.
  19                    	; No warranties are given.
  20                    	; The adoptions were Hastily Cobbled Together 2022
  21                    	; by Hans-Ake Lund
  22                    	;
  23                    	
  65                    	.include "cpm.inc"
  25                    	
  26                    	; BIOS functions
  27                    	.external CBOOT, WBOOT, CONST, CONIN, CONOUT, LIST, PUNCH, READER
  28                    	.external HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, LISTST, SECTRN
  29                    	
  30                    	.public BDOSSTART, FBASE
  31                    	
  32                    	BDOSSTART:
  33                    	;
  34                    	;   Note that the following six bytes must match those at
  35                    	; (PATTRN1) or cp/m will HALT.
  36                    	;
  37    0000  09590000  		.byte	09h, 59h, 00h, 00h, 07h, 89h	;(* serial number bytes *).
              0789
  38                    	;
  39                    	;**************************************************************
  40                    	;*
  41                    	;*                    B D O S   E N T R Y
  42                    	;*
  43                    	;**************************************************************
  44                    	;
  45    0006  C31100    	FBASE:	JP	FBASE1
  46                    	;
  47                    	;   Bdos error table.
  48                    	;
  49    0009  9900      	BADSCTR:.word	ERROR1		;bad sector on read or write.
  50    000B  A500      	BADSLCT:.word	ERROR2		;bad disk select.
  51    000D  AB00      	RODISK:	.word	ERROR3		;disk is read only.
  52    000F  B100      	ROFILE:	.word	ERROR4		;file is read only.
  53                    	;
  54                    	;   Entry into bdos. (DE) or (E) are the parameters passed. The
  55                    	; function number desired is in register (C).
  56                    	;
  57                    	FBASE1:
  58    0011  EB        		EX	DE,HL		;save the (DE) parameters.
  59    0012  224303    		LD	(PARAMS),HL
  60    0015  EB        		EX	DE,HL
  61    0016  7B        		LD	A,E		;and save register (E) in particular.
  62    0017  32D60D    		LD	(EPARAM),A
  63    001A  210000    		LD	HL,0
  64    001D  224503    		LD	(STATUS),HL	;clear return status.
  65    0020  39        		ADD	HL,SP
  66    0021  220F03    		LD	(USRSTACK),HL	;save users stack pointer.
  67    0024  314103    		LD	SP,STKAREA	;and set our own.
  68    0027  AF        		XOR	A		;clear auto select storage space.
  69    0028  32E00D    		LD	(AUTOFLAG),A
  70    002B  32DE0D    		LD	(AUTO),A
  71    002E  21740D    		LD	HL,GOBACK	;set return address.
  72    0031  E5        		PUSH	HL
  73    0032  79        		LD	A,C		;get function number.
  74    0033  FE29      		CP	NFUNCTS		;valid function number?
  75    0035  D0        		RET	NC
  76    0036  4B        		LD	C,E		;keep single register function here.
  77    0037  214700    		LD	HL,FUNCTNS	;now look thru the function table.
  78    003A  5F        		LD	E,A
  79    003B  1600      		LD	D,0		;(DE)=function number.
  80    003D  19        		ADD	HL,DE
  81    003E  19        		ADD	HL,DE		;(HL)=(start of table)+2*(function number).
  82    003F  5E        		LD	E,(HL)
  83    0040  23        		INC	HL
  84    0041  56        		LD	D,(HL)		;now (DE)=address for this function.
  85    0042  2A4303    		LD	HL,(PARAMS)	;retrieve parameters.
  86    0045  EB        		EX	DE,HL		;now (DE) has the original parameters.
  87    0046  E9        		JP	(HL)		;execute desired function.
  88                    	;
  89                    	;   BDOS function jump table.
  90                    	;
  91                    	.define NFUNCTS =	41		;number of functions in followin table.
  92                    	;
  93    0047  0000C802  	FUNCTNS:.word	WBOOT,GETCON,OUTCON,GETRDR,PUNCH,LIST,DIRCIO,GETIOB
              9001CE02
              00000000
              D402ED02
  94    0057  F302F802  		.word	SETIOB,PRTSTR,RDBUFF,GETCSTS,GETVER,RSTDSK,SETDSK,OPENFIL
              E101FE02
              7E0C830C
              450C9C0C
  95    0067  A50CAB0C  		.word	CLOSEFIL,GETFST,GETNXT,DELFILE,READSEQ,WRTSEQ,FCREATE
              C80CD70C
              E00CE60C
              EC0C
  96    0075  F50CFE0C  		.word	RENFILE,GETLOG,GETCRNT,PUTDMA,GETALOC,WRTPRTD,GETROV,SETATTR
              040D0A0D
              110D2C05
              170D1D0D
  97    0085  260D2D0D  		.word	GETPARM,GETUSER,RDRANDOM,WTRANDOM,FILESIZE,SETRAN,LOGOFF,RTN
              410D470D
              4D0D0E0C
              530D0403
  98    0095  04039B0D  		.word	RTN,WTSPECL
  99                    	;
 100                    	;   Bdos error message section.
 101                    	;
 102    0099  21CA00    	ERROR1:	LD	HL,BADSEC	;bad sector message.
 103    009C  CDE500    		CALL	PRTERR		;print it and get a 1 char responce.
 104    009F  FE03      		CP	CNTRLC		;re-boot request (control-c)?
 105    00A1  CA0000    		JP	Z,0		;yes.
 106    00A4  C9        		RET			;no, return to retry i/o function.
 107                    	;
 108    00A5  21D500    	ERROR2:	LD	HL,BADSEL	;bad drive selected.
 109    00A8  C3B400    		JP	ERROR5
 110                    	;
 111    00AB  21E100    	ERROR3:	LD	HL,DISKRO	;disk is read only.
 112    00AE  C3B400    		JP	ERROR5
 113                    	;
 114    00B1  21DC00    	ERROR4:	LD	HL,FILERO	;file is read only.
 115                    	;
 116    00B4  CDE500    	ERROR5:	CALL	PRTERR
 117                    	;    PRTPROB 'D'
 118    00B7  C30000    		JP	0		;always reboot on these errors.
 119                    	;
 120    00BA  42646F73  	BDOSERR:.byte	'B','d','o','s',' ','E','r','r',' ','O','n',' '
              20457272
              204F6E20
 121    00C6  203A2024  	BDOSDRV:.byte	' ',':',' ','$'
 122    00CA  42616420  	BADSEC:	.byte	'B','a','d',' ','S','e','c','t','o','r','$'
              53656374
              6F7224
 123    00D5  53656C65  	BADSEL:	.byte	'S','e','l','e','c','t','$'
              637424
 124    00DC  46696C65  	FILERO:	.byte	'F','i','l','e',' '
              20
 125    00E1  522F4F24  	DISKRO:	.byte	'R','/','O','$'
 126                    	;
 127                    	;   Print bdos error message.
 128                    	;
 129    00E5  E5        	PRTERR:	PUSH	HL		;save second message pointer.
 130    00E6  CDC901    		CALL	OUTCRLF		;send (cr)(lf).
 131    00E9  3A4203    		LD	A,(ACTIVE)	;get active drive.
 132    00EC  C641      		ADD	A,'A'		;make ascii.
 133    00EE  32C600    		LD	(BDOSDRV),A	;and put in message.
 134    00F1  01BA00    		LD	BC,BDOSERR	;and print it.
 135    00F4  CDD301    		CALL	PRTMESG
 136    00F7  C1        		POP	BC		;print second message line now.
 137    00F8  CDD301    		CALL	PRTMESG
 138                    	;
 139                    	;   Get an input character. We will check our 1 character
 140                    	; buffer first. This may be set by the console status routine.
 141                    	;
 142    00FB  210E03    	GETCHAR:LD	HL,CHARBUF	;check character buffer.
 143    00FE  7E        		LD	A,(HL)		;anything present already?
 144    00FF  3600      		LD	(HL),0		;...either case clear it.
 145    0101  B7        		OR	A
 146    0102  C0        		RET	NZ		;yes, use it.
 147    0103  C30000    		JP	CONIN		;nope, go get a character responce.
 148                    	;
 149                    	;   Input and echo a character.
 150                    	;
 151    0106  CDFB00    	GETECHO:CALL	GETCHAR		;input a character.
 152    0109  CD1401    		CALL	CHKCHAR		;carriage control?
 153    010C  D8        		RET	C		;no, a regular control char so don't echo.
 154    010D  F5        		PUSH	AF		;ok, save character now.
 155    010E  4F        		LD	C,A
 156    010F  CD9001    		CALL	OUTCON		;and echo it.
 157    0112  F1        		POP	AF		;get character and return.
 158    0113  C9        		RET	
 159                    	;
 160                    	;   Check character in (A). Set the zero flag on a carriage
 161                    	; control character and the carry flag on any other control
 162                    	; character.
 163                    	;
 164    0114  FE0D      	CHKCHAR:CP	CR		;check for carriage return, line feed, backspace,
 165    0116  C8        		RET	Z		;or a tab.
 166    0117  FE0A      		CP	LF
 167    0119  C8        		RET	Z
 168    011A  FE09      		CP	TAB
 169    011C  C8        		RET	Z
 170    011D  FE08      		CP	BS
 171    011F  C8        		RET	Z
 172    0120  FE20      		CP	' '		;other control char? Set carry flag.
 173    0122  C9        		RET	
 174                    	;
 175                    	;   Check the console during output. Halt on a control-s, then
 176                    	; reboot on a control-c. If anything else is ready, clear the
 177                    	; zero flag and return (the calling routine may want to do
 178                    	; something).
 179                    	;
 180    0123  3A0E03    	CKCONSOL: LD	A,(CHARBUF)	;check buffer.
 181    0126  B7        		OR	A		;if anything, just return without checking.
 182    0127  C24501    		JP	NZ,CKCON2
 183    012A  CD0000    		CALL	CONST		;nothing in buffer. Check console.
 184    012D  E601      		AND	01h		;look at bit 0.
 185    012F  C8        		RET	Z		;return if nothing.
 186    0130  CD0000    		CALL	CONIN		;ok, get it.
 187    0133  FE13      		CP	CNTRLS		;if not control-s, return with zero cleared.
 188    0135  C24201    		JP	NZ,CKCON1
 189    0138  CD0000    		CALL	CONIN		;halt processing until another char
 190    013B  FE03      		CP	CNTRLC		;is typed. Control-c?
 191    013D  CA0000    		JP	Z,0		;yes, reboot now.
 192    0140  AF        		XOR	A		;no, just pretend nothing was ever ready.
 193    0141  C9        		RET	
 194    0142  320E03    	CKCON1:	LD	(CHARBUF),A	;save character in buffer for later processing.
 195    0145  3E01      	CKCON2:	LD	A,1		;set (A) to non zero to mean something is ready.
 196    0147  C9        		RET	
 197                    	;
 198                    	;   Output (C) to the screen. If the printer flip-flop flag
 199                    	; is set, we will send character to printer also. The console
 200                    	; will be checked in the process.
 201                    	;
 202    0148  3A0A03    	OUTCHAR:LD	A,(OUTFLAG)	;check output flag.
 203    014B  B7        		OR	A		;anything and we won't generate output.
 204    014C  C26201    		JP	NZ,OUTCHR1
 205    014F  C5        		PUSH	BC
 206    0150  CD2301    		CALL	CKCONSOL	;check console (we don't care whats there).
 207    0153  C1        		POP	BC
 208    0154  C5        		PUSH	BC
 209    0155  CD0000    		CALL	CONOUT		;output (C) to the screen.
 210    0158  C1        		POP	BC
 211    0159  C5        		PUSH	BC
 212    015A  3A0D03    		LD	A,(PRTFLAG)	;check printer flip-flop flag.
 213    015D  B7        		OR	A
 214    015E  C40000    		CALL	NZ,LIST		;print it also if non-zero.
 215    0161  C1        		POP	BC
 216    0162  79        	OUTCHR1:LD	A,C		;update cursors position.
 217    0163  210C03    		LD	HL,CURPOS
 218    0166  FE7F      		CP	DEL		;rubouts don't do anything here.
 219    0168  C8        		RET	Z
 220    0169  34        		INC	(HL)		;bump line pointer.
 221    016A  FE20      		CP	' '		;and return if a normal character.
 222    016C  D0        		RET	NC
 223    016D  35        		DEC	(HL)		;restore and check for the start of the line.
 224    016E  7E        		LD	A,(HL)
 225    016F  B7        		OR	A
 226    0170  C8        		RET	Z		;ingnore control characters at the start of the line.
 227    0171  79        		LD	A,C
 228    0172  FE08      		CP	BS		;is it a backspace?
 229    0174  C27901    		JP	NZ,OUTCHR2
 230    0177  35        		DEC	(HL)		;yes, backup pointer.
 231    0178  C9        		RET	
 232    0179  FE0A      	OUTCHR2:CP	LF		;is it a line feed?
 233    017B  C0        		RET	NZ		;ignore anything else.
 234    017C  3600      		LD	(HL),0		;reset pointer to start of line.
 235    017E  C9        		RET	
 236                    	;
 237                    	;   Output (A) to the screen. If it is a control character
 238                    	; (other than carriage control), use ^x format.
 239                    	;
 240    017F  79        	SHOWIT:	LD	A,C
 241    0180  CD1401    		CALL	CHKCHAR		;check character.
 242    0183  D29001    		JP	NC,OUTCON	;not a control, use normal output.
 243    0186  F5        		PUSH	AF
 244    0187  0E5E      		LD	C,'^'		;for a control character, preceed it with '^'.
 245    0189  CD4801    		CALL	OUTCHAR
 246    018C  F1        		POP	AF
 247    018D  F640      		OR	'@'		;and then use the letter equivelant.
 248    018F  4F        		LD	C,A
 249                    	;
 250                    	;   Function to output (C) to the console device and expand tabs
 251                    	; if necessary.
 252                    	;
 253    0190  79        	OUTCON:	LD	A,C
 254    0191  FE09      		CP	TAB		;is it a tab?
 255    0193  C24801    		JP	NZ,OUTCHAR	;use regular output.
 256    0196  0E20      	OUTCON1:LD	C,' '		;yes it is, use spaces instead.
 257    0198  CD4801    		CALL	OUTCHAR
 258    019B  3A0C03    		LD	A,(CURPOS)	;go until the cursor is at a multiple of 8
 259                    	
 260    019E  E607      		AND	07h		;position.
 261    01A0  C29601    		JP	NZ,OUTCON1
 262    01A3  C9        		RET	
 263                    	;
 264                    	;   Echo a backspace character. Erase the prevoius character
 265                    	; on the screen.
 266                    	;
 267    01A4  CDAC01    	BACKUP:	CALL	BACKUP1		;backup the screen 1 place.
 268    01A7  0E20      		LD	C,' '		;then blank that character.
 269    01A9  CD0000    		CALL	CONOUT
 270    01AC  0E08      	BACKUP1:LD	C,BS		;then back space once more.
 271    01AE  C30000    		JP	CONOUT
 272                    	;
 273                    	;   Signal a deleted line. Print a '#' at the end and start
 274                    	; over.
 275                    	;
 276    01B1  0E23      	NEWLINE:LD	C,'#'
 277    01B3  CD4801    		CALL	OUTCHAR		;print this.
 278    01B6  CDC901    		CALL	OUTCRLF		;start new line.
 279    01B9  3A0C03    	NEWLN1:	LD	A,(CURPOS)	;move the cursor to the starting position.
 280    01BC  210B03    		LD	HL,STARTING
 281    01BF  BE        		CP	(HL)
 282    01C0  D0        		RET	NC		;there yet?
 283    01C1  0E20      		LD	C,' '
 284    01C3  CD4801    		CALL	OUTCHAR		;nope, keep going.
 285    01C6  C3B901    		JP	NEWLN1
 286                    	;
 287                    	;   Output a (cr) (lf) to the console device (screen).
 288                    	;
 289    01C9  0E0D      	OUTCRLF:LD	C,CR
 290    01CB  CD4801    		CALL	OUTCHAR
 291    01CE  0E0A      		LD	C,LF
 292    01D0  C34801    		JP	OUTCHAR
 293                    	;
 294                    	;   Print message pointed to by (BC). It will end with a '$'.
 295                    	;
 296    01D3  0A        	PRTMESG:LD	A,(BC)		;check for terminating character.
 297    01D4  FE24      		CP	'$'
 298    01D6  C8        		RET	Z
 299    01D7  03        		INC	BC
 300    01D8  C5        		PUSH	BC		;otherwise, bump pointer and print it.
 301    01D9  4F        		LD	C,A
 302    01DA  CD9001    		CALL	OUTCON
 303    01DD  C1        		POP	BC
 304    01DE  C3D301    		JP	PRTMESG
 305                    	;
 306                    	;   Function to execute a buffered read.
 307                    	;
 308    01E1  3A0C03    	RDBUFF:	LD	A,(CURPOS)	;use present location as starting one.
 309    01E4  320B03    		LD	(STARTING),A
 310    01E7  2A4303    		LD	HL,(PARAMS)	;get the maximum buffer space.
 311    01EA  4E        		LD	C,(HL)
 312    01EB  23        		INC	HL		;point to first available space.
 313    01EC  E5        		PUSH	HL		;and save.
 314    01ED  0600      		LD	B,0		;keep a character count.
 315    01EF  C5        	RDBUF1:	PUSH	BC
 316    01F0  E5        		PUSH	HL
 317    01F1  CDFB00    	RDBUF2:	CALL	GETCHAR		;get the next input character.
 318    01F4  E67F      		AND	7Fh		;strip bit 7.
 319    01F6  E1        		POP	HL		;reset registers.
 320    01F7  C1        		POP	BC
 321    01F8  FE0D      		CP	CR		;en of the line?
 322    01FA  CAC102    		JP	Z,RDBUF17
 323    01FD  FE0A      		CP	LF
 324    01FF  CAC102    		JP	Z,RDBUF17
 325    0202  FE08      		CP	BS		;how about a backspace?
 326    0204  C21602    		JP	NZ,RDBUF3
 327    0207  78        		LD	A,B		;yes, but ignore at the beginning of the line.
 328    0208  B7        		OR	A
 329    0209  CAEF01    		JP	Z,RDBUF1
 330    020C  05        		DEC	B		;ok, update counter.
 331    020D  3A0C03    		LD	A,(CURPOS)	;if we backspace to the start of the line,
 332    0210  320A03    		LD	(OUTFLAG),A	;treat as a cancel (control-x).
 333    0213  C37002    		JP	RDBUF10
 334    0216  FE7F      	RDBUF3:	CP	DEL		;user typed a rubout?
 335    0218  C22602    		JP	NZ,RDBUF4
 336    021B  78        		LD	A,B		;ignore at the start of the line.
 337    021C  B7        		OR	A
 338    021D  CAEF01    		JP	Z,RDBUF1
 339    0220  7E        		LD	A,(HL)		;ok, echo the prevoius character.
 340    0221  05        		DEC	B		;and reset pointers (counters).
 341    0222  2B        		DEC	HL
 342    0223  C3A902    		JP	RDBUF15
 343    0226  FE05      	RDBUF4:	CP	CNTRLE		;physical end of line?
 344    0228  C23702    		JP	NZ,RDBUF5
 345    022B  C5        		PUSH	BC		;yes, do it.
 346    022C  E5        		PUSH	HL
 347    022D  CDC901    		CALL	OUTCRLF
 348    0230  AF        		XOR	A		;and update starting position.
 349    0231  320B03    		LD	(STARTING),A
 350    0234  C3F101    		JP	RDBUF2
 351    0237  FE10      	RDBUF5:	CP	CNTRLP		;control-p?
 352    0239  C24802    		JP	NZ,RDBUF6
 353    023C  E5        		PUSH	HL		;yes, flip the print flag filp-flop byte.
 354    023D  210D03    		LD	HL,PRTFLAG
 355    0240  3E01      		LD	A,1		;PRTFLAG=1-PRTFLAG
 356    0242  96        		SUB	(HL)
 357    0243  77        		LD	(HL),A
 358    0244  E1        		POP	HL
 359    0245  C3EF01    		JP	RDBUF1
 360    0248  FE18      	RDBUF6:	CP	CNTRLX		;control-x (cancel)?
 361    024A  C25F02    		JP	NZ,RDBUF8
 362    024D  E1        		POP	HL
 363    024E  3A0B03    	RDBUF7:	LD	A,(STARTING)	;yes, backup the cursor to here.
 364    0251  210C03    		LD	HL,CURPOS
 365    0254  BE        		CP	(HL)
 366    0255  D2E101    		JP	NC,RDBUFF	;done yet?
 367    0258  35        		DEC	(HL)		;no, decrement pointer and output back up one space.
 368    0259  CDA401    		CALL	BACKUP
 369    025C  C34E02    		JP	RDBUF7
 370    025F  FE15      	RDBUF8:	CP	CNTRLU		;cntrol-u (cancel line)?
 371    0261  C26B02    		JP	NZ,RDBUF9
 372    0264  CDB101    		CALL	NEWLINE		;start a new line.
 373    0267  E1        		POP	HL
 374    0268  C3E101    		JP	RDBUFF
 375    026B  FE12      	RDBUF9:	CP	CNTRLR		;control-r?
 376    026D  C2A602    		JP	NZ,RDBUF14
 377    0270  C5        	RDBUF10:PUSH	BC		;yes, start a new line and retype the old one.
 378    0271  CDB101    		CALL	NEWLINE
 379    0274  C1        		POP	BC
 380    0275  E1        		POP	HL
 381    0276  E5        		PUSH	HL
 382    0277  C5        		PUSH	BC
 383    0278  78        	RDBUF11:LD	A,B		;done whole line yet?
 384    0279  B7        		OR	A
 385    027A  CA8A02    		JP	Z,RDBUF12
 386    027D  23        		INC	HL		;nope, get next character.
 387    027E  4E        		LD	C,(HL)
 388    027F  05        		DEC	B		;count it.
 389    0280  C5        		PUSH	BC
 390    0281  E5        		PUSH	HL
 391    0282  CD7F01    		CALL	SHOWIT		;and display it.
 392    0285  E1        		POP	HL
 393    0286  C1        		POP	BC
 394    0287  C37802    		JP	RDBUF11
 395    028A  E5        	RDBUF12:PUSH	HL		;done with line. If we were displaying
 396    028B  3A0A03    		LD	A,(OUTFLAG)	;then update cursor position.
 397    028E  B7        		OR	A
 398    028F  CAF101    		JP	Z,RDBUF2
 399    0292  210C03    		LD	HL,CURPOS	;because this line is shorter, we must
 400    0295  96        		SUB	(HL)		;back up the cursor (not the screen however)
 401    0296  320A03    		LD	(OUTFLAG),A	;some number of positions.
 402    0299  CDA401    	RDBUF13:CALL	BACKUP		;note that as long as (OUTFLAG) is non
 403    029C  210A03    		LD	HL,OUTFLAG	;zero, the screen will not be changed.
 404    029F  35        		DEC	(HL)
 405    02A0  C29902    		JP	NZ,RDBUF13
 406    02A3  C3F101    		JP	RDBUF2		;now just get the next character.
 407                    	;
 408                    	;   Just a normal character, put this in our buffer and echo.
 409                    	;
 410    02A6  23        	RDBUF14:INC	HL
 411    02A7  77        		LD	(HL),A		;store character.
 412    02A8  04        		INC	B		;and count it.
 413    02A9  C5        	RDBUF15:PUSH	BC
 414    02AA  E5        		PUSH	HL
 415    02AB  4F        		LD	C,A		;echo it now.
 416    02AC  CD7F01    		CALL	SHOWIT
 417    02AF  E1        		POP	HL
 418    02B0  C1        		POP	BC
 419    02B1  7E        		LD	A,(HL)		;was it an abort request?
 420    02B2  FE03      		CP	CNTRLC		;control-c abort?
 421    02B4  78        		LD	A,B
 422    02B5  C2BD02    		JP	NZ,RDBUF16
 423    02B8  FE01      		CP	1		;only if at start of line.
 424    02BA  CA0000    		JP	Z,0
 425    02BD  B9        	RDBUF16:CP	C		;nope, have we filled the buffer?
 426    02BE  DAEF01    		JP	C,RDBUF1
 427    02C1  E1        	RDBUF17:POP	HL		;yes end the line and return.
 428    02C2  70        		LD	(HL),B
 429    02C3  0E0D      		LD	C,CR
 430    02C5  C34801    		JP	OUTCHAR		;output (cr) and return.
 431                    	;
 432                    	;   Function to get a character from the console device.
 433                    	;
 434    02C8  CD0601    	GETCON:	CALL	GETECHO		;get and echo.
 435    02CB  C30103    		JP	SETSTAT		;save status and return.
 436                    	;
 437                    	;   Function to get a character from the tape reader device.
 438                    	;
 439    02CE  CD0000    	GETRDR:	CALL	READER		;get a character from reader, set status and return.
 440    02D1  C30103    		JP	SETSTAT
 441                    	;
 442                    	;  Function to perform direct console i/o. If (C) contains (FF)
 443                    	; then this is an input request. If (C) contains (FE) then
 444                    	; this is a status request. Otherwise we are to output (C).
 445                    	;
 446    02D4  79        	DIRCIO:	LD	A,C		;test for (FF).
 447    02D5  3C        		INC	A
 448    02D6  CAE002    		JP	Z,DIRC1
 449    02D9  3C        		INC	A		;test for (FE).
 450    02DA  CA0000    		JP	Z,CONST
 451    02DD  C30000    		JP	CONOUT		;just output (C).
 452    02E0  CD0000    	DIRC1:	CALL	CONST		;this is an input request.
 453    02E3  B7        		OR	A
 454    02E4  CA910D    		JP	Z,GOBACK1	;not ready? Just return (directly).
 455    02E7  CD0000    		CALL	CONIN		;yes, get character.
 456    02EA  C30103    		JP	SETSTAT		;set status and return.
 457                    	;
 458                    	;   Function to return the i/o byte.
 459                    	;
 460    02ED  3A0300    	GETIOB:	LD	A,(IOBYTE)
 461    02F0  C30103    		JP	SETSTAT
 462                    	;
 463                    	;   Function to set the i/o byte.
 464                    	;
 465    02F3  210300    	SETIOB:	LD	HL,IOBYTE
 466    02F6  71        		LD	(HL),C
 467    02F7  C9        		RET	
 468                    	;
 469                    	;   Function to print the character string pointed to by (DE)
 470                    	; on the console device. The string ends with a '$'.
 471                    	;
 472    02F8  EB        	PRTSTR:	EX	DE,HL
 473    02F9  4D        		LD	C,L
 474    02FA  44        		LD	B,H		;now (BC) points to it.
 475    02FB  C3D301    		JP	PRTMESG
 476                    	;
 477                    	;   Function to interigate the console device.
 478                    	;
 479    02FE  CD2301    	GETCSTS:CALL	CKCONSOL
 480                    	;
 481                    	;   Get here to set the status and return to the cleanup
 482                    	; section. Then back to the user.
 483                    	;
 484    0301  324503    	SETSTAT:LD	(STATUS),A
 485    0304  C9        	RTN:	RET	
 486                    	;
 487                    	;   Set the status to 1 (read or write error code).
 488                    	;
 489    0305  3E01      	IOERR1:	LD	A,1
 490    0307  C30103    		JP	SETSTAT
 491                    	;
 492    030A  00        	OUTFLAG:.byte	0		;output flag (non zero means no output).
 493    030B  00        	STARTING: .byte	0		;starting position for cursor.
 494    030C  00        	CURPOS:	.byte	0		;cursor position (0=start of line).
 495    030D  00        	PRTFLAG:.byte	0		;printer flag (control-p toggle). List if non zero.
 496    030E  00        	CHARBUF:.byte	0		;single input character buffer.
 497                    	;
 498                    	;   Stack area for BDOS calls.
 499                    	;
 500    030F  0000      	USRSTACK: .word	0		;save users stack pointer here.
 501                    	;
 502    0311  00000000  		.byte	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              00000000
              00000000
              00000000
              00000000
              00000000
 503    0329  00000000  		.byte	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              00000000
              00000000
              00000000
              00000000
              00000000
 504                    	STKAREA:			;end of stack area.
 505                    	;
 506    0341  00        	USERNO:	.byte	0		;current user number.
 507    0342  00        	ACTIVE:	.byte	0		;currently active drive.
 508    0343  0000      	PARAMS:	.word	0		;save (DE) parameters here on entry.
 509    0345  0000      	STATUS:	.word	0		;status returned from bdos function.
 510                    	;
 511                    	;   Select error occured, jump to error routine.
 512                    	;
 513    0347  210B00    	SLCTERR:LD	HL,BADSLCT
 514                    	;
 515                    	;   Jump to (HL) indirectly.
 516                    	;
 517    034A  5E        	JUMPHL:	LD	E,(HL)
 518    034B  23        		INC	HL
 519    034C  56        		LD	D,(HL)		;now (DE) contain the desired address.
 520    034D  EB        		EX	DE,HL
 521    034E  E9        		JP	(HL)
 522                    	;
 523                    	;   Block move. (DE) to (HL), (C) bytes total.
 524                    	;
 525    034F  0C        	DE2HL:	INC	C		;is count down to zero?
 526    0350  0D        	DE2HL1:	DEC	C
 527    0351  C8        		RET	Z		;yes, we are done.
 528    0352  1A        		LD	A,(DE)		;no, move one more byte.
 529    0353  77        		LD	(HL),A
 530    0354  13        		INC	DE
 531    0355  23        		INC	HL
 532    0356  C35003    		JP	DE2HL1		;and repeat.
 533                    	;
 534                    	;   Select the desired drive.
 535                    	;
 536    0359  3A4203    	SELECT:	LD	A,(ACTIVE)	;get active disk.
 537    035C  4F        		LD	C,A
 538    035D  CD0000    		CALL	SELDSK		;select it.
 539    0360  7C        		LD	A,H		;valid drive?
 540    0361  B5        		OR	L		;valid drive?
 541    0362  C8        		RET	Z		;return if not.
 542                    	;
 543                    	;   Here, the BIOS returned the address of the parameter block
 544                    	; in (HL). We will extract the necessary pointers and save them.
 545                    	;
 546    0363  5E        		LD	E,(HL)		;yes, get address of translation table into (DE).
 547    0364  23        		INC	HL
 548    0365  56        		LD	D,(HL)
 549    0366  23        		INC	HL
 550    0367  22B30D    		LD	(SCRATCH1),HL	;save pointers to scratch areas.
 551    036A  23        		INC	HL
 552    036B  23        		INC	HL
 553    036C  22B50D    		LD	(SCRATCH2),HL	;ditto.
 554    036F  23        		INC	HL
 555    0370  23        		INC	HL
 556    0371  22B70D    		LD	(SCRATCH3),HL	;ditto.
 557    0374  23        		INC	HL
 558    0375  23        		INC	HL
 559    0376  EB        		EX	DE,HL		;now save the translation table address.
 560    0377  22D00D    		LD	(XLATE),HL
 561    037A  21B90D    		LD	HL,DIRBUF	;put the next 8 bytes here.
 562    037D  0E08      		LD	C,8		;they consist of the directory buffer
 563    037F  CD4F03    		CALL	DE2HL		;pointer, parameter block pointer,
 564    0382  2ABB0D    		LD	HL,(DISKPB)	;check and allocation vectors.
 565    0385  EB        		EX	DE,HL
 566    0386  21C10D    		LD	HL,SECTORS	;move parameter block into our ram.
 567    0389  0E0F      		LD	C,15		;it is 15 bytes long.
 568    038B  CD4F03    		CALL	DE2HL
 569    038E  2AC60D    		LD	HL,(DSKSIZE)	;check disk size.
 570    0391  7C        		LD	A,H		;more than 256 blocks on this?
 571    0392  21DD0D    		LD	HL,BIGDISK
 572    0395  36FF      		LD	(HL),0FFh	;set to samll.
 573    0397  B7        		OR	A
 574    0398  CA9D03    		JP	Z,SELECT1
 575    039B  3600      		LD	(HL),0		;wrong, set to large.
 576    039D  3EFF      	SELECT1:LD	A,0FFh		;clear the zero flag.
 577    039F  B7        		OR	A
 578    03A0  C9        		RET	
 579                    	;
 580                    	;   Routine to home the disk track head and clear pointers.
 581                    	;
 582    03A1  CD0000    	HOMEDRV:CALL	HOME		;home the head.
 583    03A4  AF        		XOR	A
 584    03A5  2AB50D    		LD	HL,(SCRATCH2)	;set our track pointer also.
 585    03A8  77        		LD	(HL),A
 586    03A9  23        		INC	HL
 587    03AA  77        		LD	(HL),A
 588    03AB  2AB70D    		LD	HL,(SCRATCH3)	;and our sector pointer.
 589    03AE  77        		LD	(HL),A
 590    03AF  23        		INC	HL
 591    03B0  77        		LD	(HL),A
 592    03B1  C9        		RET	
 593                    	;
 594                    	;   Do the actual disk read and check the error return status.
 595                    	;
 596    03B2  CD0000    	DOREAD:	CALL	READ
 597                    	;    PRTPROB 'J'
 598    03B5  C3BB03    		JP	IORET
 599                    	;
 600                    	;   Do the actual disk write and handle any bios error.
 601                    	;
 602    03B8  CD0000    	DOWRITE:CALL	WRITE
 603    03BB  B7        	IORET:	OR	A
 604    03BC  C8        		RET	Z		;return unless an error occured.
 605    03BD  210900    		LD	HL,BADSCTR	;bad read/write on this sector.
 606    03C0  C34A03    		JP	JUMPHL
 607                    	;
 608                    	;   Routine to select the track and sector that the desired
 609                    	; block number falls in.
 610                    	;
 611    03C3  2AEA0D    	TRKSEC:	LD	HL,(FILEPOS)	;get position of last accessed file
 612    03C6  0E02      		LD	C,2		;in directory and compute sector #.
 613    03C8  CDEA04    		CALL	SHIFTR		;sector #=file-position/4.
 614    03CB  22E50D    		LD	(BLKNMBR),HL	;save this as the block number of interest.
 615    03CE  22EC0D    		LD	(CKSUMTBL),HL	;what's it doing here too?
 616                    	;
 617                    	;   if the sector number has already been set (BLKNMBR), enter
 618                    	; at this point.
 619                    	;
 620    03D1  21E50D    	TRKSEC1:LD	HL,BLKNMBR
 621    03D4  4E        		LD	C,(HL)		;move sector number into (BC).
 622    03D5  23        		INC	HL
 623    03D6  46        		LD	B,(HL)
 624    03D7  2AB70D    		LD	HL,(SCRATCH3)	;get current sector number and
 625    03DA  5E        		LD	E,(HL)		;move this into (DE).
 626    03DB  23        		INC	HL
 627    03DC  56        		LD	D,(HL)
 628    03DD  2AB50D    		LD	HL,(SCRATCH2)	;get current track number.
 629    03E0  7E        		LD	A,(HL)		;and this into (HL).
 630    03E1  23        		INC	HL
 631    03E2  66        		LD	H,(HL)
 632    03E3  6F        		LD	L,A
 633    03E4  79        	TRKSEC2:LD	A,C		;is desired sector before current one?
 634    03E5  93        		SUB	E
 635    03E6  78        		LD	A,B
 636    03E7  9A        		SBC	A,D
 637    03E8  D2FA03    		JP	NC,TRKSEC3
 638    03EB  E5        		PUSH	HL		;yes, decrement sectors by one track.
 639    03EC  2AC10D    		LD	HL,(SECTORS)	;get sectors per track.
 640    03EF  7B        		LD	A,E
 641    03F0  95        		SUB	L
 642    03F1  5F        		LD	E,A
 643    03F2  7A        		LD	A,D
 644    03F3  9C        		SBC	A,H
 645    03F4  57        		LD	D,A		;now we have backed up one full track.
 646    03F5  E1        		POP	HL
 647    03F6  2B        		DEC	HL		;adjust track counter.
 648    03F7  C3E403    		JP	TRKSEC2
 649    03FA  E5        	TRKSEC3:PUSH	HL		;desired sector is after current one.
 650    03FB  2AC10D    		LD	HL,(SECTORS)	;get sectors per track.
 651    03FE  19        		ADD	HL,DE		;bump sector pointer to next track.
 652    03FF  DA0F04    		JP	C,TRKSEC4
 653    0402  79        		LD	A,C		;is desired sector now before current one?
 654    0403  95        		SUB	L
 655    0404  78        		LD	A,B
 656    0405  9C        		SBC	A,H
 657    0406  DA0F04    		JP	C,TRKSEC4
 658    0409  EB        		EX	DE,HL		;not yes, increment track counter
 659    040A  E1        		POP	HL		;and continue until it is.
 660    040B  23        		INC	HL
 661    040C  C3FA03    		JP	TRKSEC3
 662                    	;
 663                    	;   here we have determined the track number that contains the
 664                    	; desired sector.
 665                    	;
 666    040F  E1        	TRKSEC4:POP	HL		;get track number (HL).
 667    0410  C5        		PUSH	BC
 668    0411  D5        		PUSH	DE
 669    0412  E5        		PUSH	HL
 670    0413  EB        		EX	DE,HL
 671    0414  2ACE0D    		LD	HL,(OFFSET)	;adjust for first track offset.
 672    0417  19        		ADD	HL,DE
 673    0418  44        		LD	B,H
 674    0419  4D        		LD	C,L
 675    041A  CD0000    		CALL	SETTRK		;select this track.
 676    041D  D1        		POP	DE		;reset current track pointer.
 677    041E  2AB50D    		LD	HL,(SCRATCH2)
 678    0421  73        		LD	(HL),E
 679    0422  23        		INC	HL
 680    0423  72        		LD	(HL),D
 681    0424  D1        		POP	DE
 682    0425  2AB70D    		LD	HL,(SCRATCH3)	;reset the first sector on this track.
 683    0428  73        		LD	(HL),E
 684    0429  23        		INC	HL
 685    042A  72        		LD	(HL),D
 686    042B  C1        		POP	BC
 687    042C  79        		LD	A,C		;now subtract the desired one.
 688    042D  93        		SUB	E		;to make it relative (1-# sectors/track).
 689    042E  4F        		LD	C,A
 690    042F  78        		LD	A,B
 691    0430  9A        		SBC	A,D
 692    0431  47        		LD	B,A
 693    0432  2AD00D    		LD	HL,(XLATE)	;translate this sector according to this table.
 694    0435  EB        		EX	DE,HL
 695    0436  CD0000    		CALL	SECTRN		;let the bios translate it.
 696    0439  4D        		LD	C,L
 697    043A  44        		LD	B,H
 698    043B  C30000    		JP	SETSEC		;and select it.
 699                    	;
 700                    	;   Compute block number from record number (SAVNREC) and
 701                    	; extent number (SAVEXT).
 702                    	;
 703    043E  21C30D    	GETBLOCK: LD	HL,BLKSHFT	;get logical to physical conversion.
 704    0441  4E        		LD	C,(HL)		;note that this is base 2 log of ratio.
 705    0442  3AE30D    		LD	A,(SAVNREC)	;get record number.
 706    0445  B7        	GETBLK1:OR	A		;compute (A)=(A)/2^BLKSHFT.
 707    0446  1F        		RRA	
 708    0447  0D        		DEC	C
 709    0448  C24504    		JP	NZ,GETBLK1
 710    044B  47        		LD	B,A		;save result in (B).
 711    044C  3E08      		LD	A,8
 712    044E  96        		SUB	(HL)
 713    044F  4F        		LD	C,A		;compute (C)=8-BLKSHFT.
 714    0450  3AE20D    		LD	A,(SAVEXT)
 715    0453  0D        	GETBLK2:DEC	C		;compute (A)=SAVEXT*2^(8-BLKSHFT).
 716    0454  CA5C04    		JP	Z,GETBLK3
 717    0457  B7        		OR	A
 718    0458  17        		RLA	
 719    0459  C35304    		JP	GETBLK2
 720    045C  80        	GETBLK3:ADD	A,B
 721    045D  C9        		RET	
 722                    	;
 723                    	;   Routine to extract the (BC) block byte from the fcb pointed
 724                    	; to by (PARAMS). If this is a big-disk, then these are 16 bit
 725                    	; block numbers, else they are 8 bit numbers.
 726                    	; Number is returned in (HL).
 727                    	;
 728    045E  2A4303    	EXTBLK:	LD	HL,(PARAMS)	;get fcb address.
 729    0461  111000    		LD	DE,16		;block numbers start 16 bytes into fcb.
 730    0464  19        		ADD	HL,DE
 731    0465  09        		ADD	HL,BC
 732    0466  3ADD0D    		LD	A,(BIGDISK)	;are we using a big-disk?
 733    0469  B7        		OR	A
 734    046A  CA7104    		JP	Z,EXTBLK1
 735    046D  6E        		LD	L,(HL)		;no, extract an 8 bit number from the fcb.
 736    046E  2600      		LD	H,0
 737    0470  C9        		RET	
 738    0471  09        	EXTBLK1:ADD	HL,BC		;yes, extract a 16 bit number.
 739    0472  5E        		LD	E,(HL)
 740    0473  23        		INC	HL
 741    0474  56        		LD	D,(HL)
 742    0475  EB        		EX	DE,HL		;return in (HL).
 743    0476  C9        		RET	
 744                    	;
 745                    	;   Compute block number.
 746                    	;
 747    0477  CD3E04    	COMBLK:	CALL	GETBLOCK
 748    047A  4F        		LD	C,A
 749    047B  0600      		LD	B,0
 750    047D  CD5E04    		CALL	EXTBLK
 751    0480  22E50D    		LD	(BLKNMBR),HL
 752    0483  C9        		RET	
 753                    	;
 754                    	;   Check for a zero block number (unused).
 755                    	;
 756    0484  2AE50D    	CHKBLK:	LD	HL,(BLKNMBR)
 757    0487  7D        		LD	A,L		;is it zero?
 758    0488  B4        		OR	H
 759    0489  C9        		RET	
 760                    	;
 761                    	;   Adjust physical block (BLKNMBR) and convert to logical
 762                    	; sector (LOGSECT). This is the starting sector of this block.
 763                    	; The actual sector of interest is then added to this and the
 764                    	; resulting sector number is stored back in (BLKNMBR). This
 765                    	; will still have to be adjusted for the track number.
 766                    	;
 767    048A  3AC30D    	LOGICAL:LD	A,(BLKSHFT)	;get log2(physical/logical sectors).
 768    048D  2AE50D    		LD	HL,(BLKNMBR)	;get physical sector desired.
 769    0490  29        	LOGICL1:ADD	HL,HL		;compute logical sector number.
 770    0491  3D        		DEC	A		;note logical sectors are 128 bytes long.
 771    0492  C29004    		JP	NZ,LOGICL1
 772    0495  22E70D    		LD	(LOGSECT),HL	;save logical sector.
 773    0498  3AC40D    		LD	A,(BLKMASK)	;get block mask.
 774    049B  4F        		LD	C,A
 775    049C  3AE30D    		LD	A,(SAVNREC)	;get next sector to access.
 776    049F  A1        		AND	C		;extract the relative position within physical block.
 777    04A0  B5        		OR	L		;and add it too logical sector.
 778    04A1  6F        		LD	L,A
 779    04A2  22E50D    		LD	(BLKNMBR),HL	;and store.
 780    04A5  C9        		RET	
 781                    	;
 782                    	;   Set (HL) to point to extent byte in fcb.
 783                    	;
 784    04A6  2A4303    	SETEXT:	LD	HL,(PARAMS)
 785    04A9  110C00    		LD	DE,12		;it is the twelth byte.
 786    04AC  19        		ADD	HL,DE
 787    04AD  C9        		RET	
 788                    	;
 789                    	;   Set (HL) to point to record count byte in fcb and (DE) to
 790                    	; next record number byte.
 791                    	;
 792    04AE  2A4303    	SETHLDE:LD	HL,(PARAMS)
 793    04B1  110F00    		LD	DE,15		;record count byte (#15).
 794    04B4  19        		ADD	HL,DE
 795    04B5  EB        		EX	DE,HL
 796    04B6  211100    		LD	HL,17		;next record number (#32).
 797    04B9  19        		ADD	HL,DE
 798    04BA  C9        		RET	
 799                    	;
 800                    	;   Save current file data from fcb.
 801                    	;
 802    04BB  CDAE04    	STRDATA:CALL	SETHLDE
 803    04BE  7E        		LD	A,(HL)		;get and store record count byte.
 804    04BF  32E30D    		LD	(SAVNREC),A
 805    04C2  EB        		EX	DE,HL
 806    04C3  7E        		LD	A,(HL)		;get and store next record number byte.
 807    04C4  32E10D    		LD	(SAVNXT),A
 808    04C7  CDA604    		CALL	SETEXT		;point to extent byte.
 809    04CA  3AC50D    		LD	A,(EXTMASK)	;get extent mask.
 810    04CD  A6        		AND	(HL)
 811    04CE  32E20D    		LD	(SAVEXT),A	;and save extent here.
 812    04D1  C9        		RET	
 813                    	;
 814                    	;   Set the next record to access. If (MODE) is set to 2, then
 815                    	; the last record byte (SAVNREC) has the correct number to access.
 816                    	; For sequential access, (MODE) will be equal to 1.
 817                    	;
 818    04D2  CDAE04    	SETNREC:CALL	SETHLDE
 819    04D5  3AD50D    		LD	A,(MODE)	;get sequential flag (=1).
 820    04D8  FE02      		CP	2		;a 2 indicates that no adder is needed.
 821    04DA  C2DE04    		JP	NZ,STNREC1
 822    04DD  AF        		XOR	A		;clear adder (random access?).
 823    04DE  4F        	STNREC1:LD	C,A
 824    04DF  3AE30D    		LD	A,(SAVNREC)	;get last record number.
 825    04E2  81        		ADD	A,C		;increment record count.
 826    04E3  77        		LD	(HL),A		;and set fcb's next record byte.
 827    04E4  EB        		EX	DE,HL
 828    04E5  3AE10D    		LD	A,(SAVNXT)	;get next record byte from storage.
 829    04E8  77        		LD	(HL),A		;and put this into fcb as number of records used.
 830    04E9  C9        		RET	
 831                    	;
 832                    	;   Shift (HL) right (C) bits.
 833                    	;
 834    04EA  0C        	SHIFTR:	INC	C
 835    04EB  0D        	SHIFTR1:DEC	C
 836    04EC  C8        		RET	Z
 837    04ED  7C        		LD	A,H
 838    04EE  B7        		OR	A
 839    04EF  1F        		RRA	
 840    04F0  67        		LD	H,A
 841    04F1  7D        		LD	A,L
 842    04F2  1F        		RRA	
 843    04F3  6F        		LD	L,A
 844    04F4  C3EB04    		JP	SHIFTR1
 845                    	;
 846                    	;   Compute the check-sum for the directory buffer. Return
 847                    	; integer sum in (A).
 848                    	;
 849    04F7  0E80      	CHECKSUM: LD	C,128		;length of buffer.
 850    04F9  2AB90D    		LD	HL,(DIRBUF)	;get its location.
 851    04FC  AF        		XOR	A		;clear summation byte.
 852    04FD  86        	CHKSUM1:ADD	A,(HL)		;and compute sum ignoring carries.
 853    04FE  23        		INC	HL
 854    04FF  0D        		DEC	C
 855    0500  C2FD04    		JP	NZ,CHKSUM1
 856    0503  C9        		RET	
 857                    	;
 858                    	;   Shift (HL) left (C) bits.
 859                    	;
 860    0504  0C        	SHIFTL:	INC	C
 861    0505  0D        	SHIFTL1:DEC	C
 862    0506  C8        		RET	Z
 863    0507  29        		ADD	HL,HL		;shift left 1 bit.
 864    0508  C30505    		JP	SHIFTL1
 865                    	;
 866                    	;   Routine to set a bit in a 16 bit value contained in (BC).
 867                    	; The bit set depends on the current drive selection.
 868                    	;
 869    050B  C5        	SETBIT:	PUSH	BC		;save 16 bit word.
 870    050C  3A4203    		LD	A,(ACTIVE)	;get active drive.
 871    050F  4F        		LD	C,A
 872    0510  210100    		LD	HL,1
 873    0513  CD0405    		CALL	SHIFTL		;shift bit 0 into place.
 874    0516  C1        		POP	BC		;now 'or' this with the original word.
 875    0517  79        		LD	A,C
 876    0518  B5        		OR	L
 877    0519  6F        		LD	L,A		;low byte done, do high byte.
 878    051A  78        		LD	A,B
 879    051B  B4        		OR	H
 880    051C  67        		LD	H,A
 881    051D  C9        		RET	
 882                    	;
 883                    	;   Extract the write protect status bit for the current drive.
 884                    	; The result is returned in (A), bit 0.
 885                    	;
 886    051E  2AAD0D    	GETWPRT:LD	HL,(WRTPRT)	;get status bytes.
 887    0521  3A4203    		LD	A,(ACTIVE)	;which drive is current?
 888    0524  4F        		LD	C,A
 889    0525  CDEA04    		CALL	SHIFTR		;shift status such that bit 0 is the
 890    0528  7D        		LD	A,L		;one of interest for this drive.
 891    0529  E601      		AND	01h		;and isolate it.
 892    052B  C9        		RET	
 893                    	;
 894                    	;   Function to write protect the current disk.
 895                    	;
 896    052C  21AD0D    	WRTPRTD:LD	HL,WRTPRT	;point to status word.
 897    052F  4E        		LD	C,(HL)		;set (BC) equal to the status.
 898    0530  23        		INC	HL
 899    0531  46        		LD	B,(HL)
 900    0532  CD0B05    		CALL	SETBIT		;and set this bit according to current drive.
 901    0535  22AD0D    		LD	(WRTPRT),HL	;then save.
 902    0538  2AC80D    		LD	HL,(DIRSIZE)	;now save directory size limit.
 903    053B  23        		INC	HL		;remember the last one.
 904    053C  EB        		EX	DE,HL
 905    053D  2AB30D    		LD	HL,(SCRATCH1)	;and store it here.
 906    0540  73        		LD	(HL),E		;put low byte.
 907    0541  23        		INC	HL
 908    0542  72        		LD	(HL),D		;then high byte.
 909    0543  C9        		RET	
 910                    	;
 911                    	;   Check for a read only file.
 912                    	;
 913    0544  CD5E05    	CHKROFL:CALL	FCB2HL		;set (HL) to file entry in directory buffer.
 914    0547  110900    	CKROF1:	LD	DE,9		;look at bit 7 of the ninth byte.
 915    054A  19        		ADD	HL,DE
 916    054B  7E        		LD	A,(HL)
 917    054C  17        		RLA	
 918    054D  D0        		RET	NC		;return if ok.
 919    054E  210F00    		LD	HL,ROFILE	;else, print error message and terminate.
 920    0551  C34A03    		JP	JUMPHL
 921                    	;
 922                    	;   Check the write protect status of the active disk.
 923                    	;
 924    0554  CD1E05    	CHKWPRT:CALL	GETWPRT
 925    0557  C8        		RET	Z		;return if ok.
 926    0558  210D00    		LD	HL,RODISK	;else print message and terminate.
 927    055B  C34A03    		JP	JUMPHL
 928                    	;
 929                    	;   Routine to set (HL) pointing to the proper entry in the
 930                    	; directory buffer.
 931                    	;
 932    055E  2AB90D    	FCB2HL:	LD	HL,(DIRBUF)	;get address of buffer.
 933    0561  3AE90D    		LD	A,(FCBPOS)	;relative position of file.
 934                    	;
 935                    	;   Routine to add (A) to (HL).
 936                    	;
 937    0564  85        	ADDA2HL:ADD	A,L
 938    0565  6F        		LD	L,A
 939    0566  D0        		RET	NC
 940    0567  24        		INC	H		;take care of any carry.
 941    0568  C9        		RET	
 942                    	;
 943                    	;   Routine to get the 's2' byte from the fcb supplied in
 944                    	; the initial parameter specification.
 945                    	;
 946    0569  2A4303    	GETS2:	LD	HL,(PARAMS)	;get address of fcb.
 947    056C  110E00    		LD	DE,14		;relative position of 's2'.
 948    056F  19        		ADD	HL,DE
 949    0570  7E        		LD	A,(HL)		;extract this byte.
 950    0571  C9        		RET	
 951                    	;
 952                    	;   Clear the 's2' byte in the fcb.
 953                    	;
 954    0572  CD6905    	CLEARS2:CALL	GETS2		;this sets (HL) pointing to it.
 955    0575  3600      		LD	(HL),0		;now clear it.
 956    0577  C9        		RET	
 957                    	;
 958                    	;   Set bit 7 in the 's2' byte of the fcb.
 959                    	;
 960    0578  CD6905    	SETS2B7:CALL	GETS2		;get the byte.
 961    057B  F680      		OR	80h		;and set bit 7.
 962    057D  77        		LD	(HL),A		;then store.
 963    057E  C9        		RET	
 964                    	;
 965                    	;   Compare (FILEPOS) with (SCRATCH1) and set flags based on
 966                    	; the difference. This checks to see if there are more file
 967                    	; names in the directory. We are at (FILEPOS) and there are
 968                    	; (SCRATCH1) of them to check.
 969                    	;
 970    057F  2AEA0D    	MOREFLS:LD	HL,(FILEPOS)	;we are here.
 971    0582  EB        		EX	DE,HL
 972    0583  2AB30D    		LD	HL,(SCRATCH1)	;and don't go past here.
 973    0586  7B        		LD	A,E		;compute difference but don't keep.
 974    0587  96        		SUB	(HL)
 975    0588  23        		INC	HL
 976    0589  7A        		LD	A,D
 977    058A  9E        		SBC	A,(HL)		;set carry if no more names.
 978    058B  C9        		RET	
 979                    	;
 980                    	;   Call this routine to prevent (SCRATCH1) from being greater
 981                    	; than (FILEPOS).
 982                    	;
 983    058C  CD7F05    	CHKNMBR:CALL	MOREFLS		;SCRATCH1 too big?
 984    058F  D8        		RET	C
 985    0590  13        		INC	DE		;yes, reset it to (FILEPOS).
 986    0591  72        		LD	(HL),D
 987    0592  2B        		DEC	HL
 988    0593  73        		LD	(HL),E
 989    0594  C9        		RET	
 990                    	;
 991                    	;   Compute (HL)=(DE)-(HL)
 992                    	;
 993    0595  7B        	SUBHL:	LD	A,E		;compute difference.
 994    0596  95        		SUB	L
 995    0597  6F        		LD	L,A		;store low byte.
 996    0598  7A        		LD	A,D
 997    0599  9C        		SBC	A,H
 998    059A  67        		LD	H,A		;and then high byte.
 999    059B  C9        		RET	
1000                    	;
1001                    	;   Set the directory checksum byte.
1002                    	;
1003    059C  0EFF      	SETDIR:	LD	C,0FFh
1004                    	;
1005                    	;   Routine to set or compare the directory checksum byte. If
1006                    	; (C)=0ffh, then this will set the checksum byte. Else the byte
1007                    	; will be checked. If the check fails (the disk has been changed),
1008                    	; then this disk will be write protected.
1009                    	;
1010    059E  2AEC0D    	CHECKDIR: LD	HL,(CKSUMTBL)
1011    05A1  EB        		EX	DE,HL
1012    05A2  2ACC0D    		LD	HL,(ALLOC1)
1013    05A5  CD9505    		CALL	SUBHL
1014    05A8  D0        		RET	NC		;ok if (CKSUMTBL) > (ALLOC1), so return.
1015    05A9  C5        		PUSH	BC
1016    05AA  CDF704    		CALL	CHECKSUM	;else compute checksum.
1017    05AD  2ABD0D    		LD	HL,(CHKVECT)	;get address of checksum table.
1018    05B0  EB        		EX	DE,HL
1019    05B1  2AEC0D    		LD	HL,(CKSUMTBL)
1020    05B4  19        		ADD	HL,DE		;set (HL) to point to byte for this drive.
1021    05B5  C1        		POP	BC
1022    05B6  0C        		INC	C		;set or check ?
1023    05B7  CAC405    		JP	Z,CHKDIR1
1024    05BA  BE        		CP	(HL)		;check them.
1025    05BB  C8        		RET	Z		;return if they are the same.
1026    05BC  CD7F05    		CALL	MOREFLS		;not the same, do we care?
1027    05BF  D0        		RET	NC
1028    05C0  CD2C05    		CALL	WRTPRTD		;yes, mark this as write protected.
1029    05C3  C9        		RET	
1030    05C4  77        	CHKDIR1:LD	(HL),A		;just set the byte.
1031    05C5  C9        		RET	
1032                    	;
1033                    	;   Do a write to the directory of the current disk.
1034                    	;
1035    05C6  CD9C05    	DIRWRITE: CALL	SETDIR		;set checksum byte.
1036    05C9  CDE005    		CALL	DIRDMA		;set directory dma address.
1037    05CC  0E01      		LD	C,1		;tell the bios to actually write.
1038    05CE  CDB803    		CALL	DOWRITE		;then do the write.
1039    05D1  C3DA05    		JP	DEFDMA
1040                    	;
1041                    	;   Read from the directory.
1042                    	;
1043    05D4  CDE005    	DIRREAD:CALL	DIRDMA		;set the directory dma address.
1044    05D7  CDB203    		CALL	DOREAD		;and read it.
1045                    	;
1046                    	;   Routine to set the dma address to the users choice.
1047                    	;
1048    05DA  21B10D    	DEFDMA:	LD	HL,USERDMA	;reset the default dma address and return.
1049    05DD  C3E305    		JP	DIRDMA1
1050                    	;
1051                    	;   Routine to set the dma address for directory work.
1052                    	;
1053    05E0  21B90D    	DIRDMA:	LD	HL,DIRBUF
1054                    	;
1055                    	;   Set the dma address. On entry, (HL) points to
1056                    	; word containing the desired dma address.
1057                    	;
1058    05E3  4E        	DIRDMA1:LD	C,(HL)
1059    05E4  23        		INC	HL
1060    05E5  46        		LD	B,(HL)		;setup (BC) and go to the bios to set it.
1061    05E6  C30000    		JP	SETDMA
1062                    	;
1063                    	;   Move the directory buffer into user's dma space.
1064                    	;
1065    05E9  2AB90D    	MOVEDIR:LD	HL,(DIRBUF)	;buffer is located here, and
1066    05EC  EB        		EX	DE,HL
1067    05ED  2AB10D    		LD	HL,(USERDMA)	; put it here.
1068    05F0  0E80      		LD	C,128		;this is its length.
1069    05F2  C34F03    		JP	DE2HL		;move it now and return.
1070                    	;
1071                    	;   Check (FILEPOS) and set the zero flag if it equals 0ffffh.
1072                    	;
1073    05F5  21EA0D    	CKFILPOS: LD	HL,FILEPOS
1074    05F8  7E        		LD	A,(HL)
1075    05F9  23        		INC	HL
1076    05FA  BE        		CP	(HL)		;are both bytes the same?
1077    05FB  C0        		RET	NZ
1078    05FC  3C        		INC	A		;yes, but are they each 0ffh?
1079    05FD  C9        		RET	
1080                    	;
1081                    	;   Set location (FILEPOS) to 0ffffh.
1082                    	;
1083    05FE  21FFFF    	STFILPOS: LD	HL,0FFFFh
1084    0601  22EA0D    		LD	(FILEPOS),HL
1085    0604  C9        		RET	
1086                    	;
1087                    	;   Move on to the next file position within the current
1088                    	; directory buffer. If no more exist, set pointer to 0ffffh
1089                    	; and the calling routine will check for this. Enter with (C)
1090                    	; equal to 0ffh to cause the checksum byte to be set, else we
1091                    	; will check this disk and set write protect if checksums are
1092                    	; not the same (applies only if another directory sector must
1093                    	; be read).
1094                    	;
1095    0605  2AC80D    	NXENTRY:LD	HL,(DIRSIZE)	;get directory entry size limit.
1096    0608  EB        		EX	DE,HL
1097    0609  2AEA0D    		LD	HL,(FILEPOS)	;get current count.
1098    060C  23        		INC	HL		;go on to the next one.
1099    060D  22EA0D    		LD	(FILEPOS),HL
1100    0610  CD9505    		CALL	SUBHL		;(HL)=(DIRSIZE)-(FILEPOS)
1101    0613  D21906    		JP	NC,NXENT1	;is there more room left?
1102    0616  C3FE05    		JP	STFILPOS	;no. Set this flag and return.
1103    0619  3AEA0D    	NXENT1:	LD	A,(FILEPOS)	;get file position within directory.
1104    061C  E603      		AND	03h		;only look within this sector (only 4 entries fit).
1105    061E  0605      		LD	B,5		;convert to relative position (32 bytes each).
1106    0620  87        	NXENT2:	ADD	A,A		;note that this is not efficient code.
1107    0621  05        		DEC	B		;5 'ADD A's would be better.
1108    0622  C22006    		JP	NZ,NXENT2
1109    0625  32E90D    		LD	(FCBPOS),A	;save it as position of fcb.
1110    0628  B7        		OR	A
1111    0629  C0        		RET	NZ		;return if we are within buffer.
1112    062A  C5        		PUSH	BC
1113    062B  CDC303    		CALL	TRKSEC		;we need the next directory sector.
1114    062E  CDD405    		CALL	DIRREAD
1115    0631  C1        		POP	BC
1116    0632  C39E05    		JP	CHECKDIR
1117                    	;
1118                    	;   Routine to to get a bit from the disk space allocation
1119                    	; map. It is returned in (A), bit position 0. On entry to here,
1120                    	; set (BC) to the block number on the disk to check.
1121                    	; On return, (D) will contain the original bit position for
1122                    	; this block number and (HL) will point to the address for it.
1123                    	;
1124    0635  79        	CKBITMAP: LD	A,C		;determine bit number of interest.
1125    0636  E607      		AND	07h		;compute (D)=(E)=(C and 7)+1.
1126    0638  3C        		INC	A
1127    0639  5F        		LD	E,A		;save particular bit number.
1128    063A  57        		LD	D,A
1129                    	;
1130                    	;   compute (BC)=(BC)/8.
1131                    	;
1132    063B  79        		LD	A,C
1133    063C  0F        		RRCA			;now shift right 3 bits.
1134    063D  0F        		RRCA	
1135    063E  0F        		RRCA	
1136    063F  E61F      		AND	1Fh		;and clear bits 7,6,5.
1137    0641  4F        		LD	C,A
1138    0642  78        		LD	A,B
1139    0643  87        		ADD	A,A		;now shift (B) into bits 7,6,5.
1140    0644  87        		ADD	A,A
1141    0645  87        		ADD	A,A
1142    0646  87        		ADD	A,A
1143    0647  87        		ADD	A,A
1144    0648  B1        		OR	C		;and add in (C).
1145    0649  4F        		LD	C,A		;ok, (C) ha been completed.
1146    064A  78        		LD	A,B		;is there a better way of doing this?
1147    064B  0F        		RRCA	
1148    064C  0F        		RRCA	
1149    064D  0F        		RRCA	
1150    064E  E61F      		AND	1Fh
1151    0650  47        		LD	B,A		;and now (B) is completed.
1152                    	;
1153                    	;   use this as an offset into the disk space allocation
1154                    	; table.
1155                    	;
1156    0651  2ABF0D    		LD	HL,(ALOCVECT)
1157    0654  09        		ADD	HL,BC
1158    0655  7E        		LD	A,(HL)		;now get correct byte.
1159    0656  07        	CKBMAP1:RLCA			;get correct bit into position 0.
1160    0657  1D        		DEC	E
1161    0658  C25606    		JP	NZ,CKBMAP1
1162    065B  C9        		RET	
1163                    	;
1164                    	;   Set or clear the bit map such that block number (BC) will be marked
1165                    	; as used. On entry, if (E)=0 then this bit will be cleared, if it equals
1166                    	; 1 then it will be set (don't use anyother values).
1167                    	;
1168    065C  D5        	STBITMAP: PUSH	DE
1169    065D  CD3506    		CALL	CKBITMAP	;get the byte of interest.
1170    0660  E6FE      		AND	0FEh		;clear the affected bit.
1171    0662  C1        		POP	BC
1172    0663  B1        		OR	C		;and now set it acording to (C).
1173                    	;
1174                    	;  entry to restore the original bit position and then store
1175                    	; in table. (A) contains the value, (D) contains the bit
1176                    	; position (1-8), and (HL) points to the address within the
1177                    	; space allocation table for this byte.
1178                    	;
1179    0664  0F        	STBMAP1:RRCA			;restore original bit position.
1180    0665  15        		DEC	D
1181    0666  C26406    		JP	NZ,STBMAP1
1182    0669  77        		LD	(HL),A		;and stor byte in table.
1183    066A  C9        		RET	
1184                    	;
1185                    	;   Set/clear space used bits in allocation map for this file.
1186                    	; On entry, (C)=1 to set the map and (C)=0 to clear it.
1187                    	;
1188    066B  CD5E05    	SETFILE:CALL	FCB2HL		;get address of fcb
1189    066E  111000    		LD	DE,16
1190    0671  19        		ADD	HL,DE		;get to block number bytes.
1191    0672  C5        		PUSH	BC
1192    0673  0E11      		LD	C,17		;check all 17 bytes (max) of table.
1193    0675  D1        	SETFL1:	POP	DE
1194    0676  0D        		DEC	C		;done all bytes yet?
1195    0677  C8        		RET	Z
1196    0678  D5        		PUSH	DE
1197    0679  3ADD0D    		LD	A,(BIGDISK)	;check disk size for 16 bit block numbers.
1198    067C  B7        		OR	A
1199    067D  CA8806    		JP	Z,SETFL2
1200    0680  C5        		PUSH	BC		;only 8 bit numbers. set (BC) to this one.
1201    0681  E5        		PUSH	HL
1202    0682  4E        		LD	C,(HL)		;get low byte from table, always
1203    0683  0600      		LD	B,0		;set high byte to zero.
1204    0685  C38E06    		JP	SETFL3
1205    0688  0D        	SETFL2:	DEC	C		;for 16 bit block numbers, adjust counter.
1206    0689  C5        		PUSH	BC
1207    068A  4E        		LD	C,(HL)		;now get both the low and high bytes.
1208    068B  23        		INC	HL
1209    068C  46        		LD	B,(HL)
1210    068D  E5        		PUSH	HL
1211    068E  79        	SETFL3:	LD	A,C		;block used?
1212    068F  B0        		OR	B
1213    0690  CA9D06    		JP	Z,SETFL4
1214    0693  2AC60D    		LD	HL,(DSKSIZE)	;is this block number within the
1215    0696  7D        		LD	A,L		;space on the disk?
1216    0697  91        		SUB	C
1217    0698  7C        		LD	A,H
1218    0699  98        		SBC	A,B
1219    069A  D45C06    		CALL	NC,STBITMAP	;yes, set the proper bit.
1220    069D  E1        	SETFL4:	POP	HL		;point to next block number in fcb.
1221    069E  23        		INC	HL
1222    069F  C1        		POP	BC
1223    06A0  C37506    		JP	SETFL1
1224                    	;
1225                    	;   Construct the space used allocation bit map for the active
1226                    	; drive. If a file name starts with '$' and it is under the
1227                    	; current user number, then (STATUS) is set to minus 1. Otherwise
1228                    	; it is not set at all.
1229                    	;
1230    06A3  2AC60D    	BITMAP:	LD	HL,(DSKSIZE)	;compute size of allocation table.
1231    06A6  0E03      		LD	C,3
1232    06A8  CDEA04    		CALL	SHIFTR		;(HL)=(HL)/8.
1233    06AB  23        		INC	HL		;at lease 1 byte.
1234    06AC  44        		LD	B,H
1235    06AD  4D        		LD	C,L		;set (BC) to the allocation table length.
1236                    	;
1237                    	;   Initialize the bitmap for this drive. Right now, the first
1238                    	; two bytes are specified by the disk parameter block. However
1239                    	; a patch could be entered here if it were necessary to setup
1240                    	; this table in a special mannor. For example, the bios could
1241                    	; determine locations of 'bad blocks' and set them as already
1242                    	; 'used' in the map.
1243                    	;
1244    06AE  2ABF0D    		LD	HL,(ALOCVECT)	;now zero out the table now.
1245    06B1  3600      	BITMAP1:LD	(HL),0
1246    06B3  23        		INC	HL
1247    06B4  0B        		DEC	BC
1248    06B5  78        		LD	A,B
1249    06B6  B1        		OR	C
1250                    	;    PRTPROB 'F'
1251    06B7  C2B106    		JP	NZ,BITMAP1
1252    06BA  2ACA0D    		LD	HL,(ALLOC0)	;get initial space used by directory.
1253    06BD  EB        		EX	DE,HL
1254    06BE  2ABF0D    		LD	HL,(ALOCVECT)	;and put this into map.
1255    06C1  73        		LD	(HL),E
1256    06C2  23        		INC	HL
1257    06C3  72        		LD	(HL),D
1258                    	;
1259                    	;   End of initialization portion.
1260                    	;
1261                    	;    PRTPROB 'G'
1262    06C4  CDA103    		CALL	HOMEDRV		;now home the drive.
1263                    	;    PRTPROB 'H'
1264    06C7  2AB30D    		LD	HL,(SCRATCH1)
1265    06CA  3603      		LD	(HL),3		;force next directory request to read
1266    06CC  23        		INC	HL		;in a sector.
1267    06CD  3600      		LD	(HL),0
1268    06CF  CDFE05    		CALL	STFILPOS	;clear initial file position also.
1269    06D2  0EFF      	BITMAP2:LD	C,0FFh		;read next file name in directory
1270    06D4  CD0506    		CALL	NXENTRY		;and set checksum byte.
1271    06D7  CDF505    		CALL	CKFILPOS	;is there another file?
1272                    	;    PRTPROB 'I'
1273    06DA  C8        		RET	Z
1274    06DB  CD5E05    		CALL	FCB2HL		;yes, get its address.
1275    06DE  3EE5      		LD	A,0E5h
1276    06E0  BE        		CP	(HL)		;empty file entry?
1277    06E1  CAD206    		JP	Z,BITMAP2
1278    06E4  3A4103    		LD	A,(USERNO)	;no, correct user number?
1279    06E7  BE        		CP	(HL)
1280    06E8  C2F606    		JP	NZ,BITMAP3
1281    06EB  23        		INC	HL
1282    06EC  7E        		LD	A,(HL)		;yes, does name start with a '$'?
1283    06ED  D624      		SUB	'$'
1284    06EF  C2F606    		JP	NZ,BITMAP3
1285    06F2  3D        		DEC	A		;yes, set atatus to minus one.
1286    06F3  324503    		LD	(STATUS),A
1287    06F6  0E01      	BITMAP3:LD	C,1		;now set this file's space as used in bit map.
1288    06F8  CD6B06    		CALL	SETFILE
1289    06FB  CD8C05    		CALL	CHKNMBR		;keep (SCRATCH1) in bounds.
1290    06FE  C3D206    		JP	BITMAP2
1291                    	;
1292                    	;   Set the status (STATUS) and return.
1293                    	;
1294    0701  3AD40D    	STSTATUS: LD	A,(FNDSTAT)
1295    0704  C30103    		JP	SETSTAT
1296                    	;
1297                    	;   Check extents in (A) and (C). Set the zero flag if they
1298                    	; are the same. The number of 16k chunks of disk space that
1299                    	; the directory extent covers is expressad is (EXTMASK+1).
1300                    	; No registers are modified.
1301                    	;
1302    0707  C5        	SAMEXT:	PUSH	BC
1303    0708  F5        		PUSH	AF
1304    0709  3AC50D    		LD	A,(EXTMASK)	;get extent mask and use it to
1305    070C  2F        		CPL			;to compare both extent numbers.
1306    070D  47        		LD	B,A		;save resulting mask here.
1307    070E  79        		LD	A,C		;mask first extent and save in (C).
1308    070F  A0        		AND	B
1309    0710  4F        		LD	C,A
1310    0711  F1        		POP	AF		;now mask second extent and compare
1311    0712  A0        		AND	B		;with the first one.
1312    0713  91        		SUB	C
1313    0714  E61F      		AND	1Fh		;(* only check buts 0-4 *)
1314    0716  C1        		POP	BC		;the zero flag is set if they are the same.
1315    0717  C9        		RET			;restore (BC) and return.
1316                    	;
1317                    	;   Search for the first occurence of a file name. On entry,
1318                    	; register (C) should contain the number of bytes of the fcb
1319                    	; that must match.
1320                    	;
1321    0718  3EFF      	FINDFST:LD	A,0FFh
1322    071A  32D40D    		LD	(FNDSTAT),A
1323    071D  21D80D    		LD	HL,COUNTER	;save character count.
1324    0720  71        		LD	(HL),C
1325    0721  2A4303    		LD	HL,(PARAMS)	;get filename to match.
1326    0724  22D90D    		LD	(SAVEFCB),HL	;and save.
1327    0727  CDFE05    		CALL	STFILPOS	;clear initial file position (set to 0ffffh).
1328    072A  CDA103    		CALL	HOMEDRV		;home the drive.
1329                    	;
1330                    	;   Entry to locate the next occurence of a filename within the
1331                    	; directory. The disk is not expected to have been changed. If
1332                    	; it was, then it will be write protected.
1333                    	;
1334    072D  0E00      	FINDNXT:LD	C,0		;write protect the disk if changed.
1335    072F  CD0506    		CALL	NXENTRY		;get next filename entry in directory.
1336    0732  CDF505    		CALL	CKFILPOS	;is file position = 0ffffh?
1337    0735  CA9407    		JP	Z,FNDNXT6	;yes, exit now then.
1338    0738  2AD90D    		LD	HL,(SAVEFCB)	;set (DE) pointing to filename to match.
1339    073B  EB        		EX	DE,HL
1340    073C  1A        		LD	A,(DE)
1341    073D  FEE5      		CP	0E5h		;empty directory entry?
1342    073F  CA4A07    		JP	Z,FNDNXT1	;(* are we trying to reserect erased entries? *)
1343    0742  D5        		PUSH	DE
1344    0743  CD7F05    		CALL	MOREFLS		;more files in directory?
1345    0746  D1        		POP	DE
1346    0747  D29407    		JP	NC,FNDNXT6	;no more. Exit now.
1347    074A  CD5E05    	FNDNXT1:CALL	FCB2HL		;get address of this fcb in directory.
1348    074D  3AD80D    		LD	A,(COUNTER)	;get number of bytes (characters) to check.
1349    0750  4F        		LD	C,A
1350    0751  0600      		LD	B,0		;initialize byte position counter.
1351    0753  79        	FNDNXT2:LD	A,C		;are we done with the compare?
1352    0754  B7        		OR	A
1353    0755  CA8307    		JP	Z,FNDNXT5
1354    0758  1A        		LD	A,(DE)		;no, check next byte.
1355    0759  FE3F      		CP	'?'		;don't care about this character?
1356    075B  CA7C07    		JP	Z,FNDNXT4
1357    075E  78        		LD	A,B		;get bytes position in fcb.
1358    075F  FE0D      		CP	13		;don't care about the thirteenth byte either.
1359    0761  CA7C07    		JP	Z,FNDNXT4
1360    0764  FE0C      		CP	12		;extent byte?
1361    0766  1A        		LD	A,(DE)
1362    0767  CA7307    		JP	Z,FNDNXT3
1363    076A  96        		SUB	(HL)		;otherwise compare characters.
1364    076B  E67F      		AND	7Fh
1365    076D  C22D07    		JP	NZ,FINDNXT	;not the same, check next entry.
1366    0770  C37C07    		JP	FNDNXT4		;so far so good, keep checking.
1367    0773  C5        	FNDNXT3:PUSH	BC		;check the extent byte here.
1368    0774  4E        		LD	C,(HL)
1369    0775  CD0707    		CALL	SAMEXT
1370    0778  C1        		POP	BC
1371    0779  C22D07    		JP	NZ,FINDNXT	;not the same, look some more.
1372                    	;
1373                    	;   So far the names compare. Bump pointers to the next byte
1374                    	; and continue until all (C) characters have been checked.
1375                    	;
1376    077C  13        	FNDNXT4:INC	DE		;bump pointers.
1377    077D  23        		INC	HL
1378    077E  04        		INC	B
1379    077F  0D        		DEC	C		;adjust character counter.
1380    0780  C35307    		JP	FNDNXT2
1381    0783  3AEA0D    	FNDNXT5:LD	A,(FILEPOS)	;return the position of this entry.
1382    0786  E603      		AND	03h
1383    0788  324503    		LD	(STATUS),A
1384    078B  21D40D    		LD	HL,FNDSTAT
1385    078E  7E        		LD	A,(HL)
1386    078F  17        		RLA	
1387    0790  D0        		RET	NC
1388    0791  AF        		XOR	A
1389    0792  77        		LD	(HL),A
1390    0793  C9        		RET	
1391                    	;
1392                    	;   Filename was not found. Set appropriate status.
1393                    	;
1394    0794  CDFE05    	FNDNXT6:CALL	STFILPOS	;set (FILEPOS) to 0ffffh.
1395    0797  3EFF      		LD	A,0FFh		;say not located.
1396    0799  C30103    		JP	SETSTAT
1397                    	;
1398                    	;   Erase files from the directory. Only the first byte of the
1399                    	; fcb will be affected. It is set to (E5).
1400                    	;
1401    079C  CD5405    	ERAFILE:CALL	CHKWPRT		;is disk write protected?
1402    079F  0E0C      		LD	C,12		;only compare file names.
1403    07A1  CD1807    		CALL	FINDFST		;get first file name.
1404    07A4  CDF505    	ERAFIL1:CALL	CKFILPOS	;any found?
1405    07A7  C8        		RET	Z		;nope, we must be done.
1406    07A8  CD4405    		CALL	CHKROFL		;is file read only?
1407    07AB  CD5E05    		CALL	FCB2HL		;nope, get address of fcb and
1408    07AE  36E5      		LD	(HL),0E5h	;set first byte to 'empty'.
1409    07B0  0E00      		LD	C,0		;clear the space from the bit map.
1410    07B2  CD6B06    		CALL	SETFILE
1411    07B5  CDC605    		CALL	DIRWRITE	;now write the directory sector back out.
1412    07B8  CD2D07    		CALL	FINDNXT		;find the next file name.
1413    07BB  C3A407    		JP	ERAFIL1		;and repeat process.
1414                    	;
1415                    	;   Look through the space allocation map (bit map) for the
1416                    	; next available block. Start searching at block number (BC-1).
1417                    	; The search procedure is to look for an empty block that is
1418                    	; before the starting block. If not empty, look at a later
1419                    	; block number. In this way, we return the closest empty block
1420                    	; on either side of the 'target' block number. This will speed
1421                    	; access on random devices. For serial devices, this should be
1422                    	; changed to look in the forward direction first and then start
1423                    	; at the front and search some more.
1424                    	;
1425                    	;   On return, (DE)= block number that is empty and (HL) =0
1426                    	; if no empry block was found.
1427                    	;
1428    07BE  50        	FNDSPACE: LD	D,B		;set (DE) as the block that is checked.
1429    07BF  59        		LD	E,C
1430                    	;
1431                    	;   Look before target block. Registers (BC) are used as the lower
1432                    	; pointer and (DE) as the upper pointer.
1433                    	;
1434    07C0  79        	FNDSPA1:LD	A,C		;is block 0 specified?
1435    07C1  B0        		OR	B
1436    07C2  CAD107    		JP	Z,FNDSPA2
1437    07C5  0B        		DEC	BC		;nope, check previous block.
1438    07C6  D5        		PUSH	DE
1439    07C7  C5        		PUSH	BC
1440    07C8  CD3506    		CALL	CKBITMAP
1441    07CB  1F        		RRA			;is this block empty?
1442    07CC  D2EC07    		JP	NC,FNDSPA3	;yes. use this.
1443                    	;
1444                    	;   Note that the above logic gets the first block that it finds
1445                    	; that is empty. Thus a file could be written 'backward' making
1446                    	; it very slow to access. This could be changed to look for the
1447                    	; first empty block and then continue until the start of this
1448                    	; empty space is located and then used that starting block.
1449                    	; This should help speed up access to some files especially on
1450                    	; a well used disk with lots of fairly small 'holes'.
1451                    	;
1452    07CF  C1        		POP	BC		;nope, check some more.
1453    07D0  D1        		POP	DE
1454                    	;
1455                    	;   Now look after target block.
1456                    	;
1457    07D1  2AC60D    	FNDSPA2:LD	HL,(DSKSIZE)	;is block (DE) within disk limits?
1458    07D4  7B        		LD	A,E
1459    07D5  95        		SUB	L
1460    07D6  7A        		LD	A,D
1461    07D7  9C        		SBC	A,H
1462    07D8  D2F407    		JP	NC,FNDSPA4
1463    07DB  13        		INC	DE		;yes, move on to next one.
1464    07DC  C5        		PUSH	BC
1465    07DD  D5        		PUSH	DE
1466    07DE  42        		LD	B,D
1467    07DF  4B        		LD	C,E
1468    07E0  CD3506    		CALL	CKBITMAP	;check it.
1469    07E3  1F        		RRA			;empty?
1470    07E4  D2EC07    		JP	NC,FNDSPA3
1471    07E7  D1        		POP	DE		;nope, continue searching.
1472    07E8  C1        		POP	BC
1473    07E9  C3C007    		JP	FNDSPA1
1474                    	;
1475                    	;   Empty block found. Set it as used and return with (HL)
1476                    	; pointing to it (true?).
1477                    	;
1478    07EC  17        	FNDSPA3:RLA			;reset byte.
1479    07ED  3C        		INC	A		;and set bit 0.
1480    07EE  CD6406    		CALL	STBMAP1		;update bit map.
1481    07F1  E1        		POP	HL		;set return registers.
1482    07F2  D1        		POP	DE
1483    07F3  C9        		RET	
1484                    	;
1485                    	;   Free block was not found. If (BC) is not zero, then we have
1486                    	; not checked all of the disk space.
1487                    	;
1488    07F4  79        	FNDSPA4:LD	A,C
1489    07F5  B0        		OR	B
1490    07F6  C2C007    		JP	NZ,FNDSPA1
1491    07F9  210000    		LD	HL,0		;set 'not found' status.
1492    07FC  C9        		RET	
1493                    	;
1494                    	;   Move a complete fcb entry into the directory and write it.
1495                    	;
1496    07FD  0E00      	FCBSET:	LD	C,0
1497    07FF  1E20      		LD	E,32		;length of each entry.
1498                    	;
1499                    	;   Move (E) bytes from the fcb pointed to by (PARAMS) into
1500                    	; fcb in directory starting at relative byte (C). This updated
1501                    	; directory buffer is then written to the disk.
1502                    	;
1503    0801  D5        	UPDATE:	PUSH	DE
1504    0802  0600      		LD	B,0		;set (BC) to relative byte position.
1505    0804  2A4303    		LD	HL,(PARAMS)	;get address of fcb.
1506    0807  09        		ADD	HL,BC		;compute starting byte.
1507    0808  EB        		EX	DE,HL
1508    0809  CD5E05    		CALL	FCB2HL		;get address of fcb to update in directory.
1509    080C  C1        		POP	BC		;set (C) to number of bytes to change.
1510    080D  CD4F03    		CALL	DE2HL
1511    0810  CDC303    	UPDATE1:CALL	TRKSEC		;determine the track and sector affected.
1512    0813  C3C605    		JP	DIRWRITE	;then write this sector out.
1513                    	;
1514                    	;   Routine to change the name of all files on the disk with a
1515                    	; specified name. The fcb contains the current name as the
1516                    	; first 12 characters and the new name 16 bytes into the fcb.
1517                    	;
1518    0816  CD5405    	CHGNAMES: CALL	CHKWPRT		;check for a write protected disk.
1519    0819  0E0C      		LD	C,12		;match first 12 bytes of fcb only.
1520    081B  CD1807    		CALL	FINDFST		;get first name.
1521    081E  2A4303    		LD	HL,(PARAMS)	;get address of fcb.
1522    0821  7E        		LD	A,(HL)		;get user number.
1523    0822  111000    		LD	DE,16		;move over to desired name.
1524    0825  19        		ADD	HL,DE
1525    0826  77        		LD	(HL),A		;keep same user number.
1526    0827  CDF505    	CHGNAM1:CALL	CKFILPOS	;any matching file found?
1527    082A  C8        		RET	Z		;no, we must be done.
1528    082B  CD4405    		CALL	CHKROFL		;check for read only file.
1529    082E  0E10      		LD	C,16		;start 16 bytes into fcb.
1530    0830  1E0C      		LD	E,12		;and update the first 12 bytes of directory.
1531    0832  CD0108    		CALL	UPDATE
1532    0835  CD2D07    		CALL	FINDNXT		;get te next file name.
1533    0838  C32708    		JP	CHGNAM1		;and continue.
1534                    	;
1535                    	;   Update a files attributes. The procedure is to search for
1536                    	; every file with the same name as shown in fcb (ignoring bit 7)
1537                    	; and then to update it (which includes bit 7). No other changes
1538                    	; are made.
1539                    	;
1540    083B  0E0C      	SAVEATTR: LD	C,12		;match first 12 bytes.
1541    083D  CD1807    		CALL	FINDFST		;look for first filename.
1542    0840  CDF505    	SAVATR1:CALL	CKFILPOS	;was one found?
1543    0843  C8        		RET	Z		;nope, we must be done.
1544    0844  0E00      		LD	C,0		;yes, update the first 12 bytes now.
1545    0846  1E0C      		LD	E,12
1546    0848  CD0108    		CALL	UPDATE		;update filename and write directory.
1547    084B  CD2D07    		CALL	FINDNXT		;and get the next file.
1548    084E  C34008    		JP	SAVATR1		;then continue until done.
1549                    	;
1550                    	;  Open a file (name specified in fcb).
1551                    	;
1552    0851  0E0F      	OPENIT:	LD	C,15		;compare the first 15 bytes.
1553    0853  CD1807    		CALL	FINDFST		;get the first one in directory.
1554    0856  CDF505    		CALL	CKFILPOS	;any at all?
1555    0859  C8        		RET	Z
1556    085A  CDA604    	OPENIT1:CALL	SETEXT		;point to extent byte within users fcb.
1557    085D  7E        		LD	A,(HL)		;and get it.
1558    085E  F5        		PUSH	AF		;save it and address.
1559    085F  E5        		PUSH	HL
1560    0860  CD5E05    		CALL	FCB2HL		;point to fcb in directory.
1561    0863  EB        		EX	DE,HL
1562    0864  2A4303    		LD	HL,(PARAMS)	;this is the users copy.
1563    0867  0E20      		LD	C,32		;move it into users space.
1564    0869  D5        		PUSH	DE
1565    086A  CD4F03    		CALL	DE2HL
1566    086D  CD7805    		CALL	SETS2B7		;set bit 7 in 's2' byte (unmodified).
1567    0870  D1        		POP	DE		;now get the extent byte from this fcb.
1568    0871  210C00    		LD	HL,12
1569    0874  19        		ADD	HL,DE
1570    0875  4E        		LD	C,(HL)		;into (C).
1571    0876  210F00    		LD	HL,15		;now get the record count byte into (B).
1572    0879  19        		ADD	HL,DE
1573    087A  46        		LD	B,(HL)
1574    087B  E1        		POP	HL		;keep the same extent as the user had originally.
1575    087C  F1        		POP	AF
1576    087D  77        		LD	(HL),A
1577    087E  79        		LD	A,C		;is it the same as in the directory fcb?
1578    087F  BE        		CP	(HL)
1579    0880  78        		LD	A,B		;if yes, then use the same record count.
1580    0881  CA8B08    		JP	Z,OPENIT2
1581    0884  3E00      		LD	A,0		;if the user specified an extent greater than
1582    0886  DA8B08    		JP	C,OPENIT2	;the one in the directory, then set record count to 0.
1583    0889  3E80      		LD	A,128		;otherwise set to maximum.
1584    088B  2A4303    	OPENIT2:LD	HL,(PARAMS)	;set record count in users fcb to (A).
1585    088E  110F00    		LD	DE,15
1586    0891  19        		ADD	HL,DE		;compute relative position.
1587    0892  77        		LD	(HL),A		;and set the record count.
1588    0893  C9        		RET	
1589                    	;
1590                    	;   Move two bytes from (DE) to (HL) if (and only if) (HL)
1591                    	; point to a zero value (16 bit).
1592                    	;   Return with zero flag set it (DE) was moved. Registers (DE)
1593                    	; and (HL) are not changed. However (A) is.
1594                    	;
1595    0894  7E        	MOVEWORD: LD	A,(HL)		;check for a zero word.
1596    0895  23        		INC	HL
1597    0896  B6        		OR	(HL)		;both bytes zero?
1598    0897  2B        		DEC	HL
1599    0898  C0        		RET	NZ		;nope, just return.
1600    0899  1A        		LD	A,(DE)		;yes, move two bytes from (DE) into
1601    089A  77        		LD	(HL),A		;this zero space.
1602    089B  13        		INC	DE
1603    089C  23        		INC	HL
1604    089D  1A        		LD	A,(DE)
1605    089E  77        		LD	(HL),A
1606    089F  1B        		DEC	DE		;don't disturb these registers.
1607    08A0  2B        		DEC	HL
1608    08A1  C9        		RET	
1609                    	;
1610                    	;   Get here to close a file specified by (fcb).
1611                    	;
1612    08A2  AF        	CLOSEIT:XOR	A		;clear status and file position bytes.
1613    08A3  324503    		LD	(STATUS),A
1614    08A6  32EA0D    		LD	(FILEPOS),A
1615    08A9  32EB0D    		LD	(FILEPOS+1),A
1616    08AC  CD1E05    		CALL	GETWPRT		;get write protect bit for this drive.
1617    08AF  C0        		RET	NZ		;just return if it is set.
1618    08B0  CD6905    		CALL	GETS2		;else get the 's2' byte.
1619    08B3  E680      		AND	80h		;and look at bit 7 (file unmodified?).
1620    08B5  C0        		RET	NZ		;just return if set.
1621    08B6  0E0F      		LD	C,15		;else look up this file in directory.
1622    08B8  CD1807    		CALL	FINDFST
1623    08BB  CDF505    		CALL	CKFILPOS	;was it found?
1624    08BE  C8        		RET	Z		;just return if not.
1625    08BF  011000    		LD	BC,16		;set (HL) pointing to records used section.
1626    08C2  CD5E05    		CALL	FCB2HL
1627    08C5  09        		ADD	HL,BC
1628    08C6  EB        		EX	DE,HL
1629    08C7  2A4303    		LD	HL,(PARAMS)	;do the same for users specified fcb.
1630    08CA  09        		ADD	HL,BC
1631    08CB  0E10      		LD	C,16		;this many bytes are present in this extent.
1632    08CD  3ADD0D    	CLOSEIT1: LD	A,(BIGDISK)	;8 or 16 bit record numbers?
1633    08D0  B7        		OR	A
1634    08D1  CAE808    		JP	Z,CLOSEIT4
1635    08D4  7E        		LD	A,(HL)		;just 8 bit. Get one from users fcb.
1636    08D5  B7        		OR	A
1637    08D6  1A        		LD	A,(DE)		;now get one from directory fcb.
1638    08D7  C2DB08    		JP	NZ,CLOSEIT2
1639    08DA  77        		LD	(HL),A		;users byte was zero. Update from directory.
1640    08DB  B7        	CLOSEIT2: OR	A
1641    08DC  C2E108    		JP	NZ,CLOSEIT3
1642    08DF  7E        		LD	A,(HL)		;directories byte was zero, update from users fcb.
1643    08E0  12        		LD	(DE),A
1644    08E1  BE        	CLOSEIT3: CP	(HL)		;if neither one of these bytes were zero,
1645    08E2  C21F09    		JP	NZ,CLOSEIT7	;then close error if they are not the same.
1646    08E5  C3FD08    		JP	CLOSEIT5	;ok so far, get to next byte in fcbs.
1647    08E8  CD9408    	CLOSEIT4: CALL	MOVEWORD	;update users fcb if it is zero.
1648    08EB  EB        		EX	DE,HL
1649    08EC  CD9408    		CALL	MOVEWORD	;update directories fcb if it is zero.
1650    08EF  EB        		EX	DE,HL
1651    08F0  1A        		LD	A,(DE)		;if these two values are no different,
1652    08F1  BE        		CP	(HL)		;then a close error occured.
1653    08F2  C21F09    		JP	NZ,CLOSEIT7
1654    08F5  13        		INC	DE		;check second byte.
1655    08F6  23        		INC	HL
1656    08F7  1A        		LD	A,(DE)
1657    08F8  BE        		CP	(HL)
1658    08F9  C21F09    		JP	NZ,CLOSEIT7
1659    08FC  0D        		DEC	C		;remember 16 bit values.
1660    08FD  13        	CLOSEIT5: INC	DE		;bump to next item in table.
1661    08FE  23        		INC	HL
1662    08FF  0D        		DEC	C		;there are 16 entries only.
1663    0900  C2CD08    		JP	NZ,CLOSEIT1	;continue if more to do.
1664    0903  01ECFF    		LD	BC,0FFECh	;backup 20 places (extent byte).
1665    0906  09        		ADD	HL,BC
1666    0907  EB        		EX	DE,HL
1667    0908  09        		ADD	HL,BC
1668    0909  1A        		LD	A,(DE)
1669    090A  BE        		CP	(HL)		;directory's extent already greater than the
1670    090B  DA1709    		JP	C,CLOSEIT6	;users extent?
1671    090E  77        		LD	(HL),A		;no, update directory extent.
1672    090F  010300    		LD	BC,3		;and update the record count byte in
1673    0912  09        		ADD	HL,BC		;directories fcb.
1674    0913  EB        		EX	DE,HL
1675    0914  09        		ADD	HL,BC
1676    0915  7E        		LD	A,(HL)		;get from user.
1677    0916  12        		LD	(DE),A		;and put in directory.
1678    0917  3EFF      	CLOSEIT6: LD	A,0FFh		;set 'was open and is now closed' byte.
1679    0919  32D20D    		LD	(CLOSEFLG),A
1680    091C  C31008    		JP	UPDATE1		;update the directory now.
1681    091F  214503    	CLOSEIT7: LD	HL,STATUS	;set return status and then return.
1682    0922  35        		DEC	(HL)
1683    0923  C9        		RET	
1684                    	;
1685                    	;   Routine to get the next empty space in the directory. It
1686                    	; will then be cleared for use.
1687                    	;
1688    0924  CD5405    	GETEMPTY: CALL	CHKWPRT		;make sure disk is not write protected.
1689    0927  2A4303    		LD	HL,(PARAMS)	;save current parameters (fcb).
1690    092A  E5        		PUSH	HL
1691    092B  21AC0D    		LD	HL,EMPTYFCB	;use special one for empty space.
1692    092E  224303    		LD	(PARAMS),HL
1693    0931  0E01      		LD	C,1		;search for first empty spot in directory.
1694    0933  CD1807    		CALL	FINDFST		;(* only check first byte *)
1695    0936  CDF505    		CALL	CKFILPOS	;none?
1696    0939  E1        		POP	HL
1697    093A  224303    		LD	(PARAMS),HL	;restore original fcb address.
1698    093D  C8        		RET	Z		;return if no more space.
1699    093E  EB        		EX	DE,HL
1700    093F  210F00    		LD	HL,15		;point to number of records for this file.
1701    0942  19        		ADD	HL,DE
1702    0943  0E11      		LD	C,17		;and clear all of this space.
1703    0945  AF        		XOR	A
1704    0946  77        	GETMT1:	LD	(HL),A
1705    0947  23        		INC	HL
1706    0948  0D        		DEC	C
1707    0949  C24609    		JP	NZ,GETMT1
1708    094C  210D00    		LD	HL,13		;clear the 's1' byte also.
1709    094F  19        		ADD	HL,DE
1710    0950  77        		LD	(HL),A
1711    0951  CD8C05    		CALL	CHKNMBR		;keep (SCRATCH1) within bounds.
1712    0954  CDFD07    		CALL	FCBSET		;write out this fcb entry to directory.
1713    0957  C37805    		JP	SETS2B7		;set 's2' byte bit 7 (unmodified at present).
1714                    	;
1715                    	;   Routine to close the current extent and open the next one
1716                    	; for reading.
1717                    	;
1718    095A  AF        	GETNEXT:XOR	A
1719    095B  32D20D    		LD	(CLOSEFLG),A	;clear close flag.
1720    095E  CDA208    		CALL	CLOSEIT		;close this extent.
1721    0961  CDF505    		CALL	CKFILPOS
1722    0964  C8        		RET	Z		;not there???
1723    0965  2A4303    		LD	HL,(PARAMS)	;get extent byte.
1724    0968  010C00    		LD	BC,12
1725    096B  09        		ADD	HL,BC
1726    096C  7E        		LD	A,(HL)		;and increment it.
1727    096D  3C        		INC	A
1728    096E  E61F      		AND	1Fh		;keep within range 0-31.
1729    0970  77        		LD	(HL),A
1730    0971  CA8309    		JP	Z,GTNEXT1	;overflow?
1731    0974  47        		LD	B,A		;mask extent byte.
1732    0975  3AC50D    		LD	A,(EXTMASK)
1733    0978  A0        		AND	B
1734    0979  21D20D    		LD	HL,CLOSEFLG	;check close flag (0ffh is ok).
1735    097C  A6        		AND	(HL)
1736    097D  CA8E09    		JP	Z,GTNEXT2	;if zero, we must read in next extent.
1737    0980  C3AC09    		JP	GTNEXT3		;else, it is already in memory.
1738    0983  010200    	GTNEXT1:LD	BC,2		;Point to the 's2' byte.
1739    0986  09        		ADD	HL,BC
1740    0987  34        		INC	(HL)		;and bump it.
1741    0988  7E        		LD	A,(HL)		;too many extents?
1742    0989  E60F      		AND	0Fh
1743    098B  CAB609    		JP	Z,GTNEXT5	;yes, set error code.
1744                    	;
1745                    	;   Get here to open the next extent.
1746                    	;
1747    098E  0E0F      	GTNEXT2:LD	C,15		;set to check first 15 bytes of fcb.
1748    0990  CD1807    		CALL	FINDFST		;find the first one.
1749    0993  CDF505    		CALL	CKFILPOS	;none available?
1750    0996  C2AC09    		JP	NZ,GTNEXT3
1751    0999  3AD30D    		LD	A,(RDWRTFLG)	;no extent present. Can we open an empty one?
1752    099C  3C        		INC	A		;0ffh means reading (so not possible).
1753    099D  CAB609    		JP	Z,GTNEXT5	;or an error.
1754    09A0  CD2409    		CALL	GETEMPTY	;we are writing, get an empty entry.
1755    09A3  CDF505    		CALL	CKFILPOS	;none?
1756    09A6  CAB609    		JP	Z,GTNEXT5	;error if true.
1757    09A9  C3AF09    		JP	GTNEXT4		;else we are almost done.
1758    09AC  CD5A08    	GTNEXT3:CALL	OPENIT1		;open this extent.
1759    09AF  CDBB04    	GTNEXT4:CALL	STRDATA		;move in updated data (rec #, extent #, etc.)
1760    09B2  AF        		XOR	A		;clear status and return.
1761    09B3  C30103    		JP	SETSTAT
1762                    	;
1763                    	;   Error in extending the file. Too many extents were needed
1764                    	; or not enough space on the disk.
1765                    	;
1766    09B6  CD0503    	GTNEXT5:CALL	IOERR1		;set error code, clear bit 7 of 's2'
1767    09B9  C37805    		JP	SETS2B7		;so this is not written on a close.
1768                    	;
1769                    	;   Read a sequential file.
1770                    	;
1771    09BC  3E01      	RDSEQ:	LD	A,1		;set sequential access mode.
1772    09BE  32D50D    		LD	(MODE),A
1773    09C1  3EFF      	RDSEQ1:	LD	A,0FFh		;don't allow reading unwritten space.
1774    09C3  32D30D    		LD	(RDWRTFLG),A
1775    09C6  CDBB04    		CALL	STRDATA		;put rec# and ext# into fcb.
1776    09C9  3AE30D    		LD	A,(SAVNREC)	;get next record to read.
1777    09CC  21E10D    		LD	HL,SAVNXT	;get number of records in extent.
1778    09CF  BE        		CP	(HL)		;within this extent?
1779    09D0  DAE609    		JP	C,RDSEQ2
1780    09D3  FE80      		CP	128		;no. Is this extent fully used?
1781    09D5  C2FB09    		JP	NZ,RDSEQ3	;no. End-of-file.
1782    09D8  CD5A09    		CALL	GETNEXT		;yes, open the next one.
1783    09DB  AF        		XOR	A		;reset next record to read.
1784    09DC  32E30D    		LD	(SAVNREC),A
1785    09DF  3A4503    		LD	A,(STATUS)	;check on open, successful?
1786    09E2  B7        		OR	A
1787    09E3  C2FB09    		JP	NZ,RDSEQ3	;no, error.
1788    09E6  CD7704    	RDSEQ2:	CALL	COMBLK		;ok. compute block number to read.
1789    09E9  CD8404    		CALL	CHKBLK		;check it. Within bounds?
1790    09EC  CAFB09    		JP	Z,RDSEQ3	;no, error.
1791    09EF  CD8A04    		CALL	LOGICAL		;convert (BLKNMBR) to logical sector (128 byte).
1792    09F2  CDD103    		CALL	TRKSEC1		;set the track and sector for this block #.
1793    09F5  CDB203    		CALL	DOREAD		;and read it.
1794    09F8  C3D204    		JP	SETNREC		;and set the next record to be accessed.
1795                    	;
1796                    	;   Read error occured. Set status and return.
1797                    	;
1798    09FB  C30503    	RDSEQ3:	JP	IOERR1
1799                    	;
1800                    	;   Write the next sequential record.
1801                    	;
1802    09FE  3E01      	WTSEQ:	LD	A,1		;set sequential access mode.
1803    0A00  32D50D    		LD	(MODE),A
1804    0A03  3E00      	WTSEQ1:	LD	A,0		;allow an addition empty extent to be opened.
1805    0A05  32D30D    		LD	(RDWRTFLG),A
1806    0A08  CD5405    		CALL	CHKWPRT		;check write protect status.
1807    0A0B  2A4303    		LD	HL,(PARAMS)
1808    0A0E  CD4705    		CALL	CKROF1		;check for read only file, (HL) already set to fcb.
1809    0A11  CDBB04    		CALL	STRDATA		;put updated data into fcb.
1810    0A14  3AE30D    		LD	A,(SAVNREC)	;get record number to write.
1811    0A17  FE80      		CP	128		;within range?
1812    0A19  D20503    		JP	NC,IOERR1	;no, error(?).
1813    0A1C  CD7704    		CALL	COMBLK		;compute block number.
1814    0A1F  CD8404    		CALL	CHKBLK		;check number.
1815    0A22  0E00      		LD	C,0		;is there one to write to?
1816    0A24  C26E0A    		JP	NZ,WTSEQ6	;yes, go do it.
1817    0A27  CD3E04    		CALL	GETBLOCK	;get next block number within fcb to use.
1818    0A2A  32D70D    		LD	(RELBLOCK),A	;and save.
1819    0A2D  010000    		LD	BC,0		;start looking for space from the start
1820    0A30  B7        		OR	A		;if none allocated as yet.
1821    0A31  CA3B0A    		JP	Z,WTSEQ2
1822    0A34  4F        		LD	C,A		;extract previous block number from fcb
1823    0A35  0B        		DEC	BC		;so we can be closest to it.
1824    0A36  CD5E04    		CALL	EXTBLK
1825    0A39  44        		LD	B,H
1826    0A3A  4D        		LD	C,L
1827    0A3B  CDBE07    	WTSEQ2:	CALL	FNDSPACE	;find the next empty block nearest number (BC).
1828    0A3E  7D        		LD	A,L		;check for a zero number.
1829    0A3F  B4        		OR	H
1830    0A40  C2480A    		JP	NZ,WTSEQ3
1831    0A43  3E02      		LD	A,2		;no more space?
1832    0A45  C30103    		JP	SETSTAT
1833    0A48  22E50D    	WTSEQ3:	LD	(BLKNMBR),HL	;save block number to access.
1834    0A4B  EB        		EX	DE,HL		;put block number into (DE).
1835    0A4C  2A4303    		LD	HL,(PARAMS)	;now we must update the fcb for this
1836    0A4F  011000    		LD	BC,16		;newly allocated block.
1837    0A52  09        		ADD	HL,BC
1838    0A53  3ADD0D    		LD	A,(BIGDISK)	;8 or 16 bit block numbers?
1839    0A56  B7        		OR	A
1840    0A57  3AD70D    		LD	A,(RELBLOCK)	;(* update this entry *)
1841    0A5A  CA640A    		JP	Z,WTSEQ4	;zero means 16 bit ones.
1842    0A5D  CD6405    		CALL	ADDA2HL		;(HL)=(HL)+(A)
1843    0A60  73        		LD	(HL),E		;store new block number.
1844    0A61  C36C0A    		JP	WTSEQ5
1845    0A64  4F        	WTSEQ4:	LD	C,A		;compute spot in this 16 bit table.
1846    0A65  0600      		LD	B,0
1847    0A67  09        		ADD	HL,BC
1848    0A68  09        		ADD	HL,BC
1849    0A69  73        		LD	(HL),E		;stuff block number (DE) there.
1850    0A6A  23        		INC	HL
1851    0A6B  72        		LD	(HL),D
1852    0A6C  0E02      	WTSEQ5:	LD	C,2		;set (C) to indicate writing to un-used disk space.
1853    0A6E  3A4503    	WTSEQ6:	LD	A,(STATUS)	;are we ok so far?
1854    0A71  B7        		OR	A
1855    0A72  C0        		RET	NZ
1856    0A73  C5        		PUSH	BC		;yes, save write flag for bios (register C).
1857    0A74  CD8A04    		CALL	LOGICAL		;convert (BLKNMBR) over to loical sectors.
1858    0A77  3AD50D    		LD	A,(MODE)	;get access mode flag (1=sequential,
1859    0A7A  3D        		DEC	A		;0=random, 2=special?).
1860    0A7B  3D        		DEC	A
1861    0A7C  C2BB0A    		JP	NZ,WTSEQ9
1862                    	;
1863                    	;   Special random i/o from function #40. Maybe for M/PM, but the
1864                    	; current block, if it has not been written to, will be zeroed
1865                    	; out and then written (reason?).
1866                    	;
1867    0A7F  C1        		POP	BC
1868    0A80  C5        		PUSH	BC
1869    0A81  79        		LD	A,C		;get write status flag (2=writing unused space).
1870    0A82  3D        		DEC	A
1871    0A83  3D        		DEC	A
1872    0A84  C2BB0A    		JP	NZ,WTSEQ9
1873    0A87  E5        		PUSH	HL
1874    0A88  2AB90D    		LD	HL,(DIRBUF)	;zero out the directory buffer.
1875    0A8B  57        		LD	D,A		;note that (A) is zero here.
1876    0A8C  77        	WTSEQ7:	LD	(HL),A
1877    0A8D  23        		INC	HL
1878    0A8E  14        		INC	D		;do 128 bytes.
1879    0A8F  F28C0A    		JP	P,WTSEQ7
1880    0A92  CDE005    		CALL	DIRDMA		;tell the bios the dma address for directory access.
1881    0A95  2AE70D    		LD	HL,(LOGSECT)	;get sector that starts current block.
1882    0A98  0E02      		LD	C,2		;set 'writing to unused space' flag.
1883    0A9A  22E50D    	WTSEQ8:	LD	(BLKNMBR),HL	;save sector to write.
1884    0A9D  C5        		PUSH	BC
1885    0A9E  CDD103    		CALL	TRKSEC1		;determine its track and sector numbers.
1886    0AA1  C1        		POP	BC
1887    0AA2  CDB803    		CALL	DOWRITE		;now write out 128 bytes of zeros.
1888    0AA5  2AE50D    		LD	HL,(BLKNMBR)	;get sector number.
1889    0AA8  0E00      		LD	C,0		;set normal write flag.
1890    0AAA  3AC40D    		LD	A,(BLKMASK)	;determine if we have written the entire
1891    0AAD  47        		LD	B,A		;physical block.
1892    0AAE  A5        		AND	L
1893    0AAF  B8        		CP	B
1894    0AB0  23        		INC	HL		;prepare for the next one.
1895    0AB1  C29A0A    		JP	NZ,WTSEQ8	;continue until (BLKMASK+1) sectors written.
1896    0AB4  E1        		POP	HL		;reset next sector number.
1897    0AB5  22E50D    		LD	(BLKNMBR),HL
1898    0AB8  CDDA05    		CALL	DEFDMA		;and reset dma address.
1899                    	;
1900                    	;   Normal disk write. Set the desired track and sector then
1901                    	; do the actual write.
1902                    	;
1903    0ABB  CDD103    	WTSEQ9:	CALL	TRKSEC1		;determine track and sector for this write.
1904    0ABE  C1        		POP	BC		;get write status flag.
1905    0ABF  C5        		PUSH	BC
1906    0AC0  CDB803    		CALL	DOWRITE		;and write this out.
1907    0AC3  C1        		POP	BC
1908    0AC4  3AE30D    		LD	A,(SAVNREC)	;get number of records in file.
1909    0AC7  21E10D    		LD	HL,SAVNXT	;get last record written.
1910    0ACA  BE        		CP	(HL)
1911    0ACB  DAD20A    		JP	C,WTSEQ10
1912    0ACE  77        		LD	(HL),A		;we have to update record count.
1913    0ACF  34        		INC	(HL)
1914    0AD0  0E02      		LD	C,2
1915                    	;
1916                    	;*   This area has been patched to correct disk update problem
1917                    	;* when using blocking and de-blocking in the BIOS.
1918                    	;
1919                    	WTSEQ10:
1920    0AD2  00        		NOP			;was 'dcr c'
1921    0AD3  00        		NOP			;was 'dcr c'
1922    0AD4  210000    		LD	HL,0		;was 'jnz wtseq99'
1923                    	;
1924                    	; *   End of patch.
1925                    	;
1926    0AD7  F5        		PUSH	AF
1927    0AD8  CD6905    		CALL	GETS2		;set 'extent written to' flag.
1928    0ADB  E67F      		AND	7Fh		;(* clear bit 7 *)
1929    0ADD  77        		LD	(HL),A
1930    0ADE  F1        		POP	AF		;get record count for this extent.
1931    0ADF  FE7F      	WTSEQ99:CP	127		;is it full?
1932    0AE1  C2000B    		JP	NZ,WTSEQ12
1933    0AE4  3AD50D    		LD	A,(MODE)	;yes, are we in sequential mode?
1934    0AE7  FE01      		CP	1
1935    0AE9  C2000B    		JP	NZ,WTSEQ12
1936    0AEC  CDD204    		CALL	SETNREC		;yes, set next record number.
1937    0AEF  CD5A09    		CALL	GETNEXT		;and get next empty space in directory.
1938    0AF2  214503    		LD	HL,STATUS	;ok?
1939    0AF5  7E        		LD	A,(HL)
1940    0AF6  B7        		OR	A
1941    0AF7  C2FE0A    		JP	NZ,WTSEQ11
1942    0AFA  3D        		DEC	A		;yes, set record count to -1.
1943    0AFB  32E30D    		LD	(SAVNREC),A
1944    0AFE  3600      	WTSEQ11:LD	(HL),0		;clear status.
1945    0B00  C3D204    	WTSEQ12:JP	SETNREC		;set next record to access.
1946                    	;
1947                    	;   For random i/o, set the fcb for the desired record number
1948                    	; based on the 'r0,r1,r2' bytes. These bytes in the fcb are
1949                    	; used as follows:
1950                    	;
1951                    	;       fcb+35            fcb+34            fcb+33
1952                    	;  |     'r-2'      |      'r-1'      |      'r-0'     |
1953                    	;  |7             0 | 7             0 | 7             0|
1954                    	;  |0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0|
1955                    	;  |    overflow   | | extra |  extent   |   record #  |
1956                    	;  | ______________| |_extent|__number___|_____________|
1957                    	;                     also 's2'
1958                    	;
1959                    	;   On entry, register (C) contains 0ffh if this is a read
1960                    	; and thus we can not access unwritten disk space. Otherwise,
1961                    	; another extent will be opened (for writing) if required.
1962                    	;
1963    0B03  AF        	POSITION: XOR	A		;set random i/o flag.
1964    0B04  32D50D    		LD	(MODE),A
1965                    	;
1966                    	;   Special entry (function #40). M/PM ?
1967                    	;
1968    0B07  C5        	POSITN1:PUSH	BC		;save read/write flag.
1969    0B08  2A4303    		LD	HL,(PARAMS)	;get address of fcb.
1970    0B0B  EB        		EX	DE,HL
1971    0B0C  212100    		LD	HL,33		;now get byte 'r0'.
1972    0B0F  19        		ADD	HL,DE
1973    0B10  7E        		LD	A,(HL)
1974    0B11  E67F      		AND	7Fh		;keep bits 0-6 for the record number to access.
1975    0B13  F5        		PUSH	AF
1976    0B14  7E        		LD	A,(HL)		;now get bit 7 of 'r0' and bits 0-3 of 'r1'.
1977    0B15  17        		RLA	
1978    0B16  23        		INC	HL
1979    0B17  7E        		LD	A,(HL)
1980    0B18  17        		RLA	
1981    0B19  E61F      		AND	1Fh		;and save this in bits 0-4 of (C).
1982    0B1B  4F        		LD	C,A		;this is the extent byte.
1983    0B1C  7E        		LD	A,(HL)		;now get the extra extent byte.
1984    0B1D  1F        		RRA	
1985    0B1E  1F        		RRA	
1986    0B1F  1F        		RRA	
1987    0B20  1F        		RRA	
1988    0B21  E60F      		AND	0Fh
1989    0B23  47        		LD	B,A		;and save it in (B).
1990    0B24  F1        		POP	AF		;get record number back to (A).
1991    0B25  23        		INC	HL		;check overflow byte 'r2'.
1992    0B26  6E        		LD	L,(HL)
1993    0B27  2C        		INC	L
1994    0B28  2D        		DEC	L
1995    0B29  2E06      		LD	L,6		;prepare for error.
1996    0B2B  C28B0B    		JP	NZ,POSITN5	;out of disk space error.
1997    0B2E  212000    		LD	HL,32		;store record number into fcb.
1998    0B31  19        		ADD	HL,DE
1999    0B32  77        		LD	(HL),A
2000    0B33  210C00    		LD	HL,12		;and now check the extent byte.
2001    0B36  19        		ADD	HL,DE
2002    0B37  79        		LD	A,C
2003    0B38  96        		SUB	(HL)		;same extent as before?
2004    0B39  C2470B    		JP	NZ,POSITN2
2005    0B3C  210E00    		LD	HL,14		;yes, check extra extent byte 's2' also.
2006    0B3F  19        		ADD	HL,DE
2007    0B40  78        		LD	A,B
2008    0B41  96        		SUB	(HL)
2009    0B42  E67F      		AND	7Fh
2010    0B44  CA7F0B    		JP	Z,POSITN3	;same, we are almost done then.
2011                    	;
2012                    	;  Get here when another extent is required.
2013                    	;
2014    0B47  C5        	POSITN2:PUSH	BC
2015    0B48  D5        		PUSH	DE
2016    0B49  CDA208    		CALL	CLOSEIT		;close current extent.
2017    0B4C  D1        		POP	DE
2018    0B4D  C1        		POP	BC
2019    0B4E  2E03      		LD	L,3		;prepare for error.
2020    0B50  3A4503    		LD	A,(STATUS)
2021    0B53  3C        		INC	A
2022    0B54  CA840B    		JP	Z,POSITN4	;close error.
2023    0B57  210C00    		LD	HL,12		;put desired extent into fcb now.
2024    0B5A  19        		ADD	HL,DE
2025    0B5B  71        		LD	(HL),C
2026    0B5C  210E00    		LD	HL,14		;and store extra extent byte 's2'.
2027    0B5F  19        		ADD	HL,DE
2028    0B60  70        		LD	(HL),B
2029    0B61  CD5108    		CALL	OPENIT		;try and get this extent.
2030    0B64  3A4503    		LD	A,(STATUS)	;was it there?
2031    0B67  3C        		INC	A
2032    0B68  C27F0B    		JP	NZ,POSITN3
2033    0B6B  C1        		POP	BC		;no. can we create a new one (writing?).
2034    0B6C  C5        		PUSH	BC
2035    0B6D  2E04      		LD	L,4		;prepare for error.
2036    0B6F  0C        		INC	C
2037    0B70  CA840B    		JP	Z,POSITN4	;nope, reading unwritten space error.
2038    0B73  CD2409    		CALL	GETEMPTY	;yes we can, try to find space.
2039    0B76  2E05      		LD	L,5		;prepare for error.
2040    0B78  3A4503    		LD	A,(STATUS)
2041    0B7B  3C        		INC	A
2042    0B7C  CA840B    		JP	Z,POSITN4	;out of space?
2043                    	;
2044                    	;   Normal return location. Clear error code and return.
2045                    	;
2046    0B7F  C1        	POSITN3:POP	BC		;restore stack.
2047    0B80  AF        		XOR	A		;and clear error code byte.
2048    0B81  C30103    		JP	SETSTAT
2049                    	;
2050                    	;   Error. Set the 's2' byte to indicate this (why?).
2051                    	;
2052    0B84  E5        	POSITN4:PUSH	HL
2053    0B85  CD6905    		CALL	GETS2
2054    0B88  36C0      		LD	(HL),0C0h
2055    0B8A  E1        		POP	HL
2056                    	;
2057                    	;   Return with error code (presently in L).
2058                    	;
2059    0B8B  C1        	POSITN5:POP	BC
2060    0B8C  7D        		LD	A,L		;get error code.
2061    0B8D  324503    		LD	(STATUS),A
2062    0B90  C37805    		JP	SETS2B7
2063                    	;
2064                    	;   Read a random record.
2065                    	;
2066    0B93  0EFF      	READRAN:LD	C,0FFh		;set 'read' status.
2067    0B95  CD030B    		CALL	POSITION	;position the file to proper record.
2068    0B98  CCC109    		CALL	Z,RDSEQ1	;and read it as usual (if no errors).
2069    0B9B  C9        		RET	
2070                    	;
2071                    	;   Write to a random record.
2072                    	;
2073    0B9C  0E00      	WRITERAN: LD	C,0		;set 'writing' flag.
2074    0B9E  CD030B    		CALL	POSITION	;position the file to proper record.
2075    0BA1  CC030A    		CALL	Z,WTSEQ1	;and write as usual (if no errors).
2076    0BA4  C9        		RET	
2077                    	;
2078                    	;   Compute the random record number. Enter with (HL) pointing
2079                    	; to a fcb an (DE) contains a relative location of a record
2080                    	; number. On exit, (C) contains the 'r0' byte, (B) the 'r1'
2081                    	; byte, and (A) the 'r2' byte.
2082                    	;
2083                    	;   On return, the zero flag is set if the record is within
2084                    	; bounds. Otherwise, an overflow occured.
2085                    	;
2086    0BA5  EB        	COMPRAND: EX	DE,HL		;save fcb pointer in (DE).
2087    0BA6  19        		ADD	HL,DE		;compute relative position of record #.
2088    0BA7  4E        		LD	C,(HL)		;get record number into (BC).
2089    0BA8  0600      		LD	B,0
2090    0BAA  210C00    		LD	HL,12		;now get extent.
2091    0BAD  19        		ADD	HL,DE
2092    0BAE  7E        		LD	A,(HL)		;compute (BC)=(record #)+(extent)*128.
2093    0BAF  0F        		RRCA			;move lower bit into bit 7.
2094    0BB0  E680      		AND	80h		;and ignore all other bits.
2095    0BB2  81        		ADD	A,C		;add to our record number.
2096    0BB3  4F        		LD	C,A
2097    0BB4  3E00      		LD	A,0		;take care of any carry.
2098    0BB6  88        		ADC	A,B
2099    0BB7  47        		LD	B,A
2100    0BB8  7E        		LD	A,(HL)		;now get the upper bits of extent into
2101    0BB9  0F        		RRCA			;bit positions 0-3.
2102    0BBA  E60F      		AND	0Fh		;and ignore all others.
2103    0BBC  80        		ADD	A,B		;add this in to 'r1' byte.
2104    0BBD  47        		LD	B,A
2105    0BBE  210E00    		LD	HL,14		;get the 's2' byte (extra extent).
2106    0BC1  19        		ADD	HL,DE
2107    0BC2  7E        		LD	A,(HL)
2108    0BC3  87        		ADD	A,A		;and shift it left 4 bits (bits 4-7).
2109    0BC4  87        		ADD	A,A
2110    0BC5  87        		ADD	A,A
2111    0BC6  87        		ADD	A,A
2112    0BC7  F5        		PUSH	AF		;save carry flag (bit 0 of flag byte).
2113    0BC8  80        		ADD	A,B		;now add extra extent into 'r1'.
2114    0BC9  47        		LD	B,A
2115    0BCA  F5        		PUSH	AF		;and save carry (overflow byte 'r2').
2116    0BCB  E1        		POP	HL		;bit 0 of (L) is the overflow indicator.
2117    0BCC  7D        		LD	A,L
2118    0BCD  E1        		POP	HL		;and same for first carry flag.
2119    0BCE  B5        		OR	L		;either one of these set?
2120    0BCF  E601      		AND	01h		;only check the carry flags.
2121    0BD1  C9        		RET	
2122                    	;
2123                    	;   Routine to setup the fcb (bytes 'r0', 'r1', 'r2') to
2124                    	; reflect the last record used for a random (or other) file.
2125                    	; This reads the directory and looks at all extents computing
2126                    	; the largerst record number for each and keeping the maximum
2127                    	; value only. Then 'r0', 'r1', and 'r2' will reflect this
2128                    	; maximum record number. This is used to compute the space used
2129                    	; by a random file.
2130                    	;
2131    0BD2  0E0C      	RANSIZE:LD	C,12		;look thru directory for first entry with
2132    0BD4  CD1807    		CALL	FINDFST		;this name.
2133    0BD7  2A4303    		LD	HL,(PARAMS)	;zero out the 'r0, r1, r2' bytes.
2134    0BDA  112100    		LD	DE,33
2135    0BDD  19        		ADD	HL,DE
2136    0BDE  E5        		PUSH	HL
2137    0BDF  72        		LD	(HL),D		;note that (D)=0.
2138    0BE0  23        		INC	HL
2139    0BE1  72        		LD	(HL),D
2140    0BE2  23        		INC	HL
2141    0BE3  72        		LD	(HL),D
2142    0BE4  CDF505    	RANSIZ1:CALL	CKFILPOS	;is there an extent to process?
2143    0BE7  CA0C0C    		JP	Z,RANSIZ3	;no, we are done.
2144    0BEA  CD5E05    		CALL	FCB2HL		;set (HL) pointing to proper fcb in dir.
2145    0BED  110F00    		LD	DE,15		;point to last record in extent.
2146    0BF0  CDA50B    		CALL	COMPRAND	;and compute random parameters.
2147    0BF3  E1        		POP	HL
2148    0BF4  E5        		PUSH	HL		;now check these values against those
2149    0BF5  5F        		LD	E,A		;already in fcb.
2150    0BF6  79        		LD	A,C		;the carry flag will be set if those
2151    0BF7  96        		SUB	(HL)		;in the fcb represent a larger size than
2152    0BF8  23        		INC	HL		;this extent does.
2153    0BF9  78        		LD	A,B
2154    0BFA  9E        		SBC	A,(HL)
2155    0BFB  23        		INC	HL
2156    0BFC  7B        		LD	A,E
2157    0BFD  9E        		SBC	A,(HL)
2158    0BFE  DA060C    		JP	C,RANSIZ2
2159    0C01  73        		LD	(HL),E		;we found a larger (in size) extent.
2160    0C02  2B        		DEC	HL		;stuff these values into fcb.
2161    0C03  70        		LD	(HL),B
2162    0C04  2B        		DEC	HL
2163    0C05  71        		LD	(HL),C
2164    0C06  CD2D07    	RANSIZ2:CALL	FINDNXT		;now get the next extent.
2165    0C09  C3E40B    		JP	RANSIZ1		;continue til all done.
2166    0C0C  E1        	RANSIZ3:POP	HL		;we are done, restore the stack and
2167    0C0D  C9        		RET			;return.
2168                    	;
2169                    	;   Function to return the random record position of a given
2170                    	; file which has been read in sequential mode up to now.
2171                    	;
2172    0C0E  2A4303    	SETRAN:	LD	HL,(PARAMS)	;point to fcb.
2173    0C11  112000    		LD	DE,32		;and to last used record.
2174    0C14  CDA50B    		CALL	COMPRAND	;compute random position.
2175    0C17  212100    		LD	HL,33		;now stuff these values into fcb.
2176    0C1A  19        		ADD	HL,DE
2177    0C1B  71        		LD	(HL),C		;move 'r0'.
2178    0C1C  23        		INC	HL
2179    0C1D  70        		LD	(HL),B		;and 'r1'.
2180    0C1E  23        		INC	HL
2181    0C1F  77        		LD	(HL),A		;and lastly 'r2'.
2182    0C20  C9        		RET	
2183                    	;
2184                    	;   This routine select the drive specified in (ACTIVE) and
2185                    	; update the login vector and bitmap table if this drive was
2186                    	; not already active.
2187                    	;
2188    0C21  2AAF0D    	LOGINDRV: LD	HL,(LOGIN)	;get the login vector.
2189    0C24  3A4203    		LD	A,(ACTIVE)	;get the default drive.
2190    0C27  4F        		LD	C,A
2191    0C28  CDEA04    		CALL	SHIFTR		;position active bit for this drive
2192    0C2B  E5        		PUSH	HL		;into bit 0.
2193    0C2C  EB        		EX	DE,HL
2194    0C2D  CD5903    		CALL	SELECT		;select this drive.
2195                    	;    PRTPROB 'C'
2196    0C30  E1        		POP	HL
2197    0C31  CC4703    		CALL	Z,SLCTERR	;valid drive?
2198    0C34  7D        		LD	A,L		;is this a newly activated drive?
2199    0C35  1F        		RRA	
2200    0C36  D8        		RET	C
2201    0C37  2AAF0D    		LD	HL,(LOGIN)	;yes, update the login vector.
2202    0C3A  4D        		LD	C,L
2203    0C3B  44        		LD	B,H
2204    0C3C  CD0B05    		CALL	SETBIT
2205                    	;    PRTPROB 'E'
2206    0C3F  22AF0D    		LD	(LOGIN),HL	;and save.
2207    0C42  C3A306    		JP	BITMAP		;now update the bitmap.
2208                    	;
2209                    	;   Function to set the active disk number.
2210                    	;
2211    0C45  3AD60D    	SETDSK:	LD	A,(EPARAM)	;get parameter passed and see if this
2212    0C48  214203    		LD	HL,ACTIVE	;represents a change in drives.
2213    0C4B  BE        		CP	(HL)
2214    0C4C  C8        		RET	Z
2215    0C4D  77        		LD	(HL),A		;yes it does, log it in.
2216    0C4E  C3210C    		JP	LOGINDRV
2217                    	;
2218                    	;   This is the 'auto disk select' routine. The first byte
2219                    	; of the fcb is examined for a drive specification. If non
2220                    	; zero then the drive will be selected and loged in.
2221                    	;
2222    0C51  3EFF      	AUTOSEL:LD	A,0FFh		;say 'auto-select activated'.
2223    0C53  32DE0D    		LD	(AUTO),A
2224    0C56  2A4303    		LD	HL,(PARAMS)	;get drive specified.
2225    0C59  7E        		LD	A,(HL)
2226    0C5A  E61F      		AND	1Fh		;look at lower 5 bits.
2227    0C5C  3D        		DEC	A		;adjust for (1=A, 2=B) etc.
2228    0C5D  32D60D    		LD	(EPARAM),A	;and save for the select routine.
2229    0C60  FE1E      		CP	1Eh		;check for 'no change' condition.
2230    0C62  D2750C    		JP	NC,AUTOSL1	;yes, don't change.
2231    0C65  3A4203    		LD	A,(ACTIVE)	;we must change, save currently active
2232    0C68  32DF0D    		LD	(OLDDRV),A	;drive.
2233    0C6B  7E        		LD	A,(HL)		;and save first byte of fcb also.
2234    0C6C  32E00D    		LD	(AUTOFLAG),A	;this must be non-zero.
2235    0C6F  E6E0      		AND	0E0h		;whats this for (bits 6,7 are used for
2236    0C71  77        		LD	(HL),A		;something)?
2237    0C72  CD450C    		CALL	SETDSK		;select and log in this drive.
2238    0C75  3A4103    	AUTOSL1:LD	A,(USERNO)	;move user number into fcb.
2239    0C78  2A4303    		LD	HL,(PARAMS)	;(* upper half of first byte *)
2240    0C7B  B6        		OR	(HL)
2241    0C7C  77        		LD	(HL),A
2242    0C7D  C9        		RET			;and return (all done).
2243                    	;
2244                    	;   Function to return the current cp/m version number.
2245                    	;
2246    0C7E  3E22      	GETVER:	LD	A,22h		;version 2.2
2247    0C80  C30103    		JP	SETSTAT
2248                    	;
2249                    	;   Function to reset the disk system.
2250                    	;
2251    0C83  210000    	RSTDSK:	LD	HL,0		;clear write protect status and log
2252    0C86  22AD0D    		LD	(WRTPRT),HL	;in vector.
2253    0C89  22AF0D    		LD	(LOGIN),HL
2254    0C8C  AF        		XOR	A		;select drive 'A'.
2255    0C8D  324203    		LD	(ACTIVE),A
2256    0C90  218000    		LD	HL,TBUFF	;setup default dma address.
2257    0C93  22B10D    		LD	(USERDMA),HL
2258                    	;    PRTPROB 'A'
2259    0C96  CDDA05    		CALL	DEFDMA
2260                    	;    PRTPROB 'B'
2261    0C99  C3210C    		JP	LOGINDRV	;now log in drive 'A'.
2262                    	;
2263                    	;   Function to open a specified file.
2264                    	;
2265    0C9C  CD7205    	OPENFIL:CALL	CLEARS2		;clear 's2' byte.
2266    0C9F  CD510C    		CALL	AUTOSEL		;select proper disk.
2267    0CA2  C35108    		JP	OPENIT		;and open the file.
2268                    	;
2269                    	;   Function to close a specified file.
2270                    	;
2271    0CA5  CD510C    	CLOSEFIL: CALL	AUTOSEL		;select proper disk.
2272    0CA8  C3A208    		JP	CLOSEIT		;and close the file.
2273                    	;
2274                    	;   Function to return the first occurence of a specified file
2275                    	; name. If the first byte of the fcb is '?' then the name will
2276                    	; not be checked (get the first entry no matter what).
2277                    	;
2278    0CAB  0E00      	GETFST:	LD	C,0		;prepare for special search.
2279    0CAD  EB        		EX	DE,HL
2280    0CAE  7E        		LD	A,(HL)		;is first byte a '?'?
2281    0CAF  FE3F      		CP	'?'
2282    0CB1  CAC20C    		JP	Z,GETFST1	;yes, just get very first entry (zero length match).
2283    0CB4  CDA604    		CALL	SETEXT		;get the extension byte from fcb.
2284    0CB7  7E        		LD	A,(HL)		;is it '?'? if yes, then we want
2285    0CB8  FE3F      		CP	'?'		;an entry with a specific 's2' byte.
2286    0CBA  C47205    		CALL	NZ,CLEARS2	;otherwise, look for a zero 's2' byte.
2287    0CBD  CD510C    		CALL	AUTOSEL		;select proper drive.
2288    0CC0  0E0F      		LD	C,15		;compare bytes 0-14 in fcb (12&13 excluded).
2289    0CC2  CD1807    	GETFST1:CALL	FINDFST		;find an entry and then move it into
2290    0CC5  C3E905    		JP	MOVEDIR		;the users dma space.
2291                    	;
2292                    	;   Function to return the next occurence of a file name.
2293                    	;
2294    0CC8  2AD90D    	GETNXT:	LD	HL,(SAVEFCB)	;restore pointers. note that no
2295    0CCB  224303    		LD	(PARAMS),HL	;other dbos calls are allowed.
2296    0CCE  CD510C    		CALL	AUTOSEL		;no error will be returned, but the
2297    0CD1  CD2D07    		CALL	FINDNXT		;results will be wrong.
2298    0CD4  C3E905    		JP	MOVEDIR
2299                    	;
2300                    	;   Function to delete a file by name.
2301                    	;
2302    0CD7  CD510C    	DELFILE:CALL	AUTOSEL		;select proper drive.
2303    0CDA  CD9C07    		CALL	ERAFILE		;erase the file.
2304    0CDD  C30107    		JP	STSTATUS	;set status and return.
2305                    	;
2306                    	;   Function to execute a sequential read of the specified
2307                    	; record number.
2308                    	;
2309    0CE0  CD510C    	READSEQ:CALL	AUTOSEL		;select proper drive then read.
2310    0CE3  C3BC09    		JP	RDSEQ
2311                    	;
2312                    	;   Function to write the net sequential record.
2313                    	;
2314    0CE6  CD510C    	WRTSEQ:	CALL	AUTOSEL		;select proper drive then write.
2315    0CE9  C3FE09    		JP	WTSEQ
2316                    	;
2317                    	;   Create a file function.
2318                    	;
2319    0CEC  CD7205    	FCREATE:CALL	CLEARS2		;clear the 's2' byte on all creates.
2320    0CEF  CD510C    		CALL	AUTOSEL		;select proper drive and get the next
2321    0CF2  C32409    		JP	GETEMPTY	;empty directory space.
2322                    	;
2323                    	;   Function to rename a file.
2324                    	;
2325    0CF5  CD510C    	RENFILE:CALL	AUTOSEL		;select proper drive and then switch
2326    0CF8  CD1608    		CALL	CHGNAMES	;file names.
2327    0CFB  C30107    		JP	STSTATUS
2328                    	;
2329                    	;   Function to return the login vector.
2330                    	;
2331    0CFE  2AAF0D    	GETLOG:	LD	HL,(LOGIN)
2332    0D01  C3290D    		JP	GETPRM1
2333                    	;
2334                    	;   Function to return the current disk assignment.
2335                    	;
2336    0D04  3A4203    	GETCRNT:LD	A,(ACTIVE)
2337    0D07  C30103    		JP	SETSTAT
2338                    	;
2339                    	;   Function to set the dma address.
2340                    	;
2341    0D0A  EB        	PUTDMA:	EX	DE,HL
2342    0D0B  22B10D    		LD	(USERDMA),HL	;save in our space and then get to
2343    0D0E  C3DA05    		JP	DEFDMA		;the bios with this also.
2344                    	;
2345                    	;   Function to return the allocation vector.
2346                    	;
2347    0D11  2ABF0D    	GETALOC:LD	HL,(ALOCVECT)
2348    0D14  C3290D    		JP	GETPRM1
2349                    	;
2350                    	;   Function to return the read-only status vector.
2351                    	;
2352    0D17  2AAD0D    	GETROV:	LD	HL,(WRTPRT)
2353    0D1A  C3290D    		JP	GETPRM1
2354                    	;
2355                    	;   Function to set the file attributes (read-only, system).
2356                    	;
2357    0D1D  CD510C    	SETATTR:CALL	AUTOSEL		;select proper drive then save attributes.
2358    0D20  CD3B08    		CALL	SAVEATTR
2359    0D23  C30107    		JP	STSTATUS
2360                    	;
2361                    	;   Function to return the address of the disk parameter block
2362                    	; for the current drive.
2363                    	;
2364    0D26  2ABB0D    	GETPARM:LD	HL,(DISKPB)
2365    0D29  224503    	GETPRM1:LD	(STATUS),HL
2366    0D2C  C9        		RET	
2367                    	;
2368                    	;   Function to get or set the user number. If (E) was (FF)
2369                    	; then this is a request to return the current user number.
2370                    	; Else set the user number from (E).
2371                    	;
2372    0D2D  3AD60D    	GETUSER:LD	A,(EPARAM)	;get parameter.
2373    0D30  FEFF      		CP	0FFh		;get user number?
2374    0D32  C23B0D    		JP	NZ,SETUSER
2375    0D35  3A4103    		LD	A,(USERNO)	;yes, just do it.
2376    0D38  C30103    		JP	SETSTAT
2377    0D3B  E61F      	SETUSER:AND	1Fh		;no, we should set it instead. keep low
2378    0D3D  324103    		LD	(USERNO),A	;bits (0-4) only.
2379    0D40  C9        		RET	
2380                    	;
2381                    	;   Function to read a random record from a file.
2382                    	;
2383    0D41  CD510C    	RDRANDOM: CALL	AUTOSEL		;select proper drive and read.
2384    0D44  C3930B    		JP	READRAN
2385                    	;
2386                    	;   Function to compute the file size for random files.
2387                    	;
2388    0D47  CD510C    	WTRANDOM: CALL	AUTOSEL		;select proper drive and write.
2389    0D4A  C39C0B    		JP	WRITERAN
2390                    	;
2391                    	;   Function to compute the size of a random file.
2392                    	;
2393    0D4D  CD510C    	FILESIZE: CALL	AUTOSEL		;select proper drive and check file length
2394    0D50  C3D20B    		JP	RANSIZE
2395                    	;
2396                    	;   Function #37. This allows a program to log off any drives.
2397                    	; On entry, set (DE) to contain a word with bits set for those
2398                    	; drives that are to be logged off. The log-in vector and the
2399                    	; write protect vector will be updated. This must be a M/PM
2400                    	; special function.
2401                    	;
2402    0D53  2A4303    	LOGOFF:	LD	HL,(PARAMS)	;get drives to log off.
2403    0D56  7D        		LD	A,L		;for each bit that is set, we want
2404    0D57  2F        		CPL			;to clear that bit in (LOGIN)
2405    0D58  5F        		LD	E,A		;and (WRTPRT).
2406    0D59  7C        		LD	A,H
2407    0D5A  2F        		CPL	
2408    0D5B  2AAF0D    		LD	HL,(LOGIN)	;reset the login vector.
2409    0D5E  A4        		AND	H
2410    0D5F  57        		LD	D,A
2411    0D60  7D        		LD	A,L
2412    0D61  A3        		AND	E
2413    0D62  5F        		LD	E,A
2414    0D63  2AAD0D    		LD	HL,(WRTPRT)
2415    0D66  EB        		EX	DE,HL
2416    0D67  22AF0D    		LD	(LOGIN),HL	;and save.
2417    0D6A  7D        		LD	A,L		;now do the write protect vector.
2418    0D6B  A3        		AND	E
2419    0D6C  6F        		LD	L,A
2420    0D6D  7C        		LD	A,H
2421    0D6E  A2        		AND	D
2422    0D6F  67        		LD	H,A
2423    0D70  22AD0D    		LD	(WRTPRT),HL	;and save. all done.
2424    0D73  C9        		RET	
2425                    	;
2426                    	;   Get here to return to the user.
2427                    	;
2428    0D74  3ADE0D    	GOBACK:	LD	A,(AUTO)	;was auto select activated?
2429    0D77  B7        		OR	A
2430    0D78  CA910D    		JP	Z,GOBACK1
2431    0D7B  2A4303    		LD	HL,(PARAMS)	;yes, but was a change made?
2432    0D7E  3600      		LD	(HL),0		;(* reset first byte of fcb *)
2433    0D80  3AE00D    		LD	A,(AUTOFLAG)
2434    0D83  B7        		OR	A
2435    0D84  CA910D    		JP	Z,GOBACK1
2436    0D87  77        		LD	(HL),A		;yes, reset first byte properly.
2437    0D88  3ADF0D    		LD	A,(OLDDRV)	;and get the old drive and select it.
2438    0D8B  32D60D    		LD	(EPARAM),A
2439    0D8E  CD450C    		CALL	SETDSK
2440    0D91  2A0F03    	GOBACK1:LD	HL,(USRSTACK)	;reset the users stack pointer.
2441    0D94  F9        		LD	SP,HL
2442    0D95  2A4503    		LD	HL,(STATUS)	;get return status.
2443    0D98  7D        		LD	A,L		;force version 1.4 compatability.
2444    0D99  44        		LD	B,H
2445    0D9A  C9        		RET			;and go back to user.
2446                    	;
2447                    	;   Function #40. This is a special entry to do random i/o.
2448                    	; For the case where we are writing to unused disk space, this
2449                    	; space will be zeroed out first. This must be a M/PM special
2450                    	; purpose function, because why would any normal program even
2451                    	; care about the previous contents of a sector about to be
2452                    	; written over.
2453                    	;
2454    0D9B  CD510C    	WTSPECL:CALL	AUTOSEL		;select proper drive.
2455    0D9E  3E02      		LD	A,2		;use special write mode.
2456    0DA0  32D50D    		LD	(MODE),A
2457    0DA3  0E00      		LD	C,0		;set write indicator.
2458    0DA5  CD070B    		CALL	POSITN1		;position the file.
2459    0DA8  CC030A    		CALL	Z,WTSEQ1	;and write (if no errors).
2460    0DAB  C9        		RET	
2461                    	;
2462                    	;**************************************************************
2463                    	;*
2464                    	;*     BDOS data storage pool.
2465                    	;*
2466                    	;**************************************************************
2467                    	;
2468    0DAC  E5        	EMPTYFCB: .byte	0E5h		;empty directory segment indicator.
2469    0DAD  0000      	WRTPRT:	.word	0		;write protect status for all 16 drives.
2470    0DAF  0000      	LOGIN:	.word	0		;drive active word (1 bit per drive).
2471    0DB1  8000      	USERDMA:.word	80h		;user's dma address (defaults to 80h).
2472                    	;
2473                    	;   Scratch areas from parameter block.
2474                    	;
2475    0DB3  0000      	SCRATCH1: .word	0		;relative position within dir segment for file (0-3).
2476    0DB5  0000      	SCRATCH2: .word	0		;last selected track number.
2477    0DB7  0000      	SCRATCH3: .word	0		;last selected sector number.
2478                    	;
2479                    	;   Disk storage areas from parameter block.
2480                    	;
2481    0DB9  0000      	DIRBUF:	.word	0		;address of directory buffer to use.
2482    0DBB  0000      	DISKPB:	.word	0		;contains address of disk parameter block.
2483    0DBD  0000      	CHKVECT:.word	0		;address of check vector.
2484    0DBF  0000      	ALOCVECT: .word	0		;address of allocation vector (bit map).
2485                    	;
2486                    	;   Parameter block returned from the bios.
2487                    	;
2488    0DC1  0000      	SECTORS:.word	0		;sectors per track from bios.
2489    0DC3  00        	BLKSHFT:.byte	0		;block shift.
2490    0DC4  00        	BLKMASK:.byte	0		;block mask.
2491    0DC5  00        	EXTMASK:.byte	0		;extent mask.
2492    0DC6  0000      	DSKSIZE:.word	0		;disk size from bios (number of blocks-1).
2493    0DC8  0000      	DIRSIZE:.word	0		;directory size.
2494    0DCA  0000      	ALLOC0:	.word	0		;storage for first bytes of bit map (dir space used).
2495    0DCC  0000      	ALLOC1:	.word	0
2496    0DCE  0000      	OFFSET:	.word	0		;first usable track number.
2497    0DD0  0000      	XLATE:	.word	0		;sector translation table address.
2498                    	;
2499                    	;
2500    0DD2  00        	CLOSEFLG: .byte	0		;close flag (=0ffh is extent written ok).
2501    0DD3  00        	RDWRTFLG: .byte	0		;read/write flag (0ffh=read, 0=write).
2502    0DD4  00        	FNDSTAT:.byte	0		;filename found status (0=found first entry).
2503    0DD5  00        	MODE:	.byte	0		;I/o mode select (0=random, 1=sequential, 2=special random).
2504    0DD6  00        	EPARAM:	.byte	0		;storage for register (E) on entry to bdos.
2505    0DD7  00        	RELBLOCK: .byte	0		;relative position within fcb of block number written.
2506    0DD8  00        	COUNTER:.byte	0		;byte counter for directory name searches.
2507    0DD9  00000000  	SAVEFCB:.word	0,0		;save space for address of fcb (for directory searches).
2508    0DDD  00        	BIGDISK:.byte	0		;if =0 then disk is > 256 blocks long.
2509    0DDE  00        	AUTO:	.byte	0		;if non-zero, then auto select activated.
2510    0DDF  00        	OLDDRV:	.byte	0		;on auto select, storage for previous drive.
2511    0DE0  00        	AUTOFLAG: .byte	0		;if non-zero, then auto select changed drives.
2512    0DE1  00        	SAVNXT:	.byte	0		;storage for next record number to access.
2513    0DE2  00        	SAVEXT:	.byte	0		;storage for extent number of file.
2514    0DE3  0000      	SAVNREC:.word	0		;storage for number of records in file.
2515    0DE5  0000      	BLKNMBR:.word	0		;block number (physical sector) used within a file or logical sect
2516    0DE7  0000      	LOGSECT:.word	0		;starting logical (128 byte) sector of block (physical sector).
2517    0DE9  00        	FCBPOS:	.byte	0		;relative position within buffer for fcb of file of interest.
2518    0DEA  0000      	FILEPOS:.word	0		;files position within directory (0 to max entries -1).
2519                    	;
2520                    	;   Disk directory buffer checksum bytes. One for each of the
2521                    	; 16 possible drives.
2522                    	;
2523    0DEC  00000000  	CKSUMTBL: .byte	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              00000000
              00000000
              00000000
2524                    	;
2525                    	
2526                    	; Fill with zeroes up to BDOSSIZE
2527    0DFC  00000000  	bdospad: .byte 0 (BDOSSIZE - (bdospad - BDOSSTART))
2528                    	
2529                    		.end
2530                    	
