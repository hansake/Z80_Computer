/*  z80prog.c Boot and SD card test program.
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
#include "z80comp.h"
#include "z80sd.h"
#include "cpmbiosadr.h"
/* Program name and version */
#define PRGNAME "z80cpmon "
#define VERSION "version 1.0, "

unsigned int *upladrptr; /* upload address pointer */
unsigned int *exeadrptr; /* execute address pointer */

/* External data */
extern const char upload[];
extern const int upload_size;
extern const int binsize;
extern const int binstart;
extern const char cpmsys[];
extern const int cpmsys_size;

extern const char builddate[];

/* RAM/EPROM probe */
const int ramprobe = 0;
int *rampptr;

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
    char txtin[16];
    int cmdin;
    int idx;
    int cmpidx;
    unsigned char *cmpptr;
    int inlength;
    unsigned char blockno[4];
    unsigned long inblockno;
    unsigned int upladr;
    unsigned int exeadr;
    unsigned int dumpadr;
    int dumprows;

    memset(blockno, 0, 4);
    memset(curblkno, 0, 4);;
    curblkok = NO;
    sdinitok = (void *) INITFLG;
    *sdinitok = 0; /* SD card not initialized yet */
    byteblkadr = (void *) SEBYFLG;
    upladrptr = (void *) UPLDADR;
    *upladrptr = 0x0000;
    exeadrptr = (void *) EXEDADR;
    *exeadrptr = 0x0000;
    dumpadr = 0x0000;
    dumprows = 16;

    printf(PRGNAME);
    printf(VERSION);
    printf(builddate);
    execin();
    /*printf("binstart: 0x%04x, binsize: 0x%04x (%d)\n", binstart, binsize, binsize);*/
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
                printf("  a - set address for upload\n");
                printf("  c - boot CP/M from EPROM\n");
                printf("  d - dump memory content to screen\n");
                printf("  e - set address for execute\n");
                printf("  i - initialize SD card\n");
                printf("  l - print SD card partition layout\n");
                printf("  n - set/show block #N to read/write\n");
                printf("  p - print block last read/to write\n");
                printf("  r - read block #N\n");
                printf("  s - print SD registers\n");
                printf("  t - test probe SD card\n");
                printf("  u - upload code with Xmodem to 0x%04x\n      and execute at: 0x%04x\n",
                       *upladrptr, *exeadrptr);
                printf("  w - write block #N\n");
                printf("  Ctrl-C to reload monitor from EPROM\n");
                break;
            case 'a':
                printf(" a - upload address:  0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &upladr);
                    *upladrptr = upladr;
                    *exeadrptr = upladr;
                    }
                else
                    {
                    printf("%04x", *upladrptr);
                    }
                printf("\n");
                break;
            case 'c':
                printf(" c - boot CP/M from EPROM\n");
                printf("  but first initialize SD card ");
                if (sdinit())
                    printf(" - ok\n");
                else
                    {
                    printf(" - not inserted or faulty\n");
                    break;
                    }
                printf("  and then find and print partition layout\n");
                if (!sdprobe())
                    {
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                sdpartfind();
                sdpartprint();
                memcpy(CCPADR, cpmsys, cpmsys_size);
                jumptoram(BIOSADR);
                break;
            case 'd':
                printf(" d - dump memory content starting at: 0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &dumpadr);
                    }
                else
                    {
                    printf("%04x", dumpadr);
                    }
                printf(" rows: ");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%d", &dumprows);
                    }
                else
                    {
                    printf("%d", dumprows);
                    }
                printf("\n");
                sddatprt(dumpadr, dumpadr, dumprows);
                break;
            case 'e':
                printf(" e - execute address: 0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &exeadr);
                    *exeadrptr = exeadr;
                    }
                else
                    {
                    printf("%04x", *exeadrptr);
                    }
                printf("\n");
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
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                sdpartfind();
                sdpartprint();
                break;
            case 'n':
                printf(" n - block number: ");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%lu", &inblockno);
                    ul2blk(blockno, inblockno);
                    }
                else
                    printf("%lu", blk2ul(blockno));
                printf("\n");
                break;
            case 'p':
                printf(" p - print data block %lu\n", blk2ul(curblkno));
                sddatprt(sdrdbuf, 0x0000, 32);
                break;
            case 'r':
                printf(" r - read block");
                if (!sdprobe())
                    {
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                if (sdread(sdrdbuf, blockno))
                    {
                    printf(" - ok\n");
                    memcpy(curblkno, blockno, 4);
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
                printf(" %c - upload to 0x%04x and execute at: 0x%04x\n",
                    cmdin, *upladrptr, *exeadrptr);
                printf("(Uploader code at: 0x%04x, size: %d)\n", LOADADR, upload_size);
                memcpy(LOADADR, upload, upload_size);
                jumpto(LOADADR);
                break;
            case 'w':
                printf(" w - write block");
                if (!sdprobe())
                    {
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                if (sdwrite(sdrdbuf, blockno))
                    {
                    printf(" - ok\n");
                    memcpy(curblkno, blockno, 4);
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

