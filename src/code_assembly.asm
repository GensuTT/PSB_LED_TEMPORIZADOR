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

    CPI DEZENA, 0 ; Comparação da dezena com 0
    BRNE Verifica_Flag_LED ; Se não for igual, verificar a flag do LED com a sub-rotina
    CPI UNIDADE, 0 ; Comparação da unidade com 0
    BRNE Verifica_Flag_LED ; Se não for igual, verificar a flag do LED com a sub-rotina

    CBI PORTD, LED ; (Clear Bit in I/O Register), se ambos Unidade e Dezena forem 0, desligar o LED
    RJMP Atualiza_E_Repete ; Pulo direto para a atualização do display

Verifica_Flag_LED:
    SBRS FLAG_REG, FLAG_OVERRIDE ; Pula para a próxima instrução caso o bit FLAG_OVERRIDE setado
    SBI PORTD, LED ; Se a flag estiver em 0, ligar o LED
    SBRC FLAG_REG, FLAG_OVERRIDE ; Pula para a próxima instrução caso o bit FLAG_OVERRIDE esteja zerado
    CBI PORTD, LED ; Se a flag estiver e m1, desligar o LED

Atualiza_E_Repete:
    RCALL AtualizaDisplay ; Chama a sub-rotina de atualização do display
    RJMP Principal ; Retorna ao início do loop principal

ISR_Botao:
    PUSH AUX              ; Salva o AUX atual na pilha
    IN AUX, SREG          ; Lê SREG no AUX
    PUSH AUX              ; Salva o AUX (com SREG) na pilha

    SBR FLAG_REG, (1<<FLAG_OVERRIDE) ; Coloca o bit de Override no FLAG_REG
    LDI DEZENA, 0         ; Zera a contagem de Dezena
    LDI UNIDADE, 0        ; Zera a contagem de Unidade

    POP AUX               ; Restaura o registrador de status da pilha
    OUT SREG, AUX         ; Escreve no registrador de status
    POP AUX               ; Restaura o valor original do AUX na pilha
    RETI                  ; Retorno da interrupção

ISR_Sensor:
    PUSH AUX              ; Salva o AUX na pilha
    IN AUX, SREG          ; Lê SREG no AUX
    PUSH AUX              ; Salva o AUX (com SREG) na pilha

    SBRC FLAG_REG, FLAG_OVERRIDE ; Se a flag de Override estiver em 0, pula para a próxima instrução
    RJMP Fim_ISR_Sensor   ; Se estiver em 1, vai para o fim (não acender)

    LDI DEZENA, 1         ; Reinicia o tempo para 15 segundos caso o Override seja 0
    LDI UNIDADE, 5        ; Reinicia as unidades pra 5
    CLR AUX               ; Zera o AUX
    STS TCNT1H, AUX       ; Zera a parte alta do contador do Timer 1
    STS TCNT1L, AUX       ; Zera a parte baixa do contador do Timer 1

Fim_ISR_Sensor:
    POP AUX               ; Restaura o registrador de status da pilha
    OUT SREG, AUX         ; Escreve no registrador de status
    POP AUX               ; Restaura o valor original do AUX na pilha
    RETI                  ; Retorno da interrupção

AtualizaDisplay:

    CBI CONTROLE, ContDez ; Desliga o controle do display das dezenas
    CBI CONTROLE, ContUni ; Desliga o controle do display das unidades


    MOV AUX, UNIDADE      ; Coloca o valor da unidade no AUX
    RCALL Decodifica      ; Chama a rotina de decodificação

    MOV AUX, R0           ; Colocando o padrão da rotina para o AUX
    ANDI AUX, 0x3F        ; Máscara para pegar apenas os bits 0 a 5          
    OUT PORTB, AUX        ; Envia os bits dos segmentos para a porta B

    SBRC R0, 6            ; Pula a instrução se o bit 6 for 0                   
    SBI PORTD, SEG_G      ; Se o bit 6 for 1, liga o pino PD5            
    SBRS R0, 6            ; Pula a instrução se o bit 6 for 1                  
    CBI PORTD, SEG_G      ; Se o bit 6 for 0, desliga o pino PD5         

   
    SBI CONTROLE, ContUni ; Liga o transistor que ativa o display para as unidades
    RCALL AtrasoMultiplex ; Chama o delay para a luz ser perceptível para o olho humano

    
    CBI CONTROLE, ContUni ; Desliga o transistor das unidades antes de efetuar a troca do número


    MOV AUX, DEZENA       ; Copia o valor da dezena para AUX
    RCALL Decodifica      ; Chama a rotina de decodificação

   






    MOV AUX, R0           ; Colocando o padrão da rotina para o AUX
    ANDI AUX, 0x3F        ; Máscara para pegar apenas os bits 0 a 5  
    OUT PORTB, AUX        ; Envia os bits dos segmentos para a porta B


    SBRC R0, 6            ; Pula a instrução se o bit 6 for 0
    SBI PORTD, SEG_G      ; Se o bit 6 for 1, liga o pino PD5  
    SBRS R0, 6            ; Pula a instrução se o bit 6 for 1
    CBI PORTD, SEG_G      ; Se o bit 6 for 0, desliga o pino PD5

    
    SBI CONTROLE, ContDez ; Liga o transistor que ativa o display para as dezenas
    RCALL AtrasoMultiplex ; Chama o delay para a luz ser perceptível para o olho humano

 
    CBI CONTROLE, ContDez ; Desliga o transistor das unidades antes de efetuar a troca do número

    RET


AtrasoMultiplex:
    LDI R18, 50          ; Carrega o valor 50 no registrador
L_AM1:
    LDI R19, 200         ; Carrega o valor 200 no registrador
L_AM2:
    NOP                  ; Gasto de 1 ciclo de clock
    DEC R19              ; Decremento em R19
    BRNE L_AM2           ; Volta para L_AM2 caso R19 não seja 0
    DEC R18              ; Decremento em R18
    BRNE L_AM1           ; Volta para L_AM1 caso R18 não seja 0
    RET                  ; Retorno sub-rotina


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
