   1                    	;    1  /*  z80sdrdwrv.c Z80 SD card read/write routines.
   2                    	;    2   *  Will also be used for BIOS but not tested yet.
   3                    	;    3   *
   4                    	;    4   *  SD card code for my DIY Z80 Computer. This
   5                    	;    5   *  program is compiled with Whitesmiths/COSMIC
   6                    	;    6   *  C compiler for Z80.
   7                    	;    7   *
   8                    	;    8   *  For SD card read/write and also detects the
   9                    	;    9   *  presence of an attached SD card.
  10                    	;   10   *
  11                    	;   11   *  You are free to use, modify, and redistribute
  12                    	;   12   *  this source code. No warranties are given.
  13                    	;   13   *  Hastily Cobbled Together 2021 and 2022
  14                    	;   14   *  by Hans-Ake Lund
  15                    	;   15   *
  16                    	;   16   */
  17                    	;   17  
  18                    	;   18  #include <std.h>
  19                    	;   19  #include "z80comp.h"
  20                    	;   20  #include "z80sd.h"
  21                    	;   21  
  22                    	;   22  /* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
  23                    	;   23   * (The CRC7 byte in the tables below are only for information,
  24                    	;   24   * it is calculated by the sdcommand routine.)
  25                    	;   25   */
  26                    	;   26  /* CMD 17: READ_SINGLE_BLOCK */
  27                    	;   27  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
  28                    		.psect	_text
  29                    	_cmd17:
  30    0000  51        		.byte	81
  31                    		.byte	[1]
  32                    		.byte	[1]
  33                    		.byte	[1]
  34                    		.byte	[1]
  35    0005  55        		.byte	85
  36                    	;   28  /* CMD 24: WRITE_SINGLE_BLOCK */
  37                    	;   29  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
  38                    	_cmd24:
  39    0006  58        		.byte	88
  40                    		.byte	[1]
  41                    		.byte	[1]
  42                    		.byte	[1]
  43                    		.byte	[1]
  44    000B  6F        		.byte	111
  45                    	;   30  /* CMD 58: READ_OCR */
  46                    	;   31  const unsigned char cmd58b[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
  47                    	_cmd58b:
  48    000C  7A        		.byte	122
  49                    		.byte	[1]
  50                    		.byte	[1]
  51                    		.byte	[1]
  52                    		.byte	[1]
  53    0011  FD        		.byte	253
  54                    	;   32  
  55                    	;   33  /* CRC routines from:
  56                    	;   34   * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
  57                    	;   35   */
  58                    	;   36  
  59                    	;   37  /*
  60                    	;   38  // Calculate CRC7
  61                    	;   39  // It's a 7 bit CRC with polynomial x^7 + x^3 + 1
  62                    	;   40  // input:
  63                    	;   41  //   crcIn - the CRC before (0 for first step)
  64                    	;   42  //   data - byte for CRC calculation
  65                    	;   43  // return: the new CRC7
  66                    	;   44  */
  67                    	;   45  unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
  68                    	;   46      {
  69                    	_CRC7_one:
  70    0012  CD0000    		call	c.savs
  71    0015  F5        		push	af
  72    0016  F5        		push	af
  73    0017  F5        		push	af
  74    0018  F5        		push	af
  75                    	;   47      const unsigned char g = 0x89;
  76    0019  DD36F989  		ld	(ix-7),137
  77                    	;   48      unsigned char i;
  78                    	;   49  
  79                    	;   50      crcIn ^= data;
  80    001D  DD7E04    		ld	a,(ix+4)
  81    0020  DDAE06    		xor	(ix+6)
  82    0023  DD7704    		ld	(ix+4),a
  83    0026  DD7E05    		ld	a,(ix+5)
  84    0029  DDAE07    		xor	(ix+7)
  85    002C  DD7705    		ld	(ix+5),a
  86                    	;   51      for (i = 0; i < 8; i++)
  87    002F  DD36F800  		ld	(ix-8),0
  88                    	L1:
  89    0033  DD7EF8    		ld	a,(ix-8)
  90    0036  FE08      		cp	8
  91    0038  302F      		jr	nc,L11
  92                    	;   52          {
  93                    	;   53          if (crcIn & 0x80) crcIn ^= g;
  94    003A  DD6E04    		ld	l,(ix+4)
  95    003D  DD6605    		ld	h,(ix+5)
  96    0040  CB7D      		bit	7,l
  97    0042  2813      		jr	z,L14
  98    0044  DD6EF9    		ld	l,(ix-7)
  99    0047  97        		sub	a
 100    0048  67        		ld	h,a
 101    0049  DD7E04    		ld	a,(ix+4)
 102    004C  AD        		xor	l
 103    004D  DD7704    		ld	(ix+4),a
 104    0050  DD7E05    		ld	a,(ix+5)
 105    0053  AC        		xor	h
 106    0054  DD7705    		ld	(ix+5),a
 107                    	L14:
 108                    	;   54          crcIn <<= 1;
 109    0057  DD6E04    		ld	l,(ix+4)
 110    005A  DD6605    		ld	h,(ix+5)
 111    005D  29        		add	hl,hl
 112    005E  DD7504    		ld	(ix+4),l
 113    0061  DD7405    		ld	(ix+5),h
 114                    	;   55          }
 115    0064  DD34F8    		inc	(ix-8)
 116    0067  18CA      		jr	L1
 117                    	L11:
 118                    	;   56  
 119                    	;   57      return crcIn;
 120    0069  DD6E04    		ld	l,(ix+4)
 121    006C  DD6605    		ld	h,(ix+5)
 122    006F  4D        		ld	c,l
 123    0070  44        		ld	b,h
 124    0071  C30000    		jp	c.rets
 125                    	;   58      }
 126                    	;   59  
 127                    	;   60  /*
 128                    	;   61  // Calculate CRC16 CCITT
 129                    	;   62  // It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
 130                    	;   63  // input:
 131                    	;   64  //   crcIn - the CRC before (0 for rist step)
 132                    	;   65  //   data - byte for CRC calculation
 133                    	;   66  // return: the CRC16 value
 134                    	;   67  */
 135                    	;   68  unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
 136                    	;   69      {
 137                    	_CRC16_one:
 138    0074  CD0000    		call	c.savs
 139                    	;   70      crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
 140    0077  DD6E04    		ld	l,(ix+4)
 141    007A  DD6605    		ld	h,(ix+5)
 142    007D  E5        		push	hl
 143    007E  210800    		ld	hl,8
 144    0081  E5        		push	hl
 145    0082  CD0000    		call	c.ursh
 146    0085  E1        		pop	hl
 147    0086  E5        		push	hl
 148    0087  DD6E04    		ld	l,(ix+4)
 149    008A  DD6605    		ld	h,(ix+5)
 150    008D  29        		add	hl,hl
 151    008E  29        		add	hl,hl
 152    008F  29        		add	hl,hl
 153    0090  29        		add	hl,hl
 154    0091  29        		add	hl,hl
 155    0092  29        		add	hl,hl
 156    0093  29        		add	hl,hl
 157    0094  29        		add	hl,hl
 158    0095  C1        		pop	bc
 159    0096  79        		ld	a,c
 160    0097  B5        		or	l
 161    0098  4F        		ld	c,a
 162    0099  78        		ld	a,b
 163    009A  B4        		or	h
 164    009B  47        		ld	b,a
 165    009C  DD7104    		ld	(ix+4),c
 166    009F  DD7005    		ld	(ix+5),b
 167                    	;   71      crcIn ^=  data;
 168    00A2  DD7E04    		ld	a,(ix+4)
 169    00A5  DDAE06    		xor	(ix+6)
 170    00A8  DD7704    		ld	(ix+4),a
 171    00AB  DD7E05    		ld	a,(ix+5)
 172    00AE  DDAE07    		xor	(ix+7)
 173    00B1  DD7705    		ld	(ix+5),a
 174                    	;   72      crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
 175    00B4  DD6E04    		ld	l,(ix+4)
 176    00B7  DD6605    		ld	h,(ix+5)
 177    00BA  7D        		ld	a,l
 178    00BB  E6FF      		and	255
 179    00BD  6F        		ld	l,a
 180    00BE  97        		sub	a
 181    00BF  67        		ld	h,a
 182    00C0  4D        		ld	c,l
 183    00C1  97        		sub	a
 184    00C2  47        		ld	b,a
 185    00C3  C5        		push	bc
 186    00C4  210400    		ld	hl,4
 187    00C7  E5        		push	hl
 188    00C8  CD0000    		call	c.irsh
 189    00CB  E1        		pop	hl
 190    00CC  DD7E04    		ld	a,(ix+4)
 191    00CF  AD        		xor	l
 192    00D0  DD7704    		ld	(ix+4),a
 193    00D3  DD7E05    		ld	a,(ix+5)
 194    00D6  AC        		xor	h
 195    00D7  DD7705    		ld	(ix+5),a
 196                    	;   73      crcIn ^= (crcIn << 8) << 4;
 197    00DA  DD6E04    		ld	l,(ix+4)
 198    00DD  DD6605    		ld	h,(ix+5)
 199    00E0  29        		add	hl,hl
 200    00E1  29        		add	hl,hl
 201    00E2  29        		add	hl,hl
 202    00E3  29        		add	hl,hl
 203    00E4  29        		add	hl,hl
 204    00E5  29        		add	hl,hl
 205    00E6  29        		add	hl,hl
 206    00E7  29        		add	hl,hl
 207    00E8  29        		add	hl,hl
 208    00E9  29        		add	hl,hl
 209    00EA  29        		add	hl,hl
 210    00EB  29        		add	hl,hl
 211    00EC  DD7E04    		ld	a,(ix+4)
 212    00EF  AD        		xor	l
 213    00F0  DD7704    		ld	(ix+4),a
 214    00F3  DD7E05    		ld	a,(ix+5)
 215    00F6  AC        		xor	h
 216    00F7  DD7705    		ld	(ix+5),a
 217                    	;   74      crcIn ^= ((crcIn & 0xff) << 4) << 1;
 218    00FA  DD6E04    		ld	l,(ix+4)
 219    00FD  DD6605    		ld	h,(ix+5)
 220    0100  7D        		ld	a,l
 221    0101  E6FF      		and	255
 222    0103  6F        		ld	l,a
 223    0104  97        		sub	a
 224    0105  67        		ld	h,a
 225    0106  29        		add	hl,hl
 226    0107  29        		add	hl,hl
 227    0108  29        		add	hl,hl
 228    0109  29        		add	hl,hl
 229    010A  29        		add	hl,hl
 230    010B  DD7E04    		ld	a,(ix+4)
 231    010E  AD        		xor	l
 232    010F  DD7704    		ld	(ix+4),a
 233    0112  DD7E05    		ld	a,(ix+5)
 234    0115  AC        		xor	h
 235    0116  DD7705    		ld	(ix+5),a
 236                    	;   75  
 237                    	;   76      return crcIn;
 238    0119  DD4E04    		ld	c,(ix+4)
 239    011C  DD4605    		ld	b,(ix+5)
 240    011F  C30000    		jp	c.rets
 241                    	;   77      }
 242                    	;   78  
 243                    	;   79  /* Send command to SD card and recieve answer.
 244                    	;   80   * A command is 5 bytes long and is followed by
 245                    	;   81   * a CRC7 checksum byte.
 246                    	;   82   * Returns a pointer to the response
 247                    	;   83   * or 0 if no response start bit found.
 248                    	;   84   */
 249                    	;   85  unsigned char *sdcommand(unsigned char *sdcmdp,
 250                    	;   86                           unsigned char *recbuf, int recbytes)
 251                    	;   87      {
 252                    	_sdcommand:
 253    0122  CD0000    		call	c.savs
 254    0125  21F2FF    		ld	hl,65522
 255    0128  39        		add	hl,sp
 256    0129  F9        		ld	sp,hl
 257                    	;   88      int searchn;  /* byte counter to search for response */
 258                    	;   89      int sdcbytes; /* byte counter for bytes to send */
 259                    	;   90      unsigned char *retptr; /* pointer used to store response */
 260                    	;   91      unsigned char rbyte;   /* recieved byte */
 261                    	;   92      unsigned char crc = 0; /* calculated CRC7 */
 262    012A  DD36F200  		ld	(ix-14),0
 263                    	;   93  
 264                    	;   94      /* send 8*2 clockpules */
 265                    	;   95      spiio(0xff);
 266    012E  21FF00    		ld	hl,255
 267    0131  CD0000    		call	_spiio
 268                    	;   96      spiio(0xff);
 269    0134  21FF00    		ld	hl,255
 270    0137  CD0000    		call	_spiio
 271                    	;   97      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
 272    013A  DD36F605  		ld	(ix-10),5
 273    013E  DD36F700  		ld	(ix-9),0
 274                    	L15:
 275    0142  97        		sub	a
 276    0143  DD96F6    		sub	(ix-10)
 277    0146  3E00      		ld	a,0
 278    0148  DD9EF7    		sbc	a,(ix-9)
 279    014B  F28701    		jp	p,L16
 280                    	;   98          {
 281                    	;   99          crc = CRC7_one(crc, *sdcmdp);
 282    014E  DD6E04    		ld	l,(ix+4)
 283    0151  DD6605    		ld	h,(ix+5)
 284    0154  6E        		ld	l,(hl)
 285    0155  97        		sub	a
 286    0156  67        		ld	h,a
 287    0157  E5        		push	hl
 288    0158  DD6EF2    		ld	l,(ix-14)
 289    015B  97        		sub	a
 290    015C  67        		ld	h,a
 291    015D  CD1200    		call	_CRC7_one
 292    0160  F1        		pop	af
 293    0161  DD71F2    		ld	(ix-14),c
 294                    	;  100          spiio(*sdcmdp++);
 295    0164  DD6E04    		ld	l,(ix+4)
 296    0167  DD6605    		ld	h,(ix+5)
 297    016A  DD3404    		inc	(ix+4)
 298    016D  2003      		jr	nz,L01
 299    016F  DD3405    		inc	(ix+5)
 300                    	L01:
 301    0172  6E        		ld	l,(hl)
 302    0173  97        		sub	a
 303    0174  67        		ld	h,a
 304    0175  CD0000    		call	_spiio
 305                    	;  101          }
 306    0178  DD6EF6    		ld	l,(ix-10)
 307    017B  DD66F7    		ld	h,(ix-9)
 308    017E  2B        		dec	hl
 309    017F  DD75F6    		ld	(ix-10),l
 310    0182  DD74F7    		ld	(ix-9),h
 311    0185  18BB      		jr	L15
 312                    	L16:
 313                    	;  102      spiio(crc | 0x01);
 314    0187  DD6EF2    		ld	l,(ix-14)
 315    018A  97        		sub	a
 316    018B  67        		ld	h,a
 317    018C  CBC5      		set	0,l
 318    018E  CD0000    		call	_spiio
 319                    	;  103      /* search for recieved byte with start bit
 320                    	;  104         for a maximum of 10 recieved bytes  */
 321                    	;  105      for (searchn = 10; 0 < searchn; searchn--)
 322    0191  DD36F80A  		ld	(ix-8),10
 323    0195  DD36F900  		ld	(ix-7),0
 324                    	L111:
 325    0199  97        		sub	a
 326    019A  DD96F8    		sub	(ix-8)
 327    019D  3E00      		ld	a,0
 328    019F  DD9EF9    		sbc	a,(ix-7)
 329    01A2  F2C401    		jp	p,L121
 330                    	;  106          {
 331                    	;  107          rbyte = spiio(0xff);
 332    01A5  21FF00    		ld	hl,255
 333    01A8  CD0000    		call	_spiio
 334    01AB  DD71F3    		ld	(ix-13),c
 335                    	;  108          if ((rbyte & 0x80) == 0)
 336    01AE  DD6EF3    		ld	l,(ix-13)
 337    01B1  CB7D      		bit	7,l
 338    01B3  280F      		jr	z,L121
 339                    	;  109              break;
 340                    	L131:
 341    01B5  DD6EF8    		ld	l,(ix-8)
 342    01B8  DD66F9    		ld	h,(ix-7)
 343    01BB  2B        		dec	hl
 344    01BC  DD75F8    		ld	(ix-8),l
 345    01BF  DD74F9    		ld	(ix-7),h
 346    01C2  18D5      		jr	L111
 347                    	L121:
 348                    	;  110          }
 349                    	;  111      if (searchn == 0) /* no start bit found */
 350    01C4  DD7EF8    		ld	a,(ix-8)
 351    01C7  DDB6F9    		or	(ix-7)
 352    01CA  2006      		jr	nz,L161
 353                    	;  112          return (NO);
 354    01CC  010000    		ld	bc,0
 355    01CF  C30000    		jp	c.rets
 356                    	L161:
 357                    	;  113      retptr = recbuf;
 358    01D2  DD7E06    		ld	a,(ix+6)
 359    01D5  DD77F4    		ld	(ix-12),a
 360    01D8  DD7E07    		ld	a,(ix+7)
 361    01DB  DD77F5    		ld	(ix-11),a
 362                    	;  114      *retptr++ = rbyte;
 363    01DE  DD6EF4    		ld	l,(ix-12)
 364    01E1  DD66F5    		ld	h,(ix-11)
 365    01E4  DD34F4    		inc	(ix-12)
 366    01E7  2003      		jr	nz,L21
 367    01E9  DD34F5    		inc	(ix-11)
 368                    	L21:
 369    01EC  DD7EF3    		ld	a,(ix-13)
 370    01EF  77        		ld	(hl),a
 371                    	L171:
 372                    	;  115      for (; 1 < recbytes; recbytes--) /* recieve bytes */
 373    01F0  3E01      		ld	a,1
 374    01F2  DD9608    		sub	(ix+8)
 375    01F5  3E00      		ld	a,0
 376    01F7  DD9E09    		sbc	a,(ix+9)
 377    01FA  F22302    		jp	p,L102
 378                    	;  116          *retptr++ = spiio(0xff);
 379    01FD  DD6EF4    		ld	l,(ix-12)
 380    0200  DD66F5    		ld	h,(ix-11)
 381    0203  DD34F4    		inc	(ix-12)
 382    0206  2003      		jr	nz,L41
 383    0208  DD34F5    		inc	(ix-11)
 384                    	L41:
 385    020B  E5        		push	hl
 386    020C  21FF00    		ld	hl,255
 387    020F  CD0000    		call	_spiio
 388    0212  E1        		pop	hl
 389    0213  71        		ld	(hl),c
 390    0214  DD6E08    		ld	l,(ix+8)
 391    0217  DD6609    		ld	h,(ix+9)
 392    021A  2B        		dec	hl
 393    021B  DD7508    		ld	(ix+8),l
 394    021E  DD7409    		ld	(ix+9),h
 395    0221  18CD      		jr	L171
 396                    	L102:
 397                    	;  117      return (recbuf);
 398    0223  DD4E06    		ld	c,(ix+6)
 399    0226  DD4607    		ld	b,(ix+7)
 400    0229  C30000    		jp	c.rets
 401                    	;  118      }
 402                    	;  119  
 403                    	;  120  
 404                    	;  121  /* Probe if SD card is inserted and initialized
 405                    	;  122   */
 406                    	;  123  int sdprobe()
 407                    	;  124      {
 408                    	_sdprobe:
 409    022C  CD0000    		call	c.savs0
 410    022F  21EAFF    		ld	hl,65514
 411    0232  39        		add	hl,sp
 412    0233  F9        		ld	sp,hl
 413                    	;  125      unsigned char cmdbuf[5];   /* buffer to build command in */
 414                    	;  126      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 415                    	;  127      unsigned char *statptr;    /* pointer to returned status from SD command */
 416                    	;  128      int nbytes;  /* byte counter */
 417                    	;  129      int allzero = YES;
 418    0234  DD36EA01  		ld	(ix-22),1
 419    0238  DD36EB00  		ld	(ix-21),0
 420                    	;  130  
 421                    	;  131      ledon();
 422    023C  CD0000    		call	_ledon
 423                    	;  132      spiselect();
 424    023F  CD0000    		call	_spiselect
 425                    	;  133  
 426                    	;  134      /* CMD 58: READ_OCR */
 427                    	;  135      memcpy(cmdbuf, cmd58b, 5);
 428    0242  210500    		ld	hl,5
 429    0245  E5        		push	hl
 430    0246  210C00    		ld	hl,_cmd58b
 431    0249  E5        		push	hl
 432    024A  DDE5      		push	ix
 433    024C  C1        		pop	bc
 434    024D  21F5FF    		ld	hl,65525
 435    0250  09        		add	hl,bc
 436    0251  CD0000    		call	_memcpy
 437    0254  F1        		pop	af
 438    0255  F1        		pop	af
 439                    	;  136      statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
 440    0256  210500    		ld	hl,5
 441    0259  E5        		push	hl
 442    025A  DDE5      		push	ix
 443    025C  C1        		pop	bc
 444    025D  21F0FF    		ld	hl,65520
 445    0260  09        		add	hl,bc
 446    0261  E5        		push	hl
 447    0262  DDE5      		push	ix
 448    0264  C1        		pop	bc
 449    0265  21F5FF    		ld	hl,65525
 450    0268  09        		add	hl,bc
 451    0269  CD2201    		call	_sdcommand
 452    026C  F1        		pop	af
 453    026D  F1        		pop	af
 454    026E  DD71EE    		ld	(ix-18),c
 455    0271  DD70EF    		ld	(ix-17),b
 456                    	;  137      for (nbytes = 0; nbytes < 5; nbytes++)
 457    0274  DD36EC00  		ld	(ix-20),0
 458    0278  DD36ED00  		ld	(ix-19),0
 459                    	L132:
 460    027C  DD7EEC    		ld	a,(ix-20)
 461    027F  D605      		sub	5
 462    0281  DD7EED    		ld	a,(ix-19)
 463    0284  DE00      		sbc	a,0
 464    0286  F2AC02    		jp	p,L142
 465                    	;  138          {
 466                    	;  139          if (statptr[nbytes] != 0)
 467    0289  DD6EEE    		ld	l,(ix-18)
 468    028C  DD66EF    		ld	h,(ix-17)
 469    028F  DD4EEC    		ld	c,(ix-20)
 470    0292  DD46ED    		ld	b,(ix-19)
 471    0295  09        		add	hl,bc
 472    0296  7E        		ld	a,(hl)
 473    0297  B7        		or	a
 474    0298  2808      		jr	z,L152
 475                    	;  140              allzero = NO;
 476    029A  DD36EA00  		ld	(ix-22),0
 477    029E  DD36EB00  		ld	(ix-21),0
 478                    	L152:
 479    02A2  DD34EC    		inc	(ix-20)
 480    02A5  2003      		jr	nz,L02
 481    02A7  DD34ED    		inc	(ix-19)
 482                    	L02:
 483    02AA  18D0      		jr	L132
 484                    	L142:
 485                    	;  141          }
 486                    	;  142      if (!statptr || allzero)
 487    02AC  DD7EEE    		ld	a,(ix-18)
 488    02AF  DDB6EF    		or	(ix-17)
 489    02B2  2808      		jr	z,L113
 490    02B4  DD7EEA    		ld	a,(ix-22)
 491    02B7  DDB6EB    		or	(ix-21)
 492    02BA  2811      		jr	z,L103
 493                    	L113:
 494                    	;  143          {
 495                    	;  144          *sdinitok = 0;
 496    02BC  2A0000    		ld	hl,(_sdinitok)
 497    02BF  3600      		ld	(hl),0
 498                    	;  145          spideselect();
 499    02C1  CD0000    		call	_spideselect
 500                    	;  146          ledoff();
 501    02C4  CD0000    		call	_ledoff
 502                    	;  147          return (NO);
 503    02C7  010000    		ld	bc,0
 504    02CA  C30000    		jp	c.rets0
 505                    	L103:
 506                    	;  148          }
 507                    	;  149  
 508                    	;  150      spideselect();
 509    02CD  CD0000    		call	_spideselect
 510                    	;  151      ledoff();
 511    02D0  CD0000    		call	_ledoff
 512                    	;  152  
 513                    	;  153      return (YES);
 514    02D3  010100    		ld	bc,1
 515    02D6  C30000    		jp	c.rets0
 516                    	;  154      }
 517                    	;  155  
 518                    	;  156  /* Read data block of 512 bytes to rdbuf
 519                    	;  157   * the block number is a 4 byte array
 520                    	;  158   * Returns YES if ok or NO if error
 521                    	;  159   */
 522                    	;  160  int sdread(unsigned char *rdbuf, unsigned char *rdblkno)
 523                    	;  161      {
 524                    	_sdread:
 525    02D9  CD0000    		call	c.savs
 526    02DC  21E4FF    		ld	hl,65508
 527    02DF  39        		add	hl,sp
 528    02E0  F9        		ld	sp,hl
 529                    	;  162      unsigned char *statptr;
 530                    	;  163      unsigned char rbyte;
 531                    	;  164      unsigned char cmdbuf[5];   /* buffer to build command in */
 532                    	;  165      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 533                    	;  166      int nbytes;
 534                    	;  167      int tries;
 535                    	;  168      unsigned int rxcrc16;
 536                    	;  169      unsigned int calcrc16;
 537                    	;  170  
 538                    	;  171      ledon();
 539    02E1  CD0000    		call	_ledon
 540                    	;  172      spiselect();
 541    02E4  CD0000    		call	_spiselect
 542                    	;  173  
 543                    	;  174      if (!*sdinitok)
 544    02E7  2A0000    		ld	hl,(_sdinitok)
 545    02EA  7E        		ld	a,(hl)
 546    02EB  B7        		or	a
 547    02EC  200C      		jr	nz,L123
 548                    	;  175          {
 549                    	;  176          spideselect();
 550    02EE  CD0000    		call	_spideselect
 551                    	;  177          ledoff();
 552    02F1  CD0000    		call	_ledoff
 553                    	;  178          return (NO);
 554    02F4  010000    		ld	bc,0
 555    02F7  C30000    		jp	c.rets
 556                    	L123:
 557                    	;  179          }
 558                    	;  180  
 559                    	;  181      /* CMD 17: READ_SINGLE_BLOCK */
 560                    	;  182      /* Insert block # into command */
 561                    	;  183      memcpy(cmdbuf, cmd17, 5);
 562    02FA  210500    		ld	hl,5
 563    02FD  E5        		push	hl
 564    02FE  210000    		ld	hl,_cmd17
 565    0301  E5        		push	hl
 566    0302  DDE5      		push	ix
 567    0304  C1        		pop	bc
 568    0305  21F2FF    		ld	hl,65522
 569    0308  09        		add	hl,bc
 570    0309  CD0000    		call	_memcpy
 571    030C  F1        		pop	af
 572    030D  F1        		pop	af
 573                    	;  184      if (*byteblkadr)
 574    030E  2A0000    		ld	hl,(_byteblkadr)
 575    0311  7E        		ld	a,(hl)
 576    0312  B7        		or	a
 577    0313  2809      		jr	z,L133
 578                    	;  185          blk2byte(rdblkno);
 579    0315  DD6E06    		ld	l,(ix+6)
 580    0318  DD6607    		ld	h,(ix+7)
 581    031B  CD0000    		call	_blk2byte
 582                    	L133:
 583                    	;  186      memcpy(&cmdbuf[1], rdblkno, 4);
 584    031E  210400    		ld	hl,4
 585    0321  E5        		push	hl
 586    0322  DD6E06    		ld	l,(ix+6)
 587    0325  DD6607    		ld	h,(ix+7)
 588    0328  E5        		push	hl
 589    0329  DDE5      		push	ix
 590    032B  C1        		pop	bc
 591    032C  21F3FF    		ld	hl,65523
 592    032F  09        		add	hl,bc
 593    0330  CD0000    		call	_memcpy
 594    0333  F1        		pop	af
 595    0334  F1        		pop	af
 596                    	;  187      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 597    0335  210100    		ld	hl,1
 598    0338  E5        		push	hl
 599    0339  DDE5      		push	ix
 600    033B  C1        		pop	bc
 601    033C  21EDFF    		ld	hl,65517
 602    033F  09        		add	hl,bc
 603    0340  E5        		push	hl
 604    0341  DDE5      		push	ix
 605    0343  C1        		pop	bc
 606    0344  21F2FF    		ld	hl,65522
 607    0347  09        		add	hl,bc
 608    0348  CD2201    		call	_sdcommand
 609    034B  F1        		pop	af
 610    034C  F1        		pop	af
 611    034D  DD71F8    		ld	(ix-8),c
 612    0350  DD70F9    		ld	(ix-7),b
 613                    	;  188      if (statptr[0])
 614    0353  DD6EF8    		ld	l,(ix-8)
 615    0356  DD66F9    		ld	h,(ix-7)
 616    0359  7E        		ld	a,(hl)
 617    035A  B7        		or	a
 618    035B  280C      		jr	z,L143
 619                    	;  189          {
 620                    	;  190          spideselect();
 621    035D  CD0000    		call	_spideselect
 622                    	;  191          ledoff();
 623    0360  CD0000    		call	_ledoff
 624                    	;  192          return (NO);
 625    0363  010000    		ld	bc,0
 626    0366  C30000    		jp	c.rets
 627                    	L143:
 628                    	;  193          }
 629                    	;  194      /* looking for 0xfe that is the byte before data */
 630                    	;  195      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
 631    0369  DD36E850  		ld	(ix-24),80
 632    036D  DD36E900  		ld	(ix-23),0
 633                    	L153:
 634    0371  97        		sub	a
 635    0372  DD96E8    		sub	(ix-24)
 636    0375  3E00      		ld	a,0
 637    0377  DD9EE9    		sbc	a,(ix-23)
 638    037A  F2B003    		jp	p,L163
 639    037D  21FF00    		ld	hl,255
 640    0380  CD0000    		call	_spiio
 641    0383  DD71F7    		ld	(ix-9),c
 642    0386  DD7EF7    		ld	a,(ix-9)
 643    0389  FEFE      		cp	254
 644    038B  2823      		jr	z,L163
 645                    	;  196          {
 646                    	;  197          if ((rbyte & 0xe0) == 0x00)
 647    038D  DD6EF7    		ld	l,(ix-9)
 648    0390  7D        		ld	a,l
 649    0391  E6E0      		and	224
 650    0393  200C      		jr	nz,L173
 651                    	;  198              {
 652                    	;  199              /* If a read operation fails and the card cannot provide
 653                    	;  200                 the required data, it will send a data error token instead
 654                    	;  201               */
 655                    	;  202              spideselect();
 656    0395  CD0000    		call	_spideselect
 657                    	;  203              ledoff();
 658    0398  CD0000    		call	_ledoff
 659                    	;  204              return (NO);
 660    039B  010000    		ld	bc,0
 661    039E  C30000    		jp	c.rets
 662                    	L173:
 663    03A1  DD6EE8    		ld	l,(ix-24)
 664    03A4  DD66E9    		ld	h,(ix-23)
 665    03A7  2B        		dec	hl
 666    03A8  DD75E8    		ld	(ix-24),l
 667    03AB  DD74E9    		ld	(ix-23),h
 668    03AE  18C1      		jr	L153
 669                    	L163:
 670                    	;  205              }
 671                    	;  206          }
 672                    	;  207      if (tries == 0) /* tried too many times */
 673    03B0  DD7EE8    		ld	a,(ix-24)
 674    03B3  DDB6E9    		or	(ix-23)
 675    03B6  200C      		jr	nz,L124
 676                    	;  208          {
 677                    	;  209          spideselect();
 678    03B8  CD0000    		call	_spideselect
 679                    	;  210          ledoff();
 680    03BB  CD0000    		call	_ledoff
 681                    	;  211          return (NO);
 682    03BE  010000    		ld	bc,0
 683    03C1  C30000    		jp	c.rets
 684                    	L124:
 685                    	;  212          }
 686                    	;  213      else
 687                    	;  214          {
 688                    	;  215          calcrc16 = 0;
 689    03C4  DD36E400  		ld	(ix-28),0
 690    03C8  DD36E500  		ld	(ix-27),0
 691                    	;  216          for (nbytes = 0; nbytes < 512; nbytes++)
 692    03CC  DD36EA00  		ld	(ix-22),0
 693    03D0  DD36EB00  		ld	(ix-21),0
 694                    	L144:
 695    03D4  DD7EEA    		ld	a,(ix-22)
 696    03D7  D600      		sub	0
 697    03D9  DD7EEB    		ld	a,(ix-21)
 698    03DC  DE02      		sbc	a,2
 699    03DE  F21B04    		jp	p,L154
 700                    	;  217              {
 701                    	;  218              rbyte = spiio(0xff);
 702    03E1  21FF00    		ld	hl,255
 703    03E4  CD0000    		call	_spiio
 704    03E7  DD71F7    		ld	(ix-9),c
 705                    	;  219              calcrc16 = CRC16_one(calcrc16, rbyte);
 706    03EA  DD6EF7    		ld	l,(ix-9)
 707    03ED  97        		sub	a
 708    03EE  67        		ld	h,a
 709    03EF  E5        		push	hl
 710    03F0  DD6EE4    		ld	l,(ix-28)
 711    03F3  DD66E5    		ld	h,(ix-27)
 712    03F6  CD7400    		call	_CRC16_one
 713    03F9  F1        		pop	af
 714    03FA  DD71E4    		ld	(ix-28),c
 715    03FD  DD70E5    		ld	(ix-27),b
 716                    	;  220              rdbuf[nbytes] = rbyte;
 717    0400  DD6E04    		ld	l,(ix+4)
 718    0403  DD6605    		ld	h,(ix+5)
 719    0406  DD4EEA    		ld	c,(ix-22)
 720    0409  DD46EB    		ld	b,(ix-21)
 721    040C  09        		add	hl,bc
 722    040D  DD7EF7    		ld	a,(ix-9)
 723    0410  77        		ld	(hl),a
 724                    	;  221              }
 725    0411  DD34EA    		inc	(ix-22)
 726    0414  2003      		jr	nz,L42
 727    0416  DD34EB    		inc	(ix-21)
 728                    	L42:
 729    0419  18B9      		jr	L144
 730                    	L154:
 731                    	;  222          rxcrc16 = spiio(0xff) << 8;
 732    041B  21FF00    		ld	hl,255
 733    041E  CD0000    		call	_spiio
 734    0421  69        		ld	l,c
 735    0422  60        		ld	h,b
 736    0423  29        		add	hl,hl
 737    0424  29        		add	hl,hl
 738    0425  29        		add	hl,hl
 739    0426  29        		add	hl,hl
 740    0427  29        		add	hl,hl
 741    0428  29        		add	hl,hl
 742    0429  29        		add	hl,hl
 743    042A  29        		add	hl,hl
 744    042B  DD75E6    		ld	(ix-26),l
 745    042E  DD74E7    		ld	(ix-25),h
 746                    	;  223          rxcrc16 += spiio(0xff);
 747    0431  21FF00    		ld	hl,255
 748    0434  CD0000    		call	_spiio
 749    0437  DD6EE6    		ld	l,(ix-26)
 750    043A  DD66E7    		ld	h,(ix-25)
 751    043D  09        		add	hl,bc
 752    043E  DD75E6    		ld	(ix-26),l
 753    0441  DD74E7    		ld	(ix-25),h
 754                    	;  224  
 755                    	;  225          if (rxcrc16 != calcrc16)
 756    0444  DD7EE6    		ld	a,(ix-26)
 757    0447  DDBEE4    		cp	(ix-28)
 758    044A  2006      		jr	nz,L62
 759    044C  DD7EE7    		ld	a,(ix-25)
 760    044F  DDBEE5    		cp	(ix-27)
 761                    	L62:
 762    0452  280C      		jr	z,L134
 763                    	;  226              {
 764                    	;  227              spideselect();
 765    0454  CD0000    		call	_spideselect
 766                    	;  228              ledoff();
 767    0457  CD0000    		call	_ledoff
 768                    	;  229              return (NO);
 769    045A  010000    		ld	bc,0
 770    045D  C30000    		jp	c.rets
 771                    	L134:
 772                    	;  230              }
 773                    	;  231          }
 774                    	;  232      spideselect();
 775    0460  CD0000    		call	_spideselect
 776                    	;  233      ledoff();
 777    0463  CD0000    		call	_ledoff
 778                    	;  234      return (YES);
 779    0466  010100    		ld	bc,1
 780    0469  C30000    		jp	c.rets
 781                    	;  235      }
 782                    	;  236  
 783                    	;  237  /* Write data block of 512 bytes from buffer
 784                    	;  238   * Returns YES if ok or NO if error
 785                    	;  239   */
 786                    	;  240  int sdwrite(unsigned char *wrbuf, unsigned char *wrblkno)
 787                    	;  241      {
 788                    	_sdwrite:
 789    046C  CD0000    		call	c.savs
 790    046F  21E6FF    		ld	hl,65510
 791    0472  39        		add	hl,sp
 792    0473  F9        		ld	sp,hl
 793                    	;  242      unsigned char *statptr;
 794                    	;  243      unsigned char rbyte;
 795                    	;  244      unsigned char tbyte;
 796                    	;  245      unsigned char cmdbuf[5];   /* buffer to build command in */
 797                    	;  246      unsigned char rstatbuf[5]; /* buffer to recieve status in */
 798                    	;  247      int nbytes;
 799                    	;  248      int tries;
 800                    	;  249      unsigned int calcrc16;
 801                    	;  250  
 802                    	;  251      ledon();
 803    0474  CD0000    		call	_ledon
 804                    	;  252      spiselect();
 805    0477  CD0000    		call	_spiselect
 806                    	;  253  
 807                    	;  254      if (!*sdinitok)
 808    047A  2A0000    		ld	hl,(_sdinitok)
 809    047D  7E        		ld	a,(hl)
 810    047E  B7        		or	a
 811    047F  200C      		jr	nz,L115
 812                    	;  255          {
 813                    	;  256          spideselect();
 814    0481  CD0000    		call	_spideselect
 815                    	;  257          ledoff();
 816    0484  CD0000    		call	_ledoff
 817                    	;  258          return (NO);
 818    0487  010000    		ld	bc,0
 819    048A  C30000    		jp	c.rets
 820                    	L115:
 821                    	;  259          }
 822                    	;  260      /* CMD 24: WRITE_SINGLE_BLOCK */
 823                    	;  261      /* Insert block # into command */
 824                    	;  262      memcpy(cmdbuf, cmd24, 5);
 825    048D  210500    		ld	hl,5
 826    0490  E5        		push	hl
 827    0491  210600    		ld	hl,_cmd24
 828    0494  E5        		push	hl
 829    0495  DDE5      		push	ix
 830    0497  C1        		pop	bc
 831    0498  21F1FF    		ld	hl,65521
 832    049B  09        		add	hl,bc
 833    049C  CD0000    		call	_memcpy
 834    049F  F1        		pop	af
 835    04A0  F1        		pop	af
 836                    	;  263      if (*byteblkadr)
 837    04A1  2A0000    		ld	hl,(_byteblkadr)
 838    04A4  7E        		ld	a,(hl)
 839    04A5  B7        		or	a
 840    04A6  2809      		jr	z,L125
 841                    	;  264          blk2byte(wrblkno);
 842    04A8  DD6E06    		ld	l,(ix+6)
 843    04AB  DD6607    		ld	h,(ix+7)
 844    04AE  CD0000    		call	_blk2byte
 845                    	L125:
 846                    	;  265      memcpy(&cmdbuf[1], wrblkno, 4);
 847    04B1  210400    		ld	hl,4
 848    04B4  E5        		push	hl
 849    04B5  DD6E06    		ld	l,(ix+6)
 850    04B8  DD6607    		ld	h,(ix+7)
 851    04BB  E5        		push	hl
 852    04BC  DDE5      		push	ix
 853    04BE  C1        		pop	bc
 854    04BF  21F2FF    		ld	hl,65522
 855    04C2  09        		add	hl,bc
 856    04C3  CD0000    		call	_memcpy
 857    04C6  F1        		pop	af
 858    04C7  F1        		pop	af
 859                    	;  266      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 860    04C8  210100    		ld	hl,1
 861    04CB  E5        		push	hl
 862    04CC  DDE5      		push	ix
 863    04CE  C1        		pop	bc
 864    04CF  21ECFF    		ld	hl,65516
 865    04D2  09        		add	hl,bc
 866    04D3  E5        		push	hl
 867    04D4  DDE5      		push	ix
 868    04D6  C1        		pop	bc
 869    04D7  21F1FF    		ld	hl,65521
 870    04DA  09        		add	hl,bc
 871    04DB  CD2201    		call	_sdcommand
 872    04DE  F1        		pop	af
 873    04DF  F1        		pop	af
 874    04E0  DD71F8    		ld	(ix-8),c
 875    04E3  DD70F9    		ld	(ix-7),b
 876                    	;  267      if (statptr[0])
 877    04E6  DD6EF8    		ld	l,(ix-8)
 878    04E9  DD66F9    		ld	h,(ix-7)
 879    04EC  7E        		ld	a,(hl)
 880    04ED  B7        		or	a
 881    04EE  280C      		jr	z,L135
 882                    	;  268          {
 883                    	;  269          spideselect();
 884    04F0  CD0000    		call	_spideselect
 885                    	;  270          ledoff();
 886    04F3  CD0000    		call	_ledoff
 887                    	;  271          return (NO);
 888    04F6  010000    		ld	bc,0
 889    04F9  C30000    		jp	c.rets
 890                    	L135:
 891                    	;  272          }
 892                    	;  273      /* send 0xfe, the byte before data */
 893                    	;  274      spiio(0xfe);
 894    04FC  21FE00    		ld	hl,254
 895    04FF  CD0000    		call	_spiio
 896                    	;  275      /* initialize crc and send block */
 897                    	;  276      calcrc16 = 0;
 898    0502  DD36E600  		ld	(ix-26),0
 899    0506  DD36E700  		ld	(ix-25),0
 900                    	;  277      for (nbytes = 0; nbytes < 512; nbytes++)
 901    050A  DD36EA00  		ld	(ix-22),0
 902    050E  DD36EB00  		ld	(ix-21),0
 903                    	L145:
 904    0512  DD7EEA    		ld	a,(ix-22)
 905    0515  D600      		sub	0
 906    0517  DD7EEB    		ld	a,(ix-21)
 907    051A  DE02      		sbc	a,2
 908    051C  F25805    		jp	p,L155
 909                    	;  278          {
 910                    	;  279          tbyte = wrbuf[nbytes];
 911    051F  DD6E04    		ld	l,(ix+4)
 912    0522  DD6605    		ld	h,(ix+5)
 913    0525  DD4EEA    		ld	c,(ix-22)
 914    0528  DD46EB    		ld	b,(ix-21)
 915    052B  09        		add	hl,bc
 916    052C  7E        		ld	a,(hl)
 917    052D  DD77F6    		ld	(ix-10),a
 918                    	;  280          spiio(tbyte);
 919    0530  DD6EF6    		ld	l,(ix-10)
 920    0533  97        		sub	a
 921    0534  67        		ld	h,a
 922    0535  CD0000    		call	_spiio
 923                    	;  281          calcrc16 = CRC16_one(calcrc16, tbyte);
 924    0538  DD6EF6    		ld	l,(ix-10)
 925    053B  97        		sub	a
 926    053C  67        		ld	h,a
 927    053D  E5        		push	hl
 928    053E  DD6EE6    		ld	l,(ix-26)
 929    0541  DD66E7    		ld	h,(ix-25)
 930    0544  CD7400    		call	_CRC16_one
 931    0547  F1        		pop	af
 932    0548  DD71E6    		ld	(ix-26),c
 933    054B  DD70E7    		ld	(ix-25),b
 934                    	;  282          }
 935    054E  DD34EA    		inc	(ix-22)
 936    0551  2003      		jr	nz,L23
 937    0553  DD34EB    		inc	(ix-21)
 938                    	L23:
 939    0556  18BA      		jr	L145
 940                    	L155:
 941                    	;  283      spiio((calcrc16 >> 8) & 0xff);
 942    0558  DD6EE6    		ld	l,(ix-26)
 943    055B  DD66E7    		ld	h,(ix-25)
 944    055E  E5        		push	hl
 945    055F  210800    		ld	hl,8
 946    0562  E5        		push	hl
 947    0563  CD0000    		call	c.ursh
 948    0566  E1        		pop	hl
 949    0567  7D        		ld	a,l
 950    0568  E6FF      		and	255
 951    056A  6F        		ld	l,a
 952    056B  97        		sub	a
 953    056C  67        		ld	h,a
 954    056D  CD0000    		call	_spiio
 955                    	;  284      spiio(calcrc16 & 0xff);
 956    0570  DD6EE6    		ld	l,(ix-26)
 957    0573  DD66E7    		ld	h,(ix-25)
 958    0576  7D        		ld	a,l
 959    0577  E6FF      		and	255
 960    0579  6F        		ld	l,a
 961    057A  97        		sub	a
 962    057B  67        		ld	h,a
 963    057C  CD0000    		call	_spiio
 964                    	;  285  
 965                    	;  286      /* check data resposnse */
 966                    	;  287      for (tries = 20;
 967    057F  DD36E814  		ld	(ix-24),20
 968    0583  DD36E900  		ld	(ix-23),0
 969                    	L106:
 970                    	;  288              0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
 971    0587  97        		sub	a
 972    0588  DD96E8    		sub	(ix-24)
 973    058B  3E00      		ld	a,0
 974    058D  DD9EE9    		sbc	a,(ix-23)
 975    0590  F2C005    		jp	p,L116
 976    0593  21FF00    		ld	hl,255
 977    0596  CD0000    		call	_spiio
 978    0599  DD71F7    		ld	(ix-9),c
 979    059C  DD6EF7    		ld	l,(ix-9)
 980    059F  97        		sub	a
 981    05A0  67        		ld	h,a
 982    05A1  7D        		ld	a,l
 983    05A2  E611      		and	17
 984    05A4  6F        		ld	l,a
 985    05A5  97        		sub	a
 986    05A6  67        		ld	h,a
 987    05A7  7D        		ld	a,l
 988    05A8  FE01      		cp	1
 989    05AA  2003      		jr	nz,L43
 990    05AC  7C        		ld	a,h
 991    05AD  FE00      		cp	0
 992                    	L43:
 993    05AF  280F      		jr	z,L116
 994                    	;  289              tries--)
 995                    	L126:
 996    05B1  DD6EE8    		ld	l,(ix-24)
 997    05B4  DD66E9    		ld	h,(ix-23)
 998    05B7  2B        		dec	hl
 999    05B8  DD75E8    		ld	(ix-24),l
1000    05BB  DD74E9    		ld	(ix-23),h
1001    05BE  18C7      		jr	L106
1002                    	L116:
1003                    	;  290          ;
1004                    	;  291      if (tries == 0)
1005    05C0  DD7EE8    		ld	a,(ix-24)
1006    05C3  DDB6E9    		or	(ix-23)
1007    05C6  200C      		jr	nz,L146
1008                    	;  292          {
1009                    	;  293          spideselect();
1010    05C8  CD0000    		call	_spideselect
1011                    	;  294          ledoff();
1012    05CB  CD0000    		call	_ledoff
1013                    	;  295          return (NO);
1014    05CE  010000    		ld	bc,0
1015    05D1  C30000    		jp	c.rets
1016                    	L146:
1017                    	;  296          }
1018                    	;  297      else
1019                    	;  298          {
1020                    	;  299          if ((0x1f & rbyte) == 0x05)
1021    05D4  DD6EF7    		ld	l,(ix-9)
1022    05D7  97        		sub	a
1023    05D8  67        		ld	h,a
1024    05D9  7D        		ld	a,l
1025    05DA  E61F      		and	31
1026    05DC  6F        		ld	l,a
1027    05DD  97        		sub	a
1028    05DE  67        		ld	h,a
1029    05DF  7D        		ld	a,l
1030    05E0  FE05      		cp	5
1031    05E2  2003      		jr	nz,L63
1032    05E4  7C        		ld	a,h
1033    05E5  FE00      		cp	0
1034                    	L63:
1035    05E7  2035      		jr	nz,L166
1036                    	;  300              {
1037                    	;  301              for (nbytes = 9; 0 < nbytes; nbytes--)
1038    05E9  DD36EA09  		ld	(ix-22),9
1039    05ED  DD36EB00  		ld	(ix-21),0
1040                    	L176:
1041    05F1  97        		sub	a
1042    05F2  DD96EA    		sub	(ix-22)
1043    05F5  3E00      		ld	a,0
1044    05F7  DD9EEB    		sbc	a,(ix-21)
1045    05FA  F21206    		jp	p,L107
1046                    	;  302                  spiio(0xff);
1047    05FD  21FF00    		ld	hl,255
1048    0600  CD0000    		call	_spiio
1049    0603  DD6EEA    		ld	l,(ix-22)
1050    0606  DD66EB    		ld	h,(ix-21)
1051    0609  2B        		dec	hl
1052    060A  DD75EA    		ld	(ix-22),l
1053    060D  DD74EB    		ld	(ix-21),h
1054    0610  18DF      		jr	L176
1055                    	L107:
1056                    	;  303              spideselect();
1057    0612  CD0000    		call	_spideselect
1058                    	;  304              ledoff();
1059    0615  CD0000    		call	_ledoff
1060                    	;  305              return (YES);
1061    0618  010100    		ld	bc,1
1062    061B  C30000    		jp	c.rets
1063                    	L166:
1064                    	;  306              }
1065                    	;  307          else
1066                    	;  308              {
1067                    	;  309              spideselect();
1068    061E  CD0000    		call	_spideselect
1069                    	;  310              ledoff();
1070    0621  CD0000    		call	_ledoff
1071                    	;  311              return (NO);
1072    0624  010000    		ld	bc,0
1073    0627  C30000    		jp	c.rets
1074                    	;  312              }
1075                    	;  313          }
1076                    	;  314      }
1077                    	;  315  
1078                    		.external	c.rets0
1079                    		.public	_CRC16_one
1080                    		.external	_blk2byte
1081                    		.external	c.savs0
1082                    		.public	_cmd17
1083                    		.public	_cmd24
1084                    		.external	_spideselect
1085                    		.external	_ledon
1086                    		.external	_spiselect
1087                    		.external	_memcpy
1088                    		.public	_cmd58b
1089                    		.public	_sdwrite
1090                    		.public	_sdcommand
1091                    		.external	c.ursh
1092                    		.public	_sdread
1093                    		.external	_ledoff
1094                    		.external	c.rets
1095                    		.public	_CRC7_one
1096                    		.public	_sdprobe
1097                    		.external	c.savs
1098                    		.external	c.irsh
1099                    		.external	_sdinitok
1100                    		.external	_byteblkadr
1101                    		.external	_spiio
1102                    		.end
