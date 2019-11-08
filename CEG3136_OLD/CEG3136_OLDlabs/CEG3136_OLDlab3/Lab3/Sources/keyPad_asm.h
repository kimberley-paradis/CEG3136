/*----------------------
File: KeyPad_asm.h
Description:  Header file to use the KeyPad Module
-----------------------*/

#ifndef _KEYPAD_ASM_H
#define _KEYPAD_ASM_H

//C Prototypes to assembler subroutines - Entry Points
void initKeyPad(void);
byte pollReadKey(void);
byte readKey(void);

// Some Definitions
#define NOKEY 0  // See KeyPad.asm

#endif /* _KEYPAD_ASM_H */