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
  15                    	; Modified for Whitesmiths/COSMIC x80 assembler ant tools for Z80
  16                    	;
  17                    	; You are free to use, modify, and redistribute
  18                    	; the source code implementing the modifications.
  19                    	; No warranties are given.
  20                    	; The adoptions were Hastily Cobbled Together 2022
  21                    	; by Hans-Ake Lund
  22                    	;
  65                    	.include "cpm.inc"
  24                    	
  25                    	.external BDOSSTART
  26                    	;
  27                    	;   Set origin for CP/M
  28                    	;
  29                    	;	ORG	CCP ;this is defined al link time
  30                    	;
  31                    	CBASE:
  32                    	CCPSTART:
  33    0000  C31303    		JP	COMMAND		;execute command processor (ccp).
  34    0003  C30F03    		JP	CLEARBUF	;entry to empty input buffer before starting ccp.
  35                    	
  36                    	;
  37                    	;   Standard cp/m ccp input buffer. Format is (max length),
  38                    	; (actual length), (char #1), (char #2), (char #3), etc.
  39                    	;
  40    0006  7F        	INBUFF:	.byte	127		;length of input buffer.
  41    0007  00        		.byte	0		;current length of contents.
  42    0008  20202020  		.byte	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
              20202020
              20202020
              20202020
  43    0018  434F5059  		.byte	'C','O','P','Y','R','I','G','H','T'
              52494748
              54
  44    0021  20284329  		.byte	' ','(','C',')',' ','1','9','7','9',',',' '
              20313937
              392C20
  45    002C  44494749  		.byte	'D','I','G','I','T','A','L',' ','R','E','S','E','A','R','C','H',' ',' '
              54414C20
              52455345
              41524348
              2020
  46                    	inbufend:
  47    003E  4A        		.byte	128-(inbufend-INBUFF)+2
  48    003F  0800      	INPOINT:.word	INBUFF+2	;input line pointer
  49    0041  0000      	NAMEPNT:.word	0		;input line pointer used for error message. Points to
  50                    	;			;start of name in error.
  51                    	;
  52                    	;   Routine to print (A) on the console. All registers used.
  53                    	;
  54    0043  5F        	PRINT:	LD	E,A		;setup bdos call.
  55    0044  0E02      		LD	C,2
  56    0046  C30500    		JP	ENTRY
  57                    	;
  58                    	;   Routine to print (A) on the console and to save (BC).
  59                    	;
  60    0049  C5        	PRINTB:	PUSH	BC
  61    004A  CD4300    		CALL	PRINT
  62    004D  C1        		POP	BC
  63    004E  C9        		RET	
  64                    	;
  65                    	;   Routine to send a carriage return, line feed combination
  66                    	; to the console.
  67                    	;
  68    004F  3E0D      	CRLF:	LD	A,CR
  69    0051  CD4900    		CALL	PRINTB
  70    0054  3E0A      		LD	A,LF
  71    0056  C34900    		JP	PRINTB
  72                    	;
  73                    	;   Routine to send one space to the console and save (BC).
  74                    	;
  75    0059  3E20      	SPACE:	LD	A,' '
  76    005B  C34900    		JP	PRINTB
  77                    	;
  78                    	;   Routine to print character string pointed to be (BC) on the
  79                    	; console. It must terminate with a null byte.
  80                    	;
  81    005E  C5        	PLINE:	PUSH	BC
  82    005F  CD4F00    		CALL	CRLF
  83    0062  E1        		POP	HL
  84    0063  7E        	PLINE2:	LD	A,(HL)
  85    0064  B7        		OR	A
  86    0065  C8        		RET	Z
  87    0066  23        		INC	HL
  88    0067  E5        		PUSH	HL
  89    0068  CD4300    		CALL	PRINT
  90    006B  E1        		POP	HL
  91    006C  C36300    		JP	PLINE2
  92                    	;
  93                    	;   Routine to reset the disk system.
  94                    	;
  95    006F  0E0D      	RESDSK:	LD	C,13
  96    0071  C30500    		JP	ENTRY
  97                    	;
  98                    	;   Routine to select disk (A).
  99                    	;
 100    0074  5F        	DSKSEL:	LD	E,A
 101    0075  0E0E      		LD	C,14
 102    0077  C30500    		JP	ENTRY
 103                    	;
 104                    	;   Routine to call bdos and save the return code. The zero
 105                    	; flag is set on a return of 0ffh.
 106                    	;
 107    007A  CD0500    	ENTRY1:	CALL	ENTRY
 108    007D  32A507    		LD	(RTNCODE),A	;save return code.
 109    0080  3C        		INC	A		;set zero if 0ffh returned.
 110    0081  C9        		RET	
 111                    	;
 112                    	;   Routine to open a file. (DE) must point to the FCB.
 113                    	;
 114    0082  0E0F      	OPEN:	LD	C,15
 115    0084  C37A00    		JP	ENTRY1
 116                    	;
 117                    	;   Routine to open file at (FCB).
 118                    	;
 119    0087  AF        	OPENFCB:XOR	A		;clear the record number byte at fcb+32
 120    0088  32A407    		LD	(FCB+32),A
 121    008B  118407    		LD	DE,FCB
 122    008E  C38200    		JP	OPEN
 123                    	;
 124                    	;   Routine to close a file. (DE) points to FCB.
 125                    	;
 126    0091  0E10      	CLOSE:	LD	C,16
 127    0093  C37A00    		JP	ENTRY1
 128                    	;
 129                    	;   Routine to search for the first file with ambigueous name
 130                    	; (DE).
 131                    	;
 132    0096  0E11      	SRCHFST:LD	C,17
 133    0098  C37A00    		JP	ENTRY1
 134                    	;
 135                    	;   Search for the next ambigeous file name.
 136                    	;
 137    009B  0E12      	SRCHNXT:LD	C,18
 138    009D  C37A00    		JP	ENTRY1
 139                    	;
 140                    	;   Search for file at (FCB).
 141                    	;
 142    00A0  118407    	SRCHFCB:LD	DE,FCB
 143    00A3  C39600    		JP	SRCHFST
 144                    	;
 145                    	;   Routine to delete a file pointed to by (DE).
 146                    	;
 147    00A6  0E13      	DELETE:	LD	C,19
 148    00A8  C30500    		JP	ENTRY
 149                    	;
 150                    	;   Routine to call the bdos and set the zero flag if a zero
 151                    	; status is returned.
 152                    	;
 153    00AB  CD0500    	ENTRY2:	CALL	ENTRY
 154    00AE  B7        		OR	A		;set zero flag if appropriate.
 155    00AF  C9        		RET	
 156                    	;
 157                    	;   Routine to read the next record from a sequential file.
 158                    	; (DE) points to the FCB.
 159                    	;
 160    00B0  0E14      	RDREC:	LD	C,20
 161    00B2  C3AB00    		JP	ENTRY2
 162                    	;
 163                    	;   Routine to read file at (FCB).
 164                    	;
 165    00B5  118407    	READFCB:LD	DE,FCB
 166    00B8  C3B000    		JP	RDREC
 167                    	;
 168                    	;   Routine to write the next record of a sequential file.
 169                    	; (DE) points to the FCB.
 170                    	;
 171    00BB  0E15      	WRTREC:	LD	C,21
 172    00BD  C3AB00    		JP	ENTRY2
 173                    	;
 174                    	;   Routine to create the file pointed to by (DE).
 175                    	;
 176    00C0  0E16      	CREATE:	LD	C,22
 177    00C2  C37A00    		JP	ENTRY1
 178                    	;
 179                    	;   Routine to rename the file pointed to by (DE). Note that
 180                    	; the new name starts at (DE+16).
 181                    	;
 182    00C5  0E17      	RENAM:	LD	C,23
 183    00C7  C30500    		JP	ENTRY
 184                    	;
 185                    	;   Get the current user code.
 186                    	;
 187    00CA  1EFF      	GETUSR:	LD	E,0FFh
 188                    	;
 189                    	;   Routne to get or set the current user code.
 190                    	; If (E) is FF then this is a GET, else it is a SET.
 191                    	;
 192    00CC  0E20      	GETSETUC: LD	C,32
 193    00CE  C30500    		JP	ENTRY
 194                    	;
 195                    	;   Routine to set the current drive byte at (TDRIVE).
 196                    	;
 197    00D1  CDCA00    	SETCDRV:CALL	GETUSR		;get user number
 198    00D4  87        		ADD	A,A		;and shift into the upper 4 bits.
 199    00D5  87        		ADD	A,A
 200    00D6  87        		ADD	A,A
 201    00D7  87        		ADD	A,A
 202    00D8  21A607    		LD	HL,CDRIVE	;now add in the current drive number.
 203    00DB  B6        		OR	(HL)
 204    00DC  320400    		LD	(TDRIVE),A	;and save.
 205    00DF  C9        		RET	
 206                    	;
 207                    	;   Move currently active drive down to (TDRIVE).
 208                    	;
 209    00E0  3AA607    	MOVECD:	LD	A,(CDRIVE)
 210    00E3  320400    		LD	(TDRIVE),A
 211    00E6  C9        		RET	
 212                    	;
 213                    	;   Routine to convert (A) into upper case ascii. Only letters
 214                    	; are affected.
 215                    	;
 216    00E7  FE61      	UPPER:	CP	'a'		;check for letters in the range of 'a' to 'z'.
 217    00E9  D8        		RET	C
 218    00EA  FE7B      		CP	'{'
 219    00EC  D0        		RET	NC
 220    00ED  E65F      		AND	5Fh		;convert it if found.
 221    00EF  C9        		RET	
 222                    	;
 223                    	;   Routine to get a line of input. We must check to see if the
 224                    	; user is in (BATCH) mode. If so, then read the input from file
 225                    	; ($$$.SUB). At the end, reset to console input.
 226                    	;
 227    00F0  3A6207    	GETINP:	LD	A,(BATCH)	;if =0, then use console input.
 228    00F3  B7        		OR	A
 229    00F4  CA4D01    		JP	Z,GETINP1
 230                    	;
 231                    	;   Use the submit file ($$$.sub) which is prepared by a
 232                    	; SUBMIT run. It must be on drive (A) and it will be deleted
 233                    	; if and error occures (like eof).
 234                    	;
 235    00F7  3AA607    		LD	A,(CDRIVE)	;select drive 0 if need be.
 236    00FA  B7        		OR	A
 237    00FB  3E00      		LD	A,0		;always use drive A for submit.
 238    00FD  C47400    		CALL	NZ,DSKSEL	;select it if required.
 239    0100  116307    		LD	DE,BATCHFCB
 240    0103  CD8200    		CALL	OPEN		;look for it.
 241    0106  CA4D01    		JP	Z,GETINP1	;if not there, use normal input.
 242    0109  3A7207    		LD	A,(BATCHFCB+15)	;get last record number+1.
 243    010C  3D        		DEC	A
 244    010D  328307    		LD	(BATCHFCB+32),A
 245    0110  116307    		LD	DE,BATCHFCB
 246    0113  CDB000    		CALL	RDREC		;read last record.
 247    0116  C24D01    		JP	NZ,GETINP1	;quit on end of file.
 248                    	;
 249                    	;   Move this record into input buffer.
 250                    	;
 251    0119  110700    		LD	DE,INBUFF+1
 252    011C  218000    		LD	HL,TBUFF	;data was read into buffer here.
 253    011F  0680      		LD	B,128		;all 128 characters may be used.
 254    0121  CDF903    		CALL	HL2DE		;(HL) to (DE), (B) bytes.
 255    0124  217107    		LD	HL,BATCHFCB+14
 256    0127  3600      		LD	(HL),0		;zero out the 's2' byte.
 257    0129  23        		INC	HL		;and decrement the record count.
 258    012A  35        		DEC	(HL)
 259    012B  116307    		LD	DE,BATCHFCB	;close the batch file now.
 260    012E  CD9100    		CALL	CLOSE
 261    0131  CA4D01    		JP	Z,GETINP1	;quit on an error.
 262    0134  3AA607    		LD	A,(CDRIVE)	;re-select previous drive if need be.
 263    0137  B7        		OR	A
 264    0138  C47400    		CALL	NZ,DSKSEL	;don't do needless selects.
 265                    	;
 266                    	;   Print line just read on console.
 267                    	;
 268    013B  210800    		LD	HL,INBUFF+2
 269    013E  CD6300    		CALL	PLINE2
 270    0141  CD7901    		CALL	CHKCON		;check console, quit on a key.
 271    0144  CA5E01    		JP	Z,GETINP2	;jump if no key is pressed.
 272                    	;
 273                    	;   Terminate the submit job on any keyboard input. Delete this
 274                    	; file such that it is not re-started and jump to normal keyboard
 275                    	; input section.
 276                    	;
 277    0147  CD9401    		CALL	DELBATCH	;delete the batch file.
 278    014A  C33903    		JP	CMMND1		;and restart command input.
 279                    	;
 280                    	;   Get here for normal keyboard input. Delete the submit file
 281                    	; incase there was one.
 282                    	;
 283    014D  CD9401    	GETINP1:CALL	DELBATCH	;delete file ($$$.sub).
 284    0150  CDD100    		CALL	SETCDRV		;reset active disk.
 285    0153  0E0A      		LD	C,10		;get line from console device.
 286    0155  110600    		LD	DE,INBUFF
 287    0158  CD0500    		CALL	ENTRY
 288    015B  CDE000    		CALL	MOVECD		;reset current drive (again).
 289                    	;
 290                    	;   Convert input line to upper case.
 291                    	;
 292    015E  210700    	GETINP2:LD	HL,INBUFF+1
 293    0161  46        		LD	B,(HL)		;(B)=character counter.
 294    0162  23        	GETINP3:INC	HL
 295    0163  78        		LD	A,B		;end of the line?
 296    0164  B7        		OR	A
 297    0165  CA7101    		JP	Z,GETINP4
 298    0168  7E        		LD	A,(HL)		;convert to upper case.
 299    0169  CDE700    		CALL	UPPER
 300    016C  77        		LD	(HL),A
 301    016D  05        		DEC	B		;adjust character count.
 302    016E  C36201    		JP	GETINP3
 303    0171  77        	GETINP4:LD	(HL),A		;add trailing null.
 304    0172  210800    		LD	HL,INBUFF+2
 305    0175  223F00    		LD	(INPOINT),HL	;reset input line pointer.
 306    0178  C9        		RET	
 307                    	;
 308                    	;   Routine to check the console for a key pressed. The zero
 309                    	; flag is set is none, else the character is returned in (A).
 310                    	;
 311    0179  0E0B      	CHKCON:	LD	C,11		;check console.
 312    017B  CD0500    		CALL	ENTRY
 313    017E  B7        		OR	A
 314    017F  C8        		RET	Z		;return if nothing.
 315    0180  0E01      		LD	C,1		;else get character.
 316    0182  CD0500    		CALL	ENTRY
 317    0185  B7        		OR	A		;clear zero flag and return.
 318    0186  C9        		RET	
 319                    	;
 320                    	;   Routine to get the currently active drive number.
 321                    	;
 322    0187  0E19      	GETDSK:	LD	C,25
 323    0189  C30500    		JP	ENTRY
 324                    	;
 325                    	;   Set the stabdard dma address.
 326                    	;
 327    018C  118000    	STDDMA:	LD	DE,TBUFF
 328                    	;
 329                    	;   Routine to set the dma address to (DE).
 330                    	;
 331    018F  0E1A      	DMASET:	LD	C,26
 332    0191  C30500    		JP	ENTRY
 333                    	;
 334                    	;  Delete the batch file created by SUBMIT.
 335                    	;
 336    0194  216207    	DELBATCH: LD	HL,BATCH	;is batch active?
 337    0197  7E        		LD	A,(HL)
 338    0198  B7        		OR	A
 339    0199  C8        		RET	Z
 340    019A  3600      		LD	(HL),0		;yes, de-activate it.
 341    019C  AF        		XOR	A
 342    019D  CD7400    		CALL	DSKSEL		;select drive 0 for sure.
 343    01A0  116307    		LD	DE,BATCHFCB	;and delete this file.
 344    01A3  CDA600    		CALL	DELETE
 345    01A6  3AA607    		LD	A,(CDRIVE)	;reset current drive.
 346    01A9  C37400    		JP	DSKSEL
 347                    	;
 348                    	;   Check to two strings at (PATTRN1) and (PATTRN2). They must be
 349                    	; the same or we halt....
 350                    	;
 351    01AC  11DF02    	VERIFY:	LD	DE,PATTRN1	;these are the serial number bytes.
 352    01AF  210000    		LD	HL,BDOSSTART	;ditto, but how could they be different?
 353    01B2  0606      		LD	B,6		;6 bytes each.
 354    01B4  1A        	VERIFY1:LD	A,(DE)
 355    01B5  BE        		CP	(HL)
 356    01B6  C28603    		JP	NZ,HALTSYS	;jump to halt routine.
 357    01B9  13        		INC	DE
 358    01BA  23        		INC	HL
 359    01BB  05        		DEC	B
 360    01BC  C2B401    		JP	NZ,VERIFY1
 361    01BF  C9        		RET	
 362                    	;
 363                    	;   Print back file name with a '?' to indicate a syntax error.
 364                    	;
 365    01C0  CD4F00    	SYNERR:	CALL	CRLF		;end current line.
 366    01C3  2A4100    		LD	HL,(NAMEPNT)	;this points to name in error.
 367    01C6  7E        	SYNERR1:LD	A,(HL)		;print it until a space or null is found.
 368    01C7  FE20      		CP	' '
 369    01C9  CAD901    		JP	Z,SYNERR2
 370    01CC  B7        		OR	A
 371    01CD  CAD901    		JP	Z,SYNERR2
 372    01D0  E5        		PUSH	HL
 373    01D1  CD4300    		CALL	PRINT
 374    01D4  E1        		POP	HL
 375    01D5  23        		INC	HL
 376    01D6  C3C601    		JP	SYNERR1
 377    01D9  3E3F      	SYNERR2:LD	A,'?'		;add trailing '?'.
 378    01DB  CD4300    		CALL	PRINT
 379    01DE  CD4F00    		CALL	CRLF
 380    01E1  CD9401    		CALL	DELBATCH	;delete any batch file.
 381    01E4  C33903    		JP	CMMND1		;and restart from console input.
 382                    	;
 383                    	;   Check character at (DE) for legal command input. Note that the
 384                    	; zero flag is set if the character is a delimiter.
 385                    	;
 386    01E7  1A        	CHECK:	LD	A,(DE)
 387    01E8  B7        		OR	A
 388    01E9  C8        		RET	Z
 389    01EA  FE20      		CP	' '		;control characters are not legal here.
 390    01EC  DAC001    		JP	C,SYNERR
 391    01EF  C8        		RET	Z		;check for valid delimiter.
 392    01F0  FE3D      		CP	'='
 393    01F2  C8        		RET	Z
 394    01F3  FE5F      		CP	'_'
 395    01F5  C8        		RET	Z
 396    01F6  FE2E      		CP	'.'
 397    01F8  C8        		RET	Z
 398    01F9  FE3A      		CP	':'
 399    01FB  C8        		RET	Z
 400    01FC  FE3B      		CP	';'
 401    01FE  C8        		RET	Z
 402    01FF  FE3C      		CP	'<'
 403    0201  C8        		RET	Z
 404    0202  FE3E      		CP	'>'
 405    0204  C8        		RET	Z
 406    0205  C9        		RET	
 407                    	;
 408                    	;   Get the next non-blank character from (DE).
 409                    	;
 410    0206  1A        	NONBLANK: LD	A,(DE)
 411    0207  B7        		OR	A		;string ends with a null.
 412    0208  C8        		RET	Z
 413    0209  FE20      		CP	' '
 414    020B  C0        		RET	NZ
 415    020C  13        		INC	DE
 416    020D  C30602    		JP	NONBLANK
 417                    	;
 418                    	;   Add (HL)=(HL)+(A)
 419                    	;
 420    0210  85        	ADDHL:	ADD	A,L
 421    0211  6F        		LD	L,A
 422    0212  D0        		RET	NC		;take care of any carry.
 423    0213  24        		INC	H
 424    0214  C9        		RET	
 425                    	;
 426                    	;   Convert the first name in (FCB).
 427                    	;
 428    0215  3E00      	CONVFST:LD	A,0
 429                    	;
 430                    	;   Format a file name (convert * to '?', etc.). On return,
 431                    	; (A)=0 is an unambigeous name was specified. Enter with (A) equal to
 432                    	; the position within the fcb for the name (either 0 or 16).
 433                    	;
 434    0217  218407    	CONVERT:LD	HL,FCB
 435    021A  CD1002    		CALL	ADDHL
 436    021D  E5        		PUSH	HL
 437    021E  E5        		PUSH	HL
 438    021F  AF        		XOR	A
 439    0220  32A707    		LD	(CHGDRV),A	;initialize drive change flag.
 440    0223  2A3F00    		LD	HL,(INPOINT)	;set (HL) as pointer into input line.
 441    0226  EB        		EX	DE,HL
 442    0227  CD0602    		CALL	NONBLANK	;get next non-blank character.
 443    022A  EB        		EX	DE,HL
 444    022B  224100    		LD	(NAMEPNT),HL	;save pointer here for any error message.
 445    022E  EB        		EX	DE,HL
 446    022F  E1        		POP	HL
 447    0230  1A        		LD	A,(DE)		;get first character.
 448    0231  B7        		OR	A
 449    0232  CA4002    		JP	Z,CONVRT1
 450    0235  DE40      		SBC	A,'A'-1		;might be a drive name, convert to binary.
 451    0237  47        		LD	B,A		;and save.
 452    0238  13        		INC	DE		;check next character for a ':'.
 453    0239  1A        		LD	A,(DE)
 454    023A  FE3A      		CP	':'
 455    023C  CA4702    		JP	Z,CONVRT2
 456    023F  1B        		DEC	DE		;nope, move pointer back to the start of the line.
 457    0240  3AA607    	CONVRT1:LD	A,(CDRIVE)
 458    0243  77        		LD	(HL),A
 459    0244  C34D02    		JP	CONVRT3
 460    0247  78        	CONVRT2:LD	A,B
 461    0248  32A707    		LD	(CHGDRV),A	;set change in drives flag.
 462    024B  70        		LD	(HL),B
 463    024C  13        		INC	DE
 464                    	;
 465                    	;   Convert the basic file name.
 466                    	;
 467    024D  0608      	CONVRT3:LD	B,08h
 468    024F  CDE701    	CONVRT4:CALL	CHECK
 469    0252  CA7002    		JP	Z,CONVRT8
 470    0255  23        		INC	HL
 471    0256  FE2A      		CP	'*'		;note that an '*' will fill the remaining
 472    0258  C26002    		JP	NZ,CONVRT5	;field with '?'.
 473    025B  363F      		LD	(HL),'?'
 474    025D  C36202    		JP	CONVRT6
 475    0260  77        	CONVRT5:LD	(HL),A
 476    0261  13        		INC	DE
 477    0262  05        	CONVRT6:DEC	B
 478    0263  C24F02    		JP	NZ,CONVRT4
 479    0266  CDE701    	CONVRT7:CALL	CHECK		;get next delimiter.
 480    0269  CA7702    		JP	Z,GETEXT
 481    026C  13        		INC	DE
 482    026D  C36602    		JP	CONVRT7
 483    0270  23        	CONVRT8:INC	HL		;blank fill the file name.
 484    0271  3620      		LD	(HL),' '
 485    0273  05        		DEC	B
 486    0274  C27002    		JP	NZ,CONVRT8
 487                    	;
 488                    	;   Get the extension and convert it.
 489                    	;
 490    0277  0603      	GETEXT:	LD	B,03h
 491    0279  FE2E      		CP	'.'
 492    027B  C2A002    		JP	NZ,GETEXT5
 493    027E  13        		INC	DE
 494    027F  CDE701    	GETEXT1:CALL	CHECK
 495    0282  CAA002    		JP	Z,GETEXT5
 496    0285  23        		INC	HL
 497    0286  FE2A      		CP	'*'
 498    0288  C29002    		JP	NZ,GETEXT2
 499    028B  363F      		LD	(HL),'?'
 500    028D  C39202    		JP	GETEXT3
 501    0290  77        	GETEXT2:LD	(HL),A
 502    0291  13        		INC	DE
 503    0292  05        	GETEXT3:DEC	B
 504    0293  C27F02    		JP	NZ,GETEXT1
 505    0296  CDE701    	GETEXT4:CALL	CHECK
 506    0299  CAA702    		JP	Z,GETEXT6
 507    029C  13        		INC	DE
 508    029D  C39602    		JP	GETEXT4
 509    02A0  23        	GETEXT5:INC	HL
 510    02A1  3620      		LD	(HL),' '
 511    02A3  05        		DEC	B
 512    02A4  C2A002    		JP	NZ,GETEXT5
 513    02A7  0603      	GETEXT6:LD	B,3
 514    02A9  23        	GETEXT7:INC	HL
 515    02AA  3600      		LD	(HL),0
 516    02AC  05        		DEC	B
 517    02AD  C2A902    		JP	NZ,GETEXT7
 518    02B0  EB        		EX	DE,HL
 519    02B1  223F00    		LD	(INPOINT),HL	;save input line pointer.
 520    02B4  E1        		POP	HL
 521                    	;
 522                    	;   Check to see if this is an ambigeous file name specification.
 523                    	; Set the (A) register to non zero if it is.
 524                    	;
 525    02B5  010B00    		LD	BC,11		;set name length.
 526    02B8  23        	GETEXT8:INC	HL
 527    02B9  7E        		LD	A,(HL)
 528    02BA  FE3F      		CP	'?'		;any question marks?
 529    02BC  C2C002    		JP	NZ,GETEXT9
 530    02BF  04        		INC	B		;count them.
 531    02C0  0D        	GETEXT9:DEC	C
 532    02C1  C2B802    		JP	NZ,GETEXT8
 533    02C4  78        		LD	A,B
 534    02C5  B7        		OR	A
 535    02C6  C9        		RET	
 536                    	;
 537                    	;   CP/M command table. Note commands can be either 3 or 4 characters long.
 538                    	;
 539                    	.define NUMCMDS =	6		;number of commands
 540    02C7  44495220  	CMDTBL:	.byte	'D','I','R',' '
 541    02CB  45524120  		.byte	'E','R','A',' '
 542    02CF  54595045  		.byte	'T','Y','P','E'
 543    02D3  53415645  		.byte	'S','A','V','E'
 544    02D7  52454E20  		.byte	'R','E','N',' '
 545    02DB  55534552  		.byte	'U','S','E','R'
 546                    	;
 547                    	;   The following six bytes must agree with those at (PATTRN2)
 548                    	; or cp/m will HALT. Why?
 549                    	;
 550    02DF  09590000  	PATTRN1:.byte	09h,59h,00h,00h,07h,89h ;(* serial number bytes *).
              0789
 551                    	;
 552                    	;   Search the command table for a match with what has just
 553                    	; been entered. If a match is found, then we jump to the
 554                    	; proper section. Else jump to (UNKNOWN).
 555                    	; On return, the (C) register is set to the command number
 556                    	; that matched (or NUMCMDS+1 if no match).
 557                    	;
 558    02E5  21C702    	SEARCH:	LD	HL,CMDTBL
 559    02E8  0E00      		LD	C,0
 560    02EA  79        	SEARCH1:LD	A,C
 561    02EB  FE06      		CP	NUMCMDS		;this commands exists.
 562    02ED  D0        		RET	NC
 563    02EE  118507    		LD	DE,FCB+1	;check this one.
 564    02F1  0604      		LD	B,4		;max command length.
 565    02F3  1A        	SEARCH2:LD	A,(DE)
 566    02F4  BE        		CP	(HL)
 567    02F5  C20603    		JP	NZ,SEARCH3	;not a match.
 568    02F8  13        		INC	DE
 569    02F9  23        		INC	HL
 570    02FA  05        		DEC	B
 571    02FB  C2F302    		JP	NZ,SEARCH2
 572    02FE  1A        		LD	A,(DE)		;allow a 3 character command to match.
 573    02FF  FE20      		CP	' '
 574    0301  C20B03    		JP	NZ,SEARCH4
 575    0304  79        		LD	A,C		;set return register for this command.
 576    0305  C9        		RET	
 577    0306  23        	SEARCH3:INC	HL
 578    0307  05        		DEC	B
 579    0308  C20603    		JP	NZ,SEARCH3
 580    030B  0C        	SEARCH4:INC	C
 581    030C  C3EA02    		JP	SEARCH1
 582                    	;
 583                    	;   Set the input buffer to empty and then start the command
 584                    	; processor (ccp).
 585                    	;
 586    030F  AF        	CLEARBUF: XOR	A
 587    0310  320700    		LD	(INBUFF+1),A	;second byte is actual length.
 588                    	;
 589                    	;**************************************************************
 590                    	;*
 591                    	;*
 592                    	;* C C P  -   C o n s o l e   C o m m a n d   P r o c e s s o r
 593                    	;*
 594                    	;**************************************************************
 595                    	;*
 596    0313  316207    	COMMAND:LD	SP,CCPSTACK	;setup stack area.
 597                    	;    PRTPROB '1'
 598    0316  C5        		PUSH	BC		;note that (C) should be equal to:
 599    0317  79        		LD	A,C		;(uuuudddd) where 'uuuu' is the user number
 600    0318  1F        		RRA			;and 'dddd' is the drive number.
 601    0319  1F        		RRA	
 602    031A  1F        		RRA	
 603    031B  1F        		RRA	
 604    031C  E60F      		AND	0Fh		;isolate the user number.
 605    031E  5F        		LD	E,A
 606    031F  CDCC00    		CALL	GETSETUC	;and set it.
 607                    	;    PRTPROB '2'
 608    0322  CD6F00    		CALL	RESDSK		;reset the disk system.
 609                    	;    PRTPROB '3'
 610    0325  326207    		LD	(BATCH),A	;clear batch mode flag.
 611    0328  C1        		POP	BC
 612    0329  79        		LD	A,C
 613    032A  E60F      		AND	0Fh		;isolate the drive number.
 614    032C  32A607    		LD	(CDRIVE),A	;and save.
 615    032F  CD7400    		CALL	DSKSEL		;...and select.
 616                    	;    PRTPROB '4'
 617    0332  3A0700    		LD	A,(INBUFF+1)
 618    0335  B7        		OR	A		;anything in input buffer already?
 619    0336  C24F03    		JP	NZ,CMMND2	;yes, we just process it.
 620                    	;
 621                    	;   Entry point to get a command line from the console.
 622                    	;
 623    0339  316207    	CMMND1:	LD	SP,CCPSTACK	;set stack straight.
 624    033C  CD4F00    		CALL	CRLF		;start a new line on the screen.
 625                    	;    PRTPROB '5'
 626    033F  CD8701    		CALL	GETDSK		;get current drive.
 627    0342  C641      		ADD	A,'A'
 628    0344  CD4300    		CALL	PRINT		;print current drive.
 629    0347  3E3E      		LD	A,'>'
 630    0349  CD4300    		CALL	PRINT		;and add prompt.
 631    034C  CDF000    		CALL	GETINP		;get line from user.
 632                    	;
 633                    	;   Process command line here.
 634                    	;
 635    034F  118000    	CMMND2:	LD	DE,TBUFF
 636    0352  CD8F01    		CALL	DMASET		;set standard dma address.
 637    0355  CD8701    		CALL	GETDSK
 638    0358  32A607    		LD	(CDRIVE),A	;set current drive.
 639    035B  CD1502    		CALL	CONVFST		;convert name typed in.
 640    035E  C4C001    		CALL	NZ,SYNERR	;wild cards are not allowed.
 641    0361  3AA707    		LD	A,(CHGDRV)	;if a change in drives was indicated,
 642    0364  B7        		OR	A		;then treat this as an unknown command
 643    0365  C25C06    		JP	NZ,UNKNOWN	;which gets executed.
 644    0368  CDE502    		CALL	SEARCH		;else search command table for a match.
 645                    	;
 646                    	;   Note that an unknown command returns
 647                    	; with (A) pointing to the last address
 648                    	; in our table which is (UNKNOWN).
 649                    	;
 650    036B  217803    		LD	HL,CMDADR	;now, look thru our address table for command (A).
 651    036E  5F        		LD	E,A		;set (DE) to command number.
 652    036F  1600      		LD	D,0
 653    0371  19        		ADD	HL,DE
 654    0372  19        		ADD	HL,DE		;(HL)=(CMDADR)+2*(command number).
 655    0373  7E        		LD	A,(HL)		;now pick out this address.
 656    0374  23        		INC	HL
 657    0375  66        		LD	H,(HL)
 658    0376  6F        		LD	L,A
 659    0377  E9        		JP	(HL)		;now execute it.
 660                    	;
 661                    	;   CP/M command address table.
 662                    	;
 663    0378  2E04D604  	CMDADR:	.word	DIRECT,ERASE,TYPE,SAVE
              14056405
 664    0380  C7054506  		.word	RENAME,USER,UNKNOWN
              5C06
 665                    	;
 666                    	;   Halt the system. Reason for this is unknown at present.
 667                    	;
 668                    	HALTSYS:
 669    0386  21F376    		LD	HL,76F3h	;'DI HLT' instructions.
 670    0389  220000    		LD	(CCPSTART),HL
 671    038C  210000    		LD	HL,CCPSTART
 672    038F  E9        		JP	(HL)
 673                    	;
 674                    	;   Read error while TYPEing a file.
 675                    	;
 676    0390  019603    	RDERROR:LD	BC,RDERR
 677    0393  C35E00    		JP	PLINE
 678    0396  52454144  	RDERR:	.byte	'R','E','A','D',' ','E','R','R','O','R',0
              20455252
              4F5200
 679                    	;
 680                    	;   Required file was not located.
 681                    	;
 682    03A1  01A703    	NONE:	LD	BC,NOFILE
 683    03A4  C35E00    		JP	PLINE
 684    03A7  4E4F2046  	NOFILE:	.byte	'N','O',' ','F','I','L','E',0
              494C4500
 685                    	;
 686                    	;   Decode a command of the form 'A>filename number{ filename}.
 687                    	; Note that a drive specifier is not allowed on the first file
 688                    	; name. On return, the number is in register (A). Any error
 689                    	; causes 'filename?' to be printed and the command is aborted.
 690                    	;
 691    03AF  CD1502    	DECODE:	CALL	CONVFST		;convert filename.
 692    03B2  3AA707    		LD	A,(CHGDRV)	;do not allow a drive to be specified.
 693    03B5  B7        		OR	A
 694    03B6  C2C001    		JP	NZ,SYNERR
 695    03B9  218507    		LD	HL,FCB+1	;convert number now.
 696    03BC  010B00    		LD	BC,11		;(B)=sum register, (C)=max digit count.
 697    03BF  7E        	DECODE1:LD	A,(HL)
 698    03C0  FE20      		CP	' '		;a space terminates the numeral.
 699    03C2  CAEA03    		JP	Z,DECODE3
 700    03C5  23        		INC	HL
 701    03C6  D630      		SUB	'0'		;make binary from ascii.
 702    03C8  FE0A      		CP	10		;legal digit?
 703    03CA  D2C001    		JP	NC,SYNERR
 704    03CD  57        		LD	D,A		;yes, save it in (D).
 705    03CE  78        		LD	A,B		;compute (B)=(B)*10 and check for overflow.
 706    03CF  E6E0      		AND	0E0h
 707    03D1  C2C001    		JP	NZ,SYNERR
 708    03D4  78        		LD	A,B
 709    03D5  07        		RLCA	
 710    03D6  07        		RLCA	
 711    03D7  07        		RLCA			;(A)=(B)*8
 712    03D8  80        		ADD	A,B		;.......*9
 713    03D9  DAC001    		JP	C,SYNERR
 714    03DC  80        		ADD	A,B		;.......*10
 715    03DD  DAC001    		JP	C,SYNERR
 716    03E0  82        		ADD	A,D		;add in new digit now.
 717    03E1  DAC001    	DECODE2:JP	C,SYNERR
 718    03E4  47        		LD	B,A		;and save result.
 719    03E5  0D        		DEC	C		;only look at 11 digits.
 720    03E6  C2BF03    		JP	NZ,DECODE1
 721    03E9  C9        		RET	
 722    03EA  7E        	DECODE3:LD	A,(HL)		;spaces must follow (why?).
 723    03EB  FE20      		CP	' '
 724    03ED  C2C001    		JP	NZ,SYNERR
 725    03F0  23        		INC	HL
 726    03F1  0D        	DECODE4:DEC	C
 727    03F2  C2EA03    		JP	NZ,DECODE3
 728    03F5  78        		LD	A,B		;set (A)=the numeric value entered.
 729    03F6  C9        		RET	
 730                    	;
 731                    	;   Move 3 bytes from (HL) to (DE). Note that there is only
 732                    	; one reference to this at (A2D5h).
 733                    	;
 734    03F7  0603      	MOVE3:	LD	B,3
 735                    	;
 736                    	;   Move (B) bytes from (HL) to (DE).
 737                    	;
 738    03F9  7E        	HL2DE:	LD	A,(HL)
 739    03FA  12        		LD	(DE),A
 740    03FB  23        		INC	HL
 741    03FC  13        		INC	DE
 742    03FD  05        		DEC	B
 743    03FE  C2F903    		JP	NZ,HL2DE
 744    0401  C9        		RET	
 745                    	;
 746                    	;   Compute (HL)=(TBUFF)+(A)+(C) and get the byte that's here.
 747                    	;
 748    0402  218000    	EXTRACT:LD	HL,TBUFF
 749    0405  81        		ADD	A,C
 750    0406  CD1002    		CALL	ADDHL
 751    0409  7E        		LD	A,(HL)
 752    040A  C9        		RET	
 753                    	;
 754                    	;  Check drive specified. If it means a change, then the new
 755                    	; drive will be selected. In any case, the drive byte of the
 756                    	; fcb will be set to null (means use current drive).
 757                    	;
 758    040B  AF        	DSELECT:XOR	A		;null out first byte of fcb.
 759    040C  328407    		LD	(FCB),A
 760    040F  3AA707    		LD	A,(CHGDRV)	;a drive change indicated?
 761    0412  B7        		OR	A
 762    0413  C8        		RET	Z
 763    0414  3D        		DEC	A		;yes, is it the same as the current drive?
 764    0415  21A607    		LD	HL,CDRIVE
 765    0418  BE        		CP	(HL)
 766    0419  C8        		RET	Z
 767    041A  C37400    		JP	DSKSEL		;no. Select it then.
 768                    	;
 769                    	;   Check the drive selection and reset it to the previous
 770                    	; drive if it was changed for the preceeding command.
 771                    	;
 772    041D  3AA707    	RESETDR:LD	A,(CHGDRV)	;drive change indicated?
 773    0420  B7        		OR	A
 774    0421  C8        		RET	Z
 775    0422  3D        		DEC	A		;yes, was it a different drive?
 776    0423  21A607    		LD	HL,CDRIVE
 777    0426  BE        		CP	(HL)
 778    0427  C8        		RET	Z
 779    0428  3AA607    		LD	A,(CDRIVE)	;yes, re-select our old drive.
 780    042B  C37400    		JP	DSKSEL
 781                    	;
 782                    	;**************************************************************
 783                    	;*
 784                    	;*           D I R E C T O R Y   C O M M A N D
 785                    	;*
 786                    	;**************************************************************
 787                    	;
 788    042E  CD1502    	DIRECT:	CALL	CONVFST		;convert file name.
 789    0431  CD0B04    		CALL	DSELECT		;select indicated drive.
 790    0434  218507    		LD	HL,FCB+1	;was any file indicated?
 791    0437  7E        		LD	A,(HL)
 792    0438  FE20      		CP	' '
 793    043A  C24604    		JP	NZ,DIRECT2
 794    043D  060B      		LD	B,11		;no. Fill field with '?' - same as *.*.
 795    043F  363F      	DIRECT1:LD	(HL),'?'
 796    0441  23        		INC	HL
 797    0442  05        		DEC	B
 798    0443  C23F04    		JP	NZ,DIRECT1
 799    0446  1E00      	DIRECT2:LD	E,0		;set initial cursor position.
 800    0448  D5        		PUSH	DE
 801    0449  CDA000    		CALL	SRCHFCB		;get first file name.
 802    044C  CCA103    		CALL	Z,NONE		;none found at all?
 803    044F  CAD204    	DIRECT3:JP	Z,DIRECT9	;terminate if no more names.
 804    0452  3AA507    		LD	A,(RTNCODE)	;get file's position in segment (0-3).
 805    0455  0F        		RRCA	
 806    0456  0F        		RRCA	
 807    0457  0F        		RRCA	
 808    0458  E660      		AND	60h		;(A)=position*32
 809    045A  4F        		LD	C,A
 810    045B  3E0A      		LD	A,10
 811    045D  CD0204    		CALL	EXTRACT		;extract the tenth entry in fcb.
 812    0460  17        		RLA			;check system file status bit.
 813    0461  DAC604    		JP	C,DIRECT8	;we don't list them.
 814    0464  D1        		POP	DE
 815    0465  7B        		LD	A,E		;bump name count.
 816    0466  1C        		INC	E
 817    0467  D5        		PUSH	DE
 818    0468  E603      		AND	03h		;at end of line?
 819    046A  F5        		PUSH	AF
 820    046B  C28304    		JP	NZ,DIRECT4
 821    046E  CD4F00    		CALL	CRLF		;yes, end this line and start another.
 822    0471  C5        		PUSH	BC
 823    0472  CD8701    		CALL	GETDSK		;start line with ('A:').
 824    0475  C1        		POP	BC
 825    0476  C641      		ADD	A,'A'
 826    0478  CD4900    		CALL	PRINTB
 827    047B  3E3A      		LD	A,':'
 828    047D  CD4900    		CALL	PRINTB
 829    0480  C38B04    		JP	DIRECT5
 830    0483  CD5900    	DIRECT4:CALL	SPACE		;add seperator between file names.
 831    0486  3E3A      		LD	A,':'
 832    0488  CD4900    		CALL	PRINTB
 833    048B  CD5900    	DIRECT5:CALL	SPACE
 834    048E  0601      		LD	B,1		;'extract' each file name character at a time.
 835    0490  78        	DIRECT6:LD	A,B
 836    0491  CD0204    		CALL	EXTRACT
 837    0494  E67F      		AND	7Fh		;strip bit 7 (status bit).
 838    0496  FE20      		CP	' '		;are we at the end of the name?
 839    0498  C2B004    		JP	NZ,DRECT65
 840    049B  F1        		POP	AF		;yes, don't print spaces at the end of a line.
 841    049C  F5        		PUSH	AF
 842    049D  FE03      		CP	3
 843    049F  C2AE04    		JP	NZ,DRECT63
 844    04A2  3E09      		LD	A,9		;first check for no extension.
 845    04A4  CD0204    		CALL	EXTRACT
 846    04A7  E67F      		AND	7Fh
 847    04A9  FE20      		CP	' '
 848    04AB  CAC504    		JP	Z,DIRECT7	;don't print spaces.
 849    04AE  3E20      	DRECT63:LD	A,' '		;else print them.
 850    04B0  CD4900    	DRECT65:CALL	PRINTB
 851    04B3  04        		INC	B		;bump to next character psoition.
 852    04B4  78        		LD	A,B
 853    04B5  FE0C      		CP	12		;end of the name?
 854    04B7  D2C504    		JP	NC,DIRECT7
 855    04BA  FE09      		CP	9		;nope, starting extension?
 856    04BC  C29004    		JP	NZ,DIRECT6
 857    04BF  CD5900    		CALL	SPACE		;yes, add seperating space.
 858    04C2  C39004    		JP	DIRECT6
 859    04C5  F1        	DIRECT7:POP	AF		;get the next file name.
 860    04C6  CD7901    	DIRECT8:CALL	CHKCON		;first check console, quit on anything.
 861    04C9  C2D204    		JP	NZ,DIRECT9
 862    04CC  CD9B00    		CALL	SRCHNXT		;get next name.
 863    04CF  C34F04    		JP	DIRECT3		;and continue with our list.
 864    04D2  D1        	DIRECT9:POP	DE		;restore the stack and return to command level.
 865    04D3  C33D07    		JP	GETBACK
 866                    	;
 867                    	;**************************************************************
 868                    	;*
 869                    	;*                E R A S E   C O M M A N D
 870                    	;*
 871                    	;**************************************************************
 872                    	;
 873    04D6  CD1502    	ERASE:	CALL	CONVFST		;convert file name.
 874    04D9  FE0B      		CP	11		;was '*.*' entered?
 875    04DB  C2F904    		JP	NZ,ERASE1
 876    04DE  010905    		LD	BC,YESNO	;yes, ask for confirmation.
 877    04E1  CD5E00    		CALL	PLINE
 878    04E4  CDF000    		CALL	GETINP
 879    04E7  210700    		LD	HL,INBUFF+1
 880    04EA  35        		DEC	(HL)		;must be exactly 'y'.
 881    04EB  C23903    		JP	NZ,CMMND1
 882    04EE  23        		INC	HL
 883    04EF  7E        		LD	A,(HL)
 884    04F0  FE59      		CP	'Y'
 885    04F2  C23903    		JP	NZ,CMMND1
 886    04F5  23        		INC	HL
 887    04F6  223F00    		LD	(INPOINT),HL	;save input line pointer.
 888    04F9  CD0B04    	ERASE1:	CALL	DSELECT		;select desired disk.
 889    04FC  118407    		LD	DE,FCB
 890    04FF  CDA600    		CALL	DELETE		;delete the file.
 891    0502  3C        		INC	A
 892    0503  CCA103    		CALL	Z,NONE		;not there?
 893    0506  C33D07    		JP	GETBACK		;return to command level now.
 894    0509  414C4C20  	YESNO:	.byte	'A','L','L',' ','(','Y','/','N',')','?',0
              28592F4E
              293F00
 895                    	;
 896                    	;**************************************************************
 897                    	;*
 898                    	;*            T Y P E   C O M M A N D
 899                    	;*
 900                    	;**************************************************************
 901                    	;
 902    0514  CD1502    	TYPE:	CALL	CONVFST		;convert file name.
 903    0517  C2C001    		JP	NZ,SYNERR	;wild cards not allowed.
 904    051A  CD0B04    		CALL	DSELECT		;select indicated drive.
 905    051D  CD8700    		CALL	OPENFCB		;open the file.
 906    0520  CA5E05    		JP	Z,TYPE5		;not there?
 907    0523  CD4F00    		CALL	CRLF		;ok, start a new line on the screen.
 908    0526  21A807    		LD	HL,NBYTES	;initialize byte counter.
 909    0529  36FF      		LD	(HL),0FFh	;set to read first sector.
 910    052B  21A807    	TYPE1:	LD	HL,NBYTES
 911    052E  7E        	TYPE2:	LD	A,(HL)		;have we written the entire sector?
 912    052F  FE80      		CP	128
 913    0531  DA3E05    		JP	C,TYPE3
 914    0534  E5        		PUSH	HL		;yes, read in the next one.
 915    0535  CDB500    		CALL	READFCB
 916    0538  E1        		POP	HL
 917    0539  C25705    		JP	NZ,TYPE4	;end or error?
 918    053C  AF        		XOR	A		;ok, clear byte counter.
 919    053D  77        		LD	(HL),A
 920    053E  34        	TYPE3:	INC	(HL)		;count this byte.
 921    053F  218000    		LD	HL,TBUFF	;and get the (A)th one from the buffer (TBUFF).
 922    0542  CD1002    		CALL	ADDHL
 923    0545  7E        		LD	A,(HL)
 924    0546  FE1A      		CP	CNTRLZ		;end of file mark?
 925    0548  CA3D07    		JP	Z,GETBACK
 926    054B  CD4300    		CALL	PRINT		;no, print it.
 927    054E  CD7901    		CALL	CHKCON		;check console, quit if anything ready.
 928    0551  C23D07    		JP	NZ,GETBACK
 929    0554  C32B05    		JP	TYPE1
 930                    	;
 931                    	;   Get here on an end of file or read error.
 932                    	;
 933    0557  3D        	TYPE4:	DEC	A		;read error?
 934    0558  CA3D07    		JP	Z,GETBACK
 935    055B  CD9003    		CALL	RDERROR		;yes, print message.
 936    055E  CD1D04    	TYPE5:	CALL	RESETDR		;and reset proper drive
 937    0561  C3C001    		JP	SYNERR		;now print file name with problem.
 938                    	;
 939                    	;**************************************************************
 940                    	;*
 941                    	;*            S A V E   C O M M A N D
 942                    	;*
 943                    	;**************************************************************
 944                    	;
 945    0564  CDAF03    	SAVE:	CALL	DECODE		;get numeric number that follows SAVE.
 946    0567  F5        		PUSH	AF		;save number of pages to write.
 947    0568  CD1502    		CALL	CONVFST		;convert file name.
 948    056B  C2C001    		JP	NZ,SYNERR	;wild cards not allowed.
 949    056E  CD0B04    		CALL	DSELECT		;select specified drive.
 950    0571  118407    		LD	DE,FCB		;now delete this file.
 951    0574  D5        		PUSH	DE
 952    0575  CDA600    		CALL	DELETE
 953    0578  D1        		POP	DE
 954    0579  CDC000    		CALL	CREATE		;and create it again.
 955    057C  CAB205    		JP	Z,SAVE3		;can't create?
 956    057F  AF        		XOR	A		;clear record number byte.
 957    0580  32A407    		LD	(FCB+32),A
 958    0583  F1        		POP	AF		;convert pages to sectors.
 959    0584  6F        		LD	L,A
 960    0585  2600      		LD	H,0
 961    0587  29        		ADD	HL,HL		;(HL)=number of sectors to write.
 962    0588  110001    		LD	DE,TBASE	;and we start from here.
 963    058B  7C        	SAVE1:	LD	A,H		;done yet?
 964    058C  B5        		OR	L
 965    058D  CAA805    		JP	Z,SAVE2
 966    0590  2B        		DEC	HL		;nope, count this and compute the start
 967    0591  E5        		PUSH	HL		;of the next 128 byte sector.
 968    0592  218000    		LD	HL,128
 969    0595  19        		ADD	HL,DE
 970    0596  E5        		PUSH	HL		;save it and set the transfer address.
 971    0597  CD8F01    		CALL	DMASET
 972    059A  118407    		LD	DE,FCB		;write out this sector now.
 973    059D  CDBB00    		CALL	WRTREC
 974    05A0  D1        		POP	DE		;reset (DE) to the start of the last sector.
 975    05A1  E1        		POP	HL		;restore sector count.
 976    05A2  C2B205    		JP	NZ,SAVE3	;write error?
 977    05A5  C38B05    		JP	SAVE1
 978                    	;
 979                    	;   Get here after writing all of the file.
 980                    	;
 981    05A8  118407    	SAVE2:	LD	DE,FCB		;now close the file.
 982    05AB  CD9100    		CALL	CLOSE
 983    05AE  3C        		INC	A		;did it close ok?
 984    05AF  C2B805    		JP	NZ,SAVE4
 985                    	;
 986                    	;   Print out error message (no space).
 987                    	;
 988    05B2  01BE05    	SAVE3:	LD	BC,NOSPACE
 989    05B5  CD5E00    		CALL	PLINE
 990    05B8  CD8C01    	SAVE4:	CALL	STDDMA		;reset the standard dma address.
 991    05BB  C33D07    		JP	GETBACK
 992    05BE  4E4F2053  	NOSPACE:.byte	'N','O',' ','S','P','A','C','E',0
              50414345
              00
 993                    	;
 994                    	;**************************************************************
 995                    	;*
 996                    	;*           R E N A M E   C O M M A N D
 997                    	;*
 998                    	;**************************************************************
 999                    	;
1000    05C7  CD1502    	RENAME:	CALL	CONVFST		;convert first file name.
1001    05CA  C2C001    		JP	NZ,SYNERR	;wild cards not allowed.
1002    05CD  3AA707    		LD	A,(CHGDRV)	;remember any change in drives specified.
1003    05D0  F5        		PUSH	AF
1004    05D1  CD0B04    		CALL	DSELECT		;and select this drive.
1005    05D4  CDA000    		CALL	SRCHFCB		;is this file present?
1006    05D7  C23006    		JP	NZ,RENAME6	;yes, print error message.
1007    05DA  218407    		LD	HL,FCB		;yes, move this name into second slot.
1008    05DD  119407    		LD	DE,FCB+16
1009    05E0  0610      		LD	B,16
1010    05E2  CDF903    		CALL	HL2DE
1011    05E5  2A3F00    		LD	HL,(INPOINT)	;get input pointer.
1012    05E8  EB        		EX	DE,HL
1013    05E9  CD0602    		CALL	NONBLANK	;get next non blank character.
1014    05EC  FE3D      		CP	'='		;only allow an '=' or '_' seperator.
1015    05EE  CAF605    		JP	Z,RENAME1
1016    05F1  FE5F      		CP	'_'
1017    05F3  C22A06    		JP	NZ,RENAME5
1018    05F6  EB        	RENAME1:EX	DE,HL
1019    05F7  23        		INC	HL		;ok, skip seperator.
1020    05F8  223F00    		LD	(INPOINT),HL	;save input line pointer.
1021    05FB  CD1502    		CALL	CONVFST		;convert this second file name now.
1022    05FE  C22A06    		JP	NZ,RENAME5	;again, no wild cards.
1023    0601  F1        		POP	AF		;if a drive was specified, then it
1024    0602  47        		LD	B,A		;must be the same as before.
1025    0603  21A707    		LD	HL,CHGDRV
1026    0606  7E        		LD	A,(HL)
1027    0607  B7        		OR	A
1028    0608  CA1006    		JP	Z,RENAME2
1029    060B  B8        		CP	B
1030    060C  70        		LD	(HL),B
1031    060D  C22A06    		JP	NZ,RENAME5	;they were different, error.
1032    0610  70        	RENAME2:LD	(HL),B		;	reset as per the first file specification.
1033    0611  AF        		XOR	A
1034    0612  328407    		LD	(FCB),A		;clear the drive byte of the fcb.
1035    0615  CDA000    	RENAME3:CALL	SRCHFCB		;and go look for second file.
1036    0618  CA2406    		JP	Z,RENAME4	;doesn't exist?
1037    061B  118407    		LD	DE,FCB
1038    061E  CDC500    		CALL	RENAM		;ok, rename the file.
1039    0621  C33D07    		JP	GETBACK
1040                    	;
1041                    	;   Process rename errors here.
1042                    	;
1043    0624  CDA103    	RENAME4:CALL	NONE		;file not there.
1044    0627  C33D07    		JP	GETBACK
1045    062A  CD1D04    	RENAME5:CALL	RESETDR		;bad command format.
1046    062D  C3C001    		JP	SYNERR
1047    0630  013906    	RENAME6:LD	BC,EXISTS	;destination file already exists.
1048    0633  CD5E00    		CALL	PLINE
1049    0636  C33D07    		JP	GETBACK
1050    0639  46494C45  	EXISTS:	.byte	'F','I','L','E',' ','E','X','I','S','T','S',0
              20455849
              53545300
1051                    	;
1052                    	;**************************************************************
1053                    	;*
1054                    	;*             U S E R   C O M M A N D
1055                    	;*
1056                    	;**************************************************************
1057                    	;
1058    0645  CDAF03    	USER:	CALL	DECODE		;get numeric value following command.
1059    0648  FE10      		CP	16		;legal user number?
1060    064A  D2C001    		JP	NC,SYNERR
1061    064D  5F        		LD	E,A		;yes but is there anything else?
1062    064E  3A8507    		LD	A,(FCB+1)
1063    0651  FE20      		CP	' '
1064    0653  CAC001    		JP	Z,SYNERR	;yes, that is not allowed.
1065    0656  CDCC00    		CALL	GETSETUC	;ok, set user code.
1066    0659  C34007    		JP	GETBACK1
1067                    	;
1068                    	;**************************************************************
1069                    	;*
1070                    	;*        T R A N S I A N T   P R O G R A M   C O M M A N D
1071                    	;*
1072                    	;**************************************************************
1073                    	;
1074    065C  CDAC01    	UNKNOWN:CALL	VERIFY		;check for valid system (why?).
1075    065F  3A8507    		LD	A,(FCB+1)	;anything to execute?
1076    0662  FE20      		CP	' '
1077    0664  C27B06    		JP	NZ,UNKWN1
1078    0667  3AA707    		LD	A,(CHGDRV)	;nope, only a drive change?
1079    066A  B7        		OR	A
1080    066B  CA4007    		JP	Z,GETBACK1	;neither???
1081    066E  3D        		DEC	A
1082    066F  32A607    		LD	(CDRIVE),A	;ok, store new drive.
1083    0672  CDE000    		CALL	MOVECD		;set (TDRIVE) also.
1084    0675  CD7400    		CALL	DSKSEL		;and select this drive.
1085    0678  C34007    		JP	GETBACK1	;then return.
1086                    	;
1087                    	;   Here a file name was typed. Prepare to execute it.
1088                    	;
1089    067B  118D07    	UNKWN1:	LD	DE,FCB+9	;an extension specified?
1090    067E  1A        		LD	A,(DE)
1091    067F  FE20      		CP	' '
1092    0681  C2C001    		JP	NZ,SYNERR	;yes, not allowed.
1093    0684  D5        	UNKWN2:	PUSH	DE
1094    0685  CD0B04    		CALL	DSELECT		;select specified drive.
1095    0688  D1        		POP	DE
1096    0689  213A07    		LD	HL,COMFILE	;set the extension to 'COM'.
1097    068C  CDF703    		CALL	MOVE3
1098    068F  CD8700    		CALL	OPENFCB		;and open this file.
1099    0692  CA2207    		JP	Z,UNKWN9	;not present?
1100                    	;
1101                    	;   Load in the program.
1102                    	;
1103    0695  210001    		LD	HL,TBASE	;store the program starting here.
1104    0698  E5        	UNKWN3:	PUSH	HL
1105    0699  EB        		EX	DE,HL
1106    069A  CD8F01    		CALL	DMASET		;set transfer address.
1107    069D  118407    		LD	DE,FCB		;and read the next record.
1108    06A0  CDB000    		CALL	RDREC
1109    06A3  C2B806    		JP	NZ,UNKWN4	;end of file or read error?
1110    06A6  E1        		POP	HL		;nope, bump pointer for next sector.
1111    06A7  118000    		LD	DE,128
1112    06AA  19        		ADD	HL,DE
1113    06AB  110000    		LD	DE,CBASE	;enough room for the whole file?
1114    06AE  7D        		LD	A,L
1115    06AF  93        		SUB	E
1116    06B0  7C        		LD	A,H
1117    06B1  9A        		SBC	A,D
1118    06B2  D22807    		JP	NC,UNKWN0	;no, it can't fit.
1119    06B5  C39806    		JP	UNKWN3
1120                    	;
1121                    	;   Get here after finished reading.
1122                    	;
1123    06B8  E1        	UNKWN4:	POP	HL
1124    06B9  3D        		DEC	A		;normal end of file?
1125    06BA  C22807    		JP	NZ,UNKWN0
1126    06BD  CD1D04    		CALL	RESETDR		;yes, reset previous drive.
1127    06C0  CD1502    		CALL	CONVFST		;convert the first file name that follows
1128    06C3  21A707    		LD	HL,CHGDRV	;command name.
1129    06C6  E5        		PUSH	HL
1130    06C7  7E        		LD	A,(HL)		;set drive code in default fcb.
1131    06C8  328407    		LD	(FCB),A
1132    06CB  3E10      		LD	A,16		;put second name 16 bytes later.
1133    06CD  CD1702    		CALL	CONVERT		;convert second file name.
1134    06D0  E1        		POP	HL
1135    06D1  7E        		LD	A,(HL)		;and set the drive for this second file.
1136    06D2  329407    		LD	(FCB+16),A
1137    06D5  AF        		XOR	A		;clear record byte in fcb.
1138    06D6  32A407    		LD	(FCB+32),A
1139    06D9  115C00    		LD	DE,TFCB		;move it into place at(005Ch).
1140    06DC  218407    		LD	HL,FCB
1141    06DF  0621      		LD	B,33
1142    06E1  CDF903    		CALL	HL2DE
1143    06E4  210800    		LD	HL,INBUFF+2	;now move the remainder of the input
1144    06E7  7E        	UNKWN5:	LD	A,(HL)		;line down to (0080h). Look for a non blank.
1145    06E8  B7        		OR	A		;or a null.
1146    06E9  CAF506    		JP	Z,UNKWN6
1147    06EC  FE20      		CP	' '
1148    06EE  CAF506    		JP	Z,UNKWN6
1149    06F1  23        		INC	HL
1150    06F2  C3E706    		JP	UNKWN5
1151                    	;
1152                    	;   Do the line move now. It ends in a null byte.
1153                    	;
1154    06F5  0600      	UNKWN6:	LD	B,0		;keep a character count.
1155    06F7  118100    		LD	DE,TBUFF+1	;data gets put here.
1156    06FA  7E        	UNKWN7:	LD	A,(HL)		;move it now.
1157    06FB  12        		LD	(DE),A
1158    06FC  B7        		OR	A
1159    06FD  CA0607    		JP	Z,UNKWN8
1160    0700  04        		INC	B
1161    0701  23        		INC	HL
1162    0702  13        		INC	DE
1163    0703  C3FA06    		JP	UNKWN7
1164    0706  78        	UNKWN8:	LD	A,B		;now store the character count.
1165    0707  328000    		LD	(TBUFF),A
1166    070A  CD4F00    		CALL	CRLF		;clean up the screen.
1167    070D  CD8C01    		CALL	STDDMA		;set standard transfer address.
1168    0710  CDD100    		CALL	SETCDRV		;reset current drive.
1169    0713  CD0001    		CALL	TBASE		;and execute the program.
1170                    	;
1171                    	;   Transiant programs return here (or reboot).
1172                    	;
1173    0716  316207    		LD	SP,BATCH	;set stack first off.
1174    0719  CDE000    		CALL	MOVECD		;move current drive into place (TDRIVE).
1175    071C  CD7400    		CALL	DSKSEL		;and reselect it.
1176    071F  C33903    		JP	CMMND1		;back to comand mode.
1177                    	;
1178                    	;   Get here if some error occured.
1179                    	;
1180    0722  CD1D04    	UNKWN9:	CALL	RESETDR		;inproper format.
1181    0725  C3C001    		JP	SYNERR
1182    0728  013107    	UNKWN0:	LD	BC,BADLOAD	;read error or won't fit.
1183    072B  CD5E00    		CALL	PLINE
1184    072E  C33D07    		JP	GETBACK
1185    0731  42414420  	BADLOAD:.byte	'B','A','D',' ','L','O','A','D',0
              4C4F4144
              00
1186    073A  434F4D    	COMFILE:.byte	'C','O','M'	;command file extension.
1187                    	;
1188                    	;   Get here to return to command level. We will reset the
1189                    	; previous active drive and then either return to command
1190                    	; level directly or print error message and then return.
1191                    	;
1192    073D  CD1D04    	GETBACK:CALL	RESETDR		;reset previous drive.
1193    0740  CD1502    	GETBACK1: CALL	CONVFST		;convert first name in (FCB).
1194    0743  3A8507    		LD	A,(FCB+1)	;if this was just a drive change request,
1195    0746  D620      		SUB	' '		;make sure it was valid.
1196    0748  21A707    		LD	HL,CHGDRV
1197    074B  B6        		OR	(HL)
1198    074C  C2C001    		JP	NZ,SYNERR
1199    074F  C33903    		JP	CMMND1		;ok, return to command level.
1200                    	;
1201                    	;   ccp stack area.
1202                    	;
1203    0752  00000000  		.byte	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              00000000
              00000000
              00000000
1204                    	CCPSTACK:	;end of ccp stack area.
1205                    	;
1206                    	;   Batch (or SUBMIT) processing information storage.
1207                    	;
1208    0762  00        	BATCH:	.byte	0		;batch mode flag (0=not active).
1209    0763  00        	BATCHFCB: .byte	0
1210    0764  24242420  		.byte	'$','$','$',' ',' ',' ',' ',' ','S','U','B'
              20202020
              535542
1211    076F  00000000  		.byte	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              00000000
              00000000
              00000000
              00000000
              00
1212                    	;
1213                    	;   File control block setup by the CCP.
1214                    	;
1215    0784  00        	FCB:	.byte	0
1216    0785  00000000  		.byte	0,0,0,0,0,0,0,0,0,0,0
              00000000
              000000
1217    0790  00000000  		.byte	0,0,0,0,0
              00
1218    0795  00000000  		.byte	0,0,0,0,0,0,0,0,0,0,0
              00000000
              000000
1219    07A0  00000000  		.byte	0,0,0,0,0
              00
1220    07A5  00        	RTNCODE:.byte	0		;status returned from bdos call.
1221    07A6  00        	CDRIVE:	.byte	0		;currently active drive.
1222    07A7  00        	CHGDRV:	.byte	0		;change in drives flag (0=no change).
1223    07A8  0000      	NBYTES:	.word	0		;byte counter used by TYPE.
1224                    	;
1225                    	;   Room for expansion?
1226                    	;
1227    07AA  00000000  		.byte	0,0,0,0,0,0,0,0,0,0,0,0,0
              00000000
              00000000
              00
1228                    	
1229                    	; Fill with zeroes up to CCPSIZE
1230    07B7  00000000  	ccppad:	.byte 0 (CCPSIZE - (ccppad - CBASE))
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00000000
              00
1231                    	
1232                    		.end
1233                    	
