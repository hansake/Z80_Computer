   1                    	;
   2                    	;
   3                    	;   memcmp
   4                    	;
   5                    	;   Copyright (c) 1989 COSMIC
   6                    	;   All rights reserved
   7                    	;
   8                    	;   
   9                    	    .psect  _text
  10                    	    .public _memcmp
  11                    	; PMO tweaks, also make sure result properly extended to int
  12                    	
  13                    	_memcmp:
  14    0000  D5        	    push    de
  15    0001  EB        	    ex  de, hl      ; de = s1
  16    0002  210700    	    ld  hl, 7
  17    0005  39        	    add hl, sp
  18    0006  46        	    ld  b, (hl)     ; bc = count
  19    0007  2B        	    dec hl
  20    0008  4E        	    ld  c, (hl)
  21    0009  2B        	    dec hl
  22    000A  7E        	    ld  a, (hl)     ; hl = s2
  23    000B  2B        	    dec hl
  24    000C  6E        	    ld  l, (hl)
  25    000D  67        	    ld  h, a
  26                    	again:
  27    000E  78        	    ld  a, b
  28    000F  B1        	    or  c
  29    0010  2808      	    jr  z, fin      ; will also  force 0 for return
  30    0012  1A        	    ld  a, (de)
  31    0013  96        	    sub (hl)
  32    0014  23        	    inc hl
  33    0015  13        	    inc de
  34    0016  0B        	    dec bc
  35    0017  CA0E00    	    jp  z,again    ; loop while same
  36                    	fin:
  37    001A  4F        	    ld  c, a
  38    001B  87        	    add a, a
  39    001C  9F        	    sbc a, a
  40    001D  47        	    ld  b, a
  41    001E  D1        	    pop de
  42    001F  C9        	    ret
  43                    	    .end
  44                    	
