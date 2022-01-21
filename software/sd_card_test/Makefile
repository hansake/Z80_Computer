PROTO = cxz80.proto
ARGS = -dprom -dsavlnk
ROOT = /opt/wsl/bin/
LIBDIR = /opt/wsl/lib/z80/
CMD = sh
COPY = cp -p
RM = rm -fr

TARGET = z80boot.bin /home/hal/Z80_computer/z80boot.bin \
	z80sdtst.bin /home/hal/Z80_computer/z80sdtst.bin

all: $(TARGET)

z80aio.o: z80aio.s Crts.s Crtsrom.s
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o z80aio.s
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o Crts.s
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o Crtsrom.s

z80cio.o: z80cio.c
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z80boot.o: z80boot.c
	date +'const char builddate[] = "Built %F %R";' > builddate.h
	echo "#define Z80BOOT 1" > progtype.h
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z80sdtst.c: z80boot.c
	cp $< $@

z80sdtst.o: z80sdtst.c
	date +'const char builddate[] = "Built %F %R";' > builddate.h
	echo "#define SDTEST 1" > progtype.h
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z80boot.80: z80aio.o z80cio.o z80boot.o
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -L$(LIBDIR) -o $@ -v -dmap $^

z80boot.bin: z80boot.80
	$(ROOT)hex80 -o $<.hex $<
	$(ROOT)unhex -o $@ $<.hex

z80sdtst.80: z80aio.o z80cio.o z80sdtst.o
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -L$(LIBDIR) -o $@ -v -dmap $^

z80sdtst.bin: z80sdtst.80
	$(ROOT)hex80 -o $<.hex $<
	$(ROOT)unhex -o $@ $<.hex

/home/hal/Z80_computer/z80boot.bin: z80boot.bin
	cp $< $@
	cp $< /home/hal/VirtualBox_shared/Z80/

/home/hal/Z80_computer/z80sdtst.bin: z80sdtst.bin
	cp $< $@
	cp $< /home/hal/VirtualBox_shared/Z80/

clean:
	$(RM) *.o *.80 *.map *.lnk *.ls *.err

distclean: clean
	$(RM) $(TARGET)
