/* Test Z80 embedded program with Whitesmiths compiler
 *
 */
#include <std.h>

char _romdata[0x100];
char txtout[256];

void putct(char pchar)
	{
	while ((in(0x0a) & 0x04) == 0) /* wait for tx buffer empty */
		;
	out(0x08, pchar);
	}

void prt_str(char *str)
	{
	while (*str)
		putct(*str++);
	}

void ledon()
	{
	out(0x18, 0);
	}

void ledoff()
	{
	out(0x14, 0);
	}


int ctrlc()
	{
	if (in(0x0a) & 0x01)
		{
		if (in(0x08) == 0x03)
			return (1);
		}
	return (0);
	}

int main()
	{
	long ltim;
	char *tp;
	int line = 1;

	while (YES)
		{
		if (ctrlc())
			{
			prt_str("reloading monitor from EPROM\r\n");
			reload();
			}
		ledon();
		decode(txtout, sizeof(txtout), "Whitesmiths/Cosmic Z80 C compiler, printing line: %i Ctrl-C to reload\r\n", line);
		prt_str(txtout);
		line++;
		for (ltim = 1000; 0 < ltim; ltim--)
			;
		ledoff();
		for (ltim = 1000; 0 < ltim; ltim--)
			;
		}
	}

