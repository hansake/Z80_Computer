/*  z80sdbt.c Boot and SD card test program.
 *
 *  Boot code for my DIY Z80 Computer. This
 *  program is compiled with Whitesmiths/COSMIC
 *  C compiler for Z80.
 *
 *  Initializes the hardware and detects the
 *  presence and partitioning of an attached SD card.
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties are given.
 *  Hastily Cobbled Together 2021 and 2022
 *  by Hans-Ake Lund
 *
 */

#include <std.h>
#include "z80computer.h"
#include "builddate.h"

/* Program name and version */
#define PRGNAME "z80sdbt "
#define VERSION "version 0.8, "
/* Address in high RAM where to copy uploader */
#define UPLADDR 0xf000

/* This code should be cleaned up when
   remaining functions are implemented
 */
#define PARTZRO 0  /* Empty partition entry */
#define PARTMBR 1  /* MBR partition */
#define PARTEBR 2  /* EBR logical partition */
#define PARTGPT 3  /* GPT partition */
#define EBRCONT 20 /* EBR container partition in MBR */

struct partentry
    {
    char partype;
    char dskletter;
    int bootable;
    unsigned long dskstart;
    unsigned long dskend;
    unsigned long dsksize;
    unsigned char dsktype[16];
    } dskmap[16];

unsigned char dsksign[4]; /* MBR/EBR disk signature */

/* Function prototypes */
void sdmbrpart(unsigned long);

/* External data */
extern const char upload[];
extern const int upload_size;

/* RAM/EPROM probe */
const int ramprobe = 0;
int *rampptr;

/* Response length in bytes
 */
#define R1_LEN 1
#define R3_LEN 5
#define R7_LEN 5

/* The SD card commands (5 bytes) and a CRC7 byte as the last byte.
 * (The CRC7 byte in the tables below are only for information,
 * it is calculated by the sdcommand routine.)
 */
const unsigned char cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
const unsigned char cmd8[] = {0x48, 0x00, 0x00, 0x01, 0xaa, 0x87};
const unsigned char cmd9[] = {0x49, 0x00, 0x00, 0x00, 0x00, 0xaf};
const unsigned char cmd10[] = {0x4a, 0x00, 0x00, 0x00, 0x00, 0x1b};
const unsigned char cmd16[] = {0x50, 0x00, 0x00, 0x02, 0x00, 0x15};
const unsigned char cmd17[] = {0x51, 0x00, 0x00, 0x00, 0x00, 0x55};
const unsigned char cmd24[] = {0x58, 0x00, 0x00, 0x00, 0x00, 0x6f};
const unsigned char cmd55[] = {0x77, 0x00, 0x00, 0x00, 0x00, 0x65};
const unsigned char cmd58[] = {0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd};
const unsigned char acmd41[] = {0x69, 0x40, 0x00, 0x01, 0xaa, 0x33};

/* Partition identifiers
 */
/* For GPT I have decided that a CP/M partition
 * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
 */
const unsigned char gptcpm[] =
    {
    0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
    0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
    };
/* For MBR/EBR the partition type for CP/M is 0x52
 * according to: https://en.wikipedia.org/wiki/Partition_type
 */
const unsigned char mbrcpm = 0x52;    /* CP/M partition */
const unsigned char mbrexcode = 0x5f; /* Z80 executable code partition */
/* has a special format that */
/* includes number of sectors to */
/* load and a signature, TBD */

/* Buffers
 */
unsigned char sdrdbuf[512];  /* recieved data from the SD card */

unsigned char ocrreg[4];     /* SD card OCR register */
unsigned char cidreg[16];    /* SD card CID register */
unsigned char csdreg[16];    /* SD card CSD register */
unsigned long ebrrecs[4];    /* detected EBR records to process */
int ebrrecidx; /* how many EBR records that are populated */
unsigned long ebrnext; /* next chained ebr record */

/* Variables
 */
int curblkok;  /* if YES curblockno is read into buffer */
int partdsk;   /* partition/disk number, 0 = disk A */
int sdinitok;  /* SD card initialized and ready */
int sdver2;    /* SD card version 2 if YES, version 1 if NO */
unsigned long blkmult;   /* block address multiplier */
unsigned long curblkno;  /* block in buffer if curblkok == YES */

