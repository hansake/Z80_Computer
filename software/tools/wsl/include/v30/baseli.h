/*	INTERNAL BASE LIBRARY HEADER
 *	copyright (c) 1985 by Whitesmiths, Ltd.
 */

#ifndef	__BASELI__
#define	__BASELI__	1

/*	internal ANSI function declarations
 */
BOOL _cache __((TEXT *s, COUNT n, TEXT **sp));
BYTES _dtog __((TEXT *is, DOUBLE d, BYTES p, BYTES g, BOOL strip));
BYTES _putbuf __((TEXT *s, BYTES n, struct _file *pf));
INT _print __((VOID (*pfn)(), VOID *arg, TEXT *f, ...));
INT _scan __((TEXT *p, BOOL isstr, TEXT *s, ...));

/*	internal base function declarations
 *	this header is included after wslxa.h
 */
ARGINT _doread __((struct _file *pf, UTINY *buf, BYTES size));
ARGINT _kill __((ARGINT pid, ARGINT sig));
ARGINT _read __((FD fd, TEXT *buf, ARGINT size));
ARGINT _trunc __((DOUBLE d));
ARGINT _write __((FD fd, TEXT *buf, ARGINT size));
BITS _parstype __((TEXT *s));
BOOL _chkio __((struct _file *pf, BOOL iswrite));
BOOL _cmpbuf __((TEXT *s1, TEXT *s2, BYTES n));
BOOL _cmpstr __((TEXT *s1, TEXT *s2));
BOOL _doclose __((struct _file *pf, BOOL rid));
BOOL _dowrite __((struct _file *pf, UTINY *buf, BYTES size));
BOOL _flush __((FD fd));
BOOL _isindst __((BYTES day, BYTES dwk, BYTES yr, BYTES hr));
BOOL _prefix __((TEXT *s1, TEXT *s2));
BOOL _remark __((TEXT *s1, TEXT *s2));
BYTES _balheap __((VOID));
BYTES _btod __((TEXT *is, BYTES n, DOUBLE *pdnum));
BYTES _btoi __((TEXT *s, BYTES n, BYTES *i, COUNT base));
BYTES _btol __((TEXT *s, BYTES n, ULONG *l, COUNT base));
BYTES _btos __((TEXT *s, BYTES n, UCOUNT *i, COUNT base));
BYTES _cpybuf __((TEXT *s1, TEXT *s2, BYTES an));
BYTES _dmth __((BYTES mth, BYTES yr));
BYTES _dtoe __((TEXT *is, DOUBLE d, COUNT p, COUNT g));
BYTES _dtof __((TEXT *is, DOUBLE d, COUNT p, COUNT g));
BYTES _dyr __((BYTES yr));
BYTES _fsb __((BYTES dyr, BYTES tdyr, BYTES tdwk, BYTES year));
BYTES _itob __((TEXT *is, ARGINT n, COUNT base));
BYTES _lenstr __((TEXT *is));
BYTES _ltob __((TEXT *is, LONG ln, COUNT base));
BYTES _scnbuf __((TEXT *s, BYTES n, TEXT c));
BYTES _scnstr __((TEXT *s, TEXT c));
BYTES _stob __((TEXT *is, COUNT n, COUNT base));
COUNT _close __((FD fd));
COUNT _encode __((TEXT *s, BYTES n, TEXT *f, ...));
COUNT _fcan __((TEXT *pd));
COUNT _fmod __((DOUBLE *pd, DOUBLE mul));
COUNT _frac __((DOUBLE *pd, DOUBLE mul));	/* moribund */
COUNT _ftrunc __((DOUBLE *pi));
COUNT _getf __((COUNT (*pfn)(), VOID *arg, TEXT *f, ...));
COUNT _norm __((TEXT *s, DOUBLE d, BYTES p));
COUNT _rawmode __((FD fd, COUNT new));
COUNT _remove __((TEXT *fname));
COUNT _rename __((TEXT *old, TEXT *new));
COUNT _round __((TEXT *s, COUNT n, COUNT p));
COUNT _system __((TEXT *cmd));
COUNT _unpack __((DOUBLE *pd));
COUNT _when __((TEXT **ptr, ...));
DOUBLE _abs __((DOUBLE d));
DOUBLE _addexp __((DOUBLE d, COUNT n, TEXT *msg));
DOUBLE _atan2 __((DOUBLE y, DOUBLE x));
DOUBLE _dtento __((DOUBLE d, COUNT exp));
DOUBLE _exp __((DOUBLE x, COUNT n, TEXT *mesg));
DOUBLE _ln __((DOUBLE x, DOUBLE scale, TEXT *mesg));
DOUBLE _poly __((DOUBLE d, DOUBLE *tab, COUNT n));
DOUBLE _range __((TEXT *msg));
DOUBLE _sin __((DOUBLE x, COUNT quad));
DOUBLE _sqr __((DOUBLE d));
DOUBLE _sqrt __((DOUBLE x, TEXT *mesg));
FD _open __((TEXT *fname, BITS oflag, BITS mode, ...));
#if 300 <= _CVERSION
FNPTR _doflush __((VOID));
FNPTR _onexit __((FNPTR (*pfn)()));
#endif
LONG _lseek __((FD fd, LONG offset, COUNT sense));
TEXT *_convrt __((BYTES rsize));
TEXT *_cpystr __((TEXT *dest, ...));
TEXT *_getenv __((TEXT *name));
TEXT *_uniqnm __((VOID));
ULONG _time __((VOID));
ULONG _ultime __((struct _tvec *pv));
VOID *_alloc __((BYTES need, VOID *link));
VOID *_free __((VOID *addr, VOID *link));
VOID *_nfree __((VOID *addr, VOID *link));
VOID *_nalloc __((BYTES need, VOID *link));
VOID *_onlist __((VOID *p, VOID **phead));
VOID *_realloc __((VOID *ptr, BYTES size));
VOID *_sbreak __((BYTES size));
VOID (*_signal __((ARGINT sig, VOID (*pfunc)())))();
VOID _domain __((TEXT *msg));
VOID _error __((TEXT *s1, TEXT *s2));
VOID _exit __((BOOL status));
VOID _getzone __((VOID));
VOID _onintr __((VOID (*pfn)()));
VOID _putf __((VOID (*pfn)(), VOID *arg, TEXT *f, ...));
VOID _putstr __((FD fd, ...));
VOID _raise __((TEXT **ptr, TEXT **cx));
VOID _terminate __((BOOL status));
struct _file *_finit __((struct _file *pf, FD fd, BITS mode));
struct _hinfo *_lstheap __((VOID (*pfn)()));

#endif
