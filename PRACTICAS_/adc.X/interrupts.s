    ; |------------ CABECERA ------------|
    .include "p30F4013.inc"	    ; Aqui estan todos los registros del micro.
        
    ; Interrupciones
    .GLOBAL __T3Interrupt
    .GLOBAL __ADCInterrupt
    
    
__T3Interrupt:
    BTG	    LATD,   #LATD0 ; RD0
    BCLR    IFS0,   #T3IF
    RETFIE    

; ADCBUF0 Registro de 16, resultado de conversion en 12..0 bits
; w1 = 0b1x concat ADCBUF0(11 downto 6); w0 = 0b1x concat ADCBUF0(5 downto 0);
__ADCInterrupt:
    PUSH.S
    MOV     ADCBUF0,    W0              ;
    LSR     W0,         #6,     W1      ; W1 = W0 >> 6 = w0 >> 0b 0110 ; lit5
    BSET    W1,         #7              
    AND     #0x003f,    W0              ; W0 &= 0X03F ssi w0 &= 0b 0011 1111 ; lit10
    MOV     W0,         U1TXREG         ; 
    NOP                                 ; Necesario ? 
    MOV     W1,         U1TXREG         
    BCLR    IFS0,       #ADIF           ; 
    POP.S
    RETFIE
