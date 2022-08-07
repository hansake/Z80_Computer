/*  z80sdparprt.c Print partitions on SD card.
 *
 *  Boot code for my DIY Z80 Computer. This
 *  program is compiled with Whitesmiths/COSMIC
 *  C compiler for Z80.
 *
 *  Detects the partitioning of an attached SD card.
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

/* Print partitions on SD card
 */
void sdpartprint()
    {
    char txtin[10];
    int cmdin;
    int idx;
    int cmpidx;
    unsigned char *cmpptr;
    int inlength;
    unsigned char blockno[4];

    memset(blockno, 0, 4);
    memset(curblkno, 0, 4);
    curblkok = NO;

    printf("      Disk partition sectors on SD card\n");
    printf("       MBR disk identifier: 0x%02x%02x%02x%02x\n",
       dsksign[3], dsksign[2], dsksign[1], dsksign[0]);
    printf(" Disk     Start      End     Size Part Type Id\n");
    printf(" ----     -----      ---     ---- ---- ---- --\n");
    for (idx = 0; idx < 16; idx++)
       {
       if (parptr[idx].parident)
            {
            printf("%2d (%c)%c", idx + 1, idx + 'A',
               parptr[idx].bootable ? '*' : ' ');
               printf("%8lu %8lu %8lu ",
                   blk2ul(parptr[idx].parstart),
                   blk2ul(parptr[idx].parend),
                   blk2ul(parptr[idx].parsize));
            if (parptr[idx].parident == EBRCONT)
                printf(" EBR container\n");
            else
                {
                if (parptr[idx].parident == PARTGPT)
                    {
                    printf(" GPT ");
                    if (!memcmp(guidmap[idx].parguid, gptcpm, 16))
                        printf("CP/M ");
                    else if (!memcmp(guidmap[idx].parguid, gptexcode, 16))
                        printf("Code ");
                    else
                        printf(" ??  ");
                    prtguid(guidmap[idx].parguid);
                    }
                else
                    {
                    if (parptr[idx].parident == PARTEBR)
                        printf(" EBR ");
                    else
                        printf(" MBR ");
                    if (parptr[idx].partype == mbrcpm)
                        printf("CP/M ");
                    else if (parptr[idx].partype == mbrexcode)
                        printf("Code ");
                    else
                        printf(" ??  ");
                    printf("0x%02x", parptr[idx].partype);
                    }
                printf("\n");
                }
            }
        }
    }

