/*  z80sdrdwr.c Z80 SD card read/write routines.
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
const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x01};
/* CMD 24: WRITE_SINGLE_BLOCK */
const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x01};

/* Variables for the SD card, these variables are set by the
 * initialization code.
 */
char *sdinitok;      /* SD card initialized and ready */
char *byteblkadr;    /* block address multiplier flag */

/* These are really local variables but CP/M uses a minimal stack
 * the routines using them must not be reentrant
 */
int searchn;  /* byte counter to search for response */
int sdcbytes; /* byte counter for bytes to send */
unsigned char *retptr; /* pointer used to store response */
unsigned char rbyte;   /* recieved byte */
unsigned char cmdbuf[5];   /* buffer to build command in */
unsigned char rstatbuf[5]; /* buffer to recieve status in */
unsigned char *statptr;    /* pointer to returned status from SD command */
int nbytes;  /* byte counter */
int allzero;
int tries;

/* Send command to SD card and recieve answer.
 * A command is 5 bytes long and is followed by
 * a CRC7 checksum byte (not needed in SPI mode
 * except for CMD0 and CMD8).
 * Returns a pointer to the response
 * or 0 if no response start bit found.
 */
unsigned char *sdcommand(unsigned char *sdcmdp,
                         unsigned char *recbuf, int recbytes)
    {
    byteblkadr = (void *) SEBYFLG;
    sdinitok = (void *) INITFLG;
    /* send 8*2 clockpules */
    spiio(0xff);
    spiio(0xff);
    for (sdcbytes = 5; 0 < sdcbytes; sdcbytes--) /* send bytes */
        {
        spiio(*sdcmdp++);
        }
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

/* Read data block of 512 bytes to rdbuf
 * the block number is a 4 byte array
 * Returns YES if ok or NO if error
 */
int sdread(unsigned char *rdbuf, unsigned char *rdblkno)
    {

    spiselect();

    if (!*sdinitok)
        {
        spideselect();
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
            return (NO);
            }
        }
    if (tries == 0) /* tried too many times */
        {
        spideselect();
        return (NO);
        }
    else
        {
        for (nbytes = 0; nbytes < 512; nbytes++)
            {
            rdbuf[nbytes] = spiio(0xff);
            }
        /* read crc16 but no check */
        spiio(0xff);
        spiio(0xff);
        }
    spideselect();
    return (YES);
    }

/* Write data block of 512 bytes from buffer
 * Returns YES if ok or NO if error
 */
int sdwrite(unsigned char *wrbuf, unsigned char *wrblkno)
    {

    spiselect();

    if (!*sdinitok)
        {
        spideselect();
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
        return (NO);
        }
    /* send 0xfe, the byte before data */
    spiio(0xfe);
    /* initialize crc and send block */
    for (nbytes = 0; nbytes < 512; nbytes++)
        {
        spiio(wrbuf[nbytes]);
        }
    /* send dummy crc16 */
    spiio(0x00);
    spiio(0x00);

    /* check data resposnse */
    for (tries = 20;
            0 < tries && (((rbyte = spiio(0xff)) & 0x11) != 0x01);
            tries--)
        ;
    if (tries == 0)
        {
        spideselect();
        return (NO);
        }
    else
        {
        if ((0x1f & rbyte) == 0x05)
            {
            for (nbytes = 9; 0 < nbytes; nbytes--)
                spiio(0xff);
            spideselect();
            return (YES);
            }
        else
            {
            spideselect();
            return (NO);
            }
        }
    }

extern unsigned char diskno;
extern unsigned char track;
extern unsigned char sector;

char prtbuf[10];

unsigned char hstbuf[512];      /* host SD disk buffer */
struct partentry *parptr;       /* Partition map pointer */
unsigned int lbacpmsec;         /* CP/M sector to read/write */
unsigned int lbahstblk;         /* disk block to read/write to/from hstbuf */
unsigned char sddskblk[4];/* block to read/write in SD format, per partition */
unsigned char sdcardblk[4];/* block to read/write in SD format, per card */

extern unsigned int spt;        /* sectors per track */

/* Convert unsigned int to block address
 */
void ui2blk(unsigned char *blk, unsigned int nblk)
    {
    blk[3] = nblk & 0xff;
    nblk = nblk >> 8;
    blk[2] = nblk & 0xff;
    blk[1] = 0;
    blk[0] = 0;
    }

extern unsigned int dmaad;

/* Read sector, called from BIOS
 */
rdsdsec()
    {
    parptr = (void *) PARMAPADR;
    lbacpmsec = track * spt + sector - 1;
    lbahstblk = lbacpmsec / 4;
    ui2blk(sddskblk, lbahstblk);
    memcpy(sdcardblk, sddskblk, 4);
    addblk(sdcardblk, parptr[diskno].parstart);
    if (!sdread(hstbuf, sdcardblk))
        return(1);
    memcpy(dmaad, &hstbuf[128 * (lbacpmsec & 3)], 128);
    return(0);
    }

/* Write sector, called from BIOS
 */
wrsdsec()
    {
    parptr = (void *) PARMAPADR;
    lbacpmsec = track * spt + sector - 1;
    lbahstblk = lbacpmsec / 4;
    ui2blk(sddskblk, lbahstblk);
    memcpy(sdcardblk, sddskblk, 4);
    addblk(sdcardblk, parptr[diskno].parstart);
    if (!sdread(hstbuf, sdcardblk))
        return(1);
    memcpy(&hstbuf[128 * (lbacpmsec & 3)], dmaad, 128);
    if (!sdwrite(hstbuf, sdcardblk))
        return(1);
    return(0);
    }

