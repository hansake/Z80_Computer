/*  z80sddrvprt.c Z80 SD card status print routines.
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

/* Convert unsigned long to block address
 */
void ul2blk(unsigned char *blk, unsigned long nblk)
    {
    blk[3] = nblk & 0xff;
    nblk = nblk >> 8;
    blk[2] = nblk & 0xff;
    nblk = nblk >> 8;
    blk[1] = nblk & 0xff;
    nblk = nblk >> 8;
    blk[0] = nblk & 0xff;
    }

/* Convert block address to unsigned long
 */
unsigned long blk2ul(unsigned char *blk)
    {
    return((unsigned long)(0xff & blk[3]) + 
        ((unsigned long)(0xff & blk[2]) << 8) +
        ((unsigned long)(0xff & blk[1]) << 16) +
        ((unsigned long)(0xff & blk[0]) << 24));
    }

/* Print data in 512 byte buffer */
void sddatprt(unsigned char *prtbuf, unsigned int prtbase, int dumprows)
    {
    /* Variables used for "pretty-print" */
    int allzero, dmpline, dotprted, lastallz, nbytes;
    unsigned char *prtptr;

    prtptr = prtbuf;
    dotprted = NO;
    lastallz = NO;
    for (dmpline = 0; dmpline < dumprows; dmpline++)
        {
        /* test if all 16 bytes are 0x00 */
        allzero = YES;
        for (nbytes = 0; nbytes < 16; nbytes++)
            {
            if (prtptr[nbytes] != 0)
                allzero = NO;
            }
        if (lastallz && allzero && (dmpline != (dumprows -1)))
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
            printf("%04x ", (dmpline * 16) + prtbase);
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

/* print OCR, CID and CSD registers*/
void sdprtreg()
    {
    unsigned int n;
    unsigned int csize;
    unsigned long devsize;
    unsigned long capacity;

    if (!*sdinitok)
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
    }
