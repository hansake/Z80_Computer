/*  z80sddrv.c Z80 SD card initialize and read/write routines.
 *
 *  SD card code for my DIY Z80 Computer. This
 *  program is compiled with Whitesmiths/COSMIC
 *  C compiler for Z80.
 *
 *  Initializes the hardware and detects the
 *  presence of an attached SD card.
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties are given.
 *  Hastily Cobbled Together 2021 and 2022
 *  by Hans-Ake Lund
 *
 *  When accessing data blocks on the SD card,
 *  block numbers are given as a four byte array
 *  with the most significant byte first, this is the
 *  format that the SD card is using. This internal format
 *  was chosen to make the SD card driver in the BIOS simpler
 *  and not needing to switch between SD card format and
 *  Whitesmiths 32 bit format (which is a rather peculiar
 *  PDP-11 format).
 */

#include <std.h>
#include "z80comp.h"
#include "z80sd.h"


/* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
 * (The CRC7 byte in the tables below are only for information,
 * it is calculated by the sdcommand routine.)
 */

/* CMD 0: GO_IDLE_STATE */
const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
/* CMD 8: SEND_IF_COND */
const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
/* CMD 9: SEND_CSD */
const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
/* CMD 10: SEND_CID */
const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
/* CMD 16: SET_BLOCKLEN, only if Byte addressing */
const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
/* CMD 55: APP_CMD followed by ACMD command */
const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
/* CMD 58: READ_OCR */
const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
/* ACMD 41: SEND_OP_COND */
const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};

/* Buffers
 */
unsigned char sdrdbuf[512];  /* recieved data from the SD card */

unsigned char ocrreg[4];     /* SD card OCR register */
unsigned char cidreg[16];    /* SD card CID register */
unsigned char csdreg[16];    /* SD card CSD register */

/* Variables for the SD card
 */
char *sdinitok;  /* SD card initialized and ready */
char *byteblkadr;   /* block address multiplier flag */
int curblkok;  /* if YES curblockno is read into buffer */
int partdsk;   /* partition/disk number, 0 = disk A */
int sdver2;    /* SD card version 2 if YES, version 1 if NO */
unsigned char curblkno[4];  /* block in buffer if curblkok == YES */

/* Initialise SD card interface
 *
 * returns YES if ok and NO if not ok
 *
 * References:
 *   https://www.sdcard.org/downloads/pls/
 *      Physical Layer Simplified Specification version 8.0
 *
 * A nice flowchart how to initialize:
 *   https://www.totalphase.com/blog/2018/08/set-sdc-mmc-cards-spi-mode-verify-files-successfully-programmed/
 *
 */
