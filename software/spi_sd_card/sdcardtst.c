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

#define SDTSTVER "\r\nsdcardtst version 1.2, "

unsigned char ocrreg[4] = {0};
unsigned char cidreg[16] = {0};
unsigned char csdreg[16] = {0};

char txtin[81];
char txtout[256];
int debugflg = 0;
int ready = NO;
unsigned char *dataptr;
unsigned char *rxtxptr = NULL;
unsigned long blockno = 0;
unsigned long blkmult = 1;

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

/* CRC routines from:
https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
*/

/*
// Calculate CRC7
// It's a 7 bit CRC with polynomial x^7 + x^3 + 1
// input:
//   crcIn - the CRC before (0 for first step)
//   data - byte for CRC calculation
// return: the new CRC7
*/
unsigned char CRC7_one(unsigned char crcIn, unsigned char data)
	{
	const unsigned char g = 0x89;
	unsigned char i;

	crcIn ^= data;
	for (i = 0; i < 8; i++)
		{
		if (crcIn & 0x80) crcIn ^= g;
		crcIn <<= 1;
		}

	return crcIn;
	}

/*
// Calculate CRC7 value of the buffer
// input:
//   pBuf - pointer to the buffer
//   len - length of the buffer
// return: the CRC7 value
*/
unsigned char CRC7_buf(unsigned char *pBuf, unsigned char len)
	{
	unsigned char crc = 0;

	while (len--)
		crc = CRC7_one(crc,*pBuf++);

	return crc;
	}

/*
// Calculate CRC16 CCITT
// It's a 16 bit CRC with polynomial x^16 + x^12 + x^5 + 1
// input:
//   crcIn - the CRC before (0 for rist step)
//   data - byte for CRC calculation
// return: the CRC16 value
*/
unsigned int CRC16_one(unsigned int crcIn, unsigned char data)
	{
	crcIn  = (unsigned char)(crcIn >> 8)|(crcIn << 8);
	crcIn ^=  data;
	crcIn ^= (unsigned char)(crcIn & 0xff) >> 4;
	crcIn ^= (crcIn << 8) << 4;
	crcIn ^= ((crcIn & 0xff) << 4) << 1;

	return crcIn;
	}

