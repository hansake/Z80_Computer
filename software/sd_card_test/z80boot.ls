   1                    	;    1  /*  z80boot.c
   2                    	;    2   *
   3                    	;    3   *  Boot code for my DIY Z80 Computer. This
   4                    	;    4   *  program is compiled with Whitesmiths/COSMIC
   5                    	;    5   *  C compiler for Z80.
   6                    	;    6   *
   7                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
   8                    	;    8   *
   9                    	;    9   *  Initializes the hardware and detects the
  10                    	;   10   *  presence and partitioning of an attached SD card.
  11                    	;   11   *
  12                    	;   12   *  You are free to use, modify, and redistribute
  13                    	;   13   *  this source code. No warranties are given.
  14                    	;   14   *  Hastily Cobbled Together 2021 and 2022
  15                    	;   15   *  by Hans-Ake Lund
  16                    	;   16   *
  17                    	;   17   */
  18                    	;   18  
  19                    	;   19  #include <std.h>
  20                    	;   20  #include "z80computer.h"
  21                    	;   21  #include "builddate.h"
  22                    		.psect	_text
  23                    	_builddate:
  24    0000  42        		.byte	66
  25    0001  75        		.byte	117
  26    0002  69        		.byte	105
  27    0003  6C        		.byte	108
  28    0004  74        		.byte	116
  29    0005  20        		.byte	32
  30    0006  32        		.byte	50
  31    0007  30        		.byte	48
  32    0008  32        		.byte	50
  33    0009  32        		.byte	50
  34    000A  2D        		.byte	45
  35    000B  30        		.byte	48
  36    000C  31        		.byte	49
  37    000D  2D        		.byte	45
  38    000E  32        		.byte	50
  39    000F  31        		.byte	49
  40    0010  20        		.byte	32
  41    0011  31        		.byte	49
  42    0012  34        		.byte	52
  43    0013  3A        		.byte	58
  44    0014  34        		.byte	52
  45    0015  37        		.byte	55
  46    0016  00        		.byte	0
  47                    	;   22  #include "progtype.h"
  48                    	;   23  
  49                    	;   24  #ifdef SDTEST
  50                    	;   25  #define PRGNAME "\nz80sdtest "
  51                    	;   26  #else
  52                    	;   27  #define PRGNAME "\nz80boot "
  53                    	;   28  #endif
  54                    	;   29  #define VERSION "version 0.4, "
  55                    	;   30  
  56                    	;   31  /* Response length in bytes
  57                    	;   32   */
  58                    	;   33  #define R1_LEN 1
  59                    	;   34  #define R3_LEN 5
  60                    	;   35  #define R7_LEN 5
  61                    	;   36  
  62                    	;   37  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
  63                    	;   38   * (The CRC7 byte in the tables below are only for information,
  64                    	;   39   * it is calculated by the sdcommand routine.)
  65                    	;   40   */
  66                    	;   41  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
  67                    	_cmd0:
  68    0017  40        		.byte	64
  69                    		.byte	[1]
  70                    		.byte	[1]
  71                    		.byte	[1]
  72                    		.byte	[1]
  73    001C  95        		.byte	149
  74                    	;   42  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
  75                    	_cmd8:
  76    001D  48        		.byte	72
  77                    		.byte	[1]
  78                    		.byte	[1]
  79    0020  01        		.byte	1
  80    0021  AA        		.byte	170
  81    0022  87        		.byte	135
  82                    	;   43  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
  83                    	_cmd9:
  84    0023  49        		.byte	73
  85                    		.byte	[1]
  86                    		.byte	[1]
  87                    		.byte	[1]
  88                    		.byte	[1]
  89    0028  AF        		.byte	175
  90                    	;   44  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
  91                    	_cmd10:
  92    0029  4A        		.byte	74
  93                    		.byte	[1]
  94                    		.byte	[1]
  95                    		.byte	[1]
  96                    		.byte	[1]
  97    002E  1B        		.byte	27
  98                    	;   45  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
  99                    	_cmd16:
 100    002F  50        		.byte	80
 101                    		.byte	[1]
 102                    		.byte	[1]
 103    0032  02        		.byte	2
 104                    		.byte	[1]
 105    0034  15        		.byte	21
 106                    	;   46  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
 107                    	_cmd17:
 108    0035  51        		.byte	81
 109                    		.byte	[1]
 110                    		.byte	[1]
 111                    		.byte	[1]
 112                    		.byte	[1]
 113    003A  55        		.byte	85
 114                    	;   47  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
 115                    	_cmd24:
 116    003B  58        		.byte	88
 117                    		.byte	[1]
 118                    		.byte	[1]
 119                    		.byte	[1]
 120                    		.byte	[1]
 121    0040  6F        		.byte	111
 122                    	;   48  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
 123                    	_cmd55:
 124    0041  77        		.byte	119
 125                    		.byte	[1]
 126                    		.byte	[1]
 127                    		.byte	[1]
 128                    		.byte	[1]
 129    0046  65        		.byte	101
 130                    	;   49  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
 131                    	_cmd58:
 132    0047  7A        		.byte	122
 133                    		.byte	[1]
 134                    		.byte	[1]
 135                    		.byte	[1]
 136                    		.byte	[1]
 137    004C  FD        		.byte	253
 138                    	;   50  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
 139                    	_acmd41:
 140    004D  69        		.byte	105
 141    004E  40        		.byte	64
 142                    		.byte	[1]
 143    0050  01        		.byte	1
 144    0051  AA        		.byte	170
 145    0052  33        		.byte	51
 146                    	;   51  
 147                    	;   52  /* Buffers
 148                    	;   53   */
 149                    	;   54  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
 150                    	;   55  
 151                    	;   56  unsigned char ocrreg[4];     /* SD card OCR register */
 152                    	;   57  unsigned char cidreg[16];    /* SD card CID register */
 153                    	;   58  unsigned char csdreg[16];    /* SD card CSD register */
 154                    	;   59  
 155                    	;   60  /* Variables
 156                    	;   61   */
 157                    	;   62  int curblkok;  /* if YES curblockno is read into buffer */
 158                    	;   63  int sdinitok;  /* SD card initialized and ready */
 159                    	;   64  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
 160                    	;   65  unsigned long blkmult;   /* block address multiplier */
 161                    	;   66  unsigned long curblkno;  /* block in buffer if curblkok == YES */
 162                    	;   67  
 163                    	;   68  /* CRC routines from:
 164                    	;   69   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
 165                    	;   70   */
 166                    	;   71  
 167                    	;   72  /*
 168                    	;   73  // Calculate CRC7
 169                    	;   74  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
 170                    	;   75  // input:
 171                    	;   76  //   crcIn - the CRC before (0 for first step)
 172                    	;   77  //   data - byte for CRC calculation
 173                    	;   78  // return: the new CRC7
 174                    	;   79  */
 175                    	;   80  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
 176                    	;   81      {
 177                    	_CRC7_one:
 178    0053  CD0000    		call	c.savs
 179    0056  F5        		push	af
 180    0057  F5        		push	af
 181    0058  F5        		push	af
 182    0059  F5        		push	af
 183                    	;   82      const unsigned char g = 0x89;
 184    005A  DD36F989  		ld	(ix-7),137
 185                    	;   83      unsigned char i;
 186                    	;   84  
 187                    	;   85      crcIn ^= data;
 188    005E  DD7E04    		ld	a,(ix+4)
 189    0061  DDAE06    		xor	(ix+6)
 190    0064  DD7704    		ld	(ix+4),a
 191    0067  DD7E05    		ld	a,(ix+5)
 192    006A  DDAE07    		xor	(ix+7)
 193    006D  DD7705    		ld	(ix+5),a
 194                    	;   86      for (i = 0; i < 8; i++)
 195    0070  DD36F800  		ld	(ix-8),0
 196                    	L1:
 197    0074  DD7EF8    		ld	a,(ix-8)
 198    0077  FE08      		cp	8
 199    0079  302F      		jr	nc,L11
 200                    	;   87          {
 201                    	;   88          if (crcIn & 0x80) crcIn ^= g;
 202    007B  DD6E04    		ld	l,(ix+4)
 203    007E  DD6605    		ld	h,(ix+5)
 204    0081  CB7D      		bit	7,l
 205    0083  2813      		jr	z,L14
 206    0085  DD6EF9    		ld	l,(ix-7)
 207    0088  97        		sub	a
 208    0089  67        		ld	h,a
 209    008A  DD7E04    		ld	a,(ix+4)
 210    008D  AD        		xor	l
 211    008E  DD7704    		ld	(ix+4),a
 212    0091  DD7E05    		ld	a,(ix+5)
 213    0094  AC        		xor	h
 214    0095  DD7705    		ld	(ix+5),a
 215                    	L14:
 216                    	;   89          crcIn <<= 1;
 217    0098  DD6E04    		ld	l,(ix+4)
 218    009B  DD6605    		ld	h,(ix+5)
 219    009E  29        		add	hl,hl
 220    009F  DD7504    		ld	(ix+4),l
 221    00A2  DD7405    		ld	(ix+5),h
 222                    	;   90          }
 223    00A5  DD34F8    		inc	(ix-8)
 224    00A8  18CA      		jr	L1
 225                    	L11:
 226                    	;   91  
 227                    	;   92      return crcIn;
 228    00AA  DD6E04    		ld	l,(ix+4)
 229    00AD  DD6605    		ld	h,(ix+5)
 230    00B0  4D        		ld	c,l
 231    00B1  44        		ld	b,h
 232    00B2  C30000    		jp	c.rets
 233                    	;   93      }
 234                    	;   94  
 235                    	;   95  /*
 236                    	;   96  // Calculate CRC16 CCITT
 237                    	;   97  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
 238                    	;   98  // input:
 239                    	;   99  //   crcIn - the CRC before (0 for rist step)
 240                    	;  100  //   data - byte for CRC calculation
 241                    	;  101  // return: the CRC16 value
 242                    	;  102  */
 243                    	;  103  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
 244                    	;  104      {
 245                    	_CRC16_one:
 246    00B5  CD0000    		call	c.savs
 247                    	;  105      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
 248    00B8  DD6E04    		ld	l,(ix+4)
 249    00BB  DD6605    		ld	h,(ix+5)
 250    00BE  E5        		push	hl
 251    00BF  210800    		ld	hl,8
 252    00C2  E5        		push	hl
 253    00C3  CD0000    		call	c.ursh
 254    00C6  E1        		pop	hl
 255    00C7  E5        		push	hl
 256    00C8  DD6E04    		ld	l,(ix+4)
 257    00CB  DD6605    		ld	h,(ix+5)
 258    00CE  29        		add	hl,hl
 259    00CF  29        		add	hl,hl
 260    00D0  29        		add	hl,hl
 261    00D1  29        		add	hl,hl
 262    00D2  29        		add	hl,hl
 263    00D3  29        		add	hl,hl
 264    00D4  29        		add	hl,hl
 265    00D5  29        		add	hl,hl
 266    00D6  C1        		pop	bc
 267    00D7  79        		ld	a,c
 268    00D8  B5        		or	l
 269    00D9  4F        		ld	c,a
 270    00DA  78        		ld	a,b
 271    00DB  B4        		or	h
 272    00DC  47        		ld	b,a
 273    00DD  DD7104    		ld	(ix+4),c
 274    00E0  DD7005    		ld	(ix+5),b
 275                    	;  106      crcIn ^=  data;
 276    00E3  DD7E04    		ld	a,(ix+4)
 277    00E6  DDAE06    		xor	(ix+6)
 278    00E9  DD7704    		ld	(ix+4),a
 279    00EC  DD7E05    		ld	a,(ix+5)
 280    00EF  DDAE07    		xor	(ix+7)
 281    00F2  DD7705    		ld	(ix+5),a
 282                    	;  107      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
 283    00F5  DD6E04    		ld	l,(ix+4)
 284    00F8  DD6605    		ld	h,(ix+5)
 285    00FB  7D        		ld	a,l
 286    00FC  E6FF      		and	255
 287    00FE  6F        		ld	l,a
 288    00FF  97        		sub	a
 289    0100  67        		ld	h,a
 290    0101  4D        		ld	c,l
 291    0102  97        		sub	a
 292    0103  47        		ld	b,a
 293    0104  C5        		push	bc
 294    0105  210400    		ld	hl,4
 295    0108  E5        		push	hl
 296    0109  CD0000    		call	c.irsh
 297    010C  E1        		pop	hl
 298    010D  DD7E04    		ld	a,(ix+4)
 299    0110  AD        		xor	l
 300    0111  DD7704    		ld	(ix+4),a
 301    0114  DD7E05    		ld	a,(ix+5)
 302    0117  AC        		xor	h
 303    0118  DD7705    		ld	(ix+5),a
 304                    	;  108      crcIn ^= (crcIn << 8) << 4;
 305    011B  DD6E04    		ld	l,(ix+4)
 306    011E  DD6605    		ld	h,(ix+5)
 307    0121  29        		add	hl,hl
 308    0122  29        		add	hl,hl
 309    0123  29        		add	hl,hl
 310    0124  29        		add	hl,hl
 311    0125  29        		add	hl,hl
 312    0126  29        		add	hl,hl
 313    0127  29        		add	hl,hl
 314    0128  29        		add	hl,hl
 315    0129  29        		add	hl,hl
 316    012A  29        		add	hl,hl
 317    012B  29        		add	hl,hl
 318    012C  29        		add	hl,hl
 319    012D  DD7E04    		ld	a,(ix+4)
 320    0130  AD        		xor	l
 321    0131  DD7704    		ld	(ix+4),a
 322    0134  DD7E05    		ld	a,(ix+5)
 323    0137  AC        		xor	h
 324    0138  DD7705    		ld	(ix+5),a
 325                    	;  109      crcIn ^= ((crcIn & 0xff) << 4) << 1;
 326    013B  DD6E04    		ld	l,(ix+4)
 327    013E  DD6605    		ld	h,(ix+5)
 328    0141  7D        		ld	a,l
 329    0142  E6FF      		and	255
 330    0144  6F        		ld	l,a
 331    0145  97        		sub	a
 332    0146  67        		ld	h,a
 333    0147  29        		add	hl,hl
 334    0148  29        		add	hl,hl
 335    0149  29        		add	hl,hl
 336    014A  29        		add	hl,hl
 337    014B  29        		add	hl,hl
 338    014C  DD7E04    		ld	a,(ix+4)
 339    014F  AD        		xor	l
 340    0150  DD7704    		ld	(ix+4),a
 341    0153  DD7E05    		ld	a,(ix+5)
 342    0156  AC        		xor	h
 343    0157  DD7705    		ld	(ix+5),a
 344                    	;  110  
 345                    	;  111      return crcIn;
 346    015A  DD4E04    		ld	c,(ix+4)
 347    015D  DD4605    		ld	b,(ix+5)
 348    0160  C30000    		jp	c.rets
 349                    	;  112      }
 350                    	;  113  
 351                    	;  114  /* Send command to SD card and recieve answer.
 352                    	;  115   * A command is 5 bytes long and is followed by
 353                    	;  116   * a CRC7 checksum byte.
 354                    	;  117   * Returns a pointer to the response
 355                    	;  118   * or 0 if no response start bit found.
 356                    	;  119   */
 357                    	;  120  unsigned char *sdcommand(unsigned char *sdcmdp,
 358                    	;  121                           unsigned char *recbuf, int recbytes)
 359                    	;  122      {
 360                    	_sdcommand:
 361    0163  CD0000    		call	c.savs
 362    0166  21F2FF    		ld	hl,65522
 363    0169  39        		add	hl,sp
 364    016A  F9        		ld	sp,hl
 365                    	;  123      int searchn;  /* byte counter to search for response */
 366                    	;  124      int sdcbytes; /* byte counter for bytes to send */
 367                    	;  125      unsigned char *retptr; /* pointer used to store response */
 368                    	;  126      unsigned char rbyte;   /* recieved byte */
 369                    	;  127      unsigned char crc = 0; /* calculated CRC7 */
 370    016B  DD36F200  		ld	(ix-14),0
 371                    	;  128  
 372                    	;  129      /* send 8*2 clockpules */
 373                    	;  130      spiio(0xff);
 374    016F  21FF00    		ld	hl,255
 375    0172  CD0000    		call	_spiio
 376                    	;  131      spiio(0xff);
 377    0175  21FF00    		ld	hl,255
 378    0178  CD0000    		call	_spiio
 379                    	;  132      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
 380    017B  DD36F605  		ld	(ix-10),5
 381    017F  DD36F700  		ld	(ix-9),0
 382                    	L15:
 383    0183  97        		sub	a
 384    0184  DD96F6    		sub	(ix-10)
 385    0187  3E00      		ld	a,0
 386    0189  DD9EF7    		sbc	a,(ix-9)
 387    018C  F2C801    		jp	p,L16
 388                    	;  133          {
 389                    	;  134          crc = CRC7_one(crc, *sdcmdp);
 390    018F  DD6E04    		ld	l,(ix+4)
 391    0192  DD6605    		ld	h,(ix+5)
 392    0195  6E        		ld	l,(hl)
 393    0196  97        		sub	a
 394    0197  67        		ld	h,a
 395    0198  E5        		push	hl
 396    0199  DD6EF2    		ld	l,(ix-14)
 397    019C  97        		sub	a
 398    019D  67        		ld	h,a
 399    019E  CD5300    		call	_CRC7_one
 400    01A1  F1        		pop	af
 401    01A2  DD71F2    		ld	(ix-14),c
 402                    	;  135          spiio(*sdcmdp++);
 403    01A5  DD6E04    		ld	l,(ix+4)
 404    01A8  DD6605    		ld	h,(ix+5)
 405    01AB  DD3404    		inc	(ix+4)
 406    01AE  2003      		jr	nz,L01
 407    01B0  DD3405    		inc	(ix+5)
 408                    	L01:
 409    01B3  6E        		ld	l,(hl)
 410    01B4  97        		sub	a
 411    01B5  67        		ld	h,a
 412    01B6  CD0000    		call	_spiio
 413                    	;  136          }
 414    01B9  DD6EF6    		ld	l,(ix-10)
 415    01BC  DD66F7    		ld	h,(ix-9)
 416    01BF  2B        		dec	hl
 417    01C0  DD75F6    		ld	(ix-10),l
 418    01C3  DD74F7    		ld	(ix-9),h
 419    01C6  18BB      		jr	L15
 420                    	L16:
 421                    	;  137      spiio(crc | 0x01);
 422    01C8  DD6EF2    		ld	l,(ix-14)
 423    01CB  97        		sub	a
 424    01CC  67        		ld	h,a
 425    01CD  CBC5      		set	0,l
 426    01CF  CD0000    		call	_spiio
 427                    	;  138      /* search for recieved byte with start bit
 428                    	;  139         for a maximum of 10 recieved bytes  */
 429                    	;  140      for (searchn = 10; 0 < searchn; searchn--)
 430    01D2  DD36F80A  		ld	(ix-8),10
 431    01D6  DD36F900  		ld	(ix-7),0
 432                    	L111:
 433    01DA  97        		sub	a
 434    01DB  DD96F8    		sub	(ix-8)
 435    01DE  3E00      		ld	a,0
 436    01E0  DD9EF9    		sbc	a,(ix-7)
 437    01E3  F20502    		jp	p,L121
 438                    	;  141          {
 439                    	;  142          rbyte = spiio(0xff);
 440    01E6  21FF00    		ld	hl,255
 441    01E9  CD0000    		call	_spiio
 442    01EC  DD71F3    		ld	(ix-13),c
 443                    	;  143          if ((rbyte & 0x80) == 0)
 444    01EF  DD6EF3    		ld	l,(ix-13)
 445    01F2  CB7D      		bit	7,l
 446    01F4  280F      		jr	z,L121
 447                    	;  144              break;
 448                    	L131:
 449    01F6  DD6EF8    		ld	l,(ix-8)
 450    01F9  DD66F9    		ld	h,(ix-7)
 451    01FC  2B        		dec	hl
 452    01FD  DD75F8    		ld	(ix-8),l
 453    0200  DD74F9    		ld	(ix-7),h
 454    0203  18D5      		jr	L111
 455                    	L121:
 456                    	;  145          }
 457                    	;  146      if (searchn == 0) /* no start bit found */
 458    0205  DD7EF8    		ld	a,(ix-8)
 459    0208  DDB6F9    		or	(ix-7)
 460    020B  2006      		jr	nz,L161
 461                    	;  147          return (NO);
 462    020D  010000    		ld	bc,0
 463    0210  C30000    		jp	c.rets
 464                    	L161:
 465                    	;  148      retptr = recbuf;
 466    0213  DD7E06    		ld	a,(ix+6)
 467    0216  DD77F4    		ld	(ix-12),a
 468    0219  DD7E07    		ld	a,(ix+7)
 469    021C  DD77F5    		ld	(ix-11),a
 470                    	;  149      *retptr++ = rbyte;
 471    021F  DD6EF4    		ld	l,(ix-12)
 472    0222  DD66F5    		ld	h,(ix-11)
 473    0225  DD34F4    		inc	(ix-12)
 474    0228  2003      		jr	nz,L21
 475    022A  DD34F5    		inc	(ix-11)
 476                    	L21:
 477    022D  DD7EF3    		ld	a,(ix-13)
 478    0230  77        		ld	(hl),a
 479                    	L171:
 480                    	;  150      for (; 1 < recbytes; recbytes--) /* recieve bytes */
 481    0231  3E01      		ld	a,1
 482    0233  DD9608    		sub	(ix+8)
 483    0236  3E00      		ld	a,0
 484    0238  DD9E09    		sbc	a,(ix+9)
 485    023B  F26402    		jp	p,L102
 486                    	;  151          *retptr++ = spiio(0xff);
 487    023E  DD6EF4    		ld	l,(ix-12)
 488    0241  DD66F5    		ld	h,(ix-11)
 489    0244  DD34F4    		inc	(ix-12)
 490    0247  2003      		jr	nz,L41
 491    0249  DD34F5    		inc	(ix-11)
 492                    	L41:
 493    024C  E5        		push	hl
 494    024D  21FF00    		ld	hl,255
 495    0250  CD0000    		call	_spiio
 496    0253  E1        		pop	hl
 497    0254  71        		ld	(hl),c
 498    0255  DD6E08    		ld	l,(ix+8)
 499    0258  DD6609    		ld	h,(ix+9)
 500    025B  2B        		dec	hl
 501    025C  DD7508    		ld	(ix+8),l
 502    025F  DD7409    		ld	(ix+9),h
 503    0262  18CD      		jr	L171
 504                    	L102:
 505                    	;  152      return (recbuf);
 506    0264  DD4E06    		ld	c,(ix+6)
 507    0267  DD4607    		ld	b,(ix+7)
 508    026A  C30000    		jp	c.rets
 509                    	;  153      }
 510                    	;  154  
 511                    	;  155  /* Initialise SD card interface
 512                    	;  156   *
 513                    	;  157   * returns YES if ok and NO if not ok
 514                    	;  158   *
 515                    	;  159   * References:
 516                    	;  160   *   https://www.sdcard.org/downloads/pls/
 517                    	;  161   *      Physical Layer Simplified Specification version 8.0
 518                    	;  162   *
 519                    	;  163   * A nice flowchart how to initialize:
 520                    	;  164   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
 521                    	;  165   *
 522                    	;  166   */
 523                    	;  167  int sdinit()
 524                    	;  168      {
 525                    	_sdinit:
 526    026D  CD0000    		call	c.savs0
 527    0270  21E6FF    		ld	hl,65510
 528    0273  39        		add	hl,sp
 529    0274  F9        		ld	sp,hl
 530                    	;  169      int nbytes;  /* byte counter */
 531                    	;  170      int tries;   /* tries to get to active state or searching for data  */
 532                    	;  171      int wtloop;  /* timer loop when trying to enter active state */
 533                    	;  172      unsigned char cmdbuf[5];   /* buffer to build command in */
 534                    	;  173      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 535                    	;  174      unsigned char *statptr;    /* pointer to returned status from SD command */
 536                    	;  175      unsigned char crc;         /* crc register for CID and CSD */
 537                    	;  176      unsigned char rbyte;       /* recieved byte */
 538                    	;  177  #ifdef SDTEST
 539                    	;  178      unsigned char *prtptr;     /* for debug printing */
 540                    	;  179  #endif
 541                    	;  180  
 542                    	;  181      ledon();
 543    0275  CD0000    		call	_ledon
 544                    	;  182      spideselect();
 545    0278  CD0000    		call	_spideselect
 546                    	;  183      sdinitok = NO;
 547    027B  210000    		ld	hl,0
 548    027E  220A00    		ld	(_sdinitok),hl
 549                    	;  184  
 550                    	;  185      /* start to generate 9*8 clock pulses with not selected SD card */
 551                    	;  186      for (nbytes = 9; 0 < nbytes; nbytes--)
 552    0281  DD36F809  		ld	(ix-8),9
 553    0285  DD36F900  		ld	(ix-7),0
 554                    	L132:
 555    0289  97        		sub	a
 556    028A  DD96F8    		sub	(ix-8)
 557    028D  3E00      		ld	a,0
 558    028F  DD9EF9    		sbc	a,(ix-7)
 559    0292  F2AA02    		jp	p,L142
 560                    	;  187          spiio(0xff);
 561    0295  21FF00    		ld	hl,255
 562    0298  CD0000    		call	_spiio
 563    029B  DD6EF8    		ld	l,(ix-8)
 564    029E  DD66F9    		ld	h,(ix-7)
 565    02A1  2B        		dec	hl
 566    02A2  DD75F8    		ld	(ix-8),l
 567    02A5  DD74F9    		ld	(ix-7),h
 568    02A8  18DF      		jr	L132
 569                    	L142:
 570                    	;  188  #ifdef SDTEST
 571                    	;  189      printf("\nSent 8*8 (72) clock pulses, select not active\n");
 572                    	;  190  #endif
 573                    	;  191      spiselect();
 574    02AA  CD0000    		call	_spiselect
 575                    	;  192  
 576                    	;  193      /* CMD0: GO_IDLE_STATE */
 577                    	;  194      memcpy(cmdbuf, cmd0, 5);
 578    02AD  210500    		ld	hl,5
 579    02B0  E5        		push	hl
 580    02B1  211700    		ld	hl,_cmd0
 581    02B4  E5        		push	hl
 582    02B5  DDE5      		push	ix
 583    02B7  C1        		pop	bc
 584    02B8  21EFFF    		ld	hl,65519
 585    02BB  09        		add	hl,bc
 586    02BC  CD0000    		call	_memcpy
 587    02BF  F1        		pop	af
 588    02C0  F1        		pop	af
 589                    	;  195      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 590    02C1  210100    		ld	hl,1
 591    02C4  E5        		push	hl
 592    02C5  DDE5      		push	ix
 593    02C7  C1        		pop	bc
 594    02C8  21EAFF    		ld	hl,65514
 595    02CB  09        		add	hl,bc
 596    02CC  E5        		push	hl
 597    02CD  DDE5      		push	ix
 598    02CF  C1        		pop	bc
 599    02D0  21EFFF    		ld	hl,65519
 600    02D3  09        		add	hl,bc
 601    02D4  CD6301    		call	_sdcommand
 602    02D7  F1        		pop	af
 603    02D8  F1        		pop	af
 604    02D9  DD71E8    		ld	(ix-24),c
 605    02DC  DD70E9    		ld	(ix-23),b
 606                    	;  196  #ifdef SDTEST
 607                    	;  197      if (!statptr)
 608                    	;  198          printf("CMD0: no response\n");
 609                    	;  199      else
 610                    	;  200          printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
 611                    	;  201  #endif
 612                    	;  202      if (!statptr)
 613    02DF  DD7EE8    		ld	a,(ix-24)
 614    02E2  DDB6E9    		or	(ix-23)
 615    02E5  200C      		jr	nz,L172
 616                    	;  203          {
 617                    	;  204          spideselect();
 618    02E7  CD0000    		call	_spideselect
 619                    	;  205          ledoff();
 620    02EA  CD0000    		call	_ledoff
 621                    	;  206          return (NO);
 622    02ED  010000    		ld	bc,0
 623    02F0  C30000    		jp	c.rets0
 624                    	L172:
 625                    	;  207          }
 626                    	;  208      /* CMD8: SEND_IF_COND */
 627                    	;  209      memcpy(cmdbuf, cmd8, 5);
 628    02F3  210500    		ld	hl,5
 629    02F6  E5        		push	hl
 630    02F7  211D00    		ld	hl,_cmd8
 631    02FA  E5        		push	hl
 632    02FB  DDE5      		push	ix
 633    02FD  C1        		pop	bc
 634    02FE  21EFFF    		ld	hl,65519
 635    0301  09        		add	hl,bc
 636    0302  CD0000    		call	_memcpy
 637    0305  F1        		pop	af
 638    0306  F1        		pop	af
 639                    	;  210      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
 640    0307  210500    		ld	hl,5
 641    030A  E5        		push	hl
 642    030B  DDE5      		push	ix
 643    030D  C1        		pop	bc
 644    030E  21EAFF    		ld	hl,65514
 645    0311  09        		add	hl,bc
 646    0312  E5        		push	hl
 647    0313  DDE5      		push	ix
 648    0315  C1        		pop	bc
 649    0316  21EFFF    		ld	hl,65519
 650    0319  09        		add	hl,bc
 651    031A  CD6301    		call	_sdcommand
 652    031D  F1        		pop	af
 653    031E  F1        		pop	af
 654    031F  DD71E8    		ld	(ix-24),c
 655    0322  DD70E9    		ld	(ix-23),b
 656                    	;  211  #ifdef SDTEST
 657                    	;  212      if (!statptr)
 658                    	;  213          printf("CMD8: no response\n");
 659                    	;  214      else
 660                    	;  215          {
 661                    	;  216          printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
 662                    	;  217                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
 663                    	;  218          if (!(statptr[0] & 0xfe)) /* no error */
 664                    	;  219              {
 665                    	;  220              if (statptr[4] == 0xaa)
 666                    	;  221                  printf("echo back ok, ");
 667                    	;  222              else
 668                    	;  223                  printf("invalid echo back\n");
 669                    	;  224              }
 670                    	;  225          }
 671                    	;  226  #endif
 672                    	;  227      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
 673    0325  DD7EE8    		ld	a,(ix-24)
 674    0328  DDB6E9    		or	(ix-23)
 675    032B  2810      		jr	z,L113
 676    032D  DD6EE8    		ld	l,(ix-24)
 677    0330  DD66E9    		ld	h,(ix-23)
 678    0333  6E        		ld	l,(hl)
 679    0334  97        		sub	a
 680    0335  67        		ld	h,a
 681    0336  CB85      		res	0,l
 682    0338  7D        		ld	a,l
 683    0339  B4        		or	h
 684    033A  CA9E03    		jp	z,L103
 685                    	L113:
 686                    	;  228          {
 687                    	;  229          sdver2 = NO;
 688    033D  210000    		ld	hl,0
 689    0340  220800    		ld	(_sdver2),hl
 690                    	;  230  #ifdef SDTEST
 691                    	;  231          printf("probably SD ver. 1\n");
 692                    	;  232  #endif
 693                    	;  233          }
 694                    	;  234      else
 695                    	L123:
 696                    	;  235          {
 697                    	;  236          sdver2 = YES;
 698                    	;  237          if (statptr[4] != 0xaa) /* but invalid echo back */
 699                    	;  238              {
 700                    	;  239              spideselect();
 701                    	;  240              ledoff();
 702                    	;  241              return (NO);
 703                    	;  242              }
 704                    	;  243  #ifdef SDTEST
 705                    	;  244          printf("SD ver 2\n");
 706                    	;  245  #endif
 707                    	;  246          }
 708                    	;  247  
 709                    	;  248      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
 710                    	;  249      for (tries = 0; tries < 20; tries++)
 711    0343  DD36F600  		ld	(ix-10),0
 712    0347  DD36F700  		ld	(ix-9),0
 713                    	L143:
 714    034B  DD7EF6    		ld	a,(ix-10)
 715    034E  D614      		sub	20
 716    0350  DD7EF7    		ld	a,(ix-9)
 717    0353  DE00      		sbc	a,0
 718    0355  F25804    		jp	p,L153
 719                    	;  250          {
 720                    	;  251          memcpy(cmdbuf, cmd55, 5);
 721    0358  210500    		ld	hl,5
 722    035B  E5        		push	hl
 723    035C  214100    		ld	hl,_cmd55
 724    035F  E5        		push	hl
 725    0360  DDE5      		push	ix
 726    0362  C1        		pop	bc
 727    0363  21EFFF    		ld	hl,65519
 728    0366  09        		add	hl,bc
 729    0367  CD0000    		call	_memcpy
 730    036A  F1        		pop	af
 731    036B  F1        		pop	af
 732                    	;  252          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 733    036C  210100    		ld	hl,1
 734    036F  E5        		push	hl
 735    0370  DDE5      		push	ix
 736    0372  C1        		pop	bc
 737    0373  21EAFF    		ld	hl,65514
 738    0376  09        		add	hl,bc
 739    0377  E5        		push	hl
 740    0378  DDE5      		push	ix
 741    037A  C1        		pop	bc
 742    037B  21EFFF    		ld	hl,65519
 743    037E  09        		add	hl,bc
 744    037F  CD6301    		call	_sdcommand
 745    0382  F1        		pop	af
 746    0383  F1        		pop	af
 747    0384  DD71E8    		ld	(ix-24),c
 748    0387  DD70E9    		ld	(ix-23),b
 749                    	;  253  #ifdef SDTEST
 750                    	;  254          if (!statptr)
 751                    	;  255              printf("CMD55: no response\n");
 752                    	;  256          else
 753                    	;  257              printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
 754                    	;  258  #endif
 755                    	;  259          if (!statptr)
 756    038A  DD7EE8    		ld	a,(ix-24)
 757    038D  DDB6E9    		or	(ix-23)
 758    0390  2039      		jr	nz,L104
 759                    	;  260              {
 760                    	;  261              spideselect();
 761    0392  CD0000    		call	_spideselect
 762                    	;  262              ledoff();
 763    0395  CD0000    		call	_ledoff
 764                    	;  263              return (NO);
 765    0398  010000    		ld	bc,0
 766    039B  C30000    		jp	c.rets0
 767                    	L103:
 768    039E  210100    		ld	hl,1
 769    03A1  220800    		ld	(_sdver2),hl
 770    03A4  DD6EE8    		ld	l,(ix-24)
 771    03A7  DD66E9    		ld	h,(ix-23)
 772    03AA  23        		inc	hl
 773    03AB  23        		inc	hl
 774    03AC  23        		inc	hl
 775    03AD  23        		inc	hl
 776    03AE  7E        		ld	a,(hl)
 777    03AF  FEAA      		cp	170
 778    03B1  CA4303    		jp	z,L123
 779    03B4  CD0000    		call	_spideselect
 780    03B7  CD0000    		call	_ledoff
 781    03BA  010000    		ld	bc,0
 782    03BD  C30000    		jp	c.rets0
 783                    	L163:
 784    03C0  DD34F6    		inc	(ix-10)
 785    03C3  2003      		jr	nz,L02
 786    03C5  DD34F7    		inc	(ix-9)
 787                    	L02:
 788    03C8  C34B03    		jp	L143
 789                    	L104:
 790                    	;  264              }
 791                    	;  265          memcpy(cmdbuf, acmd41, 5);
 792    03CB  210500    		ld	hl,5
 793    03CE  E5        		push	hl
 794    03CF  214D00    		ld	hl,_acmd41
 795    03D2  E5        		push	hl
 796    03D3  DDE5      		push	ix
 797    03D5  C1        		pop	bc
 798    03D6  21EFFF    		ld	hl,65519
 799    03D9  09        		add	hl,bc
 800    03DA  CD0000    		call	_memcpy
 801    03DD  F1        		pop	af
 802    03DE  F1        		pop	af
 803                    	;  266          if (sdver2)
 804    03DF  2A0800    		ld	hl,(_sdver2)
 805    03E2  7C        		ld	a,h
 806    03E3  B5        		or	l
 807    03E4  2806      		jr	z,L114
 808                    	;  267              cmdbuf[1] = 0x40;
 809    03E6  DD36F040  		ld	(ix-16),64
 810                    	;  268          else
 811    03EA  1804      		jr	L124
 812                    	L114:
 813                    	;  269              cmdbuf[1] = 0x00;
 814    03EC  DD36F000  		ld	(ix-16),0
 815                    	L124:
 816                    	;  270          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 817    03F0  210100    		ld	hl,1
 818    03F3  E5        		push	hl
 819    03F4  DDE5      		push	ix
 820    03F6  C1        		pop	bc
 821    03F7  21EAFF    		ld	hl,65514
 822    03FA  09        		add	hl,bc
 823    03FB  E5        		push	hl
 824    03FC  DDE5      		push	ix
 825    03FE  C1        		pop	bc
 826    03FF  21EFFF    		ld	hl,65519
 827    0402  09        		add	hl,bc
 828    0403  CD6301    		call	_sdcommand
 829    0406  F1        		pop	af
 830    0407  F1        		pop	af
 831    0408  DD71E8    		ld	(ix-24),c
 832    040B  DD70E9    		ld	(ix-23),b
 833                    	;  271  #ifdef SDTEST
 834                    	;  272          if (!statptr)
 835                    	;  273              printf("ACMD41: no response\n");
 836                    	;  274          else
 837                    	;  275              printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
 838                    	;  276                     statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
 839                    	;  277  #endif
 840                    	;  278          if (!statptr)
 841    040E  DD7EE8    		ld	a,(ix-24)
 842    0411  DDB6E9    		or	(ix-23)
 843    0414  200C      		jr	nz,L134
 844                    	;  279              {
 845                    	;  280              spideselect();
 846    0416  CD0000    		call	_spideselect
 847                    	;  281              ledoff();
 848    0419  CD0000    		call	_ledoff
 849                    	;  282              return (NO);
 850    041C  010000    		ld	bc,0
 851    041F  C30000    		jp	c.rets0
 852                    	L134:
 853                    	;  283              }
 854                    	;  284          if (statptr[0] == 0x00) /* now the SD card is ready */
 855    0422  DD6EE8    		ld	l,(ix-24)
 856    0425  DD66E9    		ld	h,(ix-23)
 857    0428  7E        		ld	a,(hl)
 858    0429  B7        		or	a
 859    042A  282C      		jr	z,L153
 860                    	;  285              {
 861                    	;  286              break;
 862                    	;  287              }
 863                    	;  288          for (wtloop = 0; wtloop < tries * 100; wtloop++)
 864    042C  DD36F400  		ld	(ix-12),0
 865    0430  DD36F500  		ld	(ix-11),0
 866                    	L154:
 867    0434  DD6EF6    		ld	l,(ix-10)
 868    0437  DD66F7    		ld	h,(ix-9)
 869    043A  E5        		push	hl
 870    043B  216400    		ld	hl,100
 871    043E  E5        		push	hl
 872    043F  CD0000    		call	c.imul
 873    0442  E1        		pop	hl
 874    0443  DD7EF4    		ld	a,(ix-12)
 875    0446  95        		sub	l
 876    0447  DD7EF5    		ld	a,(ix-11)
 877    044A  9C        		sbc	a,h
 878    044B  F2C003    		jp	p,L163
 879                    	L174:
 880    044E  DD34F4    		inc	(ix-12)
 881    0451  2003      		jr	nz,L22
 882    0453  DD34F5    		inc	(ix-11)
 883                    	L22:
 884    0456  18DC      		jr	L154
 885                    	L153:
 886                    	;  289              ; /* wait loop, time increasing for each try */
 887                    	;  290          }
 888                    	;  291  
 889                    	;  292      /* CMD58: READ_OCR */
 890                    	;  293      /* According to the flow chart this should not work
 891                    	;  294         for SD ver. 1 but the response is ok anyway
 892                    	;  295         all tested SD cards  */
 893                    	;  296      memcpy(cmdbuf, cmd58, 5);
 894    0458  210500    		ld	hl,5
 895    045B  E5        		push	hl
 896    045C  214700    		ld	hl,_cmd58
 897    045F  E5        		push	hl
 898    0460  DDE5      		push	ix
 899    0462  C1        		pop	bc
 900    0463  21EFFF    		ld	hl,65519
 901    0466  09        		add	hl,bc
 902    0467  CD0000    		call	_memcpy
 903    046A  F1        		pop	af
 904    046B  F1        		pop	af
 905                    	;  297      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
 906    046C  210500    		ld	hl,5
 907    046F  E5        		push	hl
 908    0470  DDE5      		push	ix
 909    0472  C1        		pop	bc
 910    0473  21EAFF    		ld	hl,65514
 911    0476  09        		add	hl,bc
 912    0477  E5        		push	hl
 913    0478  DDE5      		push	ix
 914    047A  C1        		pop	bc
 915    047B  21EFFF    		ld	hl,65519
 916    047E  09        		add	hl,bc
 917    047F  CD6301    		call	_sdcommand
 918    0482  F1        		pop	af
 919    0483  F1        		pop	af
 920    0484  DD71E8    		ld	(ix-24),c
 921    0487  DD70E9    		ld	(ix-23),b
 922                    	;  298  #ifdef SDTEST
 923                    	;  299      if (!statptr)
 924                    	;  300          printf("CMD58: no response\n");
 925                    	;  301      else
 926                    	;  302          printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
 927                    	;  303                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
 928                    	;  304  #endif
 929                    	;  305      if (!statptr)
 930    048A  DD7EE8    		ld	a,(ix-24)
 931    048D  DDB6E9    		or	(ix-23)
 932    0490  200C      		jr	nz,L115
 933                    	;  306          {
 934                    	;  307          spideselect();
 935    0492  CD0000    		call	_spideselect
 936                    	;  308          ledoff();
 937    0495  CD0000    		call	_ledoff
 938                    	;  309          return (NO);
 939    0498  010000    		ld	bc,0
 940    049B  C30000    		jp	c.rets0
 941                    	L115:
 942                    	;  310          }
 943                    	;  311      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
 944    049E  210400    		ld	hl,4
 945    04A1  E5        		push	hl
 946    04A2  DD6EE8    		ld	l,(ix-24)
 947    04A5  DD66E9    		ld	h,(ix-23)
 948    04A8  23        		inc	hl
 949    04A9  E5        		push	hl
 950    04AA  212E00    		ld	hl,_ocrreg
 951    04AD  CD0000    		call	_memcpy
 952    04B0  F1        		pop	af
 953    04B1  F1        		pop	af
 954                    	;  312      blkmult = 1; /* assume block address */
 955    04B2  3E01      		ld	a,1
 956    04B4  320600    		ld	(_blkmult+2),a
 957    04B7  87        		add	a,a
 958    04B8  9F        		sbc	a,a
 959    04B9  320700    		ld	(_blkmult+3),a
 960    04BC  320500    		ld	(_blkmult+1),a
 961    04BF  320400    		ld	(_blkmult),a
 962                    	;  313      if (ocrreg[0] & 0x80)
 963    04C2  3A2E00    		ld	a,(_ocrreg)
 964    04C5  CB7F      		bit	7,a
 965    04C7  6F        		ld	l,a
 966    04C8  2817      		jr	z,L125
 967                    	;  314          {
 968                    	;  315          /* SD Ver.2+ */
 969                    	;  316          if (!(ocrreg[0] & 0x40))
 970    04CA  3A2E00    		ld	a,(_ocrreg)
 971    04CD  CB77      		bit	6,a
 972    04CF  6F        		ld	l,a
 973    04D0  200F      		jr	nz,L125
 974                    	;  317              {
 975                    	;  318              /* SD Ver.2+, Byte address */
 976                    	;  319              blkmult = 512;
 977    04D2  97        		sub	a
 978    04D3  320400    		ld	(_blkmult),a
 979    04D6  320500    		ld	(_blkmult+1),a
 980    04D9  320600    		ld	(_blkmult+2),a
 981    04DC  3E02      		ld	a,2
 982    04DE  320700    		ld	(_blkmult+3),a
 983                    	L125:
 984                    	;  320              }
 985                    	;  321          }
 986                    	;  322  
 987                    	;  323      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
 988                    	;  324      if (blkmult == 512)
 989    04E1  210400    		ld	hl,_blkmult
 990    04E4  E5        		push	hl
 991    04E5  97        		sub	a
 992    04E6  320000    		ld	(c.r0),a
 993    04E9  320100    		ld	(c.r0+1),a
 994    04EC  320200    		ld	(c.r0+2),a
 995    04EF  3E02      		ld	a,2
 996    04F1  320300    		ld	(c.r0+3),a
 997    04F4  210000    		ld	hl,c.r0
 998    04F7  E5        		push	hl
 999    04F8  CD0000    		call	c.lcmp
1000    04FB  2046      		jr	nz,L145
1001                    	;  325          {
1002                    	;  326          memcpy(cmdbuf, cmd16, 5);
1003    04FD  210500    		ld	hl,5
1004    0500  E5        		push	hl
1005    0501  212F00    		ld	hl,_cmd16
1006    0504  E5        		push	hl
1007    0505  DDE5      		push	ix
1008    0507  C1        		pop	bc
1009    0508  21EFFF    		ld	hl,65519
1010    050B  09        		add	hl,bc
1011    050C  CD0000    		call	_memcpy
1012    050F  F1        		pop	af
1013    0510  F1        		pop	af
1014                    	;  327          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1015    0511  210100    		ld	hl,1
1016    0514  E5        		push	hl
1017    0515  DDE5      		push	ix
1018    0517  C1        		pop	bc
1019    0518  21EAFF    		ld	hl,65514
1020    051B  09        		add	hl,bc
1021    051C  E5        		push	hl
1022    051D  DDE5      		push	ix
1023    051F  C1        		pop	bc
1024    0520  21EFFF    		ld	hl,65519
1025    0523  09        		add	hl,bc
1026    0524  CD6301    		call	_sdcommand
1027    0527  F1        		pop	af
1028    0528  F1        		pop	af
1029    0529  DD71E8    		ld	(ix-24),c
1030    052C  DD70E9    		ld	(ix-23),b
1031                    	;  328  #ifdef SDTEST
1032                    	;  329          if (!statptr)
1033                    	;  330              printf("CMD16: no response\n");
1034                    	;  331          else
1035                    	;  332              printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
1036                    	;  333                  statptr[0]);
1037                    	;  334  #endif
1038                    	;  335          if (!statptr)
1039    052F  DD7EE8    		ld	a,(ix-24)
1040    0532  DDB6E9    		or	(ix-23)
1041    0535  200C      		jr	nz,L145
1042                    	;  336              {
1043                    	;  337              spideselect();
1044    0537  CD0000    		call	_spideselect
1045                    	;  338              ledoff();
1046    053A  CD0000    		call	_ledoff
1047                    	;  339              return (NO);
1048    053D  010000    		ld	bc,0
1049    0540  C30000    		jp	c.rets0
1050                    	L145:
1051                    	;  340              }
1052                    	;  341          }
1053                    	;  342      /* Register information:
1054                    	;  343       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
1055                    	;  344       */
1056                    	;  345  
1057                    	;  346      /* CMD10: SEND_CID */
1058                    	;  347      memcpy(cmdbuf, cmd10, 5);
1059    0543  210500    		ld	hl,5
1060    0546  E5        		push	hl
1061    0547  212900    		ld	hl,_cmd10
1062    054A  E5        		push	hl
1063    054B  DDE5      		push	ix
1064    054D  C1        		pop	bc
1065    054E  21EFFF    		ld	hl,65519
1066    0551  09        		add	hl,bc
1067    0552  CD0000    		call	_memcpy
1068    0555  F1        		pop	af
1069    0556  F1        		pop	af
1070                    	;  348      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1071    0557  210100    		ld	hl,1
1072    055A  E5        		push	hl
1073    055B  DDE5      		push	ix
1074    055D  C1        		pop	bc
1075    055E  21EAFF    		ld	hl,65514
1076    0561  09        		add	hl,bc
1077    0562  E5        		push	hl
1078    0563  DDE5      		push	ix
1079    0565  C1        		pop	bc
1080    0566  21EFFF    		ld	hl,65519
1081    0569  09        		add	hl,bc
1082    056A  CD6301    		call	_sdcommand
1083    056D  F1        		pop	af
1084    056E  F1        		pop	af
1085    056F  DD71E8    		ld	(ix-24),c
1086    0572  DD70E9    		ld	(ix-23),b
1087                    	;  349  #ifdef SDTEST
1088                    	;  350      if (!statptr)
1089                    	;  351          printf("CMD10: no response\n");
1090                    	;  352      else
1091                    	;  353          printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
1092                    	;  354  #endif
1093                    	;  355      if (!statptr)
1094    0575  DD7EE8    		ld	a,(ix-24)
1095    0578  DDB6E9    		or	(ix-23)
1096    057B  200C      		jr	nz,L165
1097                    	;  356          {
1098                    	;  357          spideselect();
1099    057D  CD0000    		call	_spideselect
1100                    	;  358          ledoff();
1101    0580  CD0000    		call	_ledoff
1102                    	;  359          return (NO);
1103    0583  010000    		ld	bc,0
1104    0586  C30000    		jp	c.rets0
1105                    	L165:
1106                    	;  360          }
1107                    	;  361      /* looking for 0xfe that is the byte before data */
1108                    	;  362      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
1109    0589  DD36F614  		ld	(ix-10),20
1110    058D  DD36F700  		ld	(ix-9),0
1111                    	L175:
1112    0591  97        		sub	a
1113    0592  DD96F6    		sub	(ix-10)
1114    0595  3E00      		ld	a,0
1115    0597  DD9EF7    		sbc	a,(ix-9)
1116    059A  F2BC05    		jp	p,L106
1117    059D  21FF00    		ld	hl,255
1118    05A0  CD0000    		call	_spiio
1119    05A3  79        		ld	a,c
1120    05A4  FEFE      		cp	254
1121    05A6  2003      		jr	nz,L42
1122    05A8  78        		ld	a,b
1123    05A9  FE00      		cp	0
1124                    	L42:
1125    05AB  280F      		jr	z,L106
1126                    	L116:
1127    05AD  DD6EF6    		ld	l,(ix-10)
1128    05B0  DD66F7    		ld	h,(ix-9)
1129    05B3  2B        		dec	hl
1130    05B4  DD75F6    		ld	(ix-10),l
1131    05B7  DD74F7    		ld	(ix-9),h
1132    05BA  18D5      		jr	L175
1133                    	L106:
1134                    	;  363          ;
1135                    	;  364      if (tries == 0) /* tried too many times */
1136    05BC  DD7EF6    		ld	a,(ix-10)
1137    05BF  DDB6F7    		or	(ix-9)
1138    05C2  200C      		jr	nz,L136
1139                    	;  365          {
1140                    	;  366  #ifdef SDTEST
1141                    	;  367          printf("  No data found\n");
1142                    	;  368  #endif
1143                    	;  369          spideselect();
1144    05C4  CD0000    		call	_spideselect
1145                    	;  370          ledoff();
1146    05C7  CD0000    		call	_ledoff
1147                    	;  371          return (NO);
1148    05CA  010000    		ld	bc,0
1149    05CD  C30000    		jp	c.rets0
1150                    	L136:
1151                    	;  372          }
1152                    	;  373      else
1153                    	;  374          {
1154                    	;  375          crc = 0;
1155    05D0  DD36E700  		ld	(ix-25),0
1156                    	;  376          for (nbytes = 0; nbytes < 15; nbytes++)
1157    05D4  DD36F800  		ld	(ix-8),0
1158    05D8  DD36F900  		ld	(ix-7),0
1159                    	L156:
1160    05DC  DD7EF8    		ld	a,(ix-8)
1161    05DF  D60F      		sub	15
1162    05E1  DD7EF9    		ld	a,(ix-7)
1163    05E4  DE00      		sbc	a,0
1164    05E6  F21C06    		jp	p,L166
1165                    	;  377              {
1166                    	;  378              rbyte = spiio(0xff);
1167    05E9  21FF00    		ld	hl,255
1168    05EC  CD0000    		call	_spiio
1169    05EF  DD71E6    		ld	(ix-26),c
1170                    	;  379              cidreg[nbytes] = rbyte;
1171    05F2  211E00    		ld	hl,_cidreg
1172    05F5  DD4EF8    		ld	c,(ix-8)
1173    05F8  DD46F9    		ld	b,(ix-7)
1174    05FB  09        		add	hl,bc
1175    05FC  DD7EE6    		ld	a,(ix-26)
1176    05FF  77        		ld	(hl),a
1177                    	;  380              crc = CRC7_one(crc, rbyte);
1178    0600  DD6EE6    		ld	l,(ix-26)
1179    0603  97        		sub	a
1180    0604  67        		ld	h,a
1181    0605  E5        		push	hl
1182    0606  DD6EE7    		ld	l,(ix-25)
1183    0609  97        		sub	a
1184    060A  67        		ld	h,a
1185    060B  CD5300    		call	_CRC7_one
1186    060E  F1        		pop	af
1187    060F  DD71E7    		ld	(ix-25),c
1188                    	;  381              }
1189    0612  DD34F8    		inc	(ix-8)
1190    0615  2003      		jr	nz,L62
1191    0617  DD34F9    		inc	(ix-7)
1192                    	L62:
1193    061A  18C0      		jr	L156
1194                    	L166:
1195                    	;  382          cidreg[15] = spiio(0xff);
1196    061C  21FF00    		ld	hl,255
1197    061F  CD0000    		call	_spiio
1198    0622  79        		ld	a,c
1199    0623  322D00    		ld	(_cidreg+15),a
1200                    	;  383          crc |= 0x01;
1201    0626  DDCBE7C6  		set	0,(ix-25)
1202                    	;  384          /* some SD cards need additional clock pulses */
1203                    	;  385          for (nbytes = 9; 0 < nbytes; nbytes--)
1204    062A  DD36F809  		ld	(ix-8),9
1205    062E  DD36F900  		ld	(ix-7),0
1206                    	L117:
1207    0632  97        		sub	a
1208    0633  DD96F8    		sub	(ix-8)
1209    0636  3E00      		ld	a,0
1210    0638  DD9EF9    		sbc	a,(ix-7)
1211    063B  F25306    		jp	p,L146
1212                    	;  386              spiio(0xff);
1213    063E  21FF00    		ld	hl,255
1214    0641  CD0000    		call	_spiio
1215    0644  DD6EF8    		ld	l,(ix-8)
1216    0647  DD66F9    		ld	h,(ix-7)
1217    064A  2B        		dec	hl
1218    064B  DD75F8    		ld	(ix-8),l
1219    064E  DD74F9    		ld	(ix-7),h
1220    0651  18DF      		jr	L117
1221                    	L146:
1222                    	;  387  #ifdef SDTEST
1223                    	;  388          prtptr = &cidreg[0];
1224                    	;  389          printf("  CID: [");
1225                    	;  390          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1226                    	;  391              printf("%02x ", *prtptr);
1227                    	;  392          prtptr = &cidreg[0];
1228                    	;  393          printf("\b] |");
1229                    	;  394          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1230                    	;  395              {
1231                    	;  396              if ((' ' <= *prtptr) && (*prtptr < 127))
1232                    	;  397                  putchar(*prtptr);
1233                    	;  398              else
1234                    	;  399                  putchar('.');
1235                    	;  400              }
1236                    	;  401          printf("|\n");
1237                    	;  402          if (crc == cidreg[15])
1238                    	;  403              {
1239                    	;  404              printf("CRC7 ok: [%02x]\n", crc);
1240                    	;  405              }
1241                    	;  406          else
1242                    	;  407              {
1243                    	;  408              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
1244                    	;  409                  crc, cidreg[15]);
1245                    	;  410              /* could maybe return failure here */
1246                    	;  411              }
1247                    	;  412  #endif
1248                    	;  413          }
1249                    	;  414  
1250                    	;  415      /* CMD9: SEND_CSD */
1251                    	;  416      memcpy(cmdbuf, cmd9, 5);
1252    0653  210500    		ld	hl,5
1253    0656  E5        		push	hl
1254    0657  212300    		ld	hl,_cmd9
1255    065A  E5        		push	hl
1256    065B  DDE5      		push	ix
1257    065D  C1        		pop	bc
1258    065E  21EFFF    		ld	hl,65519
1259    0661  09        		add	hl,bc
1260    0662  CD0000    		call	_memcpy
1261    0665  F1        		pop	af
1262    0666  F1        		pop	af
1263                    	;  417      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1264    0667  210100    		ld	hl,1
1265    066A  E5        		push	hl
1266    066B  DDE5      		push	ix
1267    066D  C1        		pop	bc
1268    066E  21EAFF    		ld	hl,65514
1269    0671  09        		add	hl,bc
1270    0672  E5        		push	hl
1271    0673  DDE5      		push	ix
1272    0675  C1        		pop	bc
1273    0676  21EFFF    		ld	hl,65519
1274    0679  09        		add	hl,bc
1275    067A  CD6301    		call	_sdcommand
1276    067D  F1        		pop	af
1277    067E  F1        		pop	af
1278    067F  DD71E8    		ld	(ix-24),c
1279    0682  DD70E9    		ld	(ix-23),b
1280                    	;  418  #ifdef SDTEST
1281                    	;  419      if (!statptr)
1282                    	;  420          printf("CMD9: no response\n");
1283                    	;  421      else
1284                    	;  422          printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
1285                    	;  423  #endif
1286                    	;  424      if (!statptr)
1287    0685  DD7EE8    		ld	a,(ix-24)
1288    0688  DDB6E9    		or	(ix-23)
1289    068B  200C      		jr	nz,L157
1290                    	;  425          {
1291                    	;  426          spideselect();
1292    068D  CD0000    		call	_spideselect
1293                    	;  427          ledoff();
1294    0690  CD0000    		call	_ledoff
1295                    	;  428          return (NO);
1296    0693  010000    		ld	bc,0
1297    0696  C30000    		jp	c.rets0
1298                    	L157:
1299                    	;  429          }
1300                    	;  430      /* looking for 0xfe that is the byte before data */
1301                    	;  431      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
1302    0699  DD36F614  		ld	(ix-10),20
1303    069D  DD36F700  		ld	(ix-9),0
1304                    	L167:
1305    06A1  97        		sub	a
1306    06A2  DD96F6    		sub	(ix-10)
1307    06A5  3E00      		ld	a,0
1308    06A7  DD9EF7    		sbc	a,(ix-9)
1309    06AA  F2CC06    		jp	p,L177
1310    06AD  21FF00    		ld	hl,255
1311    06B0  CD0000    		call	_spiio
1312    06B3  79        		ld	a,c
1313    06B4  FEFE      		cp	254
1314    06B6  2003      		jr	nz,L03
1315    06B8  78        		ld	a,b
1316    06B9  FE00      		cp	0
1317                    	L03:
1318    06BB  280F      		jr	z,L177
1319                    	L1001:
1320    06BD  DD6EF6    		ld	l,(ix-10)
1321    06C0  DD66F7    		ld	h,(ix-9)
1322    06C3  2B        		dec	hl
1323    06C4  DD75F6    		ld	(ix-10),l
1324    06C7  DD74F7    		ld	(ix-9),h
1325    06CA  18D5      		jr	L167
1326                    	L177:
1327                    	;  432          ;
1328                    	;  433      if (tries == 0) /* tried too many times */
1329    06CC  DD7EF6    		ld	a,(ix-10)
1330    06CF  DDB6F7    		or	(ix-9)
1331    06D2  2006      		jr	nz,L1201
1332                    	;  434          {
1333                    	;  435  #ifdef SDTEST
1334                    	;  436          printf("  No data found\n");
1335                    	;  437  #endif
1336                    	;  438          return (NO);
1337    06D4  010000    		ld	bc,0
1338    06D7  C30000    		jp	c.rets0
1339                    	L1201:
1340                    	;  439          }
1341                    	;  440      else
1342                    	;  441          {
1343                    	;  442          crc = 0;
1344    06DA  DD36E700  		ld	(ix-25),0
1345                    	;  443          for (nbytes = 0; nbytes < 15; nbytes++)
1346    06DE  DD36F800  		ld	(ix-8),0
1347    06E2  DD36F900  		ld	(ix-7),0
1348                    	L1401:
1349    06E6  DD7EF8    		ld	a,(ix-8)
1350    06E9  D60F      		sub	15
1351    06EB  DD7EF9    		ld	a,(ix-7)
1352    06EE  DE00      		sbc	a,0
1353    06F0  F22607    		jp	p,L1501
1354                    	;  444              {
1355                    	;  445              rbyte = spiio(0xff);
1356    06F3  21FF00    		ld	hl,255
1357    06F6  CD0000    		call	_spiio
1358    06F9  DD71E6    		ld	(ix-26),c
1359                    	;  446              csdreg[nbytes] = rbyte;
1360    06FC  210E00    		ld	hl,_csdreg
1361    06FF  DD4EF8    		ld	c,(ix-8)
1362    0702  DD46F9    		ld	b,(ix-7)
1363    0705  09        		add	hl,bc
1364    0706  DD7EE6    		ld	a,(ix-26)
1365    0709  77        		ld	(hl),a
1366                    	;  447              crc = CRC7_one(crc, rbyte);
1367    070A  DD6EE6    		ld	l,(ix-26)
1368    070D  97        		sub	a
1369    070E  67        		ld	h,a
1370    070F  E5        		push	hl
1371    0710  DD6EE7    		ld	l,(ix-25)
1372    0713  97        		sub	a
1373    0714  67        		ld	h,a
1374    0715  CD5300    		call	_CRC7_one
1375    0718  F1        		pop	af
1376    0719  DD71E7    		ld	(ix-25),c
1377                    	;  448              }
1378    071C  DD34F8    		inc	(ix-8)
1379    071F  2003      		jr	nz,L23
1380    0721  DD34F9    		inc	(ix-7)
1381                    	L23:
1382    0724  18C0      		jr	L1401
1383                    	L1501:
1384                    	;  449          csdreg[15] = spiio(0xff);
1385    0726  21FF00    		ld	hl,255
1386    0729  CD0000    		call	_spiio
1387    072C  79        		ld	a,c
1388    072D  321D00    		ld	(_csdreg+15),a
1389                    	;  450          crc |= 0x01;
1390    0730  DDCBE7C6  		set	0,(ix-25)
1391                    	;  451          /* some SD cards need additional clock pulses */
1392                    	;  452          for (nbytes = 9; 0 < nbytes; nbytes--)
1393    0734  DD36F809  		ld	(ix-8),9
1394    0738  DD36F900  		ld	(ix-7),0
1395                    	L1011:
1396    073C  97        		sub	a
1397    073D  DD96F8    		sub	(ix-8)
1398    0740  3E00      		ld	a,0
1399    0742  DD9EF9    		sbc	a,(ix-7)
1400    0745  F25D07    		jp	p,L1301
1401                    	;  453              spiio(0xff);
1402    0748  21FF00    		ld	hl,255
1403    074B  CD0000    		call	_spiio
1404    074E  DD6EF8    		ld	l,(ix-8)
1405    0751  DD66F9    		ld	h,(ix-7)
1406    0754  2B        		dec	hl
1407    0755  DD75F8    		ld	(ix-8),l
1408    0758  DD74F9    		ld	(ix-7),h
1409    075B  18DF      		jr	L1011
1410                    	L1301:
1411                    	;  454  #ifdef SDTEST
1412                    	;  455          prtptr = &csdreg[0];
1413                    	;  456          printf("  CSD: [");
1414                    	;  457          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1415                    	;  458              printf("%02x ", *prtptr);
1416                    	;  459          prtptr = &csdreg[0];
1417                    	;  460          printf("\b] |");
1418                    	;  461          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1419                    	;  462              {
1420                    	;  463              if ((' ' <= *prtptr) && (*prtptr < 127))
1421                    	;  464                  putchar(*prtptr);
1422                    	;  465              else
1423                    	;  466                  putchar('.');
1424                    	;  467              }
1425                    	;  468          printf("|\n");
1426                    	;  469          if (crc == csdreg[15])
1427                    	;  470              {
1428                    	;  471              printf("CRC7 ok: [%02x]\n", crc);
1429                    	;  472              }
1430                    	;  473          else
1431                    	;  474              {
1432                    	;  475              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
1433                    	;  476                  crc, csdreg[15]);
1434                    	;  477              /* could maybe return failure here */
1435                    	;  478              }
1436                    	;  479  #endif
1437                    	;  480          }
1438                    	;  481  
1439                    	;  482      for (nbytes = 9; 0 < nbytes; nbytes--)
1440    075D  DD36F809  		ld	(ix-8),9
1441    0761  DD36F900  		ld	(ix-7),0
1442                    	L1411:
1443    0765  97        		sub	a
1444    0766  DD96F8    		sub	(ix-8)
1445    0769  3E00      		ld	a,0
1446    076B  DD9EF9    		sbc	a,(ix-7)
1447    076E  F28607    		jp	p,L1511
1448                    	;  483          spiio(0xff);
1449    0771  21FF00    		ld	hl,255
1450    0774  CD0000    		call	_spiio
1451    0777  DD6EF8    		ld	l,(ix-8)
1452    077A  DD66F9    		ld	h,(ix-7)
1453    077D  2B        		dec	hl
1454    077E  DD75F8    		ld	(ix-8),l
1455    0781  DD74F9    		ld	(ix-7),h
1456    0784  18DF      		jr	L1411
1457                    	L1511:
1458                    	;  484  #ifdef SDTEST
1459                    	;  485      printf("Sent 9*8 (72) clock pulses, select active\n");
1460                    	;  486  #endif
1461                    	;  487  
1462                    	;  488      sdinitok = YES;
1463    0786  210100    		ld	hl,1
1464    0789  220A00    		ld	(_sdinitok),hl
1465                    	;  489  
1466                    	;  490      spideselect();
1467    078C  CD0000    		call	_spideselect
1468                    	;  491      ledoff();
1469    078F  CD0000    		call	_ledoff
1470                    	;  492  
1471                    	;  493      return (YES);
1472    0792  010100    		ld	bc,1
1473    0795  C30000    		jp	c.rets0
1474                    	L51:
1475    0798  53        		.byte	83
1476    0799  44        		.byte	68
1477    079A  20        		.byte	32
1478    079B  63        		.byte	99
1479    079C  61        		.byte	97
1480    079D  72        		.byte	114
1481    079E  64        		.byte	100
1482    079F  20        		.byte	32
1483    07A0  6E        		.byte	110
1484    07A1  6F        		.byte	111
1485    07A2  74        		.byte	116
1486    07A3  20        		.byte	32
1487    07A4  69        		.byte	105
1488    07A5  6E        		.byte	110
1489    07A6  69        		.byte	105
1490    07A7  74        		.byte	116
1491    07A8  69        		.byte	105
1492    07A9  61        		.byte	97
1493    07AA  6C        		.byte	108
1494    07AB  69        		.byte	105
1495    07AC  7A        		.byte	122
1496    07AD  65        		.byte	101
1497    07AE  64        		.byte	100
1498    07AF  0A        		.byte	10
1499    07B0  00        		.byte	0
1500                    	L52:
1501    07B1  53        		.byte	83
1502    07B2  44        		.byte	68
1503    07B3  20        		.byte	32
1504    07B4  63        		.byte	99
1505    07B5  61        		.byte	97
1506    07B6  72        		.byte	114
1507    07B7  64        		.byte	100
1508    07B8  20        		.byte	32
1509    07B9  69        		.byte	105
1510    07BA  6E        		.byte	110
1511    07BB  66        		.byte	102
1512    07BC  6F        		.byte	111
1513    07BD  72        		.byte	114
1514    07BE  6D        		.byte	109
1515    07BF  61        		.byte	97
1516    07C0  74        		.byte	116
1517    07C1  69        		.byte	105
1518    07C2  6F        		.byte	111
1519    07C3  6E        		.byte	110
1520    07C4  3A        		.byte	58
1521    07C5  00        		.byte	0
1522                    	L53:
1523    07C6  20        		.byte	32
1524    07C7  20        		.byte	32
1525    07C8  53        		.byte	83
1526    07C9  44        		.byte	68
1527    07CA  20        		.byte	32
1528    07CB  63        		.byte	99
1529    07CC  61        		.byte	97
1530    07CD  72        		.byte	114
1531    07CE  64        		.byte	100
1532    07CF  20        		.byte	32
1533    07D0  76        		.byte	118
1534    07D1  65        		.byte	101
1535    07D2  72        		.byte	114
1536    07D3  2E        		.byte	46
1537    07D4  20        		.byte	32
1538    07D5  32        		.byte	50
1539    07D6  2B        		.byte	43
1540    07D7  2C        		.byte	44
1541    07D8  20        		.byte	32
1542    07D9  42        		.byte	66
1543    07DA  6C        		.byte	108
1544    07DB  6F        		.byte	111
1545    07DC  63        		.byte	99
1546    07DD  6B        		.byte	107
1547    07DE  20        		.byte	32
1548    07DF  61        		.byte	97
1549    07E0  64        		.byte	100
1550    07E1  64        		.byte	100
1551    07E2  72        		.byte	114
1552    07E3  65        		.byte	101
1553    07E4  73        		.byte	115
1554    07E5  73        		.byte	115
1555    07E6  0A        		.byte	10
1556    07E7  00        		.byte	0
1557                    	L54:
1558    07E8  20        		.byte	32
1559    07E9  20        		.byte	32
1560    07EA  53        		.byte	83
1561    07EB  44        		.byte	68
1562    07EC  20        		.byte	32
1563    07ED  63        		.byte	99
1564    07EE  61        		.byte	97
1565    07EF  72        		.byte	114
1566    07F0  64        		.byte	100
1567    07F1  20        		.byte	32
1568    07F2  76        		.byte	118
1569    07F3  65        		.byte	101
1570    07F4  72        		.byte	114
1571    07F5  2E        		.byte	46
1572    07F6  20        		.byte	32
1573    07F7  32        		.byte	50
1574    07F8  2B        		.byte	43
1575    07F9  2C        		.byte	44
1576    07FA  20        		.byte	32
1577    07FB  42        		.byte	66
1578    07FC  79        		.byte	121
1579    07FD  74        		.byte	116
1580    07FE  65        		.byte	101
1581    07FF  20        		.byte	32
1582    0800  61        		.byte	97
1583    0801  64        		.byte	100
1584    0802  64        		.byte	100
1585    0803  72        		.byte	114
1586    0804  65        		.byte	101
1587    0805  73        		.byte	115
1588    0806  73        		.byte	115
1589    0807  0A        		.byte	10
1590    0808  00        		.byte	0
1591                    	L55:
1592    0809  20        		.byte	32
1593    080A  20        		.byte	32
1594    080B  53        		.byte	83
1595    080C  44        		.byte	68
1596    080D  20        		.byte	32
1597    080E  63        		.byte	99
1598    080F  61        		.byte	97
1599    0810  72        		.byte	114
1600    0811  64        		.byte	100
1601    0812  20        		.byte	32
1602    0813  76        		.byte	118
1603    0814  65        		.byte	101
1604    0815  72        		.byte	114
1605    0816  2E        		.byte	46
1606    0817  20        		.byte	32
1607    0818  31        		.byte	49
1608    0819  2C        		.byte	44
1609    081A  20        		.byte	32
1610    081B  42        		.byte	66
1611    081C  79        		.byte	121
1612    081D  74        		.byte	116
1613    081E  65        		.byte	101
1614    081F  20        		.byte	32
1615    0820  61        		.byte	97
1616    0821  64        		.byte	100
1617    0822  64        		.byte	100
1618    0823  72        		.byte	114
1619    0824  65        		.byte	101
1620    0825  73        		.byte	115
1621    0826  73        		.byte	115
1622    0827  0A        		.byte	10
1623    0828  00        		.byte	0
1624                    	L56:
1625    0829  20        		.byte	32
1626    082A  20        		.byte	32
1627    082B  4D        		.byte	77
1628    082C  61        		.byte	97
1629    082D  6E        		.byte	110
1630    082E  75        		.byte	117
1631    082F  66        		.byte	102
1632    0830  61        		.byte	97
1633    0831  63        		.byte	99
1634    0832  74        		.byte	116
1635    0833  75        		.byte	117
1636    0834  72        		.byte	114
1637    0835  65        		.byte	101
1638    0836  72        		.byte	114
1639    0837  20        		.byte	32
1640    0838  49        		.byte	73
1641    0839  44        		.byte	68
1642    083A  3A        		.byte	58
1643    083B  20        		.byte	32
1644    083C  30        		.byte	48
1645    083D  78        		.byte	120
1646    083E  25        		.byte	37
1647    083F  30        		.byte	48
1648    0840  32        		.byte	50
1649    0841  78        		.byte	120
1650    0842  2C        		.byte	44
1651    0843  20        		.byte	32
1652    0844  00        		.byte	0
1653                    	L57:
1654    0845  4F        		.byte	79
1655    0846  45        		.byte	69
1656    0847  4D        		.byte	77
1657    0848  20        		.byte	32
1658    0849  49        		.byte	73
1659    084A  44        		.byte	68
1660    084B  3A        		.byte	58
1661    084C  20        		.byte	32
1662    084D  25        		.byte	37
1663    084E  2E        		.byte	46
1664    084F  32        		.byte	50
1665    0850  73        		.byte	115
1666    0851  2C        		.byte	44
1667    0852  20        		.byte	32
1668    0853  00        		.byte	0
1669                    	L501:
1670    0854  50        		.byte	80
1671    0855  72        		.byte	114
1672    0856  6F        		.byte	111
1673    0857  64        		.byte	100
1674    0858  75        		.byte	117
1675    0859  63        		.byte	99
1676    085A  74        		.byte	116
1677    085B  20        		.byte	32
1678    085C  6E        		.byte	110
1679    085D  61        		.byte	97
1680    085E  6D        		.byte	109
1681    085F  65        		.byte	101
1682    0860  3A        		.byte	58
1683    0861  20        		.byte	32
1684    0862  25        		.byte	37
1685    0863  2E        		.byte	46
1686    0864  35        		.byte	53
1687    0865  73        		.byte	115
1688    0866  0A        		.byte	10
1689    0867  00        		.byte	0
1690                    	L511:
1691    0868  20        		.byte	32
1692    0869  20        		.byte	32
1693    086A  50        		.byte	80
1694    086B  72        		.byte	114
1695    086C  6F        		.byte	111
1696    086D  64        		.byte	100
1697    086E  75        		.byte	117
1698    086F  63        		.byte	99
1699    0870  74        		.byte	116
1700    0871  20        		.byte	32
1701    0872  72        		.byte	114
1702    0873  65        		.byte	101
1703    0874  76        		.byte	118
1704    0875  69        		.byte	105
1705    0876  73        		.byte	115
1706    0877  69        		.byte	105
1707    0878  6F        		.byte	111
1708    0879  6E        		.byte	110
1709    087A  3A        		.byte	58
1710    087B  20        		.byte	32
1711    087C  25        		.byte	37
1712    087D  64        		.byte	100
1713    087E  2E        		.byte	46
1714    087F  25        		.byte	37
1715    0880  64        		.byte	100
1716    0881  2C        		.byte	44
1717    0882  20        		.byte	32
1718    0883  00        		.byte	0
1719                    	L521:
1720    0884  53        		.byte	83
1721    0885  65        		.byte	101
1722    0886  72        		.byte	114
1723    0887  69        		.byte	105
1724    0888  61        		.byte	97
1725    0889  6C        		.byte	108
1726    088A  20        		.byte	32
1727    088B  6E        		.byte	110
1728    088C  75        		.byte	117
1729    088D  6D        		.byte	109
1730    088E  62        		.byte	98
1731    088F  65        		.byte	101
1732    0890  72        		.byte	114
1733    0891  3A        		.byte	58
1734    0892  20        		.byte	32
1735    0893  25        		.byte	37
1736    0894  6C        		.byte	108
1737    0895  75        		.byte	117
1738    0896  0A        		.byte	10
1739    0897  00        		.byte	0
1740                    	L531:
1741    0898  20        		.byte	32
1742    0899  20        		.byte	32
1743    089A  4D        		.byte	77
1744    089B  61        		.byte	97
1745    089C  6E        		.byte	110
1746    089D  75        		.byte	117
1747    089E  66        		.byte	102
1748    089F  61        		.byte	97
1749    08A0  63        		.byte	99
1750    08A1  74        		.byte	116
1751    08A2  75        		.byte	117
1752    08A3  72        		.byte	114
1753    08A4  69        		.byte	105
1754    08A5  6E        		.byte	110
1755    08A6  67        		.byte	103
1756    08A7  20        		.byte	32
1757    08A8  64        		.byte	100
1758    08A9  61        		.byte	97
1759    08AA  74        		.byte	116
1760    08AB  65        		.byte	101
1761    08AC  3A        		.byte	58
1762    08AD  20        		.byte	32
1763    08AE  25        		.byte	37
1764    08AF  64        		.byte	100
1765    08B0  2D        		.byte	45
1766    08B1  25        		.byte	37
1767    08B2  64        		.byte	100
1768    08B3  2C        		.byte	44
1769    08B4  20        		.byte	32
1770    08B5  00        		.byte	0
1771                    	L541:
1772    08B6  44        		.byte	68
1773    08B7  65        		.byte	101
1774    08B8  76        		.byte	118
1775    08B9  69        		.byte	105
1776    08BA  63        		.byte	99
1777    08BB  65        		.byte	101
1778    08BC  20        		.byte	32
1779    08BD  63        		.byte	99
1780    08BE  61        		.byte	97
1781    08BF  70        		.byte	112
1782    08C0  61        		.byte	97
1783    08C1  63        		.byte	99
1784    08C2  69        		.byte	105
1785    08C3  74        		.byte	116
1786    08C4  79        		.byte	121
1787    08C5  3A        		.byte	58
1788    08C6  20        		.byte	32
1789    08C7  25        		.byte	37
1790    08C8  6C        		.byte	108
1791    08C9  75        		.byte	117
1792    08CA  20        		.byte	32
1793    08CB  4D        		.byte	77
1794    08CC  42        		.byte	66
1795    08CD  79        		.byte	121
1796    08CE  74        		.byte	116
1797    08CF  65        		.byte	101
1798    08D0  0A        		.byte	10
1799    08D1  00        		.byte	0
1800                    	L551:
1801    08D2  44        		.byte	68
1802    08D3  65        		.byte	101
1803    08D4  76        		.byte	118
1804    08D5  69        		.byte	105
1805    08D6  63        		.byte	99
1806    08D7  65        		.byte	101
1807    08D8  20        		.byte	32
1808    08D9  63        		.byte	99
1809    08DA  61        		.byte	97
1810    08DB  70        		.byte	112
1811    08DC  61        		.byte	97
1812    08DD  63        		.byte	99
1813    08DE  69        		.byte	105
1814    08DF  74        		.byte	116
1815    08E0  79        		.byte	121
1816    08E1  3A        		.byte	58
1817    08E2  20        		.byte	32
1818    08E3  25        		.byte	37
1819    08E4  6C        		.byte	108
1820    08E5  75        		.byte	117
1821    08E6  20        		.byte	32
1822    08E7  4D        		.byte	77
1823    08E8  42        		.byte	66
1824    08E9  79        		.byte	121
1825    08EA  74        		.byte	116
1826    08EB  65        		.byte	101
1827    08EC  0A        		.byte	10
1828    08ED  00        		.byte	0
1829                    	L561:
1830    08EE  44        		.byte	68
1831    08EF  65        		.byte	101
1832    08F0  76        		.byte	118
1833    08F1  69        		.byte	105
1834    08F2  63        		.byte	99
1835    08F3  65        		.byte	101
1836    08F4  20        		.byte	32
1837    08F5  75        		.byte	117
1838    08F6  6C        		.byte	108
1839    08F7  74        		.byte	116
1840    08F8  72        		.byte	114
1841    08F9  61        		.byte	97
1842    08FA  20        		.byte	32
1843    08FB  63        		.byte	99
1844    08FC  61        		.byte	97
1845    08FD  70        		.byte	112
1846    08FE  61        		.byte	97
1847    08FF  63        		.byte	99
1848    0900  69        		.byte	105
1849    0901  74        		.byte	116
1850    0902  79        		.byte	121
1851    0903  3A        		.byte	58
1852    0904  20        		.byte	32
1853    0905  25        		.byte	37
1854    0906  6C        		.byte	108
1855    0907  75        		.byte	117
1856    0908  20        		.byte	32
1857    0909  4D        		.byte	77
1858    090A  42        		.byte	66
1859    090B  79        		.byte	121
1860    090C  74        		.byte	116
1861    090D  65        		.byte	101
1862    090E  0A        		.byte	10
1863    090F  00        		.byte	0
1864                    	;  494      }
1865                    	;  495  
1866                    	;  496  /* print OCR, CID and CSD registers*/
1867                    	;  497  void sdprtreg()
1868                    	;  498      {
1869                    	_sdprtreg:
1870    0910  CD0000    		call	c.savs0
1871    0913  21EEFF    		ld	hl,65518
1872    0916  39        		add	hl,sp
1873    0917  F9        		ld	sp,hl
1874                    	;  499      unsigned int n;
1875                    	;  500      unsigned int csize;
1876                    	;  501      unsigned long devsize;
1877                    	;  502      unsigned long capacity;
1878                    	;  503  
1879                    	;  504      if (!sdinitok)
1880    0918  2A0A00    		ld	hl,(_sdinitok)
1881    091B  7C        		ld	a,h
1882    091C  B5        		or	l
1883    091D  2009      		jr	nz,L1021
1884                    	;  505          {
1885                    	;  506          printf("SD card not initialized\n");
1886    091F  219807    		ld	hl,L51
1887    0922  CD0000    		call	_printf
1888                    	;  507          return;
1889    0925  C30000    		jp	c.rets0
1890                    	L1021:
1891                    	;  508          }
1892                    	;  509      printf("SD card information:");
1893    0928  21B107    		ld	hl,L52
1894    092B  CD0000    		call	_printf
1895                    	;  510      if (ocrreg[0] & 0x80)
1896    092E  3A2E00    		ld	a,(_ocrreg)
1897    0931  CB7F      		bit	7,a
1898    0933  6F        		ld	l,a
1899    0934  2825      		jr	z,L1121
1900                    	;  511          {
1901                    	;  512          if (ocrreg[0] & 0x40)
1902    0936  3A2E00    		ld	a,(_ocrreg)
1903    0939  CB77      		bit	6,a
1904    093B  6F        		ld	l,a
1905    093C  2808      		jr	z,L1221
1906                    	;  513              printf("  SD card ver. 2+, Block address\n");
1907    093E  21C607    		ld	hl,L53
1908    0941  CD0000    		call	_printf
1909                    	;  514          else
1910    0944  1815      		jr	L1121
1911                    	L1221:
1912                    	;  515              {
1913                    	;  516              if (sdver2)
1914    0946  2A0800    		ld	hl,(_sdver2)
1915    0949  7C        		ld	a,h
1916    094A  B5        		or	l
1917    094B  2808      		jr	z,L1421
1918                    	;  517                  printf("  SD card ver. 2+, Byte address\n");
1919    094D  21E807    		ld	hl,L54
1920    0950  CD0000    		call	_printf
1921                    	;  518              else
1922    0953  1806      		jr	L1121
1923                    	L1421:
1924                    	;  519                  printf("  SD card ver. 1, Byte address\n");
1925    0955  210908    		ld	hl,L55
1926    0958  CD0000    		call	_printf
1927                    	L1121:
1928                    	;  520              }
1929                    	;  521          }
1930                    	;  522      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
1931    095B  3A1E00    		ld	a,(_cidreg)
1932    095E  4F        		ld	c,a
1933    095F  97        		sub	a
1934    0960  47        		ld	b,a
1935    0961  C5        		push	bc
1936    0962  212908    		ld	hl,L56
1937    0965  CD0000    		call	_printf
1938    0968  F1        		pop	af
1939                    	;  523      printf("OEM ID: %.2s, ", &cidreg[1]);
1940    0969  211F00    		ld	hl,_cidreg+1
1941    096C  E5        		push	hl
1942    096D  214508    		ld	hl,L57
1943    0970  CD0000    		call	_printf
1944    0973  F1        		pop	af
1945                    	;  524      printf("Product name: %.5s\n", &cidreg[3]);
1946    0974  212100    		ld	hl,_cidreg+3
1947    0977  E5        		push	hl
1948    0978  215408    		ld	hl,L501
1949    097B  CD0000    		call	_printf
1950    097E  F1        		pop	af
1951                    	;  525      printf("  Product revision: %d.%d, ",
1952                    	;  526             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
1953    097F  3A2600    		ld	a,(_cidreg+8)
1954    0982  6F        		ld	l,a
1955    0983  97        		sub	a
1956    0984  67        		ld	h,a
1957    0985  7D        		ld	a,l
1958    0986  E60F      		and	15
1959    0988  6F        		ld	l,a
1960    0989  97        		sub	a
1961    098A  67        		ld	h,a
1962    098B  E5        		push	hl
1963    098C  3A2600    		ld	a,(_cidreg+8)
1964    098F  4F        		ld	c,a
1965    0990  97        		sub	a
1966    0991  47        		ld	b,a
1967    0992  C5        		push	bc
1968    0993  210400    		ld	hl,4
1969    0996  E5        		push	hl
1970    0997  CD0000    		call	c.irsh
1971    099A  E1        		pop	hl
1972    099B  7D        		ld	a,l
1973    099C  E60F      		and	15
1974    099E  6F        		ld	l,a
1975    099F  97        		sub	a
1976    09A0  67        		ld	h,a
1977    09A1  E5        		push	hl
1978    09A2  216808    		ld	hl,L511
1979    09A5  CD0000    		call	_printf
1980    09A8  F1        		pop	af
1981    09A9  F1        		pop	af
1982                    	;  527      printf("Serial number: %lu\n",
1983                    	;  528             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
1984    09AA  3A2700    		ld	a,(_cidreg+9)
1985    09AD  4F        		ld	c,a
1986    09AE  97        		sub	a
1987    09AF  47        		ld	b,a
1988    09B0  C5        		push	bc
1989    09B1  211800    		ld	hl,24
1990    09B4  E5        		push	hl
1991    09B5  CD0000    		call	c.ilsh
1992    09B8  E1        		pop	hl
1993    09B9  E5        		push	hl
1994    09BA  3A2800    		ld	a,(_cidreg+10)
1995    09BD  4F        		ld	c,a
1996    09BE  97        		sub	a
1997    09BF  47        		ld	b,a
1998    09C0  C5        		push	bc
1999    09C1  211000    		ld	hl,16
2000    09C4  E5        		push	hl
2001    09C5  CD0000    		call	c.ilsh
2002    09C8  E1        		pop	hl
2003    09C9  E3        		ex	(sp),hl
2004    09CA  C1        		pop	bc
2005    09CB  09        		add	hl,bc
2006    09CC  E5        		push	hl
2007    09CD  3A2900    		ld	a,(_cidreg+11)
2008    09D0  6F        		ld	l,a
2009    09D1  97        		sub	a
2010    09D2  67        		ld	h,a
2011    09D3  29        		add	hl,hl
2012    09D4  29        		add	hl,hl
2013    09D5  29        		add	hl,hl
2014    09D6  29        		add	hl,hl
2015    09D7  29        		add	hl,hl
2016    09D8  29        		add	hl,hl
2017    09D9  29        		add	hl,hl
2018    09DA  29        		add	hl,hl
2019    09DB  E3        		ex	(sp),hl
2020    09DC  C1        		pop	bc
2021    09DD  09        		add	hl,bc
2022    09DE  E5        		push	hl
2023    09DF  3A2A00    		ld	a,(_cidreg+12)
2024    09E2  6F        		ld	l,a
2025    09E3  97        		sub	a
2026    09E4  67        		ld	h,a
2027    09E5  E3        		ex	(sp),hl
2028    09E6  C1        		pop	bc
2029    09E7  09        		add	hl,bc
2030    09E8  E5        		push	hl
2031    09E9  218408    		ld	hl,L521
2032    09EC  CD0000    		call	_printf
2033    09EF  F1        		pop	af
2034                    	;  529      printf("  Manufacturing date: %d-%d, ",
2035                    	;  530             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2036    09F0  3A2C00    		ld	a,(_cidreg+14)
2037    09F3  6F        		ld	l,a
2038    09F4  97        		sub	a
2039    09F5  67        		ld	h,a
2040    09F6  7D        		ld	a,l
2041    09F7  E60F      		and	15
2042    09F9  6F        		ld	l,a
2043    09FA  97        		sub	a
2044    09FB  67        		ld	h,a
2045    09FC  E5        		push	hl
2046    09FD  3A2B00    		ld	a,(_cidreg+13)
2047    0A00  6F        		ld	l,a
2048    0A01  97        		sub	a
2049    0A02  67        		ld	h,a
2050    0A03  7D        		ld	a,l
2051    0A04  E60F      		and	15
2052    0A06  6F        		ld	l,a
2053    0A07  97        		sub	a
2054    0A08  67        		ld	h,a
2055    0A09  29        		add	hl,hl
2056    0A0A  29        		add	hl,hl
2057    0A0B  29        		add	hl,hl
2058    0A0C  29        		add	hl,hl
2059    0A0D  01D007    		ld	bc,2000
2060    0A10  09        		add	hl,bc
2061    0A11  E5        		push	hl
2062    0A12  3A2C00    		ld	a,(_cidreg+14)
2063    0A15  4F        		ld	c,a
2064    0A16  97        		sub	a
2065    0A17  47        		ld	b,a
2066    0A18  C5        		push	bc
2067    0A19  210400    		ld	hl,4
2068    0A1C  E5        		push	hl
2069    0A1D  CD0000    		call	c.irsh
2070    0A20  E1        		pop	hl
2071    0A21  E3        		ex	(sp),hl
2072    0A22  C1        		pop	bc
2073    0A23  09        		add	hl,bc
2074    0A24  E5        		push	hl
2075    0A25  219808    		ld	hl,L531
2076    0A28  CD0000    		call	_printf
2077    0A2B  F1        		pop	af
2078    0A2C  F1        		pop	af
2079                    	;  531      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
2080    0A2D  3A0E00    		ld	a,(_csdreg)
2081    0A30  E6C0      		and	192
2082    0A32  C2100B    		jp	nz,L1621
2083                    	;  532          {
2084                    	;  533          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2085    0A35  3A1300    		ld	a,(_csdreg+5)
2086    0A38  6F        		ld	l,a
2087    0A39  97        		sub	a
2088    0A3A  67        		ld	h,a
2089    0A3B  7D        		ld	a,l
2090    0A3C  E60F      		and	15
2091    0A3E  6F        		ld	l,a
2092    0A3F  97        		sub	a
2093    0A40  67        		ld	h,a
2094    0A41  E5        		push	hl
2095    0A42  3A1800    		ld	a,(_csdreg+10)
2096    0A45  6F        		ld	l,a
2097    0A46  97        		sub	a
2098    0A47  67        		ld	h,a
2099    0A48  7D        		ld	a,l
2100    0A49  E680      		and	128
2101    0A4B  6F        		ld	l,a
2102    0A4C  97        		sub	a
2103    0A4D  67        		ld	h,a
2104    0A4E  E5        		push	hl
2105    0A4F  210700    		ld	hl,7
2106    0A52  E5        		push	hl
2107    0A53  CD0000    		call	c.irsh
2108    0A56  E1        		pop	hl
2109    0A57  E3        		ex	(sp),hl
2110    0A58  C1        		pop	bc
2111    0A59  09        		add	hl,bc
2112    0A5A  E5        		push	hl
2113    0A5B  3A1700    		ld	a,(_csdreg+9)
2114    0A5E  6F        		ld	l,a
2115    0A5F  97        		sub	a
2116    0A60  67        		ld	h,a
2117    0A61  7D        		ld	a,l
2118    0A62  E603      		and	3
2119    0A64  6F        		ld	l,a
2120    0A65  97        		sub	a
2121    0A66  67        		ld	h,a
2122    0A67  29        		add	hl,hl
2123    0A68  E3        		ex	(sp),hl
2124    0A69  C1        		pop	bc
2125    0A6A  09        		add	hl,bc
2126    0A6B  23        		inc	hl
2127    0A6C  23        		inc	hl
2128    0A6D  DD75F8    		ld	(ix-8),l
2129    0A70  DD74F9    		ld	(ix-7),h
2130                    	;  534          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2131                    	;  535                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2132    0A73  3A1600    		ld	a,(_csdreg+8)
2133    0A76  4F        		ld	c,a
2134    0A77  97        		sub	a
2135    0A78  47        		ld	b,a
2136    0A79  C5        		push	bc
2137    0A7A  210600    		ld	hl,6
2138    0A7D  E5        		push	hl
2139    0A7E  CD0000    		call	c.irsh
2140    0A81  E1        		pop	hl
2141    0A82  E5        		push	hl
2142    0A83  3A1500    		ld	a,(_csdreg+7)
2143    0A86  6F        		ld	l,a
2144    0A87  97        		sub	a
2145    0A88  67        		ld	h,a
2146    0A89  29        		add	hl,hl
2147    0A8A  29        		add	hl,hl
2148    0A8B  E3        		ex	(sp),hl
2149    0A8C  C1        		pop	bc
2150    0A8D  09        		add	hl,bc
2151    0A8E  E5        		push	hl
2152    0A8F  3A1400    		ld	a,(_csdreg+6)
2153    0A92  6F        		ld	l,a
2154    0A93  97        		sub	a
2155    0A94  67        		ld	h,a
2156    0A95  7D        		ld	a,l
2157    0A96  E603      		and	3
2158    0A98  6F        		ld	l,a
2159    0A99  97        		sub	a
2160    0A9A  67        		ld	h,a
2161    0A9B  E5        		push	hl
2162    0A9C  210A00    		ld	hl,10
2163    0A9F  E5        		push	hl
2164    0AA0  CD0000    		call	c.ilsh
2165    0AA3  E1        		pop	hl
2166    0AA4  E3        		ex	(sp),hl
2167    0AA5  C1        		pop	bc
2168    0AA6  09        		add	hl,bc
2169    0AA7  23        		inc	hl
2170    0AA8  DD75F6    		ld	(ix-10),l
2171    0AAB  DD74F7    		ld	(ix-9),h
2172                    	;  536          capacity = (unsigned long) csize << (n-10);
2173    0AAE  DDE5      		push	ix
2174    0AB0  C1        		pop	bc
2175    0AB1  21EEFF    		ld	hl,65518
2176    0AB4  09        		add	hl,bc
2177    0AB5  E5        		push	hl
2178    0AB6  DDE5      		push	ix
2179    0AB8  C1        		pop	bc
2180    0AB9  21F6FF    		ld	hl,65526
2181    0ABC  09        		add	hl,bc
2182    0ABD  4D        		ld	c,l
2183    0ABE  44        		ld	b,h
2184    0ABF  97        		sub	a
2185    0AC0  320000    		ld	(c.r0),a
2186    0AC3  320100    		ld	(c.r0+1),a
2187    0AC6  0A        		ld	a,(bc)
2188    0AC7  320200    		ld	(c.r0+2),a
2189    0ACA  03        		inc	bc
2190    0ACB  0A        		ld	a,(bc)
2191    0ACC  320300    		ld	(c.r0+3),a
2192    0ACF  210000    		ld	hl,c.r0
2193    0AD2  E5        		push	hl
2194    0AD3  DD6EF8    		ld	l,(ix-8)
2195    0AD6  DD66F9    		ld	h,(ix-7)
2196    0AD9  01F6FF    		ld	bc,65526
2197    0ADC  09        		add	hl,bc
2198    0ADD  E5        		push	hl
2199    0ADE  CD0000    		call	c.llsh
2200    0AE1  CD0000    		call	c.mvl
2201    0AE4  F1        		pop	af
2202                    	;  537          printf("Device capacity: %lu MByte\n", capacity >> 10);
2203    0AE5  DDE5      		push	ix
2204    0AE7  C1        		pop	bc
2205    0AE8  21EEFF    		ld	hl,65518
2206    0AEB  09        		add	hl,bc
2207    0AEC  CD0000    		call	c.0mvf
2208    0AEF  210000    		ld	hl,c.r0
2209    0AF2  E5        		push	hl
2210    0AF3  210A00    		ld	hl,10
2211    0AF6  E5        		push	hl
2212    0AF7  CD0000    		call	c.ulrsh
2213    0AFA  E1        		pop	hl
2214    0AFB  23        		inc	hl
2215    0AFC  23        		inc	hl
2216    0AFD  4E        		ld	c,(hl)
2217    0AFE  23        		inc	hl
2218    0AFF  46        		ld	b,(hl)
2219    0B00  C5        		push	bc
2220    0B01  2B        		dec	hl
2221    0B02  2B        		dec	hl
2222    0B03  2B        		dec	hl
2223    0B04  4E        		ld	c,(hl)
2224    0B05  23        		inc	hl
2225    0B06  46        		ld	b,(hl)
2226    0B07  C5        		push	bc
2227    0B08  21B608    		ld	hl,L541
2228    0B0B  CD0000    		call	_printf
2229    0B0E  F1        		pop	af
2230    0B0F  F1        		pop	af
2231                    	L1621:
2232                    	;  538          }
2233                    	;  539      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
2234    0B10  3A0E00    		ld	a,(_csdreg)
2235    0B13  6F        		ld	l,a
2236    0B14  97        		sub	a
2237    0B15  67        		ld	h,a
2238    0B16  7D        		ld	a,l
2239    0B17  E6C0      		and	192
2240    0B19  6F        		ld	l,a
2241    0B1A  97        		sub	a
2242    0B1B  67        		ld	h,a
2243    0B1C  7D        		ld	a,l
2244    0B1D  FE40      		cp	64
2245    0B1F  2003      		jr	nz,L63
2246    0B21  7C        		ld	a,h
2247    0B22  FE00      		cp	0
2248                    	L63:
2249    0B24  C2F70B    		jp	nz,L1721
2250                    	;  540          {
2251                    	;  541          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2252                    	;  542                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2253    0B27  DDE5      		push	ix
2254    0B29  C1        		pop	bc
2255    0B2A  21F2FF    		ld	hl,65522
2256    0B2D  09        		add	hl,bc
2257    0B2E  E5        		push	hl
2258    0B2F  97        		sub	a
2259    0B30  320000    		ld	(c.r0),a
2260    0B33  320100    		ld	(c.r0+1),a
2261    0B36  3A1600    		ld	a,(_csdreg+8)
2262    0B39  320200    		ld	(c.r0+2),a
2263    0B3C  97        		sub	a
2264    0B3D  320300    		ld	(c.r0+3),a
2265    0B40  210000    		ld	hl,c.r0
2266    0B43  E5        		push	hl
2267    0B44  210800    		ld	hl,8
2268    0B47  E5        		push	hl
2269    0B48  CD0000    		call	c.llsh
2270    0B4B  97        		sub	a
2271    0B4C  320000    		ld	(c.r1),a
2272    0B4F  320100    		ld	(c.r1+1),a
2273    0B52  3A1700    		ld	a,(_csdreg+9)
2274    0B55  320200    		ld	(c.r1+2),a
2275    0B58  97        		sub	a
2276    0B59  320300    		ld	(c.r1+3),a
2277    0B5C  210000    		ld	hl,c.r1
2278    0B5F  E5        		push	hl
2279    0B60  CD0000    		call	c.ladd
2280    0B63  3A1500    		ld	a,(_csdreg+7)
2281    0B66  6F        		ld	l,a
2282    0B67  97        		sub	a
2283    0B68  67        		ld	h,a
2284    0B69  7D        		ld	a,l
2285    0B6A  E63F      		and	63
2286    0B6C  6F        		ld	l,a
2287    0B6D  97        		sub	a
2288    0B6E  67        		ld	h,a
2289    0B6F  4D        		ld	c,l
2290    0B70  44        		ld	b,h
2291    0B71  78        		ld	a,b
2292    0B72  87        		add	a,a
2293    0B73  9F        		sbc	a,a
2294    0B74  320000    		ld	(c.r1),a
2295    0B77  320100    		ld	(c.r1+1),a
2296    0B7A  78        		ld	a,b
2297    0B7B  320300    		ld	(c.r1+3),a
2298    0B7E  79        		ld	a,c
2299    0B7F  320200    		ld	(c.r1+2),a
2300    0B82  210000    		ld	hl,c.r1
2301    0B85  E5        		push	hl
2302    0B86  211000    		ld	hl,16
2303    0B89  E5        		push	hl
2304    0B8A  CD0000    		call	c.llsh
2305    0B8D  CD0000    		call	c.ladd
2306    0B90  3E01      		ld	a,1
2307    0B92  320200    		ld	(c.r1+2),a
2308    0B95  87        		add	a,a
2309    0B96  9F        		sbc	a,a
2310    0B97  320300    		ld	(c.r1+3),a
2311    0B9A  320100    		ld	(c.r1+1),a
2312    0B9D  320000    		ld	(c.r1),a
2313    0BA0  210000    		ld	hl,c.r1
2314    0BA3  E5        		push	hl
2315    0BA4  CD0000    		call	c.ladd
2316    0BA7  CD0000    		call	c.mvl
2317    0BAA  F1        		pop	af
2318                    	;  543          capacity = devsize << 9;
2319    0BAB  DDE5      		push	ix
2320    0BAD  C1        		pop	bc
2321    0BAE  21EEFF    		ld	hl,65518
2322    0BB1  09        		add	hl,bc
2323    0BB2  E5        		push	hl
2324    0BB3  DDE5      		push	ix
2325    0BB5  C1        		pop	bc
2326    0BB6  21F2FF    		ld	hl,65522
2327    0BB9  09        		add	hl,bc
2328    0BBA  CD0000    		call	c.0mvf
2329    0BBD  210000    		ld	hl,c.r0
2330    0BC0  E5        		push	hl
2331    0BC1  210900    		ld	hl,9
2332    0BC4  E5        		push	hl
2333    0BC5  CD0000    		call	c.llsh
2334    0BC8  CD0000    		call	c.mvl
2335    0BCB  F1        		pop	af
2336                    	;  544          printf("Device capacity: %lu MByte\n", capacity >> 10);
2337    0BCC  DDE5      		push	ix
2338    0BCE  C1        		pop	bc
2339    0BCF  21EEFF    		ld	hl,65518
2340    0BD2  09        		add	hl,bc
2341    0BD3  CD0000    		call	c.0mvf
2342    0BD6  210000    		ld	hl,c.r0
2343    0BD9  E5        		push	hl
2344    0BDA  210A00    		ld	hl,10
2345    0BDD  E5        		push	hl
2346    0BDE  CD0000    		call	c.ulrsh
2347    0BE1  E1        		pop	hl
2348    0BE2  23        		inc	hl
2349    0BE3  23        		inc	hl
2350    0BE4  4E        		ld	c,(hl)
2351    0BE5  23        		inc	hl
2352    0BE6  46        		ld	b,(hl)
2353    0BE7  C5        		push	bc
2354    0BE8  2B        		dec	hl
2355    0BE9  2B        		dec	hl
2356    0BEA  2B        		dec	hl
2357    0BEB  4E        		ld	c,(hl)
2358    0BEC  23        		inc	hl
2359    0BED  46        		ld	b,(hl)
2360    0BEE  C5        		push	bc
2361    0BEF  21D208    		ld	hl,L551
2362    0BF2  CD0000    		call	_printf
2363    0BF5  F1        		pop	af
2364    0BF6  F1        		pop	af
2365                    	L1721:
2366                    	;  545          }
2367                    	;  546      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
2368    0BF7  3A0E00    		ld	a,(_csdreg)
2369    0BFA  6F        		ld	l,a
2370    0BFB  97        		sub	a
2371    0BFC  67        		ld	h,a
2372    0BFD  7D        		ld	a,l
2373    0BFE  E6C0      		and	192
2374    0C00  6F        		ld	l,a
2375    0C01  97        		sub	a
2376    0C02  67        		ld	h,a
2377    0C03  7D        		ld	a,l
2378    0C04  FE80      		cp	128
2379    0C06  2003      		jr	nz,L04
2380    0C08  7C        		ld	a,h
2381    0C09  FE00      		cp	0
2382                    	L04:
2383    0C0B  C2DE0C    		jp	nz,L1031
2384                    	;  547          {
2385                    	;  548          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2386                    	;  549                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2387    0C0E  DDE5      		push	ix
2388    0C10  C1        		pop	bc
2389    0C11  21F2FF    		ld	hl,65522
2390    0C14  09        		add	hl,bc
2391    0C15  E5        		push	hl
2392    0C16  97        		sub	a
2393    0C17  320000    		ld	(c.r0),a
2394    0C1A  320100    		ld	(c.r0+1),a
2395    0C1D  3A1600    		ld	a,(_csdreg+8)
2396    0C20  320200    		ld	(c.r0+2),a
2397    0C23  97        		sub	a
2398    0C24  320300    		ld	(c.r0+3),a
2399    0C27  210000    		ld	hl,c.r0
2400    0C2A  E5        		push	hl
2401    0C2B  210800    		ld	hl,8
2402    0C2E  E5        		push	hl
2403    0C2F  CD0000    		call	c.llsh
2404    0C32  97        		sub	a
2405    0C33  320000    		ld	(c.r1),a
2406    0C36  320100    		ld	(c.r1+1),a
2407    0C39  3A1700    		ld	a,(_csdreg+9)
2408    0C3C  320200    		ld	(c.r1+2),a
2409    0C3F  97        		sub	a
2410    0C40  320300    		ld	(c.r1+3),a
2411    0C43  210000    		ld	hl,c.r1
2412    0C46  E5        		push	hl
2413    0C47  CD0000    		call	c.ladd
2414    0C4A  3A1500    		ld	a,(_csdreg+7)
2415    0C4D  6F        		ld	l,a
2416    0C4E  97        		sub	a
2417    0C4F  67        		ld	h,a
2418    0C50  7D        		ld	a,l
2419    0C51  E63F      		and	63
2420    0C53  6F        		ld	l,a
2421    0C54  97        		sub	a
2422    0C55  67        		ld	h,a
2423    0C56  4D        		ld	c,l
2424    0C57  44        		ld	b,h
2425    0C58  78        		ld	a,b
2426    0C59  87        		add	a,a
2427    0C5A  9F        		sbc	a,a
2428    0C5B  320000    		ld	(c.r1),a
2429    0C5E  320100    		ld	(c.r1+1),a
2430    0C61  78        		ld	a,b
2431    0C62  320300    		ld	(c.r1+3),a
2432    0C65  79        		ld	a,c
2433    0C66  320200    		ld	(c.r1+2),a
2434    0C69  210000    		ld	hl,c.r1
2435    0C6C  E5        		push	hl
2436    0C6D  211000    		ld	hl,16
2437    0C70  E5        		push	hl
2438    0C71  CD0000    		call	c.llsh
2439    0C74  CD0000    		call	c.ladd
2440    0C77  3E01      		ld	a,1
2441    0C79  320200    		ld	(c.r1+2),a
2442    0C7C  87        		add	a,a
2443    0C7D  9F        		sbc	a,a
2444    0C7E  320300    		ld	(c.r1+3),a
2445    0C81  320100    		ld	(c.r1+1),a
2446    0C84  320000    		ld	(c.r1),a
2447    0C87  210000    		ld	hl,c.r1
2448    0C8A  E5        		push	hl
2449    0C8B  CD0000    		call	c.ladd
2450    0C8E  CD0000    		call	c.mvl
2451    0C91  F1        		pop	af
2452                    	;  550          capacity = devsize << 9;
2453    0C92  DDE5      		push	ix
2454    0C94  C1        		pop	bc
2455    0C95  21EEFF    		ld	hl,65518
2456    0C98  09        		add	hl,bc
2457    0C99  E5        		push	hl
2458    0C9A  DDE5      		push	ix
2459    0C9C  C1        		pop	bc
2460    0C9D  21F2FF    		ld	hl,65522
2461    0CA0  09        		add	hl,bc
2462    0CA1  CD0000    		call	c.0mvf
2463    0CA4  210000    		ld	hl,c.r0
2464    0CA7  E5        		push	hl
2465    0CA8  210900    		ld	hl,9
2466    0CAB  E5        		push	hl
2467    0CAC  CD0000    		call	c.llsh
2468    0CAF  CD0000    		call	c.mvl
2469    0CB2  F1        		pop	af
2470                    	;  551          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
2471    0CB3  DDE5      		push	ix
2472    0CB5  C1        		pop	bc
2473    0CB6  21EEFF    		ld	hl,65518
2474    0CB9  09        		add	hl,bc
2475    0CBA  CD0000    		call	c.0mvf
2476    0CBD  210000    		ld	hl,c.r0
2477    0CC0  E5        		push	hl
2478    0CC1  210A00    		ld	hl,10
2479    0CC4  E5        		push	hl
2480    0CC5  CD0000    		call	c.ulrsh
2481    0CC8  E1        		pop	hl
2482    0CC9  23        		inc	hl
2483    0CCA  23        		inc	hl
2484    0CCB  4E        		ld	c,(hl)
2485    0CCC  23        		inc	hl
2486    0CCD  46        		ld	b,(hl)
2487    0CCE  C5        		push	bc
2488    0CCF  2B        		dec	hl
2489    0CD0  2B        		dec	hl
2490    0CD1  2B        		dec	hl
2491    0CD2  4E        		ld	c,(hl)
2492    0CD3  23        		inc	hl
2493    0CD4  46        		ld	b,(hl)
2494    0CD5  C5        		push	bc
2495    0CD6  21EE08    		ld	hl,L561
2496    0CD9  CD0000    		call	_printf
2497    0CDC  F1        		pop	af
2498    0CDD  F1        		pop	af
2499                    	L1031:
2500                    	;  552          }
2501                    	;  553  
2502                    	;  554  #ifdef SDTEST
2503                    	;  555  
2504                    	;  556      printf("--------------------------------------\n");
2505                    	;  557      printf("OCR register:\n");
2506                    	;  558      if (ocrreg[2] & 0x80)
2507                    	;  559          printf("2.7-2.8V (bit 15) ");
2508                    	;  560      if (ocrreg[1] & 0x01)
2509                    	;  561          printf("2.8-2.9V (bit 16) ");
2510                    	;  562      if (ocrreg[1] & 0x02)
2511                    	;  563          printf("2.9-3.0V (bit 17) ");
2512                    	;  564      if (ocrreg[1] & 0x04)
2513                    	;  565          printf("3.0-3.1V (bit 18) \n");
2514                    	;  566      if (ocrreg[1] & 0x08)
2515                    	;  567          printf("3.1-3.2V (bit 19) ");
2516                    	;  568      if (ocrreg[1] & 0x10)
2517                    	;  569          printf("3.2-3.3V (bit 20) ");
2518                    	;  570      if (ocrreg[1] & 0x20)
2519                    	;  571          printf("3.3-3.4V (bit 21) ");
2520                    	;  572      if (ocrreg[1] & 0x40)
2521                    	;  573          printf("3.4-3.5V (bit 22) \n");
2522                    	;  574      if (ocrreg[1] & 0x80)
2523                    	;  575          printf("3.5-3.6V (bit 23) \n");
2524                    	;  576      if (ocrreg[0] & 0x01)
2525                    	;  577          printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
2526                    	;  578      if (ocrreg[0] & 0x08)
2527                    	;  579          printf("Over 2TB support Status (CO2T) (bit 27) set\n");
2528                    	;  580      if (ocrreg[0] & 0x20)
2529                    	;  581          printf("UHS-II Card Status (bit 29) set ");
2530                    	;  582      if (ocrreg[0] & 0x80)
2531                    	;  583          {
2532                    	;  584          if (ocrreg[0] & 0x40)
2533                    	;  585              {
2534                    	;  586              printf("Card Capacity Status (CCS) (bit 30) set\n");
2535                    	;  587              printf("  SD Ver.2+, Block address");
2536                    	;  588              }
2537                    	;  589          else
2538                    	;  590              {
2539                    	;  591              printf("Card Capacity Status (CCS) (bit 30) not set\n");
2540                    	;  592              if (sdver2)
2541                    	;  593                  printf("  SD Ver.2+, Byte address");
2542                    	;  594              else
2543                    	;  595                  printf("  SD Ver.1, Byte address");
2544                    	;  596              }
2545                    	;  597          printf("\nCard power up status bit (busy) (bit 31) set\n");
2546                    	;  598          }
2547                    	;  599      else
2548                    	;  600          {
2549                    	;  601          printf("\nCard power up status bit (busy) (bit 31) not set.\n");
2550                    	;  602          printf("  This bit is not set if the card has not finished the power up routine.\n");
2551                    	;  603          }
2552                    	;  604      printf("--------------------------------------\n");
2553                    	;  605      printf("CID register:\n");
2554                    	;  606      printf("MID: 0x%02x, ", cidreg[0]);
2555                    	;  607      printf("OID: %.2s, ", &cidreg[1]);
2556                    	;  608      printf("PNM: %.5s, ", &cidreg[3]);
2557                    	;  609      printf("PRV: %d.%d, ",
2558                    	;  610             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
2559                    	;  611      printf("PSN: %lu, ",
2560                    	;  612             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
2561                    	;  613      printf("MDT: %d-%d\n",
2562                    	;  614             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2563                    	;  615      printf("--------------------------------------\n");
2564                    	;  616      printf("CSD register:\n");
2565                    	;  617      if ((csdreg[0] & 0xc0) == 0x00)
2566                    	;  618          {
2567                    	;  619          printf("CSD Version 1.0, Standard Capacity\n");
2568                    	;  620          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2569                    	;  621          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2570                    	;  622                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2571                    	;  623          capacity = (unsigned long) csize << (n-10);
2572                    	;  624          printf(" Device capacity: %lu KByte, %lu MByte\n",
2573                    	;  625                 capacity, capacity >> 10);
2574                    	;  626          }
2575                    	;  627      if ((csdreg[0] & 0xc0) == 0x40)
2576                    	;  628          {
2577                    	;  629          printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
2578                    	;  630          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2579                    	;  631                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2580                    	;  632          capacity = devsize << 9;
2581                    	;  633          printf(" Device capacity: %lu KByte, %lu MByte\n",
2582                    	;  634                 capacity, capacity >> 10);
2583                    	;  635          }
2584                    	;  636      if ((csdreg[0] & 0xc0) == 0x80)
2585                    	;  637          {
2586                    	;  638          printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
2587                    	;  639          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2588                    	;  640                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2589                    	;  641          capacity = devsize << 9;
2590                    	;  642          printf(" Device capacity: %lu KByte, %lu MByte\n",
2591                    	;  643                 capacity, capacity >> 10);
2592                    	;  644          }
2593                    	;  645      printf("--------------------------------------\n");
2594                    	;  646  
2595                    	;  647  #endif /* SDTEST */
2596                    	;  648  
2597                    	;  649      }
2598    0CDE  C30000    		jp	c.rets0
2599                    	;  650  
2600                    	;  651  /* Read data block of 512 bytes to buffer
2601                    	;  652   * Returns YES if ok or NO if error
2602                    	;  653   */
2603                    	;  654  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
2604                    	;  655      {
2605                    	_sdread:
2606    0CE1  CD0000    		call	c.savs
2607    0CE4  21E0FF    		ld	hl,65504
2608    0CE7  39        		add	hl,sp
2609    0CE8  F9        		ld	sp,hl
2610                    	;  656      unsigned char *statptr;
2611                    	;  657      unsigned char rbyte;
2612                    	;  658      unsigned char cmdbuf[5];   /* buffer to build command in */
2613                    	;  659      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2614                    	;  660      int nbytes;
2615                    	;  661      int tries;
2616                    	;  662      unsigned long blktoread;
2617                    	;  663      unsigned int rxcrc16;
2618                    	;  664      unsigned int calcrc16;
2619                    	;  665  
2620                    	;  666      ledon();
2621    0CE9  CD0000    		call	_ledon
2622                    	;  667      spiselect();
2623    0CEC  CD0000    		call	_spiselect
2624                    	;  668  
2625                    	;  669      if (!sdinitok)
2626    0CEF  2A0A00    		ld	hl,(_sdinitok)
2627    0CF2  7C        		ld	a,h
2628    0CF3  B5        		or	l
2629    0CF4  200C      		jr	nz,L1131
2630                    	;  670          {
2631                    	;  671  #ifdef SDTEST
2632                    	;  672          printf("SD card not initialized\n");
2633                    	;  673  #endif
2634                    	;  674          spideselect();
2635    0CF6  CD0000    		call	_spideselect
2636                    	;  675          ledoff();
2637    0CF9  CD0000    		call	_ledoff
2638                    	;  676          return (NO);
2639    0CFC  010000    		ld	bc,0
2640    0CFF  C30000    		jp	c.rets
2641                    	L1131:
2642                    	;  677          }
2643                    	;  678  
2644                    	;  679      /* CMD17: READ_SINGLE_BLOCK */
2645                    	;  680      /* Insert block # into command */
2646                    	;  681      memcpy(cmdbuf, cmd17, 5);
2647    0D02  210500    		ld	hl,5
2648    0D05  E5        		push	hl
2649    0D06  213500    		ld	hl,_cmd17
2650    0D09  E5        		push	hl
2651    0D0A  DDE5      		push	ix
2652    0D0C  C1        		pop	bc
2653    0D0D  21F2FF    		ld	hl,65522
2654    0D10  09        		add	hl,bc
2655    0D11  CD0000    		call	_memcpy
2656    0D14  F1        		pop	af
2657    0D15  F1        		pop	af
2658                    	;  682      blktoread = blkmult * rdblkno;
2659    0D16  DDE5      		push	ix
2660    0D18  C1        		pop	bc
2661    0D19  21E4FF    		ld	hl,65508
2662    0D1C  09        		add	hl,bc
2663    0D1D  E5        		push	hl
2664    0D1E  210400    		ld	hl,_blkmult
2665    0D21  CD0000    		call	c.0mvf
2666    0D24  210000    		ld	hl,c.r0
2667    0D27  E5        		push	hl
2668    0D28  DDE5      		push	ix
2669    0D2A  C1        		pop	bc
2670    0D2B  210600    		ld	hl,6
2671    0D2E  09        		add	hl,bc
2672    0D2F  E5        		push	hl
2673    0D30  CD0000    		call	c.lmul
2674    0D33  CD0000    		call	c.mvl
2675    0D36  F1        		pop	af
2676                    	;  683      cmdbuf[4] = blktoread & 0xff;
2677    0D37  DD6EE6    		ld	l,(ix-26)
2678    0D3A  7D        		ld	a,l
2679    0D3B  E6FF      		and	255
2680    0D3D  DD77F6    		ld	(ix-10),a
2681                    	;  684      blktoread = blktoread >> 8;
2682    0D40  DDE5      		push	ix
2683    0D42  C1        		pop	bc
2684    0D43  21E4FF    		ld	hl,65508
2685    0D46  09        		add	hl,bc
2686    0D47  E5        		push	hl
2687    0D48  210800    		ld	hl,8
2688    0D4B  E5        		push	hl
2689    0D4C  CD0000    		call	c.ulrsh
2690    0D4F  F1        		pop	af
2691                    	;  685      cmdbuf[3] = blktoread & 0xff;
2692    0D50  DD6EE6    		ld	l,(ix-26)
2693    0D53  7D        		ld	a,l
2694    0D54  E6FF      		and	255
2695    0D56  DD77F5    		ld	(ix-11),a
2696                    	;  686      blktoread = blktoread >> 8;
2697    0D59  DDE5      		push	ix
2698    0D5B  C1        		pop	bc
2699    0D5C  21E4FF    		ld	hl,65508
2700    0D5F  09        		add	hl,bc
2701    0D60  E5        		push	hl
2702    0D61  210800    		ld	hl,8
2703    0D64  E5        		push	hl
2704    0D65  CD0000    		call	c.ulrsh
2705    0D68  F1        		pop	af
2706                    	;  687      cmdbuf[2] = blktoread & 0xff;
2707    0D69  DD6EE6    		ld	l,(ix-26)
2708    0D6C  7D        		ld	a,l
2709    0D6D  E6FF      		and	255
2710    0D6F  DD77F4    		ld	(ix-12),a
2711                    	;  688      blktoread = blktoread >> 8;
2712    0D72  DDE5      		push	ix
2713    0D74  C1        		pop	bc
2714    0D75  21E4FF    		ld	hl,65508
2715    0D78  09        		add	hl,bc
2716    0D79  E5        		push	hl
2717    0D7A  210800    		ld	hl,8
2718    0D7D  E5        		push	hl
2719    0D7E  CD0000    		call	c.ulrsh
2720    0D81  F1        		pop	af
2721                    	;  689      cmdbuf[1] = blktoread & 0xff;
2722    0D82  DD6EE6    		ld	l,(ix-26)
2723    0D85  7D        		ld	a,l
2724    0D86  E6FF      		and	255
2725    0D88  DD77F3    		ld	(ix-13),a
2726                    	;  690  
2727                    	;  691  #ifdef SDTEST
2728                    	;  692      printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2729                    	;  693                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2730                    	;  694  #endif
2731                    	;  695      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2732    0D8B  210100    		ld	hl,1
2733    0D8E  E5        		push	hl
2734    0D8F  DDE5      		push	ix
2735    0D91  C1        		pop	bc
2736    0D92  21EDFF    		ld	hl,65517
2737    0D95  09        		add	hl,bc
2738    0D96  E5        		push	hl
2739    0D97  DDE5      		push	ix
2740    0D99  C1        		pop	bc
2741    0D9A  21F2FF    		ld	hl,65522
2742    0D9D  09        		add	hl,bc
2743    0D9E  CD6301    		call	_sdcommand
2744    0DA1  F1        		pop	af
2745    0DA2  F1        		pop	af
2746    0DA3  DD71F8    		ld	(ix-8),c
2747    0DA6  DD70F9    		ld	(ix-7),b
2748                    	;  696  #ifdef SDTEST
2749                    	;  697          printf("CMD17 R1 response [%02x]\n", statptr[0]);
2750                    	;  698  #endif
2751                    	;  699      if (statptr[0])
2752    0DA9  DD6EF8    		ld	l,(ix-8)
2753    0DAC  DD66F9    		ld	h,(ix-7)
2754    0DAF  7E        		ld	a,(hl)
2755    0DB0  B7        		or	a
2756    0DB1  280C      		jr	z,L1231
2757                    	;  700          {
2758                    	;  701  #ifdef SDTEST
2759                    	;  702          printf("  could not read block\n");
2760                    	;  703  #endif
2761                    	;  704          spideselect();
2762    0DB3  CD0000    		call	_spideselect
2763                    	;  705          ledoff();
2764    0DB6  CD0000    		call	_ledoff
2765                    	;  706          return (NO);
2766    0DB9  010000    		ld	bc,0
2767    0DBC  C30000    		jp	c.rets
2768                    	L1231:
2769                    	;  707          }
2770                    	;  708      /* looking for 0xfe that is the byte before data */
2771                    	;  709      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
2772    0DBF  DD36E850  		ld	(ix-24),80
2773    0DC3  DD36E900  		ld	(ix-23),0
2774                    	L1331:
2775    0DC7  97        		sub	a
2776    0DC8  DD96E8    		sub	(ix-24)
2777    0DCB  3E00      		ld	a,0
2778    0DCD  DD9EE9    		sbc	a,(ix-23)
2779    0DD0  F2060E    		jp	p,L1431
2780    0DD3  21FF00    		ld	hl,255
2781    0DD6  CD0000    		call	_spiio
2782    0DD9  DD71F7    		ld	(ix-9),c
2783    0DDC  DD7EF7    		ld	a,(ix-9)
2784    0DDF  FEFE      		cp	254
2785    0DE1  2823      		jr	z,L1431
2786                    	;  710          {
2787                    	;  711          if ((rbyte & 0xe0) == 0x00)
2788    0DE3  DD6EF7    		ld	l,(ix-9)
2789    0DE6  7D        		ld	a,l
2790    0DE7  E6E0      		and	224
2791    0DE9  200C      		jr	nz,L1531
2792                    	;  712              {
2793                    	;  713              /* If a read operation fails and the card cannot provide
2794                    	;  714                 the required data, it will send a data error token instead
2795                    	;  715               */
2796                    	;  716  #ifdef SDTEST
2797                    	;  717              printf("  read error: [%02x]\n", rbyte);
2798                    	;  718  #endif
2799                    	;  719              spideselect();
2800    0DEB  CD0000    		call	_spideselect
2801                    	;  720              ledoff();
2802    0DEE  CD0000    		call	_ledoff
2803                    	;  721              return (NO);
2804    0DF1  010000    		ld	bc,0
2805    0DF4  C30000    		jp	c.rets
2806                    	L1531:
2807    0DF7  DD6EE8    		ld	l,(ix-24)
2808    0DFA  DD66E9    		ld	h,(ix-23)
2809    0DFD  2B        		dec	hl
2810    0DFE  DD75E8    		ld	(ix-24),l
2811    0E01  DD74E9    		ld	(ix-23),h
2812    0E04  18C1      		jr	L1331
2813                    	L1431:
2814                    	;  722              }
2815                    	;  723          }
2816                    	;  724      if (tries == 0) /* tried too many times */
2817    0E06  DD7EE8    		ld	a,(ix-24)
2818    0E09  DDB6E9    		or	(ix-23)
2819    0E0C  200C      		jr	nz,L1041
2820                    	;  725          {
2821                    	;  726  #ifdef SDTEST
2822                    	;  727          printf("  no data found\n");
2823                    	;  728  #endif
2824                    	;  729          spideselect();
2825    0E0E  CD0000    		call	_spideselect
2826                    	;  730          ledoff();
2827    0E11  CD0000    		call	_ledoff
2828                    	;  731          return (NO);
2829    0E14  010000    		ld	bc,0
2830    0E17  C30000    		jp	c.rets
2831                    	L1041:
2832                    	;  732          }
2833                    	;  733      else
2834                    	;  734          {
2835                    	;  735          calcrc16 = 0;
2836    0E1A  DD36E000  		ld	(ix-32),0
2837    0E1E  DD36E100  		ld	(ix-31),0
2838                    	;  736          for (nbytes = 0; nbytes < 512; nbytes++)
2839    0E22  DD36EA00  		ld	(ix-22),0
2840    0E26  DD36EB00  		ld	(ix-21),0
2841                    	L1241:
2842    0E2A  DD7EEA    		ld	a,(ix-22)
2843    0E2D  D600      		sub	0
2844    0E2F  DD7EEB    		ld	a,(ix-21)
2845    0E32  DE02      		sbc	a,2
2846    0E34  F2710E    		jp	p,L1341
2847                    	;  737              {
2848                    	;  738              rbyte = spiio(0xff);
2849    0E37  21FF00    		ld	hl,255
2850    0E3A  CD0000    		call	_spiio
2851    0E3D  DD71F7    		ld	(ix-9),c
2852                    	;  739              calcrc16 = CRC16_one(calcrc16, rbyte);
2853    0E40  DD6EF7    		ld	l,(ix-9)
2854    0E43  97        		sub	a
2855    0E44  67        		ld	h,a
2856    0E45  E5        		push	hl
2857    0E46  DD6EE0    		ld	l,(ix-32)
2858    0E49  DD66E1    		ld	h,(ix-31)
2859    0E4C  CDB500    		call	_CRC16_one
2860    0E4F  F1        		pop	af
2861    0E50  DD71E0    		ld	(ix-32),c
2862    0E53  DD70E1    		ld	(ix-31),b
2863                    	;  740              rdbuf[nbytes] = rbyte;
2864    0E56  DD6E04    		ld	l,(ix+4)
2865    0E59  DD6605    		ld	h,(ix+5)
2866    0E5C  DD4EEA    		ld	c,(ix-22)
2867    0E5F  DD46EB    		ld	b,(ix-21)
2868    0E62  09        		add	hl,bc
2869    0E63  DD7EF7    		ld	a,(ix-9)
2870    0E66  77        		ld	(hl),a
2871                    	;  741              }
2872    0E67  DD34EA    		inc	(ix-22)
2873    0E6A  2003      		jr	nz,L44
2874    0E6C  DD34EB    		inc	(ix-21)
2875                    	L44:
2876    0E6F  18B9      		jr	L1241
2877                    	L1341:
2878                    	;  742          rxcrc16 = spiio(0xff) << 8;
2879    0E71  21FF00    		ld	hl,255
2880    0E74  CD0000    		call	_spiio
2881    0E77  69        		ld	l,c
2882    0E78  60        		ld	h,b
2883    0E79  29        		add	hl,hl
2884    0E7A  29        		add	hl,hl
2885    0E7B  29        		add	hl,hl
2886    0E7C  29        		add	hl,hl
2887    0E7D  29        		add	hl,hl
2888    0E7E  29        		add	hl,hl
2889    0E7F  29        		add	hl,hl
2890    0E80  29        		add	hl,hl
2891    0E81  DD75E2    		ld	(ix-30),l
2892    0E84  DD74E3    		ld	(ix-29),h
2893                    	;  743          rxcrc16 += spiio(0xff);
2894    0E87  21FF00    		ld	hl,255
2895    0E8A  CD0000    		call	_spiio
2896    0E8D  DD6EE2    		ld	l,(ix-30)
2897    0E90  DD66E3    		ld	h,(ix-29)
2898    0E93  09        		add	hl,bc
2899    0E94  DD75E2    		ld	(ix-30),l
2900    0E97  DD74E3    		ld	(ix-29),h
2901                    	;  744  
2902                    	;  745  #ifdef SDTEST
2903                    	;  746          printf("  read data block %ld:\n", rdblkno);
2904                    	;  747  #endif
2905                    	;  748          if (rxcrc16 != calcrc16)
2906    0E9A  DD7EE2    		ld	a,(ix-30)
2907    0E9D  DDBEE0    		cp	(ix-32)
2908    0EA0  2006      		jr	nz,L64
2909    0EA2  DD7EE3    		ld	a,(ix-29)
2910    0EA5  DDBEE1    		cp	(ix-31)
2911                    	L64:
2912    0EA8  280C      		jr	z,L1141
2913                    	;  749              {
2914                    	;  750  #ifdef SDTEST
2915                    	;  751              printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
2916                    	;  752                  rxcrc16, calcrc16);
2917                    	;  753  #endif
2918                    	;  754              spideselect();
2919    0EAA  CD0000    		call	_spideselect
2920                    	;  755              ledoff();
2921    0EAD  CD0000    		call	_ledoff
2922                    	;  756              return (NO);
2923    0EB0  010000    		ld	bc,0
2924    0EB3  C30000    		jp	c.rets
2925                    	L1141:
2926                    	;  757              }
2927                    	;  758          }
2928                    	;  759      spideselect();
2929    0EB6  CD0000    		call	_spideselect
2930                    	;  760      ledoff();
2931    0EB9  CD0000    		call	_ledoff
2932                    	;  761      return (YES);
2933    0EBC  010100    		ld	bc,1
2934    0EBF  C30000    		jp	c.rets
2935                    	;  762      }
2936                    	;  763  
2937                    	;  764  /* Write data block of 512 bytes from buffer
2938                    	;  765   * Returns YES if ok or NO if error
2939                    	;  766   */
2940                    	;  767  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
2941                    	;  768      {
2942                    	_sdwrite:
2943    0EC2  CD0000    		call	c.savs
2944    0EC5  21E2FF    		ld	hl,65506
2945    0EC8  39        		add	hl,sp
2946    0EC9  F9        		ld	sp,hl
2947                    	;  769      unsigned char *statptr;
2948                    	;  770      unsigned char rbyte;
2949                    	;  771      unsigned char tbyte;
2950                    	;  772      unsigned char cmdbuf[5];   /* buffer to build command in */
2951                    	;  773      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2952                    	;  774      int nbytes;
2953                    	;  775      int tries;
2954                    	;  776      unsigned long blktowrite;
2955                    	;  777      unsigned int calcrc16;
2956                    	;  778  
2957                    	;  779      ledon();
2958    0ECA  CD0000    		call	_ledon
2959                    	;  780      spiselect();
2960    0ECD  CD0000    		call	_spiselect
2961                    	;  781  
2962                    	;  782      if (!sdinitok)
2963    0ED0  2A0A00    		ld	hl,(_sdinitok)
2964    0ED3  7C        		ld	a,h
2965    0ED4  B5        		or	l
2966    0ED5  200C      		jr	nz,L1741
2967                    	;  783          {
2968                    	;  784  #ifdef SDTEST
2969                    	;  785          printf("SD card not initialized\n");
2970                    	;  786  #endif
2971                    	;  787          spideselect();
2972    0ED7  CD0000    		call	_spideselect
2973                    	;  788          ledoff();
2974    0EDA  CD0000    		call	_ledoff
2975                    	;  789          return (NO);
2976    0EDD  010000    		ld	bc,0
2977    0EE0  C30000    		jp	c.rets
2978                    	L1741:
2979                    	;  790          }
2980                    	;  791  
2981                    	;  792  #ifdef SDTEST
2982                    	;  793      printf("  write data block %ld:\n", wrblkno);
2983                    	;  794  #endif
2984                    	;  795      /* CMD24: WRITE_SINGLE_BLOCK */
2985                    	;  796      /* Insert block # into command */
2986                    	;  797      memcpy(cmdbuf, cmd24, 5);
2987    0EE3  210500    		ld	hl,5
2988    0EE6  E5        		push	hl
2989    0EE7  213B00    		ld	hl,_cmd24
2990    0EEA  E5        		push	hl
2991    0EEB  DDE5      		push	ix
2992    0EED  C1        		pop	bc
2993    0EEE  21F1FF    		ld	hl,65521
2994    0EF1  09        		add	hl,bc
2995    0EF2  CD0000    		call	_memcpy
2996    0EF5  F1        		pop	af
2997    0EF6  F1        		pop	af
2998                    	;  798      blktowrite = blkmult * wrblkno;
2999    0EF7  DDE5      		push	ix
3000    0EF9  C1        		pop	bc
3001    0EFA  21E4FF    		ld	hl,65508
3002    0EFD  09        		add	hl,bc
3003    0EFE  E5        		push	hl
3004    0EFF  210400    		ld	hl,_blkmult
3005    0F02  CD0000    		call	c.0mvf
3006    0F05  210000    		ld	hl,c.r0
3007    0F08  E5        		push	hl
3008    0F09  DDE5      		push	ix
3009    0F0B  C1        		pop	bc
3010    0F0C  210600    		ld	hl,6
3011    0F0F  09        		add	hl,bc
3012    0F10  E5        		push	hl
3013    0F11  CD0000    		call	c.lmul
3014    0F14  CD0000    		call	c.mvl
3015    0F17  F1        		pop	af
3016                    	;  799      cmdbuf[4] = blktowrite & 0xff;
3017    0F18  DD6EE6    		ld	l,(ix-26)
3018    0F1B  7D        		ld	a,l
3019    0F1C  E6FF      		and	255
3020    0F1E  DD77F5    		ld	(ix-11),a
3021                    	;  800      blktowrite = blktowrite >> 8;
3022    0F21  DDE5      		push	ix
3023    0F23  C1        		pop	bc
3024    0F24  21E4FF    		ld	hl,65508
3025    0F27  09        		add	hl,bc
3026    0F28  E5        		push	hl
3027    0F29  210800    		ld	hl,8
3028    0F2C  E5        		push	hl
3029    0F2D  CD0000    		call	c.ulrsh
3030    0F30  F1        		pop	af
3031                    	;  801      cmdbuf[3] = blktowrite & 0xff;
3032    0F31  DD6EE6    		ld	l,(ix-26)
3033    0F34  7D        		ld	a,l
3034    0F35  E6FF      		and	255
3035    0F37  DD77F4    		ld	(ix-12),a
3036                    	;  802      blktowrite = blktowrite >> 8;
3037    0F3A  DDE5      		push	ix
3038    0F3C  C1        		pop	bc
3039    0F3D  21E4FF    		ld	hl,65508
3040    0F40  09        		add	hl,bc
3041    0F41  E5        		push	hl
3042    0F42  210800    		ld	hl,8
3043    0F45  E5        		push	hl
3044    0F46  CD0000    		call	c.ulrsh
3045    0F49  F1        		pop	af
3046                    	;  803      cmdbuf[2] = blktowrite & 0xff;
3047    0F4A  DD6EE6    		ld	l,(ix-26)
3048    0F4D  7D        		ld	a,l
3049    0F4E  E6FF      		and	255
3050    0F50  DD77F3    		ld	(ix-13),a
3051                    	;  804      blktowrite = blktowrite >> 8;
3052    0F53  DDE5      		push	ix
3053    0F55  C1        		pop	bc
3054    0F56  21E4FF    		ld	hl,65508
3055    0F59  09        		add	hl,bc
3056    0F5A  E5        		push	hl
3057    0F5B  210800    		ld	hl,8
3058    0F5E  E5        		push	hl
3059    0F5F  CD0000    		call	c.ulrsh
3060    0F62  F1        		pop	af
3061                    	;  805      cmdbuf[1] = blktowrite & 0xff;
3062    0F63  DD6EE6    		ld	l,(ix-26)
3063    0F66  7D        		ld	a,l
3064    0F67  E6FF      		and	255
3065    0F69  DD77F2    		ld	(ix-14),a
3066                    	;  806  
3067                    	;  807  #ifdef SDTEST
3068                    	;  808      printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
3069                    	;  809                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
3070                    	;  810  #endif
3071                    	;  811      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3072    0F6C  210100    		ld	hl,1
3073    0F6F  E5        		push	hl
3074    0F70  DDE5      		push	ix
3075    0F72  C1        		pop	bc
3076    0F73  21ECFF    		ld	hl,65516
3077    0F76  09        		add	hl,bc
3078    0F77  E5        		push	hl
3079    0F78  DDE5      		push	ix
3080    0F7A  C1        		pop	bc
3081    0F7B  21F1FF    		ld	hl,65521
3082    0F7E  09        		add	hl,bc
3083    0F7F  CD6301    		call	_sdcommand
3084    0F82  F1        		pop	af
3085    0F83  F1        		pop	af
3086    0F84  DD71F8    		ld	(ix-8),c
3087    0F87  DD70F9    		ld	(ix-7),b
3088                    	;  812  #ifdef SDTEST
3089                    	;  813          printf("CMD24 R1 response [%02x]\n", statptr[0]);
3090                    	;  814  #endif
3091                    	;  815      if (statptr[0])
3092    0F8A  DD6EF8    		ld	l,(ix-8)
3093    0F8D  DD66F9    		ld	h,(ix-7)
3094    0F90  7E        		ld	a,(hl)
3095    0F91  B7        		or	a
3096    0F92  280C      		jr	z,L1051
3097                    	;  816          {
3098                    	;  817  #ifdef SDTEST
3099                    	;  818          printf("  could not write block\n");
3100                    	;  819  #endif
3101                    	;  820          spideselect();
3102    0F94  CD0000    		call	_spideselect
3103                    	;  821          ledoff();
3104    0F97  CD0000    		call	_ledoff
3105                    	;  822          return (NO);
3106    0F9A  010000    		ld	bc,0
3107    0F9D  C30000    		jp	c.rets
3108                    	L1051:
3109                    	;  823          }
3110                    	;  824      /* send 0xfe, the byte before data */
3111                    	;  825      spiio(0xfe);
3112    0FA0  21FE00    		ld	hl,254
3113    0FA3  CD0000    		call	_spiio
3114                    	;  826      /* initialize crc and send block */
3115                    	;  827      calcrc16 = 0;
3116    0FA6  DD36E200  		ld	(ix-30),0
3117    0FAA  DD36E300  		ld	(ix-29),0
3118                    	;  828      for (nbytes = 0; nbytes < 512; nbytes++)
3119    0FAE  DD36EA00  		ld	(ix-22),0
3120    0FB2  DD36EB00  		ld	(ix-21),0
3121                    	L1151:
3122    0FB6  DD7EEA    		ld	a,(ix-22)
3123    0FB9  D600      		sub	0
3124    0FBB  DD7EEB    		ld	a,(ix-21)
3125    0FBE  DE02      		sbc	a,2
3126    0FC0  F2FC0F    		jp	p,L1251
3127                    	;  829          {
3128                    	;  830          tbyte = wrbuf[nbytes];
3129    0FC3  DD6E04    		ld	l,(ix+4)
3130    0FC6  DD6605    		ld	h,(ix+5)
3131    0FC9  DD4EEA    		ld	c,(ix-22)
3132    0FCC  DD46EB    		ld	b,(ix-21)
3133    0FCF  09        		add	hl,bc
3134    0FD0  7E        		ld	a,(hl)
3135    0FD1  DD77F6    		ld	(ix-10),a
3136                    	;  831          spiio(tbyte);
3137    0FD4  DD6EF6    		ld	l,(ix-10)
3138    0FD7  97        		sub	a
3139    0FD8  67        		ld	h,a
3140    0FD9  CD0000    		call	_spiio
3141                    	;  832          calcrc16 = CRC16_one(calcrc16, tbyte);
3142    0FDC  DD6EF6    		ld	l,(ix-10)
3143    0FDF  97        		sub	a
3144    0FE0  67        		ld	h,a
3145    0FE1  E5        		push	hl
3146    0FE2  DD6EE2    		ld	l,(ix-30)
3147    0FE5  DD66E3    		ld	h,(ix-29)
3148    0FE8  CDB500    		call	_CRC16_one
3149    0FEB  F1        		pop	af
3150    0FEC  DD71E2    		ld	(ix-30),c
3151    0FEF  DD70E3    		ld	(ix-29),b
3152                    	;  833          }
3153    0FF2  DD34EA    		inc	(ix-22)
3154    0FF5  2003      		jr	nz,L25
3155    0FF7  DD34EB    		inc	(ix-21)
3156                    	L25:
3157    0FFA  18BA      		jr	L1151
3158                    	L1251:
3159                    	;  834      spiio((calcrc16 >> 8) & 0xff);
3160    0FFC  DD6EE2    		ld	l,(ix-30)
3161    0FFF  DD66E3    		ld	h,(ix-29)
3162    1002  E5        		push	hl
3163    1003  210800    		ld	hl,8
3164    1006  E5        		push	hl
3165    1007  CD0000    		call	c.ursh
3166    100A  E1        		pop	hl
3167    100B  7D        		ld	a,l
3168    100C  E6FF      		and	255
3169    100E  6F        		ld	l,a
3170    100F  97        		sub	a
3171    1010  67        		ld	h,a
3172    1011  CD0000    		call	_spiio
3173                    	;  835      spiio(calcrc16 & 0xff);
3174    1014  DD6EE2    		ld	l,(ix-30)
3175    1017  DD66E3    		ld	h,(ix-29)
3176    101A  7D        		ld	a,l
3177    101B  E6FF      		and	255
3178    101D  6F        		ld	l,a
3179    101E  97        		sub	a
3180    101F  67        		ld	h,a
3181    1020  CD0000    		call	_spiio
3182                    	;  836  
3183                    	;  837      /* check data resposnse */
3184                    	;  838      for (tries = 20; 
3185    1023  DD36E814  		ld	(ix-24),20
3186    1027  DD36E900  		ld	(ix-23),0
3187                    	L1551:
3188                    	;  839          0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
3189    102B  97        		sub	a
3190    102C  DD96E8    		sub	(ix-24)
3191    102F  3E00      		ld	a,0
3192    1031  DD9EE9    		sbc	a,(ix-23)
3193    1034  F26410    		jp	p,L1651
3194    1037  21FF00    		ld	hl,255
3195    103A  CD0000    		call	_spiio
3196    103D  DD71F7    		ld	(ix-9),c
3197    1040  DD6EF7    		ld	l,(ix-9)
3198    1043  97        		sub	a
3199    1044  67        		ld	h,a
3200    1045  7D        		ld	a,l
3201    1046  E611      		and	17
3202    1048  6F        		ld	l,a
3203    1049  97        		sub	a
3204    104A  67        		ld	h,a
3205    104B  7D        		ld	a,l
3206    104C  FE01      		cp	1
3207    104E  2003      		jr	nz,L45
3208    1050  7C        		ld	a,h
3209    1051  FE00      		cp	0
3210                    	L45:
3211    1053  280F      		jr	z,L1651
3212                    	;  840          tries--)
3213                    	L1751:
3214    1055  DD6EE8    		ld	l,(ix-24)
3215    1058  DD66E9    		ld	h,(ix-23)
3216    105B  2B        		dec	hl
3217    105C  DD75E8    		ld	(ix-24),l
3218    105F  DD74E9    		ld	(ix-23),h
3219    1062  18C7      		jr	L1551
3220                    	L1651:
3221                    	;  841          ;
3222                    	;  842      if (tries == 0)
3223    1064  DD7EE8    		ld	a,(ix-24)
3224    1067  DDB6E9    		or	(ix-23)
3225    106A  200C      		jr	nz,L1161
3226                    	;  843          {
3227                    	;  844  #ifdef SDTEST
3228                    	;  845          printf("No data response\n");
3229                    	;  846  #endif
3230                    	;  847          spideselect();
3231    106C  CD0000    		call	_spideselect
3232                    	;  848          ledoff();
3233    106F  CD0000    		call	_ledoff
3234                    	;  849          return (NO);
3235    1072  010000    		ld	bc,0
3236    1075  C30000    		jp	c.rets
3237                    	L1161:
3238                    	;  850          }
3239                    	;  851      else
3240                    	;  852          {
3241                    	;  853  #ifdef SDTEST
3242                    	;  854          printf("Data response [%02x]", 0x1f & rbyte);
3243                    	;  855  #endif
3244                    	;  856          if ((0x1f & rbyte) == 0x05)
3245    1078  DD6EF7    		ld	l,(ix-9)
3246    107B  97        		sub	a
3247    107C  67        		ld	h,a
3248    107D  7D        		ld	a,l
3249    107E  E61F      		and	31
3250    1080  6F        		ld	l,a
3251    1081  97        		sub	a
3252    1082  67        		ld	h,a
3253    1083  7D        		ld	a,l
3254    1084  FE05      		cp	5
3255    1086  2003      		jr	nz,L65
3256    1088  7C        		ld	a,h
3257    1089  FE00      		cp	0
3258                    	L65:
3259    108B  2035      		jr	nz,L1361
3260                    	;  857              {
3261                    	;  858  #ifdef SDTEST
3262                    	;  859              printf(", data accepted\n");
3263                    	;  860  #endif
3264                    	;  861              for (nbytes = 9; 0 < nbytes; nbytes--)
3265    108D  DD36EA09  		ld	(ix-22),9
3266    1091  DD36EB00  		ld	(ix-21),0
3267                    	L1461:
3268    1095  97        		sub	a
3269    1096  DD96EA    		sub	(ix-22)
3270    1099  3E00      		ld	a,0
3271    109B  DD9EEB    		sbc	a,(ix-21)
3272    109E  F2B610    		jp	p,L1561
3273                    	;  862                  spiio(0xff);
3274    10A1  21FF00    		ld	hl,255
3275    10A4  CD0000    		call	_spiio
3276    10A7  DD6EEA    		ld	l,(ix-22)
3277    10AA  DD66EB    		ld	h,(ix-21)
3278    10AD  2B        		dec	hl
3279    10AE  DD75EA    		ld	(ix-22),l
3280    10B1  DD74EB    		ld	(ix-21),h
3281    10B4  18DF      		jr	L1461
3282                    	L1561:
3283                    	;  863  #ifdef SDTEST
3284                    	;  864              printf("Sent 9*8 (72) clock pulses, select active\n");
3285                    	;  865  #endif
3286                    	;  866              spideselect();
3287    10B6  CD0000    		call	_spideselect
3288                    	;  867              ledoff();
3289    10B9  CD0000    		call	_ledoff
3290                    	;  868              return (YES);
3291    10BC  010100    		ld	bc,1
3292    10BF  C30000    		jp	c.rets
3293                    	L1361:
3294                    	;  869              }
3295                    	;  870          else
3296                    	;  871              {
3297                    	;  872  #ifdef SDTEST
3298                    	;  873              printf(", data not accepted\n");
3299                    	;  874  #endif
3300                    	;  875              spideselect();
3301    10C2  CD0000    		call	_spideselect
3302                    	;  876              ledoff();
3303    10C5  CD0000    		call	_ledoff
3304                    	;  877              return (NO);
3305    10C8  010000    		ld	bc,0
3306    10CB  C30000    		jp	c.rets
3307                    	L571:
3308    10CE  2A        		.byte	42
3309    10CF  0A        		.byte	10
3310    10D0  00        		.byte	0
3311                    	L502:
3312    10D1  25        		.byte	37
3313    10D2  30        		.byte	48
3314    10D3  34        		.byte	52
3315    10D4  78        		.byte	120
3316    10D5  20        		.byte	32
3317    10D6  00        		.byte	0
3318                    	L512:
3319    10D7  25        		.byte	37
3320    10D8  30        		.byte	48
3321    10D9  32        		.byte	50
3322    10DA  78        		.byte	120
3323    10DB  20        		.byte	32
3324    10DC  00        		.byte	0
3325                    	L522:
3326    10DD  20        		.byte	32
3327    10DE  7C        		.byte	124
3328    10DF  00        		.byte	0
3329                    	L532:
3330    10E0  7C        		.byte	124
3331    10E1  0A        		.byte	10
3332    10E2  00        		.byte	0
3333                    	;  878              }
3334                    	;  879          }
3335                    	;  880      }
3336                    	;  881  
3337                    	;  882  /* Print data in 512 byte buffer */
3338                    	;  883  void sddatprt(unsigned char *prtbuf)
3339                    	;  884      {
3340                    	_sddatprt:
3341    10E3  CD0000    		call	c.savs
3342    10E6  21EEFF    		ld	hl,65518
3343    10E9  39        		add	hl,sp
3344    10EA  F9        		ld	sp,hl
3345                    	;  885      /* Variables used for "pretty-print" */
3346                    	;  886      int allzero, dmpline, dotprted, lastallz, nbytes;
3347                    	;  887      unsigned char *prtptr;
3348                    	;  888  
3349                    	;  889      prtptr = prtbuf;
3350    10EB  DD7E04    		ld	a,(ix+4)
3351    10EE  DD77EE    		ld	(ix-18),a
3352    10F1  DD7E05    		ld	a,(ix+5)
3353    10F4  DD77EF    		ld	(ix-17),a
3354                    	;  890      dotprted = NO;
3355    10F7  DD36F400  		ld	(ix-12),0
3356    10FB  DD36F500  		ld	(ix-11),0
3357                    	;  891      lastallz = NO;
3358    10FF  DD36F200  		ld	(ix-14),0
3359    1103  DD36F300  		ld	(ix-13),0
3360                    	;  892      for (dmpline = 0; dmpline < 32; dmpline++)
3361    1107  DD36F600  		ld	(ix-10),0
3362    110B  DD36F700  		ld	(ix-9),0
3363                    	L1171:
3364    110F  DD7EF6    		ld	a,(ix-10)
3365    1112  D620      		sub	32
3366    1114  DD7EF7    		ld	a,(ix-9)
3367    1117  DE00      		sbc	a,0
3368    1119  F27012    		jp	p,L1271
3369                    	;  893          {
3370                    	;  894          /* test if all 16 bytes are 0x00 */
3371                    	;  895          allzero = YES;
3372    111C  DD36F801  		ld	(ix-8),1
3373    1120  DD36F900  		ld	(ix-7),0
3374                    	;  896          for (nbytes = 0; nbytes < 16; nbytes++)
3375    1124  DD36F000  		ld	(ix-16),0
3376    1128  DD36F100  		ld	(ix-15),0
3377                    	L1571:
3378    112C  DD7EF0    		ld	a,(ix-16)
3379    112F  D610      		sub	16
3380    1131  DD7EF1    		ld	a,(ix-15)
3381    1134  DE00      		sbc	a,0
3382    1136  F25C11    		jp	p,L1671
3383                    	;  897              {
3384                    	;  898              if (prtptr[nbytes] != 0)
3385    1139  DD6EEE    		ld	l,(ix-18)
3386    113C  DD66EF    		ld	h,(ix-17)
3387    113F  DD4EF0    		ld	c,(ix-16)
3388    1142  DD46F1    		ld	b,(ix-15)
3389    1145  09        		add	hl,bc
3390    1146  7E        		ld	a,(hl)
3391    1147  B7        		or	a
3392    1148  2808      		jr	z,L1771
3393                    	;  899                  allzero = NO;
3394    114A  DD36F800  		ld	(ix-8),0
3395    114E  DD36F900  		ld	(ix-7),0
3396                    	L1771:
3397    1152  DD34F0    		inc	(ix-16)
3398    1155  2003      		jr	nz,L46
3399    1157  DD34F1    		inc	(ix-15)
3400                    	L46:
3401    115A  18D0      		jr	L1571
3402                    	L1671:
3403                    	;  900              }
3404                    	;  901          if (lastallz && allzero)
3405    115C  DD7EF2    		ld	a,(ix-14)
3406    115F  DDB6F3    		or	(ix-13)
3407    1162  2822      		jr	z,L1202
3408    1164  DD7EF8    		ld	a,(ix-8)
3409    1167  DDB6F9    		or	(ix-7)
3410    116A  281A      		jr	z,L1202
3411                    	;  902              {
3412                    	;  903              if (!dotprted)
3413    116C  DD7EF4    		ld	a,(ix-12)
3414    116F  DDB6F5    		or	(ix-11)
3415    1172  C24512    		jp	nz,L1402
3416                    	;  904                  {
3417                    	;  905                  printf("*\n");
3418    1175  21CE10    		ld	hl,L571
3419    1178  CD0000    		call	_printf
3420                    	;  906                  dotprted = YES;
3421    117B  DD36F401  		ld	(ix-12),1
3422    117F  DD36F500  		ld	(ix-11),0
3423    1183  C34512    		jp	L1402
3424                    	L1202:
3425                    	;  907                  }
3426                    	;  908              }
3427                    	;  909          else
3428                    	;  910              {
3429                    	;  911              dotprted = NO;
3430    1186  DD36F400  		ld	(ix-12),0
3431    118A  DD36F500  		ld	(ix-11),0
3432                    	;  912              /* print offset */
3433                    	;  913              printf("%04x ", dmpline * 16);
3434    118E  DD6EF6    		ld	l,(ix-10)
3435    1191  DD66F7    		ld	h,(ix-9)
3436    1194  E5        		push	hl
3437    1195  211000    		ld	hl,16
3438    1198  E5        		push	hl
3439    1199  CD0000    		call	c.imul
3440    119C  21D110    		ld	hl,L502
3441    119F  CD0000    		call	_printf
3442    11A2  F1        		pop	af
3443                    	;  914              /* print 16 bytes in hex */
3444                    	;  915              for (nbytes = 0; nbytes < 16; nbytes++)
3445    11A3  DD36F000  		ld	(ix-16),0
3446    11A7  DD36F100  		ld	(ix-15),0
3447                    	L1502:
3448    11AB  DD7EF0    		ld	a,(ix-16)
3449    11AE  D610      		sub	16
3450    11B0  DD7EF1    		ld	a,(ix-15)
3451    11B3  DE00      		sbc	a,0
3452    11B5  F2DA11    		jp	p,L1602
3453                    	;  916                  printf("%02x ", prtptr[nbytes]);
3454    11B8  DD6EEE    		ld	l,(ix-18)
3455    11BB  DD66EF    		ld	h,(ix-17)
3456    11BE  DD4EF0    		ld	c,(ix-16)
3457    11C1  DD46F1    		ld	b,(ix-15)
3458    11C4  09        		add	hl,bc
3459    11C5  4E        		ld	c,(hl)
3460    11C6  97        		sub	a
3461    11C7  47        		ld	b,a
3462    11C8  C5        		push	bc
3463    11C9  21D710    		ld	hl,L512
3464    11CC  CD0000    		call	_printf
3465    11CF  F1        		pop	af
3466    11D0  DD34F0    		inc	(ix-16)
3467    11D3  2003      		jr	nz,L66
3468    11D5  DD34F1    		inc	(ix-15)
3469                    	L66:
3470    11D8  18D1      		jr	L1502
3471                    	L1602:
3472                    	;  917              /* print these bytes in ASCII if printable */
3473                    	;  918              printf(" |");
3474    11DA  21DD10    		ld	hl,L522
3475    11DD  CD0000    		call	_printf
3476                    	;  919              for (nbytes = 0; nbytes < 16; nbytes++)
3477    11E0  DD36F000  		ld	(ix-16),0
3478    11E4  DD36F100  		ld	(ix-15),0
3479                    	L1112:
3480    11E8  DD7EF0    		ld	a,(ix-16)
3481    11EB  D610      		sub	16
3482    11ED  DD7EF1    		ld	a,(ix-15)
3483    11F0  DE00      		sbc	a,0
3484    11F2  F23F12    		jp	p,L1212
3485                    	;  920                  {
3486                    	;  921                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
3487    11F5  DD6EEE    		ld	l,(ix-18)
3488    11F8  DD66EF    		ld	h,(ix-17)
3489    11FB  DD4EF0    		ld	c,(ix-16)
3490    11FE  DD46F1    		ld	b,(ix-15)
3491    1201  09        		add	hl,bc
3492    1202  7E        		ld	a,(hl)
3493    1203  FE20      		cp	32
3494    1205  3827      		jr	c,L1512
3495    1207  DD6EEE    		ld	l,(ix-18)
3496    120A  DD66EF    		ld	h,(ix-17)
3497    120D  DD4EF0    		ld	c,(ix-16)
3498    1210  DD46F1    		ld	b,(ix-15)
3499    1213  09        		add	hl,bc
3500    1214  7E        		ld	a,(hl)
3501    1215  FE7F      		cp	127
3502    1217  3015      		jr	nc,L1512
3503                    	;  922                      putchar(prtptr[nbytes]);
3504    1219  DD6EEE    		ld	l,(ix-18)
3505    121C  DD66EF    		ld	h,(ix-17)
3506    121F  DD4EF0    		ld	c,(ix-16)
3507    1222  DD46F1    		ld	b,(ix-15)
3508    1225  09        		add	hl,bc
3509    1226  6E        		ld	l,(hl)
3510    1227  97        		sub	a
3511    1228  67        		ld	h,a
3512    1229  CD0000    		call	_putchar
3513                    	;  923                  else
3514    122C  1806      		jr	L1312
3515                    	L1512:
3516                    	;  924                      putchar('.');
3517    122E  212E00    		ld	hl,46
3518    1231  CD0000    		call	_putchar
3519                    	L1312:
3520    1234  DD34F0    		inc	(ix-16)
3521    1237  2003      		jr	nz,L07
3522    1239  DD34F1    		inc	(ix-15)
3523                    	L07:
3524    123C  C3E811    		jp	L1112
3525                    	L1212:
3526                    	;  925                  }
3527                    	;  926              printf("|\n");
3528    123F  21E010    		ld	hl,L532
3529    1242  CD0000    		call	_printf
3530                    	L1402:
3531                    	;  927              }
3532                    	;  928          prtptr += 16;
3533    1245  DD6EEE    		ld	l,(ix-18)
3534    1248  DD66EF    		ld	h,(ix-17)
3535    124B  7D        		ld	a,l
3536    124C  C610      		add	a,16
3537    124E  6F        		ld	l,a
3538    124F  7C        		ld	a,h
3539    1250  CE00      		adc	a,0
3540    1252  67        		ld	h,a
3541    1253  DD75EE    		ld	(ix-18),l
3542    1256  DD74EF    		ld	(ix-17),h
3543                    	;  929          lastallz = allzero;
3544    1259  DD7EF8    		ld	a,(ix-8)
3545    125C  DD77F2    		ld	(ix-14),a
3546    125F  DD7EF9    		ld	a,(ix-7)
3547    1262  DD77F3    		ld	(ix-13),a
3548                    	;  930          }
3549    1265  DD34F6    		inc	(ix-10)
3550    1268  2003      		jr	nz,L26
3551    126A  DD34F7    		inc	(ix-9)
3552                    	L26:
3553    126D  C30F11    		jp	L1171
3554                    	L1271:
3555                    	;  931      }
3556    1270  C30000    		jp	c.rets
3557                    	L542:
3558    1273  25        		.byte	37
3559    1274  30        		.byte	48
3560    1275  32        		.byte	50
3561    1276  78        		.byte	120
3562    1277  25        		.byte	37
3563    1278  30        		.byte	48
3564    1279  32        		.byte	50
3565    127A  78        		.byte	120
3566    127B  25        		.byte	37
3567    127C  30        		.byte	48
3568    127D  32        		.byte	50
3569    127E  78        		.byte	120
3570    127F  25        		.byte	37
3571    1280  30        		.byte	48
3572    1281  32        		.byte	50
3573    1282  78        		.byte	120
3574    1283  2D        		.byte	45
3575    1284  00        		.byte	0
3576                    	L552:
3577    1285  25        		.byte	37
3578    1286  30        		.byte	48
3579    1287  32        		.byte	50
3580    1288  78        		.byte	120
3581    1289  25        		.byte	37
3582    128A  30        		.byte	48
3583    128B  32        		.byte	50
3584    128C  78        		.byte	120
3585    128D  2D        		.byte	45
3586    128E  00        		.byte	0
3587                    	L562:
3588    128F  25        		.byte	37
3589    1290  30        		.byte	48
3590    1291  32        		.byte	50
3591    1292  78        		.byte	120
3592    1293  25        		.byte	37
3593    1294  30        		.byte	48
3594    1295  32        		.byte	50
3595    1296  78        		.byte	120
3596    1297  2D        		.byte	45
3597    1298  00        		.byte	0
3598                    	L572:
3599    1299  25        		.byte	37
3600    129A  30        		.byte	48
3601    129B  32        		.byte	50
3602    129C  78        		.byte	120
3603    129D  25        		.byte	37
3604    129E  30        		.byte	48
3605    129F  32        		.byte	50
3606    12A0  78        		.byte	120
3607    12A1  2D        		.byte	45
3608    12A2  00        		.byte	0
3609                    	L503:
3610    12A3  25        		.byte	37
3611    12A4  30        		.byte	48
3612    12A5  32        		.byte	50
3613    12A6  78        		.byte	120
3614    12A7  25        		.byte	37
3615    12A8  30        		.byte	48
3616    12A9  32        		.byte	50
3617    12AA  78        		.byte	120
3618    12AB  25        		.byte	37
3619    12AC  30        		.byte	48
3620    12AD  32        		.byte	50
3621    12AE  78        		.byte	120
3622    12AF  25        		.byte	37
3623    12B0  30        		.byte	48
3624    12B1  32        		.byte	50
3625    12B2  78        		.byte	120
3626    12B3  25        		.byte	37
3627    12B4  30        		.byte	48
3628    12B5  32        		.byte	50
3629    12B6  78        		.byte	120
3630    12B7  25        		.byte	37
3631    12B8  30        		.byte	48
3632    12B9  32        		.byte	50
3633    12BA  78        		.byte	120
3634    12BB  00        		.byte	0
3635                    	L513:
3636    12BC  0A        		.byte	10
3637    12BD  20        		.byte	32
3638    12BE  20        		.byte	32
3639    12BF  5B        		.byte	91
3640    12C0  00        		.byte	0
3641                    	L523:
3642    12C1  25        		.byte	37
3643    12C2  30        		.byte	48
3644    12C3  32        		.byte	50
3645    12C4  78        		.byte	120
3646    12C5  20        		.byte	32
3647    12C6  00        		.byte	0
3648                    	L533:
3649    12C7  08        		.byte	8
3650    12C8  5D        		.byte	93
3651    12C9  00        		.byte	0
3652                    	;  932  
3653                    	;  933  /* print GUID (mixed endian format) */
3654                    	;  934  void prtguid(unsigned char *guidptr)
3655                    	;  935      {
3656                    	_prtguid:
3657    12CA  CD0000    		call	c.savs
3658    12CD  F5        		push	af
3659    12CE  F5        		push	af
3660    12CF  F5        		push	af
3661    12D0  F5        		push	af
3662                    	;  936      int index;
3663                    	;  937  
3664                    	;  938      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
3665    12D1  DD6E04    		ld	l,(ix+4)
3666    12D4  DD6605    		ld	h,(ix+5)
3667    12D7  4E        		ld	c,(hl)
3668    12D8  97        		sub	a
3669    12D9  47        		ld	b,a
3670    12DA  C5        		push	bc
3671    12DB  DD6E04    		ld	l,(ix+4)
3672    12DE  DD6605    		ld	h,(ix+5)
3673    12E1  23        		inc	hl
3674    12E2  4E        		ld	c,(hl)
3675    12E3  97        		sub	a
3676    12E4  47        		ld	b,a
3677    12E5  C5        		push	bc
3678    12E6  DD6E04    		ld	l,(ix+4)
3679    12E9  DD6605    		ld	h,(ix+5)
3680    12EC  23        		inc	hl
3681    12ED  23        		inc	hl
3682    12EE  4E        		ld	c,(hl)
3683    12EF  97        		sub	a
3684    12F0  47        		ld	b,a
3685    12F1  C5        		push	bc
3686    12F2  DD6E04    		ld	l,(ix+4)
3687    12F5  DD6605    		ld	h,(ix+5)
3688    12F8  23        		inc	hl
3689    12F9  23        		inc	hl
3690    12FA  23        		inc	hl
3691    12FB  4E        		ld	c,(hl)
3692    12FC  97        		sub	a
3693    12FD  47        		ld	b,a
3694    12FE  C5        		push	bc
3695    12FF  217312    		ld	hl,L542
3696    1302  CD0000    		call	_printf
3697    1305  F1        		pop	af
3698    1306  F1        		pop	af
3699    1307  F1        		pop	af
3700    1308  F1        		pop	af
3701                    	;  939      printf("%02x%02x-", guidptr[5], guidptr[4]);
3702    1309  DD6E04    		ld	l,(ix+4)
3703    130C  DD6605    		ld	h,(ix+5)
3704    130F  23        		inc	hl
3705    1310  23        		inc	hl
3706    1311  23        		inc	hl
3707    1312  23        		inc	hl
3708    1313  4E        		ld	c,(hl)
3709    1314  97        		sub	a
3710    1315  47        		ld	b,a
3711    1316  C5        		push	bc
3712    1317  DD6E04    		ld	l,(ix+4)
3713    131A  DD6605    		ld	h,(ix+5)
3714    131D  010500    		ld	bc,5
3715    1320  09        		add	hl,bc
3716    1321  4E        		ld	c,(hl)
3717    1322  97        		sub	a
3718    1323  47        		ld	b,a
3719    1324  C5        		push	bc
3720    1325  218512    		ld	hl,L552
3721    1328  CD0000    		call	_printf
3722    132B  F1        		pop	af
3723    132C  F1        		pop	af
3724                    	;  940      printf("%02x%02x-", guidptr[7], guidptr[6]);
3725    132D  DD6E04    		ld	l,(ix+4)
3726    1330  DD6605    		ld	h,(ix+5)
3727    1333  010600    		ld	bc,6
3728    1336  09        		add	hl,bc
3729    1337  4E        		ld	c,(hl)
3730    1338  97        		sub	a
3731    1339  47        		ld	b,a
3732    133A  C5        		push	bc
3733    133B  DD6E04    		ld	l,(ix+4)
3734    133E  DD6605    		ld	h,(ix+5)
3735    1341  010700    		ld	bc,7
3736    1344  09        		add	hl,bc
3737    1345  4E        		ld	c,(hl)
3738    1346  97        		sub	a
3739    1347  47        		ld	b,a
3740    1348  C5        		push	bc
3741    1349  218F12    		ld	hl,L562
3742    134C  CD0000    		call	_printf
3743    134F  F1        		pop	af
3744    1350  F1        		pop	af
3745                    	;  941      printf("%02x%02x-", guidptr[8], guidptr[9]);
3746    1351  DD6E04    		ld	l,(ix+4)
3747    1354  DD6605    		ld	h,(ix+5)
3748    1357  010900    		ld	bc,9
3749    135A  09        		add	hl,bc
3750    135B  4E        		ld	c,(hl)
3751    135C  97        		sub	a
3752    135D  47        		ld	b,a
3753    135E  C5        		push	bc
3754    135F  DD6E04    		ld	l,(ix+4)
3755    1362  DD6605    		ld	h,(ix+5)
3756    1365  010800    		ld	bc,8
3757    1368  09        		add	hl,bc
3758    1369  4E        		ld	c,(hl)
3759    136A  97        		sub	a
3760    136B  47        		ld	b,a
3761    136C  C5        		push	bc
3762    136D  219912    		ld	hl,L572
3763    1370  CD0000    		call	_printf
3764    1373  F1        		pop	af
3765    1374  F1        		pop	af
3766                    	;  942      printf("%02x%02x%02x%02x%02x%02x",
3767                    	;  943             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
3768    1375  DD6E04    		ld	l,(ix+4)
3769    1378  DD6605    		ld	h,(ix+5)
3770    137B  010F00    		ld	bc,15
3771    137E  09        		add	hl,bc
3772    137F  4E        		ld	c,(hl)
3773    1380  97        		sub	a
3774    1381  47        		ld	b,a
3775    1382  C5        		push	bc
3776    1383  DD6E04    		ld	l,(ix+4)
3777    1386  DD6605    		ld	h,(ix+5)
3778    1389  010E00    		ld	bc,14
3779    138C  09        		add	hl,bc
3780    138D  4E        		ld	c,(hl)
3781    138E  97        		sub	a
3782    138F  47        		ld	b,a
3783    1390  C5        		push	bc
3784    1391  DD6E04    		ld	l,(ix+4)
3785    1394  DD6605    		ld	h,(ix+5)
3786    1397  010D00    		ld	bc,13
3787    139A  09        		add	hl,bc
3788    139B  4E        		ld	c,(hl)
3789    139C  97        		sub	a
3790    139D  47        		ld	b,a
3791    139E  C5        		push	bc
3792    139F  DD6E04    		ld	l,(ix+4)
3793    13A2  DD6605    		ld	h,(ix+5)
3794    13A5  010C00    		ld	bc,12
3795    13A8  09        		add	hl,bc
3796    13A9  4E        		ld	c,(hl)
3797    13AA  97        		sub	a
3798    13AB  47        		ld	b,a
3799    13AC  C5        		push	bc
3800    13AD  DD6E04    		ld	l,(ix+4)
3801    13B0  DD6605    		ld	h,(ix+5)
3802    13B3  010B00    		ld	bc,11
3803    13B6  09        		add	hl,bc
3804    13B7  4E        		ld	c,(hl)
3805    13B8  97        		sub	a
3806    13B9  47        		ld	b,a
3807    13BA  C5        		push	bc
3808    13BB  DD6E04    		ld	l,(ix+4)
3809    13BE  DD6605    		ld	h,(ix+5)
3810    13C1  010A00    		ld	bc,10
3811    13C4  09        		add	hl,bc
3812    13C5  4E        		ld	c,(hl)
3813    13C6  97        		sub	a
3814    13C7  47        		ld	b,a
3815    13C8  C5        		push	bc
3816    13C9  21A312    		ld	hl,L503
3817    13CC  CD0000    		call	_printf
3818    13CF  210C00    		ld	hl,12
3819    13D2  39        		add	hl,sp
3820    13D3  F9        		ld	sp,hl
3821                    	;  944      printf("\n  [");
3822    13D4  21BC12    		ld	hl,L513
3823    13D7  CD0000    		call	_printf
3824                    	;  945      for (index = 0; index < 16; index++)
3825    13DA  DD36F800  		ld	(ix-8),0
3826    13DE  DD36F900  		ld	(ix-7),0
3827                    	L1712:
3828    13E2  DD7EF8    		ld	a,(ix-8)
3829    13E5  D610      		sub	16
3830    13E7  DD7EF9    		ld	a,(ix-7)
3831    13EA  DE00      		sbc	a,0
3832    13EC  F21114    		jp	p,L1022
3833                    	;  946          printf("%02x ", guidptr[index]);
3834    13EF  DD6E04    		ld	l,(ix+4)
3835    13F2  DD6605    		ld	h,(ix+5)
3836    13F5  DD4EF8    		ld	c,(ix-8)
3837    13F8  DD46F9    		ld	b,(ix-7)
3838    13FB  09        		add	hl,bc
3839    13FC  4E        		ld	c,(hl)
3840    13FD  97        		sub	a
3841    13FE  47        		ld	b,a
3842    13FF  C5        		push	bc
3843    1400  21C112    		ld	hl,L523
3844    1403  CD0000    		call	_printf
3845    1406  F1        		pop	af
3846    1407  DD34F8    		inc	(ix-8)
3847    140A  2003      		jr	nz,L47
3848    140C  DD34F9    		inc	(ix-7)
3849                    	L47:
3850    140F  18D1      		jr	L1712
3851                    	L1022:
3852                    	;  947      printf("\b]");
3853    1411  21C712    		ld	hl,L533
3854    1414  CD0000    		call	_printf
3855                    	;  948      }
3856    1417  C30000    		jp	c.rets
3857                    	L543:
3858    141A  43        		.byte	67
3859    141B  61        		.byte	97
3860    141C  6E        		.byte	110
3861    141D  27        		.byte	39
3862    141E  74        		.byte	116
3863    141F  20        		.byte	32
3864    1420  72        		.byte	114
3865    1421  65        		.byte	101
3866    1422  61        		.byte	97
3867    1423  64        		.byte	100
3868    1424  20        		.byte	32
3869    1425  47        		.byte	71
3870    1426  50        		.byte	80
3871    1427  54        		.byte	84
3872    1428  20        		.byte	32
3873    1429  65        		.byte	101
3874    142A  6E        		.byte	110
3875    142B  74        		.byte	116
3876    142C  72        		.byte	114
3877    142D  79        		.byte	121
3878    142E  20        		.byte	32
3879    142F  62        		.byte	98
3880    1430  6C        		.byte	108
3881    1431  6F        		.byte	111
3882    1432  63        		.byte	99
3883    1433  6B        		.byte	107
3884    1434  0A        		.byte	10
3885    1435  00        		.byte	0
3886                    	L553:
3887    1436  47        		.byte	71
3888    1437  50        		.byte	80
3889    1438  54        		.byte	84
3890    1439  20        		.byte	32
3891    143A  70        		.byte	112
3892    143B  61        		.byte	97
3893    143C  72        		.byte	114
3894    143D  74        		.byte	116
3895    143E  69        		.byte	105
3896    143F  74        		.byte	116
3897    1440  69        		.byte	105
3898    1441  6F        		.byte	111
3899    1442  6E        		.byte	110
3900    1443  20        		.byte	32
3901    1444  65        		.byte	101
3902    1445  6E        		.byte	110
3903    1446  74        		.byte	116
3904    1447  72        		.byte	114
3905    1448  79        		.byte	121
3906    1449  20        		.byte	32
3907    144A  25        		.byte	37
3908    144B  64        		.byte	100
3909    144C  3A        		.byte	58
3910    144D  00        		.byte	0
3911                    	L563:
3912    144E  20        		.byte	32
3913    144F  4E        		.byte	78
3914    1450  6F        		.byte	111
3915    1451  74        		.byte	116
3916    1452  20        		.byte	32
3917    1453  75        		.byte	117
3918    1454  73        		.byte	115
3919    1455  65        		.byte	101
3920    1456  64        		.byte	100
3921    1457  20        		.byte	32
3922    1458  65        		.byte	101
3923    1459  6E        		.byte	110
3924    145A  74        		.byte	116
3925    145B  72        		.byte	114
3926    145C  79        		.byte	121
3927    145D  0A        		.byte	10
3928    145E  00        		.byte	0
3929                    	L573:
3930    145F  0A        		.byte	10
3931    1460  20        		.byte	32
3932    1461  20        		.byte	32
3933    1462  50        		.byte	80
3934    1463  61        		.byte	97
3935    1464  72        		.byte	114
3936    1465  74        		.byte	116
3937    1466  69        		.byte	105
3938    1467  74        		.byte	116
3939    1468  69        		.byte	105
3940    1469  6F        		.byte	111
3941    146A  6E        		.byte	110
3942    146B  20        		.byte	32
3943    146C  74        		.byte	116
3944    146D  79        		.byte	121
3945    146E  70        		.byte	112
3946    146F  65        		.byte	101
3947    1470  20        		.byte	32
3948    1471  47        		.byte	71
3949    1472  55        		.byte	85
3950    1473  49        		.byte	73
3951    1474  44        		.byte	68
3952    1475  3A        		.byte	58
3953    1476  20        		.byte	32
3954    1477  00        		.byte	0
3955                    	L504:
3956    1478  0A        		.byte	10
3957    1479  20        		.byte	32
3958    147A  20        		.byte	32
3959    147B  55        		.byte	85
3960    147C  6E        		.byte	110
3961    147D  69        		.byte	105
3962    147E  71        		.byte	113
3963    147F  75        		.byte	117
3964    1480  65        		.byte	101
3965    1481  20        		.byte	32
3966    1482  70        		.byte	112
3967    1483  61        		.byte	97
3968    1484  72        		.byte	114
3969    1485  74        		.byte	116
3970    1486  69        		.byte	105
3971    1487  74        		.byte	116
3972    1488  69        		.byte	105
3973    1489  6F        		.byte	111
3974    148A  6E        		.byte	110
3975    148B  20        		.byte	32
3976    148C  47        		.byte	71
3977    148D  55        		.byte	85
3978    148E  49        		.byte	73
3979    148F  44        		.byte	68
3980    1490  3A        		.byte	58
3981    1491  20        		.byte	32
3982    1492  00        		.byte	0
3983                    	L514:
3984    1493  0A        		.byte	10
3985    1494  20        		.byte	32
3986    1495  20        		.byte	32
3987    1496  46        		.byte	70
3988    1497  69        		.byte	105
3989    1498  72        		.byte	114
3990    1499  73        		.byte	115
3991    149A  74        		.byte	116
3992    149B  20        		.byte	32
3993    149C  4C        		.byte	76
3994    149D  42        		.byte	66
3995    149E  41        		.byte	65
3996    149F  3A        		.byte	58
3997    14A0  20        		.byte	32
3998    14A1  00        		.byte	0
3999                    	L524:
4000    14A2  25        		.byte	37
4001    14A3  6C        		.byte	108
4002    14A4  75        		.byte	117
4003    14A5  00        		.byte	0
4004                    	L534:
4005    14A6  20        		.byte	32
4006    14A7  5B        		.byte	91
4007    14A8  00        		.byte	0
4008                    	L544:
4009    14A9  25        		.byte	37
4010    14AA  30        		.byte	48
4011    14AB  32        		.byte	50
4012    14AC  78        		.byte	120
4013    14AD  20        		.byte	32
4014    14AE  00        		.byte	0
4015                    	L554:
4016    14AF  08        		.byte	8
4017    14B0  5D        		.byte	93
4018    14B1  00        		.byte	0
4019                    	L564:
4020    14B2  0A        		.byte	10
4021    14B3  20        		.byte	32
4022    14B4  20        		.byte	32
4023    14B5  4C        		.byte	76
4024    14B6  61        		.byte	97
4025    14B7  73        		.byte	115
4026    14B8  74        		.byte	116
4027    14B9  20        		.byte	32
4028    14BA  4C        		.byte	76
4029    14BB  42        		.byte	66
4030    14BC  41        		.byte	65
4031    14BD  3A        		.byte	58
4032    14BE  20        		.byte	32
4033    14BF  00        		.byte	0
4034                    	L574:
4035    14C0  25        		.byte	37
4036    14C1  6C        		.byte	108
4037    14C2  75        		.byte	117
4038    14C3  2C        		.byte	44
4039    14C4  20        		.byte	32
4040    14C5  73        		.byte	115
4041    14C6  69        		.byte	105
4042    14C7  7A        		.byte	122
4043    14C8  65        		.byte	101
4044    14C9  20        		.byte	32
4045    14CA  25        		.byte	37
4046    14CB  6C        		.byte	108
4047    14CC  75        		.byte	117
4048    14CD  20        		.byte	32
4049    14CE  4D        		.byte	77
4050    14CF  42        		.byte	66
4051    14D0  79        		.byte	121
4052    14D1  74        		.byte	116
4053    14D2  65        		.byte	101
4054    14D3  00        		.byte	0
4055                    	L505:
4056    14D4  20        		.byte	32
4057    14D5  5B        		.byte	91
4058    14D6  00        		.byte	0
4059                    	L515:
4060    14D7  25        		.byte	37
4061    14D8  30        		.byte	48
4062    14D9  32        		.byte	50
4063    14DA  78        		.byte	120
4064    14DB  20        		.byte	32
4065    14DC  00        		.byte	0
4066                    	L525:
4067    14DD  08        		.byte	8
4068    14DE  5D        		.byte	93
4069    14DF  00        		.byte	0
4070                    	L535:
4071    14E0  0A        		.byte	10
4072    14E1  20        		.byte	32
4073    14E2  20        		.byte	32
4074    14E3  41        		.byte	65
4075    14E4  74        		.byte	116
4076    14E5  74        		.byte	116
4077    14E6  72        		.byte	114
4078    14E7  69        		.byte	105
4079    14E8  62        		.byte	98
4080    14E9  75        		.byte	117
4081    14EA  74        		.byte	116
4082    14EB  65        		.byte	101
4083    14EC  20        		.byte	32
4084    14ED  66        		.byte	102
4085    14EE  6C        		.byte	108
4086    14EF  61        		.byte	97
4087    14F0  67        		.byte	103
4088    14F1  73        		.byte	115
4089    14F2  3A        		.byte	58
4090    14F3  20        		.byte	32
4091    14F4  5B        		.byte	91
4092    14F5  00        		.byte	0
4093                    	L545:
4094    14F6  25        		.byte	37
4095    14F7  30        		.byte	48
   0    14F8  32        		.byte	50
   1    14F9  78        		.byte	120
   2    14FA  20        		.byte	32
   3    14FB  00        		.byte	0
   4                    	L555:
   5    14FC  08        		.byte	8
   6    14FD  5D        		.byte	93
   7    14FE  0A        		.byte	10
   8    14FF  20        		.byte	32
   9    1500  20        		.byte	32
  10    1501  50        		.byte	80
  11    1502  61        		.byte	97
  12    1503  72        		.byte	114
  13    1504  74        		.byte	116
  14    1505  69        		.byte	105
  15    1506  74        		.byte	116
  16    1507  69        		.byte	105
  17    1508  6F        		.byte	111
  18    1509  6E        		.byte	110
  19    150A  20        		.byte	32
  20    150B  6E        		.byte	110
  21    150C  61        		.byte	97
  22    150D  6D        		.byte	109
  23    150E  65        		.byte	101
  24    150F  3A        		.byte	58
  25    1510  20        		.byte	32
  26    1511  20        		.byte	32
  27    1512  00        		.byte	0
  28                    	L565:
  29    1513  6E        		.byte	110
  30    1514  61        		.byte	97
  31    1515  6D        		.byte	109
  32    1516  65        		.byte	101
  33    1517  20        		.byte	32
  34    1518  66        		.byte	102
  35    1519  69        		.byte	105
  36    151A  65        		.byte	101
  37    151B  6C        		.byte	108
  38    151C  64        		.byte	100
  39    151D  20        		.byte	32
  40    151E  65        		.byte	101
  41    151F  6D        		.byte	109
  42    1520  70        		.byte	112
  43    1521  74        		.byte	116
  44    1522  79        		.byte	121
  45    1523  00        		.byte	0
  46                    	L575:
  47    1524  0A        		.byte	10
  48    1525  00        		.byte	0
  49                    	L506:
  50    1526  20        		.byte	32
  51    1527  20        		.byte	32
  52    1528  20        		.byte	32
  53    1529  5B        		.byte	91
  54    152A  00        		.byte	0
  55                    	L516:
  56    152B  0A        		.byte	10
  57    152C  20        		.byte	32
  58    152D  20        		.byte	32
  59    152E  20        		.byte	32
  60    152F  20        		.byte	32
  61    1530  00        		.byte	0
  62                    	L526:
  63    1531  25        		.byte	37
  64    1532  30        		.byte	48
  65    1533  32        		.byte	50
  66    1534  78        		.byte	120
  67    1535  20        		.byte	32
  68    1536  00        		.byte	0
  69                    	L536:
  70    1537  08        		.byte	8
  71    1538  5D        		.byte	93
  72    1539  0A        		.byte	10
  73    153A  00        		.byte	0
  74                    	;  949  
  75                    	;  950  /* print GPT entry */
  76                    	;  951  void prtgptent(unsigned int entryno)
  77                    	;  952      {
  78                    	_prtgptent:
  79    153B  CD0000    		call	c.savs
  80    153E  21E4FF    		ld	hl,65508
  81    1541  39        		add	hl,sp
  82    1542  F9        		ld	sp,hl
  83                    	;  953      int index;
  84                    	;  954      int entryidx;
  85                    	;  955      int hasname;
  86                    	;  956      unsigned int block;
  87                    	;  957      unsigned char *rxdata;
  88                    	;  958      unsigned char *entryptr;
  89                    	;  959      unsigned char tstzero = 0;
  90    1543  DD36ED00  		ld	(ix-19),0
  91                    	;  960      unsigned long flba;
  92                    	;  961      unsigned long llba;
  93                    	;  962  
  94                    	;  963      block = 2 + (entryno / 4);
  95    1547  DD6E04    		ld	l,(ix+4)
  96    154A  DD6605    		ld	h,(ix+5)
  97    154D  E5        		push	hl
  98    154E  210400    		ld	hl,4
  99    1551  E5        		push	hl
 100    1552  CD0000    		call	c.udiv
 101    1555  E1        		pop	hl
 102    1556  23        		inc	hl
 103    1557  23        		inc	hl
 104    1558  DD75F2    		ld	(ix-14),l
 105    155B  DD74F3    		ld	(ix-13),h
 106                    	;  964      if ((curblkno != block) || !curblkok)
 107    155E  210000    		ld	hl,_curblkno
 108    1561  E5        		push	hl
 109    1562  DDE5      		push	ix
 110    1564  C1        		pop	bc
 111    1565  21F2FF    		ld	hl,65522
 112    1568  09        		add	hl,bc
 113    1569  4D        		ld	c,l
 114    156A  44        		ld	b,h
 115    156B  97        		sub	a
 116    156C  320000    		ld	(c.r0),a
 117    156F  320100    		ld	(c.r0+1),a
 118    1572  0A        		ld	a,(bc)
 119    1573  320200    		ld	(c.r0+2),a
 120    1576  03        		inc	bc
 121    1577  0A        		ld	a,(bc)
 122    1578  320300    		ld	(c.r0+3),a
 123    157B  210000    		ld	hl,c.r0
 124    157E  E5        		push	hl
 125    157F  CD0000    		call	c.lcmp
 126    1582  2008      		jr	nz,L1422
 127    1584  2A0C00    		ld	hl,(_curblkok)
 128    1587  7C        		ld	a,h
 129    1588  B5        		or	l
 130    1589  C2DF15    		jp	nz,L1322
 131                    	L1422:
 132                    	;  965          {
 133                    	;  966          if (!sdread(sdrdbuf, block))
 134    158C  DDE5      		push	ix
 135    158E  C1        		pop	bc
 136    158F  21F2FF    		ld	hl,65522
 137    1592  09        		add	hl,bc
 138    1593  4D        		ld	c,l
 139    1594  44        		ld	b,h
 140    1595  97        		sub	a
 141    1596  320000    		ld	(c.r0),a
 142    1599  320100    		ld	(c.r0+1),a
 143    159C  0A        		ld	a,(bc)
 144    159D  320200    		ld	(c.r0+2),a
 145    15A0  03        		inc	bc
 146    15A1  0A        		ld	a,(bc)
 147    15A2  320300    		ld	(c.r0+3),a
 148    15A5  210300    		ld	hl,c.r0+3
 149    15A8  46        		ld	b,(hl)
 150    15A9  2B        		dec	hl
 151    15AA  4E        		ld	c,(hl)
 152    15AB  C5        		push	bc
 153    15AC  2B        		dec	hl
 154    15AD  46        		ld	b,(hl)
 155    15AE  2B        		dec	hl
 156    15AF  4E        		ld	c,(hl)
 157    15B0  C5        		push	bc
 158    15B1  213200    		ld	hl,_sdrdbuf
 159    15B4  CDE10C    		call	_sdread
 160    15B7  F1        		pop	af
 161    15B8  F1        		pop	af
 162    15B9  79        		ld	a,c
 163    15BA  B0        		or	b
 164    15BB  2009      		jr	nz,L1522
 165                    	;  967              {
 166                    	;  968              printf("Can't read GPT entry block\n");
 167    15BD  211A14    		ld	hl,L543
 168    15C0  CD0000    		call	_printf
 169                    	;  969              return;
 170    15C3  C30000    		jp	c.rets
 171                    	L1522:
 172                    	;  970              }
 173                    	;  971          curblkno = block;
 174    15C6  97        		sub	a
 175    15C7  320000    		ld	(_curblkno),a
 176    15CA  320100    		ld	(_curblkno+1),a
 177    15CD  DD7EF2    		ld	a,(ix-14)
 178    15D0  320200    		ld	(_curblkno+2),a
 179                    	;  972          curblkok = YES;
 180    15D3  210100    		ld	hl,1
 181    15D6  DD7EF3    		ld	a,(ix-13)
 182    15D9  320300    		ld	(_curblkno+3),a
 183    15DC  220C00    		ld	(_curblkok),hl
 184                    	L1322:
 185                    	;  973          }
 186                    	;  974      rxdata = sdrdbuf;
 187    15DF  213200    		ld	hl,_sdrdbuf
 188    15E2  DD75F0    		ld	(ix-16),l
 189    15E5  DD74F1    		ld	(ix-15),h
 190                    	;  975      entryptr = rxdata + (128 * (entryno % 4));
 191    15E8  DD6E04    		ld	l,(ix+4)
 192    15EB  DD6605    		ld	h,(ix+5)
 193    15EE  E5        		push	hl
 194    15EF  210400    		ld	hl,4
 195    15F2  E5        		push	hl
 196    15F3  CD0000    		call	c.umod
 197    15F6  218000    		ld	hl,128
 198    15F9  E5        		push	hl
 199    15FA  CD0000    		call	c.imul
 200    15FD  E1        		pop	hl
 201    15FE  DD4EF0    		ld	c,(ix-16)
 202    1601  DD46F1    		ld	b,(ix-15)
 203    1604  09        		add	hl,bc
 204    1605  DD75EE    		ld	(ix-18),l
 205    1608  DD74EF    		ld	(ix-17),h
 206                    	;  976      for (index = 0; index < 16; index++)
 207    160B  DD36F800  		ld	(ix-8),0
 208    160F  DD36F900  		ld	(ix-7),0
 209                    	L1622:
 210    1613  DD7EF8    		ld	a,(ix-8)
 211    1616  D610      		sub	16
 212    1618  DD7EF9    		ld	a,(ix-7)
 213    161B  DE00      		sbc	a,0
 214    161D  F23E16    		jp	p,L1722
 215                    	;  977          tstzero |= entryptr[index];
 216    1620  DD6EEE    		ld	l,(ix-18)
 217    1623  DD66EF    		ld	h,(ix-17)
 218    1626  DD4EF8    		ld	c,(ix-8)
 219    1629  DD46F9    		ld	b,(ix-7)
 220    162C  09        		add	hl,bc
 221    162D  DD7EED    		ld	a,(ix-19)
 222    1630  B6        		or	(hl)
 223    1631  DD77ED    		ld	(ix-19),a
 224    1634  DD34F8    		inc	(ix-8)
 225    1637  2003      		jr	nz,L001
 226    1639  DD34F9    		inc	(ix-7)
 227                    	L001:
 228    163C  18D5      		jr	L1622
 229                    	L1722:
 230                    	;  978      printf("GPT partition entry %d:", entryno + 1);
 231    163E  DD6E04    		ld	l,(ix+4)
 232    1641  DD6605    		ld	h,(ix+5)
 233    1644  23        		inc	hl
 234    1645  E5        		push	hl
 235    1646  213614    		ld	hl,L553
 236    1649  CD0000    		call	_printf
 237    164C  F1        		pop	af
 238                    	;  979      if (!tstzero)
 239    164D  DD7EED    		ld	a,(ix-19)
 240    1650  B7        		or	a
 241    1651  2009      		jr	nz,L1232
 242                    	;  980          {
 243                    	;  981          printf(" Not used entry\n");
 244    1653  214E14    		ld	hl,L563
 245    1656  CD0000    		call	_printf
 246                    	;  982          return;
 247    1659  C30000    		jp	c.rets
 248                    	L1232:
 249                    	;  983          }
 250                    	;  984      printf("\n  Partition type GUID: ");
 251    165C  215F14    		ld	hl,L573
 252    165F  CD0000    		call	_printf
 253                    	;  985      prtguid(entryptr);
 254    1662  DD6EEE    		ld	l,(ix-18)
 255    1665  DD66EF    		ld	h,(ix-17)
 256    1668  CDCA12    		call	_prtguid
 257                    	;  986      printf("\n  Unique partition GUID: ");
 258    166B  217814    		ld	hl,L504
 259    166E  CD0000    		call	_printf
 260                    	;  987      prtguid(entryptr + 16);
 261    1671  DD6EEE    		ld	l,(ix-18)
 262    1674  DD66EF    		ld	h,(ix-17)
 263    1677  011000    		ld	bc,16
 264    167A  09        		add	hl,bc
 265    167B  CDCA12    		call	_prtguid
 266                    	;  988      printf("\n  First LBA: ");
 267    167E  219314    		ld	hl,L514
 268    1681  CD0000    		call	_printf
 269                    	;  989      /* lower 32 bits of LBA should be sufficient (I hope) */
 270                    	;  990      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
 271                    	;  991             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
 272    1684  DDE5      		push	ix
 273    1686  C1        		pop	bc
 274    1687  21E8FF    		ld	hl,65512
 275    168A  09        		add	hl,bc
 276    168B  E5        		push	hl
 277    168C  DD6EEE    		ld	l,(ix-18)
 278    168F  DD66EF    		ld	h,(ix-17)
 279    1692  012000    		ld	bc,32
 280    1695  09        		add	hl,bc
 281    1696  4D        		ld	c,l
 282    1697  44        		ld	b,h
 283    1698  97        		sub	a
 284    1699  320000    		ld	(c.r0),a
 285    169C  320100    		ld	(c.r0+1),a
 286    169F  0A        		ld	a,(bc)
 287    16A0  320200    		ld	(c.r0+2),a
 288    16A3  97        		sub	a
 289    16A4  320300    		ld	(c.r0+3),a
 290    16A7  210000    		ld	hl,c.r0
 291    16AA  E5        		push	hl
 292    16AB  DD6EEE    		ld	l,(ix-18)
 293    16AE  DD66EF    		ld	h,(ix-17)
 294    16B1  012100    		ld	bc,33
 295    16B4  09        		add	hl,bc
 296    16B5  4D        		ld	c,l
 297    16B6  44        		ld	b,h
 298    16B7  97        		sub	a
 299    16B8  320000    		ld	(c.r1),a
 300    16BB  320100    		ld	(c.r1+1),a
 301    16BE  0A        		ld	a,(bc)
 302    16BF  320200    		ld	(c.r1+2),a
 303    16C2  97        		sub	a
 304    16C3  320300    		ld	(c.r1+3),a
 305    16C6  210000    		ld	hl,c.r1
 306    16C9  E5        		push	hl
 307    16CA  210800    		ld	hl,8
 308    16CD  E5        		push	hl
 309    16CE  CD0000    		call	c.llsh
 310    16D1  CD0000    		call	c.ladd
 311    16D4  DD6EEE    		ld	l,(ix-18)
 312    16D7  DD66EF    		ld	h,(ix-17)
 313    16DA  012200    		ld	bc,34
 314    16DD  09        		add	hl,bc
 315    16DE  4D        		ld	c,l
 316    16DF  44        		ld	b,h
 317    16E0  97        		sub	a
 318    16E1  320000    		ld	(c.r1),a
 319    16E4  320100    		ld	(c.r1+1),a
 320    16E7  0A        		ld	a,(bc)
 321    16E8  320200    		ld	(c.r1+2),a
 322    16EB  97        		sub	a
 323    16EC  320300    		ld	(c.r1+3),a
 324    16EF  210000    		ld	hl,c.r1
 325    16F2  E5        		push	hl
 326    16F3  211000    		ld	hl,16
 327    16F6  E5        		push	hl
 328    16F7  CD0000    		call	c.llsh
 329    16FA  CD0000    		call	c.ladd
 330    16FD  DD6EEE    		ld	l,(ix-18)
 331    1700  DD66EF    		ld	h,(ix-17)
 332    1703  012300    		ld	bc,35
 333    1706  09        		add	hl,bc
 334    1707  4D        		ld	c,l
 335    1708  44        		ld	b,h
 336    1709  97        		sub	a
 337    170A  320000    		ld	(c.r1),a
 338    170D  320100    		ld	(c.r1+1),a
 339    1710  0A        		ld	a,(bc)
 340    1711  320200    		ld	(c.r1+2),a
 341    1714  97        		sub	a
 342    1715  320300    		ld	(c.r1+3),a
 343    1718  210000    		ld	hl,c.r1
 344    171B  E5        		push	hl
 345    171C  211800    		ld	hl,24
 346    171F  E5        		push	hl
 347    1720  CD0000    		call	c.llsh
 348    1723  CD0000    		call	c.ladd
 349    1726  CD0000    		call	c.mvl
 350    1729  F1        		pop	af
 351                    	;  992      printf("%lu", flba);
 352    172A  DD66EB    		ld	h,(ix-21)
 353    172D  DD6EEA    		ld	l,(ix-22)
 354    1730  E5        		push	hl
 355    1731  DD66E9    		ld	h,(ix-23)
 356    1734  DD6EE8    		ld	l,(ix-24)
 357    1737  E5        		push	hl
 358    1738  21A214    		ld	hl,L524
 359    173B  CD0000    		call	_printf
 360    173E  F1        		pop	af
 361    173F  F1        		pop	af
 362                    	;  993      printf(" [");
 363    1740  21A614    		ld	hl,L534
 364    1743  CD0000    		call	_printf
 365                    	;  994      for (index = 32; index < (32 + 8); index++)
 366    1746  DD36F820  		ld	(ix-8),32
 367    174A  DD36F900  		ld	(ix-7),0
 368                    	L1332:
 369    174E  DD7EF8    		ld	a,(ix-8)
 370    1751  D628      		sub	40
 371    1753  DD7EF9    		ld	a,(ix-7)
 372    1756  DE00      		sbc	a,0
 373    1758  F27D17    		jp	p,L1432
 374                    	;  995          printf("%02x ", entryptr[index]);
 375    175B  DD6EEE    		ld	l,(ix-18)
 376    175E  DD66EF    		ld	h,(ix-17)
 377    1761  DD4EF8    		ld	c,(ix-8)
 378    1764  DD46F9    		ld	b,(ix-7)
 379    1767  09        		add	hl,bc
 380    1768  4E        		ld	c,(hl)
 381    1769  97        		sub	a
 382    176A  47        		ld	b,a
 383    176B  C5        		push	bc
 384    176C  21A914    		ld	hl,L544
 385    176F  CD0000    		call	_printf
 386    1772  F1        		pop	af
 387    1773  DD34F8    		inc	(ix-8)
 388    1776  2003      		jr	nz,L201
 389    1778  DD34F9    		inc	(ix-7)
 390                    	L201:
 391    177B  18D1      		jr	L1332
 392                    	L1432:
 393                    	;  996      printf("\b]");
 394    177D  21AF14    		ld	hl,L554
 395    1780  CD0000    		call	_printf
 396                    	;  997      printf("\n  Last LBA: ");
 397    1783  21B214    		ld	hl,L564
 398    1786  CD0000    		call	_printf
 399                    	;  998      /* lower 32 bits of LBA should be sufficient (I hope) */
 400                    	;  999      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
 401                    	; 1000             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
 402    1789  DDE5      		push	ix
 403    178B  C1        		pop	bc
 404    178C  21E4FF    		ld	hl,65508
 405    178F  09        		add	hl,bc
 406    1790  E5        		push	hl
 407    1791  DD6EEE    		ld	l,(ix-18)
 408    1794  DD66EF    		ld	h,(ix-17)
 409    1797  012800    		ld	bc,40
 410    179A  09        		add	hl,bc
 411    179B  4D        		ld	c,l
 412    179C  44        		ld	b,h
 413    179D  97        		sub	a
 414    179E  320000    		ld	(c.r0),a
 415    17A1  320100    		ld	(c.r0+1),a
 416    17A4  0A        		ld	a,(bc)
 417    17A5  320200    		ld	(c.r0+2),a
 418    17A8  97        		sub	a
 419    17A9  320300    		ld	(c.r0+3),a
 420    17AC  210000    		ld	hl,c.r0
 421    17AF  E5        		push	hl
 422    17B0  DD6EEE    		ld	l,(ix-18)
 423    17B3  DD66EF    		ld	h,(ix-17)
 424    17B6  012900    		ld	bc,41
 425    17B9  09        		add	hl,bc
 426    17BA  4D        		ld	c,l
 427    17BB  44        		ld	b,h
 428    17BC  97        		sub	a
 429    17BD  320000    		ld	(c.r1),a
 430    17C0  320100    		ld	(c.r1+1),a
 431    17C3  0A        		ld	a,(bc)
 432    17C4  320200    		ld	(c.r1+2),a
 433    17C7  97        		sub	a
 434    17C8  320300    		ld	(c.r1+3),a
 435    17CB  210000    		ld	hl,c.r1
 436    17CE  E5        		push	hl
 437    17CF  210800    		ld	hl,8
 438    17D2  E5        		push	hl
 439    17D3  CD0000    		call	c.llsh
 440    17D6  CD0000    		call	c.ladd
 441    17D9  DD6EEE    		ld	l,(ix-18)
 442    17DC  DD66EF    		ld	h,(ix-17)
 443    17DF  012A00    		ld	bc,42
 444    17E2  09        		add	hl,bc
 445    17E3  4D        		ld	c,l
 446    17E4  44        		ld	b,h
 447    17E5  97        		sub	a
 448    17E6  320000    		ld	(c.r1),a
 449    17E9  320100    		ld	(c.r1+1),a
 450    17EC  0A        		ld	a,(bc)
 451    17ED  320200    		ld	(c.r1+2),a
 452    17F0  97        		sub	a
 453    17F1  320300    		ld	(c.r1+3),a
 454    17F4  210000    		ld	hl,c.r1
 455    17F7  E5        		push	hl
 456    17F8  211000    		ld	hl,16
 457    17FB  E5        		push	hl
 458    17FC  CD0000    		call	c.llsh
 459    17FF  CD0000    		call	c.ladd
 460    1802  DD6EEE    		ld	l,(ix-18)
 461    1805  DD66EF    		ld	h,(ix-17)
 462    1808  012B00    		ld	bc,43
 463    180B  09        		add	hl,bc
 464    180C  4D        		ld	c,l
 465    180D  44        		ld	b,h
 466    180E  97        		sub	a
 467    180F  320000    		ld	(c.r1),a
 468    1812  320100    		ld	(c.r1+1),a
 469    1815  0A        		ld	a,(bc)
 470    1816  320200    		ld	(c.r1+2),a
 471    1819  97        		sub	a
 472    181A  320300    		ld	(c.r1+3),a
 473    181D  210000    		ld	hl,c.r1
 474    1820  E5        		push	hl
 475    1821  211800    		ld	hl,24
 476    1824  E5        		push	hl
 477    1825  CD0000    		call	c.llsh
 478    1828  CD0000    		call	c.ladd
 479    182B  CD0000    		call	c.mvl
 480    182E  F1        		pop	af
 481                    	; 1001      printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
 482    182F  DDE5      		push	ix
 483    1831  C1        		pop	bc
 484    1832  21E4FF    		ld	hl,65508
 485    1835  09        		add	hl,bc
 486    1836  CD0000    		call	c.0mvf
 487    1839  210000    		ld	hl,c.r0
 488    183C  E5        		push	hl
 489    183D  DDE5      		push	ix
 490    183F  C1        		pop	bc
 491    1840  21E8FF    		ld	hl,65512
 492    1843  09        		add	hl,bc
 493    1844  E5        		push	hl
 494    1845  CD0000    		call	c.lsub
 495    1848  210B00    		ld	hl,11
 496    184B  E5        		push	hl
 497    184C  CD0000    		call	c.ulrsh
 498    184F  E1        		pop	hl
 499    1850  23        		inc	hl
 500    1851  23        		inc	hl
 501    1852  4E        		ld	c,(hl)
 502    1853  23        		inc	hl
 503    1854  46        		ld	b,(hl)
 504    1855  C5        		push	bc
 505    1856  2B        		dec	hl
 506    1857  2B        		dec	hl
 507    1858  2B        		dec	hl
 508    1859  4E        		ld	c,(hl)
 509    185A  23        		inc	hl
 510    185B  46        		ld	b,(hl)
 511    185C  C5        		push	bc
 512    185D  DD66E7    		ld	h,(ix-25)
 513    1860  DD6EE6    		ld	l,(ix-26)
 514    1863  E5        		push	hl
 515    1864  DD66E5    		ld	h,(ix-27)
 516    1867  DD6EE4    		ld	l,(ix-28)
 517    186A  E5        		push	hl
 518    186B  21C014    		ld	hl,L574
 519    186E  CD0000    		call	_printf
 520    1871  F1        		pop	af
 521    1872  F1        		pop	af
 522    1873  F1        		pop	af
 523    1874  F1        		pop	af
 524                    	; 1002      printf(" [");
 525    1875  21D414    		ld	hl,L505
 526    1878  CD0000    		call	_printf
 527                    	; 1003      for (index = 40; index < (40 + 8); index++)
 528    187B  DD36F828  		ld	(ix-8),40
 529    187F  DD36F900  		ld	(ix-7),0
 530                    	L1732:
 531    1883  DD7EF8    		ld	a,(ix-8)
 532    1886  D630      		sub	48
 533    1888  DD7EF9    		ld	a,(ix-7)
 534    188B  DE00      		sbc	a,0
 535    188D  F2B218    		jp	p,L1042
 536                    	; 1004          printf("%02x ", entryptr[index]);
 537    1890  DD6EEE    		ld	l,(ix-18)
 538    1893  DD66EF    		ld	h,(ix-17)
 539    1896  DD4EF8    		ld	c,(ix-8)
 540    1899  DD46F9    		ld	b,(ix-7)
 541    189C  09        		add	hl,bc
 542    189D  4E        		ld	c,(hl)
 543    189E  97        		sub	a
 544    189F  47        		ld	b,a
 545    18A0  C5        		push	bc
 546    18A1  21D714    		ld	hl,L515
 547    18A4  CD0000    		call	_printf
 548    18A7  F1        		pop	af
 549    18A8  DD34F8    		inc	(ix-8)
 550    18AB  2003      		jr	nz,L401
 551    18AD  DD34F9    		inc	(ix-7)
 552                    	L401:
 553    18B0  18D1      		jr	L1732
 554                    	L1042:
 555                    	; 1005      printf("\b]");
 556    18B2  21DD14    		ld	hl,L525
 557    18B5  CD0000    		call	_printf
 558                    	; 1006      printf("\n  Attribute flags: [");
 559    18B8  21E014    		ld	hl,L535
 560    18BB  CD0000    		call	_printf
 561                    	; 1007      /* bits 0 - 2 and 60 - 63 should be decoded */
 562                    	; 1008      for (index = 0; index < 8; index++)
 563    18BE  DD36F800  		ld	(ix-8),0
 564    18C2  DD36F900  		ld	(ix-7),0
 565                    	L1342:
 566    18C6  DD7EF8    		ld	a,(ix-8)
 567    18C9  D608      		sub	8
 568    18CB  DD7EF9    		ld	a,(ix-7)
 569    18CE  DE00      		sbc	a,0
 570    18D0  F20519    		jp	p,L1442
 571                    	; 1009          {
 572                    	; 1010          entryidx = index + 48;
 573    18D3  DD6EF8    		ld	l,(ix-8)
 574    18D6  DD66F9    		ld	h,(ix-7)
 575    18D9  013000    		ld	bc,48
 576    18DC  09        		add	hl,bc
 577    18DD  DD75F6    		ld	(ix-10),l
 578    18E0  DD74F7    		ld	(ix-9),h
 579                    	; 1011          printf("%02x ", entryptr[entryidx]);
 580    18E3  DD6EEE    		ld	l,(ix-18)
 581    18E6  DD66EF    		ld	h,(ix-17)
 582    18E9  DD4EF6    		ld	c,(ix-10)
 583    18EC  DD46F7    		ld	b,(ix-9)
 584    18EF  09        		add	hl,bc
 585    18F0  4E        		ld	c,(hl)
 586    18F1  97        		sub	a
 587    18F2  47        		ld	b,a
 588    18F3  C5        		push	bc
 589    18F4  21F614    		ld	hl,L545
 590    18F7  CD0000    		call	_printf
 591    18FA  F1        		pop	af
 592                    	; 1012          }
 593    18FB  DD34F8    		inc	(ix-8)
 594    18FE  2003      		jr	nz,L601
 595    1900  DD34F9    		inc	(ix-7)
 596                    	L601:
 597    1903  18C1      		jr	L1342
 598                    	L1442:
 599                    	; 1013      printf("\b]\n  Partition name:  ");
 600    1905  21FC14    		ld	hl,L555
 601    1908  CD0000    		call	_printf
 602                    	; 1014      /* partition name is in UTF-16LE code units */
 603                    	; 1015      hasname = NO;
 604    190B  DD36F400  		ld	(ix-12),0
 605    190F  DD36F500  		ld	(ix-11),0
 606                    	; 1016      for (index = 0; index < 72; index += 2)
 607    1913  DD36F800  		ld	(ix-8),0
 608    1917  DD36F900  		ld	(ix-7),0
 609                    	L1742:
 610    191B  DD7EF8    		ld	a,(ix-8)
 611    191E  D648      		sub	72
 612    1920  DD7EF9    		ld	a,(ix-7)
 613    1923  DE00      		sbc	a,0
 614    1925  F2B419    		jp	p,L1052
 615                    	; 1017          {
 616                    	; 1018          entryidx = index + 56;
 617    1928  DD6EF8    		ld	l,(ix-8)
 618    192B  DD66F9    		ld	h,(ix-7)
 619    192E  013800    		ld	bc,56
 620    1931  09        		add	hl,bc
 621    1932  DD75F6    		ld	(ix-10),l
 622    1935  DD74F7    		ld	(ix-9),h
 623                    	; 1019          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
 624    1938  DD6EEE    		ld	l,(ix-18)
 625    193B  DD66EF    		ld	h,(ix-17)
 626    193E  DD4EF6    		ld	c,(ix-10)
 627    1941  DD46F7    		ld	b,(ix-9)
 628    1944  09        		add	hl,bc
 629    1945  6E        		ld	l,(hl)
 630    1946  E5        		push	hl
 631    1947  DD6EF6    		ld	l,(ix-10)
 632    194A  DD66F7    		ld	h,(ix-9)
 633    194D  23        		inc	hl
 634    194E  DD4EEE    		ld	c,(ix-18)
 635    1951  DD46EF    		ld	b,(ix-17)
 636    1954  09        		add	hl,bc
 637    1955  C1        		pop	bc
 638    1956  79        		ld	a,c
 639    1957  B6        		or	(hl)
 640    1958  4F        		ld	c,a
 641    1959  CAB419    		jp	z,L1052
 642                    	; 1020              break;
 643                    	; 1021          if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
 644    195C  DD6EEE    		ld	l,(ix-18)
 645    195F  DD66EF    		ld	h,(ix-17)
 646    1962  DD4EF6    		ld	c,(ix-10)
 647    1965  DD46F7    		ld	b,(ix-9)
 648    1968  09        		add	hl,bc
 649    1969  7E        		ld	a,(hl)
 650    196A  FE20      		cp	32
 651    196C  3827      		jr	c,L1452
 652    196E  DD6EEE    		ld	l,(ix-18)
 653    1971  DD66EF    		ld	h,(ix-17)
 654    1974  DD4EF6    		ld	c,(ix-10)
 655    1977  DD46F7    		ld	b,(ix-9)
 656    197A  09        		add	hl,bc
 657    197B  7E        		ld	a,(hl)
 658    197C  FE7F      		cp	127
 659    197E  3015      		jr	nc,L1452
 660                    	; 1022              putchar(entryptr[entryidx]);
 661    1980  DD6EEE    		ld	l,(ix-18)
 662    1983  DD66EF    		ld	h,(ix-17)
 663    1986  DD4EF6    		ld	c,(ix-10)
 664    1989  DD46F7    		ld	b,(ix-9)
 665    198C  09        		add	hl,bc
 666    198D  6E        		ld	l,(hl)
 667    198E  97        		sub	a
 668    198F  67        		ld	h,a
 669    1990  CD0000    		call	_putchar
 670                    	; 1023          else
 671    1993  1806      		jr	L1552
 672                    	L1452:
 673                    	; 1024              putchar('.');
 674    1995  212E00    		ld	hl,46
 675    1998  CD0000    		call	_putchar
 676                    	L1552:
 677                    	; 1025          hasname = YES;
 678    199B  DD36F401  		ld	(ix-12),1
 679    199F  DD36F500  		ld	(ix-11),0
 680                    	; 1026          }
 681    19A3  DD6EF8    		ld	l,(ix-8)
 682    19A6  DD66F9    		ld	h,(ix-7)
 683    19A9  23        		inc	hl
 684    19AA  23        		inc	hl
 685    19AB  DD75F8    		ld	(ix-8),l
 686    19AE  DD74F9    		ld	(ix-7),h
 687    19B1  C31B19    		jp	L1742
 688                    	L1052:
 689                    	; 1027      if (!hasname)
 690    19B4  DD7EF4    		ld	a,(ix-12)
 691    19B7  DDB6F5    		or	(ix-11)
 692    19BA  2006      		jr	nz,L1652
 693                    	; 1028          printf("name field empty");
 694    19BC  211315    		ld	hl,L565
 695    19BF  CD0000    		call	_printf
 696                    	L1652:
 697                    	; 1029      printf("\n");
 698    19C2  212415    		ld	hl,L575
 699    19C5  CD0000    		call	_printf
 700                    	; 1030      printf("   [");
 701    19C8  212615    		ld	hl,L506
 702    19CB  CD0000    		call	_printf
 703                    	; 1031      entryidx = index + 56;
 704    19CE  DD6EF8    		ld	l,(ix-8)
 705    19D1  DD66F9    		ld	h,(ix-7)
 706    19D4  013800    		ld	bc,56
 707    19D7  09        		add	hl,bc
 708    19D8  DD75F6    		ld	(ix-10),l
 709    19DB  DD74F7    		ld	(ix-9),h
 710                    	; 1032      for (index = 0; index < 72; index++)
 711    19DE  DD36F800  		ld	(ix-8),0
 712    19E2  DD36F900  		ld	(ix-7),0
 713                    	L1752:
 714    19E6  DD7EF8    		ld	a,(ix-8)
 715    19E9  D648      		sub	72
 716    19EB  DD7EF9    		ld	a,(ix-7)
 717    19EE  DE00      		sbc	a,0
 718    19F0  F22E1A    		jp	p,L1062
 719                    	; 1033          {
 720                    	; 1034          if (((index & 0xf) == 0) && (index != 0))
 721    19F3  DD6EF8    		ld	l,(ix-8)
 722    19F6  DD66F9    		ld	h,(ix-7)
 723    19F9  7D        		ld	a,l
 724    19FA  E60F      		and	15
 725    19FC  200E      		jr	nz,L1362
 726    19FE  DD7EF8    		ld	a,(ix-8)
 727    1A01  DDB6F9    		or	(ix-7)
 728    1A04  2806      		jr	z,L1362
 729                    	; 1035              printf("\n    ");
 730    1A06  212B15    		ld	hl,L516
 731    1A09  CD0000    		call	_printf
 732                    	L1362:
 733                    	; 1036          printf("%02x ", entryptr[entryidx]);
 734    1A0C  DD6EEE    		ld	l,(ix-18)
 735    1A0F  DD66EF    		ld	h,(ix-17)
 736    1A12  DD4EF6    		ld	c,(ix-10)
 737    1A15  DD46F7    		ld	b,(ix-9)
 738    1A18  09        		add	hl,bc
 739    1A19  4E        		ld	c,(hl)
 740    1A1A  97        		sub	a
 741    1A1B  47        		ld	b,a
 742    1A1C  C5        		push	bc
 743    1A1D  213115    		ld	hl,L526
 744    1A20  CD0000    		call	_printf
 745    1A23  F1        		pop	af
 746                    	; 1037          }
 747    1A24  DD34F8    		inc	(ix-8)
 748    1A27  2003      		jr	nz,L011
 749    1A29  DD34F9    		inc	(ix-7)
 750                    	L011:
 751    1A2C  18B8      		jr	L1752
 752                    	L1062:
 753                    	; 1038      printf("\b]\n");
 754    1A2E  213715    		ld	hl,L536
 755    1A31  CD0000    		call	_printf
 756                    	; 1039      }
 757    1A34  C30000    		jp	c.rets
 758                    	L546:
 759    1A37  47        		.byte	71
 760    1A38  50        		.byte	80
 761    1A39  54        		.byte	84
 762    1A3A  20        		.byte	32
 763    1A3B  68        		.byte	104
 764    1A3C  65        		.byte	101
 765    1A3D  61        		.byte	97
 766    1A3E  64        		.byte	100
 767    1A3F  65        		.byte	101
 768    1A40  72        		.byte	114
 769    1A41  0A        		.byte	10
 770    1A42  00        		.byte	0
 771                    	L556:
 772    1A43  43        		.byte	67
 773    1A44  61        		.byte	97
 774    1A45  6E        		.byte	110
 775    1A46  27        		.byte	39
 776    1A47  74        		.byte	116
 777    1A48  20        		.byte	32
 778    1A49  72        		.byte	114
 779    1A4A  65        		.byte	101
 780    1A4B  61        		.byte	97
 781    1A4C  64        		.byte	100
 782    1A4D  20        		.byte	32
 783    1A4E  47        		.byte	71
 784    1A4F  50        		.byte	80
 785    1A50  54        		.byte	84
 786    1A51  20        		.byte	32
 787    1A52  70        		.byte	112
 788    1A53  61        		.byte	97
 789    1A54  72        		.byte	114
 790    1A55  74        		.byte	116
 791    1A56  69        		.byte	105
 792    1A57  74        		.byte	116
 793    1A58  69        		.byte	105
 794    1A59  6F        		.byte	111
 795    1A5A  6E        		.byte	110
 796    1A5B  20        		.byte	32
 797    1A5C  74        		.byte	116
 798    1A5D  61        		.byte	97
 799    1A5E  62        		.byte	98
 800    1A5F  6C        		.byte	108
 801    1A60  65        		.byte	101
 802    1A61  20        		.byte	32
 803    1A62  68        		.byte	104
 804    1A63  65        		.byte	101
 805    1A64  61        		.byte	97
 806    1A65  64        		.byte	100
 807    1A66  65        		.byte	101
 808    1A67  72        		.byte	114
 809    1A68  0A        		.byte	10
 810    1A69  00        		.byte	0
 811                    	L566:
 812    1A6A  20        		.byte	32
 813    1A6B  20        		.byte	32
 814    1A6C  53        		.byte	83
 815    1A6D  69        		.byte	105
 816    1A6E  67        		.byte	103
 817    1A6F  6E        		.byte	110
 818    1A70  61        		.byte	97
 819    1A71  74        		.byte	116
 820    1A72  75        		.byte	117
 821    1A73  72        		.byte	114
 822    1A74  65        		.byte	101
 823    1A75  3A        		.byte	58
 824    1A76  20        		.byte	32
 825    1A77  25        		.byte	37
 826    1A78  2E        		.byte	46
 827    1A79  38        		.byte	56
 828    1A7A  73        		.byte	115
 829    1A7B  0A        		.byte	10
 830    1A7C  00        		.byte	0
 831                    	L576:
 832    1A7D  20        		.byte	32
 833    1A7E  20        		.byte	32
 834    1A7F  52        		.byte	82
 835    1A80  65        		.byte	101
 836    1A81  76        		.byte	118
 837    1A82  69        		.byte	105
 838    1A83  73        		.byte	115
 839    1A84  69        		.byte	105
 840    1A85  6F        		.byte	111
 841    1A86  6E        		.byte	110
 842    1A87  3A        		.byte	58
 843    1A88  20        		.byte	32
 844    1A89  25        		.byte	37
 845    1A8A  64        		.byte	100
 846    1A8B  2E        		.byte	46
 847    1A8C  25        		.byte	37
 848    1A8D  64        		.byte	100
 849    1A8E  20        		.byte	32
 850    1A8F  5B        		.byte	91
 851    1A90  25        		.byte	37
 852    1A91  30        		.byte	48
 853    1A92  32        		.byte	50
 854    1A93  78        		.byte	120
 855    1A94  20        		.byte	32
 856    1A95  25        		.byte	37
 857    1A96  30        		.byte	48
 858    1A97  32        		.byte	50
 859    1A98  78        		.byte	120
 860    1A99  20        		.byte	32
 861    1A9A  25        		.byte	37
 862    1A9B  30        		.byte	48
 863    1A9C  32        		.byte	50
 864    1A9D  78        		.byte	120
 865    1A9E  20        		.byte	32
 866    1A9F  25        		.byte	37
 867    1AA0  30        		.byte	48
 868    1AA1  32        		.byte	50
 869    1AA2  78        		.byte	120
 870    1AA3  5D        		.byte	93
 871    1AA4  0A        		.byte	10
 872    1AA5  00        		.byte	0
 873                    	L507:
 874    1AA6  20        		.byte	32
 875    1AA7  20        		.byte	32
 876    1AA8  4E        		.byte	78
 877    1AA9  75        		.byte	117
 878    1AAA  6D        		.byte	109
 879    1AAB  62        		.byte	98
 880    1AAC  65        		.byte	101
 881    1AAD  72        		.byte	114
 882    1AAE  20        		.byte	32
 883    1AAF  6F        		.byte	111
 884    1AB0  66        		.byte	102
 885    1AB1  20        		.byte	32
 886    1AB2  70        		.byte	112
 887    1AB3  61        		.byte	97
 888    1AB4  72        		.byte	114
 889    1AB5  74        		.byte	116
 890    1AB6  69        		.byte	105
 891    1AB7  74        		.byte	116
 892    1AB8  69        		.byte	105
 893    1AB9  6F        		.byte	111
 894    1ABA  6E        		.byte	110
 895    1ABB  20        		.byte	32
 896    1ABC  65        		.byte	101
 897    1ABD  6E        		.byte	110
 898    1ABE  74        		.byte	116
 899    1ABF  72        		.byte	114
 900    1AC0  69        		.byte	105
 901    1AC1  65        		.byte	101
 902    1AC2  73        		.byte	115
 903    1AC3  3A        		.byte	58
 904    1AC4  20        		.byte	32
 905    1AC5  25        		.byte	37
 906    1AC6  6C        		.byte	108
 907    1AC7  75        		.byte	117
 908    1AC8  20        		.byte	32
 909    1AC9  28        		.byte	40
 910    1ACA  6D        		.byte	109
 911    1ACB  61        		.byte	97
 912    1ACC  79        		.byte	121
 913    1ACD  20        		.byte	32
 914    1ACE  62        		.byte	98
 915    1ACF  65        		.byte	101
 916    1AD0  20        		.byte	32
 917    1AD1  61        		.byte	97
 918    1AD2  63        		.byte	99
 919    1AD3  74        		.byte	116
 920    1AD4  75        		.byte	117
 921    1AD5  61        		.byte	97
 922    1AD6  6C        		.byte	108
 923    1AD7  20        		.byte	32
 924    1AD8  6F        		.byte	111
 925    1AD9  72        		.byte	114
 926    1ADA  20        		.byte	32
 927    1ADB  6D        		.byte	109
 928    1ADC  61        		.byte	97
 929    1ADD  78        		.byte	120
 930    1ADE  69        		.byte	105
 931    1ADF  6D        		.byte	109
 932    1AE0  75        		.byte	117
 933    1AE1  6D        		.byte	109
 934    1AE2  29        		.byte	41
 935    1AE3  0A        		.byte	10
 936    1AE4  00        		.byte	0
 937                    	L517:
 938    1AE5  46        		.byte	70
 939    1AE6  69        		.byte	105
 940    1AE7  72        		.byte	114
 941    1AE8  73        		.byte	115
 942    1AE9  74        		.byte	116
 943    1AEA  20        		.byte	32
 944    1AEB  31        		.byte	49
 945    1AEC  36        		.byte	54
 946    1AED  20        		.byte	32
 947    1AEE  47        		.byte	71
 948    1AEF  50        		.byte	80
 949    1AF0  54        		.byte	84
 950    1AF1  20        		.byte	32
 951    1AF2  65        		.byte	101
 952    1AF3  6E        		.byte	110
 953    1AF4  74        		.byte	116
 954    1AF5  72        		.byte	114
 955    1AF6  69        		.byte	105
 956    1AF7  65        		.byte	101
 957    1AF8  73        		.byte	115
 958    1AF9  20        		.byte	32
 959    1AFA  73        		.byte	115
 960    1AFB  63        		.byte	99
 961    1AFC  61        		.byte	97
 962    1AFD  6E        		.byte	110
 963    1AFE  6E        		.byte	110
 964    1AFF  65        		.byte	101
 965    1B00  64        		.byte	100
 966    1B01  0A        		.byte	10
 967    1B02  00        		.byte	0
 968                    	; 1040  
 969                    	; 1041  /* Get GPT header */
 970                    	; 1042  void sdgpthdr(unsigned long block)
 971                    	; 1043      {
 972                    	_sdgpthdr:
 973    1B03  CD0000    		call	c.savs
 974    1B06  21F0FF    		ld	hl,65520
 975    1B09  39        		add	hl,sp
 976    1B0A  F9        		ld	sp,hl
 977                    	; 1044      int index;
 978                    	; 1045      unsigned int partno;
 979                    	; 1046      unsigned char *rxdata;
 980                    	; 1047      unsigned long entries;
 981                    	; 1048  
 982                    	; 1049      printf("GPT header\n");
 983    1B0B  21371A    		ld	hl,L546
 984    1B0E  CD0000    		call	_printf
 985                    	; 1050      if (!sdread(sdrdbuf, block))
 986    1B11  DD6607    		ld	h,(ix+7)
 987    1B14  DD6E06    		ld	l,(ix+6)
 988    1B17  E5        		push	hl
 989    1B18  DD6605    		ld	h,(ix+5)
 990    1B1B  DD6E04    		ld	l,(ix+4)
 991    1B1E  E5        		push	hl
 992    1B1F  213200    		ld	hl,_sdrdbuf
 993    1B22  CDE10C    		call	_sdread
 994    1B25  F1        		pop	af
 995    1B26  F1        		pop	af
 996    1B27  79        		ld	a,c
 997    1B28  B0        		or	b
 998    1B29  2009      		jr	nz,L1462
 999                    	; 1051          {
1000                    	; 1052          printf("Can't read GPT partition table header\n");
1001    1B2B  21431A    		ld	hl,L556
1002    1B2E  CD0000    		call	_printf
1003                    	; 1053          return;
1004    1B31  C30000    		jp	c.rets
1005                    	L1462:
1006                    	; 1054          }
1007                    	; 1055      curblkno = block;
1008    1B34  210000    		ld	hl,_curblkno
1009    1B37  E5        		push	hl
1010    1B38  DDE5      		push	ix
1011    1B3A  C1        		pop	bc
1012    1B3B  210400    		ld	hl,4
1013    1B3E  09        		add	hl,bc
1014    1B3F  E5        		push	hl
1015    1B40  CD0000    		call	c.mvl
1016    1B43  F1        		pop	af
1017                    	; 1056      curblkok = YES;
1018    1B44  210100    		ld	hl,1
1019    1B47  220C00    		ld	(_curblkok),hl
1020                    	; 1057  
1021                    	; 1058      rxdata = sdrdbuf;
1022    1B4A  213200    		ld	hl,_sdrdbuf
1023    1B4D  DD75F4    		ld	(ix-12),l
1024    1B50  DD74F5    		ld	(ix-11),h
1025                    	; 1059      printf("  Signature: %.8s\n", &rxdata[0]);
1026    1B53  DD6EF4    		ld	l,(ix-12)
1027    1B56  DD66F5    		ld	h,(ix-11)
1028    1B59  E5        		push	hl
1029    1B5A  216A1A    		ld	hl,L566
1030    1B5D  CD0000    		call	_printf
1031    1B60  F1        		pop	af
1032                    	; 1060      printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
1033                    	; 1061             (int)rxdata[8] * ((int)rxdata[9] << 8),
1034                    	; 1062             (int)rxdata[10] + ((int)rxdata[11] << 8),
1035                    	; 1063             rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
1036    1B61  DD6EF4    		ld	l,(ix-12)
1037    1B64  DD66F5    		ld	h,(ix-11)
1038    1B67  010B00    		ld	bc,11
1039    1B6A  09        		add	hl,bc
1040    1B6B  4E        		ld	c,(hl)
1041    1B6C  97        		sub	a
1042    1B6D  47        		ld	b,a
1043    1B6E  C5        		push	bc
1044    1B6F  DD6EF4    		ld	l,(ix-12)
1045    1B72  DD66F5    		ld	h,(ix-11)
1046    1B75  010A00    		ld	bc,10
1047    1B78  09        		add	hl,bc
1048    1B79  4E        		ld	c,(hl)
1049    1B7A  97        		sub	a
1050    1B7B  47        		ld	b,a
1051    1B7C  C5        		push	bc
1052    1B7D  DD6EF4    		ld	l,(ix-12)
1053    1B80  DD66F5    		ld	h,(ix-11)
1054    1B83  010900    		ld	bc,9
1055    1B86  09        		add	hl,bc
1056    1B87  4E        		ld	c,(hl)
1057    1B88  97        		sub	a
1058    1B89  47        		ld	b,a
1059    1B8A  C5        		push	bc
1060    1B8B  DD6EF4    		ld	l,(ix-12)
1061    1B8E  DD66F5    		ld	h,(ix-11)
1062    1B91  010800    		ld	bc,8
1063    1B94  09        		add	hl,bc
1064    1B95  4E        		ld	c,(hl)
1065    1B96  97        		sub	a
1066    1B97  47        		ld	b,a
1067    1B98  C5        		push	bc
1068    1B99  DD6EF4    		ld	l,(ix-12)
1069    1B9C  DD66F5    		ld	h,(ix-11)
1070    1B9F  010A00    		ld	bc,10
1071    1BA2  09        		add	hl,bc
1072    1BA3  6E        		ld	l,(hl)
1073    1BA4  97        		sub	a
1074    1BA5  67        		ld	h,a
1075    1BA6  E5        		push	hl
1076    1BA7  DD6EF4    		ld	l,(ix-12)
1077    1BAA  DD66F5    		ld	h,(ix-11)
1078    1BAD  010B00    		ld	bc,11
1079    1BB0  09        		add	hl,bc
1080    1BB1  6E        		ld	l,(hl)
1081    1BB2  97        		sub	a
1082    1BB3  67        		ld	h,a
1083    1BB4  29        		add	hl,hl
1084    1BB5  29        		add	hl,hl
1085    1BB6  29        		add	hl,hl
1086    1BB7  29        		add	hl,hl
1087    1BB8  29        		add	hl,hl
1088    1BB9  29        		add	hl,hl
1089    1BBA  29        		add	hl,hl
1090    1BBB  29        		add	hl,hl
1091    1BBC  E3        		ex	(sp),hl
1092    1BBD  C1        		pop	bc
1093    1BBE  09        		add	hl,bc
1094    1BBF  E5        		push	hl
1095    1BC0  DD6EF4    		ld	l,(ix-12)
1096    1BC3  DD66F5    		ld	h,(ix-11)
1097    1BC6  010800    		ld	bc,8
1098    1BC9  09        		add	hl,bc
1099    1BCA  6E        		ld	l,(hl)
1100    1BCB  97        		sub	a
1101    1BCC  67        		ld	h,a
1102    1BCD  E5        		push	hl
1103    1BCE  DD6EF4    		ld	l,(ix-12)
1104    1BD1  DD66F5    		ld	h,(ix-11)
1105    1BD4  010900    		ld	bc,9
1106    1BD7  09        		add	hl,bc
1107    1BD8  6E        		ld	l,(hl)
1108    1BD9  97        		sub	a
1109    1BDA  67        		ld	h,a
1110    1BDB  29        		add	hl,hl
1111    1BDC  29        		add	hl,hl
1112    1BDD  29        		add	hl,hl
1113    1BDE  29        		add	hl,hl
1114    1BDF  29        		add	hl,hl
1115    1BE0  29        		add	hl,hl
1116    1BE1  29        		add	hl,hl
1117    1BE2  29        		add	hl,hl
1118    1BE3  E5        		push	hl
1119    1BE4  CD0000    		call	c.imul
1120    1BE7  217D1A    		ld	hl,L576
1121    1BEA  CD0000    		call	_printf
1122    1BED  210C00    		ld	hl,12
1123    1BF0  39        		add	hl,sp
1124    1BF1  F9        		ld	sp,hl
1125                    	; 1064      entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
1126                    	; 1065                ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
1127    1BF2  DDE5      		push	ix
1128    1BF4  C1        		pop	bc
1129    1BF5  21F0FF    		ld	hl,65520
1130    1BF8  09        		add	hl,bc
1131    1BF9  E5        		push	hl
1132    1BFA  DD6EF4    		ld	l,(ix-12)
1133    1BFD  DD66F5    		ld	h,(ix-11)
1134    1C00  015000    		ld	bc,80
1135    1C03  09        		add	hl,bc
1136    1C04  4D        		ld	c,l
1137    1C05  44        		ld	b,h
1138    1C06  97        		sub	a
1139    1C07  320000    		ld	(c.r0),a
1140    1C0A  320100    		ld	(c.r0+1),a
1141    1C0D  0A        		ld	a,(bc)
1142    1C0E  320200    		ld	(c.r0+2),a
1143    1C11  97        		sub	a
1144    1C12  320300    		ld	(c.r0+3),a
1145    1C15  210000    		ld	hl,c.r0
1146    1C18  E5        		push	hl
1147    1C19  DD6EF4    		ld	l,(ix-12)
1148    1C1C  DD66F5    		ld	h,(ix-11)
1149    1C1F  015100    		ld	bc,81
1150    1C22  09        		add	hl,bc
1151    1C23  4D        		ld	c,l
1152    1C24  44        		ld	b,h
1153    1C25  97        		sub	a
1154    1C26  320000    		ld	(c.r1),a
1155    1C29  320100    		ld	(c.r1+1),a
1156    1C2C  0A        		ld	a,(bc)
1157    1C2D  320200    		ld	(c.r1+2),a
1158    1C30  97        		sub	a
1159    1C31  320300    		ld	(c.r1+3),a
1160    1C34  210000    		ld	hl,c.r1
1161    1C37  E5        		push	hl
1162    1C38  210800    		ld	hl,8
1163    1C3B  E5        		push	hl
1164    1C3C  CD0000    		call	c.llsh
1165    1C3F  CD0000    		call	c.ladd
1166    1C42  DD6EF4    		ld	l,(ix-12)
1167    1C45  DD66F5    		ld	h,(ix-11)
1168    1C48  015200    		ld	bc,82
1169    1C4B  09        		add	hl,bc
1170    1C4C  4D        		ld	c,l
1171    1C4D  44        		ld	b,h
1172    1C4E  97        		sub	a
1173    1C4F  320000    		ld	(c.r1),a
1174    1C52  320100    		ld	(c.r1+1),a
1175    1C55  0A        		ld	a,(bc)
1176    1C56  320200    		ld	(c.r1+2),a
1177    1C59  97        		sub	a
1178    1C5A  320300    		ld	(c.r1+3),a
1179    1C5D  210000    		ld	hl,c.r1
1180    1C60  E5        		push	hl
1181    1C61  211000    		ld	hl,16
1182    1C64  E5        		push	hl
1183    1C65  CD0000    		call	c.llsh
1184    1C68  CD0000    		call	c.ladd
1185    1C6B  DD6EF4    		ld	l,(ix-12)
1186    1C6E  DD66F5    		ld	h,(ix-11)
1187    1C71  015300    		ld	bc,83
1188    1C74  09        		add	hl,bc
1189    1C75  4D        		ld	c,l
1190    1C76  44        		ld	b,h
1191    1C77  97        		sub	a
1192    1C78  320000    		ld	(c.r1),a
1193    1C7B  320100    		ld	(c.r1+1),a
1194    1C7E  0A        		ld	a,(bc)
1195    1C7F  320200    		ld	(c.r1+2),a
1196    1C82  97        		sub	a
1197    1C83  320300    		ld	(c.r1+3),a
1198    1C86  210000    		ld	hl,c.r1
1199    1C89  E5        		push	hl
1200    1C8A  211800    		ld	hl,24
1201    1C8D  E5        		push	hl
1202    1C8E  CD0000    		call	c.llsh
1203    1C91  CD0000    		call	c.ladd
1204    1C94  CD0000    		call	c.mvl
1205    1C97  F1        		pop	af
1206                    	; 1066      printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
1207    1C98  DD66F3    		ld	h,(ix-13)
1208    1C9B  DD6EF2    		ld	l,(ix-14)
1209    1C9E  E5        		push	hl
1210    1C9F  DD66F1    		ld	h,(ix-15)
1211    1CA2  DD6EF0    		ld	l,(ix-16)
1212    1CA5  E5        		push	hl
1213    1CA6  21A61A    		ld	hl,L507
1214    1CA9  CD0000    		call	_printf
1215    1CAC  F1        		pop	af
1216    1CAD  F1        		pop	af
1217                    	; 1067      for (partno = 0; partno < 16; partno++)
1218    1CAE  DD36F600  		ld	(ix-10),0
1219    1CB2  DD36F700  		ld	(ix-9),0
1220                    	L1562:
1221    1CB6  DD7EF6    		ld	a,(ix-10)
1222    1CB9  D610      		sub	16
1223    1CBB  DD7EF7    		ld	a,(ix-9)
1224    1CBE  DE00      		sbc	a,0
1225    1CC0  3013      		jr	nc,L1662
1226                    	; 1068          {
1227                    	; 1069          prtgptent(partno);
1228    1CC2  DD6EF6    		ld	l,(ix-10)
1229    1CC5  DD66F7    		ld	h,(ix-9)
1230    1CC8  CD3B15    		call	_prtgptent
1231                    	; 1070          }
1232    1CCB  DD34F6    		inc	(ix-10)
1233    1CCE  2003      		jr	nz,L411
1234    1CD0  DD34F7    		inc	(ix-9)
1235                    	L411:
1236    1CD3  18E1      		jr	L1562
1237                    	L1662:
1238                    	; 1071      printf("First 16 GPT entries scanned\n");
1239    1CD5  21E51A    		ld	hl,L517
1240    1CD8  CD0000    		call	_printf
1241                    	; 1072      }
1242    1CDB  C30000    		jp	c.rets
1243                    	L527:
1244    1CDE  43        		.byte	67
1245    1CDF  61        		.byte	97
1246    1CE0  6E        		.byte	110
1247    1CE1  27        		.byte	39
1248    1CE2  74        		.byte	116
1249    1CE3  20        		.byte	32
1250    1CE4  72        		.byte	114
1251    1CE5  65        		.byte	101
1252    1CE6  61        		.byte	97
1253    1CE7  64        		.byte	100
1254    1CE8  20        		.byte	32
1255    1CE9  4D        		.byte	77
1256    1CEA  42        		.byte	66
1257    1CEB  52        		.byte	82
1258    1CEC  20        		.byte	32
1259    1CED  73        		.byte	115
1260    1CEE  65        		.byte	101
1261    1CEF  63        		.byte	99
1262    1CF0  74        		.byte	116
1263    1CF1  6F        		.byte	111
1264    1CF2  72        		.byte	114
1265    1CF3  0A        		.byte	10
1266    1CF4  00        		.byte	0
1267                    	L537:
1268    1CF5  4E        		.byte	78
1269    1CF6  6F        		.byte	111
1270    1CF7  74        		.byte	116
1271    1CF8  20        		.byte	32
1272    1CF9  75        		.byte	117
1273    1CFA  73        		.byte	115
1274    1CFB  65        		.byte	101
1275    1CFC  64        		.byte	100
1276    1CFD  20        		.byte	32
1277    1CFE  65        		.byte	101
1278    1CFF  6E        		.byte	110
1279    1D00  74        		.byte	116
1280    1D01  72        		.byte	114
1281    1D02  79        		.byte	121
1282    1D03  0A        		.byte	10
1283    1D04  00        		.byte	0
1284                    	L547:
1285    1D05  62        		.byte	98
1286    1D06  6F        		.byte	111
1287    1D07  6F        		.byte	111
1288    1D08  74        		.byte	116
1289    1D09  20        		.byte	32
1290    1D0A  69        		.byte	105
1291    1D0B  6E        		.byte	110
1292    1D0C  64        		.byte	100
1293    1D0D  69        		.byte	105
1294    1D0E  63        		.byte	99
1295    1D0F  61        		.byte	97
1296    1D10  74        		.byte	116
1297    1D11  6F        		.byte	111
1298    1D12  72        		.byte	114
1299    1D13  3A        		.byte	58
1300    1D14  20        		.byte	32
1301    1D15  30        		.byte	48
1302    1D16  78        		.byte	120
1303    1D17  25        		.byte	37
1304    1D18  30        		.byte	48
1305    1D19  32        		.byte	50
1306    1D1A  78        		.byte	120
1307    1D1B  2C        		.byte	44
1308    1D1C  20        		.byte	32
1309    1D1D  53        		.byte	83
1310    1D1E  79        		.byte	121
1311    1D1F  73        		.byte	115
1312    1D20  74        		.byte	116
1313    1D21  65        		.byte	101
1314    1D22  6D        		.byte	109
1315    1D23  20        		.byte	32
1316    1D24  49        		.byte	73
1317    1D25  44        		.byte	68
1318    1D26  3A        		.byte	58
1319    1D27  20        		.byte	32
1320    1D28  30        		.byte	48
1321    1D29  78        		.byte	120
1322    1D2A  25        		.byte	37
1323    1D2B  30        		.byte	48
1324    1D2C  32        		.byte	50
1325    1D2D  78        		.byte	120
1326    1D2E  0A        		.byte	10
1327    1D2F  00        		.byte	0
1328                    	L557:
1329    1D30  20        		.byte	32
1330    1D31  20        		.byte	32
1331    1D32  45        		.byte	69
1332    1D33  78        		.byte	120
1333    1D34  74        		.byte	116
1334    1D35  65        		.byte	101
1335    1D36  6E        		.byte	110
1336    1D37  64        		.byte	100
1337    1D38  65        		.byte	101
1338    1D39  64        		.byte	100
1339    1D3A  20        		.byte	32
1340    1D3B  70        		.byte	112
1341    1D3C  61        		.byte	97
1342    1D3D  72        		.byte	114
1343    1D3E  74        		.byte	116
1344    1D3F  69        		.byte	105
1345    1D40  74        		.byte	116
1346    1D41  69        		.byte	105
1347    1D42  6F        		.byte	111
1348    1D43  6E        		.byte	110
1349    1D44  0A        		.byte	10
1350    1D45  00        		.byte	0
1351                    	L567:
1352    1D46  20        		.byte	32
1353    1D47  20        		.byte	32
1354    1D48  75        		.byte	117
1355    1D49  6E        		.byte	110
1356    1D4A  6F        		.byte	111
1357    1D4B  66        		.byte	102
1358    1D4C  66        		.byte	102
1359    1D4D  69        		.byte	105
1360    1D4E  63        		.byte	99
1361    1D4F  69        		.byte	105
1362    1D50  61        		.byte	97
1363    1D51  6C        		.byte	108
1364    1D52  20        		.byte	32
1365    1D53  34        		.byte	52
1366    1D54  38        		.byte	56
1367    1D55  20        		.byte	32
1368    1D56  62        		.byte	98
1369    1D57  69        		.byte	105
1370    1D58  74        		.byte	116
1371    1D59  20        		.byte	32
1372    1D5A  4C        		.byte	76
1373    1D5B  42        		.byte	66
1374    1D5C  41        		.byte	65
1375    1D5D  20        		.byte	32
1376    1D5E  50        		.byte	80
1377    1D5F  72        		.byte	114
1378    1D60  6F        		.byte	111
1379    1D61  70        		.byte	112
1380    1D62  6F        		.byte	111
1381    1D63  73        		.byte	115
1382    1D64  65        		.byte	101
1383    1D65  64        		.byte	100
1384    1D66  20        		.byte	32
1385    1D67  4D        		.byte	77
1386    1D68  42        		.byte	66
1387    1D69  52        		.byte	82
1388    1D6A  20        		.byte	32
1389    1D6B  46        		.byte	70
1390    1D6C  6F        		.byte	111
1391    1D6D  72        		.byte	114
1392    1D6E  6D        		.byte	109
1393    1D6F  61        		.byte	97
1394    1D70  74        		.byte	116
1395    1D71  2C        		.byte	44
1396    1D72  20        		.byte	32
1397    1D73  6E        		.byte	110
1398    1D74  6F        		.byte	111
1399    1D75  20        		.byte	32
1400    1D76  43        		.byte	67
1401    1D77  48        		.byte	72
1402    1D78  53        		.byte	83
1403    1D79  0A        		.byte	10
1404    1D7A  00        		.byte	0
1405                    	L577:
1406    1D7B  20        		.byte	32
1407    1D7C  20        		.byte	32
1408    1D7D  62        		.byte	98
1409    1D7E  65        		.byte	101
1410    1D7F  67        		.byte	103
1411    1D80  69        		.byte	105
1412    1D81  6E        		.byte	110
1413    1D82  20        		.byte	32
1414    1D83  43        		.byte	67
1415    1D84  48        		.byte	72
1416    1D85  53        		.byte	83
1417    1D86  3A        		.byte	58
1418    1D87  20        		.byte	32
1419    1D88  30        		.byte	48
1420    1D89  78        		.byte	120
1421    1D8A  25        		.byte	37
1422    1D8B  30        		.byte	48
1423    1D8C  32        		.byte	50
1424    1D8D  78        		.byte	120
1425    1D8E  2D        		.byte	45
1426    1D8F  30        		.byte	48
1427    1D90  78        		.byte	120
1428    1D91  25        		.byte	37
1429    1D92  30        		.byte	48
1430    1D93  32        		.byte	50
1431    1D94  78        		.byte	120
1432    1D95  2D        		.byte	45
1433    1D96  30        		.byte	48
1434    1D97  78        		.byte	120
1435    1D98  25        		.byte	37
1436    1D99  30        		.byte	48
1437    1D9A  32        		.byte	50
1438    1D9B  78        		.byte	120
1439    1D9C  20        		.byte	32
1440    1D9D  28        		.byte	40
1441    1D9E  63        		.byte	99
1442    1D9F  79        		.byte	121
1443    1DA0  6C        		.byte	108
1444    1DA1  3A        		.byte	58
1445    1DA2  20        		.byte	32
1446    1DA3  25        		.byte	37
1447    1DA4  64        		.byte	100
1448    1DA5  2C        		.byte	44
1449    1DA6  20        		.byte	32
1450    1DA7  68        		.byte	104
1451    1DA8  65        		.byte	101
1452    1DA9  61        		.byte	97
1453    1DAA  64        		.byte	100
1454    1DAB  3A        		.byte	58
1455    1DAC  20        		.byte	32
1456    1DAD  25        		.byte	37
1457    1DAE  64        		.byte	100
1458    1DAF  20        		.byte	32
1459    1DB0  73        		.byte	115
1460    1DB1  65        		.byte	101
1461    1DB2  63        		.byte	99
1462    1DB3  74        		.byte	116
1463    1DB4  6F        		.byte	111
1464    1DB5  72        		.byte	114
1465    1DB6  3A        		.byte	58
1466    1DB7  20        		.byte	32
1467    1DB8  25        		.byte	37
1468    1DB9  64        		.byte	100
1469    1DBA  29        		.byte	41
1470    1DBB  0A        		.byte	10
1471    1DBC  00        		.byte	0
1472                    	L5001:
1473    1DBD  20        		.byte	32
1474    1DBE  20        		.byte	32
1475    1DBF  65        		.byte	101
1476    1DC0  6E        		.byte	110
1477    1DC1  64        		.byte	100
1478    1DC2  20        		.byte	32
1479    1DC3  43        		.byte	67
1480    1DC4  48        		.byte	72
1481    1DC5  53        		.byte	83
1482    1DC6  20        		.byte	32
1483    1DC7  30        		.byte	48
1484    1DC8  78        		.byte	120
1485    1DC9  25        		.byte	37
1486    1DCA  30        		.byte	48
1487    1DCB  32        		.byte	50
1488    1DCC  78        		.byte	120
1489    1DCD  2D        		.byte	45
1490    1DCE  30        		.byte	48
1491    1DCF  78        		.byte	120
1492    1DD0  25        		.byte	37
1493    1DD1  30        		.byte	48
1494    1DD2  32        		.byte	50
1495    1DD3  78        		.byte	120
1496    1DD4  2D        		.byte	45
1497    1DD5  30        		.byte	48
1498    1DD6  78        		.byte	120
1499    1DD7  25        		.byte	37
1500    1DD8  30        		.byte	48
1501    1DD9  32        		.byte	50
1502    1DDA  78        		.byte	120
1503    1DDB  20        		.byte	32
1504    1DDC  28        		.byte	40
1505    1DDD  63        		.byte	99
1506    1DDE  79        		.byte	121
1507    1DDF  6C        		.byte	108
1508    1DE0  3A        		.byte	58
1509    1DE1  20        		.byte	32
1510    1DE2  25        		.byte	37
1511    1DE3  64        		.byte	100
1512    1DE4  2C        		.byte	44
1513    1DE5  20        		.byte	32
1514    1DE6  68        		.byte	104
1515    1DE7  65        		.byte	101
1516    1DE8  61        		.byte	97
1517    1DE9  64        		.byte	100
1518    1DEA  3A        		.byte	58
1519    1DEB  20        		.byte	32
1520    1DEC  25        		.byte	37
1521    1DED  64        		.byte	100
1522    1DEE  20        		.byte	32
1523    1DEF  73        		.byte	115
1524    1DF0  65        		.byte	101
1525    1DF1  63        		.byte	99
1526    1DF2  74        		.byte	116
1527    1DF3  6F        		.byte	111
1528    1DF4  72        		.byte	114
1529    1DF5  3A        		.byte	58
1530    1DF6  20        		.byte	32
1531    1DF7  25        		.byte	37
1532    1DF8  64        		.byte	100
1533    1DF9  29        		.byte	41
1534    1DFA  0A        		.byte	10
1535    1DFB  00        		.byte	0
1536                    	L5101:
1537    1DFC  20        		.byte	32
1538    1DFD  20        		.byte	32
1539    1DFE  70        		.byte	112
1540    1DFF  61        		.byte	97
1541    1E00  72        		.byte	114
1542    1E01  74        		.byte	116
1543    1E02  69        		.byte	105
1544    1E03  74        		.byte	116
1545    1E04  69        		.byte	105
1546    1E05  6F        		.byte	111
1547    1E06  6E        		.byte	110
1548    1E07  20        		.byte	32
1549    1E08  73        		.byte	115
1550    1E09  74        		.byte	116
1551    1E0A  61        		.byte	97
1552    1E0B  72        		.byte	114
1553    1E0C  74        		.byte	116
1554    1E0D  20        		.byte	32
1555    1E0E  4C        		.byte	76
1556    1E0F  42        		.byte	66
1557    1E10  41        		.byte	65
1558    1E11  3A        		.byte	58
1559    1E12  20        		.byte	32
1560    1E13  25        		.byte	37
1561    1E14  6C        		.byte	108
1562    1E15  75        		.byte	117
1563    1E16  20        		.byte	32
1564    1E17  5B        		.byte	91
1565    1E18  25        		.byte	37
1566    1E19  30        		.byte	48
1567    1E1A  38        		.byte	56
1568    1E1B  6C        		.byte	108
1569    1E1C  78        		.byte	120
1570    1E1D  5D        		.byte	93
1571    1E1E  0A        		.byte	10
1572    1E1F  00        		.byte	0
1573                    	L5201:
1574    1E20  20        		.byte	32
1575    1E21  20        		.byte	32
1576    1E22  70        		.byte	112
1577    1E23  61        		.byte	97
1578    1E24  72        		.byte	114
1579    1E25  74        		.byte	116
1580    1E26  69        		.byte	105
1581    1E27  74        		.byte	116
1582    1E28  69        		.byte	105
1583    1E29  6F        		.byte	111
1584    1E2A  6E        		.byte	110
1585    1E2B  20        		.byte	32
1586    1E2C  73        		.byte	115
1587    1E2D  69        		.byte	105
1588    1E2E  7A        		.byte	122
1589    1E2F  65        		.byte	101
1590    1E30  20        		.byte	32
1591    1E31  4C        		.byte	76
1592    1E32  42        		.byte	66
1593    1E33  41        		.byte	65
1594    1E34  3A        		.byte	58
1595    1E35  20        		.byte	32
1596    1E36  25        		.byte	37
1597    1E37  6C        		.byte	108
1598    1E38  75        		.byte	117
1599    1E39  20        		.byte	32
1600    1E3A  5B        		.byte	91
1601    1E3B  25        		.byte	37
1602    1E3C  30        		.byte	48
1603    1E3D  38        		.byte	56
1604    1E3E  6C        		.byte	108
1605    1E3F  78        		.byte	120
1606    1E40  5D        		.byte	93
1607    1E41  2C        		.byte	44
1608    1E42  20        		.byte	32
1609    1E43  25        		.byte	37
1610    1E44  6C        		.byte	108
1611    1E45  75        		.byte	117
1612    1E46  20        		.byte	32
1613    1E47  4D        		.byte	77
1614    1E48  42        		.byte	66
1615    1E49  79        		.byte	121
1616    1E4A  74        		.byte	116
1617    1E4B  65        		.byte	101
1618    1E4C  0A        		.byte	10
1619    1E4D  00        		.byte	0
1620                    	; 1073  
1621                    	; 1074  /* read MBR partition entry */
1622                    	; 1075  int sdmbrentry(unsigned char *partptr)
1623                    	; 1076      {
1624                    	_sdmbrentry:
1625    1E4E  CD0000    		call	c.savs
1626    1E51  21F0FF    		ld	hl,65520
1627    1E54  39        		add	hl,sp
1628    1E55  F9        		ld	sp,hl
1629                    	; 1077      int index;
1630                    	; 1078      unsigned long lbastart;
1631                    	; 1079      unsigned long lbasize;
1632                    	; 1080  
1633                    	; 1081      if ((curblkno != 0) || !curblkok)
1634    1E56  210000    		ld	hl,_curblkno
1635    1E59  7E        		ld	a,(hl)
1636    1E5A  23        		inc	hl
1637    1E5B  B6        		or	(hl)
1638    1E5C  23        		inc	hl
1639    1E5D  B6        		or	(hl)
1640    1E5E  23        		inc	hl
1641    1E5F  B6        		or	(hl)
1642    1E60  2007      		jr	nz,L1272
1643    1E62  2A0C00    		ld	hl,(_curblkok)
1644    1E65  7C        		ld	a,h
1645    1E66  B5        		or	l
1646    1E67  2034      		jr	nz,L1172
1647                    	L1272:
1648                    	; 1082          {
1649                    	; 1083          curblkno = 0;
1650    1E69  97        		sub	a
1651    1E6A  320000    		ld	(_curblkno),a
1652    1E6D  320100    		ld	(_curblkno+1),a
1653    1E70  320200    		ld	(_curblkno+2),a
1654    1E73  320300    		ld	(_curblkno+3),a
1655                    	; 1084          if (!sdread(sdrdbuf, curblkno))
1656    1E76  210300    		ld	hl,_curblkno+3
1657    1E79  46        		ld	b,(hl)
1658    1E7A  2B        		dec	hl
1659    1E7B  4E        		ld	c,(hl)
1660    1E7C  C5        		push	bc
1661    1E7D  2B        		dec	hl
1662    1E7E  46        		ld	b,(hl)
1663    1E7F  2B        		dec	hl
1664    1E80  4E        		ld	c,(hl)
1665    1E81  C5        		push	bc
1666    1E82  213200    		ld	hl,_sdrdbuf
1667    1E85  CDE10C    		call	_sdread
1668    1E88  F1        		pop	af
1669    1E89  F1        		pop	af
1670    1E8A  79        		ld	a,c
1671    1E8B  B0        		or	b
1672    1E8C  2009      		jr	nz,L1372
1673                    	; 1085              {
1674                    	; 1086              printf("Can't read MBR sector\n");
1675    1E8E  21DE1C    		ld	hl,L527
1676    1E91  CD0000    		call	_printf
1677                    	; 1087              return;
1678    1E94  C30000    		jp	c.rets
1679                    	L1372:
1680                    	; 1088              }
1681                    	; 1089          curblkok = YES;
1682    1E97  210100    		ld	hl,1
1683    1E9A  220C00    		ld	(_curblkok),hl
1684                    	L1172:
1685                    	; 1090          }
1686                    	; 1091      if (!partptr[4])
1687    1E9D  DD6E04    		ld	l,(ix+4)
1688    1EA0  DD6605    		ld	h,(ix+5)
1689    1EA3  23        		inc	hl
1690    1EA4  23        		inc	hl
1691    1EA5  23        		inc	hl
1692    1EA6  23        		inc	hl
1693    1EA7  7E        		ld	a,(hl)
1694    1EA8  B7        		or	a
1695    1EA9  2009      		jr	nz,L1472
1696                    	; 1092          {
1697                    	; 1093          printf("Not used entry\n");
1698    1EAB  21F51C    		ld	hl,L537
1699    1EAE  CD0000    		call	_printf
1700                    	; 1094          return;
1701    1EB1  C30000    		jp	c.rets
1702                    	L1472:
1703                    	; 1095          }
1704                    	; 1096      printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
1705                    	; 1097             partptr[0], partptr[4]);
1706    1EB4  DD6E04    		ld	l,(ix+4)
1707    1EB7  DD6605    		ld	h,(ix+5)
1708    1EBA  23        		inc	hl
1709    1EBB  23        		inc	hl
1710    1EBC  23        		inc	hl
1711    1EBD  23        		inc	hl
1712    1EBE  4E        		ld	c,(hl)
1713    1EBF  97        		sub	a
1714    1EC0  47        		ld	b,a
1715    1EC1  C5        		push	bc
1716    1EC2  DD6E04    		ld	l,(ix+4)
1717    1EC5  DD6605    		ld	h,(ix+5)
1718    1EC8  4E        		ld	c,(hl)
1719    1EC9  97        		sub	a
1720    1ECA  47        		ld	b,a
1721    1ECB  C5        		push	bc
1722    1ECC  21051D    		ld	hl,L547
1723    1ECF  CD0000    		call	_printf
1724    1ED2  F1        		pop	af
1725    1ED3  F1        		pop	af
1726                    	; 1098  
1727                    	; 1099      if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
1728    1ED4  DD6E04    		ld	l,(ix+4)
1729    1ED7  DD6605    		ld	h,(ix+5)
1730    1EDA  23        		inc	hl
1731    1EDB  23        		inc	hl
1732    1EDC  23        		inc	hl
1733    1EDD  23        		inc	hl
1734    1EDE  7E        		ld	a,(hl)
1735    1EDF  FE05      		cp	5
1736    1EE1  280F      		jr	z,L1672
1737    1EE3  DD6E04    		ld	l,(ix+4)
1738    1EE6  DD6605    		ld	h,(ix+5)
1739    1EE9  23        		inc	hl
1740    1EEA  23        		inc	hl
1741    1EEB  23        		inc	hl
1742    1EEC  23        		inc	hl
1743    1EED  7E        		ld	a,(hl)
1744    1EEE  FE0F      		cp	15
1745    1EF0  2006      		jr	nz,L1572
1746                    	L1672:
1747                    	; 1100          {
1748                    	; 1101          printf("  Extended partition\n");
1749    1EF2  21301D    		ld	hl,L557
1750    1EF5  CD0000    		call	_printf
1751                    	L1572:
1752                    	; 1102          /* should probably decode this also */
1753                    	; 1103          }
1754                    	; 1104      if (partptr[0] & 0x01)
1755    1EF8  DD6E04    		ld	l,(ix+4)
1756    1EFB  DD6605    		ld	h,(ix+5)
1757    1EFE  7E        		ld	a,(hl)
1758    1EFF  CB47      		bit	0,a
1759    1F01  6F        		ld	l,a
1760    1F02  2809      		jr	z,L1772
1761                    	; 1105          {
1762                    	; 1106          printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
1763    1F04  21461D    		ld	hl,L567
1764    1F07  CD0000    		call	_printf
1765                    	; 1107          /* this is however discussed
1766                    	; 1108             https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
1767                    	; 1109          */
1768                    	; 1110          }
1769                    	; 1111      else
1770    1F0A  C30920    		jp	L1003
1771                    	L1772:
1772                    	; 1112          {
1773                    	; 1113          printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1774                    	; 1114                 partptr[1], partptr[2], partptr[3],
1775                    	; 1115                 ((partptr[2] & 0xc0) >> 2) + partptr[3],
1776                    	; 1116                 partptr[1],
1777                    	; 1117                 partptr[2] & 0x3f);
1778    1F0D  DD6E04    		ld	l,(ix+4)
1779    1F10  DD6605    		ld	h,(ix+5)
1780    1F13  23        		inc	hl
1781    1F14  23        		inc	hl
1782    1F15  6E        		ld	l,(hl)
1783    1F16  97        		sub	a
1784    1F17  67        		ld	h,a
1785    1F18  7D        		ld	a,l
1786    1F19  E63F      		and	63
1787    1F1B  6F        		ld	l,a
1788    1F1C  97        		sub	a
1789    1F1D  67        		ld	h,a
1790    1F1E  E5        		push	hl
1791    1F1F  DD6E04    		ld	l,(ix+4)
1792    1F22  DD6605    		ld	h,(ix+5)
1793    1F25  23        		inc	hl
1794    1F26  4E        		ld	c,(hl)
1795    1F27  97        		sub	a
1796    1F28  47        		ld	b,a
1797    1F29  C5        		push	bc
1798    1F2A  DD6E04    		ld	l,(ix+4)
1799    1F2D  DD6605    		ld	h,(ix+5)
1800    1F30  23        		inc	hl
1801    1F31  23        		inc	hl
1802    1F32  6E        		ld	l,(hl)
1803    1F33  97        		sub	a
1804    1F34  67        		ld	h,a
1805    1F35  7D        		ld	a,l
1806    1F36  E6C0      		and	192
1807    1F38  6F        		ld	l,a
1808    1F39  97        		sub	a
1809    1F3A  67        		ld	h,a
1810    1F3B  E5        		push	hl
1811    1F3C  210200    		ld	hl,2
1812    1F3F  E5        		push	hl
1813    1F40  CD0000    		call	c.irsh
1814    1F43  E1        		pop	hl
1815    1F44  E5        		push	hl
1816    1F45  DD6E04    		ld	l,(ix+4)
1817    1F48  DD6605    		ld	h,(ix+5)
1818    1F4B  23        		inc	hl
1819    1F4C  23        		inc	hl
1820    1F4D  23        		inc	hl
1821    1F4E  6E        		ld	l,(hl)
1822    1F4F  97        		sub	a
1823    1F50  67        		ld	h,a
1824    1F51  E3        		ex	(sp),hl
1825    1F52  C1        		pop	bc
1826    1F53  09        		add	hl,bc
1827    1F54  E5        		push	hl
1828    1F55  DD6E04    		ld	l,(ix+4)
1829    1F58  DD6605    		ld	h,(ix+5)
1830    1F5B  23        		inc	hl
1831    1F5C  23        		inc	hl
1832    1F5D  23        		inc	hl
1833    1F5E  4E        		ld	c,(hl)
1834    1F5F  97        		sub	a
1835    1F60  47        		ld	b,a
1836    1F61  C5        		push	bc
1837    1F62  DD6E04    		ld	l,(ix+4)
1838    1F65  DD6605    		ld	h,(ix+5)
1839    1F68  23        		inc	hl
1840    1F69  23        		inc	hl
1841    1F6A  4E        		ld	c,(hl)
1842    1F6B  97        		sub	a
1843    1F6C  47        		ld	b,a
1844    1F6D  C5        		push	bc
1845    1F6E  DD6E04    		ld	l,(ix+4)
1846    1F71  DD6605    		ld	h,(ix+5)
1847    1F74  23        		inc	hl
1848    1F75  4E        		ld	c,(hl)
1849    1F76  97        		sub	a
1850    1F77  47        		ld	b,a
1851    1F78  C5        		push	bc
1852    1F79  217B1D    		ld	hl,L577
1853    1F7C  CD0000    		call	_printf
1854    1F7F  210C00    		ld	hl,12
1855    1F82  39        		add	hl,sp
1856    1F83  F9        		ld	sp,hl
1857                    	; 1118          printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1858                    	; 1119                 partptr[5], partptr[6], partptr[7],
1859                    	; 1120                 ((partptr[6] & 0xc0) >> 2) + partptr[7],
1860                    	; 1121                 partptr[5],
1861                    	; 1122                 partptr[6] & 0x3f);
1862    1F84  DD6E04    		ld	l,(ix+4)
1863    1F87  DD6605    		ld	h,(ix+5)
1864    1F8A  010600    		ld	bc,6
1865    1F8D  09        		add	hl,bc
1866    1F8E  6E        		ld	l,(hl)
1867    1F8F  97        		sub	a
1868    1F90  67        		ld	h,a
1869    1F91  7D        		ld	a,l
1870    1F92  E63F      		and	63
1871    1F94  6F        		ld	l,a
1872    1F95  97        		sub	a
1873    1F96  67        		ld	h,a
1874    1F97  E5        		push	hl
1875    1F98  DD6E04    		ld	l,(ix+4)
1876    1F9B  DD6605    		ld	h,(ix+5)
1877    1F9E  010500    		ld	bc,5
1878    1FA1  09        		add	hl,bc
1879    1FA2  4E        		ld	c,(hl)
1880    1FA3  97        		sub	a
1881    1FA4  47        		ld	b,a
1882    1FA5  C5        		push	bc
1883    1FA6  DD6E04    		ld	l,(ix+4)
1884    1FA9  DD6605    		ld	h,(ix+5)
1885    1FAC  010600    		ld	bc,6
1886    1FAF  09        		add	hl,bc
1887    1FB0  6E        		ld	l,(hl)
1888    1FB1  97        		sub	a
1889    1FB2  67        		ld	h,a
1890    1FB3  7D        		ld	a,l
1891    1FB4  E6C0      		and	192
1892    1FB6  6F        		ld	l,a
1893    1FB7  97        		sub	a
1894    1FB8  67        		ld	h,a
1895    1FB9  E5        		push	hl
1896    1FBA  210200    		ld	hl,2
1897    1FBD  E5        		push	hl
1898    1FBE  CD0000    		call	c.irsh
1899    1FC1  E1        		pop	hl
1900    1FC2  E5        		push	hl
1901    1FC3  DD6E04    		ld	l,(ix+4)
1902    1FC6  DD6605    		ld	h,(ix+5)
1903    1FC9  010700    		ld	bc,7
1904    1FCC  09        		add	hl,bc
1905    1FCD  6E        		ld	l,(hl)
1906    1FCE  97        		sub	a
1907    1FCF  67        		ld	h,a
1908    1FD0  E3        		ex	(sp),hl
1909    1FD1  C1        		pop	bc
1910    1FD2  09        		add	hl,bc
1911    1FD3  E5        		push	hl
1912    1FD4  DD6E04    		ld	l,(ix+4)
1913    1FD7  DD6605    		ld	h,(ix+5)
1914    1FDA  010700    		ld	bc,7
1915    1FDD  09        		add	hl,bc
1916    1FDE  4E        		ld	c,(hl)
1917    1FDF  97        		sub	a
1918    1FE0  47        		ld	b,a
1919    1FE1  C5        		push	bc
1920    1FE2  DD6E04    		ld	l,(ix+4)
1921    1FE5  DD6605    		ld	h,(ix+5)
1922    1FE8  010600    		ld	bc,6
1923    1FEB  09        		add	hl,bc
1924    1FEC  4E        		ld	c,(hl)
1925    1FED  97        		sub	a
1926    1FEE  47        		ld	b,a
1927    1FEF  C5        		push	bc
1928    1FF0  DD6E04    		ld	l,(ix+4)
1929    1FF3  DD6605    		ld	h,(ix+5)
1930    1FF6  010500    		ld	bc,5
1931    1FF9  09        		add	hl,bc
1932    1FFA  4E        		ld	c,(hl)
1933    1FFB  97        		sub	a
1934    1FFC  47        		ld	b,a
1935    1FFD  C5        		push	bc
1936    1FFE  21BD1D    		ld	hl,L5001
1937    2001  CD0000    		call	_printf
1938    2004  210C00    		ld	hl,12
1939    2007  39        		add	hl,sp
1940    2008  F9        		ld	sp,hl
1941                    	L1003:
1942                    	; 1123          }
1943                    	; 1124      /* not showing high 16 bits if 48 bit LBA */
1944                    	; 1125      lbastart = (unsigned long)partptr[8] +
1945                    	; 1126                 ((unsigned long)partptr[9] << 8) +
1946                    	; 1127                 ((unsigned long)partptr[10] << 16) +
1947                    	; 1128                 ((unsigned long)partptr[11] << 24);
1948    2009  DDE5      		push	ix
1949    200B  C1        		pop	bc
1950    200C  21F4FF    		ld	hl,65524
1951    200F  09        		add	hl,bc
1952    2010  E5        		push	hl
1953    2011  DD6E04    		ld	l,(ix+4)
1954    2014  DD6605    		ld	h,(ix+5)
1955    2017  010800    		ld	bc,8
1956    201A  09        		add	hl,bc
1957    201B  4D        		ld	c,l
1958    201C  44        		ld	b,h
1959    201D  97        		sub	a
1960    201E  320000    		ld	(c.r0),a
1961    2021  320100    		ld	(c.r0+1),a
1962    2024  0A        		ld	a,(bc)
1963    2025  320200    		ld	(c.r0+2),a
1964    2028  97        		sub	a
1965    2029  320300    		ld	(c.r0+3),a
1966    202C  210000    		ld	hl,c.r0
1967    202F  E5        		push	hl
1968    2030  DD6E04    		ld	l,(ix+4)
1969    2033  DD6605    		ld	h,(ix+5)
1970    2036  010900    		ld	bc,9
1971    2039  09        		add	hl,bc
1972    203A  4D        		ld	c,l
1973    203B  44        		ld	b,h
1974    203C  97        		sub	a
1975    203D  320000    		ld	(c.r1),a
1976    2040  320100    		ld	(c.r1+1),a
1977    2043  0A        		ld	a,(bc)
1978    2044  320200    		ld	(c.r1+2),a
1979    2047  97        		sub	a
1980    2048  320300    		ld	(c.r1+3),a
1981    204B  210000    		ld	hl,c.r1
1982    204E  E5        		push	hl
1983    204F  210800    		ld	hl,8
1984    2052  E5        		push	hl
1985    2053  CD0000    		call	c.llsh
1986    2056  CD0000    		call	c.ladd
1987    2059  DD6E04    		ld	l,(ix+4)
1988    205C  DD6605    		ld	h,(ix+5)
1989    205F  010A00    		ld	bc,10
1990    2062  09        		add	hl,bc
1991    2063  4D        		ld	c,l
1992    2064  44        		ld	b,h
1993    2065  97        		sub	a
1994    2066  320000    		ld	(c.r1),a
1995    2069  320100    		ld	(c.r1+1),a
1996    206C  0A        		ld	a,(bc)
1997    206D  320200    		ld	(c.r1+2),a
1998    2070  97        		sub	a
1999    2071  320300    		ld	(c.r1+3),a
2000    2074  210000    		ld	hl,c.r1
2001    2077  E5        		push	hl
2002    2078  211000    		ld	hl,16
2003    207B  E5        		push	hl
2004    207C  CD0000    		call	c.llsh
2005    207F  CD0000    		call	c.ladd
2006    2082  DD6E04    		ld	l,(ix+4)
2007    2085  DD6605    		ld	h,(ix+5)
2008    2088  010B00    		ld	bc,11
2009    208B  09        		add	hl,bc
2010    208C  4D        		ld	c,l
2011    208D  44        		ld	b,h
2012    208E  97        		sub	a
2013    208F  320000    		ld	(c.r1),a
2014    2092  320100    		ld	(c.r1+1),a
2015    2095  0A        		ld	a,(bc)
2016    2096  320200    		ld	(c.r1+2),a
2017    2099  97        		sub	a
2018    209A  320300    		ld	(c.r1+3),a
2019    209D  210000    		ld	hl,c.r1
2020    20A0  E5        		push	hl
2021    20A1  211800    		ld	hl,24
2022    20A4  E5        		push	hl
2023    20A5  CD0000    		call	c.llsh
2024    20A8  CD0000    		call	c.ladd
2025    20AB  CD0000    		call	c.mvl
2026    20AE  F1        		pop	af
2027                    	; 1129      lbasize = (unsigned long)partptr[12] +
2028                    	; 1130                ((unsigned long)partptr[13] << 8) +
2029                    	; 1131                ((unsigned long)partptr[14] << 16) +
2030                    	; 1132                ((unsigned long)partptr[15] << 24);
2031    20AF  DDE5      		push	ix
2032    20B1  C1        		pop	bc
2033    20B2  21F0FF    		ld	hl,65520
2034    20B5  09        		add	hl,bc
2035    20B6  E5        		push	hl
2036    20B7  DD6E04    		ld	l,(ix+4)
2037    20BA  DD6605    		ld	h,(ix+5)
2038    20BD  010C00    		ld	bc,12
2039    20C0  09        		add	hl,bc
2040    20C1  4D        		ld	c,l
2041    20C2  44        		ld	b,h
2042    20C3  97        		sub	a
2043    20C4  320000    		ld	(c.r0),a
2044    20C7  320100    		ld	(c.r0+1),a
2045    20CA  0A        		ld	a,(bc)
2046    20CB  320200    		ld	(c.r0+2),a
2047    20CE  97        		sub	a
2048    20CF  320300    		ld	(c.r0+3),a
2049    20D2  210000    		ld	hl,c.r0
2050    20D5  E5        		push	hl
2051    20D6  DD6E04    		ld	l,(ix+4)
2052    20D9  DD6605    		ld	h,(ix+5)
2053    20DC  010D00    		ld	bc,13
2054    20DF  09        		add	hl,bc
2055    20E0  4D        		ld	c,l
2056    20E1  44        		ld	b,h
2057    20E2  97        		sub	a
2058    20E3  320000    		ld	(c.r1),a
2059    20E6  320100    		ld	(c.r1+1),a
2060    20E9  0A        		ld	a,(bc)
2061    20EA  320200    		ld	(c.r1+2),a
2062    20ED  97        		sub	a
2063    20EE  320300    		ld	(c.r1+3),a
2064    20F1  210000    		ld	hl,c.r1
2065    20F4  E5        		push	hl
2066    20F5  210800    		ld	hl,8
2067    20F8  E5        		push	hl
2068    20F9  CD0000    		call	c.llsh
2069    20FC  CD0000    		call	c.ladd
2070    20FF  DD6E04    		ld	l,(ix+4)
2071    2102  DD6605    		ld	h,(ix+5)
2072    2105  010E00    		ld	bc,14
2073    2108  09        		add	hl,bc
2074    2109  4D        		ld	c,l
2075    210A  44        		ld	b,h
2076    210B  97        		sub	a
2077    210C  320000    		ld	(c.r1),a
2078    210F  320100    		ld	(c.r1+1),a
2079    2112  0A        		ld	a,(bc)
2080    2113  320200    		ld	(c.r1+2),a
2081    2116  97        		sub	a
2082    2117  320300    		ld	(c.r1+3),a
2083    211A  210000    		ld	hl,c.r1
2084    211D  E5        		push	hl
2085    211E  211000    		ld	hl,16
2086    2121  E5        		push	hl
2087    2122  CD0000    		call	c.llsh
2088    2125  CD0000    		call	c.ladd
2089    2128  DD6E04    		ld	l,(ix+4)
2090    212B  DD6605    		ld	h,(ix+5)
2091    212E  010F00    		ld	bc,15
2092    2131  09        		add	hl,bc
2093    2132  4D        		ld	c,l
2094    2133  44        		ld	b,h
2095    2134  97        		sub	a
2096    2135  320000    		ld	(c.r1),a
2097    2138  320100    		ld	(c.r1+1),a
2098    213B  0A        		ld	a,(bc)
2099    213C  320200    		ld	(c.r1+2),a
2100    213F  97        		sub	a
2101    2140  320300    		ld	(c.r1+3),a
2102    2143  210000    		ld	hl,c.r1
2103    2146  E5        		push	hl
2104    2147  211800    		ld	hl,24
2105    214A  E5        		push	hl
2106    214B  CD0000    		call	c.llsh
2107    214E  CD0000    		call	c.ladd
2108    2151  CD0000    		call	c.mvl
2109    2154  F1        		pop	af
2110                    	; 1133      printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
2111    2155  DD66F7    		ld	h,(ix-9)
2112    2158  DD6EF6    		ld	l,(ix-10)
2113    215B  E5        		push	hl
2114    215C  DD66F5    		ld	h,(ix-11)
2115    215F  DD6EF4    		ld	l,(ix-12)
2116    2162  E5        		push	hl
2117    2163  DD66F7    		ld	h,(ix-9)
2118    2166  DD6EF6    		ld	l,(ix-10)
2119    2169  E5        		push	hl
2120    216A  DD66F5    		ld	h,(ix-11)
2121    216D  DD6EF4    		ld	l,(ix-12)
2122    2170  E5        		push	hl
2123    2171  21FC1D    		ld	hl,L5101
2124    2174  CD0000    		call	_printf
2125    2177  F1        		pop	af
2126    2178  F1        		pop	af
2127    2179  F1        		pop	af
2128    217A  F1        		pop	af
2129                    	; 1134      printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
2130                    	; 1135             lbasize, lbasize, lbasize >> 11);
2131    217B  DDE5      		push	ix
2132    217D  C1        		pop	bc
2133    217E  21F0FF    		ld	hl,65520
2134    2181  09        		add	hl,bc
2135    2182  CD0000    		call	c.0mvf
2136    2185  210000    		ld	hl,c.r0
2137    2188  E5        		push	hl
2138    2189  210B00    		ld	hl,11
2139    218C  E5        		push	hl
2140    218D  CD0000    		call	c.ulrsh
2141    2190  E1        		pop	hl
2142    2191  23        		inc	hl
2143    2192  23        		inc	hl
2144    2193  4E        		ld	c,(hl)
2145    2194  23        		inc	hl
2146    2195  46        		ld	b,(hl)
2147    2196  C5        		push	bc
2148    2197  2B        		dec	hl
2149    2198  2B        		dec	hl
2150    2199  2B        		dec	hl
2151    219A  4E        		ld	c,(hl)
2152    219B  23        		inc	hl
2153    219C  46        		ld	b,(hl)
2154    219D  C5        		push	bc
2155    219E  DD66F3    		ld	h,(ix-13)
2156    21A1  DD6EF2    		ld	l,(ix-14)
2157    21A4  E5        		push	hl
2158    21A5  DD66F1    		ld	h,(ix-15)
2159    21A8  DD6EF0    		ld	l,(ix-16)
2160    21AB  E5        		push	hl
2161    21AC  DD66F3    		ld	h,(ix-13)
2162    21AF  DD6EF2    		ld	l,(ix-14)
2163    21B2  E5        		push	hl
2164    21B3  DD66F1    		ld	h,(ix-15)
2165    21B6  DD6EF0    		ld	l,(ix-16)
2166    21B9  E5        		push	hl
2167    21BA  21201E    		ld	hl,L5201
2168    21BD  CD0000    		call	_printf
2169    21C0  210C00    		ld	hl,12
2170    21C3  39        		add	hl,sp
2171    21C4  F9        		ld	sp,hl
2172                    	; 1136      if (partptr[4] == 0xee)
2173    21C5  DD6E04    		ld	l,(ix+4)
2174    21C8  DD6605    		ld	h,(ix+5)
2175    21CB  23        		inc	hl
2176    21CC  23        		inc	hl
2177    21CD  23        		inc	hl
2178    21CE  23        		inc	hl
2179    21CF  7E        		ld	a,(hl)
2180    21D0  FEEE      		cp	238
2181    21D2  2011      		jr	nz,L1103
2182                    	; 1137          sdgpthdr(lbastart);
2183    21D4  DD66F7    		ld	h,(ix-9)
2184    21D7  DD6EF6    		ld	l,(ix-10)
2185    21DA  E5        		push	hl
2186    21DB  DD66F5    		ld	h,(ix-11)
2187    21DE  DD6EF4    		ld	l,(ix-12)
2188    21E1  CD031B    		call	_sdgpthdr
2189    21E4  F1        		pop	af
2190                    	L1103:
2191                    	; 1138      }
2192    21E5  C30000    		jp	c.rets
2193                    	L221:
2194    21E8  00        		.byte	0
2195    21E9  00        		.byte	0
2196    21EA  00        		.byte	0
2197    21EB  00        		.byte	0
2198                    	; 1139  
2199                    	; 1140  /* read MBR partition information */
2200                    	; 1141  void sdmbrpart()
2201                    	; 1142      {
2202                    	_sdmbrpart:
2203    21EC  CD0000    		call	c.savs0
2204    21EF  21F6FF    		ld	hl,65526
2205    21F2  39        		add	hl,sp
2206    21F3  F9        		ld	sp,hl
2207                    	; 1143      int partidx;  /* partition index 1 - 4 */
2208                    	; 1144      unsigned char *entp; /* pointer to partition entry */
2209                    	; 1145  
2210                    	; 1146  #ifdef SDTEST
2211                    	; 1147      printf("Read MBR\n");
2212                    	; 1148  #endif
2213                    	; 1149      if (!sdread(sdrdbuf, 0))
2214    21F4  21EB21    		ld	hl,L221+3
2215    21F7  46        		ld	b,(hl)
2216    21F8  2B        		dec	hl
2217    21F9  4E        		ld	c,(hl)
2218    21FA  C5        		push	bc
2219    21FB  2B        		dec	hl
2220    21FC  46        		ld	b,(hl)
2221    21FD  2B        		dec	hl
2222    21FE  4E        		ld	c,(hl)
2223    21FF  C5        		push	bc
2224    2200  213200    		ld	hl,_sdrdbuf
2225    2203  CDE10C    		call	_sdread
2226    2206  F1        		pop	af
2227    2207  F1        		pop	af
2228    2208  79        		ld	a,c
2229    2209  B0        		or	b
2230    220A  2003      		jr	nz,L1203
2231                    	; 1150          {
2232                    	; 1151  #ifdef SDTEST
2233                    	; 1152          printf("  can't read MBR sector\n");
2234                    	; 1153  #endif
2235                    	; 1154          return;
2236    220C  C30000    		jp	c.rets0
2237                    	L1203:
2238                    	; 1155          }
2239                    	; 1156      curblkno = 0;
2240                    	; 1157      curblkok = YES;
2241    220F  210100    		ld	hl,1
2242                    	;    1  /*  z80boot.c
2243                    	;    2   *
2244                    	;    3   *  Boot code for my DIY Z80 Computer. This
2245                    	;    4   *  program is compiled with Whitesmiths/COSMIC
2246                    	;    5   *  C compiler for Z80.
2247                    	;    6   *
2248                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
2249                    	;    8   *
2250                    	;    9   *  Initializes the hardware and detects the
2251                    	;   10   *  presence and partitioning of an attached SD card.
2252                    	;   11   *
2253                    	;   12   *  You are free to use, modify, and redistribute
2254                    	;   13   *  this source code. No warranties are given.
2255                    	;   14   *  Hastily Cobbled Together 2021 and 2022
2256                    	;   15   *  by Hans-Ake Lund
2257                    	;   16   *
2258                    	;   17   */
2259                    	;   18  
2260                    	;   19  #include <std.h>
2261                    	;   20  #include "z80computer.h"
2262                    	;   21  #include "builddate.h"
2263                    	;   22  #include "progtype.h"
2264                    	;   23  
2265                    	;   24  #ifdef SDTEST
2266                    	;   25  #define PRGNAME "\nz80sdtest "
2267                    	;   26  #else
2268                    	;   27  #define PRGNAME "\nz80boot "
2269                    	;   28  #endif
2270                    	;   29  #define VERSION "version 0.4, "
2271                    	;   30  
2272                    	;   31  /* Response length in bytes
2273                    	;   32   */
2274                    	;   33  #define R1_LEN 1
2275                    	;   34  #define R3_LEN 5
2276                    	;   35  #define R7_LEN 5
2277                    	;   36  
2278                    	;   37  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
2279                    	;   38   * (The CRC7 byte in the tables below are only for information,
2280                    	;   39   * it is calculated by the sdcommand routine.)
2281                    	;   40   */
2282                    	;   41  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
2283                    	;   42  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
2284                    	;   43  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
2285                    	;   44  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
2286                    	;   45  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
2287                    	;   46  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
2288                    	;   47  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
2289                    	;   48  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
2290                    	;   49  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
2291                    	;   50  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
2292                    	;   51  
2293                    	;   52  /* Buffers
2294                    	;   53   */
2295                    	;   54  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
2296                    	;   55  
2297                    	;   56  unsigned char ocrreg[4];     /* SD card OCR register */
2298                    	;   57  unsigned char cidreg[16];    /* SD card CID register */
2299                    	;   58  unsigned char csdreg[16];    /* SD card CSD register */
2300                    	;   59  
2301                    	;   60  /* Variables
2302                    	;   61   */
2303                    	;   62  int curblkok;  /* if YES curblockno is read into buffer */
2304                    	;   63  int sdinitok;  /* SD card initialized and ready */
2305                    	;   64  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
2306                    	;   65  unsigned long blkmult;   /* block address multiplier */
2307                    	;   66  unsigned long curblkno;  /* block in buffer if curblkok == YES */
2308                    	;   67  
2309                    	;   68  /* CRC routines from:
2310                    	;   69   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
2311                    	;   70   */
2312                    	;   71  
2313                    	;   72  /*
2314                    	;   73  // Calculate CRC7
2315                    	;   74  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
2316                    	;   75  // input:
2317                    	;   76  //   crcIn - the CRC before (0 for first step)
2318                    	;   77  //   data - byte for CRC calculation
2319                    	;   78  // return: the new CRC7
2320                    	;   79  */
2321                    	;   80  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
2322                    	;   81      {
2323                    	;   82      const unsigned char g = 0x89;
2324                    	;   83      unsigned char i;
2325                    	;   84  
2326                    	;   85      crcIn ^= data;
2327                    	;   86      for (i = 0; i < 8; i++)
2328                    	;   87          {
2329                    	;   88          if (crcIn & 0x80) crcIn ^= g;
2330                    	;   89          crcIn <<= 1;
2331                    	;   90          }
2332                    	;   91  
2333                    	;   92      return crcIn;
2334                    	;   93      }
2335                    	;   94  
2336                    	;   95  /*
2337                    	;   96  // Calculate CRC16 CCITT
2338                    	;   97  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
2339                    	;   98  // input:
2340                    	;   99  //   crcIn - the CRC before (0 for rist step)
2341                    	;  100  //   data - byte for CRC calculation
2342                    	;  101  // return: the CRC16 value
2343                    	;  102  */
2344                    	;  103  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
2345                    	;  104      {
2346                    	;  105      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
2347                    	;  106      crcIn ^=  data;
2348                    	;  107      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
2349                    	;  108      crcIn ^= (crcIn << 8) << 4;
2350                    	;  109      crcIn ^= ((crcIn & 0xff) << 4) << 1;
2351                    	;  110  
2352                    	;  111      return crcIn;
2353                    	;  112      }
2354                    	;  113  
2355                    	;  114  /* Send command to SD card and recieve answer.
2356                    	;  115   * A command is 5 bytes long and is followed by
2357                    	;  116   * a CRC7 checksum byte.
2358                    	;  117   * Returns a pointer to the response
2359                    	;  118   * or 0 if no response start bit found.
2360                    	;  119   */
2361                    	;  120  unsigned char *sdcommand(unsigned char *sdcmdp,
2362                    	;  121                           unsigned char *recbuf, int recbytes)
2363                    	;  122      {
2364                    	;  123      int searchn;  /* byte counter to search for response */
2365                    	;  124      int sdcbytes; /* byte counter for bytes to send */
2366                    	;  125      unsigned char *retptr; /* pointer used to store response */
2367                    	;  126      unsigned char rbyte;   /* recieved byte */
2368                    	;  127      unsigned char crc = 0; /* calculated CRC7 */
2369                    	;  128  
2370                    	;  129      /* send 8*2 clockpules */
2371                    	;  130      spiio(0xff);
2372                    	;  131      spiio(0xff);
2373                    	;  132      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
2374                    	;  133          {
2375                    	;  134          crc = CRC7_one(crc, *sdcmdp);
2376                    	;  135          spiio(*sdcmdp++);
2377                    	;  136          }
2378                    	;  137      spiio(crc | 0x01);
2379                    	;  138      /* search for recieved byte with start bit
2380                    	;  139         for a maximum of 10 recieved bytes  */
2381                    	;  140      for (searchn = 10; 0 < searchn; searchn--)
2382                    	;  141          {
2383                    	;  142          rbyte = spiio(0xff);
2384                    	;  143          if ((rbyte & 0x80) == 0)
2385                    	;  144              break;
2386                    	;  145          }
2387                    	;  146      if (searchn == 0) /* no start bit found */
2388                    	;  147          return (NO);
2389                    	;  148      retptr = recbuf;
2390                    	;  149      *retptr++ = rbyte;
2391                    	;  150      for (; 1 < recbytes; recbytes--) /* recieve bytes */
2392                    	;  151          *retptr++ = spiio(0xff);
2393                    	;  152      return (recbuf);
2394                    	;  153      }
2395                    	;  154  
2396                    	;  155  /* Initialise SD card interface
2397                    	;  156   *
2398                    	;  157   * returns YES if ok and NO if not ok
2399                    	;  158   *
2400                    	;  159   * References:
2401                    	;  160   *   https://www.sdcard.org/downloads/pls/
2402                    	;  161   *      Physical Layer Simplified Specification version 8.0
2403                    	;  162   *
2404                    	;  163   * A nice flowchart how to initialize:
2405                    	;  164   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
2406                    	;  165   *
2407                    	;  166   */
2408                    	;  167  int sdinit()
2409                    	;  168      {
2410                    	;  169      int nbytes;  /* byte counter */
2411                    	;  170      int tries;   /* tries to get to active state or searching for data  */
2412                    	;  171      int wtloop;  /* timer loop when trying to enter active state */
2413                    	;  172      unsigned char cmdbuf[5];   /* buffer to build command in */
2414                    	;  173      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2415                    	;  174      unsigned char *statptr;    /* pointer to returned status from SD command */
2416                    	;  175      unsigned char crc;         /* crc register for CID and CSD */
2417                    	;  176      unsigned char rbyte;       /* recieved byte */
2418                    	;  177  #ifdef SDTEST
2419                    	;  178      unsigned char *prtptr;     /* for debug printing */
2420                    	;  179  #endif
2421                    	;  180  
2422                    	;  181      ledon();
2423                    	;  182      spideselect();
2424                    	;  183      sdinitok = NO;
2425                    	;  184  
2426                    	;  185      /* start to generate 9*8 clock pulses with not selected SD card */
2427                    	;  186      for (nbytes = 9; 0 < nbytes; nbytes--)
2428                    	;  187          spiio(0xff);
2429                    	;  188  #ifdef SDTEST
2430                    	;  189      printf("\nSent 8*8 (72) clock pulses, select not active\n");
2431                    	;  190  #endif
2432                    	;  191      spiselect();
2433                    	;  192  
2434                    	;  193      /* CMD0: GO_IDLE_STATE */
2435                    	;  194      memcpy(cmdbuf, cmd0, 5);
2436                    	;  195      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2437                    	;  196  #ifdef SDTEST
2438                    	;  197      if (!statptr)
2439                    	;  198          printf("CMD0: no response\n");
2440                    	;  199      else
2441                    	;  200          printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
2442                    	;  201  #endif
2443                    	;  202      if (!statptr)
2444                    	;  203          {
2445                    	;  204          spideselect();
2446                    	;  205          ledoff();
2447                    	;  206          return (NO);
2448                    	;  207          }
2449                    	;  208      /* CMD8: SEND_IF_COND */
2450                    	;  209      memcpy(cmdbuf, cmd8, 5);
2451                    	;  210      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
2452                    	;  211  #ifdef SDTEST
2453                    	;  212      if (!statptr)
2454                    	;  213          printf("CMD8: no response\n");
2455                    	;  214      else
2456                    	;  215          {
2457                    	;  216          printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
2458                    	;  217                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2459                    	;  218          if (!(statptr[0] & 0xfe)) /* no error */
2460                    	;  219              {
2461                    	;  220              if (statptr[4] == 0xaa)
2462                    	;  221                  printf("echo back ok, ");
2463                    	;  222              else
2464                    	;  223                  printf("invalid echo back\n");
2465                    	;  224              }
2466                    	;  225          }
2467                    	;  226  #endif
2468                    	;  227      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
2469                    	;  228          {
2470                    	;  229          sdver2 = NO;
2471                    	;  230  #ifdef SDTEST
2472                    	;  231          printf("probably SD ver. 1\n");
2473                    	;  232  #endif
2474                    	;  233          }
2475                    	;  234      else
2476                    	;  235          {
2477                    	;  236          sdver2 = YES;
2478                    	;  237          if (statptr[4] != 0xaa) /* but invalid echo back */
2479                    	;  238              {
2480                    	;  239              spideselect();
2481                    	;  240              ledoff();
2482                    	;  241              return (NO);
2483                    	;  242              }
2484                    	;  243  #ifdef SDTEST
2485                    	;  244          printf("SD ver 2\n");
2486                    	;  245  #endif
2487                    	;  246          }
2488                    	;  247  
2489                    	;  248      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
2490                    	;  249      for (tries = 0; tries < 20; tries++)
2491                    	;  250          {
2492                    	;  251          memcpy(cmdbuf, cmd55, 5);
2493                    	;  252          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2494                    	;  253  #ifdef SDTEST
2495                    	;  254          if (!statptr)
2496                    	;  255              printf("CMD55: no response\n");
2497                    	;  256          else
2498                    	;  257              printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
2499                    	;  258  #endif
2500                    	;  259          if (!statptr)
2501                    	;  260              {
2502                    	;  261              spideselect();
2503                    	;  262              ledoff();
2504                    	;  263              return (NO);
2505                    	;  264              }
2506                    	;  265          memcpy(cmdbuf, acmd41, 5);
2507                    	;  266          if (sdver2)
2508                    	;  267              cmdbuf[1] = 0x40;
2509                    	;  268          else
2510                    	;  269              cmdbuf[1] = 0x00;
2511                    	;  270          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2512                    	;  271  #ifdef SDTEST
2513                    	;  272          if (!statptr)
2514                    	;  273              printf("ACMD41: no response\n");
2515                    	;  274          else
2516                    	;  275              printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
2517                    	;  276                     statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
2518                    	;  277  #endif
2519                    	;  278          if (!statptr)
2520                    	;  279              {
2521                    	;  280              spideselect();
2522                    	;  281              ledoff();
2523                    	;  282              return (NO);
2524                    	;  283              }
2525                    	;  284          if (statptr[0] == 0x00) /* now the SD card is ready */
2526                    	;  285              {
2527                    	;  286              break;
2528                    	;  287              }
2529                    	;  288          for (wtloop = 0; wtloop < tries * 100; wtloop++)
2530                    	;  289              ; /* wait loop, time increasing for each try */
2531                    	;  290          }
2532                    	;  291  
2533                    	;  292      /* CMD58: READ_OCR */
2534                    	;  293      /* According to the flow chart this should not work
2535                    	;  294         for SD ver. 1 but the response is ok anyway
2536                    	;  295         all tested SD cards  */
2537                    	;  296      memcpy(cmdbuf, cmd58, 5);
2538                    	;  297      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
2539                    	;  298  #ifdef SDTEST
2540                    	;  299      if (!statptr)
2541                    	;  300          printf("CMD58: no response\n");
2542                    	;  301      else
2543                    	;  302          printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
2544                    	;  303                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2545                    	;  304  #endif
2546                    	;  305      if (!statptr)
2547                    	;  306          {
2548                    	;  307          spideselect();
2549                    	;  308          ledoff();
2550                    	;  309          return (NO);
2551                    	;  310          }
2552                    	;  311      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
2553                    	;  312      blkmult = 1; /* assume block address */
2554                    	;  313      if (ocrreg[0] & 0x80)
2555                    	;  314          {
2556                    	;  315          /* SD Ver.2+ */
2557                    	;  316          if (!(ocrreg[0] & 0x40))
2558                    	;  317              {
2559                    	;  318              /* SD Ver.2+, Byte address */
2560                    	;  319              blkmult = 512;
2561                    	;  320              }
2562                    	;  321          }
2563                    	;  322  
2564                    	;  323      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
2565                    	;  324      if (blkmult == 512)
2566                    	;  325          {
2567                    	;  326          memcpy(cmdbuf, cmd16, 5);
2568                    	;  327          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2569                    	;  328  #ifdef SDTEST
2570                    	;  329          if (!statptr)
2571                    	;  330              printf("CMD16: no response\n");
2572                    	;  331          else
2573                    	;  332              printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
2574                    	;  333                  statptr[0]);
2575                    	;  334  #endif
2576                    	;  335          if (!statptr)
2577                    	;  336              {
2578                    	;  337              spideselect();
2579                    	;  338              ledoff();
2580                    	;  339              return (NO);
2581                    	;  340              }
2582                    	;  341          }
2583                    	;  342      /* Register information:
2584                    	;  343       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
2585                    	;  344       */
2586                    	;  345  
2587                    	;  346      /* CMD10: SEND_CID */
2588                    	;  347      memcpy(cmdbuf, cmd10, 5);
2589                    	;  348      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2590                    	;  349  #ifdef SDTEST
2591                    	;  350      if (!statptr)
2592                    	;  351          printf("CMD10: no response\n");
2593                    	;  352      else
2594                    	;  353          printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
2595                    	;  354  #endif
2596                    	;  355      if (!statptr)
2597                    	;  356          {
2598                    	;  357          spideselect();
2599                    	;  358          ledoff();
2600                    	;  359          return (NO);
2601                    	;  360          }
2602                    	;  361      /* looking for 0xfe that is the byte before data */
2603                    	;  362      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2604                    	;  363          ;
2605                    	;  364      if (tries == 0) /* tried too many times */
2606                    	;  365          {
2607                    	;  366  #ifdef SDTEST
2608                    	;  367          printf("  No data found\n");
2609                    	;  368  #endif
2610                    	;  369          spideselect();
2611                    	;  370          ledoff();
2612                    	;  371          return (NO);
2613                    	;  372          }
2614                    	;  373      else
2615                    	;  374          {
2616                    	;  375          crc = 0;
2617                    	;  376          for (nbytes = 0; nbytes < 15; nbytes++)
2618                    	;  377              {
2619                    	;  378              rbyte = spiio(0xff);
2620                    	;  379              cidreg[nbytes] = rbyte;
2621                    	;  380              crc = CRC7_one(crc, rbyte);
2622                    	;  381              }
2623                    	;  382          cidreg[15] = spiio(0xff);
2624                    	;  383          crc |= 0x01;
2625                    	;  384          /* some SD cards need additional clock pulses */
2626                    	;  385          for (nbytes = 9; 0 < nbytes; nbytes--)
2627                    	;  386              spiio(0xff);
2628                    	;  387  #ifdef SDTEST
2629                    	;  388          prtptr = &cidreg[0];
2630                    	;  389          printf("  CID: [");
2631                    	;  390          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2632                    	;  391              printf("%02x ", *prtptr);
2633                    	;  392          prtptr = &cidreg[0];
2634                    	;  393          printf("\b] |");
2635                    	;  394          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2636                    	;  395              {
2637                    	;  396              if ((' ' <= *prtptr) && (*prtptr < 127))
2638                    	;  397                  putchar(*prtptr);
2639                    	;  398              else
2640                    	;  399                  putchar('.');
2641                    	;  400              }
2642                    	;  401          printf("|\n");
2643                    	;  402          if (crc == cidreg[15])
2644                    	;  403              {
2645                    	;  404              printf("CRC7 ok: [%02x]\n", crc);
2646                    	;  405              }
2647                    	;  406          else
2648                    	;  407              {
2649                    	;  408              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2650                    	;  409                  crc, cidreg[15]);
2651                    	;  410              /* could maybe return failure here */
2652                    	;  411              }
2653                    	;  412  #endif
2654                    	;  413          }
2655                    	;  414  
2656                    	;  415      /* CMD9: SEND_CSD */
2657                    	;  416      memcpy(cmdbuf, cmd9, 5);
2658                    	;  417      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2659                    	;  418  #ifdef SDTEST
2660                    	;  419      if (!statptr)
2661                    	;  420          printf("CMD9: no response\n");
2662                    	;  421      else
2663                    	;  422          printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
2664                    	;  423  #endif
2665                    	;  424      if (!statptr)
2666                    	;  425          {
2667                    	;  426          spideselect();
2668                    	;  427          ledoff();
2669                    	;  428          return (NO);
2670                    	;  429          }
2671                    	;  430      /* looking for 0xfe that is the byte before data */
2672                    	;  431      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2673                    	;  432          ;
2674                    	;  433      if (tries == 0) /* tried too many times */
2675                    	;  434          {
2676                    	;  435  #ifdef SDTEST
2677                    	;  436          printf("  No data found\n");
2678                    	;  437  #endif
2679                    	;  438          return (NO);
2680                    	;  439          }
2681                    	;  440      else
2682                    	;  441          {
2683                    	;  442          crc = 0;
2684                    	;  443          for (nbytes = 0; nbytes < 15; nbytes++)
2685                    	;  444              {
2686                    	;  445              rbyte = spiio(0xff);
2687                    	;  446              csdreg[nbytes] = rbyte;
2688                    	;  447              crc = CRC7_one(crc, rbyte);
2689                    	;  448              }
2690                    	;  449          csdreg[15] = spiio(0xff);
2691                    	;  450          crc |= 0x01;
2692                    	;  451          /* some SD cards need additional clock pulses */
2693                    	;  452          for (nbytes = 9; 0 < nbytes; nbytes--)
2694                    	;  453              spiio(0xff);
2695                    	;  454  #ifdef SDTEST
2696                    	;  455          prtptr = &csdreg[0];
2697                    	;  456          printf("  CSD: [");
2698                    	;  457          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2699                    	;  458              printf("%02x ", *prtptr);
2700                    	;  459          prtptr = &csdreg[0];
2701                    	;  460          printf("\b] |");
2702                    	;  461          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2703                    	;  462              {
2704                    	;  463              if ((' ' <= *prtptr) && (*prtptr < 127))
2705                    	;  464                  putchar(*prtptr);
2706                    	;  465              else
2707                    	;  466                  putchar('.');
2708                    	;  467              }
2709                    	;  468          printf("|\n");
2710                    	;  469          if (crc == csdreg[15])
2711                    	;  470              {
2712                    	;  471              printf("CRC7 ok: [%02x]\n", crc);
2713                    	;  472              }
2714                    	;  473          else
2715                    	;  474              {
2716                    	;  475              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2717                    	;  476                  crc, csdreg[15]);
2718                    	;  477              /* could maybe return failure here */
2719                    	;  478              }
2720                    	;  479  #endif
2721                    	;  480          }
2722                    	;  481  
2723                    	;  482      for (nbytes = 9; 0 < nbytes; nbytes--)
2724                    	;  483          spiio(0xff);
2725                    	;  484  #ifdef SDTEST
2726                    	;  485      printf("Sent 9*8 (72) clock pulses, select active\n");
2727                    	;  486  #endif
2728                    	;  487  
2729                    	;  488      sdinitok = YES;
2730                    	;  489  
2731                    	;  490      spideselect();
2732                    	;  491      ledoff();
2733                    	;  492  
2734                    	;  493      return (YES);
2735                    	;  494      }
2736                    	;  495  
2737                    	;  496  /* print OCR, CID and CSD registers*/
2738                    	;  497  void sdprtreg()
2739                    	;  498      {
2740                    	;  499      unsigned int n;
2741                    	;  500      unsigned int csize;
2742                    	;  501      unsigned long devsize;
2743                    	;  502      unsigned long capacity;
2744                    	;  503  
2745                    	;  504      if (!sdinitok)
2746                    	;  505          {
2747                    	;  506          printf("SD card not initialized\n");
2748                    	;  507          return;
2749                    	;  508          }
2750                    	;  509      printf("SD card information:");
2751                    	;  510      if (ocrreg[0] & 0x80)
2752                    	;  511          {
2753                    	;  512          if (ocrreg[0] & 0x40)
2754                    	;  513              printf("  SD card ver. 2+, Block address\n");
2755                    	;  514          else
2756                    	;  515              {
2757                    	;  516              if (sdver2)
2758                    	;  517                  printf("  SD card ver. 2+, Byte address\n");
2759                    	;  518              else
2760                    	;  519                  printf("  SD card ver. 1, Byte address\n");
2761                    	;  520              }
2762                    	;  521          }
2763                    	;  522      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
2764                    	;  523      printf("OEM ID: %.2s, ", &cidreg[1]);
2765                    	;  524      printf("Product name: %.5s\n", &cidreg[3]);
2766                    	;  525      printf("  Product revision: %d.%d, ",
2767                    	;  526             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
2768                    	;  527      printf("Serial number: %lu\n",
2769                    	;  528             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
2770                    	;  529      printf("  Manufacturing date: %d-%d, ",
2771                    	;  530             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2772                    	;  531      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
2773                    	;  532          {
2774                    	;  533          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2775                    	;  534          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2776                    	;  535                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2777                    	;  536          capacity = (unsigned long) csize << (n-10);
2778                    	;  537          printf("Device capacity: %lu MByte\n", capacity >> 10);
2779                    	;  538          }
2780                    	;  539      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
2781                    	;  540          {
2782                    	;  541          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2783                    	;  542                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2784                    	;  543          capacity = devsize << 9;
2785                    	;  544          printf("Device capacity: %lu MByte\n", capacity >> 10);
2786                    	;  545          }
2787                    	;  546      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
2788                    	;  547          {
2789                    	;  548          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2790                    	;  549                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2791                    	;  550          capacity = devsize << 9;
2792                    	;  551          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
2793                    	;  552          }
2794                    	;  553  
2795                    	;  554  #ifdef SDTEST
2796                    	;  555  
2797                    	;  556      printf("--------------------------------------\n");
2798                    	;  557      printf("OCR register:\n");
2799                    	;  558      if (ocrreg[2] & 0x80)
2800                    	;  559          printf("2.7-2.8V (bit 15) ");
2801                    	;  560      if (ocrreg[1] & 0x01)
2802                    	;  561          printf("2.8-2.9V (bit 16) ");
2803                    	;  562      if (ocrreg[1] & 0x02)
2804                    	;  563          printf("2.9-3.0V (bit 17) ");
2805                    	;  564      if (ocrreg[1] & 0x04)
2806                    	;  565          printf("3.0-3.1V (bit 18) \n");
2807                    	;  566      if (ocrreg[1] & 0x08)
2808                    	;  567          printf("3.1-3.2V (bit 19) ");
2809                    	;  568      if (ocrreg[1] & 0x10)
2810                    	;  569          printf("3.2-3.3V (bit 20) ");
2811                    	;  570      if (ocrreg[1] & 0x20)
2812                    	;  571          printf("3.3-3.4V (bit 21) ");
2813                    	;  572      if (ocrreg[1] & 0x40)
2814                    	;  573          printf("3.4-3.5V (bit 22) \n");
2815                    	;  574      if (ocrreg[1] & 0x80)
2816                    	;  575          printf("3.5-3.6V (bit 23) \n");
2817                    	;  576      if (ocrreg[0] & 0x01)
2818                    	;  577          printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
2819                    	;  578      if (ocrreg[0] & 0x08)
2820                    	;  579          printf("Over 2TB support Status (CO2T) (bit 27) set\n");
2821                    	;  580      if (ocrreg[0] & 0x20)
2822                    	;  581          printf("UHS-II Card Status (bit 29) set ");
2823                    	;  582      if (ocrreg[0] & 0x80)
2824                    	;  583          {
2825                    	;  584          if (ocrreg[0] & 0x40)
2826                    	;  585              {
2827                    	;  586              printf("Card Capacity Status (CCS) (bit 30) set\n");
2828                    	;  587              printf("  SD Ver.2+, Block address");
2829                    	;  588              }
2830                    	;  589          else
2831                    	;  590              {
2832                    	;  591              printf("Card Capacity Status (CCS) (bit 30) not set\n");
2833                    	;  592              if (sdver2)
2834                    	;  593                  printf("  SD Ver.2+, Byte address");
2835                    	;  594              else
2836                    	;  595                  printf("  SD Ver.1, Byte address");
2837                    	;  596              }
2838                    	;  597          printf("\nCard power up status bit (busy) (bit 31) set\n");
2839                    	;  598          }
2840                    	;  599      else
2841                    	;  600          {
2842                    	;  601          printf("\nCard power up status bit (busy) (bit 31) not set.\n");
2843                    	;  602          printf("  This bit is not set if the card has not finished the power up routine.\n");
2844                    	;  603          }
2845                    	;  604      printf("--------------------------------------\n");
2846                    	;  605      printf("CID register:\n");
2847                    	;  606      printf("MID: 0x%02x, ", cidreg[0]);
2848                    	;  607      printf("OID: %.2s, ", &cidreg[1]);
2849                    	;  608      printf("PNM: %.5s, ", &cidreg[3]);
2850                    	;  609      printf("PRV: %d.%d, ",
2851                    	;  610             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
2852                    	;  611      printf("PSN: %lu, ",
2853                    	;  612             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
2854                    	;  613      printf("MDT: %d-%d\n",
2855                    	;  614             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2856                    	;  615      printf("--------------------------------------\n");
2857                    	;  616      printf("CSD register:\n");
2858                    	;  617      if ((csdreg[0] & 0xc0) == 0x00)
2859                    	;  618          {
2860                    	;  619          printf("CSD Version 1.0, Standard Capacity\n");
2861                    	;  620          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2862                    	;  621          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2863                    	;  622                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2864                    	;  623          capacity = (unsigned long) csize << (n-10);
2865                    	;  624          printf(" Device capacity: %lu KByte, %lu MByte\n",
2866                    	;  625                 capacity, capacity >> 10);
2867                    	;  626          }
2868                    	;  627      if ((csdreg[0] & 0xc0) == 0x40)
2869                    	;  628          {
2870                    	;  629          printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
2871                    	;  630          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2872                    	;  631                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2873                    	;  632          capacity = devsize << 9;
2874                    	;  633          printf(" Device capacity: %lu KByte, %lu MByte\n",
2875                    	;  634                 capacity, capacity >> 10);
2876                    	;  635          }
2877                    	;  636      if ((csdreg[0] & 0xc0) == 0x80)
2878                    	;  637          {
2879                    	;  638          printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
2880                    	;  639          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2881                    	;  640                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2882                    	;  641          capacity = devsize << 9;
2883                    	;  642          printf(" Device capacity: %lu KByte, %lu MByte\n",
2884                    	;  643                 capacity, capacity >> 10);
2885                    	;  644          }
2886                    	;  645      printf("--------------------------------------\n");
2887                    	;  646  
2888                    	;  647  #endif /* SDTEST */
2889                    	;  648  
2890                    	;  649      }
2891                    	;  650  
2892                    	;  651  /* Read data block of 512 bytes to buffer
2893                    	;  652   * Returns YES if ok or NO if error
2894                    	;  653   */
2895                    	;  654  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
2896                    	;  655      {
2897                    	;  656      unsigned char *statptr;
2898                    	;  657      unsigned char rbyte;
2899                    	;  658      unsigned char cmdbuf[5];   /* buffer to build command in */
2900                    	;  659      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2901                    	;  660      int nbytes;
2902                    	;  661      int tries;
2903                    	;  662      unsigned long blktoread;
2904                    	;  663      unsigned int rxcrc16;
2905                    	;  664      unsigned int calcrc16;
2906                    	;  665  
2907                    	;  666      ledon();
2908                    	;  667      spiselect();
2909                    	;  668  
2910                    	;  669      if (!sdinitok)
2911                    	;  670          {
2912                    	;  671  #ifdef SDTEST
2913                    	;  672          printf("SD card not initialized\n");
2914                    	;  673  #endif
2915                    	;  674          spideselect();
2916                    	;  675          ledoff();
2917                    	;  676          return (NO);
2918                    	;  677          }
2919                    	;  678  
2920                    	;  679      /* CMD17: READ_SINGLE_BLOCK */
2921                    	;  680      /* Insert block # into command */
2922                    	;  681      memcpy(cmdbuf, cmd17, 5);
2923                    	;  682      blktoread = blkmult * rdblkno;
2924                    	;  683      cmdbuf[4] = blktoread & 0xff;
2925                    	;  684      blktoread = blktoread >> 8;
2926                    	;  685      cmdbuf[3] = blktoread & 0xff;
2927                    	;  686      blktoread = blktoread >> 8;
2928                    	;  687      cmdbuf[2] = blktoread & 0xff;
2929                    	;  688      blktoread = blktoread >> 8;
2930                    	;  689      cmdbuf[1] = blktoread & 0xff;
2931                    	;  690  
2932                    	;  691  #ifdef SDTEST
2933                    	;  692      printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2934                    	;  693                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2935                    	;  694  #endif
2936                    	;  695      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2937                    	;  696  #ifdef SDTEST
2938                    	;  697          printf("CMD17 R1 response [%02x]\n", statptr[0]);
2939                    	;  698  #endif
2940                    	;  699      if (statptr[0])
2941                    	;  700          {
2942                    	;  701  #ifdef SDTEST
2943                    	;  702          printf("  could not read block\n");
2944                    	;  703  #endif
2945                    	;  704          spideselect();
2946                    	;  705          ledoff();
2947                    	;  706          return (NO);
2948                    	;  707          }
2949                    	;  708      /* looking for 0xfe that is the byte before data */
2950                    	;  709      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
2951                    	;  710          {
2952                    	;  711          if ((rbyte & 0xe0) == 0x00)
2953                    	;  712              {
2954                    	;  713              /* If a read operation fails and the card cannot provide
2955                    	;  714                 the required data, it will send a data error token instead
2956                    	;  715               */
2957                    	;  716  #ifdef SDTEST
2958                    	;  717              printf("  read error: [%02x]\n", rbyte);
2959                    	;  718  #endif
2960                    	;  719              spideselect();
2961                    	;  720              ledoff();
2962                    	;  721              return (NO);
2963                    	;  722              }
2964                    	;  723          }
2965                    	;  724      if (tries == 0) /* tried too many times */
2966                    	;  725          {
2967                    	;  726  #ifdef SDTEST
2968                    	;  727          printf("  no data found\n");
2969                    	;  728  #endif
2970                    	;  729          spideselect();
2971                    	;  730          ledoff();
2972                    	;  731          return (NO);
2973                    	;  732          }
2974                    	;  733      else
2975                    	;  734          {
2976                    	;  735          calcrc16 = 0;
2977                    	;  736          for (nbytes = 0; nbytes < 512; nbytes++)
2978                    	;  737              {
2979                    	;  738              rbyte = spiio(0xff);
2980                    	;  739              calcrc16 = CRC16_one(calcrc16, rbyte);
2981                    	;  740              rdbuf[nbytes] = rbyte;
2982                    	;  741              }
2983                    	;  742          rxcrc16 = spiio(0xff) << 8;
2984                    	;  743          rxcrc16 += spiio(0xff);
2985                    	;  744  
2986                    	;  745  #ifdef SDTEST
2987                    	;  746          printf("  read data block %ld:\n", rdblkno);
2988                    	;  747  #endif
2989                    	;  748          if (rxcrc16 != calcrc16)
2990                    	;  749              {
2991                    	;  750  #ifdef SDTEST
2992                    	;  751              printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
2993                    	;  752                  rxcrc16, calcrc16);
2994                    	;  753  #endif
2995                    	;  754              spideselect();
2996                    	;  755              ledoff();
2997                    	;  756              return (NO);
2998                    	;  757              }
2999                    	;  758          }
3000                    	;  759      spideselect();
3001                    	;  760      ledoff();
3002                    	;  761      return (YES);
3003                    	;  762      }
3004                    	;  763  
3005                    	;  764  /* Write data block of 512 bytes from buffer
3006                    	;  765   * Returns YES if ok or NO if error
3007                    	;  766   */
3008                    	;  767  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
3009                    	;  768      {
3010                    	;  769      unsigned char *statptr;
3011                    	;  770      unsigned char rbyte;
3012                    	;  771      unsigned char tbyte;
3013                    	;  772      unsigned char cmdbuf[5];   /* buffer to build command in */
3014                    	;  773      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3015                    	;  774      int nbytes;
3016                    	;  775      int tries;
3017                    	;  776      unsigned long blktowrite;
3018                    	;  777      unsigned int calcrc16;
3019                    	;  778  
3020                    	;  779      ledon();
3021                    	;  780      spiselect();
3022                    	;  781  
3023                    	;  782      if (!sdinitok)
3024                    	;  783          {
3025                    	;  784  #ifdef SDTEST
3026                    	;  785          printf("SD card not initialized\n");
3027                    	;  786  #endif
3028                    	;  787          spideselect();
3029                    	;  788          ledoff();
3030                    	;  789          return (NO);
3031                    	;  790          }
3032                    	;  791  
3033                    	;  792  #ifdef SDTEST
3034                    	;  793      printf("  write data block %ld:\n", wrblkno);
3035                    	;  794  #endif
3036                    	;  795      /* CMD24: WRITE_SINGLE_BLOCK */
3037                    	;  796      /* Insert block # into command */
3038                    	;  797      memcpy(cmdbuf, cmd24, 5);
3039                    	;  798      blktowrite = blkmult * wrblkno;
3040                    	;  799      cmdbuf[4] = blktowrite & 0xff;
3041                    	;  800      blktowrite = blktowrite >> 8;
3042                    	;  801      cmdbuf[3] = blktowrite & 0xff;
3043                    	;  802      blktowrite = blktowrite >> 8;
3044                    	;  803      cmdbuf[2] = blktowrite & 0xff;
3045                    	;  804      blktowrite = blktowrite >> 8;
3046                    	;  805      cmdbuf[1] = blktowrite & 0xff;
3047                    	;  806  
3048                    	;  807  #ifdef SDTEST
3049                    	;  808      printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
3050                    	;  809                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
3051                    	;  810  #endif
3052                    	;  811      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3053                    	;  812  #ifdef SDTEST
3054                    	;  813          printf("CMD24 R1 response [%02x]\n", statptr[0]);
3055                    	;  814  #endif
3056                    	;  815      if (statptr[0])
3057                    	;  816          {
3058                    	;  817  #ifdef SDTEST
3059                    	;  818          printf("  could not write block\n");
3060                    	;  819  #endif
3061                    	;  820          spideselect();
3062                    	;  821          ledoff();
3063                    	;  822          return (NO);
3064                    	;  823          }
3065                    	;  824      /* send 0xfe, the byte before data */
3066                    	;  825      spiio(0xfe);
3067                    	;  826      /* initialize crc and send block */
3068                    	;  827      calcrc16 = 0;
3069                    	;  828      for (nbytes = 0; nbytes < 512; nbytes++)
3070                    	;  829          {
3071                    	;  830          tbyte = wrbuf[nbytes];
3072                    	;  831          spiio(tbyte);
3073                    	;  832          calcrc16 = CRC16_one(calcrc16, tbyte);
3074                    	;  833          }
3075                    	;  834      spiio((calcrc16 >> 8) & 0xff);
3076                    	;  835      spiio(calcrc16 & 0xff);
3077                    	;  836  
3078                    	;  837      /* check data resposnse */
3079                    	;  838      for (tries = 20; 
3080                    	;  839          0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
3081                    	;  840          tries--)
3082                    	;  841          ;
3083                    	;  842      if (tries == 0)
3084                    	;  843          {
3085                    	;  844  #ifdef SDTEST
3086                    	;  845          printf("No data response\n");
3087                    	;  846  #endif
3088                    	;  847          spideselect();
3089                    	;  848          ledoff();
3090                    	;  849          return (NO);
3091                    	;  850          }
3092                    	;  851      else
3093                    	;  852          {
3094                    	;  853  #ifdef SDTEST
3095                    	;  854          printf("Data response [%02x]", 0x1f & rbyte);
3096                    	;  855  #endif
3097                    	;  856          if ((0x1f & rbyte) == 0x05)
3098                    	;  857              {
3099                    	;  858  #ifdef SDTEST
3100                    	;  859              printf(", data accepted\n");
3101                    	;  860  #endif
3102                    	;  861              for (nbytes = 9; 0 < nbytes; nbytes--)
3103                    	;  862                  spiio(0xff);
3104                    	;  863  #ifdef SDTEST
3105                    	;  864              printf("Sent 9*8 (72) clock pulses, select active\n");
3106                    	;  865  #endif
3107                    	;  866              spideselect();
3108                    	;  867              ledoff();
3109                    	;  868              return (YES);
3110                    	;  869              }
3111                    	;  870          else
3112                    	;  871              {
3113                    	;  872  #ifdef SDTEST
3114                    	;  873              printf(", data not accepted\n");
3115                    	;  874  #endif
3116                    	;  875              spideselect();
3117                    	;  876              ledoff();
3118                    	;  877              return (NO);
3119                    	;  878              }
3120                    	;  879          }
3121                    	;  880      }
3122                    	;  881  
3123                    	;  882  /* Print data in 512 byte buffer */
3124                    	;  883  void sddatprt(unsigned char *prtbuf)
3125                    	;  884      {
3126                    	;  885      /* Variables used for "pretty-print" */
3127                    	;  886      int allzero, dmpline, dotprted, lastallz, nbytes;
3128                    	;  887      unsigned char *prtptr;
3129                    	;  888  
3130                    	;  889      prtptr = prtbuf;
3131                    	;  890      dotprted = NO;
3132                    	;  891      lastallz = NO;
3133                    	;  892      for (dmpline = 0; dmpline < 32; dmpline++)
3134                    	;  893          {
3135                    	;  894          /* test if all 16 bytes are 0x00 */
3136                    	;  895          allzero = YES;
3137                    	;  896          for (nbytes = 0; nbytes < 16; nbytes++)
3138                    	;  897              {
3139                    	;  898              if (prtptr[nbytes] != 0)
3140                    	;  899                  allzero = NO;
3141                    	;  900              }
3142                    	;  901          if (lastallz && allzero)
3143                    	;  902              {
3144                    	;  903              if (!dotprted)
3145                    	;  904                  {
3146                    	;  905                  printf("*\n");
3147                    	;  906                  dotprted = YES;
3148                    	;  907                  }
3149                    	;  908              }
3150                    	;  909          else
3151                    	;  910              {
3152                    	;  911              dotprted = NO;
3153                    	;  912              /* print offset */
3154                    	;  913              printf("%04x ", dmpline * 16);
3155                    	;  914              /* print 16 bytes in hex */
3156                    	;  915              for (nbytes = 0; nbytes < 16; nbytes++)
3157                    	;  916                  printf("%02x ", prtptr[nbytes]);
3158                    	;  917              /* print these bytes in ASCII if printable */
3159                    	;  918              printf(" |");
3160                    	;  919              for (nbytes = 0; nbytes < 16; nbytes++)
3161                    	;  920                  {
3162                    	;  921                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
3163                    	;  922                      putchar(prtptr[nbytes]);
3164                    	;  923                  else
3165                    	;  924                      putchar('.');
3166                    	;  925                  }
3167                    	;  926              printf("|\n");
3168                    	;  927              }
3169                    	;  928          prtptr += 16;
3170                    	;  929          lastallz = allzero;
3171                    	;  930          }
3172                    	;  931      }
3173                    	;  932  
3174                    	;  933  /* print GUID (mixed endian format) */
3175                    	;  934  void prtguid(unsigned char *guidptr)
3176                    	;  935      {
3177                    	;  936      int index;
3178                    	;  937  
3179                    	;  938      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
3180                    	;  939      printf("%02x%02x-", guidptr[5], guidptr[4]);
3181                    	;  940      printf("%02x%02x-", guidptr[7], guidptr[6]);
3182                    	;  941      printf("%02x%02x-", guidptr[8], guidptr[9]);
3183                    	;  942      printf("%02x%02x%02x%02x%02x%02x",
3184                    	;  943             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
3185                    	;  944      printf("\n  [");
3186                    	;  945      for (index = 0; index < 16; index++)
3187                    	;  946          printf("%02x ", guidptr[index]);
3188                    	;  947      printf("\b]");
3189                    	;  948      }
3190                    	;  949  
3191                    	;  950  /* print GPT entry */
3192                    	;  951  void prtgptent(unsigned int entryno)
3193                    	;  952      {
3194                    	;  953      int index;
3195                    	;  954      int entryidx;
3196                    	;  955      int hasname;
3197                    	;  956      unsigned int block;
3198                    	;  957      unsigned char *rxdata;
3199                    	;  958      unsigned char *entryptr;
3200                    	;  959      unsigned char tstzero = 0;
3201                    	;  960      unsigned long flba;
3202                    	;  961      unsigned long llba;
3203                    	;  962  
3204                    	;  963      block = 2 + (entryno / 4);
3205                    	;  964      if ((curblkno != block) || !curblkok)
3206                    	;  965          {
3207                    	;  966          if (!sdread(sdrdbuf, block))
3208                    	;  967              {
3209                    	;  968              printf("Can't read GPT entry block\n");
3210                    	;  969              return;
3211                    	;  970              }
3212                    	;  971          curblkno = block;
3213                    	;  972          curblkok = YES;
3214                    	;  973          }
3215                    	;  974      rxdata = sdrdbuf;
3216                    	;  975      entryptr = rxdata + (128 * (entryno % 4));
3217                    	;  976      for (index = 0; index < 16; index++)
3218                    	;  977          tstzero |= entryptr[index];
3219                    	;  978      printf("GPT partition entry %d:", entryno + 1);
3220                    	;  979      if (!tstzero)
3221                    	;  980          {
3222                    	;  981          printf(" Not used entry\n");
3223                    	;  982          return;
3224                    	;  983          }
3225                    	;  984      printf("\n  Partition type GUID: ");
3226                    	;  985      prtguid(entryptr);
3227                    	;  986      printf("\n  Unique partition GUID: ");
3228                    	;  987      prtguid(entryptr + 16);
3229                    	;  988      printf("\n  First LBA: ");
3230                    	;  989      /* lower 32 bits of LBA should be sufficient (I hope) */
3231                    	;  990      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
3232                    	;  991             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
3233                    	;  992      printf("%lu", flba);
3234                    	;  993      printf(" [");
3235                    	;  994      for (index = 32; index < (32 + 8); index++)
3236                    	;  995          printf("%02x ", entryptr[index]);
3237                    	;  996      printf("\b]");
3238                    	;  997      printf("\n  Last LBA: ");
3239                    	;  998      /* lower 32 bits of LBA should be sufficient (I hope) */
3240                    	;  999      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
3241                    	; 1000             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
3242                    	; 1001      printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
3243                    	; 1002      printf(" [");
3244                    	; 1003      for (index = 40; index < (40 + 8); index++)
3245                    	; 1004          printf("%02x ", entryptr[index]);
3246                    	; 1005      printf("\b]");
3247                    	; 1006      printf("\n  Attribute flags: [");
3248                    	; 1007      /* bits 0 - 2 and 60 - 63 should be decoded */
3249                    	; 1008      for (index = 0; index < 8; index++)
3250                    	; 1009          {
3251                    	; 1010          entryidx = index + 48;
3252                    	; 1011          printf("%02x ", entryptr[entryidx]);
3253                    	; 1012          }
3254                    	; 1013      printf("\b]\n  Partition name:  ");
3255                    	; 1014      /* partition name is in UTF-16LE code units */
3256                    	; 1015      hasname = NO;
3257                    	; 1016      for (index = 0; index < 72; index += 2)
3258                    	; 1017          {
3259                    	; 1018          entryidx = index + 56;
3260                    	; 1019          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
3261                    	; 1020              break;
3262                    	; 1021          if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
3263                    	; 1022              putchar(entryptr[entryidx]);
3264                    	; 1023          else
3265                    	; 1024              putchar('.');
3266                    	; 1025          hasname = YES;
3267                    	; 1026          }
3268                    	; 1027      if (!hasname)
3269                    	; 1028          printf("name field empty");
3270                    	; 1029      printf("\n");
3271                    	; 1030      printf("   [");
3272                    	; 1031      entryidx = index + 56;
3273                    	; 1032      for (index = 0; index < 72; index++)
3274                    	; 1033          {
3275                    	; 1034          if (((index & 0xf) == 0) && (index != 0))
3276                    	; 1035              printf("\n    ");
3277                    	; 1036          printf("%02x ", entryptr[entryidx]);
3278                    	; 1037          }
3279                    	; 1038      printf("\b]\n");
3280                    	; 1039      }
3281                    	; 1040  
3282                    	; 1041  /* Get GPT header */
3283                    	; 1042  void sdgpthdr(unsigned long block)
3284                    	; 1043      {
3285                    	; 1044      int index;
3286                    	; 1045      unsigned int partno;
3287                    	; 1046      unsigned char *rxdata;
3288                    	; 1047      unsigned long entries;
3289                    	; 1048  
3290                    	; 1049      printf("GPT header\n");
3291                    	; 1050      if (!sdread(sdrdbuf, block))
3292                    	; 1051          {
3293                    	; 1052          printf("Can't read GPT partition table header\n");
3294                    	; 1053          return;
3295                    	; 1054          }
3296                    	; 1055      curblkno = block;
3297                    	; 1056      curblkok = YES;
3298                    	; 1057  
3299                    	; 1058      rxdata = sdrdbuf;
3300                    	; 1059      printf("  Signature: %.8s\n", &rxdata[0]);
3301                    	; 1060      printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
3302                    	; 1061             (int)rxdata[8] * ((int)rxdata[9] << 8),
3303                    	; 1062             (int)rxdata[10] + ((int)rxdata[11] << 8),
3304                    	; 1063             rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
3305                    	; 1064      entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
3306                    	; 1065                ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
3307                    	; 1066      printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
3308                    	; 1067      for (partno = 0; partno < 16; partno++)
3309                    	; 1068          {
3310                    	; 1069          prtgptent(partno);
3311                    	; 1070          }
3312                    	; 1071      printf("First 16 GPT entries scanned\n");
3313                    	; 1072      }
3314                    	; 1073  
3315                    	; 1074  /* read MBR partition entry */
3316                    	; 1075  int sdmbrentry(unsigned char *partptr)
3317                    	; 1076      {
3318                    	; 1077      int index;
3319                    	; 1078      unsigned long lbastart;
3320                    	; 1079      unsigned long lbasize;
3321                    	; 1080  
3322                    	; 1081      if ((curblkno != 0) || !curblkok)
3323                    	; 1082          {
3324                    	; 1083          curblkno = 0;
3325                    	; 1084          if (!sdread(sdrdbuf, curblkno))
3326                    	; 1085              {
3327                    	; 1086              printf("Can't read MBR sector\n");
3328                    	; 1087              return;
3329                    	; 1088              }
3330                    	; 1089          curblkok = YES;
3331                    	; 1090          }
3332                    	; 1091      if (!partptr[4])
3333                    	; 1092          {
3334                    	; 1093          printf("Not used entry\n");
3335                    	; 1094          return;
3336                    	; 1095          }
3337                    	; 1096      printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
3338                    	; 1097             partptr[0], partptr[4]);
3339                    	; 1098  
3340                    	; 1099      if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
3341                    	; 1100          {
3342                    	; 1101          printf("  Extended partition\n");
3343                    	; 1102          /* should probably decode this also */
3344                    	; 1103          }
3345                    	; 1104      if (partptr[0] & 0x01)
3346                    	; 1105          {
3347                    	; 1106          printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
3348                    	; 1107          /* this is however discussed
3349                    	; 1108             https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
3350                    	; 1109          */
3351                    	; 1110          }
3352                    	; 1111      else
3353                    	; 1112          {
3354                    	; 1113          printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3355                    	; 1114                 partptr[1], partptr[2], partptr[3],
3356                    	; 1115                 ((partptr[2] & 0xc0) >> 2) + partptr[3],
3357                    	; 1116                 partptr[1],
3358                    	; 1117                 partptr[2] & 0x3f);
3359                    	; 1118          printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3360                    	; 1119                 partptr[5], partptr[6], partptr[7],
3361                    	; 1120                 ((partptr[6] & 0xc0) >> 2) + partptr[7],
3362                    	; 1121                 partptr[5],
3363                    	; 1122                 partptr[6] & 0x3f);
3364                    	; 1123          }
3365                    	; 1124      /* not showing high 16 bits if 48 bit LBA */
3366                    	; 1125      lbastart = (unsigned long)partptr[8] +
3367                    	; 1126                 ((unsigned long)partptr[9] << 8) +
3368                    	; 1127                 ((unsigned long)partptr[10] << 16) +
3369                    	; 1128                 ((unsigned long)partptr[11] << 24);
3370                    	; 1129      lbasize = (unsigned long)partptr[12] +
3371                    	; 1130                ((unsigned long)partptr[13] << 8) +
3372                    	; 1131                ((unsigned long)partptr[14] << 16) +
3373                    	; 1132                ((unsigned long)partptr[15] << 24);
3374                    	; 1133      printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
3375                    	; 1134      printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
3376                    	; 1135             lbasize, lbasize, lbasize >> 11);
3377                    	; 1136      if (partptr[4] == 0xee)
3378                    	; 1137          sdgpthdr(lbastart);
3379                    	; 1138      }
3380                    	; 1139  
3381                    	; 1140  /* read MBR partition information */
3382                    	; 1141  void sdmbrpart()
3383                    	; 1142      {
3384                    	; 1143      int partidx;  /* partition index 1 - 4 */
3385                    	; 1144      unsigned char *entp; /* pointer to partition entry */
3386                    	; 1145  
3387                    	; 1146  #ifdef SDTEST
3388                    	; 1147      printf("Read MBR\n");
3389                    	; 1148  #endif
3390                    	; 1149      if (!sdread(sdrdbuf, 0))
3391                    	; 1150          {
3392                    	; 1151  #ifdef SDTEST
3393                    	; 1152          printf("  can't read MBR sector\n");
3394                    	; 1153  #endif
3395                    	; 1154          return;
3396                    	; 1155          }
3397                    	; 1156      curblkno = 0;
3398    2212  97        		sub	a
3399    2213  320000    		ld	(_curblkno),a
3400    2216  320100    		ld	(_curblkno+1),a
3401    2219  320200    		ld	(_curblkno+2),a
3402    221C  320300    		ld	(_curblkno+3),a
3403    221F  220C00    		ld	(_curblkok),hl
3404                    	; 1157      curblkok = YES;
3405                    	; 1158      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
3406    2222  3A3002    		ld	a,(_sdrdbuf+510)
3407    2225  FE55      		cp	85
3408    2227  2007      		jr	nz,L1403
3409    2229  3A3102    		ld	a,(_sdrdbuf+511)
3410    222C  FEAA      		cp	170
3411    222E  2803      		jr	z,L1303
3412                    	L1403:
3413                    	; 1159          {
3414                    	; 1160  #ifdef SDTEST
3415                    	; 1161          printf("  no MBR signature found\n");
3416                    	; 1162  #endif
3417                    	; 1163          return;
3418    2230  C30000    		jp	c.rets0
3419                    	L1303:
3420                    	; 1164          }
3421                    	; 1165      /* go through MBR partition entries until first empty */
3422                    	; 1166      entp = &sdrdbuf[0x01be];
3423    2233  21F001    		ld	hl,_sdrdbuf+446
3424    2236  DD75F6    		ld	(ix-10),l
3425    2239  DD74F7    		ld	(ix-9),h
3426                    	; 1167      for (partidx = 1; partidx <= 4; partidx++, entp += 16)
3427    223C  DD36F801  		ld	(ix-8),1
3428    2240  DD36F900  		ld	(ix-7),0
3429                    	L1503:
3430    2244  3E04      		ld	a,4
3431    2246  DD96F8    		sub	(ix-8)
3432    2249  3E00      		ld	a,0
3433    224B  DD9EF9    		sbc	a,(ix-7)
3434    224E  FA7C22    		jp	m,L1603
3435                    	; 1168          {
3436                    	; 1169  #ifdef SDTEST
3437                    	; 1170          printf("MBR partition entry %d: ", partidx);
3438                    	; 1171  #endif
3439                    	; 1172          if (!sdmbrentry(entp))
3440    2251  DD6EF6    		ld	l,(ix-10)
3441    2254  DD66F7    		ld	h,(ix-9)
3442    2257  CD4E1E    		call	_sdmbrentry
3443    225A  79        		ld	a,c
3444    225B  B0        		or	b
3445    225C  281E      		jr	z,L1603
3446                    	; 1173              break;
3447                    	L1703:
3448    225E  DD34F8    		inc	(ix-8)
3449    2261  2003      		jr	nz,L421
3450    2263  DD34F9    		inc	(ix-7)
3451                    	L421:
3452    2266  DD6EF6    		ld	l,(ix-10)
3453    2269  DD66F7    		ld	h,(ix-9)
3454    226C  7D        		ld	a,l
3455    226D  C610      		add	a,16
3456    226F  6F        		ld	l,a
3457    2270  7C        		ld	a,h
3458    2271  CE00      		adc	a,0
3459    2273  67        		ld	h,a
3460    2274  DD75F6    		ld	(ix-10),l
3461    2277  DD74F7    		ld	(ix-9),h
3462    227A  18C8      		jr	L1503
3463                    	L1603:
3464                    	; 1174          }
3465                    	; 1175      }
3466    227C  C30000    		jp	c.rets0
3467                    	L5301:
3468    227F  0A        		.byte	10
3469    2280  7A        		.byte	122
3470    2281  38        		.byte	56
3471    2282  30        		.byte	48
3472    2283  62        		.byte	98
3473    2284  6F        		.byte	111
3474    2285  6F        		.byte	111
3475    2286  74        		.byte	116
3476    2287  20        		.byte	32
3477    2288  00        		.byte	0
3478                    	L5401:
3479    2289  76        		.byte	118
3480    228A  65        		.byte	101
3481    228B  72        		.byte	114
3482    228C  73        		.byte	115
3483    228D  69        		.byte	105
3484    228E  6F        		.byte	111
3485    228F  6E        		.byte	110
3486    2290  20        		.byte	32
3487    2291  30        		.byte	48
3488    2292  2E        		.byte	46
3489    2293  34        		.byte	52
3490    2294  2C        		.byte	44
3491    2295  20        		.byte	32
3492    2296  00        		.byte	0
3493                    	L5501:
3494    2297  0A        		.byte	10
3495    2298  00        		.byte	0
3496                    	L5601:
3497    2299  63        		.byte	99
3498    229A  6D        		.byte	109
3499    229B  64        		.byte	100
3500    229C  20        		.byte	32
3501    229D  28        		.byte	40
3502    229E  68        		.byte	104
3503    229F  20        		.byte	32
3504    22A0  66        		.byte	102
3505    22A1  6F        		.byte	111
3506    22A2  72        		.byte	114
3507    22A3  20        		.byte	32
3508    22A4  68        		.byte	104
3509    22A5  65        		.byte	101
3510    22A6  6C        		.byte	108
3511    22A7  70        		.byte	112
3512    22A8  29        		.byte	41
3513    22A9  3A        		.byte	58
3514    22AA  20        		.byte	32
3515    22AB  00        		.byte	0
3516                    	L5701:
3517    22AC  20        		.byte	32
3518    22AD  68        		.byte	104
3519    22AE  20        		.byte	32
3520    22AF  2D        		.byte	45
3521    22B0  20        		.byte	32
3522    22B1  68        		.byte	104
3523    22B2  65        		.byte	101
3524    22B3  6C        		.byte	108
3525    22B4  70        		.byte	112
3526    22B5  0A        		.byte	10
3527    22B6  00        		.byte	0
3528                    	L5011:
3529    22B7  0A        		.byte	10
3530    22B8  7A        		.byte	122
3531    22B9  38        		.byte	56
3532    22BA  30        		.byte	48
3533    22BB  62        		.byte	98
3534    22BC  6F        		.byte	111
3535    22BD  6F        		.byte	111
3536    22BE  74        		.byte	116
3537    22BF  20        		.byte	32
3538    22C0  00        		.byte	0
3539                    	L5111:
3540    22C1  76        		.byte	118
3541    22C2  65        		.byte	101
3542    22C3  72        		.byte	114
3543    22C4  73        		.byte	115
3544    22C5  69        		.byte	105
3545    22C6  6F        		.byte	111
3546    22C7  6E        		.byte	110
3547    22C8  20        		.byte	32
3548    22C9  30        		.byte	48
3549    22CA  2E        		.byte	46
3550    22CB  34        		.byte	52
3551    22CC  2C        		.byte	44
3552    22CD  20        		.byte	32
3553    22CE  00        		.byte	0
3554                    	L5211:
3555    22CF  0A        		.byte	10
3556    22D0  43        		.byte	67
3557    22D1  6F        		.byte	111
3558    22D2  6D        		.byte	109
3559    22D3  6D        		.byte	109
3560    22D4  61        		.byte	97
3561    22D5  6E        		.byte	110
3562    22D6  64        		.byte	100
3563    22D7  73        		.byte	115
3564    22D8  3A        		.byte	58
3565    22D9  0A        		.byte	10
3566    22DA  00        		.byte	0
3567                    	L5311:
3568    22DB  20        		.byte	32
3569    22DC  20        		.byte	32
3570    22DD  68        		.byte	104
3571    22DE  20        		.byte	32
3572    22DF  2D        		.byte	45
3573    22E0  20        		.byte	32
3574    22E1  68        		.byte	104
3575    22E2  65        		.byte	101
3576    22E3  6C        		.byte	108
3577    22E4  70        		.byte	112
3578    22E5  0A        		.byte	10
3579    22E6  00        		.byte	0
3580                    	L5411:
3581    22E7  20        		.byte	32
3582    22E8  20        		.byte	32
3583    22E9  69        		.byte	105
3584    22EA  20        		.byte	32
3585    22EB  2D        		.byte	45
3586    22EC  20        		.byte	32
3587    22ED  69        		.byte	105
3588    22EE  6E        		.byte	110
3589    22EF  69        		.byte	105
3590    22F0  74        		.byte	116
3591    22F1  69        		.byte	105
3592    22F2  61        		.byte	97
3593    22F3  6C        		.byte	108
3594    22F4  69        		.byte	105
3595    22F5  7A        		.byte	122
3596    22F6  65        		.byte	101
3597    22F7  0A        		.byte	10
3598    22F8  00        		.byte	0
3599                    	L5511:
3600    22F9  20        		.byte	32
3601    22FA  20        		.byte	32
3602    22FB  6E        		.byte	110
3603    22FC  20        		.byte	32
3604    22FD  2D        		.byte	45
3605    22FE  20        		.byte	32
3606    22FF  73        		.byte	115
3607    2300  65        		.byte	101
3608    2301  74        		.byte	116
3609    2302  2F        		.byte	47
3610    2303  73        		.byte	115
3611    2304  68        		.byte	104
3612    2305  6F        		.byte	111
3613    2306  77        		.byte	119
3614    2307  20        		.byte	32
3615    2308  62        		.byte	98
3616    2309  6C        		.byte	108
3617    230A  6F        		.byte	111
3618    230B  63        		.byte	99
3619    230C  6B        		.byte	107
3620    230D  20        		.byte	32
3621    230E  23        		.byte	35
3622    230F  4E        		.byte	78
3623    2310  20        		.byte	32
3624    2311  74        		.byte	116
3625    2312  6F        		.byte	111
3626    2313  20        		.byte	32
3627    2314  72        		.byte	114
3628    2315  65        		.byte	101
3629    2316  61        		.byte	97
3630    2317  64        		.byte	100
3631    2318  0A        		.byte	10
3632    2319  00        		.byte	0
3633                    	L5611:
3634    231A  20        		.byte	32
3635    231B  20        		.byte	32
3636    231C  72        		.byte	114
3637    231D  20        		.byte	32
3638    231E  2D        		.byte	45
3639    231F  20        		.byte	32
3640    2320  72        		.byte	114
3641    2321  65        		.byte	101
3642    2322  61        		.byte	97
3643    2323  64        		.byte	100
3644    2324  20        		.byte	32
3645    2325  62        		.byte	98
3646    2326  6C        		.byte	108
3647    2327  6F        		.byte	111
3648    2328  63        		.byte	99
3649    2329  6B        		.byte	107
3650    232A  20        		.byte	32
3651    232B  23        		.byte	35
3652    232C  4E        		.byte	78
3653    232D  0A        		.byte	10
3654    232E  00        		.byte	0
3655                    	L5711:
3656    232F  20        		.byte	32
3657    2330  20        		.byte	32
3658    2331  77        		.byte	119
3659    2332  20        		.byte	32
3660    2333  2D        		.byte	45
3661    2334  20        		.byte	32
3662    2335  72        		.byte	114
3663    2336  65        		.byte	101
3664    2337  61        		.byte	97
3665    2338  64        		.byte	100
3666    2339  20        		.byte	32
3667    233A  62        		.byte	98
3668    233B  6C        		.byte	108
3669    233C  6F        		.byte	111
3670    233D  63        		.byte	99
3671    233E  6B        		.byte	107
3672    233F  20        		.byte	32
3673    2340  23        		.byte	35
3674    2341  4E        		.byte	78
3675    2342  0A        		.byte	10
3676    2343  00        		.byte	0
3677                    	L5021:
3678    2344  20        		.byte	32
3679    2345  20        		.byte	32
3680    2346  70        		.byte	112
3681    2347  20        		.byte	32
3682    2348  2D        		.byte	45
3683    2349  20        		.byte	32
3684    234A  70        		.byte	112
3685    234B  72        		.byte	114
3686    234C  69        		.byte	105
3687    234D  6E        		.byte	110
3688    234E  74        		.byte	116
3689    234F  20        		.byte	32
3690    2350  62        		.byte	98
3691    2351  6C        		.byte	108
3692    2352  6F        		.byte	111
3693    2353  63        		.byte	99
3694    2354  6B        		.byte	107
3695    2355  20        		.byte	32
3696    2356  6C        		.byte	108
3697    2357  61        		.byte	97
3698    2358  73        		.byte	115
3699    2359  74        		.byte	116
3700    235A  20        		.byte	32
3701    235B  72        		.byte	114
3702    235C  65        		.byte	101
3703    235D  61        		.byte	97
3704    235E  64        		.byte	100
3705    235F  2F        		.byte	47
3706    2360  74        		.byte	116
3707    2361  6F        		.byte	111
3708    2362  20        		.byte	32
3709    2363  77        		.byte	119
3710    2364  72        		.byte	114
3711    2365  69        		.byte	105
3712    2366  74        		.byte	116
3713    2367  65        		.byte	101
3714    2368  0A        		.byte	10
3715    2369  00        		.byte	0
3716                    	L5121:
3717    236A  20        		.byte	32
3718    236B  20        		.byte	32
3719    236C  73        		.byte	115
3720    236D  20        		.byte	32
3721    236E  2D        		.byte	45
3722    236F  20        		.byte	32
3723    2370  70        		.byte	112
3724    2371  72        		.byte	114
3725    2372  69        		.byte	105
3726    2373  6E        		.byte	110
3727    2374  74        		.byte	116
3728    2375  20        		.byte	32
3729    2376  53        		.byte	83
3730    2377  44        		.byte	68
3731    2378  20        		.byte	32
3732    2379  72        		.byte	114
3733    237A  65        		.byte	101
3734    237B  67        		.byte	103
3735    237C  69        		.byte	105
3736    237D  73        		.byte	115
3737    237E  74        		.byte	116
3738    237F  65        		.byte	101
3739    2380  72        		.byte	114
3740    2381  73        		.byte	115
3741    2382  0A        		.byte	10
3742    2383  00        		.byte	0
3743                    	L5221:
3744    2384  20        		.byte	32
3745    2385  20        		.byte	32
3746    2386  6C        		.byte	108
3747    2387  20        		.byte	32
3748    2388  2D        		.byte	45
3749    2389  20        		.byte	32
3750    238A  70        		.byte	112
3751    238B  72        		.byte	114
3752    238C  69        		.byte	105
3753    238D  6E        		.byte	110
3754    238E  74        		.byte	116
3755    238F  20        		.byte	32
3756    2390  70        		.byte	112
3757    2391  61        		.byte	97
3758    2392  72        		.byte	114
3759    2393  74        		.byte	116
3760    2394  69        		.byte	105
3761    2395  74        		.byte	116
3762    2396  69        		.byte	105
3763    2397  6F        		.byte	111
3764    2398  6E        		.byte	110
3765    2399  20        		.byte	32
3766    239A  6C        		.byte	108
3767    239B  61        		.byte	97
3768    239C  79        		.byte	121
3769    239D  6F        		.byte	111
3770    239E  75        		.byte	117
3771    239F  74        		.byte	116
3772    23A0  0A        		.byte	10
3773    23A1  00        		.byte	0
3774                    	L5321:
3775    23A2  20        		.byte	32
3776    23A3  20        		.byte	32
3777    23A4  43        		.byte	67
3778    23A5  74        		.byte	116
3779    23A6  72        		.byte	114
3780    23A7  6C        		.byte	108
3781    23A8  2D        		.byte	45
3782    23A9  43        		.byte	67
3783    23AA  20        		.byte	32
3784    23AB  74        		.byte	116
3785    23AC  6F        		.byte	111
3786    23AD  20        		.byte	32
3787    23AE  72        		.byte	114
3788    23AF  65        		.byte	101
3789    23B0  6C        		.byte	108
3790    23B1  6F        		.byte	111
3791    23B2  61        		.byte	97
3792    23B3  64        		.byte	100
3793    23B4  20        		.byte	32
3794    23B5  6D        		.byte	109
3795    23B6  6F        		.byte	111
3796    23B7  6E        		.byte	110
3797    23B8  69        		.byte	105
3798    23B9  74        		.byte	116
3799    23BA  6F        		.byte	111
3800    23BB  72        		.byte	114
3801    23BC  2E        		.byte	46
3802    23BD  0A        		.byte	10
3803    23BE  00        		.byte	0
3804                    	L5421:
3805    23BF  20        		.byte	32
3806    23C0  69        		.byte	105
3807    23C1  20        		.byte	32
3808    23C2  2D        		.byte	45
3809    23C3  20        		.byte	32
3810    23C4  69        		.byte	105
3811    23C5  6E        		.byte	110
3812    23C6  69        		.byte	105
3813    23C7  74        		.byte	116
3814    23C8  69        		.byte	105
3815    23C9  61        		.byte	97
3816    23CA  6C        		.byte	108
3817    23CB  69        		.byte	105
3818    23CC  7A        		.byte	122
3819    23CD  65        		.byte	101
3820    23CE  20        		.byte	32
3821    23CF  53        		.byte	83
3822    23D0  44        		.byte	68
3823    23D1  20        		.byte	32
3824    23D2  63        		.byte	99
3825    23D3  61        		.byte	97
3826    23D4  72        		.byte	114
3827    23D5  64        		.byte	100
3828    23D6  00        		.byte	0
3829                    	L5521:
3830    23D7  20        		.byte	32
3831    23D8  2D        		.byte	45
3832    23D9  20        		.byte	32
3833    23DA  6F        		.byte	111
3834    23DB  6B        		.byte	107
3835    23DC  0A        		.byte	10
3836    23DD  00        		.byte	0
3837                    	L5621:
3838    23DE  20        		.byte	32
3839    23DF  2D        		.byte	45
3840    23E0  20        		.byte	32
3841    23E1  6E        		.byte	110
3842    23E2  6F        		.byte	111
3843    23E3  74        		.byte	116
3844    23E4  20        		.byte	32
3845    23E5  69        		.byte	105
3846    23E6  6E        		.byte	110
3847    23E7  73        		.byte	115
3848    23E8  65        		.byte	101
3849    23E9  72        		.byte	114
3850    23EA  74        		.byte	116
3851    23EB  65        		.byte	101
3852    23EC  64        		.byte	100
3853    23ED  20        		.byte	32
3854    23EE  6F        		.byte	111
3855    23EF  72        		.byte	114
3856    23F0  20        		.byte	32
3857    23F1  66        		.byte	102
3858    23F2  61        		.byte	97
3859    23F3  75        		.byte	117
3860    23F4  6C        		.byte	108
3861    23F5  74        		.byte	116
3862    23F6  79        		.byte	121
3863    23F7  0A        		.byte	10
3864    23F8  00        		.byte	0
3865                    	L5721:
3866    23F9  20        		.byte	32
3867    23FA  6E        		.byte	110
3868    23FB  20        		.byte	32
3869    23FC  2D        		.byte	45
3870    23FD  20        		.byte	32
3871    23FE  62        		.byte	98
3872    23FF  6C        		.byte	108
3873    2400  6F        		.byte	111
3874    2401  63        		.byte	99
3875    2402  6B        		.byte	107
3876    2403  20        		.byte	32
3877    2404  6E        		.byte	110
3878    2405  75        		.byte	117
3879    2406  6D        		.byte	109
3880    2407  62        		.byte	98
3881    2408  65        		.byte	101
3882    2409  72        		.byte	114
3883    240A  3A        		.byte	58
3884    240B  20        		.byte	32
3885    240C  00        		.byte	0
3886                    	L5031:
3887    240D  25        		.byte	37
3888    240E  6C        		.byte	108
3889    240F  75        		.byte	117
3890    2410  00        		.byte	0
3891                    	L5131:
3892    2411  25        		.byte	37
3893    2412  6C        		.byte	108
3894    2413  75        		.byte	117
3895    2414  00        		.byte	0
3896                    	L5231:
3897    2415  0A        		.byte	10
3898    2416  00        		.byte	0
3899                    	L5331:
3900    2417  20        		.byte	32
3901    2418  72        		.byte	114
3902    2419  20        		.byte	32
3903    241A  2D        		.byte	45
3904    241B  20        		.byte	32
3905    241C  72        		.byte	114
3906    241D  65        		.byte	101
3907    241E  61        		.byte	97
3908    241F  64        		.byte	100
3909    2420  20        		.byte	32
3910    2421  62        		.byte	98
3911    2422  6C        		.byte	108
3912    2423  6F        		.byte	111
3913    2424  63        		.byte	99
3914    2425  6B        		.byte	107
3915    2426  00        		.byte	0
3916                    	L5431:
3917    2427  20        		.byte	32
3918    2428  2D        		.byte	45
3919    2429  20        		.byte	32
3920    242A  6F        		.byte	111
3921    242B  6B        		.byte	107
3922    242C  0A        		.byte	10
3923    242D  00        		.byte	0
3924                    	L5531:
3925    242E  20        		.byte	32
3926    242F  2D        		.byte	45
3927    2430  20        		.byte	32
3928    2431  65        		.byte	101
3929    2432  72        		.byte	114
3930    2433  72        		.byte	114
3931    2434  6F        		.byte	111
3932    2435  72        		.byte	114
3933    2436  0A        		.byte	10
3934    2437  00        		.byte	0
3935                    	L5631:
3936    2438  20        		.byte	32
3937    2439  77        		.byte	119
3938    243A  20        		.byte	32
3939    243B  2D        		.byte	45
3940    243C  20        		.byte	32
3941    243D  77        		.byte	119
3942    243E  72        		.byte	114
3943    243F  69        		.byte	105
3944    2440  74        		.byte	116
3945    2441  65        		.byte	101
3946    2442  20        		.byte	32
3947    2443  62        		.byte	98
3948    2444  6C        		.byte	108
3949    2445  6F        		.byte	111
3950    2446  63        		.byte	99
3951    2447  6B        		.byte	107
3952    2448  00        		.byte	0
3953                    	L5731:
3954    2449  20        		.byte	32
3955    244A  2D        		.byte	45
3956    244B  20        		.byte	32
3957    244C  6F        		.byte	111
3958    244D  6B        		.byte	107
3959    244E  0A        		.byte	10
3960    244F  00        		.byte	0
3961                    	L5041:
3962    2450  20        		.byte	32
3963    2451  2D        		.byte	45
3964    2452  20        		.byte	32
3965    2453  65        		.byte	101
3966    2454  72        		.byte	114
3967    2455  72        		.byte	114
3968    2456  6F        		.byte	111
3969    2457  72        		.byte	114
3970    2458  0A        		.byte	10
3971    2459  00        		.byte	0
3972                    	L5141:
3973    245A  20        		.byte	32
3974    245B  70        		.byte	112
3975    245C  20        		.byte	32
3976    245D  2D        		.byte	45
3977    245E  20        		.byte	32
3978    245F  70        		.byte	112
3979    2460  72        		.byte	114
3980    2461  69        		.byte	105
3981    2462  6E        		.byte	110
3982    2463  74        		.byte	116
3983    2464  20        		.byte	32
3984    2465  64        		.byte	100
3985    2466  61        		.byte	97
3986    2467  74        		.byte	116
3987    2468  61        		.byte	97
3988    2469  20        		.byte	32
3989    246A  62        		.byte	98
3990    246B  6C        		.byte	108
3991    246C  6F        		.byte	111
3992    246D  63        		.byte	99
3993    246E  6B        		.byte	107
3994    246F  20        		.byte	32
3995    2470  25        		.byte	37
3996    2471  6C        		.byte	108
3997    2472  75        		.byte	117
3998    2473  0A        		.byte	10
3999    2474  00        		.byte	0
4000                    	L5241:
4001    2475  20        		.byte	32
4002    2476  73        		.byte	115
4003    2477  20        		.byte	32
4004    2478  2D        		.byte	45
4005    2479  20        		.byte	32
4006    247A  70        		.byte	112
4007    247B  72        		.byte	114
4008    247C  69        		.byte	105
4009    247D  6E        		.byte	110
4010    247E  74        		.byte	116
4011    247F  20        		.byte	32
4012    2480  53        		.byte	83
4013    2481  44        		.byte	68
4014    2482  20        		.byte	32
4015    2483  72        		.byte	114
4016    2484  65        		.byte	101
4017    2485  67        		.byte	103
4018    2486  69        		.byte	105
4019    2487  73        		.byte	115
4020    2488  74        		.byte	116
4021    2489  65        		.byte	101
4022    248A  72        		.byte	114
4023    248B  73        		.byte	115
4024    248C  0A        		.byte	10
4025    248D  00        		.byte	0
4026                    	L5341:
4027    248E  20        		.byte	32
4028    248F  6C        		.byte	108
4029    2490  20        		.byte	32
4030    2491  2D        		.byte	45
4031    2492  20        		.byte	32
4032    2493  70        		.byte	112
4033    2494  72        		.byte	114
4034    2495  69        		.byte	105
4035    2496  6E        		.byte	110
4036    2497  74        		.byte	116
4037    2498  20        		.byte	32
4038    2499  70        		.byte	112
4039    249A  61        		.byte	97
4040    249B  72        		.byte	114
4041    249C  74        		.byte	116
4042    249D  69        		.byte	105
4043    249E  74        		.byte	116
4044    249F  69        		.byte	105
4045    24A0  6F        		.byte	111
4046    24A1  6E        		.byte	110
4047    24A2  20        		.byte	32
4048    24A3  6C        		.byte	108
4049    24A4  61        		.byte	97
4050    24A5  79        		.byte	121
4051    24A6  6F        		.byte	111
4052    24A7  75        		.byte	117
4053    24A8  74        		.byte	116
4054    24A9  0A        		.byte	10
4055    24AA  00        		.byte	0
4056                    	L5441:
4057    24AB  72        		.byte	114
4058    24AC  65        		.byte	101
4059    24AD  6C        		.byte	108
4060    24AE  6F        		.byte	111
4061    24AF  61        		.byte	97
4062    24B0  64        		.byte	100
4063    24B1  69        		.byte	105
4064    24B2  6E        		.byte	110
4065    24B3  67        		.byte	103
4066    24B4  20        		.byte	32
4067    24B5  6D        		.byte	109
4068    24B6  6F        		.byte	111
4069    24B7  6E        		.byte	110
4070    24B8  69        		.byte	105
4071    24B9  74        		.byte	116
4072    24BA  6F        		.byte	111
4073    24BB  72        		.byte	114
4074    24BC  20        		.byte	32
4075    24BD  66        		.byte	102
4076    24BE  72        		.byte	114
4077    24BF  6F        		.byte	111
4078    24C0  6D        		.byte	109
4079    24C1  20        		.byte	32
4080    24C2  45        		.byte	69
4081    24C3  50        		.byte	80
4082    24C4  52        		.byte	82
4083    24C5  4F        		.byte	79
4084    24C6  4D        		.byte	77
4085    24C7  0A        		.byte	10
4086    24C8  00        		.byte	0
4087                    	L5541:
4088    24C9  20        		.byte	32
4089    24CA  63        		.byte	99
4090    24CB  6F        		.byte	111
4091    24CC  6D        		.byte	109
4092    24CD  6D        		.byte	109
4093    24CE  61        		.byte	97
4094    24CF  6E        		.byte	110
4095    24D0  64        		.byte	100
   0    24D1  20        		.byte	32
   1    24D2  6E        		.byte	110
   2    24D3  6F        		.byte	111
   3    24D4  74        		.byte	116
   4    24D5  20        		.byte	32
   5    24D6  69        		.byte	105
   6    24D7  6D        		.byte	109
   7    24D8  70        		.byte	112
   8    24D9  6C        		.byte	108
   9    24DA  65        		.byte	101
  10    24DB  6D        		.byte	109
  11    24DC  65        		.byte	101
  12    24DD  6E        		.byte	110
  13    24DE  74        		.byte	116
  14    24DF  65        		.byte	101
  15    24E0  64        		.byte	100
  16    24E1  20        		.byte	32
  17    24E2  79        		.byte	121
  18    24E3  65        		.byte	101
  19    24E4  74        		.byte	116
  20    24E5  0A        		.byte	10
  21    24E6  00        		.byte	0
  22                    	L1413:
  23    24E7  0C        		.byte	12
  24    24E8  00        		.byte	0
  25    24E9  68        		.byte	104
  26    24EA  00        		.byte	0
  27    24EB  7125      		.word	L1613
  28    24ED  C825      		.word	L1713
  29    24EF  FE26      		.word	L1733
  30    24F1  FE26      		.word	L1733
  31    24F3  E626      		.word	L1533
  32    24F5  FE26      		.word	L1733
  33    24F7  E725      		.word	L1223
  34    24F9  FE26      		.word	L1733
  35    24FB  BD26      		.word	L1333
  36    24FD  FE26      		.word	L1733
  37    24FF  3926      		.word	L1523
  38    2501  DA26      		.word	L1433
  39    2503  00        		.byte	0
  40    2504  00        		.byte	0
  41    2505  02        		.byte	2
  42    2506  00        		.byte	0
  43    2507  F226      		.word	L1633
  44    2509  0300      		.word	3
  45    250B  7B26      		.word	L1033
  46    250D  7700      		.word	119
  47    250F  FE26      		.word	L1733
  48                    	; 1176  
  49                    	; 1177  /* Test init, read and partitions on SD card over the SPI interface
  50                    	; 1178   *
  51                    	; 1179   */
  52                    	; 1180  int main()
  53                    	; 1181      {
  54                    	_main:
  55    2511  CD0000    		call	c.savs0
  56    2514  21E8FF    		ld	hl,65512
  57    2517  39        		add	hl,sp
  58    2518  F9        		ld	sp,hl
  59                    	; 1182      char txtin[10];
  60                    	; 1183      int cmdin;
  61                    	; 1184      int inlength;
  62                    	; 1185      unsigned long blockno;
  63                    	; 1186  
  64                    	; 1187      blockno = 0;
  65    2519  97        		sub	a
  66    251A  DD77E8    		ld	(ix-24),a
  67    251D  DD77E9    		ld	(ix-23),a
  68    2520  DD77EA    		ld	(ix-22),a
  69    2523  DD77EB    		ld	(ix-21),a
  70                    	; 1188      curblkno = 0;
  71                    	; 1189      curblkok = NO;
  72    2526  210000    		ld	hl,0
  73                    	;    1  /*  z80boot.c
  74                    	;    2   *
  75                    	;    3   *  Boot code for my DIY Z80 Computer. This
  76                    	;    4   *  program is compiled with Whitesmiths/COSMIC
  77                    	;    5   *  C compiler for Z80.
  78                    	;    6   *
  79                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
  80                    	;    8   *
  81                    	;    9   *  Initializes the hardware and detects the
  82                    	;   10   *  presence and partitioning of an attached SD card.
  83                    	;   11   *
  84                    	;   12   *  You are free to use, modify, and redistribute
  85                    	;   13   *  this source code. No warranties are given.
  86                    	;   14   *  Hastily Cobbled Together 2021 and 2022
  87                    	;   15   *  by Hans-Ake Lund
  88                    	;   16   *
  89                    	;   17   */
  90                    	;   18  
  91                    	;   19  #include <std.h>
  92                    	;   20  #include "z80computer.h"
  93                    	;   21  #include "builddate.h"
  94                    	;   22  #include "progtype.h"
  95                    	;   23  
  96                    	;   24  #ifdef SDTEST
  97                    	;   25  #define PRGNAME "\nz80sdtest "
  98                    	;   26  #else
  99                    	;   27  #define PRGNAME "\nz80boot "
 100                    	;   28  #endif
 101                    	;   29  #define VERSION "version 0.4, "
 102                    	;   30  
 103                    	;   31  /* Response length in bytes
 104                    	;   32   */
 105                    	;   33  #define R1_LEN 1
 106                    	;   34  #define R3_LEN 5
 107                    	;   35  #define R7_LEN 5
 108                    	;   36  
 109                    	;   37  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
 110                    	;   38   * (The CRC7 byte in the tables below are only for information,
 111                    	;   39   * it is calculated by the sdcommand routine.)
 112                    	;   40   */
 113                    	;   41  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
 114                    	;   42  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
 115                    	;   43  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
 116                    	;   44  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
 117                    	;   45  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
 118                    	;   46  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
 119                    	;   47  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
 120                    	;   48  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
 121                    	;   49  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
 122                    	;   50  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
 123                    	;   51  
 124                    	;   52  /* Buffers
 125                    	;   53   */
 126                    	;   54  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
 127                    	;   55  
 128                    	;   56  unsigned char ocrreg[4];     /* SD card OCR register */
 129                    	;   57  unsigned char cidreg[16];    /* SD card CID register */
 130                    	;   58  unsigned char csdreg[16];    /* SD card CSD register */
 131                    	;   59  
 132                    	;   60  /* Variables
 133                    	;   61   */
 134                    	;   62  int curblkok;  /* if YES curblockno is read into buffer */
 135                    	;   63  int sdinitok;  /* SD card initialized and ready */
 136                    	;   64  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
 137                    	;   65  unsigned long blkmult;   /* block address multiplier */
 138                    	;   66  unsigned long curblkno;  /* block in buffer if curblkok == YES */
 139                    	;   67  
 140                    	;   68  /* CRC routines from:
 141                    	;   69   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
 142                    	;   70   */
 143                    	;   71  
 144                    	;   72  /*
 145                    	;   73  // Calculate CRC7
 146                    	;   74  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
 147                    	;   75  // input:
 148                    	;   76  //   crcIn - the CRC before (0 for first step)
 149                    	;   77  //   data - byte for CRC calculation
 150                    	;   78  // return: the new CRC7
 151                    	;   79  */
 152                    	;   80  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
 153                    	;   81      {
 154                    	;   82      const unsigned char g = 0x89;
 155                    	;   83      unsigned char i;
 156                    	;   84  
 157                    	;   85      crcIn ^= data;
 158                    	;   86      for (i = 0; i < 8; i++)
 159                    	;   87          {
 160                    	;   88          if (crcIn & 0x80) crcIn ^= g;
 161                    	;   89          crcIn <<= 1;
 162                    	;   90          }
 163                    	;   91  
 164                    	;   92      return crcIn;
 165                    	;   93      }
 166                    	;   94  
 167                    	;   95  /*
 168                    	;   96  // Calculate CRC16 CCITT
 169                    	;   97  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
 170                    	;   98  // input:
 171                    	;   99  //   crcIn - the CRC before (0 for rist step)
 172                    	;  100  //   data - byte for CRC calculation
 173                    	;  101  // return: the CRC16 value
 174                    	;  102  */
 175                    	;  103  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
 176                    	;  104      {
 177                    	;  105      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
 178                    	;  106      crcIn ^=  data;
 179                    	;  107      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
 180                    	;  108      crcIn ^= (crcIn << 8) << 4;
 181                    	;  109      crcIn ^= ((crcIn & 0xff) << 4) << 1;
 182                    	;  110  
 183                    	;  111      return crcIn;
 184                    	;  112      }
 185                    	;  113  
 186                    	;  114  /* Send command to SD card and recieve answer.
 187                    	;  115   * A command is 5 bytes long and is followed by
 188                    	;  116   * a CRC7 checksum byte.
 189                    	;  117   * Returns a pointer to the response
 190                    	;  118   * or 0 if no response start bit found.
 191                    	;  119   */
 192                    	;  120  unsigned char *sdcommand(unsigned char *sdcmdp,
 193                    	;  121                           unsigned char *recbuf, int recbytes)
 194                    	;  122      {
 195                    	;  123      int searchn;  /* byte counter to search for response */
 196                    	;  124      int sdcbytes; /* byte counter for bytes to send */
 197                    	;  125      unsigned char *retptr; /* pointer used to store response */
 198                    	;  126      unsigned char rbyte;   /* recieved byte */
 199                    	;  127      unsigned char crc = 0; /* calculated CRC7 */
 200                    	;  128  
 201                    	;  129      /* send 8*2 clockpules */
 202                    	;  130      spiio(0xff);
 203                    	;  131      spiio(0xff);
 204                    	;  132      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
 205                    	;  133          {
 206                    	;  134          crc = CRC7_one(crc, *sdcmdp);
 207                    	;  135          spiio(*sdcmdp++);
 208                    	;  136          }
 209                    	;  137      spiio(crc | 0x01);
 210                    	;  138      /* search for recieved byte with start bit
 211                    	;  139         for a maximum of 10 recieved bytes  */
 212                    	;  140      for (searchn = 10; 0 < searchn; searchn--)
 213                    	;  141          {
 214                    	;  142          rbyte = spiio(0xff);
 215                    	;  143          if ((rbyte & 0x80) == 0)
 216                    	;  144              break;
 217                    	;  145          }
 218                    	;  146      if (searchn == 0) /* no start bit found */
 219                    	;  147          return (NO);
 220                    	;  148      retptr = recbuf;
 221                    	;  149      *retptr++ = rbyte;
 222                    	;  150      for (; 1 < recbytes; recbytes--) /* recieve bytes */
 223                    	;  151          *retptr++ = spiio(0xff);
 224                    	;  152      return (recbuf);
 225                    	;  153      }
 226                    	;  154  
 227                    	;  155  /* Initialise SD card interface
 228                    	;  156   *
 229                    	;  157   * returns YES if ok and NO if not ok
 230                    	;  158   *
 231                    	;  159   * References:
 232                    	;  160   *   https://www.sdcard.org/downloads/pls/
 233                    	;  161   *      Physical Layer Simplified Specification version 8.0
 234                    	;  162   *
 235                    	;  163   * A nice flowchart how to initialize:
 236                    	;  164   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
 237                    	;  165   *
 238                    	;  166   */
 239                    	;  167  int sdinit()
 240                    	;  168      {
 241                    	;  169      int nbytes;  /* byte counter */
 242                    	;  170      int tries;   /* tries to get to active state or searching for data  */
 243                    	;  171      int wtloop;  /* timer loop when trying to enter active state */
 244                    	;  172      unsigned char cmdbuf[5];   /* buffer to build command in */
 245                    	;  173      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 246                    	;  174      unsigned char *statptr;    /* pointer to returned status from SD command */
 247                    	;  175      unsigned char crc;         /* crc register for CID and CSD */
 248                    	;  176      unsigned char rbyte;       /* recieved byte */
 249                    	;  177  #ifdef SDTEST
 250                    	;  178      unsigned char *prtptr;     /* for debug printing */
 251                    	;  179  #endif
 252                    	;  180  
 253                    	;  181      ledon();
 254                    	;  182      spideselect();
 255                    	;  183      sdinitok = NO;
 256                    	;  184  
 257                    	;  185      /* start to generate 9*8 clock pulses with not selected SD card */
 258                    	;  186      for (nbytes = 9; 0 < nbytes; nbytes--)
 259                    	;  187          spiio(0xff);
 260                    	;  188  #ifdef SDTEST
 261                    	;  189      printf("\nSent 8*8 (72) clock pulses, select not active\n");
 262                    	;  190  #endif
 263                    	;  191      spiselect();
 264                    	;  192  
 265                    	;  193      /* CMD0: GO_IDLE_STATE */
 266                    	;  194      memcpy(cmdbuf, cmd0, 5);
 267                    	;  195      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 268                    	;  196  #ifdef SDTEST
 269                    	;  197      if (!statptr)
 270                    	;  198          printf("CMD0: no response\n");
 271                    	;  199      else
 272                    	;  200          printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
 273                    	;  201  #endif
 274                    	;  202      if (!statptr)
 275                    	;  203          {
 276                    	;  204          spideselect();
 277                    	;  205          ledoff();
 278                    	;  206          return (NO);
 279                    	;  207          }
 280                    	;  208      /* CMD8: SEND_IF_COND */
 281                    	;  209      memcpy(cmdbuf, cmd8, 5);
 282                    	;  210      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
 283                    	;  211  #ifdef SDTEST
 284                    	;  212      if (!statptr)
 285                    	;  213          printf("CMD8: no response\n");
 286                    	;  214      else
 287                    	;  215          {
 288                    	;  216          printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
 289                    	;  217                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
 290                    	;  218          if (!(statptr[0] & 0xfe)) /* no error */
 291                    	;  219              {
 292                    	;  220              if (statptr[4] == 0xaa)
 293                    	;  221                  printf("echo back ok, ");
 294                    	;  222              else
 295                    	;  223                  printf("invalid echo back\n");
 296                    	;  224              }
 297                    	;  225          }
 298                    	;  226  #endif
 299                    	;  227      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
 300                    	;  228          {
 301                    	;  229          sdver2 = NO;
 302                    	;  230  #ifdef SDTEST
 303                    	;  231          printf("probably SD ver. 1\n");
 304                    	;  232  #endif
 305                    	;  233          }
 306                    	;  234      else
 307                    	;  235          {
 308                    	;  236          sdver2 = YES;
 309                    	;  237          if (statptr[4] != 0xaa) /* but invalid echo back */
 310                    	;  238              {
 311                    	;  239              spideselect();
 312                    	;  240              ledoff();
 313                    	;  241              return (NO);
 314                    	;  242              }
 315                    	;  243  #ifdef SDTEST
 316                    	;  244          printf("SD ver 2\n");
 317                    	;  245  #endif
 318                    	;  246          }
 319                    	;  247  
 320                    	;  248      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
 321                    	;  249      for (tries = 0; tries < 20; tries++)
 322                    	;  250          {
 323                    	;  251          memcpy(cmdbuf, cmd55, 5);
 324                    	;  252          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 325                    	;  253  #ifdef SDTEST
 326                    	;  254          if (!statptr)
 327                    	;  255              printf("CMD55: no response\n");
 328                    	;  256          else
 329                    	;  257              printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
 330                    	;  258  #endif
 331                    	;  259          if (!statptr)
 332                    	;  260              {
 333                    	;  261              spideselect();
 334                    	;  262              ledoff();
 335                    	;  263              return (NO);
 336                    	;  264              }
 337                    	;  265          memcpy(cmdbuf, acmd41, 5);
 338                    	;  266          if (sdver2)
 339                    	;  267              cmdbuf[1] = 0x40;
 340                    	;  268          else
 341                    	;  269              cmdbuf[1] = 0x00;
 342                    	;  270          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 343                    	;  271  #ifdef SDTEST
 344                    	;  272          if (!statptr)
 345                    	;  273              printf("ACMD41: no response\n");
 346                    	;  274          else
 347                    	;  275              printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
 348                    	;  276                     statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
 349                    	;  277  #endif
 350                    	;  278          if (!statptr)
 351                    	;  279              {
 352                    	;  280              spideselect();
 353                    	;  281              ledoff();
 354                    	;  282              return (NO);
 355                    	;  283              }
 356                    	;  284          if (statptr[0] == 0x00) /* now the SD card is ready */
 357                    	;  285              {
 358                    	;  286              break;
 359                    	;  287              }
 360                    	;  288          for (wtloop = 0; wtloop < tries * 100; wtloop++)
 361                    	;  289              ; /* wait loop, time increasing for each try */
 362                    	;  290          }
 363                    	;  291  
 364                    	;  292      /* CMD58: READ_OCR */
 365                    	;  293      /* According to the flow chart this should not work
 366                    	;  294         for SD ver. 1 but the response is ok anyway
 367                    	;  295         all tested SD cards  */
 368                    	;  296      memcpy(cmdbuf, cmd58, 5);
 369                    	;  297      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
 370                    	;  298  #ifdef SDTEST
 371                    	;  299      if (!statptr)
 372                    	;  300          printf("CMD58: no response\n");
 373                    	;  301      else
 374                    	;  302          printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
 375                    	;  303                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
 376                    	;  304  #endif
 377                    	;  305      if (!statptr)
 378                    	;  306          {
 379                    	;  307          spideselect();
 380                    	;  308          ledoff();
 381                    	;  309          return (NO);
 382                    	;  310          }
 383                    	;  311      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
 384                    	;  312      blkmult = 1; /* assume block address */
 385                    	;  313      if (ocrreg[0] & 0x80)
 386                    	;  314          {
 387                    	;  315          /* SD Ver.2+ */
 388                    	;  316          if (!(ocrreg[0] & 0x40))
 389                    	;  317              {
 390                    	;  318              /* SD Ver.2+, Byte address */
 391                    	;  319              blkmult = 512;
 392                    	;  320              }
 393                    	;  321          }
 394                    	;  322  
 395                    	;  323      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
 396                    	;  324      if (blkmult == 512)
 397                    	;  325          {
 398                    	;  326          memcpy(cmdbuf, cmd16, 5);
 399                    	;  327          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 400                    	;  328  #ifdef SDTEST
 401                    	;  329          if (!statptr)
 402                    	;  330              printf("CMD16: no response\n");
 403                    	;  331          else
 404                    	;  332              printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
 405                    	;  333                  statptr[0]);
 406                    	;  334  #endif
 407                    	;  335          if (!statptr)
 408                    	;  336              {
 409                    	;  337              spideselect();
 410                    	;  338              ledoff();
 411                    	;  339              return (NO);
 412                    	;  340              }
 413                    	;  341          }
 414                    	;  342      /* Register information:
 415                    	;  343       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
 416                    	;  344       */
 417                    	;  345  
 418                    	;  346      /* CMD10: SEND_CID */
 419                    	;  347      memcpy(cmdbuf, cmd10, 5);
 420                    	;  348      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 421                    	;  349  #ifdef SDTEST
 422                    	;  350      if (!statptr)
 423                    	;  351          printf("CMD10: no response\n");
 424                    	;  352      else
 425                    	;  353          printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
 426                    	;  354  #endif
 427                    	;  355      if (!statptr)
 428                    	;  356          {
 429                    	;  357          spideselect();
 430                    	;  358          ledoff();
 431                    	;  359          return (NO);
 432                    	;  360          }
 433                    	;  361      /* looking for 0xfe that is the byte before data */
 434                    	;  362      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
 435                    	;  363          ;
 436                    	;  364      if (tries == 0) /* tried too many times */
 437                    	;  365          {
 438                    	;  366  #ifdef SDTEST
 439                    	;  367          printf("  No data found\n");
 440                    	;  368  #endif
 441                    	;  369          spideselect();
 442                    	;  370          ledoff();
 443                    	;  371          return (NO);
 444                    	;  372          }
 445                    	;  373      else
 446                    	;  374          {
 447                    	;  375          crc = 0;
 448                    	;  376          for (nbytes = 0; nbytes < 15; nbytes++)
 449                    	;  377              {
 450                    	;  378              rbyte = spiio(0xff);
 451                    	;  379              cidreg[nbytes] = rbyte;
 452                    	;  380              crc = CRC7_one(crc, rbyte);
 453                    	;  381              }
 454                    	;  382          cidreg[15] = spiio(0xff);
 455                    	;  383          crc |= 0x01;
 456                    	;  384          /* some SD cards need additional clock pulses */
 457                    	;  385          for (nbytes = 9; 0 < nbytes; nbytes--)
 458                    	;  386              spiio(0xff);
 459                    	;  387  #ifdef SDTEST
 460                    	;  388          prtptr = &cidreg[0];
 461                    	;  389          printf("  CID: [");
 462                    	;  390          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 463                    	;  391              printf("%02x ", *prtptr);
 464                    	;  392          prtptr = &cidreg[0];
 465                    	;  393          printf("\b] |");
 466                    	;  394          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 467                    	;  395              {
 468                    	;  396              if ((' ' <= *prtptr) && (*prtptr < 127))
 469                    	;  397                  putchar(*prtptr);
 470                    	;  398              else
 471                    	;  399                  putchar('.');
 472                    	;  400              }
 473                    	;  401          printf("|\n");
 474                    	;  402          if (crc == cidreg[15])
 475                    	;  403              {
 476                    	;  404              printf("CRC7 ok: [%02x]\n", crc);
 477                    	;  405              }
 478                    	;  406          else
 479                    	;  407              {
 480                    	;  408              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
 481                    	;  409                  crc, cidreg[15]);
 482                    	;  410              /* could maybe return failure here */
 483                    	;  411              }
 484                    	;  412  #endif
 485                    	;  413          }
 486                    	;  414  
 487                    	;  415      /* CMD9: SEND_CSD */
 488                    	;  416      memcpy(cmdbuf, cmd9, 5);
 489                    	;  417      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 490                    	;  418  #ifdef SDTEST
 491                    	;  419      if (!statptr)
 492                    	;  420          printf("CMD9: no response\n");
 493                    	;  421      else
 494                    	;  422          printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
 495                    	;  423  #endif
 496                    	;  424      if (!statptr)
 497                    	;  425          {
 498                    	;  426          spideselect();
 499                    	;  427          ledoff();
 500                    	;  428          return (NO);
 501                    	;  429          }
 502                    	;  430      /* looking for 0xfe that is the byte before data */
 503                    	;  431      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
 504                    	;  432          ;
 505                    	;  433      if (tries == 0) /* tried too many times */
 506                    	;  434          {
 507                    	;  435  #ifdef SDTEST
 508                    	;  436          printf("  No data found\n");
 509                    	;  437  #endif
 510                    	;  438          return (NO);
 511                    	;  439          }
 512                    	;  440      else
 513                    	;  441          {
 514                    	;  442          crc = 0;
 515                    	;  443          for (nbytes = 0; nbytes < 15; nbytes++)
 516                    	;  444              {
 517                    	;  445              rbyte = spiio(0xff);
 518                    	;  446              csdreg[nbytes] = rbyte;
 519                    	;  447              crc = CRC7_one(crc, rbyte);
 520                    	;  448              }
 521                    	;  449          csdreg[15] = spiio(0xff);
 522                    	;  450          crc |= 0x01;
 523                    	;  451          /* some SD cards need additional clock pulses */
 524                    	;  452          for (nbytes = 9; 0 < nbytes; nbytes--)
 525                    	;  453              spiio(0xff);
 526                    	;  454  #ifdef SDTEST
 527                    	;  455          prtptr = &csdreg[0];
 528                    	;  456          printf("  CSD: [");
 529                    	;  457          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 530                    	;  458              printf("%02x ", *prtptr);
 531                    	;  459          prtptr = &csdreg[0];
 532                    	;  460          printf("\b] |");
 533                    	;  461          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 534                    	;  462              {
 535                    	;  463              if ((' ' <= *prtptr) && (*prtptr < 127))
 536                    	;  464                  putchar(*prtptr);
 537                    	;  465              else
 538                    	;  466                  putchar('.');
 539                    	;  467              }
 540                    	;  468          printf("|\n");
 541                    	;  469          if (crc == csdreg[15])
 542                    	;  470              {
 543                    	;  471              printf("CRC7 ok: [%02x]\n", crc);
 544                    	;  472              }
 545                    	;  473          else
 546                    	;  474              {
 547                    	;  475              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
 548                    	;  476                  crc, csdreg[15]);
 549                    	;  477              /* could maybe return failure here */
 550                    	;  478              }
 551                    	;  479  #endif
 552                    	;  480          }
 553                    	;  481  
 554                    	;  482      for (nbytes = 9; 0 < nbytes; nbytes--)
 555                    	;  483          spiio(0xff);
 556                    	;  484  #ifdef SDTEST
 557                    	;  485      printf("Sent 9*8 (72) clock pulses, select active\n");
 558                    	;  486  #endif
 559                    	;  487  
 560                    	;  488      sdinitok = YES;
 561                    	;  489  
 562                    	;  490      spideselect();
 563                    	;  491      ledoff();
 564                    	;  492  
 565                    	;  493      return (YES);
 566                    	;  494      }
 567                    	;  495  
 568                    	;  496  /* print OCR, CID and CSD registers*/
 569                    	;  497  void sdprtreg()
 570                    	;  498      {
 571                    	;  499      unsigned int n;
 572                    	;  500      unsigned int csize;
 573                    	;  501      unsigned long devsize;
 574                    	;  502      unsigned long capacity;
 575                    	;  503  
 576                    	;  504      if (!sdinitok)
 577                    	;  505          {
 578                    	;  506          printf("SD card not initialized\n");
 579                    	;  507          return;
 580                    	;  508          }
 581                    	;  509      printf("SD card information:");
 582                    	;  510      if (ocrreg[0] & 0x80)
 583                    	;  511          {
 584                    	;  512          if (ocrreg[0] & 0x40)
 585                    	;  513              printf("  SD card ver. 2+, Block address\n");
 586                    	;  514          else
 587                    	;  515              {
 588                    	;  516              if (sdver2)
 589                    	;  517                  printf("  SD card ver. 2+, Byte address\n");
 590                    	;  518              else
 591                    	;  519                  printf("  SD card ver. 1, Byte address\n");
 592                    	;  520              }
 593                    	;  521          }
 594                    	;  522      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
 595                    	;  523      printf("OEM ID: %.2s, ", &cidreg[1]);
 596                    	;  524      printf("Product name: %.5s\n", &cidreg[3]);
 597                    	;  525      printf("  Product revision: %d.%d, ",
 598                    	;  526             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 599                    	;  527      printf("Serial number: %lu\n",
 600                    	;  528             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
 601                    	;  529      printf("  Manufacturing date: %d-%d, ",
 602                    	;  530             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
 603                    	;  531      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
 604                    	;  532          {
 605                    	;  533          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
 606                    	;  534          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
 607                    	;  535                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
 608                    	;  536          capacity = (unsigned long) csize << (n-10);
 609                    	;  537          printf("Device capacity: %lu MByte\n", capacity >> 10);
 610                    	;  538          }
 611                    	;  539      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
 612                    	;  540          {
 613                    	;  541          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
 614                    	;  542                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 615                    	;  543          capacity = devsize << 9;
 616                    	;  544          printf("Device capacity: %lu MByte\n", capacity >> 10);
 617                    	;  545          }
 618                    	;  546      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
 619                    	;  547          {
 620                    	;  548          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
 621                    	;  549                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 622                    	;  550          capacity = devsize << 9;
 623                    	;  551          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
 624                    	;  552          }
 625                    	;  553  
 626                    	;  554  #ifdef SDTEST
 627                    	;  555  
 628                    	;  556      printf("--------------------------------------\n");
 629                    	;  557      printf("OCR register:\n");
 630                    	;  558      if (ocrreg[2] & 0x80)
 631                    	;  559          printf("2.7-2.8V (bit 15) ");
 632                    	;  560      if (ocrreg[1] & 0x01)
 633                    	;  561          printf("2.8-2.9V (bit 16) ");
 634                    	;  562      if (ocrreg[1] & 0x02)
 635                    	;  563          printf("2.9-3.0V (bit 17) ");
 636                    	;  564      if (ocrreg[1] & 0x04)
 637                    	;  565          printf("3.0-3.1V (bit 18) \n");
 638                    	;  566      if (ocrreg[1] & 0x08)
 639                    	;  567          printf("3.1-3.2V (bit 19) ");
 640                    	;  568      if (ocrreg[1] & 0x10)
 641                    	;  569          printf("3.2-3.3V (bit 20) ");
 642                    	;  570      if (ocrreg[1] & 0x20)
 643                    	;  571          printf("3.3-3.4V (bit 21) ");
 644                    	;  572      if (ocrreg[1] & 0x40)
 645                    	;  573          printf("3.4-3.5V (bit 22) \n");
 646                    	;  574      if (ocrreg[1] & 0x80)
 647                    	;  575          printf("3.5-3.6V (bit 23) \n");
 648                    	;  576      if (ocrreg[0] & 0x01)
 649                    	;  577          printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
 650                    	;  578      if (ocrreg[0] & 0x08)
 651                    	;  579          printf("Over 2TB support Status (CO2T) (bit 27) set\n");
 652                    	;  580      if (ocrreg[0] & 0x20)
 653                    	;  581          printf("UHS-II Card Status (bit 29) set ");
 654                    	;  582      if (ocrreg[0] & 0x80)
 655                    	;  583          {
 656                    	;  584          if (ocrreg[0] & 0x40)
 657                    	;  585              {
 658                    	;  586              printf("Card Capacity Status (CCS) (bit 30) set\n");
 659                    	;  587              printf("  SD Ver.2+, Block address");
 660                    	;  588              }
 661                    	;  589          else
 662                    	;  590              {
 663                    	;  591              printf("Card Capacity Status (CCS) (bit 30) not set\n");
 664                    	;  592              if (sdver2)
 665                    	;  593                  printf("  SD Ver.2+, Byte address");
 666                    	;  594              else
 667                    	;  595                  printf("  SD Ver.1, Byte address");
 668                    	;  596              }
 669                    	;  597          printf("\nCard power up status bit (busy) (bit 31) set\n");
 670                    	;  598          }
 671                    	;  599      else
 672                    	;  600          {
 673                    	;  601          printf("\nCard power up status bit (busy) (bit 31) not set.\n");
 674                    	;  602          printf("  This bit is not set if the card has not finished the power up routine.\n");
 675                    	;  603          }
 676                    	;  604      printf("--------------------------------------\n");
 677                    	;  605      printf("CID register:\n");
 678                    	;  606      printf("MID: 0x%02x, ", cidreg[0]);
 679                    	;  607      printf("OID: %.2s, ", &cidreg[1]);
 680                    	;  608      printf("PNM: %.5s, ", &cidreg[3]);
 681                    	;  609      printf("PRV: %d.%d, ",
 682                    	;  610             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 683                    	;  611      printf("PSN: %lu, ",
 684                    	;  612             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
 685                    	;  613      printf("MDT: %d-%d\n",
 686                    	;  614             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
 687                    	;  615      printf("--------------------------------------\n");
 688                    	;  616      printf("CSD register:\n");
 689                    	;  617      if ((csdreg[0] & 0xc0) == 0x00)
 690                    	;  618          {
 691                    	;  619          printf("CSD Version 1.0, Standard Capacity\n");
 692                    	;  620          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
 693                    	;  621          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
 694                    	;  622                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
 695                    	;  623          capacity = (unsigned long) csize << (n-10);
 696                    	;  624          printf(" Device capacity: %lu KByte, %lu MByte\n",
 697                    	;  625                 capacity, capacity >> 10);
 698                    	;  626          }
 699                    	;  627      if ((csdreg[0] & 0xc0) == 0x40)
 700                    	;  628          {
 701                    	;  629          printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
 702                    	;  630          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
 703                    	;  631                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 704                    	;  632          capacity = devsize << 9;
 705                    	;  633          printf(" Device capacity: %lu KByte, %lu MByte\n",
 706                    	;  634                 capacity, capacity >> 10);
 707                    	;  635          }
 708                    	;  636      if ((csdreg[0] & 0xc0) == 0x80)
 709                    	;  637          {
 710                    	;  638          printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
 711                    	;  639          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
 712                    	;  640                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 713                    	;  641          capacity = devsize << 9;
 714                    	;  642          printf(" Device capacity: %lu KByte, %lu MByte\n",
 715                    	;  643                 capacity, capacity >> 10);
 716                    	;  644          }
 717                    	;  645      printf("--------------------------------------\n");
 718                    	;  646  
 719                    	;  647  #endif /* SDTEST */
 720                    	;  648  
 721                    	;  649      }
 722                    	;  650  
 723                    	;  651  /* Read data block of 512 bytes to buffer
 724                    	;  652   * Returns YES if ok or NO if error
 725                    	;  653   */
 726                    	;  654  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
 727                    	;  655      {
 728                    	;  656      unsigned char *statptr;
 729                    	;  657      unsigned char rbyte;
 730                    	;  658      unsigned char cmdbuf[5];   /* buffer to build command in */
 731                    	;  659      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 732                    	;  660      int nbytes;
 733                    	;  661      int tries;
 734                    	;  662      unsigned long blktoread;
 735                    	;  663      unsigned int rxcrc16;
 736                    	;  664      unsigned int calcrc16;
 737                    	;  665  
 738                    	;  666      ledon();
 739                    	;  667      spiselect();
 740                    	;  668  
 741                    	;  669      if (!sdinitok)
 742                    	;  670          {
 743                    	;  671  #ifdef SDTEST
 744                    	;  672          printf("SD card not initialized\n");
 745                    	;  673  #endif
 746                    	;  674          spideselect();
 747                    	;  675          ledoff();
 748                    	;  676          return (NO);
 749                    	;  677          }
 750                    	;  678  
 751                    	;  679      /* CMD17: READ_SINGLE_BLOCK */
 752                    	;  680      /* Insert block # into command */
 753                    	;  681      memcpy(cmdbuf, cmd17, 5);
 754                    	;  682      blktoread = blkmult * rdblkno;
 755                    	;  683      cmdbuf[4] = blktoread & 0xff;
 756                    	;  684      blktoread = blktoread >> 8;
 757                    	;  685      cmdbuf[3] = blktoread & 0xff;
 758                    	;  686      blktoread = blktoread >> 8;
 759                    	;  687      cmdbuf[2] = blktoread & 0xff;
 760                    	;  688      blktoread = blktoread >> 8;
 761                    	;  689      cmdbuf[1] = blktoread & 0xff;
 762                    	;  690  
 763                    	;  691  #ifdef SDTEST
 764                    	;  692      printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
 765                    	;  693                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
 766                    	;  694  #endif
 767                    	;  695      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 768                    	;  696  #ifdef SDTEST
 769                    	;  697          printf("CMD17 R1 response [%02x]\n", statptr[0]);
 770                    	;  698  #endif
 771                    	;  699      if (statptr[0])
 772                    	;  700          {
 773                    	;  701  #ifdef SDTEST
 774                    	;  702          printf("  could not read block\n");
 775                    	;  703  #endif
 776                    	;  704          spideselect();
 777                    	;  705          ledoff();
 778                    	;  706          return (NO);
 779                    	;  707          }
 780                    	;  708      /* looking for 0xfe that is the byte before data */
 781                    	;  709      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
 782                    	;  710          {
 783                    	;  711          if ((rbyte & 0xe0) == 0x00)
 784                    	;  712              {
 785                    	;  713              /* If a read operation fails and the card cannot provide
 786                    	;  714                 the required data, it will send a data error token instead
 787                    	;  715               */
 788                    	;  716  #ifdef SDTEST
 789                    	;  717              printf("  read error: [%02x]\n", rbyte);
 790                    	;  718  #endif
 791                    	;  719              spideselect();
 792                    	;  720              ledoff();
 793                    	;  721              return (NO);
 794                    	;  722              }
 795                    	;  723          }
 796                    	;  724      if (tries == 0) /* tried too many times */
 797                    	;  725          {
 798                    	;  726  #ifdef SDTEST
 799                    	;  727          printf("  no data found\n");
 800                    	;  728  #endif
 801                    	;  729          spideselect();
 802                    	;  730          ledoff();
 803                    	;  731          return (NO);
 804                    	;  732          }
 805                    	;  733      else
 806                    	;  734          {
 807                    	;  735          calcrc16 = 0;
 808                    	;  736          for (nbytes = 0; nbytes < 512; nbytes++)
 809                    	;  737              {
 810                    	;  738              rbyte = spiio(0xff);
 811                    	;  739              calcrc16 = CRC16_one(calcrc16, rbyte);
 812                    	;  740              rdbuf[nbytes] = rbyte;
 813                    	;  741              }
 814                    	;  742          rxcrc16 = spiio(0xff) << 8;
 815                    	;  743          rxcrc16 += spiio(0xff);
 816                    	;  744  
 817                    	;  745  #ifdef SDTEST
 818                    	;  746          printf("  read data block %ld:\n", rdblkno);
 819                    	;  747  #endif
 820                    	;  748          if (rxcrc16 != calcrc16)
 821                    	;  749              {
 822                    	;  750  #ifdef SDTEST
 823                    	;  751              printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
 824                    	;  752                  rxcrc16, calcrc16);
 825                    	;  753  #endif
 826                    	;  754              spideselect();
 827                    	;  755              ledoff();
 828                    	;  756              return (NO);
 829                    	;  757              }
 830                    	;  758          }
 831                    	;  759      spideselect();
 832                    	;  760      ledoff();
 833                    	;  761      return (YES);
 834                    	;  762      }
 835                    	;  763  
 836                    	;  764  /* Write data block of 512 bytes from buffer
 837                    	;  765   * Returns YES if ok or NO if error
 838                    	;  766   */
 839                    	;  767  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
 840                    	;  768      {
 841                    	;  769      unsigned char *statptr;
 842                    	;  770      unsigned char rbyte;
 843                    	;  771      unsigned char tbyte;
 844                    	;  772      unsigned char cmdbuf[5];   /* buffer to build command in */
 845                    	;  773      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 846                    	;  774      int nbytes;
 847                    	;  775      int tries;
 848                    	;  776      unsigned long blktowrite;
 849                    	;  777      unsigned int calcrc16;
 850                    	;  778  
 851                    	;  779      ledon();
 852                    	;  780      spiselect();
 853                    	;  781  
 854                    	;  782      if (!sdinitok)
 855                    	;  783          {
 856                    	;  784  #ifdef SDTEST
 857                    	;  785          printf("SD card not initialized\n");
 858                    	;  786  #endif
 859                    	;  787          spideselect();
 860                    	;  788          ledoff();
 861                    	;  789          return (NO);
 862                    	;  790          }
 863                    	;  791  
 864                    	;  792  #ifdef SDTEST
 865                    	;  793      printf("  write data block %ld:\n", wrblkno);
 866                    	;  794  #endif
 867                    	;  795      /* CMD24: WRITE_SINGLE_BLOCK */
 868                    	;  796      /* Insert block # into command */
 869                    	;  797      memcpy(cmdbuf, cmd24, 5);
 870                    	;  798      blktowrite = blkmult * wrblkno;
 871                    	;  799      cmdbuf[4] = blktowrite & 0xff;
 872                    	;  800      blktowrite = blktowrite >> 8;
 873                    	;  801      cmdbuf[3] = blktowrite & 0xff;
 874                    	;  802      blktowrite = blktowrite >> 8;
 875                    	;  803      cmdbuf[2] = blktowrite & 0xff;
 876                    	;  804      blktowrite = blktowrite >> 8;
 877                    	;  805      cmdbuf[1] = blktowrite & 0xff;
 878                    	;  806  
 879                    	;  807  #ifdef SDTEST
 880                    	;  808      printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
 881                    	;  809                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
 882                    	;  810  #endif
 883                    	;  811      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 884                    	;  812  #ifdef SDTEST
 885                    	;  813          printf("CMD24 R1 response [%02x]\n", statptr[0]);
 886                    	;  814  #endif
 887                    	;  815      if (statptr[0])
 888                    	;  816          {
 889                    	;  817  #ifdef SDTEST
 890                    	;  818          printf("  could not write block\n");
 891                    	;  819  #endif
 892                    	;  820          spideselect();
 893                    	;  821          ledoff();
 894                    	;  822          return (NO);
 895                    	;  823          }
 896                    	;  824      /* send 0xfe, the byte before data */
 897                    	;  825      spiio(0xfe);
 898                    	;  826      /* initialize crc and send block */
 899                    	;  827      calcrc16 = 0;
 900                    	;  828      for (nbytes = 0; nbytes < 512; nbytes++)
 901                    	;  829          {
 902                    	;  830          tbyte = wrbuf[nbytes];
 903                    	;  831          spiio(tbyte);
 904                    	;  832          calcrc16 = CRC16_one(calcrc16, tbyte);
 905                    	;  833          }
 906                    	;  834      spiio((calcrc16 >> 8) & 0xff);
 907                    	;  835      spiio(calcrc16 & 0xff);
 908                    	;  836  
 909                    	;  837      /* check data resposnse */
 910                    	;  838      for (tries = 20; 
 911                    	;  839          0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
 912                    	;  840          tries--)
 913                    	;  841          ;
 914                    	;  842      if (tries == 0)
 915                    	;  843          {
 916                    	;  844  #ifdef SDTEST
 917                    	;  845          printf("No data response\n");
 918                    	;  846  #endif
 919                    	;  847          spideselect();
 920                    	;  848          ledoff();
 921                    	;  849          return (NO);
 922                    	;  850          }
 923                    	;  851      else
 924                    	;  852          {
 925                    	;  853  #ifdef SDTEST
 926                    	;  854          printf("Data response [%02x]", 0x1f & rbyte);
 927                    	;  855  #endif
 928                    	;  856          if ((0x1f & rbyte) == 0x05)
 929                    	;  857              {
 930                    	;  858  #ifdef SDTEST
 931                    	;  859              printf(", data accepted\n");
 932                    	;  860  #endif
 933                    	;  861              for (nbytes = 9; 0 < nbytes; nbytes--)
 934                    	;  862                  spiio(0xff);
 935                    	;  863  #ifdef SDTEST
 936                    	;  864              printf("Sent 9*8 (72) clock pulses, select active\n");
 937                    	;  865  #endif
 938                    	;  866              spideselect();
 939                    	;  867              ledoff();
 940                    	;  868              return (YES);
 941                    	;  869              }
 942                    	;  870          else
 943                    	;  871              {
 944                    	;  872  #ifdef SDTEST
 945                    	;  873              printf(", data not accepted\n");
 946                    	;  874  #endif
 947                    	;  875              spideselect();
 948                    	;  876              ledoff();
 949                    	;  877              return (NO);
 950                    	;  878              }
 951                    	;  879          }
 952                    	;  880      }
 953                    	;  881  
 954                    	;  882  /* Print data in 512 byte buffer */
 955                    	;  883  void sddatprt(unsigned char *prtbuf)
 956                    	;  884      {
 957                    	;  885      /* Variables used for "pretty-print" */
 958                    	;  886      int allzero, dmpline, dotprted, lastallz, nbytes;
 959                    	;  887      unsigned char *prtptr;
 960                    	;  888  
 961                    	;  889      prtptr = prtbuf;
 962                    	;  890      dotprted = NO;
 963                    	;  891      lastallz = NO;
 964                    	;  892      for (dmpline = 0; dmpline < 32; dmpline++)
 965                    	;  893          {
 966                    	;  894          /* test if all 16 bytes are 0x00 */
 967                    	;  895          allzero = YES;
 968                    	;  896          for (nbytes = 0; nbytes < 16; nbytes++)
 969                    	;  897              {
 970                    	;  898              if (prtptr[nbytes] != 0)
 971                    	;  899                  allzero = NO;
 972                    	;  900              }
 973                    	;  901          if (lastallz && allzero)
 974                    	;  902              {
 975                    	;  903              if (!dotprted)
 976                    	;  904                  {
 977                    	;  905                  printf("*\n");
 978                    	;  906                  dotprted = YES;
 979                    	;  907                  }
 980                    	;  908              }
 981                    	;  909          else
 982                    	;  910              {
 983                    	;  911              dotprted = NO;
 984                    	;  912              /* print offset */
 985                    	;  913              printf("%04x ", dmpline * 16);
 986                    	;  914              /* print 16 bytes in hex */
 987                    	;  915              for (nbytes = 0; nbytes < 16; nbytes++)
 988                    	;  916                  printf("%02x ", prtptr[nbytes]);
 989                    	;  917              /* print these bytes in ASCII if printable */
 990                    	;  918              printf(" |");
 991                    	;  919              for (nbytes = 0; nbytes < 16; nbytes++)
 992                    	;  920                  {
 993                    	;  921                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
 994                    	;  922                      putchar(prtptr[nbytes]);
 995                    	;  923                  else
 996                    	;  924                      putchar('.');
 997                    	;  925                  }
 998                    	;  926              printf("|\n");
 999                    	;  927              }
1000                    	;  928          prtptr += 16;
1001                    	;  929          lastallz = allzero;
1002                    	;  930          }
1003                    	;  931      }
1004                    	;  932  
1005                    	;  933  /* print GUID (mixed endian format) */
1006                    	;  934  void prtguid(unsigned char *guidptr)
1007                    	;  935      {
1008                    	;  936      int index;
1009                    	;  937  
1010                    	;  938      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
1011                    	;  939      printf("%02x%02x-", guidptr[5], guidptr[4]);
1012                    	;  940      printf("%02x%02x-", guidptr[7], guidptr[6]);
1013                    	;  941      printf("%02x%02x-", guidptr[8], guidptr[9]);
1014                    	;  942      printf("%02x%02x%02x%02x%02x%02x",
1015                    	;  943             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
1016                    	;  944      printf("\n  [");
1017                    	;  945      for (index = 0; index < 16; index++)
1018                    	;  946          printf("%02x ", guidptr[index]);
1019                    	;  947      printf("\b]");
1020                    	;  948      }
1021                    	;  949  
1022                    	;  950  /* print GPT entry */
1023                    	;  951  void prtgptent(unsigned int entryno)
1024                    	;  952      {
1025                    	;  953      int index;
1026                    	;  954      int entryidx;
1027                    	;  955      int hasname;
1028                    	;  956      unsigned int block;
1029                    	;  957      unsigned char *rxdata;
1030                    	;  958      unsigned char *entryptr;
1031                    	;  959      unsigned char tstzero = 0;
1032                    	;  960      unsigned long flba;
1033                    	;  961      unsigned long llba;
1034                    	;  962  
1035                    	;  963      block = 2 + (entryno / 4);
1036                    	;  964      if ((curblkno != block) || !curblkok)
1037                    	;  965          {
1038                    	;  966          if (!sdread(sdrdbuf, block))
1039                    	;  967              {
1040                    	;  968              printf("Can't read GPT entry block\n");
1041                    	;  969              return;
1042                    	;  970              }
1043                    	;  971          curblkno = block;
1044                    	;  972          curblkok = YES;
1045                    	;  973          }
1046                    	;  974      rxdata = sdrdbuf;
1047                    	;  975      entryptr = rxdata + (128 * (entryno % 4));
1048                    	;  976      for (index = 0; index < 16; index++)
1049                    	;  977          tstzero |= entryptr[index];
1050                    	;  978      printf("GPT partition entry %d:", entryno + 1);
1051                    	;  979      if (!tstzero)
1052                    	;  980          {
1053                    	;  981          printf(" Not used entry\n");
1054                    	;  982          return;
1055                    	;  983          }
1056                    	;  984      printf("\n  Partition type GUID: ");
1057                    	;  985      prtguid(entryptr);
1058                    	;  986      printf("\n  Unique partition GUID: ");
1059                    	;  987      prtguid(entryptr + 16);
1060                    	;  988      printf("\n  First LBA: ");
1061                    	;  989      /* lower 32 bits of LBA should be sufficient (I hope) */
1062                    	;  990      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
1063                    	;  991             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
1064                    	;  992      printf("%lu", flba);
1065                    	;  993      printf(" [");
1066                    	;  994      for (index = 32; index < (32 + 8); index++)
1067                    	;  995          printf("%02x ", entryptr[index]);
1068                    	;  996      printf("\b]");
1069                    	;  997      printf("\n  Last LBA: ");
1070                    	;  998      /* lower 32 bits of LBA should be sufficient (I hope) */
1071                    	;  999      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
1072                    	; 1000             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
1073                    	; 1001      printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
1074                    	; 1002      printf(" [");
1075                    	; 1003      for (index = 40; index < (40 + 8); index++)
1076                    	; 1004          printf("%02x ", entryptr[index]);
1077                    	; 1005      printf("\b]");
1078                    	; 1006      printf("\n  Attribute flags: [");
1079                    	; 1007      /* bits 0 - 2 and 60 - 63 should be decoded */
1080                    	; 1008      for (index = 0; index < 8; index++)
1081                    	; 1009          {
1082                    	; 1010          entryidx = index + 48;
1083                    	; 1011          printf("%02x ", entryptr[entryidx]);
1084                    	; 1012          }
1085                    	; 1013      printf("\b]\n  Partition name:  ");
1086                    	; 1014      /* partition name is in UTF-16LE code units */
1087                    	; 1015      hasname = NO;
1088                    	; 1016      for (index = 0; index < 72; index += 2)
1089                    	; 1017          {
1090                    	; 1018          entryidx = index + 56;
1091                    	; 1019          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
1092                    	; 1020              break;
1093                    	; 1021          if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
1094                    	; 1022              putchar(entryptr[entryidx]);
1095                    	; 1023          else
1096                    	; 1024              putchar('.');
1097                    	; 1025          hasname = YES;
1098                    	; 1026          }
1099                    	; 1027      if (!hasname)
1100                    	; 1028          printf("name field empty");
1101                    	; 1029      printf("\n");
1102                    	; 1030      printf("   [");
1103                    	; 1031      entryidx = index + 56;
1104                    	; 1032      for (index = 0; index < 72; index++)
1105                    	; 1033          {
1106                    	; 1034          if (((index & 0xf) == 0) && (index != 0))
1107                    	; 1035              printf("\n    ");
1108                    	; 1036          printf("%02x ", entryptr[entryidx]);
1109                    	; 1037          }
1110                    	; 1038      printf("\b]\n");
1111                    	; 1039      }
1112                    	; 1040  
1113                    	; 1041  /* Get GPT header */
1114                    	; 1042  void sdgpthdr(unsigned long block)
1115                    	; 1043      {
1116                    	; 1044      int index;
1117                    	; 1045      unsigned int partno;
1118                    	; 1046      unsigned char *rxdata;
1119                    	; 1047      unsigned long entries;
1120                    	; 1048  
1121                    	; 1049      printf("GPT header\n");
1122                    	; 1050      if (!sdread(sdrdbuf, block))
1123                    	; 1051          {
1124                    	; 1052          printf("Can't read GPT partition table header\n");
1125                    	; 1053          return;
1126                    	; 1054          }
1127                    	; 1055      curblkno = block;
1128                    	; 1056      curblkok = YES;
1129                    	; 1057  
1130                    	; 1058      rxdata = sdrdbuf;
1131                    	; 1059      printf("  Signature: %.8s\n", &rxdata[0]);
1132                    	; 1060      printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
1133                    	; 1061             (int)rxdata[8] * ((int)rxdata[9] << 8),
1134                    	; 1062             (int)rxdata[10] + ((int)rxdata[11] << 8),
1135                    	; 1063             rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
1136                    	; 1064      entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
1137                    	; 1065                ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
1138                    	; 1066      printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
1139                    	; 1067      for (partno = 0; partno < 16; partno++)
1140                    	; 1068          {
1141                    	; 1069          prtgptent(partno);
1142                    	; 1070          }
1143                    	; 1071      printf("First 16 GPT entries scanned\n");
1144                    	; 1072      }
1145                    	; 1073  
1146                    	; 1074  /* read MBR partition entry */
1147                    	; 1075  int sdmbrentry(unsigned char *partptr)
1148                    	; 1076      {
1149                    	; 1077      int index;
1150                    	; 1078      unsigned long lbastart;
1151                    	; 1079      unsigned long lbasize;
1152                    	; 1080  
1153                    	; 1081      if ((curblkno != 0) || !curblkok)
1154                    	; 1082          {
1155                    	; 1083          curblkno = 0;
1156                    	; 1084          if (!sdread(sdrdbuf, curblkno))
1157                    	; 1085              {
1158                    	; 1086              printf("Can't read MBR sector\n");
1159                    	; 1087              return;
1160                    	; 1088              }
1161                    	; 1089          curblkok = YES;
1162                    	; 1090          }
1163                    	; 1091      if (!partptr[4])
1164                    	; 1092          {
1165                    	; 1093          printf("Not used entry\n");
1166                    	; 1094          return;
1167                    	; 1095          }
1168                    	; 1096      printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
1169                    	; 1097             partptr[0], partptr[4]);
1170                    	; 1098  
1171                    	; 1099      if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
1172                    	; 1100          {
1173                    	; 1101          printf("  Extended partition\n");
1174                    	; 1102          /* should probably decode this also */
1175                    	; 1103          }
1176                    	; 1104      if (partptr[0] & 0x01)
1177                    	; 1105          {
1178                    	; 1106          printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
1179                    	; 1107          /* this is however discussed
1180                    	; 1108             https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
1181                    	; 1109          */
1182                    	; 1110          }
1183                    	; 1111      else
1184                    	; 1112          {
1185                    	; 1113          printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1186                    	; 1114                 partptr[1], partptr[2], partptr[3],
1187                    	; 1115                 ((partptr[2] & 0xc0) >> 2) + partptr[3],
1188                    	; 1116                 partptr[1],
1189                    	; 1117                 partptr[2] & 0x3f);
1190                    	; 1118          printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1191                    	; 1119                 partptr[5], partptr[6], partptr[7],
1192                    	; 1120                 ((partptr[6] & 0xc0) >> 2) + partptr[7],
1193                    	; 1121                 partptr[5],
1194                    	; 1122                 partptr[6] & 0x3f);
1195                    	; 1123          }
1196                    	; 1124      /* not showing high 16 bits if 48 bit LBA */
1197                    	; 1125      lbastart = (unsigned long)partptr[8] +
1198                    	; 1126                 ((unsigned long)partptr[9] << 8) +
1199                    	; 1127                 ((unsigned long)partptr[10] << 16) +
1200                    	; 1128                 ((unsigned long)partptr[11] << 24);
1201                    	; 1129      lbasize = (unsigned long)partptr[12] +
1202                    	; 1130                ((unsigned long)partptr[13] << 8) +
1203                    	; 1131                ((unsigned long)partptr[14] << 16) +
1204                    	; 1132                ((unsigned long)partptr[15] << 24);
1205                    	; 1133      printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
1206                    	; 1134      printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
1207                    	; 1135             lbasize, lbasize, lbasize >> 11);
1208                    	; 1136      if (partptr[4] == 0xee)
1209                    	; 1137          sdgpthdr(lbastart);
1210                    	; 1138      }
1211                    	; 1139  
1212                    	; 1140  /* read MBR partition information */
1213                    	; 1141  void sdmbrpart()
1214                    	; 1142      {
1215                    	; 1143      int partidx;  /* partition index 1 - 4 */
1216                    	; 1144      unsigned char *entp; /* pointer to partition entry */
1217                    	; 1145  
1218                    	; 1146  #ifdef SDTEST
1219                    	; 1147      printf("Read MBR\n");
1220                    	; 1148  #endif
1221                    	; 1149      if (!sdread(sdrdbuf, 0))
1222                    	; 1150          {
1223                    	; 1151  #ifdef SDTEST
1224                    	; 1152          printf("  can't read MBR sector\n");
1225                    	; 1153  #endif
1226                    	; 1154          return;
1227                    	; 1155          }
1228                    	; 1156      curblkno = 0;
1229                    	; 1157      curblkok = YES;
1230                    	; 1158      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
1231                    	; 1159          {
1232                    	; 1160  #ifdef SDTEST
1233                    	; 1161          printf("  no MBR signature found\n");
1234                    	; 1162  #endif
1235                    	; 1163          return;
1236                    	; 1164          }
1237                    	; 1165      /* go through MBR partition entries until first empty */
1238                    	; 1166      entp = &sdrdbuf[0x01be];
1239                    	; 1167      for (partidx = 1; partidx <= 4; partidx++, entp += 16)
1240                    	; 1168          {
1241                    	; 1169  #ifdef SDTEST
1242                    	; 1170          printf("MBR partition entry %d: ", partidx);
1243                    	; 1171  #endif
1244                    	; 1172          if (!sdmbrentry(entp))
1245                    	; 1173              break;
1246                    	; 1174          }
1247                    	; 1175      }
1248                    	; 1176  
1249                    	; 1177  /* Test init, read and partitions on SD card over the SPI interface
1250                    	; 1178   *
1251                    	; 1179   */
1252                    	; 1180  int main()
1253                    	; 1181      {
1254                    	; 1182      char txtin[10];
1255                    	; 1183      int cmdin;
1256                    	; 1184      int inlength;
1257                    	; 1185      unsigned long blockno;
1258                    	; 1186  
1259                    	; 1187      blockno = 0;
1260                    	; 1188      curblkno = 0;
1261    2529  320000    		ld	(_curblkno),a
1262    252C  320100    		ld	(_curblkno+1),a
1263    252F  320200    		ld	(_curblkno+2),a
1264    2532  320300    		ld	(_curblkno+3),a
1265    2535  220C00    		ld	(_curblkok),hl
1266                    	; 1189      curblkok = NO;
1267                    	; 1190      sdinitok = NO; /* SD card not initialized yet */
1268    2538  210000    		ld	hl,0
1269    253B  220A00    		ld	(_sdinitok),hl
1270                    	; 1191  
1271                    	; 1192      printf(PRGNAME);
1272    253E  217F22    		ld	hl,L5301
1273    2541  CD0000    		call	_printf
1274                    	; 1193      printf(VERSION);
1275    2544  218922    		ld	hl,L5401
1276    2547  CD0000    		call	_printf
1277                    	; 1194      printf(builddate);
1278    254A  210000    		ld	hl,_builddate
1279    254D  CD0000    		call	_printf
1280                    	; 1195      printf("\n");
1281    2550  219722    		ld	hl,L5501
1282    2553  CD0000    		call	_printf
1283                    	L1213:
1284                    	; 1196      while (YES) /* forever (until Ctrl-C) */
1285                    	; 1197          {
1286                    	; 1198          printf("cmd (h for help): ");
1287    2556  219922    		ld	hl,L5601
1288    2559  CD0000    		call	_printf
1289                    	; 1199  
1290                    	; 1200          cmdin = getchar();
1291    255C  CD0000    		call	_getchar
1292    255F  DD71EE    		ld	(ix-18),c
1293    2562  DD70EF    		ld	(ix-17),b
1294                    	; 1201          switch (cmdin)
1295    2565  DD4EEE    		ld	c,(ix-18)
1296    2568  DD46EF    		ld	b,(ix-17)
1297    256B  21E724    		ld	hl,L1413
1298    256E  C30000    		jp	c.jtab
1299                    	L1613:
1300                    	; 1202              {
1301                    	; 1203              case 'h':
1302                    	; 1204                  printf(" h - help\n");
1303    2571  21AC22    		ld	hl,L5701
1304    2574  CD0000    		call	_printf
1305                    	; 1205                  printf(PRGNAME);
1306    2577  21B722    		ld	hl,L5011
1307    257A  CD0000    		call	_printf
1308                    	; 1206                  printf(VERSION);
1309    257D  21C122    		ld	hl,L5111
1310    2580  CD0000    		call	_printf
1311                    	; 1207                  printf(builddate);
1312    2583  210000    		ld	hl,_builddate
1313    2586  CD0000    		call	_printf
1314                    	; 1208                  printf("\nCommands:\n");
1315    2589  21CF22    		ld	hl,L5211
1316    258C  CD0000    		call	_printf
1317                    	; 1209                  printf("  h - help\n");
1318    258F  21DB22    		ld	hl,L5311
1319    2592  CD0000    		call	_printf
1320                    	; 1210                  printf("  i - initialize\n");
1321    2595  21E722    		ld	hl,L5411
1322    2598  CD0000    		call	_printf
1323                    	; 1211                  printf("  n - set/show block #N to read\n");
1324    259B  21F922    		ld	hl,L5511
1325    259E  CD0000    		call	_printf
1326                    	; 1212                  printf("  r - read block #N\n");
1327    25A1  211A23    		ld	hl,L5611
1328    25A4  CD0000    		call	_printf
1329                    	; 1213                  printf("  w - read block #N\n");
1330    25A7  212F23    		ld	hl,L5711
1331    25AA  CD0000    		call	_printf
1332                    	; 1214                  printf("  p - print block last read/to write\n");
1333    25AD  214423    		ld	hl,L5021
1334    25B0  CD0000    		call	_printf
1335                    	; 1215                  printf("  s - print SD registers\n");
1336    25B3  216A23    		ld	hl,L5121
1337    25B6  CD0000    		call	_printf
1338                    	; 1216                  printf("  l - print partition layout\n");
1339    25B9  218423    		ld	hl,L5221
1340    25BC  CD0000    		call	_printf
1341                    	; 1217                  printf("  Ctrl-C to reload monitor.\n");
1342    25BF  21A223    		ld	hl,L5321
1343    25C2  CD0000    		call	_printf
1344                    	; 1218                  break;
1345    25C5  C35625    		jp	L1213
1346                    	L1713:
1347                    	; 1219              case 'i':
1348                    	; 1220                  printf(" i - initialize SD card");
1349    25C8  21BF23    		ld	hl,L5421
1350    25CB  CD0000    		call	_printf
1351                    	; 1221                  if (sdinit())
1352    25CE  CD6D02    		call	_sdinit
1353    25D1  79        		ld	a,c
1354    25D2  B0        		or	b
1355    25D3  2809      		jr	z,L1023
1356                    	; 1222                      printf(" - ok\n");
1357    25D5  21D723    		ld	hl,L5521
1358    25D8  CD0000    		call	_printf
1359                    	; 1223                  else
1360    25DB  C35625    		jp	L1213
1361                    	L1023:
1362                    	; 1224                      printf(" - not inserted or faulty\n");
1363    25DE  21DE23    		ld	hl,L5621
1364    25E1  CD0000    		call	_printf
1365    25E4  C35625    		jp	L1213
1366                    	L1223:
1367                    	; 1225                  break;
1368                    	; 1226              case 'n':
1369                    	; 1227                  printf(" n - block number: ");
1370    25E7  21F923    		ld	hl,L5721
1371    25EA  CD0000    		call	_printf
1372                    	; 1228                  if (getkline(txtin, sizeof txtin))
1373    25ED  210A00    		ld	hl,10
1374    25F0  E5        		push	hl
1375    25F1  DDE5      		push	ix
1376    25F3  C1        		pop	bc
1377    25F4  21F0FF    		ld	hl,65520
1378    25F7  09        		add	hl,bc
1379    25F8  CD0000    		call	_getkline
1380    25FB  F1        		pop	af
1381    25FC  79        		ld	a,c
1382    25FD  B0        		or	b
1383    25FE  281A      		jr	z,L1323
1384                    	; 1229                      sscanf(txtin, "%lu", &blockno);
1385    2600  DDE5      		push	ix
1386    2602  C1        		pop	bc
1387    2603  21E8FF    		ld	hl,65512
1388    2606  09        		add	hl,bc
1389    2607  E5        		push	hl
1390    2608  210D24    		ld	hl,L5031
1391    260B  E5        		push	hl
1392    260C  DDE5      		push	ix
1393    260E  C1        		pop	bc
1394    260F  21F0FF    		ld	hl,65520
1395    2612  09        		add	hl,bc
1396    2613  CD0000    		call	_sscanf
1397    2616  F1        		pop	af
1398    2617  F1        		pop	af
1399                    	; 1230                  else
1400    2618  1816      		jr	L1423
1401                    	L1323:
1402                    	; 1231                      printf("%lu", blockno);
1403    261A  DD66EB    		ld	h,(ix-21)
1404    261D  DD6EEA    		ld	l,(ix-22)
1405    2620  E5        		push	hl
1406    2621  DD66E9    		ld	h,(ix-23)
1407    2624  DD6EE8    		ld	l,(ix-24)
1408    2627  E5        		push	hl
1409    2628  211124    		ld	hl,L5131
1410    262B  CD0000    		call	_printf
1411    262E  F1        		pop	af
1412    262F  F1        		pop	af
1413                    	L1423:
1414                    	; 1232                  printf("\n");
1415    2630  211524    		ld	hl,L5231
1416    2633  CD0000    		call	_printf
1417                    	; 1233                  break;
1418    2636  C35625    		jp	L1213
1419                    	L1523:
1420                    	; 1234              case 'r':
1421                    	; 1235                  printf(" r - read block");
1422    2639  211724    		ld	hl,L5331
1423    263C  CD0000    		call	_printf
1424                    	; 1236                  if (sdread(sdrdbuf, blockno))
1425    263F  DD66EB    		ld	h,(ix-21)
1426    2642  DD6EEA    		ld	l,(ix-22)
1427    2645  E5        		push	hl
1428    2646  DD66E9    		ld	h,(ix-23)
1429    2649  DD6EE8    		ld	l,(ix-24)
1430    264C  E5        		push	hl
1431    264D  213200    		ld	hl,_sdrdbuf
1432    2650  CDE10C    		call	_sdread
1433    2653  F1        		pop	af
1434    2654  F1        		pop	af
1435    2655  79        		ld	a,c
1436    2656  B0        		or	b
1437    2657  2819      		jr	z,L1623
1438                    	; 1237                      {
1439                    	; 1238                      printf(" - ok\n");
1440    2659  212724    		ld	hl,L5431
1441    265C  CD0000    		call	_printf
1442                    	; 1239                      curblkno = blockno;
1443    265F  210000    		ld	hl,_curblkno
1444    2662  E5        		push	hl
1445    2663  DDE5      		push	ix
1446    2665  C1        		pop	bc
1447    2666  21E8FF    		ld	hl,65512
1448    2669  09        		add	hl,bc
1449    266A  E5        		push	hl
1450    266B  CD0000    		call	c.mvl
1451    266E  F1        		pop	af
1452                    	; 1240                      }
1453                    	; 1241                  else
1454    266F  C35625    		jp	L1213
1455                    	L1623:
1456                    	; 1242                      printf(" - error\n");
1457    2672  212E24    		ld	hl,L5531
1458    2675  CD0000    		call	_printf
1459    2678  C35625    		jp	L1213
1460                    	L1033:
1461                    	; 1243                  break;
1462                    	; 1244              case 'w':
1463                    	; 1245                  printf(" w - write block");
1464    267B  213824    		ld	hl,L5631
1465    267E  CD0000    		call	_printf
1466                    	; 1246                  if (sdwrite(sdrdbuf, blockno))
1467    2681  DD66EB    		ld	h,(ix-21)
1468    2684  DD6EEA    		ld	l,(ix-22)
1469    2687  E5        		push	hl
1470    2688  DD66E9    		ld	h,(ix-23)
1471    268B  DD6EE8    		ld	l,(ix-24)
1472    268E  E5        		push	hl
1473    268F  213200    		ld	hl,_sdrdbuf
1474    2692  CDC20E    		call	_sdwrite
1475    2695  F1        		pop	af
1476    2696  F1        		pop	af
1477    2697  79        		ld	a,c
1478    2698  B0        		or	b
1479    2699  2819      		jr	z,L1133
1480                    	; 1247                      {
1481                    	; 1248                      printf(" - ok\n");
1482    269B  214924    		ld	hl,L5731
1483    269E  CD0000    		call	_printf
1484                    	; 1249                      curblkno = blockno;
1485    26A1  210000    		ld	hl,_curblkno
1486    26A4  E5        		push	hl
1487    26A5  DDE5      		push	ix
1488    26A7  C1        		pop	bc
1489    26A8  21E8FF    		ld	hl,65512
1490    26AB  09        		add	hl,bc
1491    26AC  E5        		push	hl
1492    26AD  CD0000    		call	c.mvl
1493    26B0  F1        		pop	af
1494                    	; 1250                      }
1495                    	; 1251                  else
1496    26B1  C35625    		jp	L1213
1497                    	L1133:
1498                    	; 1252                      printf(" - error\n");
1499    26B4  215024    		ld	hl,L5041
1500    26B7  CD0000    		call	_printf
1501    26BA  C35625    		jp	L1213
1502                    	L1333:
1503                    	; 1253                  break;
1504                    	; 1254              case 'p':
1505                    	; 1255                  printf(" p - print data block %lu\n", curblkno);
1506    26BD  210300    		ld	hl,_curblkno+3
1507    26C0  46        		ld	b,(hl)
1508    26C1  2B        		dec	hl
1509    26C2  4E        		ld	c,(hl)
1510    26C3  C5        		push	bc
1511    26C4  2B        		dec	hl
1512    26C5  46        		ld	b,(hl)
1513    26C6  2B        		dec	hl
1514    26C7  4E        		ld	c,(hl)
1515    26C8  C5        		push	bc
1516    26C9  215A24    		ld	hl,L5141
1517    26CC  CD0000    		call	_printf
1518    26CF  F1        		pop	af
1519    26D0  F1        		pop	af
1520                    	; 1256                  sddatprt(sdrdbuf);
1521    26D1  213200    		ld	hl,_sdrdbuf
1522    26D4  CDE310    		call	_sddatprt
1523                    	; 1257                  break;
1524    26D7  C35625    		jp	L1213
1525                    	L1433:
1526                    	; 1258              case 's':
1527                    	; 1259                  printf(" s - print SD registers\n");
1528    26DA  217524    		ld	hl,L5241
1529    26DD  CD0000    		call	_printf
1530                    	; 1260                  sdprtreg();
1531    26E0  CD1009    		call	_sdprtreg
1532                    	; 1261                  break;
1533    26E3  C35625    		jp	L1213
1534                    	L1533:
1535                    	; 1262              case 'l':
1536                    	; 1263                  printf(" l - print partition layout\n");
1537    26E6  218E24    		ld	hl,L5341
1538    26E9  CD0000    		call	_printf
1539                    	; 1264                  sdmbrpart();
1540    26EC  CDEC21    		call	_sdmbrpart
1541                    	; 1265                  break;
1542    26EF  C35625    		jp	L1213
1543                    	L1633:
1544                    	; 1266              case 0x03: /* Ctrl-C */
1545                    	; 1267                  printf("reloading monitor from EPROM\n");
1546    26F2  21AB24    		ld	hl,L5441
1547    26F5  CD0000    		call	_printf
1548                    	; 1268                  reload();
1549    26F8  CD0000    		call	_reload
1550                    	; 1269                  break; /* not really needed, will never get here */
1551    26FB  C35625    		jp	L1213
1552                    	L1733:
1553                    	; 1270              default:
1554                    	; 1271                  printf(" command not implemented yet\n");
1555    26FE  21C924    		ld	hl,L5541
1556    2701  CD0000    		call	_printf
1557    2704  C35625    		jp	L1213
1558                    	L1513:
1559                    	; 1272              }
1560                    	; 1273          }
1561    2707  C35625    		jp	L1213
1562                    	; 1274      }
1563                    	; 1275  
1564                    		.psect	_bss
1565                    	_curblkno:
1566                    		.byte	[4]
1567                    	_blkmult:
1568                    		.byte	[4]
1569                    	_sdver2:
1570                    		.byte	[2]
1571                    	_sdinitok:
1572                    		.byte	[2]
1573                    	_curblkok:
1574                    		.byte	[2]
1575                    	_csdreg:
1576                    		.byte	[16]
1577                    	_cidreg:
1578                    		.byte	[16]
1579                    	_ocrreg:
1580                    		.byte	[4]
1581                    	_sdrdbuf:
1582                    		.byte	[512]
1583                    		.public	_sdgpthdr
1584                    		.public	_curblkno
1585                    		.external	c.ulrsh
1586                    		.external	c.rets0
1587                    		.public	_CRC16_one
1588                    		.external	c.savs0
1589                    		.external	_getchar
1590                    		.external	c.lcmp
1591                    		.public	_cmd55
1592                    		.public	_curblkok
1593                    		.public	_cmd17
1594                    		.public	_cmd16
1595                    		.public	_cmd24
1596                    		.public	_sdver2
1597                    		.external	c.r1
1598                    		.external	_spideselect
1599                    		.public	_cmd10
1600                    		.external	c.r0
1601                    		.external	_getkline
1602                    		.external	c.jtab
1603                    		.external	_printf
1604                    		.external	_ledon
1605                    		.public	_sdmbrpart
1606                    		.external	_spiselect
1607                    		.external	_memcpy
1608                    		.public	_sdinit
1609                    		.public	_sdmbrentry
1610                    		.external	c.ladd
1611                    		.public	_sdwrite
1612                    		.public	_ocrreg
1613                    		.external	c.mvl
1614                    		.public	_prtguid
1615                    		.external	_sscanf
1616                    		.public	_blkmult
1617                    		.public	_acmd41
1618                    		.public	_csdreg
1619                    		.external	_reload
1620                    		.external	_putchar
1621                    		.public	_sdcommand
1622                    		.external	c.ursh
1623                    		.public	_sdread
1624                    		.external	_ledoff
1625                    		.external	c.rets
1626                    		.public	_CRC7_one
1627                    		.external	c.savs
1628                    		.public	_cidreg
1629                    		.public	_builddate
1630                    		.public	_cmd9
1631                    		.external	c.lmul
1632                    		.public	_cmd8
1633                    		.external	c.0mvf
1634                    		.public	_sdprtreg
1635                    		.public	_sdrdbuf
1636                    		.external	c.udiv
1637                    		.external	c.imul
1638                    		.external	c.lsub
1639                    		.public	_prtgptent
1640                    		.external	c.irsh
1641                    		.external	c.umod
1642                    		.public	_sddatprt
1643                    		.public	_main
1644                    		.external	c.llsh
1645                    		.public	_sdinitok
1646                    		.external	_spiio
1647                    		.public	_cmd0
1648                    		.external	c.ilsh
1649                    		.public	_cmd58
1650                    		.end
