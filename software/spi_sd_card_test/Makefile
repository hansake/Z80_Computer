ROOT = /opt/wsl/bin/
LIBDIR = /opt/wsl/lib/z80/
CMD = sh
COPY = cp -p
RM = rm -fr

TARGET = sdcardtst.bin

all: $(TARGET)

%.o: %.c
	date +'char builddate[] = "Built %F %R";' > builddate.h
	$(ROOT)cx80 -proto cz80e.pro -I "|/opt/wsl/include/v30/" -dnostrict -s +o $<

%.o: %.s
	$(ROOT)cx80 -proto cz80e.pro -dlistcs +o $^

sdcardtst.bin: crtsz80spi.o sdcardtst.o
	$(ROOT)cx80 -proto cz80e.pro -L$(LIBDIR) -o $@ -v -dold -dmap $^
	cp $@ /home/hal/Z80_computer

clean:
	$(RM) *.o *.map *.lnk

distclean: clean
	$(RM) $(TARGET)

rebuild: distclean $(TARGET)

