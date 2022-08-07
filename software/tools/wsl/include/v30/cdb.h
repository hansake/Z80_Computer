/*	INTERFACE TO SOURCE DEBUGGER PARTS
 *	copyright (c) 1984 by Whitesmiths Ltd.
 */

#ifndef _LVERSION
#define _LVERSION 220
#endif

#ifndef _CVERSION
#define _CVERSION 220
#endif

/*	CDB is a "crossover" utility, it must be compilable on 2.2 compilers
 */
#if 300 <= _CVERSION
#include <wslxa.h>
	#ifndef BUFSIZE
	#define BUFSIZE 512
	#endif
	#ifndef EOF
	#define EOF -1
	#endif
#else
#include <std.h>
#define FD FILE
#define RDONLY 
#endif

/*	static vs. auto tradeoff
 *
 *	to reduce stack demands
 *	recompile with BSS	static
 *
 *	to reduce load time
 *	recompile with BSS	auto
 *
 *	best represented as real bss (uninitialized data)
 */
#define BSS auto

/*	set to GLOBAL to make internal funcs appear in symtab
 *	else LOCAL to reduce collisions with user symbols
 */
#define SECRET LOCAL

/*	set to 1 to use separate internal heap (fixed size)
 *	else 0 to use library nalloc() and nfree() functions
 */
#define LCLHEAP 0

/*	special types to distinguish usage
 */
#if 300 < _CVERSION
typedef MEMAD MEMLOC;
typedef VOID *ARBPTR;
typedef INT ARBINT;	/* things widened to int like short, regardless of sign */
#else
typedef ULONG MEMLOC;
typedef TEXT *ARBPTR;
typedef int ARBINT;
#endif
typedef BYTES INDEX;

/*	p1 still not sending FADDRs to debugger
 *  see dbvar() and paddr() in p1, for more info
 */
typedef ARBPTR P1ADDR;

/*	parameters shared between symbolic debugger and interface
 */
#define DBNAME "CDB"
#define PROMPT " :>"
#define DBBUF  128

/*	cast to (IFNC) to get void fn ptr into int fn ptr
 */
#define IFNC	ARBINT (*)()
#define PFNC	ARBPTR (*)()

/*	p1 storage class for determining data addresses
 */
#define FIX 1
#define ARG 2
#define AUT 3
#define REG 4

/*	definitions for structures used by inline debugger
 */
#define FILEFRAME struct perfileinfo
#define BLOCK struct perfuncinfo
#define DISPLAY struct stackinfo
#define VAR struct variableinfo

/*	an address term   [ {file|func()} ] : [ {var|#} ]
 */
typedef struct {
	TEXT *tfile;
	TEXT *tfunc;
	MEMLOC tnum;
	INDEX tindir;
	TEXT *tvar;
	TEXT *tcast;
	BOOL tcolon;
	BOOL exists;
	} ATERM;

/*	minimum static frame info
 *	last block is globals to the file and has NULL func field
 */
FILEFRAME {
	FILEFRAME *next;		/* initially 0 */
	TEXT *file;				/* source filename I.E. "echo.c" */
	BOOL tried;				/* internal state info */
	BLOCK *funclist;		/* NULL term list BLOCKS for this file */
	};

/*	only needed if there are new things declared
 *	currently one per function
 */
BLOCK {
	BLOCK *next;
	FILEFRAME *ff;		/* pointer to fileframe for this file */
	TEXT *func;			/* function name I.E. "main" */
	INDEX fline;		/* first line of block */
	INDEX lline;		/* last line of block (opt) */
	INDEX wid;			/* internal state info */
	VAR *locls;			/* vars declared in this block */
	};

/*	minimum dynamic frame info
 */
DISPLAY {
	DISPLAY *prev;
	BLOCK *sblk;
	INDEX slin;
	/* registers[] follow */
	};

/*	variable locator info
 *	typically there is an array of these (per BLOCK)
 *	the last has a null name field
 */
VAR {
	TEXT *vname;	/* name \0+sc */
	TEXT **vprint;	/* user spec. output fmt */
	P1ADDR vaddr;	/* offset, reg num or static addr */
	INDEX vtype;	/* ty << 8 | indir count, shdb BITS but p1 puts UI */
	};

/*	FILE: dbcall.i
 *	compiler libm calls only these
 */
VOID _dbentfunc();
VOID _dblevfunc();
VOID _dbstmt();

/*	global variables
 */
#define cmpvartot _dbvtot
#define regsav	_dbrsav
#define srch	_dbvsrch
#define stack	_dbvstack
#define ffchain _dbvfile
#define badfile _dbvfend

GLOBAL LONG cmpvartot;
GLOBAL DISPLAY *stack;
GLOBAL DISPLAY *srch;
GLOBAL FILEFRAME *ffchain;
GLOBAL FILEFRAME badfile;

/*	remap to low level underscore functions:
 *	remove to link with pre 3.00 library
 */
#if 300 <= _LVERSION 
#include <fcntl.h>
#define nalloc _nalloc
#define btoi _btoi
#define btol _btol
#define close _close
#define cmpstr _cmpstr
#define cpybuf _cpybuf
#define cpystr _cpystr
#define create(a, b, c)	_open(a, (b)|O_CREAT|O_TRUNC|((c) ? O_BIN : 0), 0666)
#define encode _encode
#define exit(y) _terminate(!y)
#define itob _itob
#define lenstr _lenstr
#define lseek _lseek
#define ltob _ltob
#define nfree _nfree
#define open(a, b, c)	_open(a, (b)|((c) ? O_BIN : 0), 0666)
#define read _read
#define scnstr _scnstr
#define tolower _tolower
#define toupper _toupper
#define write _write
#endif


/*	assigned indexes into ARBINT dispatch table
 */
