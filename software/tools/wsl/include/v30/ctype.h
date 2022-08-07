/*	CHARACTER TYPES HEADER
 *	copyright (c) 1984 by Whitesmiths, Ltd.
 */

#ifndef __CTYPE__
#define __CTYPE__	1

/*	set up prototyping
 */
#ifndef __
#ifdef _PROTO
#define __(a)	a
#else
#define __(a)	()
#endif
#endif

#ifndef _EBCDIC
#define _ctype	_ctasc
#else
#define _ctype	_ctebc
#endif

/*	bit definitions for character mapping array
 */
#define	_UC		0001	/* upper case */
#define	_LC		0002	/* lower case */
#define	_D		0004	/* decimal digit */
#define	_S		0010	/* whitespace */
#define	_P		0020	/* punctuation */
#define	_C		0040	/* control */
#define	_X		0100	/* hexadecimal digit */
#define	_SP		0200	/* space */

/*	character mapping array
 */
extern const unsigned char _ctype[];

/*	function declarations
 */
int isalnum __((int c));
int isalpha __((int c));
int iscntrl __((int c));
int isdigit __((int c));
int isgraph __((int c));
int islower __((int c));
int isprint __((int c));
int ispunct __((int c));
int isspace __((int c));
int isupper __((int c));
int isxdigit __((int c));
int tolower __((int c));
int toupper __((int c));

/*	macros
 */
#define isalnum(c) ((_ctype+1)[(c)] & (_D|_UC|_LC))
#define isalpha(c) ((_ctype+1)[(c)] & (_UC|_LC))
#define iscntrl(c) ((_ctype+1)[(c)] & _C)
#define isdigit(c) ((_ctype+1)[(c)] & _D)
#define isgraph(c) ((_ctype+1)[(c)] & (_P|_D|_UC|_LC))
#define islower(c) ((_ctype+1)[(c)] & _LC)
#define isprint(c) ((_ctype+1)[(c)] & (_SP|_P|_D|_UC|_LC))
#define ispunct(c) ((_ctype+1)[(c)] & _P)
#define isspace(c) ((_ctype+1)[(c)] & (_S|_SP))
#define isupper(c) ((_ctype+1)[(c)] & _UC)
#define isxdigit(c) ((_ctype+1)[(c)] & (_D|_X))

#endif
