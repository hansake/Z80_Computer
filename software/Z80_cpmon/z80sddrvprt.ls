   1                    	;    1  /*  z80sddrvprt.c Z80 SD card status print routines.
   2                    	;    2   *
   3                    	;    3   *  SD card code for my DIY Z80 Computer. This
   4                    	;    4   *  program is compiled with Whitesmiths/COSMIC
   5                    	;    5   *  C compiler for Z80.
   6                    	;    6   *
   7                    	;    7   *  Initializes the hardware and detects the
   8                    	;    8   *  presence of an attached SD card.
   9                    	;    9   *
  10                    	;   10   *  You are free to use, modify, and redistribute
  11                    	;   11   *  this source code. No warranties are given.
  12                    	;   12   *  Hastily Cobbled Together 2021 and 2022
  13                    	;   13   *  by Hans-Ake Lund
  14                    	;   14   *
  15                    	;   15   *  When accessing data blocks on the SD card,
  16                    	;   16   *  block numbers are given as a four byte array
  17                    	;   17   *  with the most significant byte first, this is the
  18                    	;   18   *  format that the SD card is using. This internal format
  19                    	;   19   *  was chosen to make the SD card driver in the BIOS simpler
  20                    	;   20   *  and not needing to switch between SD card format and
  21                    	;   21   *  Whitesmiths 32 bit format (which is a rather peculiar
  22                    	;   22   *  PDP-11 format).
  23                    	;   23   */
  24                    	;   24  
  25                    	;   25  #include <std.h>
  26                    	;   26  #include "z80comp.h"
  27                    	;   27  #include "z80sd.h"
  28                    		.psect	_text
  29                    	;   28  
  30                    	;   29  /* Convert unsigned long to block address
  31                    	;   30   */
  32                    	;   31  void ul2blk(unsigned char *blk, unsigned long nblk)
  33                    	;   32      {
  34                    	_ul2blk:
  35    0000  CD0000    		call	c.savs
  36                    	;   33      blk[3] = nblk & 0xff;
  37    0003  DD6E04    		ld	l,(ix+4)
  38    0006  DD6605    		ld	h,(ix+5)
  39    0009  23        		inc	hl
  40    000A  23        		inc	hl
  41    000B  23        		inc	hl
  42    000C  DD4E08    		ld	c,(ix+8)
  43    000F  79        		ld	a,c
  44    0010  E6FF      		and	255
  45    0012  4F        		ld	c,a
  46    0013  71        		ld	(hl),c
  47                    	;   34      nblk = nblk >> 8;
  48    0014  DDE5      		push	ix
  49    0016  C1        		pop	bc
  50    0017  210600    		ld	hl,6
  51    001A  09        		add	hl,bc
  52    001B  E5        		push	hl
  53    001C  210800    		ld	hl,8
  54    001F  E5        		push	hl
  55    0020  CD0000    		call	c.ulrsh
  56    0023  F1        		pop	af
  57                    	;   35      blk[2] = nblk & 0xff;
  58    0024  DD6E04    		ld	l,(ix+4)
  59    0027  DD6605    		ld	h,(ix+5)
  60    002A  23        		inc	hl
  61    002B  23        		inc	hl
  62    002C  DD4E08    		ld	c,(ix+8)
  63    002F  79        		ld	a,c
  64    0030  E6FF      		and	255
  65    0032  4F        		ld	c,a
  66    0033  71        		ld	(hl),c
  67                    	;   36      nblk = nblk >> 8;
  68    0034  DDE5      		push	ix
  69    0036  C1        		pop	bc
  70    0037  210600    		ld	hl,6
  71    003A  09        		add	hl,bc
  72    003B  E5        		push	hl
  73    003C  210800    		ld	hl,8
  74    003F  E5        		push	hl
  75    0040  CD0000    		call	c.ulrsh
  76    0043  F1        		pop	af
  77                    	;   37      blk[1] = nblk & 0xff;
  78    0044  DD6E04    		ld	l,(ix+4)
  79    0047  DD6605    		ld	h,(ix+5)
  80    004A  23        		inc	hl
  81    004B  DD4E08    		ld	c,(ix+8)
  82    004E  79        		ld	a,c
  83    004F  E6FF      		and	255
  84    0051  4F        		ld	c,a
  85    0052  71        		ld	(hl),c
  86                    	;   38      nblk = nblk >> 8;
  87    0053  DDE5      		push	ix
  88    0055  C1        		pop	bc
  89    0056  210600    		ld	hl,6
  90    0059  09        		add	hl,bc
  91    005A  E5        		push	hl
  92    005B  210800    		ld	hl,8
  93    005E  E5        		push	hl
  94    005F  CD0000    		call	c.ulrsh
  95    0062  F1        		pop	af
  96                    	;   39      blk[0] = nblk & 0xff;
  97    0063  DD6E04    		ld	l,(ix+4)
  98    0066  DD6605    		ld	h,(ix+5)
  99    0069  DD4E08    		ld	c,(ix+8)
 100    006C  79        		ld	a,c
 101    006D  E6FF      		and	255
 102    006F  4F        		ld	c,a
 103    0070  71        		ld	(hl),c
 104                    	;   40      }
 105    0071  C30000    		jp	c.rets
 106                    	;   41  
 107                    	;   42  /* Convert block address to unsigned long
 108                    	;   43   */
 109                    	;   44  unsigned long blk2ul(unsigned char *blk)
 110                    	;   45      {
 111                    	_blk2ul:
 112    0074  CD0000    		call	c.savs
 113                    	;   46      return((unsigned long)(0xff & blk[3]) + 
 114                    	;   47          ((unsigned long)(0xff & blk[2]) << 8) +
 115                    	;   48          ((unsigned long)(0xff & blk[1]) << 16) +
 116                    	;   49          ((unsigned long)(0xff & blk[0]) << 24));
 117    0077  DD6E04    		ld	l,(ix+4)
 118    007A  DD6605    		ld	h,(ix+5)
 119    007D  23        		inc	hl
 120    007E  23        		inc	hl
 121    007F  23        		inc	hl
 122    0080  6E        		ld	l,(hl)
 123    0081  97        		sub	a
 124    0082  67        		ld	h,a
 125    0083  7D        		ld	a,l
 126    0084  E6FF      		and	255
 127    0086  6F        		ld	l,a
 128    0087  97        		sub	a
 129    0088  67        		ld	h,a
 130    0089  4D        		ld	c,l
 131    008A  44        		ld	b,h
 132    008B  78        		ld	a,b
 133    008C  87        		add	a,a
 134    008D  9F        		sbc	a,a
 135    008E  320000    		ld	(c.r0),a
 136    0091  320100    		ld	(c.r0+1),a
 137    0094  78        		ld	a,b
 138    0095  320300    		ld	(c.r0+3),a
 139    0098  79        		ld	a,c
 140    0099  320200    		ld	(c.r0+2),a
 141    009C  210000    		ld	hl,c.r0
 142    009F  E5        		push	hl
 143    00A0  DD6E04    		ld	l,(ix+4)
 144    00A3  DD6605    		ld	h,(ix+5)
 145    00A6  23        		inc	hl
 146    00A7  23        		inc	hl
 147    00A8  6E        		ld	l,(hl)
 148    00A9  97        		sub	a
 149    00AA  67        		ld	h,a
 150    00AB  7D        		ld	a,l
 151    00AC  E6FF      		and	255
 152    00AE  6F        		ld	l,a
 153    00AF  97        		sub	a
 154    00B0  67        		ld	h,a
 155    00B1  4D        		ld	c,l
 156    00B2  44        		ld	b,h
 157    00B3  78        		ld	a,b
 158    00B4  87        		add	a,a
 159    00B5  9F        		sbc	a,a
 160    00B6  320000    		ld	(c.r1),a
 161    00B9  320100    		ld	(c.r1+1),a
 162    00BC  78        		ld	a,b
 163    00BD  320300    		ld	(c.r1+3),a
 164    00C0  79        		ld	a,c
 165    00C1  320200    		ld	(c.r1+2),a
 166    00C4  210000    		ld	hl,c.r1
 167    00C7  E5        		push	hl
 168    00C8  210800    		ld	hl,8
 169    00CB  E5        		push	hl
 170    00CC  CD0000    		call	c.llsh
 171    00CF  CD0000    		call	c.ladd
 172    00D2  DD6E04    		ld	l,(ix+4)
 173    00D5  DD6605    		ld	h,(ix+5)
 174    00D8  23        		inc	hl
 175    00D9  6E        		ld	l,(hl)
 176    00DA  97        		sub	a
 177    00DB  67        		ld	h,a
 178    00DC  7D        		ld	a,l
 179    00DD  E6FF      		and	255
 180    00DF  6F        		ld	l,a
 181    00E0  97        		sub	a
 182    00E1  67        		ld	h,a
 183    00E2  4D        		ld	c,l
 184    00E3  44        		ld	b,h
 185    00E4  78        		ld	a,b
 186    00E5  87        		add	a,a
 187    00E6  9F        		sbc	a,a
 188    00E7  320000    		ld	(c.r1),a
 189    00EA  320100    		ld	(c.r1+1),a
 190    00ED  78        		ld	a,b
 191    00EE  320300    		ld	(c.r1+3),a
 192    00F1  79        		ld	a,c
 193    00F2  320200    		ld	(c.r1+2),a
 194    00F5  210000    		ld	hl,c.r1
 195    00F8  E5        		push	hl
 196    00F9  211000    		ld	hl,16
 197    00FC  E5        		push	hl
 198    00FD  CD0000    		call	c.llsh
 199    0100  CD0000    		call	c.ladd
 200    0103  DD6E04    		ld	l,(ix+4)
 201    0106  DD6605    		ld	h,(ix+5)
 202    0109  6E        		ld	l,(hl)
 203    010A  97        		sub	a
 204    010B  67        		ld	h,a
 205    010C  7D        		ld	a,l
 206    010D  E6FF      		and	255
 207    010F  6F        		ld	l,a
 208    0110  97        		sub	a
 209    0111  67        		ld	h,a
 210    0112  4D        		ld	c,l
 211    0113  44        		ld	b,h
 212    0114  78        		ld	a,b
 213    0115  87        		add	a,a
 214    0116  9F        		sbc	a,a
 215    0117  320000    		ld	(c.r1),a
 216    011A  320100    		ld	(c.r1+1),a
 217    011D  78        		ld	a,b
 218    011E  320300    		ld	(c.r1+3),a
 219    0121  79        		ld	a,c
 220    0122  320200    		ld	(c.r1+2),a
 221    0125  210000    		ld	hl,c.r1
 222    0128  E5        		push	hl
 223    0129  211800    		ld	hl,24
 224    012C  E5        		push	hl
 225    012D  CD0000    		call	c.llsh
 226    0130  CD0000    		call	c.ladd
 227    0133  F1        		pop	af
 228    0134  C30000    		jp	c.rets
 229                    	L5:
 230    0137  2A        		.byte	42
 231    0138  0A        		.byte	10
 232    0139  00        		.byte	0
 233                    	L51:
 234    013A  25        		.byte	37
 235    013B  30        		.byte	48
 236    013C  34        		.byte	52
 237    013D  78        		.byte	120
 238    013E  20        		.byte	32
 239    013F  00        		.byte	0
 240                    	L52:
 241    0140  25        		.byte	37
 242    0141  30        		.byte	48
 243    0142  32        		.byte	50
 244    0143  78        		.byte	120
 245    0144  20        		.byte	32
 246    0145  00        		.byte	0
 247                    	L53:
 248    0146  20        		.byte	32
 249    0147  7C        		.byte	124
 250    0148  00        		.byte	0
 251                    	L54:
 252    0149  7C        		.byte	124
 253    014A  0A        		.byte	10
 254    014B  00        		.byte	0
 255                    	;   50      }
 256                    	;   51  
 257                    	;   52  /* Print data in 512 byte buffer */
 258                    	;   53  void sddatprt(unsigned char *prtbuf, unsigned int prtbase, int dumprows)
 259                    	;   54      {
 260                    	_sddatprt:
 261    014C  CD0000    		call	c.savs
 262    014F  21EEFF    		ld	hl,65518
 263    0152  39        		add	hl,sp
 264    0153  F9        		ld	sp,hl
 265                    	;   55      /* Variables used for "pretty-print" */
 266                    	;   56      int allzero, dmpline, dotprted, lastallz, nbytes;
 267                    	;   57      unsigned char *prtptr;
 268                    	;   58  
 269                    	;   59      prtptr = prtbuf;
 270    0154  DD7E04    		ld	a,(ix+4)
 271    0157  DD77EE    		ld	(ix-18),a
 272    015A  DD7E05    		ld	a,(ix+5)
 273    015D  DD77EF    		ld	(ix-17),a
 274                    	;   60      dotprted = NO;
 275    0160  DD36F400  		ld	(ix-12),0
 276    0164  DD36F500  		ld	(ix-11),0
 277                    	;   61      lastallz = NO;
 278    0168  DD36F200  		ld	(ix-14),0
 279    016C  DD36F300  		ld	(ix-13),0
 280                    	;   62      for (dmpline = 0; dmpline < dumprows; dmpline++)
 281    0170  DD36F600  		ld	(ix-10),0
 282    0174  DD36F700  		ld	(ix-9),0
 283                    	L1:
 284    0178  DD7EF6    		ld	a,(ix-10)
 285    017B  DD9608    		sub	(ix+8)
 286    017E  DD7EF7    		ld	a,(ix-9)
 287    0181  DD9E09    		sbc	a,(ix+9)
 288    0184  F2FA02    		jp	p,L11
 289                    	;   63          {
 290                    	;   64          /* test if all 16 bytes are 0x00 */
 291                    	;   65          allzero = YES;
 292    0187  DD36F801  		ld	(ix-8),1
 293    018B  DD36F900  		ld	(ix-7),0
 294                    	;   66          for (nbytes = 0; nbytes < 16; nbytes++)
 295    018F  DD36F000  		ld	(ix-16),0
 296    0193  DD36F100  		ld	(ix-15),0
 297                    	L14:
 298    0197  DD7EF0    		ld	a,(ix-16)
 299    019A  D610      		sub	16
 300    019C  DD7EF1    		ld	a,(ix-15)
 301    019F  DE00      		sbc	a,0
 302    01A1  F2C701    		jp	p,L15
 303                    	;   67              {
 304                    	;   68              if (prtptr[nbytes] != 0)
 305    01A4  DD6EEE    		ld	l,(ix-18)
 306    01A7  DD66EF    		ld	h,(ix-17)
 307    01AA  DD4EF0    		ld	c,(ix-16)
 308    01AD  DD46F1    		ld	b,(ix-15)
 309    01B0  09        		add	hl,bc
 310    01B1  7E        		ld	a,(hl)
 311    01B2  B7        		or	a
 312    01B3  2808      		jr	z,L16
 313                    	;   69                  allzero = NO;
 314    01B5  DD36F800  		ld	(ix-8),0
 315    01B9  DD36F900  		ld	(ix-7),0
 316                    	L16:
 317    01BD  DD34F0    		inc	(ix-16)
 318    01C0  2003      		jr	nz,L21
 319    01C2  DD34F1    		inc	(ix-15)
 320                    	L21:
 321    01C5  18D0      		jr	L14
 322                    	L15:
 323                    	;   70              }
 324                    	;   71          if (lastallz && allzero && (dmpline != (dumprows -1)))
 325    01C7  DD7EF2    		ld	a,(ix-14)
 326    01CA  DDB6F3    		or	(ix-13)
 327    01CD  2838      		jr	z,L111
 328    01CF  DD7EF8    		ld	a,(ix-8)
 329    01D2  DDB6F9    		or	(ix-7)
 330    01D5  2830      		jr	z,L111
 331    01D7  DD6E08    		ld	l,(ix+8)
 332    01DA  DD6609    		ld	h,(ix+9)
 333    01DD  01FFFF    		ld	bc,65535
 334    01E0  09        		add	hl,bc
 335    01E1  7D        		ld	a,l
 336    01E2  DDBEF6    		cp	(ix-10)
 337    01E5  2004      		jr	nz,L41
 338    01E7  7C        		ld	a,h
 339    01E8  DDBEF7    		cp	(ix-9)
 340                    	L41:
 341    01EB  281A      		jr	z,L111
 342                    	;   72              {
 343                    	;   73              if (!dotprted)
 344    01ED  DD7EF4    		ld	a,(ix-12)
 345    01F0  DDB6F5    		or	(ix-11)
 346    01F3  C2CF02    		jp	nz,L131
 347                    	;   74                  {
 348                    	;   75                  printf("*\n");
 349    01F6  213701    		ld	hl,L5
 350    01F9  CD0000    		call	_printf
 351                    	;   76                  dotprted = YES;
 352    01FC  DD36F401  		ld	(ix-12),1
 353    0200  DD36F500  		ld	(ix-11),0
 354    0204  C3CF02    		jp	L131
 355                    	L111:
 356                    	;   77                  }
 357                    	;   78              }
 358                    	;   79          else
 359                    	;   80              {
 360                    	;   81              dotprted = NO;
 361    0207  DD36F400  		ld	(ix-12),0
 362    020B  DD36F500  		ld	(ix-11),0
 363                    	;   82              /* print offset */
 364                    	;   83              printf("%04x ", (dmpline * 16) + prtbase);
 365    020F  DD6EF6    		ld	l,(ix-10)
 366    0212  DD66F7    		ld	h,(ix-9)
 367    0215  E5        		push	hl
 368    0216  211000    		ld	hl,16
 369    0219  E5        		push	hl
 370    021A  CD0000    		call	c.imul
 371    021D  E1        		pop	hl
 372    021E  DD4E06    		ld	c,(ix+6)
 373    0221  DD4607    		ld	b,(ix+7)
 374    0224  09        		add	hl,bc
 375    0225  E5        		push	hl
 376    0226  213A01    		ld	hl,L51
 377    0229  CD0000    		call	_printf
 378    022C  F1        		pop	af
 379                    	;   84              /* print 16 bytes in hex */
 380                    	;   85              for (nbytes = 0; nbytes < 16; nbytes++)
 381    022D  DD36F000  		ld	(ix-16),0
 382    0231  DD36F100  		ld	(ix-15),0
 383                    	L141:
 384    0235  DD7EF0    		ld	a,(ix-16)
 385    0238  D610      		sub	16
 386    023A  DD7EF1    		ld	a,(ix-15)
 387    023D  DE00      		sbc	a,0
 388    023F  F26402    		jp	p,L151
 389                    	;   86                  printf("%02x ", prtptr[nbytes]);
 390    0242  DD6EEE    		ld	l,(ix-18)
 391    0245  DD66EF    		ld	h,(ix-17)
 392    0248  DD4EF0    		ld	c,(ix-16)
 393    024B  DD46F1    		ld	b,(ix-15)
 394    024E  09        		add	hl,bc
 395    024F  4E        		ld	c,(hl)
 396    0250  97        		sub	a
 397    0251  47        		ld	b,a
 398    0252  C5        		push	bc
 399    0253  214001    		ld	hl,L52
 400    0256  CD0000    		call	_printf
 401    0259  F1        		pop	af
 402    025A  DD34F0    		inc	(ix-16)
 403    025D  2003      		jr	nz,L61
 404    025F  DD34F1    		inc	(ix-15)
 405                    	L61:
 406    0262  18D1      		jr	L141
 407                    	L151:
 408                    	;   87              /* print these bytes in ASCII if printable */
 409                    	;   88              printf(" |");
 410    0264  214601    		ld	hl,L53
 411    0267  CD0000    		call	_printf
 412                    	;   89              for (nbytes = 0; nbytes < 16; nbytes++)
 413    026A  DD36F000  		ld	(ix-16),0
 414    026E  DD36F100  		ld	(ix-15),0
 415                    	L102:
 416    0272  DD7EF0    		ld	a,(ix-16)
 417    0275  D610      		sub	16
 418    0277  DD7EF1    		ld	a,(ix-15)
 419    027A  DE00      		sbc	a,0
 420    027C  F2C902    		jp	p,L112
 421                    	;   90                  {
 422                    	;   91                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
 423    027F  DD6EEE    		ld	l,(ix-18)
 424    0282  DD66EF    		ld	h,(ix-17)
 425    0285  DD4EF0    		ld	c,(ix-16)
 426    0288  DD46F1    		ld	b,(ix-15)
 427    028B  09        		add	hl,bc
 428    028C  7E        		ld	a,(hl)
 429    028D  FE20      		cp	32
 430    028F  3827      		jr	c,L142
 431    0291  DD6EEE    		ld	l,(ix-18)
 432    0294  DD66EF    		ld	h,(ix-17)
 433    0297  DD4EF0    		ld	c,(ix-16)
 434    029A  DD46F1    		ld	b,(ix-15)
 435    029D  09        		add	hl,bc
 436    029E  7E        		ld	a,(hl)
 437    029F  FE7F      		cp	127
 438    02A1  3015      		jr	nc,L142
 439                    	;   92                      putchar(prtptr[nbytes]);
 440    02A3  DD6EEE    		ld	l,(ix-18)
 441    02A6  DD66EF    		ld	h,(ix-17)
 442    02A9  DD4EF0    		ld	c,(ix-16)
 443    02AC  DD46F1    		ld	b,(ix-15)
 444    02AF  09        		add	hl,bc
 445    02B0  6E        		ld	l,(hl)
 446    02B1  97        		sub	a
 447    02B2  67        		ld	h,a
 448    02B3  CD0000    		call	_putchar
 449                    	;   93                  else
 450    02B6  1806      		jr	L122
 451                    	L142:
 452                    	;   94                      putchar('.');
 453    02B8  212E00    		ld	hl,46
 454    02BB  CD0000    		call	_putchar
 455                    	L122:
 456    02BE  DD34F0    		inc	(ix-16)
 457    02C1  2003      		jr	nz,L02
 458    02C3  DD34F1    		inc	(ix-15)
 459                    	L02:
 460    02C6  C37202    		jp	L102
 461                    	L112:
 462                    	;   95                  }
 463                    	;   96              printf("|\n");
 464    02C9  214901    		ld	hl,L54
 465    02CC  CD0000    		call	_printf
 466                    	L131:
 467                    	;   97              }
 468                    	;   98          prtptr += 16;
 469    02CF  DD6EEE    		ld	l,(ix-18)
 470    02D2  DD66EF    		ld	h,(ix-17)
 471    02D5  7D        		ld	a,l
 472    02D6  C610      		add	a,16
 473    02D8  6F        		ld	l,a
 474    02D9  7C        		ld	a,h
 475    02DA  CE00      		adc	a,0
 476    02DC  67        		ld	h,a
 477    02DD  DD75EE    		ld	(ix-18),l
 478    02E0  DD74EF    		ld	(ix-17),h
 479                    	;   99          lastallz = allzero;
 480    02E3  DD7EF8    		ld	a,(ix-8)
 481    02E6  DD77F2    		ld	(ix-14),a
 482    02E9  DD7EF9    		ld	a,(ix-7)
 483    02EC  DD77F3    		ld	(ix-13),a
 484                    	;  100          }
 485    02EF  DD34F6    		inc	(ix-10)
 486    02F2  2003      		jr	nz,L01
 487    02F4  DD34F7    		inc	(ix-9)
 488                    	L01:
 489    02F7  C37801    		jp	L1
 490                    	L11:
 491                    	;  101      }
 492    02FA  C30000    		jp	c.rets
 493                    	L55:
 494    02FD  53        		.byte	83
 495    02FE  44        		.byte	68
 496    02FF  20        		.byte	32
 497    0300  63        		.byte	99
 498    0301  61        		.byte	97
 499    0302  72        		.byte	114
 500    0303  64        		.byte	100
 501    0304  20        		.byte	32
 502    0305  6E        		.byte	110
 503    0306  6F        		.byte	111
 504    0307  74        		.byte	116
 505    0308  20        		.byte	32
 506    0309  69        		.byte	105
 507    030A  6E        		.byte	110
 508    030B  69        		.byte	105
 509    030C  74        		.byte	116
 510    030D  69        		.byte	105
 511    030E  61        		.byte	97
 512    030F  6C        		.byte	108
 513    0310  69        		.byte	105
 514    0311  7A        		.byte	122
 515    0312  65        		.byte	101
 516    0313  64        		.byte	100
 517    0314  0A        		.byte	10
 518    0315  00        		.byte	0
 519                    	L56:
 520    0316  53        		.byte	83
 521    0317  44        		.byte	68
 522    0318  20        		.byte	32
 523    0319  63        		.byte	99
 524    031A  61        		.byte	97
 525    031B  72        		.byte	114
 526    031C  64        		.byte	100
 527    031D  20        		.byte	32
 528    031E  69        		.byte	105
 529    031F  6E        		.byte	110
 530    0320  66        		.byte	102
 531    0321  6F        		.byte	111
 532    0322  72        		.byte	114
 533    0323  6D        		.byte	109
 534    0324  61        		.byte	97
 535    0325  74        		.byte	116
 536    0326  69        		.byte	105
 537    0327  6F        		.byte	111
 538    0328  6E        		.byte	110
 539    0329  3A        		.byte	58
 540    032A  00        		.byte	0
 541                    	L57:
 542    032B  20        		.byte	32
 543    032C  20        		.byte	32
 544    032D  53        		.byte	83
 545    032E  44        		.byte	68
 546    032F  20        		.byte	32
 547    0330  63        		.byte	99
 548    0331  61        		.byte	97
 549    0332  72        		.byte	114
 550    0333  64        		.byte	100
 551    0334  20        		.byte	32
 552    0335  76        		.byte	118
 553    0336  65        		.byte	101
 554    0337  72        		.byte	114
 555    0338  2E        		.byte	46
 556    0339  20        		.byte	32
 557    033A  32        		.byte	50
 558    033B  2B        		.byte	43
 559    033C  2C        		.byte	44
 560    033D  20        		.byte	32
 561    033E  42        		.byte	66
 562    033F  6C        		.byte	108
 563    0340  6F        		.byte	111
 564    0341  63        		.byte	99
 565    0342  6B        		.byte	107
 566    0343  20        		.byte	32
 567    0344  61        		.byte	97
 568    0345  64        		.byte	100
 569    0346  64        		.byte	100
 570    0347  72        		.byte	114
 571    0348  65        		.byte	101
 572    0349  73        		.byte	115
 573    034A  73        		.byte	115
 574    034B  0A        		.byte	10
 575    034C  00        		.byte	0
 576                    	L501:
 577    034D  20        		.byte	32
 578    034E  20        		.byte	32
 579    034F  53        		.byte	83
 580    0350  44        		.byte	68
 581    0351  20        		.byte	32
 582    0352  63        		.byte	99
 583    0353  61        		.byte	97
 584    0354  72        		.byte	114
 585    0355  64        		.byte	100
 586    0356  20        		.byte	32
 587    0357  76        		.byte	118
 588    0358  65        		.byte	101
 589    0359  72        		.byte	114
 590    035A  2E        		.byte	46
 591    035B  20        		.byte	32
 592    035C  32        		.byte	50
 593    035D  2B        		.byte	43
 594    035E  2C        		.byte	44
 595    035F  20        		.byte	32
 596    0360  42        		.byte	66
 597    0361  79        		.byte	121
 598    0362  74        		.byte	116
 599    0363  65        		.byte	101
 600    0364  20        		.byte	32
 601    0365  61        		.byte	97
 602    0366  64        		.byte	100
 603    0367  64        		.byte	100
 604    0368  72        		.byte	114
 605    0369  65        		.byte	101
 606    036A  73        		.byte	115
 607    036B  73        		.byte	115
 608    036C  0A        		.byte	10
 609    036D  00        		.byte	0
 610                    	L511:
 611    036E  20        		.byte	32
 612    036F  20        		.byte	32
 613    0370  53        		.byte	83
 614    0371  44        		.byte	68
 615    0372  20        		.byte	32
 616    0373  63        		.byte	99
 617    0374  61        		.byte	97
 618    0375  72        		.byte	114
 619    0376  64        		.byte	100
 620    0377  20        		.byte	32
 621    0378  76        		.byte	118
 622    0379  65        		.byte	101
 623    037A  72        		.byte	114
 624    037B  2E        		.byte	46
 625    037C  20        		.byte	32
 626    037D  31        		.byte	49
 627    037E  2C        		.byte	44
 628    037F  20        		.byte	32
 629    0380  42        		.byte	66
 630    0381  79        		.byte	121
 631    0382  74        		.byte	116
 632    0383  65        		.byte	101
 633    0384  20        		.byte	32
 634    0385  61        		.byte	97
 635    0386  64        		.byte	100
 636    0387  64        		.byte	100
 637    0388  72        		.byte	114
 638    0389  65        		.byte	101
 639    038A  73        		.byte	115
 640    038B  73        		.byte	115
 641    038C  0A        		.byte	10
 642    038D  00        		.byte	0
 643                    	L521:
 644    038E  20        		.byte	32
 645    038F  20        		.byte	32
 646    0390  4D        		.byte	77
 647    0391  61        		.byte	97
 648    0392  6E        		.byte	110
 649    0393  75        		.byte	117
 650    0394  66        		.byte	102
 651    0395  61        		.byte	97
 652    0396  63        		.byte	99
 653    0397  74        		.byte	116
 654    0398  75        		.byte	117
 655    0399  72        		.byte	114
 656    039A  65        		.byte	101
 657    039B  72        		.byte	114
 658    039C  20        		.byte	32
 659    039D  49        		.byte	73
 660    039E  44        		.byte	68
 661    039F  3A        		.byte	58
 662    03A0  20        		.byte	32
 663    03A1  30        		.byte	48
 664    03A2  78        		.byte	120
 665    03A3  25        		.byte	37
 666    03A4  30        		.byte	48
 667    03A5  32        		.byte	50
 668    03A6  78        		.byte	120
 669    03A7  2C        		.byte	44
 670    03A8  20        		.byte	32
 671    03A9  00        		.byte	0
 672                    	L531:
 673    03AA  4F        		.byte	79
 674    03AB  45        		.byte	69
 675    03AC  4D        		.byte	77
 676    03AD  20        		.byte	32
 677    03AE  49        		.byte	73
 678    03AF  44        		.byte	68
 679    03B0  3A        		.byte	58
 680    03B1  20        		.byte	32
 681    03B2  25        		.byte	37
 682    03B3  2E        		.byte	46
 683    03B4  32        		.byte	50
 684    03B5  73        		.byte	115
 685    03B6  2C        		.byte	44
 686    03B7  20        		.byte	32
 687    03B8  00        		.byte	0
 688                    	L541:
 689    03B9  50        		.byte	80
 690    03BA  72        		.byte	114
 691    03BB  6F        		.byte	111
 692    03BC  64        		.byte	100
 693    03BD  75        		.byte	117
 694    03BE  63        		.byte	99
 695    03BF  74        		.byte	116
 696    03C0  20        		.byte	32
 697    03C1  6E        		.byte	110
 698    03C2  61        		.byte	97
 699    03C3  6D        		.byte	109
 700    03C4  65        		.byte	101
 701    03C5  3A        		.byte	58
 702    03C6  20        		.byte	32
 703    03C7  25        		.byte	37
 704    03C8  2E        		.byte	46
 705    03C9  35        		.byte	53
 706    03CA  73        		.byte	115
 707    03CB  0A        		.byte	10
 708    03CC  00        		.byte	0
 709                    	L551:
 710    03CD  20        		.byte	32
 711    03CE  20        		.byte	32
 712    03CF  50        		.byte	80
 713    03D0  72        		.byte	114
 714    03D1  6F        		.byte	111
 715    03D2  64        		.byte	100
 716    03D3  75        		.byte	117
 717    03D4  63        		.byte	99
 718    03D5  74        		.byte	116
 719    03D6  20        		.byte	32
 720    03D7  72        		.byte	114
 721    03D8  65        		.byte	101
 722    03D9  76        		.byte	118
 723    03DA  69        		.byte	105
 724    03DB  73        		.byte	115
 725    03DC  69        		.byte	105
 726    03DD  6F        		.byte	111
 727    03DE  6E        		.byte	110
 728    03DF  3A        		.byte	58
 729    03E0  20        		.byte	32
 730    03E1  25        		.byte	37
 731    03E2  64        		.byte	100
 732    03E3  2E        		.byte	46
 733    03E4  25        		.byte	37
 734    03E5  64        		.byte	100
 735    03E6  2C        		.byte	44
 736    03E7  20        		.byte	32
 737    03E8  00        		.byte	0
 738                    	L561:
 739    03E9  53        		.byte	83
 740    03EA  65        		.byte	101
 741    03EB  72        		.byte	114
 742    03EC  69        		.byte	105
 743    03ED  61        		.byte	97
 744    03EE  6C        		.byte	108
 745    03EF  20        		.byte	32
 746    03F0  6E        		.byte	110
 747    03F1  75        		.byte	117
 748    03F2  6D        		.byte	109
 749    03F3  62        		.byte	98
 750    03F4  65        		.byte	101
 751    03F5  72        		.byte	114
 752    03F6  3A        		.byte	58
 753    03F7  20        		.byte	32
 754    03F8  25        		.byte	37
 755    03F9  6C        		.byte	108
 756    03FA  75        		.byte	117
 757    03FB  0A        		.byte	10
 758    03FC  00        		.byte	0
 759                    	L571:
 760    03FD  20        		.byte	32
 761    03FE  20        		.byte	32
 762    03FF  4D        		.byte	77
 763    0400  61        		.byte	97
 764    0401  6E        		.byte	110
 765    0402  75        		.byte	117
 766    0403  66        		.byte	102
 767    0404  61        		.byte	97
 768    0405  63        		.byte	99
 769    0406  74        		.byte	116
 770    0407  75        		.byte	117
 771    0408  72        		.byte	114
 772    0409  69        		.byte	105
 773    040A  6E        		.byte	110
 774    040B  67        		.byte	103
 775    040C  20        		.byte	32
 776    040D  64        		.byte	100
 777    040E  61        		.byte	97
 778    040F  74        		.byte	116
 779    0410  65        		.byte	101
 780    0411  3A        		.byte	58
 781    0412  20        		.byte	32
 782    0413  25        		.byte	37
 783    0414  64        		.byte	100
 784    0415  2D        		.byte	45
 785    0416  25        		.byte	37
 786    0417  64        		.byte	100
 787    0418  2C        		.byte	44
 788    0419  20        		.byte	32
 789    041A  00        		.byte	0
 790                    	L502:
 791    041B  44        		.byte	68
 792    041C  65        		.byte	101
 793    041D  76        		.byte	118
 794    041E  69        		.byte	105
 795    041F  63        		.byte	99
 796    0420  65        		.byte	101
 797    0421  20        		.byte	32
 798    0422  63        		.byte	99
 799    0423  61        		.byte	97
 800    0424  70        		.byte	112
 801    0425  61        		.byte	97
 802    0426  63        		.byte	99
 803    0427  69        		.byte	105
 804    0428  74        		.byte	116
 805    0429  79        		.byte	121
 806    042A  3A        		.byte	58
 807    042B  20        		.byte	32
 808    042C  25        		.byte	37
 809    042D  6C        		.byte	108
 810    042E  75        		.byte	117
 811    042F  20        		.byte	32
 812    0430  4D        		.byte	77
 813    0431  42        		.byte	66
 814    0432  79        		.byte	121
 815    0433  74        		.byte	116
 816    0434  65        		.byte	101
 817    0435  0A        		.byte	10
 818    0436  00        		.byte	0
 819                    	L512:
 820    0437  44        		.byte	68
 821    0438  65        		.byte	101
 822    0439  76        		.byte	118
 823    043A  69        		.byte	105
 824    043B  63        		.byte	99
 825    043C  65        		.byte	101
 826    043D  20        		.byte	32
 827    043E  63        		.byte	99
 828    043F  61        		.byte	97
 829    0440  70        		.byte	112
 830    0441  61        		.byte	97
 831    0442  63        		.byte	99
 832    0443  69        		.byte	105
 833    0444  74        		.byte	116
 834    0445  79        		.byte	121
 835    0446  3A        		.byte	58
 836    0447  20        		.byte	32
 837    0448  25        		.byte	37
 838    0449  6C        		.byte	108
 839    044A  75        		.byte	117
 840    044B  20        		.byte	32
 841    044C  4D        		.byte	77
 842    044D  42        		.byte	66
 843    044E  79        		.byte	121
 844    044F  74        		.byte	116
 845    0450  65        		.byte	101
 846    0451  0A        		.byte	10
 847    0452  00        		.byte	0
 848                    	L522:
 849    0453  44        		.byte	68
 850    0454  65        		.byte	101
 851    0455  76        		.byte	118
 852    0456  69        		.byte	105
 853    0457  63        		.byte	99
 854    0458  65        		.byte	101
 855    0459  20        		.byte	32
 856    045A  75        		.byte	117
 857    045B  6C        		.byte	108
 858    045C  74        		.byte	116
 859    045D  72        		.byte	114
 860    045E  61        		.byte	97
 861    045F  20        		.byte	32
 862    0460  63        		.byte	99
 863    0461  61        		.byte	97
 864    0462  70        		.byte	112
 865    0463  61        		.byte	97
 866    0464  63        		.byte	99
 867    0465  69        		.byte	105
 868    0466  74        		.byte	116
 869    0467  79        		.byte	121
 870    0468  3A        		.byte	58
 871    0469  20        		.byte	32
 872    046A  25        		.byte	37
 873    046B  6C        		.byte	108
 874    046C  75        		.byte	117
 875    046D  20        		.byte	32
 876    046E  4D        		.byte	77
 877    046F  42        		.byte	66
 878    0470  79        		.byte	121
 879    0471  74        		.byte	116
 880    0472  65        		.byte	101
 881    0473  0A        		.byte	10
 882    0474  00        		.byte	0
 883                    	;  102  
 884                    	;  103  /* print OCR, CID and CSD registers*/
 885                    	;  104  void sdprtreg()
 886                    	;  105      {
 887                    	_sdprtreg:
 888    0475  CD0000    		call	c.savs0
 889    0478  21EEFF    		ld	hl,65518
 890    047B  39        		add	hl,sp
 891    047C  F9        		ld	sp,hl
 892                    	;  106      unsigned int n;
 893                    	;  107      unsigned int csize;
 894                    	;  108      unsigned long devsize;
 895                    	;  109      unsigned long capacity;
 896                    	;  110  
 897                    	;  111      if (!*sdinitok)
 898    047D  2A0000    		ld	hl,(_sdinitok)
 899    0480  7E        		ld	a,(hl)
 900    0481  B7        		or	a
 901    0482  2009      		jr	nz,L162
 902                    	;  112          {
 903                    	;  113          printf("SD card not initialized\n");
 904    0484  21FD02    		ld	hl,L55
 905    0487  CD0000    		call	_printf
 906                    	;  114          return;
 907    048A  C30000    		jp	c.rets0
 908                    	L162:
 909                    	;  115          }
 910                    	;  116      printf("SD card information:");
 911    048D  211603    		ld	hl,L56
 912    0490  CD0000    		call	_printf
 913                    	;  117      if (ocrreg[0] & 0x80)
 914    0493  3A0000    		ld	a,(_ocrreg)
 915    0496  CB7F      		bit	7,a
 916    0498  6F        		ld	l,a
 917    0499  2825      		jr	z,L172
 918                    	;  118          {
 919                    	;  119          if (ocrreg[0] & 0x40)
 920    049B  3A0000    		ld	a,(_ocrreg)
 921    049E  CB77      		bit	6,a
 922    04A0  6F        		ld	l,a
 923    04A1  2808      		jr	z,L103
 924                    	;  120              printf("  SD card ver. 2+, Block address\n");
 925    04A3  212B03    		ld	hl,L57
 926    04A6  CD0000    		call	_printf
 927                    	;  121          else
 928    04A9  1815      		jr	L172
 929                    	L103:
 930                    	;  122              {
 931                    	;  123              if (sdver2)
 932    04AB  2A0000    		ld	hl,(_sdver2)
 933    04AE  7C        		ld	a,h
 934    04AF  B5        		or	l
 935    04B0  2808      		jr	z,L123
 936                    	;  124                  printf("  SD card ver. 2+, Byte address\n");
 937    04B2  214D03    		ld	hl,L501
 938    04B5  CD0000    		call	_printf
 939                    	;  125              else
 940    04B8  1806      		jr	L172
 941                    	L123:
 942                    	;  126                  printf("  SD card ver. 1, Byte address\n");
 943    04BA  216E03    		ld	hl,L511
 944    04BD  CD0000    		call	_printf
 945                    	L172:
 946                    	;  127              }
 947                    	;  128          }
 948                    	;  129      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
 949    04C0  3A0000    		ld	a,(_cidreg)
 950    04C3  4F        		ld	c,a
 951    04C4  97        		sub	a
 952    04C5  47        		ld	b,a
 953    04C6  C5        		push	bc
 954    04C7  218E03    		ld	hl,L521
 955    04CA  CD0000    		call	_printf
 956    04CD  F1        		pop	af
 957                    	;  130      printf("OEM ID: %.2s, ", &cidreg[1]);
 958    04CE  210100    		ld	hl,_cidreg+1
 959    04D1  E5        		push	hl
 960    04D2  21AA03    		ld	hl,L531
 961    04D5  CD0000    		call	_printf
 962    04D8  F1        		pop	af
 963                    	;  131      printf("Product name: %.5s\n", &cidreg[3]);
 964    04D9  210300    		ld	hl,_cidreg+3
 965    04DC  E5        		push	hl
 966    04DD  21B903    		ld	hl,L541
 967    04E0  CD0000    		call	_printf
 968    04E3  F1        		pop	af
 969                    	;  132      printf("  Product revision: %d.%d, ",
 970                    	;  133             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 971    04E4  3A0800    		ld	a,(_cidreg+8)
 972    04E7  6F        		ld	l,a
 973    04E8  97        		sub	a
 974    04E9  67        		ld	h,a
 975    04EA  7D        		ld	a,l
 976    04EB  E60F      		and	15
 977    04ED  6F        		ld	l,a
 978    04EE  97        		sub	a
 979    04EF  67        		ld	h,a
 980    04F0  E5        		push	hl
 981    04F1  3A0800    		ld	a,(_cidreg+8)
 982    04F4  4F        		ld	c,a
 983    04F5  97        		sub	a
 984    04F6  47        		ld	b,a
 985    04F7  C5        		push	bc
 986    04F8  210400    		ld	hl,4
 987    04FB  E5        		push	hl
 988    04FC  CD0000    		call	c.irsh
 989    04FF  E1        		pop	hl
 990    0500  7D        		ld	a,l
 991    0501  E60F      		and	15
 992    0503  6F        		ld	l,a
 993    0504  97        		sub	a
 994    0505  67        		ld	h,a
 995    0506  E5        		push	hl
 996    0507  21CD03    		ld	hl,L551
 997    050A  CD0000    		call	_printf
 998    050D  F1        		pop	af
 999    050E  F1        		pop	af
1000                    	;  134      printf("Serial number: %lu\n",
1001                    	;  135             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
1002    050F  3A0900    		ld	a,(_cidreg+9)
1003    0512  4F        		ld	c,a
1004    0513  97        		sub	a
1005    0514  47        		ld	b,a
1006    0515  C5        		push	bc
1007    0516  211800    		ld	hl,24
1008    0519  E5        		push	hl
1009    051A  CD0000    		call	c.ilsh
1010    051D  E1        		pop	hl
1011    051E  E5        		push	hl
1012    051F  3A0A00    		ld	a,(_cidreg+10)
1013    0522  4F        		ld	c,a
1014    0523  97        		sub	a
1015    0524  47        		ld	b,a
1016    0525  C5        		push	bc
1017    0526  211000    		ld	hl,16
1018    0529  E5        		push	hl
1019    052A  CD0000    		call	c.ilsh
1020    052D  E1        		pop	hl
1021    052E  E3        		ex	(sp),hl
1022    052F  C1        		pop	bc
1023    0530  09        		add	hl,bc
1024    0531  E5        		push	hl
1025    0532  3A0B00    		ld	a,(_cidreg+11)
1026    0535  6F        		ld	l,a
1027    0536  97        		sub	a
1028    0537  67        		ld	h,a
1029    0538  29        		add	hl,hl
1030    0539  29        		add	hl,hl
1031    053A  29        		add	hl,hl
1032    053B  29        		add	hl,hl
1033    053C  29        		add	hl,hl
1034    053D  29        		add	hl,hl
1035    053E  29        		add	hl,hl
1036    053F  29        		add	hl,hl
1037    0540  E3        		ex	(sp),hl
1038    0541  C1        		pop	bc
1039    0542  09        		add	hl,bc
1040    0543  E5        		push	hl
1041    0544  3A0C00    		ld	a,(_cidreg+12)
1042    0547  6F        		ld	l,a
1043    0548  97        		sub	a
1044    0549  67        		ld	h,a
1045    054A  E3        		ex	(sp),hl
1046    054B  C1        		pop	bc
1047    054C  09        		add	hl,bc
1048    054D  E5        		push	hl
1049    054E  21E903    		ld	hl,L561
1050    0551  CD0000    		call	_printf
1051    0554  F1        		pop	af
1052                    	;  136      printf("  Manufacturing date: %d-%d, ",
1053                    	;  137             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
1054    0555  3A0E00    		ld	a,(_cidreg+14)
1055    0558  6F        		ld	l,a
1056    0559  97        		sub	a
1057    055A  67        		ld	h,a
1058    055B  7D        		ld	a,l
1059    055C  E60F      		and	15
1060    055E  6F        		ld	l,a
1061    055F  97        		sub	a
1062    0560  67        		ld	h,a
1063    0561  E5        		push	hl
1064    0562  3A0D00    		ld	a,(_cidreg+13)
1065    0565  6F        		ld	l,a
1066    0566  97        		sub	a
1067    0567  67        		ld	h,a
1068    0568  7D        		ld	a,l
1069    0569  E60F      		and	15
1070    056B  6F        		ld	l,a
1071    056C  97        		sub	a
1072    056D  67        		ld	h,a
1073    056E  29        		add	hl,hl
1074    056F  29        		add	hl,hl
1075    0570  29        		add	hl,hl
1076    0571  29        		add	hl,hl
1077    0572  01D007    		ld	bc,2000
1078    0575  09        		add	hl,bc
1079    0576  E5        		push	hl
1080    0577  3A0E00    		ld	a,(_cidreg+14)
1081    057A  4F        		ld	c,a
1082    057B  97        		sub	a
1083    057C  47        		ld	b,a
1084    057D  C5        		push	bc
1085    057E  210400    		ld	hl,4
1086    0581  E5        		push	hl
1087    0582  CD0000    		call	c.irsh
1088    0585  E1        		pop	hl
1089    0586  E3        		ex	(sp),hl
1090    0587  C1        		pop	bc
1091    0588  09        		add	hl,bc
1092    0589  E5        		push	hl
1093    058A  21FD03    		ld	hl,L571
1094    058D  CD0000    		call	_printf
1095    0590  F1        		pop	af
1096    0591  F1        		pop	af
1097                    	;  138      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
1098    0592  3A0000    		ld	a,(_csdreg)
1099    0595  E6C0      		and	192
1100    0597  C27506    		jp	nz,L143
1101                    	;  139          {
1102                    	;  140          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
1103    059A  3A0500    		ld	a,(_csdreg+5)
1104    059D  6F        		ld	l,a
1105    059E  97        		sub	a
1106    059F  67        		ld	h,a
1107    05A0  7D        		ld	a,l
1108    05A1  E60F      		and	15
1109    05A3  6F        		ld	l,a
1110    05A4  97        		sub	a
1111    05A5  67        		ld	h,a
1112    05A6  E5        		push	hl
1113    05A7  3A0A00    		ld	a,(_csdreg+10)
1114    05AA  6F        		ld	l,a
1115    05AB  97        		sub	a
1116    05AC  67        		ld	h,a
1117    05AD  7D        		ld	a,l
1118    05AE  E680      		and	128
1119    05B0  6F        		ld	l,a
1120    05B1  97        		sub	a
1121    05B2  67        		ld	h,a
1122    05B3  E5        		push	hl
1123    05B4  210700    		ld	hl,7
1124    05B7  E5        		push	hl
1125    05B8  CD0000    		call	c.irsh
1126    05BB  E1        		pop	hl
1127    05BC  E3        		ex	(sp),hl
1128    05BD  C1        		pop	bc
1129    05BE  09        		add	hl,bc
1130    05BF  E5        		push	hl
1131    05C0  3A0900    		ld	a,(_csdreg+9)
1132    05C3  6F        		ld	l,a
1133    05C4  97        		sub	a
1134    05C5  67        		ld	h,a
1135    05C6  7D        		ld	a,l
1136    05C7  E603      		and	3
1137    05C9  6F        		ld	l,a
1138    05CA  97        		sub	a
1139    05CB  67        		ld	h,a
1140    05CC  29        		add	hl,hl
1141    05CD  E3        		ex	(sp),hl
1142    05CE  C1        		pop	bc
1143    05CF  09        		add	hl,bc
1144    05D0  23        		inc	hl
1145    05D1  23        		inc	hl
1146    05D2  DD75F8    		ld	(ix-8),l
1147    05D5  DD74F9    		ld	(ix-7),h
1148                    	;  141          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
1149                    	;  142                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
1150    05D8  3A0800    		ld	a,(_csdreg+8)
1151    05DB  4F        		ld	c,a
1152    05DC  97        		sub	a
1153    05DD  47        		ld	b,a
1154    05DE  C5        		push	bc
1155    05DF  210600    		ld	hl,6
1156    05E2  E5        		push	hl
1157    05E3  CD0000    		call	c.irsh
1158    05E6  E1        		pop	hl
1159    05E7  E5        		push	hl
1160    05E8  3A0700    		ld	a,(_csdreg+7)
1161    05EB  6F        		ld	l,a
1162    05EC  97        		sub	a
1163    05ED  67        		ld	h,a
1164    05EE  29        		add	hl,hl
1165    05EF  29        		add	hl,hl
1166    05F0  E3        		ex	(sp),hl
1167    05F1  C1        		pop	bc
1168    05F2  09        		add	hl,bc
1169    05F3  E5        		push	hl
1170    05F4  3A0600    		ld	a,(_csdreg+6)
1171    05F7  6F        		ld	l,a
1172    05F8  97        		sub	a
1173    05F9  67        		ld	h,a
1174    05FA  7D        		ld	a,l
1175    05FB  E603      		and	3
1176    05FD  6F        		ld	l,a
1177    05FE  97        		sub	a
1178    05FF  67        		ld	h,a
1179    0600  E5        		push	hl
1180    0601  210A00    		ld	hl,10
1181    0604  E5        		push	hl
1182    0605  CD0000    		call	c.ilsh
1183    0608  E1        		pop	hl
1184    0609  E3        		ex	(sp),hl
1185    060A  C1        		pop	bc
1186    060B  09        		add	hl,bc
1187    060C  23        		inc	hl
1188    060D  DD75F6    		ld	(ix-10),l
1189    0610  DD74F7    		ld	(ix-9),h
1190                    	;  143          capacity = (unsigned long) csize << (n-10);
1191    0613  DDE5      		push	ix
1192    0615  C1        		pop	bc
1193    0616  21EEFF    		ld	hl,65518
1194    0619  09        		add	hl,bc
1195    061A  E5        		push	hl
1196    061B  DDE5      		push	ix
1197    061D  C1        		pop	bc
1198    061E  21F6FF    		ld	hl,65526
1199    0621  09        		add	hl,bc
1200    0622  4D        		ld	c,l
1201    0623  44        		ld	b,h
1202    0624  97        		sub	a
1203    0625  320000    		ld	(c.r0),a
1204    0628  320100    		ld	(c.r0+1),a
1205    062B  0A        		ld	a,(bc)
1206    062C  320200    		ld	(c.r0+2),a
1207    062F  03        		inc	bc
1208    0630  0A        		ld	a,(bc)
1209    0631  320300    		ld	(c.r0+3),a
1210    0634  210000    		ld	hl,c.r0
1211    0637  E5        		push	hl
1212    0638  DD6EF8    		ld	l,(ix-8)
1213    063B  DD66F9    		ld	h,(ix-7)
1214    063E  01F6FF    		ld	bc,65526
1215    0641  09        		add	hl,bc
1216    0642  E5        		push	hl
1217    0643  CD0000    		call	c.llsh
1218    0646  CD0000    		call	c.mvl
1219    0649  F1        		pop	af
1220                    	;  144          printf("Device capacity: %lu MByte\n", capacity >> 10);
1221    064A  DDE5      		push	ix
1222    064C  C1        		pop	bc
1223    064D  21EEFF    		ld	hl,65518
1224    0650  09        		add	hl,bc
1225    0651  CD0000    		call	c.0mvf
1226    0654  210000    		ld	hl,c.r0
1227    0657  E5        		push	hl
1228    0658  210A00    		ld	hl,10
1229    065B  E5        		push	hl
1230    065C  CD0000    		call	c.ulrsh
1231    065F  E1        		pop	hl
1232    0660  23        		inc	hl
1233    0661  23        		inc	hl
1234    0662  4E        		ld	c,(hl)
1235    0663  23        		inc	hl
1236    0664  46        		ld	b,(hl)
1237    0665  C5        		push	bc
1238    0666  2B        		dec	hl
1239    0667  2B        		dec	hl
1240    0668  2B        		dec	hl
1241    0669  4E        		ld	c,(hl)
1242    066A  23        		inc	hl
1243    066B  46        		ld	b,(hl)
1244    066C  C5        		push	bc
1245    066D  211B04    		ld	hl,L502
1246    0670  CD0000    		call	_printf
1247    0673  F1        		pop	af
1248    0674  F1        		pop	af
1249                    	L143:
1250                    	;  145          }
1251                    	;  146      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
1252    0675  3A0000    		ld	a,(_csdreg)
1253    0678  6F        		ld	l,a
1254    0679  97        		sub	a
1255    067A  67        		ld	h,a
1256    067B  7D        		ld	a,l
1257    067C  E6C0      		and	192
1258    067E  6F        		ld	l,a
1259    067F  97        		sub	a
1260    0680  67        		ld	h,a
1261    0681  7D        		ld	a,l
1262    0682  FE40      		cp	64
1263    0684  2003      		jr	nz,L42
1264    0686  7C        		ld	a,h
1265    0687  FE00      		cp	0
1266                    	L42:
1267    0689  C25C07    		jp	nz,L153
1268                    	;  147          {
1269                    	;  148          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
1270                    	;  149                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1271    068C  DDE5      		push	ix
1272    068E  C1        		pop	bc
1273    068F  21F2FF    		ld	hl,65522
1274    0692  09        		add	hl,bc
1275    0693  E5        		push	hl
1276    0694  97        		sub	a
1277    0695  320000    		ld	(c.r0),a
1278    0698  320100    		ld	(c.r0+1),a
1279    069B  3A0800    		ld	a,(_csdreg+8)
1280    069E  320200    		ld	(c.r0+2),a
1281    06A1  97        		sub	a
1282    06A2  320300    		ld	(c.r0+3),a
1283    06A5  210000    		ld	hl,c.r0
1284    06A8  E5        		push	hl
1285    06A9  210800    		ld	hl,8
1286    06AC  E5        		push	hl
1287    06AD  CD0000    		call	c.llsh
1288    06B0  97        		sub	a
1289    06B1  320000    		ld	(c.r1),a
1290    06B4  320100    		ld	(c.r1+1),a
1291    06B7  3A0900    		ld	a,(_csdreg+9)
1292    06BA  320200    		ld	(c.r1+2),a
1293    06BD  97        		sub	a
1294    06BE  320300    		ld	(c.r1+3),a
1295    06C1  210000    		ld	hl,c.r1
1296    06C4  E5        		push	hl
1297    06C5  CD0000    		call	c.ladd
1298    06C8  3A0700    		ld	a,(_csdreg+7)
1299    06CB  6F        		ld	l,a
1300    06CC  97        		sub	a
1301    06CD  67        		ld	h,a
1302    06CE  7D        		ld	a,l
1303    06CF  E63F      		and	63
1304    06D1  6F        		ld	l,a
1305    06D2  97        		sub	a
1306    06D3  67        		ld	h,a
1307    06D4  4D        		ld	c,l
1308    06D5  44        		ld	b,h
1309    06D6  78        		ld	a,b
1310    06D7  87        		add	a,a
1311    06D8  9F        		sbc	a,a
1312    06D9  320000    		ld	(c.r1),a
1313    06DC  320100    		ld	(c.r1+1),a
1314    06DF  78        		ld	a,b
1315    06E0  320300    		ld	(c.r1+3),a
1316    06E3  79        		ld	a,c
1317    06E4  320200    		ld	(c.r1+2),a
1318    06E7  210000    		ld	hl,c.r1
1319    06EA  E5        		push	hl
1320    06EB  211000    		ld	hl,16
1321    06EE  E5        		push	hl
1322    06EF  CD0000    		call	c.llsh
1323    06F2  CD0000    		call	c.ladd
1324    06F5  3E01      		ld	a,1
1325    06F7  320200    		ld	(c.r1+2),a
1326    06FA  87        		add	a,a
1327    06FB  9F        		sbc	a,a
1328    06FC  320300    		ld	(c.r1+3),a
1329    06FF  320100    		ld	(c.r1+1),a
1330    0702  320000    		ld	(c.r1),a
1331    0705  210000    		ld	hl,c.r1
1332    0708  E5        		push	hl
1333    0709  CD0000    		call	c.ladd
1334    070C  CD0000    		call	c.mvl
1335    070F  F1        		pop	af
1336                    	;  150          capacity = devsize << 9;
1337    0710  DDE5      		push	ix
1338    0712  C1        		pop	bc
1339    0713  21EEFF    		ld	hl,65518
1340    0716  09        		add	hl,bc
1341    0717  E5        		push	hl
1342    0718  DDE5      		push	ix
1343    071A  C1        		pop	bc
1344    071B  21F2FF    		ld	hl,65522
1345    071E  09        		add	hl,bc
1346    071F  CD0000    		call	c.0mvf
1347    0722  210000    		ld	hl,c.r0
1348    0725  E5        		push	hl
1349    0726  210900    		ld	hl,9
1350    0729  E5        		push	hl
1351    072A  CD0000    		call	c.llsh
1352    072D  CD0000    		call	c.mvl
1353    0730  F1        		pop	af
1354                    	;  151          printf("Device capacity: %lu MByte\n", capacity >> 10);
1355    0731  DDE5      		push	ix
1356    0733  C1        		pop	bc
1357    0734  21EEFF    		ld	hl,65518
1358    0737  09        		add	hl,bc
1359    0738  CD0000    		call	c.0mvf
1360    073B  210000    		ld	hl,c.r0
1361    073E  E5        		push	hl
1362    073F  210A00    		ld	hl,10
1363    0742  E5        		push	hl
1364    0743  CD0000    		call	c.ulrsh
1365    0746  E1        		pop	hl
1366    0747  23        		inc	hl
1367    0748  23        		inc	hl
1368    0749  4E        		ld	c,(hl)
1369    074A  23        		inc	hl
1370    074B  46        		ld	b,(hl)
1371    074C  C5        		push	bc
1372    074D  2B        		dec	hl
1373    074E  2B        		dec	hl
1374    074F  2B        		dec	hl
1375    0750  4E        		ld	c,(hl)
1376    0751  23        		inc	hl
1377    0752  46        		ld	b,(hl)
1378    0753  C5        		push	bc
1379    0754  213704    		ld	hl,L512
1380    0757  CD0000    		call	_printf
1381    075A  F1        		pop	af
1382    075B  F1        		pop	af
1383                    	L153:
1384                    	;  152          }
1385                    	;  153      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
1386    075C  3A0000    		ld	a,(_csdreg)
1387    075F  6F        		ld	l,a
1388    0760  97        		sub	a
1389    0761  67        		ld	h,a
1390    0762  7D        		ld	a,l
1391    0763  E6C0      		and	192
1392    0765  6F        		ld	l,a
1393    0766  97        		sub	a
1394    0767  67        		ld	h,a
1395    0768  7D        		ld	a,l
1396    0769  FE80      		cp	128
1397    076B  2003      		jr	nz,L62
1398    076D  7C        		ld	a,h
1399    076E  FE00      		cp	0
1400                    	L62:
1401    0770  C24308    		jp	nz,L163
1402                    	;  154          {
1403                    	;  155          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
1404                    	;  156                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1405    0773  DDE5      		push	ix
1406    0775  C1        		pop	bc
1407    0776  21F2FF    		ld	hl,65522
1408    0779  09        		add	hl,bc
1409    077A  E5        		push	hl
1410    077B  97        		sub	a
1411    077C  320000    		ld	(c.r0),a
1412    077F  320100    		ld	(c.r0+1),a
1413    0782  3A0800    		ld	a,(_csdreg+8)
1414    0785  320200    		ld	(c.r0+2),a
1415    0788  97        		sub	a
1416    0789  320300    		ld	(c.r0+3),a
1417    078C  210000    		ld	hl,c.r0
1418    078F  E5        		push	hl
1419    0790  210800    		ld	hl,8
1420    0793  E5        		push	hl
1421    0794  CD0000    		call	c.llsh
1422    0797  97        		sub	a
1423    0798  320000    		ld	(c.r1),a
1424    079B  320100    		ld	(c.r1+1),a
1425    079E  3A0900    		ld	a,(_csdreg+9)
1426    07A1  320200    		ld	(c.r1+2),a
1427    07A4  97        		sub	a
1428    07A5  320300    		ld	(c.r1+3),a
1429    07A8  210000    		ld	hl,c.r1
1430    07AB  E5        		push	hl
1431    07AC  CD0000    		call	c.ladd
1432    07AF  3A0700    		ld	a,(_csdreg+7)
1433    07B2  6F        		ld	l,a
1434    07B3  97        		sub	a
1435    07B4  67        		ld	h,a
1436    07B5  7D        		ld	a,l
1437    07B6  E63F      		and	63
1438    07B8  6F        		ld	l,a
1439    07B9  97        		sub	a
1440    07BA  67        		ld	h,a
1441    07BB  4D        		ld	c,l
1442    07BC  44        		ld	b,h
1443    07BD  78        		ld	a,b
1444    07BE  87        		add	a,a
1445    07BF  9F        		sbc	a,a
1446    07C0  320000    		ld	(c.r1),a
1447    07C3  320100    		ld	(c.r1+1),a
1448    07C6  78        		ld	a,b
1449    07C7  320300    		ld	(c.r1+3),a
1450    07CA  79        		ld	a,c
1451    07CB  320200    		ld	(c.r1+2),a
1452    07CE  210000    		ld	hl,c.r1
1453    07D1  E5        		push	hl
1454    07D2  211000    		ld	hl,16
1455    07D5  E5        		push	hl
1456    07D6  CD0000    		call	c.llsh
1457    07D9  CD0000    		call	c.ladd
1458    07DC  3E01      		ld	a,1
1459    07DE  320200    		ld	(c.r1+2),a
1460    07E1  87        		add	a,a
1461    07E2  9F        		sbc	a,a
1462    07E3  320300    		ld	(c.r1+3),a
1463    07E6  320100    		ld	(c.r1+1),a
1464    07E9  320000    		ld	(c.r1),a
1465    07EC  210000    		ld	hl,c.r1
1466    07EF  E5        		push	hl
1467    07F0  CD0000    		call	c.ladd
1468    07F3  CD0000    		call	c.mvl
1469    07F6  F1        		pop	af
1470                    	;  157          capacity = devsize << 9;
1471    07F7  DDE5      		push	ix
1472    07F9  C1        		pop	bc
1473    07FA  21EEFF    		ld	hl,65518
1474    07FD  09        		add	hl,bc
1475    07FE  E5        		push	hl
1476    07FF  DDE5      		push	ix
1477    0801  C1        		pop	bc
1478    0802  21F2FF    		ld	hl,65522
1479    0805  09        		add	hl,bc
1480    0806  CD0000    		call	c.0mvf
1481    0809  210000    		ld	hl,c.r0
1482    080C  E5        		push	hl
1483    080D  210900    		ld	hl,9
1484    0810  E5        		push	hl
1485    0811  CD0000    		call	c.llsh
1486    0814  CD0000    		call	c.mvl
1487    0817  F1        		pop	af
1488                    	;  158          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
1489    0818  DDE5      		push	ix
1490    081A  C1        		pop	bc
1491    081B  21EEFF    		ld	hl,65518
1492    081E  09        		add	hl,bc
1493    081F  CD0000    		call	c.0mvf
1494    0822  210000    		ld	hl,c.r0
1495    0825  E5        		push	hl
1496    0826  210A00    		ld	hl,10
1497    0829  E5        		push	hl
1498    082A  CD0000    		call	c.ulrsh
1499    082D  E1        		pop	hl
1500    082E  23        		inc	hl
1501    082F  23        		inc	hl
1502    0830  4E        		ld	c,(hl)
1503    0831  23        		inc	hl
1504    0832  46        		ld	b,(hl)
1505    0833  C5        		push	bc
1506    0834  2B        		dec	hl
1507    0835  2B        		dec	hl
1508    0836  2B        		dec	hl
1509    0837  4E        		ld	c,(hl)
1510    0838  23        		inc	hl
1511    0839  46        		ld	b,(hl)
1512    083A  C5        		push	bc
1513    083B  215304    		ld	hl,L522
1514    083E  CD0000    		call	_printf
1515    0841  F1        		pop	af
1516    0842  F1        		pop	af
1517                    	L163:
1518                    	;  159          }
1519                    	;  160      }
1520    0843  C30000    		jp	c.rets0
1521                    		.external	c.rets0
1522                    		.external	c.ulrsh
1523                    		.external	c.savs0
1524                    		.external	_sdver2
1525                    		.external	c.r1
1526                    		.external	c.r0
1527                    		.external	_printf
1528                    		.public	_blk2ul
1529                    		.public	_ul2blk
1530                    		.external	c.ladd
1531                    		.external	_ocrreg
1532                    		.external	c.mvl
1533                    		.external	_csdreg
1534                    		.external	_putchar
1535                    		.external	c.rets
1536                    		.external	c.savs
1537                    		.external	_cidreg
1538                    		.external	c.0mvf
1539                    		.public	_sdprtreg
1540                    		.external	c.imul
1541                    		.external	c.irsh
1542                    		.public	_sddatprt
1543                    		.external	_sdinitok
1544                    		.external	c.llsh
1545                    		.external	c.ilsh
1546                    		.end
