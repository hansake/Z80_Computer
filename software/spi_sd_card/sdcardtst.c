/* sdcardtst.c
 *
 *  Test Z80 SPI/SD card interface on Z80 Computer
 *  program compiled with Whitesmiths compiler
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties given.
 *  Hastily Cobbled Together 2021 by Hans-Ake Lund
 *
 *  This code was hacked together to implement/test
 *  a "bit-banger" SPI interface to a SD card for
 *  the Z80 computer.
 *  (in the process the Whitesmith C compiler for
 *  Z80 was also rather thoroughly tested)
 *
 *  The intention is to clean up this code and
 *  use it as a base for a SD card driver for CP/M.
 */

#include <std.h>
#include "z80computer.h"
#include "builddate.h"

/* the btod() function is needed by linker but not used.
   The encode() function in olib.80 us using if for handling type double.
   TODO: investigate further how to fix the library */
btod() {prtstr("\r\n--- btod dummy function ---\r\n");}

char txtin[81];
char txtout[256];
int debugflg = 0;
int ready = NO;
unsigned char *dataptr;
unsigned char *rxtxptr = NULL;
unsigned long blockno = 0;

/* Print character on serial port A */
void putc(char pchar)
	{
	while ((in(SIO_A_CTRL) & 0x04) == 0) /* wait for tx buffer empty */
		;
	out(SIO_A_DATA, pchar);
	}

/* Print character on serial port B */
void putcb(char pchar)
	{
	while ((in(SIO_B_CTRL) & 0x04) == 0) /* wait for tx buffer empty */
		;
	out(SIO_B_DATA, pchar);
	}

/* Print string on serial port A */
void prtstr(char *str)
	{
	while (*str)
		putc(*str++);
	}

/* Get character from serial port A */
int getc()
	{
	while (!(in(SIO_A_CTRL) & 0x01)) /* test and loop until character available */
		;
	return  (in(SIO_A_DATA));
	}

/* Get line from keyboard
 * edit line with BS
 * returns when CR or Ctrl-C is entered
 * return value is length of entered string
 */
int getkline(char *txtinp)
	{
	int ncharin;
	char charin;

	for (ncharin = 0; ncharin < 80; ncharin++)
		{
		charin = getc();
		if (charin == '\r') /* CR */
			{
			*txtinp = 0;
			return (ncharin);
			}
		else if (charin == 3) /* Ctrl-C */
			return (0);
		else if (charin == '\b') /* BS */
			{
			if (0 < ncharin)
				{
				prtstr("\b \b");
				ncharin--;
				txtinp--;
				}
			}
		else
			{
			putc(charin);
			*txtinp++ = charin;
			ncharin++;
			}
		}
	*txtinp = 0;
	return (ncharin);
	}

/* Status LED on */
void ledon()
	{
	out(LEDON, 1);
	}

/* Status LED off */
void ledoff()
	{
	out(LEDOFF, 0);
	}

/* send command to SD card and recieve answer
 * returns a pointer to the response
 */
unsigned char *sdcommand(unsigned char *sndbuf, int sndbytes, unsigned char *recbuf, int recbytes)
	{
	int bitsearch;
	int chars;
	int debugnl;
	unsigned char *retptr;
	unsigned int rbyte;
	unsigned int sbyte;

	if (debugflg)
		{
		prtstr("(snd)");
		debugnl = 0;
		}
	for (; 0 < sndbytes; sndbytes--)
		{
		sbyte = *sndbuf++;
		rbyte = (spiio(sbyte) & 0xff);
		if (debugflg)
			{
			chars = decode(txtout, sizeof(txtout),
				">%+02hi<%+02hi,", sbyte, rbyte);
			/* decode does not terminate output string? */
			txtout[chars] = 0;
			prtstr(txtout);
			if (7 < debugnl++)
				{
				prtstr("\r\n");
				debugnl = 0;
				}
			putcb('*');
			}
		}
	if (debugflg)
		prtstr("\r\n");

	bitsearch = YES;
	retptr = recbuf;
	if (debugflg)
		{
		prtstr("(rec)");
		debugnl = 0;
		}
	for (; 0 < recbytes; recbytes--)
		{
		sbyte = 0xff;
		rbyte = (spiio(sbyte) & 0xff);
		*recbuf = rbyte;
		if (bitsearch && ((rbyte & 0x80) == 0))
			{
			retptr = recbuf;
			bitsearch = NO;
			}
		recbuf++;
		if (debugflg)
			{
			chars = decode(txtout, sizeof(txtout),
				">%+02hi<%+02hi,", sbyte, rbyte);
			txtout[chars] = 0;
			prtstr(txtout);
			if (7 < debugnl++)
				{
				prtstr("\r\n");
				debugnl = 0;
				}
			putcb('-');
			}
		}
	if (debugflg)
		{
		prtstr("\r\n");
		putcb('\r');
		putcb('\n');
		}

	return (retptr);
	}

