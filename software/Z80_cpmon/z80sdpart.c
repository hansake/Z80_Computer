/*  z80sdpart.c Identify partitions on SD card.
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

struct partentry *parptr;       /* Partition map pointer */

struct guidentry guidmap[16];   /* Map of GUIDs for GPT partitions */

/* Detected EBR records to process */
struct ebrentry
    {
    unsigned char ebrblk[4];
    } ebrrecs[4];

unsigned char dsksign[4];      /* MBR/EBR disk signature */

/* blockno 0, used to compare */
const unsigned char blkzero[4] = {0x00, 0x00, 0x00, 0x00};
/* blockno 1, used to increment/decrement */
const unsigned char blkone[4] = {0x00, 0x00, 0x00, 0x01};

/* Partition identifiers
 */

/* CP/M partition */
const unsigned char mbrcpm = 0x52;
/* For MBR/EBR the partition type for CP/M is 0x52
 * according to: https://en.wikipedia.org/wiki/Partition_type
 */

/* Z80 executable code partition */
const unsigned char mbrexcode = 0x5f;
/* My own "invention", has a special format that
 * includes number of bytes to load and a signature
 * that is a jump to the executable part
 */

/* For GPT I have defined that a CP/M partition
 * has GUID: AC7176FD-8D55-4FFF-86A5-A36D6368D0CB
 */
const unsigned char gptcpm[] =
    {
    0xfd, 0x76, 0x71, 0xac, 0x55, 0x8d, 0xff, 0x4f,
    0x86, 0xa5, 0xa3, 0x6d, 0x63, 0x68, 0xd0, 0xcb
    };

/* For GPT I have also defined that a executable partition
 * has GUID: 0185D755-3CAC-41F5-94D9-6F7D906868E8
 */
const unsigned char gptexcode[] =
    {
    0x55, 0xd7, 0x85, 0x01, 0xac, 0x3c, 0xf5, 0x41,
    0x94, 0xd9, 0x6f, 0x7d, 0x90, 0x68, 0x68, 0xe8
    };

int ebrrecidx; /* how many EBR records that are populated */
unsigned char ebrnext[4]; /* next chained ebr record */

/* Variables
 */
int partpar;   /* partition/disk number, 0 = disk A */

unsigned long blk2ul(unsigned char*);

/* Analyze and record GPT entry
 */
int gptentry(unsigned int entryno)
    {
    int index;
    int entryidx;
    int hasname;
    unsigned char blkno[4];
    unsigned char *rxdata;
    unsigned char *entryptr;
    unsigned char tstzero = 0;
    unsigned long llba;

    ul2blk(blkno, (unsigned long)(2 + (entryno / 4)));
    if (!sdread(sdrdbuf, blkno))
        return (NO);
    rxdata = sdrdbuf;
    entryptr = rxdata + (128 * (entryno % 4));
    for (index = 0; index < 16; index++)
        tstzero |= entryptr[index];
    if (!tstzero)
        return (NO);
    if (entryptr[48] & 0x04)
        parptr[partpar].bootable = YES;
    parptr[partpar].parident = PARTGPT;
    /* lower 32 bits of LBA should be sufficient (I hope) */
    /* partitions are using LSB while SD block are using MSB */
    part2blk(parptr[partpar].parstart, &entryptr[32]);
    part2blk(parptr[partpar].parend, &entryptr[40]);
    part2blk(parptr[partpar].parsize, &entryptr[40]);
    subblk(parptr[partpar].parsize, parptr[partpar].parstart);
    addblk(parptr[partpar].parsize, blkone);
    memcpy(guidmap[partpar].parguid, &entryptr[0], 16);
    if (!memcmp(guidmap[partpar].parguid, gptcpm, 16))
        parptr[partpar].partype = mbrcpm;
    else if (!memcmp(guidmap[partpar].parguid, gptexcode, 16))
        parptr[partpar].partype = mbrexcode;
    partpar++;
    return (YES);
    }

/* Analyze and GPT header
 */
