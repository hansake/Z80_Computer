   1                    	;    1  /* z80cio.c
   2                    	;    2   *
   3                    	;    3   * I/O routines for my DIY Z80 Computer.
   4                    	;    4   * The program compiled with Whitesmiths/COSMIC
   5                    	;    5   * C compiler for Z80.
   6                    	;    6   *
   7                    	;    7   * You are free to use, modify, and redistribute
   8                    	;    8   * this source code. No warranties given.
   9                    	;    9   * Hastily Cobbled Together 2021 and 2022
  10                    	;   10   * by Hans-Ake Lund
  11                    	;   11   *
  12                    	;   12   */
  13                    	;   13  
  14                    	;   14  #include <std.h>
  15                    	;   15  #include "z80computer.h"
  16                    		.psect	_text
  17                    	L5:
  18    0000  0A        		.byte	10
  19    0001  3D        		.byte	61
  20    0002  3D        		.byte	61
  21    0003  3D        		.byte	61
  22    0004  3D        		.byte	61
  23    0005  3D        		.byte	61
  24    0006  3D        		.byte	61
  25    0007  3D        		.byte	61
  26    0008  3D        		.byte	61
  27    0009  3D        		.byte	61
  28    000A  3D        		.byte	61
  29    000B  3D        		.byte	61
  30    000C  3D        		.byte	61
  31    000D  3D        		.byte	61
  32    000E  3D        		.byte	61
  33    000F  3D        		.byte	61
  34    0010  3D        		.byte	61
  35    0011  3D        		.byte	61
  36    0012  3D        		.byte	61
  37    0013  3D        		.byte	61
  38    0014  3D        		.byte	61
  39    0015  3D        		.byte	61
  40    0016  3D        		.byte	61
  41    0017  3D        		.byte	61
  42    0018  3D        		.byte	61
  43    0019  3D        		.byte	61
  44    001A  3D        		.byte	61
  45    001B  3D        		.byte	61
  46    001C  3D        		.byte	61
  47    001D  3D        		.byte	61
  48    001E  3D        		.byte	61
  49    001F  3D        		.byte	61
  50    0020  3D        		.byte	61
  51    0021  3D        		.byte	61
  52    0022  0A        		.byte	10
  53    0023  00        		.byte	0
  54                    	L51:
  55    0024  5A        		.byte	90
  56    0025  38        		.byte	56
  57    0026  30        		.byte	48
  58    0027  20        		.byte	32
  59    0028  43        		.byte	67
  60    0029  6F        		.byte	111
  61    002A  6D        		.byte	109
  62    002B  70        		.byte	112
  63    002C  75        		.byte	117
  64    002D  74        		.byte	116
  65    002E  65        		.byte	101
  66    002F  72        		.byte	114
  67    0030  20        		.byte	32
  68    0031  68        		.byte	104
  69    0032  61        		.byte	97
  70    0033  72        		.byte	114
  71    0034  64        		.byte	100
  72    0035  77        		.byte	119
  73    0036  61        		.byte	97
  74    0037  72        		.byte	114
  75    0038  65        		.byte	101
  76    0039  20        		.byte	32
  77    003A  69        		.byte	105
  78    003B  6E        		.byte	110
  79    003C  69        		.byte	105
  80    003D  74        		.byte	116
  81    003E  69        		.byte	105
  82    003F  61        		.byte	97
  83    0040  6C        		.byte	108
  84    0041  69        		.byte	105
  85    0042  7A        		.byte	122
  86    0043  65        		.byte	101
  87    0044  64        		.byte	100
  88    0045  0A        		.byte	10
  89    0046  00        		.byte	0
  90                    	;   16  
  91                    	;   17  /* Initialize hardware */
  92                    	;   18  void hwinit()
  93                    	;   19      {
  94                    	_hwinit:
  95                    	;   20      ledon();
  96    0047  CDA302    		call	_ledon
  97                    	;   21      ctc_init();
  98    004A  CD6300    		call	_ctc_init
  99                    	;   22      sio_init();
 100    004D  CDA500    		call	_sio_init
 101                    	;   23      pio_init();
 102    0050  CD5001    		call	_pio_init
 103                    	;   24      printf("\n=================================\n");
 104    0053  210000    		ld	hl,L5
 105    0056  CD0000    		call	_printf
 106                    	;   25      printf("Z80 Computer hardware initialized\n");
 107    0059  212400    		ld	hl,L51
 108    005C  CD0000    		call	_printf
 109                    	;   26      ledoff();
 110    005F  CDAF02    		call	_ledoff
 111                    	;   27      }
 112    0062  C9        		ret 
 113                    	;   28  
 114                    	;   29  /* ctc_init()
 115                    	;   30  ; Divide constant in CTC to get an approximate baudrate of 9600
 116                    	;   31  ; To get 9600 baud with a 4MHz xtal oscillator the divide constant
 117                    	;   32  ; should be 4000000/(9600*2*16) = 13.0208
 118                    	;   33  ; Using the CTC divider constant set to 13 will give a baud-rate
 119                    	;   34  ; of 4000000/(2*16*13) = 9615 baud which hopefully is close enough.
 120                    	;   35  ; This is tested and works with a 9600 baudrate connection to a Linux PC.
 121                    	;   36  ;
 122                    	;   37  ; (If this is not exact enough, another xtal oscillator must be selected,
 123                    	;   38  ; it should have the frequency: 3.6864 MHz
 124                    	;   39  ; The divide constant will then be set to 12 which gives the baudrate
 125                    	;   40  ; of 3686400/(2*16*12) = 9600 baud.)
 126                    	;   41  ;
 127                    	;   42  ; ctc_init: initializes the CTC channel 0 for baudrate clock to SIO/0
 128                    	;   43  ; initializes also CTC channels 1, 2 and 3
 129                    	;   44  ; input TRG0-2 is supplied by the BCLK signal which is the system clock
 130                    	;   45  ; divided by 2 by the ATF22V10C
 131                    	;   46  */
 132                    	;   47  #define BAUDDIV 13
 133                    	;   48  
 134                    	;   49  void ctc_init()
 135                    	;   50      {
 136                    	_ctc_init:
 137                    	;   51      /* CTC chan 0 */
 138                    	;   52      /* 01000111b        ; int off, counter mode, prescaler don't care,
 139                    	;   53                  ; falling edge, time trigger don't care,
 140                    	;   54                  ; time constant follows, sw reset,
 141                    	;   55                  ; this is a ctrl cmd
 142                    	;   56       */
 143                    	;   57      out(CTC_CH0, 0x47);
 144    0063  214700    		ld	hl,71
 145    0066  E5        		push	hl
 146    0067  210C00    		ld	hl,12
 147    006A  CD0000    		call	_out
 148    006D  F1        		pop	af
 149                    	;   58      out(CTC_CH0, BAUDDIV);
 150    006E  210D00    		ld	hl,13
 151    0071  E5        		push	hl
 152    0072  210C00    		ld	hl,12
 153    0075  CD0000    		call	_out
 154    0078  F1        		pop	af
 155                    	;   59      /* Interupt vector will be written to chan 0 */
 156                    	;   60  
 157                    	;   61      /* CTC chan 1, not used but generating pulses */
 158                    	;   62      /* 01000111b        ; int off, counter mode, prescaler don't care,
 159                    	;   63                  ; falling edge, time trigger don't care,
 160                    	;   64                  ; time constant follows, sw reset,
 161                    	;   65                  ; this is a ctrl cmd
 162                    	;   66       */
 163                    	;   67      out(CTC_CH1, 0x47);
 164    0079  214700    		ld	hl,71
 165    007C  E5        		push	hl
 166    007D  210D00    		ld	hl,13
 167    0080  CD0000    		call	_out
 168    0083  F1        		pop	af
 169                    	;   68      out(CTC_CH1, 10); /* divide BCLK by 10 */
 170    0084  210A00    		ld	hl,10
 171    0087  E5        		push	hl
 172    0088  210D00    		ld	hl,13
 173    008B  CD0000    		call	_out
 174    008E  F1        		pop	af
 175                    	;   69  
 176                    	;   70      /* CTC chan 2,
 177                    	;   71          generating clock pulses for NMI driven SPI interface
 178                    	;   72       */
 179                    	;   73      /* 00000011b                ; sw reset, this is a ctrl cmd
 180                    	;   74       */
 181                    	;   75      out(CTC_CH2, 0x03);
 182    008F  210300    		ld	hl,3
 183    0092  E5        		push	hl
 184    0093  210E00    		ld	hl,14
 185    0096  CD0000    		call	_out
 186    0099  F1        		pop	af
 187                    	;   76  
 188                    	;   77      /* CTC chan 3, not used yet */
 189                    	;   78  
 190                    	;   79      }
 191    009A  C9        		ret 
 192                    	;   80  
 193                    	;   81  /* sio_init() initializes the SIO/0 for serial communication
 194                    	;   82          db 00110000b            ; write to WR0: error reset
 195                    	;   83          db 00011000b            ; write to WR0: channel reset
 196                    	;   84          db 0x04, 01000100b      ; write to WR4: clkx16, 1 stop bit, no parity
 197                    	;   85          db 0x05, 01101000b      ; write to WR5: DTR inactive, enable TX 8bit,
 198                    	;   86                                  ; BREAK off, TX on, RTS inactive
 199                    	;   87          db 0x01, 00000000b      ; write to WR1: no interrupts enabled
 200                    	;   88          db 0x03, 11000001b      ; write to WR3: enable RX 8bit
 201                    	;   89   */
 202                    	;   90  const unsigned char sioregini[] = {0x30, 0x18, 0x04, 0x44, 0x05, 0x68,
 203                    	_sioregini:
 204    009B  30        		.byte	48
 205    009C  18        		.byte	24
 206    009D  04        		.byte	4
 207    009E  44        		.byte	68
 208    009F  05        		.byte	5
 209    00A0  68        		.byte	104
 210                    	;   91                                     0x01, 0x00, 0x03, 0xc1
 211    00A1  01        		.byte	1
 212                    		.byte	[1]
 213    00A3  03        		.byte	3
 214                    	;   92                                    };
 215    00A4  C1        		.byte	193
 216                    	;   93  
 217                    	;   94  void sio_init()
 218                    	;   95      {
 219                    	_sio_init:
 220    00A5  CD0000    		call	c.savs0
 221    00A8  21F4FF    		ld	hl,65524
 222    00AB  39        		add	hl,sp
 223    00AC  F9        		ld	sp,hl
 224                    	;   96      unsigned char *sioregptr;
 225                    	;   97      unsigned int port;
 226                    	;   98      int wrbytes;
 227                    	;   99  
 228                    	;  100      /* Initialize SIO port A */
 229                    	;  101      port = SIO_A_CTRL;
 230    00AD  DD36F60A  		ld	(ix-10),10
 231    00B1  DD36F700  		ld	(ix-9),0
 232                    	;  102      sioregptr = sioregini;
 233    00B5  219B00    		ld	hl,_sioregini
 234    00B8  DD75F8    		ld	(ix-8),l
 235    00BB  DD74F9    		ld	(ix-7),h
 236                    	;  103      for (wrbytes = sizeof sioregini; 0 < wrbytes; wrbytes--)
 237    00BE  DD36F40A  		ld	(ix-12),10
 238    00C2  DD36F500  		ld	(ix-11),0
 239                    	L1:
 240    00C6  97        		sub	a
 241    00C7  DD96F4    		sub	(ix-12)
 242    00CA  3E00      		ld	a,0
 243    00CC  DD9EF5    		sbc	a,(ix-11)
 244    00CF  F2FD00    		jp	p,L11
 245                    	;  104          out(port, *sioregptr++);
 246    00D2  DD6EF8    		ld	l,(ix-8)
 247    00D5  DD66F9    		ld	h,(ix-7)
 248    00D8  DD34F8    		inc	(ix-8)
 249    00DB  2003      		jr	nz,L01
 250    00DD  DD34F9    		inc	(ix-7)
 251                    	L01:
 252    00E0  6E        		ld	l,(hl)
 253    00E1  97        		sub	a
 254    00E2  67        		ld	h,a
 255    00E3  E5        		push	hl
 256    00E4  DD6EF6    		ld	l,(ix-10)
 257    00E7  DD66F7    		ld	h,(ix-9)
 258    00EA  CD0000    		call	_out
 259    00ED  F1        		pop	af
 260    00EE  DD6EF4    		ld	l,(ix-12)
 261    00F1  DD66F5    		ld	h,(ix-11)
 262    00F4  2B        		dec	hl
 263    00F5  DD75F4    		ld	(ix-12),l
 264    00F8  DD74F5    		ld	(ix-11),h
 265    00FB  18C9      		jr	L1
 266                    	L11:
 267                    	;  105  
 268                    	;  106      /* Initialize SIO port B */
 269                    	;  107      port = SIO_B_CTRL;
 270    00FD  DD36F60B  		ld	(ix-10),11
 271    0101  DD36F700  		ld	(ix-9),0
 272                    	;  108      sioregptr = sioregini;
 273    0105  219B00    		ld	hl,_sioregini
 274    0108  DD75F8    		ld	(ix-8),l
 275    010B  DD74F9    		ld	(ix-7),h
 276                    	;  109      for (wrbytes = sizeof sioregini; 0 < wrbytes; wrbytes--)
 277    010E  DD36F40A  		ld	(ix-12),10
 278    0112  DD36F500  		ld	(ix-11),0
 279                    	L14:
 280    0116  97        		sub	a
 281    0117  DD96F4    		sub	(ix-12)
 282    011A  3E00      		ld	a,0
 283    011C  DD9EF5    		sbc	a,(ix-11)
 284    011F  F24D01    		jp	p,L15
 285                    	;  110          out(port, *sioregptr++);
 286    0122  DD6EF8    		ld	l,(ix-8)
 287    0125  DD66F9    		ld	h,(ix-7)
 288    0128  DD34F8    		inc	(ix-8)
 289    012B  2003      		jr	nz,L21
 290    012D  DD34F9    		inc	(ix-7)
 291                    	L21:
 292    0130  6E        		ld	l,(hl)
 293    0131  97        		sub	a
 294    0132  67        		ld	h,a
 295    0133  E5        		push	hl
 296    0134  DD6EF6    		ld	l,(ix-10)
 297    0137  DD66F7    		ld	h,(ix-9)
 298    013A  CD0000    		call	_out
 299    013D  F1        		pop	af
 300    013E  DD6EF4    		ld	l,(ix-12)
 301    0141  DD66F5    		ld	h,(ix-11)
 302    0144  2B        		dec	hl
 303    0145  DD75F4    		ld	(ix-12),l
 304    0148  DD74F5    		ld	(ix-11),h
 305    014B  18C9      		jr	L14
 306                    	L15:
 307                    	;  111      }
 308    014D  C30000    		jp	c.rets0
 309                    	;  112  
 310                    	;  113  /* pio_init() initialize PIO channel A and B
 311                    	;  114   */
 312                    	;  115  void pio_init()
 313                    	;  116      {
 314                    	_pio_init:
 315                    	;  117      /* PIO A */
 316                    	;  118  
 317                    	;  119      /* 00001111b                ; mode 0 */
 318                    	;  120      out(PIO_A_CTRL, 0x0f);
 319    0150  210F00    		ld	hl,15
 320    0153  E5        		push	hl
 321    0154  211200    		ld	hl,18
 322    0157  CD0000    		call	_out
 323    015A  F1        		pop	af
 324                    	;  121  
 325                    	;  122      /* 00000111b                ; int disable */
 326                    	;  123      out(PIO_A_CTRL, 0x07);
 327    015B  210700    		ld	hl,7
 328    015E  E5        		push	hl
 329    015F  211200    		ld	hl,18
 330    0162  CD0000    		call	_out
 331    0165  F1        		pop	af
 332                    	;  124  
 333                    	;  125      /* PIO B, SPI interface */
 334                    	;  126      /* 11001111b                ; mode 3 */
 335                    	;  127      out(PIO_B_CTRL, 0xcf);
 336    0166  21CF00    		ld	hl,207
 337    0169  E5        		push	hl
 338    016A  211300    		ld	hl,19
 339    016D  CD0000    		call	_out
 340    0170  F1        		pop	af
 341                    	;  128  
 342                    	;  129      /* 00000001b                ; i/o mask
 343                    	;  130      ;bit 0: MISO - input     3                   3
 344                    	;  131      ;bit 1: MOSI - output    4                   5
 345                    	;  132      ;bit 2: SCK  - output    5                   7
 346                    	;  133      ;bit 3: /CS0 - output    6                   9
 347                    	;  134      ;bit 4: /CS1 - output  extra device select  11
 348                    	;  135      ;bit 5: /CS2 - output  extra device select  10
 349                    	;  136      ;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
 350                    	;  137      ;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
 351                    	;  138      ;                                                with an 8 bit transmit or receive transfer
 352                    	;  139      */
 353                    	;  140      out(PIO_B_CTRL, 0x01);
 354    0171  210100    		ld	hl,1
 355    0174  E5        		push	hl
 356    0175  211300    		ld	hl,19
 357    0178  CD0000    		call	_out
 358    017B  F1        		pop	af
 359                    	;  141  
 360                    	;  142      /* 00000111b                ; int disable */
 361                    	;  143      out(PIO_B_CTRL, 0x07);
 362    017C  210700    		ld	hl,7
 363    017F  E5        		push	hl
 364    0180  211300    		ld	hl,19
 365    0183  CD0000    		call	_out
 366    0186  F1        		pop	af
 367                    	;  144  
 368                    	;  145      /* 00111010b                ;initialize output bits
 369                    	;  146      ; bit 1: MOSI - output      ;low
 370                    	;  147      ; bit 2: SCK  - output      ;low
 371                    	;  148      ; bit 3: /CS0 - output      ;high = not selected
 372                    	;  149      ; bit 4: /CS1 - output      ;high = not selected
 373                    	;  150      ; bit 5: /CS2 - output      ;high = not selected
 374                    	;  151      ; bit 6: TP1  - output  ;low
 375                    	;  152      ; bit 7: TRA  - output  ;low
 376                    	;  153      */
 377                    	;  154      out(PIO_B_DATA, 0x3a);
 378    0187  213A00    		ld	hl,58
 379    018A  E5        		push	hl
 380    018B  211100    		ld	hl,17
 381    018E  CD0000    		call	_out
 382    0191  F1        		pop	af
 383                    	;  155      }
 384    0192  C9        		ret 
 385                    	;  156  
 386                    	;  157  /* Print character on serial port A */
 387                    	;  158  int putchar(char pchar)
 388                    	;  159      {
 389                    	_putchar:
 390    0193  CD0000    		call	c.savs
 391                    	L101:
 392                    	;  160      while ((in(SIO_A_CTRL) & 0x04) == 0) /* wait for tx buffer empty */
 393    0196  210A00    		ld	hl,10
 394    0199  CD0000    		call	_in
 395    019C  CB51      		bit	2,c
 396    019E  28F6      		jr	z,L101
 397                    	;  161          ;
 398                    	;  162      out(SIO_A_DATA, pchar);
 399    01A0  DD6E04    		ld	l,(ix+4)
 400    01A3  DD6605    		ld	h,(ix+5)
 401    01A6  E5        		push	hl
 402    01A7  210800    		ld	hl,8
 403    01AA  CD0000    		call	_out
 404    01AD  F1        		pop	af
 405                    	;  163      if (pchar == '\n')
 406    01AE  DD7E04    		ld	a,(ix+4)
 407    01B1  FE0A      		cp	10
 408    01B3  2005      		jr	nz,L02
 409    01B5  DD7E05    		ld	a,(ix+5)
 410    01B8  FE00      		cp	0
 411                    	L02:
 412    01BA  2006      		jr	nz,L121
 413                    	;  164          putchar('\r');
 414    01BC  210D00    		ld	hl,13
 415    01BF  CD9301    		call	_putchar
 416                    	L121:
 417                    	;  165      return (pchar);
 418    01C2  DD4E04    		ld	c,(ix+4)
 419    01C5  DD4605    		ld	b,(ix+5)
 420    01C8  C30000    		jp	c.rets
 421                    	;  166      }
 422                    	;  167  
 423                    	;  168  /* Get character from serial port A */
 424                    	;  169  int getchar()
 425                    	;  170      {
 426                    	_getchar:
 427                    	L131:
 428                    	;  171      while (!(in(SIO_A_CTRL) & 0x01)) /* test and loop until character available */
 429    01CB  210A00    		ld	hl,10
 430    01CE  CD0000    		call	_in
 431    01D1  CB41      		bit	0,c
 432    01D3  28F6      		jr	z,L131
 433                    	;  172          ;
 434                    	;  173      return (in(SIO_A_DATA));
 435    01D5  210800    		ld	hl,8
 436    01D8  CD0000    		call	_in
 437    01DB  C9        		ret 
 438                    	;  174      }
 439                    	;  175  
 440                    	;  176  /* Get line from keyboard
 441                    	;  177   * edit line with BS
 442                    	;  178   * returns when CR or Ctrl-C is entered
 443                    	;  179   * return value is length of entered string
 444                    	;  180   */
 445                    	;  181  int getkline(char *txtinp, int bufsize)
 446                    	;  182      {
 447                    	_getkline:
 448    01DC  CD0000    		call	c.savs
 449    01DF  21F7FF    		ld	hl,65527
 450    01E2  39        		add	hl,sp
 451    01E3  F9        		ld	sp,hl
 452                    	;  183      int ncharin;
 453                    	;  184      char charin;
 454                    	;  185  
 455                    	;  186      for (ncharin = 0; ncharin < (bufsize - 1); ncharin++)
 456    01E4  DD36F800  		ld	(ix-8),0
 457    01E8  DD36F900  		ld	(ix-7),0
 458                    	L151:
 459    01EC  DD6E06    		ld	l,(ix+6)
 460    01EF  DD6607    		ld	h,(ix+7)
 461    01F2  01FFFF    		ld	bc,65535
 462    01F5  09        		add	hl,bc
 463    01F6  DD7EF8    		ld	a,(ix-8)
 464    01F9  95        		sub	l
 465    01FA  DD7EF9    		ld	a,(ix-7)
 466    01FD  9C        		sbc	a,h
 467    01FE  F29202    		jp	p,L161
 468                    	;  187          {
 469                    	;  188          charin = getchar();
 470    0201  CDCB01    		call	_getchar
 471    0204  DD71F7    		ld	(ix-9),c
 472                    	;  189          if (charin == '\r') /* CR */
 473    0207  DD7EF7    		ld	a,(ix-9)
 474    020A  FE0D      		cp	13
 475    020C  2011      		jr	nz,L112
 476                    	;  190              {
 477                    	;  191              *txtinp = 0;
 478    020E  DD6E04    		ld	l,(ix+4)
 479    0211  DD6605    		ld	h,(ix+5)
 480    0214  3600      		ld	(hl),0
 481                    	;  192              return (ncharin);
 482    0216  DD4EF8    		ld	c,(ix-8)
 483    0219  DD46F9    		ld	b,(ix-7)
 484    021C  C30000    		jp	c.rets
 485                    	L112:
 486                    	;  193              }
 487                    	;  194          else if (charin == 3) /* Ctrl-C */
 488    021F  DD7EF7    		ld	a,(ix-9)
 489    0222  FE03      		cp	3
 490    0224  2006      		jr	nz,L132
 491                    	;  195              return (0);
 492    0226  010000    		ld	bc,0
 493    0229  C30000    		jp	c.rets
 494                    	L132:
 495                    	;  196          else if (charin == '\b') /* BS */
 496    022C  DD7EF7    		ld	a,(ix-9)
 497    022F  FE08      		cp	8
 498    0231  203A      		jr	nz,L152
 499                    	;  197              {
 500                    	;  198              if (0 < ncharin)
 501    0233  97        		sub	a
 502    0234  DD96F8    		sub	(ix-8)
 503    0237  3E00      		ld	a,0
 504    0239  DD9EF9    		sbc	a,(ix-7)
 505    023C  F28702    		jp	p,L171
 506                    	;  199                  {
 507                    	;  200                  putchar('\b');
 508    023F  210800    		ld	hl,8
 509    0242  CD9301    		call	_putchar
 510                    	;  201                  putchar(' ');
 511    0245  212000    		ld	hl,32
 512    0248  CD9301    		call	_putchar
 513                    	;  202                  putchar('\b');
 514    024B  210800    		ld	hl,8
 515    024E  CD9301    		call	_putchar
 516                    	;  203                  ncharin--;
 517    0251  DD6EF8    		ld	l,(ix-8)
 518    0254  DD66F9    		ld	h,(ix-7)
 519    0257  2B        		dec	hl
 520    0258  DD75F8    		ld	(ix-8),l
 521    025B  DD74F9    		ld	(ix-7),h
 522                    	;  204                  txtinp--;
 523    025E  DD6E04    		ld	l,(ix+4)
 524    0261  DD6605    		ld	h,(ix+5)
 525    0264  2B        		dec	hl
 526    0265  DD7504    		ld	(ix+4),l
 527    0268  DD7405    		ld	(ix+5),h
 528    026B  181A      		jr	L171
 529                    	L152:
 530                    	;  205                  }
 531                    	;  206              }
 532                    	;  207          else
 533                    	;  208              {
 534                    	;  209              putchar(charin);
 535    026D  DD6EF7    		ld	l,(ix-9)
 536    0270  97        		sub	a
 537    0271  67        		ld	h,a
 538    0272  CD9301    		call	_putchar
 539                    	;  210              *txtinp++ = charin;
 540    0275  DD6E04    		ld	l,(ix+4)
 541    0278  DD6605    		ld	h,(ix+5)
 542    027B  DD3404    		inc	(ix+4)
 543    027E  2003      		jr	nz,L03
 544    0280  DD3405    		inc	(ix+5)
 545                    	L03:
 546    0283  DD7EF7    		ld	a,(ix-9)
 547    0286  77        		ld	(hl),a
 548                    	L171:
 549    0287  DD34F8    		inc	(ix-8)
 550    028A  2003      		jr	nz,L62
 551    028C  DD34F9    		inc	(ix-7)
 552                    	L62:
 553    028F  C3EC01    		jp	L151
 554                    	L161:
 555                    	;  211              }
 556                    	;  212          }
 557                    	;  213      *txtinp = 0;
 558    0292  DD6E04    		ld	l,(ix+4)
 559    0295  DD6605    		ld	h,(ix+5)
 560    0298  3600      		ld	(hl),0
 561                    	;  214      return (ncharin);
 562    029A  DD4EF8    		ld	c,(ix-8)
 563    029D  DD46F9    		ld	b,(ix-7)
 564    02A0  C30000    		jp	c.rets
 565                    	;  215      }
 566                    	;  216  
 567                    	;  217  /* Status LED on */
 568                    	;  218  void ledon()
 569                    	;  219      {
 570                    	_ledon:
 571                    	;  220      out(LEDON, 1);
 572    02A3  210100    		ld	hl,1
 573    02A6  E5        		push	hl
 574    02A7  211800    		ld	hl,24
 575    02AA  CD0000    		call	_out
 576    02AD  F1        		pop	af
 577                    	;  221      }
 578    02AE  C9        		ret 
 579                    	;  222  
 580                    	;  223  /* Status LED off */
 581                    	;  224  void ledoff()
 582                    	;  225      {
 583                    	_ledoff:
 584                    	;  226      out(LEDOFF, 0);
 585    02AF  210000    		ld	hl,0
 586    02B2  E5        		push	hl
 587    02B3  211400    		ld	hl,20
 588    02B6  CD0000    		call	_out
 589    02B9  F1        		pop	af
 590                    	;  227      }
 591    02BA  C9        		ret 
 592                    	;  228  
 593                    		.external	c.rets0
 594                    		.external	c.savs0
 595                    		.public	_getchar
 596                    		.public	_sio_init
 597                    		.public	_pio_init
 598                    		.external	_out
 599                    		.external	_in
 600                    		.public	_getkline
 601                    		.external	_printf
 602                    		.public	_hwinit
 603                    		.public	_ledon
 604                    		.public	_ctc_init
 605                    		.public	_sioregini
 606                    		.public	_putchar
 607                    		.external	c.rets
 608                    		.public	_ledoff
 609                    		.external	c.savs
 610                    		.end
