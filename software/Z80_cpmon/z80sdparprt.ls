   1                    	;    1  /*  z80sdparprt.c Print partitions on SD card.
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
  19                    		.psect	_text
  20                    	L5:
  21    0000  25        		.byte	37
  22    0001  30        		.byte	48
  23    0002  32        		.byte	50
  24    0003  78        		.byte	120
  25    0004  25        		.byte	37
  26    0005  30        		.byte	48
  27    0006  32        		.byte	50
  28    0007  78        		.byte	120
  29    0008  25        		.byte	37
  30    0009  30        		.byte	48
  31    000A  32        		.byte	50
  32    000B  78        		.byte	120
  33    000C  25        		.byte	37
  34    000D  30        		.byte	48
  35    000E  32        		.byte	50
  36    000F  78        		.byte	120
  37    0010  2D        		.byte	45
  38    0011  00        		.byte	0
  39                    	L51:
  40    0012  25        		.byte	37
  41    0013  30        		.byte	48
  42    0014  32        		.byte	50
  43    0015  78        		.byte	120
  44    0016  25        		.byte	37
  45    0017  30        		.byte	48
  46    0018  32        		.byte	50
  47    0019  78        		.byte	120
  48    001A  2D        		.byte	45
  49    001B  00        		.byte	0
  50                    	L52:
  51    001C  25        		.byte	37
  52    001D  30        		.byte	48
  53    001E  32        		.byte	50
  54    001F  78        		.byte	120
  55    0020  25        		.byte	37
  56    0021  30        		.byte	48
  57    0022  32        		.byte	50
  58    0023  78        		.byte	120
  59    0024  2D        		.byte	45
  60    0025  00        		.byte	0
  61                    	L53:
  62    0026  25        		.byte	37
  63    0027  30        		.byte	48
  64    0028  32        		.byte	50
  65    0029  78        		.byte	120
  66    002A  25        		.byte	37
  67    002B  30        		.byte	48
  68    002C  32        		.byte	50
  69    002D  78        		.byte	120
  70    002E  2D        		.byte	45
  71    002F  00        		.byte	0
  72                    	L54:
  73    0030  25        		.byte	37
  74    0031  30        		.byte	48
  75    0032  32        		.byte	50
  76    0033  78        		.byte	120
  77    0034  25        		.byte	37
  78    0035  30        		.byte	48
  79    0036  32        		.byte	50
  80    0037  78        		.byte	120
  81    0038  25        		.byte	37
  82    0039  30        		.byte	48
  83    003A  32        		.byte	50
  84    003B  78        		.byte	120
  85    003C  25        		.byte	37
  86    003D  30        		.byte	48
  87    003E  32        		.byte	50
  88    003F  78        		.byte	120
  89    0040  25        		.byte	37
  90    0041  30        		.byte	48
  91    0042  32        		.byte	50
  92    0043  78        		.byte	120
  93    0044  25        		.byte	37
  94    0045  30        		.byte	48
  95    0046  32        		.byte	50
  96    0047  78        		.byte	120
  97    0048  00        		.byte	0
  98                    	;   19  
  99                    	;   20  /* Print GUID (mixed endian format)
 100                    	;   21   */
 101                    	;   22  void prtguid(unsigned char *guidptr)
 102                    	;   23      {
 103                    	_prtguid:
 104    0049  CD0000    		call	c.savs
 105    004C  F5        		push	af
 106    004D  F5        		push	af
 107    004E  F5        		push	af
 108    004F  F5        		push	af
 109                    	;   24      int index;
 110                    	;   25  
 111                    	;   26      printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
 112    0050  DD6E04    		ld	l,(ix+4)
 113    0053  DD6605    		ld	h,(ix+5)
 114    0056  4E        		ld	c,(hl)
 115    0057  97        		sub	a
 116    0058  47        		ld	b,a
 117    0059  C5        		push	bc
 118    005A  DD6E04    		ld	l,(ix+4)
 119    005D  DD6605    		ld	h,(ix+5)
 120    0060  23        		inc	hl
 121    0061  4E        		ld	c,(hl)
 122    0062  97        		sub	a
 123    0063  47        		ld	b,a
 124    0064  C5        		push	bc
 125    0065  DD6E04    		ld	l,(ix+4)
 126    0068  DD6605    		ld	h,(ix+5)
 127    006B  23        		inc	hl
 128    006C  23        		inc	hl
 129    006D  4E        		ld	c,(hl)
 130    006E  97        		sub	a
 131    006F  47        		ld	b,a
 132    0070  C5        		push	bc
 133    0071  DD6E04    		ld	l,(ix+4)
 134    0074  DD6605    		ld	h,(ix+5)
 135    0077  23        		inc	hl
 136    0078  23        		inc	hl
 137    0079  23        		inc	hl
 138    007A  4E        		ld	c,(hl)
 139    007B  97        		sub	a
 140    007C  47        		ld	b,a
 141    007D  C5        		push	bc
 142    007E  210000    		ld	hl,L5
 143    0081  CD0000    		call	_printf
 144    0084  F1        		pop	af
 145    0085  F1        		pop	af
 146    0086  F1        		pop	af
 147    0087  F1        		pop	af
 148                    	;   27      printf("%02x%02x-", guidptr[5], guidptr[4]);
 149    0088  DD6E04    		ld	l,(ix+4)
 150    008B  DD6605    		ld	h,(ix+5)
 151    008E  23        		inc	hl
 152    008F  23        		inc	hl
 153    0090  23        		inc	hl
 154    0091  23        		inc	hl
 155    0092  4E        		ld	c,(hl)
 156    0093  97        		sub	a
 157    0094  47        		ld	b,a
 158    0095  C5        		push	bc
 159    0096  DD6E04    		ld	l,(ix+4)
 160    0099  DD6605    		ld	h,(ix+5)
 161    009C  010500    		ld	bc,5
 162    009F  09        		add	hl,bc
 163    00A0  4E        		ld	c,(hl)
 164    00A1  97        		sub	a
 165    00A2  47        		ld	b,a
 166    00A3  C5        		push	bc
 167    00A4  211200    		ld	hl,L51
 168    00A7  CD0000    		call	_printf
 169    00AA  F1        		pop	af
 170    00AB  F1        		pop	af
 171                    	;   28      printf("%02x%02x-", guidptr[7], guidptr[6]);
 172    00AC  DD6E04    		ld	l,(ix+4)
 173    00AF  DD6605    		ld	h,(ix+5)
 174    00B2  010600    		ld	bc,6
 175    00B5  09        		add	hl,bc
 176    00B6  4E        		ld	c,(hl)
 177    00B7  97        		sub	a
 178    00B8  47        		ld	b,a
 179    00B9  C5        		push	bc
 180    00BA  DD6E04    		ld	l,(ix+4)
 181    00BD  DD6605    		ld	h,(ix+5)
 182    00C0  010700    		ld	bc,7
 183    00C3  09        		add	hl,bc
 184    00C4  4E        		ld	c,(hl)
 185    00C5  97        		sub	a
 186    00C6  47        		ld	b,a
 187    00C7  C5        		push	bc
 188    00C8  211C00    		ld	hl,L52
 189    00CB  CD0000    		call	_printf
 190    00CE  F1        		pop	af
 191    00CF  F1        		pop	af
 192                    	;   29      printf("%02x%02x-", guidptr[8], guidptr[9]);
 193    00D0  DD6E04    		ld	l,(ix+4)
 194    00D3  DD6605    		ld	h,(ix+5)
 195    00D6  010900    		ld	bc,9
 196    00D9  09        		add	hl,bc
 197    00DA  4E        		ld	c,(hl)
 198    00DB  97        		sub	a
 199    00DC  47        		ld	b,a
 200    00DD  C5        		push	bc
 201    00DE  DD6E04    		ld	l,(ix+4)
 202    00E1  DD6605    		ld	h,(ix+5)
 203    00E4  010800    		ld	bc,8
 204    00E7  09        		add	hl,bc
 205    00E8  4E        		ld	c,(hl)
 206    00E9  97        		sub	a
 207    00EA  47        		ld	b,a
 208    00EB  C5        		push	bc
 209    00EC  212600    		ld	hl,L53
 210    00EF  CD0000    		call	_printf
 211    00F2  F1        		pop	af
 212    00F3  F1        		pop	af
 213                    	;   30      printf("%02x%02x%02x%02x%02x%02x",
 214                    	;   31             guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
 215    00F4  DD6E04    		ld	l,(ix+4)
 216    00F7  DD6605    		ld	h,(ix+5)
 217    00FA  010F00    		ld	bc,15
 218    00FD  09        		add	hl,bc
 219    00FE  4E        		ld	c,(hl)
 220    00FF  97        		sub	a
 221    0100  47        		ld	b,a
 222    0101  C5        		push	bc
 223    0102  DD6E04    		ld	l,(ix+4)
 224    0105  DD6605    		ld	h,(ix+5)
 225    0108  010E00    		ld	bc,14
 226    010B  09        		add	hl,bc
 227    010C  4E        		ld	c,(hl)
 228    010D  97        		sub	a
 229    010E  47        		ld	b,a
 230    010F  C5        		push	bc
 231    0110  DD6E04    		ld	l,(ix+4)
 232    0113  DD6605    		ld	h,(ix+5)
 233    0116  010D00    		ld	bc,13
 234    0119  09        		add	hl,bc
 235    011A  4E        		ld	c,(hl)
 236    011B  97        		sub	a
 237    011C  47        		ld	b,a
 238    011D  C5        		push	bc
 239    011E  DD6E04    		ld	l,(ix+4)
 240    0121  DD6605    		ld	h,(ix+5)
 241    0124  010C00    		ld	bc,12
 242    0127  09        		add	hl,bc
 243    0128  4E        		ld	c,(hl)
 244    0129  97        		sub	a
 245    012A  47        		ld	b,a
 246    012B  C5        		push	bc
 247    012C  DD6E04    		ld	l,(ix+4)
 248    012F  DD6605    		ld	h,(ix+5)
 249    0132  010B00    		ld	bc,11
 250    0135  09        		add	hl,bc
 251    0136  4E        		ld	c,(hl)
 252    0137  97        		sub	a
 253    0138  47        		ld	b,a
 254    0139  C5        		push	bc
 255    013A  DD6E04    		ld	l,(ix+4)
 256    013D  DD6605    		ld	h,(ix+5)
 257    0140  010A00    		ld	bc,10
 258    0143  09        		add	hl,bc
 259    0144  4E        		ld	c,(hl)
 260    0145  97        		sub	a
 261    0146  47        		ld	b,a
 262    0147  C5        		push	bc
 263    0148  213000    		ld	hl,L54
 264    014B  CD0000    		call	_printf
 265    014E  210C00    		ld	hl,12
 266    0151  39        		add	hl,sp
 267    0152  F9        		ld	sp,hl
 268                    	;   32      }
 269    0153  C30000    		jp	c.rets
 270                    	L55:
 271    0156  20        		.byte	32
 272    0157  20        		.byte	32
 273    0158  20        		.byte	32
 274    0159  20        		.byte	32
 275    015A  20        		.byte	32
 276    015B  20        		.byte	32
 277    015C  44        		.byte	68
 278    015D  69        		.byte	105
 279    015E  73        		.byte	115
 280    015F  6B        		.byte	107
 281    0160  20        		.byte	32
 282    0161  70        		.byte	112
 283    0162  61        		.byte	97
 284    0163  72        		.byte	114
 285    0164  74        		.byte	116
 286    0165  69        		.byte	105
 287    0166  74        		.byte	116
 288    0167  69        		.byte	105
 289    0168  6F        		.byte	111
 290    0169  6E        		.byte	110
 291    016A  20        		.byte	32
 292    016B  73        		.byte	115
 293    016C  65        		.byte	101
 294    016D  63        		.byte	99
 295    016E  74        		.byte	116
 296    016F  6F        		.byte	111
 297    0170  72        		.byte	114
 298    0171  73        		.byte	115
 299    0172  20        		.byte	32
 300    0173  6F        		.byte	111
 301    0174  6E        		.byte	110
 302    0175  20        		.byte	32
 303    0176  53        		.byte	83
 304    0177  44        		.byte	68
 305    0178  20        		.byte	32
 306    0179  63        		.byte	99
 307    017A  61        		.byte	97
 308    017B  72        		.byte	114
 309    017C  64        		.byte	100
 310    017D  0A        		.byte	10
 311    017E  00        		.byte	0
 312                    	L56:
 313    017F  20        		.byte	32
 314    0180  20        		.byte	32
 315    0181  20        		.byte	32
 316    0182  20        		.byte	32
 317    0183  20        		.byte	32
 318    0184  20        		.byte	32
 319    0185  20        		.byte	32
 320    0186  4D        		.byte	77
 321    0187  42        		.byte	66
 322    0188  52        		.byte	82
 323    0189  20        		.byte	32
 324    018A  64        		.byte	100
 325    018B  69        		.byte	105
 326    018C  73        		.byte	115
 327    018D  6B        		.byte	107
 328    018E  20        		.byte	32
 329    018F  69        		.byte	105
 330    0190  64        		.byte	100
 331    0191  65        		.byte	101
 332    0192  6E        		.byte	110
 333    0193  74        		.byte	116
 334    0194  69        		.byte	105
 335    0195  66        		.byte	102
 336    0196  69        		.byte	105
 337    0197  65        		.byte	101
 338    0198  72        		.byte	114
 339    0199  3A        		.byte	58
 340    019A  20        		.byte	32
 341    019B  30        		.byte	48
 342    019C  78        		.byte	120
 343    019D  25        		.byte	37
 344    019E  30        		.byte	48
 345    019F  32        		.byte	50
 346    01A0  78        		.byte	120
 347    01A1  25        		.byte	37
 348    01A2  30        		.byte	48
 349    01A3  32        		.byte	50
 350    01A4  78        		.byte	120
 351    01A5  25        		.byte	37
 352    01A6  30        		.byte	48
 353    01A7  32        		.byte	50
 354    01A8  78        		.byte	120
 355    01A9  25        		.byte	37
 356    01AA  30        		.byte	48
 357    01AB  32        		.byte	50
 358    01AC  78        		.byte	120
 359    01AD  0A        		.byte	10
 360    01AE  00        		.byte	0
 361                    	L57:
 362    01AF  20        		.byte	32
 363    01B0  44        		.byte	68
 364    01B1  69        		.byte	105
 365    01B2  73        		.byte	115
 366    01B3  6B        		.byte	107
 367    01B4  20        		.byte	32
 368    01B5  20        		.byte	32
 369    01B6  20        		.byte	32
 370    01B7  20        		.byte	32
 371    01B8  20        		.byte	32
 372    01B9  53        		.byte	83
 373    01BA  74        		.byte	116
 374    01BB  61        		.byte	97
 375    01BC  72        		.byte	114
 376    01BD  74        		.byte	116
 377    01BE  20        		.byte	32
 378    01BF  20        		.byte	32
 379    01C0  20        		.byte	32
 380    01C1  20        		.byte	32
 381    01C2  20        		.byte	32
 382    01C3  20        		.byte	32
 383    01C4  45        		.byte	69
 384    01C5  6E        		.byte	110
 385    01C6  64        		.byte	100
 386    01C7  20        		.byte	32
 387    01C8  20        		.byte	32
 388    01C9  20        		.byte	32
 389    01CA  20        		.byte	32
 390    01CB  20        		.byte	32
 391    01CC  53        		.byte	83
 392    01CD  69        		.byte	105
 393    01CE  7A        		.byte	122
 394    01CF  65        		.byte	101
 395    01D0  20        		.byte	32
 396    01D1  50        		.byte	80
 397    01D2  61        		.byte	97
 398    01D3  72        		.byte	114
 399    01D4  74        		.byte	116
 400    01D5  20        		.byte	32
 401    01D6  54        		.byte	84
 402    01D7  79        		.byte	121
 403    01D8  70        		.byte	112
 404    01D9  65        		.byte	101
 405    01DA  20        		.byte	32
 406    01DB  49        		.byte	73
 407    01DC  64        		.byte	100
 408    01DD  0A        		.byte	10
 409    01DE  00        		.byte	0
 410                    	L501:
 411    01DF  20        		.byte	32
 412    01E0  2D        		.byte	45
 413    01E1  2D        		.byte	45
 414    01E2  2D        		.byte	45
 415    01E3  2D        		.byte	45
 416    01E4  20        		.byte	32
 417    01E5  20        		.byte	32
 418    01E6  20        		.byte	32
 419    01E7  20        		.byte	32
 420    01E8  20        		.byte	32
 421    01E9  2D        		.byte	45
 422    01EA  2D        		.byte	45
 423    01EB  2D        		.byte	45
 424    01EC  2D        		.byte	45
 425    01ED  2D        		.byte	45
 426    01EE  20        		.byte	32
 427    01EF  20        		.byte	32
 428    01F0  20        		.byte	32
 429    01F1  20        		.byte	32
 430    01F2  20        		.byte	32
 431    01F3  20        		.byte	32
 432    01F4  2D        		.byte	45
 433    01F5  2D        		.byte	45
 434    01F6  2D        		.byte	45
 435    01F7  20        		.byte	32
 436    01F8  20        		.byte	32
 437    01F9  20        		.byte	32
 438    01FA  20        		.byte	32
 439    01FB  20        		.byte	32
 440    01FC  2D        		.byte	45
 441    01FD  2D        		.byte	45
 442    01FE  2D        		.byte	45
 443    01FF  2D        		.byte	45
 444    0200  20        		.byte	32
 445    0201  2D        		.byte	45
 446    0202  2D        		.byte	45
 447    0203  2D        		.byte	45
 448    0204  2D        		.byte	45
 449    0205  20        		.byte	32
 450    0206  2D        		.byte	45
 451    0207  2D        		.byte	45
 452    0208  2D        		.byte	45
 453    0209  2D        		.byte	45
 454    020A  20        		.byte	32
 455    020B  2D        		.byte	45
 456    020C  2D        		.byte	45
 457    020D  0A        		.byte	10
 458    020E  00        		.byte	0
 459                    	L511:
 460    020F  25        		.byte	37
 461    0210  32        		.byte	50
 462    0211  64        		.byte	100
 463    0212  20        		.byte	32
 464    0213  28        		.byte	40
 465    0214  25        		.byte	37
 466    0215  63        		.byte	99
 467    0216  29        		.byte	41
 468    0217  25        		.byte	37
 469    0218  63        		.byte	99
 470    0219  00        		.byte	0
 471                    	L521:
 472    021A  25        		.byte	37
 473    021B  38        		.byte	56
 474    021C  6C        		.byte	108
 475    021D  75        		.byte	117
 476    021E  20        		.byte	32
 477    021F  25        		.byte	37
 478    0220  38        		.byte	56
 479    0221  6C        		.byte	108
 480    0222  75        		.byte	117
 481    0223  20        		.byte	32
 482    0224  25        		.byte	37
 483    0225  38        		.byte	56
 484    0226  6C        		.byte	108
 485    0227  75        		.byte	117
 486    0228  20        		.byte	32
 487    0229  00        		.byte	0
 488                    	L531:
 489    022A  20        		.byte	32
 490    022B  45        		.byte	69
 491    022C  42        		.byte	66
 492    022D  52        		.byte	82
 493    022E  20        		.byte	32
 494    022F  63        		.byte	99
 495    0230  6F        		.byte	111
 496    0231  6E        		.byte	110
 497    0232  74        		.byte	116
 498    0233  61        		.byte	97
 499    0234  69        		.byte	105
 500    0235  6E        		.byte	110
 501    0236  65        		.byte	101
 502    0237  72        		.byte	114
 503    0238  0A        		.byte	10
 504    0239  00        		.byte	0
 505                    	L541:
 506    023A  20        		.byte	32
 507    023B  47        		.byte	71
 508    023C  50        		.byte	80
 509    023D  54        		.byte	84
 510    023E  20        		.byte	32
 511    023F  00        		.byte	0
 512                    	L551:
 513    0240  43        		.byte	67
 514    0241  50        		.byte	80
 515    0242  2F        		.byte	47
 516    0243  4D        		.byte	77
 517    0244  20        		.byte	32
 518    0245  00        		.byte	0
 519                    	L561:
 520    0246  43        		.byte	67
 521    0247  6F        		.byte	111
 522    0248  64        		.byte	100
 523    0249  65        		.byte	101
 524    024A  20        		.byte	32
 525    024B  00        		.byte	0
 526                    	L571:
 527    024C  20        		.byte	32
 528    024D  3F        		.byte	63
 529    024E  3F        		.byte	63
 530    024F  20        		.byte	32
 531    0250  20        		.byte	32
 532    0251  00        		.byte	0
 533                    	L502:
 534    0252  20        		.byte	32
 535    0253  45        		.byte	69
 536    0254  42        		.byte	66
 537    0255  52        		.byte	82
 538    0256  20        		.byte	32
 539    0257  00        		.byte	0
 540                    	L512:
 541    0258  20        		.byte	32
 542    0259  4D        		.byte	77
 543    025A  42        		.byte	66
 544    025B  52        		.byte	82
 545    025C  20        		.byte	32
 546    025D  00        		.byte	0
 547                    	L522:
 548    025E  43        		.byte	67
 549    025F  50        		.byte	80
 550    0260  2F        		.byte	47
 551    0261  4D        		.byte	77
 552    0262  20        		.byte	32
 553    0263  00        		.byte	0
 554                    	L532:
 555    0264  43        		.byte	67
 556    0265  6F        		.byte	111
 557    0266  64        		.byte	100
 558    0267  65        		.byte	101
 559    0268  20        		.byte	32
 560    0269  00        		.byte	0
 561                    	L542:
 562    026A  20        		.byte	32
 563    026B  3F        		.byte	63
 564    026C  3F        		.byte	63
 565    026D  20        		.byte	32
 566    026E  20        		.byte	32
 567    026F  00        		.byte	0
 568                    	L552:
 569    0270  30        		.byte	48
 570    0271  78        		.byte	120
 571    0272  25        		.byte	37
 572    0273  30        		.byte	48
 573    0274  32        		.byte	50
 574    0275  78        		.byte	120
 575    0276  00        		.byte	0
 576                    	L562:
 577    0277  0A        		.byte	10
 578    0278  00        		.byte	0
 579                    	;   33  
 580                    	;   34  /* Print partitions on SD card
 581                    	;   35   */
 582                    	;   36  void sdpartprint()
 583                    	;   37      {
 584                    	_sdpartprint:
 585    0279  CD0000    		call	c.savs0
 586    027C  21E2FF    		ld	hl,65506
 587    027F  39        		add	hl,sp
 588    0280  F9        		ld	sp,hl
 589                    	;   38      char txtin[10];
 590                    	;   39      int cmdin;
 591                    	;   40      int idx;
 592                    	;   41      int cmpidx;
 593                    	;   42      unsigned char *cmpptr;
 594                    	;   43      int inlength;
 595                    	;   44      unsigned char blockno[4];
 596                    	;   45  
 597                    	;   46      memset(blockno, 0, 4);
 598    0281  210400    		ld	hl,4
 599    0284  E5        		push	hl
 600    0285  210000    		ld	hl,0
 601    0288  E5        		push	hl
 602    0289  DDE5      		push	ix
 603    028B  C1        		pop	bc
 604    028C  21E2FF    		ld	hl,65506
 605    028F  09        		add	hl,bc
 606    0290  CD0000    		call	_memset
 607    0293  F1        		pop	af
 608    0294  F1        		pop	af
 609                    	;   47      memset(curblkno, 0, 4);
 610    0295  210400    		ld	hl,4
 611    0298  E5        		push	hl
 612    0299  210000    		ld	hl,0
 613    029C  E5        		push	hl
 614    029D  210000    		ld	hl,_curblkno
 615    02A0  CD0000    		call	_memset
 616    02A3  F1        		pop	af
 617    02A4  F1        		pop	af
 618                    	;   48      curblkok = NO;
 619    02A5  210000    		ld	hl,0
 620    02A8  220000    		ld	(_curblkok),hl
 621                    	;   49  
 622                    	;   50      printf("      Disk partition sectors on SD card\n");
 623    02AB  215601    		ld	hl,L55
 624    02AE  CD0000    		call	_printf
 625                    	;   51      printf("       MBR disk identifier: 0x%02x%02x%02x%02x\n",
 626                    	;   52         dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
 627    02B1  3A0000    		ld	a,(_dsksign)
 628    02B4  4F        		ld	c,a
 629    02B5  97        		sub	a
 630    02B6  47        		ld	b,a
 631    02B7  C5        		push	bc
 632    02B8  3A0100    		ld	a,(_dsksign+1)
 633    02BB  4F        		ld	c,a
 634    02BC  97        		sub	a
 635    02BD  47        		ld	b,a
 636    02BE  C5        		push	bc
 637    02BF  3A0200    		ld	a,(_dsksign+2)
 638    02C2  4F        		ld	c,a
 639    02C3  97        		sub	a
 640    02C4  47        		ld	b,a
 641    02C5  C5        		push	bc
 642    02C6  3A0300    		ld	a,(_dsksign+3)
 643    02C9  4F        		ld	c,a
 644    02CA  97        		sub	a
 645    02CB  47        		ld	b,a
 646    02CC  C5        		push	bc
 647    02CD  217F01    		ld	hl,L56
 648    02D0  CD0000    		call	_printf
 649    02D3  F1        		pop	af
 650    02D4  F1        		pop	af
 651    02D5  F1        		pop	af
 652    02D6  F1        		pop	af
 653                    	;   53      printf(" Disk     Start      End     Size Part Type Id\n");
 654    02D7  21AF01    		ld	hl,L57
 655    02DA  CD0000    		call	_printf
 656                    	;   54      printf(" ----     -----      ---     ---- ---- ---- --\n");
 657    02DD  21DF01    		ld	hl,L501
 658    02E0  CD0000    		call	_printf
 659                    	;   55      for (idx = 0; idx < 16; idx++)
 660    02E3  DD36EC00  		ld	(ix-20),0
 661    02E7  DD36ED00  		ld	(ix-19),0
 662                    	L1:
 663    02EB  DD7EEC    		ld	a,(ix-20)
 664    02EE  D610      		sub	16
 665    02F0  DD7EED    		ld	a,(ix-19)
 666    02F3  DE00      		sbc	a,0
 667    02F5  F23105    		jp	p,L11
 668                    	;   56         {
 669                    	;   57         if (parptr[idx].parident)
 670    02F8  DD6EEC    		ld	l,(ix-20)
 671    02FB  DD66ED    		ld	h,(ix-19)
 672    02FE  E5        		push	hl
 673    02FF  211000    		ld	hl,16
 674    0302  E5        		push	hl
 675    0303  CD0000    		call	c.imul
 676    0306  E1        		pop	hl
 677    0307  ED4B0000  		ld	bc,(_parptr)
 678    030B  09        		add	hl,bc
 679    030C  7E        		ld	a,(hl)
 680    030D  B7        		or	a
 681    030E  CAEF03    		jp	z,L12
 682                    	;   58              {
 683                    	;   59              printf("%2d (%c)%c", idx + 1, idx + 'A',
 684                    	;   60                 parptr[idx].bootable ? '*' : ' ');
 685    0311  DD6EEC    		ld	l,(ix-20)
 686    0314  DD66ED    		ld	h,(ix-19)
 687    0317  E5        		push	hl
 688    0318  211000    		ld	hl,16
 689    031B  E5        		push	hl
 690    031C  CD0000    		call	c.imul
 691    031F  E1        		pop	hl
 692    0320  ED4B0000  		ld	bc,(_parptr)
 693    0324  09        		add	hl,bc
 694    0325  23        		inc	hl
 695    0326  23        		inc	hl
 696    0327  7E        		ld	a,(hl)
 697    0328  B7        		or	a
 698    0329  2805      		jr	z,L01
 699    032B  012A00    		ld	bc,42
 700    032E  1803      		jr	L21
 701                    	L01:
 702    0330  012000    		ld	bc,32
 703                    	L21:
 704    0333  C5        		push	bc
 705    0334  DD6EEC    		ld	l,(ix-20)
 706    0337  DD66ED    		ld	h,(ix-19)
 707    033A  014100    		ld	bc,65
 708    033D  09        		add	hl,bc
 709    033E  E5        		push	hl
 710    033F  DD6EEC    		ld	l,(ix-20)
 711    0342  DD66ED    		ld	h,(ix-19)
 712    0345  23        		inc	hl
 713    0346  E5        		push	hl
 714    0347  210F02    		ld	hl,L511
 715    034A  CD0000    		call	_printf
 716    034D  F1        		pop	af
 717    034E  F1        		pop	af
 718    034F  F1        		pop	af
 719                    	;   61                 printf("%8lu %8lu %8lu ",
 720                    	;   62                     blk2ul(parptr[idx].parstart),
 721                    	;   63                     blk2ul(parptr[idx].parend),
 722                    	;   64                     blk2ul(parptr[idx].parsize));
 723    0350  DD6EEC    		ld	l,(ix-20)
 724    0353  DD66ED    		ld	h,(ix-19)
 725    0356  E5        		push	hl
 726    0357  211000    		ld	hl,16
 727    035A  E5        		push	hl
 728    035B  CD0000    		call	c.imul
 729    035E  E1        		pop	hl
 730    035F  ED4B0000  		ld	bc,(_parptr)
 731    0363  09        		add	hl,bc
 732    0364  010C00    		ld	bc,12
 733    0367  09        		add	hl,bc
 734    0368  CD0000    		call	_blk2ul
 735    036B  210300    		ld	hl,c.r0+3
 736    036E  46        		ld	b,(hl)
 737    036F  2B        		dec	hl
 738    0370  4E        		ld	c,(hl)
 739    0371  C5        		push	bc
 740    0372  2B        		dec	hl
 741    0373  46        		ld	b,(hl)
 742    0374  2B        		dec	hl
 743    0375  4E        		ld	c,(hl)
 744    0376  C5        		push	bc
 745    0377  DD6EEC    		ld	l,(ix-20)
 746    037A  DD66ED    		ld	h,(ix-19)
 747    037D  E5        		push	hl
 748    037E  211000    		ld	hl,16
 749    0381  E5        		push	hl
 750    0382  CD0000    		call	c.imul
 751    0385  E1        		pop	hl
 752    0386  ED4B0000  		ld	bc,(_parptr)
 753    038A  09        		add	hl,bc
 754    038B  010800    		ld	bc,8
 755    038E  09        		add	hl,bc
 756    038F  CD0000    		call	_blk2ul
 757    0392  210300    		ld	hl,c.r0+3
 758    0395  46        		ld	b,(hl)
 759    0396  2B        		dec	hl
 760    0397  4E        		ld	c,(hl)
 761    0398  C5        		push	bc
 762    0399  2B        		dec	hl
 763    039A  46        		ld	b,(hl)
 764    039B  2B        		dec	hl
 765    039C  4E        		ld	c,(hl)
 766    039D  C5        		push	bc
 767    039E  DD6EEC    		ld	l,(ix-20)
 768    03A1  DD66ED    		ld	h,(ix-19)
 769    03A4  E5        		push	hl
 770    03A5  211000    		ld	hl,16
 771    03A8  E5        		push	hl
 772    03A9  CD0000    		call	c.imul
 773    03AC  E1        		pop	hl
 774    03AD  ED4B0000  		ld	bc,(_parptr)
 775    03B1  09        		add	hl,bc
 776    03B2  23        		inc	hl
 777    03B3  23        		inc	hl
 778    03B4  23        		inc	hl
 779    03B5  23        		inc	hl
 780    03B6  CD0000    		call	_blk2ul
 781    03B9  210300    		ld	hl,c.r0+3
 782    03BC  46        		ld	b,(hl)
 783    03BD  2B        		dec	hl
 784    03BE  4E        		ld	c,(hl)
 785    03BF  C5        		push	bc
 786    03C0  2B        		dec	hl
 787    03C1  46        		ld	b,(hl)
 788    03C2  2B        		dec	hl
 789    03C3  4E        		ld	c,(hl)
 790    03C4  C5        		push	bc
 791    03C5  211A02    		ld	hl,L521
 792    03C8  CD0000    		call	_printf
 793    03CB  210C00    		ld	hl,12
 794    03CE  39        		add	hl,sp
 795    03CF  F9        		ld	sp,hl
 796                    	;   65              if (parptr[idx].parident == EBRCONT)
 797    03D0  DD6EEC    		ld	l,(ix-20)
 798    03D3  DD66ED    		ld	h,(ix-19)
 799    03D6  E5        		push	hl
 800    03D7  211000    		ld	hl,16
 801    03DA  E5        		push	hl
 802    03DB  CD0000    		call	c.imul
 803    03DE  E1        		pop	hl
 804    03DF  ED4B0000  		ld	bc,(_parptr)
 805    03E3  09        		add	hl,bc
 806    03E4  7E        		ld	a,(hl)
 807    03E5  FE14      		cp	20
 808    03E7  2011      		jr	nz,L15
 809                    	;   66                  printf(" EBR container\n");
 810    03E9  212A02    		ld	hl,L531
 811    03EC  CD0000    		call	_printf
 812                    	;   67              else
 813                    	L12:
 814    03EF  DD34EC    		inc	(ix-20)
 815    03F2  2003      		jr	nz,L6
 816    03F4  DD34ED    		inc	(ix-19)
 817                    	L6:
 818    03F7  C3EB02    		jp	L1
 819                    	L15:
 820                    	;   68                  {
 821                    	;   69                  if (parptr[idx].parident == PARTGPT)
 822    03FA  DD6EEC    		ld	l,(ix-20)
 823    03FD  DD66ED    		ld	h,(ix-19)
 824    0400  E5        		push	hl
 825    0401  211000    		ld	hl,16
 826    0404  E5        		push	hl
 827    0405  CD0000    		call	c.imul
 828    0408  E1        		pop	hl
 829    0409  ED4B0000  		ld	bc,(_parptr)
 830    040D  09        		add	hl,bc
 831    040E  7E        		ld	a,(hl)
 832    040F  FE03      		cp	3
 833    0411  C29104    		jp	nz,L17
 834                    	;   70                      {
 835                    	;   71                      printf(" GPT ");
 836    0414  213A02    		ld	hl,L541
 837    0417  CD0000    		call	_printf
 838                    	;   72                      if (!memcmp(guidmap[idx].parguid, gptcpm, 16))
 839    041A  211000    		ld	hl,16
 840    041D  E5        		push	hl
 841    041E  210000    		ld	hl,_gptcpm
 842    0421  E5        		push	hl
 843    0422  DD6EEC    		ld	l,(ix-20)
 844    0425  DD66ED    		ld	h,(ix-19)
 845    0428  E5        		push	hl
 846    0429  211000    		ld	hl,16
 847    042C  E5        		push	hl
 848    042D  CD0000    		call	c.imul
 849    0430  E1        		pop	hl
 850    0431  010000    		ld	bc,_guidmap
 851    0434  09        		add	hl,bc
 852    0435  CD0000    		call	_memcmp
 853    0438  F1        		pop	af
 854    0439  F1        		pop	af
 855    043A  79        		ld	a,c
 856    043B  B0        		or	b
 857    043C  2008      		jr	nz,L101
 858                    	;   73                          printf("CP/M ");
 859    043E  214002    		ld	hl,L551
 860    0441  CD0000    		call	_printf
 861                    	;   74                      else if (!memcmp(guidmap[idx].parguid, gptexcode, 16))
 862    0444  1832      		jr	L111
 863                    	L101:
 864    0446  211000    		ld	hl,16
 865    0449  E5        		push	hl
 866    044A  210000    		ld	hl,_gptexcode
 867    044D  E5        		push	hl
 868    044E  DD6EEC    		ld	l,(ix-20)
 869    0451  DD66ED    		ld	h,(ix-19)
 870    0454  E5        		push	hl
 871    0455  211000    		ld	hl,16
 872    0458  E5        		push	hl
 873    0459  CD0000    		call	c.imul
 874    045C  E1        		pop	hl
 875    045D  010000    		ld	bc,_guidmap
 876    0460  09        		add	hl,bc
 877    0461  CD0000    		call	_memcmp
 878    0464  F1        		pop	af
 879    0465  F1        		pop	af
 880    0466  79        		ld	a,c
 881    0467  B0        		or	b
 882    0468  2008      		jr	nz,L121
 883                    	;   75                          printf("Code ");
 884    046A  214602    		ld	hl,L561
 885    046D  CD0000    		call	_printf
 886                    	;   76                      else
 887    0470  1806      		jr	L111
 888                    	L121:
 889                    	;   77                          printf(" ??  ");
 890    0472  214C02    		ld	hl,L571
 891    0475  CD0000    		call	_printf
 892                    	L111:
 893                    	;   78                      prtguid(guidmap[idx].parguid);
 894    0478  DD6EEC    		ld	l,(ix-20)
 895    047B  DD66ED    		ld	h,(ix-19)
 896    047E  E5        		push	hl
 897    047F  211000    		ld	hl,16
 898    0482  E5        		push	hl
 899    0483  CD0000    		call	c.imul
 900    0486  E1        		pop	hl
 901    0487  010000    		ld	bc,_guidmap
 902    048A  09        		add	hl,bc
 903    048B  CD4900    		call	_prtguid
 904                    	;   79                      }
 905                    	;   80                  else
 906    048E  C32805    		jp	L141
 907                    	L17:
 908                    	;   81                      {
 909                    	;   82                      if (parptr[idx].parident == PARTEBR)
 910    0491  DD6EEC    		ld	l,(ix-20)
 911    0494  DD66ED    		ld	h,(ix-19)
 912    0497  E5        		push	hl
 913    0498  211000    		ld	hl,16
 914    049B  E5        		push	hl
 915    049C  CD0000    		call	c.imul
 916    049F  E1        		pop	hl
 917    04A0  ED4B0000  		ld	bc,(_parptr)
 918    04A4  09        		add	hl,bc
 919    04A5  7E        		ld	a,(hl)
 920    04A6  FE02      		cp	2
 921    04A8  2008      		jr	nz,L151
 922                    	;   83                          printf(" EBR ");
 923    04AA  215202    		ld	hl,L502
 924    04AD  CD0000    		call	_printf
 925                    	;   84                      else
 926    04B0  1806      		jr	L161
 927                    	L151:
 928                    	;   85                          printf(" MBR ");
 929    04B2  215802    		ld	hl,L512
 930    04B5  CD0000    		call	_printf
 931                    	L161:
 932                    	;   86                      if (parptr[idx].partype == mbrcpm)
 933    04B8  DD6EEC    		ld	l,(ix-20)
 934    04BB  DD66ED    		ld	h,(ix-19)
 935    04BE  E5        		push	hl
 936    04BF  211000    		ld	hl,16
 937    04C2  E5        		push	hl
 938    04C3  CD0000    		call	c.imul
 939    04C6  E1        		pop	hl
 940    04C7  ED4B0000  		ld	bc,(_parptr)
 941    04CB  09        		add	hl,bc
 942    04CC  23        		inc	hl
 943    04CD  3A0000    		ld	a,(_mbrcpm)
 944    04D0  4F        		ld	c,a
 945    04D1  7E        		ld	a,(hl)
 946    04D2  B9        		cp	c
 947    04D3  2008      		jr	nz,L171
 948                    	;   87                          printf("CP/M ");
 949    04D5  215E02    		ld	hl,L522
 950    04D8  CD0000    		call	_printf
 951                    	;   88                      else if (parptr[idx].partype == mbrexcode)
 952    04DB  182B      		jr	L102
 953                    	L171:
 954    04DD  DD6EEC    		ld	l,(ix-20)
 955    04E0  DD66ED    		ld	h,(ix-19)
 956    04E3  E5        		push	hl
 957    04E4  211000    		ld	hl,16
 958    04E7  E5        		push	hl
 959    04E8  CD0000    		call	c.imul
 960    04EB  E1        		pop	hl
 961    04EC  ED4B0000  		ld	bc,(_parptr)
 962    04F0  09        		add	hl,bc
 963    04F1  23        		inc	hl
 964    04F2  3A0000    		ld	a,(_mbrexcode)
 965    04F5  4F        		ld	c,a
 966    04F6  7E        		ld	a,(hl)
 967    04F7  B9        		cp	c
 968    04F8  2008      		jr	nz,L112
 969                    	;   89                          printf("Code ");
 970    04FA  216402    		ld	hl,L532
 971    04FD  CD0000    		call	_printf
 972                    	;   90                      else
 973    0500  1806      		jr	L102
 974                    	L112:
 975                    	;   91                          printf(" ??  ");
 976    0502  216A02    		ld	hl,L542
 977    0505  CD0000    		call	_printf
 978                    	L102:
 979                    	;   92                      printf("0x%02x", parptr[idx].partype);
 980    0508  DD6EEC    		ld	l,(ix-20)
 981    050B  DD66ED    		ld	h,(ix-19)
 982    050E  E5        		push	hl
 983    050F  211000    		ld	hl,16
 984    0512  E5        		push	hl
 985    0513  CD0000    		call	c.imul
 986    0516  E1        		pop	hl
 987    0517  ED4B0000  		ld	bc,(_parptr)
 988    051B  09        		add	hl,bc
 989    051C  23        		inc	hl
 990    051D  4E        		ld	c,(hl)
 991    051E  97        		sub	a
 992    051F  47        		ld	b,a
 993    0520  C5        		push	bc
 994    0521  217002    		ld	hl,L552
 995    0524  CD0000    		call	_printf
 996    0527  F1        		pop	af
 997                    	L141:
 998                    	;   93                      }
 999                    	;   94                  printf("\n");
1000    0528  217702    		ld	hl,L562
1001    052B  CD0000    		call	_printf
1002    052E  C3EF03    		jp	L12
1003                    	L11:
1004                    	;   95                  }
1005                    	;   96              }
1006                    	;   97          }
1007                    	;   98      }
1008    0531  C30000    		jp	c.rets0
1009                    	;   99  
1010                    		.external	c.rets0
1011                    		.external	_curblkno
1012                    		.external	c.savs0
1013                    		.external	_curblkok
1014                    		.external	_parptr
1015                    		.external	c.r0
1016                    		.external	_printf
1017                    		.external	_blk2ul
1018                    		.external	_gptcpm
1019                    		.external	_memset
1020                    		.external	_gptexcode
1021                    		.external	_mbrcpm
1022                    		.external	_memcmp
1023                    		.public	_prtguid
1024                    		.public	_sdpartprint
1025                    		.external	_mbrexcode
1026                    		.external	_dsksign
1027                    		.external	c.rets
1028                    		.external	c.savs
1029                    		.external	c.imul
1030                    		.external	_guidmap
1031                    		.end
