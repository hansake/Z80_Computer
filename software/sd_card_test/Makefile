PROTO = cxz80.pro
#ARGS = -v
ROOT = /opt/wsl/bin/
LIBDIR = /opt/wsl/lib/z80/
CMD = sh
COPY = cp -p
RM = rm -fr

TARGET = z80sdtst.bin /home/hal/Z80_computer/z80sdtst.bin

all: $(TARGET)

z80lolevio.o: z80lolevio.s Crts.s
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o z80lolevio.s
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o Crts.s

z80cio.o: z80cio.c
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z80sdtst.o: z80sdtst.c
	date +'char builddate[] = "Built %F %R";' > builddate.h
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) \
	-I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z80sdtst.80: z80lolevio.o z80cio.o z80sdtst.o
	$(ROOT)cx80 -proto $(PROTO) $(ARGS) -L$(LIBDIR) -o $@ -v -dmap $^

z80sdtst.bin: z80sdtst.80
	$(ROOT)lnk80 -h -t -rt -rd -cb -o $@ $<

/home/hal/Z80_computer/z80sdtst.bin: z80sdtst.bin
	cp $< $@

clean:
	$(RM) *.o *.80 *.map *.lnk *.ls *.err

distclean: clean
	$(RM) $(TARGET)
