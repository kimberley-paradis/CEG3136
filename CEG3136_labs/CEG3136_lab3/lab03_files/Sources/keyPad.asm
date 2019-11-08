;----------------------------------------------------------------------
; File: Keypad.asm
; Author: Gilbert Arbez

; Description:
;  This contains the code for reading the
;  16-key keypad attached to Port A
;  See the schematic of the connection in the
;  design document.
;
;  The following subroutines are provided by the module
;
; char pollReadKey(): to poll keypad for a keypress
;                 Checks keypad for 2 ms for a keypress, and
;                 returns NOKEY if no keypress is found, otherwise
;                 the value returned will correspond to the
;                 ASCII code for the key, i.e. 0-9, *, # and A-D
; void initkey(): Initialises Port A for the keypad
;
; char readKey(): to read the key on the keypad
;                 The value returned will correspond to the
;                 ASCII code for the key, i.e. 0-9, *, # and A-D
;---------------------------------------------------------------------

; Include header files
 NOLIST
 include "mc9s12dg256.inc"  ; Defines EQU's for Peripheral Ports
 LIST

; Define External Symbols
 XDEF initKeyPad, pollReadKey, readKey

; External Symbols Referenced
 XREF delayms

**************EQUATES**********

; codes for scanning keyboard

FIRSTROW  EQU %11101111
SECONDROW EQU %11011111
THIRDROW  EQU %10111111
FORTHROW  EQU %01111111

;-----Conversion table
NUMKEYS	  EQU	16	; Number of keys on the keypad
BADCODE 	EQU	$FF 	; returned of translation is unsuccessful
NOKEY		  EQU $00   ; No key pressed during poll period
POLLCOUNT	EQU	1     ; Number of loops to create 1 ms poll time

.text SECTION  ; place in code section
;-----------------------------------------------------------	
; Subroutine: initKeyPad
;
; Description: 
; 	Initiliases PORT A
;-----------------------------------------------------------	
initKeyPad:
	movb #$F0, DDRA
	bset PUCR, %00000001
	rts
;-----------------------------------------------------------    
; Subroutine: ch <- pollReadKey
; Parameters: none
; Local variable:
; Returns
;       ch: NOKEY when no key pressed,
;       otherwise, ASCII Code in accumulator B

; Description:
;  Loops for a period of 2ms, checking to see if
;  key is pressed. Calls readKey to read key if keypress 
;  detected (and debounced) on Port A and get ASCII code for
;  key pressed.
;-----------------------------------------------------------
; Stack Usage ;push A
	OFFSET 0  ; to setup offset into stack 
PRK_A ds.b 1
PRK_X ds.w 1  ;[1] SP
PRK_RA ds.w 1 ;[3]
pollReadKey:   pshx ;preserve x
               psha
         ldx #POLLCOUNT
         movb #$0F,PORTA   ;PORTA = 0000 XXXX [OUTPUT INPUT]
         ldab #NOKEY     ;B = #NOKEY = 00
do       ldaa PORTA        ; A = PORTA      
	 cmpa #$0F   ;if (PORTA == 0F)
	 beq endCheckingLoop   ;No char has been pressed, dont poll any further
         ldd #2     ; A=0000 B= 0001
	 jsr delayms  ;delay 1 ms
         ldaa PORTA   ;A = PORTA
         cmpa #$0F
         beq endCheckingLoop
         jsr readKey      ;returns value in B
endCheckingLoop dex       ;If X is different than 1
          bne do          ;check while condition
          pula
          pulx
          rts


;-----------------------------------------------------------	
; Subroutine: ch <- readKey
; Arguments: none
; Local variable: 
;	ch - ASCII Code in accumulator B

; Description:
;  Main subroutine that reads a code from the
;  keyboard using the subroutine readKeybrd.  The
;  code is then translated with the subroutine
;  translate to get the corresponding ASCII code.
;-----------------------------------------------------------	
;                       B must contain ASCII code.
;Stack usage
	OFFSET 0  ; to setup offset into stack
RK_PORTA       DS.B 1 ; code variable
RK_VARSIZE
RK_X          DS.W 1 ;preserve X
RK_A	      DS.B 1 ; Preserve A
RK_RA         DS.W 1 ; return address