/*
// Calculate CRC16 CCITT value of the buffer
// input:
//   pBuf - pointer to the buffer
//   len - length of the buffer
// return: the CRC16 value
*/
unsigned int CRC16_buf(const unsigned char * pBuf, unsigned int len)
	{
	unsigned int crc = 0;

	while (len--)
		crc = CRC16_one(crc,*pBuf++);

	return crc;
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
unsigned char cmd9[] = {0xff, 0xff, 0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
unsigned char cmd10[] = {0xff, 0xff, 0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
unsigned char cmd16[] = {0xff, 0xff, 0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
unsigned char cmd55[] = {0xff, 0xff, 0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
unsigned char cmd58[] = {0xff, 0xff, 0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
unsigned char acmd41[] = {0xff, 0xff, 0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};

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
	chars = decode(txtout, sizeof(txtout),
		"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
		/* bit 0 of last byte is always 1 (end bit) */
		cmd0[7], CRC7_buf(&cmd0[2], 5) | 0x01);
	txtout[chars] = 0;
	prtstr(txtout);

	/* CMD8: SEND_IF_COND */
	statptr = sdcommand(cmd8, sizeof cmd8, rxbuf, 8);
	chars = decode(txtout, sizeof(txtout),
		"CMD8 R7 response 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi\r\n",
		 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout),
		"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
		/* bit 0 of last byte is always 1 (end bit) */
		cmd8[7], CRC7_buf(&cmd8[2], 5) | 0x01);
	txtout[chars] = 0;
	prtstr(txtout);
	if ((statptr[3] & 0x0f) == 0x01)
		prtstr("  Voltage accepted: 2.7-3.6V\r\n");

	/* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
	for (tries = 0; tries < 8; tries++)
		{
		statptr = sdcommand(cmd55, sizeof cmd55, rxbuf, 8);
		chars = decode(txtout, sizeof(txtout), "CMD55 R1 response 0x%+02hi\r\n", statptr[0]);
		txtout[chars] = 0;
		prtstr(txtout);
		chars = decode(txtout, sizeof(txtout),
			"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
			/* bit 0 of last byte is always 1 (end bit) */
			cmd55[7], CRC7_buf(&cmd55[2], 5) | 0x01);
		txtout[chars] = 0;
		prtstr(txtout);

		statptr = sdcommand(acmd41, sizeof acmd41, rxbuf, 8);
		chars = decode(txtout, sizeof(txtout), "ACMD41 R1 response 0x%+02hi\r\n", statptr[0]);
		txtout[chars] = 0;
		prtstr(txtout);
		chars = decode(txtout, sizeof(txtout),
			"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
			/* bit 0 of last byte is always 1 (end bit) */
			acmd41[7], CRC7_buf(&acmd41[2], 5) | 0x01);
		txtout[chars] = 0;
		prtstr(txtout);
		if (*statptr == 0x00)
			break;
		}

	/* CMD58: READ_OCR */
	statptr = sdcommand(cmd58, sizeof cmd58, rxbuf, 8);
	chars = decode(txtout, sizeof(txtout),
		"CMD58 R3 response 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi 0x%+02hi - OCR register\r\n",
		 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout),
		"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
		/* bit 0 of last byte is always 1 (end bit) */
		cmd58[7], CRC7_buf(&cmd58[2], 5) | 0x01);
	txtout[chars] = 0;
	prtstr(txtout);
	cpybuf(&ocrreg[0], &statptr[1], sizeof (ocrreg));
	if (ocrreg[0] & 0x80)
		{
		if (ocrreg[0] & 0x40)
			{
			/* SD Ver.2+, Block address */
			blkmult = 1;
			}
		else
			{
			/* SD Ver.2+, Byte address */
			blkmult = 512;
			}
		}

	/* CMD 16: SET_BLOCKLEN, only if Byte address */
	if (blkmult == 512)
		{
		statptr = sdcommand(cmd16, sizeof cmd16, rxbuf, 8);
		chars = decode(txtout, sizeof(txtout), "CMD16 R1 response 0x%+02hi\r\n", statptr[0]);
		txtout[chars] = 0;
		prtstr(txtout);
		chars = decode(txtout, sizeof(txtout),
			"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
			/* bit 0 of last byte is always 1 (end bit) */
			cmd16[7], CRC7_buf(&cmd16[2], 5) | 0x01);
		txtout[chars] = 0;
		prtstr(txtout);
		}

	/* CMD10: SEND_CID */
	statptr = sdcommand(cmd10, sizeof cmd10, rxbuf, 20);
	chars = decode(txtout, sizeof(txtout), "CMD10 R1 response 0x%+02hi\r\n", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout),
		"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
		/* bit 0 of last byte is always 1 (end bit) */
		cmd10[7], CRC7_buf(&cmd10[2], 5) | 0x01);
	txtout[chars] = 0;
	prtstr(txtout);
	for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
		; /* looking for 0xfe that is the byte before data */
	if (*statptr != 0xfe)
		{
		prtstr("No data found\r\n");
		}
	else
		{
		statptr++;
		prtptr = statptr;
		prtstr("CID data:\r\n  ");
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
		cpybuf(&cidreg[0], &statptr[0], sizeof (cidreg));
		}

	/* CMD9: SEND_CSD */
	statptr = sdcommand(cmd9, sizeof cmd9, rxbuf, 20);
	chars = decode(txtout, sizeof(txtout), "CMD9 R1 response 0x%+02hi\r\n", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout),
		"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
		/* bit 0 of last byte is always 1 (end bit) */
		cmd9[7], CRC7_buf(&cmd9[2], 5) | 0x01);
	txtout[chars] = 0;
	prtstr(txtout);
	for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
		; /* looking for 0xfe that is the byte before data */
	if (*statptr != 0xfe)
		{
		prtstr("No data found\r\n");
		}
	else
		{
		statptr++;
		prtptr = statptr;
		prtstr("CSD data:\r\n  ");
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
		cpybuf(&csdreg[0], &statptr[0], sizeof (csdreg));
		}

	ready = YES;
	spideselect();
	ledoff();

	/* maybe more to handle MMC cards */
	}

