/*	SHARED DATA TYPES FOR P1 AND THE DEBUGGER
 *	copyright (c) 1985 by Whitesmiths, Ltd.
 */

#ifndef _CVERSION
#define _CVERSION 220
#endif

/*	the type bit patterns
 */
#define TCHAR		0010
#define TICHAR		0011
#define TUCHAR		0012

#define TSHORT		0020
#define TUSHORT		0021

#define TINT		0030
#define TFIELD		0031
#define TUNSIGN		0032

#define TLONG		0040
#define TULONG		0041

#define TFLOAT		0050
#define TDOUBLE		0051
#define TLDOUBLE	0052

#define TPTRTO		0100
#define TARRAY		0101
#define TFNRET		0102

#define TSTRUCT		0110
#define TUNION		0111
#define TENUM		0112

#define TVOID		0120
