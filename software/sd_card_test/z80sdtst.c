/* z80sdtst.c
 *
 *  Test Z80 SPI/SD card interface on Z80 Computer
 *  program compiled with Whitesmiths compiler
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties given.
 *  Hastily Cobbled Together 2021 and 2022
 *  by Hans-Ake Lund
 *
 *  This code was hacked together to implement/test
 *  a "bit-banger" SPI interface to a SD card for
 *  the Z80 computer.
 *
 *  The idea is to use his program to understand
 *  how the SPI and SD card interfaces and the
 *  partitioning of a SD card works in order
 *  to make a CP/M disk driver for SD card
 *  that handles multiple partitions and
 *  presents a CP/M drive for each partition.
 *
 *  In the process the Whitesmith C compiler for
 *  Z80 was also rather thoroughly tested.
 *
 *  Be warned that this is a very ugly hack
 *  the intention is to clean it up to much
 *  more nice looking code.
 *
 */

#include <std.h>
#include "z80computer.h"
#include "builddate.h"

#define SDTSTVER "\nz80sdtst version 2.0, "

unsigned char rxbuf[520] = {0};
unsigned char statbuf[30] = {0};

unsigned char ocrreg[4] = {0};
unsigned char cidreg[16] = {0};
unsigned char csdreg[16] = {0};

int debugflg = 0;
int ready = NO;
int prthex = NO;
unsigned char *dataptr;
unsigned char *rxtxptr = NULL;
unsigned long blockno = 0;
unsigned long blkmult = 1;