/* CMD17 is the read block command */
unsigned char cmd17[] = {0xff, 0xff, 0x51, 0x00, 0x00, 0x00, 0x00, 0x55};

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
	blktoread = blkmult * blockno;
	cmd17[6] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd17[5] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd17[4] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd17[3] = blktoread & 0xff;
	blktoread = blktoread >> 8;

	statptr = sdcommand(cmd17, sizeof cmd17, rxbuf, 530);
	chars = decode(txtout, sizeof(txtout), "CMD17 R1 response 0x%+02hi\r\n", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout),
		"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
		/* bit 0 of last byte is always 1 (end bit) */
		cmd17[7], CRC7_buf(&cmd17[2], 5) | 0x01);
	txtout[chars] = 0;
	prtstr(txtout);
	if (statptr[0])
		{
		prtstr("could not read block\r\n");
		spideselect();
		ledoff();
		return;
		}
	statptr++;
	for (tries = 0; (tries < 80) && (*statptr != 0xfe); tries++, statptr++)
		{
		if ((*statptr & 0xe0) == 0x00)
			{
			/* If a read operation fails and the card cannot provide
			   the required data, it will send a data error token instead
			 */
			chars = decode(txtout, sizeof(txtout), "Read error: 0x%+02hi\r\n",
				 *statptr);
			txtout[chars] = 0;
			prtstr(txtout);
			break;
			}
		}
	if (*statptr != 0xfe)
		{
		prtstr("No data found\r\n");
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
			"  Recieved CRC16: 0x%+04hi, calc: 0x%+04hi\r\n",
			(rxdata[0x200] << 8) + rxdata[0x201], 
			CRC16_buf(rxdata, 512));
	       	txtout[chars] = 0;
		prtstr(txtout);
		}

	spideselect();
	ledoff();

	}

/* CMD24 is the write block command */
unsigned char cmd24[] = {0xff, 0xff, 0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};

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
		prtstr("No data in buffer to write\r\n");
		spideselect();
		ledoff();
		return;
		}

	/* CMD24: WRITE_SINGLE_BLOCK */
	/* Insert block # into command */
	blktoread = blkmult * blockno;
	cmd24[6] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd24[5] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd24[4] = blktoread & 0xff;
	blktoread = blktoread >> 8;
	cmd24[3] = blktoread & 0xff;
	blktoread = blktoread >> 8;

	statptr = sdcommand(cmd24, sizeof cmd24, statbuf, 8);
	chars = decode(txtout, sizeof(txtout), "CMD24 R1 response 0x%+02hi\r\n", statptr[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout),
		"  CRC7 sent: 0x%+02hi, calc: 0x%+02hi\r\n",
		/* bit 0 of last byte is always 1 (end bit) */
		cmd24[7], CRC7_buf(&cmd24[2], 5) | 0x01);
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
	if ((0x1f & statptr[0]) == 0x05)
		prtstr("data accepted");
	chars = decode(txtout, sizeof(txtout),
		"\r\n  Transmitted CRC16: 0x%+04hi, calc: 0x%+04hi\r\n",
		(txdata[0x200] << 8) + txdata[0x201], 
		CRC16_buf(txdata, 512));
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
		prtstr("No data read into buffer\r\n");
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
		"  Recieved CRC16: 0x%+04hi, calc: 0x%+04hi\r\n",
		(rxdata[0x200] << 8) + rxdata[0x201], 
		CRC16_buf(rxdata, 512));
       	txtout[chars] = 0;
	prtstr(txtout);
	}

