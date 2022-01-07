   1                    	;    1  /* z80sdtst.c
   2                    	;    2   *
   3                    	;    3   *  Test Z80 SPI/SD card interface on Z80 Computer
   4                    	;    4   *  program compiled with Whitesmiths compiler
   5                    	;    5   *
   6                    	;    6   *  You are free to use, modify, and redistribute
   7                    	;    7   *  this source code. No warranties given.
   8                    	;    8   *  Hastily Cobbled Together 2021 and 2022
   9                    	;    9   *  by Hans-Ake Lund
  10                    	;   10   *
  11                    	;   11   *  This code was hacked together to implement/test
  12                    	;   12   *  a "bit-banger" SPI interface to a SD card for
  13                    	;   13   *  the Z80 computer.
  14                    	;   14   *
  15                    	;   15   *  The idea is to use his program to understand
  16                    	;   16   *  how the SPI and SD card interfaces and the
  17                    	;   17   *  partitioning of a SD card works in order
  18                    	;   18   *  to make a CP/M disk driver for SD card
  19                    	;   19   *  that handles multiple partitions and
  20                    	;   20   *  presents a CP/M drive for each partition.
  21                    	;   21   *
  22                    	;   22   *  In the process the Whitesmith C compiler for
  23                    	;   23   *  Z80 was also rather thoroughly tested.
  24                    	;   24   *
  25                    	;   25   *  Be warned that this is a very ugly hack
  26                    	;   26   *  the intention is to clean it up to much
  27                    	;   27   *  more nice looking code.
  28                    	;   28   *
  29                    	;   29   */
  30                    	;   30  
  31                    	;   31  #include <std.h>
  32                    	;   32  #include "z80computer.h"
  33                    	;   33  #include "builddate.h"
  34                    		.psect	_data
  35                    	_builddate:
  36    0000  42        		.byte	66
  37    0001  75        		.byte	117
  38    0002  69        		.byte	105
  39    0003  6C        		.byte	108
  40    0004  74        		.byte	116
  41    0005  20        		.byte	32
  42    0006  32        		.byte	50
  43    0007  30        		.byte	48
  44    0008  32        		.byte	50
  45    0009  32        		.byte	50
  46    000A  2D        		.byte	45
  47    000B  30        		.byte	48
  48    000C  31        		.byte	49
  49    000D  2D        		.byte	45
  50    000E  30        		.byte	48
  51    000F  37        		.byte	55
  52    0010  20        		.byte	32
  53    0011  31        		.byte	49
  54    0012  31        		.byte	49
  55    0013  3A        		.byte	58
  56    0014  34        		.byte	52
  57    0015  30        		.byte	48
  58    0016  00        		.byte	0
  59                    	;   34  
  60                    	;   35  #define SDTSTVER "\nz80sdtst version 2.0, "
  61                    	;   36  
  62                    	;   37  unsigned char rxbuf[520] = {0};
  63                    		.psect	_bss
  64                    	_rxbuf:
  65                    		.byte	[520]
  66                    	;   38  unsigned char statbuf[30] = {0};
  67                    	_statbuf:
  68                    		.byte	[30]
  69                    	;   39  
  70                    	;   40  unsigned char ocrreg[4] = {0};
  71                    	_ocrreg:
  72                    		.byte	[4]
  73                    	;   41  unsigned char cidreg[16] = {0};
  74                    	_cidreg:
  75                    		.byte	[16]
  76                    	;   42  unsigned char csdreg[16] = {0};
  77                    	_csdreg:
  78                    		.byte	[16]
  79                    	;   43  
  80                    	;   44  int debugflg = 0;
  81                    	_debugflg:
  82                    		.byte	[2]
  83                    	;   45  int ready = NO;
  84                    	_ready:
  85                    		.byte	[2]
  86                    	;   46  int prthex = NO;
  87                    	_prthex:
  88                    		.byte	[2]
  89                    	;   47  unsigned char *dataptr;
  90                    	;   48  unsigned char *rxtxptr = NULL;
  91                    	_rxtxptr:
  92                    		.byte	[2]
  93                    	;   49  unsigned long blockno = 0;
  94                    	_blockno:
  95                    		.byte	[4]
  96                    	;   50  unsigned long blkmult = 1;
  97                    		.psect	_data
  98                    	_blkmult:
  99    0017  00        		.byte	0
 100    0018  00        		.byte	0
 101    0019  01        		.byte	1
 102    001A  00        		.byte	0
 103                    		.psect	_text
 104                    	;   51  
 105                    	;   52  /* CRC routines from:
 106                    	;   53   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
 107                    	;   54   */
 108                    	;   55  
 109                    	;   56  /*
 110                    	;   57  // Calculate CRC7
 111                    	;   58  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
 112                    	;   59  // input:
 113                    	;   60  //   crcIn - the CRC before (0 for first step)
 114                    	;   61  //   data - byte for CRC calculation
 115                    	;   62  // return: the new CRC7
 116                    	;   63  */
 117                    	;   64  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
 118                    	;   65          {
 119                    	_CRC7_one:
 120    0000  CD0000    		call	c.savs
 121    0003  F5        		push	af
 122    0004  F5        		push	af
 123    0005  F5        		push	af
 124    0006  F5        		push	af
 125                    	;   66          const unsigned char g = 0x89;
 126    0007  DD36F989  		ld	(ix-7),137
 127                    	;   67          unsigned char i;
 128                    	;   68  
 129                    	;   69          crcIn ^= data;
 130    000B  DD7E04    		ld	a,(ix+4)
 131    000E  DDAE06    		xor	(ix+6)
 132    0011  DD7704    		ld	(ix+4),a
 133    0014  DD7E05    		ld	a,(ix+5)
 134    0017  DDAE07    		xor	(ix+7)
 135    001A  DD7705    		ld	(ix+5),a
 136                    	;   70          for (i = 0; i < 8; i++)
 137    001D  DD36F800  		ld	(ix-8),0
 138                    	L1:
 139    0021  DD7EF8    		ld	a,(ix-8)
 140    0024  FE08      		cp	8
 141    0026  302F      		jr	nc,L11
 142                    	;   71                  {
 143                    	;   72                  if (crcIn & 0x80) crcIn ^= g;
 144    0028  DD6E04    		ld	l,(ix+4)
 145    002B  DD6605    		ld	h,(ix+5)
 146    002E  CB7D      		bit	7,l
 147    0030  2813      		jr	z,L14
 148    0032  DD6EF9    		ld	l,(ix-7)
 149    0035  97        		sub	a
 150    0036  67        		ld	h,a
 151    0037  DD7E04    		ld	a,(ix+4)
 152    003A  AD        		xor	l
 153    003B  DD7704    		ld	(ix+4),a
 154    003E  DD7E05    		ld	a,(ix+5)
 155    0041  AC        		xor	h
 156    0042  DD7705    		ld	(ix+5),a
 157                    	L14:
 158                    	;   73                  crcIn <<= 1;
 159    0045  DD6E04    		ld	l,(ix+4)
 160    0048  DD6605    		ld	h,(ix+5)
 161    004B  29        		add	hl,hl
 162    004C  DD7504    		ld	(ix+4),l
 163    004F  DD7405    		ld	(ix+5),h
 164                    	;   74                  }
 165    0052  DD34F8    		inc	(ix-8)
 166    0055  18CA      		jr	L1
 167                    	L11:
 168                    	;   75  
 169                    	;   76          return crcIn;
 170    0057  DD6E04    		ld	l,(ix+4)
 171    005A  DD6605    		ld	h,(ix+5)
 172    005D  4D        		ld	c,l
 173    005E  44        		ld	b,h
 174    005F  C30000    		jp	c.rets
 175                    	;   77          }
 176                    	;   78  
 177                    	;   79  /*
 178                    	;   80  // Calculate CRC7 value of the buffer
 179                    	;   81  // input:
 180                    	;   82  //   pBuf - pointer to the buffer
 181                    	;   83  //   len - length of the buffer
 182                    	;   84  // return: the CRC7 value
 183                    	;   85  */
 184                    	;   86  unsigned char CRC7_buf(unsigned char *pBuf, unsigned char len)
 185                    	;   87          {
 186                    	_CRC7_buf:
 187    0062  CD0000    		call	c.savs
 188    0065  21F9FF    		ld	hl,65529
 189    0068  39        		add	hl,sp
 190    0069  F9        		ld	sp,hl
 191                    	;   88          unsigned char crc = 0;
 192    006A  DD36F900  		ld	(ix-7),0
 193                    	L15:
 194                    	;   89  
 195                    	;   90          while (len--)
 196    006E  DD6E06    		ld	l,(ix+6)
 197    0071  DD6607    		ld	h,(ix+7)
 198    0074  E5        		push	hl
 199    0075  DD6E06    		ld	l,(ix+6)
 200    0078  DD6607    		ld	h,(ix+7)
 201    007B  2B        		dec	hl
 202    007C  DD7506    		ld	(ix+6),l
 203    007F  DD7407    		ld	(ix+7),h
 204    0082  E1        		pop	hl
 205    0083  7D        		ld	a,l
 206    0084  B4        		or	h
 207    0085  2820      		jr	z,L16
 208                    	;   91                  crc = CRC7_one(crc,*pBuf++);
 209    0087  DD6E04    		ld	l,(ix+4)
 210    008A  DD6605    		ld	h,(ix+5)
 211    008D  DD3404    		inc	(ix+4)
 212    0090  2003      		jr	nz,L6
 213    0092  DD3405    		inc	(ix+5)
 214                    	L6:
 215    0095  6E        		ld	l,(hl)
 216    0096  97        		sub	a
 217    0097  67        		ld	h,a
 218    0098  E5        		push	hl
 219    0099  DD6EF9    		ld	l,(ix-7)
 220    009C  97        		sub	a
 221    009D  67        		ld	h,a
 222    009E  CD0000    		call	_CRC7_one
 223    00A1  F1        		pop	af
 224    00A2  DD71F9    		ld	(ix-7),c
 225    00A5  18C7      		jr	L15
 226                    	L16:
 227                    	;   92  
 228                    	;   93          return crc;
 229    00A7  DD6EF9    		ld	l,(ix-7)
 230    00AA  97        		sub	a
 231    00AB  67        		ld	h,a
 232    00AC  4D        		ld	c,l
 233    00AD  44        		ld	b,h
 234    00AE  C30000    		jp	c.rets
 235                    	;   94          }
 236                    	;   95  
 237                    	;   96  /*
 238                    	;   97  // Calculate CRC16 CCITT
 239                    	;   98  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
 240                    	;   99  // input:
 241                    	;  100  //   crcIn - the CRC before (0 for rist step)
 242                    	;  101  //   data - byte for CRC calculation
 243                    	;  102  // return: the CRC16 value
 244                    	;  103  */
 245                    	;  104  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
 246                    	;  105          {
 247                    	_CRC16_one:
 248    00B1  CD0000    		call	c.savs
 249                    	;  106          crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
 250    00B4  DD6E04    		ld	l,(ix+4)
 251    00B7  DD6605    		ld	h,(ix+5)
 252    00BA  E5        		push	hl
 253    00BB  210800    		ld	hl,8
 254    00BE  E5        		push	hl
 255    00BF  CD0000    		call	c.ursh
 256    00C2  E1        		pop	hl
 257    00C3  E5        		push	hl
 258    00C4  DD6E04    		ld	l,(ix+4)
 259    00C7  DD6605    		ld	h,(ix+5)
 260    00CA  29        		add	hl,hl
 261    00CB  29        		add	hl,hl
 262    00CC  29        		add	hl,hl
 263    00CD  29        		add	hl,hl
 264    00CE  29        		add	hl,hl
 265    00CF  29        		add	hl,hl
 266    00D0  29        		add	hl,hl
 267    00D1  29        		add	hl,hl
 268    00D2  C1        		pop	bc
 269    00D3  79        		ld	a,c
 270    00D4  B5        		or	l
 271    00D5  4F        		ld	c,a
 272    00D6  78        		ld	a,b
 273    00D7  B4        		or	h
 274    00D8  47        		ld	b,a
 275    00D9  DD7104    		ld	(ix+4),c
 276    00DC  DD7005    		ld	(ix+5),b
 277                    	;  107          crcIn ^=  data;
 278    00DF  DD7E04    		ld	a,(ix+4)
 279    00E2  DDAE06    		xor	(ix+6)
 280    00E5  DD7704    		ld	(ix+4),a
 281    00E8  DD7E05    		ld	a,(ix+5)
 282    00EB  DDAE07    		xor	(ix+7)
 283    00EE  DD7705    		ld	(ix+5),a
 284                    	;  108          crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
 285    00F1  DD6E04    		ld	l,(ix+4)
 286    00F4  DD6605    		ld	h,(ix+5)
 287    00F7  7D        		ld	a,l
 288    00F8  E6FF      		and	255
 289    00FA  6F        		ld	l,a
 290    00FB  97        		sub	a
 291    00FC  67        		ld	h,a
 292    00FD  4D        		ld	c,l
 293    00FE  97        		sub	a
 294    00FF  47        		ld	b,a
 295    0100  C5        		push	bc
 296    0101  210400    		ld	hl,4
 297    0104  E5        		push	hl
 298    0105  CD0000    		call	c.irsh
 299    0108  E1        		pop	hl
 300    0109  DD7E04    		ld	a,(ix+4)
 301    010C  AD        		xor	l
 302    010D  DD7704    		ld	(ix+4),a
 303    0110  DD7E05    		ld	a,(ix+5)
 304    0113  AC        		xor	h
 305    0114  DD7705    		ld	(ix+5),a
 306                    	;  109          crcIn ^= (crcIn << 8) << 4;
 307    0117  DD6E04    		ld	l,(ix+4)
 308    011A  DD6605    		ld	h,(ix+5)
 309    011D  29        		add	hl,hl
 310    011E  29        		add	hl,hl
 311    011F  29        		add	hl,hl
 312    0120  29        		add	hl,hl
 313    0121  29        		add	hl,hl
 314    0122  29        		add	hl,hl
 315    0123  29        		add	hl,hl
 316    0124  29        		add	hl,hl
 317    0125  29        		add	hl,hl
 318    0126  29        		add	hl,hl
 319    0127  29        		add	hl,hl
 320    0128  29        		add	hl,hl
 321    0129  DD7E04    		ld	a,(ix+4)
 322    012C  AD        		xor	l
 323    012D  DD7704    		ld	(ix+4),a
 324    0130  DD7E05    		ld	a,(ix+5)
 325    0133  AC        		xor	h
 326    0134  DD7705    		ld	(ix+5),a
 327                    	;  110          crcIn ^= ((crcIn & 0xff) << 4) << 1;
 328    0137  DD6E04    		ld	l,(ix+4)
 329    013A  DD6605    		ld	h,(ix+5)
 330    013D  7D        		ld	a,l
 331    013E  E6FF      		and	255
 332    0140  6F        		ld	l,a
 333    0141  97        		sub	a
 334    0142  67        		ld	h,a
 335    0143  29        		add	hl,hl
 336    0144  29        		add	hl,hl
 337    0145  29        		add	hl,hl
 338    0146  29        		add	hl,hl
 339    0147  29        		add	hl,hl
 340    0148  DD7E04    		ld	a,(ix+4)
 341    014B  AD        		xor	l
 342    014C  DD7704    		ld	(ix+4),a
 343    014F  DD7E05    		ld	a,(ix+5)
 344    0152  AC        		xor	h
 345    0153  DD7705    		ld	(ix+5),a
 346                    	;  111  
 347                    	;  112          return crcIn;
 348    0156  DD4E04    		ld	c,(ix+4)
 349    0159  DD4605    		ld	b,(ix+5)
 350    015C  C30000    		jp	c.rets
 351                    	;  113          }
 352                    	;  114  
 353                    	;  115  /*
 354                    	;  116  // Calculate CRC16 CCITT value of the buffer
 355                    	;  117  // input:
 356                    	;  118  //   pBuf - pointer to the buffer
 357                    	;  119  //   len - length of the buffer
 358                    	;  120  // return: the CRC16 value
 359                    	;  121  */
 360                    	;  122  unsigned int CRC16_buf(const unsigned char * pBuf, unsigned int len)
 361                    	;  123          {
 362                    	_CRC16_buf:
 363    015F  CD0000    		call	c.savs
 364    0162  F5        		push	af
 365    0163  F5        		push	af
 366    0164  F5        		push	af
 367    0165  F5        		push	af
 368                    	;  124          unsigned int crc = 0;
 369    0166  DD36F800  		ld	(ix-8),0
 370    016A  DD36F900  		ld	(ix-7),0
 371                    	L17:
 372                    	;  125  
 373                    	;  126          while (len--)
 374    016E  DD6E06    		ld	l,(ix+6)
 375    0171  DD6607    		ld	h,(ix+7)
 376    0174  DD4E06    		ld	c,(ix+6)
 377    0177  DD4607    		ld	b,(ix+7)
 378    017A  0B        		dec	bc
 379    017B  DD7106    		ld	(ix+6),c
 380    017E  DD7007    		ld	(ix+7),b
 381    0181  7D        		ld	a,l
 382    0182  B4        		or	h
 383    0183  2824      		jr	z,L101
 384                    	;  127                  crc = CRC16_one(crc,*pBuf++);
 385    0185  DD6E04    		ld	l,(ix+4)
 386    0188  DD6605    		ld	h,(ix+5)
 387    018B  DD3404    		inc	(ix+4)
 388    018E  2003      		jr	nz,L41
 389    0190  DD3405    		inc	(ix+5)
 390                    	L41:
 391    0193  6E        		ld	l,(hl)
 392    0194  97        		sub	a
 393    0195  67        		ld	h,a
 394    0196  E5        		push	hl
 395    0197  DD6EF8    		ld	l,(ix-8)
 396    019A  DD66F9    		ld	h,(ix-7)
 397    019D  CDB100    		call	_CRC16_one
 398    01A0  F1        		pop	af
 399    01A1  DD71F8    		ld	(ix-8),c
 400    01A4  DD70F9    		ld	(ix-7),b
 401    01A7  18C5      		jr	L17
 402                    	L101:
 403                    	;  128  
 404                    	;  129          return crc;
 405    01A9  DD4EF8    		ld	c,(ix-8)
 406    01AC  DD46F9    		ld	b,(ix-7)
 407    01AF  C30000    		jp	c.rets
 408                    		.psect	_data
 409                    	L51:
 410    001B  28        		.byte	40
 411    001C  73        		.byte	115
 412    001D  6E        		.byte	110
 413    001E  64        		.byte	100
 414    001F  29        		.byte	41
 415    0020  00        		.byte	0
 416                    	L52:
 417    0021  3E        		.byte	62
 418    0022  25        		.byte	37
 419    0023  30        		.byte	48
 420    0024  32        		.byte	50
 421    0025  78        		.byte	120
 422    0026  3C        		.byte	60
 423    0027  25        		.byte	37
 424    0028  30        		.byte	48
 425    0029  32        		.byte	50
 426    002A  78        		.byte	120
 427    002B  2C        		.byte	44
 428    002C  00        		.byte	0
 429                    	L53:
 430    002D  0A        		.byte	10
 431    002E  00        		.byte	0
 432                    	L54:
 433    002F  0A        		.byte	10
 434    0030  00        		.byte	0
 435                    	L55:
 436    0031  28        		.byte	40
 437    0032  72        		.byte	114
 438    0033  65        		.byte	101
 439    0034  63        		.byte	99
 440    0035  29        		.byte	41
 441    0036  00        		.byte	0
 442                    	L56:
 443    0037  3E        		.byte	62
 444    0038  25        		.byte	37
 445    0039  30        		.byte	48
 446    003A  32        		.byte	50
 447    003B  78        		.byte	120
 448    003C  3C        		.byte	60
 449    003D  25        		.byte	37
 450    003E  30        		.byte	48
 451    003F  32        		.byte	50
 452    0040  78        		.byte	120
 453    0041  2C        		.byte	44
 454    0042  00        		.byte	0
 455                    	L57:
 456    0043  0A        		.byte	10
 457    0044  00        		.byte	0
 458                    	L501:
 459    0045  0A        		.byte	10
 460    0046  00        		.byte	0
 461                    		.psect	_text
 462                    	;  130          }
 463                    	;  131  
 464                    	;  132  
 465                    	;  133  /* send command to SD card and recieve answer
 466                    	;  134   * returns a pointer to the response
 467                    	;  135   */
 468                    	;  136  unsigned char *sdcommand(unsigned char *sndbuf, int sndbytes, unsigned char *recbuf, int recbytes)
 469                    	;  137          {
 470                    	_sdcommand:
 471    01B2  CD0000    		call	c.savs
 472    01B5  21F0FF    		ld	hl,65520
 473    01B8  39        		add	hl,sp
 474    01B9  F9        		ld	sp,hl
 475                    	;  138          int bitsearch;
 476                    	;  139          int debugnl;
 477                    	;  140          unsigned char *retptr;
 478                    	;  141          unsigned int rbyte;
 479                    	;  142          unsigned int sbyte;
 480                    	;  143  
 481                    	;  144          if (debugflg)
 482    01BA  2A3212    		ld	hl,(_debugflg)
 483    01BD  7C        		ld	a,h
 484    01BE  B5        		or	l
 485    01BF  280E      		jr	z,L121
 486                    	;  145                  {
 487                    	;  146                  printf("(snd)");
 488    01C1  211B00    		ld	hl,L51
 489    01C4  CD0000    		call	_printf
 490                    	;  147                  debugnl = 0;
 491    01C7  DD36F600  		ld	(ix-10),0
 492    01CB  DD36F700  		ld	(ix-9),0
 493                    	L121:
 494                    	;  148                  }
 495                    	;  149          for (; 0 < sndbytes; sndbytes--)
 496    01CF  97        		sub	a
 497    01D0  DD9606    		sub	(ix+6)
 498    01D3  3E00      		ld	a,0
 499    01D5  DD9E07    		sbc	a,(ix+7)
 500    01D8  F25A02    		jp	p,L131
 501                    	;  150                  {
 502                    	;  151                  sbyte = *sndbuf++;
 503    01DB  DD6E04    		ld	l,(ix+4)
 504    01DE  DD6605    		ld	h,(ix+5)
 505    01E1  DD3404    		inc	(ix+4)
 506    01E4  2003      		jr	nz,L02
 507    01E6  DD3405    		inc	(ix+5)
 508                    	L02:
 509    01E9  7E        		ld	a,(hl)
 510    01EA  DD77F0    		ld	(ix-16),a
 511    01ED  97        		sub	a
 512    01EE  DD77F1    		ld	(ix-15),a
 513                    	;  152                  rbyte = (spiio(sbyte) & 0xff);
 514    01F1  DD6EF0    		ld	l,(ix-16)
 515    01F4  DD66F1    		ld	h,(ix-15)
 516    01F7  CD0000    		call	_spiio
 517    01FA  79        		ld	a,c
 518    01FB  E6FF      		and	255
 519    01FD  4F        		ld	c,a
 520    01FE  97        		sub	a
 521    01FF  47        		ld	b,a
 522    0200  DD71F2    		ld	(ix-14),c
 523    0203  DD70F3    		ld	(ix-13),b
 524                    	;  153                  if (debugflg)
 525    0206  2A3212    		ld	hl,(_debugflg)
 526    0209  7C        		ld	a,h
 527    020A  B5        		or	l
 528    020B  283D      		jr	z,L141
 529                    	;  154                          {
 530                    	;  155                          printf(">%02x<%02x,", sbyte, rbyte);
 531    020D  DD6EF2    		ld	l,(ix-14)
 532    0210  DD66F3    		ld	h,(ix-13)
 533    0213  E5        		push	hl
 534    0214  DD6EF0    		ld	l,(ix-16)
 535    0217  DD66F1    		ld	h,(ix-15)
 536    021A  E5        		push	hl
 537    021B  212100    		ld	hl,L52
 538    021E  CD0000    		call	_printf
 539    0221  F1        		pop	af
 540    0222  F1        		pop	af
 541                    	;  156                          if (7 < debugnl++)
 542    0223  DD6EF6    		ld	l,(ix-10)
 543    0226  DD66F7    		ld	h,(ix-9)
 544    0229  E5        		push	hl
 545    022A  DD34F6    		inc	(ix-10)
 546    022D  2003      		jr	nz,L22
 547    022F  DD34F7    		inc	(ix-9)
 548                    	L22:
 549    0232  E1        		pop	hl
 550    0233  3E07      		ld	a,7
 551    0235  95        		sub	l
 552    0236  3E00      		ld	a,0
 553    0238  9C        		sbc	a,h
 554    0239  F24A02    		jp	p,L141
 555                    	;  157                                  {
 556                    	;  158                                  printf("\n");
 557    023C  212D00    		ld	hl,L53
 558    023F  CD0000    		call	_printf
 559                    	;  159                                  debugnl = 0;
 560    0242  DD36F600  		ld	(ix-10),0
 561    0246  DD36F700  		ld	(ix-9),0
 562                    	L141:
 563    024A  DD6E06    		ld	l,(ix+6)
 564    024D  DD6607    		ld	h,(ix+7)
 565    0250  2B        		dec	hl
 566    0251  DD7506    		ld	(ix+6),l
 567    0254  DD7407    		ld	(ix+7),h
 568    0257  C3CF01    		jp	L121
 569                    	L131:
 570                    	;  160                                  }
 571                    	;  161                          }
 572                    	;  162                  }
 573                    	;  163          if (debugflg)
 574    025A  2A3212    		ld	hl,(_debugflg)
 575    025D  7C        		ld	a,h
 576    025E  B5        		or	l
 577    025F  2806      		jr	z,L102
 578                    	;  164                  printf("\n");
 579    0261  212F00    		ld	hl,L54
 580    0264  CD0000    		call	_printf
 581                    	L102:
 582                    	;  165  
 583                    	;  166          bitsearch = YES;
 584    0267  DD36F801  		ld	(ix-8),1
 585    026B  DD36F900  		ld	(ix-7),0
 586                    	;  167          retptr = recbuf;
 587    026F  DD7E08    		ld	a,(ix+8)
 588    0272  DD77F4    		ld	(ix-12),a
 589    0275  DD7E09    		ld	a,(ix+9)
 590    0278  DD77F5    		ld	(ix-11),a
 591                    	;  168          if (debugflg)
 592    027B  2A3212    		ld	hl,(_debugflg)
 593    027E  7C        		ld	a,h
 594    027F  B5        		or	l
 595    0280  280E      		jr	z,L122
 596                    	;  169                  {
 597                    	;  170                  printf("(rec)");
 598    0282  213100    		ld	hl,L55
 599    0285  CD0000    		call	_printf
 600                    	;  171                  debugnl = 0;
 601    0288  DD36F600  		ld	(ix-10),0
 602    028C  DD36F700  		ld	(ix-9),0
 603                    	L122:
 604                    	;  172                  }
 605                    	;  173          for (; 0 < recbytes; recbytes--)
 606    0290  97        		sub	a
 607    0291  DD960A    		sub	(ix+10)
 608    0294  3E00      		ld	a,0
 609    0296  DD9E0B    		sbc	a,(ix+11)
 610    0299  F24A03    		jp	p,L132
 611                    	;  174                  {
 612                    	;  175                  sbyte = 0xff;
 613    029C  DD36F0FF  		ld	(ix-16),255
 614    02A0  DD36F100  		ld	(ix-15),0
 615                    	;  176                  rbyte = (spiio(sbyte) & 0xff);
 616    02A4  DD6EF0    		ld	l,(ix-16)
 617    02A7  DD66F1    		ld	h,(ix-15)
 618    02AA  CD0000    		call	_spiio
 619    02AD  79        		ld	a,c
 620    02AE  E6FF      		and	255
 621    02B0  4F        		ld	c,a
 622    02B1  97        		sub	a
 623    02B2  47        		ld	b,a
 624    02B3  DD71F2    		ld	(ix-14),c
 625    02B6  DD70F3    		ld	(ix-13),b
 626                    	;  177                  *recbuf = rbyte;
 627    02B9  DD6E08    		ld	l,(ix+8)
 628    02BC  DD6609    		ld	h,(ix+9)
 629    02BF  DD7EF2    		ld	a,(ix-14)
 630    02C2  77        		ld	(hl),a
 631                    	;  178                  if (bitsearch && ((rbyte & 0x80) == 0))
 632    02C3  DD7EF8    		ld	a,(ix-8)
 633    02C6  DDB6F9    		or	(ix-7)
 634    02C9  2830      		jr	z,L162
 635    02CB  DD6EF2    		ld	l,(ix-14)
 636    02CE  DD66F3    		ld	h,(ix-13)
 637    02D1  CB7D      		bit	7,l
 638    02D3  2026      		jr	nz,L162
 639                    	;  179                          {
 640                    	;  180                          retptr = recbuf;
 641    02D5  DD7E08    		ld	a,(ix+8)
 642    02D8  DD77F4    		ld	(ix-12),a
 643    02DB  DD7E09    		ld	a,(ix+9)
 644    02DE  DD77F5    		ld	(ix-11),a
 645                    	;  181                          bitsearch = NO;
 646    02E1  DD36F800  		ld	(ix-8),0
 647    02E5  DD36F900  		ld	(ix-7),0
 648    02E9  1810      		jr	L162
 649                    	L142:
 650    02EB  DD6E0A    		ld	l,(ix+10)
 651    02EE  DD660B    		ld	h,(ix+11)
 652    02F1  2B        		dec	hl
 653    02F2  DD750A    		ld	(ix+10),l
 654    02F5  DD740B    		ld	(ix+11),h
 655    02F8  C39002    		jp	L122
 656                    	L162:
 657                    	;  182                          }
 658                    	;  183                  recbuf++;
 659    02FB  DD3408    		inc	(ix+8)
 660    02FE  2003      		jr	nz,L42
 661    0300  DD3409    		inc	(ix+9)
 662                    	L42:
 663                    	;  184                  if (debugflg)
 664    0303  2A3212    		ld	hl,(_debugflg)
 665    0306  7C        		ld	a,h
 666    0307  B5        		or	l
 667    0308  28E1      		jr	z,L142
 668                    	;  185                          {
 669                    	;  186                          printf(">%02x<%02x,", sbyte, rbyte);
 670    030A  DD6EF2    		ld	l,(ix-14)
 671    030D  DD66F3    		ld	h,(ix-13)
 672    0310  E5        		push	hl
 673    0311  DD6EF0    		ld	l,(ix-16)
 674    0314  DD66F1    		ld	h,(ix-15)
 675    0317  E5        		push	hl
 676    0318  213700    		ld	hl,L56
 677    031B  CD0000    		call	_printf
 678    031E  F1        		pop	af
 679    031F  F1        		pop	af
 680                    	;  187                          if (7 < debugnl++)
 681    0320  DD6EF6    		ld	l,(ix-10)
 682    0323  DD66F7    		ld	h,(ix-9)
 683    0326  E5        		push	hl
 684    0327  DD34F6    		inc	(ix-10)
 685    032A  2003      		jr	nz,L62
 686    032C  DD34F7    		inc	(ix-9)
 687                    	L62:
 688    032F  E1        		pop	hl
 689    0330  3E07      		ld	a,7
 690    0332  95        		sub	l
 691    0333  3E00      		ld	a,0
 692    0335  9C        		sbc	a,h
 693    0336  F2EB02    		jp	p,L142
 694                    	;  188                                  {
 695                    	;  189                                  printf("\n");
 696    0339  214300    		ld	hl,L57
 697    033C  CD0000    		call	_printf
 698                    	;  190                                  debugnl = 0;
 699    033F  DD36F600  		ld	(ix-10),0
 700    0343  DD36F700  		ld	(ix-9),0
 701    0347  C3EB02    		jp	L142
 702                    	L132:
 703                    	;  191                                  }
 704                    	;  192                          }
 705                    	;  193                  }
 706                    	;  194          if (debugflg)
 707    034A  2A3212    		ld	hl,(_debugflg)
 708    034D  7C        		ld	a,h
 709    034E  B5        		or	l
 710    034F  2806      		jr	z,L113
 711                    	;  195                  printf("\n");
 712    0351  214500    		ld	hl,L501
 713    0354  CD0000    		call	_printf
 714                    	L113:
 715                    	;  196          return (retptr);
 716    0357  DD4EF4    		ld	c,(ix-12)
 717    035A  DD46F5    		ld	b,(ix-11)
 718    035D  C30000    		jp	c.rets
 719                    	;  197          }
 720                    	;  198  
 721                    	;  199  /* The SD card commands with two "idle" bytes in the beginning
 722                    	;  200   * and (at least for CMD0) a CRC7 byte as the last one.
 723                    	;  201   */
 724                    	;  202  unsigned char cmd0[] = {0xff, 0xff, 0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
 725                    		.psect	_data
 726                    	_cmd0:
 727    0047  FF        		.byte	255
 728    0048  FF        		.byte	255
 729    0049  40        		.byte	64
 730                    		.byte	[1]
 731                    		.byte	[1]
 732                    		.byte	[1]
 733                    		.byte	[1]
 734    004E  95        		.byte	149
 735                    	;  203  unsigned char cmd8[] = {0xff, 0xff, 0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
 736                    	_cmd8:
 737    004F  FF        		.byte	255
 738    0050  FF        		.byte	255
 739    0051  48        		.byte	72
 740                    		.byte	[1]
 741                    		.byte	[1]
 742    0054  01        		.byte	1
 743    0055  AA        		.byte	170
 744    0056  87        		.byte	135
 745                    	;  204  unsigned char cmd9[] = {0xff, 0xff, 0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
 746                    	_cmd9:
 747    0057  FF        		.byte	255
 748    0058  FF        		.byte	255
 749    0059  49        		.byte	73
 750                    		.byte	[1]
 751                    		.byte	[1]
 752                    		.byte	[1]
 753                    		.byte	[1]
 754    005E  AF        		.byte	175
 755                    	;  205  unsigned char cmd10[] = {0xff, 0xff, 0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
 756                    	_cmd10:
 757    005F  FF        		.byte	255
 758    0060  FF        		.byte	255
 759    0061  4A        		.byte	74
 760                    		.byte	[1]
 761                    		.byte	[1]
 762                    		.byte	[1]
 763                    		.byte	[1]
 764    0066  1B        		.byte	27
 765                    	;  206  unsigned char cmd16[] = {0xff, 0xff, 0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
 766                    	_cmd16:
 767    0067  FF        		.byte	255
 768    0068  FF        		.byte	255
 769    0069  50        		.byte	80
 770                    		.byte	[1]
 771                    		.byte	[1]
 772    006C  02        		.byte	2
 773                    		.byte	[1]
 774    006E  15        		.byte	21
 775                    	;  207  unsigned char cmd55[] = {0xff, 0xff, 0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
 776                    	_cmd55:
 777    006F  FF        		.byte	255
 778    0070  FF        		.byte	255
 779    0071  77        		.byte	119
 780                    		.byte	[1]
 781                    		.byte	[1]
 782                    		.byte	[1]
 783                    		.byte	[1]
 784    0076  65        		.byte	101
 785                    	;  208  unsigned char cmd58[] = {0xff, 0xff, 0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
 786                    	_cmd58:
 787    0077  FF        		.byte	255
 788    0078  FF        		.byte	255
 789    0079  7A        		.byte	122
 790                    		.byte	[1]
 791                    		.byte	[1]
 792                    		.byte	[1]
 793                    		.byte	[1]
 794    007E  FD        		.byte	253
 795                    	;  209  unsigned char acmd41[] = {0xff, 0xff, 0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
 796                    	_acmd41:
 797    007F  FF        		.byte	255
 798    0080  FF        		.byte	255
 799    0081  69        		.byte	105
 800    0082  40        		.byte	64
 801                    		.byte	[1]
 802    0084  01        		.byte	1
 803    0085  AA        		.byte	170
 804    0086  33        		.byte	51
 805                    	L511:
 806    0087  53        		.byte	83
 807    0088  65        		.byte	101
 808    0089  6E        		.byte	110
 809    008A  74        		.byte	116
 810    008B  20        		.byte	32
 811    008C  38        		.byte	56
 812    008D  20        		.byte	32
 813    008E  62        		.byte	98
 814    008F  79        		.byte	121
 815    0090  74        		.byte	116
 816    0091  65        		.byte	101
 817    0092  73        		.byte	115
 818    0093  20        		.byte	32
 819    0094  77        		.byte	119
 820    0095  69        		.byte	105
 821    0096  74        		.byte	116
 822    0097  68        		.byte	104
 823    0098  20        		.byte	32
 824    0099  63        		.byte	99
 825    009A  6C        		.byte	108
 826    009B  6F        		.byte	111
 827    009C  63        		.byte	99
 828    009D  6B        		.byte	107
 829    009E  20        		.byte	32
 830    009F  70        		.byte	112
 831    00A0  75        		.byte	117
 832    00A1  6C        		.byte	108
 833    00A2  73        		.byte	115
 834    00A3  65        		.byte	101
 835    00A4  73        		.byte	115
 836    00A5  2C        		.byte	44
 837    00A6  20        		.byte	32
 838    00A7  73        		.byte	115
 839    00A8  65        		.byte	101
 840    00A9  6C        		.byte	108
 841    00AA  65        		.byte	101
 842    00AB  63        		.byte	99
 843    00AC  74        		.byte	116
 844    00AD  20        		.byte	32
 845    00AE  6E        		.byte	110
 846    00AF  6F        		.byte	111
 847    00B0  74        		.byte	116
 848    00B1  20        		.byte	32
 849    00B2  61        		.byte	97
 850    00B3  63        		.byte	99
 851    00B4  74        		.byte	116
 852    00B5  69        		.byte	105
 853    00B6  76        		.byte	118
 854    00B7  65        		.byte	101
 855    00B8  0A        		.byte	10
 856    00B9  00        		.byte	0
 857                    	L521:
 858    00BA  43        		.byte	67
 859    00BB  4D        		.byte	77
 860    00BC  44        		.byte	68
 861    00BD  30        		.byte	48
 862    00BE  3A        		.byte	58
 863    00BF  20        		.byte	32
 864    00C0  47        		.byte	71
 865    00C1  4F        		.byte	79
 866    00C2  5F        		.byte	95
 867    00C3  49        		.byte	73
 868    00C4  44        		.byte	68
 869    00C5  4C        		.byte	76
 870    00C6  45        		.byte	69
 871    00C7  5F        		.byte	95
 872    00C8  53        		.byte	83
 873    00C9  54        		.byte	84
 874    00CA  41        		.byte	65
 875    00CB  54        		.byte	84
 876    00CC  45        		.byte	69
 877    00CD  2C        		.byte	44
 878    00CE  20        		.byte	32
 879    00CF  52        		.byte	82
 880    00D0  31        		.byte	49
 881    00D1  20        		.byte	32
 882    00D2  72        		.byte	114
 883    00D3  65        		.byte	101
 884    00D4  73        		.byte	115
 885    00D5  70        		.byte	112
 886    00D6  6F        		.byte	111
 887    00D7  6E        		.byte	110
 888    00D8  73        		.byte	115
 889    00D9  65        		.byte	101
 890    00DA  20        		.byte	32
 891    00DB  5B        		.byte	91
 892    00DC  25        		.byte	37
 893    00DD  30        		.byte	48
 894    00DE  32        		.byte	50
 895    00DF  78        		.byte	120
 896    00E0  5D        		.byte	93
 897    00E1  0A        		.byte	10
 898    00E2  00        		.byte	0
 899                    	L531:
 900    00E3  43        		.byte	67
 901    00E4  4D        		.byte	77
 902    00E5  44        		.byte	68
 903    00E6  38        		.byte	56
 904    00E7  3A        		.byte	58
 905    00E8  20        		.byte	32
 906    00E9  53        		.byte	83
 907    00EA  45        		.byte	69
 908    00EB  4E        		.byte	78
 909    00EC  44        		.byte	68
 910    00ED  5F        		.byte	95
 911    00EE  49        		.byte	73
 912    00EF  46        		.byte	70
 913    00F0  5F        		.byte	95
 914    00F1  43        		.byte	67
 915    00F2  4F        		.byte	79
 916    00F3  4E        		.byte	78
 917    00F4  44        		.byte	68
 918    00F5  2C        		.byte	44
 919    00F6  20        		.byte	32
 920    00F7  52        		.byte	82
 921    00F8  37        		.byte	55
 922    00F9  20        		.byte	32
 923    00FA  72        		.byte	114
 924    00FB  65        		.byte	101
 925    00FC  73        		.byte	115
 926    00FD  70        		.byte	112
 927    00FE  6F        		.byte	111
 928    00FF  6E        		.byte	110
 929    0100  73        		.byte	115
 930    0101  65        		.byte	101
 931    0102  20        		.byte	32
 932    0103  5B        		.byte	91
 933    0104  25        		.byte	37
 934    0105  30        		.byte	48
 935    0106  32        		.byte	50
 936    0107  78        		.byte	120
 937    0108  20        		.byte	32
 938    0109  25        		.byte	37
 939    010A  30        		.byte	48
 940    010B  32        		.byte	50
 941    010C  78        		.byte	120
 942    010D  20        		.byte	32
 943    010E  25        		.byte	37
 944    010F  30        		.byte	48
 945    0110  32        		.byte	50
 946    0111  78        		.byte	120
 947    0112  20        		.byte	32
 948    0113  25        		.byte	37
 949    0114  30        		.byte	48
 950    0115  32        		.byte	50
 951    0116  78        		.byte	120
 952    0117  20        		.byte	32
 953    0118  25        		.byte	37
 954    0119  30        		.byte	48
 955    011A  32        		.byte	50
 956    011B  78        		.byte	120
 957    011C  5D        		.byte	93
 958    011D  0A        		.byte	10
 959    011E  00        		.byte	0
 960                    	L541:
 961    011F  20        		.byte	32
 962    0120  20        		.byte	32
 963    0121  56        		.byte	86
 964    0122  6F        		.byte	111
 965    0123  6C        		.byte	108
 966    0124  74        		.byte	116
 967    0125  61        		.byte	97
 968    0126  67        		.byte	103
 969    0127  65        		.byte	101
 970    0128  20        		.byte	32
 971    0129  61        		.byte	97
 972    012A  63        		.byte	99
 973    012B  63        		.byte	99
 974    012C  65        		.byte	101
 975    012D  70        		.byte	112
 976    012E  74        		.byte	116
 977    012F  65        		.byte	101
 978    0130  64        		.byte	100
 979    0131  3A        		.byte	58
 980    0132  20        		.byte	32
 981    0133  32        		.byte	50
 982    0134  2E        		.byte	46
 983    0135  37        		.byte	55
 984    0136  2D        		.byte	45
 985    0137  33        		.byte	51
 986    0138  2E        		.byte	46
 987    0139  36        		.byte	54
 988    013A  56        		.byte	86
 989    013B  2C        		.byte	44
 990    013C  20        		.byte	32
 991    013D  00        		.byte	0
 992                    	L551:
 993    013E  65        		.byte	101
 994    013F  63        		.byte	99
 995    0140  68        		.byte	104
 996    0141  6F        		.byte	111
 997    0142  20        		.byte	32
 998    0143  62        		.byte	98
 999    0144  61        		.byte	97
1000    0145  63        		.byte	99
1001    0146  6B        		.byte	107
1002    0147  20        		.byte	32
1003    0148  6F        		.byte	111
1004    0149  6B        		.byte	107
1005    014A  0A        		.byte	10
1006    014B  00        		.byte	0
1007                    	L561:
1008    014C  69        		.byte	105
1009    014D  6E        		.byte	110
1010    014E  76        		.byte	118
1011    014F  61        		.byte	97
1012    0150  6C        		.byte	108
1013    0151  69        		.byte	105
1014    0152  64        		.byte	100
1015    0153  20        		.byte	32
1016    0154  65        		.byte	101
1017    0155  63        		.byte	99
1018    0156  68        		.byte	104
1019    0157  6F        		.byte	111
1020    0158  20        		.byte	32
1021    0159  62        		.byte	98
1022    015A  61        		.byte	97
1023    015B  63        		.byte	99
1024    015C  6B        		.byte	107
1025    015D  0A        		.byte	10
1026    015E  00        		.byte	0
1027                    	L571:
1028    015F  43        		.byte	67
1029    0160  4D        		.byte	77
1030    0161  44        		.byte	68
1031    0162  35        		.byte	53
1032    0163  35        		.byte	53
1033    0164  3A        		.byte	58
1034    0165  20        		.byte	32
1035    0166  41        		.byte	65
1036    0167  50        		.byte	80
1037    0168  50        		.byte	80
1038    0169  5F        		.byte	95
1039    016A  43        		.byte	67
1040    016B  4D        		.byte	77
1041    016C  44        		.byte	68
1042    016D  2C        		.byte	44
1043    016E  20        		.byte	32
1044    016F  52        		.byte	82
1045    0170  31        		.byte	49
1046    0171  20        		.byte	32
1047    0172  72        		.byte	114
1048    0173  65        		.byte	101
1049    0174  73        		.byte	115
1050    0175  70        		.byte	112
1051    0176  6F        		.byte	111
1052    0177  6E        		.byte	110
1053    0178  73        		.byte	115
1054    0179  65        		.byte	101
1055    017A  20        		.byte	32
1056    017B  5B        		.byte	91
1057    017C  25        		.byte	37
1058    017D  30        		.byte	48
1059    017E  32        		.byte	50
1060    017F  78        		.byte	120
1061    0180  5D        		.byte	93
1062    0181  0A        		.byte	10
1063    0182  00        		.byte	0
1064                    	L502:
1065    0183  41        		.byte	65
1066    0184  43        		.byte	67
1067    0185  4D        		.byte	77
1068    0186  44        		.byte	68
1069    0187  34        		.byte	52
1070    0188  31        		.byte	49
1071    0189  3A        		.byte	58
1072    018A  20        		.byte	32
1073    018B  53        		.byte	83
1074    018C  45        		.byte	69
1075    018D  4E        		.byte	78
1076    018E  44        		.byte	68
1077    018F  5F        		.byte	95
1078    0190  4F        		.byte	79
1079    0191  50        		.byte	80
1080    0192  5F        		.byte	95
1081    0193  43        		.byte	67
1082    0194  4F        		.byte	79
1083    0195  4E        		.byte	78
1084    0196  44        		.byte	68
1085    0197  2C        		.byte	44
1086    0198  20        		.byte	32
1087    0199  52        		.byte	82
1088    019A  31        		.byte	49
1089    019B  20        		.byte	32
1090    019C  72        		.byte	114
1091    019D  65        		.byte	101
1092    019E  73        		.byte	115
1093    019F  70        		.byte	112
1094    01A0  6F        		.byte	111
1095    01A1  6E        		.byte	110
1096    01A2  73        		.byte	115
1097    01A3  65        		.byte	101
1098    01A4  20        		.byte	32
1099    01A5  5B        		.byte	91
1100    01A6  25        		.byte	37
1101    01A7  30        		.byte	48
1102    01A8  32        		.byte	50
1103    01A9  78        		.byte	120
1104    01AA  5D        		.byte	93
1105    01AB  0A        		.byte	10
1106    01AC  00        		.byte	0
1107                    	L512:
1108    01AD  43        		.byte	67
1109    01AE  4D        		.byte	77
1110    01AF  44        		.byte	68
1111    01B0  35        		.byte	53
1112    01B1  38        		.byte	56
1113    01B2  3A        		.byte	58
1114    01B3  20        		.byte	32
1115    01B4  52        		.byte	82
1116    01B5  45        		.byte	69
1117    01B6  41        		.byte	65
1118    01B7  44        		.byte	68
1119    01B8  5F        		.byte	95
1120    01B9  4F        		.byte	79
1121    01BA  43        		.byte	67
1122    01BB  52        		.byte	82
1123    01BC  2C        		.byte	44
1124    01BD  20        		.byte	32
1125    01BE  52        		.byte	82
1126    01BF  33        		.byte	51
1127    01C0  20        		.byte	32
1128    01C1  72        		.byte	114
1129    01C2  65        		.byte	101
1130    01C3  73        		.byte	115
1131    01C4  70        		.byte	112
1132    01C5  6F        		.byte	111
1133    01C6  6E        		.byte	110
1134    01C7  73        		.byte	115
1135    01C8  65        		.byte	101
1136    01C9  20        		.byte	32
1137    01CA  5B        		.byte	91
1138    01CB  25        		.byte	37
1139    01CC  30        		.byte	48
1140    01CD  32        		.byte	50
1141    01CE  78        		.byte	120
1142    01CF  20        		.byte	32
1143    01D0  25        		.byte	37
1144    01D1  30        		.byte	48
1145    01D2  32        		.byte	50
1146    01D3  78        		.byte	120
1147    01D4  20        		.byte	32
1148    01D5  25        		.byte	37
1149    01D6  30        		.byte	48
1150    01D7  32        		.byte	50
1151    01D8  78        		.byte	120
1152    01D9  20        		.byte	32
1153    01DA  25        		.byte	37
1154    01DB  30        		.byte	48
1155    01DC  32        		.byte	50
1156    01DD  78        		.byte	120
1157    01DE  20        		.byte	32
1158    01DF  25        		.byte	37
1159    01E0  30        		.byte	48
1160    01E1  32        		.byte	50
1161    01E2  78        		.byte	120
1162    01E3  5D        		.byte	93
1163    01E4  0A        		.byte	10
1164    01E5  00        		.byte	0
1165                    	L522:
1166    01E6  43        		.byte	67
1167    01E7  4D        		.byte	77
1168    01E8  44        		.byte	68
1169    01E9  31        		.byte	49
1170    01EA  36        		.byte	54
1171    01EB  3A        		.byte	58
1172    01EC  20        		.byte	32
1173    01ED  53        		.byte	83
1174    01EE  45        		.byte	69
1175    01EF  54        		.byte	84
1176    01F0  5F        		.byte	95
1177    01F1  42        		.byte	66
1178    01F2  4C        		.byte	76
1179    01F3  4F        		.byte	79
1180    01F4  43        		.byte	67
1181    01F5  4B        		.byte	75
1182    01F6  4C        		.byte	76
1183    01F7  45        		.byte	69
1184    01F8  4E        		.byte	78
1185    01F9  20        		.byte	32
1186    01FA  28        		.byte	40
1187    01FB  74        		.byte	116
1188    01FC  6F        		.byte	111
1189    01FD  20        		.byte	32
1190    01FE  35        		.byte	53
1191    01FF  31        		.byte	49
1192    0200  32        		.byte	50
1193    0201  20        		.byte	32
1194    0202  62        		.byte	98
1195    0203  79        		.byte	121
1196    0204  74        		.byte	116
1197    0205  65        		.byte	101
1198    0206  73        		.byte	115
1199    0207  29        		.byte	41
1200    0208  2C        		.byte	44
1201    0209  20        		.byte	32
1202    020A  52        		.byte	82
1203    020B  31        		.byte	49
1204    020C  20        		.byte	32
1205    020D  72        		.byte	114
1206    020E  65        		.byte	101
1207    020F  73        		.byte	115
1208    0210  70        		.byte	112
1209    0211  6F        		.byte	111
1210    0212  6E        		.byte	110
1211    0213  73        		.byte	115
1212    0214  65        		.byte	101
1213    0215  20        		.byte	32
1214    0216  5B        		.byte	91
1215    0217  25        		.byte	37
1216    0218  30        		.byte	48
1217    0219  32        		.byte	50
1218    021A  78        		.byte	120
1219    021B  5D        		.byte	93
1220    021C  0A        		.byte	10
1221    021D  00        		.byte	0
1222                    	L532:
1223    021E  43        		.byte	67
1224    021F  4D        		.byte	77
1225    0220  44        		.byte	68
1226    0221  31        		.byte	49
1227    0222  30        		.byte	48
1228    0223  3A        		.byte	58
1229    0224  20        		.byte	32
1230    0225  53        		.byte	83
1231    0226  45        		.byte	69
1232    0227  4E        		.byte	78
1233    0228  44        		.byte	68
1234    0229  5F        		.byte	95
1235    022A  43        		.byte	67
1236    022B  49        		.byte	73
1237    022C  44        		.byte	68
1238    022D  2C        		.byte	44
1239    022E  20        		.byte	32
1240    022F  52        		.byte	82
1241    0230  31        		.byte	49
1242    0231  20        		.byte	32
1243    0232  72        		.byte	114
1244    0233  65        		.byte	101
1245    0234  73        		.byte	115
1246    0235  70        		.byte	112
1247    0236  6F        		.byte	111
1248    0237  6E        		.byte	110
1249    0238  73        		.byte	115
1250    0239  65        		.byte	101
1251    023A  20        		.byte	32
1252    023B  5B        		.byte	91
1253    023C  25        		.byte	37
1254    023D  30        		.byte	48
1255    023E  32        		.byte	50
1256    023F  78        		.byte	120
1257    0240  5D        		.byte	93
1258    0241  0A        		.byte	10
1259    0242  00        		.byte	0
1260                    	L542:
1261    0243  20        		.byte	32
1262    0244  20        		.byte	32
1263    0245  4E        		.byte	78
1264    0246  6F        		.byte	111
1265    0247  20        		.byte	32
1266    0248  64        		.byte	100
1267    0249  61        		.byte	97
1268    024A  74        		.byte	116
1269    024B  61        		.byte	97
1270    024C  20        		.byte	32
1271    024D  66        		.byte	102
1272    024E  6F        		.byte	111
1273    024F  75        		.byte	117
1274    0250  6E        		.byte	110
1275    0251  64        		.byte	100
1276    0252  0A        		.byte	10
1277    0253  00        		.byte	0
1278                    	L552:
1279    0254  20        		.byte	32
1280    0255  20        		.byte	32
1281    0256  43        		.byte	67
1282    0257  49        		.byte	73
1283    0258  44        		.byte	68
1284    0259  3A        		.byte	58
1285    025A  20        		.byte	32
1286    025B  5B        		.byte	91
1287    025C  00        		.byte	0
1288                    	L562:
1289    025D  25        		.byte	37
1290    025E  30        		.byte	48
1291    025F  32        		.byte	50
1292    0260  78        		.byte	120
1293    0261  20        		.byte	32
1294    0262  00        		.byte	0
1295                    	L572:
1296    0263  08        		.byte	8
1297    0264  5D        		.byte	93
1298    0265  20        		.byte	32
1299    0266  7C        		.byte	124
1300    0267  00        		.byte	0
1301                    	L503:
1302    0268  7C        		.byte	124
1303    0269  0A        		.byte	10
1304    026A  00        		.byte	0
1305                    	L513:
1306    026B  43        		.byte	67
1307    026C  4D        		.byte	77
1308    026D  44        		.byte	68
1309    026E  39        		.byte	57
1310    026F  3A        		.byte	58
1311    0270  20        		.byte	32
1312    0271  53        		.byte	83
1313    0272  45        		.byte	69
1314    0273  4E        		.byte	78
1315    0274  44        		.byte	68
1316    0275  5F        		.byte	95
1317    0276  43        		.byte	67
1318    0277  53        		.byte	83
1319    0278  44        		.byte	68
1320    0279  2C        		.byte	44
1321    027A  20        		.byte	32
1322    027B  52        		.byte	82
1323    027C  31        		.byte	49
1324    027D  20        		.byte	32
1325    027E  72        		.byte	114
1326    027F  65        		.byte	101
1327    0280  73        		.byte	115
1328    0281  70        		.byte	112
1329    0282  6F        		.byte	111
1330    0283  6E        		.byte	110
1331    0284  73        		.byte	115
1332    0285  65        		.byte	101
1333    0286  20        		.byte	32
1334    0287  5B        		.byte	91
1335    0288  25        		.byte	37
1336    0289  30        		.byte	48
1337    028A  32        		.byte	50
1338    028B  78        		.byte	120
1339    028C  5D        		.byte	93
1340    028D  0A        		.byte	10
1341    028E  00        		.byte	0
1342                    	L523:
1343    028F  20        		.byte	32
1344    0290  20        		.byte	32
1345    0291  4E        		.byte	78
1346    0292  6F        		.byte	111
1347    0293  20        		.byte	32
1348    0294  64        		.byte	100
1349    0295  61        		.byte	97
1350    0296  74        		.byte	116
1351    0297  61        		.byte	97
1352    0298  20        		.byte	32
1353    0299  66        		.byte	102
1354    029A  6F        		.byte	111
1355    029B  75        		.byte	117
1356    029C  6E        		.byte	110
1357    029D  64        		.byte	100
1358    029E  0A        		.byte	10
1359    029F  00        		.byte	0
1360                    	L533:
1361    02A0  20        		.byte	32
1362    02A1  20        		.byte	32
1363    02A2  43        		.byte	67
1364    02A3  53        		.byte	83
1365    02A4  44        		.byte	68
1366    02A5  3A        		.byte	58
1367    02A6  20        		.byte	32
1368    02A7  5B        		.byte	91
1369    02A8  00        		.byte	0
1370                    	L543:
1371    02A9  25        		.byte	37
1372    02AA  30        		.byte	48
1373    02AB  32        		.byte	50
1374    02AC  78        		.byte	120
1375    02AD  20        		.byte	32
1376    02AE  00        		.byte	0
1377                    	L553:
1378    02AF  08        		.byte	8
1379    02B0  5D        		.byte	93
1380    02B1  20        		.byte	32
1381    02B2  7C        		.byte	124
1382    02B3  00        		.byte	0
1383                    	L563:
1384    02B4  7C        		.byte	124
1385    02B5  0A        		.byte	10
1386    02B6  00        		.byte	0
1387                    	L573:
1388    02B7  53        		.byte	83
1389    02B8  65        		.byte	101
1390    02B9  6E        		.byte	110
1391    02BA  74        		.byte	116
1392    02BB  20        		.byte	32
1393    02BC  31        		.byte	49
1394    02BD  36        		.byte	54
1395    02BE  20        		.byte	32
1396    02BF  62        		.byte	98
1397    02C0  79        		.byte	121
1398    02C1  74        		.byte	116
1399    02C2  65        		.byte	101
1400    02C3  73        		.byte	115
1401    02C4  20        		.byte	32
1402    02C5  6F        		.byte	111
1403    02C6  66        		.byte	102
1404    02C7  20        		.byte	32
1405    02C8  63        		.byte	99
1406    02C9  6C        		.byte	108
1407    02CA  6F        		.byte	111
1408    02CB  63        		.byte	99
1409    02CC  6B        		.byte	107
1410    02CD  20        		.byte	32
1411    02CE  70        		.byte	112
1412    02CF  75        		.byte	117
1413    02D0  6C        		.byte	108
1414    02D1  73        		.byte	115
1415    02D2  65        		.byte	101
1416    02D3  73        		.byte	115
1417    02D4  2C        		.byte	44
1418    02D5  20        		.byte	32
1419    02D6  73        		.byte	115
1420    02D7  65        		.byte	101
1421    02D8  6C        		.byte	108
1422    02D9  65        		.byte	101
1423    02DA  63        		.byte	99
1424    02DB  74        		.byte	116
1425    02DC  20        		.byte	32
1426    02DD  61        		.byte	97
1427    02DE  63        		.byte	99
1428    02DF  74        		.byte	116
1429    02E0  69        		.byte	105
1430    02E1  76        		.byte	118
1431    02E2  65        		.byte	101
1432    02E3  0A        		.byte	10
1433    02E4  00        		.byte	0
1434                    		.psect	_text
1435                    	;  210  
1436                    	;  211  /* initialise SD card interface */
1437                    	;  212  void sdinit()
1438                    	;  213          {
1439                    	_sdinit:
1440    0360  CD0000    		call	c.savs0
1441    0363  21F0FF    		ld	hl,65520
1442    0366  39        		add	hl,sp
1443    0367  F9        		ld	sp,hl
1444                    	;  214          unsigned char *prtptr;
1445                    	;  215          unsigned char *statptr;
1446                    	;  216          int rxbytes;
1447                    	;  217          int tries;
1448                    	;  218          int wtloop;
1449                    	;  219  
1450                    	;  220          ledon();
1451    0368  CD0000    		call	_ledon
1452                    	;  221  
1453                    	;  222          /* start to generate 8 clock pulses with not selected SD card */
1454                    	;  223          spideselect();
1455    036B  CD0000    		call	_spideselect
1456                    	;  224  
1457                    	;  225          statptr = sdcommand(0, 0, rxbuf, 8);
1458    036E  210800    		ld	hl,8
1459    0371  E5        		push	hl
1460    0372  21E80F    		ld	hl,_rxbuf
1461    0375  E5        		push	hl
1462    0376  210000    		ld	hl,0
1463    0379  E5        		push	hl
1464    037A  210000    		ld	hl,0
1465    037D  CDB201    		call	_sdcommand
1466    0380  F1        		pop	af
1467    0381  F1        		pop	af
1468    0382  F1        		pop	af
1469    0383  DD71F6    		ld	(ix-10),c
1470    0386  DD70F7    		ld	(ix-9),b
1471                    	;  226          printf("Sent 8 bytes with clock pulses, select not active\n");
1472    0389  218700    		ld	hl,L511
1473    038C  CD0000    		call	_printf
1474                    	;  227  
1475                    	;  228          spiselect();
1476    038F  CD0000    		call	_spiselect
1477                    	;  229  
1478                    	;  230          /* CMD0: GO_IDLE_STATE */
1479                    	;  231          cmd0[7] = CRC7_buf(&cmd0[2], 5) | 0x01;
1480    0392  210500    		ld	hl,5
1481    0395  E5        		push	hl
1482    0396  214900    		ld	hl,_cmd0+2
1483    0399  CD6200    		call	_CRC7_buf
1484    039C  F1        		pop	af
1485    039D  CBC1      		set	0,c
1486    039F  79        		ld	a,c
1487    03A0  324E00    		ld	(_cmd0+7),a
1488                    	;  232          statptr = sdcommand(cmd0, sizeof cmd0, rxbuf, 8);
1489    03A3  210800    		ld	hl,8
1490    03A6  E5        		push	hl
1491    03A7  21E80F    		ld	hl,_rxbuf
1492    03AA  E5        		push	hl
1493    03AB  210800    		ld	hl,8
1494    03AE  E5        		push	hl
1495    03AF  214700    		ld	hl,_cmd0
1496    03B2  CDB201    		call	_sdcommand
1497    03B5  F1        		pop	af
1498    03B6  F1        		pop	af
1499    03B7  F1        		pop	af
1500    03B8  DD71F6    		ld	(ix-10),c
1501    03BB  DD70F7    		ld	(ix-9),b
1502                    	;  233          printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
1503    03BE  DD6EF6    		ld	l,(ix-10)
1504    03C1  DD66F7    		ld	h,(ix-9)
1505    03C4  4E        		ld	c,(hl)
1506    03C5  97        		sub	a
1507    03C6  47        		ld	b,a
1508    03C7  C5        		push	bc
1509    03C8  21BA00    		ld	hl,L521
1510    03CB  CD0000    		call	_printf
1511    03CE  F1        		pop	af
1512                    	;  234  
1513                    	;  235          /* CMD8: SEND_IF_COND */
1514                    	;  236          cmd8[7] = CRC7_buf(&cmd8[2], 5) | 0x01;
1515    03CF  210500    		ld	hl,5
1516    03D2  E5        		push	hl
1517    03D3  215100    		ld	hl,_cmd8+2
1518    03D6  CD6200    		call	_CRC7_buf
1519    03D9  F1        		pop	af
1520    03DA  CBC1      		set	0,c
1521    03DC  79        		ld	a,c
1522    03DD  325600    		ld	(_cmd8+7),a
1523                    	;  237          statptr = sdcommand(cmd8, sizeof cmd8, rxbuf, 8);
1524    03E0  210800    		ld	hl,8
1525    03E3  E5        		push	hl
1526    03E4  21E80F    		ld	hl,_rxbuf
1527    03E7  E5        		push	hl
1528    03E8  210800    		ld	hl,8
1529    03EB  E5        		push	hl
1530    03EC  214F00    		ld	hl,_cmd8
1531    03EF  CDB201    		call	_sdcommand
1532    03F2  F1        		pop	af
1533    03F3  F1        		pop	af
1534    03F4  F1        		pop	af
1535    03F5  DD71F6    		ld	(ix-10),c
1536    03F8  DD70F7    		ld	(ix-9),b
1537                    	;  238          printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x]\n",
1538                    	;  239                   statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
1539    03FB  DD6EF6    		ld	l,(ix-10)
1540    03FE  DD66F7    		ld	h,(ix-9)
1541    0401  23        		inc	hl
1542    0402  23        		inc	hl
1543    0403  23        		inc	hl
1544    0404  23        		inc	hl
1545    0405  4E        		ld	c,(hl)
1546    0406  97        		sub	a
1547    0407  47        		ld	b,a
1548    0408  C5        		push	bc
1549    0409  DD6EF6    		ld	l,(ix-10)
1550    040C  DD66F7    		ld	h,(ix-9)
1551    040F  23        		inc	hl
1552    0410  23        		inc	hl
1553    0411  23        		inc	hl
1554    0412  4E        		ld	c,(hl)
1555    0413  97        		sub	a
1556    0414  47        		ld	b,a
1557    0415  C5        		push	bc
1558    0416  DD6EF6    		ld	l,(ix-10)
1559    0419  DD66F7    		ld	h,(ix-9)
1560    041C  23        		inc	hl
1561    041D  23        		inc	hl
1562    041E  4E        		ld	c,(hl)
1563    041F  97        		sub	a
1564    0420  47        		ld	b,a
1565    0421  C5        		push	bc
1566    0422  DD6EF6    		ld	l,(ix-10)
1567    0425  DD66F7    		ld	h,(ix-9)
1568    0428  23        		inc	hl
1569    0429  4E        		ld	c,(hl)
1570    042A  97        		sub	a
1571    042B  47        		ld	b,a
1572    042C  C5        		push	bc
1573    042D  DD6EF6    		ld	l,(ix-10)
1574    0430  DD66F7    		ld	h,(ix-9)
1575    0433  4E        		ld	c,(hl)
1576    0434  97        		sub	a
1577    0435  47        		ld	b,a
1578    0436  C5        		push	bc
1579    0437  21E300    		ld	hl,L531
1580    043A  CD0000    		call	_printf
1581    043D  210A00    		ld	hl,10
1582    0440  39        		add	hl,sp
1583    0441  F9        		ld	sp,hl
1584                    	;  240          if (statptr[0] & 0xfe) /* if error */
1585    0442  DD6EF6    		ld	l,(ix-10)
1586    0445  DD66F7    		ld	h,(ix-9)
1587    0448  6E        		ld	l,(hl)
1588    0449  97        		sub	a
1589    044A  67        		ld	h,a
1590    044B  CB85      		res	0,l
1591    044D  7D        		ld	a,l
1592    044E  B4        		or	h
1593    044F  2814      		jr	z,L123
1594                    	;  241                  {
1595                    	;  242                  acmd41[3] = 0x00; /* probably SD Ver.1 */
1596    0451  97        		sub	a
1597    0452  328200    		ld	(_acmd41+3),a
1598                    	;  243                  blkmult = 512; /* in case that READ_OCR does not work */
1599    0455  321700    		ld	(_blkmult),a
1600    0458  321800    		ld	(_blkmult+1),a
1601    045B  321900    		ld	(_blkmult+2),a
1602    045E  3E02      		ld	a,2
1603    0460  321A00    		ld	(_blkmult+3),a
1604                    	;  244                  }
1605                    	;  245          else
1606    0463  1844      		jr	L133
1607                    	L123:
1608                    	;  246                  {
1609                    	;  247                  acmd41[3] = 0x40; /* probably SD Ver.2 */
1610    0465  3E40      		ld	a,64
1611    0467  328200    		ld	(_acmd41+3),a
1612                    	;  248                  if ((statptr[3] & 0x0f) == 0x01)
1613    046A  DD6EF6    		ld	l,(ix-10)
1614    046D  DD66F7    		ld	h,(ix-9)
1615    0470  23        		inc	hl
1616    0471  23        		inc	hl
1617    0472  23        		inc	hl
1618    0473  6E        		ld	l,(hl)
1619    0474  97        		sub	a
1620    0475  67        		ld	h,a
1621    0476  7D        		ld	a,l
1622    0477  E60F      		and	15
1623    0479  6F        		ld	l,a
1624    047A  97        		sub	a
1625    047B  67        		ld	h,a
1626    047C  7D        		ld	a,l
1627    047D  FE01      		cp	1
1628    047F  2003      		jr	nz,L23
1629    0481  7C        		ld	a,h
1630    0482  FE00      		cp	0
1631                    	L23:
1632    0484  2006      		jr	nz,L143
1633                    	;  249                          printf("  Voltage accepted: 2.7-3.6V, ");
1634    0486  211F01    		ld	hl,L541
1635    0489  CD0000    		call	_printf
1636                    	L143:
1637                    	;  250                  if (statptr[4] == 0xaa)
1638    048C  DD6EF6    		ld	l,(ix-10)
1639    048F  DD66F7    		ld	h,(ix-9)
1640    0492  23        		inc	hl
1641    0493  23        		inc	hl
1642    0494  23        		inc	hl
1643    0495  23        		inc	hl
1644    0496  7E        		ld	a,(hl)
1645    0497  FEAA      		cp	170
1646    0499  2008      		jr	nz,L153
1647                    	;  251                          printf("echo back ok\n");
1648    049B  213E01    		ld	hl,L551
1649    049E  CD0000    		call	_printf
1650                    	;  252                  else
1651    04A1  1806      		jr	L133
1652                    	L153:
1653                    	;  253                          printf("invalid echo back\n");
1654    04A3  214C01    		ld	hl,L561
1655    04A6  CD0000    		call	_printf
1656                    	L133:
1657                    	;  254                  }
1658                    	;  255  
1659                    	;  256          /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
1660                    	;  257          for (tries = 0; tries < 20; tries++)
1661    04A9  DD36F200  		ld	(ix-14),0
1662    04AD  DD36F300  		ld	(ix-13),0
1663                    	L173:
1664    04B1  DD7EF2    		ld	a,(ix-14)
1665    04B4  D614      		sub	20
1666    04B6  DD7EF3    		ld	a,(ix-13)
1667    04B9  DE00      		sbc	a,0
1668    04BB  F27B05    		jp	p,L104
1669                    	;  258                  {
1670                    	;  259                  cmd55[7] =  CRC7_buf(&cmd55[2], 5) | 0x01;
1671    04BE  210500    		ld	hl,5
1672    04C1  E5        		push	hl
1673    04C2  217100    		ld	hl,_cmd55+2
1674    04C5  CD6200    		call	_CRC7_buf
1675    04C8  F1        		pop	af
1676    04C9  CBC1      		set	0,c
1677    04CB  79        		ld	a,c
1678    04CC  327600    		ld	(_cmd55+7),a
1679                    	;  260                  statptr = sdcommand(cmd55, sizeof cmd55, rxbuf, 8);
1680    04CF  210800    		ld	hl,8
1681    04D2  E5        		push	hl
1682    04D3  21E80F    		ld	hl,_rxbuf
1683    04D6  E5        		push	hl
1684    04D7  210800    		ld	hl,8
1685    04DA  E5        		push	hl
1686    04DB  216F00    		ld	hl,_cmd55
1687    04DE  CDB201    		call	_sdcommand
1688    04E1  F1        		pop	af
1689    04E2  F1        		pop	af
1690    04E3  F1        		pop	af
1691    04E4  DD71F6    		ld	(ix-10),c
1692    04E7  DD70F7    		ld	(ix-9),b
1693                    	;  261                  printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
1694    04EA  DD6EF6    		ld	l,(ix-10)
1695    04ED  DD66F7    		ld	h,(ix-9)
1696    04F0  4E        		ld	c,(hl)
1697    04F1  97        		sub	a
1698    04F2  47        		ld	b,a
1699    04F3  C5        		push	bc
1700    04F4  215F01    		ld	hl,L571
1701    04F7  CD0000    		call	_printf
1702    04FA  F1        		pop	af
1703                    	;  262                  acmd41[7] = CRC7_buf(&acmd41[2], 5) | 0x01;
1704    04FB  210500    		ld	hl,5
1705    04FE  E5        		push	hl
1706    04FF  218100    		ld	hl,_acmd41+2
1707    0502  CD6200    		call	_CRC7_buf
1708    0505  F1        		pop	af
1709    0506  CBC1      		set	0,c
1710    0508  79        		ld	a,c
1711    0509  328600    		ld	(_acmd41+7),a
1712                    	;  263                  statptr = sdcommand(acmd41, sizeof acmd41, rxbuf, 8);
1713    050C  210800    		ld	hl,8
1714    050F  E5        		push	hl
1715    0510  21E80F    		ld	hl,_rxbuf
1716    0513  E5        		push	hl
1717    0514  210800    		ld	hl,8
1718    0517  E5        		push	hl
1719    0518  217F00    		ld	hl,_acmd41
1720    051B  CDB201    		call	_sdcommand
1721    051E  F1        		pop	af
1722    051F  F1        		pop	af
1723    0520  F1        		pop	af
1724    0521  DD71F6    		ld	(ix-10),c
1725    0524  DD70F7    		ld	(ix-9),b
1726                    	;  264                  printf("ACMD41: SEND_OP_COND, R1 response [%02x]\n", statptr[0]);
1727    0527  DD6EF6    		ld	l,(ix-10)
1728    052A  DD66F7    		ld	h,(ix-9)
1729    052D  4E        		ld	c,(hl)
1730    052E  97        		sub	a
1731    052F  47        		ld	b,a
1732    0530  C5        		push	bc
1733    0531  218301    		ld	hl,L502
1734    0534  CD0000    		call	_printf
1735    0537  F1        		pop	af
1736                    	;  265                  if (statptr[0] == 0x00)
1737    0538  DD6EF6    		ld	l,(ix-10)
1738    053B  DD66F7    		ld	h,(ix-9)
1739    053E  7E        		ld	a,(hl)
1740    053F  B7        		or	a
1741    0540  200D      		jr	nz,L134
1742                    	;  266                          break;
1743    0542  1837      		jr	L104
1744                    	L114:
1745    0544  DD34F2    		inc	(ix-14)
1746    0547  2003      		jr	nz,L43
1747    0549  DD34F3    		inc	(ix-13)
1748                    	L43:
1749    054C  C3B104    		jp	L173
1750                    	L134:
1751                    	;  267                  for (wtloop = 0; wtloop < tries * 100; wtloop++)
1752    054F  DD36F000  		ld	(ix-16),0
1753    0553  DD36F100  		ld	(ix-15),0
1754                    	L144:
1755    0557  DD6EF2    		ld	l,(ix-14)
1756    055A  DD66F3    		ld	h,(ix-13)
1757    055D  E5        		push	hl
1758    055E  216400    		ld	hl,100
1759    0561  E5        		push	hl
1760    0562  CD0000    		call	c.imul
1761    0565  E1        		pop	hl
1762    0566  DD7EF0    		ld	a,(ix-16)
1763    0569  95        		sub	l
1764    056A  DD7EF1    		ld	a,(ix-15)
1765    056D  9C        		sbc	a,h
1766    056E  F24405    		jp	p,L114
1767                    	L164:
1768    0571  DD34F0    		inc	(ix-16)
1769    0574  2003      		jr	nz,L63
1770    0576  DD34F1    		inc	(ix-15)
1771                    	L63:
1772    0579  18DC      		jr	L144
1773                    	L104:
1774                    	;  268                          ; /* wait loop, time increasing for each try */
1775                    	;  269                  }
1776                    	;  270  
1777                    	;  271          /* CMD58: READ_OCR */
1778                    	;  272          /* according to flowchart this does not work
1779                    	;  273             for SD Ver.1 but the response is ok anyway */
1780                    	;  274          cmd58[7] = CRC7_buf(&cmd58[2], 5) | 0x01;
1781    057B  210500    		ld	hl,5
1782    057E  E5        		push	hl
1783    057F  217900    		ld	hl,_cmd58+2
1784    0582  CD6200    		call	_CRC7_buf
1785    0585  F1        		pop	af
1786    0586  CBC1      		set	0,c
1787    0588  79        		ld	a,c
1788    0589  327E00    		ld	(_cmd58+7),a
1789                    	;  275          statptr = sdcommand(cmd58, sizeof cmd58, rxbuf, 8);
1790    058C  210800    		ld	hl,8
1791    058F  E5        		push	hl
1792    0590  21E80F    		ld	hl,_rxbuf
1793    0593  E5        		push	hl
1794    0594  210800    		ld	hl,8
1795    0597  E5        		push	hl
1796    0598  217700    		ld	hl,_cmd58
1797    059B  CDB201    		call	_sdcommand
1798    059E  F1        		pop	af
1799    059F  F1        		pop	af
1800    05A0  F1        		pop	af
1801    05A1  DD71F6    		ld	(ix-10),c
1802    05A4  DD70F7    		ld	(ix-9),b
1803                    	;  276          printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
1804                    	;  277                   statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
1805    05A7  DD6EF6    		ld	l,(ix-10)
1806    05AA  DD66F7    		ld	h,(ix-9)
1807    05AD  23        		inc	hl
1808    05AE  23        		inc	hl
1809    05AF  23        		inc	hl
1810    05B0  23        		inc	hl
1811    05B1  4E        		ld	c,(hl)
1812    05B2  97        		sub	a
1813    05B3  47        		ld	b,a
1814    05B4  C5        		push	bc
1815    05B5  DD6EF6    		ld	l,(ix-10)
1816    05B8  DD66F7    		ld	h,(ix-9)
1817    05BB  23        		inc	hl
1818    05BC  23        		inc	hl
1819    05BD  23        		inc	hl
1820    05BE  4E        		ld	c,(hl)
1821    05BF  97        		sub	a
1822    05C0  47        		ld	b,a
1823    05C1  C5        		push	bc
1824    05C2  DD6EF6    		ld	l,(ix-10)
1825    05C5  DD66F7    		ld	h,(ix-9)
1826    05C8  23        		inc	hl
1827    05C9  23        		inc	hl
1828    05CA  4E        		ld	c,(hl)
1829    05CB  97        		sub	a
1830    05CC  47        		ld	b,a
1831    05CD  C5        		push	bc
1832    05CE  DD6EF6    		ld	l,(ix-10)
1833    05D1  DD66F7    		ld	h,(ix-9)
1834    05D4  23        		inc	hl
1835    05D5  4E        		ld	c,(hl)
1836    05D6  97        		sub	a
1837    05D7  47        		ld	b,a
1838    05D8  C5        		push	bc
1839    05D9  DD6EF6    		ld	l,(ix-10)
1840    05DC  DD66F7    		ld	h,(ix-9)
1841    05DF  4E        		ld	c,(hl)
1842    05E0  97        		sub	a
1843    05E1  47        		ld	b,a
1844    05E2  C5        		push	bc
1845    05E3  21AD01    		ld	hl,L512
1846    05E6  CD0000    		call	_printf
1847    05E9  210A00    		ld	hl,10
1848    05EC  39        		add	hl,sp
1849    05ED  F9        		ld	sp,hl
1850                    	;  278          memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
1851    05EE  210400    		ld	hl,4
1852    05F1  E5        		push	hl
1853    05F2  DD6EF6    		ld	l,(ix-10)
1854    05F5  DD66F7    		ld	h,(ix-9)
1855    05F8  23        		inc	hl
1856    05F9  E5        		push	hl
1857    05FA  210E12    		ld	hl,_ocrreg
1858    05FD  CD0000    		call	_memcpy
1859    0600  F1        		pop	af
1860    0601  F1        		pop	af
1861                    	;  279          if (ocrreg[0] & 0x80)
1862    0602  3A0E12    		ld	a,(_ocrreg)
1863    0605  CB7F      		bit	7,a
1864    0607  6F        		ld	l,a
1865    0608  2829      		jr	z,L105
1866                    	;  280                  {
1867                    	;  281                  if (ocrreg[0] & 0x40)
1868    060A  3A0E12    		ld	a,(_ocrreg)
1869    060D  CB77      		bit	6,a
1870    060F  6F        		ld	l,a
1871    0610  2812      		jr	z,L115
1872                    	;  282                          {
1873                    	;  283                          /* SD Ver.2+, Block address */
1874                    	;  284                          blkmult = 1;
1875    0612  3E01      		ld	a,1
1876    0614  321900    		ld	(_blkmult+2),a
1877    0617  87        		add	a,a
1878    0618  9F        		sbc	a,a
1879    0619  321A00    		ld	(_blkmult+3),a
1880    061C  321800    		ld	(_blkmult+1),a
1881    061F  321700    		ld	(_blkmult),a
1882                    	;  285                          }
1883                    	;  286                  else
1884    0622  180F      		jr	L105
1885                    	L115:
1886                    	;  287                          {
1887                    	;  288                          /* SD Ver.2+, Byte address */
1888                    	;  289                          blkmult = 512;
1889    0624  97        		sub	a
1890    0625  321700    		ld	(_blkmult),a
1891    0628  321800    		ld	(_blkmult+1),a
1892    062B  321900    		ld	(_blkmult+2),a
1893    062E  3E02      		ld	a,2
1894    0630  321A00    		ld	(_blkmult+3),a
1895                    	L105:
1896                    	;  290                          }
1897                    	;  291                  }
1898                    	;  292  
1899                    	;  293          /* CMD 16: SET_BLOCKLEN, only if Byte address */
1900                    	;  294          if (blkmult == 512)
1901    0633  211700    		ld	hl,_blkmult
1902    0636  E5        		push	hl
1903    0637  97        		sub	a
1904    0638  320000    		ld	(c.r0),a
1905    063B  320100    		ld	(c.r0+1),a
1906    063E  320200    		ld	(c.r0+2),a
1907    0641  3E02      		ld	a,2
1908    0643  320300    		ld	(c.r0+3),a
1909    0646  210000    		ld	hl,c.r0
1910    0649  E5        		push	hl
1911    064A  CD0000    		call	c.lcmp
1912    064D  203D      		jr	nz,L135
1913                    	;  295                  {
1914                    	;  296                  cmd16[7] = CRC7_buf(&cmd16[2], 5) | 0x01;
1915    064F  210500    		ld	hl,5
1916    0652  E5        		push	hl
1917    0653  216900    		ld	hl,_cmd16+2
1918    0656  CD6200    		call	_CRC7_buf
1919    0659  F1        		pop	af
1920    065A  CBC1      		set	0,c
1921    065C  79        		ld	a,c
1922    065D  326E00    		ld	(_cmd16+7),a
1923                    	;  297                  statptr = sdcommand(cmd16, sizeof cmd16, rxbuf, 8);
1924    0660  210800    		ld	hl,8
1925    0663  E5        		push	hl
1926    0664  21E80F    		ld	hl,_rxbuf
1927    0667  E5        		push	hl
1928    0668  210800    		ld	hl,8
1929    066B  E5        		push	hl
1930    066C  216700    		ld	hl,_cmd16
1931    066F  CDB201    		call	_sdcommand
1932    0672  F1        		pop	af
1933    0673  F1        		pop	af
1934    0674  F1        		pop	af
1935    0675  DD71F6    		ld	(ix-10),c
1936    0678  DD70F7    		ld	(ix-9),b
1937                    	;  298                  printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n", statptr[0]);
1938    067B  DD6EF6    		ld	l,(ix-10)
1939    067E  DD66F7    		ld	h,(ix-9)
1940    0681  4E        		ld	c,(hl)
1941    0682  97        		sub	a
1942    0683  47        		ld	b,a
1943    0684  C5        		push	bc
1944    0685  21E601    		ld	hl,L522
1945    0688  CD0000    		call	_printf
1946    068B  F1        		pop	af
1947                    	L135:
1948                    	;  299                  }
1949                    	;  300  
1950                    	;  301          /* CMD10: SEND_CID */
1951                    	;  302          cmd10[7] = CRC7_buf(&cmd10[2], 5) | 0x01;
1952    068C  210500    		ld	hl,5
1953    068F  E5        		push	hl
1954    0690  216100    		ld	hl,_cmd10+2
1955    0693  CD6200    		call	_CRC7_buf
1956    0696  F1        		pop	af
1957    0697  CBC1      		set	0,c
1958    0699  79        		ld	a,c
1959    069A  326600    		ld	(_cmd10+7),a
1960                    	;  303          statptr = sdcommand(cmd10, sizeof cmd10, rxbuf, 30);
1961    069D  211E00    		ld	hl,30
1962    06A0  E5        		push	hl
1963    06A1  21E80F    		ld	hl,_rxbuf
1964    06A4  E5        		push	hl
1965    06A5  210800    		ld	hl,8
1966    06A8  E5        		push	hl
1967    06A9  215F00    		ld	hl,_cmd10
1968    06AC  CDB201    		call	_sdcommand
1969    06AF  F1        		pop	af
1970    06B0  F1        		pop	af
1971    06B1  F1        		pop	af
1972    06B2  DD71F6    		ld	(ix-10),c
1973    06B5  DD70F7    		ld	(ix-9),b
1974                    	;  304          printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
1975    06B8  DD6EF6    		ld	l,(ix-10)
1976    06BB  DD66F7    		ld	h,(ix-9)
1977    06BE  4E        		ld	c,(hl)
1978    06BF  97        		sub	a
1979    06C0  47        		ld	b,a
1980    06C1  C5        		push	bc
1981    06C2  211E02    		ld	hl,L532
1982    06C5  CD0000    		call	_printf
1983    06C8  F1        		pop	af
1984                    	;  305          for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
1985    06C9  DD36F200  		ld	(ix-14),0
1986    06CD  DD36F300  		ld	(ix-13),0
1987                    	L145:
1988    06D1  DD7EF2    		ld	a,(ix-14)
1989    06D4  D614      		sub	20
1990    06D6  DD7EF3    		ld	a,(ix-13)
1991    06D9  DE00      		sbc	a,0
1992    06DB  F2FB06    		jp	p,L155
1993    06DE  DD6EF6    		ld	l,(ix-10)
1994    06E1  DD66F7    		ld	h,(ix-9)
1995    06E4  7E        		ld	a,(hl)
1996    06E5  FEFE      		cp	254
1997    06E7  2812      		jr	z,L155
1998                    	L165:
1999    06E9  DD34F2    		inc	(ix-14)
2000    06EC  2003      		jr	nz,L04
2001    06EE  DD34F3    		inc	(ix-13)
2002                    	L04:
2003    06F1  DD34F6    		inc	(ix-10)
2004    06F4  2003      		jr	nz,L24
2005    06F6  DD34F7    		inc	(ix-9)
2006                    	L24:
2007    06F9  18D6      		jr	L145
2008                    	L155:
2009                    	;  306                  ; /* looking for 0xfe that is the byte before data */
2010                    	;  307          if (*statptr != 0xfe)
2011    06FB  DD6EF6    		ld	l,(ix-10)
2012    06FE  DD66F7    		ld	h,(ix-9)
2013    0701  7E        		ld	a,(hl)
2014    0702  FEFE      		cp	254
2015    0704  2809      		jr	z,L106
2016                    	;  308                  {
2017                    	;  309                  printf("  No data found\n");
2018    0706  214302    		ld	hl,L542
2019    0709  CD0000    		call	_printf
2020                    	;  310                  }
2021                    	;  311          else
2022    070C  C3DD07    		jp	L116
2023                    	L106:
2024                    	;  312                  {
2025                    	;  313                  statptr++;
2026    070F  DD34F6    		inc	(ix-10)
2027    0712  2003      		jr	nz,L44
2028    0714  DD34F7    		inc	(ix-9)
2029                    	L44:
2030                    	;  314                  prtptr = statptr;
2031    0717  DD7EF6    		ld	a,(ix-10)
2032    071A  DD77F8    		ld	(ix-8),a
2033    071D  DD7EF7    		ld	a,(ix-9)
2034    0720  DD77F9    		ld	(ix-7),a
2035                    	;  315                  printf("  CID: [");
2036    0723  215402    		ld	hl,L552
2037    0726  CD0000    		call	_printf
2038                    	;  316                  for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
2039    0729  DD36F400  		ld	(ix-12),0
2040    072D  DD36F500  		ld	(ix-11),0
2041                    	L126:
2042    0731  DD7EF4    		ld	a,(ix-12)
2043    0734  D610      		sub	16
2044    0736  DD7EF5    		ld	a,(ix-11)
2045    0739  DE00      		sbc	a,0
2046    073B  F26107    		jp	p,L136
2047                    	;  317                          printf("%02x ", *prtptr);
2048    073E  DD6EF8    		ld	l,(ix-8)
2049    0741  DD66F9    		ld	h,(ix-7)
2050    0744  4E        		ld	c,(hl)
2051    0745  97        		sub	a
2052    0746  47        		ld	b,a
2053    0747  C5        		push	bc
2054    0748  215D02    		ld	hl,L562
2055    074B  CD0000    		call	_printf
2056    074E  F1        		pop	af
2057    074F  DD34F4    		inc	(ix-12)
2058    0752  2003      		jr	nz,L64
2059    0754  DD34F5    		inc	(ix-11)
2060                    	L64:
2061    0757  DD34F8    		inc	(ix-8)
2062    075A  2003      		jr	nz,L05
2063    075C  DD34F9    		inc	(ix-7)
2064                    	L05:
2065    075F  18D0      		jr	L126
2066                    	L136:
2067                    	;  318                  prtptr = statptr;
2068    0761  DD7EF6    		ld	a,(ix-10)
2069    0764  DD77F8    		ld	(ix-8),a
2070    0767  DD7EF7    		ld	a,(ix-9)
2071    076A  DD77F9    		ld	(ix-7),a
2072                    	;  319                  printf("\b] |");
2073    076D  216302    		ld	hl,L572
2074    0770  CD0000    		call	_printf
2075                    	;  320                  for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
2076    0773  DD36F400  		ld	(ix-12),0
2077    0777  DD36F500  		ld	(ix-11),0
2078                    	L166:
2079    077B  DD7EF4    		ld	a,(ix-12)
2080    077E  D610      		sub	16
2081    0780  DD7EF5    		ld	a,(ix-11)
2082    0783  DE00      		sbc	a,0
2083    0785  F2C407    		jp	p,L176
2084                    	;  321                          {
2085                    	;  322                          if ((' ' <= *prtptr) && (*prtptr < 127))
2086    0788  DD6EF8    		ld	l,(ix-8)
2087    078B  DD66F9    		ld	h,(ix-7)
2088    078E  7E        		ld	a,(hl)
2089    078F  FE20      		cp	32
2090    0791  3819      		jr	c,L127
2091    0793  DD6EF8    		ld	l,(ix-8)
2092    0796  DD66F9    		ld	h,(ix-7)
2093    0799  7E        		ld	a,(hl)
2094    079A  FE7F      		cp	127
2095    079C  300E      		jr	nc,L127
2096                    	;  323                                  putchar(*prtptr);
2097    079E  DD6EF8    		ld	l,(ix-8)
2098    07A1  DD66F9    		ld	h,(ix-7)
2099    07A4  6E        		ld	l,(hl)
2100    07A5  97        		sub	a
2101    07A6  67        		ld	h,a
2102    07A7  CD0000    		call	_putchar
2103                    	;  324                          else
2104    07AA  1806      		jr	L107
2105                    	L127:
2106                    	;  325                                  putchar('.');
2107    07AC  212E00    		ld	hl,46
2108    07AF  CD0000    		call	_putchar
2109                    	L107:
2110    07B2  DD34F4    		inc	(ix-12)
2111    07B5  2003      		jr	nz,L25
2112    07B7  DD34F5    		inc	(ix-11)
2113                    	L25:
2114    07BA  DD34F8    		inc	(ix-8)
2115    07BD  2003      		jr	nz,L45
2116    07BF  DD34F9    		inc	(ix-7)
2117                    	L45:
2118    07C2  18B7      		jr	L166
2119                    	L176:
2120                    	;  326                          }
2121                    	;  327                  printf("|\n");
2122    07C4  216802    		ld	hl,L503
2123    07C7  CD0000    		call	_printf
2124                    	;  328                  memcpy(&cidreg[0], &statptr[0], sizeof (cidreg));
2125    07CA  211000    		ld	hl,16
2126    07CD  E5        		push	hl
2127    07CE  DD6EF6    		ld	l,(ix-10)
2128    07D1  DD66F7    		ld	h,(ix-9)
2129    07D4  E5        		push	hl
2130    07D5  211212    		ld	hl,_cidreg
2131    07D8  CD0000    		call	_memcpy
2132    07DB  F1        		pop	af
2133    07DC  F1        		pop	af
2134                    	L116:
2135                    	;  329                  }
2136                    	;  330  
2137                    	;  331          /* CMD9: SEND_CSD */
2138                    	;  332          cmd9[7] = CRC7_buf(&cmd9[2], 5) | 0x01;
2139    07DD  210500    		ld	hl,5
2140    07E0  E5        		push	hl
2141    07E1  215900    		ld	hl,_cmd9+2
2142    07E4  CD6200    		call	_CRC7_buf
2143    07E7  F1        		pop	af
2144    07E8  CBC1      		set	0,c
2145    07EA  79        		ld	a,c
2146    07EB  325E00    		ld	(_cmd9+7),a
2147                    	;  333          statptr = sdcommand(cmd9, sizeof cmd9, rxbuf, 30);
2148    07EE  211E00    		ld	hl,30
2149    07F1  E5        		push	hl
2150    07F2  21E80F    		ld	hl,_rxbuf
2151    07F5  E5        		push	hl
2152    07F6  210800    		ld	hl,8
2153    07F9  E5        		push	hl
2154    07FA  215700    		ld	hl,_cmd9
2155    07FD  CDB201    		call	_sdcommand
2156    0800  F1        		pop	af
2157    0801  F1        		pop	af
2158    0802  F1        		pop	af
2159    0803  DD71F6    		ld	(ix-10),c
2160    0806  DD70F7    		ld	(ix-9),b
2161                    	;  334          printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
2162    0809  DD6EF6    		ld	l,(ix-10)
2163    080C  DD66F7    		ld	h,(ix-9)
2164    080F  4E        		ld	c,(hl)
2165    0810  97        		sub	a
2166    0811  47        		ld	b,a
2167    0812  C5        		push	bc
2168    0813  216B02    		ld	hl,L513
2169    0816  CD0000    		call	_printf
2170    0819  F1        		pop	af
2171                    	;  335          for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
2172    081A  DD36F200  		ld	(ix-14),0
2173    081E  DD36F300  		ld	(ix-13),0
2174                    	L147:
2175    0822  DD7EF2    		ld	a,(ix-14)
2176    0825  D614      		sub	20
2177    0827  DD7EF3    		ld	a,(ix-13)
2178    082A  DE00      		sbc	a,0
2179    082C  F24C08    		jp	p,L157
2180    082F  DD6EF6    		ld	l,(ix-10)
2181    0832  DD66F7    		ld	h,(ix-9)
2182    0835  7E        		ld	a,(hl)
2183    0836  FEFE      		cp	254
2184    0838  2812      		jr	z,L157
2185                    	L167:
2186    083A  DD34F2    		inc	(ix-14)
2187    083D  2003      		jr	nz,L65
2188    083F  DD34F3    		inc	(ix-13)
2189                    	L65:
2190    0842  DD34F6    		inc	(ix-10)
2191    0845  2003      		jr	nz,L06
2192    0847  DD34F7    		inc	(ix-9)
2193                    	L06:
2194    084A  18D6      		jr	L147
2195                    	L157:
2196                    	;  336                  ; /* looking for 0xfe that is the byte before data */
2197                    	;  337          if (*statptr != 0xfe)
2198    084C  DD6EF6    		ld	l,(ix-10)
2199    084F  DD66F7    		ld	h,(ix-9)
2200    0852  7E        		ld	a,(hl)
2201    0853  FEFE      		cp	254
2202    0855  2809      		jr	z,L1001
2203                    	;  338                  {
2204                    	;  339                  printf("  No data found\n");
2205    0857  218F02    		ld	hl,L523
2206    085A  CD0000    		call	_printf
2207                    	;  340                  }
2208                    	;  341          else
2209    085D  C32E09    		jp	L1101
2210                    	L1001:
2211                    	;  342                  {
2212                    	;  343                  statptr++;
2213    0860  DD34F6    		inc	(ix-10)
2214    0863  2003      		jr	nz,L26
2215    0865  DD34F7    		inc	(ix-9)
2216                    	L26:
2217                    	;  344                  prtptr = statptr;
2218    0868  DD7EF6    		ld	a,(ix-10)
2219    086B  DD77F8    		ld	(ix-8),a
2220    086E  DD7EF7    		ld	a,(ix-9)
2221    0871  DD77F9    		ld	(ix-7),a
2222                    	;  345                  printf("  CSD: [");
2223    0874  21A002    		ld	hl,L533
2224    0877  CD0000    		call	_printf
2225                    	;  346                  for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
2226    087A  DD36F400  		ld	(ix-12),0
2227    087E  DD36F500  		ld	(ix-11),0
2228                    	L1201:
2229    0882  DD7EF4    		ld	a,(ix-12)
2230    0885  D610      		sub	16
2231    0887  DD7EF5    		ld	a,(ix-11)
2232    088A  DE00      		sbc	a,0
2233    088C  F2B208    		jp	p,L1301
2234                    	;  347                          printf("%02x ", *prtptr);
2235    088F  DD6EF8    		ld	l,(ix-8)
2236    0892  DD66F9    		ld	h,(ix-7)
2237    0895  4E        		ld	c,(hl)
2238    0896  97        		sub	a
2239    0897  47        		ld	b,a
2240    0898  C5        		push	bc
2241    0899  21A902    		ld	hl,L543
2242    089C  CD0000    		call	_printf
2243    089F  F1        		pop	af
2244    08A0  DD34F4    		inc	(ix-12)
2245    08A3  2003      		jr	nz,L46
2246    08A5  DD34F5    		inc	(ix-11)
2247                    	L46:
2248    08A8  DD34F8    		inc	(ix-8)
2249    08AB  2003      		jr	nz,L66
2250    08AD  DD34F9    		inc	(ix-7)
2251                    	L66:
2252    08B0  18D0      		jr	L1201
2253                    	L1301:
2254                    	;  348                  prtptr = statptr;
2255    08B2  DD7EF6    		ld	a,(ix-10)
2256    08B5  DD77F8    		ld	(ix-8),a
2257    08B8  DD7EF7    		ld	a,(ix-9)
2258    08BB  DD77F9    		ld	(ix-7),a
2259                    	;  349                  printf("\b] |");
2260    08BE  21AF02    		ld	hl,L553
2261    08C1  CD0000    		call	_printf
2262                    	;  350                  for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
2263    08C4  DD36F400  		ld	(ix-12),0
2264    08C8  DD36F500  		ld	(ix-11),0
2265                    	L1601:
2266    08CC  DD7EF4    		ld	a,(ix-12)
2267    08CF  D610      		sub	16
2268    08D1  DD7EF5    		ld	a,(ix-11)
2269    08D4  DE00      		sbc	a,0
2270    08D6  F21509    		jp	p,L1701
2271                    	;  351                          {
2272                    	;  352                          if ((' ' <= *prtptr) && (*prtptr < 127))
2273    08D9  DD6EF8    		ld	l,(ix-8)
2274    08DC  DD66F9    		ld	h,(ix-7)
2275    08DF  7E        		ld	a,(hl)
2276    08E0  FE20      		cp	32
2277    08E2  3819      		jr	c,L1211
2278    08E4  DD6EF8    		ld	l,(ix-8)
2279    08E7  DD66F9    		ld	h,(ix-7)
2280    08EA  7E        		ld	a,(hl)
2281    08EB  FE7F      		cp	127
2282    08ED  300E      		jr	nc,L1211
2283                    	;  353                                  putchar(*prtptr);
2284    08EF  DD6EF8    		ld	l,(ix-8)
2285    08F2  DD66F9    		ld	h,(ix-7)
2286    08F5  6E        		ld	l,(hl)
2287    08F6  97        		sub	a
2288    08F7  67        		ld	h,a
2289    08F8  CD0000    		call	_putchar
2290                    	;  354                          else
2291    08FB  1806      		jr	L1011
2292                    	L1211:
2293                    	;  355                                  putchar('.');
2294    08FD  212E00    		ld	hl,46
2295    0900  CD0000    		call	_putchar
2296                    	L1011:
2297    0903  DD34F4    		inc	(ix-12)
2298    0906  2003      		jr	nz,L07
2299    0908  DD34F5    		inc	(ix-11)
2300                    	L07:
2301    090B  DD34F8    		inc	(ix-8)
2302    090E  2003      		jr	nz,L27
2303    0910  DD34F9    		inc	(ix-7)
2304                    	L27:
2305    0913  18B7      		jr	L1601
2306                    	L1701:
2307                    	;  356                          }
2308                    	;  357                  printf("|\n");
2309    0915  21B402    		ld	hl,L563
2310    0918  CD0000    		call	_printf
2311                    	;  358                  memcpy(&csdreg[0], &statptr[0], sizeof (csdreg));
2312    091B  211000    		ld	hl,16
2313    091E  E5        		push	hl
2314    091F  DD6EF6    		ld	l,(ix-10)
2315    0922  DD66F7    		ld	h,(ix-9)
2316    0925  E5        		push	hl
2317    0926  212212    		ld	hl,_csdreg
2318    0929  CD0000    		call	_memcpy
2319    092C  F1        		pop	af
2320    092D  F1        		pop	af
2321                    	L1101:
2322                    	;  359                  }
2323                    	;  360  
2324                    	;  361          ready = YES;
2325    092E  210100    		ld	hl,1
2326    0931  223412    		ld	(_ready),hl
2327                    	;  362  
2328                    	;  363          statptr = sdcommand(0, 0, rxbuf, 16);
2329    0934  211000    		ld	hl,16
2330    0937  E5        		push	hl
2331    0938  21E80F    		ld	hl,_rxbuf
2332    093B  E5        		push	hl
2333    093C  210000    		ld	hl,0
2334    093F  E5        		push	hl
2335    0940  210000    		ld	hl,0
2336    0943  CDB201    		call	_sdcommand
2337    0946  F1        		pop	af
2338    0947  F1        		pop	af
2339    0948  F1        		pop	af
2340    0949  DD71F6    		ld	(ix-10),c
2341    094C  DD70F7    		ld	(ix-9),b
2342                    	;  364          printf("Sent 16 bytes of clock pulses, select active\n");
2343    094F  21B702    		ld	hl,L573
2344    0952  CD0000    		call	_printf
2345                    	;  365  
2346                    	;  366          spideselect();
2347    0955  CD0000    		call	_spideselect
2348                    	;  367          ledoff();
2349    0958  CD0000    		call	_ledoff
2350                    	;  368  
2351                    	;  369          /* maybe more to handle MMC cards */
2352                    	;  370          }
2353    095B  C30000    		jp	c.rets0
2354                    	;  371  
2355                    	;  372  /* CMD17 is the read block command */
2356                    	;  373  unsigned char cmd17[] = {0xff, 0xff, 0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
2357                    		.psect	_data
2358                    	_cmd17:
2359    02E5  FF        		.byte	255
2360    02E6  FF        		.byte	255
2361    02E7  51        		.byte	81
2362                    		.byte	[1]
2363                    		.byte	[1]
2364                    		.byte	[1]
2365                    		.byte	[1]
2366    02EC  55        		.byte	85
2367                    	L504:
2368    02ED  53        		.byte	83
2369    02EE  44        		.byte	68
2370    02EF  20        		.byte	32
2371    02F0  63        		.byte	99
2372    02F1  61        		.byte	97
2373    02F2  72        		.byte	114
2374    02F3  64        		.byte	100
2375    02F4  20        		.byte	32
2376    02F5  6E        		.byte	110
2377    02F6  6F        		.byte	111
2378    02F7  74        		.byte	116
2379    02F8  20        		.byte	32
2380    02F9  69        		.byte	105
2381    02FA  6E        		.byte	110
2382    02FB  69        		.byte	105
2383    02FC  74        		.byte	116
2384    02FD  69        		.byte	105
2385    02FE  61        		.byte	97
2386    02FF  6C        		.byte	108
2387    0300  69        		.byte	105
2388    0301  7A        		.byte	122
2389    0302  65        		.byte	101
2390    0303  64        		.byte	100
2391    0304  0A        		.byte	10
2392    0305  00        		.byte	0
2393                    	L514:
2394    0306  43        		.byte	67
2395    0307  4D        		.byte	77
2396    0308  44        		.byte	68
2397    0309  31        		.byte	49
2398    030A  37        		.byte	55
2399    030B  20        		.byte	32
2400    030C  52        		.byte	82
2401    030D  31        		.byte	49
2402    030E  20        		.byte	32
2403    030F  72        		.byte	114
2404    0310  65        		.byte	101
2405    0311  73        		.byte	115
2406    0312  70        		.byte	112
2407    0313  6F        		.byte	111
2408    0314  6E        		.byte	110
2409    0315  73        		.byte	115
2410    0316  65        		.byte	101
2411    0317  20        		.byte	32
2412    0318  5B        		.byte	91
2413    0319  25        		.byte	37
2414    031A  30        		.byte	48
2415    031B  32        		.byte	50
2416    031C  78        		.byte	120
2417    031D  5D        		.byte	93
2418    031E  0A        		.byte	10
2419    031F  00        		.byte	0
2420                    	L524:
2421    0320  63        		.byte	99
2422    0321  6F        		.byte	111
2423    0322  75        		.byte	117
2424    0323  6C        		.byte	108
2425    0324  64        		.byte	100
2426    0325  20        		.byte	32
2427    0326  6E        		.byte	110
2428    0327  6F        		.byte	111
2429    0328  74        		.byte	116
2430    0329  20        		.byte	32
2431    032A  72        		.byte	114
2432    032B  65        		.byte	101
2433    032C  61        		.byte	97
2434    032D  64        		.byte	100
2435    032E  20        		.byte	32
2436    032F  62        		.byte	98
2437    0330  6C        		.byte	108
2438    0331  6F        		.byte	111
2439    0332  63        		.byte	99
2440    0333  6B        		.byte	107
2441    0334  0A        		.byte	10
2442    0335  00        		.byte	0
2443                    	L534:
2444    0336  52        		.byte	82
2445    0337  65        		.byte	101
2446    0338  61        		.byte	97
2447    0339  64        		.byte	100
2448    033A  20        		.byte	32
2449    033B  65        		.byte	101
2450    033C  72        		.byte	114
2451    033D  72        		.byte	114
2452    033E  6F        		.byte	111
2453    033F  72        		.byte	114
2454    0340  3A        		.byte	58
2455    0341  20        		.byte	32
2456    0342  30        		.byte	48
2457    0343  78        		.byte	120
2458    0344  25        		.byte	37
2459    0345  30        		.byte	48
2460    0346  32        		.byte	50
2461    0347  78        		.byte	120
2462    0348  0A        		.byte	10
2463    0349  00        		.byte	0
2464                    	L544:
2465    034A  4E        		.byte	78
2466    034B  6F        		.byte	111
2467    034C  20        		.byte	32
2468    034D  64        		.byte	100
2469    034E  61        		.byte	97
2470    034F  74        		.byte	116
2471    0350  61        		.byte	97
2472    0351  20        		.byte	32
2473    0352  66        		.byte	102
2474    0353  6F        		.byte	111
2475    0354  75        		.byte	117
2476    0355  6E        		.byte	110
2477    0356  64        		.byte	100
2478    0357  0A        		.byte	10
2479    0358  00        		.byte	0
2480                    	L554:
2481    0359  44        		.byte	68
2482    035A  61        		.byte	97
2483    035B  74        		.byte	116
2484    035C  61        		.byte	97
2485    035D  20        		.byte	32
2486    035E  62        		.byte	98
2487    035F  6C        		.byte	108
2488    0360  6F        		.byte	111
2489    0361  63        		.byte	99
2490    0362  6B        		.byte	107
2491    0363  20        		.byte	32
2492    0364  25        		.byte	37
2493    0365  6C        		.byte	108
2494    0366  64        		.byte	100
2495    0367  3A        		.byte	58
2496    0368  0A        		.byte	10
2497    0369  00        		.byte	0
2498                    	L564:
2499    036A  20        		.byte	32
2500    036B  20        		.byte	32
2501    036C  43        		.byte	67
2502    036D  52        		.byte	82
2503    036E  43        		.byte	67
2504    036F  20        		.byte	32
2505    0370  65        		.byte	101
2506    0371  72        		.byte	114
2507    0372  72        		.byte	114
2508    0373  6F        		.byte	111
2509    0374  72        		.byte	114
2510    0375  2C        		.byte	44
2511    0376  20        		.byte	32
2512    0377  72        		.byte	114
2513    0378  65        		.byte	101
2514    0379  63        		.byte	99
2515    037A  69        		.byte	105
2516    037B  65        		.byte	101
2517    037C  76        		.byte	118
2518    037D  65        		.byte	101
2519    037E  64        		.byte	100
2520    037F  20        		.byte	32
2521    0380  43        		.byte	67
2522    0381  52        		.byte	82
2523    0382  43        		.byte	67
2524    0383  31        		.byte	49
2525    0384  36        		.byte	54
2526    0385  3A        		.byte	58
2527    0386  20        		.byte	32
2528    0387  30        		.byte	48
2529    0388  78        		.byte	120
2530    0389  25        		.byte	37
2531    038A  30        		.byte	48
2532    038B  34        		.byte	52
2533    038C  78        		.byte	120
2534    038D  2C        		.byte	44
2535    038E  20        		.byte	32
2536    038F  63        		.byte	99
2537    0390  61        		.byte	97
2538    0391  6C        		.byte	108
2539    0392  63        		.byte	99
2540    0393  3A        		.byte	58
2541    0394  20        		.byte	32
2542    0395  30        		.byte	48
2543    0396  78        		.byte	120
2544    0397  25        		.byte	37
2545    0398  30        		.byte	48
2546    0399  34        		.byte	52
2547    039A  68        		.byte	104
2548    039B  69        		.byte	105
2549    039C  0A        		.byte	10
2550    039D  00        		.byte	0
2551                    		.psect	_text
2552                    	;  374  
2553                    	;  375  /* read data block */
2554                    	;  376  int sdread(int printit)
2555                    	;  377          {
2556                    	_sdread:
2557    095E  CD0000    		call	c.savs
2558    0961  21E8FF    		ld	hl,65512
2559    0964  39        		add	hl,sp
2560    0965  F9        		ld	sp,hl
2561                    	;  378          unsigned char *rxdata;
2562                    	;  379          unsigned char *statptr;
2563                    	;  380          int dmpline;
2564                    	;  381          int rxbytes;
2565                    	;  382          int tries;
2566                    	;  383          unsigned long blktoread;
2567                    	;  384          unsigned int rxcrc16;
2568                    	;  385          unsigned int calcrc16;
2569                    	;  386  
2570                    	;  387          ledon();
2571    0966  CD0000    		call	_ledon
2572                    	;  388          spiselect();
2573    0969  CD0000    		call	_spiselect
2574                    	;  389  
2575                    	;  390          if (!ready)
2576    096C  2A3412    		ld	hl,(_ready)
2577    096F  7C        		ld	a,h
2578    0970  B5        		or	l
2579    0971  2012      		jr	nz,L1411
2580                    	;  391                  {
2581                    	;  392                  printf("SD card not initialized\n");
2582    0973  21ED02    		ld	hl,L504
2583    0976  CD0000    		call	_printf
2584                    	;  393                  spideselect();
2585    0979  CD0000    		call	_spideselect
2586                    	;  394                  ledoff();
2587    097C  CD0000    		call	_ledoff
2588                    	;  395                  return (NO);
2589    097F  010000    		ld	bc,0
2590    0982  C30000    		jp	c.rets
2591                    	L1411:
2592                    	;  396                  }
2593                    	;  397  
2594                    	;  398          /* CMD17: READ_SINGLE_BLOCK */
2595                    	;  399          /* Insert block # into command */
2596                    	;  400          blktoread = blkmult * blockno;
2597    0985  DDE5      		push	ix
2598    0987  C1        		pop	bc
2599    0988  21ECFF    		ld	hl,65516
2600    098B  09        		add	hl,bc
2601    098C  E5        		push	hl
2602    098D  211700    		ld	hl,_blkmult
2603    0990  CD0000    		call	c.0mvf
2604    0993  210000    		ld	hl,c.r0
2605    0996  E5        		push	hl
2606    0997  213A12    		ld	hl,_blockno
2607    099A  E5        		push	hl
2608    099B  CD0000    		call	c.lmul
2609    099E  CD0000    		call	c.mvl
2610    09A1  F1        		pop	af
2611                    	;  401          cmd17[6] = blktoread & 0xff;
2612    09A2  DD6EEE    		ld	l,(ix-18)
2613    09A5  7D        		ld	a,l
2614    09A6  E6FF      		and	255
2615    09A8  32EB02    		ld	(_cmd17+6),a
2616                    	;  402          blktoread = blktoread >> 8;
2617    09AB  DDE5      		push	ix
2618    09AD  C1        		pop	bc
2619    09AE  21ECFF    		ld	hl,65516
2620    09B1  09        		add	hl,bc
2621    09B2  E5        		push	hl
2622    09B3  210800    		ld	hl,8
2623    09B6  E5        		push	hl
2624    09B7  CD0000    		call	c.ulrsh
2625    09BA  F1        		pop	af
2626                    	;  403          cmd17[5] = blktoread & 0xff;
2627    09BB  DD6EEE    		ld	l,(ix-18)
2628    09BE  7D        		ld	a,l
2629    09BF  E6FF      		and	255
2630    09C1  32EA02    		ld	(_cmd17+5),a
2631                    	;  404          blktoread = blktoread >> 8;
2632    09C4  DDE5      		push	ix
2633    09C6  C1        		pop	bc
2634    09C7  21ECFF    		ld	hl,65516
2635    09CA  09        		add	hl,bc
2636    09CB  E5        		push	hl
2637    09CC  210800    		ld	hl,8
2638    09CF  E5        		push	hl
2639    09D0  CD0000    		call	c.ulrsh
2640    09D3  F1        		pop	af
2641                    	;  405          cmd17[4] = blktoread & 0xff;
2642    09D4  DD6EEE    		ld	l,(ix-18)
2643    09D7  7D        		ld	a,l
2644    09D8  E6FF      		and	255
2645    09DA  32E902    		ld	(_cmd17+4),a
2646                    	;  406          blktoread = blktoread >> 8;
2647    09DD  DDE5      		push	ix
2648    09DF  C1        		pop	bc
2649    09E0  21ECFF    		ld	hl,65516
2650    09E3  09        		add	hl,bc
2651    09E4  E5        		push	hl
2652    09E5  210800    		ld	hl,8
2653    09E8  E5        		push	hl
2654    09E9  CD0000    		call	c.ulrsh
2655    09EC  F1        		pop	af
2656                    	;  407          cmd17[3] = blktoread & 0xff;
2657    09ED  DD6EEE    		ld	l,(ix-18)
2658    09F0  7D        		ld	a,l
2659    09F1  E6FF      		and	255
2660    09F3  32E802    		ld	(_cmd17+3),a
2661                    	;  408          blktoread = blktoread >> 8;
2662    09F6  DDE5      		push	ix
2663    09F8  C1        		pop	bc
2664    09F9  21ECFF    		ld	hl,65516
2665    09FC  09        		add	hl,bc
2666    09FD  E5        		push	hl
2667    09FE  210800    		ld	hl,8
2668    0A01  E5        		push	hl
2669    0A02  CD0000    		call	c.ulrsh
2670    0A05  F1        		pop	af
2671                    	;  409  
2672                    	;  410          cmd17[7] = CRC7_buf(&cmd17[2], 5) | 0x01;
2673    0A06  210500    		ld	hl,5
2674    0A09  E5        		push	hl
2675    0A0A  21E702    		ld	hl,_cmd17+2
2676    0A0D  CD6200    		call	_CRC7_buf
2677    0A10  F1        		pop	af
2678    0A11  CBC1      		set	0,c
2679    0A13  79        		ld	a,c
2680    0A14  32EC02    		ld	(_cmd17+7),a
2681                    	;  411          statptr = sdcommand(cmd17, sizeof cmd17, rxbuf, 530);
2682    0A17  211202    		ld	hl,530
2683    0A1A  E5        		push	hl
2684    0A1B  21E80F    		ld	hl,_rxbuf
2685    0A1E  E5        		push	hl
2686    0A1F  210800    		ld	hl,8
2687    0A22  E5        		push	hl
2688    0A23  21E502    		ld	hl,_cmd17
2689    0A26  CDB201    		call	_sdcommand
2690    0A29  F1        		pop	af
2691    0A2A  F1        		pop	af
2692    0A2B  F1        		pop	af
2693    0A2C  DD71F6    		ld	(ix-10),c
2694    0A2F  DD70F7    		ld	(ix-9),b
2695                    	;  412          if (printit)
2696    0A32  DD7E04    		ld	a,(ix+4)
2697    0A35  DDB605    		or	(ix+5)
2698    0A38  2811      		jr	z,L1511
2699                    	;  413                  printf("CMD17 R1 response [%02x]\n", statptr[0]);
2700    0A3A  DD6EF6    		ld	l,(ix-10)
2701    0A3D  DD66F7    		ld	h,(ix-9)
2702    0A40  4E        		ld	c,(hl)
2703    0A41  97        		sub	a
2704    0A42  47        		ld	b,a
2705    0A43  C5        		push	bc
2706    0A44  210603    		ld	hl,L514
2707    0A47  CD0000    		call	_printf
2708    0A4A  F1        		pop	af
2709                    	L1511:
2710                    	;  414          if (statptr[0])
2711    0A4B  DD6EF6    		ld	l,(ix-10)
2712    0A4E  DD66F7    		ld	h,(ix-9)
2713    0A51  7E        		ld	a,(hl)
2714    0A52  B7        		or	a
2715    0A53  2812      		jr	z,L1611
2716                    	;  415                  {
2717                    	;  416                  printf("could not read block\n");
2718    0A55  212003    		ld	hl,L524
2719    0A58  CD0000    		call	_printf
2720                    	;  417                  spideselect();
2721    0A5B  CD0000    		call	_spideselect
2722                    	;  418                  ledoff();
2723    0A5E  CD0000    		call	_ledoff
2724                    	;  419                  return (NO);
2725    0A61  010000    		ld	bc,0
2726    0A64  C30000    		jp	c.rets
2727                    	L1611:
2728                    	;  420                  }
2729                    	;  421          statptr++;
2730    0A67  DD34F6    		inc	(ix-10)
2731    0A6A  2003      		jr	nz,L67
2732    0A6C  DD34F7    		inc	(ix-9)
2733                    	L67:
2734                    	;  422          for (tries = 0; (tries < 80) && (*statptr != 0xfe); tries++, statptr++)
2735    0A6F  DD36F000  		ld	(ix-16),0
2736    0A73  DD36F100  		ld	(ix-15),0
2737                    	L1711:
2738    0A77  DD7EF0    		ld	a,(ix-16)
2739    0A7A  D650      		sub	80
2740    0A7C  DD7EF1    		ld	a,(ix-15)
2741    0A7F  DE00      		sbc	a,0
2742    0A81  F2CA0A    		jp	p,L1021
2743    0A84  DD6EF6    		ld	l,(ix-10)
2744    0A87  DD66F7    		ld	h,(ix-9)
2745    0A8A  7E        		ld	a,(hl)
2746    0A8B  FEFE      		cp	254
2747    0A8D  283B      		jr	z,L1021
2748                    	;  423                  {
2749                    	;  424                  if ((*statptr & 0xe0) == 0x00)
2750    0A8F  DD6EF6    		ld	l,(ix-10)
2751    0A92  DD66F7    		ld	h,(ix-9)
2752    0A95  7E        		ld	a,(hl)
2753    0A96  E6E0      		and	224
2754    0A98  201D      		jr	nz,L1121
2755                    	;  425                          {
2756                    	;  426                          /* If a read operation fails and the card cannot provide
2757                    	;  427                             the required data, it will send a data error token instead
2758                    	;  428                           */
2759                    	;  429                          printf("Read error: 0x%02x\n", *statptr);
2760    0A9A  DD6EF6    		ld	l,(ix-10)
2761    0A9D  DD66F7    		ld	h,(ix-9)
2762    0AA0  4E        		ld	c,(hl)
2763    0AA1  97        		sub	a
2764    0AA2  47        		ld	b,a
2765    0AA3  C5        		push	bc
2766    0AA4  213603    		ld	hl,L534
2767    0AA7  CD0000    		call	_printf
2768    0AAA  F1        		pop	af
2769                    	;  430                          spideselect();
2770    0AAB  CD0000    		call	_spideselect
2771                    	;  431                          ledoff();
2772    0AAE  CD0000    		call	_ledoff
2773                    	;  432                          return (NO);
2774    0AB1  010000    		ld	bc,0
2775    0AB4  C30000    		jp	c.rets
2776                    	L1121:
2777    0AB7  DD34F0    		inc	(ix-16)
2778    0ABA  2003      		jr	nz,L001
2779    0ABC  DD34F1    		inc	(ix-15)
2780                    	L001:
2781    0ABF  DD34F6    		inc	(ix-10)
2782    0AC2  2003      		jr	nz,L201
2783    0AC4  DD34F7    		inc	(ix-9)
2784                    	L201:
2785    0AC7  C3770A    		jp	L1711
2786                    	L1021:
2787                    	;  433                          }
2788                    	;  434                  }
2789                    	;  435          if (*statptr != 0xfe)
2790    0ACA  DD6EF6    		ld	l,(ix-10)
2791    0ACD  DD66F7    		ld	h,(ix-9)
2792    0AD0  7E        		ld	a,(hl)
2793    0AD1  FEFE      		cp	254
2794    0AD3  2812      		jr	z,L1421
2795                    	;  436                  {
2796                    	;  437                  printf("No data found\n");
2797    0AD5  214A03    		ld	hl,L544
2798    0AD8  CD0000    		call	_printf
2799                    	;  438                  spideselect();
2800    0ADB  CD0000    		call	_spideselect
2801                    	;  439                  ledoff();
2802    0ADE  CD0000    		call	_ledoff
2803                    	;  440                  return (NO);
2804    0AE1  010000    		ld	bc,0
2805    0AE4  C30000    		jp	c.rets
2806                    	L1421:
2807                    	;  441                  }
2808                    	;  442          else
2809                    	;  443                  {
2810                    	;  444                  dataptr = statptr + 1;
2811    0AE7  DD6EF6    		ld	l,(ix-10)
2812    0AEA  DD66F7    		ld	h,(ix-9)
2813    0AED  23        		inc	hl
2814    0AEE  223E12    		ld	(_dataptr),hl
2815                    	;  445                  rxdata = dataptr;
2816    0AF1  3A3E12    		ld	a,(_dataptr)
2817    0AF4  DD77F8    		ld	(ix-8),a
2818    0AF7  3A3F12    		ld	a,(_dataptr+1)
2819    0AFA  DD77F9    		ld	(ix-7),a
2820                    	;  446                  rxtxptr = dataptr;
2821    0AFD  2A3E12    		ld	hl,(_dataptr)
2822    0B00  223812    		ld	(_rxtxptr),hl
2823                    	;  447  
2824                    	;  448                  rxcrc16 = (rxdata[0x200] << 8) + rxdata[0x201];
2825    0B03  DD6EF8    		ld	l,(ix-8)
2826    0B06  DD66F9    		ld	h,(ix-7)
2827    0B09  010002    		ld	bc,512
2828    0B0C  09        		add	hl,bc
2829    0B0D  6E        		ld	l,(hl)
2830    0B0E  97        		sub	a
2831    0B0F  67        		ld	h,a
2832    0B10  29        		add	hl,hl
2833    0B11  29        		add	hl,hl
2834    0B12  29        		add	hl,hl
2835    0B13  29        		add	hl,hl
2836    0B14  29        		add	hl,hl
2837    0B15  29        		add	hl,hl
2838    0B16  29        		add	hl,hl
2839    0B17  29        		add	hl,hl
2840    0B18  E5        		push	hl
2841    0B19  DD6EF8    		ld	l,(ix-8)
2842    0B1C  DD66F9    		ld	h,(ix-7)
2843    0B1F  010102    		ld	bc,513
2844    0B22  09        		add	hl,bc
2845    0B23  6E        		ld	l,(hl)
2846    0B24  97        		sub	a
2847    0B25  67        		ld	h,a
2848    0B26  E3        		ex	(sp),hl
2849    0B27  C1        		pop	bc
2850    0B28  09        		add	hl,bc
2851    0B29  DD75EA    		ld	(ix-22),l
2852    0B2C  DD74EB    		ld	(ix-21),h
2853                    	;  449                  calcrc16 = CRC16_buf(rxdata, 512);
2854    0B2F  210002    		ld	hl,512
2855    0B32  E5        		push	hl
2856    0B33  DD6EF8    		ld	l,(ix-8)
2857    0B36  DD66F9    		ld	h,(ix-7)
2858    0B39  CD5F01    		call	_CRC16_buf
2859    0B3C  F1        		pop	af
2860    0B3D  DD71E8    		ld	(ix-24),c
2861    0B40  DD70E9    		ld	(ix-23),b
2862                    	;  450                  if (printit || (rxcrc16 != calcrc16))
2863    0B43  DD7E04    		ld	a,(ix+4)
2864    0B46  DDB605    		or	(ix+5)
2865    0B49  2010      		jr	nz,L1721
2866    0B4B  DD7EEA    		ld	a,(ix-22)
2867    0B4E  DDBEE8    		cp	(ix-24)
2868    0B51  2006      		jr	nz,L401
2869    0B53  DD7EEB    		ld	a,(ix-21)
2870    0B56  DDBEE9    		cp	(ix-23)
2871                    	L401:
2872    0B59  283A      		jr	z,L1521
2873                    	L1721:
2874                    	;  451                          {
2875                    	;  452                          printf("Data block %ld:\n", blockno);
2876    0B5B  213D12    		ld	hl,_blockno+3
2877    0B5E  46        		ld	b,(hl)
2878    0B5F  2B        		dec	hl
2879    0B60  4E        		ld	c,(hl)
2880    0B61  C5        		push	bc
2881    0B62  2B        		dec	hl
2882    0B63  46        		ld	b,(hl)
2883    0B64  2B        		dec	hl
2884    0B65  4E        		ld	c,(hl)
2885    0B66  C5        		push	bc
2886    0B67  215903    		ld	hl,L554
2887    0B6A  CD0000    		call	_printf
2888    0B6D  F1        		pop	af
2889    0B6E  F1        		pop	af
2890                    	;  453                          if (rxcrc16 != calcrc16)
2891    0B6F  DD7EEA    		ld	a,(ix-22)
2892    0B72  DDBEE8    		cp	(ix-24)
2893    0B75  2006      		jr	nz,L601
2894    0B77  DD7EEB    		ld	a,(ix-21)
2895    0B7A  DDBEE9    		cp	(ix-23)
2896                    	L601:
2897    0B7D  2816      		jr	z,L1521
2898                    	;  454                                  printf("  CRC error, recieved CRC16: 0x%04x, calc: 0x%04hi\n", rxcrc16, calcrc16);
2899    0B7F  DD6EE8    		ld	l,(ix-24)
2900    0B82  DD66E9    		ld	h,(ix-23)
2901    0B85  E5        		push	hl
2902    0B86  DD6EEA    		ld	l,(ix-22)
2903    0B89  DD66EB    		ld	h,(ix-21)
2904    0B8C  E5        		push	hl
2905    0B8D  216A03    		ld	hl,L564
2906    0B90  CD0000    		call	_printf
2907    0B93  F1        		pop	af
2908    0B94  F1        		pop	af
2909                    	L1521:
2910                    	;  455                          }
2911                    	;  456                  }
2912                    	;  457  
2913                    	;  458          spideselect();
2914    0B95  CD0000    		call	_spideselect
2915                    	;  459          ledoff();
2916    0B98  CD0000    		call	_ledoff
2917                    	;  460          return (YES);
2918    0B9B  010100    		ld	bc,1
2919    0B9E  C30000    		jp	c.rets
2920                    	;  461          }
2921                    	;  462  
2922                    	;  463  /* CMD24 is the write block command */
2923                    	;  464  unsigned char cmd24[] = {0xff, 0xff, 0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
2924                    		.psect	_data
2925                    	_cmd24:
2926    039E  FF        		.byte	255
2927    039F  FF        		.byte	255
2928    03A0  58        		.byte	88
2929                    		.byte	[1]
2930                    		.byte	[1]
2931                    		.byte	[1]
2932                    		.byte	[1]
2933    03A5  6F        		.byte	111
2934                    	L574:
2935    03A6  4E        		.byte	78
2936    03A7  6F        		.byte	111
2937    03A8  20        		.byte	32
2938    03A9  64        		.byte	100
2939    03AA  61        		.byte	97
2940    03AB  74        		.byte	116
2941    03AC  61        		.byte	97
2942    03AD  20        		.byte	32
2943    03AE  69        		.byte	105
2944    03AF  6E        		.byte	110
2945    03B0  20        		.byte	32
2946    03B1  62        		.byte	98
2947    03B2  75        		.byte	117
2948    03B3  66        		.byte	102
2949    03B4  66        		.byte	102
2950    03B5  65        		.byte	101
2951    03B6  72        		.byte	114
2952    03B7  20        		.byte	32
2953    03B8  74        		.byte	116
2954    03B9  6F        		.byte	111
2955    03BA  20        		.byte	32
2956    03BB  77        		.byte	119
2957    03BC  72        		.byte	114
2958    03BD  69        		.byte	105
2959    03BE  74        		.byte	116
2960    03BF  65        		.byte	101
2961    03C0  0A        		.byte	10
2962    03C1  00        		.byte	0
2963                    	L505:
2964    03C2  43        		.byte	67
2965    03C3  4D        		.byte	77
2966    03C4  44        		.byte	68
2967    03C5  32        		.byte	50
2968    03C6  34        		.byte	52
2969    03C7  20        		.byte	32
2970    03C8  52        		.byte	82
2971    03C9  31        		.byte	49
2972    03CA  20        		.byte	32
2973    03CB  72        		.byte	114
2974    03CC  65        		.byte	101
2975    03CD  73        		.byte	115
2976    03CE  70        		.byte	112
2977    03CF  6F        		.byte	111
2978    03D0  6E        		.byte	110
2979    03D1  73        		.byte	115
2980    03D2  65        		.byte	101
2981    03D3  20        		.byte	32
2982    03D4  5B        		.byte	91
2983    03D5  25        		.byte	37
2984    03D6  30        		.byte	48
2985    03D7  32        		.byte	50
2986    03D8  78        		.byte	120
2987    03D9  5D        		.byte	93
2988    03DA  0A        		.byte	10
2989    03DB  00        		.byte	0
2990                    	L515:
2991    03DC  44        		.byte	68
2992    03DD  61        		.byte	97
2993    03DE  74        		.byte	116
2994    03DF  61        		.byte	97
2995    03E0  20        		.byte	32
2996    03E1  62        		.byte	98
2997    03E2  6C        		.byte	108
2998    03E3  6F        		.byte	111
2999    03E4  63        		.byte	99
3000    03E5  6B        		.byte	107
3001    03E6  20        		.byte	32
3002    03E7  25        		.byte	37
3003    03E8  6C        		.byte	108
3004    03E9  75        		.byte	117
3005    03EA  3A        		.byte	58
3006    03EB  0A        		.byte	10
3007    03EC  00        		.byte	0
3008                    	L525:
3009    03ED  44        		.byte	68
3010    03EE  61        		.byte	97
3011    03EF  74        		.byte	116
3012    03F0  61        		.byte	97
3013    03F1  20        		.byte	32
3014    03F2  72        		.byte	114
3015    03F3  65        		.byte	101
3016    03F4  73        		.byte	115
3017    03F5  70        		.byte	112
3018    03F6  6F        		.byte	111
3019    03F7  6E        		.byte	110
3020    03F8  73        		.byte	115
3021    03F9  65        		.byte	101
3022    03FA  20        		.byte	32
3023    03FB  5B        		.byte	91
3024    03FC  25        		.byte	37
3025    03FD  30        		.byte	48
3026    03FE  32        		.byte	50
3027    03FF  78        		.byte	120
3028    0400  5D        		.byte	93
3029    0401  00        		.byte	0
3030                    	L535:
3031    0402  2C        		.byte	44
3032    0403  20        		.byte	32
3033    0404  64        		.byte	100
3034    0405  61        		.byte	97
3035    0406  74        		.byte	116
3036    0407  61        		.byte	97
3037    0408  20        		.byte	32
3038    0409  61        		.byte	97
3039    040A  63        		.byte	99
3040    040B  63        		.byte	99
3041    040C  65        		.byte	101
3042    040D  70        		.byte	112
3043    040E  74        		.byte	116
3044    040F  65        		.byte	101
3045    0410  64        		.byte	100
3046    0411  00        		.byte	0
3047                    	L545:
3048    0412  0A        		.byte	10
3049    0413  00        		.byte	0
3050                    		.psect	_text
3051                    	;  465  
3052                    	;  466  /* write data block */
3053                    	;  467  void sdwrite()
3054                    	;  468          {
3055                    	_sdwrite:
3056    0BA1  CD0000    		call	c.savs0
3057    0BA4  21ECFF    		ld	hl,65516
3058    0BA7  39        		add	hl,sp
3059    0BA8  F9        		ld	sp,hl
3060                    	;  469          unsigned char *txdata;
3061                    	;  470          unsigned char *statptr;
3062                    	;  471          int prtline;
3063                    	;  472          int txbytes;
3064                    	;  473          unsigned int crc16tx;
3065                    	;  474          unsigned long blktoread;
3066                    	;  475  
3067                    	;  476          ledon();
3068    0BA9  CD0000    		call	_ledon
3069                    	;  477          spiselect();
3070    0BAC  CD0000    		call	_spiselect
3071                    	;  478  
3072                    	;  479          if (!rxtxptr)
3073    0BAF  2A3812    		ld	hl,(_rxtxptr)
3074    0BB2  7C        		ld	a,h
3075    0BB3  B5        		or	l
3076    0BB4  200F      		jr	nz,L1131
3077                    	;  480                  {
3078                    	;  481                  printf("No data in buffer to write\n");
3079    0BB6  21A603    		ld	hl,L574
3080    0BB9  CD0000    		call	_printf
3081                    	;  482                  spideselect();
3082    0BBC  CD0000    		call	_spideselect
3083                    	;  483                  ledoff();
3084    0BBF  CD0000    		call	_ledoff
3085                    	;  484                  return;
3086    0BC2  C30000    		jp	c.rets0
3087                    	L1131:
3088                    	;  485                  }
3089                    	;  486  
3090                    	;  487          /* CMD24: WRITE_SINGLE_BLOCK */
3091                    	;  488          /* Insert block # into command */
3092                    	;  489          blktoread = blkmult * blockno;
3093    0BC5  DDE5      		push	ix
3094    0BC7  C1        		pop	bc
3095    0BC8  21ECFF    		ld	hl,65516
3096    0BCB  09        		add	hl,bc
3097    0BCC  E5        		push	hl
3098    0BCD  211700    		ld	hl,_blkmult
3099    0BD0  CD0000    		call	c.0mvf
3100    0BD3  210000    		ld	hl,c.r0
3101    0BD6  E5        		push	hl
3102    0BD7  213A12    		ld	hl,_blockno
3103    0BDA  E5        		push	hl
3104    0BDB  CD0000    		call	c.lmul
3105    0BDE  CD0000    		call	c.mvl
3106    0BE1  F1        		pop	af
3107                    	;  490          cmd24[6] = blktoread & 0xff;
3108    0BE2  DD6EEE    		ld	l,(ix-18)
3109    0BE5  7D        		ld	a,l
3110    0BE6  E6FF      		and	255
3111    0BE8  32A403    		ld	(_cmd24+6),a
3112                    	;  491          blktoread = blktoread >> 8;
3113    0BEB  DDE5      		push	ix
3114    0BED  C1        		pop	bc
3115    0BEE  21ECFF    		ld	hl,65516
3116    0BF1  09        		add	hl,bc
3117    0BF2  E5        		push	hl
3118    0BF3  210800    		ld	hl,8
3119    0BF6  E5        		push	hl
3120    0BF7  CD0000    		call	c.ulrsh
3121    0BFA  F1        		pop	af
3122                    	;  492          cmd24[5] = blktoread & 0xff;
3123    0BFB  DD6EEE    		ld	l,(ix-18)
3124    0BFE  7D        		ld	a,l
3125    0BFF  E6FF      		and	255
3126    0C01  32A303    		ld	(_cmd24+5),a
3127                    	;  493          blktoread = blktoread >> 8;
3128    0C04  DDE5      		push	ix
3129    0C06  C1        		pop	bc
3130    0C07  21ECFF    		ld	hl,65516
3131    0C0A  09        		add	hl,bc
3132    0C0B  E5        		push	hl
3133    0C0C  210800    		ld	hl,8
3134    0C0F  E5        		push	hl
3135    0C10  CD0000    		call	c.ulrsh
3136    0C13  F1        		pop	af
3137                    	;  494          cmd24[4] = blktoread & 0xff;
3138    0C14  DD6EEE    		ld	l,(ix-18)
3139    0C17  7D        		ld	a,l
3140    0C18  E6FF      		and	255
3141    0C1A  32A203    		ld	(_cmd24+4),a
3142                    	;  495          blktoread = blktoread >> 8;
3143    0C1D  DDE5      		push	ix
3144    0C1F  C1        		pop	bc
3145    0C20  21ECFF    		ld	hl,65516
3146    0C23  09        		add	hl,bc
3147    0C24  E5        		push	hl
3148    0C25  210800    		ld	hl,8
3149    0C28  E5        		push	hl
3150    0C29  CD0000    		call	c.ulrsh
3151    0C2C  F1        		pop	af
3152                    	;  496          cmd24[3] = blktoread & 0xff;
3153    0C2D  DD6EEE    		ld	l,(ix-18)
3154    0C30  7D        		ld	a,l
3155    0C31  E6FF      		and	255
3156    0C33  32A103    		ld	(_cmd24+3),a
3157                    	;  497          blktoread = blktoread >> 8;
3158    0C36  DDE5      		push	ix
3159    0C38  C1        		pop	bc
3160    0C39  21ECFF    		ld	hl,65516
3161    0C3C  09        		add	hl,bc
3162    0C3D  E5        		push	hl
3163    0C3E  210800    		ld	hl,8
3164    0C41  E5        		push	hl
3165    0C42  CD0000    		call	c.ulrsh
3166    0C45  F1        		pop	af
3167                    	;  498  
3168                    	;  499          cmd24[7] = CRC7_buf(&cmd24[2], 5) | 0x01;
3169    0C46  210500    		ld	hl,5
3170    0C49  E5        		push	hl
3171    0C4A  21A003    		ld	hl,_cmd24+2
3172    0C4D  CD6200    		call	_CRC7_buf
3173    0C50  F1        		pop	af
3174    0C51  CBC1      		set	0,c
3175    0C53  79        		ld	a,c
3176    0C54  32A503    		ld	(_cmd24+7),a
3177                    	;  500          statptr = sdcommand(cmd24, sizeof cmd24, statbuf, 8);
3178    0C57  210800    		ld	hl,8
3179    0C5A  E5        		push	hl
3180    0C5B  21F011    		ld	hl,_statbuf
3181    0C5E  E5        		push	hl
3182    0C5F  210800    		ld	hl,8
3183    0C62  E5        		push	hl
3184    0C63  219E03    		ld	hl,_cmd24
3185    0C66  CDB201    		call	_sdcommand
3186    0C69  F1        		pop	af
3187    0C6A  F1        		pop	af
3188    0C6B  F1        		pop	af
3189    0C6C  DD71F6    		ld	(ix-10),c
3190    0C6F  DD70F7    		ld	(ix-9),b
3191                    	;  501          printf("CMD24 R1 response [%02x]\n", statptr[0]);
3192    0C72  DD6EF6    		ld	l,(ix-10)
3193    0C75  DD66F7    		ld	h,(ix-9)
3194    0C78  4E        		ld	c,(hl)
3195    0C79  97        		sub	a
3196    0C7A  47        		ld	b,a
3197    0C7B  C5        		push	bc
3198    0C7C  21C203    		ld	hl,L505
3199    0C7F  CD0000    		call	_printf
3200    0C82  F1        		pop	af
3201                    	;  502          dataptr = rxtxptr;
3202    0C83  2A3812    		ld	hl,(_rxtxptr)
3203    0C86  223E12    		ld	(_dataptr),hl
3204                    	;  503          txdata = dataptr;
3205    0C89  3A3E12    		ld	a,(_dataptr)
3206    0C8C  DD77F8    		ld	(ix-8),a
3207    0C8F  3A3F12    		ld	a,(_dataptr+1)
3208    0C92  DD77F9    		ld	(ix-7),a
3209                    	;  504          printf("Data block %lu:\n", blockno);
3210    0C95  213D12    		ld	hl,_blockno+3
3211    0C98  46        		ld	b,(hl)
3212    0C99  2B        		dec	hl
3213    0C9A  4E        		ld	c,(hl)
3214    0C9B  C5        		push	bc
3215    0C9C  2B        		dec	hl
3216    0C9D  46        		ld	b,(hl)
3217    0C9E  2B        		dec	hl
3218    0C9F  4E        		ld	c,(hl)
3219    0CA0  C5        		push	bc
3220    0CA1  21DC03    		ld	hl,L515
3221    0CA4  CD0000    		call	_printf
3222    0CA7  F1        		pop	af
3223    0CA8  F1        		pop	af
3224                    	;  505          /* send data after adding start flag and CRC16 */
3225                    	;  506          crc16tx = CRC16_buf(txdata, 512);
3226    0CA9  210002    		ld	hl,512
3227    0CAC  E5        		push	hl
3228    0CAD  DD6EF8    		ld	l,(ix-8)
3229    0CB0  DD66F9    		ld	h,(ix-7)
3230    0CB3  CD5F01    		call	_CRC16_buf
3231    0CB6  F1        		pop	af
3232    0CB7  DD71F0    		ld	(ix-16),c
3233    0CBA  DD70F1    		ld	(ix-15),b
3234                    	;  507          txdata[-1] = 0xfe;
3235    0CBD  DD6EF8    		ld	l,(ix-8)
3236    0CC0  DD66F9    		ld	h,(ix-7)
3237    0CC3  01FFFF    		ld	bc,65535
3238    0CC6  09        		add	hl,bc
3239    0CC7  36FE      		ld	(hl),254
3240                    	;  508          txdata[0x200] = (crc16tx >>  8) & 0xff;
3241    0CC9  DD6EF8    		ld	l,(ix-8)
3242    0CCC  DD66F9    		ld	h,(ix-7)
3243    0CCF  010002    		ld	bc,512
3244    0CD2  09        		add	hl,bc
3245    0CD3  E5        		push	hl
3246    0CD4  DD6EF0    		ld	l,(ix-16)
3247    0CD7  DD66F1    		ld	h,(ix-15)
3248    0CDA  E5        		push	hl
3249    0CDB  210800    		ld	hl,8
3250    0CDE  E5        		push	hl
3251    0CDF  CD0000    		call	c.ursh
3252    0CE2  E1        		pop	hl
3253    0CE3  7D        		ld	a,l
3254    0CE4  E6FF      		and	255
3255    0CE6  6F        		ld	l,a
3256    0CE7  C1        		pop	bc
3257    0CE8  97        		sub	a
3258    0CE9  67        		ld	h,a
3259    0CEA  7D        		ld	a,l
3260    0CEB  02        		ld	(bc),a
3261                    	;  509          txdata[0x201] = crc16tx & 0xff;
3262    0CEC  DD6EF8    		ld	l,(ix-8)
3263    0CEF  DD66F9    		ld	h,(ix-7)
3264    0CF2  010102    		ld	bc,513
3265    0CF5  09        		add	hl,bc
3266    0CF6  DD4EF0    		ld	c,(ix-16)
3267    0CF9  79        		ld	a,c
3268    0CFA  E6FF      		and	255
3269    0CFC  4F        		ld	c,a
3270    0CFD  71        		ld	(hl),c
3271                    	;  510          sdcommand(txdata - 1, 512 + 3, statbuf, 8);
3272    0CFE  210800    		ld	hl,8
3273    0D01  E5        		push	hl
3274    0D02  21F011    		ld	hl,_statbuf
3275    0D05  E5        		push	hl
3276    0D06  210302    		ld	hl,515
3277    0D09  E5        		push	hl
3278    0D0A  DD6EF8    		ld	l,(ix-8)
3279    0D0D  DD66F9    		ld	h,(ix-7)
3280    0D10  01FFFF    		ld	bc,65535
3281    0D13  09        		add	hl,bc
3282    0D14  CDB201    		call	_sdcommand
3283    0D17  F1        		pop	af
3284    0D18  F1        		pop	af
3285    0D19  F1        		pop	af
3286                    	;  511          /* check data resp. */
3287                    	;  512          for (statptr = statbuf; (*statptr & 0x11) != 0x01; statptr++)
3288    0D1A  21F011    		ld	hl,_statbuf
3289    0D1D  DD75F6    		ld	(ix-10),l
3290    0D20  DD74F7    		ld	(ix-9),h
3291                    	L1231:
3292    0D23  DD6EF6    		ld	l,(ix-10)
3293    0D26  DD66F7    		ld	h,(ix-9)
3294    0D29  6E        		ld	l,(hl)
3295    0D2A  97        		sub	a
3296    0D2B  67        		ld	h,a
3297    0D2C  7D        		ld	a,l
3298    0D2D  E611      		and	17
3299    0D2F  6F        		ld	l,a
3300    0D30  97        		sub	a
3301    0D31  67        		ld	h,a
3302    0D32  7D        		ld	a,l
3303    0D33  FE01      		cp	1
3304    0D35  2003      		jr	nz,L211
3305    0D37  7C        		ld	a,h
3306    0D38  FE00      		cp	0
3307                    	L211:
3308    0D3A  280A      		jr	z,L1331
3309                    	L1431:
3310    0D3C  DD34F6    		inc	(ix-10)
3311    0D3F  2003      		jr	nz,L411
3312    0D41  DD34F7    		inc	(ix-9)
3313                    	L411:
3314    0D44  18DD      		jr	L1231
3315                    	L1331:
3316                    	;  513                  ;
3317                    	;  514          printf("Data response [%02x]", 0x1f & statptr[0]);
3318    0D46  DD6EF6    		ld	l,(ix-10)
3319    0D49  DD66F7    		ld	h,(ix-9)
3320    0D4C  6E        		ld	l,(hl)
3321    0D4D  97        		sub	a
3322    0D4E  67        		ld	h,a
3323    0D4F  7D        		ld	a,l
3324    0D50  E61F      		and	31
3325    0D52  6F        		ld	l,a
3326    0D53  97        		sub	a
3327    0D54  67        		ld	h,a
3328    0D55  E5        		push	hl
3329    0D56  21ED03    		ld	hl,L525
3330    0D59  CD0000    		call	_printf
3331    0D5C  F1        		pop	af
3332                    	;  515          if ((0x1f & statptr[0]) == 0x05)
3333    0D5D  DD6EF6    		ld	l,(ix-10)
3334    0D60  DD66F7    		ld	h,(ix-9)
3335    0D63  6E        		ld	l,(hl)
3336    0D64  97        		sub	a
3337    0D65  67        		ld	h,a
3338    0D66  7D        		ld	a,l
3339    0D67  E61F      		and	31
3340    0D69  6F        		ld	l,a
3341    0D6A  97        		sub	a
3342    0D6B  67        		ld	h,a
3343    0D6C  7D        		ld	a,l
3344    0D6D  FE05      		cp	5
3345    0D6F  2003      		jr	nz,L611
3346    0D71  7C        		ld	a,h
3347    0D72  FE00      		cp	0
3348                    	L611:
3349    0D74  2006      		jr	nz,L1631
3350                    	;  516                  printf(", data accepted");
3351    0D76  210204    		ld	hl,L535
3352    0D79  CD0000    		call	_printf
3353                    	L1631:
3354                    	;  517          printf("\n");
3355    0D7C  211204    		ld	hl,L545
3356    0D7F  CD0000    		call	_printf
3357                    	;  518          spideselect();
3358    0D82  CD0000    		call	_spideselect
3359                    	;  519          ledoff();
3360    0D85  CD0000    		call	_ledoff
3361                    	;  520          }
3362    0D88  C30000    		jp	c.rets0
3363                    		.psect	_data
3364                    	L555:
3365    0414  4E        		.byte	78
3366    0415  6F        		.byte	111
3367    0416  20        		.byte	32
3368    0417  64        		.byte	100
3369    0418  61        		.byte	97
3370    0419  74        		.byte	116
3371    041A  61        		.byte	97
3372    041B  20        		.byte	32
3373    041C  72        		.byte	114
3374    041D  65        		.byte	101
3375    041E  61        		.byte	97
3376    041F  64        		.byte	100
3377    0420  20        		.byte	32
3378    0421  69        		.byte	105
3379    0422  6E        		.byte	110
3380    0423  74        		.byte	116
3381    0424  6F        		.byte	111
3382    0425  20        		.byte	32
3383    0426  62        		.byte	98
3384    0427  75        		.byte	117
3385    0428  66        		.byte	102
3386    0429  66        		.byte	102
3387    042A  65        		.byte	101
3388    042B  72        		.byte	114
3389    042C  0A        		.byte	10
3390    042D  00        		.byte	0
3391                    	L565:
3392    042E  44        		.byte	68
3393    042F  61        		.byte	97
3394    0430  74        		.byte	116
3395    0431  61        		.byte	97
3396    0432  20        		.byte	32
3397    0433  62        		.byte	98
3398    0434  6C        		.byte	108
3399    0435  6F        		.byte	111
3400    0436  63        		.byte	99
3401    0437  6B        		.byte	107
3402    0438  20        		.byte	32
3403    0439  25        		.byte	37
3404    043A  6C        		.byte	108
3405    043B  75        		.byte	117
3406    043C  3A        		.byte	58
3407    043D  0A        		.byte	10
3408    043E  00        		.byte	0
3409                    	L575:
3410    043F  2A        		.byte	42
3411    0440  0A        		.byte	10
3412    0441  00        		.byte	0
3413                    	L506:
3414    0442  25        		.byte	37
3415    0443  30        		.byte	48
3416    0444  34        		.byte	52
3417    0445  78        		.byte	120
3418    0446  20        		.byte	32
3419    0447  00        		.byte	0
3420                    	L516:
3421    0448  25        		.byte	37
3422    0449  30        		.byte	48
3423    044A  32        		.byte	50
3424    044B  78        		.byte	120
3425    044C  20        		.byte	32
3426    044D  00        		.byte	0
3427                    	L526:
3428    044E  20        		.byte	32
3429    044F  7C        		.byte	124
3430    0450  00        		.byte	0
3431                    	L536:
3432    0451  7C        		.byte	124
3433    0452  0A        		.byte	10
3434    0453  00        		.byte	0
3435                    		.psect	_text
3436                    	;  521  
3437                    	;  522  /* print the SD data buffer */
3438                    	;  523  void sddatprt()
3439                    	;  524          {
3440                    	_sddatprt:
3441    0D8B  CD0000    		call	c.savs0
3442    0D8E  21EAFF    		ld	hl,65514
3443    0D91  39        		add	hl,sp
3444    0D92  F9        		ld	sp,hl
3445                    	;  525          unsigned char *rxdata;
3446                    	;  526          unsigned char *statptr;
3447                    	;  527          int dmpline;
3448                    	;  528          int rxbytes;
3449                    	;  529          int tries;
3450                    	;  530          int allzero, lastallz, dotprted;
3451                    	;  531  
3452                    	;  532          if (!rxtxptr)
3453    0D93  2A3812    		ld	hl,(_rxtxptr)
3454    0D96  7C        		ld	a,h
3455    0D97  B5        		or	l
3456    0D98  2009      		jr	nz,L1731
3457                    	;  533                  {
3458                    	;  534                  printf("No data read into buffer\n");
3459    0D9A  211404    		ld	hl,L555
3460    0D9D  CD0000    		call	_printf
3461                    	;  535                  return;
3462    0DA0  C30000    		jp	c.rets0
3463                    	L1731:
3464                    	;  536                  }
3465                    	;  537          dataptr = rxtxptr;
3466    0DA3  2A3812    		ld	hl,(_rxtxptr)
3467    0DA6  223E12    		ld	(_dataptr),hl
3468                    	;  538          rxdata = dataptr;
3469    0DA9  3A3E12    		ld	a,(_dataptr)
3470    0DAC  DD77F8    		ld	(ix-8),a
3471    0DAF  3A3F12    		ld	a,(_dataptr+1)
3472    0DB2  DD77F9    		ld	(ix-7),a
3473                    	;  539          printf("Data block %lu:\n", blockno);
3474    0DB5  213D12    		ld	hl,_blockno+3
3475    0DB8  46        		ld	b,(hl)
3476    0DB9  2B        		dec	hl
3477    0DBA  4E        		ld	c,(hl)
3478    0DBB  C5        		push	bc
3479    0DBC  2B        		dec	hl
3480    0DBD  46        		ld	b,(hl)
3481    0DBE  2B        		dec	hl
3482    0DBF  4E        		ld	c,(hl)
3483    0DC0  C5        		push	bc
3484    0DC1  212E04    		ld	hl,L565
3485    0DC4  CD0000    		call	_printf
3486    0DC7  F1        		pop	af
3487    0DC8  F1        		pop	af
3488                    	;  540          dotprted = NO;
3489    0DC9  DD36EA00  		ld	(ix-22),0
3490    0DCD  DD36EB00  		ld	(ix-21),0
3491                    	;  541          lastallz = NO;
3492    0DD1  DD36EC00  		ld	(ix-20),0
3493    0DD5  DD36ED00  		ld	(ix-19),0
3494                    	;  542          for (dmpline = 0; dmpline < 32; dmpline++)
3495    0DD9  DD36F400  		ld	(ix-12),0
3496    0DDD  DD36F500  		ld	(ix-11),0
3497                    	L1041:
3498    0DE1  DD7EF4    		ld	a,(ix-12)
3499    0DE4  D620      		sub	32
3500    0DE6  DD7EF5    		ld	a,(ix-11)
3501    0DE9  DE00      		sbc	a,0
3502    0DEB  F22D0F    		jp	p,L1141
3503                    	;  543                  {
3504                    	;  544                  /* test if all 16 bytes are 0x00 */
3505                    	;  545                  allzero = YES;
3506    0DEE  DD36EE01  		ld	(ix-18),1
3507    0DF2  DD36EF00  		ld	(ix-17),0
3508                    	;  546                  for (rxbytes = 0; rxbytes < 16; rxbytes++)
3509    0DF6  DD36F200  		ld	(ix-14),0
3510    0DFA  DD36F300  		ld	(ix-13),0
3511                    	L1441:
3512    0DFE  DD7EF2    		ld	a,(ix-14)
3513    0E01  D610      		sub	16
3514    0E03  DD7EF3    		ld	a,(ix-13)
3515    0E06  DE00      		sbc	a,0
3516    0E08  F22B0E    		jp	p,L1541
3517                    	;  547                          {
3518                    	;  548                          if (dataptr[rxbytes] != 0)
3519    0E0B  2A3E12    		ld	hl,(_dataptr)
3520    0E0E  DD4EF2    		ld	c,(ix-14)
3521    0E11  DD46F3    		ld	b,(ix-13)
3522    0E14  09        		add	hl,bc
3523    0E15  7E        		ld	a,(hl)
3524    0E16  B7        		or	a
3525    0E17  2808      		jr	z,L1641
3526                    	;  549                                  allzero = NO;
3527    0E19  DD36EE00  		ld	(ix-18),0
3528    0E1D  DD36EF00  		ld	(ix-17),0
3529                    	L1641:
3530    0E21  DD34F2    		inc	(ix-14)
3531    0E24  2003      		jr	nz,L421
3532    0E26  DD34F3    		inc	(ix-13)
3533                    	L421:
3534    0E29  18D3      		jr	L1441
3535                    	L1541:
3536                    	;  550                          }
3537                    	;  551                  if (lastallz && allzero)
3538    0E2B  DD7EEC    		ld	a,(ix-20)
3539    0E2E  DDB6ED    		or	(ix-19)
3540    0E31  2822      		jr	z,L1151
3541    0E33  DD7EEE    		ld	a,(ix-18)
3542    0E36  DDB6EF    		or	(ix-17)
3543    0E39  281A      		jr	z,L1151
3544                    	;  552                          {
3545                    	;  553                          if (!dotprted)
3546    0E3B  DD7EEA    		ld	a,(ix-22)
3547    0E3E  DDB6EB    		or	(ix-21)
3548    0E41  C2080F    		jp	nz,L1351
3549                    	;  554                                  {
3550                    	;  555                                  printf("*\n");
3551    0E44  213F04    		ld	hl,L575
3552    0E47  CD0000    		call	_printf
3553                    	;  556                                  dotprted = YES;
3554    0E4A  DD36EA01  		ld	(ix-22),1
3555    0E4E  DD36EB00  		ld	(ix-21),0
3556    0E52  C3080F    		jp	L1351
3557                    	L1151:
3558                    	;  557                                  }
3559                    	;  558                          }
3560                    	;  559                  else
3561                    	;  560                          {
3562                    	;  561                          dotprted = NO;
3563    0E55  DD36EA00  		ld	(ix-22),0
3564    0E59  DD36EB00  		ld	(ix-21),0
3565                    	;  562                          /* print offset */
3566                    	;  563                          printf("%04x ", dmpline * 16);
3567    0E5D  DD6EF4    		ld	l,(ix-12)
3568    0E60  DD66F5    		ld	h,(ix-11)
3569    0E63  E5        		push	hl
3570    0E64  211000    		ld	hl,16
3571    0E67  E5        		push	hl
3572    0E68  CD0000    		call	c.imul
3573    0E6B  214204    		ld	hl,L506
3574    0E6E  CD0000    		call	_printf
3575    0E71  F1        		pop	af
3576                    	;  564                          /* print 16 bytes in hex */
3577                    	;  565                          for (rxbytes = 0; rxbytes < 16; rxbytes++)
3578    0E72  DD36F200  		ld	(ix-14),0
3579    0E76  DD36F300  		ld	(ix-13),0
3580                    	L1451:
3581    0E7A  DD7EF2    		ld	a,(ix-14)
3582    0E7D  D610      		sub	16
3583    0E7F  DD7EF3    		ld	a,(ix-13)
3584    0E82  DE00      		sbc	a,0
3585    0E84  F2A60E    		jp	p,L1551
3586                    	;  566                                  printf("%02x ", dataptr[rxbytes]);
3587    0E87  2A3E12    		ld	hl,(_dataptr)
3588    0E8A  DD4EF2    		ld	c,(ix-14)
3589    0E8D  DD46F3    		ld	b,(ix-13)
3590    0E90  09        		add	hl,bc
3591    0E91  4E        		ld	c,(hl)
3592    0E92  97        		sub	a
3593    0E93  47        		ld	b,a
3594    0E94  C5        		push	bc
3595    0E95  214804    		ld	hl,L516
3596    0E98  CD0000    		call	_printf
3597    0E9B  F1        		pop	af
3598    0E9C  DD34F2    		inc	(ix-14)
3599    0E9F  2003      		jr	nz,L621
3600    0EA1  DD34F3    		inc	(ix-13)
3601                    	L621:
3602    0EA4  18D4      		jr	L1451
3603                    	L1551:
3604                    	;  567                          /* print these bytes in ASCII if printable */
3605                    	;  568                          printf(" |");
3606    0EA6  214E04    		ld	hl,L526
3607    0EA9  CD0000    		call	_printf
3608                    	;  569                          for (rxbytes = 0; rxbytes < 16; rxbytes++)
3609    0EAC  DD36F200  		ld	(ix-14),0
3610    0EB0  DD36F300  		ld	(ix-13),0
3611                    	L1061:
3612    0EB4  DD7EF2    		ld	a,(ix-14)
3613    0EB7  D610      		sub	16
3614    0EB9  DD7EF3    		ld	a,(ix-13)
3615    0EBC  DE00      		sbc	a,0
3616    0EBE  F2020F    		jp	p,L1161
3617                    	;  570                                  {
3618                    	;  571                                  if ((' ' <= dataptr[rxbytes]) && (dataptr[rxbytes] < 127))
3619    0EC1  2A3E12    		ld	hl,(_dataptr)
3620    0EC4  DD4EF2    		ld	c,(ix-14)
3621    0EC7  DD46F3    		ld	b,(ix-13)
3622    0ECA  09        		add	hl,bc
3623    0ECB  7E        		ld	a,(hl)
3624    0ECC  FE20      		cp	32
3625    0ECE  3821      		jr	c,L1461
3626    0ED0  2A3E12    		ld	hl,(_dataptr)
3627    0ED3  DD4EF2    		ld	c,(ix-14)
3628    0ED6  DD46F3    		ld	b,(ix-13)
3629    0ED9  09        		add	hl,bc
3630    0EDA  7E        		ld	a,(hl)
3631    0EDB  FE7F      		cp	127
3632    0EDD  3012      		jr	nc,L1461
3633                    	;  572                                          putchar(dataptr[rxbytes]);
3634    0EDF  2A3E12    		ld	hl,(_dataptr)
3635    0EE2  DD4EF2    		ld	c,(ix-14)
3636    0EE5  DD46F3    		ld	b,(ix-13)
3637    0EE8  09        		add	hl,bc
3638    0EE9  6E        		ld	l,(hl)
3639    0EEA  97        		sub	a
3640    0EEB  67        		ld	h,a
3641    0EEC  CD0000    		call	_putchar
3642                    	;  573                                  else
3643    0EEF  1806      		jr	L1261
3644                    	L1461:
3645                    	;  574                                          putchar('.');
3646    0EF1  212E00    		ld	hl,46
3647    0EF4  CD0000    		call	_putchar
3648                    	L1261:
3649    0EF7  DD34F2    		inc	(ix-14)
3650    0EFA  2003      		jr	nz,L031
3651    0EFC  DD34F3    		inc	(ix-13)
3652                    	L031:
3653    0EFF  C3B40E    		jp	L1061
3654                    	L1161:
3655                    	;  575                                  }
3656                    	;  576                          printf("|\n");
3657    0F02  215104    		ld	hl,L536
3658    0F05  CD0000    		call	_printf
3659                    	L1351:
3660                    	;  577                                  }
3661                    	;  578                  dataptr += 16;
3662    0F08  2A3E12    		ld	hl,(_dataptr)
3663    0F0B  7D        		ld	a,l
3664    0F0C  C610      		add	a,16
3665    0F0E  6F        		ld	l,a
3666    0F0F  7C        		ld	a,h
3667    0F10  CE00      		adc	a,0
3668    0F12  67        		ld	h,a
3669    0F13  223E12    		ld	(_dataptr),hl
3670                    	;  579                  lastallz = allzero;
3671    0F16  DD7EEE    		ld	a,(ix-18)
3672    0F19  DD77EC    		ld	(ix-20),a
3673    0F1C  DD7EEF    		ld	a,(ix-17)
3674    0F1F  DD77ED    		ld	(ix-19),a
3675                    	;  580                  }
3676    0F22  DD34F4    		inc	(ix-12)
3677    0F25  2003      		jr	nz,L221
3678    0F27  DD34F5    		inc	(ix-11)
3679                    	L221:
3680    0F2A  C3E10D    		jp	L1041
3681                    	L1141:
3682                    	;  581          }
3683    0F2D  C30000    		jp	c.rets0
3684                    		.psect	_data
3685                    	L546:
3686    0454  4F        		.byte	79
3687    0455  43        		.byte	67
3688    0456  52        		.byte	82
3689    0457  20        		.byte	32
3690    0458  72        		.byte	114
3691    0459  65        		.byte	101
3692    045A  67        		.byte	103
3693    045B  69        		.byte	105
3694    045C  73        		.byte	115
3695    045D  74        		.byte	116
3696    045E  65        		.byte	101
3697    045F  72        		.byte	114
3698    0460  3A        		.byte	58
3699    0461  0A        		.byte	10
3700    0462  00        		.byte	0
3701                    	L556:
3702    0463  32        		.byte	50
3703    0464  2E        		.byte	46
3704    0465  37        		.byte	55
3705    0466  2D        		.byte	45
3706    0467  32        		.byte	50
3707    0468  2E        		.byte	46
3708    0469  38        		.byte	56
3709    046A  56        		.byte	86
3710    046B  20        		.byte	32
3711    046C  28        		.byte	40
3712    046D  62        		.byte	98
3713    046E  69        		.byte	105
3714    046F  74        		.byte	116
3715    0470  20        		.byte	32
3716    0471  31        		.byte	49
3717    0472  35        		.byte	53
3718    0473  29        		.byte	41
3719    0474  20        		.byte	32
3720    0475  00        		.byte	0
3721                    	L566:
3722    0476  32        		.byte	50
3723    0477  2E        		.byte	46
3724    0478  38        		.byte	56
3725    0479  2D        		.byte	45
3726    047A  32        		.byte	50
3727    047B  2E        		.byte	46
3728    047C  39        		.byte	57
3729    047D  56        		.byte	86
3730    047E  20        		.byte	32
3731    047F  28        		.byte	40
3732    0480  62        		.byte	98
3733    0481  69        		.byte	105
3734    0482  74        		.byte	116
3735    0483  20        		.byte	32
3736    0484  31        		.byte	49
3737    0485  36        		.byte	54
3738    0486  29        		.byte	41
3739    0487  20        		.byte	32
3740    0488  00        		.byte	0
3741                    	L576:
3742    0489  32        		.byte	50
3743    048A  2E        		.byte	46
3744    048B  39        		.byte	57
3745    048C  2D        		.byte	45
3746    048D  33        		.byte	51
3747    048E  2E        		.byte	46
3748    048F  30        		.byte	48
3749    0490  56        		.byte	86
3750    0491  20        		.byte	32
3751    0492  28        		.byte	40
3752    0493  62        		.byte	98
3753    0494  69        		.byte	105
3754    0495  74        		.byte	116
3755    0496  20        		.byte	32
3756    0497  31        		.byte	49
3757    0498  37        		.byte	55
3758    0499  29        		.byte	41
3759    049A  20        		.byte	32
3760    049B  00        		.byte	0
3761                    	L507:
3762    049C  33        		.byte	51
3763    049D  2E        		.byte	46
3764    049E  30        		.byte	48
3765    049F  2D        		.byte	45
3766    04A0  33        		.byte	51
3767    04A1  2E        		.byte	46
3768    04A2  31        		.byte	49
3769    04A3  56        		.byte	86
3770    04A4  20        		.byte	32
3771    04A5  28        		.byte	40
3772    04A6  62        		.byte	98
3773    04A7  69        		.byte	105
3774    04A8  74        		.byte	116
3775    04A9  20        		.byte	32
3776    04AA  31        		.byte	49
3777    04AB  38        		.byte	56
3778    04AC  29        		.byte	41
3779    04AD  20        		.byte	32
3780    04AE  0A        		.byte	10
3781    04AF  00        		.byte	0
3782                    	L517:
3783    04B0  33        		.byte	51
3784    04B1  2E        		.byte	46
3785    04B2  31        		.byte	49
3786    04B3  2D        		.byte	45
3787    04B4  33        		.byte	51
3788    04B5  2E        		.byte	46
3789    04B6  32        		.byte	50
3790    04B7  56        		.byte	86
3791    04B8  20        		.byte	32
3792    04B9  28        		.byte	40
3793    04BA  62        		.byte	98
3794    04BB  69        		.byte	105
3795    04BC  74        		.byte	116
3796    04BD  20        		.byte	32
3797    04BE  31        		.byte	49
3798    04BF  39        		.byte	57
3799    04C0  29        		.byte	41
3800    04C1  20        		.byte	32
3801    04C2  00        		.byte	0
3802                    	L527:
3803    04C3  33        		.byte	51
3804    04C4  2E        		.byte	46
3805    04C5  32        		.byte	50
3806    04C6  2D        		.byte	45
3807    04C7  33        		.byte	51
3808    04C8  2E        		.byte	46
3809    04C9  33        		.byte	51
3810    04CA  56        		.byte	86
3811    04CB  20        		.byte	32
3812    04CC  28        		.byte	40
3813    04CD  62        		.byte	98
3814    04CE  69        		.byte	105
3815    04CF  74        		.byte	116
3816    04D0  20        		.byte	32
3817    04D1  32        		.byte	50
3818    04D2  30        		.byte	48
3819    04D3  29        		.byte	41
3820    04D4  20        		.byte	32
3821    04D5  00        		.byte	0
3822                    	L537:
3823    04D6  33        		.byte	51
3824    04D7  2E        		.byte	46
3825    04D8  33        		.byte	51
3826    04D9  2D        		.byte	45
3827    04DA  33        		.byte	51
3828    04DB  2E        		.byte	46
3829    04DC  34        		.byte	52
3830    04DD  56        		.byte	86
3831    04DE  20        		.byte	32
3832    04DF  28        		.byte	40
3833    04E0  62        		.byte	98
3834    04E1  69        		.byte	105
3835    04E2  74        		.byte	116
3836    04E3  20        		.byte	32
3837    04E4  32        		.byte	50
3838    04E5  31        		.byte	49
3839    04E6  29        		.byte	41
3840    04E7  20        		.byte	32
3841    04E8  00        		.byte	0
3842                    	L547:
3843    04E9  33        		.byte	51
3844    04EA  2E        		.byte	46
3845    04EB  34        		.byte	52
3846    04EC  2D        		.byte	45
3847    04ED  33        		.byte	51
3848    04EE  2E        		.byte	46
3849    04EF  35        		.byte	53
3850    04F0  56        		.byte	86
3851    04F1  20        		.byte	32
3852    04F2  28        		.byte	40
3853    04F3  62        		.byte	98
3854    04F4  69        		.byte	105
3855    04F5  74        		.byte	116
3856    04F6  20        		.byte	32
3857    04F7  32        		.byte	50
3858    04F8  32        		.byte	50
3859    04F9  29        		.byte	41
3860    04FA  20        		.byte	32
3861    04FB  0A        		.byte	10
3862    04FC  00        		.byte	0
3863                    	L557:
3864    04FD  33        		.byte	51
3865    04FE  2E        		.byte	46
3866    04FF  35        		.byte	53
3867    0500  2D        		.byte	45
3868    0501  33        		.byte	51
3869    0502  2E        		.byte	46
3870    0503  36        		.byte	54
3871    0504  56        		.byte	86
3872    0505  20        		.byte	32
3873    0506  28        		.byte	40
3874    0507  62        		.byte	98
3875    0508  69        		.byte	105
3876    0509  74        		.byte	116
3877    050A  20        		.byte	32
3878    050B  32        		.byte	50
3879    050C  33        		.byte	51
3880    050D  29        		.byte	41
3881    050E  20        		.byte	32
3882    050F  0A        		.byte	10
3883    0510  00        		.byte	0
3884                    	L567:
3885    0511  53        		.byte	83
3886    0512  77        		.byte	119
3887    0513  69        		.byte	105
3888    0514  74        		.byte	116
3889    0515  63        		.byte	99
3890    0516  68        		.byte	104
3891    0517  69        		.byte	105
3892    0518  6E        		.byte	110
3893    0519  67        		.byte	103
3894    051A  20        		.byte	32
3895    051B  74        		.byte	116
3896    051C  6F        		.byte	111
3897    051D  20        		.byte	32
3898    051E  31        		.byte	49
3899    051F  2E        		.byte	46
3900    0520  38        		.byte	56
3901    0521  56        		.byte	86
3902    0522  20        		.byte	32
3903    0523  41        		.byte	65
3904    0524  63        		.byte	99
3905    0525  63        		.byte	99
3906    0526  65        		.byte	101
3907    0527  70        		.byte	112
3908    0528  74        		.byte	116
3909    0529  65        		.byte	101
3910    052A  64        		.byte	100
3911    052B  20        		.byte	32
3912    052C  28        		.byte	40
3913    052D  53        		.byte	83
3914    052E  31        		.byte	49
3915    052F  38        		.byte	56
3916    0530  41        		.byte	65
3917    0531  29        		.byte	41
3918    0532  20        		.byte	32
3919    0533  28        		.byte	40
3920    0534  62        		.byte	98
3921    0535  69        		.byte	105
3922    0536  74        		.byte	116
3923    0537  20        		.byte	32
3924    0538  32        		.byte	50
3925    0539  34        		.byte	52
3926    053A  29        		.byte	41
3927    053B  20        		.byte	32
3928    053C  73        		.byte	115
3929    053D  65        		.byte	101
3930    053E  74        		.byte	116
3931    053F  20        		.byte	32
3932    0540  00        		.byte	0
3933                    	L577:
3934    0541  4F        		.byte	79
3935    0542  76        		.byte	118
3936    0543  65        		.byte	101
3937    0544  72        		.byte	114
3938    0545  20        		.byte	32
3939    0546  32        		.byte	50
3940    0547  54        		.byte	84
3941    0548  42        		.byte	66
3942    0549  20        		.byte	32
3943    054A  73        		.byte	115
3944    054B  75        		.byte	117
3945    054C  70        		.byte	112
3946    054D  70        		.byte	112
3947    054E  6F        		.byte	111
3948    054F  72        		.byte	114
3949    0550  74        		.byte	116
3950    0551  20        		.byte	32
3951    0552  53        		.byte	83
3952    0553  74        		.byte	116
3953    0554  61        		.byte	97
3954    0555  74        		.byte	116
3955    0556  75        		.byte	117
3956    0557  73        		.byte	115
3957    0558  20        		.byte	32
3958    0559  28        		.byte	40
3959    055A  43        		.byte	67
3960    055B  4F        		.byte	79
3961    055C  32        		.byte	50
3962    055D  54        		.byte	84
3963    055E  29        		.byte	41
3964    055F  20        		.byte	32
3965    0560  28        		.byte	40
3966    0561  62        		.byte	98
3967    0562  69        		.byte	105
3968    0563  74        		.byte	116
3969    0564  20        		.byte	32
3970    0565  32        		.byte	50
3971    0566  37        		.byte	55
3972    0567  29        		.byte	41
3973    0568  20        		.byte	32
3974    0569  73        		.byte	115
3975    056A  65        		.byte	101
3976    056B  74        		.byte	116
3977    056C  0A        		.byte	10
3978    056D  00        		.byte	0
3979                    	L5001:
3980    056E  55        		.byte	85
3981    056F  48        		.byte	72
3982    0570  53        		.byte	83
3983    0571  2D        		.byte	45
3984    0572  49        		.byte	73
3985    0573  49        		.byte	73
3986    0574  20        		.byte	32
3987    0575  43        		.byte	67
3988    0576  61        		.byte	97
3989    0577  72        		.byte	114
3990    0578  64        		.byte	100
3991    0579  20        		.byte	32
3992    057A  53        		.byte	83
3993    057B  74        		.byte	116
3994    057C  61        		.byte	97
3995    057D  74        		.byte	116
3996    057E  75        		.byte	117
3997    057F  73        		.byte	115
3998    0580  20        		.byte	32
3999    0581  28        		.byte	40
4000    0582  62        		.byte	98
4001    0583  69        		.byte	105
4002    0584  74        		.byte	116
4003    0585  20        		.byte	32
4004    0586  32        		.byte	50
4005    0587  39        		.byte	57
4006    0588  29        		.byte	41
4007    0589  20        		.byte	32
4008    058A  73        		.byte	115
4009    058B  65        		.byte	101
4010    058C  74        		.byte	116
4011    058D  20        		.byte	32
4012    058E  00        		.byte	0
4013                    	L5101:
4014    058F  43        		.byte	67
4015    0590  61        		.byte	97
4016    0591  72        		.byte	114
4017    0592  64        		.byte	100
4018    0593  20        		.byte	32
4019    0594  43        		.byte	67
4020    0595  61        		.byte	97
4021    0596  70        		.byte	112
4022    0597  61        		.byte	97
4023    0598  63        		.byte	99
4024    0599  69        		.byte	105
4025    059A  74        		.byte	116
4026    059B  79        		.byte	121
4027    059C  20        		.byte	32
4028    059D  53        		.byte	83
4029    059E  74        		.byte	116
4030    059F  61        		.byte	97
4031    05A0  74        		.byte	116
4032    05A1  75        		.byte	117
4033    05A2  73        		.byte	115
4034    05A3  20        		.byte	32
4035    05A4  28        		.byte	40
4036    05A5  43        		.byte	67
4037    05A6  43        		.byte	67
4038    05A7  53        		.byte	83
4039    05A8  29        		.byte	41
4040    05A9  20        		.byte	32
4041    05AA  28        		.byte	40
4042    05AB  62        		.byte	98
4043    05AC  69        		.byte	105
4044    05AD  74        		.byte	116
4045    05AE  20        		.byte	32
4046    05AF  33        		.byte	51
4047    05B0  30        		.byte	48
4048    05B1  29        		.byte	41
4049    05B2  20        		.byte	32
4050    05B3  73        		.byte	115
4051    05B4  65        		.byte	101
4052    05B5  74        		.byte	116
4053    05B6  0A        		.byte	10
4054    05B7  00        		.byte	0
4055                    	L5201:
4056    05B8  20        		.byte	32
4057    05B9  20        		.byte	32
4058    05BA  53        		.byte	83
4059    05BB  44        		.byte	68
4060    05BC  20        		.byte	32
4061    05BD  56        		.byte	86
4062    05BE  65        		.byte	101
4063    05BF  72        		.byte	114
4064    05C0  2E        		.byte	46
4065    05C1  32        		.byte	50
4066    05C2  2B        		.byte	43
4067    05C3  2C        		.byte	44
4068    05C4  20        		.byte	32
4069    05C5  42        		.byte	66
4070    05C6  6C        		.byte	108
4071    05C7  6F        		.byte	111
4072    05C8  63        		.byte	99
4073    05C9  6B        		.byte	107
4074    05CA  20        		.byte	32
4075    05CB  61        		.byte	97
4076    05CC  64        		.byte	100
4077    05CD  64        		.byte	100
4078    05CE  72        		.byte	114
4079    05CF  65        		.byte	101
4080    05D0  73        		.byte	115
4081    05D1  73        		.byte	115
4082    05D2  00        		.byte	0
4083                    	L5301:
4084    05D3  43        		.byte	67
4085    05D4  61        		.byte	97
4086    05D5  72        		.byte	114
4087    05D6  64        		.byte	100
4088    05D7  20        		.byte	32
4089    05D8  43        		.byte	67
4090    05D9  61        		.byte	97
4091    05DA  70        		.byte	112
4092    05DB  61        		.byte	97
4093    05DC  63        		.byte	99
4094    05DD  69        		.byte	105
4095    05DE  74        		.byte	116
   0    05DF  79        		.byte	121
   1    05E0  20        		.byte	32
   2    05E1  53        		.byte	83
   3    05E2  74        		.byte	116
   4    05E3  61        		.byte	97
   5    05E4  74        		.byte	116
   6    05E5  75        		.byte	117
   7    05E6  73        		.byte	115
   8    05E7  20        		.byte	32
   9    05E8  28        		.byte	40
  10    05E9  43        		.byte	67
  11    05EA  43        		.byte	67
  12    05EB  53        		.byte	83
  13    05EC  29        		.byte	41
  14    05ED  20        		.byte	32
  15    05EE  28        		.byte	40
  16    05EF  62        		.byte	98
  17    05F0  69        		.byte	105
  18    05F1  74        		.byte	116
  19    05F2  20        		.byte	32
  20    05F3  33        		.byte	51
  21    05F4  30        		.byte	48
  22    05F5  29        		.byte	41
  23    05F6  20        		.byte	32
  24    05F7  6E        		.byte	110
  25    05F8  6F        		.byte	111
  26    05F9  74        		.byte	116
  27    05FA  20        		.byte	32
  28    05FB  73        		.byte	115
  29    05FC  65        		.byte	101
  30    05FD  74        		.byte	116
  31    05FE  0A        		.byte	10
  32    05FF  00        		.byte	0
  33                    	L5401:
  34    0600  20        		.byte	32
  35    0601  20        		.byte	32
  36    0602  53        		.byte	83
  37    0603  44        		.byte	68
  38    0604  20        		.byte	32
  39    0605  56        		.byte	86
  40    0606  65        		.byte	101
  41    0607  72        		.byte	114
  42    0608  2E        		.byte	46
  43    0609  31        		.byte	49
  44    060A  2C        		.byte	44
  45    060B  20        		.byte	32
  46    060C  42        		.byte	66
  47    060D  79        		.byte	121
  48    060E  74        		.byte	116
  49    060F  65        		.byte	101
  50    0610  20        		.byte	32
  51    0611  61        		.byte	97
  52    0612  64        		.byte	100
  53    0613  64        		.byte	100
  54    0614  72        		.byte	114
  55    0615  65        		.byte	101
  56    0616  73        		.byte	115
  57    0617  73        		.byte	115
  58    0618  00        		.byte	0
  59                    	L5501:
  60    0619  20        		.byte	32
  61    061A  20        		.byte	32
  62    061B  53        		.byte	83
  63    061C  44        		.byte	68
  64    061D  20        		.byte	32
  65    061E  56        		.byte	86
  66    061F  65        		.byte	101
  67    0620  72        		.byte	114
  68    0621  2E        		.byte	46
  69    0622  32        		.byte	50
  70    0623  2B        		.byte	43
  71    0624  2C        		.byte	44
  72    0625  20        		.byte	32
  73    0626  42        		.byte	66
  74    0627  79        		.byte	121
  75    0628  74        		.byte	116
  76    0629  65        		.byte	101
  77    062A  20        		.byte	32
  78    062B  61        		.byte	97
  79    062C  64        		.byte	100
  80    062D  64        		.byte	100
  81    062E  72        		.byte	114
  82    062F  65        		.byte	101
  83    0630  73        		.byte	115
  84    0631  73        		.byte	115
  85    0632  00        		.byte	0
  86                    	L5601:
  87    0633  0A        		.byte	10
  88    0634  43        		.byte	67
  89    0635  61        		.byte	97
  90    0636  72        		.byte	114
  91    0637  64        		.byte	100
  92    0638  20        		.byte	32
  93    0639  70        		.byte	112
  94    063A  6F        		.byte	111
  95    063B  77        		.byte	119
  96    063C  65        		.byte	101
  97    063D  72        		.byte	114
  98    063E  20        		.byte	32
  99    063F  75        		.byte	117
 100    0640  70        		.byte	112
 101    0641  20        		.byte	32
 102    0642  73        		.byte	115
 103    0643  74        		.byte	116
 104    0644  61        		.byte	97
 105    0645  74        		.byte	116
 106    0646  75        		.byte	117
 107    0647  73        		.byte	115
 108    0648  20        		.byte	32
 109    0649  62        		.byte	98
 110    064A  69        		.byte	105
 111    064B  74        		.byte	116
 112    064C  20        		.byte	32
 113    064D  28        		.byte	40
 114    064E  62        		.byte	98
 115    064F  75        		.byte	117
 116    0650  73        		.byte	115
 117    0651  79        		.byte	121
 118    0652  29        		.byte	41
 119    0653  20        		.byte	32
 120    0654  28        		.byte	40
 121    0655  62        		.byte	98
 122    0656  69        		.byte	105
 123    0657  74        		.byte	116
 124    0658  20        		.byte	32
 125    0659  33        		.byte	51
 126    065A  31        		.byte	49
 127    065B  29        		.byte	41
 128    065C  20        		.byte	32
 129    065D  73        		.byte	115
 130    065E  65        		.byte	101
 131    065F  74        		.byte	116
 132    0660  0A        		.byte	10
 133    0661  00        		.byte	0
 134                    	L5701:
 135    0662  0A        		.byte	10
 136    0663  43        		.byte	67
 137    0664  61        		.byte	97
 138    0665  72        		.byte	114
 139    0666  64        		.byte	100
 140    0667  20        		.byte	32
 141    0668  70        		.byte	112
 142    0669  6F        		.byte	111
 143    066A  77        		.byte	119
 144    066B  65        		.byte	101
 145    066C  72        		.byte	114
 146    066D  20        		.byte	32
 147    066E  75        		.byte	117
 148    066F  70        		.byte	112
 149    0670  20        		.byte	32
 150    0671  73        		.byte	115
 151    0672  74        		.byte	116
 152    0673  61        		.byte	97
 153    0674  74        		.byte	116
 154    0675  75        		.byte	117
 155    0676  73        		.byte	115
 156    0677  20        		.byte	32
 157    0678  62        		.byte	98
 158    0679  69        		.byte	105
 159    067A  74        		.byte	116
 160    067B  20        		.byte	32
 161    067C  28        		.byte	40
 162    067D  62        		.byte	98
 163    067E  75        		.byte	117
 164    067F  73        		.byte	115
 165    0680  79        		.byte	121
 166    0681  29        		.byte	41
 167    0682  20        		.byte	32
 168    0683  28        		.byte	40
 169    0684  62        		.byte	98
 170    0685  69        		.byte	105
 171    0686  74        		.byte	116
 172    0687  20        		.byte	32
 173    0688  33        		.byte	51
 174    0689  31        		.byte	49
 175    068A  29        		.byte	41
 176    068B  20        		.byte	32
 177    068C  6E        		.byte	110
 178    068D  6F        		.byte	111
 179    068E  74        		.byte	116
 180    068F  20        		.byte	32
 181    0690  73        		.byte	115
 182    0691  65        		.byte	101
 183    0692  74        		.byte	116
 184    0693  2E        		.byte	46
 185    0694  0A        		.byte	10
 186    0695  00        		.byte	0
 187                    	L5011:
 188    0696  20        		.byte	32
 189    0697  20        		.byte	32
 190    0698  54        		.byte	84
 191    0699  68        		.byte	104
 192    069A  69        		.byte	105
 193    069B  73        		.byte	115
 194    069C  20        		.byte	32
 195    069D  62        		.byte	98
 196    069E  69        		.byte	105
 197    069F  74        		.byte	116
 198    06A0  20        		.byte	32
 199    06A1  69        		.byte	105
 200    06A2  73        		.byte	115
 201    06A3  20        		.byte	32
 202    06A4  6E        		.byte	110
 203    06A5  6F        		.byte	111
 204    06A6  74        		.byte	116
 205    06A7  20        		.byte	32
 206    06A8  73        		.byte	115
 207    06A9  65        		.byte	101
 208    06AA  74        		.byte	116
 209    06AB  20        		.byte	32
 210    06AC  69        		.byte	105
 211    06AD  66        		.byte	102
 212    06AE  20        		.byte	32
 213    06AF  74        		.byte	116
 214    06B0  68        		.byte	104
 215    06B1  65        		.byte	101
 216    06B2  20        		.byte	32
 217    06B3  63        		.byte	99
 218    06B4  61        		.byte	97
 219    06B5  72        		.byte	114
 220    06B6  64        		.byte	100
 221    06B7  20        		.byte	32
 222    06B8  68        		.byte	104
 223    06B9  61        		.byte	97
 224    06BA  73        		.byte	115
 225    06BB  20        		.byte	32
 226    06BC  6E        		.byte	110
 227    06BD  6F        		.byte	111
 228    06BE  74        		.byte	116
 229    06BF  20        		.byte	32
 230    06C0  66        		.byte	102
 231    06C1  69        		.byte	105
 232    06C2  6E        		.byte	110
 233    06C3  69        		.byte	105
 234    06C4  73        		.byte	115
 235    06C5  68        		.byte	104
 236    06C6  65        		.byte	101
 237    06C7  64        		.byte	100
 238    06C8  20        		.byte	32
 239    06C9  74        		.byte	116
 240    06CA  68        		.byte	104
 241    06CB  65        		.byte	101
 242    06CC  20        		.byte	32
 243    06CD  70        		.byte	112
 244    06CE  6F        		.byte	111
 245    06CF  77        		.byte	119
 246    06D0  65        		.byte	101
 247    06D1  72        		.byte	114
 248    06D2  20        		.byte	32
 249    06D3  75        		.byte	117
 250    06D4  70        		.byte	112
 251    06D5  20        		.byte	32
 252    06D6  72        		.byte	114
 253    06D7  6F        		.byte	111
 254    06D8  75        		.byte	117
 255    06D9  74        		.byte	116
 256    06DA  69        		.byte	105
 257    06DB  6E        		.byte	110
 258    06DC  65        		.byte	101
 259    06DD  2E        		.byte	46
 260    06DE  0A        		.byte	10
 261    06DF  00        		.byte	0
 262                    	L5111:
 263    06E0  2D        		.byte	45
 264    06E1  2D        		.byte	45
 265    06E2  2D        		.byte	45
 266    06E3  2D        		.byte	45
 267    06E4  2D        		.byte	45
 268    06E5  2D        		.byte	45
 269    06E6  2D        		.byte	45
 270    06E7  2D        		.byte	45
 271    06E8  2D        		.byte	45
 272    06E9  2D        		.byte	45
 273    06EA  2D        		.byte	45
 274    06EB  0A        		.byte	10
 275    06EC  00        		.byte	0
 276                    	L5211:
 277    06ED  43        		.byte	67
 278    06EE  49        		.byte	73
 279    06EF  44        		.byte	68
 280    06F0  20        		.byte	32
 281    06F1  72        		.byte	114
 282    06F2  65        		.byte	101
 283    06F3  67        		.byte	103
 284    06F4  69        		.byte	105
 285    06F5  73        		.byte	115
 286    06F6  74        		.byte	116
 287    06F7  65        		.byte	101
 288    06F8  72        		.byte	114
 289    06F9  3A        		.byte	58
 290    06FA  0A        		.byte	10
 291    06FB  00        		.byte	0
 292                    	L5311:
 293    06FC  4D        		.byte	77
 294    06FD  49        		.byte	73
 295    06FE  44        		.byte	68
 296    06FF  3A        		.byte	58
 297    0700  20        		.byte	32
 298    0701  25        		.byte	37
 299    0702  64        		.byte	100
 300    0703  20        		.byte	32
 301    0704  28        		.byte	40
 302    0705  30        		.byte	48
 303    0706  78        		.byte	120
 304    0707  25        		.byte	37
 305    0708  30        		.byte	48
 306    0709  32        		.byte	50
 307    070A  78        		.byte	120
 308    070B  29        		.byte	41
 309    070C  2C        		.byte	44
 310    070D  20        		.byte	32
 311    070E  00        		.byte	0
 312                    	L5411:
 313    070F  4F        		.byte	79
 314    0710  49        		.byte	73
 315    0711  44        		.byte	68
 316    0712  3A        		.byte	58
 317    0713  20        		.byte	32
 318    0714  25        		.byte	37
 319    0715  62        		.byte	98
 320    0716  2C        		.byte	44
 321    0717  20        		.byte	32
 322    0718  00        		.byte	0
 323                    	L5511:
 324    0719  50        		.byte	80
 325    071A  4E        		.byte	78
 326    071B  4D        		.byte	77
 327    071C  3A        		.byte	58
 328    071D  20        		.byte	32
 329    071E  25        		.byte	37
 330    071F  62        		.byte	98
 331    0720  2C        		.byte	44
 332    0721  20        		.byte	32
 333    0722  00        		.byte	0
 334                    	L5611:
 335    0723  50        		.byte	80
 336    0724  52        		.byte	82
 337    0725  56        		.byte	86
 338    0726  3A        		.byte	58
 339    0727  20        		.byte	32
 340    0728  25        		.byte	37
 341    0729  64        		.byte	100
 342    072A  2E        		.byte	46
 343    072B  25        		.byte	37
 344    072C  64        		.byte	100
 345    072D  2C        		.byte	44
 346    072E  20        		.byte	32
 347    072F  00        		.byte	0
 348                    	L5711:
 349    0730  50        		.byte	80
 350    0731  53        		.byte	83
 351    0732  4E        		.byte	78
 352    0733  3A        		.byte	58
 353    0734  20        		.byte	32
 354    0735  25        		.byte	37
 355    0736  6C        		.byte	108
 356    0737  75        		.byte	117
 357    0738  2C        		.byte	44
 358    0739  20        		.byte	32
 359    073A  00        		.byte	0
 360                    	L5021:
 361    073B  4D        		.byte	77
 362    073C  44        		.byte	68
 363    073D  54        		.byte	84
 364    073E  3A        		.byte	58
 365    073F  20        		.byte	32
 366    0740  25        		.byte	37
 367    0741  64        		.byte	100
 368    0742  2D        		.byte	45
 369    0743  25        		.byte	37
 370    0744  64        		.byte	100
 371    0745  0A        		.byte	10
 372    0746  00        		.byte	0
 373                    	L5121:
 374    0747  2D        		.byte	45
 375    0748  2D        		.byte	45
 376    0749  2D        		.byte	45
 377    074A  2D        		.byte	45
 378    074B  2D        		.byte	45
 379    074C  2D        		.byte	45
 380    074D  2D        		.byte	45
 381    074E  2D        		.byte	45
 382    074F  2D        		.byte	45
 383    0750  2D        		.byte	45
 384    0751  2D        		.byte	45
 385    0752  0A        		.byte	10
 386    0753  00        		.byte	0
 387                    	L5221:
 388    0754  43        		.byte	67
 389    0755  53        		.byte	83
 390    0756  44        		.byte	68
 391    0757  20        		.byte	32
 392    0758  72        		.byte	114
 393    0759  65        		.byte	101
 394    075A  67        		.byte	103
 395    075B  69        		.byte	105
 396    075C  73        		.byte	115
 397    075D  74        		.byte	116
 398    075E  65        		.byte	101
 399    075F  72        		.byte	114
 400    0760  3A        		.byte	58
 401    0761  0A        		.byte	10
 402    0762  00        		.byte	0
 403                    	L5321:
 404    0763  43        		.byte	67
 405    0764  53        		.byte	83
 406    0765  44        		.byte	68
 407    0766  20        		.byte	32
 408    0767  56        		.byte	86
 409    0768  65        		.byte	101
 410    0769  72        		.byte	114
 411    076A  73        		.byte	115
 412    076B  69        		.byte	105
 413    076C  6F        		.byte	111
 414    076D  6E        		.byte	110
 415    076E  20        		.byte	32
 416    076F  31        		.byte	49
 417    0770  2E        		.byte	46
 418    0771  30        		.byte	48
 419    0772  2C        		.byte	44
 420    0773  20        		.byte	32
 421    0774  53        		.byte	83
 422    0775  74        		.byte	116
 423    0776  61        		.byte	97
 424    0777  6E        		.byte	110
 425    0778  64        		.byte	100
 426    0779  61        		.byte	97
 427    077A  72        		.byte	114
 428    077B  64        		.byte	100
 429    077C  20        		.byte	32
 430    077D  43        		.byte	67
 431    077E  61        		.byte	97
 432    077F  70        		.byte	112
 433    0780  61        		.byte	97
 434    0781  63        		.byte	99
 435    0782  69        		.byte	105
 436    0783  74        		.byte	116
 437    0784  79        		.byte	121
 438    0785  0A        		.byte	10
 439    0786  00        		.byte	0
 440                    	L5421:
 441    0787  20        		.byte	32
 442    0788  44        		.byte	68
 443    0789  65        		.byte	101
 444    078A  76        		.byte	118
 445    078B  69        		.byte	105
 446    078C  63        		.byte	99
 447    078D  65        		.byte	101
 448    078E  20        		.byte	32
 449    078F  63        		.byte	99
 450    0790  61        		.byte	97
 451    0791  70        		.byte	112
 452    0792  61        		.byte	97
 453    0793  63        		.byte	99
 454    0794  69        		.byte	105
 455    0795  74        		.byte	116
 456    0796  79        		.byte	121
 457    0797  3A        		.byte	58
 458    0798  20        		.byte	32
 459    0799  25        		.byte	37
 460    079A  6C        		.byte	108
 461    079B  75        		.byte	117
 462    079C  20        		.byte	32
 463    079D  4B        		.byte	75
 464    079E  42        		.byte	66
 465    079F  79        		.byte	121
 466    07A0  74        		.byte	116
 467    07A1  65        		.byte	101
 468    07A2  2C        		.byte	44
 469    07A3  20        		.byte	32
 470    07A4  25        		.byte	37
 471    07A5  6C        		.byte	108
 472    07A6  75        		.byte	117
 473    07A7  20        		.byte	32
 474    07A8  4D        		.byte	77
 475    07A9  42        		.byte	66
 476    07AA  79        		.byte	121
 477    07AB  74        		.byte	116
 478    07AC  65        		.byte	101
 479    07AD  0A        		.byte	10
 480    07AE  00        		.byte	0
 481                    	L5521:
 482    07AF  43        		.byte	67
 483    07B0  53        		.byte	83
 484    07B1  44        		.byte	68
 485    07B2  20        		.byte	32
 486    07B3  56        		.byte	86
 487    07B4  65        		.byte	101
 488    07B5  72        		.byte	114
 489    07B6  73        		.byte	115
 490    07B7  69        		.byte	105
 491    07B8  6F        		.byte	111
 492    07B9  6E        		.byte	110
 493    07BA  20        		.byte	32
 494    07BB  32        		.byte	50
 495    07BC  2E        		.byte	46
 496    07BD  30        		.byte	48
 497    07BE  2C        		.byte	44
 498    07BF  20        		.byte	32
 499    07C0  48        		.byte	72
 500    07C1  69        		.byte	105
 501    07C2  67        		.byte	103
 502    07C3  68        		.byte	104
 503    07C4  20        		.byte	32
 504    07C5  43        		.byte	67
 505    07C6  61        		.byte	97
 506    07C7  70        		.byte	112
 507    07C8  61        		.byte	97
 508    07C9  63        		.byte	99
 509    07CA  69        		.byte	105
 510    07CB  74        		.byte	116
 511    07CC  79        		.byte	121
 512    07CD  20        		.byte	32
 513    07CE  61        		.byte	97
 514    07CF  6E        		.byte	110
 515    07D0  64        		.byte	100
 516    07D1  20        		.byte	32
 517    07D2  45        		.byte	69
 518    07D3  78        		.byte	120
 519    07D4  74        		.byte	116
 520    07D5  65        		.byte	101
 521    07D6  6E        		.byte	110
 522    07D7  64        		.byte	100
 523    07D8  65        		.byte	101
 524    07D9  64        		.byte	100
 525    07DA  20        		.byte	32
 526    07DB  43        		.byte	67
 527    07DC  61        		.byte	97
 528    07DD  70        		.byte	112
 529    07DE  61        		.byte	97
 530    07DF  63        		.byte	99
 531    07E0  69        		.byte	105
 532    07E1  74        		.byte	116
 533    07E2  79        		.byte	121
 534    07E3  0A        		.byte	10
 535    07E4  00        		.byte	0
 536                    	L5621:
 537    07E5  20        		.byte	32
 538    07E6  44        		.byte	68
 539    07E7  65        		.byte	101
 540    07E8  76        		.byte	118
 541    07E9  69        		.byte	105
 542    07EA  63        		.byte	99
 543    07EB  65        		.byte	101
 544    07EC  20        		.byte	32
 545    07ED  63        		.byte	99
 546    07EE  61        		.byte	97
 547    07EF  70        		.byte	112
 548    07F0  61        		.byte	97
 549    07F1  63        		.byte	99
 550    07F2  69        		.byte	105
 551    07F3  74        		.byte	116
 552    07F4  79        		.byte	121
 553    07F5  3A        		.byte	58
 554    07F6  20        		.byte	32
 555    07F7  25        		.byte	37
 556    07F8  6C        		.byte	108
 557    07F9  75        		.byte	117
 558    07FA  20        		.byte	32
 559    07FB  4B        		.byte	75
 560    07FC  42        		.byte	66
 561    07FD  79        		.byte	121
 562    07FE  74        		.byte	116
 563    07FF  65        		.byte	101
 564    0800  2C        		.byte	44
 565    0801  20        		.byte	32
 566    0802  25        		.byte	37
 567    0803  6C        		.byte	108
 568    0804  75        		.byte	117
 569    0805  20        		.byte	32
 570    0806  4D        		.byte	77
 571    0807  42        		.byte	66
 572    0808  79        		.byte	121
 573    0809  74        		.byte	116
 574    080A  65        		.byte	101
 575    080B  0A        		.byte	10
 576    080C  00        		.byte	0
 577                    	L5721:
 578    080D  43        		.byte	67
 579    080E  53        		.byte	83
 580    080F  44        		.byte	68
 581    0810  20        		.byte	32
 582    0811  56        		.byte	86
 583    0812  65        		.byte	101
 584    0813  72        		.byte	114
 585    0814  73        		.byte	115
 586    0815  69        		.byte	105
 587    0816  6F        		.byte	111
 588    0817  6E        		.byte	110
 589    0818  20        		.byte	32
 590    0819  33        		.byte	51
 591    081A  2E        		.byte	46
 592    081B  30        		.byte	48
 593    081C  2C        		.byte	44
 594    081D  20        		.byte	32
 595    081E  55        		.byte	85
 596    081F  6C        		.byte	108
 597    0820  74        		.byte	116
 598    0821  72        		.byte	114
 599    0822  61        		.byte	97
 600    0823  20        		.byte	32
 601    0824  43        		.byte	67
 602    0825  61        		.byte	97
 603    0826  70        		.byte	112
 604    0827  61        		.byte	97
 605    0828  63        		.byte	99
 606    0829  69        		.byte	105
 607    082A  74        		.byte	116
 608    082B  79        		.byte	121
 609    082C  20        		.byte	32
 610    082D  28        		.byte	40
 611    082E  53        		.byte	83
 612    082F  44        		.byte	68
 613    0830  55        		.byte	85
 614    0831  43        		.byte	67
 615    0832  29        		.byte	41
 616    0833  0A        		.byte	10
 617    0834  00        		.byte	0
 618                    	L5031:
 619    0835  2D        		.byte	45
 620    0836  2D        		.byte	45
 621    0837  2D        		.byte	45
 622    0838  2D        		.byte	45
 623    0839  2D        		.byte	45
 624    083A  2D        		.byte	45
 625    083B  2D        		.byte	45
 626    083C  2D        		.byte	45
 627    083D  2D        		.byte	45
 628    083E  2D        		.byte	45
 629    083F  2D        		.byte	45
 630    0840  0A        		.byte	10
 631    0841  00        		.byte	0
 632                    		.psect	_text
 633                    	;  582  
 634                    	;  583  /* print OCR, CID and CSD registers*/
 635                    	;  584  void sdprtreg()
 636                    	;  585          {
 637                    	_sdprtreg:
 638    0F30  CD0000    		call	c.savs0
 639    0F33  21EEFF    		ld	hl,65518
 640    0F36  39        		add	hl,sp
 641    0F37  F9        		ld	sp,hl
 642                    	;  586          unsigned int n;
 643                    	;  587          unsigned int csize;
 644                    	;  588          unsigned long devsize;
 645                    	;  589          unsigned long capacity;
 646                    	;  590  
 647                    	;  591          printf("OCR register:\n");
 648    0F38  215404    		ld	hl,L546
 649    0F3B  CD0000    		call	_printf
 650                    	;  592          if (ocrreg[2] & 0x80)
 651    0F3E  3A1012    		ld	a,(_ocrreg+2)
 652    0F41  CB7F      		bit	7,a
 653    0F43  6F        		ld	l,a
 654    0F44  2806      		jr	z,L1661
 655                    	;  593                  printf("2.7-2.8V (bit 15) ");
 656    0F46  216304    		ld	hl,L556
 657    0F49  CD0000    		call	_printf
 658                    	L1661:
 659                    	;  594          if (ocrreg[1] & 0x01)
 660    0F4C  3A0F12    		ld	a,(_ocrreg+1)
 661    0F4F  CB47      		bit	0,a
 662    0F51  6F        		ld	l,a
 663    0F52  2806      		jr	z,L1761
 664                    	;  595                  printf("2.8-2.9V (bit 16) ");
 665    0F54  217604    		ld	hl,L566
 666    0F57  CD0000    		call	_printf
 667                    	L1761:
 668                    	;  596          if (ocrreg[1] & 0x02)
 669    0F5A  3A0F12    		ld	a,(_ocrreg+1)
 670    0F5D  CB4F      		bit	1,a
 671    0F5F  6F        		ld	l,a
 672    0F60  2806      		jr	z,L1071
 673                    	;  597                  printf("2.9-3.0V (bit 17) ");
 674    0F62  218904    		ld	hl,L576
 675    0F65  CD0000    		call	_printf
 676                    	L1071:
 677                    	;  598          if (ocrreg[1] & 0x04)
 678    0F68  3A0F12    		ld	a,(_ocrreg+1)
 679    0F6B  CB57      		bit	2,a
 680    0F6D  6F        		ld	l,a
 681    0F6E  2806      		jr	z,L1171
 682                    	;  599                  printf("3.0-3.1V (bit 18) \n");
 683    0F70  219C04    		ld	hl,L507
 684    0F73  CD0000    		call	_printf
 685                    	L1171:
 686                    	;  600          if (ocrreg[1] & 0x08)
 687    0F76  3A0F12    		ld	a,(_ocrreg+1)
 688    0F79  CB5F      		bit	3,a
 689    0F7B  6F        		ld	l,a
 690    0F7C  2806      		jr	z,L1271
 691                    	;  601                  printf("3.1-3.2V (bit 19) ");
 692    0F7E  21B004    		ld	hl,L517
 693    0F81  CD0000    		call	_printf
 694                    	L1271:
 695                    	;  602          if (ocrreg[1] & 0x10)
 696    0F84  3A0F12    		ld	a,(_ocrreg+1)
 697    0F87  CB67      		bit	4,a
 698    0F89  6F        		ld	l,a
 699    0F8A  2806      		jr	z,L1371
 700                    	;  603                  printf("3.2-3.3V (bit 20) ");
 701    0F8C  21C304    		ld	hl,L527
 702    0F8F  CD0000    		call	_printf
 703                    	L1371:
 704                    	;  604          if (ocrreg[1] & 0x20)
 705    0F92  3A0F12    		ld	a,(_ocrreg+1)
 706    0F95  CB6F      		bit	5,a
 707    0F97  6F        		ld	l,a
 708    0F98  2806      		jr	z,L1471
 709                    	;  605                  printf("3.3-3.4V (bit 21) ");
 710    0F9A  21D604    		ld	hl,L537
 711    0F9D  CD0000    		call	_printf
 712                    	L1471:
 713                    	;  606          if (ocrreg[1] & 0x40)
 714    0FA0  3A0F12    		ld	a,(_ocrreg+1)
 715    0FA3  CB77      		bit	6,a
 716    0FA5  6F        		ld	l,a
 717    0FA6  2806      		jr	z,L1571
 718                    	;  607                  printf("3.4-3.5V (bit 22) \n");
 719    0FA8  21E904    		ld	hl,L547
 720    0FAB  CD0000    		call	_printf
 721                    	L1571:
 722                    	;  608          if (ocrreg[1] & 0x80)
 723    0FAE  3A0F12    		ld	a,(_ocrreg+1)
 724    0FB1  CB7F      		bit	7,a
 725    0FB3  6F        		ld	l,a
 726    0FB4  2806      		jr	z,L1671
 727                    	;  609                  printf("3.5-3.6V (bit 23) \n");
 728    0FB6  21FD04    		ld	hl,L557
 729    0FB9  CD0000    		call	_printf
 730                    	L1671:
 731                    	;  610          if (ocrreg[0] & 0x01)
 732    0FBC  3A0E12    		ld	a,(_ocrreg)
 733    0FBF  CB47      		bit	0,a
 734    0FC1  6F        		ld	l,a
 735    0FC2  2806      		jr	z,L1771
 736                    	;  611                  printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
 737    0FC4  211105    		ld	hl,L567
 738    0FC7  CD0000    		call	_printf
 739                    	L1771:
 740                    	;  612          if (ocrreg[0] & 0x08)
 741    0FCA  3A0E12    		ld	a,(_ocrreg)
 742    0FCD  CB5F      		bit	3,a
 743    0FCF  6F        		ld	l,a
 744    0FD0  2806      		jr	z,L1002
 745                    	;  613                  printf("Over 2TB support Status (CO2T) (bit 27) set\n");
 746    0FD2  214105    		ld	hl,L577
 747    0FD5  CD0000    		call	_printf
 748                    	L1002:
 749                    	;  614          if (ocrreg[0] & 0x20)
 750    0FD8  3A0E12    		ld	a,(_ocrreg)
 751    0FDB  CB6F      		bit	5,a
 752    0FDD  6F        		ld	l,a
 753    0FDE  2806      		jr	z,L1102
 754                    	;  615                  printf("UHS-II Card Status (bit 29) set ");
 755    0FE0  216E05    		ld	hl,L5001
 756    0FE3  CD0000    		call	_printf
 757                    	L1102:
 758                    	;  616          if (ocrreg[0] & 0x80)
 759    0FE6  3A0E12    		ld	a,(_ocrreg)
 760    0FE9  CB7F      		bit	7,a
 761    0FEB  6F        		ld	l,a
 762    0FEC  2838      		jr	z,L1202
 763                    	;  617                  {
 764                    	;  618                  if (ocrreg[0] & 0x40)
 765    0FEE  3A0E12    		ld	a,(_ocrreg)
 766    0FF1  CB77      		bit	6,a
 767    0FF3  6F        		ld	l,a
 768    0FF4  280E      		jr	z,L1302
 769                    	;  619                          {
 770                    	;  620                          printf("Card Capacity Status (CCS) (bit 30) set\n");
 771    0FF6  218F05    		ld	hl,L5101
 772    0FF9  CD0000    		call	_printf
 773                    	;  621                          printf("  SD Ver.2+, Block address");
 774    0FFC  21B805    		ld	hl,L5201
 775    0FFF  CD0000    		call	_printf
 776                    	;  622                          }
 777                    	;  623                  else
 778    1002  181A      		jr	L1402
 779                    	L1302:
 780                    	;  624                          {
 781                    	;  625                          printf("Card Capacity Status (CCS) (bit 30) not set\n");
 782    1004  21D305    		ld	hl,L5301
 783    1007  CD0000    		call	_printf
 784                    	;  626                          if (acmd41[3] == 0x00)
 785    100A  3A8200    		ld	a,(_acmd41+3)
 786    100D  B7        		or	a
 787    100E  2008      		jr	nz,L1502
 788                    	;  627                                  printf("  SD Ver.1, Byte address");
 789    1010  210006    		ld	hl,L5401
 790    1013  CD0000    		call	_printf
 791                    	;  628                          else
 792    1016  1806      		jr	L1402
 793                    	L1502:
 794                    	;  629                                  printf("  SD Ver.2+, Byte address");
 795    1018  211906    		ld	hl,L5501
 796    101B  CD0000    		call	_printf
 797                    	L1402:
 798                    	;  630                          }
 799                    	;  631                  printf("\nCard power up status bit (busy) (bit 31) set\n");
 800    101E  213306    		ld	hl,L5601
 801    1021  CD0000    		call	_printf
 802                    	;  632                  }
 803                    	;  633          else
 804    1024  180C      		jr	L1702
 805                    	L1202:
 806                    	;  634                  {
 807                    	;  635                  printf("\nCard power up status bit (busy) (bit 31) not set.\n");
 808    1026  216206    		ld	hl,L5701
 809    1029  CD0000    		call	_printf
 810                    	;  636                  printf("  This bit is not set if the card has not finished the power up routine.\n");
 811    102C  219606    		ld	hl,L5011
 812    102F  CD0000    		call	_printf
 813                    	L1702:
 814                    	;  637                  }
 815                    	;  638          printf("-----------\n");
 816    1032  21E006    		ld	hl,L5111
 817    1035  CD0000    		call	_printf
 818                    	;  639          printf("CID register:\n");
 819    1038  21ED06    		ld	hl,L5211
 820    103B  CD0000    		call	_printf
 821                    	;  640          printf("MID: %d (0x%02x), ", cidreg[0], cidreg[0]);
 822    103E  3A1212    		ld	a,(_cidreg)
 823    1041  4F        		ld	c,a
 824    1042  97        		sub	a
 825    1043  47        		ld	b,a
 826    1044  C5        		push	bc
 827    1045  3A1212    		ld	a,(_cidreg)
 828    1048  4F        		ld	c,a
 829    1049  97        		sub	a
 830    104A  47        		ld	b,a
 831    104B  C5        		push	bc
 832    104C  21FC06    		ld	hl,L5311
 833    104F  CD0000    		call	_printf
 834    1052  F1        		pop	af
 835    1053  F1        		pop	af
 836                    	;  641          printf("OID: %b, ", &cidreg[1], 2);
 837    1054  210200    		ld	hl,2
 838    1057  E5        		push	hl
 839    1058  211312    		ld	hl,_cidreg+1
 840    105B  E5        		push	hl
 841    105C  210F07    		ld	hl,L5411
 842    105F  CD0000    		call	_printf
 843    1062  F1        		pop	af
 844    1063  F1        		pop	af
 845                    	;  642          printf("PNM: %b, ", &cidreg[3], 5);
 846    1064  210500    		ld	hl,5
 847    1067  E5        		push	hl
 848    1068  211512    		ld	hl,_cidreg+3
 849    106B  E5        		push	hl
 850    106C  211907    		ld	hl,L5511
 851    106F  CD0000    		call	_printf
 852    1072  F1        		pop	af
 853    1073  F1        		pop	af
 854                    	;  643          printf("PRV: %d.%d, ",
 855                    	;  644                  (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 856    1074  3A1A12    		ld	a,(_cidreg+8)
 857    1077  6F        		ld	l,a
 858    1078  97        		sub	a
 859    1079  67        		ld	h,a
 860    107A  7D        		ld	a,l
 861    107B  E60F      		and	15
 862    107D  6F        		ld	l,a
 863    107E  97        		sub	a
 864    107F  67        		ld	h,a
 865    1080  E5        		push	hl
 866    1081  3A1A12    		ld	a,(_cidreg+8)
 867    1084  4F        		ld	c,a
 868    1085  97        		sub	a
 869    1086  47        		ld	b,a
 870    1087  C5        		push	bc
 871    1088  210400    		ld	hl,4
 872    108B  E5        		push	hl
 873    108C  CD0000    		call	c.irsh
 874    108F  E1        		pop	hl
 875    1090  7D        		ld	a,l
 876    1091  E60F      		and	15
 877    1093  6F        		ld	l,a
 878    1094  97        		sub	a
 879    1095  67        		ld	h,a
 880    1096  E5        		push	hl
 881    1097  212307    		ld	hl,L5611
 882    109A  CD0000    		call	_printf
 883    109D  F1        		pop	af
 884    109E  F1        		pop	af
 885                    	;  645          printf("PSN: %lu, ",
 886                    	;  646                  (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
 887    109F  3A1B12    		ld	a,(_cidreg+9)
 888    10A2  4F        		ld	c,a
 889    10A3  97        		sub	a
 890    10A4  47        		ld	b,a
 891    10A5  C5        		push	bc
 892    10A6  211800    		ld	hl,24
 893    10A9  E5        		push	hl
 894    10AA  CD0000    		call	c.ilsh
 895    10AD  E1        		pop	hl
 896    10AE  E5        		push	hl
 897    10AF  3A1C12    		ld	a,(_cidreg+10)
 898    10B2  4F        		ld	c,a
 899    10B3  97        		sub	a
 900    10B4  47        		ld	b,a
 901    10B5  C5        		push	bc
 902    10B6  211000    		ld	hl,16
 903    10B9  E5        		push	hl
 904    10BA  CD0000    		call	c.ilsh
 905    10BD  E1        		pop	hl
 906    10BE  E3        		ex	(sp),hl
 907    10BF  C1        		pop	bc
 908    10C0  09        		add	hl,bc
 909    10C1  E5        		push	hl
 910    10C2  3A1D12    		ld	a,(_cidreg+11)
 911    10C5  6F        		ld	l,a
 912    10C6  97        		sub	a
 913    10C7  67        		ld	h,a
 914    10C8  29        		add	hl,hl
 915    10C9  29        		add	hl,hl
 916    10CA  29        		add	hl,hl
 917    10CB  29        		add	hl,hl
 918    10CC  29        		add	hl,hl
 919    10CD  29        		add	hl,hl
 920    10CE  29        		add	hl,hl
 921    10CF  29        		add	hl,hl
 922    10D0  E3        		ex	(sp),hl
 923    10D1  C1        		pop	bc
 924    10D2  09        		add	hl,bc
 925    10D3  E5        		push	hl
 926    10D4  3A1E12    		ld	a,(_cidreg+12)
 927    10D7  6F        		ld	l,a
 928    10D8  97        		sub	a
 929    10D9  67        		ld	h,a
 930    10DA  E3        		ex	(sp),hl
 931    10DB  C1        		pop	bc
 932    10DC  09        		add	hl,bc
 933    10DD  E5        		push	hl
 934    10DE  213007    		ld	hl,L5711
 935    10E1  CD0000    		call	_printf
 936    10E4  F1        		pop	af
 937                    	;  647          printf("MDT: %d-%d\n",
 938                    	;  648                  2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
 939    10E5  3A2012    		ld	a,(_cidreg+14)
 940    10E8  6F        		ld	l,a
 941    10E9  97        		sub	a
 942    10EA  67        		ld	h,a
 943    10EB  7D        		ld	a,l
 944    10EC  E60F      		and	15
 945    10EE  6F        		ld	l,a
 946    10EF  97        		sub	a
 947    10F0  67        		ld	h,a
 948    10F1  E5        		push	hl
 949    10F2  3A1F12    		ld	a,(_cidreg+13)
 950    10F5  6F        		ld	l,a
 951    10F6  97        		sub	a
 952    10F7  67        		ld	h,a
 953    10F8  7D        		ld	a,l
 954    10F9  E60F      		and	15
 955    10FB  6F        		ld	l,a
 956    10FC  97        		sub	a
 957    10FD  67        		ld	h,a
 958    10FE  29        		add	hl,hl
 959    10FF  29        		add	hl,hl
 960    1100  29        		add	hl,hl
 961    1101  29        		add	hl,hl
 962    1102  01D007    		ld	bc,2000
 963    1105  09        		add	hl,bc
 964    1106  E5        		push	hl
 965    1107  3A2012    		ld	a,(_cidreg+14)
 966    110A  4F        		ld	c,a
 967    110B  97        		sub	a
 968    110C  47        		ld	b,a
 969    110D  C5        		push	bc
 970    110E  210400    		ld	hl,4
 971    1111  E5        		push	hl
 972    1112  CD0000    		call	c.irsh
 973    1115  E1        		pop	hl
 974    1116  E3        		ex	(sp),hl
 975    1117  C1        		pop	bc
 976    1118  09        		add	hl,bc
 977    1119  E5        		push	hl
 978    111A  213B07    		ld	hl,L5021
 979    111D  CD0000    		call	_printf
 980    1120  F1        		pop	af
 981    1121  F1        		pop	af
 982                    	;  649          printf("-----------\n");
 983    1122  214707    		ld	hl,L5121
 984    1125  CD0000    		call	_printf
 985                    	;  650          printf("CSD register:\n");
 986    1128  215407    		ld	hl,L5221
 987    112B  CD0000    		call	_printf
 988                    	;  651          if ((csdreg[0] & 0xc0) == 0x00)
 989    112E  3A2212    		ld	a,(_csdreg)
 990    1131  E6C0      		and	192
 991    1133  C22712    		jp	nz,L1012
 992                    	;  652                  {
 993                    	;  653                  printf("CSD Version 1.0, Standard Capacity\n");
 994    1136  216307    		ld	hl,L5321
 995    1139  CD0000    		call	_printf
 996                    	;  654                  n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
 997    113C  3A2712    		ld	a,(_csdreg+5)
 998    113F  6F        		ld	l,a
 999    1140  97        		sub	a
1000    1141  67        		ld	h,a
1001    1142  7D        		ld	a,l
1002    1143  E60F      		and	15
1003    1145  6F        		ld	l,a
1004    1146  97        		sub	a
1005    1147  67        		ld	h,a
1006    1148  E5        		push	hl
1007    1149  3A2C12    		ld	a,(_csdreg+10)
1008    114C  6F        		ld	l,a
1009    114D  97        		sub	a
1010    114E  67        		ld	h,a
1011    114F  7D        		ld	a,l
1012    1150  E680      		and	128
1013    1152  6F        		ld	l,a
1014    1153  97        		sub	a
1015    1154  67        		ld	h,a
1016    1155  E5        		push	hl
1017    1156  210700    		ld	hl,7
1018    1159  E5        		push	hl
1019    115A  CD0000    		call	c.irsh
1020    115D  E1        		pop	hl
1021    115E  E3        		ex	(sp),hl
1022    115F  C1        		pop	bc
1023    1160  09        		add	hl,bc
1024    1161  E5        		push	hl
1025    1162  3A2B12    		ld	a,(_csdreg+9)
1026    1165  6F        		ld	l,a
1027    1166  97        		sub	a
1028    1167  67        		ld	h,a
1029    1168  7D        		ld	a,l
1030    1169  E603      		and	3
1031    116B  6F        		ld	l,a
1032    116C  97        		sub	a
1033    116D  67        		ld	h,a
1034    116E  29        		add	hl,hl
1035    116F  E3        		ex	(sp),hl
1036    1170  C1        		pop	bc
1037    1171  09        		add	hl,bc
1038    1172  23        		inc	hl
1039    1173  23        		inc	hl
1040    1174  DD75F8    		ld	(ix-8),l
1041    1177  DD74F9    		ld	(ix-7),h
1042                    	;  655                  csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
1043                    	;  656              ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
1044    117A  3A2A12    		ld	a,(_csdreg+8)
1045    117D  4F        		ld	c,a
1046    117E  97        		sub	a
1047    117F  47        		ld	b,a
1048    1180  C5        		push	bc
1049    1181  210600    		ld	hl,6
1050    1184  E5        		push	hl
1051    1185  CD0000    		call	c.irsh
1052    1188  E1        		pop	hl
1053    1189  E5        		push	hl
1054    118A  3A2912    		ld	a,(_csdreg+7)
1055    118D  6F        		ld	l,a
1056    118E  97        		sub	a
1057    118F  67        		ld	h,a
1058    1190  29        		add	hl,hl
1059    1191  29        		add	hl,hl
1060    1192  E3        		ex	(sp),hl
1061    1193  C1        		pop	bc
1062    1194  09        		add	hl,bc
1063    1195  E5        		push	hl
1064    1196  3A2812    		ld	a,(_csdreg+6)
1065    1199  6F        		ld	l,a
1066    119A  97        		sub	a
1067    119B  67        		ld	h,a
1068    119C  7D        		ld	a,l
1069    119D  E603      		and	3
1070    119F  6F        		ld	l,a
1071    11A0  97        		sub	a
1072    11A1  67        		ld	h,a
1073    11A2  E5        		push	hl
1074    11A3  210A00    		ld	hl,10
1075    11A6  E5        		push	hl
1076    11A7  CD0000    		call	c.ilsh
1077    11AA  E1        		pop	hl
1078    11AB  E3        		ex	(sp),hl
1079    11AC  C1        		pop	bc
1080    11AD  09        		add	hl,bc
1081    11AE  23        		inc	hl
1082    11AF  DD75F6    		ld	(ix-10),l
1083    11B2  DD74F7    		ld	(ix-9),h
1084                    	;  657                  capacity = (unsigned long) csize << (n-10);
1085    11B5  DDE5      		push	ix
1086    11B7  C1        		pop	bc
1087    11B8  21EEFF    		ld	hl,65518
1088    11BB  09        		add	hl,bc
1089    11BC  E5        		push	hl
1090    11BD  DDE5      		push	ix
1091    11BF  C1        		pop	bc
1092    11C0  21F6FF    		ld	hl,65526
1093    11C3  09        		add	hl,bc
1094    11C4  4D        		ld	c,l
1095    11C5  44        		ld	b,h
1096    11C6  97        		sub	a
1097    11C7  320000    		ld	(c.r0),a
1098    11CA  320100    		ld	(c.r0+1),a
1099    11CD  0A        		ld	a,(bc)
1100    11CE  320200    		ld	(c.r0+2),a
1101    11D1  03        		inc	bc
1102    11D2  0A        		ld	a,(bc)
1103    11D3  320300    		ld	(c.r0+3),a
1104    11D6  210000    		ld	hl,c.r0
1105    11D9  E5        		push	hl
1106    11DA  DD6EF8    		ld	l,(ix-8)
1107    11DD  DD66F9    		ld	h,(ix-7)
1108    11E0  01F6FF    		ld	bc,65526
1109    11E3  09        		add	hl,bc
1110    11E4  E5        		push	hl
1111    11E5  CD0000    		call	c.llsh
1112    11E8  CD0000    		call	c.mvl
1113    11EB  F1        		pop	af
1114                    	;  658                  printf(" Device capacity: %lu KByte, %lu MByte\n",
1115                    	;  659                    capacity, capacity >> 10);
1116    11EC  DDE5      		push	ix
1117    11EE  C1        		pop	bc
1118    11EF  21EEFF    		ld	hl,65518
1119    11F2  09        		add	hl,bc
1120    11F3  CD0000    		call	c.0mvf
1121    11F6  210000    		ld	hl,c.r0
1122    11F9  E5        		push	hl
1123    11FA  210A00    		ld	hl,10
1124    11FD  E5        		push	hl
1125    11FE  CD0000    		call	c.ulrsh
1126    1201  E1        		pop	hl
1127    1202  23        		inc	hl
1128    1203  23        		inc	hl
1129    1204  4E        		ld	c,(hl)
1130    1205  23        		inc	hl
1131    1206  46        		ld	b,(hl)
1132    1207  C5        		push	bc
1133    1208  2B        		dec	hl
1134    1209  2B        		dec	hl
1135    120A  2B        		dec	hl
1136    120B  4E        		ld	c,(hl)
1137    120C  23        		inc	hl
1138    120D  46        		ld	b,(hl)
1139    120E  C5        		push	bc
1140    120F  DD66F1    		ld	h,(ix-15)
1141    1212  DD6EF0    		ld	l,(ix-16)
1142    1215  E5        		push	hl
1143    1216  DD66EF    		ld	h,(ix-17)
1144    1219  DD6EEE    		ld	l,(ix-18)
1145    121C  E5        		push	hl
1146    121D  218707    		ld	hl,L5421
1147    1220  CD0000    		call	_printf
1148    1223  F1        		pop	af
1149    1224  F1        		pop	af
1150    1225  F1        		pop	af
1151    1226  F1        		pop	af
1152                    	L1012:
1153                    	;  660                  }
1154                    	;  661          if ((csdreg[0] & 0xc0) == 0x40)
1155    1227  3A2212    		ld	a,(_csdreg)
1156    122A  6F        		ld	l,a
1157    122B  97        		sub	a
1158    122C  67        		ld	h,a
1159    122D  7D        		ld	a,l
1160    122E  E6C0      		and	192
1161    1230  6F        		ld	l,a
1162    1231  97        		sub	a
1163    1232  67        		ld	h,a
1164    1233  7D        		ld	a,l
1165    1234  FE40      		cp	64
1166    1236  2003      		jr	nz,L431
1167    1238  7C        		ld	a,h
1168    1239  FE00      		cp	0
1169                    	L431:
1170    123B  C22413    		jp	nz,L1112
1171                    	;  662                  {
1172                    	;  663                  printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
1173    123E  21AF07    		ld	hl,L5521
1174    1241  CD0000    		call	_printf
1175                    	;  664                  devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
1176                    	;  665                   + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1177    1244  DDE5      		push	ix
1178    1246  C1        		pop	bc
1179    1247  21F2FF    		ld	hl,65522
1180    124A  09        		add	hl,bc
1181    124B  E5        		push	hl
1182    124C  97        		sub	a
1183    124D  320000    		ld	(c.r0),a
1184    1250  320100    		ld	(c.r0+1),a
1185    1253  3A2A12    		ld	a,(_csdreg+8)
1186    1256  320200    		ld	(c.r0+2),a
1187    1259  97        		sub	a
1188    125A  320300    		ld	(c.r0+3),a
1189    125D  210000    		ld	hl,c.r0
1190    1260  E5        		push	hl
1191    1261  210800    		ld	hl,8
1192    1264  E5        		push	hl
1193    1265  CD0000    		call	c.llsh
1194    1268  97        		sub	a
1195    1269  320000    		ld	(c.r1),a
1196    126C  320100    		ld	(c.r1+1),a
1197    126F  3A2B12    		ld	a,(_csdreg+9)
1198    1272  320200    		ld	(c.r1+2),a
1199    1275  97        		sub	a
1200    1276  320300    		ld	(c.r1+3),a
1201    1279  210000    		ld	hl,c.r1
1202    127C  E5        		push	hl
1203    127D  CD0000    		call	c.ladd
1204    1280  3A2912    		ld	a,(_csdreg+7)
1205    1283  6F        		ld	l,a
1206    1284  97        		sub	a
1207    1285  67        		ld	h,a
1208    1286  7D        		ld	a,l
1209    1287  E63F      		and	63
1210    1289  6F        		ld	l,a
1211    128A  97        		sub	a
1212    128B  67        		ld	h,a
1213    128C  4D        		ld	c,l
1214    128D  44        		ld	b,h
1215    128E  78        		ld	a,b
1216    128F  87        		add	a,a
1217    1290  9F        		sbc	a,a
1218    1291  320000    		ld	(c.r1),a
1219    1294  320100    		ld	(c.r1+1),a
1220    1297  78        		ld	a,b
1221    1298  320300    		ld	(c.r1+3),a
1222    129B  79        		ld	a,c
1223    129C  320200    		ld	(c.r1+2),a
1224    129F  210000    		ld	hl,c.r1
1225    12A2  E5        		push	hl
1226    12A3  211000    		ld	hl,16
1227    12A6  E5        		push	hl
1228    12A7  CD0000    		call	c.llsh
1229    12AA  CD0000    		call	c.ladd
1230    12AD  3E01      		ld	a,1
1231    12AF  320200    		ld	(c.r1+2),a
1232    12B2  87        		add	a,a
1233    12B3  9F        		sbc	a,a
1234    12B4  320300    		ld	(c.r1+3),a
1235    12B7  320100    		ld	(c.r1+1),a
1236    12BA  320000    		ld	(c.r1),a
1237    12BD  210000    		ld	hl,c.r1
1238    12C0  E5        		push	hl
1239    12C1  CD0000    		call	c.ladd
1240    12C4  CD0000    		call	c.mvl
1241    12C7  F1        		pop	af
1242                    	;  666                  capacity = devsize << 9;
1243    12C8  DDE5      		push	ix
1244    12CA  C1        		pop	bc
1245    12CB  21EEFF    		ld	hl,65518
1246    12CE  09        		add	hl,bc
1247    12CF  E5        		push	hl
1248    12D0  DDE5      		push	ix
1249    12D2  C1        		pop	bc
1250    12D3  21F2FF    		ld	hl,65522
1251    12D6  09        		add	hl,bc
1252    12D7  CD0000    		call	c.0mvf
1253    12DA  210000    		ld	hl,c.r0
1254    12DD  E5        		push	hl
1255    12DE  210900    		ld	hl,9
1256    12E1  E5        		push	hl
1257    12E2  CD0000    		call	c.llsh
1258    12E5  CD0000    		call	c.mvl
1259    12E8  F1        		pop	af
1260                    	;  667                  printf(" Device capacity: %lu KByte, %lu MByte\n",
1261                    	;  668                    capacity, capacity >> 10);
1262    12E9  DDE5      		push	ix
1263    12EB  C1        		pop	bc
1264    12EC  21EEFF    		ld	hl,65518
1265    12EF  09        		add	hl,bc
1266    12F0  CD0000    		call	c.0mvf
1267    12F3  210000    		ld	hl,c.r0
1268    12F6  E5        		push	hl
1269    12F7  210A00    		ld	hl,10
1270    12FA  E5        		push	hl
1271    12FB  CD0000    		call	c.ulrsh
1272    12FE  E1        		pop	hl
1273    12FF  23        		inc	hl
1274    1300  23        		inc	hl
1275    1301  4E        		ld	c,(hl)
1276    1302  23        		inc	hl
1277    1303  46        		ld	b,(hl)
1278    1304  C5        		push	bc
1279    1305  2B        		dec	hl
1280    1306  2B        		dec	hl
1281    1307  2B        		dec	hl
1282    1308  4E        		ld	c,(hl)
1283    1309  23        		inc	hl
1284    130A  46        		ld	b,(hl)
1285    130B  C5        		push	bc
1286    130C  DD66F1    		ld	h,(ix-15)
1287    130F  DD6EF0    		ld	l,(ix-16)
1288    1312  E5        		push	hl
1289    1313  DD66EF    		ld	h,(ix-17)
1290    1316  DD6EEE    		ld	l,(ix-18)
1291    1319  E5        		push	hl
1292    131A  21E507    		ld	hl,L5621
1293    131D  CD0000    		call	_printf
1294    1320  F1        		pop	af
1295    1321  F1        		pop	af
1296    1322  F1        		pop	af
1297    1323  F1        		pop	af
1298                    	L1112:
1299                    	;  669                  }
1300                    	;  670          if ((csdreg[0] & 0xc0) == 0x80)
1301    1324  3A2212    		ld	a,(_csdreg)
1302    1327  6F        		ld	l,a
1303    1328  97        		sub	a
1304    1329  67        		ld	h,a
1305    132A  7D        		ld	a,l
1306    132B  E6C0      		and	192
1307    132D  6F        		ld	l,a
1308    132E  97        		sub	a
1309    132F  67        		ld	h,a
1310    1330  7D        		ld	a,l
1311    1331  FE80      		cp	128
1312    1333  2003      		jr	nz,L631
1313    1335  7C        		ld	a,h
1314    1336  FE00      		cp	0
1315                    	L631:
1316    1338  2006      		jr	nz,L1212
1317                    	;  671                  printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
1318    133A  210D08    		ld	hl,L5721
1319    133D  CD0000    		call	_printf
1320                    	L1212:
1321                    	;  672  
1322                    	;  673          printf("-----------\n");
1323    1340  213508    		ld	hl,L5031
1324    1343  CD0000    		call	_printf
1325                    	;  674          }
1326    1346  C30000    		jp	c.rets0
1327                    		.psect	_data
1328                    	L5131:
1329    0842  25        		.byte	37
1330    0843  30        		.byte	48
1331    0844  32        		.byte	50
1332    0845  78        		.byte	120
1333    0846  25        		.byte	37
1334    0847  30        		.byte	48
1335    0848  32        		.byte	50
1336    0849  78        		.byte	120
1337    084A  25        		.byte	37
1338    084B  30        		.byte	48
1339    084C  32        		.byte	50
1340    084D  78        		.byte	120
1341    084E  25        		.byte	37
1342    084F  30        		.byte	48
1343    0850  32        		.byte	50
1344    0851  78        		.byte	120
1345    0852  2D        		.byte	45
1346    0853  00        		.byte	0
1347                    	L5231:
1348    0854  25        		.byte	37
1349    0855  30        		.byte	48
1350    0856  32        		.byte	50
1351    0857  78        		.byte	120
1352    0858  25        		.byte	37
1353    0859  30        		.byte	48
1354    085A  32        		.byte	50
1355    085B  78        		.byte	120
1356    085C  2D        		.byte	45
1357    085D  00        		.byte	0
1358                    	L5331:
1359    085E  25        		.byte	37
1360    085F  30        		.byte	48
1361    0860  32        		.byte	50
1362    0861  78        		.byte	120
1363    0862  25        		.byte	37
1364    0863  30        		.byte	48
1365    0864  32        		.byte	50
1366    0865  78        		.byte	120
1367    0866  2D        		.byte	45
1368    0867  00        		.byte	0
1369                    	L5431:
1370    0868  25        		.byte	37
1371    0869  30        		.byte	48
1372    086A  32        		.byte	50
1373    086B  78        		.byte	120
1374    086C  25        		.byte	37
1375    086D  30        		.byte	48
1376    086E  32        		.byte	50
1377    086F  78        		.byte	120
1378    0870  2D        		.byte	45
1379    0871  00        		.byte	0
1380                    	L5531:
1381    0872  25        		.byte	37
1382    0873  30        		.byte	48
1383    0874  32        		.byte	50
1384    0875  78        		.byte	120
1385    0876  25        		.byte	37
1386    0877  30        		.byte	48
1387    0878  32        		.byte	50
1388    0879  78        		.byte	120
1389    087A  25        		.byte	37
1390    087B  30        		.byte	48
1391    087C  32        		.byte	50
1392    087D  78        		.byte	120
1393    087E  25        		.byte	37
1394    087F  30        		.byte	48
1395    0880  32        		.byte	50
1396    0881  78        		.byte	120
1397    0882  25        		.byte	37
1398    0883  30        		.byte	48
1399    0884  32        		.byte	50
1400    0885  78        		.byte	120
1401    0886  25        		.byte	37
1402    0887  30        		.byte	48
1403    0888  32        		.byte	50
1404    0889  78        		.byte	120
1405    088A  00        		.byte	0
1406                    	L5631:
1407    088B  0A        		.byte	10
1408    088C  20        		.byte	32
1409    088D  20        		.byte	32
1410    088E  5B        		.byte	91
1411    088F  00        		.byte	0
1412                    	L5731:
1413    0890  25        		.byte	37
1414    0891  30        		.byte	48
1415    0892  32        		.byte	50
1416    0893  78        		.byte	120
1417    0894  20        		.byte	32
1418    0895  00        		.byte	0
1419                    	L5041:
1420    0896  08        		.byte	8
1421    0897  5D        		.byte	93
1422    0898  00        		.byte	0
1423                    		.psect	_text
1424                    	;  675  
1425                    	;  676  /* print GUID (mixed endian format) */
1426                    	;  677  void prtguid(unsigned char *guidptr)
1427                    	;  678          {
1428                    	_prtguid:
1429    1349  CD0000    		call	c.savs
1430    134C  F5        		push	af
1431    134D  F5        		push	af
1432    134E  F5        		push	af
1433    134F  F5        		push	af
1434                    	;  679          int index;
1435                    	;  680  
1436                    	;  681          printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
1437    1350  DD6E04    		ld	l,(ix+4)
1438    1353  DD6605    		ld	h,(ix+5)
1439    1356  4E        		ld	c,(hl)
1440    1357  97        		sub	a
1441    1358  47        		ld	b,a
1442    1359  C5        		push	bc
1443    135A  DD6E04    		ld	l,(ix+4)
1444    135D  DD6605    		ld	h,(ix+5)
1445    1360  23        		inc	hl
1446    1361  4E        		ld	c,(hl)
1447    1362  97        		sub	a
1448    1363  47        		ld	b,a
1449    1364  C5        		push	bc
1450    1365  DD6E04    		ld	l,(ix+4)
1451    1368  DD6605    		ld	h,(ix+5)
1452    136B  23        		inc	hl
1453    136C  23        		inc	hl
1454    136D  4E        		ld	c,(hl)
1455    136E  97        		sub	a
1456    136F  47        		ld	b,a
1457    1370  C5        		push	bc
1458    1371  DD6E04    		ld	l,(ix+4)
1459    1374  DD6605    		ld	h,(ix+5)
1460    1377  23        		inc	hl
1461    1378  23        		inc	hl
1462    1379  23        		inc	hl
1463    137A  4E        		ld	c,(hl)
1464    137B  97        		sub	a
1465    137C  47        		ld	b,a
1466    137D  C5        		push	bc
1467    137E  214208    		ld	hl,L5131
1468    1381  CD0000    		call	_printf
1469    1384  F1        		pop	af
1470    1385  F1        		pop	af
1471    1386  F1        		pop	af
1472    1387  F1        		pop	af
1473                    	;  682          printf("%02x%02x-", guidptr[5], guidptr[4]);
1474    1388  DD6E04    		ld	l,(ix+4)
1475    138B  DD6605    		ld	h,(ix+5)
1476    138E  23        		inc	hl
1477    138F  23        		inc	hl
1478    1390  23        		inc	hl
1479    1391  23        		inc	hl
1480    1392  4E        		ld	c,(hl)
1481    1393  97        		sub	a
1482    1394  47        		ld	b,a
1483    1395  C5        		push	bc
1484    1396  DD6E04    		ld	l,(ix+4)
1485    1399  DD6605    		ld	h,(ix+5)
1486    139C  010500    		ld	bc,5
1487    139F  09        		add	hl,bc
1488    13A0  4E        		ld	c,(hl)
1489    13A1  97        		sub	a
1490    13A2  47        		ld	b,a
1491    13A3  C5        		push	bc
1492    13A4  215408    		ld	hl,L5231
1493    13A7  CD0000    		call	_printf
1494    13AA  F1        		pop	af
1495    13AB  F1        		pop	af
1496                    	;  683          printf("%02x%02x-", guidptr[7], guidptr[6]);
1497    13AC  DD6E04    		ld	l,(ix+4)
1498    13AF  DD6605    		ld	h,(ix+5)
1499    13B2  010600    		ld	bc,6
1500    13B5  09        		add	hl,bc
1501    13B6  4E        		ld	c,(hl)
1502    13B7  97        		sub	a
1503    13B8  47        		ld	b,a
1504    13B9  C5        		push	bc
1505    13BA  DD6E04    		ld	l,(ix+4)
1506    13BD  DD6605    		ld	h,(ix+5)
1507    13C0  010700    		ld	bc,7
1508    13C3  09        		add	hl,bc
1509    13C4  4E        		ld	c,(hl)
1510    13C5  97        		sub	a
1511    13C6  47        		ld	b,a
1512    13C7  C5        		push	bc
1513    13C8  215E08    		ld	hl,L5331
1514    13CB  CD0000    		call	_printf
1515    13CE  F1        		pop	af
1516    13CF  F1        		pop	af
1517                    	;  684          printf("%02x%02x-", guidptr[8], guidptr[9]);
1518    13D0  DD6E04    		ld	l,(ix+4)
1519    13D3  DD6605    		ld	h,(ix+5)
1520    13D6  010900    		ld	bc,9
1521    13D9  09        		add	hl,bc
1522    13DA  4E        		ld	c,(hl)
1523    13DB  97        		sub	a
1524    13DC  47        		ld	b,a
1525    13DD  C5        		push	bc
1526    13DE  DD6E04    		ld	l,(ix+4)
1527    13E1  DD6605    		ld	h,(ix+5)
1528    13E4  010800    		ld	bc,8
1529    13E7  09        		add	hl,bc
1530    13E8  4E        		ld	c,(hl)
1531    13E9  97        		sub	a
1532    13EA  47        		ld	b,a
1533    13EB  C5        		push	bc
1534    13EC  216808    		ld	hl,L5431
1535    13EF  CD0000    		call	_printf
1536    13F2  F1        		pop	af
1537    13F3  F1        		pop	af
1538                    	;  685          printf("%02x%02x%02x%02x%02x%02x",
1539                    	;  686                  guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
1540    13F4  DD6E04    		ld	l,(ix+4)
1541    13F7  DD6605    		ld	h,(ix+5)
1542    13FA  010F00    		ld	bc,15
1543    13FD  09        		add	hl,bc
1544    13FE  4E        		ld	c,(hl)
1545    13FF  97        		sub	a
1546    1400  47        		ld	b,a
1547    1401  C5        		push	bc
1548    1402  DD6E04    		ld	l,(ix+4)
1549    1405  DD6605    		ld	h,(ix+5)
1550    1408  010E00    		ld	bc,14
1551    140B  09        		add	hl,bc
1552    140C  4E        		ld	c,(hl)
1553    140D  97        		sub	a
1554    140E  47        		ld	b,a
1555    140F  C5        		push	bc
1556    1410  DD6E04    		ld	l,(ix+4)
1557    1413  DD6605    		ld	h,(ix+5)
1558    1416  010D00    		ld	bc,13
1559    1419  09        		add	hl,bc
1560    141A  4E        		ld	c,(hl)
1561    141B  97        		sub	a
1562    141C  47        		ld	b,a
1563    141D  C5        		push	bc
1564    141E  DD6E04    		ld	l,(ix+4)
1565    1421  DD6605    		ld	h,(ix+5)
1566    1424  010C00    		ld	bc,12
1567    1427  09        		add	hl,bc
1568    1428  4E        		ld	c,(hl)
1569    1429  97        		sub	a
1570    142A  47        		ld	b,a
1571    142B  C5        		push	bc
1572    142C  DD6E04    		ld	l,(ix+4)
1573    142F  DD6605    		ld	h,(ix+5)
1574    1432  010B00    		ld	bc,11
1575    1435  09        		add	hl,bc
1576    1436  4E        		ld	c,(hl)
1577    1437  97        		sub	a
1578    1438  47        		ld	b,a
1579    1439  C5        		push	bc
1580    143A  DD6E04    		ld	l,(ix+4)
1581    143D  DD6605    		ld	h,(ix+5)
1582    1440  010A00    		ld	bc,10
1583    1443  09        		add	hl,bc
1584    1444  4E        		ld	c,(hl)
1585    1445  97        		sub	a
1586    1446  47        		ld	b,a
1587    1447  C5        		push	bc
1588    1448  217208    		ld	hl,L5531
1589    144B  CD0000    		call	_printf
1590    144E  210C00    		ld	hl,12
1591    1451  39        		add	hl,sp
1592    1452  F9        		ld	sp,hl
1593                    	;  687          if (prthex)
1594    1453  2A3612    		ld	hl,(_prthex)
1595    1456  7C        		ld	a,h
1596    1457  B5        		or	l
1597    1458  2843      		jr	z,L1312
1598                    	;  688                  {
1599                    	;  689                  printf("\n  [");
1600    145A  218B08    		ld	hl,L5631
1601    145D  CD0000    		call	_printf
1602                    	;  690                  for (index = 0; index < 16; index++)
1603    1460  DD36F800  		ld	(ix-8),0
1604    1464  DD36F900  		ld	(ix-7),0
1605                    	L1412:
1606    1468  DD7EF8    		ld	a,(ix-8)
1607    146B  D610      		sub	16
1608    146D  DD7EF9    		ld	a,(ix-7)
1609    1470  DE00      		sbc	a,0
1610    1472  F29714    		jp	p,L1512
1611                    	;  691                          printf("%02x ", guidptr[index]);
1612    1475  DD6E04    		ld	l,(ix+4)
1613    1478  DD6605    		ld	h,(ix+5)
1614    147B  DD4EF8    		ld	c,(ix-8)
1615    147E  DD46F9    		ld	b,(ix-7)
1616    1481  09        		add	hl,bc
1617    1482  4E        		ld	c,(hl)
1618    1483  97        		sub	a
1619    1484  47        		ld	b,a
1620    1485  C5        		push	bc
1621    1486  219008    		ld	hl,L5731
1622    1489  CD0000    		call	_printf
1623    148C  F1        		pop	af
1624    148D  DD34F8    		inc	(ix-8)
1625    1490  2003      		jr	nz,L241
1626    1492  DD34F9    		inc	(ix-7)
1627                    	L241:
1628    1495  18D1      		jr	L1412
1629                    	L1512:
1630                    	;  692                  printf("\b]");
1631    1497  219608    		ld	hl,L5041
1632    149A  CD0000    		call	_printf
1633                    	L1312:
1634                    	;  693                  }
1635                    	;  694          }
1636    149D  C30000    		jp	c.rets
1637                    		.psect	_data
1638                    	L5141:
1639    0899  43        		.byte	67
1640    089A  61        		.byte	97
1641    089B  6E        		.byte	110
1642    089C  27        		.byte	39
1643    089D  74        		.byte	116
1644    089E  20        		.byte	32
1645    089F  72        		.byte	114
1646    08A0  65        		.byte	101
1647    08A1  61        		.byte	97
1648    08A2  64        		.byte	100
1649    08A3  20        		.byte	32
1650    08A4  47        		.byte	71
1651    08A5  50        		.byte	80
1652    08A6  54        		.byte	84
1653    08A7  20        		.byte	32
1654    08A8  65        		.byte	101
1655    08A9  6E        		.byte	110
1656    08AA  74        		.byte	116
1657    08AB  72        		.byte	114
1658    08AC  79        		.byte	121
1659    08AD  20        		.byte	32
1660    08AE  62        		.byte	98
1661    08AF  6C        		.byte	108
1662    08B0  6F        		.byte	111
1663    08B1  63        		.byte	99
1664    08B2  6B        		.byte	107
1665    08B3  0A        		.byte	10
1666    08B4  00        		.byte	0
1667                    	L5241:
1668    08B5  47        		.byte	71
1669    08B6  50        		.byte	80
1670    08B7  54        		.byte	84
1671    08B8  20        		.byte	32
1672    08B9  70        		.byte	112
1673    08BA  61        		.byte	97
1674    08BB  72        		.byte	114
1675    08BC  74        		.byte	116
1676    08BD  69        		.byte	105
1677    08BE  74        		.byte	116
1678    08BF  69        		.byte	105
1679    08C0  6F        		.byte	111
1680    08C1  6E        		.byte	110
1681    08C2  20        		.byte	32
1682    08C3  65        		.byte	101
1683    08C4  6E        		.byte	110
1684    08C5  74        		.byte	116
1685    08C6  72        		.byte	114
1686    08C7  79        		.byte	121
1687    08C8  20        		.byte	32
1688    08C9  25        		.byte	37
1689    08CA  64        		.byte	100
1690    08CB  3A        		.byte	58
1691    08CC  00        		.byte	0
1692                    	L5341:
1693    08CD  20        		.byte	32
1694    08CE  4E        		.byte	78
1695    08CF  6F        		.byte	111
1696    08D0  74        		.byte	116
1697    08D1  20        		.byte	32
1698    08D2  75        		.byte	117
1699    08D3  73        		.byte	115
1700    08D4  65        		.byte	101
1701    08D5  64        		.byte	100
1702    08D6  20        		.byte	32
1703    08D7  65        		.byte	101
1704    08D8  6E        		.byte	110
1705    08D9  74        		.byte	116
1706    08DA  72        		.byte	114
1707    08DB  79        		.byte	121
1708    08DC  0A        		.byte	10
1709    08DD  00        		.byte	0
1710                    	L5441:
1711    08DE  0A        		.byte	10
1712    08DF  20        		.byte	32
1713    08E0  20        		.byte	32
1714    08E1  50        		.byte	80
1715    08E2  61        		.byte	97
1716    08E3  72        		.byte	114
1717    08E4  74        		.byte	116
1718    08E5  69        		.byte	105
1719    08E6  74        		.byte	116
1720    08E7  69        		.byte	105
1721    08E8  6F        		.byte	111
1722    08E9  6E        		.byte	110
1723    08EA  20        		.byte	32
1724    08EB  74        		.byte	116
1725    08EC  79        		.byte	121
1726    08ED  70        		.byte	112
1727    08EE  65        		.byte	101
1728    08EF  20        		.byte	32
1729    08F0  47        		.byte	71
1730    08F1  55        		.byte	85
1731    08F2  49        		.byte	73
1732    08F3  44        		.byte	68
1733    08F4  3A        		.byte	58
1734    08F5  20        		.byte	32
1735    08F6  00        		.byte	0
1736                    	L5541:
1737    08F7  0A        		.byte	10
1738    08F8  20        		.byte	32
1739    08F9  20        		.byte	32
1740    08FA  55        		.byte	85
1741    08FB  6E        		.byte	110
1742    08FC  69        		.byte	105
1743    08FD  71        		.byte	113
1744    08FE  75        		.byte	117
1745    08FF  65        		.byte	101
1746    0900  20        		.byte	32
1747    0901  70        		.byte	112
1748    0902  61        		.byte	97
1749    0903  72        		.byte	114
1750    0904  74        		.byte	116
1751    0905  69        		.byte	105
1752    0906  74        		.byte	116
1753    0907  69        		.byte	105
1754    0908  6F        		.byte	111
1755    0909  6E        		.byte	110
1756    090A  20        		.byte	32
1757    090B  47        		.byte	71
1758    090C  55        		.byte	85
1759    090D  49        		.byte	73
1760    090E  44        		.byte	68
1761    090F  3A        		.byte	58
1762    0910  20        		.byte	32
1763    0911  00        		.byte	0
1764                    	L5641:
1765    0912  0A        		.byte	10
1766    0913  20        		.byte	32
1767    0914  20        		.byte	32
1768    0915  46        		.byte	70
1769    0916  69        		.byte	105
1770    0917  72        		.byte	114
1771    0918  73        		.byte	115
1772    0919  74        		.byte	116
1773    091A  20        		.byte	32
1774    091B  4C        		.byte	76
1775    091C  42        		.byte	66
1776    091D  41        		.byte	65
1777    091E  3A        		.byte	58
1778    091F  20        		.byte	32
1779    0920  00        		.byte	0
1780                    	L5741:
1781    0921  25        		.byte	37
1782    0922  6C        		.byte	108
1783    0923  75        		.byte	117
1784    0924  00        		.byte	0
1785                    	L5051:
1786    0925  20        		.byte	32
1787    0926  5B        		.byte	91
1788    0927  00        		.byte	0
1789                    	L5151:
1790    0928  25        		.byte	37
1791    0929  30        		.byte	48
1792    092A  32        		.byte	50
1793    092B  78        		.byte	120
1794    092C  20        		.byte	32
1795    092D  00        		.byte	0
1796                    	L5251:
1797    092E  08        		.byte	8
1798    092F  5D        		.byte	93
1799    0930  00        		.byte	0
1800                    	L5351:
1801    0931  0A        		.byte	10
1802    0932  20        		.byte	32
1803    0933  20        		.byte	32
1804    0934  4C        		.byte	76
1805    0935  61        		.byte	97
1806    0936  73        		.byte	115
1807    0937  74        		.byte	116
1808    0938  20        		.byte	32
1809    0939  4C        		.byte	76
1810    093A  42        		.byte	66
1811    093B  41        		.byte	65
1812    093C  3A        		.byte	58
1813    093D  20        		.byte	32
1814    093E  00        		.byte	0
1815                    	L5451:
1816    093F  25        		.byte	37
1817    0940  6C        		.byte	108
1818    0941  75        		.byte	117
1819    0942  2C        		.byte	44
1820    0943  20        		.byte	32
1821    0944  73        		.byte	115
1822    0945  69        		.byte	105
1823    0946  7A        		.byte	122
1824    0947  65        		.byte	101
1825    0948  20        		.byte	32
1826    0949  25        		.byte	37
1827    094A  6C        		.byte	108
1828    094B  75        		.byte	117
1829    094C  20        		.byte	32
1830    094D  4D        		.byte	77
1831    094E  42        		.byte	66
1832    094F  79        		.byte	121
1833    0950  74        		.byte	116
1834    0951  65        		.byte	101
1835    0952  00        		.byte	0
1836                    	L5551:
1837    0953  20        		.byte	32
1838    0954  5B        		.byte	91
1839    0955  00        		.byte	0
1840                    	L5651:
1841    0956  25        		.byte	37
1842    0957  30        		.byte	48
1843    0958  32        		.byte	50
1844    0959  78        		.byte	120
1845    095A  20        		.byte	32
1846    095B  00        		.byte	0
1847                    	L5751:
1848    095C  08        		.byte	8
1849    095D  5D        		.byte	93
1850    095E  00        		.byte	0
1851                    	L5061:
1852    095F  0A        		.byte	10
1853    0960  20        		.byte	32
1854    0961  20        		.byte	32
1855    0962  41        		.byte	65
1856    0963  74        		.byte	116
1857    0964  74        		.byte	116
1858    0965  72        		.byte	114
1859    0966  69        		.byte	105
1860    0967  62        		.byte	98
1861    0968  75        		.byte	117
1862    0969  74        		.byte	116
1863    096A  65        		.byte	101
1864    096B  20        		.byte	32
1865    096C  66        		.byte	102
1866    096D  6C        		.byte	108
1867    096E  61        		.byte	97
1868    096F  67        		.byte	103
1869    0970  73        		.byte	115
1870    0971  3A        		.byte	58
1871    0972  20        		.byte	32
1872    0973  5B        		.byte	91
1873    0974  00        		.byte	0
1874                    	L5161:
1875    0975  25        		.byte	37
1876    0976  30        		.byte	48
1877    0977  32        		.byte	50
1878    0978  78        		.byte	120
1879    0979  20        		.byte	32
1880    097A  00        		.byte	0
1881                    	L5261:
1882    097B  08        		.byte	8
1883    097C  5D        		.byte	93
1884    097D  0A        		.byte	10
1885    097E  20        		.byte	32
1886    097F  20        		.byte	32
1887    0980  50        		.byte	80
1888    0981  61        		.byte	97
1889    0982  72        		.byte	114
1890    0983  74        		.byte	116
1891    0984  69        		.byte	105
1892    0985  74        		.byte	116
1893    0986  69        		.byte	105
1894    0987  6F        		.byte	111
1895    0988  6E        		.byte	110
1896    0989  20        		.byte	32
1897    098A  6E        		.byte	110
1898    098B  61        		.byte	97
1899    098C  6D        		.byte	109
1900    098D  65        		.byte	101
1901    098E  3A        		.byte	58
1902    098F  20        		.byte	32
1903    0990  20        		.byte	32
1904    0991  00        		.byte	0
1905                    	L5361:
1906    0992  6E        		.byte	110
1907    0993  61        		.byte	97
1908    0994  6D        		.byte	109
1909    0995  65        		.byte	101
1910    0996  20        		.byte	32
1911    0997  66        		.byte	102
1912    0998  69        		.byte	105
1913    0999  65        		.byte	101
1914    099A  6C        		.byte	108
1915    099B  64        		.byte	100
1916    099C  20        		.byte	32
1917    099D  65        		.byte	101
1918    099E  6D        		.byte	109
1919    099F  70        		.byte	112
1920    09A0  74        		.byte	116
1921    09A1  79        		.byte	121
1922    09A2  00        		.byte	0
1923                    	L5461:
1924    09A3  0A        		.byte	10
1925    09A4  00        		.byte	0
1926                    	L5561:
1927    09A5  20        		.byte	32
1928    09A6  20        		.byte	32
1929    09A7  20        		.byte	32
1930    09A8  5B        		.byte	91
1931    09A9  00        		.byte	0
1932                    	L5661:
1933    09AA  0A        		.byte	10
1934    09AB  20        		.byte	32
1935    09AC  20        		.byte	32
1936    09AD  20        		.byte	32
1937    09AE  20        		.byte	32
1938    09AF  00        		.byte	0
1939                    	L5761:
1940    09B0  25        		.byte	37
1941    09B1  30        		.byte	48
1942    09B2  32        		.byte	50
1943    09B3  78        		.byte	120
1944    09B4  20        		.byte	32
1945    09B5  00        		.byte	0
1946                    	L5071:
1947    09B6  08        		.byte	8
1948    09B7  5D        		.byte	93
1949    09B8  0A        		.byte	10
1950    09B9  00        		.byte	0
1951                    		.psect	_text
1952                    	;  695  
1953                    	;  696  /* print GPT entry */
1954                    	;  697  void prtgptent(unsigned int entryno)
1955                    	;  698          {
1956                    	_prtgptent:
1957    14A0  CD0000    		call	c.savs
1958    14A3  21E4FF    		ld	hl,65508
1959    14A6  39        		add	hl,sp
1960    14A7  F9        		ld	sp,hl
1961                    	;  699          int index;
1962                    	;  700          int entryidx;
1963                    	;  701          int hasname;
1964                    	;  702          unsigned int block;
1965                    	;  703          unsigned char *rxdata;
1966                    	;  704          unsigned char *entryptr;
1967                    	;  705          unsigned char tstzero = 0;
1968    14A8  DD36ED00  		ld	(ix-19),0
1969                    	;  706          unsigned long flba;
1970                    	;  707          unsigned long llba;
1971                    	;  708  
1972                    	;  709          block = 2 + (entryno / 4);
1973    14AC  DD6E04    		ld	l,(ix+4)
1974    14AF  DD6605    		ld	h,(ix+5)
1975    14B2  E5        		push	hl
1976    14B3  210400    		ld	hl,4
1977    14B6  E5        		push	hl
1978    14B7  CD0000    		call	c.udiv
1979    14BA  E1        		pop	hl
1980    14BB  23        		inc	hl
1981    14BC  23        		inc	hl
1982    14BD  DD75F2    		ld	(ix-14),l
1983    14C0  DD74F3    		ld	(ix-13),h
1984                    	;  710          if ((blockno != block) || YES /*!rxtxptr*/)
1985                    	;  711                  {
1986                    	;  712                  blockno = block;
1987    14C3  97        		sub	a
1988    14C4  323A12    		ld	(_blockno),a
1989    14C7  323B12    		ld	(_blockno+1),a
1990    14CA  DD7EF2    		ld	a,(ix-14)
1991    14CD  323C12    		ld	(_blockno+2),a
1992    14D0  DD7EF3    		ld	a,(ix-13)
1993    14D3  323D12    		ld	(_blockno+3),a
1994                    	;  713                  if (!sdread(NO))
1995    14D6  210000    		ld	hl,0
1996    14D9  CD5E09    		call	_sdread
1997    14DC  79        		ld	a,c
1998    14DD  B0        		or	b
1999    14DE  2009      		jr	nz,L1022
2000                    	;  714                          {
2001                    	;  715                          printf("Can't read GPT entry block\n");
2002    14E0  219908    		ld	hl,L5141
2003    14E3  CD0000    		call	_printf
2004                    	;  716                          return;
2005    14E6  C30000    		jp	c.rets
2006                    	L1022:
2007                    	;  717                          }
2008                    	;  718                  }
2009                    	;  719          rxdata = dataptr;
2010    14E9  3A3E12    		ld	a,(_dataptr)
2011    14EC  DD77F0    		ld	(ix-16),a
2012    14EF  3A3F12    		ld	a,(_dataptr+1)
2013    14F2  DD77F1    		ld	(ix-15),a
2014                    	;  720          entryptr = rxdata + (128 * (entryno % 4));
2015    14F5  DD6E04    		ld	l,(ix+4)
2016    14F8  DD6605    		ld	h,(ix+5)
2017    14FB  E5        		push	hl
2018    14FC  210400    		ld	hl,4
2019    14FF  E5        		push	hl
2020    1500  CD0000    		call	c.umod
2021    1503  218000    		ld	hl,128
2022    1506  E5        		push	hl
2023    1507  CD0000    		call	c.imul
2024    150A  E1        		pop	hl
2025    150B  DD4EF0    		ld	c,(ix-16)
2026    150E  DD46F1    		ld	b,(ix-15)
2027    1511  09        		add	hl,bc
2028    1512  DD75EE    		ld	(ix-18),l
2029    1515  DD74EF    		ld	(ix-17),h
2030                    	;  721          for (index = 0; index < 16; index++)
2031    1518  DD36F800  		ld	(ix-8),0
2032    151C  DD36F900  		ld	(ix-7),0
2033                    	L1222:
2034    1520  DD7EF8    		ld	a,(ix-8)
2035    1523  D610      		sub	16
2036    1525  DD7EF9    		ld	a,(ix-7)
2037    1528  DE00      		sbc	a,0
2038    152A  F24B15    		jp	p,L1322
2039                    	;  722                  tstzero |= entryptr[index];
2040    152D  DD6EEE    		ld	l,(ix-18)
2041    1530  DD66EF    		ld	h,(ix-17)
2042    1533  DD4EF8    		ld	c,(ix-8)
2043    1536  DD46F9    		ld	b,(ix-7)
2044    1539  09        		add	hl,bc
2045    153A  DD7EED    		ld	a,(ix-19)
2046    153D  B6        		or	(hl)
2047    153E  DD77ED    		ld	(ix-19),a
2048    1541  DD34F8    		inc	(ix-8)
2049    1544  2003      		jr	nz,L641
2050    1546  DD34F9    		inc	(ix-7)
2051                    	L641:
2052    1549  18D5      		jr	L1222
2053                    	L1322:
2054                    	;  723          printf("GPT partition entry %d:", entryno + 1);
2055    154B  DD6E04    		ld	l,(ix+4)
2056    154E  DD6605    		ld	h,(ix+5)
2057    1551  23        		inc	hl
2058    1552  E5        		push	hl
2059    1553  21B508    		ld	hl,L5241
2060    1556  CD0000    		call	_printf
2061    1559  F1        		pop	af
2062                    	;  724          if (!tstzero)
2063    155A  DD7EED    		ld	a,(ix-19)
2064    155D  B7        		or	a
2065    155E  2009      		jr	nz,L1622
2066                    	;  725                  {
2067                    	;  726                  printf(" Not used entry\n");
2068    1560  21CD08    		ld	hl,L5341
2069    1563  CD0000    		call	_printf
2070                    	;  727                  return;
2071    1566  C30000    		jp	c.rets
2072                    	L1622:
2073                    	;  728                  }
2074                    	;  729          printf("\n  Partition type GUID: ");
2075    1569  21DE08    		ld	hl,L5441
2076    156C  CD0000    		call	_printf
2077                    	;  730          prtguid(entryptr);
2078    156F  DD6EEE    		ld	l,(ix-18)
2079    1572  DD66EF    		ld	h,(ix-17)
2080    1575  CD4913    		call	_prtguid
2081                    	;  731          printf("\n  Unique partition GUID: ");
2082    1578  21F708    		ld	hl,L5541
2083    157B  CD0000    		call	_printf
2084                    	;  732          prtguid(entryptr + 16);
2085    157E  DD6EEE    		ld	l,(ix-18)
2086    1581  DD66EF    		ld	h,(ix-17)
2087    1584  011000    		ld	bc,16
2088    1587  09        		add	hl,bc
2089    1588  CD4913    		call	_prtguid
2090                    	;  733          printf("\n  First LBA: ");
2091    158B  211209    		ld	hl,L5641
2092    158E  CD0000    		call	_printf
2093                    	;  734          /* lower 32 bits of LBA should be sufficient (I hope) */
2094                    	;  735          flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
2095                    	;  736                  ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
2096    1591  DDE5      		push	ix
2097    1593  C1        		pop	bc
2098    1594  21E8FF    		ld	hl,65512
2099    1597  09        		add	hl,bc
2100    1598  E5        		push	hl
2101    1599  DD6EEE    		ld	l,(ix-18)
2102    159C  DD66EF    		ld	h,(ix-17)
2103    159F  012000    		ld	bc,32
2104    15A2  09        		add	hl,bc
2105    15A3  4D        		ld	c,l
2106    15A4  44        		ld	b,h
2107    15A5  97        		sub	a
2108    15A6  320000    		ld	(c.r0),a
2109    15A9  320100    		ld	(c.r0+1),a
2110    15AC  0A        		ld	a,(bc)
2111    15AD  320200    		ld	(c.r0+2),a
2112    15B0  97        		sub	a
2113    15B1  320300    		ld	(c.r0+3),a
2114    15B4  210000    		ld	hl,c.r0
2115    15B7  E5        		push	hl
2116    15B8  DD6EEE    		ld	l,(ix-18)
2117    15BB  DD66EF    		ld	h,(ix-17)
2118    15BE  012100    		ld	bc,33
2119    15C1  09        		add	hl,bc
2120    15C2  4D        		ld	c,l
2121    15C3  44        		ld	b,h
2122    15C4  97        		sub	a
2123    15C5  320000    		ld	(c.r1),a
2124    15C8  320100    		ld	(c.r1+1),a
2125    15CB  0A        		ld	a,(bc)
2126    15CC  320200    		ld	(c.r1+2),a
2127    15CF  97        		sub	a
2128    15D0  320300    		ld	(c.r1+3),a
2129    15D3  210000    		ld	hl,c.r1
2130    15D6  E5        		push	hl
2131    15D7  210800    		ld	hl,8
2132    15DA  E5        		push	hl
2133    15DB  CD0000    		call	c.llsh
2134    15DE  CD0000    		call	c.ladd
2135    15E1  DD6EEE    		ld	l,(ix-18)
2136    15E4  DD66EF    		ld	h,(ix-17)
2137    15E7  012200    		ld	bc,34
2138    15EA  09        		add	hl,bc
2139    15EB  4D        		ld	c,l
2140    15EC  44        		ld	b,h
2141    15ED  97        		sub	a
2142    15EE  320000    		ld	(c.r1),a
2143    15F1  320100    		ld	(c.r1+1),a
2144    15F4  0A        		ld	a,(bc)
2145    15F5  320200    		ld	(c.r1+2),a
2146    15F8  97        		sub	a
2147    15F9  320300    		ld	(c.r1+3),a
2148    15FC  210000    		ld	hl,c.r1
2149    15FF  E5        		push	hl
2150    1600  211000    		ld	hl,16
2151    1603  E5        		push	hl
2152    1604  CD0000    		call	c.llsh
2153    1607  CD0000    		call	c.ladd
2154    160A  DD6EEE    		ld	l,(ix-18)
2155    160D  DD66EF    		ld	h,(ix-17)
2156    1610  012300    		ld	bc,35
2157    1613  09        		add	hl,bc
2158    1614  4D        		ld	c,l
2159    1615  44        		ld	b,h
2160    1616  97        		sub	a
2161    1617  320000    		ld	(c.r1),a
2162    161A  320100    		ld	(c.r1+1),a
2163    161D  0A        		ld	a,(bc)
2164    161E  320200    		ld	(c.r1+2),a
2165    1621  97        		sub	a
2166    1622  320300    		ld	(c.r1+3),a
2167    1625  210000    		ld	hl,c.r1
2168    1628  E5        		push	hl
2169    1629  211800    		ld	hl,24
2170    162C  E5        		push	hl
2171    162D  CD0000    		call	c.llsh
2172    1630  CD0000    		call	c.ladd
2173    1633  CD0000    		call	c.mvl
2174    1636  F1        		pop	af
2175                    	;  737          printf("%lu", flba);
2176    1637  DD66EB    		ld	h,(ix-21)
2177    163A  DD6EEA    		ld	l,(ix-22)
2178    163D  E5        		push	hl
2179    163E  DD66E9    		ld	h,(ix-23)
2180    1641  DD6EE8    		ld	l,(ix-24)
2181    1644  E5        		push	hl
2182    1645  212109    		ld	hl,L5741
2183    1648  CD0000    		call	_printf
2184    164B  F1        		pop	af
2185    164C  F1        		pop	af
2186                    	;  738          if (prthex)
2187    164D  2A3612    		ld	hl,(_prthex)
2188    1650  7C        		ld	a,h
2189    1651  B5        		or	l
2190    1652  2843      		jr	z,L1722
2191                    	;  739                  {
2192                    	;  740                  printf(" [");
2193    1654  212509    		ld	hl,L5051
2194    1657  CD0000    		call	_printf
2195                    	;  741                  for (index = 32; index < (32 + 8); index++)
2196    165A  DD36F820  		ld	(ix-8),32
2197    165E  DD36F900  		ld	(ix-7),0
2198                    	L1032:
2199    1662  DD7EF8    		ld	a,(ix-8)
2200    1665  D628      		sub	40
2201    1667  DD7EF9    		ld	a,(ix-7)
2202    166A  DE00      		sbc	a,0
2203    166C  F29116    		jp	p,L1132
2204                    	;  742                          printf("%02x ", entryptr[index]);
2205    166F  DD6EEE    		ld	l,(ix-18)
2206    1672  DD66EF    		ld	h,(ix-17)
2207    1675  DD4EF8    		ld	c,(ix-8)
2208    1678  DD46F9    		ld	b,(ix-7)
2209    167B  09        		add	hl,bc
2210    167C  4E        		ld	c,(hl)
2211    167D  97        		sub	a
2212    167E  47        		ld	b,a
2213    167F  C5        		push	bc
2214    1680  212809    		ld	hl,L5151
2215    1683  CD0000    		call	_printf
2216    1686  F1        		pop	af
2217    1687  DD34F8    		inc	(ix-8)
2218    168A  2003      		jr	nz,L051
2219    168C  DD34F9    		inc	(ix-7)
2220                    	L051:
2221    168F  18D1      		jr	L1032
2222                    	L1132:
2223                    	;  743                  printf("\b]");
2224    1691  212E09    		ld	hl,L5251
2225    1694  CD0000    		call	_printf
2226                    	L1722:
2227                    	;  744                  }
2228                    	;  745          printf("\n  Last LBA: ");
2229    1697  213109    		ld	hl,L5351
2230    169A  CD0000    		call	_printf
2231                    	;  746          /* lower 32 bits of LBA should be sufficient (I hope) */
2232                    	;  747          llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
2233                    	;  748                  ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
2234    169D  DDE5      		push	ix
2235    169F  C1        		pop	bc
2236    16A0  21E4FF    		ld	hl,65508
2237    16A3  09        		add	hl,bc
2238    16A4  E5        		push	hl
2239    16A5  DD6EEE    		ld	l,(ix-18)
2240    16A8  DD66EF    		ld	h,(ix-17)
2241    16AB  012800    		ld	bc,40
2242    16AE  09        		add	hl,bc
2243    16AF  4D        		ld	c,l
2244    16B0  44        		ld	b,h
2245    16B1  97        		sub	a
2246    16B2  320000    		ld	(c.r0),a
2247    16B5  320100    		ld	(c.r0+1),a
2248    16B8  0A        		ld	a,(bc)
2249    16B9  320200    		ld	(c.r0+2),a
2250    16BC  97        		sub	a
2251    16BD  320300    		ld	(c.r0+3),a
2252    16C0  210000    		ld	hl,c.r0
2253    16C3  E5        		push	hl
2254    16C4  DD6EEE    		ld	l,(ix-18)
2255    16C7  DD66EF    		ld	h,(ix-17)
2256    16CA  012900    		ld	bc,41
2257    16CD  09        		add	hl,bc
2258    16CE  4D        		ld	c,l
2259    16CF  44        		ld	b,h
2260    16D0  97        		sub	a
2261    16D1  320000    		ld	(c.r1),a
2262    16D4  320100    		ld	(c.r1+1),a
2263    16D7  0A        		ld	a,(bc)
2264    16D8  320200    		ld	(c.r1+2),a
2265    16DB  97        		sub	a
2266    16DC  320300    		ld	(c.r1+3),a
2267    16DF  210000    		ld	hl,c.r1
2268    16E2  E5        		push	hl
2269    16E3  210800    		ld	hl,8
2270    16E6  E5        		push	hl
2271    16E7  CD0000    		call	c.llsh
2272    16EA  CD0000    		call	c.ladd
2273    16ED  DD6EEE    		ld	l,(ix-18)
2274    16F0  DD66EF    		ld	h,(ix-17)
2275    16F3  012A00    		ld	bc,42
2276    16F6  09        		add	hl,bc
2277    16F7  4D        		ld	c,l
2278    16F8  44        		ld	b,h
2279    16F9  97        		sub	a
2280    16FA  320000    		ld	(c.r1),a
2281    16FD  320100    		ld	(c.r1+1),a
2282    1700  0A        		ld	a,(bc)
2283    1701  320200    		ld	(c.r1+2),a
2284    1704  97        		sub	a
2285    1705  320300    		ld	(c.r1+3),a
2286    1708  210000    		ld	hl,c.r1
2287    170B  E5        		push	hl
2288    170C  211000    		ld	hl,16
2289    170F  E5        		push	hl
2290    1710  CD0000    		call	c.llsh
2291    1713  CD0000    		call	c.ladd
2292    1716  DD6EEE    		ld	l,(ix-18)
2293    1719  DD66EF    		ld	h,(ix-17)
2294    171C  012B00    		ld	bc,43
2295    171F  09        		add	hl,bc
2296    1720  4D        		ld	c,l
2297    1721  44        		ld	b,h
2298    1722  97        		sub	a
2299    1723  320000    		ld	(c.r1),a
2300    1726  320100    		ld	(c.r1+1),a
2301    1729  0A        		ld	a,(bc)
2302    172A  320200    		ld	(c.r1+2),a
2303    172D  97        		sub	a
2304    172E  320300    		ld	(c.r1+3),a
2305    1731  210000    		ld	hl,c.r1
2306    1734  E5        		push	hl
2307    1735  211800    		ld	hl,24
2308    1738  E5        		push	hl
2309    1739  CD0000    		call	c.llsh
2310    173C  CD0000    		call	c.ladd
2311    173F  CD0000    		call	c.mvl
2312    1742  F1        		pop	af
2313                    	;  749          printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
2314    1743  DDE5      		push	ix
2315    1745  C1        		pop	bc
2316    1746  21E4FF    		ld	hl,65508
2317    1749  09        		add	hl,bc
2318    174A  CD0000    		call	c.0mvf
2319    174D  210000    		ld	hl,c.r0
2320    1750  E5        		push	hl
2321    1751  DDE5      		push	ix
2322    1753  C1        		pop	bc
2323    1754  21E8FF    		ld	hl,65512
2324    1757  09        		add	hl,bc
2325    1758  E5        		push	hl
2326    1759  CD0000    		call	c.lsub
2327    175C  210B00    		ld	hl,11
2328    175F  E5        		push	hl
2329    1760  CD0000    		call	c.ulrsh
2330    1763  E1        		pop	hl
2331    1764  23        		inc	hl
2332    1765  23        		inc	hl
2333    1766  4E        		ld	c,(hl)
2334    1767  23        		inc	hl
2335    1768  46        		ld	b,(hl)
2336    1769  C5        		push	bc
2337    176A  2B        		dec	hl
2338    176B  2B        		dec	hl
2339    176C  2B        		dec	hl
2340    176D  4E        		ld	c,(hl)
2341    176E  23        		inc	hl
2342    176F  46        		ld	b,(hl)
2343    1770  C5        		push	bc
2344    1771  DD66E7    		ld	h,(ix-25)
2345    1774  DD6EE6    		ld	l,(ix-26)
2346    1777  E5        		push	hl
2347    1778  DD66E5    		ld	h,(ix-27)
2348    177B  DD6EE4    		ld	l,(ix-28)
2349    177E  E5        		push	hl
2350    177F  213F09    		ld	hl,L5451
2351    1782  CD0000    		call	_printf
2352    1785  F1        		pop	af
2353    1786  F1        		pop	af
2354    1787  F1        		pop	af
2355    1788  F1        		pop	af
2356                    	;  750          if (prthex)
2357    1789  2A3612    		ld	hl,(_prthex)
2358    178C  7C        		ld	a,h
2359    178D  B5        		or	l
2360    178E  2843      		jr	z,L1432
2361                    	;  751                  {
2362                    	;  752                  printf(" [");
2363    1790  215309    		ld	hl,L5551
2364    1793  CD0000    		call	_printf
2365                    	;  753                  for (index = 40; index < (40 + 8); index++)
2366    1796  DD36F828  		ld	(ix-8),40
2367    179A  DD36F900  		ld	(ix-7),0
2368                    	L1532:
2369    179E  DD7EF8    		ld	a,(ix-8)
2370    17A1  D630      		sub	48
2371    17A3  DD7EF9    		ld	a,(ix-7)
2372    17A6  DE00      		sbc	a,0
2373    17A8  F2CD17    		jp	p,L1632
2374                    	;  754                          printf("%02x ", entryptr[index]);
2375    17AB  DD6EEE    		ld	l,(ix-18)
2376    17AE  DD66EF    		ld	h,(ix-17)
2377    17B1  DD4EF8    		ld	c,(ix-8)
2378    17B4  DD46F9    		ld	b,(ix-7)
2379    17B7  09        		add	hl,bc
2380    17B8  4E        		ld	c,(hl)
2381    17B9  97        		sub	a
2382    17BA  47        		ld	b,a
2383    17BB  C5        		push	bc
2384    17BC  215609    		ld	hl,L5651
2385    17BF  CD0000    		call	_printf
2386    17C2  F1        		pop	af
2387    17C3  DD34F8    		inc	(ix-8)
2388    17C6  2003      		jr	nz,L251
2389    17C8  DD34F9    		inc	(ix-7)
2390                    	L251:
2391    17CB  18D1      		jr	L1532
2392                    	L1632:
2393                    	;  755                  printf("\b]");
2394    17CD  215C09    		ld	hl,L5751
2395    17D0  CD0000    		call	_printf
2396                    	L1432:
2397                    	;  756                  }
2398                    	;  757          printf("\n  Attribute flags: [");
2399    17D3  215F09    		ld	hl,L5061
2400    17D6  CD0000    		call	_printf
2401                    	;  758          /* bits 0 - 2 and 60 - 63 should be decoded */
2402                    	;  759          for (index = 0; index < 8; index++)
2403    17D9  DD36F800  		ld	(ix-8),0
2404    17DD  DD36F900  		ld	(ix-7),0
2405                    	L1142:
2406    17E1  DD7EF8    		ld	a,(ix-8)
2407    17E4  D608      		sub	8
2408    17E6  DD7EF9    		ld	a,(ix-7)
2409    17E9  DE00      		sbc	a,0
2410    17EB  F22018    		jp	p,L1242
2411                    	;  760                  {
2412                    	;  761                  entryidx = index + 48;
2413    17EE  DD6EF8    		ld	l,(ix-8)
2414    17F1  DD66F9    		ld	h,(ix-7)
2415    17F4  013000    		ld	bc,48
2416    17F7  09        		add	hl,bc
2417    17F8  DD75F6    		ld	(ix-10),l
2418    17FB  DD74F7    		ld	(ix-9),h
2419                    	;  762                  printf("%02x ", entryptr[entryidx]);
2420    17FE  DD6EEE    		ld	l,(ix-18)
2421    1801  DD66EF    		ld	h,(ix-17)
2422    1804  DD4EF6    		ld	c,(ix-10)
2423    1807  DD46F7    		ld	b,(ix-9)
2424    180A  09        		add	hl,bc
2425    180B  4E        		ld	c,(hl)
2426    180C  97        		sub	a
2427    180D  47        		ld	b,a
2428    180E  C5        		push	bc
2429    180F  217509    		ld	hl,L5161
2430    1812  CD0000    		call	_printf
2431    1815  F1        		pop	af
2432                    	;  763          }
2433    1816  DD34F8    		inc	(ix-8)
2434    1819  2003      		jr	nz,L451
2435    181B  DD34F9    		inc	(ix-7)
2436                    	L451:
2437    181E  18C1      		jr	L1142
2438                    	L1242:
2439                    	;  764          printf("\b]\n  Partition name:  ");
2440    1820  217B09    		ld	hl,L5261
2441    1823  CD0000    		call	_printf
2442                    	;  765          /* partition name is in UTF-16LE code units */
2443                    	;  766          hasname = NO;
2444    1826  DD36F400  		ld	(ix-12),0
2445    182A  DD36F500  		ld	(ix-11),0
2446                    	;  767          for (index = 0; index < 72; index += 2)
2447    182E  DD36F800  		ld	(ix-8),0
2448    1832  DD36F900  		ld	(ix-7),0
2449                    	L1542:
2450    1836  DD7EF8    		ld	a,(ix-8)
2451    1839  D648      		sub	72
2452    183B  DD7EF9    		ld	a,(ix-7)
2453    183E  DE00      		sbc	a,0
2454    1840  F2CF18    		jp	p,L1642
2455                    	;  768                  {
2456                    	;  769                  entryidx = index + 56;
2457    1843  DD6EF8    		ld	l,(ix-8)
2458    1846  DD66F9    		ld	h,(ix-7)
2459    1849  013800    		ld	bc,56
2460    184C  09        		add	hl,bc
2461    184D  DD75F6    		ld	(ix-10),l
2462    1850  DD74F7    		ld	(ix-9),h
2463                    	;  770                  if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
2464    1853  DD6EEE    		ld	l,(ix-18)
2465    1856  DD66EF    		ld	h,(ix-17)
2466    1859  DD4EF6    		ld	c,(ix-10)
2467    185C  DD46F7    		ld	b,(ix-9)
2468    185F  09        		add	hl,bc
2469    1860  6E        		ld	l,(hl)
2470    1861  E5        		push	hl
2471    1862  DD6EF6    		ld	l,(ix-10)
2472    1865  DD66F7    		ld	h,(ix-9)
2473    1868  23        		inc	hl
2474    1869  DD4EEE    		ld	c,(ix-18)
2475    186C  DD46EF    		ld	b,(ix-17)
2476    186F  09        		add	hl,bc
2477    1870  C1        		pop	bc
2478    1871  79        		ld	a,c
2479    1872  B6        		or	(hl)
2480    1873  4F        		ld	c,a
2481    1874  CACF18    		jp	z,L1642
2482                    	;  771                          break;
2483                    	;  772                  if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
2484    1877  DD6EEE    		ld	l,(ix-18)
2485    187A  DD66EF    		ld	h,(ix-17)
2486    187D  DD4EF6    		ld	c,(ix-10)
2487    1880  DD46F7    		ld	b,(ix-9)
2488    1883  09        		add	hl,bc
2489    1884  7E        		ld	a,(hl)
2490    1885  FE20      		cp	32
2491    1887  3827      		jr	c,L1252
2492    1889  DD6EEE    		ld	l,(ix-18)
2493    188C  DD66EF    		ld	h,(ix-17)
2494    188F  DD4EF6    		ld	c,(ix-10)
2495    1892  DD46F7    		ld	b,(ix-9)
2496    1895  09        		add	hl,bc
2497    1896  7E        		ld	a,(hl)
2498    1897  FE7F      		cp	127
2499    1899  3015      		jr	nc,L1252
2500                    	;  773                          putchar(entryptr[entryidx]);
2501    189B  DD6EEE    		ld	l,(ix-18)
2502    189E  DD66EF    		ld	h,(ix-17)
2503    18A1  DD4EF6    		ld	c,(ix-10)
2504    18A4  DD46F7    		ld	b,(ix-9)
2505    18A7  09        		add	hl,bc
2506    18A8  6E        		ld	l,(hl)
2507    18A9  97        		sub	a
2508    18AA  67        		ld	h,a
2509    18AB  CD0000    		call	_putchar
2510                    	;  774                  else
2511    18AE  1806      		jr	L1352
2512                    	L1252:
2513                    	;  775                          putchar('.');
2514    18B0  212E00    		ld	hl,46
2515    18B3  CD0000    		call	_putchar
2516                    	L1352:
2517                    	;  776                  hasname = YES;
2518    18B6  DD36F401  		ld	(ix-12),1
2519    18BA  DD36F500  		ld	(ix-11),0
2520                    	;  777                  }
2521    18BE  DD6EF8    		ld	l,(ix-8)
2522    18C1  DD66F9    		ld	h,(ix-7)
2523    18C4  23        		inc	hl
2524    18C5  23        		inc	hl
2525    18C6  DD75F8    		ld	(ix-8),l
2526    18C9  DD74F9    		ld	(ix-7),h
2527    18CC  C33618    		jp	L1542
2528                    	L1642:
2529                    	;  778          if (!hasname)
2530    18CF  DD7EF4    		ld	a,(ix-12)
2531    18D2  DDB6F5    		or	(ix-11)
2532    18D5  2006      		jr	nz,L1452
2533                    	;  779                  printf("name field empty");
2534    18D7  219209    		ld	hl,L5361
2535    18DA  CD0000    		call	_printf
2536                    	L1452:
2537                    	;  780          printf("\n");
2538    18DD  21A309    		ld	hl,L5461
2539    18E0  CD0000    		call	_printf
2540                    	;  781          if (prthex)
2541    18E3  2A3612    		ld	hl,(_prthex)
2542    18E6  7C        		ld	a,h
2543    18E7  B5        		or	l
2544    18E8  CA5719    		jp	z,L1552
2545                    	;  782                  {
2546                    	;  783                  printf("   [");
2547    18EB  21A509    		ld	hl,L5561
2548    18EE  CD0000    		call	_printf
2549                    	;  784                  entryidx = index + 56;
2550    18F1  DD6EF8    		ld	l,(ix-8)
2551    18F4  DD66F9    		ld	h,(ix-7)
2552    18F7  013800    		ld	bc,56
2553    18FA  09        		add	hl,bc
2554    18FB  DD75F6    		ld	(ix-10),l
2555    18FE  DD74F7    		ld	(ix-9),h
2556                    	;  785                  for (index = 0; index < 72; index++)
2557    1901  DD36F800  		ld	(ix-8),0
2558    1905  DD36F900  		ld	(ix-7),0
2559                    	L1652:
2560    1909  DD7EF8    		ld	a,(ix-8)
2561    190C  D648      		sub	72
2562    190E  DD7EF9    		ld	a,(ix-7)
2563    1911  DE00      		sbc	a,0
2564    1913  F25119    		jp	p,L1752
2565                    	;  786                          {
2566                    	;  787                          if (((index & 0xf) == 0) && (index != 0)) 
2567    1916  DD6EF8    		ld	l,(ix-8)
2568    1919  DD66F9    		ld	h,(ix-7)
2569    191C  7D        		ld	a,l
2570    191D  E60F      		and	15
2571    191F  200E      		jr	nz,L1262
2572    1921  DD7EF8    		ld	a,(ix-8)
2573    1924  DDB6F9    		or	(ix-7)
2574    1927  2806      		jr	z,L1262
2575                    	;  788                                  printf("\n    ");
2576    1929  21AA09    		ld	hl,L5661
2577    192C  CD0000    		call	_printf
2578                    	L1262:
2579                    	;  789                          printf("%02x ", entryptr[entryidx]);
2580    192F  DD6EEE    		ld	l,(ix-18)
2581    1932  DD66EF    		ld	h,(ix-17)
2582    1935  DD4EF6    		ld	c,(ix-10)
2583    1938  DD46F7    		ld	b,(ix-9)
2584    193B  09        		add	hl,bc
2585    193C  4E        		ld	c,(hl)
2586    193D  97        		sub	a
2587    193E  47        		ld	b,a
2588    193F  C5        		push	bc
2589    1940  21B009    		ld	hl,L5761
2590    1943  CD0000    		call	_printf
2591    1946  F1        		pop	af
2592                    	;  790                          }
2593    1947  DD34F8    		inc	(ix-8)
2594    194A  2003      		jr	nz,L651
2595    194C  DD34F9    		inc	(ix-7)
2596                    	L651:
2597    194F  18B8      		jr	L1652
2598                    	L1752:
2599                    	;  791                  printf("\b]\n");
2600    1951  21B609    		ld	hl,L5071
2601    1954  CD0000    		call	_printf
2602                    	L1552:
2603                    	;  792                  }
2604                    	;  793          }
2605    1957  C30000    		jp	c.rets
2606                    		.psect	_data
2607                    	L5171:
2608    09BA  47        		.byte	71
2609    09BB  50        		.byte	80
2610    09BC  54        		.byte	84
2611    09BD  20        		.byte	32
2612    09BE  68        		.byte	104
2613    09BF  65        		.byte	101
2614    09C0  61        		.byte	97
2615    09C1  64        		.byte	100
2616    09C2  65        		.byte	101
2617    09C3  72        		.byte	114
2618    09C4  0A        		.byte	10
2619    09C5  00        		.byte	0
2620                    	L5271:
2621    09C6  43        		.byte	67
2622    09C7  61        		.byte	97
2623    09C8  6E        		.byte	110
2624    09C9  27        		.byte	39
2625    09CA  74        		.byte	116
2626    09CB  20        		.byte	32
2627    09CC  72        		.byte	114
2628    09CD  65        		.byte	101
2629    09CE  61        		.byte	97
2630    09CF  64        		.byte	100
2631    09D0  20        		.byte	32
2632    09D1  47        		.byte	71
2633    09D2  50        		.byte	80
2634    09D3  54        		.byte	84
2635    09D4  20        		.byte	32
2636    09D5  70        		.byte	112
2637    09D6  61        		.byte	97
2638    09D7  72        		.byte	114
2639    09D8  74        		.byte	116
2640    09D9  69        		.byte	105
2641    09DA  74        		.byte	116
2642    09DB  69        		.byte	105
2643    09DC  6F        		.byte	111
2644    09DD  6E        		.byte	110
2645    09DE  20        		.byte	32
2646    09DF  74        		.byte	116
2647    09E0  61        		.byte	97
2648    09E1  62        		.byte	98
2649    09E2  6C        		.byte	108
2650    09E3  65        		.byte	101
2651    09E4  20        		.byte	32
2652    09E5  68        		.byte	104
2653    09E6  65        		.byte	101
2654    09E7  61        		.byte	97
2655    09E8  64        		.byte	100
2656    09E9  65        		.byte	101
2657    09EA  72        		.byte	114
2658    09EB  0A        		.byte	10
2659    09EC  00        		.byte	0
2660                    	L5371:
2661    09ED  20        		.byte	32
2662    09EE  20        		.byte	32
2663    09EF  53        		.byte	83
2664    09F0  69        		.byte	105
2665    09F1  67        		.byte	103
2666    09F2  6E        		.byte	110
2667    09F3  61        		.byte	97
2668    09F4  74        		.byte	116
2669    09F5  75        		.byte	117
2670    09F6  72        		.byte	114
2671    09F7  65        		.byte	101
2672    09F8  3A        		.byte	58
2673    09F9  20        		.byte	32
2674    09FA  25        		.byte	37
2675    09FB  38        		.byte	56
2676    09FC  73        		.byte	115
2677    09FD  0A        		.byte	10
2678    09FE  00        		.byte	0
2679                    	L5471:
2680    09FF  20        		.byte	32
2681    0A00  20        		.byte	32
2682    0A01  52        		.byte	82
2683    0A02  65        		.byte	101
2684    0A03  76        		.byte	118
2685    0A04  69        		.byte	105
2686    0A05  73        		.byte	115
2687    0A06  69        		.byte	105
2688    0A07  6F        		.byte	111
2689    0A08  6E        		.byte	110
2690    0A09  3A        		.byte	58
2691    0A0A  20        		.byte	32
2692    0A0B  25        		.byte	37
2693    0A0C  64        		.byte	100
2694    0A0D  2E        		.byte	46
2695    0A0E  25        		.byte	37
2696    0A0F  64        		.byte	100
2697    0A10  20        		.byte	32
2698    0A11  5B        		.byte	91
2699    0A12  25        		.byte	37
2700    0A13  30        		.byte	48
2701    0A14  32        		.byte	50
2702    0A15  78        		.byte	120
2703    0A16  20        		.byte	32
2704    0A17  25        		.byte	37
2705    0A18  30        		.byte	48
2706    0A19  32        		.byte	50
2707    0A1A  78        		.byte	120
2708    0A1B  20        		.byte	32
2709    0A1C  25        		.byte	37
2710    0A1D  30        		.byte	48
2711    0A1E  32        		.byte	50
2712    0A1F  78        		.byte	120
2713    0A20  20        		.byte	32
2714    0A21  25        		.byte	37
2715    0A22  30        		.byte	48
2716    0A23  32        		.byte	50
2717    0A24  78        		.byte	120
2718    0A25  5D        		.byte	93
2719    0A26  0A        		.byte	10
2720    0A27  00        		.byte	0
2721                    	L5571:
2722    0A28  20        		.byte	32
2723    0A29  20        		.byte	32
2724    0A2A  4E        		.byte	78
2725    0A2B  75        		.byte	117
2726    0A2C  6D        		.byte	109
2727    0A2D  62        		.byte	98
2728    0A2E  65        		.byte	101
2729    0A2F  72        		.byte	114
2730    0A30  20        		.byte	32
2731    0A31  6F        		.byte	111
2732    0A32  66        		.byte	102
2733    0A33  20        		.byte	32
2734    0A34  70        		.byte	112
2735    0A35  61        		.byte	97
2736    0A36  72        		.byte	114
2737    0A37  74        		.byte	116
2738    0A38  69        		.byte	105
2739    0A39  74        		.byte	116
2740    0A3A  69        		.byte	105
2741    0A3B  6F        		.byte	111
2742    0A3C  6E        		.byte	110
2743    0A3D  20        		.byte	32
2744    0A3E  65        		.byte	101
2745    0A3F  6E        		.byte	110
2746    0A40  74        		.byte	116
2747    0A41  72        		.byte	114
2748    0A42  69        		.byte	105
2749    0A43  65        		.byte	101
2750    0A44  73        		.byte	115
2751    0A45  3A        		.byte	58
2752    0A46  20        		.byte	32
2753    0A47  25        		.byte	37
2754    0A48  6C        		.byte	108
2755    0A49  75        		.byte	117
2756    0A4A  20        		.byte	32
2757    0A4B  28        		.byte	40
2758    0A4C  6D        		.byte	109
2759    0A4D  61        		.byte	97
2760    0A4E  79        		.byte	121
2761    0A4F  20        		.byte	32
2762    0A50  62        		.byte	98
2763    0A51  65        		.byte	101
2764    0A52  20        		.byte	32
2765    0A53  61        		.byte	97
2766    0A54  63        		.byte	99
2767    0A55  74        		.byte	116
2768    0A56  75        		.byte	117
2769    0A57  61        		.byte	97
2770    0A58  6C        		.byte	108
2771    0A59  20        		.byte	32
2772    0A5A  6F        		.byte	111
2773    0A5B  72        		.byte	114
2774    0A5C  20        		.byte	32
2775    0A5D  6D        		.byte	109
2776    0A5E  61        		.byte	97
2777    0A5F  78        		.byte	120
2778    0A60  69        		.byte	105
2779    0A61  6D        		.byte	109
2780    0A62  75        		.byte	117
2781    0A63  6D        		.byte	109
2782    0A64  29        		.byte	41
2783    0A65  0A        		.byte	10
2784    0A66  00        		.byte	0
2785                    	L5671:
2786    0A67  46        		.byte	70
2787    0A68  69        		.byte	105
2788    0A69  72        		.byte	114
2789    0A6A  73        		.byte	115
2790    0A6B  74        		.byte	116
2791    0A6C  20        		.byte	32
2792    0A6D  31        		.byte	49
2793    0A6E  32        		.byte	50
2794    0A6F  38        		.byte	56
2795    0A70  20        		.byte	32
2796    0A71  62        		.byte	98
2797    0A72  79        		.byte	121
2798    0A73  74        		.byte	116
2799    0A74  65        		.byte	101
2800    0A75  73        		.byte	115
2801    0A76  20        		.byte	32
2802    0A77  6F        		.byte	111
2803    0A78  66        		.byte	102
2804    0A79  20        		.byte	32
2805    0A7A  47        		.byte	71
2806    0A7B  54        		.byte	84
2807    0A7C  50        		.byte	80
2808    0A7D  20        		.byte	32
2809    0A7E  68        		.byte	104
2810    0A7F  65        		.byte	101
2811    0A80  61        		.byte	97
2812    0A81  64        		.byte	100
2813    0A82  65        		.byte	101
2814    0A83  72        		.byte	114
2815    0A84  0A        		.byte	10
2816    0A85  20        		.byte	32
2817    0A86  20        		.byte	32
2818    0A87  20        		.byte	32
2819    0A88  5B        		.byte	91
2820    0A89  00        		.byte	0
2821                    	L5771:
2822    0A8A  0A        		.byte	10
2823    0A8B  20        		.byte	32
2824    0A8C  20        		.byte	32
2825    0A8D  20        		.byte	32
2826    0A8E  20        		.byte	32
2827    0A8F  00        		.byte	0
2828                    	L5002:
2829    0A90  25        		.byte	37
2830    0A91  30        		.byte	48
2831    0A92  32        		.byte	50
2832    0A93  78        		.byte	120
2833    0A94  20        		.byte	32
2834    0A95  00        		.byte	0
2835                    	L5102:
2836    0A96  08        		.byte	8
2837    0A97  5D        		.byte	93
2838    0A98  0A        		.byte	10
2839    0A99  00        		.byte	0
2840                    	L5202:
2841    0A9A  46        		.byte	70
2842    0A9B  69        		.byte	105
2843    0A9C  72        		.byte	114
2844    0A9D  73        		.byte	115
2845    0A9E  74        		.byte	116
2846    0A9F  20        		.byte	32
2847    0AA0  31        		.byte	49
2848    0AA1  36        		.byte	54
2849    0AA2  20        		.byte	32
2850    0AA3  47        		.byte	71
2851    0AA4  50        		.byte	80
2852    0AA5  54        		.byte	84
2853    0AA6  20        		.byte	32
2854    0AA7  65        		.byte	101
2855    0AA8  6E        		.byte	110
2856    0AA9  74        		.byte	116
2857    0AAA  72        		.byte	114
2858    0AAB  69        		.byte	105
2859    0AAC  65        		.byte	101
2860    0AAD  73        		.byte	115
2861    0AAE  20        		.byte	32
2862    0AAF  73        		.byte	115
2863    0AB0  63        		.byte	99
2864    0AB1  61        		.byte	97
2865    0AB2  6E        		.byte	110
2866    0AB3  6E        		.byte	110
2867    0AB4  65        		.byte	101
2868    0AB5  64        		.byte	100
2869    0AB6  0A        		.byte	10
2870    0AB7  00        		.byte	0
2871                    		.psect	_text
2872                    	;  794  
2873                    	;  795  /* print GPT header */
2874                    	;  796  void prtgpthdr(unsigned long block)
2875                    	;  797          {
2876                    	_prtgpthdr:
2877    195A  CD0000    		call	c.savs
2878    195D  21F0FF    		ld	hl,65520
2879    1960  39        		add	hl,sp
2880    1961  F9        		ld	sp,hl
2881                    	;  798          int index;
2882                    	;  799          unsigned int partno;
2883                    	;  800          unsigned char *rxdata;
2884                    	;  801          unsigned long entries;
2885                    	;  802  
2886                    	;  803          printf("GPT header\n");
2887    1962  21BA09    		ld	hl,L5171
2888    1965  CD0000    		call	_printf
2889                    	;  804          blockno = block;
2890    1968  213A12    		ld	hl,_blockno
2891    196B  E5        		push	hl
2892    196C  DDE5      		push	ix
2893    196E  C1        		pop	bc
2894    196F  210400    		ld	hl,4
2895    1972  09        		add	hl,bc
2896    1973  E5        		push	hl
2897    1974  CD0000    		call	c.mvl
2898    1977  F1        		pop	af
2899                    	;  805          if (!sdread(NO))
2900    1978  210000    		ld	hl,0
2901    197B  CD5E09    		call	_sdread
2902    197E  79        		ld	a,c
2903    197F  B0        		or	b
2904    1980  2009      		jr	nz,L1362
2905                    	;  806                  {
2906                    	;  807                  printf("Can't read GPT partition table header\n");
2907    1982  21C609    		ld	hl,L5271
2908    1985  CD0000    		call	_printf
2909                    	;  808                  return;
2910    1988  C30000    		jp	c.rets
2911                    	L1362:
2912                    	;  809                  }
2913                    	;  810          rxdata = dataptr;
2914    198B  3A3E12    		ld	a,(_dataptr)
2915    198E  DD77F4    		ld	(ix-12),a
2916    1991  3A3F12    		ld	a,(_dataptr+1)
2917    1994  DD77F5    		ld	(ix-11),a
2918                    	;  811          printf("  Signature: %8s\n", &rxdata[0]);
2919    1997  DD6EF4    		ld	l,(ix-12)
2920    199A  DD66F5    		ld	h,(ix-11)
2921    199D  E5        		push	hl
2922    199E  21ED09    		ld	hl,L5371
2923    19A1  CD0000    		call	_printf
2924    19A4  F1        		pop	af
2925                    	;  812          printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
2926                    	;  813                   (int)rxdata[8] * ((int)rxdata[9] << 8),
2927                    	;  814                   (int)rxdata[10] + ((int)rxdata[11] << 8),
2928                    	;  815                   rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
2929    19A5  DD6EF4    		ld	l,(ix-12)
2930    19A8  DD66F5    		ld	h,(ix-11)
2931    19AB  010B00    		ld	bc,11
2932    19AE  09        		add	hl,bc
2933    19AF  4E        		ld	c,(hl)
2934    19B0  97        		sub	a
2935    19B1  47        		ld	b,a
2936    19B2  C5        		push	bc
2937    19B3  DD6EF4    		ld	l,(ix-12)
2938    19B6  DD66F5    		ld	h,(ix-11)
2939    19B9  010A00    		ld	bc,10
2940    19BC  09        		add	hl,bc
2941    19BD  4E        		ld	c,(hl)
2942    19BE  97        		sub	a
2943    19BF  47        		ld	b,a
2944    19C0  C5        		push	bc
2945    19C1  DD6EF4    		ld	l,(ix-12)
2946    19C4  DD66F5    		ld	h,(ix-11)
2947    19C7  010900    		ld	bc,9
2948    19CA  09        		add	hl,bc
2949    19CB  4E        		ld	c,(hl)
2950    19CC  97        		sub	a
2951    19CD  47        		ld	b,a
2952    19CE  C5        		push	bc
2953    19CF  DD6EF4    		ld	l,(ix-12)
2954    19D2  DD66F5    		ld	h,(ix-11)
2955    19D5  010800    		ld	bc,8
2956    19D8  09        		add	hl,bc
2957    19D9  4E        		ld	c,(hl)
2958    19DA  97        		sub	a
2959    19DB  47        		ld	b,a
2960    19DC  C5        		push	bc
2961    19DD  DD6EF4    		ld	l,(ix-12)
2962    19E0  DD66F5    		ld	h,(ix-11)
2963    19E3  010A00    		ld	bc,10
2964    19E6  09        		add	hl,bc
2965    19E7  6E        		ld	l,(hl)
2966    19E8  97        		sub	a
2967    19E9  67        		ld	h,a
2968    19EA  E5        		push	hl
2969    19EB  DD6EF4    		ld	l,(ix-12)
2970    19EE  DD66F5    		ld	h,(ix-11)
2971    19F1  010B00    		ld	bc,11
2972    19F4  09        		add	hl,bc
2973    19F5  6E        		ld	l,(hl)
2974    19F6  97        		sub	a
2975    19F7  67        		ld	h,a
2976    19F8  29        		add	hl,hl
2977    19F9  29        		add	hl,hl
2978    19FA  29        		add	hl,hl
2979    19FB  29        		add	hl,hl
2980    19FC  29        		add	hl,hl
2981    19FD  29        		add	hl,hl
2982    19FE  29        		add	hl,hl
2983    19FF  29        		add	hl,hl
2984    1A00  E3        		ex	(sp),hl
2985    1A01  C1        		pop	bc
2986    1A02  09        		add	hl,bc
2987    1A03  E5        		push	hl
2988    1A04  DD6EF4    		ld	l,(ix-12)
2989    1A07  DD66F5    		ld	h,(ix-11)
2990    1A0A  010800    		ld	bc,8
2991    1A0D  09        		add	hl,bc
2992    1A0E  6E        		ld	l,(hl)
2993    1A0F  97        		sub	a
2994    1A10  67        		ld	h,a
2995    1A11  E5        		push	hl
2996    1A12  DD6EF4    		ld	l,(ix-12)
2997    1A15  DD66F5    		ld	h,(ix-11)
2998    1A18  010900    		ld	bc,9
2999    1A1B  09        		add	hl,bc
3000    1A1C  6E        		ld	l,(hl)
3001    1A1D  97        		sub	a
3002    1A1E  67        		ld	h,a
3003    1A1F  29        		add	hl,hl
3004    1A20  29        		add	hl,hl
3005    1A21  29        		add	hl,hl
3006    1A22  29        		add	hl,hl
3007    1A23  29        		add	hl,hl
3008    1A24  29        		add	hl,hl
3009    1A25  29        		add	hl,hl
3010    1A26  29        		add	hl,hl
3011    1A27  E5        		push	hl
3012    1A28  CD0000    		call	c.imul
3013    1A2B  21FF09    		ld	hl,L5471
3014    1A2E  CD0000    		call	_printf
3015    1A31  210C00    		ld	hl,12
3016    1A34  39        		add	hl,sp
3017    1A35  F9        		ld	sp,hl
3018                    	;  816          entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
3019                    	;  817                    ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
3020    1A36  DDE5      		push	ix
3021    1A38  C1        		pop	bc
3022    1A39  21F0FF    		ld	hl,65520
3023    1A3C  09        		add	hl,bc
3024    1A3D  E5        		push	hl
3025    1A3E  DD6EF4    		ld	l,(ix-12)
3026    1A41  DD66F5    		ld	h,(ix-11)
3027    1A44  015000    		ld	bc,80
3028    1A47  09        		add	hl,bc
3029    1A48  4D        		ld	c,l
3030    1A49  44        		ld	b,h
3031    1A4A  97        		sub	a
3032    1A4B  320000    		ld	(c.r0),a
3033    1A4E  320100    		ld	(c.r0+1),a
3034    1A51  0A        		ld	a,(bc)
3035    1A52  320200    		ld	(c.r0+2),a
3036    1A55  97        		sub	a
3037    1A56  320300    		ld	(c.r0+3),a
3038    1A59  210000    		ld	hl,c.r0
3039    1A5C  E5        		push	hl
3040    1A5D  DD6EF4    		ld	l,(ix-12)
3041    1A60  DD66F5    		ld	h,(ix-11)
3042    1A63  015100    		ld	bc,81
3043    1A66  09        		add	hl,bc
3044    1A67  4D        		ld	c,l
3045    1A68  44        		ld	b,h
3046    1A69  97        		sub	a
3047    1A6A  320000    		ld	(c.r1),a
3048    1A6D  320100    		ld	(c.r1+1),a
3049    1A70  0A        		ld	a,(bc)
3050    1A71  320200    		ld	(c.r1+2),a
3051    1A74  97        		sub	a
3052    1A75  320300    		ld	(c.r1+3),a
3053    1A78  210000    		ld	hl,c.r1
3054    1A7B  E5        		push	hl
3055    1A7C  210800    		ld	hl,8
3056    1A7F  E5        		push	hl
3057    1A80  CD0000    		call	c.llsh
3058    1A83  CD0000    		call	c.ladd
3059    1A86  DD6EF4    		ld	l,(ix-12)
3060    1A89  DD66F5    		ld	h,(ix-11)
3061    1A8C  015200    		ld	bc,82
3062    1A8F  09        		add	hl,bc
3063    1A90  4D        		ld	c,l
3064    1A91  44        		ld	b,h
3065    1A92  97        		sub	a
3066    1A93  320000    		ld	(c.r1),a
3067    1A96  320100    		ld	(c.r1+1),a
3068    1A99  0A        		ld	a,(bc)
3069    1A9A  320200    		ld	(c.r1+2),a
3070    1A9D  97        		sub	a
3071    1A9E  320300    		ld	(c.r1+3),a
3072    1AA1  210000    		ld	hl,c.r1
3073    1AA4  E5        		push	hl
3074    1AA5  211000    		ld	hl,16
3075    1AA8  E5        		push	hl
3076    1AA9  CD0000    		call	c.llsh
3077    1AAC  CD0000    		call	c.ladd
3078    1AAF  DD6EF4    		ld	l,(ix-12)
3079    1AB2  DD66F5    		ld	h,(ix-11)
3080    1AB5  015300    		ld	bc,83
3081    1AB8  09        		add	hl,bc
3082    1AB9  4D        		ld	c,l
3083    1ABA  44        		ld	b,h
3084    1ABB  97        		sub	a
3085    1ABC  320000    		ld	(c.r1),a
3086    1ABF  320100    		ld	(c.r1+1),a
3087    1AC2  0A        		ld	a,(bc)
3088    1AC3  320200    		ld	(c.r1+2),a
3089    1AC6  97        		sub	a
3090    1AC7  320300    		ld	(c.r1+3),a
3091    1ACA  210000    		ld	hl,c.r1
3092    1ACD  E5        		push	hl
3093    1ACE  211800    		ld	hl,24
3094    1AD1  E5        		push	hl
3095    1AD2  CD0000    		call	c.llsh
3096    1AD5  CD0000    		call	c.ladd
3097    1AD8  CD0000    		call	c.mvl
3098    1ADB  F1        		pop	af
3099                    	;  818          printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
3100    1ADC  DD66F3    		ld	h,(ix-13)
3101    1ADF  DD6EF2    		ld	l,(ix-14)
3102    1AE2  E5        		push	hl
3103    1AE3  DD66F1    		ld	h,(ix-15)
3104    1AE6  DD6EF0    		ld	l,(ix-16)
3105    1AE9  E5        		push	hl
3106    1AEA  21280A    		ld	hl,L5571
3107    1AED  CD0000    		call	_printf
3108    1AF0  F1        		pop	af
3109    1AF1  F1        		pop	af
3110                    	;  819          if (prthex)
3111    1AF2  2A3612    		ld	hl,(_prthex)
3112    1AF5  7C        		ld	a,h
3113    1AF6  B5        		or	l
3114    1AF7  CA561B    		jp	z,L1462
3115                    	;  820                  {
3116                    	;  821                  printf("First 128 bytes of GTP header\n   [");
3117    1AFA  21670A    		ld	hl,L5671
3118    1AFD  CD0000    		call	_printf
3119                    	;  822                  for (index = 0; index < 128; index++)
3120    1B00  DD36F800  		ld	(ix-8),0
3121    1B04  DD36F900  		ld	(ix-7),0
3122                    	L1562:
3123    1B08  DD7EF8    		ld	a,(ix-8)
3124    1B0B  D680      		sub	128
3125    1B0D  DD7EF9    		ld	a,(ix-7)
3126    1B10  DE00      		sbc	a,0
3127    1B12  F2501B    		jp	p,L1662
3128                    	;  823                          {
3129                    	;  824                          if (((index & 0xf) == 0) && (index != 0)) 
3130    1B15  DD6EF8    		ld	l,(ix-8)
3131    1B18  DD66F9    		ld	h,(ix-7)
3132    1B1B  7D        		ld	a,l
3133    1B1C  E60F      		and	15
3134    1B1E  200E      		jr	nz,L1172
3135    1B20  DD7EF8    		ld	a,(ix-8)
3136    1B23  DDB6F9    		or	(ix-7)
3137    1B26  2806      		jr	z,L1172
3138                    	;  825                                  printf("\n    ");
3139    1B28  218A0A    		ld	hl,L5771
3140    1B2B  CD0000    		call	_printf
3141                    	L1172:
3142                    	;  826                          printf("%02x ", rxdata[index]);
3143    1B2E  DD6EF4    		ld	l,(ix-12)
3144    1B31  DD66F5    		ld	h,(ix-11)
3145    1B34  DD4EF8    		ld	c,(ix-8)
3146    1B37  DD46F9    		ld	b,(ix-7)
3147    1B3A  09        		add	hl,bc
3148    1B3B  4E        		ld	c,(hl)
3149    1B3C  97        		sub	a
3150    1B3D  47        		ld	b,a
3151    1B3E  C5        		push	bc
3152    1B3F  21900A    		ld	hl,L5002
3153    1B42  CD0000    		call	_printf
3154    1B45  F1        		pop	af
3155                    	;  827                          }
3156    1B46  DD34F8    		inc	(ix-8)
3157    1B49  2003      		jr	nz,L261
3158    1B4B  DD34F9    		inc	(ix-7)
3159                    	L261:
3160    1B4E  18B8      		jr	L1562
3161                    	L1662:
3162                    	;  828                  printf("\b]\n");
3163    1B50  21960A    		ld	hl,L5102
3164    1B53  CD0000    		call	_printf
3165                    	L1462:
3166                    	;  829                  }
3167                    	;  830          for (partno = 0; partno < 16; partno++)
3168    1B56  DD36F600  		ld	(ix-10),0
3169    1B5A  DD36F700  		ld	(ix-9),0
3170                    	L1272:
3171    1B5E  DD7EF6    		ld	a,(ix-10)
3172    1B61  D610      		sub	16
3173    1B63  DD7EF7    		ld	a,(ix-9)
3174    1B66  DE00      		sbc	a,0
3175    1B68  3013      		jr	nc,L1372
3176                    	;  831                  {
3177                    	;  832                  prtgptent(partno);
3178    1B6A  DD6EF6    		ld	l,(ix-10)
3179    1B6D  DD66F7    		ld	h,(ix-9)
3180    1B70  CDA014    		call	_prtgptent
3181                    	;  833                  }
3182    1B73  DD34F6    		inc	(ix-10)
3183    1B76  2003      		jr	nz,L461
3184    1B78  DD34F7    		inc	(ix-9)
3185                    	L461:
3186    1B7B  18E1      		jr	L1272
3187                    	L1372:
3188                    	;  834          printf("First 16 GPT entries scanned\n");
3189    1B7D  219A0A    		ld	hl,L5202
3190    1B80  CD0000    		call	_printf
3191                    	;  835          }
3192    1B83  C30000    		jp	c.rets
3193                    		.psect	_data
3194                    	L5302:
3195    0AB8  43        		.byte	67
3196    0AB9  61        		.byte	97
3197    0ABA  6E        		.byte	110
3198    0ABB  27        		.byte	39
3199    0ABC  74        		.byte	116
3200    0ABD  20        		.byte	32
3201    0ABE  72        		.byte	114
3202    0ABF  65        		.byte	101
3203    0AC0  61        		.byte	97
3204    0AC1  64        		.byte	100
3205    0AC2  20        		.byte	32
3206    0AC3  4D        		.byte	77
3207    0AC4  42        		.byte	66
3208    0AC5  52        		.byte	82
3209    0AC6  20        		.byte	32
3210    0AC7  73        		.byte	115
3211    0AC8  65        		.byte	101
3212    0AC9  63        		.byte	99
3213    0ACA  74        		.byte	116
3214    0ACB  6F        		.byte	111
3215    0ACC  72        		.byte	114
3216    0ACD  0A        		.byte	10
3217    0ACE  00        		.byte	0
3218                    	L5402:
3219    0ACF  4E        		.byte	78
3220    0AD0  6F        		.byte	111
3221    0AD1  74        		.byte	116
3222    0AD2  20        		.byte	32
3223    0AD3  75        		.byte	117
3224    0AD4  73        		.byte	115
3225    0AD5  65        		.byte	101
3226    0AD6  64        		.byte	100
3227    0AD7  20        		.byte	32
3228    0AD8  65        		.byte	101
3229    0AD9  6E        		.byte	110
3230    0ADA  74        		.byte	116
3231    0ADB  72        		.byte	114
3232    0ADC  79        		.byte	121
3233    0ADD  0A        		.byte	10
3234    0ADE  00        		.byte	0
3235                    	L5502:
3236    0ADF  62        		.byte	98
3237    0AE0  6F        		.byte	111
3238    0AE1  6F        		.byte	111
3239    0AE2  74        		.byte	116
3240    0AE3  20        		.byte	32
3241    0AE4  69        		.byte	105
3242    0AE5  6E        		.byte	110
3243    0AE6  64        		.byte	100
3244    0AE7  69        		.byte	105
3245    0AE8  63        		.byte	99
3246    0AE9  61        		.byte	97
3247    0AEA  74        		.byte	116
3248    0AEB  6F        		.byte	111
3249    0AEC  72        		.byte	114
3250    0AED  3A        		.byte	58
3251    0AEE  20        		.byte	32
3252    0AEF  30        		.byte	48
3253    0AF0  78        		.byte	120
3254    0AF1  25        		.byte	37
3255    0AF2  30        		.byte	48
3256    0AF3  32        		.byte	50
3257    0AF4  78        		.byte	120
3258    0AF5  2C        		.byte	44
3259    0AF6  20        		.byte	32
3260    0AF7  53        		.byte	83
3261    0AF8  79        		.byte	121
3262    0AF9  73        		.byte	115
3263    0AFA  74        		.byte	116
3264    0AFB  65        		.byte	101
3265    0AFC  6D        		.byte	109
3266    0AFD  20        		.byte	32
3267    0AFE  49        		.byte	73
3268    0AFF  44        		.byte	68
3269    0B00  3A        		.byte	58
3270    0B01  20        		.byte	32
3271    0B02  30        		.byte	48
3272    0B03  78        		.byte	120
3273    0B04  25        		.byte	37
3274    0B05  30        		.byte	48
3275    0B06  32        		.byte	50
3276    0B07  78        		.byte	120
3277    0B08  0A        		.byte	10
3278    0B09  00        		.byte	0
3279                    	L5602:
3280    0B0A  20        		.byte	32
3281    0B0B  20        		.byte	32
3282    0B0C  45        		.byte	69
3283    0B0D  78        		.byte	120
3284    0B0E  74        		.byte	116
3285    0B0F  65        		.byte	101
3286    0B10  6E        		.byte	110
3287    0B11  64        		.byte	100
3288    0B12  65        		.byte	101
3289    0B13  64        		.byte	100
3290    0B14  20        		.byte	32
3291    0B15  70        		.byte	112
3292    0B16  61        		.byte	97
3293    0B17  72        		.byte	114
3294    0B18  74        		.byte	116
3295    0B19  69        		.byte	105
3296    0B1A  74        		.byte	116
3297    0B1B  69        		.byte	105
3298    0B1C  6F        		.byte	111
3299    0B1D  6E        		.byte	110
3300    0B1E  0A        		.byte	10
3301    0B1F  00        		.byte	0
3302                    	L5702:
3303    0B20  20        		.byte	32
3304    0B21  20        		.byte	32
3305    0B22  75        		.byte	117
3306    0B23  6E        		.byte	110
3307    0B24  6F        		.byte	111
3308    0B25  66        		.byte	102
3309    0B26  66        		.byte	102
3310    0B27  69        		.byte	105
3311    0B28  63        		.byte	99
3312    0B29  69        		.byte	105
3313    0B2A  61        		.byte	97
3314    0B2B  6C        		.byte	108
3315    0B2C  20        		.byte	32
3316    0B2D  34        		.byte	52
3317    0B2E  38        		.byte	56
3318    0B2F  20        		.byte	32
3319    0B30  62        		.byte	98
3320    0B31  69        		.byte	105
3321    0B32  74        		.byte	116
3322    0B33  20        		.byte	32
3323    0B34  4C        		.byte	76
3324    0B35  42        		.byte	66
3325    0B36  41        		.byte	65
3326    0B37  20        		.byte	32
3327    0B38  50        		.byte	80
3328    0B39  72        		.byte	114
3329    0B3A  6F        		.byte	111
3330    0B3B  70        		.byte	112
3331    0B3C  6F        		.byte	111
3332    0B3D  73        		.byte	115
3333    0B3E  65        		.byte	101
3334    0B3F  64        		.byte	100
3335    0B40  20        		.byte	32
3336    0B41  4D        		.byte	77
3337    0B42  42        		.byte	66
3338    0B43  52        		.byte	82
3339    0B44  20        		.byte	32
3340    0B45  46        		.byte	70
3341    0B46  6F        		.byte	111
3342    0B47  72        		.byte	114
3343    0B48  6D        		.byte	109
3344    0B49  61        		.byte	97
3345    0B4A  74        		.byte	116
3346    0B4B  2C        		.byte	44
3347    0B4C  20        		.byte	32
3348    0B4D  6E        		.byte	110
3349    0B4E  6F        		.byte	111
3350    0B4F  20        		.byte	32
3351    0B50  43        		.byte	67
3352    0B51  48        		.byte	72
3353    0B52  53        		.byte	83
3354    0B53  0A        		.byte	10
3355    0B54  00        		.byte	0
3356                    	L5012:
3357    0B55  20        		.byte	32
3358    0B56  20        		.byte	32
3359    0B57  62        		.byte	98
3360    0B58  65        		.byte	101
3361    0B59  67        		.byte	103
3362    0B5A  69        		.byte	105
3363    0B5B  6E        		.byte	110
3364    0B5C  20        		.byte	32
3365    0B5D  43        		.byte	67
3366    0B5E  48        		.byte	72
3367    0B5F  53        		.byte	83
3368    0B60  3A        		.byte	58
3369    0B61  20        		.byte	32
3370    0B62  30        		.byte	48
3371    0B63  78        		.byte	120
3372    0B64  25        		.byte	37
3373    0B65  30        		.byte	48
3374    0B66  32        		.byte	50
3375    0B67  78        		.byte	120
3376    0B68  2D        		.byte	45
3377    0B69  30        		.byte	48
3378    0B6A  78        		.byte	120
3379    0B6B  25        		.byte	37
3380    0B6C  30        		.byte	48
3381    0B6D  32        		.byte	50
3382    0B6E  78        		.byte	120
3383    0B6F  2D        		.byte	45
3384    0B70  30        		.byte	48
3385    0B71  78        		.byte	120
3386    0B72  25        		.byte	37
3387    0B73  30        		.byte	48
3388    0B74  32        		.byte	50
3389    0B75  78        		.byte	120
3390    0B76  20        		.byte	32
3391    0B77  28        		.byte	40
3392    0B78  63        		.byte	99
3393    0B79  79        		.byte	121
3394    0B7A  6C        		.byte	108
3395    0B7B  3A        		.byte	58
3396    0B7C  20        		.byte	32
3397    0B7D  25        		.byte	37
3398    0B7E  64        		.byte	100
3399    0B7F  2C        		.byte	44
3400    0B80  20        		.byte	32
3401    0B81  68        		.byte	104
3402    0B82  65        		.byte	101
3403    0B83  61        		.byte	97
3404    0B84  64        		.byte	100
3405    0B85  3A        		.byte	58
3406    0B86  20        		.byte	32
3407    0B87  25        		.byte	37
3408    0B88  64        		.byte	100
3409    0B89  20        		.byte	32
3410    0B8A  73        		.byte	115
3411    0B8B  65        		.byte	101
3412    0B8C  63        		.byte	99
3413    0B8D  74        		.byte	116
3414    0B8E  6F        		.byte	111
3415    0B8F  72        		.byte	114
3416    0B90  3A        		.byte	58
3417    0B91  20        		.byte	32
3418    0B92  25        		.byte	37
3419    0B93  64        		.byte	100
3420    0B94  29        		.byte	41
3421    0B95  0A        		.byte	10
3422    0B96  00        		.byte	0
3423                    	L5112:
3424    0B97  20        		.byte	32
3425    0B98  20        		.byte	32
3426    0B99  65        		.byte	101
3427    0B9A  6E        		.byte	110
3428    0B9B  64        		.byte	100
3429    0B9C  20        		.byte	32
3430    0B9D  43        		.byte	67
3431    0B9E  48        		.byte	72
3432    0B9F  53        		.byte	83
3433    0BA0  20        		.byte	32
3434    0BA1  30        		.byte	48
3435    0BA2  78        		.byte	120
3436    0BA3  25        		.byte	37
3437    0BA4  30        		.byte	48
3438    0BA5  32        		.byte	50
3439    0BA6  78        		.byte	120
3440    0BA7  2D        		.byte	45
3441    0BA8  30        		.byte	48
3442    0BA9  78        		.byte	120
3443    0BAA  25        		.byte	37
3444    0BAB  30        		.byte	48
3445    0BAC  32        		.byte	50
3446    0BAD  78        		.byte	120
3447    0BAE  2D        		.byte	45
3448    0BAF  30        		.byte	48
3449    0BB0  78        		.byte	120
3450    0BB1  25        		.byte	37
3451    0BB2  30        		.byte	48
3452    0BB3  32        		.byte	50
3453    0BB4  78        		.byte	120
3454    0BB5  20        		.byte	32
3455    0BB6  28        		.byte	40
3456    0BB7  63        		.byte	99
3457    0BB8  79        		.byte	121
3458    0BB9  6C        		.byte	108
3459    0BBA  3A        		.byte	58
3460    0BBB  20        		.byte	32
3461    0BBC  25        		.byte	37
3462    0BBD  64        		.byte	100
3463    0BBE  2C        		.byte	44
3464    0BBF  20        		.byte	32
3465    0BC0  68        		.byte	104
3466    0BC1  65        		.byte	101
3467    0BC2  61        		.byte	97
3468    0BC3  64        		.byte	100
3469    0BC4  3A        		.byte	58
3470    0BC5  20        		.byte	32
3471    0BC6  25        		.byte	37
3472    0BC7  64        		.byte	100
3473    0BC8  20        		.byte	32
3474    0BC9  73        		.byte	115
3475    0BCA  65        		.byte	101
3476    0BCB  63        		.byte	99
3477    0BCC  74        		.byte	116
3478    0BCD  6F        		.byte	111
3479    0BCE  72        		.byte	114
3480    0BCF  3A        		.byte	58
3481    0BD0  20        		.byte	32
3482    0BD1  25        		.byte	37
3483    0BD2  64        		.byte	100
3484    0BD3  29        		.byte	41
3485    0BD4  0A        		.byte	10
3486    0BD5  00        		.byte	0
3487                    	L5212:
3488    0BD6  20        		.byte	32
3489    0BD7  20        		.byte	32
3490    0BD8  70        		.byte	112
3491    0BD9  61        		.byte	97
3492    0BDA  72        		.byte	114
3493    0BDB  74        		.byte	116
3494    0BDC  69        		.byte	105
3495    0BDD  74        		.byte	116
3496    0BDE  69        		.byte	105
3497    0BDF  6F        		.byte	111
3498    0BE0  6E        		.byte	110
3499    0BE1  20        		.byte	32
3500    0BE2  73        		.byte	115
3501    0BE3  74        		.byte	116
3502    0BE4  61        		.byte	97
3503    0BE5  72        		.byte	114
3504    0BE6  74        		.byte	116
3505    0BE7  20        		.byte	32
3506    0BE8  4C        		.byte	76
3507    0BE9  42        		.byte	66
3508    0BEA  41        		.byte	65
3509    0BEB  3A        		.byte	58
3510    0BEC  20        		.byte	32
3511    0BED  25        		.byte	37
3512    0BEE  6C        		.byte	108
3513    0BEF  75        		.byte	117
3514    0BF0  20        		.byte	32
3515    0BF1  5B        		.byte	91
3516    0BF2  25        		.byte	37
3517    0BF3  30        		.byte	48
3518    0BF4  38        		.byte	56
3519    0BF5  6C        		.byte	108
3520    0BF6  78        		.byte	120
3521    0BF7  5D        		.byte	93
3522    0BF8  0A        		.byte	10
3523    0BF9  00        		.byte	0
3524                    	L5312:
3525    0BFA  20        		.byte	32
3526    0BFB  20        		.byte	32
3527    0BFC  70        		.byte	112
3528    0BFD  61        		.byte	97
3529    0BFE  72        		.byte	114
3530    0BFF  74        		.byte	116
3531    0C00  69        		.byte	105
3532    0C01  74        		.byte	116
3533    0C02  69        		.byte	105
3534    0C03  6F        		.byte	111
3535    0C04  6E        		.byte	110
3536    0C05  20        		.byte	32
3537    0C06  73        		.byte	115
3538    0C07  69        		.byte	105
3539    0C08  7A        		.byte	122
3540    0C09  65        		.byte	101
3541    0C0A  20        		.byte	32
3542    0C0B  4C        		.byte	76
3543    0C0C  42        		.byte	66
3544    0C0D  41        		.byte	65
3545    0C0E  3A        		.byte	58
3546    0C0F  20        		.byte	32
3547    0C10  25        		.byte	37
3548    0C11  6C        		.byte	108
3549    0C12  75        		.byte	117
3550    0C13  20        		.byte	32
3551    0C14  5B        		.byte	91
3552    0C15  25        		.byte	37
3553    0C16  30        		.byte	48
3554    0C17  38        		.byte	56
3555    0C18  6C        		.byte	108
3556    0C19  78        		.byte	120
3557    0C1A  5D        		.byte	93
3558    0C1B  2C        		.byte	44
3559    0C1C  20        		.byte	32
3560    0C1D  25        		.byte	37
3561    0C1E  6C        		.byte	108
3562    0C1F  75        		.byte	117
3563    0C20  20        		.byte	32
3564    0C21  4D        		.byte	77
3565    0C22  42        		.byte	66
3566    0C23  79        		.byte	121
3567    0C24  74        		.byte	116
3568    0C25  65        		.byte	101
3569    0C26  0A        		.byte	10
3570    0C27  00        		.byte	0
3571                    	L5412:
3572    0C28  20        		.byte	32
3573    0C29  20        		.byte	32
3574    0C2A  5B        		.byte	91
3575    0C2B  00        		.byte	0
3576                    	L5512:
3577    0C2C  25        		.byte	37
3578    0C2D  30        		.byte	48
3579    0C2E  32        		.byte	50
3580    0C2F  78        		.byte	120
3581    0C30  20        		.byte	32
3582    0C31  00        		.byte	0
3583                    	L5612:
3584    0C32  08        		.byte	8
3585    0C33  5D        		.byte	93
3586    0C34  0A        		.byte	10
3587    0C35  00        		.byte	0
3588                    		.psect	_text
3589                    	;  836  
3590                    	;  837  /* print MBR partition entry */
3591                    	;  838  void prtmbrpart(unsigned char *partptr)
3592                    	;  839          {
3593                    	_prtmbrpart:
3594    1B86  CD0000    		call	c.savs
3595    1B89  21F0FF    		ld	hl,65520
3596    1B8C  39        		add	hl,sp
3597    1B8D  F9        		ld	sp,hl
3598                    	;  840          int index;
3599                    	;  841          unsigned long lbastart;
3600                    	;  842          unsigned long lbasize;
3601                    	;  843  
3602                    	;  844  
3603                    	;  845          if ((blockno != 0) || YES /*!rxtxptr*/)
3604                    	;  846                  {
3605                    	;  847                  blockno = 0;
3606    1B8E  97        		sub	a
3607    1B8F  323A12    		ld	(_blockno),a
3608    1B92  323B12    		ld	(_blockno+1),a
3609    1B95  323C12    		ld	(_blockno+2),a
3610    1B98  323D12    		ld	(_blockno+3),a
3611                    	;  848                  if (!sdread(NO))
3612    1B9B  210000    		ld	hl,0
3613    1B9E  CD5E09    		call	_sdread
3614    1BA1  79        		ld	a,c
3615    1BA2  B0        		or	b
3616    1BA3  2009      		jr	nz,L1672
3617                    	;  849                          {
3618                    	;  850                          printf("Can't read MBR sector\n");
3619    1BA5  21B80A    		ld	hl,L5302
3620    1BA8  CD0000    		call	_printf
3621                    	;  851                          return;
3622    1BAB  C30000    		jp	c.rets
3623                    	L1672:
3624                    	;  852                          }
3625                    	;  853                  }
3626                    	;  854          if (!partptr[4])
3627    1BAE  DD6E04    		ld	l,(ix+4)
3628    1BB1  DD6605    		ld	h,(ix+5)
3629    1BB4  23        		inc	hl
3630    1BB5  23        		inc	hl
3631    1BB6  23        		inc	hl
3632    1BB7  23        		inc	hl
3633    1BB8  7E        		ld	a,(hl)
3634    1BB9  B7        		or	a
3635    1BBA  2009      		jr	nz,L1003
3636                    	;  855                  {
3637                    	;  856                  printf("Not used entry\n");
3638    1BBC  21CF0A    		ld	hl,L5402
3639    1BBF  CD0000    		call	_printf
3640                    	;  857                  return;
3641    1BC2  C30000    		jp	c.rets
3642                    	L1003:
3643                    	;  858                  }
3644                    	;  859          printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
3645                    	;  860            partptr[0], partptr[4]);
3646    1BC5  DD6E04    		ld	l,(ix+4)
3647    1BC8  DD6605    		ld	h,(ix+5)
3648    1BCB  23        		inc	hl
3649    1BCC  23        		inc	hl
3650    1BCD  23        		inc	hl
3651    1BCE  23        		inc	hl
3652    1BCF  4E        		ld	c,(hl)
3653    1BD0  97        		sub	a
3654    1BD1  47        		ld	b,a
3655    1BD2  C5        		push	bc
3656    1BD3  DD6E04    		ld	l,(ix+4)
3657    1BD6  DD6605    		ld	h,(ix+5)
3658    1BD9  4E        		ld	c,(hl)
3659    1BDA  97        		sub	a
3660    1BDB  47        		ld	b,a
3661    1BDC  C5        		push	bc
3662    1BDD  21DF0A    		ld	hl,L5502
3663    1BE0  CD0000    		call	_printf
3664    1BE3  F1        		pop	af
3665    1BE4  F1        		pop	af
3666                    	;  861  
3667                    	;  862          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
3668    1BE5  DD6E04    		ld	l,(ix+4)
3669    1BE8  DD6605    		ld	h,(ix+5)
3670    1BEB  23        		inc	hl
3671    1BEC  23        		inc	hl
3672    1BED  23        		inc	hl
3673    1BEE  23        		inc	hl
3674    1BEF  7E        		ld	a,(hl)
3675    1BF0  FE05      		cp	5
3676    1BF2  280F      		jr	z,L1203
3677    1BF4  DD6E04    		ld	l,(ix+4)
3678    1BF7  DD6605    		ld	h,(ix+5)
3679    1BFA  23        		inc	hl
3680    1BFB  23        		inc	hl
3681    1BFC  23        		inc	hl
3682    1BFD  23        		inc	hl
3683    1BFE  7E        		ld	a,(hl)
3684    1BFF  FE0F      		cp	15
3685    1C01  2006      		jr	nz,L1103
3686                    	L1203:
3687                    	;  863                  {
3688                    	;  864                  printf("  Extended partition\n");
3689    1C03  210A0B    		ld	hl,L5602
3690    1C06  CD0000    		call	_printf
3691                    	L1103:
3692                    	;  865                  /* should probably decode this also */
3693                    	;  866                  }
3694                    	;  867          if (partptr[0] & 0x01)
3695    1C09  DD6E04    		ld	l,(ix+4)
3696    1C0C  DD6605    		ld	h,(ix+5)
3697    1C0F  7E        		ld	a,(hl)
3698    1C10  CB47      		bit	0,a
3699    1C12  6F        		ld	l,a
3700    1C13  2809      		jr	z,L1303
3701                    	;  868                  {
3702                    	;  869                  printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
3703    1C15  21200B    		ld	hl,L5702
3704    1C18  CD0000    		call	_printf
3705                    	;  870                  /* this is however discussed
3706                    	;  871                     https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
3707                    	;  872                  */
3708                    	;  873                  }
3709                    	;  874          else
3710    1C1B  C31A1D    		jp	L1403
3711                    	L1303:
3712                    	;  875                  {
3713                    	;  876                  printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3714                    	;  877                    partptr[1], partptr[2], partptr[3],
3715                    	;  878                    ((partptr[2] & 0xc0) >> 2) + partptr[3],
3716                    	;  879                    partptr[1],
3717                    	;  880                    partptr[2] & 0x3f);
3718    1C1E  DD6E04    		ld	l,(ix+4)
3719    1C21  DD6605    		ld	h,(ix+5)
3720    1C24  23        		inc	hl
3721    1C25  23        		inc	hl
3722    1C26  6E        		ld	l,(hl)
3723    1C27  97        		sub	a
3724    1C28  67        		ld	h,a
3725    1C29  7D        		ld	a,l
3726    1C2A  E63F      		and	63
3727    1C2C  6F        		ld	l,a
3728    1C2D  97        		sub	a
3729    1C2E  67        		ld	h,a
3730    1C2F  E5        		push	hl
3731    1C30  DD6E04    		ld	l,(ix+4)
3732    1C33  DD6605    		ld	h,(ix+5)
3733    1C36  23        		inc	hl
3734    1C37  4E        		ld	c,(hl)
3735    1C38  97        		sub	a
3736    1C39  47        		ld	b,a
3737    1C3A  C5        		push	bc
3738    1C3B  DD6E04    		ld	l,(ix+4)
3739    1C3E  DD6605    		ld	h,(ix+5)
3740    1C41  23        		inc	hl
3741    1C42  23        		inc	hl
3742    1C43  6E        		ld	l,(hl)
3743    1C44  97        		sub	a
3744    1C45  67        		ld	h,a
3745    1C46  7D        		ld	a,l
3746    1C47  E6C0      		and	192
3747    1C49  6F        		ld	l,a
3748    1C4A  97        		sub	a
3749    1C4B  67        		ld	h,a
3750    1C4C  E5        		push	hl
3751    1C4D  210200    		ld	hl,2
3752    1C50  E5        		push	hl
3753    1C51  CD0000    		call	c.irsh
3754    1C54  E1        		pop	hl
3755    1C55  E5        		push	hl
3756    1C56  DD6E04    		ld	l,(ix+4)
3757    1C59  DD6605    		ld	h,(ix+5)
3758    1C5C  23        		inc	hl
3759    1C5D  23        		inc	hl
3760    1C5E  23        		inc	hl
3761    1C5F  6E        		ld	l,(hl)
3762    1C60  97        		sub	a
3763    1C61  67        		ld	h,a
3764    1C62  E3        		ex	(sp),hl
3765    1C63  C1        		pop	bc
3766    1C64  09        		add	hl,bc
3767    1C65  E5        		push	hl
3768    1C66  DD6E04    		ld	l,(ix+4)
3769    1C69  DD6605    		ld	h,(ix+5)
3770    1C6C  23        		inc	hl
3771    1C6D  23        		inc	hl
3772    1C6E  23        		inc	hl
3773    1C6F  4E        		ld	c,(hl)
3774    1C70  97        		sub	a
3775    1C71  47        		ld	b,a
3776    1C72  C5        		push	bc
3777    1C73  DD6E04    		ld	l,(ix+4)
3778    1C76  DD6605    		ld	h,(ix+5)
3779    1C79  23        		inc	hl
3780    1C7A  23        		inc	hl
3781    1C7B  4E        		ld	c,(hl)
3782    1C7C  97        		sub	a
3783    1C7D  47        		ld	b,a
3784    1C7E  C5        		push	bc
3785    1C7F  DD6E04    		ld	l,(ix+4)
3786    1C82  DD6605    		ld	h,(ix+5)
3787    1C85  23        		inc	hl
3788    1C86  4E        		ld	c,(hl)
3789    1C87  97        		sub	a
3790    1C88  47        		ld	b,a
3791    1C89  C5        		push	bc
3792    1C8A  21550B    		ld	hl,L5012
3793    1C8D  CD0000    		call	_printf
3794    1C90  210C00    		ld	hl,12
3795    1C93  39        		add	hl,sp
3796    1C94  F9        		ld	sp,hl
3797                    	;  881                  printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3798                    	;  882                    partptr[5], partptr[6], partptr[7],
3799                    	;  883                    ((partptr[6] & 0xc0) >> 2) + partptr[7],
3800                    	;  884                    partptr[5],
3801                    	;  885                    partptr[6] & 0x3f);
3802    1C95  DD6E04    		ld	l,(ix+4)
3803    1C98  DD6605    		ld	h,(ix+5)
3804    1C9B  010600    		ld	bc,6
3805    1C9E  09        		add	hl,bc
3806    1C9F  6E        		ld	l,(hl)
3807    1CA0  97        		sub	a
3808    1CA1  67        		ld	h,a
3809    1CA2  7D        		ld	a,l
3810    1CA3  E63F      		and	63
3811    1CA5  6F        		ld	l,a
3812    1CA6  97        		sub	a
3813    1CA7  67        		ld	h,a
3814    1CA8  E5        		push	hl
3815    1CA9  DD6E04    		ld	l,(ix+4)
3816    1CAC  DD6605    		ld	h,(ix+5)
3817    1CAF  010500    		ld	bc,5
3818    1CB2  09        		add	hl,bc
3819    1CB3  4E        		ld	c,(hl)
3820    1CB4  97        		sub	a
3821    1CB5  47        		ld	b,a
3822    1CB6  C5        		push	bc
3823    1CB7  DD6E04    		ld	l,(ix+4)
3824    1CBA  DD6605    		ld	h,(ix+5)
3825    1CBD  010600    		ld	bc,6
3826    1CC0  09        		add	hl,bc
3827    1CC1  6E        		ld	l,(hl)
3828    1CC2  97        		sub	a
3829    1CC3  67        		ld	h,a
3830    1CC4  7D        		ld	a,l
3831    1CC5  E6C0      		and	192
3832    1CC7  6F        		ld	l,a
3833    1CC8  97        		sub	a
3834    1CC9  67        		ld	h,a
3835    1CCA  E5        		push	hl
3836    1CCB  210200    		ld	hl,2
3837    1CCE  E5        		push	hl
3838    1CCF  CD0000    		call	c.irsh
3839    1CD2  E1        		pop	hl
3840    1CD3  E5        		push	hl
3841    1CD4  DD6E04    		ld	l,(ix+4)
3842    1CD7  DD6605    		ld	h,(ix+5)
3843    1CDA  010700    		ld	bc,7
3844    1CDD  09        		add	hl,bc
3845    1CDE  6E        		ld	l,(hl)
3846    1CDF  97        		sub	a
3847    1CE0  67        		ld	h,a
3848    1CE1  E3        		ex	(sp),hl
3849    1CE2  C1        		pop	bc
3850    1CE3  09        		add	hl,bc
3851    1CE4  E5        		push	hl
3852    1CE5  DD6E04    		ld	l,(ix+4)
3853    1CE8  DD6605    		ld	h,(ix+5)
3854    1CEB  010700    		ld	bc,7
3855    1CEE  09        		add	hl,bc
3856    1CEF  4E        		ld	c,(hl)
3857    1CF0  97        		sub	a
3858    1CF1  47        		ld	b,a
3859    1CF2  C5        		push	bc
3860    1CF3  DD6E04    		ld	l,(ix+4)
3861    1CF6  DD6605    		ld	h,(ix+5)
3862    1CF9  010600    		ld	bc,6
3863    1CFC  09        		add	hl,bc
3864    1CFD  4E        		ld	c,(hl)
3865    1CFE  97        		sub	a
3866    1CFF  47        		ld	b,a
3867    1D00  C5        		push	bc
3868    1D01  DD6E04    		ld	l,(ix+4)
3869    1D04  DD6605    		ld	h,(ix+5)
3870    1D07  010500    		ld	bc,5
3871    1D0A  09        		add	hl,bc
3872    1D0B  4E        		ld	c,(hl)
3873    1D0C  97        		sub	a
3874    1D0D  47        		ld	b,a
3875    1D0E  C5        		push	bc
3876    1D0F  21970B    		ld	hl,L5112
3877    1D12  CD0000    		call	_printf
3878    1D15  210C00    		ld	hl,12
3879    1D18  39        		add	hl,sp
3880    1D19  F9        		ld	sp,hl
3881                    	L1403:
3882                    	;  886                  }
3883                    	;  887          /* not showing high 16 bits if 48 bit LBA */
3884                    	;  888          lbastart = (unsigned long)partptr[8] +
3885                    	;  889            ((unsigned long)partptr[9] << 8) +
3886                    	;  890            ((unsigned long)partptr[10] << 16) +
3887                    	;  891            ((unsigned long)partptr[11] << 24);
3888    1D1A  DDE5      		push	ix
3889    1D1C  C1        		pop	bc
3890    1D1D  21F4FF    		ld	hl,65524
3891    1D20  09        		add	hl,bc
3892    1D21  E5        		push	hl
3893    1D22  DD6E04    		ld	l,(ix+4)
3894    1D25  DD6605    		ld	h,(ix+5)
3895    1D28  010800    		ld	bc,8
3896    1D2B  09        		add	hl,bc
3897    1D2C  4D        		ld	c,l
3898    1D2D  44        		ld	b,h
3899    1D2E  97        		sub	a
3900    1D2F  320000    		ld	(c.r0),a
3901    1D32  320100    		ld	(c.r0+1),a
3902    1D35  0A        		ld	a,(bc)
3903    1D36  320200    		ld	(c.r0+2),a
3904    1D39  97        		sub	a
3905    1D3A  320300    		ld	(c.r0+3),a
3906    1D3D  210000    		ld	hl,c.r0
3907    1D40  E5        		push	hl
3908    1D41  DD6E04    		ld	l,(ix+4)
3909    1D44  DD6605    		ld	h,(ix+5)
3910    1D47  010900    		ld	bc,9
3911    1D4A  09        		add	hl,bc
3912    1D4B  4D        		ld	c,l
3913    1D4C  44        		ld	b,h
3914    1D4D  97        		sub	a
3915    1D4E  320000    		ld	(c.r1),a
3916    1D51  320100    		ld	(c.r1+1),a
3917    1D54  0A        		ld	a,(bc)
3918    1D55  320200    		ld	(c.r1+2),a
3919    1D58  97        		sub	a
3920    1D59  320300    		ld	(c.r1+3),a
3921    1D5C  210000    		ld	hl,c.r1
3922    1D5F  E5        		push	hl
3923    1D60  210800    		ld	hl,8
3924    1D63  E5        		push	hl
3925    1D64  CD0000    		call	c.llsh
3926    1D67  CD0000    		call	c.ladd
3927    1D6A  DD6E04    		ld	l,(ix+4)
3928    1D6D  DD6605    		ld	h,(ix+5)
3929    1D70  010A00    		ld	bc,10
3930    1D73  09        		add	hl,bc
3931    1D74  4D        		ld	c,l
3932    1D75  44        		ld	b,h
3933    1D76  97        		sub	a
3934    1D77  320000    		ld	(c.r1),a
3935    1D7A  320100    		ld	(c.r1+1),a
3936    1D7D  0A        		ld	a,(bc)
3937    1D7E  320200    		ld	(c.r1+2),a
3938    1D81  97        		sub	a
3939    1D82  320300    		ld	(c.r1+3),a
3940    1D85  210000    		ld	hl,c.r1
3941    1D88  E5        		push	hl
3942    1D89  211000    		ld	hl,16
3943    1D8C  E5        		push	hl
3944    1D8D  CD0000    		call	c.llsh
3945    1D90  CD0000    		call	c.ladd
3946    1D93  DD6E04    		ld	l,(ix+4)
3947    1D96  DD6605    		ld	h,(ix+5)
3948    1D99  010B00    		ld	bc,11
3949    1D9C  09        		add	hl,bc
3950    1D9D  4D        		ld	c,l
3951    1D9E  44        		ld	b,h
3952    1D9F  97        		sub	a
3953    1DA0  320000    		ld	(c.r1),a
3954    1DA3  320100    		ld	(c.r1+1),a
3955    1DA6  0A        		ld	a,(bc)
3956    1DA7  320200    		ld	(c.r1+2),a
3957    1DAA  97        		sub	a
3958    1DAB  320300    		ld	(c.r1+3),a
3959    1DAE  210000    		ld	hl,c.r1
3960    1DB1  E5        		push	hl
3961    1DB2  211800    		ld	hl,24
3962    1DB5  E5        		push	hl
3963    1DB6  CD0000    		call	c.llsh
3964    1DB9  CD0000    		call	c.ladd
3965    1DBC  CD0000    		call	c.mvl
3966    1DBF  F1        		pop	af
3967                    	;  892          lbasize = (unsigned long)partptr[12] +
3968                    	;  893            ((unsigned long)partptr[13] << 8) +
3969                    	;  894            ((unsigned long)partptr[14] << 16) +
3970                    	;  895            ((unsigned long)partptr[15] << 24);
3971    1DC0  DDE5      		push	ix
3972    1DC2  C1        		pop	bc
3973    1DC3  21F0FF    		ld	hl,65520
3974    1DC6  09        		add	hl,bc
3975    1DC7  E5        		push	hl
3976    1DC8  DD6E04    		ld	l,(ix+4)
3977    1DCB  DD6605    		ld	h,(ix+5)
3978    1DCE  010C00    		ld	bc,12
3979    1DD1  09        		add	hl,bc
3980    1DD2  4D        		ld	c,l
3981    1DD3  44        		ld	b,h
3982    1DD4  97        		sub	a
3983    1DD5  320000    		ld	(c.r0),a
3984    1DD8  320100    		ld	(c.r0+1),a
3985    1DDB  0A        		ld	a,(bc)
3986    1DDC  320200    		ld	(c.r0+2),a
3987    1DDF  97        		sub	a
3988    1DE0  320300    		ld	(c.r0+3),a
3989    1DE3  210000    		ld	hl,c.r0
3990    1DE6  E5        		push	hl
3991    1DE7  DD6E04    		ld	l,(ix+4)
3992    1DEA  DD6605    		ld	h,(ix+5)
3993    1DED  010D00    		ld	bc,13
3994    1DF0  09        		add	hl,bc
3995    1DF1  4D        		ld	c,l
3996    1DF2  44        		ld	b,h
3997    1DF3  97        		sub	a
3998    1DF4  320000    		ld	(c.r1),a
3999    1DF7  320100    		ld	(c.r1+1),a
4000    1DFA  0A        		ld	a,(bc)
4001    1DFB  320200    		ld	(c.r1+2),a
4002    1DFE  97        		sub	a
4003    1DFF  320300    		ld	(c.r1+3),a
4004    1E02  210000    		ld	hl,c.r1
4005    1E05  E5        		push	hl
4006    1E06  210800    		ld	hl,8
4007    1E09  E5        		push	hl
4008    1E0A  CD0000    		call	c.llsh
4009    1E0D  CD0000    		call	c.ladd
4010    1E10  DD6E04    		ld	l,(ix+4)
4011    1E13  DD6605    		ld	h,(ix+5)
4012    1E16  010E00    		ld	bc,14
4013    1E19  09        		add	hl,bc
4014    1E1A  4D        		ld	c,l
4015    1E1B  44        		ld	b,h
4016    1E1C  97        		sub	a
4017    1E1D  320000    		ld	(c.r1),a
4018    1E20  320100    		ld	(c.r1+1),a
4019    1E23  0A        		ld	a,(bc)
4020    1E24  320200    		ld	(c.r1+2),a
4021    1E27  97        		sub	a
4022    1E28  320300    		ld	(c.r1+3),a
4023    1E2B  210000    		ld	hl,c.r1
4024    1E2E  E5        		push	hl
4025    1E2F  211000    		ld	hl,16
4026    1E32  E5        		push	hl
4027    1E33  CD0000    		call	c.llsh
4028    1E36  CD0000    		call	c.ladd
4029    1E39  DD6E04    		ld	l,(ix+4)
4030    1E3C  DD6605    		ld	h,(ix+5)
4031    1E3F  010F00    		ld	bc,15
4032    1E42  09        		add	hl,bc
4033    1E43  4D        		ld	c,l
4034    1E44  44        		ld	b,h
4035    1E45  97        		sub	a
4036    1E46  320000    		ld	(c.r1),a
4037    1E49  320100    		ld	(c.r1+1),a
4038    1E4C  0A        		ld	a,(bc)
4039    1E4D  320200    		ld	(c.r1+2),a
4040    1E50  97        		sub	a
4041    1E51  320300    		ld	(c.r1+3),a
4042    1E54  210000    		ld	hl,c.r1
4043    1E57  E5        		push	hl
4044    1E58  211800    		ld	hl,24
4045    1E5B  E5        		push	hl
4046    1E5C  CD0000    		call	c.llsh
4047    1E5F  CD0000    		call	c.ladd
4048    1E62  CD0000    		call	c.mvl
4049    1E65  F1        		pop	af
4050                    	;  896          printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
4051    1E66  DD66F7    		ld	h,(ix-9)
4052    1E69  DD6EF6    		ld	l,(ix-10)
4053    1E6C  E5        		push	hl
4054    1E6D  DD66F5    		ld	h,(ix-11)
4055    1E70  DD6EF4    		ld	l,(ix-12)
4056    1E73  E5        		push	hl
4057    1E74  DD66F7    		ld	h,(ix-9)
4058    1E77  DD6EF6    		ld	l,(ix-10)
4059    1E7A  E5        		push	hl
4060    1E7B  DD66F5    		ld	h,(ix-11)
4061    1E7E  DD6EF4    		ld	l,(ix-12)
4062    1E81  E5        		push	hl
4063    1E82  21D60B    		ld	hl,L5212
4064    1E85  CD0000    		call	_printf
4065    1E88  F1        		pop	af
4066    1E89  F1        		pop	af
4067    1E8A  F1        		pop	af
4068    1E8B  F1        		pop	af
4069                    	;  897          printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
4070                    	;  898          lbasize, lbasize, lbasize >> 11);
4071    1E8C  DDE5      		push	ix
4072    1E8E  C1        		pop	bc
4073    1E8F  21F0FF    		ld	hl,65520
4074    1E92  09        		add	hl,bc
4075    1E93  CD0000    		call	c.0mvf
4076    1E96  210000    		ld	hl,c.r0
4077    1E99  E5        		push	hl
4078    1E9A  210B00    		ld	hl,11
4079    1E9D  E5        		push	hl
4080    1E9E  CD0000    		call	c.ulrsh
4081    1EA1  E1        		pop	hl
4082    1EA2  23        		inc	hl
4083    1EA3  23        		inc	hl
4084    1EA4  4E        		ld	c,(hl)
4085    1EA5  23        		inc	hl
4086    1EA6  46        		ld	b,(hl)
4087    1EA7  C5        		push	bc
4088    1EA8  2B        		dec	hl
4089    1EA9  2B        		dec	hl
4090    1EAA  2B        		dec	hl
4091    1EAB  4E        		ld	c,(hl)
4092    1EAC  23        		inc	hl
4093    1EAD  46        		ld	b,(hl)
4094    1EAE  C5        		push	bc
4095    1EAF  DD66F3    		ld	h,(ix-13)
   0    1EB2  DD6EF2    		ld	l,(ix-14)
   1    1EB5  E5        		push	hl
   2    1EB6  DD66F1    		ld	h,(ix-15)
   3    1EB9  DD6EF0    		ld	l,(ix-16)
   4    1EBC  E5        		push	hl
   5    1EBD  DD66F3    		ld	h,(ix-13)
   6    1EC0  DD6EF2    		ld	l,(ix-14)
   7    1EC3  E5        		push	hl
   8    1EC4  DD66F1    		ld	h,(ix-15)
   9    1EC7  DD6EF0    		ld	l,(ix-16)
  10    1ECA  E5        		push	hl
  11    1ECB  21FA0B    		ld	hl,L5312
  12    1ECE  CD0000    		call	_printf
  13    1ED1  210C00    		ld	hl,12
  14    1ED4  39        		add	hl,sp
  15    1ED5  F9        		ld	sp,hl
  16                    	;  899          if (prthex)
  17    1ED6  2A3612    		ld	hl,(_prthex)
  18    1ED9  7C        		ld	a,h
  19    1EDA  B5        		or	l
  20    1EDB  2843      		jr	z,L1503
  21                    	;  900                  {
  22                    	;  901                  printf("  [");
  23    1EDD  21280C    		ld	hl,L5412
  24    1EE0  CD0000    		call	_printf
  25                    	;  902                  for (index = 0; index < 16; index++)
  26    1EE3  DD36F800  		ld	(ix-8),0
  27    1EE7  DD36F900  		ld	(ix-7),0
  28                    	L1603:
  29    1EEB  DD7EF8    		ld	a,(ix-8)
  30    1EEE  D610      		sub	16
  31    1EF0  DD7EF9    		ld	a,(ix-7)
  32    1EF3  DE00      		sbc	a,0
  33    1EF5  F21A1F    		jp	p,L1703
  34                    	;  903                          printf("%02x ", partptr[index]);
  35    1EF8  DD6E04    		ld	l,(ix+4)
  36    1EFB  DD6605    		ld	h,(ix+5)
  37    1EFE  DD4EF8    		ld	c,(ix-8)
  38    1F01  DD46F9    		ld	b,(ix-7)
  39    1F04  09        		add	hl,bc
  40    1F05  4E        		ld	c,(hl)
  41    1F06  97        		sub	a
  42    1F07  47        		ld	b,a
  43    1F08  C5        		push	bc
  44    1F09  212C0C    		ld	hl,L5512
  45    1F0C  CD0000    		call	_printf
  46    1F0F  F1        		pop	af
  47    1F10  DD34F8    		inc	(ix-8)
  48    1F13  2003      		jr	nz,L071
  49    1F15  DD34F9    		inc	(ix-7)
  50                    	L071:
  51    1F18  18D1      		jr	L1603
  52                    	L1703:
  53                    	;  904                  printf("\b]\n");
  54    1F1A  21320C    		ld	hl,L5612
  55    1F1D  CD0000    		call	_printf
  56                    	L1503:
  57                    	;  905                  }
  58                    	;  906          if (partptr[4] == 0xee)
  59    1F20  DD6E04    		ld	l,(ix+4)
  60    1F23  DD6605    		ld	h,(ix+5)
  61    1F26  23        		inc	hl
  62    1F27  23        		inc	hl
  63    1F28  23        		inc	hl
  64    1F29  23        		inc	hl
  65    1F2A  7E        		ld	a,(hl)
  66    1F2B  FEEE      		cp	238
  67    1F2D  2011      		jr	nz,L1213
  68                    	;  907                  prtgpthdr(lbastart);
  69    1F2F  DD66F7    		ld	h,(ix-9)
  70    1F32  DD6EF6    		ld	l,(ix-10)
  71    1F35  E5        		push	hl
  72    1F36  DD66F5    		ld	h,(ix-11)
  73    1F39  DD6EF4    		ld	l,(ix-12)
  74    1F3C  CD5A19    		call	_prtgpthdr
  75    1F3F  F1        		pop	af
  76                    	L1213:
  77                    	;  908          }
  78    1F40  C30000    		jp	c.rets
  79                    		.psect	_data
  80                    	L5712:
  81    0C36  52        		.byte	82
  82    0C37  65        		.byte	101
  83    0C38  61        		.byte	97
  84    0C39  64        		.byte	100
  85    0C3A  20        		.byte	32
  86    0C3B  4D        		.byte	77
  87    0C3C  42        		.byte	66
  88    0C3D  52        		.byte	82
  89    0C3E  0A        		.byte	10
  90    0C3F  00        		.byte	0
  91                    	L5022:
  92    0C40  43        		.byte	67
  93    0C41  61        		.byte	97
  94    0C42  6E        		.byte	110
  95    0C43  27        		.byte	39
  96    0C44  74        		.byte	116
  97    0C45  20        		.byte	32
  98    0C46  72        		.byte	114
  99    0C47  65        		.byte	101
 100    0C48  61        		.byte	97
 101    0C49  64        		.byte	100
 102    0C4A  20        		.byte	32
 103    0C4B  4D        		.byte	77
 104    0C4C  42        		.byte	66
 105    0C4D  52        		.byte	82
 106    0C4E  20        		.byte	32
 107    0C4F  73        		.byte	115
 108    0C50  65        		.byte	101
 109    0C51  63        		.byte	99
 110    0C52  74        		.byte	116
 111    0C53  6F        		.byte	111
 112    0C54  72        		.byte	114
 113    0C55  0A        		.byte	10
 114    0C56  00        		.byte	0
 115                    	L5122:
 116    0C57  43        		.byte	67
 117    0C58  61        		.byte	97
 118    0C59  6E        		.byte	110
 119    0C5A  27        		.byte	39
 120    0C5B  74        		.byte	116
 121    0C5C  20        		.byte	32
 122    0C5D  72        		.byte	114
 123    0C5E  65        		.byte	101
 124    0C5F  61        		.byte	97
 125    0C60  64        		.byte	100
 126    0C61  20        		.byte	32
 127    0C62  4D        		.byte	77
 128    0C63  42        		.byte	66
 129    0C64  52        		.byte	82
 130    0C65  20        		.byte	32
 131    0C66  73        		.byte	115
 132    0C67  65        		.byte	101
 133    0C68  63        		.byte	99
 134    0C69  74        		.byte	116
 135    0C6A  6F        		.byte	111
 136    0C6B  72        		.byte	114
 137    0C6C  0A        		.byte	10
 138    0C6D  00        		.byte	0
 139                    	L5222:
 140    0C6E  4E        		.byte	78
 141    0C6F  6F        		.byte	111
 142    0C70  20        		.byte	32
 143    0C71  4D        		.byte	77
 144    0C72  42        		.byte	66
 145    0C73  52        		.byte	82
 146    0C74  20        		.byte	32
 147    0C75  73        		.byte	115
 148    0C76  69        		.byte	105
 149    0C77  67        		.byte	103
 150    0C78  6E        		.byte	110
 151    0C79  61        		.byte	97
 152    0C7A  74        		.byte	116
 153    0C7B  75        		.byte	117
 154    0C7C  72        		.byte	114
 155    0C7D  65        		.byte	101
 156    0C7E  20        		.byte	32
 157    0C7F  66        		.byte	102
 158    0C80  6F        		.byte	111
 159    0C81  75        		.byte	117
 160    0C82  6E        		.byte	110
 161    0C83  64        		.byte	100
 162    0C84  0A        		.byte	10
 163    0C85  00        		.byte	0
 164                    	L5322:
 165    0C86  4D        		.byte	77
 166    0C87  42        		.byte	66
 167    0C88  52        		.byte	82
 168    0C89  20        		.byte	32
 169    0C8A  70        		.byte	112
 170    0C8B  61        		.byte	97
 171    0C8C  72        		.byte	114
 172    0C8D  74        		.byte	116
 173    0C8E  69        		.byte	105
 174    0C8F  74        		.byte	116
 175    0C90  69        		.byte	105
 176    0C91  6F        		.byte	111
 177    0C92  6E        		.byte	110
 178    0C93  20        		.byte	32
 179    0C94  65        		.byte	101
 180    0C95  6E        		.byte	110
 181    0C96  74        		.byte	116
 182    0C97  72        		.byte	114
 183    0C98  79        		.byte	121
 184    0C99  20        		.byte	32
 185    0C9A  31        		.byte	49
 186    0C9B  3A        		.byte	58
 187    0C9C  20        		.byte	32
 188    0C9D  00        		.byte	0
 189                    	L5422:
 190    0C9E  4D        		.byte	77
 191    0C9F  42        		.byte	66
 192    0CA0  52        		.byte	82
 193    0CA1  20        		.byte	32
 194    0CA2  70        		.byte	112
 195    0CA3  61        		.byte	97
 196    0CA4  72        		.byte	114
 197    0CA5  74        		.byte	116
 198    0CA6  69        		.byte	105
 199    0CA7  74        		.byte	116
 200    0CA8  69        		.byte	105
 201    0CA9  6F        		.byte	111
 202    0CAA  6E        		.byte	110
 203    0CAB  20        		.byte	32
 204    0CAC  65        		.byte	101
 205    0CAD  6E        		.byte	110
 206    0CAE  74        		.byte	116
 207    0CAF  72        		.byte	114
 208    0CB0  79        		.byte	121
 209    0CB1  20        		.byte	32
 210    0CB2  32        		.byte	50
 211    0CB3  3A        		.byte	58
 212    0CB4  20        		.byte	32
 213    0CB5  00        		.byte	0
 214                    	L5522:
 215    0CB6  4D        		.byte	77
 216    0CB7  42        		.byte	66
 217    0CB8  52        		.byte	82
 218    0CB9  20        		.byte	32
 219    0CBA  70        		.byte	112
 220    0CBB  61        		.byte	97
 221    0CBC  72        		.byte	114
 222    0CBD  74        		.byte	116
 223    0CBE  69        		.byte	105
 224    0CBF  74        		.byte	116
 225    0CC0  69        		.byte	105
 226    0CC1  6F        		.byte	111
 227    0CC2  6E        		.byte	110
 228    0CC3  20        		.byte	32
 229    0CC4  65        		.byte	101
 230    0CC5  6E        		.byte	110
 231    0CC6  74        		.byte	116
 232    0CC7  72        		.byte	114
 233    0CC8  79        		.byte	121
 234    0CC9  20        		.byte	32
 235    0CCA  33        		.byte	51
 236    0CCB  3A        		.byte	58
 237    0CCC  20        		.byte	32
 238    0CCD  00        		.byte	0
 239                    	L5622:
 240    0CCE  4D        		.byte	77
 241    0CCF  42        		.byte	66
 242    0CD0  52        		.byte	82
 243    0CD1  20        		.byte	32
 244    0CD2  70        		.byte	112
 245    0CD3  61        		.byte	97
 246    0CD4  72        		.byte	114
 247    0CD5  74        		.byte	116
 248    0CD6  69        		.byte	105
 249    0CD7  74        		.byte	116
 250    0CD8  69        		.byte	105
 251    0CD9  6F        		.byte	111
 252    0CDA  6E        		.byte	110
 253    0CDB  20        		.byte	32
 254    0CDC  65        		.byte	101
 255    0CDD  6E        		.byte	110
 256    0CDE  74        		.byte	116
 257    0CDF  72        		.byte	114
 258    0CE0  79        		.byte	121
 259    0CE1  20        		.byte	32
 260    0CE2  34        		.byte	52
 261    0CE3  3A        		.byte	58
 262    0CE4  20        		.byte	32
 263    0CE5  00        		.byte	0
 264                    		.psect	_text
 265                    	;  909  
 266                    	;  910  /* print partition layout */
 267                    	;  911  void sdprtpart()
 268                    	;  912          {
 269                    	_sdprtpart:
 270    1F43  CD0000    		call	c.savs0
 271    1F46  F5        		push	af
 272    1F47  F5        		push	af
 273    1F48  F5        		push	af
 274    1F49  F5        		push	af
 275                    	;  913          unsigned char *rxdata;
 276                    	;  914  
 277                    	;  915          printf("Read MBR\n");
 278    1F4A  21360C    		ld	hl,L5712
 279    1F4D  CD0000    		call	_printf
 280                    	;  916          blockno = 0;
 281    1F50  97        		sub	a
 282    1F51  323A12    		ld	(_blockno),a
 283    1F54  323B12    		ld	(_blockno+1),a
 284    1F57  323C12    		ld	(_blockno+2),a
 285    1F5A  323D12    		ld	(_blockno+3),a
 286                    	;  917          if (!sdread(NO))
 287    1F5D  210000    		ld	hl,0
 288    1F60  CD5E09    		call	_sdread
 289    1F63  79        		ld	a,c
 290    1F64  B0        		or	b
 291    1F65  2009      		jr	nz,L1313
 292                    	;  918                  {
 293                    	;  919                  printf("Can't read MBR sector\n");
 294    1F67  21400C    		ld	hl,L5022
 295    1F6A  CD0000    		call	_printf
 296                    	;  920                  return;
 297    1F6D  C30000    		jp	c.rets0
 298                    	L1313:
 299                    	;  921                  }
 300                    	;  922          if ((blockno != 0) || YES /*!rxtxptr*/)
 301                    	;  923                  {
 302                    	;  924                  blockno = 0;
 303    1F70  97        		sub	a
 304    1F71  323A12    		ld	(_blockno),a
 305    1F74  323B12    		ld	(_blockno+1),a
 306    1F77  323C12    		ld	(_blockno+2),a
 307    1F7A  323D12    		ld	(_blockno+3),a
 308                    	;  925                  if (!sdread(NO))
 309    1F7D  210000    		ld	hl,0
 310    1F80  CD5E09    		call	_sdread
 311    1F83  79        		ld	a,c
 312    1F84  B0        		or	b
 313    1F85  2009      		jr	nz,L1413
 314                    	;  926                          {
 315                    	;  927                          printf("Can't read MBR sector\n");
 316    1F87  21570C    		ld	hl,L5122
 317    1F8A  CD0000    		call	_printf
 318                    	;  928                          return;
 319    1F8D  C30000    		jp	c.rets0
 320                    	L1413:
 321                    	;  929                          }
 322                    	;  930                  }
 323                    	;  931          rxdata = dataptr;
 324    1F90  3A3E12    		ld	a,(_dataptr)
 325    1F93  DD77F8    		ld	(ix-8),a
 326    1F96  3A3F12    		ld	a,(_dataptr+1)
 327    1F99  DD77F9    		ld	(ix-7),a
 328                    	;  932          if (!((rxdata[0x1fe] == 0x55) && (rxdata[0x1ff] == 0xaa)))
 329    1F9C  DD6EF8    		ld	l,(ix-8)
 330    1F9F  DD66F9    		ld	h,(ix-7)
 331    1FA2  01FE01    		ld	bc,510
 332    1FA5  09        		add	hl,bc
 333    1FA6  7E        		ld	a,(hl)
 334    1FA7  FE55      		cp	85
 335    1FA9  200F      		jr	nz,L1713
 336    1FAB  DD6EF8    		ld	l,(ix-8)
 337    1FAE  DD66F9    		ld	h,(ix-7)
 338    1FB1  01FF01    		ld	bc,511
 339    1FB4  09        		add	hl,bc
 340    1FB5  7E        		ld	a,(hl)
 341    1FB6  FEAA      		cp	170
 342    1FB8  2809      		jr	z,L1613
 343                    	L1713:
 344                    	;  933                  {
 345                    	;  934                  printf("No MBR signature found\n");
 346    1FBA  216E0C    		ld	hl,L5222
 347    1FBD  CD0000    		call	_printf
 348                    	;  935                  return;
 349    1FC0  C30000    		jp	c.rets0
 350                    	L1613:
 351                    	;  936                  }
 352                    	;  937  
 353                    	;  938          /* print MBR partition entries */
 354                    	;  939          printf("MBR partition entry 1: ");
 355    1FC3  21860C    		ld	hl,L5322
 356    1FC6  CD0000    		call	_printf
 357                    	;  940          prtmbrpart(&rxdata[0x01be]);
 358    1FC9  DD6EF8    		ld	l,(ix-8)
 359    1FCC  DD66F9    		ld	h,(ix-7)
 360    1FCF  01BE01    		ld	bc,446
 361    1FD2  09        		add	hl,bc
 362    1FD3  CD861B    		call	_prtmbrpart
 363                    	;  941          printf("MBR partition entry 2: ");
 364    1FD6  219E0C    		ld	hl,L5422
 365    1FD9  CD0000    		call	_printf
 366                    	;  942          prtmbrpart(&rxdata[0x01ce]);
 367    1FDC  DD6EF8    		ld	l,(ix-8)
 368    1FDF  DD66F9    		ld	h,(ix-7)
 369    1FE2  01CE01    		ld	bc,462
 370    1FE5  09        		add	hl,bc
 371    1FE6  CD861B    		call	_prtmbrpart
 372                    	;  943          printf("MBR partition entry 3: ");
 373    1FE9  21B60C    		ld	hl,L5522
 374    1FEC  CD0000    		call	_printf
 375                    	;  944          prtmbrpart(&rxdata[0x01de]);
 376    1FEF  DD6EF8    		ld	l,(ix-8)
 377    1FF2  DD66F9    		ld	h,(ix-7)
 378    1FF5  01DE01    		ld	bc,478
 379    1FF8  09        		add	hl,bc
 380    1FF9  CD861B    		call	_prtmbrpart
 381                    	;  945          printf("MBR partition entry 4: ");
 382    1FFC  21CE0C    		ld	hl,L5622
 383    1FFF  CD0000    		call	_printf
 384                    	;  946          prtmbrpart(&rxdata[0x01ee]);
 385    2002  DD6EF8    		ld	l,(ix-8)
 386    2005  DD66F9    		ld	h,(ix-7)
 387    2008  01EE01    		ld	bc,494
 388    200B  09        		add	hl,bc
 389    200C  CD861B    		call	_prtmbrpart
 390                    	;  947          }
 391    200F  C30000    		jp	c.rets0
 392                    		.psect	_data
 393                    	L5722:
 394    0CE6  0A        		.byte	10
 395    0CE7  7A        		.byte	122
 396    0CE8  38        		.byte	56
 397    0CE9  30        		.byte	48
 398    0CEA  73        		.byte	115
 399    0CEB  64        		.byte	100
 400    0CEC  74        		.byte	116
 401    0CED  73        		.byte	115
 402    0CEE  74        		.byte	116
 403    0CEF  20        		.byte	32
 404    0CF0  76        		.byte	118
 405    0CF1  65        		.byte	101
 406    0CF2  72        		.byte	114
 407    0CF3  73        		.byte	115
 408    0CF4  69        		.byte	105
 409    0CF5  6F        		.byte	111
 410    0CF6  6E        		.byte	110
 411    0CF7  20        		.byte	32
 412    0CF8  32        		.byte	50
 413    0CF9  2E        		.byte	46
 414    0CFA  30        		.byte	48
 415    0CFB  2C        		.byte	44
 416    0CFC  20        		.byte	32
 417    0CFD  00        		.byte	0
 418                    	L5032:
 419    0CFE  0A        		.byte	10
 420    0CFF  00        		.byte	0
 421                    	L5132:
 422    0D00  63        		.byte	99
 423    0D01  6D        		.byte	109
 424    0D02  64        		.byte	100
 425    0D03  20        		.byte	32
 426    0D04  28        		.byte	40
 427    0D05  68        		.byte	104
 428    0D06  20        		.byte	32
 429    0D07  66        		.byte	102
 430    0D08  6F        		.byte	111
 431    0D09  72        		.byte	114
 432    0D0A  20        		.byte	32
 433    0D0B  68        		.byte	104
 434    0D0C  65        		.byte	101
 435    0D0D  6C        		.byte	108
 436    0D0E  70        		.byte	112
 437    0D0F  29        		.byte	41
 438    0D10  3A        		.byte	58
 439    0D11  20        		.byte	32
 440    0D12  00        		.byte	0
 441                    	L5232:
 442    0D13  20        		.byte	32
 443    0D14  68        		.byte	104
 444    0D15  20        		.byte	32
 445    0D16  2D        		.byte	45
 446    0D17  20        		.byte	32
 447    0D18  68        		.byte	104
 448    0D19  65        		.byte	101
 449    0D1A  6C        		.byte	108
 450    0D1B  70        		.byte	112
 451    0D1C  0A        		.byte	10
 452    0D1D  00        		.byte	0
 453                    	L5332:
 454    0D1E  0A        		.byte	10
 455    0D1F  7A        		.byte	122
 456    0D20  38        		.byte	56
 457    0D21  30        		.byte	48
 458    0D22  73        		.byte	115
 459    0D23  64        		.byte	100
 460    0D24  74        		.byte	116
 461    0D25  73        		.byte	115
 462    0D26  74        		.byte	116
 463    0D27  20        		.byte	32
 464    0D28  76        		.byte	118
 465    0D29  65        		.byte	101
 466    0D2A  72        		.byte	114
 467    0D2B  73        		.byte	115
 468    0D2C  69        		.byte	105
 469    0D2D  6F        		.byte	111
 470    0D2E  6E        		.byte	110
 471    0D2F  20        		.byte	32
 472    0D30  32        		.byte	50
 473    0D31  2E        		.byte	46
 474    0D32  30        		.byte	48
 475    0D33  2C        		.byte	44
 476    0D34  20        		.byte	32
 477    0D35  00        		.byte	0
 478                    	L5432:
 479    0D36  0A        		.byte	10
 480    0D37  43        		.byte	67
 481    0D38  6F        		.byte	111
 482    0D39  6D        		.byte	109
 483    0D3A  6D        		.byte	109
 484    0D3B  61        		.byte	97
 485    0D3C  6E        		.byte	110
 486    0D3D  64        		.byte	100
 487    0D3E  73        		.byte	115
 488    0D3F  3A        		.byte	58
 489    0D40  0A        		.byte	10
 490    0D41  00        		.byte	0
 491                    	L5532:
 492    0D42  20        		.byte	32
 493    0D43  20        		.byte	32
 494    0D44  68        		.byte	104
 495    0D45  20        		.byte	32
 496    0D46  2D        		.byte	45
 497    0D47  20        		.byte	32
 498    0D48  68        		.byte	104
 499    0D49  65        		.byte	101
 500    0D4A  6C        		.byte	108
 501    0D4B  70        		.byte	112
 502    0D4C  0A        		.byte	10
 503    0D4D  00        		.byte	0
 504                    	L5632:
 505    0D4E  20        		.byte	32
 506    0D4F  20        		.byte	32
 507    0D50  64        		.byte	100
 508    0D51  20        		.byte	32
 509    0D52  2D        		.byte	45
 510    0D53  20        		.byte	32
 511    0D54  62        		.byte	98
 512    0D55  79        		.byte	121
 513    0D56  74        		.byte	116
 514    0D57  65        		.byte	101
 515    0D58  20        		.byte	32
 516    0D59  6C        		.byte	108
 517    0D5A  65        		.byte	101
 518    0D5B  76        		.byte	118
 519    0D5C  65        		.byte	101
 520    0D5D  6C        		.byte	108
 521    0D5E  20        		.byte	32
 522    0D5F  64        		.byte	100
 523    0D60  65        		.byte	101
 524    0D61  62        		.byte	98
 525    0D62  75        		.byte	117
 526    0D63  67        		.byte	103
 527    0D64  20        		.byte	32
 528    0D65  70        		.byte	112
 529    0D66  72        		.byte	114
 530    0D67  69        		.byte	105
 531    0D68  6E        		.byte	110
 532    0D69  74        		.byte	116
 533    0D6A  20        		.byte	32
 534    0D6B  6F        		.byte	111
 535    0D6C  6E        		.byte	110
 536    0D6D  0A        		.byte	10
 537    0D6E  00        		.byte	0
 538                    	L5732:
 539    0D6F  20        		.byte	32
 540    0D70  20        		.byte	32
 541    0D71  6F        		.byte	111
 542    0D72  20        		.byte	32
 543    0D73  2D        		.byte	45
 544    0D74  20        		.byte	32
 545    0D75  62        		.byte	98
 546    0D76  79        		.byte	121
 547    0D77  74        		.byte	116
 548    0D78  65        		.byte	101
 549    0D79  20        		.byte	32
 550    0D7A  6C        		.byte	108
 551    0D7B  65        		.byte	101
 552    0D7C  76        		.byte	118
 553    0D7D  65        		.byte	101
 554    0D7E  6C        		.byte	108
 555    0D7F  20        		.byte	32
 556    0D80  64        		.byte	100
 557    0D81  65        		.byte	101
 558    0D82  62        		.byte	98
 559    0D83  75        		.byte	117
 560    0D84  67        		.byte	103
 561    0D85  20        		.byte	32
 562    0D86  70        		.byte	112
 563    0D87  72        		.byte	114
 564    0D88  69        		.byte	105
 565    0D89  6E        		.byte	110
 566    0D8A  74        		.byte	116
 567    0D8B  20        		.byte	32
 568    0D8C  6F        		.byte	111
 569    0D8D  66        		.byte	102
 570    0D8E  66        		.byte	102
 571    0D8F  0A        		.byte	10
 572    0D90  00        		.byte	0
 573                    	L5042:
 574    0D91  20        		.byte	32
 575    0D92  20        		.byte	32
 576    0D93  69        		.byte	105
 577    0D94  20        		.byte	32
 578    0D95  2D        		.byte	45
 579    0D96  20        		.byte	32
 580    0D97  69        		.byte	105
 581    0D98  6E        		.byte	110
 582    0D99  69        		.byte	105
 583    0D9A  74        		.byte	116
 584    0D9B  69        		.byte	105
 585    0D9C  61        		.byte	97
 586    0D9D  6C        		.byte	108
 587    0D9E  69        		.byte	105
 588    0D9F  7A        		.byte	122
 589    0DA0  65        		.byte	101
 590    0DA1  0A        		.byte	10
 591    0DA2  00        		.byte	0
 592                    	L5142:
 593    0DA3  20        		.byte	32
 594    0DA4  20        		.byte	32
 595    0DA5  6E        		.byte	110
 596    0DA6  20        		.byte	32
 597    0DA7  2D        		.byte	45
 598    0DA8  20        		.byte	32
 599    0DA9  73        		.byte	115
 600    0DAA  65        		.byte	101
 601    0DAB  74        		.byte	116
 602    0DAC  2F        		.byte	47
 603    0DAD  73        		.byte	115
 604    0DAE  68        		.byte	104
 605    0DAF  6F        		.byte	111
 606    0DB0  77        		.byte	119
 607    0DB1  20        		.byte	32
 608    0DB2  62        		.byte	98
 609    0DB3  6C        		.byte	108
 610    0DB4  6F        		.byte	111
 611    0DB5  63        		.byte	99
 612    0DB6  6B        		.byte	107
 613    0DB7  20        		.byte	32
 614    0DB8  23        		.byte	35
 615    0DB9  4E        		.byte	78
 616    0DBA  20        		.byte	32
 617    0DBB  74        		.byte	116
 618    0DBC  6F        		.byte	111
 619    0DBD  20        		.byte	32
 620    0DBE  72        		.byte	114
 621    0DBF  65        		.byte	101
 622    0DC0  61        		.byte	97
 623    0DC1  64        		.byte	100
 624    0DC2  2F        		.byte	47
 625    0DC3  77        		.byte	119
 626    0DC4  72        		.byte	114
 627    0DC5  69        		.byte	105
 628    0DC6  74        		.byte	116
 629    0DC7  65        		.byte	101
 630    0DC8  0A        		.byte	10
 631    0DC9  00        		.byte	0
 632                    	L5242:
 633    0DCA  20        		.byte	32
 634    0DCB  20        		.byte	32
 635    0DCC  72        		.byte	114
 636    0DCD  20        		.byte	32
 637    0DCE  2D        		.byte	45
 638    0DCF  20        		.byte	32
 639    0DD0  72        		.byte	114
 640    0DD1  65        		.byte	101
 641    0DD2  61        		.byte	97
 642    0DD3  64        		.byte	100
 643    0DD4  20        		.byte	32
 644    0DD5  62        		.byte	98
 645    0DD6  6C        		.byte	108
 646    0DD7  6F        		.byte	111
 647    0DD8  63        		.byte	99
 648    0DD9  6B        		.byte	107
 649    0DDA  20        		.byte	32
 650    0DDB  23        		.byte	35
 651    0DDC  4E        		.byte	78
 652    0DDD  0A        		.byte	10
 653    0DDE  00        		.byte	0
 654                    	L5342:
 655    0DDF  20        		.byte	32
 656    0DE0  20        		.byte	32
 657    0DE1  77        		.byte	119
 658    0DE2  20        		.byte	32
 659    0DE3  2D        		.byte	45
 660    0DE4  20        		.byte	32
 661    0DE5  77        		.byte	119
 662    0DE6  72        		.byte	114
 663    0DE7  69        		.byte	105
 664    0DE8  74        		.byte	116
 665    0DE9  65        		.byte	101
 666    0DEA  20        		.byte	32
 667    0DEB  62        		.byte	98
 668    0DEC  6C        		.byte	108
 669    0DED  6F        		.byte	111
 670    0DEE  63        		.byte	99
 671    0DEF  6B        		.byte	107
 672    0DF0  20        		.byte	32
 673    0DF1  23        		.byte	35
 674    0DF2  4E        		.byte	78
 675    0DF3  0A        		.byte	10
 676    0DF4  00        		.byte	0
 677                    	L5442:
 678    0DF5  20        		.byte	32
 679    0DF6  20        		.byte	32
 680    0DF7  70        		.byte	112
 681    0DF8  20        		.byte	32
 682    0DF9  2D        		.byte	45
 683    0DFA  20        		.byte	32
 684    0DFB  70        		.byte	112
 685    0DFC  72        		.byte	114
 686    0DFD  69        		.byte	105
 687    0DFE  6E        		.byte	110
 688    0DFF  74        		.byte	116
 689    0E00  20        		.byte	32
 690    0E01  62        		.byte	98
 691    0E02  6C        		.byte	108
 692    0E03  6F        		.byte	111
 693    0E04  63        		.byte	99
 694    0E05  6B        		.byte	107
 695    0E06  20        		.byte	32
 696    0E07  6C        		.byte	108
 697    0E08  61        		.byte	97
 698    0E09  73        		.byte	115
 699    0E0A  74        		.byte	116
 700    0E0B  20        		.byte	32
 701    0E0C  72        		.byte	114
 702    0E0D  65        		.byte	101
 703    0E0E  61        		.byte	97
 704    0E0F  64        		.byte	100
 705    0E10  20        		.byte	32
 706    0E11  6F        		.byte	111
 707    0E12  72        		.byte	114
 708    0E13  20        		.byte	32
 709    0E14  77        		.byte	119
 710    0E15  72        		.byte	114
 711    0E16  69        		.byte	105
 712    0E17  74        		.byte	116
 713    0E18  74        		.byte	116
 714    0E19  65        		.byte	101
 715    0E1A  6E        		.byte	110
 716    0E1B  0A        		.byte	10
 717    0E1C  00        		.byte	0
 718                    	L5542:
 719    0E1D  20        		.byte	32
 720    0E1E  20        		.byte	32
 721    0E1F  73        		.byte	115
 722    0E20  20        		.byte	32
 723    0E21  2D        		.byte	45
 724    0E22  20        		.byte	32
 725    0E23  70        		.byte	112
 726    0E24  72        		.byte	114
 727    0E25  69        		.byte	105
 728    0E26  6E        		.byte	110
 729    0E27  74        		.byte	116
 730    0E28  20        		.byte	32
 731    0E29  53        		.byte	83
 732    0E2A  44        		.byte	68
 733    0E2B  20        		.byte	32
 734    0E2C  72        		.byte	114
 735    0E2D  65        		.byte	101
 736    0E2E  67        		.byte	103
 737    0E2F  69        		.byte	105
 738    0E30  73        		.byte	115
 739    0E31  74        		.byte	116
 740    0E32  65        		.byte	101
 741    0E33  72        		.byte	114
 742    0E34  73        		.byte	115
 743    0E35  0A        		.byte	10
 744    0E36  00        		.byte	0
 745                    	L5642:
 746    0E37  20        		.byte	32
 747    0E38  20        		.byte	32
 748    0E39  6C        		.byte	108
 749    0E3A  20        		.byte	32
 750    0E3B  2D        		.byte	45
 751    0E3C  20        		.byte	32
 752    0E3D  70        		.byte	112
 753    0E3E  72        		.byte	114
 754    0E3F  69        		.byte	105
 755    0E40  6E        		.byte	110
 756    0E41  74        		.byte	116
 757    0E42  20        		.byte	32
 758    0E43  70        		.byte	112
 759    0E44  61        		.byte	97
 760    0E45  72        		.byte	114
 761    0E46  74        		.byte	116
 762    0E47  69        		.byte	105
 763    0E48  74        		.byte	116
 764    0E49  69        		.byte	105
 765    0E4A  6F        		.byte	111
 766    0E4B  6E        		.byte	110
 767    0E4C  20        		.byte	32
 768    0E4D  6C        		.byte	108
 769    0E4E  61        		.byte	97
 770    0E4F  79        		.byte	121
 771    0E50  6F        		.byte	111
 772    0E51  75        		.byte	117
 773    0E52  74        		.byte	116
 774    0E53  0A        		.byte	10
 775    0E54  00        		.byte	0
 776                    	L5742:
 777    0E55  20        		.byte	32
 778    0E56  20        		.byte	32
 779    0E57  78        		.byte	120
 780    0E58  20        		.byte	32
 781    0E59  2D        		.byte	45
 782    0E5A  20        		.byte	32
 783    0E5B  70        		.byte	112
 784    0E5C  72        		.byte	114
 785    0E5D  69        		.byte	105
 786    0E5E  6E        		.byte	110
 787    0E5F  74        		.byte	116
 788    0E60  20        		.byte	32
 789    0E61  22        		.byte	34
 790    0E62  72        		.byte	114
 791    0E63  61        		.byte	97
 792    0E64  77        		.byte	119
 793    0E65  22        		.byte	34
 794    0E66  20        		.byte	32
 795    0E67  68        		.byte	104
 796    0E68  65        		.byte	101
 797    0E69  78        		.byte	120
 798    0E6A  20        		.byte	32
 799    0E6B  66        		.byte	102
 800    0E6C  69        		.byte	105
 801    0E6D  65        		.byte	101
 802    0E6E  6C        		.byte	108
 803    0E6F  64        		.byte	100
 804    0E70  73        		.byte	115
 805    0E71  20        		.byte	32
 806    0E72  6F        		.byte	111
 807    0E73  6E        		.byte	110
 808    0E74  0A        		.byte	10
 809    0E75  00        		.byte	0
 810                    	L5052:
 811    0E76  20        		.byte	32
 812    0E77  20        		.byte	32
 813    0E78  79        		.byte	121
 814    0E79  20        		.byte	32
 815    0E7A  2D        		.byte	45
 816    0E7B  20        		.byte	32
 817    0E7C  70        		.byte	112
 818    0E7D  72        		.byte	114
 819    0E7E  69        		.byte	105
 820    0E7F  6E        		.byte	110
 821    0E80  74        		.byte	116
 822    0E81  20        		.byte	32
 823    0E82  22        		.byte	34
 824    0E83  72        		.byte	114
 825    0E84  61        		.byte	97
 826    0E85  77        		.byte	119
 827    0E86  22        		.byte	34
 828    0E87  20        		.byte	32
 829    0E88  68        		.byte	104
 830    0E89  65        		.byte	101
 831    0E8A  78        		.byte	120
 832    0E8B  20        		.byte	32
 833    0E8C  66        		.byte	102
 834    0E8D  69        		.byte	105
 835    0E8E  65        		.byte	101
 836    0E8F  6C        		.byte	108
 837    0E90  64        		.byte	100
 838    0E91  73        		.byte	115
 839    0E92  20        		.byte	32
 840    0E93  6F        		.byte	111
 841    0E94  66        		.byte	102
 842    0E95  66        		.byte	102
 843    0E96  0A        		.byte	10
 844    0E97  00        		.byte	0
 845                    	L5152:
 846    0E98  20        		.byte	32
 847    0E99  20        		.byte	32
 848    0E9A  43        		.byte	67
 849    0E9B  74        		.byte	116
 850    0E9C  72        		.byte	114
 851    0E9D  6C        		.byte	108
 852    0E9E  2D        		.byte	45
 853    0E9F  43        		.byte	67
 854    0EA0  20        		.byte	32
 855    0EA1  74        		.byte	116
 856    0EA2  6F        		.byte	111
 857    0EA3  20        		.byte	32
 858    0EA4  72        		.byte	114
 859    0EA5  65        		.byte	101
 860    0EA6  6C        		.byte	108
 861    0EA7  6F        		.byte	111
 862    0EA8  61        		.byte	97
 863    0EA9  64        		.byte	100
 864    0EAA  20        		.byte	32
 865    0EAB  6D        		.byte	109
 866    0EAC  6F        		.byte	111
 867    0EAD  6E        		.byte	110
 868    0EAE  69        		.byte	105
 869    0EAF  74        		.byte	116
 870    0EB0  6F        		.byte	111
 871    0EB1  72        		.byte	114
 872    0EB2  2E        		.byte	46
 873    0EB3  0A        		.byte	10
 874    0EB4  00        		.byte	0
 875                    	L5252:
 876    0EB5  20        		.byte	32
 877    0EB6  64        		.byte	100
 878    0EB7  20        		.byte	32
 879    0EB8  2D        		.byte	45
 880    0EB9  20        		.byte	32
 881    0EBA  62        		.byte	98
 882    0EBB  79        		.byte	121
 883    0EBC  74        		.byte	116
 884    0EBD  65        		.byte	101
 885    0EBE  20        		.byte	32
 886    0EBF  64        		.byte	100
 887    0EC0  65        		.byte	101
 888    0EC1  62        		.byte	98
 889    0EC2  75        		.byte	117
 890    0EC3  67        		.byte	103
 891    0EC4  20        		.byte	32
 892    0EC5  6F        		.byte	111
 893    0EC6  6E        		.byte	110
 894    0EC7  0A        		.byte	10
 895    0EC8  00        		.byte	0
 896                    	L5352:
 897    0EC9  20        		.byte	32
 898    0ECA  6F        		.byte	111
 899    0ECB  20        		.byte	32
 900    0ECC  2D        		.byte	45
 901    0ECD  20        		.byte	32
 902    0ECE  62        		.byte	98
 903    0ECF  79        		.byte	121
 904    0ED0  74        		.byte	116
 905    0ED1  65        		.byte	101
 906    0ED2  20        		.byte	32
 907    0ED3  64        		.byte	100
 908    0ED4  65        		.byte	101
 909    0ED5  62        		.byte	98
 910    0ED6  75        		.byte	117
 911    0ED7  67        		.byte	103
 912    0ED8  20        		.byte	32
 913    0ED9  6F        		.byte	111
 914    0EDA  66        		.byte	102
 915    0EDB  66        		.byte	102
 916    0EDC  0A        		.byte	10
 917    0EDD  00        		.byte	0
 918                    	L5452:
 919    0EDE  20        		.byte	32
 920    0EDF  78        		.byte	120
 921    0EE0  20        		.byte	32
 922    0EE1  2D        		.byte	45
 923    0EE2  20        		.byte	32
 924    0EE3  68        		.byte	104
 925    0EE4  65        		.byte	101
 926    0EE5  78        		.byte	120
 927    0EE6  20        		.byte	32
 928    0EE7  64        		.byte	100
 929    0EE8  65        		.byte	101
 930    0EE9  62        		.byte	98
 931    0EEA  75        		.byte	117
 932    0EEB  67        		.byte	103
 933    0EEC  20        		.byte	32
 934    0EED  6F        		.byte	111
 935    0EEE  6E        		.byte	110
 936    0EEF  0A        		.byte	10
 937    0EF0  00        		.byte	0
 938                    	L5552:
 939    0EF1  20        		.byte	32
 940    0EF2  79        		.byte	121
 941    0EF3  20        		.byte	32
 942    0EF4  2D        		.byte	45
 943    0EF5  20        		.byte	32
 944    0EF6  68        		.byte	104
 945    0EF7  65        		.byte	101
 946    0EF8  78        		.byte	120
 947    0EF9  20        		.byte	32
 948    0EFA  64        		.byte	100
 949    0EFB  65        		.byte	101
 950    0EFC  62        		.byte	98
 951    0EFD  75        		.byte	117
 952    0EFE  67        		.byte	103
 953    0EFF  20        		.byte	32
 954    0F00  6F        		.byte	111
 955    0F01  66        		.byte	102
 956    0F02  66        		.byte	102
 957    0F03  0A        		.byte	10
 958    0F04  00        		.byte	0
 959                    	L5652:
 960    0F05  20        		.byte	32
 961    0F06  69        		.byte	105
 962    0F07  20        		.byte	32
 963    0F08  2D        		.byte	45
 964    0F09  20        		.byte	32
 965    0F0A  69        		.byte	105
 966    0F0B  6E        		.byte	110
 967    0F0C  69        		.byte	105
 968    0F0D  74        		.byte	116
 969    0F0E  69        		.byte	105
 970    0F0F  61        		.byte	97
 971    0F10  6C        		.byte	108
 972    0F11  69        		.byte	105
 973    0F12  7A        		.byte	122
 974    0F13  65        		.byte	101
 975    0F14  20        		.byte	32
 976    0F15  53        		.byte	83
 977    0F16  44        		.byte	68
 978    0F17  20        		.byte	32
 979    0F18  63        		.byte	99
 980    0F19  61        		.byte	97
 981    0F1A  72        		.byte	114
 982    0F1B  64        		.byte	100
 983    0F1C  0A        		.byte	10
 984    0F1D  00        		.byte	0
 985                    	L5752:
 986    0F1E  20        		.byte	32
 987    0F1F  6E        		.byte	110
 988    0F20  20        		.byte	32
 989    0F21  2D        		.byte	45
 990    0F22  20        		.byte	32
 991    0F23  62        		.byte	98
 992    0F24  6C        		.byte	108
 993    0F25  6F        		.byte	111
 994    0F26  63        		.byte	99
 995    0F27  6B        		.byte	107
 996    0F28  20        		.byte	32
 997    0F29  6E        		.byte	110
 998    0F2A  75        		.byte	117
 999    0F2B  6D        		.byte	109
1000    0F2C  62        		.byte	98
1001    0F2D  65        		.byte	101
1002    0F2E  72        		.byte	114
1003    0F2F  3A        		.byte	58
1004    0F30  20        		.byte	32
1005    0F31  00        		.byte	0
1006                    	L5062:
1007    0F32  25        		.byte	37
1008    0F33  6C        		.byte	108
1009    0F34  75        		.byte	117
1010    0F35  00        		.byte	0
1011                    	L5162:
1012    0F36  25        		.byte	37
1013    0F37  6C        		.byte	108
1014    0F38  75        		.byte	117
1015    0F39  00        		.byte	0
1016                    	L5262:
1017    0F3A  0A        		.byte	10
1018    0F3B  00        		.byte	0
1019                    	L5362:
1020    0F3C  20        		.byte	32
1021    0F3D  72        		.byte	114
1022    0F3E  20        		.byte	32
1023    0F3F  2D        		.byte	45
1024    0F40  20        		.byte	32
1025    0F41  72        		.byte	114
1026    0F42  65        		.byte	101
1027    0F43  61        		.byte	97
1028    0F44  64        		.byte	100
1029    0F45  20        		.byte	32
1030    0F46  62        		.byte	98
1031    0F47  6C        		.byte	108
1032    0F48  6F        		.byte	111
1033    0F49  63        		.byte	99
1034    0F4A  6B        		.byte	107
1035    0F4B  0A        		.byte	10
1036    0F4C  00        		.byte	0
1037                    	L5462:
1038    0F4D  20        		.byte	32
1039    0F4E  77        		.byte	119
1040    0F4F  20        		.byte	32
1041    0F50  2D        		.byte	45
1042    0F51  20        		.byte	32
1043    0F52  77        		.byte	119
1044    0F53  72        		.byte	114
1045    0F54  69        		.byte	105
1046    0F55  74        		.byte	116
1047    0F56  65        		.byte	101
1048    0F57  20        		.byte	32
1049    0F58  62        		.byte	98
1050    0F59  6C        		.byte	108
1051    0F5A  6F        		.byte	111
1052    0F5B  63        		.byte	99
1053    0F5C  6B        		.byte	107
1054    0F5D  0A        		.byte	10
1055    0F5E  00        		.byte	0
1056                    	L5562:
1057    0F5F  20        		.byte	32
1058    0F60  70        		.byte	112
1059    0F61  20        		.byte	32
1060    0F62  2D        		.byte	45
1061    0F63  20        		.byte	32
1062    0F64  70        		.byte	112
1063    0F65  72        		.byte	114
1064    0F66  69        		.byte	105
1065    0F67  6E        		.byte	110
1066    0F68  74        		.byte	116
1067    0F69  20        		.byte	32
1068    0F6A  64        		.byte	100
1069    0F6B  61        		.byte	97
1070    0F6C  74        		.byte	116
1071    0F6D  61        		.byte	97
1072    0F6E  20        		.byte	32
1073    0F6F  62        		.byte	98
1074    0F70  6C        		.byte	108
1075    0F71  6F        		.byte	111
1076    0F72  63        		.byte	99
1077    0F73  6B        		.byte	107
1078    0F74  0A        		.byte	10
1079    0F75  00        		.byte	0
1080                    	L5662:
1081    0F76  20        		.byte	32
1082    0F77  73        		.byte	115
1083    0F78  20        		.byte	32
1084    0F79  2D        		.byte	45
1085    0F7A  20        		.byte	32
1086    0F7B  70        		.byte	112
1087    0F7C  72        		.byte	114
1088    0F7D  69        		.byte	105
1089    0F7E  6E        		.byte	110
1090    0F7F  74        		.byte	116
1091    0F80  20        		.byte	32
1092    0F81  53        		.byte	83
1093    0F82  44        		.byte	68
1094    0F83  20        		.byte	32
1095    0F84  72        		.byte	114
1096    0F85  65        		.byte	101
1097    0F86  67        		.byte	103
1098    0F87  69        		.byte	105
1099    0F88  73        		.byte	115
1100    0F89  74        		.byte	116
1101    0F8A  65        		.byte	101
1102    0F8B  72        		.byte	114
1103    0F8C  73        		.byte	115
1104    0F8D  0A        		.byte	10
1105    0F8E  00        		.byte	0
1106                    	L5762:
1107    0F8F  20        		.byte	32
1108    0F90  6C        		.byte	108
1109    0F91  20        		.byte	32
1110    0F92  2D        		.byte	45
1111    0F93  20        		.byte	32
1112    0F94  70        		.byte	112
1113    0F95  72        		.byte	114
1114    0F96  69        		.byte	105
1115    0F97  6E        		.byte	110
1116    0F98  74        		.byte	116
1117    0F99  20        		.byte	32
1118    0F9A  70        		.byte	112
1119    0F9B  61        		.byte	97
1120    0F9C  72        		.byte	114
1121    0F9D  74        		.byte	116
1122    0F9E  69        		.byte	105
1123    0F9F  74        		.byte	116
1124    0FA0  69        		.byte	105
1125    0FA1  6F        		.byte	111
1126    0FA2  6E        		.byte	110
1127    0FA3  20        		.byte	32
1128    0FA4  6C        		.byte	108
1129    0FA5  61        		.byte	97
1130    0FA6  79        		.byte	121
1131    0FA7  6F        		.byte	111
1132    0FA8  75        		.byte	117
1133    0FA9  74        		.byte	116
1134    0FAA  0A        		.byte	10
1135    0FAB  00        		.byte	0
1136                    	L5072:
1137    0FAC  72        		.byte	114
1138    0FAD  65        		.byte	101
1139    0FAE  6C        		.byte	108
1140    0FAF  6F        		.byte	111
1141    0FB0  61        		.byte	97
1142    0FB1  64        		.byte	100
1143    0FB2  69        		.byte	105
1144    0FB3  6E        		.byte	110
1145    0FB4  67        		.byte	103
1146    0FB5  20        		.byte	32
1147    0FB6  6D        		.byte	109
1148    0FB7  6F        		.byte	111
1149    0FB8  6E        		.byte	110
1150    0FB9  69        		.byte	105
1151    0FBA  74        		.byte	116
1152    0FBB  6F        		.byte	111
1153    0FBC  72        		.byte	114
1154    0FBD  20        		.byte	32
1155    0FBE  66        		.byte	102
1156    0FBF  72        		.byte	114
1157    0FC0  6F        		.byte	111
1158    0FC1  6D        		.byte	109
1159    0FC2  20        		.byte	32
1160    0FC3  45        		.byte	69
1161    0FC4  50        		.byte	80
1162    0FC5  52        		.byte	82
1163    0FC6  4F        		.byte	79
1164    0FC7  4D        		.byte	77
1165    0FC8  0A        		.byte	10
1166    0FC9  00        		.byte	0
1167                    	L5172:
1168    0FCA  20        		.byte	32
1169    0FCB  63        		.byte	99
1170    0FCC  6F        		.byte	111
1171    0FCD  6D        		.byte	109
1172    0FCE  6D        		.byte	109
1173    0FCF  61        		.byte	97
1174    0FD0  6E        		.byte	110
1175    0FD1  64        		.byte	100
1176    0FD2  20        		.byte	32
1177    0FD3  6E        		.byte	110
1178    0FD4  6F        		.byte	111
1179    0FD5  74        		.byte	116
1180    0FD6  20        		.byte	32
1181    0FD7  69        		.byte	105
1182    0FD8  6D        		.byte	109
1183    0FD9  70        		.byte	112
1184    0FDA  6C        		.byte	108
1185    0FDB  65        		.byte	101
1186    0FDC  6D        		.byte	109
1187    0FDD  65        		.byte	101
1188    0FDE  6E        		.byte	110
1189    0FDF  74        		.byte	116
1190    0FE0  65        		.byte	101
1191    0FE1  64        		.byte	100
1192    0FE2  20        		.byte	32
1193    0FE3  79        		.byte	121
1194    0FE4  65        		.byte	101
1195    0FE5  74        		.byte	116
1196    0FE6  0A        		.byte	10
1197    0FE7  00        		.byte	0
1198                    		.psect	_text
1199                    	L1223:
1200    2012  12        		.byte	18
1201    2013  00        		.byte	0
1202    2014  68        		.byte	104
1203    2015  00        		.byte	0
1204    2016  7D20      		.word	L1423
1205    2018  2221      		.word	L1133
1206    201A  C521      		.word	L1343
1207    201C  C521      		.word	L1343
1208    201E  AD21      		.word	L1143
1209    2020  C521      		.word	L1343
1210    2022  2E21      		.word	L1233
1211    2024  F520      		.word	L1623
1212    2026  9521      		.word	L1733
1213    2028  C521      		.word	L1343
1214    202A  7A21      		.word	L1533
1215    202C  A121      		.word	L1043
1216    202E  C521      		.word	L1343
1217    2030  C521      		.word	L1343
1218    2032  C521      		.word	L1343
1219    2034  8921      		.word	L1633
1220    2036  0421      		.word	L1723
1221    2038  1321      		.word	L1033
1222    203A  00        		.byte	0
1223    203B  00        		.byte	0
1224    203C  02        		.byte	2
1225    203D  00        		.byte	0
1226    203E  B921      		.word	L1243
1227    2040  0300      		.word	3
1228    2042  E620      		.word	L1523
1229    2044  6400      		.word	100
1230    2046  C521      		.word	L1343
1231                    	;  948  
1232                    	;  949  /* Test init, read and write on SD card over the SPI interface
1233                    	;  950   *
1234                    	;  951   */
1235                    	;  952  int main()
1236                    	;  953          {
1237                    	_main:
1238    2048  CD0000    		call	c.savs0
1239    204B  21ECFF    		ld	hl,65516
1240    204E  39        		add	hl,sp
1241    204F  F9        		ld	sp,hl
1242                    	;  954          char txtin[10];
1243                    	;  955          int cmdin;
1244                    	;  956          int inlength;
1245                    	;  957  
1246                    	;  958          printf(SDTSTVER);
1247    2050  21E60C    		ld	hl,L5722
1248    2053  CD0000    		call	_printf
1249                    	;  959          printf(builddate);
1250    2056  210000    		ld	hl,_builddate
1251    2059  CD0000    		call	_printf
1252                    	;  960          printf("\n");
1253    205C  21FE0C    		ld	hl,L5032
1254    205F  CD0000    		call	_printf
1255                    	L1023:
1256                    	;  961          while (YES) /* forever (until Ctrl-C) */
1257                    	;  962                  {
1258                    	;  963                  printf("cmd (h for help): ");
1259    2062  21000D    		ld	hl,L5132
1260    2065  CD0000    		call	_printf
1261                    	;  964  
1262                    	;  965                  cmdin = getchar();
1263    2068  CD0000    		call	_getchar
1264    206B  DD71EE    		ld	(ix-18),c
1265    206E  DD70EF    		ld	(ix-17),b
1266                    	;  966                  switch (cmdin)
1267    2071  DD4EEE    		ld	c,(ix-18)
1268    2074  DD46EF    		ld	b,(ix-17)
1269    2077  211220    		ld	hl,L1223
1270    207A  C30000    		jp	c.jtab
1271                    	L1423:
1272                    	;  967                          {
1273                    	;  968                          case 'h':
1274                    	;  969                                  printf(" h - help\n");
1275    207D  21130D    		ld	hl,L5232
1276    2080  CD0000    		call	_printf
1277                    	;  970                                  printf(SDTSTVER);
1278    2083  211E0D    		ld	hl,L5332
1279    2086  CD0000    		call	_printf
1280                    	;  971                                  printf(builddate);
1281    2089  210000    		ld	hl,_builddate
1282    208C  CD0000    		call	_printf
1283                    	;  972                                  printf("\nCommands:\n");
1284    208F  21360D    		ld	hl,L5432
1285    2092  CD0000    		call	_printf
1286                    	;  973                                  printf("  h - help\n");
1287    2095  21420D    		ld	hl,L5532
1288    2098  CD0000    		call	_printf
1289                    	;  974                                  printf("  d - byte level debug print on\n");
1290    209B  214E0D    		ld	hl,L5632
1291    209E  CD0000    		call	_printf
1292                    	;  975                                  printf("  o - byte level debug print off\n");
1293    20A1  216F0D    		ld	hl,L5732
1294    20A4  CD0000    		call	_printf
1295                    	;  976                                  printf("  i - initialize\n");
1296    20A7  21910D    		ld	hl,L5042
1297    20AA  CD0000    		call	_printf
1298                    	;  977                                  printf("  n - set/show block #N to read/write\n");
1299    20AD  21A30D    		ld	hl,L5142
1300    20B0  CD0000    		call	_printf
1301                    	;  978                                  printf("  r - read block #N\n");
1302    20B3  21CA0D    		ld	hl,L5242
1303    20B6  CD0000    		call	_printf
1304                    	;  979                                  printf("  w - write block #N\n");
1305    20B9  21DF0D    		ld	hl,L5342
1306    20BC  CD0000    		call	_printf
1307                    	;  980                                  printf("  p - print block last read or written\n");
1308    20BF  21F50D    		ld	hl,L5442
1309    20C2  CD0000    		call	_printf
1310                    	;  981                                  printf("  s - print SD registers\n");
1311    20C5  211D0E    		ld	hl,L5542
1312    20C8  CD0000    		call	_printf
1313                    	;  982                                  printf("  l - print partition layout\n");
1314    20CB  21370E    		ld	hl,L5642
1315    20CE  CD0000    		call	_printf
1316                    	;  983                                  printf("  x - print \"raw\" hex fields on\n");
1317    20D1  21550E    		ld	hl,L5742
1318    20D4  CD0000    		call	_printf
1319                    	;  984                                  printf("  y - print \"raw\" hex fields off\n");
1320    20D7  21760E    		ld	hl,L5052
1321    20DA  CD0000    		call	_printf
1322                    	;  985                                  printf("  Ctrl-C to reload monitor.\n");
1323    20DD  21980E    		ld	hl,L5152
1324    20E0  CD0000    		call	_printf
1325                    	;  986                                  break;
1326    20E3  C36220    		jp	L1023
1327                    	L1523:
1328                    	;  987                          case 'd':
1329                    	;  988                                  debugflg = YES;
1330    20E6  210100    		ld	hl,1
1331    20E9  223212    		ld	(_debugflg),hl
1332                    	;  989                                  printf(" d - byte debug on\n");
1333    20EC  21B50E    		ld	hl,L5252
1334    20EF  CD0000    		call	_printf
1335                    	;  990                                  break;
1336    20F2  C36220    		jp	L1023
1337                    	L1623:
1338                    	;  991                          case 'o':
1339                    	;  992                                  debugflg = NO;
1340    20F5  210000    		ld	hl,0
1341    20F8  223212    		ld	(_debugflg),hl
1342                    	;  993                                  printf(" o - byte debug off\n");
1343    20FB  21C90E    		ld	hl,L5352
1344    20FE  CD0000    		call	_printf
1345                    	;  994                                  break;
1346    2101  C36220    		jp	L1023
1347                    	L1723:
1348                    	;  995                          case 'x':
1349                    	;  996                                  prthex = YES;
1350    2104  210100    		ld	hl,1
1351    2107  223612    		ld	(_prthex),hl
1352                    	;  997                                  printf(" x - hex debug on\n");
1353    210A  21DE0E    		ld	hl,L5452
1354    210D  CD0000    		call	_printf
1355                    	;  998                                  break;
1356    2110  C36220    		jp	L1023
1357                    	L1033:
1358                    	;  999                          case 'y':
1359                    	; 1000                                  prthex = NO;
1360    2113  210000    		ld	hl,0
1361    2116  223612    		ld	(_prthex),hl
1362                    	; 1001                                  printf(" y - hex debug off\n");
1363    2119  21F10E    		ld	hl,L5552
1364    211C  CD0000    		call	_printf
1365                    	; 1002                                  break;
1366    211F  C36220    		jp	L1023
1367                    	L1133:
1368                    	; 1003                          case 'i':
1369                    	; 1004                                  printf(" i - initialize SD card\n");
1370    2122  21050F    		ld	hl,L5652
1371    2125  CD0000    		call	_printf
1372                    	; 1005                                  sdinit();
1373    2128  CD6003    		call	_sdinit
1374                    	; 1006                                  break;
1375    212B  C36220    		jp	L1023
1376                    	L1233:
1377                    	; 1007                          case 'n':
1378                    	; 1008                                  printf(" n - block number: ");
1379    212E  211E0F    		ld	hl,L5752
1380    2131  CD0000    		call	_printf
1381                    	; 1009                                  if (getkline(txtin, sizeof txtin))
1382    2134  210A00    		ld	hl,10
1383    2137  E5        		push	hl
1384    2138  DDE5      		push	ix
1385    213A  C1        		pop	bc
1386    213B  21F0FF    		ld	hl,65520
1387    213E  09        		add	hl,bc
1388    213F  CD0000    		call	_getkline
1389    2142  F1        		pop	af
1390    2143  79        		ld	a,c
1391    2144  B0        		or	b
1392    2145  2816      		jr	z,L1333
1393                    	; 1010                                          sscanf(txtin, "%lu", &blockno);
1394    2147  213A12    		ld	hl,_blockno
1395    214A  E5        		push	hl
1396    214B  21320F    		ld	hl,L5062
1397    214E  E5        		push	hl
1398    214F  DDE5      		push	ix
1399    2151  C1        		pop	bc
1400    2152  21F0FF    		ld	hl,65520
1401    2155  09        		add	hl,bc
1402    2156  CD0000    		call	_sscanf
1403    2159  F1        		pop	af
1404    215A  F1        		pop	af
1405                    	; 1011                                  else
1406    215B  1814      		jr	L1433
1407                    	L1333:
1408                    	; 1012                                          printf("%lu", blockno);
1409    215D  213D12    		ld	hl,_blockno+3
1410    2160  46        		ld	b,(hl)
1411    2161  2B        		dec	hl
1412    2162  4E        		ld	c,(hl)
1413    2163  C5        		push	bc
1414    2164  2B        		dec	hl
1415    2165  46        		ld	b,(hl)
1416    2166  2B        		dec	hl
1417    2167  4E        		ld	c,(hl)
1418    2168  C5        		push	bc
1419    2169  21360F    		ld	hl,L5162
1420    216C  CD0000    		call	_printf
1421    216F  F1        		pop	af
1422    2170  F1        		pop	af
1423                    	L1433:
1424                    	; 1013                                  printf("\n");
1425    2171  213A0F    		ld	hl,L5262
1426    2174  CD0000    		call	_printf
1427                    	; 1014                                  break;
1428    2177  C36220    		jp	L1023
1429                    	L1533:
1430                    	; 1015                          case 'r':
1431                    	; 1016                                  printf(" r - read block\n");
1432    217A  213C0F    		ld	hl,L5362
1433    217D  CD0000    		call	_printf
1434                    	; 1017                                  sdread(YES);
1435    2180  210100    		ld	hl,1
1436    2183  CD5E09    		call	_sdread
1437                    	; 1018                                  break;
1438    2186  C36220    		jp	L1023
1439                    	L1633:
1440                    	; 1019                          case 'w':
1441                    	; 1020                                  printf(" w - write block\n");
1442    2189  214D0F    		ld	hl,L5462
1443    218C  CD0000    		call	_printf
1444                    	; 1021                                  sdwrite();
1445    218F  CDA10B    		call	_sdwrite
1446                    	; 1022                                  break;
1447    2192  C36220    		jp	L1023
1448                    	L1733:
1449                    	; 1023                          case 'p':
1450                    	; 1024                                  printf(" p - print data block\n");
1451    2195  215F0F    		ld	hl,L5562
1452    2198  CD0000    		call	_printf
1453                    	; 1025                                  sddatprt();
1454    219B  CD8B0D    		call	_sddatprt
1455                    	; 1026                                  break;
1456    219E  C36220    		jp	L1023
1457                    	L1043:
1458                    	; 1027                          case 's':
1459                    	; 1028                                  printf(" s - print SD registers\n");
1460    21A1  21760F    		ld	hl,L5662
1461    21A4  CD0000    		call	_printf
1462                    	; 1029                                  sdprtreg();
1463    21A7  CD300F    		call	_sdprtreg
1464                    	; 1030                                  break;
1465    21AA  C36220    		jp	L1023
1466                    	L1143:
1467                    	; 1031                          case 'l':
1468                    	; 1032                                  printf(" l - print partition layout\n");
1469    21AD  218F0F    		ld	hl,L5762
1470    21B0  CD0000    		call	_printf
1471                    	; 1033                                  sdprtpart();
1472    21B3  CD431F    		call	_sdprtpart
1473                    	; 1034                                  break;
1474    21B6  C36220    		jp	L1023
1475                    	L1243:
1476                    	; 1035                          case 0x03: /* Ctrl-C */
1477                    	; 1036                                  printf("reloading monitor from EPROM\n");
1478    21B9  21AC0F    		ld	hl,L5072
1479    21BC  CD0000    		call	_printf
1480                    	; 1037                                  reload();
1481    21BF  CD0000    		call	_reload
1482                    	; 1038                                  break; /* not really needed, will never get here */
1483    21C2  C36220    		jp	L1023
1484                    	L1343:
1485                    	; 1039                          default:
1486                    	; 1040                                  printf(" command not implemented yet\n");
1487    21C5  21CA0F    		ld	hl,L5172
1488    21C8  CD0000    		call	_printf
1489    21CB  C36220    		jp	L1023
1490                    	L1323:
1491                    	; 1041                          }
1492                    	; 1042                  }
1493    21CE  C36220    		jp	L1023
1494                    	; 1043          }
1495                    	; 1044  
1496                    		.psect	_bss
1497                    	_dataptr:
1498                    		.byte	[2]
1499                    		.external	c.ulrsh
1500                    		.external	c.rets0
1501                    		.public	_CRC16_one
1502                    		.public	_prtgpthdr
1503                    		.external	c.savs0
1504                    		.external	_getchar
1505                    		.external	c.lcmp
1506                    		.public	_cmd55
1507                    		.public	_cmd17
1508                    		.public	_cmd16
1509                    		.public	_CRC16_buf
1510                    		.public	_prthex
1511                    		.public	_cmd24
1512                    		.external	c.r1
1513                    		.external	_spideselect
1514                    		.public	_cmd10
1515                    		.public	_ready
1516                    		.external	c.r0
1517                    		.external	_getkline
1518                    		.external	c.jtab
1519                    		.external	_printf
1520                    		.external	_ledon
1521                    		.public	_prtmbrpart
1522                    		.external	_spiselect
1523                    		.external	_memcpy
1524                    		.public	_sdinit
1525                    		.external	c.ladd
1526                    		.public	_sdwrite
1527                    		.public	_ocrreg
1528                    		.external	c.mvl
1529                    		.public	_debugflg
1530                    		.public	_prtguid
1531                    		.external	_sscanf
1532                    		.public	_blkmult
1533                    		.public	_acmd41
1534                    		.public	_statbuf
1535                    		.public	_csdreg
1536                    		.external	_reload
1537                    		.external	_putchar
1538                    		.public	_sdcommand
1539                    		.external	c.ursh
1540                    		.public	_sdread
1541                    		.public	_dataptr
1542                    		.external	_ledoff
1543                    		.external	c.rets
1544                    		.public	_CRC7_one
1545                    		.external	c.savs
1546                    		.public	_cidreg
1547                    		.public	_builddate
1548                    		.public	_cmd9
1549                    		.external	c.lmul
1550                    		.public	_cmd8
1551                    		.public	_rxtxptr
1552                    		.public	_sdprtreg
1553                    		.external	c.0mvf
1554                    		.public	_CRC7_buf
1555                    		.external	c.udiv
1556                    		.external	c.imul
1557                    		.external	c.lsub
1558                    		.public	_prtgptent
1559                    		.external	c.irsh
1560                    		.public	_blockno
1561                    		.external	c.umod
1562                    		.public	_rxbuf
1563                    		.public	_sddatprt
1564                    		.public	_main
1565                    		.external	c.llsh
1566                    		.public	_sdprtpart
1567                    		.public	_cmd0
1568                    		.external	_spiio
1569                    		.external	c.ilsh
1570                    		.public	_cmd58
1571                    		.end
