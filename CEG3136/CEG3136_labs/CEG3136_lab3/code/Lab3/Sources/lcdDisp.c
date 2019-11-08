/*-------------------------------------
File: lcdDisp.c  (LCD Diplay Module)

Description: C Module that provides
             display functions on the
             LCD. It makes use of the LCD ASM 
             Module developed in assembler.
-------------------------------------*/
#include "alarm.h"
#include "lcd_asm.h"

/*--------------------------
Function: initLCD
Parameters: None.
Returns: nothing
Description: Initialised the LCD hardware by
             calling the assembler subroutine.
---------------------------*/

void initLCD(void)
{
  lcd_init(); /Call provided initializer function
}

/*--------------------------
Function: printStr

Parameters: str - pointer to string to be printed 
                  (only 16 chars are printed)
            lineno - 0 first line
                     1 second line
Returns: nothing

Description: Prints a string on the display on one of the
             two lines.  String is padded with spaces to
             erase any existing characters.
---------------------------*/
void printLCDStr(char *str, byte lineno)
{
	clear_lcd(); //maybe??
	if(lineno == 0)//if lineno is 0, print string on first line
	{
		set_lcd_addr(0x00); //set write address to first line
		type_lcd(str); //print the string to the display
	}
	if(lineno == 1) //if lineno is 1, print string on second line
	{
		set_lcd_addr(0x40); //set write address to second line
		type_lcd(str); //print the string to the display
	}
}
