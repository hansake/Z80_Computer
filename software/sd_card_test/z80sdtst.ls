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
 509                    	L51:
 510    026D  0A        		.byte	10
 511    026E  53        		.byte	83
 512    026F  65        		.byte	101
 513    0270  6E        		.byte	110
 514    0271  74        		.byte	116
 515    0272  20        		.byte	32
 516    0273  38        		.byte	56
 517    0274  2A        		.byte	42
 518    0275  38        		.byte	56
 519    0276  20        		.byte	32
 520    0277  28        		.byte	40
 521    0278  37        		.byte	55
 522    0279  32        		.byte	50
 523    027A  29        		.byte	41
 524    027B  20        		.byte	32
 525    027C  63        		.byte	99
 526    027D  6C        		.byte	108
 527    027E  6F        		.byte	111
 528    027F  63        		.byte	99
 529    0280  6B        		.byte	107
 530    0281  20        		.byte	32
 531    0282  70        		.byte	112
 532    0283  75        		.byte	117
 533    0284  6C        		.byte	108
 534    0285  73        		.byte	115
 535    0286  65        		.byte	101
 536    0287  73        		.byte	115
 537    0288  2C        		.byte	44
 538    0289  20        		.byte	32
 539    028A  73        		.byte	115
 540    028B  65        		.byte	101
 541    028C  6C        		.byte	108
 542    028D  65        		.byte	101
 543    028E  63        		.byte	99
 544    028F  74        		.byte	116
 545    0290  20        		.byte	32
 546    0291  6E        		.byte	110
 547    0292  6F        		.byte	111
 548    0293  74        		.byte	116
 549    0294  20        		.byte	32
 550    0295  61        		.byte	97
 551    0296  63        		.byte	99
 552    0297  74        		.byte	116
 553    0298  69        		.byte	105
 554    0299  76        		.byte	118
 555    029A  65        		.byte	101
 556    029B  0A        		.byte	10
 557    029C  00        		.byte	0
 558                    	L52:
 559    029D  43        		.byte	67
 560    029E  4D        		.byte	77
 561    029F  44        		.byte	68
 562    02A0  30        		.byte	48
 563    02A1  3A        		.byte	58
 564    02A2  20        		.byte	32
 565    02A3  6E        		.byte	110
 566    02A4  6F        		.byte	111
 567    02A5  20        		.byte	32
 568    02A6  72        		.byte	114
 569    02A7  65        		.byte	101
 570    02A8  73        		.byte	115
 571    02A9  70        		.byte	112
 572    02AA  6F        		.byte	111
 573    02AB  6E        		.byte	110
 574    02AC  73        		.byte	115
 575    02AD  65        		.byte	101
 576    02AE  0A        		.byte	10
 577    02AF  00        		.byte	0
 578                    	L53:
 579    02B0  43        		.byte	67
 580    02B1  4D        		.byte	77
 581    02B2  44        		.byte	68
 582    02B3  30        		.byte	48
 583    02B4  3A        		.byte	58
 584    02B5  20        		.byte	32
 585    02B6  47        		.byte	71
 586    02B7  4F        		.byte	79
 587    02B8  5F        		.byte	95
 588    02B9  49        		.byte	73
 589    02BA  44        		.byte	68
 590    02BB  4C        		.byte	76
 591    02BC  45        		.byte	69
 592    02BD  5F        		.byte	95
 593    02BE  53        		.byte	83
 594    02BF  54        		.byte	84
 595    02C0  41        		.byte	65
 596    02C1  54        		.byte	84
 597    02C2  45        		.byte	69
 598    02C3  2C        		.byte	44
 599    02C4  20        		.byte	32
 600    02C5  52        		.byte	82
 601    02C6  31        		.byte	49
 602    02C7  20        		.byte	32
 603    02C8  72        		.byte	114
 604    02C9  65        		.byte	101
 605    02CA  73        		.byte	115
 606    02CB  70        		.byte	112
 607    02CC  6F        		.byte	111
 608    02CD  6E        		.byte	110
 609    02CE  73        		.byte	115
 610    02CF  65        		.byte	101
 611    02D0  20        		.byte	32
 612    02D1  5B        		.byte	91
 613    02D2  25        		.byte	37
 614    02D3  30        		.byte	48
 615    02D4  32        		.byte	50
 616    02D5  78        		.byte	120
 617    02D6  5D        		.byte	93
 618    02D7  0A        		.byte	10
 619    02D8  00        		.byte	0
 620                    	L54:
 621    02D9  43        		.byte	67
 622    02DA  4D        		.byte	77
 623    02DB  44        		.byte	68
 624    02DC  38        		.byte	56
 625    02DD  3A        		.byte	58
 626    02DE  20        		.byte	32
 627    02DF  6E        		.byte	110
 628    02E0  6F        		.byte	111
 629    02E1  20        		.byte	32
 630    02E2  72        		.byte	114
 631    02E3  65        		.byte	101
 632    02E4  73        		.byte	115
 633    02E5  70        		.byte	112
 634    02E6  6F        		.byte	111
 635    02E7  6E        		.byte	110
 636    02E8  73        		.byte	115
 637    02E9  65        		.byte	101
 638    02EA  0A        		.byte	10
 639    02EB  00        		.byte	0
 640                    	L55:
 641    02EC  43        		.byte	67
 642    02ED  4D        		.byte	77
 643    02EE  44        		.byte	68
 644    02EF  38        		.byte	56
 645    02F0  3A        		.byte	58
 646    02F1  20        		.byte	32
 647    02F2  53        		.byte	83
 648    02F3  45        		.byte	69
 649    02F4  4E        		.byte	78
 650    02F5  44        		.byte	68
 651    02F6  5F        		.byte	95
 652    02F7  49        		.byte	73
 653    02F8  46        		.byte	70
 654    02F9  5F        		.byte	95
 655    02FA  43        		.byte	67
 656    02FB  4F        		.byte	79
 657    02FC  4E        		.byte	78
 658    02FD  44        		.byte	68
 659    02FE  2C        		.byte	44
 660    02FF  20        		.byte	32
 661    0300  52        		.byte	82
 662    0301  37        		.byte	55
 663    0302  20        		.byte	32
 664    0303  72        		.byte	114
 665    0304  65        		.byte	101
 666    0305  73        		.byte	115
 667    0306  70        		.byte	112
 668    0307  6F        		.byte	111
 669    0308  6E        		.byte	110
 670    0309  73        		.byte	115
 671    030A  65        		.byte	101
 672    030B  20        		.byte	32
 673    030C  5B        		.byte	91
 674    030D  25        		.byte	37
 675    030E  30        		.byte	48
 676    030F  32        		.byte	50
 677    0310  78        		.byte	120
 678    0311  20        		.byte	32
 679    0312  25        		.byte	37
 680    0313  30        		.byte	48
 681    0314  32        		.byte	50
 682    0315  78        		.byte	120
 683    0316  20        		.byte	32
 684    0317  25        		.byte	37
 685    0318  30        		.byte	48
 686    0319  32        		.byte	50
 687    031A  78        		.byte	120
 688    031B  20        		.byte	32
 689    031C  25        		.byte	37
 690    031D  30        		.byte	48
 691    031E  32        		.byte	50
 692    031F  78        		.byte	120
 693    0320  20        		.byte	32
 694    0321  25        		.byte	37
 695    0322  30        		.byte	48
 696    0323  32        		.byte	50
 697    0324  78        		.byte	120
 698    0325  5D        		.byte	93
 699    0326  2C        		.byte	44
 700    0327  20        		.byte	32
 701    0328  00        		.byte	0
 702                    	L56:
 703    0329  65        		.byte	101
 704    032A  63        		.byte	99
 705    032B  68        		.byte	104
 706    032C  6F        		.byte	111
 707    032D  20        		.byte	32
 708    032E  62        		.byte	98
 709    032F  61        		.byte	97
 710    0330  63        		.byte	99
 711    0331  6B        		.byte	107
 712    0332  20        		.byte	32
 713    0333  6F        		.byte	111
 714    0334  6B        		.byte	107
 715    0335  2C        		.byte	44
 716    0336  20        		.byte	32
 717    0337  00        		.byte	0
 718                    	L57:
 719    0338  69        		.byte	105
 720    0339  6E        		.byte	110
 721    033A  76        		.byte	118
 722    033B  61        		.byte	97
 723    033C  6C        		.byte	108
 724    033D  69        		.byte	105
 725    033E  64        		.byte	100
 726    033F  20        		.byte	32
 727    0340  65        		.byte	101
 728    0341  63        		.byte	99
 729    0342  68        		.byte	104
 730    0343  6F        		.byte	111
 731    0344  20        		.byte	32
 732    0345  62        		.byte	98
 733    0346  61        		.byte	97
 734    0347  63        		.byte	99
 735    0348  6B        		.byte	107
 736    0349  0A        		.byte	10
 737    034A  00        		.byte	0
 738                    	L501:
 739    034B  70        		.byte	112
 740    034C  72        		.byte	114
 741    034D  6F        		.byte	111
 742    034E  62        		.byte	98
 743    034F  61        		.byte	97
 744    0350  62        		.byte	98
 745    0351  6C        		.byte	108
 746    0352  79        		.byte	121
 747    0353  20        		.byte	32
 748    0354  53        		.byte	83
 749    0355  44        		.byte	68
 750    0356  20        		.byte	32
 751    0357  76        		.byte	118
 752    0358  65        		.byte	101
 753    0359  72        		.byte	114
 754    035A  2E        		.byte	46
 755    035B  20        		.byte	32
 756    035C  31        		.byte	49
 757    035D  0A        		.byte	10
 758    035E  00        		.byte	0
 759                    	L511:
 760    035F  53        		.byte	83
 761    0360  44        		.byte	68
 762    0361  20        		.byte	32
 763    0362  76        		.byte	118
 764    0363  65        		.byte	101
 765    0364  72        		.byte	114
 766    0365  20        		.byte	32
 767    0366  32        		.byte	50
 768    0367  0A        		.byte	10
 769    0368  00        		.byte	0
 770                    	L521:
 771    0369  43        		.byte	67
 772    036A  4D        		.byte	77
 773    036B  44        		.byte	68
 774    036C  35        		.byte	53
 775    036D  35        		.byte	53
 776    036E  3A        		.byte	58
 777    036F  20        		.byte	32
 778    0370  6E        		.byte	110
 779    0371  6F        		.byte	111
 780    0372  20        		.byte	32
 781    0373  72        		.byte	114
 782    0374  65        		.byte	101
 783    0375  73        		.byte	115
 784    0376  70        		.byte	112
 785    0377  6F        		.byte	111
 786    0378  6E        		.byte	110
 787    0379  73        		.byte	115
 788    037A  65        		.byte	101
 789    037B  0A        		.byte	10
 790    037C  00        		.byte	0
 791                    	L531:
 792    037D  43        		.byte	67
 793    037E  4D        		.byte	77
 794    037F  44        		.byte	68
 795    0380  35        		.byte	53
 796    0381  35        		.byte	53
 797    0382  3A        		.byte	58
 798    0383  20        		.byte	32
 799    0384  41        		.byte	65
 800    0385  50        		.byte	80
 801    0386  50        		.byte	80
 802    0387  5F        		.byte	95
 803    0388  43        		.byte	67
 804    0389  4D        		.byte	77
 805    038A  44        		.byte	68
 806    038B  2C        		.byte	44
 807    038C  20        		.byte	32
 808    038D  52        		.byte	82
 809    038E  31        		.byte	49
 810    038F  20        		.byte	32
 811    0390  72        		.byte	114
 812    0391  65        		.byte	101
 813    0392  73        		.byte	115
 814    0393  70        		.byte	112
 815    0394  6F        		.byte	111
 816    0395  6E        		.byte	110
 817    0396  73        		.byte	115
 818    0397  65        		.byte	101
 819    0398  20        		.byte	32
 820    0399  5B        		.byte	91
 821    039A  25        		.byte	37
 822    039B  30        		.byte	48
 823    039C  32        		.byte	50
 824    039D  78        		.byte	120
 825    039E  5D        		.byte	93
 826    039F  0A        		.byte	10
 827    03A0  00        		.byte	0
 828                    	L541:
 829    03A1  41        		.byte	65
 830    03A2  43        		.byte	67
 831    03A3  4D        		.byte	77
 832    03A4  44        		.byte	68
 833    03A5  34        		.byte	52
 834    03A6  31        		.byte	49
 835    03A7  3A        		.byte	58
 836    03A8  20        		.byte	32
 837    03A9  6E        		.byte	110
 838    03AA  6F        		.byte	111
 839    03AB  20        		.byte	32
 840    03AC  72        		.byte	114
 841    03AD  65        		.byte	101
 842    03AE  73        		.byte	115
 843    03AF  70        		.byte	112
 844    03B0  6F        		.byte	111
 845    03B1  6E        		.byte	110
 846    03B2  73        		.byte	115
 847    03B3  65        		.byte	101
 848    03B4  0A        		.byte	10
 849    03B5  00        		.byte	0
 850                    	L571:
 851                    		.byte	[1]
 852                    	L561:
 853    03B7  20        		.byte	32
 854    03B8  2D        		.byte	45
 855    03B9  20        		.byte	32
 856    03BA  72        		.byte	114
 857    03BB  65        		.byte	101
 858    03BC  61        		.byte	97
 859    03BD  64        		.byte	100
 860    03BE  79        		.byte	121
 861    03BF  00        		.byte	0
 862                    	L551:
 863    03C0  41        		.byte	65
 864    03C1  43        		.byte	67
 865    03C2  4D        		.byte	77
 866    03C3  44        		.byte	68
 867    03C4  34        		.byte	52
 868    03C5  31        		.byte	49
 869    03C6  3A        		.byte	58
 870    03C7  20        		.byte	32
 871    03C8  53        		.byte	83
 872    03C9  45        		.byte	69
 873    03CA  4E        		.byte	78
 874    03CB  44        		.byte	68
 875    03CC  5F        		.byte	95
 876    03CD  4F        		.byte	79
 877    03CE  50        		.byte	80
 878    03CF  5F        		.byte	95
 879    03D0  43        		.byte	67
 880    03D1  4F        		.byte	79
 881    03D2  4E        		.byte	78
 882    03D3  44        		.byte	68
 883    03D4  2C        		.byte	44
 884    03D5  20        		.byte	32
 885    03D6  52        		.byte	82
 886    03D7  31        		.byte	49
 887    03D8  20        		.byte	32
 888    03D9  72        		.byte	114
 889    03DA  65        		.byte	101
 890    03DB  73        		.byte	115
 891    03DC  70        		.byte	112
 892    03DD  6F        		.byte	111
 893    03DE  6E        		.byte	110
 894    03DF  73        		.byte	115
 895    03E0  65        		.byte	101
 896    03E1  20        		.byte	32
 897    03E2  5B        		.byte	91
 898    03E3  25        		.byte	37
 899    03E4  30        		.byte	48
 900    03E5  32        		.byte	50
 901    03E6  78        		.byte	120
 902    03E7  5D        		.byte	93
 903    03E8  25        		.byte	37
 904    03E9  73        		.byte	115
 905    03EA  0A        		.byte	10
 906    03EB  00        		.byte	0
 907                    	L502:
 908    03EC  43        		.byte	67
 909    03ED  4D        		.byte	77
 910    03EE  44        		.byte	68
 911    03EF  35        		.byte	53
 912    03F0  38        		.byte	56
 913    03F1  3A        		.byte	58
 914    03F2  20        		.byte	32
 915    03F3  6E        		.byte	110
 916    03F4  6F        		.byte	111
 917    03F5  20        		.byte	32
 918    03F6  72        		.byte	114
 919    03F7  65        		.byte	101
 920    03F8  73        		.byte	115
 921    03F9  70        		.byte	112
 922    03FA  6F        		.byte	111
 923    03FB  6E        		.byte	110
 924    03FC  73        		.byte	115
 925    03FD  65        		.byte	101
 926    03FE  0A        		.byte	10
 927    03FF  00        		.byte	0
 928                    	L512:
 929    0400  43        		.byte	67
 930    0401  4D        		.byte	77
 931    0402  44        		.byte	68
 932    0403  35        		.byte	53
 933    0404  38        		.byte	56
 934    0405  3A        		.byte	58
 935    0406  20        		.byte	32
 936    0407  52        		.byte	82
 937    0408  45        		.byte	69
 938    0409  41        		.byte	65
 939    040A  44        		.byte	68
 940    040B  5F        		.byte	95
 941    040C  4F        		.byte	79
 942    040D  43        		.byte	67
 943    040E  52        		.byte	82
 944    040F  2C        		.byte	44
 945    0410  20        		.byte	32
 946    0411  52        		.byte	82
 947    0412  33        		.byte	51
 948    0413  20        		.byte	32
 949    0414  72        		.byte	114
 950    0415  65        		.byte	101
 951    0416  73        		.byte	115
 952    0417  70        		.byte	112
 953    0418  6F        		.byte	111
 954    0419  6E        		.byte	110
 955    041A  73        		.byte	115
 956    041B  65        		.byte	101
 957    041C  20        		.byte	32
 958    041D  5B        		.byte	91
 959    041E  25        		.byte	37
 960    041F  30        		.byte	48
 961    0420  32        		.byte	50
 962    0421  78        		.byte	120
 963    0422  20        		.byte	32
 964    0423  25        		.byte	37
 965    0424  30        		.byte	48
 966    0425  32        		.byte	50
 967    0426  78        		.byte	120
 968    0427  20        		.byte	32
 969    0428  25        		.byte	37
 970    0429  30        		.byte	48
 971    042A  32        		.byte	50
 972    042B  78        		.byte	120
 973    042C  20        		.byte	32
 974    042D  25        		.byte	37
 975    042E  30        		.byte	48
 976    042F  32        		.byte	50
 977    0430  78        		.byte	120
 978    0431  20        		.byte	32
 979    0432  25        		.byte	37
 980    0433  30        		.byte	48
 981    0434  32        		.byte	50
 982    0435  78        		.byte	120
 983    0436  5D        		.byte	93
 984    0437  0A        		.byte	10
 985    0438  00        		.byte	0
 986                    	L522:
 987    0439  43        		.byte	67
 988    043A  4D        		.byte	77
 989    043B  44        		.byte	68
 990    043C  31        		.byte	49
 991    043D  36        		.byte	54
 992    043E  3A        		.byte	58
 993    043F  20        		.byte	32
 994    0440  6E        		.byte	110
 995    0441  6F        		.byte	111
 996    0442  20        		.byte	32
 997    0443  72        		.byte	114
 998    0444  65        		.byte	101
 999    0445  73        		.byte	115
1000    0446  70        		.byte	112
1001    0447  6F        		.byte	111
1002    0448  6E        		.byte	110
1003    0449  73        		.byte	115
1004    044A  65        		.byte	101
1005    044B  0A        		.byte	10
1006    044C  00        		.byte	0
1007                    	L532:
1008    044D  43        		.byte	67
1009    044E  4D        		.byte	77
1010    044F  44        		.byte	68
1011    0450  31        		.byte	49
1012    0451  36        		.byte	54
1013    0452  3A        		.byte	58
1014    0453  20        		.byte	32
1015    0454  53        		.byte	83
1016    0455  45        		.byte	69
1017    0456  54        		.byte	84
1018    0457  5F        		.byte	95
1019    0458  42        		.byte	66
1020    0459  4C        		.byte	76
1021    045A  4F        		.byte	79
1022    045B  43        		.byte	67
1023    045C  4B        		.byte	75
1024    045D  4C        		.byte	76
1025    045E  45        		.byte	69
1026    045F  4E        		.byte	78
1027    0460  20        		.byte	32
1028    0461  28        		.byte	40
1029    0462  74        		.byte	116
1030    0463  6F        		.byte	111
1031    0464  20        		.byte	32
1032    0465  35        		.byte	53
1033    0466  31        		.byte	49
1034    0467  32        		.byte	50
1035    0468  20        		.byte	32
1036    0469  62        		.byte	98
1037    046A  79        		.byte	121
1038    046B  74        		.byte	116
1039    046C  65        		.byte	101
1040    046D  73        		.byte	115
1041    046E  29        		.byte	41
1042    046F  2C        		.byte	44
1043    0470  20        		.byte	32
1044    0471  52        		.byte	82
1045    0472  31        		.byte	49
1046    0473  20        		.byte	32
1047    0474  72        		.byte	114
1048    0475  65        		.byte	101
1049    0476  73        		.byte	115
1050    0477  70        		.byte	112
1051    0478  6F        		.byte	111
1052    0479  6E        		.byte	110
1053    047A  73        		.byte	115
1054    047B  65        		.byte	101
1055    047C  20        		.byte	32
1056    047D  5B        		.byte	91
1057    047E  25        		.byte	37
1058    047F  30        		.byte	48
1059    0480  32        		.byte	50
1060    0481  78        		.byte	120
1061    0482  5D        		.byte	93
1062    0483  0A        		.byte	10
1063    0484  00        		.byte	0
1064                    	L542:
1065    0485  43        		.byte	67
1066    0486  4D        		.byte	77
1067    0487  44        		.byte	68
1068    0488  31        		.byte	49
1069    0489  30        		.byte	48
1070    048A  3A        		.byte	58
1071    048B  20        		.byte	32
1072    048C  6E        		.byte	110
1073    048D  6F        		.byte	111
1074    048E  20        		.byte	32
1075    048F  72        		.byte	114
1076    0490  65        		.byte	101
1077    0491  73        		.byte	115
1078    0492  70        		.byte	112
1079    0493  6F        		.byte	111
1080    0494  6E        		.byte	110
1081    0495  73        		.byte	115
1082    0496  65        		.byte	101
1083    0497  0A        		.byte	10
1084    0498  00        		.byte	0
1085                    	L552:
1086    0499  43        		.byte	67
1087    049A  4D        		.byte	77
1088    049B  44        		.byte	68
1089    049C  31        		.byte	49
1090    049D  30        		.byte	48
1091    049E  3A        		.byte	58
1092    049F  20        		.byte	32
1093    04A0  53        		.byte	83
1094    04A1  45        		.byte	69
1095    04A2  4E        		.byte	78
1096    04A3  44        		.byte	68
1097    04A4  5F        		.byte	95
1098    04A5  43        		.byte	67
1099    04A6  49        		.byte	73
1100    04A7  44        		.byte	68
1101    04A8  2C        		.byte	44
1102    04A9  20        		.byte	32
1103    04AA  52        		.byte	82
1104    04AB  31        		.byte	49
1105    04AC  20        		.byte	32
1106    04AD  72        		.byte	114
1107    04AE  65        		.byte	101
1108    04AF  73        		.byte	115
1109    04B0  70        		.byte	112
1110    04B1  6F        		.byte	111
1111    04B2  6E        		.byte	110
1112    04B3  73        		.byte	115
1113    04B4  65        		.byte	101
1114    04B5  20        		.byte	32
1115    04B6  5B        		.byte	91
1116    04B7  25        		.byte	37
1117    04B8  30        		.byte	48
1118    04B9  32        		.byte	50
1119    04BA  78        		.byte	120
1120    04BB  5D        		.byte	93
1121    04BC  0A        		.byte	10
1122    04BD  00        		.byte	0
1123                    	L562:
1124    04BE  20        		.byte	32
1125    04BF  20        		.byte	32
1126    04C0  4E        		.byte	78
1127    04C1  6F        		.byte	111
1128    04C2  20        		.byte	32
1129    04C3  64        		.byte	100
1130    04C4  61        		.byte	97
1131    04C5  74        		.byte	116
1132    04C6  61        		.byte	97
1133    04C7  20        		.byte	32
1134    04C8  66        		.byte	102
1135    04C9  6F        		.byte	111
1136    04CA  75        		.byte	117
1137    04CB  6E        		.byte	110
1138    04CC  64        		.byte	100
1139    04CD  0A        		.byte	10
1140    04CE  00        		.byte	0
1141                    	L572:
1142    04CF  20        		.byte	32
1143    04D0  20        		.byte	32
1144    04D1  43        		.byte	67
1145    04D2  49        		.byte	73
1146    04D3  44        		.byte	68
1147    04D4  3A        		.byte	58
1148    04D5  20        		.byte	32
1149    04D6  5B        		.byte	91
1150    04D7  00        		.byte	0
1151                    	L503:
1152    04D8  25        		.byte	37
1153    04D9  30        		.byte	48
1154    04DA  32        		.byte	50
1155    04DB  78        		.byte	120
1156    04DC  20        		.byte	32
1157    04DD  00        		.byte	0
1158                    	L513:
1159    04DE  08        		.byte	8
1160    04DF  5D        		.byte	93
1161    04E0  20        		.byte	32
1162    04E1  7C        		.byte	124
1163    04E2  00        		.byte	0
1164                    	L523:
1165    04E3  7C        		.byte	124
1166    04E4  0A        		.byte	10
1167    04E5  00        		.byte	0
1168                    	L533:
1169    04E6  43        		.byte	67
1170    04E7  52        		.byte	82
1171    04E8  43        		.byte	67
1172    04E9  37        		.byte	55
1173    04EA  20        		.byte	32
1174    04EB  6F        		.byte	111
1175    04EC  6B        		.byte	107
1176    04ED  3A        		.byte	58
1177    04EE  20        		.byte	32
1178    04EF  5B        		.byte	91
1179    04F0  25        		.byte	37
1180    04F1  30        		.byte	48
1181    04F2  32        		.byte	50
1182    04F3  78        		.byte	120
1183    04F4  5D        		.byte	93
1184    04F5  0A        		.byte	10
1185    04F6  00        		.byte	0
1186                    	L543:
1187    04F7  43        		.byte	67
1188    04F8  52        		.byte	82
1189    04F9  43        		.byte	67
1190    04FA  37        		.byte	55
1191    04FB  20        		.byte	32
1192    04FC  65        		.byte	101
1193    04FD  72        		.byte	114
1194    04FE  72        		.byte	114
1195    04FF  6F        		.byte	111
1196    0500  72        		.byte	114
1197    0501  2C        		.byte	44
1198    0502  20        		.byte	32
1199    0503  63        		.byte	99
1200    0504  61        		.byte	97
1201    0505  6C        		.byte	108
1202    0506  63        		.byte	99
1203    0507  75        		.byte	117
1204    0508  6C        		.byte	108
1205    0509  61        		.byte	97
1206    050A  74        		.byte	116
1207    050B  65        		.byte	101
1208    050C  64        		.byte	100
1209    050D  3A        		.byte	58
1210    050E  20        		.byte	32
1211    050F  5B        		.byte	91
1212    0510  25        		.byte	37
1213    0511  30        		.byte	48
1214    0512  32        		.byte	50
1215    0513  78        		.byte	120
1216    0514  5D        		.byte	93
1217    0515  2C        		.byte	44
1218    0516  20        		.byte	32
1219    0517  72        		.byte	114
1220    0518  65        		.byte	101
1221    0519  63        		.byte	99
1222    051A  69        		.byte	105
1223    051B  65        		.byte	101
1224    051C  76        		.byte	118
1225    051D  65        		.byte	101
1226    051E  64        		.byte	100
1227    051F  3A        		.byte	58
1228    0520  20        		.byte	32
1229    0521  5B        		.byte	91
1230    0522  25        		.byte	37
1231    0523  30        		.byte	48
1232    0524  32        		.byte	50
1233    0525  78        		.byte	120
1234    0526  5D        		.byte	93
1235    0527  0A        		.byte	10
1236    0528  00        		.byte	0
1237                    	L553:
1238    0529  43        		.byte	67
1239    052A  4D        		.byte	77
1240    052B  44        		.byte	68
1241    052C  39        		.byte	57
1242    052D  3A        		.byte	58
1243    052E  20        		.byte	32
1244    052F  6E        		.byte	110
1245    0530  6F        		.byte	111
1246    0531  20        		.byte	32
1247    0532  72        		.byte	114
1248    0533  65        		.byte	101
1249    0534  73        		.byte	115
1250    0535  70        		.byte	112
1251    0536  6F        		.byte	111
1252    0537  6E        		.byte	110
1253    0538  73        		.byte	115
1254    0539  65        		.byte	101
1255    053A  0A        		.byte	10
1256    053B  00        		.byte	0
1257                    	L563:
1258    053C  43        		.byte	67
1259    053D  4D        		.byte	77
1260    053E  44        		.byte	68
1261    053F  39        		.byte	57
1262    0540  3A        		.byte	58
1263    0541  20        		.byte	32
1264    0542  53        		.byte	83
1265    0543  45        		.byte	69
1266    0544  4E        		.byte	78
1267    0545  44        		.byte	68
1268    0546  5F        		.byte	95
1269    0547  43        		.byte	67
1270    0548  53        		.byte	83
1271    0549  44        		.byte	68
1272    054A  2C        		.byte	44
1273    054B  20        		.byte	32
1274    054C  52        		.byte	82
1275    054D  31        		.byte	49
1276    054E  20        		.byte	32
1277    054F  72        		.byte	114
1278    0550  65        		.byte	101
1279    0551  73        		.byte	115
1280    0552  70        		.byte	112
1281    0553  6F        		.byte	111
1282    0554  6E        		.byte	110
1283    0555  73        		.byte	115
1284    0556  65        		.byte	101
1285    0557  20        		.byte	32
1286    0558  5B        		.byte	91
1287    0559  25        		.byte	37
1288    055A  30        		.byte	48
1289    055B  32        		.byte	50
1290    055C  78        		.byte	120
1291    055D  5D        		.byte	93
1292    055E  0A        		.byte	10
1293    055F  00        		.byte	0
1294                    	L573:
1295    0560  20        		.byte	32
1296    0561  20        		.byte	32
1297    0562  4E        		.byte	78
1298    0563  6F        		.byte	111
1299    0564  20        		.byte	32
1300    0565  64        		.byte	100
1301    0566  61        		.byte	97
1302    0567  74        		.byte	116
1303    0568  61        		.byte	97
1304    0569  20        		.byte	32
1305    056A  66        		.byte	102
1306    056B  6F        		.byte	111
1307    056C  75        		.byte	117
1308    056D  6E        		.byte	110
1309    056E  64        		.byte	100
1310    056F  0A        		.byte	10
1311    0570  00        		.byte	0
1312                    	L504:
1313    0571  20        		.byte	32
1314    0572  20        		.byte	32
1315    0573  43        		.byte	67
1316    0574  53        		.byte	83
1317    0575  44        		.byte	68
1318    0576  3A        		.byte	58
1319    0577  20        		.byte	32
1320    0578  5B        		.byte	91
1321    0579  00        		.byte	0
1322                    	L514:
1323    057A  25        		.byte	37
1324    057B  30        		.byte	48
1325    057C  32        		.byte	50
1326    057D  78        		.byte	120
1327    057E  20        		.byte	32
1328    057F  00        		.byte	0
1329                    	L524:
1330    0580  08        		.byte	8
1331    0581  5D        		.byte	93
1332    0582  20        		.byte	32
1333    0583  7C        		.byte	124
1334    0584  00        		.byte	0
1335                    	L534:
1336    0585  7C        		.byte	124
1337    0586  0A        		.byte	10
1338    0587  00        		.byte	0
1339                    	L544:
1340    0588  43        		.byte	67
1341    0589  52        		.byte	82
1342    058A  43        		.byte	67
1343    058B  37        		.byte	55
1344    058C  20        		.byte	32
1345    058D  6F        		.byte	111
1346    058E  6B        		.byte	107
1347    058F  3A        		.byte	58
1348    0590  20        		.byte	32
1349    0591  5B        		.byte	91
1350    0592  25        		.byte	37
1351    0593  30        		.byte	48
1352    0594  32        		.byte	50
1353    0595  78        		.byte	120
1354    0596  5D        		.byte	93
1355    0597  0A        		.byte	10
1356    0598  00        		.byte	0
1357                    	L554:
1358    0599  43        		.byte	67
1359    059A  52        		.byte	82
1360    059B  43        		.byte	67
1361    059C  37        		.byte	55
1362    059D  20        		.byte	32
1363    059E  65        		.byte	101
1364    059F  72        		.byte	114
1365    05A0  72        		.byte	114
1366    05A1  6F        		.byte	111
1367    05A2  72        		.byte	114
1368    05A3  2C        		.byte	44
1369    05A4  20        		.byte	32
1370    05A5  63        		.byte	99
1371    05A6  61        		.byte	97
1372    05A7  6C        		.byte	108
1373    05A8  63        		.byte	99
1374    05A9  75        		.byte	117
1375    05AA  6C        		.byte	108
1376    05AB  61        		.byte	97
1377    05AC  74        		.byte	116
1378    05AD  65        		.byte	101
1379    05AE  64        		.byte	100
1380    05AF  3A        		.byte	58
1381    05B0  20        		.byte	32
1382    05B1  5B        		.byte	91
1383    05B2  25        		.byte	37
1384    05B3  30        		.byte	48
1385    05B4  32        		.byte	50
1386    05B5  78        		.byte	120
1387    05B6  5D        		.byte	93
1388    05B7  2C        		.byte	44
1389    05B8  20        		.byte	32
1390    05B9  72        		.byte	114
1391    05BA  65        		.byte	101
1392    05BB  63        		.byte	99
1393    05BC  69        		.byte	105
1394    05BD  65        		.byte	101
1395    05BE  76        		.byte	118
1396    05BF  65        		.byte	101
1397    05C0  64        		.byte	100
1398    05C1  3A        		.byte	58
1399    05C2  20        		.byte	32
1400    05C3  5B        		.byte	91
1401    05C4  25        		.byte	37
1402    05C5  30        		.byte	48
1403    05C6  32        		.byte	50
1404    05C7  78        		.byte	120
1405    05C8  5D        		.byte	93
1406    05C9  0A        		.byte	10
1407    05CA  00        		.byte	0
1408                    	L564:
1409    05CB  53        		.byte	83
1410    05CC  65        		.byte	101
1411    05CD  6E        		.byte	110
1412    05CE  74        		.byte	116
1413    05CF  20        		.byte	32
1414    05D0  39        		.byte	57
1415    05D1  2A        		.byte	42
1416    05D2  38        		.byte	56
1417    05D3  20        		.byte	32
1418    05D4  28        		.byte	40
1419    05D5  37        		.byte	55
1420    05D6  32        		.byte	50
1421    05D7  29        		.byte	41
1422    05D8  20        		.byte	32
1423    05D9  63        		.byte	99
1424    05DA  6C        		.byte	108
1425    05DB  6F        		.byte	111
1426    05DC  63        		.byte	99
1427    05DD  6B        		.byte	107
1428    05DE  20        		.byte	32
1429    05DF  70        		.byte	112
1430    05E0  75        		.byte	117
1431    05E1  6C        		.byte	108
1432    05E2  73        		.byte	115
1433    05E3  65        		.byte	101
1434    05E4  73        		.byte	115
1435    05E5  2C        		.byte	44
1436    05E6  20        		.byte	32
1437    05E7  73        		.byte	115
1438    05E8  65        		.byte	101
1439    05E9  6C        		.byte	108
1440    05EA  65        		.byte	101
1441    05EB  63        		.byte	99
1442    05EC  74        		.byte	116
1443    05ED  20        		.byte	32
1444    05EE  61        		.byte	97
1445    05EF  63        		.byte	99
1446    05F0  74        		.byte	116
1447    05F1  69        		.byte	105
1448    05F2  76        		.byte	118
1449    05F3  65        		.byte	101
1450    05F4  0A        		.byte	10
1451    05F5  00        		.byte	0
1452                    	;  153      }
1453                    	;  154  
1454                    	;  155  /* Initialise SD card interface
1455                    	;  156   *
1456                    	;  157   * returns YES if ok and NO if not ok
1457                    	;  158   *
1458                    	;  159   * References:
1459                    	;  160   *   https://www.sdcard.org/downloads/pls/
1460                    	;  161   *      Physical Layer Simplified Specification version 8.0
1461                    	;  162   *
1462                    	;  163   * A nice flowchart how to initialize:
1463                    	;  164   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
1464                    	;  165   *
1465                    	;  166   */
1466                    	;  167  int sdinit()
1467                    	;  168      {
1468                    	_sdinit:
1469    05F6  CD0000    		call	c.savs0
1470    05F9  21E4FF    		ld	hl,65508
1471    05FC  39        		add	hl,sp
1472    05FD  F9        		ld	sp,hl
1473                    	;  169      int nbytes;  /* byte counter */
1474                    	;  170      int tries;   /* tries to get to active state or searching for data  */
1475                    	;  171      int wtloop;  /* timer loop when trying to enter active state */
1476                    	;  172      unsigned char cmdbuf[5];   /* buffer to build command in */
1477                    	;  173      unsigned char rstatbuf[5]; /* buffer to recieve status in */
1478                    	;  174      unsigned char *statptr;    /* pointer to returned status from SD command */
1479                    	;  175      unsigned char crc;         /* crc register for CID and CSD */
1480                    	;  176      unsigned char rbyte;       /* recieved byte */
1481                    	;  177  #ifdef SDTEST
1482                    	;  178      unsigned char *prtptr;     /* for debug printing */
1483                    	;  179  #endif
1484                    	;  180  
1485                    	;  181      ledon();
1486    05FE  CD0000    		call	_ledon
1487                    	;  182      spideselect();
1488    0601  CD0000    		call	_spideselect
1489                    	;  183      sdinitok = NO;
1490    0604  210000    		ld	hl,0
1491    0607  220A00    		ld	(_sdinitok),hl
1492                    	;  184  
1493                    	;  185      /* start to generate 9*8 clock pulses with not selected SD card */
1494                    	;  186      for (nbytes = 9; 0 < nbytes; nbytes--)
1495    060A  DD36F809  		ld	(ix-8),9
1496    060E  DD36F900  		ld	(ix-7),0
1497                    	L132:
1498    0612  97        		sub	a
1499    0613  DD96F8    		sub	(ix-8)
1500    0616  3E00      		ld	a,0
1501    0618  DD9EF9    		sbc	a,(ix-7)
1502    061B  F23306    		jp	p,L142
1503                    	;  187          spiio(0xff);
1504    061E  21FF00    		ld	hl,255
1505    0621  CD0000    		call	_spiio
1506    0624  DD6EF8    		ld	l,(ix-8)
1507    0627  DD66F9    		ld	h,(ix-7)
1508    062A  2B        		dec	hl
1509    062B  DD75F8    		ld	(ix-8),l
1510    062E  DD74F9    		ld	(ix-7),h
1511    0631  18DF      		jr	L132
1512                    	L142:
1513                    	;  188  #ifdef SDTEST
1514                    	;  189      printf("\nSent 8*8 (72) clock pulses, select not active\n");
1515    0633  216D02    		ld	hl,L51
1516    0636  CD0000    		call	_printf
1517                    	;  190  #endif
1518                    	;  191      spiselect();
1519    0639  CD0000    		call	_spiselect
1520                    	;  192  
1521                    	;  193      /* CMD0: GO_IDLE_STATE */
1522                    	;  194      memcpy(cmdbuf, cmd0, 5);
1523    063C  210500    		ld	hl,5
1524    063F  E5        		push	hl
1525    0640  211700    		ld	hl,_cmd0
1526    0643  E5        		push	hl
1527    0644  DDE5      		push	ix
1528    0646  C1        		pop	bc
1529    0647  21EFFF    		ld	hl,65519
1530    064A  09        		add	hl,bc
1531    064B  CD0000    		call	_memcpy
1532    064E  F1        		pop	af
1533    064F  F1        		pop	af
1534                    	;  195      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1535    0650  210100    		ld	hl,1
1536    0653  E5        		push	hl
1537    0654  DDE5      		push	ix
1538    0656  C1        		pop	bc
1539    0657  21EAFF    		ld	hl,65514
1540    065A  09        		add	hl,bc
1541    065B  E5        		push	hl
1542    065C  DDE5      		push	ix
1543    065E  C1        		pop	bc
1544    065F  21EFFF    		ld	hl,65519
1545    0662  09        		add	hl,bc
1546    0663  CD6301    		call	_sdcommand
1547    0666  F1        		pop	af
1548    0667  F1        		pop	af
1549    0668  DD71E8    		ld	(ix-24),c
1550    066B  DD70E9    		ld	(ix-23),b
1551                    	;  196  #ifdef SDTEST
1552                    	;  197      if (!statptr)
1553    066E  DD7EE8    		ld	a,(ix-24)
1554    0671  DDB6E9    		or	(ix-23)
1555    0674  2008      		jr	nz,L172
1556                    	;  198          printf("CMD0: no response\n");
1557    0676  219D02    		ld	hl,L52
1558    0679  CD0000    		call	_printf
1559                    	;  199      else
1560    067C  1811      		jr	L103
1561                    	L172:
1562                    	;  200          printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
1563    067E  DD6EE8    		ld	l,(ix-24)
1564    0681  DD66E9    		ld	h,(ix-23)
1565    0684  4E        		ld	c,(hl)
1566    0685  97        		sub	a
1567    0686  47        		ld	b,a
1568    0687  C5        		push	bc
1569    0688  21B002    		ld	hl,L53
1570    068B  CD0000    		call	_printf
1571    068E  F1        		pop	af
1572                    	L103:
1573                    	;  201  #endif
1574                    	;  202      if (!statptr)
1575    068F  DD7EE8    		ld	a,(ix-24)
1576    0692  DDB6E9    		or	(ix-23)
1577    0695  200C      		jr	nz,L113
1578                    	;  203          {
1579                    	;  204          spideselect();
1580    0697  CD0000    		call	_spideselect
1581                    	;  205          ledoff();
1582    069A  CD0000    		call	_ledoff
1583                    	;  206          return (NO);
1584    069D  010000    		ld	bc,0
1585    06A0  C30000    		jp	c.rets0
1586                    	L113:
1587                    	;  207          }
1588                    	;  208      /* CMD8: SEND_IF_COND */
1589                    	;  209      memcpy(cmdbuf, cmd8, 5);
1590    06A3  210500    		ld	hl,5
1591    06A6  E5        		push	hl
1592    06A7  211D00    		ld	hl,_cmd8
1593    06AA  E5        		push	hl
1594    06AB  DDE5      		push	ix
1595    06AD  C1        		pop	bc
1596    06AE  21EFFF    		ld	hl,65519
1597    06B1  09        		add	hl,bc
1598    06B2  CD0000    		call	_memcpy
1599    06B5  F1        		pop	af
1600    06B6  F1        		pop	af
1601                    	;  210      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
1602    06B7  210500    		ld	hl,5
1603    06BA  E5        		push	hl
1604    06BB  DDE5      		push	ix
1605    06BD  C1        		pop	bc
1606    06BE  21EAFF    		ld	hl,65514
1607    06C1  09        		add	hl,bc
1608    06C2  E5        		push	hl
1609    06C3  DDE5      		push	ix
1610    06C5  C1        		pop	bc
1611    06C6  21EFFF    		ld	hl,65519
1612    06C9  09        		add	hl,bc
1613    06CA  CD6301    		call	_sdcommand
1614    06CD  F1        		pop	af
1615    06CE  F1        		pop	af
1616    06CF  DD71E8    		ld	(ix-24),c
1617    06D2  DD70E9    		ld	(ix-23),b
1618                    	;  211  #ifdef SDTEST
1619                    	;  212      if (!statptr)
1620    06D5  DD7EE8    		ld	a,(ix-24)
1621    06D8  DDB6E9    		or	(ix-23)
1622    06DB  2009      		jr	nz,L123
1623                    	;  213          printf("CMD8: no response\n");
1624    06DD  21D902    		ld	hl,L54
1625    06E0  CD0000    		call	_printf
1626                    	;  214      else
1627    06E3  C35907    		jp	L133
1628                    	L123:
1629                    	;  215          {
1630                    	;  216          printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
1631                    	;  217                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
1632    06E6  DD6EE8    		ld	l,(ix-24)
1633    06E9  DD66E9    		ld	h,(ix-23)
1634    06EC  23        		inc	hl
1635    06ED  23        		inc	hl
1636    06EE  23        		inc	hl
1637    06EF  23        		inc	hl
1638    06F0  4E        		ld	c,(hl)
1639    06F1  97        		sub	a
1640    06F2  47        		ld	b,a
1641    06F3  C5        		push	bc
1642    06F4  DD6EE8    		ld	l,(ix-24)
1643    06F7  DD66E9    		ld	h,(ix-23)
1644    06FA  23        		inc	hl
1645    06FB  23        		inc	hl
1646    06FC  23        		inc	hl
1647    06FD  4E        		ld	c,(hl)
1648    06FE  97        		sub	a
1649    06FF  47        		ld	b,a
1650    0700  C5        		push	bc
1651    0701  DD6EE8    		ld	l,(ix-24)
1652    0704  DD66E9    		ld	h,(ix-23)
1653    0707  23        		inc	hl
1654    0708  23        		inc	hl
1655    0709  4E        		ld	c,(hl)
1656    070A  97        		sub	a
1657    070B  47        		ld	b,a
1658    070C  C5        		push	bc
1659    070D  DD6EE8    		ld	l,(ix-24)
1660    0710  DD66E9    		ld	h,(ix-23)
1661    0713  23        		inc	hl
1662    0714  4E        		ld	c,(hl)
1663    0715  97        		sub	a
1664    0716  47        		ld	b,a
1665    0717  C5        		push	bc
1666    0718  DD6EE8    		ld	l,(ix-24)
1667    071B  DD66E9    		ld	h,(ix-23)
1668    071E  4E        		ld	c,(hl)
1669    071F  97        		sub	a
1670    0720  47        		ld	b,a
1671    0721  C5        		push	bc
1672    0722  21EC02    		ld	hl,L55
1673    0725  CD0000    		call	_printf
1674    0728  210A00    		ld	hl,10
1675    072B  39        		add	hl,sp
1676    072C  F9        		ld	sp,hl
1677                    	;  218          if (!(statptr[0] & 0xfe)) /* no error */
1678    072D  DD6EE8    		ld	l,(ix-24)
1679    0730  DD66E9    		ld	h,(ix-23)
1680    0733  6E        		ld	l,(hl)
1681    0734  97        		sub	a
1682    0735  67        		ld	h,a
1683    0736  CB85      		res	0,l
1684    0738  7D        		ld	a,l
1685    0739  B4        		or	h
1686    073A  201D      		jr	nz,L133
1687                    	;  219              {
1688                    	;  220              if (statptr[4] == 0xaa)
1689    073C  DD6EE8    		ld	l,(ix-24)
1690    073F  DD66E9    		ld	h,(ix-23)
1691    0742  23        		inc	hl
1692    0743  23        		inc	hl
1693    0744  23        		inc	hl
1694    0745  23        		inc	hl
1695    0746  7E        		ld	a,(hl)
1696    0747  FEAA      		cp	170
1697    0749  2008      		jr	nz,L153
1698                    	;  221                  printf("echo back ok, ");
1699    074B  212903    		ld	hl,L56
1700    074E  CD0000    		call	_printf
1701                    	;  222              else
1702    0751  1806      		jr	L133
1703                    	L153:
1704                    	;  223                  printf("invalid echo back\n");
1705    0753  213803    		ld	hl,L57
1706    0756  CD0000    		call	_printf
1707                    	L133:
1708                    	;  224              }
1709                    	;  225          }
1710                    	;  226  #endif
1711                    	;  227      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
1712    0759  DD7EE8    		ld	a,(ix-24)
1713    075C  DDB6E9    		or	(ix-23)
1714    075F  2810      		jr	z,L104
1715    0761  DD6EE8    		ld	l,(ix-24)
1716    0764  DD66E9    		ld	h,(ix-23)
1717    0767  6E        		ld	l,(hl)
1718    0768  97        		sub	a
1719    0769  67        		ld	h,a
1720    076A  CB85      		res	0,l
1721    076C  7D        		ld	a,l
1722    076D  B4        		or	h
1723    076E  CAD507    		jp	z,L173
1724                    	L104:
1725                    	;  228          {
1726                    	;  229          sdver2 = NO;
1727    0771  210000    		ld	hl,0
1728    0774  220800    		ld	(_sdver2),hl
1729                    	;  230  #ifdef SDTEST
1730                    	;  231          printf("probably SD ver. 1\n");
1731    0777  214B03    		ld	hl,L501
1732    077A  CD0000    		call	_printf
1733                    	;  232  #endif
1734                    	;  233          }
1735                    	;  234      else
1736                    	L114:
1737                    	;  235          {
1738                    	;  236          sdver2 = YES;
1739                    	;  237          if (statptr[4] != 0xaa) /* but invalid echo back */
1740                    	;  238              {
1741                    	;  239              spideselect();
1742                    	;  240              ledoff();
1743                    	;  241              return (NO);
1744                    	;  242              }
1745                    	;  243  #ifdef SDTEST
1746                    	;  244          printf("SD ver 2\n");
1747                    	;  245  #endif
1748                    	;  246          }
1749                    	;  247  
1750                    	;  248      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
1751                    	;  249      for (tries = 0; tries < 20; tries++)
1752    077D  DD36F600  		ld	(ix-10),0
1753    0781  DD36F700  		ld	(ix-9),0
1754                    	L134:
1755    0785  DD7EF6    		ld	a,(ix-10)
1756    0788  D614      		sub	20
1757    078A  DD7EF7    		ld	a,(ix-9)
1758    078D  DE00      		sbc	a,0
1759    078F  F2F108    		jp	p,L144
1760                    	;  250          {
1761                    	;  251          memcpy(cmdbuf, cmd55, 5);
1762    0792  210500    		ld	hl,5
1763    0795  E5        		push	hl
1764    0796  214100    		ld	hl,_cmd55
1765    0799  E5        		push	hl
1766    079A  DDE5      		push	ix
1767    079C  C1        		pop	bc
1768    079D  21EFFF    		ld	hl,65519
1769    07A0  09        		add	hl,bc
1770    07A1  CD0000    		call	_memcpy
1771    07A4  F1        		pop	af
1772    07A5  F1        		pop	af
1773                    	;  252          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1774    07A6  210100    		ld	hl,1
1775    07A9  E5        		push	hl
1776    07AA  DDE5      		push	ix
1777    07AC  C1        		pop	bc
1778    07AD  21EAFF    		ld	hl,65514
1779    07B0  09        		add	hl,bc
1780    07B1  E5        		push	hl
1781    07B2  DDE5      		push	ix
1782    07B4  C1        		pop	bc
1783    07B5  21EFFF    		ld	hl,65519
1784    07B8  09        		add	hl,bc
1785    07B9  CD6301    		call	_sdcommand
1786    07BC  F1        		pop	af
1787    07BD  F1        		pop	af
1788    07BE  DD71E8    		ld	(ix-24),c
1789    07C1  DD70E9    		ld	(ix-23),b
1790                    	;  253  #ifdef SDTEST
1791                    	;  254          if (!statptr)
1792    07C4  DD7EE8    		ld	a,(ix-24)
1793    07C7  DDB6E9    		or	(ix-23)
1794    07CA  203E      		jr	nz,L174
1795                    	;  255              printf("CMD55: no response\n");
1796    07CC  216903    		ld	hl,L521
1797    07CF  CD0000    		call	_printf
1798                    	;  256          else
1799    07D2  C31B08    		jp	L105
1800                    	L173:
1801    07D5  210100    		ld	hl,1
1802    07D8  220800    		ld	(_sdver2),hl
1803    07DB  DD6EE8    		ld	l,(ix-24)
1804    07DE  DD66E9    		ld	h,(ix-23)
1805    07E1  23        		inc	hl
1806    07E2  23        		inc	hl
1807    07E3  23        		inc	hl
1808    07E4  23        		inc	hl
1809    07E5  7E        		ld	a,(hl)
1810    07E6  FEAA      		cp	170
1811    07E8  280C      		jr	z,L124
1812    07EA  CD0000    		call	_spideselect
1813    07ED  CD0000    		call	_ledoff
1814    07F0  010000    		ld	bc,0
1815    07F3  C30000    		jp	c.rets0
1816                    	L124:
1817    07F6  215F03    		ld	hl,L511
1818    07F9  CD0000    		call	_printf
1819    07FC  C37D07    		jp	L114
1820                    	L154:
1821    07FF  DD34F6    		inc	(ix-10)
1822    0802  2003      		jr	nz,L02
1823    0804  DD34F7    		inc	(ix-9)
1824                    	L02:
1825    0807  C38507    		jp	L134
1826                    	L174:
1827                    	;  257              printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
1828    080A  DD6EE8    		ld	l,(ix-24)
1829    080D  DD66E9    		ld	h,(ix-23)
1830    0810  4E        		ld	c,(hl)
1831    0811  97        		sub	a
1832    0812  47        		ld	b,a
1833    0813  C5        		push	bc
1834    0814  217D03    		ld	hl,L531
1835    0817  CD0000    		call	_printf
1836    081A  F1        		pop	af
1837                    	L105:
1838                    	;  258  #endif
1839                    	;  259          if (!statptr)
1840    081B  DD7EE8    		ld	a,(ix-24)
1841    081E  DDB6E9    		or	(ix-23)
1842    0821  200C      		jr	nz,L115
1843                    	;  260              {
1844                    	;  261              spideselect();
1845    0823  CD0000    		call	_spideselect
1846                    	;  262              ledoff();
1847    0826  CD0000    		call	_ledoff
1848                    	;  263              return (NO);
1849    0829  010000    		ld	bc,0
1850    082C  C30000    		jp	c.rets0
1851                    	L115:
1852                    	;  264              }
1853                    	;  265          memcpy(cmdbuf, acmd41, 5);
1854    082F  210500    		ld	hl,5
1855    0832  E5        		push	hl
1856    0833  214D00    		ld	hl,_acmd41
1857    0836  E5        		push	hl
1858    0837  DDE5      		push	ix
1859    0839  C1        		pop	bc
1860    083A  21EFFF    		ld	hl,65519
1861    083D  09        		add	hl,bc
1862    083E  CD0000    		call	_memcpy
1863    0841  F1        		pop	af
1864    0842  F1        		pop	af
1865                    	;  266          if (sdver2)
1866    0843  2A0800    		ld	hl,(_sdver2)
1867    0846  7C        		ld	a,h
1868    0847  B5        		or	l
1869    0848  2806      		jr	z,L125
1870                    	;  267              cmdbuf[1] = 0x40;
1871    084A  DD36F040  		ld	(ix-16),64
1872                    	;  268          else
1873    084E  1804      		jr	L135
1874                    	L125:
1875                    	;  269              cmdbuf[1] = 0x00;
1876    0850  DD36F000  		ld	(ix-16),0
1877                    	L135:
1878                    	;  270          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1879    0854  210100    		ld	hl,1
1880    0857  E5        		push	hl
1881    0858  DDE5      		push	ix
1882    085A  C1        		pop	bc
1883    085B  21EAFF    		ld	hl,65514
1884    085E  09        		add	hl,bc
1885    085F  E5        		push	hl
1886    0860  DDE5      		push	ix
1887    0862  C1        		pop	bc
1888    0863  21EFFF    		ld	hl,65519
1889    0866  09        		add	hl,bc
1890    0867  CD6301    		call	_sdcommand
1891    086A  F1        		pop	af
1892    086B  F1        		pop	af
1893    086C  DD71E8    		ld	(ix-24),c
1894    086F  DD70E9    		ld	(ix-23),b
1895                    	;  271  #ifdef SDTEST
1896                    	;  272          if (!statptr)
1897    0872  DD7EE8    		ld	a,(ix-24)
1898    0875  DDB6E9    		or	(ix-23)
1899    0878  2008      		jr	nz,L145
1900                    	;  273              printf("ACMD41: no response\n");
1901    087A  21A103    		ld	hl,L541
1902    087D  CD0000    		call	_printf
1903                    	;  274          else
1904    0880  1825      		jr	L155
1905                    	L145:
1906                    	;  275              printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
1907                    	;  276                     statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
1908    0882  DD6EE8    		ld	l,(ix-24)
1909    0885  DD66E9    		ld	h,(ix-23)
1910    0888  7E        		ld	a,(hl)
1911    0889  B7        		or	a
1912    088A  2005      		jr	nz,L22
1913    088C  01B703    		ld	bc,L561
1914    088F  1803      		jr	L42
1915                    	L22:
1916    0891  01B603    		ld	bc,L571
1917                    	L42:
1918    0894  C5        		push	bc
1919    0895  DD6EE8    		ld	l,(ix-24)
1920    0898  DD66E9    		ld	h,(ix-23)
1921    089B  4E        		ld	c,(hl)
1922    089C  97        		sub	a
1923    089D  47        		ld	b,a
1924    089E  C5        		push	bc
1925    089F  21C003    		ld	hl,L551
1926    08A2  CD0000    		call	_printf
1927    08A5  F1        		pop	af
1928    08A6  F1        		pop	af
1929                    	L155:
1930                    	;  277  #endif
1931                    	;  278          if (!statptr)
1932    08A7  DD7EE8    		ld	a,(ix-24)
1933    08AA  DDB6E9    		or	(ix-23)
1934    08AD  200C      		jr	nz,L165
1935                    	;  279              {
1936                    	;  280              spideselect();
1937    08AF  CD0000    		call	_spideselect
1938                    	;  281              ledoff();
1939    08B2  CD0000    		call	_ledoff
1940                    	;  282              return (NO);
1941    08B5  010000    		ld	bc,0
1942    08B8  C30000    		jp	c.rets0
1943                    	L165:
1944                    	;  283              }
1945                    	;  284          if (statptr[0] == 0x00) /* now the SD card is ready */
1946    08BB  DD6EE8    		ld	l,(ix-24)
1947    08BE  DD66E9    		ld	h,(ix-23)
1948    08C1  7E        		ld	a,(hl)
1949    08C2  B7        		or	a
1950    08C3  282C      		jr	z,L144
1951                    	;  285              {
1952                    	;  286              break;
1953                    	;  287              }
1954                    	;  288          for (wtloop = 0; wtloop < tries * 100; wtloop++)
1955    08C5  DD36F400  		ld	(ix-12),0
1956    08C9  DD36F500  		ld	(ix-11),0
1957                    	L106:
1958    08CD  DD6EF6    		ld	l,(ix-10)
1959    08D0  DD66F7    		ld	h,(ix-9)
1960    08D3  E5        		push	hl
1961    08D4  216400    		ld	hl,100
1962    08D7  E5        		push	hl
1963    08D8  CD0000    		call	c.imul
1964    08DB  E1        		pop	hl
1965    08DC  DD7EF4    		ld	a,(ix-12)
1966    08DF  95        		sub	l
1967    08E0  DD7EF5    		ld	a,(ix-11)
1968    08E3  9C        		sbc	a,h
1969    08E4  F2FF07    		jp	p,L154
1970                    	L126:
1971    08E7  DD34F4    		inc	(ix-12)
1972    08EA  2003      		jr	nz,L62
1973    08EC  DD34F5    		inc	(ix-11)
1974                    	L62:
1975    08EF  18DC      		jr	L106
1976                    	L144:
1977                    	;  289              ; /* wait loop, time increasing for each try */
1978                    	;  290          }
1979                    	;  291  
1980                    	;  292      /* CMD58: READ_OCR */
1981                    	;  293      /* According to the flow chart this should not work
1982                    	;  294         for SD ver. 1 but the response is ok anyway
1983                    	;  295         all tested SD cards  */
1984                    	;  296      memcpy(cmdbuf, cmd58, 5);
1985    08F1  210500    		ld	hl,5
1986    08F4  E5        		push	hl
1987    08F5  214700    		ld	hl,_cmd58
1988    08F8  E5        		push	hl
1989    08F9  DDE5      		push	ix
1990    08FB  C1        		pop	bc
1991    08FC  21EFFF    		ld	hl,65519
1992    08FF  09        		add	hl,bc
1993    0900  CD0000    		call	_memcpy
1994    0903  F1        		pop	af
1995    0904  F1        		pop	af
1996                    	;  297      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
1997    0905  210500    		ld	hl,5
1998    0908  E5        		push	hl
1999    0909  DDE5      		push	ix
2000    090B  C1        		pop	bc
2001    090C  21EAFF    		ld	hl,65514
2002    090F  09        		add	hl,bc
2003    0910  E5        		push	hl
2004    0911  DDE5      		push	ix
2005    0913  C1        		pop	bc
2006    0914  21EFFF    		ld	hl,65519
2007    0917  09        		add	hl,bc
2008    0918  CD6301    		call	_sdcommand
2009    091B  F1        		pop	af
2010    091C  F1        		pop	af
2011    091D  DD71E8    		ld	(ix-24),c
2012    0920  DD70E9    		ld	(ix-23),b
2013                    	;  298  #ifdef SDTEST
2014                    	;  299      if (!statptr)
2015    0923  DD7EE8    		ld	a,(ix-24)
2016    0926  DDB6E9    		or	(ix-23)
2017    0929  2009      		jr	nz,L146
2018                    	;  300          printf("CMD58: no response\n");
2019    092B  21EC03    		ld	hl,L502
2020    092E  CD0000    		call	_printf
2021                    	;  301      else
2022    0931  C37B09    		jp	L156
2023                    	L146:
2024                    	;  302          printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
2025                    	;  303                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2026    0934  DD6EE8    		ld	l,(ix-24)
2027    0937  DD66E9    		ld	h,(ix-23)
2028    093A  23        		inc	hl
2029    093B  23        		inc	hl
2030    093C  23        		inc	hl
2031    093D  23        		inc	hl
2032    093E  4E        		ld	c,(hl)
2033    093F  97        		sub	a
2034    0940  47        		ld	b,a
2035    0941  C5        		push	bc
2036    0942  DD6EE8    		ld	l,(ix-24)
2037    0945  DD66E9    		ld	h,(ix-23)
2038    0948  23        		inc	hl
2039    0949  23        		inc	hl
2040    094A  23        		inc	hl
2041    094B  4E        		ld	c,(hl)
2042    094C  97        		sub	a
2043    094D  47        		ld	b,a
2044    094E  C5        		push	bc
2045    094F  DD6EE8    		ld	l,(ix-24)
2046    0952  DD66E9    		ld	h,(ix-23)
2047    0955  23        		inc	hl
2048    0956  23        		inc	hl
2049    0957  4E        		ld	c,(hl)
2050    0958  97        		sub	a
2051    0959  47        		ld	b,a
2052    095A  C5        		push	bc
2053    095B  DD6EE8    		ld	l,(ix-24)
2054    095E  DD66E9    		ld	h,(ix-23)
2055    0961  23        		inc	hl
2056    0962  4E        		ld	c,(hl)
2057    0963  97        		sub	a
2058    0964  47        		ld	b,a
2059    0965  C5        		push	bc
2060    0966  DD6EE8    		ld	l,(ix-24)
2061    0969  DD66E9    		ld	h,(ix-23)
2062    096C  4E        		ld	c,(hl)
2063    096D  97        		sub	a
2064    096E  47        		ld	b,a
2065    096F  C5        		push	bc
2066    0970  210004    		ld	hl,L512
2067    0973  CD0000    		call	_printf
2068    0976  210A00    		ld	hl,10
2069    0979  39        		add	hl,sp
2070    097A  F9        		ld	sp,hl
2071                    	L156:
2072                    	;  304  #endif
2073                    	;  305      if (!statptr)
2074    097B  DD7EE8    		ld	a,(ix-24)
2075    097E  DDB6E9    		or	(ix-23)
2076    0981  200C      		jr	nz,L166
2077                    	;  306          {
2078                    	;  307          spideselect();
2079    0983  CD0000    		call	_spideselect
2080                    	;  308          ledoff();
2081    0986  CD0000    		call	_ledoff
2082                    	;  309          return (NO);
2083    0989  010000    		ld	bc,0
2084    098C  C30000    		jp	c.rets0
2085                    	L166:
2086                    	;  310          }
2087                    	;  311      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
2088    098F  210400    		ld	hl,4
2089    0992  E5        		push	hl
2090    0993  DD6EE8    		ld	l,(ix-24)
2091    0996  DD66E9    		ld	h,(ix-23)
2092    0999  23        		inc	hl
2093    099A  E5        		push	hl
2094    099B  212E00    		ld	hl,_ocrreg
2095    099E  CD0000    		call	_memcpy
2096    09A1  F1        		pop	af
2097    09A2  F1        		pop	af
2098                    	;  312      blkmult = 1; /* assume block address */
2099    09A3  3E01      		ld	a,1
2100    09A5  320600    		ld	(_blkmult+2),a
2101    09A8  87        		add	a,a
2102    09A9  9F        		sbc	a,a
2103    09AA  320700    		ld	(_blkmult+3),a
2104    09AD  320500    		ld	(_blkmult+1),a
2105    09B0  320400    		ld	(_blkmult),a
2106                    	;  313      if (ocrreg[0] & 0x80)
2107    09B3  3A2E00    		ld	a,(_ocrreg)
2108    09B6  CB7F      		bit	7,a
2109    09B8  6F        		ld	l,a
2110    09B9  2817      		jr	z,L176
2111                    	;  314          {
2112                    	;  315          /* SD Ver.2+ */
2113                    	;  316          if (!(ocrreg[0] & 0x40))
2114    09BB  3A2E00    		ld	a,(_ocrreg)
2115    09BE  CB77      		bit	6,a
2116    09C0  6F        		ld	l,a
2117    09C1  200F      		jr	nz,L176
2118                    	;  317              {
2119                    	;  318              /* SD Ver.2+, Byte address */
2120                    	;  319              blkmult = 512;
2121    09C3  97        		sub	a
2122    09C4  320400    		ld	(_blkmult),a
2123    09C7  320500    		ld	(_blkmult+1),a
2124    09CA  320600    		ld	(_blkmult+2),a
2125    09CD  3E02      		ld	a,2
2126    09CF  320700    		ld	(_blkmult+3),a
2127                    	L176:
2128                    	;  320              }
2129                    	;  321          }
2130                    	;  322  
2131                    	;  323      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
2132                    	;  324      if (blkmult == 512)
2133    09D2  210400    		ld	hl,_blkmult
2134    09D5  E5        		push	hl
2135    09D6  97        		sub	a
2136    09D7  320000    		ld	(c.r0),a
2137    09DA  320100    		ld	(c.r0+1),a
2138    09DD  320200    		ld	(c.r0+2),a
2139    09E0  3E02      		ld	a,2
2140    09E2  320300    		ld	(c.r0+3),a
2141    09E5  210000    		ld	hl,c.r0
2142    09E8  E5        		push	hl
2143    09E9  CD0000    		call	c.lcmp
2144    09EC  C2560A    		jp	nz,L117
2145                    	;  325          {
2146                    	;  326          memcpy(cmdbuf, cmd16, 5);
2147    09EF  210500    		ld	hl,5
2148    09F2  E5        		push	hl
2149    09F3  212F00    		ld	hl,_cmd16
2150    09F6  E5        		push	hl
2151    09F7  DDE5      		push	ix
2152    09F9  C1        		pop	bc
2153    09FA  21EFFF    		ld	hl,65519
2154    09FD  09        		add	hl,bc
2155    09FE  CD0000    		call	_memcpy
2156    0A01  F1        		pop	af
2157    0A02  F1        		pop	af
2158                    	;  327          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2159    0A03  210100    		ld	hl,1
2160    0A06  E5        		push	hl
2161    0A07  DDE5      		push	ix
2162    0A09  C1        		pop	bc
2163    0A0A  21EAFF    		ld	hl,65514
2164    0A0D  09        		add	hl,bc
2165    0A0E  E5        		push	hl
2166    0A0F  DDE5      		push	ix
2167    0A11  C1        		pop	bc
2168    0A12  21EFFF    		ld	hl,65519
2169    0A15  09        		add	hl,bc
2170    0A16  CD6301    		call	_sdcommand
2171    0A19  F1        		pop	af
2172    0A1A  F1        		pop	af
2173    0A1B  DD71E8    		ld	(ix-24),c
2174    0A1E  DD70E9    		ld	(ix-23),b
2175                    	;  328  #ifdef SDTEST
2176                    	;  329          if (!statptr)
2177    0A21  DD7EE8    		ld	a,(ix-24)
2178    0A24  DDB6E9    		or	(ix-23)
2179    0A27  2008      		jr	nz,L127
2180                    	;  330              printf("CMD16: no response\n");
2181    0A29  213904    		ld	hl,L522
2182    0A2C  CD0000    		call	_printf
2183                    	;  331          else
2184    0A2F  1811      		jr	L137
2185                    	L127:
2186                    	;  332              printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
2187                    	;  333                  statptr[0]);
2188    0A31  DD6EE8    		ld	l,(ix-24)
2189    0A34  DD66E9    		ld	h,(ix-23)
2190    0A37  4E        		ld	c,(hl)
2191    0A38  97        		sub	a
2192    0A39  47        		ld	b,a
2193    0A3A  C5        		push	bc
2194    0A3B  214D04    		ld	hl,L532
2195    0A3E  CD0000    		call	_printf
2196    0A41  F1        		pop	af
2197                    	L137:
2198                    	;  334  #endif
2199                    	;  335          if (!statptr)
2200    0A42  DD7EE8    		ld	a,(ix-24)
2201    0A45  DDB6E9    		or	(ix-23)
2202    0A48  200C      		jr	nz,L117
2203                    	;  336              {
2204                    	;  337              spideselect();
2205    0A4A  CD0000    		call	_spideselect
2206                    	;  338              ledoff();
2207    0A4D  CD0000    		call	_ledoff
2208                    	;  339              return (NO);
2209    0A50  010000    		ld	bc,0
2210    0A53  C30000    		jp	c.rets0
2211                    	L117:
2212                    	;  340              }
2213                    	;  341          }
2214                    	;  342      /* Register information:
2215                    	;  343       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
2216                    	;  344       */
2217                    	;  345  
2218                    	;  346      /* CMD10: SEND_CID */
2219                    	;  347      memcpy(cmdbuf, cmd10, 5);
2220    0A56  210500    		ld	hl,5
2221    0A59  E5        		push	hl
2222    0A5A  212900    		ld	hl,_cmd10
2223    0A5D  E5        		push	hl
2224    0A5E  DDE5      		push	ix
2225    0A60  C1        		pop	bc
2226    0A61  21EFFF    		ld	hl,65519
2227    0A64  09        		add	hl,bc
2228    0A65  CD0000    		call	_memcpy
2229    0A68  F1        		pop	af
2230    0A69  F1        		pop	af
2231                    	;  348      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2232    0A6A  210100    		ld	hl,1
2233    0A6D  E5        		push	hl
2234    0A6E  DDE5      		push	ix
2235    0A70  C1        		pop	bc
2236    0A71  21EAFF    		ld	hl,65514
2237    0A74  09        		add	hl,bc
2238    0A75  E5        		push	hl
2239    0A76  DDE5      		push	ix
2240    0A78  C1        		pop	bc
2241    0A79  21EFFF    		ld	hl,65519
2242    0A7C  09        		add	hl,bc
2243    0A7D  CD6301    		call	_sdcommand
2244    0A80  F1        		pop	af
2245    0A81  F1        		pop	af
2246    0A82  DD71E8    		ld	(ix-24),c
2247    0A85  DD70E9    		ld	(ix-23),b
2248                    	;  349  #ifdef SDTEST
2249                    	;  350      if (!statptr)
2250    0A88  DD7EE8    		ld	a,(ix-24)
2251    0A8B  DDB6E9    		or	(ix-23)
2252    0A8E  2008      		jr	nz,L157
2253                    	;  351          printf("CMD10: no response\n");
2254    0A90  218504    		ld	hl,L542
2255    0A93  CD0000    		call	_printf
2256                    	;  352      else
2257    0A96  1811      		jr	L167
2258                    	L157:
2259                    	;  353          printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
2260    0A98  DD6EE8    		ld	l,(ix-24)
2261    0A9B  DD66E9    		ld	h,(ix-23)
2262    0A9E  4E        		ld	c,(hl)
2263    0A9F  97        		sub	a
2264    0AA0  47        		ld	b,a
2265    0AA1  C5        		push	bc
2266    0AA2  219904    		ld	hl,L552
2267    0AA5  CD0000    		call	_printf
2268    0AA8  F1        		pop	af
2269                    	L167:
2270                    	;  354  #endif
2271                    	;  355      if (!statptr)
2272    0AA9  DD7EE8    		ld	a,(ix-24)
2273    0AAC  DDB6E9    		or	(ix-23)
2274    0AAF  200C      		jr	nz,L177
2275                    	;  356          {
2276                    	;  357          spideselect();
2277    0AB1  CD0000    		call	_spideselect
2278                    	;  358          ledoff();
2279    0AB4  CD0000    		call	_ledoff
2280                    	;  359          return (NO);
2281    0AB7  010000    		ld	bc,0
2282    0ABA  C30000    		jp	c.rets0
2283                    	L177:
2284                    	;  360          }
2285                    	;  361      /* looking for 0xfe that is the byte before data */
2286                    	;  362      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2287    0ABD  DD36F614  		ld	(ix-10),20
2288    0AC1  DD36F700  		ld	(ix-9),0
2289                    	L1001:
2290    0AC5  97        		sub	a
2291    0AC6  DD96F6    		sub	(ix-10)
2292    0AC9  3E00      		ld	a,0
2293    0ACB  DD9EF7    		sbc	a,(ix-9)
2294    0ACE  F2F00A    		jp	p,L1101
2295    0AD1  21FF00    		ld	hl,255
2296    0AD4  CD0000    		call	_spiio
2297    0AD7  79        		ld	a,c
2298    0AD8  FEFE      		cp	254
2299    0ADA  2003      		jr	nz,L03
2300    0ADC  78        		ld	a,b
2301    0ADD  FE00      		cp	0
2302                    	L03:
2303    0ADF  280F      		jr	z,L1101
2304                    	L1201:
2305    0AE1  DD6EF6    		ld	l,(ix-10)
2306    0AE4  DD66F7    		ld	h,(ix-9)
2307    0AE7  2B        		dec	hl
2308    0AE8  DD75F6    		ld	(ix-10),l
2309    0AEB  DD74F7    		ld	(ix-9),h
2310    0AEE  18D5      		jr	L1001
2311                    	L1101:
2312                    	;  363          ;
2313                    	;  364      if (tries == 0) /* tried too many times */
2314    0AF0  DD7EF6    		ld	a,(ix-10)
2315    0AF3  DDB6F7    		or	(ix-9)
2316    0AF6  2012      		jr	nz,L1401
2317                    	;  365          {
2318                    	;  366  #ifdef SDTEST
2319                    	;  367          printf("  No data found\n");
2320    0AF8  21BE04    		ld	hl,L562
2321    0AFB  CD0000    		call	_printf
2322                    	;  368  #endif
2323                    	;  369          spideselect();
2324    0AFE  CD0000    		call	_spideselect
2325                    	;  370          ledoff();
2326    0B01  CD0000    		call	_ledoff
2327                    	;  371          return (NO);
2328    0B04  010000    		ld	bc,0
2329    0B07  C30000    		jp	c.rets0
2330                    	L1401:
2331                    	;  372          }
2332                    	;  373      else
2333                    	;  374          {
2334                    	;  375          crc = 0;
2335    0B0A  DD36E700  		ld	(ix-25),0
2336                    	;  376          for (nbytes = 0; nbytes < 15; nbytes++)
2337    0B0E  DD36F800  		ld	(ix-8),0
2338    0B12  DD36F900  		ld	(ix-7),0
2339                    	L1601:
2340    0B16  DD7EF8    		ld	a,(ix-8)
2341    0B19  D60F      		sub	15
2342    0B1B  DD7EF9    		ld	a,(ix-7)
2343    0B1E  DE00      		sbc	a,0
2344    0B20  F2560B    		jp	p,L1701
2345                    	;  377              {
2346                    	;  378              rbyte = spiio(0xff);
2347    0B23  21FF00    		ld	hl,255
2348    0B26  CD0000    		call	_spiio
2349    0B29  DD71E6    		ld	(ix-26),c
2350                    	;  379              cidreg[nbytes] = rbyte;
2351    0B2C  211E00    		ld	hl,_cidreg
2352    0B2F  DD4EF8    		ld	c,(ix-8)
2353    0B32  DD46F9    		ld	b,(ix-7)
2354    0B35  09        		add	hl,bc
2355    0B36  DD7EE6    		ld	a,(ix-26)
2356    0B39  77        		ld	(hl),a
2357                    	;  380              crc = CRC7_one(crc, rbyte);
2358    0B3A  DD6EE6    		ld	l,(ix-26)
2359    0B3D  97        		sub	a
2360    0B3E  67        		ld	h,a
2361    0B3F  E5        		push	hl
2362    0B40  DD6EE7    		ld	l,(ix-25)
2363    0B43  97        		sub	a
2364    0B44  67        		ld	h,a
2365    0B45  CD5300    		call	_CRC7_one
2366    0B48  F1        		pop	af
2367    0B49  DD71E7    		ld	(ix-25),c
2368                    	;  381              }
2369    0B4C  DD34F8    		inc	(ix-8)
2370    0B4F  2003      		jr	nz,L23
2371    0B51  DD34F9    		inc	(ix-7)
2372                    	L23:
2373    0B54  18C0      		jr	L1601
2374                    	L1701:
2375                    	;  382          cidreg[15] = spiio(0xff);
2376    0B56  21FF00    		ld	hl,255
2377    0B59  CD0000    		call	_spiio
2378    0B5C  79        		ld	a,c
2379    0B5D  322D00    		ld	(_cidreg+15),a
2380                    	;  383          crc |= 0x01;
2381    0B60  DDCBE7C6  		set	0,(ix-25)
2382                    	;  384          /* some SD cards need additional clock pulses */
2383                    	;  385          for (nbytes = 9; 0 < nbytes; nbytes--)
2384    0B64  DD36F809  		ld	(ix-8),9
2385    0B68  DD36F900  		ld	(ix-7),0
2386                    	L1211:
2387    0B6C  97        		sub	a
2388    0B6D  DD96F8    		sub	(ix-8)
2389    0B70  3E00      		ld	a,0
2390    0B72  DD9EF9    		sbc	a,(ix-7)
2391    0B75  F28D0B    		jp	p,L1311
2392                    	;  386              spiio(0xff);
2393    0B78  21FF00    		ld	hl,255
2394    0B7B  CD0000    		call	_spiio
2395    0B7E  DD6EF8    		ld	l,(ix-8)
2396    0B81  DD66F9    		ld	h,(ix-7)
2397    0B84  2B        		dec	hl
2398    0B85  DD75F8    		ld	(ix-8),l
2399    0B88  DD74F9    		ld	(ix-7),h
2400    0B8B  18DF      		jr	L1211
2401                    	L1311:
2402                    	;  387  #ifdef SDTEST
2403                    	;  388          prtptr = &cidreg[0];
2404    0B8D  211E00    		ld	hl,_cidreg
2405    0B90  DD75E4    		ld	(ix-28),l
2406    0B93  DD74E5    		ld	(ix-27),h
2407                    	;  389          printf("  CID: [");
2408    0B96  21CF04    		ld	hl,L572
2409    0B99  CD0000    		call	_printf
2410                    	;  390          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2411    0B9C  DD36F800  		ld	(ix-8),0
2412    0BA0  DD36F900  		ld	(ix-7),0
2413                    	L1611:
2414    0BA4  DD7EF8    		ld	a,(ix-8)
2415    0BA7  D610      		sub	16
2416    0BA9  DD7EF9    		ld	a,(ix-7)
2417    0BAC  DE00      		sbc	a,0
2418    0BAE  F2D40B    		jp	p,L1711
2419                    	;  391              printf("%02x ", *prtptr);
2420    0BB1  DD6EE4    		ld	l,(ix-28)
2421    0BB4  DD66E5    		ld	h,(ix-27)
2422    0BB7  4E        		ld	c,(hl)
2423    0BB8  97        		sub	a
2424    0BB9  47        		ld	b,a
2425    0BBA  C5        		push	bc
2426    0BBB  21D804    		ld	hl,L503
2427    0BBE  CD0000    		call	_printf
2428    0BC1  F1        		pop	af
2429    0BC2  DD34F8    		inc	(ix-8)
2430    0BC5  2003      		jr	nz,L43
2431    0BC7  DD34F9    		inc	(ix-7)
2432                    	L43:
2433    0BCA  DD34E4    		inc	(ix-28)
2434    0BCD  2003      		jr	nz,L63
2435    0BCF  DD34E5    		inc	(ix-27)
2436                    	L63:
2437    0BD2  18D0      		jr	L1611
2438                    	L1711:
2439                    	;  392          prtptr = &cidreg[0];
2440    0BD4  211E00    		ld	hl,_cidreg
2441    0BD7  DD75E4    		ld	(ix-28),l
2442    0BDA  DD74E5    		ld	(ix-27),h
2443                    	;  393          printf("\b] |");
2444    0BDD  21DE04    		ld	hl,L513
2445    0BE0  CD0000    		call	_printf
2446                    	;  394          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2447    0BE3  DD36F800  		ld	(ix-8),0
2448    0BE7  DD36F900  		ld	(ix-7),0
2449                    	L1221:
2450    0BEB  DD7EF8    		ld	a,(ix-8)
2451    0BEE  D610      		sub	16
2452    0BF0  DD7EF9    		ld	a,(ix-7)
2453    0BF3  DE00      		sbc	a,0
2454    0BF5  F2340C    		jp	p,L1321
2455                    	;  395              {
2456                    	;  396              if ((' ' <= *prtptr) && (*prtptr < 127))
2457    0BF8  DD6EE4    		ld	l,(ix-28)
2458    0BFB  DD66E5    		ld	h,(ix-27)
2459    0BFE  7E        		ld	a,(hl)
2460    0BFF  FE20      		cp	32
2461    0C01  3819      		jr	c,L1621
2462    0C03  DD6EE4    		ld	l,(ix-28)
2463    0C06  DD66E5    		ld	h,(ix-27)
2464    0C09  7E        		ld	a,(hl)
2465    0C0A  FE7F      		cp	127
2466    0C0C  300E      		jr	nc,L1621
2467                    	;  397                  putchar(*prtptr);
2468    0C0E  DD6EE4    		ld	l,(ix-28)
2469    0C11  DD66E5    		ld	h,(ix-27)
2470    0C14  6E        		ld	l,(hl)
2471    0C15  97        		sub	a
2472    0C16  67        		ld	h,a
2473    0C17  CD0000    		call	_putchar
2474                    	;  398              else
2475    0C1A  1806      		jr	L1421
2476                    	L1621:
2477                    	;  399                  putchar('.');
2478    0C1C  212E00    		ld	hl,46
2479    0C1F  CD0000    		call	_putchar
2480                    	L1421:
2481    0C22  DD34F8    		inc	(ix-8)
2482    0C25  2003      		jr	nz,L04
2483    0C27  DD34F9    		inc	(ix-7)
2484                    	L04:
2485    0C2A  DD34E4    		inc	(ix-28)
2486    0C2D  2003      		jr	nz,L24
2487    0C2F  DD34E5    		inc	(ix-27)
2488                    	L24:
2489    0C32  18B7      		jr	L1221
2490                    	L1321:
2491                    	;  400              }
2492                    	;  401          printf("|\n");
2493    0C34  21E304    		ld	hl,L523
2494    0C37  CD0000    		call	_printf
2495                    	;  402          if (crc == cidreg[15])
2496    0C3A  212D00    		ld	hl,_cidreg+15
2497    0C3D  DD7EE7    		ld	a,(ix-25)
2498    0C40  BE        		cp	(hl)
2499    0C41  200F      		jr	nz,L1031
2500                    	;  403              {
2501                    	;  404              printf("CRC7 ok: [%02x]\n", crc);
2502    0C43  DD4EE7    		ld	c,(ix-25)
2503    0C46  97        		sub	a
2504    0C47  47        		ld	b,a
2505    0C48  C5        		push	bc
2506    0C49  21E604    		ld	hl,L533
2507    0C4C  CD0000    		call	_printf
2508    0C4F  F1        		pop	af
2509                    	;  405              }
2510                    	;  406          else
2511    0C50  1815      		jr	L1501
2512                    	L1031:
2513                    	;  407              {
2514                    	;  408              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2515                    	;  409                  crc, cidreg[15]);
2516    0C52  3A2D00    		ld	a,(_cidreg+15)
2517    0C55  4F        		ld	c,a
2518    0C56  97        		sub	a
2519    0C57  47        		ld	b,a
2520    0C58  C5        		push	bc
2521    0C59  DD4EE7    		ld	c,(ix-25)
2522    0C5C  97        		sub	a
2523    0C5D  47        		ld	b,a
2524    0C5E  C5        		push	bc
2525    0C5F  21F704    		ld	hl,L543
2526    0C62  CD0000    		call	_printf
2527    0C65  F1        		pop	af
2528    0C66  F1        		pop	af
2529                    	L1501:
2530                    	;  410              /* could maybe return failure here */
2531                    	;  411              }
2532                    	;  412  #endif
2533                    	;  413          }
2534                    	;  414  
2535                    	;  415      /* CMD9: SEND_CSD */
2536                    	;  416      memcpy(cmdbuf, cmd9, 5);
2537    0C67  210500    		ld	hl,5
2538    0C6A  E5        		push	hl
2539    0C6B  212300    		ld	hl,_cmd9
2540    0C6E  E5        		push	hl
2541    0C6F  DDE5      		push	ix
2542    0C71  C1        		pop	bc
2543    0C72  21EFFF    		ld	hl,65519
2544    0C75  09        		add	hl,bc
2545    0C76  CD0000    		call	_memcpy
2546    0C79  F1        		pop	af
2547    0C7A  F1        		pop	af
2548                    	;  417      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2549    0C7B  210100    		ld	hl,1
2550    0C7E  E5        		push	hl
2551    0C7F  DDE5      		push	ix
2552    0C81  C1        		pop	bc
2553    0C82  21EAFF    		ld	hl,65514
2554    0C85  09        		add	hl,bc
2555    0C86  E5        		push	hl
2556    0C87  DDE5      		push	ix
2557    0C89  C1        		pop	bc
2558    0C8A  21EFFF    		ld	hl,65519
2559    0C8D  09        		add	hl,bc
2560    0C8E  CD6301    		call	_sdcommand
2561    0C91  F1        		pop	af
2562    0C92  F1        		pop	af
2563    0C93  DD71E8    		ld	(ix-24),c
2564    0C96  DD70E9    		ld	(ix-23),b
2565                    	;  418  #ifdef SDTEST
2566                    	;  419      if (!statptr)
2567    0C99  DD7EE8    		ld	a,(ix-24)
2568    0C9C  DDB6E9    		or	(ix-23)
2569    0C9F  2008      		jr	nz,L1231
2570                    	;  420          printf("CMD9: no response\n");
2571    0CA1  212905    		ld	hl,L553
2572    0CA4  CD0000    		call	_printf
2573                    	;  421      else
2574    0CA7  1811      		jr	L1331
2575                    	L1231:
2576                    	;  422          printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
2577    0CA9  DD6EE8    		ld	l,(ix-24)
2578    0CAC  DD66E9    		ld	h,(ix-23)
2579    0CAF  4E        		ld	c,(hl)
2580    0CB0  97        		sub	a
2581    0CB1  47        		ld	b,a
2582    0CB2  C5        		push	bc
2583    0CB3  213C05    		ld	hl,L563
2584    0CB6  CD0000    		call	_printf
2585    0CB9  F1        		pop	af
2586                    	L1331:
2587                    	;  423  #endif
2588                    	;  424      if (!statptr)
2589    0CBA  DD7EE8    		ld	a,(ix-24)
2590    0CBD  DDB6E9    		or	(ix-23)
2591    0CC0  200C      		jr	nz,L1431
2592                    	;  425          {
2593                    	;  426          spideselect();
2594    0CC2  CD0000    		call	_spideselect
2595                    	;  427          ledoff();
2596    0CC5  CD0000    		call	_ledoff
2597                    	;  428          return (NO);
2598    0CC8  010000    		ld	bc,0
2599    0CCB  C30000    		jp	c.rets0
2600                    	L1431:
2601                    	;  429          }
2602                    	;  430      /* looking for 0xfe that is the byte before data */
2603                    	;  431      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2604    0CCE  DD36F614  		ld	(ix-10),20
2605    0CD2  DD36F700  		ld	(ix-9),0
2606                    	L1531:
2607    0CD6  97        		sub	a
2608    0CD7  DD96F6    		sub	(ix-10)
2609    0CDA  3E00      		ld	a,0
2610    0CDC  DD9EF7    		sbc	a,(ix-9)
2611    0CDF  F2010D    		jp	p,L1631
2612    0CE2  21FF00    		ld	hl,255
2613    0CE5  CD0000    		call	_spiio
2614    0CE8  79        		ld	a,c
2615    0CE9  FEFE      		cp	254
2616    0CEB  2003      		jr	nz,L44
2617    0CED  78        		ld	a,b
2618    0CEE  FE00      		cp	0
2619                    	L44:
2620    0CF0  280F      		jr	z,L1631
2621                    	L1731:
2622    0CF2  DD6EF6    		ld	l,(ix-10)
2623    0CF5  DD66F7    		ld	h,(ix-9)
2624    0CF8  2B        		dec	hl
2625    0CF9  DD75F6    		ld	(ix-10),l
2626    0CFC  DD74F7    		ld	(ix-9),h
2627    0CFF  18D5      		jr	L1531
2628                    	L1631:
2629                    	;  432          ;
2630                    	;  433      if (tries == 0) /* tried too many times */
2631    0D01  DD7EF6    		ld	a,(ix-10)
2632    0D04  DDB6F7    		or	(ix-9)
2633    0D07  200C      		jr	nz,L1141
2634                    	;  434          {
2635                    	;  435  #ifdef SDTEST
2636                    	;  436          printf("  No data found\n");
2637    0D09  216005    		ld	hl,L573
2638    0D0C  CD0000    		call	_printf
2639                    	;  437  #endif
2640                    	;  438          return (NO);
2641    0D0F  010000    		ld	bc,0
2642    0D12  C30000    		jp	c.rets0
2643                    	L1141:
2644                    	;  439          }
2645                    	;  440      else
2646                    	;  441          {
2647                    	;  442          crc = 0;
2648    0D15  DD36E700  		ld	(ix-25),0
2649                    	;  443          for (nbytes = 0; nbytes < 15; nbytes++)
2650    0D19  DD36F800  		ld	(ix-8),0
2651    0D1D  DD36F900  		ld	(ix-7),0
2652                    	L1341:
2653    0D21  DD7EF8    		ld	a,(ix-8)
2654    0D24  D60F      		sub	15
2655    0D26  DD7EF9    		ld	a,(ix-7)
2656    0D29  DE00      		sbc	a,0
2657    0D2B  F2610D    		jp	p,L1441
2658                    	;  444              {
2659                    	;  445              rbyte = spiio(0xff);
2660    0D2E  21FF00    		ld	hl,255
2661    0D31  CD0000    		call	_spiio
2662    0D34  DD71E6    		ld	(ix-26),c
2663                    	;  446              csdreg[nbytes] = rbyte;
2664    0D37  210E00    		ld	hl,_csdreg
2665    0D3A  DD4EF8    		ld	c,(ix-8)
2666    0D3D  DD46F9    		ld	b,(ix-7)
2667    0D40  09        		add	hl,bc
2668    0D41  DD7EE6    		ld	a,(ix-26)
2669    0D44  77        		ld	(hl),a
2670                    	;  447              crc = CRC7_one(crc, rbyte);
2671    0D45  DD6EE6    		ld	l,(ix-26)
2672    0D48  97        		sub	a
2673    0D49  67        		ld	h,a
2674    0D4A  E5        		push	hl
2675    0D4B  DD6EE7    		ld	l,(ix-25)
2676    0D4E  97        		sub	a
2677    0D4F  67        		ld	h,a
2678    0D50  CD5300    		call	_CRC7_one
2679    0D53  F1        		pop	af
2680    0D54  DD71E7    		ld	(ix-25),c
2681                    	;  448              }
2682    0D57  DD34F8    		inc	(ix-8)
2683    0D5A  2003      		jr	nz,L64
2684    0D5C  DD34F9    		inc	(ix-7)
2685                    	L64:
2686    0D5F  18C0      		jr	L1341
2687                    	L1441:
2688                    	;  449          csdreg[15] = spiio(0xff);
2689    0D61  21FF00    		ld	hl,255
2690    0D64  CD0000    		call	_spiio
2691    0D67  79        		ld	a,c
2692    0D68  321D00    		ld	(_csdreg+15),a
2693                    	;  450          crc |= 0x01;
2694    0D6B  DDCBE7C6  		set	0,(ix-25)
2695                    	;  451          /* some SD cards need additional clock pulses */
2696                    	;  452          for (nbytes = 9; 0 < nbytes; nbytes--)
2697    0D6F  DD36F809  		ld	(ix-8),9
2698    0D73  DD36F900  		ld	(ix-7),0
2699                    	L1741:
2700    0D77  97        		sub	a
2701    0D78  DD96F8    		sub	(ix-8)
2702    0D7B  3E00      		ld	a,0
2703    0D7D  DD9EF9    		sbc	a,(ix-7)
2704    0D80  F2980D    		jp	p,L1051
2705                    	;  453              spiio(0xff);
2706    0D83  21FF00    		ld	hl,255
2707    0D86  CD0000    		call	_spiio
2708    0D89  DD6EF8    		ld	l,(ix-8)
2709    0D8C  DD66F9    		ld	h,(ix-7)
2710    0D8F  2B        		dec	hl
2711    0D90  DD75F8    		ld	(ix-8),l
2712    0D93  DD74F9    		ld	(ix-7),h
2713    0D96  18DF      		jr	L1741
2714                    	L1051:
2715                    	;  454  #ifdef SDTEST
2716                    	;  455          prtptr = &csdreg[0];
2717    0D98  210E00    		ld	hl,_csdreg
2718    0D9B  DD75E4    		ld	(ix-28),l
2719    0D9E  DD74E5    		ld	(ix-27),h
2720                    	;  456          printf("  CSD: [");
2721    0DA1  217105    		ld	hl,L504
2722    0DA4  CD0000    		call	_printf
2723                    	;  457          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2724    0DA7  DD36F800  		ld	(ix-8),0
2725    0DAB  DD36F900  		ld	(ix-7),0
2726                    	L1351:
2727    0DAF  DD7EF8    		ld	a,(ix-8)
2728    0DB2  D610      		sub	16
2729    0DB4  DD7EF9    		ld	a,(ix-7)
2730    0DB7  DE00      		sbc	a,0
2731    0DB9  F2DF0D    		jp	p,L1451
2732                    	;  458              printf("%02x ", *prtptr);
2733    0DBC  DD6EE4    		ld	l,(ix-28)
2734    0DBF  DD66E5    		ld	h,(ix-27)
2735    0DC2  4E        		ld	c,(hl)
2736    0DC3  97        		sub	a
2737    0DC4  47        		ld	b,a
2738    0DC5  C5        		push	bc
2739    0DC6  217A05    		ld	hl,L514
2740    0DC9  CD0000    		call	_printf
2741    0DCC  F1        		pop	af
2742    0DCD  DD34F8    		inc	(ix-8)
2743    0DD0  2003      		jr	nz,L05
2744    0DD2  DD34F9    		inc	(ix-7)
2745                    	L05:
2746    0DD5  DD34E4    		inc	(ix-28)
2747    0DD8  2003      		jr	nz,L25
2748    0DDA  DD34E5    		inc	(ix-27)
2749                    	L25:
2750    0DDD  18D0      		jr	L1351
2751                    	L1451:
2752                    	;  459          prtptr = &csdreg[0];
2753    0DDF  210E00    		ld	hl,_csdreg
2754    0DE2  DD75E4    		ld	(ix-28),l
2755    0DE5  DD74E5    		ld	(ix-27),h
2756                    	;  460          printf("\b] |");
2757    0DE8  218005    		ld	hl,L524
2758    0DEB  CD0000    		call	_printf
2759                    	;  461          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2760    0DEE  DD36F800  		ld	(ix-8),0
2761    0DF2  DD36F900  		ld	(ix-7),0
2762                    	L1751:
2763    0DF6  DD7EF8    		ld	a,(ix-8)
2764    0DF9  D610      		sub	16
2765    0DFB  DD7EF9    		ld	a,(ix-7)
2766    0DFE  DE00      		sbc	a,0
2767    0E00  F23F0E    		jp	p,L1061
2768                    	;  462              {
2769                    	;  463              if ((' ' <= *prtptr) && (*prtptr < 127))
2770    0E03  DD6EE4    		ld	l,(ix-28)
2771    0E06  DD66E5    		ld	h,(ix-27)
2772    0E09  7E        		ld	a,(hl)
2773    0E0A  FE20      		cp	32
2774    0E0C  3819      		jr	c,L1361
2775    0E0E  DD6EE4    		ld	l,(ix-28)
2776    0E11  DD66E5    		ld	h,(ix-27)
2777    0E14  7E        		ld	a,(hl)
2778    0E15  FE7F      		cp	127
2779    0E17  300E      		jr	nc,L1361
2780                    	;  464                  putchar(*prtptr);
2781    0E19  DD6EE4    		ld	l,(ix-28)
2782    0E1C  DD66E5    		ld	h,(ix-27)
2783    0E1F  6E        		ld	l,(hl)
2784    0E20  97        		sub	a
2785    0E21  67        		ld	h,a
2786    0E22  CD0000    		call	_putchar
2787                    	;  465              else
2788    0E25  1806      		jr	L1161
2789                    	L1361:
2790                    	;  466                  putchar('.');
2791    0E27  212E00    		ld	hl,46
2792    0E2A  CD0000    		call	_putchar
2793                    	L1161:
2794    0E2D  DD34F8    		inc	(ix-8)
2795    0E30  2003      		jr	nz,L45
2796    0E32  DD34F9    		inc	(ix-7)
2797                    	L45:
2798    0E35  DD34E4    		inc	(ix-28)
2799    0E38  2003      		jr	nz,L65
2800    0E3A  DD34E5    		inc	(ix-27)
2801                    	L65:
2802    0E3D  18B7      		jr	L1751
2803                    	L1061:
2804                    	;  467              }
2805                    	;  468          printf("|\n");
2806    0E3F  218505    		ld	hl,L534
2807    0E42  CD0000    		call	_printf
2808                    	;  469          if (crc == csdreg[15])
2809    0E45  211D00    		ld	hl,_csdreg+15
2810    0E48  DD7EE7    		ld	a,(ix-25)
2811    0E4B  BE        		cp	(hl)
2812    0E4C  200F      		jr	nz,L1561
2813                    	;  470              {
2814                    	;  471              printf("CRC7 ok: [%02x]\n", crc);
2815    0E4E  DD4EE7    		ld	c,(ix-25)
2816    0E51  97        		sub	a
2817    0E52  47        		ld	b,a
2818    0E53  C5        		push	bc
2819    0E54  218805    		ld	hl,L544
2820    0E57  CD0000    		call	_printf
2821    0E5A  F1        		pop	af
2822                    	;  472              }
2823                    	;  473          else
2824    0E5B  1815      		jr	L1241
2825                    	L1561:
2826                    	;  474              {
2827                    	;  475              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2828                    	;  476                  crc, csdreg[15]);
2829    0E5D  3A1D00    		ld	a,(_csdreg+15)
2830    0E60  4F        		ld	c,a
2831    0E61  97        		sub	a
2832    0E62  47        		ld	b,a
2833    0E63  C5        		push	bc
2834    0E64  DD4EE7    		ld	c,(ix-25)
2835    0E67  97        		sub	a
2836    0E68  47        		ld	b,a
2837    0E69  C5        		push	bc
2838    0E6A  219905    		ld	hl,L554
2839    0E6D  CD0000    		call	_printf
2840    0E70  F1        		pop	af
2841    0E71  F1        		pop	af
2842                    	L1241:
2843                    	;  477              /* could maybe return failure here */
2844                    	;  478              }
2845                    	;  479  #endif
2846                    	;  480          }
2847                    	;  481  
2848                    	;  482      for (nbytes = 9; 0 < nbytes; nbytes--)
2849    0E72  DD36F809  		ld	(ix-8),9
2850    0E76  DD36F900  		ld	(ix-7),0
2851                    	L1761:
2852    0E7A  97        		sub	a
2853    0E7B  DD96F8    		sub	(ix-8)
2854    0E7E  3E00      		ld	a,0
2855    0E80  DD9EF9    		sbc	a,(ix-7)
2856    0E83  F29B0E    		jp	p,L1071
2857                    	;  483          spiio(0xff);
2858    0E86  21FF00    		ld	hl,255
2859    0E89  CD0000    		call	_spiio
2860    0E8C  DD6EF8    		ld	l,(ix-8)
2861    0E8F  DD66F9    		ld	h,(ix-7)
2862    0E92  2B        		dec	hl
2863    0E93  DD75F8    		ld	(ix-8),l
2864    0E96  DD74F9    		ld	(ix-7),h
2865    0E99  18DF      		jr	L1761
2866                    	L1071:
2867                    	;  484  #ifdef SDTEST
2868                    	;  485      printf("Sent 9*8 (72) clock pulses, select active\n");
2869    0E9B  21CB05    		ld	hl,L564
2870    0E9E  CD0000    		call	_printf
2871                    	;  486  #endif
2872                    	;  487  
2873                    	;  488      sdinitok = YES;
2874    0EA1  210100    		ld	hl,1
2875    0EA4  220A00    		ld	(_sdinitok),hl
2876                    	;  489  
2877                    	;  490      spideselect();
2878    0EA7  CD0000    		call	_spideselect
2879                    	;  491      ledoff();
2880    0EAA  CD0000    		call	_ledoff
2881                    	;  492  
2882                    	;  493      return (YES);
2883    0EAD  010100    		ld	bc,1
2884    0EB0  C30000    		jp	c.rets0
2885                    	L574:
2886    0EB3  53        		.byte	83
2887    0EB4  44        		.byte	68
2888    0EB5  20        		.byte	32
2889    0EB6  63        		.byte	99
2890    0EB7  61        		.byte	97
2891    0EB8  72        		.byte	114
2892    0EB9  64        		.byte	100
2893    0EBA  20        		.byte	32
2894    0EBB  6E        		.byte	110
2895    0EBC  6F        		.byte	111
2896    0EBD  74        		.byte	116
2897    0EBE  20        		.byte	32
2898    0EBF  69        		.byte	105
2899    0EC0  6E        		.byte	110
2900    0EC1  69        		.byte	105
2901    0EC2  74        		.byte	116
2902    0EC3  69        		.byte	105
2903    0EC4  61        		.byte	97
2904    0EC5  6C        		.byte	108
2905    0EC6  69        		.byte	105
2906    0EC7  7A        		.byte	122
2907    0EC8  65        		.byte	101
2908    0EC9  64        		.byte	100
2909    0ECA  0A        		.byte	10
2910    0ECB  00        		.byte	0
2911                    	L505:
2912    0ECC  53        		.byte	83
2913    0ECD  44        		.byte	68
2914    0ECE  20        		.byte	32
2915    0ECF  63        		.byte	99
2916    0ED0  61        		.byte	97
2917    0ED1  72        		.byte	114
2918    0ED2  64        		.byte	100
2919    0ED3  20        		.byte	32
2920    0ED4  69        		.byte	105
2921    0ED5  6E        		.byte	110
2922    0ED6  66        		.byte	102
2923    0ED7  6F        		.byte	111
2924    0ED8  72        		.byte	114
2925    0ED9  6D        		.byte	109
2926    0EDA  61        		.byte	97
2927    0EDB  74        		.byte	116
2928    0EDC  69        		.byte	105
2929    0EDD  6F        		.byte	111
2930    0EDE  6E        		.byte	110
2931    0EDF  3A        		.byte	58
2932    0EE0  00        		.byte	0
2933                    	L515:
2934    0EE1  20        		.byte	32
2935    0EE2  20        		.byte	32
2936    0EE3  53        		.byte	83
2937    0EE4  44        		.byte	68
2938    0EE5  20        		.byte	32
2939    0EE6  63        		.byte	99
2940    0EE7  61        		.byte	97
2941    0EE8  72        		.byte	114
2942    0EE9  64        		.byte	100
2943    0EEA  20        		.byte	32
2944    0EEB  76        		.byte	118
2945    0EEC  65        		.byte	101
2946    0EED  72        		.byte	114
2947    0EEE  2E        		.byte	46
2948    0EEF  20        		.byte	32
2949    0EF0  32        		.byte	50
2950    0EF1  2B        		.byte	43
2951    0EF2  2C        		.byte	44
2952    0EF3  20        		.byte	32
2953    0EF4  42        		.byte	66
2954    0EF5  6C        		.byte	108
2955    0EF6  6F        		.byte	111
2956    0EF7  63        		.byte	99
2957    0EF8  6B        		.byte	107
2958    0EF9  20        		.byte	32
2959    0EFA  61        		.byte	97
2960    0EFB  64        		.byte	100
2961    0EFC  64        		.byte	100
2962    0EFD  72        		.byte	114
2963    0EFE  65        		.byte	101
2964    0EFF  73        		.byte	115
2965    0F00  73        		.byte	115
2966    0F01  0A        		.byte	10
2967    0F02  00        		.byte	0
2968                    	L525:
2969    0F03  20        		.byte	32
2970    0F04  20        		.byte	32
2971    0F05  53        		.byte	83
2972    0F06  44        		.byte	68
2973    0F07  20        		.byte	32
2974    0F08  63        		.byte	99
2975    0F09  61        		.byte	97
2976    0F0A  72        		.byte	114
2977    0F0B  64        		.byte	100
2978    0F0C  20        		.byte	32
2979    0F0D  76        		.byte	118
2980    0F0E  65        		.byte	101
2981    0F0F  72        		.byte	114
2982    0F10  2E        		.byte	46
2983    0F11  20        		.byte	32
2984    0F12  32        		.byte	50
2985    0F13  2B        		.byte	43
2986    0F14  2C        		.byte	44
2987    0F15  20        		.byte	32
2988    0F16  42        		.byte	66
2989    0F17  79        		.byte	121
2990    0F18  74        		.byte	116
2991    0F19  65        		.byte	101
2992    0F1A  20        		.byte	32
2993    0F1B  61        		.byte	97
2994    0F1C  64        		.byte	100
2995    0F1D  64        		.byte	100
2996    0F1E  72        		.byte	114
2997    0F1F  65        		.byte	101
2998    0F20  73        		.byte	115
2999    0F21  73        		.byte	115
3000    0F22  0A        		.byte	10
3001    0F23  00        		.byte	0
3002                    	L535:
3003    0F24  20        		.byte	32
3004    0F25  20        		.byte	32
3005    0F26  53        		.byte	83
3006    0F27  44        		.byte	68
3007    0F28  20        		.byte	32
3008    0F29  63        		.byte	99
3009    0F2A  61        		.byte	97
3010    0F2B  72        		.byte	114
3011    0F2C  64        		.byte	100
3012    0F2D  20        		.byte	32
3013    0F2E  76        		.byte	118
3014    0F2F  65        		.byte	101
3015    0F30  72        		.byte	114
3016    0F31  2E        		.byte	46
3017    0F32  20        		.byte	32
3018    0F33  31        		.byte	49
3019    0F34  2C        		.byte	44
3020    0F35  20        		.byte	32
3021    0F36  42        		.byte	66
3022    0F37  79        		.byte	121
3023    0F38  74        		.byte	116
3024    0F39  65        		.byte	101
3025    0F3A  20        		.byte	32
3026    0F3B  61        		.byte	97
3027    0F3C  64        		.byte	100
3028    0F3D  64        		.byte	100
3029    0F3E  72        		.byte	114
3030    0F3F  65        		.byte	101
3031    0F40  73        		.byte	115
3032    0F41  73        		.byte	115
3033    0F42  0A        		.byte	10
3034    0F43  00        		.byte	0
3035                    	L545:
3036    0F44  20        		.byte	32
3037    0F45  20        		.byte	32
3038    0F46  4D        		.byte	77
3039    0F47  61        		.byte	97
3040    0F48  6E        		.byte	110
3041    0F49  75        		.byte	117
3042    0F4A  66        		.byte	102
3043    0F4B  61        		.byte	97
3044    0F4C  63        		.byte	99
3045    0F4D  74        		.byte	116
3046    0F4E  75        		.byte	117
3047    0F4F  72        		.byte	114
3048    0F50  65        		.byte	101
3049    0F51  72        		.byte	114
3050    0F52  20        		.byte	32
3051    0F53  49        		.byte	73
3052    0F54  44        		.byte	68
3053    0F55  3A        		.byte	58
3054    0F56  20        		.byte	32
3055    0F57  30        		.byte	48
3056    0F58  78        		.byte	120
3057    0F59  25        		.byte	37
3058    0F5A  30        		.byte	48
3059    0F5B  32        		.byte	50
3060    0F5C  78        		.byte	120
3061    0F5D  2C        		.byte	44
3062    0F5E  20        		.byte	32
3063    0F5F  00        		.byte	0
3064                    	L555:
3065    0F60  4F        		.byte	79
3066    0F61  45        		.byte	69
3067    0F62  4D        		.byte	77
3068    0F63  20        		.byte	32
3069    0F64  49        		.byte	73
3070    0F65  44        		.byte	68
3071    0F66  3A        		.byte	58
3072    0F67  20        		.byte	32
3073    0F68  25        		.byte	37
3074    0F69  2E        		.byte	46
3075    0F6A  32        		.byte	50
3076    0F6B  73        		.byte	115
3077    0F6C  2C        		.byte	44
3078    0F6D  20        		.byte	32
3079    0F6E  00        		.byte	0
3080                    	L565:
3081    0F6F  50        		.byte	80
3082    0F70  72        		.byte	114
3083    0F71  6F        		.byte	111
3084    0F72  64        		.byte	100
3085    0F73  75        		.byte	117
3086    0F74  63        		.byte	99
3087    0F75  74        		.byte	116
3088    0F76  20        		.byte	32
3089    0F77  6E        		.byte	110
3090    0F78  61        		.byte	97
3091    0F79  6D        		.byte	109
3092    0F7A  65        		.byte	101
3093    0F7B  3A        		.byte	58
3094    0F7C  20        		.byte	32
3095    0F7D  25        		.byte	37
3096    0F7E  2E        		.byte	46
3097    0F7F  35        		.byte	53
3098    0F80  73        		.byte	115
3099    0F81  0A        		.byte	10
3100    0F82  00        		.byte	0
3101                    	L575:
3102    0F83  20        		.byte	32
3103    0F84  20        		.byte	32
3104    0F85  50        		.byte	80
3105    0F86  72        		.byte	114
3106    0F87  6F        		.byte	111
3107    0F88  64        		.byte	100
3108    0F89  75        		.byte	117
3109    0F8A  63        		.byte	99
3110    0F8B  74        		.byte	116
3111    0F8C  20        		.byte	32
3112    0F8D  72        		.byte	114
3113    0F8E  65        		.byte	101
3114    0F8F  76        		.byte	118
3115    0F90  69        		.byte	105
3116    0F91  73        		.byte	115
3117    0F92  69        		.byte	105
3118    0F93  6F        		.byte	111
3119    0F94  6E        		.byte	110
3120    0F95  3A        		.byte	58
3121    0F96  20        		.byte	32
3122    0F97  25        		.byte	37
3123    0F98  64        		.byte	100
3124    0F99  2E        		.byte	46
3125    0F9A  25        		.byte	37
3126    0F9B  64        		.byte	100
3127    0F9C  2C        		.byte	44
3128    0F9D  20        		.byte	32
3129    0F9E  00        		.byte	0
3130                    	L506:
3131    0F9F  53        		.byte	83
3132    0FA0  65        		.byte	101
3133    0FA1  72        		.byte	114
3134    0FA2  69        		.byte	105
3135    0FA3  61        		.byte	97
3136    0FA4  6C        		.byte	108
3137    0FA5  20        		.byte	32
3138    0FA6  6E        		.byte	110
3139    0FA7  75        		.byte	117
3140    0FA8  6D        		.byte	109
3141    0FA9  62        		.byte	98
3142    0FAA  65        		.byte	101
3143    0FAB  72        		.byte	114
3144    0FAC  3A        		.byte	58
3145    0FAD  20        		.byte	32
3146    0FAE  25        		.byte	37
3147    0FAF  6C        		.byte	108
3148    0FB0  75        		.byte	117
3149    0FB1  0A        		.byte	10
3150    0FB2  00        		.byte	0
3151                    	L516:
3152    0FB3  20        		.byte	32
3153    0FB4  20        		.byte	32
3154    0FB5  4D        		.byte	77
3155    0FB6  61        		.byte	97
3156    0FB7  6E        		.byte	110
3157    0FB8  75        		.byte	117
3158    0FB9  66        		.byte	102
3159    0FBA  61        		.byte	97
3160    0FBB  63        		.byte	99
3161    0FBC  74        		.byte	116
3162    0FBD  75        		.byte	117
3163    0FBE  72        		.byte	114
3164    0FBF  69        		.byte	105
3165    0FC0  6E        		.byte	110
3166    0FC1  67        		.byte	103
3167    0FC2  20        		.byte	32
3168    0FC3  64        		.byte	100
3169    0FC4  61        		.byte	97
3170    0FC5  74        		.byte	116
3171    0FC6  65        		.byte	101
3172    0FC7  3A        		.byte	58
3173    0FC8  20        		.byte	32
3174    0FC9  25        		.byte	37
3175    0FCA  64        		.byte	100
3176    0FCB  2D        		.byte	45
3177    0FCC  25        		.byte	37
3178    0FCD  64        		.byte	100
3179    0FCE  2C        		.byte	44
3180    0FCF  20        		.byte	32
3181    0FD0  00        		.byte	0
3182                    	L526:
3183    0FD1  44        		.byte	68
3184    0FD2  65        		.byte	101
3185    0FD3  76        		.byte	118
3186    0FD4  69        		.byte	105
3187    0FD5  63        		.byte	99
3188    0FD6  65        		.byte	101
3189    0FD7  20        		.byte	32
3190    0FD8  63        		.byte	99
3191    0FD9  61        		.byte	97
3192    0FDA  70        		.byte	112
3193    0FDB  61        		.byte	97
3194    0FDC  63        		.byte	99
3195    0FDD  69        		.byte	105
3196    0FDE  74        		.byte	116
3197    0FDF  79        		.byte	121
3198    0FE0  3A        		.byte	58
3199    0FE1  20        		.byte	32
3200    0FE2  25        		.byte	37
3201    0FE3  6C        		.byte	108
3202    0FE4  75        		.byte	117
3203    0FE5  20        		.byte	32
3204    0FE6  4D        		.byte	77
3205    0FE7  42        		.byte	66
3206    0FE8  79        		.byte	121
3207    0FE9  74        		.byte	116
3208    0FEA  65        		.byte	101
3209    0FEB  0A        		.byte	10
3210    0FEC  00        		.byte	0
3211                    	L536:
3212    0FED  44        		.byte	68
3213    0FEE  65        		.byte	101
3214    0FEF  76        		.byte	118
3215    0FF0  69        		.byte	105
3216    0FF1  63        		.byte	99
3217    0FF2  65        		.byte	101
3218    0FF3  20        		.byte	32
3219    0FF4  63        		.byte	99
3220    0FF5  61        		.byte	97
3221    0FF6  70        		.byte	112
3222    0FF7  61        		.byte	97
3223    0FF8  63        		.byte	99
3224    0FF9  69        		.byte	105
3225    0FFA  74        		.byte	116
3226    0FFB  79        		.byte	121
3227    0FFC  3A        		.byte	58
3228    0FFD  20        		.byte	32
3229    0FFE  25        		.byte	37
3230    0FFF  6C        		.byte	108
3231    1000  75        		.byte	117
3232    1001  20        		.byte	32
3233    1002  4D        		.byte	77
3234    1003  42        		.byte	66
3235    1004  79        		.byte	121
3236    1005  74        		.byte	116
3237    1006  65        		.byte	101
3238    1007  0A        		.byte	10
3239    1008  00        		.byte	0
3240                    	L546:
3241    1009  44        		.byte	68
3242    100A  65        		.byte	101
3243    100B  76        		.byte	118
3244    100C  69        		.byte	105
3245    100D  63        		.byte	99
3246    100E  65        		.byte	101
3247    100F  20        		.byte	32
3248    1010  75        		.byte	117
3249    1011  6C        		.byte	108
3250    1012  74        		.byte	116
3251    1013  72        		.byte	114
3252    1014  61        		.byte	97
3253    1015  20        		.byte	32
3254    1016  63        		.byte	99
3255    1017  61        		.byte	97
3256    1018  70        		.byte	112
3257    1019  61        		.byte	97
3258    101A  63        		.byte	99
3259    101B  69        		.byte	105
3260    101C  74        		.byte	116
3261    101D  79        		.byte	121
3262    101E  3A        		.byte	58
3263    101F  20        		.byte	32
3264    1020  25        		.byte	37
3265    1021  6C        		.byte	108
3266    1022  75        		.byte	117
3267    1023  20        		.byte	32
3268    1024  4D        		.byte	77
3269    1025  42        		.byte	66
3270    1026  79        		.byte	121
3271    1027  74        		.byte	116
3272    1028  65        		.byte	101
3273    1029  0A        		.byte	10
3274    102A  00        		.byte	0
3275                    	L556:
3276    102B  2D        		.byte	45
3277    102C  2D        		.byte	45
3278    102D  2D        		.byte	45
3279    102E  2D        		.byte	45
3280    102F  2D        		.byte	45
3281    1030  2D        		.byte	45
3282    1031  2D        		.byte	45
3283    1032  2D        		.byte	45
3284    1033  2D        		.byte	45
3285    1034  2D        		.byte	45
3286    1035  2D        		.byte	45
3287    1036  2D        		.byte	45
3288    1037  2D        		.byte	45
3289    1038  2D        		.byte	45
3290    1039  2D        		.byte	45
3291    103A  2D        		.byte	45
3292    103B  2D        		.byte	45
3293    103C  2D        		.byte	45
3294    103D  2D        		.byte	45
3295    103E  2D        		.byte	45
3296    103F  2D        		.byte	45
3297    1040  2D        		.byte	45
3298    1041  2D        		.byte	45
3299    1042  2D        		.byte	45
3300    1043  2D        		.byte	45
3301    1044  2D        		.byte	45
3302    1045  2D        		.byte	45
3303    1046  2D        		.byte	45
3304    1047  2D        		.byte	45
3305    1048  2D        		.byte	45
3306    1049  2D        		.byte	45
3307    104A  2D        		.byte	45
3308    104B  2D        		.byte	45
3309    104C  2D        		.byte	45
3310    104D  2D        		.byte	45
3311    104E  2D        		.byte	45
3312    104F  2D        		.byte	45
3313    1050  2D        		.byte	45
3314    1051  0A        		.byte	10
3315    1052  00        		.byte	0
3316                    	L566:
3317    1053  4F        		.byte	79
3318    1054  43        		.byte	67
3319    1055  52        		.byte	82
3320    1056  20        		.byte	32
3321    1057  72        		.byte	114
3322    1058  65        		.byte	101
3323    1059  67        		.byte	103
3324    105A  69        		.byte	105
3325    105B  73        		.byte	115
3326    105C  74        		.byte	116
3327    105D  65        		.byte	101
3328    105E  72        		.byte	114
3329    105F  3A        		.byte	58
3330    1060  0A        		.byte	10
3331    1061  00        		.byte	0
3332                    	L576:
3333    1062  32        		.byte	50
3334    1063  2E        		.byte	46
3335    1064  37        		.byte	55
3336    1065  2D        		.byte	45
3337    1066  32        		.byte	50
3338    1067  2E        		.byte	46
3339    1068  38        		.byte	56
3340    1069  56        		.byte	86
3341    106A  20        		.byte	32
3342    106B  28        		.byte	40
3343    106C  62        		.byte	98
3344    106D  69        		.byte	105
3345    106E  74        		.byte	116
3346    106F  20        		.byte	32
3347    1070  31        		.byte	49
3348    1071  35        		.byte	53
3349    1072  29        		.byte	41
3350    1073  20        		.byte	32
3351    1074  00        		.byte	0
3352                    	L507:
3353    1075  32        		.byte	50
3354    1076  2E        		.byte	46
3355    1077  38        		.byte	56
3356    1078  2D        		.byte	45
3357    1079  32        		.byte	50
3358    107A  2E        		.byte	46
3359    107B  39        		.byte	57
3360    107C  56        		.byte	86
3361    107D  20        		.byte	32
3362    107E  28        		.byte	40
3363    107F  62        		.byte	98
3364    1080  69        		.byte	105
3365    1081  74        		.byte	116
3366    1082  20        		.byte	32
3367    1083  31        		.byte	49
3368    1084  36        		.byte	54
3369    1085  29        		.byte	41
3370    1086  20        		.byte	32
3371    1087  00        		.byte	0
3372                    	L517:
3373    1088  32        		.byte	50
3374    1089  2E        		.byte	46
3375    108A  39        		.byte	57
3376    108B  2D        		.byte	45
3377    108C  33        		.byte	51
3378    108D  2E        		.byte	46
3379    108E  30        		.byte	48
3380    108F  56        		.byte	86
3381    1090  20        		.byte	32
3382    1091  28        		.byte	40
3383    1092  62        		.byte	98
3384    1093  69        		.byte	105
3385    1094  74        		.byte	116
3386    1095  20        		.byte	32
3387    1096  31        		.byte	49
3388    1097  37        		.byte	55
3389    1098  29        		.byte	41
3390    1099  20        		.byte	32
3391    109A  00        		.byte	0
3392                    	L527:
3393    109B  33        		.byte	51
3394    109C  2E        		.byte	46
3395    109D  30        		.byte	48
3396    109E  2D        		.byte	45
3397    109F  33        		.byte	51
3398    10A0  2E        		.byte	46
3399    10A1  31        		.byte	49
3400    10A2  56        		.byte	86
3401    10A3  20        		.byte	32
3402    10A4  28        		.byte	40
3403    10A5  62        		.byte	98
3404    10A6  69        		.byte	105
3405    10A7  74        		.byte	116
3406    10A8  20        		.byte	32
3407    10A9  31        		.byte	49
3408    10AA  38        		.byte	56
3409    10AB  29        		.byte	41
3410    10AC  20        		.byte	32
3411    10AD  0A        		.byte	10
3412    10AE  00        		.byte	0
3413                    	L537:
3414    10AF  33        		.byte	51
3415    10B0  2E        		.byte	46
3416    10B1  31        		.byte	49
3417    10B2  2D        		.byte	45
3418    10B3  33        		.byte	51
3419    10B4  2E        		.byte	46
3420    10B5  32        		.byte	50
3421    10B6  56        		.byte	86
3422    10B7  20        		.byte	32
3423    10B8  28        		.byte	40
3424    10B9  62        		.byte	98
3425    10BA  69        		.byte	105
3426    10BB  74        		.byte	116
3427    10BC  20        		.byte	32
3428    10BD  31        		.byte	49
3429    10BE  39        		.byte	57
3430    10BF  29        		.byte	41
3431    10C0  20        		.byte	32
3432    10C1  00        		.byte	0
3433                    	L547:
3434    10C2  33        		.byte	51
3435    10C3  2E        		.byte	46
3436    10C4  32        		.byte	50
3437    10C5  2D        		.byte	45
3438    10C6  33        		.byte	51
3439    10C7  2E        		.byte	46
3440    10C8  33        		.byte	51
3441    10C9  56        		.byte	86
3442    10CA  20        		.byte	32
3443    10CB  28        		.byte	40
3444    10CC  62        		.byte	98
3445    10CD  69        		.byte	105
3446    10CE  74        		.byte	116
3447    10CF  20        		.byte	32
3448    10D0  32        		.byte	50
3449    10D1  30        		.byte	48
3450    10D2  29        		.byte	41
3451    10D3  20        		.byte	32
3452    10D4  00        		.byte	0
3453                    	L557:
3454    10D5  33        		.byte	51
3455    10D6  2E        		.byte	46
3456    10D7  33        		.byte	51
3457    10D8  2D        		.byte	45
3458    10D9  33        		.byte	51
3459    10DA  2E        		.byte	46
3460    10DB  34        		.byte	52
3461    10DC  56        		.byte	86
3462    10DD  20        		.byte	32
3463    10DE  28        		.byte	40
3464    10DF  62        		.byte	98
3465    10E0  69        		.byte	105
3466    10E1  74        		.byte	116
3467    10E2  20        		.byte	32
3468    10E3  32        		.byte	50
3469    10E4  31        		.byte	49
3470    10E5  29        		.byte	41
3471    10E6  20        		.byte	32
3472    10E7  00        		.byte	0
3473                    	L567:
3474    10E8  33        		.byte	51
3475    10E9  2E        		.byte	46
3476    10EA  34        		.byte	52
3477    10EB  2D        		.byte	45
3478    10EC  33        		.byte	51
3479    10ED  2E        		.byte	46
3480    10EE  35        		.byte	53
3481    10EF  56        		.byte	86
3482    10F0  20        		.byte	32
3483    10F1  28        		.byte	40
3484    10F2  62        		.byte	98
3485    10F3  69        		.byte	105
3486    10F4  74        		.byte	116
3487    10F5  20        		.byte	32
3488    10F6  32        		.byte	50
3489    10F7  32        		.byte	50
3490    10F8  29        		.byte	41
3491    10F9  20        		.byte	32
3492    10FA  0A        		.byte	10
3493    10FB  00        		.byte	0
3494                    	L577:
3495    10FC  33        		.byte	51
3496    10FD  2E        		.byte	46
3497    10FE  35        		.byte	53
3498    10FF  2D        		.byte	45
3499    1100  33        		.byte	51
3500    1101  2E        		.byte	46
3501    1102  36        		.byte	54
3502    1103  56        		.byte	86
3503    1104  20        		.byte	32
3504    1105  28        		.byte	40
3505    1106  62        		.byte	98
3506    1107  69        		.byte	105
3507    1108  74        		.byte	116
3508    1109  20        		.byte	32
3509    110A  32        		.byte	50
3510    110B  33        		.byte	51
3511    110C  29        		.byte	41
3512    110D  20        		.byte	32
3513    110E  0A        		.byte	10
3514    110F  00        		.byte	0
3515                    	L5001:
3516    1110  53        		.byte	83
3517    1111  77        		.byte	119
3518    1112  69        		.byte	105
3519    1113  74        		.byte	116
3520    1114  63        		.byte	99
3521    1115  68        		.byte	104
3522    1116  69        		.byte	105
3523    1117  6E        		.byte	110
3524    1118  67        		.byte	103
3525    1119  20        		.byte	32
3526    111A  74        		.byte	116
3527    111B  6F        		.byte	111
3528    111C  20        		.byte	32
3529    111D  31        		.byte	49
3530    111E  2E        		.byte	46
3531    111F  38        		.byte	56
3532    1120  56        		.byte	86
3533    1121  20        		.byte	32
3534    1122  41        		.byte	65
3535    1123  63        		.byte	99
3536    1124  63        		.byte	99
3537    1125  65        		.byte	101
3538    1126  70        		.byte	112
3539    1127  74        		.byte	116
3540    1128  65        		.byte	101
3541    1129  64        		.byte	100
3542    112A  20        		.byte	32
3543    112B  28        		.byte	40
3544    112C  53        		.byte	83
3545    112D  31        		.byte	49
3546    112E  38        		.byte	56
3547    112F  41        		.byte	65
3548    1130  29        		.byte	41
3549    1131  20        		.byte	32
3550    1132  28        		.byte	40
3551    1133  62        		.byte	98
3552    1134  69        		.byte	105
3553    1135  74        		.byte	116
3554    1136  20        		.byte	32
3555    1137  32        		.byte	50
3556    1138  34        		.byte	52
3557    1139  29        		.byte	41
3558    113A  20        		.byte	32
3559    113B  73        		.byte	115
3560    113C  65        		.byte	101
3561    113D  74        		.byte	116
3562    113E  20        		.byte	32
3563    113F  00        		.byte	0
3564                    	L5101:
3565    1140  4F        		.byte	79
3566    1141  76        		.byte	118
3567    1142  65        		.byte	101
3568    1143  72        		.byte	114
3569    1144  20        		.byte	32
3570    1145  32        		.byte	50
3571    1146  54        		.byte	84
3572    1147  42        		.byte	66
3573    1148  20        		.byte	32
3574    1149  73        		.byte	115
3575    114A  75        		.byte	117
3576    114B  70        		.byte	112
3577    114C  70        		.byte	112
3578    114D  6F        		.byte	111
3579    114E  72        		.byte	114
3580    114F  74        		.byte	116
3581    1150  20        		.byte	32
3582    1151  53        		.byte	83
3583    1152  74        		.byte	116
3584    1153  61        		.byte	97
3585    1154  74        		.byte	116
3586    1155  75        		.byte	117
3587    1156  73        		.byte	115
3588    1157  20        		.byte	32
3589    1158  28        		.byte	40
3590    1159  43        		.byte	67
3591    115A  4F        		.byte	79
3592    115B  32        		.byte	50
3593    115C  54        		.byte	84
3594    115D  29        		.byte	41
3595    115E  20        		.byte	32
3596    115F  28        		.byte	40
3597    1160  62        		.byte	98
3598    1161  69        		.byte	105
3599    1162  74        		.byte	116
3600    1163  20        		.byte	32
3601    1164  32        		.byte	50
3602    1165  37        		.byte	55
3603    1166  29        		.byte	41
3604    1167  20        		.byte	32
3605    1168  73        		.byte	115
3606    1169  65        		.byte	101
3607    116A  74        		.byte	116
3608    116B  0A        		.byte	10
3609    116C  00        		.byte	0
3610                    	L5201:
3611    116D  55        		.byte	85
3612    116E  48        		.byte	72
3613    116F  53        		.byte	83
3614    1170  2D        		.byte	45
3615    1171  49        		.byte	73
3616    1172  49        		.byte	73
3617    1173  20        		.byte	32
3618    1174  43        		.byte	67
3619    1175  61        		.byte	97
3620    1176  72        		.byte	114
3621    1177  64        		.byte	100
3622    1178  20        		.byte	32
3623    1179  53        		.byte	83
3624    117A  74        		.byte	116
3625    117B  61        		.byte	97
3626    117C  74        		.byte	116
3627    117D  75        		.byte	117
3628    117E  73        		.byte	115
3629    117F  20        		.byte	32
3630    1180  28        		.byte	40
3631    1181  62        		.byte	98
3632    1182  69        		.byte	105
3633    1183  74        		.byte	116
3634    1184  20        		.byte	32
3635    1185  32        		.byte	50
3636    1186  39        		.byte	57
3637    1187  29        		.byte	41
3638    1188  20        		.byte	32
3639    1189  73        		.byte	115
3640    118A  65        		.byte	101
3641    118B  74        		.byte	116
3642    118C  20        		.byte	32
3643    118D  00        		.byte	0
3644                    	L5301:
3645    118E  43        		.byte	67
3646    118F  61        		.byte	97
3647    1190  72        		.byte	114
3648    1191  64        		.byte	100
3649    1192  20        		.byte	32
3650    1193  43        		.byte	67
3651    1194  61        		.byte	97
3652    1195  70        		.byte	112
3653    1196  61        		.byte	97
3654    1197  63        		.byte	99
3655    1198  69        		.byte	105
3656    1199  74        		.byte	116
3657    119A  79        		.byte	121
3658    119B  20        		.byte	32
3659    119C  53        		.byte	83
3660    119D  74        		.byte	116
3661    119E  61        		.byte	97
3662    119F  74        		.byte	116
3663    11A0  75        		.byte	117
3664    11A1  73        		.byte	115
3665    11A2  20        		.byte	32
3666    11A3  28        		.byte	40
3667    11A4  43        		.byte	67
3668    11A5  43        		.byte	67
3669    11A6  53        		.byte	83
3670    11A7  29        		.byte	41
3671    11A8  20        		.byte	32
3672    11A9  28        		.byte	40
3673    11AA  62        		.byte	98
3674    11AB  69        		.byte	105
3675    11AC  74        		.byte	116
3676    11AD  20        		.byte	32
3677    11AE  33        		.byte	51
3678    11AF  30        		.byte	48
3679    11B0  29        		.byte	41
3680    11B1  20        		.byte	32
3681    11B2  73        		.byte	115
3682    11B3  65        		.byte	101
3683    11B4  74        		.byte	116
3684    11B5  0A        		.byte	10
3685    11B6  00        		.byte	0
3686                    	L5401:
3687    11B7  20        		.byte	32
3688    11B8  20        		.byte	32
3689    11B9  53        		.byte	83
3690    11BA  44        		.byte	68
3691    11BB  20        		.byte	32
3692    11BC  56        		.byte	86
3693    11BD  65        		.byte	101
3694    11BE  72        		.byte	114
3695    11BF  2E        		.byte	46
3696    11C0  32        		.byte	50
3697    11C1  2B        		.byte	43
3698    11C2  2C        		.byte	44
3699    11C3  20        		.byte	32
3700    11C4  42        		.byte	66
3701    11C5  6C        		.byte	108
3702    11C6  6F        		.byte	111
3703    11C7  63        		.byte	99
3704    11C8  6B        		.byte	107
3705    11C9  20        		.byte	32
3706    11CA  61        		.byte	97
3707    11CB  64        		.byte	100
3708    11CC  64        		.byte	100
3709    11CD  72        		.byte	114
3710    11CE  65        		.byte	101
3711    11CF  73        		.byte	115
3712    11D0  73        		.byte	115
3713    11D1  00        		.byte	0
3714                    	L5501:
3715    11D2  43        		.byte	67
3716    11D3  61        		.byte	97
3717    11D4  72        		.byte	114
3718    11D5  64        		.byte	100
3719    11D6  20        		.byte	32
3720    11D7  43        		.byte	67
3721    11D8  61        		.byte	97
3722    11D9  70        		.byte	112
3723    11DA  61        		.byte	97
3724    11DB  63        		.byte	99
3725    11DC  69        		.byte	105
3726    11DD  74        		.byte	116
3727    11DE  79        		.byte	121
3728    11DF  20        		.byte	32
3729    11E0  53        		.byte	83
3730    11E1  74        		.byte	116
3731    11E2  61        		.byte	97
3732    11E3  74        		.byte	116
3733    11E4  75        		.byte	117
3734    11E5  73        		.byte	115
3735    11E6  20        		.byte	32
3736    11E7  28        		.byte	40
3737    11E8  43        		.byte	67
3738    11E9  43        		.byte	67
3739    11EA  53        		.byte	83
3740    11EB  29        		.byte	41
3741    11EC  20        		.byte	32
3742    11ED  28        		.byte	40
3743    11EE  62        		.byte	98
3744    11EF  69        		.byte	105
3745    11F0  74        		.byte	116
3746    11F1  20        		.byte	32
3747    11F2  33        		.byte	51
3748    11F3  30        		.byte	48
3749    11F4  29        		.byte	41
3750    11F5  20        		.byte	32
3751    11F6  6E        		.byte	110
3752    11F7  6F        		.byte	111
3753    11F8  74        		.byte	116
3754    11F9  20        		.byte	32
3755    11FA  73        		.byte	115
3756    11FB  65        		.byte	101
3757    11FC  74        		.byte	116
3758    11FD  0A        		.byte	10
3759    11FE  00        		.byte	0
3760                    	L5601:
3761    11FF  20        		.byte	32
3762    1200  20        		.byte	32
3763    1201  53        		.byte	83
3764    1202  44        		.byte	68
3765    1203  20        		.byte	32
3766    1204  56        		.byte	86
3767    1205  65        		.byte	101
3768    1206  72        		.byte	114
3769    1207  2E        		.byte	46
3770    1208  32        		.byte	50
3771    1209  2B        		.byte	43
3772    120A  2C        		.byte	44
3773    120B  20        		.byte	32
3774    120C  42        		.byte	66
3775    120D  79        		.byte	121
3776    120E  74        		.byte	116
3777    120F  65        		.byte	101
3778    1210  20        		.byte	32
3779    1211  61        		.byte	97
3780    1212  64        		.byte	100
3781    1213  64        		.byte	100
3782    1214  72        		.byte	114
3783    1215  65        		.byte	101
3784    1216  73        		.byte	115
3785    1217  73        		.byte	115
3786    1218  00        		.byte	0
3787                    	L5701:
3788    1219  20        		.byte	32
3789    121A  20        		.byte	32
3790    121B  53        		.byte	83
3791    121C  44        		.byte	68
3792    121D  20        		.byte	32
3793    121E  56        		.byte	86
3794    121F  65        		.byte	101
3795    1220  72        		.byte	114
3796    1221  2E        		.byte	46
3797    1222  31        		.byte	49
3798    1223  2C        		.byte	44
3799    1224  20        		.byte	32
3800    1225  42        		.byte	66
3801    1226  79        		.byte	121
3802    1227  74        		.byte	116
3803    1228  65        		.byte	101
3804    1229  20        		.byte	32
3805    122A  61        		.byte	97
3806    122B  64        		.byte	100
3807    122C  64        		.byte	100
3808    122D  72        		.byte	114
3809    122E  65        		.byte	101
3810    122F  73        		.byte	115
3811    1230  73        		.byte	115
3812    1231  00        		.byte	0
3813                    	L5011:
3814    1232  0A        		.byte	10
3815    1233  43        		.byte	67
3816    1234  61        		.byte	97
3817    1235  72        		.byte	114
3818    1236  64        		.byte	100
3819    1237  20        		.byte	32
3820    1238  70        		.byte	112
3821    1239  6F        		.byte	111
3822    123A  77        		.byte	119
3823    123B  65        		.byte	101
3824    123C  72        		.byte	114
3825    123D  20        		.byte	32
3826    123E  75        		.byte	117
3827    123F  70        		.byte	112
3828    1240  20        		.byte	32
3829    1241  73        		.byte	115
3830    1242  74        		.byte	116
3831    1243  61        		.byte	97
3832    1244  74        		.byte	116
3833    1245  75        		.byte	117
3834    1246  73        		.byte	115
3835    1247  20        		.byte	32
3836    1248  62        		.byte	98
3837    1249  69        		.byte	105
3838    124A  74        		.byte	116
3839    124B  20        		.byte	32
3840    124C  28        		.byte	40
3841    124D  62        		.byte	98
3842    124E  75        		.byte	117
3843    124F  73        		.byte	115
3844    1250  79        		.byte	121
3845    1251  29        		.byte	41
3846    1252  20        		.byte	32
3847    1253  28        		.byte	40
3848    1254  62        		.byte	98
3849    1255  69        		.byte	105
3850    1256  74        		.byte	116
3851    1257  20        		.byte	32
3852    1258  33        		.byte	51
3853    1259  31        		.byte	49
3854    125A  29        		.byte	41
3855    125B  20        		.byte	32
3856    125C  73        		.byte	115
3857    125D  65        		.byte	101
3858    125E  74        		.byte	116
3859    125F  0A        		.byte	10
3860    1260  00        		.byte	0
3861                    	L5111:
3862    1261  0A        		.byte	10
3863    1262  43        		.byte	67
3864    1263  61        		.byte	97
3865    1264  72        		.byte	114
3866    1265  64        		.byte	100
3867    1266  20        		.byte	32
3868    1267  70        		.byte	112
3869    1268  6F        		.byte	111
3870    1269  77        		.byte	119
3871    126A  65        		.byte	101
3872    126B  72        		.byte	114
3873    126C  20        		.byte	32
3874    126D  75        		.byte	117
3875    126E  70        		.byte	112
3876    126F  20        		.byte	32
3877    1270  73        		.byte	115
3878    1271  74        		.byte	116
3879    1272  61        		.byte	97
3880    1273  74        		.byte	116
3881    1274  75        		.byte	117
3882    1275  73        		.byte	115
3883    1276  20        		.byte	32
3884    1277  62        		.byte	98
3885    1278  69        		.byte	105
3886    1279  74        		.byte	116
3887    127A  20        		.byte	32
3888    127B  28        		.byte	40
3889    127C  62        		.byte	98
3890    127D  75        		.byte	117
3891    127E  73        		.byte	115
3892    127F  79        		.byte	121
3893    1280  29        		.byte	41
3894    1281  20        		.byte	32
3895    1282  28        		.byte	40
3896    1283  62        		.byte	98
3897    1284  69        		.byte	105
3898    1285  74        		.byte	116
3899    1286  20        		.byte	32
3900    1287  33        		.byte	51
3901    1288  31        		.byte	49
3902    1289  29        		.byte	41
3903    128A  20        		.byte	32
3904    128B  6E        		.byte	110
3905    128C  6F        		.byte	111
3906    128D  74        		.byte	116
3907    128E  20        		.byte	32
3908    128F  73        		.byte	115
3909    1290  65        		.byte	101
3910    1291  74        		.byte	116
3911    1292  2E        		.byte	46
3912    1293  0A        		.byte	10
3913    1294  00        		.byte	0
3914                    	L5211:
3915    1295  20        		.byte	32
3916    1296  20        		.byte	32
3917    1297  54        		.byte	84
3918    1298  68        		.byte	104
3919    1299  69        		.byte	105
3920    129A  73        		.byte	115
3921    129B  20        		.byte	32
3922    129C  62        		.byte	98
3923    129D  69        		.byte	105
3924    129E  74        		.byte	116
3925    129F  20        		.byte	32
3926    12A0  69        		.byte	105
3927    12A1  73        		.byte	115
3928    12A2  20        		.byte	32
3929    12A3  6E        		.byte	110
3930    12A4  6F        		.byte	111
3931    12A5  74        		.byte	116
3932    12A6  20        		.byte	32
3933    12A7  73        		.byte	115
3934    12A8  65        		.byte	101
3935    12A9  74        		.byte	116
3936    12AA  20        		.byte	32
3937    12AB  69        		.byte	105
3938    12AC  66        		.byte	102
3939    12AD  20        		.byte	32
3940    12AE  74        		.byte	116
3941    12AF  68        		.byte	104
3942    12B0  65        		.byte	101
3943    12B1  20        		.byte	32
3944    12B2  63        		.byte	99
3945    12B3  61        		.byte	97
3946    12B4  72        		.byte	114
3947    12B5  64        		.byte	100
3948    12B6  20        		.byte	32
3949    12B7  68        		.byte	104
3950    12B8  61        		.byte	97
3951    12B9  73        		.byte	115
3952    12BA  20        		.byte	32
3953    12BB  6E        		.byte	110
3954    12BC  6F        		.byte	111
3955    12BD  74        		.byte	116
3956    12BE  20        		.byte	32
3957    12BF  66        		.byte	102
3958    12C0  69        		.byte	105
3959    12C1  6E        		.byte	110
3960    12C2  69        		.byte	105
3961    12C3  73        		.byte	115
3962    12C4  68        		.byte	104
3963    12C5  65        		.byte	101
3964    12C6  64        		.byte	100
3965    12C7  20        		.byte	32
3966    12C8  74        		.byte	116
3967    12C9  68        		.byte	104
3968    12CA  65        		.byte	101
3969    12CB  20        		.byte	32
3970    12CC  70        		.byte	112
3971    12CD  6F        		.byte	111
3972    12CE  77        		.byte	119
3973    12CF  65        		.byte	101
3974    12D0  72        		.byte	114
3975    12D1  20        		.byte	32
3976    12D2  75        		.byte	117
3977    12D3  70        		.byte	112
3978    12D4  20        		.byte	32
3979    12D5  72        		.byte	114
3980    12D6  6F        		.byte	111
3981    12D7  75        		.byte	117
3982    12D8  74        		.byte	116
3983    12D9  69        		.byte	105
3984    12DA  6E        		.byte	110
3985    12DB  65        		.byte	101
3986    12DC  2E        		.byte	46
3987    12DD  0A        		.byte	10
3988    12DE  00        		.byte	0
3989                    	L5311:
3990    12DF  2D        		.byte	45
3991    12E0  2D        		.byte	45
3992    12E1  2D        		.byte	45
3993    12E2  2D        		.byte	45
3994    12E3  2D        		.byte	45
3995    12E4  2D        		.byte	45
3996    12E5  2D        		.byte	45
3997    12E6  2D        		.byte	45
3998    12E7  2D        		.byte	45
3999    12E8  2D        		.byte	45
4000    12E9  2D        		.byte	45
4001    12EA  2D        		.byte	45
4002    12EB  2D        		.byte	45
4003    12EC  2D        		.byte	45
4004    12ED  2D        		.byte	45
4005    12EE  2D        		.byte	45
4006    12EF  2D        		.byte	45
4007    12F0  2D        		.byte	45
4008    12F1  2D        		.byte	45
4009    12F2  2D        		.byte	45
4010    12F3  2D        		.byte	45
4011    12F4  2D        		.byte	45
4012    12F5  2D        		.byte	45
4013    12F6  2D        		.byte	45
4014    12F7  2D        		.byte	45
4015    12F8  2D        		.byte	45
4016    12F9  2D        		.byte	45
4017    12FA  2D        		.byte	45
4018    12FB  2D        		.byte	45
4019    12FC  2D        		.byte	45
4020    12FD  2D        		.byte	45
4021    12FE  2D        		.byte	45
4022    12FF  2D        		.byte	45
4023    1300  2D        		.byte	45
4024    1301  2D        		.byte	45
4025    1302  2D        		.byte	45
4026    1303  2D        		.byte	45
4027    1304  2D        		.byte	45
4028    1305  0A        		.byte	10
4029    1306  00        		.byte	0
4030                    	L5411:
4031    1307  43        		.byte	67
4032    1308  49        		.byte	73
4033    1309  44        		.byte	68
4034    130A  20        		.byte	32
4035    130B  72        		.byte	114
4036    130C  65        		.byte	101
4037    130D  67        		.byte	103
4038    130E  69        		.byte	105
4039    130F  73        		.byte	115
4040    1310  74        		.byte	116
4041    1311  65        		.byte	101
4042    1312  72        		.byte	114
4043    1313  3A        		.byte	58
4044    1314  0A        		.byte	10
4045    1315  00        		.byte	0
4046                    	L5511:
4047    1316  4D        		.byte	77
4048    1317  49        		.byte	73
4049    1318  44        		.byte	68
4050    1319  3A        		.byte	58
4051    131A  20        		.byte	32
4052    131B  30        		.byte	48
4053    131C  78        		.byte	120
4054    131D  25        		.byte	37
4055    131E  30        		.byte	48
4056    131F  32        		.byte	50
4057    1320  78        		.byte	120
4058    1321  2C        		.byte	44
4059    1322  20        		.byte	32
4060    1323  00        		.byte	0
4061                    	L5611:
4062    1324  4F        		.byte	79
4063    1325  49        		.byte	73
4064    1326  44        		.byte	68
4065    1327  3A        		.byte	58
4066    1328  20        		.byte	32
4067    1329  25        		.byte	37
4068    132A  2E        		.byte	46
4069    132B  32        		.byte	50
4070    132C  73        		.byte	115
4071    132D  2C        		.byte	44
4072    132E  20        		.byte	32
4073    132F  00        		.byte	0
4074                    	L5711:
4075    1330  50        		.byte	80
4076    1331  4E        		.byte	78
4077    1332  4D        		.byte	77
4078    1333  3A        		.byte	58
4079    1334  20        		.byte	32
4080    1335  25        		.byte	37
4081    1336  2E        		.byte	46
4082    1337  35        		.byte	53
4083    1338  73        		.byte	115
4084    1339  2C        		.byte	44
4085    133A  20        		.byte	32
4086    133B  00        		.byte	0
4087                    	L5021:
4088    133C  50        		.byte	80
4089    133D  52        		.byte	82
4090    133E  56        		.byte	86
4091    133F  3A        		.byte	58
4092    1340  20        		.byte	32
4093    1341  25        		.byte	37
4094    1342  64        		.byte	100
4095    1343  2E        		.byte	46
   0    1344  25        		.byte	37
   1    1345  64        		.byte	100
   2    1346  2C        		.byte	44
   3    1347  20        		.byte	32
   4    1348  00        		.byte	0
   5                    	L5121:
   6    1349  50        		.byte	80
   7    134A  53        		.byte	83
   8    134B  4E        		.byte	78
   9    134C  3A        		.byte	58
  10    134D  20        		.byte	32
  11    134E  25        		.byte	37
  12    134F  6C        		.byte	108
  13    1350  75        		.byte	117
  14    1351  2C        		.byte	44
  15    1352  20        		.byte	32
  16    1353  00        		.byte	0
  17                    	L5221:
  18    1354  4D        		.byte	77
  19    1355  44        		.byte	68
  20    1356  54        		.byte	84
  21    1357  3A        		.byte	58
  22    1358  20        		.byte	32
  23    1359  25        		.byte	37
  24    135A  64        		.byte	100
  25    135B  2D        		.byte	45
  26    135C  25        		.byte	37
  27    135D  64        		.byte	100
  28    135E  0A        		.byte	10
  29    135F  00        		.byte	0
  30                    	L5321:
  31    1360  2D        		.byte	45
  32    1361  2D        		.byte	45
  33    1362  2D        		.byte	45
  34    1363  2D        		.byte	45
  35    1364  2D        		.byte	45
  36    1365  2D        		.byte	45
  37    1366  2D        		.byte	45
  38    1367  2D        		.byte	45
  39    1368  2D        		.byte	45
  40    1369  2D        		.byte	45
  41    136A  2D        		.byte	45
  42    136B  2D        		.byte	45
  43    136C  2D        		.byte	45
  44    136D  2D        		.byte	45
  45    136E  2D        		.byte	45
  46    136F  2D        		.byte	45
  47    1370  2D        		.byte	45
  48    1371  2D        		.byte	45
  49    1372  2D        		.byte	45
  50    1373  2D        		.byte	45
  51    1374  2D        		.byte	45
  52    1375  2D        		.byte	45
  53    1376  2D        		.byte	45
  54    1377  2D        		.byte	45
  55    1378  2D        		.byte	45
  56    1379  2D        		.byte	45
  57    137A  2D        		.byte	45
  58    137B  2D        		.byte	45
  59    137C  2D        		.byte	45
  60    137D  2D        		.byte	45
  61    137E  2D        		.byte	45
  62    137F  2D        		.byte	45
  63    1380  2D        		.byte	45
  64    1381  2D        		.byte	45
  65    1382  2D        		.byte	45
  66    1383  2D        		.byte	45
  67    1384  2D        		.byte	45
  68    1385  2D        		.byte	45
  69    1386  0A        		.byte	10
  70    1387  00        		.byte	0
  71                    	L5421:
  72    1388  43        		.byte	67
  73    1389  53        		.byte	83
  74    138A  44        		.byte	68
  75    138B  20        		.byte	32
  76    138C  72        		.byte	114
  77    138D  65        		.byte	101
  78    138E  67        		.byte	103
  79    138F  69        		.byte	105
  80    1390  73        		.byte	115
  81    1391  74        		.byte	116
  82    1392  65        		.byte	101
  83    1393  72        		.byte	114
  84    1394  3A        		.byte	58
  85    1395  0A        		.byte	10
  86    1396  00        		.byte	0
  87                    	L5521:
  88    1397  43        		.byte	67
  89    1398  53        		.byte	83
  90    1399  44        		.byte	68
  91    139A  20        		.byte	32
  92    139B  56        		.byte	86
  93    139C  65        		.byte	101
  94    139D  72        		.byte	114
  95    139E  73        		.byte	115
  96    139F  69        		.byte	105
  97    13A0  6F        		.byte	111
  98    13A1  6E        		.byte	110
  99    13A2  20        		.byte	32
 100    13A3  31        		.byte	49
 101    13A4  2E        		.byte	46
 102    13A5  30        		.byte	48
 103    13A6  2C        		.byte	44
 104    13A7  20        		.byte	32
 105    13A8  53        		.byte	83
 106    13A9  74        		.byte	116
 107    13AA  61        		.byte	97
 108    13AB  6E        		.byte	110
 109    13AC  64        		.byte	100
 110    13AD  61        		.byte	97
 111    13AE  72        		.byte	114
 112    13AF  64        		.byte	100
 113    13B0  20        		.byte	32
 114    13B1  43        		.byte	67
 115    13B2  61        		.byte	97
 116    13B3  70        		.byte	112
 117    13B4  61        		.byte	97
 118    13B5  63        		.byte	99
 119    13B6  69        		.byte	105
 120    13B7  74        		.byte	116
 121    13B8  79        		.byte	121
 122    13B9  0A        		.byte	10
 123    13BA  00        		.byte	0
 124                    	L5621:
 125    13BB  20        		.byte	32
 126    13BC  44        		.byte	68
 127    13BD  65        		.byte	101
 128    13BE  76        		.byte	118
 129    13BF  69        		.byte	105
 130    13C0  63        		.byte	99
 131    13C1  65        		.byte	101
 132    13C2  20        		.byte	32
 133    13C3  63        		.byte	99
 134    13C4  61        		.byte	97
 135    13C5  70        		.byte	112
 136    13C6  61        		.byte	97
 137    13C7  63        		.byte	99
 138    13C8  69        		.byte	105
 139    13C9  74        		.byte	116
 140    13CA  79        		.byte	121
 141    13CB  3A        		.byte	58
 142    13CC  20        		.byte	32
 143    13CD  25        		.byte	37
 144    13CE  6C        		.byte	108
 145    13CF  75        		.byte	117
 146    13D0  20        		.byte	32
 147    13D1  4B        		.byte	75
 148    13D2  42        		.byte	66
 149    13D3  79        		.byte	121
 150    13D4  74        		.byte	116
 151    13D5  65        		.byte	101
 152    13D6  2C        		.byte	44
 153    13D7  20        		.byte	32
 154    13D8  25        		.byte	37
 155    13D9  6C        		.byte	108
 156    13DA  75        		.byte	117
 157    13DB  20        		.byte	32
 158    13DC  4D        		.byte	77
 159    13DD  42        		.byte	66
 160    13DE  79        		.byte	121
 161    13DF  74        		.byte	116
 162    13E0  65        		.byte	101
 163    13E1  0A        		.byte	10
 164    13E2  00        		.byte	0
 165                    	L5721:
 166    13E3  43        		.byte	67
 167    13E4  53        		.byte	83
 168    13E5  44        		.byte	68
 169    13E6  20        		.byte	32
 170    13E7  56        		.byte	86
 171    13E8  65        		.byte	101
 172    13E9  72        		.byte	114
 173    13EA  73        		.byte	115
 174    13EB  69        		.byte	105
 175    13EC  6F        		.byte	111
 176    13ED  6E        		.byte	110
 177    13EE  20        		.byte	32
 178    13EF  32        		.byte	50
 179    13F0  2E        		.byte	46
 180    13F1  30        		.byte	48
 181    13F2  2C        		.byte	44
 182    13F3  20        		.byte	32
 183    13F4  48        		.byte	72
 184    13F5  69        		.byte	105
 185    13F6  67        		.byte	103
 186    13F7  68        		.byte	104
 187    13F8  20        		.byte	32
 188    13F9  43        		.byte	67
 189    13FA  61        		.byte	97
 190    13FB  70        		.byte	112
 191    13FC  61        		.byte	97
 192    13FD  63        		.byte	99
 193    13FE  69        		.byte	105
 194    13FF  74        		.byte	116
 195    1400  79        		.byte	121
 196    1401  20        		.byte	32
 197    1402  61        		.byte	97
 198    1403  6E        		.byte	110
 199    1404  64        		.byte	100
 200    1405  20        		.byte	32
 201    1406  45        		.byte	69
 202    1407  78        		.byte	120
 203    1408  74        		.byte	116
 204    1409  65        		.byte	101
 205    140A  6E        		.byte	110
 206    140B  64        		.byte	100
 207    140C  65        		.byte	101
 208    140D  64        		.byte	100
 209    140E  20        		.byte	32
 210    140F  43        		.byte	67
 211    1410  61        		.byte	97
 212    1411  70        		.byte	112
 213    1412  61        		.byte	97
 214    1413  63        		.byte	99
 215    1414  69        		.byte	105
 216    1415  74        		.byte	116
 217    1416  79        		.byte	121
 218    1417  0A        		.byte	10
 219    1418  00        		.byte	0
 220                    	L5031:
 221    1419  20        		.byte	32
 222    141A  44        		.byte	68
 223    141B  65        		.byte	101
 224    141C  76        		.byte	118
 225    141D  69        		.byte	105
 226    141E  63        		.byte	99
 227    141F  65        		.byte	101
 228    1420  20        		.byte	32
 229    1421  63        		.byte	99
 230    1422  61        		.byte	97
 231    1423  70        		.byte	112
 232    1424  61        		.byte	97
 233    1425  63        		.byte	99
 234    1426  69        		.byte	105
 235    1427  74        		.byte	116
 236    1428  79        		.byte	121
 237    1429  3A        		.byte	58
 238    142A  20        		.byte	32
 239    142B  25        		.byte	37
 240    142C  6C        		.byte	108
 241    142D  75        		.byte	117
 242    142E  20        		.byte	32
 243    142F  4B        		.byte	75
 244    1430  42        		.byte	66
 245    1431  79        		.byte	121
 246    1432  74        		.byte	116
 247    1433  65        		.byte	101
 248    1434  2C        		.byte	44
 249    1435  20        		.byte	32
 250    1436  25        		.byte	37
 251    1437  6C        		.byte	108
 252    1438  75        		.byte	117
 253    1439  20        		.byte	32
 254    143A  4D        		.byte	77
 255    143B  42        		.byte	66
 256    143C  79        		.byte	121
 257    143D  74        		.byte	116
 258    143E  65        		.byte	101
 259    143F  0A        		.byte	10
 260    1440  00        		.byte	0
 261                    	L5131:
 262    1441  43        		.byte	67
 263    1442  53        		.byte	83
 264    1443  44        		.byte	68
 265    1444  20        		.byte	32
 266    1445  56        		.byte	86
 267    1446  65        		.byte	101
 268    1447  72        		.byte	114
 269    1448  73        		.byte	115
 270    1449  69        		.byte	105
 271    144A  6F        		.byte	111
 272    144B  6E        		.byte	110
 273    144C  20        		.byte	32
 274    144D  33        		.byte	51
 275    144E  2E        		.byte	46
 276    144F  30        		.byte	48
 277    1450  2C        		.byte	44
 278    1451  20        		.byte	32
 279    1452  55        		.byte	85
 280    1453  6C        		.byte	108
 281    1454  74        		.byte	116
 282    1455  72        		.byte	114
 283    1456  61        		.byte	97
 284    1457  20        		.byte	32
 285    1458  43        		.byte	67
 286    1459  61        		.byte	97
 287    145A  70        		.byte	112
 288    145B  61        		.byte	97
 289    145C  63        		.byte	99
 290    145D  69        		.byte	105
 291    145E  74        		.byte	116
 292    145F  79        		.byte	121
 293    1460  20        		.byte	32
 294    1461  28        		.byte	40
 295    1462  53        		.byte	83
 296    1463  44        		.byte	68
 297    1464  55        		.byte	85
 298    1465  43        		.byte	67
 299    1466  29        		.byte	41
 300    1467  0A        		.byte	10
 301    1468  00        		.byte	0
 302                    	L5231:
 303    1469  20        		.byte	32
 304    146A  44        		.byte	68
 305    146B  65        		.byte	101
 306    146C  76        		.byte	118
 307    146D  69        		.byte	105
 308    146E  63        		.byte	99
 309    146F  65        		.byte	101
 310    1470  20        		.byte	32
 311    1471  63        		.byte	99
 312    1472  61        		.byte	97
 313    1473  70        		.byte	112
 314    1474  61        		.byte	97
 315    1475  63        		.byte	99
 316    1476  69        		.byte	105
 317    1477  74        		.byte	116
 318    1478  79        		.byte	121
 319    1479  3A        		.byte	58
 320    147A  20        		.byte	32
 321    147B  25        		.byte	37
 322    147C  6C        		.byte	108
 323    147D  75        		.byte	117
 324    147E  20        		.byte	32
 325    147F  4B        		.byte	75
 326    1480  42        		.byte	66
 327    1481  79        		.byte	121
 328    1482  74        		.byte	116
 329    1483  65        		.byte	101
 330    1484  2C        		.byte	44
 331    1485  20        		.byte	32
 332    1486  25        		.byte	37
 333    1487  6C        		.byte	108
 334    1488  75        		.byte	117
 335    1489  20        		.byte	32
 336    148A  4D        		.byte	77
 337    148B  42        		.byte	66
 338    148C  79        		.byte	121
 339    148D  74        		.byte	116
 340    148E  65        		.byte	101
 341    148F  0A        		.byte	10
 342    1490  00        		.byte	0
 343                    	L5331:
 344    1491  2D        		.byte	45
 345    1492  2D        		.byte	45
 346    1493  2D        		.byte	45
 347    1494  2D        		.byte	45
 348    1495  2D        		.byte	45
 349    1496  2D        		.byte	45
 350    1497  2D        		.byte	45
 351    1498  2D        		.byte	45
 352    1499  2D        		.byte	45
 353    149A  2D        		.byte	45
 354    149B  2D        		.byte	45
 355    149C  2D        		.byte	45
 356    149D  2D        		.byte	45
 357    149E  2D        		.byte	45
 358    149F  2D        		.byte	45
 359    14A0  2D        		.byte	45
 360    14A1  2D        		.byte	45
 361    14A2  2D        		.byte	45
 362    14A3  2D        		.byte	45
 363    14A4  2D        		.byte	45
 364    14A5  2D        		.byte	45
 365    14A6  2D        		.byte	45
 366    14A7  2D        		.byte	45
 367    14A8  2D        		.byte	45
 368    14A9  2D        		.byte	45
 369    14AA  2D        		.byte	45
 370    14AB  2D        		.byte	45
 371    14AC  2D        		.byte	45
 372    14AD  2D        		.byte	45
 373    14AE  2D        		.byte	45
 374    14AF  2D        		.byte	45
 375    14B0  2D        		.byte	45
 376    14B1  2D        		.byte	45
 377    14B2  2D        		.byte	45
 378    14B3  2D        		.byte	45
 379    14B4  2D        		.byte	45
 380    14B5  2D        		.byte	45
 381    14B6  2D        		.byte	45
 382    14B7  0A        		.byte	10
 383    14B8  00        		.byte	0
 384                    	;  494      }
 385                    	;  495  
 386                    	;  496  /* print OCR, CID and CSD registers*/
 387                    	;  497  void sdprtreg()
 388                    	;  498      {
 389                    	_sdprtreg:
 390    14B9  CD0000    		call	c.savs0
 391    14BC  21EEFF    		ld	hl,65518
 392    14BF  39        		add	hl,sp
 393    14C0  F9        		ld	sp,hl
 394                    	;  499      unsigned int n;
 395                    	;  500      unsigned int csize;
 396                    	;  501      unsigned long devsize;
 397                    	;  502      unsigned long capacity;
 398                    	;  503  
 399                    	;  504      if (!sdinitok)
 400    14C1  2A0A00    		ld	hl,(_sdinitok)
 401    14C4  7C        		ld	a,h
 402    14C5  B5        		or	l
 403    14C6  2009      		jr	nz,L1371
 404                    	;  505          {
 405                    	;  506          printf("SD card not initialized\n");
 406    14C8  21B30E    		ld	hl,L574
 407    14CB  CD0000    		call	_printf
 408                    	;  507          return;
 409    14CE  C30000    		jp	c.rets0
 410                    	L1371:
 411                    	;  508          }
 412                    	;  509      printf("SD card information:");
 413    14D1  21CC0E    		ld	hl,L505
 414    14D4  CD0000    		call	_printf
 415                    	;  510      if (ocrreg[0] & 0x80)
 416    14D7  3A2E00    		ld	a,(_ocrreg)
 417    14DA  CB7F      		bit	7,a
 418    14DC  6F        		ld	l,a
 419    14DD  2825      		jr	z,L1471
 420                    	;  511          {
 421                    	;  512          if (ocrreg[0] & 0x40)
 422    14DF  3A2E00    		ld	a,(_ocrreg)
 423    14E2  CB77      		bit	6,a
 424    14E4  6F        		ld	l,a
 425    14E5  2808      		jr	z,L1571
 426                    	;  513              printf("  SD card ver. 2+, Block address\n");
 427    14E7  21E10E    		ld	hl,L515
 428    14EA  CD0000    		call	_printf
 429                    	;  514          else
 430    14ED  1815      		jr	L1471
 431                    	L1571:
 432                    	;  515              {
 433                    	;  516              if (sdver2)
 434    14EF  2A0800    		ld	hl,(_sdver2)
 435    14F2  7C        		ld	a,h
 436    14F3  B5        		or	l
 437    14F4  2808      		jr	z,L1771
 438                    	;  517                  printf("  SD card ver. 2+, Byte address\n");
 439    14F6  21030F    		ld	hl,L525
 440    14F9  CD0000    		call	_printf
 441                    	;  518              else
 442    14FC  1806      		jr	L1471
 443                    	L1771:
 444                    	;  519                  printf("  SD card ver. 1, Byte address\n");
 445    14FE  21240F    		ld	hl,L535
 446    1501  CD0000    		call	_printf
 447                    	L1471:
 448                    	;  520              }
 449                    	;  521          }
 450                    	;  522      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
 451    1504  3A1E00    		ld	a,(_cidreg)
 452    1507  4F        		ld	c,a
 453    1508  97        		sub	a
 454    1509  47        		ld	b,a
 455    150A  C5        		push	bc
 456    150B  21440F    		ld	hl,L545
 457    150E  CD0000    		call	_printf
 458    1511  F1        		pop	af
 459                    	;  523      printf("OEM ID: %.2s, ", &cidreg[1]);
 460    1512  211F00    		ld	hl,_cidreg+1
 461    1515  E5        		push	hl
 462    1516  21600F    		ld	hl,L555
 463    1519  CD0000    		call	_printf
 464    151C  F1        		pop	af
 465                    	;  524      printf("Product name: %.5s\n", &cidreg[3]);
 466    151D  212100    		ld	hl,_cidreg+3
 467    1520  E5        		push	hl
 468    1521  216F0F    		ld	hl,L565
 469    1524  CD0000    		call	_printf
 470    1527  F1        		pop	af
 471                    	;  525      printf("  Product revision: %d.%d, ",
 472                    	;  526             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 473    1528  3A2600    		ld	a,(_cidreg+8)
 474    152B  6F        		ld	l,a
 475    152C  97        		sub	a
 476    152D  67        		ld	h,a
 477    152E  7D        		ld	a,l
 478    152F  E60F      		and	15
 479    1531  6F        		ld	l,a
 480    1532  97        		sub	a
 481    1533  67        		ld	h,a
 482    1534  E5        		push	hl
 483    1535  3A2600    		ld	a,(_cidreg+8)
 484    1538  4F        		ld	c,a
 485    1539  97        		sub	a
 486    153A  47        		ld	b,a
 487    153B  C5        		push	bc
 488    153C  210400    		ld	hl,4
 489    153F  E5        		push	hl
 490    1540  CD0000    		call	c.irsh
 491    1543  E1        		pop	hl
 492    1544  7D        		ld	a,l
 493    1545  E60F      		and	15
 494    1547  6F        		ld	l,a
 495    1548  97        		sub	a
 496    1549  67        		ld	h,a
 497    154A  E5        		push	hl
 498    154B  21830F    		ld	hl,L575
 499    154E  CD0000    		call	_printf
 500    1551  F1        		pop	af
 501    1552  F1        		pop	af
 502                    	;  527      printf("Serial number: %lu\n",
 503                    	;  528             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
 504    1553  3A2700    		ld	a,(_cidreg+9)
 505    1556  4F        		ld	c,a
 506    1557  97        		sub	a
 507    1558  47        		ld	b,a
 508    1559  C5        		push	bc
 509    155A  211800    		ld	hl,24
 510    155D  E5        		push	hl
 511    155E  CD0000    		call	c.ilsh
 512    1561  E1        		pop	hl
 513    1562  E5        		push	hl
 514    1563  3A2800    		ld	a,(_cidreg+10)
 515    1566  4F        		ld	c,a
 516    1567  97        		sub	a
 517    1568  47        		ld	b,a
 518    1569  C5        		push	bc
 519    156A  211000    		ld	hl,16
 520    156D  E5        		push	hl
 521    156E  CD0000    		call	c.ilsh
 522    1571  E1        		pop	hl
 523    1572  E3        		ex	(sp),hl
 524    1573  C1        		pop	bc
 525    1574  09        		add	hl,bc
 526    1575  E5        		push	hl
 527    1576  3A2900    		ld	a,(_cidreg+11)
 528    1579  6F        		ld	l,a
 529    157A  97        		sub	a
 530    157B  67        		ld	h,a
 531    157C  29        		add	hl,hl
 532    157D  29        		add	hl,hl
 533    157E  29        		add	hl,hl
 534    157F  29        		add	hl,hl
 535    1580  29        		add	hl,hl
 536    1581  29        		add	hl,hl
 537    1582  29        		add	hl,hl
 538    1583  29        		add	hl,hl
 539    1584  E3        		ex	(sp),hl
 540    1585  C1        		pop	bc
 541    1586  09        		add	hl,bc
 542    1587  E5        		push	hl
 543    1588  3A2A00    		ld	a,(_cidreg+12)
 544    158B  6F        		ld	l,a
 545    158C  97        		sub	a
 546    158D  67        		ld	h,a
 547    158E  E3        		ex	(sp),hl
 548    158F  C1        		pop	bc
 549    1590  09        		add	hl,bc
 550    1591  E5        		push	hl
 551    1592  219F0F    		ld	hl,L506
 552    1595  CD0000    		call	_printf
 553    1598  F1        		pop	af
 554                    	;  529      printf("  Manufacturing date: %d-%d, ",
 555                    	;  530             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
 556    1599  3A2C00    		ld	a,(_cidreg+14)
 557    159C  6F        		ld	l,a
 558    159D  97        		sub	a
 559    159E  67        		ld	h,a
 560    159F  7D        		ld	a,l
 561    15A0  E60F      		and	15
 562    15A2  6F        		ld	l,a
 563    15A3  97        		sub	a
 564    15A4  67        		ld	h,a
 565    15A5  E5        		push	hl
 566    15A6  3A2B00    		ld	a,(_cidreg+13)
 567    15A9  6F        		ld	l,a
 568    15AA  97        		sub	a
 569    15AB  67        		ld	h,a
 570    15AC  7D        		ld	a,l
 571    15AD  E60F      		and	15
 572    15AF  6F        		ld	l,a
 573    15B0  97        		sub	a
 574    15B1  67        		ld	h,a
 575    15B2  29        		add	hl,hl
 576    15B3  29        		add	hl,hl
 577    15B4  29        		add	hl,hl
 578    15B5  29        		add	hl,hl
 579    15B6  01D007    		ld	bc,2000
 580    15B9  09        		add	hl,bc
 581    15BA  E5        		push	hl
 582    15BB  3A2C00    		ld	a,(_cidreg+14)
 583    15BE  4F        		ld	c,a
 584    15BF  97        		sub	a
 585    15C0  47        		ld	b,a
 586    15C1  C5        		push	bc
 587    15C2  210400    		ld	hl,4
 588    15C5  E5        		push	hl
 589    15C6  CD0000    		call	c.irsh
 590    15C9  E1        		pop	hl
 591    15CA  E3        		ex	(sp),hl
 592    15CB  C1        		pop	bc
 593    15CC  09        		add	hl,bc
 594    15CD  E5        		push	hl
 595    15CE  21B30F    		ld	hl,L516
 596    15D1  CD0000    		call	_printf
 597    15D4  F1        		pop	af
 598    15D5  F1        		pop	af
 599                    	;  531      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
 600    15D6  3A0E00    		ld	a,(_csdreg)
 601    15D9  E6C0      		and	192
 602    15DB  C2B916    		jp	nz,L1102
 603                    	;  532          {
 604                    	;  533          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
 605    15DE  3A1300    		ld	a,(_csdreg+5)
 606    15E1  6F        		ld	l,a
 607    15E2  97        		sub	a
 608    15E3  67        		ld	h,a
 609    15E4  7D        		ld	a,l
 610    15E5  E60F      		and	15
 611    15E7  6F        		ld	l,a
 612    15E8  97        		sub	a
 613    15E9  67        		ld	h,a
 614    15EA  E5        		push	hl
 615    15EB  3A1800    		ld	a,(_csdreg+10)
 616    15EE  6F        		ld	l,a
 617    15EF  97        		sub	a
 618    15F0  67        		ld	h,a
 619    15F1  7D        		ld	a,l
 620    15F2  E680      		and	128
 621    15F4  6F        		ld	l,a
 622    15F5  97        		sub	a
 623    15F6  67        		ld	h,a
 624    15F7  E5        		push	hl
 625    15F8  210700    		ld	hl,7
 626    15FB  E5        		push	hl
 627    15FC  CD0000    		call	c.irsh
 628    15FF  E1        		pop	hl
 629    1600  E3        		ex	(sp),hl
 630    1601  C1        		pop	bc
 631    1602  09        		add	hl,bc
 632    1603  E5        		push	hl
 633    1604  3A1700    		ld	a,(_csdreg+9)
 634    1607  6F        		ld	l,a
 635    1608  97        		sub	a
 636    1609  67        		ld	h,a
 637    160A  7D        		ld	a,l
 638    160B  E603      		and	3
 639    160D  6F        		ld	l,a
 640    160E  97        		sub	a
 641    160F  67        		ld	h,a
 642    1610  29        		add	hl,hl
 643    1611  E3        		ex	(sp),hl
 644    1612  C1        		pop	bc
 645    1613  09        		add	hl,bc
 646    1614  23        		inc	hl
 647    1615  23        		inc	hl
 648    1616  DD75F8    		ld	(ix-8),l
 649    1619  DD74F9    		ld	(ix-7),h
 650                    	;  534          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
 651                    	;  535                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
 652    161C  3A1600    		ld	a,(_csdreg+8)
 653    161F  4F        		ld	c,a
 654    1620  97        		sub	a
 655    1621  47        		ld	b,a
 656    1622  C5        		push	bc
 657    1623  210600    		ld	hl,6
 658    1626  E5        		push	hl
 659    1627  CD0000    		call	c.irsh
 660    162A  E1        		pop	hl
 661    162B  E5        		push	hl
 662    162C  3A1500    		ld	a,(_csdreg+7)
 663    162F  6F        		ld	l,a
 664    1630  97        		sub	a
 665    1631  67        		ld	h,a
 666    1632  29        		add	hl,hl
 667    1633  29        		add	hl,hl
 668    1634  E3        		ex	(sp),hl
 669    1635  C1        		pop	bc
 670    1636  09        		add	hl,bc
 671    1637  E5        		push	hl
 672    1638  3A1400    		ld	a,(_csdreg+6)
 673    163B  6F        		ld	l,a
 674    163C  97        		sub	a
 675    163D  67        		ld	h,a
 676    163E  7D        		ld	a,l
 677    163F  E603      		and	3
 678    1641  6F        		ld	l,a
 679    1642  97        		sub	a
 680    1643  67        		ld	h,a
 681    1644  E5        		push	hl
 682    1645  210A00    		ld	hl,10
 683    1648  E5        		push	hl
 684    1649  CD0000    		call	c.ilsh
 685    164C  E1        		pop	hl
 686    164D  E3        		ex	(sp),hl
 687    164E  C1        		pop	bc
 688    164F  09        		add	hl,bc
 689    1650  23        		inc	hl
 690    1651  DD75F6    		ld	(ix-10),l
 691    1654  DD74F7    		ld	(ix-9),h
 692                    	;  536          capacity = (unsigned long) csize << (n-10);
 693    1657  DDE5      		push	ix
 694    1659  C1        		pop	bc
 695    165A  21EEFF    		ld	hl,65518
 696    165D  09        		add	hl,bc
 697    165E  E5        		push	hl
 698    165F  DDE5      		push	ix
 699    1661  C1        		pop	bc
 700    1662  21F6FF    		ld	hl,65526
 701    1665  09        		add	hl,bc
 702    1666  4D        		ld	c,l
 703    1667  44        		ld	b,h
 704    1668  97        		sub	a
 705    1669  320000    		ld	(c.r0),a
 706    166C  320100    		ld	(c.r0+1),a
 707    166F  0A        		ld	a,(bc)
 708    1670  320200    		ld	(c.r0+2),a
 709    1673  03        		inc	bc
 710    1674  0A        		ld	a,(bc)
 711    1675  320300    		ld	(c.r0+3),a
 712    1678  210000    		ld	hl,c.r0
 713    167B  E5        		push	hl
 714    167C  DD6EF8    		ld	l,(ix-8)
 715    167F  DD66F9    		ld	h,(ix-7)
 716    1682  01F6FF    		ld	bc,65526
 717    1685  09        		add	hl,bc
 718    1686  E5        		push	hl
 719    1687  CD0000    		call	c.llsh
 720    168A  CD0000    		call	c.mvl
 721    168D  F1        		pop	af
 722                    	;  537          printf("Device capacity: %lu MByte\n", capacity >> 10);
 723    168E  DDE5      		push	ix
 724    1690  C1        		pop	bc
 725    1691  21EEFF    		ld	hl,65518
 726    1694  09        		add	hl,bc
 727    1695  CD0000    		call	c.0mvf
 728    1698  210000    		ld	hl,c.r0
 729    169B  E5        		push	hl
 730    169C  210A00    		ld	hl,10
 731    169F  E5        		push	hl
 732    16A0  CD0000    		call	c.ulrsh
 733    16A3  E1        		pop	hl
 734    16A4  23        		inc	hl
 735    16A5  23        		inc	hl
 736    16A6  4E        		ld	c,(hl)
 737    16A7  23        		inc	hl
 738    16A8  46        		ld	b,(hl)
 739    16A9  C5        		push	bc
 740    16AA  2B        		dec	hl
 741    16AB  2B        		dec	hl
 742    16AC  2B        		dec	hl
 743    16AD  4E        		ld	c,(hl)
 744    16AE  23        		inc	hl
 745    16AF  46        		ld	b,(hl)
 746    16B0  C5        		push	bc
 747    16B1  21D10F    		ld	hl,L526
 748    16B4  CD0000    		call	_printf
 749    16B7  F1        		pop	af
 750    16B8  F1        		pop	af
 751                    	L1102:
 752                    	;  538          }
 753                    	;  539      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
 754    16B9  3A0E00    		ld	a,(_csdreg)
 755    16BC  6F        		ld	l,a
 756    16BD  97        		sub	a
 757    16BE  67        		ld	h,a
 758    16BF  7D        		ld	a,l
 759    16C0  E6C0      		and	192
 760    16C2  6F        		ld	l,a
 761    16C3  97        		sub	a
 762    16C4  67        		ld	h,a
 763    16C5  7D        		ld	a,l
 764    16C6  FE40      		cp	64
 765    16C8  2003      		jr	nz,L26
 766    16CA  7C        		ld	a,h
 767    16CB  FE00      		cp	0
 768                    	L26:
 769    16CD  C2A017    		jp	nz,L1202
 770                    	;  540          {
 771                    	;  541          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
 772                    	;  542                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 773    16D0  DDE5      		push	ix
 774    16D2  C1        		pop	bc
 775    16D3  21F2FF    		ld	hl,65522
 776    16D6  09        		add	hl,bc
 777    16D7  E5        		push	hl
 778    16D8  97        		sub	a
 779    16D9  320000    		ld	(c.r0),a
 780    16DC  320100    		ld	(c.r0+1),a
 781    16DF  3A1600    		ld	a,(_csdreg+8)
 782    16E2  320200    		ld	(c.r0+2),a
 783    16E5  97        		sub	a
 784    16E6  320300    		ld	(c.r0+3),a
 785    16E9  210000    		ld	hl,c.r0
 786    16EC  E5        		push	hl
 787    16ED  210800    		ld	hl,8
 788    16F0  E5        		push	hl
 789    16F1  CD0000    		call	c.llsh
 790    16F4  97        		sub	a
 791    16F5  320000    		ld	(c.r1),a
 792    16F8  320100    		ld	(c.r1+1),a
 793    16FB  3A1700    		ld	a,(_csdreg+9)
 794    16FE  320200    		ld	(c.r1+2),a
 795    1701  97        		sub	a
 796    1702  320300    		ld	(c.r1+3),a
 797    1705  210000    		ld	hl,c.r1
 798    1708  E5        		push	hl
 799    1709  CD0000    		call	c.ladd
 800    170C  3A1500    		ld	a,(_csdreg+7)
 801    170F  6F        		ld	l,a
 802    1710  97        		sub	a
 803    1711  67        		ld	h,a
 804    1712  7D        		ld	a,l
 805    1713  E63F      		and	63
 806    1715  6F        		ld	l,a
 807    1716  97        		sub	a
 808    1717  67        		ld	h,a
 809    1718  4D        		ld	c,l
 810    1719  44        		ld	b,h
 811    171A  78        		ld	a,b
 812    171B  87        		add	a,a
 813    171C  9F        		sbc	a,a
 814    171D  320000    		ld	(c.r1),a
 815    1720  320100    		ld	(c.r1+1),a
 816    1723  78        		ld	a,b
 817    1724  320300    		ld	(c.r1+3),a
 818    1727  79        		ld	a,c
 819    1728  320200    		ld	(c.r1+2),a
 820    172B  210000    		ld	hl,c.r1
 821    172E  E5        		push	hl
 822    172F  211000    		ld	hl,16
 823    1732  E5        		push	hl
 824    1733  CD0000    		call	c.llsh
 825    1736  CD0000    		call	c.ladd
 826    1739  3E01      		ld	a,1
 827    173B  320200    		ld	(c.r1+2),a
 828    173E  87        		add	a,a
 829    173F  9F        		sbc	a,a
 830    1740  320300    		ld	(c.r1+3),a
 831    1743  320100    		ld	(c.r1+1),a
 832    1746  320000    		ld	(c.r1),a
 833    1749  210000    		ld	hl,c.r1
 834    174C  E5        		push	hl
 835    174D  CD0000    		call	c.ladd
 836    1750  CD0000    		call	c.mvl
 837    1753  F1        		pop	af
 838                    	;  543          capacity = devsize << 9;
 839    1754  DDE5      		push	ix
 840    1756  C1        		pop	bc
 841    1757  21EEFF    		ld	hl,65518
 842    175A  09        		add	hl,bc
 843    175B  E5        		push	hl
 844    175C  DDE5      		push	ix
 845    175E  C1        		pop	bc
 846    175F  21F2FF    		ld	hl,65522
 847    1762  09        		add	hl,bc
 848    1763  CD0000    		call	c.0mvf
 849    1766  210000    		ld	hl,c.r0
 850    1769  E5        		push	hl
 851    176A  210900    		ld	hl,9
 852    176D  E5        		push	hl
 853    176E  CD0000    		call	c.llsh
 854    1771  CD0000    		call	c.mvl
 855    1774  F1        		pop	af
 856                    	;  544          printf("Device capacity: %lu MByte\n", capacity >> 10);
 857    1775  DDE5      		push	ix
 858    1777  C1        		pop	bc
 859    1778  21EEFF    		ld	hl,65518
 860    177B  09        		add	hl,bc
 861    177C  CD0000    		call	c.0mvf
 862    177F  210000    		ld	hl,c.r0
 863    1782  E5        		push	hl
 864    1783  210A00    		ld	hl,10
 865    1786  E5        		push	hl
 866    1787  CD0000    		call	c.ulrsh
 867    178A  E1        		pop	hl
 868    178B  23        		inc	hl
 869    178C  23        		inc	hl
 870    178D  4E        		ld	c,(hl)
 871    178E  23        		inc	hl
 872    178F  46        		ld	b,(hl)
 873    1790  C5        		push	bc
 874    1791  2B        		dec	hl
 875    1792  2B        		dec	hl
 876    1793  2B        		dec	hl
 877    1794  4E        		ld	c,(hl)
 878    1795  23        		inc	hl
 879    1796  46        		ld	b,(hl)
 880    1797  C5        		push	bc
 881    1798  21ED0F    		ld	hl,L536
 882    179B  CD0000    		call	_printf
 883    179E  F1        		pop	af
 884    179F  F1        		pop	af
 885                    	L1202:
 886                    	;  545          }
 887                    	;  546      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
 888    17A0  3A0E00    		ld	a,(_csdreg)
 889    17A3  6F        		ld	l,a
 890    17A4  97        		sub	a
 891    17A5  67        		ld	h,a
 892    17A6  7D        		ld	a,l
 893    17A7  E6C0      		and	192
 894    17A9  6F        		ld	l,a
 895    17AA  97        		sub	a
 896    17AB  67        		ld	h,a
 897    17AC  7D        		ld	a,l
 898    17AD  FE80      		cp	128
 899    17AF  2003      		jr	nz,L46
 900    17B1  7C        		ld	a,h
 901    17B2  FE00      		cp	0
 902                    	L46:
 903    17B4  C28718    		jp	nz,L1302
 904                    	;  547          {
 905                    	;  548          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
 906                    	;  549                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 907    17B7  DDE5      		push	ix
 908    17B9  C1        		pop	bc
 909    17BA  21F2FF    		ld	hl,65522
 910    17BD  09        		add	hl,bc
 911    17BE  E5        		push	hl
 912    17BF  97        		sub	a
 913    17C0  320000    		ld	(c.r0),a
 914    17C3  320100    		ld	(c.r0+1),a
 915    17C6  3A1600    		ld	a,(_csdreg+8)
 916    17C9  320200    		ld	(c.r0+2),a
 917    17CC  97        		sub	a
 918    17CD  320300    		ld	(c.r0+3),a
 919    17D0  210000    		ld	hl,c.r0
 920    17D3  E5        		push	hl
 921    17D4  210800    		ld	hl,8
 922    17D7  E5        		push	hl
 923    17D8  CD0000    		call	c.llsh
 924    17DB  97        		sub	a
 925    17DC  320000    		ld	(c.r1),a
 926    17DF  320100    		ld	(c.r1+1),a
 927    17E2  3A1700    		ld	a,(_csdreg+9)
 928    17E5  320200    		ld	(c.r1+2),a
 929    17E8  97        		sub	a
 930    17E9  320300    		ld	(c.r1+3),a
 931    17EC  210000    		ld	hl,c.r1
 932    17EF  E5        		push	hl
 933    17F0  CD0000    		call	c.ladd
 934    17F3  3A1500    		ld	a,(_csdreg+7)
 935    17F6  6F        		ld	l,a
 936    17F7  97        		sub	a
 937    17F8  67        		ld	h,a
 938    17F9  7D        		ld	a,l
 939    17FA  E63F      		and	63
 940    17FC  6F        		ld	l,a
 941    17FD  97        		sub	a
 942    17FE  67        		ld	h,a
 943    17FF  4D        		ld	c,l
 944    1800  44        		ld	b,h
 945    1801  78        		ld	a,b
 946    1802  87        		add	a,a
 947    1803  9F        		sbc	a,a
 948    1804  320000    		ld	(c.r1),a
 949    1807  320100    		ld	(c.r1+1),a
 950    180A  78        		ld	a,b
 951    180B  320300    		ld	(c.r1+3),a
 952    180E  79        		ld	a,c
 953    180F  320200    		ld	(c.r1+2),a
 954    1812  210000    		ld	hl,c.r1
 955    1815  E5        		push	hl
 956    1816  211000    		ld	hl,16
 957    1819  E5        		push	hl
 958    181A  CD0000    		call	c.llsh
 959    181D  CD0000    		call	c.ladd
 960    1820  3E01      		ld	a,1
 961    1822  320200    		ld	(c.r1+2),a
 962    1825  87        		add	a,a
 963    1826  9F        		sbc	a,a
 964    1827  320300    		ld	(c.r1+3),a
 965    182A  320100    		ld	(c.r1+1),a
 966    182D  320000    		ld	(c.r1),a
 967    1830  210000    		ld	hl,c.r1
 968    1833  E5        		push	hl
 969    1834  CD0000    		call	c.ladd
 970    1837  CD0000    		call	c.mvl
 971    183A  F1        		pop	af
 972                    	;  550          capacity = devsize << 9;
 973    183B  DDE5      		push	ix
 974    183D  C1        		pop	bc
 975    183E  21EEFF    		ld	hl,65518
 976    1841  09        		add	hl,bc
 977    1842  E5        		push	hl
 978    1843  DDE5      		push	ix
 979    1845  C1        		pop	bc
 980    1846  21F2FF    		ld	hl,65522
 981    1849  09        		add	hl,bc
 982    184A  CD0000    		call	c.0mvf
 983    184D  210000    		ld	hl,c.r0
 984    1850  E5        		push	hl
 985    1851  210900    		ld	hl,9
 986    1854  E5        		push	hl
 987    1855  CD0000    		call	c.llsh
 988    1858  CD0000    		call	c.mvl
 989    185B  F1        		pop	af
 990                    	;  551          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
 991    185C  DDE5      		push	ix
 992    185E  C1        		pop	bc
 993    185F  21EEFF    		ld	hl,65518
 994    1862  09        		add	hl,bc
 995    1863  CD0000    		call	c.0mvf
 996    1866  210000    		ld	hl,c.r0
 997    1869  E5        		push	hl
 998    186A  210A00    		ld	hl,10
 999    186D  E5        		push	hl
1000    186E  CD0000    		call	c.ulrsh
1001    1871  E1        		pop	hl
1002    1872  23        		inc	hl
1003    1873  23        		inc	hl
1004    1874  4E        		ld	c,(hl)
1005    1875  23        		inc	hl
1006    1876  46        		ld	b,(hl)
1007    1877  C5        		push	bc
1008    1878  2B        		dec	hl
1009    1879  2B        		dec	hl
1010    187A  2B        		dec	hl
1011    187B  4E        		ld	c,(hl)
1012    187C  23        		inc	hl
1013    187D  46        		ld	b,(hl)
1014    187E  C5        		push	bc
1015    187F  210910    		ld	hl,L546
1016    1882  CD0000    		call	_printf
1017    1885  F1        		pop	af
1018    1886  F1        		pop	af
1019                    	L1302:
1020                    	;  552          }
1021                    	;  553  
1022                    	;  554  #ifdef SDTEST
1023                    	;  555  
1024                    	;  556      printf("--------------------------------------\n");
1025    1887  212B10    		ld	hl,L556
1026    188A  CD0000    		call	_printf
1027                    	;  557      printf("OCR register:\n");
1028    188D  215310    		ld	hl,L566
1029    1890  CD0000    		call	_printf
1030                    	;  558      if (ocrreg[2] & 0x80)
1031    1893  3A3000    		ld	a,(_ocrreg+2)
1032    1896  CB7F      		bit	7,a
1033    1898  6F        		ld	l,a
1034    1899  2806      		jr	z,L1402
1035                    	;  559          printf("2.7-2.8V (bit 15) ");
1036    189B  216210    		ld	hl,L576
1037    189E  CD0000    		call	_printf
1038                    	L1402:
1039                    	;  560      if (ocrreg[1] & 0x01)
1040    18A1  3A2F00    		ld	a,(_ocrreg+1)
1041    18A4  CB47      		bit	0,a
1042    18A6  6F        		ld	l,a
1043    18A7  2806      		jr	z,L1502
1044                    	;  561          printf("2.8-2.9V (bit 16) ");
1045    18A9  217510    		ld	hl,L507
1046    18AC  CD0000    		call	_printf
1047                    	L1502:
1048                    	;  562      if (ocrreg[1] & 0x02)
1049    18AF  3A2F00    		ld	a,(_ocrreg+1)
1050    18B2  CB4F      		bit	1,a
1051    18B4  6F        		ld	l,a
1052    18B5  2806      		jr	z,L1602
1053                    	;  563          printf("2.9-3.0V (bit 17) ");
1054    18B7  218810    		ld	hl,L517
1055    18BA  CD0000    		call	_printf
1056                    	L1602:
1057                    	;  564      if (ocrreg[1] & 0x04)
1058    18BD  3A2F00    		ld	a,(_ocrreg+1)
1059    18C0  CB57      		bit	2,a
1060    18C2  6F        		ld	l,a
1061    18C3  2806      		jr	z,L1702
1062                    	;  565          printf("3.0-3.1V (bit 18) \n");
1063    18C5  219B10    		ld	hl,L527
1064    18C8  CD0000    		call	_printf
1065                    	L1702:
1066                    	;  566      if (ocrreg[1] & 0x08)
1067    18CB  3A2F00    		ld	a,(_ocrreg+1)
1068    18CE  CB5F      		bit	3,a
1069    18D0  6F        		ld	l,a
1070    18D1  2806      		jr	z,L1012
1071                    	;  567          printf("3.1-3.2V (bit 19) ");
1072    18D3  21AF10    		ld	hl,L537
1073    18D6  CD0000    		call	_printf
1074                    	L1012:
1075                    	;  568      if (ocrreg[1] & 0x10)
1076    18D9  3A2F00    		ld	a,(_ocrreg+1)
1077    18DC  CB67      		bit	4,a
1078    18DE  6F        		ld	l,a
1079    18DF  2806      		jr	z,L1112
1080                    	;  569          printf("3.2-3.3V (bit 20) ");
1081    18E1  21C210    		ld	hl,L547
1082    18E4  CD0000    		call	_printf
1083                    	L1112:
1084                    	;  570      if (ocrreg[1] & 0x20)
1085    18E7  3A2F00    		ld	a,(_ocrreg+1)
1086    18EA  CB6F      		bit	5,a
1087    18EC  6F        		ld	l,a
1088    18ED  2806      		jr	z,L1212
1089                    	;  571          printf("3.3-3.4V (bit 21) ");
1090    18EF  21D510    		ld	hl,L557
1091    18F2  CD0000    		call	_printf
1092                    	L1212:
1093                    	;  572      if (ocrreg[1] & 0x40)
1094    18F5  3A2F00    		ld	a,(_ocrreg+1)
1095    18F8  CB77      		bit	6,a
1096    18FA  6F        		ld	l,a
1097    18FB  2806      		jr	z,L1312
1098                    	;  573          printf("3.4-3.5V (bit 22) \n");
1099    18FD  21E810    		ld	hl,L567
1100    1900  CD0000    		call	_printf
1101                    	L1312:
1102                    	;  574      if (ocrreg[1] & 0x80)
1103    1903  3A2F00    		ld	a,(_ocrreg+1)
1104    1906  CB7F      		bit	7,a
1105    1908  6F        		ld	l,a
1106    1909  2806      		jr	z,L1412
1107                    	;  575          printf("3.5-3.6V (bit 23) \n");
1108    190B  21FC10    		ld	hl,L577
1109    190E  CD0000    		call	_printf
1110                    	L1412:
1111                    	;  576      if (ocrreg[0] & 0x01)
1112    1911  3A2E00    		ld	a,(_ocrreg)
1113    1914  CB47      		bit	0,a
1114    1916  6F        		ld	l,a
1115    1917  2806      		jr	z,L1512
1116                    	;  577          printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
1117    1919  211011    		ld	hl,L5001
1118    191C  CD0000    		call	_printf
1119                    	L1512:
1120                    	;  578      if (ocrreg[0] & 0x08)
1121    191F  3A2E00    		ld	a,(_ocrreg)
1122    1922  CB5F      		bit	3,a
1123    1924  6F        		ld	l,a
1124    1925  2806      		jr	z,L1612
1125                    	;  579          printf("Over 2TB support Status (CO2T) (bit 27) set\n");
1126    1927  214011    		ld	hl,L5101
1127    192A  CD0000    		call	_printf
1128                    	L1612:
1129                    	;  580      if (ocrreg[0] & 0x20)
1130    192D  3A2E00    		ld	a,(_ocrreg)
1131    1930  CB6F      		bit	5,a
1132    1932  6F        		ld	l,a
1133    1933  2806      		jr	z,L1712
1134                    	;  581          printf("UHS-II Card Status (bit 29) set ");
1135    1935  216D11    		ld	hl,L5201
1136    1938  CD0000    		call	_printf
1137                    	L1712:
1138                    	;  582      if (ocrreg[0] & 0x80)
1139    193B  3A2E00    		ld	a,(_ocrreg)
1140    193E  CB7F      		bit	7,a
1141    1940  6F        		ld	l,a
1142    1941  2839      		jr	z,L1022
1143                    	;  583          {
1144                    	;  584          if (ocrreg[0] & 0x40)
1145    1943  3A2E00    		ld	a,(_ocrreg)
1146    1946  CB77      		bit	6,a
1147    1948  6F        		ld	l,a
1148    1949  280E      		jr	z,L1122
1149                    	;  585              {
1150                    	;  586              printf("Card Capacity Status (CCS) (bit 30) set\n");
1151    194B  218E11    		ld	hl,L5301
1152    194E  CD0000    		call	_printf
1153                    	;  587              printf("  SD Ver.2+, Block address");
1154    1951  21B711    		ld	hl,L5401
1155    1954  CD0000    		call	_printf
1156                    	;  588              }
1157                    	;  589          else
1158    1957  181B      		jr	L1222
1159                    	L1122:
1160                    	;  590              {
1161                    	;  591              printf("Card Capacity Status (CCS) (bit 30) not set\n");
1162    1959  21D211    		ld	hl,L5501
1163    195C  CD0000    		call	_printf
1164                    	;  592              if (sdver2)
1165    195F  2A0800    		ld	hl,(_sdver2)
1166    1962  7C        		ld	a,h
1167    1963  B5        		or	l
1168    1964  2808      		jr	z,L1322
1169                    	;  593                  printf("  SD Ver.2+, Byte address");
1170    1966  21FF11    		ld	hl,L5601
1171    1969  CD0000    		call	_printf
1172                    	;  594              else
1173    196C  1806      		jr	L1222
1174                    	L1322:
1175                    	;  595                  printf("  SD Ver.1, Byte address");
1176    196E  211912    		ld	hl,L5701
1177    1971  CD0000    		call	_printf
1178                    	L1222:
1179                    	;  596              }
1180                    	;  597          printf("\nCard power up status bit (busy) (bit 31) set\n");
1181    1974  213212    		ld	hl,L5011
1182    1977  CD0000    		call	_printf
1183                    	;  598          }
1184                    	;  599      else
1185    197A  180C      		jr	L1522
1186                    	L1022:
1187                    	;  600          {
1188                    	;  601          printf("\nCard power up status bit (busy) (bit 31) not set.\n");
1189    197C  216112    		ld	hl,L5111
1190    197F  CD0000    		call	_printf
1191                    	;  602          printf("  This bit is not set if the card has not finished the power up routine.\n");
1192    1982  219512    		ld	hl,L5211
1193    1985  CD0000    		call	_printf
1194                    	L1522:
1195                    	;  603          }
1196                    	;  604      printf("--------------------------------------\n");
1197    1988  21DF12    		ld	hl,L5311
1198    198B  CD0000    		call	_printf
1199                    	;  605      printf("CID register:\n");
1200    198E  210713    		ld	hl,L5411
1201    1991  CD0000    		call	_printf
1202                    	;  606      printf("MID: 0x%02x, ", cidreg[0]);
1203    1994  3A1E00    		ld	a,(_cidreg)
1204    1997  4F        		ld	c,a
1205    1998  97        		sub	a
1206    1999  47        		ld	b,a
1207    199A  C5        		push	bc
1208    199B  211613    		ld	hl,L5511
1209    199E  CD0000    		call	_printf
1210    19A1  F1        		pop	af
1211                    	;  607      printf("OID: %.2s, ", &cidreg[1]);
1212    19A2  211F00    		ld	hl,_cidreg+1
1213    19A5  E5        		push	hl
1214    19A6  212413    		ld	hl,L5611
1215    19A9  CD0000    		call	_printf
1216    19AC  F1        		pop	af
1217                    	;  608      printf("PNM: %.5s, ", &cidreg[3]);
1218    19AD  212100    		ld	hl,_cidreg+3
1219    19B0  E5        		push	hl
1220    19B1  213013    		ld	hl,L5711
1221    19B4  CD0000    		call	_printf
1222    19B7  F1        		pop	af
1223                    	;  609      printf("PRV: %d.%d, ",
1224                    	;  610             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
1225    19B8  3A2600    		ld	a,(_cidreg+8)
1226    19BB  6F        		ld	l,a
1227    19BC  97        		sub	a
1228    19BD  67        		ld	h,a
1229    19BE  7D        		ld	a,l
1230    19BF  E60F      		and	15
1231    19C1  6F        		ld	l,a
1232    19C2  97        		sub	a
1233    19C3  67        		ld	h,a
1234    19C4  E5        		push	hl
1235    19C5  3A2600    		ld	a,(_cidreg+8)
1236    19C8  4F        		ld	c,a
1237    19C9  97        		sub	a
1238    19CA  47        		ld	b,a
1239    19CB  C5        		push	bc
1240    19CC  210400    		ld	hl,4
1241    19CF  E5        		push	hl
1242    19D0  CD0000    		call	c.irsh
1243    19D3  E1        		pop	hl
1244    19D4  7D        		ld	a,l
1245    19D5  E60F      		and	15
1246    19D7  6F        		ld	l,a
1247    19D8  97        		sub	a
1248    19D9  67        		ld	h,a
1249    19DA  E5        		push	hl
1250    19DB  213C13    		ld	hl,L5021
1251    19DE  CD0000    		call	_printf
1252    19E1  F1        		pop	af
1253    19E2  F1        		pop	af
1254                    	;  611      printf("PSN: %lu, ",
1255                    	;  612             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
1256    19E3  3A2700    		ld	a,(_cidreg+9)
1257    19E6  4F        		ld	c,a
1258    19E7  97        		sub	a
1259    19E8  47        		ld	b,a
1260    19E9  C5        		push	bc
1261    19EA  211800    		ld	hl,24
1262    19ED  E5        		push	hl
1263    19EE  CD0000    		call	c.ilsh
1264    19F1  E1        		pop	hl
1265    19F2  E5        		push	hl
1266    19F3  3A2800    		ld	a,(_cidreg+10)
1267    19F6  4F        		ld	c,a
1268    19F7  97        		sub	a
1269    19F8  47        		ld	b,a
1270    19F9  C5        		push	bc
1271    19FA  211000    		ld	hl,16
1272    19FD  E5        		push	hl
1273    19FE  CD0000    		call	c.ilsh
1274    1A01  E1        		pop	hl
1275    1A02  E3        		ex	(sp),hl
1276    1A03  C1        		pop	bc
1277    1A04  09        		add	hl,bc
1278    1A05  E5        		push	hl
1279    1A06  3A2900    		ld	a,(_cidreg+11)
1280    1A09  6F        		ld	l,a
1281    1A0A  97        		sub	a
1282    1A0B  67        		ld	h,a
1283    1A0C  29        		add	hl,hl
1284    1A0D  29        		add	hl,hl
1285    1A0E  29        		add	hl,hl
1286    1A0F  29        		add	hl,hl
1287    1A10  29        		add	hl,hl
1288    1A11  29        		add	hl,hl
1289    1A12  29        		add	hl,hl
1290    1A13  29        		add	hl,hl
1291    1A14  E3        		ex	(sp),hl
1292    1A15  C1        		pop	bc
1293    1A16  09        		add	hl,bc
1294    1A17  E5        		push	hl
1295    1A18  3A2A00    		ld	a,(_cidreg+12)
1296    1A1B  6F        		ld	l,a
1297    1A1C  97        		sub	a
1298    1A1D  67        		ld	h,a
1299    1A1E  E3        		ex	(sp),hl
1300    1A1F  C1        		pop	bc
1301    1A20  09        		add	hl,bc
1302    1A21  E5        		push	hl
1303    1A22  214913    		ld	hl,L5121
1304    1A25  CD0000    		call	_printf
1305    1A28  F1        		pop	af
1306                    	;  613      printf("MDT: %d-%d\n",
1307                    	;  614             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
1308    1A29  3A2C00    		ld	a,(_cidreg+14)
1309    1A2C  6F        		ld	l,a
1310    1A2D  97        		sub	a
1311    1A2E  67        		ld	h,a
1312    1A2F  7D        		ld	a,l
1313    1A30  E60F      		and	15
1314    1A32  6F        		ld	l,a
1315    1A33  97        		sub	a
1316    1A34  67        		ld	h,a
1317    1A35  E5        		push	hl
1318    1A36  3A2B00    		ld	a,(_cidreg+13)
1319    1A39  6F        		ld	l,a
1320    1A3A  97        		sub	a
1321    1A3B  67        		ld	h,a
1322    1A3C  7D        		ld	a,l
1323    1A3D  E60F      		and	15
1324    1A3F  6F        		ld	l,a
1325    1A40  97        		sub	a
1326    1A41  67        		ld	h,a
1327    1A42  29        		add	hl,hl
1328    1A43  29        		add	hl,hl
1329    1A44  29        		add	hl,hl
1330    1A45  29        		add	hl,hl
1331    1A46  01D007    		ld	bc,2000
1332    1A49  09        		add	hl,bc
1333    1A4A  E5        		push	hl
1334    1A4B  3A2C00    		ld	a,(_cidreg+14)
1335    1A4E  4F        		ld	c,a
1336    1A4F  97        		sub	a
1337    1A50  47        		ld	b,a
1338    1A51  C5        		push	bc
1339    1A52  210400    		ld	hl,4
1340    1A55  E5        		push	hl
1341    1A56  CD0000    		call	c.irsh
1342    1A59  E1        		pop	hl
1343    1A5A  E3        		ex	(sp),hl
1344    1A5B  C1        		pop	bc
1345    1A5C  09        		add	hl,bc
1346    1A5D  E5        		push	hl
1347    1A5E  215413    		ld	hl,L5221
1348    1A61  CD0000    		call	_printf
1349    1A64  F1        		pop	af
1350    1A65  F1        		pop	af
1351                    	;  615      printf("--------------------------------------\n");
1352    1A66  216013    		ld	hl,L5321
1353    1A69  CD0000    		call	_printf
1354                    	;  616      printf("CSD register:\n");
1355    1A6C  218813    		ld	hl,L5421
1356    1A6F  CD0000    		call	_printf
1357                    	;  617      if ((csdreg[0] & 0xc0) == 0x00)
1358    1A72  3A0E00    		ld	a,(_csdreg)
1359    1A75  E6C0      		and	192
1360    1A77  C26B1B    		jp	nz,L1622
1361                    	;  618          {
1362                    	;  619          printf("CSD Version 1.0, Standard Capacity\n");
1363    1A7A  219713    		ld	hl,L5521
1364    1A7D  CD0000    		call	_printf
1365                    	;  620          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
1366    1A80  3A1300    		ld	a,(_csdreg+5)
1367    1A83  6F        		ld	l,a
1368    1A84  97        		sub	a
1369    1A85  67        		ld	h,a
1370    1A86  7D        		ld	a,l
1371    1A87  E60F      		and	15
1372    1A89  6F        		ld	l,a
1373    1A8A  97        		sub	a
1374    1A8B  67        		ld	h,a
1375    1A8C  E5        		push	hl
1376    1A8D  3A1800    		ld	a,(_csdreg+10)
1377    1A90  6F        		ld	l,a
1378    1A91  97        		sub	a
1379    1A92  67        		ld	h,a
1380    1A93  7D        		ld	a,l
1381    1A94  E680      		and	128
1382    1A96  6F        		ld	l,a
1383    1A97  97        		sub	a
1384    1A98  67        		ld	h,a
1385    1A99  E5        		push	hl
1386    1A9A  210700    		ld	hl,7
1387    1A9D  E5        		push	hl
1388    1A9E  CD0000    		call	c.irsh
1389    1AA1  E1        		pop	hl
1390    1AA2  E3        		ex	(sp),hl
1391    1AA3  C1        		pop	bc
1392    1AA4  09        		add	hl,bc
1393    1AA5  E5        		push	hl
1394    1AA6  3A1700    		ld	a,(_csdreg+9)
1395    1AA9  6F        		ld	l,a
1396    1AAA  97        		sub	a
1397    1AAB  67        		ld	h,a
1398    1AAC  7D        		ld	a,l
1399    1AAD  E603      		and	3
1400    1AAF  6F        		ld	l,a
1401    1AB0  97        		sub	a
1402    1AB1  67        		ld	h,a
1403    1AB2  29        		add	hl,hl
1404    1AB3  E3        		ex	(sp),hl
1405    1AB4  C1        		pop	bc
1406    1AB5  09        		add	hl,bc
1407    1AB6  23        		inc	hl
1408    1AB7  23        		inc	hl
1409    1AB8  DD75F8    		ld	(ix-8),l
1410    1ABB  DD74F9    		ld	(ix-7),h
1411                    	;  621          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
1412                    	;  622                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
1413    1ABE  3A1600    		ld	a,(_csdreg+8)
1414    1AC1  4F        		ld	c,a
1415    1AC2  97        		sub	a
1416    1AC3  47        		ld	b,a
1417    1AC4  C5        		push	bc
1418    1AC5  210600    		ld	hl,6
1419    1AC8  E5        		push	hl
1420    1AC9  CD0000    		call	c.irsh
1421    1ACC  E1        		pop	hl
1422    1ACD  E5        		push	hl
1423    1ACE  3A1500    		ld	a,(_csdreg+7)
1424    1AD1  6F        		ld	l,a
1425    1AD2  97        		sub	a
1426    1AD3  67        		ld	h,a
1427    1AD4  29        		add	hl,hl
1428    1AD5  29        		add	hl,hl
1429    1AD6  E3        		ex	(sp),hl
1430    1AD7  C1        		pop	bc
1431    1AD8  09        		add	hl,bc
1432    1AD9  E5        		push	hl
1433    1ADA  3A1400    		ld	a,(_csdreg+6)
1434    1ADD  6F        		ld	l,a
1435    1ADE  97        		sub	a
1436    1ADF  67        		ld	h,a
1437    1AE0  7D        		ld	a,l
1438    1AE1  E603      		and	3
1439    1AE3  6F        		ld	l,a
1440    1AE4  97        		sub	a
1441    1AE5  67        		ld	h,a
1442    1AE6  E5        		push	hl
1443    1AE7  210A00    		ld	hl,10
1444    1AEA  E5        		push	hl
1445    1AEB  CD0000    		call	c.ilsh
1446    1AEE  E1        		pop	hl
1447    1AEF  E3        		ex	(sp),hl
1448    1AF0  C1        		pop	bc
1449    1AF1  09        		add	hl,bc
1450    1AF2  23        		inc	hl
1451    1AF3  DD75F6    		ld	(ix-10),l
1452    1AF6  DD74F7    		ld	(ix-9),h
1453                    	;  623          capacity = (unsigned long) csize << (n-10);
1454    1AF9  DDE5      		push	ix
1455    1AFB  C1        		pop	bc
1456    1AFC  21EEFF    		ld	hl,65518
1457    1AFF  09        		add	hl,bc
1458    1B00  E5        		push	hl
1459    1B01  DDE5      		push	ix
1460    1B03  C1        		pop	bc
1461    1B04  21F6FF    		ld	hl,65526
1462    1B07  09        		add	hl,bc
1463    1B08  4D        		ld	c,l
1464    1B09  44        		ld	b,h
1465    1B0A  97        		sub	a
1466    1B0B  320000    		ld	(c.r0),a
1467    1B0E  320100    		ld	(c.r0+1),a
1468    1B11  0A        		ld	a,(bc)
1469    1B12  320200    		ld	(c.r0+2),a
1470    1B15  03        		inc	bc
1471    1B16  0A        		ld	a,(bc)
1472    1B17  320300    		ld	(c.r0+3),a
1473    1B1A  210000    		ld	hl,c.r0
1474    1B1D  E5        		push	hl
1475    1B1E  DD6EF8    		ld	l,(ix-8)
1476    1B21  DD66F9    		ld	h,(ix-7)
1477    1B24  01F6FF    		ld	bc,65526
1478    1B27  09        		add	hl,bc
1479    1B28  E5        		push	hl
1480    1B29  CD0000    		call	c.llsh
1481    1B2C  CD0000    		call	c.mvl
1482    1B2F  F1        		pop	af
1483                    	;  624          printf(" Device capacity: %lu KByte, %lu MByte\n",
1484                    	;  625                 capacity, capacity >> 10);
1485    1B30  DDE5      		push	ix
1486    1B32  C1        		pop	bc
1487    1B33  21EEFF    		ld	hl,65518
1488    1B36  09        		add	hl,bc
1489    1B37  CD0000    		call	c.0mvf
1490    1B3A  210000    		ld	hl,c.r0
1491    1B3D  E5        		push	hl
1492    1B3E  210A00    		ld	hl,10
1493    1B41  E5        		push	hl
1494    1B42  CD0000    		call	c.ulrsh
1495    1B45  E1        		pop	hl
1496    1B46  23        		inc	hl
1497    1B47  23        		inc	hl
1498    1B48  4E        		ld	c,(hl)
1499    1B49  23        		inc	hl
1500    1B4A  46        		ld	b,(hl)
1501    1B4B  C5        		push	bc
1502    1B4C  2B        		dec	hl
1503    1B4D  2B        		dec	hl
1504    1B4E  2B        		dec	hl
1505    1B4F  4E        		ld	c,(hl)
1506    1B50  23        		inc	hl
1507    1B51  46        		ld	b,(hl)
1508    1B52  C5        		push	bc
1509    1B53  DD66F1    		ld	h,(ix-15)
1510    1B56  DD6EF0    		ld	l,(ix-16)
1511    1B59  E5        		push	hl
1512    1B5A  DD66EF    		ld	h,(ix-17)
1513    1B5D  DD6EEE    		ld	l,(ix-18)
1514    1B60  E5        		push	hl
1515    1B61  21BB13    		ld	hl,L5621
1516    1B64  CD0000    		call	_printf
1517    1B67  F1        		pop	af
1518    1B68  F1        		pop	af
1519    1B69  F1        		pop	af
1520    1B6A  F1        		pop	af
1521                    	L1622:
1522                    	;  626          }
1523                    	;  627      if ((csdreg[0] & 0xc0) == 0x40)
1524    1B6B  3A0E00    		ld	a,(_csdreg)
1525    1B6E  6F        		ld	l,a
1526    1B6F  97        		sub	a
1527    1B70  67        		ld	h,a
1528    1B71  7D        		ld	a,l
1529    1B72  E6C0      		and	192
1530    1B74  6F        		ld	l,a
1531    1B75  97        		sub	a
1532    1B76  67        		ld	h,a
1533    1B77  7D        		ld	a,l
1534    1B78  FE40      		cp	64
1535    1B7A  2003      		jr	nz,L66
1536    1B7C  7C        		ld	a,h
1537    1B7D  FE00      		cp	0
1538                    	L66:
1539    1B7F  C2681C    		jp	nz,L1722
1540                    	;  628          {
1541                    	;  629          printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
1542    1B82  21E313    		ld	hl,L5721
1543    1B85  CD0000    		call	_printf
1544                    	;  630          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
1545                    	;  631                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1546    1B88  DDE5      		push	ix
1547    1B8A  C1        		pop	bc
1548    1B8B  21F2FF    		ld	hl,65522
1549    1B8E  09        		add	hl,bc
1550    1B8F  E5        		push	hl
1551    1B90  97        		sub	a
1552    1B91  320000    		ld	(c.r0),a
1553    1B94  320100    		ld	(c.r0+1),a
1554    1B97  3A1600    		ld	a,(_csdreg+8)
1555    1B9A  320200    		ld	(c.r0+2),a
1556    1B9D  97        		sub	a
1557    1B9E  320300    		ld	(c.r0+3),a
1558    1BA1  210000    		ld	hl,c.r0
1559    1BA4  E5        		push	hl
1560    1BA5  210800    		ld	hl,8
1561    1BA8  E5        		push	hl
1562    1BA9  CD0000    		call	c.llsh
1563    1BAC  97        		sub	a
1564    1BAD  320000    		ld	(c.r1),a
1565    1BB0  320100    		ld	(c.r1+1),a
1566    1BB3  3A1700    		ld	a,(_csdreg+9)
1567    1BB6  320200    		ld	(c.r1+2),a
1568    1BB9  97        		sub	a
1569    1BBA  320300    		ld	(c.r1+3),a
1570    1BBD  210000    		ld	hl,c.r1
1571    1BC0  E5        		push	hl
1572    1BC1  CD0000    		call	c.ladd
1573    1BC4  3A1500    		ld	a,(_csdreg+7)
1574    1BC7  6F        		ld	l,a
1575    1BC8  97        		sub	a
1576    1BC9  67        		ld	h,a
1577    1BCA  7D        		ld	a,l
1578    1BCB  E63F      		and	63
1579    1BCD  6F        		ld	l,a
1580    1BCE  97        		sub	a
1581    1BCF  67        		ld	h,a
1582    1BD0  4D        		ld	c,l
1583    1BD1  44        		ld	b,h
1584    1BD2  78        		ld	a,b
1585    1BD3  87        		add	a,a
1586    1BD4  9F        		sbc	a,a
1587    1BD5  320000    		ld	(c.r1),a
1588    1BD8  320100    		ld	(c.r1+1),a
1589    1BDB  78        		ld	a,b
1590    1BDC  320300    		ld	(c.r1+3),a
1591    1BDF  79        		ld	a,c
1592    1BE0  320200    		ld	(c.r1+2),a
1593    1BE3  210000    		ld	hl,c.r1
1594    1BE6  E5        		push	hl
1595    1BE7  211000    		ld	hl,16
1596    1BEA  E5        		push	hl
1597    1BEB  CD0000    		call	c.llsh
1598    1BEE  CD0000    		call	c.ladd
1599    1BF1  3E01      		ld	a,1
1600    1BF3  320200    		ld	(c.r1+2),a
1601    1BF6  87        		add	a,a
1602    1BF7  9F        		sbc	a,a
1603    1BF8  320300    		ld	(c.r1+3),a
1604    1BFB  320100    		ld	(c.r1+1),a
1605    1BFE  320000    		ld	(c.r1),a
1606    1C01  210000    		ld	hl,c.r1
1607    1C04  E5        		push	hl
1608    1C05  CD0000    		call	c.ladd
1609    1C08  CD0000    		call	c.mvl
1610    1C0B  F1        		pop	af
1611                    	;  632          capacity = devsize << 9;
1612    1C0C  DDE5      		push	ix
1613    1C0E  C1        		pop	bc
1614    1C0F  21EEFF    		ld	hl,65518
1615    1C12  09        		add	hl,bc
1616    1C13  E5        		push	hl
1617    1C14  DDE5      		push	ix
1618    1C16  C1        		pop	bc
1619    1C17  21F2FF    		ld	hl,65522
1620    1C1A  09        		add	hl,bc
1621    1C1B  CD0000    		call	c.0mvf
1622    1C1E  210000    		ld	hl,c.r0
1623    1C21  E5        		push	hl
1624    1C22  210900    		ld	hl,9
1625    1C25  E5        		push	hl
1626    1C26  CD0000    		call	c.llsh
1627    1C29  CD0000    		call	c.mvl
1628    1C2C  F1        		pop	af
1629                    	;  633          printf(" Device capacity: %lu KByte, %lu MByte\n",
1630                    	;  634                 capacity, capacity >> 10);
1631    1C2D  DDE5      		push	ix
1632    1C2F  C1        		pop	bc
1633    1C30  21EEFF    		ld	hl,65518
1634    1C33  09        		add	hl,bc
1635    1C34  CD0000    		call	c.0mvf
1636    1C37  210000    		ld	hl,c.r0
1637    1C3A  E5        		push	hl
1638    1C3B  210A00    		ld	hl,10
1639    1C3E  E5        		push	hl
1640    1C3F  CD0000    		call	c.ulrsh
1641    1C42  E1        		pop	hl
1642    1C43  23        		inc	hl
1643    1C44  23        		inc	hl
1644    1C45  4E        		ld	c,(hl)
1645    1C46  23        		inc	hl
1646    1C47  46        		ld	b,(hl)
1647    1C48  C5        		push	bc
1648    1C49  2B        		dec	hl
1649    1C4A  2B        		dec	hl
1650    1C4B  2B        		dec	hl
1651    1C4C  4E        		ld	c,(hl)
1652    1C4D  23        		inc	hl
1653    1C4E  46        		ld	b,(hl)
1654    1C4F  C5        		push	bc
1655    1C50  DD66F1    		ld	h,(ix-15)
1656    1C53  DD6EF0    		ld	l,(ix-16)
1657    1C56  E5        		push	hl
1658    1C57  DD66EF    		ld	h,(ix-17)
1659    1C5A  DD6EEE    		ld	l,(ix-18)
1660    1C5D  E5        		push	hl
1661    1C5E  211914    		ld	hl,L5031
1662    1C61  CD0000    		call	_printf
1663    1C64  F1        		pop	af
1664    1C65  F1        		pop	af
1665    1C66  F1        		pop	af
1666    1C67  F1        		pop	af
1667                    	L1722:
1668                    	;  635          }
1669                    	;  636      if ((csdreg[0] & 0xc0) == 0x80)
1670    1C68  3A0E00    		ld	a,(_csdreg)
1671    1C6B  6F        		ld	l,a
1672    1C6C  97        		sub	a
1673    1C6D  67        		ld	h,a
1674    1C6E  7D        		ld	a,l
1675    1C6F  E6C0      		and	192
1676    1C71  6F        		ld	l,a
1677    1C72  97        		sub	a
1678    1C73  67        		ld	h,a
1679    1C74  7D        		ld	a,l
1680    1C75  FE80      		cp	128
1681    1C77  2003      		jr	nz,L07
1682    1C79  7C        		ld	a,h
1683    1C7A  FE00      		cp	0
1684                    	L07:
1685    1C7C  C2651D    		jp	nz,L1032
1686                    	;  637          {
1687                    	;  638          printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
1688    1C7F  214114    		ld	hl,L5131
1689    1C82  CD0000    		call	_printf
1690                    	;  639          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
1691                    	;  640                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1692    1C85  DDE5      		push	ix
1693    1C87  C1        		pop	bc
1694    1C88  21F2FF    		ld	hl,65522
1695    1C8B  09        		add	hl,bc
1696    1C8C  E5        		push	hl
1697    1C8D  97        		sub	a
1698    1C8E  320000    		ld	(c.r0),a
1699    1C91  320100    		ld	(c.r0+1),a
1700    1C94  3A1600    		ld	a,(_csdreg+8)
1701    1C97  320200    		ld	(c.r0+2),a
1702    1C9A  97        		sub	a
1703    1C9B  320300    		ld	(c.r0+3),a
1704    1C9E  210000    		ld	hl,c.r0
1705    1CA1  E5        		push	hl
1706    1CA2  210800    		ld	hl,8
1707    1CA5  E5        		push	hl
1708    1CA6  CD0000    		call	c.llsh
1709    1CA9  97        		sub	a
1710    1CAA  320000    		ld	(c.r1),a
1711    1CAD  320100    		ld	(c.r1+1),a
1712    1CB0  3A1700    		ld	a,(_csdreg+9)
1713    1CB3  320200    		ld	(c.r1+2),a
1714    1CB6  97        		sub	a
1715    1CB7  320300    		ld	(c.r1+3),a
1716    1CBA  210000    		ld	hl,c.r1
1717    1CBD  E5        		push	hl
1718    1CBE  CD0000    		call	c.ladd
1719    1CC1  3A1500    		ld	a,(_csdreg+7)
1720    1CC4  6F        		ld	l,a
1721    1CC5  97        		sub	a
1722    1CC6  67        		ld	h,a
1723    1CC7  7D        		ld	a,l
1724    1CC8  E63F      		and	63
1725    1CCA  6F        		ld	l,a
1726    1CCB  97        		sub	a
1727    1CCC  67        		ld	h,a
1728    1CCD  4D        		ld	c,l
1729    1CCE  44        		ld	b,h
1730    1CCF  78        		ld	a,b
1731    1CD0  87        		add	a,a
1732    1CD1  9F        		sbc	a,a
1733    1CD2  320000    		ld	(c.r1),a
1734    1CD5  320100    		ld	(c.r1+1),a
1735    1CD8  78        		ld	a,b
1736    1CD9  320300    		ld	(c.r1+3),a
1737    1CDC  79        		ld	a,c
1738    1CDD  320200    		ld	(c.r1+2),a
1739    1CE0  210000    		ld	hl,c.r1
1740    1CE3  E5        		push	hl
1741    1CE4  211000    		ld	hl,16
1742    1CE7  E5        		push	hl
1743    1CE8  CD0000    		call	c.llsh
1744    1CEB  CD0000    		call	c.ladd
1745    1CEE  3E01      		ld	a,1
1746    1CF0  320200    		ld	(c.r1+2),a
1747    1CF3  87        		add	a,a
1748    1CF4  9F        		sbc	a,a
1749    1CF5  320300    		ld	(c.r1+3),a
1750    1CF8  320100    		ld	(c.r1+1),a
1751    1CFB  320000    		ld	(c.r1),a
1752    1CFE  210000    		ld	hl,c.r1
1753    1D01  E5        		push	hl
1754    1D02  CD0000    		call	c.ladd
1755    1D05  CD0000    		call	c.mvl
1756    1D08  F1        		pop	af
1757                    	;  641          capacity = devsize << 9;
1758    1D09  DDE5      		push	ix
1759    1D0B  C1        		pop	bc
1760    1D0C  21EEFF    		ld	hl,65518
1761    1D0F  09        		add	hl,bc
1762    1D10  E5        		push	hl
1763    1D11  DDE5      		push	ix
1764    1D13  C1        		pop	bc
1765    1D14  21F2FF    		ld	hl,65522
1766    1D17  09        		add	hl,bc
1767    1D18  CD0000    		call	c.0mvf
1768    1D1B  210000    		ld	hl,c.r0
1769    1D1E  E5        		push	hl
1770    1D1F  210900    		ld	hl,9
1771    1D22  E5        		push	hl
1772    1D23  CD0000    		call	c.llsh
1773    1D26  CD0000    		call	c.mvl
1774    1D29  F1        		pop	af
1775                    	;  642          printf(" Device capacity: %lu KByte, %lu MByte\n",
1776                    	;  643                 capacity, capacity >> 10);
1777    1D2A  DDE5      		push	ix
1778    1D2C  C1        		pop	bc
1779    1D2D  21EEFF    		ld	hl,65518
1780    1D30  09        		add	hl,bc
1781    1D31  CD0000    		call	c.0mvf
1782    1D34  210000    		ld	hl,c.r0
1783    1D37  E5        		push	hl
1784    1D38  210A00    		ld	hl,10
1785    1D3B  E5        		push	hl
1786    1D3C  CD0000    		call	c.ulrsh
1787    1D3F  E1        		pop	hl
1788    1D40  23        		inc	hl
1789    1D41  23        		inc	hl
1790    1D42  4E        		ld	c,(hl)
1791    1D43  23        		inc	hl
1792    1D44  46        		ld	b,(hl)
1793    1D45  C5        		push	bc
1794    1D46  2B        		dec	hl
1795    1D47  2B        		dec	hl
1796    1D48  2B        		dec	hl
1797    1D49  4E        		ld	c,(hl)
1798    1D4A  23        		inc	hl
1799    1D4B  46        		ld	b,(hl)
1800    1D4C  C5        		push	bc
1801    1D4D  DD66F1    		ld	h,(ix-15)
1802    1D50  DD6EF0    		ld	l,(ix-16)
1803    1D53  E5        		push	hl
1804    1D54  DD66EF    		ld	h,(ix-17)
1805    1D57  DD6EEE    		ld	l,(ix-18)
1806    1D5A  E5        		push	hl
1807    1D5B  216914    		ld	hl,L5231
1808    1D5E  CD0000    		call	_printf
1809    1D61  F1        		pop	af
1810    1D62  F1        		pop	af
1811    1D63  F1        		pop	af
1812    1D64  F1        		pop	af
1813                    	L1032:
1814                    	;  644          }
1815                    	;  645      printf("--------------------------------------\n");
1816    1D65  219114    		ld	hl,L5331
1817    1D68  CD0000    		call	_printf
1818                    	;  646  
1819                    	;  647  #endif /* SDTEST */
1820                    	;  648  
1821                    	;  649      }
1822    1D6B  C30000    		jp	c.rets0
1823                    	L5431:
1824    1D6E  53        		.byte	83
1825    1D6F  44        		.byte	68
1826    1D70  20        		.byte	32
1827    1D71  63        		.byte	99
1828    1D72  61        		.byte	97
1829    1D73  72        		.byte	114
1830    1D74  64        		.byte	100
1831    1D75  20        		.byte	32
1832    1D76  6E        		.byte	110
1833    1D77  6F        		.byte	111
1834    1D78  74        		.byte	116
1835    1D79  20        		.byte	32
1836    1D7A  69        		.byte	105
1837    1D7B  6E        		.byte	110
1838    1D7C  69        		.byte	105
1839    1D7D  74        		.byte	116
1840    1D7E  69        		.byte	105
1841    1D7F  61        		.byte	97
1842    1D80  6C        		.byte	108
1843    1D81  69        		.byte	105
1844    1D82  7A        		.byte	122
1845    1D83  65        		.byte	101
1846    1D84  64        		.byte	100
1847    1D85  0A        		.byte	10
1848    1D86  00        		.byte	0
1849                    	L5531:
1850    1D87  0A        		.byte	10
1851    1D88  43        		.byte	67
1852    1D89  4D        		.byte	77
1853    1D8A  44        		.byte	68
1854    1D8B  31        		.byte	49
1855    1D8C  37        		.byte	55
1856    1D8D  3A        		.byte	58
1857    1D8E  20        		.byte	32
1858    1D8F  52        		.byte	82
1859    1D90  45        		.byte	69
1860    1D91  41        		.byte	65
1861    1D92  44        		.byte	68
1862    1D93  5F        		.byte	95
1863    1D94  53        		.byte	83
1864    1D95  49        		.byte	73
1865    1D96  4E        		.byte	78
1866    1D97  47        		.byte	71
1867    1D98  4C        		.byte	76
1868    1D99  45        		.byte	69
1869    1D9A  5F        		.byte	95
1870    1D9B  42        		.byte	66
1871    1D9C  4C        		.byte	76
1872    1D9D  4F        		.byte	79
1873    1D9E  43        		.byte	67
1874    1D9F  4B        		.byte	75
1875    1DA0  2C        		.byte	44
1876    1DA1  20        		.byte	32
1877    1DA2  63        		.byte	99
1878    1DA3  6F        		.byte	111
1879    1DA4  6D        		.byte	109
1880    1DA5  6D        		.byte	109
1881    1DA6  61        		.byte	97
1882    1DA7  6E        		.byte	110
1883    1DA8  64        		.byte	100
1884    1DA9  20        		.byte	32
1885    1DAA  5B        		.byte	91
1886    1DAB  25        		.byte	37
1887    1DAC  30        		.byte	48
1888    1DAD  32        		.byte	50
1889    1DAE  78        		.byte	120
1890    1DAF  20        		.byte	32
1891    1DB0  25        		.byte	37
1892    1DB1  30        		.byte	48
1893    1DB2  32        		.byte	50
1894    1DB3  78        		.byte	120
1895    1DB4  20        		.byte	32
1896    1DB5  25        		.byte	37
1897    1DB6  30        		.byte	48
1898    1DB7  32        		.byte	50
1899    1DB8  78        		.byte	120
1900    1DB9  20        		.byte	32
1901    1DBA  25        		.byte	37
1902    1DBB  30        		.byte	48
1903    1DBC  32        		.byte	50
1904    1DBD  78        		.byte	120
1905    1DBE  20        		.byte	32
1906    1DBF  25        		.byte	37
1907    1DC0  30        		.byte	48
1908    1DC1  32        		.byte	50
1909    1DC2  78        		.byte	120
1910    1DC3  5D        		.byte	93
1911    1DC4  0A        		.byte	10
1912    1DC5  00        		.byte	0
1913                    	L5631:
1914    1DC6  43        		.byte	67
1915    1DC7  4D        		.byte	77
1916    1DC8  44        		.byte	68
1917    1DC9  31        		.byte	49
1918    1DCA  37        		.byte	55
1919    1DCB  20        		.byte	32
1920    1DCC  52        		.byte	82
1921    1DCD  31        		.byte	49
1922    1DCE  20        		.byte	32
1923    1DCF  72        		.byte	114
1924    1DD0  65        		.byte	101
1925    1DD1  73        		.byte	115
1926    1DD2  70        		.byte	112
1927    1DD3  6F        		.byte	111
1928    1DD4  6E        		.byte	110
1929    1DD5  73        		.byte	115
1930    1DD6  65        		.byte	101
1931    1DD7  20        		.byte	32
1932    1DD8  5B        		.byte	91
1933    1DD9  25        		.byte	37
1934    1DDA  30        		.byte	48
1935    1DDB  32        		.byte	50
1936    1DDC  78        		.byte	120
1937    1DDD  5D        		.byte	93
1938    1DDE  0A        		.byte	10
1939    1DDF  00        		.byte	0
1940                    	L5731:
1941    1DE0  20        		.byte	32
1942    1DE1  20        		.byte	32
1943    1DE2  63        		.byte	99
1944    1DE3  6F        		.byte	111
1945    1DE4  75        		.byte	117
1946    1DE5  6C        		.byte	108
1947    1DE6  64        		.byte	100
1948    1DE7  20        		.byte	32
1949    1DE8  6E        		.byte	110
1950    1DE9  6F        		.byte	111
1951    1DEA  74        		.byte	116
1952    1DEB  20        		.byte	32
1953    1DEC  72        		.byte	114
1954    1DED  65        		.byte	101
1955    1DEE  61        		.byte	97
1956    1DEF  64        		.byte	100
1957    1DF0  20        		.byte	32
1958    1DF1  62        		.byte	98
1959    1DF2  6C        		.byte	108
1960    1DF3  6F        		.byte	111
1961    1DF4  63        		.byte	99
1962    1DF5  6B        		.byte	107
1963    1DF6  0A        		.byte	10
1964    1DF7  00        		.byte	0
1965                    	L5041:
1966    1DF8  20        		.byte	32
1967    1DF9  20        		.byte	32
1968    1DFA  72        		.byte	114
1969    1DFB  65        		.byte	101
1970    1DFC  61        		.byte	97
1971    1DFD  64        		.byte	100
1972    1DFE  20        		.byte	32
1973    1DFF  65        		.byte	101
1974    1E00  72        		.byte	114
1975    1E01  72        		.byte	114
1976    1E02  6F        		.byte	111
1977    1E03  72        		.byte	114
1978    1E04  3A        		.byte	58
1979    1E05  20        		.byte	32
1980    1E06  5B        		.byte	91
1981    1E07  25        		.byte	37
1982    1E08  30        		.byte	48
1983    1E09  32        		.byte	50
1984    1E0A  78        		.byte	120
1985    1E0B  5D        		.byte	93
1986    1E0C  0A        		.byte	10
1987    1E0D  00        		.byte	0
1988                    	L5141:
1989    1E0E  20        		.byte	32
1990    1E0F  20        		.byte	32
1991    1E10  6E        		.byte	110
1992    1E11  6F        		.byte	111
1993    1E12  20        		.byte	32
1994    1E13  64        		.byte	100
1995    1E14  61        		.byte	97
1996    1E15  74        		.byte	116
1997    1E16  61        		.byte	97
1998    1E17  20        		.byte	32
1999    1E18  66        		.byte	102
2000    1E19  6F        		.byte	111
2001    1E1A  75        		.byte	117
2002    1E1B  6E        		.byte	110
2003    1E1C  64        		.byte	100
2004    1E1D  0A        		.byte	10
2005    1E1E  00        		.byte	0
2006                    	L5241:
2007    1E1F  20        		.byte	32
2008    1E20  20        		.byte	32
2009    1E21  72        		.byte	114
2010    1E22  65        		.byte	101
2011    1E23  61        		.byte	97
2012    1E24  64        		.byte	100
2013    1E25  20        		.byte	32
2014    1E26  64        		.byte	100
2015    1E27  61        		.byte	97
2016    1E28  74        		.byte	116
2017    1E29  61        		.byte	97
2018    1E2A  20        		.byte	32
2019    1E2B  62        		.byte	98
2020    1E2C  6C        		.byte	108
2021    1E2D  6F        		.byte	111
2022    1E2E  63        		.byte	99
2023    1E2F  6B        		.byte	107
2024    1E30  20        		.byte	32
2025    1E31  25        		.byte	37
2026    1E32  6C        		.byte	108
2027    1E33  64        		.byte	100
2028    1E34  3A        		.byte	58
2029    1E35  0A        		.byte	10
2030    1E36  00        		.byte	0
2031                    	L5341:
2032    1E37  20        		.byte	32
2033    1E38  20        		.byte	32
2034    1E39  43        		.byte	67
2035    1E3A  52        		.byte	82
2036    1E3B  43        		.byte	67
2037    1E3C  31        		.byte	49
2038    1E3D  36        		.byte	54
2039    1E3E  20        		.byte	32
2040    1E3F  65        		.byte	101
2041    1E40  72        		.byte	114
2042    1E41  72        		.byte	114
2043    1E42  6F        		.byte	111
2044    1E43  72        		.byte	114
2045    1E44  2C        		.byte	44
2046    1E45  20        		.byte	32
2047    1E46  72        		.byte	114
2048    1E47  65        		.byte	101
2049    1E48  63        		.byte	99
2050    1E49  69        		.byte	105
2051    1E4A  65        		.byte	101
2052    1E4B  76        		.byte	118
2053    1E4C  65        		.byte	101
2054    1E4D  64        		.byte	100
2055    1E4E  3A        		.byte	58
2056    1E4F  20        		.byte	32
2057    1E50  30        		.byte	48
2058    1E51  78        		.byte	120
2059    1E52  25        		.byte	37
2060    1E53  30        		.byte	48
2061    1E54  34        		.byte	52
2062    1E55  78        		.byte	120
2063    1E56  2C        		.byte	44
2064    1E57  20        		.byte	32
2065    1E58  63        		.byte	99
2066    1E59  61        		.byte	97
2067    1E5A  6C        		.byte	108
2068    1E5B  63        		.byte	99
2069    1E5C  3A        		.byte	58
2070    1E5D  20        		.byte	32
2071    1E5E  30        		.byte	48
2072    1E5F  78        		.byte	120
2073    1E60  25        		.byte	37
2074    1E61  30        		.byte	48
2075    1E62  34        		.byte	52
2076    1E63  68        		.byte	104
2077    1E64  69        		.byte	105
2078    1E65  0A        		.byte	10
2079    1E66  00        		.byte	0
2080                    	;  650  
2081                    	;  651  /* Read data block of 512 bytes to buffer
2082                    	;  652   * Returns YES if ok or NO if error
2083                    	;  653   */
2084                    	;  654  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
2085                    	;  655      {
2086                    	_sdread:
2087    1E67  CD0000    		call	c.savs
2088    1E6A  21E0FF    		ld	hl,65504
2089    1E6D  39        		add	hl,sp
2090    1E6E  F9        		ld	sp,hl
2091                    	;  656      unsigned char *statptr;
2092                    	;  657      unsigned char rbyte;
2093                    	;  658      unsigned char cmdbuf[5];   /* buffer to build command in */
2094                    	;  659      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2095                    	;  660      int nbytes;
2096                    	;  661      int tries;
2097                    	;  662      unsigned long blktoread;
2098                    	;  663      unsigned int rxcrc16;
2099                    	;  664      unsigned int calcrc16;
2100                    	;  665  
2101                    	;  666      ledon();
2102    1E6F  CD0000    		call	_ledon
2103                    	;  667      spiselect();
2104    1E72  CD0000    		call	_spiselect
2105                    	;  668  
2106                    	;  669      if (!sdinitok)
2107    1E75  2A0A00    		ld	hl,(_sdinitok)
2108    1E78  7C        		ld	a,h
2109    1E79  B5        		or	l
2110    1E7A  2012      		jr	nz,L1132
2111                    	;  670          {
2112                    	;  671  #ifdef SDTEST
2113                    	;  672          printf("SD card not initialized\n");
2114    1E7C  216E1D    		ld	hl,L5431
2115    1E7F  CD0000    		call	_printf
2116                    	;  673  #endif
2117                    	;  674          spideselect();
2118    1E82  CD0000    		call	_spideselect
2119                    	;  675          ledoff();
2120    1E85  CD0000    		call	_ledoff
2121                    	;  676          return (NO);
2122    1E88  010000    		ld	bc,0
2123    1E8B  C30000    		jp	c.rets
2124                    	L1132:
2125                    	;  677          }
2126                    	;  678  
2127                    	;  679      /* CMD17: READ_SINGLE_BLOCK */
2128                    	;  680      /* Insert block # into command */
2129                    	;  681      memcpy(cmdbuf, cmd17, 5);
2130    1E8E  210500    		ld	hl,5
2131    1E91  E5        		push	hl
2132    1E92  213500    		ld	hl,_cmd17
2133    1E95  E5        		push	hl
2134    1E96  DDE5      		push	ix
2135    1E98  C1        		pop	bc
2136    1E99  21F2FF    		ld	hl,65522
2137    1E9C  09        		add	hl,bc
2138    1E9D  CD0000    		call	_memcpy
2139    1EA0  F1        		pop	af
2140    1EA1  F1        		pop	af
2141                    	;  682      blktoread = blkmult * rdblkno;
2142    1EA2  DDE5      		push	ix
2143    1EA4  C1        		pop	bc
2144    1EA5  21E4FF    		ld	hl,65508
2145    1EA8  09        		add	hl,bc
2146    1EA9  E5        		push	hl
2147    1EAA  210400    		ld	hl,_blkmult
2148    1EAD  CD0000    		call	c.0mvf
2149    1EB0  210000    		ld	hl,c.r0
2150    1EB3  E5        		push	hl
2151    1EB4  DDE5      		push	ix
2152    1EB6  C1        		pop	bc
2153    1EB7  210600    		ld	hl,6
2154    1EBA  09        		add	hl,bc
2155    1EBB  E5        		push	hl
2156    1EBC  CD0000    		call	c.lmul
2157    1EBF  CD0000    		call	c.mvl
2158    1EC2  F1        		pop	af
2159                    	;  683      cmdbuf[4] = blktoread & 0xff;
2160    1EC3  DD6EE6    		ld	l,(ix-26)
2161    1EC6  7D        		ld	a,l
2162    1EC7  E6FF      		and	255
2163    1EC9  DD77F6    		ld	(ix-10),a
2164                    	;  684      blktoread = blktoread >> 8;
2165    1ECC  DDE5      		push	ix
2166    1ECE  C1        		pop	bc
2167    1ECF  21E4FF    		ld	hl,65508
2168    1ED2  09        		add	hl,bc
2169    1ED3  E5        		push	hl
2170    1ED4  210800    		ld	hl,8
2171    1ED7  E5        		push	hl
2172    1ED8  CD0000    		call	c.ulrsh
2173    1EDB  F1        		pop	af
2174                    	;  685      cmdbuf[3] = blktoread & 0xff;
2175    1EDC  DD6EE6    		ld	l,(ix-26)
2176    1EDF  7D        		ld	a,l
2177    1EE0  E6FF      		and	255
2178    1EE2  DD77F5    		ld	(ix-11),a
2179                    	;  686      blktoread = blktoread >> 8;
2180    1EE5  DDE5      		push	ix
2181    1EE7  C1        		pop	bc
2182    1EE8  21E4FF    		ld	hl,65508
2183    1EEB  09        		add	hl,bc
2184    1EEC  E5        		push	hl
2185    1EED  210800    		ld	hl,8
2186    1EF0  E5        		push	hl
2187    1EF1  CD0000    		call	c.ulrsh
2188    1EF4  F1        		pop	af
2189                    	;  687      cmdbuf[2] = blktoread & 0xff;
2190    1EF5  DD6EE6    		ld	l,(ix-26)
2191    1EF8  7D        		ld	a,l
2192    1EF9  E6FF      		and	255
2193    1EFB  DD77F4    		ld	(ix-12),a
2194                    	;  688      blktoread = blktoread >> 8;
2195    1EFE  DDE5      		push	ix
2196    1F00  C1        		pop	bc
2197    1F01  21E4FF    		ld	hl,65508
2198    1F04  09        		add	hl,bc
2199    1F05  E5        		push	hl
2200    1F06  210800    		ld	hl,8
2201    1F09  E5        		push	hl
2202    1F0A  CD0000    		call	c.ulrsh
2203    1F0D  F1        		pop	af
2204                    	;  689      cmdbuf[1] = blktoread & 0xff;
2205    1F0E  DD6EE6    		ld	l,(ix-26)
2206    1F11  7D        		ld	a,l
2207    1F12  E6FF      		and	255
2208    1F14  DD77F3    		ld	(ix-13),a
2209                    	;  690  
2210                    	;  691  #ifdef SDTEST
2211                    	;  692      printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2212                    	;  693                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2213    1F17  DD4EF6    		ld	c,(ix-10)
2214    1F1A  97        		sub	a
2215    1F1B  47        		ld	b,a
2216    1F1C  C5        		push	bc
2217    1F1D  DD4EF5    		ld	c,(ix-11)
2218    1F20  97        		sub	a
2219    1F21  47        		ld	b,a
2220    1F22  C5        		push	bc
2221    1F23  DD4EF4    		ld	c,(ix-12)
2222    1F26  97        		sub	a
2223    1F27  47        		ld	b,a
2224    1F28  C5        		push	bc
2225    1F29  DD4EF3    		ld	c,(ix-13)
2226    1F2C  97        		sub	a
2227    1F2D  47        		ld	b,a
2228    1F2E  C5        		push	bc
2229    1F2F  DD4EF2    		ld	c,(ix-14)
2230    1F32  97        		sub	a
2231    1F33  47        		ld	b,a
2232    1F34  C5        		push	bc
2233    1F35  21871D    		ld	hl,L5531
2234    1F38  CD0000    		call	_printf
2235    1F3B  210A00    		ld	hl,10
2236    1F3E  39        		add	hl,sp
2237    1F3F  F9        		ld	sp,hl
2238                    	;  694  #endif
2239                    	;  695      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2240    1F40  210100    		ld	hl,1
2241    1F43  E5        		push	hl
2242    1F44  DDE5      		push	ix
2243    1F46  C1        		pop	bc
2244    1F47  21EDFF    		ld	hl,65517
2245    1F4A  09        		add	hl,bc
2246    1F4B  E5        		push	hl
2247    1F4C  DDE5      		push	ix
2248    1F4E  C1        		pop	bc
2249    1F4F  21F2FF    		ld	hl,65522
2250    1F52  09        		add	hl,bc
2251    1F53  CD6301    		call	_sdcommand
2252    1F56  F1        		pop	af
2253    1F57  F1        		pop	af
2254    1F58  DD71F8    		ld	(ix-8),c
2255    1F5B  DD70F9    		ld	(ix-7),b
2256                    	;  696  #ifdef SDTEST
2257                    	;  697          printf("CMD17 R1 response [%02x]\n", statptr[0]);
2258    1F5E  DD6EF8    		ld	l,(ix-8)
2259    1F61  DD66F9    		ld	h,(ix-7)
2260    1F64  4E        		ld	c,(hl)
2261    1F65  97        		sub	a
2262    1F66  47        		ld	b,a
2263    1F67  C5        		push	bc
2264    1F68  21C61D    		ld	hl,L5631
2265    1F6B  CD0000    		call	_printf
2266    1F6E  F1        		pop	af
2267                    	;  698  #endif
2268                    	;  699      if (statptr[0])
2269    1F6F  DD6EF8    		ld	l,(ix-8)
2270    1F72  DD66F9    		ld	h,(ix-7)
2271    1F75  7E        		ld	a,(hl)
2272    1F76  B7        		or	a
2273    1F77  2812      		jr	z,L1232
2274                    	;  700          {
2275                    	;  701  #ifdef SDTEST
2276                    	;  702          printf("  could not read block\n");
2277    1F79  21E01D    		ld	hl,L5731
2278    1F7C  CD0000    		call	_printf
2279                    	;  703  #endif
2280                    	;  704          spideselect();
2281    1F7F  CD0000    		call	_spideselect
2282                    	;  705          ledoff();
2283    1F82  CD0000    		call	_ledoff
2284                    	;  706          return (NO);
2285    1F85  010000    		ld	bc,0
2286    1F88  C30000    		jp	c.rets
2287                    	L1232:
2288                    	;  707          }
2289                    	;  708      /* looking for 0xfe that is the byte before data */
2290                    	;  709      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
2291    1F8B  DD36E850  		ld	(ix-24),80
2292    1F8F  DD36E900  		ld	(ix-23),0
2293                    	L1332:
2294    1F93  97        		sub	a
2295    1F94  DD96E8    		sub	(ix-24)
2296    1F97  3E00      		ld	a,0
2297    1F99  DD9EE9    		sbc	a,(ix-23)
2298    1F9C  F2DF1F    		jp	p,L1432
2299    1F9F  21FF00    		ld	hl,255
2300    1FA2  CD0000    		call	_spiio
2301    1FA5  DD71F7    		ld	(ix-9),c
2302    1FA8  DD7EF7    		ld	a,(ix-9)
2303    1FAB  FEFE      		cp	254
2304    1FAD  2830      		jr	z,L1432
2305                    	;  710          {
2306                    	;  711          if ((rbyte & 0xe0) == 0x00)
2307    1FAF  DD6EF7    		ld	l,(ix-9)
2308    1FB2  7D        		ld	a,l
2309    1FB3  E6E0      		and	224
2310    1FB5  2019      		jr	nz,L1532
2311                    	;  712              {
2312                    	;  713              /* If a read operation fails and the card cannot provide
2313                    	;  714                 the required data, it will send a data error token instead
2314                    	;  715               */
2315                    	;  716  #ifdef SDTEST
2316                    	;  717              printf("  read error: [%02x]\n", rbyte);
2317    1FB7  DD4EF7    		ld	c,(ix-9)
2318    1FBA  97        		sub	a
2319    1FBB  47        		ld	b,a
2320    1FBC  C5        		push	bc
2321    1FBD  21F81D    		ld	hl,L5041
2322    1FC0  CD0000    		call	_printf
2323    1FC3  F1        		pop	af
2324                    	;  718  #endif
2325                    	;  719              spideselect();
2326    1FC4  CD0000    		call	_spideselect
2327                    	;  720              ledoff();
2328    1FC7  CD0000    		call	_ledoff
2329                    	;  721              return (NO);
2330    1FCA  010000    		ld	bc,0
2331    1FCD  C30000    		jp	c.rets
2332                    	L1532:
2333    1FD0  DD6EE8    		ld	l,(ix-24)
2334    1FD3  DD66E9    		ld	h,(ix-23)
2335    1FD6  2B        		dec	hl
2336    1FD7  DD75E8    		ld	(ix-24),l
2337    1FDA  DD74E9    		ld	(ix-23),h
2338    1FDD  18B4      		jr	L1332
2339                    	L1432:
2340                    	;  722              }
2341                    	;  723          }
2342                    	;  724      if (tries == 0) /* tried too many times */
2343    1FDF  DD7EE8    		ld	a,(ix-24)
2344    1FE2  DDB6E9    		or	(ix-23)
2345    1FE5  2012      		jr	nz,L1042
2346                    	;  725          {
2347                    	;  726  #ifdef SDTEST
2348                    	;  727          printf("  no data found\n");
2349    1FE7  210E1E    		ld	hl,L5141
2350    1FEA  CD0000    		call	_printf
2351                    	;  728  #endif
2352                    	;  729          spideselect();
2353    1FED  CD0000    		call	_spideselect
2354                    	;  730          ledoff();
2355    1FF0  CD0000    		call	_ledoff
2356                    	;  731          return (NO);
2357    1FF3  010000    		ld	bc,0
2358    1FF6  C30000    		jp	c.rets
2359                    	L1042:
2360                    	;  732          }
2361                    	;  733      else
2362                    	;  734          {
2363                    	;  735          calcrc16 = 0;
2364    1FF9  DD36E000  		ld	(ix-32),0
2365    1FFD  DD36E100  		ld	(ix-31),0
2366                    	;  736          for (nbytes = 0; nbytes < 512; nbytes++)
2367    2001  DD36EA00  		ld	(ix-22),0
2368    2005  DD36EB00  		ld	(ix-21),0
2369                    	L1242:
2370    2009  DD7EEA    		ld	a,(ix-22)
2371    200C  D600      		sub	0
2372    200E  DD7EEB    		ld	a,(ix-21)
2373    2011  DE02      		sbc	a,2
2374    2013  F25020    		jp	p,L1342
2375                    	;  737              {
2376                    	;  738              rbyte = spiio(0xff);
2377    2016  21FF00    		ld	hl,255
2378    2019  CD0000    		call	_spiio
2379    201C  DD71F7    		ld	(ix-9),c
2380                    	;  739              calcrc16 = CRC16_one(calcrc16, rbyte);
2381    201F  DD6EF7    		ld	l,(ix-9)
2382    2022  97        		sub	a
2383    2023  67        		ld	h,a
2384    2024  E5        		push	hl
2385    2025  DD6EE0    		ld	l,(ix-32)
2386    2028  DD66E1    		ld	h,(ix-31)
2387    202B  CDB500    		call	_CRC16_one
2388    202E  F1        		pop	af
2389    202F  DD71E0    		ld	(ix-32),c
2390    2032  DD70E1    		ld	(ix-31),b
2391                    	;  740              rdbuf[nbytes] = rbyte;
2392    2035  DD6E04    		ld	l,(ix+4)
2393    2038  DD6605    		ld	h,(ix+5)
2394    203B  DD4EEA    		ld	c,(ix-22)
2395    203E  DD46EB    		ld	b,(ix-21)
2396    2041  09        		add	hl,bc
2397    2042  DD7EF7    		ld	a,(ix-9)
2398    2045  77        		ld	(hl),a
2399                    	;  741              }
2400    2046  DD34EA    		inc	(ix-22)
2401    2049  2003      		jr	nz,L47
2402    204B  DD34EB    		inc	(ix-21)
2403                    	L47:
2404    204E  18B9      		jr	L1242
2405                    	L1342:
2406                    	;  742          rxcrc16 = spiio(0xff) << 8;
2407    2050  21FF00    		ld	hl,255
2408    2053  CD0000    		call	_spiio
2409    2056  69        		ld	l,c
2410    2057  60        		ld	h,b
2411    2058  29        		add	hl,hl
2412    2059  29        		add	hl,hl
2413    205A  29        		add	hl,hl
2414    205B  29        		add	hl,hl
2415    205C  29        		add	hl,hl
2416    205D  29        		add	hl,hl
2417    205E  29        		add	hl,hl
2418    205F  29        		add	hl,hl
2419    2060  DD75E2    		ld	(ix-30),l
2420    2063  DD74E3    		ld	(ix-29),h
2421                    	;  743          rxcrc16 += spiio(0xff);
2422    2066  21FF00    		ld	hl,255
2423    2069  CD0000    		call	_spiio
2424    206C  DD6EE2    		ld	l,(ix-30)
2425    206F  DD66E3    		ld	h,(ix-29)
2426    2072  09        		add	hl,bc
2427    2073  DD75E2    		ld	(ix-30),l
2428    2076  DD74E3    		ld	(ix-29),h
2429                    	;  744  
2430                    	;  745  #ifdef SDTEST
2431                    	;  746          printf("  read data block %ld:\n", rdblkno);
2432    2079  DD6609    		ld	h,(ix+9)
2433    207C  DD6E08    		ld	l,(ix+8)
2434    207F  E5        		push	hl
2435    2080  DD6607    		ld	h,(ix+7)
2436    2083  DD6E06    		ld	l,(ix+6)
2437    2086  E5        		push	hl
2438    2087  211F1E    		ld	hl,L5241
2439    208A  CD0000    		call	_printf
2440    208D  F1        		pop	af
2441    208E  F1        		pop	af
2442                    	;  747  #endif
2443                    	;  748          if (rxcrc16 != calcrc16)
2444    208F  DD7EE2    		ld	a,(ix-30)
2445    2092  DDBEE0    		cp	(ix-32)
2446    2095  2006      		jr	nz,L67
2447    2097  DD7EE3    		ld	a,(ix-29)
2448    209A  DDBEE1    		cp	(ix-31)
2449                    	L67:
2450    209D  2822      		jr	z,L1142
2451                    	;  749              {
2452                    	;  750  #ifdef SDTEST
2453                    	;  751              printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
2454                    	;  752                  rxcrc16, calcrc16);
2455    209F  DD6EE0    		ld	l,(ix-32)
2456    20A2  DD66E1    		ld	h,(ix-31)
2457    20A5  E5        		push	hl
2458    20A6  DD6EE2    		ld	l,(ix-30)
2459    20A9  DD66E3    		ld	h,(ix-29)
2460    20AC  E5        		push	hl
2461    20AD  21371E    		ld	hl,L5341
2462    20B0  CD0000    		call	_printf
2463    20B3  F1        		pop	af
2464    20B4  F1        		pop	af
2465                    	;  753  #endif
2466                    	;  754              spideselect();
2467    20B5  CD0000    		call	_spideselect
2468                    	;  755              ledoff();
2469    20B8  CD0000    		call	_ledoff
2470                    	;  756              return (NO);
2471    20BB  010000    		ld	bc,0
2472    20BE  C30000    		jp	c.rets
2473                    	L1142:
2474                    	;  757              }
2475                    	;  758          }
2476                    	;  759      spideselect();
2477    20C1  CD0000    		call	_spideselect
2478                    	;  760      ledoff();
2479    20C4  CD0000    		call	_ledoff
2480                    	;  761      return (YES);
2481    20C7  010100    		ld	bc,1
2482    20CA  C30000    		jp	c.rets
2483                    	L5441:
2484    20CD  53        		.byte	83
2485    20CE  44        		.byte	68
2486    20CF  20        		.byte	32
2487    20D0  63        		.byte	99
2488    20D1  61        		.byte	97
2489    20D2  72        		.byte	114
2490    20D3  64        		.byte	100
2491    20D4  20        		.byte	32
2492    20D5  6E        		.byte	110
2493    20D6  6F        		.byte	111
2494    20D7  74        		.byte	116
2495    20D8  20        		.byte	32
2496    20D9  69        		.byte	105
2497    20DA  6E        		.byte	110
2498    20DB  69        		.byte	105
2499    20DC  74        		.byte	116
2500    20DD  69        		.byte	105
2501    20DE  61        		.byte	97
2502    20DF  6C        		.byte	108
2503    20E0  69        		.byte	105
2504    20E1  7A        		.byte	122
2505    20E2  65        		.byte	101
2506    20E3  64        		.byte	100
2507    20E4  0A        		.byte	10
2508    20E5  00        		.byte	0
2509                    	L5541:
2510    20E6  20        		.byte	32
2511    20E7  20        		.byte	32
2512    20E8  77        		.byte	119
2513    20E9  72        		.byte	114
2514    20EA  69        		.byte	105
2515    20EB  74        		.byte	116
2516    20EC  65        		.byte	101
2517    20ED  20        		.byte	32
2518    20EE  64        		.byte	100
2519    20EF  61        		.byte	97
2520    20F0  74        		.byte	116
2521    20F1  61        		.byte	97
2522    20F2  20        		.byte	32
2523    20F3  62        		.byte	98
2524    20F4  6C        		.byte	108
2525    20F5  6F        		.byte	111
2526    20F6  63        		.byte	99
2527    20F7  6B        		.byte	107
2528    20F8  20        		.byte	32
2529    20F9  25        		.byte	37
2530    20FA  6C        		.byte	108
2531    20FB  64        		.byte	100
2532    20FC  3A        		.byte	58
2533    20FD  0A        		.byte	10
2534    20FE  00        		.byte	0
2535                    	L5641:
2536    20FF  0A        		.byte	10
2537    2100  43        		.byte	67
2538    2101  4D        		.byte	77
2539    2102  44        		.byte	68
2540    2103  32        		.byte	50
2541    2104  34        		.byte	52
2542    2105  3A        		.byte	58
2543    2106  20        		.byte	32
2544    2107  57        		.byte	87
2545    2108  52        		.byte	82
2546    2109  49        		.byte	73
2547    210A  54        		.byte	84
2548    210B  45        		.byte	69
2549    210C  5F        		.byte	95
2550    210D  53        		.byte	83
2551    210E  49        		.byte	73
2552    210F  4E        		.byte	78
2553    2110  47        		.byte	71
2554    2111  4C        		.byte	76
2555    2112  45        		.byte	69
2556    2113  5F        		.byte	95
2557    2114  42        		.byte	66
2558    2115  4C        		.byte	76
2559    2116  4F        		.byte	79
2560    2117  43        		.byte	67
2561    2118  4B        		.byte	75
2562    2119  2C        		.byte	44
2563    211A  20        		.byte	32
2564    211B  63        		.byte	99
2565    211C  6F        		.byte	111
2566    211D  6D        		.byte	109
2567    211E  6D        		.byte	109
2568    211F  61        		.byte	97
2569    2120  6E        		.byte	110
2570    2121  64        		.byte	100
2571    2122  20        		.byte	32
2572    2123  5B        		.byte	91
2573    2124  25        		.byte	37
2574    2125  30        		.byte	48
2575    2126  32        		.byte	50
2576    2127  78        		.byte	120
2577    2128  20        		.byte	32
2578    2129  25        		.byte	37
2579    212A  30        		.byte	48
2580    212B  32        		.byte	50
2581    212C  78        		.byte	120
2582    212D  20        		.byte	32
2583    212E  25        		.byte	37
2584    212F  30        		.byte	48
2585    2130  32        		.byte	50
2586    2131  78        		.byte	120
2587    2132  20        		.byte	32
2588    2133  25        		.byte	37
2589    2134  30        		.byte	48
2590    2135  32        		.byte	50
2591    2136  78        		.byte	120
2592    2137  20        		.byte	32
2593    2138  25        		.byte	37
2594    2139  30        		.byte	48
2595    213A  32        		.byte	50
2596    213B  78        		.byte	120
2597    213C  5D        		.byte	93
2598    213D  0A        		.byte	10
2599    213E  00        		.byte	0
2600                    	L5741:
2601    213F  43        		.byte	67
2602    2140  4D        		.byte	77
2603    2141  44        		.byte	68
2604    2142  32        		.byte	50
2605    2143  34        		.byte	52
2606    2144  20        		.byte	32
2607    2145  52        		.byte	82
2608    2146  31        		.byte	49
2609    2147  20        		.byte	32
2610    2148  72        		.byte	114
2611    2149  65        		.byte	101
2612    214A  73        		.byte	115
2613    214B  70        		.byte	112
2614    214C  6F        		.byte	111
2615    214D  6E        		.byte	110
2616    214E  73        		.byte	115
2617    214F  65        		.byte	101
2618    2150  20        		.byte	32
2619    2151  5B        		.byte	91
2620    2152  25        		.byte	37
2621    2153  30        		.byte	48
2622    2154  32        		.byte	50
2623    2155  78        		.byte	120
2624    2156  5D        		.byte	93
2625    2157  0A        		.byte	10
2626    2158  00        		.byte	0
2627                    	L5051:
2628    2159  20        		.byte	32
2629    215A  20        		.byte	32
2630    215B  63        		.byte	99
2631    215C  6F        		.byte	111
2632    215D  75        		.byte	117
2633    215E  6C        		.byte	108
2634    215F  64        		.byte	100
2635    2160  20        		.byte	32
2636    2161  6E        		.byte	110
2637    2162  6F        		.byte	111
2638    2163  74        		.byte	116
2639    2164  20        		.byte	32
2640    2165  77        		.byte	119
2641    2166  72        		.byte	114
2642    2167  69        		.byte	105
2643    2168  74        		.byte	116
2644    2169  65        		.byte	101
2645    216A  20        		.byte	32
2646    216B  62        		.byte	98
2647    216C  6C        		.byte	108
2648    216D  6F        		.byte	111
2649    216E  63        		.byte	99
2650    216F  6B        		.byte	107
2651    2170  0A        		.byte	10
2652    2171  00        		.byte	0
2653                    	L5151:
2654    2172  4E        		.byte	78
2655    2173  6F        		.byte	111
2656    2174  20        		.byte	32
2657    2175  64        		.byte	100
2658    2176  61        		.byte	97
2659    2177  74        		.byte	116
2660    2178  61        		.byte	97
2661    2179  20        		.byte	32
2662    217A  72        		.byte	114
2663    217B  65        		.byte	101
2664    217C  73        		.byte	115
2665    217D  70        		.byte	112
2666    217E  6F        		.byte	111
2667    217F  6E        		.byte	110
2668    2180  73        		.byte	115
2669    2181  65        		.byte	101
2670    2182  0A        		.byte	10
2671    2183  00        		.byte	0
2672                    	L5251:
2673    2184  44        		.byte	68
2674    2185  61        		.byte	97
2675    2186  74        		.byte	116
2676    2187  61        		.byte	97
2677    2188  20        		.byte	32
2678    2189  72        		.byte	114
2679    218A  65        		.byte	101
2680    218B  73        		.byte	115
2681    218C  70        		.byte	112
2682    218D  6F        		.byte	111
2683    218E  6E        		.byte	110
2684    218F  73        		.byte	115
2685    2190  65        		.byte	101
2686    2191  20        		.byte	32
2687    2192  5B        		.byte	91
2688    2193  25        		.byte	37
2689    2194  30        		.byte	48
2690    2195  32        		.byte	50
2691    2196  78        		.byte	120
2692    2197  5D        		.byte	93
2693    2198  00        		.byte	0
2694                    	L5351:
2695    2199  2C        		.byte	44
2696    219A  20        		.byte	32
2697    219B  64        		.byte	100
2698    219C  61        		.byte	97
2699    219D  74        		.byte	116
2700    219E  61        		.byte	97
2701    219F  20        		.byte	32
2702    21A0  61        		.byte	97
2703    21A1  63        		.byte	99
2704    21A2  63        		.byte	99
2705    21A3  65        		.byte	101
2706    21A4  70        		.byte	112
2707    21A5  74        		.byte	116
2708    21A6  65        		.byte	101
2709    21A7  64        		.byte	100
2710    21A8  0A        		.byte	10
2711    21A9  00        		.byte	0
2712                    	L5451:
2713    21AA  53        		.byte	83
2714    21AB  65        		.byte	101
2715    21AC  6E        		.byte	110
2716    21AD  74        		.byte	116
2717    21AE  20        		.byte	32
2718    21AF  39        		.byte	57
2719    21B0  2A        		.byte	42
2720    21B1  38        		.byte	56
2721    21B2  20        		.byte	32
2722    21B3  28        		.byte	40
2723    21B4  37        		.byte	55
2724    21B5  32        		.byte	50
2725    21B6  29        		.byte	41
2726    21B7  20        		.byte	32
2727    21B8  63        		.byte	99
2728    21B9  6C        		.byte	108
2729    21BA  6F        		.byte	111
2730    21BB  63        		.byte	99
2731    21BC  6B        		.byte	107
2732    21BD  20        		.byte	32
2733    21BE  70        		.byte	112
2734    21BF  75        		.byte	117
2735    21C0  6C        		.byte	108
2736    21C1  73        		.byte	115
2737    21C2  65        		.byte	101
2738    21C3  73        		.byte	115
2739    21C4  2C        		.byte	44
2740    21C5  20        		.byte	32
2741    21C6  73        		.byte	115
2742    21C7  65        		.byte	101
2743    21C8  6C        		.byte	108
2744    21C9  65        		.byte	101
2745    21CA  63        		.byte	99
2746    21CB  74        		.byte	116
2747    21CC  20        		.byte	32
2748    21CD  61        		.byte	97
2749    21CE  63        		.byte	99
2750    21CF  74        		.byte	116
2751    21D0  69        		.byte	105
2752    21D1  76        		.byte	118
2753    21D2  65        		.byte	101
2754    21D3  0A        		.byte	10
2755    21D4  00        		.byte	0
2756                    	L5551:
2757    21D5  2C        		.byte	44
2758    21D6  20        		.byte	32
2759    21D7  64        		.byte	100
2760    21D8  61        		.byte	97
2761    21D9  74        		.byte	116
2762    21DA  61        		.byte	97
2763    21DB  20        		.byte	32
2764    21DC  6E        		.byte	110
2765    21DD  6F        		.byte	111
2766    21DE  74        		.byte	116
2767    21DF  20        		.byte	32
2768    21E0  61        		.byte	97
2769    21E1  63        		.byte	99
2770    21E2  63        		.byte	99
2771    21E3  65        		.byte	101
2772    21E4  70        		.byte	112
2773    21E5  74        		.byte	116
2774    21E6  65        		.byte	101
2775    21E7  64        		.byte	100
2776    21E8  0A        		.byte	10
2777    21E9  00        		.byte	0
2778                    	;  762      }
2779                    	;  763  
2780                    	;  764  /* Write data block of 512 bytes from buffer
2781                    	;  765   * Returns YES if ok or NO if error
2782                    	;  766   */
2783                    	;  767  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
2784                    	;  768      {
2785                    	_sdwrite:
2786    21EA  CD0000    		call	c.savs
2787    21ED  21E2FF    		ld	hl,65506
2788    21F0  39        		add	hl,sp
2789    21F1  F9        		ld	sp,hl
2790                    	;  769      unsigned char *statptr;
2791                    	;  770      unsigned char rbyte;
2792                    	;  771      unsigned char tbyte;
2793                    	;  772      unsigned char cmdbuf[5];   /* buffer to build command in */
2794                    	;  773      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2795                    	;  774      int nbytes;
2796                    	;  775      int tries;
2797                    	;  776      unsigned long blktowrite;
2798                    	;  777      unsigned int calcrc16;
2799                    	;  778  
2800                    	;  779      ledon();
2801    21F2  CD0000    		call	_ledon
2802                    	;  780      spiselect();
2803    21F5  CD0000    		call	_spiselect
2804                    	;  781  
2805                    	;  782      if (!sdinitok)
2806    21F8  2A0A00    		ld	hl,(_sdinitok)
2807    21FB  7C        		ld	a,h
2808    21FC  B5        		or	l
2809    21FD  2012      		jr	nz,L1742
2810                    	;  783          {
2811                    	;  784  #ifdef SDTEST
2812                    	;  785          printf("SD card not initialized\n");
2813    21FF  21CD20    		ld	hl,L5441
2814    2202  CD0000    		call	_printf
2815                    	;  786  #endif
2816                    	;  787          spideselect();
2817    2205  CD0000    		call	_spideselect
2818                    	;  788          ledoff();
2819    2208  CD0000    		call	_ledoff
2820                    	;  789          return (NO);
2821    220B  010000    		ld	bc,0
2822    220E  C30000    		jp	c.rets
2823                    	L1742:
2824                    	;  790          }
2825                    	;  791  
2826                    	;  792  #ifdef SDTEST
2827                    	;  793      printf("  write data block %ld:\n", wrblkno);
2828    2211  DD6609    		ld	h,(ix+9)
2829    2214  DD6E08    		ld	l,(ix+8)
2830    2217  E5        		push	hl
2831    2218  DD6607    		ld	h,(ix+7)
2832    221B  DD6E06    		ld	l,(ix+6)
2833    221E  E5        		push	hl
2834    221F  21E620    		ld	hl,L5541
2835    2222  CD0000    		call	_printf
2836    2225  F1        		pop	af
2837    2226  F1        		pop	af
2838                    	;  794  #endif
2839                    	;  795      /* CMD24: WRITE_SINGLE_BLOCK */
2840                    	;  796      /* Insert block # into command */
2841                    	;  797      memcpy(cmdbuf, cmd24, 5);
2842    2227  210500    		ld	hl,5
2843    222A  E5        		push	hl
2844    222B  213B00    		ld	hl,_cmd24
2845    222E  E5        		push	hl
2846    222F  DDE5      		push	ix
2847    2231  C1        		pop	bc
2848    2232  21F1FF    		ld	hl,65521
2849    2235  09        		add	hl,bc
2850    2236  CD0000    		call	_memcpy
2851    2239  F1        		pop	af
2852    223A  F1        		pop	af
2853                    	;  798      blktowrite = blkmult * wrblkno;
2854    223B  DDE5      		push	ix
2855    223D  C1        		pop	bc
2856    223E  21E4FF    		ld	hl,65508
2857    2241  09        		add	hl,bc
2858    2242  E5        		push	hl
2859    2243  210400    		ld	hl,_blkmult
2860    2246  CD0000    		call	c.0mvf
2861    2249  210000    		ld	hl,c.r0
2862    224C  E5        		push	hl
2863    224D  DDE5      		push	ix
2864    224F  C1        		pop	bc
2865    2250  210600    		ld	hl,6
2866    2253  09        		add	hl,bc
2867    2254  E5        		push	hl
2868    2255  CD0000    		call	c.lmul
2869    2258  CD0000    		call	c.mvl
2870    225B  F1        		pop	af
2871                    	;  799      cmdbuf[4] = blktowrite & 0xff;
2872    225C  DD6EE6    		ld	l,(ix-26)
2873    225F  7D        		ld	a,l
2874    2260  E6FF      		and	255
2875    2262  DD77F5    		ld	(ix-11),a
2876                    	;  800      blktowrite = blktowrite >> 8;
2877    2265  DDE5      		push	ix
2878    2267  C1        		pop	bc
2879    2268  21E4FF    		ld	hl,65508
2880    226B  09        		add	hl,bc
2881    226C  E5        		push	hl
2882    226D  210800    		ld	hl,8
2883    2270  E5        		push	hl
2884    2271  CD0000    		call	c.ulrsh
2885    2274  F1        		pop	af
2886                    	;  801      cmdbuf[3] = blktowrite & 0xff;
2887    2275  DD6EE6    		ld	l,(ix-26)
2888    2278  7D        		ld	a,l
2889    2279  E6FF      		and	255
2890    227B  DD77F4    		ld	(ix-12),a
2891                    	;  802      blktowrite = blktowrite >> 8;
2892    227E  DDE5      		push	ix
2893    2280  C1        		pop	bc
2894    2281  21E4FF    		ld	hl,65508
2895    2284  09        		add	hl,bc
2896    2285  E5        		push	hl
2897    2286  210800    		ld	hl,8
2898    2289  E5        		push	hl
2899    228A  CD0000    		call	c.ulrsh
2900    228D  F1        		pop	af
2901                    	;  803      cmdbuf[2] = blktowrite & 0xff;
2902    228E  DD6EE6    		ld	l,(ix-26)
2903    2291  7D        		ld	a,l
2904    2292  E6FF      		and	255
2905    2294  DD77F3    		ld	(ix-13),a
2906                    	;  804      blktowrite = blktowrite >> 8;
2907    2297  DDE5      		push	ix
2908    2299  C1        		pop	bc
2909    229A  21E4FF    		ld	hl,65508
2910    229D  09        		add	hl,bc
2911    229E  E5        		push	hl
2912    229F  210800    		ld	hl,8
2913    22A2  E5        		push	hl
2914    22A3  CD0000    		call	c.ulrsh
2915    22A6  F1        		pop	af
2916                    	;  805      cmdbuf[1] = blktowrite & 0xff;
2917    22A7  DD6EE6    		ld	l,(ix-26)
2918    22AA  7D        		ld	a,l
2919    22AB  E6FF      		and	255
2920    22AD  DD77F2    		ld	(ix-14),a
2921                    	;  806  
2922                    	;  807  #ifdef SDTEST
2923                    	;  808      printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2924                    	;  809                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2925    22B0  DD4EF5    		ld	c,(ix-11)
2926    22B3  97        		sub	a
2927    22B4  47        		ld	b,a
2928    22B5  C5        		push	bc
2929    22B6  DD4EF4    		ld	c,(ix-12)
2930    22B9  97        		sub	a
2931    22BA  47        		ld	b,a
2932    22BB  C5        		push	bc
2933    22BC  DD4EF3    		ld	c,(ix-13)
2934    22BF  97        		sub	a
2935    22C0  47        		ld	b,a
2936    22C1  C5        		push	bc
2937    22C2  DD4EF2    		ld	c,(ix-14)
2938    22C5  97        		sub	a
2939    22C6  47        		ld	b,a
2940    22C7  C5        		push	bc
2941    22C8  DD4EF1    		ld	c,(ix-15)
2942    22CB  97        		sub	a
2943    22CC  47        		ld	b,a
2944    22CD  C5        		push	bc
2945    22CE  21FF20    		ld	hl,L5641
2946    22D1  CD0000    		call	_printf
2947    22D4  210A00    		ld	hl,10
2948    22D7  39        		add	hl,sp
2949    22D8  F9        		ld	sp,hl
2950                    	;  810  #endif
2951                    	;  811      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2952    22D9  210100    		ld	hl,1
2953    22DC  E5        		push	hl
2954    22DD  DDE5      		push	ix
2955    22DF  C1        		pop	bc
2956    22E0  21ECFF    		ld	hl,65516
2957    22E3  09        		add	hl,bc
2958    22E4  E5        		push	hl
2959    22E5  DDE5      		push	ix
2960    22E7  C1        		pop	bc
2961    22E8  21F1FF    		ld	hl,65521
2962    22EB  09        		add	hl,bc
2963    22EC  CD6301    		call	_sdcommand
2964    22EF  F1        		pop	af
2965    22F0  F1        		pop	af
2966    22F1  DD71F8    		ld	(ix-8),c
2967    22F4  DD70F9    		ld	(ix-7),b
2968                    	;  812  #ifdef SDTEST
2969                    	;  813          printf("CMD24 R1 response [%02x]\n", statptr[0]);
2970    22F7  DD6EF8    		ld	l,(ix-8)
2971    22FA  DD66F9    		ld	h,(ix-7)
2972    22FD  4E        		ld	c,(hl)
2973    22FE  97        		sub	a
2974    22FF  47        		ld	b,a
2975    2300  C5        		push	bc
2976    2301  213F21    		ld	hl,L5741
2977    2304  CD0000    		call	_printf
2978    2307  F1        		pop	af
2979                    	;  814  #endif
2980                    	;  815      if (statptr[0])
2981    2308  DD6EF8    		ld	l,(ix-8)
2982    230B  DD66F9    		ld	h,(ix-7)
2983    230E  7E        		ld	a,(hl)
2984    230F  B7        		or	a
2985    2310  2812      		jr	z,L1052
2986                    	;  816          {
2987                    	;  817  #ifdef SDTEST
2988                    	;  818          printf("  could not write block\n");
2989    2312  215921    		ld	hl,L5051
2990    2315  CD0000    		call	_printf
2991                    	;  819  #endif
2992                    	;  820          spideselect();
2993    2318  CD0000    		call	_spideselect
2994                    	;  821          ledoff();
2995    231B  CD0000    		call	_ledoff
2996                    	;  822          return (NO);
2997    231E  010000    		ld	bc,0
2998    2321  C30000    		jp	c.rets
2999                    	L1052:
3000                    	;  823          }
3001                    	;  824      /* send 0xfe, the byte before data */
3002                    	;  825      spiio(0xfe);
3003    2324  21FE00    		ld	hl,254
3004    2327  CD0000    		call	_spiio
3005                    	;  826      /* initialize crc and send block */
3006                    	;  827      calcrc16 = 0;
3007    232A  DD36E200  		ld	(ix-30),0
3008    232E  DD36E300  		ld	(ix-29),0
3009                    	;  828      for (nbytes = 0; nbytes < 512; nbytes++)
3010    2332  DD36EA00  		ld	(ix-22),0
3011    2336  DD36EB00  		ld	(ix-21),0
3012                    	L1152:
3013    233A  DD7EEA    		ld	a,(ix-22)
3014    233D  D600      		sub	0
3015    233F  DD7EEB    		ld	a,(ix-21)
3016    2342  DE02      		sbc	a,2
3017    2344  F28023    		jp	p,L1252
3018                    	;  829          {
3019                    	;  830          tbyte = wrbuf[nbytes];
3020    2347  DD6E04    		ld	l,(ix+4)
3021    234A  DD6605    		ld	h,(ix+5)
3022    234D  DD4EEA    		ld	c,(ix-22)
3023    2350  DD46EB    		ld	b,(ix-21)
3024    2353  09        		add	hl,bc
3025    2354  7E        		ld	a,(hl)
3026    2355  DD77F6    		ld	(ix-10),a
3027                    	;  831          spiio(tbyte);
3028    2358  DD6EF6    		ld	l,(ix-10)
3029    235B  97        		sub	a
3030    235C  67        		ld	h,a
3031    235D  CD0000    		call	_spiio
3032                    	;  832          calcrc16 = CRC16_one(calcrc16, tbyte);
3033    2360  DD6EF6    		ld	l,(ix-10)
3034    2363  97        		sub	a
3035    2364  67        		ld	h,a
3036    2365  E5        		push	hl
3037    2366  DD6EE2    		ld	l,(ix-30)
3038    2369  DD66E3    		ld	h,(ix-29)
3039    236C  CDB500    		call	_CRC16_one
3040    236F  F1        		pop	af
3041    2370  DD71E2    		ld	(ix-30),c
3042    2373  DD70E3    		ld	(ix-29),b
3043                    	;  833          }
3044    2376  DD34EA    		inc	(ix-22)
3045    2379  2003      		jr	nz,L201
3046    237B  DD34EB    		inc	(ix-21)
3047                    	L201:
3048    237E  18BA      		jr	L1152
3049                    	L1252:
3050                    	;  834      spiio((calcrc16 >> 8) & 0xff);
3051    2380  DD6EE2    		ld	l,(ix-30)
3052    2383  DD66E3    		ld	h,(ix-29)
3053    2386  E5        		push	hl
3054    2387  210800    		ld	hl,8
3055    238A  E5        		push	hl
3056    238B  CD0000    		call	c.ursh
3057    238E  E1        		pop	hl
3058    238F  7D        		ld	a,l
3059    2390  E6FF      		and	255
3060    2392  6F        		ld	l,a
3061    2393  97        		sub	a
3062    2394  67        		ld	h,a
3063    2395  CD0000    		call	_spiio
3064                    	;  835      spiio(calcrc16 & 0xff);
3065    2398  DD6EE2    		ld	l,(ix-30)
3066    239B  DD66E3    		ld	h,(ix-29)
3067    239E  7D        		ld	a,l
3068    239F  E6FF      		and	255
3069    23A1  6F        		ld	l,a
3070    23A2  97        		sub	a
3071    23A3  67        		ld	h,a
3072    23A4  CD0000    		call	_spiio
3073                    	;  836  
3074                    	;  837      /* check data resposnse */
3075                    	;  838      for (tries = 20; 
3076    23A7  DD36E814  		ld	(ix-24),20
3077    23AB  DD36E900  		ld	(ix-23),0
3078                    	L1552:
3079                    	;  839          0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
3080    23AF  97        		sub	a
3081    23B0  DD96E8    		sub	(ix-24)
3082    23B3  3E00      		ld	a,0
3083    23B5  DD9EE9    		sbc	a,(ix-23)
3084    23B8  F2E823    		jp	p,L1652
3085    23BB  21FF00    		ld	hl,255
3086    23BE  CD0000    		call	_spiio
3087    23C1  DD71F7    		ld	(ix-9),c
3088    23C4  DD6EF7    		ld	l,(ix-9)
3089    23C7  97        		sub	a
3090    23C8  67        		ld	h,a
3091    23C9  7D        		ld	a,l
3092    23CA  E611      		and	17
3093    23CC  6F        		ld	l,a
3094    23CD  97        		sub	a
3095    23CE  67        		ld	h,a
3096    23CF  7D        		ld	a,l
3097    23D0  FE01      		cp	1
3098    23D2  2003      		jr	nz,L401
3099    23D4  7C        		ld	a,h
3100    23D5  FE00      		cp	0
3101                    	L401:
3102    23D7  280F      		jr	z,L1652
3103                    	;  840          tries--)
3104                    	L1752:
3105    23D9  DD6EE8    		ld	l,(ix-24)
3106    23DC  DD66E9    		ld	h,(ix-23)
3107    23DF  2B        		dec	hl
3108    23E0  DD75E8    		ld	(ix-24),l
3109    23E3  DD74E9    		ld	(ix-23),h
3110    23E6  18C7      		jr	L1552
3111                    	L1652:
3112                    	;  841          ;
3113                    	;  842      if (tries == 0)
3114    23E8  DD7EE8    		ld	a,(ix-24)
3115    23EB  DDB6E9    		or	(ix-23)
3116    23EE  2012      		jr	nz,L1162
3117                    	;  843          {
3118                    	;  844  #ifdef SDTEST
3119                    	;  845          printf("No data response\n");
3120    23F0  217221    		ld	hl,L5151
3121    23F3  CD0000    		call	_printf
3122                    	;  846  #endif
3123                    	;  847          spideselect();
3124    23F6  CD0000    		call	_spideselect
3125                    	;  848          ledoff();
3126    23F9  CD0000    		call	_ledoff
3127                    	;  849          return (NO);
3128    23FC  010000    		ld	bc,0
3129    23FF  C30000    		jp	c.rets
3130                    	L1162:
3131                    	;  850          }
3132                    	;  851      else
3133                    	;  852          {
3134                    	;  853  #ifdef SDTEST
3135                    	;  854          printf("Data response [%02x]", 0x1f & rbyte);
3136    2402  DD6EF7    		ld	l,(ix-9)
3137    2405  97        		sub	a
3138    2406  67        		ld	h,a
3139    2407  7D        		ld	a,l
3140    2408  E61F      		and	31
3141    240A  6F        		ld	l,a
3142    240B  97        		sub	a
3143    240C  67        		ld	h,a
3144    240D  E5        		push	hl
3145    240E  218421    		ld	hl,L5251
3146    2411  CD0000    		call	_printf
3147    2414  F1        		pop	af
3148                    	;  855  #endif
3149                    	;  856          if ((0x1f & rbyte) == 0x05)
3150    2415  DD6EF7    		ld	l,(ix-9)
3151    2418  97        		sub	a
3152    2419  67        		ld	h,a
3153    241A  7D        		ld	a,l
3154    241B  E61F      		and	31
3155    241D  6F        		ld	l,a
3156    241E  97        		sub	a
3157    241F  67        		ld	h,a
3158    2420  7D        		ld	a,l
3159    2421  FE05      		cp	5
3160    2423  2003      		jr	nz,L601
3161    2425  7C        		ld	a,h
3162    2426  FE00      		cp	0
3163                    	L601:
3164    2428  2041      		jr	nz,L1362
3165                    	;  857              {
3166                    	;  858  #ifdef SDTEST
3167                    	;  859              printf(", data accepted\n");
3168    242A  219921    		ld	hl,L5351
3169    242D  CD0000    		call	_printf
3170                    	;  860  #endif
3171                    	;  861              for (nbytes = 9; 0 < nbytes; nbytes--)
3172    2430  DD36EA09  		ld	(ix-22),9
3173    2434  DD36EB00  		ld	(ix-21),0
3174                    	L1462:
3175    2438  97        		sub	a
3176    2439  DD96EA    		sub	(ix-22)
3177    243C  3E00      		ld	a,0
3178    243E  DD9EEB    		sbc	a,(ix-21)
3179    2441  F25924    		jp	p,L1562
3180                    	;  862                  spiio(0xff);
3181    2444  21FF00    		ld	hl,255
3182    2447  CD0000    		call	_spiio
3183    244A  DD6EEA    		ld	l,(ix-22)
3184    244D  DD66EB    		ld	h,(ix-21)
3185    2450  2B        		dec	hl
3186    2451  DD75EA    		ld	(ix-22),l
3187    2454  DD74EB    		ld	(ix-21),h
3188    2457  18DF      		jr	L1462
3189                    	L1562:
3190                    	;  863  #ifdef SDTEST
3191                    	;  864              printf("Sent 9*8 (72) clock pulses, select active\n");
3192    2459  21AA21    		ld	hl,L5451
3193    245C  CD0000    		call	_printf
3194                    	;  865  #endif
3195                    	;  866              spideselect();
3196    245F  CD0000    		call	_spideselect
3197                    	;  867              ledoff();
3198    2462  CD0000    		call	_ledoff
3199                    	;  868              return (YES);
3200    2465  010100    		ld	bc,1
3201    2468  C30000    		jp	c.rets
3202                    	L1362:
3203                    	;  869              }
3204                    	;  870          else
3205                    	;  871              {
3206                    	;  872  #ifdef SDTEST
3207                    	;  873              printf(", data not accepted\n");
3208    246B  21D521    		ld	hl,L5551
3209    246E  CD0000    		call	_printf
3210                    	;  874  #endif
3211                    	;  875              spideselect();
3212    2471  CD0000    		call	_spideselect
3213                    	;  876              ledoff();
3214    2474  CD0000    		call	_ledoff
3215                    	;  877              return (NO);
3216    2477  010000    		ld	bc,0
3217    247A  C30000    		jp	c.rets
3218                    	L5651:
3219    247D  2A        		.byte	42
3220    247E  0A        		.byte	10
3221    247F  00        		.byte	0
3222                    	L5751:
3223    2480  25        		.byte	37
3224    2481  30        		.byte	48
3225    2482  34        		.byte	52
3226    2483  78        		.byte	120
3227    2484  20        		.byte	32
3228    2485  00        		.byte	0
3229                    	L5061:
3230    2486  25        		.byte	37
3231    2487  30        		.byte	48
3232    2488  32        		.byte	50
3233    2489  78        		.byte	120
3234    248A  20        		.byte	32
3235    248B  00        		.byte	0
3236                    	L5161:
3237    248C  20        		.byte	32
3238    248D  7C        		.byte	124
3239    248E  00        		.byte	0
3240                    	L5261:
3241    248F  7C        		.byte	124
3242    2490  0A        		.byte	10
3243    2491  00        		.byte	0
3244                    	;  878              }
3245                    	;  879          }
3246                    	;  880      }
3247                    	;  881  
3248                    	;  882  /* Print data in 512 byte buffer */
3249                    	;  883  void sddatprt(unsigned char *prtbuf)
3250                    	;  884      {
3251                    	_sddatprt:
3252    2492  CD0000    		call	c.savs
3253    2495  21EEFF    		ld	hl,65518
3254    2498  39        		add	hl,sp
3255    2499  F9        		ld	sp,hl
3256                    	;  885      /* Variables used for "pretty-print" */
3257                    	;  886      int allzero, dmpline, dotprted, lastallz, nbytes;
3258                    	;  887      unsigned char *prtptr;
3259                    	;  888  
3260                    	;  889      prtptr = prtbuf;
3261    249A  DD7E04    		ld	a,(ix+4)
3262    249D  DD77EE    		ld	(ix-18),a
3263    24A0  DD7E05    		ld	a,(ix+5)
3264    24A3  DD77EF    		ld	(ix-17),a
3265                    	;  890      dotprted = NO;
3266    24A6  DD36F400  		ld	(ix-12),0
3267    24AA  DD36F500  		ld	(ix-11),0
3268                    	;  891      lastallz = NO;
3269    24AE  DD36F200  		ld	(ix-14),0
3270    24B2  DD36F300  		ld	(ix-13),0
3271                    	;  892      for (dmpline = 0; dmpline < 32; dmpline++)
3272    24B6  DD36F600  		ld	(ix-10),0
3273    24BA  DD36F700  		ld	(ix-9),0
3274                    	L1172:
3275    24BE  DD7EF6    		ld	a,(ix-10)
3276    24C1  D620      		sub	32
3277    24C3  DD7EF7    		ld	a,(ix-9)
3278    24C6  DE00      		sbc	a,0
3279    24C8  F21F26    		jp	p,L1272
3280                    	;  893          {
3281                    	;  894          /* test if all 16 bytes are 0x00 */
3282                    	;  895          allzero = YES;
3283    24CB  DD36F801  		ld	(ix-8),1
3284    24CF  DD36F900  		ld	(ix-7),0
3285                    	;  896          for (nbytes = 0; nbytes < 16; nbytes++)
3286    24D3  DD36F000  		ld	(ix-16),0
3287    24D7  DD36F100  		ld	(ix-15),0
3288                    	L1572:
3289    24DB  DD7EF0    		ld	a,(ix-16)
3290    24DE  D610      		sub	16
3291    24E0  DD7EF1    		ld	a,(ix-15)
3292    24E3  DE00      		sbc	a,0
3293    24E5  F20B25    		jp	p,L1672
3294                    	;  897              {
3295                    	;  898              if (prtptr[nbytes] != 0)
3296    24E8  DD6EEE    		ld	l,(ix-18)
3297    24EB  DD66EF    		ld	h,(ix-17)
3298    24EE  DD4EF0    		ld	c,(ix-16)
3299    24F1  DD46F1    		ld	b,(ix-15)
3300    24F4  09        		add	hl,bc
3301    24F5  7E        		ld	a,(hl)
3302    24F6  B7        		or	a
3303    24F7  2808      		jr	z,L1772
3304                    	;  899                  allzero = NO;
3305    24F9  DD36F800  		ld	(ix-8),0
3306    24FD  DD36F900  		ld	(ix-7),0
3307                    	L1772:
3308    2501  DD34F0    		inc	(ix-16)
3309    2504  2003      		jr	nz,L411
3310    2506  DD34F1    		inc	(ix-15)
3311                    	L411:
3312    2509  18D0      		jr	L1572
3313                    	L1672:
3314                    	;  900              }
3315                    	;  901          if (lastallz && allzero)
3316    250B  DD7EF2    		ld	a,(ix-14)
3317    250E  DDB6F3    		or	(ix-13)
3318    2511  2822      		jr	z,L1203
3319    2513  DD7EF8    		ld	a,(ix-8)
3320    2516  DDB6F9    		or	(ix-7)
3321    2519  281A      		jr	z,L1203
3322                    	;  902              {
3323                    	;  903              if (!dotprted)
3324    251B  DD7EF4    		ld	a,(ix-12)
3325    251E  DDB6F5    		or	(ix-11)
3326    2521  C2F425    		jp	nz,L1403
3327                    	;  904                  {
3328                    	;  905                  printf("*\n");
3329    2524  217D24    		ld	hl,L5651
3330    2527  CD0000    		call	_printf
3331                    	;  906                  dotprted = YES;
3332    252A  DD36F401  		ld	(ix-12),1
3333    252E  DD36F500  		ld	(ix-11),0
3334    2532  C3F425    		jp	L1403
3335                    	L1203:
3336                    	;  907                  }
3337                    	;  908              }
3338                    	;  909          else
3339                    	;  910              {
3340                    	;  911              dotprted = NO;
3341    2535  DD36F400  		ld	(ix-12),0
3342    2539  DD36F500  		ld	(ix-11),0
3343                    	;  912              /* print offset */
3344                    	;  913              printf("%04x ", dmpline * 16);
3345    253D  DD6EF6    		ld	l,(ix-10)
3346    2540  DD66F7    		ld	h,(ix-9)
3347    2543  E5        		push	hl
3348    2544  211000    		ld	hl,16
3349    2547  E5        		push	hl
3350    2548  CD0000    		call	c.imul
3351    254B  218024    		ld	hl,L5751
3352    254E  CD0000    		call	_printf
3353    2551  F1        		pop	af
3354                    	;  914              /* print 16 bytes in hex */
3355                    	;  915              for (nbytes = 0; nbytes < 16; nbytes++)
3356    2552  DD36F000  		ld	(ix-16),0
3357    2556  DD36F100  		ld	(ix-15),0
3358                    	L1503:
3359    255A  DD7EF0    		ld	a,(ix-16)
3360    255D  D610      		sub	16
3361    255F  DD7EF1    		ld	a,(ix-15)
3362    2562  DE00      		sbc	a,0
3363    2564  F28925    		jp	p,L1603
3364                    	;  916                  printf("%02x ", prtptr[nbytes]);
3365    2567  DD6EEE    		ld	l,(ix-18)
3366    256A  DD66EF    		ld	h,(ix-17)
3367    256D  DD4EF0    		ld	c,(ix-16)
3368    2570  DD46F1    		ld	b,(ix-15)
3369    2573  09        		add	hl,bc
3370    2574  4E        		ld	c,(hl)
3371    2575  97        		sub	a
3372    2576  47        		ld	b,a
3373    2577  C5        		push	bc
3374    2578  218624    		ld	hl,L5061
3375    257B  CD0000    		call	_printf
3376    257E  F1        		pop	af
3377    257F  DD34F0    		inc	(ix-16)
3378    2582  2003      		jr	nz,L611
3379    2584  DD34F1    		inc	(ix-15)
3380                    	L611:
3381    2587  18D1      		jr	L1503
3382                    	L1603:
3383                    	;  917              /* print these bytes in ASCII if printable */
3384                    	;  918              printf(" |");
3385    2589  218C24    		ld	hl,L5161
3386    258C  CD0000    		call	_printf
3387                    	;  919              for (nbytes = 0; nbytes < 16; nbytes++)
3388    258F  DD36F000  		ld	(ix-16),0
3389    2593  DD36F100  		ld	(ix-15),0
3390                    	L1113:
3391    2597  DD7EF0    		ld	a,(ix-16)
3392    259A  D610      		sub	16
3393    259C  DD7EF1    		ld	a,(ix-15)
3394    259F  DE00      		sbc	a,0
3395    25A1  F2EE25    		jp	p,L1213
3396                    	;  920                  {
3397                    	;  921                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
3398    25A4  DD6EEE    		ld	l,(ix-18)
3399    25A7  DD66EF    		ld	h,(ix-17)
3400    25AA  DD4EF0    		ld	c,(ix-16)
3401    25AD  DD46F1    		ld	b,(ix-15)
3402    25B0  09        		add	hl,bc
3403    25B1  7E        		ld	a,(hl)
3404    25B2  FE20      		cp	32
3405    25B4  3827      		jr	c,L1513
3406    25B6  DD6EEE    		ld	l,(ix-18)
3407    25B9  DD66EF    		ld	h,(ix-17)
3408    25BC  DD4EF0    		ld	c,(ix-16)
3409    25BF  DD46F1    		ld	b,(ix-15)
3410    25C2  09        		add	hl,bc
3411    25C3  7E        		ld	a,(hl)
3412    25C4  FE7F      		cp	127
3413    25C6  3015      		jr	nc,L1513
3414                    	;  922                      putchar(prtptr[nbytes]);
3415    25C8  DD6EEE    		ld	l,(ix-18)
3416    25CB  DD66EF    		ld	h,(ix-17)
3417    25CE  DD4EF0    		ld	c,(ix-16)
3418    25D1  DD46F1    		ld	b,(ix-15)
3419    25D4  09        		add	hl,bc
3420    25D5  6E        		ld	l,(hl)
3421    25D6  97        		sub	a
3422    25D7  67        		ld	h,a
3423    25D8  CD0000    		call	_putchar
3424                    	;  923                  else
3425    25DB  1806      		jr	L1313
3426                    	L1513:
3427                    	;  924                      putchar('.');
3428    25DD  212E00    		ld	hl,46
3429    25E0  CD0000    		call	_putchar
3430                    	L1313:
3431    25E3  DD34F0    		inc	(ix-16)
3432    25E6  2003      		jr	nz,L021
3433    25E8  DD34F1    		inc	(ix-15)
3434                    	L021:
3435    25EB  C39725    		jp	L1113
3436                    	L1213:
3437                    	;  925                  }
3438                    	;  926              printf("|\n");
3439    25EE  218F24    		ld	hl,L5261
3440    25F1  CD0000    		call	_printf
3441                    	L1403:
3442                    	;  927              }
3443                    	;  928          prtptr += 16;
3444    25F4  DD6EEE    		ld	l,(ix-18)
3445    25F7  DD66EF    		ld	h,(ix-17)
3446    25FA  7D        		ld	a,l
3447    25FB  C610      		add	a,16
3448    25FD  6F        		ld	l,a
3449    25FE  7C        		ld	a,h
3450    25FF  CE00      		adc	a,0
3451    2601  67        		ld	h,a
3452    2602  DD75EE    		ld	(ix-18),l
3453    2605  DD74EF    		ld	(ix-17),h
3454                    	;  929          lastallz = allzero;
3455    2608  DD7EF8    		ld	a,(ix-8)
3456    260B  DD77F2    		ld	(ix-14),a
3457    260E  DD7EF9    		ld	a,(ix-7)
3458    2611  DD77F3    		ld	(ix-13),a
3459                    	;  930          }
3460    2614  DD34F6    		inc	(ix-10)
3461    2617  2003      		jr	nz,L211
3462    2619  DD34F7    		inc	(ix-9)
3463                    	L211:
3464    261C  C3BE24    		jp	L1172
3465                    	L1272:
3466                    	;  931      }
3467    261F  C30000    		jp	c.rets
3468                    	L5361:
3469    2622  25        		.byte	37
3470    2623  30        		.byte	48
3471    2624  32        		.byte	50
3472    2625  78        		.byte	120
3473    2626  25        		.byte	37
3474    2627  30        		.byte	48
3475    2628  32        		.byte	50
3476    2629  78        		.byte	120
3477    262A  25        		.byte	37
3478    262B  30        		.byte	48
3479    262C  32        		.byte	50
3480    262D  78        		.byte	120
3481    262E  25        		.byte	37
3482    262F  30        		.byte	48
3483    2630  32        		.byte	50
3484    2631  78        		.byte	120
3485    2632  2D        		.byte	45
3486    2633  00        		.byte	0
3487                    	L5461:
3488    2634  25        		.byte	37
3489    2635  30        		.byte	48
3490    2636  32        		.byte	50
3491    2637  78        		.byte	120
3492    2638  25        		.byte	37
3493    2639  30        		.byte	48
3494    263A  32        		.byte	50
3495    263B  78        		.byte	120
3496    263C  2D        		.byte	45
3497    263D  00        		.byte	0
3498                    	L5561:
3499    263E  25        		.byte	37
3500    263F  30        		.byte	48
3501    2640  32        		.byte	50
3502    2641  78        		.byte	120
3503    2642  25        		.byte	37
3504    2643  30        		.byte	48
3505    2644  32        		.byte	50
3506    2645  78        		.byte	120
3507    2646  2D        		.byte	45
3508    2647  00        		.byte	0
3509                    	L5661:
3510    2648  25        		.byte	37
3511    2649  30        		.byte	48
3512    264A  32        		.byte	50
3513    264B  78        		.byte	120
3514    264C  25        		.byte	37
3515    264D  30        		.byte	48
3516    264E  32        		.byte	50
3517    264F  78        		.byte	120
3518    2650  2D        		.byte	45
3519    2651  00        		.byte	0
3520                    	L5761:
3521    2652  25        		.byte	37
3522    2653  30        		.byte	48
3523    2654  32        		.byte	50
3524    2655  78        		.byte	120
3525    2656  25        		.byte	37
3526    2657  30        		.byte	48
3527    2658  32        		.byte	50
3528    2659  78        		.byte	120
3529    265A  25        		.byte	37
3530    265B  30        		.byte	48
3531    265C  32        		.byte	50
3532    265D  78        		.byte	120
3533    265E  25        		.byte	37
3534    265F  30        		.byte	48
3535    2660  32        		.byte	50
3536    2661  78        		.byte	120
3537    2662  25        		.byte	37
3538    2663  30        		.byte	48
3539    2664  32        		.byte	50
3540    2665  78        		.byte	120
3541    2666  25        		.byte	37
3542    2667  30        		.byte	48
3543    2668  32        		.byte	50
3544    2669  78        		.byte	120
3545    266A  00        		.byte	0
3546                    	L5071:
3547    266B  0A        		.byte	10
3548    266C  20        		.byte	32
3549    266D  20        		.byte	32
3550    266E  5B        		.byte	91
3551    266F  00        		.byte	0
3552                    	L5171:
3553    2670  25        		.byte	37
3554    2671  30        		.byte	48
3555    2672  32        		.byte	50
3556    2673  78        		.byte	120
3557    2674  20        		.byte	32
3558    2675  00        		.byte	0
3559                    	L5271:
3560    2676  08        		.byte	8
3561    2677  5D        		.byte	93
3562    2678  00        		.byte	0
3563                    	;  932  
3564                    	;  933  /* print GUID (mixed endian format) */
3565                    	;  934  void prtguid(unsigned char *guidptr)
3566                    	;  935      {
3567                    	_prtguid:
3568    2679  CD0000    		call	c.savs
3569    267C  F5        		push	af
3570    267D  F5        		push	af
3571    267E  F5        		push	af
3572    267F  F5        		push	af
3573                    	;  936      int index;
3574                    	;  937  
3575                    	;  938      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
3576    2680  DD6E04    		ld	l,(ix+4)
3577    2683  DD6605    		ld	h,(ix+5)
3578    2686  4E        		ld	c,(hl)
3579    2687  97        		sub	a
3580    2688  47        		ld	b,a
3581    2689  C5        		push	bc
3582    268A  DD6E04    		ld	l,(ix+4)
3583    268D  DD6605    		ld	h,(ix+5)
3584    2690  23        		inc	hl
3585    2691  4E        		ld	c,(hl)
3586    2692  97        		sub	a
3587    2693  47        		ld	b,a
3588    2694  C5        		push	bc
3589    2695  DD6E04    		ld	l,(ix+4)
3590    2698  DD6605    		ld	h,(ix+5)
3591    269B  23        		inc	hl
3592    269C  23        		inc	hl
3593    269D  4E        		ld	c,(hl)
3594    269E  97        		sub	a
3595    269F  47        		ld	b,a
3596    26A0  C5        		push	bc
3597    26A1  DD6E04    		ld	l,(ix+4)
3598    26A4  DD6605    		ld	h,(ix+5)
3599    26A7  23        		inc	hl
3600    26A8  23        		inc	hl
3601    26A9  23        		inc	hl
3602    26AA  4E        		ld	c,(hl)
3603    26AB  97        		sub	a
3604    26AC  47        		ld	b,a
3605    26AD  C5        		push	bc
3606    26AE  212226    		ld	hl,L5361
3607    26B1  CD0000    		call	_printf
3608    26B4  F1        		pop	af
3609    26B5  F1        		pop	af
3610    26B6  F1        		pop	af
3611    26B7  F1        		pop	af
3612                    	;  939      printf("%02x%02x-", guidptr[5], guidptr[4]);
3613    26B8  DD6E04    		ld	l,(ix+4)
3614    26BB  DD6605    		ld	h,(ix+5)
3615    26BE  23        		inc	hl
3616    26BF  23        		inc	hl
3617    26C0  23        		inc	hl
3618    26C1  23        		inc	hl
3619    26C2  4E        		ld	c,(hl)
3620    26C3  97        		sub	a
3621    26C4  47        		ld	b,a
3622    26C5  C5        		push	bc
3623    26C6  DD6E04    		ld	l,(ix+4)
3624    26C9  DD6605    		ld	h,(ix+5)
3625    26CC  010500    		ld	bc,5
3626    26CF  09        		add	hl,bc
3627    26D0  4E        		ld	c,(hl)
3628    26D1  97        		sub	a
3629    26D2  47        		ld	b,a
3630    26D3  C5        		push	bc
3631    26D4  213426    		ld	hl,L5461
3632    26D7  CD0000    		call	_printf
3633    26DA  F1        		pop	af
3634    26DB  F1        		pop	af
3635                    	;  940      printf("%02x%02x-", guidptr[7], guidptr[6]);
3636    26DC  DD6E04    		ld	l,(ix+4)
3637    26DF  DD6605    		ld	h,(ix+5)
3638    26E2  010600    		ld	bc,6
3639    26E5  09        		add	hl,bc
3640    26E6  4E        		ld	c,(hl)
3641    26E7  97        		sub	a
3642    26E8  47        		ld	b,a
3643    26E9  C5        		push	bc
3644    26EA  DD6E04    		ld	l,(ix+4)
3645    26ED  DD6605    		ld	h,(ix+5)
3646    26F0  010700    		ld	bc,7
3647    26F3  09        		add	hl,bc
3648    26F4  4E        		ld	c,(hl)
3649    26F5  97        		sub	a
3650    26F6  47        		ld	b,a
3651    26F7  C5        		push	bc
3652    26F8  213E26    		ld	hl,L5561
3653    26FB  CD0000    		call	_printf
3654    26FE  F1        		pop	af
3655    26FF  F1        		pop	af
3656                    	;  941      printf("%02x%02x-", guidptr[8], guidptr[9]);
3657    2700  DD6E04    		ld	l,(ix+4)
3658    2703  DD6605    		ld	h,(ix+5)
3659    2706  010900    		ld	bc,9
3660    2709  09        		add	hl,bc
3661    270A  4E        		ld	c,(hl)
3662    270B  97        		sub	a
3663    270C  47        		ld	b,a
3664    270D  C5        		push	bc
3665    270E  DD6E04    		ld	l,(ix+4)
3666    2711  DD6605    		ld	h,(ix+5)
3667    2714  010800    		ld	bc,8
3668    2717  09        		add	hl,bc
3669    2718  4E        		ld	c,(hl)
3670    2719  97        		sub	a
3671    271A  47        		ld	b,a
3672    271B  C5        		push	bc
3673    271C  214826    		ld	hl,L5661
3674    271F  CD0000    		call	_printf
3675    2722  F1        		pop	af
3676    2723  F1        		pop	af
3677                    	;  942      printf("%02x%02x%02x%02x%02x%02x",
3678                    	;  943             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
3679    2724  DD6E04    		ld	l,(ix+4)
3680    2727  DD6605    		ld	h,(ix+5)
3681    272A  010F00    		ld	bc,15
3682    272D  09        		add	hl,bc
3683    272E  4E        		ld	c,(hl)
3684    272F  97        		sub	a
3685    2730  47        		ld	b,a
3686    2731  C5        		push	bc
3687    2732  DD6E04    		ld	l,(ix+4)
3688    2735  DD6605    		ld	h,(ix+5)
3689    2738  010E00    		ld	bc,14
3690    273B  09        		add	hl,bc
3691    273C  4E        		ld	c,(hl)
3692    273D  97        		sub	a
3693    273E  47        		ld	b,a
3694    273F  C5        		push	bc
3695    2740  DD6E04    		ld	l,(ix+4)
3696    2743  DD6605    		ld	h,(ix+5)
3697    2746  010D00    		ld	bc,13
3698    2749  09        		add	hl,bc
3699    274A  4E        		ld	c,(hl)
3700    274B  97        		sub	a
3701    274C  47        		ld	b,a
3702    274D  C5        		push	bc
3703    274E  DD6E04    		ld	l,(ix+4)
3704    2751  DD6605    		ld	h,(ix+5)
3705    2754  010C00    		ld	bc,12
3706    2757  09        		add	hl,bc
3707    2758  4E        		ld	c,(hl)
3708    2759  97        		sub	a
3709    275A  47        		ld	b,a
3710    275B  C5        		push	bc
3711    275C  DD6E04    		ld	l,(ix+4)
3712    275F  DD6605    		ld	h,(ix+5)
3713    2762  010B00    		ld	bc,11
3714    2765  09        		add	hl,bc
3715    2766  4E        		ld	c,(hl)
3716    2767  97        		sub	a
3717    2768  47        		ld	b,a
3718    2769  C5        		push	bc
3719    276A  DD6E04    		ld	l,(ix+4)
3720    276D  DD6605    		ld	h,(ix+5)
3721    2770  010A00    		ld	bc,10
3722    2773  09        		add	hl,bc
3723    2774  4E        		ld	c,(hl)
3724    2775  97        		sub	a
3725    2776  47        		ld	b,a
3726    2777  C5        		push	bc
3727    2778  215226    		ld	hl,L5761
3728    277B  CD0000    		call	_printf
3729    277E  210C00    		ld	hl,12
3730    2781  39        		add	hl,sp
3731    2782  F9        		ld	sp,hl
3732                    	;  944      printf("\n  [");
3733    2783  216B26    		ld	hl,L5071
3734    2786  CD0000    		call	_printf
3735                    	;  945      for (index = 0; index < 16; index++)
3736    2789  DD36F800  		ld	(ix-8),0
3737    278D  DD36F900  		ld	(ix-7),0
3738                    	L1713:
3739    2791  DD7EF8    		ld	a,(ix-8)
3740    2794  D610      		sub	16
3741    2796  DD7EF9    		ld	a,(ix-7)
3742    2799  DE00      		sbc	a,0
3743    279B  F2C027    		jp	p,L1023
3744                    	;  946          printf("%02x ", guidptr[index]);
3745    279E  DD6E04    		ld	l,(ix+4)
3746    27A1  DD6605    		ld	h,(ix+5)
3747    27A4  DD4EF8    		ld	c,(ix-8)
3748    27A7  DD46F9    		ld	b,(ix-7)
3749    27AA  09        		add	hl,bc
3750    27AB  4E        		ld	c,(hl)
3751    27AC  97        		sub	a
3752    27AD  47        		ld	b,a
3753    27AE  C5        		push	bc
3754    27AF  217026    		ld	hl,L5171
3755    27B2  CD0000    		call	_printf
3756    27B5  F1        		pop	af
3757    27B6  DD34F8    		inc	(ix-8)
3758    27B9  2003      		jr	nz,L421
3759    27BB  DD34F9    		inc	(ix-7)
3760                    	L421:
3761    27BE  18D1      		jr	L1713
3762                    	L1023:
3763                    	;  947      printf("\b]");
3764    27C0  217626    		ld	hl,L5271
3765    27C3  CD0000    		call	_printf
3766                    	;  948      }
3767    27C6  C30000    		jp	c.rets
3768                    	L5371:
3769    27C9  43        		.byte	67
3770    27CA  61        		.byte	97
3771    27CB  6E        		.byte	110
3772    27CC  27        		.byte	39
3773    27CD  74        		.byte	116
3774    27CE  20        		.byte	32
3775    27CF  72        		.byte	114
3776    27D0  65        		.byte	101
3777    27D1  61        		.byte	97
3778    27D2  64        		.byte	100
3779    27D3  20        		.byte	32
3780    27D4  47        		.byte	71
3781    27D5  50        		.byte	80
3782    27D6  54        		.byte	84
3783    27D7  20        		.byte	32
3784    27D8  65        		.byte	101
3785    27D9  6E        		.byte	110
3786    27DA  74        		.byte	116
3787    27DB  72        		.byte	114
3788    27DC  79        		.byte	121
3789    27DD  20        		.byte	32
3790    27DE  62        		.byte	98
3791    27DF  6C        		.byte	108
3792    27E0  6F        		.byte	111
3793    27E1  63        		.byte	99
3794    27E2  6B        		.byte	107
3795    27E3  0A        		.byte	10
3796    27E4  00        		.byte	0
3797                    	L5471:
3798    27E5  47        		.byte	71
3799    27E6  50        		.byte	80
3800    27E7  54        		.byte	84
3801    27E8  20        		.byte	32
3802    27E9  70        		.byte	112
3803    27EA  61        		.byte	97
3804    27EB  72        		.byte	114
3805    27EC  74        		.byte	116
3806    27ED  69        		.byte	105
3807    27EE  74        		.byte	116
3808    27EF  69        		.byte	105
3809    27F0  6F        		.byte	111
3810    27F1  6E        		.byte	110
3811    27F2  20        		.byte	32
3812    27F3  65        		.byte	101
3813    27F4  6E        		.byte	110
3814    27F5  74        		.byte	116
3815    27F6  72        		.byte	114
3816    27F7  79        		.byte	121
3817    27F8  20        		.byte	32
3818    27F9  25        		.byte	37
3819    27FA  64        		.byte	100
3820    27FB  3A        		.byte	58
3821    27FC  00        		.byte	0
3822                    	L5571:
3823    27FD  20        		.byte	32
3824    27FE  4E        		.byte	78
3825    27FF  6F        		.byte	111
3826    2800  74        		.byte	116
3827    2801  20        		.byte	32
3828    2802  75        		.byte	117
3829    2803  73        		.byte	115
3830    2804  65        		.byte	101
3831    2805  64        		.byte	100
3832    2806  20        		.byte	32
3833    2807  65        		.byte	101
3834    2808  6E        		.byte	110
3835    2809  74        		.byte	116
3836    280A  72        		.byte	114
3837    280B  79        		.byte	121
3838    280C  0A        		.byte	10
3839    280D  00        		.byte	0
3840                    	L5671:
3841    280E  0A        		.byte	10
3842    280F  20        		.byte	32
3843    2810  20        		.byte	32
3844    2811  50        		.byte	80
3845    2812  61        		.byte	97
3846    2813  72        		.byte	114
3847    2814  74        		.byte	116
3848    2815  69        		.byte	105
3849    2816  74        		.byte	116
3850    2817  69        		.byte	105
3851    2818  6F        		.byte	111
3852    2819  6E        		.byte	110
3853    281A  20        		.byte	32
3854    281B  74        		.byte	116
3855    281C  79        		.byte	121
3856    281D  70        		.byte	112
3857    281E  65        		.byte	101
3858    281F  20        		.byte	32
3859    2820  47        		.byte	71
3860    2821  55        		.byte	85
3861    2822  49        		.byte	73
3862    2823  44        		.byte	68
3863    2824  3A        		.byte	58
3864    2825  20        		.byte	32
3865    2826  00        		.byte	0
3866                    	L5771:
3867    2827  0A        		.byte	10
3868    2828  20        		.byte	32
3869    2829  20        		.byte	32
3870    282A  55        		.byte	85
3871    282B  6E        		.byte	110
3872    282C  69        		.byte	105
3873    282D  71        		.byte	113
3874    282E  75        		.byte	117
3875    282F  65        		.byte	101
3876    2830  20        		.byte	32
3877    2831  70        		.byte	112
3878    2832  61        		.byte	97
3879    2833  72        		.byte	114
3880    2834  74        		.byte	116
3881    2835  69        		.byte	105
3882    2836  74        		.byte	116
3883    2837  69        		.byte	105
3884    2838  6F        		.byte	111
3885    2839  6E        		.byte	110
3886    283A  20        		.byte	32
3887    283B  47        		.byte	71
3888    283C  55        		.byte	85
3889    283D  49        		.byte	73
3890    283E  44        		.byte	68
3891    283F  3A        		.byte	58
3892    2840  20        		.byte	32
3893    2841  00        		.byte	0
3894                    	L5002:
3895    2842  0A        		.byte	10
3896    2843  20        		.byte	32
3897    2844  20        		.byte	32
3898    2845  46        		.byte	70
3899    2846  69        		.byte	105
3900    2847  72        		.byte	114
3901    2848  73        		.byte	115
3902    2849  74        		.byte	116
3903    284A  20        		.byte	32
3904    284B  4C        		.byte	76
3905    284C  42        		.byte	66
3906    284D  41        		.byte	65
3907    284E  3A        		.byte	58
3908    284F  20        		.byte	32
3909    2850  00        		.byte	0
3910                    	L5102:
3911    2851  25        		.byte	37
3912    2852  6C        		.byte	108
3913    2853  75        		.byte	117
3914    2854  00        		.byte	0
3915                    	L5202:
3916    2855  20        		.byte	32
3917    2856  5B        		.byte	91
3918    2857  00        		.byte	0
3919                    	L5302:
3920    2858  25        		.byte	37
3921    2859  30        		.byte	48
3922    285A  32        		.byte	50
3923    285B  78        		.byte	120
3924    285C  20        		.byte	32
3925    285D  00        		.byte	0
3926                    	L5402:
3927    285E  08        		.byte	8
3928    285F  5D        		.byte	93
3929    2860  00        		.byte	0
3930                    	L5502:
3931    2861  0A        		.byte	10
3932    2862  20        		.byte	32
3933    2863  20        		.byte	32
3934    2864  4C        		.byte	76
3935    2865  61        		.byte	97
3936    2866  73        		.byte	115
3937    2867  74        		.byte	116
3938    2868  20        		.byte	32
3939    2869  4C        		.byte	76
3940    286A  42        		.byte	66
3941    286B  41        		.byte	65
3942    286C  3A        		.byte	58
3943    286D  20        		.byte	32
3944    286E  00        		.byte	0
3945                    	L5602:
3946    286F  25        		.byte	37
3947    2870  6C        		.byte	108
3948    2871  75        		.byte	117
3949    2872  2C        		.byte	44
3950    2873  20        		.byte	32
3951    2874  73        		.byte	115
3952    2875  69        		.byte	105
3953    2876  7A        		.byte	122
3954    2877  65        		.byte	101
3955    2878  20        		.byte	32
3956    2879  25        		.byte	37
3957    287A  6C        		.byte	108
3958    287B  75        		.byte	117
3959    287C  20        		.byte	32
3960    287D  4D        		.byte	77
3961    287E  42        		.byte	66
3962    287F  79        		.byte	121
3963    2880  74        		.byte	116
3964    2881  65        		.byte	101
3965    2882  00        		.byte	0
3966                    	L5702:
3967    2883  20        		.byte	32
3968    2884  5B        		.byte	91
3969    2885  00        		.byte	0
3970                    	L5012:
3971    2886  25        		.byte	37
3972    2887  30        		.byte	48
3973    2888  32        		.byte	50
3974    2889  78        		.byte	120
3975    288A  20        		.byte	32
3976    288B  00        		.byte	0
3977                    	L5112:
3978    288C  08        		.byte	8
3979    288D  5D        		.byte	93
3980    288E  00        		.byte	0
3981                    	L5212:
3982    288F  0A        		.byte	10
3983    2890  20        		.byte	32
3984    2891  20        		.byte	32
3985    2892  41        		.byte	65
3986    2893  74        		.byte	116
3987    2894  74        		.byte	116
3988    2895  72        		.byte	114
3989    2896  69        		.byte	105
3990    2897  62        		.byte	98
3991    2898  75        		.byte	117
3992    2899  74        		.byte	116
3993    289A  65        		.byte	101
3994    289B  20        		.byte	32
3995    289C  66        		.byte	102
3996    289D  6C        		.byte	108
3997    289E  61        		.byte	97
3998    289F  67        		.byte	103
3999    28A0  73        		.byte	115
4000    28A1  3A        		.byte	58
4001    28A2  20        		.byte	32
4002    28A3  5B        		.byte	91
4003    28A4  00        		.byte	0
4004                    	L5312:
4005    28A5  25        		.byte	37
4006    28A6  30        		.byte	48
4007    28A7  32        		.byte	50
4008    28A8  78        		.byte	120
4009    28A9  20        		.byte	32
4010    28AA  00        		.byte	0
4011                    	L5412:
4012    28AB  08        		.byte	8
4013    28AC  5D        		.byte	93
4014    28AD  0A        		.byte	10
4015    28AE  20        		.byte	32
4016    28AF  20        		.byte	32
4017    28B0  50        		.byte	80
4018    28B1  61        		.byte	97
4019    28B2  72        		.byte	114
4020    28B3  74        		.byte	116
4021    28B4  69        		.byte	105
4022    28B5  74        		.byte	116
4023    28B6  69        		.byte	105
4024    28B7  6F        		.byte	111
4025    28B8  6E        		.byte	110
4026    28B9  20        		.byte	32
4027    28BA  6E        		.byte	110
4028    28BB  61        		.byte	97
4029    28BC  6D        		.byte	109
4030    28BD  65        		.byte	101
4031    28BE  3A        		.byte	58
4032    28BF  20        		.byte	32
4033    28C0  20        		.byte	32
4034    28C1  00        		.byte	0
4035                    	L5512:
4036    28C2  6E        		.byte	110
4037    28C3  61        		.byte	97
4038    28C4  6D        		.byte	109
4039    28C5  65        		.byte	101
4040    28C6  20        		.byte	32
4041    28C7  66        		.byte	102
4042    28C8  69        		.byte	105
4043    28C9  65        		.byte	101
4044    28CA  6C        		.byte	108
4045    28CB  64        		.byte	100
4046    28CC  20        		.byte	32
4047    28CD  65        		.byte	101
4048    28CE  6D        		.byte	109
4049    28CF  70        		.byte	112
4050    28D0  74        		.byte	116
4051    28D1  79        		.byte	121
4052    28D2  00        		.byte	0
4053                    	L5612:
4054    28D3  0A        		.byte	10
4055    28D4  00        		.byte	0
4056                    	L5712:
4057    28D5  20        		.byte	32
4058    28D6  20        		.byte	32
4059    28D7  20        		.byte	32
4060    28D8  5B        		.byte	91
4061    28D9  00        		.byte	0
4062                    	L5022:
4063    28DA  0A        		.byte	10
4064    28DB  20        		.byte	32
4065    28DC  20        		.byte	32
4066    28DD  20        		.byte	32
4067    28DE  20        		.byte	32
4068    28DF  00        		.byte	0
4069                    	L5122:
4070    28E0  25        		.byte	37
4071    28E1  30        		.byte	48
4072    28E2  32        		.byte	50
4073    28E3  78        		.byte	120
4074    28E4  20        		.byte	32
4075    28E5  00        		.byte	0
4076                    	L5222:
4077    28E6  08        		.byte	8
4078    28E7  5D        		.byte	93
4079    28E8  0A        		.byte	10
4080    28E9  00        		.byte	0
4081                    	;  949  
4082                    	;  950  /* print GPT entry */
4083                    	;  951  void prtgptent(unsigned int entryno)
4084                    	;  952      {
4085                    	_prtgptent:
4086    28EA  CD0000    		call	c.savs
4087    28ED  21E4FF    		ld	hl,65508
4088    28F0  39        		add	hl,sp
4089    28F1  F9        		ld	sp,hl
4090                    	;  953      int index;
4091                    	;  954      int entryidx;
4092                    	;  955      int hasname;
4093                    	;  956      unsigned int block;
4094                    	;  957      unsigned char *rxdata;
4095                    	;  958      unsigned char *entryptr;
   0                    	;  959      unsigned char tstzero = 0;
   1    28F2  DD36ED00  		ld	(ix-19),0
   2                    	;  960      unsigned long flba;
   3                    	;  961      unsigned long llba;
   4                    	;  962  
   5                    	;  963      block = 2 + (entryno / 4);
   6    28F6  DD6E04    		ld	l,(ix+4)
   7    28F9  DD6605    		ld	h,(ix+5)
   8    28FC  E5        		push	hl
   9    28FD  210400    		ld	hl,4
  10    2900  E5        		push	hl
  11    2901  CD0000    		call	c.udiv
  12    2904  E1        		pop	hl
  13    2905  23        		inc	hl
  14    2906  23        		inc	hl
  15    2907  DD75F2    		ld	(ix-14),l
  16    290A  DD74F3    		ld	(ix-13),h
  17                    	;  964      if ((curblkno != block) || !curblkok)
  18    290D  210000    		ld	hl,_curblkno
  19    2910  E5        		push	hl
  20    2911  DDE5      		push	ix
  21    2913  C1        		pop	bc
  22    2914  21F2FF    		ld	hl,65522
  23    2917  09        		add	hl,bc
  24    2918  4D        		ld	c,l
  25    2919  44        		ld	b,h
  26    291A  97        		sub	a
  27    291B  320000    		ld	(c.r0),a
  28    291E  320100    		ld	(c.r0+1),a
  29    2921  0A        		ld	a,(bc)
  30    2922  320200    		ld	(c.r0+2),a
  31    2925  03        		inc	bc
  32    2926  0A        		ld	a,(bc)
  33    2927  320300    		ld	(c.r0+3),a
  34    292A  210000    		ld	hl,c.r0
  35    292D  E5        		push	hl
  36    292E  CD0000    		call	c.lcmp
  37    2931  2008      		jr	nz,L1423
  38    2933  2A0C00    		ld	hl,(_curblkok)
  39    2936  7C        		ld	a,h
  40    2937  B5        		or	l
  41    2938  C28E29    		jp	nz,L1323
  42                    	L1423:
  43                    	;  965          {
  44                    	;  966          if (!sdread(sdrdbuf, block))
  45    293B  DDE5      		push	ix
  46    293D  C1        		pop	bc
  47    293E  21F2FF    		ld	hl,65522
  48    2941  09        		add	hl,bc
  49    2942  4D        		ld	c,l
  50    2943  44        		ld	b,h
  51    2944  97        		sub	a
  52    2945  320000    		ld	(c.r0),a
  53    2948  320100    		ld	(c.r0+1),a
  54    294B  0A        		ld	a,(bc)
  55    294C  320200    		ld	(c.r0+2),a
  56    294F  03        		inc	bc
  57    2950  0A        		ld	a,(bc)
  58    2951  320300    		ld	(c.r0+3),a
  59    2954  210300    		ld	hl,c.r0+3
  60    2957  46        		ld	b,(hl)
  61    2958  2B        		dec	hl
  62    2959  4E        		ld	c,(hl)
  63    295A  C5        		push	bc
  64    295B  2B        		dec	hl
  65    295C  46        		ld	b,(hl)
  66    295D  2B        		dec	hl
  67    295E  4E        		ld	c,(hl)
  68    295F  C5        		push	bc
  69    2960  213200    		ld	hl,_sdrdbuf
  70    2963  CD671E    		call	_sdread
  71    2966  F1        		pop	af
  72    2967  F1        		pop	af
  73    2968  79        		ld	a,c
  74    2969  B0        		or	b
  75    296A  2009      		jr	nz,L1523
  76                    	;  967              {
  77                    	;  968              printf("Can't read GPT entry block\n");
  78    296C  21C927    		ld	hl,L5371
  79    296F  CD0000    		call	_printf
  80                    	;  969              return;
  81    2972  C30000    		jp	c.rets
  82                    	L1523:
  83                    	;  970              }
  84                    	;  971          curblkno = block;
  85    2975  97        		sub	a
  86    2976  320000    		ld	(_curblkno),a
  87    2979  320100    		ld	(_curblkno+1),a
  88    297C  DD7EF2    		ld	a,(ix-14)
  89    297F  320200    		ld	(_curblkno+2),a
  90                    	;  972          curblkok = YES;
  91    2982  210100    		ld	hl,1
  92    2985  DD7EF3    		ld	a,(ix-13)
  93    2988  320300    		ld	(_curblkno+3),a
  94    298B  220C00    		ld	(_curblkok),hl
  95                    	L1323:
  96                    	;  973          }
  97                    	;  974      rxdata = sdrdbuf;
  98    298E  213200    		ld	hl,_sdrdbuf
  99    2991  DD75F0    		ld	(ix-16),l
 100    2994  DD74F1    		ld	(ix-15),h
 101                    	;  975      entryptr = rxdata + (128 * (entryno % 4));
 102    2997  DD6E04    		ld	l,(ix+4)
 103    299A  DD6605    		ld	h,(ix+5)
 104    299D  E5        		push	hl
 105    299E  210400    		ld	hl,4
 106    29A1  E5        		push	hl
 107    29A2  CD0000    		call	c.umod
 108    29A5  218000    		ld	hl,128
 109    29A8  E5        		push	hl
 110    29A9  CD0000    		call	c.imul
 111    29AC  E1        		pop	hl
 112    29AD  DD4EF0    		ld	c,(ix-16)
 113    29B0  DD46F1    		ld	b,(ix-15)
 114    29B3  09        		add	hl,bc
 115    29B4  DD75EE    		ld	(ix-18),l
 116    29B7  DD74EF    		ld	(ix-17),h
 117                    	;  976      for (index = 0; index < 16; index++)
 118    29BA  DD36F800  		ld	(ix-8),0
 119    29BE  DD36F900  		ld	(ix-7),0
 120                    	L1623:
 121    29C2  DD7EF8    		ld	a,(ix-8)
 122    29C5  D610      		sub	16
 123    29C7  DD7EF9    		ld	a,(ix-7)
 124    29CA  DE00      		sbc	a,0
 125    29CC  F2ED29    		jp	p,L1723
 126                    	;  977          tstzero |= entryptr[index];
 127    29CF  DD6EEE    		ld	l,(ix-18)
 128    29D2  DD66EF    		ld	h,(ix-17)
 129    29D5  DD4EF8    		ld	c,(ix-8)
 130    29D8  DD46F9    		ld	b,(ix-7)
 131    29DB  09        		add	hl,bc
 132    29DC  DD7EED    		ld	a,(ix-19)
 133    29DF  B6        		or	(hl)
 134    29E0  DD77ED    		ld	(ix-19),a
 135    29E3  DD34F8    		inc	(ix-8)
 136    29E6  2003      		jr	nz,L031
 137    29E8  DD34F9    		inc	(ix-7)
 138                    	L031:
 139    29EB  18D5      		jr	L1623
 140                    	L1723:
 141                    	;  978      printf("GPT partition entry %d:", entryno + 1);
 142    29ED  DD6E04    		ld	l,(ix+4)
 143    29F0  DD6605    		ld	h,(ix+5)
 144    29F3  23        		inc	hl
 145    29F4  E5        		push	hl
 146    29F5  21E527    		ld	hl,L5471
 147    29F8  CD0000    		call	_printf
 148    29FB  F1        		pop	af
 149                    	;  979      if (!tstzero)
 150    29FC  DD7EED    		ld	a,(ix-19)
 151    29FF  B7        		or	a
 152    2A00  2009      		jr	nz,L1233
 153                    	;  980          {
 154                    	;  981          printf(" Not used entry\n");
 155    2A02  21FD27    		ld	hl,L5571
 156    2A05  CD0000    		call	_printf
 157                    	;  982          return;
 158    2A08  C30000    		jp	c.rets
 159                    	L1233:
 160                    	;  983          }
 161                    	;  984      printf("\n  Partition type GUID: ");
 162    2A0B  210E28    		ld	hl,L5671
 163    2A0E  CD0000    		call	_printf
 164                    	;  985      prtguid(entryptr);
 165    2A11  DD6EEE    		ld	l,(ix-18)
 166    2A14  DD66EF    		ld	h,(ix-17)
 167    2A17  CD7926    		call	_prtguid
 168                    	;  986      printf("\n  Unique partition GUID: ");
 169    2A1A  212728    		ld	hl,L5771
 170    2A1D  CD0000    		call	_printf
 171                    	;  987      prtguid(entryptr + 16);
 172    2A20  DD6EEE    		ld	l,(ix-18)
 173    2A23  DD66EF    		ld	h,(ix-17)
 174    2A26  011000    		ld	bc,16
 175    2A29  09        		add	hl,bc
 176    2A2A  CD7926    		call	_prtguid
 177                    	;  988      printf("\n  First LBA: ");
 178    2A2D  214228    		ld	hl,L5002
 179    2A30  CD0000    		call	_printf
 180                    	;  989      /* lower 32 bits of LBA should be sufficient (I hope) */
 181                    	;  990      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
 182                    	;  991             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
 183    2A33  DDE5      		push	ix
 184    2A35  C1        		pop	bc
 185    2A36  21E8FF    		ld	hl,65512
 186    2A39  09        		add	hl,bc
 187    2A3A  E5        		push	hl
 188    2A3B  DD6EEE    		ld	l,(ix-18)
 189    2A3E  DD66EF    		ld	h,(ix-17)
 190    2A41  012000    		ld	bc,32
 191    2A44  09        		add	hl,bc
 192    2A45  4D        		ld	c,l
 193    2A46  44        		ld	b,h
 194    2A47  97        		sub	a
 195    2A48  320000    		ld	(c.r0),a
 196    2A4B  320100    		ld	(c.r0+1),a
 197    2A4E  0A        		ld	a,(bc)
 198    2A4F  320200    		ld	(c.r0+2),a
 199    2A52  97        		sub	a
 200    2A53  320300    		ld	(c.r0+3),a
 201    2A56  210000    		ld	hl,c.r0
 202    2A59  E5        		push	hl
 203    2A5A  DD6EEE    		ld	l,(ix-18)
 204    2A5D  DD66EF    		ld	h,(ix-17)
 205    2A60  012100    		ld	bc,33
 206    2A63  09        		add	hl,bc
 207    2A64  4D        		ld	c,l
 208    2A65  44        		ld	b,h
 209    2A66  97        		sub	a
 210    2A67  320000    		ld	(c.r1),a
 211    2A6A  320100    		ld	(c.r1+1),a
 212    2A6D  0A        		ld	a,(bc)
 213    2A6E  320200    		ld	(c.r1+2),a
 214    2A71  97        		sub	a
 215    2A72  320300    		ld	(c.r1+3),a
 216    2A75  210000    		ld	hl,c.r1
 217    2A78  E5        		push	hl
 218    2A79  210800    		ld	hl,8
 219    2A7C  E5        		push	hl
 220    2A7D  CD0000    		call	c.llsh
 221    2A80  CD0000    		call	c.ladd
 222    2A83  DD6EEE    		ld	l,(ix-18)
 223    2A86  DD66EF    		ld	h,(ix-17)
 224    2A89  012200    		ld	bc,34
 225    2A8C  09        		add	hl,bc
 226    2A8D  4D        		ld	c,l
 227    2A8E  44        		ld	b,h
 228    2A8F  97        		sub	a
 229    2A90  320000    		ld	(c.r1),a
 230    2A93  320100    		ld	(c.r1+1),a
 231    2A96  0A        		ld	a,(bc)
 232    2A97  320200    		ld	(c.r1+2),a
 233    2A9A  97        		sub	a
 234    2A9B  320300    		ld	(c.r1+3),a
 235    2A9E  210000    		ld	hl,c.r1
 236    2AA1  E5        		push	hl
 237    2AA2  211000    		ld	hl,16
 238    2AA5  E5        		push	hl
 239    2AA6  CD0000    		call	c.llsh
 240    2AA9  CD0000    		call	c.ladd
 241    2AAC  DD6EEE    		ld	l,(ix-18)
 242    2AAF  DD66EF    		ld	h,(ix-17)
 243    2AB2  012300    		ld	bc,35
 244    2AB5  09        		add	hl,bc
 245    2AB6  4D        		ld	c,l
 246    2AB7  44        		ld	b,h
 247    2AB8  97        		sub	a
 248    2AB9  320000    		ld	(c.r1),a
 249    2ABC  320100    		ld	(c.r1+1),a
 250    2ABF  0A        		ld	a,(bc)
 251    2AC0  320200    		ld	(c.r1+2),a
 252    2AC3  97        		sub	a
 253    2AC4  320300    		ld	(c.r1+3),a
 254    2AC7  210000    		ld	hl,c.r1
 255    2ACA  E5        		push	hl
 256    2ACB  211800    		ld	hl,24
 257    2ACE  E5        		push	hl
 258    2ACF  CD0000    		call	c.llsh
 259    2AD2  CD0000    		call	c.ladd
 260    2AD5  CD0000    		call	c.mvl
 261    2AD8  F1        		pop	af
 262                    	;  992      printf("%lu", flba);
 263    2AD9  DD66EB    		ld	h,(ix-21)
 264    2ADC  DD6EEA    		ld	l,(ix-22)
 265    2ADF  E5        		push	hl
 266    2AE0  DD66E9    		ld	h,(ix-23)
 267    2AE3  DD6EE8    		ld	l,(ix-24)
 268    2AE6  E5        		push	hl
 269    2AE7  215128    		ld	hl,L5102
 270    2AEA  CD0000    		call	_printf
 271    2AED  F1        		pop	af
 272    2AEE  F1        		pop	af
 273                    	;  993      printf(" [");
 274    2AEF  215528    		ld	hl,L5202
 275    2AF2  CD0000    		call	_printf
 276                    	;  994      for (index = 32; index < (32 + 8); index++)
 277    2AF5  DD36F820  		ld	(ix-8),32
 278    2AF9  DD36F900  		ld	(ix-7),0
 279                    	L1333:
 280    2AFD  DD7EF8    		ld	a,(ix-8)
 281    2B00  D628      		sub	40
 282    2B02  DD7EF9    		ld	a,(ix-7)
 283    2B05  DE00      		sbc	a,0
 284    2B07  F22C2B    		jp	p,L1433
 285                    	;  995          printf("%02x ", entryptr[index]);
 286    2B0A  DD6EEE    		ld	l,(ix-18)
 287    2B0D  DD66EF    		ld	h,(ix-17)
 288    2B10  DD4EF8    		ld	c,(ix-8)
 289    2B13  DD46F9    		ld	b,(ix-7)
 290    2B16  09        		add	hl,bc
 291    2B17  4E        		ld	c,(hl)
 292    2B18  97        		sub	a
 293    2B19  47        		ld	b,a
 294    2B1A  C5        		push	bc
 295    2B1B  215828    		ld	hl,L5302
 296    2B1E  CD0000    		call	_printf
 297    2B21  F1        		pop	af
 298    2B22  DD34F8    		inc	(ix-8)
 299    2B25  2003      		jr	nz,L231
 300    2B27  DD34F9    		inc	(ix-7)
 301                    	L231:
 302    2B2A  18D1      		jr	L1333
 303                    	L1433:
 304                    	;  996      printf("\b]");
 305    2B2C  215E28    		ld	hl,L5402
 306    2B2F  CD0000    		call	_printf
 307                    	;  997      printf("\n  Last LBA: ");
 308    2B32  216128    		ld	hl,L5502
 309    2B35  CD0000    		call	_printf
 310                    	;  998      /* lower 32 bits of LBA should be sufficient (I hope) */
 311                    	;  999      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
 312                    	; 1000             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
 313    2B38  DDE5      		push	ix
 314    2B3A  C1        		pop	bc
 315    2B3B  21E4FF    		ld	hl,65508
 316    2B3E  09        		add	hl,bc
 317    2B3F  E5        		push	hl
 318    2B40  DD6EEE    		ld	l,(ix-18)
 319    2B43  DD66EF    		ld	h,(ix-17)
 320    2B46  012800    		ld	bc,40
 321    2B49  09        		add	hl,bc
 322    2B4A  4D        		ld	c,l
 323    2B4B  44        		ld	b,h
 324    2B4C  97        		sub	a
 325    2B4D  320000    		ld	(c.r0),a
 326    2B50  320100    		ld	(c.r0+1),a
 327    2B53  0A        		ld	a,(bc)
 328    2B54  320200    		ld	(c.r0+2),a
 329    2B57  97        		sub	a
 330    2B58  320300    		ld	(c.r0+3),a
 331    2B5B  210000    		ld	hl,c.r0
 332    2B5E  E5        		push	hl
 333    2B5F  DD6EEE    		ld	l,(ix-18)
 334    2B62  DD66EF    		ld	h,(ix-17)
 335    2B65  012900    		ld	bc,41
 336    2B68  09        		add	hl,bc
 337    2B69  4D        		ld	c,l
 338    2B6A  44        		ld	b,h
 339    2B6B  97        		sub	a
 340    2B6C  320000    		ld	(c.r1),a
 341    2B6F  320100    		ld	(c.r1+1),a
 342    2B72  0A        		ld	a,(bc)
 343    2B73  320200    		ld	(c.r1+2),a
 344    2B76  97        		sub	a
 345    2B77  320300    		ld	(c.r1+3),a
 346    2B7A  210000    		ld	hl,c.r1
 347    2B7D  E5        		push	hl
 348    2B7E  210800    		ld	hl,8
 349    2B81  E5        		push	hl
 350    2B82  CD0000    		call	c.llsh
 351    2B85  CD0000    		call	c.ladd
 352    2B88  DD6EEE    		ld	l,(ix-18)
 353    2B8B  DD66EF    		ld	h,(ix-17)
 354    2B8E  012A00    		ld	bc,42
 355    2B91  09        		add	hl,bc
 356    2B92  4D        		ld	c,l
 357    2B93  44        		ld	b,h
 358    2B94  97        		sub	a
 359    2B95  320000    		ld	(c.r1),a
 360    2B98  320100    		ld	(c.r1+1),a
 361    2B9B  0A        		ld	a,(bc)
 362    2B9C  320200    		ld	(c.r1+2),a
 363    2B9F  97        		sub	a
 364    2BA0  320300    		ld	(c.r1+3),a
 365    2BA3  210000    		ld	hl,c.r1
 366    2BA6  E5        		push	hl
 367    2BA7  211000    		ld	hl,16
 368    2BAA  E5        		push	hl
 369    2BAB  CD0000    		call	c.llsh
 370    2BAE  CD0000    		call	c.ladd
 371    2BB1  DD6EEE    		ld	l,(ix-18)
 372    2BB4  DD66EF    		ld	h,(ix-17)
 373    2BB7  012B00    		ld	bc,43
 374    2BBA  09        		add	hl,bc
 375    2BBB  4D        		ld	c,l
 376    2BBC  44        		ld	b,h
 377    2BBD  97        		sub	a
 378    2BBE  320000    		ld	(c.r1),a
 379    2BC1  320100    		ld	(c.r1+1),a
 380    2BC4  0A        		ld	a,(bc)
 381    2BC5  320200    		ld	(c.r1+2),a
 382    2BC8  97        		sub	a
 383    2BC9  320300    		ld	(c.r1+3),a
 384    2BCC  210000    		ld	hl,c.r1
 385    2BCF  E5        		push	hl
 386    2BD0  211800    		ld	hl,24
 387    2BD3  E5        		push	hl
 388    2BD4  CD0000    		call	c.llsh
 389    2BD7  CD0000    		call	c.ladd
 390    2BDA  CD0000    		call	c.mvl
 391    2BDD  F1        		pop	af
 392                    	; 1001      printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
 393    2BDE  DDE5      		push	ix
 394    2BE0  C1        		pop	bc
 395    2BE1  21E4FF    		ld	hl,65508
 396    2BE4  09        		add	hl,bc
 397    2BE5  CD0000    		call	c.0mvf
 398    2BE8  210000    		ld	hl,c.r0
 399    2BEB  E5        		push	hl
 400    2BEC  DDE5      		push	ix
 401    2BEE  C1        		pop	bc
 402    2BEF  21E8FF    		ld	hl,65512
 403    2BF2  09        		add	hl,bc
 404    2BF3  E5        		push	hl
 405    2BF4  CD0000    		call	c.lsub
 406    2BF7  210B00    		ld	hl,11
 407    2BFA  E5        		push	hl
 408    2BFB  CD0000    		call	c.ulrsh
 409    2BFE  E1        		pop	hl
 410    2BFF  23        		inc	hl
 411    2C00  23        		inc	hl
 412    2C01  4E        		ld	c,(hl)
 413    2C02  23        		inc	hl
 414    2C03  46        		ld	b,(hl)
 415    2C04  C5        		push	bc
 416    2C05  2B        		dec	hl
 417    2C06  2B        		dec	hl
 418    2C07  2B        		dec	hl
 419    2C08  4E        		ld	c,(hl)
 420    2C09  23        		inc	hl
 421    2C0A  46        		ld	b,(hl)
 422    2C0B  C5        		push	bc
 423    2C0C  DD66E7    		ld	h,(ix-25)
 424    2C0F  DD6EE6    		ld	l,(ix-26)
 425    2C12  E5        		push	hl
 426    2C13  DD66E5    		ld	h,(ix-27)
 427    2C16  DD6EE4    		ld	l,(ix-28)
 428    2C19  E5        		push	hl
 429    2C1A  216F28    		ld	hl,L5602
 430    2C1D  CD0000    		call	_printf
 431    2C20  F1        		pop	af
 432    2C21  F1        		pop	af
 433    2C22  F1        		pop	af
 434    2C23  F1        		pop	af
 435                    	; 1002      printf(" [");
 436    2C24  218328    		ld	hl,L5702
 437    2C27  CD0000    		call	_printf
 438                    	; 1003      for (index = 40; index < (40 + 8); index++)
 439    2C2A  DD36F828  		ld	(ix-8),40
 440    2C2E  DD36F900  		ld	(ix-7),0
 441                    	L1733:
 442    2C32  DD7EF8    		ld	a,(ix-8)
 443    2C35  D630      		sub	48
 444    2C37  DD7EF9    		ld	a,(ix-7)
 445    2C3A  DE00      		sbc	a,0
 446    2C3C  F2612C    		jp	p,L1043
 447                    	; 1004          printf("%02x ", entryptr[index]);
 448    2C3F  DD6EEE    		ld	l,(ix-18)
 449    2C42  DD66EF    		ld	h,(ix-17)
 450    2C45  DD4EF8    		ld	c,(ix-8)
 451    2C48  DD46F9    		ld	b,(ix-7)
 452    2C4B  09        		add	hl,bc
 453    2C4C  4E        		ld	c,(hl)
 454    2C4D  97        		sub	a
 455    2C4E  47        		ld	b,a
 456    2C4F  C5        		push	bc
 457    2C50  218628    		ld	hl,L5012
 458    2C53  CD0000    		call	_printf
 459    2C56  F1        		pop	af
 460    2C57  DD34F8    		inc	(ix-8)
 461    2C5A  2003      		jr	nz,L431
 462    2C5C  DD34F9    		inc	(ix-7)
 463                    	L431:
 464    2C5F  18D1      		jr	L1733
 465                    	L1043:
 466                    	; 1005      printf("\b]");
 467    2C61  218C28    		ld	hl,L5112
 468    2C64  CD0000    		call	_printf
 469                    	; 1006      printf("\n  Attribute flags: [");
 470    2C67  218F28    		ld	hl,L5212
 471    2C6A  CD0000    		call	_printf
 472                    	; 1007      /* bits 0 - 2 and 60 - 63 should be decoded */
 473                    	; 1008      for (index = 0; index < 8; index++)
 474    2C6D  DD36F800  		ld	(ix-8),0
 475    2C71  DD36F900  		ld	(ix-7),0
 476                    	L1343:
 477    2C75  DD7EF8    		ld	a,(ix-8)
 478    2C78  D608      		sub	8
 479    2C7A  DD7EF9    		ld	a,(ix-7)
 480    2C7D  DE00      		sbc	a,0
 481    2C7F  F2B42C    		jp	p,L1443
 482                    	; 1009          {
 483                    	; 1010          entryidx = index + 48;
 484    2C82  DD6EF8    		ld	l,(ix-8)
 485    2C85  DD66F9    		ld	h,(ix-7)
 486    2C88  013000    		ld	bc,48
 487    2C8B  09        		add	hl,bc
 488    2C8C  DD75F6    		ld	(ix-10),l
 489    2C8F  DD74F7    		ld	(ix-9),h
 490                    	; 1011          printf("%02x ", entryptr[entryidx]);
 491    2C92  DD6EEE    		ld	l,(ix-18)
 492    2C95  DD66EF    		ld	h,(ix-17)
 493    2C98  DD4EF6    		ld	c,(ix-10)
 494    2C9B  DD46F7    		ld	b,(ix-9)
 495    2C9E  09        		add	hl,bc
 496    2C9F  4E        		ld	c,(hl)
 497    2CA0  97        		sub	a
 498    2CA1  47        		ld	b,a
 499    2CA2  C5        		push	bc
 500    2CA3  21A528    		ld	hl,L5312
 501    2CA6  CD0000    		call	_printf
 502    2CA9  F1        		pop	af
 503                    	; 1012          }
 504    2CAA  DD34F8    		inc	(ix-8)
 505    2CAD  2003      		jr	nz,L631
 506    2CAF  DD34F9    		inc	(ix-7)
 507                    	L631:
 508    2CB2  18C1      		jr	L1343
 509                    	L1443:
 510                    	; 1013      printf("\b]\n  Partition name:  ");
 511    2CB4  21AB28    		ld	hl,L5412
 512    2CB7  CD0000    		call	_printf
 513                    	; 1014      /* partition name is in UTF-16LE code units */
 514                    	; 1015      hasname = NO;
 515    2CBA  DD36F400  		ld	(ix-12),0
 516    2CBE  DD36F500  		ld	(ix-11),0
 517                    	; 1016      for (index = 0; index < 72; index += 2)
 518    2CC2  DD36F800  		ld	(ix-8),0
 519    2CC6  DD36F900  		ld	(ix-7),0
 520                    	L1743:
 521    2CCA  DD7EF8    		ld	a,(ix-8)
 522    2CCD  D648      		sub	72
 523    2CCF  DD7EF9    		ld	a,(ix-7)
 524    2CD2  DE00      		sbc	a,0
 525    2CD4  F2632D    		jp	p,L1053
 526                    	; 1017          {
 527                    	; 1018          entryidx = index + 56;
 528    2CD7  DD6EF8    		ld	l,(ix-8)
 529    2CDA  DD66F9    		ld	h,(ix-7)
 530    2CDD  013800    		ld	bc,56
 531    2CE0  09        		add	hl,bc
 532    2CE1  DD75F6    		ld	(ix-10),l
 533    2CE4  DD74F7    		ld	(ix-9),h
 534                    	; 1019          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
 535    2CE7  DD6EEE    		ld	l,(ix-18)
 536    2CEA  DD66EF    		ld	h,(ix-17)
 537    2CED  DD4EF6    		ld	c,(ix-10)
 538    2CF0  DD46F7    		ld	b,(ix-9)
 539    2CF3  09        		add	hl,bc
 540    2CF4  6E        		ld	l,(hl)
 541    2CF5  E5        		push	hl
 542    2CF6  DD6EF6    		ld	l,(ix-10)
 543    2CF9  DD66F7    		ld	h,(ix-9)
 544    2CFC  23        		inc	hl
 545    2CFD  DD4EEE    		ld	c,(ix-18)
 546    2D00  DD46EF    		ld	b,(ix-17)
 547    2D03  09        		add	hl,bc
 548    2D04  C1        		pop	bc
 549    2D05  79        		ld	a,c
 550    2D06  B6        		or	(hl)
 551    2D07  4F        		ld	c,a
 552    2D08  CA632D    		jp	z,L1053
 553                    	; 1020              break;
 554                    	; 1021          if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
 555    2D0B  DD6EEE    		ld	l,(ix-18)
 556    2D0E  DD66EF    		ld	h,(ix-17)
 557    2D11  DD4EF6    		ld	c,(ix-10)
 558    2D14  DD46F7    		ld	b,(ix-9)
 559    2D17  09        		add	hl,bc
 560    2D18  7E        		ld	a,(hl)
 561    2D19  FE20      		cp	32
 562    2D1B  3827      		jr	c,L1453
 563    2D1D  DD6EEE    		ld	l,(ix-18)
 564    2D20  DD66EF    		ld	h,(ix-17)
 565    2D23  DD4EF6    		ld	c,(ix-10)
 566    2D26  DD46F7    		ld	b,(ix-9)
 567    2D29  09        		add	hl,bc
 568    2D2A  7E        		ld	a,(hl)
 569    2D2B  FE7F      		cp	127
 570    2D2D  3015      		jr	nc,L1453
 571                    	; 1022              putchar(entryptr[entryidx]);
 572    2D2F  DD6EEE    		ld	l,(ix-18)
 573    2D32  DD66EF    		ld	h,(ix-17)
 574    2D35  DD4EF6    		ld	c,(ix-10)
 575    2D38  DD46F7    		ld	b,(ix-9)
 576    2D3B  09        		add	hl,bc
 577    2D3C  6E        		ld	l,(hl)
 578    2D3D  97        		sub	a
 579    2D3E  67        		ld	h,a
 580    2D3F  CD0000    		call	_putchar
 581                    	; 1023          else
 582    2D42  1806      		jr	L1553
 583                    	L1453:
 584                    	; 1024              putchar('.');
 585    2D44  212E00    		ld	hl,46
 586    2D47  CD0000    		call	_putchar
 587                    	L1553:
 588                    	; 1025          hasname = YES;
 589    2D4A  DD36F401  		ld	(ix-12),1
 590    2D4E  DD36F500  		ld	(ix-11),0
 591                    	; 1026          }
 592    2D52  DD6EF8    		ld	l,(ix-8)
 593    2D55  DD66F9    		ld	h,(ix-7)
 594    2D58  23        		inc	hl
 595    2D59  23        		inc	hl
 596    2D5A  DD75F8    		ld	(ix-8),l
 597    2D5D  DD74F9    		ld	(ix-7),h
 598    2D60  C3CA2C    		jp	L1743
 599                    	L1053:
 600                    	; 1027      if (!hasname)
 601    2D63  DD7EF4    		ld	a,(ix-12)
 602    2D66  DDB6F5    		or	(ix-11)
 603    2D69  2006      		jr	nz,L1653
 604                    	; 1028          printf("name field empty");
 605    2D6B  21C228    		ld	hl,L5512
 606    2D6E  CD0000    		call	_printf
 607                    	L1653:
 608                    	; 1029      printf("\n");
 609    2D71  21D328    		ld	hl,L5612
 610    2D74  CD0000    		call	_printf
 611                    	; 1030      printf("   [");
 612    2D77  21D528    		ld	hl,L5712
 613    2D7A  CD0000    		call	_printf
 614                    	; 1031      entryidx = index + 56;
 615    2D7D  DD6EF8    		ld	l,(ix-8)
 616    2D80  DD66F9    		ld	h,(ix-7)
 617    2D83  013800    		ld	bc,56
 618    2D86  09        		add	hl,bc
 619    2D87  DD75F6    		ld	(ix-10),l
 620    2D8A  DD74F7    		ld	(ix-9),h
 621                    	; 1032      for (index = 0; index < 72; index++)
 622    2D8D  DD36F800  		ld	(ix-8),0
 623    2D91  DD36F900  		ld	(ix-7),0
 624                    	L1753:
 625    2D95  DD7EF8    		ld	a,(ix-8)
 626    2D98  D648      		sub	72
 627    2D9A  DD7EF9    		ld	a,(ix-7)
 628    2D9D  DE00      		sbc	a,0
 629    2D9F  F2DD2D    		jp	p,L1063
 630                    	; 1033          {
 631                    	; 1034          if (((index & 0xf) == 0) && (index != 0))
 632    2DA2  DD6EF8    		ld	l,(ix-8)
 633    2DA5  DD66F9    		ld	h,(ix-7)
 634    2DA8  7D        		ld	a,l
 635    2DA9  E60F      		and	15
 636    2DAB  200E      		jr	nz,L1363
 637    2DAD  DD7EF8    		ld	a,(ix-8)
 638    2DB0  DDB6F9    		or	(ix-7)
 639    2DB3  2806      		jr	z,L1363
 640                    	; 1035              printf("\n    ");
 641    2DB5  21DA28    		ld	hl,L5022
 642    2DB8  CD0000    		call	_printf
 643                    	L1363:
 644                    	; 1036          printf("%02x ", entryptr[entryidx]);
 645    2DBB  DD6EEE    		ld	l,(ix-18)
 646    2DBE  DD66EF    		ld	h,(ix-17)
 647    2DC1  DD4EF6    		ld	c,(ix-10)
 648    2DC4  DD46F7    		ld	b,(ix-9)
 649    2DC7  09        		add	hl,bc
 650    2DC8  4E        		ld	c,(hl)
 651    2DC9  97        		sub	a
 652    2DCA  47        		ld	b,a
 653    2DCB  C5        		push	bc
 654    2DCC  21E028    		ld	hl,L5122
 655    2DCF  CD0000    		call	_printf
 656    2DD2  F1        		pop	af
 657                    	; 1037          }
 658    2DD3  DD34F8    		inc	(ix-8)
 659    2DD6  2003      		jr	nz,L041
 660    2DD8  DD34F9    		inc	(ix-7)
 661                    	L041:
 662    2DDB  18B8      		jr	L1753
 663                    	L1063:
 664                    	; 1038      printf("\b]\n");
 665    2DDD  21E628    		ld	hl,L5222
 666    2DE0  CD0000    		call	_printf
 667                    	; 1039      }
 668    2DE3  C30000    		jp	c.rets
 669                    	L5322:
 670    2DE6  47        		.byte	71
 671    2DE7  50        		.byte	80
 672    2DE8  54        		.byte	84
 673    2DE9  20        		.byte	32
 674    2DEA  68        		.byte	104
 675    2DEB  65        		.byte	101
 676    2DEC  61        		.byte	97
 677    2DED  64        		.byte	100
 678    2DEE  65        		.byte	101
 679    2DEF  72        		.byte	114
 680    2DF0  0A        		.byte	10
 681    2DF1  00        		.byte	0
 682                    	L5422:
 683    2DF2  43        		.byte	67
 684    2DF3  61        		.byte	97
 685    2DF4  6E        		.byte	110
 686    2DF5  27        		.byte	39
 687    2DF6  74        		.byte	116
 688    2DF7  20        		.byte	32
 689    2DF8  72        		.byte	114
 690    2DF9  65        		.byte	101
 691    2DFA  61        		.byte	97
 692    2DFB  64        		.byte	100
 693    2DFC  20        		.byte	32
 694    2DFD  47        		.byte	71
 695    2DFE  50        		.byte	80
 696    2DFF  54        		.byte	84
 697    2E00  20        		.byte	32
 698    2E01  70        		.byte	112
 699    2E02  61        		.byte	97
 700    2E03  72        		.byte	114
 701    2E04  74        		.byte	116
 702    2E05  69        		.byte	105
 703    2E06  74        		.byte	116
 704    2E07  69        		.byte	105
 705    2E08  6F        		.byte	111
 706    2E09  6E        		.byte	110
 707    2E0A  20        		.byte	32
 708    2E0B  74        		.byte	116
 709    2E0C  61        		.byte	97
 710    2E0D  62        		.byte	98
 711    2E0E  6C        		.byte	108
 712    2E0F  65        		.byte	101
 713    2E10  20        		.byte	32
 714    2E11  68        		.byte	104
 715    2E12  65        		.byte	101
 716    2E13  61        		.byte	97
 717    2E14  64        		.byte	100
 718    2E15  65        		.byte	101
 719    2E16  72        		.byte	114
 720    2E17  0A        		.byte	10
 721    2E18  00        		.byte	0
 722                    	L5522:
 723    2E19  20        		.byte	32
 724    2E1A  20        		.byte	32
 725    2E1B  53        		.byte	83
 726    2E1C  69        		.byte	105
 727    2E1D  67        		.byte	103
 728    2E1E  6E        		.byte	110
 729    2E1F  61        		.byte	97
 730    2E20  74        		.byte	116
 731    2E21  75        		.byte	117
 732    2E22  72        		.byte	114
 733    2E23  65        		.byte	101
 734    2E24  3A        		.byte	58
 735    2E25  20        		.byte	32
 736    2E26  25        		.byte	37
 737    2E27  2E        		.byte	46
 738    2E28  38        		.byte	56
 739    2E29  73        		.byte	115
 740    2E2A  0A        		.byte	10
 741    2E2B  00        		.byte	0
 742                    	L5622:
 743    2E2C  20        		.byte	32
 744    2E2D  20        		.byte	32
 745    2E2E  52        		.byte	82
 746    2E2F  65        		.byte	101
 747    2E30  76        		.byte	118
 748    2E31  69        		.byte	105
 749    2E32  73        		.byte	115
 750    2E33  69        		.byte	105
 751    2E34  6F        		.byte	111
 752    2E35  6E        		.byte	110
 753    2E36  3A        		.byte	58
 754    2E37  20        		.byte	32
 755    2E38  25        		.byte	37
 756    2E39  64        		.byte	100
 757    2E3A  2E        		.byte	46
 758    2E3B  25        		.byte	37
 759    2E3C  64        		.byte	100
 760    2E3D  20        		.byte	32
 761    2E3E  5B        		.byte	91
 762    2E3F  25        		.byte	37
 763    2E40  30        		.byte	48
 764    2E41  32        		.byte	50
 765    2E42  78        		.byte	120
 766    2E43  20        		.byte	32
 767    2E44  25        		.byte	37
 768    2E45  30        		.byte	48
 769    2E46  32        		.byte	50
 770    2E47  78        		.byte	120
 771    2E48  20        		.byte	32
 772    2E49  25        		.byte	37
 773    2E4A  30        		.byte	48
 774    2E4B  32        		.byte	50
 775    2E4C  78        		.byte	120
 776    2E4D  20        		.byte	32
 777    2E4E  25        		.byte	37
 778    2E4F  30        		.byte	48
 779    2E50  32        		.byte	50
 780    2E51  78        		.byte	120
 781    2E52  5D        		.byte	93
 782    2E53  0A        		.byte	10
 783    2E54  00        		.byte	0
 784                    	L5722:
 785    2E55  20        		.byte	32
 786    2E56  20        		.byte	32
 787    2E57  4E        		.byte	78
 788    2E58  75        		.byte	117
 789    2E59  6D        		.byte	109
 790    2E5A  62        		.byte	98
 791    2E5B  65        		.byte	101
 792    2E5C  72        		.byte	114
 793    2E5D  20        		.byte	32
 794    2E5E  6F        		.byte	111
 795    2E5F  66        		.byte	102
 796    2E60  20        		.byte	32
 797    2E61  70        		.byte	112
 798    2E62  61        		.byte	97
 799    2E63  72        		.byte	114
 800    2E64  74        		.byte	116
 801    2E65  69        		.byte	105
 802    2E66  74        		.byte	116
 803    2E67  69        		.byte	105
 804    2E68  6F        		.byte	111
 805    2E69  6E        		.byte	110
 806    2E6A  20        		.byte	32
 807    2E6B  65        		.byte	101
 808    2E6C  6E        		.byte	110
 809    2E6D  74        		.byte	116
 810    2E6E  72        		.byte	114
 811    2E6F  69        		.byte	105
 812    2E70  65        		.byte	101
 813    2E71  73        		.byte	115
 814    2E72  3A        		.byte	58
 815    2E73  20        		.byte	32
 816    2E74  25        		.byte	37
 817    2E75  6C        		.byte	108
 818    2E76  75        		.byte	117
 819    2E77  20        		.byte	32
 820    2E78  28        		.byte	40
 821    2E79  6D        		.byte	109
 822    2E7A  61        		.byte	97
 823    2E7B  79        		.byte	121
 824    2E7C  20        		.byte	32
 825    2E7D  62        		.byte	98
 826    2E7E  65        		.byte	101
 827    2E7F  20        		.byte	32
 828    2E80  61        		.byte	97
 829    2E81  63        		.byte	99
 830    2E82  74        		.byte	116
 831    2E83  75        		.byte	117
 832    2E84  61        		.byte	97
 833    2E85  6C        		.byte	108
 834    2E86  20        		.byte	32
 835    2E87  6F        		.byte	111
 836    2E88  72        		.byte	114
 837    2E89  20        		.byte	32
 838    2E8A  6D        		.byte	109
 839    2E8B  61        		.byte	97
 840    2E8C  78        		.byte	120
 841    2E8D  69        		.byte	105
 842    2E8E  6D        		.byte	109
 843    2E8F  75        		.byte	117
 844    2E90  6D        		.byte	109
 845    2E91  29        		.byte	41
 846    2E92  0A        		.byte	10
 847    2E93  00        		.byte	0
 848                    	L5032:
 849    2E94  46        		.byte	70
 850    2E95  69        		.byte	105
 851    2E96  72        		.byte	114
 852    2E97  73        		.byte	115
 853    2E98  74        		.byte	116
 854    2E99  20        		.byte	32
 855    2E9A  31        		.byte	49
 856    2E9B  36        		.byte	54
 857    2E9C  20        		.byte	32
 858    2E9D  47        		.byte	71
 859    2E9E  50        		.byte	80
 860    2E9F  54        		.byte	84
 861    2EA0  20        		.byte	32
 862    2EA1  65        		.byte	101
 863    2EA2  6E        		.byte	110
 864    2EA3  74        		.byte	116
 865    2EA4  72        		.byte	114
 866    2EA5  69        		.byte	105
 867    2EA6  65        		.byte	101
 868    2EA7  73        		.byte	115
 869    2EA8  20        		.byte	32
 870    2EA9  73        		.byte	115
 871    2EAA  63        		.byte	99
 872    2EAB  61        		.byte	97
 873    2EAC  6E        		.byte	110
 874    2EAD  6E        		.byte	110
 875    2EAE  65        		.byte	101
 876    2EAF  64        		.byte	100
 877    2EB0  0A        		.byte	10
 878    2EB1  00        		.byte	0
 879                    	; 1040  
 880                    	; 1041  /* Get GPT header */
 881                    	; 1042  void sdgpthdr(unsigned long block)
 882                    	; 1043      {
 883                    	_sdgpthdr:
 884    2EB2  CD0000    		call	c.savs
 885    2EB5  21F0FF    		ld	hl,65520
 886    2EB8  39        		add	hl,sp
 887    2EB9  F9        		ld	sp,hl
 888                    	; 1044      int index;
 889                    	; 1045      unsigned int partno;
 890                    	; 1046      unsigned char *rxdata;
 891                    	; 1047      unsigned long entries;
 892                    	; 1048  
 893                    	; 1049      printf("GPT header\n");
 894    2EBA  21E62D    		ld	hl,L5322
 895    2EBD  CD0000    		call	_printf
 896                    	; 1050      if (!sdread(sdrdbuf, block))
 897    2EC0  DD6607    		ld	h,(ix+7)
 898    2EC3  DD6E06    		ld	l,(ix+6)
 899    2EC6  E5        		push	hl
 900    2EC7  DD6605    		ld	h,(ix+5)
 901    2ECA  DD6E04    		ld	l,(ix+4)
 902    2ECD  E5        		push	hl
 903    2ECE  213200    		ld	hl,_sdrdbuf
 904    2ED1  CD671E    		call	_sdread
 905    2ED4  F1        		pop	af
 906    2ED5  F1        		pop	af
 907    2ED6  79        		ld	a,c
 908    2ED7  B0        		or	b
 909    2ED8  2009      		jr	nz,L1463
 910                    	; 1051          {
 911                    	; 1052          printf("Can't read GPT partition table header\n");
 912    2EDA  21F22D    		ld	hl,L5422
 913    2EDD  CD0000    		call	_printf
 914                    	; 1053          return;
 915    2EE0  C30000    		jp	c.rets
 916                    	L1463:
 917                    	; 1054          }
 918                    	; 1055      curblkno = block;
 919    2EE3  210000    		ld	hl,_curblkno
 920    2EE6  E5        		push	hl
 921    2EE7  DDE5      		push	ix
 922    2EE9  C1        		pop	bc
 923    2EEA  210400    		ld	hl,4
 924    2EED  09        		add	hl,bc
 925    2EEE  E5        		push	hl
 926    2EEF  CD0000    		call	c.mvl
 927    2EF2  F1        		pop	af
 928                    	; 1056      curblkok = YES;
 929    2EF3  210100    		ld	hl,1
 930    2EF6  220C00    		ld	(_curblkok),hl
 931                    	; 1057  
 932                    	; 1058      rxdata = sdrdbuf;
 933    2EF9  213200    		ld	hl,_sdrdbuf
 934    2EFC  DD75F4    		ld	(ix-12),l
 935    2EFF  DD74F5    		ld	(ix-11),h
 936                    	; 1059      printf("  Signature: %.8s\n", &rxdata[0]);
 937    2F02  DD6EF4    		ld	l,(ix-12)
 938    2F05  DD66F5    		ld	h,(ix-11)
 939    2F08  E5        		push	hl
 940    2F09  21192E    		ld	hl,L5522
 941    2F0C  CD0000    		call	_printf
 942    2F0F  F1        		pop	af
 943                    	; 1060      printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
 944                    	; 1061             (int)rxdata[8] * ((int)rxdata[9] << 8),
 945                    	; 1062             (int)rxdata[10] + ((int)rxdata[11] << 8),
 946                    	; 1063             rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
 947    2F10  DD6EF4    		ld	l,(ix-12)
 948    2F13  DD66F5    		ld	h,(ix-11)
 949    2F16  010B00    		ld	bc,11
 950    2F19  09        		add	hl,bc
 951    2F1A  4E        		ld	c,(hl)
 952    2F1B  97        		sub	a
 953    2F1C  47        		ld	b,a
 954    2F1D  C5        		push	bc
 955    2F1E  DD6EF4    		ld	l,(ix-12)
 956    2F21  DD66F5    		ld	h,(ix-11)
 957    2F24  010A00    		ld	bc,10
 958    2F27  09        		add	hl,bc
 959    2F28  4E        		ld	c,(hl)
 960    2F29  97        		sub	a
 961    2F2A  47        		ld	b,a
 962    2F2B  C5        		push	bc
 963    2F2C  DD6EF4    		ld	l,(ix-12)
 964    2F2F  DD66F5    		ld	h,(ix-11)
 965    2F32  010900    		ld	bc,9
 966    2F35  09        		add	hl,bc
 967    2F36  4E        		ld	c,(hl)
 968    2F37  97        		sub	a
 969    2F38  47        		ld	b,a
 970    2F39  C5        		push	bc
 971    2F3A  DD6EF4    		ld	l,(ix-12)
 972    2F3D  DD66F5    		ld	h,(ix-11)
 973    2F40  010800    		ld	bc,8
 974    2F43  09        		add	hl,bc
 975    2F44  4E        		ld	c,(hl)
 976    2F45  97        		sub	a
 977    2F46  47        		ld	b,a
 978    2F47  C5        		push	bc
 979    2F48  DD6EF4    		ld	l,(ix-12)
 980    2F4B  DD66F5    		ld	h,(ix-11)
 981    2F4E  010A00    		ld	bc,10
 982    2F51  09        		add	hl,bc
 983    2F52  6E        		ld	l,(hl)
 984    2F53  97        		sub	a
 985    2F54  67        		ld	h,a
 986    2F55  E5        		push	hl
 987    2F56  DD6EF4    		ld	l,(ix-12)
 988    2F59  DD66F5    		ld	h,(ix-11)
 989    2F5C  010B00    		ld	bc,11
 990    2F5F  09        		add	hl,bc
 991    2F60  6E        		ld	l,(hl)
 992    2F61  97        		sub	a
 993    2F62  67        		ld	h,a
 994    2F63  29        		add	hl,hl
 995    2F64  29        		add	hl,hl
 996    2F65  29        		add	hl,hl
 997    2F66  29        		add	hl,hl
 998    2F67  29        		add	hl,hl
 999    2F68  29        		add	hl,hl
1000    2F69  29        		add	hl,hl
1001    2F6A  29        		add	hl,hl
1002    2F6B  E3        		ex	(sp),hl
1003    2F6C  C1        		pop	bc
1004    2F6D  09        		add	hl,bc
1005    2F6E  E5        		push	hl
1006    2F6F  DD6EF4    		ld	l,(ix-12)
1007    2F72  DD66F5    		ld	h,(ix-11)
1008    2F75  010800    		ld	bc,8
1009    2F78  09        		add	hl,bc
1010    2F79  6E        		ld	l,(hl)
1011    2F7A  97        		sub	a
1012    2F7B  67        		ld	h,a
1013    2F7C  E5        		push	hl
1014    2F7D  DD6EF4    		ld	l,(ix-12)
1015    2F80  DD66F5    		ld	h,(ix-11)
1016    2F83  010900    		ld	bc,9
1017    2F86  09        		add	hl,bc
1018    2F87  6E        		ld	l,(hl)
1019    2F88  97        		sub	a
1020    2F89  67        		ld	h,a
1021    2F8A  29        		add	hl,hl
1022    2F8B  29        		add	hl,hl
1023    2F8C  29        		add	hl,hl
1024    2F8D  29        		add	hl,hl
1025    2F8E  29        		add	hl,hl
1026    2F8F  29        		add	hl,hl
1027    2F90  29        		add	hl,hl
1028    2F91  29        		add	hl,hl
1029    2F92  E5        		push	hl
1030    2F93  CD0000    		call	c.imul
1031    2F96  212C2E    		ld	hl,L5622
1032    2F99  CD0000    		call	_printf
1033    2F9C  210C00    		ld	hl,12
1034    2F9F  39        		add	hl,sp
1035    2FA0  F9        		ld	sp,hl
1036                    	; 1064      entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
1037                    	; 1065                ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
1038    2FA1  DDE5      		push	ix
1039    2FA3  C1        		pop	bc
1040    2FA4  21F0FF    		ld	hl,65520
1041    2FA7  09        		add	hl,bc
1042    2FA8  E5        		push	hl
1043    2FA9  DD6EF4    		ld	l,(ix-12)
1044    2FAC  DD66F5    		ld	h,(ix-11)
1045    2FAF  015000    		ld	bc,80
1046    2FB2  09        		add	hl,bc
1047    2FB3  4D        		ld	c,l
1048    2FB4  44        		ld	b,h
1049    2FB5  97        		sub	a
1050    2FB6  320000    		ld	(c.r0),a
1051    2FB9  320100    		ld	(c.r0+1),a
1052    2FBC  0A        		ld	a,(bc)
1053    2FBD  320200    		ld	(c.r0+2),a
1054    2FC0  97        		sub	a
1055    2FC1  320300    		ld	(c.r0+3),a
1056    2FC4  210000    		ld	hl,c.r0
1057    2FC7  E5        		push	hl
1058    2FC8  DD6EF4    		ld	l,(ix-12)
1059    2FCB  DD66F5    		ld	h,(ix-11)
1060    2FCE  015100    		ld	bc,81
1061    2FD1  09        		add	hl,bc
1062    2FD2  4D        		ld	c,l
1063    2FD3  44        		ld	b,h
1064    2FD4  97        		sub	a
1065    2FD5  320000    		ld	(c.r1),a
1066    2FD8  320100    		ld	(c.r1+1),a
1067    2FDB  0A        		ld	a,(bc)
1068    2FDC  320200    		ld	(c.r1+2),a
1069    2FDF  97        		sub	a
1070    2FE0  320300    		ld	(c.r1+3),a
1071    2FE3  210000    		ld	hl,c.r1
1072    2FE6  E5        		push	hl
1073    2FE7  210800    		ld	hl,8
1074    2FEA  E5        		push	hl
1075    2FEB  CD0000    		call	c.llsh
1076    2FEE  CD0000    		call	c.ladd
1077    2FF1  DD6EF4    		ld	l,(ix-12)
1078    2FF4  DD66F5    		ld	h,(ix-11)
1079    2FF7  015200    		ld	bc,82
1080    2FFA  09        		add	hl,bc
1081    2FFB  4D        		ld	c,l
1082    2FFC  44        		ld	b,h
1083    2FFD  97        		sub	a
1084    2FFE  320000    		ld	(c.r1),a
1085    3001  320100    		ld	(c.r1+1),a
1086    3004  0A        		ld	a,(bc)
1087    3005  320200    		ld	(c.r1+2),a
1088    3008  97        		sub	a
1089    3009  320300    		ld	(c.r1+3),a
1090    300C  210000    		ld	hl,c.r1
1091    300F  E5        		push	hl
1092    3010  211000    		ld	hl,16
1093    3013  E5        		push	hl
1094    3014  CD0000    		call	c.llsh
1095    3017  CD0000    		call	c.ladd
1096    301A  DD6EF4    		ld	l,(ix-12)
1097    301D  DD66F5    		ld	h,(ix-11)
1098    3020  015300    		ld	bc,83
1099    3023  09        		add	hl,bc
1100    3024  4D        		ld	c,l
1101    3025  44        		ld	b,h
1102    3026  97        		sub	a
1103    3027  320000    		ld	(c.r1),a
1104    302A  320100    		ld	(c.r1+1),a
1105    302D  0A        		ld	a,(bc)
1106    302E  320200    		ld	(c.r1+2),a
1107    3031  97        		sub	a
1108    3032  320300    		ld	(c.r1+3),a
1109    3035  210000    		ld	hl,c.r1
1110    3038  E5        		push	hl
1111    3039  211800    		ld	hl,24
1112    303C  E5        		push	hl
1113    303D  CD0000    		call	c.llsh
1114    3040  CD0000    		call	c.ladd
1115    3043  CD0000    		call	c.mvl
1116    3046  F1        		pop	af
1117                    	; 1066      printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
1118    3047  DD66F3    		ld	h,(ix-13)
1119    304A  DD6EF2    		ld	l,(ix-14)
1120    304D  E5        		push	hl
1121    304E  DD66F1    		ld	h,(ix-15)
1122    3051  DD6EF0    		ld	l,(ix-16)
1123    3054  E5        		push	hl
1124    3055  21552E    		ld	hl,L5722
1125    3058  CD0000    		call	_printf
1126    305B  F1        		pop	af
1127    305C  F1        		pop	af
1128                    	; 1067      for (partno = 0; partno < 16; partno++)
1129    305D  DD36F600  		ld	(ix-10),0
1130    3061  DD36F700  		ld	(ix-9),0
1131                    	L1563:
1132    3065  DD7EF6    		ld	a,(ix-10)
1133    3068  D610      		sub	16
1134    306A  DD7EF7    		ld	a,(ix-9)
1135    306D  DE00      		sbc	a,0
1136    306F  3013      		jr	nc,L1663
1137                    	; 1068          {
1138                    	; 1069          prtgptent(partno);
1139    3071  DD6EF6    		ld	l,(ix-10)
1140    3074  DD66F7    		ld	h,(ix-9)
1141    3077  CDEA28    		call	_prtgptent
1142                    	; 1070          }
1143    307A  DD34F6    		inc	(ix-10)
1144    307D  2003      		jr	nz,L441
1145    307F  DD34F7    		inc	(ix-9)
1146                    	L441:
1147    3082  18E1      		jr	L1563
1148                    	L1663:
1149                    	; 1071      printf("First 16 GPT entries scanned\n");
1150    3084  21942E    		ld	hl,L5032
1151    3087  CD0000    		call	_printf
1152                    	; 1072      }
1153    308A  C30000    		jp	c.rets
1154                    	L5132:
1155    308D  43        		.byte	67
1156    308E  61        		.byte	97
1157    308F  6E        		.byte	110
1158    3090  27        		.byte	39
1159    3091  74        		.byte	116
1160    3092  20        		.byte	32
1161    3093  72        		.byte	114
1162    3094  65        		.byte	101
1163    3095  61        		.byte	97
1164    3096  64        		.byte	100
1165    3097  20        		.byte	32
1166    3098  4D        		.byte	77
1167    3099  42        		.byte	66
1168    309A  52        		.byte	82
1169    309B  20        		.byte	32
1170    309C  73        		.byte	115
1171    309D  65        		.byte	101
1172    309E  63        		.byte	99
1173    309F  74        		.byte	116
1174    30A0  6F        		.byte	111
1175    30A1  72        		.byte	114
1176    30A2  0A        		.byte	10
1177    30A3  00        		.byte	0
1178                    	L5232:
1179    30A4  4E        		.byte	78
1180    30A5  6F        		.byte	111
1181    30A6  74        		.byte	116
1182    30A7  20        		.byte	32
1183    30A8  75        		.byte	117
1184    30A9  73        		.byte	115
1185    30AA  65        		.byte	101
1186    30AB  64        		.byte	100
1187    30AC  20        		.byte	32
1188    30AD  65        		.byte	101
1189    30AE  6E        		.byte	110
1190    30AF  74        		.byte	116
1191    30B0  72        		.byte	114
1192    30B1  79        		.byte	121
1193    30B2  0A        		.byte	10
1194    30B3  00        		.byte	0
1195                    	L5332:
1196    30B4  62        		.byte	98
1197    30B5  6F        		.byte	111
1198    30B6  6F        		.byte	111
1199    30B7  74        		.byte	116
1200    30B8  20        		.byte	32
1201    30B9  69        		.byte	105
1202    30BA  6E        		.byte	110
1203    30BB  64        		.byte	100
1204    30BC  69        		.byte	105
1205    30BD  63        		.byte	99
1206    30BE  61        		.byte	97
1207    30BF  74        		.byte	116
1208    30C0  6F        		.byte	111
1209    30C1  72        		.byte	114
1210    30C2  3A        		.byte	58
1211    30C3  20        		.byte	32
1212    30C4  30        		.byte	48
1213    30C5  78        		.byte	120
1214    30C6  25        		.byte	37
1215    30C7  30        		.byte	48
1216    30C8  32        		.byte	50
1217    30C9  78        		.byte	120
1218    30CA  2C        		.byte	44
1219    30CB  20        		.byte	32
1220    30CC  53        		.byte	83
1221    30CD  79        		.byte	121
1222    30CE  73        		.byte	115
1223    30CF  74        		.byte	116
1224    30D0  65        		.byte	101
1225    30D1  6D        		.byte	109
1226    30D2  20        		.byte	32
1227    30D3  49        		.byte	73
1228    30D4  44        		.byte	68
1229    30D5  3A        		.byte	58
1230    30D6  20        		.byte	32
1231    30D7  30        		.byte	48
1232    30D8  78        		.byte	120
1233    30D9  25        		.byte	37
1234    30DA  30        		.byte	48
1235    30DB  32        		.byte	50
1236    30DC  78        		.byte	120
1237    30DD  0A        		.byte	10
1238    30DE  00        		.byte	0
1239                    	L5432:
1240    30DF  20        		.byte	32
1241    30E0  20        		.byte	32
1242    30E1  45        		.byte	69
1243    30E2  78        		.byte	120
1244    30E3  74        		.byte	116
1245    30E4  65        		.byte	101
1246    30E5  6E        		.byte	110
1247    30E6  64        		.byte	100
1248    30E7  65        		.byte	101
1249    30E8  64        		.byte	100
1250    30E9  20        		.byte	32
1251    30EA  70        		.byte	112
1252    30EB  61        		.byte	97
1253    30EC  72        		.byte	114
1254    30ED  74        		.byte	116
1255    30EE  69        		.byte	105
1256    30EF  74        		.byte	116
1257    30F0  69        		.byte	105
1258    30F1  6F        		.byte	111
1259    30F2  6E        		.byte	110
1260    30F3  0A        		.byte	10
1261    30F4  00        		.byte	0
1262                    	L5532:
1263    30F5  20        		.byte	32
1264    30F6  20        		.byte	32
1265    30F7  75        		.byte	117
1266    30F8  6E        		.byte	110
1267    30F9  6F        		.byte	111
1268    30FA  66        		.byte	102
1269    30FB  66        		.byte	102
1270    30FC  69        		.byte	105
1271    30FD  63        		.byte	99
1272    30FE  69        		.byte	105
1273    30FF  61        		.byte	97
1274    3100  6C        		.byte	108
1275    3101  20        		.byte	32
1276    3102  34        		.byte	52
1277    3103  38        		.byte	56
1278    3104  20        		.byte	32
1279    3105  62        		.byte	98
1280    3106  69        		.byte	105
1281    3107  74        		.byte	116
1282    3108  20        		.byte	32
1283    3109  4C        		.byte	76
1284    310A  42        		.byte	66
1285    310B  41        		.byte	65
1286    310C  20        		.byte	32
1287    310D  50        		.byte	80
1288    310E  72        		.byte	114
1289    310F  6F        		.byte	111
1290    3110  70        		.byte	112
1291    3111  6F        		.byte	111
1292    3112  73        		.byte	115
1293    3113  65        		.byte	101
1294    3114  64        		.byte	100
1295    3115  20        		.byte	32
1296    3116  4D        		.byte	77
1297    3117  42        		.byte	66
1298    3118  52        		.byte	82
1299    3119  20        		.byte	32
1300    311A  46        		.byte	70
1301    311B  6F        		.byte	111
1302    311C  72        		.byte	114
1303    311D  6D        		.byte	109
1304    311E  61        		.byte	97
1305    311F  74        		.byte	116
1306    3120  2C        		.byte	44
1307    3121  20        		.byte	32
1308    3122  6E        		.byte	110
1309    3123  6F        		.byte	111
1310    3124  20        		.byte	32
1311    3125  43        		.byte	67
1312    3126  48        		.byte	72
1313    3127  53        		.byte	83
1314    3128  0A        		.byte	10
1315    3129  00        		.byte	0
1316                    	L5632:
1317    312A  20        		.byte	32
1318    312B  20        		.byte	32
1319    312C  62        		.byte	98
1320    312D  65        		.byte	101
1321    312E  67        		.byte	103
1322    312F  69        		.byte	105
1323    3130  6E        		.byte	110
1324    3131  20        		.byte	32
1325    3132  43        		.byte	67
1326    3133  48        		.byte	72
1327    3134  53        		.byte	83
1328    3135  3A        		.byte	58
1329    3136  20        		.byte	32
1330    3137  30        		.byte	48
1331    3138  78        		.byte	120
1332    3139  25        		.byte	37
1333    313A  30        		.byte	48
1334    313B  32        		.byte	50
1335    313C  78        		.byte	120
1336    313D  2D        		.byte	45
1337    313E  30        		.byte	48
1338    313F  78        		.byte	120
1339    3140  25        		.byte	37
1340    3141  30        		.byte	48
1341    3142  32        		.byte	50
1342    3143  78        		.byte	120
1343    3144  2D        		.byte	45
1344    3145  30        		.byte	48
1345    3146  78        		.byte	120
1346    3147  25        		.byte	37
1347    3148  30        		.byte	48
1348    3149  32        		.byte	50
1349    314A  78        		.byte	120
1350    314B  20        		.byte	32
1351    314C  28        		.byte	40
1352    314D  63        		.byte	99
1353    314E  79        		.byte	121
1354    314F  6C        		.byte	108
1355    3150  3A        		.byte	58
1356    3151  20        		.byte	32
1357    3152  25        		.byte	37
1358    3153  64        		.byte	100
1359    3154  2C        		.byte	44
1360    3155  20        		.byte	32
1361    3156  68        		.byte	104
1362    3157  65        		.byte	101
1363    3158  61        		.byte	97
1364    3159  64        		.byte	100
1365    315A  3A        		.byte	58
1366    315B  20        		.byte	32
1367    315C  25        		.byte	37
1368    315D  64        		.byte	100
1369    315E  20        		.byte	32
1370    315F  73        		.byte	115
1371    3160  65        		.byte	101
1372    3161  63        		.byte	99
1373    3162  74        		.byte	116
1374    3163  6F        		.byte	111
1375    3164  72        		.byte	114
1376    3165  3A        		.byte	58
1377    3166  20        		.byte	32
1378    3167  25        		.byte	37
1379    3168  64        		.byte	100
1380    3169  29        		.byte	41
1381    316A  0A        		.byte	10
1382    316B  00        		.byte	0
1383                    	L5732:
1384    316C  20        		.byte	32
1385    316D  20        		.byte	32
1386    316E  65        		.byte	101
1387    316F  6E        		.byte	110
1388    3170  64        		.byte	100
1389    3171  20        		.byte	32
1390    3172  43        		.byte	67
1391    3173  48        		.byte	72
1392    3174  53        		.byte	83
1393    3175  20        		.byte	32
1394    3176  30        		.byte	48
1395    3177  78        		.byte	120
1396    3178  25        		.byte	37
1397    3179  30        		.byte	48
1398    317A  32        		.byte	50
1399    317B  78        		.byte	120
1400    317C  2D        		.byte	45
1401    317D  30        		.byte	48
1402    317E  78        		.byte	120
1403    317F  25        		.byte	37
1404    3180  30        		.byte	48
1405    3181  32        		.byte	50
1406    3182  78        		.byte	120
1407    3183  2D        		.byte	45
1408    3184  30        		.byte	48
1409    3185  78        		.byte	120
1410    3186  25        		.byte	37
1411    3187  30        		.byte	48
1412    3188  32        		.byte	50
1413    3189  78        		.byte	120
1414    318A  20        		.byte	32
1415    318B  28        		.byte	40
1416    318C  63        		.byte	99
1417    318D  79        		.byte	121
1418    318E  6C        		.byte	108
1419    318F  3A        		.byte	58
1420    3190  20        		.byte	32
1421    3191  25        		.byte	37
1422    3192  64        		.byte	100
1423    3193  2C        		.byte	44
1424    3194  20        		.byte	32
1425    3195  68        		.byte	104
1426    3196  65        		.byte	101
1427    3197  61        		.byte	97
1428    3198  64        		.byte	100
1429    3199  3A        		.byte	58
1430    319A  20        		.byte	32
1431    319B  25        		.byte	37
1432    319C  64        		.byte	100
1433    319D  20        		.byte	32
1434    319E  73        		.byte	115
1435    319F  65        		.byte	101
1436    31A0  63        		.byte	99
1437    31A1  74        		.byte	116
1438    31A2  6F        		.byte	111
1439    31A3  72        		.byte	114
1440    31A4  3A        		.byte	58
1441    31A5  20        		.byte	32
1442    31A6  25        		.byte	37
1443    31A7  64        		.byte	100
1444    31A8  29        		.byte	41
1445    31A9  0A        		.byte	10
1446    31AA  00        		.byte	0
1447                    	L5042:
1448    31AB  20        		.byte	32
1449    31AC  20        		.byte	32
1450    31AD  70        		.byte	112
1451    31AE  61        		.byte	97
1452    31AF  72        		.byte	114
1453    31B0  74        		.byte	116
1454    31B1  69        		.byte	105
1455    31B2  74        		.byte	116
1456    31B3  69        		.byte	105
1457    31B4  6F        		.byte	111
1458    31B5  6E        		.byte	110
1459    31B6  20        		.byte	32
1460    31B7  73        		.byte	115
1461    31B8  74        		.byte	116
1462    31B9  61        		.byte	97
1463    31BA  72        		.byte	114
1464    31BB  74        		.byte	116
1465    31BC  20        		.byte	32
1466    31BD  4C        		.byte	76
1467    31BE  42        		.byte	66
1468    31BF  41        		.byte	65
1469    31C0  3A        		.byte	58
1470    31C1  20        		.byte	32
1471    31C2  25        		.byte	37
1472    31C3  6C        		.byte	108
1473    31C4  75        		.byte	117
1474    31C5  20        		.byte	32
1475    31C6  5B        		.byte	91
1476    31C7  25        		.byte	37
1477    31C8  30        		.byte	48
1478    31C9  38        		.byte	56
1479    31CA  6C        		.byte	108
1480    31CB  78        		.byte	120
1481    31CC  5D        		.byte	93
1482    31CD  0A        		.byte	10
1483    31CE  00        		.byte	0
1484                    	L5142:
1485    31CF  20        		.byte	32
1486    31D0  20        		.byte	32
1487    31D1  70        		.byte	112
1488    31D2  61        		.byte	97
1489    31D3  72        		.byte	114
1490    31D4  74        		.byte	116
1491    31D5  69        		.byte	105
1492    31D6  74        		.byte	116
1493    31D7  69        		.byte	105
1494    31D8  6F        		.byte	111
1495    31D9  6E        		.byte	110
1496    31DA  20        		.byte	32
1497    31DB  73        		.byte	115
1498    31DC  69        		.byte	105
1499    31DD  7A        		.byte	122
1500    31DE  65        		.byte	101
1501    31DF  20        		.byte	32
1502    31E0  4C        		.byte	76
1503    31E1  42        		.byte	66
1504    31E2  41        		.byte	65
1505    31E3  3A        		.byte	58
1506    31E4  20        		.byte	32
1507    31E5  25        		.byte	37
1508    31E6  6C        		.byte	108
1509    31E7  75        		.byte	117
1510    31E8  20        		.byte	32
1511    31E9  5B        		.byte	91
1512    31EA  25        		.byte	37
1513    31EB  30        		.byte	48
1514    31EC  38        		.byte	56
1515    31ED  6C        		.byte	108
1516    31EE  78        		.byte	120
1517    31EF  5D        		.byte	93
1518    31F0  2C        		.byte	44
1519    31F1  20        		.byte	32
1520    31F2  25        		.byte	37
1521    31F3  6C        		.byte	108
1522    31F4  75        		.byte	117
1523    31F5  20        		.byte	32
1524    31F6  4D        		.byte	77
1525    31F7  42        		.byte	66
1526    31F8  79        		.byte	121
1527    31F9  74        		.byte	116
1528    31FA  65        		.byte	101
1529    31FB  0A        		.byte	10
1530    31FC  00        		.byte	0
1531                    	; 1073  
1532                    	; 1074  /* read MBR partition entry */
1533                    	; 1075  int sdmbrentry(unsigned char *partptr)
1534                    	; 1076      {
1535                    	_sdmbrentry:
1536    31FD  CD0000    		call	c.savs
1537    3200  21F0FF    		ld	hl,65520
1538    3203  39        		add	hl,sp
1539    3204  F9        		ld	sp,hl
1540                    	; 1077      int index;
1541                    	; 1078      unsigned long lbastart;
1542                    	; 1079      unsigned long lbasize;
1543                    	; 1080  
1544                    	; 1081      if ((curblkno != 0) || !curblkok)
1545    3205  210000    		ld	hl,_curblkno
1546    3208  7E        		ld	a,(hl)
1547    3209  23        		inc	hl
1548    320A  B6        		or	(hl)
1549    320B  23        		inc	hl
1550    320C  B6        		or	(hl)
1551    320D  23        		inc	hl
1552    320E  B6        		or	(hl)
1553    320F  2007      		jr	nz,L1273
1554    3211  2A0C00    		ld	hl,(_curblkok)
1555    3214  7C        		ld	a,h
1556    3215  B5        		or	l
1557    3216  2034      		jr	nz,L1173
1558                    	L1273:
1559                    	; 1082          {
1560                    	; 1083          curblkno = 0;
1561    3218  97        		sub	a
1562    3219  320000    		ld	(_curblkno),a
1563    321C  320100    		ld	(_curblkno+1),a
1564    321F  320200    		ld	(_curblkno+2),a
1565    3222  320300    		ld	(_curblkno+3),a
1566                    	; 1084          if (!sdread(sdrdbuf, curblkno))
1567    3225  210300    		ld	hl,_curblkno+3
1568    3228  46        		ld	b,(hl)
1569    3229  2B        		dec	hl
1570    322A  4E        		ld	c,(hl)
1571    322B  C5        		push	bc
1572    322C  2B        		dec	hl
1573    322D  46        		ld	b,(hl)
1574    322E  2B        		dec	hl
1575    322F  4E        		ld	c,(hl)
1576    3230  C5        		push	bc
1577    3231  213200    		ld	hl,_sdrdbuf
1578    3234  CD671E    		call	_sdread
1579    3237  F1        		pop	af
1580    3238  F1        		pop	af
1581    3239  79        		ld	a,c
1582    323A  B0        		or	b
1583    323B  2009      		jr	nz,L1373
1584                    	; 1085              {
1585                    	; 1086              printf("Can't read MBR sector\n");
1586    323D  218D30    		ld	hl,L5132
1587    3240  CD0000    		call	_printf
1588                    	; 1087              return;
1589    3243  C30000    		jp	c.rets
1590                    	L1373:
1591                    	; 1088              }
1592                    	; 1089          curblkok = YES;
1593    3246  210100    		ld	hl,1
1594    3249  220C00    		ld	(_curblkok),hl
1595                    	L1173:
1596                    	; 1090          }
1597                    	; 1091      if (!partptr[4])
1598    324C  DD6E04    		ld	l,(ix+4)
1599    324F  DD6605    		ld	h,(ix+5)
1600    3252  23        		inc	hl
1601    3253  23        		inc	hl
1602    3254  23        		inc	hl
1603    3255  23        		inc	hl
1604    3256  7E        		ld	a,(hl)
1605    3257  B7        		or	a
1606    3258  2009      		jr	nz,L1473
1607                    	; 1092          {
1608                    	; 1093          printf("Not used entry\n");
1609    325A  21A430    		ld	hl,L5232
1610    325D  CD0000    		call	_printf
1611                    	; 1094          return;
1612    3260  C30000    		jp	c.rets
1613                    	L1473:
1614                    	; 1095          }
1615                    	; 1096      printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
1616                    	; 1097             partptr[0], partptr[4]);
1617    3263  DD6E04    		ld	l,(ix+4)
1618    3266  DD6605    		ld	h,(ix+5)
1619    3269  23        		inc	hl
1620    326A  23        		inc	hl
1621    326B  23        		inc	hl
1622    326C  23        		inc	hl
1623    326D  4E        		ld	c,(hl)
1624    326E  97        		sub	a
1625    326F  47        		ld	b,a
1626    3270  C5        		push	bc
1627    3271  DD6E04    		ld	l,(ix+4)
1628    3274  DD6605    		ld	h,(ix+5)
1629    3277  4E        		ld	c,(hl)
1630    3278  97        		sub	a
1631    3279  47        		ld	b,a
1632    327A  C5        		push	bc
1633    327B  21B430    		ld	hl,L5332
1634    327E  CD0000    		call	_printf
1635    3281  F1        		pop	af
1636    3282  F1        		pop	af
1637                    	; 1098  
1638                    	; 1099      if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
1639    3283  DD6E04    		ld	l,(ix+4)
1640    3286  DD6605    		ld	h,(ix+5)
1641    3289  23        		inc	hl
1642    328A  23        		inc	hl
1643    328B  23        		inc	hl
1644    328C  23        		inc	hl
1645    328D  7E        		ld	a,(hl)
1646    328E  FE05      		cp	5
1647    3290  280F      		jr	z,L1673
1648    3292  DD6E04    		ld	l,(ix+4)
1649    3295  DD6605    		ld	h,(ix+5)
1650    3298  23        		inc	hl
1651    3299  23        		inc	hl
1652    329A  23        		inc	hl
1653    329B  23        		inc	hl
1654    329C  7E        		ld	a,(hl)
1655    329D  FE0F      		cp	15
1656    329F  2006      		jr	nz,L1573
1657                    	L1673:
1658                    	; 1100          {
1659                    	; 1101          printf("  Extended partition\n");
1660    32A1  21DF30    		ld	hl,L5432
1661    32A4  CD0000    		call	_printf
1662                    	L1573:
1663                    	; 1102          /* should probably decode this also */
1664                    	; 1103          }
1665                    	; 1104      if (partptr[0] & 0x01)
1666    32A7  DD6E04    		ld	l,(ix+4)
1667    32AA  DD6605    		ld	h,(ix+5)
1668    32AD  7E        		ld	a,(hl)
1669    32AE  CB47      		bit	0,a
1670    32B0  6F        		ld	l,a
1671    32B1  2809      		jr	z,L1773
1672                    	; 1105          {
1673                    	; 1106          printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
1674    32B3  21F530    		ld	hl,L5532
1675    32B6  CD0000    		call	_printf
1676                    	; 1107          /* this is however discussed
1677                    	; 1108             https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
1678                    	; 1109          */
1679                    	; 1110          }
1680                    	; 1111      else
1681    32B9  C3B833    		jp	L1004
1682                    	L1773:
1683                    	; 1112          {
1684                    	; 1113          printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1685                    	; 1114                 partptr[1], partptr[2], partptr[3],
1686                    	; 1115                 ((partptr[2] & 0xc0) >> 2) + partptr[3],
1687                    	; 1116                 partptr[1],
1688                    	; 1117                 partptr[2] & 0x3f);
1689    32BC  DD6E04    		ld	l,(ix+4)
1690    32BF  DD6605    		ld	h,(ix+5)
1691    32C2  23        		inc	hl
1692    32C3  23        		inc	hl
1693    32C4  6E        		ld	l,(hl)
1694    32C5  97        		sub	a
1695    32C6  67        		ld	h,a
1696    32C7  7D        		ld	a,l
1697    32C8  E63F      		and	63
1698    32CA  6F        		ld	l,a
1699    32CB  97        		sub	a
1700    32CC  67        		ld	h,a
1701    32CD  E5        		push	hl
1702    32CE  DD6E04    		ld	l,(ix+4)
1703    32D1  DD6605    		ld	h,(ix+5)
1704    32D4  23        		inc	hl
1705    32D5  4E        		ld	c,(hl)
1706    32D6  97        		sub	a
1707    32D7  47        		ld	b,a
1708    32D8  C5        		push	bc
1709    32D9  DD6E04    		ld	l,(ix+4)
1710    32DC  DD6605    		ld	h,(ix+5)
1711    32DF  23        		inc	hl
1712    32E0  23        		inc	hl
1713    32E1  6E        		ld	l,(hl)
1714    32E2  97        		sub	a
1715    32E3  67        		ld	h,a
1716    32E4  7D        		ld	a,l
1717    32E5  E6C0      		and	192
1718    32E7  6F        		ld	l,a
1719    32E8  97        		sub	a
1720    32E9  67        		ld	h,a
1721    32EA  E5        		push	hl
1722    32EB  210200    		ld	hl,2
1723    32EE  E5        		push	hl
1724    32EF  CD0000    		call	c.irsh
1725    32F2  E1        		pop	hl
1726    32F3  E5        		push	hl
1727    32F4  DD6E04    		ld	l,(ix+4)
1728    32F7  DD6605    		ld	h,(ix+5)
1729    32FA  23        		inc	hl
1730    32FB  23        		inc	hl
1731    32FC  23        		inc	hl
1732    32FD  6E        		ld	l,(hl)
1733    32FE  97        		sub	a
1734    32FF  67        		ld	h,a
1735    3300  E3        		ex	(sp),hl
1736    3301  C1        		pop	bc
1737    3302  09        		add	hl,bc
1738    3303  E5        		push	hl
1739    3304  DD6E04    		ld	l,(ix+4)
1740    3307  DD6605    		ld	h,(ix+5)
1741    330A  23        		inc	hl
1742    330B  23        		inc	hl
1743    330C  23        		inc	hl
1744    330D  4E        		ld	c,(hl)
1745    330E  97        		sub	a
1746    330F  47        		ld	b,a
1747    3310  C5        		push	bc
1748    3311  DD6E04    		ld	l,(ix+4)
1749    3314  DD6605    		ld	h,(ix+5)
1750    3317  23        		inc	hl
1751    3318  23        		inc	hl
1752    3319  4E        		ld	c,(hl)
1753    331A  97        		sub	a
1754    331B  47        		ld	b,a
1755    331C  C5        		push	bc
1756    331D  DD6E04    		ld	l,(ix+4)
1757    3320  DD6605    		ld	h,(ix+5)
1758    3323  23        		inc	hl
1759    3324  4E        		ld	c,(hl)
1760    3325  97        		sub	a
1761    3326  47        		ld	b,a
1762    3327  C5        		push	bc
1763    3328  212A31    		ld	hl,L5632
1764    332B  CD0000    		call	_printf
1765    332E  210C00    		ld	hl,12
1766    3331  39        		add	hl,sp
1767    3332  F9        		ld	sp,hl
1768                    	; 1118          printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1769                    	; 1119                 partptr[5], partptr[6], partptr[7],
1770                    	; 1120                 ((partptr[6] & 0xc0) >> 2) + partptr[7],
1771                    	; 1121                 partptr[5],
1772                    	; 1122                 partptr[6] & 0x3f);
1773    3333  DD6E04    		ld	l,(ix+4)
1774    3336  DD6605    		ld	h,(ix+5)
1775    3339  010600    		ld	bc,6
1776    333C  09        		add	hl,bc
1777    333D  6E        		ld	l,(hl)
1778    333E  97        		sub	a
1779    333F  67        		ld	h,a
1780    3340  7D        		ld	a,l
1781    3341  E63F      		and	63
1782    3343  6F        		ld	l,a
1783    3344  97        		sub	a
1784    3345  67        		ld	h,a
1785    3346  E5        		push	hl
1786    3347  DD6E04    		ld	l,(ix+4)
1787    334A  DD6605    		ld	h,(ix+5)
1788    334D  010500    		ld	bc,5
1789    3350  09        		add	hl,bc
1790    3351  4E        		ld	c,(hl)
1791    3352  97        		sub	a
1792    3353  47        		ld	b,a
1793    3354  C5        		push	bc
1794    3355  DD6E04    		ld	l,(ix+4)
1795    3358  DD6605    		ld	h,(ix+5)
1796    335B  010600    		ld	bc,6
1797    335E  09        		add	hl,bc
1798    335F  6E        		ld	l,(hl)
1799    3360  97        		sub	a
1800    3361  67        		ld	h,a
1801    3362  7D        		ld	a,l
1802    3363  E6C0      		and	192
1803    3365  6F        		ld	l,a
1804    3366  97        		sub	a
1805    3367  67        		ld	h,a
1806    3368  E5        		push	hl
1807    3369  210200    		ld	hl,2
1808    336C  E5        		push	hl
1809    336D  CD0000    		call	c.irsh
1810    3370  E1        		pop	hl
1811    3371  E5        		push	hl
1812    3372  DD6E04    		ld	l,(ix+4)
1813    3375  DD6605    		ld	h,(ix+5)
1814    3378  010700    		ld	bc,7
1815    337B  09        		add	hl,bc
1816    337C  6E        		ld	l,(hl)
1817    337D  97        		sub	a
1818    337E  67        		ld	h,a
1819    337F  E3        		ex	(sp),hl
1820    3380  C1        		pop	bc
1821    3381  09        		add	hl,bc
1822    3382  E5        		push	hl
1823    3383  DD6E04    		ld	l,(ix+4)
1824    3386  DD6605    		ld	h,(ix+5)
1825    3389  010700    		ld	bc,7
1826    338C  09        		add	hl,bc
1827    338D  4E        		ld	c,(hl)
1828    338E  97        		sub	a
1829    338F  47        		ld	b,a
1830    3390  C5        		push	bc
1831    3391  DD6E04    		ld	l,(ix+4)
1832    3394  DD6605    		ld	h,(ix+5)
1833    3397  010600    		ld	bc,6
1834    339A  09        		add	hl,bc
1835    339B  4E        		ld	c,(hl)
1836    339C  97        		sub	a
1837    339D  47        		ld	b,a
1838    339E  C5        		push	bc
1839    339F  DD6E04    		ld	l,(ix+4)
1840    33A2  DD6605    		ld	h,(ix+5)
1841    33A5  010500    		ld	bc,5
1842    33A8  09        		add	hl,bc
1843    33A9  4E        		ld	c,(hl)
1844    33AA  97        		sub	a
1845    33AB  47        		ld	b,a
1846    33AC  C5        		push	bc
1847    33AD  216C31    		ld	hl,L5732
1848    33B0  CD0000    		call	_printf
1849    33B3  210C00    		ld	hl,12
1850    33B6  39        		add	hl,sp
1851    33B7  F9        		ld	sp,hl
1852                    	L1004:
1853                    	; 1123          }
1854                    	; 1124      /* not showing high 16 bits if 48 bit LBA */
1855                    	; 1125      lbastart = (unsigned long)partptr[8] +
1856                    	; 1126                 ((unsigned long)partptr[9] << 8) +
1857                    	; 1127                 ((unsigned long)partptr[10] << 16) +
1858                    	; 1128                 ((unsigned long)partptr[11] << 24);
1859    33B8  DDE5      		push	ix
1860    33BA  C1        		pop	bc
1861    33BB  21F4FF    		ld	hl,65524
1862    33BE  09        		add	hl,bc
1863    33BF  E5        		push	hl
1864    33C0  DD6E04    		ld	l,(ix+4)
1865    33C3  DD6605    		ld	h,(ix+5)
1866    33C6  010800    		ld	bc,8
1867    33C9  09        		add	hl,bc
1868    33CA  4D        		ld	c,l
1869    33CB  44        		ld	b,h
1870    33CC  97        		sub	a
1871    33CD  320000    		ld	(c.r0),a
1872    33D0  320100    		ld	(c.r0+1),a
1873    33D3  0A        		ld	a,(bc)
1874    33D4  320200    		ld	(c.r0+2),a
1875    33D7  97        		sub	a
1876    33D8  320300    		ld	(c.r0+3),a
1877    33DB  210000    		ld	hl,c.r0
1878    33DE  E5        		push	hl
1879    33DF  DD6E04    		ld	l,(ix+4)
1880    33E2  DD6605    		ld	h,(ix+5)
1881    33E5  010900    		ld	bc,9
1882    33E8  09        		add	hl,bc
1883    33E9  4D        		ld	c,l
1884    33EA  44        		ld	b,h
1885    33EB  97        		sub	a
1886    33EC  320000    		ld	(c.r1),a
1887    33EF  320100    		ld	(c.r1+1),a
1888    33F2  0A        		ld	a,(bc)
1889    33F3  320200    		ld	(c.r1+2),a
1890    33F6  97        		sub	a
1891    33F7  320300    		ld	(c.r1+3),a
1892    33FA  210000    		ld	hl,c.r1
1893    33FD  E5        		push	hl
1894    33FE  210800    		ld	hl,8
1895    3401  E5        		push	hl
1896    3402  CD0000    		call	c.llsh
1897    3405  CD0000    		call	c.ladd
1898    3408  DD6E04    		ld	l,(ix+4)
1899    340B  DD6605    		ld	h,(ix+5)
1900    340E  010A00    		ld	bc,10
1901    3411  09        		add	hl,bc
1902    3412  4D        		ld	c,l
1903    3413  44        		ld	b,h
1904    3414  97        		sub	a
1905    3415  320000    		ld	(c.r1),a
1906    3418  320100    		ld	(c.r1+1),a
1907    341B  0A        		ld	a,(bc)
1908    341C  320200    		ld	(c.r1+2),a
1909    341F  97        		sub	a
1910    3420  320300    		ld	(c.r1+3),a
1911    3423  210000    		ld	hl,c.r1
1912    3426  E5        		push	hl
1913    3427  211000    		ld	hl,16
1914    342A  E5        		push	hl
1915    342B  CD0000    		call	c.llsh
1916    342E  CD0000    		call	c.ladd
1917    3431  DD6E04    		ld	l,(ix+4)
1918    3434  DD6605    		ld	h,(ix+5)
1919    3437  010B00    		ld	bc,11
1920    343A  09        		add	hl,bc
1921    343B  4D        		ld	c,l
1922    343C  44        		ld	b,h
1923    343D  97        		sub	a
1924    343E  320000    		ld	(c.r1),a
1925    3441  320100    		ld	(c.r1+1),a
1926    3444  0A        		ld	a,(bc)
1927    3445  320200    		ld	(c.r1+2),a
1928    3448  97        		sub	a
1929    3449  320300    		ld	(c.r1+3),a
1930    344C  210000    		ld	hl,c.r1
1931    344F  E5        		push	hl
1932    3450  211800    		ld	hl,24
1933    3453  E5        		push	hl
1934    3454  CD0000    		call	c.llsh
1935    3457  CD0000    		call	c.ladd
1936    345A  CD0000    		call	c.mvl
1937    345D  F1        		pop	af
1938                    	; 1129      lbasize = (unsigned long)partptr[12] +
1939                    	; 1130                ((unsigned long)partptr[13] << 8) +
1940                    	; 1131                ((unsigned long)partptr[14] << 16) +
1941                    	; 1132                ((unsigned long)partptr[15] << 24);
1942    345E  DDE5      		push	ix
1943    3460  C1        		pop	bc
1944    3461  21F0FF    		ld	hl,65520
1945    3464  09        		add	hl,bc
1946    3465  E5        		push	hl
1947    3466  DD6E04    		ld	l,(ix+4)
1948    3469  DD6605    		ld	h,(ix+5)
1949    346C  010C00    		ld	bc,12
1950    346F  09        		add	hl,bc
1951    3470  4D        		ld	c,l
1952    3471  44        		ld	b,h
1953    3472  97        		sub	a
1954    3473  320000    		ld	(c.r0),a
1955    3476  320100    		ld	(c.r0+1),a
1956    3479  0A        		ld	a,(bc)
1957    347A  320200    		ld	(c.r0+2),a
1958    347D  97        		sub	a
1959    347E  320300    		ld	(c.r0+3),a
1960    3481  210000    		ld	hl,c.r0
1961    3484  E5        		push	hl
1962    3485  DD6E04    		ld	l,(ix+4)
1963    3488  DD6605    		ld	h,(ix+5)
1964    348B  010D00    		ld	bc,13
1965    348E  09        		add	hl,bc
1966    348F  4D        		ld	c,l
1967    3490  44        		ld	b,h
1968    3491  97        		sub	a
1969    3492  320000    		ld	(c.r1),a
1970    3495  320100    		ld	(c.r1+1),a
1971    3498  0A        		ld	a,(bc)
1972    3499  320200    		ld	(c.r1+2),a
1973    349C  97        		sub	a
1974    349D  320300    		ld	(c.r1+3),a
1975    34A0  210000    		ld	hl,c.r1
1976    34A3  E5        		push	hl
1977    34A4  210800    		ld	hl,8
1978    34A7  E5        		push	hl
1979    34A8  CD0000    		call	c.llsh
1980    34AB  CD0000    		call	c.ladd
1981    34AE  DD6E04    		ld	l,(ix+4)
1982    34B1  DD6605    		ld	h,(ix+5)
1983    34B4  010E00    		ld	bc,14
1984    34B7  09        		add	hl,bc
1985    34B8  4D        		ld	c,l
1986    34B9  44        		ld	b,h
1987    34BA  97        		sub	a
1988    34BB  320000    		ld	(c.r1),a
1989    34BE  320100    		ld	(c.r1+1),a
1990    34C1  0A        		ld	a,(bc)
1991    34C2  320200    		ld	(c.r1+2),a
1992    34C5  97        		sub	a
1993    34C6  320300    		ld	(c.r1+3),a
1994    34C9  210000    		ld	hl,c.r1
1995    34CC  E5        		push	hl
1996    34CD  211000    		ld	hl,16
1997    34D0  E5        		push	hl
1998    34D1  CD0000    		call	c.llsh
1999    34D4  CD0000    		call	c.ladd
2000    34D7  DD6E04    		ld	l,(ix+4)
2001    34DA  DD6605    		ld	h,(ix+5)
2002    34DD  010F00    		ld	bc,15
2003    34E0  09        		add	hl,bc
2004    34E1  4D        		ld	c,l
2005    34E2  44        		ld	b,h
2006    34E3  97        		sub	a
2007    34E4  320000    		ld	(c.r1),a
2008    34E7  320100    		ld	(c.r1+1),a
2009    34EA  0A        		ld	a,(bc)
2010    34EB  320200    		ld	(c.r1+2),a
2011    34EE  97        		sub	a
2012    34EF  320300    		ld	(c.r1+3),a
2013    34F2  210000    		ld	hl,c.r1
2014    34F5  E5        		push	hl
2015    34F6  211800    		ld	hl,24
2016    34F9  E5        		push	hl
2017    34FA  CD0000    		call	c.llsh
2018    34FD  CD0000    		call	c.ladd
2019    3500  CD0000    		call	c.mvl
2020    3503  F1        		pop	af
2021                    	; 1133      printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
2022    3504  DD66F7    		ld	h,(ix-9)
2023    3507  DD6EF6    		ld	l,(ix-10)
2024    350A  E5        		push	hl
2025    350B  DD66F5    		ld	h,(ix-11)
2026    350E  DD6EF4    		ld	l,(ix-12)
2027    3511  E5        		push	hl
2028    3512  DD66F7    		ld	h,(ix-9)
2029    3515  DD6EF6    		ld	l,(ix-10)
2030    3518  E5        		push	hl
2031    3519  DD66F5    		ld	h,(ix-11)
2032    351C  DD6EF4    		ld	l,(ix-12)
2033    351F  E5        		push	hl
2034    3520  21AB31    		ld	hl,L5042
2035    3523  CD0000    		call	_printf
2036    3526  F1        		pop	af
2037    3527  F1        		pop	af
2038    3528  F1        		pop	af
2039    3529  F1        		pop	af
2040                    	; 1134      printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
2041                    	; 1135             lbasize, lbasize, lbasize >> 11);
2042    352A  DDE5      		push	ix
2043    352C  C1        		pop	bc
2044    352D  21F0FF    		ld	hl,65520
2045    3530  09        		add	hl,bc
2046    3531  CD0000    		call	c.0mvf
2047    3534  210000    		ld	hl,c.r0
2048    3537  E5        		push	hl
2049    3538  210B00    		ld	hl,11
2050    353B  E5        		push	hl
2051    353C  CD0000    		call	c.ulrsh
2052    353F  E1        		pop	hl
2053    3540  23        		inc	hl
2054    3541  23        		inc	hl
2055    3542  4E        		ld	c,(hl)
2056    3543  23        		inc	hl
2057    3544  46        		ld	b,(hl)
2058    3545  C5        		push	bc
2059    3546  2B        		dec	hl
2060    3547  2B        		dec	hl
2061    3548  2B        		dec	hl
2062    3549  4E        		ld	c,(hl)
2063    354A  23        		inc	hl
2064    354B  46        		ld	b,(hl)
2065    354C  C5        		push	bc
2066    354D  DD66F3    		ld	h,(ix-13)
2067    3550  DD6EF2    		ld	l,(ix-14)
2068    3553  E5        		push	hl
2069    3554  DD66F1    		ld	h,(ix-15)
2070    3557  DD6EF0    		ld	l,(ix-16)
2071    355A  E5        		push	hl
2072    355B  DD66F3    		ld	h,(ix-13)
2073    355E  DD6EF2    		ld	l,(ix-14)
2074    3561  E5        		push	hl
2075    3562  DD66F1    		ld	h,(ix-15)
2076    3565  DD6EF0    		ld	l,(ix-16)
2077    3568  E5        		push	hl
2078    3569  21CF31    		ld	hl,L5142
2079    356C  CD0000    		call	_printf
2080    356F  210C00    		ld	hl,12
2081    3572  39        		add	hl,sp
2082    3573  F9        		ld	sp,hl
2083                    	; 1136      if (partptr[4] == 0xee)
2084    3574  DD6E04    		ld	l,(ix+4)
2085    3577  DD6605    		ld	h,(ix+5)
2086    357A  23        		inc	hl
2087    357B  23        		inc	hl
2088    357C  23        		inc	hl
2089    357D  23        		inc	hl
2090    357E  7E        		ld	a,(hl)
2091    357F  FEEE      		cp	238
2092    3581  2011      		jr	nz,L1104
2093                    	; 1137          sdgpthdr(lbastart);
2094    3583  DD66F7    		ld	h,(ix-9)
2095    3586  DD6EF6    		ld	l,(ix-10)
2096    3589  E5        		push	hl
2097    358A  DD66F5    		ld	h,(ix-11)
2098    358D  DD6EF4    		ld	l,(ix-12)
2099    3590  CDB22E    		call	_sdgpthdr
2100    3593  F1        		pop	af
2101                    	L1104:
2102                    	; 1138      }
2103    3594  C30000    		jp	c.rets
2104                    	L5242:
2105    3597  52        		.byte	82
2106    3598  65        		.byte	101
2107    3599  61        		.byte	97
2108    359A  64        		.byte	100
2109    359B  20        		.byte	32
2110    359C  4D        		.byte	77
2111    359D  42        		.byte	66
2112    359E  52        		.byte	82
2113    359F  0A        		.byte	10
2114    35A0  00        		.byte	0
2115                    	L251:
2116    35A1  00        		.byte	0
2117    35A2  00        		.byte	0
2118    35A3  00        		.byte	0
2119    35A4  00        		.byte	0
2120                    	L5342:
2121    35A5  20        		.byte	32
2122    35A6  20        		.byte	32
2123    35A7  63        		.byte	99
2124    35A8  61        		.byte	97
2125    35A9  6E        		.byte	110
2126    35AA  27        		.byte	39
2127    35AB  74        		.byte	116
2128    35AC  20        		.byte	32
2129    35AD  72        		.byte	114
2130    35AE  65        		.byte	101
2131    35AF  61        		.byte	97
2132    35B0  64        		.byte	100
2133    35B1  20        		.byte	32
2134    35B2  4D        		.byte	77
2135    35B3  42        		.byte	66
2136    35B4  52        		.byte	82
2137    35B5  20        		.byte	32
2138    35B6  73        		.byte	115
2139    35B7  65        		.byte	101
2140    35B8  63        		.byte	99
2141    35B9  74        		.byte	116
2142    35BA  6F        		.byte	111
2143    35BB  72        		.byte	114
2144    35BC  0A        		.byte	10
2145    35BD  00        		.byte	0
2146                    	L5442:
2147    35BE  20        		.byte	32
2148    35BF  20        		.byte	32
2149    35C0  6E        		.byte	110
2150    35C1  6F        		.byte	111
2151    35C2  20        		.byte	32
2152    35C3  4D        		.byte	77
2153    35C4  42        		.byte	66
2154    35C5  52        		.byte	82
2155    35C6  20        		.byte	32
2156    35C7  73        		.byte	115
2157    35C8  69        		.byte	105
2158    35C9  67        		.byte	103
2159    35CA  6E        		.byte	110
2160    35CB  61        		.byte	97
2161    35CC  74        		.byte	116
2162    35CD  75        		.byte	117
2163    35CE  72        		.byte	114
2164    35CF  65        		.byte	101
2165    35D0  20        		.byte	32
2166    35D1  66        		.byte	102
2167    35D2  6F        		.byte	111
2168    35D3  75        		.byte	117
2169    35D4  6E        		.byte	110
2170    35D5  64        		.byte	100
2171    35D6  0A        		.byte	10
2172    35D7  00        		.byte	0
2173                    	L5542:
2174    35D8  4D        		.byte	77
2175    35D9  42        		.byte	66
2176    35DA  52        		.byte	82
2177    35DB  20        		.byte	32
2178    35DC  70        		.byte	112
2179    35DD  61        		.byte	97
2180    35DE  72        		.byte	114
2181    35DF  74        		.byte	116
2182    35E0  69        		.byte	105
2183    35E1  74        		.byte	116
2184    35E2  69        		.byte	105
2185    35E3  6F        		.byte	111
2186    35E4  6E        		.byte	110
2187    35E5  20        		.byte	32
2188    35E6  65        		.byte	101
2189    35E7  6E        		.byte	110
2190    35E8  74        		.byte	116
2191    35E9  72        		.byte	114
2192    35EA  79        		.byte	121
2193    35EB  20        		.byte	32
2194    35EC  25        		.byte	37
2195    35ED  64        		.byte	100
2196    35EE  3A        		.byte	58
2197    35EF  20        		.byte	32
2198    35F0  00        		.byte	0
2199                    	; 1139  
2200                    	; 1140  /* read MBR partition information */
2201                    	; 1141  void sdmbrpart()
2202                    	; 1142      {
2203                    	_sdmbrpart:
2204    35F1  CD0000    		call	c.savs0
2205    35F4  21F6FF    		ld	hl,65526
2206    35F7  39        		add	hl,sp
2207    35F8  F9        		ld	sp,hl
2208                    	; 1143      int partidx;  /* partition index 1 - 4 */
2209                    	; 1144      unsigned char *entp; /* pointer to partition entry */
2210                    	; 1145  
2211                    	; 1146  #ifdef SDTEST
2212                    	; 1147      printf("Read MBR\n");
2213    35F9  219735    		ld	hl,L5242
2214    35FC  CD0000    		call	_printf
2215                    	; 1148  #endif
2216                    	; 1149      if (!sdread(sdrdbuf, 0))
2217    35FF  21A435    		ld	hl,L251+3
2218    3602  46        		ld	b,(hl)
2219    3603  2B        		dec	hl
2220    3604  4E        		ld	c,(hl)
2221    3605  C5        		push	bc
2222    3606  2B        		dec	hl
2223    3607  46        		ld	b,(hl)
2224    3608  2B        		dec	hl
2225    3609  4E        		ld	c,(hl)
2226    360A  C5        		push	bc
2227    360B  213200    		ld	hl,_sdrdbuf
2228    360E  CD671E    		call	_sdread
2229    3611  F1        		pop	af
2230    3612  F1        		pop	af
2231    3613  79        		ld	a,c
2232    3614  B0        		or	b
2233    3615  2009      		jr	nz,L1204
2234                    	; 1150          {
2235                    	; 1151  #ifdef SDTEST
2236                    	; 1152          printf("  can't read MBR sector\n");
2237    3617  21A535    		ld	hl,L5342
2238    361A  CD0000    		call	_printf
2239                    	; 1153  #endif
2240                    	; 1154          return;
2241    361D  C30000    		jp	c.rets0
2242                    	L1204:
2243                    	; 1155          }
2244                    	; 1156      curblkno = 0;
2245                    	; 1157      curblkok = YES;
2246    3620  210100    		ld	hl,1
2247                    	;    1  /*  z80boot.c
2248                    	;    2   *
2249                    	;    3   *  Boot code for my DIY Z80 Computer. This
2250                    	;    4   *  program is compiled with Whitesmiths/COSMIC
2251                    	;    5   *  C compiler for Z80.
2252                    	;    6   *
2253                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
2254                    	;    8   *
2255                    	;    9   *  Initializes the hardware and detects the
2256                    	;   10   *  presence and partitioning of an attached SD card.
2257                    	;   11   *
2258                    	;   12   *  You are free to use, modify, and redistribute
2259                    	;   13   *  this source code. No warranties are given.
2260                    	;   14   *  Hastily Cobbled Together 2021 and 2022
2261                    	;   15   *  by Hans-Ake Lund
2262                    	;   16   *
2263                    	;   17   */
2264                    	;   18  
2265                    	;   19  #include <std.h>
2266                    	;   20  #include "z80computer.h"
2267                    	;   21  #include "builddate.h"
2268                    	;   22  #include "progtype.h"
2269                    	;   23  
2270                    	;   24  #ifdef SDTEST
2271                    	;   25  #define PRGNAME "\nz80sdtest "
2272                    	;   26  #else
2273                    	;   27  #define PRGNAME "\nz80boot "
2274                    	;   28  #endif
2275                    	;   29  #define VERSION "version 0.4, "
2276                    	;   30  
2277                    	;   31  /* Response length in bytes
2278                    	;   32   */
2279                    	;   33  #define R1_LEN 1
2280                    	;   34  #define R3_LEN 5
2281                    	;   35  #define R7_LEN 5
2282                    	;   36  
2283                    	;   37  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
2284                    	;   38   * (The CRC7 byte in the tables below are only for information,
2285                    	;   39   * it is calculated by the sdcommand routine.)
2286                    	;   40   */
2287                    	;   41  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
2288                    	;   42  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
2289                    	;   43  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
2290                    	;   44  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
2291                    	;   45  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
2292                    	;   46  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
2293                    	;   47  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
2294                    	;   48  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
2295                    	;   49  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
2296                    	;   50  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
2297                    	;   51  
2298                    	;   52  /* Buffers
2299                    	;   53   */
2300                    	;   54  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
2301                    	;   55  
2302                    	;   56  unsigned char ocrreg[4];     /* SD card OCR register */
2303                    	;   57  unsigned char cidreg[16];    /* SD card CID register */
2304                    	;   58  unsigned char csdreg[16];    /* SD card CSD register */
2305                    	;   59  
2306                    	;   60  /* Variables
2307                    	;   61   */
2308                    	;   62  int curblkok;  /* if YES curblockno is read into buffer */
2309                    	;   63  int sdinitok;  /* SD card initialized and ready */
2310                    	;   64  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
2311                    	;   65  unsigned long blkmult;   /* block address multiplier */
2312                    	;   66  unsigned long curblkno;  /* block in buffer if curblkok == YES */
2313                    	;   67  
2314                    	;   68  /* CRC routines from:
2315                    	;   69   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
2316                    	;   70   */
2317                    	;   71  
2318                    	;   72  /*
2319                    	;   73  // Calculate CRC7
2320                    	;   74  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
2321                    	;   75  // input:
2322                    	;   76  //   crcIn - the CRC before (0 for first step)
2323                    	;   77  //   data - byte for CRC calculation
2324                    	;   78  // return: the new CRC7
2325                    	;   79  */
2326                    	;   80  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
2327                    	;   81      {
2328                    	;   82      const unsigned char g = 0x89;
2329                    	;   83      unsigned char i;
2330                    	;   84  
2331                    	;   85      crcIn ^= data;
2332                    	;   86      for (i = 0; i < 8; i++)
2333                    	;   87          {
2334                    	;   88          if (crcIn & 0x80) crcIn ^= g;
2335                    	;   89          crcIn <<= 1;
2336                    	;   90          }
2337                    	;   91  
2338                    	;   92      return crcIn;
2339                    	;   93      }
2340                    	;   94  
2341                    	;   95  /*
2342                    	;   96  // Calculate CRC16 CCITT
2343                    	;   97  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
2344                    	;   98  // input:
2345                    	;   99  //   crcIn - the CRC before (0 for rist step)
2346                    	;  100  //   data - byte for CRC calculation
2347                    	;  101  // return: the CRC16 value
2348                    	;  102  */
2349                    	;  103  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
2350                    	;  104      {
2351                    	;  105      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
2352                    	;  106      crcIn ^=  data;
2353                    	;  107      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
2354                    	;  108      crcIn ^= (crcIn << 8) << 4;
2355                    	;  109      crcIn ^= ((crcIn & 0xff) << 4) << 1;
2356                    	;  110  
2357                    	;  111      return crcIn;
2358                    	;  112      }
2359                    	;  113  
2360                    	;  114  /* Send command to SD card and recieve answer.
2361                    	;  115   * A command is 5 bytes long and is followed by
2362                    	;  116   * a CRC7 checksum byte.
2363                    	;  117   * Returns a pointer to the response
2364                    	;  118   * or 0 if no response start bit found.
2365                    	;  119   */
2366                    	;  120  unsigned char *sdcommand(unsigned char *sdcmdp,
2367                    	;  121                           unsigned char *recbuf, int recbytes)
2368                    	;  122      {
2369                    	;  123      int searchn;  /* byte counter to search for response */
2370                    	;  124      int sdcbytes; /* byte counter for bytes to send */
2371                    	;  125      unsigned char *retptr; /* pointer used to store response */
2372                    	;  126      unsigned char rbyte;   /* recieved byte */
2373                    	;  127      unsigned char crc = 0; /* calculated CRC7 */
2374                    	;  128  
2375                    	;  129      /* send 8*2 clockpules */
2376                    	;  130      spiio(0xff);
2377                    	;  131      spiio(0xff);
2378                    	;  132      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
2379                    	;  133          {
2380                    	;  134          crc = CRC7_one(crc, *sdcmdp);
2381                    	;  135          spiio(*sdcmdp++);
2382                    	;  136          }
2383                    	;  137      spiio(crc | 0x01);
2384                    	;  138      /* search for recieved byte with start bit
2385                    	;  139         for a maximum of 10 recieved bytes  */
2386                    	;  140      for (searchn = 10; 0 < searchn; searchn--)
2387                    	;  141          {
2388                    	;  142          rbyte = spiio(0xff);
2389                    	;  143          if ((rbyte & 0x80) == 0)
2390                    	;  144              break;
2391                    	;  145          }
2392                    	;  146      if (searchn == 0) /* no start bit found */
2393                    	;  147          return (NO);
2394                    	;  148      retptr = recbuf;
2395                    	;  149      *retptr++ = rbyte;
2396                    	;  150      for (; 1 < recbytes; recbytes--) /* recieve bytes */
2397                    	;  151          *retptr++ = spiio(0xff);
2398                    	;  152      return (recbuf);
2399                    	;  153      }
2400                    	;  154  
2401                    	;  155  /* Initialise SD card interface
2402                    	;  156   *
2403                    	;  157   * returns YES if ok and NO if not ok
2404                    	;  158   *
2405                    	;  159   * References:
2406                    	;  160   *   https://www.sdcard.org/downloads/pls/
2407                    	;  161   *      Physical Layer Simplified Specification version 8.0
2408                    	;  162   *
2409                    	;  163   * A nice flowchart how to initialize:
2410                    	;  164   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
2411                    	;  165   *
2412                    	;  166   */
2413                    	;  167  int sdinit()
2414                    	;  168      {
2415                    	;  169      int nbytes;  /* byte counter */
2416                    	;  170      int tries;   /* tries to get to active state or searching for data  */
2417                    	;  171      int wtloop;  /* timer loop when trying to enter active state */
2418                    	;  172      unsigned char cmdbuf[5];   /* buffer to build command in */
2419                    	;  173      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2420                    	;  174      unsigned char *statptr;    /* pointer to returned status from SD command */
2421                    	;  175      unsigned char crc;         /* crc register for CID and CSD */
2422                    	;  176      unsigned char rbyte;       /* recieved byte */
2423                    	;  177  #ifdef SDTEST
2424                    	;  178      unsigned char *prtptr;     /* for debug printing */
2425                    	;  179  #endif
2426                    	;  180  
2427                    	;  181      ledon();
2428                    	;  182      spideselect();
2429                    	;  183      sdinitok = NO;
2430                    	;  184  
2431                    	;  185      /* start to generate 9*8 clock pulses with not selected SD card */
2432                    	;  186      for (nbytes = 9; 0 < nbytes; nbytes--)
2433                    	;  187          spiio(0xff);
2434                    	;  188  #ifdef SDTEST
2435                    	;  189      printf("\nSent 8*8 (72) clock pulses, select not active\n");
2436                    	;  190  #endif
2437                    	;  191      spiselect();
2438                    	;  192  
2439                    	;  193      /* CMD0: GO_IDLE_STATE */
2440                    	;  194      memcpy(cmdbuf, cmd0, 5);
2441                    	;  195      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2442                    	;  196  #ifdef SDTEST
2443                    	;  197      if (!statptr)
2444                    	;  198          printf("CMD0: no response\n");
2445                    	;  199      else
2446                    	;  200          printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
2447                    	;  201  #endif
2448                    	;  202      if (!statptr)
2449                    	;  203          {
2450                    	;  204          spideselect();
2451                    	;  205          ledoff();
2452                    	;  206          return (NO);
2453                    	;  207          }
2454                    	;  208      /* CMD8: SEND_IF_COND */
2455                    	;  209      memcpy(cmdbuf, cmd8, 5);
2456                    	;  210      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
2457                    	;  211  #ifdef SDTEST
2458                    	;  212      if (!statptr)
2459                    	;  213          printf("CMD8: no response\n");
2460                    	;  214      else
2461                    	;  215          {
2462                    	;  216          printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
2463                    	;  217                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2464                    	;  218          if (!(statptr[0] & 0xfe)) /* no error */
2465                    	;  219              {
2466                    	;  220              if (statptr[4] == 0xaa)
2467                    	;  221                  printf("echo back ok, ");
2468                    	;  222              else
2469                    	;  223                  printf("invalid echo back\n");
2470                    	;  224              }
2471                    	;  225          }
2472                    	;  226  #endif
2473                    	;  227      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
2474                    	;  228          {
2475                    	;  229          sdver2 = NO;
2476                    	;  230  #ifdef SDTEST
2477                    	;  231          printf("probably SD ver. 1\n");
2478                    	;  232  #endif
2479                    	;  233          }
2480                    	;  234      else
2481                    	;  235          {
2482                    	;  236          sdver2 = YES;
2483                    	;  237          if (statptr[4] != 0xaa) /* but invalid echo back */
2484                    	;  238              {
2485                    	;  239              spideselect();
2486                    	;  240              ledoff();
2487                    	;  241              return (NO);
2488                    	;  242              }
2489                    	;  243  #ifdef SDTEST
2490                    	;  244          printf("SD ver 2\n");
2491                    	;  245  #endif
2492                    	;  246          }
2493                    	;  247  
2494                    	;  248      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
2495                    	;  249      for (tries = 0; tries < 20; tries++)
2496                    	;  250          {
2497                    	;  251          memcpy(cmdbuf, cmd55, 5);
2498                    	;  252          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2499                    	;  253  #ifdef SDTEST
2500                    	;  254          if (!statptr)
2501                    	;  255              printf("CMD55: no response\n");
2502                    	;  256          else
2503                    	;  257              printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
2504                    	;  258  #endif
2505                    	;  259          if (!statptr)
2506                    	;  260              {
2507                    	;  261              spideselect();
2508                    	;  262              ledoff();
2509                    	;  263              return (NO);
2510                    	;  264              }
2511                    	;  265          memcpy(cmdbuf, acmd41, 5);
2512                    	;  266          if (sdver2)
2513                    	;  267              cmdbuf[1] = 0x40;
2514                    	;  268          else
2515                    	;  269              cmdbuf[1] = 0x00;
2516                    	;  270          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2517                    	;  271  #ifdef SDTEST
2518                    	;  272          if (!statptr)
2519                    	;  273              printf("ACMD41: no response\n");
2520                    	;  274          else
2521                    	;  275              printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
2522                    	;  276                     statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
2523                    	;  277  #endif
2524                    	;  278          if (!statptr)
2525                    	;  279              {
2526                    	;  280              spideselect();
2527                    	;  281              ledoff();
2528                    	;  282              return (NO);
2529                    	;  283              }
2530                    	;  284          if (statptr[0] == 0x00) /* now the SD card is ready */
2531                    	;  285              {
2532                    	;  286              break;
2533                    	;  287              }
2534                    	;  288          for (wtloop = 0; wtloop < tries * 100; wtloop++)
2535                    	;  289              ; /* wait loop, time increasing for each try */
2536                    	;  290          }
2537                    	;  291  
2538                    	;  292      /* CMD58: READ_OCR */
2539                    	;  293      /* According to the flow chart this should not work
2540                    	;  294         for SD ver. 1 but the response is ok anyway
2541                    	;  295         all tested SD cards  */
2542                    	;  296      memcpy(cmdbuf, cmd58, 5);
2543                    	;  297      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
2544                    	;  298  #ifdef SDTEST
2545                    	;  299      if (!statptr)
2546                    	;  300          printf("CMD58: no response\n");
2547                    	;  301      else
2548                    	;  302          printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
2549                    	;  303                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2550                    	;  304  #endif
2551                    	;  305      if (!statptr)
2552                    	;  306          {
2553                    	;  307          spideselect();
2554                    	;  308          ledoff();
2555                    	;  309          return (NO);
2556                    	;  310          }
2557                    	;  311      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
2558                    	;  312      blkmult = 1; /* assume block address */
2559                    	;  313      if (ocrreg[0] & 0x80)
2560                    	;  314          {
2561                    	;  315          /* SD Ver.2+ */
2562                    	;  316          if (!(ocrreg[0] & 0x40))
2563                    	;  317              {
2564                    	;  318              /* SD Ver.2+, Byte address */
2565                    	;  319              blkmult = 512;
2566                    	;  320              }
2567                    	;  321          }
2568                    	;  322  
2569                    	;  323      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
2570                    	;  324      if (blkmult == 512)
2571                    	;  325          {
2572                    	;  326          memcpy(cmdbuf, cmd16, 5);
2573                    	;  327          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2574                    	;  328  #ifdef SDTEST
2575                    	;  329          if (!statptr)
2576                    	;  330              printf("CMD16: no response\n");
2577                    	;  331          else
2578                    	;  332              printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
2579                    	;  333                  statptr[0]);
2580                    	;  334  #endif
2581                    	;  335          if (!statptr)
2582                    	;  336              {
2583                    	;  337              spideselect();
2584                    	;  338              ledoff();
2585                    	;  339              return (NO);
2586                    	;  340              }
2587                    	;  341          }
2588                    	;  342      /* Register information:
2589                    	;  343       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
2590                    	;  344       */
2591                    	;  345  
2592                    	;  346      /* CMD10: SEND_CID */
2593                    	;  347      memcpy(cmdbuf, cmd10, 5);
2594                    	;  348      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2595                    	;  349  #ifdef SDTEST
2596                    	;  350      if (!statptr)
2597                    	;  351          printf("CMD10: no response\n");
2598                    	;  352      else
2599                    	;  353          printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
2600                    	;  354  #endif
2601                    	;  355      if (!statptr)
2602                    	;  356          {
2603                    	;  357          spideselect();
2604                    	;  358          ledoff();
2605                    	;  359          return (NO);
2606                    	;  360          }
2607                    	;  361      /* looking for 0xfe that is the byte before data */
2608                    	;  362      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2609                    	;  363          ;
2610                    	;  364      if (tries == 0) /* tried too many times */
2611                    	;  365          {
2612                    	;  366  #ifdef SDTEST
2613                    	;  367          printf("  No data found\n");
2614                    	;  368  #endif
2615                    	;  369          spideselect();
2616                    	;  370          ledoff();
2617                    	;  371          return (NO);
2618                    	;  372          }
2619                    	;  373      else
2620                    	;  374          {
2621                    	;  375          crc = 0;
2622                    	;  376          for (nbytes = 0; nbytes < 15; nbytes++)
2623                    	;  377              {
2624                    	;  378              rbyte = spiio(0xff);
2625                    	;  379              cidreg[nbytes] = rbyte;
2626                    	;  380              crc = CRC7_one(crc, rbyte);
2627                    	;  381              }
2628                    	;  382          cidreg[15] = spiio(0xff);
2629                    	;  383          crc |= 0x01;
2630                    	;  384          /* some SD cards need additional clock pulses */
2631                    	;  385          for (nbytes = 9; 0 < nbytes; nbytes--)
2632                    	;  386              spiio(0xff);
2633                    	;  387  #ifdef SDTEST
2634                    	;  388          prtptr = &cidreg[0];
2635                    	;  389          printf("  CID: [");
2636                    	;  390          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2637                    	;  391              printf("%02x ", *prtptr);
2638                    	;  392          prtptr = &cidreg[0];
2639                    	;  393          printf("\b] |");
2640                    	;  394          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2641                    	;  395              {
2642                    	;  396              if ((' ' <= *prtptr) && (*prtptr < 127))
2643                    	;  397                  putchar(*prtptr);
2644                    	;  398              else
2645                    	;  399                  putchar('.');
2646                    	;  400              }
2647                    	;  401          printf("|\n");
2648                    	;  402          if (crc == cidreg[15])
2649                    	;  403              {
2650                    	;  404              printf("CRC7 ok: [%02x]\n", crc);
2651                    	;  405              }
2652                    	;  406          else
2653                    	;  407              {
2654                    	;  408              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2655                    	;  409                  crc, cidreg[15]);
2656                    	;  410              /* could maybe return failure here */
2657                    	;  411              }
2658                    	;  412  #endif
2659                    	;  413          }
2660                    	;  414  
2661                    	;  415      /* CMD9: SEND_CSD */
2662                    	;  416      memcpy(cmdbuf, cmd9, 5);
2663                    	;  417      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2664                    	;  418  #ifdef SDTEST
2665                    	;  419      if (!statptr)
2666                    	;  420          printf("CMD9: no response\n");
2667                    	;  421      else
2668                    	;  422          printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
2669                    	;  423  #endif
2670                    	;  424      if (!statptr)
2671                    	;  425          {
2672                    	;  426          spideselect();
2673                    	;  427          ledoff();
2674                    	;  428          return (NO);
2675                    	;  429          }
2676                    	;  430      /* looking for 0xfe that is the byte before data */
2677                    	;  431      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2678                    	;  432          ;
2679                    	;  433      if (tries == 0) /* tried too many times */
2680                    	;  434          {
2681                    	;  435  #ifdef SDTEST
2682                    	;  436          printf("  No data found\n");
2683                    	;  437  #endif
2684                    	;  438          return (NO);
2685                    	;  439          }
2686                    	;  440      else
2687                    	;  441          {
2688                    	;  442          crc = 0;
2689                    	;  443          for (nbytes = 0; nbytes < 15; nbytes++)
2690                    	;  444              {
2691                    	;  445              rbyte = spiio(0xff);
2692                    	;  446              csdreg[nbytes] = rbyte;
2693                    	;  447              crc = CRC7_one(crc, rbyte);
2694                    	;  448              }
2695                    	;  449          csdreg[15] = spiio(0xff);
2696                    	;  450          crc |= 0x01;
2697                    	;  451          /* some SD cards need additional clock pulses */
2698                    	;  452          for (nbytes = 9; 0 < nbytes; nbytes--)
2699                    	;  453              spiio(0xff);
2700                    	;  454  #ifdef SDTEST
2701                    	;  455          prtptr = &csdreg[0];
2702                    	;  456          printf("  CSD: [");
2703                    	;  457          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2704                    	;  458              printf("%02x ", *prtptr);
2705                    	;  459          prtptr = &csdreg[0];
2706                    	;  460          printf("\b] |");
2707                    	;  461          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2708                    	;  462              {
2709                    	;  463              if ((' ' <= *prtptr) && (*prtptr < 127))
2710                    	;  464                  putchar(*prtptr);
2711                    	;  465              else
2712                    	;  466                  putchar('.');
2713                    	;  467              }
2714                    	;  468          printf("|\n");
2715                    	;  469          if (crc == csdreg[15])
2716                    	;  470              {
2717                    	;  471              printf("CRC7 ok: [%02x]\n", crc);
2718                    	;  472              }
2719                    	;  473          else
2720                    	;  474              {
2721                    	;  475              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2722                    	;  476                  crc, csdreg[15]);
2723                    	;  477              /* could maybe return failure here */
2724                    	;  478              }
2725                    	;  479  #endif
2726                    	;  480          }
2727                    	;  481  
2728                    	;  482      for (nbytes = 9; 0 < nbytes; nbytes--)
2729                    	;  483          spiio(0xff);
2730                    	;  484  #ifdef SDTEST
2731                    	;  485      printf("Sent 9*8 (72) clock pulses, select active\n");
2732                    	;  486  #endif
2733                    	;  487  
2734                    	;  488      sdinitok = YES;
2735                    	;  489  
2736                    	;  490      spideselect();
2737                    	;  491      ledoff();
2738                    	;  492  
2739                    	;  493      return (YES);
2740                    	;  494      }
2741                    	;  495  
2742                    	;  496  /* print OCR, CID and CSD registers*/
2743                    	;  497  void sdprtreg()
2744                    	;  498      {
2745                    	;  499      unsigned int n;
2746                    	;  500      unsigned int csize;
2747                    	;  501      unsigned long devsize;
2748                    	;  502      unsigned long capacity;
2749                    	;  503  
2750                    	;  504      if (!sdinitok)
2751                    	;  505          {
2752                    	;  506          printf("SD card not initialized\n");
2753                    	;  507          return;
2754                    	;  508          }
2755                    	;  509      printf("SD card information:");
2756                    	;  510      if (ocrreg[0] & 0x80)
2757                    	;  511          {
2758                    	;  512          if (ocrreg[0] & 0x40)
2759                    	;  513              printf("  SD card ver. 2+, Block address\n");
2760                    	;  514          else
2761                    	;  515              {
2762                    	;  516              if (sdver2)
2763                    	;  517                  printf("  SD card ver. 2+, Byte address\n");
2764                    	;  518              else
2765                    	;  519                  printf("  SD card ver. 1, Byte address\n");
2766                    	;  520              }
2767                    	;  521          }
2768                    	;  522      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
2769                    	;  523      printf("OEM ID: %.2s, ", &cidreg[1]);
2770                    	;  524      printf("Product name: %.5s\n", &cidreg[3]);
2771                    	;  525      printf("  Product revision: %d.%d, ",
2772                    	;  526             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
2773                    	;  527      printf("Serial number: %lu\n",
2774                    	;  528             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
2775                    	;  529      printf("  Manufacturing date: %d-%d, ",
2776                    	;  530             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2777                    	;  531      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
2778                    	;  532          {
2779                    	;  533          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2780                    	;  534          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2781                    	;  535                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2782                    	;  536          capacity = (unsigned long) csize << (n-10);
2783                    	;  537          printf("Device capacity: %lu MByte\n", capacity >> 10);
2784                    	;  538          }
2785                    	;  539      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
2786                    	;  540          {
2787                    	;  541          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2788                    	;  542                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2789                    	;  543          capacity = devsize << 9;
2790                    	;  544          printf("Device capacity: %lu MByte\n", capacity >> 10);
2791                    	;  545          }
2792                    	;  546      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
2793                    	;  547          {
2794                    	;  548          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2795                    	;  549                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2796                    	;  550          capacity = devsize << 9;
2797                    	;  551          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
2798                    	;  552          }
2799                    	;  553  
2800                    	;  554  #ifdef SDTEST
2801                    	;  555  
2802                    	;  556      printf("--------------------------------------\n");
2803                    	;  557      printf("OCR register:\n");
2804                    	;  558      if (ocrreg[2] & 0x80)
2805                    	;  559          printf("2.7-2.8V (bit 15) ");
2806                    	;  560      if (ocrreg[1] & 0x01)
2807                    	;  561          printf("2.8-2.9V (bit 16) ");
2808                    	;  562      if (ocrreg[1] & 0x02)
2809                    	;  563          printf("2.9-3.0V (bit 17) ");
2810                    	;  564      if (ocrreg[1] & 0x04)
2811                    	;  565          printf("3.0-3.1V (bit 18) \n");
2812                    	;  566      if (ocrreg[1] & 0x08)
2813                    	;  567          printf("3.1-3.2V (bit 19) ");
2814                    	;  568      if (ocrreg[1] & 0x10)
2815                    	;  569          printf("3.2-3.3V (bit 20) ");
2816                    	;  570      if (ocrreg[1] & 0x20)
2817                    	;  571          printf("3.3-3.4V (bit 21) ");
2818                    	;  572      if (ocrreg[1] & 0x40)
2819                    	;  573          printf("3.4-3.5V (bit 22) \n");
2820                    	;  574      if (ocrreg[1] & 0x80)
2821                    	;  575          printf("3.5-3.6V (bit 23) \n");
2822                    	;  576      if (ocrreg[0] & 0x01)
2823                    	;  577          printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
2824                    	;  578      if (ocrreg[0] & 0x08)
2825                    	;  579          printf("Over 2TB support Status (CO2T) (bit 27) set\n");
2826                    	;  580      if (ocrreg[0] & 0x20)
2827                    	;  581          printf("UHS-II Card Status (bit 29) set ");
2828                    	;  582      if (ocrreg[0] & 0x80)
2829                    	;  583          {
2830                    	;  584          if (ocrreg[0] & 0x40)
2831                    	;  585              {
2832                    	;  586              printf("Card Capacity Status (CCS) (bit 30) set\n");
2833                    	;  587              printf("  SD Ver.2+, Block address");
2834                    	;  588              }
2835                    	;  589          else
2836                    	;  590              {
2837                    	;  591              printf("Card Capacity Status (CCS) (bit 30) not set\n");
2838                    	;  592              if (sdver2)
2839                    	;  593                  printf("  SD Ver.2+, Byte address");
2840                    	;  594              else
2841                    	;  595                  printf("  SD Ver.1, Byte address");
2842                    	;  596              }
2843                    	;  597          printf("\nCard power up status bit (busy) (bit 31) set\n");
2844                    	;  598          }
2845                    	;  599      else
2846                    	;  600          {
2847                    	;  601          printf("\nCard power up status bit (busy) (bit 31) not set.\n");
2848                    	;  602          printf("  This bit is not set if the card has not finished the power up routine.\n");
2849                    	;  603          }
2850                    	;  604      printf("--------------------------------------\n");
2851                    	;  605      printf("CID register:\n");
2852                    	;  606      printf("MID: 0x%02x, ", cidreg[0]);
2853                    	;  607      printf("OID: %.2s, ", &cidreg[1]);
2854                    	;  608      printf("PNM: %.5s, ", &cidreg[3]);
2855                    	;  609      printf("PRV: %d.%d, ",
2856                    	;  610             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
2857                    	;  611      printf("PSN: %lu, ",
2858                    	;  612             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
2859                    	;  613      printf("MDT: %d-%d\n",
2860                    	;  614             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2861                    	;  615      printf("--------------------------------------\n");
2862                    	;  616      printf("CSD register:\n");
2863                    	;  617      if ((csdreg[0] & 0xc0) == 0x00)
2864                    	;  618          {
2865                    	;  619          printf("CSD Version 1.0, Standard Capacity\n");
2866                    	;  620          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2867                    	;  621          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2868                    	;  622                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2869                    	;  623          capacity = (unsigned long) csize << (n-10);
2870                    	;  624          printf(" Device capacity: %lu KByte, %lu MByte\n",
2871                    	;  625                 capacity, capacity >> 10);
2872                    	;  626          }
2873                    	;  627      if ((csdreg[0] & 0xc0) == 0x40)
2874                    	;  628          {
2875                    	;  629          printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
2876                    	;  630          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2877                    	;  631                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2878                    	;  632          capacity = devsize << 9;
2879                    	;  633          printf(" Device capacity: %lu KByte, %lu MByte\n",
2880                    	;  634                 capacity, capacity >> 10);
2881                    	;  635          }
2882                    	;  636      if ((csdreg[0] & 0xc0) == 0x80)
2883                    	;  637          {
2884                    	;  638          printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
2885                    	;  639          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2886                    	;  640                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2887                    	;  641          capacity = devsize << 9;
2888                    	;  642          printf(" Device capacity: %lu KByte, %lu MByte\n",
2889                    	;  643                 capacity, capacity >> 10);
2890                    	;  644          }
2891                    	;  645      printf("--------------------------------------\n");
2892                    	;  646  
2893                    	;  647  #endif /* SDTEST */
2894                    	;  648  
2895                    	;  649      }
2896                    	;  650  
2897                    	;  651  /* Read data block of 512 bytes to buffer
2898                    	;  652   * Returns YES if ok or NO if error
2899                    	;  653   */
2900                    	;  654  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
2901                    	;  655      {
2902                    	;  656      unsigned char *statptr;
2903                    	;  657      unsigned char rbyte;
2904                    	;  658      unsigned char cmdbuf[5];   /* buffer to build command in */
2905                    	;  659      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2906                    	;  660      int nbytes;
2907                    	;  661      int tries;
2908                    	;  662      unsigned long blktoread;
2909                    	;  663      unsigned int rxcrc16;
2910                    	;  664      unsigned int calcrc16;
2911                    	;  665  
2912                    	;  666      ledon();
2913                    	;  667      spiselect();
2914                    	;  668  
2915                    	;  669      if (!sdinitok)
2916                    	;  670          {
2917                    	;  671  #ifdef SDTEST
2918                    	;  672          printf("SD card not initialized\n");
2919                    	;  673  #endif
2920                    	;  674          spideselect();
2921                    	;  675          ledoff();
2922                    	;  676          return (NO);
2923                    	;  677          }
2924                    	;  678  
2925                    	;  679      /* CMD17: READ_SINGLE_BLOCK */
2926                    	;  680      /* Insert block # into command */
2927                    	;  681      memcpy(cmdbuf, cmd17, 5);
2928                    	;  682      blktoread = blkmult * rdblkno;
2929                    	;  683      cmdbuf[4] = blktoread & 0xff;
2930                    	;  684      blktoread = blktoread >> 8;
2931                    	;  685      cmdbuf[3] = blktoread & 0xff;
2932                    	;  686      blktoread = blktoread >> 8;
2933                    	;  687      cmdbuf[2] = blktoread & 0xff;
2934                    	;  688      blktoread = blktoread >> 8;
2935                    	;  689      cmdbuf[1] = blktoread & 0xff;
2936                    	;  690  
2937                    	;  691  #ifdef SDTEST
2938                    	;  692      printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2939                    	;  693                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2940                    	;  694  #endif
2941                    	;  695      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2942                    	;  696  #ifdef SDTEST
2943                    	;  697          printf("CMD17 R1 response [%02x]\n", statptr[0]);
2944                    	;  698  #endif
2945                    	;  699      if (statptr[0])
2946                    	;  700          {
2947                    	;  701  #ifdef SDTEST
2948                    	;  702          printf("  could not read block\n");
2949                    	;  703  #endif
2950                    	;  704          spideselect();
2951                    	;  705          ledoff();
2952                    	;  706          return (NO);
2953                    	;  707          }
2954                    	;  708      /* looking for 0xfe that is the byte before data */
2955                    	;  709      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
2956                    	;  710          {
2957                    	;  711          if ((rbyte & 0xe0) == 0x00)
2958                    	;  712              {
2959                    	;  713              /* If a read operation fails and the card cannot provide
2960                    	;  714                 the required data, it will send a data error token instead
2961                    	;  715               */
2962                    	;  716  #ifdef SDTEST
2963                    	;  717              printf("  read error: [%02x]\n", rbyte);
2964                    	;  718  #endif
2965                    	;  719              spideselect();
2966                    	;  720              ledoff();
2967                    	;  721              return (NO);
2968                    	;  722              }
2969                    	;  723          }
2970                    	;  724      if (tries == 0) /* tried too many times */
2971                    	;  725          {
2972                    	;  726  #ifdef SDTEST
2973                    	;  727          printf("  no data found\n");
2974                    	;  728  #endif
2975                    	;  729          spideselect();
2976                    	;  730          ledoff();
2977                    	;  731          return (NO);
2978                    	;  732          }
2979                    	;  733      else
2980                    	;  734          {
2981                    	;  735          calcrc16 = 0;
2982                    	;  736          for (nbytes = 0; nbytes < 512; nbytes++)
2983                    	;  737              {
2984                    	;  738              rbyte = spiio(0xff);
2985                    	;  739              calcrc16 = CRC16_one(calcrc16, rbyte);
2986                    	;  740              rdbuf[nbytes] = rbyte;
2987                    	;  741              }
2988                    	;  742          rxcrc16 = spiio(0xff) << 8;
2989                    	;  743          rxcrc16 += spiio(0xff);
2990                    	;  744  
2991                    	;  745  #ifdef SDTEST
2992                    	;  746          printf("  read data block %ld:\n", rdblkno);
2993                    	;  747  #endif
2994                    	;  748          if (rxcrc16 != calcrc16)
2995                    	;  749              {
2996                    	;  750  #ifdef SDTEST
2997                    	;  751              printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
2998                    	;  752                  rxcrc16, calcrc16);
2999                    	;  753  #endif
3000                    	;  754              spideselect();
3001                    	;  755              ledoff();
3002                    	;  756              return (NO);
3003                    	;  757              }
3004                    	;  758          }
3005                    	;  759      spideselect();
3006                    	;  760      ledoff();
3007                    	;  761      return (YES);
3008                    	;  762      }
3009                    	;  763  
3010                    	;  764  /* Write data block of 512 bytes from buffer
3011                    	;  765   * Returns YES if ok or NO if error
3012                    	;  766   */
3013                    	;  767  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
3014                    	;  768      {
3015                    	;  769      unsigned char *statptr;
3016                    	;  770      unsigned char rbyte;
3017                    	;  771      unsigned char tbyte;
3018                    	;  772      unsigned char cmdbuf[5];   /* buffer to build command in */
3019                    	;  773      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3020                    	;  774      int nbytes;
3021                    	;  775      int tries;
3022                    	;  776      unsigned long blktowrite;
3023                    	;  777      unsigned int calcrc16;
3024                    	;  778  
3025                    	;  779      ledon();
3026                    	;  780      spiselect();
3027                    	;  781  
3028                    	;  782      if (!sdinitok)
3029                    	;  783          {
3030                    	;  784  #ifdef SDTEST
3031                    	;  785          printf("SD card not initialized\n");
3032                    	;  786  #endif
3033                    	;  787          spideselect();
3034                    	;  788          ledoff();
3035                    	;  789          return (NO);
3036                    	;  790          }
3037                    	;  791  
3038                    	;  792  #ifdef SDTEST
3039                    	;  793      printf("  write data block %ld:\n", wrblkno);
3040                    	;  794  #endif
3041                    	;  795      /* CMD24: WRITE_SINGLE_BLOCK */
3042                    	;  796      /* Insert block # into command */
3043                    	;  797      memcpy(cmdbuf, cmd24, 5);
3044                    	;  798      blktowrite = blkmult * wrblkno;
3045                    	;  799      cmdbuf[4] = blktowrite & 0xff;
3046                    	;  800      blktowrite = blktowrite >> 8;
3047                    	;  801      cmdbuf[3] = blktowrite & 0xff;
3048                    	;  802      blktowrite = blktowrite >> 8;
3049                    	;  803      cmdbuf[2] = blktowrite & 0xff;
3050                    	;  804      blktowrite = blktowrite >> 8;
3051                    	;  805      cmdbuf[1] = blktowrite & 0xff;
3052                    	;  806  
3053                    	;  807  #ifdef SDTEST
3054                    	;  808      printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
3055                    	;  809                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
3056                    	;  810  #endif
3057                    	;  811      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3058                    	;  812  #ifdef SDTEST
3059                    	;  813          printf("CMD24 R1 response [%02x]\n", statptr[0]);
3060                    	;  814  #endif
3061                    	;  815      if (statptr[0])
3062                    	;  816          {
3063                    	;  817  #ifdef SDTEST
3064                    	;  818          printf("  could not write block\n");
3065                    	;  819  #endif
3066                    	;  820          spideselect();
3067                    	;  821          ledoff();
3068                    	;  822          return (NO);
3069                    	;  823          }
3070                    	;  824      /* send 0xfe, the byte before data */
3071                    	;  825      spiio(0xfe);
3072                    	;  826      /* initialize crc and send block */
3073                    	;  827      calcrc16 = 0;
3074                    	;  828      for (nbytes = 0; nbytes < 512; nbytes++)
3075                    	;  829          {
3076                    	;  830          tbyte = wrbuf[nbytes];
3077                    	;  831          spiio(tbyte);
3078                    	;  832          calcrc16 = CRC16_one(calcrc16, tbyte);
3079                    	;  833          }
3080                    	;  834      spiio((calcrc16 >> 8) & 0xff);
3081                    	;  835      spiio(calcrc16 & 0xff);
3082                    	;  836  
3083                    	;  837      /* check data resposnse */
3084                    	;  838      for (tries = 20; 
3085                    	;  839          0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
3086                    	;  840          tries--)
3087                    	;  841          ;
3088                    	;  842      if (tries == 0)
3089                    	;  843          {
3090                    	;  844  #ifdef SDTEST
3091                    	;  845          printf("No data response\n");
3092                    	;  846  #endif
3093                    	;  847          spideselect();
3094                    	;  848          ledoff();
3095                    	;  849          return (NO);
3096                    	;  850          }
3097                    	;  851      else
3098                    	;  852          {
3099                    	;  853  #ifdef SDTEST
3100                    	;  854          printf("Data response [%02x]", 0x1f & rbyte);
3101                    	;  855  #endif
3102                    	;  856          if ((0x1f & rbyte) == 0x05)
3103                    	;  857              {
3104                    	;  858  #ifdef SDTEST
3105                    	;  859              printf(", data accepted\n");
3106                    	;  860  #endif
3107                    	;  861              for (nbytes = 9; 0 < nbytes; nbytes--)
3108                    	;  862                  spiio(0xff);
3109                    	;  863  #ifdef SDTEST
3110                    	;  864              printf("Sent 9*8 (72) clock pulses, select active\n");
3111                    	;  865  #endif
3112                    	;  866              spideselect();
3113                    	;  867              ledoff();
3114                    	;  868              return (YES);
3115                    	;  869              }
3116                    	;  870          else
3117                    	;  871              {
3118                    	;  872  #ifdef SDTEST
3119                    	;  873              printf(", data not accepted\n");
3120                    	;  874  #endif
3121                    	;  875              spideselect();
3122                    	;  876              ledoff();
3123                    	;  877              return (NO);
3124                    	;  878              }
3125                    	;  879          }
3126                    	;  880      }
3127                    	;  881  
3128                    	;  882  /* Print data in 512 byte buffer */
3129                    	;  883  void sddatprt(unsigned char *prtbuf)
3130                    	;  884      {
3131                    	;  885      /* Variables used for "pretty-print" */
3132                    	;  886      int allzero, dmpline, dotprted, lastallz, nbytes;
3133                    	;  887      unsigned char *prtptr;
3134                    	;  888  
3135                    	;  889      prtptr = prtbuf;
3136                    	;  890      dotprted = NO;
3137                    	;  891      lastallz = NO;
3138                    	;  892      for (dmpline = 0; dmpline < 32; dmpline++)
3139                    	;  893          {
3140                    	;  894          /* test if all 16 bytes are 0x00 */
3141                    	;  895          allzero = YES;
3142                    	;  896          for (nbytes = 0; nbytes < 16; nbytes++)
3143                    	;  897              {
3144                    	;  898              if (prtptr[nbytes] != 0)
3145                    	;  899                  allzero = NO;
3146                    	;  900              }
3147                    	;  901          if (lastallz && allzero)
3148                    	;  902              {
3149                    	;  903              if (!dotprted)
3150                    	;  904                  {
3151                    	;  905                  printf("*\n");
3152                    	;  906                  dotprted = YES;
3153                    	;  907                  }
3154                    	;  908              }
3155                    	;  909          else
3156                    	;  910              {
3157                    	;  911              dotprted = NO;
3158                    	;  912              /* print offset */
3159                    	;  913              printf("%04x ", dmpline * 16);
3160                    	;  914              /* print 16 bytes in hex */
3161                    	;  915              for (nbytes = 0; nbytes < 16; nbytes++)
3162                    	;  916                  printf("%02x ", prtptr[nbytes]);
3163                    	;  917              /* print these bytes in ASCII if printable */
3164                    	;  918              printf(" |");
3165                    	;  919              for (nbytes = 0; nbytes < 16; nbytes++)
3166                    	;  920                  {
3167                    	;  921                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
3168                    	;  922                      putchar(prtptr[nbytes]);
3169                    	;  923                  else
3170                    	;  924                      putchar('.');
3171                    	;  925                  }
3172                    	;  926              printf("|\n");
3173                    	;  927              }
3174                    	;  928          prtptr += 16;
3175                    	;  929          lastallz = allzero;
3176                    	;  930          }
3177                    	;  931      }
3178                    	;  932  
3179                    	;  933  /* print GUID (mixed endian format) */
3180                    	;  934  void prtguid(unsigned char *guidptr)
3181                    	;  935      {
3182                    	;  936      int index;
3183                    	;  937  
3184                    	;  938      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
3185                    	;  939      printf("%02x%02x-", guidptr[5], guidptr[4]);
3186                    	;  940      printf("%02x%02x-", guidptr[7], guidptr[6]);
3187                    	;  941      printf("%02x%02x-", guidptr[8], guidptr[9]);
3188                    	;  942      printf("%02x%02x%02x%02x%02x%02x",
3189                    	;  943             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
3190                    	;  944      printf("\n  [");
3191                    	;  945      for (index = 0; index < 16; index++)
3192                    	;  946          printf("%02x ", guidptr[index]);
3193                    	;  947      printf("\b]");
3194                    	;  948      }
3195                    	;  949  
3196                    	;  950  /* print GPT entry */
3197                    	;  951  void prtgptent(unsigned int entryno)
3198                    	;  952      {
3199                    	;  953      int index;
3200                    	;  954      int entryidx;
3201                    	;  955      int hasname;
3202                    	;  956      unsigned int block;
3203                    	;  957      unsigned char *rxdata;
3204                    	;  958      unsigned char *entryptr;
3205                    	;  959      unsigned char tstzero = 0;
3206                    	;  960      unsigned long flba;
3207                    	;  961      unsigned long llba;
3208                    	;  962  
3209                    	;  963      block = 2 + (entryno / 4);
3210                    	;  964      if ((curblkno != block) || !curblkok)
3211                    	;  965          {
3212                    	;  966          if (!sdread(sdrdbuf, block))
3213                    	;  967              {
3214                    	;  968              printf("Can't read GPT entry block\n");
3215                    	;  969              return;
3216                    	;  970              }
3217                    	;  971          curblkno = block;
3218                    	;  972          curblkok = YES;
3219                    	;  973          }
3220                    	;  974      rxdata = sdrdbuf;
3221                    	;  975      entryptr = rxdata + (128 * (entryno % 4));
3222                    	;  976      for (index = 0; index < 16; index++)
3223                    	;  977          tstzero |= entryptr[index];
3224                    	;  978      printf("GPT partition entry %d:", entryno + 1);
3225                    	;  979      if (!tstzero)
3226                    	;  980          {
3227                    	;  981          printf(" Not used entry\n");
3228                    	;  982          return;
3229                    	;  983          }
3230                    	;  984      printf("\n  Partition type GUID: ");
3231                    	;  985      prtguid(entryptr);
3232                    	;  986      printf("\n  Unique partition GUID: ");
3233                    	;  987      prtguid(entryptr + 16);
3234                    	;  988      printf("\n  First LBA: ");
3235                    	;  989      /* lower 32 bits of LBA should be sufficient (I hope) */
3236                    	;  990      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
3237                    	;  991             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
3238                    	;  992      printf("%lu", flba);
3239                    	;  993      printf(" [");
3240                    	;  994      for (index = 32; index < (32 + 8); index++)
3241                    	;  995          printf("%02x ", entryptr[index]);
3242                    	;  996      printf("\b]");
3243                    	;  997      printf("\n  Last LBA: ");
3244                    	;  998      /* lower 32 bits of LBA should be sufficient (I hope) */
3245                    	;  999      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
3246                    	; 1000             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
3247                    	; 1001      printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
3248                    	; 1002      printf(" [");
3249                    	; 1003      for (index = 40; index < (40 + 8); index++)
3250                    	; 1004          printf("%02x ", entryptr[index]);
3251                    	; 1005      printf("\b]");
3252                    	; 1006      printf("\n  Attribute flags: [");
3253                    	; 1007      /* bits 0 - 2 and 60 - 63 should be decoded */
3254                    	; 1008      for (index = 0; index < 8; index++)
3255                    	; 1009          {
3256                    	; 1010          entryidx = index + 48;
3257                    	; 1011          printf("%02x ", entryptr[entryidx]);
3258                    	; 1012          }
3259                    	; 1013      printf("\b]\n  Partition name:  ");
3260                    	; 1014      /* partition name is in UTF-16LE code units */
3261                    	; 1015      hasname = NO;
3262                    	; 1016      for (index = 0; index < 72; index += 2)
3263                    	; 1017          {
3264                    	; 1018          entryidx = index + 56;
3265                    	; 1019          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
3266                    	; 1020              break;
3267                    	; 1021          if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
3268                    	; 1022              putchar(entryptr[entryidx]);
3269                    	; 1023          else
3270                    	; 1024              putchar('.');
3271                    	; 1025          hasname = YES;
3272                    	; 1026          }
3273                    	; 1027      if (!hasname)
3274                    	; 1028          printf("name field empty");
3275                    	; 1029      printf("\n");
3276                    	; 1030      printf("   [");
3277                    	; 1031      entryidx = index + 56;
3278                    	; 1032      for (index = 0; index < 72; index++)
3279                    	; 1033          {
3280                    	; 1034          if (((index & 0xf) == 0) && (index != 0))
3281                    	; 1035              printf("\n    ");
3282                    	; 1036          printf("%02x ", entryptr[entryidx]);
3283                    	; 1037          }
3284                    	; 1038      printf("\b]\n");
3285                    	; 1039      }
3286                    	; 1040  
3287                    	; 1041  /* Get GPT header */
3288                    	; 1042  void sdgpthdr(unsigned long block)
3289                    	; 1043      {
3290                    	; 1044      int index;
3291                    	; 1045      unsigned int partno;
3292                    	; 1046      unsigned char *rxdata;
3293                    	; 1047      unsigned long entries;
3294                    	; 1048  
3295                    	; 1049      printf("GPT header\n");
3296                    	; 1050      if (!sdread(sdrdbuf, block))
3297                    	; 1051          {
3298                    	; 1052          printf("Can't read GPT partition table header\n");
3299                    	; 1053          return;
3300                    	; 1054          }
3301                    	; 1055      curblkno = block;
3302                    	; 1056      curblkok = YES;
3303                    	; 1057  
3304                    	; 1058      rxdata = sdrdbuf;
3305                    	; 1059      printf("  Signature: %.8s\n", &rxdata[0]);
3306                    	; 1060      printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
3307                    	; 1061             (int)rxdata[8] * ((int)rxdata[9] << 8),
3308                    	; 1062             (int)rxdata[10] + ((int)rxdata[11] << 8),
3309                    	; 1063             rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
3310                    	; 1064      entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
3311                    	; 1065                ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
3312                    	; 1066      printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
3313                    	; 1067      for (partno = 0; partno < 16; partno++)
3314                    	; 1068          {
3315                    	; 1069          prtgptent(partno);
3316                    	; 1070          }
3317                    	; 1071      printf("First 16 GPT entries scanned\n");
3318                    	; 1072      }
3319                    	; 1073  
3320                    	; 1074  /* read MBR partition entry */
3321                    	; 1075  int sdmbrentry(unsigned char *partptr)
3322                    	; 1076      {
3323                    	; 1077      int index;
3324                    	; 1078      unsigned long lbastart;
3325                    	; 1079      unsigned long lbasize;
3326                    	; 1080  
3327                    	; 1081      if ((curblkno != 0) || !curblkok)
3328                    	; 1082          {
3329                    	; 1083          curblkno = 0;
3330                    	; 1084          if (!sdread(sdrdbuf, curblkno))
3331                    	; 1085              {
3332                    	; 1086              printf("Can't read MBR sector\n");
3333                    	; 1087              return;
3334                    	; 1088              }
3335                    	; 1089          curblkok = YES;
3336                    	; 1090          }
3337                    	; 1091      if (!partptr[4])
3338                    	; 1092          {
3339                    	; 1093          printf("Not used entry\n");
3340                    	; 1094          return;
3341                    	; 1095          }
3342                    	; 1096      printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
3343                    	; 1097             partptr[0], partptr[4]);
3344                    	; 1098  
3345                    	; 1099      if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
3346                    	; 1100          {
3347                    	; 1101          printf("  Extended partition\n");
3348                    	; 1102          /* should probably decode this also */
3349                    	; 1103          }
3350                    	; 1104      if (partptr[0] & 0x01)
3351                    	; 1105          {
3352                    	; 1106          printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
3353                    	; 1107          /* this is however discussed
3354                    	; 1108             https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
3355                    	; 1109          */
3356                    	; 1110          }
3357                    	; 1111      else
3358                    	; 1112          {
3359                    	; 1113          printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3360                    	; 1114                 partptr[1], partptr[2], partptr[3],
3361                    	; 1115                 ((partptr[2] & 0xc0) >> 2) + partptr[3],
3362                    	; 1116                 partptr[1],
3363                    	; 1117                 partptr[2] & 0x3f);
3364                    	; 1118          printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3365                    	; 1119                 partptr[5], partptr[6], partptr[7],
3366                    	; 1120                 ((partptr[6] & 0xc0) >> 2) + partptr[7],
3367                    	; 1121                 partptr[5],
3368                    	; 1122                 partptr[6] & 0x3f);
3369                    	; 1123          }
3370                    	; 1124      /* not showing high 16 bits if 48 bit LBA */
3371                    	; 1125      lbastart = (unsigned long)partptr[8] +
3372                    	; 1126                 ((unsigned long)partptr[9] << 8) +
3373                    	; 1127                 ((unsigned long)partptr[10] << 16) +
3374                    	; 1128                 ((unsigned long)partptr[11] << 24);
3375                    	; 1129      lbasize = (unsigned long)partptr[12] +
3376                    	; 1130                ((unsigned long)partptr[13] << 8) +
3377                    	; 1131                ((unsigned long)partptr[14] << 16) +
3378                    	; 1132                ((unsigned long)partptr[15] << 24);
3379                    	; 1133      printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
3380                    	; 1134      printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
3381                    	; 1135             lbasize, lbasize, lbasize >> 11);
3382                    	; 1136      if (partptr[4] == 0xee)
3383                    	; 1137          sdgpthdr(lbastart);
3384                    	; 1138      }
3385                    	; 1139  
3386                    	; 1140  /* read MBR partition information */
3387                    	; 1141  void sdmbrpart()
3388                    	; 1142      {
3389                    	; 1143      int partidx;  /* partition index 1 - 4 */
3390                    	; 1144      unsigned char *entp; /* pointer to partition entry */
3391                    	; 1145  
3392                    	; 1146  #ifdef SDTEST
3393                    	; 1147      printf("Read MBR\n");
3394                    	; 1148  #endif
3395                    	; 1149      if (!sdread(sdrdbuf, 0))
3396                    	; 1150          {
3397                    	; 1151  #ifdef SDTEST
3398                    	; 1152          printf("  can't read MBR sector\n");
3399                    	; 1153  #endif
3400                    	; 1154          return;
3401                    	; 1155          }
3402                    	; 1156      curblkno = 0;
3403    3623  97        		sub	a
3404    3624  320000    		ld	(_curblkno),a
3405    3627  320100    		ld	(_curblkno+1),a
3406    362A  320200    		ld	(_curblkno+2),a
3407    362D  320300    		ld	(_curblkno+3),a
3408    3630  220C00    		ld	(_curblkok),hl
3409                    	; 1157      curblkok = YES;
3410                    	; 1158      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
3411    3633  3A3002    		ld	a,(_sdrdbuf+510)
3412    3636  FE55      		cp	85
3413    3638  2007      		jr	nz,L1404
3414    363A  3A3102    		ld	a,(_sdrdbuf+511)
3415    363D  FEAA      		cp	170
3416    363F  2809      		jr	z,L1304
3417                    	L1404:
3418                    	; 1159          {
3419                    	; 1160  #ifdef SDTEST
3420                    	; 1161          printf("  no MBR signature found\n");
3421    3641  21BE35    		ld	hl,L5442
3422    3644  CD0000    		call	_printf
3423                    	; 1162  #endif
3424                    	; 1163          return;
3425    3647  C30000    		jp	c.rets0
3426                    	L1304:
3427                    	; 1164          }
3428                    	; 1165      /* go through MBR partition entries until first empty */
3429                    	; 1166      entp = &sdrdbuf[0x01be];
3430    364A  21F001    		ld	hl,_sdrdbuf+446
3431    364D  DD75F6    		ld	(ix-10),l
3432    3650  DD74F7    		ld	(ix-9),h
3433                    	; 1167      for (partidx = 1; partidx <= 4; partidx++, entp += 16)
3434    3653  DD36F801  		ld	(ix-8),1
3435    3657  DD36F900  		ld	(ix-7),0
3436                    	L1504:
3437    365B  3E04      		ld	a,4
3438    365D  DD96F8    		sub	(ix-8)
3439    3660  3E00      		ld	a,0
3440    3662  DD9EF9    		sbc	a,(ix-7)
3441    3665  FAA136    		jp	m,L1604
3442                    	; 1168          {
3443                    	; 1169  #ifdef SDTEST
3444                    	; 1170          printf("MBR partition entry %d: ", partidx);
3445    3668  DD6EF8    		ld	l,(ix-8)
3446    366B  DD66F9    		ld	h,(ix-7)
3447    366E  E5        		push	hl
3448    366F  21D835    		ld	hl,L5542
3449    3672  CD0000    		call	_printf
3450    3675  F1        		pop	af
3451                    	; 1171  #endif
3452                    	; 1172          if (!sdmbrentry(entp))
3453    3676  DD6EF6    		ld	l,(ix-10)
3454    3679  DD66F7    		ld	h,(ix-9)
3455    367C  CDFD31    		call	_sdmbrentry
3456    367F  79        		ld	a,c
3457    3680  B0        		or	b
3458    3681  281E      		jr	z,L1604
3459                    	; 1173              break;
3460                    	L1704:
3461    3683  DD34F8    		inc	(ix-8)
3462    3686  2003      		jr	nz,L451
3463    3688  DD34F9    		inc	(ix-7)
3464                    	L451:
3465    368B  DD6EF6    		ld	l,(ix-10)
3466    368E  DD66F7    		ld	h,(ix-9)
3467    3691  7D        		ld	a,l
3468    3692  C610      		add	a,16
3469    3694  6F        		ld	l,a
3470    3695  7C        		ld	a,h
3471    3696  CE00      		adc	a,0
3472    3698  67        		ld	h,a
3473    3699  DD75F6    		ld	(ix-10),l
3474    369C  DD74F7    		ld	(ix-9),h
3475    369F  18BA      		jr	L1504
3476                    	L1604:
3477                    	; 1174          }
3478                    	; 1175      }
3479    36A1  C30000    		jp	c.rets0
3480                    	L5642:
3481    36A4  0A        		.byte	10
3482    36A5  7A        		.byte	122
3483    36A6  38        		.byte	56
3484    36A7  30        		.byte	48
3485    36A8  73        		.byte	115
3486    36A9  64        		.byte	100
3487    36AA  74        		.byte	116
3488    36AB  65        		.byte	101
3489    36AC  73        		.byte	115
3490    36AD  74        		.byte	116
3491    36AE  20        		.byte	32
3492    36AF  00        		.byte	0
3493                    	L5742:
3494    36B0  76        		.byte	118
3495    36B1  65        		.byte	101
3496    36B2  72        		.byte	114
3497    36B3  73        		.byte	115
3498    36B4  69        		.byte	105
3499    36B5  6F        		.byte	111
3500    36B6  6E        		.byte	110
3501    36B7  20        		.byte	32
3502    36B8  30        		.byte	48
3503    36B9  2E        		.byte	46
3504    36BA  34        		.byte	52
3505    36BB  2C        		.byte	44
3506    36BC  20        		.byte	32
3507    36BD  00        		.byte	0
3508                    	L5052:
3509    36BE  0A        		.byte	10
3510    36BF  00        		.byte	0
3511                    	L5152:
3512    36C0  63        		.byte	99
3513    36C1  6D        		.byte	109
3514    36C2  64        		.byte	100
3515    36C3  20        		.byte	32
3516    36C4  28        		.byte	40
3517    36C5  68        		.byte	104
3518    36C6  20        		.byte	32
3519    36C7  66        		.byte	102
3520    36C8  6F        		.byte	111
3521    36C9  72        		.byte	114
3522    36CA  20        		.byte	32
3523    36CB  68        		.byte	104
3524    36CC  65        		.byte	101
3525    36CD  6C        		.byte	108
3526    36CE  70        		.byte	112
3527    36CF  29        		.byte	41
3528    36D0  3A        		.byte	58
3529    36D1  20        		.byte	32
3530    36D2  00        		.byte	0
3531                    	L5252:
3532    36D3  20        		.byte	32
3533    36D4  68        		.byte	104
3534    36D5  20        		.byte	32
3535    36D6  2D        		.byte	45
3536    36D7  20        		.byte	32
3537    36D8  68        		.byte	104
3538    36D9  65        		.byte	101
3539    36DA  6C        		.byte	108
3540    36DB  70        		.byte	112
3541    36DC  0A        		.byte	10
3542    36DD  00        		.byte	0
3543                    	L5352:
3544    36DE  0A        		.byte	10
3545    36DF  7A        		.byte	122
3546    36E0  38        		.byte	56
3547    36E1  30        		.byte	48
3548    36E2  73        		.byte	115
3549    36E3  64        		.byte	100
3550    36E4  74        		.byte	116
3551    36E5  65        		.byte	101
3552    36E6  73        		.byte	115
3553    36E7  74        		.byte	116
3554    36E8  20        		.byte	32
3555    36E9  00        		.byte	0
3556                    	L5452:
3557    36EA  76        		.byte	118
3558    36EB  65        		.byte	101
3559    36EC  72        		.byte	114
3560    36ED  73        		.byte	115
3561    36EE  69        		.byte	105
3562    36EF  6F        		.byte	111
3563    36F0  6E        		.byte	110
3564    36F1  20        		.byte	32
3565    36F2  30        		.byte	48
3566    36F3  2E        		.byte	46
3567    36F4  34        		.byte	52
3568    36F5  2C        		.byte	44
3569    36F6  20        		.byte	32
3570    36F7  00        		.byte	0
3571                    	L5552:
3572    36F8  0A        		.byte	10
3573    36F9  43        		.byte	67
3574    36FA  6F        		.byte	111
3575    36FB  6D        		.byte	109
3576    36FC  6D        		.byte	109
3577    36FD  61        		.byte	97
3578    36FE  6E        		.byte	110
3579    36FF  64        		.byte	100
3580    3700  73        		.byte	115
3581    3701  3A        		.byte	58
3582    3702  0A        		.byte	10
3583    3703  00        		.byte	0
3584                    	L5652:
3585    3704  20        		.byte	32
3586    3705  20        		.byte	32
3587    3706  68        		.byte	104
3588    3707  20        		.byte	32
3589    3708  2D        		.byte	45
3590    3709  20        		.byte	32
3591    370A  68        		.byte	104
3592    370B  65        		.byte	101
3593    370C  6C        		.byte	108
3594    370D  70        		.byte	112
3595    370E  0A        		.byte	10
3596    370F  00        		.byte	0
3597                    	L5752:
3598    3710  20        		.byte	32
3599    3711  20        		.byte	32
3600    3712  69        		.byte	105
3601    3713  20        		.byte	32
3602    3714  2D        		.byte	45
3603    3715  20        		.byte	32
3604    3716  69        		.byte	105
3605    3717  6E        		.byte	110
3606    3718  69        		.byte	105
3607    3719  74        		.byte	116
3608    371A  69        		.byte	105
3609    371B  61        		.byte	97
3610    371C  6C        		.byte	108
3611    371D  69        		.byte	105
3612    371E  7A        		.byte	122
3613    371F  65        		.byte	101
3614    3720  0A        		.byte	10
3615    3721  00        		.byte	0
3616                    	L5062:
3617    3722  20        		.byte	32
3618    3723  20        		.byte	32
3619    3724  6E        		.byte	110
3620    3725  20        		.byte	32
3621    3726  2D        		.byte	45
3622    3727  20        		.byte	32
3623    3728  73        		.byte	115
3624    3729  65        		.byte	101
3625    372A  74        		.byte	116
3626    372B  2F        		.byte	47
3627    372C  73        		.byte	115
3628    372D  68        		.byte	104
3629    372E  6F        		.byte	111
3630    372F  77        		.byte	119
3631    3730  20        		.byte	32
3632    3731  62        		.byte	98
3633    3732  6C        		.byte	108
3634    3733  6F        		.byte	111
3635    3734  63        		.byte	99
3636    3735  6B        		.byte	107
3637    3736  20        		.byte	32
3638    3737  23        		.byte	35
3639    3738  4E        		.byte	78
3640    3739  20        		.byte	32
3641    373A  74        		.byte	116
3642    373B  6F        		.byte	111
3643    373C  20        		.byte	32
3644    373D  72        		.byte	114
3645    373E  65        		.byte	101
3646    373F  61        		.byte	97
3647    3740  64        		.byte	100
3648    3741  0A        		.byte	10
3649    3742  00        		.byte	0
3650                    	L5162:
3651    3743  20        		.byte	32
3652    3744  20        		.byte	32
3653    3745  72        		.byte	114
3654    3746  20        		.byte	32
3655    3747  2D        		.byte	45
3656    3748  20        		.byte	32
3657    3749  72        		.byte	114
3658    374A  65        		.byte	101
3659    374B  61        		.byte	97
3660    374C  64        		.byte	100
3661    374D  20        		.byte	32
3662    374E  62        		.byte	98
3663    374F  6C        		.byte	108
3664    3750  6F        		.byte	111
3665    3751  63        		.byte	99
3666    3752  6B        		.byte	107
3667    3753  20        		.byte	32
3668    3754  23        		.byte	35
3669    3755  4E        		.byte	78
3670    3756  0A        		.byte	10
3671    3757  00        		.byte	0
3672                    	L5262:
3673    3758  20        		.byte	32
3674    3759  20        		.byte	32
3675    375A  77        		.byte	119
3676    375B  20        		.byte	32
3677    375C  2D        		.byte	45
3678    375D  20        		.byte	32
3679    375E  72        		.byte	114
3680    375F  65        		.byte	101
3681    3760  61        		.byte	97
3682    3761  64        		.byte	100
3683    3762  20        		.byte	32
3684    3763  62        		.byte	98
3685    3764  6C        		.byte	108
3686    3765  6F        		.byte	111
3687    3766  63        		.byte	99
3688    3767  6B        		.byte	107
3689    3768  20        		.byte	32
3690    3769  23        		.byte	35
3691    376A  4E        		.byte	78
3692    376B  0A        		.byte	10
3693    376C  00        		.byte	0
3694                    	L5362:
3695    376D  20        		.byte	32
3696    376E  20        		.byte	32
3697    376F  70        		.byte	112
3698    3770  20        		.byte	32
3699    3771  2D        		.byte	45
3700    3772  20        		.byte	32
3701    3773  70        		.byte	112
3702    3774  72        		.byte	114
3703    3775  69        		.byte	105
3704    3776  6E        		.byte	110
3705    3777  74        		.byte	116
3706    3778  20        		.byte	32
3707    3779  62        		.byte	98
3708    377A  6C        		.byte	108
3709    377B  6F        		.byte	111
3710    377C  63        		.byte	99
3711    377D  6B        		.byte	107
3712    377E  20        		.byte	32
3713    377F  6C        		.byte	108
3714    3780  61        		.byte	97
3715    3781  73        		.byte	115
3716    3782  74        		.byte	116
3717    3783  20        		.byte	32
3718    3784  72        		.byte	114
3719    3785  65        		.byte	101
3720    3786  61        		.byte	97
3721    3787  64        		.byte	100
3722    3788  2F        		.byte	47
3723    3789  74        		.byte	116
3724    378A  6F        		.byte	111
3725    378B  20        		.byte	32
3726    378C  77        		.byte	119
3727    378D  72        		.byte	114
3728    378E  69        		.byte	105
3729    378F  74        		.byte	116
3730    3790  65        		.byte	101
3731    3791  0A        		.byte	10
3732    3792  00        		.byte	0
3733                    	L5462:
3734    3793  20        		.byte	32
3735    3794  20        		.byte	32
3736    3795  73        		.byte	115
3737    3796  20        		.byte	32
3738    3797  2D        		.byte	45
3739    3798  20        		.byte	32
3740    3799  70        		.byte	112
3741    379A  72        		.byte	114
3742    379B  69        		.byte	105
3743    379C  6E        		.byte	110
3744    379D  74        		.byte	116
3745    379E  20        		.byte	32
3746    379F  53        		.byte	83
3747    37A0  44        		.byte	68
3748    37A1  20        		.byte	32
3749    37A2  72        		.byte	114
3750    37A3  65        		.byte	101
3751    37A4  67        		.byte	103
3752    37A5  69        		.byte	105
3753    37A6  73        		.byte	115
3754    37A7  74        		.byte	116
3755    37A8  65        		.byte	101
3756    37A9  72        		.byte	114
3757    37AA  73        		.byte	115
3758    37AB  0A        		.byte	10
3759    37AC  00        		.byte	0
3760                    	L5562:
3761    37AD  20        		.byte	32
3762    37AE  20        		.byte	32
3763    37AF  6C        		.byte	108
3764    37B0  20        		.byte	32
3765    37B1  2D        		.byte	45
3766    37B2  20        		.byte	32
3767    37B3  70        		.byte	112
3768    37B4  72        		.byte	114
3769    37B5  69        		.byte	105
3770    37B6  6E        		.byte	110
3771    37B7  74        		.byte	116
3772    37B8  20        		.byte	32
3773    37B9  70        		.byte	112
3774    37BA  61        		.byte	97
3775    37BB  72        		.byte	114
3776    37BC  74        		.byte	116
3777    37BD  69        		.byte	105
3778    37BE  74        		.byte	116
3779    37BF  69        		.byte	105
3780    37C0  6F        		.byte	111
3781    37C1  6E        		.byte	110
3782    37C2  20        		.byte	32
3783    37C3  6C        		.byte	108
3784    37C4  61        		.byte	97
3785    37C5  79        		.byte	121
3786    37C6  6F        		.byte	111
3787    37C7  75        		.byte	117
3788    37C8  74        		.byte	116
3789    37C9  0A        		.byte	10
3790    37CA  00        		.byte	0
3791                    	L5662:
3792    37CB  20        		.byte	32
3793    37CC  20        		.byte	32
3794    37CD  43        		.byte	67
3795    37CE  74        		.byte	116
3796    37CF  72        		.byte	114
3797    37D0  6C        		.byte	108
3798    37D1  2D        		.byte	45
3799    37D2  43        		.byte	67
3800    37D3  20        		.byte	32
3801    37D4  74        		.byte	116
3802    37D5  6F        		.byte	111
3803    37D6  20        		.byte	32
3804    37D7  72        		.byte	114
3805    37D8  65        		.byte	101
3806    37D9  6C        		.byte	108
3807    37DA  6F        		.byte	111
3808    37DB  61        		.byte	97
3809    37DC  64        		.byte	100
3810    37DD  20        		.byte	32
3811    37DE  6D        		.byte	109
3812    37DF  6F        		.byte	111
3813    37E0  6E        		.byte	110
3814    37E1  69        		.byte	105
3815    37E2  74        		.byte	116
3816    37E3  6F        		.byte	111
3817    37E4  72        		.byte	114
3818    37E5  2E        		.byte	46
3819    37E6  0A        		.byte	10
3820    37E7  00        		.byte	0
3821                    	L5762:
3822    37E8  20        		.byte	32
3823    37E9  69        		.byte	105
3824    37EA  20        		.byte	32
3825    37EB  2D        		.byte	45
3826    37EC  20        		.byte	32
3827    37ED  69        		.byte	105
3828    37EE  6E        		.byte	110
3829    37EF  69        		.byte	105
3830    37F0  74        		.byte	116
3831    37F1  69        		.byte	105
3832    37F2  61        		.byte	97
3833    37F3  6C        		.byte	108
3834    37F4  69        		.byte	105
3835    37F5  7A        		.byte	122
3836    37F6  65        		.byte	101
3837    37F7  20        		.byte	32
3838    37F8  53        		.byte	83
3839    37F9  44        		.byte	68
3840    37FA  20        		.byte	32
3841    37FB  63        		.byte	99
3842    37FC  61        		.byte	97
3843    37FD  72        		.byte	114
3844    37FE  64        		.byte	100
3845    37FF  00        		.byte	0
3846                    	L5072:
3847    3800  20        		.byte	32
3848    3801  2D        		.byte	45
3849    3802  20        		.byte	32
3850    3803  6F        		.byte	111
3851    3804  6B        		.byte	107
3852    3805  0A        		.byte	10
3853    3806  00        		.byte	0
3854                    	L5172:
3855    3807  20        		.byte	32
3856    3808  2D        		.byte	45
3857    3809  20        		.byte	32
3858    380A  6E        		.byte	110
3859    380B  6F        		.byte	111
3860    380C  74        		.byte	116
3861    380D  20        		.byte	32
3862    380E  69        		.byte	105
3863    380F  6E        		.byte	110
3864    3810  73        		.byte	115
3865    3811  65        		.byte	101
3866    3812  72        		.byte	114
3867    3813  74        		.byte	116
3868    3814  65        		.byte	101
3869    3815  64        		.byte	100
3870    3816  20        		.byte	32
3871    3817  6F        		.byte	111
3872    3818  72        		.byte	114
3873    3819  20        		.byte	32
3874    381A  66        		.byte	102
3875    381B  61        		.byte	97
3876    381C  75        		.byte	117
3877    381D  6C        		.byte	108
3878    381E  74        		.byte	116
3879    381F  79        		.byte	121
3880    3820  0A        		.byte	10
3881    3821  00        		.byte	0
3882                    	L5272:
3883    3822  20        		.byte	32
3884    3823  6E        		.byte	110
3885    3824  20        		.byte	32
3886    3825  2D        		.byte	45
3887    3826  20        		.byte	32
3888    3827  62        		.byte	98
3889    3828  6C        		.byte	108
3890    3829  6F        		.byte	111
3891    382A  63        		.byte	99
3892    382B  6B        		.byte	107
3893    382C  20        		.byte	32
3894    382D  6E        		.byte	110
3895    382E  75        		.byte	117
3896    382F  6D        		.byte	109
3897    3830  62        		.byte	98
3898    3831  65        		.byte	101
3899    3832  72        		.byte	114
3900    3833  3A        		.byte	58
3901    3834  20        		.byte	32
3902    3835  00        		.byte	0
3903                    	L5372:
3904    3836  25        		.byte	37
3905    3837  6C        		.byte	108
3906    3838  75        		.byte	117
3907    3839  00        		.byte	0
3908                    	L5472:
3909    383A  25        		.byte	37
3910    383B  6C        		.byte	108
3911    383C  75        		.byte	117
3912    383D  00        		.byte	0
3913                    	L5572:
3914    383E  0A        		.byte	10
3915    383F  00        		.byte	0
3916                    	L5672:
3917    3840  20        		.byte	32
3918    3841  72        		.byte	114
3919    3842  20        		.byte	32
3920    3843  2D        		.byte	45
3921    3844  20        		.byte	32
3922    3845  72        		.byte	114
3923    3846  65        		.byte	101
3924    3847  61        		.byte	97
3925    3848  64        		.byte	100
3926    3849  20        		.byte	32
3927    384A  62        		.byte	98
3928    384B  6C        		.byte	108
3929    384C  6F        		.byte	111
3930    384D  63        		.byte	99
3931    384E  6B        		.byte	107
3932    384F  00        		.byte	0
3933                    	L5772:
3934    3850  20        		.byte	32
3935    3851  2D        		.byte	45
3936    3852  20        		.byte	32
3937    3853  6F        		.byte	111
3938    3854  6B        		.byte	107
3939    3855  0A        		.byte	10
3940    3856  00        		.byte	0
3941                    	L5003:
3942    3857  20        		.byte	32
3943    3858  2D        		.byte	45
3944    3859  20        		.byte	32
3945    385A  65        		.byte	101
3946    385B  72        		.byte	114
3947    385C  72        		.byte	114
3948    385D  6F        		.byte	111
3949    385E  72        		.byte	114
3950    385F  0A        		.byte	10
3951    3860  00        		.byte	0
3952                    	L5103:
3953    3861  20        		.byte	32
3954    3862  77        		.byte	119
3955    3863  20        		.byte	32
3956    3864  2D        		.byte	45
3957    3865  20        		.byte	32
3958    3866  77        		.byte	119
3959    3867  72        		.byte	114
3960    3868  69        		.byte	105
3961    3869  74        		.byte	116
3962    386A  65        		.byte	101
3963    386B  20        		.byte	32
3964    386C  62        		.byte	98
3965    386D  6C        		.byte	108
3966    386E  6F        		.byte	111
3967    386F  63        		.byte	99
3968    3870  6B        		.byte	107
3969    3871  00        		.byte	0
3970                    	L5203:
3971    3872  20        		.byte	32
3972    3873  2D        		.byte	45
3973    3874  20        		.byte	32
3974    3875  6F        		.byte	111
3975    3876  6B        		.byte	107
3976    3877  0A        		.byte	10
3977    3878  00        		.byte	0
3978                    	L5303:
3979    3879  20        		.byte	32
3980    387A  2D        		.byte	45
3981    387B  20        		.byte	32
3982    387C  65        		.byte	101
3983    387D  72        		.byte	114
3984    387E  72        		.byte	114
3985    387F  6F        		.byte	111
3986    3880  72        		.byte	114
3987    3881  0A        		.byte	10
3988    3882  00        		.byte	0
3989                    	L5403:
3990    3883  20        		.byte	32
3991    3884  70        		.byte	112
3992    3885  20        		.byte	32
3993    3886  2D        		.byte	45
3994    3887  20        		.byte	32
3995    3888  70        		.byte	112
3996    3889  72        		.byte	114
3997    388A  69        		.byte	105
3998    388B  6E        		.byte	110
3999    388C  74        		.byte	116
4000    388D  20        		.byte	32
4001    388E  64        		.byte	100
4002    388F  61        		.byte	97
4003    3890  74        		.byte	116
4004    3891  61        		.byte	97
4005    3892  20        		.byte	32
4006    3893  62        		.byte	98
4007    3894  6C        		.byte	108
4008    3895  6F        		.byte	111
4009    3896  63        		.byte	99
4010    3897  6B        		.byte	107
4011    3898  20        		.byte	32
4012    3899  25        		.byte	37
4013    389A  6C        		.byte	108
4014    389B  75        		.byte	117
4015    389C  0A        		.byte	10
4016    389D  00        		.byte	0
4017                    	L5503:
4018    389E  20        		.byte	32
4019    389F  73        		.byte	115
4020    38A0  20        		.byte	32
4021    38A1  2D        		.byte	45
4022    38A2  20        		.byte	32
4023    38A3  70        		.byte	112
4024    38A4  72        		.byte	114
4025    38A5  69        		.byte	105
4026    38A6  6E        		.byte	110
4027    38A7  74        		.byte	116
4028    38A8  20        		.byte	32
4029    38A9  53        		.byte	83
4030    38AA  44        		.byte	68
4031    38AB  20        		.byte	32
4032    38AC  72        		.byte	114
4033    38AD  65        		.byte	101
4034    38AE  67        		.byte	103
4035    38AF  69        		.byte	105
4036    38B0  73        		.byte	115
4037    38B1  74        		.byte	116
4038    38B2  65        		.byte	101
4039    38B3  72        		.byte	114
4040    38B4  73        		.byte	115
4041    38B5  0A        		.byte	10
4042    38B6  00        		.byte	0
4043                    	L5603:
4044    38B7  20        		.byte	32
4045    38B8  6C        		.byte	108
4046    38B9  20        		.byte	32
4047    38BA  2D        		.byte	45
4048    38BB  20        		.byte	32
4049    38BC  70        		.byte	112
4050    38BD  72        		.byte	114
4051    38BE  69        		.byte	105
4052    38BF  6E        		.byte	110
4053    38C0  74        		.byte	116
4054    38C1  20        		.byte	32
4055    38C2  70        		.byte	112
4056    38C3  61        		.byte	97
4057    38C4  72        		.byte	114
4058    38C5  74        		.byte	116
4059    38C6  69        		.byte	105
4060    38C7  74        		.byte	116
4061    38C8  69        		.byte	105
4062    38C9  6F        		.byte	111
4063    38CA  6E        		.byte	110
4064    38CB  20        		.byte	32
4065    38CC  6C        		.byte	108
4066    38CD  61        		.byte	97
4067    38CE  79        		.byte	121
4068    38CF  6F        		.byte	111
4069    38D0  75        		.byte	117
4070    38D1  74        		.byte	116
4071    38D2  0A        		.byte	10
4072    38D3  00        		.byte	0
4073                    	L5703:
4074    38D4  72        		.byte	114
4075    38D5  65        		.byte	101
4076    38D6  6C        		.byte	108
4077    38D7  6F        		.byte	111
4078    38D8  61        		.byte	97
4079    38D9  64        		.byte	100
4080    38DA  69        		.byte	105
4081    38DB  6E        		.byte	110
4082    38DC  67        		.byte	103
4083    38DD  20        		.byte	32
4084    38DE  6D        		.byte	109
4085    38DF  6F        		.byte	111
4086    38E0  6E        		.byte	110
4087    38E1  69        		.byte	105
4088    38E2  74        		.byte	116
4089    38E3  6F        		.byte	111
4090    38E4  72        		.byte	114
4091    38E5  20        		.byte	32
4092    38E6  66        		.byte	102
4093    38E7  72        		.byte	114
4094    38E8  6F        		.byte	111
4095    38E9  6D        		.byte	109
   0    38EA  20        		.byte	32
   1    38EB  45        		.byte	69
   2    38EC  50        		.byte	80
   3    38ED  52        		.byte	82
   4    38EE  4F        		.byte	79
   5    38EF  4D        		.byte	77
   6    38F0  0A        		.byte	10
   7    38F1  00        		.byte	0
   8                    	L5013:
   9    38F2  20        		.byte	32
  10    38F3  63        		.byte	99
  11    38F4  6F        		.byte	111
  12    38F5  6D        		.byte	109
  13    38F6  6D        		.byte	109
  14    38F7  61        		.byte	97
  15    38F8  6E        		.byte	110
  16    38F9  64        		.byte	100
  17    38FA  20        		.byte	32
  18    38FB  6E        		.byte	110
  19    38FC  6F        		.byte	111
  20    38FD  74        		.byte	116
  21    38FE  20        		.byte	32
  22    38FF  69        		.byte	105
  23    3900  6D        		.byte	109
  24    3901  70        		.byte	112
  25    3902  6C        		.byte	108
  26    3903  65        		.byte	101
  27    3904  6D        		.byte	109
  28    3905  65        		.byte	101
  29    3906  6E        		.byte	110
  30    3907  74        		.byte	116
  31    3908  65        		.byte	101
  32    3909  64        		.byte	100
  33    390A  20        		.byte	32
  34    390B  79        		.byte	121
  35    390C  65        		.byte	101
  36    390D  74        		.byte	116
  37    390E  0A        		.byte	10
  38    390F  00        		.byte	0
  39                    	L1414:
  40    3910  0C        		.byte	12
  41    3911  00        		.byte	0
  42    3912  68        		.byte	104
  43    3913  00        		.byte	0
  44    3914  9A39      		.word	L1614
  45    3916  F139      		.word	L1714
  46    3918  273B      		.word	L1734
  47    391A  273B      		.word	L1734
  48    391C  0F3B      		.word	L1534
  49    391E  273B      		.word	L1734
  50    3920  103A      		.word	L1224
  51    3922  273B      		.word	L1734
  52    3924  E63A      		.word	L1334
  53    3926  273B      		.word	L1734
  54    3928  623A      		.word	L1524
  55    392A  033B      		.word	L1434
  56    392C  00        		.byte	0
  57    392D  00        		.byte	0
  58    392E  02        		.byte	2
  59    392F  00        		.byte	0
  60    3930  1B3B      		.word	L1634
  61    3932  0300      		.word	3
  62    3934  A43A      		.word	L1034
  63    3936  7700      		.word	119
  64    3938  273B      		.word	L1734
  65                    	; 1176  
  66                    	; 1177  /* Test init, read and partitions on SD card over the SPI interface
  67                    	; 1178   *
  68                    	; 1179   */
  69                    	; 1180  int main()
  70                    	; 1181      {
  71                    	_main:
  72    393A  CD0000    		call	c.savs0
  73    393D  21E8FF    		ld	hl,65512
  74    3940  39        		add	hl,sp
  75    3941  F9        		ld	sp,hl
  76                    	; 1182      char txtin[10];
  77                    	; 1183      int cmdin;
  78                    	; 1184      int inlength;
  79                    	; 1185      unsigned long blockno;
  80                    	; 1186  
  81                    	; 1187      blockno = 0;
  82    3942  97        		sub	a
  83    3943  DD77E8    		ld	(ix-24),a
  84    3946  DD77E9    		ld	(ix-23),a
  85    3949  DD77EA    		ld	(ix-22),a
  86    394C  DD77EB    		ld	(ix-21),a
  87                    	; 1188      curblkno = 0;
  88                    	; 1189      curblkok = NO;
  89    394F  210000    		ld	hl,0
  90                    	;    1  /*  z80boot.c
  91                    	;    2   *
  92                    	;    3   *  Boot code for my DIY Z80 Computer. This
  93                    	;    4   *  program is compiled with Whitesmiths/COSMIC
  94                    	;    5   *  C compiler for Z80.
  95                    	;    6   *
  96                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
  97                    	;    8   *
  98                    	;    9   *  Initializes the hardware and detects the
  99                    	;   10   *  presence and partitioning of an attached SD card.
 100                    	;   11   *
 101                    	;   12   *  You are free to use, modify, and redistribute
 102                    	;   13   *  this source code. No warranties are given.
 103                    	;   14   *  Hastily Cobbled Together 2021 and 2022
 104                    	;   15   *  by Hans-Ake Lund
 105                    	;   16   *
 106                    	;   17   */
 107                    	;   18  
 108                    	;   19  #include <std.h>
 109                    	;   20  #include "z80computer.h"
 110                    	;   21  #include "builddate.h"
 111                    	;   22  #include "progtype.h"
 112                    	;   23  
 113                    	;   24  #ifdef SDTEST
 114                    	;   25  #define PRGNAME "\nz80sdtest "
 115                    	;   26  #else
 116                    	;   27  #define PRGNAME "\nz80boot "
 117                    	;   28  #endif
 118                    	;   29  #define VERSION "version 0.4, "
 119                    	;   30  
 120                    	;   31  /* Response length in bytes
 121                    	;   32   */
 122                    	;   33  #define R1_LEN 1
 123                    	;   34  #define R3_LEN 5
 124                    	;   35  #define R7_LEN 5
 125                    	;   36  
 126                    	;   37  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
 127                    	;   38   * (The CRC7 byte in the tables below are only for information,
 128                    	;   39   * it is calculated by the sdcommand routine.)
 129                    	;   40   */
 130                    	;   41  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
 131                    	;   42  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
 132                    	;   43  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
 133                    	;   44  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
 134                    	;   45  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
 135                    	;   46  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
 136                    	;   47  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
 137                    	;   48  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
 138                    	;   49  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
 139                    	;   50  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
 140                    	;   51  
 141                    	;   52  /* Buffers
 142                    	;   53   */
 143                    	;   54  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
 144                    	;   55  
 145                    	;   56  unsigned char ocrreg[4];     /* SD card OCR register */
 146                    	;   57  unsigned char cidreg[16];    /* SD card CID register */
 147                    	;   58  unsigned char csdreg[16];    /* SD card CSD register */
 148                    	;   59  
 149                    	;   60  /* Variables
 150                    	;   61   */
 151                    	;   62  int curblkok;  /* if YES curblockno is read into buffer */
 152                    	;   63  int sdinitok;  /* SD card initialized and ready */
 153                    	;   64  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
 154                    	;   65  unsigned long blkmult;   /* block address multiplier */
 155                    	;   66  unsigned long curblkno;  /* block in buffer if curblkok == YES */
 156                    	;   67  
 157                    	;   68  /* CRC routines from:
 158                    	;   69   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
 159                    	;   70   */
 160                    	;   71  
 161                    	;   72  /*
 162                    	;   73  // Calculate CRC7
 163                    	;   74  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
 164                    	;   75  // input:
 165                    	;   76  //   crcIn - the CRC before (0 for first step)
 166                    	;   77  //   data - byte for CRC calculation
 167                    	;   78  // return: the new CRC7
 168                    	;   79  */
 169                    	;   80  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
 170                    	;   81      {
 171                    	;   82      const unsigned char g = 0x89;
 172                    	;   83      unsigned char i;
 173                    	;   84  
 174                    	;   85      crcIn ^= data;
 175                    	;   86      for (i = 0; i < 8; i++)
 176                    	;   87          {
 177                    	;   88          if (crcIn & 0x80) crcIn ^= g;
 178                    	;   89          crcIn <<= 1;
 179                    	;   90          }
 180                    	;   91  
 181                    	;   92      return crcIn;
 182                    	;   93      }
 183                    	;   94  
 184                    	;   95  /*
 185                    	;   96  // Calculate CRC16 CCITT
 186                    	;   97  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
 187                    	;   98  // input:
 188                    	;   99  //   crcIn - the CRC before (0 for rist step)
 189                    	;  100  //   data - byte for CRC calculation
 190                    	;  101  // return: the CRC16 value
 191                    	;  102  */
 192                    	;  103  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
 193                    	;  104      {
 194                    	;  105      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
 195                    	;  106      crcIn ^=  data;
 196                    	;  107      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
 197                    	;  108      crcIn ^= (crcIn << 8) << 4;
 198                    	;  109      crcIn ^= ((crcIn & 0xff) << 4) << 1;
 199                    	;  110  
 200                    	;  111      return crcIn;
 201                    	;  112      }
 202                    	;  113  
 203                    	;  114  /* Send command to SD card and recieve answer.
 204                    	;  115   * A command is 5 bytes long and is followed by
 205                    	;  116   * a CRC7 checksum byte.
 206                    	;  117   * Returns a pointer to the response
 207                    	;  118   * or 0 if no response start bit found.
 208                    	;  119   */
 209                    	;  120  unsigned char *sdcommand(unsigned char *sdcmdp,
 210                    	;  121                           unsigned char *recbuf, int recbytes)
 211                    	;  122      {
 212                    	;  123      int searchn;  /* byte counter to search for response */
 213                    	;  124      int sdcbytes; /* byte counter for bytes to send */
 214                    	;  125      unsigned char *retptr; /* pointer used to store response */
 215                    	;  126      unsigned char rbyte;   /* recieved byte */
 216                    	;  127      unsigned char crc = 0; /* calculated CRC7 */
 217                    	;  128  
 218                    	;  129      /* send 8*2 clockpules */
 219                    	;  130      spiio(0xff);
 220                    	;  131      spiio(0xff);
 221                    	;  132      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
 222                    	;  133          {
 223                    	;  134          crc = CRC7_one(crc, *sdcmdp);
 224                    	;  135          spiio(*sdcmdp++);
 225                    	;  136          }
 226                    	;  137      spiio(crc | 0x01);
 227                    	;  138      /* search for recieved byte with start bit
 228                    	;  139         for a maximum of 10 recieved bytes  */
 229                    	;  140      for (searchn = 10; 0 < searchn; searchn--)
 230                    	;  141          {
 231                    	;  142          rbyte = spiio(0xff);
 232                    	;  143          if ((rbyte & 0x80) == 0)
 233                    	;  144              break;
 234                    	;  145          }
 235                    	;  146      if (searchn == 0) /* no start bit found */
 236                    	;  147          return (NO);
 237                    	;  148      retptr = recbuf;
 238                    	;  149      *retptr++ = rbyte;
 239                    	;  150      for (; 1 < recbytes; recbytes--) /* recieve bytes */
 240                    	;  151          *retptr++ = spiio(0xff);
 241                    	;  152      return (recbuf);
 242                    	;  153      }
 243                    	;  154  
 244                    	;  155  /* Initialise SD card interface
 245                    	;  156   *
 246                    	;  157   * returns YES if ok and NO if not ok
 247                    	;  158   *
 248                    	;  159   * References:
 249                    	;  160   *   https://www.sdcard.org/downloads/pls/
 250                    	;  161   *      Physical Layer Simplified Specification version 8.0
 251                    	;  162   *
 252                    	;  163   * A nice flowchart how to initialize:
 253                    	;  164   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
 254                    	;  165   *
 255                    	;  166   */
 256                    	;  167  int sdinit()
 257                    	;  168      {
 258                    	;  169      int nbytes;  /* byte counter */
 259                    	;  170      int tries;   /* tries to get to active state or searching for data  */
 260                    	;  171      int wtloop;  /* timer loop when trying to enter active state */
 261                    	;  172      unsigned char cmdbuf[5];   /* buffer to build command in */
 262                    	;  173      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 263                    	;  174      unsigned char *statptr;    /* pointer to returned status from SD command */
 264                    	;  175      unsigned char crc;         /* crc register for CID and CSD */
 265                    	;  176      unsigned char rbyte;       /* recieved byte */
 266                    	;  177  #ifdef SDTEST
 267                    	;  178      unsigned char *prtptr;     /* for debug printing */
 268                    	;  179  #endif
 269                    	;  180  
 270                    	;  181      ledon();
 271                    	;  182      spideselect();
 272                    	;  183      sdinitok = NO;
 273                    	;  184  
 274                    	;  185      /* start to generate 9*8 clock pulses with not selected SD card */
 275                    	;  186      for (nbytes = 9; 0 < nbytes; nbytes--)
 276                    	;  187          spiio(0xff);
 277                    	;  188  #ifdef SDTEST
 278                    	;  189      printf("\nSent 8*8 (72) clock pulses, select not active\n");
 279                    	;  190  #endif
 280                    	;  191      spiselect();
 281                    	;  192  
 282                    	;  193      /* CMD0: GO_IDLE_STATE */
 283                    	;  194      memcpy(cmdbuf, cmd0, 5);
 284                    	;  195      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 285                    	;  196  #ifdef SDTEST
 286                    	;  197      if (!statptr)
 287                    	;  198          printf("CMD0: no response\n");
 288                    	;  199      else
 289                    	;  200          printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
 290                    	;  201  #endif
 291                    	;  202      if (!statptr)
 292                    	;  203          {
 293                    	;  204          spideselect();
 294                    	;  205          ledoff();
 295                    	;  206          return (NO);
 296                    	;  207          }
 297                    	;  208      /* CMD8: SEND_IF_COND */
 298                    	;  209      memcpy(cmdbuf, cmd8, 5);
 299                    	;  210      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
 300                    	;  211  #ifdef SDTEST
 301                    	;  212      if (!statptr)
 302                    	;  213          printf("CMD8: no response\n");
 303                    	;  214      else
 304                    	;  215          {
 305                    	;  216          printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
 306                    	;  217                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
 307                    	;  218          if (!(statptr[0] & 0xfe)) /* no error */
 308                    	;  219              {
 309                    	;  220              if (statptr[4] == 0xaa)
 310                    	;  221                  printf("echo back ok, ");
 311                    	;  222              else
 312                    	;  223                  printf("invalid echo back\n");
 313                    	;  224              }
 314                    	;  225          }
 315                    	;  226  #endif
 316                    	;  227      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
 317                    	;  228          {
 318                    	;  229          sdver2 = NO;
 319                    	;  230  #ifdef SDTEST
 320                    	;  231          printf("probably SD ver. 1\n");
 321                    	;  232  #endif
 322                    	;  233          }
 323                    	;  234      else
 324                    	;  235          {
 325                    	;  236          sdver2 = YES;
 326                    	;  237          if (statptr[4] != 0xaa) /* but invalid echo back */
 327                    	;  238              {
 328                    	;  239              spideselect();
 329                    	;  240              ledoff();
 330                    	;  241              return (NO);
 331                    	;  242              }
 332                    	;  243  #ifdef SDTEST
 333                    	;  244          printf("SD ver 2\n");
 334                    	;  245  #endif
 335                    	;  246          }
 336                    	;  247  
 337                    	;  248      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
 338                    	;  249      for (tries = 0; tries < 20; tries++)
 339                    	;  250          {
 340                    	;  251          memcpy(cmdbuf, cmd55, 5);
 341                    	;  252          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 342                    	;  253  #ifdef SDTEST
 343                    	;  254          if (!statptr)
 344                    	;  255              printf("CMD55: no response\n");
 345                    	;  256          else
 346                    	;  257              printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
 347                    	;  258  #endif
 348                    	;  259          if (!statptr)
 349                    	;  260              {
 350                    	;  261              spideselect();
 351                    	;  262              ledoff();
 352                    	;  263              return (NO);
 353                    	;  264              }
 354                    	;  265          memcpy(cmdbuf, acmd41, 5);
 355                    	;  266          if (sdver2)
 356                    	;  267              cmdbuf[1] = 0x40;
 357                    	;  268          else
 358                    	;  269              cmdbuf[1] = 0x00;
 359                    	;  270          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 360                    	;  271  #ifdef SDTEST
 361                    	;  272          if (!statptr)
 362                    	;  273              printf("ACMD41: no response\n");
 363                    	;  274          else
 364                    	;  275              printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
 365                    	;  276                     statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
 366                    	;  277  #endif
 367                    	;  278          if (!statptr)
 368                    	;  279              {
 369                    	;  280              spideselect();
 370                    	;  281              ledoff();
 371                    	;  282              return (NO);
 372                    	;  283              }
 373                    	;  284          if (statptr[0] == 0x00) /* now the SD card is ready */
 374                    	;  285              {
 375                    	;  286              break;
 376                    	;  287              }
 377                    	;  288          for (wtloop = 0; wtloop < tries * 100; wtloop++)
 378                    	;  289              ; /* wait loop, time increasing for each try */
 379                    	;  290          }
 380                    	;  291  
 381                    	;  292      /* CMD58: READ_OCR */
 382                    	;  293      /* According to the flow chart this should not work
 383                    	;  294         for SD ver. 1 but the response is ok anyway
 384                    	;  295         all tested SD cards  */
 385                    	;  296      memcpy(cmdbuf, cmd58, 5);
 386                    	;  297      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
 387                    	;  298  #ifdef SDTEST
 388                    	;  299      if (!statptr)
 389                    	;  300          printf("CMD58: no response\n");
 390                    	;  301      else
 391                    	;  302          printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
 392                    	;  303                 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
 393                    	;  304  #endif
 394                    	;  305      if (!statptr)
 395                    	;  306          {
 396                    	;  307          spideselect();
 397                    	;  308          ledoff();
 398                    	;  309          return (NO);
 399                    	;  310          }
 400                    	;  311      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
 401                    	;  312      blkmult = 1; /* assume block address */
 402                    	;  313      if (ocrreg[0] & 0x80)
 403                    	;  314          {
 404                    	;  315          /* SD Ver.2+ */
 405                    	;  316          if (!(ocrreg[0] & 0x40))
 406                    	;  317              {
 407                    	;  318              /* SD Ver.2+, Byte address */
 408                    	;  319              blkmult = 512;
 409                    	;  320              }
 410                    	;  321          }
 411                    	;  322  
 412                    	;  323      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
 413                    	;  324      if (blkmult == 512)
 414                    	;  325          {
 415                    	;  326          memcpy(cmdbuf, cmd16, 5);
 416                    	;  327          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 417                    	;  328  #ifdef SDTEST
 418                    	;  329          if (!statptr)
 419                    	;  330              printf("CMD16: no response\n");
 420                    	;  331          else
 421                    	;  332              printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
 422                    	;  333                  statptr[0]);
 423                    	;  334  #endif
 424                    	;  335          if (!statptr)
 425                    	;  336              {
 426                    	;  337              spideselect();
 427                    	;  338              ledoff();
 428                    	;  339              return (NO);
 429                    	;  340              }
 430                    	;  341          }
 431                    	;  342      /* Register information:
 432                    	;  343       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
 433                    	;  344       */
 434                    	;  345  
 435                    	;  346      /* CMD10: SEND_CID */
 436                    	;  347      memcpy(cmdbuf, cmd10, 5);
 437                    	;  348      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 438                    	;  349  #ifdef SDTEST
 439                    	;  350      if (!statptr)
 440                    	;  351          printf("CMD10: no response\n");
 441                    	;  352      else
 442                    	;  353          printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
 443                    	;  354  #endif
 444                    	;  355      if (!statptr)
 445                    	;  356          {
 446                    	;  357          spideselect();
 447                    	;  358          ledoff();
 448                    	;  359          return (NO);
 449                    	;  360          }
 450                    	;  361      /* looking for 0xfe that is the byte before data */
 451                    	;  362      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
 452                    	;  363          ;
 453                    	;  364      if (tries == 0) /* tried too many times */
 454                    	;  365          {
 455                    	;  366  #ifdef SDTEST
 456                    	;  367          printf("  No data found\n");
 457                    	;  368  #endif
 458                    	;  369          spideselect();
 459                    	;  370          ledoff();
 460                    	;  371          return (NO);
 461                    	;  372          }
 462                    	;  373      else
 463                    	;  374          {
 464                    	;  375          crc = 0;
 465                    	;  376          for (nbytes = 0; nbytes < 15; nbytes++)
 466                    	;  377              {
 467                    	;  378              rbyte = spiio(0xff);
 468                    	;  379              cidreg[nbytes] = rbyte;
 469                    	;  380              crc = CRC7_one(crc, rbyte);
 470                    	;  381              }
 471                    	;  382          cidreg[15] = spiio(0xff);
 472                    	;  383          crc |= 0x01;
 473                    	;  384          /* some SD cards need additional clock pulses */
 474                    	;  385          for (nbytes = 9; 0 < nbytes; nbytes--)
 475                    	;  386              spiio(0xff);
 476                    	;  387  #ifdef SDTEST
 477                    	;  388          prtptr = &cidreg[0];
 478                    	;  389          printf("  CID: [");
 479                    	;  390          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 480                    	;  391              printf("%02x ", *prtptr);
 481                    	;  392          prtptr = &cidreg[0];
 482                    	;  393          printf("\b] |");
 483                    	;  394          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 484                    	;  395              {
 485                    	;  396              if ((' ' <= *prtptr) && (*prtptr < 127))
 486                    	;  397                  putchar(*prtptr);
 487                    	;  398              else
 488                    	;  399                  putchar('.');
 489                    	;  400              }
 490                    	;  401          printf("|\n");
 491                    	;  402          if (crc == cidreg[15])
 492                    	;  403              {
 493                    	;  404              printf("CRC7 ok: [%02x]\n", crc);
 494                    	;  405              }
 495                    	;  406          else
 496                    	;  407              {
 497                    	;  408              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
 498                    	;  409                  crc, cidreg[15]);
 499                    	;  410              /* could maybe return failure here */
 500                    	;  411              }
 501                    	;  412  #endif
 502                    	;  413          }
 503                    	;  414  
 504                    	;  415      /* CMD9: SEND_CSD */
 505                    	;  416      memcpy(cmdbuf, cmd9, 5);
 506                    	;  417      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 507                    	;  418  #ifdef SDTEST
 508                    	;  419      if (!statptr)
 509                    	;  420          printf("CMD9: no response\n");
 510                    	;  421      else
 511                    	;  422          printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
 512                    	;  423  #endif
 513                    	;  424      if (!statptr)
 514                    	;  425          {
 515                    	;  426          spideselect();
 516                    	;  427          ledoff();
 517                    	;  428          return (NO);
 518                    	;  429          }
 519                    	;  430      /* looking for 0xfe that is the byte before data */
 520                    	;  431      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
 521                    	;  432          ;
 522                    	;  433      if (tries == 0) /* tried too many times */
 523                    	;  434          {
 524                    	;  435  #ifdef SDTEST
 525                    	;  436          printf("  No data found\n");
 526                    	;  437  #endif
 527                    	;  438          return (NO);
 528                    	;  439          }
 529                    	;  440      else
 530                    	;  441          {
 531                    	;  442          crc = 0;
 532                    	;  443          for (nbytes = 0; nbytes < 15; nbytes++)
 533                    	;  444              {
 534                    	;  445              rbyte = spiio(0xff);
 535                    	;  446              csdreg[nbytes] = rbyte;
 536                    	;  447              crc = CRC7_one(crc, rbyte);
 537                    	;  448              }
 538                    	;  449          csdreg[15] = spiio(0xff);
 539                    	;  450          crc |= 0x01;
 540                    	;  451          /* some SD cards need additional clock pulses */
 541                    	;  452          for (nbytes = 9; 0 < nbytes; nbytes--)
 542                    	;  453              spiio(0xff);
 543                    	;  454  #ifdef SDTEST
 544                    	;  455          prtptr = &csdreg[0];
 545                    	;  456          printf("  CSD: [");
 546                    	;  457          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 547                    	;  458              printf("%02x ", *prtptr);
 548                    	;  459          prtptr = &csdreg[0];
 549                    	;  460          printf("\b] |");
 550                    	;  461          for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
 551                    	;  462              {
 552                    	;  463              if ((' ' <= *prtptr) && (*prtptr < 127))
 553                    	;  464                  putchar(*prtptr);
 554                    	;  465              else
 555                    	;  466                  putchar('.');
 556                    	;  467              }
 557                    	;  468          printf("|\n");
 558                    	;  469          if (crc == csdreg[15])
 559                    	;  470              {
 560                    	;  471              printf("CRC7 ok: [%02x]\n", crc);
 561                    	;  472              }
 562                    	;  473          else
 563                    	;  474              {
 564                    	;  475              printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
 565                    	;  476                  crc, csdreg[15]);
 566                    	;  477              /* could maybe return failure here */
 567                    	;  478              }
 568                    	;  479  #endif
 569                    	;  480          }
 570                    	;  481  
 571                    	;  482      for (nbytes = 9; 0 < nbytes; nbytes--)
 572                    	;  483          spiio(0xff);
 573                    	;  484  #ifdef SDTEST
 574                    	;  485      printf("Sent 9*8 (72) clock pulses, select active\n");
 575                    	;  486  #endif
 576                    	;  487  
 577                    	;  488      sdinitok = YES;
 578                    	;  489  
 579                    	;  490      spideselect();
 580                    	;  491      ledoff();
 581                    	;  492  
 582                    	;  493      return (YES);
 583                    	;  494      }
 584                    	;  495  
 585                    	;  496  /* print OCR, CID and CSD registers*/
 586                    	;  497  void sdprtreg()
 587                    	;  498      {
 588                    	;  499      unsigned int n;
 589                    	;  500      unsigned int csize;
 590                    	;  501      unsigned long devsize;
 591                    	;  502      unsigned long capacity;
 592                    	;  503  
 593                    	;  504      if (!sdinitok)
 594                    	;  505          {
 595                    	;  506          printf("SD card not initialized\n");
 596                    	;  507          return;
 597                    	;  508          }
 598                    	;  509      printf("SD card information:");
 599                    	;  510      if (ocrreg[0] & 0x80)
 600                    	;  511          {
 601                    	;  512          if (ocrreg[0] & 0x40)
 602                    	;  513              printf("  SD card ver. 2+, Block address\n");
 603                    	;  514          else
 604                    	;  515              {
 605                    	;  516              if (sdver2)
 606                    	;  517                  printf("  SD card ver. 2+, Byte address\n");
 607                    	;  518              else
 608                    	;  519                  printf("  SD card ver. 1, Byte address\n");
 609                    	;  520              }
 610                    	;  521          }
 611                    	;  522      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
 612                    	;  523      printf("OEM ID: %.2s, ", &cidreg[1]);
 613                    	;  524      printf("Product name: %.5s\n", &cidreg[3]);
 614                    	;  525      printf("  Product revision: %d.%d, ",
 615                    	;  526             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 616                    	;  527      printf("Serial number: %lu\n",
 617                    	;  528             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
 618                    	;  529      printf("  Manufacturing date: %d-%d, ",
 619                    	;  530             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
 620                    	;  531      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
 621                    	;  532          {
 622                    	;  533          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
 623                    	;  534          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
 624                    	;  535                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
 625                    	;  536          capacity = (unsigned long) csize << (n-10);
 626                    	;  537          printf("Device capacity: %lu MByte\n", capacity >> 10);
 627                    	;  538          }
 628                    	;  539      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
 629                    	;  540          {
 630                    	;  541          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
 631                    	;  542                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 632                    	;  543          capacity = devsize << 9;
 633                    	;  544          printf("Device capacity: %lu MByte\n", capacity >> 10);
 634                    	;  545          }
 635                    	;  546      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
 636                    	;  547          {
 637                    	;  548          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
 638                    	;  549                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 639                    	;  550          capacity = devsize << 9;
 640                    	;  551          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
 641                    	;  552          }
 642                    	;  553  
 643                    	;  554  #ifdef SDTEST
 644                    	;  555  
 645                    	;  556      printf("--------------------------------------\n");
 646                    	;  557      printf("OCR register:\n");
 647                    	;  558      if (ocrreg[2] & 0x80)
 648                    	;  559          printf("2.7-2.8V (bit 15) ");
 649                    	;  560      if (ocrreg[1] & 0x01)
 650                    	;  561          printf("2.8-2.9V (bit 16) ");
 651                    	;  562      if (ocrreg[1] & 0x02)
 652                    	;  563          printf("2.9-3.0V (bit 17) ");
 653                    	;  564      if (ocrreg[1] & 0x04)
 654                    	;  565          printf("3.0-3.1V (bit 18) \n");
 655                    	;  566      if (ocrreg[1] & 0x08)
 656                    	;  567          printf("3.1-3.2V (bit 19) ");
 657                    	;  568      if (ocrreg[1] & 0x10)
 658                    	;  569          printf("3.2-3.3V (bit 20) ");
 659                    	;  570      if (ocrreg[1] & 0x20)
 660                    	;  571          printf("3.3-3.4V (bit 21) ");
 661                    	;  572      if (ocrreg[1] & 0x40)
 662                    	;  573          printf("3.4-3.5V (bit 22) \n");
 663                    	;  574      if (ocrreg[1] & 0x80)
 664                    	;  575          printf("3.5-3.6V (bit 23) \n");
 665                    	;  576      if (ocrreg[0] & 0x01)
 666                    	;  577          printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
 667                    	;  578      if (ocrreg[0] & 0x08)
 668                    	;  579          printf("Over 2TB support Status (CO2T) (bit 27) set\n");
 669                    	;  580      if (ocrreg[0] & 0x20)
 670                    	;  581          printf("UHS-II Card Status (bit 29) set ");
 671                    	;  582      if (ocrreg[0] & 0x80)
 672                    	;  583          {
 673                    	;  584          if (ocrreg[0] & 0x40)
 674                    	;  585              {
 675                    	;  586              printf("Card Capacity Status (CCS) (bit 30) set\n");
 676                    	;  587              printf("  SD Ver.2+, Block address");
 677                    	;  588              }
 678                    	;  589          else
 679                    	;  590              {
 680                    	;  591              printf("Card Capacity Status (CCS) (bit 30) not set\n");
 681                    	;  592              if (sdver2)
 682                    	;  593                  printf("  SD Ver.2+, Byte address");
 683                    	;  594              else
 684                    	;  595                  printf("  SD Ver.1, Byte address");
 685                    	;  596              }
 686                    	;  597          printf("\nCard power up status bit (busy) (bit 31) set\n");
 687                    	;  598          }
 688                    	;  599      else
 689                    	;  600          {
 690                    	;  601          printf("\nCard power up status bit (busy) (bit 31) not set.\n");
 691                    	;  602          printf("  This bit is not set if the card has not finished the power up routine.\n");
 692                    	;  603          }
 693                    	;  604      printf("--------------------------------------\n");
 694                    	;  605      printf("CID register:\n");
 695                    	;  606      printf("MID: 0x%02x, ", cidreg[0]);
 696                    	;  607      printf("OID: %.2s, ", &cidreg[1]);
 697                    	;  608      printf("PNM: %.5s, ", &cidreg[3]);
 698                    	;  609      printf("PRV: %d.%d, ",
 699                    	;  610             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 700                    	;  611      printf("PSN: %lu, ",
 701                    	;  612             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
 702                    	;  613      printf("MDT: %d-%d\n",
 703                    	;  614             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
 704                    	;  615      printf("--------------------------------------\n");
 705                    	;  616      printf("CSD register:\n");
 706                    	;  617      if ((csdreg[0] & 0xc0) == 0x00)
 707                    	;  618          {
 708                    	;  619          printf("CSD Version 1.0, Standard Capacity\n");
 709                    	;  620          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
 710                    	;  621          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
 711                    	;  622                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
 712                    	;  623          capacity = (unsigned long) csize << (n-10);
 713                    	;  624          printf(" Device capacity: %lu KByte, %lu MByte\n",
 714                    	;  625                 capacity, capacity >> 10);
 715                    	;  626          }
 716                    	;  627      if ((csdreg[0] & 0xc0) == 0x40)
 717                    	;  628          {
 718                    	;  629          printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
 719                    	;  630          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
 720                    	;  631                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 721                    	;  632          capacity = devsize << 9;
 722                    	;  633          printf(" Device capacity: %lu KByte, %lu MByte\n",
 723                    	;  634                 capacity, capacity >> 10);
 724                    	;  635          }
 725                    	;  636      if ((csdreg[0] & 0xc0) == 0x80)
 726                    	;  637          {
 727                    	;  638          printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
 728                    	;  639          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
 729                    	;  640                    + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 730                    	;  641          capacity = devsize << 9;
 731                    	;  642          printf(" Device capacity: %lu KByte, %lu MByte\n",
 732                    	;  643                 capacity, capacity >> 10);
 733                    	;  644          }
 734                    	;  645      printf("--------------------------------------\n");
 735                    	;  646  
 736                    	;  647  #endif /* SDTEST */
 737                    	;  648  
 738                    	;  649      }
 739                    	;  650  
 740                    	;  651  /* Read data block of 512 bytes to buffer
 741                    	;  652   * Returns YES if ok or NO if error
 742                    	;  653   */
 743                    	;  654  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
 744                    	;  655      {
 745                    	;  656      unsigned char *statptr;
 746                    	;  657      unsigned char rbyte;
 747                    	;  658      unsigned char cmdbuf[5];   /* buffer to build command in */
 748                    	;  659      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 749                    	;  660      int nbytes;
 750                    	;  661      int tries;
 751                    	;  662      unsigned long blktoread;
 752                    	;  663      unsigned int rxcrc16;
 753                    	;  664      unsigned int calcrc16;
 754                    	;  665  
 755                    	;  666      ledon();
 756                    	;  667      spiselect();
 757                    	;  668  
 758                    	;  669      if (!sdinitok)
 759                    	;  670          {
 760                    	;  671  #ifdef SDTEST
 761                    	;  672          printf("SD card not initialized\n");
 762                    	;  673  #endif
 763                    	;  674          spideselect();
 764                    	;  675          ledoff();
 765                    	;  676          return (NO);
 766                    	;  677          }
 767                    	;  678  
 768                    	;  679      /* CMD17: READ_SINGLE_BLOCK */
 769                    	;  680      /* Insert block # into command */
 770                    	;  681      memcpy(cmdbuf, cmd17, 5);
 771                    	;  682      blktoread = blkmult * rdblkno;
 772                    	;  683      cmdbuf[4] = blktoread & 0xff;
 773                    	;  684      blktoread = blktoread >> 8;
 774                    	;  685      cmdbuf[3] = blktoread & 0xff;
 775                    	;  686      blktoread = blktoread >> 8;
 776                    	;  687      cmdbuf[2] = blktoread & 0xff;
 777                    	;  688      blktoread = blktoread >> 8;
 778                    	;  689      cmdbuf[1] = blktoread & 0xff;
 779                    	;  690  
 780                    	;  691  #ifdef SDTEST
 781                    	;  692      printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
 782                    	;  693                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
 783                    	;  694  #endif
 784                    	;  695      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 785                    	;  696  #ifdef SDTEST
 786                    	;  697          printf("CMD17 R1 response [%02x]\n", statptr[0]);
 787                    	;  698  #endif
 788                    	;  699      if (statptr[0])
 789                    	;  700          {
 790                    	;  701  #ifdef SDTEST
 791                    	;  702          printf("  could not read block\n");
 792                    	;  703  #endif
 793                    	;  704          spideselect();
 794                    	;  705          ledoff();
 795                    	;  706          return (NO);
 796                    	;  707          }
 797                    	;  708      /* looking for 0xfe that is the byte before data */
 798                    	;  709      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
 799                    	;  710          {
 800                    	;  711          if ((rbyte & 0xe0) == 0x00)
 801                    	;  712              {
 802                    	;  713              /* If a read operation fails and the card cannot provide
 803                    	;  714                 the required data, it will send a data error token instead
 804                    	;  715               */
 805                    	;  716  #ifdef SDTEST
 806                    	;  717              printf("  read error: [%02x]\n", rbyte);
 807                    	;  718  #endif
 808                    	;  719              spideselect();
 809                    	;  720              ledoff();
 810                    	;  721              return (NO);
 811                    	;  722              }
 812                    	;  723          }
 813                    	;  724      if (tries == 0) /* tried too many times */
 814                    	;  725          {
 815                    	;  726  #ifdef SDTEST
 816                    	;  727          printf("  no data found\n");
 817                    	;  728  #endif
 818                    	;  729          spideselect();
 819                    	;  730          ledoff();
 820                    	;  731          return (NO);
 821                    	;  732          }
 822                    	;  733      else
 823                    	;  734          {
 824                    	;  735          calcrc16 = 0;
 825                    	;  736          for (nbytes = 0; nbytes < 512; nbytes++)
 826                    	;  737              {
 827                    	;  738              rbyte = spiio(0xff);
 828                    	;  739              calcrc16 = CRC16_one(calcrc16, rbyte);
 829                    	;  740              rdbuf[nbytes] = rbyte;
 830                    	;  741              }
 831                    	;  742          rxcrc16 = spiio(0xff) << 8;
 832                    	;  743          rxcrc16 += spiio(0xff);
 833                    	;  744  
 834                    	;  745  #ifdef SDTEST
 835                    	;  746          printf("  read data block %ld:\n", rdblkno);
 836                    	;  747  #endif
 837                    	;  748          if (rxcrc16 != calcrc16)
 838                    	;  749              {
 839                    	;  750  #ifdef SDTEST
 840                    	;  751              printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
 841                    	;  752                  rxcrc16, calcrc16);
 842                    	;  753  #endif
 843                    	;  754              spideselect();
 844                    	;  755              ledoff();
 845                    	;  756              return (NO);
 846                    	;  757              }
 847                    	;  758          }
 848                    	;  759      spideselect();
 849                    	;  760      ledoff();
 850                    	;  761      return (YES);
 851                    	;  762      }
 852                    	;  763  
 853                    	;  764  /* Write data block of 512 bytes from buffer
 854                    	;  765   * Returns YES if ok or NO if error
 855                    	;  766   */
 856                    	;  767  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
 857                    	;  768      {
 858                    	;  769      unsigned char *statptr;
 859                    	;  770      unsigned char rbyte;
 860                    	;  771      unsigned char tbyte;
 861                    	;  772      unsigned char cmdbuf[5];   /* buffer to build command in */
 862                    	;  773      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 863                    	;  774      int nbytes;
 864                    	;  775      int tries;
 865                    	;  776      unsigned long blktowrite;
 866                    	;  777      unsigned int calcrc16;
 867                    	;  778  
 868                    	;  779      ledon();
 869                    	;  780      spiselect();
 870                    	;  781  
 871                    	;  782      if (!sdinitok)
 872                    	;  783          {
 873                    	;  784  #ifdef SDTEST
 874                    	;  785          printf("SD card not initialized\n");
 875                    	;  786  #endif
 876                    	;  787          spideselect();
 877                    	;  788          ledoff();
 878                    	;  789          return (NO);
 879                    	;  790          }
 880                    	;  791  
 881                    	;  792  #ifdef SDTEST
 882                    	;  793      printf("  write data block %ld:\n", wrblkno);
 883                    	;  794  #endif
 884                    	;  795      /* CMD24: WRITE_SINGLE_BLOCK */
 885                    	;  796      /* Insert block # into command */
 886                    	;  797      memcpy(cmdbuf, cmd24, 5);
 887                    	;  798      blktowrite = blkmult * wrblkno;
 888                    	;  799      cmdbuf[4] = blktowrite & 0xff;
 889                    	;  800      blktowrite = blktowrite >> 8;
 890                    	;  801      cmdbuf[3] = blktowrite & 0xff;
 891                    	;  802      blktowrite = blktowrite >> 8;
 892                    	;  803      cmdbuf[2] = blktowrite & 0xff;
 893                    	;  804      blktowrite = blktowrite >> 8;
 894                    	;  805      cmdbuf[1] = blktowrite & 0xff;
 895                    	;  806  
 896                    	;  807  #ifdef SDTEST
 897                    	;  808      printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
 898                    	;  809                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
 899                    	;  810  #endif
 900                    	;  811      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 901                    	;  812  #ifdef SDTEST
 902                    	;  813          printf("CMD24 R1 response [%02x]\n", statptr[0]);
 903                    	;  814  #endif
 904                    	;  815      if (statptr[0])
 905                    	;  816          {
 906                    	;  817  #ifdef SDTEST
 907                    	;  818          printf("  could not write block\n");
 908                    	;  819  #endif
 909                    	;  820          spideselect();
 910                    	;  821          ledoff();
 911                    	;  822          return (NO);
 912                    	;  823          }
 913                    	;  824      /* send 0xfe, the byte before data */
 914                    	;  825      spiio(0xfe);
 915                    	;  826      /* initialize crc and send block */
 916                    	;  827      calcrc16 = 0;
 917                    	;  828      for (nbytes = 0; nbytes < 512; nbytes++)
 918                    	;  829          {
 919                    	;  830          tbyte = wrbuf[nbytes];
 920                    	;  831          spiio(tbyte);
 921                    	;  832          calcrc16 = CRC16_one(calcrc16, tbyte);
 922                    	;  833          }
 923                    	;  834      spiio((calcrc16 >> 8) & 0xff);
 924                    	;  835      spiio(calcrc16 & 0xff);
 925                    	;  836  
 926                    	;  837      /* check data resposnse */
 927                    	;  838      for (tries = 20; 
 928                    	;  839          0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
 929                    	;  840          tries--)
 930                    	;  841          ;
 931                    	;  842      if (tries == 0)
 932                    	;  843          {
 933                    	;  844  #ifdef SDTEST
 934                    	;  845          printf("No data response\n");
 935                    	;  846  #endif
 936                    	;  847          spideselect();
 937                    	;  848          ledoff();
 938                    	;  849          return (NO);
 939                    	;  850          }
 940                    	;  851      else
 941                    	;  852          {
 942                    	;  853  #ifdef SDTEST
 943                    	;  854          printf("Data response [%02x]", 0x1f & rbyte);
 944                    	;  855  #endif
 945                    	;  856          if ((0x1f & rbyte) == 0x05)
 946                    	;  857              {
 947                    	;  858  #ifdef SDTEST
 948                    	;  859              printf(", data accepted\n");
 949                    	;  860  #endif
 950                    	;  861              for (nbytes = 9; 0 < nbytes; nbytes--)
 951                    	;  862                  spiio(0xff);
 952                    	;  863  #ifdef SDTEST
 953                    	;  864              printf("Sent 9*8 (72) clock pulses, select active\n");
 954                    	;  865  #endif
 955                    	;  866              spideselect();
 956                    	;  867              ledoff();
 957                    	;  868              return (YES);
 958                    	;  869              }
 959                    	;  870          else
 960                    	;  871              {
 961                    	;  872  #ifdef SDTEST
 962                    	;  873              printf(", data not accepted\n");
 963                    	;  874  #endif
 964                    	;  875              spideselect();
 965                    	;  876              ledoff();
 966                    	;  877              return (NO);
 967                    	;  878              }
 968                    	;  879          }
 969                    	;  880      }
 970                    	;  881  
 971                    	;  882  /* Print data in 512 byte buffer */
 972                    	;  883  void sddatprt(unsigned char *prtbuf)
 973                    	;  884      {
 974                    	;  885      /* Variables used for "pretty-print" */
 975                    	;  886      int allzero, dmpline, dotprted, lastallz, nbytes;
 976                    	;  887      unsigned char *prtptr;
 977                    	;  888  
 978                    	;  889      prtptr = prtbuf;
 979                    	;  890      dotprted = NO;
 980                    	;  891      lastallz = NO;
 981                    	;  892      for (dmpline = 0; dmpline < 32; dmpline++)
 982                    	;  893          {
 983                    	;  894          /* test if all 16 bytes are 0x00 */
 984                    	;  895          allzero = YES;
 985                    	;  896          for (nbytes = 0; nbytes < 16; nbytes++)
 986                    	;  897              {
 987                    	;  898              if (prtptr[nbytes] != 0)
 988                    	;  899                  allzero = NO;
 989                    	;  900              }
 990                    	;  901          if (lastallz && allzero)
 991                    	;  902              {
 992                    	;  903              if (!dotprted)
 993                    	;  904                  {
 994                    	;  905                  printf("*\n");
 995                    	;  906                  dotprted = YES;
 996                    	;  907                  }
 997                    	;  908              }
 998                    	;  909          else
 999                    	;  910              {
1000                    	;  911              dotprted = NO;
1001                    	;  912              /* print offset */
1002                    	;  913              printf("%04x ", dmpline * 16);
1003                    	;  914              /* print 16 bytes in hex */
1004                    	;  915              for (nbytes = 0; nbytes < 16; nbytes++)
1005                    	;  916                  printf("%02x ", prtptr[nbytes]);
1006                    	;  917              /* print these bytes in ASCII if printable */
1007                    	;  918              printf(" |");
1008                    	;  919              for (nbytes = 0; nbytes < 16; nbytes++)
1009                    	;  920                  {
1010                    	;  921                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
1011                    	;  922                      putchar(prtptr[nbytes]);
1012                    	;  923                  else
1013                    	;  924                      putchar('.');
1014                    	;  925                  }
1015                    	;  926              printf("|\n");
1016                    	;  927              }
1017                    	;  928          prtptr += 16;
1018                    	;  929          lastallz = allzero;
1019                    	;  930          }
1020                    	;  931      }
1021                    	;  932  
1022                    	;  933  /* print GUID (mixed endian format) */
1023                    	;  934  void prtguid(unsigned char *guidptr)
1024                    	;  935      {
1025                    	;  936      int index;
1026                    	;  937  
1027                    	;  938      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
1028                    	;  939      printf("%02x%02x-", guidptr[5], guidptr[4]);
1029                    	;  940      printf("%02x%02x-", guidptr[7], guidptr[6]);
1030                    	;  941      printf("%02x%02x-", guidptr[8], guidptr[9]);
1031                    	;  942      printf("%02x%02x%02x%02x%02x%02x",
1032                    	;  943             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
1033                    	;  944      printf("\n  [");
1034                    	;  945      for (index = 0; index < 16; index++)
1035                    	;  946          printf("%02x ", guidptr[index]);
1036                    	;  947      printf("\b]");
1037                    	;  948      }
1038                    	;  949  
1039                    	;  950  /* print GPT entry */
1040                    	;  951  void prtgptent(unsigned int entryno)
1041                    	;  952      {
1042                    	;  953      int index;
1043                    	;  954      int entryidx;
1044                    	;  955      int hasname;
1045                    	;  956      unsigned int block;
1046                    	;  957      unsigned char *rxdata;
1047                    	;  958      unsigned char *entryptr;
1048                    	;  959      unsigned char tstzero = 0;
1049                    	;  960      unsigned long flba;
1050                    	;  961      unsigned long llba;
1051                    	;  962  
1052                    	;  963      block = 2 + (entryno / 4);
1053                    	;  964      if ((curblkno != block) || !curblkok)
1054                    	;  965          {
1055                    	;  966          if (!sdread(sdrdbuf, block))
1056                    	;  967              {
1057                    	;  968              printf("Can't read GPT entry block\n");
1058                    	;  969              return;
1059                    	;  970              }
1060                    	;  971          curblkno = block;
1061                    	;  972          curblkok = YES;
1062                    	;  973          }
1063                    	;  974      rxdata = sdrdbuf;
1064                    	;  975      entryptr = rxdata + (128 * (entryno % 4));
1065                    	;  976      for (index = 0; index < 16; index++)
1066                    	;  977          tstzero |= entryptr[index];
1067                    	;  978      printf("GPT partition entry %d:", entryno + 1);
1068                    	;  979      if (!tstzero)
1069                    	;  980          {
1070                    	;  981          printf(" Not used entry\n");
1071                    	;  982          return;
1072                    	;  983          }
1073                    	;  984      printf("\n  Partition type GUID: ");
1074                    	;  985      prtguid(entryptr);
1075                    	;  986      printf("\n  Unique partition GUID: ");
1076                    	;  987      prtguid(entryptr + 16);
1077                    	;  988      printf("\n  First LBA: ");
1078                    	;  989      /* lower 32 bits of LBA should be sufficient (I hope) */
1079                    	;  990      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
1080                    	;  991             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
1081                    	;  992      printf("%lu", flba);
1082                    	;  993      printf(" [");
1083                    	;  994      for (index = 32; index < (32 + 8); index++)
1084                    	;  995          printf("%02x ", entryptr[index]);
1085                    	;  996      printf("\b]");
1086                    	;  997      printf("\n  Last LBA: ");
1087                    	;  998      /* lower 32 bits of LBA should be sufficient (I hope) */
1088                    	;  999      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
1089                    	; 1000             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
1090                    	; 1001      printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
1091                    	; 1002      printf(" [");
1092                    	; 1003      for (index = 40; index < (40 + 8); index++)
1093                    	; 1004          printf("%02x ", entryptr[index]);
1094                    	; 1005      printf("\b]");
1095                    	; 1006      printf("\n  Attribute flags: [");
1096                    	; 1007      /* bits 0 - 2 and 60 - 63 should be decoded */
1097                    	; 1008      for (index = 0; index < 8; index++)
1098                    	; 1009          {
1099                    	; 1010          entryidx = index + 48;
1100                    	; 1011          printf("%02x ", entryptr[entryidx]);
1101                    	; 1012          }
1102                    	; 1013      printf("\b]\n  Partition name:  ");
1103                    	; 1014      /* partition name is in UTF-16LE code units */
1104                    	; 1015      hasname = NO;
1105                    	; 1016      for (index = 0; index < 72; index += 2)
1106                    	; 1017          {
1107                    	; 1018          entryidx = index + 56;
1108                    	; 1019          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
1109                    	; 1020              break;
1110                    	; 1021          if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
1111                    	; 1022              putchar(entryptr[entryidx]);
1112                    	; 1023          else
1113                    	; 1024              putchar('.');
1114                    	; 1025          hasname = YES;
1115                    	; 1026          }
1116                    	; 1027      if (!hasname)
1117                    	; 1028          printf("name field empty");
1118                    	; 1029      printf("\n");
1119                    	; 1030      printf("   [");
1120                    	; 1031      entryidx = index + 56;
1121                    	; 1032      for (index = 0; index < 72; index++)
1122                    	; 1033          {
1123                    	; 1034          if (((index & 0xf) == 0) && (index != 0))
1124                    	; 1035              printf("\n    ");
1125                    	; 1036          printf("%02x ", entryptr[entryidx]);
1126                    	; 1037          }
1127                    	; 1038      printf("\b]\n");
1128                    	; 1039      }
1129                    	; 1040  
1130                    	; 1041  /* Get GPT header */
1131                    	; 1042  void sdgpthdr(unsigned long block)
1132                    	; 1043      {
1133                    	; 1044      int index;
1134                    	; 1045      unsigned int partno;
1135                    	; 1046      unsigned char *rxdata;
1136                    	; 1047      unsigned long entries;
1137                    	; 1048  
1138                    	; 1049      printf("GPT header\n");
1139                    	; 1050      if (!sdread(sdrdbuf, block))
1140                    	; 1051          {
1141                    	; 1052          printf("Can't read GPT partition table header\n");
1142                    	; 1053          return;
1143                    	; 1054          }
1144                    	; 1055      curblkno = block;
1145                    	; 1056      curblkok = YES;
1146                    	; 1057  
1147                    	; 1058      rxdata = sdrdbuf;
1148                    	; 1059      printf("  Signature: %.8s\n", &rxdata[0]);
1149                    	; 1060      printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
1150                    	; 1061             (int)rxdata[8] * ((int)rxdata[9] << 8),
1151                    	; 1062             (int)rxdata[10] + ((int)rxdata[11] << 8),
1152                    	; 1063             rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
1153                    	; 1064      entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
1154                    	; 1065                ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
1155                    	; 1066      printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
1156                    	; 1067      for (partno = 0; partno < 16; partno++)
1157                    	; 1068          {
1158                    	; 1069          prtgptent(partno);
1159                    	; 1070          }
1160                    	; 1071      printf("First 16 GPT entries scanned\n");
1161                    	; 1072      }
1162                    	; 1073  
1163                    	; 1074  /* read MBR partition entry */
1164                    	; 1075  int sdmbrentry(unsigned char *partptr)
1165                    	; 1076      {
1166                    	; 1077      int index;
1167                    	; 1078      unsigned long lbastart;
1168                    	; 1079      unsigned long lbasize;
1169                    	; 1080  
1170                    	; 1081      if ((curblkno != 0) || !curblkok)
1171                    	; 1082          {
1172                    	; 1083          curblkno = 0;
1173                    	; 1084          if (!sdread(sdrdbuf, curblkno))
1174                    	; 1085              {
1175                    	; 1086              printf("Can't read MBR sector\n");
1176                    	; 1087              return;
1177                    	; 1088              }
1178                    	; 1089          curblkok = YES;
1179                    	; 1090          }
1180                    	; 1091      if (!partptr[4])
1181                    	; 1092          {
1182                    	; 1093          printf("Not used entry\n");
1183                    	; 1094          return;
1184                    	; 1095          }
1185                    	; 1096      printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
1186                    	; 1097             partptr[0], partptr[4]);
1187                    	; 1098  
1188                    	; 1099      if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
1189                    	; 1100          {
1190                    	; 1101          printf("  Extended partition\n");
1191                    	; 1102          /* should probably decode this also */
1192                    	; 1103          }
1193                    	; 1104      if (partptr[0] & 0x01)
1194                    	; 1105          {
1195                    	; 1106          printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
1196                    	; 1107          /* this is however discussed
1197                    	; 1108             https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
1198                    	; 1109          */
1199                    	; 1110          }
1200                    	; 1111      else
1201                    	; 1112          {
1202                    	; 1113          printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1203                    	; 1114                 partptr[1], partptr[2], partptr[3],
1204                    	; 1115                 ((partptr[2] & 0xc0) >> 2) + partptr[3],
1205                    	; 1116                 partptr[1],
1206                    	; 1117                 partptr[2] & 0x3f);
1207                    	; 1118          printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
1208                    	; 1119                 partptr[5], partptr[6], partptr[7],
1209                    	; 1120                 ((partptr[6] & 0xc0) >> 2) + partptr[7],
1210                    	; 1121                 partptr[5],
1211                    	; 1122                 partptr[6] & 0x3f);
1212                    	; 1123          }
1213                    	; 1124      /* not showing high 16 bits if 48 bit LBA */
1214                    	; 1125      lbastart = (unsigned long)partptr[8] +
1215                    	; 1126                 ((unsigned long)partptr[9] << 8) +
1216                    	; 1127                 ((unsigned long)partptr[10] << 16) +
1217                    	; 1128                 ((unsigned long)partptr[11] << 24);
1218                    	; 1129      lbasize = (unsigned long)partptr[12] +
1219                    	; 1130                ((unsigned long)partptr[13] << 8) +
1220                    	; 1131                ((unsigned long)partptr[14] << 16) +
1221                    	; 1132                ((unsigned long)partptr[15] << 24);
1222                    	; 1133      printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
1223                    	; 1134      printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
1224                    	; 1135             lbasize, lbasize, lbasize >> 11);
1225                    	; 1136      if (partptr[4] == 0xee)
1226                    	; 1137          sdgpthdr(lbastart);
1227                    	; 1138      }
1228                    	; 1139  
1229                    	; 1140  /* read MBR partition information */
1230                    	; 1141  void sdmbrpart()
1231                    	; 1142      {
1232                    	; 1143      int partidx;  /* partition index 1 - 4 */
1233                    	; 1144      unsigned char *entp; /* pointer to partition entry */
1234                    	; 1145  
1235                    	; 1146  #ifdef SDTEST
1236                    	; 1147      printf("Read MBR\n");
1237                    	; 1148  #endif
1238                    	; 1149      if (!sdread(sdrdbuf, 0))
1239                    	; 1150          {
1240                    	; 1151  #ifdef SDTEST
1241                    	; 1152          printf("  can't read MBR sector\n");
1242                    	; 1153  #endif
1243                    	; 1154          return;
1244                    	; 1155          }
1245                    	; 1156      curblkno = 0;
1246                    	; 1157      curblkok = YES;
1247                    	; 1158      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
1248                    	; 1159          {
1249                    	; 1160  #ifdef SDTEST
1250                    	; 1161          printf("  no MBR signature found\n");
1251                    	; 1162  #endif
1252                    	; 1163          return;
1253                    	; 1164          }
1254                    	; 1165      /* go through MBR partition entries until first empty */
1255                    	; 1166      entp = &sdrdbuf[0x01be];
1256                    	; 1167      for (partidx = 1; partidx <= 4; partidx++, entp += 16)
1257                    	; 1168          {
1258                    	; 1169  #ifdef SDTEST
1259                    	; 1170          printf("MBR partition entry %d: ", partidx);
1260                    	; 1171  #endif
1261                    	; 1172          if (!sdmbrentry(entp))
1262                    	; 1173              break;
1263                    	; 1174          }
1264                    	; 1175      }
1265                    	; 1176  
1266                    	; 1177  /* Test init, read and partitions on SD card over the SPI interface
1267                    	; 1178   *
1268                    	; 1179   */
1269                    	; 1180  int main()
1270                    	; 1181      {
1271                    	; 1182      char txtin[10];
1272                    	; 1183      int cmdin;
1273                    	; 1184      int inlength;
1274                    	; 1185      unsigned long blockno;
1275                    	; 1186  
1276                    	; 1187      blockno = 0;
1277                    	; 1188      curblkno = 0;
1278    3952  320000    		ld	(_curblkno),a
1279    3955  320100    		ld	(_curblkno+1),a
1280    3958  320200    		ld	(_curblkno+2),a
1281    395B  320300    		ld	(_curblkno+3),a
1282    395E  220C00    		ld	(_curblkok),hl
1283                    	; 1189      curblkok = NO;
1284                    	; 1190      sdinitok = NO; /* SD card not initialized yet */
1285    3961  210000    		ld	hl,0
1286    3964  220A00    		ld	(_sdinitok),hl
1287                    	; 1191  
1288                    	; 1192      printf(PRGNAME);
1289    3967  21A436    		ld	hl,L5642
1290    396A  CD0000    		call	_printf
1291                    	; 1193      printf(VERSION);
1292    396D  21B036    		ld	hl,L5742
1293    3970  CD0000    		call	_printf
1294                    	; 1194      printf(builddate);
1295    3973  210000    		ld	hl,_builddate
1296    3976  CD0000    		call	_printf
1297                    	; 1195      printf("\n");
1298    3979  21BE36    		ld	hl,L5052
1299    397C  CD0000    		call	_printf
1300                    	L1214:
1301                    	; 1196      while (YES) /* forever (until Ctrl-C) */
1302                    	; 1197          {
1303                    	; 1198          printf("cmd (h for help): ");
1304    397F  21C036    		ld	hl,L5152
1305    3982  CD0000    		call	_printf
1306                    	; 1199  
1307                    	; 1200          cmdin = getchar();
1308    3985  CD0000    		call	_getchar
1309    3988  DD71EE    		ld	(ix-18),c
1310    398B  DD70EF    		ld	(ix-17),b
1311                    	; 1201          switch (cmdin)
1312    398E  DD4EEE    		ld	c,(ix-18)
1313    3991  DD46EF    		ld	b,(ix-17)
1314    3994  211039    		ld	hl,L1414
1315    3997  C30000    		jp	c.jtab
1316                    	L1614:
1317                    	; 1202              {
1318                    	; 1203              case 'h':
1319                    	; 1204                  printf(" h - help\n");
1320    399A  21D336    		ld	hl,L5252
1321    399D  CD0000    		call	_printf
1322                    	; 1205                  printf(PRGNAME);
1323    39A0  21DE36    		ld	hl,L5352
1324    39A3  CD0000    		call	_printf
1325                    	; 1206                  printf(VERSION);
1326    39A6  21EA36    		ld	hl,L5452
1327    39A9  CD0000    		call	_printf
1328                    	; 1207                  printf(builddate);
1329    39AC  210000    		ld	hl,_builddate
1330    39AF  CD0000    		call	_printf
1331                    	; 1208                  printf("\nCommands:\n");
1332    39B2  21F836    		ld	hl,L5552
1333    39B5  CD0000    		call	_printf
1334                    	; 1209                  printf("  h - help\n");
1335    39B8  210437    		ld	hl,L5652
1336    39BB  CD0000    		call	_printf
1337                    	; 1210                  printf("  i - initialize\n");
1338    39BE  211037    		ld	hl,L5752
1339    39C1  CD0000    		call	_printf
1340                    	; 1211                  printf("  n - set/show block #N to read\n");
1341    39C4  212237    		ld	hl,L5062
1342    39C7  CD0000    		call	_printf
1343                    	; 1212                  printf("  r - read block #N\n");
1344    39CA  214337    		ld	hl,L5162
1345    39CD  CD0000    		call	_printf
1346                    	; 1213                  printf("  w - read block #N\n");
1347    39D0  215837    		ld	hl,L5262
1348    39D3  CD0000    		call	_printf
1349                    	; 1214                  printf("  p - print block last read/to write\n");
1350    39D6  216D37    		ld	hl,L5362
1351    39D9  CD0000    		call	_printf
1352                    	; 1215                  printf("  s - print SD registers\n");
1353    39DC  219337    		ld	hl,L5462
1354    39DF  CD0000    		call	_printf
1355                    	; 1216                  printf("  l - print partition layout\n");
1356    39E2  21AD37    		ld	hl,L5562
1357    39E5  CD0000    		call	_printf
1358                    	; 1217                  printf("  Ctrl-C to reload monitor.\n");
1359    39E8  21CB37    		ld	hl,L5662
1360    39EB  CD0000    		call	_printf
1361                    	; 1218                  break;
1362    39EE  C37F39    		jp	L1214
1363                    	L1714:
1364                    	; 1219              case 'i':
1365                    	; 1220                  printf(" i - initialize SD card");
1366    39F1  21E837    		ld	hl,L5762
1367    39F4  CD0000    		call	_printf
1368                    	; 1221                  if (sdinit())
1369    39F7  CDF605    		call	_sdinit
1370    39FA  79        		ld	a,c
1371    39FB  B0        		or	b
1372    39FC  2809      		jr	z,L1024
1373                    	; 1222                      printf(" - ok\n");
1374    39FE  210038    		ld	hl,L5072
1375    3A01  CD0000    		call	_printf
1376                    	; 1223                  else
1377    3A04  C37F39    		jp	L1214
1378                    	L1024:
1379                    	; 1224                      printf(" - not inserted or faulty\n");
1380    3A07  210738    		ld	hl,L5172
1381    3A0A  CD0000    		call	_printf
1382    3A0D  C37F39    		jp	L1214
1383                    	L1224:
1384                    	; 1225                  break;
1385                    	; 1226              case 'n':
1386                    	; 1227                  printf(" n - block number: ");
1387    3A10  212238    		ld	hl,L5272
1388    3A13  CD0000    		call	_printf
1389                    	; 1228                  if (getkline(txtin, sizeof txtin))
1390    3A16  210A00    		ld	hl,10
1391    3A19  E5        		push	hl
1392    3A1A  DDE5      		push	ix
1393    3A1C  C1        		pop	bc
1394    3A1D  21F0FF    		ld	hl,65520
1395    3A20  09        		add	hl,bc
1396    3A21  CD0000    		call	_getkline
1397    3A24  F1        		pop	af
1398    3A25  79        		ld	a,c
1399    3A26  B0        		or	b
1400    3A27  281A      		jr	z,L1324
1401                    	; 1229                      sscanf(txtin, "%lu", &blockno);
1402    3A29  DDE5      		push	ix
1403    3A2B  C1        		pop	bc
1404    3A2C  21E8FF    		ld	hl,65512
1405    3A2F  09        		add	hl,bc
1406    3A30  E5        		push	hl
1407    3A31  213638    		ld	hl,L5372
1408    3A34  E5        		push	hl
1409    3A35  DDE5      		push	ix
1410    3A37  C1        		pop	bc
1411    3A38  21F0FF    		ld	hl,65520
1412    3A3B  09        		add	hl,bc
1413    3A3C  CD0000    		call	_sscanf
1414    3A3F  F1        		pop	af
1415    3A40  F1        		pop	af
1416                    	; 1230                  else
1417    3A41  1816      		jr	L1424
1418                    	L1324:
1419                    	; 1231                      printf("%lu", blockno);
1420    3A43  DD66EB    		ld	h,(ix-21)
1421    3A46  DD6EEA    		ld	l,(ix-22)
1422    3A49  E5        		push	hl
1423    3A4A  DD66E9    		ld	h,(ix-23)
1424    3A4D  DD6EE8    		ld	l,(ix-24)
1425    3A50  E5        		push	hl
1426    3A51  213A38    		ld	hl,L5472
1427    3A54  CD0000    		call	_printf
1428    3A57  F1        		pop	af
1429    3A58  F1        		pop	af
1430                    	L1424:
1431                    	; 1232                  printf("\n");
1432    3A59  213E38    		ld	hl,L5572
1433    3A5C  CD0000    		call	_printf
1434                    	; 1233                  break;
1435    3A5F  C37F39    		jp	L1214
1436                    	L1524:
1437                    	; 1234              case 'r':
1438                    	; 1235                  printf(" r - read block");
1439    3A62  214038    		ld	hl,L5672
1440    3A65  CD0000    		call	_printf
1441                    	; 1236                  if (sdread(sdrdbuf, blockno))
1442    3A68  DD66EB    		ld	h,(ix-21)
1443    3A6B  DD6EEA    		ld	l,(ix-22)
1444    3A6E  E5        		push	hl
1445    3A6F  DD66E9    		ld	h,(ix-23)
1446    3A72  DD6EE8    		ld	l,(ix-24)
1447    3A75  E5        		push	hl
1448    3A76  213200    		ld	hl,_sdrdbuf
1449    3A79  CD671E    		call	_sdread
1450    3A7C  F1        		pop	af
1451    3A7D  F1        		pop	af
1452    3A7E  79        		ld	a,c
1453    3A7F  B0        		or	b
1454    3A80  2819      		jr	z,L1624
1455                    	; 1237                      {
1456                    	; 1238                      printf(" - ok\n");
1457    3A82  215038    		ld	hl,L5772
1458    3A85  CD0000    		call	_printf
1459                    	; 1239                      curblkno = blockno;
1460    3A88  210000    		ld	hl,_curblkno
1461    3A8B  E5        		push	hl
1462    3A8C  DDE5      		push	ix
1463    3A8E  C1        		pop	bc
1464    3A8F  21E8FF    		ld	hl,65512
1465    3A92  09        		add	hl,bc
1466    3A93  E5        		push	hl
1467    3A94  CD0000    		call	c.mvl
1468    3A97  F1        		pop	af
1469                    	; 1240                      }
1470                    	; 1241                  else
1471    3A98  C37F39    		jp	L1214
1472                    	L1624:
1473                    	; 1242                      printf(" - error\n");
1474    3A9B  215738    		ld	hl,L5003
1475    3A9E  CD0000    		call	_printf
1476    3AA1  C37F39    		jp	L1214
1477                    	L1034:
1478                    	; 1243                  break;
1479                    	; 1244              case 'w':
1480                    	; 1245                  printf(" w - write block");
1481    3AA4  216138    		ld	hl,L5103
1482    3AA7  CD0000    		call	_printf
1483                    	; 1246                  if (sdwrite(sdrdbuf, blockno))
1484    3AAA  DD66EB    		ld	h,(ix-21)
1485    3AAD  DD6EEA    		ld	l,(ix-22)
1486    3AB0  E5        		push	hl
1487    3AB1  DD66E9    		ld	h,(ix-23)
1488    3AB4  DD6EE8    		ld	l,(ix-24)
1489    3AB7  E5        		push	hl
1490    3AB8  213200    		ld	hl,_sdrdbuf
1491    3ABB  CDEA21    		call	_sdwrite
1492    3ABE  F1        		pop	af
1493    3ABF  F1        		pop	af
1494    3AC0  79        		ld	a,c
1495    3AC1  B0        		or	b
1496    3AC2  2819      		jr	z,L1134
1497                    	; 1247                      {
1498                    	; 1248                      printf(" - ok\n");
1499    3AC4  217238    		ld	hl,L5203
1500    3AC7  CD0000    		call	_printf
1501                    	; 1249                      curblkno = blockno;
1502    3ACA  210000    		ld	hl,_curblkno
1503    3ACD  E5        		push	hl
1504    3ACE  DDE5      		push	ix
1505    3AD0  C1        		pop	bc
1506    3AD1  21E8FF    		ld	hl,65512
1507    3AD4  09        		add	hl,bc
1508    3AD5  E5        		push	hl
1509    3AD6  CD0000    		call	c.mvl
1510    3AD9  F1        		pop	af
1511                    	; 1250                      }
1512                    	; 1251                  else
1513    3ADA  C37F39    		jp	L1214
1514                    	L1134:
1515                    	; 1252                      printf(" - error\n");
1516    3ADD  217938    		ld	hl,L5303
1517    3AE0  CD0000    		call	_printf
1518    3AE3  C37F39    		jp	L1214
1519                    	L1334:
1520                    	; 1253                  break;
1521                    	; 1254              case 'p':
1522                    	; 1255                  printf(" p - print data block %lu\n", curblkno);
1523    3AE6  210300    		ld	hl,_curblkno+3
1524    3AE9  46        		ld	b,(hl)
1525    3AEA  2B        		dec	hl
1526    3AEB  4E        		ld	c,(hl)
1527    3AEC  C5        		push	bc
1528    3AED  2B        		dec	hl
1529    3AEE  46        		ld	b,(hl)
1530    3AEF  2B        		dec	hl
1531    3AF0  4E        		ld	c,(hl)
1532    3AF1  C5        		push	bc
1533    3AF2  218338    		ld	hl,L5403
1534    3AF5  CD0000    		call	_printf
1535    3AF8  F1        		pop	af
1536    3AF9  F1        		pop	af
1537                    	; 1256                  sddatprt(sdrdbuf);
1538    3AFA  213200    		ld	hl,_sdrdbuf
1539    3AFD  CD9224    		call	_sddatprt
1540                    	; 1257                  break;
1541    3B00  C37F39    		jp	L1214
1542                    	L1434:
1543                    	; 1258              case 's':
1544                    	; 1259                  printf(" s - print SD registers\n");
1545    3B03  219E38    		ld	hl,L5503
1546    3B06  CD0000    		call	_printf
1547                    	; 1260                  sdprtreg();
1548    3B09  CDB914    		call	_sdprtreg
1549                    	; 1261                  break;
1550    3B0C  C37F39    		jp	L1214
1551                    	L1534:
1552                    	; 1262              case 'l':
1553                    	; 1263                  printf(" l - print partition layout\n");
1554    3B0F  21B738    		ld	hl,L5603
1555    3B12  CD0000    		call	_printf
1556                    	; 1264                  sdmbrpart();
1557    3B15  CDF135    		call	_sdmbrpart
1558                    	; 1265                  break;
1559    3B18  C37F39    		jp	L1214
1560                    	L1634:
1561                    	; 1266              case 0x03: /* Ctrl-C */
1562                    	; 1267                  printf("reloading monitor from EPROM\n");
1563    3B1B  21D438    		ld	hl,L5703
1564    3B1E  CD0000    		call	_printf
1565                    	; 1268                  reload();
1566    3B21  CD0000    		call	_reload
1567                    	; 1269                  break; /* not really needed, will never get here */
1568    3B24  C37F39    		jp	L1214
1569                    	L1734:
1570                    	; 1270              default:
1571                    	; 1271                  printf(" command not implemented yet\n");
1572    3B27  21F238    		ld	hl,L5013
1573    3B2A  CD0000    		call	_printf
1574    3B2D  C37F39    		jp	L1214
1575                    	L1514:
1576                    	; 1272              }
1577                    	; 1273          }
1578    3B30  C37F39    		jp	L1214
1579                    	; 1274      }
1580                    	; 1275  
1581                    		.psect	_bss
1582                    	_curblkno:
1583                    		.byte	[4]
1584                    	_blkmult:
1585                    		.byte	[4]
1586                    	_sdver2:
1587                    		.byte	[2]
1588                    	_sdinitok:
1589                    		.byte	[2]
1590                    	_curblkok:
1591                    		.byte	[2]
1592                    	_csdreg:
1593                    		.byte	[16]
1594                    	_cidreg:
1595                    		.byte	[16]
1596                    	_ocrreg:
1597                    		.byte	[4]
1598                    	_sdrdbuf:
1599                    		.byte	[512]
1600                    		.public	_sdgpthdr
1601                    		.public	_curblkno
1602                    		.external	c.ulrsh
1603                    		.external	c.rets0
1604                    		.public	_CRC16_one
1605                    		.external	c.savs0
1606                    		.external	_getchar
1607                    		.external	c.lcmp
1608                    		.public	_cmd55
1609                    		.public	_curblkok
1610                    		.public	_cmd17
1611                    		.public	_cmd16
1612                    		.public	_cmd24
1613                    		.public	_sdver2
1614                    		.external	c.r1
1615                    		.external	_spideselect
1616                    		.public	_cmd10
1617                    		.external	c.r0
1618                    		.external	_getkline
1619                    		.external	c.jtab
1620                    		.external	_printf
1621                    		.external	_ledon
1622                    		.public	_sdmbrpart
1623                    		.external	_spiselect
1624                    		.external	_memcpy
1625                    		.public	_sdinit
1626                    		.public	_sdmbrentry
1627                    		.external	c.ladd
1628                    		.public	_sdwrite
1629                    		.public	_ocrreg
1630                    		.external	c.mvl
1631                    		.public	_prtguid
1632                    		.external	_sscanf
1633                    		.public	_blkmult
1634                    		.public	_acmd41
1635                    		.public	_csdreg
1636                    		.external	_reload
1637                    		.external	_putchar
1638                    		.public	_sdcommand
1639                    		.external	c.ursh
1640                    		.public	_sdread
1641                    		.external	_ledoff
1642                    		.external	c.rets
1643                    		.public	_CRC7_one
1644                    		.external	c.savs
1645                    		.public	_cidreg
1646                    		.public	_builddate
1647                    		.public	_cmd9
1648                    		.external	c.lmul
1649                    		.public	_cmd8
1650                    		.external	c.0mvf
1651                    		.public	_sdprtreg
1652                    		.public	_sdrdbuf
1653                    		.external	c.udiv
1654                    		.external	c.imul
1655                    		.external	c.lsub
1656                    		.public	_prtgptent
1657                    		.external	c.irsh
1658                    		.external	c.umod
1659                    		.public	_sddatprt
1660                    		.public	_main
1661                    		.external	c.llsh
1662                    		.public	_sdinitok
1663                    		.external	_spiio
1664                    		.public	_cmd0
1665                    		.external	c.ilsh
1666                    		.public	_cmd58
1667                    		.end
