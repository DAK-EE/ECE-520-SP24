
/*

    Title:	    7-Segment LED Keypad
    Author:	    Diego King
    Date:	    March 26, 2024
    IDE:	    MPLABX v6.20
    Device:	    PIC18F47K42 CURIOSITY NANO
    Version:	    2
    Description:   This program reads a 4x4 matrix keypad (only the first
row and three columns are used) and drives a 7-Segment LED (active low) based on the key
which is pressed:
		1 => Increment (roll-over if F)
		2 => Decrement (roll-under if 0)
		3 => Reset
    Inputs:	    RB[3:7]
    Outputs:	    RB[0:2], RD[0:7]
    
    */
;INCLUDES, HEADERS, PSECT SCRIPTS
#include "AssemblyConfig.inc"
PSECT absdata,abs,ovrld
;DEFINES AND VARIABLES
    DINDEXLO EQU 0x20 ;used for _delay Subroutine
    DINDEXHI EQU 0x21 ;used for _delay Subroutine

;INITIALIZATION
    CALL _setupPortD
    CALL _setupPortB
    CALL _ssegZero ;INITIALIZE TBLPTR TO 0x000D1
;PROGRAM START
_main:
    CALL _readKeys
    TSTFSZ WREG, 0 ;WREG is 0 when no key is pressed
    CALL _keyFunctions
    GOTO _main
_readKeys:
;   TEST COLUMN 1
    CLRF WREG
    BSF PORTB, 0
    BTFSC PORTB, 3
    MOVLW 1	
    BCF PORTB, 0
    
;   TEST COLUMN 2
    BSF PORTB, 1
    BTFSC PORTB, 3
    MOVLW 2
    BCF PORTB, 1
    
;   TEST COLUMN 3
    BSF PORTB, 2
    BTFSC PORTB, 3
    MOVLW 3	
    BCF PORTB, 2
    RETURN
_keyFunctions:
    ;This subroutine takes the output of _readKeys (WREG)
    ;Case WREG
    ;	1 -> 2-1=1 therefore N and Z flags not triggered, move to _increment
    ;	2 -> 2-2=0 therefore Z flag triggered, move to _decrement
    ;	3 -> 2-3=-1 therefore N flag triggered, move to _zero
    SUBLW 2
    BN _ssegZero
    BZ _decrement
    BRA _increment
_ssegZero:
;    ORG 0x000D0
    MOVLW 0x00
    MOVWF TBLPTRU, 0
    MOVLW 0x00
    MOVWF TBLPTRH, 0
    MOVLW 0xD1
    MOVWF TBLPTRL, 0
    TBLRD*
    MOVFF TABLAT, LATD
    GOTO _delay
_ssegF:
    MOVLW 0x00
    MOVWF TBLPTRU, 0
    MOVLW 0x00
    MOVWF TBLPTRH, 0
    MOVLW 0xE0
    MOVWF TBLPTRL, 0
    TBLRD*
    MOVFF TABLAT, LATD
    GOTO _delay
_decrement:
    DECF TBLPTR, 1, 0
    TBLRD*
    BTFSS TABLAT, 7, 0
    GOTO _ssegF
    MOVFF TABLAT, LATD
    GOTO _delay
_increment:
    TBLRD+*
    BTFSS TABLAT, 7, 0
    GOTO _ssegZero
    MOVFF TABLAT, LATD
    GOTO _delay
_delay:			;Subroutine takes around 130k instruction cycles
    CLRF DINDEXLO, 0
    CLRF DINDEXHI, 0
_loop:
    INCFSZ DINDEXLO, 1, 0
    GOTO _loop
    INCF DINDEXHI, 1, 0
    TSTFSZ DINDEXHI, 0
    GOTO _loop
    RETURN
;SETTING UP PORTD
_setupPortD:
    BANKSEL	PORTD ;
    CLRF	PORTD ;Init PORTD
    BANKSEL	LATD ;Data Latch
    CLRF	LATD ;
    BANKSEL	ANSELD ;
    CLRF	ANSELD ;digital I/O
    BANKSEL	TRISD ;
    MOVLW	0b00000000 ;outputs RB[0:7]
    MOVWF	TRISD ;
    RETURN
;SETTING UP PORTB
_setupPortB:
    BANKSEL	PORTB ;
    CLRF	PORTB ;Init PORTB
    BANKSEL	LATB ;Data Latch
    CLRF	LATB ;
    BANKSEL	ANSELB ;
    CLRF	ANSELB ;digital I/O
    BANKSEL	TRISB ;
    MOVLW	0b11111000 ;outputs RB[0:2], inputs RB[3:7]
    MOVWF	TRISB ;
    RETURN
    ORG 0x000D0
;    SSEG DECODE LUT FOR:
;    1. ACTIVE LOW (COMMON ANODE)
;    2. DP IS MSB
;    [rdp g f e d c b a] = [7 6 5 4 3 2 1 0]
    DB 0x00, 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x98, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E, 0x00