/* print OCR, CID and CSD registers*/
void sdprtreg()
	{
	int chars;
	unsigned int n;
	unsigned int csize;
	unsigned long devsize;
	unsigned long capacity;

	prtstr("OCR register:\r\n");
	if (ocrreg[2] & 0x80)
		prtstr("2.7-2.8V (bit 15) ");
	if (ocrreg[1] & 0x01)
		prtstr("2.8-2.9V (bit 16) ");
	if (ocrreg[1] & 0x02)
		prtstr("2.9-3.0V (bit 17) ");
	if (ocrreg[1] & 0x04)
		prtstr("3.0-3.1V (bit 18) \r\n");
	if (ocrreg[1] & 0x08)
		prtstr("3.1-3.2V (bit 19) ");
	if (ocrreg[1] & 0x10)
		prtstr("3.2-3.3V (bit 20) ");
	if (ocrreg[1] & 0x20)
		prtstr("3.3-3.4V (bit 21) ");
	if (ocrreg[1] & 0x40)
		prtstr("3.4-3.5V (bit 22) \r\n");
	if (ocrreg[1] & 0x80)
		prtstr("3.5-3.6V (bit 23) \r\n");
	if (ocrreg[0] & 0x01)
		prtstr("Switching to 1.8V Accepted (S18A) (bit 24) set ");
	if (ocrreg[0] & 0x08)
		prtstr("Over 2TB support Status (CO2T) (bit 27) set\r\n");
	if (ocrreg[0] & 0x20)
		prtstr("UHS-II Card Status (bit 29) set ");
	if (ocrreg[0] & 0x80)
		{
		if (ocrreg[0] & 0x40)
			{
			prtstr("Card Capacity Status (CCS) (bit 30) set\r\n");
			prtstr("  SD Ver.2+, Block address");
			}
		else
			{
			prtstr("Card Capacity Status (CCS) (bit 30) not set\r\n");
			prtstr("  SD Ver.2+, Byte address");
			}
		prtstr("\r\nCard power up status bit (busy) (bit 31) set\r\n");
		}
	else
		{
		prtstr("\r\nCard power up status bit (busy) (bit 31) not set.\r\n");
		prtstr("  This bit is not set if the card has not finished the power up routine.\r\n");
		}
	prtstr("-----------\r\n");
	prtstr("CID register:\r\n");
	chars = decode(txtout, sizeof(txtout), "MID: %i (0x%+02hi), ", cidreg[0], cidreg[0]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout), "OID: %b, ", &cidreg[1], 2);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout), "PNM: %b, ", &cidreg[3], 5);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout), "PRV: %i.%i, ",
		(cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout), "PSN: %ul, ",
		(cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
	txtout[chars] = 0;
	prtstr(txtout);
	chars = decode(txtout, sizeof(txtout), "MDT: %i-%i\r\n",
		2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
	txtout[chars] = 0;
	prtstr(txtout);
	prtstr("-----------\r\n");
	prtstr("CSD register:\r\n");
	if ((csdreg[0] & 0xc0) == 0x00)
		{
		prtstr("CSD Version 1.0, Standard Capacity\r\n");
		n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
		csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) + ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
		capacity = (unsigned long) csize << (n-10);
		chars = decode(txtout, sizeof(txtout),
		 " Device capacity: %ul Kbyte, %ul Mbyte\r\n",
		  capacity, capacity >> 10);
		txtout[chars] = 0;
		prtstr(txtout);
		}
	if ((csdreg[0] & 0xc0) == 0x40)
		{
		prtstr("CSD Version 2.0, High Capacity and Extended Capacity\r\n");
		devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
		 + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
		capacity = devsize << 9;
		chars = decode(txtout, sizeof(txtout),
		 " Device capacity: %ul Kbyte, %ul Mbyte\r\n",
		  capacity, capacity >> 10);
		txtout[chars] = 0;
		prtstr(txtout);
		}
	if ((csdreg[0] & 0xc0) == 0x80)
		prtstr("CSD Version 3.0, Ultra Capacity (SDUC)\r\n");

	prtstr("-----------\r\n");
	}

/* Test init, read and write on SD card over the SPI interface
 *
 */
int main()
	{
	int chars;
	int cmdin;
	int inlength;

	prtstr(SDTSTVER);
	prtstr(builddate);
	prtstr("\r\n");
	while (YES) /* forever (until Ctrl-C) */
		{
		prtstr("cmd (h for help): ");

		cmdin = getc();
		switch (cmdin)
			{
			case 'h':
				prtstr(SDTSTVER);
				prtstr(builddate);
				prtstr("\r\n");
				prtstr("Commands:\r\n");
				prtstr("  h - help\r\n");
				prtstr("  d - byte level debug on\r\n");
				prtstr("  o - byte level debug off\r\n");
				prtstr("  i - initialize\r\n");
				prtstr("  n - set/show block #N to read/write\r\n");
				prtstr("  r - read block #N\r\n");
				prtstr("  w - write block #N\r\n");
				prtstr("  p - print block last read or written\r\n");
				prtstr("  s - print SD registers\r\n");
				prtstr("  Ctrl-C to reload monitor.\r\n");
				break;
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
				else
					{
					chars = decode(txtout, sizeof(txtout), "%ul\r\n", blockno);
					txtout[chars] = 0;
					prtstr(txtout);
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
			case 's':
				prtstr(" s - print SD registers\r\n");
				sdprtreg();
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

