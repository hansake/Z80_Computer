   1                    	;    1  /*  z80sdpart.c Identify partitions on SD card.
   2                    	;    2   *
   3                    	;    3   *  Boot code for my DIY Z80 Computer. This
   4                    	;    4   *  program is compiled with Whitesmiths/COSMIC
   5                    	;    5   *  C compiler for Z80.
   6                    	;    6   *
   7                    	;    7   *  Detects the partitioning of an attached SD card.
   8                    	;    8   *
   9                    	;    9   *  You are free to use, modify, and redistribute
  10                    	;   10   *  this source code. No warranties are given.
  11                    	;   11   *  Hastily Cobbled Together 2021 and 2022
  12                    	;   12   *  by Hans-Ake Lund
  13                    	;   13   *
  14                    	;   14   */
  15                    	;   15  
  16                    	;   16  #include <std.h>
  17                    	;   17  #include "z80comp.h"
  18                    	;   18  #include "z80sd.h"
  19                    	;   19  
  20                    	;   20  struct partentry *parptr;       /* Partition map pointer */
  21                    	;   21  
  22                    	;   22  struct guidentry guidmap[16];   /* Map of GUIDs for GPT partitions */
  23                    	;   23  
  24                    	;   24  /* Detected EBR records to process */
  25                    	;   25  struct ebrentry
  26                    	;   26      {
  27                    	;   27      unsigned char ebrblk[4];
  28                    	;   28      } ebrrecs[4];
  29                    	;   29  
  30                    	;   30  unsigned char dsksign[4];      /* MBR/EBR disk signature */
  31                    	;   31  
  32                    	;   32  /* blockno 0, used to compare */
  33                    	;   33  const unsigned char blkzero[4] = {0x00, 0x00, 0x00, 0x00};
  34                    		.psect	_text
  35                    	_blkzero:
  36                    		.byte	[1]
  37                    		.byte	[1]
  38                    		.byte	[1]
  39                    		.byte	[1]
  40                    	;   34  /* blockno 1, used to increment/decrement */
  41                    	;   35  const unsigned char blkone[4] = {0x00, 0x00, 0x00, 0x01};
  42                    	_blkone:
  43                    		.byte	[1]
  44                    		.byte	[1]
  45                    		.byte	[1]
  46    0007  01        		.byte	1
  47                    	;   36  
  48                    	;   37  /* Partition identifiers
  49                    	;   38   */
  50                    	;   39  
  51                    	;   40  /* CP/M partition */
  52                    	;   41  const unsigned char mbrcpm = 0x52;
  53                    	_mbrcpm:
  54    0008  52        		.byte	82
  55                    	;   42  /* For MBR/EBR the partition type for CP/M is 0x52
  56                    	;   43   * according to: https://en.wikipedia.org/wiki/Partition_type
  57                    	;   44   */
  58                    	;   45  
  59                    	;   46  /* Z80 executable code partition */
  60                    	;   47  const unsigned char mbrexcode = 0x5f;
  61                    	_mbrexcode:
  62    0009  5F        		.byte	95
  63                    	;   48  /* My own "invention", has a special format that
  64                    	;   49   * includes number of bytes to load and a signature
  65                    	;   50   * that is a jump to the executable part
  66                    	;   51   */
  67                    	;   52  
  68                    	;   53  /* For GPT I have defined that a CP/M partition
  69                    	;   54   * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
  70                    	;   55   */
  71                    	;   56  const unsigned char gptcpm[] =
  72                    	;   57      {
  73                    	_gptcpm:
  74                    	;   58      0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
  75    000A  FD        		.byte	253
  76    000B  76        		.byte	118
  77    000C  71        		.byte	113
  78    000D  AC        		.byte	172
  79    000E  55        		.byte	85
  80    000F  8D        		.byte	141
  81    0010  FF        		.byte	255
  82    0011  4F        		.byte	79
  83                    	;   59      0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
  84    0012  86        		.byte	134
  85    0013  A5        		.byte	165
  86    0014  A3        		.byte	163
  87    0015  6D        		.byte	109
  88    0016  63        		.byte	99
  89    0017  68        		.byte	104
  90    0018  D0        		.byte	208
  91                    	;   60      };
  92    0019  CB        		.byte	203
  93                    	;   61  
  94                    	;   62  /* For GPT I have also defined that a executable partition
  95                    	;   63   * has GUID: 0185D755-3CAC-41F5-94D9-6F7D906868E8
  96                    	;   64   */
  97                    	;   65  const unsigned char gptexcode[] =
  98                    	;   66      {
  99                    	_gptexcode:
 100                    	;   67      0x55, 0xd7, 0x85, 0x01, 0xac, 0x3c, 0xf5, 0x41,
 101    001A  55        		.byte	85
 102    001B  D7        		.byte	215
 103    001C  85        		.byte	133
 104    001D  01        		.byte	1
 105    001E  AC        		.byte	172
 106    001F  3C        		.byte	60
 107    0020  F5        		.byte	245
 108    0021  41        		.byte	65
 109                    	;   68      0x94, 0xd9, 0x6f, 0x7d, 0x90, 0x68, 0x68, 0xe8
 110    0022  94        		.byte	148
 111    0023  D9        		.byte	217
 112    0024  6F        		.byte	111
 113    0025  7D        		.byte	125
 114    0026  90        		.byte	144
 115    0027  68        		.byte	104
 116    0028  68        		.byte	104
 117                    	;   69      };
 118    0029  E8        		.byte	232
 119                    	;   70  
 120                    	;   71  int ebrrecidx; /* how many EBR records that are populated */
 121                    	;   72  unsigned char ebrnext[4]; /* next chained ebr record */
 122                    	;   73  
 123                    	;   74  /* Variables
 124                    	;   75   */
 125                    	;   76  int partpar;   /* partition/disk number, 0 = disk A */
 126                    	;   77  
 127                    	;   78  unsigned long blk2ul(unsigned char*);
 128                    	;   79  
 129                    	;   80  /* Analyze and record GPT entry
 130                    	;   81   */
 131                    	;   82  int gptentry(unsigned int entryno)
 132                    	;   83      {
 133                    	_gptentry:
 134    002A  CD0000    		call	c.savs
 135    002D  21E6FF    		ld	hl,65510
 136    0030  39        		add	hl,sp
 137    0031  F9        		ld	sp,hl
 138                    	;   84      int index;
 139                    	;   85      int entryidx;
 140                    	;   86      int hasname;
 141                    	;   87      unsigned char blkno[4];
 142                    	;   88      unsigned char *rxdata;
 143                    	;   89      unsigned char *entryptr;
 144                    	;   90      unsigned char tstzero = 0;
 145    0032  DD36EB00  		ld	(ix-21),0
 146                    	;   91      unsigned long llba;
 147                    	;   92  
 148                    	;   93      ul2blk(blkno, (unsigned long)(2 + (entryno / 4)));
 149    0036  DD6E04    		ld	l,(ix+4)
 150    0039  DD6605    		ld	h,(ix+5)
 151    003C  E5        		push	hl
 152    003D  210400    		ld	hl,4
 153    0040  E5        		push	hl
 154    0041  CD0000    		call	c.udiv
 155    0044  E1        		pop	hl
 156    0045  23        		inc	hl
 157    0046  23        		inc	hl
 158    0047  4D        		ld	c,l
 159    0048  44        		ld	b,h
 160    0049  97        		sub	a
 161    004A  320000    		ld	(c.r0),a
 162    004D  320100    		ld	(c.r0+1),a
 163    0050  79        		ld	a,c
 164    0051  320200    		ld	(c.r0+2),a
 165    0054  78        		ld	a,b
 166    0055  320300    		ld	(c.r0+3),a
 167    0058  210300    		ld	hl,c.r0+3
 168    005B  46        		ld	b,(hl)
 169    005C  2B        		dec	hl
 170    005D  4E        		ld	c,(hl)
 171    005E  C5        		push	bc
 172    005F  2B        		dec	hl
 173    0060  46        		ld	b,(hl)
 174    0061  2B        		dec	hl
 175    0062  4E        		ld	c,(hl)
 176    0063  C5        		push	bc
 177    0064  DDE5      		push	ix
 178    0066  C1        		pop	bc
 179    0067  21F0FF    		ld	hl,65520
 180    006A  09        		add	hl,bc
 181    006B  CD0000    		call	_ul2blk
 182    006E  F1        		pop	af
 183    006F  F1        		pop	af
 184                    	;   94      if (!sdread(sdrdbuf, blkno))
 185    0070  DDE5      		push	ix
 186    0072  C1        		pop	bc
 187    0073  21F0FF    		ld	hl,65520
 188    0076  09        		add	hl,bc
 189    0077  E5        		push	hl
 190    0078  210000    		ld	hl,_sdrdbuf
 191    007B  CD0000    		call	_sdread
 192    007E  F1        		pop	af
 193    007F  79        		ld	a,c
 194    0080  B0        		or	b
 195    0081  2006      		jr	nz,L1
 196                    	;   95          return (NO);
 197    0083  010000    		ld	bc,0
 198    0086  C30000    		jp	c.rets
 199                    	L1:
 200                    	;   96      rxdata = sdrdbuf;
 201    0089  210000    		ld	hl,_sdrdbuf
 202    008C  DD75EE    		ld	(ix-18),l
 203    008F  DD74EF    		ld	(ix-17),h
 204                    	;   97      entryptr = rxdata + (128 * (entryno % 4));
 205    0092  DD6E04    		ld	l,(ix+4)
 206    0095  DD6605    		ld	h,(ix+5)
 207    0098  E5        		push	hl
 208    0099  210400    		ld	hl,4
 209    009C  E5        		push	hl
 210    009D  CD0000    		call	c.umod
 211    00A0  218000    		ld	hl,128
 212    00A3  E5        		push	hl
 213    00A4  CD0000    		call	c.imul
 214    00A7  E1        		pop	hl
 215    00A8  DD4EEE    		ld	c,(ix-18)
 216    00AB  DD46EF    		ld	b,(ix-17)
 217    00AE  09        		add	hl,bc
 218    00AF  DD75EC    		ld	(ix-20),l
 219    00B2  DD74ED    		ld	(ix-19),h
 220                    	;   98      for (index = 0; index < 16; index++)
 221    00B5  DD36F800  		ld	(ix-8),0
 222    00B9  DD36F900  		ld	(ix-7),0
 223                    	L11:
 224    00BD  DD7EF8    		ld	a,(ix-8)
 225    00C0  D610      		sub	16
 226    00C2  DD7EF9    		ld	a,(ix-7)
 227    00C5  DE00      		sbc	a,0
 228    00C7  F2E800    		jp	p,L12
 229                    	;   99          tstzero |= entryptr[index];
 230    00CA  DD6EEC    		ld	l,(ix-20)
 231    00CD  DD66ED    		ld	h,(ix-19)
 232    00D0  DD4EF8    		ld	c,(ix-8)
 233    00D3  DD46F9    		ld	b,(ix-7)
 234    00D6  09        		add	hl,bc
 235    00D7  DD7EEB    		ld	a,(ix-21)
 236    00DA  B6        		or	(hl)
 237    00DB  DD77EB    		ld	(ix-21),a
 238    00DE  DD34F8    		inc	(ix-8)
 239    00E1  2003      		jr	nz,L4
 240    00E3  DD34F9    		inc	(ix-7)
 241                    	L4:
 242    00E6  18D5      		jr	L11
 243                    	L12:
 244                    	;  100      if (!tstzero)
 245    00E8  DD7EEB    		ld	a,(ix-21)
 246    00EB  B7        		or	a
 247    00EC  2006      		jr	nz,L15
 248                    	;  101          return (NO);
 249    00EE  010000    		ld	bc,0
 250    00F1  C30000    		jp	c.rets
 251                    	L15:
 252                    	;  102      if (entryptr[48] & 0x04)
 253    00F4  DD6EEC    		ld	l,(ix-20)
 254    00F7  DD66ED    		ld	h,(ix-19)
 255    00FA  013000    		ld	bc,48
 256    00FD  09        		add	hl,bc
 257    00FE  7E        		ld	a,(hl)
 258    00FF  CB57      		bit	2,a
 259    0101  6F        		ld	l,a
 260    0102  2815      		jr	z,L16
 261                    	;  103          parptr[partpar].bootable = YES;
 262    0104  2A0000    		ld	hl,(_partpar)
 263    0107  E5        		push	hl
 264    0108  211000    		ld	hl,16
 265    010B  E5        		push	hl
 266    010C  CD0000    		call	c.imul
 267    010F  E1        		pop	hl
 268    0110  ED4B1C01  		ld	bc,(_parptr)
 269    0114  09        		add	hl,bc
 270    0115  23        		inc	hl
 271    0116  23        		inc	hl
 272    0117  3601      		ld	(hl),1
 273                    	L16:
 274                    	;  104      parptr[partpar].parident = PARTGPT;
 275    0119  2A0000    		ld	hl,(_partpar)
 276    011C  E5        		push	hl
 277    011D  211000    		ld	hl,16
 278    0120  E5        		push	hl
 279    0121  CD0000    		call	c.imul
 280    0124  E1        		pop	hl
 281    0125  ED4B1C01  		ld	bc,(_parptr)
 282    0129  09        		add	hl,bc
 283    012A  3603      		ld	(hl),3
 284                    	;  105      /* lower 32 bits of LBA should be sufficient (I hope) */
 285                    	;  106      /* partitions are using LSB while SD block are using MSB */
 286                    	;  107      part2blk(parptr[partpar].parstart, &entryptr[32]);
 287    012C  DD6EEC    		ld	l,(ix-20)
 288    012F  DD66ED    		ld	h,(ix-19)
 289    0132  012000    		ld	bc,32
 290    0135  09        		add	hl,bc
 291    0136  E5        		push	hl
 292    0137  2A0000    		ld	hl,(_partpar)
 293    013A  E5        		push	hl
 294    013B  211000    		ld	hl,16
 295    013E  E5        		push	hl
 296    013F  CD0000    		call	c.imul
 297    0142  E1        		pop	hl
 298    0143  ED4B1C01  		ld	bc,(_parptr)
 299    0147  09        		add	hl,bc
 300    0148  23        		inc	hl
 301    0149  23        		inc	hl
 302    014A  23        		inc	hl
 303    014B  23        		inc	hl
 304    014C  CD0000    		call	_part2blk
 305    014F  F1        		pop	af
 306                    	;  108      part2blk(parptr[partpar].parend, &entryptr[40]);
 307    0150  DD6EEC    		ld	l,(ix-20)
 308    0153  DD66ED    		ld	h,(ix-19)
 309    0156  012800    		ld	bc,40
 310    0159  09        		add	hl,bc
 311    015A  E5        		push	hl
 312    015B  2A0000    		ld	hl,(_partpar)
 313    015E  E5        		push	hl
 314    015F  211000    		ld	hl,16
 315    0162  E5        		push	hl
 316    0163  CD0000    		call	c.imul
 317    0166  E1        		pop	hl
 318    0167  ED4B1C01  		ld	bc,(_parptr)
 319    016B  09        		add	hl,bc
 320    016C  010800    		ld	bc,8
 321    016F  09        		add	hl,bc
 322    0170  CD0000    		call	_part2blk
 323    0173  F1        		pop	af
 324                    	;  109      part2blk(parptr[partpar].parsize, &entryptr[40]);
 325    0174  DD6EEC    		ld	l,(ix-20)
 326    0177  DD66ED    		ld	h,(ix-19)
 327    017A  012800    		ld	bc,40
 328    017D  09        		add	hl,bc
 329    017E  E5        		push	hl
 330    017F  2A0000    		ld	hl,(_partpar)
 331    0182  E5        		push	hl
 332    0183  211000    		ld	hl,16
 333    0186  E5        		push	hl
 334    0187  CD0000    		call	c.imul
 335    018A  E1        		pop	hl
 336    018B  ED4B1C01  		ld	bc,(_parptr)
 337    018F  09        		add	hl,bc
 338    0190  010C00    		ld	bc,12
 339    0193  09        		add	hl,bc
 340    0194  CD0000    		call	_part2blk
 341    0197  F1        		pop	af
 342                    	;  110      subblk(parptr[partpar].parsize, parptr[partpar].parstart);
 343    0198  2A0000    		ld	hl,(_partpar)
 344    019B  E5        		push	hl
 345    019C  211000    		ld	hl,16
 346    019F  E5        		push	hl
 347    01A0  CD0000    		call	c.imul
 348    01A3  E1        		pop	hl
 349    01A4  ED4B1C01  		ld	bc,(_parptr)
 350    01A8  09        		add	hl,bc
 351    01A9  23        		inc	hl
 352    01AA  23        		inc	hl
 353    01AB  23        		inc	hl
 354    01AC  23        		inc	hl
 355    01AD  E5        		push	hl
 356    01AE  2A0000    		ld	hl,(_partpar)
 357    01B1  E5        		push	hl
 358    01B2  211000    		ld	hl,16
 359    01B5  E5        		push	hl
 360    01B6  CD0000    		call	c.imul
 361    01B9  E1        		pop	hl
 362    01BA  ED4B1C01  		ld	bc,(_parptr)
 363    01BE  09        		add	hl,bc
 364    01BF  010C00    		ld	bc,12
 365    01C2  09        		add	hl,bc
 366    01C3  CD0000    		call	_subblk
 367    01C6  F1        		pop	af
 368                    	;  111      addblk(parptr[partpar].parsize, blkone);
 369    01C7  210400    		ld	hl,_blkone
 370    01CA  E5        		push	hl
 371    01CB  2A0000    		ld	hl,(_partpar)
 372    01CE  E5        		push	hl
 373    01CF  211000    		ld	hl,16
 374    01D2  E5        		push	hl
 375    01D3  CD0000    		call	c.imul
 376    01D6  E1        		pop	hl
 377    01D7  ED4B1C01  		ld	bc,(_parptr)
 378    01DB  09        		add	hl,bc
 379    01DC  010C00    		ld	bc,12
 380    01DF  09        		add	hl,bc
 381    01E0  CD0000    		call	_addblk
 382    01E3  F1        		pop	af
 383                    	;  112      memcpy(guidmap[partpar].parguid, &entryptr[0], 16);
 384    01E4  211000    		ld	hl,16
 385    01E7  E5        		push	hl
 386    01E8  DD6EEC    		ld	l,(ix-20)
 387    01EB  DD66ED    		ld	h,(ix-19)
 388    01EE  E5        		push	hl
 389    01EF  2A0000    		ld	hl,(_partpar)
 390    01F2  E5        		push	hl
 391    01F3  211000    		ld	hl,16
 392    01F6  E5        		push	hl
 393    01F7  CD0000    		call	c.imul
 394    01FA  E1        		pop	hl
 395    01FB  011C00    		ld	bc,_guidmap
 396    01FE  09        		add	hl,bc
 397    01FF  CD0000    		call	_memcpy
 398    0202  F1        		pop	af
 399    0203  F1        		pop	af
 400                    	;  113      if (!memcmp(guidmap[partpar].parguid, gptcpm, 16))
 401    0204  211000    		ld	hl,16
 402    0207  E5        		push	hl
 403    0208  210A00    		ld	hl,_gptcpm
 404    020B  E5        		push	hl
 405    020C  2A0000    		ld	hl,(_partpar)
 406    020F  E5        		push	hl
 407    0210  211000    		ld	hl,16
 408    0213  E5        		push	hl
 409    0214  CD0000    		call	c.imul
 410    0217  E1        		pop	hl
 411    0218  011C00    		ld	bc,_guidmap
 412    021B  09        		add	hl,bc
 413    021C  CD0000    		call	_memcmp
 414    021F  F1        		pop	af
 415    0220  F1        		pop	af
 416    0221  79        		ld	a,c
 417    0222  B0        		or	b
 418    0223  2018      		jr	nz,L17
 419                    	;  114          parptr[partpar].partype = mbrcpm;
 420    0225  2A0000    		ld	hl,(_partpar)
 421    0228  E5        		push	hl
 422    0229  211000    		ld	hl,16
 423    022C  E5        		push	hl
 424    022D  CD0000    		call	c.imul
 425    0230  E1        		pop	hl
 426    0231  ED4B1C01  		ld	bc,(_parptr)
 427    0235  09        		add	hl,bc
 428    0236  23        		inc	hl
 429    0237  3A0800    		ld	a,(_mbrcpm)
 430    023A  77        		ld	(hl),a
 431                    	;  115      else if (!memcmp(guidmap[partpar].parguid, gptexcode, 16))
 432    023B  1837      		jr	L101
 433                    	L17:
 434    023D  211000    		ld	hl,16
 435    0240  E5        		push	hl
 436    0241  211A00    		ld	hl,_gptexcode
 437    0244  E5        		push	hl
 438    0245  2A0000    		ld	hl,(_partpar)
 439    0248  E5        		push	hl
 440    0249  211000    		ld	hl,16
 441    024C  E5        		push	hl
 442    024D  CD0000    		call	c.imul
 443    0250  E1        		pop	hl
 444    0251  011C00    		ld	bc,_guidmap
 445    0254  09        		add	hl,bc
 446    0255  CD0000    		call	_memcmp
 447    0258  F1        		pop	af
 448    0259  F1        		pop	af
 449    025A  79        		ld	a,c
 450    025B  B0        		or	b
 451    025C  2016      		jr	nz,L101
 452                    	;  116          parptr[partpar].partype = mbrexcode;
 453    025E  2A0000    		ld	hl,(_partpar)
 454    0261  E5        		push	hl
 455    0262  211000    		ld	hl,16
 456    0265  E5        		push	hl
 457    0266  CD0000    		call	c.imul
 458    0269  E1        		pop	hl
 459    026A  ED4B1C01  		ld	bc,(_parptr)
 460    026E  09        		add	hl,bc
 461    026F  23        		inc	hl
 462    0270  3A0900    		ld	a,(_mbrexcode)
 463    0273  77        		ld	(hl),a
 464                    	L101:
 465                    	;  117      partpar++;
 466    0274  2A0000    		ld	hl,(_partpar)
 467    0277  23        		inc	hl
 468    0278  220000    		ld	(_partpar),hl
 469                    	;  118      return (YES);
 470    027B  010100    		ld	bc,1
 471    027E  C30000    		jp	c.rets
 472                    	;  119      }
 473                    	;  120  
 474                    	;  121  /* Analyze and GPT header
 475                    	;  122   */
 476                    	;  123  void sdgpthdr(unsigned char *blkno)
 477                    	;  124      {
 478                    	_sdgpthdr:
 479    0281  CD0000    		call	c.savs
 480    0284  21F0FF    		ld	hl,65520
 481    0287  39        		add	hl,sp
 482    0288  F9        		ld	sp,hl
 483                    	;  125      int index;
 484                    	;  126      unsigned int partno;
 485                    	;  127      unsigned char *rxdata;
 486                    	;  128      unsigned long entries;
 487                    	;  129  
 488                    	;  130      if (!sdread(sdrdbuf, blkno))
 489    0289  DD6E04    		ld	l,(ix+4)
 490    028C  DD6605    		ld	h,(ix+5)
 491    028F  E5        		push	hl
 492    0290  210000    		ld	hl,_sdrdbuf
 493    0293  CD0000    		call	_sdread
 494    0296  F1        		pop	af
 495    0297  79        		ld	a,c
 496    0298  B0        		or	b
 497    0299  2003      		jr	nz,L121
 498                    	;  131          return;
 499    029B  C30000    		jp	c.rets
 500                    	L121:
 501                    	;  132      rxdata = sdrdbuf;
 502    029E  210000    		ld	hl,_sdrdbuf
 503    02A1  DD75F4    		ld	(ix-12),l
 504    02A4  DD74F5    		ld	(ix-11),h
 505                    	;  133      for (partno = 0; (partno < 16) && (partpar < 16); partno++)
 506    02A7  DD36F600  		ld	(ix-10),0
 507    02AB  DD36F700  		ld	(ix-9),0
 508                    	L131:
 509    02AF  DD7EF6    		ld	a,(ix-10)
 510    02B2  D610      		sub	16
 511    02B4  DD7EF7    		ld	a,(ix-9)
 512    02B7  DE00      		sbc	a,0
 513    02B9  3027      		jr	nc,L141
 514    02BB  3A0000    		ld	a,(_partpar)
 515    02BE  D610      		sub	16
 516    02C0  3A0100    		ld	a,(_partpar+1)
 517    02C3  DE00      		sbc	a,0
 518    02C5  F2E202    		jp	p,L141
 519                    	;  134          {
 520                    	;  135          if (!gptentry(partno))
 521    02C8  DD6EF6    		ld	l,(ix-10)
 522    02CB  DD66F7    		ld	h,(ix-9)
 523    02CE  CD2A00    		call	_gptentry
 524    02D1  79        		ld	a,c
 525    02D2  B0        		or	b
 526    02D3  2003      		jr	nz,L151
 527                    	;  136              return;
 528    02D5  C30000    		jp	c.rets
 529                    	L151:
 530    02D8  DD34F6    		inc	(ix-10)
 531    02DB  2003      		jr	nz,L01
 532    02DD  DD34F7    		inc	(ix-9)
 533                    	L01:
 534    02E0  18CD      		jr	L131
 535                    	L141:
 536                    	;  137          }
 537                    	;  138      }
 538    02E2  C30000    		jp	c.rets
 539                    	;  139  
 540                    	;  140  /* Analyze and print MBR partition entry
 541                    	;  141   * Returns:
 542                    	;  142   *    -1 if errror - should not happen
 543                    	;  143   *     0 if not used entry
 544                    	;  144   *     1 if MBR entry
 545                    	;  145   *     2 if EBR entry
 546                    	;  146   *     3 if GTP entry
 547                    	;  147   */
 548                    	;  148  int sdmbrentry(unsigned char *partptr)
 549                    	;  149      {
 550                    	_sdmbrentry:
 551    02E5  CD0000    		call	c.savs
 552    02E8  21F6FF    		ld	hl,65526
 553    02EB  39        		add	hl,sp
 554    02EC  F9        		ld	sp,hl
 555                    	;  150      int index;
 556                    	;  151      int parttype;
 557                    	;  152  
 558                    	;  153      parttype = PARTMBR;
 559    02ED  DD36F601  		ld	(ix-10),1
 560    02F1  DD36F700  		ld	(ix-9),0
 561                    	;  154      if (!partptr[4])
 562    02F5  DD6E04    		ld	l,(ix+4)
 563    02F8  DD6605    		ld	h,(ix+5)
 564    02FB  23        		inc	hl
 565    02FC  23        		inc	hl
 566    02FD  23        		inc	hl
 567    02FE  23        		inc	hl
 568    02FF  7E        		ld	a,(hl)
 569    0300  B7        		or	a
 570    0301  2006      		jr	nz,L102
 571                    	;  155          return (PARTZRO);
 572    0303  010000    		ld	bc,0
 573    0306  C30000    		jp	c.rets
 574                    	L102:
 575                    	;  156      if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
 576    0309  DD6E04    		ld	l,(ix+4)
 577    030C  DD6605    		ld	h,(ix+5)
 578    030F  23        		inc	hl
 579    0310  23        		inc	hl
 580    0311  23        		inc	hl
 581    0312  23        		inc	hl
 582    0313  7E        		ld	a,(hl)
 583    0314  FEEE      		cp	238
 584    0316  CA0906    		jp	z,L112
 585                    	;  157          {
 586                    	;  158          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
 587    0319  DD6E04    		ld	l,(ix+4)
 588    031C  DD6605    		ld	h,(ix+5)
 589    031F  23        		inc	hl
 590    0320  23        		inc	hl
 591    0321  23        		inc	hl
 592    0322  23        		inc	hl
 593    0323  7E        		ld	a,(hl)
 594    0324  FE05      		cp	5
 595    0326  2810      		jr	z,L132
 596    0328  DD6E04    		ld	l,(ix+4)
 597    032B  DD6605    		ld	h,(ix+5)
 598    032E  23        		inc	hl
 599    032F  23        		inc	hl
 600    0330  23        		inc	hl
 601    0331  23        		inc	hl
 602    0332  7E        		ld	a,(hl)
 603    0333  FE0F      		cp	15
 604    0335  C29604    		jp	nz,L122
 605                    	L132:
 606                    	;  159              {
 607                    	;  160              parttype = PARTEBR;
 608    0338  DD36F602  		ld	(ix-10),2
 609    033C  DD36F700  		ld	(ix-9),0
 610                    	;  161              if (memcmp(curblkno, blkzero, 4) == 0) /* points to EBR in the MBR */
 611    0340  210400    		ld	hl,4
 612    0343  E5        		push	hl
 613    0344  210000    		ld	hl,_blkzero
 614    0347  E5        		push	hl
 615    0348  210000    		ld	hl,_curblkno
 616    034B  CD0000    		call	_memcmp
 617    034E  F1        		pop	af
 618    034F  F1        		pop	af
 619    0350  79        		ld	a,c
 620    0351  B0        		or	b
 621    0352  C27604    		jp	nz,L142
 622                    	;  162                  {
 623                    	;  163                  memset(ebrnext, 0, 4);
 624    0355  210400    		ld	hl,4
 625    0358  E5        		push	hl
 626    0359  210000    		ld	hl,0
 627    035C  E5        		push	hl
 628    035D  210200    		ld	hl,_ebrnext
 629    0360  CD0000    		call	_memset
 630    0363  F1        		pop	af
 631    0364  F1        		pop	af
 632                    	;  164                  parptr[partpar].parident = EBRCONT;
 633    0365  2A0000    		ld	hl,(_partpar)
 634    0368  E5        		push	hl
 635    0369  211000    		ld	hl,16
 636    036C  E5        		push	hl
 637    036D  CD0000    		call	c.imul
 638    0370  E1        		pop	hl
 639    0371  ED4B1C01  		ld	bc,(_parptr)
 640    0375  09        		add	hl,bc
 641    0376  3614      		ld	(hl),20
 642                    	;  165                  part2blk(parptr[partpar].parstart, &partptr[8]);
 643    0378  DD6E04    		ld	l,(ix+4)
 644    037B  DD6605    		ld	h,(ix+5)
 645    037E  010800    		ld	bc,8
 646    0381  09        		add	hl,bc
 647    0382  E5        		push	hl
 648    0383  2A0000    		ld	hl,(_partpar)
 649    0386  E5        		push	hl
 650    0387  211000    		ld	hl,16
 651    038A  E5        		push	hl
 652    038B  CD0000    		call	c.imul
 653    038E  E1        		pop	hl
 654    038F  ED4B1C01  		ld	bc,(_parptr)
 655    0393  09        		add	hl,bc
 656    0394  23        		inc	hl
 657    0395  23        		inc	hl
 658    0396  23        		inc	hl
 659    0397  23        		inc	hl
 660    0398  CD0000    		call	_part2blk
 661    039B  F1        		pop	af
 662                    	;  166                  part2blk(parptr[partpar].parsize, &partptr[12]);
 663    039C  DD6E04    		ld	l,(ix+4)
 664    039F  DD6605    		ld	h,(ix+5)
 665    03A2  010C00    		ld	bc,12
 666    03A5  09        		add	hl,bc
 667    03A6  E5        		push	hl
 668    03A7  2A0000    		ld	hl,(_partpar)
 669    03AA  E5        		push	hl
 670    03AB  211000    		ld	hl,16
 671    03AE  E5        		push	hl
 672    03AF  CD0000    		call	c.imul
 673    03B2  E1        		pop	hl
 674    03B3  ED4B1C01  		ld	bc,(_parptr)
 675    03B7  09        		add	hl,bc
 676    03B8  010C00    		ld	bc,12
 677    03BB  09        		add	hl,bc
 678    03BC  CD0000    		call	_part2blk
 679    03BF  F1        		pop	af
 680                    	;  167                  part2blk(parptr[partpar].parend, &partptr[8]);
 681    03C0  DD6E04    		ld	l,(ix+4)
 682    03C3  DD6605    		ld	h,(ix+5)
 683    03C6  010800    		ld	bc,8
 684    03C9  09        		add	hl,bc
 685    03CA  E5        		push	hl
 686    03CB  2A0000    		ld	hl,(_partpar)
 687    03CE  E5        		push	hl
 688    03CF  211000    		ld	hl,16
 689    03D2  E5        		push	hl
 690    03D3  CD0000    		call	c.imul
 691    03D6  E1        		pop	hl
 692    03D7  ED4B1C01  		ld	bc,(_parptr)
 693    03DB  09        		add	hl,bc
 694    03DC  010800    		ld	bc,8
 695    03DF  09        		add	hl,bc
 696    03E0  CD0000    		call	_part2blk
 697    03E3  F1        		pop	af
 698                    	;  168                  addblk(parptr[partpar].parend, parptr[partpar].parsize);
 699    03E4  2A0000    		ld	hl,(_partpar)
 700    03E7  E5        		push	hl
 701    03E8  211000    		ld	hl,16
 702    03EB  E5        		push	hl
 703    03EC  CD0000    		call	c.imul
 704    03EF  E1        		pop	hl
 705    03F0  ED4B1C01  		ld	bc,(_parptr)
 706    03F4  09        		add	hl,bc
 707    03F5  010C00    		ld	bc,12
 708    03F8  09        		add	hl,bc
 709    03F9  E5        		push	hl
 710    03FA  2A0000    		ld	hl,(_partpar)
 711    03FD  E5        		push	hl
 712    03FE  211000    		ld	hl,16
 713    0401  E5        		push	hl
 714    0402  CD0000    		call	c.imul
 715    0405  E1        		pop	hl
 716    0406  ED4B1C01  		ld	bc,(_parptr)
 717    040A  09        		add	hl,bc
 718    040B  010800    		ld	bc,8
 719    040E  09        		add	hl,bc
 720    040F  CD0000    		call	_addblk
 721    0412  F1        		pop	af
 722                    	;  169                  subblk(parptr[partpar].parend, blkone);
 723    0413  210400    		ld	hl,_blkone
 724    0416  E5        		push	hl
 725    0417  2A0000    		ld	hl,(_partpar)
 726    041A  E5        		push	hl
 727    041B  211000    		ld	hl,16
 728    041E  E5        		push	hl
 729    041F  CD0000    		call	c.imul
 730    0422  E1        		pop	hl
 731    0423  ED4B1C01  		ld	bc,(_parptr)
 732    0427  09        		add	hl,bc
 733    0428  010800    		ld	bc,8
 734    042B  09        		add	hl,bc
 735    042C  CD0000    		call	_subblk
 736    042F  F1        		pop	af
 737                    	;  170                  parptr[partpar].partype = partptr[4];
 738    0430  2A0000    		ld	hl,(_partpar)
 739    0433  E5        		push	hl
 740    0434  211000    		ld	hl,16
 741    0437  E5        		push	hl
 742    0438  CD0000    		call	c.imul
 743    043B  E1        		pop	hl
 744    043C  ED4B1C01  		ld	bc,(_parptr)
 745    0440  09        		add	hl,bc
 746    0441  23        		inc	hl
 747    0442  DD4E04    		ld	c,(ix+4)
 748    0445  DD4605    		ld	b,(ix+5)
 749    0448  03        		inc	bc
 750    0449  03        		inc	bc
 751    044A  03        		inc	bc
 752    044B  03        		inc	bc
 753    044C  0A        		ld	a,(bc)
 754    044D  77        		ld	(hl),a
 755                    	;  171                  partpar++;
 756    044E  2A0000    		ld	hl,(_partpar)
 757    0451  23        		inc	hl
 758    0452  220000    		ld	(_partpar),hl
 759                    	;  172                  /* save to handle later */
 760                    	;  173                  part2blk(ebrrecs[ebrrecidx++].ebrblk, &partptr[8]);
 761    0455  DD6E04    		ld	l,(ix+4)
 762    0458  DD6605    		ld	h,(ix+5)
 763    045B  010800    		ld	bc,8
 764    045E  09        		add	hl,bc
 765    045F  E5        		push	hl
 766    0460  2A0600    		ld	hl,(_ebrrecidx)
 767    0463  E5        		push	hl
 768    0464  23        		inc	hl
 769    0465  220600    		ld	(_ebrrecidx),hl
 770    0468  E1        		pop	hl
 771    0469  29        		add	hl,hl
 772    046A  29        		add	hl,hl
 773    046B  010800    		ld	bc,_ebrrecs
 774    046E  09        		add	hl,bc
 775    046F  CD0000    		call	_part2blk
 776    0472  F1        		pop	af
 777                    	;  174                  }
 778                    	;  175              else
 779    0473  C30906    		jp	L112
 780                    	L142:
 781                    	;  176                  {
 782                    	;  177                  part2blk(ebrnext, &partptr[8]);
 783    0476  DD6E04    		ld	l,(ix+4)
 784    0479  DD6605    		ld	h,(ix+5)
 785    047C  010800    		ld	bc,8
 786    047F  09        		add	hl,bc
 787    0480  E5        		push	hl
 788    0481  210200    		ld	hl,_ebrnext
 789    0484  CD0000    		call	_part2blk
 790    0487  F1        		pop	af
 791                    	;  178                  addblk(ebrnext, curblkno);
 792    0488  210000    		ld	hl,_curblkno
 793    048B  E5        		push	hl
 794    048C  210200    		ld	hl,_ebrnext
 795    048F  CD0000    		call	_addblk
 796    0492  F1        		pop	af
 797    0493  C30906    		jp	L112
 798                    	L122:
 799                    	;  179                  }
 800                    	;  180              }
 801                    	;  181          else
 802                    	;  182              {
 803                    	;  183              if (memcmp(&partptr[12], blkzero, 4)) /* ugly hack to avoid empty partitions */
 804    0496  210400    		ld	hl,4
 805    0499  E5        		push	hl
 806    049A  210000    		ld	hl,_blkzero
 807    049D  E5        		push	hl
 808    049E  DD6E04    		ld	l,(ix+4)
 809    04A1  DD6605    		ld	h,(ix+5)
 810    04A4  010C00    		ld	bc,12
 811    04A7  09        		add	hl,bc
 812    04A8  CD0000    		call	_memcmp
 813    04AB  F1        		pop	af
 814    04AC  F1        		pop	af
 815    04AD  79        		ld	a,c
 816    04AE  B0        		or	b
 817    04AF  CA0906    		jp	z,L112
 818                    	;  184                  {
 819                    	;  185                  if (partptr[0] & 0x80)
 820    04B2  DD6E04    		ld	l,(ix+4)
 821    04B5  DD6605    		ld	h,(ix+5)
 822    04B8  7E        		ld	a,(hl)
 823    04B9  CB7F      		bit	7,a
 824    04BB  6F        		ld	l,a
 825    04BC  2815      		jr	z,L103
 826                    	;  186                      parptr[partpar].bootable = YES;
 827    04BE  2A0000    		ld	hl,(_partpar)
 828    04C1  E5        		push	hl
 829    04C2  211000    		ld	hl,16
 830    04C5  E5        		push	hl
 831    04C6  CD0000    		call	c.imul
 832    04C9  E1        		pop	hl
 833    04CA  ED4B1C01  		ld	bc,(_parptr)
 834    04CE  09        		add	hl,bc
 835    04CF  23        		inc	hl
 836    04D0  23        		inc	hl
 837    04D1  3601      		ld	(hl),1
 838                    	L103:
 839                    	;  187                  if (!memcmp(curblkno, blkzero, 4))
 840    04D3  210400    		ld	hl,4
 841    04D6  E5        		push	hl
 842    04D7  210000    		ld	hl,_blkzero
 843    04DA  E5        		push	hl
 844    04DB  210000    		ld	hl,_curblkno
 845    04DE  CD0000    		call	_memcmp
 846    04E1  F1        		pop	af
 847    04E2  F1        		pop	af
 848    04E3  79        		ld	a,c
 849    04E4  B0        		or	b
 850    04E5  2015      		jr	nz,L113
 851                    	;  188                      parptr[partpar].parident = PARTMBR;
 852    04E7  2A0000    		ld	hl,(_partpar)
 853    04EA  E5        		push	hl
 854    04EB  211000    		ld	hl,16
 855    04EE  E5        		push	hl
 856    04EF  CD0000    		call	c.imul
 857    04F2  E1        		pop	hl
 858    04F3  ED4B1C01  		ld	bc,(_parptr)
 859    04F7  09        		add	hl,bc
 860    04F8  3601      		ld	(hl),1
 861                    	;  189                  else
 862    04FA  1813      		jr	L123
 863                    	L113:
 864                    	;  190                      parptr[partpar].parident = PARTEBR;
 865    04FC  2A0000    		ld	hl,(_partpar)
 866    04FF  E5        		push	hl
 867    0500  211000    		ld	hl,16
 868    0503  E5        		push	hl
 869    0504  CD0000    		call	c.imul
 870    0507  E1        		pop	hl
 871    0508  ED4B1C01  		ld	bc,(_parptr)
 872    050C  09        		add	hl,bc
 873    050D  3602      		ld	(hl),2
 874                    	L123:
 875                    	;  191                  part2blk(parptr[partpar].parstart, &partptr[8]);
 876    050F  DD6E04    		ld	l,(ix+4)
 877    0512  DD6605    		ld	h,(ix+5)
 878    0515  010800    		ld	bc,8
 879    0518  09        		add	hl,bc
 880    0519  E5        		push	hl
 881    051A  2A0000    		ld	hl,(_partpar)
 882    051D  E5        		push	hl
 883    051E  211000    		ld	hl,16
 884    0521  E5        		push	hl
 885    0522  CD0000    		call	c.imul
 886    0525  E1        		pop	hl
 887    0526  ED4B1C01  		ld	bc,(_parptr)
 888    052A  09        		add	hl,bc
 889    052B  23        		inc	hl
 890    052C  23        		inc	hl
 891    052D  23        		inc	hl
 892    052E  23        		inc	hl
 893    052F  CD0000    		call	_part2blk
 894    0532  F1        		pop	af
 895                    	;  192                  addblk(parptr[partpar].parstart, curblkno);
 896    0533  210000    		ld	hl,_curblkno
 897    0536  E5        		push	hl
 898    0537  2A0000    		ld	hl,(_partpar)
 899    053A  E5        		push	hl
 900    053B  211000    		ld	hl,16
 901    053E  E5        		push	hl
 902    053F  CD0000    		call	c.imul
 903    0542  E1        		pop	hl
 904    0543  ED4B1C01  		ld	bc,(_parptr)
 905    0547  09        		add	hl,bc
 906    0548  23        		inc	hl
 907    0549  23        		inc	hl
 908    054A  23        		inc	hl
 909    054B  23        		inc	hl
 910    054C  CD0000    		call	_addblk
 911    054F  F1        		pop	af
 912                    	;  193                  part2blk(parptr[partpar].parsize, &partptr[12]);
 913    0550  DD6E04    		ld	l,(ix+4)
 914    0553  DD6605    		ld	h,(ix+5)
 915    0556  010C00    		ld	bc,12
 916    0559  09        		add	hl,bc
 917    055A  E5        		push	hl
 918    055B  2A0000    		ld	hl,(_partpar)
 919    055E  E5        		push	hl
 920    055F  211000    		ld	hl,16
 921    0562  E5        		push	hl
 922    0563  CD0000    		call	c.imul
 923    0566  E1        		pop	hl
 924    0567  ED4B1C01  		ld	bc,(_parptr)
 925    056B  09        		add	hl,bc
 926    056C  010C00    		ld	bc,12
 927    056F  09        		add	hl,bc
 928    0570  CD0000    		call	_part2blk
 929    0573  F1        		pop	af
 930                    	;  194                  part2blk(parptr[partpar].parend, &partptr[12]);
 931    0574  DD6E04    		ld	l,(ix+4)
 932    0577  DD6605    		ld	h,(ix+5)
 933    057A  010C00    		ld	bc,12
 934    057D  09        		add	hl,bc
 935    057E  E5        		push	hl
 936    057F  2A0000    		ld	hl,(_partpar)
 937    0582  E5        		push	hl
 938    0583  211000    		ld	hl,16
 939    0586  E5        		push	hl
 940    0587  CD0000    		call	c.imul
 941    058A  E1        		pop	hl
 942    058B  ED4B1C01  		ld	bc,(_parptr)
 943    058F  09        		add	hl,bc
 944    0590  010800    		ld	bc,8
 945    0593  09        		add	hl,bc
 946    0594  CD0000    		call	_part2blk
 947    0597  F1        		pop	af
 948                    	;  195                  addblk(parptr[partpar].parend, parptr[partpar].parstart);
 949    0598  2A0000    		ld	hl,(_partpar)
 950    059B  E5        		push	hl
 951    059C  211000    		ld	hl,16
 952    059F  E5        		push	hl
 953    05A0  CD0000    		call	c.imul
 954    05A3  E1        		pop	hl
 955    05A4  ED4B1C01  		ld	bc,(_parptr)
 956    05A8  09        		add	hl,bc
 957    05A9  23        		inc	hl
 958    05AA  23        		inc	hl
 959    05AB  23        		inc	hl
 960    05AC  23        		inc	hl
 961    05AD  E5        		push	hl
 962    05AE  2A0000    		ld	hl,(_partpar)
 963    05B1  E5        		push	hl
 964    05B2  211000    		ld	hl,16
 965    05B5  E5        		push	hl
 966    05B6  CD0000    		call	c.imul
 967    05B9  E1        		pop	hl
 968    05BA  ED4B1C01  		ld	bc,(_parptr)
 969    05BE  09        		add	hl,bc
 970    05BF  010800    		ld	bc,8
 971    05C2  09        		add	hl,bc
 972    05C3  CD0000    		call	_addblk
 973    05C6  F1        		pop	af
 974                    	;  196                  subblk(parptr[partpar].parend, blkone);
 975    05C7  210400    		ld	hl,_blkone
 976    05CA  E5        		push	hl
 977    05CB  2A0000    		ld	hl,(_partpar)
 978    05CE  E5        		push	hl
 979    05CF  211000    		ld	hl,16
 980    05D2  E5        		push	hl
 981    05D3  CD0000    		call	c.imul
 982    05D6  E1        		pop	hl
 983    05D7  ED4B1C01  		ld	bc,(_parptr)
 984    05DB  09        		add	hl,bc
 985    05DC  010800    		ld	bc,8
 986    05DF  09        		add	hl,bc
 987    05E0  CD0000    		call	_subblk
 988    05E3  F1        		pop	af
 989                    	;  197                  parptr[partpar].partype = partptr[4];
 990    05E4  2A0000    		ld	hl,(_partpar)
 991    05E7  E5        		push	hl
 992    05E8  211000    		ld	hl,16
 993    05EB  E5        		push	hl
 994    05EC  CD0000    		call	c.imul
 995    05EF  E1        		pop	hl
 996    05F0  ED4B1C01  		ld	bc,(_parptr)
 997    05F4  09        		add	hl,bc
 998    05F5  23        		inc	hl
 999    05F6  DD4E04    		ld	c,(ix+4)
1000    05F9  DD4605    		ld	b,(ix+5)
1001    05FC  03        		inc	bc
1002    05FD  03        		inc	bc
1003    05FE  03        		inc	bc
1004    05FF  03        		inc	bc
1005    0600  0A        		ld	a,(bc)
1006    0601  77        		ld	(hl),a
1007                    	;  198                  partpar++;
1008    0602  2A0000    		ld	hl,(_partpar)
1009    0605  23        		inc	hl
1010    0606  220000    		ld	(_partpar),hl
1011                    	L112:
1012                    	;  199                  }
1013                    	;  200              }
1014                    	;  201          }
1015                    	;  202  
1016                    	;  203      if (partptr[4] == 0xee) /* GPT partitions */
1017    0609  DD6E04    		ld	l,(ix+4)
1018    060C  DD6605    		ld	h,(ix+5)
1019    060F  23        		inc	hl
1020    0610  23        		inc	hl
1021    0611  23        		inc	hl
1022    0612  23        		inc	hl
1023    0613  7E        		ld	a,(hl)
1024    0614  FEEE      		cp	238
1025    0616  C26606    		jp	nz,L133
1026                    	;  204          {
1027                    	;  205          parttype = PARTGPT;
1028    0619  DD36F603  		ld	(ix-10),3
1029    061D  DD36F700  		ld	(ix-9),0
1030                    	;  206          sdgpthdr(parptr[partpar].parstart); /* handle GTP partitions */
1031    0621  2A0000    		ld	hl,(_partpar)
1032    0624  E5        		push	hl
1033    0625  211000    		ld	hl,16
1034    0628  E5        		push	hl
1035    0629  CD0000    		call	c.imul
1036    062C  E1        		pop	hl
1037    062D  ED4B1C01  		ld	bc,(_parptr)
1038    0631  09        		add	hl,bc
1039    0632  23        		inc	hl
1040    0633  23        		inc	hl
1041    0634  23        		inc	hl
1042    0635  23        		inc	hl
1043    0636  CD8102    		call	_sdgpthdr
1044                    	;  207          /* re-read MBR on sector 0
1045                    	;  208             This is probably not needed as there
1046                    	;  209             is only one entry (the first one)
1047                    	;  210             in the MBR when using GPT */
1048                    	;  211          if (sdread(sdrdbuf, 0))
1049    0639  210000    		ld	hl,0
1050    063C  E5        		push	hl
1051    063D  210000    		ld	hl,_sdrdbuf
1052    0640  CD0000    		call	_sdread
1053    0643  F1        		pop	af
1054    0644  79        		ld	a,c
1055    0645  B0        		or	b
1056    0646  2818      		jr	z,L143
1057                    	;  212              {
1058                    	;  213              memset(curblkno, 0, 4);
1059    0648  210400    		ld	hl,4
1060    064B  E5        		push	hl
1061    064C  210000    		ld	hl,0
1062    064F  E5        		push	hl
1063    0650  210000    		ld	hl,_curblkno
1064    0653  CD0000    		call	_memset
1065    0656  F1        		pop	af
1066    0657  F1        		pop	af
1067                    	;  214              curblkok = YES;
1068    0658  210100    		ld	hl,1
1069    065B  220000    		ld	(_curblkok),hl
1070                    	;  215              }
1071                    	;  216          else
1072    065E  1806      		jr	L133
1073                    	L143:
1074                    	;  217              return(-1);
1075    0660  01FFFF    		ld	bc,65535
1076    0663  C30000    		jp	c.rets
1077                    	L133:
1078                    	;  218          }
1079                    	;  219      return (parttype);
1080    0666  DD4EF6    		ld	c,(ix-10)
1081    0669  DD46F7    		ld	b,(ix-9)
1082    066C  C30000    		jp	c.rets
1083                    	;  220      }
1084                    	;  221  
1085                    	;  222  /* Read and analyze MBR/EBR partition sector block
1086                    	;  223   * and go through and print partition entries.
1087                    	;  224   */
1088                    	;  225  void sdmbrpart(unsigned char *sector)
1089                    	;  226      {
1090                    	_sdmbrpart:
1091    066F  CD0000    		call	c.savs
1092    0672  21EEFF    		ld	hl,65518
1093    0675  39        		add	hl,sp
1094    0676  F9        		ld	sp,hl
1095                    	;  227      int partidx;  /* partition index 1 - 4 */
1096                    	;  228      int cpartidx; /* chain partition index 1 - 4 */
1097                    	;  229      int chainidx;
1098                    	;  230      int enttype;
1099                    	;  231      unsigned char *entp; /* pointer to partition entry */
1100                    	;  232      char *mbrebr;
1101                    	;  233  
1102                    	;  234      if (sdread(sdrdbuf, sector))
1103    0677  DD6E04    		ld	l,(ix+4)
1104    067A  DD6605    		ld	h,(ix+5)
1105    067D  E5        		push	hl
1106    067E  210000    		ld	hl,_sdrdbuf
1107    0681  CD0000    		call	_sdread
1108    0684  F1        		pop	af
1109    0685  79        		ld	a,c
1110    0686  B0        		or	b
1111    0687  2829      		jr	z,L163
1112                    	;  235          {
1113                    	;  236          memcpy(curblkno, sector, 4);
1114    0689  210400    		ld	hl,4
1115    068C  E5        		push	hl
1116    068D  DD6E04    		ld	l,(ix+4)
1117    0690  DD6605    		ld	h,(ix+5)
1118    0693  E5        		push	hl
1119    0694  210000    		ld	hl,_curblkno
1120    0697  CD0000    		call	_memcpy
1121    069A  F1        		pop	af
1122    069B  F1        		pop	af
1123                    	;  237          curblkok = YES;
1124    069C  210100    		ld	hl,1
1125    069F  220000    		ld	(_curblkok),hl
1126                    	;  238          }
1127                    	;  239      else
1128                    	;  240          return;
1129                    	;  241      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
1130    06A2  3AFE01    		ld	a,(_sdrdbuf+510)
1131    06A5  FE55      		cp	85
1132    06A7  2009      		jr	nz,L114
1133    06A9  3AFF01    		ld	a,(_sdrdbuf+511)
1134    06AC  FEAA      		cp	170
1135    06AE  2805      		jr	z,L104
1136    06B0  1800      		jr	L114
1137                    	L163:
1138                    	;  242          return;
1139                    	L114:
1140    06B2  C30000    		jp	c.rets
1141                    	L104:
1142                    	;  243      if (memcmp(curblkno, blkzero, 4) == 0)
1143    06B5  210400    		ld	hl,4
1144    06B8  E5        		push	hl
1145    06B9  210000    		ld	hl,_blkzero
1146    06BC  E5        		push	hl
1147    06BD  210000    		ld	hl,_curblkno
1148    06C0  CD0000    		call	_memcmp
1149    06C3  F1        		pop	af
1150    06C4  F1        		pop	af
1151    06C5  79        		ld	a,c
1152    06C6  B0        		or	b
1153    06C7  2010      		jr	nz,L124
1154                    	;  244          memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
1155    06C9  210400    		ld	hl,4
1156    06CC  E5        		push	hl
1157    06CD  21B801    		ld	hl,_sdrdbuf+440
1158    06D0  E5        		push	hl
1159    06D1  211800    		ld	hl,_dsksign
1160    06D4  CD0000    		call	_memcpy
1161    06D7  F1        		pop	af
1162    06D8  F1        		pop	af
1163                    	L124:
1164                    	;  245      /* go through MBR partition entries until first empty */
1165                    	;  246      /* !!as the MBR entry routine is called recusively a way is
1166                    	;  247         needed to read sector 0 when going back to MBR if
1167                    	;  248         there is a primary partition entry after an EBR entry!! */
1168                    	;  249      entp = &sdrdbuf[0x01be] ;
1169    06D9  21BE01    		ld	hl,_sdrdbuf+446
1170    06DC  DD75F0    		ld	(ix-16),l
1171    06DF  DD74F1    		ld	(ix-15),h
1172                    	;  250      for (partidx = 1; (partidx <= 4) && (partpar < 16); partidx++, entp += 16)
1173    06E2  DD36F801  		ld	(ix-8),1
1174    06E6  DD36F900  		ld	(ix-7),0
1175                    	L134:
1176    06EA  3E04      		ld	a,4
1177    06EC  DD96F8    		sub	(ix-8)
1178    06EF  3E00      		ld	a,0
1179    06F1  DD9EF9    		sbc	a,(ix-7)
1180    06F4  FA4A07    		jp	m,L144
1181    06F7  3A0000    		ld	a,(_partpar)
1182    06FA  D610      		sub	16
1183    06FC  3A0100    		ld	a,(_partpar+1)
1184    06FF  DE00      		sbc	a,0
1185    0701  F24A07    		jp	p,L144
1186                    	;  251          {
1187                    	;  252          enttype = sdmbrentry(entp);
1188    0704  DD6EF0    		ld	l,(ix-16)
1189    0707  DD66F1    		ld	h,(ix-15)
1190    070A  CDE502    		call	_sdmbrentry
1191    070D  DD71F2    		ld	(ix-14),c
1192    0710  DD70F3    		ld	(ix-13),b
1193                    	;  253          if (enttype == -1) /* read error */
1194    0713  DD7EF2    		ld	a,(ix-14)
1195    0716  FEFF      		cp	255
1196    0718  2005      		jr	nz,L02
1197    071A  DD7EF3    		ld	a,(ix-13)
1198    071D  FEFF      		cp	255
1199                    	L02:
1200    071F  2021      		jr	nz,L174
1201                    	;  254              return;
1202    0721  C30000    		jp	c.rets
1203                    	L154:
1204    0724  DD34F8    		inc	(ix-8)
1205    0727  2003      		jr	nz,L61
1206    0729  DD34F9    		inc	(ix-7)
1207                    	L61:
1208    072C  DD6EF0    		ld	l,(ix-16)
1209    072F  DD66F1    		ld	h,(ix-15)
1210    0732  7D        		ld	a,l
1211    0733  C610      		add	a,16
1212    0735  6F        		ld	l,a
1213    0736  7C        		ld	a,h
1214    0737  CE00      		adc	a,0
1215    0739  67        		ld	h,a
1216    073A  DD75F0    		ld	(ix-16),l
1217    073D  DD74F1    		ld	(ix-15),h
1218    0740  18A8      		jr	L134
1219                    	L174:
1220                    	;  255          else if (enttype == PARTZRO)
1221    0742  DD7EF2    		ld	a,(ix-14)
1222    0745  DDB6F3    		or	(ix-13)
1223    0748  20DA      		jr	nz,L154
1224                    	;  256              break;
1225                    	L144:
1226                    	;  257          }
1227                    	;  258      /* now handle the previously saved EBR partition sectors */
1228                    	;  259      for (partidx = 0; (partidx < ebrrecidx) && (partpar < 16); partidx++)
1229    074A  DD36F800  		ld	(ix-8),0
1230    074E  DD36F900  		ld	(ix-7),0
1231                    	L125:
1232    0752  210600    		ld	hl,_ebrrecidx
1233    0755  DD7EF8    		ld	a,(ix-8)
1234    0758  96        		sub	(hl)
1235    0759  DD7EF9    		ld	a,(ix-7)
1236    075C  23        		inc	hl
1237    075D  9E        		sbc	a,(hl)
1238    075E  F20509    		jp	p,L135
1239    0761  3A0000    		ld	a,(_partpar)
1240    0764  D610      		sub	16
1241    0766  3A0100    		ld	a,(_partpar+1)
1242    0769  DE00      		sbc	a,0
1243    076B  F20509    		jp	p,L135
1244                    	;  260          {
1245                    	;  261          if (sdread(sdrdbuf, ebrrecs[partidx].ebrblk))
1246    076E  DD6EF8    		ld	l,(ix-8)
1247    0771  DD66F9    		ld	h,(ix-7)
1248    0774  29        		add	hl,hl
1249    0775  29        		add	hl,hl
1250    0776  010800    		ld	bc,_ebrrecs
1251    0779  09        		add	hl,bc
1252    077A  E5        		push	hl
1253    077B  210000    		ld	hl,_sdrdbuf
1254    077E  CD0000    		call	_sdread
1255    0781  F1        		pop	af
1256    0782  79        		ld	a,c
1257    0783  B0        		or	b
1258    0784  CAFC07    		jp	z,L165
1259                    	;  262              {
1260                    	;  263              memcpy(curblkno, ebrrecs[partidx].ebrblk, 4);
1261    0787  210400    		ld	hl,4
1262    078A  E5        		push	hl
1263    078B  DD6EF8    		ld	l,(ix-8)
1264    078E  DD66F9    		ld	h,(ix-7)
1265    0791  29        		add	hl,hl
1266    0792  29        		add	hl,hl
1267    0793  010800    		ld	bc,_ebrrecs
1268    0796  09        		add	hl,bc
1269    0797  E5        		push	hl
1270    0798  210000    		ld	hl,_curblkno
1271    079B  CD0000    		call	_memcpy
1272    079E  F1        		pop	af
1273    079F  F1        		pop	af
1274                    	;  264              curblkok = YES;
1275    07A0  210100    		ld	hl,1
1276    07A3  220000    		ld	(_curblkok),hl
1277                    	;  265              }
1278                    	;  266          else
1279                    	;  267              return;
1280                    	;  268          entp = &sdrdbuf[0x01be] ;
1281    07A6  21BE01    		ld	hl,_sdrdbuf+446
1282    07A9  DD75F0    		ld	(ix-16),l
1283    07AC  DD74F1    		ld	(ix-15),h
1284                    	;  269          for (partidx = 1; (partidx <= 4) && (partpar < 16); partidx++, entp += 16)
1285    07AF  DD36F801  		ld	(ix-8),1
1286    07B3  DD36F900  		ld	(ix-7),0
1287                    	L106:
1288    07B7  3E04      		ld	a,4
1289    07B9  DD96F8    		sub	(ix-8)
1290    07BC  3E00      		ld	a,0
1291    07BE  DD9EF9    		sbc	a,(ix-7)
1292    07C1  FAF107    		jp	m,L145
1293    07C4  3A0000    		ld	a,(_partpar)
1294    07C7  D610      		sub	16
1295    07C9  3A0100    		ld	a,(_partpar+1)
1296    07CC  DE00      		sbc	a,0
1297    07CE  F2F107    		jp	p,L145
1298                    	;  270              {
1299                    	;  271              enttype = sdmbrentry(entp);
1300    07D1  DD6EF0    		ld	l,(ix-16)
1301    07D4  DD66F1    		ld	h,(ix-15)
1302    07D7  CDE502    		call	_sdmbrentry
1303    07DA  DD71F2    		ld	(ix-14),c
1304    07DD  DD70F3    		ld	(ix-13),b
1305                    	;  272              if (enttype == -1) /* read error */
1306    07E0  DD7EF2    		ld	a,(ix-14)
1307    07E3  FEFF      		cp	255
1308    07E5  2005      		jr	nz,L62
1309    07E7  DD7EF3    		ld	a,(ix-13)
1310    07EA  FEFF      		cp	255
1311                    	L62:
1312    07EC  2030      		jr	nz,L146
1313                    	;  273                   return;
1314    07EE  C30000    		jp	c.rets
1315                    	L145:
1316    07F1  DD34F8    		inc	(ix-8)
1317    07F4  2003      		jr	nz,L22
1318    07F6  DD34F9    		inc	(ix-7)
1319                    	L22:
1320    07F9  C35207    		jp	L125
1321                    	L165:
1322    07FC  C30000    		jp	c.rets
1323                    	L126:
1324    07FF  DD34F8    		inc	(ix-8)
1325    0802  2003      		jr	nz,L42
1326    0804  DD34F9    		inc	(ix-7)
1327                    	L42:
1328    0807  DD6EF0    		ld	l,(ix-16)
1329    080A  DD66F1    		ld	h,(ix-15)
1330    080D  7D        		ld	a,l
1331    080E  C610      		add	a,16
1332    0810  6F        		ld	l,a
1333    0811  7C        		ld	a,h
1334    0812  CE00      		adc	a,0
1335    0814  67        		ld	h,a
1336    0815  DD75F0    		ld	(ix-16),l
1337    0818  DD74F1    		ld	(ix-15),h
1338    081B  C3B707    		jp	L106
1339                    	L146:
1340                    	;  274              else if (enttype == PARTZRO) /* empty partition entry */
1341    081E  DD7EF2    		ld	a,(ix-14)
1342    0821  DDB6F3    		or	(ix-13)
1343    0824  28CB      		jr	z,L145
1344                    	;  275                  break;
1345                    	;  276              else if (enttype == PARTEBR) /* next chained EBR */
1346    0826  DD7EF2    		ld	a,(ix-14)
1347    0829  FE02      		cp	2
1348    082B  2005      		jr	nz,L03
1349    082D  DD7EF3    		ld	a,(ix-13)
1350    0830  FE00      		cp	0
1351                    	L03:
1352    0832  20CB      		jr	nz,L126
1353                    	;  277                  /* follow the EBR chain */
1354                    	;  278                  {
1355                    	;  279                  for (chainidx = 0;
1356    0834  DD36F400  		ld	(ix-12),0
1357    0838  DD36F500  		ld	(ix-11),0
1358                    	L117:
1359                    	;  280                      (chainidx < 16) && (partpar < 16);
1360    083C  DD7EF4    		ld	a,(ix-12)
1361    083F  D610      		sub	16
1362    0841  DD7EF5    		ld	a,(ix-11)
1363    0844  DE00      		sbc	a,0
1364    0846  F2FF07    		jp	p,L126
1365    0849  3A0000    		ld	a,(_partpar)
1366    084C  D610      		sub	16
1367    084E  3A0100    		ld	a,(_partpar+1)
1368    0851  DE00      		sbc	a,0
1369    0853  F2FF07    		jp	p,L126
1370                    	;  281                      chainidx++)
1371                    	;  282                      {
1372                    	;  283                      /* ugly hack to stop reading the same sector */
1373                    	;  284                      if (!memcmp(ebrnext, curblkno, 4))
1374    0856  210400    		ld	hl,4
1375    0859  E5        		push	hl
1376    085A  210000    		ld	hl,_curblkno
1377    085D  E5        		push	hl
1378    085E  210200    		ld	hl,_ebrnext
1379    0861  CD0000    		call	_memcmp
1380    0864  F1        		pop	af
1381    0865  F1        		pop	af
1382    0866  79        		ld	a,c
1383    0867  B0        		or	b
1384    0868  200D      		jr	nz,L157
1385                    	;  285                           break;
1386    086A  C3FF07    		jp	L126
1387                    	L137:
1388    086D  DD34F4    		inc	(ix-12)
1389    0870  2003      		jr	nz,L23
1390    0872  DD34F5    		inc	(ix-11)
1391                    	L23:
1392    0875  18C5      		jr	L117
1393                    	L157:
1394                    	;  286                      if (sdread(sdrdbuf, ebrnext))
1395    0877  210200    		ld	hl,_ebrnext
1396    087A  E5        		push	hl
1397    087B  210000    		ld	hl,_sdrdbuf
1398    087E  CD0000    		call	_sdread
1399    0881  F1        		pop	af
1400    0882  79        		ld	a,c
1401    0883  B0        		or	b
1402    0884  285E      		jr	z,L167
1403                    	;  287                          {
1404                    	;  288                          memcpy(curblkno, ebrnext, 4);
1405    0886  210400    		ld	hl,4
1406    0889  E5        		push	hl
1407    088A  210200    		ld	hl,_ebrnext
1408    088D  E5        		push	hl
1409    088E  210000    		ld	hl,_curblkno
1410    0891  CD0000    		call	_memcpy
1411    0894  F1        		pop	af
1412    0895  F1        		pop	af
1413                    	;  289                          curblkok = YES;
1414    0896  210100    		ld	hl,1
1415    0899  220000    		ld	(_curblkok),hl
1416                    	;  290                          }
1417                    	;  291                      else
1418                    	;  292                          return;
1419                    	;  293                      entp = &sdrdbuf[0x01be] ;
1420    089C  21BE01    		ld	hl,_sdrdbuf+446
1421    089F  DD75F0    		ld	(ix-16),l
1422    08A2  DD74F1    		ld	(ix-15),h
1423                    	;  294                      for (cpartidx = 1;
1424    08A5  DD36F601  		ld	(ix-10),1
1425    08A9  DD36F700  		ld	(ix-9),0
1426                    	L1001:
1427                    	;  295                          (cpartidx <= 4) && (partpar < 16);
1428    08AD  3E04      		ld	a,4
1429    08AF  DD96F6    		sub	(ix-10)
1430    08B2  3E00      		ld	a,0
1431    08B4  DD9EF7    		sbc	a,(ix-9)
1432    08B7  FA6D08    		jp	m,L137
1433    08BA  3A0000    		ld	a,(_partpar)
1434    08BD  D610      		sub	16
1435    08BF  3A0100    		ld	a,(_partpar+1)
1436    08C2  DE00      		sbc	a,0
1437    08C4  F26D08    		jp	p,L137
1438                    	;  296                          cpartidx++, entp += 16)
1439                    	;  297                          {
1440                    	;  298                          enttype = sdmbrentry(entp);
1441    08C7  DD6EF0    		ld	l,(ix-16)
1442    08CA  DD66F1    		ld	h,(ix-15)
1443    08CD  CDE502    		call	_sdmbrentry
1444    08D0  DD71F2    		ld	(ix-14),c
1445    08D3  DD70F3    		ld	(ix-13),b
1446                    	;  299                          if (enttype == -1) /* read error */
1447    08D6  DD7EF2    		ld	a,(ix-14)
1448    08D9  FEFF      		cp	255
1449    08DB  2005      		jr	nz,L63
1450    08DD  DD7EF3    		ld	a,(ix-13)
1451    08E0  FEFF      		cp	255
1452                    	L63:
1453    08E2  2003      		jr	nz,L1201
1454                    	L167:
1455                    	;  300                              return;
1456    08E4  C30000    		jp	c.rets
1457                    	L1201:
1458    08E7  DD34F6    		inc	(ix-10)
1459    08EA  2003      		jr	nz,L43
1460    08EC  DD34F7    		inc	(ix-9)
1461                    	L43:
1462    08EF  DD6EF0    		ld	l,(ix-16)
1463    08F2  DD66F1    		ld	h,(ix-15)
1464    08F5  7D        		ld	a,l
1465    08F6  C610      		add	a,16
1466    08F8  6F        		ld	l,a
1467    08F9  7C        		ld	a,h
1468    08FA  CE00      		adc	a,0
1469    08FC  67        		ld	h,a
1470    08FD  DD75F0    		ld	(ix-16),l
1471    0900  DD74F1    		ld	(ix-15),h
1472    0903  18A8      		jr	L1001
1473                    	L135:
1474                    	;  301                          }
1475                    	;  302                      }
1476                    	;  303                  }
1477                    	;  304              }
1478                    	;  305          }
1479                    	;  306      }
1480    0905  C30000    		jp	c.rets
1481                    	;  307  
1482                    	;  308  /* Find partitions on SD card
1483                    	;  309   */
1484                    	;  310  void sdpartfind()
1485                    	;  311      {
1486                    	_sdpartfind:
1487                    	;  312      ebrrecidx = 0;
1488                    	;  313      partpar = 0;
1489                    	;    1  /*  z80sdpart.c Identify partitions on SD card.
1490                    	;    2   *
1491                    	;    3   *  Boot code for my DIY Z80 Computer. This
1492                    	;    4   *  program is compiled with Whitesmiths/COSMIC
1493                    	;    5   *  C compiler for Z80.
1494                    	;    6   *
1495                    	;    7   *  Detects the partitioning of an attached SD card.
1496                    	;    8   *
1497                    	;    9   *  You are free to use, modify, and redistribute
1498                    	;   10   *  this source code. No warranties are given.
1499                    	;   11   *  Hastily Cobbled Together 2021 and 2022
1500                    	;   12   *  by Hans-Ake Lund
1501                    	;   13   *
1502                    	;   14   */
1503                    	;   15  
1504                    	;   16  #include <std.h>
1505                    	;   17  #include "z80comp.h"
1506                    	;   18  #include "z80sd.h"
1507                    	;   19  
1508                    	;   20  struct partentry *parptr;       /* Partition map pointer */
1509                    	;   21  
1510                    	;   22  struct guidentry guidmap[16];   /* Map of GUIDs for GPT partitions */
1511                    	;   23  
1512                    	;   24  /* Detected EBR records to process */
1513                    	;   25  struct ebrentry
1514                    	;   26      {
1515                    	;   27      unsigned char ebrblk[4];
1516                    	;   28      } ebrrecs[4];
1517                    	;   29  
1518                    	;   30  unsigned char dsksign[4];      /* MBR/EBR disk signature */
1519                    	;   31  
1520                    	;   32  /* blockno 0, used to compare */
1521                    	;   33  const unsigned char blkzero[4] = {0x00, 0x00, 0x00, 0x00};
1522                    	;   34  /* blockno 1, used to increment/decrement */
1523                    	;   35  const unsigned char blkone[4] = {0x00, 0x00, 0x00, 0x01};
1524                    	;   36  
1525                    	;   37  /* Partition identifiers
1526                    	;   38   */
1527                    	;   39  
1528                    	;   40  /* CP/M partition */
1529                    	;   41  const unsigned char mbrcpm = 0x52;
1530                    	;   42  /* For MBR/EBR the partition type for CP/M is 0x52
1531                    	;   43   * according to: https://en.wikipedia.org/wiki/Partition_type
1532                    	;   44   */
1533                    	;   45  
1534                    	;   46  /* Z80 executable code partition */
1535                    	;   47  const unsigned char mbrexcode = 0x5f;
1536                    	;   48  /* My own "invention", has a special format that
1537                    	;   49   * includes number of bytes to load and a signature
1538                    	;   50   * that is a jump to the executable part
1539                    	;   51   */
1540                    	;   52  
1541                    	;   53  /* For GPT I have defined that a CP/M partition
1542                    	;   54   * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
1543                    	;   55   */
1544                    	;   56  const unsigned char gptcpm[] =
1545                    	;   57      {
1546                    	;   58      0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
1547                    	;   59      0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
1548                    	;   60      };
1549                    	;   61  
1550                    	;   62  /* For GPT I have also defined that a executable partition
1551                    	;   63   * has GUID: 0185D755-3CAC-41F5-94D9-6F7D906868E8
1552                    	;   64   */
1553                    	;   65  const unsigned char gptexcode[] =
1554                    	;   66      {
1555                    	;   67      0x55, 0xd7, 0x85, 0x01, 0xac, 0x3c, 0xf5, 0x41,
1556                    	;   68      0x94, 0xd9, 0x6f, 0x7d, 0x90, 0x68, 0x68, 0xe8
1557                    	;   69      };
1558                    	;   70  
1559                    	;   71  int ebrrecidx; /* how many EBR records that are populated */
1560                    	;   72  unsigned char ebrnext[4]; /* next chained ebr record */
1561                    	;   73  
1562                    	;   74  /* Variables
1563                    	;   75   */
1564                    	;   76  int partpar;   /* partition/disk number, 0 = disk A */
1565                    	;   77  
1566                    	;   78  unsigned long blk2ul(unsigned char*);
1567                    	;   79  
1568                    	;   80  /* Analyze and record GPT entry
1569                    	;   81   */
1570                    	;   82  int gptentry(unsigned int entryno)
1571                    	;   83      {
1572                    	;   84      int index;
1573                    	;   85      int entryidx;
1574                    	;   86      int hasname;
1575                    	;   87      unsigned char blkno[4];
1576                    	;   88      unsigned char *rxdata;
1577                    	;   89      unsigned char *entryptr;
1578                    	;   90      unsigned char tstzero = 0;
1579                    	;   91      unsigned long llba;
1580                    	;   92  
1581                    	;   93      ul2blk(blkno, (unsigned long)(2 + (entryno / 4)));
1582                    	;   94      if (!sdread(sdrdbuf, blkno))
1583                    	;   95          return (NO);
1584                    	;   96      rxdata = sdrdbuf;
1585                    	;   97      entryptr = rxdata + (128 * (entryno % 4));
1586                    	;   98      for (index = 0; index < 16; index++)
1587                    	;   99          tstzero |= entryptr[index];
1588                    	;  100      if (!tstzero)
1589                    	;  101          return (NO);
1590                    	;  102      if (entryptr[48] & 0x04)
1591                    	;  103          parptr[partpar].bootable = YES;
1592                    	;  104      parptr[partpar].parident = PARTGPT;
1593                    	;  105      /* lower 32 bits of LBA should be sufficient (I hope) */
1594                    	;  106      /* partitions are using LSB while SD block are using MSB */
1595                    	;  107      part2blk(parptr[partpar].parstart, &entryptr[32]);
1596                    	;  108      part2blk(parptr[partpar].parend, &entryptr[40]);
1597                    	;  109      part2blk(parptr[partpar].parsize, &entryptr[40]);
1598                    	;  110      subblk(parptr[partpar].parsize, parptr[partpar].parstart);
1599                    	;  111      addblk(parptr[partpar].parsize, blkone);
1600                    	;  112      memcpy(guidmap[partpar].parguid, &entryptr[0], 16);
1601                    	;  113      if (!memcmp(guidmap[partpar].parguid, gptcpm, 16))
1602                    	;  114          parptr[partpar].partype = mbrcpm;
1603                    	;  115      else if (!memcmp(guidmap[partpar].parguid, gptexcode, 16))
1604                    	;  116          parptr[partpar].partype = mbrexcode;
1605                    	;  117      partpar++;
1606                    	;  118      return (YES);
1607                    	;  119      }
1608                    	;  120  
1609                    	;  121  /* Analyze and GPT header
1610                    	;  122   */
1611                    	;  123  void sdgpthdr(unsigned char *blkno)
1612                    	;  124      {
1613                    	;  125      int index;
1614                    	;  126      unsigned int partno;
1615                    	;  127      unsigned char *rxdata;
1616                    	;  128      unsigned long entries;
1617                    	;  129  
1618                    	;  130      if (!sdread(sdrdbuf, blkno))
1619                    	;  131          return;
1620                    	;  132      rxdata = sdrdbuf;
1621                    	;  133      for (partno = 0; (partno < 16) && (partpar < 16); partno++)
1622                    	;  134          {
1623                    	;  135          if (!gptentry(partno))
1624                    	;  136              return;
1625                    	;  137          }
1626                    	;  138      }
1627                    	;  139  
1628                    	;  140  /* Analyze and print MBR partition entry
1629                    	;  141   * Returns:
1630                    	;  142   *    -1 if errror - should not happen
1631                    	;  143   *     0 if not used entry
1632                    	;  144   *     1 if MBR entry
1633                    	;  145   *     2 if EBR entry
1634                    	;  146   *     3 if GTP entry
1635                    	;  147   */
1636                    	;  148  int sdmbrentry(unsigned char *partptr)
1637                    	;  149      {
1638                    	;  150      int index;
1639                    	;  151      int parttype;
1640                    	;  152  
1641                    	;  153      parttype = PARTMBR;
1642                    	;  154      if (!partptr[4])
1643                    	;  155          return (PARTZRO);
1644                    	;  156      if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
1645                    	;  157          {
1646                    	;  158          if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
1647                    	;  159              {
1648                    	;  160              parttype = PARTEBR;
1649                    	;  161              if (memcmp(curblkno, blkzero, 4) == 0) /* points to EBR in the MBR */
1650                    	;  162                  {
1651                    	;  163                  memset(ebrnext, 0, 4);
1652                    	;  164                  parptr[partpar].parident = EBRCONT;
1653                    	;  165                  part2blk(parptr[partpar].parstart, &partptr[8]);
1654                    	;  166                  part2blk(parptr[partpar].parsize, &partptr[12]);
1655                    	;  167                  part2blk(parptr[partpar].parend, &partptr[8]);
1656                    	;  168                  addblk(parptr[partpar].parend, parptr[partpar].parsize);
1657                    	;  169                  subblk(parptr[partpar].parend, blkone);
1658                    	;  170                  parptr[partpar].partype = partptr[4];
1659                    	;  171                  partpar++;
1660                    	;  172                  /* save to handle later */
1661                    	;  173                  part2blk(ebrrecs[ebrrecidx++].ebrblk, &partptr[8]);
1662                    	;  174                  }
1663                    	;  175              else
1664                    	;  176                  {
1665                    	;  177                  part2blk(ebrnext, &partptr[8]);
1666                    	;  178                  addblk(ebrnext, curblkno);
1667                    	;  179                  }
1668                    	;  180              }
1669                    	;  181          else
1670                    	;  182              {
1671                    	;  183              if (memcmp(&partptr[12], blkzero, 4)) /* ugly hack to avoid empty partitions */
1672                    	;  184                  {
1673                    	;  185                  if (partptr[0] & 0x80)
1674                    	;  186                      parptr[partpar].bootable = YES;
1675                    	;  187                  if (!memcmp(curblkno, blkzero, 4))
1676                    	;  188                      parptr[partpar].parident = PARTMBR;
1677                    	;  189                  else
1678                    	;  190                      parptr[partpar].parident = PARTEBR;
1679                    	;  191                  part2blk(parptr[partpar].parstart, &partptr[8]);
1680                    	;  192                  addblk(parptr[partpar].parstart, curblkno);
1681                    	;  193                  part2blk(parptr[partpar].parsize, &partptr[12]);
1682                    	;  194                  part2blk(parptr[partpar].parend, &partptr[12]);
1683                    	;  195                  addblk(parptr[partpar].parend, parptr[partpar].parstart);
1684                    	;  196                  subblk(parptr[partpar].parend, blkone);
1685                    	;  197                  parptr[partpar].partype = partptr[4];
1686                    	;  198                  partpar++;
1687                    	;  199                  }
1688                    	;  200              }
1689                    	;  201          }
1690                    	;  202  
1691                    	;  203      if (partptr[4] == 0xee) /* GPT partitions */
1692                    	;  204          {
1693                    	;  205          parttype = PARTGPT;
1694                    	;  206          sdgpthdr(parptr[partpar].parstart); /* handle GTP partitions */
1695                    	;  207          /* re-read MBR on sector 0
1696                    	;  208             This is probably not needed as there
1697                    	;  209             is only one entry (the first one)
1698                    	;  210             in the MBR when using GPT */
1699                    	;  211          if (sdread(sdrdbuf, 0))
1700                    	;  212              {
1701                    	;  213              memset(curblkno, 0, 4);
1702                    	;  214              curblkok = YES;
1703                    	;  215              }
1704                    	;  216          else
1705                    	;  217              return(-1);
1706                    	;  218          }
1707                    	;  219      return (parttype);
1708                    	;  220      }
1709                    	;  221  
1710                    	;  222  /* Read and analyze MBR/EBR partition sector block
1711                    	;  223   * and go through and print partition entries.
1712                    	;  224   */
1713                    	;  225  void sdmbrpart(unsigned char *sector)
1714                    	;  226      {
1715                    	;  227      int partidx;  /* partition index 1 - 4 */
1716                    	;  228      int cpartidx; /* chain partition index 1 - 4 */
1717                    	;  229      int chainidx;
1718                    	;  230      int enttype;
1719                    	;  231      unsigned char *entp; /* pointer to partition entry */
1720                    	;  232      char *mbrebr;
1721                    	;  233  
1722                    	;  234      if (sdread(sdrdbuf, sector))
1723                    	;  235          {
1724                    	;  236          memcpy(curblkno, sector, 4);
1725                    	;  237          curblkok = YES;
1726                    	;  238          }
1727                    	;  239      else
1728                    	;  240          return;
1729                    	;  241      if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
1730                    	;  242          return;
1731                    	;  243      if (memcmp(curblkno, blkzero, 4) == 0)
1732                    	;  244          memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
1733                    	;  245      /* go through MBR partition entries until first empty */
1734                    	;  246      /* !!as the MBR entry routine is called recusively a way is
1735                    	;  247         needed to read sector 0 when going back to MBR if
1736                    	;  248         there is a primary partition entry after an EBR entry!! */
1737                    	;  249      entp = &sdrdbuf[0x01be] ;
1738                    	;  250      for (partidx = 1; (partidx <= 4) && (partpar < 16); partidx++, entp += 16)
1739                    	;  251          {
1740                    	;  252          enttype = sdmbrentry(entp);
1741                    	;  253          if (enttype == -1) /* read error */
1742                    	;  254              return;
1743                    	;  255          else if (enttype == PARTZRO)
1744                    	;  256              break;
1745                    	;  257          }
1746                    	;  258      /* now handle the previously saved EBR partition sectors */
1747                    	;  259      for (partidx = 0; (partidx < ebrrecidx) && (partpar < 16); partidx++)
1748                    	;  260          {
1749                    	;  261          if (sdread(sdrdbuf, ebrrecs[partidx].ebrblk))
1750                    	;  262              {
1751                    	;  263              memcpy(curblkno, ebrrecs[partidx].ebrblk, 4);
1752                    	;  264              curblkok = YES;
1753                    	;  265              }
1754                    	;  266          else
1755                    	;  267              return;
1756                    	;  268          entp = &sdrdbuf[0x01be] ;
1757                    	;  269          for (partidx = 1; (partidx <= 4) && (partpar < 16); partidx++, entp += 16)
1758                    	;  270              {
1759                    	;  271              enttype = sdmbrentry(entp);
1760                    	;  272              if (enttype == -1) /* read error */
1761                    	;  273                   return;
1762                    	;  274              else if (enttype == PARTZRO) /* empty partition entry */
1763                    	;  275                  break;
1764                    	;  276              else if (enttype == PARTEBR) /* next chained EBR */
1765                    	;  277                  /* follow the EBR chain */
1766                    	;  278                  {
1767                    	;  279                  for (chainidx = 0;
1768                    	;  280                      (chainidx < 16) && (partpar < 16);
1769                    	;  281                      chainidx++)
1770                    	;  282                      {
1771                    	;  283                      /* ugly hack to stop reading the same sector */
1772                    	;  284                      if (!memcmp(ebrnext, curblkno, 4))
1773                    	;  285                           break;
1774                    	;  286                      if (sdread(sdrdbuf, ebrnext))
1775                    	;  287                          {
1776                    	;  288                          memcpy(curblkno, ebrnext, 4);
1777                    	;  289                          curblkok = YES;
1778                    	;  290                          }
1779                    	;  291                      else
1780                    	;  292                          return;
1781                    	;  293                      entp = &sdrdbuf[0x01be] ;
1782                    	;  294                      for (cpartidx = 1;
1783                    	;  295                          (cpartidx <= 4) && (partpar < 16);
1784                    	;  296                          cpartidx++, entp += 16)
1785                    	;  297                          {
1786                    	;  298                          enttype = sdmbrentry(entp);
1787                    	;  299                          if (enttype == -1) /* read error */
1788                    	;  300                              return;
1789                    	;  301                          }
1790                    	;  302                      }
1791                    	;  303                  }
1792                    	;  304              }
1793                    	;  305          }
1794                    	;  306      }
1795                    	;  307  
1796                    	;  308  /* Find partitions on SD card
1797                    	;  309   */
1798                    	;  310  void sdpartfind()
1799                    	;  311      {
1800                    	;  312      ebrrecidx = 0;
1801    0908  210000    		ld	hl,0
1802    090B  220600    		ld	(_ebrrecidx),hl
1803    090E  220000    		ld	(_partpar),hl
1804                    	;  313      partpar = 0;
1805                    	;  314      parptr = (void *) PARMAPADR;
1806    0911  97        		sub	a
1807    0912  321C01    		ld	(_parptr),a
1808    0915  3EFF      		ld	a,255
1809    0917  321D01    		ld	(_parptr+1),a
1810                    	;  315      memset(parptr, 0, PARMAPSIZE);
1811    091A  210001    		ld	hl,256
1812    091D  E5        		push	hl
1813    091E  210000    		ld	hl,0
1814    0921  E5        		push	hl
1815    0922  2A1C01    		ld	hl,(_parptr)
1816    0925  CD0000    		call	_memset
1817    0928  F1        		pop	af
1818    0929  F1        		pop	af
1819                    	;  316      sdmbrpart(blkzero);
1820    092A  210000    		ld	hl,_blkzero
1821    092D  CD6F06    		call	_sdmbrpart
1822                    	;  317      }
1823    0930  C9        		ret 
1824                    	;  318  
1825                    		.psect	_bss
1826                    	_partpar:
1827                    		.byte	[2]
1828                    	_ebrnext:
1829                    		.byte	[4]
1830                    	_ebrrecidx:
1831                    		.byte	[2]
1832                    	_ebrrecs:
1833                    		.byte	[16]
1834                    	_dsksign:
1835                    		.byte	[4]
1836                    	_guidmap:
1837                    		.byte	[256]
1838                    	_parptr:
1839                    		.byte	[2]
1840                    		.external	_curblkno
1841                    		.public	_sdgpthdr
1842                    		.external	_curblkok
1843                    		.public	_parptr
1844                    		.external	c.r0
1845                    		.public	_sdmbrpart
1846                    		.external	_ul2blk
1847                    		.external	_memset
1848                    		.external	_memcpy
1849                    		.public	_gptcpm
1850                    		.public	_sdmbrentry
1851                    		.external	_subblk
1852                    		.public	_gptexcode
1853                    		.public	_mbrcpm
1854                    		.external	_memcmp
1855                    		.public	_gptentry
1856                    		.public	_blkone
1857                    		.public	_partpar
1858                    		.public	_mbrexcode
1859                    		.public	_blkzero
1860                    		.public	_ebrrecidx
1861                    		.public	_ebrnext
1862                    		.public	_dsksign
1863                    		.external	_sdread
1864                    		.external	c.rets
1865                    		.public	_sdpartfind
1866                    		.external	c.savs
1867                    		.external	_sdrdbuf
1868                    		.external	c.udiv
1869                    		.external	c.imul
1870                    		.public	_guidmap
1871                    		.external	c.umod
1872                    		.public	_ebrrecs
1873                    		.external	_addblk
1874                    		.external	_part2blk
1875                    		.end
