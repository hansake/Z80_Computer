ROOT = /opt/wsl/bin/
LIBDIR = /opt/wsl/lib/z80/
CMD = sh
COPY = cp -p
RM = rm -fr

TARGET = wtest.bin

all: $(TARGET)

%.o: %.c
	$(ROOT)cx80 -proto cz80e.pro -I "|/opt/wsl/include/v30/" -dnostrict -s +o $<

%.o: %.s
	$(ROOT)cx80 -proto cz80e.pro +o $^

wtest.bin: crtsz80.o wtest.o
	$(ROOT)cx80 -proto cz80e.pro -L$(LIBDIR) -o $@ -v -dold -dmap $^
	cp $@ /home/hal/Z80_computer

clean:
	$(RM) *.o *.map *.lnk

distclean: clean
	$(RM) $(TARGET)

rebuild: distclean $(TARGET)