/* CRC routines from:
 * https://github.com/LonelyWolf/stm32/blob/master/stm32l-dosfs/sdcard.c
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
	int debugnl;
	unsigned char *retptr;
	unsigned int rbyte;
	unsigned int sbyte;

	if (debugflg)
		{
		printf("(snd)");
		debugnl = 0;
		}
	for (; 0 < sndbytes; sndbytes--)
		{
		sbyte = *sndbuf++;
		rbyte = (spiio(sbyte) & 0xff);
		if (debugflg)
			{
			printf(">%02x<%02x,", sbyte, rbyte);
			if (7 < debugnl++)
				{
				printf("\n");
				debugnl = 0;
				}
			}
		}
	if (debugflg)
		printf("\n");

	bitsearch = YES;
	retptr = recbuf;
	if (debugflg)
		{
		printf("(rec)");
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
			printf(">%02x<%02x,", sbyte, rbyte);
			if (7 < debugnl++)
				{
				printf("\n");
				debugnl = 0;
				}
			}
		}
	if (debugflg)
		printf("\n");
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

/* initialise SD card interface */
void sdinit()
	{
	unsigned char *prtptr;
	unsigned char *statptr;
	int rxbytes;
	int tries;
	int wtloop;

	ledon();

	/* start to generate 8 clock pulses with not selected SD card */
	spideselect();

	statptr = sdcommand(0, 0, rxbuf, 8);
	printf("Sent 8 bytes with clock pulses, select not active\n");

	spiselect();

	/* CMD0: GO_IDLE_STATE */
	cmd0[7] = CRC7_buf(&cmd0[2], 5) | 0x01;
	statptr = sdcommand(cmd0, sizeof cmd0, rxbuf, 8);
	printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);

	/* CMD8: SEND_IF_COND */
	cmd8[7] = CRC7_buf(&cmd8[2], 5) | 0x01;
	statptr = sdcommand(cmd8, sizeof cmd8, rxbuf, 8);
	printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x]\n",
		 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
	if (statptr[0] & 0xfe) /* if error */
		{
		acmd41[3] = 0x00; /* probably SD Ver.1 */
		blkmult = 512; /* in case that READ_OCR does not work */
		}
	else
		{
		acmd41[3] = 0x40; /* probably SD Ver.2 */
		if ((statptr[3] & 0x0f) == 0x01)
			printf("  Voltage accepted: 2.7-3.6V, ");
		if (statptr[4] == 0xaa)
			printf("echo back ok\n");
		else
			printf("invalid echo back\n");
		}

	/* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
	for (tries = 0; tries < 20; tries++)
		{
		cmd55[7] =  CRC7_buf(&cmd55[2], 5) | 0x01;
		statptr = sdcommand(cmd55, sizeof cmd55, rxbuf, 8);
		printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
		acmd41[7] = CRC7_buf(&acmd41[2], 5) | 0x01;
		statptr = sdcommand(acmd41, sizeof acmd41, rxbuf, 8);
		printf("ACMD41: SEND_OP_COND, R1 response [%02x]\n", statptr[0]);
		if (statptr[0] == 0x00)
			break;
		for (wtloop = 0; wtloop < tries * 100; wtloop++)
			; /* wait loop, time increasing for each try */
		}

	/* CMD58: READ_OCR */
	/* according to flowchart this does not work
	   for SD Ver.1 but the response is ok anyway */
	cmd58[7] = CRC7_buf(&cmd58[2], 5) | 0x01;
	statptr = sdcommand(cmd58, sizeof cmd58, rxbuf, 8);
	printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
		 statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
	memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
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
		cmd16[7] = CRC7_buf(&cmd16[2], 5) | 0x01;
		statptr = sdcommand(cmd16, sizeof cmd16, rxbuf, 8);
		printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n", statptr[0]);
		}

	/* CMD10: SEND_CID */
	cmd10[7] = CRC7_buf(&cmd10[2], 5) | 0x01;
	statptr = sdcommand(cmd10, sizeof cmd10, rxbuf, 30);
	printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
	for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
		; /* looking for 0xfe that is the byte before data */
	if (*statptr != 0xfe)
		{
		printf("  No data found\n");
		}
	else
		{
		statptr++;
		prtptr = statptr;
		printf("  CID: [");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			printf("%02x ", *prtptr);
		prtptr = statptr;
		printf("\b] |");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			{
			if ((' ' <= *prtptr) && (*prtptr < 127))
				putchar(*prtptr);
			else
				putchar('.');
			}
		printf("|\n");
		memcpy(&cidreg[0], &statptr[0], sizeof (cidreg));
		}

	/* CMD9: SEND_CSD */
	cmd9[7] = CRC7_buf(&cmd9[2], 5) | 0x01;
	statptr = sdcommand(cmd9, sizeof cmd9, rxbuf, 30);
	printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
	for (tries = 0; (tries < 20) && (*statptr != 0xfe); tries++, statptr++)
		; /* looking for 0xfe that is the byte before data */
	if (*statptr != 0xfe)
		{
		printf("  No data found\n");
		}
	else
		{
		statptr++;
		prtptr = statptr;
		printf("  CSD: [");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			printf("%02x ", *prtptr);
		prtptr = statptr;
		printf("\b] |");
		for (rxbytes = 0; rxbytes < 16; rxbytes++, prtptr++)
			{
			if ((' ' <= *prtptr) && (*prtptr < 127))
				putchar(*prtptr);
			else
				putchar('.');
			}
		printf("|\n");
		memcpy(&csdreg[0], &statptr[0], sizeof (csdreg));
		}

	ready = YES;

	statptr = sdcommand(0, 0, rxbuf, 16);
	printf("Sent 16 bytes of clock pulses, select active\n");

	spideselect();
	ledoff();

	/* maybe more to handle MMC cards */
	}

/* CMD17 is the read block command */
unsigned char cmd17[] = {0xff, 0xff, 0x51, 0x00, 0x00, 0x00, 0x00, 0x55};