/* debug bool */
int sdtestflg;

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
    sdinitok = NO;

    /* start to generate 9*8 clock pulses with not selected SD card */
    for (nbytes = 9; 0 < nbytes; nbytes--)
        spiio(0xff);
    if (sdtestflg)
        {
        printf("\nSent 8*8 (72) clock pulses, select not active\n");
        } /* sdtestflg */
    spiselect();

    /* CMD0: GO_IDLE_STATE */
    for (tries = 0; tries < 10; tries++)
        {
        memcpy(cmdbuf, cmd0, 5);
        statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
        if (sdtestflg)
            {
            if (!statptr)
                printf("CMD0: no response\n");
            else
                printf("CMD0: GO_IDLE_STATE, R1 response [%02x]\n", statptr[0]);
            } /* sdtestflg */
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

    /* CMD8: SEND_IF_COND */
    memcpy(cmdbuf, cmd8, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R7_LEN);
    if (sdtestflg)
        {
        if (!statptr)
            printf("CMD8: no response\n");
        else
            {
            printf("CMD8: SEND_IF_COND, R7 response [%02x %02x %02x %02x %02x], ",
                   statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
            if (!(statptr[0] & 0xfe)) /* no error */
                {
                if (statptr[4] == 0xaa)
                    printf("echo back ok, ");
                else
                    printf("invalid echo back\n");
                }
            }
        } /* sdtestflg */
    if (!statptr || (statptr[0] & 0xfe)) /* if no answer or error */
        {
        sdver2 = NO;
        if (sdtestflg)
            {
            printf("probably SD ver. 1\n");
            } /* sdtestflg */
        }
    else
        {
        sdver2 = YES;
        if (statptr[4] != 0xaa) /* but invalid echo back */
            {
            spideselect();
            ledoff();
            return (NO);
            }
        if (sdtestflg)
            {
            printf("SD ver 2\n");
            } /* sdtestflg */
        }

    /* CMD55: APP_CMD followed by ACMD41: SEND_OP_COND until status is 0x00 */
    for (tries = 0; tries < 20; tries++)
        {
        memcpy(cmdbuf, cmd55, 5);
        statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
        if (sdtestflg)
            {
            if (!statptr)
                printf("CMD55: no response\n");
            else
                printf("CMD55: APP_CMD, R1 response [%02x]\n", statptr[0]);
            } /* sdtestflg */
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
        if (sdtestflg)
            {
            if (!statptr)
                printf("ACMD41: no response\n");
            else
                printf("ACMD41: SEND_OP_COND, R1 response [%02x]%s\n",
                       statptr[0], (statptr[0] == 0x00) ? " - ready" : "");
            } /* sdtestflg */
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

    /* CMD58: READ_OCR */
    /* According to the flow chart this should not work
       for SD ver. 1 but the response is ok anyway
       all tested SD cards  */
    memcpy(cmdbuf, cmd58, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
    if (sdtestflg)
        {
        if (!statptr)
            printf("CMD58: no response\n");
        else
            printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
                   statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
        } /* sdtestflg */
    if (!statptr)
        {
        spideselect();
        ledoff();
        return (NO);
        }
    memcpy(&ocrreg[0], &statptr[1], sizeof (ocrreg));
    blkmult = 1; /* assume block address */
    if (ocrreg[0] & 0x80)
        {
        /* SD Ver.2+ */
        if (!(ocrreg[0] & 0x40))
            {
            /* SD Ver.2+, Byte address */
            blkmult = 512;
            }
        }

    /* CMD 16: SET_BLOCKLEN, only if Byte addressing */
    if (blkmult == 512)
        {
        memcpy(cmdbuf, cmd16, 5);
        statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
        if (sdtestflg)
            {
            if (!statptr)
                printf("CMD16: no response\n");
            else
                printf("CMD16: SET_BLOCKLEN (to 512 bytes), R1 response [%02x]\n",
                       statptr[0]);
            } /* sdtestflg */
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

    /* CMD10: SEND_CID */
    memcpy(cmdbuf, cmd10, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (sdtestflg)
        {
        if (!statptr)
            printf("CMD10: no response\n");
        else
            printf("CMD10: SEND_CID, R1 response [%02x]\n", statptr[0]);
        } /* sdtestflg */
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
        if (sdtestflg)
            {
            printf("  No data found\n");
            } /* sdtestflg */
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
        if (sdtestflg)
            {
            prtptr = &cidreg[0];
            printf("  CID: [");
            for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
                printf("%02x ", *prtptr);
            prtptr = &cidreg[0];
            printf("\b] |");
            for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
                {
                if ((' ' <= *prtptr) && (*prtptr < 127))
                    putchar(*prtptr);
                else
                    putchar('.');
                }
            printf("|\n");
            if (crc == cidreg[15])
                {
                printf("CRC7 ok: [%02x]\n", crc);
                }
            else
                {
                printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
                       crc, cidreg[15]);
                /* could maybe return failure here */
                }
            } /* sdtestflg */
        }

    /* CMD9: SEND_CSD */
    memcpy(cmdbuf, cmd9, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (sdtestflg)
        {
        if (!statptr)
            printf("CMD9: no response\n");
        else
            printf("CMD9: SEND_CSD, R1 response [%02x]\n", statptr[0]);
        } /* sdtestflg */
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
        if (sdtestflg)
            {
            printf("  No data found\n");
            } /* sdtestflg */
        return (NO);
        }
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
        if (sdtestflg)
            {
            prtptr = &csdreg[0];
            printf("  CSD: [");
            for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
                printf("%02x ", *prtptr);
            prtptr = &csdreg[0];
            printf("\b] |");
            for (nbytes = 0; nbytes < 16; nbytes++, prtptr++)
                {
                if ((' ' <= *prtptr) && (*prtptr < 127))
                    putchar(*prtptr);
                else
                    putchar('.');
                }
            printf("|\n");
            if (crc == csdreg[15])
                {
                printf("CRC7 ok: [%02x]\n", crc);
                }
            else
                {
                printf("CRC7 error, calculated: [%02x], recieved: [%02x]\n",
                       crc, csdreg[15]);
                /* could maybe return failure here */
                }
            } /* sdtestflg */
        }

    for (nbytes = 9; 0 < nbytes; nbytes--)
        spiio(0xff);
    if (sdtestflg)
        {
        printf("Sent 9*8 (72) clock pulses, select active\n");
        } /* sdtestflg */

    sdinitok = YES;

    spideselect();
    ledoff();

    return (YES);
    }

int sdprobe()
    {
    unsigned char cmdbuf[5];   /* buffer to build command in */
    unsigned char rstatbuf[5]; /* buffer to recieve status in */
    unsigned char *statptr;    /* pointer to returned status from SD command */
    int nbytes;  /* byte counter */
    int allzero = YES;

    ledon();
    spiselect();

    /* CMD58: READ_OCR */
    memcpy(cmdbuf, cmd58, 5);
    statptr = sdcommand(cmdbuf, rstatbuf, R3_LEN);
    for (nbytes = 0; nbytes < 5; nbytes++)
        {
        if (statptr[nbytes] != 0)
            allzero = NO;
        }
    if (sdtestflg)
        {
        if (!statptr)
            printf("CMD58: no response\n");
        else
            {
            printf("CMD58: READ_OCR, R3 response [%02x %02x %02x %02x %02x]\n",
                   statptr[0], statptr[1], statptr[2], statptr[3], statptr[4]);
            if (allzero)
                printf("SD card not inserted or not initialized\n");
            }
        } /* sdtestflg */
    if (!statptr || allzero)
        {
        sdinitok = NO;
        spideselect();
        ledoff();
        return (NO);
        }

    spideselect();
    ledoff();

    return (YES);
    }

/* print OCR, CID and CSD registers*/
void sdprtreg()
    {
    unsigned int n;
    unsigned int csize;
    unsigned long devsize;
    unsigned long capacity;

    if (!sdinitok)
        {
        printf("SD card not initialized\n");
        return;
        }
    printf("SD card information:");
    if (ocrreg[0] & 0x80)
        {
        if (ocrreg[0] & 0x40)
            printf("  SD card ver. 2+, Block address\n");
        else
            {
            if (sdver2)
                printf("  SD card ver. 2+, Byte address\n");
            else
                printf("  SD card ver. 1, Byte address\n");
            }
        }
    printf("  Manufacturer ID: 0x%02x, ", cidreg[0]);
    printf("OEM ID: %.2s, ", &cidreg[1]);
    printf("Product name: %.5s\n", &cidreg[3]);
    printf("  Product revision: %d.%d, ",
           (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
    printf("Serial number: %lu\n",
           (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
    printf("  Manufacturing date: %d-%d, ",
           2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
    if ((csdreg[0] & 0xc0) == 0x00) /* CSD version 1 */
        {
        n = (csdreg[5] & 0x0F) + ((csdreg[10] & 0x80) >> 7) + ((csdreg[9] & 0x03) << 1) + 2;
        csize = (csdreg[8] >> 6) + ((unsigned int) csdreg[7] << 2) +
                ((unsigned int) (csdreg[6] & 0x03) << 10) + 1;
        capacity = (unsigned long) csize << (n-10);
        printf("Device capacity: %lu MByte\n", capacity >> 10);
        }
    if ((csdreg[0] & 0xc0) == 0x40) /* CSD version 2 */
        {
        devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
                  ((unsigned long)(csdreg[7] & 63) << 16) + 1;
        capacity = devsize << 9;
        printf("Device capacity: %lu MByte\n", capacity >> 10);
        }
    if ((csdreg[0] & 0xc0) == 0x80) /* CSD version 3 */
        {
        devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8) +
                  ((unsigned long)(csdreg[7] & 63) << 16) + 1;
        capacity = devsize << 9;
        printf("Device ultra capacity: %lu MByte\n", capacity >> 10);
        }

    if (sdtestflg)
        {

        printf("--------------------------------------\n");
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
                if (sdver2)
                    printf("  SD Ver.2+, Byte address");
                else
                    printf("  SD Ver.1, Byte address");
                }
            printf("\nCard power up status bit (busy) (bit 31) set\n");
            }
        else
            {
            printf("\nCard power up status bit (busy) (bit 31) not set.\n");
            printf("  This bit is not set if the card has not finished the power up routine.\n");
            }
        printf("--------------------------------------\n");
        printf("CID register:\n");
        printf("MID: 0x%02x, ", cidreg[0]);
        printf("OID: %.2s, ", &cidreg[1]);
        printf("PNM: %.5s, ", &cidreg[3]);
        printf("PRV: %d.%d, ",
               (cidreg[8] >> 4) & 0x0f, cidreg[8] & 0x0f);
        printf("PSN: %lu, ",
               (cidreg[9] << 24) + (cidreg[10] << 16) + (cidreg[11] << 8) + cidreg[12]);
        printf("MDT: %d-%d\n",
               2000 + ((cidreg[13] & 0x0f) << 4) + (cidreg[14] >> 4), cidreg[14] & 0x0f);
        printf("--------------------------------------\n");
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
            {
            printf("CSD Version 3.0, Ultra Capacity (SDUC)\n");
            devsize = csdreg[9] + ((unsigned long)csdreg[8] << 8)
                      + ((unsigned long)(csdreg[7] & 63) << 16) + 1;
            capacity = devsize << 9;
            printf(" Device capacity: %lu KByte, %lu MByte\n",
                   capacity, capacity >> 10);
            }
        printf("--------------------------------------\n");

        } /* sdtestflg */ /* SDTEST */

    }

/* Read data block of 512 bytes to buffer
 * Returns YES if ok or NO if error
 */
int sdread(unsigned char *rdbuf, unsigned long rdblkno)
    {
    unsigned char *statptr;
    unsigned char rbyte;
    unsigned char cmdbuf[5];   /* buffer to build command in */
    unsigned char rstatbuf[5]; /* buffer to recieve status in */
    int nbytes;
    int tries;
    unsigned long blktoread;
    unsigned int rxcrc16;
    unsigned int calcrc16;

    ledon();
    spiselect();

    if (!sdinitok)
        {
        if (sdtestflg)
            {
            printf("SD card not initialized\n");
            } /* sdtestflg */
        spideselect();
        ledoff();
        return (NO);
        }

    /* CMD17: READ_SINGLE_BLOCK */
    /* Insert block # into command */
    memcpy(cmdbuf, cmd17, 5);
    blktoread = blkmult * rdblkno;
    cmdbuf[4] = blktoread & 0xff;
    blktoread = blktoread >> 8;
    cmdbuf[3] = blktoread & 0xff;
    blktoread = blktoread >> 8;
    cmdbuf[2] = blktoread & 0xff;
    blktoread = blktoread >> 8;
    cmdbuf[1] = blktoread & 0xff;

    if (sdtestflg)
        {
        printf("\nCMD17: READ_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
               cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
        } /* sdtestflg */
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (sdtestflg)
        {
        printf("CMD17 R1 response [%02x]\n", statptr[0]);
        } /* sdtestflg */
    if (statptr[0])
        {
        if (sdtestflg)
            {
            printf("  could not read block\n");
            } /* sdtestflg */
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
            if (sdtestflg)
                {
                printf("  read error: [%02x]\n", rbyte);
                } /* sdtestflg */
            spideselect();
            ledoff();
            return (NO);
            }
        }
    if (tries == 0) /* tried too many times */
        {
        if (sdtestflg)
            {
            printf("  no data found\n");
            } /* sdtestflg */
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

        if (sdtestflg)
            {
            printf("  read data block %ld:\n", rdblkno);
            } /* sdtestflg */
        if (rxcrc16 != calcrc16)
            {
            if (sdtestflg)
                {
                printf("  CRC16 error, recieved: 0x%04x, calc: 0x%04hi\n",
                       rxcrc16, calcrc16);
                } /* sdtestflg */
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
int sdwrite(unsigned char *wrbuf, unsigned long wrblkno)
    {
    unsigned char *statptr;
    unsigned char rbyte;
    unsigned char tbyte;
    unsigned char cmdbuf[5];   /* buffer to build command in */
    unsigned char rstatbuf[5]; /* buffer to recieve status in */
    int nbytes;
    int tries;
    unsigned long blktowrite;
    unsigned int calcrc16;

    ledon();
    spiselect();

    if (!sdinitok)
        {
        if (sdtestflg)
            {
            printf("SD card not initialized\n");
            } /* sdtestflg */
        spideselect();
        ledoff();
        return (NO);
        }

    if (sdtestflg)
        {
        printf("  write data block %ld:\n", wrblkno);
        } /* sdtestflg */
    /* CMD24: WRITE_SINGLE_BLOCK */
    /* Insert block # into command */
    memcpy(cmdbuf, cmd24, 5);
    blktowrite = blkmult * wrblkno;
    cmdbuf[4] = blktowrite & 0xff;
    blktowrite = blktowrite >> 8;
    cmdbuf[3] = blktowrite & 0xff;
    blktowrite = blktowrite >> 8;
    cmdbuf[2] = blktowrite & 0xff;
    blktowrite = blktowrite >> 8;
    cmdbuf[1] = blktowrite & 0xff;

    if (sdtestflg)
        {
        printf("\nCMD24: WRITE_SINGLE_BLOCK, command [%02x %02x %02x %02x %02x]\n",
               cmdbuf[0], cmdbuf[1], cmdbuf[2], cmdbuf[3], cmdbuf[4]);
        } /* sdtestflg */
    statptr = sdcommand(cmdbuf, rstatbuf, R1_LEN);
    if (sdtestflg)
        {
        printf("CMD24 R1 response [%02x]\n", statptr[0]);
        } /* sdtestflg */
    if (statptr[0])
        {
        if (sdtestflg)
            {
            printf("  could not write block\n");
            } /* sdtestflg */
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
        if (sdtestflg)
            {
            printf("No data response\n");
            } /* sdtestflg */
        spideselect();
        ledoff();
        return (NO);
        }
    else
        {
        if (sdtestflg)
            {
            printf("Data response [%02x]", 0x1f & rbyte);
            } /* sdtestflg */
        if ((0x1f & rbyte) == 0x05)
            {
            if (sdtestflg)
                {
                printf(", data accepted\n");
                } /* sdtestflg */
            for (nbytes = 9; 0 < nbytes; nbytes--)
                spiio(0xff);
            if (sdtestflg)
                {
                printf("Sent 9*8 (72) clock pulses, select active\n");
                } /* sdtestflg */
            spideselect();
            ledoff();
            return (YES);
            }
        else
            {
            if (sdtestflg)
                {
                printf(", data not accepted\n");
                } /* sdtestflg */
            spideselect();
            ledoff();
            return (NO);
            }
        }
    }

/* Print data in 512 byte buffer */
void sddatprt(unsigned char *prtbuf)
    {
    /* Variables used for "pretty-print" */
    int allzero, dmpline, dotprted, lastallz, nbytes;
    unsigned char *prtptr;

    prtptr = prtbuf;
    dotprted = NO;
    lastallz = NO;
    for (dmpline = 0; dmpline < 32; dmpline++)
        {
        /* test if all 16 bytes are 0x00 */
        allzero = YES;
        for (nbytes = 0; nbytes < 16; nbytes++)
            {
            if (prtptr[nbytes] != 0)
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
            for (nbytes = 0; nbytes < 16; nbytes++)
                printf("%02x ", prtptr[nbytes]);
            /* print these bytes in ASCII if printable */
            printf(" |");
            for (nbytes = 0; nbytes < 16; nbytes++)
                {
                if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
                    putchar(prtptr[nbytes]);
                else
                    putchar('.');
                }
            printf("|\n");
            }
        prtptr += 16;
        lastallz = allzero;
        }
    }

/* Print GUID (mixed endian format)
 */
void prtguid(unsigned char *guidptr)
    {
    int index;

    printf("%02x%02x%02x%02x-", guidptr[3], guidptr[2], guidptr[1], guidptr[0]);
    printf("%02x%02x-", guidptr[5], guidptr[4]);
    printf("%02x%02x-", guidptr[7], guidptr[6]);
    printf("%02x%02x-", guidptr[8], guidptr[9]);
    printf("%02x%02x%02x%02x%02x%02x",
           guidptr[10], guidptr[11], guidptr[12], guidptr[13], guidptr[14], guidptr[15]);
    }

/* Analyze and print GPT entry
 */
int prtgptent(unsigned int entryno)
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
    if ((curblkno != block) || !curblkok)
        {
        if (!sdread(sdrdbuf, block))
            {
            if (sdtestflg)
                {
                printf("Can't read GPT entry block\n");
                return (NO);
                } /* sdtestflg */
            }
        curblkno = block;
        curblkok = YES;
        }
    rxdata = sdrdbuf;
    entryptr = rxdata + (128 * (entryno % 4));
    for (index = 0; index < 16; index++)
        tstzero |= entryptr[index];
    if (sdtestflg)
        {
        printf("GPT partition entry %d:", entryno + 1);
        } /* sdtestflg */
    if (!tstzero)
        {
        if (sdtestflg)
            {
            printf(" Not used entry\n");
            } /* sdtestflg */
        return (NO);
        }
    if (sdtestflg)
        {
        printf("\n  Partition type GUID: ");
        prtguid(entryptr);
        printf("\n  [");
        for (index = 0; index < 16; index++)
            printf("%02x ", entryptr[index]);
        printf("\b]");
        printf("\n  Unique partition GUID: ");
        prtguid(entryptr + 16);
        printf("\n  [");
        for (index = 0; index < 16; index++)
            printf("%02x ", (entryptr + 16)[index]);
        printf("\b]");
        printf("\n  First LBA: ");
        /* lower 32 bits of LBA should be sufficient (I hope) */
        } /* sdtestflg */
    flba = (unsigned long)entryptr[32] + ((unsigned long)entryptr[33] << 8) +
           ((unsigned long)entryptr[34] << 16) + ((unsigned long)entryptr[35] << 24);
    if (sdtestflg)
        {
        printf("%lu", flba);
        printf(" [");
        for (index = 32; index < (32 + 8); index++)
            printf("%02x ", entryptr[index]);
        printf("\b]");
        printf("\n  Last LBA: ");
        } /* sdtestflg */
    /* lower 32 bits of LBA should be sufficient (I hope) */
    llba = (unsigned long)entryptr[40] + ((unsigned long)entryptr[41] << 8) +
           ((unsigned long)entryptr[42] << 16) + ((unsigned long)entryptr[43] << 24);

    if (entryptr[48] & 0x04)
        dskmap[partdsk].bootable = YES;
    dskmap[partdsk].partype = PARTGPT;
    dskmap[partdsk].dskletter = 'A' + partdsk;
    dskmap[partdsk].dskstart = flba;
    dskmap[partdsk].dskend = llba;
    dskmap[partdsk].dsksize = llba - flba + 1;
    memcpy(dskmap[partdsk].dsktype, entryptr, 16);
    partdsk++;

    if (sdtestflg)
        {
        printf("%lu, size %lu MByte", llba, (llba - flba) >> 11);
        printf(" [");
        for (index = 40; index < (40 + 8); index++)
            printf("%02x ", entryptr[index]);
        printf("\b]");
        printf("\n  Attribute flags: [");
        /* bits 0 - 2 and 60 - 63 should be decoded */
        for (index = 0; index < 8; index++)
            {
            entryidx = index + 48;
            printf("%02x ", entryptr[entryidx]);
            }
        printf("\b]\n  Partition name:  ");
        } /* sdtestflg */
    /* partition name is in UTF-16LE code units */
    hasname = NO;
    for (index = 0; index < 72; index += 2)
        {
        entryidx = index + 56;
        if ((entryptr[entryidx] | entryptr[entryidx + 1]) == 0)
            break;
        if (sdtestflg)
            {
            if ((' ' <= entryptr[entryidx]) && (entryptr[entryidx] < 127))
                putchar(entryptr[entryidx]);
            else
                putchar('.');
            } /* sdtestflg */
        hasname = YES;
        }
    if (sdtestflg)
        {
        if (!hasname)
            printf("name field empty");
        printf("\n");
        printf("   [");
        for (index = 0; index < 72; index++)
            {
            if (((index & 0xf) == 0) && (index != 0))
                printf("\n    ");
            entryidx = index + 56;
            printf("%02x ", entryptr[entryidx]);
            }
        printf("\b]\n");
        } /* sdtestflg */
    return (YES);
    }

/* Analyze and print GPT header
 */
void sdgpthdr(unsigned long block)
    {
    int index;
    unsigned int partno;
    unsigned char *rxdata;
    unsigned long entries;

    if (sdtestflg)
        {
        printf("GPT header\n");
        } /* sdtestflg */
    if (!sdread(sdrdbuf, block))
        {
        if (sdtestflg)
            {
            printf("Can't read GPT partition table header\n");
            } /* sdtestflg */
        return;
        }
    curblkno = block;
    curblkok = YES;

    rxdata = sdrdbuf;
    if (sdtestflg)
        {
        printf("  Signature: %.8s\n", &rxdata[0]);
        printf("  Revision: %d.%d [%02x %02x %02x %02x]\n",
               (int)rxdata[8] * ((int)rxdata[9] << 8),
               (int)rxdata[10] + ((int)rxdata[11] << 8),
               rxdata[8], rxdata[9], rxdata[10], rxdata[11]);
        entries = (unsigned long)rxdata[80] + ((unsigned long)rxdata[81] << 8) +
                  ((unsigned long)rxdata[82] << 16) + ((unsigned long)rxdata[83] << 24);
        printf("  Number of partition entries: %lu (may be actual or maximum)\n", entries);
        } /* sdtestflg */
    for (partno = 0; (partno < 16) && (partdsk < 16); partno++)
        {
        if (!prtgptent(partno))
            {
            if (!sdtestflg)
                {
                /* go through all entries if compiled as test program */
                return;
                } /* sdtestflg */
            }
        }
    if (sdtestflg)
        {
        printf("First 16 GPT entries scanned\n");
        } /* sdtestflg */
    }

/* Analyze and print MBR partition entry
 * Returns:
 *    -1 if errror - should not happen
 *     0 if not used entry
 *     1 if MBR entry
 *     2 if EBR entry
 *     3 if GTP entry
 */
int sdmbrentry(unsigned char *partptr)
    {
    int index;
    int parttype;
    unsigned long lbastart;
    unsigned long lbasize;

    parttype = PARTMBR;
    if (!partptr[4])
        {
        if (sdtestflg)
            {
            printf("Not used entry\n");
            } /* sdtestflg */
        return (PARTZRO);
        }
    if (sdtestflg)
        {
        printf("Boot indicator: 0x%02x, System ID: 0x%02x\n",
               partptr[0], partptr[4]);

        if ((partptr[4] == 0x05) || (partptr[4] == 0x0f))
            {
            printf("  Extended partition entry\n");
            }
        if (partptr[0] & 0x01)
            {
            printf("  Unofficial 48 bit LBA Proposed MBR Format, no CHS\n");
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
        } /* sdtestflg */
    /* not showing high 16 bits if 48 bit LBA */
    lbastart = (unsigned long)partptr[8] +
               ((unsigned long)partptr[9] << 8) +
               ((unsigned long)partptr[10] << 16) +
               ((unsigned long)partptr[11] << 24);
    lbasize = (unsigned long)partptr[12] +
              ((unsigned long)partptr[13] << 8) +
              ((unsigned long)partptr[14] << 16) +
              ((unsigned long)partptr[15] << 24);

    if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
        {
        if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
            {
            parttype = PARTEBR;
            if (curblkno == 0) /* points to EBR in the MBR */
                {
                ebrnext = 0;
                dskmap[partdsk].partype = EBRCONT;
                dskmap[partdsk].dskletter = 'A' + partdsk;
                dskmap[partdsk].dskstart = lbastart;
                dskmap[partdsk].dskend = lbastart + lbasize - 1;
                dskmap[partdsk].dsksize = lbasize;
                dskmap[partdsk].dsktype[0] = partptr[4];
                partdsk++;
                ebrrecs[ebrrecidx++] = lbastart; /* save to handle later */
                }
            else
                {
                ebrnext = curblkno + lbastart;
                }
            }
        else
            {
            if (0 < lbasize) /* one more ugly hack to avoid empty partitions */
                {
                if (partptr[0] & 0x80)
                    dskmap[partdsk].bootable = YES;
                if (curblkno == 0)
                    dskmap[partdsk].partype = PARTMBR;
                else
                    dskmap[partdsk].partype = PARTEBR;
                dskmap[partdsk].dskletter = 'A' + partdsk;
                dskmap[partdsk].dskstart = curblkno + lbastart;
                dskmap[partdsk].dskend = curblkno + lbastart + lbasize - 1;
                dskmap[partdsk].dsksize = lbasize;
                dskmap[partdsk].dsktype[0] = partptr[4];
                partdsk++;
                }
            }
        }

    if (sdtestflg)
        {
        printf("  partition start LBA: %lu [%08lx]\n",
               curblkno + lbastart, curblkno + lbastart);
        printf("  partition size LBA: %lu [%08lx], %lu MByte\n",
               lbasize, lbasize, lbasize >> 11);
        } /* sdtestflg */
    if (partptr[4] == 0xee) /* GPT partitions */
        {
        parttype = PARTGPT;
        if (sdtestflg)
            {
            printf("GTP partitions\n");
            } /* sdtestflg */
        sdgpthdr(lbastart); /* handle GTP partitions */
        /* re-read MBR on sector 0
           This is probably not needed as there
           is only one entry (the first one)
           in the MBR when using GPT */
        if (sdread(sdrdbuf, 0))
            {
            curblkno = 0;
            curblkok = YES;
            }
        else
            {
            if (sdtestflg)
                {
                printf("  can't read MBR on sector 0\n");
                } /* sdtestflg */
            return(-1);
            }
        }
    return (parttype);
    }

/* Read and analyze MBR/EBR partition sector block
 * and go through and print partition entries.
 */
void sdmbrpart(unsigned long sector)
    {
    int partidx;  /* partition index 1 - 4 */
    int cpartidx; /* chain partition index 1 - 4 */
    int chainidx;
    int enttype;
    unsigned char *entp; /* pointer to partition entry */
    char *mbrebr;

    if (sdtestflg)
        {
        if (sector == 0) /* if sector 0 it is MBR else it is EBR */
            mbrebr = "MBR";
        else
            mbrebr = "EBR";
        printf("Read %s from sector %lu\n", mbrebr, sector);
        } /* sdtestflg */
    if (sdread(sdrdbuf, sector))
        {
        curblkno = sector;
        curblkok = YES;
        }
    else
        {
        if (sdtestflg)
            {
            printf("  can't read %s sector %lu\n", mbrebr, sector);
            } /* sdtestflg */
        return;
        }
    if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
        {
        if (sdtestflg)
            {
            printf("  no %s boot signature found\n", mbrebr);
            } /* sdtestflg */
        return;
        }
    if (curblkno == 0)
        {
        memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
        if (sdtestflg)
            {

            printf("  disk identifier: 0x%02x%02x%02x%02x\n",
                   dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
            } /* sdtestflg */
        }
    /* go through MBR partition entries until first empty */
    /* !!as the MBR entry routine is called recusively a way is
       needed to read sector 0 when going back to MBR if
       there is a primary partition entry after an EBR entry!! */
    entp = &sdrdbuf[0x01be] ;
    for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
        {
        if (sdtestflg)
            {
            printf("%s partition entry %d: ", mbrebr, partidx);
            } /* sdtestflg */
        enttype = sdmbrentry(entp);
        if (enttype == -1) /* read error */
                 return;
        else if (enttype == PARTZRO)
            {
            if (!sdtestflg)
                {
                /* if compiled as test program show also empty partitions */
                break;
                } /* sdtestflg */
            }
        }
    /* now handle the previously saved EBR partition sectors */
    for (partidx = 0; (partidx < ebrrecidx) && (partdsk < 16); partidx++)
        {
        if (sdread(sdrdbuf, ebrrecs[partidx]))
            {
            curblkno = ebrrecs[partidx];
            curblkok = YES;
            }
        else
            {
            if (sdtestflg)
                {
                printf("  can't read %s sector %lu\n", mbrebr, sector);
                } /* sdtestflg */
            return;
            }
        entp = &sdrdbuf[0x01be] ;
        for (partidx = 1; (partidx <= 4) && (partdsk < 16); partidx++, entp += 16)
            {
            if (sdtestflg)
                {
                printf("EBR partition entry %d: ", partidx);
                } /* sdtestflg */
            enttype = sdmbrentry(entp);
            if (enttype == -1) /* read error */
                 return;
            else if (enttype == PARTZRO) /* empty partition entry */
                {
                if (sdtestflg)
                    {
                    /* if compiled as test program show also empty partitions */
                    printf("Empty partition entry\n");
                    } /* sdtestflg */
                else
                    break;
                }
            else if (enttype == PARTEBR) /* next chained EBR */
                {
                if (sdtestflg)
                    {
                    printf("EBR chain\n");
                    } /* sdtestflg */
                /* follow the EBR chain */
                for (chainidx = 0;
                    ebrnext && (chainidx < 16) && (partdsk < 16);
                    chainidx++)
                    {
                    /* ugly hack to stop reading the same sector */
                    if (ebrnext == curblkno)
                         break;
                    if (sdread(sdrdbuf, ebrnext))
                        {
                        curblkno = ebrnext;
                        curblkok = YES;
                        }
                    else
                        {
                        if (sdtestflg)
                            {
                            printf("  can't read %s sector %lu\n", mbrebr, sector);
                            } /* sdtestflg */
                        return;
                        }
                    entp = &sdrdbuf[0x01be] ;
                    for (cpartidx = 1;
                        (cpartidx <= 4) && (partdsk < 16);
                        cpartidx++, entp += 16)
                        {
                        if (sdtestflg)
                            {
                            printf("EBR chained  partition entry %d: ",
                                 cpartidx);
                            } /* sdtestflg */
                        enttype = sdmbrentry(entp);
                        if (enttype == -1) /* read error */
                            return;
                        }
                    }
                }
            }
        }
    }

/* Executing in RAM or EPROM
 */
void execin()
    {
    printf(", executing in: ");
    rampptr = &ramprobe;
    *rampptr = 1; /* try to change const */
    if (ramprobe)
        printf("RAM\n");
    else
        printf("EPROM\n");
    *rampptr = 0;
    }

/* Test init, read and partitions on SD card over the SPI interface,
 * boot from SD card, upload with Xmodem
 */
int main()
    {
    char txtin[10];
    int cmdin;
    int idx;
    int cmpidx;
    unsigned char *cmpptr;
    int inlength;
    unsigned long blockno;

    blockno = 0;
    curblkno = 0;
    curblkok = NO;
    sdinitok = NO; /* SD card not initialized yet */

    printf(PRGNAME);
    printf(VERSION);
    printf(builddate);
    execin();
    while (YES) /* forever (until Ctrl-C) */
        {
        printf("cmd (? for help): ");

        cmdin = getchar();
        switch (cmdin)
            {
            case '?':
                printf(" ? - help\n");
                printf(PRGNAME);
                printf(VERSION);
                printf(builddate);
                execin();
                printf("Commands:\n");
                printf("  ? - help\n");
                printf("  b - boot from SD card\n");
                printf("  d - debug on/off\n");
                printf("  i - initialize SD card\n");
                printf("  l - print SD card partition layout\n");
                printf("  n - set/show sector #N to read/write\n");
                printf("  p - print sector last read/to write\n");
                printf("  r - read sector #N\n");
                printf("  s - print SD registers\n");
                printf("  t - test probe SD card\n");
                printf("  u - upload code with Xmodem to RAM address 0x0000\n");
                printf("  w - write sector #N\n");
                printf("  Ctrl-C to reload monitor from EPROM\n");
                break;
            case 'b':
                printf(" d - boot from SD card - ");
                printf("implementation ongoing\n");
                break;
            case 'd':
                printf(" d - toggle debug flag - ");
                if (sdtestflg)
                    {
                    sdtestflg = NO;
                    printf("OFF\n");
                    }
                else
                    {
                    sdtestflg = YES;
                    printf("ON\n");
                    }
                break;
            case 'i':
                printf(" i - initialize SD card");
                if (sdinit())
                    printf(" - ok\n");
                else
                    printf(" - not inserted or faulty\n");
                break;
            case 'l':
                printf(" l - print partition layout\n");
                if (!sdprobe())
                    {
                    printf(" - SD not initialized or inserted or faulty\n");
                    break;
                    }
                ebrrecidx = 0;
                partdsk = 0;
                memset(dskmap, 0, sizeof dskmap);
                sdmbrpart(0);
                printf("      Disk partition sectors on SD card\n");
                printf("       MBR disk identifier: 0x%02x%02x%02x%02x\n",
                       dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
                printf(" Disk     Start      End     Size Part Type Id\n");
                printf(" ----     -----      ---     ---- ---- ---- --\n");
                for (idx = 0; idx < 16; idx++)
                    {
                    if (dskmap[idx].dskletter)
                        {
                        printf("%2d (%c)%c", dskmap[idx].dskletter - 'A' + 1,
                               dskmap[idx].dskletter,
                               dskmap[idx].bootable ? '*' : ' ');
                        printf("%8lu %8lu %8lu ",
                               dskmap[idx].dskstart, dskmap[idx].dskend,
                               dskmap[idx].dsksize);
                        if (dskmap[idx].partype == EBRCONT)
                            {
                            printf(" EBR container\n");
                            }
                        else
                            {
                            if (dskmap[idx].partype == PARTGPT)
                                {
                                printf(" GPT ");
                                /*if (memcmp(dskmap[idx].dsktype, gptcpm, 16) == 0)
                                  not really working as I expected ? */
                                cmpptr = dskmap[idx].dsktype;
                                for (cmpidx = 0; cmpidx < 16; cmpidx++, cmpptr++)
                                    {
                                    if (gptcpm[cmpidx] != *cmpptr)
                                        break;
                                    }
                                if (cmpidx == 16)
                                    printf("CP/M ");
                                else
                                    printf(" ??  ");
                                prtguid(dskmap[idx].dsktype);
                                }
                            else
                                {
                                if (dskmap[idx].partype == PARTEBR)
                                    printf(" EBR ");
                                else
                                    printf(" MBR ");
                                if (dskmap[idx].dsktype[0] == mbrcpm)
                                    printf("CP/M ");
                                else if (dskmap[idx].dsktype[0] == mbrexcode)
                                    printf("Code ");
                                else
                                    printf(" ??  ");
                                printf("0x%02x", dskmap[idx].dsktype[0]);
                                }
                            printf("\n");
                            }
                        }
                    }
                break;
            case 'n':
                printf(" n - sector number: ");
                if (getkline(txtin, sizeof txtin))
                    sscanf(txtin, "%lu", &blockno);
                else
                    printf("%lu", blockno);
                printf("\n");
                break;
            case 'p':
                printf(" p - print data sector %lu\n", curblkno);
                sddatprt(sdrdbuf);
                break;
            case 'r':
                printf(" r - read sector");
                if (!sdprobe())
                    {
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                if (sdread(sdrdbuf, blockno))
                    {
                    printf(" - ok\n");
                    curblkno = blockno;
                    }
                else
                    printf(" - read error\n");
                break;
            case 's':
                printf(" s - print SD registers\n");
                sdprtreg();
                break;
            case 't':
                printf(" t - test if card inserted\n");
                if (sdprobe())
                    printf(" - ok\n");
                else
                    printf(" - not initialized or inserted or faulty\n");
                break;
            case 'u':
                printf(" u - upload with Xmodem\n");
                if (sdtestflg)
                    {
                    printf("Copy from: 0x%04x, to: 0x%04x, size: %d\n",
                        upload, UPLADDR, upload_size);
                    } /* sdtestflg */
                memcpy(UPLADDR, upload, upload_size);
                jumpto(UPLADDR);
                break;
            case 'w':
                printf(" w - write sector");
                if (!sdprobe())
                    printf(" - not initialized or inserted or faulty\n");
                if (sdwrite(sdrdbuf, blockno))
                    {
                    printf(" - ok\n");
                    curblkno = blockno;
                    }
                else
                    printf(" - write error\n");
                break;
            case 0x03: /* Ctrl-C */
                printf("reloading monitor from EPROM\n");
                reload();
                break; /* not really needed, will never get here */
            default:
                printf(" invalid command\n");
            }
        }
    }

