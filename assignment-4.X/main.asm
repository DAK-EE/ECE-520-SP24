    //-----------------------------
    //Temperature Controller
    //-----------------------------
    //Purpose: This program controls a cooling fan and heater based on
    //the current temperature and a hard-coded desired temperature.
    //Compiler: MPLAB X IDE v6.20
    //Author: Diego King
    //Versions:
    //	v1 - March 5, 2024
    //-----------------------------
    
    ;------------------------------
    ;	    INPUTS
    ;------------------------------
    #define desired 15
    #define measured -5
    
    
    #define WREG 0x3FE8
    #define STATUS 0x3FD8
    #define PRODL 0x3FF3
    
    #define desiredReg 0x20
    #define measuredReg 0x21
    #define controllerReg 0x22

    #define desiredDecRegLow 0x60
    #define desiredDecRegHigh 0x61
    #define desiredDecRegSign 0x62

    #define measuredDecRegLow 0x70
    #define measuredDecRegHigh 0x71
    #define measuredDecRegSign 0x72

    #define heater PORTD,2
    #define cooler PORTD,1
;    ---INITIALIZING PORTD---
;    ---SEE P.261 OF DATASHEET---
    #define LATD 0X3FBD
    #define PORTD 0x3FCD
    #define TRISD 0x3FC5
    #define ANSELD 0x3A70
    BANKSEL PORTD
    CLRF PORTD
    BANKSEL LATD
    CLRF LATD
    BANKSEL ANSELD
    CLRF ANSELD
    BANKSEL TRISD
    MOVLW 0b11111000
    MOVWF TRISD
;   ---END OF PORTD INIT---

;    ---MISC VARIABLES---
    #define testee 0x30
    #define index 0x27
    MOVLW 8
    MOVWF index
    
;    ---HARD CODING THRESHOLDS---
    #define desiredMin 10
    #define desiredMax 50
    #define desiredMinReg 0x31
    #define desiredMaxReg 0x32
    MOVLW desiredMin
    MOVWF desiredMinReg
    MOVLW desiredMax
    MOVWF desiredMaxReg
    
    #define measuredMin -20
    #define measuredMax 60
    #define measuredMinReg 0x33
    #define measuredMaxReg 0x34
    MOVLW measuredMin
    MOVWF measuredMinReg
    MOVLW measuredMax
    MOVWF measuredMaxReg
;    ---END OF THRESHOLD CODING---
    
    MOVLW desired
    CALL CLAMP_DESIRED
    MOVWF desiredReg
    CALL DISPLAY_DESIRED
IDLE:
    CLRF PORTD
    CLRF controllerReg
POLL:
    MOVLW measured
    CALL CLAMP_MEASURED
    MOVWF measuredReg
    CALL DISPLAY_MEASURED
    CPFSEQ desiredReg
    GOTO TEST
    GOTO POLL
TEST:
    CPFSLT desiredReg
    GOTO HEAT
    GOTO COOL
HEAT:
    MOVLW 1
    MOVWF controllerReg
    bcf cooler
    bsf heater
    GOTO POLL
COOL:
    MOVLW 2
    MOVWF controllerReg
    bcf heater
    bsf cooler
    GOTO POLL
;THE FOLLOWING FUNCTIONS CONVERT
;DECIMAL TO BCD USING THE DOUBLE
;DABBLE ALGORITHM
DISPLAY_DESIRED:
    CALL RESOLVE_SIGN
    BNN DISPLAY_NONNEG_DESIRED
    CLRF 0x40
    BSF 0x40, 0
    MOVFF 0x40, desiredDecRegSign
DISPLAY_NONNEG_DESIRED:
    CALL DOUBLE_DABBLE
    MOVLW 0b00001111
    ANDWF testee, 0
    MOVWF 0x40
    MOVFF 0x40, desiredDecRegLow
    MOVLW 0b11110000
    ANDWF testee, 0
    MOVWF 0x40
    SWAPF 0x40, 1
    MOVFF 0x40, desiredDecRegHigh
    RETURN
DISPLAY_MEASURED:
    CALL RESOLVE_SIGN
    BNN DISPLAY_NONNEG_MEASURED
    CLRF 0x40
    BSF 0x40, 0
    MOVFF 0x40, measuredDecRegSign
DISPLAY_NONNEG_MEASURED:
    CALL DOUBLE_DABBLE
    MOVLW 0b00001111
    ANDWF testee, 0
    MOVWF 0x40
    MOVFF 0x40, measuredDecRegLow
    MOVLW 0b11110000
    ANDWF testee, 0
    MOVWF 0x40
    SWAPF 0x40, 1
    MOVFF 0x40, measuredDecRegHigh
    RETURN
DOUBLE_DABBLE:
    CLRF testee
LOOP:
    RLCF WREG
    RLCF testee
    DECFSZ index
    CALL TEST_NIBBLE, 1
    TSTFSZ index
    GOTO LOOP
    MOVLW 8
    MOVWF index
    RETURN
TEST_NIBBLE:
    MOVLW 4
    MOVWF 0x28
    MOVLW 0b00001111
    ANDWF testee, 0
    CPFSLT 0x28
    RETURN 1
    MOVLW 3
    ADDWF testee, 1
    RETURN 1
RESOLVE_SIGN:
    BTFSC WREG,7
    GOTO TWOS_COMPLEMENT
    BCF STATUS,4
    RETURN
TWOS_COMPLEMENT:
    COMF WREG
    INCF WREG
    BSF STATUS,4
    RETURN
;THE FOLLOWING FUNCTIONS ENSURE THE 
;MEASURED AND DESIRED VALUES
;DO NOT EXCEED THEIR THRESHOLDS
CLAMP_DESIRED:
    MOVWF testee
    BTFSS desiredMinReg, 7
    GOTO TEST_AGAINST_POS_DESIRED
    GOTO TEST_AGAINST_NEG_DESIRED
TEST_AGAINST_POS_DESIRED:
    BTFSC testee, 7
    RETLW desiredMin
    GOTO MINCOMPARE_DESIRED
TEST_AGAINST_NEG_DESIRED:
    BTFSS testee, 7
    GOTO MAX_CHECK_SIGN_DESIRED
    GOTO MINCOMPARE_DESIRED
MINCOMPARE_DESIRED:
    MOVLW desiredMin
    CPFSLT testee
    MOVFF testee, WREG
    GOTO MAX_CHECK_SIGN_DESIRED
MAX_CHECK_SIGN_DESIRED:
    BTFSC testee, 7
    RETURN
    MOVLW desiredMax
    CPFSGT testee
    MOVFF testee, WREG
    RETURN
CLAMP_MEASURED:
    MOVWF testee
    BTFSS measuredMinReg, 7
    GOTO TEST_AGAINST_POS_MEASURED
    GOTO TEST_AGAINST_NEG_MEASURED
TEST_AGAINST_POS_MEASURED:
    BTFSC testee, 7
    RETLW measuredMin
    GOTO MINCOMPARE_MEASURED
TEST_AGAINST_NEG_MEASURED:
    BTFSS testee, 7
    GOTO MAX_CHECK_SIGN_MEASURED
    GOTO MINCOMPARE_MEASURED
MINCOMPARE_MEASURED:
    MOVLW measuredMin
    CPFSLT testee
    MOVFF testee, WREG
    GOTO MAX_CHECK_SIGN_MEASURED
MAX_CHECK_SIGN_MEASURED:
    BTFSC testee, 7
    RETURN
    MOVLW measuredMax
    CPFSGT testee
    MOVFF testee, WREG
    RETURN
    
    END