int sdinit()
    {
    int nbytes;  /* byte counter */
    int tries;   /* tries to get to active state or searching for data  */
    int wtloop;  /* timer loop when trying to enter active state */
    unsigned char cmdbuf[5];   /* buffer to build command in */
    unsigned char rstatbuf[5]; /* buffer to recieve status in */
    unsigned char *statptr;    /* pointer to returned status from SD command */
    unsigned char crc;         /* crc register for CID and CSD */
    unsigned char rbyte;       /* recieved byte */
    unsigned char *prtptr;     /* for debug printing */

    ledon();
    spideselect();
    *sdinitok = 0;

    /* start to generate 9*8 clock pulses with not selected SD card */
    for (nbytes = 9; 0 < nbytes; nbytes--)
        spiio(0xff);
    spiselect();

    /* CMD 0: GO_IDLE_STATE */
    for (tries = 0; tries < 10; tries++)
        {
        memcpy(cmdbuf, cmd0, 5);
        statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
        if (!statptr)
            {
            spideselect();
            ledoff();
            return (NO);
            }
        if (statptr[0] == 0x01)
            break;
        for (wtloop = 0; wtloop < tries * 10; wtloop++)
            {
            /* wait loop, time increasing for each try */
            spiio(0xff);
            }
        }

    /* CMD 8: SEND_IF_COND */
    memcpy(cmdbuf, cmd8, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
    if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
        sdver2 = NO;
    else
        {
        sdver2 = YES;
        if (statptr[4] != 0xaa) /* but invalid echo back */
            {
            spideselect();
            ledoff();
            return (NO);
            }
        }

    /* CMD 55: APP_CMD followed by ACMD 41: SEND_OP_COND until status is 0x00 */
    for (tries = 0; tries < 20; tries++)
        {
        memcpy(cmdbuf, cmd55, 5);
        statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
        if (!statptr)
            {
            spideselect();
            ledoff();
            return (NO);
            }
        memcpy(cmdbuf, acmd41, 5);
        if (sdver2)
            cmdbuf[1] = 0x40;
        else
            cmdbuf[1] = 0x00;
        statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
        if (!statptr)
            {
            spideselect();
            ledoff();
            return (NO);
            }
        if (statptr[0] == 0x00) /* now the SD card is ready */
            {
            break;
            }
        for (wtloop = 0; wtloop < tries * 10; wtloop++)
            {
            /* wait loop, time increasing for each try */
            spiio(0xff);
            }
        }

    /* CMD 58: READ_OCR */
    /* According to the flow chart this should not work
       for SD ver. 1 but the response is ok anyway
       all tested SD cards  */
    memcpy(cmdbuf, cmd58, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
    if (!statptr)
        {
        spideselect();
        ledoff();
        return (NO);
        }
    memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
    *byteblkadr = 0; /* assume block address */
    if (ocrreg[0] & 0x80)
        {
        /* SD Ver.2+ */
        if (!(ocrreg[0] & 0x40))
            {
            /* SD Ver.2+, Byte address */
            *byteblkadr = 1;
            }
        }

    /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
    if (*byteblkadr)
        {
        memcpy(cmdbuf, cmd16, 5);
        statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
        if (!statptr)
            {
            spideselect();
            ledoff();
            return (NO);
            }
        }
    /* Register information:
     *   https://www.cameramemoryspeed.com/sd-memory-card-faq/reading-sd-card-cid-serial-psn-internal-numbers/
     */

    /* CMD 10: SEND_CID */
    memcpy(cmdbuf, cmd10, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (!statptr)
        {
        spideselect();
        ledoff();
        return (NO);
        }
    /* looking for 0xfe that is the byte before data */
    for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
        ;
    if (tries == 0) /* tried too many times */
        {
        spideselect();
        ledoff();
        return (NO);
        }
    else
        {
        crc = 0;
        for (nbytes = 0; nbytes < 15; nbytes++)
            {
            rbyte = spiio(0xff);
            cidreg[nbytes] = rbyte;
            crc = CRC7_one(crc, rbyte);
            }
        cidreg[15] = spiio(0xff);
        crc |= 0x01;
        /* some SD cards need additional clock pulses */
        for (nbytes = 9; 0 < nbytes; nbytes--)
            spiio(0xff);
        }

    /* CMD 9: SEND_CSD */
    memcpy(cmdbuf, cmd9, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (!statptr)
        {
        spideselect();
        ledoff();
        return (NO);
        }
    /* looking for 0xfe that is the byte before data */
    for (tries = 20; (0 < tries) && (spiio(0xff) != 0xfe); tries--)
        ;
    if (tries == 0) /* tried too many times */
        return (NO);
    else
        {
        crc = 0;
        for (nbytes = 0; nbytes < 15; nbytes++)
            {
            rbyte = spiio(0xff);
            csdreg[nbytes] = rbyte;
            crc = CRC7_one(crc, rbyte);
            }
        csdreg[15] = spiio(0xff);
        crc |= 0x01;
        /* some SD cards need additional clock pulses */
        for (nbytes = 9; 0 < nbytes; nbytes--)
            spiio(0xff);
        }

    for (nbytes = 9; 0 < nbytes; nbytes--)
        spiio(0xff);

    *sdinitok = 1;

    spideselect();
    ledoff();

    return (YES);
    }

