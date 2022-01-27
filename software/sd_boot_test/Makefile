# Makefile to build boot and SD card test program
# for my DIY Z80 computer
# the boot and upload parts are not ready yet.
#
PROTO = cxz80.proto
ARGS = -dprom -dsavlnk
EXECDIR = /opt/wsl/bin/
LIBDIR = /opt/wsl/lib/z80/
CMD = sh
COPY = cp -p
RM = rm -fr

TARGET = z80sdbt.bin /home/hal/Z80_computer/z80sdbt.bin

all: $(TARGET)

z80aio.o: z80aio.s Crtsrom.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o z80aio.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o Crtsrom.s

z80cio.o: z80cio.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z80sdbt.o: z80sdbt.c
	date +'const char builddate[] = "Built %F %R";' > builddate.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z80sdbt.80: z80aio.o z80cio.o z80sdbt.o
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -L$(LIBDIR) -o $@ -v -dmap $^

z80sdbt.bin: z80sdbt.80
	$(EXECDIR)hex80 -o $(basename $@).hex $<
	$(EXECDIR)unhex -o $@ $(basename $@).hex

/home/hal/Z80_computer/z80sdbt.bin: z80sdbt.bin
	cp $< $@
	cp $< /home/hal/VirtualBox_shared/Z80/

clean:
	$(RM) *.o *.80 *.map *.lnk *.ls *.err

distclean: clean
	$(RM) $(TARGET)
