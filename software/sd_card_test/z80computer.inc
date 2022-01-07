; Port definitions for switching between low EPROM and RAM
.define MEMEPROM = 00h
.define MEMLORAM = 04h

; Port definitions for the SIO/0 chip
.define SIO_BASE = 08h
.define SIO_A_DATA = SIO_BASE + 0 + 0
.define SIO_A_CTRL = SIO_BASE + 0 + 2
.define SIO_B_DATA = SIO_BASE + 1 + 0
.define SIO_B_CTRL = SIO_BASE + 1 + 2

; Port definitions for the CTC chip
.define CTC_BASE = 0ch
.define CTC_CH0 = CTC_BASE + 0
.define CTC_CH1 = CTC_BASE + 1
.define CTC_CH2 = CTC_BASE + 2
.define CTC_CH3 = CTC_BASE + 3

; Port definitions for the PIO chip
.define PIO_BASE = 10h
.define PIO_A_DATA = PIO_BASE + 0 + 0
.define PIO_A_CTRL = PIO_BASE + 0 + 2
.define PIO_B_DATA = PIO_BASE + 1 + 0
.define PIO_B_CTRL = PIO_BASE + 1 + 2

; Port definitions for switching LED off and on
.define LEDOFF = 14h
.define LEDON = 18h

