    ; |------------ CABECERA ------------|
    .include "p30F4013.inc" ; Aqui estan todos los registros del micro.
    
    ; |------------ FUNCIONES ------------|
    ; Estas funciones son de los diagramas que definimos
    .GLOBAL _comandoLCD	    
    .GLOBAL _datoLCD
    .GLOBAL _busyFlagLCD
    .GLOBAL _iniLCD8bits
    .GLOBAL _imprimeLCD
    
    ; |------------ EQUIVALENCIAS ------------|
    ; Este es el equivalente a definicion de macros (#define) en C
    .EQU    RS_LCD,	RF2 ; RS
    .EQU    RW_LCD,	RF3 ; RW
    .EQU    ENABLE_LCD, RD2 ; ENABLE
    .EQU    BF_LCD,	RB7 ; BF: BUSY_FLAG
    
; |------------------ FUNCION COMANDO_LCD ------------------| LISTA
_comandoLCD:
    BCLR    PORTF, #RS_LCD	; RS = 0
    NOP
    BCLR    PORTF, #RW_LCD	; RW = 0
    NOP
    BSET    PORTD, #ENABLE_LCD	; ENABLE = 1
    NOP
    
    MOV.B   WREG,   PORTB	; PORTB = W0
    NOP
    BCLR    PORTD, #ENABLE_LCD	; ENABLE = 0
    NOP
  
    RETURN
    
; |------------------- FUNCION DATO LCD -------------------| Lista   
_datoLCD:
    BSET    PORTF, #RS_LCD	;   RS = 1
    NOP
    BCLR    PORTF, #RW_LCD	;   RW = 0
    NOP
    BSET    PORTD, #ENABLE_LCD	;   ENABLE = 1
    NOP
    
    MOV.B   WREG,   PORTB	;   PORTB = W0
    NOP
    BCLR    PORTD, #ENABLE_LCD	;   ENABLE = 0
    NOP
  
    RETURN    

; |------------------- FUNCION BUSY_FLAG -------------------|   
_busyFlagLCD:
    BCLR    PORTF,  #RS_LCD	;   RS = 0
    NOP
    SETM.B  TRISB		;   Prendemos la parte baja - TRISB OR 0X00FF
    NOP
    BSET    PORTF,  #RW_LCD	;   RW = 1
    NOP
    BSET    PORTD,  #ENABLE_LCD	;   ENABLE = 1
    NOP
    
PROCESO:
    BTSC	PORTB,	#BF_LCD	;   VERIFICA SI BF = 0, SI NO, SE EJECUTA EL GOTO
    GOTO	PROCESO
    
    BCLR	PORTD,	#ENABLE_LCD ;	ENABLE = 0
    NOP
    BCLR	PORTF, #RW_LCD	    ;   RW = 0
    NOP
    MOV		#0XFF00,    W0	    ;   Se usara para realizar la masacara de bits
    IOR		TRISB,	    WREG    ;	TRISB = TRISB OR 0XFF00 
    
    RETURN;
    
; |------------------- FUNCION INICIALIZAR LCD DE 8 BITS -------------------|
; | ---- INICIALIZACION ---|
; | D7 | D6 | D5 | D4 | D3 |  D2 |  D1 |  D0 |     COMANDO    | CODIGO |
; | 0  | 0  | 1  | 1  | X  |  X  |  X  |  X  |   FUNCION SET  |  0X30  |    ; RETARDO 01
; | 0  | 0  | 1  | 1  | X  |  X  |  X  |  X  |   FUNCION SET  |  0X30  |    ; RETARDO 02
; | 0  | 0  | 1  | 1  | X  |  X  |  X  |  X  |   FUNCION SET  |  0X30  |    ; RETARDO 03
; | ---- CONFIGURACION ----|
; | 0  | 0  | 1  | 1  | N=1| F=0 |  X  |  X  |   FUNCION SET  |  0X38  |
; | 0  | 0  | 0  | 0  | 1  | D=0 | C=0 | B=0 | DISPLAY ON/OFF |  0X08  |
; | 0  | 0  | 0  | 0  | 0  |  0  |  0  |  1  |  CLEAR DISPLAY |  0X01  |
; | 0  | 0  | 0  | 0  | 0  |  1  |I/D=1| S=0 | ENTRY MODE SET |  0X06  |
; | 0  | 0  | 0  | 0  | 1  | D=1 | C=1 | B=1 | DISPLAY ON/OFF |  0X0F  |
    
_iniLCD8bits:
    ; ------- TABLA DE INICIALIZACION -------------
    CALL    RETARDO_15ms	; -- RETARDO 01
    MOV	    #0X30,  W0
    CALL    _comandoLCD
    CALL    RETARDO_15ms	; -- RETARDO 02
    MOV	    #0X30,  W0
    CALL    _comandoLCD
    CALL    RETARDO_15ms	; -- RETARDO 03
    MOV	    #0X30,  W0
    CALL    _comandoLCD
    
    ; ------- TABLA DE CONFIGURACI�N ---------------
    CALL    _busyFlagLCD
    MOV	    #0X38,  W0	    ;	CODIGO: 0X38 - FUNCTION SET
    CALL    _comandoLCD
    
    CALL    _busyFlagLCD
    MOV	    #0X08,  W0	    ;	CODIGO: 0X08 - DISPLAY ON/OFF
    CALL    _comandoLCD
    
    CALL    _busyFlagLCD
    MOV	    #0X01,  W0	    ;	CODIGO: 0X01 - CLEAR DISPLAY
    CALL    _comandoLCD
    
    CALL    _busyFlagLCD
    MOV	    #0X06,  W0	    ;	CODIGO: 0X06 - ENTRY MODE SET
    CALL    _comandoLCD
    
    CALL    _busyFlagLCD
    MOV	    #0X0F,  W0	    ;	CODIGO: 0X0F - DISPLAY ON/OFF
    CALL    _comandoLCD
    
    RETURN
    
_imprimeLCD:
    