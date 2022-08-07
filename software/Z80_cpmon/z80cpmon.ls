   1                    	;    1  /*  z80prog.c Boot and SD card test program.
   2                    	;    2   *
   3                    	;    3   *  Boot code for my DIY Z80 Computer. This
   4                    	;    4   *  program is compiled with Whitesmiths/COSMIC
   5                    	;    5   *  C compiler for Z80.
   6                    	;    6   *
   7                    	;    7   *  Initializes the hardware and detects the
   8                    	;    8   *  presence and partitioning of an attached SD card.
   9                    	;    9   *
  10                    	;   10   *  You are free to use, modify, and redistribute
  11                    	;   11   *  this source code. No warranties are given.
  12                    	;   12   *  Hastily Cobbled Together 2021 and 2022
  13                    	;   13   *  by Hans-Ake Lund
  14                    	;   14   *
  15                    	;   15   */
  16                    	;   16  
  17                    	;   17  #include <std.h>
  18                    	;   18  #include "z80comp.h"
  19                    	;   19  #include "z80sd.h"
  20                    	;   20  #include "cpmbiosadr.h"
  21                    	;   21  /* Program name and version */
  22                    	;   22  #define PRGNAME "z80cpmon "
  23                    	;   23  #define VERSION "version 1.0, "
  24                    	;   24  
  25                    	;   25  unsigned int *upladrptr; /* upload address pointer */
  26                    	;   26  unsigned int *exeadrptr; /* execute address pointer */
  27                    	;   27  
  28                    	;   28  /* External data */
  29                    	;   29  extern const char upload[];
  30                    	;   30  extern const int upload_size;
  31                    	;   31  extern const int binsize;
  32                    	;   32  extern const int binstart;
  33                    	;   33  extern const char cpmsys[];
  34                    	;   34  extern const int cpmsys_size;
  35                    	;   35  
  36                    	;   36  extern const char builddate[];
  37                    	;   37  
  38                    	;   38  /* RAM/EPROM probe */
  39                    	;   39  const int ramprobe = 0;
  40                    		.psect	_text
  41                    	_ramprobe:
  42                    		.byte	[2]
  43                    	L5:
  44    0002  2C        		.byte	44
  45    0003  20        		.byte	32
  46    0004  65        		.byte	101
  47    0005  78        		.byte	120
  48    0006  65        		.byte	101
  49    0007  63        		.byte	99
  50    0008  75        		.byte	117
  51    0009  74        		.byte	116
  52    000A  69        		.byte	105
  53    000B  6E        		.byte	110
  54    000C  67        		.byte	103
  55    000D  20        		.byte	32
  56    000E  69        		.byte	105
  57    000F  6E        		.byte	110
  58    0010  3A        		.byte	58
  59    0011  20        		.byte	32
  60    0012  00        		.byte	0
  61                    	L51:
  62    0013  52        		.byte	82
  63    0014  41        		.byte	65
  64    0015  4D        		.byte	77
  65    0016  0A        		.byte	10
  66    0017  00        		.byte	0
  67                    	L52:
  68    0018  45        		.byte	69
  69    0019  50        		.byte	80
  70    001A  52        		.byte	82
  71    001B  4F        		.byte	79
  72    001C  4D        		.byte	77
  73    001D  0A        		.byte	10
  74    001E  00        		.byte	0
  75                    	;   40  int *rampptr;
  76                    	;   41  
  77                    	;   42  /* Executing in RAM or EPROM
  78                    	;   43   */
  79                    	;   44  void execin()
  80                    	;   45      {
  81                    	_execin:
  82                    	;   46      printf(", executing in: ");
  83    001F  210200    		ld	hl,L5
  84    0022  CD0000    		call	_printf
  85                    	;   47      rampptr = &ramprobe;
  86    0025  210000    		ld	hl,_ramprobe
  87                    	;   48      *rampptr = 1; /* try to change const */
  88    0028  220000    		ld	(_rampptr),hl
  89    002B  3601      		ld	(hl),1
  90    002D  23        		inc	hl
  91    002E  3600      		ld	(hl),0
  92                    	;   49      if (ramprobe)
  93    0030  2A0000    		ld	hl,(_ramprobe)
  94    0033  7C        		ld	a,h
  95    0034  B5        		or	l
  96    0035  2808      		jr	z,L1
  97                    	;   50          printf("RAM\n");
  98    0037  211300    		ld	hl,L51
  99    003A  CD0000    		call	_printf
 100                    	;   51      else
 101    003D  1806      		jr	L11
 102                    	L1:
 103                    	;   52          printf("EPROM\n");
 104    003F  211800    		ld	hl,L52
 105    0042  CD0000    		call	_printf
 106                    	L11:
 107                    	;   53      *rampptr = 0;
 108    0045  2A0000    		ld	hl,(_rampptr)
 109    0048  3600      		ld	(hl),0
 110    004A  23        		inc	hl
 111    004B  3600      		ld	(hl),0
 112                    	;   54      }
 113    004D  C9        		ret 
 114                    	L53:
 115    004E  7A        		.byte	122
 116    004F  38        		.byte	56
 117    0050  30        		.byte	48
 118    0051  63        		.byte	99
 119    0052  70        		.byte	112
 120    0053  6D        		.byte	109
 121    0054  6F        		.byte	111
 122    0055  6E        		.byte	110
 123    0056  20        		.byte	32
 124    0057  00        		.byte	0
 125                    	L54:
 126    0058  76        		.byte	118
 127    0059  65        		.byte	101
 128    005A  72        		.byte	114
 129    005B  73        		.byte	115
 130    005C  69        		.byte	105
 131    005D  6F        		.byte	111
 132    005E  6E        		.byte	110
 133    005F  20        		.byte	32
 134    0060  31        		.byte	49
 135    0061  2E        		.byte	46
 136    0062  30        		.byte	48
 137    0063  2C        		.byte	44
 138    0064  20        		.byte	32
 139    0065  00        		.byte	0
 140                    	L55:
 141    0066  63        		.byte	99
 142    0067  6D        		.byte	109
 143    0068  64        		.byte	100
 144    0069  20        		.byte	32
 145    006A  28        		.byte	40
 146    006B  3F        		.byte	63
 147    006C  20        		.byte	32
 148    006D  66        		.byte	102
 149    006E  6F        		.byte	111
 150    006F  72        		.byte	114
 151    0070  20        		.byte	32
 152    0071  68        		.byte	104
 153    0072  65        		.byte	101
 154    0073  6C        		.byte	108
 155    0074  70        		.byte	112
 156    0075  29        		.byte	41
 157    0076  3A        		.byte	58
 158    0077  20        		.byte	32
 159    0078  00        		.byte	0
 160                    	L56:
 161    0079  20        		.byte	32
 162    007A  3F        		.byte	63
 163    007B  20        		.byte	32
 164    007C  2D        		.byte	45
 165    007D  20        		.byte	32
 166    007E  68        		.byte	104
 167    007F  65        		.byte	101
 168    0080  6C        		.byte	108
 169    0081  70        		.byte	112
 170    0082  0A        		.byte	10
 171    0083  00        		.byte	0
 172                    	L57:
 173    0084  7A        		.byte	122
 174    0085  38        		.byte	56
 175    0086  30        		.byte	48
 176    0087  63        		.byte	99
 177    0088  70        		.byte	112
 178    0089  6D        		.byte	109
 179    008A  6F        		.byte	111
 180    008B  6E        		.byte	110
 181    008C  20        		.byte	32
 182    008D  00        		.byte	0
 183                    	L501:
 184    008E  76        		.byte	118
 185    008F  65        		.byte	101
 186    0090  72        		.byte	114
 187    0091  73        		.byte	115
 188    0092  69        		.byte	105
 189    0093  6F        		.byte	111
 190    0094  6E        		.byte	110
 191    0095  20        		.byte	32
 192    0096  31        		.byte	49
 193    0097  2E        		.byte	46
 194    0098  30        		.byte	48
 195    0099  2C        		.byte	44
 196    009A  20        		.byte	32
 197    009B  00        		.byte	0
 198                    	L511:
 199    009C  43        		.byte	67
 200    009D  6F        		.byte	111
 201    009E  6D        		.byte	109
 202    009F  6D        		.byte	109
 203    00A0  61        		.byte	97
 204    00A1  6E        		.byte	110
 205    00A2  64        		.byte	100
 206    00A3  73        		.byte	115
 207    00A4  3A        		.byte	58
 208    00A5  0A        		.byte	10
 209    00A6  00        		.byte	0
 210                    	L521:
 211    00A7  20        		.byte	32
 212    00A8  20        		.byte	32
 213    00A9  3F        		.byte	63
 214    00AA  20        		.byte	32
 215    00AB  2D        		.byte	45
 216    00AC  20        		.byte	32
 217    00AD  68        		.byte	104
 218    00AE  65        		.byte	101
 219    00AF  6C        		.byte	108
 220    00B0  70        		.byte	112
 221    00B1  0A        		.byte	10
 222    00B2  00        		.byte	0
 223                    	L531:
 224    00B3  20        		.byte	32
 225    00B4  20        		.byte	32
 226    00B5  61        		.byte	97
 227    00B6  20        		.byte	32
 228    00B7  2D        		.byte	45
 229    00B8  20        		.byte	32
 230    00B9  73        		.byte	115
 231    00BA  65        		.byte	101
 232    00BB  74        		.byte	116
 233    00BC  20        		.byte	32
 234    00BD  61        		.byte	97
 235    00BE  64        		.byte	100
 236    00BF  64        		.byte	100
 237    00C0  72        		.byte	114
 238    00C1  65        		.byte	101
 239    00C2  73        		.byte	115
 240    00C3  73        		.byte	115
 241    00C4  20        		.byte	32
 242    00C5  66        		.byte	102
 243    00C6  6F        		.byte	111
 244    00C7  72        		.byte	114
 245    00C8  20        		.byte	32
 246    00C9  75        		.byte	117
 247    00CA  70        		.byte	112
 248    00CB  6C        		.byte	108
 249    00CC  6F        		.byte	111
 250    00CD  61        		.byte	97
 251    00CE  64        		.byte	100
 252    00CF  0A        		.byte	10
 253    00D0  00        		.byte	0
 254                    	L541:
 255    00D1  20        		.byte	32
 256    00D2  20        		.byte	32
 257    00D3  63        		.byte	99
 258    00D4  20        		.byte	32
 259    00D5  2D        		.byte	45
 260    00D6  20        		.byte	32
 261    00D7  62        		.byte	98
 262    00D8  6F        		.byte	111
 263    00D9  6F        		.byte	111
 264    00DA  74        		.byte	116
 265    00DB  20        		.byte	32
 266    00DC  43        		.byte	67
 267    00DD  50        		.byte	80
 268    00DE  2F        		.byte	47
 269    00DF  4D        		.byte	77
 270    00E0  20        		.byte	32
 271    00E1  66        		.byte	102
 272    00E2  72        		.byte	114
 273    00E3  6F        		.byte	111
 274    00E4  6D        		.byte	109
 275    00E5  20        		.byte	32
 276    00E6  45        		.byte	69
 277    00E7  50        		.byte	80
 278    00E8  52        		.byte	82
 279    00E9  4F        		.byte	79
 280    00EA  4D        		.byte	77
 281    00EB  0A        		.byte	10
 282    00EC  00        		.byte	0
 283                    	L551:
 284    00ED  20        		.byte	32
 285    00EE  20        		.byte	32
 286    00EF  64        		.byte	100
 287    00F0  20        		.byte	32
 288    00F1  2D        		.byte	45
 289    00F2  20        		.byte	32
 290    00F3  64        		.byte	100
 291    00F4  75        		.byte	117
 292    00F5  6D        		.byte	109
 293    00F6  70        		.byte	112
 294    00F7  20        		.byte	32
 295    00F8  6D        		.byte	109
 296    00F9  65        		.byte	101
 297    00FA  6D        		.byte	109
 298    00FB  6F        		.byte	111
 299    00FC  72        		.byte	114
 300    00FD  79        		.byte	121
 301    00FE  20        		.byte	32
 302    00FF  63        		.byte	99
 303    0100  6F        		.byte	111
 304    0101  6E        		.byte	110
 305    0102  74        		.byte	116
 306    0103  65        		.byte	101
 307    0104  6E        		.byte	110
 308    0105  74        		.byte	116
 309    0106  20        		.byte	32
 310    0107  74        		.byte	116
 311    0108  6F        		.byte	111
 312    0109  20        		.byte	32
 313    010A  73        		.byte	115
 314    010B  63        		.byte	99
 315    010C  72        		.byte	114
 316    010D  65        		.byte	101
 317    010E  65        		.byte	101
 318    010F  6E        		.byte	110
 319    0110  0A        		.byte	10
 320    0111  00        		.byte	0
 321                    	L561:
 322    0112  20        		.byte	32
 323    0113  20        		.byte	32
 324    0114  65        		.byte	101
 325    0115  20        		.byte	32
 326    0116  2D        		.byte	45
 327    0117  20        		.byte	32
 328    0118  73        		.byte	115
 329    0119  65        		.byte	101
 330    011A  74        		.byte	116
 331    011B  20        		.byte	32
 332    011C  61        		.byte	97
 333    011D  64        		.byte	100
 334    011E  64        		.byte	100
 335    011F  72        		.byte	114
 336    0120  65        		.byte	101
 337    0121  73        		.byte	115
 338    0122  73        		.byte	115
 339    0123  20        		.byte	32
 340    0124  66        		.byte	102
 341    0125  6F        		.byte	111
 342    0126  72        		.byte	114
 343    0127  20        		.byte	32
 344    0128  65        		.byte	101
 345    0129  78        		.byte	120
 346    012A  65        		.byte	101
 347    012B  63        		.byte	99
 348    012C  75        		.byte	117
 349    012D  74        		.byte	116
 350    012E  65        		.byte	101
 351    012F  0A        		.byte	10
 352    0130  00        		.byte	0
 353                    	L571:
 354    0131  20        		.byte	32
 355    0132  20        		.byte	32
 356    0133  69        		.byte	105
 357    0134  20        		.byte	32
 358    0135  2D        		.byte	45
 359    0136  20        		.byte	32
 360    0137  69        		.byte	105
 361    0138  6E        		.byte	110
 362    0139  69        		.byte	105
 363    013A  74        		.byte	116
 364    013B  69        		.byte	105
 365    013C  61        		.byte	97
 366    013D  6C        		.byte	108
 367    013E  69        		.byte	105
 368    013F  7A        		.byte	122
 369    0140  65        		.byte	101
 370    0141  20        		.byte	32
 371    0142  53        		.byte	83
 372    0143  44        		.byte	68
 373    0144  20        		.byte	32
 374    0145  63        		.byte	99
 375    0146  61        		.byte	97
 376    0147  72        		.byte	114
 377    0148  64        		.byte	100
 378    0149  0A        		.byte	10
 379    014A  00        		.byte	0
 380                    	L502:
 381    014B  20        		.byte	32
 382    014C  20        		.byte	32
 383    014D  6C        		.byte	108
 384    014E  20        		.byte	32
 385    014F  2D        		.byte	45
 386    0150  20        		.byte	32
 387    0151  70        		.byte	112
 388    0152  72        		.byte	114
 389    0153  69        		.byte	105
 390    0154  6E        		.byte	110
 391    0155  74        		.byte	116
 392    0156  20        		.byte	32
 393    0157  53        		.byte	83
 394    0158  44        		.byte	68
 395    0159  20        		.byte	32
 396    015A  63        		.byte	99
 397    015B  61        		.byte	97
 398    015C  72        		.byte	114
 399    015D  64        		.byte	100
 400    015E  20        		.byte	32
 401    015F  70        		.byte	112
 402    0160  61        		.byte	97
 403    0161  72        		.byte	114
 404    0162  74        		.byte	116
 405    0163  69        		.byte	105
 406    0164  74        		.byte	116
 407    0165  69        		.byte	105
 408    0166  6F        		.byte	111
 409    0167  6E        		.byte	110
 410    0168  20        		.byte	32
 411    0169  6C        		.byte	108
 412    016A  61        		.byte	97
 413    016B  79        		.byte	121
 414    016C  6F        		.byte	111
 415    016D  75        		.byte	117
 416    016E  74        		.byte	116
 417    016F  0A        		.byte	10
 418    0170  00        		.byte	0
 419                    	L512:
 420    0171  20        		.byte	32
 421    0172  20        		.byte	32
 422    0173  6E        		.byte	110
 423    0174  20        		.byte	32
 424    0175  2D        		.byte	45
 425    0176  20        		.byte	32
 426    0177  73        		.byte	115
 427    0178  65        		.byte	101
 428    0179  74        		.byte	116
 429    017A  2F        		.byte	47
 430    017B  73        		.byte	115
 431    017C  68        		.byte	104
 432    017D  6F        		.byte	111
 433    017E  77        		.byte	119
 434    017F  20        		.byte	32
 435    0180  62        		.byte	98
 436    0181  6C        		.byte	108
 437    0182  6F        		.byte	111
 438    0183  63        		.byte	99
 439    0184  6B        		.byte	107
 440    0185  20        		.byte	32
 441    0186  23        		.byte	35
 442    0187  4E        		.byte	78
 443    0188  20        		.byte	32
 444    0189  74        		.byte	116
 445    018A  6F        		.byte	111
 446    018B  20        		.byte	32
 447    018C  72        		.byte	114
 448    018D  65        		.byte	101
 449    018E  61        		.byte	97
 450    018F  64        		.byte	100
 451    0190  2F        		.byte	47
 452    0191  77        		.byte	119
 453    0192  72        		.byte	114
 454    0193  69        		.byte	105
 455    0194  74        		.byte	116
 456    0195  65        		.byte	101
 457    0196  0A        		.byte	10
 458    0197  00        		.byte	0
 459                    	L522:
 460    0198  20        		.byte	32
 461    0199  20        		.byte	32
 462    019A  70        		.byte	112
 463    019B  20        		.byte	32
 464    019C  2D        		.byte	45
 465    019D  20        		.byte	32
 466    019E  70        		.byte	112
 467    019F  72        		.byte	114
 468    01A0  69        		.byte	105
 469    01A1  6E        		.byte	110
 470    01A2  74        		.byte	116
 471    01A3  20        		.byte	32
 472    01A4  62        		.byte	98
 473    01A5  6C        		.byte	108
 474    01A6  6F        		.byte	111
 475    01A7  63        		.byte	99
 476    01A8  6B        		.byte	107
 477    01A9  20        		.byte	32
 478    01AA  6C        		.byte	108
 479    01AB  61        		.byte	97
 480    01AC  73        		.byte	115
 481    01AD  74        		.byte	116
 482    01AE  20        		.byte	32
 483    01AF  72        		.byte	114
 484    01B0  65        		.byte	101
 485    01B1  61        		.byte	97
 486    01B2  64        		.byte	100
 487    01B3  2F        		.byte	47
 488    01B4  74        		.byte	116
 489    01B5  6F        		.byte	111
 490    01B6  20        		.byte	32
 491    01B7  77        		.byte	119
 492    01B8  72        		.byte	114
 493    01B9  69        		.byte	105
 494    01BA  74        		.byte	116
 495    01BB  65        		.byte	101
 496    01BC  0A        		.byte	10
 497    01BD  00        		.byte	0
 498                    	L532:
 499    01BE  20        		.byte	32
 500    01BF  20        		.byte	32
 501    01C0  72        		.byte	114
 502    01C1  20        		.byte	32
 503    01C2  2D        		.byte	45
 504    01C3  20        		.byte	32
 505    01C4  72        		.byte	114
 506    01C5  65        		.byte	101
 507    01C6  61        		.byte	97
 508    01C7  64        		.byte	100
 509    01C8  20        		.byte	32
 510    01C9  62        		.byte	98
 511    01CA  6C        		.byte	108
 512    01CB  6F        		.byte	111
 513    01CC  63        		.byte	99
 514    01CD  6B        		.byte	107
 515    01CE  20        		.byte	32
 516    01CF  23        		.byte	35
 517    01D0  4E        		.byte	78
 518    01D1  0A        		.byte	10
 519    01D2  00        		.byte	0
 520                    	L542:
 521    01D3  20        		.byte	32
 522    01D4  20        		.byte	32
 523    01D5  73        		.byte	115
 524    01D6  20        		.byte	32
 525    01D7  2D        		.byte	45
 526    01D8  20        		.byte	32
 527    01D9  70        		.byte	112
 528    01DA  72        		.byte	114
 529    01DB  69        		.byte	105
 530    01DC  6E        		.byte	110
 531    01DD  74        		.byte	116
 532    01DE  20        		.byte	32
 533    01DF  53        		.byte	83
 534    01E0  44        		.byte	68
 535    01E1  20        		.byte	32
 536    01E2  72        		.byte	114
 537    01E3  65        		.byte	101
 538    01E4  67        		.byte	103
 539    01E5  69        		.byte	105
 540    01E6  73        		.byte	115
 541    01E7  74        		.byte	116
 542    01E8  65        		.byte	101
 543    01E9  72        		.byte	114
 544    01EA  73        		.byte	115
 545    01EB  0A        		.byte	10
 546    01EC  00        		.byte	0
 547                    	L552:
 548    01ED  20        		.byte	32
 549    01EE  20        		.byte	32
 550    01EF  74        		.byte	116
 551    01F0  20        		.byte	32
 552    01F1  2D        		.byte	45
 553    01F2  20        		.byte	32
 554    01F3  74        		.byte	116
 555    01F4  65        		.byte	101
 556    01F5  73        		.byte	115
 557    01F6  74        		.byte	116
 558    01F7  20        		.byte	32
 559    01F8  70        		.byte	112
 560    01F9  72        		.byte	114
 561    01FA  6F        		.byte	111
 562    01FB  62        		.byte	98
 563    01FC  65        		.byte	101
 564    01FD  20        		.byte	32
 565    01FE  53        		.byte	83
 566    01FF  44        		.byte	68
 567    0200  20        		.byte	32
 568    0201  63        		.byte	99
 569    0202  61        		.byte	97
 570    0203  72        		.byte	114
 571    0204  64        		.byte	100
 572    0205  0A        		.byte	10
 573    0206  00        		.byte	0
 574                    	L562:
 575    0207  20        		.byte	32
 576    0208  20        		.byte	32
 577    0209  75        		.byte	117
 578    020A  20        		.byte	32
 579    020B  2D        		.byte	45
 580    020C  20        		.byte	32
 581    020D  75        		.byte	117
 582    020E  70        		.byte	112
 583    020F  6C        		.byte	108
 584    0210  6F        		.byte	111
 585    0211  61        		.byte	97
 586    0212  64        		.byte	100
 587    0213  20        		.byte	32
 588    0214  63        		.byte	99
 589    0215  6F        		.byte	111
 590    0216  64        		.byte	100
 591    0217  65        		.byte	101
 592    0218  20        		.byte	32
 593    0219  77        		.byte	119
 594    021A  69        		.byte	105
 595    021B  74        		.byte	116
 596    021C  68        		.byte	104
 597    021D  20        		.byte	32
 598    021E  58        		.byte	88
 599    021F  6D        		.byte	109
 600    0220  6F        		.byte	111
 601    0221  64        		.byte	100
 602    0222  65        		.byte	101
 603    0223  6D        		.byte	109
 604    0224  20        		.byte	32
 605    0225  74        		.byte	116
 606    0226  6F        		.byte	111
 607    0227  20        		.byte	32
 608    0228  30        		.byte	48
 609    0229  78        		.byte	120
 610    022A  25        		.byte	37
 611    022B  30        		.byte	48
 612    022C  34        		.byte	52
 613    022D  78        		.byte	120
 614    022E  0A        		.byte	10
 615    022F  20        		.byte	32
 616    0230  20        		.byte	32
 617    0231  20        		.byte	32
 618    0232  20        		.byte	32
 619    0233  20        		.byte	32
 620    0234  20        		.byte	32
 621    0235  61        		.byte	97
 622    0236  6E        		.byte	110
 623    0237  64        		.byte	100
 624    0238  20        		.byte	32
 625    0239  65        		.byte	101
 626    023A  78        		.byte	120
 627    023B  65        		.byte	101
 628    023C  63        		.byte	99
 629    023D  75        		.byte	117
 630    023E  74        		.byte	116
 631    023F  65        		.byte	101
 632    0240  20        		.byte	32
 633    0241  61        		.byte	97
 634    0242  74        		.byte	116
 635    0243  3A        		.byte	58
 636    0244  20        		.byte	32
 637    0245  30        		.byte	48
 638    0246  78        		.byte	120
 639    0247  25        		.byte	37
 640    0248  30        		.byte	48
 641    0249  34        		.byte	52
 642    024A  78        		.byte	120
 643    024B  0A        		.byte	10
 644    024C  00        		.byte	0
 645                    	L572:
 646    024D  20        		.byte	32
 647    024E  20        		.byte	32
 648    024F  77        		.byte	119
 649    0250  20        		.byte	32
 650    0251  2D        		.byte	45
 651    0252  20        		.byte	32
 652    0253  77        		.byte	119
 653    0254  72        		.byte	114
 654    0255  69        		.byte	105
 655    0256  74        		.byte	116
 656    0257  65        		.byte	101
 657    0258  20        		.byte	32
 658    0259  62        		.byte	98
 659    025A  6C        		.byte	108
 660    025B  6F        		.byte	111
 661    025C  63        		.byte	99
 662    025D  6B        		.byte	107
 663    025E  20        		.byte	32
 664    025F  23        		.byte	35
 665    0260  4E        		.byte	78
 666    0261  0A        		.byte	10
 667    0262  00        		.byte	0
 668                    	L503:
 669    0263  20        		.byte	32
 670    0264  20        		.byte	32
 671    0265  43        		.byte	67
 672    0266  74        		.byte	116
 673    0267  72        		.byte	114
 674    0268  6C        		.byte	108
 675    0269  2D        		.byte	45
 676    026A  43        		.byte	67
 677    026B  20        		.byte	32
 678    026C  74        		.byte	116
 679    026D  6F        		.byte	111
 680    026E  20        		.byte	32
 681    026F  72        		.byte	114
 682    0270  65        		.byte	101
 683    0271  6C        		.byte	108
 684    0272  6F        		.byte	111
 685    0273  61        		.byte	97
 686    0274  64        		.byte	100
 687    0275  20        		.byte	32
 688    0276  6D        		.byte	109
 689    0277  6F        		.byte	111
 690    0278  6E        		.byte	110
 691    0279  69        		.byte	105
 692    027A  74        		.byte	116
 693    027B  6F        		.byte	111
 694    027C  72        		.byte	114
 695    027D  20        		.byte	32
 696    027E  66        		.byte	102
 697    027F  72        		.byte	114
 698    0280  6F        		.byte	111
 699    0281  6D        		.byte	109
 700    0282  20        		.byte	32
 701    0283  45        		.byte	69
 702    0284  50        		.byte	80
 703    0285  52        		.byte	82
 704    0286  4F        		.byte	79
 705    0287  4D        		.byte	77
 706    0288  0A        		.byte	10
 707    0289  00        		.byte	0
 708                    	L513:
 709    028A  20        		.byte	32
 710    028B  61        		.byte	97
 711    028C  20        		.byte	32
 712    028D  2D        		.byte	45
 713    028E  20        		.byte	32
 714    028F  75        		.byte	117
 715    0290  70        		.byte	112
 716    0291  6C        		.byte	108
 717    0292  6F        		.byte	111
 718    0293  61        		.byte	97
 719    0294  64        		.byte	100
 720    0295  20        		.byte	32
 721    0296  61        		.byte	97
 722    0297  64        		.byte	100
 723    0298  64        		.byte	100
 724    0299  72        		.byte	114
 725    029A  65        		.byte	101
 726    029B  73        		.byte	115
 727    029C  73        		.byte	115
 728    029D  3A        		.byte	58
 729    029E  20        		.byte	32
 730    029F  20        		.byte	32
 731    02A0  30        		.byte	48
 732    02A1  78        		.byte	120
 733    02A2  00        		.byte	0
 734                    	L523:
 735    02A3  25        		.byte	37
 736    02A4  78        		.byte	120
 737    02A5  00        		.byte	0
 738                    	L533:
 739    02A6  25        		.byte	37
 740    02A7  30        		.byte	48
 741    02A8  34        		.byte	52
 742    02A9  78        		.byte	120
 743    02AA  00        		.byte	0
 744                    	L543:
 745    02AB  0A        		.byte	10
 746    02AC  00        		.byte	0
 747                    	L553:
 748    02AD  20        		.byte	32
 749    02AE  63        		.byte	99
 750    02AF  20        		.byte	32
 751    02B0  2D        		.byte	45
 752    02B1  20        		.byte	32
 753    02B2  62        		.byte	98
 754    02B3  6F        		.byte	111
 755    02B4  6F        		.byte	111
 756    02B5  74        		.byte	116
 757    02B6  20        		.byte	32
 758    02B7  43        		.byte	67
 759    02B8  50        		.byte	80
 760    02B9  2F        		.byte	47
 761    02BA  4D        		.byte	77
 762    02BB  20        		.byte	32
 763    02BC  66        		.byte	102
 764    02BD  72        		.byte	114
 765    02BE  6F        		.byte	111
 766    02BF  6D        		.byte	109
 767    02C0  20        		.byte	32
 768    02C1  45        		.byte	69
 769    02C2  50        		.byte	80
 770    02C3  52        		.byte	82
 771    02C4  4F        		.byte	79
 772    02C5  4D        		.byte	77
 773    02C6  0A        		.byte	10
 774    02C7  00        		.byte	0
 775                    	L563:
 776    02C8  20        		.byte	32
 777    02C9  20        		.byte	32
 778    02CA  62        		.byte	98
 779    02CB  75        		.byte	117
 780    02CC  74        		.byte	116
 781    02CD  20        		.byte	32
 782    02CE  66        		.byte	102
 783    02CF  69        		.byte	105
 784    02D0  72        		.byte	114
 785    02D1  73        		.byte	115
 786    02D2  74        		.byte	116
 787    02D3  20        		.byte	32
 788    02D4  69        		.byte	105
 789    02D5  6E        		.byte	110
 790    02D6  69        		.byte	105
 791    02D7  74        		.byte	116
 792    02D8  69        		.byte	105
 793    02D9  61        		.byte	97
 794    02DA  6C        		.byte	108
 795    02DB  69        		.byte	105
 796    02DC  7A        		.byte	122
 797    02DD  65        		.byte	101
 798    02DE  20        		.byte	32
 799    02DF  53        		.byte	83
 800    02E0  44        		.byte	68
 801    02E1  20        		.byte	32
 802    02E2  63        		.byte	99
 803    02E3  61        		.byte	97
 804    02E4  72        		.byte	114
 805    02E5  64        		.byte	100
 806    02E6  20        		.byte	32
 807    02E7  00        		.byte	0
 808                    	L573:
 809    02E8  20        		.byte	32
 810    02E9  2D        		.byte	45
 811    02EA  20        		.byte	32
 812    02EB  6F        		.byte	111
 813    02EC  6B        		.byte	107
 814    02ED  0A        		.byte	10
 815    02EE  00        		.byte	0
 816                    	L504:
 817    02EF  20        		.byte	32
 818    02F0  2D        		.byte	45
 819    02F1  20        		.byte	32
 820    02F2  6E        		.byte	110
 821    02F3  6F        		.byte	111
 822    02F4  74        		.byte	116
 823    02F5  20        		.byte	32
 824    02F6  69        		.byte	105
 825    02F7  6E        		.byte	110
 826    02F8  73        		.byte	115
 827    02F9  65        		.byte	101
 828    02FA  72        		.byte	114
 829    02FB  74        		.byte	116
 830    02FC  65        		.byte	101
 831    02FD  64        		.byte	100
 832    02FE  20        		.byte	32
 833    02FF  6F        		.byte	111
 834    0300  72        		.byte	114
 835    0301  20        		.byte	32
 836    0302  66        		.byte	102
 837    0303  61        		.byte	97
 838    0304  75        		.byte	117
 839    0305  6C        		.byte	108
 840    0306  74        		.byte	116
 841    0307  79        		.byte	121
 842    0308  0A        		.byte	10
 843    0309  00        		.byte	0
 844                    	L514:
 845    030A  20        		.byte	32
 846    030B  20        		.byte	32
 847    030C  61        		.byte	97
 848    030D  6E        		.byte	110
 849    030E  64        		.byte	100
 850    030F  20        		.byte	32
 851    0310  74        		.byte	116
 852    0311  68        		.byte	104
 853    0312  65        		.byte	101
 854    0313  6E        		.byte	110
 855    0314  20        		.byte	32
 856    0315  66        		.byte	102
 857    0316  69        		.byte	105
 858    0317  6E        		.byte	110
 859    0318  64        		.byte	100
 860    0319  20        		.byte	32
 861    031A  61        		.byte	97
 862    031B  6E        		.byte	110
 863    031C  64        		.byte	100
 864    031D  20        		.byte	32
 865    031E  70        		.byte	112
 866    031F  72        		.byte	114
 867    0320  69        		.byte	105
 868    0321  6E        		.byte	110
 869    0322  74        		.byte	116
 870    0323  20        		.byte	32
 871    0324  70        		.byte	112
 872    0325  61        		.byte	97
 873    0326  72        		.byte	114
 874    0327  74        		.byte	116
 875    0328  69        		.byte	105
 876    0329  74        		.byte	116
 877    032A  69        		.byte	105
 878    032B  6F        		.byte	111
 879    032C  6E        		.byte	110
 880    032D  20        		.byte	32
 881    032E  6C        		.byte	108
 882    032F  61        		.byte	97
 883    0330  79        		.byte	121
 884    0331  6F        		.byte	111
 885    0332  75        		.byte	117
 886    0333  74        		.byte	116
 887    0334  0A        		.byte	10
 888    0335  00        		.byte	0
 889                    	L524:
 890    0336  20        		.byte	32
 891    0337  2D        		.byte	45
 892    0338  20        		.byte	32
 893    0339  6E        		.byte	110
 894    033A  6F        		.byte	111
 895    033B  74        		.byte	116
 896    033C  20        		.byte	32
 897    033D  69        		.byte	105
 898    033E  6E        		.byte	110
 899    033F  69        		.byte	105
 900    0340  74        		.byte	116
 901    0341  69        		.byte	105
 902    0342  61        		.byte	97
 903    0343  6C        		.byte	108
 904    0344  69        		.byte	105
 905    0345  7A        		.byte	122
 906    0346  65        		.byte	101
 907    0347  64        		.byte	100
 908    0348  20        		.byte	32
 909    0349  6F        		.byte	111
 910    034A  72        		.byte	114
 911    034B  20        		.byte	32
 912    034C  69        		.byte	105
 913    034D  6E        		.byte	110
 914    034E  73        		.byte	115
 915    034F  65        		.byte	101
 916    0350  72        		.byte	114
 917    0351  74        		.byte	116
 918    0352  65        		.byte	101
 919    0353  64        		.byte	100
 920    0354  20        		.byte	32
 921    0355  6F        		.byte	111
 922    0356  72        		.byte	114
 923    0357  20        		.byte	32
 924    0358  66        		.byte	102
 925    0359  61        		.byte	97
 926    035A  75        		.byte	117
 927    035B  6C        		.byte	108
 928    035C  74        		.byte	116
 929    035D  79        		.byte	121
 930    035E  0A        		.byte	10
 931    035F  00        		.byte	0
 932                    	L534:
 933    0360  20        		.byte	32
 934    0361  64        		.byte	100
 935    0362  20        		.byte	32
 936    0363  2D        		.byte	45
 937    0364  20        		.byte	32
 938    0365  64        		.byte	100
 939    0366  75        		.byte	117
 940    0367  6D        		.byte	109
 941    0368  70        		.byte	112
 942    0369  20        		.byte	32
 943    036A  6D        		.byte	109
 944    036B  65        		.byte	101
 945    036C  6D        		.byte	109
 946    036D  6F        		.byte	111
 947    036E  72        		.byte	114
 948    036F  79        		.byte	121
 949    0370  20        		.byte	32
 950    0371  63        		.byte	99
 951    0372  6F        		.byte	111
 952    0373  6E        		.byte	110
 953    0374  74        		.byte	116
 954    0375  65        		.byte	101
 955    0376  6E        		.byte	110
 956    0377  74        		.byte	116
 957    0378  20        		.byte	32
 958    0379  73        		.byte	115
 959    037A  74        		.byte	116
 960    037B  61        		.byte	97
 961    037C  72        		.byte	114
 962    037D  74        		.byte	116
 963    037E  69        		.byte	105
 964    037F  6E        		.byte	110
 965    0380  67        		.byte	103
 966    0381  20        		.byte	32
 967    0382  61        		.byte	97
 968    0383  74        		.byte	116
 969    0384  3A        		.byte	58
 970    0385  20        		.byte	32
 971    0386  30        		.byte	48
 972    0387  78        		.byte	120
 973    0388  00        		.byte	0
 974                    	L544:
 975    0389  25        		.byte	37
 976    038A  78        		.byte	120
 977    038B  00        		.byte	0
 978                    	L554:
 979    038C  25        		.byte	37
 980    038D  30        		.byte	48
 981    038E  34        		.byte	52
 982    038F  78        		.byte	120
 983    0390  00        		.byte	0
 984                    	L564:
 985    0391  20        		.byte	32
 986    0392  72        		.byte	114
 987    0393  6F        		.byte	111
 988    0394  77        		.byte	119
 989    0395  73        		.byte	115
 990    0396  3A        		.byte	58
 991    0397  20        		.byte	32
 992    0398  00        		.byte	0
 993                    	L574:
 994    0399  25        		.byte	37
 995    039A  64        		.byte	100
 996    039B  00        		.byte	0
 997                    	L505:
 998    039C  25        		.byte	37
 999    039D  64        		.byte	100
