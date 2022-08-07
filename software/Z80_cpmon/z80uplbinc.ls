   1                    	;    1  /* Created by the bintoc program: Sun Aug  7 18:56:43 2022
   2                    	;    2   * Input file names: z80upload.bin, 
   3                    	;    3   * Output file name: z80uplbinc.c
   4                    	;    4   * Byte array name: upload
   5                    	;    5   * Variable with size of byte array: upload_size
   6                    	;    6   */
   7                    	;    7  const unsigned char upload[] = {
   8                    		.psect	_text
   9                    	_upload:
  10                    	;    8      0xc3, 0x0c, 0xb0, 0x3e, 0x03, 0xd3, 0x0e, 0xd3, 0x00, 0xc3, 0x00, 0x00, 
  11    0000  C3        		.byte	195
  12    0001  0C        		.byte	12
  13    0002  B0        		.byte	176
  14    0003  3E        		.byte	62
  15    0004  03        		.byte	3
  16    0005  D3        		.byte	211
  17    0006  0E        		.byte	14
  18    0007  D3        		.byte	211
  19                    		.byte	[1]
  20    0009  C3        		.byte	195
  21                    		.byte	[1]
  22                    		.byte	[1]
  23                    	;    9      0x31, 0x00, 0xb0, 0xd3, 0x14, 0xf3, 0xcd, 0x18, 0xb0, 0xc3, 0x1f, 0xb1, 
  24    000C  31        		.byte	49
  25                    		.byte	[1]
  26    000E  B0        		.byte	176
  27    000F  D3        		.byte	211
  28    0010  14        		.byte	20
  29    0011  F3        		.byte	243
  30    0012  CD        		.byte	205
  31    0013  18        		.byte	24
  32    0014  B0        		.byte	176
  33    0015  C3        		.byte	195
  34    0016  1F        		.byte	31
  35    0017  B1        		.byte	177
  36                    	;   10      0x21, 0xe4, 0xb0, 0xcd, 0x9b, 0xb1, 0xd3, 0x04, 0x06, 0x01, 0xcd, 0x6b, 
  37    0018  21        		.byte	33
  38    0019  E4        		.byte	228
  39    001A  B0        		.byte	176
  40    001B  CD        		.byte	205
  41    001C  9B        		.byte	155
  42    001D  B1        		.byte	177
  43    001E  D3        		.byte	211
  44    001F  04        		.byte	4
  45    0020  06        		.byte	6
  46    0021  01        		.byte	1
  47    0022  CD        		.byte	205
  48    0023  6B        		.byte	107
  49                    	;   11      0xb1, 0x38, 0x07, 0xfe, 0x03, 0xca, 0xdb, 0xb0, 0x18, 0xf2, 0x2a, 0xf0, 
  50    0024  B1        		.byte	177
  51    0025  38        		.byte	56
  52    0026  07        		.byte	7
  53    0027  FE        		.byte	254
  54    0028  03        		.byte	3
  55    0029  CA        		.byte	202
  56    002A  DB        		.byte	219
  57    002B  B0        		.byte	176
  58    002C  18        		.byte	24
  59    002D  F2        		.byte	242
  60    002E  2A        		.byte	42
  61    002F  F0        		.byte	240
  62                    	;   12      0xfe, 0x22, 0xab, 0xb1, 0x3e, 0x00, 0x32, 0xae, 0xb1, 0x3e, 0x15, 0xcd, 
  63    0030  FE        		.byte	254
  64    0031  22        		.byte	34
  65    0032  AB        		.byte	171
  66    0033  B1        		.byte	177
  67    0034  3E        		.byte	62
  68                    		.byte	[1]
  69    0036  32        		.byte	50
  70    0037  AE        		.byte	174
  71    0038  B1        		.byte	177
  72    0039  3E        		.byte	62
  73    003A  15        		.byte	21
  74    003B  CD        		.byte	205
  75                    	;   13      0x59, 0xb1, 0x06, 0x03, 0xcd, 0x6b, 0xb1, 0x30, 0x0e, 0x06, 0x01, 0xcd, 
  76    003C  59        		.byte	89
  77    003D  B1        		.byte	177
  78    003E  06        		.byte	6
  79    003F  03        		.byte	3
  80    0040  CD        		.byte	205
  81    0041  6B        		.byte	107
  82    0042  B1        		.byte	177
  83    0043  30        		.byte	48
  84    0044  0E        		.byte	14
  85    0045  06        		.byte	6
  86    0046  01        		.byte	1
  87    0047  CD        		.byte	205
  88                    	;   14      0x6b, 0xb1, 0x30, 0xf9, 0x3e, 0x15, 0xcd, 0x59, 0xb1, 0x18, 0xeb, 0xfe, 
  89    0048  6B        		.byte	107
  90    0049  B1        		.byte	177
  91    004A  30        		.byte	48
  92    004B  F9        		.byte	249
  93    004C  3E        		.byte	62
  94    004D  15        		.byte	21
  95    004E  CD        		.byte	205
  96    004F  59        		.byte	89
  97    0050  B1        		.byte	177
  98    0051  18        		.byte	24
  99    0052  EB        		.byte	235
 100    0053  FE        		.byte	254
 101                    	;   15      0x01, 0x28, 0x0c, 0xfe, 0x03, 0xca, 0xdb, 0xb0, 0xfe, 0x04, 0xca, 0xc7, 
 102    0054  01        		.byte	1
 103    0055  28        		.byte	40
 104    0056  0C        		.byte	12
 105    0057  FE        		.byte	254
 106    0058  03        		.byte	3
 107    0059  CA        		.byte	202
 108    005A  DB        		.byte	219
 109    005B  B0        		.byte	176
 110    005C  FE        		.byte	254
 111    005D  04        		.byte	4
 112    005E  CA        		.byte	202
 113    005F  C7        		.byte	199
 114                    	;   16      0xb0, 0x18, 0xe2, 0x06, 0x01, 0xcd, 0x6b, 0xb1, 0x38, 0xdb, 0x57, 0x06, 
 115    0060  B0        		.byte	176
 116    0061  18        		.byte	24
 117    0062  E2        		.byte	226
 118    0063  06        		.byte	6
 119    0064  01        		.byte	1
 120    0065  CD        		.byte	205
 121    0066  6B        		.byte	107
 122    0067  B1        		.byte	177
 123    0068  38        		.byte	56
 124    0069  DB        		.byte	219
 125    006A  57        		.byte	87
 126    006B  06        		.byte	6
 127                    	;   17      0x01, 0xcd, 0x6b, 0xb1, 0x38, 0xd3, 0x2f, 0xba, 0x28, 0x02, 0x18, 0xcd, 
 128    006C  01        		.byte	1
 129    006D  CD        		.byte	205
 130    006E  6B        		.byte	107
 131    006F  B1        		.byte	177
 132    0070  38        		.byte	56
 133    0071  D3        		.byte	211
 134    0072  2F        		.byte	47
 135    0073  BA        		.byte	186
 136    0074  28        		.byte	40
 137    0075  02        		.byte	2
 138    0076  18        		.byte	24
 139    0077  CD        		.byte	205
 140                    	;   18      0x7a, 0x32, 0xad, 0xb1, 0x0e, 0x00, 0x21, 0xaf, 0xb1, 0x16, 0x80, 0x06, 
 141    0078  7A        		.byte	122
 142    0079  32        		.byte	50
 143    007A  AD        		.byte	173
 144    007B  B1        		.byte	177
 145    007C  0E        		.byte	14
 146                    		.byte	[1]
 147    007E  21        		.byte	33
 148    007F  AF        		.byte	175
 149    0080  B1        		.byte	177
 150    0081  16        		.byte	22
 151    0082  80        		.byte	128
 152    0083  06        		.byte	6
 153                    	;   19      0x01, 0xcd, 0x6b, 0xb1, 0x38, 0xbb, 0x77, 0x81, 0x4f, 0x23, 0x15, 0x20, 
 154    0084  01        		.byte	1
 155    0085  CD        		.byte	205
 156    0086  6B        		.byte	107
 157    0087  B1        		.byte	177
 158    0088  38        		.byte	56
 159    0089  BB        		.byte	187
 160    008A  77        		.byte	119
 161    008B  81        		.byte	129
 162    008C  4F        		.byte	79
 163    008D  23        		.byte	35
 164    008E  15        		.byte	21
 165    008F  20        		.byte	32
 166                    	;   20      0xf2, 0x51, 0x06, 0x01, 0xcd, 0x6b, 0xb1, 0x38, 0xac, 0xba, 0x20, 0xa9, 
 167    0090  F2        		.byte	242
 168    0091  51        		.byte	81
 169    0092  06        		.byte	6
 170    0093  01        		.byte	1
 171    0094  CD        		.byte	205
 172    0095  6B        		.byte	107
 173    0096  B1        		.byte	177
 174    0097  38        		.byte	56
 175    0098  AC        		.byte	172
 176    0099  BA        		.byte	186
 177    009A  20        		.byte	32
 178    009B  A9        		.byte	169
 179                    	;   21      0x3a, 0xad, 0xb1, 0x47, 0x3a, 0xae, 0xb1, 0x3c, 0xb8, 0x28, 0x02, 0x18, 
 180    009C  3A        		.byte	58
 181    009D  AD        		.byte	173
 182    009E  B1        		.byte	177
 183    009F  47        		.byte	71
 184    00A0  3A        		.byte	58
 185    00A1  AE        		.byte	174
 186    00A2  B1        		.byte	177
 187    00A3  3C        		.byte	60
 188    00A4  B8        		.byte	184
 189    00A5  28        		.byte	40
 190    00A6  02        		.byte	2
 191    00A7  18        		.byte	24
 192                    	;   22      0x16, 0x3a, 0xad, 0xb1, 0x32, 0xae, 0xb1, 0xed, 0x5b, 0xab, 0xb1, 0x21, 
 193    00A8  16        		.byte	22
 194    00A9  3A        		.byte	58
 195    00AA  AD        		.byte	173
 196    00AB  B1        		.byte	177
 197    00AC  32        		.byte	50
 198    00AD  AE        		.byte	174
 199    00AE  B1        		.byte	177
 200    00AF  ED        		.byte	237
 201    00B0  5B        		.byte	91
 202    00B1  AB        		.byte	171
 203    00B2  B1        		.byte	177
 204    00B3  21        		.byte	33
 205                    	;   23      0xaf, 0xb1, 0x01, 0x80, 0x00, 0xed, 0xb0, 0xed, 0x53, 0xab, 0xb1, 0x3e, 
 206    00B4  AF        		.byte	175
 207    00B5  B1        		.byte	177
 208    00B6  01        		.byte	1
 209    00B7  80        		.byte	128
 210                    		.byte	[1]
 211    00B9  ED        		.byte	237
 212    00BA  B0        		.byte	176
 213    00BB  ED        		.byte	237
 214    00BC  53        		.byte	83
 215    00BD  AB        		.byte	171
 216    00BE  B1        		.byte	177
 217    00BF  3E        		.byte	62
 218                    	;   24      0x06, 0xcd, 0x59, 0xb1, 0xc3, 0x3e, 0xb0, 0x3e, 0x06, 0xcd, 0x59, 0xb1, 
 219    00C0  06        		.byte	6
 220    00C1  CD        		.byte	205
 221    00C2  59        		.byte	89
 222    00C3  B1        		.byte	177
 223    00C4  C3        		.byte	195
 224    00C5  3E        		.byte	62
 225    00C6  B0        		.byte	176
 226    00C7  3E        		.byte	62
 227    00C8  06        		.byte	6
 228    00C9  CD        		.byte	205
 229    00CA  59        		.byte	89
 230    00CB  B1        		.byte	177
 231                    	;   25      0x21, 0x30, 0x75, 0x2b, 0x7c, 0xb5, 0x20, 0xfb, 0x21, 0xf4, 0xb0, 0xcd, 
 232    00CC  21        		.byte	33
 233    00CD  30        		.byte	48
 234    00CE  75        		.byte	117
 235    00CF  2B        		.byte	43
 236    00D0  7C        		.byte	124
 237    00D1  B5        		.byte	181
 238    00D2  20        		.byte	32
 239    00D3  FB        		.byte	251
 240    00D4  21        		.byte	33
 241    00D5  F4        		.byte	244
 242    00D6  B0        		.byte	176
 243    00D7  CD        		.byte	205
 244                    	;   26      0x9b, 0xb1, 0xc9, 0x21, 0x08, 0xb1, 0xcd, 0x9b, 0xb1, 0xc3, 0x03, 0xb0, 
 245    00D8  9B        		.byte	155
 246    00D9  B1        		.byte	177
 247    00DA  C9        		.byte	201
 248    00DB  21        		.byte	33
 249    00DC  08        		.byte	8
 250    00DD  B1        		.byte	177
 251    00DE  CD        		.byte	205
 252    00DF  9B        		.byte	155
 253    00E0  B1        		.byte	177
 254    00E1  C3        		.byte	195
 255    00E2  03        		.byte	3
 256    00E3  B0        		.byte	176
 257                    	;   27      0x75, 0x70, 0x6c, 0x6f, 0x61, 0x64, 0x69, 0x6e, 0x67, 0x20, 0x66, 0x69, 
 258    00E4  75        		.byte	117
 259    00E5  70        		.byte	112
 260    00E6  6C        		.byte	108
 261    00E7  6F        		.byte	111
 262    00E8  61        		.byte	97
 263    00E9  64        		.byte	100
 264    00EA  69        		.byte	105
 265    00EB  6E        		.byte	110
 266    00EC  67        		.byte	103
 267    00ED  20        		.byte	32
 268    00EE  66        		.byte	102
 269    00EF  69        		.byte	105
 270                    	;   28      0x6c, 0x65, 0x20, 0x00, 0x2d, 0x20, 0x75, 0x70, 0x6c, 0x6f, 0x61, 0x64, 
 271    00F0  6C        		.byte	108
 272    00F1  65        		.byte	101
 273    00F2  20        		.byte	32
 274                    		.byte	[1]
 275    00F4  2D        		.byte	45
 276    00F5  20        		.byte	32
 277    00F6  75        		.byte	117
 278    00F7  70        		.byte	112
 279    00F8  6C        		.byte	108
 280    00F9  6F        		.byte	111
 281    00FA  61        		.byte	97
 282    00FB  64        		.byte	100
 283                    	;   29      0x20, 0x63, 0x6f, 0x6d, 0x70, 0x6c, 0x65, 0x74, 0x65, 0x0d, 0x0a, 0x00, 
 284    00FC  20        		.byte	32
 285    00FD  63        		.byte	99
 286    00FE  6F        		.byte	111
 287    00FF  6D        		.byte	109
 288    0100  70        		.byte	112
 289    0101  6C        		.byte	108
 290    0102  65        		.byte	101
 291    0103  74        		.byte	116
 292    0104  65        		.byte	101
 293    0105  0D        		.byte	13
 294    0106  0A        		.byte	10
 295                    		.byte	[1]
 296                    	;   30      0x0d, 0x0a, 0x75, 0x70, 0x6c, 0x6f, 0x61, 0x64, 0x20, 0x69, 0x6e, 0x74, 
 297    0108  0D        		.byte	13
 298    0109  0A        		.byte	10
 299    010A  75        		.byte	117
 300    010B  70        		.byte	112
 301    010C  6C        		.byte	108
 302    010D  6F        		.byte	111
 303    010E  61        		.byte	97
 304    010F  64        		.byte	100
 305    0110  20        		.byte	32
 306    0111  69        		.byte	105
 307    0112  6E        		.byte	110
 308    0113  74        		.byte	116
 309                    	;   31      0x65, 0x72, 0x72, 0x75, 0x70, 0x74, 0x65, 0x64, 0x0d, 0x0a, 0x00, 0xd3, 
 310    0114  65        		.byte	101
 311    0115  72        		.byte	114
 312    0116  72        		.byte	114
 313    0117  75        		.byte	117
 314    0118  70        		.byte	112
 315    0119  74        		.byte	116
 316    011A  65        		.byte	101
 317    011B  64        		.byte	100
 318    011C  0D        		.byte	13
 319    011D  0A        		.byte	10
 320                    		.byte	[1]
 321    011F  D3        		.byte	211
 322                    	;   32      0x04, 0x21, 0x2b, 0xb1, 0xcd, 0x9b, 0xb1, 0x2a, 0xf2, 0xfe, 0xe9, 0x65, 
 323    0120  04        		.byte	4
 324    0121  21        		.byte	33
 325    0122  2B        		.byte	43
 326    0123  B1        		.byte	177
 327    0124  CD        		.byte	205
 328    0125  9B        		.byte	155
 329    0126  B1        		.byte	177
 330    0127  2A        		.byte	42
 331    0128  F2        		.byte	242
 332    0129  FE        		.byte	254
 333    012A  E9        		.byte	233
 334    012B  65        		.byte	101
 335                    	;   33      0x78, 0x65, 0x63, 0x75, 0x74, 0x69, 0x6e, 0x67, 0x20, 0x63, 0x6f, 0x64, 
 336    012C  78        		.byte	120
 337    012D  65        		.byte	101
 338    012E  63        		.byte	99
 339    012F  75        		.byte	117
 340    0130  74        		.byte	116
 341    0131  69        		.byte	105
 342    0132  6E        		.byte	110
 343    0133  67        		.byte	103
 344    0134  20        		.byte	32
 345    0135  63        		.byte	99
 346    0136  6F        		.byte	111
 347    0137  64        		.byte	100
 348                    	;   34      0x65, 0x20, 0x69, 0x6e, 0x20, 0x52, 0x41, 0x4d, 0x0d, 0x0a, 0x00, 0xf5, 
 349    0138  65        		.byte	101
 350    0139  20        		.byte	32
 351    013A  69        		.byte	105
 352    013B  6E        		.byte	110
 353    013C  20        		.byte	32
 354    013D  52        		.byte	82
 355    013E  41        		.byte	65
 356    013F  4D        		.byte	77
 357    0140  0D        		.byte	13
 358    0141  0A        		.byte	10
 359                    		.byte	[1]
 360    0143  F5        		.byte	245
 361                    	;   35      0xc5, 0xdb, 0x0a, 0xcb, 0x57, 0x28, 0xfa, 0xc1, 0xf1, 0xc9, 0xf5, 0xc5, 
 362    0144  C5        		.byte	197
 363    0145  DB        		.byte	219
 364    0146  0A        		.byte	10
 365    0147  CB        		.byte	203
 366    0148  57        		.byte	87
 367    0149  28        		.byte	40
 368    014A  FA        		.byte	250
 369    014B  C1        		.byte	193
 370    014C  F1        		.byte	241
 371    014D  C9        		.byte	201
 372    014E  F5        		.byte	245
 373    014F  C5        		.byte	197
 374                    	;   36      0xdb, 0x0a, 0xcb, 0x47, 0x28, 0xfa, 0xc1, 0xf1, 0xc9, 0xc5, 0xf5, 0xcd, 
 375    0150  DB        		.byte	219
 376    0151  0A        		.byte	10
 377    0152  CB        		.byte	203
 378    0153  47        		.byte	71
 379    0154  28        		.byte	40
 380    0155  FA        		.byte	250
 381    0156  C1        		.byte	193
 382    0157  F1        		.byte	241
 383    0158  C9        		.byte	201
 384    0159  C5        		.byte	197
 385    015A  F5        		.byte	245
 386    015B  CD        		.byte	205
 387                    	;   37      0x43, 0xb1, 0xf1, 0xd3, 0x08, 0xc1, 0xc9, 0xc5, 0xcd, 0x4e, 0xb1, 0xdb, 
 388    015C  43        		.byte	67
 389    015D  B1        		.byte	177
 390    015E  F1        		.byte	241
 391    015F  D3        		.byte	211
 392    0160  08        		.byte	8
 393    0161  C1        		.byte	193
 394    0162  C9        		.byte	201
 395    0163  C5        		.byte	197
 396    0164  CD        		.byte	205
 397    0165  4E        		.byte	78
 398    0166  B1        		.byte	177
 399    0167  DB        		.byte	219
 400                    	;   38      0x08, 0xc1, 0xc9, 0xc5, 0xd5, 0x11, 0x28, 0x23, 0xdb, 0x0a, 0xcb, 0x47, 
 401    0168  08        		.byte	8
 402    0169  C1        		.byte	193
 403    016A  C9        		.byte	201
 404    016B  C5        		.byte	197
 405    016C  D5        		.byte	213
 406    016D  11        		.byte	17
 407    016E  28        		.byte	40
 408    016F  23        		.byte	35
 409    0170  DB        		.byte	219
 410    0171  0A        		.byte	10
 411    0172  CB        		.byte	203
 412    0173  47        		.byte	71
 413                    	;   39      0x20, 0x09, 0x1b, 0x7a, 0xb3, 0x20, 0xf5, 0x10, 0xf3, 0x18, 0x07, 0xdb, 
 414    0174  20        		.byte	32
 415    0175  09        		.byte	9
 416    0176  1B        		.byte	27
 417    0177  7A        		.byte	122
 418    0178  B3        		.byte	179
 419    0179  20        		.byte	32
 420    017A  F5        		.byte	245
 421    017B  10        		.byte	16
 422    017C  F3        		.byte	243
 423    017D  18        		.byte	24
 424    017E  07        		.byte	7
 425    017F  DB        		.byte	219
 426                    	;   40      0x08, 0xd1, 0xc1, 0x37, 0x3f, 0xc9, 0x3e, 0x00, 0xd1, 0xc1, 0x37, 0xc9, 
 427    0180  08        		.byte	8
 428    0181  D1        		.byte	209
 429    0182  C1        		.byte	193
 430    0183  37        		.byte	55
 431    0184  3F        		.byte	63
 432    0185  C9        		.byte	201
 433    0186  3E        		.byte	62
 434                    		.byte	[1]
 435    0188  D1        		.byte	209
 436    0189  C1        		.byte	193
 437    018A  37        		.byte	55
 438    018B  C9        		.byte	201
 439                    	;   41      0xc5, 0xdb, 0x0a, 0xcb, 0x47, 0x28, 0x04, 0xdb, 0x08, 0xc1, 0xc9, 0x3e, 
 440    018C  C5        		.byte	197
 441    018D  DB        		.byte	219
 442    018E  0A        		.byte	10
 443    018F  CB        		.byte	203
 444    0190  47        		.byte	71
 445    0191  28        		.byte	40
 446    0192  04        		.byte	4
 447    0193  DB        		.byte	219
 448    0194  08        		.byte	8
 449    0195  C1        		.byte	193
 450    0196  C9        		.byte	201
 451    0197  3E        		.byte	62
 452                    	;   42      0x00, 0xc1, 0xc9, 0xf5, 0xe5, 0x7e, 0xfe, 0x00, 0x28, 0x06, 0xcd, 0x59, 
 453                    		.byte	[1]
 454    0199  C1        		.byte	193
 455    019A  C9        		.byte	201
 456    019B  F5        		.byte	245
 457    019C  E5        		.byte	229
 458    019D  7E        		.byte	126
 459    019E  FE        		.byte	254
 460                    		.byte	[1]
 461    01A0  28        		.byte	40
 462    01A1  06        		.byte	6
 463    01A2  CD        		.byte	205
 464    01A3  59        		.byte	89
 465                    	;   43      0xb1, 0x23, 0x18, 0xf5, 0xe1, 0xf1, 0xc9, 0x00, 0x00, 0x00, 0x00, 0x00, 
 466    01A4  B1        		.byte	177
 467    01A5  23        		.byte	35
 468    01A6  18        		.byte	24
 469    01A7  F5        		.byte	245
 470    01A8  E1        		.byte	225
 471    01A9  F1        		.byte	241
 472    01AA  C9        		.byte	201
 473                    		.byte	[1]
 474                    		.byte	[1]
 475                    		.byte	[1]
 476                    		.byte	[1]
 477                    		.byte	[1]
 478                    	;   44      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 479                    		.byte	[1]
 480                    		.byte	[1]
 481                    		.byte	[1]
 482                    		.byte	[1]
 483                    		.byte	[1]
 484                    		.byte	[1]
 485                    		.byte	[1]
 486                    		.byte	[1]
 487                    		.byte	[1]
 488                    		.byte	[1]
 489                    		.byte	[1]
 490                    		.byte	[1]
 491                    	;   45      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 492                    		.byte	[1]
 493                    		.byte	[1]
 494                    		.byte	[1]
 495                    		.byte	[1]
 496                    		.byte	[1]
 497                    		.byte	[1]
 498                    		.byte	[1]
 499                    		.byte	[1]
 500                    		.byte	[1]
 501                    		.byte	[1]
 502                    		.byte	[1]
 503                    		.byte	[1]
 504                    	;   46      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 505                    		.byte	[1]
 506                    		.byte	[1]
 507                    		.byte	[1]
 508                    		.byte	[1]
 509                    		.byte	[1]
 510                    		.byte	[1]
 511                    		.byte	[1]
 512                    		.byte	[1]
 513                    		.byte	[1]
 514                    		.byte	[1]
 515                    		.byte	[1]
 516                    		.byte	[1]
 517                    	;   47      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 518                    		.byte	[1]
 519                    		.byte	[1]
 520                    		.byte	[1]
 521                    		.byte	[1]
 522                    		.byte	[1]
 523                    		.byte	[1]
 524                    		.byte	[1]
 525                    		.byte	[1]
 526                    		.byte	[1]
 527                    		.byte	[1]
 528                    		.byte	[1]
 529                    		.byte	[1]
 530                    	;   48      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 531                    		.byte	[1]
 532                    		.byte	[1]
 533                    		.byte	[1]
 534                    		.byte	[1]
 535                    		.byte	[1]
 536                    		.byte	[1]
 537                    		.byte	[1]
 538                    		.byte	[1]
 539                    		.byte	[1]
 540                    		.byte	[1]
 541                    		.byte	[1]
 542                    		.byte	[1]
 543                    	;   49      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 544                    		.byte	[1]
 545                    		.byte	[1]
 546                    		.byte	[1]
 547                    		.byte	[1]
 548                    		.byte	[1]
 549                    		.byte	[1]
 550                    		.byte	[1]
 551                    		.byte	[1]
 552                    		.byte	[1]
 553                    		.byte	[1]
 554                    		.byte	[1]
 555                    		.byte	[1]
 556                    	;   50      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 557                    		.byte	[1]
 558                    		.byte	[1]
 559                    		.byte	[1]
 560                    		.byte	[1]
 561                    		.byte	[1]
 562                    		.byte	[1]
 563                    		.byte	[1]
 564                    		.byte	[1]
 565                    		.byte	[1]
 566                    		.byte	[1]
 567                    		.byte	[1]
 568                    		.byte	[1]
 569                    	;   51      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 570                    		.byte	[1]
 571                    		.byte	[1]
 572                    		.byte	[1]
 573                    		.byte	[1]
 574                    		.byte	[1]
 575                    		.byte	[1]
 576                    		.byte	[1]
 577                    		.byte	[1]
 578                    		.byte	[1]
 579                    		.byte	[1]
 580                    		.byte	[1]
 581                    		.byte	[1]
 582                    	;   52      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 583                    		.byte	[1]
 584                    		.byte	[1]
 585                    		.byte	[1]
 586                    		.byte	[1]
 587                    		.byte	[1]
 588                    		.byte	[1]
 589                    		.byte	[1]
 590                    		.byte	[1]
 591                    		.byte	[1]
 592                    		.byte	[1]
 593                    		.byte	[1]
 594                    		.byte	[1]
 595                    	;   53      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 596                    		.byte	[1]
 597                    		.byte	[1]
 598                    		.byte	[1]
 599                    		.byte	[1]
 600                    		.byte	[1]
 601                    		.byte	[1]
 602                    		.byte	[1]
 603                    		.byte	[1]
 604                    		.byte	[1]
 605                    		.byte	[1]
 606                    		.byte	[1]
 607                    		.byte	[1]
 608                    	;   54      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, };
 609                    		.byte	[1]
 610                    		.byte	[1]
 611                    		.byte	[1]
 612                    		.byte	[1]
 613                    		.byte	[1]
 614                    		.byte	[1]
 615                    		.byte	[1]
 616                    		.byte	[1]
 617                    		.byte	[1]
 618                    		.byte	[1]
 619                    	;   55  const unsigned int upload_size = 562;
 620                    	_upload_size:
 621    0232  3202      		.word	562
 622                    		.public	_upload_size
 623                    		.public	_upload
 624                    		.end
