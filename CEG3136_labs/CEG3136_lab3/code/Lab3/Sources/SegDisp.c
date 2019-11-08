/*--------------------------------------------
File: SegDisp.c
Description:  Segment Display Module
---------------------------------------------*/

#include <stdtypes.h>
#include "mc9s12dg256.h"
#include "SegDisp.h"
#include "Delay_asm.h"

// Prototypes for internal functions

/*---------------------------------------------
Function: initDisp
Description: initializes hardware for the 
             7-segment displays.
-----------------------------------------------*/
void initDisp(void) 
{
	DDRB = 0xFF; //init PORTB to output
	DDRP = 0xFF; // init PORTP to output
	PORTB = 0x39; //init display to blank
	PTP = 0x00;
}

/*---------------------------------------------
Function: clearDisp
Description: Clears all displays.
-----------------------------------------------*/
void clearDisp(void) 
{
	PORTB = 0x39; //init display to blank
	PTP = 0xFF;
}

/*---------------------------------------------
Function: setCharDisplay
Description: Receives an ASCII character (ch)
             and translates
             it to the corresponding code to 
             display on 7-segment display.  Code
             is stored in appropriate element of
             codes for identified display (dispNum).
-----------------------------------------------*/
void setCharDisplay(char ch, byte dispNum) 
{
	byte pattern = 0x00; //if there is no matching char display nothing
	if (ch=='0') pattern = 0x3F;
	else if (ch == '1') pattern = 0x06;
	else if (ch == '2') pattern = 0x5B;
	else if (ch == '3') pattern = 0x4F;
	else if (ch == '4') pattern = 0x66;
	else if (ch == '5') pattern = 0x6D;
	else if (ch == '6') pattern = 0x7D;
	else if (ch == '7') pattern = 0x07;
	else if (ch == '8') pattern = 0x7F;
	else if (ch == '9') pattern = 0x6F;
	else if (ch == 'a') pattern = 0x77;
	else if (ch == 'b') pattern = 0x7D;
	else if (ch == 'c') pattern = 0x39;
	else if (ch == 'd') pattern = 0x5E;
	else if (ch == '#') pattern = 0x70;
	else if (ch == '*') pattern = 0x46;
	digit[dispNum] = pattern;

}

/*---------------------------------------------
Function: segDisp
Description: Displays the codes in the code display table 
             (contains four character codes) on the 4 displays 
             for a period of 100 milliseconds by displaying 
             the characters on the displays for 5 millisecond 
             periods.
-----------------------------------------------*/
void segDisp(void) 
{
int i;
int j;
	for(int i=0; i<5; ++i)
	 {
		for (int j=0; j<4; ++j)
		 {
			PTP = PTPDir[j];
			PORTB = digit[j];
			delayms(5);
}
