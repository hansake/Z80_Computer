z80mon is a simple monitor for the Z80 Computer with functions to test the hardware,
upload and run programs and reload from EPROM.

This test program will test CPU, RAM, i/o devices and interrupts on the Z80 computer board.

The assembler I used is z80asm: https://github.com/AlbertVeli/z80asm

The monitor program will do the following:
- Copy program from EPROM to high RAM and then jump to the copied code
- Flash the green LED once
- Initialize the CTC, channel 0 for baudrate, channel 2 and 3 output pulses
- Flash the LED two times
- Initialize the SIO, channel A and B are using 9600 baud
- Flash the LED three times
- Initialize the PIO, port A and B initialized in output mode (Ready and Strobe must be connected on each port)
- Flash the LED four times
If the test function is selected with the 't' command:
- Send some text on SIO channel A
- Test if there is any characters in SIO channel A recieve buffer,
- if that is the case these characters and some text is sent
- Flash the LED five times
- Send some text on SIO channel B
- Test if there is any characters in SIO channel B recieve buffer,
- if that is the case these characters and some text is sent
- Flash the LED six times
- Test low RAM (0x0000 - 0xefff) and output the result
- Flash the LED seven times
- Check if interrupt is handled and show this on serial channels.
- - The tests are then repeated from start of test loop

The red LED is indicating that RAM is selected for low memory .

For each interupt a moving bit pattern is output on PIO port A.
Output from CTC channel 1 and 2 is also available in the PIO connectors.

If the upload function is selected:
- A program is uploaded with the 'u' command from address 0x0000 with the Xmodem protocol.
- I have been using minicom with tx to upload programs
- The program is then started with the 'g' command
