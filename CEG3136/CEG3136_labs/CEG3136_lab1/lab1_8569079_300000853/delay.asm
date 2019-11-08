;------------------------------------------------------
; Alarm System Simulation Assembler Program
; File: delay.asm
; Description: The Delay Module
; Author: Gilbert Arbez
; Date: Fall 2010
;------------------------------------------------------

; Some definitions

  SWITCH code_section

;------------------------------------------------------
; Subroutine setDelay
; Parameters: cnt - accumulator D
; Returns: nothing
; Global Variables: delayCount
; Description: Intialises the delayCount 
;              variable.
;------------------------------------------------------
setDelay: 

   ; Complete this subroutine
	STD delayCount ; store delayCount in accumulator


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

  polldelay:  pshb
  pshx
  pshy


	; Complete this routine

  	LDAA #FALSE
  	LDX #3000

timerLoop:  ; check loop that verifies the decrement of the timer using the 1 ms loop delay
	BNE delay_loop
	BEQ endLoop

delay_loop:  ; small loop that implements a 1ms counter using clock speed (24 clock cycles : 1 millisecond)
	NOP
  	NOP
  	NOP
  	NOP
  	DEX
	BRA timerLoop
  ; end of 1 MS delay loop

endLoop:  ; decrement delayCount commands, this is the loop that will terminate the timer cycle at the end of the preset time.
  	LDY delayCount	
  	DEY
  	STY delayCount
  	BNE return_from_poll_delay
  	LDAA #TRUE

return_from_poll_delay:
   ; restore registers and stack
   puly
   pulx
   pulb
   rts



;------------------------------------------------------
; Global variables
;------------------------------------------------------
   switch globalVar
delayCount ds.w 1   ; 2 byte delay counter
