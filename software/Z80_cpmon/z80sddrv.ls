   1                    	;    1  /*  z80sddrv.c Z80 SD card initialize and read/write routines.
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
  28                    	;   28  
  29                    	;   29  
  30                    	;   30  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
  31                    	;   31   * (The CRC7 byte in the tables below are only for information,
  32                    	;   32   * it is calculated by the sdcommand routine.)
  33                    	;   33   */
  34                    	;   34  
  35                    	;   35  /* CMD 0: GO_IDLE_STATE */
  36                    	;   36  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
  37                    		.psect	_text
  38                    	_cmd0:
  39    0000  40        		.byte	64
  40                    		.byte	[1]
  41                    		.byte	[1]
  42                    		.byte	[1]
  43                    		.byte	[1]
  44    0005  95        		.byte	149
  45                    	;   37  /* CMD 8: SEND_IF_COND */
  46                    	;   38  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
  47                    	_cmd8:
  48    0006  48        		.byte	72
  49                    		.byte	[1]
  50                    		.byte	[1]
  51    0009  01        		.byte	1
  52    000A  AA        		.byte	170
  53    000B  87        		.byte	135
  54                    	;   39  /* CMD 9: SEND_CSD */
  55                    	;   40  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
  56                    	_cmd9:
  57    000C  49        		.byte	73
  58                    		.byte	[1]
  59                    		.byte	[1]
  60                    		.byte	[1]
  61                    		.byte	[1]
  62    0011  AF        		.byte	175
  63                    	;   41  /* CMD 10: SEND_CID */
  64                    	;   42  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
  65                    	_cmd10:
  66    0012  4A        		.byte	74
  67                    		.byte	[1]
  68                    		.byte	[1]
  69                    		.byte	[1]
  70                    		.byte	[1]
  71    0017  1B        		.byte	27
  72                    	;   43  /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
  73                    	;   44  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
  74                    	_cmd16:
  75    0018  50        		.byte	80
  76                    		.byte	[1]
  77                    		.byte	[1]
  78    001B  02        		.byte	2
  79                    		.byte	[1]
  80    001D  15        		.byte	21
  81                    	;   45  /* CMD 55: APP_CMD followed by ACMD command */
  82                    	;   46  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
  83                    	_cmd55:
  84    001E  77        		.byte	119
  85                    		.byte	[1]
  86                    		.byte	[1]
  87                    		.byte	[1]
  88                    		.byte	[1]
  89    0023  65        		.byte	101
  90                    	;   47  /* CMD 58: READ_OCR */
  91                    	;   48  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
  92                    	_cmd58:
  93    0024  7A        		.byte	122
  94                    		.byte	[1]
  95                    		.byte	[1]
  96                    		.byte	[1]
  97                    		.byte	[1]
  98    0029  FD        		.byte	253
  99                    	;   49  /* ACMD 41: SEND_OP_COND */
 100                    	;   50  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
 101                    	_acmd41:
 102    002A  69        		.byte	105
 103    002B  40        		.byte	64
 104                    		.byte	[1]
 105    002D  01        		.byte	1
 106    002E  AA        		.byte	170
 107    002F  33        		.byte	51
 108                    	;   51  
 109                    	;   52  /* Buffers
 110                    	;   53   */
 111                    	;   54  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
 112                    	;   55  
 113                    	;   56  unsigned char ocrreg[4];     /* SD card OCR register */
 114                    	;   57  unsigned char cidreg[16];    /* SD card CID register */
 115                    	;   58  unsigned char csdreg[16];    /* SD card CSD register */
 116                    	;   59  
 117                    	;   60  /* Variables for the SD card
 118                    	;   61   */
 119                    	;   62  char *sdinitok;  /* SD card initialized and ready */
 120                    	;   63  char *byteblkadr;   /* block address multiplier flag */
 121                    	;   64  int curblkok;  /* if YES curblockno is read into buffer */
 122                    	;   65  int partdsk;   /* partition/disk number, 0 = disk A */
 123                    	;   66  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
 124                    	;   67  unsigned char curblkno[4];  /* block in buffer if curblkok == YES */
 125                    	;   68  
 126                    	;   69  /* Initialise SD card interface
 127                    	;   70   *
 128                    	;   71   * returns YES if ok and NO if not ok
 129                    	;   72   *
 130                    	;   73   * References:
 131                    	;   74   *   https://www.sdcard.org/downloads/pls/
 132                    	;   75   *      Physical Layer Simplified Specification version 8.0
 133                    	;   76   *
 134                    	;   77   * A nice flowchart how to initialize:
 135                    	;   78   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
 136                    	;   79   *
 137                    	;   80   */
 138                    	;   81  int sdinit()
 139                    	;   82      {
 140                    	_sdinit:
 141    0030  CD0000    		call	c.savs0
 142    0033  21E4FF    		ld	hl,65508
 143    0036  39        		add	hl,sp
 144    0037  F9        		ld	sp,hl
 145                    	;   83      int nbytes;  /* byte counter */
 146                    	;   84      int tries;   /* tries to get to active state or searching for data  */
 147                    	;   85      int wtloop;  /* timer loop when trying to enter active state */
 148                    	;   86      unsigned char cmdbuf[5];   /* buffer to build command in */
 149                    	;   87      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 150                    	;   88      unsigned char *statptr;    /* pointer to returned status from SD command */
 151                    	;   89      unsigned char crc;         /* crc register for CID and CSD */
 152                    	;   90      unsigned char rbyte;       /* recieved byte */
 153                    	;   91      unsigned char *prtptr;     /* for debug printing */
 154                    	;   92  
 155                    	;   93      ledon();
 156    0038  CD0000    		call	_ledon
 157                    	;   94      spideselect();
 158    003B  CD0000    		call	_spideselect
 159                    	;   95      *sdinitok = 0;
 160    003E  2A2E02    		ld	hl,(_sdinitok)
 161    0041  3600      		ld	(hl),0
 162                    	;   96  
 163                    	;   97      /* start to generate 9*8 clock pulses with not selected SD card */
 164                    	;   98      for (nbytes = 9; 0 < nbytes; nbytes--)
 165    0043  DD36F809  		ld	(ix-8),9
 166    0047  DD36F900  		ld	(ix-7),0
 167                    	L1:
 168    004B  97        		sub	a
 169    004C  DD96F8    		sub	(ix-8)
 170    004F  3E00      		ld	a,0
 171    0051  DD9EF9    		sbc	a,(ix-7)
 172    0054  F26C00    		jp	p,L11
 173                    	;   99          spiio(0xff);
 174    0057  21FF00    		ld	hl,255
 175    005A  CD0000    		call	_spiio
 176    005D  DD6EF8    		ld	l,(ix-8)
 177    0060  DD66F9    		ld	h,(ix-7)
 178    0063  2B        		dec	hl
 179    0064  DD75F8    		ld	(ix-8),l
 180    0067  DD74F9    		ld	(ix-7),h
 181    006A  18DF      		jr	L1
 182                    	L11:
 183                    	;  100      spiselect();
 184    006C  CD0000    		call	_spiselect
 185                    	;  101  
 186                    	;  102      /* CMD 0: GO_IDLE_STATE */
 187                    	;  103      for (tries = 0; tries < 10; tries++)
 188    006F  DD36F600  		ld	(ix-10),0
 189    0073  DD36F700  		ld	(ix-9),0
 190                    	L14:
 191    0077  DD7EF6    		ld	a,(ix-10)
 192    007A  D60A      		sub	10
 193    007C  DD7EF7    		ld	a,(ix-9)
 194    007F  DE00      		sbc	a,0
 195    0081  F20F01    		jp	p,L15
 196                    	;  104          {
 197                    	;  105          memcpy(cmdbuf, cmd0, 5);
 198    0084  210500    		ld	hl,5
 199    0087  E5        		push	hl
 200    0088  210000    		ld	hl,_cmd0
 201    008B  E5        		push	hl
 202    008C  DDE5      		push	ix
 203    008E  C1        		pop	bc
 204    008F  21EFFF    		ld	hl,65519
 205    0092  09        		add	hl,bc
 206    0093  CD0000    		call	_memcpy
 207    0096  F1        		pop	af
 208    0097  F1        		pop	af
 209                    	;  106          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 210    0098  210100    		ld	hl,1
 211    009B  E5        		push	hl
 212    009C  DDE5      		push	ix
 213    009E  C1        		pop	bc
 214    009F  21EAFF    		ld	hl,65514
 215    00A2  09        		add	hl,bc
 216    00A3  E5        		push	hl
 217    00A4  DDE5      		push	ix
 218    00A6  C1        		pop	bc
 219    00A7  21EFFF    		ld	hl,65519
 220    00AA  09        		add	hl,bc
 221    00AB  CD0000    		call	_sdcommand
 222    00AE  F1        		pop	af
 223    00AF  F1        		pop	af
 224    00B0  DD71E8    		ld	(ix-24),c
 225    00B3  DD70E9    		ld	(ix-23),b
 226                    	;  107          if (!statptr)
 227    00B6  DD7EE8    		ld	a,(ix-24)
 228    00B9  DDB6E9    		or	(ix-23)
 229    00BC  2017      		jr	nz,L101
 230                    	;  108              {
 231                    	;  109              spideselect();
 232    00BE  CD0000    		call	_spideselect
 233                    	;  110              ledoff();
 234    00C1  CD0000    		call	_ledoff
 235                    	;  111              return (NO);
 236    00C4  010000    		ld	bc,0
 237    00C7  C30000    		jp	c.rets0
 238                    	L16:
 239    00CA  DD34F6    		inc	(ix-10)
 240    00CD  2003      		jr	nz,L4
 241    00CF  DD34F7    		inc	(ix-9)
 242                    	L4:
 243    00D2  C37700    		jp	L14
 244                    	L101:
 245                    	;  112              }
 246                    	;  113          if (statptr[0] == 0x01)
 247    00D5  DD6EE8    		ld	l,(ix-24)
 248    00D8  DD66E9    		ld	h,(ix-23)
 249    00DB  7E        		ld	a,(hl)
 250    00DC  FE01      		cp	1
 251    00DE  282F      		jr	z,L15
 252                    	;  114              break;
 253                    	;  115          for (wtloop = 0; wtloop < tries * 10; wtloop++)
 254    00E0  DD36F400  		ld	(ix-12),0
 255    00E4  DD36F500  		ld	(ix-11),0
 256                    	L121:
 257    00E8  DD6EF6    		ld	l,(ix-10)
 258    00EB  DD66F7    		ld	h,(ix-9)
 259    00EE  4D        		ld	c,l
 260    00EF  44        		ld	b,h
 261    00F0  29        		add	hl,hl
 262    00F1  29        		add	hl,hl
 263    00F2  09        		add	hl,bc
 264    00F3  29        		add	hl,hl
 265    00F4  DD7EF4    		ld	a,(ix-12)
 266    00F7  95        		sub	l
 267    00F8  DD7EF5    		ld	a,(ix-11)
 268    00FB  9C        		sbc	a,h
 269    00FC  F2CA00    		jp	p,L16
 270                    	;  116              {
 271                    	;  117              /* wait loop, time increasing for each try */
 272                    	;  118              spiio(0xff);
 273    00FF  21FF00    		ld	hl,255
 274    0102  CD0000    		call	_spiio
 275                    	;  119              }
 276    0105  DD34F4    		inc	(ix-12)
 277    0108  2003      		jr	nz,L6
 278    010A  DD34F5    		inc	(ix-11)
 279                    	L6:
 280    010D  18D9      		jr	L121
 281                    	L15:
 282                    	;  120          }
 283                    	;  121  
 284                    	;  122      /* CMD 8: SEND_IF_COND */
 285                    	;  123      memcpy(cmdbuf, cmd8, 5);
 286    010F  210500    		ld	hl,5
 287    0112  E5        		push	hl
 288    0113  210600    		ld	hl,_cmd8
 289    0116  E5        		push	hl
 290    0117  DDE5      		push	ix
 291    0119  C1        		pop	bc
 292    011A  21EFFF    		ld	hl,65519
 293    011D  09        		add	hl,bc
 294    011E  CD0000    		call	_memcpy
 295    0121  F1        		pop	af
 296    0122  F1        		pop	af
 297                    	;  124      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
 298    0123  210500    		ld	hl,5
 299    0126  E5        		push	hl
 300    0127  DDE5      		push	ix
 301    0129  C1        		pop	bc
 302    012A  21EAFF    		ld	hl,65514
 303    012D  09        		add	hl,bc
 304    012E  E5        		push	hl
 305    012F  DDE5      		push	ix
 306    0131  C1        		pop	bc
 307    0132  21EFFF    		ld	hl,65519
 308    0135  09        		add	hl,bc
 309    0136  CD0000    		call	_sdcommand
 310    0139  F1        		pop	af
 311    013A  F1        		pop	af
 312    013B  DD71E8    		ld	(ix-24),c
 313    013E  DD70E9    		ld	(ix-23),b
 314                    	;  125      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
 315    0141  DD7EE8    		ld	a,(ix-24)
 316    0144  DDB6E9    		or	(ix-23)
 317    0147  2810      		jr	z,L171
 318    0149  DD6EE8    		ld	l,(ix-24)
 319    014C  DD66E9    		ld	h,(ix-23)
 320    014F  6E        		ld	l,(hl)
 321    0150  97        		sub	a
 322    0151  67        		ld	h,a
 323    0152  CB85      		res	0,l
 324    0154  7D        		ld	a,l
 325    0155  B4        		or	h
 326    0156  CABA01    		jp	z,L161
 327                    	L171:
 328                    	;  126          sdver2 = NO;
 329    0159  210000    		ld	hl,0
 330    015C  220200    		ld	(_sdver2),hl
 331                    	;  127      else
 332                    	L102:
 333                    	;  128          {
 334                    	;  129          sdver2 = YES;
 335                    	;  130          if (statptr[4] != 0xaa) /* but invalid echo back */
 336                    	;  131              {
 337                    	;  132              spideselect();
 338                    	;  133              ledoff();
 339                    	;  134              return (NO);
 340                    	;  135              }
 341                    	;  136          }
 342                    	;  137  
 343                    	;  138      /* CMD 55: APP_CMD followed by ACMD 41: SEND_OP_COND until status is 0x00 */
 344                    	;  139      for (tries = 0; tries < 20; tries++)
 345    015F  DD36F600  		ld	(ix-10),0
 346    0163  DD36F700  		ld	(ix-9),0
 347                    	L122:
 348    0167  DD7EF6    		ld	a,(ix-10)
 349    016A  D614      		sub	20
 350    016C  DD7EF7    		ld	a,(ix-9)
 351    016F  DE00      		sbc	a,0
 352    0171  F27702    		jp	p,L132
 353                    	;  140          {
 354                    	;  141          memcpy(cmdbuf, cmd55, 5);
 355    0174  210500    		ld	hl,5
 356    0177  E5        		push	hl
 357    0178  211E00    		ld	hl,_cmd55
 358    017B  E5        		push	hl
 359    017C  DDE5      		push	ix
 360    017E  C1        		pop	bc
 361    017F  21EFFF    		ld	hl,65519
 362    0182  09        		add	hl,bc
 363    0183  CD0000    		call	_memcpy
 364    0186  F1        		pop	af
 365    0187  F1        		pop	af
 366                    	;  142          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 367    0188  210100    		ld	hl,1
 368    018B  E5        		push	hl
 369    018C  DDE5      		push	ix
 370    018E  C1        		pop	bc
 371    018F  21EAFF    		ld	hl,65514
 372    0192  09        		add	hl,bc
 373    0193  E5        		push	hl
 374    0194  DDE5      		push	ix
 375    0196  C1        		pop	bc
 376    0197  21EFFF    		ld	hl,65519
 377    019A  09        		add	hl,bc
 378    019B  CD0000    		call	_sdcommand
 379    019E  F1        		pop	af
 380    019F  F1        		pop	af
 381    01A0  DD71E8    		ld	(ix-24),c
 382    01A3  DD70E9    		ld	(ix-23),b
 383                    	;  143          if (!statptr)
 384    01A6  DD7EE8    		ld	a,(ix-24)
 385    01A9  DDB6E9    		or	(ix-23)
 386    01AC  2039      		jr	nz,L162
 387                    	;  144              {
 388                    	;  145              spideselect();
 389    01AE  CD0000    		call	_spideselect
 390                    	;  146              ledoff();
 391    01B1  CD0000    		call	_ledoff
 392                    	;  147              return (NO);
 393    01B4  010000    		ld	bc,0
 394    01B7  C30000    		jp	c.rets0
 395                    	L161:
 396    01BA  210100    		ld	hl,1
 397    01BD  220200    		ld	(_sdver2),hl
 398    01C0  DD6EE8    		ld	l,(ix-24)
 399    01C3  DD66E9    		ld	h,(ix-23)
 400    01C6  23        		inc	hl
 401    01C7  23        		inc	hl
 402    01C8  23        		inc	hl
 403    01C9  23        		inc	hl
 404    01CA  7E        		ld	a,(hl)
 405    01CB  FEAA      		cp	170
 406    01CD  CA5F01    		jp	z,L102
 407    01D0  CD0000    		call	_spideselect
 408    01D3  CD0000    		call	_ledoff
 409    01D6  010000    		ld	bc,0
 410    01D9  C30000    		jp	c.rets0
 411                    	L142:
 412    01DC  DD34F6    		inc	(ix-10)
 413    01DF  2003      		jr	nz,L01
 414    01E1  DD34F7    		inc	(ix-9)
 415                    	L01:
 416    01E4  C36701    		jp	L122
 417                    	L162:
 418                    	;  148              }
 419                    	;  149          memcpy(cmdbuf, acmd41, 5);
 420    01E7  210500    		ld	hl,5
 421    01EA  E5        		push	hl
 422    01EB  212A00    		ld	hl,_acmd41
 423    01EE  E5        		push	hl
 424    01EF  DDE5      		push	ix
 425    01F1  C1        		pop	bc
 426    01F2  21EFFF    		ld	hl,65519
 427    01F5  09        		add	hl,bc
 428    01F6  CD0000    		call	_memcpy
 429    01F9  F1        		pop	af
 430    01FA  F1        		pop	af
 431                    	;  150          if (sdver2)
 432    01FB  2A0200    		ld	hl,(_sdver2)
 433    01FE  7C        		ld	a,h
 434    01FF  B5        		or	l
 435    0200  2806      		jr	z,L172
 436                    	;  151              cmdbuf[1] = 0x40;
 437    0202  DD36F040  		ld	(ix-16),64
 438                    	;  152          else
 439    0206  1804      		jr	L103
 440                    	L172:
 441                    	;  153              cmdbuf[1] = 0x00;
 442    0208  DD36F000  		ld	(ix-16),0
 443                    	L103:
 444                    	;  154          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 445    020C  210100    		ld	hl,1
 446    020F  E5        		push	hl
 447    0210  DDE5      		push	ix
 448    0212  C1        		pop	bc
 449    0213  21EAFF    		ld	hl,65514
 450    0216  09        		add	hl,bc
 451    0217  E5        		push	hl
 452    0218  DDE5      		push	ix
 453    021A  C1        		pop	bc
 454    021B  21EFFF    		ld	hl,65519
 455    021E  09        		add	hl,bc
 456    021F  CD0000    		call	_sdcommand
 457    0222  F1        		pop	af
 458    0223  F1        		pop	af
 459    0224  DD71E8    		ld	(ix-24),c
 460    0227  DD70E9    		ld	(ix-23),b
 461                    	;  155          if (!statptr)
 462    022A  DD7EE8    		ld	a,(ix-24)
 463    022D  DDB6E9    		or	(ix-23)
 464    0230  200C      		jr	nz,L113
 465                    	;  156              {
 466                    	;  157              spideselect();
 467    0232  CD0000    		call	_spideselect
 468                    	;  158              ledoff();
 469    0235  CD0000    		call	_ledoff
 470                    	;  159              return (NO);
 471    0238  010000    		ld	bc,0
 472    023B  C30000    		jp	c.rets0
 473                    	L113:
 474                    	;  160              }
 475                    	;  161          if (statptr[0] == 0x00) /* now the SD card is ready */
 476    023E  DD6EE8    		ld	l,(ix-24)
 477    0241  DD66E9    		ld	h,(ix-23)
 478    0244  7E        		ld	a,(hl)
 479    0245  B7        		or	a
 480    0246  282F      		jr	z,L132
 481                    	;  162              {
 482                    	;  163              break;
 483                    	;  164              }
 484                    	;  165          for (wtloop = 0; wtloop < tries * 10; wtloop++)
 485    0248  DD36F400  		ld	(ix-12),0
 486    024C  DD36F500  		ld	(ix-11),0
 487                    	L133:
 488    0250  DD6EF6    		ld	l,(ix-10)
 489    0253  DD66F7    		ld	h,(ix-9)
 490    0256  4D        		ld	c,l
 491    0257  44        		ld	b,h
 492    0258  29        		add	hl,hl
 493    0259  29        		add	hl,hl
 494    025A  09        		add	hl,bc
 495    025B  29        		add	hl,hl
 496    025C  DD7EF4    		ld	a,(ix-12)
 497    025F  95        		sub	l
 498    0260  DD7EF5    		ld	a,(ix-11)
 499    0263  9C        		sbc	a,h
 500    0264  F2DC01    		jp	p,L142
 501                    	;  166              {
 502                    	;  167              /* wait loop, time increasing for each try */
 503                    	;  168              spiio(0xff);
 504    0267  21FF00    		ld	hl,255
 505    026A  CD0000    		call	_spiio
 506                    	;  169              }
 507    026D  DD34F4    		inc	(ix-12)
 508    0270  2003      		jr	nz,L21
 509    0272  DD34F5    		inc	(ix-11)
 510                    	L21:
 511    0275  18D9      		jr	L133
 512                    	L132:
 513                    	;  170          }
 514                    	;  171  
 515                    	;  172      /* CMD 58: READ_OCR */
 516                    	;  173      /* According to the flow chart this should not work
 517                    	;  174         for SD ver. 1 but the response is ok anyway
 518                    	;  175         all tested SD cards  */
 519                    	;  176      memcpy(cmdbuf, cmd58, 5);
 520    0277  210500    		ld	hl,5
 521    027A  E5        		push	hl
 522    027B  212400    		ld	hl,_cmd58
 523    027E  E5        		push	hl
 524    027F  DDE5      		push	ix
 525    0281  C1        		pop	bc
 526    0282  21EFFF    		ld	hl,65519
 527    0285  09        		add	hl,bc
 528    0286  CD0000    		call	_memcpy
 529    0289  F1        		pop	af
 530    028A  F1        		pop	af
 531                    	;  177      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
 532    028B  210500    		ld	hl,5
 533    028E  E5        		push	hl
 534    028F  DDE5      		push	ix
 535    0291  C1        		pop	bc
 536    0292  21EAFF    		ld	hl,65514
 537    0295  09        		add	hl,bc
 538    0296  E5        		push	hl
 539    0297  DDE5      		push	ix
 540    0299  C1        		pop	bc
 541    029A  21EFFF    		ld	hl,65519
 542    029D  09        		add	hl,bc
 543    029E  CD0000    		call	_sdcommand
 544    02A1  F1        		pop	af
 545    02A2  F1        		pop	af
 546    02A3  DD71E8    		ld	(ix-24),c
 547    02A6  DD70E9    		ld	(ix-23),b
 548                    	;  178      if (!statptr)
 549    02A9  DD7EE8    		ld	a,(ix-24)
 550    02AC  DDB6E9    		or	(ix-23)
 551    02AF  200C      		jr	nz,L173
 552                    	;  179          {
 553                    	;  180          spideselect();
 554    02B1  CD0000    		call	_spideselect
 555                    	;  181          ledoff();
 556    02B4  CD0000    		call	_ledoff
 557                    	;  182          return (NO);
 558    02B7  010000    		ld	bc,0
 559    02BA  C30000    		jp	c.rets0
 560                    	L173:
 561                    	;  183          }
 562                    	;  184      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
 563    02BD  210400    		ld	hl,4
 564    02C0  E5        		push	hl
 565    02C1  DD6EE8    		ld	l,(ix-24)
 566    02C4  DD66E9    		ld	h,(ix-23)
 567    02C7  23        		inc	hl
 568    02C8  E5        		push	hl
 569    02C9  212A00    		ld	hl,_ocrreg
 570    02CC  CD0000    		call	_memcpy
 571    02CF  F1        		pop	af
 572    02D0  F1        		pop	af
 573                    	;  185      *byteblkadr = 0; /* assume block address */
 574    02D1  2A3002    		ld	hl,(_byteblkadr)
 575    02D4  3600      		ld	(hl),0
 576                    	;  186      if (ocrreg[0] & 0x80)
 577    02D6  3A2A00    		ld	a,(_ocrreg)
 578    02D9  CB7F      		bit	7,a
 579    02DB  6F        		ld	l,a
 580    02DC  280D      		jr	z,L104
 581                    	;  187          {
 582                    	;  188          /* SD Ver.2+ */
 583                    	;  189          if (!(ocrreg[0] & 0x40))
 584    02DE  3A2A00    		ld	a,(_ocrreg)
 585    02E1  CB77      		bit	6,a
 586    02E3  6F        		ld	l,a
 587    02E4  2005      		jr	nz,L104
 588                    	;  190              {
 589                    	;  191              /* SD Ver.2+, Byte address */
 590                    	;  192              *byteblkadr = 1;
 591    02E6  2A3002    		ld	hl,(_byteblkadr)
 592    02E9  3601      		ld	(hl),1
 593                    	L104:
 594                    	;  193              }
 595                    	;  194          }
 596                    	;  195  
 597                    	;  196      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
 598                    	;  197      if (*byteblkadr)
 599    02EB  2A3002    		ld	hl,(_byteblkadr)
 600    02EE  7E        		ld	a,(hl)
 601    02EF  B7        		or	a
 602    02F0  2846      		jr	z,L124
 603                    	;  198          {
 604                    	;  199          memcpy(cmdbuf, cmd16, 5);
 605    02F2  210500    		ld	hl,5
 606    02F5  E5        		push	hl
 607    02F6  211800    		ld	hl,_cmd16
 608    02F9  E5        		push	hl
 609    02FA  DDE5      		push	ix
 610    02FC  C1        		pop	bc
 611    02FD  21EFFF    		ld	hl,65519
 612    0300  09        		add	hl,bc
 613    0301  CD0000    		call	_memcpy
 614    0304  F1        		pop	af
 615    0305  F1        		pop	af
 616                    	;  200          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 617    0306  210100    		ld	hl,1
 618    0309  E5        		push	hl
 619    030A  DDE5      		push	ix
 620    030C  C1        		pop	bc
 621    030D  21EAFF    		ld	hl,65514
 622    0310  09        		add	hl,bc
 623    0311  E5        		push	hl
 624    0312  DDE5      		push	ix
 625    0314  C1        		pop	bc
 626    0315  21EFFF    		ld	hl,65519
 627    0318  09        		add	hl,bc
 628    0319  CD0000    		call	_sdcommand
 629    031C  F1        		pop	af
 630    031D  F1        		pop	af
 631    031E  DD71E8    		ld	(ix-24),c
 632    0321  DD70E9    		ld	(ix-23),b
 633                    	;  201          if (!statptr)
 634    0324  DD7EE8    		ld	a,(ix-24)
 635    0327  DDB6E9    		or	(ix-23)
 636    032A  200C      		jr	nz,L124
 637                    	;  202              {
 638                    	;  203              spideselect();
 639    032C  CD0000    		call	_spideselect
 640                    	;  204              ledoff();
 641    032F  CD0000    		call	_ledoff
 642                    	;  205              return (NO);
 643    0332  010000    		ld	bc,0
 644    0335  C30000    		jp	c.rets0
 645                    	L124:
 646                    	;  206              }
 647                    	;  207          }
 648                    	;  208      /* Register information:
 649                    	;  209       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
 650                    	;  210       */
 651                    	;  211  
 652                    	;  212      /* CMD 10: SEND_CID */
 653                    	;  213      memcpy(cmdbuf, cmd10, 5);
 654    0338  210500    		ld	hl,5
 655    033B  E5        		push	hl
 656    033C  211200    		ld	hl,_cmd10
 657    033F  E5        		push	hl
 658    0340  DDE5      		push	ix
 659    0342  C1        		pop	bc
 660    0343  21EFFF    		ld	hl,65519
 661    0346  09        		add	hl,bc
 662    0347  CD0000    		call	_memcpy
 663    034A  F1        		pop	af
 664    034B  F1        		pop	af
 665                    	;  214      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 666    034C  210100    		ld	hl,1
 667    034F  E5        		push	hl
 668    0350  DDE5      		push	ix
 669    0352  C1        		pop	bc
 670    0353  21EAFF    		ld	hl,65514
 671    0356  09        		add	hl,bc
 672    0357  E5        		push	hl
 673    0358  DDE5      		push	ix
 674    035A  C1        		pop	bc
 675    035B  21EFFF    		ld	hl,65519
 676    035E  09        		add	hl,bc
 677    035F  CD0000    		call	_sdcommand
 678    0362  F1        		pop	af
 679    0363  F1        		pop	af
 680    0364  DD71E8    		ld	(ix-24),c
 681    0367  DD70E9    		ld	(ix-23),b
 682                    	;  215      if (!statptr)
 683    036A  DD7EE8    		ld	a,(ix-24)
 684    036D  DDB6E9    		or	(ix-23)
 685    0370  200C      		jr	nz,L144
 686                    	;  216          {
 687                    	;  217          spideselect();
 688    0372  CD0000    		call	_spideselect
 689                    	;  218          ledoff();
 690    0375  CD0000    		call	_ledoff
 691                    	;  219          return (NO);
 692    0378  010000    		ld	bc,0
 693    037B  C30000    		jp	c.rets0
 694                    	L144:
 695                    	;  220          }
 696                    	;  221      /* looking for 0xfe that is the byte before data */
 697                    	;  222      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
 698    037E  DD36F614  		ld	(ix-10),20
 699    0382  DD36F700  		ld	(ix-9),0
 700                    	L154:
 701    0386  97        		sub	a
 702    0387  DD96F6    		sub	(ix-10)
 703    038A  3E00      		ld	a,0
 704    038C  DD9EF7    		sbc	a,(ix-9)
 705    038F  F2B103    		jp	p,L164
 706    0392  21FF00    		ld	hl,255
 707    0395  CD0000    		call	_spiio
 708    0398  79        		ld	a,c
 709    0399  FEFE      		cp	254
 710    039B  2003      		jr	nz,L41
 711    039D  78        		ld	a,b
 712    039E  FE00      		cp	0
 713                    	L41:
 714    03A0  280F      		jr	z,L164
 715                    	L174:
 716    03A2  DD6EF6    		ld	l,(ix-10)
 717    03A5  DD66F7    		ld	h,(ix-9)
 718    03A8  2B        		dec	hl
 719    03A9  DD75F6    		ld	(ix-10),l
 720    03AC  DD74F7    		ld	(ix-9),h
 721    03AF  18D5      		jr	L154
 722                    	L164:
 723                    	;  223          ;
 724                    	;  224      if (tries == 0) /* tried too many times */
 725    03B1  DD7EF6    		ld	a,(ix-10)
 726    03B4  DDB6F7    		or	(ix-9)
 727    03B7  200C      		jr	nz,L115
 728                    	;  225          {
 729                    	;  226          spideselect();
 730    03B9  CD0000    		call	_spideselect
 731                    	;  227          ledoff();
 732    03BC  CD0000    		call	_ledoff
 733                    	;  228          return (NO);
 734    03BF  010000    		ld	bc,0
 735    03C2  C30000    		jp	c.rets0
 736                    	L115:
 737                    	;  229          }
 738                    	;  230      else
 739                    	;  231          {
 740                    	;  232          crc = 0;
 741    03C5  DD36E700  		ld	(ix-25),0
 742                    	;  233          for (nbytes = 0; nbytes < 15; nbytes++)
 743    03C9  DD36F800  		ld	(ix-8),0
 744    03CD  DD36F900  		ld	(ix-7),0
 745                    	L135:
 746    03D1  DD7EF8    		ld	a,(ix-8)
 747    03D4  D60F      		sub	15
 748    03D6  DD7EF9    		ld	a,(ix-7)
 749    03D9  DE00      		sbc	a,0
 750    03DB  F21104    		jp	p,L145
 751                    	;  234              {
 752                    	;  235              rbyte = spiio(0xff);
 753    03DE  21FF00    		ld	hl,255
 754    03E1  CD0000    		call	_spiio
 755    03E4  DD71E6    		ld	(ix-26),c
 756                    	;  236              cidreg[nbytes] = rbyte;
 757    03E7  211A00    		ld	hl,_cidreg
 758    03EA  DD4EF8    		ld	c,(ix-8)
 759    03ED  DD46F9    		ld	b,(ix-7)
 760    03F0  09        		add	hl,bc
 761    03F1  DD7EE6    		ld	a,(ix-26)
 762    03F4  77        		ld	(hl),a
 763                    	;  237              crc = CRC7_one(crc, rbyte);
 764    03F5  DD4EE6    		ld	c,(ix-26)
 765    03F8  97        		sub	a
 766    03F9  47        		ld	b,a
 767    03FA  C5        		push	bc
 768    03FB  DD6EE7    		ld	l,(ix-25)
 769    03FE  97        		sub	a
 770    03FF  67        		ld	h,a
 771    0400  CD0000    		call	_CRC7_one
 772    0403  F1        		pop	af
 773    0404  DD71E7    		ld	(ix-25),c
 774                    	;  238              }
 775    0407  DD34F8    		inc	(ix-8)
 776    040A  2003      		jr	nz,L61
 777    040C  DD34F9    		inc	(ix-7)
 778                    	L61:
 779    040F  18C0      		jr	L135
 780                    	L145:
 781                    	;  239          cidreg[15] = spiio(0xff);
 782    0411  21FF00    		ld	hl,255
 783    0414  CD0000    		call	_spiio
 784    0417  79        		ld	a,c
 785    0418  322900    		ld	(_cidreg+15),a
 786                    	;  240          crc |= 0x01;
 787    041B  DDCBE7C6  		set	0,(ix-25)
 788                    	;  241          /* some SD cards need additional clock pulses */
 789                    	;  242          for (nbytes = 9; 0 < nbytes; nbytes--)
 790    041F  DD36F809  		ld	(ix-8),9
 791    0423  DD36F900  		ld	(ix-7),0
 792                    	L175:
 793    0427  97        		sub	a
 794    0428  DD96F8    		sub	(ix-8)
 795    042B  3E00      		ld	a,0
 796    042D  DD9EF9    		sbc	a,(ix-7)
 797    0430  F24804    		jp	p,L125
 798                    	;  243              spiio(0xff);
 799    0433  21FF00    		ld	hl,255
 800    0436  CD0000    		call	_spiio
 801    0439  DD6EF8    		ld	l,(ix-8)
 802    043C  DD66F9    		ld	h,(ix-7)
 803    043F  2B        		dec	hl
 804    0440  DD75F8    		ld	(ix-8),l
 805    0443  DD74F9    		ld	(ix-7),h
 806    0446  18DF      		jr	L175
 807                    	L125:
 808                    	;  244          }
 809                    	;  245  
 810                    	;  246      /* CMD 9: SEND_CSD */
 811                    	;  247      memcpy(cmdbuf, cmd9, 5);
 812    0448  210500    		ld	hl,5
 813    044B  E5        		push	hl
 814    044C  210C00    		ld	hl,_cmd9
 815    044F  E5        		push	hl
 816    0450  DDE5      		push	ix
 817    0452  C1        		pop	bc
 818    0453  21EFFF    		ld	hl,65519
 819    0456  09        		add	hl,bc
 820    0457  CD0000    		call	_memcpy
 821    045A  F1        		pop	af
 822    045B  F1        		pop	af
 823                    	;  248      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 824    045C  210100    		ld	hl,1
 825    045F  E5        		push	hl
 826    0460  DDE5      		push	ix
 827    0462  C1        		pop	bc
 828    0463  21EAFF    		ld	hl,65514
 829    0466  09        		add	hl,bc
 830    0467  E5        		push	hl
 831    0468  DDE5      		push	ix
 832    046A  C1        		pop	bc
 833    046B  21EFFF    		ld	hl,65519
 834    046E  09        		add	hl,bc
 835    046F  CD0000    		call	_sdcommand
 836    0472  F1        		pop	af
 837    0473  F1        		pop	af
 838    0474  DD71E8    		ld	(ix-24),c
 839    0477  DD70E9    		ld	(ix-23),b
 840                    	;  249      if (!statptr)
 841    047A  DD7EE8    		ld	a,(ix-24)
 842    047D  DDB6E9    		or	(ix-23)
 843    0480  200C      		jr	nz,L136
 844                    	;  250          {
 845                    	;  251          spideselect();
 846    0482  CD0000    		call	_spideselect
 847                    	;  252          ledoff();
 848    0485  CD0000    		call	_ledoff
 849                    	;  253          return (NO);
 850    0488  010000    		ld	bc,0
 851    048B  C30000    		jp	c.rets0
 852                    	L136:
 853                    	;  254          }
 854                    	;  255      /* looking for 0xfe that is the byte before data */
 855                    	;  256      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
 856    048E  DD36F614  		ld	(ix-10),20
 857    0492  DD36F700  		ld	(ix-9),0
 858                    	L146:
 859    0496  97        		sub	a
 860    0497  DD96F6    		sub	(ix-10)
 861    049A  3E00      		ld	a,0
 862    049C  DD9EF7    		sbc	a,(ix-9)
 863    049F  F2C104    		jp	p,L156
 864    04A2  21FF00    		ld	hl,255
 865    04A5  CD0000    		call	_spiio
 866    04A8  79        		ld	a,c
 867    04A9  FEFE      		cp	254
 868    04AB  2003      		jr	nz,L02
 869    04AD  78        		ld	a,b
 870    04AE  FE00      		cp	0
 871                    	L02:
 872    04B0  280F      		jr	z,L156
 873                    	L166:
 874    04B2  DD6EF6    		ld	l,(ix-10)
 875    04B5  DD66F7    		ld	h,(ix-9)
 876    04B8  2B        		dec	hl
 877    04B9  DD75F6    		ld	(ix-10),l
 878    04BC  DD74F7    		ld	(ix-9),h
 879    04BF  18D5      		jr	L146
 880                    	L156:
 881                    	;  257          ;
 882                    	;  258      if (tries == 0) /* tried too many times */
 883    04C1  DD7EF6    		ld	a,(ix-10)
 884    04C4  DDB6F7    		or	(ix-9)
 885    04C7  2006      		jr	nz,L107
 886                    	;  259          return (NO);
 887    04C9  010000    		ld	bc,0
 888    04CC  C30000    		jp	c.rets0
 889                    	L107:
 890                    	;  260      else
 891                    	;  261          {
 892                    	;  262          crc = 0;
 893    04CF  DD36E700  		ld	(ix-25),0
 894                    	;  263          for (nbytes = 0; nbytes < 15; nbytes++)
 895    04D3  DD36F800  		ld	(ix-8),0
 896    04D7  DD36F900  		ld	(ix-7),0
 897                    	L127:
 898    04DB  DD7EF8    		ld	a,(ix-8)
 899    04DE  D60F      		sub	15
 900    04E0  DD7EF9    		ld	a,(ix-7)
 901    04E3  DE00      		sbc	a,0
 902    04E5  F21B05    		jp	p,L137
 903                    	;  264              {
 904                    	;  265              rbyte = spiio(0xff);
 905    04E8  21FF00    		ld	hl,255
 906    04EB  CD0000    		call	_spiio
 907    04EE  DD71E6    		ld	(ix-26),c
 908                    	;  266              csdreg[nbytes] = rbyte;
 909    04F1  210A00    		ld	hl,_csdreg
 910    04F4  DD4EF8    		ld	c,(ix-8)
 911    04F7  DD46F9    		ld	b,(ix-7)
 912    04FA  09        		add	hl,bc
 913    04FB  DD7EE6    		ld	a,(ix-26)
 914    04FE  77        		ld	(hl),a
 915                    	;  267              crc = CRC7_one(crc, rbyte);
 916    04FF  DD4EE6    		ld	c,(ix-26)
 917    0502  97        		sub	a
 918    0503  47        		ld	b,a
 919    0504  C5        		push	bc
 920    0505  DD6EE7    		ld	l,(ix-25)
 921    0508  97        		sub	a
 922    0509  67        		ld	h,a
 923    050A  CD0000    		call	_CRC7_one
 924    050D  F1        		pop	af
 925    050E  DD71E7    		ld	(ix-25),c
 926                    	;  268              }
 927    0511  DD34F8    		inc	(ix-8)
 928    0514  2003      		jr	nz,L22
 929    0516  DD34F9    		inc	(ix-7)
 930                    	L22:
 931    0519  18C0      		jr	L127
 932                    	L137:
 933                    	;  269          csdreg[15] = spiio(0xff);
 934    051B  21FF00    		ld	hl,255
 935    051E  CD0000    		call	_spiio
 936    0521  79        		ld	a,c
 937    0522  321900    		ld	(_csdreg+15),a
 938                    	;  270          crc |= 0x01;
 939    0525  DDCBE7C6  		set	0,(ix-25)
 940                    	;  271          /* some SD cards need additional clock pulses */
 941                    	;  272          for (nbytes = 9; 0 < nbytes; nbytes--)
 942    0529  DD36F809  		ld	(ix-8),9
 943    052D  DD36F900  		ld	(ix-7),0
 944                    	L167:
 945    0531  97        		sub	a
 946    0532  DD96F8    		sub	(ix-8)
 947    0535  3E00      		ld	a,0
 948    0537  DD9EF9    		sbc	a,(ix-7)
 949    053A  F25205    		jp	p,L117
 950                    	;  273              spiio(0xff);
 951    053D  21FF00    		ld	hl,255
 952    0540  CD0000    		call	_spiio
 953    0543  DD6EF8    		ld	l,(ix-8)
 954    0546  DD66F9    		ld	h,(ix-7)
 955    0549  2B        		dec	hl
 956    054A  DD75F8    		ld	(ix-8),l
 957    054D  DD74F9    		ld	(ix-7),h
 958    0550  18DF      		jr	L167
 959                    	L117:
 960                    	;  274          }
 961                    	;  275  
 962                    	;  276      for (nbytes = 9; 0 < nbytes; nbytes--)
 963    0552  DD36F809  		ld	(ix-8),9
 964    0556  DD36F900  		ld	(ix-7),0
 965                    	L1201:
 966    055A  97        		sub	a
 967    055B  DD96F8    		sub	(ix-8)
 968    055E  3E00      		ld	a,0
 969    0560  DD9EF9    		sbc	a,(ix-7)
 970    0563  F27B05    		jp	p,L1301
 971                    	;  277          spiio(0xff);
 972    0566  21FF00    		ld	hl,255
 973    0569  CD0000    		call	_spiio
 974    056C  DD6EF8    		ld	l,(ix-8)
 975    056F  DD66F9    		ld	h,(ix-7)
 976    0572  2B        		dec	hl
 977    0573  DD75F8    		ld	(ix-8),l
 978    0576  DD74F9    		ld	(ix-7),h
 979    0579  18DF      		jr	L1201
 980                    	L1301:
 981                    	;  278  
 982                    	;  279      *sdinitok = 1;
 983    057B  2A2E02    		ld	hl,(_sdinitok)
 984    057E  3601      		ld	(hl),1
 985                    	;  280  
 986                    	;  281      spideselect();
 987    0580  CD0000    		call	_spideselect
 988                    	;  282      ledoff();
 989    0583  CD0000    		call	_ledoff
 990                    	;  283  
 991                    	;  284      return (YES);
 992    0586  010100    		ld	bc,1
 993    0589  C30000    		jp	c.rets0
 994                    	;  285      }
 995                    	;  286  
 996                    		.psect	_bss
 997                    	_partdsk:
 998                    		.byte	[2]
 999                    	_sdver2:
