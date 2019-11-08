;------------------------------------------------------
; Alarm System Simulation Assembler Program
; File: delay.asm
; Description: The Delay Module
; Author: Gilbert Arbez
; Date: Fall 2010
;------------------------------------------------------

; Some definitions
COUNT equ 3000
	SWITCH code_section

;-------------------------------
; Subroutine delayms
; Parameters: num - number of milliseconds to delay - in D
; Returns: nothing
; Description: Delays for num ms. 
;--------------------------------
delayms:
delayms_loop:
	jsr delay1ms
	dbne d, delayms_loop
  	rts
	
;------------------------------------------------------
; Subroutine setDelay
; Parameters: cnt - accumulator D
; Returns: nothing
; Global Variables: delayCount
; Description: Intialises the delayCount 
;              variable.
;------------------------------------------------------
setDelay: 
	std delayCount ; delayCount = counter  
   	rts     


;------------------------------------------------------
; Subroutine: polldelay
; Parameters:  none
; Returns: TRUE when delay counter reaches 0 - in accumulator A
; Local Variables
;   retval - acc A cntr - X register
; Global Variables:
;      delayCount
; Description: The subroutine delays for 1 ms, decrements delayCount.
;              If delayCount is zero, return TRUE; FALSE otherwise.
;   Core Clock is set to 24 MHz, so 1 cycle is 41 2/3 ns
;   NOP takes up 1 cycle, thus 41 2/3 ns
;   Need 24 cyles to create 1 microsecond delay
;   8 cycles creates a 333 1/3 nano delay
;	DEX - 1 cycle
;	BNE - 3 cyles - when branch is taken
;	Need 4 NOP
;   Run Loop 3000 times to create a 1 ms delay   
;------------------------------------------------------
; Stack Usage:
	OFFSET 0  ; to setup offset into stack
PDLY_VARSIZE:
PDLY_PR_Y   DS.W 1 ; preserve Y
PDLY_PR_X   DS.W 1 ; preserve X
PDLY_PR_B   DS.B 1 ; preserve B
PDLY_RA     DS.W 1 ; return address

polldelay: pshb  
   	pshx  
   	pshy  
     
   	jsr delay1ms; Complete this routine  
   	ldy delayCount  
   	dey  
   	sty delayCount  
   	bne ifFalse  
   	ldaa #TRUE  
   	bra isTrue 
	ifFalse:  
   	ldaa #FALSE  
   	; restore registers and stack  
	isTrue: 
   	puly  
   	pulx  
   	pulb  
   	rts
  
delay1ms:
	pshx
	ldx #COUNT
delayloop:
	nop
	nop
	nop
	nop
	dex
	bne delayloop
	pulx
	rts

;------------------------------------------------------
; Global variables
;------------------------------------------------------
   switch globalVar
delayCount ds.w 1   ; 2 byte delay counter