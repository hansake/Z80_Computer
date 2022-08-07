The "Z80_cpmon" directory contains a monitor that was used to develop
a SPI/SD card interface that was used to develop a BIOS for CP/M.
The monitor can also load a copy of CP/M 2.2 from EPROM.

The "monitor" directory contains a simple monitor and test program 
that also can be used to upload code with Xmodem and run the code 
on the Z80 computer.

The "sd_boot_test" directory contains a program that is used to
 explore a SD card with SPI interface.
Programs can also be uploaded to RAM with Xmodem.
Eventually this program will also be able to boot from a SD card partition.

The "tools" directory contain source code for "bintoc" and "z80asm" that are
used to build the Z80 programs.
