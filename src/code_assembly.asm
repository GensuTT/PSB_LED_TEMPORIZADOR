.NOLIST
.INCLUDE "m328Pdef.inc"
.LIST

; atribuição de nome de hardware e pinos

.equ INTERRUPTOR = PD2     ; D2 (Entrada c/ pull-up, ativo LOW)
.equ SENSOR      = PD3     ; D3 (Entrada c/ pull-up, ativo LOW)
.equ LED         = PD4     ; D4 (Saída, ativo HIGH)
.equ SEG_G       = PD5     ; D5 (Saída, Segmento G do display)

.equ ContDez     = PC0     ; C0 (Base do Transistor da Dezena)
.equ ContUni     = PC1     ; C1 (Base do Transistor da Unidade)

.equ DISPLAY     = PORTB   ; PB0-PB5 = Segmentos A-F
.equ CONTROLE    = PORTC   ; Porta dos transistores

.equ FLAG_OVERRIDE = 0

; Regs
.def AUX      = R16
.def UNIDADE  = R20
.def DEZENA   = R21
.def FLAG_REG = R22

; interromper 

.ORG 0x0000
    RJMP Inicializacoes

.ORG INT0addr            ; Interrupção do Botão (PD2)
    RJMP ISR_Botao

.ORG INT1addr            ; Interrupção do Sensor (PD3)
    RJMP ISR_Sensor

.ORG OC1Aaddr
    RJMP ISR_Timer1

; inicio
.ORG 0x0034
Inicializacoes:
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; PORTB - Display
    
    LDI AUX, 0b00111111        
    OUT DDRB, AUX
    CLR AUX                  
    OUT PORTB, AUX
    
    LDI AUX, (1<<LED)|(1<<SEG_G)
    OUT DDRD, AUX              
    LDI AUX, (1<<INTERRUPTOR)
    OUT PORTD, AUX             

    ; PORTC
    ; C0 - Dezena C1 - Unidade
    LDI AUX, (1<<ContDez)|(1<<ContUni)
    OUT DDRC, AUX
    OUT PORTC, AUX            
    LDI UNIDADE, 0
    LDI DEZENA, 0
    CLR FLAG_REG

    

    CLR AUX
    STS TCCR1A, AUX
    LDI AUX, (1<<WGM12)|(1<<CS12)|(1<<CS10)
    STS TCCR1B, AUX
    LDI AUX, HIGH(15624)
    STS OCR1AH, AUX
    LDI AUX, LOW(15624)
    STS OCR1AL, AUX
    LDI AUX, (1<<OCIE1A)
    STS TIMSK1, AUX

    LDI AUX, (1<<ISC11)|(1<<ISC10)|(1<<ISC01)|(0<<ISC00)
    STS EICRA, AUX

    LDI AUX, (1<<INT1)|(1<<INT0)
    OUT EIMSK, AUX

    SEI                    

; main

Principal:
    SBIS PIND, SENSOR ; Verificamos o pino do sensor, caso esteja baixa (detectando presença) limpa a flag de override, iniciando novamente o sistema         
    CBR FLAG_REG, (1<<FLAG_OVERRIDE)

    CPI DEZENA, 0
    BRNE Verifica_Flag_LED
    CPI UNIDADE, 0
    BRNE Verifica_Flag_LED

    CBI PORTD, LED
    RJMP Atualiza_E_Repete

Verifica_Flag_LED:
    SBRS FLAG_REG, FLAG_OVERRIDE
    SBI PORTD, LED
    SBRC FLAG_REG, FLAG_OVERRIDE
    CBI PORTD, LED

Atualiza_E_Repete:
    RCALL AtualizaDisplay
    RJMP Principal

ISR_Botao:
    PUSH AUX
    IN AUX, SREG
    PUSH AUX

    SBR FLAG_REG, (1<<FLAG_OVERRIDE)
    LDI DEZENA, 0
    LDI UNIDADE, 0

    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI

ISR_Sensor:
    PUSH AUX
    IN AUX, SREG
    PUSH AUX

    SBRC FLAG_REG, FLAG_OVERRIDE
    RJMP Fim_ISR_Sensor

    LDI DEZENA, 1
    LDI UNIDADE, 5
    CLR AUX
    STS TCNT1H, AUX
    STS TCNT1L, AUX

Fim_ISR_Sensor:
    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI

AtualizaDisplay:

    CBI CONTROLE, ContDez
    CBI CONTROLE, ContUni


    MOV AUX, UNIDADE
    RCALL Decodifica

    MOV AUX, R0
    ANDI AUX, 0x3F            
    OUT PORTB, AUX

    SBRC R0, 6                    
    SBI PORTD, SEG_G              
    SBRS R0, 6                    
    CBI PORTD, SEG_G           

   
    SBI CONTROLE, ContUni
    RCALL AtrasoMultiplex

    
    CBI CONTROLE, ContUni


    MOV AUX, DEZENA
    RCALL Decodifica

   






    MOV AUX, R0
    ANDI AUX, 0x3F
    OUT PORTB, AUX


    SBRC R0, 6
    SBI PORTD, SEG_G
    SBRS R0, 6
    CBI PORTD, SEG_G

    
    SBI CONTROLE, ContDez
    RCALL AtrasoMultiplex

 
    CBI CONTROLE, ContDez

    RET


AtrasoMultiplex:
    LDI R18, 50
L_AM1:
    LDI R19, 200
L_AM2:
    NOP
    DEC R19
    BRNE L_AM2
    DEC R18
    BRNE L_AM1
    RET


Decodifica:
    LDI ZH, HIGH(Tabela<<1)
    LDI ZL, LOW(Tabela<<1)
    ADD ZL, AUX
    BRCC le_tab
    INC ZH
le_tab:
    LPM R0, Z
    RET


ISR_Timer1:
    PUSH AUX
    IN AUX, SREG
    PUSH AUX

    SBRC FLAG_REG, FLAG_OVERRIDE
    RJMP Avalia_Zero

    SBIS PIND, SENSOR
    RJMP Avalia_Zero      

    LDI DEZENA, 1
    LDI UNIDADE, 5
    RJMP Fim_ISR          

Avalia_Zero:
    CPI DEZENA, 0
    BRNE Decrementa_Tempo
    CPI UNIDADE, 0
    BREQ Fim_ISR

Decrementa_Tempo:
    CPI UNIDADE, 0
    BRNE Sub_Unidade
    DEC DEZENA
    LDI UNIDADE, 9
    RJMP Fim_ISR

Sub_Unidade:
    DEC UNIDADE

Fim_ISR:
    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI

Tabela:
    .DB 0x3F, 0x06 ; 0, 1
    .DB 0x5B, 0x4F ; 2, 3
    .DB 0x66, 0x6D ; 4, 5
    .DB 0x7D, 0x07 ; 6, 7
    .DB 0x7F, 0x6F ; 8, 9
