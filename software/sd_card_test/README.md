The source code here is compiled using the Whitesmiths/COSMIC C compiler for Z80.

z80sdtst.c is a program for my DIY Z80 computer board that analyses the type of SD card connected and its partition layout.

z80boot.c is the master code from which z80sdtst.c is generated with a flag to be quite chatty.
In the future z80boot will initialize hardware and partition tables and also boot whatever
program that is on the first SD card partition.