readKey:psha
        pshx	
    leas -RK_VARSIZE,SP 
RK_DO                    
		           
    movb #$0F,PORTA         
RK_LE: ldab PORTA        
    cmpb #$0F
    beq RK_LE
    movb PORTA,0,SP 
    ldd #10
    jsr delayms	           
    ldab PORTA	           
    cmpb 0,SP
    bne RK_DO
    jsr readKeybrd     
    stab 0,SP
    movb #$0F,PORTA 
RK_TE: ldab PORTA 
    cmpb #$0F
    bne RK_TE
    ldd #10
    jsr delayms
    ldab 0,SP
    jsr translate
    leas RK_VARSIZE,SP
    pulx
    pula
    rts		           ;  return(ch); 


;----------------------------------------------------------
; Subroutine: readKeybrd

; Parameters: none.
; Local variable: none.
; Returns
;       The content of PORTA after row detection.
;
; Description:
;  The function tries different combinations to the output
;  pins. The combination that causes the input pins to change
;  from 1111 is returned, allowing the recognition of the row.
;-----------------------------------------------------------
	OFFSET 0
RKB_A ds.b 1;           
RKB_RETURN_ADD ds.w 1     

;FIRSTROW EQU %1110 (output [controllable])  1101  (input)

readKeybrd: psha
   clra
startReading:
; THE RIGHT ROW SHOULD HAVE AN EFFECT ON THE INPUT PINS
   movb #FIRSTROW,PORTA   ;was the key pressed in the first row?   
   ldaa PORTA             ; 1110(controllable)   1101
   cmpa #FIRSTROW         
   bne endReadKeybrd      ; IF THERE IS AN EFFECT ON THE INPUT PINS, JACKPOT!
   movb #SECONDROW,PORTA 
   ldaa PORTA       
   cmpa #SECONDROW
   bne endReadKeybrd    
   movb #THIRDROW,PORTA  
   ldaa PORTA       
   cmpa #THIRDROW
   bne endReadKeybrd 
   movb #FORTHROW,PORTA                
   cmpa #FORTHROW
   bne endReadKeybrd
   ;bra startReading                     
endReadKeybrd 
   ldab PORTA        
   pula
   rts  

;----------------------------------------------------------
; Subroutine: translate
; Parameters: none.
; Local variable: none.
; Returns
;       The ASCII code corresponding to the content of PORTA
;       in accumulator B.
;
; Description:
;  The function goes through multiple comparisons (16) and
;  assigns the corresponding ASCII code to the content of
;  PORTA.
;-----------------------------------------------------------

translate: pshx
 cmpb #%11100111
 beq charA

 cmpb #%11010111
 beq charB

 cmpb #%10110111
 beq charC

 cmpb #%01110111
 beq charD

 cmpb #%01111101 
 beq zero

 cmpb #%11101110
 beq one

 cmpb #%11101101
 beq two 

 cmpb #%11101011
 beq three 

 cmpb #%11011110
 beq four 

 cmpb #%11011101
 beq five

 cmpb #%11011011
 beq six

 cmpb #%10111110
 beq seven

 cmpb #%10111101
 beq eight

 cmpb #%10111011
 beq nine

 cmpb #%01111110
 beq asterisk

 cmpb #%01111011
 beq sharp

 cmpb #%11111111
 beq invalid

charA: ldab #'a'
 bra endtranslate

charB: ldab #'b'
 bra endtranslate

charC: ldab #'c'
 bra endtranslate

charD: ldab #'d'
 bra endtranslate

zero: ldab #'0'
 bra endtranslate

one: ldab #'1'
 bra endtranslate

two: ldab #'2'
 bra endtranslate

three: ldab #'3'
 bra endtranslate

four: ldab #'4'
 bra endtranslate

five: ldab #'5'
 bra endtranslate

six: ldab #'6'
 bra endtranslate

seven: ldab #'7'
 bra endtranslate

eight: ldab #'8'
 bra endtranslate

nine: ldab #'9'
 bra endtranslate

asterisk: ldab #'*'
 bra endtranslate

sharp: ldab #'#'
 bra endtranslate

invalid: ldab #BADCODE
endtranslate: pulx
 	rts