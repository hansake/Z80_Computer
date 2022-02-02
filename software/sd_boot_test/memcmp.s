;
;
;   memcmp
;
;   Copyright (c) 1989 COSMIC
;   All rights reserved
;
;   
    .psect  _text
    .public _memcmp
; PMO tweaks, also make sure result properly extended to int

_memcmp:
    push    de
    ex  de, hl      ; de = s1
    ld  hl, 7
    add hl, sp
    ld  b, (hl)     ; bc = count
    dec hl
    ld  c, (hl)
    dec hl
    ld  a, (hl)     ; hl = s2
    dec hl
    ld  l, (hl)
    ld  h, a
again:
    ld  a, b
    or  c
    jr  z, fin      ; will also  force 0 for return
    ld  a, (de)
    sub (hl)
    inc hl
    inc de
    dec bc
    jp  z,again    ; loop while same
fin:
    ld  c, a
    add a, a
    sbc a, a
    ld  b, a
    pop de
    ret
    .end

