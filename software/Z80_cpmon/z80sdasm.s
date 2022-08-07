	.public _addblk
	.public _subblk
	.public _blk2byte
	.public _part2blk


;/* Make block address to byte address
; * by multiplying with 512 (blocksize)
; */
;int blk2byte(unsigned char *)
_blk2byte:
	;dsk parameter in HL
	; shift left 8 bits
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	ld	(hl), 0
	; then shift left 1 bit
	dec	hl
	sla	(hl)
	dec	hl
	rl	(hl)
	dec	hl
	rl	(hl)
	ret

;/* Convert partition address to block address
; * four byte LSB to MSB
; */
;void part2blk(unsigned char *, unsigned char *);
_part2blk:
	;put dsk parameter in DE
	ld	de, 3	;put pointer to LSB in DE
	add	hl, de
	ld	e, l
	ld	d, h
	;part parameter on stack
	ld	hl, 2
	add	hl, sp
	ld	b, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, b
	ld	b, 4
moveit:
	ld	a, (hl)
	ld	(de),  a
	dec	de
	inc	hl
	djnz	moveit

	ret

;/* Add block addresses
; */
;void addblk(unsigned char *, unsigned char *);
_addblk:
	;first dsk parameter in HL
	ld	de, 3	;put pointer to LSB in DE
	add	hl, de
	ld	e, l
	ld	d, h
	;second dsk parameter on stack
	ld	hl, 2
	add	hl, sp
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	hl, 3	;put pointer to LSB in HL
	add	hl, bc

	ld	b, 4
	scf
	ccf
addit:
	ld	a, (de)
	adc	a, (hl)
	ld	(de),  a
	dec	de
	dec	hl
	djnz	addit

	ret

;/* Substract block addresses
; */
;void subblk(unsigned char *, unsigned char *);
_subblk:
	;first dsk parameter in HL
	ld	de, 3	;put pointer to LSB in DE
	add	hl, de
	ld	e, l
	ld	d, h
	;second dsk parameter on stack
	ld	hl, 2
	add	hl, sp
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	hl, 3	;put pointer to LSB in HL
	add	hl, bc

	ld	b, 4
	scf
	ccf
subit:
	ld	a, (de)
	sbc	a, (hl)
	ld	(de),  a
	dec	de
	dec	hl
	djnz	subit

	ret


	.end

