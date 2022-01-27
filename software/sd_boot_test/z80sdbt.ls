   1                    	;    1  /*  z80sdbt.c Boot and test program trying to make a unified prog.
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
  39    000F  37        		.byte	55
  40    0010  20        		.byte	32
  41    0011  31        		.byte	49
  42    0012  34        		.byte	52
  43    0013  3A        		.byte	58
  44    0014  35        		.byte	53
  45    0015  37        		.byte	55
  46    0016  00        		.byte	0
  47                    	;   22  
  48                    	;   23  #define PRGNAME "\nz80sdbt "
  49                    	;   24  #define VERSION "version 0.7, "
  50                    	;   25  /* This code should be cleaned up when
  51                    	;   26     remaining functions are implemented
  52                    	;   27   */
  53                    	;   28  #define PARTZRO 0  /* Empty partition entry */
  54                    	;   29  #define PARTMBR 1  /* MBR partition */
  55                    	;   30  #define PARTEBR 2  /* EBR logical partition */
  56                    	;   31  #define PARTGPT 3  /* GPT partition */
  57                    	;   32  #define EBRCONT 20 /* EBR container partition in MBR */
  58                    	;   33  
  59                    	;   34  struct partentry
  60                    	;   35      {
  61                    	;   36      char partype;
  62                    	;   37      char dskletter;
  63                    	;   38      int bootable;
  64                    	;   39      unsigned long dskstart;
  65                    	;   40      unsigned long dskend;
  66                    	;   41      unsigned long dsksize;
  67                    	;   42      unsigned char dsktype[16];
  68                    	;   43      } dskmap[16];
  69                    	;   44  
  70                    	;   45  unsigned char dsksign[4]; /* MBR/EBR disk signature */
  71                    	;   46  
  72                    	;   47  /* Function prototypes */
  73                    	;   48  void sdmbrpart(unsigned long);
  74                    	;   49  
  75                    	;   50  /* Response length in bytes
  76                    	;   51   */
  77                    	;   52  #define R1_LEN 1
  78                    	;   53  #define R3_LEN 5
  79                    	;   54  #define R7_LEN 5
  80                    	;   55  
  81                    	;   56  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
  82                    	;   57   * (The CRC7 byte in the tables below are only for information,
  83                    	;   58   * it is calculated by the sdcommand routine.)
  84                    	;   59   */
  85                    	;   60  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
  86                    	_cmd0:
  87    0017  40        		.byte	64
  88                    		.byte	[1]
  89                    		.byte	[1]
  90                    		.byte	[1]
  91                    		.byte	[1]
  92    001C  95        		.byte	149
  93                    	;   61  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
  94                    	_cmd8:
  95    001D  48        		.byte	72
  96                    		.byte	[1]
  97                    		.byte	[1]
  98    0020  01        		.byte	1
  99    0021  AA        		.byte	170
 100    0022  87        		.byte	135
 101                    	;   62  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
 102                    	_cmd9:
 103    0023  49        		.byte	73
 104                    		.byte	[1]
 105                    		.byte	[1]
 106                    		.byte	[1]
 107                    		.byte	[1]
 108    0028  AF        		.byte	175
 109                    	;   63  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
 110                    	_cmd10:
 111    0029  4A        		.byte	74
 112                    		.byte	[1]
 113                    		.byte	[1]
 114                    		.byte	[1]
 115                    		.byte	[1]
 116    002E  1B        		.byte	27
 117                    	;   64  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
 118                    	_cmd16:
 119    002F  50        		.byte	80
 120                    		.byte	[1]
 121                    		.byte	[1]
 122    0032  02        		.byte	2
 123                    		.byte	[1]
 124    0034  15        		.byte	21
 125                    	;   65  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
 126                    	_cmd17:
 127    0035  51        		.byte	81
 128                    		.byte	[1]
 129                    		.byte	[1]
 130                    		.byte	[1]
 131                    		.byte	[1]
 132    003A  55        		.byte	85
 133                    	;   66  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
 134                    	_cmd24:
 135    003B  58        		.byte	88
 136                    		.byte	[1]
 137                    		.byte	[1]
 138                    		.byte	[1]
 139                    		.byte	[1]
 140    0040  6F        		.byte	111
 141                    	;   67  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
 142                    	_cmd55:
 143    0041  77        		.byte	119
 144                    		.byte	[1]
 145                    		.byte	[1]
 146                    		.byte	[1]
 147                    		.byte	[1]
 148    0046  65        		.byte	101
 149                    	;   68  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
 150                    	_cmd58:
 151    0047  7A        		.byte	122
 152                    		.byte	[1]
 153                    		.byte	[1]
 154                    		.byte	[1]
 155                    		.byte	[1]
 156    004C  FD        		.byte	253
 157                    	;   69  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
 158                    	_acmd41:
 159    004D  69        		.byte	105
 160    004E  40        		.byte	64
 161                    		.byte	[1]
 162    0050  01        		.byte	1
 163    0051  AA        		.byte	170
 164    0052  33        		.byte	51
 165                    	;   70  
 166                    	;   71  /* Partition identifiers
 167                    	;   72   */
 168                    	;   73  /* For GPT I have decided that a CP/M partition
 169                    	;   74   * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
 170                    	;   75   */
 171                    	;   76  const unsigned char gptcpm[] =
 172                    	;   77      {
 173                    	_gptcpm:
 174                    	;   78      0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
 175    0053  FD        		.byte	253
 176    0054  76        		.byte	118
 177    0055  71        		.byte	113
 178    0056  AC        		.byte	172
 179    0057  55        		.byte	85
 180    0058  8D        		.byte	141
 181    0059  FF        		.byte	255
 182    005A  4F        		.byte	79
 183                    	;   79      0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
 184    005B  86        		.byte	134
 185    005C  A5        		.byte	165
 186    005D  A3        		.byte	163
 187    005E  6D        		.byte	109
 188    005F  63        		.byte	99
 189    0060  68        		.byte	104
 190    0061  D0        		.byte	208
 191                    	;   80      };
 192    0062  CB        		.byte	203
 193                    	;   81  /* For MBR/EBR the partition type for CP/M is 0x52
 194                    	;   82   * according to: https://en.wikipedia.org/wiki/Partition_type
 195                    	;   83   */
 196                    	;   84  const unsigned char mbrcpm = 0x52;    /* CP/M partition */
 197                    	_mbrcpm:
 198    0063  52        		.byte	82
 199                    	;   85  const unsigned char mbrexcode = 0x5f; /* Z80 executable code partition */
 200                    	_mbrexcode:
 201    0064  5F        		.byte	95
 202                    	;   86  /* has a special format that */
 203                    	;   87  /* includes number of sectors to */
 204                    	;   88  /* load and a signature, TBD */
 205                    	;   89  
 206                    	;   90  /* Buffers
 207                    	;   91   */
 208                    	;   92  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
 209                    	;   93  
 210                    	;   94  unsigned char ocrreg[4];     /* SD card OCR register */
 211                    	;   95  unsigned char cidreg[16];    /* SD card CID register */
 212                    	;   96  unsigned char csdreg[16];    /* SD card CSD register */
 213                    	;   97  unsigned long ebrrecs[4];    /* detected EBR records to process */
 214                    	;   98  int ebrrecidx; /* how many EBR records that are populated */
 215                    	;   99  unsigned long ebrnext; /* next chained ebr record */
 216                    	;  100  
 217                    	;  101  /* Variables
 218                    	;  102   */
 219                    	;  103  int curblkok;  /* if YES curblockno is read into buffer */
 220                    	;  104  int partdsk;   /* partition/disk number, 0 = disk A */
 221                    	;  105  int sdinitok;  /* SD card initialized and ready */
 222                    	;  106  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
 223                    	;  107  unsigned long blkmult;   /* block address multiplier */
 224                    	;  108  unsigned long curblkno;  /* block in buffer if curblkok == YES */
 225                    	;  109  
 226                    	;  110  /* debug bool */
 227                    	;  111  int sdtestflg;
 228                    	;  112  
 229                    	;  113  /* CRC routines from:
 230                    	;  114   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
 231                    	;  115   */
 232                    	;  116  
 233                    	;  117  /*
 234                    	;  118  // Calculate CRC7
 235                    	;  119  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
 236                    	;  120  // input:
 237                    	;  121  //   crcIn - the CRC before (0 for first step)
 238                    	;  122  //   data - byte for CRC calculation
 239                    	;  123  // return: the new CRC7
 240                    	;  124  */
 241                    	;  125  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
 242                    	;  126      {
 243                    	_CRC7_one:
 244    0065  CD0000    		call	c.savs
 245    0068  F5        		push	af
 246    0069  F5        		push	af
 247    006A  F5        		push	af
 248    006B  F5        		push	af
 249                    	;  127      const unsigned char g = 0x89;
 250    006C  DD36F989  		ld	(ix-7),137
 251                    	;  128      unsigned char i;
 252                    	;  129  
 253                    	;  130      crcIn ^= data;
 254    0070  DD7E04    		ld	a,(ix+4)
 255    0073  DDAE06    		xor	(ix+6)
 256    0076  DD7704    		ld	(ix+4),a
 257    0079  DD7E05    		ld	a,(ix+5)
 258    007C  DDAE07    		xor	(ix+7)
 259    007F  DD7705    		ld	(ix+5),a
 260                    	;  131      for (i = 0; i < 8; i++)
 261    0082  DD36F800  		ld	(ix-8),0
 262                    	L1:
 263    0086  DD7EF8    		ld	a,(ix-8)
 264    0089  FE08      		cp	8
 265    008B  302F      		jr	nc,L11
 266                    	;  132          {
 267                    	;  133          if (crcIn & 0x80) crcIn ^= g;
 268    008D  DD6E04    		ld	l,(ix+4)
 269    0090  DD6605    		ld	h,(ix+5)
 270    0093  CB7D      		bit	7,l
 271    0095  2813      		jr	z,L14
 272    0097  DD6EF9    		ld	l,(ix-7)
 273    009A  97        		sub	a
 274    009B  67        		ld	h,a
 275    009C  DD7E04    		ld	a,(ix+4)
 276    009F  AD        		xor	l
 277    00A0  DD7704    		ld	(ix+4),a
 278    00A3  DD7E05    		ld	a,(ix+5)
 279    00A6  AC        		xor	h
 280    00A7  DD7705    		ld	(ix+5),a
 281                    	L14:
 282                    	;  134          crcIn <<= 1;
 283    00AA  DD6E04    		ld	l,(ix+4)
 284    00AD  DD6605    		ld	h,(ix+5)
 285    00B0  29        		add	hl,hl
 286    00B1  DD7504    		ld	(ix+4),l
 287    00B4  DD7405    		ld	(ix+5),h
 288                    	;  135          }
 289    00B7  DD34F8    		inc	(ix-8)
 290    00BA  18CA      		jr	L1
 291                    	L11:
 292                    	;  136  
 293                    	;  137      return crcIn;
 294    00BC  DD6E04    		ld	l,(ix+4)
 295    00BF  DD6605    		ld	h,(ix+5)
 296    00C2  4D        		ld	c,l
 297    00C3  44        		ld	b,h
 298    00C4  C30000    		jp	c.rets
 299                    	;  138      }
 300                    	;  139  
 301                    	;  140  /*
 302                    	;  141  // Calculate CRC16 CCITT
 303                    	;  142  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
 304                    	;  143  // input:
 305                    	;  144  //   crcIn - the CRC before (0 for rist step)
 306                    	;  145  //   data - byte for CRC calculation
 307                    	;  146  // return: the CRC16 value
 308                    	;  147  */
 309                    	;  148  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
 310                    	;  149      {
 311                    	_CRC16_one:
 312    00C7  CD0000    		call	c.savs
 313                    	;  150      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
 314    00CA  DD6E04    		ld	l,(ix+4)
 315    00CD  DD6605    		ld	h,(ix+5)
 316    00D0  E5        		push	hl
 317    00D1  210800    		ld	hl,8
 318    00D4  E5        		push	hl
 319    00D5  CD0000    		call	c.ursh
 320    00D8  E1        		pop	hl
 321    00D9  E5        		push	hl
 322    00DA  DD6E04    		ld	l,(ix+4)
 323    00DD  DD6605    		ld	h,(ix+5)
 324    00E0  29        		add	hl,hl
 325    00E1  29        		add	hl,hl
 326    00E2  29        		add	hl,hl
 327    00E3  29        		add	hl,hl
 328    00E4  29        		add	hl,hl
 329    00E5  29        		add	hl,hl
 330    00E6  29        		add	hl,hl
 331    00E7  29        		add	hl,hl
 332    00E8  C1        		pop	bc
 333    00E9  79        		ld	a,c
 334    00EA  B5        		or	l
 335    00EB  4F        		ld	c,a
 336    00EC  78        		ld	a,b
 337    00ED  B4        		or	h
 338    00EE  47        		ld	b,a
 339    00EF  DD7104    		ld	(ix+4),c
 340    00F2  DD7005    		ld	(ix+5),b
 341                    	;  151      crcIn ^=  data;
 342    00F5  DD7E04    		ld	a,(ix+4)
 343    00F8  DDAE06    		xor	(ix+6)
 344    00FB  DD7704    		ld	(ix+4),a
 345    00FE  DD7E05    		ld	a,(ix+5)
 346    0101  DDAE07    		xor	(ix+7)
 347    0104  DD7705    		ld	(ix+5),a
 348                    	;  152      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
 349    0107  DD6E04    		ld	l,(ix+4)
 350    010A  DD6605    		ld	h,(ix+5)
 351    010D  7D        		ld	a,l
 352    010E  E6FF      		and	255
 353    0110  6F        		ld	l,a
 354    0111  97        		sub	a
 355    0112  67        		ld	h,a
 356    0113  4D        		ld	c,l
 357    0114  97        		sub	a
 358    0115  47        		ld	b,a
 359    0116  C5        		push	bc
 360    0117  210400    		ld	hl,4
 361    011A  E5        		push	hl
 362    011B  CD0000    		call	c.irsh
 363    011E  E1        		pop	hl
 364    011F  DD7E04    		ld	a,(ix+4)
 365    0122  AD        		xor	l
 366    0123  DD7704    		ld	(ix+4),a
 367    0126  DD7E05    		ld	a,(ix+5)
 368    0129  AC        		xor	h
 369    012A  DD7705    		ld	(ix+5),a
 370                    	;  153      crcIn ^= (crcIn << 8) << 4;
 371    012D  DD6E04    		ld	l,(ix+4)
 372    0130  DD6605    		ld	h,(ix+5)
 373    0133  29        		add	hl,hl
 374    0134  29        		add	hl,hl
 375    0135  29        		add	hl,hl
 376    0136  29        		add	hl,hl
 377    0137  29        		add	hl,hl
 378    0138  29        		add	hl,hl
 379    0139  29        		add	hl,hl
 380    013A  29        		add	hl,hl
 381    013B  29        		add	hl,hl
 382    013C  29        		add	hl,hl
 383    013D  29        		add	hl,hl
 384    013E  29        		add	hl,hl
 385    013F  DD7E04    		ld	a,(ix+4)
 386    0142  AD        		xor	l
 387    0143  DD7704    		ld	(ix+4),a
 388    0146  DD7E05    		ld	a,(ix+5)
 389    0149  AC        		xor	h
 390    014A  DD7705    		ld	(ix+5),a
 391                    	;  154      crcIn ^= ((crcIn & 0xff) << 4) << 1;
 392    014D  DD6E04    		ld	l,(ix+4)
 393    0150  DD6605    		ld	h,(ix+5)
 394    0153  7D        		ld	a,l
 395    0154  E6FF      		and	255
 396    0156  6F        		ld	l,a
 397    0157  97        		sub	a
 398    0158  67        		ld	h,a
 399    0159  29        		add	hl,hl
 400    015A  29        		add	hl,hl
 401    015B  29        		add	hl,hl
 402    015C  29        		add	hl,hl
 403    015D  29        		add	hl,hl
 404    015E  DD7E04    		ld	a,(ix+4)
 405    0161  AD        		xor	l
 406    0162  DD7704    		ld	(ix+4),a
 407    0165  DD7E05    		ld	a,(ix+5)
 408    0168  AC        		xor	h
 409    0169  DD7705    		ld	(ix+5),a
 410                    	;  155  
 411                    	;  156      return crcIn;
 412    016C  DD4E04    		ld	c,(ix+4)
 413    016F  DD4605    		ld	b,(ix+5)
 414    0172  C30000    		jp	c.rets
 415                    	;  157      }
 416                    	;  158  
 417                    	;  159  /* Send command to SD card and recieve answer.
 418                    	;  160   * A command is 5 bytes long and is followed by
 419                    	;  161   * a CRC7 checksum byte.
 420                    	;  162   * Returns a pointer to the response
 421                    	;  163   * or 0 if no response start bit found.
 422                    	;  164   */
 423                    	;  165  unsigned char *sdcommand(unsigned char *sdcmdp,
 424                    	;  166                           unsigned char *recbuf, int recbytes)
 425                    	;  167      {
 426                    	_sdcommand:
 427    0175  CD0000    		call	c.savs
 428    0178  21F2FF    		ld	hl,65522
 429    017B  39        		add	hl,sp
 430    017C  F9        		ld	sp,hl
 431                    	;  168      int searchn;  /* byte counter to search for response */
 432                    	;  169      int sdcbytes; /* byte counter for bytes to send */
 433                    	;  170      unsigned char *retptr; /* pointer used to store response */
 434                    	;  171      unsigned char rbyte;   /* recieved byte */
 435                    	;  172      unsigned char crc = 0; /* calculated CRC7 */
 436    017D  DD36F200  		ld	(ix-14),0
 437                    	;  173  
 438                    	;  174      /* send 8*2 clockpules */
 439                    	;  175      spiio(0xff);
 440    0181  21FF00    		ld	hl,255
 441    0184  CD0000    		call	_spiio
 442                    	;  176      spiio(0xff);
 443    0187  21FF00    		ld	hl,255
 444    018A  CD0000    		call	_spiio
 445                    	;  177      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
 446    018D  DD36F605  		ld	(ix-10),5
 447    0191  DD36F700  		ld	(ix-9),0
 448                    	L15:
 449    0195  97        		sub	a
 450    0196  DD96F6    		sub	(ix-10)
 451    0199  3E00      		ld	a,0
 452    019B  DD9EF7    		sbc	a,(ix-9)
 453    019E  F2DA01    		jp	p,L16
 454                    	;  178          {
 455                    	;  179          crc = CRC7_one(crc, *sdcmdp);
 456    01A1  DD6E04    		ld	l,(ix+4)
 457    01A4  DD6605    		ld	h,(ix+5)
 458    01A7  6E        		ld	l,(hl)
 459    01A8  97        		sub	a
 460    01A9  67        		ld	h,a
 461    01AA  E5        		push	hl
 462    01AB  DD6EF2    		ld	l,(ix-14)
 463    01AE  97        		sub	a
 464    01AF  67        		ld	h,a
 465    01B0  CD6500    		call	_CRC7_one
 466    01B3  F1        		pop	af
 467    01B4  DD71F2    		ld	(ix-14),c
 468                    	;  180          spiio(*sdcmdp++);
 469    01B7  DD6E04    		ld	l,(ix+4)
 470    01BA  DD6605    		ld	h,(ix+5)
 471    01BD  DD3404    		inc	(ix+4)
 472    01C0  2003      		jr	nz,L01
 473    01C2  DD3405    		inc	(ix+5)
 474                    	L01:
 475    01C5  6E        		ld	l,(hl)
 476    01C6  97        		sub	a
 477    01C7  67        		ld	h,a
 478    01C8  CD0000    		call	_spiio
 479                    	;  181          }
 480    01CB  DD6EF6    		ld	l,(ix-10)
 481    01CE  DD66F7    		ld	h,(ix-9)
 482    01D1  2B        		dec	hl
 483    01D2  DD75F6    		ld	(ix-10),l
 484    01D5  DD74F7    		ld	(ix-9),h
 485    01D8  18BB      		jr	L15
 486                    	L16:
 487                    	;  182      spiio(crc | 0x01);
 488    01DA  DD6EF2    		ld	l,(ix-14)
 489    01DD  97        		sub	a
 490    01DE  67        		ld	h,a
 491    01DF  CBC5      		set	0,l
 492    01E1  CD0000    		call	_spiio
 493                    	;  183      /* search for recieved byte with start bit
 494                    	;  184         for a maximum of 10 recieved bytes  */
 495                    	;  185      for (searchn = 10; 0 < searchn; searchn--)
 496    01E4  DD36F80A  		ld	(ix-8),10
 497    01E8  DD36F900  		ld	(ix-7),0
 498                    	L111:
 499    01EC  97        		sub	a
 500    01ED  DD96F8    		sub	(ix-8)
 501    01F0  3E00      		ld	a,0
 502    01F2  DD9EF9    		sbc	a,(ix-7)
 503    01F5  F21702    		jp	p,L121
 504                    	;  186          {
 505                    	;  187          rbyte = spiio(0xff);
 506    01F8  21FF00    		ld	hl,255
 507    01FB  CD0000    		call	_spiio
 508    01FE  DD71F3    		ld	(ix-13),c
 509                    	;  188          if ((rbyte & 0x80) == 0)
 510    0201  DD6EF3    		ld	l,(ix-13)
 511    0204  CB7D      		bit	7,l
 512    0206  280F      		jr	z,L121
 513                    	;  189              break;
 514                    	L131:
 515    0208  DD6EF8    		ld	l,(ix-8)
 516    020B  DD66F9    		ld	h,(ix-7)
 517    020E  2B        		dec	hl
 518    020F  DD75F8    		ld	(ix-8),l
 519    0212  DD74F9    		ld	(ix-7),h
 520    0215  18D5      		jr	L111
 521                    	L121:
 522                    	;  190          }
 523                    	;  191      if (searchn == 0) /* no start bit found */
 524    0217  DD7EF8    		ld	a,(ix-8)
 525    021A  DDB6F9    		or	(ix-7)
 526    021D  2006      		jr	nz,L161
 527                    	;  192          return (NO);
 528    021F  010000    		ld	bc,0
 529    0222  C30000    		jp	c.rets
 530                    	L161:
 531                    	;  193      retptr = recbuf;
 532    0225  DD7E06    		ld	a,(ix+6)
 533    0228  DD77F4    		ld	(ix-12),a
 534    022B  DD7E07    		ld	a,(ix+7)
 535    022E  DD77F5    		ld	(ix-11),a
 536                    	;  194      *retptr++ = rbyte;
 537    0231  DD6EF4    		ld	l,(ix-12)
 538    0234  DD66F5    		ld	h,(ix-11)
 539    0237  DD34F4    		inc	(ix-12)
 540    023A  2003      		jr	nz,L21
 541    023C  DD34F5    		inc	(ix-11)
 542                    	L21:
 543    023F  DD7EF3    		ld	a,(ix-13)
 544    0242  77        		ld	(hl),a
 545                    	L171:
 546                    	;  195      for (; 1 < recbytes; recbytes--) /* recieve bytes */
 547    0243  3E01      		ld	a,1
 548    0245  DD9608    		sub	(ix+8)
 549    0248  3E00      		ld	a,0
 550    024A  DD9E09    		sbc	a,(ix+9)
 551    024D  F27602    		jp	p,L102
 552                    	;  196          *retptr++ = spiio(0xff);
 553    0250  DD6EF4    		ld	l,(ix-12)
 554    0253  DD66F5    		ld	h,(ix-11)
 555    0256  DD34F4    		inc	(ix-12)
 556    0259  2003      		jr	nz,L41
 557    025B  DD34F5    		inc	(ix-11)
 558                    	L41:
 559    025E  E5        		push	hl
 560    025F  21FF00    		ld	hl,255
 561    0262  CD0000    		call	_spiio
 562    0265  E1        		pop	hl
 563    0266  71        		ld	(hl),c
 564    0267  DD6E08    		ld	l,(ix+8)
 565    026A  DD6609    		ld	h,(ix+9)
 566    026D  2B        		dec	hl
 567    026E  DD7508    		ld	(ix+8),l
 568    0271  DD7409    		ld	(ix+9),h
 569    0274  18CD      		jr	L171
 570                    	L102:
 571                    	;  197      return (recbuf);
 572    0276  DD4E06    		ld	c,(ix+6)
 573    0279  DD4607    		ld	b,(ix+7)
 574    027C  C30000    		jp	c.rets
 575                    	L51:
 576    027F  0A        		.byte	10
 577    0280  53        		.byte	83
 578    0281  65        		.byte	101
 579    0282  6E        		.byte	110
 580    0283  74        		.byte	116
 581    0284  20        		.byte	32
 582    0285  38        		.byte	56
 583    0286  2A        		.byte	42
 584    0287  38        		.byte	56
 585    0288  20        		.byte	32
 586    0289  28        		.byte	40
 587    028A  37        		.byte	55
 588    028B  32        		.byte	50
 589    028C  29        		.byte	41
 590    028D  20        		.byte	32
 591    028E  63        		.byte	99
 592    028F  6C        		.byte	108
 593    0290  6F        		.byte	111
 594    0291  63        		.byte	99
 595    0292  6B        		.byte	107
 596    0293  20        		.byte	32
 597    0294  70        		.byte	112
 598    0295  75        		.byte	117
 599    0296  6C        		.byte	108
 600    0297  73        		.byte	115
 601    0298  65        		.byte	101
 602    0299  73        		.byte	115
 603    029A  2C        		.byte	44
 604    029B  20        		.byte	32
 605    029C  73        		.byte	115
 606    029D  65        		.byte	101
 607    029E  6C        		.byte	108
 608    029F  65        		.byte	101
 609    02A0  63        		.byte	99
 610    02A1  74        		.byte	116
 611    02A2  20        		.byte	32
 612    02A3  6E        		.byte	110
 613    02A4  6F        		.byte	111
 614    02A5  74        		.byte	116
 615    02A6  20        		.byte	32
 616    02A7  61        		.byte	97
 617    02A8  63        		.byte	99
 618    02A9  74        		.byte	116
 619    02AA  69        		.byte	105
 620    02AB  76        		.byte	118
 621    02AC  65        		.byte	101
 622    02AD  0A        		.byte	10
 623    02AE  00        		.byte	0
 624                    	L52:
 625    02AF  43        		.byte	67
 626    02B0  4D        		.byte	77
 627    02B1  44        		.byte	68
 628    02B2  30        		.byte	48
 629    02B3  3A        		.byte	58
 630    02B4  20        		.byte	32
 631    02B5  6E        		.byte	110
 632    02B6  6F        		.byte	111
 633    02B7  20        		.byte	32
 634    02B8  72        		.byte	114
 635    02B9  65        		.byte	101
 636    02BA  73        		.byte	115
 637    02BB  70        		.byte	112
 638    02BC  6F        		.byte	111
 639    02BD  6E        		.byte	110
 640    02BE  73        		.byte	115
 641    02BF  65        		.byte	101
 642    02C0  0A        		.byte	10
 643    02C1  00        		.byte	0
 644                    	L53:
 645    02C2  43        		.byte	67
 646    02C3  4D        		.byte	77
 647    02C4  44        		.byte	68
 648    02C5  30        		.byte	48
 649    02C6  3A        		.byte	58
 650    02C7  20        		.byte	32
 651    02C8  47        		.byte	71
 652    02C9  4F        		.byte	79
 653    02CA  5F        		.byte	95
 654    02CB  49        		.byte	73
 655    02CC  44        		.byte	68
 656    02CD  4C        		.byte	76
 657    02CE  45        		.byte	69
 658    02CF  5F        		.byte	95
 659    02D0  53        		.byte	83
 660    02D1  54        		.byte	84
 661    02D2  41        		.byte	65
 662    02D3  54        		.byte	84
 663    02D4  45        		.byte	69
 664    02D5  2C        		.byte	44
 665    02D6  20        		.byte	32
 666    02D7  52        		.byte	82
 667    02D8  31        		.byte	49
 668    02D9  20        		.byte	32
 669    02DA  72        		.byte	114
 670    02DB  65        		.byte	101
 671    02DC  73        		.byte	115
 672    02DD  70        		.byte	112
 673    02DE  6F        		.byte	111
 674    02DF  6E        		.byte	110
 675    02E0  73        		.byte	115
 676    02E1  65        		.byte	101
 677    02E2  20        		.byte	32
 678    02E3  5B        		.byte	91
 679    02E4  25        		.byte	37
 680    02E5  30        		.byte	48
 681    02E6  32        		.byte	50
 682    02E7  78        		.byte	120
 683    02E8  5D        		.byte	93
 684    02E9  0A        		.byte	10
 685    02EA  00        		.byte	0
 686                    	L54:
 687    02EB  43        		.byte	67
 688    02EC  4D        		.byte	77
 689    02ED  44        		.byte	68
 690    02EE  38        		.byte	56
 691    02EF  3A        		.byte	58
 692    02F0  20        		.byte	32
 693    02F1  6E        		.byte	110
 694    02F2  6F        		.byte	111
 695    02F3  20        		.byte	32
 696    02F4  72        		.byte	114
 697    02F5  65        		.byte	101
 698    02F6  73        		.byte	115
 699    02F7  70        		.byte	112
 700    02F8  6F        		.byte	111
 701    02F9  6E        		.byte	110
 702    02FA  73        		.byte	115
 703    02FB  65        		.byte	101
 704    02FC  0A        		.byte	10
 705    02FD  00        		.byte	0
 706                    	L55:
 707    02FE  43        		.byte	67
 708    02FF  4D        		.byte	77
 709    0300  44        		.byte	68
 710    0301  38        		.byte	56
 711    0302  3A        		.byte	58
 712    0303  20        		.byte	32
 713    0304  53        		.byte	83
 714    0305  45        		.byte	69
 715    0306  4E        		.byte	78
 716    0307  44        		.byte	68
 717    0308  5F        		.byte	95
 718    0309  49        		.byte	73
 719    030A  46        		.byte	70
 720    030B  5F        		.byte	95
 721    030C  43        		.byte	67
 722    030D  4F        		.byte	79
 723    030E  4E        		.byte	78
 724    030F  44        		.byte	68
 725    0310  2C        		.byte	44
 726    0311  20        		.byte	32
 727    0312  52        		.byte	82
 728    0313  37        		.byte	55
 729    0314  20        		.byte	32
 730    0315  72        		.byte	114
 731    0316  65        		.byte	101
 732    0317  73        		.byte	115
 733    0318  70        		.byte	112
 734    0319  6F        		.byte	111
 735    031A  6E        		.byte	110
 736    031B  73        		.byte	115
 737    031C  65        		.byte	101
 738    031D  20        		.byte	32
 739    031E  5B        		.byte	91
 740    031F  25        		.byte	37
 741    0320  30        		.byte	48
 742    0321  32        		.byte	50
 743    0322  78        		.byte	120
 744    0323  20        		.byte	32
 745    0324  25        		.byte	37
 746    0325  30        		.byte	48
 747    0326  32        		.byte	50
 748    0327  78        		.byte	120
 749    0328  20        		.byte	32
 750    0329  25        		.byte	37
 751    032A  30        		.byte	48
 752    032B  32        		.byte	50
 753    032C  78        		.byte	120
 754    032D  20        		.byte	32
 755    032E  25        		.byte	37
 756    032F  30        		.byte	48
 757    0330  32        		.byte	50
 758    0331  78        		.byte	120
 759    0332  20        		.byte	32
 760    0333  25        		.byte	37
 761    0334  30        		.byte	48
 762    0335  32        		.byte	50
 763    0336  78        		.byte	120
 764    0337  5D        		.byte	93
 765    0338  2C        		.byte	44
 766    0339  20        		.byte	32
 767    033A  00        		.byte	0
 768                    	L56:
 769    033B  65        		.byte	101
 770    033C  63        		.byte	99
 771    033D  68        		.byte	104
 772    033E  6F        		.byte	111
 773    033F  20        		.byte	32
 774    0340  62        		.byte	98
 775    0341  61        		.byte	97
 776    0342  63        		.byte	99
 777    0343  6B        		.byte	107
 778    0344  20        		.byte	32
 779    0345  6F        		.byte	111
 780    0346  6B        		.byte	107
 781    0347  2C        		.byte	44
 782    0348  20        		.byte	32
 783    0349  00        		.byte	0
 784                    	L57:
 785    034A  69        		.byte	105
 786    034B  6E        		.byte	110
 787    034C  76        		.byte	118
 788    034D  61        		.byte	97
 789    034E  6C        		.byte	108
 790    034F  69        		.byte	105
 791    0350  64        		.byte	100
 792    0351  20        		.byte	32
 793    0352  65        		.byte	101
 794    0353  63        		.byte	99
 795    0354  68        		.byte	104
 796    0355  6F        		.byte	111
 797    0356  20        		.byte	32
 798    0357  62        		.byte	98
 799    0358  61        		.byte	97
 800    0359  63        		.byte	99
 801    035A  6B        		.byte	107
 802    035B  0A        		.byte	10
 803    035C  00        		.byte	0
 804                    	L501:
 805    035D  70        		.byte	112
 806    035E  72        		.byte	114
 807    035F  6F        		.byte	111
 808    0360  62        		.byte	98
 809    0361  61        		.byte	97
 810    0362  62        		.byte	98
 811    0363  6C        		.byte	108
 812    0364  79        		.byte	121
 813    0365  20        		.byte	32
 814    0366  53        		.byte	83
 815    0367  44        		.byte	68
 816    0368  20        		.byte	32
 817    0369  76        		.byte	118
 818    036A  65        		.byte	101
 819    036B  72        		.byte	114
 820    036C  2E        		.byte	46
 821    036D  20        		.byte	32
 822    036E  31        		.byte	49
 823    036F  0A        		.byte	10
 824    0370  00        		.byte	0
 825                    	L511:
 826    0371  53        		.byte	83
 827    0372  44        		.byte	68
 828    0373  20        		.byte	32
 829    0374  76        		.byte	118
 830    0375  65        		.byte	101
 831    0376  72        		.byte	114
 832    0377  20        		.byte	32
 833    0378  32        		.byte	50
 834    0379  0A        		.byte	10
 835    037A  00        		.byte	0
 836                    	L521:
 837    037B  43        		.byte	67
 838    037C  4D        		.byte	77
 839    037D  44        		.byte	68
 840    037E  35        		.byte	53
 841    037F  35        		.byte	53
 842    0380  3A        		.byte	58
 843    0381  20        		.byte	32
 844    0382  6E        		.byte	110
 845    0383  6F        		.byte	111
 846    0384  20        		.byte	32
 847    0385  72        		.byte	114
 848    0386  65        		.byte	101
 849    0387  73        		.byte	115
 850    0388  70        		.byte	112
 851    0389  6F        		.byte	111
 852    038A  6E        		.byte	110
 853    038B  73        		.byte	115
 854    038C  65        		.byte	101
 855    038D  0A        		.byte	10
 856    038E  00        		.byte	0
 857                    	L531:
 858    038F  43        		.byte	67
 859    0390  4D        		.byte	77
 860    0391  44        		.byte	68
 861    0392  35        		.byte	53
 862    0393  35        		.byte	53
 863    0394  3A        		.byte	58
 864    0395  20        		.byte	32
 865    0396  41        		.byte	65
 866    0397  50        		.byte	80
 867    0398  50        		.byte	80
 868    0399  5F        		.byte	95
 869    039A  43        		.byte	67
 870    039B  4D        		.byte	77
 871    039C  44        		.byte	68
 872    039D  2C        		.byte	44
 873    039E  20        		.byte	32
 874    039F  52        		.byte	82
 875    03A0  31        		.byte	49
 876    03A1  20        		.byte	32
 877    03A2  72        		.byte	114
 878    03A3  65        		.byte	101
 879    03A4  73        		.byte	115
 880    03A5  70        		.byte	112
 881    03A6  6F        		.byte	111
 882    03A7  6E        		.byte	110
 883    03A8  73        		.byte	115
 884    03A9  65        		.byte	101
 885    03AA  20        		.byte	32
 886    03AB  5B        		.byte	91
 887    03AC  25        		.byte	37
 888    03AD  30        		.byte	48
 889    03AE  32        		.byte	50
 890    03AF  78        		.byte	120
 891    03B0  5D        		.byte	93
 892    03B1  0A        		.byte	10
 893    03B2  00        		.byte	0
 894                    	L541:
 895    03B3  41        		.byte	65
 896    03B4  43        		.byte	67
 897    03B5  4D        		.byte	77
 898    03B6  44        		.byte	68
 899    03B7  34        		.byte	52
 900    03B8  31        		.byte	49
 901    03B9  3A        		.byte	58
 902    03BA  20        		.byte	32
 903    03BB  6E        		.byte	110
 904    03BC  6F        		.byte	111
 905    03BD  20        		.byte	32
 906    03BE  72        		.byte	114
 907    03BF  65        		.byte	101
 908    03C0  73        		.byte	115
 909    03C1  70        		.byte	112
 910    03C2  6F        		.byte	111
 911    03C3  6E        		.byte	110
 912    03C4  73        		.byte	115
 913    03C5  65        		.byte	101
 914    03C6  0A        		.byte	10
 915    03C7  00        		.byte	0
 916                    	L571:
 917                    		.byte	[1]
 918                    	L561:
 919    03C9  20        		.byte	32
 920    03CA  2D        		.byte	45
 921    03CB  20        		.byte	32
 922    03CC  72        		.byte	114
 923    03CD  65        		.byte	101
 924    03CE  61        		.byte	97
 925    03CF  64        		.byte	100
 926    03D0  79        		.byte	121
 927    03D1  00        		.byte	0
 928                    	L551:
 929    03D2  41        		.byte	65
 930    03D3  43        		.byte	67
 931    03D4  4D        		.byte	77
 932    03D5  44        		.byte	68
 933    03D6  34        		.byte	52
 934    03D7  31        		.byte	49
 935    03D8  3A        		.byte	58
 936    03D9  20        		.byte	32
 937    03DA  53        		.byte	83
 938    03DB  45        		.byte	69
 939    03DC  4E        		.byte	78
 940    03DD  44        		.byte	68
 941    03DE  5F        		.byte	95
 942    03DF  4F        		.byte	79
 943    03E0  50        		.byte	80
 944    03E1  5F        		.byte	95
 945    03E2  43        		.byte	67
 946    03E3  4F        		.byte	79
 947    03E4  4E        		.byte	78
 948    03E5  44        		.byte	68
 949    03E6  2C        		.byte	44
 950    03E7  20        		.byte	32
 951    03E8  52        		.byte	82
 952    03E9  31        		.byte	49
 953    03EA  20        		.byte	32
 954    03EB  72        		.byte	114
 955    03EC  65        		.byte	101
 956    03ED  73        		.byte	115
 957    03EE  70        		.byte	112
 958    03EF  6F        		.byte	111
 959    03F0  6E        		.byte	110
 960    03F1  73        		.byte	115
 961    03F2  65        		.byte	101
 962    03F3  20        		.byte	32
 963    03F4  5B        		.byte	91
 964    03F5  25        		.byte	37
 965    03F6  30        		.byte	48
 966    03F7  32        		.byte	50
 967    03F8  78        		.byte	120
 968    03F9  5D        		.byte	93
 969    03FA  25        		.byte	37
 970    03FB  73        		.byte	115
 971    03FC  0A        		.byte	10
 972    03FD  00        		.byte	0
 973                    	L502:
 974    03FE  43        		.byte	67
 975    03FF  4D        		.byte	77
 976    0400  44        		.byte	68
 977    0401  35        		.byte	53
 978    0402  38        		.byte	56
 979    0403  3A        		.byte	58
 980    0404  20        		.byte	32
 981    0405  6E        		.byte	110
 982    0406  6F        		.byte	111
 983    0407  20        		.byte	32
 984    0408  72        		.byte	114
 985    0409  65        		.byte	101
 986    040A  73        		.byte	115
 987    040B  70        		.byte	112
 988    040C  6F        		.byte	111
 989    040D  6E        		.byte	110
 990    040E  73        		.byte	115
 991    040F  65        		.byte	101
 992    0410  0A        		.byte	10
 993    0411  00        		.byte	0
 994                    	L512:
 995    0412  43        		.byte	67
 996    0413  4D        		.byte	77
 997    0414  44        		.byte	68
 998    0415  35        		.byte	53
 999    0416  38        		.byte	56
1000    0417  3A        		.byte	58
1001    0418  20        		.byte	32
1002    0419  52        		.byte	82
1003    041A  45        		.byte	69
1004    041B  41        		.byte	65
1005    041C  44        		.byte	68
1006    041D  5F        		.byte	95
1007    041E  4F        		.byte	79
1008    041F  43        		.byte	67
1009    0420  52        		.byte	82
1010    0421  2C        		.byte	44
1011    0422  20        		.byte	32
1012    0423  52        		.byte	82
1013    0424  33        		.byte	51
1014    0425  20        		.byte	32
1015    0426  72        		.byte	114
1016    0427  65        		.byte	101
1017    0428  73        		.byte	115
1018    0429  70        		.byte	112
1019    042A  6F        		.byte	111
1020    042B  6E        		.byte	110
1021    042C  73        		.byte	115
1022    042D  65        		.byte	101
1023    042E  20        		.byte	32
1024    042F  5B        		.byte	91
1025    0430  25        		.byte	37
1026    0431  30        		.byte	48
1027    0432  32        		.byte	50
1028    0433  78        		.byte	120
1029    0434  20        		.byte	32
1030    0435  25        		.byte	37
1031    0436  30        		.byte	48
1032    0437  32        		.byte	50
1033    0438  78        		.byte	120
1034    0439  20        		.byte	32
1035    043A  25        		.byte	37
1036    043B  30        		.byte	48
1037    043C  32        		.byte	50
1038    043D  78        		.byte	120
1039    043E  20        		.byte	32
1040    043F  25        		.byte	37
1041    0440  30        		.byte	48
1042    0441  32        		.byte	50
1043    0442  78        		.byte	120
1044    0443  20        		.byte	32
1045    0444  25        		.byte	37
1046    0445  30        		.byte	48
1047    0446  32        		.byte	50
1048    0447  78        		.byte	120
1049    0448  5D        		.byte	93
1050    0449  0A        		.byte	10
1051    044A  00        		.byte	0
1052                    	L522:
1053    044B  43        		.byte	67
1054    044C  4D        		.byte	77
1055    044D  44        		.byte	68
1056    044E  31        		.byte	49
1057    044F  36        		.byte	54
1058    0450  3A        		.byte	58
1059    0451  20        		.byte	32
1060    0452  6E        		.byte	110
1061    0453  6F        		.byte	111
1062    0454  20        		.byte	32
1063    0455  72        		.byte	114
1064    0456  65        		.byte	101
1065    0457  73        		.byte	115
1066    0458  70        		.byte	112
1067    0459  6F        		.byte	111
1068    045A  6E        		.byte	110
1069    045B  73        		.byte	115
1070    045C  65        		.byte	101
1071    045D  0A        		.byte	10
1072    045E  00        		.byte	0
1073                    	L532:
1074    045F  43        		.byte	67
1075    0460  4D        		.byte	77
1076    0461  44        		.byte	68
1077    0462  31        		.byte	49
1078    0463  36        		.byte	54
1079    0464  3A        		.byte	58
1080    0465  20        		.byte	32
1081    0466  53        		.byte	83
1082    0467  45        		.byte	69
1083    0468  54        		.byte	84
1084    0469  5F        		.byte	95
1085    046A  42        		.byte	66
1086    046B  4C        		.byte	76
1087    046C  4F        		.byte	79
1088    046D  43        		.byte	67
1089    046E  4B        		.byte	75
1090    046F  4C        		.byte	76
1091    0470  45        		.byte	69
1092    0471  4E        		.byte	78
1093    0472  20        		.byte	32
1094    0473  28        		.byte	40
1095    0474  74        		.byte	116
1096    0475  6F        		.byte	111
1097    0476  20        		.byte	32
1098    0477  35        		.byte	53
1099    0478  31        		.byte	49
1100    0479  32        		.byte	50
1101    047A  20        		.byte	32
1102    047B  62        		.byte	98
1103    047C  79        		.byte	121
1104    047D  74        		.byte	116
1105    047E  65        		.byte	101
1106    047F  73        		.byte	115
1107    0480  29        		.byte	41
1108    0481  2C        		.byte	44
1109    0482  20        		.byte	32
1110    0483  52        		.byte	82
1111    0484  31        		.byte	49
1112    0485  20        		.byte	32
1113    0486  72        		.byte	114
1114    0487  65        		.byte	101
1115    0488  73        		.byte	115
1116    0489  70        		.byte	112
1117    048A  6F        		.byte	111
1118    048B  6E        		.byte	110
1119    048C  73        		.byte	115
1120    048D  65        		.byte	101
1121    048E  20        		.byte	32
1122    048F  5B        		.byte	91
1123    0490  25        		.byte	37
1124    0491  30        		.byte	48
1125    0492  32        		.byte	50
1126    0493  78        		.byte	120
1127    0494  5D        		.byte	93
1128    0495  0A        		.byte	10
1129    0496  00        		.byte	0
1130                    	L542:
1131    0497  43        		.byte	67
1132    0498  4D        		.byte	77
1133    0499  44        		.byte	68
1134    049A  31        		.byte	49
1135    049B  30        		.byte	48
1136    049C  3A        		.byte	58
1137    049D  20        		.byte	32
1138    049E  6E        		.byte	110
1139    049F  6F        		.byte	111
1140    04A0  20        		.byte	32
1141    04A1  72        		.byte	114
1142    04A2  65        		.byte	101
1143    04A3  73        		.byte	115
1144    04A4  70        		.byte	112
1145    04A5  6F        		.byte	111
1146    04A6  6E        		.byte	110
1147    04A7  73        		.byte	115
1148    04A8  65        		.byte	101
1149    04A9  0A        		.byte	10
1150    04AA  00        		.byte	0
1151                    	L552:
1152    04AB  43        		.byte	67
1153    04AC  4D        		.byte	77
1154    04AD  44        		.byte	68
1155    04AE  31        		.byte	49
1156    04AF  30        		.byte	48
1157    04B0  3A        		.byte	58
1158    04B1  20        		.byte	32
1159    04B2  53        		.byte	83
1160    04B3  45        		.byte	69
1161    04B4  4E        		.byte	78
1162    04B5  44        		.byte	68
1163    04B6  5F        		.byte	95
1164    04B7  43        		.byte	67
1165    04B8  49        		.byte	73
1166    04B9  44        		.byte	68
1167    04BA  2C        		.byte	44
1168    04BB  20        		.byte	32
1169    04BC  52        		.byte	82
1170    04BD  31        		.byte	49
1171    04BE  20        		.byte	32
1172    04BF  72        		.byte	114
1173    04C0  65        		.byte	101
1174    04C1  73        		.byte	115
1175    04C2  70        		.byte	112
1176    04C3  6F        		.byte	111
1177    04C4  6E        		.byte	110
1178    04C5  73        		.byte	115
1179    04C6  65        		.byte	101
1180    04C7  20        		.byte	32
1181    04C8  5B        		.byte	91
1182    04C9  25        		.byte	37
1183    04CA  30        		.byte	48
1184    04CB  32        		.byte	50
1185    04CC  78        		.byte	120
1186    04CD  5D        		.byte	93
1187    04CE  0A        		.byte	10
1188    04CF  00        		.byte	0
1189                    	L562:
1190    04D0  20        		.byte	32
1191    04D1  20        		.byte	32
1192    04D2  4E        		.byte	78
1193    04D3  6F        		.byte	111
1194    04D4  20        		.byte	32
1195    04D5  64        		.byte	100
1196    04D6  61        		.byte	97
1197    04D7  74        		.byte	116
1198    04D8  61        		.byte	97
1199    04D9  20        		.byte	32
1200    04DA  66        		.byte	102
1201    04DB  6F        		.byte	111
1202    04DC  75        		.byte	117
1203    04DD  6E        		.byte	110
1204    04DE  64        		.byte	100
1205    04DF  0A        		.byte	10
1206    04E0  00        		.byte	0
1207                    	L572:
1208    04E1  20        		.byte	32
1209    04E2  20        		.byte	32
1210    04E3  43        		.byte	67
1211    04E4  49        		.byte	73
1212    04E5  44        		.byte	68
1213    04E6  3A        		.byte	58
1214    04E7  20        		.byte	32
1215    04E8  5B        		.byte	91
1216    04E9  00        		.byte	0
1217                    	L503:
1218    04EA  25        		.byte	37
1219    04EB  30        		.byte	48
1220    04EC  32        		.byte	50
1221    04ED  78        		.byte	120
1222    04EE  20        		.byte	32
1223    04EF  00        		.byte	0
1224                    	L513:
1225    04F0  08        		.byte	8
1226    04F1  5D        		.byte	93
1227    04F2  20        		.byte	32
1228    04F3  7C        		.byte	124
1229    04F4  00        		.byte	0
1230                    	L523:
1231    04F5  7C        		.byte	124
1232    04F6  0A        		.byte	10
1233    04F7  00        		.byte	0
1234                    	L533:
1235    04F8  43        		.byte	67
1236    04F9  52        		.byte	82
1237    04FA  43        		.byte	67
1238    04FB  37        		.byte	55
1239    04FC  20        		.byte	32
1240    04FD  6F        		.byte	111
1241    04FE  6B        		.byte	107
1242    04FF  3A        		.byte	58
1243    0500  20        		.byte	32
1244    0501  5B        		.byte	91
1245    0502  25        		.byte	37
1246    0503  30        		.byte	48
1247    0504  32        		.byte	50
1248    0505  78        		.byte	120
1249    0506  5D        		.byte	93
1250    0507  0A        		.byte	10
1251    0508  00        		.byte	0
1252                    	L543:
1253    0509  43        		.byte	67
1254    050A  52        		.byte	82
1255    050B  43        		.byte	67
1256    050C  37        		.byte	55
1257    050D  20        		.byte	32
1258    050E  65        		.byte	101
1259    050F  72        		.byte	114
1260    0510  72        		.byte	114
1261    0511  6F        		.byte	111
1262    0512  72        		.byte	114
1263    0513  2C        		.byte	44
1264    0514  20        		.byte	32
1265    0515  63        		.byte	99
1266    0516  61        		.byte	97
1267    0517  6C        		.byte	108
1268    0518  63        		.byte	99
1269    0519  75        		.byte	117
1270    051A  6C        		.byte	108
1271    051B  61        		.byte	97
1272    051C  74        		.byte	116
1273    051D  65        		.byte	101
1274    051E  64        		.byte	100
1275    051F  3A        		.byte	58
1276    0520  20        		.byte	32
1277    0521  5B        		.byte	91
1278    0522  25        		.byte	37
1279    0523  30        		.byte	48
1280    0524  32        		.byte	50
1281    0525  78        		.byte	120
1282    0526  5D        		.byte	93
1283    0527  2C        		.byte	44
1284    0528  20        		.byte	32
1285    0529  72        		.byte	114
1286    052A  65        		.byte	101
1287    052B  63        		.byte	99
1288    052C  69        		.byte	105
1289    052D  65        		.byte	101
1290    052E  76        		.byte	118
1291    052F  65        		.byte	101
1292    0530  64        		.byte	100
1293    0531  3A        		.byte	58
1294    0532  20        		.byte	32
1295    0533  5B        		.byte	91
1296    0534  25        		.byte	37
1297    0535  30        		.byte	48
1298    0536  32        		.byte	50
1299    0537  78        		.byte	120
1300    0538  5D        		.byte	93
1301    0539  0A        		.byte	10
1302    053A  00        		.byte	0
1303                    	L553:
1304    053B  43        		.byte	67
1305    053C  4D        		.byte	77
1306    053D  44        		.byte	68
1307    053E  39        		.byte	57
1308    053F  3A        		.byte	58
1309    0540  20        		.byte	32
1310    0541  6E        		.byte	110
1311    0542  6F        		.byte	111
1312    0543  20        		.byte	32
1313    0544  72        		.byte	114
1314    0545  65        		.byte	101
1315    0546  73        		.byte	115
1316    0547  70        		.byte	112
1317    0548  6F        		.byte	111
1318    0549  6E        		.byte	110
1319    054A  73        		.byte	115
1320    054B  65        		.byte	101
1321    054C  0A        		.byte	10
1322    054D  00        		.byte	0
1323                    	L563:
1324    054E  43        		.byte	67
1325    054F  4D        		.byte	77
1326    0550  44        		.byte	68
1327    0551  39        		.byte	57
1328    0552  3A        		.byte	58
1329    0553  20        		.byte	32
1330    0554  53        		.byte	83
1331    0555  45        		.byte	69
1332    0556  4E        		.byte	78
1333    0557  44        		.byte	68
1334    0558  5F        		.byte	95
1335    0559  43        		.byte	67
1336    055A  53        		.byte	83
1337    055B  44        		.byte	68
1338    055C  2C        		.byte	44
1339    055D  20        		.byte	32
1340    055E  52        		.byte	82
1341    055F  31        		.byte	49
1342    0560  20        		.byte	32
1343    0561  72        		.byte	114
1344    0562  65        		.byte	101
1345    0563  73        		.byte	115
1346    0564  70        		.byte	112
1347    0565  6F        		.byte	111
1348    0566  6E        		.byte	110
1349    0567  73        		.byte	115
1350    0568  65        		.byte	101
1351    0569  20        		.byte	32
1352    056A  5B        		.byte	91
1353    056B  25        		.byte	37
1354    056C  30        		.byte	48
1355    056D  32        		.byte	50
1356    056E  78        		.byte	120
1357    056F  5D        		.byte	93
1358    0570  0A        		.byte	10
1359    0571  00        		.byte	0
1360                    	L573:
1361    0572  20        		.byte	32
1362    0573  20        		.byte	32
1363    0574  4E        		.byte	78
1364    0575  6F        		.byte	111
1365    0576  20        		.byte	32
1366    0577  64        		.byte	100
1367    0578  61        		.byte	97
1368    0579  74        		.byte	116
1369    057A  61        		.byte	97
1370    057B  20        		.byte	32
1371    057C  66        		.byte	102
1372    057D  6F        		.byte	111
1373    057E  75        		.byte	117
1374    057F  6E        		.byte	110
1375    0580  64        		.byte	100
1376    0581  0A        		.byte	10
1377    0582  00        		.byte	0
1378                    	L504:
1379    0583  20        		.byte	32
1380    0584  20        		.byte	32
1381    0585  43        		.byte	67
1382    0586  53        		.byte	83
1383    0587  44        		.byte	68
1384    0588  3A        		.byte	58
1385    0589  20        		.byte	32
1386    058A  5B        		.byte	91
1387    058B  00        		.byte	0
1388                    	L514:
1389    058C  25        		.byte	37
1390    058D  30        		.byte	48
1391    058E  32        		.byte	50
1392    058F  78        		.byte	120
1393    0590  20        		.byte	32
1394    0591  00        		.byte	0
1395                    	L524:
1396    0592  08        		.byte	8
1397    0593  5D        		.byte	93
1398    0594  20        		.byte	32
1399    0595  7C        		.byte	124
1400    0596  00        		.byte	0
1401                    	L534:
1402    0597  7C        		.byte	124
1403    0598  0A        		.byte	10
1404    0599  00        		.byte	0
1405                    	L544:
1406    059A  43        		.byte	67
1407    059B  52        		.byte	82
1408    059C  43        		.byte	67
1409    059D  37        		.byte	55
1410    059E  20        		.byte	32
1411    059F  6F        		.byte	111
1412    05A0  6B        		.byte	107
1413    05A1  3A        		.byte	58
1414    05A2  20        		.byte	32
1415    05A3  5B        		.byte	91
1416    05A4  25        		.byte	37
1417    05A5  30        		.byte	48
1418    05A6  32        		.byte	50
1419    05A7  78        		.byte	120
1420    05A8  5D        		.byte	93
1421    05A9  0A        		.byte	10
1422    05AA  00        		.byte	0
1423                    	L554:
1424    05AB  43        		.byte	67
1425    05AC  52        		.byte	82
1426    05AD  43        		.byte	67
1427    05AE  37        		.byte	55
1428    05AF  20        		.byte	32
1429    05B0  65        		.byte	101
1430    05B1  72        		.byte	114
1431    05B2  72        		.byte	114
1432    05B3  6F        		.byte	111
1433    05B4  72        		.byte	114
1434    05B5  2C        		.byte	44
1435    05B6  20        		.byte	32
1436    05B7  63        		.byte	99
1437    05B8  61        		.byte	97
1438    05B9  6C        		.byte	108
1439    05BA  63        		.byte	99
1440    05BB  75        		.byte	117
1441    05BC  6C        		.byte	108
1442    05BD  61        		.byte	97
1443    05BE  74        		.byte	116
1444    05BF  65        		.byte	101
1445    05C0  64        		.byte	100
1446    05C1  3A        		.byte	58
1447    05C2  20        		.byte	32
1448    05C3  5B        		.byte	91
1449    05C4  25        		.byte	37
1450    05C5  30        		.byte	48
1451    05C6  32        		.byte	50
1452    05C7  78        		.byte	120
1453    05C8  5D        		.byte	93
1454    05C9  2C        		.byte	44
1455    05CA  20        		.byte	32
1456    05CB  72        		.byte	114
1457    05CC  65        		.byte	101
1458    05CD  63        		.byte	99
1459    05CE  69        		.byte	105
1460    05CF  65        		.byte	101
1461    05D0  76        		.byte	118
1462    05D1  65        		.byte	101
1463    05D2  64        		.byte	100
1464    05D3  3A        		.byte	58
1465    05D4  20        		.byte	32
1466    05D5  5B        		.byte	91
1467    05D6  25        		.byte	37
1468    05D7  30        		.byte	48
1469    05D8  32        		.byte	50
1470    05D9  78        		.byte	120
1471    05DA  5D        		.byte	93
1472    05DB  0A        		.byte	10
1473    05DC  00        		.byte	0
1474                    	L564:
1475    05DD  53        		.byte	83
1476    05DE  65        		.byte	101
1477    05DF  6E        		.byte	110
1478    05E0  74        		.byte	116
1479    05E1  20        		.byte	32
1480    05E2  39        		.byte	57
1481    05E3  2A        		.byte	42
1482    05E4  38        		.byte	56
1483    05E5  20        		.byte	32
1484    05E6  28        		.byte	40
1485    05E7  37        		.byte	55
1486    05E8  32        		.byte	50
1487    05E9  29        		.byte	41
1488    05EA  20        		.byte	32
1489    05EB  63        		.byte	99
1490    05EC  6C        		.byte	108
1491    05ED  6F        		.byte	111
1492    05EE  63        		.byte	99
1493    05EF  6B        		.byte	107
1494    05F0  20        		.byte	32
1495    05F1  70        		.byte	112
1496    05F2  75        		.byte	117
1497    05F3  6C        		.byte	108
1498    05F4  73        		.byte	115
1499    05F5  65        		.byte	101
1500    05F6  73        		.byte	115
1501    05F7  2C        		.byte	44
1502    05F8  20        		.byte	32
1503    05F9  73        		.byte	115
1504    05FA  65        		.byte	101
1505    05FB  6C        		.byte	108
1506    05FC  65        		.byte	101
1507    05FD  63        		.byte	99
1508    05FE  74        		.byte	116
1509    05FF  20        		.byte	32
1510    0600  61        		.byte	97
1511    0601  63        		.byte	99
1512    0602  74        		.byte	116
1513    0603  69        		.byte	105
1514    0604  76        		.byte	118
1515    0605  65        		.byte	101
1516    0606  0A        		.byte	10
1517    0607  00        		.byte	0
1518                    	;  198      }
1519                    	;  199  
1520                    	;  200  /* Initialise SD card interface
1521                    	;  201   *
1522                    	;  202   * returns YES if ok and NO if not ok
1523                    	;  203   *
1524                    	;  204   * References:
1525                    	;  205   *   https://www.sdcard.org/downloads/pls/
1526                    	;  206   *      Physical Layer Simplified Specification version 8.0
1527                    	;  207   *
1528                    	;  208   * A nice flowchart how to initialize:
1529                    	;  209   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
1530                    	;  210   *
1531                    	;  211   */
1532                    	;  212  int sdinit()
1533                    	;  213      {
1534                    	_sdinit:
1535    0608  CD0000    		call	c.savs0
1536    060B  21E4FF    		ld	hl,65508
1537    060E  39        		add	hl,sp
1538    060F  F9        		ld	sp,hl
1539                    	;  214      int nbytes;  /* byte counter */
1540                    	;  215      int tries;   /* tries to get to active state or searching for data  */
1541                    	;  216      int wtloop;  /* timer loop when trying to enter active state */
1542                    	;  217      unsigned char cmdbuf[5];   /* buffer to build command in */
1543                    	;  218      unsigned char rstatbuf[5]; /* buffer to recieve status in */
1544                    	;  219      unsigned char *statptr;    /* pointer to returned status from SD command */
1545                    	;  220      unsigned char crc;         /* crc register for CID and CSD */
1546                    	;  221      unsigned char rbyte;       /* recieved byte */
1547                    	;  222      unsigned char *prtptr;     /* for debug printing */
1548                    	;  223  
1549                    	;  224      ledon();
1550    0610  CD0000    		call	_ledon
1551                    	;  225      spideselect();
1552    0613  CD0000    		call	_spideselect
1553                    	;  226      sdinitok = NO;
1554    0616  210000    		ld	hl,0
1555    0619  220C00    		ld	(_sdinitok),hl
1556                    	;  227  
1557                    	;  228      /* start to generate 9*8 clock pulses with not selected SD card */
1558                    	;  229      for (nbytes = 9; 0 < nbytes; nbytes--)
1559    061C  DD36F809  		ld	(ix-8),9
1560    0620  DD36F900  		ld	(ix-7),0
1561                    	L132:
1562    0624  97        		sub	a
1563    0625  DD96F8    		sub	(ix-8)
1564    0628  3E00      		ld	a,0
1565    062A  DD9EF9    		sbc	a,(ix-7)
1566    062D  F24506    		jp	p,L142
1567                    	;  230          spiio(0xff);
1568    0630  21FF00    		ld	hl,255
1569    0633  CD0000    		call	_spiio
1570    0636  DD6EF8    		ld	l,(ix-8)
1571    0639  DD66F9    		ld	h,(ix-7)
1572    063C  2B        		dec	hl
1573    063D  DD75F8    		ld	(ix-8),l
1574    0640  DD74F9    		ld	(ix-7),h
1575    0643  18DF      		jr	L132
1576                    	L142:
1577                    	;  231      if (sdtestflg)
1578    0645  2A0000    		ld	hl,(_sdtestflg)
1579    0648  7C        		ld	a,h
1580    0649  B5        		or	l
1581    064A  2806      		jr	z,L172
1582                    	;  232          {
1583                    	;  233          printf("\nSent 8*8 (72) clock pulses, select not active\n");
1584    064C  217F02    		ld	hl,L51
1585    064F  CD0000    		call	_printf
1586                    	L172:
1587                    	;  234          } /* sdtestflg */
1588                    	;  235      spiselect();
1589    0652  CD0000    		call	_spiselect
1590                    	;  236  
1591                    	;  237      /* CMD0: GO_IDLE_STATE */
1592                    	;  238      for (tries = 0; tries < 10; tries++)
1593    0655  DD36F600  		ld	(ix-10),0
1594    0659  DD36F700  		ld	(ix-9),0
1595                    	L103:
1596    065D  DD7EF6    		ld	a,(ix-10)
1597    0660  D60A      		sub	10
1598    0662  DD7EF7    		ld	a,(ix-9)
1599    0665  DE00      		sbc	a,0
1600    0667  F21D07    		jp	p,L113
1601                    	;  239          {
1602                    	;  240          memcpy(cmdbuf, cmd0, 5);
1603    066A  210500    		ld	hl,5
1604    066D  E5        		push	hl
1605    066E  211700    		ld	hl,_cmd0
1606    0671  E5        		push	hl
1607    0672  DDE5      		push	ix
1608    0674  C1        		pop	bc
1609    0675  21EFFF    		ld	hl,65519
1610    0678  09        		add	hl,bc
1611    0679  CD0000    		call	_memcpy
1612    067C  F1        		pop	af
1613    067D  F1        		pop	af
1614                    	;  241          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1615    067E  210100    		ld	hl,1
1616    0681  E5        		push	hl
1617    0682  DDE5      		push	ix
1618    0684  C1        		pop	bc
1619    0685  21EAFF    		ld	hl,65514
1620    0688  09        		add	hl,bc
1621    0689  E5        		push	hl
1622    068A  DDE5      		push	ix
1623    068C  C1        		pop	bc
1624    068D  21EFFF    		ld	hl,65519
1625    0690  09        		add	hl,bc
1626    0691  CD7501    		call	_sdcommand
1627    0694  F1        		pop	af
1628    0695  F1        		pop	af
1629    0696  DD71E8    		ld	(ix-24),c
1630    0699  DD70E9    		ld	(ix-23),b
1631                    	;  242          if (sdtestflg)
1632    069C  2A0000    		ld	hl,(_sdtestflg)
1633    069F  7C        		ld	a,h
1634    06A0  B5        		or	l
1635    06A1  282C      		jr	z,L143
1636                    	;  243              {
1637                    	;  244              if (!statptr)
1638    06A3  DD7EE8    		ld	a,(ix-24)
1639    06A6  DDB6E9    		or	(ix-23)
1640    06A9  2013      		jr	nz,L153
1641                    	;  245                  printf("CMD0: no response\n");
1642    06AB  21AF02    		ld	hl,L52
1643    06AE  CD0000    		call	_printf
1644                    	;  246              else
1645    06B1  181C      		jr	L143
1646                    	L123:
1647    06B3  DD34F6    		inc	(ix-10)
1648    06B6  2003      		jr	nz,L02
1649    06B8  DD34F7    		inc	(ix-9)
1650                    	L02:
1651    06BB  C35D06    		jp	L103
1652                    	L153:
1653                    	;  247                  printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
1654    06BE  DD6EE8    		ld	l,(ix-24)
1655    06C1  DD66E9    		ld	h,(ix-23)
1656    06C4  4E        		ld	c,(hl)
1657    06C5  97        		sub	a
1658    06C6  47        		ld	b,a
1659    06C7  C5        		push	bc
1660    06C8  21C202    		ld	hl,L53
1661    06CB  CD0000    		call	_printf
1662    06CE  F1        		pop	af
1663                    	L143:
1664                    	;  248              } /* sdtestflg */
1665                    	;  249          if (!statptr)
1666    06CF  DD7EE8    		ld	a,(ix-24)
1667    06D2  DDB6E9    		or	(ix-23)
1668    06D5  200C      		jr	nz,L173
1669                    	;  250              {
1670                    	;  251              spideselect();
1671    06D7  CD0000    		call	_spideselect
1672                    	;  252              ledoff();
1673    06DA  CD0000    		call	_ledoff
1674                    	;  253              return (NO);
1675    06DD  010000    		ld	bc,0
1676    06E0  C30000    		jp	c.rets0
1677                    	L173:
1678                    	;  254              }
1679                    	;  255          if (statptr[0] == 0x01)
1680    06E3  DD6EE8    		ld	l,(ix-24)
1681    06E6  DD66E9    		ld	h,(ix-23)
1682    06E9  7E        		ld	a,(hl)
1683    06EA  FE01      		cp	1
1684    06EC  282F      		jr	z,L113
1685                    	;  256              break;
1686                    	;  257          for (wtloop = 0; wtloop < tries * 10; wtloop++)
1687    06EE  DD36F400  		ld	(ix-12),0
1688    06F2  DD36F500  		ld	(ix-11),0
1689                    	L114:
1690    06F6  DD6EF6    		ld	l,(ix-10)
1691    06F9  DD66F7    		ld	h,(ix-9)
1692    06FC  4D        		ld	c,l
1693    06FD  44        		ld	b,h
1694    06FE  29        		add	hl,hl
1695    06FF  29        		add	hl,hl
1696    0700  09        		add	hl,bc
1697    0701  29        		add	hl,hl
1698    0702  DD7EF4    		ld	a,(ix-12)
1699    0705  95        		sub	l
1700    0706  DD7EF5    		ld	a,(ix-11)
1701    0709  9C        		sbc	a,h
1702    070A  F2B306    		jp	p,L123
1703                    	;  258              {
1704                    	;  259              /* wait loop, time increasing for each try */
1705                    	;  260              spiio(0xff);
1706    070D  21FF00    		ld	hl,255
1707    0710  CD0000    		call	_spiio
1708                    	;  261              }
1709    0713  DD34F4    		inc	(ix-12)
1710    0716  2003      		jr	nz,L22
1711    0718  DD34F5    		inc	(ix-11)
1712                    	L22:
1713    071B  18D9      		jr	L114
1714                    	L113:
1715                    	;  262          }
1716                    	;  263  
1717                    	;  264      /* CMD8: SEND_IF_COND */
1718                    	;  265      memcpy(cmdbuf, cmd8, 5);
1719    071D  210500    		ld	hl,5
1720    0720  E5        		push	hl
1721    0721  211D00    		ld	hl,_cmd8
1722    0724  E5        		push	hl
1723    0725  DDE5      		push	ix
1724    0727  C1        		pop	bc
1725    0728  21EFFF    		ld	hl,65519
1726    072B  09        		add	hl,bc
1727    072C  CD0000    		call	_memcpy
1728    072F  F1        		pop	af
1729    0730  F1        		pop	af
1730                    	;  266      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
1731    0731  210500    		ld	hl,5
1732    0734  E5        		push	hl
1733    0735  DDE5      		push	ix
1734    0737  C1        		pop	bc
1735    0738  21EAFF    		ld	hl,65514
1736    073B  09        		add	hl,bc
1737    073C  E5        		push	hl
1738    073D  DDE5      		push	ix
1739    073F  C1        		pop	bc
1740    0740  21EFFF    		ld	hl,65519
1741    0743  09        		add	hl,bc
1742    0744  CD7501    		call	_sdcommand
1743    0747  F1        		pop	af
1744    0748  F1        		pop	af
1745    0749  DD71E8    		ld	(ix-24),c
1746    074C  DD70E9    		ld	(ix-23),b
1747                    	;  267      if (sdtestflg)
1748    074F  2A0000    		ld	hl,(_sdtestflg)
1749    0752  7C        		ld	a,h
1750    0753  B5        		or	l
1751    0754  CADB07    		jp	z,L154
1752                    	;  268          {
1753                    	;  269          if (!statptr)
1754    0757  DD7EE8    		ld	a,(ix-24)
1755    075A  DDB6E9    		or	(ix-23)
1756    075D  2009      		jr	nz,L164
1757                    	;  270              printf("CMD8: no response\n");
1758    075F  21EB02    		ld	hl,L54
1759    0762  CD0000    		call	_printf
1760                    	;  271          else
1761    0765  C3DB07    		jp	L154
1762                    	L164:
1763                    	;  272              {
1764                    	;  273              printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
1765                    	;  274                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
1766    0768  DD6EE8    		ld	l,(ix-24)
1767    076B  DD66E9    		ld	h,(ix-23)
1768    076E  23        		inc	hl
1769    076F  23        		inc	hl
1770    0770  23        		inc	hl
1771    0771  23        		inc	hl
1772    0772  4E        		ld	c,(hl)
1773    0773  97        		sub	a
1774    0774  47        		ld	b,a
1775    0775  C5        		push	bc
1776    0776  DD6EE8    		ld	l,(ix-24)
1777    0779  DD66E9    		ld	h,(ix-23)
1778    077C  23        		inc	hl
1779    077D  23        		inc	hl
1780    077E  23        		inc	hl
1781    077F  4E        		ld	c,(hl)
1782    0780  97        		sub	a
1783    0781  47        		ld	b,a
1784    0782  C5        		push	bc
1785    0783  DD6EE8    		ld	l,(ix-24)
1786    0786  DD66E9    		ld	h,(ix-23)
1787    0789  23        		inc	hl
1788    078A  23        		inc	hl
1789    078B  4E        		ld	c,(hl)
1790    078C  97        		sub	a
1791    078D  47        		ld	b,a
1792    078E  C5        		push	bc
1793    078F  DD6EE8    		ld	l,(ix-24)
1794    0792  DD66E9    		ld	h,(ix-23)
1795    0795  23        		inc	hl
1796    0796  4E        		ld	c,(hl)
1797    0797  97        		sub	a
1798    0798  47        		ld	b,a
1799    0799  C5        		push	bc
1800    079A  DD6EE8    		ld	l,(ix-24)
1801    079D  DD66E9    		ld	h,(ix-23)
1802    07A0  4E        		ld	c,(hl)
1803    07A1  97        		sub	a
1804    07A2  47        		ld	b,a
1805    07A3  C5        		push	bc
1806    07A4  21FE02    		ld	hl,L55
1807    07A7  CD0000    		call	_printf
1808    07AA  210A00    		ld	hl,10
1809    07AD  39        		add	hl,sp
1810    07AE  F9        		ld	sp,hl
1811                    	;  275              if (!(statptr[0] & 0xfe)) /* no error */
1812    07AF  DD6EE8    		ld	l,(ix-24)
1813    07B2  DD66E9    		ld	h,(ix-23)
1814    07B5  6E        		ld	l,(hl)
1815    07B6  97        		sub	a
1816    07B7  67        		ld	h,a
1817    07B8  CB85      		res	0,l
1818    07BA  7D        		ld	a,l
1819    07BB  B4        		or	h
1820    07BC  201D      		jr	nz,L154
1821                    	;  276                  {
1822                    	;  277                  if (statptr[4] == 0xaa)
1823    07BE  DD6EE8    		ld	l,(ix-24)
1824    07C1  DD66E9    		ld	h,(ix-23)
1825    07C4  23        		inc	hl
1826    07C5  23        		inc	hl
1827    07C6  23        		inc	hl
1828    07C7  23        		inc	hl
1829    07C8  7E        		ld	a,(hl)
1830    07C9  FEAA      		cp	170
1831    07CB  2008      		jr	nz,L115
1832                    	;  278                      printf("echo back ok, ");
1833    07CD  213B03    		ld	hl,L56
1834    07D0  CD0000    		call	_printf
1835                    	;  279                  else
1836    07D3  1806      		jr	L154
1837                    	L115:
1838                    	;  280                      printf("invalid echo back\n");
1839    07D5  214A03    		ld	hl,L57
1840    07D8  CD0000    		call	_printf
1841                    	L154:
1842                    	;  281                  }
1843                    	;  282              }
1844                    	;  283          } /* sdtestflg */
1845                    	;  284      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
1846    07DB  DD7EE8    		ld	a,(ix-24)
1847    07DE  DDB6E9    		or	(ix-23)
1848    07E1  280F      		jr	z,L145
1849    07E3  DD6EE8    		ld	l,(ix-24)
1850    07E6  DD66E9    		ld	h,(ix-23)
1851    07E9  6E        		ld	l,(hl)
1852    07EA  97        		sub	a
1853    07EB  67        		ld	h,a
1854    07EC  CB85      		res	0,l
1855    07EE  7D        		ld	a,l
1856    07EF  B4        		or	h
1857    07F0  2815      		jr	z,L135
1858                    	L145:
1859                    	;  285          {
1860                    	;  286          sdver2 = NO;
1861    07F2  210000    		ld	hl,0
1862    07F5  220A00    		ld	(_sdver2),hl
1863                    	;  287          if (sdtestflg)
1864    07F8  2A0000    		ld	hl,(_sdtestflg)
1865    07FB  7C        		ld	a,h
1866    07FC  B5        		or	l
1867    07FD  2836      		jr	z,L165
1868                    	;  288              {
1869                    	;  289              printf("probably SD ver. 1\n");
1870    07FF  215D03    		ld	hl,L501
1871    0802  CD0000    		call	_printf
1872    0805  182E      		jr	L165
1873                    	L135:
1874                    	;  290              } /* sdtestflg */
1875                    	;  291          }
1876                    	;  292      else
1877                    	;  293          {
1878                    	;  294          sdver2 = YES;
1879    0807  210100    		ld	hl,1
1880    080A  220A00    		ld	(_sdver2),hl
1881                    	;  295          if (statptr[4] != 0xaa) /* but invalid echo back */
1882    080D  DD6EE8    		ld	l,(ix-24)
1883    0810  DD66E9    		ld	h,(ix-23)
1884    0813  23        		inc	hl
1885    0814  23        		inc	hl
1886    0815  23        		inc	hl
1887    0816  23        		inc	hl
1888    0817  7E        		ld	a,(hl)
1889    0818  FEAA      		cp	170
1890    081A  280C      		jr	z,L175
1891                    	;  296              {
1892                    	;  297              spideselect();
1893    081C  CD0000    		call	_spideselect
1894                    	;  298              ledoff();
1895    081F  CD0000    		call	_ledoff
1896                    	;  299              return (NO);
1897    0822  010000    		ld	bc,0
1898    0825  C30000    		jp	c.rets0
1899                    	L175:
1900                    	;  300              }
1901                    	;  301          if (sdtestflg)
1902    0828  2A0000    		ld	hl,(_sdtestflg)
1903    082B  7C        		ld	a,h
1904    082C  B5        		or	l
1905    082D  2806      		jr	z,L165
1906                    	;  302              {
1907                    	;  303              printf("SD ver 2\n");
1908    082F  217103    		ld	hl,L511
1909    0832  CD0000    		call	_printf
1910                    	L165:
1911                    	;  304              } /* sdtestflg */
1912                    	;  305          }
1913                    	;  306  
1914                    	;  307      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
1915                    	;  308      for (tries = 0; tries < 20; tries++)
1916    0835  DD36F600  		ld	(ix-10),0
1917    0839  DD36F700  		ld	(ix-9),0
1918                    	L116:
1919    083D  DD7EF6    		ld	a,(ix-10)
1920    0840  D614      		sub	20
1921    0842  DD7EF7    		ld	a,(ix-9)
1922    0845  DE00      		sbc	a,0
1923    0847  F28F09    		jp	p,L126
1924                    	;  309          {
1925                    	;  310          memcpy(cmdbuf, cmd55, 5);
1926    084A  210500    		ld	hl,5
1927    084D  E5        		push	hl
1928    084E  214100    		ld	hl,_cmd55
1929    0851  E5        		push	hl
1930    0852  DDE5      		push	ix
1931    0854  C1        		pop	bc
1932    0855  21EFFF    		ld	hl,65519
1933    0858  09        		add	hl,bc
1934    0859  CD0000    		call	_memcpy
1935    085C  F1        		pop	af
1936    085D  F1        		pop	af
1937                    	;  311          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1938    085E  210100    		ld	hl,1
1939    0861  E5        		push	hl
1940    0862  DDE5      		push	ix
1941    0864  C1        		pop	bc
1942    0865  21EAFF    		ld	hl,65514
1943    0868  09        		add	hl,bc
1944    0869  E5        		push	hl
1945    086A  DDE5      		push	ix
1946    086C  C1        		pop	bc
1947    086D  21EFFF    		ld	hl,65519
1948    0870  09        		add	hl,bc
1949    0871  CD7501    		call	_sdcommand
1950    0874  F1        		pop	af
1951    0875  F1        		pop	af
1952    0876  DD71E8    		ld	(ix-24),c
1953    0879  DD70E9    		ld	(ix-23),b
1954                    	;  312          if (sdtestflg)
1955    087C  2A0000    		ld	hl,(_sdtestflg)
1956    087F  7C        		ld	a,h
1957    0880  B5        		or	l
1958    0881  282C      		jr	z,L156
1959                    	;  313              {
1960                    	;  314              if (!statptr)
1961    0883  DD7EE8    		ld	a,(ix-24)
1962    0886  DDB6E9    		or	(ix-23)
1963    0889  2013      		jr	nz,L166
1964                    	;  315                  printf("CMD55: no response\n");
1965    088B  217B03    		ld	hl,L521
1966    088E  CD0000    		call	_printf
1967                    	;  316              else
1968    0891  181C      		jr	L156
1969                    	L136:
1970    0893  DD34F6    		inc	(ix-10)
1971    0896  2003      		jr	nz,L42
1972    0898  DD34F7    		inc	(ix-9)
1973                    	L42:
1974    089B  C33D08    		jp	L116
1975                    	L166:
1976                    	;  317                  printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
1977    089E  DD6EE8    		ld	l,(ix-24)
1978    08A1  DD66E9    		ld	h,(ix-23)
1979    08A4  4E        		ld	c,(hl)
1980    08A5  97        		sub	a
1981    08A6  47        		ld	b,a
1982    08A7  C5        		push	bc
1983    08A8  218F03    		ld	hl,L531
1984    08AB  CD0000    		call	_printf
1985    08AE  F1        		pop	af
1986                    	L156:
1987                    	;  318              } /* sdtestflg */
1988                    	;  319          if (!statptr)
1989    08AF  DD7EE8    		ld	a,(ix-24)
1990    08B2  DDB6E9    		or	(ix-23)
1991    08B5  200C      		jr	nz,L107
1992                    	;  320              {
1993                    	;  321              spideselect();
1994    08B7  CD0000    		call	_spideselect
1995                    	;  322              ledoff();
1996    08BA  CD0000    		call	_ledoff
1997                    	;  323              return (NO);
1998    08BD  010000    		ld	bc,0
1999    08C0  C30000    		jp	c.rets0
2000                    	L107:
2001                    	;  324              }
2002                    	;  325          memcpy(cmdbuf, acmd41, 5);
2003    08C3  210500    		ld	hl,5
2004    08C6  E5        		push	hl
2005    08C7  214D00    		ld	hl,_acmd41
2006    08CA  E5        		push	hl
2007    08CB  DDE5      		push	ix
2008    08CD  C1        		pop	bc
2009    08CE  21EFFF    		ld	hl,65519
2010    08D1  09        		add	hl,bc
2011    08D2  CD0000    		call	_memcpy
2012    08D5  F1        		pop	af
2013    08D6  F1        		pop	af
2014                    	;  326          if (sdver2)
2015    08D7  2A0A00    		ld	hl,(_sdver2)
2016    08DA  7C        		ld	a,h
2017    08DB  B5        		or	l
2018    08DC  2806      		jr	z,L117
2019                    	;  327              cmdbuf[1] = 0x40;
2020    08DE  DD36F040  		ld	(ix-16),64
2021                    	;  328          else
2022    08E2  1804      		jr	L127
2023                    	L117:
2024                    	;  329              cmdbuf[1] = 0x00;
2025    08E4  DD36F000  		ld	(ix-16),0
2026                    	L127:
2027                    	;  330          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2028    08E8  210100    		ld	hl,1
2029    08EB  E5        		push	hl
2030    08EC  DDE5      		push	ix
2031    08EE  C1        		pop	bc
2032    08EF  21EAFF    		ld	hl,65514
2033    08F2  09        		add	hl,bc
2034    08F3  E5        		push	hl
2035    08F4  DDE5      		push	ix
2036    08F6  C1        		pop	bc
2037    08F7  21EFFF    		ld	hl,65519
2038    08FA  09        		add	hl,bc
2039    08FB  CD7501    		call	_sdcommand
2040    08FE  F1        		pop	af
2041    08FF  F1        		pop	af
2042    0900  DD71E8    		ld	(ix-24),c
2043    0903  DD70E9    		ld	(ix-23),b
2044                    	;  331          if (sdtestflg)
2045    0906  2A0000    		ld	hl,(_sdtestflg)
2046    0909  7C        		ld	a,h
2047    090A  B5        		or	l
2048    090B  2835      		jr	z,L137
2049                    	;  332              {
2050                    	;  333              if (!statptr)
2051    090D  DD7EE8    		ld	a,(ix-24)
2052    0910  DDB6E9    		or	(ix-23)
2053    0913  2008      		jr	nz,L147
2054                    	;  334                  printf("ACMD41: no response\n");
2055    0915  21B303    		ld	hl,L541
2056    0918  CD0000    		call	_printf
2057                    	;  335              else
2058    091B  1825      		jr	L137
2059                    	L147:
2060                    	;  336                  printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
2061                    	;  337                         statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
2062    091D  DD6EE8    		ld	l,(ix-24)
2063    0920  DD66E9    		ld	h,(ix-23)
2064    0923  7E        		ld	a,(hl)
2065    0924  B7        		or	a
2066    0925  2005      		jr	nz,L62
2067    0927  01C903    		ld	bc,L561
2068    092A  1803      		jr	L03
2069                    	L62:
2070    092C  01C803    		ld	bc,L571
2071                    	L03:
2072    092F  C5        		push	bc
2073    0930  DD6EE8    		ld	l,(ix-24)
2074    0933  DD66E9    		ld	h,(ix-23)
2075    0936  4E        		ld	c,(hl)
2076    0937  97        		sub	a
2077    0938  47        		ld	b,a
2078    0939  C5        		push	bc
2079    093A  21D203    		ld	hl,L551
2080    093D  CD0000    		call	_printf
2081    0940  F1        		pop	af
2082    0941  F1        		pop	af
2083                    	L137:
2084                    	;  338              } /* sdtestflg */
2085                    	;  339          if (!statptr)
2086    0942  DD7EE8    		ld	a,(ix-24)
2087    0945  DDB6E9    		or	(ix-23)
2088    0948  200C      		jr	nz,L167
2089                    	;  340              {
2090                    	;  341              spideselect();
2091    094A  CD0000    		call	_spideselect
2092                    	;  342              ledoff();
2093    094D  CD0000    		call	_ledoff
2094                    	;  343              return (NO);
2095    0950  010000    		ld	bc,0
2096    0953  C30000    		jp	c.rets0
2097                    	L167:
2098                    	;  344              }
2099                    	;  345          if (statptr[0] == 0x00) /* now the SD card is ready */
2100    0956  DD6EE8    		ld	l,(ix-24)
2101    0959  DD66E9    		ld	h,(ix-23)
2102    095C  7E        		ld	a,(hl)
2103    095D  B7        		or	a
2104    095E  282F      		jr	z,L126
2105                    	;  346              {
2106                    	;  347              break;
2107                    	;  348              }
2108                    	;  349          for (wtloop = 0; wtloop < tries * 10; wtloop++)
2109    0960  DD36F400  		ld	(ix-12),0
2110    0964  DD36F500  		ld	(ix-11),0
2111                    	L1001:
2112    0968  DD6EF6    		ld	l,(ix-10)
2113    096B  DD66F7    		ld	h,(ix-9)
2114    096E  4D        		ld	c,l
2115    096F  44        		ld	b,h
2116    0970  29        		add	hl,hl
2117    0971  29        		add	hl,hl
2118    0972  09        		add	hl,bc
2119    0973  29        		add	hl,hl
2120    0974  DD7EF4    		ld	a,(ix-12)
2121    0977  95        		sub	l
2122    0978  DD7EF5    		ld	a,(ix-11)
2123    097B  9C        		sbc	a,h
2124    097C  F29308    		jp	p,L136
2125                    	;  350              {
2126                    	;  351              /* wait loop, time increasing for each try */
2127                    	;  352              spiio(0xff);
2128    097F  21FF00    		ld	hl,255
2129    0982  CD0000    		call	_spiio
2130                    	;  353              }
2131    0985  DD34F4    		inc	(ix-12)
2132    0988  2003      		jr	nz,L23
2133    098A  DD34F5    		inc	(ix-11)
2134                    	L23:
2135    098D  18D9      		jr	L1001
2136                    	L126:
2137                    	;  354          }
2138                    	;  355  
2139                    	;  356      /* CMD58: READ_OCR */
2140                    	;  357      /* According to the flow chart this should not work
2141                    	;  358         for SD ver. 1 but the response is ok anyway
2142                    	;  359         all tested SD cards  */
2143                    	;  360      memcpy(cmdbuf, cmd58, 5);
2144    098F  210500    		ld	hl,5
2145    0992  E5        		push	hl
2146    0993  214700    		ld	hl,_cmd58
2147    0996  E5        		push	hl
2148    0997  DDE5      		push	ix
2149    0999  C1        		pop	bc
2150    099A  21EFFF    		ld	hl,65519
2151    099D  09        		add	hl,bc
2152    099E  CD0000    		call	_memcpy
2153    09A1  F1        		pop	af
2154    09A2  F1        		pop	af
2155                    	;  361      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
2156    09A3  210500    		ld	hl,5
2157    09A6  E5        		push	hl
2158    09A7  DDE5      		push	ix
2159    09A9  C1        		pop	bc
2160    09AA  21EAFF    		ld	hl,65514
2161    09AD  09        		add	hl,bc
2162    09AE  E5        		push	hl
2163    09AF  DDE5      		push	ix
2164    09B1  C1        		pop	bc
2165    09B2  21EFFF    		ld	hl,65519
2166    09B5  09        		add	hl,bc
2167    09B6  CD7501    		call	_sdcommand
2168    09B9  F1        		pop	af
2169    09BA  F1        		pop	af
2170    09BB  DD71E8    		ld	(ix-24),c
2171    09BE  DD70E9    		ld	(ix-23),b
2172                    	;  362      if (sdtestflg)
2173    09C1  2A0000    		ld	hl,(_sdtestflg)
2174    09C4  7C        		ld	a,h
2175    09C5  B5        		or	l
2176    09C6  CA210A    		jp	z,L1401
2177                    	;  363          {
2178                    	;  364          if (!statptr)
2179    09C9  DD7EE8    		ld	a,(ix-24)
2180    09CC  DDB6E9    		or	(ix-23)
2181    09CF  2009      		jr	nz,L1501
2182                    	;  365              printf("CMD58: no response\n");
2183    09D1  21FE03    		ld	hl,L502
2184    09D4  CD0000    		call	_printf
2185                    	;  366          else
2186    09D7  C3210A    		jp	L1401
2187                    	L1501:
2188                    	;  367              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
2189                    	;  368                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2190    09DA  DD6EE8    		ld	l,(ix-24)
2191    09DD  DD66E9    		ld	h,(ix-23)
2192    09E0  23        		inc	hl
2193    09E1  23        		inc	hl
2194    09E2  23        		inc	hl
2195    09E3  23        		inc	hl
2196    09E4  4E        		ld	c,(hl)
2197    09E5  97        		sub	a
2198    09E6  47        		ld	b,a
2199    09E7  C5        		push	bc
2200    09E8  DD6EE8    		ld	l,(ix-24)
2201    09EB  DD66E9    		ld	h,(ix-23)
2202    09EE  23        		inc	hl
2203    09EF  23        		inc	hl
2204    09F0  23        		inc	hl
2205    09F1  4E        		ld	c,(hl)
2206    09F2  97        		sub	a
2207    09F3  47        		ld	b,a
2208    09F4  C5        		push	bc
2209    09F5  DD6EE8    		ld	l,(ix-24)
2210    09F8  DD66E9    		ld	h,(ix-23)
2211    09FB  23        		inc	hl
2212    09FC  23        		inc	hl
2213    09FD  4E        		ld	c,(hl)
2214    09FE  97        		sub	a
2215    09FF  47        		ld	b,a
2216    0A00  C5        		push	bc
2217    0A01  DD6EE8    		ld	l,(ix-24)
2218    0A04  DD66E9    		ld	h,(ix-23)
2219    0A07  23        		inc	hl
2220    0A08  4E        		ld	c,(hl)
2221    0A09  97        		sub	a
2222    0A0A  47        		ld	b,a
2223    0A0B  C5        		push	bc
2224    0A0C  DD6EE8    		ld	l,(ix-24)
2225    0A0F  DD66E9    		ld	h,(ix-23)
2226    0A12  4E        		ld	c,(hl)
2227    0A13  97        		sub	a
2228    0A14  47        		ld	b,a
2229    0A15  C5        		push	bc
2230    0A16  211204    		ld	hl,L512
2231    0A19  CD0000    		call	_printf
2232    0A1C  210A00    		ld	hl,10
2233    0A1F  39        		add	hl,sp
2234    0A20  F9        		ld	sp,hl
2235                    	L1401:
2236                    	;  369          } /* sdtestflg */
2237                    	;  370      if (!statptr)
2238    0A21  DD7EE8    		ld	a,(ix-24)
2239    0A24  DDB6E9    		or	(ix-23)
2240    0A27  200C      		jr	nz,L1701
2241                    	;  371          {
2242                    	;  372          spideselect();
2243    0A29  CD0000    		call	_spideselect
2244                    	;  373          ledoff();
2245    0A2C  CD0000    		call	_ledoff
2246                    	;  374          return (NO);
2247    0A2F  010000    		ld	bc,0
2248    0A32  C30000    		jp	c.rets0
2249                    	L1701:
2250                    	;  375          }
2251                    	;  376      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
2252    0A35  210400    		ld	hl,4
2253    0A38  E5        		push	hl
2254    0A39  DD6EE8    		ld	l,(ix-24)
2255    0A3C  DD66E9    		ld	h,(ix-23)
2256    0A3F  23        		inc	hl
2257    0A40  E5        		push	hl
2258    0A41  214800    		ld	hl,_ocrreg
2259    0A44  CD0000    		call	_memcpy
2260    0A47  F1        		pop	af
2261    0A48  F1        		pop	af
2262                    	;  377      blkmult = 1; /* assume block address */
2263    0A49  3E01      		ld	a,1
2264    0A4B  320800    		ld	(_blkmult+2),a
2265    0A4E  87        		add	a,a
2266    0A4F  9F        		sbc	a,a
2267    0A50  320900    		ld	(_blkmult+3),a
2268    0A53  320700    		ld	(_blkmult+1),a
2269    0A56  320600    		ld	(_blkmult),a
2270                    	;  378      if (ocrreg[0] & 0x80)
2271    0A59  3A4800    		ld	a,(_ocrreg)
2272    0A5C  CB7F      		bit	7,a
2273    0A5E  6F        		ld	l,a
2274    0A5F  2817      		jr	z,L1011
2275                    	;  379          {
2276                    	;  380          /* SD Ver.2+ */
2277                    	;  381          if (!(ocrreg[0] & 0x40))
2278    0A61  3A4800    		ld	a,(_ocrreg)
2279    0A64  CB77      		bit	6,a
2280    0A66  6F        		ld	l,a
2281    0A67  200F      		jr	nz,L1011
2282                    	;  382              {
2283                    	;  383              /* SD Ver.2+, Byte address */
2284                    	;  384              blkmult = 512;
2285    0A69  97        		sub	a
2286    0A6A  320600    		ld	(_blkmult),a
2287    0A6D  320700    		ld	(_blkmult+1),a
2288    0A70  320800    		ld	(_blkmult+2),a
2289    0A73  3E02      		ld	a,2
2290    0A75  320900    		ld	(_blkmult+3),a
2291                    	L1011:
2292                    	;  385              }
2293                    	;  386          }
2294                    	;  387  
2295                    	;  388      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
2296                    	;  389      if (blkmult == 512)
2297    0A78  210600    		ld	hl,_blkmult
2298    0A7B  E5        		push	hl
2299    0A7C  97        		sub	a
2300    0A7D  320000    		ld	(c.r0),a
2301    0A80  320100    		ld	(c.r0+1),a
2302    0A83  320200    		ld	(c.r0+2),a
2303    0A86  3E02      		ld	a,2
2304    0A88  320300    		ld	(c.r0+3),a
2305    0A8B  210000    		ld	hl,c.r0
2306    0A8E  E5        		push	hl
2307    0A8F  CD0000    		call	c.lcmp
2308    0A92  C2030B    		jp	nz,L1211
2309                    	;  390          {
2310                    	;  391          memcpy(cmdbuf, cmd16, 5);
2311    0A95  210500    		ld	hl,5
2312    0A98  E5        		push	hl
2313    0A99  212F00    		ld	hl,_cmd16
2314    0A9C  E5        		push	hl
2315    0A9D  DDE5      		push	ix
2316    0A9F  C1        		pop	bc
2317    0AA0  21EFFF    		ld	hl,65519
2318    0AA3  09        		add	hl,bc
2319    0AA4  CD0000    		call	_memcpy
2320    0AA7  F1        		pop	af
2321    0AA8  F1        		pop	af
2322                    	;  392          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2323    0AA9  210100    		ld	hl,1
2324    0AAC  E5        		push	hl
2325    0AAD  DDE5      		push	ix
2326    0AAF  C1        		pop	bc
2327    0AB0  21EAFF    		ld	hl,65514
2328    0AB3  09        		add	hl,bc
2329    0AB4  E5        		push	hl
2330    0AB5  DDE5      		push	ix
2331    0AB7  C1        		pop	bc
2332    0AB8  21EFFF    		ld	hl,65519
2333    0ABB  09        		add	hl,bc
2334    0ABC  CD7501    		call	_sdcommand
2335    0ABF  F1        		pop	af
2336    0AC0  F1        		pop	af
2337    0AC1  DD71E8    		ld	(ix-24),c
2338    0AC4  DD70E9    		ld	(ix-23),b
2339                    	;  393          if (sdtestflg)
2340    0AC7  2A0000    		ld	hl,(_sdtestflg)
2341    0ACA  7C        		ld	a,h
2342    0ACB  B5        		or	l
2343    0ACC  2821      		jr	z,L1311
2344                    	;  394              {
2345                    	;  395              if (!statptr)
2346    0ACE  DD7EE8    		ld	a,(ix-24)
2347    0AD1  DDB6E9    		or	(ix-23)
2348    0AD4  2008      		jr	nz,L1411
2349                    	;  396                  printf("CMD16: no response\n");
2350    0AD6  214B04    		ld	hl,L522
2351    0AD9  CD0000    		call	_printf
2352                    	;  397              else
2353    0ADC  1811      		jr	L1311
2354                    	L1411:
2355                    	;  398                  printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
2356                    	;  399                         statptr[0]);
2357    0ADE  DD6EE8    		ld	l,(ix-24)
2358    0AE1  DD66E9    		ld	h,(ix-23)
2359    0AE4  4E        		ld	c,(hl)
2360    0AE5  97        		sub	a
2361    0AE6  47        		ld	b,a
2362    0AE7  C5        		push	bc
2363    0AE8  215F04    		ld	hl,L532
2364    0AEB  CD0000    		call	_printf
2365    0AEE  F1        		pop	af
2366                    	L1311:
2367                    	;  400              } /* sdtestflg */
2368                    	;  401          if (!statptr)
2369    0AEF  DD7EE8    		ld	a,(ix-24)
2370    0AF2  DDB6E9    		or	(ix-23)
2371    0AF5  200C      		jr	nz,L1211
2372                    	;  402              {
2373                    	;  403              spideselect();
2374    0AF7  CD0000    		call	_spideselect
2375                    	;  404              ledoff();
2376    0AFA  CD0000    		call	_ledoff
2377                    	;  405              return (NO);
2378    0AFD  010000    		ld	bc,0
2379    0B00  C30000    		jp	c.rets0
2380                    	L1211:
2381                    	;  406              }
2382                    	;  407          }
2383                    	;  408      /* Register information:
2384                    	;  409       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
2385                    	;  410       */
2386                    	;  411  
2387                    	;  412      /* CMD10: SEND_CID */
2388                    	;  413      memcpy(cmdbuf, cmd10, 5);
2389    0B03  210500    		ld	hl,5
2390    0B06  E5        		push	hl
2391    0B07  212900    		ld	hl,_cmd10
2392    0B0A  E5        		push	hl
2393    0B0B  DDE5      		push	ix
2394    0B0D  C1        		pop	bc
2395    0B0E  21EFFF    		ld	hl,65519
2396    0B11  09        		add	hl,bc
2397    0B12  CD0000    		call	_memcpy
2398    0B15  F1        		pop	af
2399    0B16  F1        		pop	af
2400                    	;  414      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2401    0B17  210100    		ld	hl,1
2402    0B1A  E5        		push	hl
2403    0B1B  DDE5      		push	ix
2404    0B1D  C1        		pop	bc
2405    0B1E  21EAFF    		ld	hl,65514
2406    0B21  09        		add	hl,bc
2407    0B22  E5        		push	hl
2408    0B23  DDE5      		push	ix
2409    0B25  C1        		pop	bc
2410    0B26  21EFFF    		ld	hl,65519
2411    0B29  09        		add	hl,bc
2412    0B2A  CD7501    		call	_sdcommand
2413    0B2D  F1        		pop	af
2414    0B2E  F1        		pop	af
2415    0B2F  DD71E8    		ld	(ix-24),c
2416    0B32  DD70E9    		ld	(ix-23),b
2417                    	;  415      if (sdtestflg)
2418    0B35  2A0000    		ld	hl,(_sdtestflg)
2419    0B38  7C        		ld	a,h
2420    0B39  B5        		or	l
2421    0B3A  2821      		jr	z,L1711
2422                    	;  416          {
2423                    	;  417          if (!statptr)
2424    0B3C  DD7EE8    		ld	a,(ix-24)
2425    0B3F  DDB6E9    		or	(ix-23)
2426    0B42  2008      		jr	nz,L1021
2427                    	;  418              printf("CMD10: no response\n");
2428    0B44  219704    		ld	hl,L542
2429    0B47  CD0000    		call	_printf
2430                    	;  419          else
2431    0B4A  1811      		jr	L1711
2432                    	L1021:
2433                    	;  420              printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
2434    0B4C  DD6EE8    		ld	l,(ix-24)
2435    0B4F  DD66E9    		ld	h,(ix-23)
2436    0B52  4E        		ld	c,(hl)
2437    0B53  97        		sub	a
2438    0B54  47        		ld	b,a
2439    0B55  C5        		push	bc
2440    0B56  21AB04    		ld	hl,L552
2441    0B59  CD0000    		call	_printf
2442    0B5C  F1        		pop	af
2443                    	L1711:
2444                    	;  421          } /* sdtestflg */
2445                    	;  422      if (!statptr)
2446    0B5D  DD7EE8    		ld	a,(ix-24)
2447    0B60  DDB6E9    		or	(ix-23)
2448    0B63  200C      		jr	nz,L1221
2449                    	;  423          {
2450                    	;  424          spideselect();
2451    0B65  CD0000    		call	_spideselect
2452                    	;  425          ledoff();
2453    0B68  CD0000    		call	_ledoff
2454                    	;  426          return (NO);
2455    0B6B  010000    		ld	bc,0
2456    0B6E  C30000    		jp	c.rets0
2457                    	L1221:
2458                    	;  427          }
2459                    	;  428      /* looking for 0xfe that is the byte before data */
2460                    	;  429      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2461    0B71  DD36F614  		ld	(ix-10),20
2462    0B75  DD36F700  		ld	(ix-9),0
2463                    	L1321:
2464    0B79  97        		sub	a
2465    0B7A  DD96F6    		sub	(ix-10)
2466    0B7D  3E00      		ld	a,0
2467    0B7F  DD9EF7    		sbc	a,(ix-9)
2468    0B82  F2A40B    		jp	p,L1421
2469    0B85  21FF00    		ld	hl,255
2470    0B88  CD0000    		call	_spiio
2471    0B8B  79        		ld	a,c
2472    0B8C  FEFE      		cp	254
2473    0B8E  2003      		jr	nz,L43
2474    0B90  78        		ld	a,b
2475    0B91  FE00      		cp	0
2476                    	L43:
2477    0B93  280F      		jr	z,L1421
2478                    	L1521:
2479    0B95  DD6EF6    		ld	l,(ix-10)
2480    0B98  DD66F7    		ld	h,(ix-9)
2481    0B9B  2B        		dec	hl
2482    0B9C  DD75F6    		ld	(ix-10),l
2483    0B9F  DD74F7    		ld	(ix-9),h
2484    0BA2  18D5      		jr	L1321
2485                    	L1421:
2486                    	;  430          ;
2487                    	;  431      if (tries == 0) /* tried too many times */
2488    0BA4  DD7EF6    		ld	a,(ix-10)
2489    0BA7  DDB6F7    		or	(ix-9)
2490    0BAA  2019      		jr	nz,L1721
2491                    	;  432          {
2492                    	;  433          if (sdtestflg)
2493    0BAC  2A0000    		ld	hl,(_sdtestflg)
2494    0BAF  7C        		ld	a,h
2495    0BB0  B5        		or	l
2496    0BB1  2806      		jr	z,L1031
2497                    	;  434              {
2498                    	;  435              printf("  No data found\n");
2499    0BB3  21D004    		ld	hl,L562
2500    0BB6  CD0000    		call	_printf
2501                    	L1031:
2502                    	;  436              } /* sdtestflg */
2503                    	;  437          spideselect();
2504    0BB9  CD0000    		call	_spideselect
2505                    	;  438          ledoff();
2506    0BBC  CD0000    		call	_ledoff
2507                    	;  439          return (NO);
2508    0BBF  010000    		ld	bc,0
2509    0BC2  C30000    		jp	c.rets0
2510                    	L1721:
2511                    	;  440          }
2512                    	;  441      else
2513                    	;  442          {
2514                    	;  443          crc = 0;
2515    0BC5  DD36E700  		ld	(ix-25),0
2516                    	;  444          for (nbytes = 0; nbytes < 15; nbytes++)
2517    0BC9  DD36F800  		ld	(ix-8),0
2518    0BCD  DD36F900  		ld	(ix-7),0
2519                    	L1231:
2520    0BD1  DD7EF8    		ld	a,(ix-8)
2521    0BD4  D60F      		sub	15
2522    0BD6  DD7EF9    		ld	a,(ix-7)
2523    0BD9  DE00      		sbc	a,0
2524    0BDB  F2110C    		jp	p,L1331
2525                    	;  445              {
2526                    	;  446              rbyte = spiio(0xff);
2527    0BDE  21FF00    		ld	hl,255
2528    0BE1  CD0000    		call	_spiio
2529    0BE4  DD71E6    		ld	(ix-26),c
2530                    	;  447              cidreg[nbytes] = rbyte;
2531    0BE7  213800    		ld	hl,_cidreg
2532    0BEA  DD4EF8    		ld	c,(ix-8)
2533    0BED  DD46F9    		ld	b,(ix-7)
2534    0BF0  09        		add	hl,bc
2535    0BF1  DD7EE6    		ld	a,(ix-26)
2536    0BF4  77        		ld	(hl),a
2537                    	;  448              crc = CRC7_one(crc, rbyte);
2538    0BF5  DD6EE6    		ld	l,(ix-26)
2539    0BF8  97        		sub	a
2540    0BF9  67        		ld	h,a
2541    0BFA  E5        		push	hl
2542    0BFB  DD6EE7    		ld	l,(ix-25)
2543    0BFE  97        		sub	a
2544    0BFF  67        		ld	h,a
2545    0C00  CD6500    		call	_CRC7_one
2546    0C03  F1        		pop	af
2547    0C04  DD71E7    		ld	(ix-25),c
2548                    	;  449              }
2549    0C07  DD34F8    		inc	(ix-8)
2550    0C0A  2003      		jr	nz,L63
2551    0C0C  DD34F9    		inc	(ix-7)
2552                    	L63:
2553    0C0F  18C0      		jr	L1231
2554                    	L1331:
2555                    	;  450          cidreg[15] = spiio(0xff);
2556    0C11  21FF00    		ld	hl,255
2557    0C14  CD0000    		call	_spiio
2558    0C17  79        		ld	a,c
2559    0C18  324700    		ld	(_cidreg+15),a
2560                    	;  451          crc |= 0x01;
2561    0C1B  DDCBE7C6  		set	0,(ix-25)
2562                    	;  452          /* some SD cards need additional clock pulses */
2563                    	;  453          for (nbytes = 9; 0 < nbytes; nbytes--)
2564    0C1F  DD36F809  		ld	(ix-8),9
2565    0C23  DD36F900  		ld	(ix-7),0
2566                    	L1631:
2567    0C27  97        		sub	a
2568    0C28  DD96F8    		sub	(ix-8)
2569    0C2B  3E00      		ld	a,0
2570    0C2D  DD9EF9    		sbc	a,(ix-7)
2571    0C30  F2480C    		jp	p,L1731
2572                    	;  454              spiio(0xff);
2573    0C33  21FF00    		ld	hl,255
2574    0C36  CD0000    		call	_spiio
2575    0C39  DD6EF8    		ld	l,(ix-8)
2576    0C3C  DD66F9    		ld	h,(ix-7)
2577    0C3F  2B        		dec	hl
2578    0C40  DD75F8    		ld	(ix-8),l
2579    0C43  DD74F9    		ld	(ix-7),h
2580    0C46  18DF      		jr	L1631
2581                    	L1731:
2582                    	;  455          if (sdtestflg)
2583    0C48  2A0000    		ld	hl,(_sdtestflg)
2584    0C4B  7C        		ld	a,h
2585    0C4C  B5        		or	l
2586    0C4D  CA2A0D    		jp	z,L1131
2587                    	;  456              {
2588                    	;  457              prtptr = &cidreg[0];
2589    0C50  213800    		ld	hl,_cidreg
2590    0C53  DD75E4    		ld	(ix-28),l
2591    0C56  DD74E5    		ld	(ix-27),h
2592                    	;  458              printf("  CID: [");
2593    0C59  21E104    		ld	hl,L572
2594    0C5C  CD0000    		call	_printf
2595                    	;  459              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2596    0C5F  DD36F800  		ld	(ix-8),0
2597    0C63  DD36F900  		ld	(ix-7),0
2598                    	L1341:
2599    0C67  DD7EF8    		ld	a,(ix-8)
2600    0C6A  D610      		sub	16
2601    0C6C  DD7EF9    		ld	a,(ix-7)
2602    0C6F  DE00      		sbc	a,0
2603    0C71  F2970C    		jp	p,L1441
2604                    	;  460                  printf("%02x ", *prtptr);
2605    0C74  DD6EE4    		ld	l,(ix-28)
2606    0C77  DD66E5    		ld	h,(ix-27)
2607    0C7A  4E        		ld	c,(hl)
2608    0C7B  97        		sub	a
2609    0C7C  47        		ld	b,a
2610    0C7D  C5        		push	bc
2611    0C7E  21EA04    		ld	hl,L503
2612    0C81  CD0000    		call	_printf
2613    0C84  F1        		pop	af
2614    0C85  DD34F8    		inc	(ix-8)
2615    0C88  2003      		jr	nz,L04
2616    0C8A  DD34F9    		inc	(ix-7)
2617                    	L04:
2618    0C8D  DD34E4    		inc	(ix-28)
2619    0C90  2003      		jr	nz,L24
2620    0C92  DD34E5    		inc	(ix-27)
2621                    	L24:
2622    0C95  18D0      		jr	L1341
2623                    	L1441:
2624                    	;  461              prtptr = &cidreg[0];
2625    0C97  213800    		ld	hl,_cidreg
2626    0C9A  DD75E4    		ld	(ix-28),l
2627    0C9D  DD74E5    		ld	(ix-27),h
2628                    	;  462              printf("\b] |");
2629    0CA0  21F004    		ld	hl,L513
2630    0CA3  CD0000    		call	_printf
2631                    	;  463              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2632    0CA6  DD36F800  		ld	(ix-8),0
2633    0CAA  DD36F900  		ld	(ix-7),0
2634                    	L1741:
2635    0CAE  DD7EF8    		ld	a,(ix-8)
2636    0CB1  D610      		sub	16
2637    0CB3  DD7EF9    		ld	a,(ix-7)
2638    0CB6  DE00      		sbc	a,0
2639    0CB8  F2F70C    		jp	p,L1051
2640                    	;  464                  {
2641                    	;  465                  if ((' ' <= *prtptr) && (*prtptr < 127))
2642    0CBB  DD6EE4    		ld	l,(ix-28)
2643    0CBE  DD66E5    		ld	h,(ix-27)
2644    0CC1  7E        		ld	a,(hl)
2645    0CC2  FE20      		cp	32
2646    0CC4  3819      		jr	c,L1351
2647    0CC6  DD6EE4    		ld	l,(ix-28)
2648    0CC9  DD66E5    		ld	h,(ix-27)
2649    0CCC  7E        		ld	a,(hl)
2650    0CCD  FE7F      		cp	127
2651    0CCF  300E      		jr	nc,L1351
2652                    	;  466                      putchar(*prtptr);
2653    0CD1  DD6EE4    		ld	l,(ix-28)
2654    0CD4  DD66E5    		ld	h,(ix-27)
2655    0CD7  6E        		ld	l,(hl)
2656    0CD8  97        		sub	a
2657    0CD9  67        		ld	h,a
2658    0CDA  CD0000    		call	_putchar
2659                    	;  467                  else
2660    0CDD  1806      		jr	L1151
2661                    	L1351:
2662                    	;  468                      putchar('.');
2663    0CDF  212E00    		ld	hl,46
2664    0CE2  CD0000    		call	_putchar
2665                    	L1151:
2666    0CE5  DD34F8    		inc	(ix-8)
2667    0CE8  2003      		jr	nz,L44
2668    0CEA  DD34F9    		inc	(ix-7)
2669                    	L44:
2670    0CED  DD34E4    		inc	(ix-28)
2671    0CF0  2003      		jr	nz,L64
2672    0CF2  DD34E5    		inc	(ix-27)
2673                    	L64:
2674    0CF5  18B7      		jr	L1741
2675                    	L1051:
2676                    	;  469                  }
2677                    	;  470              printf("|\n");
2678    0CF7  21F504    		ld	hl,L523
2679    0CFA  CD0000    		call	_printf
2680                    	;  471              if (crc == cidreg[15])
2681    0CFD  214700    		ld	hl,_cidreg+15
2682    0D00  DD7EE7    		ld	a,(ix-25)
2683    0D03  BE        		cp	(hl)
2684    0D04  200F      		jr	nz,L1551
2685                    	;  472                  {
2686                    	;  473                  printf("CRC7 ok: [%02x]\n", crc);
2687    0D06  DD4EE7    		ld	c,(ix-25)
2688    0D09  97        		sub	a
2689    0D0A  47        		ld	b,a
2690    0D0B  C5        		push	bc
2691    0D0C  21F804    		ld	hl,L533
2692    0D0F  CD0000    		call	_printf
2693    0D12  F1        		pop	af
2694                    	;  474                  }
2695                    	;  475              else
2696    0D13  1815      		jr	L1131
2697                    	L1551:
2698                    	;  476                  {
2699                    	;  477                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2700                    	;  478                         crc, cidreg[15]);
2701    0D15  3A4700    		ld	a,(_cidreg+15)
2702    0D18  4F        		ld	c,a
2703    0D19  97        		sub	a
2704    0D1A  47        		ld	b,a
2705    0D1B  C5        		push	bc
2706    0D1C  DD4EE7    		ld	c,(ix-25)
2707    0D1F  97        		sub	a
2708    0D20  47        		ld	b,a
2709    0D21  C5        		push	bc
2710    0D22  210905    		ld	hl,L543
2711    0D25  CD0000    		call	_printf
2712    0D28  F1        		pop	af
2713    0D29  F1        		pop	af
2714                    	L1131:
2715                    	;  479                  /* could maybe return failure here */
2716                    	;  480                  }
2717                    	;  481              } /* sdtestflg */
2718                    	;  482          }
2719                    	;  483  
2720                    	;  484      /* CMD9: SEND_CSD */
2721                    	;  485      memcpy(cmdbuf, cmd9, 5);
2722    0D2A  210500    		ld	hl,5
2723    0D2D  E5        		push	hl
2724    0D2E  212300    		ld	hl,_cmd9
2725    0D31  E5        		push	hl
2726    0D32  DDE5      		push	ix
2727    0D34  C1        		pop	bc
2728    0D35  21EFFF    		ld	hl,65519
2729    0D38  09        		add	hl,bc
2730    0D39  CD0000    		call	_memcpy
2731    0D3C  F1        		pop	af
2732    0D3D  F1        		pop	af
2733                    	;  486      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2734    0D3E  210100    		ld	hl,1
2735    0D41  E5        		push	hl
2736    0D42  DDE5      		push	ix
2737    0D44  C1        		pop	bc
2738    0D45  21EAFF    		ld	hl,65514
2739    0D48  09        		add	hl,bc
2740    0D49  E5        		push	hl
2741    0D4A  DDE5      		push	ix
2742    0D4C  C1        		pop	bc
2743    0D4D  21EFFF    		ld	hl,65519
2744    0D50  09        		add	hl,bc
2745    0D51  CD7501    		call	_sdcommand
2746    0D54  F1        		pop	af
2747    0D55  F1        		pop	af
2748    0D56  DD71E8    		ld	(ix-24),c
2749    0D59  DD70E9    		ld	(ix-23),b
2750                    	;  487      if (sdtestflg)
2751    0D5C  2A0000    		ld	hl,(_sdtestflg)
2752    0D5F  7C        		ld	a,h
2753    0D60  B5        		or	l
2754    0D61  2821      		jr	z,L1751
2755                    	;  488          {
2756                    	;  489          if (!statptr)
2757    0D63  DD7EE8    		ld	a,(ix-24)
2758    0D66  DDB6E9    		or	(ix-23)
2759    0D69  2008      		jr	nz,L1061
2760                    	;  490              printf("CMD9: no response\n");
2761    0D6B  213B05    		ld	hl,L553
2762    0D6E  CD0000    		call	_printf
2763                    	;  491          else
2764    0D71  1811      		jr	L1751
2765                    	L1061:
2766                    	;  492              printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
2767    0D73  DD6EE8    		ld	l,(ix-24)
2768    0D76  DD66E9    		ld	h,(ix-23)
2769    0D79  4E        		ld	c,(hl)
2770    0D7A  97        		sub	a
2771    0D7B  47        		ld	b,a
2772    0D7C  C5        		push	bc
2773    0D7D  214E05    		ld	hl,L563
2774    0D80  CD0000    		call	_printf
2775    0D83  F1        		pop	af
2776                    	L1751:
2777                    	;  493          } /* sdtestflg */
2778                    	;  494      if (!statptr)
2779    0D84  DD7EE8    		ld	a,(ix-24)
2780    0D87  DDB6E9    		or	(ix-23)
2781    0D8A  200C      		jr	nz,L1261
2782                    	;  495          {
2783                    	;  496          spideselect();
2784    0D8C  CD0000    		call	_spideselect
2785                    	;  497          ledoff();
2786    0D8F  CD0000    		call	_ledoff
2787                    	;  498          return (NO);
2788    0D92  010000    		ld	bc,0
2789    0D95  C30000    		jp	c.rets0
2790                    	L1261:
2791                    	;  499          }
2792                    	;  500      /* looking for 0xfe that is the byte before data */
2793                    	;  501      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2794    0D98  DD36F614  		ld	(ix-10),20
2795    0D9C  DD36F700  		ld	(ix-9),0
2796                    	L1361:
2797    0DA0  97        		sub	a
2798    0DA1  DD96F6    		sub	(ix-10)
2799    0DA4  3E00      		ld	a,0
2800    0DA6  DD9EF7    		sbc	a,(ix-9)
2801    0DA9  F2CB0D    		jp	p,L1461
2802    0DAC  21FF00    		ld	hl,255
2803    0DAF  CD0000    		call	_spiio
2804    0DB2  79        		ld	a,c
2805    0DB3  FEFE      		cp	254
2806    0DB5  2003      		jr	nz,L05
2807    0DB7  78        		ld	a,b
2808    0DB8  FE00      		cp	0
2809                    	L05:
2810    0DBA  280F      		jr	z,L1461
2811                    	L1561:
2812    0DBC  DD6EF6    		ld	l,(ix-10)
2813    0DBF  DD66F7    		ld	h,(ix-9)
2814    0DC2  2B        		dec	hl
2815    0DC3  DD75F6    		ld	(ix-10),l
2816    0DC6  DD74F7    		ld	(ix-9),h
2817    0DC9  18D5      		jr	L1361
2818                    	L1461:
2819                    	;  502          ;
2820                    	;  503      if (tries == 0) /* tried too many times */
2821    0DCB  DD7EF6    		ld	a,(ix-10)
2822    0DCE  DDB6F7    		or	(ix-9)
2823    0DD1  2013      		jr	nz,L1761
2824                    	;  504          {
2825                    	;  505          if (sdtestflg)
2826    0DD3  2A0000    		ld	hl,(_sdtestflg)
2827    0DD6  7C        		ld	a,h
2828    0DD7  B5        		or	l
2829    0DD8  2806      		jr	z,L1071
2830                    	;  506              {
2831                    	;  507              printf("  No data found\n");
2832    0DDA  217205    		ld	hl,L573
2833    0DDD  CD0000    		call	_printf
2834                    	L1071:
2835                    	;  508              } /* sdtestflg */
2836                    	;  509          return (NO);
2837    0DE0  010000    		ld	bc,0
2838    0DE3  C30000    		jp	c.rets0
2839                    	L1761:
2840                    	;  510          }
2841                    	;  511      else
2842                    	;  512          {
2843                    	;  513          crc = 0;
2844    0DE6  DD36E700  		ld	(ix-25),0
2845                    	;  514          for (nbytes = 0; nbytes < 15; nbytes++)
2846    0DEA  DD36F800  		ld	(ix-8),0
2847    0DEE  DD36F900  		ld	(ix-7),0
2848                    	L1271:
2849    0DF2  DD7EF8    		ld	a,(ix-8)
2850    0DF5  D60F      		sub	15
2851    0DF7  DD7EF9    		ld	a,(ix-7)
2852    0DFA  DE00      		sbc	a,0
2853    0DFC  F2320E    		jp	p,L1371
2854                    	;  515              {
2855                    	;  516              rbyte = spiio(0xff);
2856    0DFF  21FF00    		ld	hl,255
2857    0E02  CD0000    		call	_spiio
2858    0E05  DD71E6    		ld	(ix-26),c
2859                    	;  517              csdreg[nbytes] = rbyte;
2860    0E08  212800    		ld	hl,_csdreg
2861    0E0B  DD4EF8    		ld	c,(ix-8)
2862    0E0E  DD46F9    		ld	b,(ix-7)
2863    0E11  09        		add	hl,bc
2864    0E12  DD7EE6    		ld	a,(ix-26)
2865    0E15  77        		ld	(hl),a
2866                    	;  518              crc = CRC7_one(crc, rbyte);
2867    0E16  DD6EE6    		ld	l,(ix-26)
2868    0E19  97        		sub	a
2869    0E1A  67        		ld	h,a
2870    0E1B  E5        		push	hl
2871    0E1C  DD6EE7    		ld	l,(ix-25)
2872    0E1F  97        		sub	a
2873    0E20  67        		ld	h,a
2874    0E21  CD6500    		call	_CRC7_one
2875    0E24  F1        		pop	af
2876    0E25  DD71E7    		ld	(ix-25),c
2877                    	;  519              }
2878    0E28  DD34F8    		inc	(ix-8)
2879    0E2B  2003      		jr	nz,L25
2880    0E2D  DD34F9    		inc	(ix-7)
2881                    	L25:
2882    0E30  18C0      		jr	L1271
2883                    	L1371:
2884                    	;  520          csdreg[15] = spiio(0xff);
2885    0E32  21FF00    		ld	hl,255
2886    0E35  CD0000    		call	_spiio
2887    0E38  79        		ld	a,c
2888    0E39  323700    		ld	(_csdreg+15),a
2889                    	;  521          crc |= 0x01;
2890    0E3C  DDCBE7C6  		set	0,(ix-25)
2891                    	;  522          /* some SD cards need additional clock pulses */
2892                    	;  523          for (nbytes = 9; 0 < nbytes; nbytes--)
2893    0E40  DD36F809  		ld	(ix-8),9
2894    0E44  DD36F900  		ld	(ix-7),0
2895                    	L1671:
2896    0E48  97        		sub	a
2897    0E49  DD96F8    		sub	(ix-8)
2898    0E4C  3E00      		ld	a,0
2899    0E4E  DD9EF9    		sbc	a,(ix-7)
2900    0E51  F2690E    		jp	p,L1771
2901                    	;  524              spiio(0xff);
2902    0E54  21FF00    		ld	hl,255
2903    0E57  CD0000    		call	_spiio
2904    0E5A  DD6EF8    		ld	l,(ix-8)
2905    0E5D  DD66F9    		ld	h,(ix-7)
2906    0E60  2B        		dec	hl
2907    0E61  DD75F8    		ld	(ix-8),l
2908    0E64  DD74F9    		ld	(ix-7),h
2909    0E67  18DF      		jr	L1671
2910                    	L1771:
2911                    	;  525          if (sdtestflg)
2912    0E69  2A0000    		ld	hl,(_sdtestflg)
2913    0E6C  7C        		ld	a,h
2914    0E6D  B5        		or	l
2915    0E6E  CA4B0F    		jp	z,L1171
2916                    	;  526              {
2917                    	;  527              prtptr = &csdreg[0];
2918    0E71  212800    		ld	hl,_csdreg
2919    0E74  DD75E4    		ld	(ix-28),l
2920    0E77  DD74E5    		ld	(ix-27),h
2921                    	;  528              printf("  CSD: [");
2922    0E7A  218305    		ld	hl,L504
2923    0E7D  CD0000    		call	_printf
2924                    	;  529              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2925    0E80  DD36F800  		ld	(ix-8),0
2926    0E84  DD36F900  		ld	(ix-7),0
2927                    	L1302:
2928    0E88  DD7EF8    		ld	a,(ix-8)
2929    0E8B  D610      		sub	16
2930    0E8D  DD7EF9    		ld	a,(ix-7)
2931    0E90  DE00      		sbc	a,0
2932    0E92  F2B80E    		jp	p,L1402
2933                    	;  530                  printf("%02x ", *prtptr);
2934    0E95  DD6EE4    		ld	l,(ix-28)
2935    0E98  DD66E5    		ld	h,(ix-27)
2936    0E9B  4E        		ld	c,(hl)
2937    0E9C  97        		sub	a
2938    0E9D  47        		ld	b,a
2939    0E9E  C5        		push	bc
2940    0E9F  218C05    		ld	hl,L514
2941    0EA2  CD0000    		call	_printf
2942    0EA5  F1        		pop	af
2943    0EA6  DD34F8    		inc	(ix-8)
2944    0EA9  2003      		jr	nz,L45
2945    0EAB  DD34F9    		inc	(ix-7)
2946                    	L45:
2947    0EAE  DD34E4    		inc	(ix-28)
2948    0EB1  2003      		jr	nz,L65
2949    0EB3  DD34E5    		inc	(ix-27)
2950                    	L65:
2951    0EB6  18D0      		jr	L1302
2952                    	L1402:
2953                    	;  531              prtptr = &csdreg[0];
2954    0EB8  212800    		ld	hl,_csdreg
2955    0EBB  DD75E4    		ld	(ix-28),l
2956    0EBE  DD74E5    		ld	(ix-27),h
2957                    	;  532              printf("\b] |");
2958    0EC1  219205    		ld	hl,L524
2959    0EC4  CD0000    		call	_printf
2960                    	;  533              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2961    0EC7  DD36F800  		ld	(ix-8),0
2962    0ECB  DD36F900  		ld	(ix-7),0
2963                    	L1702:
2964    0ECF  DD7EF8    		ld	a,(ix-8)
2965    0ED2  D610      		sub	16
2966    0ED4  DD7EF9    		ld	a,(ix-7)
2967    0ED7  DE00      		sbc	a,0
2968    0ED9  F2180F    		jp	p,L1012
2969                    	;  534                  {
2970                    	;  535                  if ((' ' <= *prtptr) && (*prtptr < 127))
2971    0EDC  DD6EE4    		ld	l,(ix-28)
2972    0EDF  DD66E5    		ld	h,(ix-27)
2973    0EE2  7E        		ld	a,(hl)
2974    0EE3  FE20      		cp	32
2975    0EE5  3819      		jr	c,L1312
2976    0EE7  DD6EE4    		ld	l,(ix-28)
2977    0EEA  DD66E5    		ld	h,(ix-27)
2978    0EED  7E        		ld	a,(hl)
2979    0EEE  FE7F      		cp	127
2980    0EF0  300E      		jr	nc,L1312
2981                    	;  536                      putchar(*prtptr);
2982    0EF2  DD6EE4    		ld	l,(ix-28)
2983    0EF5  DD66E5    		ld	h,(ix-27)
2984    0EF8  6E        		ld	l,(hl)
2985    0EF9  97        		sub	a
2986    0EFA  67        		ld	h,a
2987    0EFB  CD0000    		call	_putchar
2988                    	;  537                  else
2989    0EFE  1806      		jr	L1112
2990                    	L1312:
2991                    	;  538                      putchar('.');
2992    0F00  212E00    		ld	hl,46
2993    0F03  CD0000    		call	_putchar
2994                    	L1112:
2995    0F06  DD34F8    		inc	(ix-8)
2996    0F09  2003      		jr	nz,L06
2997    0F0B  DD34F9    		inc	(ix-7)
2998                    	L06:
2999    0F0E  DD34E4    		inc	(ix-28)
3000    0F11  2003      		jr	nz,L26
3001    0F13  DD34E5    		inc	(ix-27)
3002                    	L26:
3003    0F16  18B7      		jr	L1702
3004                    	L1012:
3005                    	;  539                  }
3006                    	;  540              printf("|\n");
3007    0F18  219705    		ld	hl,L534
3008    0F1B  CD0000    		call	_printf
3009                    	;  541              if (crc == csdreg[15])
3010    0F1E  213700    		ld	hl,_csdreg+15
3011    0F21  DD7EE7    		ld	a,(ix-25)
3012    0F24  BE        		cp	(hl)
3013    0F25  200F      		jr	nz,L1512
3014                    	;  542                  {
3015                    	;  543                  printf("CRC7 ok: [%02x]\n", crc);
3016    0F27  DD4EE7    		ld	c,(ix-25)
3017    0F2A  97        		sub	a
3018    0F2B  47        		ld	b,a
3019    0F2C  C5        		push	bc
3020    0F2D  219A05    		ld	hl,L544
3021    0F30  CD0000    		call	_printf
3022    0F33  F1        		pop	af
3023                    	;  544                  }
3024                    	;  545              else
3025    0F34  1815      		jr	L1171
3026                    	L1512:
3027                    	;  546                  {
3028                    	;  547                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
3029                    	;  548                         crc, csdreg[15]);
3030    0F36  3A3700    		ld	a,(_csdreg+15)
3031    0F39  4F        		ld	c,a
3032    0F3A  97        		sub	a
3033    0F3B  47        		ld	b,a
3034    0F3C  C5        		push	bc
3035    0F3D  DD4EE7    		ld	c,(ix-25)
3036    0F40  97        		sub	a
3037    0F41  47        		ld	b,a
3038    0F42  C5        		push	bc
3039    0F43  21AB05    		ld	hl,L554
3040    0F46  CD0000    		call	_printf
3041    0F49  F1        		pop	af
3042    0F4A  F1        		pop	af
3043                    	L1171:
3044                    	;  549                  /* could maybe return failure here */
3045                    	;  550                  }
3046                    	;  551              } /* sdtestflg */
3047                    	;  552          }
3048                    	;  553  
3049                    	;  554      for (nbytes = 9; 0 < nbytes; nbytes--)
3050    0F4B  DD36F809  		ld	(ix-8),9
3051    0F4F  DD36F900  		ld	(ix-7),0
3052                    	L1712:
3053    0F53  97        		sub	a
3054    0F54  DD96F8    		sub	(ix-8)
3055    0F57  3E00      		ld	a,0
3056    0F59  DD9EF9    		sbc	a,(ix-7)
3057    0F5C  F2740F    		jp	p,L1022
3058                    	;  555          spiio(0xff);
3059    0F5F  21FF00    		ld	hl,255
3060    0F62  CD0000    		call	_spiio
3061    0F65  DD6EF8    		ld	l,(ix-8)
3062    0F68  DD66F9    		ld	h,(ix-7)
3063    0F6B  2B        		dec	hl
3064    0F6C  DD75F8    		ld	(ix-8),l
3065    0F6F  DD74F9    		ld	(ix-7),h
3066    0F72  18DF      		jr	L1712
3067                    	L1022:
3068                    	;  556      if (sdtestflg)
3069    0F74  2A0000    		ld	hl,(_sdtestflg)
3070    0F77  7C        		ld	a,h
3071    0F78  B5        		or	l
3072    0F79  2806      		jr	z,L1322
3073                    	;  557          {
3074                    	;  558          printf("Sent 9*8 (72) clock pulses, select active\n");
3075    0F7B  21DD05    		ld	hl,L564
3076    0F7E  CD0000    		call	_printf
3077                    	L1322:
3078                    	;  559          } /* sdtestflg */
3079                    	;  560  
3080                    	;  561      sdinitok = YES;
3081    0F81  210100    		ld	hl,1
3082    0F84  220C00    		ld	(_sdinitok),hl
3083                    	;  562  
3084                    	;  563      spideselect();
3085    0F87  CD0000    		call	_spideselect
3086                    	;  564      ledoff();
3087    0F8A  CD0000    		call	_ledoff
3088                    	;  565  
3089                    	;  566      return (YES);
3090    0F8D  010100    		ld	bc,1
3091    0F90  C30000    		jp	c.rets0
3092                    	L574:
3093    0F93  43        		.byte	67
3094    0F94  4D        		.byte	77
3095    0F95  44        		.byte	68
3096    0F96  35        		.byte	53
3097    0F97  38        		.byte	56
3098    0F98  3A        		.byte	58
3099    0F99  20        		.byte	32
3100    0F9A  6E        		.byte	110
3101    0F9B  6F        		.byte	111
3102    0F9C  20        		.byte	32
3103    0F9D  72        		.byte	114
3104    0F9E  65        		.byte	101
3105    0F9F  73        		.byte	115
3106    0FA0  70        		.byte	112
3107    0FA1  6F        		.byte	111
3108    0FA2  6E        		.byte	110
3109    0FA3  73        		.byte	115
3110    0FA4  65        		.byte	101
3111    0FA5  0A        		.byte	10
3112    0FA6  00        		.byte	0
3113                    	L505:
3114    0FA7  43        		.byte	67
3115    0FA8  4D        		.byte	77
3116    0FA9  44        		.byte	68
3117    0FAA  35        		.byte	53
3118    0FAB  38        		.byte	56
3119    0FAC  3A        		.byte	58
3120    0FAD  20        		.byte	32
3121    0FAE  52        		.byte	82
3122    0FAF  45        		.byte	69
3123    0FB0  41        		.byte	65
3124    0FB1  44        		.byte	68
3125    0FB2  5F        		.byte	95
3126    0FB3  4F        		.byte	79
3127    0FB4  43        		.byte	67
3128    0FB5  52        		.byte	82
3129    0FB6  2C        		.byte	44
3130    0FB7  20        		.byte	32
3131    0FB8  52        		.byte	82
3132    0FB9  33        		.byte	51
3133    0FBA  20        		.byte	32
3134    0FBB  72        		.byte	114
3135    0FBC  65        		.byte	101
3136    0FBD  73        		.byte	115
3137    0FBE  70        		.byte	112
3138    0FBF  6F        		.byte	111
3139    0FC0  6E        		.byte	110
3140    0FC1  73        		.byte	115
3141    0FC2  65        		.byte	101
3142    0FC3  20        		.byte	32
3143    0FC4  5B        		.byte	91
3144    0FC5  25        		.byte	37
3145    0FC6  30        		.byte	48
3146    0FC7  32        		.byte	50
3147    0FC8  78        		.byte	120
3148    0FC9  20        		.byte	32
3149    0FCA  25        		.byte	37
3150    0FCB  30        		.byte	48
3151    0FCC  32        		.byte	50
3152    0FCD  78        		.byte	120
3153    0FCE  20        		.byte	32
3154    0FCF  25        		.byte	37
3155    0FD0  30        		.byte	48
3156    0FD1  32        		.byte	50
3157    0FD2  78        		.byte	120
3158    0FD3  20        		.byte	32
3159    0FD4  25        		.byte	37
3160    0FD5  30        		.byte	48
3161    0FD6  32        		.byte	50
3162    0FD7  78        		.byte	120
3163    0FD8  20        		.byte	32
3164    0FD9  25        		.byte	37
3165    0FDA  30        		.byte	48
3166    0FDB  32        		.byte	50
3167    0FDC  78        		.byte	120
3168    0FDD  5D        		.byte	93
3169    0FDE  0A        		.byte	10
3170    0FDF  00        		.byte	0
3171                    	L515:
3172    0FE0  53        		.byte	83
3173    0FE1  44        		.byte	68
3174    0FE2  20        		.byte	32
3175    0FE3  63        		.byte	99
3176    0FE4  61        		.byte	97
3177    0FE5  72        		.byte	114
3178    0FE6  64        		.byte	100
3179    0FE7  20        		.byte	32
3180    0FE8  6E        		.byte	110
3181    0FE9  6F        		.byte	111
3182    0FEA  74        		.byte	116
3183    0FEB  20        		.byte	32
3184    0FEC  69        		.byte	105
3185    0FED  6E        		.byte	110
3186    0FEE  73        		.byte	115
3187    0FEF  65        		.byte	101
3188    0FF0  72        		.byte	114
3189    0FF1  74        		.byte	116
3190    0FF2  65        		.byte	101
3191    0FF3  64        		.byte	100
3192    0FF4  20        		.byte	32
3193    0FF5  6F        		.byte	111
3194    0FF6  72        		.byte	114
3195    0FF7  20        		.byte	32
3196    0FF8  6E        		.byte	110
3197    0FF9  6F        		.byte	111
3198    0FFA  74        		.byte	116
3199    0FFB  20        		.byte	32
3200    0FFC  69        		.byte	105
3201    0FFD  6E        		.byte	110
3202    0FFE  69        		.byte	105
3203    0FFF  74        		.byte	116
3204    1000  69        		.byte	105
3205    1001  61        		.byte	97
3206    1002  6C        		.byte	108
3207    1003  69        		.byte	105
3208    1004  7A        		.byte	122
3209    1005  65        		.byte	101
3210    1006  64        		.byte	100
3211    1007  0A        		.byte	10
3212    1008  00        		.byte	0
3213                    	;  567      }
3214                    	;  568  
3215                    	;  569  int sdprobe()
3216                    	;  570      {
3217                    	_sdprobe:
3218    1009  CD0000    		call	c.savs0
3219    100C  21EAFF    		ld	hl,65514
3220    100F  39        		add	hl,sp
3221    1010  F9        		ld	sp,hl
3222                    	;  571      unsigned char cmdbuf[5];   /* buffer to build command in */
3223                    	;  572      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3224                    	;  573      unsigned char *statptr;    /* pointer to returned status from SD command */
3225                    	;  574      int nbytes;  /* byte counter */
3226                    	;  575      int allzero = YES;
3227    1011  DD36EA01  		ld	(ix-22),1
3228    1015  DD36EB00  		ld	(ix-21),0
3229                    	;  576  
3230                    	;  577      ledon();
3231    1019  CD0000    		call	_ledon
3232                    	;  578      spiselect();
3233    101C  CD0000    		call	_spiselect
3234                    	;  579  
3235                    	;  580      /* CMD58: READ_OCR */
3236                    	;  581      memcpy(cmdbuf, cmd58, 5);
3237    101F  210500    		ld	hl,5
3238    1022  E5        		push	hl
3239    1023  214700    		ld	hl,_cmd58
3240    1026  E5        		push	hl
3241    1027  DDE5      		push	ix
3242    1029  C1        		pop	bc
3243    102A  21F5FF    		ld	hl,65525
3244    102D  09        		add	hl,bc
3245    102E  CD0000    		call	_memcpy
3246    1031  F1        		pop	af
3247    1032  F1        		pop	af
3248                    	;  582      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
3249    1033  210500    		ld	hl,5
3250    1036  E5        		push	hl
3251    1037  DDE5      		push	ix
3252    1039  C1        		pop	bc
3253    103A  21F0FF    		ld	hl,65520
3254    103D  09        		add	hl,bc
3255    103E  E5        		push	hl
3256    103F  DDE5      		push	ix
3257    1041  C1        		pop	bc
3258    1042  21F5FF    		ld	hl,65525
3259    1045  09        		add	hl,bc
3260    1046  CD7501    		call	_sdcommand
3261    1049  F1        		pop	af
3262    104A  F1        		pop	af
3263    104B  DD71EE    		ld	(ix-18),c
3264    104E  DD70EF    		ld	(ix-17),b
3265                    	;  583      for (nbytes = 0; nbytes < 5; nbytes++)
3266    1051  DD36EC00  		ld	(ix-20),0
3267    1055  DD36ED00  		ld	(ix-19),0
3268                    	L1422:
3269    1059  DD7EEC    		ld	a,(ix-20)
3270    105C  D605      		sub	5
3271    105E  DD7EED    		ld	a,(ix-19)
3272    1061  DE00      		sbc	a,0
3273    1063  F28910    		jp	p,L1522
3274                    	;  584          {
3275                    	;  585          if (statptr[nbytes] != 0)
3276    1066  DD6EEE    		ld	l,(ix-18)
3277    1069  DD66EF    		ld	h,(ix-17)
3278    106C  DD4EEC    		ld	c,(ix-20)
3279    106F  DD46ED    		ld	b,(ix-19)
3280    1072  09        		add	hl,bc
3281    1073  7E        		ld	a,(hl)
3282    1074  B7        		or	a
3283    1075  2808      		jr	z,L1622
3284                    	;  586              allzero = NO;
3285    1077  DD36EA00  		ld	(ix-22),0
3286    107B  DD36EB00  		ld	(ix-21),0
3287                    	L1622:
3288    107F  DD34EC    		inc	(ix-20)
3289    1082  2003      		jr	nz,L66
3290    1084  DD34ED    		inc	(ix-19)
3291                    	L66:
3292    1087  18D0      		jr	L1422
3293                    	L1522:
3294                    	;  587          }
3295                    	;  588      if (sdtestflg)
3296    1089  2A0000    		ld	hl,(_sdtestflg)
3297    108C  7C        		ld	a,h
3298    108D  B5        		or	l
3299    108E  CAF710    		jp	z,L1132
3300                    	;  589          {
3301                    	;  590          if (!statptr)
3302    1091  DD7EEE    		ld	a,(ix-18)
3303    1094  DDB6EF    		or	(ix-17)
3304    1097  2009      		jr	nz,L1232
3305                    	;  591              printf("CMD58: no response\n");
3306    1099  21930F    		ld	hl,L574
3307    109C  CD0000    		call	_printf
3308                    	;  592          else
3309    109F  C3F710    		jp	L1132
3310                    	L1232:
3311                    	;  593              {
3312                    	;  594              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
3313                    	;  595                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
3314    10A2  DD6EEE    		ld	l,(ix-18)
3315    10A5  DD66EF    		ld	h,(ix-17)
3316    10A8  23        		inc	hl
3317    10A9  23        		inc	hl
3318    10AA  23        		inc	hl
3319    10AB  23        		inc	hl
3320    10AC  4E        		ld	c,(hl)
3321    10AD  97        		sub	a
3322    10AE  47        		ld	b,a
3323    10AF  C5        		push	bc
3324    10B0  DD6EEE    		ld	l,(ix-18)
3325    10B3  DD66EF    		ld	h,(ix-17)
3326    10B6  23        		inc	hl
3327    10B7  23        		inc	hl
3328    10B8  23        		inc	hl
3329    10B9  4E        		ld	c,(hl)
3330    10BA  97        		sub	a
3331    10BB  47        		ld	b,a
3332    10BC  C5        		push	bc
3333    10BD  DD6EEE    		ld	l,(ix-18)
3334    10C0  DD66EF    		ld	h,(ix-17)
3335    10C3  23        		inc	hl
3336    10C4  23        		inc	hl
3337    10C5  4E        		ld	c,(hl)
3338    10C6  97        		sub	a
3339    10C7  47        		ld	b,a
3340    10C8  C5        		push	bc
3341    10C9  DD6EEE    		ld	l,(ix-18)
3342    10CC  DD66EF    		ld	h,(ix-17)
3343    10CF  23        		inc	hl
3344    10D0  4E        		ld	c,(hl)
3345    10D1  97        		sub	a
3346    10D2  47        		ld	b,a
3347    10D3  C5        		push	bc
3348    10D4  DD6EEE    		ld	l,(ix-18)
3349    10D7  DD66EF    		ld	h,(ix-17)
3350    10DA  4E        		ld	c,(hl)
3351    10DB  97        		sub	a
3352    10DC  47        		ld	b,a
3353    10DD  C5        		push	bc
3354    10DE  21A70F    		ld	hl,L505
3355    10E1  CD0000    		call	_printf
3356    10E4  210A00    		ld	hl,10
3357    10E7  39        		add	hl,sp
3358    10E8  F9        		ld	sp,hl
3359                    	;  596              if (allzero)
3360    10E9  DD7EEA    		ld	a,(ix-22)
3361    10EC  DDB6EB    		or	(ix-21)
3362    10EF  2806      		jr	z,L1132
3363                    	;  597                  printf("SD card not inserted or not initialized\n");
3364    10F1  21E00F    		ld	hl,L515
3365    10F4  CD0000    		call	_printf
3366                    	L1132:
3367                    	;  598              }
3368                    	;  599          } /* sdtestflg */
3369                    	;  600      if (!statptr || allzero)
3370    10F7  DD7EEE    		ld	a,(ix-18)
3371    10FA  DDB6EF    		or	(ix-17)
3372    10FD  2808      		jr	z,L1632
3373    10FF  DD7EEA    		ld	a,(ix-22)
3374    1102  DDB6EB    		or	(ix-21)
3375    1105  2812      		jr	z,L1532
3376                    	L1632:
3377                    	;  601          {
3378                    	;  602          sdinitok = NO;
3379    1107  210000    		ld	hl,0
3380    110A  220C00    		ld	(_sdinitok),hl
3381                    	;  603          spideselect();
3382    110D  CD0000    		call	_spideselect
3383                    	;  604          ledoff();
3384    1110  CD0000    		call	_ledoff
3385                    	;  605          return (NO);
3386    1113  010000    		ld	bc,0
3387    1116  C30000    		jp	c.rets0
3388                    	L1532:
3389                    	;  606          }
3390                    	;  607  
3391                    	;  608      spideselect();
3392    1119  CD0000    		call	_spideselect
3393                    	;  609      ledoff();
3394    111C  CD0000    		call	_ledoff
3395                    	;  610  
3396                    	;  611      return (YES);
3397    111F  010100    		ld	bc,1
3398    1122  C30000    		jp	c.rets0
3399                    	L525:
3400    1125  53        		.byte	83
3401    1126  44        		.byte	68
3402    1127  20        		.byte	32
3403    1128  63        		.byte	99
3404    1129  61        		.byte	97
3405    112A  72        		.byte	114
3406    112B  64        		.byte	100
3407    112C  20        		.byte	32
3408    112D  6E        		.byte	110
3409    112E  6F        		.byte	111
3410    112F  74        		.byte	116
3411    1130  20        		.byte	32
3412    1131  69        		.byte	105
3413    1132  6E        		.byte	110
3414    1133  69        		.byte	105
3415    1134  74        		.byte	116
3416    1135  69        		.byte	105
3417    1136  61        		.byte	97
3418    1137  6C        		.byte	108
3419    1138  69        		.byte	105
3420    1139  7A        		.byte	122
3421    113A  65        		.byte	101
3422    113B  64        		.byte	100
3423    113C  0A        		.byte	10
3424    113D  00        		.byte	0
3425                    	L535:
3426    113E  53        		.byte	83
3427    113F  44        		.byte	68
3428    1140  20        		.byte	32
3429    1141  63        		.byte	99
3430    1142  61        		.byte	97
3431    1143  72        		.byte	114
3432    1144  64        		.byte	100
3433    1145  20        		.byte	32
3434    1146  69        		.byte	105
3435    1147  6E        		.byte	110
3436    1148  66        		.byte	102
3437    1149  6F        		.byte	111
3438    114A  72        		.byte	114
3439    114B  6D        		.byte	109
3440    114C  61        		.byte	97
3441    114D  74        		.byte	116
3442    114E  69        		.byte	105
3443    114F  6F        		.byte	111
3444    1150  6E        		.byte	110
3445    1151  3A        		.byte	58
3446    1152  00        		.byte	0
3447                    	L545:
3448    1153  20        		.byte	32
3449    1154  20        		.byte	32
3450    1155  53        		.byte	83
3451    1156  44        		.byte	68
3452    1157  20        		.byte	32
3453    1158  63        		.byte	99
3454    1159  61        		.byte	97
3455    115A  72        		.byte	114
3456    115B  64        		.byte	100
3457    115C  20        		.byte	32
3458    115D  76        		.byte	118
3459    115E  65        		.byte	101
3460    115F  72        		.byte	114
3461    1160  2E        		.byte	46
3462    1161  20        		.byte	32
3463    1162  32        		.byte	50
3464    1163  2B        		.byte	43
3465    1164  2C        		.byte	44
3466    1165  20        		.byte	32
3467    1166  42        		.byte	66
3468    1167  6C        		.byte	108
3469    1168  6F        		.byte	111
3470    1169  63        		.byte	99
3471    116A  6B        		.byte	107
3472    116B  20        		.byte	32
3473    116C  61        		.byte	97
3474    116D  64        		.byte	100
3475    116E  64        		.byte	100
3476    116F  72        		.byte	114
3477    1170  65        		.byte	101
3478    1171  73        		.byte	115
3479    1172  73        		.byte	115
3480    1173  0A        		.byte	10
3481    1174  00        		.byte	0
3482                    	L555:
3483    1175  20        		.byte	32
3484    1176  20        		.byte	32
3485    1177  53        		.byte	83
3486    1178  44        		.byte	68
3487    1179  20        		.byte	32
3488    117A  63        		.byte	99
3489    117B  61        		.byte	97
3490    117C  72        		.byte	114
3491    117D  64        		.byte	100
3492    117E  20        		.byte	32
3493    117F  76        		.byte	118
3494    1180  65        		.byte	101
3495    1181  72        		.byte	114
3496    1182  2E        		.byte	46
3497    1183  20        		.byte	32
3498    1184  32        		.byte	50
3499    1185  2B        		.byte	43
3500    1186  2C        		.byte	44
3501    1187  20        		.byte	32
3502    1188  42        		.byte	66
3503    1189  79        		.byte	121
3504    118A  74        		.byte	116
3505    118B  65        		.byte	101
3506    118C  20        		.byte	32
3507    118D  61        		.byte	97
3508    118E  64        		.byte	100
3509    118F  64        		.byte	100
3510    1190  72        		.byte	114
3511    1191  65        		.byte	101
3512    1192  73        		.byte	115
3513    1193  73        		.byte	115
3514    1194  0A        		.byte	10
3515    1195  00        		.byte	0
3516                    	L565:
3517    1196  20        		.byte	32
3518    1197  20        		.byte	32
3519    1198  53        		.byte	83
3520    1199  44        		.byte	68
3521    119A  20        		.byte	32
3522    119B  63        		.byte	99
3523    119C  61        		.byte	97
3524    119D  72        		.byte	114
3525    119E  64        		.byte	100
3526    119F  20        		.byte	32
3527    11A0  76        		.byte	118
3528    11A1  65        		.byte	101
3529    11A2  72        		.byte	114
3530    11A3  2E        		.byte	46
3531    11A4  20        		.byte	32
3532    11A5  31        		.byte	49
3533    11A6  2C        		.byte	44
3534    11A7  20        		.byte	32
3535    11A8  42        		.byte	66
3536    11A9  79        		.byte	121
3537    11AA  74        		.byte	116
3538    11AB  65        		.byte	101
3539    11AC  20        		.byte	32
3540    11AD  61        		.byte	97
3541    11AE  64        		.byte	100
3542    11AF  64        		.byte	100
3543    11B0  72        		.byte	114
3544    11B1  65        		.byte	101
3545    11B2  73        		.byte	115
3546    11B3  73        		.byte	115
3547    11B4  0A        		.byte	10
3548    11B5  00        		.byte	0
3549                    	L575:
3550    11B6  20        		.byte	32
3551    11B7  20        		.byte	32
3552    11B8  4D        		.byte	77
3553    11B9  61        		.byte	97
3554    11BA  6E        		.byte	110
3555    11BB  75        		.byte	117
3556    11BC  66        		.byte	102
3557    11BD  61        		.byte	97
3558    11BE  63        		.byte	99
3559    11BF  74        		.byte	116
3560    11C0  75        		.byte	117
3561    11C1  72        		.byte	114
3562    11C2  65        		.byte	101
3563    11C3  72        		.byte	114
3564    11C4  20        		.byte	32
3565    11C5  49        		.byte	73
3566    11C6  44        		.byte	68
3567    11C7  3A        		.byte	58
3568    11C8  20        		.byte	32
3569    11C9  30        		.byte	48
3570    11CA  78        		.byte	120
3571    11CB  25        		.byte	37
3572    11CC  30        		.byte	48
3573    11CD  32        		.byte	50
3574    11CE  78        		.byte	120
3575    11CF  2C        		.byte	44
3576    11D0  20        		.byte	32
3577    11D1  00        		.byte	0
3578                    	L506:
3579    11D2  4F        		.byte	79
3580    11D3  45        		.byte	69
3581    11D4  4D        		.byte	77
3582    11D5  20        		.byte	32
3583    11D6  49        		.byte	73
3584    11D7  44        		.byte	68
3585    11D8  3A        		.byte	58
3586    11D9  20        		.byte	32
3587    11DA  25        		.byte	37
3588    11DB  2E        		.byte	46
3589    11DC  32        		.byte	50
3590    11DD  73        		.byte	115
3591    11DE  2C        		.byte	44
3592    11DF  20        		.byte	32
3593    11E0  00        		.byte	0
3594                    	L516:
3595    11E1  50        		.byte	80
3596    11E2  72        		.byte	114
3597    11E3  6F        		.byte	111
3598    11E4  64        		.byte	100
3599    11E5  75        		.byte	117
3600    11E6  63        		.byte	99
3601    11E7  74        		.byte	116
3602    11E8  20        		.byte	32
3603    11E9  6E        		.byte	110
3604    11EA  61        		.byte	97
3605    11EB  6D        		.byte	109
3606    11EC  65        		.byte	101
3607    11ED  3A        		.byte	58
3608    11EE  20        		.byte	32
3609    11EF  25        		.byte	37
3610    11F0  2E        		.byte	46
3611    11F1  35        		.byte	53
3612    11F2  73        		.byte	115
3613    11F3  0A        		.byte	10
3614    11F4  00        		.byte	0
3615                    	L526:
3616    11F5  20        		.byte	32
3617    11F6  20        		.byte	32
3618    11F7  50        		.byte	80
3619    11F8  72        		.byte	114
3620    11F9  6F        		.byte	111
3621    11FA  64        		.byte	100
3622    11FB  75        		.byte	117
3623    11FC  63        		.byte	99
3624    11FD  74        		.byte	116
3625    11FE  20        		.byte	32
3626    11FF  72        		.byte	114
3627    1200  65        		.byte	101
3628    1201  76        		.byte	118
3629    1202  69        		.byte	105
3630    1203  73        		.byte	115
3631    1204  69        		.byte	105
3632    1205  6F        		.byte	111
3633    1206  6E        		.byte	110
3634    1207  3A        		.byte	58
3635    1208  20        		.byte	32
3636    1209  25        		.byte	37
3637    120A  64        		.byte	100
3638    120B  2E        		.byte	46
3639    120C  25        		.byte	37
3640    120D  64        		.byte	100
3641    120E  2C        		.byte	44
3642    120F  20        		.byte	32
3643    1210  00        		.byte	0
3644                    	L536:
3645    1211  53        		.byte	83
3646    1212  65        		.byte	101
3647    1213  72        		.byte	114
3648    1214  69        		.byte	105
3649    1215  61        		.byte	97
3650    1216  6C        		.byte	108
3651    1217  20        		.byte	32
3652    1218  6E        		.byte	110
3653    1219  75        		.byte	117
3654    121A  6D        		.byte	109
3655    121B  62        		.byte	98
3656    121C  65        		.byte	101
3657    121D  72        		.byte	114
3658    121E  3A        		.byte	58
3659    121F  20        		.byte	32
3660    1220  25        		.byte	37
3661    1221  6C        		.byte	108
3662    1222  75        		.byte	117
3663    1223  0A        		.byte	10
3664    1224  00        		.byte	0
3665                    	L546:
3666    1225  20        		.byte	32
3667    1226  20        		.byte	32
3668    1227  4D        		.byte	77
3669    1228  61        		.byte	97
3670    1229  6E        		.byte	110
3671    122A  75        		.byte	117
3672    122B  66        		.byte	102
3673    122C  61        		.byte	97
3674    122D  63        		.byte	99
3675    122E  74        		.byte	116
3676    122F  75        		.byte	117
3677    1230  72        		.byte	114
3678    1231  69        		.byte	105
3679    1232  6E        		.byte	110
3680    1233  67        		.byte	103
3681    1234  20        		.byte	32
3682    1235  64        		.byte	100
3683    1236  61        		.byte	97
3684    1237  74        		.byte	116
3685    1238  65        		.byte	101
3686    1239  3A        		.byte	58
3687    123A  20        		.byte	32
3688    123B  25        		.byte	37
3689    123C  64        		.byte	100
3690    123D  2D        		.byte	45
3691    123E  25        		.byte	37
3692    123F  64        		.byte	100
3693    1240  2C        		.byte	44
3694    1241  20        		.byte	32
3695    1242  00        		.byte	0
3696                    	L556:
3697    1243  44        		.byte	68
3698    1244  65        		.byte	101
3699    1245  76        		.byte	118
3700    1246  69        		.byte	105
3701    1247  63        		.byte	99
3702    1248  65        		.byte	101
3703    1249  20        		.byte	32
3704    124A  63        		.byte	99
3705    124B  61        		.byte	97
3706    124C  70        		.byte	112
3707    124D  61        		.byte	97
3708    124E  63        		.byte	99
3709    124F  69        		.byte	105
3710    1250  74        		.byte	116
3711    1251  79        		.byte	121
3712    1252  3A        		.byte	58
3713    1253  20        		.byte	32
3714    1254  25        		.byte	37
3715    1255  6C        		.byte	108
3716    1256  75        		.byte	117
3717    1257  20        		.byte	32
3718    1258  4D        		.byte	77
3719    1259  42        		.byte	66
3720    125A  79        		.byte	121
3721    125B  74        		.byte	116
3722    125C  65        		.byte	101
3723    125D  0A        		.byte	10
3724    125E  00        		.byte	0
3725                    	L566:
3726    125F  44        		.byte	68
3727    1260  65        		.byte	101
3728    1261  76        		.byte	118
3729    1262  69        		.byte	105
3730    1263  63        		.byte	99
3731    1264  65        		.byte	101
3732    1265  20        		.byte	32
3733    1266  63        		.byte	99
3734    1267  61        		.byte	97
3735    1268  70        		.byte	112
3736    1269  61        		.byte	97
3737    126A  63        		.byte	99
3738    126B  69        		.byte	105
3739    126C  74        		.byte	116
3740    126D  79        		.byte	121
3741    126E  3A        		.byte	58
3742    126F  20        		.byte	32
3743    1270  25        		.byte	37
3744    1271  6C        		.byte	108
3745    1272  75        		.byte	117
3746    1273  20        		.byte	32
3747    1274  4D        		.byte	77
3748    1275  42        		.byte	66
3749    1276  79        		.byte	121
3750    1277  74        		.byte	116
3751    1278  65        		.byte	101
3752    1279  0A        		.byte	10
3753    127A  00        		.byte	0
3754                    	L576:
3755    127B  44        		.byte	68
3756    127C  65        		.byte	101
3757    127D  76        		.byte	118
3758    127E  69        		.byte	105
3759    127F  63        		.byte	99
3760    1280  65        		.byte	101
3761    1281  20        		.byte	32
3762    1282  75        		.byte	117
3763    1283  6C        		.byte	108
3764    1284  74        		.byte	116
3765    1285  72        		.byte	114
3766    1286  61        		.byte	97
3767    1287  20        		.byte	32
3768    1288  63        		.byte	99
3769    1289  61        		.byte	97
3770    128A  70        		.byte	112
3771    128B  61        		.byte	97
3772    128C  63        		.byte	99
3773    128D  69        		.byte	105
3774    128E  74        		.byte	116
3775    128F  79        		.byte	121
3776    1290  3A        		.byte	58
3777    1291  20        		.byte	32
3778    1292  25        		.byte	37
3779    1293  6C        		.byte	108
3780    1294  75        		.byte	117
3781    1295  20        		.byte	32
3782    1296  4D        		.byte	77
3783    1297  42        		.byte	66
3784    1298  79        		.byte	121
3785    1299  74        		.byte	116
3786    129A  65        		.byte	101
3787    129B  0A        		.byte	10
3788    129C  00        		.byte	0
3789                    	L507:
3790    129D  2D        		.byte	45
3791    129E  2D        		.byte	45
3792    129F  2D        		.byte	45
3793    12A0  2D        		.byte	45
3794    12A1  2D        		.byte	45
3795    12A2  2D        		.byte	45
3796    12A3  2D        		.byte	45
3797    12A4  2D        		.byte	45
3798    12A5  2D        		.byte	45
3799    12A6  2D        		.byte	45
3800    12A7  2D        		.byte	45
3801    12A8  2D        		.byte	45
3802    12A9  2D        		.byte	45
3803    12AA  2D        		.byte	45
3804    12AB  2D        		.byte	45
3805    12AC  2D        		.byte	45
3806    12AD  2D        		.byte	45
3807    12AE  2D        		.byte	45
3808    12AF  2D        		.byte	45
3809    12B0  2D        		.byte	45
3810    12B1  2D        		.byte	45
3811    12B2  2D        		.byte	45
3812    12B3  2D        		.byte	45
3813    12B4  2D        		.byte	45
3814    12B5  2D        		.byte	45
3815    12B6  2D        		.byte	45
3816    12B7  2D        		.byte	45
3817    12B8  2D        		.byte	45
3818    12B9  2D        		.byte	45
3819    12BA  2D        		.byte	45
3820    12BB  2D        		.byte	45
3821    12BC  2D        		.byte	45
3822    12BD  2D        		.byte	45
3823    12BE  2D        		.byte	45
3824    12BF  2D        		.byte	45
3825    12C0  2D        		.byte	45
3826    12C1  2D        		.byte	45
3827    12C2  2D        		.byte	45
3828    12C3  0A        		.byte	10
3829    12C4  00        		.byte	0
3830                    	L517:
3831    12C5  4F        		.byte	79
3832    12C6  43        		.byte	67
3833    12C7  52        		.byte	82
3834    12C8  20        		.byte	32
3835    12C9  72        		.byte	114
3836    12CA  65        		.byte	101
3837    12CB  67        		.byte	103
3838    12CC  69        		.byte	105
3839    12CD  73        		.byte	115
3840    12CE  74        		.byte	116
3841    12CF  65        		.byte	101
3842    12D0  72        		.byte	114
3843    12D1  3A        		.byte	58
3844    12D2  0A        		.byte	10
3845    12D3  00        		.byte	0
3846                    	L527:
3847    12D4  32        		.byte	50
3848    12D5  2E        		.byte	46
3849    12D6  37        		.byte	55
3850    12D7  2D        		.byte	45
3851    12D8  32        		.byte	50
3852    12D9  2E        		.byte	46
3853    12DA  38        		.byte	56
3854    12DB  56        		.byte	86
3855    12DC  20        		.byte	32
3856    12DD  28        		.byte	40
3857    12DE  62        		.byte	98
3858    12DF  69        		.byte	105
3859    12E0  74        		.byte	116
3860    12E1  20        		.byte	32
3861    12E2  31        		.byte	49
3862    12E3  35        		.byte	53
3863    12E4  29        		.byte	41
3864    12E5  20        		.byte	32
3865    12E6  00        		.byte	0
3866                    	L537:
3867    12E7  32        		.byte	50
3868    12E8  2E        		.byte	46
3869    12E9  38        		.byte	56
3870    12EA  2D        		.byte	45
3871    12EB  32        		.byte	50
3872    12EC  2E        		.byte	46
3873    12ED  39        		.byte	57
3874    12EE  56        		.byte	86
3875    12EF  20        		.byte	32
3876    12F0  28        		.byte	40
3877    12F1  62        		.byte	98
3878    12F2  69        		.byte	105
3879    12F3  74        		.byte	116
3880    12F4  20        		.byte	32
3881    12F5  31        		.byte	49
3882    12F6  36        		.byte	54
3883    12F7  29        		.byte	41
3884    12F8  20        		.byte	32
3885    12F9  00        		.byte	0
3886                    	L547:
3887    12FA  32        		.byte	50
3888    12FB  2E        		.byte	46
3889    12FC  39        		.byte	57
3890    12FD  2D        		.byte	45
3891    12FE  33        		.byte	51
3892    12FF  2E        		.byte	46
3893    1300  30        		.byte	48
3894    1301  56        		.byte	86
3895    1302  20        		.byte	32
3896    1303  28        		.byte	40
3897    1304  62        		.byte	98
3898    1305  69        		.byte	105
3899    1306  74        		.byte	116
3900    1307  20        		.byte	32
3901    1308  31        		.byte	49
3902    1309  37        		.byte	55
3903    130A  29        		.byte	41
3904    130B  20        		.byte	32
3905    130C  00        		.byte	0
3906                    	L557:
3907    130D  33        		.byte	51
3908    130E  2E        		.byte	46
3909    130F  30        		.byte	48
3910    1310  2D        		.byte	45
3911    1311  33        		.byte	51
3912    1312  2E        		.byte	46
3913    1313  31        		.byte	49
3914    1314  56        		.byte	86
3915    1315  20        		.byte	32
3916    1316  28        		.byte	40
3917    1317  62        		.byte	98
3918    1318  69        		.byte	105
3919    1319  74        		.byte	116
3920    131A  20        		.byte	32
3921    131B  31        		.byte	49
3922    131C  38        		.byte	56
3923    131D  29        		.byte	41
3924    131E  20        		.byte	32
3925    131F  0A        		.byte	10
3926    1320  00        		.byte	0
3927                    	L567:
3928    1321  33        		.byte	51
3929    1322  2E        		.byte	46
3930    1323  31        		.byte	49
3931    1324  2D        		.byte	45
3932    1325  33        		.byte	51
3933    1326  2E        		.byte	46
3934    1327  32        		.byte	50
3935    1328  56        		.byte	86
3936    1329  20        		.byte	32
3937    132A  28        		.byte	40
3938    132B  62        		.byte	98
3939    132C  69        		.byte	105
3940    132D  74        		.byte	116
3941    132E  20        		.byte	32
3942    132F  31        		.byte	49
3943    1330  39        		.byte	57
3944    1331  29        		.byte	41
3945    1332  20        		.byte	32
3946    1333  00        		.byte	0
3947                    	L577:
3948    1334  33        		.byte	51
3949    1335  2E        		.byte	46
3950    1336  32        		.byte	50
3951    1337  2D        		.byte	45
3952    1338  33        		.byte	51
3953    1339  2E        		.byte	46
3954    133A  33        		.byte	51
3955    133B  56        		.byte	86
3956    133C  20        		.byte	32
3957    133D  28        		.byte	40
3958    133E  62        		.byte	98
3959    133F  69        		.byte	105
3960    1340  74        		.byte	116
3961    1341  20        		.byte	32
3962    1342  32        		.byte	50
3963    1343  30        		.byte	48
3964    1344  29        		.byte	41
3965    1345  20        		.byte	32
3966    1346  00        		.byte	0
3967                    	L5001:
3968    1347  33        		.byte	51
3969    1348  2E        		.byte	46
3970    1349  33        		.byte	51
3971    134A  2D        		.byte	45
3972    134B  33        		.byte	51
3973    134C  2E        		.byte	46
3974    134D  34        		.byte	52
3975    134E  56        		.byte	86
3976    134F  20        		.byte	32
3977    1350  28        		.byte	40
3978    1351  62        		.byte	98
3979    1352  69        		.byte	105
3980    1353  74        		.byte	116
3981    1354  20        		.byte	32
3982    1355  32        		.byte	50
3983    1356  31        		.byte	49
3984    1357  29        		.byte	41
3985    1358  20        		.byte	32
3986    1359  00        		.byte	0
3987                    	L5101:
3988    135A  33        		.byte	51
3989    135B  2E        		.byte	46
3990    135C  34        		.byte	52
3991    135D  2D        		.byte	45
3992    135E  33        		.byte	51
3993    135F  2E        		.byte	46
3994    1360  35        		.byte	53
3995    1361  56        		.byte	86
3996    1362  20        		.byte	32
3997    1363  28        		.byte	40
3998    1364  62        		.byte	98
3999    1365  69        		.byte	105
4000    1366  74        		.byte	116
4001    1367  20        		.byte	32
4002    1368  32        		.byte	50
4003    1369  32        		.byte	50
4004    136A  29        		.byte	41
4005    136B  20        		.byte	32
4006    136C  0A        		.byte	10
4007    136D  00        		.byte	0
4008                    	L5201:
4009    136E  33        		.byte	51
4010    136F  2E        		.byte	46
4011    1370  35        		.byte	53
4012    1371  2D        		.byte	45
4013    1372  33        		.byte	51
4014    1373  2E        		.byte	46
4015    1374  36        		.byte	54
4016    1375  56        		.byte	86
4017    1376  20        		.byte	32
4018    1377  28        		.byte	40
4019    1378  62        		.byte	98
4020    1379  69        		.byte	105
4021    137A  74        		.byte	116
4022    137B  20        		.byte	32
4023    137C  32        		.byte	50
4024    137D  33        		.byte	51
4025    137E  29        		.byte	41
4026    137F  20        		.byte	32
4027    1380  0A        		.byte	10
4028    1381  00        		.byte	0
4029                    	L5301:
4030    1382  53        		.byte	83
4031    1383  77        		.byte	119
4032    1384  69        		.byte	105
4033    1385  74        		.byte	116
4034    1386  63        		.byte	99
4035    1387  68        		.byte	104
4036    1388  69        		.byte	105
4037    1389  6E        		.byte	110
4038    138A  67        		.byte	103
4039    138B  20        		.byte	32
4040    138C  74        		.byte	116
4041    138D  6F        		.byte	111
4042    138E  20        		.byte	32
4043    138F  31        		.byte	49
4044    1390  2E        		.byte	46
4045    1391  38        		.byte	56
4046    1392  56        		.byte	86
4047    1393  20        		.byte	32
4048    1394  41        		.byte	65
4049    1395  63        		.byte	99
4050    1396  63        		.byte	99
4051    1397  65        		.byte	101
4052    1398  70        		.byte	112
4053    1399  74        		.byte	116
4054    139A  65        		.byte	101
4055    139B  64        		.byte	100
4056    139C  20        		.byte	32
4057    139D  28        		.byte	40
4058    139E  53        		.byte	83
4059    139F  31        		.byte	49
4060    13A0  38        		.byte	56
4061    13A1  41        		.byte	65
4062    13A2  29        		.byte	41
4063    13A3  20        		.byte	32
4064    13A4  28        		.byte	40
4065    13A5  62        		.byte	98
4066    13A6  69        		.byte	105
4067    13A7  74        		.byte	116
4068    13A8  20        		.byte	32
4069    13A9  32        		.byte	50
4070    13AA  34        		.byte	52
4071    13AB  29        		.byte	41
4072    13AC  20        		.byte	32
4073    13AD  73        		.byte	115
4074    13AE  65        		.byte	101
4075    13AF  74        		.byte	116
4076    13B0  20        		.byte	32
4077    13B1  00        		.byte	0
4078                    	L5401:
4079    13B2  4F        		.byte	79
4080    13B3  76        		.byte	118
4081    13B4  65        		.byte	101
4082    13B5  72        		.byte	114
4083    13B6  20        		.byte	32
4084    13B7  32        		.byte	50
4085    13B8  54        		.byte	84
4086    13B9  42        		.byte	66
4087    13BA  20        		.byte	32
4088    13BB  73        		.byte	115
4089    13BC  75        		.byte	117
4090    13BD  70        		.byte	112
4091    13BE  70        		.byte	112
4092    13BF  6F        		.byte	111
4093    13C0  72        		.byte	114
4094    13C1  74        		.byte	116
4095    13C2  20        		.byte	32
   0    13C3  53        		.byte	83
   1    13C4  74        		.byte	116
   2    13C5  61        		.byte	97
   3    13C6  74        		.byte	116
   4    13C7  75        		.byte	117
   5    13C8  73        		.byte	115
   6    13C9  20        		.byte	32
   7    13CA  28        		.byte	40
   8    13CB  43        		.byte	67
   9    13CC  4F        		.byte	79
  10    13CD  32        		.byte	50
  11    13CE  54        		.byte	84
  12    13CF  29        		.byte	41
  13    13D0  20        		.byte	32
  14    13D1  28        		.byte	40
  15    13D2  62        		.byte	98
  16    13D3  69        		.byte	105
  17    13D4  74        		.byte	116
  18    13D5  20        		.byte	32
  19    13D6  32        		.byte	50
  20    13D7  37        		.byte	55
  21    13D8  29        		.byte	41
  22    13D9  20        		.byte	32
  23    13DA  73        		.byte	115
  24    13DB  65        		.byte	101
  25    13DC  74        		.byte	116
  26    13DD  0A        		.byte	10
  27    13DE  00        		.byte	0
  28                    	L5501:
  29    13DF  55        		.byte	85
  30    13E0  48        		.byte	72
  31    13E1  53        		.byte	83
  32    13E2  2D        		.byte	45
  33    13E3  49        		.byte	73
  34    13E4  49        		.byte	73
  35    13E5  20        		.byte	32
  36    13E6  43        		.byte	67
  37    13E7  61        		.byte	97
  38    13E8  72        		.byte	114
  39    13E9  64        		.byte	100
  40    13EA  20        		.byte	32
  41    13EB  53        		.byte	83
  42    13EC  74        		.byte	116
  43    13ED  61        		.byte	97
  44    13EE  74        		.byte	116
  45    13EF  75        		.byte	117
  46    13F0  73        		.byte	115
  47    13F1  20        		.byte	32
  48    13F2  28        		.byte	40
  49    13F3  62        		.byte	98
  50    13F4  69        		.byte	105
  51    13F5  74        		.byte	116
  52    13F6  20        		.byte	32
  53    13F7  32        		.byte	50
  54    13F8  39        		.byte	57
  55    13F9  29        		.byte	41
  56    13FA  20        		.byte	32
  57    13FB  73        		.byte	115
  58    13FC  65        		.byte	101
  59    13FD  74        		.byte	116
  60    13FE  20        		.byte	32
  61    13FF  00        		.byte	0
  62                    	L5601:
  63    1400  43        		.byte	67
  64    1401  61        		.byte	97
  65    1402  72        		.byte	114
  66    1403  64        		.byte	100
  67    1404  20        		.byte	32
  68    1405  43        		.byte	67
  69    1406  61        		.byte	97
  70    1407  70        		.byte	112
  71    1408  61        		.byte	97
  72    1409  63        		.byte	99
  73    140A  69        		.byte	105
  74    140B  74        		.byte	116
  75    140C  79        		.byte	121
  76    140D  20        		.byte	32
  77    140E  53        		.byte	83
  78    140F  74        		.byte	116
  79    1410  61        		.byte	97
  80    1411  74        		.byte	116
  81    1412  75        		.byte	117
  82    1413  73        		.byte	115
  83    1414  20        		.byte	32
  84    1415  28        		.byte	40
  85    1416  43        		.byte	67
  86    1417  43        		.byte	67
  87    1418  53        		.byte	83
  88    1419  29        		.byte	41
  89    141A  20        		.byte	32
  90    141B  28        		.byte	40
  91    141C  62        		.byte	98
  92    141D  69        		.byte	105
  93    141E  74        		.byte	116
  94    141F  20        		.byte	32
  95    1420  33        		.byte	51
  96    1421  30        		.byte	48
  97    1422  29        		.byte	41
  98    1423  20        		.byte	32
  99    1424  73        		.byte	115
 100    1425  65        		.byte	101
 101    1426  74        		.byte	116
 102    1427  0A        		.byte	10
 103    1428  00        		.byte	0
 104                    	L5701:
 105    1429  20        		.byte	32
 106    142A  20        		.byte	32
 107    142B  53        		.byte	83
 108    142C  44        		.byte	68
 109    142D  20        		.byte	32
 110    142E  56        		.byte	86
 111    142F  65        		.byte	101
 112    1430  72        		.byte	114
 113    1431  2E        		.byte	46
 114    1432  32        		.byte	50
 115    1433  2B        		.byte	43
 116    1434  2C        		.byte	44
 117    1435  20        		.byte	32
 118    1436  42        		.byte	66
 119    1437  6C        		.byte	108
 120    1438  6F        		.byte	111
 121    1439  63        		.byte	99
 122    143A  6B        		.byte	107
 123    143B  20        		.byte	32
 124    143C  61        		.byte	97
 125    143D  64        		.byte	100
 126    143E  64        		.byte	100
 127    143F  72        		.byte	114
 128    1440  65        		.byte	101
 129    1441  73        		.byte	115
 130    1442  73        		.byte	115
 131    1443  00        		.byte	0
 132                    	L5011:
 133    1444  43        		.byte	67
 134    1445  61        		.byte	97
 135    1446  72        		.byte	114
 136    1447  64        		.byte	100
 137    1448  20        		.byte	32
 138    1449  43        		.byte	67
 139    144A  61        		.byte	97
 140    144B  70        		.byte	112
 141    144C  61        		.byte	97
 142    144D  63        		.byte	99
 143    144E  69        		.byte	105
 144    144F  74        		.byte	116
 145    1450  79        		.byte	121
 146    1451  20        		.byte	32
 147    1452  53        		.byte	83
 148    1453  74        		.byte	116
 149    1454  61        		.byte	97
 150    1455  74        		.byte	116
 151    1456  75        		.byte	117
 152    1457  73        		.byte	115
 153    1458  20        		.byte	32
 154    1459  28        		.byte	40
 155    145A  43        		.byte	67
 156    145B  43        		.byte	67
 157    145C  53        		.byte	83
 158    145D  29        		.byte	41
 159    145E  20        		.byte	32
 160    145F  28        		.byte	40
 161    1460  62        		.byte	98
 162    1461  69        		.byte	105
 163    1462  74        		.byte	116
 164    1463  20        		.byte	32
 165    1464  33        		.byte	51
 166    1465  30        		.byte	48
 167    1466  29        		.byte	41
 168    1467  20        		.byte	32
 169    1468  6E        		.byte	110
 170    1469  6F        		.byte	111
 171    146A  74        		.byte	116
 172    146B  20        		.byte	32
 173    146C  73        		.byte	115
 174    146D  65        		.byte	101
 175    146E  74        		.byte	116
 176    146F  0A        		.byte	10
 177    1470  00        		.byte	0
 178                    	L5111:
 179    1471  20        		.byte	32
 180    1472  20        		.byte	32
 181    1473  53        		.byte	83
 182    1474  44        		.byte	68
 183    1475  20        		.byte	32
 184    1476  56        		.byte	86
 185    1477  65        		.byte	101
 186    1478  72        		.byte	114
 187    1479  2E        		.byte	46
 188    147A  32        		.byte	50
 189    147B  2B        		.byte	43
 190    147C  2C        		.byte	44
 191    147D  20        		.byte	32
 192    147E  42        		.byte	66
 193    147F  79        		.byte	121
 194    1480  74        		.byte	116
 195    1481  65        		.byte	101
 196    1482  20        		.byte	32
 197    1483  61        		.byte	97
 198    1484  64        		.byte	100
 199    1485  64        		.byte	100
 200    1486  72        		.byte	114
 201    1487  65        		.byte	101
 202    1488  73        		.byte	115
 203    1489  73        		.byte	115
 204    148A  00        		.byte	0
 205                    	L5211:
 206    148B  20        		.byte	32
 207    148C  20        		.byte	32
 208    148D  53        		.byte	83
 209    148E  44        		.byte	68
 210    148F  20        		.byte	32
 211    1490  56        		.byte	86
 212    1491  65        		.byte	101
 213    1492  72        		.byte	114
 214    1493  2E        		.byte	46
 215    1494  31        		.byte	49
 216    1495  2C        		.byte	44
 217    1496  20        		.byte	32
 218    1497  42        		.byte	66
 219    1498  79        		.byte	121
 220    1499  74        		.byte	116
 221    149A  65        		.byte	101
 222    149B  20        		.byte	32
 223    149C  61        		.byte	97
 224    149D  64        		.byte	100
 225    149E  64        		.byte	100
 226    149F  72        		.byte	114
 227    14A0  65        		.byte	101
 228    14A1  73        		.byte	115
 229    14A2  73        		.byte	115
 230    14A3  00        		.byte	0
 231                    	L5311:
 232    14A4  0A        		.byte	10
 233    14A5  43        		.byte	67
 234    14A6  61        		.byte	97
 235    14A7  72        		.byte	114
 236    14A8  64        		.byte	100
 237    14A9  20        		.byte	32
 238    14AA  70        		.byte	112
 239    14AB  6F        		.byte	111
 240    14AC  77        		.byte	119
 241    14AD  65        		.byte	101
 242    14AE  72        		.byte	114
 243    14AF  20        		.byte	32
 244    14B0  75        		.byte	117
 245    14B1  70        		.byte	112
 246    14B2  20        		.byte	32
 247    14B3  73        		.byte	115
 248    14B4  74        		.byte	116
 249    14B5  61        		.byte	97
 250    14B6  74        		.byte	116
 251    14B7  75        		.byte	117
 252    14B8  73        		.byte	115
 253    14B9  20        		.byte	32
 254    14BA  62        		.byte	98
 255    14BB  69        		.byte	105
 256    14BC  74        		.byte	116
 257    14BD  20        		.byte	32
 258    14BE  28        		.byte	40
 259    14BF  62        		.byte	98
 260    14C0  75        		.byte	117
 261    14C1  73        		.byte	115
 262    14C2  79        		.byte	121
 263    14C3  29        		.byte	41
 264    14C4  20        		.byte	32
 265    14C5  28        		.byte	40
 266    14C6  62        		.byte	98
 267    14C7  69        		.byte	105
 268    14C8  74        		.byte	116
 269    14C9  20        		.byte	32
 270    14CA  33        		.byte	51
 271    14CB  31        		.byte	49
 272    14CC  29        		.byte	41
 273    14CD  20        		.byte	32
 274    14CE  73        		.byte	115
 275    14CF  65        		.byte	101
 276    14D0  74        		.byte	116
 277    14D1  0A        		.byte	10
 278    14D2  00        		.byte	0
 279                    	L5411:
 280    14D3  0A        		.byte	10
 281    14D4  43        		.byte	67
 282    14D5  61        		.byte	97
 283    14D6  72        		.byte	114
 284    14D7  64        		.byte	100
 285    14D8  20        		.byte	32
 286    14D9  70        		.byte	112
 287    14DA  6F        		.byte	111
 288    14DB  77        		.byte	119
 289    14DC  65        		.byte	101
 290    14DD  72        		.byte	114
 291    14DE  20        		.byte	32
 292    14DF  75        		.byte	117
 293    14E0  70        		.byte	112
 294    14E1  20        		.byte	32
 295    14E2  73        		.byte	115
 296    14E3  74        		.byte	116
 297    14E4  61        		.byte	97
 298    14E5  74        		.byte	116
 299    14E6  75        		.byte	117
 300    14E7  73        		.byte	115
 301    14E8  20        		.byte	32
 302    14E9  62        		.byte	98
 303    14EA  69        		.byte	105
 304    14EB  74        		.byte	116
 305    14EC  20        		.byte	32
 306    14ED  28        		.byte	40
 307    14EE  62        		.byte	98
 308    14EF  75        		.byte	117
 309    14F0  73        		.byte	115
 310    14F1  79        		.byte	121
 311    14F2  29        		.byte	41
 312    14F3  20        		.byte	32
 313    14F4  28        		.byte	40
 314    14F5  62        		.byte	98
 315    14F6  69        		.byte	105
 316    14F7  74        		.byte	116
 317    14F8  20        		.byte	32
 318    14F9  33        		.byte	51
 319    14FA  31        		.byte	49
 320    14FB  29        		.byte	41
 321    14FC  20        		.byte	32
 322    14FD  6E        		.byte	110
 323    14FE  6F        		.byte	111
 324    14FF  74        		.byte	116
 325    1500  20        		.byte	32
 326    1501  73        		.byte	115
 327    1502  65        		.byte	101
 328    1503  74        		.byte	116
 329    1504  2E        		.byte	46
 330    1505  0A        		.byte	10
 331    1506  00        		.byte	0
 332                    	L5511:
 333    1507  20        		.byte	32
 334    1508  20        		.byte	32
 335    1509  54        		.byte	84
 336    150A  68        		.byte	104
 337    150B  69        		.byte	105
 338    150C  73        		.byte	115
 339    150D  20        		.byte	32
 340    150E  62        		.byte	98
 341    150F  69        		.byte	105
 342    1510  74        		.byte	116
 343    1511  20        		.byte	32
 344    1512  69        		.byte	105
 345    1513  73        		.byte	115
 346    1514  20        		.byte	32
 347    1515  6E        		.byte	110
 348    1516  6F        		.byte	111
 349    1517  74        		.byte	116
 350    1518  20        		.byte	32
 351    1519  73        		.byte	115
 352    151A  65        		.byte	101
 353    151B  74        		.byte	116
 354    151C  20        		.byte	32
 355    151D  69        		.byte	105
 356    151E  66        		.byte	102
 357    151F  20        		.byte	32
 358    1520  74        		.byte	116
 359    1521  68        		.byte	104
 360    1522  65        		.byte	101
 361    1523  20        		.byte	32
 362    1524  63        		.byte	99
 363    1525  61        		.byte	97
 364    1526  72        		.byte	114
 365    1527  64        		.byte	100
 366    1528  20        		.byte	32
 367    1529  68        		.byte	104
 368    152A  61        		.byte	97
 369    152B  73        		.byte	115
 370    152C  20        		.byte	32
 371    152D  6E        		.byte	110
 372    152E  6F        		.byte	111
 373    152F  74        		.byte	116
 374    1530  20        		.byte	32
 375    1531  66        		.byte	102
 376    1532  69        		.byte	105
 377    1533  6E        		.byte	110
 378    1534  69        		.byte	105
 379    1535  73        		.byte	115
 380    1536  68        		.byte	104
 381    1537  65        		.byte	101
 382    1538  64        		.byte	100
 383    1539  20        		.byte	32
 384    153A  74        		.byte	116
 385    153B  68        		.byte	104
 386    153C  65        		.byte	101
 387    153D  20        		.byte	32
 388    153E  70        		.byte	112
 389    153F  6F        		.byte	111
 390    1540  77        		.byte	119
 391    1541  65        		.byte	101
 392    1542  72        		.byte	114
 393    1543  20        		.byte	32
 394    1544  75        		.byte	117
 395    1545  70        		.byte	112
 396    1546  20        		.byte	32
 397    1547  72        		.byte	114
 398    1548  6F        		.byte	111
 399    1549  75        		.byte	117
 400    154A  74        		.byte	116
 401    154B  69        		.byte	105
 402    154C  6E        		.byte	110
 403    154D  65        		.byte	101
 404    154E  2E        		.byte	46
 405    154F  0A        		.byte	10
 406    1550  00        		.byte	0
 407                    	L5611:
 408    1551  2D        		.byte	45
 409    1552  2D        		.byte	45
 410    1553  2D        		.byte	45
 411    1554  2D        		.byte	45
 412    1555  2D        		.byte	45
 413    1556  2D        		.byte	45
 414    1557  2D        		.byte	45
 415    1558  2D        		.byte	45
 416    1559  2D        		.byte	45
 417    155A  2D        		.byte	45
 418    155B  2D        		.byte	45
 419    155C  2D        		.byte	45
 420    155D  2D        		.byte	45
 421    155E  2D        		.byte	45
 422    155F  2D        		.byte	45
 423    1560  2D        		.byte	45
 424    1561  2D        		.byte	45
 425    1562  2D        		.byte	45
 426    1563  2D        		.byte	45
 427    1564  2D        		.byte	45
 428    1565  2D        		.byte	45
 429    1566  2D        		.byte	45
 430    1567  2D        		.byte	45
 431    1568  2D        		.byte	45
 432    1569  2D        		.byte	45
 433    156A  2D        		.byte	45
 434    156B  2D        		.byte	45
 435    156C  2D        		.byte	45
 436    156D  2D        		.byte	45
 437    156E  2D        		.byte	45
 438    156F  2D        		.byte	45
 439    1570  2D        		.byte	45
 440    1571  2D        		.byte	45
 441    1572  2D        		.byte	45
 442    1573  2D        		.byte	45
 443    1574  2D        		.byte	45
 444    1575  2D        		.byte	45
 445    1576  2D        		.byte	45
 446    1577  0A        		.byte	10
 447    1578  00        		.byte	0
 448                    	L5711:
 449    1579  43        		.byte	67
 450    157A  49        		.byte	73
 451    157B  44        		.byte	68
 452    157C  20        		.byte	32
 453    157D  72        		.byte	114
 454    157E  65        		.byte	101
 455    157F  67        		.byte	103
 456    1580  69        		.byte	105
 457    1581  73        		.byte	115
 458    1582  74        		.byte	116
 459    1583  65        		.byte	101
 460    1584  72        		.byte	114
 461    1585  3A        		.byte	58
 462    1586  0A        		.byte	10
 463    1587  00        		.byte	0
 464                    	L5021:
 465    1588  4D        		.byte	77
 466    1589  49        		.byte	73
 467    158A  44        		.byte	68
 468    158B  3A        		.byte	58
 469    158C  20        		.byte	32
 470    158D  30        		.byte	48
 471    158E  78        		.byte	120
 472    158F  25        		.byte	37
 473    1590  30        		.byte	48
 474    1591  32        		.byte	50
 475    1592  78        		.byte	120
 476    1593  2C        		.byte	44
 477    1594  20        		.byte	32
 478    1595  00        		.byte	0
 479                    	L5121:
 480    1596  4F        		.byte	79
 481    1597  49        		.byte	73
 482    1598  44        		.byte	68
 483    1599  3A        		.byte	58
 484    159A  20        		.byte	32
 485    159B  25        		.byte	37
 486    159C  2E        		.byte	46
 487    159D  32        		.byte	50
 488    159E  73        		.byte	115
 489    159F  2C        		.byte	44
 490    15A0  20        		.byte	32
 491    15A1  00        		.byte	0
 492                    	L5221:
 493    15A2  50        		.byte	80
 494    15A3  4E        		.byte	78
 495    15A4  4D        		.byte	77
 496    15A5  3A        		.byte	58
 497    15A6  20        		.byte	32
 498    15A7  25        		.byte	37
 499    15A8  2E        		.byte	46
 500    15A9  35        		.byte	53
 501    15AA  73        		.byte	115
 502    15AB  2C        		.byte	44
 503    15AC  20        		.byte	32
 504    15AD  00        		.byte	0
 505                    	L5321:
 506    15AE  50        		.byte	80
 507    15AF  52        		.byte	82
 508    15B0  56        		.byte	86
 509    15B1  3A        		.byte	58
 510    15B2  20        		.byte	32
 511    15B3  25        		.byte	37
 512    15B4  64        		.byte	100
 513    15B5  2E        		.byte	46
 514    15B6  25        		.byte	37
 515    15B7  64        		.byte	100
 516    15B8  2C        		.byte	44
 517    15B9  20        		.byte	32
 518    15BA  00        		.byte	0
 519                    	L5421:
 520    15BB  50        		.byte	80
 521    15BC  53        		.byte	83
 522    15BD  4E        		.byte	78
 523    15BE  3A        		.byte	58
 524    15BF  20        		.byte	32
 525    15C0  25        		.byte	37
 526    15C1  6C        		.byte	108
 527    15C2  75        		.byte	117
 528    15C3  2C        		.byte	44
 529    15C4  20        		.byte	32
 530    15C5  00        		.byte	0
 531                    	L5521:
 532    15C6  4D        		.byte	77
 533    15C7  44        		.byte	68
 534    15C8  54        		.byte	84
 535    15C9  3A        		.byte	58
 536    15CA  20        		.byte	32
 537    15CB  25        		.byte	37
 538    15CC  64        		.byte	100
 539    15CD  2D        		.byte	45
 540    15CE  25        		.byte	37
 541    15CF  64        		.byte	100
 542    15D0  0A        		.byte	10
 543    15D1  00        		.byte	0
 544                    	L5621:
 545    15D2  2D        		.byte	45
 546    15D3  2D        		.byte	45
 547    15D4  2D        		.byte	45
 548    15D5  2D        		.byte	45
 549    15D6  2D        		.byte	45
 550    15D7  2D        		.byte	45
 551    15D8  2D        		.byte	45
 552    15D9  2D        		.byte	45
 553    15DA  2D        		.byte	45
 554    15DB  2D        		.byte	45
 555    15DC  2D        		.byte	45
 556    15DD  2D        		.byte	45
 557    15DE  2D        		.byte	45
 558    15DF  2D        		.byte	45
 559    15E0  2D        		.byte	45
 560    15E1  2D        		.byte	45
 561    15E2  2D        		.byte	45
 562    15E3  2D        		.byte	45
 563    15E4  2D        		.byte	45
 564    15E5  2D        		.byte	45
 565    15E6  2D        		.byte	45
 566    15E7  2D        		.byte	45
 567    15E8  2D        		.byte	45
 568    15E9  2D        		.byte	45
 569    15EA  2D        		.byte	45
 570    15EB  2D        		.byte	45
 571    15EC  2D        		.byte	45
 572    15ED  2D        		.byte	45
 573    15EE  2D        		.byte	45
 574    15EF  2D        		.byte	45
 575    15F0  2D        		.byte	45
 576    15F1  2D        		.byte	45
 577    15F2  2D        		.byte	45
 578    15F3  2D        		.byte	45
 579    15F4  2D        		.byte	45
 580    15F5  2D        		.byte	45
 581    15F6  2D        		.byte	45
 582    15F7  2D        		.byte	45
 583    15F8  0A        		.byte	10
 584    15F9  00        		.byte	0
 585                    	L5721:
 586    15FA  43        		.byte	67
 587    15FB  53        		.byte	83
 588    15FC  44        		.byte	68
 589    15FD  20        		.byte	32
 590    15FE  72        		.byte	114
 591    15FF  65        		.byte	101
 592    1600  67        		.byte	103
 593    1601  69        		.byte	105
 594    1602  73        		.byte	115
 595    1603  74        		.byte	116
 596    1604  65        		.byte	101
 597    1605  72        		.byte	114
 598    1606  3A        		.byte	58
 599    1607  0A        		.byte	10
 600    1608  00        		.byte	0
 601                    	L5031:
 602    1609  43        		.byte	67
 603    160A  53        		.byte	83
 604    160B  44        		.byte	68
 605    160C  20        		.byte	32
 606    160D  56        		.byte	86
 607    160E  65        		.byte	101
 608    160F  72        		.byte	114
 609    1610  73        		.byte	115
 610    1611  69        		.byte	105
 611    1612  6F        		.byte	111
 612    1613  6E        		.byte	110
 613    1614  20        		.byte	32
 614    1615  31        		.byte	49
 615    1616  2E        		.byte	46
 616    1617  30        		.byte	48
 617    1618  2C        		.byte	44
 618    1619  20        		.byte	32
 619    161A  53        		.byte	83
 620    161B  74        		.byte	116
 621    161C  61        		.byte	97
 622    161D  6E        		.byte	110
 623    161E  64        		.byte	100
 624    161F  61        		.byte	97
 625    1620  72        		.byte	114
 626    1621  64        		.byte	100
 627    1622  20        		.byte	32
 628    1623  43        		.byte	67
 629    1624  61        		.byte	97
 630    1625  70        		.byte	112
 631    1626  61        		.byte	97
 632    1627  63        		.byte	99
 633    1628  69        		.byte	105
 634    1629  74        		.byte	116
 635    162A  79        		.byte	121
 636    162B  0A        		.byte	10
 637    162C  00        		.byte	0
 638                    	L5131:
 639    162D  20        		.byte	32
 640    162E  44        		.byte	68
 641    162F  65        		.byte	101
 642    1630  76        		.byte	118
 643    1631  69        		.byte	105
 644    1632  63        		.byte	99
 645    1633  65        		.byte	101
 646    1634  20        		.byte	32
 647    1635  63        		.byte	99
 648    1636  61        		.byte	97
 649    1637  70        		.byte	112
 650    1638  61        		.byte	97
 651    1639  63        		.byte	99
 652    163A  69        		.byte	105
 653    163B  74        		.byte	116
 654    163C  79        		.byte	121
 655    163D  3A        		.byte	58
 656    163E  20        		.byte	32
 657    163F  25        		.byte	37
 658    1640  6C        		.byte	108
 659    1641  75        		.byte	117
 660    1642  20        		.byte	32
 661    1643  4B        		.byte	75
 662    1644  42        		.byte	66
 663    1645  79        		.byte	121
 664    1646  74        		.byte	116
 665    1647  65        		.byte	101
 666    1648  2C        		.byte	44
 667    1649  20        		.byte	32
 668    164A  25        		.byte	37
 669    164B  6C        		.byte	108
 670    164C  75        		.byte	117
 671    164D  20        		.byte	32
 672    164E  4D        		.byte	77
 673    164F  42        		.byte	66
 674    1650  79        		.byte	121
 675    1651  74        		.byte	116
 676    1652  65        		.byte	101
 677    1653  0A        		.byte	10
 678    1654  00        		.byte	0
 679                    	L5231:
 680    1655  43        		.byte	67
 681    1656  53        		.byte	83
 682    1657  44        		.byte	68
 683    1658  20        		.byte	32
 684    1659  56        		.byte	86
 685    165A  65        		.byte	101
 686    165B  72        		.byte	114
 687    165C  73        		.byte	115
 688    165D  69        		.byte	105
 689    165E  6F        		.byte	111
 690    165F  6E        		.byte	110
 691    1660  20        		.byte	32
 692    1661  32        		.byte	50
 693    1662  2E        		.byte	46
 694    1663  30        		.byte	48
 695    1664  2C        		.byte	44
 696    1665  20        		.byte	32
 697    1666  48        		.byte	72
 698    1667  69        		.byte	105
 699    1668  67        		.byte	103
 700    1669  68        		.byte	104
 701    166A  20        		.byte	32
 702    166B  43        		.byte	67
 703    166C  61        		.byte	97
 704    166D  70        		.byte	112
 705    166E  61        		.byte	97
 706    166F  63        		.byte	99
 707    1670  69        		.byte	105
 708    1671  74        		.byte	116
 709    1672  79        		.byte	121
 710    1673  20        		.byte	32
 711    1674  61        		.byte	97
 712    1675  6E        		.byte	110
 713    1676  64        		.byte	100
 714    1677  20        		.byte	32
 715    1678  45        		.byte	69
 716    1679  78        		.byte	120
 717    167A  74        		.byte	116
 718    167B  65        		.byte	101
 719    167C  6E        		.byte	110
 720    167D  64        		.byte	100
 721    167E  65        		.byte	101
 722    167F  64        		.byte	100
 723    1680  20        		.byte	32
 724    1681  43        		.byte	67
 725    1682  61        		.byte	97
 726    1683  70        		.byte	112
 727    1684  61        		.byte	97
 728    1685  63        		.byte	99
 729    1686  69        		.byte	105
 730    1687  74        		.byte	116
 731    1688  79        		.byte	121
 732    1689  0A        		.byte	10
 733    168A  00        		.byte	0
 734                    	L5331:
 735    168B  20        		.byte	32
 736    168C  44        		.byte	68
 737    168D  65        		.byte	101
 738    168E  76        		.byte	118
 739    168F  69        		.byte	105
 740    1690  63        		.byte	99
 741    1691  65        		.byte	101
 742    1692  20        		.byte	32
 743    1693  63        		.byte	99
 744    1694  61        		.byte	97
 745    1695  70        		.byte	112
 746    1696  61        		.byte	97
 747    1697  63        		.byte	99
 748    1698  69        		.byte	105
 749    1699  74        		.byte	116
 750    169A  79        		.byte	121
 751    169B  3A        		.byte	58
 752    169C  20        		.byte	32
 753    169D  25        		.byte	37
 754    169E  6C        		.byte	108
 755    169F  75        		.byte	117
 756    16A0  20        		.byte	32
 757    16A1  4B        		.byte	75
 758    16A2  42        		.byte	66
 759    16A3  79        		.byte	121
 760    16A4  74        		.byte	116
 761    16A5  65        		.byte	101
 762    16A6  2C        		.byte	44
 763    16A7  20        		.byte	32
 764    16A8  25        		.byte	37
 765    16A9  6C        		.byte	108
 766    16AA  75        		.byte	117
 767    16AB  20        		.byte	32
 768    16AC  4D        		.byte	77
 769    16AD  42        		.byte	66
 770    16AE  79        		.byte	121
 771    16AF  74        		.byte	116
 772    16B0  65        		.byte	101
 773    16B1  0A        		.byte	10
 774    16B2  00        		.byte	0
 775                    	L5431:
 776    16B3  43        		.byte	67
 777    16B4  53        		.byte	83
 778    16B5  44        		.byte	68
 779    16B6  20        		.byte	32
 780    16B7  56        		.byte	86
 781    16B8  65        		.byte	101
 782    16B9  72        		.byte	114
 783    16BA  73        		.byte	115
 784    16BB  69        		.byte	105
 785    16BC  6F        		.byte	111
 786    16BD  6E        		.byte	110
 787    16BE  20        		.byte	32
 788    16BF  33        		.byte	51
 789    16C0  2E        		.byte	46
 790    16C1  30        		.byte	48
 791    16C2  2C        		.byte	44
 792    16C3  20        		.byte	32
 793    16C4  55        		.byte	85
 794    16C5  6C        		.byte	108
 795    16C6  74        		.byte	116
 796    16C7  72        		.byte	114
 797    16C8  61        		.byte	97
 798    16C9  20        		.byte	32
 799    16CA  43        		.byte	67
 800    16CB  61        		.byte	97
 801    16CC  70        		.byte	112
 802    16CD  61        		.byte	97
 803    16CE  63        		.byte	99
 804    16CF  69        		.byte	105
 805    16D0  74        		.byte	116
 806    16D1  79        		.byte	121
 807    16D2  20        		.byte	32
 808    16D3  28        		.byte	40
 809    16D4  53        		.byte	83
 810    16D5  44        		.byte	68
 811    16D6  55        		.byte	85
 812    16D7  43        		.byte	67
 813    16D8  29        		.byte	41
 814    16D9  0A        		.byte	10
 815    16DA  00        		.byte	0
 816                    	L5531:
 817    16DB  20        		.byte	32
 818    16DC  44        		.byte	68
 819    16DD  65        		.byte	101
 820    16DE  76        		.byte	118
 821    16DF  69        		.byte	105
 822    16E0  63        		.byte	99
 823    16E1  65        		.byte	101
 824    16E2  20        		.byte	32
 825    16E3  63        		.byte	99
 826    16E4  61        		.byte	97
 827    16E5  70        		.byte	112
 828    16E6  61        		.byte	97
 829    16E7  63        		.byte	99
 830    16E8  69        		.byte	105
 831    16E9  74        		.byte	116
 832    16EA  79        		.byte	121
 833    16EB  3A        		.byte	58
 834    16EC  20        		.byte	32
 835    16ED  25        		.byte	37
 836    16EE  6C        		.byte	108
 837    16EF  75        		.byte	117
 838    16F0  20        		.byte	32
 839    16F1  4B        		.byte	75
 840    16F2  42        		.byte	66
 841    16F3  79        		.byte	121
 842    16F4  74        		.byte	116
 843    16F5  65        		.byte	101
 844    16F6  2C        		.byte	44
 845    16F7  20        		.byte	32
 846    16F8  25        		.byte	37
 847    16F9  6C        		.byte	108
 848    16FA  75        		.byte	117
 849    16FB  20        		.byte	32
 850    16FC  4D        		.byte	77
 851    16FD  42        		.byte	66
 852    16FE  79        		.byte	121
 853    16FF  74        		.byte	116
 854    1700  65        		.byte	101
 855    1701  0A        		.byte	10
 856    1702  00        		.byte	0
 857                    	L5631:
 858    1703  2D        		.byte	45
 859    1704  2D        		.byte	45
 860    1705  2D        		.byte	45
 861    1706  2D        		.byte	45
 862    1707  2D        		.byte	45
 863    1708  2D        		.byte	45
 864    1709  2D        		.byte	45
 865    170A  2D        		.byte	45
 866    170B  2D        		.byte	45
 867    170C  2D        		.byte	45
 868    170D  2D        		.byte	45
 869    170E  2D        		.byte	45
 870    170F  2D        		.byte	45
 871    1710  2D        		.byte	45
 872    1711  2D        		.byte	45
 873    1712  2D        		.byte	45
 874    1713  2D        		.byte	45
 875    1714  2D        		.byte	45
 876    1715  2D        		.byte	45
 877    1716  2D        		.byte	45
 878    1717  2D        		.byte	45
 879    1718  2D        		.byte	45
 880    1719  2D        		.byte	45
 881    171A  2D        		.byte	45
 882    171B  2D        		.byte	45
 883    171C  2D        		.byte	45
 884    171D  2D        		.byte	45
 885    171E  2D        		.byte	45
 886    171F  2D        		.byte	45
 887    1720  2D        		.byte	45
 888    1721  2D        		.byte	45
 889    1722  2D        		.byte	45
 890    1723  2D        		.byte	45
 891    1724  2D        		.byte	45
 892    1725  2D        		.byte	45
 893    1726  2D        		.byte	45
 894    1727  2D        		.byte	45
 895    1728  2D        		.byte	45
 896    1729  0A        		.byte	10
 897    172A  00        		.byte	0
 898                    	;  612      }
 899                    	;  613  
 900                    	;  614  /* print OCR, CID and CSD registers*/
 901                    	;  615  void sdprtreg()
 902                    	;  616      {
 903                    	_sdprtreg:
 904    172B  CD0000    		call	c.savs0
 905    172E  21EEFF    		ld	hl,65518
 906    1731  39        		add	hl,sp
 907    1732  F9        		ld	sp,hl
 908                    	;  617      unsigned int n;
 909                    	;  618      unsigned int csize;
 910                    	;  619      unsigned long devsize;
 911                    	;  620      unsigned long capacity;
 912                    	;  621  
 913                    	;  622      if (!sdinitok)
 914    1733  2A0C00    		ld	hl,(_sdinitok)
 915    1736  7C        		ld	a,h
 916    1737  B5        		or	l
 917    1738  2009      		jr	nz,L1732
 918                    	;  623          {
 919                    	;  624          printf("SD card not initialized\n");
 920    173A  212511    		ld	hl,L525
 921    173D  CD0000    		call	_printf
 922                    	;  625          return;
 923    1740  C30000    		jp	c.rets0
 924                    	L1732:
 925                    	;  626          }
 926                    	;  627      printf("SD card information:");
 927    1743  213E11    		ld	hl,L535
 928    1746  CD0000    		call	_printf
 929                    	;  628      if (ocrreg[0] & 0x80)
 930    1749  3A4800    		ld	a,(_ocrreg)
 931    174C  CB7F      		bit	7,a
 932    174E  6F        		ld	l,a
 933    174F  2825      		jr	z,L1042
 934                    	;  629          {
 935                    	;  630          if (ocrreg[0] & 0x40)
 936    1751  3A4800    		ld	a,(_ocrreg)
 937    1754  CB77      		bit	6,a
 938    1756  6F        		ld	l,a
 939    1757  2808      		jr	z,L1142
 940                    	;  631              printf("  SD card ver. 2+, Block address\n");
 941    1759  215311    		ld	hl,L545
 942    175C  CD0000    		call	_printf
 943                    	;  632          else
 944    175F  1815      		jr	L1042
 945                    	L1142:
 946                    	;  633              {
 947                    	;  634              if (sdver2)
 948    1761  2A0A00    		ld	hl,(_sdver2)
 949    1764  7C        		ld	a,h
 950    1765  B5        		or	l
 951    1766  2808      		jr	z,L1342
 952                    	;  635                  printf("  SD card ver. 2+, Byte address\n");
 953    1768  217511    		ld	hl,L555
 954    176B  CD0000    		call	_printf
 955                    	;  636              else
 956    176E  1806      		jr	L1042
 957                    	L1342:
 958                    	;  637                  printf("  SD card ver. 1, Byte address\n");
 959    1770  219611    		ld	hl,L565
 960    1773  CD0000    		call	_printf
 961                    	L1042:
 962                    	;  638              }
 963                    	;  639          }
 964                    	;  640      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
 965    1776  3A3800    		ld	a,(_cidreg)
 966    1779  4F        		ld	c,a
 967    177A  97        		sub	a
 968    177B  47        		ld	b,a
 969    177C  C5        		push	bc
 970    177D  21B611    		ld	hl,L575
 971    1780  CD0000    		call	_printf
 972    1783  F1        		pop	af
 973                    	;  641      printf("OEM ID: %.2s, ", &cidreg[1]);
 974    1784  213900    		ld	hl,_cidreg+1
 975    1787  E5        		push	hl
 976    1788  21D211    		ld	hl,L506
 977    178B  CD0000    		call	_printf
 978    178E  F1        		pop	af
 979                    	;  642      printf("Product name: %.5s\n", &cidreg[3]);
 980    178F  213B00    		ld	hl,_cidreg+3
 981    1792  E5        		push	hl
 982    1793  21E111    		ld	hl,L516
 983    1796  CD0000    		call	_printf
 984    1799  F1        		pop	af
 985                    	;  643      printf("  Product revision: %d.%d, ",
 986                    	;  644             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 987    179A  3A4000    		ld	a,(_cidreg+8)
 988    179D  6F        		ld	l,a
 989    179E  97        		sub	a
 990    179F  67        		ld	h,a
 991    17A0  7D        		ld	a,l
 992    17A1  E60F      		and	15
 993    17A3  6F        		ld	l,a
 994    17A4  97        		sub	a
 995    17A5  67        		ld	h,a
 996    17A6  E5        		push	hl
 997    17A7  3A4000    		ld	a,(_cidreg+8)
 998    17AA  4F        		ld	c,a
 999    17AB  97        		sub	a
1000    17AC  47        		ld	b,a
1001    17AD  C5        		push	bc
1002    17AE  210400    		ld	hl,4
1003    17B1  E5        		push	hl
1004    17B2  CD0000    		call	c.irsh
1005    17B5  E1        		pop	hl
1006    17B6  7D        		ld	a,l
1007    17B7  E60F      		and	15
1008    17B9  6F        		ld	l,a
1009    17BA  97        		sub	a
1010    17BB  67        		ld	h,a
1011    17BC  E5        		push	hl
1012    17BD  21F511    		ld	hl,L526
1013    17C0  CD0000    		call	_printf
1014    17C3  F1        		pop	af
1015    17C4  F1        		pop	af
1016                    	;  645      printf("Serial number: %lu\n",
1017                    	;  646             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
1018    17C5  3A4100    		ld	a,(_cidreg+9)
1019    17C8  4F        		ld	c,a
1020    17C9  97        		sub	a
1021    17CA  47        		ld	b,a
1022    17CB  C5        		push	bc
1023    17CC  211800    		ld	hl,24
1024    17CF  E5        		push	hl
1025    17D0  CD0000    		call	c.ilsh
1026    17D3  E1        		pop	hl
1027    17D4  E5        		push	hl
1028    17D5  3A4200    		ld	a,(_cidreg+10)
1029    17D8  4F        		ld	c,a
1030    17D9  97        		sub	a
1031    17DA  47        		ld	b,a
1032    17DB  C5        		push	bc
1033    17DC  211000    		ld	hl,16
1034    17DF  E5        		push	hl
1035    17E0  CD0000    		call	c.ilsh
1036    17E3  E1        		pop	hl
1037    17E4  E3        		ex	(sp),hl
1038    17E5  C1        		pop	bc
1039    17E6  09        		add	hl,bc
1040    17E7  E5        		push	hl
1041    17E8  3A4300    		ld	a,(_cidreg+11)
1042    17EB  6F        		ld	l,a
1043    17EC  97        		sub	a
1044    17ED  67        		ld	h,a
1045    17EE  29        		add	hl,hl
1046    17EF  29        		add	hl,hl
1047    17F0  29        		add	hl,hl
1048    17F1  29        		add	hl,hl
1049    17F2  29        		add	hl,hl
1050    17F3  29        		add	hl,hl
1051    17F4  29        		add	hl,hl
1052    17F5  29        		add	hl,hl
1053    17F6  E3        		ex	(sp),hl
1054    17F7  C1        		pop	bc
1055    17F8  09        		add	hl,bc
1056    17F9  E5        		push	hl
1057    17FA  3A4400    		ld	a,(_cidreg+12)
1058    17FD  6F        		ld	l,a
1059    17FE  97        		sub	a
1060    17FF  67        		ld	h,a
1061    1800  E3        		ex	(sp),hl
1062    1801  C1        		pop	bc
1063    1802  09        		add	hl,bc
1064    1803  E5        		push	hl
1065    1804  211112    		ld	hl,L536
1066    1807  CD0000    		call	_printf
1067    180A  F1        		pop	af
1068                    	;  647      printf("  Manufacturing date: %d-%d, ",
1069                    	;  648             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
1070    180B  3A4600    		ld	a,(_cidreg+14)
1071    180E  6F        		ld	l,a
1072    180F  97        		sub	a
1073    1810  67        		ld	h,a
1074    1811  7D        		ld	a,l
1075    1812  E60F      		and	15
1076    1814  6F        		ld	l,a
1077    1815  97        		sub	a
1078    1816  67        		ld	h,a
1079    1817  E5        		push	hl
1080    1818  3A4500    		ld	a,(_cidreg+13)
1081    181B  6F        		ld	l,a
1082    181C  97        		sub	a
1083    181D  67        		ld	h,a
1084    181E  7D        		ld	a,l
1085    181F  E60F      		and	15
1086    1821  6F        		ld	l,a
1087    1822  97        		sub	a
1088    1823  67        		ld	h,a
1089    1824  29        		add	hl,hl
1090    1825  29        		add	hl,hl
1091    1826  29        		add	hl,hl
1092    1827  29        		add	hl,hl
1093    1828  01D007    		ld	bc,2000
1094    182B  09        		add	hl,bc
1095    182C  E5        		push	hl
1096    182D  3A4600    		ld	a,(_cidreg+14)
1097    1830  4F        		ld	c,a
1098    1831  97        		sub	a
1099    1832  47        		ld	b,a
1100    1833  C5        		push	bc
1101    1834  210400    		ld	hl,4
1102    1837  E5        		push	hl
1103    1838  CD0000    		call	c.irsh
1104    183B  E1        		pop	hl
1105    183C  E3        		ex	(sp),hl
1106    183D  C1        		pop	bc
1107    183E  09        		add	hl,bc
1108    183F  E5        		push	hl
1109    1840  212512    		ld	hl,L546
1110    1843  CD0000    		call	_printf
1111    1846  F1        		pop	af
1112    1847  F1        		pop	af
1113                    	;  649      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
1114    1848  3A2800    		ld	a,(_csdreg)
1115    184B  E6C0      		and	192
1116    184D  C22B19    		jp	nz,L1542
1117                    	;  650          {
1118                    	;  651          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
1119    1850  3A2D00    		ld	a,(_csdreg+5)
1120    1853  6F        		ld	l,a
1121    1854  97        		sub	a
1122    1855  67        		ld	h,a
1123    1856  7D        		ld	a,l
1124    1857  E60F      		and	15
1125    1859  6F        		ld	l,a
1126    185A  97        		sub	a
1127    185B  67        		ld	h,a
1128    185C  E5        		push	hl
1129    185D  3A3200    		ld	a,(_csdreg+10)
1130    1860  6F        		ld	l,a
1131    1861  97        		sub	a
1132    1862  67        		ld	h,a
1133    1863  7D        		ld	a,l
1134    1864  E680      		and	128
1135    1866  6F        		ld	l,a
1136    1867  97        		sub	a
1137    1868  67        		ld	h,a
1138    1869  E5        		push	hl
1139    186A  210700    		ld	hl,7
1140    186D  E5        		push	hl
1141    186E  CD0000    		call	c.irsh
1142    1871  E1        		pop	hl
1143    1872  E3        		ex	(sp),hl
1144    1873  C1        		pop	bc
1145    1874  09        		add	hl,bc
1146    1875  E5        		push	hl
1147    1876  3A3100    		ld	a,(_csdreg+9)
1148    1879  6F        		ld	l,a
1149    187A  97        		sub	a
1150    187B  67        		ld	h,a
1151    187C  7D        		ld	a,l
1152    187D  E603      		and	3
1153    187F  6F        		ld	l,a
1154    1880  97        		sub	a
1155    1881  67        		ld	h,a
1156    1882  29        		add	hl,hl
1157    1883  E3        		ex	(sp),hl
1158    1884  C1        		pop	bc
1159    1885  09        		add	hl,bc
1160    1886  23        		inc	hl
1161    1887  23        		inc	hl
1162    1888  DD75F8    		ld	(ix-8),l
1163    188B  DD74F9    		ld	(ix-7),h
1164                    	;  652          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
1165                    	;  653                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
1166    188E  3A3000    		ld	a,(_csdreg+8)
1167    1891  4F        		ld	c,a
1168    1892  97        		sub	a
1169    1893  47        		ld	b,a
1170    1894  C5        		push	bc
1171    1895  210600    		ld	hl,6
1172    1898  E5        		push	hl
1173    1899  CD0000    		call	c.irsh
1174    189C  E1        		pop	hl
1175    189D  E5        		push	hl
1176    189E  3A2F00    		ld	a,(_csdreg+7)
1177    18A1  6F        		ld	l,a
1178    18A2  97        		sub	a
1179    18A3  67        		ld	h,a
1180    18A4  29        		add	hl,hl
1181    18A5  29        		add	hl,hl
1182    18A6  E3        		ex	(sp),hl
1183    18A7  C1        		pop	bc
1184    18A8  09        		add	hl,bc
1185    18A9  E5        		push	hl
1186    18AA  3A2E00    		ld	a,(_csdreg+6)
1187    18AD  6F        		ld	l,a
1188    18AE  97        		sub	a
1189    18AF  67        		ld	h,a
1190    18B0  7D        		ld	a,l
1191    18B1  E603      		and	3
1192    18B3  6F        		ld	l,a
1193    18B4  97        		sub	a
1194    18B5  67        		ld	h,a
1195    18B6  E5        		push	hl
1196    18B7  210A00    		ld	hl,10
1197    18BA  E5        		push	hl
1198    18BB  CD0000    		call	c.ilsh
1199    18BE  E1        		pop	hl
1200    18BF  E3        		ex	(sp),hl
1201    18C0  C1        		pop	bc
1202    18C1  09        		add	hl,bc
1203    18C2  23        		inc	hl
1204    18C3  DD75F6    		ld	(ix-10),l
1205    18C6  DD74F7    		ld	(ix-9),h
1206                    	;  654          capacity = (unsigned long) csize << (n-10);
1207    18C9  DDE5      		push	ix
1208    18CB  C1        		pop	bc
1209    18CC  21EEFF    		ld	hl,65518
1210    18CF  09        		add	hl,bc
1211    18D0  E5        		push	hl
1212    18D1  DDE5      		push	ix
1213    18D3  C1        		pop	bc
1214    18D4  21F6FF    		ld	hl,65526
1215    18D7  09        		add	hl,bc
1216    18D8  4D        		ld	c,l
1217    18D9  44        		ld	b,h
1218    18DA  97        		sub	a
1219    18DB  320000    		ld	(c.r0),a
1220    18DE  320100    		ld	(c.r0+1),a
1221    18E1  0A        		ld	a,(bc)
1222    18E2  320200    		ld	(c.r0+2),a
1223    18E5  03        		inc	bc
1224    18E6  0A        		ld	a,(bc)
1225    18E7  320300    		ld	(c.r0+3),a
1226    18EA  210000    		ld	hl,c.r0
1227    18ED  E5        		push	hl
1228    18EE  DD6EF8    		ld	l,(ix-8)
1229    18F1  DD66F9    		ld	h,(ix-7)
1230    18F4  01F6FF    		ld	bc,65526
1231    18F7  09        		add	hl,bc
1232    18F8  E5        		push	hl
1233    18F9  CD0000    		call	c.llsh
1234    18FC  CD0000    		call	c.mvl
1235    18FF  F1        		pop	af
1236                    	;  655          printf("Device capacity: %lu MByte\n", capacity >> 10);
1237    1900  DDE5      		push	ix
1238    1902  C1        		pop	bc
1239    1903  21EEFF    		ld	hl,65518
1240    1906  09        		add	hl,bc
1241    1907  CD0000    		call	c.0mvf
1242    190A  210000    		ld	hl,c.r0
1243    190D  E5        		push	hl
1244    190E  210A00    		ld	hl,10
1245    1911  E5        		push	hl
1246    1912  CD0000    		call	c.ulrsh
1247    1915  E1        		pop	hl
1248    1916  23        		inc	hl
1249    1917  23        		inc	hl
1250    1918  4E        		ld	c,(hl)
1251    1919  23        		inc	hl
1252    191A  46        		ld	b,(hl)
1253    191B  C5        		push	bc
1254    191C  2B        		dec	hl
1255    191D  2B        		dec	hl
1256    191E  2B        		dec	hl
1257    191F  4E        		ld	c,(hl)
1258    1920  23        		inc	hl
1259    1921  46        		ld	b,(hl)
1260    1922  C5        		push	bc
1261    1923  214312    		ld	hl,L556
1262    1926  CD0000    		call	_printf
1263    1929  F1        		pop	af
1264    192A  F1        		pop	af
1265                    	L1542:
1266                    	;  656          }
1267                    	;  657      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
1268    192B  3A2800    		ld	a,(_csdreg)
1269    192E  6F        		ld	l,a
1270    192F  97        		sub	a
1271    1930  67        		ld	h,a
1272    1931  7D        		ld	a,l
1273    1932  E6C0      		and	192
1274    1934  6F        		ld	l,a
1275    1935  97        		sub	a
1276    1936  67        		ld	h,a
1277    1937  7D        		ld	a,l
1278    1938  FE40      		cp	64
1279    193A  2003      		jr	nz,L27
1280    193C  7C        		ld	a,h
1281    193D  FE00      		cp	0
1282                    	L27:
1283    193F  C2121A    		jp	nz,L1642
1284                    	;  658          {
1285                    	;  659          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
1286                    	;  660                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1287    1942  DDE5      		push	ix
1288    1944  C1        		pop	bc
1289    1945  21F2FF    		ld	hl,65522
1290    1948  09        		add	hl,bc
1291    1949  E5        		push	hl
1292    194A  97        		sub	a
1293    194B  320000    		ld	(c.r0),a
1294    194E  320100    		ld	(c.r0+1),a
1295    1951  3A3000    		ld	a,(_csdreg+8)
1296    1954  320200    		ld	(c.r0+2),a
1297    1957  97        		sub	a
1298    1958  320300    		ld	(c.r0+3),a
1299    195B  210000    		ld	hl,c.r0
1300    195E  E5        		push	hl
1301    195F  210800    		ld	hl,8
1302    1962  E5        		push	hl
1303    1963  CD0000    		call	c.llsh
1304    1966  97        		sub	a
1305    1967  320000    		ld	(c.r1),a
1306    196A  320100    		ld	(c.r1+1),a
1307    196D  3A3100    		ld	a,(_csdreg+9)
1308    1970  320200    		ld	(c.r1+2),a
1309    1973  97        		sub	a
1310    1974  320300    		ld	(c.r1+3),a
1311    1977  210000    		ld	hl,c.r1
1312    197A  E5        		push	hl
1313    197B  CD0000    		call	c.ladd
1314    197E  3A2F00    		ld	a,(_csdreg+7)
1315    1981  6F        		ld	l,a
1316    1982  97        		sub	a
1317    1983  67        		ld	h,a
1318    1984  7D        		ld	a,l
1319    1985  E63F      		and	63
1320    1987  6F        		ld	l,a
1321    1988  97        		sub	a
1322    1989  67        		ld	h,a
1323    198A  4D        		ld	c,l
1324    198B  44        		ld	b,h
1325    198C  78        		ld	a,b
1326    198D  87        		add	a,a
1327    198E  9F        		sbc	a,a
1328    198F  320000    		ld	(c.r1),a
1329    1992  320100    		ld	(c.r1+1),a
1330    1995  78        		ld	a,b
1331    1996  320300    		ld	(c.r1+3),a
1332    1999  79        		ld	a,c
1333    199A  320200    		ld	(c.r1+2),a
1334    199D  210000    		ld	hl,c.r1
1335    19A0  E5        		push	hl
1336    19A1  211000    		ld	hl,16
1337    19A4  E5        		push	hl
1338    19A5  CD0000    		call	c.llsh
1339    19A8  CD0000    		call	c.ladd
1340    19AB  3E01      		ld	a,1
1341    19AD  320200    		ld	(c.r1+2),a
1342    19B0  87        		add	a,a
1343    19B1  9F        		sbc	a,a
1344    19B2  320300    		ld	(c.r1+3),a
1345    19B5  320100    		ld	(c.r1+1),a
1346    19B8  320000    		ld	(c.r1),a
1347    19BB  210000    		ld	hl,c.r1
1348    19BE  E5        		push	hl
1349    19BF  CD0000    		call	c.ladd
1350    19C2  CD0000    		call	c.mvl
1351    19C5  F1        		pop	af
1352                    	;  661          capacity = devsize << 9;
1353    19C6  DDE5      		push	ix
1354    19C8  C1        		pop	bc
1355    19C9  21EEFF    		ld	hl,65518
1356    19CC  09        		add	hl,bc
1357    19CD  E5        		push	hl
1358    19CE  DDE5      		push	ix
1359    19D0  C1        		pop	bc
1360    19D1  21F2FF    		ld	hl,65522
1361    19D4  09        		add	hl,bc
1362    19D5  CD0000    		call	c.0mvf
1363    19D8  210000    		ld	hl,c.r0
1364    19DB  E5        		push	hl
1365    19DC  210900    		ld	hl,9
1366    19DF  E5        		push	hl
1367    19E0  CD0000    		call	c.llsh
1368    19E3  CD0000    		call	c.mvl
1369    19E6  F1        		pop	af
1370                    	;  662          printf("Device capacity: %lu MByte\n", capacity >> 10);
1371    19E7  DDE5      		push	ix
1372    19E9  C1        		pop	bc
1373    19EA  21EEFF    		ld	hl,65518
1374    19ED  09        		add	hl,bc
1375    19EE  CD0000    		call	c.0mvf
1376    19F1  210000    		ld	hl,c.r0
1377    19F4  E5        		push	hl
1378    19F5  210A00    		ld	hl,10
1379    19F8  E5        		push	hl
1380    19F9  CD0000    		call	c.ulrsh
1381    19FC  E1        		pop	hl
1382    19FD  23        		inc	hl
1383    19FE  23        		inc	hl
1384    19FF  4E        		ld	c,(hl)
1385    1A00  23        		inc	hl
1386    1A01  46        		ld	b,(hl)
1387    1A02  C5        		push	bc
1388    1A03  2B        		dec	hl
1389    1A04  2B        		dec	hl
1390    1A05  2B        		dec	hl
1391    1A06  4E        		ld	c,(hl)
1392    1A07  23        		inc	hl
1393    1A08  46        		ld	b,(hl)
1394    1A09  C5        		push	bc
1395    1A0A  215F12    		ld	hl,L566
1396    1A0D  CD0000    		call	_printf
1397    1A10  F1        		pop	af
1398    1A11  F1        		pop	af
1399                    	L1642:
1400                    	;  663          }
1401                    	;  664      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
1402    1A12  3A2800    		ld	a,(_csdreg)
1403    1A15  6F        		ld	l,a
1404    1A16  97        		sub	a
1405    1A17  67        		ld	h,a
1406    1A18  7D        		ld	a,l
1407    1A19  E6C0      		and	192
1408    1A1B  6F        		ld	l,a
1409    1A1C  97        		sub	a
1410    1A1D  67        		ld	h,a
1411    1A1E  7D        		ld	a,l
1412    1A1F  FE80      		cp	128
1413    1A21  2003      		jr	nz,L47
1414    1A23  7C        		ld	a,h
1415    1A24  FE00      		cp	0
1416                    	L47:
1417    1A26  C2F91A    		jp	nz,L1742
1418                    	;  665          {
1419                    	;  666          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
1420                    	;  667                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1421    1A29  DDE5      		push	ix
1422    1A2B  C1        		pop	bc
1423    1A2C  21F2FF    		ld	hl,65522
1424    1A2F  09        		add	hl,bc
1425    1A30  E5        		push	hl
1426    1A31  97        		sub	a
1427    1A32  320000    		ld	(c.r0),a
1428    1A35  320100    		ld	(c.r0+1),a
1429    1A38  3A3000    		ld	a,(_csdreg+8)
1430    1A3B  320200    		ld	(c.r0+2),a
1431    1A3E  97        		sub	a
1432    1A3F  320300    		ld	(c.r0+3),a
1433    1A42  210000    		ld	hl,c.r0
1434    1A45  E5        		push	hl
1435    1A46  210800    		ld	hl,8
1436    1A49  E5        		push	hl
1437    1A4A  CD0000    		call	c.llsh
1438    1A4D  97        		sub	a
1439    1A4E  320000    		ld	(c.r1),a
1440    1A51  320100    		ld	(c.r1+1),a
1441    1A54  3A3100    		ld	a,(_csdreg+9)
1442    1A57  320200    		ld	(c.r1+2),a
1443    1A5A  97        		sub	a
1444    1A5B  320300    		ld	(c.r1+3),a
1445    1A5E  210000    		ld	hl,c.r1
1446    1A61  E5        		push	hl
1447    1A62  CD0000    		call	c.ladd
1448    1A65  3A2F00    		ld	a,(_csdreg+7)
1449    1A68  6F        		ld	l,a
1450    1A69  97        		sub	a
1451    1A6A  67        		ld	h,a
1452    1A6B  7D        		ld	a,l
1453    1A6C  E63F      		and	63
1454    1A6E  6F        		ld	l,a
1455    1A6F  97        		sub	a
1456    1A70  67        		ld	h,a
1457    1A71  4D        		ld	c,l
1458    1A72  44        		ld	b,h
1459    1A73  78        		ld	a,b
1460    1A74  87        		add	a,a
1461    1A75  9F        		sbc	a,a
1462    1A76  320000    		ld	(c.r1),a
1463    1A79  320100    		ld	(c.r1+1),a
1464    1A7C  78        		ld	a,b
1465    1A7D  320300    		ld	(c.r1+3),a
1466    1A80  79        		ld	a,c
1467    1A81  320200    		ld	(c.r1+2),a
1468    1A84  210000    		ld	hl,c.r1
1469    1A87  E5        		push	hl
1470    1A88  211000    		ld	hl,16
1471    1A8B  E5        		push	hl
1472    1A8C  CD0000    		call	c.llsh
1473    1A8F  CD0000    		call	c.ladd
1474    1A92  3E01      		ld	a,1
1475    1A94  320200    		ld	(c.r1+2),a
1476    1A97  87        		add	a,a
1477    1A98  9F        		sbc	a,a
1478    1A99  320300    		ld	(c.r1+3),a
1479    1A9C  320100    		ld	(c.r1+1),a
1480    1A9F  320000    		ld	(c.r1),a
1481    1AA2  210000    		ld	hl,c.r1
1482    1AA5  E5        		push	hl
1483    1AA6  CD0000    		call	c.ladd
1484    1AA9  CD0000    		call	c.mvl
1485    1AAC  F1        		pop	af
1486                    	;  668          capacity = devsize << 9;
1487    1AAD  DDE5      		push	ix
1488    1AAF  C1        		pop	bc
1489    1AB0  21EEFF    		ld	hl,65518
1490    1AB3  09        		add	hl,bc
1491    1AB4  E5        		push	hl
1492    1AB5  DDE5      		push	ix
1493    1AB7  C1        		pop	bc
1494    1AB8  21F2FF    		ld	hl,65522
1495    1ABB  09        		add	hl,bc
1496    1ABC  CD0000    		call	c.0mvf
1497    1ABF  210000    		ld	hl,c.r0
1498    1AC2  E5        		push	hl
1499    1AC3  210900    		ld	hl,9
1500    1AC6  E5        		push	hl
1501    1AC7  CD0000    		call	c.llsh
1502    1ACA  CD0000    		call	c.mvl
1503    1ACD  F1        		pop	af
1504                    	;  669          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
1505    1ACE  DDE5      		push	ix
1506    1AD0  C1        		pop	bc
1507    1AD1  21EEFF    		ld	hl,65518
1508    1AD4  09        		add	hl,bc
1509    1AD5  CD0000    		call	c.0mvf
1510    1AD8  210000    		ld	hl,c.r0
1511    1ADB  E5        		push	hl
1512    1ADC  210A00    		ld	hl,10
1513    1ADF  E5        		push	hl
1514    1AE0  CD0000    		call	c.ulrsh
1515    1AE3  E1        		pop	hl
1516    1AE4  23        		inc	hl
1517    1AE5  23        		inc	hl
1518    1AE6  4E        		ld	c,(hl)
1519    1AE7  23        		inc	hl
1520    1AE8  46        		ld	b,(hl)
1521    1AE9  C5        		push	bc
1522    1AEA  2B        		dec	hl
1523    1AEB  2B        		dec	hl
1524    1AEC  2B        		dec	hl
1525    1AED  4E        		ld	c,(hl)
1526    1AEE  23        		inc	hl
1527    1AEF  46        		ld	b,(hl)
1528    1AF0  C5        		push	bc
1529    1AF1  217B12    		ld	hl,L576
1530    1AF4  CD0000    		call	_printf
1531    1AF7  F1        		pop	af
1532    1AF8  F1        		pop	af
1533                    	L1742:
1534                    	;  670          }
1535                    	;  671  
1536                    	;  672      if (sdtestflg)
1537    1AF9  2A0000    		ld	hl,(_sdtestflg)
1538    1AFC  7C        		ld	a,h
1539    1AFD  B5        		or	l
1540    1AFE  CAE51F    		jp	z,L1052
1541                    	;  673          {
1542                    	;  674  
1543                    	;  675          printf("--------------------------------------\n");
1544    1B01  219D12    		ld	hl,L507
1545    1B04  CD0000    		call	_printf
1546                    	;  676          printf("OCR register:\n");
1547    1B07  21C512    		ld	hl,L517
1548    1B0A  CD0000    		call	_printf
1549                    	;  677          if (ocrreg[2] & 0x80)
1550    1B0D  3A4A00    		ld	a,(_ocrreg+2)
1551    1B10  CB7F      		bit	7,a
1552    1B12  6F        		ld	l,a
1553    1B13  2806      		jr	z,L1152
1554                    	;  678              printf("2.7-2.8V (bit 15) ");
1555    1B15  21D412    		ld	hl,L527
1556    1B18  CD0000    		call	_printf
1557                    	L1152:
1558                    	;  679          if (ocrreg[1] & 0x01)
1559    1B1B  3A4900    		ld	a,(_ocrreg+1)
1560    1B1E  CB47      		bit	0,a
1561    1B20  6F        		ld	l,a
1562    1B21  2806      		jr	z,L1252
1563                    	;  680              printf("2.8-2.9V (bit 16) ");
1564    1B23  21E712    		ld	hl,L537
1565    1B26  CD0000    		call	_printf
1566                    	L1252:
1567                    	;  681          if (ocrreg[1] & 0x02)
1568    1B29  3A4900    		ld	a,(_ocrreg+1)
1569    1B2C  CB4F      		bit	1,a
1570    1B2E  6F        		ld	l,a
1571    1B2F  2806      		jr	z,L1352
1572                    	;  682              printf("2.9-3.0V (bit 17) ");
1573    1B31  21FA12    		ld	hl,L547
1574    1B34  CD0000    		call	_printf
1575                    	L1352:
1576                    	;  683          if (ocrreg[1] & 0x04)
1577    1B37  3A4900    		ld	a,(_ocrreg+1)
1578    1B3A  CB57      		bit	2,a
1579    1B3C  6F        		ld	l,a
1580    1B3D  2806      		jr	z,L1452
1581                    	;  684              printf("3.0-3.1V (bit 18) \n");
1582    1B3F  210D13    		ld	hl,L557
1583    1B42  CD0000    		call	_printf
1584                    	L1452:
1585                    	;  685          if (ocrreg[1] & 0x08)
1586    1B45  3A4900    		ld	a,(_ocrreg+1)
1587    1B48  CB5F      		bit	3,a
1588    1B4A  6F        		ld	l,a
1589    1B4B  2806      		jr	z,L1552
1590                    	;  686              printf("3.1-3.2V (bit 19) ");
1591    1B4D  212113    		ld	hl,L567
1592    1B50  CD0000    		call	_printf
1593                    	L1552:
1594                    	;  687          if (ocrreg[1] & 0x10)
1595    1B53  3A4900    		ld	a,(_ocrreg+1)
1596    1B56  CB67      		bit	4,a
1597    1B58  6F        		ld	l,a
1598    1B59  2806      		jr	z,L1652
1599                    	;  688              printf("3.2-3.3V (bit 20) ");
1600    1B5B  213413    		ld	hl,L577
1601    1B5E  CD0000    		call	_printf
1602                    	L1652:
1603                    	;  689          if (ocrreg[1] & 0x20)
1604    1B61  3A4900    		ld	a,(_ocrreg+1)
1605    1B64  CB6F      		bit	5,a
1606    1B66  6F        		ld	l,a
1607    1B67  2806      		jr	z,L1752
1608                    	;  690              printf("3.3-3.4V (bit 21) ");
1609    1B69  214713    		ld	hl,L5001
1610    1B6C  CD0000    		call	_printf
1611                    	L1752:
1612                    	;  691          if (ocrreg[1] & 0x40)
1613    1B6F  3A4900    		ld	a,(_ocrreg+1)
1614    1B72  CB77      		bit	6,a
1615    1B74  6F        		ld	l,a
1616    1B75  2806      		jr	z,L1062
1617                    	;  692              printf("3.4-3.5V (bit 22) \n");
1618    1B77  215A13    		ld	hl,L5101
1619    1B7A  CD0000    		call	_printf
1620                    	L1062:
1621                    	;  693          if (ocrreg[1] & 0x80)
1622    1B7D  3A4900    		ld	a,(_ocrreg+1)
1623    1B80  CB7F      		bit	7,a
1624    1B82  6F        		ld	l,a
1625    1B83  2806      		jr	z,L1162
1626                    	;  694              printf("3.5-3.6V (bit 23) \n");
1627    1B85  216E13    		ld	hl,L5201
1628    1B88  CD0000    		call	_printf
1629                    	L1162:
1630                    	;  695          if (ocrreg[0] & 0x01)
1631    1B8B  3A4800    		ld	a,(_ocrreg)
1632    1B8E  CB47      		bit	0,a
1633    1B90  6F        		ld	l,a
1634    1B91  2806      		jr	z,L1262
1635                    	;  696              printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
1636    1B93  218213    		ld	hl,L5301
1637    1B96  CD0000    		call	_printf
1638                    	L1262:
1639                    	;  697          if (ocrreg[0] & 0x08)
1640    1B99  3A4800    		ld	a,(_ocrreg)
1641    1B9C  CB5F      		bit	3,a
1642    1B9E  6F        		ld	l,a
1643    1B9F  2806      		jr	z,L1362
1644                    	;  698              printf("Over 2TB support Status (CO2T) (bit 27) set\n");
1645    1BA1  21B213    		ld	hl,L5401
1646    1BA4  CD0000    		call	_printf
1647                    	L1362:
1648                    	;  699          if (ocrreg[0] & 0x20)
1649    1BA7  3A4800    		ld	a,(_ocrreg)
1650    1BAA  CB6F      		bit	5,a
1651    1BAC  6F        		ld	l,a
1652    1BAD  2806      		jr	z,L1462
1653                    	;  700              printf("UHS-II Card Status (bit 29) set ");
1654    1BAF  21DF13    		ld	hl,L5501
1655    1BB2  CD0000    		call	_printf
1656                    	L1462:
1657                    	;  701          if (ocrreg[0] & 0x80)
1658    1BB5  3A4800    		ld	a,(_ocrreg)
1659    1BB8  CB7F      		bit	7,a
1660    1BBA  6F        		ld	l,a
1661    1BBB  2839      		jr	z,L1562
1662                    	;  702              {
1663                    	;  703              if (ocrreg[0] & 0x40)
1664    1BBD  3A4800    		ld	a,(_ocrreg)
1665    1BC0  CB77      		bit	6,a
1666    1BC2  6F        		ld	l,a
1667    1BC3  280E      		jr	z,L1662
1668                    	;  704                  {
1669                    	;  705                  printf("Card Capacity Status (CCS) (bit 30) set\n");
1670    1BC5  210014    		ld	hl,L5601
1671    1BC8  CD0000    		call	_printf
1672                    	;  706                  printf("  SD Ver.2+, Block address");
1673    1BCB  212914    		ld	hl,L5701
1674    1BCE  CD0000    		call	_printf
1675                    	;  707                  }
1676                    	;  708              else
1677    1BD1  181B      		jr	L1762
1678                    	L1662:
1679                    	;  709                  {
1680                    	;  710                  printf("Card Capacity Status (CCS) (bit 30) not set\n");
1681    1BD3  214414    		ld	hl,L5011
1682    1BD6  CD0000    		call	_printf
1683                    	;  711                  if (sdver2)
1684    1BD9  2A0A00    		ld	hl,(_sdver2)
1685    1BDC  7C        		ld	a,h
1686    1BDD  B5        		or	l
1687    1BDE  2808      		jr	z,L1072
1688                    	;  712                      printf("  SD Ver.2+, Byte address");
1689    1BE0  217114    		ld	hl,L5111
1690    1BE3  CD0000    		call	_printf
1691                    	;  713                  else
1692    1BE6  1806      		jr	L1762
1693                    	L1072:
1694                    	;  714                      printf("  SD Ver.1, Byte address");
1695    1BE8  218B14    		ld	hl,L5211
1696    1BEB  CD0000    		call	_printf
1697                    	L1762:
1698                    	;  715                  }
1699                    	;  716              printf("\nCard power up status bit (busy) (bit 31) set\n");
1700    1BEE  21A414    		ld	hl,L5311
1701    1BF1  CD0000    		call	_printf
1702                    	;  717              }
1703                    	;  718          else
1704    1BF4  180C      		jr	L1272
1705                    	L1562:
1706                    	;  719              {
1707                    	;  720              printf("\nCard power up status bit (busy) (bit 31) not set.\n");
1708    1BF6  21D314    		ld	hl,L5411
1709    1BF9  CD0000    		call	_printf
1710                    	;  721              printf("  This bit is not set if the card has not finished the power up routine.\n");
1711    1BFC  210715    		ld	hl,L5511
1712    1BFF  CD0000    		call	_printf
1713                    	L1272:
1714                    	;  722              }
1715                    	;  723          printf("--------------------------------------\n");
1716    1C02  215115    		ld	hl,L5611
1717    1C05  CD0000    		call	_printf
1718                    	;  724          printf("CID register:\n");
1719    1C08  217915    		ld	hl,L5711
1720    1C0B  CD0000    		call	_printf
1721                    	;  725          printf("MID: 0x%02x, ", cidreg[0]);
1722    1C0E  3A3800    		ld	a,(_cidreg)
1723    1C11  4F        		ld	c,a
1724    1C12  97        		sub	a
1725    1C13  47        		ld	b,a
1726    1C14  C5        		push	bc
1727    1C15  218815    		ld	hl,L5021
1728    1C18  CD0000    		call	_printf
1729    1C1B  F1        		pop	af
1730                    	;  726          printf("OID: %.2s, ", &cidreg[1]);
1731    1C1C  213900    		ld	hl,_cidreg+1
1732    1C1F  E5        		push	hl
1733    1C20  219615    		ld	hl,L5121
1734    1C23  CD0000    		call	_printf
1735    1C26  F1        		pop	af
1736                    	;  727          printf("PNM: %.5s, ", &cidreg[3]);
1737    1C27  213B00    		ld	hl,_cidreg+3
1738    1C2A  E5        		push	hl
1739    1C2B  21A215    		ld	hl,L5221
1740    1C2E  CD0000    		call	_printf
1741    1C31  F1        		pop	af
1742                    	;  728          printf("PRV: %d.%d, ",
1743                    	;  729                 (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
1744    1C32  3A4000    		ld	a,(_cidreg+8)
1745    1C35  6F        		ld	l,a
1746    1C36  97        		sub	a
1747    1C37  67        		ld	h,a
1748    1C38  7D        		ld	a,l
1749    1C39  E60F      		and	15
1750    1C3B  6F        		ld	l,a
1751    1C3C  97        		sub	a
1752    1C3D  67        		ld	h,a
1753    1C3E  E5        		push	hl
1754    1C3F  3A4000    		ld	a,(_cidreg+8)
1755    1C42  4F        		ld	c,a
1756    1C43  97        		sub	a
1757    1C44  47        		ld	b,a
1758    1C45  C5        		push	bc
1759    1C46  210400    		ld	hl,4
1760    1C49  E5        		push	hl
1761    1C4A  CD0000    		call	c.irsh
1762    1C4D  E1        		pop	hl
1763    1C4E  7D        		ld	a,l
1764    1C4F  E60F      		and	15
1765    1C51  6F        		ld	l,a
1766    1C52  97        		sub	a
1767    1C53  67        		ld	h,a
1768    1C54  E5        		push	hl
1769    1C55  21AE15    		ld	hl,L5321
1770    1C58  CD0000    		call	_printf
1771    1C5B  F1        		pop	af
1772    1C5C  F1        		pop	af
1773                    	;  730          printf("PSN: %lu, ",
1774                    	;  731                 (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
1775    1C5D  3A4100    		ld	a,(_cidreg+9)
1776    1C60  4F        		ld	c,a
1777    1C61  97        		sub	a
1778    1C62  47        		ld	b,a
1779    1C63  C5        		push	bc
1780    1C64  211800    		ld	hl,24
1781    1C67  E5        		push	hl
1782    1C68  CD0000    		call	c.ilsh
1783    1C6B  E1        		pop	hl
1784    1C6C  E5        		push	hl
1785    1C6D  3A4200    		ld	a,(_cidreg+10)
1786    1C70  4F        		ld	c,a
1787    1C71  97        		sub	a
1788    1C72  47        		ld	b,a
1789    1C73  C5        		push	bc
1790    1C74  211000    		ld	hl,16
1791    1C77  E5        		push	hl
1792    1C78  CD0000    		call	c.ilsh
1793    1C7B  E1        		pop	hl
1794    1C7C  E3        		ex	(sp),hl
1795    1C7D  C1        		pop	bc
1796    1C7E  09        		add	hl,bc
1797    1C7F  E5        		push	hl
1798    1C80  3A4300    		ld	a,(_cidreg+11)
1799    1C83  6F        		ld	l,a
1800    1C84  97        		sub	a
1801    1C85  67        		ld	h,a
1802    1C86  29        		add	hl,hl
1803    1C87  29        		add	hl,hl
1804    1C88  29        		add	hl,hl
1805    1C89  29        		add	hl,hl
1806    1C8A  29        		add	hl,hl
1807    1C8B  29        		add	hl,hl
1808    1C8C  29        		add	hl,hl
1809    1C8D  29        		add	hl,hl
1810    1C8E  E3        		ex	(sp),hl
1811    1C8F  C1        		pop	bc
1812    1C90  09        		add	hl,bc
1813    1C91  E5        		push	hl
1814    1C92  3A4400    		ld	a,(_cidreg+12)
1815    1C95  6F        		ld	l,a
1816    1C96  97        		sub	a
1817    1C97  67        		ld	h,a
1818    1C98  E3        		ex	(sp),hl
1819    1C99  C1        		pop	bc
1820    1C9A  09        		add	hl,bc
1821    1C9B  E5        		push	hl
1822    1C9C  21BB15    		ld	hl,L5421
1823    1C9F  CD0000    		call	_printf
1824    1CA2  F1        		pop	af
1825                    	;  732          printf("MDT: %d-%d\n",
1826                    	;  733                 2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
1827    1CA3  3A4600    		ld	a,(_cidreg+14)
1828    1CA6  6F        		ld	l,a
1829    1CA7  97        		sub	a
1830    1CA8  67        		ld	h,a
1831    1CA9  7D        		ld	a,l
1832    1CAA  E60F      		and	15
1833    1CAC  6F        		ld	l,a
1834    1CAD  97        		sub	a
1835    1CAE  67        		ld	h,a
1836    1CAF  E5        		push	hl
1837    1CB0  3A4500    		ld	a,(_cidreg+13)
1838    1CB3  6F        		ld	l,a
1839    1CB4  97        		sub	a
1840    1CB5  67        		ld	h,a
1841    1CB6  7D        		ld	a,l
1842    1CB7  E60F      		and	15
1843    1CB9  6F        		ld	l,a
1844    1CBA  97        		sub	a
1845    1CBB  67        		ld	h,a
1846    1CBC  29        		add	hl,hl
1847    1CBD  29        		add	hl,hl
1848    1CBE  29        		add	hl,hl
1849    1CBF  29        		add	hl,hl
1850    1CC0  01D007    		ld	bc,2000
1851    1CC3  09        		add	hl,bc
1852    1CC4  E5        		push	hl
1853    1CC5  3A4600    		ld	a,(_cidreg+14)
1854    1CC8  4F        		ld	c,a
1855    1CC9  97        		sub	a
1856    1CCA  47        		ld	b,a
1857    1CCB  C5        		push	bc
1858    1CCC  210400    		ld	hl,4
1859    1CCF  E5        		push	hl
1860    1CD0  CD0000    		call	c.irsh
1861    1CD3  E1        		pop	hl
1862    1CD4  E3        		ex	(sp),hl
1863    1CD5  C1        		pop	bc
1864    1CD6  09        		add	hl,bc
1865    1CD7  E5        		push	hl
1866    1CD8  21C615    		ld	hl,L5521
1867    1CDB  CD0000    		call	_printf
1868    1CDE  F1        		pop	af
1869    1CDF  F1        		pop	af
1870                    	;  734          printf("--------------------------------------\n");
1871    1CE0  21D215    		ld	hl,L5621
1872    1CE3  CD0000    		call	_printf
1873                    	;  735          printf("CSD register:\n");
1874    1CE6  21FA15    		ld	hl,L5721
1875    1CE9  CD0000    		call	_printf
1876                    	;  736          if ((csdreg[0] & 0xc0) == 0x00)
1877    1CEC  3A2800    		ld	a,(_csdreg)
1878    1CEF  E6C0      		and	192
1879    1CF1  C2E51D    		jp	nz,L1372
1880                    	;  737              {
1881                    	;  738              printf("CSD Version 1.0, Standard Capacity\n");
1882    1CF4  210916    		ld	hl,L5031
1883    1CF7  CD0000    		call	_printf
1884                    	;  739              n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
1885    1CFA  3A2D00    		ld	a,(_csdreg+5)
1886    1CFD  6F        		ld	l,a
1887    1CFE  97        		sub	a
1888    1CFF  67        		ld	h,a
1889    1D00  7D        		ld	a,l
1890    1D01  E60F      		and	15
1891    1D03  6F        		ld	l,a
1892    1D04  97        		sub	a
1893    1D05  67        		ld	h,a
1894    1D06  E5        		push	hl
1895    1D07  3A3200    		ld	a,(_csdreg+10)
1896    1D0A  6F        		ld	l,a
1897    1D0B  97        		sub	a
1898    1D0C  67        		ld	h,a
1899    1D0D  7D        		ld	a,l
1900    1D0E  E680      		and	128
1901    1D10  6F        		ld	l,a
1902    1D11  97        		sub	a
1903    1D12  67        		ld	h,a
1904    1D13  E5        		push	hl
1905    1D14  210700    		ld	hl,7
1906    1D17  E5        		push	hl
1907    1D18  CD0000    		call	c.irsh
1908    1D1B  E1        		pop	hl
1909    1D1C  E3        		ex	(sp),hl
1910    1D1D  C1        		pop	bc
1911    1D1E  09        		add	hl,bc
1912    1D1F  E5        		push	hl
1913    1D20  3A3100    		ld	a,(_csdreg+9)
1914    1D23  6F        		ld	l,a
1915    1D24  97        		sub	a
1916    1D25  67        		ld	h,a
1917    1D26  7D        		ld	a,l
1918    1D27  E603      		and	3
1919    1D29  6F        		ld	l,a
1920    1D2A  97        		sub	a
1921    1D2B  67        		ld	h,a
1922    1D2C  29        		add	hl,hl
1923    1D2D  E3        		ex	(sp),hl
1924    1D2E  C1        		pop	bc
1925    1D2F  09        		add	hl,bc
1926    1D30  23        		inc	hl
1927    1D31  23        		inc	hl
1928    1D32  DD75F8    		ld	(ix-8),l
1929    1D35  DD74F9    		ld	(ix-7),h
1930                    	;  740              csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
1931                    	;  741                      ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
1932    1D38  3A3000    		ld	a,(_csdreg+8)
1933    1D3B  4F        		ld	c,a
1934    1D3C  97        		sub	a
1935    1D3D  47        		ld	b,a
1936    1D3E  C5        		push	bc
1937    1D3F  210600    		ld	hl,6
1938    1D42  E5        		push	hl
1939    1D43  CD0000    		call	c.irsh
1940    1D46  E1        		pop	hl
1941    1D47  E5        		push	hl
1942    1D48  3A2F00    		ld	a,(_csdreg+7)
1943    1D4B  6F        		ld	l,a
1944    1D4C  97        		sub	a
1945    1D4D  67        		ld	h,a
1946    1D4E  29        		add	hl,hl
1947    1D4F  29        		add	hl,hl
1948    1D50  E3        		ex	(sp),hl
1949    1D51  C1        		pop	bc
1950    1D52  09        		add	hl,bc
1951    1D53  E5        		push	hl
1952    1D54  3A2E00    		ld	a,(_csdreg+6)
1953    1D57  6F        		ld	l,a
1954    1D58  97        		sub	a
1955    1D59  67        		ld	h,a
1956    1D5A  7D        		ld	a,l
1957    1D5B  E603      		and	3
1958    1D5D  6F        		ld	l,a
1959    1D5E  97        		sub	a
1960    1D5F  67        		ld	h,a
1961    1D60  E5        		push	hl
1962    1D61  210A00    		ld	hl,10
1963    1D64  E5        		push	hl
1964    1D65  CD0000    		call	c.ilsh
1965    1D68  E1        		pop	hl
1966    1D69  E3        		ex	(sp),hl
1967    1D6A  C1        		pop	bc
1968    1D6B  09        		add	hl,bc
1969    1D6C  23        		inc	hl
1970    1D6D  DD75F6    		ld	(ix-10),l
1971    1D70  DD74F7    		ld	(ix-9),h
1972                    	;  742              capacity = (unsigned long) csize << (n-10);
1973    1D73  DDE5      		push	ix
1974    1D75  C1        		pop	bc
1975    1D76  21EEFF    		ld	hl,65518
1976    1D79  09        		add	hl,bc
1977    1D7A  E5        		push	hl
1978    1D7B  DDE5      		push	ix
1979    1D7D  C1        		pop	bc
1980    1D7E  21F6FF    		ld	hl,65526
1981    1D81  09        		add	hl,bc
1982    1D82  4D        		ld	c,l
1983    1D83  44        		ld	b,h
1984    1D84  97        		sub	a
1985    1D85  320000    		ld	(c.r0),a
1986    1D88  320100    		ld	(c.r0+1),a
1987    1D8B  0A        		ld	a,(bc)
1988    1D8C  320200    		ld	(c.r0+2),a
1989    1D8F  03        		inc	bc
1990    1D90  0A        		ld	a,(bc)
1991    1D91  320300    		ld	(c.r0+3),a
1992    1D94  210000    		ld	hl,c.r0
1993    1D97  E5        		push	hl
1994    1D98  DD6EF8    		ld	l,(ix-8)
1995    1D9B  DD66F9    		ld	h,(ix-7)
1996    1D9E  01F6FF    		ld	bc,65526
1997    1DA1  09        		add	hl,bc
1998    1DA2  E5        		push	hl
1999    1DA3  CD0000    		call	c.llsh
2000    1DA6  CD0000    		call	c.mvl
2001    1DA9  F1        		pop	af
2002                    	;  743              printf(" Device capacity: %lu KByte, %lu MByte\n",
2003                    	;  744                     capacity, capacity >> 10);
2004    1DAA  DDE5      		push	ix
2005    1DAC  C1        		pop	bc
2006    1DAD  21EEFF    		ld	hl,65518
2007    1DB0  09        		add	hl,bc
2008    1DB1  CD0000    		call	c.0mvf
2009    1DB4  210000    		ld	hl,c.r0
2010    1DB7  E5        		push	hl
2011    1DB8  210A00    		ld	hl,10
2012    1DBB  E5        		push	hl
2013    1DBC  CD0000    		call	c.ulrsh
2014    1DBF  E1        		pop	hl
2015    1DC0  23        		inc	hl
2016    1DC1  23        		inc	hl
2017    1DC2  4E        		ld	c,(hl)
2018    1DC3  23        		inc	hl
2019    1DC4  46        		ld	b,(hl)
2020    1DC5  C5        		push	bc
2021    1DC6  2B        		dec	hl
2022    1DC7  2B        		dec	hl
2023    1DC8  2B        		dec	hl
2024    1DC9  4E        		ld	c,(hl)
2025    1DCA  23        		inc	hl
2026    1DCB  46        		ld	b,(hl)
2027    1DCC  C5        		push	bc
2028    1DCD  DD66F1    		ld	h,(ix-15)
2029    1DD0  DD6EF0    		ld	l,(ix-16)
2030    1DD3  E5        		push	hl
2031    1DD4  DD66EF    		ld	h,(ix-17)
2032    1DD7  DD6EEE    		ld	l,(ix-18)
2033    1DDA  E5        		push	hl
2034    1DDB  212D16    		ld	hl,L5131
2035    1DDE  CD0000    		call	_printf
2036    1DE1  F1        		pop	af
2037    1DE2  F1        		pop	af
2038    1DE3  F1        		pop	af
2039    1DE4  F1        		pop	af
2040                    	L1372:
2041                    	;  745              }
2042                    	;  746          if ((csdreg[0] & 0xc0) == 0x40)
2043    1DE5  3A2800    		ld	a,(_csdreg)
2044    1DE8  6F        		ld	l,a
2045    1DE9  97        		sub	a
2046    1DEA  67        		ld	h,a
2047    1DEB  7D        		ld	a,l
2048    1DEC  E6C0      		and	192
2049    1DEE  6F        		ld	l,a
2050    1DEF  97        		sub	a
2051    1DF0  67        		ld	h,a
2052    1DF1  7D        		ld	a,l
2053    1DF2  FE40      		cp	64
2054    1DF4  2003      		jr	nz,L67
2055    1DF6  7C        		ld	a,h
2056    1DF7  FE00      		cp	0
2057                    	L67:
2058    1DF9  C2E21E    		jp	nz,L1472
2059                    	;  747              {
2060                    	;  748              printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
2061    1DFC  215516    		ld	hl,L5231
2062    1DFF  CD0000    		call	_printf
2063                    	;  749              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2064                    	;  750                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2065    1E02  DDE5      		push	ix
2066    1E04  C1        		pop	bc
2067    1E05  21F2FF    		ld	hl,65522
2068    1E08  09        		add	hl,bc
2069    1E09  E5        		push	hl
2070    1E0A  97        		sub	a
2071    1E0B  320000    		ld	(c.r0),a
2072    1E0E  320100    		ld	(c.r0+1),a
2073    1E11  3A3000    		ld	a,(_csdreg+8)
2074    1E14  320200    		ld	(c.r0+2),a
2075    1E17  97        		sub	a
2076    1E18  320300    		ld	(c.r0+3),a
2077    1E1B  210000    		ld	hl,c.r0
2078    1E1E  E5        		push	hl
2079    1E1F  210800    		ld	hl,8
2080    1E22  E5        		push	hl
2081    1E23  CD0000    		call	c.llsh
2082    1E26  97        		sub	a
2083    1E27  320000    		ld	(c.r1),a
2084    1E2A  320100    		ld	(c.r1+1),a
2085    1E2D  3A3100    		ld	a,(_csdreg+9)
2086    1E30  320200    		ld	(c.r1+2),a
2087    1E33  97        		sub	a
2088    1E34  320300    		ld	(c.r1+3),a
2089    1E37  210000    		ld	hl,c.r1
2090    1E3A  E5        		push	hl
2091    1E3B  CD0000    		call	c.ladd
2092    1E3E  3A2F00    		ld	a,(_csdreg+7)
2093    1E41  6F        		ld	l,a
2094    1E42  97        		sub	a
2095    1E43  67        		ld	h,a
2096    1E44  7D        		ld	a,l
2097    1E45  E63F      		and	63
2098    1E47  6F        		ld	l,a
2099    1E48  97        		sub	a
2100    1E49  67        		ld	h,a
2101    1E4A  4D        		ld	c,l
2102    1E4B  44        		ld	b,h
2103    1E4C  78        		ld	a,b
2104    1E4D  87        		add	a,a
2105    1E4E  9F        		sbc	a,a
2106    1E4F  320000    		ld	(c.r1),a
2107    1E52  320100    		ld	(c.r1+1),a
2108    1E55  78        		ld	a,b
2109    1E56  320300    		ld	(c.r1+3),a
2110    1E59  79        		ld	a,c
2111    1E5A  320200    		ld	(c.r1+2),a
2112    1E5D  210000    		ld	hl,c.r1
2113    1E60  E5        		push	hl
2114    1E61  211000    		ld	hl,16
2115    1E64  E5        		push	hl
2116    1E65  CD0000    		call	c.llsh
2117    1E68  CD0000    		call	c.ladd
2118    1E6B  3E01      		ld	a,1
2119    1E6D  320200    		ld	(c.r1+2),a
2120    1E70  87        		add	a,a
2121    1E71  9F        		sbc	a,a
2122    1E72  320300    		ld	(c.r1+3),a
2123    1E75  320100    		ld	(c.r1+1),a
2124    1E78  320000    		ld	(c.r1),a
2125    1E7B  210000    		ld	hl,c.r1
2126    1E7E  E5        		push	hl
2127    1E7F  CD0000    		call	c.ladd
2128    1E82  CD0000    		call	c.mvl
2129    1E85  F1        		pop	af
2130                    	;  751              capacity = devsize << 9;
2131    1E86  DDE5      		push	ix
2132    1E88  C1        		pop	bc
2133    1E89  21EEFF    		ld	hl,65518
2134    1E8C  09        		add	hl,bc
2135    1E8D  E5        		push	hl
2136    1E8E  DDE5      		push	ix
2137    1E90  C1        		pop	bc
2138    1E91  21F2FF    		ld	hl,65522
2139    1E94  09        		add	hl,bc
2140    1E95  CD0000    		call	c.0mvf
2141    1E98  210000    		ld	hl,c.r0
2142    1E9B  E5        		push	hl
2143    1E9C  210900    		ld	hl,9
2144    1E9F  E5        		push	hl
2145    1EA0  CD0000    		call	c.llsh
2146    1EA3  CD0000    		call	c.mvl
2147    1EA6  F1        		pop	af
2148                    	;  752              printf(" Device capacity: %lu KByte, %lu MByte\n",
2149                    	;  753                     capacity, capacity >> 10);
2150    1EA7  DDE5      		push	ix
2151    1EA9  C1        		pop	bc
2152    1EAA  21EEFF    		ld	hl,65518
2153    1EAD  09        		add	hl,bc
2154    1EAE  CD0000    		call	c.0mvf
2155    1EB1  210000    		ld	hl,c.r0
2156    1EB4  E5        		push	hl
2157    1EB5  210A00    		ld	hl,10
2158    1EB8  E5        		push	hl
2159    1EB9  CD0000    		call	c.ulrsh
2160    1EBC  E1        		pop	hl
2161    1EBD  23        		inc	hl
2162    1EBE  23        		inc	hl
2163    1EBF  4E        		ld	c,(hl)
2164    1EC0  23        		inc	hl
2165    1EC1  46        		ld	b,(hl)
2166    1EC2  C5        		push	bc
2167    1EC3  2B        		dec	hl
2168    1EC4  2B        		dec	hl
2169    1EC5  2B        		dec	hl
2170    1EC6  4E        		ld	c,(hl)
2171    1EC7  23        		inc	hl
2172    1EC8  46        		ld	b,(hl)
2173    1EC9  C5        		push	bc
2174    1ECA  DD66F1    		ld	h,(ix-15)
2175    1ECD  DD6EF0    		ld	l,(ix-16)
2176    1ED0  E5        		push	hl
2177    1ED1  DD66EF    		ld	h,(ix-17)
2178    1ED4  DD6EEE    		ld	l,(ix-18)
2179    1ED7  E5        		push	hl
2180    1ED8  218B16    		ld	hl,L5331
2181    1EDB  CD0000    		call	_printf
2182    1EDE  F1        		pop	af
2183    1EDF  F1        		pop	af
2184    1EE0  F1        		pop	af
2185    1EE1  F1        		pop	af
2186                    	L1472:
2187                    	;  754              }
2188                    	;  755          if ((csdreg[0] & 0xc0) == 0x80)
2189    1EE2  3A2800    		ld	a,(_csdreg)
2190    1EE5  6F        		ld	l,a
2191    1EE6  97        		sub	a
2192    1EE7  67        		ld	h,a
2193    1EE8  7D        		ld	a,l
2194    1EE9  E6C0      		and	192
2195    1EEB  6F        		ld	l,a
2196    1EEC  97        		sub	a
2197    1EED  67        		ld	h,a
2198    1EEE  7D        		ld	a,l
2199    1EEF  FE80      		cp	128
2200    1EF1  2003      		jr	nz,L001
2201    1EF3  7C        		ld	a,h
2202    1EF4  FE00      		cp	0
2203                    	L001:
2204    1EF6  C2DF1F    		jp	nz,L1572
2205                    	;  756              {
2206                    	;  757              printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
2207    1EF9  21B316    		ld	hl,L5431
2208    1EFC  CD0000    		call	_printf
2209                    	;  758              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2210                    	;  759                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2211    1EFF  DDE5      		push	ix
2212    1F01  C1        		pop	bc
2213    1F02  21F2FF    		ld	hl,65522
2214    1F05  09        		add	hl,bc
2215    1F06  E5        		push	hl
2216    1F07  97        		sub	a
2217    1F08  320000    		ld	(c.r0),a
2218    1F0B  320100    		ld	(c.r0+1),a
2219    1F0E  3A3000    		ld	a,(_csdreg+8)
2220    1F11  320200    		ld	(c.r0+2),a
2221    1F14  97        		sub	a
2222    1F15  320300    		ld	(c.r0+3),a
2223    1F18  210000    		ld	hl,c.r0
2224    1F1B  E5        		push	hl
2225    1F1C  210800    		ld	hl,8
2226    1F1F  E5        		push	hl
2227    1F20  CD0000    		call	c.llsh
2228    1F23  97        		sub	a
2229    1F24  320000    		ld	(c.r1),a
2230    1F27  320100    		ld	(c.r1+1),a
2231    1F2A  3A3100    		ld	a,(_csdreg+9)
2232    1F2D  320200    		ld	(c.r1+2),a
2233    1F30  97        		sub	a
2234    1F31  320300    		ld	(c.r1+3),a
2235    1F34  210000    		ld	hl,c.r1
2236    1F37  E5        		push	hl
2237    1F38  CD0000    		call	c.ladd
2238    1F3B  3A2F00    		ld	a,(_csdreg+7)
2239    1F3E  6F        		ld	l,a
2240    1F3F  97        		sub	a
2241    1F40  67        		ld	h,a
2242    1F41  7D        		ld	a,l
2243    1F42  E63F      		and	63
2244    1F44  6F        		ld	l,a
2245    1F45  97        		sub	a
2246    1F46  67        		ld	h,a
2247    1F47  4D        		ld	c,l
2248    1F48  44        		ld	b,h
2249    1F49  78        		ld	a,b
2250    1F4A  87        		add	a,a
2251    1F4B  9F        		sbc	a,a
2252    1F4C  320000    		ld	(c.r1),a
2253    1F4F  320100    		ld	(c.r1+1),a
2254    1F52  78        		ld	a,b
2255    1F53  320300    		ld	(c.r1+3),a
2256    1F56  79        		ld	a,c
2257    1F57  320200    		ld	(c.r1+2),a
2258    1F5A  210000    		ld	hl,c.r1
2259    1F5D  E5        		push	hl
2260    1F5E  211000    		ld	hl,16
2261    1F61  E5        		push	hl
2262    1F62  CD0000    		call	c.llsh
2263    1F65  CD0000    		call	c.ladd
2264    1F68  3E01      		ld	a,1
2265    1F6A  320200    		ld	(c.r1+2),a
2266    1F6D  87        		add	a,a
2267    1F6E  9F        		sbc	a,a
2268    1F6F  320300    		ld	(c.r1+3),a
2269    1F72  320100    		ld	(c.r1+1),a
2270    1F75  320000    		ld	(c.r1),a
2271    1F78  210000    		ld	hl,c.r1
2272    1F7B  E5        		push	hl
2273    1F7C  CD0000    		call	c.ladd
2274    1F7F  CD0000    		call	c.mvl
2275    1F82  F1        		pop	af
2276                    	;  760              capacity = devsize << 9;
2277    1F83  DDE5      		push	ix
2278    1F85  C1        		pop	bc
2279    1F86  21EEFF    		ld	hl,65518
2280    1F89  09        		add	hl,bc
2281    1F8A  E5        		push	hl
2282    1F8B  DDE5      		push	ix
2283    1F8D  C1        		pop	bc
2284    1F8E  21F2FF    		ld	hl,65522
2285    1F91  09        		add	hl,bc
2286    1F92  CD0000    		call	c.0mvf
2287    1F95  210000    		ld	hl,c.r0
2288    1F98  E5        		push	hl
2289    1F99  210900    		ld	hl,9
2290    1F9C  E5        		push	hl
2291    1F9D  CD0000    		call	c.llsh
2292    1FA0  CD0000    		call	c.mvl
2293    1FA3  F1        		pop	af
2294                    	;  761              printf(" Device capacity: %lu KByte, %lu MByte\n",
2295                    	;  762                     capacity, capacity >> 10);
2296    1FA4  DDE5      		push	ix
2297    1FA6  C1        		pop	bc
2298    1FA7  21EEFF    		ld	hl,65518
2299    1FAA  09        		add	hl,bc
2300    1FAB  CD0000    		call	c.0mvf
2301    1FAE  210000    		ld	hl,c.r0
2302    1FB1  E5        		push	hl
2303    1FB2  210A00    		ld	hl,10
2304    1FB5  E5        		push	hl
2305    1FB6  CD0000    		call	c.ulrsh
2306    1FB9  E1        		pop	hl
2307    1FBA  23        		inc	hl
2308    1FBB  23        		inc	hl
2309    1FBC  4E        		ld	c,(hl)
2310    1FBD  23        		inc	hl
2311    1FBE  46        		ld	b,(hl)
2312    1FBF  C5        		push	bc
2313    1FC0  2B        		dec	hl
2314    1FC1  2B        		dec	hl
2315    1FC2  2B        		dec	hl
2316    1FC3  4E        		ld	c,(hl)
2317    1FC4  23        		inc	hl
2318    1FC5  46        		ld	b,(hl)
2319    1FC6  C5        		push	bc
2320    1FC7  DD66F1    		ld	h,(ix-15)
2321    1FCA  DD6EF0    		ld	l,(ix-16)
2322    1FCD  E5        		push	hl
2323    1FCE  DD66EF    		ld	h,(ix-17)
2324    1FD1  DD6EEE    		ld	l,(ix-18)
2325    1FD4  E5        		push	hl
2326    1FD5  21DB16    		ld	hl,L5531
2327    1FD8  CD0000    		call	_printf
2328    1FDB  F1        		pop	af
2329    1FDC  F1        		pop	af
2330    1FDD  F1        		pop	af
2331    1FDE  F1        		pop	af
2332                    	L1572:
2333                    	;  763              }
2334                    	;  764          printf("--------------------------------------\n");
2335    1FDF  210317    		ld	hl,L5631
2336    1FE2  CD0000    		call	_printf
2337                    	L1052:
2338                    	;  765  
2339                    	;  766          } /* sdtestflg */ /* SDTEST */
2340                    	;  767  
2341                    	;  768      }
2342    1FE5  C30000    		jp	c.rets0
2343                    	L5731:
2344    1FE8  53        		.byte	83
2345    1FE9  44        		.byte	68
2346    1FEA  20        		.byte	32
2347    1FEB  63        		.byte	99
2348    1FEC  61        		.byte	97
2349    1FED  72        		.byte	114
2350    1FEE  64        		.byte	100
2351    1FEF  20        		.byte	32
2352    1FF0  6E        		.byte	110
2353    1FF1  6F        		.byte	111
2354    1FF2  74        		.byte	116
2355    1FF3  20        		.byte	32
2356    1FF4  69        		.byte	105
2357    1FF5  6E        		.byte	110
2358    1FF6  69        		.byte	105
2359    1FF7  74        		.byte	116
2360    1FF8  69        		.byte	105
2361    1FF9  61        		.byte	97
2362    1FFA  6C        		.byte	108
2363    1FFB  69        		.byte	105
2364    1FFC  7A        		.byte	122
2365    1FFD  65        		.byte	101
2366    1FFE  64        		.byte	100
2367    1FFF  0A        		.byte	10
2368    2000  00        		.byte	0
2369                    	L5041:
2370    2001  0A        		.byte	10
2371    2002  43        		.byte	67
2372    2003  4D        		.byte	77
2373    2004  44        		.byte	68
2374    2005  31        		.byte	49
2375    2006  37        		.byte	55
2376    2007  3A        		.byte	58
2377    2008  20        		.byte	32
2378    2009  52        		.byte	82
2379    200A  45        		.byte	69
2380    200B  41        		.byte	65
2381    200C  44        		.byte	68
2382    200D  5F        		.byte	95
2383    200E  53        		.byte	83
2384    200F  49        		.byte	73
2385    2010  4E        		.byte	78
2386    2011  47        		.byte	71
2387    2012  4C        		.byte	76
2388    2013  45        		.byte	69
2389    2014  5F        		.byte	95
2390    2015  42        		.byte	66
2391    2016  4C        		.byte	76
2392    2017  4F        		.byte	79
2393    2018  43        		.byte	67
2394    2019  4B        		.byte	75
2395    201A  2C        		.byte	44
2396    201B  20        		.byte	32
2397    201C  63        		.byte	99
2398    201D  6F        		.byte	111
2399    201E  6D        		.byte	109
2400    201F  6D        		.byte	109
2401    2020  61        		.byte	97
2402    2021  6E        		.byte	110
2403    2022  64        		.byte	100
2404    2023  20        		.byte	32
2405    2024  5B        		.byte	91
2406    2025  25        		.byte	37
2407    2026  30        		.byte	48
2408    2027  32        		.byte	50
2409    2028  78        		.byte	120
2410    2029  20        		.byte	32
2411    202A  25        		.byte	37
2412    202B  30        		.byte	48
2413    202C  32        		.byte	50
2414    202D  78        		.byte	120
2415    202E  20        		.byte	32
2416    202F  25        		.byte	37
2417    2030  30        		.byte	48
2418    2031  32        		.byte	50
2419    2032  78        		.byte	120
2420    2033  20        		.byte	32
2421    2034  25        		.byte	37
2422    2035  30        		.byte	48
2423    2036  32        		.byte	50
2424    2037  78        		.byte	120
2425    2038  20        		.byte	32
2426    2039  25        		.byte	37
2427    203A  30        		.byte	48
2428    203B  32        		.byte	50
2429    203C  78        		.byte	120
2430    203D  5D        		.byte	93
2431    203E  0A        		.byte	10
2432    203F  00        		.byte	0
2433                    	L5141:
2434    2040  43        		.byte	67
2435    2041  4D        		.byte	77
2436    2042  44        		.byte	68
2437    2043  31        		.byte	49
2438    2044  37        		.byte	55
2439    2045  20        		.byte	32
2440    2046  52        		.byte	82
2441    2047  31        		.byte	49
2442    2048  20        		.byte	32
2443    2049  72        		.byte	114
2444    204A  65        		.byte	101
2445    204B  73        		.byte	115
2446    204C  70        		.byte	112
2447    204D  6F        		.byte	111
2448    204E  6E        		.byte	110
2449    204F  73        		.byte	115
2450    2050  65        		.byte	101
2451    2051  20        		.byte	32
2452    2052  5B        		.byte	91
2453    2053  25        		.byte	37
2454    2054  30        		.byte	48
2455    2055  32        		.byte	50
2456    2056  78        		.byte	120
2457    2057  5D        		.byte	93
2458    2058  0A        		.byte	10
2459    2059  00        		.byte	0
2460                    	L5241:
2461    205A  20        		.byte	32
2462    205B  20        		.byte	32
2463    205C  63        		.byte	99
2464    205D  6F        		.byte	111
2465    205E  75        		.byte	117
2466    205F  6C        		.byte	108
2467    2060  64        		.byte	100
2468    2061  20        		.byte	32
2469    2062  6E        		.byte	110
2470    2063  6F        		.byte	111
2471    2064  74        		.byte	116
2472    2065  20        		.byte	32
2473    2066  72        		.byte	114
2474    2067  65        		.byte	101
2475    2068  61        		.byte	97
2476    2069  64        		.byte	100
2477    206A  20        		.byte	32
2478    206B  62        		.byte	98
2479    206C  6C        		.byte	108
2480    206D  6F        		.byte	111
2481    206E  63        		.byte	99
2482    206F  6B        		.byte	107
2483    2070  0A        		.byte	10
2484    2071  00        		.byte	0
2485                    	L5341:
2486    2072  20        		.byte	32
2487    2073  20        		.byte	32
2488    2074  72        		.byte	114
2489    2075  65        		.byte	101
2490    2076  61        		.byte	97
2491    2077  64        		.byte	100
2492    2078  20        		.byte	32
2493    2079  65        		.byte	101
2494    207A  72        		.byte	114
2495    207B  72        		.byte	114
2496    207C  6F        		.byte	111
2497    207D  72        		.byte	114
2498    207E  3A        		.byte	58
2499    207F  20        		.byte	32
2500    2080  5B        		.byte	91
2501    2081  25        		.byte	37
2502    2082  30        		.byte	48
2503    2083  32        		.byte	50
2504    2084  78        		.byte	120
2505    2085  5D        		.byte	93
2506    2086  0A        		.byte	10
2507    2087  00        		.byte	0
2508                    	L5441:
2509    2088  20        		.byte	32
2510    2089  20        		.byte	32
2511    208A  6E        		.byte	110
2512    208B  6F        		.byte	111
2513    208C  20        		.byte	32
2514    208D  64        		.byte	100
2515    208E  61        		.byte	97
2516    208F  74        		.byte	116
2517    2090  61        		.byte	97
2518    2091  20        		.byte	32
2519    2092  66        		.byte	102
2520    2093  6F        		.byte	111
2521    2094  75        		.byte	117
2522    2095  6E        		.byte	110
2523    2096  64        		.byte	100
2524    2097  0A        		.byte	10
2525    2098  00        		.byte	0
2526                    	L5541:
2527    2099  20        		.byte	32
2528    209A  20        		.byte	32
2529    209B  72        		.byte	114
2530    209C  65        		.byte	101
2531    209D  61        		.byte	97
2532    209E  64        		.byte	100
2533    209F  20        		.byte	32
2534    20A0  64        		.byte	100
2535    20A1  61        		.byte	97
2536    20A2  74        		.byte	116
2537    20A3  61        		.byte	97
2538    20A4  20        		.byte	32
2539    20A5  62        		.byte	98
2540    20A6  6C        		.byte	108
2541    20A7  6F        		.byte	111
2542    20A8  63        		.byte	99
2543    20A9  6B        		.byte	107
2544    20AA  20        		.byte	32
2545    20AB  25        		.byte	37
2546    20AC  6C        		.byte	108
2547    20AD  64        		.byte	100
2548    20AE  3A        		.byte	58
2549    20AF  0A        		.byte	10
2550    20B0  00        		.byte	0
2551                    	L5641:
2552    20B1  20        		.byte	32
2553    20B2  20        		.byte	32
2554    20B3  43        		.byte	67
2555    20B4  52        		.byte	82
2556    20B5  43        		.byte	67
2557    20B6  31        		.byte	49
2558    20B7  36        		.byte	54
2559    20B8  20        		.byte	32
2560    20B9  65        		.byte	101
2561    20BA  72        		.byte	114
2562    20BB  72        		.byte	114
2563    20BC  6F        		.byte	111
2564    20BD  72        		.byte	114
2565    20BE  2C        		.byte	44
2566    20BF  20        		.byte	32
2567    20C0  72        		.byte	114
2568    20C1  65        		.byte	101
2569    20C2  63        		.byte	99
2570    20C3  69        		.byte	105
2571    20C4  65        		.byte	101
2572    20C5  76        		.byte	118
2573    20C6  65        		.byte	101
2574    20C7  64        		.byte	100
2575    20C8  3A        		.byte	58
2576    20C9  20        		.byte	32
2577    20CA  30        		.byte	48
2578    20CB  78        		.byte	120
2579    20CC  25        		.byte	37
2580    20CD  30        		.byte	48
2581    20CE  34        		.byte	52
2582    20CF  78        		.byte	120
2583    20D0  2C        		.byte	44
2584    20D1  20        		.byte	32
2585    20D2  63        		.byte	99
2586    20D3  61        		.byte	97
2587    20D4  6C        		.byte	108
2588    20D5  63        		.byte	99
2589    20D6  3A        		.byte	58
2590    20D7  20        		.byte	32
2591    20D8  30        		.byte	48
2592    20D9  78        		.byte	120
2593    20DA  25        		.byte	37
2594    20DB  30        		.byte	48
2595    20DC  34        		.byte	52
2596    20DD  68        		.byte	104
2597    20DE  69        		.byte	105
2598    20DF  0A        		.byte	10
2599    20E0  00        		.byte	0
2600                    	;  769  
2601                    	;  770  /* Read data block of 512 bytes to buffer
2602                    	;  771   * Returns YES if ok or NO if error
2603                    	;  772   */
2604                    	;  773  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
2605                    	;  774      {
2606                    	_sdread:
2607    20E1  CD0000    		call	c.savs
2608    20E4  21E0FF    		ld	hl,65504
2609    20E7  39        		add	hl,sp
2610    20E8  F9        		ld	sp,hl
2611                    	;  775      unsigned char *statptr;
2612                    	;  776      unsigned char rbyte;
2613                    	;  777      unsigned char cmdbuf[5];   /* buffer to build command in */
2614                    	;  778      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2615                    	;  779      int nbytes;
2616                    	;  780      int tries;
2617                    	;  781      unsigned long blktoread;
2618                    	;  782      unsigned int rxcrc16;
2619                    	;  783      unsigned int calcrc16;
2620                    	;  784  
2621                    	;  785      ledon();
2622    20E9  CD0000    		call	_ledon
2623                    	;  786      spiselect();
2624    20EC  CD0000    		call	_spiselect
2625                    	;  787  
2626                    	;  788      if (!sdinitok)
2627    20EF  2A0C00    		ld	hl,(_sdinitok)
2628    20F2  7C        		ld	a,h
2629    20F3  B5        		or	l
2630    20F4  2019      		jr	nz,L1672
2631                    	;  789          {
2632                    	;  790          if (sdtestflg)
2633    20F6  2A0000    		ld	hl,(_sdtestflg)
2634    20F9  7C        		ld	a,h
2635    20FA  B5        		or	l
2636    20FB  2806      		jr	z,L1772
2637                    	;  791              {
2638                    	;  792              printf("SD card not initialized\n");
2639    20FD  21E81F    		ld	hl,L5731
2640    2100  CD0000    		call	_printf
2641                    	L1772:
2642                    	;  793              } /* sdtestflg */
2643                    	;  794          spideselect();
2644    2103  CD0000    		call	_spideselect
2645                    	;  795          ledoff();
2646    2106  CD0000    		call	_ledoff
2647                    	;  796          return (NO);
2648    2109  010000    		ld	bc,0
2649    210C  C30000    		jp	c.rets
2650                    	L1672:
2651                    	;  797          }
2652                    	;  798  
2653                    	;  799      /* CMD17: READ_SINGLE_BLOCK */
2654                    	;  800      /* Insert block # into command */
2655                    	;  801      memcpy(cmdbuf, cmd17, 5);
2656    210F  210500    		ld	hl,5
2657    2112  E5        		push	hl
2658    2113  213500    		ld	hl,_cmd17
2659    2116  E5        		push	hl
2660    2117  DDE5      		push	ix
2661    2119  C1        		pop	bc
2662    211A  21F2FF    		ld	hl,65522
2663    211D  09        		add	hl,bc
2664    211E  CD0000    		call	_memcpy
2665    2121  F1        		pop	af
2666    2122  F1        		pop	af
2667                    	;  802      blktoread = blkmult * rdblkno;
2668    2123  DDE5      		push	ix
2669    2125  C1        		pop	bc
2670    2126  21E4FF    		ld	hl,65508
2671    2129  09        		add	hl,bc
2672    212A  E5        		push	hl
2673    212B  210600    		ld	hl,_blkmult
2674    212E  CD0000    		call	c.0mvf
2675    2131  210000    		ld	hl,c.r0
2676    2134  E5        		push	hl
2677    2135  DDE5      		push	ix
2678    2137  C1        		pop	bc
2679    2138  210600    		ld	hl,6
2680    213B  09        		add	hl,bc
2681    213C  E5        		push	hl
2682    213D  CD0000    		call	c.lmul
2683    2140  CD0000    		call	c.mvl
2684    2143  F1        		pop	af
2685                    	;  803      cmdbuf[4] = blktoread & 0xff;
2686    2144  DD6EE6    		ld	l,(ix-26)
2687    2147  7D        		ld	a,l
2688    2148  E6FF      		and	255
2689    214A  DD77F6    		ld	(ix-10),a
2690                    	;  804      blktoread = blktoread >> 8;
2691    214D  DDE5      		push	ix
2692    214F  C1        		pop	bc
2693    2150  21E4FF    		ld	hl,65508
2694    2153  09        		add	hl,bc
2695    2154  E5        		push	hl
2696    2155  210800    		ld	hl,8
2697    2158  E5        		push	hl
2698    2159  CD0000    		call	c.ulrsh
2699    215C  F1        		pop	af
2700                    	;  805      cmdbuf[3] = blktoread & 0xff;
2701    215D  DD6EE6    		ld	l,(ix-26)
2702    2160  7D        		ld	a,l
2703    2161  E6FF      		and	255
2704    2163  DD77F5    		ld	(ix-11),a
2705                    	;  806      blktoread = blktoread >> 8;
2706    2166  DDE5      		push	ix
2707    2168  C1        		pop	bc
2708    2169  21E4FF    		ld	hl,65508
2709    216C  09        		add	hl,bc
2710    216D  E5        		push	hl
2711    216E  210800    		ld	hl,8
2712    2171  E5        		push	hl
2713    2172  CD0000    		call	c.ulrsh
2714    2175  F1        		pop	af
2715                    	;  807      cmdbuf[2] = blktoread & 0xff;
2716    2176  DD6EE6    		ld	l,(ix-26)
2717    2179  7D        		ld	a,l
2718    217A  E6FF      		and	255
2719    217C  DD77F4    		ld	(ix-12),a
2720                    	;  808      blktoread = blktoread >> 8;
2721    217F  DDE5      		push	ix
2722    2181  C1        		pop	bc
2723    2182  21E4FF    		ld	hl,65508
2724    2185  09        		add	hl,bc
2725    2186  E5        		push	hl
2726    2187  210800    		ld	hl,8
2727    218A  E5        		push	hl
2728    218B  CD0000    		call	c.ulrsh
2729    218E  F1        		pop	af
2730                    	;  809      cmdbuf[1] = blktoread & 0xff;
2731    218F  DD6EE6    		ld	l,(ix-26)
2732    2192  7D        		ld	a,l
2733    2193  E6FF      		and	255
2734    2195  DD77F3    		ld	(ix-13),a
2735                    	;  810  
2736                    	;  811      if (sdtestflg)
2737    2198  2A0000    		ld	hl,(_sdtestflg)
2738    219B  7C        		ld	a,h
2739    219C  B5        		or	l
2740    219D  2829      		jr	z,L1003
2741                    	;  812          {
2742                    	;  813          printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2743                    	;  814                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2744    219F  DD4EF6    		ld	c,(ix-10)
2745    21A2  97        		sub	a
2746    21A3  47        		ld	b,a
2747    21A4  C5        		push	bc
2748    21A5  DD4EF5    		ld	c,(ix-11)
2749    21A8  97        		sub	a
2750    21A9  47        		ld	b,a
2751    21AA  C5        		push	bc
2752    21AB  DD4EF4    		ld	c,(ix-12)
2753    21AE  97        		sub	a
2754    21AF  47        		ld	b,a
2755    21B0  C5        		push	bc
2756    21B1  DD4EF3    		ld	c,(ix-13)
2757    21B4  97        		sub	a
2758    21B5  47        		ld	b,a
2759    21B6  C5        		push	bc
2760    21B7  DD4EF2    		ld	c,(ix-14)
2761    21BA  97        		sub	a
2762    21BB  47        		ld	b,a
2763    21BC  C5        		push	bc
2764    21BD  210120    		ld	hl,L5041
2765    21C0  CD0000    		call	_printf
2766    21C3  210A00    		ld	hl,10
2767    21C6  39        		add	hl,sp
2768    21C7  F9        		ld	sp,hl
2769                    	L1003:
2770                    	;  815          } /* sdtestflg */
2771                    	;  816      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2772    21C8  210100    		ld	hl,1
2773    21CB  E5        		push	hl
2774    21CC  DDE5      		push	ix
2775    21CE  C1        		pop	bc
2776    21CF  21EDFF    		ld	hl,65517
2777    21D2  09        		add	hl,bc
2778    21D3  E5        		push	hl
2779    21D4  DDE5      		push	ix
2780    21D6  C1        		pop	bc
2781    21D7  21F2FF    		ld	hl,65522
2782    21DA  09        		add	hl,bc
2783    21DB  CD7501    		call	_sdcommand
2784    21DE  F1        		pop	af
2785    21DF  F1        		pop	af
2786    21E0  DD71F8    		ld	(ix-8),c
2787    21E3  DD70F9    		ld	(ix-7),b
2788                    	;  817      if (sdtestflg)
2789    21E6  2A0000    		ld	hl,(_sdtestflg)
2790    21E9  7C        		ld	a,h
2791    21EA  B5        		or	l
2792    21EB  2811      		jr	z,L1103
2793                    	;  818          {
2794                    	;  819          printf("CMD17 R1 response [%02x]\n", statptr[0]);
2795    21ED  DD6EF8    		ld	l,(ix-8)
2796    21F0  DD66F9    		ld	h,(ix-7)
2797    21F3  4E        		ld	c,(hl)
2798    21F4  97        		sub	a
2799    21F5  47        		ld	b,a
2800    21F6  C5        		push	bc
2801    21F7  214020    		ld	hl,L5141
2802    21FA  CD0000    		call	_printf
2803    21FD  F1        		pop	af
2804                    	L1103:
2805                    	;  820          } /* sdtestflg */
2806                    	;  821      if (statptr[0])
2807    21FE  DD6EF8    		ld	l,(ix-8)
2808    2201  DD66F9    		ld	h,(ix-7)
2809    2204  7E        		ld	a,(hl)
2810    2205  B7        		or	a
2811    2206  2819      		jr	z,L1203
2812                    	;  822          {
2813                    	;  823          if (sdtestflg)
2814    2208  2A0000    		ld	hl,(_sdtestflg)
2815    220B  7C        		ld	a,h
2816    220C  B5        		or	l
2817    220D  2806      		jr	z,L1303
2818                    	;  824              {
2819                    	;  825              printf("  could not read block\n");
2820    220F  215A20    		ld	hl,L5241
2821    2212  CD0000    		call	_printf
2822                    	L1303:
2823                    	;  826              } /* sdtestflg */
2824                    	;  827          spideselect();
2825    2215  CD0000    		call	_spideselect
2826                    	;  828          ledoff();
2827    2218  CD0000    		call	_ledoff
2828                    	;  829          return (NO);
2829    221B  010000    		ld	bc,0
2830    221E  C30000    		jp	c.rets
2831                    	L1203:
2832                    	;  830          }
2833                    	;  831      /* looking for 0xfe that is the byte before data */
2834                    	;  832      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
2835    2221  DD36E850  		ld	(ix-24),80
2836    2225  DD36E900  		ld	(ix-23),0
2837                    	L1403:
2838    2229  97        		sub	a
2839    222A  DD96E8    		sub	(ix-24)
2840    222D  3E00      		ld	a,0
2841    222F  DD9EE9    		sbc	a,(ix-23)
2842    2232  F27E22    		jp	p,L1503
2843    2235  21FF00    		ld	hl,255
2844    2238  CD0000    		call	_spiio
2845    223B  DD71F7    		ld	(ix-9),c
2846    223E  DD7EF7    		ld	a,(ix-9)
2847    2241  FEFE      		cp	254
2848    2243  2839      		jr	z,L1503
2849                    	;  833          {
2850                    	;  834          if ((rbyte & 0xe0) == 0x00)
2851    2245  DD6EF7    		ld	l,(ix-9)
2852    2248  7D        		ld	a,l
2853    2249  E6E0      		and	224
2854    224B  2016      		jr	nz,L1603
2855                    	;  835              {
2856                    	;  836              /* If a read operation fails and the card cannot provide
2857                    	;  837                 the required data, it will send a data error token instead
2858                    	;  838               */
2859                    	;  839              if (sdtestflg)
2860    224D  2A0000    		ld	hl,(_sdtestflg)
2861    2250  7C        		ld	a,h
2862    2251  B5        		or	l
2863    2252  281E      		jr	z,L1113
2864                    	;  840                  {
2865                    	;  841                  printf("  read error: [%02x]\n", rbyte);
2866    2254  DD4EF7    		ld	c,(ix-9)
2867    2257  97        		sub	a
2868    2258  47        		ld	b,a
2869    2259  C5        		push	bc
2870    225A  217220    		ld	hl,L5341
2871    225D  CD0000    		call	_printf
2872    2260  F1        		pop	af
2873    2261  180F      		jr	L1113
2874                    	L1603:
2875    2263  DD6EE8    		ld	l,(ix-24)
2876    2266  DD66E9    		ld	h,(ix-23)
2877    2269  2B        		dec	hl
2878    226A  DD75E8    		ld	(ix-24),l
2879    226D  DD74E9    		ld	(ix-23),h
2880    2270  18B7      		jr	L1403
2881                    	L1113:
2882                    	;  842                  } /* sdtestflg */
2883                    	;  843              spideselect();
2884    2272  CD0000    		call	_spideselect
2885                    	;  844              ledoff();
2886    2275  CD0000    		call	_ledoff
2887                    	;  845              return (NO);
2888    2278  010000    		ld	bc,0
2889    227B  C30000    		jp	c.rets
2890                    	L1503:
2891                    	;  846              }
2892                    	;  847          }
2893                    	;  848      if (tries == 0) /* tried too many times */
2894    227E  DD7EE8    		ld	a,(ix-24)
2895    2281  DDB6E9    		or	(ix-23)
2896    2284  2019      		jr	nz,L1213
2897                    	;  849          {
2898                    	;  850          if (sdtestflg)
2899    2286  2A0000    		ld	hl,(_sdtestflg)
2900    2289  7C        		ld	a,h
2901    228A  B5        		or	l
2902    228B  2806      		jr	z,L1313
2903                    	;  851              {
2904                    	;  852              printf("  no data found\n");
2905    228D  218820    		ld	hl,L5441
2906    2290  CD0000    		call	_printf
2907                    	L1313:
2908                    	;  853              } /* sdtestflg */
2909                    	;  854          spideselect();
2910    2293  CD0000    		call	_spideselect
2911                    	;  855          ledoff();
2912    2296  CD0000    		call	_ledoff
2913                    	;  856          return (NO);
2914    2299  010000    		ld	bc,0
2915    229C  C30000    		jp	c.rets
2916                    	L1213:
2917                    	;  857          }
2918                    	;  858      else
2919                    	;  859          {
2920                    	;  860          calcrc16 = 0;
2921    229F  DD36E000  		ld	(ix-32),0
2922    22A3  DD36E100  		ld	(ix-31),0
2923                    	;  861          for (nbytes = 0; nbytes < 512; nbytes++)
2924    22A7  DD36EA00  		ld	(ix-22),0
2925    22AB  DD36EB00  		ld	(ix-21),0
2926                    	L1513:
2927    22AF  DD7EEA    		ld	a,(ix-22)
2928    22B2  D600      		sub	0
2929    22B4  DD7EEB    		ld	a,(ix-21)
2930    22B7  DE02      		sbc	a,2
2931    22B9  F2F622    		jp	p,L1613
2932                    	;  862              {
2933                    	;  863              rbyte = spiio(0xff);
2934    22BC  21FF00    		ld	hl,255
2935    22BF  CD0000    		call	_spiio
2936    22C2  DD71F7    		ld	(ix-9),c
2937                    	;  864              calcrc16 = CRC16_one(calcrc16, rbyte);
2938    22C5  DD6EF7    		ld	l,(ix-9)
2939    22C8  97        		sub	a
2940    22C9  67        		ld	h,a
2941    22CA  E5        		push	hl
2942    22CB  DD6EE0    		ld	l,(ix-32)
2943    22CE  DD66E1    		ld	h,(ix-31)
2944    22D1  CDC700    		call	_CRC16_one
2945    22D4  F1        		pop	af
2946    22D5  DD71E0    		ld	(ix-32),c
2947    22D8  DD70E1    		ld	(ix-31),b
2948                    	;  865              rdbuf[nbytes] = rbyte;
2949    22DB  DD6E04    		ld	l,(ix+4)
2950    22DE  DD6605    		ld	h,(ix+5)
2951    22E1  DD4EEA    		ld	c,(ix-22)
2952    22E4  DD46EB    		ld	b,(ix-21)
2953    22E7  09        		add	hl,bc
2954    22E8  DD7EF7    		ld	a,(ix-9)
2955    22EB  77        		ld	(hl),a
2956                    	;  866              }
2957    22EC  DD34EA    		inc	(ix-22)
2958    22EF  2003      		jr	nz,L401
2959    22F1  DD34EB    		inc	(ix-21)
2960                    	L401:
2961    22F4  18B9      		jr	L1513
2962                    	L1613:
2963                    	;  867          rxcrc16 = spiio(0xff) << 8;
2964    22F6  21FF00    		ld	hl,255
2965    22F9  CD0000    		call	_spiio
2966    22FC  69        		ld	l,c
2967    22FD  60        		ld	h,b
2968    22FE  29        		add	hl,hl
2969    22FF  29        		add	hl,hl
2970    2300  29        		add	hl,hl
2971    2301  29        		add	hl,hl
2972    2302  29        		add	hl,hl
2973    2303  29        		add	hl,hl
2974    2304  29        		add	hl,hl
2975    2305  29        		add	hl,hl
2976    2306  DD75E2    		ld	(ix-30),l
2977    2309  DD74E3    		ld	(ix-29),h
2978                    	;  868          rxcrc16 += spiio(0xff);
2979    230C  21FF00    		ld	hl,255
2980    230F  CD0000    		call	_spiio
2981    2312  DD6EE2    		ld	l,(ix-30)
2982    2315  DD66E3    		ld	h,(ix-29)
2983    2318  09        		add	hl,bc
2984    2319  DD75E2    		ld	(ix-30),l
2985    231C  DD74E3    		ld	(ix-29),h
2986                    	;  869  
2987                    	;  870          if (sdtestflg)
2988    231F  2A0000    		ld	hl,(_sdtestflg)
2989    2322  7C        		ld	a,h
2990    2323  B5        		or	l
2991    2324  2816      		jr	z,L1123
2992                    	;  871              {
2993                    	;  872              printf("  read data block %ld:\n", rdblkno);
2994    2326  DD6609    		ld	h,(ix+9)
2995    2329  DD6E08    		ld	l,(ix+8)
2996    232C  E5        		push	hl
2997    232D  DD6607    		ld	h,(ix+7)
2998    2330  DD6E06    		ld	l,(ix+6)
2999    2333  E5        		push	hl
3000    2334  219920    		ld	hl,L5541
3001    2337  CD0000    		call	_printf
3002    233A  F1        		pop	af
3003    233B  F1        		pop	af
3004                    	L1123:
3005                    	;  873              } /* sdtestflg */
3006                    	;  874          if (rxcrc16 != calcrc16)
3007    233C  DD7EE2    		ld	a,(ix-30)
3008    233F  DDBEE0    		cp	(ix-32)
3009    2342  2006      		jr	nz,L601
3010    2344  DD7EE3    		ld	a,(ix-29)
3011    2347  DDBEE1    		cp	(ix-31)
3012                    	L601:
3013    234A  2829      		jr	z,L1413
3014                    	;  875              {
3015                    	;  876              if (sdtestflg)
3016    234C  2A0000    		ld	hl,(_sdtestflg)
3017    234F  7C        		ld	a,h
3018    2350  B5        		or	l
3019    2351  2816      		jr	z,L1323
3020                    	;  877                  {
3021                    	;  878                  printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
3022                    	;  879                         rxcrc16, calcrc16);
3023    2353  DD6EE0    		ld	l,(ix-32)
3024    2356  DD66E1    		ld	h,(ix-31)
3025    2359  E5        		push	hl
3026    235A  DD6EE2    		ld	l,(ix-30)
3027    235D  DD66E3    		ld	h,(ix-29)
3028    2360  E5        		push	hl
3029    2361  21B120    		ld	hl,L5641
3030    2364  CD0000    		call	_printf
3031    2367  F1        		pop	af
3032    2368  F1        		pop	af
3033                    	L1323:
3034                    	;  880                  } /* sdtestflg */
3035                    	;  881              spideselect();
3036    2369  CD0000    		call	_spideselect
3037                    	;  882              ledoff();
3038    236C  CD0000    		call	_ledoff
3039                    	;  883              return (NO);
3040    236F  010000    		ld	bc,0
3041    2372  C30000    		jp	c.rets
3042                    	L1413:
3043                    	;  884              }
3044                    	;  885          }
3045                    	;  886      spideselect();
3046    2375  CD0000    		call	_spideselect
3047                    	;  887      ledoff();
3048    2378  CD0000    		call	_ledoff
3049                    	;  888      return (YES);
3050    237B  010100    		ld	bc,1
3051    237E  C30000    		jp	c.rets
3052                    	L5741:
3053    2381  53        		.byte	83
3054    2382  44        		.byte	68
3055    2383  20        		.byte	32
3056    2384  63        		.byte	99
3057    2385  61        		.byte	97
3058    2386  72        		.byte	114
3059    2387  64        		.byte	100
3060    2388  20        		.byte	32
3061    2389  6E        		.byte	110
3062    238A  6F        		.byte	111
3063    238B  74        		.byte	116
3064    238C  20        		.byte	32
3065    238D  69        		.byte	105
3066    238E  6E        		.byte	110
3067    238F  69        		.byte	105
3068    2390  74        		.byte	116
3069    2391  69        		.byte	105
3070    2392  61        		.byte	97
3071    2393  6C        		.byte	108
3072    2394  69        		.byte	105
3073    2395  7A        		.byte	122
3074    2396  65        		.byte	101
3075    2397  64        		.byte	100
3076    2398  0A        		.byte	10
3077    2399  00        		.byte	0
3078                    	L5051:
3079    239A  20        		.byte	32
3080    239B  20        		.byte	32
3081    239C  77        		.byte	119
3082    239D  72        		.byte	114
3083    239E  69        		.byte	105
3084    239F  74        		.byte	116
3085    23A0  65        		.byte	101
3086    23A1  20        		.byte	32
3087    23A2  64        		.byte	100
3088    23A3  61        		.byte	97
3089    23A4  74        		.byte	116
3090    23A5  61        		.byte	97
3091    23A6  20        		.byte	32
3092    23A7  62        		.byte	98
3093    23A8  6C        		.byte	108
3094    23A9  6F        		.byte	111
3095    23AA  63        		.byte	99
3096    23AB  6B        		.byte	107
3097    23AC  20        		.byte	32
3098    23AD  25        		.byte	37
3099    23AE  6C        		.byte	108
3100    23AF  64        		.byte	100
3101    23B0  3A        		.byte	58
3102    23B1  0A        		.byte	10
3103    23B2  00        		.byte	0
3104                    	L5151:
3105    23B3  0A        		.byte	10
3106    23B4  43        		.byte	67
3107    23B5  4D        		.byte	77
3108    23B6  44        		.byte	68
3109    23B7  32        		.byte	50
3110    23B8  34        		.byte	52
3111    23B9  3A        		.byte	58
3112    23BA  20        		.byte	32
3113    23BB  57        		.byte	87
3114    23BC  52        		.byte	82
3115    23BD  49        		.byte	73
3116    23BE  54        		.byte	84
3117    23BF  45        		.byte	69
3118    23C0  5F        		.byte	95
3119    23C1  53        		.byte	83
3120    23C2  49        		.byte	73
3121    23C3  4E        		.byte	78
3122    23C4  47        		.byte	71
3123    23C5  4C        		.byte	76
3124    23C6  45        		.byte	69
3125    23C7  5F        		.byte	95
3126    23C8  42        		.byte	66
3127    23C9  4C        		.byte	76
3128    23CA  4F        		.byte	79
3129    23CB  43        		.byte	67
3130    23CC  4B        		.byte	75
3131    23CD  2C        		.byte	44
3132    23CE  20        		.byte	32
3133    23CF  63        		.byte	99
3134    23D0  6F        		.byte	111
3135    23D1  6D        		.byte	109
3136    23D2  6D        		.byte	109
3137    23D3  61        		.byte	97
3138    23D4  6E        		.byte	110
3139    23D5  64        		.byte	100
3140    23D6  20        		.byte	32
3141    23D7  5B        		.byte	91
3142    23D8  25        		.byte	37
3143    23D9  30        		.byte	48
3144    23DA  32        		.byte	50
3145    23DB  78        		.byte	120
3146    23DC  20        		.byte	32
3147    23DD  25        		.byte	37
3148    23DE  30        		.byte	48
3149    23DF  32        		.byte	50
3150    23E0  78        		.byte	120
3151    23E1  20        		.byte	32
3152    23E2  25        		.byte	37
3153    23E3  30        		.byte	48
3154    23E4  32        		.byte	50
3155    23E5  78        		.byte	120
3156    23E6  20        		.byte	32
3157    23E7  25        		.byte	37
3158    23E8  30        		.byte	48
3159    23E9  32        		.byte	50
3160    23EA  78        		.byte	120
3161    23EB  20        		.byte	32
3162    23EC  25        		.byte	37
3163    23ED  30        		.byte	48
3164    23EE  32        		.byte	50
3165    23EF  78        		.byte	120
3166    23F0  5D        		.byte	93
3167    23F1  0A        		.byte	10
3168    23F2  00        		.byte	0
3169                    	L5251:
3170    23F3  43        		.byte	67
3171    23F4  4D        		.byte	77
3172    23F5  44        		.byte	68
3173    23F6  32        		.byte	50
3174    23F7  34        		.byte	52
3175    23F8  20        		.byte	32
3176    23F9  52        		.byte	82
3177    23FA  31        		.byte	49
3178    23FB  20        		.byte	32
3179    23FC  72        		.byte	114
3180    23FD  65        		.byte	101
3181    23FE  73        		.byte	115
3182    23FF  70        		.byte	112
3183    2400  6F        		.byte	111
3184    2401  6E        		.byte	110
3185    2402  73        		.byte	115
3186    2403  65        		.byte	101
3187    2404  20        		.byte	32
3188    2405  5B        		.byte	91
3189    2406  25        		.byte	37
3190    2407  30        		.byte	48
3191    2408  32        		.byte	50
3192    2409  78        		.byte	120
3193    240A  5D        		.byte	93
3194    240B  0A        		.byte	10
3195    240C  00        		.byte	0
3196                    	L5351:
3197    240D  20        		.byte	32
3198    240E  20        		.byte	32
3199    240F  63        		.byte	99
3200    2410  6F        		.byte	111
3201    2411  75        		.byte	117
3202    2412  6C        		.byte	108
3203    2413  64        		.byte	100
3204    2414  20        		.byte	32
3205    2415  6E        		.byte	110
3206    2416  6F        		.byte	111
3207    2417  74        		.byte	116
3208    2418  20        		.byte	32
3209    2419  77        		.byte	119
3210    241A  72        		.byte	114
3211    241B  69        		.byte	105
3212    241C  74        		.byte	116
3213    241D  65        		.byte	101
3214    241E  20        		.byte	32
3215    241F  62        		.byte	98
3216    2420  6C        		.byte	108
3217    2421  6F        		.byte	111
3218    2422  63        		.byte	99
3219    2423  6B        		.byte	107
3220    2424  0A        		.byte	10
3221    2425  00        		.byte	0
3222                    	L5451:
3223    2426  4E        		.byte	78
3224    2427  6F        		.byte	111
3225    2428  20        		.byte	32
3226    2429  64        		.byte	100
3227    242A  61        		.byte	97
3228    242B  74        		.byte	116
3229    242C  61        		.byte	97
3230    242D  20        		.byte	32
3231    242E  72        		.byte	114
3232    242F  65        		.byte	101
3233    2430  73        		.byte	115
3234    2431  70        		.byte	112
3235    2432  6F        		.byte	111
3236    2433  6E        		.byte	110
3237    2434  73        		.byte	115
3238    2435  65        		.byte	101
3239    2436  0A        		.byte	10
3240    2437  00        		.byte	0
3241                    	L5551:
3242    2438  44        		.byte	68
3243    2439  61        		.byte	97
3244    243A  74        		.byte	116
3245    243B  61        		.byte	97
3246    243C  20        		.byte	32
3247    243D  72        		.byte	114
3248    243E  65        		.byte	101
3249    243F  73        		.byte	115
3250    2440  70        		.byte	112
3251    2441  6F        		.byte	111
3252    2442  6E        		.byte	110
3253    2443  73        		.byte	115
3254    2444  65        		.byte	101
3255    2445  20        		.byte	32
3256    2446  5B        		.byte	91
3257    2447  25        		.byte	37
3258    2448  30        		.byte	48
3259    2449  32        		.byte	50
3260    244A  78        		.byte	120
3261    244B  5D        		.byte	93
3262    244C  00        		.byte	0
3263                    	L5651:
3264    244D  2C        		.byte	44
3265    244E  20        		.byte	32
3266    244F  64        		.byte	100
3267    2450  61        		.byte	97
3268    2451  74        		.byte	116
3269    2452  61        		.byte	97
3270    2453  20        		.byte	32
3271    2454  61        		.byte	97
3272    2455  63        		.byte	99
3273    2456  63        		.byte	99
3274    2457  65        		.byte	101
3275    2458  70        		.byte	112
3276    2459  74        		.byte	116
3277    245A  65        		.byte	101
3278    245B  64        		.byte	100
3279    245C  0A        		.byte	10
3280    245D  00        		.byte	0
3281                    	L5751:
3282    245E  53        		.byte	83
3283    245F  65        		.byte	101
3284    2460  6E        		.byte	110
3285    2461  74        		.byte	116
3286    2462  20        		.byte	32
3287    2463  39        		.byte	57
3288    2464  2A        		.byte	42
3289    2465  38        		.byte	56
3290    2466  20        		.byte	32
3291    2467  28        		.byte	40
3292    2468  37        		.byte	55
3293    2469  32        		.byte	50
3294    246A  29        		.byte	41
3295    246B  20        		.byte	32
3296    246C  63        		.byte	99
3297    246D  6C        		.byte	108
3298    246E  6F        		.byte	111
3299    246F  63        		.byte	99
3300    2470  6B        		.byte	107
3301    2471  20        		.byte	32
3302    2472  70        		.byte	112
3303    2473  75        		.byte	117
3304    2474  6C        		.byte	108
3305    2475  73        		.byte	115
3306    2476  65        		.byte	101
3307    2477  73        		.byte	115
3308    2478  2C        		.byte	44
3309    2479  20        		.byte	32
3310    247A  73        		.byte	115
3311    247B  65        		.byte	101
3312    247C  6C        		.byte	108
3313    247D  65        		.byte	101
3314    247E  63        		.byte	99
3315    247F  74        		.byte	116
3316    2480  20        		.byte	32
3317    2481  61        		.byte	97
3318    2482  63        		.byte	99
3319    2483  74        		.byte	116
3320    2484  69        		.byte	105
3321    2485  76        		.byte	118
3322    2486  65        		.byte	101
3323    2487  0A        		.byte	10
3324    2488  00        		.byte	0
3325                    	L5061:
3326    2489  2C        		.byte	44
3327    248A  20        		.byte	32
3328    248B  64        		.byte	100
3329    248C  61        		.byte	97
3330    248D  74        		.byte	116
3331    248E  61        		.byte	97
3332    248F  20        		.byte	32
3333    2490  6E        		.byte	110
3334    2491  6F        		.byte	111
3335    2492  74        		.byte	116
3336    2493  20        		.byte	32
3337    2494  61        		.byte	97
3338    2495  63        		.byte	99
3339    2496  63        		.byte	99
3340    2497  65        		.byte	101
3341    2498  70        		.byte	112
3342    2499  74        		.byte	116
3343    249A  65        		.byte	101
3344    249B  64        		.byte	100
3345    249C  0A        		.byte	10
3346    249D  00        		.byte	0
3347                    	;  889      }
3348                    	;  890  
3349                    	;  891  /* Write data block of 512 bytes from buffer
3350                    	;  892   * Returns YES if ok or NO if error
3351                    	;  893   */
3352                    	;  894  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
3353                    	;  895      {
3354                    	_sdwrite:
3355    249E  CD0000    		call	c.savs
3356    24A1  21E2FF    		ld	hl,65506
3357    24A4  39        		add	hl,sp
3358    24A5  F9        		ld	sp,hl
3359                    	;  896      unsigned char *statptr;
3360                    	;  897      unsigned char rbyte;
3361                    	;  898      unsigned char tbyte;
3362                    	;  899      unsigned char cmdbuf[5];   /* buffer to build command in */
3363                    	;  900      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3364                    	;  901      int nbytes;
3365                    	;  902      int tries;
3366                    	;  903      unsigned long blktowrite;
3367                    	;  904      unsigned int calcrc16;
3368                    	;  905  
3369                    	;  906      ledon();
3370    24A6  CD0000    		call	_ledon
3371                    	;  907      spiselect();
3372    24A9  CD0000    		call	_spiselect
3373                    	;  908  
3374                    	;  909      if (!sdinitok)
3375    24AC  2A0C00    		ld	hl,(_sdinitok)
3376    24AF  7C        		ld	a,h
3377    24B0  B5        		or	l
3378    24B1  2019      		jr	nz,L1423
3379                    	;  910          {
3380                    	;  911          if (sdtestflg)
3381    24B3  2A0000    		ld	hl,(_sdtestflg)
3382    24B6  7C        		ld	a,h
3383    24B7  B5        		or	l
3384    24B8  2806      		jr	z,L1523
3385                    	;  912              {
3386                    	;  913              printf("SD card not initialized\n");
3387    24BA  218123    		ld	hl,L5741
3388    24BD  CD0000    		call	_printf
3389                    	L1523:
3390                    	;  914              } /* sdtestflg */
3391                    	;  915          spideselect();
3392    24C0  CD0000    		call	_spideselect
3393                    	;  916          ledoff();
3394    24C3  CD0000    		call	_ledoff
3395                    	;  917          return (NO);
3396    24C6  010000    		ld	bc,0
3397    24C9  C30000    		jp	c.rets
3398                    	L1423:
3399                    	;  918          }
3400                    	;  919  
3401                    	;  920      if (sdtestflg)
3402    24CC  2A0000    		ld	hl,(_sdtestflg)
3403    24CF  7C        		ld	a,h
3404    24D0  B5        		or	l
3405    24D1  2816      		jr	z,L1623
3406                    	;  921          {
3407                    	;  922          printf("  write data block %ld:\n", wrblkno);
3408    24D3  DD6609    		ld	h,(ix+9)
3409    24D6  DD6E08    		ld	l,(ix+8)
3410    24D9  E5        		push	hl
3411    24DA  DD6607    		ld	h,(ix+7)
3412    24DD  DD6E06    		ld	l,(ix+6)
3413    24E0  E5        		push	hl
3414    24E1  219A23    		ld	hl,L5051
3415    24E4  CD0000    		call	_printf
3416    24E7  F1        		pop	af
3417    24E8  F1        		pop	af
3418                    	L1623:
3419                    	;  923          } /* sdtestflg */
3420                    	;  924      /* CMD24: WRITE_SINGLE_BLOCK */
3421                    	;  925      /* Insert block # into command */
3422                    	;  926      memcpy(cmdbuf, cmd24, 5);
3423    24E9  210500    		ld	hl,5
3424    24EC  E5        		push	hl
3425    24ED  213B00    		ld	hl,_cmd24
3426    24F0  E5        		push	hl
3427    24F1  DDE5      		push	ix
3428    24F3  C1        		pop	bc
3429    24F4  21F1FF    		ld	hl,65521
3430    24F7  09        		add	hl,bc
3431    24F8  CD0000    		call	_memcpy
3432    24FB  F1        		pop	af
3433    24FC  F1        		pop	af
3434                    	;  927      blktowrite = blkmult * wrblkno;
3435    24FD  DDE5      		push	ix
3436    24FF  C1        		pop	bc
3437    2500  21E4FF    		ld	hl,65508
3438    2503  09        		add	hl,bc
3439    2504  E5        		push	hl
3440    2505  210600    		ld	hl,_blkmult
3441    2508  CD0000    		call	c.0mvf
3442    250B  210000    		ld	hl,c.r0
3443    250E  E5        		push	hl
3444    250F  DDE5      		push	ix
3445    2511  C1        		pop	bc
3446    2512  210600    		ld	hl,6
3447    2515  09        		add	hl,bc
3448    2516  E5        		push	hl
3449    2517  CD0000    		call	c.lmul
3450    251A  CD0000    		call	c.mvl
3451    251D  F1        		pop	af
3452                    	;  928      cmdbuf[4] = blktowrite & 0xff;
3453    251E  DD6EE6    		ld	l,(ix-26)
3454    2521  7D        		ld	a,l
3455    2522  E6FF      		and	255
3456    2524  DD77F5    		ld	(ix-11),a
3457                    	;  929      blktowrite = blktowrite >> 8;
3458    2527  DDE5      		push	ix
3459    2529  C1        		pop	bc
3460    252A  21E4FF    		ld	hl,65508
3461    252D  09        		add	hl,bc
3462    252E  E5        		push	hl
3463    252F  210800    		ld	hl,8
3464    2532  E5        		push	hl
3465    2533  CD0000    		call	c.ulrsh
3466    2536  F1        		pop	af
3467                    	;  930      cmdbuf[3] = blktowrite & 0xff;
3468    2537  DD6EE6    		ld	l,(ix-26)
3469    253A  7D        		ld	a,l
3470    253B  E6FF      		and	255
3471    253D  DD77F4    		ld	(ix-12),a
3472                    	;  931      blktowrite = blktowrite >> 8;
3473    2540  DDE5      		push	ix
3474    2542  C1        		pop	bc
3475    2543  21E4FF    		ld	hl,65508
3476    2546  09        		add	hl,bc
3477    2547  E5        		push	hl
3478    2548  210800    		ld	hl,8
3479    254B  E5        		push	hl
3480    254C  CD0000    		call	c.ulrsh
3481    254F  F1        		pop	af
3482                    	;  932      cmdbuf[2] = blktowrite & 0xff;
3483    2550  DD6EE6    		ld	l,(ix-26)
3484    2553  7D        		ld	a,l
3485    2554  E6FF      		and	255
3486    2556  DD77F3    		ld	(ix-13),a
3487                    	;  933      blktowrite = blktowrite >> 8;
3488    2559  DDE5      		push	ix
3489    255B  C1        		pop	bc
3490    255C  21E4FF    		ld	hl,65508
3491    255F  09        		add	hl,bc
3492    2560  E5        		push	hl
3493    2561  210800    		ld	hl,8
3494    2564  E5        		push	hl
3495    2565  CD0000    		call	c.ulrsh
3496    2568  F1        		pop	af
3497                    	;  934      cmdbuf[1] = blktowrite & 0xff;
3498    2569  DD6EE6    		ld	l,(ix-26)
3499    256C  7D        		ld	a,l
3500    256D  E6FF      		and	255
3501    256F  DD77F2    		ld	(ix-14),a
3502                    	;  935  
3503                    	;  936      if (sdtestflg)
3504    2572  2A0000    		ld	hl,(_sdtestflg)
3505    2575  7C        		ld	a,h
3506    2576  B5        		or	l
3507    2577  2829      		jr	z,L1723
3508                    	;  937          {
3509                    	;  938          printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
3510                    	;  939                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
3511    2579  DD4EF5    		ld	c,(ix-11)
3512    257C  97        		sub	a
3513    257D  47        		ld	b,a
3514    257E  C5        		push	bc
3515    257F  DD4EF4    		ld	c,(ix-12)
3516    2582  97        		sub	a
3517    2583  47        		ld	b,a
3518    2584  C5        		push	bc
3519    2585  DD4EF3    		ld	c,(ix-13)
3520    2588  97        		sub	a
3521    2589  47        		ld	b,a
3522    258A  C5        		push	bc
3523    258B  DD4EF2    		ld	c,(ix-14)
3524    258E  97        		sub	a
3525    258F  47        		ld	b,a
3526    2590  C5        		push	bc
3527    2591  DD4EF1    		ld	c,(ix-15)
3528    2594  97        		sub	a
3529    2595  47        		ld	b,a
3530    2596  C5        		push	bc
3531    2597  21B323    		ld	hl,L5151
3532    259A  CD0000    		call	_printf
3533    259D  210A00    		ld	hl,10
3534    25A0  39        		add	hl,sp
3535    25A1  F9        		ld	sp,hl
3536                    	L1723:
3537                    	;  940          } /* sdtestflg */
3538                    	;  941      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3539    25A2  210100    		ld	hl,1
3540    25A5  E5        		push	hl
3541    25A6  DDE5      		push	ix
3542    25A8  C1        		pop	bc
3543    25A9  21ECFF    		ld	hl,65516
3544    25AC  09        		add	hl,bc
3545    25AD  E5        		push	hl
3546    25AE  DDE5      		push	ix
3547    25B0  C1        		pop	bc
3548    25B1  21F1FF    		ld	hl,65521
3549    25B4  09        		add	hl,bc
3550    25B5  CD7501    		call	_sdcommand
3551    25B8  F1        		pop	af
3552    25B9  F1        		pop	af
3553    25BA  DD71F8    		ld	(ix-8),c
3554    25BD  DD70F9    		ld	(ix-7),b
3555                    	;  942      if (sdtestflg)
3556    25C0  2A0000    		ld	hl,(_sdtestflg)
3557    25C3  7C        		ld	a,h
3558    25C4  B5        		or	l
3559    25C5  2811      		jr	z,L1033
3560                    	;  943          {
3561                    	;  944          printf("CMD24 R1 response [%02x]\n", statptr[0]);
3562    25C7  DD6EF8    		ld	l,(ix-8)
3563    25CA  DD66F9    		ld	h,(ix-7)
3564    25CD  4E        		ld	c,(hl)
3565    25CE  97        		sub	a
3566    25CF  47        		ld	b,a
3567    25D0  C5        		push	bc
3568    25D1  21F323    		ld	hl,L5251
3569    25D4  CD0000    		call	_printf
3570    25D7  F1        		pop	af
3571                    	L1033:
3572                    	;  945          } /* sdtestflg */
3573                    	;  946      if (statptr[0])
3574    25D8  DD6EF8    		ld	l,(ix-8)
3575    25DB  DD66F9    		ld	h,(ix-7)
3576    25DE  7E        		ld	a,(hl)
3577    25DF  B7        		or	a
3578    25E0  2819      		jr	z,L1133
3579                    	;  947          {
3580                    	;  948          if (sdtestflg)
3581    25E2  2A0000    		ld	hl,(_sdtestflg)
3582    25E5  7C        		ld	a,h
3583    25E6  B5        		or	l
3584    25E7  2806      		jr	z,L1233
3585                    	;  949              {
3586                    	;  950              printf("  could not write block\n");
3587    25E9  210D24    		ld	hl,L5351
3588    25EC  CD0000    		call	_printf
3589                    	L1233:
3590                    	;  951              } /* sdtestflg */
3591                    	;  952          spideselect();
3592    25EF  CD0000    		call	_spideselect
3593                    	;  953          ledoff();
3594    25F2  CD0000    		call	_ledoff
3595                    	;  954          return (NO);
3596    25F5  010000    		ld	bc,0
3597    25F8  C30000    		jp	c.rets
3598                    	L1133:
3599                    	;  955          }
3600                    	;  956      /* send 0xfe, the byte before data */
3601                    	;  957      spiio(0xfe);
3602    25FB  21FE00    		ld	hl,254
3603    25FE  CD0000    		call	_spiio
3604                    	;  958      /* initialize crc and send block */
3605                    	;  959      calcrc16 = 0;
3606    2601  DD36E200  		ld	(ix-30),0
3607    2605  DD36E300  		ld	(ix-29),0
3608                    	;  960      for (nbytes = 0; nbytes < 512; nbytes++)
3609    2609  DD36EA00  		ld	(ix-22),0
3610    260D  DD36EB00  		ld	(ix-21),0
3611                    	L1333:
3612    2611  DD7EEA    		ld	a,(ix-22)
3613    2614  D600      		sub	0
3614    2616  DD7EEB    		ld	a,(ix-21)
3615    2619  DE02      		sbc	a,2
3616    261B  F25726    		jp	p,L1433
3617                    	;  961          {
3618                    	;  962          tbyte = wrbuf[nbytes];
3619    261E  DD6E04    		ld	l,(ix+4)
3620    2621  DD6605    		ld	h,(ix+5)
3621    2624  DD4EEA    		ld	c,(ix-22)
3622    2627  DD46EB    		ld	b,(ix-21)
3623    262A  09        		add	hl,bc
3624    262B  7E        		ld	a,(hl)
3625    262C  DD77F6    		ld	(ix-10),a
3626                    	;  963          spiio(tbyte);
3627    262F  DD6EF6    		ld	l,(ix-10)
3628    2632  97        		sub	a
3629    2633  67        		ld	h,a
3630    2634  CD0000    		call	_spiio
3631                    	;  964          calcrc16 = CRC16_one(calcrc16, tbyte);
3632    2637  DD6EF6    		ld	l,(ix-10)
3633    263A  97        		sub	a
3634    263B  67        		ld	h,a
3635    263C  E5        		push	hl
3636    263D  DD6EE2    		ld	l,(ix-30)
3637    2640  DD66E3    		ld	h,(ix-29)
3638    2643  CDC700    		call	_CRC16_one
3639    2646  F1        		pop	af
3640    2647  DD71E2    		ld	(ix-30),c
3641    264A  DD70E3    		ld	(ix-29),b
3642                    	;  965          }
3643    264D  DD34EA    		inc	(ix-22)
3644    2650  2003      		jr	nz,L211
3645    2652  DD34EB    		inc	(ix-21)
3646                    	L211:
3647    2655  18BA      		jr	L1333
3648                    	L1433:
3649                    	;  966      spiio((calcrc16 >> 8) & 0xff);
3650    2657  DD6EE2    		ld	l,(ix-30)
3651    265A  DD66E3    		ld	h,(ix-29)
3652    265D  E5        		push	hl
3653    265E  210800    		ld	hl,8
3654    2661  E5        		push	hl
3655    2662  CD0000    		call	c.ursh
3656    2665  E1        		pop	hl
3657    2666  7D        		ld	a,l
3658    2667  E6FF      		and	255
3659    2669  6F        		ld	l,a
3660    266A  97        		sub	a
3661    266B  67        		ld	h,a
3662    266C  CD0000    		call	_spiio
3663                    	;  967      spiio(calcrc16 & 0xff);
3664    266F  DD6EE2    		ld	l,(ix-30)
3665    2672  DD66E3    		ld	h,(ix-29)
3666    2675  7D        		ld	a,l
3667    2676  E6FF      		and	255
3668    2678  6F        		ld	l,a
3669    2679  97        		sub	a
3670    267A  67        		ld	h,a
3671    267B  CD0000    		call	_spiio
3672                    	;  968  
3673                    	;  969      /* check data resposnse */
3674                    	;  970      for (tries = 20;
3675    267E  DD36E814  		ld	(ix-24),20
3676    2682  DD36E900  		ld	(ix-23),0
3677                    	L1733:
3678                    	;  971              0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
3679    2686  97        		sub	a
3680    2687  DD96E8    		sub	(ix-24)
3681    268A  3E00      		ld	a,0
3682    268C  DD9EE9    		sbc	a,(ix-23)
3683    268F  F2BF26    		jp	p,L1043
3684    2692  21FF00    		ld	hl,255
3685    2695  CD0000    		call	_spiio
3686    2698  DD71F7    		ld	(ix-9),c
3687    269B  DD6EF7    		ld	l,(ix-9)
3688    269E  97        		sub	a
3689    269F  67        		ld	h,a
3690    26A0  7D        		ld	a,l
3691    26A1  E611      		and	17
3692    26A3  6F        		ld	l,a
3693    26A4  97        		sub	a
3694    26A5  67        		ld	h,a
3695    26A6  7D        		ld	a,l
3696    26A7  FE01      		cp	1
3697    26A9  2003      		jr	nz,L411
3698    26AB  7C        		ld	a,h
3699    26AC  FE00      		cp	0
3700                    	L411:
3701    26AE  280F      		jr	z,L1043
3702                    	;  972              tries--)
3703                    	L1143:
3704    26B0  DD6EE8    		ld	l,(ix-24)
3705    26B3  DD66E9    		ld	h,(ix-23)
3706    26B6  2B        		dec	hl
3707    26B7  DD75E8    		ld	(ix-24),l
3708    26BA  DD74E9    		ld	(ix-23),h
3709    26BD  18C7      		jr	L1733
3710                    	L1043:
3711                    	;  973          ;
3712                    	;  974      if (tries == 0)
3713    26BF  DD7EE8    		ld	a,(ix-24)
3714    26C2  DDB6E9    		or	(ix-23)
3715    26C5  2019      		jr	nz,L1343
3716                    	;  975          {
3717                    	;  976          if (sdtestflg)
3718    26C7  2A0000    		ld	hl,(_sdtestflg)
3719    26CA  7C        		ld	a,h
3720    26CB  B5        		or	l
3721    26CC  2806      		jr	z,L1443
3722                    	;  977              {
3723                    	;  978              printf("No data response\n");
3724    26CE  212624    		ld	hl,L5451
3725    26D1  CD0000    		call	_printf
3726                    	L1443:
3727                    	;  979              } /* sdtestflg */
3728                    	;  980          spideselect();
3729    26D4  CD0000    		call	_spideselect
3730                    	;  981          ledoff();
3731    26D7  CD0000    		call	_ledoff
3732                    	;  982          return (NO);
3733    26DA  010000    		ld	bc,0
3734    26DD  C30000    		jp	c.rets
3735                    	L1343:
3736                    	;  983          }
3737                    	;  984      else
3738                    	;  985          {
3739                    	;  986          if (sdtestflg)
3740    26E0  2A0000    		ld	hl,(_sdtestflg)
3741    26E3  7C        		ld	a,h
3742    26E4  B5        		or	l
3743    26E5  2813      		jr	z,L1643
3744                    	;  987              {
3745                    	;  988              printf("Data response [%02x]", 0x1f & rbyte);
3746    26E7  DD6EF7    		ld	l,(ix-9)
3747    26EA  97        		sub	a
3748    26EB  67        		ld	h,a
3749    26EC  7D        		ld	a,l
3750    26ED  E61F      		and	31
3751    26EF  6F        		ld	l,a
3752    26F0  97        		sub	a
3753    26F1  67        		ld	h,a
3754    26F2  E5        		push	hl
3755    26F3  213824    		ld	hl,L5551
3756    26F6  CD0000    		call	_printf
3757    26F9  F1        		pop	af
3758                    	L1643:
3759                    	;  989              } /* sdtestflg */
3760                    	;  990          if ((0x1f & rbyte) == 0x05)
3761    26FA  DD6EF7    		ld	l,(ix-9)
3762    26FD  97        		sub	a
3763    26FE  67        		ld	h,a
3764    26FF  7D        		ld	a,l
3765    2700  E61F      		and	31
3766    2702  6F        		ld	l,a
3767    2703  97        		sub	a
3768    2704  67        		ld	h,a
3769    2705  7D        		ld	a,l
3770    2706  FE05      		cp	5
3771    2708  2003      		jr	nz,L611
3772    270A  7C        		ld	a,h
3773    270B  FE00      		cp	0
3774                    	L611:
3775    270D  C25F27    		jp	nz,L1743
3776                    	;  991              {
3777                    	;  992              if (sdtestflg)
3778    2710  2A0000    		ld	hl,(_sdtestflg)
3779    2713  7C        		ld	a,h
3780    2714  B5        		or	l
3781    2715  2806      		jr	z,L1053
3782                    	;  993                  {
3783                    	;  994                  printf(", data accepted\n");
3784    2717  214D24    		ld	hl,L5651
3785    271A  CD0000    		call	_printf
3786                    	L1053:
3787                    	;  995                  } /* sdtestflg */
3788                    	;  996              for (nbytes = 9; 0 < nbytes; nbytes--)
3789    271D  DD36EA09  		ld	(ix-22),9
3790    2721  DD36EB00  		ld	(ix-21),0
3791                    	L1153:
3792    2725  97        		sub	a
3793    2726  DD96EA    		sub	(ix-22)
3794    2729  3E00      		ld	a,0
3795    272B  DD9EEB    		sbc	a,(ix-21)
3796    272E  F24627    		jp	p,L1253
3797                    	;  997                  spiio(0xff);
3798    2731  21FF00    		ld	hl,255
3799    2734  CD0000    		call	_spiio
3800    2737  DD6EEA    		ld	l,(ix-22)
3801    273A  DD66EB    		ld	h,(ix-21)
3802    273D  2B        		dec	hl
3803    273E  DD75EA    		ld	(ix-22),l
3804    2741  DD74EB    		ld	(ix-21),h
3805    2744  18DF      		jr	L1153
3806                    	L1253:
3807                    	;  998              if (sdtestflg)
3808    2746  2A0000    		ld	hl,(_sdtestflg)
3809    2749  7C        		ld	a,h
3810    274A  B5        		or	l
3811    274B  2806      		jr	z,L1553
3812                    	;  999                  {
3813                    	; 1000                  printf("Sent 9*8 (72) clock pulses, select active\n");
3814    274D  215E24    		ld	hl,L5751
3815    2750  CD0000    		call	_printf
3816                    	L1553:
3817                    	; 1001                  } /* sdtestflg */
3818                    	; 1002              spideselect();
3819    2753  CD0000    		call	_spideselect
3820                    	; 1003              ledoff();
3821    2756  CD0000    		call	_ledoff
3822                    	; 1004              return (YES);
3823    2759  010100    		ld	bc,1
3824    275C  C30000    		jp	c.rets
3825                    	L1743:
3826                    	; 1005              }
3827                    	; 1006          else
3828                    	; 1007              {
3829                    	; 1008              if (sdtestflg)
3830    275F  2A0000    		ld	hl,(_sdtestflg)
3831    2762  7C        		ld	a,h
3832    2763  B5        		or	l
3833    2764  2806      		jr	z,L1753
3834                    	; 1009                  {
3835                    	; 1010                  printf(", data not accepted\n");
3836    2766  218924    		ld	hl,L5061
3837    2769  CD0000    		call	_printf
3838                    	L1753:
3839                    	; 1011                  } /* sdtestflg */
3840                    	; 1012              spideselect();
3841    276C  CD0000    		call	_spideselect
3842                    	; 1013              ledoff();
3843    276F  CD0000    		call	_ledoff
3844                    	; 1014              return (NO);
3845    2772  010000    		ld	bc,0
3846    2775  C30000    		jp	c.rets
3847                    	L5161:
3848    2778  2A        		.byte	42
3849    2779  0A        		.byte	10
3850    277A  00        		.byte	0
3851                    	L5261:
3852    277B  25        		.byte	37
3853    277C  30        		.byte	48
3854    277D  34        		.byte	52
3855    277E  78        		.byte	120
3856    277F  20        		.byte	32
3857    2780  00        		.byte	0
3858                    	L5361:
3859    2781  25        		.byte	37
3860    2782  30        		.byte	48
3861    2783  32        		.byte	50
3862    2784  78        		.byte	120
3863    2785  20        		.byte	32
3864    2786  00        		.byte	0
3865                    	L5461:
3866    2787  20        		.byte	32
3867    2788  7C        		.byte	124
3868    2789  00        		.byte	0
3869                    	L5561:
3870    278A  7C        		.byte	124
3871    278B  0A        		.byte	10
3872    278C  00        		.byte	0
3873                    	; 1015              }
3874                    	; 1016          }
3875                    	; 1017      }
3876                    	; 1018  
3877                    	; 1019  /* Print data in 512 byte buffer */
3878                    	; 1020  void sddatprt(unsigned char *prtbuf)
3879                    	; 1021      {
3880                    	_sddatprt:
3881    278D  CD0000    		call	c.savs
3882    2790  21EEFF    		ld	hl,65518
3883    2793  39        		add	hl,sp
3884    2794  F9        		ld	sp,hl
3885                    	; 1022      /* Variables used for "pretty-print" */
3886                    	; 1023      int allzero, dmpline, dotprted, lastallz, nbytes;
3887                    	; 1024      unsigned char *prtptr;
3888                    	; 1025  
3889                    	; 1026      prtptr = prtbuf;
3890    2795  DD7E04    		ld	a,(ix+4)
3891    2798  DD77EE    		ld	(ix-18),a
3892    279B  DD7E05    		ld	a,(ix+5)
3893    279E  DD77EF    		ld	(ix-17),a
3894                    	; 1027      dotprted = NO;
3895    27A1  DD36F400  		ld	(ix-12),0
3896    27A5  DD36F500  		ld	(ix-11),0
3897                    	; 1028      lastallz = NO;
3898    27A9  DD36F200  		ld	(ix-14),0
3899    27AD  DD36F300  		ld	(ix-13),0
3900                    	; 1029      for (dmpline = 0; dmpline < 32; dmpline++)
3901    27B1  DD36F600  		ld	(ix-10),0
3902    27B5  DD36F700  		ld	(ix-9),0
3903                    	L1063:
3904    27B9  DD7EF6    		ld	a,(ix-10)
3905    27BC  D620      		sub	32
3906    27BE  DD7EF7    		ld	a,(ix-9)
3907    27C1  DE00      		sbc	a,0
3908    27C3  F21A29    		jp	p,L1163
3909                    	; 1030          {
3910                    	; 1031          /* test if all 16 bytes are 0x00 */
3911                    	; 1032          allzero = YES;
3912    27C6  DD36F801  		ld	(ix-8),1
3913    27CA  DD36F900  		ld	(ix-7),0
3914                    	; 1033          for (nbytes = 0; nbytes < 16; nbytes++)
3915    27CE  DD36F000  		ld	(ix-16),0
3916    27D2  DD36F100  		ld	(ix-15),0
3917                    	L1463:
3918    27D6  DD7EF0    		ld	a,(ix-16)
3919    27D9  D610      		sub	16
3920    27DB  DD7EF1    		ld	a,(ix-15)
3921    27DE  DE00      		sbc	a,0
3922    27E0  F20628    		jp	p,L1563
3923                    	; 1034              {
3924                    	; 1035              if (prtptr[nbytes] != 0)
3925    27E3  DD6EEE    		ld	l,(ix-18)
3926    27E6  DD66EF    		ld	h,(ix-17)
3927    27E9  DD4EF0    		ld	c,(ix-16)
3928    27EC  DD46F1    		ld	b,(ix-15)
3929    27EF  09        		add	hl,bc
3930    27F0  7E        		ld	a,(hl)
3931    27F1  B7        		or	a
3932    27F2  2808      		jr	z,L1663
3933                    	; 1036                  allzero = NO;
3934    27F4  DD36F800  		ld	(ix-8),0
3935    27F8  DD36F900  		ld	(ix-7),0
3936                    	L1663:
3937    27FC  DD34F0    		inc	(ix-16)
3938    27FF  2003      		jr	nz,L421
3939    2801  DD34F1    		inc	(ix-15)
3940                    	L421:
3941    2804  18D0      		jr	L1463
3942                    	L1563:
3943                    	; 1037              }
3944                    	; 1038          if (lastallz && allzero)
3945    2806  DD7EF2    		ld	a,(ix-14)
3946    2809  DDB6F3    		or	(ix-13)
3947    280C  2822      		jr	z,L1173
3948    280E  DD7EF8    		ld	a,(ix-8)
3949    2811  DDB6F9    		or	(ix-7)
3950    2814  281A      		jr	z,L1173
3951                    	; 1039              {
3952                    	; 1040              if (!dotprted)
3953    2816  DD7EF4    		ld	a,(ix-12)
3954    2819  DDB6F5    		or	(ix-11)
3955    281C  C2EF28    		jp	nz,L1373
3956                    	; 1041                  {
3957                    	; 1042                  printf("*\n");
3958    281F  217827    		ld	hl,L5161
3959    2822  CD0000    		call	_printf
3960                    	; 1043                  dotprted = YES;
3961    2825  DD36F401  		ld	(ix-12),1
3962    2829  DD36F500  		ld	(ix-11),0
3963    282D  C3EF28    		jp	L1373
3964                    	L1173:
3965                    	; 1044                  }
3966                    	; 1045              }
3967                    	; 1046          else
3968                    	; 1047              {
3969                    	; 1048              dotprted = NO;
3970    2830  DD36F400  		ld	(ix-12),0
3971    2834  DD36F500  		ld	(ix-11),0
3972                    	; 1049              /* print offset */
3973                    	; 1050              printf("%04x ", dmpline * 16);
3974    2838  DD6EF6    		ld	l,(ix-10)
3975    283B  DD66F7    		ld	h,(ix-9)
3976    283E  E5        		push	hl
3977    283F  211000    		ld	hl,16
3978    2842  E5        		push	hl
3979    2843  CD0000    		call	c.imul
3980    2846  217B27    		ld	hl,L5261
3981    2849  CD0000    		call	_printf
3982    284C  F1        		pop	af
3983                    	; 1051              /* print 16 bytes in hex */
3984                    	; 1052              for (nbytes = 0; nbytes < 16; nbytes++)
3985    284D  DD36F000  		ld	(ix-16),0
3986    2851  DD36F100  		ld	(ix-15),0
3987                    	L1473:
3988    2855  DD7EF0    		ld	a,(ix-16)
3989    2858  D610      		sub	16
3990    285A  DD7EF1    		ld	a,(ix-15)
3991    285D  DE00      		sbc	a,0
3992    285F  F28428    		jp	p,L1573
3993                    	; 1053                  printf("%02x ", prtptr[nbytes]);
3994    2862  DD6EEE    		ld	l,(ix-18)
3995    2865  DD66EF    		ld	h,(ix-17)
3996    2868  DD4EF0    		ld	c,(ix-16)
3997    286B  DD46F1    		ld	b,(ix-15)
3998    286E  09        		add	hl,bc
3999    286F  4E        		ld	c,(hl)
4000    2870  97        		sub	a
4001    2871  47        		ld	b,a
4002    2872  C5        		push	bc
4003    2873  218127    		ld	hl,L5361
4004    2876  CD0000    		call	_printf
4005    2879  F1        		pop	af
4006    287A  DD34F0    		inc	(ix-16)
4007    287D  2003      		jr	nz,L621
4008    287F  DD34F1    		inc	(ix-15)
4009                    	L621:
4010    2882  18D1      		jr	L1473
4011                    	L1573:
4012                    	; 1054              /* print these bytes in ASCII if printable */
4013                    	; 1055              printf(" |");
4014    2884  218727    		ld	hl,L5461
4015    2887  CD0000    		call	_printf
4016                    	; 1056              for (nbytes = 0; nbytes < 16; nbytes++)
4017    288A  DD36F000  		ld	(ix-16),0
4018    288E  DD36F100  		ld	(ix-15),0
4019                    	L1004:
4020    2892  DD7EF0    		ld	a,(ix-16)
4021    2895  D610      		sub	16
4022    2897  DD7EF1    		ld	a,(ix-15)
4023    289A  DE00      		sbc	a,0
4024    289C  F2E928    		jp	p,L1104
4025                    	; 1057                  {
4026                    	; 1058                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
4027    289F  DD6EEE    		ld	l,(ix-18)
4028    28A2  DD66EF    		ld	h,(ix-17)
4029    28A5  DD4EF0    		ld	c,(ix-16)
4030    28A8  DD46F1    		ld	b,(ix-15)
4031    28AB  09        		add	hl,bc
4032    28AC  7E        		ld	a,(hl)
4033    28AD  FE20      		cp	32
4034    28AF  3827      		jr	c,L1404
4035    28B1  DD6EEE    		ld	l,(ix-18)
4036    28B4  DD66EF    		ld	h,(ix-17)
4037    28B7  DD4EF0    		ld	c,(ix-16)
4038    28BA  DD46F1    		ld	b,(ix-15)
4039    28BD  09        		add	hl,bc
4040    28BE  7E        		ld	a,(hl)
4041    28BF  FE7F      		cp	127
4042    28C1  3015      		jr	nc,L1404
4043                    	; 1059                      putchar(prtptr[nbytes]);
4044    28C3  DD6EEE    		ld	l,(ix-18)
4045    28C6  DD66EF    		ld	h,(ix-17)
4046    28C9  DD4EF0    		ld	c,(ix-16)
4047    28CC  DD46F1    		ld	b,(ix-15)
4048    28CF  09        		add	hl,bc
4049    28D0  6E        		ld	l,(hl)
4050    28D1  97        		sub	a
4051    28D2  67        		ld	h,a
4052    28D3  CD0000    		call	_putchar
4053                    	; 1060                  else
4054    28D6  1806      		jr	L1204
4055                    	L1404:
4056                    	; 1061                      putchar('.');
4057    28D8  212E00    		ld	hl,46
4058    28DB  CD0000    		call	_putchar
4059                    	L1204:
4060    28DE  DD34F0    		inc	(ix-16)
4061    28E1  2003      		jr	nz,L031
4062    28E3  DD34F1    		inc	(ix-15)
4063                    	L031:
4064    28E6  C39228    		jp	L1004
4065                    	L1104:
4066                    	; 1062                  }
4067                    	; 1063              printf("|\n");
4068    28E9  218A27    		ld	hl,L5561
4069    28EC  CD0000    		call	_printf
4070                    	L1373:
4071                    	; 1064              }
4072                    	; 1065          prtptr += 16;
4073    28EF  DD6EEE    		ld	l,(ix-18)
4074    28F2  DD66EF    		ld	h,(ix-17)
4075    28F5  7D        		ld	a,l
4076    28F6  C610      		add	a,16
4077    28F8  6F        		ld	l,a
4078    28F9  7C        		ld	a,h
4079    28FA  CE00      		adc	a,0
4080    28FC  67        		ld	h,a
4081    28FD  DD75EE    		ld	(ix-18),l
4082    2900  DD74EF    		ld	(ix-17),h
4083                    	; 1066          lastallz = allzero;
4084    2903  DD7EF8    		ld	a,(ix-8)
4085    2906  DD77F2    		ld	(ix-14),a
4086    2909  DD7EF9    		ld	a,(ix-7)
4087    290C  DD77F3    		ld	(ix-13),a
4088                    	; 1067          }
4089    290F  DD34F6    		inc	(ix-10)
4090    2912  2003      		jr	nz,L221
4091    2914  DD34F7    		inc	(ix-9)
4092                    	L221:
4093    2917  C3B927    		jp	L1063
4094                    	L1163:
4095                    	; 1068      }
   0    291A  C30000    		jp	c.rets
   1                    	L5661:
   2    291D  25        		.byte	37
   3    291E  30        		.byte	48
   4    291F  32        		.byte	50
   5    2920  78        		.byte	120
   6    2921  25        		.byte	37
   7    2922  30        		.byte	48
   8    2923  32        		.byte	50
   9    2924  78        		.byte	120
  10    2925  25        		.byte	37
  11    2926  30        		.byte	48
  12    2927  32        		.byte	50
  13    2928  78        		.byte	120
  14    2929  25        		.byte	37
  15    292A  30        		.byte	48
  16    292B  32        		.byte	50
  17    292C  78        		.byte	120
  18    292D  2D        		.byte	45
  19    292E  00        		.byte	0
  20                    	L5761:
  21    292F  25        		.byte	37
  22    2930  30        		.byte	48
  23    2931  32        		.byte	50
  24    2932  78        		.byte	120
  25    2933  25        		.byte	37
  26    2934  30        		.byte	48
  27    2935  32        		.byte	50
  28    2936  78        		.byte	120
  29    2937  2D        		.byte	45
  30    2938  00        		.byte	0
  31                    	L5071:
  32    2939  25        		.byte	37
  33    293A  30        		.byte	48
  34    293B  32        		.byte	50
  35    293C  78        		.byte	120
  36    293D  25        		.byte	37
  37    293E  30        		.byte	48
  38    293F  32        		.byte	50
  39    2940  78        		.byte	120
  40    2941  2D        		.byte	45
  41    2942  00        		.byte	0
  42                    	L5171:
  43    2943  25        		.byte	37
  44    2944  30        		.byte	48
  45    2945  32        		.byte	50
  46    2946  78        		.byte	120
  47    2947  25        		.byte	37
  48    2948  30        		.byte	48
  49    2949  32        		.byte	50
  50    294A  78        		.byte	120
  51    294B  2D        		.byte	45
  52    294C  00        		.byte	0
  53                    	L5271:
  54    294D  25        		.byte	37
  55    294E  30        		.byte	48
  56    294F  32        		.byte	50
  57    2950  78        		.byte	120
  58    2951  25        		.byte	37
  59    2952  30        		.byte	48
  60    2953  32        		.byte	50
  61    2954  78        		.byte	120
  62    2955  25        		.byte	37
  63    2956  30        		.byte	48
  64    2957  32        		.byte	50
  65    2958  78        		.byte	120
  66    2959  25        		.byte	37
  67    295A  30        		.byte	48
  68    295B  32        		.byte	50
  69    295C  78        		.byte	120
  70    295D  25        		.byte	37
  71    295E  30        		.byte	48
  72    295F  32        		.byte	50
  73    2960  78        		.byte	120
  74    2961  25        		.byte	37
  75    2962  30        		.byte	48
  76    2963  32        		.byte	50
  77    2964  78        		.byte	120
  78    2965  00        		.byte	0
  79                    	; 1069  
  80                    	; 1070  /* Print GUID (mixed endian format)
  81                    	; 1071   */
  82                    	; 1072  void prtguid(unsigned char *guidptr)
  83                    	; 1073      {
  84                    	_prtguid:
  85    2966  CD0000    		call	c.savs
  86    2969  F5        		push	af
  87    296A  F5        		push	af
  88    296B  F5        		push	af
  89    296C  F5        		push	af
  90                    	; 1074      int index;
  91                    	; 1075  
  92                    	; 1076      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
  93    296D  DD6E04    		ld	l,(ix+4)
  94    2970  DD6605    		ld	h,(ix+5)
  95    2973  4E        		ld	c,(hl)
  96    2974  97        		sub	a
  97    2975  47        		ld	b,a
  98    2976  C5        		push	bc
  99    2977  DD6E04    		ld	l,(ix+4)
 100    297A  DD6605    		ld	h,(ix+5)
 101    297D  23        		inc	hl
 102    297E  4E        		ld	c,(hl)
 103    297F  97        		sub	a
 104    2980  47        		ld	b,a
 105    2981  C5        		push	bc
 106    2982  DD6E04    		ld	l,(ix+4)
 107    2985  DD6605    		ld	h,(ix+5)
 108    2988  23        		inc	hl
 109    2989  23        		inc	hl
 110    298A  4E        		ld	c,(hl)
 111    298B  97        		sub	a
 112    298C  47        		ld	b,a
 113    298D  C5        		push	bc
 114    298E  DD6E04    		ld	l,(ix+4)
 115    2991  DD6605    		ld	h,(ix+5)
 116    2994  23        		inc	hl
 117    2995  23        		inc	hl
 118    2996  23        		inc	hl
 119    2997  4E        		ld	c,(hl)
 120    2998  97        		sub	a
 121    2999  47        		ld	b,a
 122    299A  C5        		push	bc
 123    299B  211D29    		ld	hl,L5661
 124    299E  CD0000    		call	_printf
 125    29A1  F1        		pop	af
 126    29A2  F1        		pop	af
 127    29A3  F1        		pop	af
 128    29A4  F1        		pop	af
 129                    	; 1077      printf("%02x%02x-", guidptr[5], guidptr[4]);
 130    29A5  DD6E04    		ld	l,(ix+4)
 131    29A8  DD6605    		ld	h,(ix+5)
 132    29AB  23        		inc	hl
 133    29AC  23        		inc	hl
 134    29AD  23        		inc	hl
 135    29AE  23        		inc	hl
 136    29AF  4E        		ld	c,(hl)
 137    29B0  97        		sub	a
 138    29B1  47        		ld	b,a
 139    29B2  C5        		push	bc
 140    29B3  DD6E04    		ld	l,(ix+4)
 141    29B6  DD6605    		ld	h,(ix+5)
 142    29B9  010500    		ld	bc,5
 143    29BC  09        		add	hl,bc
 144    29BD  4E        		ld	c,(hl)
 145    29BE  97        		sub	a
 146    29BF  47        		ld	b,a
 147    29C0  C5        		push	bc
 148    29C1  212F29    		ld	hl,L5761
 149    29C4  CD0000    		call	_printf
 150    29C7  F1        		pop	af
 151    29C8  F1        		pop	af
 152                    	; 1078      printf("%02x%02x-", guidptr[7], guidptr[6]);
 153    29C9  DD6E04    		ld	l,(ix+4)
 154    29CC  DD6605    		ld	h,(ix+5)
 155    29CF  010600    		ld	bc,6
 156    29D2  09        		add	hl,bc
 157    29D3  4E        		ld	c,(hl)
 158    29D4  97        		sub	a
 159    29D5  47        		ld	b,a
 160    29D6  C5        		push	bc
 161    29D7  DD6E04    		ld	l,(ix+4)
 162    29DA  DD6605    		ld	h,(ix+5)
 163    29DD  010700    		ld	bc,7
 164    29E0  09        		add	hl,bc
 165    29E1  4E        		ld	c,(hl)
 166    29E2  97        		sub	a
 167    29E3  47        		ld	b,a
 168    29E4  C5        		push	bc
 169    29E5  213929    		ld	hl,L5071
 170    29E8  CD0000    		call	_printf
 171    29EB  F1        		pop	af
 172    29EC  F1        		pop	af
 173                    	; 1079      printf("%02x%02x-", guidptr[8], guidptr[9]);
 174    29ED  DD6E04    		ld	l,(ix+4)
 175    29F0  DD6605    		ld	h,(ix+5)
 176    29F3  010900    		ld	bc,9
 177    29F6  09        		add	hl,bc
 178    29F7  4E        		ld	c,(hl)
 179    29F8  97        		sub	a
 180    29F9  47        		ld	b,a
 181    29FA  C5        		push	bc
 182    29FB  DD6E04    		ld	l,(ix+4)
 183    29FE  DD6605    		ld	h,(ix+5)
 184    2A01  010800    		ld	bc,8
 185    2A04  09        		add	hl,bc
 186    2A05  4E        		ld	c,(hl)
 187    2A06  97        		sub	a
 188    2A07  47        		ld	b,a
 189    2A08  C5        		push	bc
 190    2A09  214329    		ld	hl,L5171
 191    2A0C  CD0000    		call	_printf
 192    2A0F  F1        		pop	af
 193    2A10  F1        		pop	af
 194                    	; 1080      printf("%02x%02x%02x%02x%02x%02x",
 195                    	; 1081             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
 196    2A11  DD6E04    		ld	l,(ix+4)
 197    2A14  DD6605    		ld	h,(ix+5)
 198    2A17  010F00    		ld	bc,15
 199    2A1A  09        		add	hl,bc
 200    2A1B  4E        		ld	c,(hl)
 201    2A1C  97        		sub	a
 202    2A1D  47        		ld	b,a
 203    2A1E  C5        		push	bc
 204    2A1F  DD6E04    		ld	l,(ix+4)
 205    2A22  DD6605    		ld	h,(ix+5)
 206    2A25  010E00    		ld	bc,14
 207    2A28  09        		add	hl,bc
 208    2A29  4E        		ld	c,(hl)
 209    2A2A  97        		sub	a
 210    2A2B  47        		ld	b,a
 211    2A2C  C5        		push	bc
 212    2A2D  DD6E04    		ld	l,(ix+4)
 213    2A30  DD6605    		ld	h,(ix+5)
 214    2A33  010D00    		ld	bc,13
 215    2A36  09        		add	hl,bc
 216    2A37  4E        		ld	c,(hl)
 217    2A38  97        		sub	a
 218    2A39  47        		ld	b,a
 219    2A3A  C5        		push	bc
 220    2A3B  DD6E04    		ld	l,(ix+4)
 221    2A3E  DD6605    		ld	h,(ix+5)
 222    2A41  010C00    		ld	bc,12
 223    2A44  09        		add	hl,bc
 224    2A45  4E        		ld	c,(hl)
 225    2A46  97        		sub	a
 226    2A47  47        		ld	b,a
 227    2A48  C5        		push	bc
 228    2A49  DD6E04    		ld	l,(ix+4)
 229    2A4C  DD6605    		ld	h,(ix+5)
 230    2A4F  010B00    		ld	bc,11
 231    2A52  09        		add	hl,bc
 232    2A53  4E        		ld	c,(hl)
 233    2A54  97        		sub	a
 234    2A55  47        		ld	b,a
 235    2A56  C5        		push	bc
 236    2A57  DD6E04    		ld	l,(ix+4)
 237    2A5A  DD6605    		ld	h,(ix+5)
 238    2A5D  010A00    		ld	bc,10
 239    2A60  09        		add	hl,bc
 240    2A61  4E        		ld	c,(hl)
 241    2A62  97        		sub	a
 242    2A63  47        		ld	b,a
 243    2A64  C5        		push	bc
 244    2A65  214D29    		ld	hl,L5271
 245    2A68  CD0000    		call	_printf
 246    2A6B  210C00    		ld	hl,12
 247    2A6E  39        		add	hl,sp
 248    2A6F  F9        		ld	sp,hl
 249                    	; 1082      }
 250    2A70  C30000    		jp	c.rets
 251                    	L5371:
 252    2A73  43        		.byte	67
 253    2A74  61        		.byte	97
 254    2A75  6E        		.byte	110
 255    2A76  27        		.byte	39
 256    2A77  74        		.byte	116
 257    2A78  20        		.byte	32
 258    2A79  72        		.byte	114
 259    2A7A  65        		.byte	101
 260    2A7B  61        		.byte	97
 261    2A7C  64        		.byte	100
 262    2A7D  20        		.byte	32
 263    2A7E  47        		.byte	71
 264    2A7F  50        		.byte	80
 265    2A80  54        		.byte	84
 266    2A81  20        		.byte	32
 267    2A82  65        		.byte	101
 268    2A83  6E        		.byte	110
 269    2A84  74        		.byte	116
 270    2A85  72        		.byte	114
 271    2A86  79        		.byte	121
 272    2A87  20        		.byte	32
 273    2A88  62        		.byte	98
 274    2A89  6C        		.byte	108
 275    2A8A  6F        		.byte	111
 276    2A8B  63        		.byte	99
 277    2A8C  6B        		.byte	107
 278    2A8D  0A        		.byte	10
 279    2A8E  00        		.byte	0
 280                    	L5471:
 281    2A8F  47        		.byte	71
 282    2A90  50        		.byte	80
 283    2A91  54        		.byte	84
 284    2A92  20        		.byte	32
 285    2A93  70        		.byte	112
 286    2A94  61        		.byte	97
 287    2A95  72        		.byte	114
 288    2A96  74        		.byte	116
 289    2A97  69        		.byte	105
 290    2A98  74        		.byte	116
 291    2A99  69        		.byte	105
 292    2A9A  6F        		.byte	111
 293    2A9B  6E        		.byte	110
 294    2A9C  20        		.byte	32
 295    2A9D  65        		.byte	101
 296    2A9E  6E        		.byte	110
 297    2A9F  74        		.byte	116
 298    2AA0  72        		.byte	114
 299    2AA1  79        		.byte	121
 300    2AA2  20        		.byte	32
 301    2AA3  25        		.byte	37
 302    2AA4  64        		.byte	100
 303    2AA5  3A        		.byte	58
 304    2AA6  00        		.byte	0
 305                    	L5571:
 306    2AA7  20        		.byte	32
 307    2AA8  4E        		.byte	78
 308    2AA9  6F        		.byte	111
 309    2AAA  74        		.byte	116
 310    2AAB  20        		.byte	32
 311    2AAC  75        		.byte	117
 312    2AAD  73        		.byte	115
 313    2AAE  65        		.byte	101
 314    2AAF  64        		.byte	100
 315    2AB0  20        		.byte	32
 316    2AB1  65        		.byte	101
 317    2AB2  6E        		.byte	110
 318    2AB3  74        		.byte	116
 319    2AB4  72        		.byte	114
 320    2AB5  79        		.byte	121
 321    2AB6  0A        		.byte	10
 322    2AB7  00        		.byte	0
 323                    	L5671:
 324    2AB8  0A        		.byte	10
 325    2AB9  20        		.byte	32
 326    2ABA  20        		.byte	32
 327    2ABB  50        		.byte	80
 328    2ABC  61        		.byte	97
 329    2ABD  72        		.byte	114
 330    2ABE  74        		.byte	116
 331    2ABF  69        		.byte	105
 332    2AC0  74        		.byte	116
 333    2AC1  69        		.byte	105
 334    2AC2  6F        		.byte	111
 335    2AC3  6E        		.byte	110
 336    2AC4  20        		.byte	32
 337    2AC5  74        		.byte	116
 338    2AC6  79        		.byte	121
 339    2AC7  70        		.byte	112
 340    2AC8  65        		.byte	101
 341    2AC9  20        		.byte	32
 342    2ACA  47        		.byte	71
 343    2ACB  55        		.byte	85
 344    2ACC  49        		.byte	73
 345    2ACD  44        		.byte	68
 346    2ACE  3A        		.byte	58
 347    2ACF  20        		.byte	32
 348    2AD0  00        		.byte	0
 349                    	L5771:
 350    2AD1  0A        		.byte	10
 351    2AD2  20        		.byte	32
 352    2AD3  20        		.byte	32
 353    2AD4  5B        		.byte	91
 354    2AD5  00        		.byte	0
 355                    	L5002:
 356    2AD6  25        		.byte	37
 357    2AD7  30        		.byte	48
 358    2AD8  32        		.byte	50
 359    2AD9  78        		.byte	120
 360    2ADA  20        		.byte	32
 361    2ADB  00        		.byte	0
 362                    	L5102:
 363    2ADC  08        		.byte	8
 364    2ADD  5D        		.byte	93
 365    2ADE  00        		.byte	0
 366                    	L5202:
 367    2ADF  0A        		.byte	10
 368    2AE0  20        		.byte	32
 369    2AE1  20        		.byte	32
 370    2AE2  55        		.byte	85
 371    2AE3  6E        		.byte	110
 372    2AE4  69        		.byte	105
 373    2AE5  71        		.byte	113
 374    2AE6  75        		.byte	117
 375    2AE7  65        		.byte	101
 376    2AE8  20        		.byte	32
 377    2AE9  70        		.byte	112
 378    2AEA  61        		.byte	97
 379    2AEB  72        		.byte	114
 380    2AEC  74        		.byte	116
 381    2AED  69        		.byte	105
 382    2AEE  74        		.byte	116
 383    2AEF  69        		.byte	105
 384    2AF0  6F        		.byte	111
 385    2AF1  6E        		.byte	110
 386    2AF2  20        		.byte	32
 387    2AF3  47        		.byte	71
 388    2AF4  55        		.byte	85
 389    2AF5  49        		.byte	73
 390    2AF6  44        		.byte	68
 391    2AF7  3A        		.byte	58
 392    2AF8  20        		.byte	32
 393    2AF9  00        		.byte	0
 394                    	L5302:
 395    2AFA  0A        		.byte	10
 396    2AFB  20        		.byte	32
 397    2AFC  20        		.byte	32
 398    2AFD  5B        		.byte	91
 399    2AFE  00        		.byte	0
 400                    	L5402:
 401    2AFF  25        		.byte	37
 402    2B00  30        		.byte	48
 403    2B01  32        		.byte	50
 404    2B02  78        		.byte	120
 405    2B03  20        		.byte	32
 406    2B04  00        		.byte	0
 407                    	L5502:
 408    2B05  08        		.byte	8
 409    2B06  5D        		.byte	93
 410    2B07  00        		.byte	0
 411                    	L5602:
 412    2B08  0A        		.byte	10
 413    2B09  20        		.byte	32
 414    2B0A  20        		.byte	32
 415    2B0B  46        		.byte	70
 416    2B0C  69        		.byte	105
 417    2B0D  72        		.byte	114
 418    2B0E  73        		.byte	115
 419    2B0F  74        		.byte	116
 420    2B10  20        		.byte	32
 421    2B11  4C        		.byte	76
 422    2B12  42        		.byte	66
 423    2B13  41        		.byte	65
 424    2B14  3A        		.byte	58
 425    2B15  20        		.byte	32
 426    2B16  00        		.byte	0
 427                    	L5702:
 428    2B17  25        		.byte	37
 429    2B18  6C        		.byte	108
 430    2B19  75        		.byte	117
 431    2B1A  00        		.byte	0
 432                    	L5012:
 433    2B1B  20        		.byte	32
 434    2B1C  5B        		.byte	91
 435    2B1D  00        		.byte	0
 436                    	L5112:
 437    2B1E  25        		.byte	37
 438    2B1F  30        		.byte	48
 439    2B20  32        		.byte	50
 440    2B21  78        		.byte	120
 441    2B22  20        		.byte	32
 442    2B23  00        		.byte	0
 443                    	L5212:
 444    2B24  08        		.byte	8
 445    2B25  5D        		.byte	93
 446    2B26  00        		.byte	0
 447                    	L5312:
 448    2B27  0A        		.byte	10
 449    2B28  20        		.byte	32
 450    2B29  20        		.byte	32
 451    2B2A  4C        		.byte	76
 452    2B2B  61        		.byte	97
 453    2B2C  73        		.byte	115
 454    2B2D  74        		.byte	116
 455    2B2E  20        		.byte	32
 456    2B2F  4C        		.byte	76
 457    2B30  42        		.byte	66
 458    2B31  41        		.byte	65
 459    2B32  3A        		.byte	58
 460    2B33  20        		.byte	32
 461    2B34  00        		.byte	0
 462                    	L5412:
 463    2B35  25        		.byte	37
 464    2B36  6C        		.byte	108
 465    2B37  75        		.byte	117
 466    2B38  2C        		.byte	44
 467    2B39  20        		.byte	32
 468    2B3A  73        		.byte	115
 469    2B3B  69        		.byte	105
 470    2B3C  7A        		.byte	122
 471    2B3D  65        		.byte	101
 472    2B3E  20        		.byte	32
 473    2B3F  25        		.byte	37
 474    2B40  6C        		.byte	108
 475    2B41  75        		.byte	117
 476    2B42  20        		.byte	32
 477    2B43  4D        		.byte	77
 478    2B44  42        		.byte	66
 479    2B45  79        		.byte	121
 480    2B46  74        		.byte	116
 481    2B47  65        		.byte	101
 482    2B48  00        		.byte	0
 483                    	L5512:
 484    2B49  20        		.byte	32
 485    2B4A  5B        		.byte	91
 486    2B4B  00        		.byte	0
 487                    	L5612:
 488    2B4C  25        		.byte	37
 489    2B4D  30        		.byte	48
 490    2B4E  32        		.byte	50
 491    2B4F  78        		.byte	120
 492    2B50  20        		.byte	32
 493    2B51  00        		.byte	0
 494                    	L5712:
 495    2B52  08        		.byte	8
 496    2B53  5D        		.byte	93
 497    2B54  00        		.byte	0
 498                    	L5022:
 499    2B55  0A        		.byte	10
 500    2B56  20        		.byte	32
 501    2B57  20        		.byte	32
 502    2B58  41        		.byte	65
 503    2B59  74        		.byte	116
 504    2B5A  74        		.byte	116
 505    2B5B  72        		.byte	114
 506    2B5C  69        		.byte	105
 507    2B5D  62        		.byte	98
 508    2B5E  75        		.byte	117
 509    2B5F  74        		.byte	116
 510    2B60  65        		.byte	101
 511    2B61  20        		.byte	32
 512    2B62  66        		.byte	102
 513    2B63  6C        		.byte	108
 514    2B64  61        		.byte	97
 515    2B65  67        		.byte	103
 516    2B66  73        		.byte	115
 517    2B67  3A        		.byte	58
 518    2B68  20        		.byte	32
 519    2B69  5B        		.byte	91
 520    2B6A  00        		.byte	0
 521                    	L5122:
 522    2B6B  25        		.byte	37
 523    2B6C  30        		.byte	48
 524    2B6D  32        		.byte	50
 525    2B6E  78        		.byte	120
 526    2B6F  20        		.byte	32
 527    2B70  00        		.byte	0
 528                    	L5222:
 529    2B71  08        		.byte	8
 530    2B72  5D        		.byte	93
 531    2B73  0A        		.byte	10
 532    2B74  20        		.byte	32
 533    2B75  20        		.byte	32
 534    2B76  50        		.byte	80
 535    2B77  61        		.byte	97
 536    2B78  72        		.byte	114
 537    2B79  74        		.byte	116
 538    2B7A  69        		.byte	105
 539    2B7B  74        		.byte	116
 540    2B7C  69        		.byte	105
 541    2B7D  6F        		.byte	111
 542    2B7E  6E        		.byte	110
 543    2B7F  20        		.byte	32
 544    2B80  6E        		.byte	110
 545    2B81  61        		.byte	97
 546    2B82  6D        		.byte	109
 547    2B83  65        		.byte	101
 548    2B84  3A        		.byte	58
 549    2B85  20        		.byte	32
 550    2B86  20        		.byte	32
 551    2B87  00        		.byte	0
 552                    	L5322:
 553    2B88  6E        		.byte	110
 554    2B89  61        		.byte	97
 555    2B8A  6D        		.byte	109
 556    2B8B  65        		.byte	101
 557    2B8C  20        		.byte	32
 558    2B8D  66        		.byte	102
 559    2B8E  69        		.byte	105
 560    2B8F  65        		.byte	101
 561    2B90  6C        		.byte	108
 562    2B91  64        		.byte	100
 563    2B92  20        		.byte	32
 564    2B93  65        		.byte	101
 565    2B94  6D        		.byte	109
 566    2B95  70        		.byte	112
 567    2B96  74        		.byte	116
 568    2B97  79        		.byte	121
 569    2B98  00        		.byte	0
 570                    	L5422:
 571    2B99  0A        		.byte	10
 572    2B9A  00        		.byte	0
 573                    	L5522:
 574    2B9B  20        		.byte	32
 575    2B9C  20        		.byte	32
 576    2B9D  20        		.byte	32
 577    2B9E  5B        		.byte	91
 578    2B9F  00        		.byte	0
 579                    	L5622:
 580    2BA0  0A        		.byte	10
 581    2BA1  20        		.byte	32
 582    2BA2  20        		.byte	32
 583    2BA3  20        		.byte	32
 584    2BA4  20        		.byte	32
 585    2BA5  00        		.byte	0
 586                    	L5722:
 587    2BA6  25        		.byte	37
 588    2BA7  30        		.byte	48
 589    2BA8  32        		.byte	50
 590    2BA9  78        		.byte	120
 591    2BAA  20        		.byte	32
 592    2BAB  00        		.byte	0
 593                    	L5032:
 594    2BAC  08        		.byte	8
 595    2BAD  5D        		.byte	93
 596    2BAE  0A        		.byte	10
 597    2BAF  00        		.byte	0
 598                    	; 1083  
 599                    	; 1084  /* Analyze and print GPT entry
 600                    	; 1085   */
 601                    	; 1086  int prtgptent(unsigned int entryno)
 602                    	; 1087      {
 603                    	_prtgptent:
 604    2BB0  CD0000    		call	c.savs
 605    2BB3  21E4FF    		ld	hl,65508
 606    2BB6  39        		add	hl,sp
 607    2BB7  F9        		ld	sp,hl
 608                    	; 1088      int index;
 609                    	; 1089      int entryidx;
 610                    	; 1090      int hasname;
 611                    	; 1091      unsigned int block;
 612                    	; 1092      unsigned char *rxdata;
 613                    	; 1093      unsigned char *entryptr;
 614                    	; 1094      unsigned char tstzero = 0;
 615    2BB8  DD36ED00  		ld	(ix-19),0
 616                    	; 1095      unsigned long flba;
 617                    	; 1096      unsigned long llba;
 618                    	; 1097  
 619                    	; 1098      block = 2 + (entryno / 4);
 620    2BBC  DD6E04    		ld	l,(ix+4)
 621    2BBF  DD6605    		ld	h,(ix+5)
 622    2BC2  E5        		push	hl
 623    2BC3  210400    		ld	hl,4
 624    2BC6  E5        		push	hl
 625    2BC7  CD0000    		call	c.udiv
 626    2BCA  E1        		pop	hl
 627    2BCB  23        		inc	hl
 628    2BCC  23        		inc	hl
 629    2BCD  DD75F2    		ld	(ix-14),l
 630    2BD0  DD74F3    		ld	(ix-13),h
 631                    	; 1099      if ((curblkno != block) || !curblkok)
 632    2BD3  210200    		ld	hl,_curblkno
 633    2BD6  E5        		push	hl
 634    2BD7  DDE5      		push	ix
 635    2BD9  C1        		pop	bc
 636    2BDA  21F2FF    		ld	hl,65522
 637    2BDD  09        		add	hl,bc
 638    2BDE  4D        		ld	c,l
 639    2BDF  44        		ld	b,h
 640    2BE0  97        		sub	a
 641    2BE1  320000    		ld	(c.r0),a
 642    2BE4  320100    		ld	(c.r0+1),a
 643    2BE7  0A        		ld	a,(bc)
 644    2BE8  320200    		ld	(c.r0+2),a
 645    2BEB  03        		inc	bc
 646    2BEC  0A        		ld	a,(bc)
 647    2BED  320300    		ld	(c.r0+3),a
 648    2BF0  210000    		ld	hl,c.r0
 649    2BF3  E5        		push	hl
 650    2BF4  CD0000    		call	c.lcmp
 651    2BF7  2008      		jr	nz,L1704
 652    2BF9  2A1000    		ld	hl,(_curblkok)
 653    2BFC  7C        		ld	a,h
 654    2BFD  B5        		or	l
 655    2BFE  C25E2C    		jp	nz,L1604
 656                    	L1704:
 657                    	; 1100          {
 658                    	; 1101          if (!sdread(sdrdbuf, block))
 659    2C01  DDE5      		push	ix
 660    2C03  C1        		pop	bc
 661    2C04  21F2FF    		ld	hl,65522
 662    2C07  09        		add	hl,bc
 663    2C08  4D        		ld	c,l
 664    2C09  44        		ld	b,h
 665    2C0A  97        		sub	a
 666    2C0B  320000    		ld	(c.r0),a
 667    2C0E  320100    		ld	(c.r0+1),a
 668    2C11  0A        		ld	a,(bc)
 669    2C12  320200    		ld	(c.r0+2),a
 670    2C15  03        		inc	bc
 671    2C16  0A        		ld	a,(bc)
 672    2C17  320300    		ld	(c.r0+3),a
 673    2C1A  210300    		ld	hl,c.r0+3
 674    2C1D  46        		ld	b,(hl)
 675    2C1E  2B        		dec	hl
 676    2C1F  4E        		ld	c,(hl)
 677    2C20  C5        		push	bc
 678    2C21  2B        		dec	hl
 679    2C22  46        		ld	b,(hl)
 680    2C23  2B        		dec	hl
 681    2C24  4E        		ld	c,(hl)
 682    2C25  C5        		push	bc
 683    2C26  214C00    		ld	hl,_sdrdbuf
 684    2C29  CDE120    		call	_sdread
 685    2C2C  F1        		pop	af
 686    2C2D  F1        		pop	af
 687    2C2E  79        		ld	a,c
 688    2C2F  B0        		or	b
 689    2C30  2013      		jr	nz,L1014
 690                    	; 1102              {
 691                    	; 1103              if (sdtestflg)
 692    2C32  2A0000    		ld	hl,(_sdtestflg)
 693    2C35  7C        		ld	a,h
 694    2C36  B5        		or	l
 695    2C37  280C      		jr	z,L1014
 696                    	; 1104                  {
 697                    	; 1105                  printf("Can't read GPT entry block\n");
 698    2C39  21732A    		ld	hl,L5371
 699    2C3C  CD0000    		call	_printf
 700                    	; 1106                  return (NO);
 701    2C3F  010000    		ld	bc,0
 702    2C42  C30000    		jp	c.rets
 703                    	L1014:
 704                    	; 1107                  } /* sdtestflg */
 705                    	; 1108              }
 706                    	; 1109          curblkno = block;
 707    2C45  97        		sub	a
 708    2C46  320200    		ld	(_curblkno),a
 709    2C49  320300    		ld	(_curblkno+1),a
 710    2C4C  DD7EF2    		ld	a,(ix-14)
 711    2C4F  320400    		ld	(_curblkno+2),a
 712                    	; 1110          curblkok = YES;
 713    2C52  210100    		ld	hl,1
 714    2C55  DD7EF3    		ld	a,(ix-13)
 715    2C58  320500    		ld	(_curblkno+3),a
 716    2C5B  221000    		ld	(_curblkok),hl
 717                    	L1604:
 718                    	; 1111          }
 719                    	; 1112      rxdata = sdrdbuf;
 720    2C5E  214C00    		ld	hl,_sdrdbuf
 721    2C61  DD75F0    		ld	(ix-16),l
 722    2C64  DD74F1    		ld	(ix-15),h
 723                    	; 1113      entryptr = rxdata + (128 * (entryno % 4));
 724    2C67  DD6E04    		ld	l,(ix+4)
 725    2C6A  DD6605    		ld	h,(ix+5)
 726    2C6D  E5        		push	hl
 727    2C6E  210400    		ld	hl,4
 728    2C71  E5        		push	hl
 729    2C72  CD0000    		call	c.umod
 730    2C75  218000    		ld	hl,128
 731    2C78  E5        		push	hl
 732    2C79  CD0000    		call	c.imul
 733    2C7C  E1        		pop	hl
 734    2C7D  DD4EF0    		ld	c,(ix-16)
 735    2C80  DD46F1    		ld	b,(ix-15)
 736    2C83  09        		add	hl,bc
 737    2C84  DD75EE    		ld	(ix-18),l
 738    2C87  DD74EF    		ld	(ix-17),h
 739                    	; 1114      for (index = 0; index < 16; index++)
 740    2C8A  DD36F800  		ld	(ix-8),0
 741    2C8E  DD36F900  		ld	(ix-7),0
 742                    	L1214:
 743    2C92  DD7EF8    		ld	a,(ix-8)
 744    2C95  D610      		sub	16
 745    2C97  DD7EF9    		ld	a,(ix-7)
 746    2C9A  DE00      		sbc	a,0
 747    2C9C  F2BD2C    		jp	p,L1314
 748                    	; 1115          tstzero |= entryptr[index];
 749    2C9F  DD6EEE    		ld	l,(ix-18)
 750    2CA2  DD66EF    		ld	h,(ix-17)
 751    2CA5  DD4EF8    		ld	c,(ix-8)
 752    2CA8  DD46F9    		ld	b,(ix-7)
 753    2CAB  09        		add	hl,bc
 754    2CAC  DD7EED    		ld	a,(ix-19)
 755    2CAF  B6        		or	(hl)
 756    2CB0  DD77ED    		ld	(ix-19),a
 757    2CB3  DD34F8    		inc	(ix-8)
 758    2CB6  2003      		jr	nz,L631
 759    2CB8  DD34F9    		inc	(ix-7)
 760                    	L631:
 761    2CBB  18D5      		jr	L1214
 762                    	L1314:
 763                    	; 1116      if (sdtestflg)
 764    2CBD  2A0000    		ld	hl,(_sdtestflg)
 765    2CC0  7C        		ld	a,h
 766    2CC1  B5        		or	l
 767    2CC2  280F      		jr	z,L1614
 768                    	; 1117          {
 769                    	; 1118          printf("GPT partition entry %d:", entryno + 1);
 770    2CC4  DD6E04    		ld	l,(ix+4)
 771    2CC7  DD6605    		ld	h,(ix+5)
 772    2CCA  23        		inc	hl
 773    2CCB  E5        		push	hl
 774    2CCC  218F2A    		ld	hl,L5471
 775    2CCF  CD0000    		call	_printf
 776    2CD2  F1        		pop	af
 777                    	L1614:
 778                    	; 1119          } /* sdtestflg */
 779                    	; 1120      if (!tstzero)
 780    2CD3  DD7EED    		ld	a,(ix-19)
 781    2CD6  B7        		or	a
 782    2CD7  2013      		jr	nz,L1714
 783                    	; 1121          {
 784                    	; 1122          if (sdtestflg)
 785    2CD9  2A0000    		ld	hl,(_sdtestflg)
 786    2CDC  7C        		ld	a,h
 787    2CDD  B5        		or	l
 788    2CDE  2806      		jr	z,L1024
 789                    	; 1123              {
 790                    	; 1124              printf(" Not used entry\n");
 791    2CE0  21A72A    		ld	hl,L5571
 792    2CE3  CD0000    		call	_printf
 793                    	L1024:
 794                    	; 1125              } /* sdtestflg */
 795                    	; 1126          return (NO);
 796    2CE6  010000    		ld	bc,0
 797    2CE9  C30000    		jp	c.rets
 798                    	L1714:
 799                    	; 1127          }
 800                    	; 1128      if (sdtestflg)
 801    2CEC  2A0000    		ld	hl,(_sdtestflg)
 802    2CEF  7C        		ld	a,h
 803    2CF0  B5        		or	l
 804    2CF1  CAA62D    		jp	z,L1124
 805                    	; 1129          {
 806                    	; 1130          printf("\n  Partition type GUID: ");
 807    2CF4  21B82A    		ld	hl,L5671
 808    2CF7  CD0000    		call	_printf
 809                    	; 1131          prtguid(entryptr);
 810    2CFA  DD6EEE    		ld	l,(ix-18)
 811    2CFD  DD66EF    		ld	h,(ix-17)
 812    2D00  CD6629    		call	_prtguid
 813                    	; 1132          printf("\n  [");
 814    2D03  21D12A    		ld	hl,L5771
 815    2D06  CD0000    		call	_printf
 816                    	; 1133          for (index = 0; index < 16; index++)
 817    2D09  DD36F800  		ld	(ix-8),0
 818    2D0D  DD36F900  		ld	(ix-7),0
 819                    	L1224:
 820    2D11  DD7EF8    		ld	a,(ix-8)
 821    2D14  D610      		sub	16
 822    2D16  DD7EF9    		ld	a,(ix-7)
 823    2D19  DE00      		sbc	a,0
 824    2D1B  F2402D    		jp	p,L1324
 825                    	; 1134              printf("%02x ", entryptr[index]);
 826    2D1E  DD6EEE    		ld	l,(ix-18)
 827    2D21  DD66EF    		ld	h,(ix-17)
 828    2D24  DD4EF8    		ld	c,(ix-8)
 829    2D27  DD46F9    		ld	b,(ix-7)
 830    2D2A  09        		add	hl,bc
 831    2D2B  4E        		ld	c,(hl)
 832    2D2C  97        		sub	a
 833    2D2D  47        		ld	b,a
 834    2D2E  C5        		push	bc
 835    2D2F  21D62A    		ld	hl,L5002
 836    2D32  CD0000    		call	_printf
 837    2D35  F1        		pop	af
 838    2D36  DD34F8    		inc	(ix-8)
 839    2D39  2003      		jr	nz,L041
 840    2D3B  DD34F9    		inc	(ix-7)
 841                    	L041:
 842    2D3E  18D1      		jr	L1224
 843                    	L1324:
 844                    	; 1135          printf("\b]");
 845    2D40  21DC2A    		ld	hl,L5102
 846    2D43  CD0000    		call	_printf
 847                    	; 1136          printf("\n  Unique partition GUID: ");
 848    2D46  21DF2A    		ld	hl,L5202
 849    2D49  CD0000    		call	_printf
 850                    	; 1137          prtguid(entryptr + 16);
 851    2D4C  DD6EEE    		ld	l,(ix-18)
 852    2D4F  DD66EF    		ld	h,(ix-17)
 853    2D52  011000    		ld	bc,16
 854    2D55  09        		add	hl,bc
 855    2D56  CD6629    		call	_prtguid
 856                    	; 1138          printf("\n  [");
 857    2D59  21FA2A    		ld	hl,L5302
 858    2D5C  CD0000    		call	_printf
 859                    	; 1139          for (index = 0; index < 16; index++)
 860    2D5F  DD36F800  		ld	(ix-8),0
 861    2D63  DD36F900  		ld	(ix-7),0
 862                    	L1624:
 863    2D67  DD7EF8    		ld	a,(ix-8)
 864    2D6A  D610      		sub	16
 865    2D6C  DD7EF9    		ld	a,(ix-7)
 866    2D6F  DE00      		sbc	a,0
 867    2D71  F29A2D    		jp	p,L1724
 868                    	; 1140              printf("%02x ", (entryptr + 16)[index]);
 869    2D74  DD6EEE    		ld	l,(ix-18)
 870    2D77  DD66EF    		ld	h,(ix-17)
 871    2D7A  011000    		ld	bc,16
 872    2D7D  09        		add	hl,bc
 873    2D7E  DD4EF8    		ld	c,(ix-8)
 874    2D81  DD46F9    		ld	b,(ix-7)
 875    2D84  09        		add	hl,bc
 876    2D85  4E        		ld	c,(hl)
 877    2D86  97        		sub	a
 878    2D87  47        		ld	b,a
 879    2D88  C5        		push	bc
 880    2D89  21FF2A    		ld	hl,L5402
 881    2D8C  CD0000    		call	_printf
 882    2D8F  F1        		pop	af
 883    2D90  DD34F8    		inc	(ix-8)
 884    2D93  2003      		jr	nz,L241
 885    2D95  DD34F9    		inc	(ix-7)
 886                    	L241:
 887    2D98  18CD      		jr	L1624
 888                    	L1724:
 889                    	; 1141          printf("\b]");
 890    2D9A  21052B    		ld	hl,L5502
 891    2D9D  CD0000    		call	_printf
 892                    	; 1142          printf("\n  First LBA: ");
 893    2DA0  21082B    		ld	hl,L5602
 894    2DA3  CD0000    		call	_printf
 895                    	L1124:
 896                    	; 1143          /* lower 32 bits of LBA should be sufficient (I hope) */
 897                    	; 1144          } /* sdtestflg */
 898                    	; 1145      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
 899                    	; 1146             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
 900    2DA6  DDE5      		push	ix
 901    2DA8  C1        		pop	bc
 902    2DA9  21E8FF    		ld	hl,65512
 903    2DAC  09        		add	hl,bc
 904    2DAD  E5        		push	hl
 905    2DAE  DD6EEE    		ld	l,(ix-18)
 906    2DB1  DD66EF    		ld	h,(ix-17)
 907    2DB4  012000    		ld	bc,32
 908    2DB7  09        		add	hl,bc
 909    2DB8  4D        		ld	c,l
 910    2DB9  44        		ld	b,h
 911    2DBA  97        		sub	a
 912    2DBB  320000    		ld	(c.r0),a
 913    2DBE  320100    		ld	(c.r0+1),a
 914    2DC1  0A        		ld	a,(bc)
 915    2DC2  320200    		ld	(c.r0+2),a
 916    2DC5  97        		sub	a
 917    2DC6  320300    		ld	(c.r0+3),a
 918    2DC9  210000    		ld	hl,c.r0
 919    2DCC  E5        		push	hl
 920    2DCD  DD6EEE    		ld	l,(ix-18)
 921    2DD0  DD66EF    		ld	h,(ix-17)
 922    2DD3  012100    		ld	bc,33
 923    2DD6  09        		add	hl,bc
 924    2DD7  4D        		ld	c,l
 925    2DD8  44        		ld	b,h
 926    2DD9  97        		sub	a
 927    2DDA  320000    		ld	(c.r1),a
 928    2DDD  320100    		ld	(c.r1+1),a
 929    2DE0  0A        		ld	a,(bc)
 930    2DE1  320200    		ld	(c.r1+2),a
 931    2DE4  97        		sub	a
 932    2DE5  320300    		ld	(c.r1+3),a
 933    2DE8  210000    		ld	hl,c.r1
 934    2DEB  E5        		push	hl
 935    2DEC  210800    		ld	hl,8
 936    2DEF  E5        		push	hl
 937    2DF0  CD0000    		call	c.llsh
 938    2DF3  CD0000    		call	c.ladd
 939    2DF6  DD6EEE    		ld	l,(ix-18)
 940    2DF9  DD66EF    		ld	h,(ix-17)
 941    2DFC  012200    		ld	bc,34
 942    2DFF  09        		add	hl,bc
 943    2E00  4D        		ld	c,l
 944    2E01  44        		ld	b,h
 945    2E02  97        		sub	a
 946    2E03  320000    		ld	(c.r1),a
 947    2E06  320100    		ld	(c.r1+1),a
 948    2E09  0A        		ld	a,(bc)
 949    2E0A  320200    		ld	(c.r1+2),a
 950    2E0D  97        		sub	a
 951    2E0E  320300    		ld	(c.r1+3),a
 952    2E11  210000    		ld	hl,c.r1
 953    2E14  E5        		push	hl
 954    2E15  211000    		ld	hl,16
 955    2E18  E5        		push	hl
 956    2E19  CD0000    		call	c.llsh
 957    2E1C  CD0000    		call	c.ladd
 958    2E1F  DD6EEE    		ld	l,(ix-18)
 959    2E22  DD66EF    		ld	h,(ix-17)
 960    2E25  012300    		ld	bc,35
 961    2E28  09        		add	hl,bc
 962    2E29  4D        		ld	c,l
 963    2E2A  44        		ld	b,h
 964    2E2B  97        		sub	a
 965    2E2C  320000    		ld	(c.r1),a
 966    2E2F  320100    		ld	(c.r1+1),a
 967    2E32  0A        		ld	a,(bc)
 968    2E33  320200    		ld	(c.r1+2),a
 969    2E36  97        		sub	a
 970    2E37  320300    		ld	(c.r1+3),a
 971    2E3A  210000    		ld	hl,c.r1
 972    2E3D  E5        		push	hl
 973    2E3E  211800    		ld	hl,24
 974    2E41  E5        		push	hl
 975    2E42  CD0000    		call	c.llsh
 976    2E45  CD0000    		call	c.ladd
 977    2E48  CD0000    		call	c.mvl
 978    2E4B  F1        		pop	af
 979                    	; 1147      if (sdtestflg)
 980    2E4C  2A0000    		ld	hl,(_sdtestflg)
 981    2E4F  7C        		ld	a,h
 982    2E50  B5        		or	l
 983    2E51  CAB32E    		jp	z,L1234
 984                    	; 1148          {
 985                    	; 1149          printf("%lu", flba);
 986    2E54  DD66EB    		ld	h,(ix-21)
 987    2E57  DD6EEA    		ld	l,(ix-22)
 988    2E5A  E5        		push	hl
 989    2E5B  DD66E9    		ld	h,(ix-23)
 990    2E5E  DD6EE8    		ld	l,(ix-24)
 991    2E61  E5        		push	hl
 992    2E62  21172B    		ld	hl,L5702
 993    2E65  CD0000    		call	_printf
 994    2E68  F1        		pop	af
 995    2E69  F1        		pop	af
 996                    	; 1150          printf(" [");
 997    2E6A  211B2B    		ld	hl,L5012
 998    2E6D  CD0000    		call	_printf
 999                    	; 1151          for (index = 32; index < (32 + 8); index++)
1000    2E70  DD36F820  		ld	(ix-8),32
1001    2E74  DD36F900  		ld	(ix-7),0
1002                    	L1334:
1003    2E78  DD7EF8    		ld	a,(ix-8)
1004    2E7B  D628      		sub	40
1005    2E7D  DD7EF9    		ld	a,(ix-7)
1006    2E80  DE00      		sbc	a,0
1007    2E82  F2A72E    		jp	p,L1434
1008                    	; 1152              printf("%02x ", entryptr[index]);
1009    2E85  DD6EEE    		ld	l,(ix-18)
1010    2E88  DD66EF    		ld	h,(ix-17)
1011    2E8B  DD4EF8    		ld	c,(ix-8)
1012    2E8E  DD46F9    		ld	b,(ix-7)
1013    2E91  09        		add	hl,bc
1014    2E92  4E        		ld	c,(hl)
1015    2E93  97        		sub	a
1016    2E94  47        		ld	b,a
1017    2E95  C5        		push	bc
1018    2E96  211E2B    		ld	hl,L5112
1019    2E99  CD0000    		call	_printf
1020    2E9C  F1        		pop	af
1021    2E9D  DD34F8    		inc	(ix-8)
1022    2EA0  2003      		jr	nz,L441
1023    2EA2  DD34F9    		inc	(ix-7)
1024                    	L441:
1025    2EA5  18D1      		jr	L1334
1026                    	L1434:
1027                    	; 1153          printf("\b]");
1028    2EA7  21242B    		ld	hl,L5212
1029    2EAA  CD0000    		call	_printf
1030                    	; 1154          printf("\n  Last LBA: ");
1031    2EAD  21272B    		ld	hl,L5312
1032    2EB0  CD0000    		call	_printf
1033                    	L1234:
1034                    	; 1155          } /* sdtestflg */
1035                    	; 1156      /* lower 32 bits of LBA should be sufficient (I hope) */
1036                    	; 1157      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
1037                    	; 1158             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
1038    2EB3  DDE5      		push	ix
1039    2EB5  C1        		pop	bc
1040    2EB6  21E4FF    		ld	hl,65508
1041    2EB9  09        		add	hl,bc
1042    2EBA  E5        		push	hl
1043    2EBB  DD6EEE    		ld	l,(ix-18)
1044    2EBE  DD66EF    		ld	h,(ix-17)
1045    2EC1  012800    		ld	bc,40
1046    2EC4  09        		add	hl,bc
1047    2EC5  4D        		ld	c,l
1048    2EC6  44        		ld	b,h
1049    2EC7  97        		sub	a
1050    2EC8  320000    		ld	(c.r0),a
1051    2ECB  320100    		ld	(c.r0+1),a
1052    2ECE  0A        		ld	a,(bc)
1053    2ECF  320200    		ld	(c.r0+2),a
1054    2ED2  97        		sub	a
1055    2ED3  320300    		ld	(c.r0+3),a
1056    2ED6  210000    		ld	hl,c.r0
1057    2ED9  E5        		push	hl
1058    2EDA  DD6EEE    		ld	l,(ix-18)
1059    2EDD  DD66EF    		ld	h,(ix-17)
1060    2EE0  012900    		ld	bc,41
1061    2EE3  09        		add	hl,bc
1062    2EE4  4D        		ld	c,l
1063    2EE5  44        		ld	b,h
1064    2EE6  97        		sub	a
1065    2EE7  320000    		ld	(c.r1),a
1066    2EEA  320100    		ld	(c.r1+1),a
1067    2EED  0A        		ld	a,(bc)
1068    2EEE  320200    		ld	(c.r1+2),a
1069    2EF1  97        		sub	a
1070    2EF2  320300    		ld	(c.r1+3),a
1071    2EF5  210000    		ld	hl,c.r1
1072    2EF8  E5        		push	hl
1073    2EF9  210800    		ld	hl,8
1074    2EFC  E5        		push	hl
1075    2EFD  CD0000    		call	c.llsh
1076    2F00  CD0000    		call	c.ladd
1077    2F03  DD6EEE    		ld	l,(ix-18)
1078    2F06  DD66EF    		ld	h,(ix-17)
1079    2F09  012A00    		ld	bc,42
1080    2F0C  09        		add	hl,bc
1081    2F0D  4D        		ld	c,l
1082    2F0E  44        		ld	b,h
1083    2F0F  97        		sub	a
1084    2F10  320000    		ld	(c.r1),a
1085    2F13  320100    		ld	(c.r1+1),a
1086    2F16  0A        		ld	a,(bc)
1087    2F17  320200    		ld	(c.r1+2),a
1088    2F1A  97        		sub	a
1089    2F1B  320300    		ld	(c.r1+3),a
1090    2F1E  210000    		ld	hl,c.r1
1091    2F21  E5        		push	hl
1092    2F22  211000    		ld	hl,16
1093    2F25  E5        		push	hl
1094    2F26  CD0000    		call	c.llsh
1095    2F29  CD0000    		call	c.ladd
1096    2F2C  DD6EEE    		ld	l,(ix-18)
1097    2F2F  DD66EF    		ld	h,(ix-17)
1098    2F32  012B00    		ld	bc,43
1099    2F35  09        		add	hl,bc
1100    2F36  4D        		ld	c,l
1101    2F37  44        		ld	b,h
1102    2F38  97        		sub	a
1103    2F39  320000    		ld	(c.r1),a
1104    2F3C  320100    		ld	(c.r1+1),a
1105    2F3F  0A        		ld	a,(bc)
1106    2F40  320200    		ld	(c.r1+2),a
1107    2F43  97        		sub	a
1108    2F44  320300    		ld	(c.r1+3),a
1109    2F47  210000    		ld	hl,c.r1
1110    2F4A  E5        		push	hl
1111    2F4B  211800    		ld	hl,24
1112    2F4E  E5        		push	hl
1113    2F4F  CD0000    		call	c.llsh
1114    2F52  CD0000    		call	c.ladd
1115    2F55  CD0000    		call	c.mvl
1116    2F58  F1        		pop	af
1117                    	; 1159  
1118                    	; 1160      if (entryptr[48] & 0x04)
1119    2F59  DD6EEE    		ld	l,(ix-18)
1120    2F5C  DD66EF    		ld	h,(ix-17)
1121    2F5F  013000    		ld	bc,48
1122    2F62  09        		add	hl,bc
1123    2F63  7E        		ld	a,(hl)
1124    2F64  CB57      		bit	2,a
1125    2F66  6F        		ld	l,a
1126    2F67  2815      		jr	z,L1734
1127                    	; 1161          dskmap[partdsk].bootable = YES;
1128    2F69  2A0E00    		ld	hl,(_partdsk)
1129    2F6C  E5        		push	hl
1130    2F6D  212000    		ld	hl,32
1131    2F70  E5        		push	hl
1132    2F71  CD0000    		call	c.imul
1133    2F74  E1        		pop	hl
1134    2F75  015202    		ld	bc,_dskmap+2
1135    2F78  09        		add	hl,bc
1136    2F79  3601      		ld	(hl),1
1137    2F7B  23        		inc	hl
1138    2F7C  3600      		ld	(hl),0
1139                    	L1734:
1140                    	; 1162      dskmap[partdsk].partype = PARTGPT;
1141    2F7E  2A0E00    		ld	hl,(_partdsk)
1142    2F81  E5        		push	hl
1143    2F82  212000    		ld	hl,32
1144    2F85  E5        		push	hl
1145    2F86  CD0000    		call	c.imul
1146    2F89  E1        		pop	hl
1147    2F8A  015002    		ld	bc,_dskmap
1148    2F8D  09        		add	hl,bc
1149    2F8E  3603      		ld	(hl),3
1150                    	; 1163      dskmap[partdsk].dskletter = 'A' + partdsk;
1151    2F90  2A0E00    		ld	hl,(_partdsk)
1152    2F93  E5        		push	hl
1153    2F94  212000    		ld	hl,32
1154    2F97  E5        		push	hl
1155    2F98  CD0000    		call	c.imul
1156    2F9B  E1        		pop	hl
1157    2F9C  015102    		ld	bc,_dskmap+1
1158    2F9F  09        		add	hl,bc
1159    2FA0  3A0E00    		ld	a,(_partdsk)
1160    2FA3  C641      		add	a,65
1161    2FA5  4F        		ld	c,a
1162    2FA6  71        		ld	(hl),c
1163                    	; 1164      dskmap[partdsk].dskstart = flba;
1164    2FA7  2A0E00    		ld	hl,(_partdsk)
1165    2FAA  E5        		push	hl
1166    2FAB  212000    		ld	hl,32
1167    2FAE  E5        		push	hl
1168    2FAF  CD0000    		call	c.imul
1169    2FB2  E1        		pop	hl
1170    2FB3  015402    		ld	bc,_dskmap+4
1171    2FB6  09        		add	hl,bc
1172    2FB7  E5        		push	hl
1173    2FB8  DDE5      		push	ix
1174    2FBA  C1        		pop	bc
1175    2FBB  21E8FF    		ld	hl,65512
1176    2FBE  09        		add	hl,bc
1177    2FBF  E5        		push	hl
1178    2FC0  CD0000    		call	c.mvl
1179    2FC3  F1        		pop	af
1180                    	; 1165      dskmap[partdsk].dskend = llba;
1181    2FC4  2A0E00    		ld	hl,(_partdsk)
1182    2FC7  E5        		push	hl
1183    2FC8  212000    		ld	hl,32
1184    2FCB  E5        		push	hl
1185    2FCC  CD0000    		call	c.imul
1186    2FCF  E1        		pop	hl
1187    2FD0  015802    		ld	bc,_dskmap+8
1188    2FD3  09        		add	hl,bc
1189    2FD4  E5        		push	hl
1190    2FD5  DDE5      		push	ix
1191    2FD7  C1        		pop	bc
1192    2FD8  21E4FF    		ld	hl,65508
1193    2FDB  09        		add	hl,bc
1194    2FDC  E5        		push	hl
1195    2FDD  CD0000    		call	c.mvl
1196    2FE0  F1        		pop	af
1197                    	; 1166      dskmap[partdsk].dsksize = llba - flba + 1;
1198    2FE1  2A0E00    		ld	hl,(_partdsk)
1199    2FE4  E5        		push	hl
1200    2FE5  212000    		ld	hl,32
1201    2FE8  E5        		push	hl
1202    2FE9  CD0000    		call	c.imul
1203    2FEC  E1        		pop	hl
1204    2FED  015C02    		ld	bc,_dskmap+12
1205    2FF0  09        		add	hl,bc
1206    2FF1  E5        		push	hl
1207    2FF2  DDE5      		push	ix
1208    2FF4  C1        		pop	bc
1209    2FF5  21E4FF    		ld	hl,65508
1210    2FF8  09        		add	hl,bc
1211    2FF9  CD0000    		call	c.0mvf
1212    2FFC  210000    		ld	hl,c.r0
1213    2FFF  E5        		push	hl
1214    3000  DDE5      		push	ix
1215    3002  C1        		pop	bc
1216    3003  21E8FF    		ld	hl,65512
1217    3006  09        		add	hl,bc
1218    3007  E5        		push	hl
1219    3008  CD0000    		call	c.lsub
1220    300B  3E01      		ld	a,1
1221    300D  320200    		ld	(c.r1+2),a
1222    3010  87        		add	a,a
1223    3011  9F        		sbc	a,a
1224    3012  320300    		ld	(c.r1+3),a
1225    3015  320100    		ld	(c.r1+1),a
1226    3018  320000    		ld	(c.r1),a
1227    301B  210000    		ld	hl,c.r1
1228    301E  E5        		push	hl
1229    301F  CD0000    		call	c.ladd
1230    3022  CD0000    		call	c.mvl
1231    3025  F1        		pop	af
1232                    	; 1167      memcpy(dskmap[partdsk].dsktype, entryptr, 16);
1233    3026  211000    		ld	hl,16
1234    3029  E5        		push	hl
1235    302A  DD6EEE    		ld	l,(ix-18)
1236    302D  DD66EF    		ld	h,(ix-17)
1237    3030  E5        		push	hl
1238    3031  2A0E00    		ld	hl,(_partdsk)
1239    3034  E5        		push	hl
1240    3035  212000    		ld	hl,32
1241    3038  E5        		push	hl
1242    3039  CD0000    		call	c.imul
1243    303C  E1        		pop	hl
1244    303D  016002    		ld	bc,_dskmap+16
1245    3040  09        		add	hl,bc
1246    3041  CD0000    		call	_memcpy
1247    3044  F1        		pop	af
1248    3045  F1        		pop	af
1249                    	; 1168      partdsk++;
1250    3046  2A0E00    		ld	hl,(_partdsk)
1251    3049  23        		inc	hl
1252    304A  220E00    		ld	(_partdsk),hl
1253                    	; 1169  
1254                    	; 1170      if (sdtestflg)
1255    304D  2A0000    		ld	hl,(_sdtestflg)
1256    3050  7C        		ld	a,h
1257    3051  B5        		or	l
1258    3052  CA3131    		jp	z,L1044
1259                    	; 1171          {
1260                    	; 1172          printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
1261    3055  DDE5      		push	ix
1262    3057  C1        		pop	bc
1263    3058  21E4FF    		ld	hl,65508
1264    305B  09        		add	hl,bc
1265    305C  CD0000    		call	c.0mvf
1266    305F  210000    		ld	hl,c.r0
1267    3062  E5        		push	hl
1268    3063  DDE5      		push	ix
1269    3065  C1        		pop	bc
1270    3066  21E8FF    		ld	hl,65512
1271    3069  09        		add	hl,bc
1272    306A  E5        		push	hl
1273    306B  CD0000    		call	c.lsub
1274    306E  210B00    		ld	hl,11
1275    3071  E5        		push	hl
1276    3072  CD0000    		call	c.ulrsh
1277    3075  E1        		pop	hl
1278    3076  23        		inc	hl
1279    3077  23        		inc	hl
1280    3078  4E        		ld	c,(hl)
1281    3079  23        		inc	hl
1282    307A  46        		ld	b,(hl)
1283    307B  C5        		push	bc
1284    307C  2B        		dec	hl
1285    307D  2B        		dec	hl
1286    307E  2B        		dec	hl
1287    307F  4E        		ld	c,(hl)
1288    3080  23        		inc	hl
1289    3081  46        		ld	b,(hl)
1290    3082  C5        		push	bc
1291    3083  DD66E7    		ld	h,(ix-25)
1292    3086  DD6EE6    		ld	l,(ix-26)
1293    3089  E5        		push	hl
1294    308A  DD66E5    		ld	h,(ix-27)
1295    308D  DD6EE4    		ld	l,(ix-28)
1296    3090  E5        		push	hl
1297    3091  21352B    		ld	hl,L5412
1298    3094  CD0000    		call	_printf
1299    3097  F1        		pop	af
1300    3098  F1        		pop	af
1301    3099  F1        		pop	af
1302    309A  F1        		pop	af
1303                    	; 1173          printf(" [");
1304    309B  21492B    		ld	hl,L5512
1305    309E  CD0000    		call	_printf
1306                    	; 1174          for (index = 40; index < (40 + 8); index++)
1307    30A1  DD36F828  		ld	(ix-8),40
1308    30A5  DD36F900  		ld	(ix-7),0
1309                    	L1144:
1310    30A9  DD7EF8    		ld	a,(ix-8)
1311    30AC  D630      		sub	48
1312    30AE  DD7EF9    		ld	a,(ix-7)
1313    30B1  DE00      		sbc	a,0
1314    30B3  F2D830    		jp	p,L1244
1315                    	; 1175              printf("%02x ", entryptr[index]);
1316    30B6  DD6EEE    		ld	l,(ix-18)
1317    30B9  DD66EF    		ld	h,(ix-17)
1318    30BC  DD4EF8    		ld	c,(ix-8)
1319    30BF  DD46F9    		ld	b,(ix-7)
1320    30C2  09        		add	hl,bc
1321    30C3  4E        		ld	c,(hl)
1322    30C4  97        		sub	a
1323    30C5  47        		ld	b,a
1324    30C6  C5        		push	bc
1325    30C7  214C2B    		ld	hl,L5612
1326    30CA  CD0000    		call	_printf
1327    30CD  F1        		pop	af
1328    30CE  DD34F8    		inc	(ix-8)
1329    30D1  2003      		jr	nz,L641
1330    30D3  DD34F9    		inc	(ix-7)
1331                    	L641:
1332    30D6  18D1      		jr	L1144
1333                    	L1244:
1334                    	; 1176          printf("\b]");
1335    30D8  21522B    		ld	hl,L5712
1336    30DB  CD0000    		call	_printf
1337                    	; 1177          printf("\n  Attribute flags: [");
1338    30DE  21552B    		ld	hl,L5022
1339    30E1  CD0000    		call	_printf
1340                    	; 1178          /* bits 0 - 2 and 60 - 63 should be decoded */
1341                    	; 1179          for (index = 0; index < 8; index++)
1342    30E4  DD36F800  		ld	(ix-8),0
1343    30E8  DD36F900  		ld	(ix-7),0
1344                    	L1544:
1345    30EC  DD7EF8    		ld	a,(ix-8)
1346    30EF  D608      		sub	8
1347    30F1  DD7EF9    		ld	a,(ix-7)
1348    30F4  DE00      		sbc	a,0
1349    30F6  F22B31    		jp	p,L1644
1350                    	; 1180              {
1351                    	; 1181              entryidx = index + 48;
1352    30F9  DD6EF8    		ld	l,(ix-8)
1353    30FC  DD66F9    		ld	h,(ix-7)
1354    30FF  013000    		ld	bc,48
1355    3102  09        		add	hl,bc
1356    3103  DD75F6    		ld	(ix-10),l
1357    3106  DD74F7    		ld	(ix-9),h
1358                    	; 1182              printf("%02x ", entryptr[entryidx]);
1359    3109  DD6EEE    		ld	l,(ix-18)
1360    310C  DD66EF    		ld	h,(ix-17)
1361    310F  DD4EF6    		ld	c,(ix-10)
1362    3112  DD46F7    		ld	b,(ix-9)
1363    3115  09        		add	hl,bc
1364    3116  4E        		ld	c,(hl)
1365    3117  97        		sub	a
1366    3118  47        		ld	b,a
1367    3119  C5        		push	bc
1368    311A  216B2B    		ld	hl,L5122
1369    311D  CD0000    		call	_printf
1370    3120  F1        		pop	af
1371                    	; 1183              }
1372    3121  DD34F8    		inc	(ix-8)
1373    3124  2003      		jr	nz,L051
1374    3126  DD34F9    		inc	(ix-7)
1375                    	L051:
1376    3129  18C1      		jr	L1544
1377                    	L1644:
1378                    	; 1184          printf("\b]\n  Partition name:  ");
1379    312B  21712B    		ld	hl,L5222
1380    312E  CD0000    		call	_printf
1381                    	L1044:
1382                    	; 1185          } /* sdtestflg */
1383                    	; 1186      /* partition name is in UTF-16LE code units */
1384                    	; 1187      hasname = NO;
1385    3131  DD36F400  		ld	(ix-12),0
1386    3135  DD36F500  		ld	(ix-11),0
1387                    	; 1188      for (index = 0; index < 72; index += 2)
1388    3139  DD36F800  		ld	(ix-8),0
1389    313D  DD36F900  		ld	(ix-7),0
1390                    	L1154:
1391    3141  DD7EF8    		ld	a,(ix-8)
1392    3144  D648      		sub	72
1393    3146  DD7EF9    		ld	a,(ix-7)
1394    3149  DE00      		sbc	a,0
1395    314B  F2E131    		jp	p,L1254
1396                    	; 1189          {
1397                    	; 1190          entryidx = index + 56;
1398    314E  DD6EF8    		ld	l,(ix-8)
1399    3151  DD66F9    		ld	h,(ix-7)
1400    3154  013800    		ld	bc,56
1401    3157  09        		add	hl,bc
1402    3158  DD75F6    		ld	(ix-10),l
1403    315B  DD74F7    		ld	(ix-9),h
1404                    	; 1191          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
1405    315E  DD6EEE    		ld	l,(ix-18)
1406    3161  DD66EF    		ld	h,(ix-17)
1407    3164  DD4EF6    		ld	c,(ix-10)
1408    3167  DD46F7    		ld	b,(ix-9)
1409    316A  09        		add	hl,bc
1410    316B  6E        		ld	l,(hl)
1411    316C  E5        		push	hl
1412    316D  DD6EF6    		ld	l,(ix-10)
1413    3170  DD66F7    		ld	h,(ix-9)
1414    3173  23        		inc	hl
1415    3174  DD4EEE    		ld	c,(ix-18)
1416    3177  DD46EF    		ld	b,(ix-17)
1417    317A  09        		add	hl,bc
1418    317B  C1        		pop	bc
1419    317C  79        		ld	a,c
1420    317D  B6        		or	(hl)
1421    317E  4F        		ld	c,a
1422    317F  CAE131    		jp	z,L1254
1423                    	; 1192              break;
1424                    	; 1193          if (sdtestflg)
1425    3182  2A0000    		ld	hl,(_sdtestflg)
1426    3185  7C        		ld	a,h
1427    3186  B5        		or	l
1428    3187  283F      		jr	z,L1654
1429                    	; 1194              {
1430                    	; 1195              if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
1431    3189  DD6EEE    		ld	l,(ix-18)
1432    318C  DD66EF    		ld	h,(ix-17)
1433    318F  DD4EF6    		ld	c,(ix-10)
1434    3192  DD46F7    		ld	b,(ix-9)
1435    3195  09        		add	hl,bc
1436    3196  7E        		ld	a,(hl)
1437    3197  FE20      		cp	32
1438    3199  3827      		jr	c,L1754
1439    319B  DD6EEE    		ld	l,(ix-18)
1440    319E  DD66EF    		ld	h,(ix-17)
1441    31A1  DD4EF6    		ld	c,(ix-10)
1442    31A4  DD46F7    		ld	b,(ix-9)
1443    31A7  09        		add	hl,bc
1444    31A8  7E        		ld	a,(hl)
1445    31A9  FE7F      		cp	127
1446    31AB  3015      		jr	nc,L1754
1447                    	; 1196                  putchar(entryptr[entryidx]);
1448    31AD  DD6EEE    		ld	l,(ix-18)
1449    31B0  DD66EF    		ld	h,(ix-17)
1450    31B3  DD4EF6    		ld	c,(ix-10)
1451    31B6  DD46F7    		ld	b,(ix-9)
1452    31B9  09        		add	hl,bc
1453    31BA  6E        		ld	l,(hl)
1454    31BB  97        		sub	a
1455    31BC  67        		ld	h,a
1456    31BD  CD0000    		call	_putchar
1457                    	; 1197              else
1458    31C0  1806      		jr	L1654
1459                    	L1754:
1460                    	; 1198                  putchar('.');
1461    31C2  212E00    		ld	hl,46
1462    31C5  CD0000    		call	_putchar
1463                    	L1654:
1464                    	; 1199              } /* sdtestflg */
1465                    	; 1200          hasname = YES;
1466    31C8  DD36F401  		ld	(ix-12),1
1467    31CC  DD36F500  		ld	(ix-11),0
1468                    	; 1201          }
1469    31D0  DD6EF8    		ld	l,(ix-8)
1470    31D3  DD66F9    		ld	h,(ix-7)
1471    31D6  23        		inc	hl
1472    31D7  23        		inc	hl
1473    31D8  DD75F8    		ld	(ix-8),l
1474    31DB  DD74F9    		ld	(ix-7),h
1475    31DE  C34131    		jp	L1154
1476                    	L1254:
1477                    	; 1202      if (sdtestflg)
1478    31E1  2A0000    		ld	hl,(_sdtestflg)
1479    31E4  7C        		ld	a,h
1480    31E5  B5        		or	l
1481    31E6  CA6A32    		jp	z,L1164
1482                    	; 1203          {
1483                    	; 1204          if (!hasname)
1484    31E9  DD7EF4    		ld	a,(ix-12)
1485    31EC  DDB6F5    		or	(ix-11)
1486    31EF  2006      		jr	nz,L1264
1487                    	; 1205              printf("name field empty");
1488    31F1  21882B    		ld	hl,L5322
1489    31F4  CD0000    		call	_printf
1490                    	L1264:
1491                    	; 1206          printf("\n");
1492    31F7  21992B    		ld	hl,L5422
1493    31FA  CD0000    		call	_printf
1494                    	; 1207          printf("   [");
1495    31FD  219B2B    		ld	hl,L5522
1496    3200  CD0000    		call	_printf
1497                    	; 1208          for (index = 0; index < 72; index++)
1498    3203  DD36F800  		ld	(ix-8),0
1499    3207  DD36F900  		ld	(ix-7),0
1500                    	L1364:
1501    320B  DD7EF8    		ld	a,(ix-8)
1502    320E  D648      		sub	72
1503    3210  DD7EF9    		ld	a,(ix-7)
1504    3213  DE00      		sbc	a,0
1505    3215  F26432    		jp	p,L1464
1506                    	; 1209              {
1507                    	; 1210              if (((index & 0xf) == 0) && (index != 0))
1508    3218  DD6EF8    		ld	l,(ix-8)
1509    321B  DD66F9    		ld	h,(ix-7)
1510    321E  7D        		ld	a,l
1511    321F  E60F      		and	15
1512    3221  200E      		jr	nz,L1764
1513    3223  DD7EF8    		ld	a,(ix-8)
1514    3226  DDB6F9    		or	(ix-7)
1515    3229  2806      		jr	z,L1764
1516                    	; 1211                  printf("\n    ");
1517    322B  21A02B    		ld	hl,L5622
1518    322E  CD0000    		call	_printf
1519                    	L1764:
1520                    	; 1212              entryidx = index + 56;
1521    3231  DD6EF8    		ld	l,(ix-8)
1522    3234  DD66F9    		ld	h,(ix-7)
1523    3237  013800    		ld	bc,56
1524    323A  09        		add	hl,bc
1525    323B  DD75F6    		ld	(ix-10),l
1526    323E  DD74F7    		ld	(ix-9),h
1527                    	; 1213              printf("%02x ", entryptr[entryidx]);
1528    3241  DD6EEE    		ld	l,(ix-18)
1529    3244  DD66EF    		ld	h,(ix-17)
1530    3247  DD4EF6    		ld	c,(ix-10)
1531    324A  DD46F7    		ld	b,(ix-9)
1532    324D  09        		add	hl,bc
1533    324E  4E        		ld	c,(hl)
1534    324F  97        		sub	a
1535    3250  47        		ld	b,a
1536    3251  C5        		push	bc
1537    3252  21A62B    		ld	hl,L5722
1538    3255  CD0000    		call	_printf
1539    3258  F1        		pop	af
1540                    	; 1214              }
1541    3259  DD34F8    		inc	(ix-8)
1542    325C  2003      		jr	nz,L251
1543    325E  DD34F9    		inc	(ix-7)
1544                    	L251:
1545    3261  C30B32    		jp	L1364
1546                    	L1464:
1547                    	; 1215          printf("\b]\n");
1548    3264  21AC2B    		ld	hl,L5032
1549    3267  CD0000    		call	_printf
1550                    	L1164:
1551                    	; 1216          } /* sdtestflg */
1552                    	; 1217      return (YES);
1553    326A  010100    		ld	bc,1
1554    326D  C30000    		jp	c.rets
1555                    	L5132:
1556    3270  47        		.byte	71
1557    3271  50        		.byte	80
1558    3272  54        		.byte	84
1559    3273  20        		.byte	32
1560    3274  68        		.byte	104
1561    3275  65        		.byte	101
1562    3276  61        		.byte	97
1563    3277  64        		.byte	100
1564    3278  65        		.byte	101
1565    3279  72        		.byte	114
1566    327A  0A        		.byte	10
1567    327B  00        		.byte	0
1568                    	L5232:
1569    327C  43        		.byte	67
1570    327D  61        		.byte	97
1571    327E  6E        		.byte	110
1572    327F  27        		.byte	39
1573    3280  74        		.byte	116
1574    3281  20        		.byte	32
1575    3282  72        		.byte	114
1576    3283  65        		.byte	101
1577    3284  61        		.byte	97
1578    3285  64        		.byte	100
1579    3286  20        		.byte	32
1580    3287  47        		.byte	71
1581    3288  50        		.byte	80
1582    3289  54        		.byte	84
1583    328A  20        		.byte	32
1584    328B  70        		.byte	112
1585    328C  61        		.byte	97
1586    328D  72        		.byte	114
1587    328E  74        		.byte	116
1588    328F  69        		.byte	105
1589    3290  74        		.byte	116
1590    3291  69        		.byte	105
1591    3292  6F        		.byte	111
1592    3293  6E        		.byte	110
1593    3294  20        		.byte	32
1594    3295  74        		.byte	116
1595    3296  61        		.byte	97
1596    3297  62        		.byte	98
1597    3298  6C        		.byte	108
1598    3299  65        		.byte	101
1599    329A  20        		.byte	32
1600    329B  68        		.byte	104
1601    329C  65        		.byte	101
1602    329D  61        		.byte	97
1603    329E  64        		.byte	100
1604    329F  65        		.byte	101
1605    32A0  72        		.byte	114
1606    32A1  0A        		.byte	10
1607    32A2  00        		.byte	0
1608                    	L5332:
1609    32A3  20        		.byte	32
1610    32A4  20        		.byte	32
1611    32A5  53        		.byte	83
1612    32A6  69        		.byte	105
1613    32A7  67        		.byte	103
1614    32A8  6E        		.byte	110
1615    32A9  61        		.byte	97
1616    32AA  74        		.byte	116
1617    32AB  75        		.byte	117
1618    32AC  72        		.byte	114
1619    32AD  65        		.byte	101
1620    32AE  3A        		.byte	58
1621    32AF  20        		.byte	32
1622    32B0  25        		.byte	37
1623    32B1  2E        		.byte	46
1624    32B2  38        		.byte	56
1625    32B3  73        		.byte	115
1626    32B4  0A        		.byte	10
1627    32B5  00        		.byte	0
1628                    	L5432:
1629    32B6  20        		.byte	32
1630    32B7  20        		.byte	32
1631    32B8  52        		.byte	82
1632    32B9  65        		.byte	101
1633    32BA  76        		.byte	118
1634    32BB  69        		.byte	105
1635    32BC  73        		.byte	115
1636    32BD  69        		.byte	105
1637    32BE  6F        		.byte	111
1638    32BF  6E        		.byte	110
1639    32C0  3A        		.byte	58
1640    32C1  20        		.byte	32
1641    32C2  25        		.byte	37
1642    32C3  64        		.byte	100
1643    32C4  2E        		.byte	46
1644    32C5  25        		.byte	37
1645    32C6  64        		.byte	100
1646    32C7  20        		.byte	32
1647    32C8  5B        		.byte	91
1648    32C9  25        		.byte	37
1649    32CA  30        		.byte	48
1650    32CB  32        		.byte	50
1651    32CC  78        		.byte	120
1652    32CD  20        		.byte	32
1653    32CE  25        		.byte	37
1654    32CF  30        		.byte	48
1655    32D0  32        		.byte	50
1656    32D1  78        		.byte	120
1657    32D2  20        		.byte	32
1658    32D3  25        		.byte	37
1659    32D4  30        		.byte	48
1660    32D5  32        		.byte	50
1661    32D6  78        		.byte	120
1662    32D7  20        		.byte	32
1663    32D8  25        		.byte	37
1664    32D9  30        		.byte	48
1665    32DA  32        		.byte	50
1666    32DB  78        		.byte	120
1667    32DC  5D        		.byte	93
1668    32DD  0A        		.byte	10
1669    32DE  00        		.byte	0
1670                    	L5532:
1671    32DF  20        		.byte	32
1672    32E0  20        		.byte	32
1673    32E1  4E        		.byte	78
1674    32E2  75        		.byte	117
1675    32E3  6D        		.byte	109
1676    32E4  62        		.byte	98
1677    32E5  65        		.byte	101
1678    32E6  72        		.byte	114
1679    32E7  20        		.byte	32
1680    32E8  6F        		.byte	111
1681    32E9  66        		.byte	102
1682    32EA  20        		.byte	32
1683    32EB  70        		.byte	112
1684    32EC  61        		.byte	97
1685    32ED  72        		.byte	114
1686    32EE  74        		.byte	116
1687    32EF  69        		.byte	105
1688    32F0  74        		.byte	116
1689    32F1  69        		.byte	105
1690    32F2  6F        		.byte	111
1691    32F3  6E        		.byte	110
1692    32F4  20        		.byte	32
1693    32F5  65        		.byte	101
1694    32F6  6E        		.byte	110
1695    32F7  74        		.byte	116
1696    32F8  72        		.byte	114
1697    32F9  69        		.byte	105
1698    32FA  65        		.byte	101
1699    32FB  73        		.byte	115
1700    32FC  3A        		.byte	58
1701    32FD  20        		.byte	32
1702    32FE  25        		.byte	37
1703    32FF  6C        		.byte	108
1704    3300  75        		.byte	117
1705    3301  20        		.byte	32
1706    3302  28        		.byte	40
1707    3303  6D        		.byte	109
1708    3304  61        		.byte	97
1709    3305  79        		.byte	121
1710    3306  20        		.byte	32
1711    3307  62        		.byte	98
1712    3308  65        		.byte	101
1713    3309  20        		.byte	32
1714    330A  61        		.byte	97
1715    330B  63        		.byte	99
1716    330C  74        		.byte	116
1717    330D  75        		.byte	117
1718    330E  61        		.byte	97
1719    330F  6C        		.byte	108
1720    3310  20        		.byte	32
1721    3311  6F        		.byte	111
1722    3312  72        		.byte	114
1723    3313  20        		.byte	32
1724    3314  6D        		.byte	109
1725    3315  61        		.byte	97
1726    3316  78        		.byte	120
1727    3317  69        		.byte	105
1728    3318  6D        		.byte	109
1729    3319  75        		.byte	117
1730    331A  6D        		.byte	109
1731    331B  29        		.byte	41
1732    331C  0A        		.byte	10
1733    331D  00        		.byte	0
1734                    	L5632:
1735    331E  46        		.byte	70
1736    331F  69        		.byte	105
1737    3320  72        		.byte	114
1738    3321  73        		.byte	115
1739    3322  74        		.byte	116
1740    3323  20        		.byte	32
1741    3324  31        		.byte	49
1742    3325  36        		.byte	54
1743    3326  20        		.byte	32
1744    3327  47        		.byte	71
1745    3328  50        		.byte	80
1746    3329  54        		.byte	84
1747    332A  20        		.byte	32
1748    332B  65        		.byte	101
1749    332C  6E        		.byte	110
1750    332D  74        		.byte	116
1751    332E  72        		.byte	114
1752    332F  69        		.byte	105
1753    3330  65        		.byte	101
1754    3331  73        		.byte	115
1755    3332  20        		.byte	32
1756    3333  73        		.byte	115
1757    3334  63        		.byte	99
1758    3335  61        		.byte	97
1759    3336  6E        		.byte	110
1760    3337  6E        		.byte	110
1761    3338  65        		.byte	101
1762    3339  64        		.byte	100
1763    333A  0A        		.byte	10
1764    333B  00        		.byte	0
1765                    	; 1218      }
1766                    	; 1219  
1767                    	; 1220  /* Analyze and print GPT header
1768                    	; 1221   */
1769                    	; 1222  void sdgpthdr(unsigned long block)
1770                    	; 1223      {
1771                    	_sdgpthdr:
1772    333C  CD0000    		call	c.savs
1773    333F  21F0FF    		ld	hl,65520
1774    3342  39        		add	hl,sp
1775    3343  F9        		ld	sp,hl
1776                    	; 1224      int index;
1777                    	; 1225      unsigned int partno;
1778                    	; 1226      unsigned char *rxdata;
1779                    	; 1227      unsigned long entries;
1780                    	; 1228  
1781                    	; 1229      if (sdtestflg)
1782    3344  2A0000    		ld	hl,(_sdtestflg)
1783    3347  7C        		ld	a,h
1784    3348  B5        		or	l
1785    3349  2806      		jr	z,L1074
1786                    	; 1230          {
1787                    	; 1231          printf("GPT header\n");
1788    334B  217032    		ld	hl,L5132
1789    334E  CD0000    		call	_printf
1790                    	L1074:
1791                    	; 1232          } /* sdtestflg */
1792                    	; 1233      if (!sdread(sdrdbuf, block))
1793    3351  DD6607    		ld	h,(ix+7)
1794    3354  DD6E06    		ld	l,(ix+6)
1795    3357  E5        		push	hl
1796    3358  DD6605    		ld	h,(ix+5)
1797    335B  DD6E04    		ld	l,(ix+4)
1798    335E  E5        		push	hl
1799    335F  214C00    		ld	hl,_sdrdbuf
1800    3362  CDE120    		call	_sdread
1801    3365  F1        		pop	af
1802    3366  F1        		pop	af
1803    3367  79        		ld	a,c
1804    3368  B0        		or	b
1805    3369  2010      		jr	nz,L1174
1806                    	; 1234          {
1807                    	; 1235          if (sdtestflg)
1808    336B  2A0000    		ld	hl,(_sdtestflg)
1809    336E  7C        		ld	a,h
1810    336F  B5        		or	l
1811    3370  2806      		jr	z,L1274
1812                    	; 1236              {
1813                    	; 1237              printf("Can't read GPT partition table header\n");
1814    3372  217C32    		ld	hl,L5232
1815    3375  CD0000    		call	_printf
1816                    	L1274:
1817                    	; 1238              } /* sdtestflg */
1818                    	; 1239          return;
1819    3378  C30000    		jp	c.rets
1820                    	L1174:
1821                    	; 1240          }
1822                    	; 1241      curblkno = block;
1823    337B  210200    		ld	hl,_curblkno
1824    337E  E5        		push	hl
1825    337F  DDE5      		push	ix
1826    3381  C1        		pop	bc
1827    3382  210400    		ld	hl,4
1828    3385  09        		add	hl,bc
1829    3386  E5        		push	hl
1830    3387  CD0000    		call	c.mvl
1831    338A  F1        		pop	af
1832                    	; 1242      curblkok = YES;
1833    338B  210100    		ld	hl,1
1834    338E  221000    		ld	(_curblkok),hl
1835                    	; 1243  
1836                    	; 1244      rxdata = sdrdbuf;
1837    3391  214C00    		ld	hl,_sdrdbuf
1838    3394  DD75F4    		ld	(ix-12),l
1839    3397  DD74F5    		ld	(ix-11),h
1840                    	; 1245      if (sdtestflg)
1841    339A  2A0000    		ld	hl,(_sdtestflg)
1842    339D  7C        		ld	a,h
1843    339E  B5        		or	l
1844    339F  CAFD34    		jp	z,L1374
1845                    	; 1246          {
1846                    	; 1247          printf("  Signature: %.8s\n", &rxdata[0]);
1847    33A2  DD6EF4    		ld	l,(ix-12)
1848    33A5  DD66F5    		ld	h,(ix-11)
1849    33A8  E5        		push	hl
1850    33A9  21A332    		ld	hl,L5332
1851    33AC  CD0000    		call	_printf
1852    33AF  F1        		pop	af
1853                    	; 1248          printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
1854                    	; 1249                 (int)rxdata[8] * ((int)rxdata[9] << 8),
1855                    	; 1250                 (int)rxdata[10] + ((int)rxdata[11] << 8),
1856                    	; 1251                 rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
1857    33B0  DD6EF4    		ld	l,(ix-12)
1858    33B3  DD66F5    		ld	h,(ix-11)
1859    33B6  010B00    		ld	bc,11
1860    33B9  09        		add	hl,bc
1861    33BA  4E        		ld	c,(hl)
1862    33BB  97        		sub	a
1863    33BC  47        		ld	b,a
1864    33BD  C5        		push	bc
1865    33BE  DD6EF4    		ld	l,(ix-12)
1866    33C1  DD66F5    		ld	h,(ix-11)
1867    33C4  010A00    		ld	bc,10
1868    33C7  09        		add	hl,bc
1869    33C8  4E        		ld	c,(hl)
1870    33C9  97        		sub	a
1871    33CA  47        		ld	b,a
1872    33CB  C5        		push	bc
1873    33CC  DD6EF4    		ld	l,(ix-12)
1874    33CF  DD66F5    		ld	h,(ix-11)
1875    33D2  010900    		ld	bc,9
1876    33D5  09        		add	hl,bc
1877    33D6  4E        		ld	c,(hl)
1878    33D7  97        		sub	a
1879    33D8  47        		ld	b,a
1880    33D9  C5        		push	bc
1881    33DA  DD6EF4    		ld	l,(ix-12)
1882    33DD  DD66F5    		ld	h,(ix-11)
1883    33E0  010800    		ld	bc,8
1884    33E3  09        		add	hl,bc
1885    33E4  4E        		ld	c,(hl)
1886    33E5  97        		sub	a
1887    33E6  47        		ld	b,a
1888    33E7  C5        		push	bc
1889    33E8  DD6EF4    		ld	l,(ix-12)
1890    33EB  DD66F5    		ld	h,(ix-11)
1891    33EE  010A00    		ld	bc,10
1892    33F1  09        		add	hl,bc
1893    33F2  6E        		ld	l,(hl)
1894    33F3  97        		sub	a
1895    33F4  67        		ld	h,a
1896    33F5  E5        		push	hl
1897    33F6  DD6EF4    		ld	l,(ix-12)
1898    33F9  DD66F5    		ld	h,(ix-11)
1899    33FC  010B00    		ld	bc,11
1900    33FF  09        		add	hl,bc
1901    3400  6E        		ld	l,(hl)
1902    3401  97        		sub	a
1903    3402  67        		ld	h,a
1904    3403  29        		add	hl,hl
1905    3404  29        		add	hl,hl
1906    3405  29        		add	hl,hl
1907    3406  29        		add	hl,hl
1908    3407  29        		add	hl,hl
1909    3408  29        		add	hl,hl
1910    3409  29        		add	hl,hl
1911    340A  29        		add	hl,hl
1912    340B  E3        		ex	(sp),hl
1913    340C  C1        		pop	bc
1914    340D  09        		add	hl,bc
1915    340E  E5        		push	hl
1916    340F  DD6EF4    		ld	l,(ix-12)
1917    3412  DD66F5    		ld	h,(ix-11)
1918    3415  010800    		ld	bc,8
1919    3418  09        		add	hl,bc
1920    3419  6E        		ld	l,(hl)
1921    341A  97        		sub	a
1922    341B  67        		ld	h,a
1923    341C  E5        		push	hl
1924    341D  DD6EF4    		ld	l,(ix-12)
1925    3420  DD66F5    		ld	h,(ix-11)
1926    3423  010900    		ld	bc,9
1927    3426  09        		add	hl,bc
1928    3427  6E        		ld	l,(hl)
1929    3428  97        		sub	a
1930    3429  67        		ld	h,a
1931    342A  29        		add	hl,hl
1932    342B  29        		add	hl,hl
1933    342C  29        		add	hl,hl
1934    342D  29        		add	hl,hl
1935    342E  29        		add	hl,hl
1936    342F  29        		add	hl,hl
1937    3430  29        		add	hl,hl
1938    3431  29        		add	hl,hl
1939    3432  E5        		push	hl
1940    3433  CD0000    		call	c.imul
1941    3436  21B632    		ld	hl,L5432
1942    3439  CD0000    		call	_printf
1943    343C  210C00    		ld	hl,12
1944    343F  39        		add	hl,sp
1945    3440  F9        		ld	sp,hl
1946                    	; 1252          entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
1947                    	; 1253                    ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
1948    3441  DDE5      		push	ix
1949    3443  C1        		pop	bc
1950    3444  21F0FF    		ld	hl,65520
1951    3447  09        		add	hl,bc
1952    3448  E5        		push	hl
1953    3449  DD6EF4    		ld	l,(ix-12)
1954    344C  DD66F5    		ld	h,(ix-11)
1955    344F  015000    		ld	bc,80
1956    3452  09        		add	hl,bc
1957    3453  4D        		ld	c,l
1958    3454  44        		ld	b,h
1959    3455  97        		sub	a
1960    3456  320000    		ld	(c.r0),a
1961    3459  320100    		ld	(c.r0+1),a
1962    345C  0A        		ld	a,(bc)
1963    345D  320200    		ld	(c.r0+2),a
1964    3460  97        		sub	a
1965    3461  320300    		ld	(c.r0+3),a
1966    3464  210000    		ld	hl,c.r0
1967    3467  E5        		push	hl
1968    3468  DD6EF4    		ld	l,(ix-12)
1969    346B  DD66F5    		ld	h,(ix-11)
1970    346E  015100    		ld	bc,81
1971    3471  09        		add	hl,bc
1972    3472  4D        		ld	c,l
1973    3473  44        		ld	b,h
1974    3474  97        		sub	a
1975    3475  320000    		ld	(c.r1),a
1976    3478  320100    		ld	(c.r1+1),a
1977    347B  0A        		ld	a,(bc)
1978    347C  320200    		ld	(c.r1+2),a
1979    347F  97        		sub	a
1980    3480  320300    		ld	(c.r1+3),a
1981    3483  210000    		ld	hl,c.r1
1982    3486  E5        		push	hl
1983    3487  210800    		ld	hl,8
1984    348A  E5        		push	hl
1985    348B  CD0000    		call	c.llsh
1986    348E  CD0000    		call	c.ladd
1987    3491  DD6EF4    		ld	l,(ix-12)
1988    3494  DD66F5    		ld	h,(ix-11)
1989    3497  015200    		ld	bc,82
1990    349A  09        		add	hl,bc
1991    349B  4D        		ld	c,l
1992    349C  44        		ld	b,h
1993    349D  97        		sub	a
1994    349E  320000    		ld	(c.r1),a
1995    34A1  320100    		ld	(c.r1+1),a
1996    34A4  0A        		ld	a,(bc)
1997    34A5  320200    		ld	(c.r1+2),a
1998    34A8  97        		sub	a
1999    34A9  320300    		ld	(c.r1+3),a
2000    34AC  210000    		ld	hl,c.r1
2001    34AF  E5        		push	hl
2002    34B0  211000    		ld	hl,16
2003    34B3  E5        		push	hl
2004    34B4  CD0000    		call	c.llsh
2005    34B7  CD0000    		call	c.ladd
2006    34BA  DD6EF4    		ld	l,(ix-12)
2007    34BD  DD66F5    		ld	h,(ix-11)
2008    34C0  015300    		ld	bc,83
2009    34C3  09        		add	hl,bc
2010    34C4  4D        		ld	c,l
2011    34C5  44        		ld	b,h
2012    34C6  97        		sub	a
2013    34C7  320000    		ld	(c.r1),a
2014    34CA  320100    		ld	(c.r1+1),a
2015    34CD  0A        		ld	a,(bc)
2016    34CE  320200    		ld	(c.r1+2),a
2017    34D1  97        		sub	a
2018    34D2  320300    		ld	(c.r1+3),a
2019    34D5  210000    		ld	hl,c.r1
2020    34D8  E5        		push	hl
2021    34D9  211800    		ld	hl,24
2022    34DC  E5        		push	hl
2023    34DD  CD0000    		call	c.llsh
2024    34E0  CD0000    		call	c.ladd
2025    34E3  CD0000    		call	c.mvl
2026    34E6  F1        		pop	af
2027                    	; 1254          printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
2028    34E7  DD66F3    		ld	h,(ix-13)
2029    34EA  DD6EF2    		ld	l,(ix-14)
2030    34ED  E5        		push	hl
2031    34EE  DD66F1    		ld	h,(ix-15)
2032    34F1  DD6EF0    		ld	l,(ix-16)
2033    34F4  E5        		push	hl
2034    34F5  21DF32    		ld	hl,L5532
2035    34F8  CD0000    		call	_printf
2036    34FB  F1        		pop	af
2037    34FC  F1        		pop	af
2038                    	L1374:
2039                    	; 1255          } /* sdtestflg */
2040                    	; 1256      for (partno = 0; (partno < 16) && (partdsk < 16); partno++)
2041    34FD  DD36F600  		ld	(ix-10),0
2042    3501  DD36F700  		ld	(ix-9),0
2043                    	L1474:
2044    3505  DD7EF6    		ld	a,(ix-10)
2045    3508  D610      		sub	16
2046    350A  DD7EF7    		ld	a,(ix-9)
2047    350D  DE00      		sbc	a,0
2048    350F  302E      		jr	nc,L1574
2049    3511  3A0E00    		ld	a,(_partdsk)
2050    3514  D610      		sub	16
2051    3516  3A0F00    		ld	a,(_partdsk+1)
2052    3519  DE00      		sbc	a,0
2053    351B  F23F35    		jp	p,L1574
2054                    	; 1257          {
2055                    	; 1258          if (!prtgptent(partno))
2056    351E  DD6EF6    		ld	l,(ix-10)
2057    3521  DD66F7    		ld	h,(ix-9)
2058    3524  CDB02B    		call	_prtgptent
2059    3527  79        		ld	a,c
2060    3528  B0        		or	b
2061    3529  200A      		jr	nz,L1674
2062                    	; 1259              {
2063                    	; 1260              if (!sdtestflg)
2064    352B  2A0000    		ld	hl,(_sdtestflg)
2065    352E  7C        		ld	a,h
2066    352F  B5        		or	l
2067    3530  2003      		jr	nz,L1674
2068                    	; 1261                  {
2069                    	; 1262                  /* go through all entries if compiled as test program */
2070                    	; 1263                  return;
2071    3532  C30000    		jp	c.rets
2072                    	L1674:
2073    3535  DD34F6    		inc	(ix-10)
2074    3538  2003      		jr	nz,L651
2075    353A  DD34F7    		inc	(ix-9)
2076                    	L651:
2077    353D  18C6      		jr	L1474
2078                    	L1574:
2079                    	; 1264                  } /* sdtestflg */
2080                    	; 1265              }
2081                    	; 1266          }
2082                    	; 1267      if (sdtestflg)
2083    353F  2A0000    		ld	hl,(_sdtestflg)
2084    3542  7C        		ld	a,h
2085    3543  B5        		or	l
2086    3544  2806      		jr	z,L1205
2087                    	; 1268          {
2088                    	; 1269          printf("First 16 GPT entries scanned\n");
2089    3546  211E33    		ld	hl,L5632
2090    3549  CD0000    		call	_printf
2091                    	L1205:
2092                    	; 1270          } /* sdtestflg */
2093                    	; 1271      }
2094    354C  C30000    		jp	c.rets
2095                    	L5732:
2096    354F  4E        		.byte	78
2097    3550  6F        		.byte	111
2098    3551  74        		.byte	116
2099    3552  20        		.byte	32
2100    3553  75        		.byte	117
2101    3554  73        		.byte	115
2102    3555  65        		.byte	101
2103    3556  64        		.byte	100
2104    3557  20        		.byte	32
2105    3558  65        		.byte	101
2106    3559  6E        		.byte	110
2107    355A  74        		.byte	116
2108    355B  72        		.byte	114
2109    355C  79        		.byte	121
2110    355D  0A        		.byte	10
2111    355E  00        		.byte	0
2112                    	L5042:
2113    355F  42        		.byte	66
2114    3560  6F        		.byte	111
2115    3561  6F        		.byte	111
2116    3562  74        		.byte	116
2117    3563  20        		.byte	32
2118    3564  69        		.byte	105
2119    3565  6E        		.byte	110
2120    3566  64        		.byte	100
2121    3567  69        		.byte	105
2122    3568  63        		.byte	99
2123    3569  61        		.byte	97
2124    356A  74        		.byte	116
2125    356B  6F        		.byte	111
2126    356C  72        		.byte	114
2127    356D  3A        		.byte	58
2128    356E  20        		.byte	32
2129    356F  30        		.byte	48
2130    3570  78        		.byte	120
2131    3571  25        		.byte	37
2132    3572  30        		.byte	48
2133    3573  32        		.byte	50
2134    3574  78        		.byte	120
2135    3575  2C        		.byte	44
2136    3576  20        		.byte	32
2137    3577  53        		.byte	83
2138    3578  79        		.byte	121
2139    3579  73        		.byte	115
2140    357A  74        		.byte	116
2141    357B  65        		.byte	101
2142    357C  6D        		.byte	109
2143    357D  20        		.byte	32
2144    357E  49        		.byte	73
2145    357F  44        		.byte	68
2146    3580  3A        		.byte	58
2147    3581  20        		.byte	32
2148    3582  30        		.byte	48
2149    3583  78        		.byte	120
2150    3584  25        		.byte	37
2151    3585  30        		.byte	48
2152    3586  32        		.byte	50
2153    3587  78        		.byte	120
2154    3588  0A        		.byte	10
2155    3589  00        		.byte	0
2156                    	L5142:
2157    358A  20        		.byte	32
2158    358B  20        		.byte	32
2159    358C  45        		.byte	69
2160    358D  78        		.byte	120
2161    358E  74        		.byte	116
2162    358F  65        		.byte	101
2163    3590  6E        		.byte	110
2164    3591  64        		.byte	100
2165    3592  65        		.byte	101
2166    3593  64        		.byte	100
2167    3594  20        		.byte	32
2168    3595  70        		.byte	112
2169    3596  61        		.byte	97
2170    3597  72        		.byte	114
2171    3598  74        		.byte	116
2172    3599  69        		.byte	105
2173    359A  74        		.byte	116
2174    359B  69        		.byte	105
2175    359C  6F        		.byte	111
2176    359D  6E        		.byte	110
2177    359E  20        		.byte	32
2178    359F  65        		.byte	101
2179    35A0  6E        		.byte	110
2180    35A1  74        		.byte	116
2181    35A2  72        		.byte	114
2182    35A3  79        		.byte	121
2183    35A4  0A        		.byte	10
2184    35A5  00        		.byte	0
2185                    	L5242:
2186    35A6  20        		.byte	32
2187    35A7  20        		.byte	32
2188    35A8  55        		.byte	85
2189    35A9  6E        		.byte	110
2190    35AA  6F        		.byte	111
2191    35AB  66        		.byte	102
2192    35AC  66        		.byte	102
2193    35AD  69        		.byte	105
2194    35AE  63        		.byte	99
2195    35AF  69        		.byte	105
2196    35B0  61        		.byte	97
2197    35B1  6C        		.byte	108
2198    35B2  20        		.byte	32
2199    35B3  34        		.byte	52
2200    35B4  38        		.byte	56
2201    35B5  20        		.byte	32
2202    35B6  62        		.byte	98
2203    35B7  69        		.byte	105
2204    35B8  74        		.byte	116
2205    35B9  20        		.byte	32
2206    35BA  4C        		.byte	76
2207    35BB  42        		.byte	66
2208    35BC  41        		.byte	65
2209    35BD  20        		.byte	32
2210    35BE  50        		.byte	80
2211    35BF  72        		.byte	114
2212    35C0  6F        		.byte	111
2213    35C1  70        		.byte	112
2214    35C2  6F        		.byte	111
2215    35C3  73        		.byte	115
2216    35C4  65        		.byte	101
2217    35C5  64        		.byte	100
2218    35C6  20        		.byte	32
2219    35C7  4D        		.byte	77
2220    35C8  42        		.byte	66
2221    35C9  52        		.byte	82
2222    35CA  20        		.byte	32
2223    35CB  46        		.byte	70
2224    35CC  6F        		.byte	111
2225    35CD  72        		.byte	114
2226    35CE  6D        		.byte	109
2227    35CF  61        		.byte	97
2228    35D0  74        		.byte	116
2229    35D1  2C        		.byte	44
2230    35D2  20        		.byte	32
2231    35D3  6E        		.byte	110
2232    35D4  6F        		.byte	111
2233    35D5  20        		.byte	32
2234    35D6  43        		.byte	67
2235    35D7  48        		.byte	72
2236    35D8  53        		.byte	83
2237    35D9  0A        		.byte	10
2238    35DA  00        		.byte	0
2239                    	L5342:
2240    35DB  20        		.byte	32
2241    35DC  20        		.byte	32
2242    35DD  62        		.byte	98
2243    35DE  65        		.byte	101
2244    35DF  67        		.byte	103
2245    35E0  69        		.byte	105
2246    35E1  6E        		.byte	110
2247    35E2  20        		.byte	32
2248    35E3  43        		.byte	67
2249    35E4  48        		.byte	72
2250    35E5  53        		.byte	83
2251    35E6  3A        		.byte	58
2252    35E7  20        		.byte	32
2253    35E8  30        		.byte	48
2254    35E9  78        		.byte	120
2255    35EA  25        		.byte	37
2256    35EB  30        		.byte	48
2257    35EC  32        		.byte	50
2258    35ED  78        		.byte	120
2259    35EE  2D        		.byte	45
2260    35EF  30        		.byte	48
2261    35F0  78        		.byte	120
2262    35F1  25        		.byte	37
2263    35F2  30        		.byte	48
2264    35F3  32        		.byte	50
2265    35F4  78        		.byte	120
2266    35F5  2D        		.byte	45
2267    35F6  30        		.byte	48
2268    35F7  78        		.byte	120
2269    35F8  25        		.byte	37
2270    35F9  30        		.byte	48
2271    35FA  32        		.byte	50
2272    35FB  78        		.byte	120
2273    35FC  20        		.byte	32
2274    35FD  28        		.byte	40
2275    35FE  63        		.byte	99
2276    35FF  79        		.byte	121
2277    3600  6C        		.byte	108
2278    3601  3A        		.byte	58
2279    3602  20        		.byte	32
2280    3603  25        		.byte	37
2281    3604  64        		.byte	100
2282    3605  2C        		.byte	44
2283    3606  20        		.byte	32
2284    3607  68        		.byte	104
2285    3608  65        		.byte	101
2286    3609  61        		.byte	97
2287    360A  64        		.byte	100
2288    360B  3A        		.byte	58
2289    360C  20        		.byte	32
2290    360D  25        		.byte	37
2291    360E  64        		.byte	100
2292    360F  20        		.byte	32
2293    3610  73        		.byte	115
2294    3611  65        		.byte	101
2295    3612  63        		.byte	99
2296    3613  74        		.byte	116
2297    3614  6F        		.byte	111
2298    3615  72        		.byte	114
2299    3616  3A        		.byte	58
2300    3617  20        		.byte	32
2301    3618  25        		.byte	37
2302    3619  64        		.byte	100
2303    361A  29        		.byte	41
2304    361B  0A        		.byte	10
2305    361C  00        		.byte	0
2306                    	L5442:
2307    361D  20        		.byte	32
2308    361E  20        		.byte	32
2309    361F  65        		.byte	101
2310    3620  6E        		.byte	110
2311    3621  64        		.byte	100
2312    3622  20        		.byte	32
2313    3623  43        		.byte	67
2314    3624  48        		.byte	72
2315    3625  53        		.byte	83
2316    3626  20        		.byte	32
2317    3627  30        		.byte	48
2318    3628  78        		.byte	120
2319    3629  25        		.byte	37
2320    362A  30        		.byte	48
2321    362B  32        		.byte	50
2322    362C  78        		.byte	120
2323    362D  2D        		.byte	45
2324    362E  30        		.byte	48
2325    362F  78        		.byte	120
2326    3630  25        		.byte	37
2327    3631  30        		.byte	48
2328    3632  32        		.byte	50
2329    3633  78        		.byte	120
2330    3634  2D        		.byte	45
2331    3635  30        		.byte	48
2332    3636  78        		.byte	120
2333    3637  25        		.byte	37
2334    3638  30        		.byte	48
2335    3639  32        		.byte	50
2336    363A  78        		.byte	120
2337    363B  20        		.byte	32
2338    363C  28        		.byte	40
2339    363D  63        		.byte	99
2340    363E  79        		.byte	121
2341    363F  6C        		.byte	108
2342    3640  3A        		.byte	58
2343    3641  20        		.byte	32
2344    3642  25        		.byte	37
2345    3643  64        		.byte	100
2346    3644  2C        		.byte	44
2347    3645  20        		.byte	32
2348    3646  68        		.byte	104
2349    3647  65        		.byte	101
2350    3648  61        		.byte	97
2351    3649  64        		.byte	100
2352    364A  3A        		.byte	58
2353    364B  20        		.byte	32
2354    364C  25        		.byte	37
2355    364D  64        		.byte	100
2356    364E  20        		.byte	32
2357    364F  73        		.byte	115
2358    3650  65        		.byte	101
2359    3651  63        		.byte	99
2360    3652  74        		.byte	116
2361    3653  6F        		.byte	111
2362    3654  72        		.byte	114
2363    3655  3A        		.byte	58
2364    3656  20        		.byte	32
2365    3657  25        		.byte	37
2366    3658  64        		.byte	100
2367    3659  29        		.byte	41
2368    365A  0A        		.byte	10
2369    365B  00        		.byte	0
2370                    	L5542:
2371    365C  20        		.byte	32
2372    365D  20        		.byte	32
2373    365E  70        		.byte	112
2374    365F  61        		.byte	97
2375    3660  72        		.byte	114
2376    3661  74        		.byte	116
2377    3662  69        		.byte	105
2378    3663  74        		.byte	116
2379    3664  69        		.byte	105
2380    3665  6F        		.byte	111
2381    3666  6E        		.byte	110
2382    3667  20        		.byte	32
2383    3668  73        		.byte	115
2384    3669  74        		.byte	116
2385    366A  61        		.byte	97
2386    366B  72        		.byte	114
2387    366C  74        		.byte	116
2388    366D  20        		.byte	32
2389    366E  4C        		.byte	76
2390    366F  42        		.byte	66
2391    3670  41        		.byte	65
2392    3671  3A        		.byte	58
2393    3672  20        		.byte	32
2394    3673  25        		.byte	37
2395    3674  6C        		.byte	108
2396    3675  75        		.byte	117
2397    3676  20        		.byte	32
2398    3677  5B        		.byte	91
2399    3678  25        		.byte	37
2400    3679  30        		.byte	48
2401    367A  38        		.byte	56
2402    367B  6C        		.byte	108
2403    367C  78        		.byte	120
2404    367D  5D        		.byte	93
2405    367E  0A        		.byte	10
2406    367F  00        		.byte	0
2407                    	L5642:
2408    3680  20        		.byte	32
2409    3681  20        		.byte	32
2410    3682  70        		.byte	112
2411    3683  61        		.byte	97
2412    3684  72        		.byte	114
2413    3685  74        		.byte	116
2414    3686  69        		.byte	105
2415    3687  74        		.byte	116
2416    3688  69        		.byte	105
2417    3689  6F        		.byte	111
2418    368A  6E        		.byte	110
2419    368B  20        		.byte	32
2420    368C  73        		.byte	115
2421    368D  69        		.byte	105
2422    368E  7A        		.byte	122
2423    368F  65        		.byte	101
2424    3690  20        		.byte	32
2425    3691  4C        		.byte	76
2426    3692  42        		.byte	66
2427    3693  41        		.byte	65
2428    3694  3A        		.byte	58
2429    3695  20        		.byte	32
2430    3696  25        		.byte	37
2431    3697  6C        		.byte	108
2432    3698  75        		.byte	117
2433    3699  20        		.byte	32
2434    369A  5B        		.byte	91
2435    369B  25        		.byte	37
2436    369C  30        		.byte	48
2437    369D  38        		.byte	56
2438    369E  6C        		.byte	108
2439    369F  78        		.byte	120
2440    36A0  5D        		.byte	93
2441    36A1  2C        		.byte	44
2442    36A2  20        		.byte	32
2443    36A3  25        		.byte	37
2444    36A4  6C        		.byte	108
2445    36A5  75        		.byte	117
2446    36A6  20        		.byte	32
2447    36A7  4D        		.byte	77
2448    36A8  42        		.byte	66
2449    36A9  79        		.byte	121
2450    36AA  74        		.byte	116
2451    36AB  65        		.byte	101
2452    36AC  0A        		.byte	10
2453    36AD  00        		.byte	0
2454                    	L5742:
2455    36AE  47        		.byte	71
2456    36AF  54        		.byte	84
2457    36B0  50        		.byte	80
2458    36B1  20        		.byte	32
2459    36B2  70        		.byte	112
2460    36B3  61        		.byte	97
2461    36B4  72        		.byte	114
2462    36B5  74        		.byte	116
2463    36B6  69        		.byte	105
2464    36B7  74        		.byte	116
2465    36B8  69        		.byte	105
2466    36B9  6F        		.byte	111
2467    36BA  6E        		.byte	110
2468    36BB  73        		.byte	115
2469    36BC  0A        		.byte	10
2470    36BD  00        		.byte	0
2471                    	L261:
2472    36BE  00        		.byte	0
2473    36BF  00        		.byte	0
2474    36C0  00        		.byte	0
2475    36C1  00        		.byte	0
2476                    	L5052:
2477    36C2  20        		.byte	32
2478    36C3  20        		.byte	32
2479    36C4  63        		.byte	99
2480    36C5  61        		.byte	97
2481    36C6  6E        		.byte	110
2482    36C7  27        		.byte	39
2483    36C8  74        		.byte	116
2484    36C9  20        		.byte	32
2485    36CA  72        		.byte	114
2486    36CB  65        		.byte	101
2487    36CC  61        		.byte	97
2488    36CD  64        		.byte	100
2489    36CE  20        		.byte	32
2490    36CF  4D        		.byte	77
2491    36D0  42        		.byte	66
2492    36D1  52        		.byte	82
2493    36D2  20        		.byte	32
2494    36D3  6F        		.byte	111
2495    36D4  6E        		.byte	110
2496    36D5  20        		.byte	32
2497    36D6  73        		.byte	115
2498    36D7  65        		.byte	101
2499    36D8  63        		.byte	99
2500    36D9  74        		.byte	116
2501    36DA  6F        		.byte	111
2502    36DB  72        		.byte	114
2503    36DC  20        		.byte	32
2504    36DD  30        		.byte	48
2505    36DE  0A        		.byte	10
2506    36DF  00        		.byte	0
2507                    	; 1272  
2508                    	; 1273  /* Analyze and print MBR partition entry
2509                    	; 1274   * Returns:
2510                    	; 1275   *    -1 if errror - should not happen
2511                    	; 1276   *     0 if not used entry
2512                    	; 1277   *     1 if MBR entry
2513                    	; 1278   *     2 if EBR entry
2514                    	; 1279   *     3 if GTP entry
2515                    	; 1280   */
2516                    	; 1281  int sdmbrentry(unsigned char *partptr)
2517                    	; 1282      {
2518                    	_sdmbrentry:
2519    36E0  CD0000    		call	c.savs
2520    36E3  21EEFF    		ld	hl,65518
2521    36E6  39        		add	hl,sp
2522    36E7  F9        		ld	sp,hl
2523                    	; 1283      int index;
2524                    	; 1284      int parttype;
2525                    	; 1285      unsigned long lbastart;
2526                    	; 1286      unsigned long lbasize;
2527                    	; 1287  
2528                    	; 1288      parttype = PARTMBR;
2529    36E8  DD36F601  		ld	(ix-10),1
2530    36EC  DD36F700  		ld	(ix-9),0
2531                    	; 1289      if (!partptr[4])
2532    36F0  DD6E04    		ld	l,(ix+4)
2533    36F3  DD6605    		ld	h,(ix+5)
2534    36F6  23        		inc	hl
2535    36F7  23        		inc	hl
2536    36F8  23        		inc	hl
2537    36F9  23        		inc	hl
2538    36FA  7E        		ld	a,(hl)
2539    36FB  B7        		or	a
2540    36FC  2013      		jr	nz,L1305
2541                    	; 1290          {
2542                    	; 1291          if (sdtestflg)
2543    36FE  2A0000    		ld	hl,(_sdtestflg)
2544    3701  7C        		ld	a,h
2545    3702  B5        		or	l
2546    3703  2806      		jr	z,L1405
2547                    	; 1292              {
2548                    	; 1293              printf("Not used entry\n");
2549    3705  214F35    		ld	hl,L5732
2550    3708  CD0000    		call	_printf
2551                    	L1405:
2552                    	; 1294              } /* sdtestflg */
2553                    	; 1295          return (PARTZRO);
2554    370B  010000    		ld	bc,0
2555    370E  C30000    		jp	c.rets
2556                    	L1305:
2557                    	; 1296          }
2558                    	; 1297      if (sdtestflg)
2559    3711  2A0000    		ld	hl,(_sdtestflg)
2560    3714  7C        		ld	a,h
2561    3715  B5        		or	l
2562    3716  CA6E38    		jp	z,L1505
2563                    	; 1298          {
2564                    	; 1299          printf("Boot indicator: 0x%02x, System ID: 0x%02x\n",
2565                    	; 1300                 partptr[0], partptr[4]);
2566    3719  DD6E04    		ld	l,(ix+4)
2567    371C  DD6605    		ld	h,(ix+5)
2568    371F  23        		inc	hl
2569    3720  23        		inc	hl
2570    3721  23        		inc	hl
2571    3722  23        		inc	hl
2572    3723  4E        		ld	c,(hl)
2573    3724  97        		sub	a
2574    3725  47        		ld	b,a
2575    3726  C5        		push	bc
2576    3727  DD6E04    		ld	l,(ix+4)
2577    372A  DD6605    		ld	h,(ix+5)
2578    372D  4E        		ld	c,(hl)
2579    372E  97        		sub	a
2580    372F  47        		ld	b,a
2581    3730  C5        		push	bc
2582    3731  215F35    		ld	hl,L5042
2583    3734  CD0000    		call	_printf
2584    3737  F1        		pop	af
2585    3738  F1        		pop	af
2586                    	; 1301  
2587                    	; 1302          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
2588    3739  DD6E04    		ld	l,(ix+4)
2589    373C  DD6605    		ld	h,(ix+5)
2590    373F  23        		inc	hl
2591    3740  23        		inc	hl
2592    3741  23        		inc	hl
2593    3742  23        		inc	hl
2594    3743  7E        		ld	a,(hl)
2595    3744  FE05      		cp	5
2596    3746  280F      		jr	z,L1705
2597    3748  DD6E04    		ld	l,(ix+4)
2598    374B  DD6605    		ld	h,(ix+5)
2599    374E  23        		inc	hl
2600    374F  23        		inc	hl
2601    3750  23        		inc	hl
2602    3751  23        		inc	hl
2603    3752  7E        		ld	a,(hl)
2604    3753  FE0F      		cp	15
2605    3755  2006      		jr	nz,L1605
2606                    	L1705:
2607                    	; 1303              {
2608                    	; 1304              printf("  Extended partition entry\n");
2609    3757  218A35    		ld	hl,L5142
2610    375A  CD0000    		call	_printf
2611                    	L1605:
2612                    	; 1305              }
2613                    	; 1306          if (partptr[0] & 0x01)
2614    375D  DD6E04    		ld	l,(ix+4)
2615    3760  DD6605    		ld	h,(ix+5)
2616    3763  7E        		ld	a,(hl)
2617    3764  CB47      		bit	0,a
2618    3766  6F        		ld	l,a
2619    3767  2809      		jr	z,L1015
2620                    	; 1307              {
2621                    	; 1308              printf("  Unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
2622    3769  21A635    		ld	hl,L5242
2623    376C  CD0000    		call	_printf
2624                    	; 1309              /* this is however discussed
2625                    	; 1310                 https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
2626                    	; 1311              */
2627                    	; 1312              }
2628                    	; 1313          else
2629    376F  C36E38    		jp	L1505
2630                    	L1015:
2631                    	; 1314              {
2632                    	; 1315              printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
2633                    	; 1316                     partptr[1], partptr[2], partptr[3],
2634                    	; 1317                     ((partptr[2] & 0xc0) >> 2) + partptr[3],
2635                    	; 1318                     partptr[1],
2636                    	; 1319                     partptr[2] & 0x3f);
2637    3772  DD6E04    		ld	l,(ix+4)
2638    3775  DD6605    		ld	h,(ix+5)
2639    3778  23        		inc	hl
2640    3779  23        		inc	hl
2641    377A  6E        		ld	l,(hl)
2642    377B  97        		sub	a
2643    377C  67        		ld	h,a
2644    377D  7D        		ld	a,l
2645    377E  E63F      		and	63
2646    3780  6F        		ld	l,a
2647    3781  97        		sub	a
2648    3782  67        		ld	h,a
2649    3783  E5        		push	hl
2650    3784  DD6E04    		ld	l,(ix+4)
2651    3787  DD6605    		ld	h,(ix+5)
2652    378A  23        		inc	hl
2653    378B  4E        		ld	c,(hl)
2654    378C  97        		sub	a
2655    378D  47        		ld	b,a
2656    378E  C5        		push	bc
2657    378F  DD6E04    		ld	l,(ix+4)
2658    3792  DD6605    		ld	h,(ix+5)
2659    3795  23        		inc	hl
2660    3796  23        		inc	hl
2661    3797  6E        		ld	l,(hl)
2662    3798  97        		sub	a
2663    3799  67        		ld	h,a
2664    379A  7D        		ld	a,l
2665    379B  E6C0      		and	192
2666    379D  6F        		ld	l,a
2667    379E  97        		sub	a
2668    379F  67        		ld	h,a
2669    37A0  E5        		push	hl
2670    37A1  210200    		ld	hl,2
2671    37A4  E5        		push	hl
2672    37A5  CD0000    		call	c.irsh
2673    37A8  E1        		pop	hl
2674    37A9  E5        		push	hl
2675    37AA  DD6E04    		ld	l,(ix+4)
2676    37AD  DD6605    		ld	h,(ix+5)
2677    37B0  23        		inc	hl
2678    37B1  23        		inc	hl
2679    37B2  23        		inc	hl
2680    37B3  6E        		ld	l,(hl)
2681    37B4  97        		sub	a
2682    37B5  67        		ld	h,a
2683    37B6  E3        		ex	(sp),hl
2684    37B7  C1        		pop	bc
2685    37B8  09        		add	hl,bc
2686    37B9  E5        		push	hl
2687    37BA  DD6E04    		ld	l,(ix+4)
2688    37BD  DD6605    		ld	h,(ix+5)
2689    37C0  23        		inc	hl
2690    37C1  23        		inc	hl
2691    37C2  23        		inc	hl
2692    37C3  4E        		ld	c,(hl)
2693    37C4  97        		sub	a
2694    37C5  47        		ld	b,a
2695    37C6  C5        		push	bc
2696    37C7  DD6E04    		ld	l,(ix+4)
2697    37CA  DD6605    		ld	h,(ix+5)
2698    37CD  23        		inc	hl
2699    37CE  23        		inc	hl
2700    37CF  4E        		ld	c,(hl)
2701    37D0  97        		sub	a
2702    37D1  47        		ld	b,a
2703    37D2  C5        		push	bc
2704    37D3  DD6E04    		ld	l,(ix+4)
2705    37D6  DD6605    		ld	h,(ix+5)
2706    37D9  23        		inc	hl
2707    37DA  4E        		ld	c,(hl)
2708    37DB  97        		sub	a
2709    37DC  47        		ld	b,a
2710    37DD  C5        		push	bc
2711    37DE  21DB35    		ld	hl,L5342
2712    37E1  CD0000    		call	_printf
2713    37E4  210C00    		ld	hl,12
2714    37E7  39        		add	hl,sp
2715    37E8  F9        		ld	sp,hl
2716                    	; 1320              printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
2717                    	; 1321                     partptr[5], partptr[6], partptr[7],
2718                    	; 1322                     ((partptr[6] & 0xc0) >> 2) + partptr[7],
2719                    	; 1323                     partptr[5],
2720                    	; 1324                     partptr[6] & 0x3f);
2721    37E9  DD6E04    		ld	l,(ix+4)
2722    37EC  DD6605    		ld	h,(ix+5)
2723    37EF  010600    		ld	bc,6
2724    37F2  09        		add	hl,bc
2725    37F3  6E        		ld	l,(hl)
2726    37F4  97        		sub	a
2727    37F5  67        		ld	h,a
2728    37F6  7D        		ld	a,l
2729    37F7  E63F      		and	63
2730    37F9  6F        		ld	l,a
2731    37FA  97        		sub	a
2732    37FB  67        		ld	h,a
2733    37FC  E5        		push	hl
2734    37FD  DD6E04    		ld	l,(ix+4)
2735    3800  DD6605    		ld	h,(ix+5)
2736    3803  010500    		ld	bc,5
2737    3806  09        		add	hl,bc
2738    3807  4E        		ld	c,(hl)
2739    3808  97        		sub	a
2740    3809  47        		ld	b,a
2741    380A  C5        		push	bc
2742    380B  DD6E04    		ld	l,(ix+4)
2743    380E  DD6605    		ld	h,(ix+5)
2744    3811  010600    		ld	bc,6
2745    3814  09        		add	hl,bc
2746    3815  6E        		ld	l,(hl)
2747    3816  97        		sub	a
2748    3817  67        		ld	h,a
2749    3818  7D        		ld	a,l
2750    3819  E6C0      		and	192
2751    381B  6F        		ld	l,a
2752    381C  97        		sub	a
2753    381D  67        		ld	h,a
2754    381E  E5        		push	hl
2755    381F  210200    		ld	hl,2
2756    3822  E5        		push	hl
2757    3823  CD0000    		call	c.irsh
2758    3826  E1        		pop	hl
2759    3827  E5        		push	hl
2760    3828  DD6E04    		ld	l,(ix+4)
2761    382B  DD6605    		ld	h,(ix+5)
2762    382E  010700    		ld	bc,7
2763    3831  09        		add	hl,bc
2764    3832  6E        		ld	l,(hl)
2765    3833  97        		sub	a
2766    3834  67        		ld	h,a
2767    3835  E3        		ex	(sp),hl
2768    3836  C1        		pop	bc
2769    3837  09        		add	hl,bc
2770    3838  E5        		push	hl
2771    3839  DD6E04    		ld	l,(ix+4)
2772    383C  DD6605    		ld	h,(ix+5)
2773    383F  010700    		ld	bc,7
2774    3842  09        		add	hl,bc
2775    3843  4E        		ld	c,(hl)
2776    3844  97        		sub	a
2777    3845  47        		ld	b,a
2778    3846  C5        		push	bc
2779    3847  DD6E04    		ld	l,(ix+4)
2780    384A  DD6605    		ld	h,(ix+5)
2781    384D  010600    		ld	bc,6
2782    3850  09        		add	hl,bc
2783    3851  4E        		ld	c,(hl)
2784    3852  97        		sub	a
2785    3853  47        		ld	b,a
2786    3854  C5        		push	bc
2787    3855  DD6E04    		ld	l,(ix+4)
2788    3858  DD6605    		ld	h,(ix+5)
2789    385B  010500    		ld	bc,5
2790    385E  09        		add	hl,bc
2791    385F  4E        		ld	c,(hl)
2792    3860  97        		sub	a
2793    3861  47        		ld	b,a
2794    3862  C5        		push	bc
2795    3863  211D36    		ld	hl,L5442
2796    3866  CD0000    		call	_printf
2797    3869  210C00    		ld	hl,12
2798    386C  39        		add	hl,sp
2799    386D  F9        		ld	sp,hl
2800                    	L1505:
2801                    	; 1325              }
2802                    	; 1326          } /* sdtestflg */
2803                    	; 1327      /* not showing high 16 bits if 48 bit LBA */
2804                    	; 1328      lbastart = (unsigned long)partptr[8] +
2805                    	; 1329                 ((unsigned long)partptr[9] << 8) +
2806                    	; 1330                 ((unsigned long)partptr[10] << 16) +
2807                    	; 1331                 ((unsigned long)partptr[11] << 24);
2808    386E  DDE5      		push	ix
2809    3870  C1        		pop	bc
2810    3871  21F2FF    		ld	hl,65522
2811    3874  09        		add	hl,bc
2812    3875  E5        		push	hl
2813    3876  DD6E04    		ld	l,(ix+4)
2814    3879  DD6605    		ld	h,(ix+5)
2815    387C  010800    		ld	bc,8
2816    387F  09        		add	hl,bc
2817    3880  4D        		ld	c,l
2818    3881  44        		ld	b,h
2819    3882  97        		sub	a
2820    3883  320000    		ld	(c.r0),a
2821    3886  320100    		ld	(c.r0+1),a
2822    3889  0A        		ld	a,(bc)
2823    388A  320200    		ld	(c.r0+2),a
2824    388D  97        		sub	a
2825    388E  320300    		ld	(c.r0+3),a
2826    3891  210000    		ld	hl,c.r0
2827    3894  E5        		push	hl
2828    3895  DD6E04    		ld	l,(ix+4)
2829    3898  DD6605    		ld	h,(ix+5)
2830    389B  010900    		ld	bc,9
2831    389E  09        		add	hl,bc
2832    389F  4D        		ld	c,l
2833    38A0  44        		ld	b,h
2834    38A1  97        		sub	a
2835    38A2  320000    		ld	(c.r1),a
2836    38A5  320100    		ld	(c.r1+1),a
2837    38A8  0A        		ld	a,(bc)
2838    38A9  320200    		ld	(c.r1+2),a
2839    38AC  97        		sub	a
2840    38AD  320300    		ld	(c.r1+3),a
2841    38B0  210000    		ld	hl,c.r1
2842    38B3  E5        		push	hl
2843    38B4  210800    		ld	hl,8
2844    38B7  E5        		push	hl
2845    38B8  CD0000    		call	c.llsh
2846    38BB  CD0000    		call	c.ladd
2847    38BE  DD6E04    		ld	l,(ix+4)
2848    38C1  DD6605    		ld	h,(ix+5)
2849    38C4  010A00    		ld	bc,10
2850    38C7  09        		add	hl,bc
2851    38C8  4D        		ld	c,l
2852    38C9  44        		ld	b,h
2853    38CA  97        		sub	a
2854    38CB  320000    		ld	(c.r1),a
2855    38CE  320100    		ld	(c.r1+1),a
2856    38D1  0A        		ld	a,(bc)
2857    38D2  320200    		ld	(c.r1+2),a
2858    38D5  97        		sub	a
2859    38D6  320300    		ld	(c.r1+3),a
2860    38D9  210000    		ld	hl,c.r1
2861    38DC  E5        		push	hl
2862    38DD  211000    		ld	hl,16
2863    38E0  E5        		push	hl
2864    38E1  CD0000    		call	c.llsh
2865    38E4  CD0000    		call	c.ladd
2866    38E7  DD6E04    		ld	l,(ix+4)
2867    38EA  DD6605    		ld	h,(ix+5)
2868    38ED  010B00    		ld	bc,11
2869    38F0  09        		add	hl,bc
2870    38F1  4D        		ld	c,l
2871    38F2  44        		ld	b,h
2872    38F3  97        		sub	a
2873    38F4  320000    		ld	(c.r1),a
2874    38F7  320100    		ld	(c.r1+1),a
2875    38FA  0A        		ld	a,(bc)
2876    38FB  320200    		ld	(c.r1+2),a
2877    38FE  97        		sub	a
2878    38FF  320300    		ld	(c.r1+3),a
2879    3902  210000    		ld	hl,c.r1
2880    3905  E5        		push	hl
2881    3906  211800    		ld	hl,24
2882    3909  E5        		push	hl
2883    390A  CD0000    		call	c.llsh
2884    390D  CD0000    		call	c.ladd
2885    3910  CD0000    		call	c.mvl
2886    3913  F1        		pop	af
2887                    	; 1332      lbasize = (unsigned long)partptr[12] +
2888                    	; 1333                ((unsigned long)partptr[13] << 8) +
2889                    	; 1334                ((unsigned long)partptr[14] << 16) +
2890                    	; 1335                ((unsigned long)partptr[15] << 24);
2891    3914  DDE5      		push	ix
2892    3916  C1        		pop	bc
2893    3917  21EEFF    		ld	hl,65518
2894    391A  09        		add	hl,bc
2895    391B  E5        		push	hl
2896    391C  DD6E04    		ld	l,(ix+4)
2897    391F  DD6605    		ld	h,(ix+5)
2898    3922  010C00    		ld	bc,12
2899    3925  09        		add	hl,bc
2900    3926  4D        		ld	c,l
2901    3927  44        		ld	b,h
2902    3928  97        		sub	a
2903    3929  320000    		ld	(c.r0),a
2904    392C  320100    		ld	(c.r0+1),a
2905    392F  0A        		ld	a,(bc)
2906    3930  320200    		ld	(c.r0+2),a
2907    3933  97        		sub	a
2908    3934  320300    		ld	(c.r0+3),a
2909    3937  210000    		ld	hl,c.r0
2910    393A  E5        		push	hl
2911    393B  DD6E04    		ld	l,(ix+4)
2912    393E  DD6605    		ld	h,(ix+5)
2913    3941  010D00    		ld	bc,13
2914    3944  09        		add	hl,bc
2915    3945  4D        		ld	c,l
2916    3946  44        		ld	b,h
2917    3947  97        		sub	a
2918    3948  320000    		ld	(c.r1),a
2919    394B  320100    		ld	(c.r1+1),a
2920    394E  0A        		ld	a,(bc)
2921    394F  320200    		ld	(c.r1+2),a
2922    3952  97        		sub	a
2923    3953  320300    		ld	(c.r1+3),a
2924    3956  210000    		ld	hl,c.r1
2925    3959  E5        		push	hl
2926    395A  210800    		ld	hl,8
2927    395D  E5        		push	hl
2928    395E  CD0000    		call	c.llsh
2929    3961  CD0000    		call	c.ladd
2930    3964  DD6E04    		ld	l,(ix+4)
2931    3967  DD6605    		ld	h,(ix+5)
2932    396A  010E00    		ld	bc,14
2933    396D  09        		add	hl,bc
2934    396E  4D        		ld	c,l
2935    396F  44        		ld	b,h
2936    3970  97        		sub	a
2937    3971  320000    		ld	(c.r1),a
2938    3974  320100    		ld	(c.r1+1),a
2939    3977  0A        		ld	a,(bc)
2940    3978  320200    		ld	(c.r1+2),a
2941    397B  97        		sub	a
2942    397C  320300    		ld	(c.r1+3),a
2943    397F  210000    		ld	hl,c.r1
2944    3982  E5        		push	hl
2945    3983  211000    		ld	hl,16
2946    3986  E5        		push	hl
2947    3987  CD0000    		call	c.llsh
2948    398A  CD0000    		call	c.ladd
2949    398D  DD6E04    		ld	l,(ix+4)
2950    3990  DD6605    		ld	h,(ix+5)
2951    3993  010F00    		ld	bc,15
2952    3996  09        		add	hl,bc
2953    3997  4D        		ld	c,l
2954    3998  44        		ld	b,h
2955    3999  97        		sub	a
2956    399A  320000    		ld	(c.r1),a
2957    399D  320100    		ld	(c.r1+1),a
2958    39A0  0A        		ld	a,(bc)
2959    39A1  320200    		ld	(c.r1+2),a
2960    39A4  97        		sub	a
2961    39A5  320300    		ld	(c.r1+3),a
2962    39A8  210000    		ld	hl,c.r1
2963    39AB  E5        		push	hl
2964    39AC  211800    		ld	hl,24
2965    39AF  E5        		push	hl
2966    39B0  CD0000    		call	c.llsh
2967    39B3  CD0000    		call	c.ladd
2968    39B6  CD0000    		call	c.mvl
2969    39B9  F1        		pop	af
2970                    	; 1336  
2971                    	; 1337      if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
2972    39BA  DD6E04    		ld	l,(ix+4)
2973    39BD  DD6605    		ld	h,(ix+5)
2974    39C0  23        		inc	hl
2975    39C1  23        		inc	hl
2976    39C2  23        		inc	hl
2977    39C3  23        		inc	hl
2978    39C4  7E        		ld	a,(hl)
2979    39C5  FEEE      		cp	238
2980    39C7  CA353C    		jp	z,L1215
2981                    	; 1338          {
2982                    	; 1339          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
2983    39CA  DD6E04    		ld	l,(ix+4)
2984    39CD  DD6605    		ld	h,(ix+5)
2985    39D0  23        		inc	hl
2986    39D1  23        		inc	hl
2987    39D2  23        		inc	hl
2988    39D3  23        		inc	hl
2989    39D4  7E        		ld	a,(hl)
2990    39D5  FE05      		cp	5
2991    39D7  2810      		jr	z,L1415
2992    39D9  DD6E04    		ld	l,(ix+4)
2993    39DC  DD6605    		ld	h,(ix+5)
2994    39DF  23        		inc	hl
2995    39E0  23        		inc	hl
2996    39E1  23        		inc	hl
2997    39E2  23        		inc	hl
2998    39E3  7E        		ld	a,(hl)
2999    39E4  FE0F      		cp	15
3000    39E6  C2153B    		jp	nz,L1315
3001                    	L1415:
3002                    	; 1340              {
3003                    	; 1341              parttype = PARTEBR;
3004    39E9  DD36F602  		ld	(ix-10),2
3005    39ED  DD36F700  		ld	(ix-9),0
3006                    	; 1342              if (curblkno == 0) /* points to EBR in the MBR */
3007    39F1  210200    		ld	hl,_curblkno
3008    39F4  7E        		ld	a,(hl)
3009    39F5  23        		inc	hl
3010    39F6  B6        		or	(hl)
3011    39F7  23        		inc	hl
3012    39F8  B6        		or	(hl)
3013    39F9  23        		inc	hl
3014    39FA  B6        		or	(hl)
3015    39FB  C2F53A    		jp	nz,L1515
3016                    	; 1343                  {
3017                    	; 1344                  ebrnext = 0;
3018    39FE  97        		sub	a
3019    39FF  321200    		ld	(_ebrnext),a
3020    3A02  321300    		ld	(_ebrnext+1),a
3021    3A05  321400    		ld	(_ebrnext+2),a
3022    3A08  321500    		ld	(_ebrnext+3),a
3023                    	; 1345                  dskmap[partdsk].partype = EBRCONT;
3024    3A0B  2A0E00    		ld	hl,(_partdsk)
3025    3A0E  E5        		push	hl
3026    3A0F  212000    		ld	hl,32
3027    3A12  E5        		push	hl
3028    3A13  CD0000    		call	c.imul
3029    3A16  E1        		pop	hl
3030    3A17  015002    		ld	bc,_dskmap
3031    3A1A  09        		add	hl,bc
3032    3A1B  3614      		ld	(hl),20
3033                    	; 1346                  dskmap[partdsk].dskletter = 'A' + partdsk;
3034    3A1D  2A0E00    		ld	hl,(_partdsk)
3035    3A20  E5        		push	hl
3036    3A21  212000    		ld	hl,32
3037    3A24  E5        		push	hl
3038    3A25  CD0000    		call	c.imul
3039    3A28  E1        		pop	hl
3040    3A29  015102    		ld	bc,_dskmap+1
3041    3A2C  09        		add	hl,bc
3042    3A2D  3A0E00    		ld	a,(_partdsk)
3043    3A30  C641      		add	a,65
3044    3A32  4F        		ld	c,a
3045    3A33  71        		ld	(hl),c
3046                    	; 1347                  dskmap[partdsk].dskstart = lbastart;
3047    3A34  2A0E00    		ld	hl,(_partdsk)
3048    3A37  E5        		push	hl
3049    3A38  212000    		ld	hl,32
3050    3A3B  E5        		push	hl
3051    3A3C  CD0000    		call	c.imul
3052    3A3F  E1        		pop	hl
3053    3A40  015402    		ld	bc,_dskmap+4
3054    3A43  09        		add	hl,bc
3055    3A44  E5        		push	hl
3056    3A45  DDE5      		push	ix
3057    3A47  C1        		pop	bc
3058    3A48  21F2FF    		ld	hl,65522
3059    3A4B  09        		add	hl,bc
3060    3A4C  E5        		push	hl
3061    3A4D  CD0000    		call	c.mvl
3062    3A50  F1        		pop	af
3063                    	; 1348                  dskmap[partdsk].dskend = lbastart + lbasize - 1;
3064    3A51  2A0E00    		ld	hl,(_partdsk)
3065    3A54  E5        		push	hl
3066    3A55  212000    		ld	hl,32
3067    3A58  E5        		push	hl
3068    3A59  CD0000    		call	c.imul
3069    3A5C  E1        		pop	hl
3070    3A5D  015802    		ld	bc,_dskmap+8
3071    3A60  09        		add	hl,bc
3072    3A61  E5        		push	hl
3073    3A62  DDE5      		push	ix
3074    3A64  C1        		pop	bc
3075    3A65  21F2FF    		ld	hl,65522
3076    3A68  09        		add	hl,bc
3077    3A69  CD0000    		call	c.0mvf
3078    3A6C  210000    		ld	hl,c.r0
3079    3A6F  E5        		push	hl
3080    3A70  DDE5      		push	ix
3081    3A72  C1        		pop	bc
3082    3A73  21EEFF    		ld	hl,65518
3083    3A76  09        		add	hl,bc
3084    3A77  E5        		push	hl
3085    3A78  CD0000    		call	c.ladd
3086    3A7B  3EFF      		ld	a,255
3087    3A7D  320200    		ld	(c.r1+2),a
3088    3A80  87        		add	a,a
3089    3A81  9F        		sbc	a,a
3090    3A82  320300    		ld	(c.r1+3),a
3091    3A85  320100    		ld	(c.r1+1),a
3092    3A88  320000    		ld	(c.r1),a
3093    3A8B  210000    		ld	hl,c.r1
3094    3A8E  E5        		push	hl
3095    3A8F  CD0000    		call	c.ladd
3096    3A92  CD0000    		call	c.mvl
3097    3A95  F1        		pop	af
3098                    	; 1349                  dskmap[partdsk].dsksize = lbasize;
3099    3A96  2A0E00    		ld	hl,(_partdsk)
3100    3A99  E5        		push	hl
3101    3A9A  212000    		ld	hl,32
3102    3A9D  E5        		push	hl
3103    3A9E  CD0000    		call	c.imul
3104    3AA1  E1        		pop	hl
3105    3AA2  015C02    		ld	bc,_dskmap+12
3106    3AA5  09        		add	hl,bc
3107    3AA6  E5        		push	hl
3108    3AA7  DDE5      		push	ix
3109    3AA9  C1        		pop	bc
3110    3AAA  21EEFF    		ld	hl,65518
3111    3AAD  09        		add	hl,bc
3112    3AAE  E5        		push	hl
3113    3AAF  CD0000    		call	c.mvl
3114    3AB2  F1        		pop	af
3115                    	; 1350                  dskmap[partdsk].dsktype[0] = partptr[4];
3116    3AB3  2A0E00    		ld	hl,(_partdsk)
3117    3AB6  E5        		push	hl
3118    3AB7  212000    		ld	hl,32
3119    3ABA  E5        		push	hl
3120    3ABB  CD0000    		call	c.imul
3121    3ABE  E1        		pop	hl
3122    3ABF  016002    		ld	bc,_dskmap+16
3123    3AC2  09        		add	hl,bc
3124    3AC3  DD4E04    		ld	c,(ix+4)
3125    3AC6  DD4605    		ld	b,(ix+5)
3126    3AC9  03        		inc	bc
3127    3ACA  03        		inc	bc
3128    3ACB  03        		inc	bc
3129    3ACC  03        		inc	bc
3130    3ACD  0A        		ld	a,(bc)
3131    3ACE  77        		ld	(hl),a
3132                    	; 1351                  partdsk++;
3133    3ACF  2A0E00    		ld	hl,(_partdsk)
3134    3AD2  23        		inc	hl
3135    3AD3  220E00    		ld	(_partdsk),hl
3136                    	; 1352                  ebrrecs[ebrrecidx++] = lbastart; /* save to handle later */
3137    3AD6  2A1600    		ld	hl,(_ebrrecidx)
3138    3AD9  E5        		push	hl
3139    3ADA  23        		inc	hl
3140    3ADB  221600    		ld	(_ebrrecidx),hl
3141    3ADE  E1        		pop	hl
3142    3ADF  29        		add	hl,hl
3143    3AE0  29        		add	hl,hl
3144    3AE1  011800    		ld	bc,_ebrrecs
3145    3AE4  09        		add	hl,bc
3146    3AE5  E5        		push	hl
3147    3AE6  DDE5      		push	ix
3148    3AE8  C1        		pop	bc
3149    3AE9  21F2FF    		ld	hl,65522
3150    3AEC  09        		add	hl,bc
3151    3AED  E5        		push	hl
3152    3AEE  CD0000    		call	c.mvl
3153    3AF1  F1        		pop	af
3154                    	; 1353                  }
3155                    	; 1354              else
3156    3AF2  C3353C    		jp	L1215
3157                    	L1515:
3158                    	; 1355                  {
3159                    	; 1356                  ebrnext = curblkno + lbastart;
3160    3AF5  211200    		ld	hl,_ebrnext
3161    3AF8  E5        		push	hl
3162    3AF9  210200    		ld	hl,_curblkno
3163    3AFC  CD0000    		call	c.0mvf
3164    3AFF  210000    		ld	hl,c.r0
3165    3B02  E5        		push	hl
3166    3B03  DDE5      		push	ix
3167    3B05  C1        		pop	bc
3168    3B06  21F2FF    		ld	hl,65522
3169    3B09  09        		add	hl,bc
3170    3B0A  E5        		push	hl
3171    3B0B  CD0000    		call	c.ladd
3172    3B0E  CD0000    		call	c.mvl
3173    3B11  F1        		pop	af
3174    3B12  C3353C    		jp	L1215
3175                    	L1315:
3176                    	; 1357                  }
3177                    	; 1358              }
3178                    	; 1359          else
3179                    	; 1360              {
3180                    	; 1361              if (partptr[0] & 0x80)
3181    3B15  DD6E04    		ld	l,(ix+4)
3182    3B18  DD6605    		ld	h,(ix+5)
3183    3B1B  7E        		ld	a,(hl)
3184    3B1C  CB7F      		bit	7,a
3185    3B1E  6F        		ld	l,a
3186    3B1F  2815      		jr	z,L1025
3187                    	; 1362                  dskmap[partdsk].bootable = YES;
3188    3B21  2A0E00    		ld	hl,(_partdsk)
3189    3B24  E5        		push	hl
3190    3B25  212000    		ld	hl,32
3191    3B28  E5        		push	hl
3192    3B29  CD0000    		call	c.imul
3193    3B2C  E1        		pop	hl
3194    3B2D  015202    		ld	bc,_dskmap+2
3195    3B30  09        		add	hl,bc
3196    3B31  3601      		ld	(hl),1
3197    3B33  23        		inc	hl
3198    3B34  3600      		ld	(hl),0
3199                    	L1025:
3200                    	; 1363              if (curblkno == 0)
3201    3B36  210200    		ld	hl,_curblkno
3202    3B39  7E        		ld	a,(hl)
3203    3B3A  23        		inc	hl
3204    3B3B  B6        		or	(hl)
3205    3B3C  23        		inc	hl
3206    3B3D  B6        		or	(hl)
3207    3B3E  23        		inc	hl
3208    3B3F  B6        		or	(hl)
3209    3B40  2014      		jr	nz,L1125
3210                    	; 1364                  dskmap[partdsk].partype = PARTMBR;
3211    3B42  2A0E00    		ld	hl,(_partdsk)
3212    3B45  E5        		push	hl
3213    3B46  212000    		ld	hl,32
3214    3B49  E5        		push	hl
3215    3B4A  CD0000    		call	c.imul
3216    3B4D  E1        		pop	hl
3217    3B4E  015002    		ld	bc,_dskmap
3218    3B51  09        		add	hl,bc
3219    3B52  3601      		ld	(hl),1
3220                    	; 1365              else
3221    3B54  1812      		jr	L1225
3222                    	L1125:
3223                    	; 1366                  dskmap[partdsk].partype = PARTEBR;
3224    3B56  2A0E00    		ld	hl,(_partdsk)
3225    3B59  E5        		push	hl
3226    3B5A  212000    		ld	hl,32
3227    3B5D  E5        		push	hl
3228    3B5E  CD0000    		call	c.imul
3229    3B61  E1        		pop	hl
3230    3B62  015002    		ld	bc,_dskmap
3231    3B65  09        		add	hl,bc
3232    3B66  3602      		ld	(hl),2
3233                    	L1225:
3234                    	; 1367              dskmap[partdsk].dskletter = 'A' + partdsk;
3235    3B68  2A0E00    		ld	hl,(_partdsk)
3236    3B6B  E5        		push	hl
3237    3B6C  212000    		ld	hl,32
3238    3B6F  E5        		push	hl
3239    3B70  CD0000    		call	c.imul
3240    3B73  E1        		pop	hl
3241    3B74  015102    		ld	bc,_dskmap+1
3242    3B77  09        		add	hl,bc
3243    3B78  3A0E00    		ld	a,(_partdsk)
3244    3B7B  C641      		add	a,65
3245    3B7D  4F        		ld	c,a
3246    3B7E  71        		ld	(hl),c
3247                    	; 1368              dskmap[partdsk].dskstart = curblkno + lbastart;
3248    3B7F  2A0E00    		ld	hl,(_partdsk)
3249    3B82  E5        		push	hl
3250    3B83  212000    		ld	hl,32
3251    3B86  E5        		push	hl
3252    3B87  CD0000    		call	c.imul
3253    3B8A  E1        		pop	hl
3254    3B8B  015402    		ld	bc,_dskmap+4
3255    3B8E  09        		add	hl,bc
3256    3B8F  E5        		push	hl
3257    3B90  210200    		ld	hl,_curblkno
3258    3B93  CD0000    		call	c.0mvf
3259    3B96  210000    		ld	hl,c.r0
3260    3B99  E5        		push	hl
3261    3B9A  DDE5      		push	ix
3262    3B9C  C1        		pop	bc
3263    3B9D  21F2FF    		ld	hl,65522
3264    3BA0  09        		add	hl,bc
3265    3BA1  E5        		push	hl
3266    3BA2  CD0000    		call	c.ladd
3267    3BA5  CD0000    		call	c.mvl
3268    3BA8  F1        		pop	af
3269                    	; 1369              dskmap[partdsk].dskend = curblkno + lbastart + lbasize - 1;
3270    3BA9  2A0E00    		ld	hl,(_partdsk)
3271    3BAC  E5        		push	hl
3272    3BAD  212000    		ld	hl,32
3273    3BB0  E5        		push	hl
3274    3BB1  CD0000    		call	c.imul
3275    3BB4  E1        		pop	hl
3276    3BB5  015802    		ld	bc,_dskmap+8
3277    3BB8  09        		add	hl,bc
3278    3BB9  E5        		push	hl
3279    3BBA  210200    		ld	hl,_curblkno
3280    3BBD  CD0000    		call	c.0mvf
3281    3BC0  210000    		ld	hl,c.r0
3282    3BC3  E5        		push	hl
3283    3BC4  DDE5      		push	ix
3284    3BC6  C1        		pop	bc
3285    3BC7  21F2FF    		ld	hl,65522
3286    3BCA  09        		add	hl,bc
3287    3BCB  E5        		push	hl
3288    3BCC  CD0000    		call	c.ladd
3289    3BCF  DDE5      		push	ix
3290    3BD1  C1        		pop	bc
3291    3BD2  21EEFF    		ld	hl,65518
3292    3BD5  09        		add	hl,bc
3293    3BD6  E5        		push	hl
3294    3BD7  CD0000    		call	c.ladd
3295    3BDA  3EFF      		ld	a,255
3296    3BDC  320200    		ld	(c.r1+2),a
3297    3BDF  87        		add	a,a
3298    3BE0  9F        		sbc	a,a
3299    3BE1  320300    		ld	(c.r1+3),a
3300    3BE4  320100    		ld	(c.r1+1),a
3301    3BE7  320000    		ld	(c.r1),a
3302    3BEA  210000    		ld	hl,c.r1
3303    3BED  E5        		push	hl
3304    3BEE  CD0000    		call	c.ladd
3305    3BF1  CD0000    		call	c.mvl
3306    3BF4  F1        		pop	af
3307                    	; 1370              dskmap[partdsk].dsksize = lbasize;
3308    3BF5  2A0E00    		ld	hl,(_partdsk)
3309    3BF8  E5        		push	hl
3310    3BF9  212000    		ld	hl,32
3311    3BFC  E5        		push	hl
3312    3BFD  CD0000    		call	c.imul
3313    3C00  E1        		pop	hl
3314    3C01  015C02    		ld	bc,_dskmap+12
3315    3C04  09        		add	hl,bc
3316    3C05  E5        		push	hl
3317    3C06  DDE5      		push	ix
3318    3C08  C1        		pop	bc
3319    3C09  21EEFF    		ld	hl,65518
3320    3C0C  09        		add	hl,bc
3321    3C0D  E5        		push	hl
3322    3C0E  CD0000    		call	c.mvl
3323    3C11  F1        		pop	af
3324                    	; 1371              dskmap[partdsk].dsktype[0] = partptr[4];
3325    3C12  2A0E00    		ld	hl,(_partdsk)
3326    3C15  E5        		push	hl
3327    3C16  212000    		ld	hl,32
3328    3C19  E5        		push	hl
3329    3C1A  CD0000    		call	c.imul
3330    3C1D  E1        		pop	hl
3331    3C1E  016002    		ld	bc,_dskmap+16
3332    3C21  09        		add	hl,bc
3333    3C22  DD4E04    		ld	c,(ix+4)
3334    3C25  DD4605    		ld	b,(ix+5)
3335    3C28  03        		inc	bc
3336    3C29  03        		inc	bc
3337    3C2A  03        		inc	bc
3338    3C2B  03        		inc	bc
3339    3C2C  0A        		ld	a,(bc)
3340    3C2D  77        		ld	(hl),a
3341                    	; 1372              partdsk++;
3342    3C2E  2A0E00    		ld	hl,(_partdsk)
3343    3C31  23        		inc	hl
3344    3C32  220E00    		ld	(_partdsk),hl
3345                    	L1215:
3346                    	; 1373              }
3347                    	; 1374          }
3348                    	; 1375  
3349                    	; 1376      if (sdtestflg)
3350    3C35  2A0000    		ld	hl,(_sdtestflg)
3351    3C38  7C        		ld	a,h
3352    3C39  B5        		or	l
3353    3C3A  CAD73C    		jp	z,L1325
3354                    	; 1377          {
3355                    	; 1378          printf("  partition start LBA: %lu [%08lx]\n",
3356                    	; 1379                 curblkno + lbastart, curblkno + lbastart);
3357    3C3D  210200    		ld	hl,_curblkno
3358    3C40  CD0000    		call	c.0mvf
3359    3C43  210000    		ld	hl,c.r0
3360    3C46  E5        		push	hl
3361    3C47  DDE5      		push	ix
3362    3C49  C1        		pop	bc
3363    3C4A  21F2FF    		ld	hl,65522
3364    3C4D  09        		add	hl,bc
3365    3C4E  E5        		push	hl
3366    3C4F  CD0000    		call	c.ladd
3367    3C52  E1        		pop	hl
3368    3C53  23        		inc	hl
3369    3C54  23        		inc	hl
3370    3C55  4E        		ld	c,(hl)
3371    3C56  23        		inc	hl
3372    3C57  46        		ld	b,(hl)
3373    3C58  C5        		push	bc
3374    3C59  2B        		dec	hl
3375    3C5A  2B        		dec	hl
3376    3C5B  2B        		dec	hl
3377    3C5C  4E        		ld	c,(hl)
3378    3C5D  23        		inc	hl
3379    3C5E  46        		ld	b,(hl)
3380    3C5F  C5        		push	bc
3381    3C60  210200    		ld	hl,_curblkno
3382    3C63  CD0000    		call	c.0mvf
3383    3C66  210000    		ld	hl,c.r0
3384    3C69  E5        		push	hl
3385    3C6A  DDE5      		push	ix
3386    3C6C  C1        		pop	bc
3387    3C6D  21F2FF    		ld	hl,65522
3388    3C70  09        		add	hl,bc
3389    3C71  E5        		push	hl
3390    3C72  CD0000    		call	c.ladd
3391    3C75  E1        		pop	hl
3392    3C76  23        		inc	hl
3393    3C77  23        		inc	hl
3394    3C78  4E        		ld	c,(hl)
3395    3C79  23        		inc	hl
3396    3C7A  46        		ld	b,(hl)
3397    3C7B  C5        		push	bc
3398    3C7C  2B        		dec	hl
3399    3C7D  2B        		dec	hl
3400    3C7E  2B        		dec	hl
3401    3C7F  4E        		ld	c,(hl)
3402    3C80  23        		inc	hl
3403    3C81  46        		ld	b,(hl)
3404    3C82  C5        		push	bc
3405    3C83  215C36    		ld	hl,L5542
3406    3C86  CD0000    		call	_printf
3407    3C89  F1        		pop	af
3408    3C8A  F1        		pop	af
3409    3C8B  F1        		pop	af
3410    3C8C  F1        		pop	af
3411                    	; 1380          printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
3412                    	; 1381                 lbasize, lbasize, lbasize >> 11);
3413    3C8D  DDE5      		push	ix
3414    3C8F  C1        		pop	bc
3415    3C90  21EEFF    		ld	hl,65518
3416    3C93  09        		add	hl,bc
3417    3C94  CD0000    		call	c.0mvf
3418    3C97  210000    		ld	hl,c.r0
3419    3C9A  E5        		push	hl
3420    3C9B  210B00    		ld	hl,11
3421    3C9E  E5        		push	hl
3422    3C9F  CD0000    		call	c.ulrsh
3423    3CA2  E1        		pop	hl
3424    3CA3  23        		inc	hl
3425    3CA4  23        		inc	hl
3426    3CA5  4E        		ld	c,(hl)
3427    3CA6  23        		inc	hl
3428    3CA7  46        		ld	b,(hl)
3429    3CA8  C5        		push	bc
3430    3CA9  2B        		dec	hl
3431    3CAA  2B        		dec	hl
3432    3CAB  2B        		dec	hl
3433    3CAC  4E        		ld	c,(hl)
3434    3CAD  23        		inc	hl
3435    3CAE  46        		ld	b,(hl)
3436    3CAF  C5        		push	bc
3437    3CB0  DD66F1    		ld	h,(ix-15)
3438    3CB3  DD6EF0    		ld	l,(ix-16)
3439    3CB6  E5        		push	hl
3440    3CB7  DD66EF    		ld	h,(ix-17)
3441    3CBA  DD6EEE    		ld	l,(ix-18)
3442    3CBD  E5        		push	hl
3443    3CBE  DD66F1    		ld	h,(ix-15)
3444    3CC1  DD6EF0    		ld	l,(ix-16)
3445    3CC4  E5        		push	hl
3446    3CC5  DD66EF    		ld	h,(ix-17)
3447    3CC8  DD6EEE    		ld	l,(ix-18)
3448    3CCB  E5        		push	hl
3449    3CCC  218036    		ld	hl,L5642
3450    3CCF  CD0000    		call	_printf
3451    3CD2  210C00    		ld	hl,12
3452    3CD5  39        		add	hl,sp
3453    3CD6  F9        		ld	sp,hl
3454                    	L1325:
3455                    	; 1382          } /* sdtestflg */
3456                    	; 1383      if (partptr[4] == 0xee) /* GPT partitions */
3457    3CD7  DD6E04    		ld	l,(ix+4)
3458    3CDA  DD6605    		ld	h,(ix+5)
3459    3CDD  23        		inc	hl
3460    3CDE  23        		inc	hl
3461    3CDF  23        		inc	hl
3462    3CE0  23        		inc	hl
3463    3CE1  7E        		ld	a,(hl)
3464    3CE2  FEEE      		cp	238
3465    3CE4  C24D3D    		jp	nz,L1425
3466                    	; 1384          {
3467                    	; 1385          parttype = PARTGPT;
3468    3CE7  DD36F603  		ld	(ix-10),3
3469    3CEB  DD36F700  		ld	(ix-9),0
3470                    	; 1386          if (sdtestflg)
3471    3CEF  2A0000    		ld	hl,(_sdtestflg)
3472    3CF2  7C        		ld	a,h
3473    3CF3  B5        		or	l
3474    3CF4  2806      		jr	z,L1525
3475                    	; 1387              {
3476                    	; 1388              printf("GTP partitions\n");
3477    3CF6  21AE36    		ld	hl,L5742
3478    3CF9  CD0000    		call	_printf
3479                    	L1525:
3480                    	; 1389              } /* sdtestflg */
3481                    	; 1390          sdgpthdr(lbastart); /* handle GTP partitions */
3482    3CFC  DD66F5    		ld	h,(ix-11)
3483    3CFF  DD6EF4    		ld	l,(ix-12)
3484    3D02  E5        		push	hl
3485    3D03  DD66F3    		ld	h,(ix-13)
3486    3D06  DD6EF2    		ld	l,(ix-14)
3487    3D09  CD3C33    		call	_sdgpthdr
3488    3D0C  F1        		pop	af
3489                    	; 1391          /* re-read MBR on sector 0
3490                    	; 1392             This is probably not needed as there
3491                    	; 1393             is only one entry (the first one)
3492                    	; 1394             in the MBR when using GPT */
3493                    	; 1395          if (sdread(sdrdbuf, 0))
3494    3D0D  21C136    		ld	hl,L261+3
3495    3D10  46        		ld	b,(hl)
3496    3D11  2B        		dec	hl
3497    3D12  4E        		ld	c,(hl)
3498    3D13  C5        		push	bc
3499    3D14  2B        		dec	hl
3500    3D15  46        		ld	b,(hl)
3501    3D16  2B        		dec	hl
3502    3D17  4E        		ld	c,(hl)
3503    3D18  C5        		push	bc
3504    3D19  214C00    		ld	hl,_sdrdbuf
3505    3D1C  CDE120    		call	_sdread
3506    3D1F  F1        		pop	af
3507    3D20  F1        		pop	af
3508    3D21  79        		ld	a,c
3509    3D22  B0        		or	b
3510    3D23  2815      		jr	z,L1625
3511                    	; 1396              {
3512                    	; 1397              curblkno = 0;
3513                    	; 1398              curblkok = YES;
3514    3D25  210100    		ld	hl,1
3515                    	;    1  /*  z80sdbt.c Boot and test program trying to make a unified prog.
3516                    	;    2   *
3517                    	;    3   *  Boot code for my DIY Z80 Computer. This
3518                    	;    4   *  program is compiled with Whitesmiths/COSMIC
3519                    	;    5   *  C compiler for Z80.
3520                    	;    6   *
3521                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
3522                    	;    8   *
3523                    	;    9   *  Initializes the hardware and detects the
3524                    	;   10   *  presence and partitioning of an attached SD card.
3525                    	;   11   *
3526                    	;   12   *  You are free to use, modify, and redistribute
3527                    	;   13   *  this source code. No warranties are given.
3528                    	;   14   *  Hastily Cobbled Together 2021 and 2022
3529                    	;   15   *  by Hans-Ake Lund
3530                    	;   16   *
3531                    	;   17   */
3532                    	;   18  
3533                    	;   19  #include <std.h>
3534                    	;   20  #include "z80computer.h"
3535                    	;   21  #include "builddate.h"
3536                    	;   22  
3537                    	;   23  #define PRGNAME "\nz80sdbt "
3538                    	;   24  #define VERSION "version 0.7, "
3539                    	;   25  /* This code should be cleaned up when
3540                    	;   26     remaining functions are implemented
3541                    	;   27   */
3542                    	;   28  #define PARTZRO 0  /* Empty partition entry */
3543                    	;   29  #define PARTMBR 1  /* MBR partition */
3544                    	;   30  #define PARTEBR 2  /* EBR logical partition */
3545                    	;   31  #define PARTGPT 3  /* GPT partition */
3546                    	;   32  #define EBRCONT 20 /* EBR container partition in MBR */
3547                    	;   33  
3548                    	;   34  struct partentry
3549                    	;   35      {
3550                    	;   36      char partype;
3551                    	;   37      char dskletter;
3552                    	;   38      int bootable;
3553                    	;   39      unsigned long dskstart;
3554                    	;   40      unsigned long dskend;
3555                    	;   41      unsigned long dsksize;
3556                    	;   42      unsigned char dsktype[16];
3557                    	;   43      } dskmap[16];
3558                    	;   44  
3559                    	;   45  unsigned char dsksign[4]; /* MBR/EBR disk signature */
3560                    	;   46  
3561                    	;   47  /* Function prototypes */
3562                    	;   48  void sdmbrpart(unsigned long);
3563                    	;   49  
3564                    	;   50  /* Response length in bytes
3565                    	;   51   */
3566                    	;   52  #define R1_LEN 1
3567                    	;   53  #define R3_LEN 5
3568                    	;   54  #define R7_LEN 5
3569                    	;   55  
3570                    	;   56  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
3571                    	;   57   * (The CRC7 byte in the tables below are only for information,
3572                    	;   58   * it is calculated by the sdcommand routine.)
3573                    	;   59   */
3574                    	;   60  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
3575                    	;   61  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
3576                    	;   62  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
3577                    	;   63  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
3578                    	;   64  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
3579                    	;   65  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
3580                    	;   66  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
3581                    	;   67  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
3582                    	;   68  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
3583                    	;   69  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
3584                    	;   70  
3585                    	;   71  /* Partition identifiers
3586                    	;   72   */
3587                    	;   73  /* For GPT I have decided that a CP/M partition
3588                    	;   74   * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
3589                    	;   75   */
3590                    	;   76  const unsigned char gptcpm[] =
3591                    	;   77      {
3592                    	;   78      0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
3593                    	;   79      0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
3594                    	;   80      };
3595                    	;   81  /* For MBR/EBR the partition type for CP/M is 0x52
3596                    	;   82   * according to: https://en.wikipedia.org/wiki/Partition_type
3597                    	;   83   */
3598                    	;   84  const unsigned char mbrcpm = 0x52;    /* CP/M partition */
3599                    	;   85  const unsigned char mbrexcode = 0x5f; /* Z80 executable code partition */
3600                    	;   86  /* has a special format that */
3601                    	;   87  /* includes number of sectors to */
3602                    	;   88  /* load and a signature, TBD */
3603                    	;   89  
3604                    	;   90  /* Buffers
3605                    	;   91   */
3606                    	;   92  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
3607                    	;   93  
3608                    	;   94  unsigned char ocrreg[4];     /* SD card OCR register */
3609                    	;   95  unsigned char cidreg[16];    /* SD card CID register */
3610                    	;   96  unsigned char csdreg[16];    /* SD card CSD register */
3611                    	;   97  unsigned long ebrrecs[4];    /* detected EBR records to process */
3612                    	;   98  int ebrrecidx; /* how many EBR records that are populated */
3613                    	;   99  unsigned long ebrnext; /* next chained ebr record */
3614                    	;  100  
3615                    	;  101  /* Variables
3616                    	;  102   */
3617                    	;  103  int curblkok;  /* if YES curblockno is read into buffer */
3618                    	;  104  int partdsk;   /* partition/disk number, 0 = disk A */
3619                    	;  105  int sdinitok;  /* SD card initialized and ready */
3620                    	;  106  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
3621                    	;  107  unsigned long blkmult;   /* block address multiplier */
3622                    	;  108  unsigned long curblkno;  /* block in buffer if curblkok == YES */
3623                    	;  109  
3624                    	;  110  /* debug bool */
3625                    	;  111  int sdtestflg;
3626                    	;  112  
3627                    	;  113  /* CRC routines from:
3628                    	;  114   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
3629                    	;  115   */
3630                    	;  116  
3631                    	;  117  /*
3632                    	;  118  // Calculate CRC7
3633                    	;  119  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
3634                    	;  120  // input:
3635                    	;  121  //   crcIn - the CRC before (0 for first step)
3636                    	;  122  //   data - byte for CRC calculation
3637                    	;  123  // return: the new CRC7
3638                    	;  124  */
3639                    	;  125  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
3640                    	;  126      {
3641                    	;  127      const unsigned char g = 0x89;
3642                    	;  128      unsigned char i;
3643                    	;  129  
3644                    	;  130      crcIn ^= data;
3645                    	;  131      for (i = 0; i < 8; i++)
3646                    	;  132          {
3647                    	;  133          if (crcIn & 0x80) crcIn ^= g;
3648                    	;  134          crcIn <<= 1;
3649                    	;  135          }
3650                    	;  136  
3651                    	;  137      return crcIn;
3652                    	;  138      }
3653                    	;  139  
3654                    	;  140  /*
3655                    	;  141  // Calculate CRC16 CCITT
3656                    	;  142  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
3657                    	;  143  // input:
3658                    	;  144  //   crcIn - the CRC before (0 for rist step)
3659                    	;  145  //   data - byte for CRC calculation
3660                    	;  146  // return: the CRC16 value
3661                    	;  147  */
3662                    	;  148  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
3663                    	;  149      {
3664                    	;  150      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
3665                    	;  151      crcIn ^=  data;
3666                    	;  152      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
3667                    	;  153      crcIn ^= (crcIn << 8) << 4;
3668                    	;  154      crcIn ^= ((crcIn & 0xff) << 4) << 1;
3669                    	;  155  
3670                    	;  156      return crcIn;
3671                    	;  157      }
3672                    	;  158  
3673                    	;  159  /* Send command to SD card and recieve answer.
3674                    	;  160   * A command is 5 bytes long and is followed by
3675                    	;  161   * a CRC7 checksum byte.
3676                    	;  162   * Returns a pointer to the response
3677                    	;  163   * or 0 if no response start bit found.
3678                    	;  164   */
3679                    	;  165  unsigned char *sdcommand(unsigned char *sdcmdp,
3680                    	;  166                           unsigned char *recbuf, int recbytes)
3681                    	;  167      {
3682                    	;  168      int searchn;  /* byte counter to search for response */
3683                    	;  169      int sdcbytes; /* byte counter for bytes to send */
3684                    	;  170      unsigned char *retptr; /* pointer used to store response */
3685                    	;  171      unsigned char rbyte;   /* recieved byte */
3686                    	;  172      unsigned char crc = 0; /* calculated CRC7 */
3687                    	;  173  
3688                    	;  174      /* send 8*2 clockpules */
3689                    	;  175      spiio(0xff);
3690                    	;  176      spiio(0xff);
3691                    	;  177      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
3692                    	;  178          {
3693                    	;  179          crc = CRC7_one(crc, *sdcmdp);
3694                    	;  180          spiio(*sdcmdp++);
3695                    	;  181          }
3696                    	;  182      spiio(crc | 0x01);
3697                    	;  183      /* search for recieved byte with start bit
3698                    	;  184         for a maximum of 10 recieved bytes  */
3699                    	;  185      for (searchn = 10; 0 < searchn; searchn--)
3700                    	;  186          {
3701                    	;  187          rbyte = spiio(0xff);
3702                    	;  188          if ((rbyte & 0x80) == 0)
3703                    	;  189              break;
3704                    	;  190          }
3705                    	;  191      if (searchn == 0) /* no start bit found */
3706                    	;  192          return (NO);
3707                    	;  193      retptr = recbuf;
3708                    	;  194      *retptr++ = rbyte;
3709                    	;  195      for (; 1 < recbytes; recbytes--) /* recieve bytes */
3710                    	;  196          *retptr++ = spiio(0xff);
3711                    	;  197      return (recbuf);
3712                    	;  198      }
3713                    	;  199  
3714                    	;  200  /* Initialise SD card interface
3715                    	;  201   *
3716                    	;  202   * returns YES if ok and NO if not ok
3717                    	;  203   *
3718                    	;  204   * References:
3719                    	;  205   *   https://www.sdcard.org/downloads/pls/
3720                    	;  206   *      Physical Layer Simplified Specification version 8.0
3721                    	;  207   *
3722                    	;  208   * A nice flowchart how to initialize:
3723                    	;  209   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
3724                    	;  210   *
3725                    	;  211   */
3726                    	;  212  int sdinit()
3727                    	;  213      {
3728                    	;  214      int nbytes;  /* byte counter */
3729                    	;  215      int tries;   /* tries to get to active state or searching for data  */
3730                    	;  216      int wtloop;  /* timer loop when trying to enter active state */
3731                    	;  217      unsigned char cmdbuf[5];   /* buffer to build command in */
3732                    	;  218      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3733                    	;  219      unsigned char *statptr;    /* pointer to returned status from SD command */
3734                    	;  220      unsigned char crc;         /* crc register for CID and CSD */
3735                    	;  221      unsigned char rbyte;       /* recieved byte */
3736                    	;  222      unsigned char *prtptr;     /* for debug printing */
3737                    	;  223  
3738                    	;  224      ledon();
3739                    	;  225      spideselect();
3740                    	;  226      sdinitok = NO;
3741                    	;  227  
3742                    	;  228      /* start to generate 9*8 clock pulses with not selected SD card */
3743                    	;  229      for (nbytes = 9; 0 < nbytes; nbytes--)
3744                    	;  230          spiio(0xff);
3745                    	;  231      if (sdtestflg)
3746                    	;  232          {
3747                    	;  233          printf("\nSent 8*8 (72) clock pulses, select not active\n");
3748                    	;  234          } /* sdtestflg */
3749                    	;  235      spiselect();
3750                    	;  236  
3751                    	;  237      /* CMD0: GO_IDLE_STATE */
3752                    	;  238      for (tries = 0; tries < 10; tries++)
3753                    	;  239          {
3754                    	;  240          memcpy(cmdbuf, cmd0, 5);
3755                    	;  241          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3756                    	;  242          if (sdtestflg)
3757                    	;  243              {
3758                    	;  244              if (!statptr)
3759                    	;  245                  printf("CMD0: no response\n");
3760                    	;  246              else
3761                    	;  247                  printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
3762                    	;  248              } /* sdtestflg */
3763                    	;  249          if (!statptr)
3764                    	;  250              {
3765                    	;  251              spideselect();
3766                    	;  252              ledoff();
3767                    	;  253              return (NO);
3768                    	;  254              }
3769                    	;  255          if (statptr[0] == 0x01)
3770                    	;  256              break;
3771                    	;  257          for (wtloop = 0; wtloop < tries * 10; wtloop++)
3772                    	;  258              {
3773                    	;  259              /* wait loop, time increasing for each try */
3774                    	;  260              spiio(0xff);
3775                    	;  261              }
3776                    	;  262          }
3777                    	;  263  
3778                    	;  264      /* CMD8: SEND_IF_COND */
3779                    	;  265      memcpy(cmdbuf, cmd8, 5);
3780                    	;  266      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
3781                    	;  267      if (sdtestflg)
3782                    	;  268          {
3783                    	;  269          if (!statptr)
3784                    	;  270              printf("CMD8: no response\n");
3785                    	;  271          else
3786                    	;  272              {
3787                    	;  273              printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
3788                    	;  274                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
3789                    	;  275              if (!(statptr[0] & 0xfe)) /* no error */
3790                    	;  276                  {
3791                    	;  277                  if (statptr[4] == 0xaa)
3792                    	;  278                      printf("echo back ok, ");
3793                    	;  279                  else
3794                    	;  280                      printf("invalid echo back\n");
3795                    	;  281                  }
3796                    	;  282              }
3797                    	;  283          } /* sdtestflg */
3798                    	;  284      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
3799                    	;  285          {
3800                    	;  286          sdver2 = NO;
3801                    	;  287          if (sdtestflg)
3802                    	;  288              {
3803                    	;  289              printf("probably SD ver. 1\n");
3804                    	;  290              } /* sdtestflg */
3805                    	;  291          }
3806                    	;  292      else
3807                    	;  293          {
3808                    	;  294          sdver2 = YES;
3809                    	;  295          if (statptr[4] != 0xaa) /* but invalid echo back */
3810                    	;  296              {
3811                    	;  297              spideselect();
3812                    	;  298              ledoff();
3813                    	;  299              return (NO);
3814                    	;  300              }
3815                    	;  301          if (sdtestflg)
3816                    	;  302              {
3817                    	;  303              printf("SD ver 2\n");
3818                    	;  304              } /* sdtestflg */
3819                    	;  305          }
3820                    	;  306  
3821                    	;  307      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
3822                    	;  308      for (tries = 0; tries < 20; tries++)
3823                    	;  309          {
3824                    	;  310          memcpy(cmdbuf, cmd55, 5);
3825                    	;  311          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3826                    	;  312          if (sdtestflg)
3827                    	;  313              {
3828                    	;  314              if (!statptr)
3829                    	;  315                  printf("CMD55: no response\n");
3830                    	;  316              else
3831                    	;  317                  printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
3832                    	;  318              } /* sdtestflg */
3833                    	;  319          if (!statptr)
3834                    	;  320              {
3835                    	;  321              spideselect();
3836                    	;  322              ledoff();
3837                    	;  323              return (NO);
3838                    	;  324              }
3839                    	;  325          memcpy(cmdbuf, acmd41, 5);
3840                    	;  326          if (sdver2)
3841                    	;  327              cmdbuf[1] = 0x40;
3842                    	;  328          else
3843                    	;  329              cmdbuf[1] = 0x00;
3844                    	;  330          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3845                    	;  331          if (sdtestflg)
3846                    	;  332              {
3847                    	;  333              if (!statptr)
3848                    	;  334                  printf("ACMD41: no response\n");
3849                    	;  335              else
3850                    	;  336                  printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
3851                    	;  337                         statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
3852                    	;  338              } /* sdtestflg */
3853                    	;  339          if (!statptr)
3854                    	;  340              {
3855                    	;  341              spideselect();
3856                    	;  342              ledoff();
3857                    	;  343              return (NO);
3858                    	;  344              }
3859                    	;  345          if (statptr[0] == 0x00) /* now the SD card is ready */
3860                    	;  346              {
3861                    	;  347              break;
3862                    	;  348              }
3863                    	;  349          for (wtloop = 0; wtloop < tries * 10; wtloop++)
3864                    	;  350              {
3865                    	;  351              /* wait loop, time increasing for each try */
3866                    	;  352              spiio(0xff);
3867                    	;  353              }
3868                    	;  354          }
3869                    	;  355  
3870                    	;  356      /* CMD58: READ_OCR */
3871                    	;  357      /* According to the flow chart this should not work
3872                    	;  358         for SD ver. 1 but the response is ok anyway
3873                    	;  359         all tested SD cards  */
3874                    	;  360      memcpy(cmdbuf, cmd58, 5);
3875                    	;  361      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
3876                    	;  362      if (sdtestflg)
3877                    	;  363          {
3878                    	;  364          if (!statptr)
3879                    	;  365              printf("CMD58: no response\n");
3880                    	;  366          else
3881                    	;  367              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
3882                    	;  368                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
3883                    	;  369          } /* sdtestflg */
3884                    	;  370      if (!statptr)
3885                    	;  371          {
3886                    	;  372          spideselect();
3887                    	;  373          ledoff();
3888                    	;  374          return (NO);
3889                    	;  375          }
3890                    	;  376      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
3891                    	;  377      blkmult = 1; /* assume block address */
3892                    	;  378      if (ocrreg[0] & 0x80)
3893                    	;  379          {
3894                    	;  380          /* SD Ver.2+ */
3895                    	;  381          if (!(ocrreg[0] & 0x40))
3896                    	;  382              {
3897                    	;  383              /* SD Ver.2+, Byte address */
3898                    	;  384              blkmult = 512;
3899                    	;  385              }
3900                    	;  386          }
3901                    	;  387  
3902                    	;  388      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
3903                    	;  389      if (blkmult == 512)
3904                    	;  390          {
3905                    	;  391          memcpy(cmdbuf, cmd16, 5);
3906                    	;  392          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3907                    	;  393          if (sdtestflg)
3908                    	;  394              {
3909                    	;  395              if (!statptr)
3910                    	;  396                  printf("CMD16: no response\n");
3911                    	;  397              else
3912                    	;  398                  printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
3913                    	;  399                         statptr[0]);
3914                    	;  400              } /* sdtestflg */
3915                    	;  401          if (!statptr)
3916                    	;  402              {
3917                    	;  403              spideselect();
3918                    	;  404              ledoff();
3919                    	;  405              return (NO);
3920                    	;  406              }
3921                    	;  407          }
3922                    	;  408      /* Register information:
3923                    	;  409       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
3924                    	;  410       */
3925                    	;  411  
3926                    	;  412      /* CMD10: SEND_CID */
3927                    	;  413      memcpy(cmdbuf, cmd10, 5);
3928                    	;  414      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3929                    	;  415      if (sdtestflg)
3930                    	;  416          {
3931                    	;  417          if (!statptr)
3932                    	;  418              printf("CMD10: no response\n");
3933                    	;  419          else
3934                    	;  420              printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
3935                    	;  421          } /* sdtestflg */
3936                    	;  422      if (!statptr)
3937                    	;  423          {
3938                    	;  424          spideselect();
3939                    	;  425          ledoff();
3940                    	;  426          return (NO);
3941                    	;  427          }
3942                    	;  428      /* looking for 0xfe that is the byte before data */
3943                    	;  429      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
3944                    	;  430          ;
3945                    	;  431      if (tries == 0) /* tried too many times */
3946                    	;  432          {
3947                    	;  433          if (sdtestflg)
3948                    	;  434              {
3949                    	;  435              printf("  No data found\n");
3950                    	;  436              } /* sdtestflg */
3951                    	;  437          spideselect();
3952                    	;  438          ledoff();
3953                    	;  439          return (NO);
3954                    	;  440          }
3955                    	;  441      else
3956                    	;  442          {
3957                    	;  443          crc = 0;
3958                    	;  444          for (nbytes = 0; nbytes < 15; nbytes++)
3959                    	;  445              {
3960                    	;  446              rbyte = spiio(0xff);
3961                    	;  447              cidreg[nbytes] = rbyte;
3962                    	;  448              crc = CRC7_one(crc, rbyte);
3963                    	;  449              }
3964                    	;  450          cidreg[15] = spiio(0xff);
3965                    	;  451          crc |= 0x01;
3966                    	;  452          /* some SD cards need additional clock pulses */
3967                    	;  453          for (nbytes = 9; 0 < nbytes; nbytes--)
3968                    	;  454              spiio(0xff);
3969                    	;  455          if (sdtestflg)
3970                    	;  456              {
3971                    	;  457              prtptr = &cidreg[0];
3972                    	;  458              printf("  CID: [");
3973                    	;  459              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
3974                    	;  460                  printf("%02x ", *prtptr);
3975                    	;  461              prtptr = &cidreg[0];
3976                    	;  462              printf("\b] |");
3977                    	;  463              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
3978                    	;  464                  {
3979                    	;  465                  if ((' ' <= *prtptr) && (*prtptr < 127))
3980                    	;  466                      putchar(*prtptr);
3981                    	;  467                  else
3982                    	;  468                      putchar('.');
3983                    	;  469                  }
3984                    	;  470              printf("|\n");
3985                    	;  471              if (crc == cidreg[15])
3986                    	;  472                  {
3987                    	;  473                  printf("CRC7 ok: [%02x]\n", crc);
3988                    	;  474                  }
3989                    	;  475              else
3990                    	;  476                  {
3991                    	;  477                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
3992                    	;  478                         crc, cidreg[15]);
3993                    	;  479                  /* could maybe return failure here */
3994                    	;  480                  }
3995                    	;  481              } /* sdtestflg */
3996                    	;  482          }
3997                    	;  483  
3998                    	;  484      /* CMD9: SEND_CSD */
3999                    	;  485      memcpy(cmdbuf, cmd9, 5);
4000                    	;  486      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
4001                    	;  487      if (sdtestflg)
4002                    	;  488          {
4003                    	;  489          if (!statptr)
4004                    	;  490              printf("CMD9: no response\n");
4005                    	;  491          else
4006                    	;  492              printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
4007                    	;  493          } /* sdtestflg */
4008                    	;  494      if (!statptr)
4009                    	;  495          {
4010                    	;  496          spideselect();
4011                    	;  497          ledoff();
4012                    	;  498          return (NO);
4013                    	;  499          }
4014                    	;  500      /* looking for 0xfe that is the byte before data */
4015                    	;  501      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
4016                    	;  502          ;
4017                    	;  503      if (tries == 0) /* tried too many times */
4018                    	;  504          {
4019                    	;  505          if (sdtestflg)
4020                    	;  506              {
4021                    	;  507              printf("  No data found\n");
4022                    	;  508              } /* sdtestflg */
4023                    	;  509          return (NO);
4024                    	;  510          }
4025                    	;  511      else
4026                    	;  512          {
4027                    	;  513          crc = 0;
4028                    	;  514          for (nbytes = 0; nbytes < 15; nbytes++)
4029                    	;  515              {
4030                    	;  516              rbyte = spiio(0xff);
4031                    	;  517              csdreg[nbytes] = rbyte;
4032                    	;  518              crc = CRC7_one(crc, rbyte);
4033                    	;  519              }
4034                    	;  520          csdreg[15] = spiio(0xff);
4035                    	;  521          crc |= 0x01;
4036                    	;  522          /* some SD cards need additional clock pulses */
4037                    	;  523          for (nbytes = 9; 0 < nbytes; nbytes--)
4038                    	;  524              spiio(0xff);
4039                    	;  525          if (sdtestflg)
4040                    	;  526              {
4041                    	;  527              prtptr = &csdreg[0];
4042                    	;  528              printf("  CSD: [");
4043                    	;  529              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
4044                    	;  530                  printf("%02x ", *prtptr);
4045                    	;  531              prtptr = &csdreg[0];
4046                    	;  532              printf("\b] |");
4047                    	;  533              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
4048                    	;  534                  {
4049                    	;  535                  if ((' ' <= *prtptr) && (*prtptr < 127))
4050                    	;  536                      putchar(*prtptr);
4051                    	;  537                  else
4052                    	;  538                      putchar('.');
4053                    	;  539                  }
4054                    	;  540              printf("|\n");
4055                    	;  541              if (crc == csdreg[15])
4056                    	;  542                  {
4057                    	;  543                  printf("CRC7 ok: [%02x]\n", crc);
4058                    	;  544                  }
4059                    	;  545              else
4060                    	;  546                  {
4061                    	;  547                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
4062                    	;  548                         crc, csdreg[15]);
4063                    	;  549                  /* could maybe return failure here */
4064                    	;  550                  }
4065                    	;  551              } /* sdtestflg */
4066                    	;  552          }
4067                    	;  553  
4068                    	;  554      for (nbytes = 9; 0 < nbytes; nbytes--)
4069                    	;  555          spiio(0xff);
4070                    	;  556      if (sdtestflg)
4071                    	;  557          {
4072                    	;  558          printf("Sent 9*8 (72) clock pulses, select active\n");
4073                    	;  559          } /* sdtestflg */
4074                    	;  560  
4075                    	;  561      sdinitok = YES;
4076                    	;  562  
4077                    	;  563      spideselect();
4078                    	;  564      ledoff();
4079                    	;  565  
4080                    	;  566      return (YES);
4081                    	;  567      }
4082                    	;  568  
4083                    	;  569  int sdprobe()
4084                    	;  570      {
4085                    	;  571      unsigned char cmdbuf[5];   /* buffer to build command in */
4086                    	;  572      unsigned char rstatbuf[5]; /* buffer to recieve status in */
4087                    	;  573      unsigned char *statptr;    /* pointer to returned status from SD command */
4088                    	;  574      int nbytes;  /* byte counter */
4089                    	;  575      int allzero = YES;
4090                    	;  576  
4091                    	;  577      ledon();
4092                    	;  578      spiselect();
4093                    	;  579  
4094                    	;  580      /* CMD58: READ_OCR */
4095                    	;  581      memcpy(cmdbuf, cmd58, 5);
   0                    	;  582      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
   1                    	;  583      for (nbytes = 0; nbytes < 5; nbytes++)
   2                    	;  584          {
   3                    	;  585          if (statptr[nbytes] != 0)
   4                    	;  586              allzero = NO;
   5                    	;  587          }
   6                    	;  588      if (sdtestflg)
   7                    	;  589          {
   8                    	;  590          if (!statptr)
   9                    	;  591              printf("CMD58: no response\n");
  10                    	;  592          else
  11                    	;  593              {
  12                    	;  594              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
  13                    	;  595                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
  14                    	;  596              if (allzero)
  15                    	;  597                  printf("SD card not inserted or not initialized\n");
  16                    	;  598              }
  17                    	;  599          } /* sdtestflg */
  18                    	;  600      if (!statptr || allzero)
  19                    	;  601          {
  20                    	;  602          sdinitok = NO;
  21                    	;  603          spideselect();
  22                    	;  604          ledoff();
  23                    	;  605          return (NO);
  24                    	;  606          }
  25                    	;  607  
  26                    	;  608      spideselect();
  27                    	;  609      ledoff();
  28                    	;  610  
  29                    	;  611      return (YES);
  30                    	;  612      }
  31                    	;  613  
  32                    	;  614  /* print OCR, CID and CSD registers*/
  33                    	;  615  void sdprtreg()
  34                    	;  616      {
  35                    	;  617      unsigned int n;
  36                    	;  618      unsigned int csize;
  37                    	;  619      unsigned long devsize;
  38                    	;  620      unsigned long capacity;
  39                    	;  621  
  40                    	;  622      if (!sdinitok)
  41                    	;  623          {
  42                    	;  624          printf("SD card not initialized\n");
  43                    	;  625          return;
  44                    	;  626          }
  45                    	;  627      printf("SD card information:");
  46                    	;  628      if (ocrreg[0] & 0x80)
  47                    	;  629          {
  48                    	;  630          if (ocrreg[0] & 0x40)
  49                    	;  631              printf("  SD card ver. 2+, Block address\n");
  50                    	;  632          else
  51                    	;  633              {
  52                    	;  634              if (sdver2)
  53                    	;  635                  printf("  SD card ver. 2+, Byte address\n");
  54                    	;  636              else
  55                    	;  637                  printf("  SD card ver. 1, Byte address\n");
  56                    	;  638              }
  57                    	;  639          }
  58                    	;  640      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
  59                    	;  641      printf("OEM ID: %.2s, ", &cidreg[1]);
  60                    	;  642      printf("Product name: %.5s\n", &cidreg[3]);
  61                    	;  643      printf("  Product revision: %d.%d, ",
  62                    	;  644             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
  63                    	;  645      printf("Serial number: %lu\n",
  64                    	;  646             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
  65                    	;  647      printf("  Manufacturing date: %d-%d, ",
  66                    	;  648             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
  67                    	;  649      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
  68                    	;  650          {
  69                    	;  651          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
  70                    	;  652          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
  71                    	;  653                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
  72                    	;  654          capacity = (unsigned long) csize << (n-10);
  73                    	;  655          printf("Device capacity: %lu MByte\n", capacity >> 10);
  74                    	;  656          }
  75                    	;  657      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
  76                    	;  658          {
  77                    	;  659          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
  78                    	;  660                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
  79                    	;  661          capacity = devsize << 9;
  80                    	;  662          printf("Device capacity: %lu MByte\n", capacity >> 10);
  81                    	;  663          }
  82                    	;  664      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
  83                    	;  665          {
  84                    	;  666          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
  85                    	;  667                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
  86                    	;  668          capacity = devsize << 9;
  87                    	;  669          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
  88                    	;  670          }
  89                    	;  671  
  90                    	;  672      if (sdtestflg)
  91                    	;  673          {
  92                    	;  674  
  93                    	;  675          printf("--------------------------------------\n");
  94                    	;  676          printf("OCR register:\n");
  95                    	;  677          if (ocrreg[2] & 0x80)
  96                    	;  678              printf("2.7-2.8V (bit 15) ");
  97                    	;  679          if (ocrreg[1] & 0x01)
  98                    	;  680              printf("2.8-2.9V (bit 16) ");
  99                    	;  681          if (ocrreg[1] & 0x02)
 100                    	;  682              printf("2.9-3.0V (bit 17) ");
 101                    	;  683          if (ocrreg[1] & 0x04)
 102                    	;  684              printf("3.0-3.1V (bit 18) \n");
 103                    	;  685          if (ocrreg[1] & 0x08)
 104                    	;  686              printf("3.1-3.2V (bit 19) ");
 105                    	;  687          if (ocrreg[1] & 0x10)
 106                    	;  688              printf("3.2-3.3V (bit 20) ");
 107                    	;  689          if (ocrreg[1] & 0x20)
 108                    	;  690              printf("3.3-3.4V (bit 21) ");
 109                    	;  691          if (ocrreg[1] & 0x40)
 110                    	;  692              printf("3.4-3.5V (bit 22) \n");
 111                    	;  693          if (ocrreg[1] & 0x80)
 112                    	;  694              printf("3.5-3.6V (bit 23) \n");
 113                    	;  695          if (ocrreg[0] & 0x01)
 114                    	;  696              printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
 115                    	;  697          if (ocrreg[0] & 0x08)
 116                    	;  698              printf("Over 2TB support Status (CO2T) (bit 27) set\n");
 117                    	;  699          if (ocrreg[0] & 0x20)
 118                    	;  700              printf("UHS-II Card Status (bit 29) set ");
 119                    	;  701          if (ocrreg[0] & 0x80)
 120                    	;  702              {
 121                    	;  703              if (ocrreg[0] & 0x40)
 122                    	;  704                  {
 123                    	;  705                  printf("Card Capacity Status (CCS) (bit 30) set\n");
 124                    	;  706                  printf("  SD Ver.2+, Block address");
 125                    	;  707                  }
 126                    	;  708              else
 127                    	;  709                  {
 128                    	;  710                  printf("Card Capacity Status (CCS) (bit 30) not set\n");
 129                    	;  711                  if (sdver2)
 130                    	;  712                      printf("  SD Ver.2+, Byte address");
 131                    	;  713                  else
 132                    	;  714                      printf("  SD Ver.1, Byte address");
 133                    	;  715                  }
 134                    	;  716              printf("\nCard power up status bit (busy) (bit 31) set\n");
 135                    	;  717              }
 136                    	;  718          else
 137                    	;  719              {
 138                    	;  720              printf("\nCard power up status bit (busy) (bit 31) not set.\n");
 139                    	;  721              printf("  This bit is not set if the card has not finished the power up routine.\n");
 140                    	;  722              }
 141                    	;  723          printf("--------------------------------------\n");
 142                    	;  724          printf("CID register:\n");
 143                    	;  725          printf("MID: 0x%02x, ", cidreg[0]);
 144                    	;  726          printf("OID: %.2s, ", &cidreg[1]);
 145                    	;  727          printf("PNM: %.5s, ", &cidreg[3]);
 146                    	;  728          printf("PRV: %d.%d, ",
 147                    	;  729                 (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
 148                    	;  730          printf("PSN: %lu, ",
 149                    	;  731                 (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
 150                    	;  732          printf("MDT: %d-%d\n",
 151                    	;  733                 2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
 152                    	;  734          printf("--------------------------------------\n");
 153                    	;  735          printf("CSD register:\n");
 154                    	;  736          if ((csdreg[0] & 0xc0) == 0x00)
 155                    	;  737              {
 156                    	;  738              printf("CSD Version 1.0, Standard Capacity\n");
 157                    	;  739              n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
 158                    	;  740              csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
 159                    	;  741                      ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
 160                    	;  742              capacity = (unsigned long) csize << (n-10);
 161                    	;  743              printf(" Device capacity: %lu KByte, %lu MByte\n",
 162                    	;  744                     capacity, capacity >> 10);
 163                    	;  745              }
 164                    	;  746          if ((csdreg[0] & 0xc0) == 0x40)
 165                    	;  747              {
 166                    	;  748              printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
 167                    	;  749              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
 168                    	;  750                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 169                    	;  751              capacity = devsize << 9;
 170                    	;  752              printf(" Device capacity: %lu KByte, %lu MByte\n",
 171                    	;  753                     capacity, capacity >> 10);
 172                    	;  754              }
 173                    	;  755          if ((csdreg[0] & 0xc0) == 0x80)
 174                    	;  756              {
 175                    	;  757              printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
 176                    	;  758              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
 177                    	;  759                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
 178                    	;  760              capacity = devsize << 9;
 179                    	;  761              printf(" Device capacity: %lu KByte, %lu MByte\n",
 180                    	;  762                     capacity, capacity >> 10);
 181                    	;  763              }
 182                    	;  764          printf("--------------------------------------\n");
 183                    	;  765  
 184                    	;  766          } /* sdtestflg */ /* SDTEST */
 185                    	;  767  
 186                    	;  768      }
 187                    	;  769  
 188                    	;  770  /* Read data block of 512 bytes to buffer
 189                    	;  771   * Returns YES if ok or NO if error
 190                    	;  772   */
 191                    	;  773  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
 192                    	;  774      {
 193                    	;  775      unsigned char *statptr;
 194                    	;  776      unsigned char rbyte;
 195                    	;  777      unsigned char cmdbuf[5];   /* buffer to build command in */
 196                    	;  778      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 197                    	;  779      int nbytes;
 198                    	;  780      int tries;
 199                    	;  781      unsigned long blktoread;
 200                    	;  782      unsigned int rxcrc16;
 201                    	;  783      unsigned int calcrc16;
 202                    	;  784  
 203                    	;  785      ledon();
 204                    	;  786      spiselect();
 205                    	;  787  
 206                    	;  788      if (!sdinitok)
 207                    	;  789          {
 208                    	;  790          if (sdtestflg)
 209                    	;  791              {
 210                    	;  792              printf("SD card not initialized\n");
 211                    	;  793              } /* sdtestflg */
 212                    	;  794          spideselect();
 213                    	;  795          ledoff();
 214                    	;  796          return (NO);
 215                    	;  797          }
 216                    	;  798  
 217                    	;  799      /* CMD17: READ_SINGLE_BLOCK */
 218                    	;  800      /* Insert block # into command */
 219                    	;  801      memcpy(cmdbuf, cmd17, 5);
 220                    	;  802      blktoread = blkmult * rdblkno;
 221                    	;  803      cmdbuf[4] = blktoread & 0xff;
 222                    	;  804      blktoread = blktoread >> 8;
 223                    	;  805      cmdbuf[3] = blktoread & 0xff;
 224                    	;  806      blktoread = blktoread >> 8;
 225                    	;  807      cmdbuf[2] = blktoread & 0xff;
 226                    	;  808      blktoread = blktoread >> 8;
 227                    	;  809      cmdbuf[1] = blktoread & 0xff;
 228                    	;  810  
 229                    	;  811      if (sdtestflg)
 230                    	;  812          {
 231                    	;  813          printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
 232                    	;  814                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
 233                    	;  815          } /* sdtestflg */
 234                    	;  816      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 235                    	;  817      if (sdtestflg)
 236                    	;  818          {
 237                    	;  819          printf("CMD17 R1 response [%02x]\n", statptr[0]);
 238                    	;  820          } /* sdtestflg */
 239                    	;  821      if (statptr[0])
 240                    	;  822          {
 241                    	;  823          if (sdtestflg)
 242                    	;  824              {
 243                    	;  825              printf("  could not read block\n");
 244                    	;  826              } /* sdtestflg */
 245                    	;  827          spideselect();
 246                    	;  828          ledoff();
 247                    	;  829          return (NO);
 248                    	;  830          }
 249                    	;  831      /* looking for 0xfe that is the byte before data */
 250                    	;  832      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
 251                    	;  833          {
 252                    	;  834          if ((rbyte & 0xe0) == 0x00)
 253                    	;  835              {
 254                    	;  836              /* If a read operation fails and the card cannot provide
 255                    	;  837                 the required data, it will send a data error token instead
 256                    	;  838               */
 257                    	;  839              if (sdtestflg)
 258                    	;  840                  {
 259                    	;  841                  printf("  read error: [%02x]\n", rbyte);
 260                    	;  842                  } /* sdtestflg */
 261                    	;  843              spideselect();
 262                    	;  844              ledoff();
 263                    	;  845              return (NO);
 264                    	;  846              }
 265                    	;  847          }
 266                    	;  848      if (tries == 0) /* tried too many times */
 267                    	;  849          {
 268                    	;  850          if (sdtestflg)
 269                    	;  851              {
 270                    	;  852              printf("  no data found\n");
 271                    	;  853              } /* sdtestflg */
 272                    	;  854          spideselect();
 273                    	;  855          ledoff();
 274                    	;  856          return (NO);
 275                    	;  857          }
 276                    	;  858      else
 277                    	;  859          {
 278                    	;  860          calcrc16 = 0;
 279                    	;  861          for (nbytes = 0; nbytes < 512; nbytes++)
 280                    	;  862              {
 281                    	;  863              rbyte = spiio(0xff);
 282                    	;  864              calcrc16 = CRC16_one(calcrc16, rbyte);
 283                    	;  865              rdbuf[nbytes] = rbyte;
 284                    	;  866              }
 285                    	;  867          rxcrc16 = spiio(0xff) << 8;
 286                    	;  868          rxcrc16 += spiio(0xff);
 287                    	;  869  
 288                    	;  870          if (sdtestflg)
 289                    	;  871              {
 290                    	;  872              printf("  read data block %ld:\n", rdblkno);
 291                    	;  873              } /* sdtestflg */
 292                    	;  874          if (rxcrc16 != calcrc16)
 293                    	;  875              {
 294                    	;  876              if (sdtestflg)
 295                    	;  877                  {
 296                    	;  878                  printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
 297                    	;  879                         rxcrc16, calcrc16);
 298                    	;  880                  } /* sdtestflg */
 299                    	;  881              spideselect();
 300                    	;  882              ledoff();
 301                    	;  883              return (NO);
 302                    	;  884              }
 303                    	;  885          }
 304                    	;  886      spideselect();
 305                    	;  887      ledoff();
 306                    	;  888      return (YES);
 307                    	;  889      }
 308                    	;  890  
 309                    	;  891  /* Write data block of 512 bytes from buffer
 310                    	;  892   * Returns YES if ok or NO if error
 311                    	;  893   */
 312                    	;  894  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
 313                    	;  895      {
 314                    	;  896      unsigned char *statptr;
 315                    	;  897      unsigned char rbyte;
 316                    	;  898      unsigned char tbyte;
 317                    	;  899      unsigned char cmdbuf[5];   /* buffer to build command in */
 318                    	;  900      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 319                    	;  901      int nbytes;
 320                    	;  902      int tries;
 321                    	;  903      unsigned long blktowrite;
 322                    	;  904      unsigned int calcrc16;
 323                    	;  905  
 324                    	;  906      ledon();
 325                    	;  907      spiselect();
 326                    	;  908  
 327                    	;  909      if (!sdinitok)
 328                    	;  910          {
 329                    	;  911          if (sdtestflg)
 330                    	;  912              {
 331                    	;  913              printf("SD card not initialized\n");
 332                    	;  914              } /* sdtestflg */
 333                    	;  915          spideselect();
 334                    	;  916          ledoff();
 335                    	;  917          return (NO);
 336                    	;  918          }
 337                    	;  919  
 338                    	;  920      if (sdtestflg)
 339                    	;  921          {
 340                    	;  922          printf("  write data block %ld:\n", wrblkno);
 341                    	;  923          } /* sdtestflg */
 342                    	;  924      /* CMD24: WRITE_SINGLE_BLOCK */
 343                    	;  925      /* Insert block # into command */
 344                    	;  926      memcpy(cmdbuf, cmd24, 5);
 345                    	;  927      blktowrite = blkmult * wrblkno;
 346                    	;  928      cmdbuf[4] = blktowrite & 0xff;
 347                    	;  929      blktowrite = blktowrite >> 8;
 348                    	;  930      cmdbuf[3] = blktowrite & 0xff;
 349                    	;  931      blktowrite = blktowrite >> 8;
 350                    	;  932      cmdbuf[2] = blktowrite & 0xff;
 351                    	;  933      blktowrite = blktowrite >> 8;
 352                    	;  934      cmdbuf[1] = blktowrite & 0xff;
 353                    	;  935  
 354                    	;  936      if (sdtestflg)
 355                    	;  937          {
 356                    	;  938          printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
 357                    	;  939                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
 358                    	;  940          } /* sdtestflg */
 359                    	;  941      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 360                    	;  942      if (sdtestflg)
 361                    	;  943          {
 362                    	;  944          printf("CMD24 R1 response [%02x]\n", statptr[0]);
 363                    	;  945          } /* sdtestflg */
 364                    	;  946      if (statptr[0])
 365                    	;  947          {
 366                    	;  948          if (sdtestflg)
 367                    	;  949              {
 368                    	;  950              printf("  could not write block\n");
 369                    	;  951              } /* sdtestflg */
 370                    	;  952          spideselect();
 371                    	;  953          ledoff();
 372                    	;  954          return (NO);
 373                    	;  955          }
 374                    	;  956      /* send 0xfe, the byte before data */
 375                    	;  957      spiio(0xfe);
 376                    	;  958      /* initialize crc and send block */
 377                    	;  959      calcrc16 = 0;
 378                    	;  960      for (nbytes = 0; nbytes < 512; nbytes++)
 379                    	;  961          {
 380                    	;  962          tbyte = wrbuf[nbytes];
 381                    	;  963          spiio(tbyte);
 382                    	;  964          calcrc16 = CRC16_one(calcrc16, tbyte);
 383                    	;  965          }
 384                    	;  966      spiio((calcrc16 >> 8) & 0xff);
 385                    	;  967      spiio(calcrc16 & 0xff);
 386                    	;  968  
 387                    	;  969      /* check data resposnse */
 388                    	;  970      for (tries = 20;
 389                    	;  971              0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
 390                    	;  972              tries--)
 391                    	;  973          ;
 392                    	;  974      if (tries == 0)
 393                    	;  975          {
 394                    	;  976          if (sdtestflg)
 395                    	;  977              {
 396                    	;  978              printf("No data response\n");
 397                    	;  979              } /* sdtestflg */
 398                    	;  980          spideselect();
 399                    	;  981          ledoff();
 400                    	;  982          return (NO);
 401                    	;  983          }
 402                    	;  984      else
 403                    	;  985          {
 404                    	;  986          if (sdtestflg)
 405                    	;  987              {
 406                    	;  988              printf("Data response [%02x]", 0x1f & rbyte);
 407                    	;  989              } /* sdtestflg */
 408                    	;  990          if ((0x1f & rbyte) == 0x05)
 409                    	;  991              {
 410                    	;  992              if (sdtestflg)
 411                    	;  993                  {
 412                    	;  994                  printf(", data accepted\n");
 413                    	;  995                  } /* sdtestflg */
 414                    	;  996              for (nbytes = 9; 0 < nbytes; nbytes--)
 415                    	;  997                  spiio(0xff);
 416                    	;  998              if (sdtestflg)
 417                    	;  999                  {
 418                    	; 1000                  printf("Sent 9*8 (72) clock pulses, select active\n");
 419                    	; 1001                  } /* sdtestflg */
 420                    	; 1002              spideselect();
 421                    	; 1003              ledoff();
 422                    	; 1004              return (YES);
 423                    	; 1005              }
 424                    	; 1006          else
 425                    	; 1007              {
 426                    	; 1008              if (sdtestflg)
 427                    	; 1009                  {
 428                    	; 1010                  printf(", data not accepted\n");
 429                    	; 1011                  } /* sdtestflg */
 430                    	; 1012              spideselect();
 431                    	; 1013              ledoff();
 432                    	; 1014              return (NO);
 433                    	; 1015              }
 434                    	; 1016          }
 435                    	; 1017      }
 436                    	; 1018  
 437                    	; 1019  /* Print data in 512 byte buffer */
 438                    	; 1020  void sddatprt(unsigned char *prtbuf)
 439                    	; 1021      {
 440                    	; 1022      /* Variables used for "pretty-print" */
 441                    	; 1023      int allzero, dmpline, dotprted, lastallz, nbytes;
 442                    	; 1024      unsigned char *prtptr;
 443                    	; 1025  
 444                    	; 1026      prtptr = prtbuf;
 445                    	; 1027      dotprted = NO;
 446                    	; 1028      lastallz = NO;
 447                    	; 1029      for (dmpline = 0; dmpline < 32; dmpline++)
 448                    	; 1030          {
 449                    	; 1031          /* test if all 16 bytes are 0x00 */
 450                    	; 1032          allzero = YES;
 451                    	; 1033          for (nbytes = 0; nbytes < 16; nbytes++)
 452                    	; 1034              {
 453                    	; 1035              if (prtptr[nbytes] != 0)
 454                    	; 1036                  allzero = NO;
 455                    	; 1037              }
 456                    	; 1038          if (lastallz && allzero)
 457                    	; 1039              {
 458                    	; 1040              if (!dotprted)
 459                    	; 1041                  {
 460                    	; 1042                  printf("*\n");
 461                    	; 1043                  dotprted = YES;
 462                    	; 1044                  }
 463                    	; 1045              }
 464                    	; 1046          else
 465                    	; 1047              {
 466                    	; 1048              dotprted = NO;
 467                    	; 1049              /* print offset */
 468                    	; 1050              printf("%04x ", dmpline * 16);
 469                    	; 1051              /* print 16 bytes in hex */
 470                    	; 1052              for (nbytes = 0; nbytes < 16; nbytes++)
 471                    	; 1053                  printf("%02x ", prtptr[nbytes]);
 472                    	; 1054              /* print these bytes in ASCII if printable */
 473                    	; 1055              printf(" |");
 474                    	; 1056              for (nbytes = 0; nbytes < 16; nbytes++)
 475                    	; 1057                  {
 476                    	; 1058                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
 477                    	; 1059                      putchar(prtptr[nbytes]);
 478                    	; 1060                  else
 479                    	; 1061                      putchar('.');
 480                    	; 1062                  }
 481                    	; 1063              printf("|\n");
 482                    	; 1064              }
 483                    	; 1065          prtptr += 16;
 484                    	; 1066          lastallz = allzero;
 485                    	; 1067          }
 486                    	; 1068      }
 487                    	; 1069  
 488                    	; 1070  /* Print GUID (mixed endian format)
 489                    	; 1071   */
 490                    	; 1072  void prtguid(unsigned char *guidptr)
 491                    	; 1073      {
 492                    	; 1074      int index;
 493                    	; 1075  
 494                    	; 1076      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
 495                    	; 1077      printf("%02x%02x-", guidptr[5], guidptr[4]);
 496                    	; 1078      printf("%02x%02x-", guidptr[7], guidptr[6]);
 497                    	; 1079      printf("%02x%02x-", guidptr[8], guidptr[9]);
 498                    	; 1080      printf("%02x%02x%02x%02x%02x%02x",
 499                    	; 1081             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
 500                    	; 1082      }
 501                    	; 1083  
 502                    	; 1084  /* Analyze and print GPT entry
 503                    	; 1085   */
 504                    	; 1086  int prtgptent(unsigned int entryno)
 505                    	; 1087      {
 506                    	; 1088      int index;
 507                    	; 1089      int entryidx;
 508                    	; 1090      int hasname;
 509                    	; 1091      unsigned int block;
 510                    	; 1092      unsigned char *rxdata;
 511                    	; 1093      unsigned char *entryptr;
 512                    	; 1094      unsigned char tstzero = 0;
 513                    	; 1095      unsigned long flba;
 514                    	; 1096      unsigned long llba;
 515                    	; 1097  
 516                    	; 1098      block = 2 + (entryno / 4);
 517                    	; 1099      if ((curblkno != block) || !curblkok)
 518                    	; 1100          {
 519                    	; 1101          if (!sdread(sdrdbuf, block))
 520                    	; 1102              {
 521                    	; 1103              if (sdtestflg)
 522                    	; 1104                  {
 523                    	; 1105                  printf("Can't read GPT entry block\n");
 524                    	; 1106                  return (NO);
 525                    	; 1107                  } /* sdtestflg */
 526                    	; 1108              }
 527                    	; 1109          curblkno = block;
 528                    	; 1110          curblkok = YES;
 529                    	; 1111          }
 530                    	; 1112      rxdata = sdrdbuf;
 531                    	; 1113      entryptr = rxdata + (128 * (entryno % 4));
 532                    	; 1114      for (index = 0; index < 16; index++)
 533                    	; 1115          tstzero |= entryptr[index];
 534                    	; 1116      if (sdtestflg)
 535                    	; 1117          {
 536                    	; 1118          printf("GPT partition entry %d:", entryno + 1);
 537                    	; 1119          } /* sdtestflg */
 538                    	; 1120      if (!tstzero)
 539                    	; 1121          {
 540                    	; 1122          if (sdtestflg)
 541                    	; 1123              {
 542                    	; 1124              printf(" Not used entry\n");
 543                    	; 1125              } /* sdtestflg */
 544                    	; 1126          return (NO);
 545                    	; 1127          }
 546                    	; 1128      if (sdtestflg)
 547                    	; 1129          {
 548                    	; 1130          printf("\n  Partition type GUID: ");
 549                    	; 1131          prtguid(entryptr);
 550                    	; 1132          printf("\n  [");
 551                    	; 1133          for (index = 0; index < 16; index++)
 552                    	; 1134              printf("%02x ", entryptr[index]);
 553                    	; 1135          printf("\b]");
 554                    	; 1136          printf("\n  Unique partition GUID: ");
 555                    	; 1137          prtguid(entryptr + 16);
 556                    	; 1138          printf("\n  [");
 557                    	; 1139          for (index = 0; index < 16; index++)
 558                    	; 1140              printf("%02x ", (entryptr + 16)[index]);
 559                    	; 1141          printf("\b]");
 560                    	; 1142          printf("\n  First LBA: ");
 561                    	; 1143          /* lower 32 bits of LBA should be sufficient (I hope) */
 562                    	; 1144          } /* sdtestflg */
 563                    	; 1145      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
 564                    	; 1146             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
 565                    	; 1147      if (sdtestflg)
 566                    	; 1148          {
 567                    	; 1149          printf("%lu", flba);
 568                    	; 1150          printf(" [");
 569                    	; 1151          for (index = 32; index < (32 + 8); index++)
 570                    	; 1152              printf("%02x ", entryptr[index]);
 571                    	; 1153          printf("\b]");
 572                    	; 1154          printf("\n  Last LBA: ");
 573                    	; 1155          } /* sdtestflg */
 574                    	; 1156      /* lower 32 bits of LBA should be sufficient (I hope) */
 575                    	; 1157      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
 576                    	; 1158             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
 577                    	; 1159  
 578                    	; 1160      if (entryptr[48] & 0x04)
 579                    	; 1161          dskmap[partdsk].bootable = YES;
 580                    	; 1162      dskmap[partdsk].partype = PARTGPT;
 581                    	; 1163      dskmap[partdsk].dskletter = 'A' + partdsk;
 582                    	; 1164      dskmap[partdsk].dskstart = flba;
 583                    	; 1165      dskmap[partdsk].dskend = llba;
 584                    	; 1166      dskmap[partdsk].dsksize = llba - flba + 1;
 585                    	; 1167      memcpy(dskmap[partdsk].dsktype, entryptr, 16);
 586                    	; 1168      partdsk++;
 587                    	; 1169  
 588                    	; 1170      if (sdtestflg)
 589                    	; 1171          {
 590                    	; 1172          printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
 591                    	; 1173          printf(" [");
 592                    	; 1174          for (index = 40; index < (40 + 8); index++)
 593                    	; 1175              printf("%02x ", entryptr[index]);
 594                    	; 1176          printf("\b]");
 595                    	; 1177          printf("\n  Attribute flags: [");
 596                    	; 1178          /* bits 0 - 2 and 60 - 63 should be decoded */
 597                    	; 1179          for (index = 0; index < 8; index++)
 598                    	; 1180              {
 599                    	; 1181              entryidx = index + 48;
 600                    	; 1182              printf("%02x ", entryptr[entryidx]);
 601                    	; 1183              }
 602                    	; 1184          printf("\b]\n  Partition name:  ");
 603                    	; 1185          } /* sdtestflg */
 604                    	; 1186      /* partition name is in UTF-16LE code units */
 605                    	; 1187      hasname = NO;
 606                    	; 1188      for (index = 0; index < 72; index += 2)
 607                    	; 1189          {
 608                    	; 1190          entryidx = index + 56;
 609                    	; 1191          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
 610                    	; 1192              break;
 611                    	; 1193          if (sdtestflg)
 612                    	; 1194              {
 613                    	; 1195              if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
 614                    	; 1196                  putchar(entryptr[entryidx]);
 615                    	; 1197              else
 616                    	; 1198                  putchar('.');
 617                    	; 1199              } /* sdtestflg */
 618                    	; 1200          hasname = YES;
 619                    	; 1201          }
 620                    	; 1202      if (sdtestflg)
 621                    	; 1203          {
 622                    	; 1204          if (!hasname)
 623                    	; 1205              printf("name field empty");
 624                    	; 1206          printf("\n");
 625                    	; 1207          printf("   [");
 626                    	; 1208          for (index = 0; index < 72; index++)
 627                    	; 1209              {
 628                    	; 1210              if (((index & 0xf) == 0) && (index != 0))
 629                    	; 1211                  printf("\n    ");
 630                    	; 1212              entryidx = index + 56;
 631                    	; 1213              printf("%02x ", entryptr[entryidx]);
 632                    	; 1214              }
 633                    	; 1215          printf("\b]\n");
 634                    	; 1216          } /* sdtestflg */
 635                    	; 1217      return (YES);
 636                    	; 1218      }
 637                    	; 1219  
 638                    	; 1220  /* Analyze and print GPT header
 639                    	; 1221   */
 640                    	; 1222  void sdgpthdr(unsigned long block)
 641                    	; 1223      {
 642                    	; 1224      int index;
 643                    	; 1225      unsigned int partno;
 644                    	; 1226      unsigned char *rxdata;
 645                    	; 1227      unsigned long entries;
 646                    	; 1228  
 647                    	; 1229      if (sdtestflg)
 648                    	; 1230          {
 649                    	; 1231          printf("GPT header\n");
 650                    	; 1232          } /* sdtestflg */
 651                    	; 1233      if (!sdread(sdrdbuf, block))
 652                    	; 1234          {
 653                    	; 1235          if (sdtestflg)
 654                    	; 1236              {
 655                    	; 1237              printf("Can't read GPT partition table header\n");
 656                    	; 1238              } /* sdtestflg */
 657                    	; 1239          return;
 658                    	; 1240          }
 659                    	; 1241      curblkno = block;
 660                    	; 1242      curblkok = YES;
 661                    	; 1243  
 662                    	; 1244      rxdata = sdrdbuf;
 663                    	; 1245      if (sdtestflg)
 664                    	; 1246          {
 665                    	; 1247          printf("  Signature: %.8s\n", &rxdata[0]);
 666                    	; 1248          printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
 667                    	; 1249                 (int)rxdata[8] * ((int)rxdata[9] << 8),
 668                    	; 1250                 (int)rxdata[10] + ((int)rxdata[11] << 8),
 669                    	; 1251                 rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
 670                    	; 1252          entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
 671                    	; 1253                    ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
 672                    	; 1254          printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
 673                    	; 1255          } /* sdtestflg */
 674                    	; 1256      for (partno = 0; (partno < 16) && (partdsk < 16); partno++)
 675                    	; 1257          {
 676                    	; 1258          if (!prtgptent(partno))
 677                    	; 1259              {
 678                    	; 1260              if (!sdtestflg)
 679                    	; 1261                  {
 680                    	; 1262                  /* go through all entries if compiled as test program */
 681                    	; 1263                  return;
 682                    	; 1264                  } /* sdtestflg */
 683                    	; 1265              }
 684                    	; 1266          }
 685                    	; 1267      if (sdtestflg)
 686                    	; 1268          {
 687                    	; 1269          printf("First 16 GPT entries scanned\n");
 688                    	; 1270          } /* sdtestflg */
 689                    	; 1271      }
 690                    	; 1272  
 691                    	; 1273  /* Analyze and print MBR partition entry
 692                    	; 1274   * Returns:
 693                    	; 1275   *    -1 if errror - should not happen
 694                    	; 1276   *     0 if not used entry
 695                    	; 1277   *     1 if MBR entry
 696                    	; 1278   *     2 if EBR entry
 697                    	; 1279   *     3 if GTP entry
 698                    	; 1280   */
 699                    	; 1281  int sdmbrentry(unsigned char *partptr)
 700                    	; 1282      {
 701                    	; 1283      int index;
 702                    	; 1284      int parttype;
 703                    	; 1285      unsigned long lbastart;
 704                    	; 1286      unsigned long lbasize;
 705                    	; 1287  
 706                    	; 1288      parttype = PARTMBR;
 707                    	; 1289      if (!partptr[4])
 708                    	; 1290          {
 709                    	; 1291          if (sdtestflg)
 710                    	; 1292              {
 711                    	; 1293              printf("Not used entry\n");
 712                    	; 1294              } /* sdtestflg */
 713                    	; 1295          return (PARTZRO);
 714                    	; 1296          }
 715                    	; 1297      if (sdtestflg)
 716                    	; 1298          {
 717                    	; 1299          printf("Boot indicator: 0x%02x, System ID: 0x%02x\n",
 718                    	; 1300                 partptr[0], partptr[4]);
 719                    	; 1301  
 720                    	; 1302          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
 721                    	; 1303              {
 722                    	; 1304              printf("  Extended partition entry\n");
 723                    	; 1305              }
 724                    	; 1306          if (partptr[0] & 0x01)
 725                    	; 1307              {
 726                    	; 1308              printf("  Unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
 727                    	; 1309              /* this is however discussed
 728                    	; 1310                 https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
 729                    	; 1311              */
 730                    	; 1312              }
 731                    	; 1313          else
 732                    	; 1314              {
 733                    	; 1315              printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
 734                    	; 1316                     partptr[1], partptr[2], partptr[3],
 735                    	; 1317                     ((partptr[2] & 0xc0) >> 2) + partptr[3],
 736                    	; 1318                     partptr[1],
 737                    	; 1319                     partptr[2] & 0x3f);
 738                    	; 1320              printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
 739                    	; 1321                     partptr[5], partptr[6], partptr[7],
 740                    	; 1322                     ((partptr[6] & 0xc0) >> 2) + partptr[7],
 741                    	; 1323                     partptr[5],
 742                    	; 1324                     partptr[6] & 0x3f);
 743                    	; 1325              }
 744                    	; 1326          } /* sdtestflg */
 745                    	; 1327      /* not showing high 16 bits if 48 bit LBA */
 746                    	; 1328      lbastart = (unsigned long)partptr[8] +
 747                    	; 1329                 ((unsigned long)partptr[9] << 8) +
 748                    	; 1330                 ((unsigned long)partptr[10] << 16) +
 749                    	; 1331                 ((unsigned long)partptr[11] << 24);
 750                    	; 1332      lbasize = (unsigned long)partptr[12] +
 751                    	; 1333                ((unsigned long)partptr[13] << 8) +
 752                    	; 1334                ((unsigned long)partptr[14] << 16) +
 753                    	; 1335                ((unsigned long)partptr[15] << 24);
 754                    	; 1336  
 755                    	; 1337      if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
 756                    	; 1338          {
 757                    	; 1339          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
 758                    	; 1340              {
 759                    	; 1341              parttype = PARTEBR;
 760                    	; 1342              if (curblkno == 0) /* points to EBR in the MBR */
 761                    	; 1343                  {
 762                    	; 1344                  ebrnext = 0;
 763                    	; 1345                  dskmap[partdsk].partype = EBRCONT;
 764                    	; 1346                  dskmap[partdsk].dskletter = 'A' + partdsk;
 765                    	; 1347                  dskmap[partdsk].dskstart = lbastart;
 766                    	; 1348                  dskmap[partdsk].dskend = lbastart + lbasize - 1;
 767                    	; 1349                  dskmap[partdsk].dsksize = lbasize;
 768                    	; 1350                  dskmap[partdsk].dsktype[0] = partptr[4];
 769                    	; 1351                  partdsk++;
 770                    	; 1352                  ebrrecs[ebrrecidx++] = lbastart; /* save to handle later */
 771                    	; 1353                  }
 772                    	; 1354              else
 773                    	; 1355                  {
 774                    	; 1356                  ebrnext = curblkno + lbastart;
 775                    	; 1357                  }
 776                    	; 1358              }
 777                    	; 1359          else
 778                    	; 1360              {
 779                    	; 1361              if (partptr[0] & 0x80)
 780                    	; 1362                  dskmap[partdsk].bootable = YES;
 781                    	; 1363              if (curblkno == 0)
 782                    	; 1364                  dskmap[partdsk].partype = PARTMBR;
 783                    	; 1365              else
 784                    	; 1366                  dskmap[partdsk].partype = PARTEBR;
 785                    	; 1367              dskmap[partdsk].dskletter = 'A' + partdsk;
 786                    	; 1368              dskmap[partdsk].dskstart = curblkno + lbastart;
 787                    	; 1369              dskmap[partdsk].dskend = curblkno + lbastart + lbasize - 1;
 788                    	; 1370              dskmap[partdsk].dsksize = lbasize;
 789                    	; 1371              dskmap[partdsk].dsktype[0] = partptr[4];
 790                    	; 1372              partdsk++;
 791                    	; 1373              }
 792                    	; 1374          }
 793                    	; 1375  
 794                    	; 1376      if (sdtestflg)
 795                    	; 1377          {
 796                    	; 1378          printf("  partition start LBA: %lu [%08lx]\n",
 797                    	; 1379                 curblkno + lbastart, curblkno + lbastart);
 798                    	; 1380          printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
 799                    	; 1381                 lbasize, lbasize, lbasize >> 11);
 800                    	; 1382          } /* sdtestflg */
 801                    	; 1383      if (partptr[4] == 0xee) /* GPT partitions */
 802                    	; 1384          {
 803                    	; 1385          parttype = PARTGPT;
 804                    	; 1386          if (sdtestflg)
 805                    	; 1387              {
 806                    	; 1388              printf("GTP partitions\n");
 807                    	; 1389              } /* sdtestflg */
 808                    	; 1390          sdgpthdr(lbastart); /* handle GTP partitions */
 809                    	; 1391          /* re-read MBR on sector 0
 810                    	; 1392             This is probably not needed as there
 811                    	; 1393             is only one entry (the first one)
 812                    	; 1394             in the MBR when using GPT */
 813                    	; 1395          if (sdread(sdrdbuf, 0))
 814                    	; 1396              {
 815                    	; 1397              curblkno = 0;
 816    3D28  97        		sub	a
 817    3D29  320200    		ld	(_curblkno),a
 818    3D2C  320300    		ld	(_curblkno+1),a
 819    3D2F  320400    		ld	(_curblkno+2),a
 820    3D32  320500    		ld	(_curblkno+3),a
 821    3D35  221000    		ld	(_curblkok),hl
 822                    	; 1398              curblkok = YES;
 823                    	; 1399              }
 824                    	; 1400          else
 825    3D38  1813      		jr	L1425
 826                    	L1625:
 827                    	; 1401              {
 828                    	; 1402              if (sdtestflg)
 829    3D3A  2A0000    		ld	hl,(_sdtestflg)
 830    3D3D  7C        		ld	a,h
 831    3D3E  B5        		or	l
 832    3D3F  2806      		jr	z,L1035
 833                    	; 1403                  {
 834                    	; 1404                  printf("  can't read MBR on sector 0\n");
 835    3D41  21C236    		ld	hl,L5052
 836    3D44  CD0000    		call	_printf
 837                    	L1035:
 838                    	; 1405                  } /* sdtestflg */
 839                    	; 1406              return(-1);
 840    3D47  01FFFF    		ld	bc,65535
 841    3D4A  C30000    		jp	c.rets
 842                    	L1425:
 843                    	; 1407              }
 844                    	; 1408          }
 845                    	; 1409      return (parttype);
 846    3D4D  DD4EF6    		ld	c,(ix-10)
 847    3D50  DD46F7    		ld	b,(ix-9)
 848    3D53  C30000    		jp	c.rets
 849                    	L5152:
 850    3D56  4D        		.byte	77
 851    3D57  42        		.byte	66
 852    3D58  52        		.byte	82
 853    3D59  00        		.byte	0
 854                    	L5252:
 855    3D5A  45        		.byte	69
 856    3D5B  42        		.byte	66
 857    3D5C  52        		.byte	82
 858    3D5D  00        		.byte	0
 859                    	L5352:
 860    3D5E  52        		.byte	82
 861    3D5F  65        		.byte	101
 862    3D60  61        		.byte	97
 863    3D61  64        		.byte	100
 864    3D62  20        		.byte	32
 865    3D63  25        		.byte	37
 866    3D64  73        		.byte	115
 867    3D65  20        		.byte	32
 868    3D66  66        		.byte	102
 869    3D67  72        		.byte	114
 870    3D68  6F        		.byte	111
 871    3D69  6D        		.byte	109
 872    3D6A  20        		.byte	32
 873    3D6B  73        		.byte	115
 874    3D6C  65        		.byte	101
 875    3D6D  63        		.byte	99
 876    3D6E  74        		.byte	116
 877    3D6F  6F        		.byte	111
 878    3D70  72        		.byte	114
 879    3D71  20        		.byte	32
 880    3D72  25        		.byte	37
 881    3D73  6C        		.byte	108
 882    3D74  75        		.byte	117
 883    3D75  0A        		.byte	10
 884    3D76  00        		.byte	0
 885                    	L5452:
 886    3D77  20        		.byte	32
 887    3D78  20        		.byte	32
 888    3D79  63        		.byte	99
 889    3D7A  61        		.byte	97
 890    3D7B  6E        		.byte	110
 891    3D7C  27        		.byte	39
 892    3D7D  74        		.byte	116
 893    3D7E  20        		.byte	32
 894    3D7F  72        		.byte	114
 895    3D80  65        		.byte	101
 896    3D81  61        		.byte	97
 897    3D82  64        		.byte	100
 898    3D83  20        		.byte	32
 899    3D84  25        		.byte	37
 900    3D85  73        		.byte	115
 901    3D86  20        		.byte	32
 902    3D87  73        		.byte	115
 903    3D88  65        		.byte	101
 904    3D89  63        		.byte	99
 905    3D8A  74        		.byte	116
 906    3D8B  6F        		.byte	111
 907    3D8C  72        		.byte	114
 908    3D8D  20        		.byte	32
 909    3D8E  25        		.byte	37
 910    3D8F  6C        		.byte	108
 911    3D90  75        		.byte	117
 912    3D91  0A        		.byte	10
 913    3D92  00        		.byte	0
 914                    	L5552:
 915    3D93  20        		.byte	32
 916    3D94  20        		.byte	32
 917    3D95  6E        		.byte	110
 918    3D96  6F        		.byte	111
 919    3D97  20        		.byte	32
 920    3D98  25        		.byte	37
 921    3D99  73        		.byte	115
 922    3D9A  20        		.byte	32
 923    3D9B  62        		.byte	98
 924    3D9C  6F        		.byte	111
 925    3D9D  6F        		.byte	111
 926    3D9E  74        		.byte	116
 927    3D9F  20        		.byte	32
 928    3DA0  73        		.byte	115
 929    3DA1  69        		.byte	105
 930    3DA2  67        		.byte	103
 931    3DA3  6E        		.byte	110
 932    3DA4  61        		.byte	97
 933    3DA5  74        		.byte	116
 934    3DA6  75        		.byte	117
 935    3DA7  72        		.byte	114
 936    3DA8  65        		.byte	101
 937    3DA9  20        		.byte	32
 938    3DAA  66        		.byte	102
 939    3DAB  6F        		.byte	111
 940    3DAC  75        		.byte	117
 941    3DAD  6E        		.byte	110
 942    3DAE  64        		.byte	100
 943    3DAF  0A        		.byte	10
 944    3DB0  00        		.byte	0
 945                    	L5652:
 946    3DB1  20        		.byte	32
 947    3DB2  20        		.byte	32
 948    3DB3  64        		.byte	100
 949    3DB4  69        		.byte	105
 950    3DB5  73        		.byte	115
 951    3DB6  6B        		.byte	107
 952    3DB7  20        		.byte	32
 953    3DB8  69        		.byte	105
 954    3DB9  64        		.byte	100
 955    3DBA  65        		.byte	101
 956    3DBB  6E        		.byte	110
 957    3DBC  74        		.byte	116
 958    3DBD  69        		.byte	105
 959    3DBE  66        		.byte	102
 960    3DBF  69        		.byte	105
 961    3DC0  65        		.byte	101
 962    3DC1  72        		.byte	114
 963    3DC2  3A        		.byte	58
 964    3DC3  20        		.byte	32
 965    3DC4  30        		.byte	48
 966    3DC5  78        		.byte	120
 967    3DC6  25        		.byte	37
 968    3DC7  30        		.byte	48
 969    3DC8  32        		.byte	50
 970    3DC9  78        		.byte	120
 971    3DCA  25        		.byte	37
 972    3DCB  30        		.byte	48
 973    3DCC  32        		.byte	50
 974    3DCD  78        		.byte	120
 975    3DCE  25        		.byte	37
 976    3DCF  30        		.byte	48
 977    3DD0  32        		.byte	50
 978    3DD1  78        		.byte	120
 979    3DD2  25        		.byte	37
 980    3DD3  30        		.byte	48
 981    3DD4  32        		.byte	50
 982    3DD5  78        		.byte	120
 983    3DD6  0A        		.byte	10
 984    3DD7  00        		.byte	0
 985                    	L5752:
 986    3DD8  25        		.byte	37
 987    3DD9  73        		.byte	115
 988    3DDA  20        		.byte	32
 989    3DDB  70        		.byte	112
 990    3DDC  61        		.byte	97
 991    3DDD  72        		.byte	114
 992    3DDE  74        		.byte	116
 993    3DDF  69        		.byte	105
 994    3DE0  74        		.byte	116
 995    3DE1  69        		.byte	105
 996    3DE2  6F        		.byte	111
 997    3DE3  6E        		.byte	110
 998    3DE4  20        		.byte	32
 999    3DE5  65        		.byte	101
1000    3DE6  6E        		.byte	110
1001    3DE7  74        		.byte	116
1002    3DE8  72        		.byte	114
1003    3DE9  79        		.byte	121
1004    3DEA  20        		.byte	32
1005    3DEB  25        		.byte	37
1006    3DEC  64        		.byte	100
1007    3DED  3A        		.byte	58
1008    3DEE  20        		.byte	32
1009    3DEF  00        		.byte	0
1010                    	L5062:
1011    3DF0  20        		.byte	32
1012    3DF1  20        		.byte	32
1013    3DF2  63        		.byte	99
1014    3DF3  61        		.byte	97
1015    3DF4  6E        		.byte	110
1016    3DF5  27        		.byte	39
1017    3DF6  74        		.byte	116
1018    3DF7  20        		.byte	32
1019    3DF8  72        		.byte	114
1020    3DF9  65        		.byte	101
1021    3DFA  61        		.byte	97
1022    3DFB  64        		.byte	100
1023    3DFC  20        		.byte	32
1024    3DFD  25        		.byte	37
1025    3DFE  73        		.byte	115
1026    3DFF  20        		.byte	32
1027    3E00  73        		.byte	115
1028    3E01  65        		.byte	101
1029    3E02  63        		.byte	99
1030    3E03  74        		.byte	116
1031    3E04  6F        		.byte	111
1032    3E05  72        		.byte	114
1033    3E06  20        		.byte	32
1034    3E07  25        		.byte	37
1035    3E08  6C        		.byte	108
1036    3E09  75        		.byte	117
1037    3E0A  0A        		.byte	10
1038    3E0B  00        		.byte	0
1039                    	L5162:
1040    3E0C  45        		.byte	69
1041    3E0D  42        		.byte	66
1042    3E0E  52        		.byte	82
1043    3E0F  20        		.byte	32
1044    3E10  70        		.byte	112
1045    3E11  61        		.byte	97
1046    3E12  72        		.byte	114
1047    3E13  74        		.byte	116
1048    3E14  69        		.byte	105
1049    3E15  74        		.byte	116
1050    3E16  69        		.byte	105
1051    3E17  6F        		.byte	111
1052    3E18  6E        		.byte	110
1053    3E19  20        		.byte	32
1054    3E1A  65        		.byte	101
1055    3E1B  6E        		.byte	110
1056    3E1C  74        		.byte	116
1057    3E1D  72        		.byte	114
1058    3E1E  79        		.byte	121
1059    3E1F  20        		.byte	32
1060    3E20  25        		.byte	37
1061    3E21  64        		.byte	100
1062    3E22  3A        		.byte	58
1063    3E23  20        		.byte	32
1064    3E24  00        		.byte	0
1065                    	L5262:
1066    3E25  45        		.byte	69
1067    3E26  6D        		.byte	109
1068    3E27  70        		.byte	112
1069    3E28  74        		.byte	116
1070    3E29  79        		.byte	121
1071    3E2A  20        		.byte	32
1072    3E2B  70        		.byte	112
1073    3E2C  61        		.byte	97
1074    3E2D  72        		.byte	114
1075    3E2E  74        		.byte	116
1076    3E2F  69        		.byte	105
1077    3E30  74        		.byte	116
1078    3E31  69        		.byte	105
1079    3E32  6F        		.byte	111
1080    3E33  6E        		.byte	110
1081    3E34  20        		.byte	32
1082    3E35  65        		.byte	101
1083    3E36  6E        		.byte	110
1084    3E37  74        		.byte	116
1085    3E38  72        		.byte	114
1086    3E39  79        		.byte	121
1087    3E3A  0A        		.byte	10
1088    3E3B  00        		.byte	0
1089                    	L5362:
1090    3E3C  45        		.byte	69
1091    3E3D  42        		.byte	66
1092    3E3E  52        		.byte	82
1093    3E3F  20        		.byte	32
1094    3E40  63        		.byte	99
1095    3E41  68        		.byte	104
1096    3E42  61        		.byte	97
1097    3E43  69        		.byte	105
1098    3E44  6E        		.byte	110
1099    3E45  0A        		.byte	10
1100    3E46  00        		.byte	0
1101                    	L5462:
1102    3E47  20        		.byte	32
1103    3E48  20        		.byte	32
1104    3E49  63        		.byte	99
1105    3E4A  61        		.byte	97
1106    3E4B  6E        		.byte	110
1107    3E4C  27        		.byte	39
1108    3E4D  74        		.byte	116
1109    3E4E  20        		.byte	32
1110    3E4F  72        		.byte	114
1111    3E50  65        		.byte	101
1112    3E51  61        		.byte	97
1113    3E52  64        		.byte	100
1114    3E53  20        		.byte	32
1115    3E54  25        		.byte	37
1116    3E55  73        		.byte	115
1117    3E56  20        		.byte	32
1118    3E57  73        		.byte	115
1119    3E58  65        		.byte	101
1120    3E59  63        		.byte	99
1121    3E5A  74        		.byte	116
1122    3E5B  6F        		.byte	111
1123    3E5C  72        		.byte	114
1124    3E5D  20        		.byte	32
1125    3E5E  25        		.byte	37
1126    3E5F  6C        		.byte	108
1127    3E60  75        		.byte	117
1128    3E61  0A        		.byte	10
1129    3E62  00        		.byte	0
1130                    	L5562:
1131    3E63  45        		.byte	69
1132    3E64  42        		.byte	66
1133    3E65  52        		.byte	82
1134    3E66  20        		.byte	32
1135    3E67  63        		.byte	99
1136    3E68  68        		.byte	104
1137    3E69  61        		.byte	97
1138    3E6A  69        		.byte	105
1139    3E6B  6E        		.byte	110
1140    3E6C  65        		.byte	101
1141    3E6D  64        		.byte	100
1142    3E6E  20        		.byte	32
1143    3E6F  20        		.byte	32
1144    3E70  70        		.byte	112
1145    3E71  61        		.byte	97
1146    3E72  72        		.byte	114
1147    3E73  74        		.byte	116
1148    3E74  69        		.byte	105
1149    3E75  74        		.byte	116
1150    3E76  69        		.byte	105
1151    3E77  6F        		.byte	111
1152    3E78  6E        		.byte	110
1153    3E79  20        		.byte	32
1154    3E7A  65        		.byte	101
1155    3E7B  6E        		.byte	110
1156    3E7C  74        		.byte	116
1157    3E7D  72        		.byte	114
1158    3E7E  79        		.byte	121
1159    3E7F  20        		.byte	32
1160    3E80  25        		.byte	37
1161    3E81  64        		.byte	100
1162    3E82  3A        		.byte	58
1163    3E83  20        		.byte	32
1164    3E84  00        		.byte	0
1165                    	; 1410      }
1166                    	; 1411  
1167                    	; 1412  /* Read and analyze MBR/EBR partition sector block
1168                    	; 1413   * and go through and print partition entries.
1169                    	; 1414   */
1170                    	; 1415  void sdmbrpart(unsigned long sector)
1171                    	; 1416      {
1172                    	_sdmbrpart:
1173    3E85  CD0000    		call	c.savs
1174    3E88  21EEFF    		ld	hl,65518
1175    3E8B  39        		add	hl,sp
1176    3E8C  F9        		ld	sp,hl
1177                    	; 1417      int partidx;  /* partition index 1 - 4 */
1178                    	; 1418      int cpartidx; /* chain partition index 1 - 4 */
1179                    	; 1419      int chainidx;
1180                    	; 1420      int enttype;
1181                    	; 1421      unsigned char *entp; /* pointer to partition entry */
1182                    	; 1422      char *mbrebr;
1183                    	; 1423  
1184                    	; 1424      if (sdtestflg)
1185    3E8D  2A0000    		ld	hl,(_sdtestflg)
1186    3E90  7C        		ld	a,h
1187    3E91  B5        		or	l
1188    3E92  2840      		jr	z,L1135
1189                    	; 1425          {
1190                    	; 1426          if (sector == 0) /* if sector 0 it is MBR else it is EBR */
1191    3E94  DD7E04    		ld	a,(ix+4)
1192    3E97  DDB605    		or	(ix+5)
1193    3E9A  DDB606    		or	(ix+6)
1194    3E9D  DDB607    		or	(ix+7)
1195    3EA0  200B      		jr	nz,L1235
1196                    	; 1427              mbrebr = "MBR";
1197    3EA2  21563D    		ld	hl,L5152
1198    3EA5  DD75EE    		ld	(ix-18),l
1199    3EA8  DD74EF    		ld	(ix-17),h
1200                    	; 1428          else
1201    3EAB  1809      		jr	L1335
1202                    	L1235:
1203                    	; 1429              mbrebr = "EBR";
1204    3EAD  215A3D    		ld	hl,L5252
1205    3EB0  DD75EE    		ld	(ix-18),l
1206    3EB3  DD74EF    		ld	(ix-17),h
1207                    	L1335:
1208                    	; 1430          printf("Read %s from sector %lu\n", mbrebr, sector);
1209    3EB6  DD6607    		ld	h,(ix+7)
1210    3EB9  DD6E06    		ld	l,(ix+6)
1211    3EBC  E5        		push	hl
1212    3EBD  DD6605    		ld	h,(ix+5)
1213    3EC0  DD6E04    		ld	l,(ix+4)
1214    3EC3  E5        		push	hl
1215    3EC4  DD6EEE    		ld	l,(ix-18)
1216    3EC7  DD66EF    		ld	h,(ix-17)
1217    3ECA  E5        		push	hl
1218    3ECB  215E3D    		ld	hl,L5352
1219    3ECE  CD0000    		call	_printf
1220    3ED1  F1        		pop	af
1221    3ED2  F1        		pop	af
1222    3ED3  F1        		pop	af
1223                    	L1135:
1224                    	; 1431          } /* sdtestflg */
1225                    	; 1432      if (sdread(sdrdbuf, sector))
1226    3ED4  DD6607    		ld	h,(ix+7)
1227    3ED7  DD6E06    		ld	l,(ix+6)
1228    3EDA  E5        		push	hl
1229    3EDB  DD6605    		ld	h,(ix+5)
1230    3EDE  DD6E04    		ld	l,(ix+4)
1231    3EE1  E5        		push	hl
1232    3EE2  214C00    		ld	hl,_sdrdbuf
1233    3EE5  CDE120    		call	_sdread
1234    3EE8  F1        		pop	af
1235    3EE9  F1        		pop	af
1236    3EEA  79        		ld	a,c
1237    3EEB  B0        		or	b
1238    3EEC  2827      		jr	z,L1435
1239                    	; 1433          {
1240                    	; 1434          curblkno = sector;
1241    3EEE  210200    		ld	hl,_curblkno
1242    3EF1  E5        		push	hl
1243    3EF2  DDE5      		push	ix
1244    3EF4  C1        		pop	bc
1245    3EF5  210400    		ld	hl,4
1246    3EF8  09        		add	hl,bc
1247    3EF9  E5        		push	hl
1248    3EFA  CD0000    		call	c.mvl
1249    3EFD  F1        		pop	af
1250                    	; 1435          curblkok = YES;
1251    3EFE  210100    		ld	hl,1
1252    3F01  221000    		ld	(_curblkok),hl
1253                    	; 1436          }
1254                    	; 1437      else
1255                    	; 1438          {
1256                    	; 1439          if (sdtestflg)
1257                    	; 1440              {
1258                    	; 1441              printf("  can't read %s sector %lu\n", mbrebr, sector);
1259                    	; 1442              } /* sdtestflg */
1260                    	; 1443          return;
1261                    	; 1444          }
1262                    	; 1445      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
1263    3F04  3A4A02    		ld	a,(_sdrdbuf+510)
1264    3F07  FE55      		cp	85
1265    3F09  2032      		jr	nz,L1045
1266    3F0B  3A4B02    		ld	a,(_sdrdbuf+511)
1267    3F0E  FEAA      		cp	170
1268    3F10  CA553F    		jp	z,L1735
1269    3F13  1828      		jr	L1045
1270                    	L1435:
1271    3F15  2A0000    		ld	hl,(_sdtestflg)
1272    3F18  7C        		ld	a,h
1273    3F19  B5        		or	l
1274    3F1A  281E      		jr	z,L1635
1275    3F1C  DD6607    		ld	h,(ix+7)
1276    3F1F  DD6E06    		ld	l,(ix+6)
1277    3F22  E5        		push	hl
1278    3F23  DD6605    		ld	h,(ix+5)
1279    3F26  DD6E04    		ld	l,(ix+4)
1280    3F29  E5        		push	hl
1281    3F2A  DD6EEE    		ld	l,(ix-18)
1282    3F2D  DD66EF    		ld	h,(ix-17)
1283    3F30  E5        		push	hl
1284    3F31  21773D    		ld	hl,L5452
1285    3F34  CD0000    		call	_printf
1286    3F37  F1        		pop	af
1287    3F38  F1        		pop	af
1288    3F39  F1        		pop	af
1289                    	L1635:
1290    3F3A  C30000    		jp	c.rets
1291                    	L1045:
1292                    	; 1446          {
1293                    	; 1447          if (sdtestflg)
1294    3F3D  2A0000    		ld	hl,(_sdtestflg)
1295    3F40  7C        		ld	a,h
1296    3F41  B5        		or	l
1297    3F42  280E      		jr	z,L1145
1298                    	; 1448              {
1299                    	; 1449              printf("  no %s boot signature found\n", mbrebr);
1300    3F44  DD6EEE    		ld	l,(ix-18)
1301    3F47  DD66EF    		ld	h,(ix-17)
1302    3F4A  E5        		push	hl
1303    3F4B  21933D    		ld	hl,L5552
1304    3F4E  CD0000    		call	_printf
1305    3F51  F1        		pop	af
1306                    	L1145:
1307                    	; 1450              } /* sdtestflg */
1308                    	; 1451          return;
1309    3F52  C30000    		jp	c.rets
1310                    	L1735:
1311                    	; 1452          }
1312                    	; 1453      if (curblkno == 0)
1313    3F55  210200    		ld	hl,_curblkno
1314    3F58  7E        		ld	a,(hl)
1315    3F59  23        		inc	hl
1316    3F5A  B6        		or	(hl)
1317    3F5B  23        		inc	hl
1318    3F5C  B6        		or	(hl)
1319    3F5D  23        		inc	hl
1320    3F5E  B6        		or	(hl)
1321    3F5F  203D      		jr	nz,L1245
1322                    	; 1454          {
1323                    	; 1455          memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
1324    3F61  210400    		ld	hl,4
1325    3F64  E5        		push	hl
1326    3F65  210402    		ld	hl,_sdrdbuf+440
1327    3F68  E5        		push	hl
1328    3F69  214C02    		ld	hl,_dsksign
1329    3F6C  CD0000    		call	_memcpy
1330    3F6F  F1        		pop	af
1331    3F70  F1        		pop	af
1332                    	; 1456          if (sdtestflg)
1333    3F71  2A0000    		ld	hl,(_sdtestflg)
1334    3F74  7C        		ld	a,h
1335    3F75  B5        		or	l
1336    3F76  2826      		jr	z,L1245
1337                    	; 1457              {
1338                    	; 1458  
1339                    	; 1459              printf("  disk identifier: 0x%02x%02x%02x%02x\n",
1340                    	; 1460                     dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
1341    3F78  3A4C02    		ld	a,(_dsksign)
1342    3F7B  4F        		ld	c,a
1343    3F7C  97        		sub	a
1344    3F7D  47        		ld	b,a
1345    3F7E  C5        		push	bc
1346    3F7F  3A4D02    		ld	a,(_dsksign+1)
1347    3F82  4F        		ld	c,a
1348    3F83  97        		sub	a
1349    3F84  47        		ld	b,a
1350    3F85  C5        		push	bc
1351    3F86  3A4E02    		ld	a,(_dsksign+2)
1352    3F89  4F        		ld	c,a
1353    3F8A  97        		sub	a
1354    3F8B  47        		ld	b,a
1355    3F8C  C5        		push	bc
1356    3F8D  3A4F02    		ld	a,(_dsksign+3)
1357    3F90  4F        		ld	c,a
1358    3F91  97        		sub	a
1359    3F92  47        		ld	b,a
1360    3F93  C5        		push	bc
1361    3F94  21B13D    		ld	hl,L5652
1362    3F97  CD0000    		call	_printf
1363    3F9A  F1        		pop	af
1364    3F9B  F1        		pop	af
1365    3F9C  F1        		pop	af
1366    3F9D  F1        		pop	af
1367                    	L1245:
1368                    	; 1461              } /* sdtestflg */
1369                    	; 1462          }
1370                    	; 1463      /* go through MBR partition entries until first empty */
1371                    	; 1464      /* !!as the MBR entry routine is called recusively a way is
1372                    	; 1465         needed to read sector 0 when going back to MBR if
1373                    	; 1466         there is a primary partition entry after an EBR entry!! */
1374                    	; 1467      entp = &sdrdbuf[0x01be] ;
1375    3F9E  210A02    		ld	hl,_sdrdbuf+446
1376    3FA1  DD75F0    		ld	(ix-16),l
1377    3FA4  DD74F1    		ld	(ix-15),h
1378                    	; 1468      for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
1379    3FA7  DD36F801  		ld	(ix-8),1
1380    3FAB  DD36F900  		ld	(ix-7),0
1381                    	L1445:
1382    3FAF  3E04      		ld	a,4
1383    3FB1  DD96F8    		sub	(ix-8)
1384    3FB4  3E00      		ld	a,0
1385    3FB6  DD9EF9    		sbc	a,(ix-7)
1386    3FB9  FA3540    		jp	m,L1545
1387    3FBC  3A0E00    		ld	a,(_partdsk)
1388    3FBF  D610      		sub	16
1389    3FC1  3A0F00    		ld	a,(_partdsk+1)
1390    3FC4  DE00      		sbc	a,0
1391    3FC6  F23540    		jp	p,L1545
1392                    	; 1469          {
1393                    	; 1470          if (sdtestflg)
1394    3FC9  2A0000    		ld	hl,(_sdtestflg)
1395    3FCC  7C        		ld	a,h
1396    3FCD  B5        		or	l
1397    3FCE  2836      		jr	z,L1055
1398                    	; 1471              {
1399                    	; 1472              printf("%s partition entry %d: ", mbrebr, partidx);
1400    3FD0  DD6EF8    		ld	l,(ix-8)
1401    3FD3  DD66F9    		ld	h,(ix-7)
1402    3FD6  E5        		push	hl
1403    3FD7  DD6EEE    		ld	l,(ix-18)
1404    3FDA  DD66EF    		ld	h,(ix-17)
1405    3FDD  E5        		push	hl
1406    3FDE  21D83D    		ld	hl,L5752
1407    3FE1  CD0000    		call	_printf
1408    3FE4  F1        		pop	af
1409    3FE5  F1        		pop	af
1410    3FE6  181E      		jr	L1055
1411                    	L1645:
1412    3FE8  DD34F8    		inc	(ix-8)
1413    3FEB  2003      		jr	nz,L661
1414    3FED  DD34F9    		inc	(ix-7)
1415                    	L661:
1416    3FF0  DD6EF0    		ld	l,(ix-16)
1417    3FF3  DD66F1    		ld	h,(ix-15)
1418    3FF6  7D        		ld	a,l
1419    3FF7  C610      		add	a,16
1420    3FF9  6F        		ld	l,a
1421    3FFA  7C        		ld	a,h
1422    3FFB  CE00      		adc	a,0
1423    3FFD  67        		ld	h,a
1424    3FFE  DD75F0    		ld	(ix-16),l
1425    4001  DD74F1    		ld	(ix-15),h
1426    4004  18A9      		jr	L1445
1427                    	L1055:
1428                    	; 1473              } /* sdtestflg */
1429                    	; 1474          enttype = sdmbrentry(entp);
1430    4006  DD6EF0    		ld	l,(ix-16)
1431    4009  DD66F1    		ld	h,(ix-15)
1432    400C  CDE036    		call	_sdmbrentry
1433    400F  DD71F2    		ld	(ix-14),c
1434    4012  DD70F3    		ld	(ix-13),b
1435                    	; 1475          if (enttype == -1) /* read error */
1436    4015  DD7EF2    		ld	a,(ix-14)
1437    4018  FEFF      		cp	255
1438    401A  2005      		jr	nz,L071
1439    401C  DD7EF3    		ld	a,(ix-13)
1440    401F  FEFF      		cp	255
1441                    	L071:
1442    4021  2003      		jr	nz,L1155
1443                    	; 1476                   return;
1444    4023  C30000    		jp	c.rets
1445                    	L1155:
1446                    	; 1477          else if (enttype == PARTZRO)
1447    4026  DD7EF2    		ld	a,(ix-14)
1448    4029  DDB6F3    		or	(ix-13)
1449    402C  20BA      		jr	nz,L1645
1450                    	; 1478              {
1451                    	; 1479              if (!sdtestflg)
1452    402E  2A0000    		ld	hl,(_sdtestflg)
1453    4031  7C        		ld	a,h
1454    4032  B5        		or	l
1455    4033  20B3      		jr	nz,L1645
1456                    	; 1480                  {
1457                    	; 1481                  /* if compiled as test program show also empty partitions */
1458                    	; 1482                  break;
1459                    	L1545:
1460                    	; 1483                  } /* sdtestflg */
1461                    	; 1484              }
1462                    	; 1485          }
1463                    	; 1486      /* now handle the previously saved EBR partition sectors */
1464                    	; 1487      for (partidx = 0; (partidx < ebrrecidx) && (partdsk < 16); partidx++)
1465    4035  DD36F800  		ld	(ix-8),0
1466    4039  DD36F900  		ld	(ix-7),0
1467                    	L1555:
1468    403D  211600    		ld	hl,_ebrrecidx
1469    4040  DD7EF8    		ld	a,(ix-8)
1470    4043  96        		sub	(hl)
1471    4044  DD7EF9    		ld	a,(ix-7)
1472    4047  23        		inc	hl
1473    4048  9E        		sbc	a,(hl)
1474    4049  F29E42    		jp	p,L1655
1475    404C  3A0E00    		ld	a,(_partdsk)
1476    404F  D610      		sub	16
1477    4051  3A0F00    		ld	a,(_partdsk+1)
1478    4054  DE00      		sbc	a,0
1479    4056  F29E42    		jp	p,L1655
1480                    	; 1488          {
1481                    	; 1489          if (sdread(sdrdbuf, ebrrecs[partidx]))
1482    4059  DD6EF8    		ld	l,(ix-8)
1483    405C  DD66F9    		ld	h,(ix-7)
1484    405F  29        		add	hl,hl
1485    4060  29        		add	hl,hl
1486    4061  011800    		ld	bc,_ebrrecs
1487    4064  09        		add	hl,bc
1488    4065  23        		inc	hl
1489    4066  23        		inc	hl
1490    4067  4E        		ld	c,(hl)
1491    4068  23        		inc	hl
1492    4069  46        		ld	b,(hl)
1493    406A  C5        		push	bc
1494    406B  2B        		dec	hl
1495    406C  2B        		dec	hl
1496    406D  2B        		dec	hl
1497    406E  4E        		ld	c,(hl)
1498    406F  23        		inc	hl
1499    4070  46        		ld	b,(hl)
1500    4071  C5        		push	bc
1501    4072  214C00    		ld	hl,_sdrdbuf
1502    4075  CDE120    		call	_sdread
1503    4078  F1        		pop	af
1504    4079  F1        		pop	af
1505    407A  79        		ld	a,c
1506    407B  B0        		or	b
1507    407C  CAE940    		jp	z,L1165
1508                    	; 1490              {
1509                    	; 1491              curblkno = ebrrecs[partidx];
1510    407F  210200    		ld	hl,_curblkno
1511    4082  E5        		push	hl
1512    4083  DD6EF8    		ld	l,(ix-8)
1513    4086  DD66F9    		ld	h,(ix-7)
1514    4089  29        		add	hl,hl
1515    408A  29        		add	hl,hl
1516    408B  011800    		ld	bc,_ebrrecs
1517    408E  09        		add	hl,bc
1518    408F  E5        		push	hl
1519    4090  CD0000    		call	c.mvl
1520    4093  F1        		pop	af
1521                    	; 1492              curblkok = YES;
1522    4094  210100    		ld	hl,1
1523    4097  221000    		ld	(_curblkok),hl
1524                    	; 1493              }
1525                    	; 1494          else
1526                    	; 1495              {
1527                    	; 1496              if (sdtestflg)
1528                    	; 1497                  {
1529                    	; 1498                  printf("  can't read %s sector %lu\n", mbrebr, sector);
1530                    	; 1499                  } /* sdtestflg */
1531                    	; 1500              return;
1532                    	; 1501              }
1533                    	; 1502          entp = &sdrdbuf[0x01be] ;
1534    409A  210A02    		ld	hl,_sdrdbuf+446
1535    409D  DD75F0    		ld	(ix-16),l
1536    40A0  DD74F1    		ld	(ix-15),h
1537                    	; 1503          for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
1538    40A3  DD36F801  		ld	(ix-8),1
1539    40A7  DD36F900  		ld	(ix-7),0
1540                    	L1465:
1541    40AB  3E04      		ld	a,4
1542    40AD  DD96F8    		sub	(ix-8)
1543    40B0  3E00      		ld	a,0
1544    40B2  DD9EF9    		sbc	a,(ix-7)
1545    40B5  FADE40    		jp	m,L1755
1546    40B8  3A0E00    		ld	a,(_partdsk)
1547    40BB  D610      		sub	16
1548    40BD  3A0F00    		ld	a,(_partdsk+1)
1549    40C0  DE00      		sbc	a,0
1550    40C2  F2DE40    		jp	p,L1755
1551                    	; 1504              {
1552                    	; 1505              if (sdtestflg)
1553    40C5  2A0000    		ld	hl,(_sdtestflg)
1554    40C8  7C        		ld	a,h
1555    40C9  B5        		or	l
1556    40CA  CA3041    		jp	z,L1075
1557                    	; 1506                  {
1558                    	; 1507                  printf("EBR partition entry %d: ", partidx);
1559    40CD  DD6EF8    		ld	l,(ix-8)
1560    40D0  DD66F9    		ld	h,(ix-7)
1561    40D3  E5        		push	hl
1562    40D4  210C3E    		ld	hl,L5162
1563    40D7  CD0000    		call	_printf
1564    40DA  F1        		pop	af
1565    40DB  C33041    		jp	L1075
1566                    	L1755:
1567    40DE  DD34F8    		inc	(ix-8)
1568    40E1  2003      		jr	nz,L271
1569    40E3  DD34F9    		inc	(ix-7)
1570                    	L271:
1571    40E6  C33D40    		jp	L1555
1572                    	L1165:
1573    40E9  2A0000    		ld	hl,(_sdtestflg)
1574    40EC  7C        		ld	a,h
1575    40ED  B5        		or	l
1576    40EE  281E      		jr	z,L1365
1577    40F0  DD6607    		ld	h,(ix+7)
1578    40F3  DD6E06    		ld	l,(ix+6)
1579    40F6  E5        		push	hl
1580    40F7  DD6605    		ld	h,(ix+5)
1581    40FA  DD6E04    		ld	l,(ix+4)
1582    40FD  E5        		push	hl
1583    40FE  DD6EEE    		ld	l,(ix-18)
1584    4101  DD66EF    		ld	h,(ix-17)
1585    4104  E5        		push	hl
1586    4105  21F03D    		ld	hl,L5062
1587    4108  CD0000    		call	_printf
1588    410B  F1        		pop	af
1589    410C  F1        		pop	af
1590    410D  F1        		pop	af
1591                    	L1365:
1592    410E  C30000    		jp	c.rets
1593                    	L1665:
1594    4111  DD34F8    		inc	(ix-8)
1595    4114  2003      		jr	nz,L471
1596    4116  DD34F9    		inc	(ix-7)
1597                    	L471:
1598    4119  DD6EF0    		ld	l,(ix-16)
1599    411C  DD66F1    		ld	h,(ix-15)
1600    411F  7D        		ld	a,l
1601    4120  C610      		add	a,16
1602    4122  6F        		ld	l,a
1603    4123  7C        		ld	a,h
1604    4124  CE00      		adc	a,0
1605    4126  67        		ld	h,a
1606    4127  DD75F0    		ld	(ix-16),l
1607    412A  DD74F1    		ld	(ix-15),h
1608    412D  C3AB40    		jp	L1465
1609                    	L1075:
1610                    	; 1508                  } /* sdtestflg */
1611                    	; 1509              enttype = sdmbrentry(entp);
1612    4130  DD6EF0    		ld	l,(ix-16)
1613    4133  DD66F1    		ld	h,(ix-15)
1614    4136  CDE036    		call	_sdmbrentry
1615    4139  DD71F2    		ld	(ix-14),c
1616    413C  DD70F3    		ld	(ix-13),b
1617                    	; 1510              if (enttype == -1) /* read error */
1618    413F  DD7EF2    		ld	a,(ix-14)
1619    4142  FEFF      		cp	255
1620    4144  2005      		jr	nz,L671
1621    4146  DD7EF3    		ld	a,(ix-13)
1622    4149  FEFF      		cp	255
1623                    	L671:
1624    414B  2003      		jr	nz,L1175
1625                    	; 1511                   return;
1626    414D  C30000    		jp	c.rets
1627                    	L1175:
1628                    	; 1512              else if (enttype == PARTZRO) /* empty partition entry */
1629    4150  DD7EF2    		ld	a,(ix-14)
1630    4153  DDB6F3    		or	(ix-13)
1631    4156  2010      		jr	nz,L1375
1632                    	; 1513                  {
1633                    	; 1514                  if (sdtestflg)
1634    4158  2A0000    		ld	hl,(_sdtestflg)
1635    415B  7C        		ld	a,h
1636    415C  B5        		or	l
1637    415D  CADE40    		jp	z,L1755
1638                    	; 1515                      {
1639                    	; 1516                      /* if compiled as test program show also empty partitions */
1640                    	; 1517                      printf("Empty partition entry\n");
1641    4160  21253E    		ld	hl,L5262
1642    4163  CD0000    		call	_printf
1643                    	; 1518                      } /* sdtestflg */
1644                    	; 1519                  else
1645    4166  18A9      		jr	L1665
1646                    	L1375:
1647                    	; 1520                      break;
1648                    	; 1521                  }
1649                    	; 1522              else if (enttype == PARTEBR) /* next chained EBR */
1650    4168  DD7EF2    		ld	a,(ix-14)
1651    416B  FE02      		cp	2
1652    416D  2005      		jr	nz,L002
1653    416F  DD7EF3    		ld	a,(ix-13)
1654    4172  FE00      		cp	0
1655                    	L002:
1656    4174  C21141    		jp	nz,L1665
1657                    	; 1523                  {
1658                    	; 1524                  if (sdtestflg)
1659    4177  2A0000    		ld	hl,(_sdtestflg)
1660    417A  7C        		ld	a,h
1661    417B  B5        		or	l
1662    417C  2806      		jr	z,L1006
1663                    	; 1525                      {
1664                    	; 1526                      printf("EBR chain\n");
1665    417E  213C3E    		ld	hl,L5362
1666    4181  CD0000    		call	_printf
1667                    	L1006:
1668                    	; 1527                      } /* sdtestflg */
1669                    	; 1528                  /* follow the EBR chain */
1670                    	; 1529                  for (chainidx = 0;
1671    4184  DD36F400  		ld	(ix-12),0
1672    4188  DD36F500  		ld	(ix-11),0
1673                    	L1106:
1674                    	; 1530                      ebrnext && (chainidx < 16) && (partdsk < 16);
1675    418C  211200    		ld	hl,_ebrnext
1676    418F  7E        		ld	a,(hl)
1677    4190  23        		inc	hl
1678    4191  B6        		or	(hl)
1679    4192  23        		inc	hl
1680    4193  B6        		or	(hl)
1681    4194  23        		inc	hl
1682    4195  B6        		or	(hl)
1683    4196  CA1141    		jp	z,L1665
1684    4199  DD7EF4    		ld	a,(ix-12)
1685    419C  D610      		sub	16
1686    419E  DD7EF5    		ld	a,(ix-11)
1687    41A1  DE00      		sbc	a,0
1688    41A3  F21141    		jp	p,L1665
1689    41A6  3A0E00    		ld	a,(_partdsk)
1690    41A9  D610      		sub	16
1691    41AB  3A0F00    		ld	a,(_partdsk+1)
1692    41AE  DE00      		sbc	a,0
1693    41B0  F21141    		jp	p,L1665
1694                    	; 1531                      chainidx++)
1695                    	; 1532                      {
1696                    	; 1533                      /* ugly hack to stop reading the same sector */
1697                    	; 1534                      if (ebrnext == curblkno)
1698    41B3  211200    		ld	hl,_ebrnext
1699    41B6  E5        		push	hl
1700    41B7  210200    		ld	hl,_curblkno
1701    41BA  E5        		push	hl
1702    41BB  CD0000    		call	c.lcmp
1703    41BE  200D      		jr	nz,L1506
1704                    	; 1535                           break;
1705    41C0  C31141    		jp	L1665
1706                    	L1306:
1707    41C3  DD34F4    		inc	(ix-12)
1708    41C6  2003      		jr	nz,L202
1709    41C8  DD34F5    		inc	(ix-11)
1710                    	L202:
1711    41CB  18BF      		jr	L1106
1712                    	L1506:
1713                    	; 1536                      if (sdread(sdrdbuf, ebrnext))
1714    41CD  211500    		ld	hl,_ebrnext+3
1715    41D0  46        		ld	b,(hl)
1716    41D1  2B        		dec	hl
1717    41D2  4E        		ld	c,(hl)
1718    41D3  C5        		push	bc
1719    41D4  2B        		dec	hl
1720    41D5  46        		ld	b,(hl)
1721    41D6  2B        		dec	hl
1722    41D7  4E        		ld	c,(hl)
1723    41D8  C5        		push	bc
1724    41D9  214C00    		ld	hl,_sdrdbuf
1725    41DC  CDE120    		call	_sdread
1726    41DF  F1        		pop	af
1727    41E0  F1        		pop	af
1728    41E1  79        		ld	a,c
1729    41E2  B0        		or	b
1730    41E3  2855      		jr	z,L1606
1731                    	; 1537                          {
1732                    	; 1538                          curblkno = ebrnext;
1733    41E5  210200    		ld	hl,_curblkno
1734    41E8  E5        		push	hl
1735    41E9  211200    		ld	hl,_ebrnext
1736    41EC  E5        		push	hl
1737    41ED  CD0000    		call	c.mvl
1738    41F0  F1        		pop	af
1739                    	; 1539                          curblkok = YES;
1740    41F1  210100    		ld	hl,1
1741    41F4  221000    		ld	(_curblkok),hl
1742                    	; 1540                          }
1743                    	; 1541                      else
1744                    	; 1542                          {
1745                    	; 1543                          if (sdtestflg)
1746                    	; 1544                              {
1747                    	; 1545                              printf("  can't read %s sector %lu\n", mbrebr, sector);
1748                    	; 1546                              } /* sdtestflg */
1749                    	; 1547                          return;
1750                    	; 1548                          }
1751                    	; 1549                      entp = &sdrdbuf[0x01be] ;
1752    41F7  210A02    		ld	hl,_sdrdbuf+446
1753    41FA  DD75F0    		ld	(ix-16),l
1754    41FD  DD74F1    		ld	(ix-15),h
1755                    	; 1550                      for (cpartidx = 1;
1756    4200  DD36F601  		ld	(ix-10),1
1757    4204  DD36F700  		ld	(ix-9),0
1758                    	L1116:
1759                    	; 1551                          (cpartidx <= 4) && (partdsk < 16);
1760    4208  3E04      		ld	a,4
1761    420A  DD96F6    		sub	(ix-10)
1762    420D  3E00      		ld	a,0
1763    420F  DD9EF7    		sbc	a,(ix-9)
1764    4212  FAC341    		jp	m,L1306
1765    4215  3A0E00    		ld	a,(_partdsk)
1766    4218  D610      		sub	16
1767    421A  3A0F00    		ld	a,(_partdsk+1)
1768    421D  DE00      		sbc	a,0
1769    421F  F2C341    		jp	p,L1306
1770                    	; 1552                          cpartidx++, entp += 16)
1771                    	; 1553                          {
1772                    	; 1554                          if (sdtestflg)
1773    4222  2A0000    		ld	hl,(_sdtestflg)
1774    4225  7C        		ld	a,h
1775    4226  B5        		or	l
1776    4227  CA8142    		jp	z,L1516
1777                    	; 1555                              {
1778                    	; 1556                              printf("EBR chained  partition entry %d: ",
1779                    	; 1557                                   cpartidx);
1780    422A  DD6EF6    		ld	l,(ix-10)
1781    422D  DD66F7    		ld	h,(ix-9)
1782    4230  E5        		push	hl
1783    4231  21633E    		ld	hl,L5562
1784    4234  CD0000    		call	_printf
1785    4237  F1        		pop	af
1786    4238  1847      		jr	L1516
1787                    	L1606:
1788    423A  2A0000    		ld	hl,(_sdtestflg)
1789    423D  7C        		ld	a,h
1790    423E  B5        		or	l
1791    423F  281E      		jr	z,L1016
1792    4241  DD6607    		ld	h,(ix+7)
1793    4244  DD6E06    		ld	l,(ix+6)
1794    4247  E5        		push	hl
1795    4248  DD6605    		ld	h,(ix+5)
1796    424B  DD6E04    		ld	l,(ix+4)
1797    424E  E5        		push	hl
1798    424F  DD6EEE    		ld	l,(ix-18)
1799    4252  DD66EF    		ld	h,(ix-17)
1800    4255  E5        		push	hl
1801    4256  21473E    		ld	hl,L5462
1802    4259  CD0000    		call	_printf
1803    425C  F1        		pop	af
1804    425D  F1        		pop	af
1805    425E  F1        		pop	af
1806                    	L1016:
1807    425F  C30000    		jp	c.rets
1808                    	L1316:
1809    4262  DD34F6    		inc	(ix-10)
1810    4265  2003      		jr	nz,L402
1811    4267  DD34F7    		inc	(ix-9)
1812                    	L402:
1813    426A  DD6EF0    		ld	l,(ix-16)
1814    426D  DD66F1    		ld	h,(ix-15)
1815    4270  7D        		ld	a,l
1816    4271  C610      		add	a,16
1817    4273  6F        		ld	l,a
1818    4274  7C        		ld	a,h
1819    4275  CE00      		adc	a,0
1820    4277  67        		ld	h,a
1821    4278  DD75F0    		ld	(ix-16),l
1822    427B  DD74F1    		ld	(ix-15),h
1823    427E  C30842    		jp	L1116
1824                    	L1516:
1825                    	; 1558                              } /* sdtestflg */
1826                    	; 1559                          enttype = sdmbrentry(entp);
1827    4281  DD6EF0    		ld	l,(ix-16)
1828    4284  DD66F1    		ld	h,(ix-15)
1829    4287  CDE036    		call	_sdmbrentry
1830    428A  DD71F2    		ld	(ix-14),c
1831    428D  DD70F3    		ld	(ix-13),b
1832                    	; 1560                          if (enttype == -1) /* read error */
1833    4290  DD7EF2    		ld	a,(ix-14)
1834    4293  FEFF      		cp	255
1835    4295  2005      		jr	nz,L602
1836    4297  DD7EF3    		ld	a,(ix-13)
1837    429A  FEFF      		cp	255
1838                    	L602:
1839    429C  20C4      		jr	nz,L1316
1840                    	; 1561                              return;
1841                    	; 1562                          }
1842                    	; 1563                      }
1843                    	; 1564                  }
1844                    	; 1565              }
1845                    	; 1566          }
1846                    	; 1567      }
1847                    	L1655:
1848                    	;    1  /*  z80sdbt.c Boot and test program trying to make a unified prog.
1849                    	;    2   *
1850                    	;    3   *  Boot code for my DIY Z80 Computer. This
1851                    	;    4   *  program is compiled with Whitesmiths/COSMIC
1852                    	;    5   *  C compiler for Z80.
1853                    	;    6   *
1854                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
1855                    	;    8   *
1856                    	;    9   *  Initializes the hardware and detects the
1857                    	;   10   *  presence and partitioning of an attached SD card.
1858                    	;   11   *
1859                    	;   12   *  You are free to use, modify, and redistribute
1860                    	;   13   *  this source code. No warranties are given.
1861                    	;   14   *  Hastily Cobbled Together 2021 and 2022
1862                    	;   15   *  by Hans-Ake Lund
1863                    	;   16   *
1864                    	;   17   */
1865                    	;   18  
1866                    	;   19  #include <std.h>
1867                    	;   20  #include "z80computer.h"
1868                    	;   21  #include "builddate.h"
1869                    	;   22  
1870                    	;   23  #define PRGNAME "\nz80sdbt "
1871                    	;   24  #define VERSION "version 0.7, "
1872                    	;   25  /* This code should be cleaned up when
1873                    	;   26     remaining functions are implemented
1874                    	;   27   */
1875                    	;   28  #define PARTZRO 0  /* Empty partition entry */
1876                    	;   29  #define PARTMBR 1  /* MBR partition */
1877                    	;   30  #define PARTEBR 2  /* EBR logical partition */
1878                    	;   31  #define PARTGPT 3  /* GPT partition */
1879                    	;   32  #define EBRCONT 20 /* EBR container partition in MBR */
1880                    	;   33  
1881                    	;   34  struct partentry
1882                    	;   35      {
1883                    	;   36      char partype;
1884                    	;   37      char dskletter;
1885                    	;   38      int bootable;
1886                    	;   39      unsigned long dskstart;
1887                    	;   40      unsigned long dskend;
1888                    	;   41      unsigned long dsksize;
1889                    	;   42      unsigned char dsktype[16];
1890                    	;   43      } dskmap[16];
1891                    	;   44  
1892                    	;   45  unsigned char dsksign[4]; /* MBR/EBR disk signature */
1893                    	;   46  
1894                    	;   47  /* Function prototypes */
1895                    	;   48  void sdmbrpart(unsigned long);
1896                    	;   49  
1897                    	;   50  /* Response length in bytes
1898                    	;   51   */
1899                    	;   52  #define R1_LEN 1
1900                    	;   53  #define R3_LEN 5
1901                    	;   54  #define R7_LEN 5
1902                    	;   55  
1903                    	;   56  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
1904                    	;   57   * (The CRC7 byte in the tables below are only for information,
1905                    	;   58   * it is calculated by the sdcommand routine.)
1906                    	;   59   */
1907                    	;   60  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
1908                    	;   61  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
1909                    	;   62  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
1910                    	;   63  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
1911                    	;   64  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
1912                    	;   65  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
1913                    	;   66  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
1914                    	;   67  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
1915                    	;   68  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
1916                    	;   69  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
1917                    	;   70  
1918                    	;   71  /* Partition identifiers
1919                    	;   72   */
1920                    	;   73  /* For GPT I have decided that a CP/M partition
1921                    	;   74   * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
1922                    	;   75   */
1923                    	;   76  const unsigned char gptcpm[] =
1924                    	;   77      {
1925                    	;   78      0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
1926                    	;   79      0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
1927                    	;   80      };
1928                    	;   81  /* For MBR/EBR the partition type for CP/M is 0x52
1929                    	;   82   * according to: https://en.wikipedia.org/wiki/Partition_type
1930                    	;   83   */
1931                    	;   84  const unsigned char mbrcpm = 0x52;    /* CP/M partition */
1932                    	;   85  const unsigned char mbrexcode = 0x5f; /* Z80 executable code partition */
1933                    	;   86  /* has a special format that */
1934                    	;   87  /* includes number of sectors to */
1935                    	;   88  /* load and a signature, TBD */
1936                    	;   89  
1937                    	;   90  /* Buffers
1938                    	;   91   */
1939                    	;   92  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
1940                    	;   93  
1941                    	;   94  unsigned char ocrreg[4];     /* SD card OCR register */
1942                    	;   95  unsigned char cidreg[16];    /* SD card CID register */
1943                    	;   96  unsigned char csdreg[16];    /* SD card CSD register */
1944                    	;   97  unsigned long ebrrecs[4];    /* detected EBR records to process */
1945                    	;   98  int ebrrecidx; /* how many EBR records that are populated */
1946                    	;   99  unsigned long ebrnext; /* next chained ebr record */
1947                    	;  100  
1948                    	;  101  /* Variables
1949                    	;  102   */
1950                    	;  103  int curblkok;  /* if YES curblockno is read into buffer */
1951                    	;  104  int partdsk;   /* partition/disk number, 0 = disk A */
1952                    	;  105  int sdinitok;  /* SD card initialized and ready */
1953                    	;  106  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
1954                    	;  107  unsigned long blkmult;   /* block address multiplier */
1955                    	;  108  unsigned long curblkno;  /* block in buffer if curblkok == YES */
1956                    	;  109  
1957                    	;  110  /* debug bool */
1958                    	;  111  int sdtestflg;
1959                    	;  112  
1960                    	;  113  /* CRC routines from:
1961                    	;  114   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
1962                    	;  115   */
1963                    	;  116  
1964                    	;  117  /*
1965                    	;  118  // Calculate CRC7
1966                    	;  119  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
1967                    	;  120  // input:
1968                    	;  121  //   crcIn - the CRC before (0 for first step)
1969                    	;  122  //   data - byte for CRC calculation
1970                    	;  123  // return: the new CRC7
1971                    	;  124  */
1972                    	;  125  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
1973                    	;  126      {
1974                    	;  127      const unsigned char g = 0x89;
1975                    	;  128      unsigned char i;
1976                    	;  129  
1977                    	;  130      crcIn ^= data;
1978                    	;  131      for (i = 0; i < 8; i++)
1979                    	;  132          {
1980                    	;  133          if (crcIn & 0x80) crcIn ^= g;
1981                    	;  134          crcIn <<= 1;
1982                    	;  135          }
1983                    	;  136  
1984                    	;  137      return crcIn;
1985                    	;  138      }
1986                    	;  139  
1987                    	;  140  /*
1988                    	;  141  // Calculate CRC16 CCITT
1989                    	;  142  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
1990                    	;  143  // input:
1991                    	;  144  //   crcIn - the CRC before (0 for rist step)
1992                    	;  145  //   data - byte for CRC calculation
1993                    	;  146  // return: the CRC16 value
1994                    	;  147  */
1995                    	;  148  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
1996                    	;  149      {
1997                    	;  150      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
1998                    	;  151      crcIn ^=  data;
1999                    	;  152      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
2000                    	;  153      crcIn ^= (crcIn << 8) << 4;
2001                    	;  154      crcIn ^= ((crcIn & 0xff) << 4) << 1;
2002                    	;  155  
2003                    	;  156      return crcIn;
2004                    	;  157      }
2005                    	;  158  
2006                    	;  159  /* Send command to SD card and recieve answer.
2007                    	;  160   * A command is 5 bytes long and is followed by
2008                    	;  161   * a CRC7 checksum byte.
2009                    	;  162   * Returns a pointer to the response
2010                    	;  163   * or 0 if no response start bit found.
2011                    	;  164   */
2012                    	;  165  unsigned char *sdcommand(unsigned char *sdcmdp,
2013                    	;  166                           unsigned char *recbuf, int recbytes)
2014                    	;  167      {
2015                    	;  168      int searchn;  /* byte counter to search for response */
2016                    	;  169      int sdcbytes; /* byte counter for bytes to send */
2017                    	;  170      unsigned char *retptr; /* pointer used to store response */
2018                    	;  171      unsigned char rbyte;   /* recieved byte */
2019                    	;  172      unsigned char crc = 0; /* calculated CRC7 */
2020                    	;  173  
2021                    	;  174      /* send 8*2 clockpules */
2022                    	;  175      spiio(0xff);
2023                    	;  176      spiio(0xff);
2024                    	;  177      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
2025                    	;  178          {
2026                    	;  179          crc = CRC7_one(crc, *sdcmdp);
2027                    	;  180          spiio(*sdcmdp++);
2028                    	;  181          }
2029                    	;  182      spiio(crc | 0x01);
2030                    	;  183      /* search for recieved byte with start bit
2031                    	;  184         for a maximum of 10 recieved bytes  */
2032                    	;  185      for (searchn = 10; 0 < searchn; searchn--)
2033                    	;  186          {
2034                    	;  187          rbyte = spiio(0xff);
2035                    	;  188          if ((rbyte & 0x80) == 0)
2036                    	;  189              break;
2037                    	;  190          }
2038                    	;  191      if (searchn == 0) /* no start bit found */
2039                    	;  192          return (NO);
2040                    	;  193      retptr = recbuf;
2041                    	;  194      *retptr++ = rbyte;
2042                    	;  195      for (; 1 < recbytes; recbytes--) /* recieve bytes */
2043                    	;  196          *retptr++ = spiio(0xff);
2044                    	;  197      return (recbuf);
2045                    	;  198      }
2046                    	;  199  
2047                    	;  200  /* Initialise SD card interface
2048                    	;  201   *
2049                    	;  202   * returns YES if ok and NO if not ok
2050                    	;  203   *
2051                    	;  204   * References:
2052                    	;  205   *   https://www.sdcard.org/downloads/pls/
2053                    	;  206   *      Physical Layer Simplified Specification version 8.0
2054                    	;  207   *
2055                    	;  208   * A nice flowchart how to initialize:
2056                    	;  209   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
2057                    	;  210   *
2058                    	;  211   */
2059                    	;  212  int sdinit()
2060                    	;  213      {
2061                    	;  214      int nbytes;  /* byte counter */
2062                    	;  215      int tries;   /* tries to get to active state or searching for data  */
2063                    	;  216      int wtloop;  /* timer loop when trying to enter active state */
2064                    	;  217      unsigned char cmdbuf[5];   /* buffer to build command in */
2065                    	;  218      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2066                    	;  219      unsigned char *statptr;    /* pointer to returned status from SD command */
2067                    	;  220      unsigned char crc;         /* crc register for CID and CSD */
2068                    	;  221      unsigned char rbyte;       /* recieved byte */
2069                    	;  222      unsigned char *prtptr;     /* for debug printing */
2070                    	;  223  
2071                    	;  224      ledon();
2072                    	;  225      spideselect();
2073                    	;  226      sdinitok = NO;
2074                    	;  227  
2075                    	;  228      /* start to generate 9*8 clock pulses with not selected SD card */
2076                    	;  229      for (nbytes = 9; 0 < nbytes; nbytes--)
2077                    	;  230          spiio(0xff);
2078                    	;  231      if (sdtestflg)
2079                    	;  232          {
2080                    	;  233          printf("\nSent 8*8 (72) clock pulses, select not active\n");
2081                    	;  234          } /* sdtestflg */
2082                    	;  235      spiselect();
2083                    	;  236  
2084                    	;  237      /* CMD0: GO_IDLE_STATE */
2085                    	;  238      for (tries = 0; tries < 10; tries++)
2086                    	;  239          {
2087                    	;  240          memcpy(cmdbuf, cmd0, 5);
2088                    	;  241          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2089                    	;  242          if (sdtestflg)
2090                    	;  243              {
2091                    	;  244              if (!statptr)
2092                    	;  245                  printf("CMD0: no response\n");
2093                    	;  246              else
2094                    	;  247                  printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
2095                    	;  248              } /* sdtestflg */
2096                    	;  249          if (!statptr)
2097                    	;  250              {
2098                    	;  251              spideselect();
2099                    	;  252              ledoff();
2100                    	;  253              return (NO);
2101                    	;  254              }
2102                    	;  255          if (statptr[0] == 0x01)
2103                    	;  256              break;
2104                    	;  257          for (wtloop = 0; wtloop < tries * 10; wtloop++)
2105                    	;  258              {
2106                    	;  259              /* wait loop, time increasing for each try */
2107                    	;  260              spiio(0xff);
2108                    	;  261              }
2109                    	;  262          }
2110                    	;  263  
2111                    	;  264      /* CMD8: SEND_IF_COND */
2112                    	;  265      memcpy(cmdbuf, cmd8, 5);
2113                    	;  266      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
2114                    	;  267      if (sdtestflg)
2115                    	;  268          {
2116                    	;  269          if (!statptr)
2117                    	;  270              printf("CMD8: no response\n");
2118                    	;  271          else
2119                    	;  272              {
2120                    	;  273              printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
2121                    	;  274                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2122                    	;  275              if (!(statptr[0] & 0xfe)) /* no error */
2123                    	;  276                  {
2124                    	;  277                  if (statptr[4] == 0xaa)
2125                    	;  278                      printf("echo back ok, ");
2126                    	;  279                  else
2127                    	;  280                      printf("invalid echo back\n");
2128                    	;  281                  }
2129                    	;  282              }
2130                    	;  283          } /* sdtestflg */
2131                    	;  284      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
2132                    	;  285          {
2133                    	;  286          sdver2 = NO;
2134                    	;  287          if (sdtestflg)
2135                    	;  288              {
2136                    	;  289              printf("probably SD ver. 1\n");
2137                    	;  290              } /* sdtestflg */
2138                    	;  291          }
2139                    	;  292      else
2140                    	;  293          {
2141                    	;  294          sdver2 = YES;
2142                    	;  295          if (statptr[4] != 0xaa) /* but invalid echo back */
2143                    	;  296              {
2144                    	;  297              spideselect();
2145                    	;  298              ledoff();
2146                    	;  299              return (NO);
2147                    	;  300              }
2148                    	;  301          if (sdtestflg)
2149                    	;  302              {
2150                    	;  303              printf("SD ver 2\n");
2151                    	;  304              } /* sdtestflg */
2152                    	;  305          }
2153                    	;  306  
2154                    	;  307      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
2155                    	;  308      for (tries = 0; tries < 20; tries++)
2156                    	;  309          {
2157                    	;  310          memcpy(cmdbuf, cmd55, 5);
2158                    	;  311          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2159                    	;  312          if (sdtestflg)
2160                    	;  313              {
2161                    	;  314              if (!statptr)
2162                    	;  315                  printf("CMD55: no response\n");
2163                    	;  316              else
2164                    	;  317                  printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
2165                    	;  318              } /* sdtestflg */
2166                    	;  319          if (!statptr)
2167                    	;  320              {
2168                    	;  321              spideselect();
2169                    	;  322              ledoff();
2170                    	;  323              return (NO);
2171                    	;  324              }
2172                    	;  325          memcpy(cmdbuf, acmd41, 5);
2173                    	;  326          if (sdver2)
2174                    	;  327              cmdbuf[1] = 0x40;
2175                    	;  328          else
2176                    	;  329              cmdbuf[1] = 0x00;
2177                    	;  330          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2178                    	;  331          if (sdtestflg)
2179                    	;  332              {
2180                    	;  333              if (!statptr)
2181                    	;  334                  printf("ACMD41: no response\n");
2182                    	;  335              else
2183                    	;  336                  printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
2184                    	;  337                         statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
2185                    	;  338              } /* sdtestflg */
2186                    	;  339          if (!statptr)
2187                    	;  340              {
2188                    	;  341              spideselect();
2189                    	;  342              ledoff();
2190                    	;  343              return (NO);
2191                    	;  344              }
2192                    	;  345          if (statptr[0] == 0x00) /* now the SD card is ready */
2193                    	;  346              {
2194                    	;  347              break;
2195                    	;  348              }
2196                    	;  349          for (wtloop = 0; wtloop < tries * 10; wtloop++)
2197                    	;  350              {
2198                    	;  351              /* wait loop, time increasing for each try */
2199                    	;  352              spiio(0xff);
2200                    	;  353              }
2201                    	;  354          }
2202                    	;  355  
2203                    	;  356      /* CMD58: READ_OCR */
2204                    	;  357      /* According to the flow chart this should not work
2205                    	;  358         for SD ver. 1 but the response is ok anyway
2206                    	;  359         all tested SD cards  */
2207                    	;  360      memcpy(cmdbuf, cmd58, 5);
2208                    	;  361      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
2209                    	;  362      if (sdtestflg)
2210                    	;  363          {
2211                    	;  364          if (!statptr)
2212                    	;  365              printf("CMD58: no response\n");
2213                    	;  366          else
2214                    	;  367              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
2215                    	;  368                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2216                    	;  369          } /* sdtestflg */
2217                    	;  370      if (!statptr)
2218                    	;  371          {
2219                    	;  372          spideselect();
2220                    	;  373          ledoff();
2221                    	;  374          return (NO);
2222                    	;  375          }
2223                    	;  376      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
2224                    	;  377      blkmult = 1; /* assume block address */
2225                    	;  378      if (ocrreg[0] & 0x80)
2226                    	;  379          {
2227                    	;  380          /* SD Ver.2+ */
2228                    	;  381          if (!(ocrreg[0] & 0x40))
2229                    	;  382              {
2230                    	;  383              /* SD Ver.2+, Byte address */
2231                    	;  384              blkmult = 512;
2232                    	;  385              }
2233                    	;  386          }
2234                    	;  387  
2235                    	;  388      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
2236                    	;  389      if (blkmult == 512)
2237                    	;  390          {
2238                    	;  391          memcpy(cmdbuf, cmd16, 5);
2239                    	;  392          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2240                    	;  393          if (sdtestflg)
2241                    	;  394              {
2242                    	;  395              if (!statptr)
2243                    	;  396                  printf("CMD16: no response\n");
2244                    	;  397              else
2245                    	;  398                  printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
2246                    	;  399                         statptr[0]);
2247                    	;  400              } /* sdtestflg */
2248                    	;  401          if (!statptr)
2249                    	;  402              {
2250                    	;  403              spideselect();
2251                    	;  404              ledoff();
2252                    	;  405              return (NO);
2253                    	;  406              }
2254                    	;  407          }
2255                    	;  408      /* Register information:
2256                    	;  409       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
2257                    	;  410       */
2258                    	;  411  
2259                    	;  412      /* CMD10: SEND_CID */
2260                    	;  413      memcpy(cmdbuf, cmd10, 5);
2261                    	;  414      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2262                    	;  415      if (sdtestflg)
2263                    	;  416          {
2264                    	;  417          if (!statptr)
2265                    	;  418              printf("CMD10: no response\n");
2266                    	;  419          else
2267                    	;  420              printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
2268                    	;  421          } /* sdtestflg */
2269                    	;  422      if (!statptr)
2270                    	;  423          {
2271                    	;  424          spideselect();
2272                    	;  425          ledoff();
2273                    	;  426          return (NO);
2274                    	;  427          }
2275                    	;  428      /* looking for 0xfe that is the byte before data */
2276                    	;  429      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2277                    	;  430          ;
2278                    	;  431      if (tries == 0) /* tried too many times */
2279                    	;  432          {
2280                    	;  433          if (sdtestflg)
2281                    	;  434              {
2282                    	;  435              printf("  No data found\n");
2283                    	;  436              } /* sdtestflg */
2284                    	;  437          spideselect();
2285                    	;  438          ledoff();
2286                    	;  439          return (NO);
2287                    	;  440          }
2288                    	;  441      else
2289                    	;  442          {
2290                    	;  443          crc = 0;
2291                    	;  444          for (nbytes = 0; nbytes < 15; nbytes++)
2292                    	;  445              {
2293                    	;  446              rbyte = spiio(0xff);
2294                    	;  447              cidreg[nbytes] = rbyte;
2295                    	;  448              crc = CRC7_one(crc, rbyte);
2296                    	;  449              }
2297                    	;  450          cidreg[15] = spiio(0xff);
2298                    	;  451          crc |= 0x01;
2299                    	;  452          /* some SD cards need additional clock pulses */
2300                    	;  453          for (nbytes = 9; 0 < nbytes; nbytes--)
2301                    	;  454              spiio(0xff);
2302                    	;  455          if (sdtestflg)
2303                    	;  456              {
2304                    	;  457              prtptr = &cidreg[0];
2305                    	;  458              printf("  CID: [");
2306                    	;  459              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2307                    	;  460                  printf("%02x ", *prtptr);
2308                    	;  461              prtptr = &cidreg[0];
2309                    	;  462              printf("\b] |");
2310                    	;  463              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2311                    	;  464                  {
2312                    	;  465                  if ((' ' <= *prtptr) && (*prtptr < 127))
2313                    	;  466                      putchar(*prtptr);
2314                    	;  467                  else
2315                    	;  468                      putchar('.');
2316                    	;  469                  }
2317                    	;  470              printf("|\n");
2318                    	;  471              if (crc == cidreg[15])
2319                    	;  472                  {
2320                    	;  473                  printf("CRC7 ok: [%02x]\n", crc);
2321                    	;  474                  }
2322                    	;  475              else
2323                    	;  476                  {
2324                    	;  477                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2325                    	;  478                         crc, cidreg[15]);
2326                    	;  479                  /* could maybe return failure here */
2327                    	;  480                  }
2328                    	;  481              } /* sdtestflg */
2329                    	;  482          }
2330                    	;  483  
2331                    	;  484      /* CMD9: SEND_CSD */
2332                    	;  485      memcpy(cmdbuf, cmd9, 5);
2333                    	;  486      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2334                    	;  487      if (sdtestflg)
2335                    	;  488          {
2336                    	;  489          if (!statptr)
2337                    	;  490              printf("CMD9: no response\n");
2338                    	;  491          else
2339                    	;  492              printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
2340                    	;  493          } /* sdtestflg */
2341                    	;  494      if (!statptr)
2342                    	;  495          {
2343                    	;  496          spideselect();
2344                    	;  497          ledoff();
2345                    	;  498          return (NO);
2346                    	;  499          }
2347                    	;  500      /* looking for 0xfe that is the byte before data */
2348                    	;  501      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
2349                    	;  502          ;
2350                    	;  503      if (tries == 0) /* tried too many times */
2351                    	;  504          {
2352                    	;  505          if (sdtestflg)
2353                    	;  506              {
2354                    	;  507              printf("  No data found\n");
2355                    	;  508              } /* sdtestflg */
2356                    	;  509          return (NO);
2357                    	;  510          }
2358                    	;  511      else
2359                    	;  512          {
2360                    	;  513          crc = 0;
2361                    	;  514          for (nbytes = 0; nbytes < 15; nbytes++)
2362                    	;  515              {
2363                    	;  516              rbyte = spiio(0xff);
2364                    	;  517              csdreg[nbytes] = rbyte;
2365                    	;  518              crc = CRC7_one(crc, rbyte);
2366                    	;  519              }
2367                    	;  520          csdreg[15] = spiio(0xff);
2368                    	;  521          crc |= 0x01;
2369                    	;  522          /* some SD cards need additional clock pulses */
2370                    	;  523          for (nbytes = 9; 0 < nbytes; nbytes--)
2371                    	;  524              spiio(0xff);
2372                    	;  525          if (sdtestflg)
2373                    	;  526              {
2374                    	;  527              prtptr = &csdreg[0];
2375                    	;  528              printf("  CSD: [");
2376                    	;  529              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2377                    	;  530                  printf("%02x ", *prtptr);
2378                    	;  531              prtptr = &csdreg[0];
2379                    	;  532              printf("\b] |");
2380                    	;  533              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
2381                    	;  534                  {
2382                    	;  535                  if ((' ' <= *prtptr) && (*prtptr < 127))
2383                    	;  536                      putchar(*prtptr);
2384                    	;  537                  else
2385                    	;  538                      putchar('.');
2386                    	;  539                  }
2387                    	;  540              printf("|\n");
2388                    	;  541              if (crc == csdreg[15])
2389                    	;  542                  {
2390                    	;  543                  printf("CRC7 ok: [%02x]\n", crc);
2391                    	;  544                  }
2392                    	;  545              else
2393                    	;  546                  {
2394                    	;  547                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
2395                    	;  548                         crc, csdreg[15]);
2396                    	;  549                  /* could maybe return failure here */
2397                    	;  550                  }
2398                    	;  551              } /* sdtestflg */
2399                    	;  552          }
2400                    	;  553  
2401                    	;  554      for (nbytes = 9; 0 < nbytes; nbytes--)
2402                    	;  555          spiio(0xff);
2403                    	;  556      if (sdtestflg)
2404                    	;  557          {
2405                    	;  558          printf("Sent 9*8 (72) clock pulses, select active\n");
2406                    	;  559          } /* sdtestflg */
2407                    	;  560  
2408                    	;  561      sdinitok = YES;
2409                    	;  562  
2410                    	;  563      spideselect();
2411                    	;  564      ledoff();
2412                    	;  565  
2413                    	;  566      return (YES);
2414                    	;  567      }
2415                    	;  568  
2416                    	;  569  int sdprobe()
2417                    	;  570      {
2418                    	;  571      unsigned char cmdbuf[5];   /* buffer to build command in */
2419                    	;  572      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2420                    	;  573      unsigned char *statptr;    /* pointer to returned status from SD command */
2421                    	;  574      int nbytes;  /* byte counter */
2422                    	;  575      int allzero = YES;
2423                    	;  576  
2424                    	;  577      ledon();
2425                    	;  578      spiselect();
2426                    	;  579  
2427                    	;  580      /* CMD58: READ_OCR */
2428                    	;  581      memcpy(cmdbuf, cmd58, 5);
2429                    	;  582      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
2430                    	;  583      for (nbytes = 0; nbytes < 5; nbytes++)
2431                    	;  584          {
2432                    	;  585          if (statptr[nbytes] != 0)
2433                    	;  586              allzero = NO;
2434                    	;  587          }
2435                    	;  588      if (sdtestflg)
2436                    	;  589          {
2437                    	;  590          if (!statptr)
2438                    	;  591              printf("CMD58: no response\n");
2439                    	;  592          else
2440                    	;  593              {
2441                    	;  594              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
2442                    	;  595                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2443                    	;  596              if (allzero)
2444                    	;  597                  printf("SD card not inserted or not initialized\n");
2445                    	;  598              }
2446                    	;  599          } /* sdtestflg */
2447                    	;  600      if (!statptr || allzero)
2448                    	;  601          {
2449                    	;  602          sdinitok = NO;
2450                    	;  603          spideselect();
2451                    	;  604          ledoff();
2452                    	;  605          return (NO);
2453                    	;  606          }
2454                    	;  607  
2455                    	;  608      spideselect();
2456                    	;  609      ledoff();
2457                    	;  610  
2458                    	;  611      return (YES);
2459                    	;  612      }
2460                    	;  613  
2461                    	;  614  /* print OCR, CID and CSD registers*/
2462                    	;  615  void sdprtreg()
2463                    	;  616      {
2464                    	;  617      unsigned int n;
2465                    	;  618      unsigned int csize;
2466                    	;  619      unsigned long devsize;
2467                    	;  620      unsigned long capacity;
2468                    	;  621  
2469                    	;  622      if (!sdinitok)
2470                    	;  623          {
2471                    	;  624          printf("SD card not initialized\n");
2472                    	;  625          return;
2473                    	;  626          }
2474                    	;  627      printf("SD card information:");
2475                    	;  628      if (ocrreg[0] & 0x80)
2476                    	;  629          {
2477                    	;  630          if (ocrreg[0] & 0x40)
2478                    	;  631              printf("  SD card ver. 2+, Block address\n");
2479                    	;  632          else
2480                    	;  633              {
2481                    	;  634              if (sdver2)
2482                    	;  635                  printf("  SD card ver. 2+, Byte address\n");
2483                    	;  636              else
2484                    	;  637                  printf("  SD card ver. 1, Byte address\n");
2485                    	;  638              }
2486                    	;  639          }
2487                    	;  640      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
2488                    	;  641      printf("OEM ID: %.2s, ", &cidreg[1]);
2489                    	;  642      printf("Product name: %.5s\n", &cidreg[3]);
2490                    	;  643      printf("  Product revision: %d.%d, ",
2491                    	;  644             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
2492                    	;  645      printf("Serial number: %lu\n",
2493                    	;  646             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
2494                    	;  647      printf("  Manufacturing date: %d-%d, ",
2495                    	;  648             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2496                    	;  649      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
2497                    	;  650          {
2498                    	;  651          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2499                    	;  652          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2500                    	;  653                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2501                    	;  654          capacity = (unsigned long) csize << (n-10);
2502                    	;  655          printf("Device capacity: %lu MByte\n", capacity >> 10);
2503                    	;  656          }
2504                    	;  657      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
2505                    	;  658          {
2506                    	;  659          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2507                    	;  660                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2508                    	;  661          capacity = devsize << 9;
2509                    	;  662          printf("Device capacity: %lu MByte\n", capacity >> 10);
2510                    	;  663          }
2511                    	;  664      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
2512                    	;  665          {
2513                    	;  666          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
2514                    	;  667                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2515                    	;  668          capacity = devsize << 9;
2516                    	;  669          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
2517                    	;  670          }
2518                    	;  671  
2519                    	;  672      if (sdtestflg)
2520                    	;  673          {
2521                    	;  674  
2522                    	;  675          printf("--------------------------------------\n");
2523                    	;  676          printf("OCR register:\n");
2524                    	;  677          if (ocrreg[2] & 0x80)
2525                    	;  678              printf("2.7-2.8V (bit 15) ");
2526                    	;  679          if (ocrreg[1] & 0x01)
2527                    	;  680              printf("2.8-2.9V (bit 16) ");
2528                    	;  681          if (ocrreg[1] & 0x02)
2529                    	;  682              printf("2.9-3.0V (bit 17) ");
2530                    	;  683          if (ocrreg[1] & 0x04)
2531                    	;  684              printf("3.0-3.1V (bit 18) \n");
2532                    	;  685          if (ocrreg[1] & 0x08)
2533                    	;  686              printf("3.1-3.2V (bit 19) ");
2534                    	;  687          if (ocrreg[1] & 0x10)
2535                    	;  688              printf("3.2-3.3V (bit 20) ");
2536                    	;  689          if (ocrreg[1] & 0x20)
2537                    	;  690              printf("3.3-3.4V (bit 21) ");
2538                    	;  691          if (ocrreg[1] & 0x40)
2539                    	;  692              printf("3.4-3.5V (bit 22) \n");
2540                    	;  693          if (ocrreg[1] & 0x80)
2541                    	;  694              printf("3.5-3.6V (bit 23) \n");
2542                    	;  695          if (ocrreg[0] & 0x01)
2543                    	;  696              printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
2544                    	;  697          if (ocrreg[0] & 0x08)
2545                    	;  698              printf("Over 2TB support Status (CO2T) (bit 27) set\n");
2546                    	;  699          if (ocrreg[0] & 0x20)
2547                    	;  700              printf("UHS-II Card Status (bit 29) set ");
2548                    	;  701          if (ocrreg[0] & 0x80)
2549                    	;  702              {
2550                    	;  703              if (ocrreg[0] & 0x40)
2551                    	;  704                  {
2552                    	;  705                  printf("Card Capacity Status (CCS) (bit 30) set\n");
2553                    	;  706                  printf("  SD Ver.2+, Block address");
2554                    	;  707                  }
2555                    	;  708              else
2556                    	;  709                  {
2557                    	;  710                  printf("Card Capacity Status (CCS) (bit 30) not set\n");
2558                    	;  711                  if (sdver2)
2559                    	;  712                      printf("  SD Ver.2+, Byte address");
2560                    	;  713                  else
2561                    	;  714                      printf("  SD Ver.1, Byte address");
2562                    	;  715                  }
2563                    	;  716              printf("\nCard power up status bit (busy) (bit 31) set\n");
2564                    	;  717              }
2565                    	;  718          else
2566                    	;  719              {
2567                    	;  720              printf("\nCard power up status bit (busy) (bit 31) not set.\n");
2568                    	;  721              printf("  This bit is not set if the card has not finished the power up routine.\n");
2569                    	;  722              }
2570                    	;  723          printf("--------------------------------------\n");
2571                    	;  724          printf("CID register:\n");
2572                    	;  725          printf("MID: 0x%02x, ", cidreg[0]);
2573                    	;  726          printf("OID: %.2s, ", &cidreg[1]);
2574                    	;  727          printf("PNM: %.5s, ", &cidreg[3]);
2575                    	;  728          printf("PRV: %d.%d, ",
2576                    	;  729                 (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
2577                    	;  730          printf("PSN: %lu, ",
2578                    	;  731                 (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
2579                    	;  732          printf("MDT: %d-%d\n",
2580                    	;  733                 2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
2581                    	;  734          printf("--------------------------------------\n");
2582                    	;  735          printf("CSD register:\n");
2583                    	;  736          if ((csdreg[0] & 0xc0) == 0x00)
2584                    	;  737              {
2585                    	;  738              printf("CSD Version 1.0, Standard Capacity\n");
2586                    	;  739              n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
2587                    	;  740              csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
2588                    	;  741                      ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
2589                    	;  742              capacity = (unsigned long) csize << (n-10);
2590                    	;  743              printf(" Device capacity: %lu KByte, %lu MByte\n",
2591                    	;  744                     capacity, capacity >> 10);
2592                    	;  745              }
2593                    	;  746          if ((csdreg[0] & 0xc0) == 0x40)
2594                    	;  747              {
2595                    	;  748              printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
2596                    	;  749              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2597                    	;  750                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2598                    	;  751              capacity = devsize << 9;
2599                    	;  752              printf(" Device capacity: %lu KByte, %lu MByte\n",
2600                    	;  753                     capacity, capacity >> 10);
2601                    	;  754              }
2602                    	;  755          if ((csdreg[0] & 0xc0) == 0x80)
2603                    	;  756              {
2604                    	;  757              printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
2605                    	;  758              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
2606                    	;  759                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
2607                    	;  760              capacity = devsize << 9;
2608                    	;  761              printf(" Device capacity: %lu KByte, %lu MByte\n",
2609                    	;  762                     capacity, capacity >> 10);
2610                    	;  763              }
2611                    	;  764          printf("--------------------------------------\n");
2612                    	;  765  
2613                    	;  766          } /* sdtestflg */ /* SDTEST */
2614                    	;  767  
2615                    	;  768      }
2616                    	;  769  
2617                    	;  770  /* Read data block of 512 bytes to buffer
2618                    	;  771   * Returns YES if ok or NO if error
2619                    	;  772   */
2620                    	;  773  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
2621                    	;  774      {
2622                    	;  775      unsigned char *statptr;
2623                    	;  776      unsigned char rbyte;
2624                    	;  777      unsigned char cmdbuf[5];   /* buffer to build command in */
2625                    	;  778      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2626                    	;  779      int nbytes;
2627                    	;  780      int tries;
2628                    	;  781      unsigned long blktoread;
2629                    	;  782      unsigned int rxcrc16;
2630                    	;  783      unsigned int calcrc16;
2631                    	;  784  
2632                    	;  785      ledon();
2633                    	;  786      spiselect();
2634                    	;  787  
2635                    	;  788      if (!sdinitok)
2636                    	;  789          {
2637                    	;  790          if (sdtestflg)
2638                    	;  791              {
2639                    	;  792              printf("SD card not initialized\n");
2640                    	;  793              } /* sdtestflg */
2641                    	;  794          spideselect();
2642                    	;  795          ledoff();
2643                    	;  796          return (NO);
2644                    	;  797          }
2645                    	;  798  
2646                    	;  799      /* CMD17: READ_SINGLE_BLOCK */
2647                    	;  800      /* Insert block # into command */
2648                    	;  801      memcpy(cmdbuf, cmd17, 5);
2649                    	;  802      blktoread = blkmult * rdblkno;
2650                    	;  803      cmdbuf[4] = blktoread & 0xff;
2651                    	;  804      blktoread = blktoread >> 8;
2652                    	;  805      cmdbuf[3] = blktoread & 0xff;
2653                    	;  806      blktoread = blktoread >> 8;
2654                    	;  807      cmdbuf[2] = blktoread & 0xff;
2655                    	;  808      blktoread = blktoread >> 8;
2656                    	;  809      cmdbuf[1] = blktoread & 0xff;
2657                    	;  810  
2658                    	;  811      if (sdtestflg)
2659                    	;  812          {
2660                    	;  813          printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2661                    	;  814                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2662                    	;  815          } /* sdtestflg */
2663                    	;  816      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2664                    	;  817      if (sdtestflg)
2665                    	;  818          {
2666                    	;  819          printf("CMD17 R1 response [%02x]\n", statptr[0]);
2667                    	;  820          } /* sdtestflg */
2668                    	;  821      if (statptr[0])
2669                    	;  822          {
2670                    	;  823          if (sdtestflg)
2671                    	;  824              {
2672                    	;  825              printf("  could not read block\n");
2673                    	;  826              } /* sdtestflg */
2674                    	;  827          spideselect();
2675                    	;  828          ledoff();
2676                    	;  829          return (NO);
2677                    	;  830          }
2678                    	;  831      /* looking for 0xfe that is the byte before data */
2679                    	;  832      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
2680                    	;  833          {
2681                    	;  834          if ((rbyte & 0xe0) == 0x00)
2682                    	;  835              {
2683                    	;  836              /* If a read operation fails and the card cannot provide
2684                    	;  837                 the required data, it will send a data error token instead
2685                    	;  838               */
2686                    	;  839              if (sdtestflg)
2687                    	;  840                  {
2688                    	;  841                  printf("  read error: [%02x]\n", rbyte);
2689                    	;  842                  } /* sdtestflg */
2690                    	;  843              spideselect();
2691                    	;  844              ledoff();
2692                    	;  845              return (NO);
2693                    	;  846              }
2694                    	;  847          }
2695                    	;  848      if (tries == 0) /* tried too many times */
2696                    	;  849          {
2697                    	;  850          if (sdtestflg)
2698                    	;  851              {
2699                    	;  852              printf("  no data found\n");
2700                    	;  853              } /* sdtestflg */
2701                    	;  854          spideselect();
2702                    	;  855          ledoff();
2703                    	;  856          return (NO);
2704                    	;  857          }
2705                    	;  858      else
2706                    	;  859          {
2707                    	;  860          calcrc16 = 0;
2708                    	;  861          for (nbytes = 0; nbytes < 512; nbytes++)
2709                    	;  862              {
2710                    	;  863              rbyte = spiio(0xff);
2711                    	;  864              calcrc16 = CRC16_one(calcrc16, rbyte);
2712                    	;  865              rdbuf[nbytes] = rbyte;
2713                    	;  866              }
2714                    	;  867          rxcrc16 = spiio(0xff) << 8;
2715                    	;  868          rxcrc16 += spiio(0xff);
2716                    	;  869  
2717                    	;  870          if (sdtestflg)
2718                    	;  871              {
2719                    	;  872              printf("  read data block %ld:\n", rdblkno);
2720                    	;  873              } /* sdtestflg */
2721                    	;  874          if (rxcrc16 != calcrc16)
2722                    	;  875              {
2723                    	;  876              if (sdtestflg)
2724                    	;  877                  {
2725                    	;  878                  printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
2726                    	;  879                         rxcrc16, calcrc16);
2727                    	;  880                  } /* sdtestflg */
2728                    	;  881              spideselect();
2729                    	;  882              ledoff();
2730                    	;  883              return (NO);
2731                    	;  884              }
2732                    	;  885          }
2733                    	;  886      spideselect();
2734                    	;  887      ledoff();
2735                    	;  888      return (YES);
2736                    	;  889      }
2737                    	;  890  
2738                    	;  891  /* Write data block of 512 bytes from buffer
2739                    	;  892   * Returns YES if ok or NO if error
2740                    	;  893   */
2741                    	;  894  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
2742                    	;  895      {
2743                    	;  896      unsigned char *statptr;
2744                    	;  897      unsigned char rbyte;
2745                    	;  898      unsigned char tbyte;
2746                    	;  899      unsigned char cmdbuf[5];   /* buffer to build command in */
2747                    	;  900      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2748                    	;  901      int nbytes;
2749                    	;  902      int tries;
2750                    	;  903      unsigned long blktowrite;
2751                    	;  904      unsigned int calcrc16;
2752                    	;  905  
2753                    	;  906      ledon();
2754                    	;  907      spiselect();
2755                    	;  908  
2756                    	;  909      if (!sdinitok)
2757                    	;  910          {
2758                    	;  911          if (sdtestflg)
2759                    	;  912              {
2760                    	;  913              printf("SD card not initialized\n");
2761                    	;  914              } /* sdtestflg */
2762                    	;  915          spideselect();
2763                    	;  916          ledoff();
2764                    	;  917          return (NO);
2765                    	;  918          }
2766                    	;  919  
2767                    	;  920      if (sdtestflg)
2768                    	;  921          {
2769                    	;  922          printf("  write data block %ld:\n", wrblkno);
2770                    	;  923          } /* sdtestflg */
2771                    	;  924      /* CMD24: WRITE_SINGLE_BLOCK */
2772                    	;  925      /* Insert block # into command */
2773                    	;  926      memcpy(cmdbuf, cmd24, 5);
2774                    	;  927      blktowrite = blkmult * wrblkno;
2775                    	;  928      cmdbuf[4] = blktowrite & 0xff;
2776                    	;  929      blktowrite = blktowrite >> 8;
2777                    	;  930      cmdbuf[3] = blktowrite & 0xff;
2778                    	;  931      blktowrite = blktowrite >> 8;
2779                    	;  932      cmdbuf[2] = blktowrite & 0xff;
2780                    	;  933      blktowrite = blktowrite >> 8;
2781                    	;  934      cmdbuf[1] = blktowrite & 0xff;
2782                    	;  935  
2783                    	;  936      if (sdtestflg)
2784                    	;  937          {
2785                    	;  938          printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
2786                    	;  939                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
2787                    	;  940          } /* sdtestflg */
2788                    	;  941      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2789                    	;  942      if (sdtestflg)
2790                    	;  943          {
2791                    	;  944          printf("CMD24 R1 response [%02x]\n", statptr[0]);
2792                    	;  945          } /* sdtestflg */
2793                    	;  946      if (statptr[0])
2794                    	;  947          {
2795                    	;  948          if (sdtestflg)
2796                    	;  949              {
2797                    	;  950              printf("  could not write block\n");
2798                    	;  951              } /* sdtestflg */
2799                    	;  952          spideselect();
2800                    	;  953          ledoff();
2801                    	;  954          return (NO);
2802                    	;  955          }
2803                    	;  956      /* send 0xfe, the byte before data */
2804                    	;  957      spiio(0xfe);
2805                    	;  958      /* initialize crc and send block */
2806                    	;  959      calcrc16 = 0;
2807                    	;  960      for (nbytes = 0; nbytes < 512; nbytes++)
2808                    	;  961          {
2809                    	;  962          tbyte = wrbuf[nbytes];
2810                    	;  963          spiio(tbyte);
2811                    	;  964          calcrc16 = CRC16_one(calcrc16, tbyte);
2812                    	;  965          }
2813                    	;  966      spiio((calcrc16 >> 8) & 0xff);
2814                    	;  967      spiio(calcrc16 & 0xff);
2815                    	;  968  
2816                    	;  969      /* check data resposnse */
2817                    	;  970      for (tries = 20;
2818                    	;  971              0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
2819                    	;  972              tries--)
2820                    	;  973          ;
2821                    	;  974      if (tries == 0)
2822                    	;  975          {
2823                    	;  976          if (sdtestflg)
2824                    	;  977              {
2825                    	;  978              printf("No data response\n");
2826                    	;  979              } /* sdtestflg */
2827                    	;  980          spideselect();
2828                    	;  981          ledoff();
2829                    	;  982          return (NO);
2830                    	;  983          }
2831                    	;  984      else
2832                    	;  985          {
2833                    	;  986          if (sdtestflg)
2834                    	;  987              {
2835                    	;  988              printf("Data response [%02x]", 0x1f & rbyte);
2836                    	;  989              } /* sdtestflg */
2837                    	;  990          if ((0x1f & rbyte) == 0x05)
2838                    	;  991              {
2839                    	;  992              if (sdtestflg)
2840                    	;  993                  {
2841                    	;  994                  printf(", data accepted\n");
2842                    	;  995                  } /* sdtestflg */
2843                    	;  996              for (nbytes = 9; 0 < nbytes; nbytes--)
2844                    	;  997                  spiio(0xff);
2845                    	;  998              if (sdtestflg)
2846                    	;  999                  {
2847                    	; 1000                  printf("Sent 9*8 (72) clock pulses, select active\n");
2848                    	; 1001                  } /* sdtestflg */
2849                    	; 1002              spideselect();
2850                    	; 1003              ledoff();
2851                    	; 1004              return (YES);
2852                    	; 1005              }
2853                    	; 1006          else
2854                    	; 1007              {
2855                    	; 1008              if (sdtestflg)
2856                    	; 1009                  {
2857                    	; 1010                  printf(", data not accepted\n");
2858                    	; 1011                  } /* sdtestflg */
2859                    	; 1012              spideselect();
2860                    	; 1013              ledoff();
2861                    	; 1014              return (NO);
2862                    	; 1015              }
2863                    	; 1016          }
2864                    	; 1017      }
2865                    	; 1018  
2866                    	; 1019  /* Print data in 512 byte buffer */
2867                    	; 1020  void sddatprt(unsigned char *prtbuf)
2868                    	; 1021      {
2869                    	; 1022      /* Variables used for "pretty-print" */
2870                    	; 1023      int allzero, dmpline, dotprted, lastallz, nbytes;
2871                    	; 1024      unsigned char *prtptr;
2872                    	; 1025  
2873                    	; 1026      prtptr = prtbuf;
2874                    	; 1027      dotprted = NO;
2875                    	; 1028      lastallz = NO;
2876                    	; 1029      for (dmpline = 0; dmpline < 32; dmpline++)
2877                    	; 1030          {
2878                    	; 1031          /* test if all 16 bytes are 0x00 */
2879                    	; 1032          allzero = YES;
2880                    	; 1033          for (nbytes = 0; nbytes < 16; nbytes++)
2881                    	; 1034              {
2882                    	; 1035              if (prtptr[nbytes] != 0)
2883                    	; 1036                  allzero = NO;
2884                    	; 1037              }
2885                    	; 1038          if (lastallz && allzero)
2886                    	; 1039              {
2887                    	; 1040              if (!dotprted)
2888                    	; 1041                  {
2889                    	; 1042                  printf("*\n");
2890                    	; 1043                  dotprted = YES;
2891                    	; 1044                  }
2892                    	; 1045              }
2893                    	; 1046          else
2894                    	; 1047              {
2895                    	; 1048              dotprted = NO;
2896                    	; 1049              /* print offset */
2897                    	; 1050              printf("%04x ", dmpline * 16);
2898                    	; 1051              /* print 16 bytes in hex */
2899                    	; 1052              for (nbytes = 0; nbytes < 16; nbytes++)
2900                    	; 1053                  printf("%02x ", prtptr[nbytes]);
2901                    	; 1054              /* print these bytes in ASCII if printable */
2902                    	; 1055              printf(" |");
2903                    	; 1056              for (nbytes = 0; nbytes < 16; nbytes++)
2904                    	; 1057                  {
2905                    	; 1058                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
2906                    	; 1059                      putchar(prtptr[nbytes]);
2907                    	; 1060                  else
2908                    	; 1061                      putchar('.');
2909                    	; 1062                  }
2910                    	; 1063              printf("|\n");
2911                    	; 1064              }
2912                    	; 1065          prtptr += 16;
2913                    	; 1066          lastallz = allzero;
2914                    	; 1067          }
2915                    	; 1068      }
2916                    	; 1069  
2917                    	; 1070  /* Print GUID (mixed endian format)
2918                    	; 1071   */
2919                    	; 1072  void prtguid(unsigned char *guidptr)
2920                    	; 1073      {
2921                    	; 1074      int index;
2922                    	; 1075  
2923                    	; 1076      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
2924                    	; 1077      printf("%02x%02x-", guidptr[5], guidptr[4]);
2925                    	; 1078      printf("%02x%02x-", guidptr[7], guidptr[6]);
2926                    	; 1079      printf("%02x%02x-", guidptr[8], guidptr[9]);
2927                    	; 1080      printf("%02x%02x%02x%02x%02x%02x",
2928                    	; 1081             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
2929                    	; 1082      }
2930                    	; 1083  
2931                    	; 1084  /* Analyze and print GPT entry
2932                    	; 1085   */
2933                    	; 1086  int prtgptent(unsigned int entryno)
2934                    	; 1087      {
2935                    	; 1088      int index;
2936                    	; 1089      int entryidx;
2937                    	; 1090      int hasname;
2938                    	; 1091      unsigned int block;
2939                    	; 1092      unsigned char *rxdata;
2940                    	; 1093      unsigned char *entryptr;
2941                    	; 1094      unsigned char tstzero = 0;
2942                    	; 1095      unsigned long flba;
2943                    	; 1096      unsigned long llba;
2944                    	; 1097  
2945                    	; 1098      block = 2 + (entryno / 4);
2946                    	; 1099      if ((curblkno != block) || !curblkok)
2947                    	; 1100          {
2948                    	; 1101          if (!sdread(sdrdbuf, block))
2949                    	; 1102              {
2950                    	; 1103              if (sdtestflg)
2951                    	; 1104                  {
2952                    	; 1105                  printf("Can't read GPT entry block\n");
2953                    	; 1106                  return (NO);
2954                    	; 1107                  } /* sdtestflg */
2955                    	; 1108              }
2956                    	; 1109          curblkno = block;
2957                    	; 1110          curblkok = YES;
2958                    	; 1111          }
2959                    	; 1112      rxdata = sdrdbuf;
2960                    	; 1113      entryptr = rxdata + (128 * (entryno % 4));
2961                    	; 1114      for (index = 0; index < 16; index++)
2962                    	; 1115          tstzero |= entryptr[index];
2963                    	; 1116      if (sdtestflg)
2964                    	; 1117          {
2965                    	; 1118          printf("GPT partition entry %d:", entryno + 1);
2966                    	; 1119          } /* sdtestflg */
2967                    	; 1120      if (!tstzero)
2968                    	; 1121          {
2969                    	; 1122          if (sdtestflg)
2970                    	; 1123              {
2971                    	; 1124              printf(" Not used entry\n");
2972                    	; 1125              } /* sdtestflg */
2973                    	; 1126          return (NO);
2974                    	; 1127          }
2975                    	; 1128      if (sdtestflg)
2976                    	; 1129          {
2977                    	; 1130          printf("\n  Partition type GUID: ");
2978                    	; 1131          prtguid(entryptr);
2979                    	; 1132          printf("\n  [");
2980                    	; 1133          for (index = 0; index < 16; index++)
2981                    	; 1134              printf("%02x ", entryptr[index]);
2982                    	; 1135          printf("\b]");
2983                    	; 1136          printf("\n  Unique partition GUID: ");
2984                    	; 1137          prtguid(entryptr + 16);
2985                    	; 1138          printf("\n  [");
2986                    	; 1139          for (index = 0; index < 16; index++)
2987                    	; 1140              printf("%02x ", (entryptr + 16)[index]);
2988                    	; 1141          printf("\b]");
2989                    	; 1142          printf("\n  First LBA: ");
2990                    	; 1143          /* lower 32 bits of LBA should be sufficient (I hope) */
2991                    	; 1144          } /* sdtestflg */
2992                    	; 1145      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
2993                    	; 1146             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
2994                    	; 1147      if (sdtestflg)
2995                    	; 1148          {
2996                    	; 1149          printf("%lu", flba);
2997                    	; 1150          printf(" [");
2998                    	; 1151          for (index = 32; index < (32 + 8); index++)
2999                    	; 1152              printf("%02x ", entryptr[index]);
3000                    	; 1153          printf("\b]");
3001                    	; 1154          printf("\n  Last LBA: ");
3002                    	; 1155          } /* sdtestflg */
3003                    	; 1156      /* lower 32 bits of LBA should be sufficient (I hope) */
3004                    	; 1157      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
3005                    	; 1158             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
3006                    	; 1159  
3007                    	; 1160      if (entryptr[48] & 0x04)
3008                    	; 1161          dskmap[partdsk].bootable = YES;
3009                    	; 1162      dskmap[partdsk].partype = PARTGPT;
3010                    	; 1163      dskmap[partdsk].dskletter = 'A' + partdsk;
3011                    	; 1164      dskmap[partdsk].dskstart = flba;
3012                    	; 1165      dskmap[partdsk].dskend = llba;
3013                    	; 1166      dskmap[partdsk].dsksize = llba - flba + 1;
3014                    	; 1167      memcpy(dskmap[partdsk].dsktype, entryptr, 16);
3015                    	; 1168      partdsk++;
3016                    	; 1169  
3017                    	; 1170      if (sdtestflg)
3018                    	; 1171          {
3019                    	; 1172          printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
3020                    	; 1173          printf(" [");
3021                    	; 1174          for (index = 40; index < (40 + 8); index++)
3022                    	; 1175              printf("%02x ", entryptr[index]);
3023                    	; 1176          printf("\b]");
3024                    	; 1177          printf("\n  Attribute flags: [");
3025                    	; 1178          /* bits 0 - 2 and 60 - 63 should be decoded */
3026                    	; 1179          for (index = 0; index < 8; index++)
3027                    	; 1180              {
3028                    	; 1181              entryidx = index + 48;
3029                    	; 1182              printf("%02x ", entryptr[entryidx]);
3030                    	; 1183              }
3031                    	; 1184          printf("\b]\n  Partition name:  ");
3032                    	; 1185          } /* sdtestflg */
3033                    	; 1186      /* partition name is in UTF-16LE code units */
3034                    	; 1187      hasname = NO;
3035                    	; 1188      for (index = 0; index < 72; index += 2)
3036                    	; 1189          {
3037                    	; 1190          entryidx = index + 56;
3038                    	; 1191          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
3039                    	; 1192              break;
3040                    	; 1193          if (sdtestflg)
3041                    	; 1194              {
3042                    	; 1195              if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
3043                    	; 1196                  putchar(entryptr[entryidx]);
3044                    	; 1197              else
3045                    	; 1198                  putchar('.');
3046                    	; 1199              } /* sdtestflg */
3047                    	; 1200          hasname = YES;
3048                    	; 1201          }
3049                    	; 1202      if (sdtestflg)
3050                    	; 1203          {
3051                    	; 1204          if (!hasname)
3052                    	; 1205              printf("name field empty");
3053                    	; 1206          printf("\n");
3054                    	; 1207          printf("   [");
3055                    	; 1208          for (index = 0; index < 72; index++)
3056                    	; 1209              {
3057                    	; 1210              if (((index & 0xf) == 0) && (index != 0))
3058                    	; 1211                  printf("\n    ");
3059                    	; 1212              entryidx = index + 56;
3060                    	; 1213              printf("%02x ", entryptr[entryidx]);
3061                    	; 1214              }
3062                    	; 1215          printf("\b]\n");
3063                    	; 1216          } /* sdtestflg */
3064                    	; 1217      return (YES);
3065                    	; 1218      }
3066                    	; 1219  
3067                    	; 1220  /* Analyze and print GPT header
3068                    	; 1221   */
3069                    	; 1222  void sdgpthdr(unsigned long block)
3070                    	; 1223      {
3071                    	; 1224      int index;
3072                    	; 1225      unsigned int partno;
3073                    	; 1226      unsigned char *rxdata;
3074                    	; 1227      unsigned long entries;
3075                    	; 1228  
3076                    	; 1229      if (sdtestflg)
3077                    	; 1230          {
3078                    	; 1231          printf("GPT header\n");
3079                    	; 1232          } /* sdtestflg */
3080                    	; 1233      if (!sdread(sdrdbuf, block))
3081                    	; 1234          {
3082                    	; 1235          if (sdtestflg)
3083                    	; 1236              {
3084                    	; 1237              printf("Can't read GPT partition table header\n");
3085                    	; 1238              } /* sdtestflg */
3086                    	; 1239          return;
3087                    	; 1240          }
3088                    	; 1241      curblkno = block;
3089                    	; 1242      curblkok = YES;
3090                    	; 1243  
3091                    	; 1244      rxdata = sdrdbuf;
3092                    	; 1245      if (sdtestflg)
3093                    	; 1246          {
3094                    	; 1247          printf("  Signature: %.8s\n", &rxdata[0]);
3095                    	; 1248          printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
3096                    	; 1249                 (int)rxdata[8] * ((int)rxdata[9] << 8),
3097                    	; 1250                 (int)rxdata[10] + ((int)rxdata[11] << 8),
3098                    	; 1251                 rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
3099                    	; 1252          entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
3100                    	; 1253                    ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
3101                    	; 1254          printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
3102                    	; 1255          } /* sdtestflg */
3103                    	; 1256      for (partno = 0; (partno < 16) && (partdsk < 16); partno++)
3104                    	; 1257          {
3105                    	; 1258          if (!prtgptent(partno))
3106                    	; 1259              {
3107                    	; 1260              if (!sdtestflg)
3108                    	; 1261                  {
3109                    	; 1262                  /* go through all entries if compiled as test program */
3110                    	; 1263                  return;
3111                    	; 1264                  } /* sdtestflg */
3112                    	; 1265              }
3113                    	; 1266          }
3114                    	; 1267      if (sdtestflg)
3115                    	; 1268          {
3116                    	; 1269          printf("First 16 GPT entries scanned\n");
3117                    	; 1270          } /* sdtestflg */
3118                    	; 1271      }
3119                    	; 1272  
3120                    	; 1273  /* Analyze and print MBR partition entry
3121                    	; 1274   * Returns:
3122                    	; 1275   *    -1 if errror - should not happen
3123                    	; 1276   *     0 if not used entry
3124                    	; 1277   *     1 if MBR entry
3125                    	; 1278   *     2 if EBR entry
3126                    	; 1279   *     3 if GTP entry
3127                    	; 1280   */
3128                    	; 1281  int sdmbrentry(unsigned char *partptr)
3129                    	; 1282      {
3130                    	; 1283      int index;
3131                    	; 1284      int parttype;
3132                    	; 1285      unsigned long lbastart;
3133                    	; 1286      unsigned long lbasize;
3134                    	; 1287  
3135                    	; 1288      parttype = PARTMBR;
3136                    	; 1289      if (!partptr[4])
3137                    	; 1290          {
3138                    	; 1291          if (sdtestflg)
3139                    	; 1292              {
3140                    	; 1293              printf("Not used entry\n");
3141                    	; 1294              } /* sdtestflg */
3142                    	; 1295          return (PARTZRO);
3143                    	; 1296          }
3144                    	; 1297      if (sdtestflg)
3145                    	; 1298          {
3146                    	; 1299          printf("Boot indicator: 0x%02x, System ID: 0x%02x\n",
3147                    	; 1300                 partptr[0], partptr[4]);
3148                    	; 1301  
3149                    	; 1302          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
3150                    	; 1303              {
3151                    	; 1304              printf("  Extended partition entry\n");
3152                    	; 1305              }
3153                    	; 1306          if (partptr[0] & 0x01)
3154                    	; 1307              {
3155                    	; 1308              printf("  Unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
3156                    	; 1309              /* this is however discussed
3157                    	; 1310                 https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
3158                    	; 1311              */
3159                    	; 1312              }
3160                    	; 1313          else
3161                    	; 1314              {
3162                    	; 1315              printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3163                    	; 1316                     partptr[1], partptr[2], partptr[3],
3164                    	; 1317                     ((partptr[2] & 0xc0) >> 2) + partptr[3],
3165                    	; 1318                     partptr[1],
3166                    	; 1319                     partptr[2] & 0x3f);
3167                    	; 1320              printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3168                    	; 1321                     partptr[5], partptr[6], partptr[7],
3169                    	; 1322                     ((partptr[6] & 0xc0) >> 2) + partptr[7],
3170                    	; 1323                     partptr[5],
3171                    	; 1324                     partptr[6] & 0x3f);
3172                    	; 1325              }
3173                    	; 1326          } /* sdtestflg */
3174                    	; 1327      /* not showing high 16 bits if 48 bit LBA */
3175                    	; 1328      lbastart = (unsigned long)partptr[8] +
3176                    	; 1329                 ((unsigned long)partptr[9] << 8) +
3177                    	; 1330                 ((unsigned long)partptr[10] << 16) +
3178                    	; 1331                 ((unsigned long)partptr[11] << 24);
3179                    	; 1332      lbasize = (unsigned long)partptr[12] +
3180                    	; 1333                ((unsigned long)partptr[13] << 8) +
3181                    	; 1334                ((unsigned long)partptr[14] << 16) +
3182                    	; 1335                ((unsigned long)partptr[15] << 24);
3183                    	; 1336  
3184                    	; 1337      if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
3185                    	; 1338          {
3186                    	; 1339          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
3187                    	; 1340              {
3188                    	; 1341              parttype = PARTEBR;
3189                    	; 1342              if (curblkno == 0) /* points to EBR in the MBR */
3190                    	; 1343                  {
3191                    	; 1344                  ebrnext = 0;
3192                    	; 1345                  dskmap[partdsk].partype = EBRCONT;
3193                    	; 1346                  dskmap[partdsk].dskletter = 'A' + partdsk;
3194                    	; 1347                  dskmap[partdsk].dskstart = lbastart;
3195                    	; 1348                  dskmap[partdsk].dskend = lbastart + lbasize - 1;
3196                    	; 1349                  dskmap[partdsk].dsksize = lbasize;
3197                    	; 1350                  dskmap[partdsk].dsktype[0] = partptr[4];
3198                    	; 1351                  partdsk++;
3199                    	; 1352                  ebrrecs[ebrrecidx++] = lbastart; /* save to handle later */
3200                    	; 1353                  }
3201                    	; 1354              else
3202                    	; 1355                  {
3203                    	; 1356                  ebrnext = curblkno + lbastart;
3204                    	; 1357                  }
3205                    	; 1358              }
3206                    	; 1359          else
3207                    	; 1360              {
3208                    	; 1361              if (partptr[0] & 0x80)
3209                    	; 1362                  dskmap[partdsk].bootable = YES;
3210                    	; 1363              if (curblkno == 0)
3211                    	; 1364                  dskmap[partdsk].partype = PARTMBR;
3212                    	; 1365              else
3213                    	; 1366                  dskmap[partdsk].partype = PARTEBR;
3214                    	; 1367              dskmap[partdsk].dskletter = 'A' + partdsk;
3215                    	; 1368              dskmap[partdsk].dskstart = curblkno + lbastart;
3216                    	; 1369              dskmap[partdsk].dskend = curblkno + lbastart + lbasize - 1;
3217                    	; 1370              dskmap[partdsk].dsksize = lbasize;
3218                    	; 1371              dskmap[partdsk].dsktype[0] = partptr[4];
3219                    	; 1372              partdsk++;
3220                    	; 1373              }
3221                    	; 1374          }
3222                    	; 1375  
3223                    	; 1376      if (sdtestflg)
3224                    	; 1377          {
3225                    	; 1378          printf("  partition start LBA: %lu [%08lx]\n",
3226                    	; 1379                 curblkno + lbastart, curblkno + lbastart);
3227                    	; 1380          printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
3228                    	; 1381                 lbasize, lbasize, lbasize >> 11);
3229                    	; 1382          } /* sdtestflg */
3230                    	; 1383      if (partptr[4] == 0xee) /* GPT partitions */
3231                    	; 1384          {
3232                    	; 1385          parttype = PARTGPT;
3233                    	; 1386          if (sdtestflg)
3234                    	; 1387              {
3235                    	; 1388              printf("GTP partitions\n");
3236                    	; 1389              } /* sdtestflg */
3237                    	; 1390          sdgpthdr(lbastart); /* handle GTP partitions */
3238                    	; 1391          /* re-read MBR on sector 0
3239                    	; 1392             This is probably not needed as there
3240                    	; 1393             is only one entry (the first one)
3241                    	; 1394             in the MBR when using GPT */
3242                    	; 1395          if (sdread(sdrdbuf, 0))
3243                    	; 1396              {
3244                    	; 1397              curblkno = 0;
3245                    	; 1398              curblkok = YES;
3246                    	; 1399              }
3247                    	; 1400          else
3248                    	; 1401              {
3249                    	; 1402              if (sdtestflg)
3250                    	; 1403                  {
3251                    	; 1404                  printf("  can't read MBR on sector 0\n");
3252                    	; 1405                  } /* sdtestflg */
3253                    	; 1406              return(-1);
3254                    	; 1407              }
3255                    	; 1408          }
3256                    	; 1409      return (parttype);
3257                    	; 1410      }
3258                    	; 1411  
3259                    	; 1412  /* Read and analyze MBR/EBR partition sector block
3260                    	; 1413   * and go through and print partition entries.
3261                    	; 1414   */
3262                    	; 1415  void sdmbrpart(unsigned long sector)
3263                    	; 1416      {
3264                    	; 1417      int partidx;  /* partition index 1 - 4 */
3265                    	; 1418      int cpartidx; /* chain partition index 1 - 4 */
3266                    	; 1419      int chainidx;
3267                    	; 1420      int enttype;
3268                    	; 1421      unsigned char *entp; /* pointer to partition entry */
3269                    	; 1422      char *mbrebr;
3270                    	; 1423  
3271                    	; 1424      if (sdtestflg)
3272                    	; 1425          {
3273                    	; 1426          if (sector == 0) /* if sector 0 it is MBR else it is EBR */
3274                    	; 1427              mbrebr = "MBR";
3275                    	; 1428          else
3276                    	; 1429              mbrebr = "EBR";
3277                    	; 1430          printf("Read %s from sector %lu\n", mbrebr, sector);
3278                    	; 1431          } /* sdtestflg */
3279                    	; 1432      if (sdread(sdrdbuf, sector))
3280                    	; 1433          {
3281                    	; 1434          curblkno = sector;
3282                    	; 1435          curblkok = YES;
3283                    	; 1436          }
3284                    	; 1437      else
3285                    	; 1438          {
3286                    	; 1439          if (sdtestflg)
3287                    	; 1440              {
3288                    	; 1441              printf("  can't read %s sector %lu\n", mbrebr, sector);
3289                    	; 1442              } /* sdtestflg */
3290                    	; 1443          return;
3291                    	; 1444          }
3292                    	; 1445      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
3293                    	; 1446          {
3294                    	; 1447          if (sdtestflg)
3295                    	; 1448              {
3296                    	; 1449              printf("  no %s boot signature found\n", mbrebr);
3297                    	; 1450              } /* sdtestflg */
3298                    	; 1451          return;
3299                    	; 1452          }
3300                    	; 1453      if (curblkno == 0)
3301                    	; 1454          {
3302                    	; 1455          memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
3303                    	; 1456          if (sdtestflg)
3304                    	; 1457              {
3305                    	; 1458  
3306                    	; 1459              printf("  disk identifier: 0x%02x%02x%02x%02x\n",
3307                    	; 1460                     dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
3308                    	; 1461              } /* sdtestflg */
3309                    	; 1462          }
3310                    	; 1463      /* go through MBR partition entries until first empty */
3311                    	; 1464      /* !!as the MBR entry routine is called recusively a way is
3312                    	; 1465         needed to read sector 0 when going back to MBR if
3313                    	; 1466         there is a primary partition entry after an EBR entry!! */
3314                    	; 1467      entp = &sdrdbuf[0x01be] ;
3315                    	; 1468      for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
3316                    	; 1469          {
3317                    	; 1470          if (sdtestflg)
3318                    	; 1471              {
3319                    	; 1472              printf("%s partition entry %d: ", mbrebr, partidx);
3320                    	; 1473              } /* sdtestflg */
3321                    	; 1474          enttype = sdmbrentry(entp);
3322                    	; 1475          if (enttype == -1) /* read error */
3323                    	; 1476                   return;
3324                    	; 1477          else if (enttype == PARTZRO)
3325                    	; 1478              {
3326                    	; 1479              if (!sdtestflg)
3327                    	; 1480                  {
3328                    	; 1481                  /* if compiled as test program show also empty partitions */
3329                    	; 1482                  break;
3330                    	; 1483                  } /* sdtestflg */
3331                    	; 1484              }
3332                    	; 1485          }
3333                    	; 1486      /* now handle the previously saved EBR partition sectors */
3334                    	; 1487      for (partidx = 0; (partidx < ebrrecidx) && (partdsk < 16); partidx++)
3335                    	; 1488          {
3336                    	; 1489          if (sdread(sdrdbuf, ebrrecs[partidx]))
3337                    	; 1490              {
3338                    	; 1491              curblkno = ebrrecs[partidx];
3339                    	; 1492              curblkok = YES;
3340                    	; 1493              }
3341                    	; 1494          else
3342                    	; 1495              {
3343                    	; 1496              if (sdtestflg)
3344                    	; 1497                  {
3345                    	; 1498                  printf("  can't read %s sector %lu\n", mbrebr, sector);
3346                    	; 1499                  } /* sdtestflg */
3347                    	; 1500              return;
3348                    	; 1501              }
3349                    	; 1502          entp = &sdrdbuf[0x01be] ;
3350                    	; 1503          for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
3351                    	; 1504              {
3352                    	; 1505              if (sdtestflg)
3353                    	; 1506                  {
3354                    	; 1507                  printf("EBR partition entry %d: ", partidx);
3355                    	; 1508                  } /* sdtestflg */
3356                    	; 1509              enttype = sdmbrentry(entp);
3357                    	; 1510              if (enttype == -1) /* read error */
3358                    	; 1511                   return;
3359                    	; 1512              else if (enttype == PARTZRO) /* empty partition entry */
3360                    	; 1513                  {
3361                    	; 1514                  if (sdtestflg)
3362                    	; 1515                      {
3363                    	; 1516                      /* if compiled as test program show also empty partitions */
3364                    	; 1517                      printf("Empty partition entry\n");
3365                    	; 1518                      } /* sdtestflg */
3366                    	; 1519                  else
3367                    	; 1520                      break;
3368                    	; 1521                  }
3369                    	; 1522              else if (enttype == PARTEBR) /* next chained EBR */
3370                    	; 1523                  {
3371                    	; 1524                  if (sdtestflg)
3372                    	; 1525                      {
3373                    	; 1526                      printf("EBR chain\n");
3374                    	; 1527                      } /* sdtestflg */
3375                    	; 1528                  /* follow the EBR chain */
3376                    	; 1529                  for (chainidx = 0;
3377                    	; 1530                      ebrnext && (chainidx < 16) && (partdsk < 16);
3378                    	; 1531                      chainidx++)
3379                    	; 1532                      {
3380                    	; 1533                      /* ugly hack to stop reading the same sector */
3381                    	; 1534                      if (ebrnext == curblkno)
3382                    	; 1535                           break;
3383                    	; 1536                      if (sdread(sdrdbuf, ebrnext))
3384                    	; 1537                          {
3385                    	; 1538                          curblkno = ebrnext;
3386                    	; 1539                          curblkok = YES;
3387                    	; 1540                          }
3388                    	; 1541                      else
3389                    	; 1542                          {
3390                    	; 1543                          if (sdtestflg)
3391                    	; 1544                              {
3392                    	; 1545                              printf("  can't read %s sector %lu\n", mbrebr, sector);
3393                    	; 1546                              } /* sdtestflg */
3394                    	; 1547                          return;
3395                    	; 1548                          }
3396                    	; 1549                      entp = &sdrdbuf[0x01be] ;
3397                    	; 1550                      for (cpartidx = 1;
3398                    	; 1551                          (cpartidx <= 4) && (partdsk < 16);
3399                    	; 1552                          cpartidx++, entp += 16)
3400                    	; 1553                          {
3401                    	; 1554                          if (sdtestflg)
3402                    	; 1555                              {
3403                    	; 1556                              printf("EBR chained  partition entry %d: ",
3404                    	; 1557                                   cpartidx);
3405                    	; 1558                              } /* sdtestflg */
3406                    	; 1559                          enttype = sdmbrentry(entp);
3407                    	; 1560                          if (enttype == -1) /* read error */
3408                    	; 1561                              return;
3409    429E  C30000    		jp	c.rets
3410                    	L5662:
3411    42A1  0A        		.byte	10
3412    42A2  7A        		.byte	122
3413    42A3  38        		.byte	56
3414    42A4  30        		.byte	48
3415    42A5  73        		.byte	115
3416    42A6  64        		.byte	100
3417    42A7  62        		.byte	98
3418    42A8  74        		.byte	116
3419    42A9  20        		.byte	32
3420    42AA  00        		.byte	0
3421                    	L5762:
3422    42AB  76        		.byte	118
3423    42AC  65        		.byte	101
3424    42AD  72        		.byte	114
3425    42AE  73        		.byte	115
3426    42AF  69        		.byte	105
3427    42B0  6F        		.byte	111
3428    42B1  6E        		.byte	110
3429    42B2  20        		.byte	32
3430    42B3  30        		.byte	48
3431    42B4  2E        		.byte	46
3432    42B5  37        		.byte	55
3433    42B6  2C        		.byte	44
3434    42B7  20        		.byte	32
3435    42B8  00        		.byte	0
3436                    	L5072:
3437    42B9  0A        		.byte	10
3438    42BA  00        		.byte	0
3439                    	L5172:
3440    42BB  63        		.byte	99
3441    42BC  6D        		.byte	109
3442    42BD  64        		.byte	100
3443    42BE  20        		.byte	32
3444    42BF  28        		.byte	40
3445    42C0  3F        		.byte	63
3446    42C1  20        		.byte	32
3447    42C2  66        		.byte	102
3448    42C3  6F        		.byte	111
3449    42C4  72        		.byte	114
3450    42C5  20        		.byte	32
3451    42C6  68        		.byte	104
3452    42C7  65        		.byte	101
3453    42C8  6C        		.byte	108
3454    42C9  70        		.byte	112
3455    42CA  29        		.byte	41
3456    42CB  3A        		.byte	58
3457    42CC  20        		.byte	32
3458    42CD  00        		.byte	0
3459                    	L5272:
3460    42CE  20        		.byte	32
3461    42CF  3F        		.byte	63
3462    42D0  20        		.byte	32
3463    42D1  2D        		.byte	45
3464    42D2  20        		.byte	32
3465    42D3  68        		.byte	104
3466    42D4  65        		.byte	101
3467    42D5  6C        		.byte	108
3468    42D6  70        		.byte	112
3469    42D7  0A        		.byte	10
3470    42D8  00        		.byte	0
3471                    	L5372:
3472    42D9  0A        		.byte	10
3473    42DA  7A        		.byte	122
3474    42DB  38        		.byte	56
3475    42DC  30        		.byte	48
3476    42DD  73        		.byte	115
3477    42DE  64        		.byte	100
3478    42DF  62        		.byte	98
3479    42E0  74        		.byte	116
3480    42E1  20        		.byte	32
3481    42E2  00        		.byte	0
3482                    	L5472:
3483    42E3  76        		.byte	118
3484    42E4  65        		.byte	101
3485    42E5  72        		.byte	114
3486    42E6  73        		.byte	115
3487    42E7  69        		.byte	105
3488    42E8  6F        		.byte	111
3489    42E9  6E        		.byte	110
3490    42EA  20        		.byte	32
3491    42EB  30        		.byte	48
3492    42EC  2E        		.byte	46
3493    42ED  37        		.byte	55
3494    42EE  2C        		.byte	44
3495    42EF  20        		.byte	32
3496    42F0  00        		.byte	0
3497                    	L5572:
3498    42F1  0A        		.byte	10
3499    42F2  43        		.byte	67
3500    42F3  6F        		.byte	111
3501    42F4  6D        		.byte	109
3502    42F5  6D        		.byte	109
3503    42F6  61        		.byte	97
3504    42F7  6E        		.byte	110
3505    42F8  64        		.byte	100
3506    42F9  73        		.byte	115
3507    42FA  3A        		.byte	58
3508    42FB  0A        		.byte	10
3509    42FC  00        		.byte	0
3510                    	L5672:
3511    42FD  20        		.byte	32
3512    42FE  20        		.byte	32
3513    42FF  3F        		.byte	63
3514    4300  20        		.byte	32
3515    4301  2D        		.byte	45
3516    4302  20        		.byte	32
3517    4303  68        		.byte	104
3518    4304  65        		.byte	101
3519    4305  6C        		.byte	108
3520    4306  70        		.byte	112
3521    4307  0A        		.byte	10
3522    4308  00        		.byte	0
3523                    	L5772:
3524    4309  20        		.byte	32
3525    430A  20        		.byte	32
3526    430B  62        		.byte	98
3527    430C  20        		.byte	32
3528    430D  2D        		.byte	45
3529    430E  20        		.byte	32
3530    430F  62        		.byte	98
3531    4310  6F        		.byte	111
3532    4311  6F        		.byte	111
3533    4312  74        		.byte	116
3534    4313  20        		.byte	32
3535    4314  66        		.byte	102
3536    4315  72        		.byte	114
3537    4316  6F        		.byte	111
3538    4317  6D        		.byte	109
3539    4318  20        		.byte	32
3540    4319  53        		.byte	83
3541    431A  44        		.byte	68
3542    431B  20        		.byte	32
3543    431C  63        		.byte	99
3544    431D  61        		.byte	97
3545    431E  72        		.byte	114
3546    431F  64        		.byte	100
3547    4320  0A        		.byte	10
3548    4321  00        		.byte	0
3549                    	L5003:
3550    4322  20        		.byte	32
3551    4323  20        		.byte	32
3552    4324  64        		.byte	100
3553    4325  20        		.byte	32
3554    4326  2D        		.byte	45
3555    4327  20        		.byte	32
3556    4328  64        		.byte	100
3557    4329  65        		.byte	101
3558    432A  62        		.byte	98
3559    432B  75        		.byte	117
3560    432C  67        		.byte	103
3561    432D  20        		.byte	32
3562    432E  6F        		.byte	111
3563    432F  6E        		.byte	110
3564    4330  2F        		.byte	47
3565    4331  6F        		.byte	111
3566    4332  66        		.byte	102
3567    4333  66        		.byte	102
3568    4334  0A        		.byte	10
3569    4335  00        		.byte	0
3570                    	L5103:
3571    4336  20        		.byte	32
3572    4337  20        		.byte	32
3573    4338  69        		.byte	105
3574    4339  20        		.byte	32
3575    433A  2D        		.byte	45
3576    433B  20        		.byte	32
3577    433C  69        		.byte	105
3578    433D  6E        		.byte	110
3579    433E  69        		.byte	105
3580    433F  74        		.byte	116
3581    4340  69        		.byte	105
3582    4341  61        		.byte	97
3583    4342  6C        		.byte	108
3584    4343  69        		.byte	105
3585    4344  7A        		.byte	122
3586    4345  65        		.byte	101
3587    4346  20        		.byte	32
3588    4347  53        		.byte	83
3589    4348  44        		.byte	68
3590    4349  20        		.byte	32
3591    434A  63        		.byte	99
3592    434B  61        		.byte	97
3593    434C  72        		.byte	114
3594    434D  64        		.byte	100
3595    434E  0A        		.byte	10
3596    434F  00        		.byte	0
3597                    	L5203:
3598    4350  20        		.byte	32
3599    4351  20        		.byte	32
3600    4352  6C        		.byte	108
3601    4353  20        		.byte	32
3602    4354  2D        		.byte	45
3603    4355  20        		.byte	32
3604    4356  70        		.byte	112
3605    4357  72        		.byte	114
3606    4358  69        		.byte	105
3607    4359  6E        		.byte	110
3608    435A  74        		.byte	116
3609    435B  20        		.byte	32
3610    435C  70        		.byte	112
3611    435D  61        		.byte	97
3612    435E  72        		.byte	114
3613    435F  74        		.byte	116
3614    4360  69        		.byte	105
3615    4361  74        		.byte	116
3616    4362  69        		.byte	105
3617    4363  6F        		.byte	111
3618    4364  6E        		.byte	110
3619    4365  20        		.byte	32
3620    4366  6C        		.byte	108
3621    4367  61        		.byte	97
3622    4368  79        		.byte	121
3623    4369  6F        		.byte	111
3624    436A  75        		.byte	117
3625    436B  74        		.byte	116
3626    436C  0A        		.byte	10
3627    436D  00        		.byte	0
3628                    	L5303:
3629    436E  20        		.byte	32
3630    436F  20        		.byte	32
3631    4370  6E        		.byte	110
3632    4371  20        		.byte	32
3633    4372  2D        		.byte	45
3634    4373  20        		.byte	32
3635    4374  73        		.byte	115
3636    4375  65        		.byte	101
3637    4376  74        		.byte	116
3638    4377  2F        		.byte	47
3639    4378  73        		.byte	115
3640    4379  68        		.byte	104
3641    437A  6F        		.byte	111
3642    437B  77        		.byte	119
3643    437C  20        		.byte	32
3644    437D  62        		.byte	98
3645    437E  6C        		.byte	108
3646    437F  6F        		.byte	111
3647    4380  63        		.byte	99
3648    4381  6B        		.byte	107
3649    4382  20        		.byte	32
3650    4383  23        		.byte	35
3651    4384  4E        		.byte	78
3652    4385  20        		.byte	32
3653    4386  74        		.byte	116
3654    4387  6F        		.byte	111
3655    4388  20        		.byte	32
3656    4389  72        		.byte	114
3657    438A  65        		.byte	101
3658    438B  61        		.byte	97
3659    438C  64        		.byte	100
3660    438D  0A        		.byte	10
3661    438E  00        		.byte	0
3662                    	L5403:
3663    438F  20        		.byte	32
3664    4390  20        		.byte	32
3665    4391  70        		.byte	112
3666    4392  20        		.byte	32
3667    4393  2D        		.byte	45
3668    4394  20        		.byte	32
3669    4395  70        		.byte	112
3670    4396  72        		.byte	114
3671    4397  69        		.byte	105
3672    4398  6E        		.byte	110
3673    4399  74        		.byte	116
3674    439A  20        		.byte	32
3675    439B  62        		.byte	98
3676    439C  6C        		.byte	108
3677    439D  6F        		.byte	111
3678    439E  63        		.byte	99
3679    439F  6B        		.byte	107
3680    43A0  20        		.byte	32
3681    43A1  6C        		.byte	108
3682    43A2  61        		.byte	97
3683    43A3  73        		.byte	115
3684    43A4  74        		.byte	116
3685    43A5  20        		.byte	32
3686    43A6  72        		.byte	114
3687    43A7  65        		.byte	101
3688    43A8  61        		.byte	97
3689    43A9  64        		.byte	100
3690    43AA  2F        		.byte	47
3691    43AB  74        		.byte	116
3692    43AC  6F        		.byte	111
3693    43AD  20        		.byte	32
3694    43AE  77        		.byte	119
3695    43AF  72        		.byte	114
3696    43B0  69        		.byte	105
3697    43B1  74        		.byte	116
3698    43B2  65        		.byte	101
3699    43B3  0A        		.byte	10
3700    43B4  00        		.byte	0
3701                    	L5503:
3702    43B5  20        		.byte	32
3703    43B6  20        		.byte	32
3704    43B7  72        		.byte	114
3705    43B8  20        		.byte	32
3706    43B9  2D        		.byte	45
3707    43BA  20        		.byte	32
3708    43BB  72        		.byte	114
3709    43BC  65        		.byte	101
3710    43BD  61        		.byte	97
3711    43BE  64        		.byte	100
3712    43BF  20        		.byte	32
3713    43C0  62        		.byte	98
3714    43C1  6C        		.byte	108
3715    43C2  6F        		.byte	111
3716    43C3  63        		.byte	99
3717    43C4  6B        		.byte	107
3718    43C5  20        		.byte	32
3719    43C6  23        		.byte	35
3720    43C7  4E        		.byte	78
3721    43C8  0A        		.byte	10
3722    43C9  00        		.byte	0
3723                    	L5603:
3724    43CA  20        		.byte	32
3725    43CB  20        		.byte	32
3726    43CC  73        		.byte	115
3727    43CD  20        		.byte	32
3728    43CE  2D        		.byte	45
3729    43CF  20        		.byte	32
3730    43D0  70        		.byte	112
3731    43D1  72        		.byte	114
3732    43D2  69        		.byte	105
3733    43D3  6E        		.byte	110
3734    43D4  74        		.byte	116
3735    43D5  20        		.byte	32
3736    43D6  53        		.byte	83
3737    43D7  44        		.byte	68
3738    43D8  20        		.byte	32
3739    43D9  72        		.byte	114
3740    43DA  65        		.byte	101
3741    43DB  67        		.byte	103
3742    43DC  69        		.byte	105
3743    43DD  73        		.byte	115
3744    43DE  74        		.byte	116
3745    43DF  65        		.byte	101
3746    43E0  72        		.byte	114
3747    43E1  73        		.byte	115
3748    43E2  0A        		.byte	10
3749    43E3  00        		.byte	0
3750                    	L5703:
3751    43E4  20        		.byte	32
3752    43E5  20        		.byte	32
3753    43E6  74        		.byte	116
3754    43E7  20        		.byte	32
3755    43E8  2D        		.byte	45
3756    43E9  20        		.byte	32
3757    43EA  74        		.byte	116
3758    43EB  65        		.byte	101
3759    43EC  73        		.byte	115
3760    43ED  74        		.byte	116
3761    43EE  20        		.byte	32
3762    43EF  70        		.byte	112
3763    43F0  72        		.byte	114
3764    43F1  6F        		.byte	111
3765    43F2  62        		.byte	98
3766    43F3  65        		.byte	101
3767    43F4  20        		.byte	32
3768    43F5  53        		.byte	83
3769    43F6  44        		.byte	68
3770    43F7  20        		.byte	32
3771    43F8  63        		.byte	99
3772    43F9  61        		.byte	97
3773    43FA  72        		.byte	114
3774    43FB  64        		.byte	100
3775    43FC  0A        		.byte	10
3776    43FD  00        		.byte	0
3777                    	L5013:
3778    43FE  20        		.byte	32
3779    43FF  20        		.byte	32
3780    4400  75        		.byte	117
3781    4401  20        		.byte	32
3782    4402  2D        		.byte	45
3783    4403  20        		.byte	32
3784    4404  75        		.byte	117
3785    4405  70        		.byte	112
3786    4406  6C        		.byte	108
3787    4407  6F        		.byte	111
3788    4408  61        		.byte	97
3789    4409  64        		.byte	100
3790    440A  20        		.byte	32
3791    440B  70        		.byte	112
3792    440C  72        		.byte	114
3793    440D  6F        		.byte	111
3794    440E  67        		.byte	103
3795    440F  72        		.byte	114
3796    4410  61        		.byte	97
3797    4411  6D        		.byte	109
3798    4412  20        		.byte	32
3799    4413  77        		.byte	119
3800    4414  69        		.byte	105
3801    4415  74        		.byte	116
3802    4416  68        		.byte	104
3803    4417  20        		.byte	32
3804    4418  58        		.byte	88
3805    4419  6D        		.byte	109
3806    441A  6F        		.byte	111
3807    441B  64        		.byte	100
3808    441C  65        		.byte	101
3809    441D  6D        		.byte	109
3810    441E  0A        		.byte	10
3811    441F  00        		.byte	0
3812                    	L5113:
3813    4420  20        		.byte	32
3814    4421  20        		.byte	32
3815    4422  77        		.byte	119
3816    4423  20        		.byte	32
3817    4424  2D        		.byte	45
3818    4425  20        		.byte	32
3819    4426  72        		.byte	114
3820    4427  65        		.byte	101
3821    4428  61        		.byte	97
3822    4429  64        		.byte	100
3823    442A  20        		.byte	32
3824    442B  62        		.byte	98
3825    442C  6C        		.byte	108
3826    442D  6F        		.byte	111
3827    442E  63        		.byte	99
3828    442F  6B        		.byte	107
3829    4430  20        		.byte	32
3830    4431  23        		.byte	35
3831    4432  4E        		.byte	78
3832    4433  0A        		.byte	10
3833    4434  00        		.byte	0
3834                    	L5213:
3835    4435  20        		.byte	32
3836    4436  20        		.byte	32
3837    4437  43        		.byte	67
3838    4438  74        		.byte	116
3839    4439  72        		.byte	114
3840    443A  6C        		.byte	108
3841    443B  2D        		.byte	45
3842    443C  43        		.byte	67
3843    443D  20        		.byte	32
3844    443E  74        		.byte	116
3845    443F  6F        		.byte	111
3846    4440  20        		.byte	32
3847    4441  72        		.byte	114
3848    4442  65        		.byte	101
3849    4443  6C        		.byte	108
3850    4444  6F        		.byte	111
3851    4445  61        		.byte	97
3852    4446  64        		.byte	100
3853    4447  20        		.byte	32
3854    4448  6D        		.byte	109
3855    4449  6F        		.byte	111
3856    444A  6E        		.byte	110
3857    444B  69        		.byte	105
3858    444C  74        		.byte	116
3859    444D  6F        		.byte	111
3860    444E  72        		.byte	114
3861    444F  2E        		.byte	46
3862    4450  0A        		.byte	10
3863    4451  00        		.byte	0
3864                    	L5313:
3865    4452  20        		.byte	32
3866    4453  64        		.byte	100
3867    4454  20        		.byte	32
3868    4455  2D        		.byte	45
3869    4456  20        		.byte	32
3870    4457  62        		.byte	98
3871    4458  6F        		.byte	111
3872    4459  6F        		.byte	111
3873    445A  74        		.byte	116
3874    445B  20        		.byte	32
3875    445C  66        		.byte	102
3876    445D  72        		.byte	114
3877    445E  6F        		.byte	111
3878    445F  6D        		.byte	109
3879    4460  20        		.byte	32
3880    4461  53        		.byte	83
3881    4462  44        		.byte	68
3882    4463  20        		.byte	32
3883    4464  63        		.byte	99
3884    4465  61        		.byte	97
3885    4466  72        		.byte	114
3886    4467  64        		.byte	100
3887    4468  20        		.byte	32
3888    4469  2D        		.byte	45
3889    446A  20        		.byte	32
3890    446B  00        		.byte	0
3891                    	L5413:
3892    446C  69        		.byte	105
3893    446D  6D        		.byte	109
3894    446E  70        		.byte	112
3895    446F  6C        		.byte	108
3896    4470  65        		.byte	101
3897    4471  6D        		.byte	109
3898    4472  65        		.byte	101
3899    4473  6E        		.byte	110
3900    4474  74        		.byte	116
3901    4475  61        		.byte	97
3902    4476  74        		.byte	116
3903    4477  69        		.byte	105
3904    4478  6F        		.byte	111
3905    4479  6E        		.byte	110
3906    447A  20        		.byte	32
3907    447B  6F        		.byte	111
3908    447C  6E        		.byte	110
3909    447D  67        		.byte	103
3910    447E  6F        		.byte	111
3911    447F  69        		.byte	105
3912    4480  6E        		.byte	110
3913    4481  67        		.byte	103
3914    4482  0A        		.byte	10
3915    4483  00        		.byte	0
3916                    	L5513:
3917    4484  20        		.byte	32
3918    4485  64        		.byte	100
3919    4486  20        		.byte	32
3920    4487  2D        		.byte	45
3921    4488  20        		.byte	32
3922    4489  74        		.byte	116
3923    448A  6F        		.byte	111
3924    448B  67        		.byte	103
3925    448C  67        		.byte	103
3926    448D  6C        		.byte	108
3927    448E  65        		.byte	101
3928    448F  20        		.byte	32
3929    4490  64        		.byte	100
3930    4491  65        		.byte	101
3931    4492  62        		.byte	98
3932    4493  75        		.byte	117
3933    4494  67        		.byte	103
3934    4495  20        		.byte	32
3935    4496  66        		.byte	102
3936    4497  6C        		.byte	108
3937    4498  61        		.byte	97
3938    4499  67        		.byte	103
3939    449A  20        		.byte	32
3940    449B  2D        		.byte	45
3941    449C  20        		.byte	32
3942    449D  00        		.byte	0
3943                    	L5613:
3944    449E  4F        		.byte	79
3945    449F  46        		.byte	70
3946    44A0  46        		.byte	70
3947    44A1  0A        		.byte	10
3948    44A2  00        		.byte	0
3949                    	L5713:
3950    44A3  4F        		.byte	79
3951    44A4  4E        		.byte	78
3952    44A5  0A        		.byte	10
3953    44A6  00        		.byte	0
3954                    	L5023:
3955    44A7  20        		.byte	32
3956    44A8  69        		.byte	105
3957    44A9  20        		.byte	32
3958    44AA  2D        		.byte	45
3959    44AB  20        		.byte	32
3960    44AC  69        		.byte	105
3961    44AD  6E        		.byte	110
3962    44AE  69        		.byte	105
3963    44AF  74        		.byte	116
3964    44B0  69        		.byte	105
3965    44B1  61        		.byte	97
3966    44B2  6C        		.byte	108
3967    44B3  69        		.byte	105
3968    44B4  7A        		.byte	122
3969    44B5  65        		.byte	101
3970    44B6  20        		.byte	32
3971    44B7  53        		.byte	83
3972    44B8  44        		.byte	68
3973    44B9  20        		.byte	32
3974    44BA  63        		.byte	99
3975    44BB  61        		.byte	97
3976    44BC  72        		.byte	114
3977    44BD  64        		.byte	100
3978    44BE  00        		.byte	0
3979                    	L5123:
3980    44BF  20        		.byte	32
3981    44C0  2D        		.byte	45
3982    44C1  20        		.byte	32
3983    44C2  6F        		.byte	111
3984    44C3  6B        		.byte	107
3985    44C4  0A        		.byte	10
3986    44C5  00        		.byte	0
3987                    	L5223:
3988    44C6  20        		.byte	32
3989    44C7  2D        		.byte	45
3990    44C8  20        		.byte	32
3991    44C9  6E        		.byte	110
3992    44CA  6F        		.byte	111
3993    44CB  74        		.byte	116
3994    44CC  20        		.byte	32
3995    44CD  69        		.byte	105
3996    44CE  6E        		.byte	110
3997    44CF  73        		.byte	115
3998    44D0  65        		.byte	101
3999    44D1  72        		.byte	114
4000    44D2  74        		.byte	116
4001    44D3  65        		.byte	101
4002    44D4  64        		.byte	100
4003    44D5  20        		.byte	32
4004    44D6  6F        		.byte	111
4005    44D7  72        		.byte	114
4006    44D8  20        		.byte	32
4007    44D9  66        		.byte	102
4008    44DA  61        		.byte	97
4009    44DB  75        		.byte	117
4010    44DC  6C        		.byte	108
4011    44DD  74        		.byte	116
4012    44DE  79        		.byte	121
4013    44DF  0A        		.byte	10
4014    44E0  00        		.byte	0
4015                    	L5323:
4016    44E1  20        		.byte	32
4017    44E2  6C        		.byte	108
4018    44E3  20        		.byte	32
4019    44E4  2D        		.byte	45
4020    44E5  20        		.byte	32
4021    44E6  70        		.byte	112
4022    44E7  72        		.byte	114
4023    44E8  69        		.byte	105
4024    44E9  6E        		.byte	110
4025    44EA  74        		.byte	116
4026    44EB  20        		.byte	32
4027    44EC  70        		.byte	112
4028    44ED  61        		.byte	97
4029    44EE  72        		.byte	114
4030    44EF  74        		.byte	116
4031    44F0  69        		.byte	105
4032    44F1  74        		.byte	116
4033    44F2  69        		.byte	105
4034    44F3  6F        		.byte	111
4035    44F4  6E        		.byte	110
4036    44F5  20        		.byte	32
4037    44F6  6C        		.byte	108
4038    44F7  61        		.byte	97
4039    44F8  79        		.byte	121
4040    44F9  6F        		.byte	111
4041    44FA  75        		.byte	117
4042    44FB  74        		.byte	116
4043    44FC  0A        		.byte	10
4044    44FD  00        		.byte	0
4045                    	L5423:
4046    44FE  20        		.byte	32
4047    44FF  2D        		.byte	45
4048    4500  20        		.byte	32
4049    4501  53        		.byte	83
4050    4502  44        		.byte	68
4051    4503  20        		.byte	32
4052    4504  6E        		.byte	110
4053    4505  6F        		.byte	111
4054    4506  74        		.byte	116
4055    4507  20        		.byte	32
4056    4508  69        		.byte	105
4057    4509  6E        		.byte	110
4058    450A  69        		.byte	105
4059    450B  74        		.byte	116
4060    450C  69        		.byte	105
4061    450D  61        		.byte	97
4062    450E  6C        		.byte	108
4063    450F  69        		.byte	105
4064    4510  7A        		.byte	122
4065    4511  65        		.byte	101
4066    4512  64        		.byte	100
4067    4513  20        		.byte	32
4068    4514  6F        		.byte	111
4069    4515  72        		.byte	114
4070    4516  20        		.byte	32
4071    4517  69        		.byte	105
4072    4518  6E        		.byte	110
4073    4519  73        		.byte	115
4074    451A  65        		.byte	101
4075    451B  72        		.byte	114
4076    451C  74        		.byte	116
4077    451D  65        		.byte	101
4078    451E  64        		.byte	100
4079    451F  20        		.byte	32
4080    4520  6F        		.byte	111
4081    4521  72        		.byte	114
4082    4522  20        		.byte	32
4083    4523  66        		.byte	102
4084    4524  61        		.byte	97
4085    4525  75        		.byte	117
4086    4526  6C        		.byte	108
4087    4527  74        		.byte	116
4088    4528  79        		.byte	121
4089    4529  0A        		.byte	10
4090    452A  00        		.byte	0
4091                    	L212:
4092    452B  00        		.byte	0
4093    452C  00        		.byte	0
4094    452D  00        		.byte	0
4095    452E  00        		.byte	0
   0                    	L5523:
   1    452F  20        		.byte	32
   2    4530  20        		.byte	32
   3    4531  20        		.byte	32
   4    4532  20        		.byte	32
   5    4533  20        		.byte	32
   6    4534  20        		.byte	32
   7    4535  44        		.byte	68
   8    4536  69        		.byte	105
   9    4537  73        		.byte	115
  10    4538  6B        		.byte	107
  11    4539  20        		.byte	32
  12    453A  70        		.byte	112
  13    453B  61        		.byte	97
  14    453C  72        		.byte	114
  15    453D  74        		.byte	116
  16    453E  69        		.byte	105
  17    453F  74        		.byte	116
  18    4540  69        		.byte	105
  19    4541  6F        		.byte	111
  20    4542  6E        		.byte	110
  21    4543  20        		.byte	32
  22    4544  73        		.byte	115
  23    4545  65        		.byte	101
  24    4546  63        		.byte	99
  25    4547  74        		.byte	116
  26    4548  6F        		.byte	111
  27    4549  72        		.byte	114
  28    454A  73        		.byte	115
  29    454B  20        		.byte	32
  30    454C  6F        		.byte	111
  31    454D  6E        		.byte	110
  32    454E  20        		.byte	32
  33    454F  53        		.byte	83
  34    4550  44        		.byte	68
  35    4551  20        		.byte	32
  36    4552  63        		.byte	99
  37    4553  61        		.byte	97
  38    4554  72        		.byte	114
  39    4555  64        		.byte	100
  40    4556  0A        		.byte	10
  41    4557  00        		.byte	0
  42                    	L5623:
  43    4558  20        		.byte	32
  44    4559  20        		.byte	32
  45    455A  20        		.byte	32
  46    455B  20        		.byte	32
  47    455C  20        		.byte	32
  48    455D  20        		.byte	32
  49    455E  20        		.byte	32
  50    455F  4D        		.byte	77
  51    4560  42        		.byte	66
  52    4561  52        		.byte	82
  53    4562  20        		.byte	32
  54    4563  64        		.byte	100
  55    4564  69        		.byte	105
  56    4565  73        		.byte	115
  57    4566  6B        		.byte	107
  58    4567  20        		.byte	32
  59    4568  69        		.byte	105
  60    4569  64        		.byte	100
  61    456A  65        		.byte	101
  62    456B  6E        		.byte	110
  63    456C  74        		.byte	116
  64    456D  69        		.byte	105
  65    456E  66        		.byte	102
  66    456F  69        		.byte	105
  67    4570  65        		.byte	101
  68    4571  72        		.byte	114
  69    4572  3A        		.byte	58
  70    4573  20        		.byte	32
  71    4574  30        		.byte	48
  72    4575  78        		.byte	120
  73    4576  25        		.byte	37
  74    4577  30        		.byte	48
  75    4578  32        		.byte	50
  76    4579  78        		.byte	120
  77    457A  25        		.byte	37
  78    457B  30        		.byte	48
  79    457C  32        		.byte	50
  80    457D  78        		.byte	120
  81    457E  25        		.byte	37
  82    457F  30        		.byte	48
  83    4580  32        		.byte	50
  84    4581  78        		.byte	120
  85    4582  25        		.byte	37
  86    4583  30        		.byte	48
  87    4584  32        		.byte	50
  88    4585  78        		.byte	120
  89    4586  0A        		.byte	10
  90    4587  00        		.byte	0
  91                    	L5723:
  92    4588  20        		.byte	32
  93    4589  44        		.byte	68
  94    458A  69        		.byte	105
  95    458B  73        		.byte	115
  96    458C  6B        		.byte	107
  97    458D  20        		.byte	32
  98    458E  20        		.byte	32
  99    458F  20        		.byte	32
 100    4590  20        		.byte	32
 101    4591  20        		.byte	32
 102    4592  53        		.byte	83
 103    4593  74        		.byte	116
 104    4594  61        		.byte	97
 105    4595  72        		.byte	114
 106    4596  74        		.byte	116
 107    4597  20        		.byte	32
 108    4598  20        		.byte	32
 109    4599  20        		.byte	32
 110    459A  20        		.byte	32
 111    459B  20        		.byte	32
 112    459C  20        		.byte	32
 113    459D  45        		.byte	69
 114    459E  6E        		.byte	110
 115    459F  64        		.byte	100
 116    45A0  20        		.byte	32
 117    45A1  20        		.byte	32
 118    45A2  20        		.byte	32
 119    45A3  20        		.byte	32
 120    45A4  20        		.byte	32
 121    45A5  53        		.byte	83
 122    45A6  69        		.byte	105
 123    45A7  7A        		.byte	122
 124    45A8  65        		.byte	101
 125    45A9  20        		.byte	32
 126    45AA  50        		.byte	80
 127    45AB  61        		.byte	97
 128    45AC  72        		.byte	114
 129    45AD  74        		.byte	116
 130    45AE  20        		.byte	32
 131    45AF  54        		.byte	84
 132    45B0  79        		.byte	121
 133    45B1  70        		.byte	112
 134    45B2  65        		.byte	101
 135    45B3  20        		.byte	32
 136    45B4  49        		.byte	73
 137    45B5  64        		.byte	100
 138    45B6  0A        		.byte	10
 139    45B7  00        		.byte	0
 140                    	L5033:
 141    45B8  20        		.byte	32
 142    45B9  2D        		.byte	45
 143    45BA  2D        		.byte	45
 144    45BB  2D        		.byte	45
 145    45BC  2D        		.byte	45
 146    45BD  20        		.byte	32
 147    45BE  20        		.byte	32
 148    45BF  20        		.byte	32
 149    45C0  20        		.byte	32
 150    45C1  20        		.byte	32
 151    45C2  2D        		.byte	45
 152    45C3  2D        		.byte	45
 153    45C4  2D        		.byte	45
 154    45C5  2D        		.byte	45
 155    45C6  2D        		.byte	45
 156    45C7  20        		.byte	32
 157    45C8  20        		.byte	32
 158    45C9  20        		.byte	32
 159    45CA  20        		.byte	32
 160    45CB  20        		.byte	32
 161    45CC  20        		.byte	32
 162    45CD  2D        		.byte	45
 163    45CE  2D        		.byte	45
 164    45CF  2D        		.byte	45
 165    45D0  20        		.byte	32
 166    45D1  20        		.byte	32
 167    45D2  20        		.byte	32
 168    45D3  20        		.byte	32
 169    45D4  20        		.byte	32
 170    45D5  2D        		.byte	45
 171    45D6  2D        		.byte	45
 172    45D7  2D        		.byte	45
 173    45D8  2D        		.byte	45
 174    45D9  20        		.byte	32
 175    45DA  2D        		.byte	45
 176    45DB  2D        		.byte	45
 177    45DC  2D        		.byte	45
 178    45DD  2D        		.byte	45
 179    45DE  20        		.byte	32
 180    45DF  2D        		.byte	45
 181    45E0  2D        		.byte	45
 182    45E1  2D        		.byte	45
 183    45E2  2D        		.byte	45
 184    45E3  20        		.byte	32
 185    45E4  2D        		.byte	45
 186    45E5  2D        		.byte	45
 187    45E6  0A        		.byte	10
 188    45E7  00        		.byte	0
 189                    	L5133:
 190    45E8  25        		.byte	37
 191    45E9  32        		.byte	50
 192    45EA  64        		.byte	100
 193    45EB  20        		.byte	32
 194    45EC  28        		.byte	40
 195    45ED  25        		.byte	37
 196    45EE  63        		.byte	99
 197    45EF  29        		.byte	41
 198    45F0  25        		.byte	37
 199    45F1  63        		.byte	99
 200    45F2  00        		.byte	0
 201                    	L5233:
 202    45F3  25        		.byte	37
 203    45F4  38        		.byte	56
 204    45F5  6C        		.byte	108
 205    45F6  75        		.byte	117
 206    45F7  20        		.byte	32
 207    45F8  25        		.byte	37
 208    45F9  38        		.byte	56
 209    45FA  6C        		.byte	108
 210    45FB  75        		.byte	117
 211    45FC  20        		.byte	32
 212    45FD  25        		.byte	37
 213    45FE  38        		.byte	56
 214    45FF  6C        		.byte	108
 215    4600  75        		.byte	117
 216    4601  20        		.byte	32
 217    4602  00        		.byte	0
 218                    	L5333:
 219    4603  20        		.byte	32
 220    4604  45        		.byte	69
 221    4605  42        		.byte	66
 222    4606  52        		.byte	82
 223    4607  20        		.byte	32
 224    4608  63        		.byte	99
 225    4609  6F        		.byte	111
 226    460A  6E        		.byte	110
 227    460B  74        		.byte	116
 228    460C  61        		.byte	97
 229    460D  69        		.byte	105
 230    460E  6E        		.byte	110
 231    460F  65        		.byte	101
 232    4610  72        		.byte	114
 233    4611  0A        		.byte	10
 234    4612  00        		.byte	0
 235                    	L5433:
 236    4613  20        		.byte	32
 237    4614  47        		.byte	71
 238    4615  50        		.byte	80
 239    4616  54        		.byte	84
 240    4617  20        		.byte	32
 241    4618  00        		.byte	0
 242                    	L5533:
 243    4619  43        		.byte	67
 244    461A  50        		.byte	80
 245    461B  2F        		.byte	47
 246    461C  4D        		.byte	77
 247    461D  20        		.byte	32
 248    461E  00        		.byte	0
 249                    	L5633:
 250    461F  20        		.byte	32
 251    4620  3F        		.byte	63
 252    4621  3F        		.byte	63
 253    4622  20        		.byte	32
 254    4623  20        		.byte	32
 255    4624  00        		.byte	0
 256                    	L5733:
 257    4625  20        		.byte	32
 258    4626  45        		.byte	69
 259    4627  42        		.byte	66
 260    4628  52        		.byte	82
 261    4629  20        		.byte	32
 262    462A  00        		.byte	0
 263                    	L5043:
 264    462B  20        		.byte	32
 265    462C  4D        		.byte	77
 266    462D  42        		.byte	66
 267    462E  52        		.byte	82
 268    462F  20        		.byte	32
 269    4630  00        		.byte	0
 270                    	L5143:
 271    4631  43        		.byte	67
 272    4632  50        		.byte	80
 273    4633  2F        		.byte	47
 274    4634  4D        		.byte	77
 275    4635  20        		.byte	32
 276    4636  00        		.byte	0
 277                    	L5243:
 278    4637  43        		.byte	67
 279    4638  6F        		.byte	111
 280    4639  64        		.byte	100
 281    463A  65        		.byte	101
 282    463B  20        		.byte	32
 283    463C  00        		.byte	0
 284                    	L5343:
 285    463D  20        		.byte	32
 286    463E  3F        		.byte	63
 287    463F  3F        		.byte	63
 288    4640  20        		.byte	32
 289    4641  20        		.byte	32
 290    4642  00        		.byte	0
 291                    	L5443:
 292    4643  30        		.byte	48
 293    4644  78        		.byte	120
 294    4645  25        		.byte	37
 295    4646  30        		.byte	48
 296    4647  32        		.byte	50
 297    4648  78        		.byte	120
 298    4649  00        		.byte	0
 299                    	L5543:
 300    464A  0A        		.byte	10
 301    464B  00        		.byte	0
 302                    	L5643:
 303    464C  20        		.byte	32
 304    464D  6E        		.byte	110
 305    464E  20        		.byte	32
 306    464F  2D        		.byte	45
 307    4650  20        		.byte	32
 308    4651  62        		.byte	98
 309    4652  6C        		.byte	108
 310    4653  6F        		.byte	111
 311    4654  63        		.byte	99
 312    4655  6B        		.byte	107
 313    4656  20        		.byte	32
 314    4657  6E        		.byte	110
 315    4658  75        		.byte	117
 316    4659  6D        		.byte	109
 317    465A  62        		.byte	98
 318    465B  65        		.byte	101
 319    465C  72        		.byte	114
 320    465D  3A        		.byte	58
 321    465E  20        		.byte	32
 322    465F  00        		.byte	0
 323                    	L5743:
 324    4660  25        		.byte	37
 325    4661  6C        		.byte	108
 326    4662  75        		.byte	117
 327    4663  00        		.byte	0
 328                    	L5053:
 329    4664  25        		.byte	37
 330    4665  6C        		.byte	108
 331    4666  75        		.byte	117
 332    4667  00        		.byte	0
 333                    	L5153:
 334    4668  0A        		.byte	10
 335    4669  00        		.byte	0
 336                    	L5253:
 337    466A  20        		.byte	32
 338    466B  70        		.byte	112
 339    466C  20        		.byte	32
 340    466D  2D        		.byte	45
 341    466E  20        		.byte	32
 342    466F  70        		.byte	112
 343    4670  72        		.byte	114
 344    4671  69        		.byte	105
 345    4672  6E        		.byte	110
 346    4673  74        		.byte	116
 347    4674  20        		.byte	32
 348    4675  64        		.byte	100
 349    4676  61        		.byte	97
 350    4677  74        		.byte	116
 351    4678  61        		.byte	97
 352    4679  20        		.byte	32
 353    467A  62        		.byte	98
 354    467B  6C        		.byte	108
 355    467C  6F        		.byte	111
 356    467D  63        		.byte	99
 357    467E  6B        		.byte	107
 358    467F  20        		.byte	32
 359    4680  25        		.byte	37
 360    4681  6C        		.byte	108
 361    4682  75        		.byte	117
 362    4683  0A        		.byte	10
 363    4684  00        		.byte	0
 364                    	L5353:
 365    4685  20        		.byte	32
 366    4686  72        		.byte	114
 367    4687  20        		.byte	32
 368    4688  2D        		.byte	45
 369    4689  20        		.byte	32
 370    468A  72        		.byte	114
 371    468B  65        		.byte	101
 372    468C  61        		.byte	97
 373    468D  64        		.byte	100
 374    468E  20        		.byte	32
 375    468F  62        		.byte	98
 376    4690  6C        		.byte	108
 377    4691  6F        		.byte	111
 378    4692  63        		.byte	99
 379    4693  6B        		.byte	107
 380    4694  00        		.byte	0
 381                    	L5453:
 382    4695  20        		.byte	32
 383    4696  2D        		.byte	45
 384    4697  20        		.byte	32
 385    4698  6E        		.byte	110
 386    4699  6F        		.byte	111
 387    469A  74        		.byte	116
 388    469B  20        		.byte	32
 389    469C  69        		.byte	105
 390    469D  6E        		.byte	110
 391    469E  69        		.byte	105
 392    469F  74        		.byte	116
 393    46A0  69        		.byte	105
 394    46A1  61        		.byte	97
 395    46A2  6C        		.byte	108
 396    46A3  69        		.byte	105
 397    46A4  7A        		.byte	122
 398    46A5  65        		.byte	101
 399    46A6  64        		.byte	100
 400    46A7  20        		.byte	32
 401    46A8  6F        		.byte	111
 402    46A9  72        		.byte	114
 403    46AA  20        		.byte	32
 404    46AB  69        		.byte	105
 405    46AC  6E        		.byte	110
 406    46AD  73        		.byte	115
 407    46AE  65        		.byte	101
 408    46AF  72        		.byte	114
 409    46B0  74        		.byte	116
 410    46B1  65        		.byte	101
 411    46B2  64        		.byte	100
 412    46B3  20        		.byte	32
 413    46B4  6F        		.byte	111
 414    46B5  72        		.byte	114
 415    46B6  20        		.byte	32
 416    46B7  66        		.byte	102
 417    46B8  61        		.byte	97
 418    46B9  75        		.byte	117
 419    46BA  6C        		.byte	108
 420    46BB  74        		.byte	116
 421    46BC  79        		.byte	121
 422    46BD  0A        		.byte	10
 423    46BE  00        		.byte	0
 424                    	L5553:
 425    46BF  20        		.byte	32
 426    46C0  2D        		.byte	45
 427    46C1  20        		.byte	32
 428    46C2  6F        		.byte	111
 429    46C3  6B        		.byte	107
 430    46C4  0A        		.byte	10
 431    46C5  00        		.byte	0
 432                    	L5653:
 433    46C6  20        		.byte	32
 434    46C7  2D        		.byte	45
 435    46C8  20        		.byte	32
 436    46C9  72        		.byte	114
 437    46CA  65        		.byte	101
 438    46CB  61        		.byte	97
 439    46CC  64        		.byte	100
 440    46CD  20        		.byte	32
 441    46CE  65        		.byte	101
 442    46CF  72        		.byte	114
 443    46D0  72        		.byte	114
 444    46D1  6F        		.byte	111
 445    46D2  72        		.byte	114
 446    46D3  0A        		.byte	10
 447    46D4  00        		.byte	0
 448                    	L5753:
 449    46D5  20        		.byte	32
 450    46D6  73        		.byte	115
 451    46D7  20        		.byte	32
 452    46D8  2D        		.byte	45
 453    46D9  20        		.byte	32
 454    46DA  70        		.byte	112
 455    46DB  72        		.byte	114
 456    46DC  69        		.byte	105
 457    46DD  6E        		.byte	110
 458    46DE  74        		.byte	116
 459    46DF  20        		.byte	32
 460    46E0  53        		.byte	83
 461    46E1  44        		.byte	68
 462    46E2  20        		.byte	32
 463    46E3  72        		.byte	114
 464    46E4  65        		.byte	101
 465    46E5  67        		.byte	103
 466    46E6  69        		.byte	105
 467    46E7  73        		.byte	115
 468    46E8  74        		.byte	116
 469    46E9  65        		.byte	101
 470    46EA  72        		.byte	114
 471    46EB  73        		.byte	115
 472    46EC  0A        		.byte	10
 473    46ED  00        		.byte	0
 474                    	L5063:
 475    46EE  20        		.byte	32
 476    46EF  74        		.byte	116
 477    46F0  20        		.byte	32
 478    46F1  2D        		.byte	45
 479    46F2  20        		.byte	32
 480    46F3  74        		.byte	116
 481    46F4  65        		.byte	101
 482    46F5  73        		.byte	115
 483    46F6  74        		.byte	116
 484    46F7  20        		.byte	32
 485    46F8  69        		.byte	105
 486    46F9  66        		.byte	102
 487    46FA  20        		.byte	32
 488    46FB  63        		.byte	99
 489    46FC  61        		.byte	97
 490    46FD  72        		.byte	114
 491    46FE  64        		.byte	100
 492    46FF  20        		.byte	32
 493    4700  69        		.byte	105
 494    4701  6E        		.byte	110
 495    4702  73        		.byte	115
 496    4703  65        		.byte	101
 497    4704  72        		.byte	114
 498    4705  74        		.byte	116
 499    4706  65        		.byte	101
 500    4707  64        		.byte	100
 501    4708  0A        		.byte	10
 502    4709  00        		.byte	0
 503                    	L5163:
 504    470A  20        		.byte	32
 505    470B  2D        		.byte	45
 506    470C  20        		.byte	32
 507    470D  6F        		.byte	111
 508    470E  6B        		.byte	107
 509    470F  0A        		.byte	10
 510    4710  00        		.byte	0
 511                    	L5263:
 512    4711  20        		.byte	32
 513    4712  2D        		.byte	45
 514    4713  20        		.byte	32
 515    4714  6E        		.byte	110
 516    4715  6F        		.byte	111
 517    4716  74        		.byte	116
 518    4717  20        		.byte	32
 519    4718  69        		.byte	105
 520    4719  6E        		.byte	110
 521    471A  69        		.byte	105
 522    471B  74        		.byte	116
 523    471C  69        		.byte	105
 524    471D  61        		.byte	97
 525    471E  6C        		.byte	108
 526    471F  69        		.byte	105
 527    4720  7A        		.byte	122
 528    4721  65        		.byte	101
 529    4722  64        		.byte	100
 530    4723  20        		.byte	32
 531    4724  6F        		.byte	111
 532    4725  72        		.byte	114
 533    4726  20        		.byte	32
 534    4727  69        		.byte	105
 535    4728  6E        		.byte	110
 536    4729  73        		.byte	115
 537    472A  65        		.byte	101
 538    472B  72        		.byte	114
 539    472C  74        		.byte	116
 540    472D  65        		.byte	101
 541    472E  64        		.byte	100
 542    472F  20        		.byte	32
 543    4730  6F        		.byte	111
 544    4731  72        		.byte	114
 545    4732  20        		.byte	32
 546    4733  66        		.byte	102
 547    4734  61        		.byte	97
 548    4735  75        		.byte	117
 549    4736  6C        		.byte	108
 550    4737  74        		.byte	116
 551    4738  79        		.byte	121
 552    4739  0A        		.byte	10
 553    473A  00        		.byte	0
 554                    	L5363:
 555    473B  20        		.byte	32
 556    473C  75        		.byte	117
 557    473D  20        		.byte	32
 558    473E  2D        		.byte	45
 559    473F  20        		.byte	32
 560    4740  75        		.byte	117
 561    4741  70        		.byte	112
 562    4742  6C        		.byte	108
 563    4743  6F        		.byte	111
 564    4744  61        		.byte	97
 565    4745  64        		.byte	100
 566    4746  20        		.byte	32
 567    4747  77        		.byte	119
 568    4748  69        		.byte	105
 569    4749  74        		.byte	116
 570    474A  68        		.byte	104
 571    474B  20        		.byte	32
 572    474C  58        		.byte	88
 573    474D  6D        		.byte	109
 574    474E  6F        		.byte	111
 575    474F  64        		.byte	100
 576    4750  65        		.byte	101
 577    4751  6D        		.byte	109
 578    4752  20        		.byte	32
 579    4753  2D        		.byte	45
 580    4754  20        		.byte	32
 581    4755  00        		.byte	0
 582                    	L5463:
 583    4756  69        		.byte	105
 584    4757  6D        		.byte	109
 585    4758  70        		.byte	112
 586    4759  6C        		.byte	108
 587    475A  65        		.byte	101
 588    475B  6D        		.byte	109
 589    475C  65        		.byte	101
 590    475D  6E        		.byte	110
 591    475E  74        		.byte	116
 592    475F  61        		.byte	97
 593    4760  74        		.byte	116
 594    4761  69        		.byte	105
 595    4762  6F        		.byte	111
 596    4763  6E        		.byte	110
 597    4764  20        		.byte	32
 598    4765  6F        		.byte	111
 599    4766  6E        		.byte	110
 600    4767  67        		.byte	103
 601    4768  6F        		.byte	111
 602    4769  69        		.byte	105
 603    476A  6E        		.byte	110
 604    476B  67        		.byte	103
 605    476C  0A        		.byte	10
 606    476D  00        		.byte	0
 607                    	L5563:
 608    476E  20        		.byte	32
 609    476F  77        		.byte	119
 610    4770  20        		.byte	32
 611    4771  2D        		.byte	45
 612    4772  20        		.byte	32
 613    4773  77        		.byte	119
 614    4774  72        		.byte	114
 615    4775  69        		.byte	105
 616    4776  74        		.byte	116
 617    4777  65        		.byte	101
 618    4778  20        		.byte	32
 619    4779  62        		.byte	98
 620    477A  6C        		.byte	108
 621    477B  6F        		.byte	111
 622    477C  63        		.byte	99
 623    477D  6B        		.byte	107
 624    477E  00        		.byte	0
 625                    	L5663:
 626    477F  20        		.byte	32
 627    4780  2D        		.byte	45
 628    4781  20        		.byte	32
 629    4782  6E        		.byte	110
 630    4783  6F        		.byte	111
 631    4784  74        		.byte	116
 632    4785  20        		.byte	32
 633    4786  69        		.byte	105
 634    4787  6E        		.byte	110
 635    4788  69        		.byte	105
 636    4789  74        		.byte	116
 637    478A  69        		.byte	105
 638    478B  61        		.byte	97
 639    478C  6C        		.byte	108
 640    478D  69        		.byte	105
 641    478E  7A        		.byte	122
 642    478F  65        		.byte	101
 643    4790  64        		.byte	100
 644    4791  20        		.byte	32
 645    4792  6F        		.byte	111
 646    4793  72        		.byte	114
 647    4794  20        		.byte	32
 648    4795  69        		.byte	105
 649    4796  6E        		.byte	110
 650    4797  73        		.byte	115
 651    4798  65        		.byte	101
 652    4799  72        		.byte	114
 653    479A  74        		.byte	116
 654    479B  65        		.byte	101
 655    479C  64        		.byte	100
 656    479D  20        		.byte	32
 657    479E  6F        		.byte	111
 658    479F  72        		.byte	114
 659    47A0  20        		.byte	32
 660    47A1  66        		.byte	102
 661    47A2  61        		.byte	97
 662    47A3  75        		.byte	117
 663    47A4  6C        		.byte	108
 664    47A5  74        		.byte	116
 665    47A6  79        		.byte	121
 666    47A7  0A        		.byte	10
 667    47A8  00        		.byte	0
 668                    	L5763:
 669    47A9  20        		.byte	32
 670    47AA  2D        		.byte	45
 671    47AB  20        		.byte	32
 672    47AC  6F        		.byte	111
 673    47AD  6B        		.byte	107
 674    47AE  0A        		.byte	10
 675    47AF  00        		.byte	0
 676                    	L5073:
 677    47B0  20        		.byte	32
 678    47B1  2D        		.byte	45
 679    47B2  20        		.byte	32
 680    47B3  77        		.byte	119
 681    47B4  72        		.byte	114
 682    47B5  69        		.byte	105
 683    47B6  74        		.byte	116
 684    47B7  65        		.byte	101
 685    47B8  20        		.byte	32
 686    47B9  65        		.byte	101
 687    47BA  72        		.byte	114
 688    47BB  72        		.byte	114
 689    47BC  6F        		.byte	111
 690    47BD  72        		.byte	114
 691    47BE  0A        		.byte	10
 692    47BF  00        		.byte	0
 693                    	L5173:
 694    47C0  72        		.byte	114
 695    47C1  65        		.byte	101
 696    47C2  6C        		.byte	108
 697    47C3  6F        		.byte	111
 698    47C4  61        		.byte	97
 699    47C5  64        		.byte	100
 700    47C6  69        		.byte	105
 701    47C7  6E        		.byte	110
 702    47C8  67        		.byte	103
 703    47C9  20        		.byte	32
 704    47CA  6D        		.byte	109
 705    47CB  6F        		.byte	111
 706    47CC  6E        		.byte	110
 707    47CD  69        		.byte	105
 708    47CE  74        		.byte	116
 709    47CF  6F        		.byte	111
 710    47D0  72        		.byte	114
 711    47D1  20        		.byte	32
 712    47D2  66        		.byte	102
 713    47D3  72        		.byte	114
 714    47D4  6F        		.byte	111
 715    47D5  6D        		.byte	109
 716    47D6  20        		.byte	32
 717    47D7  45        		.byte	69
 718    47D8  50        		.byte	80
 719    47D9  52        		.byte	82
 720    47DA  4F        		.byte	79
 721    47DB  4D        		.byte	77
 722    47DC  0A        		.byte	10
 723    47DD  00        		.byte	0
 724                    	L5273:
 725    47DE  20        		.byte	32
 726    47DF  69        		.byte	105
 727    47E0  6E        		.byte	110
 728    47E1  76        		.byte	118
 729    47E2  61        		.byte	97
 730    47E3  6C        		.byte	108
 731    47E4  69        		.byte	105
 732    47E5  64        		.byte	100
 733    47E6  20        		.byte	32
 734    47E7  63        		.byte	99
 735    47E8  6F        		.byte	111
 736    47E9  6D        		.byte	109
 737    47EA  6D        		.byte	109
 738    47EB  61        		.byte	97
 739    47EC  6E        		.byte	110
 740    47ED  64        		.byte	100
 741    47EE  0A        		.byte	10
 742    47EF  00        		.byte	0
 743                    	L1126:
 744    47F0  0C        		.byte	12
 745    47F1  00        		.byte	0
 746    47F2  6C        		.byte	108
 747    47F3  00        		.byte	0
 748    47F4  4E49      		.word	L1336
 749    47F6  7C4D      		.word	L1507
 750    47F8  264C      		.word	L1366
 751    47FA  7C4D      		.word	L1507
 752    47FC  784C      		.word	L1666
 753    47FE  7C4D      		.word	L1507
 754    4800  954C      		.word	L1766
 755    4802  E74C      		.word	L1376
 756    4804  F34C      		.word	L1476
 757    4806  124D      		.word	L1776
 758    4808  7C4D      		.word	L1507
 759    480A  214D      		.word	L1007
 760    480C  00        		.byte	0
 761    480D  00        		.byte	0
 762    480E  05        		.byte	5
 763    480F  00        		.byte	0
 764    4810  704D      		.word	L1407
 765    4812  0300      		.word	3
 766    4814  8648      		.word	L1326
 767    4816  3F00      		.word	63
 768    4818  F548      		.word	L1426
 769    481A  6200      		.word	98
 770    481C  0449      		.word	L1526
 771    481E  6400      		.word	100
 772    4820  2F49      		.word	L1036
 773    4822  6900      		.word	105
 774    4824  7C4D      		.word	L1507
 775                    	; 1562                          }
 776                    	; 1563                      }
 777                    	; 1564                  }
 778                    	; 1565              }
 779                    	; 1566          }
 780                    	; 1567      }
 781                    	; 1568  
 782                    	; 1569  /* Test init, read and partitions on SD card over the SPI interface
 783                    	; 1570   *
 784                    	; 1571   */
 785                    	; 1572  int main()
 786                    	; 1573      {
 787                    	_main:
 788    4826  CD0000    		call	c.savs0
 789    4829  21E2FF    		ld	hl,65506
 790    482C  39        		add	hl,sp
 791    482D  F9        		ld	sp,hl
 792                    	; 1574      char txtin[10];
 793                    	; 1575      int cmdin;
 794                    	; 1576      int idx;
 795                    	; 1577      int cmpidx;
 796                    	; 1578      unsigned char *cmpptr;
 797                    	; 1579      int inlength;
 798                    	; 1580      unsigned long blockno;
 799                    	; 1581  
 800                    	; 1582      blockno = 0;
 801    482E  97        		sub	a
 802    482F  DD77E2    		ld	(ix-30),a
 803    4832  DD77E3    		ld	(ix-29),a
 804    4835  DD77E4    		ld	(ix-28),a
 805    4838  DD77E5    		ld	(ix-27),a
 806                    	; 1583      curblkno = 0;
 807                    	; 1584      curblkok = NO;
 808    483B  210000    		ld	hl,0
 809                    	;    1  /*  z80sdbt.c Boot and test program trying to make a unified prog.
 810                    	;    2   *
 811                    	;    3   *  Boot code for my DIY Z80 Computer. This
 812                    	;    4   *  program is compiled with Whitesmiths/COSMIC
 813                    	;    5   *  C compiler for Z80.
 814                    	;    6   *
 815                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
 816                    	;    8   *
 817                    	;    9   *  Initializes the hardware and detects the
 818                    	;   10   *  presence and partitioning of an attached SD card.
 819                    	;   11   *
 820                    	;   12   *  You are free to use, modify, and redistribute
 821                    	;   13   *  this source code. No warranties are given.
 822                    	;   14   *  Hastily Cobbled Together 2021 and 2022
 823                    	;   15   *  by Hans-Ake Lund
 824                    	;   16   *
 825                    	;   17   */
 826                    	;   18  
 827                    	;   19  #include <std.h>
 828                    	;   20  #include "z80computer.h"
 829                    	;   21  #include "builddate.h"
 830                    	;   22  
 831                    	;   23  #define PRGNAME "\nz80sdbt "
 832                    	;   24  #define VERSION "version 0.7, "
 833                    	;   25  /* This code should be cleaned up when
 834                    	;   26     remaining functions are implemented
 835                    	;   27   */
 836                    	;   28  #define PARTZRO 0  /* Empty partition entry */
 837                    	;   29  #define PARTMBR 1  /* MBR partition */
 838                    	;   30  #define PARTEBR 2  /* EBR logical partition */
 839                    	;   31  #define PARTGPT 3  /* GPT partition */
 840                    	;   32  #define EBRCONT 20 /* EBR container partition in MBR */
 841                    	;   33  
 842                    	;   34  struct partentry
 843                    	;   35      {
 844                    	;   36      char partype;
 845                    	;   37      char dskletter;
 846                    	;   38      int bootable;
 847                    	;   39      unsigned long dskstart;
 848                    	;   40      unsigned long dskend;
 849                    	;   41      unsigned long dsksize;
 850                    	;   42      unsigned char dsktype[16];
 851                    	;   43      } dskmap[16];
 852                    	;   44  
 853                    	;   45  unsigned char dsksign[4]; /* MBR/EBR disk signature */
 854                    	;   46  
 855                    	;   47  /* Function prototypes */
 856                    	;   48  void sdmbrpart(unsigned long);
 857                    	;   49  
 858                    	;   50  /* Response length in bytes
 859                    	;   51   */
 860                    	;   52  #define R1_LEN 1
 861                    	;   53  #define R3_LEN 5
 862                    	;   54  #define R7_LEN 5
 863                    	;   55  
 864                    	;   56  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
 865                    	;   57   * (The CRC7 byte in the tables below are only for information,
 866                    	;   58   * it is calculated by the sdcommand routine.)
 867                    	;   59   */
 868                    	;   60  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
 869                    	;   61  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
 870                    	;   62  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
 871                    	;   63  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
 872                    	;   64  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
 873                    	;   65  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
 874                    	;   66  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
 875                    	;   67  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
 876                    	;   68  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
 877                    	;   69  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
 878                    	;   70  
 879                    	;   71  /* Partition identifiers
 880                    	;   72   */
 881                    	;   73  /* For GPT I have decided that a CP/M partition
 882                    	;   74   * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
 883                    	;   75   */
 884                    	;   76  const unsigned char gptcpm[] =
 885                    	;   77      {
 886                    	;   78      0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
 887                    	;   79      0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
 888                    	;   80      };
 889                    	;   81  /* For MBR/EBR the partition type for CP/M is 0x52
 890                    	;   82   * according to: https://en.wikipedia.org/wiki/Partition_type
 891                    	;   83   */
 892                    	;   84  const unsigned char mbrcpm = 0x52;    /* CP/M partition */
 893                    	;   85  const unsigned char mbrexcode = 0x5f; /* Z80 executable code partition */
 894                    	;   86  /* has a special format that */
 895                    	;   87  /* includes number of sectors to */
 896                    	;   88  /* load and a signature, TBD */
 897                    	;   89  
 898                    	;   90  /* Buffers
 899                    	;   91   */
 900                    	;   92  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
 901                    	;   93  
 902                    	;   94  unsigned char ocrreg[4];     /* SD card OCR register */
 903                    	;   95  unsigned char cidreg[16];    /* SD card CID register */
 904                    	;   96  unsigned char csdreg[16];    /* SD card CSD register */
 905                    	;   97  unsigned long ebrrecs[4];    /* detected EBR records to process */
 906                    	;   98  int ebrrecidx; /* how many EBR records that are populated */
 907                    	;   99  unsigned long ebrnext; /* next chained ebr record */
 908                    	;  100  
 909                    	;  101  /* Variables
 910                    	;  102   */
 911                    	;  103  int curblkok;  /* if YES curblockno is read into buffer */
 912                    	;  104  int partdsk;   /* partition/disk number, 0 = disk A */
 913                    	;  105  int sdinitok;  /* SD card initialized and ready */
 914                    	;  106  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
 915                    	;  107  unsigned long blkmult;   /* block address multiplier */
 916                    	;  108  unsigned long curblkno;  /* block in buffer if curblkok == YES */
 917                    	;  109  
 918                    	;  110  /* debug bool */
 919                    	;  111  int sdtestflg;
 920                    	;  112  
 921                    	;  113  /* CRC routines from:
 922                    	;  114   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
 923                    	;  115   */
 924                    	;  116  
 925                    	;  117  /*
 926                    	;  118  // Calculate CRC7
 927                    	;  119  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
 928                    	;  120  // input:
 929                    	;  121  //   crcIn - the CRC before (0 for first step)
 930                    	;  122  //   data - byte for CRC calculation
 931                    	;  123  // return: the new CRC7
 932                    	;  124  */
 933                    	;  125  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
 934                    	;  126      {
 935                    	;  127      const unsigned char g = 0x89;
 936                    	;  128      unsigned char i;
 937                    	;  129  
 938                    	;  130      crcIn ^= data;
 939                    	;  131      for (i = 0; i < 8; i++)
 940                    	;  132          {
 941                    	;  133          if (crcIn & 0x80) crcIn ^= g;
 942                    	;  134          crcIn <<= 1;
 943                    	;  135          }
 944                    	;  136  
 945                    	;  137      return crcIn;
 946                    	;  138      }
 947                    	;  139  
 948                    	;  140  /*
 949                    	;  141  // Calculate CRC16 CCITT
 950                    	;  142  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
 951                    	;  143  // input:
 952                    	;  144  //   crcIn - the CRC before (0 for rist step)
 953                    	;  145  //   data - byte for CRC calculation
 954                    	;  146  // return: the CRC16 value
 955                    	;  147  */
 956                    	;  148  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
 957                    	;  149      {
 958                    	;  150      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
 959                    	;  151      crcIn ^=  data;
 960                    	;  152      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
 961                    	;  153      crcIn ^= (crcIn << 8) << 4;
 962                    	;  154      crcIn ^= ((crcIn & 0xff) << 4) << 1;
 963                    	;  155  
 964                    	;  156      return crcIn;
 965                    	;  157      }
 966                    	;  158  
 967                    	;  159  /* Send command to SD card and recieve answer.
 968                    	;  160   * A command is 5 bytes long and is followed by
 969                    	;  161   * a CRC7 checksum byte.
 970                    	;  162   * Returns a pointer to the response
 971                    	;  163   * or 0 if no response start bit found.
 972                    	;  164   */
 973                    	;  165  unsigned char *sdcommand(unsigned char *sdcmdp,
 974                    	;  166                           unsigned char *recbuf, int recbytes)
 975                    	;  167      {
 976                    	;  168      int searchn;  /* byte counter to search for response */
 977                    	;  169      int sdcbytes; /* byte counter for bytes to send */
 978                    	;  170      unsigned char *retptr; /* pointer used to store response */
 979                    	;  171      unsigned char rbyte;   /* recieved byte */
 980                    	;  172      unsigned char crc = 0; /* calculated CRC7 */
 981                    	;  173  
 982                    	;  174      /* send 8*2 clockpules */
 983                    	;  175      spiio(0xff);
 984                    	;  176      spiio(0xff);
 985                    	;  177      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
 986                    	;  178          {
 987                    	;  179          crc = CRC7_one(crc, *sdcmdp);
 988                    	;  180          spiio(*sdcmdp++);
 989                    	;  181          }
 990                    	;  182      spiio(crc | 0x01);
 991                    	;  183      /* search for recieved byte with start bit
 992                    	;  184         for a maximum of 10 recieved bytes  */
 993                    	;  185      for (searchn = 10; 0 < searchn; searchn--)
 994                    	;  186          {
 995                    	;  187          rbyte = spiio(0xff);
 996                    	;  188          if ((rbyte & 0x80) == 0)
 997                    	;  189              break;
 998                    	;  190          }
 999                    	;  191      if (searchn == 0) /* no start bit found */
1000                    	;  192          return (NO);
1001                    	;  193      retptr = recbuf;
1002                    	;  194      *retptr++ = rbyte;
1003                    	;  195      for (; 1 < recbytes; recbytes--) /* recieve bytes */
1004                    	;  196          *retptr++ = spiio(0xff);
1005                    	;  197      return (recbuf);
1006                    	;  198      }
1007                    	;  199  
1008                    	;  200  /* Initialise SD card interface
1009                    	;  201   *
1010                    	;  202   * returns YES if ok and NO if not ok
1011                    	;  203   *
1012                    	;  204   * References:
1013                    	;  205   *   https://www.sdcard.org/downloads/pls/
1014                    	;  206   *      Physical Layer Simplified Specification version 8.0
1015                    	;  207   *
1016                    	;  208   * A nice flowchart how to initialize:
1017                    	;  209   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
1018                    	;  210   *
1019                    	;  211   */
1020                    	;  212  int sdinit()
1021                    	;  213      {
1022                    	;  214      int nbytes;  /* byte counter */
1023                    	;  215      int tries;   /* tries to get to active state or searching for data  */
1024                    	;  216      int wtloop;  /* timer loop when trying to enter active state */
1025                    	;  217      unsigned char cmdbuf[5];   /* buffer to build command in */
1026                    	;  218      unsigned char rstatbuf[5]; /* buffer to recieve status in */
1027                    	;  219      unsigned char *statptr;    /* pointer to returned status from SD command */
1028                    	;  220      unsigned char crc;         /* crc register for CID and CSD */
1029                    	;  221      unsigned char rbyte;       /* recieved byte */
1030                    	;  222      unsigned char *prtptr;     /* for debug printing */
1031                    	;  223  
1032                    	;  224      ledon();
1033                    	;  225      spideselect();
1034                    	;  226      sdinitok = NO;
1035                    	;  227  
1036                    	;  228      /* start to generate 9*8 clock pulses with not selected SD card */
1037                    	;  229      for (nbytes = 9; 0 < nbytes; nbytes--)
1038                    	;  230          spiio(0xff);
1039                    	;  231      if (sdtestflg)
1040                    	;  232          {
1041                    	;  233          printf("\nSent 8*8 (72) clock pulses, select not active\n");
1042                    	;  234          } /* sdtestflg */
1043                    	;  235      spiselect();
1044                    	;  236  
1045                    	;  237      /* CMD0: GO_IDLE_STATE */
1046                    	;  238      for (tries = 0; tries < 10; tries++)
1047                    	;  239          {
1048                    	;  240          memcpy(cmdbuf, cmd0, 5);
1049                    	;  241          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1050                    	;  242          if (sdtestflg)
1051                    	;  243              {
1052                    	;  244              if (!statptr)
1053                    	;  245                  printf("CMD0: no response\n");
1054                    	;  246              else
1055                    	;  247                  printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
1056                    	;  248              } /* sdtestflg */
1057                    	;  249          if (!statptr)
1058                    	;  250              {
1059                    	;  251              spideselect();
1060                    	;  252              ledoff();
1061                    	;  253              return (NO);
1062                    	;  254              }
1063                    	;  255          if (statptr[0] == 0x01)
1064                    	;  256              break;
1065                    	;  257          for (wtloop = 0; wtloop < tries * 10; wtloop++)
1066                    	;  258              {
1067                    	;  259              /* wait loop, time increasing for each try */
1068                    	;  260              spiio(0xff);
1069                    	;  261              }
1070                    	;  262          }
1071                    	;  263  
1072                    	;  264      /* CMD8: SEND_IF_COND */
1073                    	;  265      memcpy(cmdbuf, cmd8, 5);
1074                    	;  266      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
1075                    	;  267      if (sdtestflg)
1076                    	;  268          {
1077                    	;  269          if (!statptr)
1078                    	;  270              printf("CMD8: no response\n");
1079                    	;  271          else
1080                    	;  272              {
1081                    	;  273              printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
1082                    	;  274                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
1083                    	;  275              if (!(statptr[0] & 0xfe)) /* no error */
1084                    	;  276                  {
1085                    	;  277                  if (statptr[4] == 0xaa)
1086                    	;  278                      printf("echo back ok, ");
1087                    	;  279                  else
1088                    	;  280                      printf("invalid echo back\n");
1089                    	;  281                  }
1090                    	;  282              }
1091                    	;  283          } /* sdtestflg */
1092                    	;  284      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
1093                    	;  285          {
1094                    	;  286          sdver2 = NO;
1095                    	;  287          if (sdtestflg)
1096                    	;  288              {
1097                    	;  289              printf("probably SD ver. 1\n");
1098                    	;  290              } /* sdtestflg */
1099                    	;  291          }
1100                    	;  292      else
1101                    	;  293          {
1102                    	;  294          sdver2 = YES;
1103                    	;  295          if (statptr[4] != 0xaa) /* but invalid echo back */
1104                    	;  296              {
1105                    	;  297              spideselect();
1106                    	;  298              ledoff();
1107                    	;  299              return (NO);
1108                    	;  300              }
1109                    	;  301          if (sdtestflg)
1110                    	;  302              {
1111                    	;  303              printf("SD ver 2\n");
1112                    	;  304              } /* sdtestflg */
1113                    	;  305          }
1114                    	;  306  
1115                    	;  307      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
1116                    	;  308      for (tries = 0; tries < 20; tries++)
1117                    	;  309          {
1118                    	;  310          memcpy(cmdbuf, cmd55, 5);
1119                    	;  311          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1120                    	;  312          if (sdtestflg)
1121                    	;  313              {
1122                    	;  314              if (!statptr)
1123                    	;  315                  printf("CMD55: no response\n");
1124                    	;  316              else
1125                    	;  317                  printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
1126                    	;  318              } /* sdtestflg */
1127                    	;  319          if (!statptr)
1128                    	;  320              {
1129                    	;  321              spideselect();
1130                    	;  322              ledoff();
1131                    	;  323              return (NO);
1132                    	;  324              }
1133                    	;  325          memcpy(cmdbuf, acmd41, 5);
1134                    	;  326          if (sdver2)
1135                    	;  327              cmdbuf[1] = 0x40;
1136                    	;  328          else
1137                    	;  329              cmdbuf[1] = 0x00;
1138                    	;  330          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1139                    	;  331          if (sdtestflg)
1140                    	;  332              {
1141                    	;  333              if (!statptr)
1142                    	;  334                  printf("ACMD41: no response\n");
1143                    	;  335              else
1144                    	;  336                  printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
1145                    	;  337                         statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
1146                    	;  338              } /* sdtestflg */
1147                    	;  339          if (!statptr)
1148                    	;  340              {
1149                    	;  341              spideselect();
1150                    	;  342              ledoff();
1151                    	;  343              return (NO);
1152                    	;  344              }
1153                    	;  345          if (statptr[0] == 0x00) /* now the SD card is ready */
1154                    	;  346              {
1155                    	;  347              break;
1156                    	;  348              }
1157                    	;  349          for (wtloop = 0; wtloop < tries * 10; wtloop++)
1158                    	;  350              {
1159                    	;  351              /* wait loop, time increasing for each try */
1160                    	;  352              spiio(0xff);
1161                    	;  353              }
1162                    	;  354          }
1163                    	;  355  
1164                    	;  356      /* CMD58: READ_OCR */
1165                    	;  357      /* According to the flow chart this should not work
1166                    	;  358         for SD ver. 1 but the response is ok anyway
1167                    	;  359         all tested SD cards  */
1168                    	;  360      memcpy(cmdbuf, cmd58, 5);
1169                    	;  361      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
1170                    	;  362      if (sdtestflg)
1171                    	;  363          {
1172                    	;  364          if (!statptr)
1173                    	;  365              printf("CMD58: no response\n");
1174                    	;  366          else
1175                    	;  367              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
1176                    	;  368                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
1177                    	;  369          } /* sdtestflg */
1178                    	;  370      if (!statptr)
1179                    	;  371          {
1180                    	;  372          spideselect();
1181                    	;  373          ledoff();
1182                    	;  374          return (NO);
1183                    	;  375          }
1184                    	;  376      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
1185                    	;  377      blkmult = 1; /* assume block address */
1186                    	;  378      if (ocrreg[0] & 0x80)
1187                    	;  379          {
1188                    	;  380          /* SD Ver.2+ */
1189                    	;  381          if (!(ocrreg[0] & 0x40))
1190                    	;  382              {
1191                    	;  383              /* SD Ver.2+, Byte address */
1192                    	;  384              blkmult = 512;
1193                    	;  385              }
1194                    	;  386          }
1195                    	;  387  
1196                    	;  388      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
1197                    	;  389      if (blkmult == 512)
1198                    	;  390          {
1199                    	;  391          memcpy(cmdbuf, cmd16, 5);
1200                    	;  392          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1201                    	;  393          if (sdtestflg)
1202                    	;  394              {
1203                    	;  395              if (!statptr)
1204                    	;  396                  printf("CMD16: no response\n");
1205                    	;  397              else
1206                    	;  398                  printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
1207                    	;  399                         statptr[0]);
1208                    	;  400              } /* sdtestflg */
1209                    	;  401          if (!statptr)
1210                    	;  402              {
1211                    	;  403              spideselect();
1212                    	;  404              ledoff();
1213                    	;  405              return (NO);
1214                    	;  406              }
1215                    	;  407          }
1216                    	;  408      /* Register information:
1217                    	;  409       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
1218                    	;  410       */
1219                    	;  411  
1220                    	;  412      /* CMD10: SEND_CID */
1221                    	;  413      memcpy(cmdbuf, cmd10, 5);
1222                    	;  414      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1223                    	;  415      if (sdtestflg)
1224                    	;  416          {
1225                    	;  417          if (!statptr)
1226                    	;  418              printf("CMD10: no response\n");
1227                    	;  419          else
1228                    	;  420              printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
1229                    	;  421          } /* sdtestflg */
1230                    	;  422      if (!statptr)
1231                    	;  423          {
1232                    	;  424          spideselect();
1233                    	;  425          ledoff();
1234                    	;  426          return (NO);
1235                    	;  427          }
1236                    	;  428      /* looking for 0xfe that is the byte before data */
1237                    	;  429      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
1238                    	;  430          ;
1239                    	;  431      if (tries == 0) /* tried too many times */
1240                    	;  432          {
1241                    	;  433          if (sdtestflg)
1242                    	;  434              {
1243                    	;  435              printf("  No data found\n");
1244                    	;  436              } /* sdtestflg */
1245                    	;  437          spideselect();
1246                    	;  438          ledoff();
1247                    	;  439          return (NO);
1248                    	;  440          }
1249                    	;  441      else
1250                    	;  442          {
1251                    	;  443          crc = 0;
1252                    	;  444          for (nbytes = 0; nbytes < 15; nbytes++)
1253                    	;  445              {
1254                    	;  446              rbyte = spiio(0xff);
1255                    	;  447              cidreg[nbytes] = rbyte;
1256                    	;  448              crc = CRC7_one(crc, rbyte);
1257                    	;  449              }
1258                    	;  450          cidreg[15] = spiio(0xff);
1259                    	;  451          crc |= 0x01;
1260                    	;  452          /* some SD cards need additional clock pulses */
1261                    	;  453          for (nbytes = 9; 0 < nbytes; nbytes--)
1262                    	;  454              spiio(0xff);
1263                    	;  455          if (sdtestflg)
1264                    	;  456              {
1265                    	;  457              prtptr = &cidreg[0];
1266                    	;  458              printf("  CID: [");
1267                    	;  459              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1268                    	;  460                  printf("%02x ", *prtptr);
1269                    	;  461              prtptr = &cidreg[0];
1270                    	;  462              printf("\b] |");
1271                    	;  463              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1272                    	;  464                  {
1273                    	;  465                  if ((' ' <= *prtptr) && (*prtptr < 127))
1274                    	;  466                      putchar(*prtptr);
1275                    	;  467                  else
1276                    	;  468                      putchar('.');
1277                    	;  469                  }
1278                    	;  470              printf("|\n");
1279                    	;  471              if (crc == cidreg[15])
1280                    	;  472                  {
1281                    	;  473                  printf("CRC7 ok: [%02x]\n", crc);
1282                    	;  474                  }
1283                    	;  475              else
1284                    	;  476                  {
1285                    	;  477                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
1286                    	;  478                         crc, cidreg[15]);
1287                    	;  479                  /* could maybe return failure here */
1288                    	;  480                  }
1289                    	;  481              } /* sdtestflg */
1290                    	;  482          }
1291                    	;  483  
1292                    	;  484      /* CMD9: SEND_CSD */
1293                    	;  485      memcpy(cmdbuf, cmd9, 5);
1294                    	;  486      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1295                    	;  487      if (sdtestflg)
1296                    	;  488          {
1297                    	;  489          if (!statptr)
1298                    	;  490              printf("CMD9: no response\n");
1299                    	;  491          else
1300                    	;  492              printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
1301                    	;  493          } /* sdtestflg */
1302                    	;  494      if (!statptr)
1303                    	;  495          {
1304                    	;  496          spideselect();
1305                    	;  497          ledoff();
1306                    	;  498          return (NO);
1307                    	;  499          }
1308                    	;  500      /* looking for 0xfe that is the byte before data */
1309                    	;  501      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
1310                    	;  502          ;
1311                    	;  503      if (tries == 0) /* tried too many times */
1312                    	;  504          {
1313                    	;  505          if (sdtestflg)
1314                    	;  506              {
1315                    	;  507              printf("  No data found\n");
1316                    	;  508              } /* sdtestflg */
1317                    	;  509          return (NO);
1318                    	;  510          }
1319                    	;  511      else
1320                    	;  512          {
1321                    	;  513          crc = 0;
1322                    	;  514          for (nbytes = 0; nbytes < 15; nbytes++)
1323                    	;  515              {
1324                    	;  516              rbyte = spiio(0xff);
1325                    	;  517              csdreg[nbytes] = rbyte;
1326                    	;  518              crc = CRC7_one(crc, rbyte);
1327                    	;  519              }
1328                    	;  520          csdreg[15] = spiio(0xff);
1329                    	;  521          crc |= 0x01;
1330                    	;  522          /* some SD cards need additional clock pulses */
1331                    	;  523          for (nbytes = 9; 0 < nbytes; nbytes--)
1332                    	;  524              spiio(0xff);
1333                    	;  525          if (sdtestflg)
1334                    	;  526              {
1335                    	;  527              prtptr = &csdreg[0];
1336                    	;  528              printf("  CSD: [");
1337                    	;  529              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1338                    	;  530                  printf("%02x ", *prtptr);
1339                    	;  531              prtptr = &csdreg[0];
1340                    	;  532              printf("\b] |");
1341                    	;  533              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
1342                    	;  534                  {
1343                    	;  535                  if ((' ' <= *prtptr) && (*prtptr < 127))
1344                    	;  536                      putchar(*prtptr);
1345                    	;  537                  else
1346                    	;  538                      putchar('.');
1347                    	;  539                  }
1348                    	;  540              printf("|\n");
1349                    	;  541              if (crc == csdreg[15])
1350                    	;  542                  {
1351                    	;  543                  printf("CRC7 ok: [%02x]\n", crc);
1352                    	;  544                  }
1353                    	;  545              else
1354                    	;  546                  {
1355                    	;  547                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
1356                    	;  548                         crc, csdreg[15]);
1357                    	;  549                  /* could maybe return failure here */
1358                    	;  550                  }
1359                    	;  551              } /* sdtestflg */
1360                    	;  552          }
1361                    	;  553  
1362                    	;  554      for (nbytes = 9; 0 < nbytes; nbytes--)
1363                    	;  555          spiio(0xff);
1364                    	;  556      if (sdtestflg)
1365                    	;  557          {
1366                    	;  558          printf("Sent 9*8 (72) clock pulses, select active\n");
1367                    	;  559          } /* sdtestflg */
1368                    	;  560  
1369                    	;  561      sdinitok = YES;
1370                    	;  562  
1371                    	;  563      spideselect();
1372                    	;  564      ledoff();
1373                    	;  565  
1374                    	;  566      return (YES);
1375                    	;  567      }
1376                    	;  568  
1377                    	;  569  int sdprobe()
1378                    	;  570      {
1379                    	;  571      unsigned char cmdbuf[5];   /* buffer to build command in */
1380                    	;  572      unsigned char rstatbuf[5]; /* buffer to recieve status in */
1381                    	;  573      unsigned char *statptr;    /* pointer to returned status from SD command */
1382                    	;  574      int nbytes;  /* byte counter */
1383                    	;  575      int allzero = YES;
1384                    	;  576  
1385                    	;  577      ledon();
1386                    	;  578      spiselect();
1387                    	;  579  
1388                    	;  580      /* CMD58: READ_OCR */
1389                    	;  581      memcpy(cmdbuf, cmd58, 5);
1390                    	;  582      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
1391                    	;  583      for (nbytes = 0; nbytes < 5; nbytes++)
1392                    	;  584          {
1393                    	;  585          if (statptr[nbytes] != 0)
1394                    	;  586              allzero = NO;
1395                    	;  587          }
1396                    	;  588      if (sdtestflg)
1397                    	;  589          {
1398                    	;  590          if (!statptr)
1399                    	;  591              printf("CMD58: no response\n");
1400                    	;  592          else
1401                    	;  593              {
1402                    	;  594              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
1403                    	;  595                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
1404                    	;  596              if (allzero)
1405                    	;  597                  printf("SD card not inserted or not initialized\n");
1406                    	;  598              }
1407                    	;  599          } /* sdtestflg */
1408                    	;  600      if (!statptr || allzero)
1409                    	;  601          {
1410                    	;  602          sdinitok = NO;
1411                    	;  603          spideselect();
1412                    	;  604          ledoff();
1413                    	;  605          return (NO);
1414                    	;  606          }
1415                    	;  607  
1416                    	;  608      spideselect();
1417                    	;  609      ledoff();
1418                    	;  610  
1419                    	;  611      return (YES);
1420                    	;  612      }
1421                    	;  613  
1422                    	;  614  /* print OCR, CID and CSD registers*/
1423                    	;  615  void sdprtreg()
1424                    	;  616      {
1425                    	;  617      unsigned int n;
1426                    	;  618      unsigned int csize;
1427                    	;  619      unsigned long devsize;
1428                    	;  620      unsigned long capacity;
1429                    	;  621  
1430                    	;  622      if (!sdinitok)
1431                    	;  623          {
1432                    	;  624          printf("SD card not initialized\n");
1433                    	;  625          return;
1434                    	;  626          }
1435                    	;  627      printf("SD card information:");
1436                    	;  628      if (ocrreg[0] & 0x80)
1437                    	;  629          {
1438                    	;  630          if (ocrreg[0] & 0x40)
1439                    	;  631              printf("  SD card ver. 2+, Block address\n");
1440                    	;  632          else
1441                    	;  633              {
1442                    	;  634              if (sdver2)
1443                    	;  635                  printf("  SD card ver. 2+, Byte address\n");
1444                    	;  636              else
1445                    	;  637                  printf("  SD card ver. 1, Byte address\n");
1446                    	;  638              }
1447                    	;  639          }
1448                    	;  640      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
1449                    	;  641      printf("OEM ID: %.2s, ", &cidreg[1]);
1450                    	;  642      printf("Product name: %.5s\n", &cidreg[3]);
1451                    	;  643      printf("  Product revision: %d.%d, ",
1452                    	;  644             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
1453                    	;  645      printf("Serial number: %lu\n",
1454                    	;  646             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
1455                    	;  647      printf("  Manufacturing date: %d-%d, ",
1456                    	;  648             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
1457                    	;  649      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
1458                    	;  650          {
1459                    	;  651          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
1460                    	;  652          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
1461                    	;  653                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
1462                    	;  654          capacity = (unsigned long) csize << (n-10);
1463                    	;  655          printf("Device capacity: %lu MByte\n", capacity >> 10);
1464                    	;  656          }
1465                    	;  657      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
1466                    	;  658          {
1467                    	;  659          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
1468                    	;  660                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1469                    	;  661          capacity = devsize << 9;
1470                    	;  662          printf("Device capacity: %lu MByte\n", capacity >> 10);
1471                    	;  663          }
1472                    	;  664      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
1473                    	;  665          {
1474                    	;  666          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
1475                    	;  667                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1476                    	;  668          capacity = devsize << 9;
1477                    	;  669          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
1478                    	;  670          }
1479                    	;  671  
1480                    	;  672      if (sdtestflg)
1481                    	;  673          {
1482                    	;  674  
1483                    	;  675          printf("--------------------------------------\n");
1484                    	;  676          printf("OCR register:\n");
1485                    	;  677          if (ocrreg[2] & 0x80)
1486                    	;  678              printf("2.7-2.8V (bit 15) ");
1487                    	;  679          if (ocrreg[1] & 0x01)
1488                    	;  680              printf("2.8-2.9V (bit 16) ");
1489                    	;  681          if (ocrreg[1] & 0x02)
1490                    	;  682              printf("2.9-3.0V (bit 17) ");
1491                    	;  683          if (ocrreg[1] & 0x04)
1492                    	;  684              printf("3.0-3.1V (bit 18) \n");
1493                    	;  685          if (ocrreg[1] & 0x08)
1494                    	;  686              printf("3.1-3.2V (bit 19) ");
1495                    	;  687          if (ocrreg[1] & 0x10)
1496                    	;  688              printf("3.2-3.3V (bit 20) ");
1497                    	;  689          if (ocrreg[1] & 0x20)
1498                    	;  690              printf("3.3-3.4V (bit 21) ");
1499                    	;  691          if (ocrreg[1] & 0x40)
1500                    	;  692              printf("3.4-3.5V (bit 22) \n");
1501                    	;  693          if (ocrreg[1] & 0x80)
1502                    	;  694              printf("3.5-3.6V (bit 23) \n");
1503                    	;  695          if (ocrreg[0] & 0x01)
1504                    	;  696              printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
1505                    	;  697          if (ocrreg[0] & 0x08)
1506                    	;  698              printf("Over 2TB support Status (CO2T) (bit 27) set\n");
1507                    	;  699          if (ocrreg[0] & 0x20)
1508                    	;  700              printf("UHS-II Card Status (bit 29) set ");
1509                    	;  701          if (ocrreg[0] & 0x80)
1510                    	;  702              {
1511                    	;  703              if (ocrreg[0] & 0x40)
1512                    	;  704                  {
1513                    	;  705                  printf("Card Capacity Status (CCS) (bit 30) set\n");
1514                    	;  706                  printf("  SD Ver.2+, Block address");
1515                    	;  707                  }
1516                    	;  708              else
1517                    	;  709                  {
1518                    	;  710                  printf("Card Capacity Status (CCS) (bit 30) not set\n");
1519                    	;  711                  if (sdver2)
1520                    	;  712                      printf("  SD Ver.2+, Byte address");
1521                    	;  713                  else
1522                    	;  714                      printf("  SD Ver.1, Byte address");
1523                    	;  715                  }
1524                    	;  716              printf("\nCard power up status bit (busy) (bit 31) set\n");
1525                    	;  717              }
1526                    	;  718          else
1527                    	;  719              {
1528                    	;  720              printf("\nCard power up status bit (busy) (bit 31) not set.\n");
1529                    	;  721              printf("  This bit is not set if the card has not finished the power up routine.\n");
1530                    	;  722              }
1531                    	;  723          printf("--------------------------------------\n");
1532                    	;  724          printf("CID register:\n");
1533                    	;  725          printf("MID: 0x%02x, ", cidreg[0]);
1534                    	;  726          printf("OID: %.2s, ", &cidreg[1]);
1535                    	;  727          printf("PNM: %.5s, ", &cidreg[3]);
1536                    	;  728          printf("PRV: %d.%d, ",
1537                    	;  729                 (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
1538                    	;  730          printf("PSN: %lu, ",
1539                    	;  731                 (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
1540                    	;  732          printf("MDT: %d-%d\n",
1541                    	;  733                 2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
1542                    	;  734          printf("--------------------------------------\n");
1543                    	;  735          printf("CSD register:\n");
1544                    	;  736          if ((csdreg[0] & 0xc0) == 0x00)
1545                    	;  737              {
1546                    	;  738              printf("CSD Version 1.0, Standard Capacity\n");
1547                    	;  739              n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
1548                    	;  740              csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
1549                    	;  741                      ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
1550                    	;  742              capacity = (unsigned long) csize << (n-10);
1551                    	;  743              printf(" Device capacity: %lu KByte, %lu MByte\n",
1552                    	;  744                     capacity, capacity >> 10);
1553                    	;  745              }
1554                    	;  746          if ((csdreg[0] & 0xc0) == 0x40)
1555                    	;  747              {
1556                    	;  748              printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
1557                    	;  749              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
1558                    	;  750                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1559                    	;  751              capacity = devsize << 9;
1560                    	;  752              printf(" Device capacity: %lu KByte, %lu MByte\n",
1561                    	;  753                     capacity, capacity >> 10);
1562                    	;  754              }
1563                    	;  755          if ((csdreg[0] & 0xc0) == 0x80)
1564                    	;  756              {
1565                    	;  757              printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
1566                    	;  758              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
1567                    	;  759                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
1568                    	;  760              capacity = devsize << 9;
1569                    	;  761              printf(" Device capacity: %lu KByte, %lu MByte\n",
1570                    	;  762                     capacity, capacity >> 10);
1571                    	;  763              }
1572                    	;  764          printf("--------------------------------------\n");
1573                    	;  765  
1574                    	;  766          } /* sdtestflg */ /* SDTEST */
1575                    	;  767  
1576                    	;  768      }
1577                    	;  769  
1578                    	;  770  /* Read data block of 512 bytes to buffer
1579                    	;  771   * Returns YES if ok or NO if error
1580                    	;  772   */
1581                    	;  773  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
1582                    	;  774      {
1583                    	;  775      unsigned char *statptr;
1584                    	;  776      unsigned char rbyte;
1585                    	;  777      unsigned char cmdbuf[5];   /* buffer to build command in */
1586                    	;  778      unsigned char rstatbuf[5]; /* buffer to recieve status in */
1587                    	;  779      int nbytes;
1588                    	;  780      int tries;
1589                    	;  781      unsigned long blktoread;
1590                    	;  782      unsigned int rxcrc16;
1591                    	;  783      unsigned int calcrc16;
1592                    	;  784  
1593                    	;  785      ledon();
1594                    	;  786      spiselect();
1595                    	;  787  
1596                    	;  788      if (!sdinitok)
1597                    	;  789          {
1598                    	;  790          if (sdtestflg)
1599                    	;  791              {
1600                    	;  792              printf("SD card not initialized\n");
1601                    	;  793              } /* sdtestflg */
1602                    	;  794          spideselect();
1603                    	;  795          ledoff();
1604                    	;  796          return (NO);
1605                    	;  797          }
1606                    	;  798  
1607                    	;  799      /* CMD17: READ_SINGLE_BLOCK */
1608                    	;  800      /* Insert block # into command */
1609                    	;  801      memcpy(cmdbuf, cmd17, 5);
1610                    	;  802      blktoread = blkmult * rdblkno;
1611                    	;  803      cmdbuf[4] = blktoread & 0xff;
1612                    	;  804      blktoread = blktoread >> 8;
1613                    	;  805      cmdbuf[3] = blktoread & 0xff;
1614                    	;  806      blktoread = blktoread >> 8;
1615                    	;  807      cmdbuf[2] = blktoread & 0xff;
1616                    	;  808      blktoread = blktoread >> 8;
1617                    	;  809      cmdbuf[1] = blktoread & 0xff;
1618                    	;  810  
1619                    	;  811      if (sdtestflg)
1620                    	;  812          {
1621                    	;  813          printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
1622                    	;  814                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
1623                    	;  815          } /* sdtestflg */
1624                    	;  816      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1625                    	;  817      if (sdtestflg)
1626                    	;  818          {
1627                    	;  819          printf("CMD17 R1 response [%02x]\n", statptr[0]);
1628                    	;  820          } /* sdtestflg */
1629                    	;  821      if (statptr[0])
1630                    	;  822          {
1631                    	;  823          if (sdtestflg)
1632                    	;  824              {
1633                    	;  825              printf("  could not read block\n");
1634                    	;  826              } /* sdtestflg */
1635                    	;  827          spideselect();
1636                    	;  828          ledoff();
1637                    	;  829          return (NO);
1638                    	;  830          }
1639                    	;  831      /* looking for 0xfe that is the byte before data */
1640                    	;  832      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
1641                    	;  833          {
1642                    	;  834          if ((rbyte & 0xe0) == 0x00)
1643                    	;  835              {
1644                    	;  836              /* If a read operation fails and the card cannot provide
1645                    	;  837                 the required data, it will send a data error token instead
1646                    	;  838               */
1647                    	;  839              if (sdtestflg)
1648                    	;  840                  {
1649                    	;  841                  printf("  read error: [%02x]\n", rbyte);
1650                    	;  842                  } /* sdtestflg */
1651                    	;  843              spideselect();
1652                    	;  844              ledoff();
1653                    	;  845              return (NO);
1654                    	;  846              }
1655                    	;  847          }
1656                    	;  848      if (tries == 0) /* tried too many times */
1657                    	;  849          {
1658                    	;  850          if (sdtestflg)
1659                    	;  851              {
1660                    	;  852              printf("  no data found\n");
1661                    	;  853              } /* sdtestflg */
1662                    	;  854          spideselect();
1663                    	;  855          ledoff();
1664                    	;  856          return (NO);
1665                    	;  857          }
1666                    	;  858      else
1667                    	;  859          {
1668                    	;  860          calcrc16 = 0;
1669                    	;  861          for (nbytes = 0; nbytes < 512; nbytes++)
1670                    	;  862              {
1671                    	;  863              rbyte = spiio(0xff);
1672                    	;  864              calcrc16 = CRC16_one(calcrc16, rbyte);
1673                    	;  865              rdbuf[nbytes] = rbyte;
1674                    	;  866              }
1675                    	;  867          rxcrc16 = spiio(0xff) << 8;
1676                    	;  868          rxcrc16 += spiio(0xff);
1677                    	;  869  
1678                    	;  870          if (sdtestflg)
1679                    	;  871              {
1680                    	;  872              printf("  read data block %ld:\n", rdblkno);
1681                    	;  873              } /* sdtestflg */
1682                    	;  874          if (rxcrc16 != calcrc16)
1683                    	;  875              {
1684                    	;  876              if (sdtestflg)
1685                    	;  877                  {
1686                    	;  878                  printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
1687                    	;  879                         rxcrc16, calcrc16);
1688                    	;  880                  } /* sdtestflg */
1689                    	;  881              spideselect();
1690                    	;  882              ledoff();
1691                    	;  883              return (NO);
1692                    	;  884              }
1693                    	;  885          }
1694                    	;  886      spideselect();
1695                    	;  887      ledoff();
1696                    	;  888      return (YES);
1697                    	;  889      }
1698                    	;  890  
1699                    	;  891  /* Write data block of 512 bytes from buffer
1700                    	;  892   * Returns YES if ok or NO if error
1701                    	;  893   */
1702                    	;  894  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
1703                    	;  895      {
1704                    	;  896      unsigned char *statptr;
1705                    	;  897      unsigned char rbyte;
1706                    	;  898      unsigned char tbyte;
1707                    	;  899      unsigned char cmdbuf[5];   /* buffer to build command in */
1708                    	;  900      unsigned char rstatbuf[5]; /* buffer to recieve status in */
1709                    	;  901      int nbytes;
1710                    	;  902      int tries;
1711                    	;  903      unsigned long blktowrite;
1712                    	;  904      unsigned int calcrc16;
1713                    	;  905  
1714                    	;  906      ledon();
1715                    	;  907      spiselect();
1716                    	;  908  
1717                    	;  909      if (!sdinitok)
1718                    	;  910          {
1719                    	;  911          if (sdtestflg)
1720                    	;  912              {
1721                    	;  913              printf("SD card not initialized\n");
1722                    	;  914              } /* sdtestflg */
1723                    	;  915          spideselect();
1724                    	;  916          ledoff();
1725                    	;  917          return (NO);
1726                    	;  918          }
1727                    	;  919  
1728                    	;  920      if (sdtestflg)
1729                    	;  921          {
1730                    	;  922          printf("  write data block %ld:\n", wrblkno);
1731                    	;  923          } /* sdtestflg */
1732                    	;  924      /* CMD24: WRITE_SINGLE_BLOCK */
1733                    	;  925      /* Insert block # into command */
1734                    	;  926      memcpy(cmdbuf, cmd24, 5);
1735                    	;  927      blktowrite = blkmult * wrblkno;
1736                    	;  928      cmdbuf[4] = blktowrite & 0xff;
1737                    	;  929      blktowrite = blktowrite >> 8;
1738                    	;  930      cmdbuf[3] = blktowrite & 0xff;
1739                    	;  931      blktowrite = blktowrite >> 8;
1740                    	;  932      cmdbuf[2] = blktowrite & 0xff;
1741                    	;  933      blktowrite = blktowrite >> 8;
1742                    	;  934      cmdbuf[1] = blktowrite & 0xff;
1743                    	;  935  
1744                    	;  936      if (sdtestflg)
1745                    	;  937          {
1746                    	;  938          printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
1747                    	;  939                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
1748                    	;  940          } /* sdtestflg */
1749                    	;  941      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
1750                    	;  942      if (sdtestflg)
1751                    	;  943          {
1752                    	;  944          printf("CMD24 R1 response [%02x]\n", statptr[0]);
1753                    	;  945          } /* sdtestflg */
1754                    	;  946      if (statptr[0])
1755                    	;  947          {
1756                    	;  948          if (sdtestflg)
1757                    	;  949              {
1758                    	;  950              printf("  could not write block\n");
1759                    	;  951              } /* sdtestflg */
1760                    	;  952          spideselect();
1761                    	;  953          ledoff();
1762                    	;  954          return (NO);
1763                    	;  955          }
1764                    	;  956      /* send 0xfe, the byte before data */
1765                    	;  957      spiio(0xfe);
1766                    	;  958      /* initialize crc and send block */
1767                    	;  959      calcrc16 = 0;
1768                    	;  960      for (nbytes = 0; nbytes < 512; nbytes++)
1769                    	;  961          {
1770                    	;  962          tbyte = wrbuf[nbytes];
1771                    	;  963          spiio(tbyte);
1772                    	;  964          calcrc16 = CRC16_one(calcrc16, tbyte);
1773                    	;  965          }
1774                    	;  966      spiio((calcrc16 >> 8) & 0xff);
1775                    	;  967      spiio(calcrc16 & 0xff);
1776                    	;  968  
1777                    	;  969      /* check data resposnse */
1778                    	;  970      for (tries = 20;
1779                    	;  971              0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
1780                    	;  972              tries--)
1781                    	;  973          ;
1782                    	;  974      if (tries == 0)
1783                    	;  975          {
1784                    	;  976          if (sdtestflg)
1785                    	;  977              {
1786                    	;  978              printf("No data response\n");
1787                    	;  979              } /* sdtestflg */
1788                    	;  980          spideselect();
1789                    	;  981          ledoff();
1790                    	;  982          return (NO);
1791                    	;  983          }
1792                    	;  984      else
1793                    	;  985          {
1794                    	;  986          if (sdtestflg)
1795                    	;  987              {
1796                    	;  988              printf("Data response [%02x]", 0x1f & rbyte);
1797                    	;  989              } /* sdtestflg */
1798                    	;  990          if ((0x1f & rbyte) == 0x05)
1799                    	;  991              {
1800                    	;  992              if (sdtestflg)
1801                    	;  993                  {
1802                    	;  994                  printf(", data accepted\n");
1803                    	;  995                  } /* sdtestflg */
1804                    	;  996              for (nbytes = 9; 0 < nbytes; nbytes--)
1805                    	;  997                  spiio(0xff);
1806                    	;  998              if (sdtestflg)
1807                    	;  999                  {
1808                    	; 1000                  printf("Sent 9*8 (72) clock pulses, select active\n");
1809                    	; 1001                  } /* sdtestflg */
1810                    	; 1002              spideselect();
1811                    	; 1003              ledoff();
1812                    	; 1004              return (YES);
1813                    	; 1005              }
1814                    	; 1006          else
1815                    	; 1007              {
1816                    	; 1008              if (sdtestflg)
1817                    	; 1009                  {
1818                    	; 1010                  printf(", data not accepted\n");
1819                    	; 1011                  } /* sdtestflg */
1820                    	; 1012              spideselect();
1821                    	; 1013              ledoff();
1822                    	; 1014              return (NO);
1823                    	; 1015              }
1824                    	; 1016          }
1825                    	; 1017      }
1826                    	; 1018  
1827                    	; 1019  /* Print data in 512 byte buffer */
1828                    	; 1020  void sddatprt(unsigned char *prtbuf)
1829                    	; 1021      {
1830                    	; 1022      /* Variables used for "pretty-print" */
1831                    	; 1023      int allzero, dmpline, dotprted, lastallz, nbytes;
1832                    	; 1024      unsigned char *prtptr;
1833                    	; 1025  
1834                    	; 1026      prtptr = prtbuf;
1835                    	; 1027      dotprted = NO;
1836                    	; 1028      lastallz = NO;
1837                    	; 1029      for (dmpline = 0; dmpline < 32; dmpline++)
1838                    	; 1030          {
1839                    	; 1031          /* test if all 16 bytes are 0x00 */
1840                    	; 1032          allzero = YES;
1841                    	; 1033          for (nbytes = 0; nbytes < 16; nbytes++)
1842                    	; 1034              {
1843                    	; 1035              if (prtptr[nbytes] != 0)
1844                    	; 1036                  allzero = NO;
1845                    	; 1037              }
1846                    	; 1038          if (lastallz && allzero)
1847                    	; 1039              {
1848                    	; 1040              if (!dotprted)
1849                    	; 1041                  {
1850                    	; 1042                  printf("*\n");
1851                    	; 1043                  dotprted = YES;
1852                    	; 1044                  }
1853                    	; 1045              }
1854                    	; 1046          else
1855                    	; 1047              {
1856                    	; 1048              dotprted = NO;
1857                    	; 1049              /* print offset */
1858                    	; 1050              printf("%04x ", dmpline * 16);
1859                    	; 1051              /* print 16 bytes in hex */
1860                    	; 1052              for (nbytes = 0; nbytes < 16; nbytes++)
1861                    	; 1053                  printf("%02x ", prtptr[nbytes]);
1862                    	; 1054              /* print these bytes in ASCII if printable */
1863                    	; 1055              printf(" |");
1864                    	; 1056              for (nbytes = 0; nbytes < 16; nbytes++)
1865                    	; 1057                  {
1866                    	; 1058                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
1867                    	; 1059                      putchar(prtptr[nbytes]);
1868                    	; 1060                  else
1869                    	; 1061                      putchar('.');
1870                    	; 1062                  }
1871                    	; 1063              printf("|\n");
1872                    	; 1064              }
1873                    	; 1065          prtptr += 16;
1874                    	; 1066          lastallz = allzero;
1875                    	; 1067          }
1876                    	; 1068      }
1877                    	; 1069  
1878                    	; 1070  /* Print GUID (mixed endian format)
1879                    	; 1071   */
1880                    	; 1072  void prtguid(unsigned char *guidptr)
1881                    	; 1073      {
1882                    	; 1074      int index;
1883                    	; 1075  
1884                    	; 1076      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
1885                    	; 1077      printf("%02x%02x-", guidptr[5], guidptr[4]);
1886                    	; 1078      printf("%02x%02x-", guidptr[7], guidptr[6]);
1887                    	; 1079      printf("%02x%02x-", guidptr[8], guidptr[9]);
1888                    	; 1080      printf("%02x%02x%02x%02x%02x%02x",
1889                    	; 1081             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
1890                    	; 1082      }
1891                    	; 1083  
1892                    	; 1084  /* Analyze and print GPT entry
1893                    	; 1085   */
1894                    	; 1086  int prtgptent(unsigned int entryno)
1895                    	; 1087      {
1896                    	; 1088      int index;
1897                    	; 1089      int entryidx;
1898                    	; 1090      int hasname;
1899                    	; 1091      unsigned int block;
1900                    	; 1092      unsigned char *rxdata;
1901                    	; 1093      unsigned char *entryptr;
1902                    	; 1094      unsigned char tstzero = 0;
1903                    	; 1095      unsigned long flba;
1904                    	; 1096      unsigned long llba;
1905                    	; 1097  
1906                    	; 1098      block = 2 + (entryno / 4);
1907                    	; 1099      if ((curblkno != block) || !curblkok)
1908                    	; 1100          {
1909                    	; 1101          if (!sdread(sdrdbuf, block))
1910                    	; 1102              {
1911                    	; 1103              if (sdtestflg)
1912                    	; 1104                  {
1913                    	; 1105                  printf("Can't read GPT entry block\n");
1914                    	; 1106                  return (NO);
1915                    	; 1107                  } /* sdtestflg */
1916                    	; 1108              }
1917                    	; 1109          curblkno = block;
1918                    	; 1110          curblkok = YES;
1919                    	; 1111          }
1920                    	; 1112      rxdata = sdrdbuf;
1921                    	; 1113      entryptr = rxdata + (128 * (entryno % 4));
1922                    	; 1114      for (index = 0; index < 16; index++)
1923                    	; 1115          tstzero |= entryptr[index];
1924                    	; 1116      if (sdtestflg)
1925                    	; 1117          {
1926                    	; 1118          printf("GPT partition entry %d:", entryno + 1);
1927                    	; 1119          } /* sdtestflg */
1928                    	; 1120      if (!tstzero)
1929                    	; 1121          {
1930                    	; 1122          if (sdtestflg)
1931                    	; 1123              {
1932                    	; 1124              printf(" Not used entry\n");
1933                    	; 1125              } /* sdtestflg */
1934                    	; 1126          return (NO);
1935                    	; 1127          }
1936                    	; 1128      if (sdtestflg)
1937                    	; 1129          {
1938                    	; 1130          printf("\n  Partition type GUID: ");
1939                    	; 1131          prtguid(entryptr);
1940                    	; 1132          printf("\n  [");
1941                    	; 1133          for (index = 0; index < 16; index++)
1942                    	; 1134              printf("%02x ", entryptr[index]);
1943                    	; 1135          printf("\b]");
1944                    	; 1136          printf("\n  Unique partition GUID: ");
1945                    	; 1137          prtguid(entryptr + 16);
1946                    	; 1138          printf("\n  [");
1947                    	; 1139          for (index = 0; index < 16; index++)
1948                    	; 1140              printf("%02x ", (entryptr + 16)[index]);
1949                    	; 1141          printf("\b]");
1950                    	; 1142          printf("\n  First LBA: ");
1951                    	; 1143          /* lower 32 bits of LBA should be sufficient (I hope) */
1952                    	; 1144          } /* sdtestflg */
1953                    	; 1145      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
1954                    	; 1146             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
1955                    	; 1147      if (sdtestflg)
1956                    	; 1148          {
1957                    	; 1149          printf("%lu", flba);
1958                    	; 1150          printf(" [");
1959                    	; 1151          for (index = 32; index < (32 + 8); index++)
1960                    	; 1152              printf("%02x ", entryptr[index]);
1961                    	; 1153          printf("\b]");
1962                    	; 1154          printf("\n  Last LBA: ");
1963                    	; 1155          } /* sdtestflg */
1964                    	; 1156      /* lower 32 bits of LBA should be sufficient (I hope) */
1965                    	; 1157      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
1966                    	; 1158             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
1967                    	; 1159  
1968                    	; 1160      if (entryptr[48] & 0x04)
1969                    	; 1161          dskmap[partdsk].bootable = YES;
1970                    	; 1162      dskmap[partdsk].partype = PARTGPT;
1971                    	; 1163      dskmap[partdsk].dskletter = 'A' + partdsk;
1972                    	; 1164      dskmap[partdsk].dskstart = flba;
1973                    	; 1165      dskmap[partdsk].dskend = llba;
1974                    	; 1166      dskmap[partdsk].dsksize = llba - flba + 1;
1975                    	; 1167      memcpy(dskmap[partdsk].dsktype, entryptr, 16);
1976                    	; 1168      partdsk++;
1977                    	; 1169  
1978                    	; 1170      if (sdtestflg)
1979                    	; 1171          {
1980                    	; 1172          printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
1981                    	; 1173          printf(" [");
1982                    	; 1174          for (index = 40; index < (40 + 8); index++)
1983                    	; 1175              printf("%02x ", entryptr[index]);
1984                    	; 1176          printf("\b]");
1985                    	; 1177          printf("\n  Attribute flags: [");
1986                    	; 1178          /* bits 0 - 2 and 60 - 63 should be decoded */
1987                    	; 1179          for (index = 0; index < 8; index++)
1988                    	; 1180              {
1989                    	; 1181              entryidx = index + 48;
1990                    	; 1182              printf("%02x ", entryptr[entryidx]);
1991                    	; 1183              }
1992                    	; 1184          printf("\b]\n  Partition name:  ");
1993                    	; 1185          } /* sdtestflg */
1994                    	; 1186      /* partition name is in UTF-16LE code units */
1995                    	; 1187      hasname = NO;
1996                    	; 1188      for (index = 0; index < 72; index += 2)
1997                    	; 1189          {
1998                    	; 1190          entryidx = index + 56;
1999                    	; 1191          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
2000                    	; 1192              break;
2001                    	; 1193          if (sdtestflg)
2002                    	; 1194              {
2003                    	; 1195              if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
2004                    	; 1196                  putchar(entryptr[entryidx]);
2005                    	; 1197              else
2006                    	; 1198                  putchar('.');
2007                    	; 1199              } /* sdtestflg */
2008                    	; 1200          hasname = YES;
2009                    	; 1201          }
2010                    	; 1202      if (sdtestflg)
2011                    	; 1203          {
2012                    	; 1204          if (!hasname)
2013                    	; 1205              printf("name field empty");
2014                    	; 1206          printf("\n");
2015                    	; 1207          printf("   [");
2016                    	; 1208          for (index = 0; index < 72; index++)
2017                    	; 1209              {
2018                    	; 1210              if (((index & 0xf) == 0) && (index != 0))
2019                    	; 1211                  printf("\n    ");
2020                    	; 1212              entryidx = index + 56;
2021                    	; 1213              printf("%02x ", entryptr[entryidx]);
2022                    	; 1214              }
2023                    	; 1215          printf("\b]\n");
2024                    	; 1216          } /* sdtestflg */
2025                    	; 1217      return (YES);
2026                    	; 1218      }
2027                    	; 1219  
2028                    	; 1220  /* Analyze and print GPT header
2029                    	; 1221   */
2030                    	; 1222  void sdgpthdr(unsigned long block)
2031                    	; 1223      {
2032                    	; 1224      int index;
2033                    	; 1225      unsigned int partno;
2034                    	; 1226      unsigned char *rxdata;
2035                    	; 1227      unsigned long entries;
2036                    	; 1228  
2037                    	; 1229      if (sdtestflg)
2038                    	; 1230          {
2039                    	; 1231          printf("GPT header\n");
2040                    	; 1232          } /* sdtestflg */
2041                    	; 1233      if (!sdread(sdrdbuf, block))
2042                    	; 1234          {
2043                    	; 1235          if (sdtestflg)
2044                    	; 1236              {
2045                    	; 1237              printf("Can't read GPT partition table header\n");
2046                    	; 1238              } /* sdtestflg */
2047                    	; 1239          return;
2048                    	; 1240          }
2049                    	; 1241      curblkno = block;
2050                    	; 1242      curblkok = YES;
2051                    	; 1243  
2052                    	; 1244      rxdata = sdrdbuf;
2053                    	; 1245      if (sdtestflg)
2054                    	; 1246          {
2055                    	; 1247          printf("  Signature: %.8s\n", &rxdata[0]);
2056                    	; 1248          printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
2057                    	; 1249                 (int)rxdata[8] * ((int)rxdata[9] << 8),
2058                    	; 1250                 (int)rxdata[10] + ((int)rxdata[11] << 8),
2059                    	; 1251                 rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
2060                    	; 1252          entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
2061                    	; 1253                    ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
2062                    	; 1254          printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
2063                    	; 1255          } /* sdtestflg */
2064                    	; 1256      for (partno = 0; (partno < 16) && (partdsk < 16); partno++)
2065                    	; 1257          {
2066                    	; 1258          if (!prtgptent(partno))
2067                    	; 1259              {
2068                    	; 1260              if (!sdtestflg)
2069                    	; 1261                  {
2070                    	; 1262                  /* go through all entries if compiled as test program */
2071                    	; 1263                  return;
2072                    	; 1264                  } /* sdtestflg */
2073                    	; 1265              }
2074                    	; 1266          }
2075                    	; 1267      if (sdtestflg)
2076                    	; 1268          {
2077                    	; 1269          printf("First 16 GPT entries scanned\n");
2078                    	; 1270          } /* sdtestflg */
2079                    	; 1271      }
2080                    	; 1272  
2081                    	; 1273  /* Analyze and print MBR partition entry
2082                    	; 1274   * Returns:
2083                    	; 1275   *    -1 if errror - should not happen
2084                    	; 1276   *     0 if not used entry
2085                    	; 1277   *     1 if MBR entry
2086                    	; 1278   *     2 if EBR entry
2087                    	; 1279   *     3 if GTP entry
2088                    	; 1280   */
2089                    	; 1281  int sdmbrentry(unsigned char *partptr)
2090                    	; 1282      {
2091                    	; 1283      int index;
2092                    	; 1284      int parttype;
2093                    	; 1285      unsigned long lbastart;
2094                    	; 1286      unsigned long lbasize;
2095                    	; 1287  
2096                    	; 1288      parttype = PARTMBR;
2097                    	; 1289      if (!partptr[4])
2098                    	; 1290          {
2099                    	; 1291          if (sdtestflg)
2100                    	; 1292              {
2101                    	; 1293              printf("Not used entry\n");
2102                    	; 1294              } /* sdtestflg */
2103                    	; 1295          return (PARTZRO);
2104                    	; 1296          }
2105                    	; 1297      if (sdtestflg)
2106                    	; 1298          {
2107                    	; 1299          printf("Boot indicator: 0x%02x, System ID: 0x%02x\n",
2108                    	; 1300                 partptr[0], partptr[4]);
2109                    	; 1301  
2110                    	; 1302          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
2111                    	; 1303              {
2112                    	; 1304              printf("  Extended partition entry\n");
2113                    	; 1305              }
2114                    	; 1306          if (partptr[0] & 0x01)
2115                    	; 1307              {
2116                    	; 1308              printf("  Unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
2117                    	; 1309              /* this is however discussed
2118                    	; 1310                 https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
2119                    	; 1311              */
2120                    	; 1312              }
2121                    	; 1313          else
2122                    	; 1314              {
2123                    	; 1315              printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
2124                    	; 1316                     partptr[1], partptr[2], partptr[3],
2125                    	; 1317                     ((partptr[2] & 0xc0) >> 2) + partptr[3],
2126                    	; 1318                     partptr[1],
2127                    	; 1319                     partptr[2] & 0x3f);
2128                    	; 1320              printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
2129                    	; 1321                     partptr[5], partptr[6], partptr[7],
2130                    	; 1322                     ((partptr[6] & 0xc0) >> 2) + partptr[7],
2131                    	; 1323                     partptr[5],
2132                    	; 1324                     partptr[6] & 0x3f);
2133                    	; 1325              }
2134                    	; 1326          } /* sdtestflg */
2135                    	; 1327      /* not showing high 16 bits if 48 bit LBA */
2136                    	; 1328      lbastart = (unsigned long)partptr[8] +
2137                    	; 1329                 ((unsigned long)partptr[9] << 8) +
2138                    	; 1330                 ((unsigned long)partptr[10] << 16) +
2139                    	; 1331                 ((unsigned long)partptr[11] << 24);
2140                    	; 1332      lbasize = (unsigned long)partptr[12] +
2141                    	; 1333                ((unsigned long)partptr[13] << 8) +
2142                    	; 1334                ((unsigned long)partptr[14] << 16) +
2143                    	; 1335                ((unsigned long)partptr[15] << 24);
2144                    	; 1336  
2145                    	; 1337      if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
2146                    	; 1338          {
2147                    	; 1339          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
2148                    	; 1340              {
2149                    	; 1341              parttype = PARTEBR;
2150                    	; 1342              if (curblkno == 0) /* points to EBR in the MBR */
2151                    	; 1343                  {
2152                    	; 1344                  ebrnext = 0;
2153                    	; 1345                  dskmap[partdsk].partype = EBRCONT;
2154                    	; 1346                  dskmap[partdsk].dskletter = 'A' + partdsk;
2155                    	; 1347                  dskmap[partdsk].dskstart = lbastart;
2156                    	; 1348                  dskmap[partdsk].dskend = lbastart + lbasize - 1;
2157                    	; 1349                  dskmap[partdsk].dsksize = lbasize;
2158                    	; 1350                  dskmap[partdsk].dsktype[0] = partptr[4];
2159                    	; 1351                  partdsk++;
2160                    	; 1352                  ebrrecs[ebrrecidx++] = lbastart; /* save to handle later */
2161                    	; 1353                  }
2162                    	; 1354              else
2163                    	; 1355                  {
2164                    	; 1356                  ebrnext = curblkno + lbastart;
2165                    	; 1357                  }
2166                    	; 1358              }
2167                    	; 1359          else
2168                    	; 1360              {
2169                    	; 1361              if (partptr[0] & 0x80)
2170                    	; 1362                  dskmap[partdsk].bootable = YES;
2171                    	; 1363              if (curblkno == 0)
2172                    	; 1364                  dskmap[partdsk].partype = PARTMBR;
2173                    	; 1365              else
2174                    	; 1366                  dskmap[partdsk].partype = PARTEBR;
2175                    	; 1367              dskmap[partdsk].dskletter = 'A' + partdsk;
2176                    	; 1368              dskmap[partdsk].dskstart = curblkno + lbastart;
2177                    	; 1369              dskmap[partdsk].dskend = curblkno + lbastart + lbasize - 1;
2178                    	; 1370              dskmap[partdsk].dsksize = lbasize;
2179                    	; 1371              dskmap[partdsk].dsktype[0] = partptr[4];
2180                    	; 1372              partdsk++;
2181                    	; 1373              }
2182                    	; 1374          }
2183                    	; 1375  
2184                    	; 1376      if (sdtestflg)
2185                    	; 1377          {
2186                    	; 1378          printf("  partition start LBA: %lu [%08lx]\n",
2187                    	; 1379                 curblkno + lbastart, curblkno + lbastart);
2188                    	; 1380          printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
2189                    	; 1381                 lbasize, lbasize, lbasize >> 11);
2190                    	; 1382          } /* sdtestflg */
2191                    	; 1383      if (partptr[4] == 0xee) /* GPT partitions */
2192                    	; 1384          {
2193                    	; 1385          parttype = PARTGPT;
2194                    	; 1386          if (sdtestflg)
2195                    	; 1387              {
2196                    	; 1388              printf("GTP partitions\n");
2197                    	; 1389              } /* sdtestflg */
2198                    	; 1390          sdgpthdr(lbastart); /* handle GTP partitions */
2199                    	; 1391          /* re-read MBR on sector 0
2200                    	; 1392             This is probably not needed as there
2201                    	; 1393             is only one entry (the first one)
2202                    	; 1394             in the MBR when using GPT */
2203                    	; 1395          if (sdread(sdrdbuf, 0))
2204                    	; 1396              {
2205                    	; 1397              curblkno = 0;
2206                    	; 1398              curblkok = YES;
2207                    	; 1399              }
2208                    	; 1400          else
2209                    	; 1401              {
2210                    	; 1402              if (sdtestflg)
2211                    	; 1403                  {
2212                    	; 1404                  printf("  can't read MBR on sector 0\n");
2213                    	; 1405                  } /* sdtestflg */
2214                    	; 1406              return(-1);
2215                    	; 1407              }
2216                    	; 1408          }
2217                    	; 1409      return (parttype);
2218                    	; 1410      }
2219                    	; 1411  
2220                    	; 1412  /* Read and analyze MBR/EBR partition sector block
2221                    	; 1413   * and go through and print partition entries.
2222                    	; 1414   */
2223                    	; 1415  void sdmbrpart(unsigned long sector)
2224                    	; 1416      {
2225                    	; 1417      int partidx;  /* partition index 1 - 4 */
2226                    	; 1418      int cpartidx; /* chain partition index 1 - 4 */
2227                    	; 1419      int chainidx;
2228                    	; 1420      int enttype;
2229                    	; 1421      unsigned char *entp; /* pointer to partition entry */
2230                    	; 1422      char *mbrebr;
2231                    	; 1423  
2232                    	; 1424      if (sdtestflg)
2233                    	; 1425          {
2234                    	; 1426          if (sector == 0) /* if sector 0 it is MBR else it is EBR */
2235                    	; 1427              mbrebr = "MBR";
2236                    	; 1428          else
2237                    	; 1429              mbrebr = "EBR";
2238                    	; 1430          printf("Read %s from sector %lu\n", mbrebr, sector);
2239                    	; 1431          } /* sdtestflg */
2240                    	; 1432      if (sdread(sdrdbuf, sector))
2241                    	; 1433          {
2242                    	; 1434          curblkno = sector;
2243                    	; 1435          curblkok = YES;
2244                    	; 1436          }
2245                    	; 1437      else
2246                    	; 1438          {
2247                    	; 1439          if (sdtestflg)
2248                    	; 1440              {
2249                    	; 1441              printf("  can't read %s sector %lu\n", mbrebr, sector);
2250                    	; 1442              } /* sdtestflg */
2251                    	; 1443          return;
2252                    	; 1444          }
2253                    	; 1445      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
2254                    	; 1446          {
2255                    	; 1447          if (sdtestflg)
2256                    	; 1448              {
2257                    	; 1449              printf("  no %s boot signature found\n", mbrebr);
2258                    	; 1450              } /* sdtestflg */
2259                    	; 1451          return;
2260                    	; 1452          }
2261                    	; 1453      if (curblkno == 0)
2262                    	; 1454          {
2263                    	; 1455          memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
2264                    	; 1456          if (sdtestflg)
2265                    	; 1457              {
2266                    	; 1458  
2267                    	; 1459              printf("  disk identifier: 0x%02x%02x%02x%02x\n",
2268                    	; 1460                     dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
2269                    	; 1461              } /* sdtestflg */
2270                    	; 1462          }
2271                    	; 1463      /* go through MBR partition entries until first empty */
2272                    	; 1464      /* !!as the MBR entry routine is called recusively a way is
2273                    	; 1465         needed to read sector 0 when going back to MBR if
2274                    	; 1466         there is a primary partition entry after an EBR entry!! */
2275                    	; 1467      entp = &sdrdbuf[0x01be] ;
2276                    	; 1468      for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
2277                    	; 1469          {
2278                    	; 1470          if (sdtestflg)
2279                    	; 1471              {
2280                    	; 1472              printf("%s partition entry %d: ", mbrebr, partidx);
2281                    	; 1473              } /* sdtestflg */
2282                    	; 1474          enttype = sdmbrentry(entp);
2283                    	; 1475          if (enttype == -1) /* read error */
2284                    	; 1476                   return;
2285                    	; 1477          else if (enttype == PARTZRO)
2286                    	; 1478              {
2287                    	; 1479              if (!sdtestflg)
2288                    	; 1480                  {
2289                    	; 1481                  /* if compiled as test program show also empty partitions */
2290                    	; 1482                  break;
2291                    	; 1483                  } /* sdtestflg */
2292                    	; 1484              }
2293                    	; 1485          }
2294                    	; 1486      /* now handle the previously saved EBR partition sectors */
2295                    	; 1487      for (partidx = 0; (partidx < ebrrecidx) && (partdsk < 16); partidx++)
2296                    	; 1488          {
2297                    	; 1489          if (sdread(sdrdbuf, ebrrecs[partidx]))
2298                    	; 1490              {
2299                    	; 1491              curblkno = ebrrecs[partidx];
2300                    	; 1492              curblkok = YES;
2301                    	; 1493              }
2302                    	; 1494          else
2303                    	; 1495              {
2304                    	; 1496              if (sdtestflg)
2305                    	; 1497                  {
2306                    	; 1498                  printf("  can't read %s sector %lu\n", mbrebr, sector);
2307                    	; 1499                  } /* sdtestflg */
2308                    	; 1500              return;
2309                    	; 1501              }
2310                    	; 1502          entp = &sdrdbuf[0x01be] ;
2311                    	; 1503          for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
2312                    	; 1504              {
2313                    	; 1505              if (sdtestflg)
2314                    	; 1506                  {
2315                    	; 1507                  printf("EBR partition entry %d: ", partidx);
2316                    	; 1508                  } /* sdtestflg */
2317                    	; 1509              enttype = sdmbrentry(entp);
2318                    	; 1510              if (enttype == -1) /* read error */
2319                    	; 1511                   return;
2320                    	; 1512              else if (enttype == PARTZRO) /* empty partition entry */
2321                    	; 1513                  {
2322                    	; 1514                  if (sdtestflg)
2323                    	; 1515                      {
2324                    	; 1516                      /* if compiled as test program show also empty partitions */
2325                    	; 1517                      printf("Empty partition entry\n");
2326                    	; 1518                      } /* sdtestflg */
2327                    	; 1519                  else
2328                    	; 1520                      break;
2329                    	; 1521                  }
2330                    	; 1522              else if (enttype == PARTEBR) /* next chained EBR */
2331                    	; 1523                  {
2332                    	; 1524                  if (sdtestflg)
2333                    	; 1525                      {
2334                    	; 1526                      printf("EBR chain\n");
2335                    	; 1527                      } /* sdtestflg */
2336                    	; 1528                  /* follow the EBR chain */
2337                    	; 1529                  for (chainidx = 0;
2338                    	; 1530                      ebrnext && (chainidx < 16) && (partdsk < 16);
2339                    	; 1531                      chainidx++)
2340                    	; 1532                      {
2341                    	; 1533                      /* ugly hack to stop reading the same sector */
2342                    	; 1534                      if (ebrnext == curblkno)
2343                    	; 1535                           break;
2344                    	; 1536                      if (sdread(sdrdbuf, ebrnext))
2345                    	; 1537                          {
2346                    	; 1538                          curblkno = ebrnext;
2347                    	; 1539                          curblkok = YES;
2348                    	; 1540                          }
2349                    	; 1541                      else
2350                    	; 1542                          {
2351                    	; 1543                          if (sdtestflg)
2352                    	; 1544                              {
2353                    	; 1545                              printf("  can't read %s sector %lu\n", mbrebr, sector);
2354                    	; 1546                              } /* sdtestflg */
2355                    	; 1547                          return;
2356                    	; 1548                          }
2357                    	; 1549                      entp = &sdrdbuf[0x01be] ;
2358                    	; 1550                      for (cpartidx = 1;
2359                    	; 1551                          (cpartidx <= 4) && (partdsk < 16);
2360                    	; 1552                          cpartidx++, entp += 16)
2361                    	; 1553                          {
2362                    	; 1554                          if (sdtestflg)
2363                    	; 1555                              {
2364                    	; 1556                              printf("EBR chained  partition entry %d: ",
2365                    	; 1557                                   cpartidx);
2366                    	; 1558                              } /* sdtestflg */
2367                    	; 1559                          enttype = sdmbrentry(entp);
2368                    	; 1560                          if (enttype == -1) /* read error */
2369                    	; 1561                              return;
2370                    	; 1562                          }
2371                    	; 1563                      }
2372                    	; 1564                  }
2373                    	; 1565              }
2374                    	; 1566          }
2375                    	; 1567      }
2376                    	; 1568  
2377                    	; 1569  /* Test init, read and partitions on SD card over the SPI interface
2378                    	; 1570   *
2379                    	; 1571   */
2380                    	; 1572  int main()
2381                    	; 1573      {
2382                    	; 1574      char txtin[10];
2383                    	; 1575      int cmdin;
2384                    	; 1576      int idx;
2385                    	; 1577      int cmpidx;
2386                    	; 1578      unsigned char *cmpptr;
2387                    	; 1579      int inlength;
2388                    	; 1580      unsigned long blockno;
2389                    	; 1581  
2390                    	; 1582      blockno = 0;
2391                    	; 1583      curblkno = 0;
2392    483E  320200    		ld	(_curblkno),a
2393    4841  320300    		ld	(_curblkno+1),a
2394    4844  320400    		ld	(_curblkno+2),a
2395    4847  320500    		ld	(_curblkno+3),a
2396    484A  221000    		ld	(_curblkok),hl
2397                    	; 1584      curblkok = NO;
2398                    	; 1585      sdinitok = NO; /* SD card not initialized yet */
2399    484D  210000    		ld	hl,0
2400    4850  220C00    		ld	(_sdinitok),hl
2401                    	; 1586  
2402                    	; 1587      printf(PRGNAME);
2403    4853  21A142    		ld	hl,L5662
2404    4856  CD0000    		call	_printf
2405                    	; 1588      printf(VERSION);
2406    4859  21AB42    		ld	hl,L5762
2407    485C  CD0000    		call	_printf
2408                    	; 1589      printf(builddate);
2409    485F  210000    		ld	hl,_builddate
2410    4862  CD0000    		call	_printf
2411                    	; 1590      printf("\n");
2412    4865  21B942    		ld	hl,L5072
2413    4868  CD0000    		call	_printf
2414                    	L1716:
2415                    	; 1591      while (YES) /* forever (until Ctrl-C) */
2416                    	; 1592          {
2417                    	; 1593          printf("cmd (? for help): ");
2418    486B  21BB42    		ld	hl,L5172
2419    486E  CD0000    		call	_printf
2420                    	; 1594  
2421                    	; 1595          cmdin = getchar();
2422    4871  CD0000    		call	_getchar
2423    4874  DD71EE    		ld	(ix-18),c
2424    4877  DD70EF    		ld	(ix-17),b
2425                    	; 1596          switch (cmdin)
2426    487A  DD4EEE    		ld	c,(ix-18)
2427    487D  DD46EF    		ld	b,(ix-17)
2428    4880  21F047    		ld	hl,L1126
2429    4883  C30000    		jp	c.jtab
2430                    	L1326:
2431                    	; 1597              {
2432                    	; 1598              case '?':
2433                    	; 1599                  printf(" ? - help\n");
2434    4886  21CE42    		ld	hl,L5272
2435    4889  CD0000    		call	_printf
2436                    	; 1600                  printf(PRGNAME);
2437    488C  21D942    		ld	hl,L5372
2438    488F  CD0000    		call	_printf
2439                    	; 1601                  printf(VERSION);
2440    4892  21E342    		ld	hl,L5472
2441    4895  CD0000    		call	_printf
2442                    	; 1602                  printf(builddate);
2443    4898  210000    		ld	hl,_builddate
2444    489B  CD0000    		call	_printf
2445                    	; 1603                  printf("\nCommands:\n");
2446    489E  21F142    		ld	hl,L5572
2447    48A1  CD0000    		call	_printf
2448                    	; 1604                  printf("  ? - help\n");
2449    48A4  21FD42    		ld	hl,L5672
2450    48A7  CD0000    		call	_printf
2451                    	; 1605                  printf("  b - boot from SD card\n");
2452    48AA  210943    		ld	hl,L5772
2453    48AD  CD0000    		call	_printf
2454                    	; 1606                  printf("  d - debug on/off\n");
2455    48B0  212243    		ld	hl,L5003
2456    48B3  CD0000    		call	_printf
2457                    	; 1607                  printf("  i - initialize SD card\n");
2458    48B6  213643    		ld	hl,L5103
2459    48B9  CD0000    		call	_printf
2460                    	; 1608                  printf("  l - print partition layout\n");
2461    48BC  215043    		ld	hl,L5203
2462    48BF  CD0000    		call	_printf
2463                    	; 1609                  printf("  n - set/show block #N to read\n");
2464    48C2  216E43    		ld	hl,L5303
2465    48C5  CD0000    		call	_printf
2466                    	; 1610                  printf("  p - print block last read/to write\n");
2467    48C8  218F43    		ld	hl,L5403
2468    48CB  CD0000    		call	_printf
2469                    	; 1611                  printf("  r - read block #N\n");
2470    48CE  21B543    		ld	hl,L5503
2471    48D1  CD0000    		call	_printf
2472                    	; 1612                  printf("  s - print SD registers\n");
2473    48D4  21CA43    		ld	hl,L5603
2474    48D7  CD0000    		call	_printf
2475                    	; 1613                  printf("  t - test probe SD card\n");
2476    48DA  21E443    		ld	hl,L5703
2477    48DD  CD0000    		call	_printf
2478                    	; 1614                  printf("  u - upload program with Xmodem\n");
2479    48E0  21FE43    		ld	hl,L5013
2480    48E3  CD0000    		call	_printf
2481                    	; 1615                  printf("  w - read block #N\n");
2482    48E6  212044    		ld	hl,L5113
2483    48E9  CD0000    		call	_printf
2484                    	; 1616                  printf("  Ctrl-C to reload monitor.\n");
2485    48EC  213544    		ld	hl,L5213
2486    48EF  CD0000    		call	_printf
2487                    	; 1617                  break;
2488    48F2  C36B48    		jp	L1716
2489                    	L1426:
2490                    	; 1618              case 'b':
2491                    	; 1619                  printf(" d - boot from SD card - ");
2492    48F5  215244    		ld	hl,L5313
2493    48F8  CD0000    		call	_printf
2494                    	; 1620                  printf("implementation ongoing\n");
2495    48FB  216C44    		ld	hl,L5413
2496    48FE  CD0000    		call	_printf
2497                    	; 1621                  break;
2498    4901  C36B48    		jp	L1716
2499                    	L1526:
2500                    	; 1622              case 'd':
2501                    	; 1623                  printf(" d - toggle debug flag - ");
2502    4904  218444    		ld	hl,L5513
2503    4907  CD0000    		call	_printf
2504                    	; 1624                  if (sdtestflg)
2505    490A  2A0000    		ld	hl,(_sdtestflg)
2506    490D  7C        		ld	a,h
2507    490E  B5        		or	l
2508    490F  280F      		jr	z,L1626
2509                    	; 1625                      {
2510                    	; 1626                      sdtestflg = NO;
2511    4911  210000    		ld	hl,0
2512    4914  220000    		ld	(_sdtestflg),hl
2513                    	; 1627                      printf("OFF\n");
2514    4917  219E44    		ld	hl,L5613
2515    491A  CD0000    		call	_printf
2516                    	; 1628                      }
2517                    	; 1629                  else
2518    491D  C36B48    		jp	L1716
2519                    	L1626:
2520                    	; 1630                      {
2521                    	; 1631                      sdtestflg = YES;
2522    4920  210100    		ld	hl,1
2523    4923  220000    		ld	(_sdtestflg),hl
2524                    	; 1632                      printf("ON\n");
2525    4926  21A344    		ld	hl,L5713
2526    4929  CD0000    		call	_printf
2527    492C  C36B48    		jp	L1716
2528                    	L1036:
2529                    	; 1633                      }
2530                    	; 1634                  break;
2531                    	; 1635              case 'i':
2532                    	; 1636                  printf(" i - initialize SD card");
2533    492F  21A744    		ld	hl,L5023
2534    4932  CD0000    		call	_printf
2535                    	; 1637                  if (sdinit())
2536    4935  CD0806    		call	_sdinit
2537    4938  79        		ld	a,c
2538    4939  B0        		or	b
2539    493A  2809      		jr	z,L1136
2540                    	; 1638                      printf(" - ok\n");
2541    493C  21BF44    		ld	hl,L5123
2542    493F  CD0000    		call	_printf
2543                    	; 1639                  else
2544    4942  C36B48    		jp	L1716
2545                    	L1136:
2546                    	; 1640                      printf(" - not inserted or faulty\n");
2547    4945  21C644    		ld	hl,L5223
2548    4948  CD0000    		call	_printf
2549    494B  C36B48    		jp	L1716
2550                    	L1336:
2551                    	; 1641                  break;
2552                    	; 1642              case 'l':
2553                    	; 1643                  printf(" l - print partition layout\n");
2554    494E  21E144    		ld	hl,L5323
2555    4951  CD0000    		call	_printf
2556                    	; 1644                  if (!sdprobe())
2557    4954  CD0910    		call	_sdprobe
2558    4957  79        		ld	a,c
2559    4958  B0        		or	b
2560    4959  2009      		jr	nz,L1436
2561                    	; 1645                      {
2562                    	; 1646                      printf(" - SD not initialized or inserted or faulty\n");
2563    495B  21FE44    		ld	hl,L5423
2564    495E  CD0000    		call	_printf
2565                    	; 1647                      break;
2566    4961  C36B48    		jp	L1716
2567                    	L1436:
2568                    	; 1648                      }
2569                    	; 1649                  ebrrecidx = 0;
2570                    	; 1650                  partdsk = 0;
2571                    	;    1  /*  z80sdbt.c Boot and test program trying to make a unified prog.
2572                    	;    2   *
2573                    	;    3   *  Boot code for my DIY Z80 Computer. This
2574                    	;    4   *  program is compiled with Whitesmiths/COSMIC
2575                    	;    5   *  C compiler for Z80.
2576                    	;    6   *
2577                    	;    7   *  From this file z80sdtst.c is generated with SDTEST defined.
2578                    	;    8   *
2579                    	;    9   *  Initializes the hardware and detects the
2580                    	;   10   *  presence and partitioning of an attached SD card.
2581                    	;   11   *
2582                    	;   12   *  You are free to use, modify, and redistribute
2583                    	;   13   *  this source code. No warranties are given.
2584                    	;   14   *  Hastily Cobbled Together 2021 and 2022
2585                    	;   15   *  by Hans-Ake Lund
2586                    	;   16   *
2587                    	;   17   */
2588                    	;   18  
2589                    	;   19  #include <std.h>
2590                    	;   20  #include "z80computer.h"
2591                    	;   21  #include "builddate.h"
2592                    	;   22  
2593                    	;   23  #define PRGNAME "\nz80sdbt "
2594                    	;   24  #define VERSION "version 0.7, "
2595                    	;   25  /* This code should be cleaned up when
2596                    	;   26     remaining functions are implemented
2597                    	;   27   */
2598                    	;   28  #define PARTZRO 0  /* Empty partition entry */
2599                    	;   29  #define PARTMBR 1  /* MBR partition */
2600                    	;   30  #define PARTEBR 2  /* EBR logical partition */
2601                    	;   31  #define PARTGPT 3  /* GPT partition */
2602                    	;   32  #define EBRCONT 20 /* EBR container partition in MBR */
2603                    	;   33  
2604                    	;   34  struct partentry
2605                    	;   35      {
2606                    	;   36      char partype;
2607                    	;   37      char dskletter;
2608                    	;   38      int bootable;
2609                    	;   39      unsigned long dskstart;
2610                    	;   40      unsigned long dskend;
2611                    	;   41      unsigned long dsksize;
2612                    	;   42      unsigned char dsktype[16];
2613                    	;   43      } dskmap[16];
2614                    	;   44  
2615                    	;   45  unsigned char dsksign[4]; /* MBR/EBR disk signature */
2616                    	;   46  
2617                    	;   47  /* Function prototypes */
2618                    	;   48  void sdmbrpart(unsigned long);
2619                    	;   49  
2620                    	;   50  /* Response length in bytes
2621                    	;   51   */
2622                    	;   52  #define R1_LEN 1
2623                    	;   53  #define R3_LEN 5
2624                    	;   54  #define R7_LEN 5
2625                    	;   55  
2626                    	;   56  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
2627                    	;   57   * (The CRC7 byte in the tables below are only for information,
2628                    	;   58   * it is calculated by the sdcommand routine.)
2629                    	;   59   */
2630                    	;   60  const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
2631                    	;   61  const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
2632                    	;   62  const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
2633                    	;   63  const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
2634                    	;   64  const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
2635                    	;   65  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
2636                    	;   66  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
2637                    	;   67  const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
2638                    	;   68  const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
2639                    	;   69  const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};
2640                    	;   70  
2641                    	;   71  /* Partition identifiers
2642                    	;   72   */
2643                    	;   73  /* For GPT I have decided that a CP/M partition
2644                    	;   74   * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
2645                    	;   75   */
2646                    	;   76  const unsigned char gptcpm[] =
2647                    	;   77      {
2648                    	;   78      0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
2649                    	;   79      0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
2650                    	;   80      };
2651                    	;   81  /* For MBR/EBR the partition type for CP/M is 0x52
2652                    	;   82   * according to: https://en.wikipedia.org/wiki/Partition_type
2653                    	;   83   */
2654                    	;   84  const unsigned char mbrcpm = 0x52;    /* CP/M partition */
2655                    	;   85  const unsigned char mbrexcode = 0x5f; /* Z80 executable code partition */
2656                    	;   86  /* has a special format that */
2657                    	;   87  /* includes number of sectors to */
2658                    	;   88  /* load and a signature, TBD */
2659                    	;   89  
2660                    	;   90  /* Buffers
2661                    	;   91   */
2662                    	;   92  unsigned char sdrdbuf[512];  /* recieved data from the SD card */
2663                    	;   93  
2664                    	;   94  unsigned char ocrreg[4];     /* SD card OCR register */
2665                    	;   95  unsigned char cidreg[16];    /* SD card CID register */
2666                    	;   96  unsigned char csdreg[16];    /* SD card CSD register */
2667                    	;   97  unsigned long ebrrecs[4];    /* detected EBR records to process */
2668                    	;   98  int ebrrecidx; /* how many EBR records that are populated */
2669                    	;   99  unsigned long ebrnext; /* next chained ebr record */
2670                    	;  100  
2671                    	;  101  /* Variables
2672                    	;  102   */
2673                    	;  103  int curblkok;  /* if YES curblockno is read into buffer */
2674                    	;  104  int partdsk;   /* partition/disk number, 0 = disk A */
2675                    	;  105  int sdinitok;  /* SD card initialized and ready */
2676                    	;  106  int sdver2;    /* SD card version 2 if YES, version 1 if NO */
2677                    	;  107  unsigned long blkmult;   /* block address multiplier */
2678                    	;  108  unsigned long curblkno;  /* block in buffer if curblkok == YES */
2679                    	;  109  
2680                    	;  110  /* debug bool */
2681                    	;  111  int sdtestflg;
2682                    	;  112  
2683                    	;  113  /* CRC routines from:
2684                    	;  114   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
2685                    	;  115   */
2686                    	;  116  
2687                    	;  117  /*
2688                    	;  118  // Calculate CRC7
2689                    	;  119  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
2690                    	;  120  // input:
2691                    	;  121  //   crcIn - the CRC before (0 for first step)
2692                    	;  122  //   data - byte for CRC calculation
2693                    	;  123  // return: the new CRC7
2694                    	;  124  */
2695                    	;  125  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
2696                    	;  126      {
2697                    	;  127      const unsigned char g = 0x89;
2698                    	;  128      unsigned char i;
2699                    	;  129  
2700                    	;  130      crcIn ^= data;
2701                    	;  131      for (i = 0; i < 8; i++)
2702                    	;  132          {
2703                    	;  133          if (crcIn & 0x80) crcIn ^= g;
2704                    	;  134          crcIn <<= 1;
2705                    	;  135          }
2706                    	;  136  
2707                    	;  137      return crcIn;
2708                    	;  138      }
2709                    	;  139  
2710                    	;  140  /*
2711                    	;  141  // Calculate CRC16 CCITT
2712                    	;  142  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
2713                    	;  143  // input:
2714                    	;  144  //   crcIn - the CRC before (0 for rist step)
2715                    	;  145  //   data - byte for CRC calculation
2716                    	;  146  // return: the CRC16 value
2717                    	;  147  */
2718                    	;  148  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
2719                    	;  149      {
2720                    	;  150      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
2721                    	;  151      crcIn ^=  data;
2722                    	;  152      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
2723                    	;  153      crcIn ^= (crcIn << 8) << 4;
2724                    	;  154      crcIn ^= ((crcIn & 0xff) << 4) << 1;
2725                    	;  155  
2726                    	;  156      return crcIn;
2727                    	;  157      }
2728                    	;  158  
2729                    	;  159  /* Send command to SD card and recieve answer.
2730                    	;  160   * A command is 5 bytes long and is followed by
2731                    	;  161   * a CRC7 checksum byte.
2732                    	;  162   * Returns a pointer to the response
2733                    	;  163   * or 0 if no response start bit found.
2734                    	;  164   */
2735                    	;  165  unsigned char *sdcommand(unsigned char *sdcmdp,
2736                    	;  166                           unsigned char *recbuf, int recbytes)
2737                    	;  167      {
2738                    	;  168      int searchn;  /* byte counter to search for response */
2739                    	;  169      int sdcbytes; /* byte counter for bytes to send */
2740                    	;  170      unsigned char *retptr; /* pointer used to store response */
2741                    	;  171      unsigned char rbyte;   /* recieved byte */
2742                    	;  172      unsigned char crc = 0; /* calculated CRC7 */
2743                    	;  173  
2744                    	;  174      /* send 8*2 clockpules */
2745                    	;  175      spiio(0xff);
2746                    	;  176      spiio(0xff);
2747                    	;  177      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
2748                    	;  178          {
2749                    	;  179          crc = CRC7_one(crc, *sdcmdp);
2750                    	;  180          spiio(*sdcmdp++);
2751                    	;  181          }
2752                    	;  182      spiio(crc | 0x01);
2753                    	;  183      /* search for recieved byte with start bit
2754                    	;  184         for a maximum of 10 recieved bytes  */
2755                    	;  185      for (searchn = 10; 0 < searchn; searchn--)
2756                    	;  186          {
2757                    	;  187          rbyte = spiio(0xff);
2758                    	;  188          if ((rbyte & 0x80) == 0)
2759                    	;  189              break;
2760                    	;  190          }
2761                    	;  191      if (searchn == 0) /* no start bit found */
2762                    	;  192          return (NO);
2763                    	;  193      retptr = recbuf;
2764                    	;  194      *retptr++ = rbyte;
2765                    	;  195      for (; 1 < recbytes; recbytes--) /* recieve bytes */
2766                    	;  196          *retptr++ = spiio(0xff);
2767                    	;  197      return (recbuf);
2768                    	;  198      }
2769                    	;  199  
2770                    	;  200  /* Initialise SD card interface
2771                    	;  201   *
2772                    	;  202   * returns YES if ok and NO if not ok
2773                    	;  203   *
2774                    	;  204   * References:
2775                    	;  205   *   https://www.sdcard.org/downloads/pls/
2776                    	;  206   *      Physical Layer Simplified Specification version 8.0
2777                    	;  207   *
2778                    	;  208   * A nice flowchart how to initialize:
2779                    	;  209   *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
2780                    	;  210   *
2781                    	;  211   */
2782                    	;  212  int sdinit()
2783                    	;  213      {
2784                    	;  214      int nbytes;  /* byte counter */
2785                    	;  215      int tries;   /* tries to get to active state or searching for data  */
2786                    	;  216      int wtloop;  /* timer loop when trying to enter active state */
2787                    	;  217      unsigned char cmdbuf[5];   /* buffer to build command in */
2788                    	;  218      unsigned char rstatbuf[5]; /* buffer to recieve status in */
2789                    	;  219      unsigned char *statptr;    /* pointer to returned status from SD command */
2790                    	;  220      unsigned char crc;         /* crc register for CID and CSD */
2791                    	;  221      unsigned char rbyte;       /* recieved byte */
2792                    	;  222      unsigned char *prtptr;     /* for debug printing */
2793                    	;  223  
2794                    	;  224      ledon();
2795                    	;  225      spideselect();
2796                    	;  226      sdinitok = NO;
2797                    	;  227  
2798                    	;  228      /* start to generate 9*8 clock pulses with not selected SD card */
2799                    	;  229      for (nbytes = 9; 0 < nbytes; nbytes--)
2800                    	;  230          spiio(0xff);
2801                    	;  231      if (sdtestflg)
2802                    	;  232          {
2803                    	;  233          printf("\nSent 8*8 (72) clock pulses, select not active\n");
2804                    	;  234          } /* sdtestflg */
2805                    	;  235      spiselect();
2806                    	;  236  
2807                    	;  237      /* CMD0: GO_IDLE_STATE */
2808                    	;  238      for (tries = 0; tries < 10; tries++)
2809                    	;  239          {
2810                    	;  240          memcpy(cmdbuf, cmd0, 5);
2811                    	;  241          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2812                    	;  242          if (sdtestflg)
2813                    	;  243              {
2814                    	;  244              if (!statptr)
2815                    	;  245                  printf("CMD0: no response\n");
2816                    	;  246              else
2817                    	;  247                  printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
2818                    	;  248              } /* sdtestflg */
2819                    	;  249          if (!statptr)
2820                    	;  250              {
2821                    	;  251              spideselect();
2822                    	;  252              ledoff();
2823                    	;  253              return (NO);
2824                    	;  254              }
2825                    	;  255          if (statptr[0] == 0x01)
2826                    	;  256              break;
2827                    	;  257          for (wtloop = 0; wtloop < tries * 10; wtloop++)
2828                    	;  258              {
2829                    	;  259              /* wait loop, time increasing for each try */
2830                    	;  260              spiio(0xff);
2831                    	;  261              }
2832                    	;  262          }
2833                    	;  263  
2834                    	;  264      /* CMD8: SEND_IF_COND */
2835                    	;  265      memcpy(cmdbuf, cmd8, 5);
2836                    	;  266      statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
2837                    	;  267      if (sdtestflg)
2838                    	;  268          {
2839                    	;  269          if (!statptr)
2840                    	;  270              printf("CMD8: no response\n");
2841                    	;  271          else
2842                    	;  272              {
2843                    	;  273              printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
2844                    	;  274                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2845                    	;  275              if (!(statptr[0] & 0xfe)) /* no error */
2846                    	;  276                  {
2847                    	;  277                  if (statptr[4] == 0xaa)
2848                    	;  278                      printf("echo back ok, ");
2849                    	;  279                  else
2850                    	;  280                      printf("invalid echo back\n");
2851                    	;  281                  }
2852                    	;  282              }
2853                    	;  283          } /* sdtestflg */
2854                    	;  284      if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
2855                    	;  285          {
2856                    	;  286          sdver2 = NO;
2857                    	;  287          if (sdtestflg)
2858                    	;  288              {
2859                    	;  289              printf("probably SD ver. 1\n");
2860                    	;  290              } /* sdtestflg */
2861                    	;  291          }
2862                    	;  292      else
2863                    	;  293          {
2864                    	;  294          sdver2 = YES;
2865                    	;  295          if (statptr[4] != 0xaa) /* but invalid echo back */
2866                    	;  296              {
2867                    	;  297              spideselect();
2868                    	;  298              ledoff();
2869                    	;  299              return (NO);
2870                    	;  300              }
2871                    	;  301          if (sdtestflg)
2872                    	;  302              {
2873                    	;  303              printf("SD ver 2\n");
2874                    	;  304              } /* sdtestflg */
2875                    	;  305          }
2876                    	;  306  
2877                    	;  307      /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
2878                    	;  308      for (tries = 0; tries < 20; tries++)
2879                    	;  309          {
2880                    	;  310          memcpy(cmdbuf, cmd55, 5);
2881                    	;  311          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2882                    	;  312          if (sdtestflg)
2883                    	;  313              {
2884                    	;  314              if (!statptr)
2885                    	;  315                  printf("CMD55: no response\n");
2886                    	;  316              else
2887                    	;  317                  printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
2888                    	;  318              } /* sdtestflg */
2889                    	;  319          if (!statptr)
2890                    	;  320              {
2891                    	;  321              spideselect();
2892                    	;  322              ledoff();
2893                    	;  323              return (NO);
2894                    	;  324              }
2895                    	;  325          memcpy(cmdbuf, acmd41, 5);
2896                    	;  326          if (sdver2)
2897                    	;  327              cmdbuf[1] = 0x40;
2898                    	;  328          else
2899                    	;  329              cmdbuf[1] = 0x00;
2900                    	;  330          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2901                    	;  331          if (sdtestflg)
2902                    	;  332              {
2903                    	;  333              if (!statptr)
2904                    	;  334                  printf("ACMD41: no response\n");
2905                    	;  335              else
2906                    	;  336                  printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
2907                    	;  337                         statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
2908                    	;  338              } /* sdtestflg */
2909                    	;  339          if (!statptr)
2910                    	;  340              {
2911                    	;  341              spideselect();
2912                    	;  342              ledoff();
2913                    	;  343              return (NO);
2914                    	;  344              }
2915                    	;  345          if (statptr[0] == 0x00) /* now the SD card is ready */
2916                    	;  346              {
2917                    	;  347              break;
2918                    	;  348              }
2919                    	;  349          for (wtloop = 0; wtloop < tries * 10; wtloop++)
2920                    	;  350              {
2921                    	;  351              /* wait loop, time increasing for each try */
2922                    	;  352              spiio(0xff);
2923                    	;  353              }
2924                    	;  354          }
2925                    	;  355  
2926                    	;  356      /* CMD58: READ_OCR */
2927                    	;  357      /* According to the flow chart this should not work
2928                    	;  358         for SD ver. 1 but the response is ok anyway
2929                    	;  359         all tested SD cards  */
2930                    	;  360      memcpy(cmdbuf, cmd58, 5);
2931                    	;  361      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
2932                    	;  362      if (sdtestflg)
2933                    	;  363          {
2934                    	;  364          if (!statptr)
2935                    	;  365              printf("CMD58: no response\n");
2936                    	;  366          else
2937                    	;  367              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
2938                    	;  368                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
2939                    	;  369          } /* sdtestflg */
2940                    	;  370      if (!statptr)
2941                    	;  371          {
2942                    	;  372          spideselect();
2943                    	;  373          ledoff();
2944                    	;  374          return (NO);
2945                    	;  375          }
2946                    	;  376      memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
2947                    	;  377      blkmult = 1; /* assume block address */
2948                    	;  378      if (ocrreg[0] & 0x80)
2949                    	;  379          {
2950                    	;  380          /* SD Ver.2+ */
2951                    	;  381          if (!(ocrreg[0] & 0x40))
2952                    	;  382              {
2953                    	;  383              /* SD Ver.2+, Byte address */
2954                    	;  384              blkmult = 512;
2955                    	;  385              }
2956                    	;  386          }
2957                    	;  387  
2958                    	;  388      /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
2959                    	;  389      if (blkmult == 512)
2960                    	;  390          {
2961                    	;  391          memcpy(cmdbuf, cmd16, 5);
2962                    	;  392          statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2963                    	;  393          if (sdtestflg)
2964                    	;  394              {
2965                    	;  395              if (!statptr)
2966                    	;  396                  printf("CMD16: no response\n");
2967                    	;  397              else
2968                    	;  398                  printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
2969                    	;  399                         statptr[0]);
2970                    	;  400              } /* sdtestflg */
2971                    	;  401          if (!statptr)
2972                    	;  402              {
2973                    	;  403              spideselect();
2974                    	;  404              ledoff();
2975                    	;  405              return (NO);
2976                    	;  406              }
2977                    	;  407          }
2978                    	;  408      /* Register information:
2979                    	;  409       *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
2980                    	;  410       */
2981                    	;  411  
2982                    	;  412      /* CMD10: SEND_CID */
2983                    	;  413      memcpy(cmdbuf, cmd10, 5);
2984                    	;  414      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
2985                    	;  415      if (sdtestflg)
2986                    	;  416          {
2987                    	;  417          if (!statptr)
2988                    	;  418              printf("CMD10: no response\n");
2989                    	;  419          else
2990                    	;  420              printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
2991                    	;  421          } /* sdtestflg */
2992                    	;  422      if (!statptr)
2993                    	;  423          {
2994                    	;  424          spideselect();
2995                    	;  425          ledoff();
2996                    	;  426          return (NO);
2997                    	;  427          }
2998                    	;  428      /* looking for 0xfe that is the byte before data */
2999                    	;  429      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
3000                    	;  430          ;
3001                    	;  431      if (tries == 0) /* tried too many times */
3002                    	;  432          {
3003                    	;  433          if (sdtestflg)
3004                    	;  434              {
3005                    	;  435              printf("  No data found\n");
3006                    	;  436              } /* sdtestflg */
3007                    	;  437          spideselect();
3008                    	;  438          ledoff();
3009                    	;  439          return (NO);
3010                    	;  440          }
3011                    	;  441      else
3012                    	;  442          {
3013                    	;  443          crc = 0;
3014                    	;  444          for (nbytes = 0; nbytes < 15; nbytes++)
3015                    	;  445              {
3016                    	;  446              rbyte = spiio(0xff);
3017                    	;  447              cidreg[nbytes] = rbyte;
3018                    	;  448              crc = CRC7_one(crc, rbyte);
3019                    	;  449              }
3020                    	;  450          cidreg[15] = spiio(0xff);
3021                    	;  451          crc |= 0x01;
3022                    	;  452          /* some SD cards need additional clock pulses */
3023                    	;  453          for (nbytes = 9; 0 < nbytes; nbytes--)
3024                    	;  454              spiio(0xff);
3025                    	;  455          if (sdtestflg)
3026                    	;  456              {
3027                    	;  457              prtptr = &cidreg[0];
3028                    	;  458              printf("  CID: [");
3029                    	;  459              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
3030                    	;  460                  printf("%02x ", *prtptr);
3031                    	;  461              prtptr = &cidreg[0];
3032                    	;  462              printf("\b] |");
3033                    	;  463              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
3034                    	;  464                  {
3035                    	;  465                  if ((' ' <= *prtptr) && (*prtptr < 127))
3036                    	;  466                      putchar(*prtptr);
3037                    	;  467                  else
3038                    	;  468                      putchar('.');
3039                    	;  469                  }
3040                    	;  470              printf("|\n");
3041                    	;  471              if (crc == cidreg[15])
3042                    	;  472                  {
3043                    	;  473                  printf("CRC7 ok: [%02x]\n", crc);
3044                    	;  474                  }
3045                    	;  475              else
3046                    	;  476                  {
3047                    	;  477                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
3048                    	;  478                         crc, cidreg[15]);
3049                    	;  479                  /* could maybe return failure here */
3050                    	;  480                  }
3051                    	;  481              } /* sdtestflg */
3052                    	;  482          }
3053                    	;  483  
3054                    	;  484      /* CMD9: SEND_CSD */
3055                    	;  485      memcpy(cmdbuf, cmd9, 5);
3056                    	;  486      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3057                    	;  487      if (sdtestflg)
3058                    	;  488          {
3059                    	;  489          if (!statptr)
3060                    	;  490              printf("CMD9: no response\n");
3061                    	;  491          else
3062                    	;  492              printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
3063                    	;  493          } /* sdtestflg */
3064                    	;  494      if (!statptr)
3065                    	;  495          {
3066                    	;  496          spideselect();
3067                    	;  497          ledoff();
3068                    	;  498          return (NO);
3069                    	;  499          }
3070                    	;  500      /* looking for 0xfe that is the byte before data */
3071                    	;  501      for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
3072                    	;  502          ;
3073                    	;  503      if (tries == 0) /* tried too many times */
3074                    	;  504          {
3075                    	;  505          if (sdtestflg)
3076                    	;  506              {
3077                    	;  507              printf("  No data found\n");
3078                    	;  508              } /* sdtestflg */
3079                    	;  509          return (NO);
3080                    	;  510          }
3081                    	;  511      else
3082                    	;  512          {
3083                    	;  513          crc = 0;
3084                    	;  514          for (nbytes = 0; nbytes < 15; nbytes++)
3085                    	;  515              {
3086                    	;  516              rbyte = spiio(0xff);
3087                    	;  517              csdreg[nbytes] = rbyte;
3088                    	;  518              crc = CRC7_one(crc, rbyte);
3089                    	;  519              }
3090                    	;  520          csdreg[15] = spiio(0xff);
3091                    	;  521          crc |= 0x01;
3092                    	;  522          /* some SD cards need additional clock pulses */
3093                    	;  523          for (nbytes = 9; 0 < nbytes; nbytes--)
3094                    	;  524              spiio(0xff);
3095                    	;  525          if (sdtestflg)
3096                    	;  526              {
3097                    	;  527              prtptr = &csdreg[0];
3098                    	;  528              printf("  CSD: [");
3099                    	;  529              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
3100                    	;  530                  printf("%02x ", *prtptr);
3101                    	;  531              prtptr = &csdreg[0];
3102                    	;  532              printf("\b] |");
3103                    	;  533              for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
3104                    	;  534                  {
3105                    	;  535                  if ((' ' <= *prtptr) && (*prtptr < 127))
3106                    	;  536                      putchar(*prtptr);
3107                    	;  537                  else
3108                    	;  538                      putchar('.');
3109                    	;  539                  }
3110                    	;  540              printf("|\n");
3111                    	;  541              if (crc == csdreg[15])
3112                    	;  542                  {
3113                    	;  543                  printf("CRC7 ok: [%02x]\n", crc);
3114                    	;  544                  }
3115                    	;  545              else
3116                    	;  546                  {
3117                    	;  547                  printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
3118                    	;  548                         crc, csdreg[15]);
3119                    	;  549                  /* could maybe return failure here */
3120                    	;  550                  }
3121                    	;  551              } /* sdtestflg */
3122                    	;  552          }
3123                    	;  553  
3124                    	;  554      for (nbytes = 9; 0 < nbytes; nbytes--)
3125                    	;  555          spiio(0xff);
3126                    	;  556      if (sdtestflg)
3127                    	;  557          {
3128                    	;  558          printf("Sent 9*8 (72) clock pulses, select active\n");
3129                    	;  559          } /* sdtestflg */
3130                    	;  560  
3131                    	;  561      sdinitok = YES;
3132                    	;  562  
3133                    	;  563      spideselect();
3134                    	;  564      ledoff();
3135                    	;  565  
3136                    	;  566      return (YES);
3137                    	;  567      }
3138                    	;  568  
3139                    	;  569  int sdprobe()
3140                    	;  570      {
3141                    	;  571      unsigned char cmdbuf[5];   /* buffer to build command in */
3142                    	;  572      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3143                    	;  573      unsigned char *statptr;    /* pointer to returned status from SD command */
3144                    	;  574      int nbytes;  /* byte counter */
3145                    	;  575      int allzero = YES;
3146                    	;  576  
3147                    	;  577      ledon();
3148                    	;  578      spiselect();
3149                    	;  579  
3150                    	;  580      /* CMD58: READ_OCR */
3151                    	;  581      memcpy(cmdbuf, cmd58, 5);
3152                    	;  582      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
3153                    	;  583      for (nbytes = 0; nbytes < 5; nbytes++)
3154                    	;  584          {
3155                    	;  585          if (statptr[nbytes] != 0)
3156                    	;  586              allzero = NO;
3157                    	;  587          }
3158                    	;  588      if (sdtestflg)
3159                    	;  589          {
3160                    	;  590          if (!statptr)
3161                    	;  591              printf("CMD58: no response\n");
3162                    	;  592          else
3163                    	;  593              {
3164                    	;  594              printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
3165                    	;  595                     statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
3166                    	;  596              if (allzero)
3167                    	;  597                  printf("SD card not inserted or not initialized\n");
3168                    	;  598              }
3169                    	;  599          } /* sdtestflg */
3170                    	;  600      if (!statptr || allzero)
3171                    	;  601          {
3172                    	;  602          sdinitok = NO;
3173                    	;  603          spideselect();
3174                    	;  604          ledoff();
3175                    	;  605          return (NO);
3176                    	;  606          }
3177                    	;  607  
3178                    	;  608      spideselect();
3179                    	;  609      ledoff();
3180                    	;  610  
3181                    	;  611      return (YES);
3182                    	;  612      }
3183                    	;  613  
3184                    	;  614  /* print OCR, CID and CSD registers*/
3185                    	;  615  void sdprtreg()
3186                    	;  616      {
3187                    	;  617      unsigned int n;
3188                    	;  618      unsigned int csize;
3189                    	;  619      unsigned long devsize;
3190                    	;  620      unsigned long capacity;
3191                    	;  621  
3192                    	;  622      if (!sdinitok)
3193                    	;  623          {
3194                    	;  624          printf("SD card not initialized\n");
3195                    	;  625          return;
3196                    	;  626          }
3197                    	;  627      printf("SD card information:");
3198                    	;  628      if (ocrreg[0] & 0x80)
3199                    	;  629          {
3200                    	;  630          if (ocrreg[0] & 0x40)
3201                    	;  631              printf("  SD card ver. 2+, Block address\n");
3202                    	;  632          else
3203                    	;  633              {
3204                    	;  634              if (sdver2)
3205                    	;  635                  printf("  SD card ver. 2+, Byte address\n");
3206                    	;  636              else
3207                    	;  637                  printf("  SD card ver. 1, Byte address\n");
3208                    	;  638              }
3209                    	;  639          }
3210                    	;  640      printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
3211                    	;  641      printf("OEM ID: %.2s, ", &cidreg[1]);
3212                    	;  642      printf("Product name: %.5s\n", &cidreg[3]);
3213                    	;  643      printf("  Product revision: %d.%d, ",
3214                    	;  644             (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
3215                    	;  645      printf("Serial number: %lu\n",
3216                    	;  646             (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
3217                    	;  647      printf("  Manufacturing date: %d-%d, ",
3218                    	;  648             2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
3219                    	;  649      if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
3220                    	;  650          {
3221                    	;  651          n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
3222                    	;  652          csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
3223                    	;  653                  ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
3224                    	;  654          capacity = (unsigned long) csize << (n-10);
3225                    	;  655          printf("Device capacity: %lu MByte\n", capacity >> 10);
3226                    	;  656          }
3227                    	;  657      if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
3228                    	;  658          {
3229                    	;  659          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
3230                    	;  660                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
3231                    	;  661          capacity = devsize << 9;
3232                    	;  662          printf("Device capacity: %lu MByte\n", capacity >> 10);
3233                    	;  663          }
3234                    	;  664      if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
3235                    	;  665          {
3236                    	;  666          devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
3237                    	;  667                    ((unsigned long)(csdreg[7] & 63) << 16) + 1;
3238                    	;  668          capacity = devsize << 9;
3239                    	;  669          printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
3240                    	;  670          }
3241                    	;  671  
3242                    	;  672      if (sdtestflg)
3243                    	;  673          {
3244                    	;  674  
3245                    	;  675          printf("--------------------------------------\n");
3246                    	;  676          printf("OCR register:\n");
3247                    	;  677          if (ocrreg[2] & 0x80)
3248                    	;  678              printf("2.7-2.8V (bit 15) ");
3249                    	;  679          if (ocrreg[1] & 0x01)
3250                    	;  680              printf("2.8-2.9V (bit 16) ");
3251                    	;  681          if (ocrreg[1] & 0x02)
3252                    	;  682              printf("2.9-3.0V (bit 17) ");
3253                    	;  683          if (ocrreg[1] & 0x04)
3254                    	;  684              printf("3.0-3.1V (bit 18) \n");
3255                    	;  685          if (ocrreg[1] & 0x08)
3256                    	;  686              printf("3.1-3.2V (bit 19) ");
3257                    	;  687          if (ocrreg[1] & 0x10)
3258                    	;  688              printf("3.2-3.3V (bit 20) ");
3259                    	;  689          if (ocrreg[1] & 0x20)
3260                    	;  690              printf("3.3-3.4V (bit 21) ");
3261                    	;  691          if (ocrreg[1] & 0x40)
3262                    	;  692              printf("3.4-3.5V (bit 22) \n");
3263                    	;  693          if (ocrreg[1] & 0x80)
3264                    	;  694              printf("3.5-3.6V (bit 23) \n");
3265                    	;  695          if (ocrreg[0] & 0x01)
3266                    	;  696              printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
3267                    	;  697          if (ocrreg[0] & 0x08)
3268                    	;  698              printf("Over 2TB support Status (CO2T) (bit 27) set\n");
3269                    	;  699          if (ocrreg[0] & 0x20)
3270                    	;  700              printf("UHS-II Card Status (bit 29) set ");
3271                    	;  701          if (ocrreg[0] & 0x80)
3272                    	;  702              {
3273                    	;  703              if (ocrreg[0] & 0x40)
3274                    	;  704                  {
3275                    	;  705                  printf("Card Capacity Status (CCS) (bit 30) set\n");
3276                    	;  706                  printf("  SD Ver.2+, Block address");
3277                    	;  707                  }
3278                    	;  708              else
3279                    	;  709                  {
3280                    	;  710                  printf("Card Capacity Status (CCS) (bit 30) not set\n");
3281                    	;  711                  if (sdver2)
3282                    	;  712                      printf("  SD Ver.2+, Byte address");
3283                    	;  713                  else
3284                    	;  714                      printf("  SD Ver.1, Byte address");
3285                    	;  715                  }
3286                    	;  716              printf("\nCard power up status bit (busy) (bit 31) set\n");
3287                    	;  717              }
3288                    	;  718          else
3289                    	;  719              {
3290                    	;  720              printf("\nCard power up status bit (busy) (bit 31) not set.\n");
3291                    	;  721              printf("  This bit is not set if the card has not finished the power up routine.\n");
3292                    	;  722              }
3293                    	;  723          printf("--------------------------------------\n");
3294                    	;  724          printf("CID register:\n");
3295                    	;  725          printf("MID: 0x%02x, ", cidreg[0]);
3296                    	;  726          printf("OID: %.2s, ", &cidreg[1]);
3297                    	;  727          printf("PNM: %.5s, ", &cidreg[3]);
3298                    	;  728          printf("PRV: %d.%d, ",
3299                    	;  729                 (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
3300                    	;  730          printf("PSN: %lu, ",
3301                    	;  731                 (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
3302                    	;  732          printf("MDT: %d-%d\n",
3303                    	;  733                 2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
3304                    	;  734          printf("--------------------------------------\n");
3305                    	;  735          printf("CSD register:\n");
3306                    	;  736          if ((csdreg[0] & 0xc0) == 0x00)
3307                    	;  737              {
3308                    	;  738              printf("CSD Version 1.0, Standard Capacity\n");
3309                    	;  739              n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
3310                    	;  740              csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
3311                    	;  741                      ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
3312                    	;  742              capacity = (unsigned long) csize << (n-10);
3313                    	;  743              printf(" Device capacity: %lu KByte, %lu MByte\n",
3314                    	;  744                     capacity, capacity >> 10);
3315                    	;  745              }
3316                    	;  746          if ((csdreg[0] & 0xc0) == 0x40)
3317                    	;  747              {
3318                    	;  748              printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
3319                    	;  749              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
3320                    	;  750                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
3321                    	;  751              capacity = devsize << 9;
3322                    	;  752              printf(" Device capacity: %lu KByte, %lu MByte\n",
3323                    	;  753                     capacity, capacity >> 10);
3324                    	;  754              }
3325                    	;  755          if ((csdreg[0] & 0xc0) == 0x80)
3326                    	;  756              {
3327                    	;  757              printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
3328                    	;  758              devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
3329                    	;  759                        + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
3330                    	;  760              capacity = devsize << 9;
3331                    	;  761              printf(" Device capacity: %lu KByte, %lu MByte\n",
3332                    	;  762                     capacity, capacity >> 10);
3333                    	;  763              }
3334                    	;  764          printf("--------------------------------------\n");
3335                    	;  765  
3336                    	;  766          } /* sdtestflg */ /* SDTEST */
3337                    	;  767  
3338                    	;  768      }
3339                    	;  769  
3340                    	;  770  /* Read data block of 512 bytes to buffer
3341                    	;  771   * Returns YES if ok or NO if error
3342                    	;  772   */
3343                    	;  773  int sdread(unsigned char *rdbuf, unsigned long rdblkno)
3344                    	;  774      {
3345                    	;  775      unsigned char *statptr;
3346                    	;  776      unsigned char rbyte;
3347                    	;  777      unsigned char cmdbuf[5];   /* buffer to build command in */
3348                    	;  778      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3349                    	;  779      int nbytes;
3350                    	;  780      int tries;
3351                    	;  781      unsigned long blktoread;
3352                    	;  782      unsigned int rxcrc16;
3353                    	;  783      unsigned int calcrc16;
3354                    	;  784  
3355                    	;  785      ledon();
3356                    	;  786      spiselect();
3357                    	;  787  
3358                    	;  788      if (!sdinitok)
3359                    	;  789          {
3360                    	;  790          if (sdtestflg)
3361                    	;  791              {
3362                    	;  792              printf("SD card not initialized\n");
3363                    	;  793              } /* sdtestflg */
3364                    	;  794          spideselect();
3365                    	;  795          ledoff();
3366                    	;  796          return (NO);
3367                    	;  797          }
3368                    	;  798  
3369                    	;  799      /* CMD17: READ_SINGLE_BLOCK */
3370                    	;  800      /* Insert block # into command */
3371                    	;  801      memcpy(cmdbuf, cmd17, 5);
3372                    	;  802      blktoread = blkmult * rdblkno;
3373                    	;  803      cmdbuf[4] = blktoread & 0xff;
3374                    	;  804      blktoread = blktoread >> 8;
3375                    	;  805      cmdbuf[3] = blktoread & 0xff;
3376                    	;  806      blktoread = blktoread >> 8;
3377                    	;  807      cmdbuf[2] = blktoread & 0xff;
3378                    	;  808      blktoread = blktoread >> 8;
3379                    	;  809      cmdbuf[1] = blktoread & 0xff;
3380                    	;  810  
3381                    	;  811      if (sdtestflg)
3382                    	;  812          {
3383                    	;  813          printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
3384                    	;  814                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
3385                    	;  815          } /* sdtestflg */
3386                    	;  816      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3387                    	;  817      if (sdtestflg)
3388                    	;  818          {
3389                    	;  819          printf("CMD17 R1 response [%02x]\n", statptr[0]);
3390                    	;  820          } /* sdtestflg */
3391                    	;  821      if (statptr[0])
3392                    	;  822          {
3393                    	;  823          if (sdtestflg)
3394                    	;  824              {
3395                    	;  825              printf("  could not read block\n");
3396                    	;  826              } /* sdtestflg */
3397                    	;  827          spideselect();
3398                    	;  828          ledoff();
3399                    	;  829          return (NO);
3400                    	;  830          }
3401                    	;  831      /* looking for 0xfe that is the byte before data */
3402                    	;  832      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
3403                    	;  833          {
3404                    	;  834          if ((rbyte & 0xe0) == 0x00)
3405                    	;  835              {
3406                    	;  836              /* If a read operation fails and the card cannot provide
3407                    	;  837                 the required data, it will send a data error token instead
3408                    	;  838               */
3409                    	;  839              if (sdtestflg)
3410                    	;  840                  {
3411                    	;  841                  printf("  read error: [%02x]\n", rbyte);
3412                    	;  842                  } /* sdtestflg */
3413                    	;  843              spideselect();
3414                    	;  844              ledoff();
3415                    	;  845              return (NO);
3416                    	;  846              }
3417                    	;  847          }
3418                    	;  848      if (tries == 0) /* tried too many times */
3419                    	;  849          {
3420                    	;  850          if (sdtestflg)
3421                    	;  851              {
3422                    	;  852              printf("  no data found\n");
3423                    	;  853              } /* sdtestflg */
3424                    	;  854          spideselect();
3425                    	;  855          ledoff();
3426                    	;  856          return (NO);
3427                    	;  857          }
3428                    	;  858      else
3429                    	;  859          {
3430                    	;  860          calcrc16 = 0;
3431                    	;  861          for (nbytes = 0; nbytes < 512; nbytes++)
3432                    	;  862              {
3433                    	;  863              rbyte = spiio(0xff);
3434                    	;  864              calcrc16 = CRC16_one(calcrc16, rbyte);
3435                    	;  865              rdbuf[nbytes] = rbyte;
3436                    	;  866              }
3437                    	;  867          rxcrc16 = spiio(0xff) << 8;
3438                    	;  868          rxcrc16 += spiio(0xff);
3439                    	;  869  
3440                    	;  870          if (sdtestflg)
3441                    	;  871              {
3442                    	;  872              printf("  read data block %ld:\n", rdblkno);
3443                    	;  873              } /* sdtestflg */
3444                    	;  874          if (rxcrc16 != calcrc16)
3445                    	;  875              {
3446                    	;  876              if (sdtestflg)
3447                    	;  877                  {
3448                    	;  878                  printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
3449                    	;  879                         rxcrc16, calcrc16);
3450                    	;  880                  } /* sdtestflg */
3451                    	;  881              spideselect();
3452                    	;  882              ledoff();
3453                    	;  883              return (NO);
3454                    	;  884              }
3455                    	;  885          }
3456                    	;  886      spideselect();
3457                    	;  887      ledoff();
3458                    	;  888      return (YES);
3459                    	;  889      }
3460                    	;  890  
3461                    	;  891  /* Write data block of 512 bytes from buffer
3462                    	;  892   * Returns YES if ok or NO if error
3463                    	;  893   */
3464                    	;  894  int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
3465                    	;  895      {
3466                    	;  896      unsigned char *statptr;
3467                    	;  897      unsigned char rbyte;
3468                    	;  898      unsigned char tbyte;
3469                    	;  899      unsigned char cmdbuf[5];   /* buffer to build command in */
3470                    	;  900      unsigned char rstatbuf[5]; /* buffer to recieve status in */
3471                    	;  901      int nbytes;
3472                    	;  902      int tries;
3473                    	;  903      unsigned long blktowrite;
3474                    	;  904      unsigned int calcrc16;
3475                    	;  905  
3476                    	;  906      ledon();
3477                    	;  907      spiselect();
3478                    	;  908  
3479                    	;  909      if (!sdinitok)
3480                    	;  910          {
3481                    	;  911          if (sdtestflg)
3482                    	;  912              {
3483                    	;  913              printf("SD card not initialized\n");
3484                    	;  914              } /* sdtestflg */
3485                    	;  915          spideselect();
3486                    	;  916          ledoff();
3487                    	;  917          return (NO);
3488                    	;  918          }
3489                    	;  919  
3490                    	;  920      if (sdtestflg)
3491                    	;  921          {
3492                    	;  922          printf("  write data block %ld:\n", wrblkno);
3493                    	;  923          } /* sdtestflg */
3494                    	;  924      /* CMD24: WRITE_SINGLE_BLOCK */
3495                    	;  925      /* Insert block # into command */
3496                    	;  926      memcpy(cmdbuf, cmd24, 5);
3497                    	;  927      blktowrite = blkmult * wrblkno;
3498                    	;  928      cmdbuf[4] = blktowrite & 0xff;
3499                    	;  929      blktowrite = blktowrite >> 8;
3500                    	;  930      cmdbuf[3] = blktowrite & 0xff;
3501                    	;  931      blktowrite = blktowrite >> 8;
3502                    	;  932      cmdbuf[2] = blktowrite & 0xff;
3503                    	;  933      blktowrite = blktowrite >> 8;
3504                    	;  934      cmdbuf[1] = blktowrite & 0xff;
3505                    	;  935  
3506                    	;  936      if (sdtestflg)
3507                    	;  937          {
3508                    	;  938          printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
3509                    	;  939                 cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
3510                    	;  940          } /* sdtestflg */
3511                    	;  941      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
3512                    	;  942      if (sdtestflg)
3513                    	;  943          {
3514                    	;  944          printf("CMD24 R1 response [%02x]\n", statptr[0]);
3515                    	;  945          } /* sdtestflg */
3516                    	;  946      if (statptr[0])
3517                    	;  947          {
3518                    	;  948          if (sdtestflg)
3519                    	;  949              {
3520                    	;  950              printf("  could not write block\n");
3521                    	;  951              } /* sdtestflg */
3522                    	;  952          spideselect();
3523                    	;  953          ledoff();
3524                    	;  954          return (NO);
3525                    	;  955          }
3526                    	;  956      /* send 0xfe, the byte before data */
3527                    	;  957      spiio(0xfe);
3528                    	;  958      /* initialize crc and send block */
3529                    	;  959      calcrc16 = 0;
3530                    	;  960      for (nbytes = 0; nbytes < 512; nbytes++)
3531                    	;  961          {
3532                    	;  962          tbyte = wrbuf[nbytes];
3533                    	;  963          spiio(tbyte);
3534                    	;  964          calcrc16 = CRC16_one(calcrc16, tbyte);
3535                    	;  965          }
3536                    	;  966      spiio((calcrc16 >> 8) & 0xff);
3537                    	;  967      spiio(calcrc16 & 0xff);
3538                    	;  968  
3539                    	;  969      /* check data resposnse */
3540                    	;  970      for (tries = 20;
3541                    	;  971              0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
3542                    	;  972              tries--)
3543                    	;  973          ;
3544                    	;  974      if (tries == 0)
3545                    	;  975          {
3546                    	;  976          if (sdtestflg)
3547                    	;  977              {
3548                    	;  978              printf("No data response\n");
3549                    	;  979              } /* sdtestflg */
3550                    	;  980          spideselect();
3551                    	;  981          ledoff();
3552                    	;  982          return (NO);
3553                    	;  983          }
3554                    	;  984      else
3555                    	;  985          {
3556                    	;  986          if (sdtestflg)
3557                    	;  987              {
3558                    	;  988              printf("Data response [%02x]", 0x1f & rbyte);
3559                    	;  989              } /* sdtestflg */
3560                    	;  990          if ((0x1f & rbyte) == 0x05)
3561                    	;  991              {
3562                    	;  992              if (sdtestflg)
3563                    	;  993                  {
3564                    	;  994                  printf(", data accepted\n");
3565                    	;  995                  } /* sdtestflg */
3566                    	;  996              for (nbytes = 9; 0 < nbytes; nbytes--)
3567                    	;  997                  spiio(0xff);
3568                    	;  998              if (sdtestflg)
3569                    	;  999                  {
3570                    	; 1000                  printf("Sent 9*8 (72) clock pulses, select active\n");
3571                    	; 1001                  } /* sdtestflg */
3572                    	; 1002              spideselect();
3573                    	; 1003              ledoff();
3574                    	; 1004              return (YES);
3575                    	; 1005              }
3576                    	; 1006          else
3577                    	; 1007              {
3578                    	; 1008              if (sdtestflg)
3579                    	; 1009                  {
3580                    	; 1010                  printf(", data not accepted\n");
3581                    	; 1011                  } /* sdtestflg */
3582                    	; 1012              spideselect();
3583                    	; 1013              ledoff();
3584                    	; 1014              return (NO);
3585                    	; 1015              }
3586                    	; 1016          }
3587                    	; 1017      }
3588                    	; 1018  
3589                    	; 1019  /* Print data in 512 byte buffer */
3590                    	; 1020  void sddatprt(unsigned char *prtbuf)
3591                    	; 1021      {
3592                    	; 1022      /* Variables used for "pretty-print" */
3593                    	; 1023      int allzero, dmpline, dotprted, lastallz, nbytes;
3594                    	; 1024      unsigned char *prtptr;
3595                    	; 1025  
3596                    	; 1026      prtptr = prtbuf;
3597                    	; 1027      dotprted = NO;
3598                    	; 1028      lastallz = NO;
3599                    	; 1029      for (dmpline = 0; dmpline < 32; dmpline++)
3600                    	; 1030          {
3601                    	; 1031          /* test if all 16 bytes are 0x00 */
3602                    	; 1032          allzero = YES;
3603                    	; 1033          for (nbytes = 0; nbytes < 16; nbytes++)
3604                    	; 1034              {
3605                    	; 1035              if (prtptr[nbytes] != 0)
3606                    	; 1036                  allzero = NO;
3607                    	; 1037              }
3608                    	; 1038          if (lastallz && allzero)
3609                    	; 1039              {
3610                    	; 1040              if (!dotprted)
3611                    	; 1041                  {
3612                    	; 1042                  printf("*\n");
3613                    	; 1043                  dotprted = YES;
3614                    	; 1044                  }
3615                    	; 1045              }
3616                    	; 1046          else
3617                    	; 1047              {
3618                    	; 1048              dotprted = NO;
3619                    	; 1049              /* print offset */
3620                    	; 1050              printf("%04x ", dmpline * 16);
3621                    	; 1051              /* print 16 bytes in hex */
3622                    	; 1052              for (nbytes = 0; nbytes < 16; nbytes++)
3623                    	; 1053                  printf("%02x ", prtptr[nbytes]);
3624                    	; 1054              /* print these bytes in ASCII if printable */
3625                    	; 1055              printf(" |");
3626                    	; 1056              for (nbytes = 0; nbytes < 16; nbytes++)
3627                    	; 1057                  {
3628                    	; 1058                  if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
3629                    	; 1059                      putchar(prtptr[nbytes]);
3630                    	; 1060                  else
3631                    	; 1061                      putchar('.');
3632                    	; 1062                  }
3633                    	; 1063              printf("|\n");
3634                    	; 1064              }
3635                    	; 1065          prtptr += 16;
3636                    	; 1066          lastallz = allzero;
3637                    	; 1067          }
3638                    	; 1068      }
3639                    	; 1069  
3640                    	; 1070  /* Print GUID (mixed endian format)
3641                    	; 1071   */
3642                    	; 1072  void prtguid(unsigned char *guidptr)
3643                    	; 1073      {
3644                    	; 1074      int index;
3645                    	; 1075  
3646                    	; 1076      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
3647                    	; 1077      printf("%02x%02x-", guidptr[5], guidptr[4]);
3648                    	; 1078      printf("%02x%02x-", guidptr[7], guidptr[6]);
3649                    	; 1079      printf("%02x%02x-", guidptr[8], guidptr[9]);
3650                    	; 1080      printf("%02x%02x%02x%02x%02x%02x",
3651                    	; 1081             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
3652                    	; 1082      }
3653                    	; 1083  
3654                    	; 1084  /* Analyze and print GPT entry
3655                    	; 1085   */
3656                    	; 1086  int prtgptent(unsigned int entryno)
3657                    	; 1087      {
3658                    	; 1088      int index;
3659                    	; 1089      int entryidx;
3660                    	; 1090      int hasname;
3661                    	; 1091      unsigned int block;
3662                    	; 1092      unsigned char *rxdata;
3663                    	; 1093      unsigned char *entryptr;
3664                    	; 1094      unsigned char tstzero = 0;
3665                    	; 1095      unsigned long flba;
3666                    	; 1096      unsigned long llba;
3667                    	; 1097  
3668                    	; 1098      block = 2 + (entryno / 4);
3669                    	; 1099      if ((curblkno != block) || !curblkok)
3670                    	; 1100          {
3671                    	; 1101          if (!sdread(sdrdbuf, block))
3672                    	; 1102              {
3673                    	; 1103              if (sdtestflg)
3674                    	; 1104                  {
3675                    	; 1105                  printf("Can't read GPT entry block\n");
3676                    	; 1106                  return (NO);
3677                    	; 1107                  } /* sdtestflg */
3678                    	; 1108              }
3679                    	; 1109          curblkno = block;
3680                    	; 1110          curblkok = YES;
3681                    	; 1111          }
3682                    	; 1112      rxdata = sdrdbuf;
3683                    	; 1113      entryptr = rxdata + (128 * (entryno % 4));
3684                    	; 1114      for (index = 0; index < 16; index++)
3685                    	; 1115          tstzero |= entryptr[index];
3686                    	; 1116      if (sdtestflg)
3687                    	; 1117          {
3688                    	; 1118          printf("GPT partition entry %d:", entryno + 1);
3689                    	; 1119          } /* sdtestflg */
3690                    	; 1120      if (!tstzero)
3691                    	; 1121          {
3692                    	; 1122          if (sdtestflg)
3693                    	; 1123              {
3694                    	; 1124              printf(" Not used entry\n");
3695                    	; 1125              } /* sdtestflg */
3696                    	; 1126          return (NO);
3697                    	; 1127          }
3698                    	; 1128      if (sdtestflg)
3699                    	; 1129          {
3700                    	; 1130          printf("\n  Partition type GUID: ");
3701                    	; 1131          prtguid(entryptr);
3702                    	; 1132          printf("\n  [");
3703                    	; 1133          for (index = 0; index < 16; index++)
3704                    	; 1134              printf("%02x ", entryptr[index]);
3705                    	; 1135          printf("\b]");
3706                    	; 1136          printf("\n  Unique partition GUID: ");
3707                    	; 1137          prtguid(entryptr + 16);
3708                    	; 1138          printf("\n  [");
3709                    	; 1139          for (index = 0; index < 16; index++)
3710                    	; 1140              printf("%02x ", (entryptr + 16)[index]);
3711                    	; 1141          printf("\b]");
3712                    	; 1142          printf("\n  First LBA: ");
3713                    	; 1143          /* lower 32 bits of LBA should be sufficient (I hope) */
3714                    	; 1144          } /* sdtestflg */
3715                    	; 1145      flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
3716                    	; 1146             ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
3717                    	; 1147      if (sdtestflg)
3718                    	; 1148          {
3719                    	; 1149          printf("%lu", flba);
3720                    	; 1150          printf(" [");
3721                    	; 1151          for (index = 32; index < (32 + 8); index++)
3722                    	; 1152              printf("%02x ", entryptr[index]);
3723                    	; 1153          printf("\b]");
3724                    	; 1154          printf("\n  Last LBA: ");
3725                    	; 1155          } /* sdtestflg */
3726                    	; 1156      /* lower 32 bits of LBA should be sufficient (I hope) */
3727                    	; 1157      llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
3728                    	; 1158             ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
3729                    	; 1159  
3730                    	; 1160      if (entryptr[48] & 0x04)
3731                    	; 1161          dskmap[partdsk].bootable = YES;
3732                    	; 1162      dskmap[partdsk].partype = PARTGPT;
3733                    	; 1163      dskmap[partdsk].dskletter = 'A' + partdsk;
3734                    	; 1164      dskmap[partdsk].dskstart = flba;
3735                    	; 1165      dskmap[partdsk].dskend = llba;
3736                    	; 1166      dskmap[partdsk].dsksize = llba - flba + 1;
3737                    	; 1167      memcpy(dskmap[partdsk].dsktype, entryptr, 16);
3738                    	; 1168      partdsk++;
3739                    	; 1169  
3740                    	; 1170      if (sdtestflg)
3741                    	; 1171          {
3742                    	; 1172          printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
3743                    	; 1173          printf(" [");
3744                    	; 1174          for (index = 40; index < (40 + 8); index++)
3745                    	; 1175              printf("%02x ", entryptr[index]);
3746                    	; 1176          printf("\b]");
3747                    	; 1177          printf("\n  Attribute flags: [");
3748                    	; 1178          /* bits 0 - 2 and 60 - 63 should be decoded */
3749                    	; 1179          for (index = 0; index < 8; index++)
3750                    	; 1180              {
3751                    	; 1181              entryidx = index + 48;
3752                    	; 1182              printf("%02x ", entryptr[entryidx]);
3753                    	; 1183              }
3754                    	; 1184          printf("\b]\n  Partition name:  ");
3755                    	; 1185          } /* sdtestflg */
3756                    	; 1186      /* partition name is in UTF-16LE code units */
3757                    	; 1187      hasname = NO;
3758                    	; 1188      for (index = 0; index < 72; index += 2)
3759                    	; 1189          {
3760                    	; 1190          entryidx = index + 56;
3761                    	; 1191          if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
3762                    	; 1192              break;
3763                    	; 1193          if (sdtestflg)
3764                    	; 1194              {
3765                    	; 1195              if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
3766                    	; 1196                  putchar(entryptr[entryidx]);
3767                    	; 1197              else
3768                    	; 1198                  putchar('.');
3769                    	; 1199              } /* sdtestflg */
3770                    	; 1200          hasname = YES;
3771                    	; 1201          }
3772                    	; 1202      if (sdtestflg)
3773                    	; 1203          {
3774                    	; 1204          if (!hasname)
3775                    	; 1205              printf("name field empty");
3776                    	; 1206          printf("\n");
3777                    	; 1207          printf("   [");
3778                    	; 1208          for (index = 0; index < 72; index++)
3779                    	; 1209              {
3780                    	; 1210              if (((index & 0xf) == 0) && (index != 0))
3781                    	; 1211                  printf("\n    ");
3782                    	; 1212              entryidx = index + 56;
3783                    	; 1213              printf("%02x ", entryptr[entryidx]);
3784                    	; 1214              }
3785                    	; 1215          printf("\b]\n");
3786                    	; 1216          } /* sdtestflg */
3787                    	; 1217      return (YES);
3788                    	; 1218      }
3789                    	; 1219  
3790                    	; 1220  /* Analyze and print GPT header
3791                    	; 1221   */
3792                    	; 1222  void sdgpthdr(unsigned long block)
3793                    	; 1223      {
3794                    	; 1224      int index;
3795                    	; 1225      unsigned int partno;
3796                    	; 1226      unsigned char *rxdata;
3797                    	; 1227      unsigned long entries;
3798                    	; 1228  
3799                    	; 1229      if (sdtestflg)
3800                    	; 1230          {
3801                    	; 1231          printf("GPT header\n");
3802                    	; 1232          } /* sdtestflg */
3803                    	; 1233      if (!sdread(sdrdbuf, block))
3804                    	; 1234          {
3805                    	; 1235          if (sdtestflg)
3806                    	; 1236              {
3807                    	; 1237              printf("Can't read GPT partition table header\n");
3808                    	; 1238              } /* sdtestflg */
3809                    	; 1239          return;
3810                    	; 1240          }
3811                    	; 1241      curblkno = block;
3812                    	; 1242      curblkok = YES;
3813                    	; 1243  
3814                    	; 1244      rxdata = sdrdbuf;
3815                    	; 1245      if (sdtestflg)
3816                    	; 1246          {
3817                    	; 1247          printf("  Signature: %.8s\n", &rxdata[0]);
3818                    	; 1248          printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
3819                    	; 1249                 (int)rxdata[8] * ((int)rxdata[9] << 8),
3820                    	; 1250                 (int)rxdata[10] + ((int)rxdata[11] << 8),
3821                    	; 1251                 rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
3822                    	; 1252          entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
3823                    	; 1253                    ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
3824                    	; 1254          printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
3825                    	; 1255          } /* sdtestflg */
3826                    	; 1256      for (partno = 0; (partno < 16) && (partdsk < 16); partno++)
3827                    	; 1257          {
3828                    	; 1258          if (!prtgptent(partno))
3829                    	; 1259              {
3830                    	; 1260              if (!sdtestflg)
3831                    	; 1261                  {
3832                    	; 1262                  /* go through all entries if compiled as test program */
3833                    	; 1263                  return;
3834                    	; 1264                  } /* sdtestflg */
3835                    	; 1265              }
3836                    	; 1266          }
3837                    	; 1267      if (sdtestflg)
3838                    	; 1268          {
3839                    	; 1269          printf("First 16 GPT entries scanned\n");
3840                    	; 1270          } /* sdtestflg */
3841                    	; 1271      }
3842                    	; 1272  
3843                    	; 1273  /* Analyze and print MBR partition entry
3844                    	; 1274   * Returns:
3845                    	; 1275   *    -1 if errror - should not happen
3846                    	; 1276   *     0 if not used entry
3847                    	; 1277   *     1 if MBR entry
3848                    	; 1278   *     2 if EBR entry
3849                    	; 1279   *     3 if GTP entry
3850                    	; 1280   */
3851                    	; 1281  int sdmbrentry(unsigned char *partptr)
3852                    	; 1282      {
3853                    	; 1283      int index;
3854                    	; 1284      int parttype;
3855                    	; 1285      unsigned long lbastart;
3856                    	; 1286      unsigned long lbasize;
3857                    	; 1287  
3858                    	; 1288      parttype = PARTMBR;
3859                    	; 1289      if (!partptr[4])
3860                    	; 1290          {
3861                    	; 1291          if (sdtestflg)
3862                    	; 1292              {
3863                    	; 1293              printf("Not used entry\n");
3864                    	; 1294              } /* sdtestflg */
3865                    	; 1295          return (PARTZRO);
3866                    	; 1296          }
3867                    	; 1297      if (sdtestflg)
3868                    	; 1298          {
3869                    	; 1299          printf("Boot indicator: 0x%02x, System ID: 0x%02x\n",
3870                    	; 1300                 partptr[0], partptr[4]);
3871                    	; 1301  
3872                    	; 1302          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
3873                    	; 1303              {
3874                    	; 1304              printf("  Extended partition entry\n");
3875                    	; 1305              }
3876                    	; 1306          if (partptr[0] & 0x01)
3877                    	; 1307              {
3878                    	; 1308              printf("  Unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
3879                    	; 1309              /* this is however discussed
3880                    	; 1310                 https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
3881                    	; 1311              */
3882                    	; 1312              }
3883                    	; 1313          else
3884                    	; 1314              {
3885                    	; 1315              printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3886                    	; 1316                     partptr[1], partptr[2], partptr[3],
3887                    	; 1317                     ((partptr[2] & 0xc0) >> 2) + partptr[3],
3888                    	; 1318                     partptr[1],
3889                    	; 1319                     partptr[2] & 0x3f);
3890                    	; 1320              printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
3891                    	; 1321                     partptr[5], partptr[6], partptr[7],
3892                    	; 1322                     ((partptr[6] & 0xc0) >> 2) + partptr[7],
3893                    	; 1323                     partptr[5],
3894                    	; 1324                     partptr[6] & 0x3f);
3895                    	; 1325              }
3896                    	; 1326          } /* sdtestflg */
3897                    	; 1327      /* not showing high 16 bits if 48 bit LBA */
3898                    	; 1328      lbastart = (unsigned long)partptr[8] +
3899                    	; 1329                 ((unsigned long)partptr[9] << 8) +
3900                    	; 1330                 ((unsigned long)partptr[10] << 16) +
3901                    	; 1331                 ((unsigned long)partptr[11] << 24);
3902                    	; 1332      lbasize = (unsigned long)partptr[12] +
3903                    	; 1333                ((unsigned long)partptr[13] << 8) +
3904                    	; 1334                ((unsigned long)partptr[14] << 16) +
3905                    	; 1335                ((unsigned long)partptr[15] << 24);
3906                    	; 1336  
3907                    	; 1337      if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
3908                    	; 1338          {
3909                    	; 1339          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
3910                    	; 1340              {
3911                    	; 1341              parttype = PARTEBR;
3912                    	; 1342              if (curblkno == 0) /* points to EBR in the MBR */
3913                    	; 1343                  {
3914                    	; 1344                  ebrnext = 0;
3915                    	; 1345                  dskmap[partdsk].partype = EBRCONT;
3916                    	; 1346                  dskmap[partdsk].dskletter = 'A' + partdsk;
3917                    	; 1347                  dskmap[partdsk].dskstart = lbastart;
3918                    	; 1348                  dskmap[partdsk].dskend = lbastart + lbasize - 1;
3919                    	; 1349                  dskmap[partdsk].dsksize = lbasize;
3920                    	; 1350                  dskmap[partdsk].dsktype[0] = partptr[4];
3921                    	; 1351                  partdsk++;
3922                    	; 1352                  ebrrecs[ebrrecidx++] = lbastart; /* save to handle later */
3923                    	; 1353                  }
3924                    	; 1354              else
3925                    	; 1355                  {
3926                    	; 1356                  ebrnext = curblkno + lbastart;
3927                    	; 1357                  }
3928                    	; 1358              }
3929                    	; 1359          else
3930                    	; 1360              {
3931                    	; 1361              if (partptr[0] & 0x80)
3932                    	; 1362                  dskmap[partdsk].bootable = YES;
3933                    	; 1363              if (curblkno == 0)
3934                    	; 1364                  dskmap[partdsk].partype = PARTMBR;
3935                    	; 1365              else
3936                    	; 1366                  dskmap[partdsk].partype = PARTEBR;
3937                    	; 1367              dskmap[partdsk].dskletter = 'A' + partdsk;
3938                    	; 1368              dskmap[partdsk].dskstart = curblkno + lbastart;
3939                    	; 1369              dskmap[partdsk].dskend = curblkno + lbastart + lbasize - 1;
3940                    	; 1370              dskmap[partdsk].dsksize = lbasize;
3941                    	; 1371              dskmap[partdsk].dsktype[0] = partptr[4];
3942                    	; 1372              partdsk++;
3943                    	; 1373              }
3944                    	; 1374          }
3945                    	; 1375  
3946                    	; 1376      if (sdtestflg)
3947                    	; 1377          {
3948                    	; 1378          printf("  partition start LBA: %lu [%08lx]\n",
3949                    	; 1379                 curblkno + lbastart, curblkno + lbastart);
3950                    	; 1380          printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
3951                    	; 1381                 lbasize, lbasize, lbasize >> 11);
3952                    	; 1382          } /* sdtestflg */
3953                    	; 1383      if (partptr[4] == 0xee) /* GPT partitions */
3954                    	; 1384          {
3955                    	; 1385          parttype = PARTGPT;
3956                    	; 1386          if (sdtestflg)
3957                    	; 1387              {
3958                    	; 1388              printf("GTP partitions\n");
3959                    	; 1389              } /* sdtestflg */
3960                    	; 1390          sdgpthdr(lbastart); /* handle GTP partitions */
3961                    	; 1391          /* re-read MBR on sector 0
3962                    	; 1392             This is probably not needed as there
3963                    	; 1393             is only one entry (the first one)
3964                    	; 1394             in the MBR when using GPT */
3965                    	; 1395          if (sdread(sdrdbuf, 0))
3966                    	; 1396              {
3967                    	; 1397              curblkno = 0;
3968                    	; 1398              curblkok = YES;
3969                    	; 1399              }
3970                    	; 1400          else
3971                    	; 1401              {
3972                    	; 1402              if (sdtestflg)
3973                    	; 1403                  {
3974                    	; 1404                  printf("  can't read MBR on sector 0\n");
3975                    	; 1405                  } /* sdtestflg */
3976                    	; 1406              return(-1);
3977                    	; 1407              }
3978                    	; 1408          }
3979                    	; 1409      return (parttype);
3980                    	; 1410      }
3981                    	; 1411  
3982                    	; 1412  /* Read and analyze MBR/EBR partition sector block
3983                    	; 1413   * and go through and print partition entries.
3984                    	; 1414   */
3985                    	; 1415  void sdmbrpart(unsigned long sector)
3986                    	; 1416      {
3987                    	; 1417      int partidx;  /* partition index 1 - 4 */
3988                    	; 1418      int cpartidx; /* chain partition index 1 - 4 */
3989                    	; 1419      int chainidx;
3990                    	; 1420      int enttype;
3991                    	; 1421      unsigned char *entp; /* pointer to partition entry */
3992                    	; 1422      char *mbrebr;
3993                    	; 1423  
3994                    	; 1424      if (sdtestflg)
3995                    	; 1425          {
3996                    	; 1426          if (sector == 0) /* if sector 0 it is MBR else it is EBR */
3997                    	; 1427              mbrebr = "MBR";
3998                    	; 1428          else
3999                    	; 1429              mbrebr = "EBR";
4000                    	; 1430          printf("Read %s from sector %lu\n", mbrebr, sector);
4001                    	; 1431          } /* sdtestflg */
4002                    	; 1432      if (sdread(sdrdbuf, sector))
4003                    	; 1433          {
4004                    	; 1434          curblkno = sector;
4005                    	; 1435          curblkok = YES;
4006                    	; 1436          }
4007                    	; 1437      else
4008                    	; 1438          {
4009                    	; 1439          if (sdtestflg)
4010                    	; 1440              {
4011                    	; 1441              printf("  can't read %s sector %lu\n", mbrebr, sector);
4012                    	; 1442              } /* sdtestflg */
4013                    	; 1443          return;
4014                    	; 1444          }
4015                    	; 1445      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
4016                    	; 1446          {
4017                    	; 1447          if (sdtestflg)
4018                    	; 1448              {
4019                    	; 1449              printf("  no %s boot signature found\n", mbrebr);
4020                    	; 1450              } /* sdtestflg */
4021                    	; 1451          return;
4022                    	; 1452          }
4023                    	; 1453      if (curblkno == 0)
4024                    	; 1454          {
4025                    	; 1455          memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
4026                    	; 1456          if (sdtestflg)
4027                    	; 1457              {
4028                    	; 1458  
4029                    	; 1459              printf("  disk identifier: 0x%02x%02x%02x%02x\n",
4030                    	; 1460                     dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
4031                    	; 1461              } /* sdtestflg */
4032                    	; 1462          }
4033                    	; 1463      /* go through MBR partition entries until first empty */
4034                    	; 1464      /* !!as the MBR entry routine is called recusively a way is
4035                    	; 1465         needed to read sector 0 when going back to MBR if
4036                    	; 1466         there is a primary partition entry after an EBR entry!! */
4037                    	; 1467      entp = &sdrdbuf[0x01be] ;
4038                    	; 1468      for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
4039                    	; 1469          {
4040                    	; 1470          if (sdtestflg)
4041                    	; 1471              {
4042                    	; 1472              printf("%s partition entry %d: ", mbrebr, partidx);
4043                    	; 1473              } /* sdtestflg */
4044                    	; 1474          enttype = sdmbrentry(entp);
4045                    	; 1475          if (enttype == -1) /* read error */
4046                    	; 1476                   return;
4047                    	; 1477          else if (enttype == PARTZRO)
4048                    	; 1478              {
4049                    	; 1479              if (!sdtestflg)
4050                    	; 1480                  {
4051                    	; 1481                  /* if compiled as test program show also empty partitions */
4052                    	; 1482                  break;
4053                    	; 1483                  } /* sdtestflg */
4054                    	; 1484              }
4055                    	; 1485          }
4056                    	; 1486      /* now handle the previously saved EBR partition sectors */
4057                    	; 1487      for (partidx = 0; (partidx < ebrrecidx) && (partdsk < 16); partidx++)
4058                    	; 1488          {
4059                    	; 1489          if (sdread(sdrdbuf, ebrrecs[partidx]))
4060                    	; 1490              {
4061                    	; 1491              curblkno = ebrrecs[partidx];
4062                    	; 1492              curblkok = YES;
4063                    	; 1493              }
4064                    	; 1494          else
4065                    	; 1495              {
4066                    	; 1496              if (sdtestflg)
4067                    	; 1497                  {
4068                    	; 1498                  printf("  can't read %s sector %lu\n", mbrebr, sector);
4069                    	; 1499                  } /* sdtestflg */
4070                    	; 1500              return;
4071                    	; 1501              }
4072                    	; 1502          entp = &sdrdbuf[0x01be] ;
4073                    	; 1503          for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
4074                    	; 1504              {
4075                    	; 1505              if (sdtestflg)
4076                    	; 1506                  {
4077                    	; 1507                  printf("EBR partition entry %d: ", partidx);
4078                    	; 1508                  } /* sdtestflg */
4079                    	; 1509              enttype = sdmbrentry(entp);
4080                    	; 1510              if (enttype == -1) /* read error */
4081                    	; 1511                   return;
4082                    	; 1512              else if (enttype == PARTZRO) /* empty partition entry */
4083                    	; 1513                  {
4084                    	; 1514                  if (sdtestflg)
4085                    	; 1515                      {
4086                    	; 1516                      /* if compiled as test program show also empty partitions */
4087                    	; 1517                      printf("Empty partition entry\n");
4088                    	; 1518                      } /* sdtestflg */
4089                    	; 1519                  else
4090                    	; 1520                      break;
4091                    	; 1521                  }
4092                    	; 1522              else if (enttype == PARTEBR) /* next chained EBR */
4093                    	; 1523                  {
4094                    	; 1524                  if (sdtestflg)
4095                    	; 1525                      {
   0                    	; 1526                      printf("EBR chain\n");
   1                    	; 1527                      } /* sdtestflg */
   2                    	; 1528                  /* follow the EBR chain */
   3                    	; 1529                  for (chainidx = 0;
   4                    	; 1530                      ebrnext && (chainidx < 16) && (partdsk < 16);
   5                    	; 1531                      chainidx++)
   6                    	; 1532                      {
   7                    	; 1533                      /* ugly hack to stop reading the same sector */
   8                    	; 1534                      if (ebrnext == curblkno)
   9                    	; 1535                           break;
  10                    	; 1536                      if (sdread(sdrdbuf, ebrnext))
  11                    	; 1537                          {
  12                    	; 1538                          curblkno = ebrnext;
  13                    	; 1539                          curblkok = YES;
  14                    	; 1540                          }
  15                    	; 1541                      else
  16                    	; 1542                          {
  17                    	; 1543                          if (sdtestflg)
  18                    	; 1544                              {
  19                    	; 1545                              printf("  can't read %s sector %lu\n", mbrebr, sector);
  20                    	; 1546                              } /* sdtestflg */
  21                    	; 1547                          return;
  22                    	; 1548                          }
  23                    	; 1549                      entp = &sdrdbuf[0x01be] ;
  24                    	; 1550                      for (cpartidx = 1;
  25                    	; 1551                          (cpartidx <= 4) && (partdsk < 16);
  26                    	; 1552                          cpartidx++, entp += 16)
  27                    	; 1553                          {
  28                    	; 1554                          if (sdtestflg)
  29                    	; 1555                              {
  30                    	; 1556                              printf("EBR chained  partition entry %d: ",
  31                    	; 1557                                   cpartidx);
  32                    	; 1558                              } /* sdtestflg */
  33                    	; 1559                          enttype = sdmbrentry(entp);
  34                    	; 1560                          if (enttype == -1) /* read error */
  35                    	; 1561                              return;
  36                    	; 1562                          }
  37                    	; 1563                      }
  38                    	; 1564                  }
  39                    	; 1565              }
  40                    	; 1566          }
  41                    	; 1567      }
  42                    	; 1568  
  43                    	; 1569  /* Test init, read and partitions on SD card over the SPI interface
  44                    	; 1570   *
  45                    	; 1571   */
  46                    	; 1572  int main()
  47                    	; 1573      {
  48                    	; 1574      char txtin[10];
  49                    	; 1575      int cmdin;
  50                    	; 1576      int idx;
  51                    	; 1577      int cmpidx;
  52                    	; 1578      unsigned char *cmpptr;
  53                    	; 1579      int inlength;
  54                    	; 1580      unsigned long blockno;
  55                    	; 1581  
  56                    	; 1582      blockno = 0;
  57                    	; 1583      curblkno = 0;
  58                    	; 1584      curblkok = NO;
  59                    	; 1585      sdinitok = NO; /* SD card not initialized yet */
  60                    	; 1586  
  61                    	; 1587      printf(PRGNAME);
  62                    	; 1588      printf(VERSION);
  63                    	; 1589      printf(builddate);
  64                    	; 1590      printf("\n");
  65                    	; 1591      while (YES) /* forever (until Ctrl-C) */
  66                    	; 1592          {
  67                    	; 1593          printf("cmd (? for help): ");
  68                    	; 1594  
  69                    	; 1595          cmdin = getchar();
  70                    	; 1596          switch (cmdin)
  71                    	; 1597              {
  72                    	; 1598              case '?':
  73                    	; 1599                  printf(" ? - help\n");
  74                    	; 1600                  printf(PRGNAME);
  75                    	; 1601                  printf(VERSION);
  76                    	; 1602                  printf(builddate);
  77                    	; 1603                  printf("\nCommands:\n");
  78                    	; 1604                  printf("  ? - help\n");
  79                    	; 1605                  printf("  b - boot from SD card\n");
  80                    	; 1606                  printf("  d - debug on/off\n");
  81                    	; 1607                  printf("  i - initialize SD card\n");
  82                    	; 1608                  printf("  l - print partition layout\n");
  83                    	; 1609                  printf("  n - set/show block #N to read\n");
  84                    	; 1610                  printf("  p - print block last read/to write\n");
  85                    	; 1611                  printf("  r - read block #N\n");
  86                    	; 1612                  printf("  s - print SD registers\n");
  87                    	; 1613                  printf("  t - test probe SD card\n");
  88                    	; 1614                  printf("  u - upload program with Xmodem\n");
  89                    	; 1615                  printf("  w - read block #N\n");
  90                    	; 1616                  printf("  Ctrl-C to reload monitor.\n");
  91                    	; 1617                  break;
  92                    	; 1618              case 'b':
  93                    	; 1619                  printf(" d - boot from SD card - ");
  94                    	; 1620                  printf("implementation ongoing\n");
  95                    	; 1621                  break;
  96                    	; 1622              case 'd':
  97                    	; 1623                  printf(" d - toggle debug flag - ");
  98                    	; 1624                  if (sdtestflg)
  99                    	; 1625                      {
 100                    	; 1626                      sdtestflg = NO;
 101                    	; 1627                      printf("OFF\n");
 102                    	; 1628                      }
 103                    	; 1629                  else
 104                    	; 1630                      {
 105                    	; 1631                      sdtestflg = YES;
 106                    	; 1632                      printf("ON\n");
 107                    	; 1633                      }
 108                    	; 1634                  break;
 109                    	; 1635              case 'i':
 110                    	; 1636                  printf(" i - initialize SD card");
 111                    	; 1637                  if (sdinit())
 112                    	; 1638                      printf(" - ok\n");
 113                    	; 1639                  else
 114                    	; 1640                      printf(" - not inserted or faulty\n");
 115                    	; 1641                  break;
 116                    	; 1642              case 'l':
 117                    	; 1643                  printf(" l - print partition layout\n");
 118                    	; 1644                  if (!sdprobe())
 119                    	; 1645                      {
 120                    	; 1646                      printf(" - SD not initialized or inserted or faulty\n");
 121                    	; 1647                      break;
 122                    	; 1648                      }
 123                    	; 1649                  ebrrecidx = 0;
 124    4964  210000    		ld	hl,0
 125    4967  221600    		ld	(_ebrrecidx),hl
 126    496A  220E00    		ld	(_partdsk),hl
 127                    	; 1650                  partdsk = 0;
 128                    	; 1651                  memset(dskmap, 0, sizeof dskmap);
 129    496D  210002    		ld	hl,512
 130    4970  E5        		push	hl
 131    4971  210000    		ld	hl,0
 132    4974  E5        		push	hl
 133    4975  215002    		ld	hl,_dskmap
 134    4978  CD0000    		call	_memset
 135    497B  F1        		pop	af
 136    497C  F1        		pop	af
 137                    	; 1652                  sdmbrpart(0);
 138    497D  212E45    		ld	hl,L212+3
 139    4980  46        		ld	b,(hl)
 140    4981  2B        		dec	hl
 141    4982  4E        		ld	c,(hl)
 142    4983  C5        		push	bc
 143    4984  2B        		dec	hl
 144    4985  46        		ld	b,(hl)
 145    4986  2B        		dec	hl
 146    4987  4E        		ld	c,(hl)
 147    4988  C5        		push	bc
 148    4989  E1        		pop	hl
 149    498A  CD853E    		call	_sdmbrpart
 150    498D  F1        		pop	af
 151                    	; 1653                  printf("      Disk partition sectors on SD card\n");
 152    498E  212F45    		ld	hl,L5523
 153    4991  CD0000    		call	_printf
 154                    	; 1654                  printf("       MBR disk identifier: 0x%02x%02x%02x%02x\n",
 155                    	; 1655                         dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
 156    4994  3A4C02    		ld	a,(_dsksign)
 157    4997  4F        		ld	c,a
 158    4998  97        		sub	a
 159    4999  47        		ld	b,a
 160    499A  C5        		push	bc
 161    499B  3A4D02    		ld	a,(_dsksign+1)
 162    499E  4F        		ld	c,a
 163    499F  97        		sub	a
 164    49A0  47        		ld	b,a
 165    49A1  C5        		push	bc
 166    49A2  3A4E02    		ld	a,(_dsksign+2)
 167    49A5  4F        		ld	c,a
 168    49A6  97        		sub	a
 169    49A7  47        		ld	b,a
 170    49A8  C5        		push	bc
 171    49A9  3A4F02    		ld	a,(_dsksign+3)
 172    49AC  4F        		ld	c,a
 173    49AD  97        		sub	a
 174    49AE  47        		ld	b,a
 175    49AF  C5        		push	bc
 176    49B0  215845    		ld	hl,L5623
 177    49B3  CD0000    		call	_printf
 178    49B6  F1        		pop	af
 179    49B7  F1        		pop	af
 180    49B8  F1        		pop	af
 181    49B9  F1        		pop	af
 182                    	; 1656                  printf(" Disk     Start      End     Size Part Type Id\n");
 183    49BA  218845    		ld	hl,L5723
 184    49BD  CD0000    		call	_printf
 185                    	; 1657                  printf(" ----     -----      ---     ---- ---- ---- --\n");
 186    49C0  21B845    		ld	hl,L5033
 187    49C3  CD0000    		call	_printf
 188                    	; 1658                  for (idx = 0; idx < 16; idx++)
 189    49C6  DD36EC00  		ld	(ix-20),0
 190    49CA  DD36ED00  		ld	(ix-19),0
 191                    	L1536:
 192    49CE  DD7EEC    		ld	a,(ix-20)
 193    49D1  D610      		sub	16
 194    49D3  DD7EED    		ld	a,(ix-19)
 195    49D6  DE00      		sbc	a,0
 196    49D8  F26B48    		jp	p,L1716
 197                    	; 1659                      {
 198                    	; 1660                      if (dskmap[idx].dskletter)
 199    49DB  DD6EEC    		ld	l,(ix-20)
 200    49DE  DD66ED    		ld	h,(ix-19)
 201    49E1  E5        		push	hl
 202    49E2  212000    		ld	hl,32
 203    49E5  E5        		push	hl
 204    49E6  CD0000    		call	c.imul
 205    49E9  E1        		pop	hl
 206    49EA  015102    		ld	bc,_dskmap+1
 207    49ED  09        		add	hl,bc
 208    49EE  7E        		ld	a,(hl)
 209    49EF  B7        		or	a
 210    49F0  CAD84A    		jp	z,L1736
 211                    	; 1661                          {
 212                    	; 1662                          printf("%2d (%c)%c", dskmap[idx].dskletter - 'A' + 1,
 213                    	; 1663                                 dskmap[idx].dskletter,
 214                    	; 1664                                 dskmap[idx].bootable ? '*' : ' ');
 215    49F3  DD6EEC    		ld	l,(ix-20)
 216    49F6  DD66ED    		ld	h,(ix-19)
 217    49F9  E5        		push	hl
 218    49FA  212000    		ld	hl,32
 219    49FD  E5        		push	hl
 220    49FE  CD0000    		call	c.imul
 221    4A01  E1        		pop	hl
 222    4A02  015202    		ld	bc,_dskmap+2
 223    4A05  09        		add	hl,bc
 224    4A06  7E        		ld	a,(hl)
 225    4A07  23        		inc	hl
 226    4A08  B6        		or	(hl)
 227    4A09  2805      		jr	z,L612
 228    4A0B  012A00    		ld	bc,42
 229    4A0E  1803      		jr	L022
 230                    	L612:
 231    4A10  012000    		ld	bc,32
 232                    	L022:
 233    4A13  C5        		push	bc
 234    4A14  DD6EEC    		ld	l,(ix-20)
 235    4A17  DD66ED    		ld	h,(ix-19)
 236    4A1A  E5        		push	hl
 237    4A1B  212000    		ld	hl,32
 238    4A1E  E5        		push	hl
 239    4A1F  CD0000    		call	c.imul
 240    4A22  E1        		pop	hl
 241    4A23  015102    		ld	bc,_dskmap+1
 242    4A26  09        		add	hl,bc
 243    4A27  4E        		ld	c,(hl)
 244    4A28  97        		sub	a
 245    4A29  47        		ld	b,a
 246    4A2A  C5        		push	bc
 247    4A2B  DD6EEC    		ld	l,(ix-20)
 248    4A2E  DD66ED    		ld	h,(ix-19)
 249    4A31  E5        		push	hl
 250    4A32  212000    		ld	hl,32
 251    4A35  E5        		push	hl
 252    4A36  CD0000    		call	c.imul
 253    4A39  E1        		pop	hl
 254    4A3A  015102    		ld	bc,_dskmap+1
 255    4A3D  09        		add	hl,bc
 256    4A3E  6E        		ld	l,(hl)
 257    4A3F  97        		sub	a
 258    4A40  67        		ld	h,a
 259    4A41  01C0FF    		ld	bc,65472
 260    4A44  09        		add	hl,bc
 261    4A45  E5        		push	hl
 262    4A46  21E845    		ld	hl,L5133
 263    4A49  CD0000    		call	_printf
 264    4A4C  F1        		pop	af
 265    4A4D  F1        		pop	af
 266    4A4E  F1        		pop	af
 267                    	; 1665                          printf("%8lu %8lu %8lu ",
 268                    	; 1666                                 dskmap[idx].dskstart, dskmap[idx].dskend,
 269                    	; 1667                                 dskmap[idx].dsksize);
 270    4A4F  DD6EEC    		ld	l,(ix-20)
 271    4A52  DD66ED    		ld	h,(ix-19)
 272    4A55  E5        		push	hl
 273    4A56  212000    		ld	hl,32
 274    4A59  E5        		push	hl
 275    4A5A  CD0000    		call	c.imul
 276    4A5D  E1        		pop	hl
 277    4A5E  015C02    		ld	bc,_dskmap+12
 278    4A61  09        		add	hl,bc
 279    4A62  23        		inc	hl
 280    4A63  23        		inc	hl
 281    4A64  4E        		ld	c,(hl)
 282    4A65  23        		inc	hl
 283    4A66  46        		ld	b,(hl)
 284    4A67  C5        		push	bc
 285    4A68  2B        		dec	hl
 286    4A69  2B        		dec	hl
 287    4A6A  2B        		dec	hl
 288    4A6B  4E        		ld	c,(hl)
 289    4A6C  23        		inc	hl
 290    4A6D  46        		ld	b,(hl)
 291    4A6E  C5        		push	bc
 292    4A6F  DD6EEC    		ld	l,(ix-20)
 293    4A72  DD66ED    		ld	h,(ix-19)
 294    4A75  E5        		push	hl
 295    4A76  212000    		ld	hl,32
 296    4A79  E5        		push	hl
 297    4A7A  CD0000    		call	c.imul
 298    4A7D  E1        		pop	hl
 299    4A7E  015802    		ld	bc,_dskmap+8
 300    4A81  09        		add	hl,bc
 301    4A82  23        		inc	hl
 302    4A83  23        		inc	hl
 303    4A84  4E        		ld	c,(hl)
 304    4A85  23        		inc	hl
 305    4A86  46        		ld	b,(hl)
 306    4A87  C5        		push	bc
 307    4A88  2B        		dec	hl
 308    4A89  2B        		dec	hl
 309    4A8A  2B        		dec	hl
 310    4A8B  4E        		ld	c,(hl)
 311    4A8C  23        		inc	hl
 312    4A8D  46        		ld	b,(hl)
 313    4A8E  C5        		push	bc
 314    4A8F  DD6EEC    		ld	l,(ix-20)
 315    4A92  DD66ED    		ld	h,(ix-19)
 316    4A95  E5        		push	hl
 317    4A96  212000    		ld	hl,32
 318    4A99  E5        		push	hl
 319    4A9A  CD0000    		call	c.imul
 320    4A9D  E1        		pop	hl
 321    4A9E  015402    		ld	bc,_dskmap+4
 322    4AA1  09        		add	hl,bc
 323    4AA2  23        		inc	hl
 324    4AA3  23        		inc	hl
 325    4AA4  4E        		ld	c,(hl)
 326    4AA5  23        		inc	hl
 327    4AA6  46        		ld	b,(hl)
 328    4AA7  C5        		push	bc
 329    4AA8  2B        		dec	hl
 330    4AA9  2B        		dec	hl
 331    4AAA  2B        		dec	hl
 332    4AAB  4E        		ld	c,(hl)
 333    4AAC  23        		inc	hl
 334    4AAD  46        		ld	b,(hl)
 335    4AAE  C5        		push	bc
 336    4AAF  21F345    		ld	hl,L5233
 337    4AB2  CD0000    		call	_printf
 338    4AB5  210C00    		ld	hl,12
 339    4AB8  39        		add	hl,sp
 340    4AB9  F9        		ld	sp,hl
 341                    	; 1668                          if (dskmap[idx].partype == EBRCONT)
 342    4ABA  DD6EEC    		ld	l,(ix-20)
 343    4ABD  DD66ED    		ld	h,(ix-19)
 344    4AC0  E5        		push	hl
 345    4AC1  212000    		ld	hl,32
 346    4AC4  E5        		push	hl
 347    4AC5  CD0000    		call	c.imul
 348    4AC8  E1        		pop	hl
 349    4AC9  015002    		ld	bc,_dskmap
 350    4ACC  09        		add	hl,bc
 351    4ACD  7E        		ld	a,(hl)
 352    4ACE  FE14      		cp	20
 353    4AD0  2011      		jr	nz,L1246
 354                    	; 1669                              {
 355                    	; 1670                              printf(" EBR container\n");
 356    4AD2  210346    		ld	hl,L5333
 357    4AD5  CD0000    		call	_printf
 358                    	; 1671                              }
 359                    	; 1672                          else
 360                    	L1736:
 361    4AD8  DD34EC    		inc	(ix-20)
 362    4ADB  2003      		jr	nz,L412
 363    4ADD  DD34ED    		inc	(ix-19)
 364                    	L412:
 365    4AE0  C3CE49    		jp	L1536
 366                    	L1246:
 367                    	; 1673                              {
 368                    	; 1674                              if (dskmap[idx].partype == PARTGPT)
 369    4AE3  DD6EEC    		ld	l,(ix-20)
 370    4AE6  DD66ED    		ld	h,(ix-19)
 371    4AE9  E5        		push	hl
 372    4AEA  212000    		ld	hl,32
 373    4AED  E5        		push	hl
 374    4AEE  CD0000    		call	c.imul
 375    4AF1  E1        		pop	hl
 376    4AF2  015002    		ld	bc,_dskmap
 377    4AF5  09        		add	hl,bc
 378    4AF6  7E        		ld	a,(hl)
 379    4AF7  FE03      		cp	3
 380    4AF9  C28D4B    		jp	nz,L1446
 381                    	; 1675                                  {
 382                    	; 1676                                  printf(" GPT ");
 383    4AFC  211346    		ld	hl,L5433
 384    4AFF  CD0000    		call	_printf
 385                    	; 1677                                  /*if (memcmp(dskmap[idx].dsktype, gptcpm, 16) == 0)
 386                    	; 1678                                    not really working as I expected ? */
 387                    	; 1679                                  cmpptr = dskmap[idx].dsktype;
 388    4B02  DD6EEC    		ld	l,(ix-20)
 389    4B05  DD66ED    		ld	h,(ix-19)
 390    4B08  E5        		push	hl
 391    4B09  212000    		ld	hl,32
 392    4B0C  E5        		push	hl
 393    4B0D  CD0000    		call	c.imul
 394    4B10  E1        		pop	hl
 395    4B11  016002    		ld	bc,_dskmap+16
 396    4B14  09        		add	hl,bc
 397    4B15  DD75E8    		ld	(ix-24),l
 398    4B18  DD74E9    		ld	(ix-23),h
 399                    	; 1680                                  for (cmpidx = 0; cmpidx < 16; cmpidx++, cmpptr++)
 400    4B1B  DD36EA00  		ld	(ix-22),0
 401    4B1F  DD36EB00  		ld	(ix-21),0
 402                    	L1546:
 403    4B23  DD7EEA    		ld	a,(ix-22)
 404    4B26  D610      		sub	16
 405    4B28  DD7EEB    		ld	a,(ix-21)
 406    4B2B  DE00      		sbc	a,0
 407    4B2D  F2584B    		jp	p,L1646
 408                    	; 1681                                      {
 409                    	; 1682                                      if (gptcpm[cmpidx] != *cmpptr)
 410    4B30  215300    		ld	hl,_gptcpm
 411    4B33  DD4EEA    		ld	c,(ix-22)
 412    4B36  DD46EB    		ld	b,(ix-21)
 413    4B39  09        		add	hl,bc
 414    4B3A  DD4EE8    		ld	c,(ix-24)
 415    4B3D  DD46E9    		ld	b,(ix-23)
 416    4B40  0A        		ld	a,(bc)
 417    4B41  4F        		ld	c,a
 418    4B42  7E        		ld	a,(hl)
 419    4B43  B9        		cp	c
 420    4B44  2012      		jr	nz,L1646
 421                    	; 1683                                          break;
 422                    	L1746:
 423    4B46  DD34EA    		inc	(ix-22)
 424    4B49  2003      		jr	nz,L222
 425    4B4B  DD34EB    		inc	(ix-21)
 426                    	L222:
 427    4B4E  DD34E8    		inc	(ix-24)
 428    4B51  2003      		jr	nz,L422
 429    4B53  DD34E9    		inc	(ix-23)
 430                    	L422:
 431    4B56  18CB      		jr	L1546
 432                    	L1646:
 433                    	; 1684                                      }
 434                    	; 1685                                  if (cmpidx == 16)
 435    4B58  DD7EEA    		ld	a,(ix-22)
 436    4B5B  FE10      		cp	16
 437    4B5D  2005      		jr	nz,L622
 438    4B5F  DD7EEB    		ld	a,(ix-21)
 439    4B62  FE00      		cp	0
 440                    	L622:
 441    4B64  2008      		jr	nz,L1256
 442                    	; 1686                                      printf("CP/M ");
 443    4B66  211946    		ld	hl,L5533
 444    4B69  CD0000    		call	_printf
 445                    	; 1687                                  else
 446    4B6C  1806      		jr	L1356
 447                    	L1256:
 448                    	; 1688                                      printf(" ??  ");
 449    4B6E  211F46    		ld	hl,L5633
 450    4B71  CD0000    		call	_printf
 451                    	L1356:
 452                    	; 1689                                  prtguid(dskmap[idx].dsktype);
 453    4B74  DD6EEC    		ld	l,(ix-20)
 454    4B77  DD66ED    		ld	h,(ix-19)
 455    4B7A  E5        		push	hl
 456    4B7B  212000    		ld	hl,32
 457    4B7E  E5        		push	hl
 458    4B7F  CD0000    		call	c.imul
 459    4B82  E1        		pop	hl
 460    4B83  016002    		ld	bc,_dskmap+16
 461    4B86  09        		add	hl,bc
 462    4B87  CD6629    		call	_prtguid
 463                    	; 1690                                  }
 464                    	; 1691                              else
 465    4B8A  C31D4C    		jp	L1456
 466                    	L1446:
 467                    	; 1692                                  {
 468                    	; 1693                                  if (dskmap[idx].partype == PARTEBR)
 469    4B8D  DD6EEC    		ld	l,(ix-20)
 470    4B90  DD66ED    		ld	h,(ix-19)
 471    4B93  E5        		push	hl
 472    4B94  212000    		ld	hl,32
 473    4B97  E5        		push	hl
 474    4B98  CD0000    		call	c.imul
 475    4B9B  E1        		pop	hl
 476    4B9C  015002    		ld	bc,_dskmap
 477    4B9F  09        		add	hl,bc
 478    4BA0  7E        		ld	a,(hl)
 479    4BA1  FE02      		cp	2
 480    4BA3  2008      		jr	nz,L1556
 481                    	; 1694                                      printf(" EBR ");
 482    4BA5  212546    		ld	hl,L5733
 483    4BA8  CD0000    		call	_printf
 484                    	; 1695                                  else
 485    4BAB  1806      		jr	L1656
 486                    	L1556:
 487                    	; 1696                                      printf(" MBR ");
 488    4BAD  212B46    		ld	hl,L5043
 489    4BB0  CD0000    		call	_printf
 490                    	L1656:
 491                    	; 1697                                  if (dskmap[idx].dsktype[0] == mbrcpm)
 492    4BB3  DD6EEC    		ld	l,(ix-20)
 493    4BB6  DD66ED    		ld	h,(ix-19)
 494    4BB9  E5        		push	hl
 495    4BBA  212000    		ld	hl,32
 496    4BBD  E5        		push	hl
 497    4BBE  CD0000    		call	c.imul
 498    4BC1  E1        		pop	hl
 499    4BC2  016002    		ld	bc,_dskmap+16
 500    4BC5  09        		add	hl,bc
 501    4BC6  3A6300    		ld	a,(_mbrcpm)
 502    4BC9  4F        		ld	c,a
 503    4BCA  7E        		ld	a,(hl)
 504    4BCB  B9        		cp	c
 505    4BCC  2008      		jr	nz,L1756
 506                    	; 1698                                      printf("CP/M ");
 507    4BCE  213146    		ld	hl,L5143
 508    4BD1  CD0000    		call	_printf
 509                    	; 1699                                  else if (dskmap[idx].dsktype[0] == mbrexcode)
 510    4BD4  1829      		jr	L1066
 511                    	L1756:
 512    4BD6  DD6EEC    		ld	l,(ix-20)
 513    4BD9  DD66ED    		ld	h,(ix-19)
 514    4BDC  E5        		push	hl
 515    4BDD  212000    		ld	hl,32
 516    4BE0  E5        		push	hl
 517    4BE1  CD0000    		call	c.imul
 518    4BE4  E1        		pop	hl
 519    4BE5  016002    		ld	bc,_dskmap+16
 520    4BE8  09        		add	hl,bc
 521    4BE9  3A6400    		ld	a,(_mbrexcode)
 522    4BEC  4F        		ld	c,a
 523    4BED  7E        		ld	a,(hl)
 524    4BEE  B9        		cp	c
 525    4BEF  2008      		jr	nz,L1166
 526                    	; 1700                                      printf("Code ");
 527    4BF1  213746    		ld	hl,L5243
 528    4BF4  CD0000    		call	_printf
 529                    	; 1701                                  else
 530    4BF7  1806      		jr	L1066
 531                    	L1166:
 532                    	; 1702                                      printf(" ??  ");
 533    4BF9  213D46    		ld	hl,L5343
 534    4BFC  CD0000    		call	_printf
 535                    	L1066:
 536                    	; 1703                                  printf("0x%02x", dskmap[idx].dsktype[0]);
 537    4BFF  DD6EEC    		ld	l,(ix-20)
 538    4C02  DD66ED    		ld	h,(ix-19)
 539    4C05  E5        		push	hl
 540    4C06  212000    		ld	hl,32
 541    4C09  E5        		push	hl
 542    4C0A  CD0000    		call	c.imul
 543    4C0D  E1        		pop	hl
 544    4C0E  016002    		ld	bc,_dskmap+16
 545    4C11  09        		add	hl,bc
 546    4C12  4E        		ld	c,(hl)
 547    4C13  97        		sub	a
 548    4C14  47        		ld	b,a
 549    4C15  C5        		push	bc
 550    4C16  214346    		ld	hl,L5443
 551    4C19  CD0000    		call	_printf
 552    4C1C  F1        		pop	af
 553                    	L1456:
 554                    	; 1704                                  }
 555                    	; 1705                              printf("\n");
 556    4C1D  214A46    		ld	hl,L5543
 557    4C20  CD0000    		call	_printf
 558    4C23  C3D84A    		jp	L1736
 559                    	L1366:
 560                    	; 1706                              }
 561                    	; 1707                          }
 562                    	; 1708                      }
 563                    	; 1709                  break;
 564                    	; 1710              case 'n':
 565                    	; 1711                  printf(" n - block number: ");
 566    4C26  214C46    		ld	hl,L5643
 567    4C29  CD0000    		call	_printf
 568                    	; 1712                  if (getkline(txtin, sizeof txtin))
 569    4C2C  210A00    		ld	hl,10
 570    4C2F  E5        		push	hl
 571    4C30  DDE5      		push	ix
 572    4C32  C1        		pop	bc
 573    4C33  21F0FF    		ld	hl,65520
 574    4C36  09        		add	hl,bc
 575    4C37  CD0000    		call	_getkline
 576    4C3A  F1        		pop	af
 577    4C3B  79        		ld	a,c
 578    4C3C  B0        		or	b
 579    4C3D  281A      		jr	z,L1466
 580                    	; 1713                      sscanf(txtin, "%lu", &blockno);
 581    4C3F  DDE5      		push	ix
 582    4C41  C1        		pop	bc
 583    4C42  21E2FF    		ld	hl,65506
 584    4C45  09        		add	hl,bc
 585    4C46  E5        		push	hl
 586    4C47  216046    		ld	hl,L5743
 587    4C4A  E5        		push	hl
 588    4C4B  DDE5      		push	ix
 589    4C4D  C1        		pop	bc
 590    4C4E  21F0FF    		ld	hl,65520
 591    4C51  09        		add	hl,bc
 592    4C52  CD0000    		call	_sscanf
 593    4C55  F1        		pop	af
 594    4C56  F1        		pop	af
 595                    	; 1714                  else
 596    4C57  1816      		jr	L1566
 597                    	L1466:
 598                    	; 1715                      printf("%lu", blockno);
 599    4C59  DD66E5    		ld	h,(ix-27)
 600    4C5C  DD6EE4    		ld	l,(ix-28)
 601    4C5F  E5        		push	hl
 602    4C60  DD66E3    		ld	h,(ix-29)
 603    4C63  DD6EE2    		ld	l,(ix-30)
 604    4C66  E5        		push	hl
 605    4C67  216446    		ld	hl,L5053
 606    4C6A  CD0000    		call	_printf
 607    4C6D  F1        		pop	af
 608    4C6E  F1        		pop	af
 609                    	L1566:
 610                    	; 1716                  printf("\n");
 611    4C6F  216846    		ld	hl,L5153
 612    4C72  CD0000    		call	_printf
 613                    	; 1717                  break;
 614    4C75  C36B48    		jp	L1716
 615                    	L1666:
 616                    	; 1718              case 'p':
 617                    	; 1719                  printf(" p - print data block %lu\n", curblkno);
 618    4C78  210500    		ld	hl,_curblkno+3
 619    4C7B  46        		ld	b,(hl)
 620    4C7C  2B        		dec	hl
 621    4C7D  4E        		ld	c,(hl)
 622    4C7E  C5        		push	bc
 623    4C7F  2B        		dec	hl
 624    4C80  46        		ld	b,(hl)
 625    4C81  2B        		dec	hl
 626    4C82  4E        		ld	c,(hl)
 627    4C83  C5        		push	bc
 628    4C84  216A46    		ld	hl,L5253
 629    4C87  CD0000    		call	_printf
 630    4C8A  F1        		pop	af
 631    4C8B  F1        		pop	af
 632                    	; 1720                  sddatprt(sdrdbuf);
 633    4C8C  214C00    		ld	hl,_sdrdbuf
 634    4C8F  CD8D27    		call	_sddatprt
 635                    	; 1721                  break;
 636    4C92  C36B48    		jp	L1716
 637                    	L1766:
 638                    	; 1722              case 'r':
 639                    	; 1723                  printf(" r - read block");
 640    4C95  218546    		ld	hl,L5353
 641    4C98  CD0000    		call	_printf
 642                    	; 1724                  if (!sdprobe())
 643    4C9B  CD0910    		call	_sdprobe
 644    4C9E  79        		ld	a,c
 645    4C9F  B0        		or	b
 646    4CA0  2009      		jr	nz,L1076
 647                    	; 1725                      {
 648                    	; 1726                      printf(" - not initialized or inserted or faulty\n");
 649    4CA2  219546    		ld	hl,L5453
 650    4CA5  CD0000    		call	_printf
 651                    	; 1727                      break;
 652    4CA8  C36B48    		jp	L1716
 653                    	L1076:
 654                    	; 1728                      }
 655                    	; 1729                  if (sdread(sdrdbuf, blockno))
 656    4CAB  DD66E5    		ld	h,(ix-27)
 657    4CAE  DD6EE4    		ld	l,(ix-28)
 658    4CB1  E5        		push	hl
 659    4CB2  DD66E3    		ld	h,(ix-29)
 660    4CB5  DD6EE2    		ld	l,(ix-30)
 661    4CB8  E5        		push	hl
 662    4CB9  214C00    		ld	hl,_sdrdbuf
 663    4CBC  CDE120    		call	_sdread
 664    4CBF  F1        		pop	af
 665    4CC0  F1        		pop	af
 666    4CC1  79        		ld	a,c
 667    4CC2  B0        		or	b
 668    4CC3  2819      		jr	z,L1176
 669                    	; 1730                      {
 670                    	; 1731                      printf(" - ok\n");
 671    4CC5  21BF46    		ld	hl,L5553
 672    4CC8  CD0000    		call	_printf
 673                    	; 1732                      curblkno = blockno;
 674    4CCB  210200    		ld	hl,_curblkno
 675    4CCE  E5        		push	hl
 676    4CCF  DDE5      		push	ix
 677    4CD1  C1        		pop	bc
 678    4CD2  21E2FF    		ld	hl,65506
 679    4CD5  09        		add	hl,bc
 680    4CD6  E5        		push	hl
 681    4CD7  CD0000    		call	c.mvl
 682    4CDA  F1        		pop	af
 683                    	; 1733                      }
 684                    	; 1734                  else
 685    4CDB  C36B48    		jp	L1716
 686                    	L1176:
 687                    	; 1735                      printf(" - read error\n");
 688    4CDE  21C646    		ld	hl,L5653
 689    4CE1  CD0000    		call	_printf
 690    4CE4  C36B48    		jp	L1716
 691                    	L1376:
 692                    	; 1736                  break;
 693                    	; 1737              case 's':
 694                    	; 1738                  printf(" s - print SD registers\n");
 695    4CE7  21D546    		ld	hl,L5753
 696    4CEA  CD0000    		call	_printf
 697                    	; 1739                  sdprtreg();
 698    4CED  CD2B17    		call	_sdprtreg
 699                    	; 1740                  break;
 700    4CF0  C36B48    		jp	L1716
 701                    	L1476:
 702                    	; 1741              case 't':
 703                    	; 1742                  printf(" t - test if card inserted\n");
 704    4CF3  21EE46    		ld	hl,L5063
 705    4CF6  CD0000    		call	_printf
 706                    	; 1743                  if (sdprobe())
 707    4CF9  CD0910    		call	_sdprobe
 708    4CFC  79        		ld	a,c
 709    4CFD  B0        		or	b
 710    4CFE  2809      		jr	z,L1576
 711                    	; 1744                      printf(" - ok\n");
 712    4D00  210A47    		ld	hl,L5163
 713    4D03  CD0000    		call	_printf
 714                    	; 1745                  else
 715    4D06  C36B48    		jp	L1716
 716                    	L1576:
 717                    	; 1746                      printf(" - not initialized or inserted or faulty\n");
 718    4D09  211147    		ld	hl,L5263
 719    4D0C  CD0000    		call	_printf
 720    4D0F  C36B48    		jp	L1716
 721                    	L1776:
 722                    	; 1747                  break;
 723                    	; 1748              case 'u':
 724                    	; 1749                  printf(" u - upload with Xmodem - ");
 725    4D12  213B47    		ld	hl,L5363
 726    4D15  CD0000    		call	_printf
 727                    	; 1750                  printf("implementation ongoing\n");
 728    4D18  215647    		ld	hl,L5463
 729    4D1B  CD0000    		call	_printf
 730                    	; 1751                  break;
 731    4D1E  C36B48    		jp	L1716
 732                    	L1007:
 733                    	; 1752              case 'w':
 734                    	; 1753                  printf(" w - write block");
 735    4D21  216E47    		ld	hl,L5563
 736    4D24  CD0000    		call	_printf
 737                    	; 1754                  if (!sdprobe())
 738    4D27  CD0910    		call	_sdprobe
 739    4D2A  79        		ld	a,c
 740    4D2B  B0        		or	b
 741    4D2C  2006      		jr	nz,L1107
 742                    	; 1755                      printf(" - not initialized or inserted or faulty\n");
 743    4D2E  217F47    		ld	hl,L5663
 744    4D31  CD0000    		call	_printf
 745                    	L1107:
 746                    	; 1756                  if (sdwrite(sdrdbuf, blockno))
 747    4D34  DD66E5    		ld	h,(ix-27)
 748    4D37  DD6EE4    		ld	l,(ix-28)
 749    4D3A  E5        		push	hl
 750    4D3B  DD66E3    		ld	h,(ix-29)
 751    4D3E  DD6EE2    		ld	l,(ix-30)
 752    4D41  E5        		push	hl
 753    4D42  214C00    		ld	hl,_sdrdbuf
 754    4D45  CD9E24    		call	_sdwrite
 755    4D48  F1        		pop	af
 756    4D49  F1        		pop	af
 757    4D4A  79        		ld	a,c
 758    4D4B  B0        		or	b
 759    4D4C  2819      		jr	z,L1207
 760                    	; 1757                      {
 761                    	; 1758                      printf(" - ok\n");
 762    4D4E  21A947    		ld	hl,L5763
 763    4D51  CD0000    		call	_printf
 764                    	; 1759                      curblkno = blockno;
 765    4D54  210200    		ld	hl,_curblkno
 766    4D57  E5        		push	hl
 767    4D58  DDE5      		push	ix
 768    4D5A  C1        		pop	bc
 769    4D5B  21E2FF    		ld	hl,65506
 770    4D5E  09        		add	hl,bc
 771    4D5F  E5        		push	hl
 772    4D60  CD0000    		call	c.mvl
 773    4D63  F1        		pop	af
 774                    	; 1760                      }
 775                    	; 1761                  else
 776    4D64  C36B48    		jp	L1716
 777                    	L1207:
 778                    	; 1762                      printf(" - write error\n");
 779    4D67  21B047    		ld	hl,L5073
 780    4D6A  CD0000    		call	_printf
 781    4D6D  C36B48    		jp	L1716
 782                    	L1407:
 783                    	; 1763                  break;
 784                    	; 1764              case 0x03: /* Ctrl-C */
 785                    	; 1765                  printf("reloading monitor from EPROM\n");
 786    4D70  21C047    		ld	hl,L5173
 787    4D73  CD0000    		call	_printf
 788                    	; 1766                  reload();
 789    4D76  CD0000    		call	_reload
 790                    	; 1767                  break; /* not really needed, will never get here */
 791    4D79  C36B48    		jp	L1716
 792                    	L1507:
 793                    	; 1768              default:
 794                    	; 1769                  printf(" invalid command\n");
 795    4D7C  21DE47    		ld	hl,L5273
 796    4D7F  CD0000    		call	_printf
 797    4D82  C36B48    		jp	L1716
 798                    	L1226:
 799                    	; 1770              }
 800                    	; 1771          }
 801    4D85  C36B48    		jp	L1716
 802                    	; 1772      }
 803                    	; 1773  
 804                    		.psect	_bss
 805                    	_sdtestflg:
 806                    		.byte	[2]
 807                    	_curblkno:
 808                    		.byte	[4]
 809                    	_blkmult:
 810                    		.byte	[4]
 811                    	_sdver2:
 812                    		.byte	[2]
 813                    	_sdinitok:
 814                    		.byte	[2]
 815                    	_partdsk:
 816                    		.byte	[2]
 817                    	_curblkok:
 818                    		.byte	[2]
 819                    	_ebrnext:
 820                    		.byte	[4]
 821                    	_ebrrecidx:
 822                    		.byte	[2]
 823                    	_ebrrecs:
 824                    		.byte	[16]
 825                    	_csdreg:
 826                    		.byte	[16]
 827                    	_cidreg:
 828                    		.byte	[16]
 829                    	_ocrreg:
 830                    		.byte	[4]
 831                    	_sdrdbuf:
 832                    		.byte	[512]
 833                    	_dsksign:
 834                    		.byte	[4]
 835                    	_dskmap:
 836                    		.byte	[512]
 837                    		.public	_sdgpthdr
 838                    		.public	_curblkno
 839                    		.external	c.ulrsh
 840                    		.external	c.rets0
 841                    		.public	_CRC16_one
 842                    		.external	c.savs0
 843                    		.external	_getchar
 844                    		.external	c.lcmp
 845                    		.public	_cmd55
 846                    		.public	_curblkok
 847                    		.public	_cmd17
 848                    		.public	_cmd16
 849                    		.public	_cmd24
 850                    		.public	_sdver2
 851                    		.external	c.r1
 852                    		.external	_spideselect
 853                    		.public	_cmd10
 854                    		.external	c.r0
 855                    		.external	_getkline
 856                    		.external	c.jtab
 857                    		.external	_printf
 858                    		.external	_ledon
 859                    		.public	_sdtestflg
 860                    		.public	_sdmbrpart
 861                    		.external	_spiselect
 862                    		.external	_memset
 863                    		.external	_memcpy
 864                    		.public	_sdinit
 865                    		.public	_gptcpm
 866                    		.public	_sdmbrentry
 867                    		.external	c.ladd
 868                    		.public	_sdwrite
 869                    		.public	_ocrreg
 870                    		.external	c.mvl
 871                    		.public	_mbrcpm
 872                    		.public	_dskmap
 873                    		.public	_prtguid
 874                    		.external	_sscanf
 875                    		.public	_blkmult
 876                    		.public	_acmd41
 877                    		.public	_partdsk
 878                    		.public	_mbrexcode
 879                    		.public	_ebrrecidx
 880                    		.public	_ebrnext
 881                    		.public	_csdreg
 882                    		.external	_reload
 883                    		.external	_putchar
 884                    		.public	_sdcommand
 885                    		.external	c.ursh
 886                    		.public	_dsksign
 887                    		.public	_sdread
 888                    		.external	_ledoff
 889                    		.external	c.rets
 890                    		.public	_CRC7_one
 891                    		.public	_sdprobe
 892                    		.external	c.savs
 893                    		.public	_cidreg
 894                    		.public	_builddate
 895                    		.public	_cmd9
 896                    		.external	c.lmul
 897                    		.public	_cmd8
 898                    		.external	c.0mvf
 899                    		.public	_sdprtreg
 900                    		.public	_sdrdbuf
 901                    		.external	c.udiv
 902                    		.external	c.imul
 903                    		.external	c.lsub
 904                    		.public	_prtgptent
 905                    		.external	c.irsh
 906                    		.external	c.umod
 907                    		.public	_ebrrecs
 908                    		.public	_sddatprt
 909                    		.public	_main
 910                    		.external	c.llsh
 911                    		.public	_sdinitok
 912                    		.external	_spiio
 913                    		.public	_cmd0
 914                    		.external	c.ilsh
 915                    		.public	_cmd58
 916                    		.end