/* read data block */
int sdread(int printit)
	{
	unsigned char *rxdata;
	unsigned char *statptr;
	int dmpline;
	int rxbytes;
	int tries;
	unsigned long blktoread;
	unsigned int rxcrc16;
	unsigned int calcrc16;

	ledon();
	spiselect();

	if (!ready)
		{
		printf("SD card not initialized\n");
		spideselect();
		ledoff();
		return (NO);
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

	cmd17[7] = CRC7_buf(&cmd17[2], 5) | 0x01;
	statptr = sdcommand(cmd17, sizeof cmd17, rxbuf, 530);
	if (printit)
		printf("CMD17 R1 response [%02x]\n", statptr[0]);
	if (statptr[0])
		{
		printf("could not read block\n");
		spideselect();
		ledoff();
		return (NO);
		}
	statptr++;
	for (tries = 0; (tries < 80) && (*statptr != 0xfe); tries++, statptr++)
		{
		if ((*statptr & 0xe0) == 0x00)
			{
			/* If a read operation fails and the card cannot provide
			   the required data, it will send a data error token instead
			 */
			printf("Read error: 0x%02x\n", *statptr);
			spideselect();
			ledoff();
			return (NO);
			}
		}
	if (*statptr != 0xfe)
		{
		printf("No data found\n");
		spideselect();
		ledoff();
		return (NO);
		}
	else
		{
		dataptr = statptr + 1;
		rxdata = dataptr;
		rxtxptr = dataptr;

		rxcrc16 = (rxdata[0x200] << 8) + rxdata[0x201];
		calcrc16 = CRC16_buf(rxdata, 512);
		if (printit || (rxcrc16 != calcrc16))
			{
			printf("Data block %ld:\n", blockno);
			if (rxcrc16 != calcrc16)
				printf("  CRC error, recieved CRC16: 0x%04x, calc: 0x%04hi\n", rxcrc16, calcrc16);
			}
		}

	spideselect();
	ledoff();
	return (YES);
	}

/* CMD24 is the write block command */
unsigned char cmd24[] = {0xff, 0xff, 0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};

/* write data block */
void sdwrite()
	{
	unsigned char *txdata;
	unsigned char *statptr;
	int prtline;
	int txbytes;
	unsigned int crc16tx;
	unsigned long blktoread;

	ledon();
	spiselect();

	if (!rxtxptr)
		{
		printf("No data in buffer to write\n");
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

	cmd24[7] = CRC7_buf(&cmd24[2], 5) | 0x01;
	statptr = sdcommand(cmd24, sizeof cmd24, statbuf, 8);
	printf("CMD24 R1 response [%02x]\n", statptr[0]);
	dataptr = rxtxptr;
	txdata = dataptr;
	printf("Data block %lu:\n", blockno);
	/* send data after adding start flag and CRC16 */
	crc16tx = CRC16_buf(txdata, 512);
	txdata[-1] = 0xfe;
	txdata[0x200] = (crc16tx >>  8) & 0xff;
	txdata[0x201] = crc16tx & 0xff;
	sdcommand(txdata - 1, 512 + 3, statbuf, 8);
	/* check data resp. */
	for (statptr = statbuf; (*statptr & 0x11) != 0x01; statptr++)
		;
	printf("Data response [%02x]", 0x1f & statptr[0]);
	if ((0x1f & statptr[0]) == 0x05)
		printf(", data accepted");
	printf("\n");
	spideselect();
	ledoff();
	}

/* print the SD data buffer */
void sddatprt()
	{
	unsigned char *rxdata;
	unsigned char *statptr;
	int dmpline;
	int rxbytes;
	int tries;
	int allzero, lastallz, dotprted;

	if (!rxtxptr)
		{
		printf("No data read into buffer\n");
		return;
		}
	dataptr = rxtxptr;
	rxdata = dataptr;
	printf("Data block %lu:\n", blockno);
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
				printf("*\n");
				dotprted = YES;
				}
			}
		else
			{
			dotprted = NO;
			/* print offset */
			printf("%04x ", dmpline * 16);
			/* print 16 bytes in hex */
			for (rxbytes = 0; rxbytes < 16; rxbytes++)
				printf("%02x ", dataptr[rxbytes]);
			/* print these bytes in ASCII if printable */
			printf(" |");
			for (rxbytes = 0; rxbytes < 16; rxbytes++)
				{
				if ((' ' <= dataptr[rxbytes]) && (dataptr[rxbytes] < 127))
					putchar(dataptr[rxbytes]);
				else
					putchar('.');
				}
			printf("|\n");
				}
		dataptr += 16;
		lastallz = allzero;
		}
	}

