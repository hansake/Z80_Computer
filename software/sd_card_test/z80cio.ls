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
  18    0000  5A        		.byte	90
  19    0001  38        		.byte	56
  20    0002  30        		.byte	48
  21    0003  20        		.byte	32
  22    0004  43        		.byte	67
  23    0005  6F        		.byte	111
  24    0006  6D        		.byte	109
  25    0007  70        		.byte	112
  26    0008  75        		.byte	117
  27    0009  74        		.byte	116
  28    000A  65        		.byte	101
  29    000B  72        		.byte	114
  30    000C  20        		.byte	32
  31    000D  68        		.byte	104
  32    000E  61        		.byte	97
  33    000F  72        		.byte	114
  34    0010  64        		.byte	100
  35    0011  77        		.byte	119
  36    0012  61        		.byte	97
  37    0013  72        		.byte	114
  38    0014  65        		.byte	101
  39    0015  20        		.byte	32
  40    0016  69        		.byte	105
  41    0017  6E        		.byte	110
  42    0018  69        		.byte	105
  43    0019  74        		.byte	116
  44    001A  69        		.byte	105
  45    001B  61        		.byte	97
  46    001C  6C        		.byte	108
  47    001D  69        		.byte	105
  48    001E  7A        		.byte	122
  49    001F  65        		.byte	101
  50    0020  64        		.byte	100
  51    0021  0A        		.byte	10
  52    0022  00        		.byte	0
  53                    	;   16  
  54                    	;   17  /* Initialize hardware */
  55                    	;   18  void hwinit()
  56                    	;   19      {
  57                    	_hwinit:
  58                    	;   20      ledon();
  59    0023  CD7902    		call	_ledon
  60                    	;   21      ctc_init();
  61    0026  CD3900    		call	_ctc_init
  62                    	;   22      sio_init();
  63    0029  CD7B00    		call	_sio_init
  64                    	;   23      pio_init();
  65    002C  CD2601    		call	_pio_init
  66                    	;   24      printf("Z80 Computer hardware initialized\n");
  67    002F  210000    		ld	hl,L5
  68    0032  CD0000    		call	_printf
  69                    	;   25      ledoff();
  70    0035  CD8502    		call	_ledoff
  71                    	;   26      }
  72    0038  C9        		ret 
  73                    	;   27  
  74                    	;   28  /* ctc_init()
  75                    	;   29  ; Divide constant in CTC to get an approximate baudrate of 9600
  76                    	;   30  ; To get 9600 baud with a 4MHz xtal oscillator the divide constant
  77                    	;   31  ; should be 4000000/(9600*2*16) = 13.0208
  78                    	;   32  ; Using the CTC divider constant set to 13 will give a baud-rate
  79                    	;   33  ; of 4000000/(2*16*13) = 9615 baud which hopefully is close enough.
  80                    	;   34  ; This is tested and works with a 9600 baudrate connection to a Linux PC.
  81                    	;   35  ;
  82                    	;   36  ; (If this is not exact enough, another xtal oscillator must be selected,
  83                    	;   37  ; it should have the frequency: 3.6864 MHz
  84                    	;   38  ; The divide constant will then be set to 12 which gives the baudrate
  85                    	;   39  ; of 3686400/(2*16*12) = 9600 baud.)
  86                    	;   40  ;
  87                    	;   41  ; ctc_init: initializes the CTC channel 0 for baudrate clock to SIO/0
  88                    	;   42  ; initializes also CTC channels 1, 2 and 3
  89                    	;   43  ; input TRG0-2 is supplied by the BCLK signal which is the system clock
  90                    	;   44  ; divided by 2 by the ATF22V10C
  91                    	;   45  */
  92                    	;   46  #define BAUDDIV 13
  93                    	;   47  
  94                    	;   48  void ctc_init()
  95                    	;   49      {
  96                    	_ctc_init:
  97                    	;   50      /* CTC chan 0 */
  98                    	;   51      /* 01000111b        ; int off, counter mode, prescaler don't care,
  99                    	;   52                  ; falling edge, time trigger don't care,
 100                    	;   53                  ; time constant follows, sw reset,
 101                    	;   54                  ; this is a ctrl cmd
 102                    	;   55       */
 103                    	;   56      out(CTC_CH0, 0x47);
 104    0039  214700    		ld	hl,71
 105    003C  E5        		push	hl
 106    003D  210C00    		ld	hl,12
 107    0040  CD0000    		call	_out
 108    0043  F1        		pop	af
 109                    	;   57      out(CTC_CH0, BAUDDIV);
 110    0044  210D00    		ld	hl,13
 111    0047  E5        		push	hl
 112    0048  210C00    		ld	hl,12
 113    004B  CD0000    		call	_out
 114    004E  F1        		pop	af
 115                    	;   58      /* Interupt vector will be written to chan 0 */
 116                    	;   59  
 117                    	;   60      /* CTC chan 1, not used but generating pulses */
 118                    	;   61      /* 01000111b        ; int off, counter mode, prescaler don't care,
 119                    	;   62                  ; falling edge, time trigger don't care,
 120                    	;   63                  ; time constant follows, sw reset,
 121                    	;   64                  ; this is a ctrl cmd
 122                    	;   65       */
 123                    	;   66      out(CTC_CH1, 0x47);
 124    004F  214700    		ld	hl,71
 125    0052  E5        		push	hl
 126    0053  210D00    		ld	hl,13
 127    0056  CD0000    		call	_out
 128    0059  F1        		pop	af
 129                    	;   67      out(CTC_CH1, 10); /* divide BCLK by 10 */
 130    005A  210A00    		ld	hl,10
 131    005D  E5        		push	hl
 132    005E  210D00    		ld	hl,13
 133    0061  CD0000    		call	_out
 134    0064  F1        		pop	af
 135                    	;   68  
 136                    	;   69      /* CTC chan 2,
 137                    	;   70          generating clock pulses for NMI driven SPI interface
 138                    	;   71       */
 139                    	;   72      /* 00000011b                ; sw reset, this is a ctrl cmd
 140                    	;   73       */
 141                    	;   74      out(CTC_CH2, 0x03);
 142    0065  210300    		ld	hl,3
 143    0068  E5        		push	hl
 144    0069  210E00    		ld	hl,14
 145    006C  CD0000    		call	_out
 146    006F  F1        		pop	af
 147                    	;   75  
 148                    	;   76      /* CTC chan 3, not used yet */
 149                    	;   77  
 150                    	;   78      }
 151    0070  C9        		ret 
 152                    	;   79  
 153                    	;   80  /* sio_init() initializes the SIO/0 for serial communication
 154                    	;   81          db 00110000b            ; write to WR0: error reset
 155                    	;   82          db 00011000b            ; write to WR0: channel reset
 156                    	;   83          db 0x04, 01000100b      ; write to WR4: clkx16, 1 stop bit, no parity
 157                    	;   84          db 0x05, 01101000b      ; write to WR5: DTR inactive, enable TX 8bit,
 158                    	;   85                                  ; BREAK off, TX on, RTS inactive
 159                    	;   86          db 0x01, 00000000b      ; write to WR1: no interrupts enabled
 160                    	;   87          db 0x03, 11000001b      ; write to WR3: enable RX 8bit
 161                    	;   88   */
 162                    	;   89  const unsigned char sioregini[] = {0x30, 0x18, 0x04, 0x44, 0x05, 0x68,
 163                    	_sioregini:
 164    0071  30        		.byte	48
 165    0072  18        		.byte	24
 166    0073  04        		.byte	4
 167    0074  44        		.byte	68
 168    0075  05        		.byte	5
 169    0076  68        		.byte	104
 170                    	;   90                                     0x01, 0x00, 0x03, 0xc1
 171    0077  01        		.byte	1
 172                    		.byte	[1]
 173    0079  03        		.byte	3
 174                    	;   91                                    };
 175    007A  C1        		.byte	193
 176                    	;   92  
 177                    	;   93  void sio_init()
 178                    	;   94      {
 179                    	_sio_init:
 180    007B  CD0000    		call	c.savs0
 181    007E  21F4FF    		ld	hl,65524
 182    0081  39        		add	hl,sp
 183    0082  F9        		ld	sp,hl
 184                    	;   95      unsigned char *sioregptr;
 185                    	;   96      unsigned int port;
 186                    	;   97      int wrbytes;
 187                    	;   98  
 188                    	;   99      /* Initialize SIO port A */
 189                    	;  100      port = SIO_A_CTRL;
 190    0083  DD36F60A  		ld	(ix-10),10
 191    0087  DD36F700  		ld	(ix-9),0
 192                    	;  101      sioregptr = sioregini;
 193    008B  217100    		ld	hl,_sioregini
 194    008E  DD75F8    		ld	(ix-8),l
 195    0091  DD74F9    		ld	(ix-7),h
 196                    	;  102      for (wrbytes = sizeof sioregini; 0 < wrbytes; wrbytes--)
 197    0094  DD36F40A  		ld	(ix-12),10
 198    0098  DD36F500  		ld	(ix-11),0
 199                    	L1:
 200    009C  97        		sub	a
 201    009D  DD96F4    		sub	(ix-12)
 202    00A0  3E00      		ld	a,0
 203    00A2  DD9EF5    		sbc	a,(ix-11)
 204    00A5  F2D300    		jp	p,L11
 205                    	;  103          out(port, *sioregptr++);
 206    00A8  DD6EF8    		ld	l,(ix-8)
 207    00AB  DD66F9    		ld	h,(ix-7)
 208    00AE  DD34F8    		inc	(ix-8)
 209    00B1  2003      		jr	nz,L01
 210    00B3  DD34F9    		inc	(ix-7)
 211                    	L01:
 212    00B6  6E        		ld	l,(hl)
 213    00B7  97        		sub	a
 214    00B8  67        		ld	h,a
 215    00B9  E5        		push	hl
 216    00BA  DD6EF6    		ld	l,(ix-10)
 217    00BD  DD66F7    		ld	h,(ix-9)
 218    00C0  CD0000    		call	_out
 219    00C3  F1        		pop	af
 220    00C4  DD6EF4    		ld	l,(ix-12)
 221    00C7  DD66F5    		ld	h,(ix-11)
 222    00CA  2B        		dec	hl
 223    00CB  DD75F4    		ld	(ix-12),l
 224    00CE  DD74F5    		ld	(ix-11),h
 225    00D1  18C9      		jr	L1
 226                    	L11:
 227                    	;  104  
 228                    	;  105      /* Initialize SIO port B */
 229                    	;  106      port = SIO_B_CTRL;
 230    00D3  DD36F60B  		ld	(ix-10),11
 231    00D7  DD36F700  		ld	(ix-9),0
 232                    	;  107      sioregptr = sioregini;
 233    00DB  217100    		ld	hl,_sioregini
 234    00DE  DD75F8    		ld	(ix-8),l
 235    00E1  DD74F9    		ld	(ix-7),h
 236                    	;  108      for (wrbytes = sizeof sioregini; 0 < wrbytes; wrbytes--)
 237    00E4  DD36F40A  		ld	(ix-12),10
 238    00E8  DD36F500  		ld	(ix-11),0
 239                    	L14:
 240    00EC  97        		sub	a
 241    00ED  DD96F4    		sub	(ix-12)
 242    00F0  3E00      		ld	a,0
 243    00F2  DD9EF5    		sbc	a,(ix-11)
 244    00F5  F22301    		jp	p,L15
 245                    	;  109          out(port, *sioregptr++);
 246    00F8  DD6EF8    		ld	l,(ix-8)
 247    00FB  DD66F9    		ld	h,(ix-7)
 248    00FE  DD34F8    		inc	(ix-8)
 249    0101  2003      		jr	nz,L21
 250    0103  DD34F9    		inc	(ix-7)
 251                    	L21:
 252    0106  6E        		ld	l,(hl)
 253    0107  97        		sub	a
 254    0108  67        		ld	h,a
 255    0109  E5        		push	hl
 256    010A  DD6EF6    		ld	l,(ix-10)
 257    010D  DD66F7    		ld	h,(ix-9)
 258    0110  CD0000    		call	_out
 259    0113  F1        		pop	af
 260    0114  DD6EF4    		ld	l,(ix-12)
 261    0117  DD66F5    		ld	h,(ix-11)
 262    011A  2B        		dec	hl
 263    011B  DD75F4    		ld	(ix-12),l
 264    011E  DD74F5    		ld	(ix-11),h
 265    0121  18C9      		jr	L14
 266                    	L15:
 267                    	;  110      }
 268    0123  C30000    		jp	c.rets0
 269                    	;  111  
 270                    	;  112  /* pio_init() initialize PIO channel A and B
 271                    	;  113   */
 272                    	;  114  void pio_init()
 273                    	;  115      {
 274                    	_pio_init:
 275                    	;  116      /* PIO A */
 276                    	;  117  
 277                    	;  118      /* 00001111b                ; mode 0 */
 278                    	;  119      out(PIO_A_CTRL, 0x0f);
 279    0126  210F00    		ld	hl,15
 280    0129  E5        		push	hl
 281    012A  211200    		ld	hl,18
 282    012D  CD0000    		call	_out
 283    0130  F1        		pop	af
 284                    	;  120  
 285                    	;  121      /* 00000111b                ; int disable */
 286                    	;  122      out(PIO_A_CTRL, 0x07);
 287    0131  210700    		ld	hl,7
 288    0134  E5        		push	hl
 289    0135  211200    		ld	hl,18
 290    0138  CD0000    		call	_out
 291    013B  F1        		pop	af
 292                    	;  123  
 293                    	;  124      /* PIO B, SPI interface */
 294                    	;  125      /* 11001111b                ; mode 3 */
 295                    	;  126      out(PIO_B_CTRL, 0xcf);
 296    013C  21CF00    		ld	hl,207
 297    013F  E5        		push	hl
 298    0140  211300    		ld	hl,19
 299    0143  CD0000    		call	_out
 300    0146  F1        		pop	af
 301                    	;  127  
 302                    	;  128      /* 00000001b                ; i/o mask
 303                    	;  129      ;bit 0: MISO - input     3                   3
 304                    	;  130      ;bit 1: MOSI - output    4                   5
 305                    	;  131      ;bit 2: SCK  - output    5                   7
 306                    	;  132      ;bit 3: /CS0 - output    6                   9
 307                    	;  133      ;bit 4: /CS1 - output  extra device select  11
 308                    	;  134      ;bit 5: /CS2 - output  extra device select  10
 309                    	;  135      ;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
 310                    	;  136      ;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
 311                    	;  137      ;                                                with an 8 bit transmit or receive transfer
 312                    	;  138      */
 313                    	;  139      out(PIO_B_CTRL, 0x01);
 314    0147  210100    		ld	hl,1
 315    014A  E5        		push	hl
 316    014B  211300    		ld	hl,19
 317    014E  CD0000    		call	_out
 318    0151  F1        		pop	af
 319                    	;  140  
 320                    	;  141      /* 00000111b                ; int disable */
 321                    	;  142      out(PIO_B_CTRL, 0x07);
 322    0152  210700    		ld	hl,7
 323    0155  E5        		push	hl
 324    0156  211300    		ld	hl,19
 325    0159  CD0000    		call	_out
 326    015C  F1        		pop	af
 327                    	;  143  
 328                    	;  144      /* 00111010b                ;initialize output bits
 329                    	;  145      ; bit 1: MOSI - output      ;low
 330                    	;  146      ; bit 2: SCK  - output      ;low
 331                    	;  147      ; bit 3: /CS0 - output      ;high = not selected
 332                    	;  148      ; bit 4: /CS1 - output      ;high = not selected
 333                    	;  149      ; bit 5: /CS2 - output      ;high = not selected
 334                    	;  150      ; bit 6: TP1  - output  ;low
 335                    	;  151      ; bit 7: TRA  - output  ;low
 336                    	;  152      */
 337                    	;  153      out(PIO_B_DATA, 0x3a);
 338    015D  213A00    		ld	hl,58
 339    0160  E5        		push	hl
 340    0161  211100    		ld	hl,17
 341    0164  CD0000    		call	_out
 342    0167  F1        		pop	af
 343                    	;  154      }
 344    0168  C9        		ret 
 345                    	;  155  
 346                    	;  156  /* Print character on serial port A */
 347                    	;  157  int putchar(char pchar)
 348                    	;  158      {
 349                    	_putchar:
 350    0169  CD0000    		call	c.savs
 351                    	L101:
 352                    	;  159      while ((in(SIO_A_CTRL) & 0x04) == 0) /* wait for tx buffer empty */
 353    016C  210A00    		ld	hl,10
 354    016F  CD0000    		call	_in
 355    0172  CB51      		bit	2,c
 356    0174  28F6      		jr	z,L101
 357                    	;  160          ;
 358                    	;  161      out(SIO_A_DATA, pchar);
 359    0176  DD6E04    		ld	l,(ix+4)
 360    0179  DD6605    		ld	h,(ix+5)
 361    017C  E5        		push	hl
 362    017D  210800    		ld	hl,8
 363    0180  CD0000    		call	_out
 364    0183  F1        		pop	af
 365                    	;  162      if (pchar == '\n')
 366    0184  DD7E04    		ld	a,(ix+4)
 367    0187  FE0A      		cp	10
 368    0189  2005      		jr	nz,L02
 369    018B  DD7E05    		ld	a,(ix+5)
 370    018E  FE00      		cp	0
 371                    	L02:
 372    0190  2006      		jr	nz,L121
 373                    	;  163          putchar('\r');
 374    0192  210D00    		ld	hl,13
 375    0195  CD6901    		call	_putchar
 376                    	L121:
 377                    	;  164      return (pchar);
 378    0198  DD4E04    		ld	c,(ix+4)
 379    019B  DD4605    		ld	b,(ix+5)
 380    019E  C30000    		jp	c.rets
 381                    	;  165      }
 382                    	;  166  
 383                    	;  167  /* Get character from serial port A */
 384                    	;  168  int getchar()
 385                    	;  169      {
 386                    	_getchar:
 387                    	L131:
 388                    	;  170      while (!(in(SIO_A_CTRL) & 0x01)) /* test and loop until character available */
 389    01A1  210A00    		ld	hl,10
 390    01A4  CD0000    		call	_in
 391    01A7  CB41      		bit	0,c
 392    01A9  28F6      		jr	z,L131
 393                    	;  171          ;
 394                    	;  172      return (in(SIO_A_DATA));
 395    01AB  210800    		ld	hl,8
 396    01AE  CD0000    		call	_in
 397    01B1  C9        		ret 
 398                    	;  173      }
 399                    	;  174  
 400                    	;  175  /* Get line from keyboard
 401                    	;  176   * edit line with BS
 402                    	;  177   * returns when CR or Ctrl-C is entered
 403                    	;  178   * return value is length of entered string
 404                    	;  179   */
 405                    	;  180  int getkline(char *txtinp, int bufsize)
 406                    	;  181      {
 407                    	_getkline:
 408    01B2  CD0000    		call	c.savs
 409    01B5  21F7FF    		ld	hl,65527
 410    01B8  39        		add	hl,sp
 411    01B9  F9        		ld	sp,hl
 412                    	;  182      int ncharin;
 413                    	;  183      char charin;
 414                    	;  184  
 415                    	;  185      for (ncharin = 0; ncharin < (bufsize - 1); ncharin++)
 416    01BA  DD36F800  		ld	(ix-8),0
 417    01BE  DD36F900  		ld	(ix-7),0
 418                    	L151:
 419    01C2  DD6E06    		ld	l,(ix+6)
 420    01C5  DD6607    		ld	h,(ix+7)
 421    01C8  01FFFF    		ld	bc,65535
 422    01CB  09        		add	hl,bc
 423    01CC  DD7EF8    		ld	a,(ix-8)
 424    01CF  95        		sub	l
 425    01D0  DD7EF9    		ld	a,(ix-7)
 426    01D3  9C        		sbc	a,h
 427    01D4  F26802    		jp	p,L161
 428                    	;  186          {
 429                    	;  187          charin = getchar();
 430    01D7  CDA101    		call	_getchar
 431    01DA  DD71F7    		ld	(ix-9),c
 432                    	;  188          if (charin == '\r') /* CR */
 433    01DD  DD7EF7    		ld	a,(ix-9)
 434    01E0  FE0D      		cp	13
 435    01E2  2011      		jr	nz,L112
 436                    	;  189              {
 437                    	;  190              *txtinp = 0;
 438    01E4  DD6E04    		ld	l,(ix+4)
 439    01E7  DD6605    		ld	h,(ix+5)
 440    01EA  3600      		ld	(hl),0
 441                    	;  191              return (ncharin);
 442    01EC  DD4EF8    		ld	c,(ix-8)
 443    01EF  DD46F9    		ld	b,(ix-7)
 444    01F2  C30000    		jp	c.rets
 445                    	L112:
 446                    	;  192              }
 447                    	;  193          else if (charin == 3) /* Ctrl-C */
 448    01F5  DD7EF7    		ld	a,(ix-9)
 449    01F8  FE03      		cp	3
 450    01FA  2006      		jr	nz,L132
 451                    	;  194              return (0);
 452    01FC  010000    		ld	bc,0
 453    01FF  C30000    		jp	c.rets
 454                    	L132:
 455                    	;  195          else if (charin == '\b') /* BS */
 456    0202  DD7EF7    		ld	a,(ix-9)
 457    0205  FE08      		cp	8
 458    0207  203A      		jr	nz,L152
 459                    	;  196              {
 460                    	;  197              if (0 < ncharin)
 461    0209  97        		sub	a
 462    020A  DD96F8    		sub	(ix-8)
 463    020D  3E00      		ld	a,0
 464    020F  DD9EF9    		sbc	a,(ix-7)
 465    0212  F25D02    		jp	p,L171
 466                    	;  198                  {
 467                    	;  199                  putchar('\b');
 468    0215  210800    		ld	hl,8
 469    0218  CD6901    		call	_putchar
 470                    	;  200                  putchar(' ');
 471    021B  212000    		ld	hl,32
 472    021E  CD6901    		call	_putchar
 473                    	;  201                  putchar('\b');
 474    0221  210800    		ld	hl,8
 475    0224  CD6901    		call	_putchar
 476                    	;  202                  ncharin--;
 477    0227  DD6EF8    		ld	l,(ix-8)
 478    022A  DD66F9    		ld	h,(ix-7)
 479    022D  2B        		dec	hl
 480    022E  DD75F8    		ld	(ix-8),l
 481    0231  DD74F9    		ld	(ix-7),h
 482                    	;  203                  txtinp--;
 483    0234  DD6E04    		ld	l,(ix+4)
 484    0237  DD6605    		ld	h,(ix+5)
 485    023A  2B        		dec	hl
 486    023B  DD7504    		ld	(ix+4),l
 487    023E  DD7405    		ld	(ix+5),h
 488    0241  181A      		jr	L171
 489                    	L152:
 490                    	;  204                  }
 491                    	;  205              }
 492                    	;  206          else
 493                    	;  207              {
 494                    	;  208              putchar(charin);
 495    0243  DD6EF7    		ld	l,(ix-9)
 496    0246  97        		sub	a
 497    0247  67        		ld	h,a
 498    0248  CD6901    		call	_putchar
 499                    	;  209              *txtinp++ = charin;
 500    024B  DD6E04    		ld	l,(ix+4)
 501    024E  DD6605    		ld	h,(ix+5)
 502    0251  DD3404    		inc	(ix+4)
 503    0254  2003      		jr	nz,L03
 504    0256  DD3405    		inc	(ix+5)
 505                    	L03:
 506    0259  DD7EF7    		ld	a,(ix-9)
 507    025C  77        		ld	(hl),a
 508                    	L171:
 509    025D  DD34F8    		inc	(ix-8)
 510    0260  2003      		jr	nz,L62
 511    0262  DD34F9    		inc	(ix-7)
 512                    	L62:
 513    0265  C3C201    		jp	L151
 514                    	L161:
 515                    	;  210              }
 516                    	;  211          }
 517                    	;  212      *txtinp = 0;
 518    0268  DD6E04    		ld	l,(ix+4)
 519    026B  DD6605    		ld	h,(ix+5)
 520    026E  3600      		ld	(hl),0
 521                    	;  213      return (ncharin);
 522    0270  DD4EF8    		ld	c,(ix-8)
 523    0273  DD46F9    		ld	b,(ix-7)
 524    0276  C30000    		jp	c.rets
 525                    	;  214      }
 526                    	;  215  
 527                    	;  216  /* Status LED on */
 528                    	;  217  void ledon()
 529                    	;  218      {
 530                    	_ledon:
 531                    	;  219      out(LEDON, 1);
 532    0279  210100    		ld	hl,1
 533    027C  E5        		push	hl
 534    027D  211800    		ld	hl,24
 535    0280  CD0000    		call	_out
 536    0283  F1        		pop	af
 537                    	;  220      }
 538    0284  C9        		ret 
 539                    	;  221  
 540                    	;  222  /* Status LED off */
 541                    	;  223  void ledoff()
 542                    	;  224      {
 543                    	_ledoff:
 544                    	;  225      out(LEDOFF, 0);
 545    0285  210000    		ld	hl,0
 546    0288  E5        		push	hl
 547    0289  211400    		ld	hl,20
 548    028C  CD0000    		call	_out
 549    028F  F1        		pop	af
 550                    	;  226      }
 551    0290  C9        		ret 
 552                    	;  227  
 553                    		.external	c.rets0
 554                    		.external	c.savs0
 555                    		.public	_getchar
 556                    		.public	_sio_init
 557                    		.public	_pio_init
 558                    		.external	_out
 559                    		.external	_in
 560                    		.public	_getkline
 561                    		.external	_printf
 562                    		.public	_hwinit
 563                    		.public	_ledon
 564                    		.public	_ctc_init
 565                    		.public	_sioregini
 566                    		.public	_putchar
 567                    		.external	c.rets
 568                    		.public	_ledoff
 569                    		.external	c.savs
 570                    		.end
