/* z80computer.h
 *
 * Defines hardware for the Z80 Computer
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties given.
 *  Hastily Cobbled Together 2021 by Hans-Ake Lund
 */

/* Port definitions for switching between low EPROM and RAM */
#define MEMEPROM 0x00
#define MEMLORAM 0x04

/* Port definitions for the SIO/0 chip */
#define SIO_BASE 0x08
#define SIO_A_DATA (SIO_BASE + 0 + 0)
#define SIO_A_CTRL (SIO_BASE + 0 + 2)
#define SIO_B_DATA (SIO_BASE + 1 + 0)
#define SIO_B_CTRL (SIO_BASE + 1 + 2)

/* Port definitions for the CTC chip */
#define CTC_BASE 0x0c
#define CTC_CH0 (CTC_BASE + 0)
#define CTC_CH1 (CTC_BASE + 1)
#define CTC_CH2 (CTC_BASE + 2)
#define CTC_CH3 (CTC_BASE + 3)

/* Port definitions for the PIO chip */
#define PIO_BASE 0x10
#define PIO_A_DATA (PIO_BASE + 0 + 0)
#define PIO_A_CTRL (PIO_BASE + 0 + 2)
#define PIO_B_DATA (PIO_BASE + 1 + 0)
#define PIO_B_CTRL (PIO_BASE + 1 + 2)

/* Port definitions for switching LED off and on */
#define LEDOFF 0x14
#define LEDON 0x18
