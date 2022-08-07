/*	HEAP INFO STRUCTURE
 *	copyright (c) 1985 by Whitesmiths, Ltd.
 */

#ifndef __HEAP__
#define __HEAP__	1

/*	minimum info to describe current heap state
 */
typedef struct _hinfo
	{
	BYTES total;
	BYTES avail;
	BYTES maint;
	} HINFO;

#endif
