   1                    	;    1  /* z80cio.c
   2                    	;    2   *
   3                    	;    3   *  I/O routines for my DIY Z80 Computer.
   4                    	;    4   *  The program compiled with Whitesmiths C compiler.
   5                    	;    5   *
   6                    	;    6   *  You are free to use, modify, and redistribute
   7                    	;    7   *  this source code. No warranties given.
   8                    	;    8   *  Hastily Cobbled Together 2021 and 2022
   9                    	;    9   *  by Hans-Ake Lund
  10                    	;   10   *
  11                    	;   11   */
  12                    	;   12  
  13                    	;   13  #include <std.h>
  14                    	;   14  #include "z80computer.h"
  15                    		.psect	_text
  16                    	;   15  
  17                    	;   16  /* Print character on serial port A */
  18                    	;   17  int putchar(char pchar)
  19                    	;   18          {
  20                    	_putchar:
  21    0000  CD0000    		call	c.savs
  22                    	L1:
  23                    	;   19          while ((in(SIO_A_CTRL) & 0x04) == 0) /* wait for tx buffer empty */
  24    0003  210A00    		ld	hl,10
  25    0006  CD0000    		call	_in
  26    0009  CB51      		bit	2,c
  27    000B  28F6      		jr	z,L1
  28                    	;   20                  ;
  29                    	;   21          out(SIO_A_DATA, pchar);
  30    000D  DD6E04    		ld	l,(ix+4)
  31    0010  DD6605    		ld	h,(ix+5)
  32    0013  E5        		push	hl
  33    0014  210800    		ld	hl,8
  34    0017  CD0000    		call	_out
  35    001A  F1        		pop	af
  36                    	;   22          if (pchar == '\n')
  37    001B  DD7E04    		ld	a,(ix+4)
  38    001E  FE0A      		cp	10
  39    0020  2005      		jr	nz,L4
  40    0022  DD7E05    		ld	a,(ix+5)
  41    0025  FE00      		cp	0
  42                    	L4:
  43    0027  2006      		jr	nz,L12
  44                    	;   23                  putchar('\r');
  45    0029  210D00    		ld	hl,13
  46    002C  CD0000    		call	_putchar
  47                    	L12:
  48                    	;   24          return (pchar);
  49    002F  DD4E04    		ld	c,(ix+4)
  50    0032  DD4605    		ld	b,(ix+5)
  51    0035  C30000    		jp	c.rets
  52                    	;   25          }
  53                    	;   26  
  54                    	;   27  /* Get character from serial port A */
  55                    	;   28  int getchar()
  56                    	;   29          {
  57                    	_getchar:
  58                    	L13:
  59                    	;   30          while (!(in(SIO_A_CTRL) & 0x01)) /* test and loop until character available */
  60    0038  210A00    		ld	hl,10
  61    003B  CD0000    		call	_in
  62    003E  CB41      		bit	0,c
  63    0040  28F6      		jr	z,L13
  64                    	;   31                  ;
  65                    	;   32          return  (in(SIO_A_DATA));
  66    0042  210800    		ld	hl,8
  67    0045  CD0000    		call	_in
  68    0048  C9        		ret 
  69                    		.psect	_data
  70                    	L5:
  71    0000  08        		.byte	8
  72    0001  20        		.byte	32
  73    0002  08        		.byte	8
  74    0003  00        		.byte	0
  75                    		.psect	_text
  76                    	;   33          }
  77                    	;   34  
  78                    	;   35  /* Get line from keyboard
  79                    	;   36   * edit line with BS
  80                    	;   37   * returns when CR or Ctrl-C is entered
  81                    	;   38   * return value is length of entered string
  82                    	;   39   */
  83                    	;   40  int getkline(char *txtinp, int bufsize)
  84                    	;   41          {
  85                    	_getkline:
  86    0049  CD0000    		call	c.savs
  87    004C  21F7FF    		ld	hl,65527
  88    004F  39        		add	hl,sp
  89    0050  F9        		ld	sp,hl
  90                    	;   42          int ncharin;
  91                    	;   43          char charin;
  92                    	;   44  
  93                    	;   45          for (ncharin = 0; ncharin < (bufsize - 1); ncharin++)
  94    0051  DD36F800  		ld	(ix-8),0
  95    0055  DD36F900  		ld	(ix-7),0
  96                    	L15:
  97    0059  DD6E06    		ld	l,(ix+6)
  98    005C  DD6607    		ld	h,(ix+7)
  99    005F  01FFFF    		ld	bc,65535
 100    0062  09        		add	hl,bc
 101    0063  DD7EF8    		ld	a,(ix-8)
 102    0066  95        		sub	l
 103    0067  DD7EF9    		ld	a,(ix-7)
 104    006A  9C        		sbc	a,h
 105    006B  F2FB00    		jp	p,L16
 106                    	;   46                  {
 107                    	;   47                  charin = getchar();
 108    006E  CD3800    		call	_getchar
 109    0071  DD71F7    		ld	(ix-9),c
 110                    	;   48                  if (charin == '\r') /* CR */
 111    0074  DD7EF7    		ld	a,(ix-9)
 112    0077  FE0D      		cp	13
 113    0079  2011      		jr	nz,L111
 114                    	;   49                          {
 115                    	;   50                          *txtinp = 0;
 116    007B  DD6E04    		ld	l,(ix+4)
 117    007E  DD6605    		ld	h,(ix+5)
 118    0081  3600      		ld	(hl),0
 119                    	;   51                          return (ncharin);
 120    0083  DD4EF8    		ld	c,(ix-8)
 121    0086  DD46F9    		ld	b,(ix-7)
 122    0089  C30000    		jp	c.rets
 123                    	L111:
 124                    	;   52                          }
 125                    	;   53                  else if (charin == 3) /* Ctrl-C */
 126    008C  DD7EF7    		ld	a,(ix-9)
 127    008F  FE03      		cp	3
 128    0091  2006      		jr	nz,L131
 129                    	;   54                          return (0);
 130    0093  010000    		ld	bc,0
 131    0096  C30000    		jp	c.rets
 132                    	L131:
 133                    	;   55                  else if (charin == '\b') /* BS */
 134    0099  DD7EF7    		ld	a,(ix-9)
 135    009C  FE08      		cp	8
 136    009E  202E      		jr	nz,L151
 137                    	;   56                          {
 138                    	;   57                          if (0 < ncharin)
 139    00A0  97        		sub	a
 140    00A1  DD96F8    		sub	(ix-8)
 141    00A4  3E00      		ld	a,0
 142    00A6  DD9EF9    		sbc	a,(ix-7)
 143    00A9  F2F000    		jp	p,L17
 144                    	;   58                                  {
 145                    	;   59                                  puts("\b \b");
 146    00AC  210000    		ld	hl,L5
 147    00AF  CD0000    		call	_puts
 148                    	;   60                                  ncharin--;
 149    00B2  DD6EF8    		ld	l,(ix-8)
 150    00B5  DD66F9    		ld	h,(ix-7)
 151    00B8  2B        		dec	hl
 152    00B9  DD75F8    		ld	(ix-8),l
 153    00BC  DD74F9    		ld	(ix-7),h
 154                    	;   61                                  txtinp--;
 155    00BF  DD6E04    		ld	l,(ix+4)
 156    00C2  DD6605    		ld	h,(ix+5)
 157    00C5  2B        		dec	hl
 158    00C6  DD7504    		ld	(ix+4),l
 159    00C9  DD7405    		ld	(ix+5),h
 160    00CC  1822      		jr	L17
 161                    	L151:
 162                    	;   62                                  }
 163                    	;   63                          }
 164                    	;   64                  else
 165                    	;   65                          {
 166                    	;   66                          putchar(charin);
 167    00CE  DD6EF7    		ld	l,(ix-9)
 168    00D1  97        		sub	a
 169    00D2  67        		ld	h,a
 170    00D3  CD0000    		call	_putchar
 171                    	;   67                          *txtinp++ = charin;
 172    00D6  DD6E04    		ld	l,(ix+4)
 173    00D9  DD6605    		ld	h,(ix+5)
 174    00DC  DD3404    		inc	(ix+4)
 175    00DF  2003      		jr	nz,L41
 176    00E1  DD3405    		inc	(ix+5)
 177                    	L41:
 178    00E4  DD7EF7    		ld	a,(ix-9)
 179    00E7  77        		ld	(hl),a
 180                    	;   68                          ncharin++;
 181    00E8  DD34F8    		inc	(ix-8)
 182    00EB  2003      		jr	nz,L61
 183    00ED  DD34F9    		inc	(ix-7)
 184                    	L61:
 185                    	L17:
 186    00F0  DD34F8    		inc	(ix-8)
 187    00F3  2003      		jr	nz,L21
 188    00F5  DD34F9    		inc	(ix-7)
 189                    	L21:
 190    00F8  C35900    		jp	L15
 191                    	L16:
 192                    	;   69                          }
 193                    	;   70                  }
 194                    	;   71          *txtinp = 0;
 195    00FB  DD6E04    		ld	l,(ix+4)
 196    00FE  DD6605    		ld	h,(ix+5)
 197    0101  3600      		ld	(hl),0
 198                    	;   72          return (ncharin);
 199    0103  DD4EF8    		ld	c,(ix-8)
 200    0106  DD46F9    		ld	b,(ix-7)
 201    0109  C30000    		jp	c.rets
 202                    	;   73          }
 203                    	;   74  
 204                    	;   75  /* Status LED on */
 205                    	;   76  void ledon()
 206                    	;   77          {
 207                    	_ledon:
 208                    	;   78          out(LEDON, 1);
 209    010C  210100    		ld	hl,1
 210    010F  E5        		push	hl
 211    0110  211800    		ld	hl,24
 212    0113  CD0000    		call	_out
 213    0116  F1        		pop	af
 214                    	;   79          }
 215    0117  C9        		ret 
 216                    	;   80  
 217                    	;   81  /* Status LED off */
 218                    	;   82  void ledoff()
 219                    	;   83          {
 220                    	_ledoff:
 221                    	;   84          out(LEDOFF, 0);
 222    0118  210000    		ld	hl,0
 223    011B  E5        		push	hl
 224    011C  211400    		ld	hl,20
 225    011F  CD0000    		call	_out
 226    0122  F1        		pop	af
 227                    	;   85          }
 228    0123  C9        		ret 
 229                    	;   86  
 230                    	;   87  
 231                    		.public	_getchar
 232                    		.external	_out
 233                    		.external	_in
 234                    		.public	_getkline
 235                    		.public	_ledon
 236                    		.external	_puts
 237                    		.public	_putchar
 238                    		.public	_ledoff
 239                    		.external	c.rets
 240                    		.external	c.savs
 241                    		.end
