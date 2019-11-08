;------------------------------------------------------
; File: Keypad.asm
; Author: Will Wu
; 
; Description: Reads one of the 16 characters from the 
;              keypad attached to Port A.
;------------------------------------------------------

; Include files
#include "sections.inc" ; Contains the EQUATES for the symbols
#include "reg9s12.inc" ; Defines the EQUATES for the peripheral ports

; Convertion Table
NUMKEYS	  EQU 16  ; Number of keys on the keypad
BADCODE	  EQU $FF ; Unsuccessful return of translation
NOKEY	  EQU $00 ; No key pressed
POLLCNT   EQU 1	  ; Loop number to create 1ms poll time

 SWITCH globalConst ; global constant

; Rows
ROW1 EQU %11101111 ; FIRSTROW  = 1110 1111
ROW2 EQU %11011111 ; SECONDROW = 1101 1111
ROW3 EQU %10111111 ; THIRDROW  = 1011 1111
ROW4 EQU %01111111 ; FORTHROW  = 0111 1111

; Define structures
 OFFSET 0
trnsTbl_code ds.b 1
trnsTbl_ascii ds.b 1
trnsTbl_struct_len EQU *

; Translation Table
trnsTbl dc.b %11101110,'1'
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

 SWITCH code_section ; place in code section

;------------------------------------------------------
; Subroutine: initKeyPad
; Parameters: none
; Returns: none
; Local Variables: none
; Global Variables: none
; Descriptions: Initiates PORTA
;		Bit 0 to 3 are inputs
;		Bit 4 to 7 are outputs
;		Enables pull up
;------------------------------------------------------
initKeyPad:
   movb #$f0,DDRA ; DDRA = 0x0f
   movb #$01,PUCR ; PUCR = 00000001
   rts

;------------------------------------------------------
; Subroutine: pollReadKey
; Parameters: none
; Returns: input - NOKEY if no inputs
;		   otherwise ASCII code in acc. B
; Local Variables: code  - store into acc. B
;		   input - store into acc. B
;		   cnt   - counter, creates 10ms delay
; Global Variables: none
; Descriptions: Checks if there are any inputs from 
;		the keypad, if so, delay 2ms and then
;		checks again. Calls readKey if input
;		detected.
;------------------------------------------------------
; Stack Usage
	OFFSET 0 ; set offset to stack
PRK_INPUT DS.B 1 ; return value, in ASCII
PRK_VARSIZE:
PRK_PR_X  DS.W 1 ; Preserve X for cnt
PRK_RA    DS.W 1 ; Return address

pollReadKey: pshx           ; int cnt
   leas -PRK_VARSIZE,SP     ; load effective addr into SP
   movb #NOKEY,PRK_INPUT,SP ; input = NOKEY
   ldx #POLLCNT             ; cnt = POLLCNT
   movb #$0f,PORTA           ; PORTA = 0x0f
prkloop1:
prkif1:
   ldab PORTA
   cmpb #$0f
   beq prkendif1            ; if (PORTA != 0x0f)
   ldd #2
   jsr delayms              ; delayms(2)
prkif2:
   ldab PORTA
   cmpb #$0f
   beq prkendif2            ; if (PORTA != 0x0f)
   jsr readKey
   stab PRK_INPUT,SP        ; input = readKey()
   bra prkendloop1
prkendif2
prkendif1
   dex                      ; cnt--
   bne prkloop1             ; while (cnt != 0)
prkendloop1
   ldab PRK_INPUT,SP        ; return(input)
   ; Restore stack and regs
   leas PRK_VARSIZE,SP
   pulx
   rts

;------------------------------------------------------
; Subroutine: readKey
; Parameters: none
; Returns: ch - ASCII code, stored in acc. B
; Local Variables: ch - in acc. B
;                  keycode - on stack 
; Global Variables: none
; Descriptions: Reads code from the keypad using
;               subroutine keyInput. The code will then
;               be translated into ASCII code using the
;               subroutine translate.
;------------------------------------------------------
; Stack Usage
	OFFSET 0 ; set offset to stack