/* print OCR, CID and CSD registers*/
void sdprtreg()
	{
	unsigned int n;
	unsigned int csize;
	unsigned long devsize;
	unsigned long capacity;

	printf("OCR register:\n");
	if (ocrreg[2] & 0x80)
		printf("2.7-2.8V (bit 15) ");
	if (ocrreg[1] & 0x01)
		printf("2.8-2.9V (bit 16) ");
	if (ocrreg[1] & 0x02)
		printf("2.9-3.0V (bit 17) ");
	if (ocrreg[1] & 0x04)
		printf("3.0-3.1V (bit 18) \n");
	if (ocrreg[1] & 0x08)
		printf("3.1-3.2V (bit 19) ");
	if (ocrreg[1] & 0x10)
		printf("3.2-3.3V (bit 20) ");
	if (ocrreg[1] & 0x20)
		printf("3.3-3.4V (bit 21) ");
	if (ocrreg[1] & 0x40)
		printf("3.4-3.5V (bit 22) \n");
	if (ocrreg[1] & 0x80)
		printf("3.5-3.6V (bit 23) \n");
	if (ocrreg[0] & 0x01)
		printf("Switching to 1.8V Accepted (S18A) (bit 24) set ");
	if (ocrreg[0] & 0x08)
		printf("Over 2TB support Status (CO2T) (bit 27) set\n");
	if (ocrreg[0] & 0x20)
		printf("UHS-II Card Status (bit 29) set ");
	if (ocrreg[0] & 0x80)
		{
		if (ocrreg[0] & 0x40)
			{
			printf("Card Capacity Status (CCS) (bit 30) set\n");
			printf("  SD Ver.2+, Block address");
			}
		else
			{
			printf("Card Capacity Status (CCS) (bit 30) not set\n");
			if (acmd41[3] == 0x00)
				printf("  SD Ver.1, Byte address");
			else
				printf("  SD Ver.2+, Byte address");
			}
		printf("\nCard power up status bit (busy) (bit 31) set\n");
		}
	else
		{
		printf("\nCard power up status bit (busy) (bit 31) not set.\n");
		printf("  This bit is not set if the card has not finished the power up routine.\n");
		}
	printf("-----------\n");
	printf("CID register:\n");
	printf("MID: %d (0x%02x), ", cidreg[0], cidreg[0]);
	printf("OID: %b, ", &cidreg[1], 2);
	printf("PNM: %b, ", &cidreg[3], 5);
	printf("PRV: %d.%d, ",
		(cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
	printf("PSN: %lu, ",
		(cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
	printf("MDT: %d-%d\n",
		2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
	printf("-----------\n");
	printf("CSD register:\n");
	if ((csdreg[0] & 0xc0) == 0x00)
		{
		printf("CSD Version 1.0, Standard Capacity\n");
		n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
		csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
            ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
		capacity = (unsigned long) csize << (n-10);
		printf(" Device capacity: %lu KByte, %lu MByte\n",
		  capacity, capacity >> 10);
		}
	if ((csdreg[0] & 0xc0) == 0x40)
		{
		printf("CSD Version 2.0, High Capacity and Extended Capacity\n");
		devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
		 + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
		capacity = devsize << 9;
		printf(" Device capacity: %lu KByte, %lu MByte\n",
		  capacity, capacity >> 10);
		}
	if ((csdreg[0] & 0xc0) == 0x80)
		printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");

	printf("-----------\n");
	}

/* print GUID (mixed endian format) */
void prtguid(unsigned char *guidptr)
	{
	int index;

	printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
	printf("%02x%02x-", guidptr[5], guidptr[4]);
	printf("%02x%02x-", guidptr[7], guidptr[6]);
	printf("%02x%02x-", guidptr[8], guidptr[9]);
	printf("%02x%02x%02x%02x%02x%02x",
		guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
	if (prthex)
		{
		printf("\n  [");
		for (index = 0; index < 16; index++)
			printf("%02x ", guidptr[index]);
		printf("\b]");
		}
	}

/* print GPT entry */
void prtgptent(unsigned int entryno)
	{
	int index;
	int entryidx;
	int hasname;
	unsigned int block;
	unsigned char *rxdata;
	unsigned char *entryptr;
	unsigned char tstzero = 0;
	unsigned long flba;
	unsigned long llba;

	block = 2 + (entryno / 4);
	if ((blockno != block) || YES /*!rxtxptr*/)
		{
		blockno = block;
		if (!sdread(NO))
			{
			printf("Can't read GPT entry block\n");
			return;
			}
		}
	rxdata = dataptr;
	entryptr = rxdata + (128 * (entryno % 4));
	for (index = 0; index < 16; index++)
		tstzero |= entryptr[index];
	printf("GPT partition entry %d:", entryno + 1);
	if (!tstzero)
		{
		printf(" Not used entry\n");
		return;
		}
	printf("\n  Partition type GUID: ");
	prtguid(entryptr);
	printf("\n  Unique partition GUID: ");
	prtguid(entryptr + 16);
	printf("\n  First LBA: ");
	/* lower 32 bits of LBA should be sufficient (I hope) */
	flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
		((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
	printf("%lu", flba);
	if (prthex)
		{
		printf(" [");
		for (index = 32; index < (32 + 8); index++)
			printf("%02x ", entryptr[index]);
		printf("\b]");
		}
	printf("\n  Last LBA: ");
	/* lower 32 bits of LBA should be sufficient (I hope) */
	llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
		((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);
	printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
	if (prthex)
		{
		printf(" [");
		for (index = 40; index < (40 + 8); index++)
			printf("%02x ", entryptr[index]);
		printf("\b]");
		}
	printf("\n  Attribute flags: [");
	/* bits 0 - 2 and 60 - 63 should be decoded */
	for (index = 0; index < 8; index++)
		{
		entryidx = index + 48;
		printf("%02x ", entryptr[entryidx]);
        }
	printf("\b]\n  Partition name:  ");
	/* partition name is in UTF-16LE code units */
	hasname = NO;
	for (index = 0; index < 72; index += 2)
		{
		entryidx = index + 56;
		if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
			break;
		if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
			putchar(entryptr[entryidx]);
		else
			putchar('.');
		hasname = YES;
		}
	if (!hasname)
		printf("name field empty");
	printf("\n");
	if (prthex)
		{
		printf("   [");
		entryidx = index + 56;
		for (index = 0; index < 72; index++)
			{
			if (((index & 0xf) == 0) && (index != 0)) 
				printf("\n    ");
			printf("%02x ", entryptr[entryidx]);
			}
		printf("\b]\n");
		}
	}

/* print GPT header */
void prtgpthdr(unsigned long block)
	{
	int index;
	unsigned int partno;
	unsigned char *rxdata;
	unsigned long entries;

	printf("GPT header\n");
	blockno = block;
	if (!sdread(NO))
		{
		printf("Can't read GPT partition table header\n");
		return;
		}
	rxdata = dataptr;
	printf("  Signature: %8s\n", &rxdata[0]);
	printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
		 (int)rxdata[8] * ((int)rxdata[9] << 8),
		 (int)rxdata[10] + ((int)rxdata[11] << 8),
		 rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
	entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
		  ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
	printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
	if (prthex)
		{
		printf("First 128 bytes of GTP header\n   [");
		for (index = 0; index < 128; index++)
			{
			if (((index & 0xf) == 0) && (index != 0)) 
				printf("\n    ");
			printf("%02x ", rxdata[index]);
			}
		printf("\b]\n");
		}
	for (partno = 0; partno < 16; partno++)
		{
		prtgptent(partno);
		}
	printf("First 16 GPT entries scanned\n");
	}

/* print MBR partition entry */
void prtmbrpart(unsigned char *partptr)
	{
	int index;
	unsigned long lbastart;
	unsigned long lbasize;


	if ((blockno != 0) || YES /*!rxtxptr*/)
		{
		blockno = 0;
		if (!sdread(NO))
			{
			printf("Can't read MBR sector\n");
			return;
			}
		}
	if (!partptr[4])
		{
		printf("Not used entry\n");
		return;
		}
	printf("boot indicator: 0x%02x, System ID: 0x%02x\n",
	  partptr[0], partptr[4]);

	if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
		{
		printf("  Extended partition\n");
		/* should probably decode this also */
		}
	if (partptr[0] & 0x01)
		{
		printf("  unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
		/* this is however discussed
		   https://wiki.osdev.org/Partition_Table#.22Unofficial.22_48_bit_LBA_Proposed_MBR_Format
		*/
		}
	else
		{
		printf("  begin CHS: 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
		  partptr[1], partptr[2], partptr[3],
		  ((partptr[2] & 0xc0) >> 2) + partptr[3],
		  partptr[1],
		  partptr[2] & 0x3f);
		printf("  end CHS 0x%02x-0x%02x-0x%02x (cyl: %d, head: %d sector: %d)\n",
		  partptr[5], partptr[6], partptr[7],
		  ((partptr[6] & 0xc0) >> 2) + partptr[7],
		  partptr[5],
		  partptr[6] & 0x3f);
		}
	/* not showing high 16 bits if 48 bit LBA */
	lbastart = (unsigned long)partptr[8] +
	  ((unsigned long)partptr[9] << 8) +
	  ((unsigned long)partptr[10] << 16) +
	  ((unsigned long)partptr[11] << 24);
	lbasize = (unsigned long)partptr[12] +
	  ((unsigned long)partptr[13] << 8) +
	  ((unsigned long)partptr[14] << 16) +
	  ((unsigned long)partptr[15] << 24);
	printf("  partition start LBA: %lu [%08lx]\n", lbastart, lbastart);
	printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
        lbasize, lbasize, lbasize >> 11);
	if (prthex)
		{
		printf("  [");
		for (index = 0; index < 16; index++)
			printf("%02x ", partptr[index]);
		printf("\b]\n");
		}
	if (partptr[4] == 0xee)
		prtgpthdr(lbastart);
	}

/* print partition layout */
void sdprtpart()
	{
	unsigned char *rxdata;

	printf("Read MBR\n");
	blockno = 0;
	if (!sdread(NO))
		{
		printf("Can't read MBR sector\n");
		return;
		}
	if ((blockno != 0) || YES /*!rxtxptr*/)
		{
		blockno = 0;
		if (!sdread(NO))
			{
			printf("Can't read MBR sector\n");
			return;
			}
		}
	rxdata = dataptr;
	if (!((rxdata[0x1fe] == 0x55) && (rxdata[0x1ff] == 0xaa)))
		{
		printf("No MBR signature found\n");
		return;
		}

	/* print MBR partition entries */
	printf("MBR partition entry 1: ");
	prtmbrpart(&rxdata[0x01be]);
	printf("MBR partition entry 2: ");
	prtmbrpart(&rxdata[0x01ce]);
	printf("MBR partition entry 3: ");
	prtmbrpart(&rxdata[0x01de]);
	printf("MBR partition entry 4: ");
	prtmbrpart(&rxdata[0x01ee]);
	}

/* Test init, read and write on SD card over the SPI interface
 *
 */
int main()
	{
	char txtin[10];
	int cmdin;
	int inlength;

	printf(SDTSTVER);
	printf(builddate);
	printf("\n");
	while (YES) /* forever (until Ctrl-C) */
		{
		printf("cmd (h for help): ");

		cmdin = getchar();
		switch (cmdin)
			{
			case 'h':
				printf(" h - help\n");
				printf(SDTSTVER);
				printf(builddate);
				printf("\nCommands:\n");
				printf("  h - help\n");
				printf("  d - byte level debug print on\n");
				printf("  o - byte level debug print off\n");
				printf("  i - initialize\n");
				printf("  n - set/show block #N to read/write\n");
				printf("  r - read block #N\n");
				printf("  w - write block #N\n");
				printf("  p - print block last read or written\n");
				printf("  s - print SD registers\n");
				printf("  l - print partition layout\n");
				printf("  x - print \"raw\" hex fields on\n");
				printf("  y - print \"raw\" hex fields off\n");
				printf("  Ctrl-C to reload monitor.\n");
				break;
			case 'd':
				debugflg = YES;
				printf(" d - byte debug on\n");
				break;
			case 'o':
				debugflg = NO;
				printf(" o - byte debug off\n");
				break;
			case 'x':
				prthex = YES;
				printf(" x - hex debug on\n");
				break;
			case 'y':
				prthex = NO;
				printf(" y - hex debug off\n");
				break;
			case 'i':
				printf(" i - initialize SD card\n");
				sdinit();
				break;
			case 'n':
				printf(" n - block number: ");
				if (getkline(txtin, sizeof txtin))
					sscanf(txtin, "%lu", &blockno);
				else
					printf("%lu", blockno);
				printf("\n");
				break;
			case 'r':
				printf(" r - read block\n");
				sdread(YES);
				break;
			case 'w':
				printf(" w - write block\n");
				sdwrite();
				break;
			case 'p':
				printf(" p - print data block\n");
				sddatprt();
				break;
			case 's':
				printf(" s - print SD registers\n");
				sdprtreg();
				break;
			case 'l':
				printf(" l - print partition layout\n");
				sdprtpart();
				break;
			case 0x03: /* Ctrl-C */
				printf("reloading monitor from EPROM\n");
				reload();
				break; /* not really needed, will never get here */
			default:
				printf(" command not implemented yet\n");
			}
		}
	}

