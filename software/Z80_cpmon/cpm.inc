;**************************************************************
;*
;*             C P / M   version   2 . 2
;*
;*   Reconstructed from memory image on February 27, 1981
;*
;*                by Clark A. Calkins
;*
;*   Modifications by Madis Kaal 2018 to produce identical
;*   binary image to actual CPM.SYS for some Xerox machine
;*   Also fixed some minor typos and converted to pyz80
;*   assembler syntax
;**************************************************************
;
; Memory layout is defined when linking the code.
;
.external ccp	;base of ccp
.external bdos	;base of bdos
.external bios	;base of bios
;
; The size of CCP and BDOS
.define CCPSIZE  =	0800h
.define BDOSSIZE =	0e00h

; CP/M addresses
.define IOBYTE	=	0003h		;i/o definition byte.
.define TDRIVE	=	0004h		;current drive name and user number.
.define ENTRY	=	0005h		;entry point for the cp/m bdos.
.define TFCB	=	005Ch		;default file control block.
.define TBUFF	=	0080h		;i/o buffer and command line storage.
.define TBASE	=	0100h		;transiant program storage area.
;
.define cdisk	=	0004h		;current disk number 0=a,... l5=p
.define iobyte	=	0003h		;intel i/o byte

;
;   Set control character equates.
;
.define CNTRLC	=	3		;control-c
.define CNTRLE	=	05h		;control-e
.define BS	=	08h		;backspace
.define TAB	=	09h		;tab
.define LF	=	0Ah		;line feed
.define FF	=	0Ch		;form feed
.define CR	=	0Dh		;carriage return
.define CNTRLP	=	10h		;control-p
.define CNTRLR	=	12h		;control-r
.define CNTRLS	=	13h		;control-s
.define CNTRLU	=	15h		;control-u
.define CNTRLX	=	18h		;control-x
.define CNTRLZ	=	1Ah		;control-z (end-of-file mark)
.define DEL	=	7Fh		;rubout

;------------------------------------
; Minimal print probe,
; insert in the code
;    rst 38h
;    .byte 'x' ;character to print
;
; implemented as the macro PRTPROB
    .macro PRTPROB
    rst 7 ;rst 38h in Zilog manual
    .byte ?1
    .endm
;------------------------------------