void sdgpthdr(unsigned char *blkno)
    {
    int index;
    unsigned int partno;
    unsigned char *rxdata;
    unsigned long entries;

    if (!sdread(sdrdbuf, blkno))
        return;
    rxdata = sdrdbuf;
    for (partno = 0; (partno < 16) && (partpar < 16); partno++)
        {
        if (!gptentry(partno))
            return;
        }
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

    parttype = PARTMBR;
    if (!partptr[4])
        return (PARTZRO);
    if (!(partptr[4] == 0xee)) /* not pointing to a GPT partition */
        {
        if ((partptr[4] == 0x05) || (partptr[4] == 0x0f)) /* EBR partition */
            {
            parttype = PARTEBR;
            if (memcmp(curblkno, blkzero, 4) == 0) /* points to EBR in the MBR */
                {
                memset(ebrnext, 0, 4);
                parptr[partpar].parident = EBRCONT;
                part2blk(parptr[partpar].parstart, &partptr[8]);
                part2blk(parptr[partpar].parsize, &partptr[12]);
                part2blk(parptr[partpar].parend, &partptr[8]);
                addblk(parptr[partpar].parend, parptr[partpar].parsize);
                subblk(parptr[partpar].parend, blkone);
                parptr[partpar].partype = partptr[4];
                partpar++;
                /* save to handle later */
                part2blk(ebrrecs[ebrrecidx++].ebrblk, &partptr[8]);
                }
            else
                {
                part2blk(ebrnext, &partptr[8]);
                addblk(ebrnext, curblkno);
                }
            }
        else
            {
            if (memcmp(&partptr[12], blkzero, 4)) /* ugly hack to avoid empty partitions */
                {
                if (partptr[0] & 0x80)
                    parptr[partpar].bootable = YES;
                if (!memcmp(curblkno, blkzero, 4))
                    parptr[partpar].parident = PARTMBR;
                else
                    parptr[partpar].parident = PARTEBR;
                part2blk(parptr[partpar].parstart, &partptr[8]);
                addblk(parptr[partpar].parstart, curblkno);
                part2blk(parptr[partpar].parsize, &partptr[12]);
                part2blk(parptr[partpar].parend, &partptr[12]);
                addblk(parptr[partpar].parend, parptr[partpar].parstart);
                subblk(parptr[partpar].parend, blkone);
                parptr[partpar].partype = partptr[4];
                partpar++;
                }
            }
        }

    if (partptr[4] == 0xee) /* GPT partitions */
        {
        parttype = PARTGPT;
        sdgpthdr(parptr[partpar].parstart); /* handle GTP partitions */
        /* re-read MBR on sector 0
           This is probably not needed as there
           is only one entry (the first one)
           in the MBR when using GPT */
        if (sdread(sdrdbuf, 0))
            {
            memset(curblkno, 0, 4);
            curblkok = YES;
            }
        else
            return(-1);
        }
    return (parttype);
    }

/* Read and analyze MBR/EBR partition sector block
 * and go through and print partition entries.
 */
void sdmbrpart(unsigned char *sector)
    {
    int partidx;  /* partition index 1 - 4 */
    int cpartidx; /* chain partition index 1 - 4 */
    int chainidx;
    int enttype;
    unsigned char *entp; /* pointer to partition entry */
    char *mbrebr;

    if (sdread(sdrdbuf, sector))
        {
        memcpy(curblkno, sector, 4);
        curblkok = YES;
        }
    else
        return;
    if (!((sdrdbuf[0x1fe] == 0x55) && (sdrdbuf[0x1ff] == 0xaa)))
        return;
    if (memcmp(curblkno, blkzero, 4) == 0)
        memcpy(dsksign, &sdrdbuf[0x1b8], sizeof dsksign);
    /* go through MBR partition entries until first empty */
    /* !!as the MBR entry routine is called recusively a way is
       needed to read sector 0 when going back to MBR if
       there is a primary partition entry after an EBR entry!! */
    entp = &sdrdbuf[0x01be] ;
    for (partidx = 1; (partidx <= 4) && (partpar < 16); partidx++, entp += 16)
        {
        enttype = sdmbrentry(entp);
        if (enttype == -1) /* read error */
            return;
        else if (enttype == PARTZRO)
            break;
        }
    /* now handle the previously saved EBR partition sectors */
    for (partidx = 0; (partidx < ebrrecidx) && (partpar < 16); partidx++)
        {
        if (sdread(sdrdbuf, ebrrecs[partidx].ebrblk))
            {
            memcpy(curblkno, ebrrecs[partidx].ebrblk, 4);
            curblkok = YES;
            }
        else
            return;
        entp = &sdrdbuf[0x01be] ;
        for (partidx = 1; (partidx <= 4) && (partpar < 16); partidx++, entp += 16)
            {
            enttype = sdmbrentry(entp);
            if (enttype == -1) /* read error */
                 return;
            else if (enttype == PARTZRO) /* empty partition entry */
                break;
            else if (enttype == PARTEBR) /* next chained EBR */
                /* follow the EBR chain */
                {
                for (chainidx = 0;
                    (chainidx < 16) && (partpar < 16);
                    chainidx++)
                    {
                    /* ugly hack to stop reading the same sector */
                    if (!memcmp(ebrnext, curblkno, 4))
                         break;
                    if (sdread(sdrdbuf, ebrnext))
                        {
                        memcpy(curblkno, ebrnext, 4);
                        curblkok = YES;
                        }
                    else
                        return;
                    entp = &sdrdbuf[0x01be] ;
                    for (cpartidx = 1;
                        (cpartidx <= 4) && (partpar < 16);
                        cpartidx++, entp += 16)
                        {
                        enttype = sdmbrentry(entp);
                        if (enttype == -1) /* read error */
                            return;
                        }
                    }
                }
            }
        }
    }

/* Find partitions on SD card
 */
void sdpartfind()
    {
    ebrrecidx = 0;
    partpar = 0;
    parptr = (void *) PARMAPADR;
    memset(parptr, 0, PARMAPSIZE);
    sdmbrpart(blkzero);
    }

