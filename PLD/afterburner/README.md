I am using a homebuilt programmer for ATF16V8 and ATF22V10C as described in https://github.com/ole00/afterburner

The main problem I had when building the programmer was to remove the EN (pin 4) connection of the MT3608
circuit to +5V and instead connect EN to the Arduino UNO board for control of the programming voltage.
I destroyed one MT3608 module when trying.