RK_KEYCODE DS.B 1 ; keycode var.
RK_VARSIZE DS.B 1 ; Preserve acc. A
RK_RA      DS.W 1 ; Return address

readKey: psha               ; byte keycode
   leas -RK_VARSIZE,SP
rkloop1:
   movb $0F,PORTA           ; PORTA = 0x0f
rkloop2:
   ldab PORTA
   cmpb #$0F
   beq rkloop2              ; while (PORTA == 0x0f)
   movb PORTA,RK_KEYCODE,SP ; keycode = PORTA
   ldd #10
   jsr delayms              ; delayms(10)
   ldab PORTA
   cmpb RK_KEYCODE,SP
   bne rkloop1              ; while (keycode != PORTA)
   jsr keyInput
   stab RK_KEYCODE,SP       ; keycode = keyInput()
   movb #$0F,PORTA           ; PORTA = 0x0f
rkloop3:
   ldab PORTA
   cmpb #$0F
   bne rkloop3              ; while (PORTA != 0x0f)
   ldd #10
   jsr delayms              ; delayms(10)
   ldab RK_KEYCODE,SP
   jsr translate            ; ch = translate(keycode)
   ; Restore stack and regs
   leas RK_VARSIZE,SP
   pula
   rts                      ; return(ch)

;------------------------------------------------------
; Subroutine: keyInput
; Parameters: none
; Returns: keyinput - keycode of the key pressed, in 
;                     acc. B
; Local Variables: keyinput - in acc. B
; Global Variables: none
; Descriptions: If low level is found on one of the
;               input pins, return the input.
;------------------------------------------------------
keyInput:
   movb #ROW1,PORTA ; PORTA = FIRSTROW
kiif1:
   ldab PORTA
   cmpb #ROW1
   bne kiendif1     ; if (PORTA == FIRSTROW)
   movb #ROW2,PORTA ; PORTA = SECONDROW
kiif2:
   ldab PORTA
   cmpb #ROW2
   bne kiendif2     ; if (PORTA == SECONDROW)
   movb #ROW3,PORTA ; PORTA = THRIDROW
kiif3:
   ldab PORTA
   cmpb #ROW3
   bne kiendif3     ; if (PORTA == THIRDROW)
   movb #ROW4,PORTA ; PORTA = FORTHROW
kiendif1
kiendif2
kiendif3
   ldab PORTA       ; keyinput = PORTA
   rts              ; return(keyinput)

;------------------------------------------------------
; Subroutine: translate
; Parameters: input - keycode read from keypad, in 
;             acc B
; Returns: ch - character in ASCII code, in acc. B
; Local Variables: ptr - pointer to translation table,
;                        in reg X
;                  cnt - counter, in acc A
; Global Variables: none
; Descriptions: Use the translation table to translate
;               the keycode into ASCII codes. If no
;               value is found, BADCODE is returned.
;------------------------------------------------------
; Stack Usage
	OFFSET 0
TL_CH DS.B 1   ; Return var
TL_PR_A DS.B 1 ; Preserved A for cnt
TL_PR_X DS.B 1 ; Preserved X for code
TL_RA DS.W 1   ; Return addr

translate: psha
   pshx
   leas -1,SP                    ; byte ch
   ldx #trnsTbl                  ; ptr = trnsTbl
   clra                          ; cnt = 0
   movb #BADCODE,TL_CH,SP        ; ch = BADCODE
tlloop1:
   cmpb trnsTbl_code,X
   bne tlendif1                  ; if(input == (ptr = code))
   movb trnsTbl_ascii,X,TL_CH,SP ; ch = [ptr+1]
   bra tlendloop1
tlendif1:
   leax trnsTbl_struct_len,X     ; ptr++
   inca ; cnt++
   cmpa #NUMKEYS
   blo tlloop1                   ; while (cnt < NUMKEYS)
tlendloop1
   ; Restore regs
   pulb
   pulx
   pula
   rts

