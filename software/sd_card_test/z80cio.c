/* z80cio.c
 *
 * I/O routines for my DIY Z80 Computer.
 * The program compiled with Whitesmiths/COSMIC
 * C compiler for Z80.
 *
 * You are free to use, modify, and redistribute
 * this source code. No warranties given.
 * Hastily Cobbled Together 2021 and 2022
 * by Hans-Ake Lund
 *
 */

#include <std.h>
#include "z80computer.h"

/* Initialize hardware */
void hwinit()
    {
    ledon();
    ctc_init();
    sio_init();
    pio_init();
    printf("Z80 Computer hardware initialized\n");
    ledoff();
    }

/* ctc_init()
; Divide constant in CTC to get an approximate baudrate of 9600
; To get 9600 baud with a 4MHz xtal oscillator the divide constant
; should be 4000000/(9600*2*16) = 13.0208
; Using the CTC divider constant set to 13 will give a baud-rate
; of 4000000/(2*16*13) = 9615 baud which hopefully is close enough.
; This is tested and works with a 9600 baudrate connection to a Linux PC.
;
; (If this is not exact enough, another xtal oscillator must be selected,
; it should have the frequency: 3.6864 MHz
; The divide constant will then be set to 12 which gives the baudrate
; of 3686400/(2*16*12) = 9600 baud.)
;
; ctc_init: initializes the CTC channel 0 for baudrate clock to SIO/0
; initializes also CTC channels 1, 2 and 3
; input TRG0-2 is supplied by the BCLK signal which is the system clock
; divided by 2 by the ATF22V10C
*/
#define BAUDDIV 13

void ctc_init()
    {
    /* CTC chan 0 */
    /* 01000111b	; int off, counter mode, prescaler don't care,
    		; falling edge, time trigger don't care,
    		; time constant follows, sw reset,
    		; this is a ctrl cmd
     */
    out(CTC_CH0, 0x47);
    out(CTC_CH0, BAUDDIV);
    /* Interupt vector will be written to chan 0 */

    /* CTC chan 1, not used but generating pulses */
    /* 01000111b	; int off, counter mode, prescaler don't care,
    		; falling edge, time trigger don't care,
    		; time constant follows, sw reset,
    		; this is a ctrl cmd
     */
    out(CTC_CH1, 0x47);
    out(CTC_CH1, 10); /* divide BCLK by 10 */

    /* CTC chan 2,
        generating clock pulses for NMI driven SPI interface
     */
    /* 00000011b		; sw reset, this is a ctrl cmd
     */
    out(CTC_CH2, 0x03);

    /* CTC chan 3, not used yet */

    }

/* sio_init() initializes the SIO/0 for serial communication
	db 00110000b		; write to WR0: error reset
	db 00011000b		; write to WR0: channel reset
	db 0x04, 01000100b	; write to WR4: clkx16, 1 stop bit, no parity
	db 0x05, 01101000b	; write to WR5: DTR inactive, enable TX 8bit,
				; BREAK off, TX on, RTS inactive
	db 0x01, 00000000b	; write to WR1: no interrupts enabled
	db 0x03, 11000001b	; write to WR3: enable RX 8bit
 */
const unsigned char sioregini[] = {0x30, 0x18, 0x04, 0x44, 0x05, 0x68,
                                   0x01, 0x00, 0x03, 0xc1
                                  };

void sio_init()
    {
    unsigned char *sioregptr;
    unsigned int port;
    int wrbytes;

    /* Initialize SIO port A */
    port = SIO_A_CTRL;
    sioregptr = sioregini;
    for (wrbytes = sizeof sioregini; 0 < wrbytes; wrbytes--)
        out(port, *sioregptr++);

    /* Initialize SIO port B */
    port = SIO_B_CTRL;
    sioregptr = sioregini;
    for (wrbytes = sizeof sioregini; 0 < wrbytes; wrbytes--)
        out(port, *sioregptr++);
    }

/* pio_init() initialize PIO channel A and B
 */
void pio_init()
    {
    /* PIO A */

    /* 00001111b		; mode 0 */
    out(PIO_A_CTRL, 0x0f);

    /* 00000111b		; int disable */
    out(PIO_A_CTRL, 0x07);

    /* PIO B, SPI interface */
    /* 11001111b		; mode 3 */
    out(PIO_B_CTRL, 0xcf);

    /* 00000001b		; i/o mask
    ;bit 0: MISO - input     3                   3
    ;bit 1: MOSI - output    4                   5
    ;bit 2: SCK  - output    5                   7
    ;bit 3: /CS0 - output    6                   9
    ;bit 4: /CS1 - output  extra device select  11
    ;bit 5: /CS2 - output  extra device select  10
    ;bit 6: TP1  - output  test point            8  (used to measure NMI handling time)
    ;bit 7: TRA  - output  byte in transfer      6   signals that NMI routine is active
    ;                                                with an 8 bit transmit or receive transfer
    */
    out(PIO_B_CTRL, 0x01);

    /* 00000111b		; int disable */
    out(PIO_B_CTRL, 0x07);

    /* 00111010b		;initialize output bits
    ; bit 1: MOSI - output	;low
    ; bit 2: SCK  - output	;low
    ; bit 3: /CS0 - output	;high = not selected
    ; bit 4: /CS1 - output	;high = not selected
    ; bit 5: /CS2 - output	;high = not selected
    ; bit 6: TP1  - output  ;low
    ; bit 7: TRA  - output  ;low
    */
    out(PIO_B_DATA, 0x3a);
    }

/* Print character on serial port A */
int putchar(char pchar)
    {
    while ((in(SIO_A_CTRL) & 0x04) == 0) /* wait for tx buffer empty */
        ;
    out(SIO_A_DATA, pchar);
    if (pchar == '\n')
        putchar('\r');
    return (pchar);
    }

/* Get character from serial port A */
int getchar()
    {
    while (!(in(SIO_A_CTRL) & 0x01)) /* test and loop until character available */
        ;
    return (in(SIO_A_DATA));
    }

/* Get line from keyboard
 * edit line with BS
 * returns when CR or Ctrl-C is entered
 * return value is length of entered string
 */
int getkline(char *txtinp, int bufsize)
    {
    int ncharin;
    char charin;

    for (ncharin = 0; ncharin < (bufsize - 1); ncharin++)
        {
        charin = getchar();
        if (charin == '\r') /* CR */
            {
            *txtinp = 0;
            return (ncharin);
            }
        else if (charin == 3) /* Ctrl-C */
            return (0);
        else if (charin == '\b') /* BS */
            {
            if (0 < ncharin)
                {
                putchar('\b');
                putchar(' ');
                putchar('\b');
                ncharin--;
                txtinp--;
                }
            }
        else
            {
            putchar(charin);
            *txtinp++ = charin;
            }
        }
    *txtinp = 0;
    return (ncharin);
    }

/* Status LED on */
void ledon()
    {
    out(LEDON, 1);
    }

/* Status LED off */
void ledoff()
    {
    out(LEDOFF, 0);
    }

