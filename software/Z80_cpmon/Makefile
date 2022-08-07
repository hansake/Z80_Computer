# Makefile to build CP/M and BIOS
# for my DIY Z80 computer with
# a SD card disk
#
include gmsl

# Build configuration
#
PROTO = cxz80.proto
ARGS = -dprom -dsavlnk
EXECDIR = ../tools/wsl/bin/
LIBDIR = ../tools/wsl/lib/z80/
INCLDIR = ../tools/wsl/include/v30/

TARGET = z80cpmon.bin
OBJFILES = z80aio.o z80cio.o z80sdasm.o z80sddrv.o z80sdrdwr.o z80sddrvprt.o z80sdpart.o z80sdparprt.o z80cpmon.o z80uplbinc.o builddate.o cpmsys.o

all: $(TARGET)

z80aio.o: z80aio.s Crtsrom.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o z80aio.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o Crtsrom.s

toram.o: toram.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o toram.s

z80sdasm.o: z80sdasm.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o z80sdasm.s

z80cio.o: z80cio.c z80comp.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80sddrv.o: z80sddrv.c z80comp.h z80sd.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80sdrdwr.o: z80sdrdwr.c z80comp.h z80sd.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80sddrvprt.o: z80sddrvprt.c z80comp.h z80sd.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80sdpart.o: z80sdpart.c z80comp.h z80sd.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80sdparprt.o: z80sdparprt.c z80comp.h z80sd.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80cpmon.o: z80cpmon.c z80comp.h z80sd.h cpmbiosadr.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

builddate.o: builddate.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80uplbinc.o: z80uplbinc.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

z80uplbinc.c: z80upload.bin
	$(EXECDIR)bintoc -v -n upload -o $@ $^

z80upload.bin: z80upload.80
	stripmhdr -o $@ $<

z80upload.80: z80upload.o
	lnk80 -o $@ +map=$(basename $@).map -t -rt -rd -cb +h \
	+text -b0xb000 z80upload.o

z80upload.o: z80upload.s
	x80 -o $@ +l > $(basename $<).ls $<

cpmsys.o: cpmsys.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

cpmsys.c: cpmsys.bin
	$(EXECDIR)bintoc -v -n cpmsys -o $@ $^

builddate.c:
	date +'const char builddate[] = "built %F %R";' > builddate.c

z80cpmon.80: $(OBJFILES)
	date +'const char builddate[] = "built %F %R";' > builddate.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o builddate.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -L$(LIBDIR) -o $@ -v -dmap $^

z80cpmon.bin: z80cpmon.80
	$(EXECDIR)hex80 -o $(basename $@).hex $<
	$(EXECDIR)unhex -o $@ $(basename $@).hex
	$(EXECDIR)sizinbin $@

# The CP/M and BIOS code is built and linked with the monitor
SDCODE = z80sdio.o z80sdbiorw.o

# The link addresses for CCP and BDOS are calculated
# backwards from where the BIOS starts.
# The size of BIOS may be from end of BDOS
# to end of memory.
BIOSADR = 0xee00
# size of BDOS: 0xe00 (3584) bytes
BDOSADR = $(shell printf "0x%x" $(call subtract, \
              $(shell printf "%d" $(BIOSADR)), 3584))
# size of CPP: 0x800 (2048) bytes
CCPADR = $(shell printf "0x%x" $(call subtract, \
              $(shell printf "%d" $(BDOSADR)), 2048))

cpmsys.bin: cpmsys.80
	stripmhdr -o $@ $<

cpmsys.80: ccp.o bdos.o z80bios.o $(SDCODE)
	lnk80 -o $@ +map=$(basename $@).map -t -rt -rd -cb +h \
	+text -b$(CCPADR) +def ccp=__text__ ccp.o \
	+text -b$(BDOSADR) +def bdos=__text__ bdos.o \
	+text -b$(BIOSADR) +def bios=__text__ z80bios.o $(SDCODE) $(LIBDIR)/libi.z80 $(LIBDIR)/libm.z80

cpmbiosadr.h:
	echo "#define BIOSADR $(BIOSADR)" > cpmbiosadr.h
	echo "#define CCPADR $(CCPADR)" >> cpmbiosadr.h

bdos.o: bdos.s cpm.inc
	x80 -o $@ +l > $(basename $<).ls $<

ccp.o: ccp.s cpm.inc
	x80 -o $@ +l > $(basename $<).ls $<

z80bios.o: z80bios.s cpm.inc z80comp.inc
	x80 -o $@ +l > $(basename $<).ls $<

z80sdio.o: z80sdio.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o $<

z80sdbiorw.o: z80sdbiorw.c z80comp.h z80sd.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|$(INCLDIR)" -dlistcs -dnostrict -s +o $<

clean:
	rm -f *.o *.80 *.map *.lnk *.ls *.err *.bin *.hex \
	cpmsys.c z80uplbinc.c builddate.c cpmbiosadr.h
