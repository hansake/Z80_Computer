/*	VARIABLE ARGUMENT LIST HEADER
 *	copyright (c) 1984 by Whitesmiths, Ltd.
 */

#ifndef __STDARG__
#define __STDARG__	1

/*	type and macro declarations
 */
#ifndef __STDIO__
typedef char *va_list[2];
#endif
#ifndef _argsize
extern void *_va;
#define _argsize(ty)	(sizeof ((*(ty (*)())_va)()))
#endif
#ifndef _bndof
#define _bndof(ty)	((unsigned)&(((struct{char c;ty x;}*)0)->x))
#endif
#ifndef _bndup
#define _bndup(ptr, ty)	((unsigned)(ptr) + (_bndof(ty) - 1) & \
							~(_bndof(ty) - 1))
#endif

#define _VAOLD	0
#define _VANEW	1

/*	macros
 */
#define va_start(ap, arg) ((ap)[_VAOLD] = (char *)&(arg), \
							(ap)[_VANEW] = (ap)[_VAOLD] + sizeof (arg))
#define va_arg(ap, type) ((ap)[_VAOLD] = (char *)_bndup((ap)[_VANEW], type), \
							(ap)[_VANEW] = (ap)[_VAOLD] + _argsize(type), \
							*(type *)(ap)[_VAOLD])
#define va_end(ap)

#endif