/* The SD card commands with two "idle" bytes in the beginning
 * and (at least for CMD0) a CRC7 byte as the last one.
 */
unsigned char cmd0[] = {0xff, 0xff, 0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
unsigned char cmd8[] = {0xff, 0xff, 0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
unsigned char cmd9[] = {0xff, 0xff, 0x49, 0x00, 0x00, 0x00, 0x00, 0x01};
unsigned char cmd10[] = {0xff, 0xff, 0x4a, 0x00, 0x00, 0x00, 0x00, 0x01};
unsigned char cmd55[] = {0xff, 0xff, 0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
unsigned char cmd58[] = {0xff, 0xff, 0x7a, 0x00, 0x00, 0x00, 0x00, 0x01};
unsigned char acmd41[] = {0xff, 0xff, 0x69, 0x40, 0x00, 0x01, 0xaa, 0x77};

unsigned char rxbuf[520] = {0};
unsigned char statbuf[20] = {0};

/* initialise SD card interface */
void sdinit()
	{
	unsigned char *prtptr;
	unsigned char *statptr;
	int chars;
	int rxbytes;
	int tries;

	ledon();

	/* start to generate 8 clock pulses with not selected SD card */
	spideselect();

	statptr = sdcommand(0, 0, rxbuf, 8);
	prtstr("Sent 8 clock pulses\r\n");

	spiselect();

	/* CMD0: GO_IDLE_STATE */
	statptr = sdcommand(cmd0, sizeof cmd0, rxbuf, 8);
	chars = decode(txtout, sizeof(txtout), "CMD0 R1 response 0x%+02hi\r\n", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);

	/* CMD8: SEND_IF_COND */
	statptr = sdcommand(cmd8, sizeof cmd8, rxbuf, 8);
	chars = decode(txtout, sizeof(txtout),
		"CMD8 R7 response 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi\r\n",
		 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
	txtout[chars] = 0;
	prtstr(txtout);

	/* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
	for (tries = 0; tries < 8; tries++)
		{
		statptr = sdcommand(cmd55, sizeof cmd55, rxbuf, 8);
		chars = decode(txtout, sizeof(txtout), "CMD55 R1 response 0x%+02hi\r\n", statptr[0]);
		txtout[chars] = 0;
		prtstr(txtout);

		statptr = sdcommand(acmd41, sizeof acmd41, rxbuf, 8);
		chars = decode(txtout, sizeof(txtout), "ACMD41 R1 response 0x%+02hi\r\n", statptr[0]);
		txtout[chars] = 0;
		prtstr(txtout);
		if (*statptr == 0x00)
			break;
		}

	/* CMD58: READ_OCR */
	statptr = sdcommand(cmd58, sizeof cmd58, rxbuf, 8);
	chars = decode(txtout, sizeof(txtout),
		"CMD58 R3 response 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi\r\n",
		 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
	txtout[chars] = 0;
	prtstr(txtout);


	/* CMD10: SEND_CID */
	statptr = sdcommand(cmd10, sizeof cmd10, rxbuf, 20);
	chars = decode(txtout, sizeof(txtout), "CMD10 R1 response 0x%+02hi, ", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
		; /* looking for 0xfe that is the byte before data */
	if (*statptr != 0xfe)
		{
		prtstr("no data found\r\n");
		}
	else
		{
		statptr++;
		prtptr = statptr;
		prtstr("CID data:\r\n");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			{
			chars = decode(txtout, sizeof(txtout), "%+02hi ", *prtptr);
	                txtout[chars] = 0;
        	        prtstr(txtout);
			}
		prtptr = statptr;
		prtstr(" |");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			{
			if ((' ' <= *prtptr) && (*prtptr < 127))
				putc(*prtptr);
			else
				putc('.');
			}
		prtstr("|\r\n");
		}

	/* CMD9: SEND_CSD */
	statptr = sdcommand(cmd9, sizeof cmd9, rxbuf, 20);
	chars = decode(txtout, sizeof(txtout), "CMD9 R1 response 0x%+02hi, ", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
		; /* looking for 0xfe that is the byte before data */
	if (*statptr != 0xfe)
		{
		prtstr("no data found\r\n");
		}
	else
		{
		statptr++;
		prtptr = statptr;
		prtstr("CSD data:\r\n");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			{
			chars = decode(txtout, sizeof(txtout), "%+02hi ", *prtptr);
	                txtout[chars] = 0;
        	        prtstr(txtout);
			}
		prtptr = statptr;
		prtstr(" |");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			{
			if ((' ' <= *prtptr) && (*prtptr < 127))
				putc(*prtptr);
			else
				putc('.');
			}
		prtstr("|\r\n");
		}

	ready = YES;
	spideselect();
	ledoff();

	/* maybe more to go here */
	}

/* CMD17 is the read block command */
unsigned char cmd17[] = {0xff, 0xff, 0x51, 0x00, 0x00, 0x00, 0x00, 0xff};

/* read data block */
void sdread()
	{
	unsigned char *rxdata;
	unsigned char *statptr;
	int chars;
	int dmpline;
	int rxbytes;
	int tries;
	unsigned long blktoread;

	ledon();
	spiselect();

	if (!ready)
		{
		prtstr("SD card not initialized\r\n");
		spideselect();
		ledoff();
		return;
		}

	/* CMD17: READ_SINGLE_BLOCK */
	/* Insert block # into command */
	blktoread = blockno;
	cmd17[6] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd17[5] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd17[4] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd17[3] = blktoread & 0xff;
	blktoread = blktoread >> 8;

	statptr = sdcommand(cmd17, sizeof cmd17, rxbuf, 530);
	chars = decode(txtout, sizeof(txtout), "CMD17 R1 response 0x%+02hi, ", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	if (statptr[0])
		{
		prtstr("could not read block\r\n");
		spideselect();
		ledoff();
		return;
		}
	for (tries = 0; (tries < 80) && (*statptr != 0xfe); tries++, statptr++)
		;
	if (*statptr != 0xfe)
		{
		prtstr("no data found\r\n");
		}
	else
		{
		dataptr = statptr + 1;
		rxdata = dataptr;
		rxtxptr = dataptr;
		chars = decode(txtout, sizeof(txtout), "Data block %ul:\r\n", blockno);
		txtout[chars] = 0;
		prtstr(txtout);
		chars = decode(txtout, sizeof(txtout),
			"Recieved CRC16 0x%+02hi 0x%+02hi\r\n",
			rxdata[0x200], rxdata[0x201]);
	       	txtout[chars] = 0;
		prtstr(txtout);
		/* TODO:  check CRC */
		}

	spideselect();
	ledoff();

	}

/* CMD24 is the write block command */
unsigned char cmd24[] = {0xff, 0xff, 0x58, 0x00, 0x00, 0x00, 0x00, 0xff};

/* write data block */
void sdwrite()
	{
	unsigned char *txdata;
	unsigned char *statptr;
	int chars;
	int prtline;
	int txbytes;
	unsigned long blktoread;

	ledon();
	spiselect();

	if (!rxtxptr)
		{
		prtstr("no data in buffer to write\r\n");
		spideselect();
		ledoff();
		return;
		}

	/* CMD17: READ_SINGLE_BLOCK */
	/* Insert block # into command */
	blktoread = blockno;
	cmd24[6] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd24[5] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd24[4] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd24[3] = blktoread & 0xff;
	blktoread = blktoread >> 8;

	statptr = sdcommand(cmd24, sizeof cmd24, statbuf, 8);
	chars = decode(txtout, sizeof(txtout), "CMD24 R1 response 0x%+02hi, ", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	dataptr = rxtxptr;
	txdata = dataptr;
	chars = decode(txtout, sizeof(txtout), "Data block %ul:\r\n", blockno);
	txtout[chars] = 0;
	prtstr(txtout);
	/* send data */
	sdcommand(txdata - 1, 512 + 3, statbuf, 8);
	/* check data resp. */
	for (statptr = statbuf; (*statptr & 0x11) != 0x01; statptr++)
		;
	chars = decode(txtout, sizeof(txtout), "Data response 0x%+02hi, ", 0x1f & statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout),
		"Transmitted CRC16 0x%+02hi 0x%+02hi\r\n",
		txdata[0x200], txdata[0x201]);
	txtout[chars] = 0;
	prtstr(txtout);

	spideselect();
	ledoff();
	}

/* print the SD data buffer */
void sddatprt()
	{
	unsigned char *rxdata;
	unsigned char *statptr;
	int chars;
	int dmpline;
	int rxbytes;
	int tries;
	int allzero, lastallz, dotprted;

	if (!rxtxptr)
		{
		prtstr("no data read into buffer\r\n");
		return;
		}
	dataptr = rxtxptr;
	rxdata = dataptr;
	chars = decode(txtout, sizeof(txtout), "Data block %ul:\r\n", blockno);
	txtout[chars] = 0;
	prtstr(txtout);
	dotprted = NO;
	lastallz = NO;
	for (dmpline = 0; dmpline < 32; dmpline++)
		{
		/* test if all 16 bytes are 0x00 */
		allzero = YES;
		for (rxbytes = 0; rxbytes < 16; rxbytes++)
			{
			if (dataptr[rxbytes] != 0)
				allzero = NO;
			}
		if (lastallz && allzero)
			{
			if (!dotprted)
				{
				prtstr("*\r\n");
				dotprted = YES;
				}
			}
		else
			{
			dotprted = NO;
			/* print offset */
			chars = decode(txtout, sizeof(txtout), "%+04hi ", dmpline * 16);
        	        txtout[chars] = 0;
			prtstr(txtout);
			/* print 16 bytes in hex */
			for (rxbytes = 0; rxbytes < 16; rxbytes++)
				{
				chars = decode(txtout, sizeof(txtout), "%+02hi ", dataptr[rxbytes]);
                		txtout[chars] = 0;
       	        		prtstr(txtout);
				}
			/* print these bytes in ASCII if printable */
			prtstr(" |");
			for (rxbytes = 0; rxbytes < 16; rxbytes++)
				{
				if ((' ' <= dataptr[rxbytes]) && (dataptr[rxbytes] < 127))
					putc(dataptr[rxbytes]);
				else
					putc('.');
				}
			prtstr("|\r\n");
				}
		dataptr += 16;
		lastallz = allzero;
		}
	chars = decode(txtout, sizeof(txtout),
		"Recieved CRC16 0x%+02hi 0x%+02hi\r\n",
		rxdata[0x200], rxdata[0x201]);
       	txtout[chars] = 0;
	prtstr(txtout);
	}

/* Test init, read and write on SD card over the SPI interface
 *
 */
int main()
	{
	int chars;
	int cmdin;
	int inlength;

	while (YES) /* forever (until Ctrl-C) */
		{
		prtstr("\r\nsdcardtst version 0.8, ");
		prtstr(builddate);
		prtstr("\r\n");
		prtstr("Commands:\r\n");
		prtstr("  d - byte level debug on\r\n");
		prtstr("  o - byte level debug off\r\n");
		prtstr("  i - initialize\r\n");
		prtstr("  n - set block #N to read/write\r\n");
		prtstr("  r - read block #N\r\n");
		prtstr("  w - write block #N\r\n");
		prtstr("  p - print block last read or written\r\n");
		prtstr("  Ctrl-C to reload monitor.\r\n");
		prtstr("cmd: ");

		cmdin = getc();
		switch (cmdin)
			{
			case 'd':
				debugflg = YES;
				prtstr(" d - debug on\r\n");
				break;
			case 'o':
				debugflg = NO;
				prtstr(" o - debug off\r\n");
				break;
			case 'i':
				prtstr(" i - initialize SD card\r\n");
				sdinit();
				break;
			case 'n':
				prtstr(" n - block number: ");
				if (inlength = getkline(txtin))
					{
					encode(txtin, inlength, "%ul", &blockno);
					prtstr("\r\n");
					}
				break;
			case 'r':
				prtstr(" r - read block\r\n");
				sdread();
				break;
			case 'w':
				prtstr(" w - write block\r\n");
				sdwrite();
				break;
			case 'p':
				prtstr(" p - print data block\r\n");
				sddatprt();
				break;
			case 0x03: /* Ctrl-C */
				prtstr("reloading monitor from EPROM\r\n");
				reload();
				break; /* not really needed, will never get here */
			default:
				prtstr(" command not implemented yet\r\n");
			}
		}
	}

