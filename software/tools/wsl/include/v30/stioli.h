/*	INTERNAL STANDARD I/O HEADER
 *	copyright (c) 1985 by Whitesmiths, Ltd.
 */

#ifndef __STIOLI__
#define __STIOLI__	1

/*	the tmp file structure
 */
typedef struct _tmp
	{
	struct _tmp *tlist;		/* chain used to remove file */
	char tname[L_tmpnam];	/* temporary file name */
	struct _file *tpf;		/* ptr to FILE for closing file */
	} TMPNM;

/*	flag bit definitions
 */
#define EOFERR		01		/* end of file error */
#define IOERR		02		/* i/o error */
#define OPREAD		04		/* file opened for read */
#define OPWRITE		010		/* file opened for write */
#define READING		020		/* current buffer is for reading */
#define WRITING		040		/* current buffer is for writing */
							/* READING & WRITING should track values in std.h */
#define BUFALLOC	0100	/* buffer allocated by system */
#define FILALLOC	0200	/* FILE structure allocated by system */
#define FULBUF		0400	/* full buffering on output, no flush on '\n' */
#define NOBUF		01000	/* no buffering, i/o done directly to user buffer */
#define TXTFILE		02000	/* text file (default is binary) */
							/* TXTFILE never set in IDRIS/UNIX */
#define BADSEEK		(-1L)	/* error from _lseek() or ftell() */

#endif