1000                    		.byte	[2]
1001                    	_curblkok:
1002                    		.byte	[2]
1003                    	_curblkno:
1004                    		.byte	[4]
1005                    	_csdreg:
1006                    		.byte	[16]
1007                    	_cidreg:
1008                    		.byte	[16]
1009                    	_ocrreg:
1010                    		.byte	[4]
1011                    	_sdrdbuf:
1012                    		.byte	[512]
1013                    	_sdinitok:
1014                    		.byte	[2]
1015                    	_byteblkadr:
1016                    		.byte	[2]
1017                    		.public	_curblkno
1018                    		.external	c.rets0
1019                    		.external	c.savs0
1020                    		.public	_cmd55
1021                    		.public	_curblkok
1022                    		.public	_cmd16
1023                    		.public	_sdver2
1024                    		.external	_spideselect
1025                    		.public	_cmd10
1026                    		.external	_ledon
1027                    		.external	_spiselect
1028                    		.external	_memcpy
1029                    		.public	_sdinit
1030                    		.public	_ocrreg
1031                    		.public	_acmd41
1032                    		.public	_partdsk
1033                    		.public	_csdreg
1034                    		.external	_sdcommand
1035                    		.external	_CRC7_one
1036                    		.external	_ledoff
1037                    		.public	_cidreg
1038                    		.public	_cmd9
1039                    		.public	_cmd8
1040                    		.public	_sdrdbuf
1041                    		.public	_sdinitok
1042                    		.public	_byteblkadr
1043                    		.external	_spiio
1044                    		.public	_cmd0
1045                    		.public	_cmd58
1046                    		.end
