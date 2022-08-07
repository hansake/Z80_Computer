   1                    	;    1  /*  z80sdrdwr.c Z80 SD card read/write routines.
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
  27                    	;   27  const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x01};
  28                    		.psect	_text
  29                    	_cmd17:
  30    0000  51        		.byte	81
  31                    		.byte	[1]
  32                    		.byte	[1]
  33                    		.byte	[1]
  34                    		.byte	[1]
  35    0005  01        		.byte	1
  36                    	;   28  /* CMD 24: WRITE_SINGLE_BLOCK */
  37                    	;   29  const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x01};
  38                    	_cmd24:
  39    0006  58        		.byte	88
  40                    		.byte	[1]
  41                    		.byte	[1]
  42                    		.byte	[1]
  43                    		.byte	[1]
  44    000B  01        		.byte	1
  45                    	;   30  
  46                    	;   31  /* Variables for the SD card, these variables are set by the
  47                    	;   32   * initialization code.
  48                    	;   33   */
  49                    	;   34  char *sdinitok;      /* SD card initialized and ready */
  50                    	;   35  char *byteblkadr;    /* block address multiplier flag */
  51                    	;   36  
  52                    	;   37  /* These are really local variables but CP/M uses a minimal stack
  53                    	;   38   * the routines using them must not be reentrant
  54                    	;   39   */
  55                    	;   40  int searchn;  /* byte counter to search for response */
  56                    	;   41  int sdcbytes; /* byte counter for bytes to send */
  57                    	;   42  unsigned char *retptr; /* pointer used to store response */
  58                    	;   43  unsigned char rbyte;   /* recieved byte */
  59                    	;   44  unsigned char cmdbuf[5];   /* buffer to build command in */
  60                    	;   45  unsigned char rstatbuf[5]; /* buffer to recieve status in */
  61                    	;   46  unsigned char *statptr;    /* pointer to returned status from SD command */
  62                    	;   47  int nbytes;  /* byte counter */
  63                    	;   48  int allzero;
  64                    	;   49  int tries;
  65                    	;   50  
  66                    	;   51  /* Send command to SD card and recieve answer.
  67                    	;   52   * A command is 5 bytes long and is followed by
  68                    	;   53   * a CRC7 checksum byte (not needed in SPI mode
  69                    	;   54   * except for CMD0 and CMD8).
  70                    	;   55   * Returns a pointer to the response
  71                    	;   56   * or 0 if no response start bit found.
  72                    	;   57   */
  73                    	;   58  unsigned char *sdcommand(unsigned char *sdcmdp,
  74                    	;   59                           unsigned char *recbuf, int recbytes)
  75                    	;   60      {
  76                    	_sdcommand:
  77    000C  CD0000    		call	c.savs
  78                    	;   61      byteblkadr = (void *) SEBYFLG;
  79    000F  21FFFE    		ld	hl,65279
  80    0012  223302    		ld	(_byteblkadr),hl
  81                    	;   62      sdinitok = (void *) INITFLG;
  82    0015  21FEFE    		ld	hl,65278
  83    0018  223102    		ld	(_sdinitok),hl
  84                    	;   63      /* send 8*2 clockpules */
  85                    	;   64      spiio(0xff);
  86    001B  21FF00    		ld	hl,255
  87    001E  CD0000    		call	_spiio
  88                    	;   65      spiio(0xff);
  89    0021  21FF00    		ld	hl,255
  90    0024  CD0000    		call	_spiio
  91                    	;   66      for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
  92    0027  210500    		ld	hl,5
  93    002A  222B02    		ld	(_sdcbytes),hl
  94                    	L1:
  95    002D  212B02    		ld	hl,_sdcbytes
  96    0030  97        		sub	a
  97    0031  96        		sub	(hl)
  98    0032  3E00      		ld	a,0
  99    0034  23        		inc	hl
 100    0035  9E        		sbc	a,(hl)
 101    0036  F25600    		jp	p,L11
 102                    	;   67          {
 103                    	;   68          spiio(*sdcmdp++);
 104    0039  DD6E04    		ld	l,(ix+4)
 105    003C  DD6605    		ld	h,(ix+5)
 106    003F  DD3404    		inc	(ix+4)
 107    0042  2003      		jr	nz,L4
 108    0044  DD3405    		inc	(ix+5)
 109                    	L4:
 110    0047  6E        		ld	l,(hl)
 111    0048  97        		sub	a
 112    0049  67        		ld	h,a
 113    004A  CD0000    		call	_spiio
 114                    	;   69          }
 115    004D  2A2B02    		ld	hl,(_sdcbytes)
 116    0050  2B        		dec	hl
 117    0051  222B02    		ld	(_sdcbytes),hl
 118    0054  18D7      		jr	L1
 119                    	L11:
 120                    	;   70      /* search for recieved byte with start bit
 121                    	;   71         for a maximum of 10 recieved bytes  */
 122                    	;   72      for (searchn = 10; 0 < searchn; searchn--)
 123    0056  210A00    		ld	hl,10
 124    0059  222D02    		ld	(_searchn),hl
 125                    	L14:
 126    005C  212D02    		ld	hl,_searchn
 127    005F  97        		sub	a
 128    0060  96        		sub	(hl)
 129    0061  3E00      		ld	a,0
 130    0063  23        		inc	hl
 131    0064  9E        		sbc	a,(hl)
 132    0065  F28000    		jp	p,L15
 133                    	;   73          {
 134                    	;   74          rbyte = spiio(0xff);
 135    0068  21FF00    		ld	hl,255
 136    006B  CD0000    		call	_spiio
 137    006E  79        		ld	a,c
 138    006F  322802    		ld	(_rbyte),a
 139                    	;   75          if ((rbyte & 0x80) == 0)
 140    0072  CB7F      		bit	7,a
 141    0074  6F        		ld	l,a
 142    0075  2809      		jr	z,L15
 143                    	;   76              break;
 144                    	L16:
 145    0077  2A2D02    		ld	hl,(_searchn)
 146    007A  2B        		dec	hl
 147    007B  222D02    		ld	(_searchn),hl
 148    007E  18DC      		jr	L14
 149                    	L15:
 150                    	;   77          }
 151                    	;   78      if (searchn == 0) /* no start bit found */
 152    0080  2A2D02    		ld	hl,(_searchn)
 153    0083  7C        		ld	a,h
 154    0084  B5        		or	l
 155    0085  2006      		jr	nz,L111
 156                    	;   79          return (NO);
 157    0087  010000    		ld	bc,0
 158    008A  C30000    		jp	c.rets
 159                    	L111:
 160                    	;   80      retptr = recbuf;
 161    008D  DD6E06    		ld	l,(ix+6)
 162    0090  DD6607    		ld	h,(ix+7)
 163                    	;   81      *retptr++ = rbyte;
 164    0093  222902    		ld	(_retptr),hl
 165    0096  E5        		push	hl
 166    0097  2A2902    		ld	hl,(_retptr)
 167    009A  23        		inc	hl
 168    009B  222902    		ld	(_retptr),hl
 169    009E  E1        		pop	hl
 170    009F  3A2802    		ld	a,(_rbyte)
 171    00A2  77        		ld	(hl),a
 172                    	L121:
 173                    	;   82      for (; 1 < recbytes; recbytes--) /* recieve bytes */
 174    00A3  3E01      		ld	a,1
 175    00A5  DD9608    		sub	(ix+8)
 176    00A8  3E00      		ld	a,0
 177    00AA  DD9E09    		sbc	a,(ix+9)
 178    00AD  F2CF00    		jp	p,L131
 179                    	;   83          *retptr++ = spiio(0xff);
 180    00B0  2A2902    		ld	hl,(_retptr)
 181    00B3  E5        		push	hl
 182    00B4  23        		inc	hl
 183    00B5  222902    		ld	(_retptr),hl
 184    00B8  21FF00    		ld	hl,255
 185    00BB  CD0000    		call	_spiio
 186    00BE  E1        		pop	hl
 187    00BF  71        		ld	(hl),c
 188    00C0  DD6E08    		ld	l,(ix+8)
 189    00C3  DD6609    		ld	h,(ix+9)
 190    00C6  2B        		dec	hl
 191    00C7  DD7508    		ld	(ix+8),l
 192    00CA  DD7409    		ld	(ix+9),h
 193    00CD  18D4      		jr	L121
 194                    	L131:
 195                    	;   84      return (recbuf);
 196    00CF  DD4E06    		ld	c,(ix+6)
 197    00D2  DD4607    		ld	b,(ix+7)
 198    00D5  C30000    		jp	c.rets
 199                    	;   85      }
 200                    	;   86  
 201                    	;   87  /* Read data block of 512 bytes to rdbuf
 202                    	;   88   * the block number is a 4 byte array
 203                    	;   89   * Returns YES if ok or NO if error
 204                    	;   90   */
 205                    	;   91  int sdread(unsigned char *rdbuf, unsigned char *rdblkno)
 206                    	;   92      {
 207                    	_sdread:
 208    00D8  CD0000    		call	c.savs
 209                    	;   93  
 210                    	;   94      spiselect();
 211    00DB  CD0000    		call	_spiselect
 212                    	;   95  
 213                    	;   96      if (!*sdinitok)
 214    00DE  2A3102    		ld	hl,(_sdinitok)
 215    00E1  7E        		ld	a,(hl)
 216    00E2  B7        		or	a
 217    00E3  2009      		jr	nz,L161
 218                    	;   97          {
 219                    	;   98          spideselect();
 220    00E5  CD0000    		call	_spideselect
 221                    	;   99          return (NO);
 222    00E8  010000    		ld	bc,0
 223    00EB  C30000    		jp	c.rets
 224                    	L161:
 225                    	;  100          }
 226                    	;  101  
 227                    	;  102      /* CMD 17: READ_SINGLE_BLOCK */
 228                    	;  103      /* Insert block # into command */
 229                    	;  104      memcpy(cmdbuf, cmd17, 5);
 230    00EE  210500    		ld	hl,5
 231    00F1  E5        		push	hl
 232    00F2  210000    		ld	hl,_cmd17
 233    00F5  E5        		push	hl
 234    00F6  212302    		ld	hl,_cmdbuf
 235    00F9  CD0000    		call	_memcpy
 236    00FC  F1        		pop	af
 237    00FD  F1        		pop	af
 238                    	;  105      if (*byteblkadr)
 239    00FE  2A3302    		ld	hl,(_byteblkadr)
 240    0101  7E        		ld	a,(hl)
 241    0102  B7        		or	a
 242    0103  2809      		jr	z,L171
 243                    	;  106          blk2byte(rdblkno);
 244    0105  DD6E06    		ld	l,(ix+6)
 245    0108  DD6607    		ld	h,(ix+7)
 246    010B  CD0000    		call	_blk2byte
 247                    	L171:
 248                    	;  107      memcpy(&cmdbuf[1], rdblkno, 4);
 249    010E  210400    		ld	hl,4
 250    0111  E5        		push	hl
 251    0112  DD6E06    		ld	l,(ix+6)
 252    0115  DD6607    		ld	h,(ix+7)
 253    0118  E5        		push	hl
 254    0119  212402    		ld	hl,_cmdbuf+1
 255    011C  CD0000    		call	_memcpy
 256    011F  F1        		pop	af
 257    0120  F1        		pop	af
 258                    	;  108      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 259    0121  210100    		ld	hl,1
 260    0124  E5        		push	hl
 261    0125  211E02    		ld	hl,_rstatbuf
 262    0128  E5        		push	hl
 263    0129  212302    		ld	hl,_cmdbuf
 264    012C  CD0C00    		call	_sdcommand
 265    012F  F1        		pop	af
 266    0130  F1        		pop	af
 267    0131  ED431C02  		ld	(_statptr),bc
 268                    	;  109      if (statptr[0])
 269    0135  2A1C02    		ld	hl,(_statptr)
 270    0138  7E        		ld	a,(hl)
 271    0139  B7        		or	a
 272    013A  2809      		jr	z,L102
 273                    	;  110          {
 274                    	;  111          spideselect();
 275    013C  CD0000    		call	_spideselect
 276                    	;  112          return (NO);
 277    013F  010000    		ld	bc,0
 278    0142  C30000    		jp	c.rets
 279                    	L102:
 280                    	;  113          }
 281                    	;  114      /* looking for 0xfe that is the byte before data */
 282                    	;  115      for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
 283    0145  215000    		ld	hl,80
 284    0148  221602    		ld	(_tries),hl
 285                    	L112:
 286    014B  211602    		ld	hl,_tries
 287    014E  97        		sub	a
 288    014F  96        		sub	(hl)
 289    0150  3E00      		ld	a,0
 290    0152  23        		inc	hl
 291    0153  9E        		sbc	a,(hl)
 292    0154  F27E01    		jp	p,L122
 293    0157  21FF00    		ld	hl,255
 294    015A  CD0000    		call	_spiio
 295    015D  79        		ld	a,c
 296    015E  322802    		ld	(_rbyte),a
 297    0161  FEFE      		cp	254
 298    0163  2819      		jr	z,L122
 299                    	;  116          {
 300                    	;  117          if ((rbyte & 0xe0) == 0x00)
 301    0165  3A2802    		ld	a,(_rbyte)
 302    0168  E6E0      		and	224
 303    016A  2009      		jr	nz,L132
 304                    	;  118              {
 305                    	;  119              /* If a read operation fails and the card cannot provide
 306                    	;  120                 the required data, it will send a data error token instead
 307                    	;  121               */
 308                    	;  122              spideselect();
 309    016C  CD0000    		call	_spideselect
 310                    	;  123              return (NO);
 311    016F  010000    		ld	bc,0
 312    0172  C30000    		jp	c.rets
 313                    	L132:
 314    0175  2A1602    		ld	hl,(_tries)
 315    0178  2B        		dec	hl
 316    0179  221602    		ld	(_tries),hl
 317    017C  18CD      		jr	L112
 318                    	L122:
 319                    	;  124              }
 320                    	;  125          }
 321                    	;  126      if (tries == 0) /* tried too many times */
 322    017E  2A1602    		ld	hl,(_tries)
 323    0181  7C        		ld	a,h
 324    0182  B5        		or	l
 325    0183  2009      		jr	nz,L162
 326                    	;  127          {
 327                    	;  128          spideselect();
 328    0185  CD0000    		call	_spideselect
 329                    	;  129          return (NO);
 330    0188  010000    		ld	bc,0
 331    018B  C30000    		jp	c.rets
 332                    	L162:
 333                    	;  130          }
 334                    	;  131      else
 335                    	;  132          {
 336                    	;  133          for (nbytes = 0; nbytes < 512; nbytes++)
 337    018E  210000    		ld	hl,0
 338    0191  221A02    		ld	(_nbytes),hl
 339                    	L103:
 340    0194  3A1A02    		ld	a,(_nbytes)
 341    0197  D600      		sub	0
 342    0199  3A1B02    		ld	a,(_nbytes+1)
 343    019C  DE02      		sbc	a,2
 344    019E  F2BE01    		jp	p,L113
 345                    	;  134              {
 346                    	;  135              rdbuf[nbytes] = spiio(0xff);
 347    01A1  DD6E04    		ld	l,(ix+4)
 348    01A4  DD6605    		ld	h,(ix+5)
 349    01A7  ED4B1A02  		ld	bc,(_nbytes)
 350    01AB  09        		add	hl,bc
 351    01AC  E5        		push	hl
 352    01AD  21FF00    		ld	hl,255
 353    01B0  CD0000    		call	_spiio
 354    01B3  E1        		pop	hl
 355    01B4  71        		ld	(hl),c
 356                    	;  136              }
 357    01B5  2A1A02    		ld	hl,(_nbytes)
 358    01B8  23        		inc	hl
 359    01B9  221A02    		ld	(_nbytes),hl
 360    01BC  18D6      		jr	L103
 361                    	L113:
 362                    	;  137          /* read crc16 but no check */
 363                    	;  138          spiio(0xff);
 364    01BE  21FF00    		ld	hl,255
 365    01C1  CD0000    		call	_spiio
 366                    	;  139          spiio(0xff);
 367    01C4  21FF00    		ld	hl,255
 368    01C7  CD0000    		call	_spiio
 369                    	;  140          }
 370                    	;  141      spideselect();
 371    01CA  CD0000    		call	_spideselect
 372                    	;  142      return (YES);
 373    01CD  010100    		ld	bc,1
 374    01D0  C30000    		jp	c.rets
 375                    	;  143      }
 376                    	;  144  
 377                    	;  145  /* Write data block of 512 bytes from buffer
 378                    	;  146   * Returns YES if ok or NO if error
 379                    	;  147   */
 380                    	;  148  int sdwrite(unsigned char *wrbuf, unsigned char *wrblkno)
 381                    	;  149      {
 382                    	_sdwrite:
 383    01D3  CD0000    		call	c.savs
 384                    	;  150  
 385                    	;  151      spiselect();
 386    01D6  CD0000    		call	_spiselect
 387                    	;  152  
 388                    	;  153      if (!*sdinitok)
 389    01D9  2A3102    		ld	hl,(_sdinitok)
 390    01DC  7E        		ld	a,(hl)
 391    01DD  B7        		or	a
 392    01DE  2009      		jr	nz,L143
 393                    	;  154          {
 394                    	;  155          spideselect();
 395    01E0  CD0000    		call	_spideselect
 396                    	;  156          return (NO);
 397    01E3  010000    		ld	bc,0
 398    01E6  C30000    		jp	c.rets
 399                    	L143:
 400                    	;  157          }
 401                    	;  158      /* CMD 24: WRITE_SINGLE_BLOCK */
 402                    	;  159      /* Insert block # into command */
 403                    	;  160      memcpy(cmdbuf, cmd24, 5);
 404    01E9  210500    		ld	hl,5
 405    01EC  E5        		push	hl
 406    01ED  210600    		ld	hl,_cmd24
 407    01F0  E5        		push	hl
 408    01F1  212302    		ld	hl,_cmdbuf
 409    01F4  CD0000    		call	_memcpy
 410    01F7  F1        		pop	af
 411    01F8  F1        		pop	af
 412                    	;  161      if (*byteblkadr)
 413    01F9  2A3302    		ld	hl,(_byteblkadr)
 414    01FC  7E        		ld	a,(hl)
 415    01FD  B7        		or	a
 416    01FE  2809      		jr	z,L153
 417                    	;  162          blk2byte(wrblkno);
 418    0200  DD6E06    		ld	l,(ix+6)
 419    0203  DD6607    		ld	h,(ix+7)
 420    0206  CD0000    		call	_blk2byte
 421                    	L153:
 422                    	;  163      memcpy(&cmdbuf[1], wrblkno, 4);
 423    0209  210400    		ld	hl,4
 424    020C  E5        		push	hl
 425    020D  DD6E06    		ld	l,(ix+6)
 426    0210  DD6607    		ld	h,(ix+7)
 427    0213  E5        		push	hl
 428    0214  212402    		ld	hl,_cmdbuf+1
 429    0217  CD0000    		call	_memcpy
 430    021A  F1        		pop	af
 431    021B  F1        		pop	af
 432                    	;  164      statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
 433    021C  210100    		ld	hl,1
 434    021F  E5        		push	hl
 435    0220  211E02    		ld	hl,_rstatbuf
 436    0223  E5        		push	hl
 437    0224  212302    		ld	hl,_cmdbuf
 438    0227  CD0C00    		call	_sdcommand
 439    022A  F1        		pop	af
 440    022B  F1        		pop	af
 441    022C  ED431C02  		ld	(_statptr),bc
 442                    	;  165      if (statptr[0])
 443    0230  2A1C02    		ld	hl,(_statptr)
 444    0233  7E        		ld	a,(hl)
 445    0234  B7        		or	a
 446    0235  2809      		jr	z,L163
 447                    	;  166          {
 448                    	;  167          spideselect();
 449    0237  CD0000    		call	_spideselect
 450                    	;  168          return (NO);
 451    023A  010000    		ld	bc,0
 452    023D  C30000    		jp	c.rets
 453                    	L163:
 454                    	;  169          }
 455                    	;  170      /* send 0xfe, the byte before data */
 456                    	;  171      spiio(0xfe);
 457    0240  21FE00    		ld	hl,254
 458    0243  CD0000    		call	_spiio
 459                    	;  172      /* initialize crc and send block */
 460                    	;  173      for (nbytes = 0; nbytes < 512; nbytes++)
 461    0246  210000    		ld	hl,0
 462    0249  221A02    		ld	(_nbytes),hl
 463                    	L173:
 464    024C  3A1A02    		ld	a,(_nbytes)
 465    024F  D600      		sub	0
 466    0251  3A1B02    		ld	a,(_nbytes+1)
 467    0254  DE02      		sbc	a,2
 468    0256  F27302    		jp	p,L104
 469                    	;  174          {
 470                    	;  175          spiio(wrbuf[nbytes]);
 471    0259  DD6E04    		ld	l,(ix+4)
 472    025C  DD6605    		ld	h,(ix+5)
 473    025F  ED4B1A02  		ld	bc,(_nbytes)
 474    0263  09        		add	hl,bc
 475    0264  6E        		ld	l,(hl)
 476    0265  97        		sub	a
 477    0266  67        		ld	h,a
 478    0267  CD0000    		call	_spiio
 479                    	;  176          }
 480    026A  2A1A02    		ld	hl,(_nbytes)
 481    026D  23        		inc	hl
 482    026E  221A02    		ld	(_nbytes),hl
 483    0271  18D9      		jr	L173
 484                    	L104:
 485                    	;  177      /* send dummy crc16 */
 486                    	;  178      spiio(0x00);
 487    0273  210000    		ld	hl,0
 488    0276  CD0000    		call	_spiio
 489                    	;  179      spiio(0x00);
 490    0279  210000    		ld	hl,0
 491    027C  CD0000    		call	_spiio
 492                    	;  180  
 493                    	;  181      /* check data resposnse */
 494                    	;  182      for (tries = 20;
 495    027F  211400    		ld	hl,20
 496    0282  221602    		ld	(_tries),hl
 497                    	L134:
 498                    	;  183              0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
 499    0285  211602    		ld	hl,_tries
 500    0288  97        		sub	a
 501    0289  96        		sub	(hl)
 502    028A  3E00      		ld	a,0
 503    028C  23        		inc	hl
 504    028D  9E        		sbc	a,(hl)
 505    028E  F2B702    		jp	p,L144
 506    0291  21FF00    		ld	hl,255
 507    0294  CD0000    		call	_spiio
 508    0297  79        		ld	a,c
 509    0298  322802    		ld	(_rbyte),a
 510    029B  6F        		ld	l,a
 511    029C  97        		sub	a
 512    029D  67        		ld	h,a
 513    029E  7D        		ld	a,l
 514    029F  E611      		and	17
 515    02A1  6F        		ld	l,a
 516    02A2  97        		sub	a
 517    02A3  67        		ld	h,a
 518    02A4  7D        		ld	a,l
 519    02A5  FE01      		cp	1
 520    02A7  2003      		jr	nz,L21
 521    02A9  7C        		ld	a,h
 522    02AA  FE00      		cp	0
 523                    	L21:
 524    02AC  2809      		jr	z,L144
 525                    	;  184              tries--)
 526                    	L154:
 527    02AE  2A1602    		ld	hl,(_tries)
 528    02B1  2B        		dec	hl
 529    02B2  221602    		ld	(_tries),hl
 530    02B5  18CE      		jr	L134
 531                    	L144:
 532                    	;  185          ;
 533                    	;  186      if (tries == 0)
 534    02B7  2A1602    		ld	hl,(_tries)
 535    02BA  7C        		ld	a,h
 536    02BB  B5        		or	l
 537    02BC  2009      		jr	nz,L174
 538                    	;  187          {
 539                    	;  188          spideselect();
 540    02BE  CD0000    		call	_spideselect
 541                    	;  189          return (NO);
 542    02C1  010000    		ld	bc,0
 543    02C4  C30000    		jp	c.rets
 544                    	L174:
 545                    	;  190          }
 546                    	;  191      else
 547                    	;  192          {
 548                    	;  193          if ((0x1f & rbyte) == 0x05)
 549    02C7  3A2802    		ld	a,(_rbyte)
 550    02CA  6F        		ld	l,a
 551    02CB  97        		sub	a
 552    02CC  67        		ld	h,a
 553    02CD  7D        		ld	a,l
 554    02CE  E61F      		and	31
 555    02D0  6F        		ld	l,a
 556    02D1  97        		sub	a
 557    02D2  67        		ld	h,a
 558    02D3  7D        		ld	a,l
 559    02D4  FE05      		cp	5
 560    02D6  2003      		jr	nz,L41
 561    02D8  7C        		ld	a,h
 562    02D9  FE00      		cp	0
 563                    	L41:
 564    02DB  202A      		jr	nz,L115
 565                    	;  194              {
 566                    	;  195              for (nbytes = 9; 0 < nbytes; nbytes--)
 567    02DD  210900    		ld	hl,9
 568    02E0  221A02    		ld	(_nbytes),hl
 569                    	L125:
 570    02E3  211A02    		ld	hl,_nbytes
 571    02E6  97        		sub	a
 572    02E7  96        		sub	(hl)
 573    02E8  3E00      		ld	a,0
 574    02EA  23        		inc	hl
 575    02EB  9E        		sbc	a,(hl)
 576    02EC  F2FE02    		jp	p,L135
 577                    	;  196                  spiio(0xff);
 578    02EF  21FF00    		ld	hl,255
 579    02F2  CD0000    		call	_spiio
 580    02F5  2A1A02    		ld	hl,(_nbytes)
 581    02F8  2B        		dec	hl
 582    02F9  221A02    		ld	(_nbytes),hl
 583    02FC  18E5      		jr	L125
 584                    	L135:
 585                    	;  197              spideselect();
 586    02FE  CD0000    		call	_spideselect
 587                    	;  198              return (YES);
 588    0301  010100    		ld	bc,1
 589    0304  C30000    		jp	c.rets
 590                    	L115:
 591                    	;  199              }
 592                    	;  200          else
 593                    	;  201              {
 594                    	;  202              spideselect();
 595    0307  CD0000    		call	_spideselect
 596                    	;  203              return (NO);
 597    030A  010000    		ld	bc,0
 598    030D  C30000    		jp	c.rets
 599                    	;  204              }
 600                    	;  205          }
 601                    	;  206      }
 602                    	;  207  
 603                    	;  208  extern unsigned char diskno;
 604                    	;  209  extern unsigned char track;
 605                    	;  210  extern unsigned char sector;
 606                    	;  211  
 607                    	;  212  char prtbuf[10];
 608                    	;  213  
 609                    	;  214  unsigned char hstbuf[512];      /* host SD disk buffer */
 610                    	;  215  struct partentry *parptr;       /* Partition map pointer */
 611                    	;  216  unsigned int lbacpmsec;         /* CP/M sector to read/write */
 612                    	;  217  unsigned int lbahstblk;         /* disk block to read/write to/from hstbuf */
 613                    	;  218  unsigned char sddskblk[4];/* block to read/write in SD format, per partition */
 614                    	;  219  unsigned char sdcardblk[4];/* block to read/write in SD format, per card */
 615                    	;  220  
 616                    	;  221  extern unsigned int spt;        /* sectors per track */
 617                    	;  222  
 618                    	;  223  /* Convert unsigned int to block address
 619                    	;  224   */
 620                    	;  225  void ui2blk(unsigned char *blk, unsigned int nblk)
 621                    	;  226      {
 622                    	_ui2blk:
 623    0310  CD0000    		call	c.savs
 624                    	;  227      blk[3] = nblk & 0xff;
 625    0313  DD6E04    		ld	l,(ix+4)
 626    0316  DD6605    		ld	h,(ix+5)
 627    0319  23        		inc	hl
 628    031A  23        		inc	hl
 629    031B  23        		inc	hl
 630    031C  DD4E06    		ld	c,(ix+6)
 631    031F  79        		ld	a,c
 632    0320  E6FF      		and	255
 633    0322  4F        		ld	c,a
 634    0323  71        		ld	(hl),c
 635                    	;  228      nblk = nblk >> 8;
 636    0324  DD6E06    		ld	l,(ix+6)
 637    0327  DD6607    		ld	h,(ix+7)
 638    032A  E5        		push	hl
 639    032B  210800    		ld	hl,8
 640    032E  E5        		push	hl
 641    032F  CD0000    		call	c.ursh
 642    0332  C1        		pop	bc
 643    0333  DD7106    		ld	(ix+6),c
 644    0336  DD7007    		ld	(ix+7),b
 645                    	;  229      blk[2] = nblk & 0xff;
 646    0339  DD6E04    		ld	l,(ix+4)
 647    033C  DD6605    		ld	h,(ix+5)
 648    033F  23        		inc	hl
 649    0340  23        		inc	hl
 650    0341  DD4E06    		ld	c,(ix+6)
 651    0344  79        		ld	a,c
 652    0345  E6FF      		and	255
 653    0347  4F        		ld	c,a
 654    0348  71        		ld	(hl),c
 655                    	;  230      blk[1] = 0;
 656    0349  DD6E04    		ld	l,(ix+4)
 657    034C  DD6605    		ld	h,(ix+5)
 658    034F  23        		inc	hl
 659    0350  3600      		ld	(hl),0
 660                    	;  231      blk[0] = 0;
 661    0352  DD6E04    		ld	l,(ix+4)
 662    0355  DD6605    		ld	h,(ix+5)
 663    0358  3600      		ld	(hl),0
 664                    	;  232      }
 665    035A  C30000    		jp	c.rets
 666                    	;  233  
 667                    	;  234  extern unsigned int dmaad;
 668                    	;  235  
 669                    	;  236  /* Read sector, called from BIOS
 670                    	;  237   */
 671                    	;  238  rdsdsec()
 672                    	;  239      {
 673                    	_rdsdsec:
 674                    	;  240      parptr = (void *) PARMAPADR;
 675    035D  97        		sub	a
 676    035E  322F02    		ld	(_parptr),a
 677    0361  3EFF      		ld	a,255
 678    0363  323002    		ld	(_parptr+1),a
 679                    	;  241      lbacpmsec = track * spt + sector - 1;
 680    0366  3A0000    		ld	a,(_track)
 681    0369  4F        		ld	c,a
 682    036A  97        		sub	a
 683    036B  47        		ld	b,a
 684    036C  C5        		push	bc
 685    036D  2A0000    		ld	hl,(_spt)
 686    0370  E5        		push	hl
 687    0371  CD0000    		call	c.imul
 688    0374  E1        		pop	hl
 689    0375  E5        		push	hl
 690    0376  3A0000    		ld	a,(_sector)
 691    0379  6F        		ld	l,a
 692    037A  97        		sub	a
 693    037B  67        		ld	h,a
 694    037C  E3        		ex	(sp),hl
 695    037D  C1        		pop	bc
 696    037E  09        		add	hl,bc
 697    037F  01FFFF    		ld	bc,65535
 698    0382  09        		add	hl,bc
 699                    	;  242      lbahstblk = lbacpmsec / 4;
 700    0383  220A00    		ld	(_lbacpmsec),hl
 701    0386  E5        		push	hl
 702    0387  210400    		ld	hl,4
 703    038A  E5        		push	hl
 704    038B  CD0000    		call	c.udiv
 705    038E  E1        		pop	hl
 706                    	;  243      ui2blk(sddskblk, lbahstblk);
 707    038F  220800    		ld	(_lbahstblk),hl
 708    0392  E5        		push	hl
 709    0393  210400    		ld	hl,_sddskblk
 710    0396  CD1003    		call	_ui2blk
 711    0399  F1        		pop	af
 712                    	;  244      memcpy(sdcardblk, sddskblk, 4);
 713    039A  210400    		ld	hl,4
 714    039D  E5        		push	hl
 715    039E  210400    		ld	hl,_sddskblk
 716    03A1  E5        		push	hl
 717    03A2  210000    		ld	hl,_sdcardblk
 718    03A5  CD0000    		call	_memcpy
 719    03A8  F1        		pop	af
 720    03A9  F1        		pop	af
 721                    	;  245      addblk(sdcardblk, parptr[diskno].parstart);
 722    03AA  3A0000    		ld	a,(_diskno)
 723    03AD  4F        		ld	c,a
 724    03AE  97        		sub	a
 725    03AF  47        		ld	b,a
 726    03B0  C5        		push	bc
 727    03B1  211000    		ld	hl,16
 728    03B4  E5        		push	hl
 729    03B5  CD0000    		call	c.imul
 730    03B8  E1        		pop	hl
 731    03B9  ED4B2F02  		ld	bc,(_parptr)
 732    03BD  09        		add	hl,bc
 733    03BE  23        		inc	hl
 734    03BF  23        		inc	hl
 735    03C0  23        		inc	hl
 736    03C1  23        		inc	hl
 737    03C2  E5        		push	hl
 738    03C3  210000    		ld	hl,_sdcardblk
 739    03C6  CD0000    		call	_addblk
 740    03C9  F1        		pop	af
 741                    	;  246      if (!sdread(hstbuf, sdcardblk))
 742    03CA  210000    		ld	hl,_sdcardblk
 743    03CD  E5        		push	hl
 744    03CE  210C00    		ld	hl,_hstbuf
 745    03D1  CDD800    		call	_sdread
 746    03D4  F1        		pop	af
 747    03D5  79        		ld	a,c
 748    03D6  B0        		or	b
 749    03D7  2004      		jr	nz,L175
 750                    	;  247          return(1);
 751    03D9  010100    		ld	bc,1
 752    03DC  C9        		ret 
 753                    	L175:
 754                    	;  248      memcpy(dmaad, &hstbuf[128 * (lbacpmsec & 3)], 128);
 755    03DD  218000    		ld	hl,128
 756    03E0  E5        		push	hl
 757    03E1  2A0A00    		ld	hl,(_lbacpmsec)
 758    03E4  7D        		ld	a,l
 759    03E5  E603      		and	3
 760    03E7  6F        		ld	l,a
 761    03E8  97        		sub	a
 762    03E9  67        		ld	h,a
 763    03EA  E5        		push	hl
 764    03EB  218000    		ld	hl,128
 765    03EE  E5        		push	hl
 766    03EF  CD0000    		call	c.imul
 767    03F2  E1        		pop	hl
 768    03F3  010C00    		ld	bc,_hstbuf
 769    03F6  09        		add	hl,bc
 770    03F7  E5        		push	hl
 771    03F8  2A0000    		ld	hl,(_dmaad)
 772    03FB  CD0000    		call	_memcpy
 773    03FE  F1        		pop	af
 774    03FF  F1        		pop	af
 775                    	;  249      return(0);
 776    0400  010000    		ld	bc,0
 777    0403  C9        		ret 
 778                    	;  250      }
 779                    	;  251  
 780                    	;  252  /* Write sector, called from BIOS
 781                    	;  253   */
 782                    	;  254  wrsdsec()
 783                    	;  255      {
 784                    	_wrsdsec:
 785                    	;  256      parptr = (void *) PARMAPADR;
 786    0404  97        		sub	a
 787    0405  322F02    		ld	(_parptr),a
 788    0408  3EFF      		ld	a,255
 789    040A  323002    		ld	(_parptr+1),a
 790                    	;  257      lbacpmsec = track * spt + sector - 1;
 791    040D  3A0000    		ld	a,(_track)
 792    0410  4F        		ld	c,a
 793    0411  97        		sub	a
 794    0412  47        		ld	b,a
 795    0413  C5        		push	bc
 796    0414  2A0000    		ld	hl,(_spt)
 797    0417  E5        		push	hl
 798    0418  CD0000    		call	c.imul
 799    041B  E1        		pop	hl
 800    041C  E5        		push	hl
 801    041D  3A0000    		ld	a,(_sector)
 802    0420  6F        		ld	l,a
 803    0421  97        		sub	a
 804    0422  67        		ld	h,a
 805    0423  E3        		ex	(sp),hl
 806    0424  C1        		pop	bc
 807    0425  09        		add	hl,bc
 808    0426  01FFFF    		ld	bc,65535
 809    0429  09        		add	hl,bc
 810                    	;  258      lbahstblk = lbacpmsec / 4;
 811    042A  220A00    		ld	(_lbacpmsec),hl
 812    042D  E5        		push	hl
 813    042E  210400    		ld	hl,4
 814    0431  E5        		push	hl
 815    0432  CD0000    		call	c.udiv
 816    0435  E1        		pop	hl
 817                    	;  259      ui2blk(sddskblk, lbahstblk);
 818    0436  220800    		ld	(_lbahstblk),hl
 819    0439  E5        		push	hl
 820    043A  210400    		ld	hl,_sddskblk
 821    043D  CD1003    		call	_ui2blk
 822    0440  F1        		pop	af
 823                    	;  260      memcpy(sdcardblk, sddskblk, 4);
 824    0441  210400    		ld	hl,4
 825    0444  E5        		push	hl
 826    0445  210400    		ld	hl,_sddskblk
 827    0448  E5        		push	hl
 828    0449  210000    		ld	hl,_sdcardblk
 829    044C  CD0000    		call	_memcpy
 830    044F  F1        		pop	af
 831    0450  F1        		pop	af
 832                    	;  261      addblk(sdcardblk, parptr[diskno].parstart);
 833    0451  3A0000    		ld	a,(_diskno)
 834    0454  4F        		ld	c,a
 835    0455  97        		sub	a
 836    0456  47        		ld	b,a
 837    0457  C5        		push	bc
 838    0458  211000    		ld	hl,16
 839    045B  E5        		push	hl
 840    045C  CD0000    		call	c.imul
 841    045F  E1        		pop	hl
 842    0460  ED4B2F02  		ld	bc,(_parptr)
 843    0464  09        		add	hl,bc
 844    0465  23        		inc	hl
 845    0466  23        		inc	hl
 846    0467  23        		inc	hl
 847    0468  23        		inc	hl
 848    0469  E5        		push	hl
 849    046A  210000    		ld	hl,_sdcardblk
 850    046D  CD0000    		call	_addblk
 851    0470  F1        		pop	af
 852                    	;  262      if (!sdread(hstbuf, sdcardblk))
 853    0471  210000    		ld	hl,_sdcardblk
 854    0474  E5        		push	hl
 855    0475  210C00    		ld	hl,_hstbuf
 856    0478  CDD800    		call	_sdread
 857    047B  F1        		pop	af
 858    047C  79        		ld	a,c
 859    047D  B0        		or	b
 860    047E  2004      		jr	nz,L106
 861                    	;  263          return(1);
 862    0480  010100    		ld	bc,1
 863    0483  C9        		ret 
 864                    	L106:
 865                    	;  264      memcpy(&hstbuf[128 * (lbacpmsec & 3)], dmaad, 128);
 866    0484  218000    		ld	hl,128
 867    0487  E5        		push	hl
 868    0488  2A0000    		ld	hl,(_dmaad)
 869    048B  E5        		push	hl
 870    048C  2A0A00    		ld	hl,(_lbacpmsec)
 871    048F  7D        		ld	a,l
 872    0490  E603      		and	3
 873    0492  6F        		ld	l,a
 874    0493  97        		sub	a
 875    0494  67        		ld	h,a
 876    0495  E5        		push	hl
 877    0496  218000    		ld	hl,128
 878    0499  E5        		push	hl
 879    049A  CD0000    		call	c.imul
 880    049D  E1        		pop	hl
 881    049E  010C00    		ld	bc,_hstbuf
 882    04A1  09        		add	hl,bc
 883    04A2  CD0000    		call	_memcpy
 884    04A5  F1        		pop	af
 885    04A6  F1        		pop	af
 886                    	;  265      if (!sdwrite(hstbuf, sdcardblk))
 887    04A7  210000    		ld	hl,_sdcardblk
 888    04AA  E5        		push	hl
 889    04AB  210C00    		ld	hl,_hstbuf
 890    04AE  CDD301    		call	_sdwrite
 891    04B1  F1        		pop	af
 892    04B2  79        		ld	a,c
 893    04B3  B0        		or	b
 894    04B4  2004      		jr	nz,L116
 895                    	;  266          return(1);
 896    04B6  010100    		ld	bc,1
 897    04B9  C9        		ret 
 898                    	L116:
 899                    	;  267      return(0);
 900    04BA  010000    		ld	bc,0
 901    04BD  C9        		ret 
 902                    	;  268      }
 903                    	;  269  
 904                    		.psect	_bss
 905                    	_sdcardblk:
 906                    		.byte	[4]
 907                    	_sddskblk:
 908                    		.byte	[4]
 909                    	_lbahstblk:
 910                    		.byte	[2]
 911                    	_lbacpmsec:
 912                    		.byte	[2]
 913                    	_hstbuf:
 914                    		.byte	[512]
 915                    	_prtbuf:
 916                    		.byte	[10]
 917                    	_tries:
 918                    		.byte	[2]
 919                    	_allzero:
 920                    		.byte	[2]
 921                    	_nbytes:
 922                    		.byte	[2]
 923                    	_statptr:
 924                    		.byte	[2]
 925                    	_rstatbuf:
 926                    		.byte	[5]
 927                    	_cmdbuf:
 928                    		.byte	[5]
 929                    	_rbyte:
 930                    		.byte	[1]
 931                    	_retptr:
 932                    		.byte	[2]
 933                    	_sdcbytes:
 934                    		.byte	[2]
 935                    	_searchn:
 936                    		.byte	[2]
 937                    	_parptr:
 938                    		.byte	[2]
 939                    	_sdinitok:
 940                    		.byte	[2]
 941                    	_byteblkadr:
 942                    		.byte	[2]
 943                    		.external	_blk2byte
 944                    		.public	_cmd17
 945                    		.public	_cmd24
 946                    		.public	_parptr
 947                    		.external	_spt
 948                    		.external	_track
 949                    		.public	_nbytes
 950                    		.external	_spideselect
 951                    		.public	_prtbuf
 952                    		.public	_sddskblk
 953                    		.public	_statptr
 954                    		.external	_sector
 955                    		.public	_hstbuf
 956                    		.external	_spiselect
 957                    		.external	_memcpy
 958                    		.public	_ui2blk
 959                    		.external	_diskno
 960                    		.public	_sdwrite
 961                    		.public	_wrsdsec
 962                    		.public	_allzero
 963                    		.external	_dmaad
 964                    		.public	_lbahstblk
 965                    		.public	_sdcommand
 966                    		.external	c.ursh
 967                    		.public	_sdread
 968                    		.public	_cmdbuf
 969                    		.external	c.rets
 970                    		.external	c.savs
 971                    		.public	_rstatbuf
 972                    		.public	_sdcardblk
 973                    		.external	c.udiv
 974                    		.public	_lbacpmsec
 975                    		.external	c.imul
 976                    		.public	_rdsdsec
 977                    		.public	_tries
 978                    		.public	_rbyte
 979                    		.public	_sdinitok
 980                    		.public	_searchn
 981                    		.external	_spiio
 982                    		.public	_byteblkadr
 983                    		.external	_addblk
 984                    		.public	_retptr
 985                    		.public	_sdcbytes
 986                    		.end
