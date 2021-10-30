#	STANDARD ANSI C ENVIRONMENT PROTOTYPE FILE
#	For Linux
#	Programmable flag options:
#
#	64180	: generate code for 64180 instead of Z80
#	dl1	: generate line info dl1 style
#	dl2	: generate line info dl2 style
#	far	: far calls on Z80
#	float	: add floating point libraries at link time
#	lincl	: include header files in listing or diagnostic output
#	listc	: create C source listing with interspersed error messages
#	listcs	: create c/assembler listing
#	map	: create a map file (r).map
#	nobss	: do not use the bss section
#	noopt	: do not do optimize assembler code
#	nostrict: allow more lenient type checking
#	old     : link in old whitesmiths library routines
#	prom	: move rom to ram on startup
#	proto	: enable prototype checking
#	rev	: reorder bits inbitfields from most to least significant
#	savlnk	: save the linker file
#	schar	: make "plain" char signed char (default is unsigned)
#	sp	: enable single precision with double precision
#	std	: force the output to conform to ANSI C draft standard
#	strict	: enforce more stronger tye checking
#	sprec	: generate code for single-precision floating point
#		  double are converted to float
#	verbose	: display name of C functions as they are processed by the
#		  code generator
#	xdebug	: generate debugging info for cxdb
c:(e)cpp80	-o (o) -x {lincl?+lincl} {proto?-d_PROTO} \
		{std?+std} {listc?-err} \
		{listcs?-err} -i (h) \
		{dl1?+lincl:{dl2?+lincl}} {xdebug?+xdebug} \
		(i)

1:(e)cp180	-o (o) -sr -m {schar?:-u} {std?+std}  \
		{listcs?-err} {listc? -err > (r).err} \
		{nostrict?-strict} {strict?+strict} \
		{xdebug?+xdebug} {dl1?-dl:{dl2?-dl}} \
		{sprec?-sp} \
		(i)

2:(e)cp280	-o (o) -x4 {64180?-h64180} {far?-far} \
		{nobss? -bss} {listcs?+list -err} \
		{dl1?-dl1:{dl2?-dl2}} \
		{rev?-rev} {sp?-sp} \
		{verbose?-v} \
		(i)

3:(e)cp380	-o (o) {noopt?-z} -e -r30 (i)

s:(e)x80	-o (o) {listcs?+l >(r).ls} (i)

o::echo		 -o (o) -h -t -rt -rd -cb > (r).lnk
 echo		{map?+map=(r).map} \
		+text -b0x0000 \
		(i) {old?(l)olib.80} >> (r).lnk
 echo		(l)lib{sprec?f:d}.80 (l)libi.80 (l)libm.80 >> (r).lnk
 echo		+def __memory=__bss__  >> (r).lnk
 (e)lnk80 < (r).lnk
80:
