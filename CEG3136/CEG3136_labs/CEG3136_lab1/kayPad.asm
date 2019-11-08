;----------------------------------------------------------------------
; File: Keypad.asm
; Author:

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
 include "sections.inc"
 include "reg9s12.inc"  ; Defines EQU's for Peripheral Ports

**************EQUATES**********

;-----Conversion table
NUMKEYS 		EQU	16	; Number of keys on the keypad
BADCODE 		EQU	$FF 	; returned of translation is unsuccessful
NOKEY		EQU 	$00   ; No key pressed during poll period
POLLCOUNT	EQU	1     ; Number of loops to create 1 ms poll time

ROW1 EQU %11101111
ROW2 EQU %11011111
ROW3 EQU %10111111
ROW4 EQU %01111111
 SWITCH globalConst  ; Constant data

; Conversion table structure cnvTbl_struct
 OFFSET 0
cnvTbl_code DS.B 1
cnvTbl_ascii  DS.B 1
cnvTbl_struct_len EQU *

; Conversion Table
cnvTbl:  dc.b %11101110,'1'
	dc.b %11101101,'2'
	dc.b %11101011,'3'
	dc.b %11100111,'a'
	dc.b %11011110,'4'
	dc.b %11011101,'5'
	dc.b %11011011,'6'
	dc.b %11010111,'b'
	dc.b %10111110,'7'
	dc.b %10111101,'8'
	dc.b %10111011,'9'
	dc.b %10110111,'c'
	dc.b %01111110,'*'
	dc.b %01111101,'0'
	dc.b %01111011,'#'
	dc.b %01110111,'d'


 SWITCH code_section  ; place in code section
;-----------------------------------------------------------	
; Subroutine: initKeyPad
;
; Description: 
; 	Initiliases PORT A
; 	Bits 0-3 as inputs
; 	Bits 4-7 as ouputs
; 	Enable pullups 
;-----------------------------------------------------------	
initKeyPad:
	movb #$f0,DDRA ; Data Direction Register
	movb #$01,PUCR; Enable pullups
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
; Stack Usage
	;OFFSET 0  ; to setup offset into stack
;PRK_CH         DS.B 1 ; return value, ASCII code
;PRK_VARSIZE:
;PRK_PR_X       DS.W 1 ; preserve X
;PRK_RA         DS.W 1 ; return address 

pollReadKey: pshx   ; preserve register
	psha
   ;leas -PRK_VARSIZE,SP
   ;movb #NOKEY,PRK_CH,SP ; ch = NOKEY;
   	ldab #NOKEY
	ldx #POLLCOUNT   ; count = POLLCOUNT;
	movb #$0f,PORTA ; PORTA = 0x0f; //set outputs to low
	
prk_loop:           ;           do {
prk_if1:
   ldaa PORTA        ;      if(PORTA != 0x0f)
   cmpa #$0f        ;       {
   beq prk_endif1   ; 
   ldd #2           ;                 delayms(2)
   jsr delayms     ;              
prk_if2:            ;             
   ldaa PORTA        ;                 if(PORTA != 0x0f)
   cmpa #$0f        ;                 {
   beq prk_endif2
	ldd#1; debounce 1 ms
	jsr delay1ms
   jsr readKey      ;                     ch = readKey();
   ;stab PRK_CH,SP   ;
   ;bra prk_endloop  ;                     break;
prk_endif2:
prk_endif1:         ;              }
   dex              ;          count--;
   bne prk_loop       ;        } while(count!=0);
;prk_endloop: 
   ;ldab PRK_CH,SP   ; return(ch); in B - Acummulator
; Restore stack and registers
   ;leas PRK_VARSIZE,SP
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
; Stack Usage
;	OFFSET 0  ; to setup offset into stack
;RK_TMP       DS.B 1 ; code variable
;RK_VARSIZE:    
;RK_RA         DS.W 1 ; return address

readKey:
;leas -RK_VARSIZE,SP ; 
rk_loop:                     ; do{
    movb $0F,PORTA         ;    PORTA = 0x0F;
rk_while1:
    ldaa PORTA         ;    while(PORTA==0x0F) 
    cmpa #$0F
    beq rk_while1
    ;movb PORTA,RK_TMP,SP ;    tmp = PORTA;
    ldd #10
    jsr delayms	           ;    delayms(10); Debouncing Key press
    ldab PORTA	           ; 
    ;cmpb RK_TMP,SP			;
 	cba ; PORTA check with before and after delay
    bne rk_loop				;} while(tmp != PORTA); 
    jsr keyPress       ; tmp = keyPress();  // get the keycode
    ;stab RK_TMP,SP
    movb #$0F,PORTA        ; PORTA = 0x0F;  // set all output pins to 0
rk_while2: 
    ldaa PORTA         ; while(PORTA!=0F)
    cmpa #$0F			;{
    bne rk_while2
    ldd #10
    jsr delayms            ; delayms(10);  // Debouncing release of the key
    ;ldab RK_TMP,SP			;} 
    jsr translate          ; ch = translate(tmp);
    ;leas RK_VARSIZE,SP
    rts		           ;  return(ch); 

;-----------------------------------------------------------	
; Subroutine: key <- keyPress       
; Arguments: none
; Local variables:  key: Accumulator B
; Returns: key - in Accumulator B - code corresponding to key pressed

; Description: Assume key is pressed. Set 0 on each output pin
;              to find row and hence code for the key.
;-----------------------------------------------------------	
; codes for scanning keyboard

keyPress: 
    movb #ROW1,PORTA  ; PORTA = ROW1;
kp_if1:
    ldaa PORTA          ; if(PORTA == ROW1) 
    cmpa #ROW1
    bne kp_endif      ; {
    movb #ROW2,PORTA  ;   PORTA = ROW2
kp_if2:
    ldaa PORTA          ;   if(PORTA == ROW2)
    cmpa #ROW2
    bne kp_endif      ;   {
    movb #ROW3,PORTA  ;      PORTA = ROW3;
kp_if3:
    ldaa PORTA          ;      if(PORTA == ROW3)
    cmpa #ROW3        ;        {
    bne kp_endif      ;          PORTA = ROW4;
    movb #ROW4,PORTA  ;        }
    cmpa #ROW4
    bne kp_endif 
    bra keyPress
kp_endif: 		   ;   }                                                    
                        ; }
    ldab PORTA        ; key = PORTA;
    rts               ; return(key);
	      
;-----------------------------------------------------------	
; Subroutine:  ch <- translate(code)
; Arguments
;	code - in Acc B - code read from keypad port
; Returns
;	ch - saved on stack but returned in Acc B - ASCII code
; Local Variables
;    	ptr - in register X - pointer to the table
;	count - counter for loop in accumulator A
; Description:
;   Translates the code by using the conversion table
;   searching for the code.  If not found, then BADCODE
;   is returned.
;-----------------------------------------------------------	
; Stack Usage:
;   OFFSET 0
;TR_CH DS.B 1  ; for ch 
;TR_VARSIZE:
;TR_PR_A DS.B 1 ; preserved regiters A
;TR_PR_X DS.B 1 ; preserved regiters X
;TR_RA DS.W 1 ; return address

translate: pshx
	;psha	; preserve registers
;	leas -TR_VARSIZE,SP 		    ; 
	ldx #cnvTbl		    ; ptr = cnvTbl;
	;movb #BADCODE,TR_CH,SP ; ch = BADCODE;
	clra			    ; ix = 0;
tr_for: 			    ; for(i=0;i<NUMKEYS;i++) {
tr_if:	
	cmpb cnvTbl_code,X  	    ;     if(code == ptr->code)
	bne tr_endif		    ;     {
	ldab cnvTbl_ascii,X 	    ;        ch <- [ptr+1]
	bra tr_end  		    ;         break;
tr_endif:  			    ;     }
				    ;     else {	
	leax cnvTbl_struct_len,X    ;           ptr++;
	inca ;    
	cmpa #NUMKEYS               ;} 
	blo tr_for;
tr_end ; 
	; restore registres
	;pula
	pulx
	rts
	
