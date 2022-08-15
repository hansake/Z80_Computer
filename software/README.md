The "Z80_cpmon" directory contains a monitor that was used to develop
a SPI/SD card interface for a BIOS for CP/M.
The monitor can load a copy of CP/M 2.2 from EPROM.

```
=================================
Z80 Computer hardware initialized
z80cpmon version 1.0, built 2022-08-07 13:19, executing in: EPROM
cmd (? for help):  ? - help                                                     
z80cpmon version 1.0, built 2022-08-07 13:19, executing in: EPROM               
Commands:                                                                       
  ? - help                                                                      
  a - set address for upload                                                    
  c - boot CP/M from EPROM                                                      
  d - dump memory content to screen                                             
  e - set address for execute                                                   
  i - initialize SD card                                                        
  l - print SD card partition layout                                            
  n - set/show block #N to read/write                                           
  p - print block last read/to write                                            
  r - read block #N                                                             
  s - print SD registers                                                        
  t - test probe SD card                                                        
  u - upload code with Xmodem to 0x0000                                         
      and execute at: 0x0000                                                    
  w - write block #N                                                            
  Ctrl-C to reload monitor from EPROM  
cmd (? for help):  c - boot CP/M from EPROM
  but first initialize SD card  - ok
  and then find and print partition layout
      Disk partition sectors on SD card
       MBR disk identifier: 0x071a6f5a
 Disk     Start      End     Size Part Type Id
 ----     -----      ---     ---- ---- ---- --
 1 (A)     2048     4095     2048  MBR CP/M 0x52
 2 (B)     4096     6143     2048  MBR CP/M 0x52                                
 3 (C)     6144     8191     2048  MBR CP/M 0x52                                
 4 (D)     8192    10239     2048  MBR CP/M 0x52                                
CP/M 2.2 & Z80 BIOS v1.0 with unbelievably slow SPI/SD card interface           
(Ctrl-Z to reboot from EPROM)                                                   
                                                                                
A>dir                                                                           
A: DUMP     COM : SDIR     COM : SUBMIT   COM : ED       COM                    
A: STAT     COM : BYE      COM : RMAC     COM : CREF80   COM                    
A: LINK     COM : L80      COM : M80      COM : SID      COM                    
A: RESET    COM : WM       HLP : ZSID     COM : MAC      COM                    
A: TRACE    UTL : HIST     UTL : LIB80    COM : WM       COM                    
A: HIST     COM : DDT      COM : Z80ASM   COM : CLS      COM                    
A: SLRNK    COM : MOVCPM   COM : ASM      COM : LOAD     COM                    
A: XSUB     COM : LIB      COM : PIP      COM : SYSGEN   COM                    
A>dir d:                                                                        
D: EX       MAC : EX       COM : ZEXDOC   COM : PRELIM   MAC                    
D: PRELIM   COM : ZEXDOC   MAC : CPUTEST  COM                                   
A>

```

The "monitor" directory contains a simple monitor and test program 
that also can be used to upload code with Xmodem and run the code 
on the Z80 computer.

The "sd_boot_test" directory contains a program that is used to
 explore a SD card with SPI interface.
Programs can also be uploaded to RAM with Xmodem.
Eventually this program will also be able to boot from a SD card partition.

The transfer speed of the SPI interface is 976 bytes per second (i.e. 7811 bits per second). 

The "tools" directory contain source code for "bintoc" and "z80asm" that are
used to build the Z80 programs.
