/*  z80sd.h
 *
 *  Defines SD card rouines for the Z80 Computer
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties given.
 *  Hastily Cobbled Together 2021 and 2022
 *  by Hans-Ake Lund
 */

/* Command length for SD commands in bytes
 */
#define CMD_LEN 6

/* Response length for SD commands in bytes
 */
#define R1_LEN 1
#define R3_LEN 5
#define R7_LEN 5

/* Structure and defines for partitions
 */
/* Internal partition identifiers
 */
#define PARTZRO 0  /* Empty partition entry */
#define PARTMBR 1  /* MBR partition */
#define PARTEBR 2  /* EBR logical partition */
#define PARTGPT 3  /* GPT partition */
#define EBRCONT 20 /* EBR container partition in MBR */

#define PARMAPADR 0xff00   /* address of the partition map */
#define PARMAPSIZE (16*16) /* size of the partition map */

#define INITFLG 0xfefe     /* Address of byte where the SD init ok flag is stored */
#define SEBYFLG 0xfeff     /* Address of byte where the SD block address multiplier flag is stored */
#define LOADADR 0xb000     /* Address in high RAM where to copy and execute uploader code */
#define UPLDADR 0xfef0     /* Address of variable where the upload address is stored */
#define EXEDADR 0xfef2     /* Address of variable where the execute address is stored */

extern char *byteblkadr;   /* block address multiplier flag */
extern char *sdinitok;     /* SD card initialized and ready */

/* The partition entry contains start and end blocks,
 * partition size, type of a partition and
 * if the partition is bootable.
 * Max 16 partitions as this is the limit for CP/M.
 */
struct partentry
    {
    unsigned char parident;     /* internal partition identification */
    unsigned char partype;      /* partition type as defined for MBR */
    unsigned char bootable;     /* bootable partition = TRUE */
    unsigned char parpad;
    unsigned char parstart[4];  /* first block of partition on SD card */
    unsigned char parend[4];    /* last block of partition */
    unsigned char parsize[4];   /* size of partition */
    };

struct guidentry
    {
    unsigned char parguid[16];  /* GUIDs for GPT partitions */
    };

extern struct partentry *parptr;         /* Partition map pointer */
extern struct guidentry guidmap[];       /* Map of GUIDs for GPT partitions */

extern const unsigned char mbrcpm;       /* Identifier of CP/M partition */
extern const unsigned char mbrexcode;    /* Identifier of Z80 executable code partition */
extern const unsigned char gptcpm[];     /* GPT GUID identifier for CP/M partition  */
extern const unsigned char gptexcode[];  /* GPT GUID identifier for executable partition  */

extern unsigned char dsksign[];       /* SD disk signature */

/* Buffers and registers
 */
extern unsigned char sdrdbuf[512];  /* recieved data from the SD card */
extern unsigned char ocrreg[4];     /* SD card OCR register */
extern unsigned char cidreg[16];    /* SD card CID register */
extern unsigned char csdreg[16];    /* SD card CSD register */

/* Variables
 */
extern unsigned char curblkno[4]; /* block in buffer if curblkok == YES */
extern int curblkok;
extern int curblkok;     /* if YES curblockno is read into buffer */ 
extern int sdver2;       /* SD card version 2 if YES, version 1 if NO */

/* Function prototypes */
void sdmbrpart(unsigned char *);

int sdread(unsigned char *, unsigned char *);
int sdwrite(unsigned char *, unsigned char *);

/* Make block address to byte address
 * by multiplying with 512 (blocksize)
 */
int blk2byte(unsigned char *);

/* Convert unsigned long to block address
 */
void ul2blk(unsigned char *, unsigned long);

/* Convert block address to unsigned long
 */
unsigned long blk2ul(unsigned char *);

/* Add block addresses
 */
void addblk(unsigned char *, unsigned char *);

/* Substract block addresses
 */
void subblk(unsigned char *, unsigned char *);

/*
Some parameters has to be exported from the boot program to the BIOS. This parameter data is placed in the uppermost part of the RAM memory to be available at a known location. The data contains:

    The partition table 16*16 bytes
    A flag to indicate if the SD card is using sector or byte addressing.
    A flag to indicate that the SD card is inserted and initialized

In addition there is one 16 bit variable to point to the memory location where program code is uploaded with Xmodem and executed. This is for the uploader but very useful for BIOS development. Also the flag for a successfully uploaded program is placed in this area.

Fixed addresses for parameters in high memory:

    0xfff0 - 0xffff: partition 16 (disk P)
    0xffe0 - 0xffef: partition 15 (disk O)
    0xffd0 - 0xffdf: partition 14 (disk N)
    0xffc0 - 0xffcf: partition 13 (disk M)
    0xffb0 - 0xffbf: partition 12 (disk L)
    0xffa0 - 0xffaf: partition 11 (disk K)
    0xff90 - 0xff9f: partition 10 (disk J)
    0xff80 - 0xff8f: partition 9 (disk I)
    0xff70 - 0xff7f: partition 8 (disk H)
    0xff60 - 0xff6f: partition 7 (disk G)
    0xff50 - 0xff5f: partition 6 (disk F)
    0xff40 - 0xff4f: partition 5 (disk E)
    0xff30 - 0xff3f: partition 4 (disk D)
    0xff20 - 0xff2f: partition 3 (disk C)
    0xff10 - 0xff1f: partition 2 (disk B)
    0xff00 - 0xff0f: partition 1 (disk A)
    0xfeff: sector or byte addressing flag, if 0: sector addressing
    0xfefe: SD card initialization was ok, if 0 not ok
    0xfef4 - 0xfefe: reserved, not used (yet)
    0xfef2 - 0xfef3: execute address
    0xfef0 - 0xfef1: upload address
*/

