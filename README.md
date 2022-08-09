# Z80 Computer
A simple Z80 based computer board in a plastic box.

![Z80 Computer](photos/Z80_computer.png?raw=true)

The project was started when I began to try to organize my collection of integrated
circuits and found some Z80 ICs.
I also found a Vero-Wire kit that I bought many years ago but never used until now.

The board contains:
- Z80 CPU
- Z80 CTC
- Z80 SIO/0
- Z80 PIO
- EPROM 32KB
- two RAM 32KB

The lower memory range 0x0000 - 0x7fff can be switched between EPROM and RAM from the program.

Address decoding is done with a Programmable Logic Device (PLD): ATF22V10C.

In addition there is:
- a 4MHz crystal oscillator
- a reset circuit using LM555 (and a transistor to invert the reset signal)
- some resistors and capacitors

New hardware and software functions has been added:
- A test program to verify the operation of the board is also available.
- Also a simple monitor with Xmodem upload to RAM was added.
- An interface to a microSD memory card using SPI was added, also a test program for this interface is now added.

CP/M is running on this computer.
