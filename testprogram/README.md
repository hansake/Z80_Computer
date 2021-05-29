This test program will test RAM and i/o devices on the Z80 computer board.

Testing interupts will be added.

The assembler I used is z80asm: https://github.com/AlbertVeli/z80asm

The test program will do the following:
- Copy program from EPROM to high RAM and then jump to the copied code
- Flash the LED once
- Initialize the CTC, channel 0 for baudrate, channel 2 and 3 output pulses
- Flash the LED two times
- Initialize the SIO, channel A and B are using 9600 baud
- Flash the LED three times
- Initialize the PIO, port A and B initialized in output mode (Ready and Strobe must be connected on each port)
- Flash the LED four times
- The test loop starts here
- Send some text on SIO channel A
- Test if there is any characters in SIO channel A recieve buffer,
- if that is the case these characters and some text is sent
- Flash the LED five times
- Send some text on SIO channel B
- Test if there is any characters in SIO channel B recieve buffer,
- if that is the case these characters and some text is sent
- Flash the LED six times
- Test low RAM (0x0000 - 0x7fff) and output the result
- Flash the LED seven times
- Test low RAM (end of program - 0xffff) and output the result
- Flash the LED seven times
- The tests are then repeated from start of test loop
- Check if interrupt is handled and show this on serial channels.

As the LED is indicating that RAM is selected for low memory (0x0000 - 0x7fff)
it will be on during low RAM test.

For each interupt a moving bit pattern is output on PIO ports A and B.
Output from CTC channel 1 and 2 is also available in the PIO connectors.

The main reason why the test program is copied to high RAM and executed
there is that the LED flashing implies that the low memory addresses are
switched between RAM and EPROM.

Maybe I will add a separate indicator LED later so that the LED flashing
is not dependent on if EPROM or RAM is selected.

