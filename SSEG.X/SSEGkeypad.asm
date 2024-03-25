
;INCLUDES, HEADERS, PSECT SCRIPTS
#include "D:\Documents\ECE 520\AssemblyConfig.inc"
#include <xc.inc>
PSECT absdata,abs,ovrld
;DEFINES AND VARIABLES
    DINDEXLO EQU 0x20
    DINDEXHI EQU 0x21

;INITIALIZATION
    CALL _setupPortD
    CALL _setupPortB
    CALL _zero ;INITIALIZE TBLPTR TO 0x000101
    ORG 0x20
;PROGRAM START
_main:
    CALL _readKeys
    TSTFSZ WREG, 0
    CALL _keyFunctions
    GOTO _main
_readKeys:
;   TEST COLUMN 1
    CLRF WREG
    BSF PORTB, 0
    NOP
    BTFSC PORTB, 3
    MOVLW 1	
    BCF PORTB, 0
    
;   TEST COLUMN 2
    BSF PORTB, 1
    NOP
    BTFSC PORTB, 3
    MOVLW 2
    BCF PORTB, 1
    
;   TEST COLUMN 3
    BSF PORTB, 2
    NOP
    BTFSC PORTB, 3
    MOVLW 3	
    BCF PORTB, 2
    RETURN
_keyFunctions:
    SUBLW 2
    BN _zero
    BZ _decrement
    BRA _increment
_zero:
    MOVLW 0x00
    MOVWF TBLPTRU, 0
    MOVLW 0x01
    MOVWF TBLPTRH, 0
    MOVLW 0x01
    MOVWF TBLPTRL, 0
    TBLRD*
    MOVFF TABLAT, PORTD
    RETURN
_decrement:
    DECF TBLPTR, 1, 0
    TBLRD*
    BTFSS TABLAT, 7, 0
    GOTO _increment
    MOVFF TABLAT, PORTD
    CALL _delay
    RETURN
_increment:
    TBLRD+*
    BTFSS TABLAT, 7, 0
    GOTO _decrement
    MOVFF TABLAT, PORTD
    CALL _delay
    RETURN
_delay:			;Subroutine takes around 130k instruction cycles
    CLRF DINDEXLO, 0
    CLRF DINDEXHI, 0
    BSF STATUS,0, 0
_loop:
    INCFSZ DINDEXLO, 1, 0
    GOTO _loop
    INCF DINDEXHI, 1, 0
    BTFSS DINDEXHI, 5, 0
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
    ORG 0x100
;    SSEG DECODE LUT FOR:
;    1. ACTIVE LOW (COMMON ANODE)
;    2. DP IS MSB
;    [a b c d e f g rdp] = [0 1 2 3 4 5 6 7]
;    DB 0x00, 0x03, 0x9F, 0x25, 0x0D, 0x99, 0x49, 0x41, 0x1F, 0x01, 0x19, 0x00
;    [rdp g f e d c b a] = [7 6 5 4 3 2 1 0]
    DB 0x00, 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x98, 0x00