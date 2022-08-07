   1                    		.public _addblk
   2                    		.public _subblk
   3                    		.public _blk2byte
   4                    		.public _part2blk
   5                    	
   6                    	
   7                    	;/* Make block address to byte address
   8                    	; * by multiplying with 512 (blocksize)
   9                    	; */
  10                    	;int blk2byte(unsigned char *)
  11                    	_blk2byte:
  12                    		;dsk parameter in HL
  13                    		; shift left 8 bits
  14    0000  23        		inc	hl
  15    0001  7E        		ld	a, (hl)
  16    0002  2B        		dec	hl
  17    0003  77        		ld	(hl), a
  18    0004  23        		inc	hl
  19    0005  23        		inc	hl
  20    0006  7E        		ld	a, (hl)
  21    0007  2B        		dec	hl
  22    0008  77        		ld	(hl), a
  23    0009  23        		inc	hl
  24    000A  23        		inc	hl
  25    000B  7E        		ld	a, (hl)
  26    000C  2B        		dec	hl
  27    000D  77        		ld	(hl), a
  28    000E  23        		inc	hl
  29    000F  3600      		ld	(hl), 0
  30                    		; then shift left 1 bit
  31    0011  2B        		dec	hl
  32    0012  CB26      		sla	(hl)
  33    0014  2B        		dec	hl
  34    0015  CB16      		rl	(hl)
  35    0017  2B        		dec	hl
  36    0018  CB16      		rl	(hl)
  37    001A  C9        		ret
  38                    	
  39                    	;/* Convert partition address to block address
  40                    	; * four byte LSB to MSB
  41                    	; */
  42                    	;void part2blk(unsigned char *, unsigned char *);
  43                    	_part2blk:
  44                    		;put dsk parameter in DE
  45    001B  110300    		ld	de, 3	;put pointer to LSB in DE
  46    001E  19        		add	hl, de
  47    001F  5D        		ld	e, l
  48    0020  54        		ld	d, h
  49                    		;part parameter on stack
  50    0021  210200    		ld	hl, 2
  51    0024  39        		add	hl, sp
  52    0025  46        		ld	b, (hl)
  53    0026  23        		inc	hl
  54    0027  66        		ld	h, (hl)
  55    0028  68        		ld	l, b
  56    0029  0604      		ld	b, 4
  57                    	moveit:
  58    002B  7E        		ld	a, (hl)
  59    002C  12        		ld	(de),  a
  60    002D  1B        		dec	de
  61    002E  23        		inc	hl
  62    002F  10FA      		djnz	moveit
  63                    	
  64    0031  C9        		ret
  65                    	
  66                    	;/* Add block addresses
  67                    	; */
  68                    	;void addblk(unsigned char *, unsigned char *);
  69                    	_addblk:
  70                    		;first dsk parameter in HL
  71    0032  110300    		ld	de, 3	;put pointer to LSB in DE
  72    0035  19        		add	hl, de
  73    0036  5D        		ld	e, l
  74    0037  54        		ld	d, h
  75                    		;second dsk parameter on stack
  76    0038  210200    		ld	hl, 2
  77    003B  39        		add	hl, sp
  78    003C  4E        		ld	c, (hl)
  79    003D  23        		inc	hl
  80    003E  46        		ld	b, (hl)
  81    003F  210300    		ld	hl, 3	;put pointer to LSB in HL
  82    0042  09        		add	hl, bc
  83                    	
  84    0043  0604      		ld	b, 4
  85    0045  37        		scf
  86    0046  3F        		ccf
  87                    	addit:
  88    0047  1A        		ld	a, (de)
  89    0048  8E        		adc	a, (hl)
  90    0049  12        		ld	(de),  a
  91    004A  1B        		dec	de
  92    004B  2B        		dec	hl
  93    004C  10F9      		djnz	addit
  94                    	
  95    004E  C9        		ret
  96                    	
  97                    	;/* Substract block addresses
  98                    	; */
  99                    	;void subblk(unsigned char *, unsigned char *);
 100                    	_subblk:
 101                    		;first dsk parameter in HL
 102    004F  110300    		ld	de, 3	;put pointer to LSB in DE
 103    0052  19        		add	hl, de
 104    0053  5D        		ld	e, l
 105    0054  54        		ld	d, h
 106                    		;second dsk parameter on stack
 107    0055  210200    		ld	hl, 2
 108    0058  39        		add	hl, sp
 109    0059  4E        		ld	c, (hl)
 110    005A  23        		inc	hl
 111    005B  46        		ld	b, (hl)
 112    005C  210300    		ld	hl, 3	;put pointer to LSB in HL
 113    005F  09        		add	hl, bc
 114                    	
 115    0060  0604      		ld	b, 4
 116    0062  37        		scf
 117    0063  3F        		ccf
 118                    	subit:
 119    0064  1A        		ld	a, (de)
 120    0065  9E        		sbc	a, (hl)
 121    0066  12        		ld	(de),  a
 122    0067  1B        		dec	de
 123    0068  2B        		dec	hl
 124    0069  10F9      		djnz	subit
 125                    	
 126    006B  C9        		ret
 127                    	
 128                    	
 129                    		.end
 130                    	
