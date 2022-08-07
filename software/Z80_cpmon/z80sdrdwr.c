/*  z80sdrdwrv.c Z80 SD card read/write routines.
 *  Will also be used for BIOS but not tested yet.
 *
 *  SD card code for my DIY Z80 Computer. This
 *  program is compiled with Whitesmiths/COSMIC
 *  C compiler for Z80.
 *
 *  For SD card read/write and also detects the
 *  presence of an attached SD card.
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties are given.
 *  Hastily Cobbled Together 2021 and 2022
 *  by Hans-Ake Lund
 *
 */

#include <std.h>
#include "z80comp.h"
#include "z80sd.h"

/* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
 * (The CRC7 byte in the tables below are only for information,
 * it is calculated by the sdcommand routine.)
 */
/* CMD 17: READ_SINGLE_BLOCK */
const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
/* CMD 24: WRITE_SINGLE_BLOCK */
const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
/* CMD 58: READ_OCR */
const unsigned char cmd58b[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};

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

/* Send command to SD card and recieve answer.
 * A command is 5 bytes long and is followed by
 * a CRC7 checksum byte.
 * Returns a pointer to the response
 * or 0 if no response start bit found.
 */
unsigned char *sdcommand(unsigned char *sdcmdp,
                         unsigned char *recbuf, int recbytes)
    {
    int searchn;  /* byte counter to search for response */
    int sdcbytes; /* byte counter for bytes to send */
    unsigned char *retptr; /* pointer used to store response */
    unsigned char rbyte;   /* recieved byte */
    unsigned char crc = 0; /* calculated CRC7 */

    /* send 8*2 clockpules */
    spiio(0xff);
    spiio(0xff);
    for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
        {
        crc = CRC7_one(crc, *sdcmdp);
        spiio(*sdcmdp++);
        }
    spiio(crc | 0x01);
    /* search for recieved byte with start bit
       for a maximum of 10 recieved bytes  */
    for (searchn = 10; 0 < searchn; searchn--)
        {
        rbyte = spiio(0xff);
        if ((rbyte & 0x80) == 0)
            break;
        }
    if (searchn == 0) /* no start bit found */
        return (NO);
    retptr = recbuf;
    *retptr++ = rbyte;
    for (; 1 < recbytes; recbytes--) /* recieve bytes */
        *retptr++ = spiio(0xff);
    return (recbuf);
    }


/* Probe if SD card is inserted and initialized
 */
int sdprobe()
    {
    unsigned char cmdbuf[5];   /* buffer to build command in */
    unsigned char rstatbuf[5]; /* buffer to recieve status in */
    unsigned char *statptr;    /* pointer to returned status from SD command */
    int nbytes;  /* byte counter */
    int allzero = YES;

    ledon();
    spiselect();

    /* CMD 58: READ_OCR */
    memcpy(cmdbuf, cmd58b, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
    for (nbytes = 0; nbytes < 5; nbytes++)
        {
        if (statptr[nbytes] != 0)
            allzero = NO;
        }
    if (!statptr || allzero)
        {
        *sdinitok = 0;
        spideselect();
        ledoff();
        return (NO);
        }

    spideselect();
    ledoff();

    return (YES);
    }

/* Read data block of 512 bytes to rdbuf
 * the block number is a 4 byte array
 * Returns YES if ok or NO if error
 */
int sdread(unsigned char *rdbuf, unsigned char *rdblkno)
    {
    unsigned char *statptr;
    unsigned char rbyte;
    unsigned char cmdbuf[5];   /* buffer to build command in */
    unsigned char rstatbuf[5]; /* buffer to recieve status in */
    int nbytes;
    int tries;
    unsigned int rxcrc16;
    unsigned int calcrc16;

    ledon();
    spiselect();

    if (!*sdinitok)
        {
        spideselect();
        ledoff();
        return (NO);
        }

    /* CMD 17: READ_SINGLE_BLOCK */
    /* Insert block # into command */
    memcpy(cmdbuf, cmd17, 5);
    if (*byteblkadr)
        blk2byte(rdblkno);
    memcpy(&cmdbuf[1], rdblkno, 4);
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (statptr[0])
        {
        spideselect();
        ledoff();
        return (NO);
        }
    /* looking for 0xfe that is the byte before data */
    for (tries = 80; (0 < tries) && ((rbyte = spiio(0xff)) != 0xfe); tries--)
        {
        if ((rbyte & 0xe0) == 0x00)
            {
            /* If a read operation fails and the card cannot provide
               the required data, it will send a data error token instead
             */
            spideselect();
            ledoff();
            return (NO);
            }
        }
    if (tries == 0) /* tried too many times */
        {
        spideselect();
        ledoff();
        return (NO);
        }
    else
        {
        calcrc16 = 0;
        for (nbytes = 0; nbytes < 512; nbytes++)
            {
            rbyte = spiio(0xff);
            calcrc16 = CRC16_one(calcrc16, rbyte);
            rdbuf[nbytes] = rbyte;
            }
        rxcrc16 = spiio(0xff) << 8;
        rxcrc16 += spiio(0xff);

        if (rxcrc16 != calcrc16)
            {
            spideselect();
            ledoff();
            return (NO);
            }
        }
    spideselect();
    ledoff();
    return (YES);
    }

/* Write data block of 512 bytes from buffer
 * Returns YES if ok or NO if error
 */
int sdwrite(unsigned char *wrbuf, unsigned char *wrblkno)
    {
    unsigned char *statptr;
    unsigned char rbyte;
    unsigned char tbyte;
    unsigned char cmdbuf[5];   /* buffer to build command in */
    unsigned char rstatbuf[5]; /* buffer to recieve status in */
    int nbytes;
    int tries;
    unsigned int calcrc16;

    ledon();
    spiselect();

    if (!*sdinitok)
        {
        spideselect();
        ledoff();
        return (NO);
        }
    /* CMD 24: WRITE_SINGLE_BLOCK */
    /* Insert block # into command */
    memcpy(cmdbuf, cmd24, 5);
    if (*byteblkadr)
        blk2byte(wrblkno);
    memcpy(&cmdbuf[1], wrblkno, 4);
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (statptr[0])
        {
        spideselect();
        ledoff();
        return (NO);
        }
    /* send 0xfe, the byte before data */
    spiio(0xfe);
    /* initialize crc and send block */
    calcrc16 = 0;
    for (nbytes = 0; nbytes < 512; nbytes++)
        {
        tbyte = wrbuf[nbytes];
        spiio(tbyte);
        calcrc16 = CRC16_one(calcrc16, tbyte);
        }
    spiio((calcrc16 >> 8) & 0xff);
    spiio(calcrc16 & 0xff);

    /* check data resposnse */
    for (tries = 20;
            0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
            tries--)
        ;
    if (tries == 0)
        {
        spideselect();
        ledoff();
        return (NO);
        }
    else
        {
        if ((0x1f & rbyte) == 0x05)
            {
            for (nbytes = 9; 0 < nbytes; nbytes--)
                spiio(0xff);
            spideselect();
            ledoff();
            return (YES);
            }
        else
            {
            spideselect();
            ledoff();
            return (NO);
            }
        }
    }