#define ANYEVENTS 0
#define CASTMATCH ANYEVENTS+1
#define CLOSESRC CASTMATCH+1
#define CMPDTY CLOSESRC+1
#define CMPVAR CMPDTY+1
#define DEACTEV CMPVAR+1
#define DEBUGTOP DEACTEV+1
#define DESCVAR DEBUGTOP+1
#define DOCMD DESCVAR+1
#define DOINDIR DOCMD+1
#define GET DOINDIR+1
#define GETINDIRS GET+1
#define GETSC GETINDIRS+1
#define ISLINE GETSC+1
#define ISNUM ISLINE+1
#define ISVAR ISNUM+1
#define MKCURRENT ISVAR+1
#define NUMBERP MKCURRENT+1
#define OPENPATH NUMBERP+1
#define PRTLOC OPENPATH+1
#define PUT PRTLOC+1
#define PUTBUF PUT+1
#define PUTFBUF PUTBUF+1
#define PUTPROMPT PUTFBUF+1
#define RESETEVENTS PUTPROMPT+1
#define SETINDIRS RESETEVENTS+1
#define SHOWCURLIN SETINDIRS+1
#define SHOWLINS SHOWCURLIN+1
#define TMATCH SHOWLINS+1

#define HTINT TMATCH+1
GLOBAL ARBINT (*_dbtint[HTINT])();
#define anyevents (*_dbtint[ANYEVENTS])
#define castmatch (*_dbtint[CASTMATCH])
#define closesrc (*_dbtint[CLOSESRC])
#define cmpdty (*_dbtint[CMPDTY])
#define cmpvar (*_dbtint[CMPVAR])
#define deactev (*_dbtint[DEACTEV])
#define debug (*_dbtint[DEBUGTOP])
#define descvar (*_dbtint[DESCVAR])
#define docmd (*_dbtint[DOCMD])
#define doindir (*_dbtint[DOINDIR])
#define get (*_dbtint[GET])
#define getindirs (*_dbtint[GETINDIRS])
#define getsc (*_dbtint[GETSC])
#define isline (*_dbtint[ISLINE])
#define isnum (*_dbtint[ISNUM])
#define isvar (*_dbtint[ISVAR])
#define mkcurrent (*_dbtint[MKCURRENT])
#define numberp (*_dbtint[NUMBERP])
#define openpath (*_dbtint[OPENPATH])
#define prtloc (*_dbtint[PRTLOC])
#define put (*_dbtint[PUT])
#define putbuf (*_dbtint[PUTBUF])
#define putfbuf (*_dbtint[PUTFBUF])
#define putprompt (*_dbtint[PUTPROMPT])
#define resetevents (*_dbtint[RESETEVENTS])
#define setindirs (*_dbtint[SETINDIRS])
#define showcurlin (*_dbtint[SHOWCURLIN])
#define showlins (*_dbtint[SHOWLINS])
#define tmatch (*_dbtint[TMATCH])

/*	assigned indexes into ARBPTR dispatch table
 */
#define BUYSTR 0
#define CKEVENTS BUYSTR+1
#define DATALOC CKEVENTS+1
#define ENDTERM DATALOC+1
#define GETTERM ENDTERM+1
#define LOCVAR GETTERM+1
#define LOGFILE LOCVAR+1
#define LOOKUP LOGFILE+1
#define MKEVENT LOOKUP+1
#define MOVE MKEVENT+1
#define MUSTLOC MOVE+1
#define NBLNK MUSTLOC+1
#define NEED NBLNK+1
#define ONVARLIST NEED+1
#define PREFFMT ONVARLIST+1
#define REALFNAME PREFFMT+1
#define REDIRECT REALFNAME+1
#define RELEASE REDIRECT+1
#define RMEVENT RELEASE+1
#define SCOPE RMEVENT+1
#define SHOWFR SCOPE+1
#define SHOWVARS SHOWFR+1
#define SUBBLOCK SHOWVARS+1
#define UI SUBBLOCK+1
#define UL UI+1
#define UPDATE UL+1
#define ZEROLIST UPDATE+1

#define HTPTR ZEROLIST+1
GLOBAL ARBPTR (*_dbtptr[HTPTR])();
#define buystr (*_dbtptr[BUYSTR])
#define ckevents (*_dbtptr[CKEVENTS])
#define dataloc (*_dbtptr[DATALOC])
#define endterm (*_dbtptr[ENDTERM])
#define getterm (*_dbtptr[GETTERM])
#define locvar (*_dbtptr[LOCVAR])
#define logfile (*_dbtptr[LOGFILE])
#define lookup (*_dbtptr[LOOKUP])
#define mkevent (*_dbtptr[MKEVENT])
#define move (*_dbtptr[MOVE])
#define mustloc (*_dbtptr[MUSTLOC])
#define nblnk (*_dbtptr[NBLNK])
#define need (*_dbtptr[NEED])
#define onvarlist (*_dbtptr[ONVARLIST])
#define preffmt (*_dbtptr[PREFFMT])
#define realfname (*_dbtptr[REALFNAME])
#define redirect (*_dbtptr[REDIRECT])
#define release (*_dbtptr[RELEASE])
#define rmevent (*_dbtptr[RMEVENT])
#define scope (*_dbtptr[SCOPE])
#define showfr (*_dbtptr[SHOWFR])
#define showvars (*_dbtptr[SHOWVARS])
#define subblock (*_dbtptr[SUBBLOCK])
#define ui (*_dbtptr[UI])
#define ul (*_dbtptr[UL])
#define update (*_dbtptr[UPDATE])
#define zerolist (*_dbtptr[ZEROLIST])

/*	defined in db<mach>c.c
 */
#define getaddr _dbaddr
MEMLOC getaddr();
