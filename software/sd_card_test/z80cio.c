/* z80cio.c
 *
 *  I/O routines for my DIY Z80 Computer.
 *  The program compiled with Whitesmiths C compiler.
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties given.
 *  Hastily Cobbled Together 2021 and 2022
 *  by Hans-Ake Lund
 *
 */

#include <std.h>
#include "z80computer.h"

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
	return  (in(SIO_A_DATA));
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
				puts("\b \b");
				ncharin--;
				txtinp--;
				}
			}
		else
			{
			putchar(charin);
			*txtinp++ = charin;
			ncharin++;
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