1000    039E  00        		.byte	0
1001                    	L515:
1002    039F  0A        		.byte	10
1003    03A0  00        		.byte	0
1004                    	L525:
1005    03A1  20        		.byte	32
1006    03A2  65        		.byte	101
1007    03A3  20        		.byte	32
1008    03A4  2D        		.byte	45
1009    03A5  20        		.byte	32
1010    03A6  65        		.byte	101
1011    03A7  78        		.byte	120
1012    03A8  65        		.byte	101
1013    03A9  63        		.byte	99
1014    03AA  75        		.byte	117
1015    03AB  74        		.byte	116
1016    03AC  65        		.byte	101
1017    03AD  20        		.byte	32
1018    03AE  61        		.byte	97
1019    03AF  64        		.byte	100
1020    03B0  64        		.byte	100
1021    03B1  72        		.byte	114
1022    03B2  65        		.byte	101
1023    03B3  73        		.byte	115
1024    03B4  73        		.byte	115
1025    03B5  3A        		.byte	58
1026    03B6  20        		.byte	32
1027    03B7  30        		.byte	48
1028    03B8  78        		.byte	120
1029    03B9  00        		.byte	0
1030                    	L535:
1031    03BA  25        		.byte	37
1032    03BB  78        		.byte	120
1033    03BC  00        		.byte	0
1034                    	L545:
1035    03BD  25        		.byte	37
1036    03BE  30        		.byte	48
1037    03BF  34        		.byte	52
1038    03C0  78        		.byte	120
1039    03C1  00        		.byte	0
1040                    	L555:
1041    03C2  0A        		.byte	10
1042    03C3  00        		.byte	0
1043                    	L565:
1044    03C4  20        		.byte	32
1045    03C5  69        		.byte	105
1046    03C6  20        		.byte	32
1047    03C7  2D        		.byte	45
1048    03C8  20        		.byte	32
1049    03C9  69        		.byte	105
1050    03CA  6E        		.byte	110
1051    03CB  69        		.byte	105
1052    03CC  74        		.byte	116
1053    03CD  69        		.byte	105
1054    03CE  61        		.byte	97
1055    03CF  6C        		.byte	108
1056    03D0  69        		.byte	105
1057    03D1  7A        		.byte	122
1058    03D2  65        		.byte	101
1059    03D3  20        		.byte	32
1060    03D4  53        		.byte	83
1061    03D5  44        		.byte	68
1062    03D6  20        		.byte	32
1063    03D7  63        		.byte	99
1064    03D8  61        		.byte	97
1065    03D9  72        		.byte	114
1066    03DA  64        		.byte	100
1067    03DB  00        		.byte	0
1068                    	L575:
1069    03DC  20        		.byte	32
1070    03DD  2D        		.byte	45
1071    03DE  20        		.byte	32
1072    03DF  6F        		.byte	111
1073    03E0  6B        		.byte	107
1074    03E1  0A        		.byte	10
1075    03E2  00        		.byte	0
1076                    	L506:
1077    03E3  20        		.byte	32
1078    03E4  2D        		.byte	45
1079    03E5  20        		.byte	32
1080    03E6  6E        		.byte	110
1081    03E7  6F        		.byte	111
1082    03E8  74        		.byte	116
1083    03E9  20        		.byte	32
1084    03EA  69        		.byte	105
1085    03EB  6E        		.byte	110
1086    03EC  73        		.byte	115
1087    03ED  65        		.byte	101
1088    03EE  72        		.byte	114
1089    03EF  74        		.byte	116
1090    03F0  65        		.byte	101
1091    03F1  64        		.byte	100
1092    03F2  20        		.byte	32
1093    03F3  6F        		.byte	111
1094    03F4  72        		.byte	114
1095    03F5  20        		.byte	32
1096    03F6  66        		.byte	102
1097    03F7  61        		.byte	97
1098    03F8  75        		.byte	117
1099    03F9  6C        		.byte	108
1100    03FA  74        		.byte	116
1101    03FB  79        		.byte	121
1102    03FC  0A        		.byte	10
1103    03FD  00        		.byte	0
1104                    	L516:
1105    03FE  20        		.byte	32
1106    03FF  6C        		.byte	108
1107    0400  20        		.byte	32
1108    0401  2D        		.byte	45
1109    0402  20        		.byte	32
1110    0403  70        		.byte	112
1111    0404  72        		.byte	114
1112    0405  69        		.byte	105
1113    0406  6E        		.byte	110
1114    0407  74        		.byte	116
1115    0408  20        		.byte	32
1116    0409  70        		.byte	112
1117    040A  61        		.byte	97
1118    040B  72        		.byte	114
1119    040C  74        		.byte	116
1120    040D  69        		.byte	105
1121    040E  74        		.byte	116
1122    040F  69        		.byte	105
1123    0410  6F        		.byte	111
1124    0411  6E        		.byte	110
1125    0412  20        		.byte	32
1126    0413  6C        		.byte	108
1127    0414  61        		.byte	97
1128    0415  79        		.byte	121
1129    0416  6F        		.byte	111
1130    0417  75        		.byte	117
1131    0418  74        		.byte	116
1132    0419  0A        		.byte	10
1133    041A  00        		.byte	0
1134                    	L526:
1135    041B  20        		.byte	32
1136    041C  2D        		.byte	45
1137    041D  20        		.byte	32
1138    041E  6E        		.byte	110
1139    041F  6F        		.byte	111
1140    0420  74        		.byte	116
1141    0421  20        		.byte	32
1142    0422  69        		.byte	105
1143    0423  6E        		.byte	110
1144    0424  69        		.byte	105
1145    0425  74        		.byte	116
1146    0426  69        		.byte	105
1147    0427  61        		.byte	97
1148    0428  6C        		.byte	108
1149    0429  69        		.byte	105
1150    042A  7A        		.byte	122
1151    042B  65        		.byte	101
1152    042C  64        		.byte	100
1153    042D  20        		.byte	32
1154    042E  6F        		.byte	111
1155    042F  72        		.byte	114
1156    0430  20        		.byte	32
1157    0431  69        		.byte	105
1158    0432  6E        		.byte	110
1159    0433  73        		.byte	115
1160    0434  65        		.byte	101
1161    0435  72        		.byte	114
1162    0436  74        		.byte	116
1163    0437  65        		.byte	101
1164    0438  64        		.byte	100
1165    0439  20        		.byte	32
1166    043A  6F        		.byte	111
1167    043B  72        		.byte	114
1168    043C  20        		.byte	32
1169    043D  66        		.byte	102
1170    043E  61        		.byte	97
1171    043F  75        		.byte	117
1172    0440  6C        		.byte	108
1173    0441  74        		.byte	116
1174    0442  79        		.byte	121
1175    0443  0A        		.byte	10
1176    0444  00        		.byte	0
1177                    	L536:
1178    0445  20        		.byte	32
1179    0446  6E        		.byte	110
1180    0447  20        		.byte	32
1181    0448  2D        		.byte	45
1182    0449  20        		.byte	32
1183    044A  62        		.byte	98
1184    044B  6C        		.byte	108
1185    044C  6F        		.byte	111
1186    044D  63        		.byte	99
1187    044E  6B        		.byte	107
1188    044F  20        		.byte	32
1189    0450  6E        		.byte	110
1190    0451  75        		.byte	117
1191    0452  6D        		.byte	109
1192    0453  62        		.byte	98
1193    0454  65        		.byte	101
1194    0455  72        		.byte	114
1195    0456  3A        		.byte	58
1196    0457  20        		.byte	32
1197    0458  00        		.byte	0
1198                    	L546:
1199    0459  25        		.byte	37
1200    045A  6C        		.byte	108
1201    045B  75        		.byte	117
1202    045C  00        		.byte	0
1203                    	L556:
1204    045D  25        		.byte	37
1205    045E  6C        		.byte	108
1206    045F  75        		.byte	117
1207    0460  00        		.byte	0
1208                    	L566:
1209    0461  0A        		.byte	10
1210    0462  00        		.byte	0
1211                    	L576:
1212    0463  20        		.byte	32
1213    0464  70        		.byte	112
1214    0465  20        		.byte	32
1215    0466  2D        		.byte	45
1216    0467  20        		.byte	32
1217    0468  70        		.byte	112
1218    0469  72        		.byte	114
1219    046A  69        		.byte	105
1220    046B  6E        		.byte	110
1221    046C  74        		.byte	116
1222    046D  20        		.byte	32
1223    046E  64        		.byte	100
1224    046F  61        		.byte	97
1225    0470  74        		.byte	116
1226    0471  61        		.byte	97
1227    0472  20        		.byte	32
1228    0473  62        		.byte	98
1229    0474  6C        		.byte	108
1230    0475  6F        		.byte	111
1231    0476  63        		.byte	99
1232    0477  6B        		.byte	107
1233    0478  20        		.byte	32
1234    0479  25        		.byte	37
1235    047A  6C        		.byte	108
1236    047B  75        		.byte	117
1237    047C  0A        		.byte	10
1238    047D  00        		.byte	0
1239                    	L507:
1240    047E  20        		.byte	32
1241    047F  72        		.byte	114
1242    0480  20        		.byte	32
1243    0481  2D        		.byte	45
1244    0482  20        		.byte	32
1245    0483  72        		.byte	114
1246    0484  65        		.byte	101
1247    0485  61        		.byte	97
1248    0486  64        		.byte	100
1249    0487  20        		.byte	32
1250    0488  62        		.byte	98
1251    0489  6C        		.byte	108
1252    048A  6F        		.byte	111
1253    048B  63        		.byte	99
1254    048C  6B        		.byte	107
1255    048D  00        		.byte	0
1256                    	L517:
1257    048E  20        		.byte	32
1258    048F  2D        		.byte	45
1259    0490  20        		.byte	32
1260    0491  6E        		.byte	110
1261    0492  6F        		.byte	111
1262    0493  74        		.byte	116
1263    0494  20        		.byte	32
1264    0495  69        		.byte	105
1265    0496  6E        		.byte	110
1266    0497  69        		.byte	105
1267    0498  74        		.byte	116
1268    0499  69        		.byte	105
1269    049A  61        		.byte	97
1270    049B  6C        		.byte	108
1271    049C  69        		.byte	105
1272    049D  7A        		.byte	122
1273    049E  65        		.byte	101
1274    049F  64        		.byte	100
1275    04A0  20        		.byte	32
1276    04A1  6F        		.byte	111
1277    04A2  72        		.byte	114
1278    04A3  20        		.byte	32
1279    04A4  69        		.byte	105
1280    04A5  6E        		.byte	110
1281    04A6  73        		.byte	115
1282    04A7  65        		.byte	101
1283    04A8  72        		.byte	114
1284    04A9  74        		.byte	116
1285    04AA  65        		.byte	101
1286    04AB  64        		.byte	100
1287    04AC  20        		.byte	32
1288    04AD  6F        		.byte	111
1289    04AE  72        		.byte	114
1290    04AF  20        		.byte	32
1291    04B0  66        		.byte	102
1292    04B1  61        		.byte	97
1293    04B2  75        		.byte	117
1294    04B3  6C        		.byte	108
1295    04B4  74        		.byte	116
1296    04B5  79        		.byte	121
1297    04B6  0A        		.byte	10
1298    04B7  00        		.byte	0
1299                    	L527:
1300    04B8  20        		.byte	32
1301    04B9  2D        		.byte	45
1302    04BA  20        		.byte	32
1303    04BB  6F        		.byte	111
1304    04BC  6B        		.byte	107
1305    04BD  0A        		.byte	10
1306    04BE  00        		.byte	0
1307                    	L537:
1308    04BF  20        		.byte	32
1309    04C0  2D        		.byte	45
1310    04C1  20        		.byte	32
1311    04C2  72        		.byte	114
1312    04C3  65        		.byte	101
1313    04C4  61        		.byte	97
1314    04C5  64        		.byte	100
1315    04C6  20        		.byte	32
1316    04C7  65        		.byte	101
1317    04C8  72        		.byte	114
1318    04C9  72        		.byte	114
1319    04CA  6F        		.byte	111
1320    04CB  72        		.byte	114
1321    04CC  0A        		.byte	10
1322    04CD  00        		.byte	0
1323                    	L547:
1324    04CE  20        		.byte	32
1325    04CF  73        		.byte	115
1326    04D0  20        		.byte	32
1327    04D1  2D        		.byte	45
1328    04D2  20        		.byte	32
1329    04D3  70        		.byte	112
1330    04D4  72        		.byte	114
1331    04D5  69        		.byte	105
1332    04D6  6E        		.byte	110
1333    04D7  74        		.byte	116
1334    04D8  20        		.byte	32
1335    04D9  53        		.byte	83
1336    04DA  44        		.byte	68
1337    04DB  20        		.byte	32
1338    04DC  72        		.byte	114
1339    04DD  65        		.byte	101
1340    04DE  67        		.byte	103
1341    04DF  69        		.byte	105
1342    04E0  73        		.byte	115
1343    04E1  74        		.byte	116
1344    04E2  65        		.byte	101
1345    04E3  72        		.byte	114
1346    04E4  73        		.byte	115
1347    04E5  0A        		.byte	10
1348    04E6  00        		.byte	0
1349                    	L557:
1350    04E7  20        		.byte	32
1351    04E8  74        		.byte	116
1352    04E9  20        		.byte	32
1353    04EA  2D        		.byte	45
1354    04EB  20        		.byte	32
1355    04EC  74        		.byte	116
1356    04ED  65        		.byte	101
1357    04EE  73        		.byte	115
1358    04EF  74        		.byte	116
1359    04F0  20        		.byte	32
1360    04F1  69        		.byte	105
1361    04F2  66        		.byte	102
1362    04F3  20        		.byte	32
1363    04F4  63        		.byte	99
1364    04F5  61        		.byte	97
1365    04F6  72        		.byte	114
1366    04F7  64        		.byte	100
1367    04F8  20        		.byte	32
1368    04F9  69        		.byte	105
1369    04FA  6E        		.byte	110
1370    04FB  73        		.byte	115
1371    04FC  65        		.byte	101
1372    04FD  72        		.byte	114
1373    04FE  74        		.byte	116
1374    04FF  65        		.byte	101
1375    0500  64        		.byte	100
1376    0501  0A        		.byte	10
1377    0502  00        		.byte	0
1378                    	L567:
1379    0503  20        		.byte	32
1380    0504  2D        		.byte	45
1381    0505  20        		.byte	32
1382    0506  6F        		.byte	111
1383    0507  6B        		.byte	107
1384    0508  0A        		.byte	10
1385    0509  00        		.byte	0
1386                    	L577:
1387    050A  20        		.byte	32
1388    050B  2D        		.byte	45
1389    050C  20        		.byte	32
1390    050D  6E        		.byte	110
1391    050E  6F        		.byte	111
1392    050F  74        		.byte	116
1393    0510  20        		.byte	32
1394    0511  69        		.byte	105
1395    0512  6E        		.byte	110
1396    0513  69        		.byte	105
1397    0514  74        		.byte	116
1398    0515  69        		.byte	105
1399    0516  61        		.byte	97
1400    0517  6C        		.byte	108
1401    0518  69        		.byte	105
1402    0519  7A        		.byte	122
1403    051A  65        		.byte	101
1404    051B  64        		.byte	100
1405    051C  20        		.byte	32
1406    051D  6F        		.byte	111
1407    051E  72        		.byte	114
1408    051F  20        		.byte	32
1409    0520  69        		.byte	105
1410    0521  6E        		.byte	110
1411    0522  73        		.byte	115
1412    0523  65        		.byte	101
1413    0524  72        		.byte	114
1414    0525  74        		.byte	116
1415    0526  65        		.byte	101
1416    0527  64        		.byte	100
1417    0528  20        		.byte	32
1418    0529  6F        		.byte	111
1419    052A  72        		.byte	114
1420    052B  20        		.byte	32
1421    052C  66        		.byte	102
1422    052D  61        		.byte	97
1423    052E  75        		.byte	117
1424    052F  6C        		.byte	108
1425    0530  74        		.byte	116
1426    0531  79        		.byte	121
1427    0532  0A        		.byte	10
1428    0533  00        		.byte	0
1429                    	L5001:
1430    0534  20        		.byte	32
1431    0535  25        		.byte	37
1432    0536  63        		.byte	99
1433    0537  20        		.byte	32
1434    0538  2D        		.byte	45
1435    0539  20        		.byte	32
1436    053A  75        		.byte	117
1437    053B  70        		.byte	112
1438    053C  6C        		.byte	108
1439    053D  6F        		.byte	111
1440    053E  61        		.byte	97
1441    053F  64        		.byte	100
1442    0540  20        		.byte	32
1443    0541  74        		.byte	116
1444    0542  6F        		.byte	111
1445    0543  20        		.byte	32
1446    0544  30        		.byte	48
1447    0545  78        		.byte	120
1448    0546  25        		.byte	37
1449    0547  30        		.byte	48
1450    0548  34        		.byte	52
1451    0549  78        		.byte	120
1452    054A  20        		.byte	32
1453    054B  61        		.byte	97
1454    054C  6E        		.byte	110
1455    054D  64        		.byte	100
1456    054E  20        		.byte	32
1457    054F  65        		.byte	101
1458    0550  78        		.byte	120
1459    0551  65        		.byte	101
1460    0552  63        		.byte	99
1461    0553  75        		.byte	117
1462    0554  74        		.byte	116
1463    0555  65        		.byte	101
1464    0556  20        		.byte	32
1465    0557  61        		.byte	97
1466    0558  74        		.byte	116
1467    0559  3A        		.byte	58
1468    055A  20        		.byte	32
1469    055B  30        		.byte	48
1470    055C  78        		.byte	120
1471    055D  25        		.byte	37
1472    055E  30        		.byte	48
1473    055F  34        		.byte	52
1474    0560  78        		.byte	120
1475    0561  0A        		.byte	10
1476    0562  00        		.byte	0
1477                    	L5101:
1478    0563  28        		.byte	40
1479    0564  55        		.byte	85
1480    0565  70        		.byte	112
1481    0566  6C        		.byte	108
1482    0567  6F        		.byte	111
1483    0568  61        		.byte	97
1484    0569  64        		.byte	100
1485    056A  65        		.byte	101
1486    056B  72        		.byte	114
1487    056C  20        		.byte	32
1488    056D  63        		.byte	99
1489    056E  6F        		.byte	111
1490    056F  64        		.byte	100
1491    0570  65        		.byte	101
1492    0571  20        		.byte	32
1493    0572  61        		.byte	97
1494    0573  74        		.byte	116
1495    0574  3A        		.byte	58
1496    0575  20        		.byte	32
1497    0576  30        		.byte	48
1498    0577  78        		.byte	120
1499    0578  25        		.byte	37
1500    0579  30        		.byte	48
1501    057A  34        		.byte	52
1502    057B  78        		.byte	120
1503    057C  2C        		.byte	44
1504    057D  20        		.byte	32
1505    057E  73        		.byte	115
1506    057F  69        		.byte	105
1507    0580  7A        		.byte	122
1508    0581  65        		.byte	101
1509    0582  3A        		.byte	58
1510    0583  20        		.byte	32
1511    0584  25        		.byte	37
1512    0585  64        		.byte	100
1513    0586  29        		.byte	41
1514    0587  0A        		.byte	10
1515    0588  00        		.byte	0
1516                    	L5201:
1517    0589  20        		.byte	32
1518    058A  77        		.byte	119
1519    058B  20        		.byte	32
1520    058C  2D        		.byte	45
1521    058D  20        		.byte	32
1522    058E  77        		.byte	119
1523    058F  72        		.byte	114
1524    0590  69        		.byte	105
1525    0591  74        		.byte	116
1526    0592  65        		.byte	101
1527    0593  20        		.byte	32
1528    0594  62        		.byte	98
1529    0595  6C        		.byte	108
1530    0596  6F        		.byte	111
1531    0597  63        		.byte	99
1532    0598  6B        		.byte	107
1533    0599  00        		.byte	0
1534                    	L5301:
1535    059A  20        		.byte	32
1536    059B  2D        		.byte	45
1537    059C  20        		.byte	32
1538    059D  6E        		.byte	110
1539    059E  6F        		.byte	111
1540    059F  74        		.byte	116
1541    05A0  20        		.byte	32
1542    05A1  69        		.byte	105
1543    05A2  6E        		.byte	110
1544    05A3  69        		.byte	105
1545    05A4  74        		.byte	116
1546    05A5  69        		.byte	105
1547    05A6  61        		.byte	97
1548    05A7  6C        		.byte	108
1549    05A8  69        		.byte	105
1550    05A9  7A        		.byte	122
1551    05AA  65        		.byte	101
1552    05AB  64        		.byte	100
1553    05AC  20        		.byte	32
1554    05AD  6F        		.byte	111
1555    05AE  72        		.byte	114
1556    05AF  20        		.byte	32
1557    05B0  69        		.byte	105
1558    05B1  6E        		.byte	110
1559    05B2  73        		.byte	115
1560    05B3  65        		.byte	101
1561    05B4  72        		.byte	114
1562    05B5  74        		.byte	116
1563    05B6  65        		.byte	101
1564    05B7  64        		.byte	100
1565    05B8  20        		.byte	32
1566    05B9  6F        		.byte	111
1567    05BA  72        		.byte	114
1568    05BB  20        		.byte	32
1569    05BC  66        		.byte	102
1570    05BD  61        		.byte	97
1571    05BE  75        		.byte	117
1572    05BF  6C        		.byte	108
1573    05C0  74        		.byte	116
1574    05C1  79        		.byte	121
1575    05C2  0A        		.byte	10
1576    05C3  00        		.byte	0
1577                    	L5401:
1578    05C4  20        		.byte	32
1579    05C5  2D        		.byte	45
1580    05C6  20        		.byte	32
1581    05C7  6F        		.byte	111
1582    05C8  6B        		.byte	107
1583    05C9  0A        		.byte	10
1584    05CA  00        		.byte	0
1585                    	L5501:
1586    05CB  20        		.byte	32
1587    05CC  2D        		.byte	45
1588    05CD  20        		.byte	32
1589    05CE  77        		.byte	119
1590    05CF  72        		.byte	114
1591    05D0  69        		.byte	105
1592    05D1  74        		.byte	116
1593    05D2  65        		.byte	101
1594    05D3  20        		.byte	32
1595    05D4  65        		.byte	101
1596    05D5  72        		.byte	114
1597    05D6  72        		.byte	114
1598    05D7  6F        		.byte	111
1599    05D8  72        		.byte	114
1600    05D9  0A        		.byte	10
1601    05DA  00        		.byte	0
1602                    	L5601:
1603    05DB  72        		.byte	114
1604    05DC  65        		.byte	101
1605    05DD  6C        		.byte	108
1606    05DE  6F        		.byte	111
1607    05DF  61        		.byte	97
1608    05E0  64        		.byte	100
1609    05E1  69        		.byte	105
1610    05E2  6E        		.byte	110
1611    05E3  67        		.byte	103
1612    05E4  20        		.byte	32
1613    05E5  6D        		.byte	109
1614    05E6  6F        		.byte	111
1615    05E7  6E        		.byte	110
1616    05E8  69        		.byte	105
1617    05E9  74        		.byte	116
1618    05EA  6F        		.byte	111
1619    05EB  72        		.byte	114
1620    05EC  20        		.byte	32
1621    05ED  66        		.byte	102
1622    05EE  72        		.byte	114
1623    05EF  6F        		.byte	111
1624    05F0  6D        		.byte	109
1625    05F1  20        		.byte	32
1626    05F2  45        		.byte	69
1627    05F3  50        		.byte	80
1628    05F4  52        		.byte	82
1629    05F5  4F        		.byte	79
1630    05F6  4D        		.byte	77
1631    05F7  0A        		.byte	10
1632    05F8  00        		.byte	0
1633                    	L5701:
1634    05F9  20        		.byte	32
1635    05FA  69        		.byte	105
1636    05FB  6E        		.byte	110
1637    05FC  76        		.byte	118
1638    05FD  61        		.byte	97
1639    05FE  6C        		.byte	108
1640    05FF  69        		.byte	105
1641    0600  64        		.byte	100
1642    0601  20        		.byte	32
1643    0602  63        		.byte	99
1644    0603  6F        		.byte	111
1645    0604  6D        		.byte	109
1646    0605  6D        		.byte	109
1647    0606  61        		.byte	97
1648    0607  6E        		.byte	110
1649    0608  64        		.byte	100
1650    0609  0A        		.byte	10
1651    060A  00        		.byte	0
1652                    	L14:
1653    060B  0C        		.byte	12
1654    060C  00        		.byte	0
1655    060D  6C        		.byte	108
1656    060E  00        		.byte	0
1657    060F  4109      		.word	L113
1658    0611  1D0B      		.word	L155
1659    0613  6009      		.word	L133
1660    0615  1D0B      		.word	L155
1661    0617  D409      		.word	L163
1662    0619  1D0B      		.word	L155
1663    061B  010A      		.word	L173
1664    061D  500A      		.word	L134
1665    061F  5C0A      		.word	L144
1666    0621  7B0A      		.word	L174
1667    0623  1D0B      		.word	L155
1668    0625  C20A      		.word	L105
1669    0627  09        		.byte	9
1670    0628  00        		.byte	0
1671    0629  61        		.byte	97
1672    062A  00        		.byte	0
1673    062B  6F07      		.word	L17
1674    062D  1D0B      		.word	L155
1675    062F  D107      		.word	L121
1676    0631  2808      		.word	L161
1677    0633  CC08      		.word	L132
1678    0635  1D0B      		.word	L155
1679    0637  1D0B      		.word	L155
1680    0639  1D0B      		.word	L155
1681    063B  2209      		.word	L162
1682    063D  00        		.byte	0
1683    063E  00        		.byte	0
1684    063F  02        		.byte	2
1685    0640  00        		.byte	0
1686    0641  110B      		.word	L145
1687    0643  0300      		.word	3
1688    0645  E106      		.word	L16
1689    0647  3F00      		.word	63
1690    0649  1D0B      		.word	L155
1691                    	;   55  
1692                    	;   56  /* Test init, read and partitions on SD card over the SPI interface,
1693                    	;   57   * boot from SD card, upload with Xmodem
1694                    	;   58   */
1695                    	;   59  int main()
1696                    	;   60      {
1697                    	_main:
1698    064B  CD0000    		call	c.savs0
1699    064E  21D0FF    		ld	hl,65488
1700    0651  39        		add	hl,sp
1701    0652  F9        		ld	sp,hl
1702                    	;   61      char txtin[16];
1703                    	;   62      int cmdin;
1704                    	;   63      int idx;
1705                    	;   64      int cmpidx;
1706                    	;   65      unsigned char *cmpptr;
1707                    	;   66      int inlength;
1708                    	;   67      unsigned char blockno[4];
1709                    	;   68      unsigned long inblockno;
1710                    	;   69      unsigned int upladr;
1711                    	;   70      unsigned int exeadr;
1712                    	;   71      unsigned int dumpadr;
1713                    	;   72      int dumprows;
1714                    	;   73  
1715                    	;   74      memset(blockno, 0, 4);
1716    0653  210400    		ld	hl,4
1717    0656  E5        		push	hl
1718    0657  210000    		ld	hl,0
1719    065A  E5        		push	hl
1720    065B  DDE5      		push	ix
1721    065D  C1        		pop	bc
1722    065E  21DCFF    		ld	hl,65500
1723    0661  09        		add	hl,bc
1724    0662  CD0000    		call	_memset
1725    0665  F1        		pop	af
1726    0666  F1        		pop	af
1727                    	;   75      memset(curblkno, 0, 4);;
1728    0667  210400    		ld	hl,4
1729    066A  E5        		push	hl
1730    066B  210000    		ld	hl,0
1731    066E  E5        		push	hl
1732    066F  210000    		ld	hl,_curblkno
1733    0672  CD0000    		call	_memset
1734    0675  F1        		pop	af
1735    0676  F1        		pop	af
1736                    	;   76      curblkok = NO;
1737    0677  210000    		ld	hl,0
1738    067A  220000    		ld	(_curblkok),hl
1739                    	;   77      sdinitok = (void *) INITFLG;
1740    067D  21FEFE    		ld	hl,65278
1741                    	;   78      *sdinitok = 0; /* SD card not initialized yet */
1742    0680  220000    		ld	(_sdinitok),hl
1743    0683  3600      		ld	(hl),0
1744                    	;   79      byteblkadr = (void *) SEBYFLG;
1745    0685  21FFFE    		ld	hl,65279
1746    0688  220000    		ld	(_byteblkadr),hl
1747                    	;   80      upladrptr = (void *) UPLDADR;
1748    068B  21F0FE    		ld	hl,65264
1749                    	;   81      *upladrptr = 0x0000;
1750    068E  220400    		ld	(_upladrptr),hl
1751    0691  3600      		ld	(hl),0
1752    0693  23        		inc	hl
1753    0694  3600      		ld	(hl),0
1754                    	;   82      exeadrptr = (void *) EXEDADR;
1755    0696  21F2FE    		ld	hl,65266
1756                    	;   83      *exeadrptr = 0x0000;
1757    0699  220200    		ld	(_exeadrptr),hl
1758    069C  3600      		ld	(hl),0
1759    069E  23        		inc	hl
1760    069F  3600      		ld	(hl),0
1761                    	;   84      dumpadr = 0x0000;
1762    06A1  DD36D200  		ld	(ix-46),0
1763    06A5  DD36D300  		ld	(ix-45),0
1764                    	;   85      dumprows = 16;
1765    06A9  DD36D010  		ld	(ix-48),16
1766    06AD  DD36D100  		ld	(ix-47),0
1767                    	;   86  
1768                    	;   87      printf(PRGNAME);
1769    06B1  214E00    		ld	hl,L53
1770    06B4  CD0000    		call	_printf
1771                    	;   88      printf(VERSION);
1772    06B7  215800    		ld	hl,L54
1773    06BA  CD0000    		call	_printf
1774                    	;   89      printf(builddate);
1775    06BD  210000    		ld	hl,_builddate
1776    06C0  CD0000    		call	_printf
1777                    	;   90      execin();
1778    06C3  CD1F00    		call	_execin
1779                    	L12:
1780                    	;   91      /*printf("binstart: 0x%04x, binsize: 0x%04x (%d)\n", binstart, binsize, binsize);*/
1781                    	;   92      while (YES) /* forever (until Ctrl-C) */
1782                    	;   93          {
1783                    	;   94          printf("cmd (? for help): ");
1784    06C6  216600    		ld	hl,L55
1785    06C9  CD0000    		call	_printf
1786                    	;   95  
1787                    	;   96          cmdin = getchar();
1788    06CC  CD0000    		call	_getchar
1789    06CF  DD71E8    		ld	(ix-24),c
1790    06D2  DD70E9    		ld	(ix-23),b
1791                    	;   97          switch (cmdin)
1792    06D5  DD4EE8    		ld	c,(ix-24)
1793    06D8  DD46E9    		ld	b,(ix-23)
1794    06DB  210B06    		ld	hl,L14
1795    06DE  C30000    		jp	c.jtab
1796                    	L16:
1797                    	;   98              {
1798                    	;   99              case '?':
1799                    	;  100                  printf(" ? - help\n");
1800    06E1  217900    		ld	hl,L56
1801    06E4  CD0000    		call	_printf
1802                    	;  101                  printf(PRGNAME);
1803    06E7  218400    		ld	hl,L57
1804    06EA  CD0000    		call	_printf
1805                    	;  102                  printf(VERSION);
1806    06ED  218E00    		ld	hl,L501
1807    06F0  CD0000    		call	_printf
1808                    	;  103                  printf(builddate);
1809    06F3  210000    		ld	hl,_builddate
1810    06F6  CD0000    		call	_printf
1811                    	;  104                  execin();
1812    06F9  CD1F00    		call	_execin
1813                    	;  105                  printf("Commands:\n");
1814    06FC  219C00    		ld	hl,L511
1815    06FF  CD0000    		call	_printf
1816                    	;  106                  printf("  ? - help\n");
1817    0702  21A700    		ld	hl,L521
1818    0705  CD0000    		call	_printf
1819                    	;  107                  printf("  a - set address for upload\n");
1820    0708  21B300    		ld	hl,L531
1821    070B  CD0000    		call	_printf
1822                    	;  108                  printf("  c - boot CP/M from EPROM\n");
1823    070E  21D100    		ld	hl,L541
1824    0711  CD0000    		call	_printf
1825                    	;  109                  printf("  d - dump memory content to screen\n");
1826    0714  21ED00    		ld	hl,L551
1827    0717  CD0000    		call	_printf
1828                    	;  110                  printf("  e - set address for execute\n");
1829    071A  211201    		ld	hl,L561
1830    071D  CD0000    		call	_printf
1831                    	;  111                  printf("  i - initialize SD card\n");
1832    0720  213101    		ld	hl,L571
1833    0723  CD0000    		call	_printf
1834                    	;  112                  printf("  l - print SD card partition layout\n");
1835    0726  214B01    		ld	hl,L502
1836    0729  CD0000    		call	_printf
1837                    	;  113                  printf("  n - set/show block #N to read/write\n");
1838    072C  217101    		ld	hl,L512
1839    072F  CD0000    		call	_printf
1840                    	;  114                  printf("  p - print block last read/to write\n");
1841    0732  219801    		ld	hl,L522
1842    0735  CD0000    		call	_printf
1843                    	;  115                  printf("  r - read block #N\n");
1844    0738  21BE01    		ld	hl,L532
1845    073B  CD0000    		call	_printf
1846                    	;  116                  printf("  s - print SD registers\n");
1847    073E  21D301    		ld	hl,L542
1848    0741  CD0000    		call	_printf
1849                    	;  117                  printf("  t - test probe SD card\n");
1850    0744  21ED01    		ld	hl,L552
1851    0747  CD0000    		call	_printf
1852                    	;  118                  printf("  u - upload code with Xmodem to 0x%04x\n      and execute at: 0x%04x\n",
1853                    	;  119                         *upladrptr, *exeadrptr);
1854    074A  2A0200    		ld	hl,(_exeadrptr)
1855    074D  4E        		ld	c,(hl)
1856    074E  23        		inc	hl
1857    074F  46        		ld	b,(hl)
1858    0750  C5        		push	bc
1859    0751  2A0400    		ld	hl,(_upladrptr)
1860    0754  4E        		ld	c,(hl)
1861    0755  23        		inc	hl
1862    0756  46        		ld	b,(hl)
1863    0757  C5        		push	bc
1864    0758  210702    		ld	hl,L562
1865    075B  CD0000    		call	_printf
1866    075E  F1        		pop	af
1867    075F  F1        		pop	af
1868                    	;  120                  printf("  w - write block #N\n");
1869    0760  214D02    		ld	hl,L572
1870    0763  CD0000    		call	_printf
1871                    	;  121                  printf("  Ctrl-C to reload monitor from EPROM\n");
1872    0766  216302    		ld	hl,L503
1873    0769  CD0000    		call	_printf
1874                    	;  122                  break;
1875    076C  C3C606    		jp	L12
1876                    	L17:
1877                    	;  123              case 'a':
1878                    	;  124                  printf(" a - upload address:  0x");
1879    076F  218A02    		ld	hl,L513
1880    0772  CD0000    		call	_printf
1881                    	;  125                  if (getkline(txtin, sizeof txtin))
1882    0775  211000    		ld	hl,16
1883    0778  E5        		push	hl
1884    0779  DDE5      		push	ix
1885    077B  C1        		pop	bc
1886    077C  21EAFF    		ld	hl,65514
1887    077F  09        		add	hl,bc
1888    0780  CD0000    		call	_getkline
1889    0783  F1        		pop	af
1890    0784  79        		ld	a,c
1891    0785  B0        		or	b
1892    0786  2832      		jr	z,L101
1893                    	;  126                      {
1894                    	;  127                      sscanf(txtin, "%x", &upladr);
1895    0788  DDE5      		push	ix
1896    078A  C1        		pop	bc
1897    078B  21D6FF    		ld	hl,65494
1898    078E  09        		add	hl,bc
1899    078F  E5        		push	hl
1900    0790  21A302    		ld	hl,L523
1901    0793  E5        		push	hl
1902    0794  DDE5      		push	ix
1903    0796  C1        		pop	bc
1904    0797  21EAFF    		ld	hl,65514
1905    079A  09        		add	hl,bc
1906    079B  CD0000    		call	_sscanf
1907    079E  F1        		pop	af
1908    079F  F1        		pop	af
1909                    	;  128                      *upladrptr = upladr;
1910    07A0  2A0400    		ld	hl,(_upladrptr)
1911    07A3  DD7ED6    		ld	a,(ix-42)
1912    07A6  77        		ld	(hl),a
1913    07A7  DD7ED7    		ld	a,(ix-41)
1914    07AA  23        		inc	hl
1915    07AB  77        		ld	(hl),a
1916                    	;  129                      *exeadrptr = upladr;
1917    07AC  2A0200    		ld	hl,(_exeadrptr)
1918    07AF  DD7ED6    		ld	a,(ix-42)
1919    07B2  77        		ld	(hl),a
1920    07B3  DD7ED7    		ld	a,(ix-41)
1921    07B6  23        		inc	hl
1922    07B7  77        		ld	(hl),a
1923                    	;  130                      }
1924                    	;  131                  else
1925    07B8  180E      		jr	L111
1926                    	L101:
1927                    	;  132                      {
1928                    	;  133                      printf("%04x", *upladrptr);
1929    07BA  2A0400    		ld	hl,(_upladrptr)
1930    07BD  4E        		ld	c,(hl)
1931    07BE  23        		inc	hl
1932    07BF  46        		ld	b,(hl)
1933    07C0  C5        		push	bc
1934    07C1  21A602    		ld	hl,L533
1935    07C4  CD0000    		call	_printf
1936    07C7  F1        		pop	af
1937                    	L111:
1938                    	;  134                      }
1939                    	;  135                  printf("\n");
1940    07C8  21AB02    		ld	hl,L543
1941    07CB  CD0000    		call	_printf
1942                    	;  136                  break;
1943    07CE  C3C606    		jp	L12
1944                    	L121:
1945                    	;  137              case 'c':
1946                    	;  138                  printf(" c - boot CP/M from EPROM\n");
1947    07D1  21AD02    		ld	hl,L553
1948    07D4  CD0000    		call	_printf
1949                    	;  139                  printf("  but first initialize SD card ");
1950    07D7  21C802    		ld	hl,L563
1951    07DA  CD0000    		call	_printf
1952                    	;  140                  if (sdinit())
1953    07DD  CD0000    		call	_sdinit
1954    07E0  79        		ld	a,c
1955    07E1  B0        		or	b
1956    07E2  281C      		jr	z,L131
1957                    	;  141                      printf(" - ok\n");
1958    07E4  21E802    		ld	hl,L573
1959    07E7  CD0000    		call	_printf
1960                    	;  142                  else
1961                    	;  143                      {
1962                    	;  144                      printf(" - not inserted or faulty\n");
1963                    	;  145                      break;
1964                    	;  146                      }
1965                    	;  147                  printf("  and then find and print partition layout\n");
1966    07EA  210A03    		ld	hl,L514
1967    07ED  CD0000    		call	_printf
1968                    	;  148                  if (!sdprobe())
1969    07F0  CD0000    		call	_sdprobe
1970    07F3  79        		ld	a,c
1971    07F4  B0        		or	b
1972    07F5  2012      		jr	nz,L151
1973                    	;  149                      {
1974                    	;  150                      printf(" - not initialized or inserted or faulty\n");
1975    07F7  213603    		ld	hl,L524
1976    07FA  CD0000    		call	_printf
1977                    	;  151                      break;
1978    07FD  C3C606    		jp	L12
1979                    	L131:
1980    0800  21EF02    		ld	hl,L504
1981    0803  CD0000    		call	_printf
1982    0806  C3C606    		jp	L12
1983                    	L151:
1984                    	;  152                      }
1985                    	;  153                  sdpartfind();
1986    0809  CD0000    		call	_sdpartfind
1987                    	;  154                  sdpartprint();
1988    080C  CD0000    		call	_sdpartprint
1989                    	;  155                  memcpy(CCPADR, cpmsys, cpmsys_size);
1990    080F  2A0000    		ld	hl,(_cpmsys_size)
1991    0812  E5        		push	hl
1992    0813  210000    		ld	hl,_cpmsys
1993    0816  E5        		push	hl
1994    0817  2100D8    		ld	hl,55296
1995    081A  CD0000    		call	_memcpy
1996    081D  F1        		pop	af
1997    081E  F1        		pop	af
1998                    	;  156                  jumptoram(BIOSADR);
1999    081F  2100EE    		ld	hl,60928
2000    0822  CD0000    		call	_jumptoram
2001                    	;  157                  break;
2002    0825  C3C606    		jp	L12
2003                    	L161:
2004                    	;  158              case 'd':
2005                    	;  159                  printf(" d - dump memory content starting at: 0x");
2006    0828  216003    		ld	hl,L534
2007    082B  CD0000    		call	_printf
2008                    	;  160                  if (getkline(txtin, sizeof txtin))
2009    082E  211000    		ld	hl,16
2010    0831  E5        		push	hl
2011    0832  DDE5      		push	ix
2012    0834  C1        		pop	bc
2013    0835  21EAFF    		ld	hl,65514
2014    0838  09        		add	hl,bc
2015    0839  CD0000    		call	_getkline
2016    083C  F1        		pop	af
2017    083D  79        		ld	a,c
2018    083E  B0        		or	b
2019    083F  281A      		jr	z,L171
2020                    	;  161                      {
2021                    	;  162                      sscanf(txtin, "%x", &dumpadr);
2022    0841  DDE5      		push	ix
2023    0843  C1        		pop	bc
2024    0844  21D2FF    		ld	hl,65490
2025    0847  09        		add	hl,bc
2026    0848  E5        		push	hl
2027    0849  218903    		ld	hl,L544
2028    084C  E5        		push	hl
2029    084D  DDE5      		push	ix
2030    084F  C1        		pop	bc
2031    0850  21EAFF    		ld	hl,65514
2032    0853  09        		add	hl,bc
2033    0854  CD0000    		call	_sscanf
2034    0857  F1        		pop	af
2035    0858  F1        		pop	af
2036                    	;  163                      }
2037                    	;  164                  else
2038    0859  180E      		jr	L102
2039                    	L171:
2040                    	;  165                      {
2041                    	;  166                      printf("%04x", dumpadr);
2042    085B  DD6ED2    		ld	l,(ix-46)
2043    085E  DD66D3    		ld	h,(ix-45)
2044    0861  E5        		push	hl
2045    0862  218C03    		ld	hl,L554
2046    0865  CD0000    		call	_printf
2047    0868  F1        		pop	af
2048                    	L102:
2049                    	;  167                      }
2050                    	;  168                  printf(" rows: ");
2051    0869  219103    		ld	hl,L564
2052    086C  CD0000    		call	_printf
2053                    	;  169                  if (getkline(txtin, sizeof txtin))
2054    086F  211000    		ld	hl,16
2055    0872  E5        		push	hl
2056    0873  DDE5      		push	ix
2057    0875  C1        		pop	bc
2058    0876  21EAFF    		ld	hl,65514
2059    0879  09        		add	hl,bc
2060    087A  CD0000    		call	_getkline
2061    087D  F1        		pop	af
2062    087E  79        		ld	a,c
2063    087F  B0        		or	b
2064    0880  281A      		jr	z,L112
2065                    	;  170                      {
2066                    	;  171                      sscanf(txtin, "%d", &dumprows);
2067    0882  DDE5      		push	ix
2068    0884  C1        		pop	bc
2069    0885  21D0FF    		ld	hl,65488
2070    0888  09        		add	hl,bc
2071    0889  E5        		push	hl
2072    088A  219903    		ld	hl,L574
2073    088D  E5        		push	hl
2074    088E  DDE5      		push	ix
2075    0890  C1        		pop	bc
2076    0891  21EAFF    		ld	hl,65514
2077    0894  09        		add	hl,bc
2078    0895  CD0000    		call	_sscanf
2079    0898  F1        		pop	af
2080    0899  F1        		pop	af
2081                    	;  172                      }
2082                    	;  173                  else
2083    089A  180E      		jr	L122
2084                    	L112:
2085                    	;  174                      {
2086                    	;  175                      printf("%d", dumprows);
2087    089C  DD6ED0    		ld	l,(ix-48)
2088    089F  DD66D1    		ld	h,(ix-47)
2089    08A2  E5        		push	hl
2090    08A3  219C03    		ld	hl,L505
2091    08A6  CD0000    		call	_printf
2092    08A9  F1        		pop	af
2093                    	L122:
2094                    	;  176                      }
2095                    	;  177                  printf("\n");
2096    08AA  219F03    		ld	hl,L515
2097    08AD  CD0000    		call	_printf
2098                    	;  178                  sddatprt(dumpadr, dumpadr, dumprows);
2099    08B0  DD6ED0    		ld	l,(ix-48)
2100    08B3  DD66D1    		ld	h,(ix-47)
2101    08B6  E5        		push	hl
2102    08B7  DD6ED2    		ld	l,(ix-46)
2103    08BA  DD66D3    		ld	h,(ix-45)
2104    08BD  E5        		push	hl
2105    08BE  DD6ED2    		ld	l,(ix-46)
2106    08C1  DD66D3    		ld	h,(ix-45)
2107    08C4  CD0000    		call	_sddatprt
2108    08C7  F1        		pop	af
2109    08C8  F1        		pop	af
2110                    	;  179                  break;
2111    08C9  C3C606    		jp	L12
2112                    	L132:
2113                    	;  180              case 'e':
2114                    	;  181                  printf(" e - execute address: 0x");
2115    08CC  21A103    		ld	hl,L525
2116    08CF  CD0000    		call	_printf
2117                    	;  182                  if (getkline(txtin, sizeof txtin))
2118    08D2  211000    		ld	hl,16
2119    08D5  E5        		push	hl
2120    08D6  DDE5      		push	ix
2121    08D8  C1        		pop	bc
2122    08D9  21EAFF    		ld	hl,65514
2123    08DC  09        		add	hl,bc
2124    08DD  CD0000    		call	_getkline
2125    08E0  F1        		pop	af
2126    08E1  79        		ld	a,c
2127    08E2  B0        		or	b
2128    08E3  2826      		jr	z,L142
2129                    	;  183                      {
2130                    	;  184                      sscanf(txtin, "%x", &exeadr);
2131    08E5  DDE5      		push	ix
2132    08E7  C1        		pop	bc
2133    08E8  21D4FF    		ld	hl,65492
2134    08EB  09        		add	hl,bc
2135    08EC  E5        		push	hl
2136    08ED  21BA03    		ld	hl,L535
2137    08F0  E5        		push	hl
2138    08F1  DDE5      		push	ix
2139    08F3  C1        		pop	bc
2140    08F4  21EAFF    		ld	hl,65514
2141    08F7  09        		add	hl,bc
2142    08F8  CD0000    		call	_sscanf
2143    08FB  F1        		pop	af
2144    08FC  F1        		pop	af
2145                    	;  185                      *exeadrptr = exeadr;
2146    08FD  2A0200    		ld	hl,(_exeadrptr)
2147    0900  DD7ED4    		ld	a,(ix-44)
2148    0903  77        		ld	(hl),a
2149    0904  DD7ED5    		ld	a,(ix-43)
2150    0907  23        		inc	hl
2151    0908  77        		ld	(hl),a
2152                    	;  186                      }
2153                    	;  187                  else
2154    0909  180E      		jr	L152
2155                    	L142:
2156                    	;  188                      {
2157                    	;  189                      printf("%04x", *exeadrptr);
2158    090B  2A0200    		ld	hl,(_exeadrptr)
2159    090E  4E        		ld	c,(hl)
2160    090F  23        		inc	hl
2161    0910  46        		ld	b,(hl)
2162    0911  C5        		push	bc
2163    0912  21BD03    		ld	hl,L545
2164    0915  CD0000    		call	_printf
2165    0918  F1        		pop	af
2166                    	L152:
2167                    	;  190                      }
2168                    	;  191                  printf("\n");
2169    0919  21C203    		ld	hl,L555
2170    091C  CD0000    		call	_printf
2171                    	;  192                  break;
2172    091F  C3C606    		jp	L12
2173                    	L162:
2174                    	;  193              case 'i':
2175                    	;  194                  printf(" i - initialize SD card");
2176    0922  21C403    		ld	hl,L565
2177    0925  CD0000    		call	_printf
2178                    	;  195                  if (sdinit())
2179    0928  CD0000    		call	_sdinit
2180    092B  79        		ld	a,c
2181    092C  B0        		or	b
2182    092D  2809      		jr	z,L172
2183                    	;  196                      printf(" - ok\n");
2184    092F  21DC03    		ld	hl,L575
2185    0932  CD0000    		call	_printf
2186                    	;  197                  else
2187    0935  C3C606    		jp	L12
2188                    	L172:
2189                    	;  198                      printf(" - not inserted or faulty\n");
2190    0938  21E303    		ld	hl,L506
2191    093B  CD0000    		call	_printf
2192    093E  C3C606    		jp	L12
2193                    	L113:
2194                    	;  199                  break;
2195                    	;  200              case 'l':
2196                    	;  201                  printf(" l - print partition layout\n");
2197    0941  21FE03    		ld	hl,L516
2198    0944  CD0000    		call	_printf
2199                    	;  202                  if (!sdprobe())
2200    0947  CD0000    		call	_sdprobe
2201    094A  79        		ld	a,c
2202    094B  B0        		or	b
2203    094C  2009      		jr	nz,L123
2204                    	;  203                      {
2205                    	;  204                      printf(" - not initialized or inserted or faulty\n");
2206    094E  211B04    		ld	hl,L526
2207    0951  CD0000    		call	_printf
2208                    	;  205                      break;
2209    0954  C3C606    		jp	L12
2210                    	L123:
2211                    	;  206                      }
2212                    	;  207                  sdpartfind();
2213    0957  CD0000    		call	_sdpartfind
2214                    	;  208                  sdpartprint();
2215    095A  CD0000    		call	_sdpartprint
2216                    	;  209                  break;
2217    095D  C3C606    		jp	L12
2218                    	L133:
2219                    	;  210              case 'n':
2220                    	;  211                  printf(" n - block number: ");
2221    0960  214504    		ld	hl,L536
2222    0963  CD0000    		call	_printf
2223                    	;  212                  if (getkline(txtin, sizeof txtin))
2224    0966  211000    		ld	hl,16
2225    0969  E5        		push	hl
2226    096A  DDE5      		push	ix
2227    096C  C1        		pop	bc
2228    096D  21EAFF    		ld	hl,65514
2229    0970  09        		add	hl,bc
2230    0971  CD0000    		call	_getkline
2231    0974  F1        		pop	af
2232    0975  79        		ld	a,c
2233    0976  B0        		or	b
2234    0977  2834      		jr	z,L143
2235                    	;  213                      {
2236                    	;  214                      sscanf(txtin, "%lu", &inblockno);
2237    0979  DDE5      		push	ix
2238    097B  C1        		pop	bc
2239    097C  21D8FF    		ld	hl,65496
2240    097F  09        		add	hl,bc
2241    0980  E5        		push	hl
2242    0981  215904    		ld	hl,L546
2243    0984  E5        		push	hl
2244    0985  DDE5      		push	ix
2245    0987  C1        		pop	bc
2246    0988  21EAFF    		ld	hl,65514
2247    098B  09        		add	hl,bc
2248    098C  CD0000    		call	_sscanf
2249    098F  F1        		pop	af
2250    0990  F1        		pop	af
2251                    	;  215                      ul2blk(blockno, inblockno);
2252    0991  DD66DB    		ld	h,(ix-37)
2253    0994  DD6EDA    		ld	l,(ix-38)
2254    0997  E5        		push	hl
2255    0998  DD66D9    		ld	h,(ix-39)
2256    099B  DD6ED8    		ld	l,(ix-40)
2257    099E  E5        		push	hl
2258    099F  DDE5      		push	ix
2259    09A1  C1        		pop	bc
2260    09A2  21DCFF    		ld	hl,65500
2261    09A5  09        		add	hl,bc
2262    09A6  CD0000    		call	_ul2blk
2263    09A9  F1        		pop	af
2264    09AA  F1        		pop	af
2265                    	;  216                      }
2266                    	;  217                  else
2267    09AB  181E      		jr	L153
2268                    	L143:
2269                    	;  218                      printf("%lu", blk2ul(blockno));
2270    09AD  DDE5      		push	ix
2271    09AF  C1        		pop	bc
2272    09B0  21DCFF    		ld	hl,65500
2273    09B3  09        		add	hl,bc
2274    09B4  CD0000    		call	_blk2ul
2275    09B7  210300    		ld	hl,c.r0+3
2276    09BA  46        		ld	b,(hl)
2277    09BB  2B        		dec	hl
2278    09BC  4E        		ld	c,(hl)
2279    09BD  C5        		push	bc
2280    09BE  2B        		dec	hl
2281    09BF  46        		ld	b,(hl)
2282    09C0  2B        		dec	hl
2283    09C1  4E        		ld	c,(hl)
2284    09C2  C5        		push	bc
2285    09C3  215D04    		ld	hl,L556
2286    09C6  CD0000    		call	_printf
2287    09C9  F1        		pop	af
2288    09CA  F1        		pop	af
2289                    	L153:
2290                    	;  219                  printf("\n");
2291    09CB  216104    		ld	hl,L566
2292    09CE  CD0000    		call	_printf
2293                    	;  220                  break;
2294    09D1  C3C606    		jp	L12
2295                    	L163:
2296                    	;  221              case 'p':
2297                    	;  222                  printf(" p - print data block %lu\n", blk2ul(curblkno));
2298    09D4  210000    		ld	hl,_curblkno
2299    09D7  CD0000    		call	_blk2ul
2300    09DA  210300    		ld	hl,c.r0+3
2301    09DD  46        		ld	b,(hl)
2302    09DE  2B        		dec	hl
2303    09DF  4E        		ld	c,(hl)
2304    09E0  C5        		push	bc
2305    09E1  2B        		dec	hl
2306    09E2  46        		ld	b,(hl)
2307    09E3  2B        		dec	hl
2308    09E4  4E        		ld	c,(hl)
2309    09E5  C5        		push	bc
2310    09E6  216304    		ld	hl,L576
2311    09E9  CD0000    		call	_printf
2312    09EC  F1        		pop	af
2313    09ED  F1        		pop	af
2314                    	;  223                  sddatprt(sdrdbuf, 0x0000, 32);
2315    09EE  212000    		ld	hl,32
2316    09F1  E5        		push	hl
2317    09F2  210000    		ld	hl,0
2318    09F5  E5        		push	hl
2319    09F6  210000    		ld	hl,_sdrdbuf
2320    09F9  CD0000    		call	_sddatprt
2321    09FC  F1        		pop	af
2322    09FD  F1        		pop	af
2323                    	;  224                  break;
2324    09FE  C3C606    		jp	L12
2325                    	L173:
2326                    	;  225              case 'r':
2327                    	;  226                  printf(" r - read block");
2328    0A01  217E04    		ld	hl,L507
2329    0A04  CD0000    		call	_printf
2330                    	;  227                  if (!sdprobe())
2331    0A07  CD0000    		call	_sdprobe
2332    0A0A  79        		ld	a,c
2333    0A0B  B0        		or	b
2334    0A0C  2009      		jr	nz,L104
2335                    	;  228                      {
2336                    	;  229                      printf(" - not initialized or inserted or faulty\n");
2337    0A0E  218E04    		ld	hl,L517
2338    0A11  CD0000    		call	_printf
2339                    	;  230                      break;
2340    0A14  C3C606    		jp	L12
2341                    	L104:
2342                    	;  231                      }
2343                    	;  232                  if (sdread(sdrdbuf, blockno))
2344    0A17  DDE5      		push	ix
2345    0A19  C1        		pop	bc
2346    0A1A  21DCFF    		ld	hl,65500
2347    0A1D  09        		add	hl,bc
2348    0A1E  E5        		push	hl
2349    0A1F  210000    		ld	hl,_sdrdbuf
2350    0A22  CD0000    		call	_sdread
2351    0A25  F1        		pop	af
2352    0A26  79        		ld	a,c
2353    0A27  B0        		or	b
2354    0A28  281D      		jr	z,L114
2355                    	;  233                      {
2356                    	;  234                      printf(" - ok\n");
2357    0A2A  21B804    		ld	hl,L527
2358    0A2D  CD0000    		call	_printf
2359                    	;  235                      memcpy(curblkno, blockno, 4);
2360    0A30  210400    		ld	hl,4
2361    0A33  E5        		push	hl
2362    0A34  DDE5      		push	ix
2363    0A36  C1        		pop	bc
2364    0A37  21DCFF    		ld	hl,65500
2365    0A3A  09        		add	hl,bc
2366    0A3B  E5        		push	hl
2367    0A3C  210000    		ld	hl,_curblkno
2368    0A3F  CD0000    		call	_memcpy
2369    0A42  F1        		pop	af
2370    0A43  F1        		pop	af
2371                    	;  236                      }
2372                    	;  237                  else
2373    0A44  C3C606    		jp	L12
2374                    	L114:
2375                    	;  238                      printf(" - read error\n");
2376    0A47  21BF04    		ld	hl,L537
2377    0A4A  CD0000    		call	_printf
2378    0A4D  C3C606    		jp	L12
2379                    	L134:
2380                    	;  239                  break;
2381                    	;  240              case 's':
2382                    	;  241                  printf(" s - print SD registers\n");
2383    0A50  21CE04    		ld	hl,L547
2384    0A53  CD0000    		call	_printf
2385                    	;  242                  sdprtreg();
2386    0A56  CD0000    		call	_sdprtreg
2387                    	;  243                  break;
2388    0A59  C3C606    		jp	L12
2389                    	L144:
2390                    	;  244              case 't':
2391                    	;  245                  printf(" t - test if card inserted\n");
2392    0A5C  21E704    		ld	hl,L557
2393    0A5F  CD0000    		call	_printf
2394                    	;  246                  if (sdprobe())
2395    0A62  CD0000    		call	_sdprobe
2396    0A65  79        		ld	a,c
2397    0A66  B0        		or	b
2398    0A67  2809      		jr	z,L154
2399                    	;  247                      printf(" - ok\n");
2400    0A69  210305    		ld	hl,L567
2401    0A6C  CD0000    		call	_printf
2402                    	;  248                  else
2403    0A6F  C3C606    		jp	L12
2404                    	L154:
2405                    	;  249                      printf(" - not initialized or inserted or faulty\n");
2406    0A72  210A05    		ld	hl,L577
2407    0A75  CD0000    		call	_printf
2408    0A78  C3C606    		jp	L12
2409                    	L174:
2410                    	;  250                  break;
2411                    	;  251              case 'u':
2412                    	;  252                  printf(" %c - upload to 0x%04x and execute at: 0x%04x\n",
2413                    	;  253                      cmdin, *upladrptr, *exeadrptr);
2414    0A7B  2A0200    		ld	hl,(_exeadrptr)
2415    0A7E  4E        		ld	c,(hl)
2416    0A7F  23        		inc	hl
2417    0A80  46        		ld	b,(hl)
2418    0A81  C5        		push	bc
2419    0A82  2A0400    		ld	hl,(_upladrptr)
2420    0A85  4E        		ld	c,(hl)
2421    0A86  23        		inc	hl
2422    0A87  46        		ld	b,(hl)
2423    0A88  C5        		push	bc
2424    0A89  DD6EE8    		ld	l,(ix-24)
2425    0A8C  DD66E9    		ld	h,(ix-23)
2426    0A8F  E5        		push	hl
2427    0A90  213405    		ld	hl,L5001
2428    0A93  CD0000    		call	_printf
2429    0A96  F1        		pop	af
2430    0A97  F1        		pop	af
2431    0A98  F1        		pop	af
2432                    	;  254                  printf("(Uploader code at: 0x%04x, size: %d)\n", LOADADR, upload_size);
2433    0A99  2A0000    		ld	hl,(_upload_size)
2434    0A9C  E5        		push	hl
2435    0A9D  2100B0    		ld	hl,45056
2436    0AA0  E5        		push	hl
2437    0AA1  216305    		ld	hl,L5101
2438    0AA4  CD0000    		call	_printf
2439    0AA7  F1        		pop	af
2440    0AA8  F1        		pop	af
2441                    	;  255                  memcpy(LOADADR, upload, upload_size);
2442    0AA9  2A0000    		ld	hl,(_upload_size)
2443    0AAC  E5        		push	hl
2444    0AAD  210000    		ld	hl,_upload
2445    0AB0  E5        		push	hl
2446    0AB1  2100B0    		ld	hl,45056
2447    0AB4  CD0000    		call	_memcpy
2448    0AB7  F1        		pop	af
2449    0AB8  F1        		pop	af
2450                    	;  256                  jumpto(LOADADR);
2451    0AB9  2100B0    		ld	hl,45056
2452    0ABC  CD0000    		call	_jumpto
2453                    	;  257                  break;
2454    0ABF  C3C606    		jp	L12
2455                    	L105:
2456                    	;  258              case 'w':
2457                    	;  259                  printf(" w - write block");
2458    0AC2  218905    		ld	hl,L5201
2459    0AC5  CD0000    		call	_printf
2460                    	;  260                  if (!sdprobe())
2461    0AC8  CD0000    		call	_sdprobe
2462    0ACB  79        		ld	a,c
2463    0ACC  B0        		or	b
2464    0ACD  2009      		jr	nz,L115
2465                    	;  261                      {
2466                    	;  262                      printf(" - not initialized or inserted or faulty\n");
2467    0ACF  219A05    		ld	hl,L5301
2468    0AD2  CD0000    		call	_printf
2469                    	;  263                      break;
2470    0AD5  C3C606    		jp	L12
2471                    	L115:
2472                    	;  264                      }
2473                    	;  265                  if (sdwrite(sdrdbuf, blockno))
2474    0AD8  DDE5      		push	ix
2475    0ADA  C1        		pop	bc
2476    0ADB  21DCFF    		ld	hl,65500
2477    0ADE  09        		add	hl,bc
2478    0ADF  E5        		push	hl
2479    0AE0  210000    		ld	hl,_sdrdbuf
2480    0AE3  CD0000    		call	_sdwrite
2481    0AE6  F1        		pop	af
2482    0AE7  79        		ld	a,c
2483    0AE8  B0        		or	b
2484    0AE9  281D      		jr	z,L125
2485                    	;  266                      {
2486                    	;  267                      printf(" - ok\n");
2487    0AEB  21C405    		ld	hl,L5401
2488    0AEE  CD0000    		call	_printf
2489                    	;  268                      memcpy(curblkno, blockno, 4);
2490    0AF1  210400    		ld	hl,4
2491    0AF4  E5        		push	hl
2492    0AF5  DDE5      		push	ix
2493    0AF7  C1        		pop	bc
2494    0AF8  21DCFF    		ld	hl,65500
2495    0AFB  09        		add	hl,bc
2496    0AFC  E5        		push	hl
2497    0AFD  210000    		ld	hl,_curblkno
2498    0B00  CD0000    		call	_memcpy
2499    0B03  F1        		pop	af
2500    0B04  F1        		pop	af
2501                    	;  269                      }
2502                    	;  270                  else
2503    0B05  C3C606    		jp	L12
2504                    	L125:
2505                    	;  271                      printf(" - write error\n");
2506    0B08  21CB05    		ld	hl,L5501
2507    0B0B  CD0000    		call	_printf
2508    0B0E  C3C606    		jp	L12
2509                    	L145:
2510                    	;  272                  break;
2511                    	;  273              case 0x03: /* Ctrl-C */
2512                    	;  274                  printf("reloading monitor from EPROM\n");
2513    0B11  21DB05    		ld	hl,L5601
2514    0B14  CD0000    		call	_printf
2515                    	;  275                  reload();
2516    0B17  CD0000    		call	_reload
2517                    	;  276                  break; /* not really needed, will never get here */
2518    0B1A  C3C606    		jp	L12
2519                    	L155:
2520                    	;  277              default:
2521                    	;  278                  printf(" invalid command\n");
2522    0B1D  21F905    		ld	hl,L5701
2523    0B20  CD0000    		call	_printf
2524    0B23  C3C606    		jp	L12
2525                    	L15:
2526                    	;  279              }
2527                    	;  280          }
2528    0B26  C3C606    		jp	L12
2529                    	;  281      }
2530                    	;  282  
2531                    		.psect	_bss
2532                    	_rampptr:
2533                    		.byte	[2]
2534                    	_exeadrptr:
2535                    		.byte	[2]
2536                    	_upladrptr:
2537                    		.byte	[2]
2538                    		.external	_curblkno
2539                    		.external	_jumpto
2540                    		.external	_upload_size
2541                    		.external	_jumptoram
2542                    		.external	_cpmsys
2543                    		.external	c.savs0
2544                    		.external	_getchar
2545                    		.public	_upladrptr
2546                    		.external	_curblkok
2547                    		.public	_ramprobe
2548                    		.external	c.r0
2549                    		.external	_getkline
2550                    		.external	c.jtab
2551                    		.external	_printf
2552                    		.public	_exeadrptr
2553                    		.external	_blk2ul
2554                    		.external	_ul2blk
2555                    		.external	_memcpy
2556                    		.external	_sdinit
2557                    		.external	_memset
2558                    		.public	_rampptr
2559                    		.external	_upload
2560                    		.external	_sdwrite
2561                    		.external	_sscanf
2562                    		.public	_execin
2563                    		.external	_sdpartprint
2564                    		.external	_cpmsys_size
2565                    		.external	_reload
2566                    		.external	_sdread
2567                    		.external	_sdpartfind
2568                    		.external	_sdprobe
2569                    		.external	_builddate
2570                    		.external	_sdprtreg
2571                    		.external	_sdrdbuf
2572                    		.external	_sddatprt
2573                    		.external	_sdinitok
2574                    		.public	_main
2575                    		.external	_byteblkadr
2576                    		.end
